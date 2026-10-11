# AWS application failover proposal

Status: Earlier exploration; not adopted by [ADR 0001](../adr/0001-model-gateway-architecture.md). Date: 2026-10-11.

The repository now covers infrastructure only. Application state, workflow and evaluation choices below belong to a separate repository and are not selected platform components. The inference gateway is managed APIM; the table below predates that decision and must not be read as a plan to deploy APIM on EKS. An independent AWS recovery gateway requires a subsequent infrastructure ADR.

## Scope and recovery objectives

Azure remains the primary application cloud. Propose AWS warm standby for the gateway, application API, and enough worker capacity to run representative jobs. Replicate application state and artifacts into approved AWS locations before a failure. Full active-active writes are out of scope.

The objectives below are initial portfolio test targets, not verified service guarantees or customer commitments:

| Failure scope | Proposed target | Conditions |
| --- | --- | --- |
| Azure Front Door only | Restore access within 5 minutes | Secured alternate ingress healthy; origin/database remain authoritative |
| Azure application region or cloud | Restore core service within 30 minutes | AWS capacity, credentials, data, and fencing checks pass |
| Committed database state | RPO at most 5 minutes | Measured replication lag within target; otherwise report actual loss window |
| Durable artifacts and accepted jobs | Same 5-minute target for recoverable completed work | Consistent manifest/checkpoint replicated; unreplicated artifacts remain unavailable |

RTO measures time until the service passes its user-journey checks; RPO measures the recoverable loss window. DNS change completion or healthy pods alone do not prove recovery. [AWS recovery strategies](https://docs.aws.amazon.com/whitepapers/latest/disaster-recovery-workloads-on-aws/disaster-recovery-options-in-the-cloud.html) explain the warm-standby cost/recovery trade-off.

Residency is a promotion prerequisite. Maintain separate US and UK/EU recovery deployments, matching each tenant's primary boundary. Database replicas, object copies, backups, queues, logs, secrets, and inference destinations must stay in the assigned boundary. Never promote UK/EU tenants into US recovery capacity or the reverse. Office and operator locations do not change tenant residency; govern remote support access separately.

## Deployment shape

| Dependency | Azure primary | Proposed AWS recovery | Verification required |
| --- | --- | --- | --- |
| Application/gateway/workers | AKS | EKS with minimal running capacity and scale-out headroom | Same pinned images, policy, schema, and workload behaviour |
| Public edge | Front Door/WAF | CloudFront/WAF with independently reachable origin | Hostnames, certificates, headers, cookies, uploads, streaming, timeouts |
| Secured Azure bypass origin | Private Azure ingress | Preconfigured secondary edge route to Azure | Network reachability without Front Door; no public unauthenticated bypass |
| Recovery application origin | AKS ingress | AWS ALB/EKS ingress | Independent TLS/auth/WAF and origin protection |
| Durable state | PostgreSQL | RDS PostgreSQL candidate | Logical replication/CDC feasibility, lag, schema and promotion correctness |
| Artifacts | Blob Storage | S3 copies plus checksummed manifests | Encrypted, tenant-isolated, version-consistent copying |
| Queue transport | Service Bus | SQS or equivalent adapter | Rebuild deliveries from durable job/outbox state |
| Cache | Azure private cache | ElastiCache or local disposable cache | Cold-cache load and strict tenant separation |
| Secrets/keys | Key Vault | AWS Secrets Manager/KMS | Replicate/reissue only permitted material; prove decryptability without Azure |
| Images/configuration | Primary deployment systems | Independent image mirror and config/state access | No Azure registry, portal, or secrets retrieval needed |
| DNS/recovery control | Independent authority, proposed Route 53 | Same recovery control | No Front Door dependency; AWS outage behaviour also documented |

CloudFront-to-private-Azure connectivity is a feasibility spike, not an assumed turnkey integration. Compare an AWS proxy with approved private connectivity against another edge provider. Any approach must preserve WAF, authorization, and origin restrictions. If no secure bypass is demonstrated, do not advertise ingress-only failover as available.

Avoid an AWS application that still reads its database, artifacts, secrets, or queue exclusively from Azure. Bedrock availability alone is not application recovery. Google Cloud inference may remain available in AWS recovery, subject to the same tenant policy; a GCP outage is not itself a reason to promote application state.

## Database and artifact consistency

Investigate Azure PostgreSQL logical publication to an AWS PostgreSQL subscriber or a supported CDC tool over approved transport. Do not assume managed cross-cloud physical replication exists. Validate extensions, replication slots and WAL growth, primary keys, DDL, sequences, large objects, schema migrations, encryption, and observability. Managed Azure geo-backup/read-replica features are Azure recovery facilities, not a ready-made AWS replica. [Azure continuity documentation](https://learn.microsoft.com/en-us/azure/postgresql/backup-restore/concepts-business-continuity).

Keep one writer. Promote only with a provable fencing mechanism that prevents stale Azure API/worker instances from accepting mutations or executing side effects after AWS takes over. Design a bounded writer lease and fencing epochs; its authority must survive the declared outage without becoming an unexamined cross-cloud single point of failure. An unreachable primary is not evidence that it is stopped. Until the fencing design is proven, uncertain ownership permits read-only recovery only.

Store jobs, idempotency keys, checkpoints, routing decisions, and an outbox transactionally. Replicate artifact content, validate its checksum, then publish a recovery manifest referencing the matching database/checkpoint version. A database pointer without its object does not represent recovered work. Readers reject incomplete manifests. Keep immutable backups independently of live replication to recover from corruption or deletion.

Estimate loss from the last verified transaction and artifact watermark, not from configured replication frequency. Block write promotion or expose a reduced recovery mode if lag exceeds policy. Audit the actual lost/unavailable window and require explicit operational acceptance before a lossy promotion.

## Queues and external actions

Native Service Bus disaster recovery does not transfer work to AWS. Microsoft distinguishes message/data geo-replication from metadata-only geo-disaster recovery, both within its service. [Service Bus replication documentation](https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-geo-replication).

Use a transactional outbox to recreate eligible deliveries in the AWS transport. Implement queue adapters with defined acknowledgement, visibility, dead-letter, ordering, and retry semantics; Service Bus and SQS are not assumed equivalent. Work remains recoverable from durable job state even if the queue is lost.

At-least-once replay requires idempotent tool operations. Track an external action's intent and result using a durable action ID; reconcile unknown outcomes before reissuing writes to customer systems. Never claim exactly-once execution merely because a queue offers deduplication. Pause scheduled triggers while promotion is in progress to prevent two clouds launching the same workflow.

## Identity and secrets

AWS workload credentials must be obtainable without Azure token exchange during a full Azure outage. Use AWS-native workload identities for AWS deployments and independent secrets for approved external model adapters. Check model entitlements and quotas in the recovery account before a drill.

Customer SSO may still depend on Entra or another customer IdP. Cached signing keys can validate unexpired tokens but cannot restore new logins, renew tokens, or establish that revocation remains safe indefinitely. Define a bounded existing-session policy and an explicit new-login limitation. Do not weaken customer identity requirements or add an undocumented alternate user account. Recovery operator access needs a separately governed, tested emergency path.

## Promotion and failback

1. Identify the failing layer using independent synthetic probes. For an edge-only incident, switch secured ingress without changing database ownership.
2. For full application recovery, declare the incident, freeze scheduling, verify AWS health/capacity, credentials, approved inference, replication watermarks, and artifact integrity.
3. Fence the old writer and worker side effects. If fencing cannot be proven, remain read-only.
4. Record the new writer epoch, promote the recovery database, start idempotent workers, and reconcile unresolved actions.
5. Switch DNS after the AWS service is recovery-ready. Exercise login/session behaviour, model calls, job creation, artifact download, and audit persistence.
6. Observe replication/data-loss evidence and announce the actual reduced service scope.
7. Fail back only after reverse synchronization and validation. Quiesce writes, establish ownership, reconcile jobs/objects, then move traffic. Never automatically switch writers back when a health check turns green.

Route 53 supports health-driven failover; health must represent an approved recovery-ready state, not just a load balancer response. DNS TTL cannot bound every client's cache or persistent connection. Automatic ingress recovery may be appropriate; stateful promotion initially remains operator controlled. [Route 53 failover](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-failover.html).

## Proof and cost before acceptance

Run drills for edge failure, regional application loss, database partition, missing artifact, identity renewal failure, throttled recovery models, stale policy, unavailable image registry, and duplicate external actions. Prove failback as well as failover. Record measured RTO/RPO, writer epoch, replication lag, user-journey results, and cost.

Keep AWS warm capacity small for portfolio work, with a full-capacity drill as an explicit scheduled exercise. Budget for EKS, database replicas, NAT/private connectivity, object copies, cross-cloud transfer, observability, and model quotas. A logically independent design without affordable capacity and exercised recovery remains a proposal.

## Outstanding decisions

Exact regions/residency, secure secondary-edge transport, cross-cloud CDC product, fencing authority, identity outage policy, recovery tier, cloud cost envelope, and retention approval must be resolved before claiming production readiness. Terraform and Kubernetes changes belong to implementation issues after architecture review.
