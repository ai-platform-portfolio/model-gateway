# ADR 0001: Regulated model access with Foundry, Bedrock and APIM

- Status: Proposed
- Date and provider evidence checked: 2026-10-11
- Issue: [AI-30](https://linear.app/ai-platform-portfolio/issue/AI-30/draft-adr-for-model-gateway-architecture)

## Context

Design a model-access platform for regulated financial services environments: confidential financial data, controlled processing locations, least-privilege access, auditable changes and attributable consumption. Azure is the primary platform cloud. Deploy infrastructure in the UK initially; parameterize Terraform modules for additional regions and residency policies. Applications and evaluations are maintained in a separate repository.

## Decision

Implement Microsoft Foundry for GPT, Amazon Bedrock for Claude and initial open-weight model routes, Google Gemini Enterprise Agent Platform for Gemini, and Azure API Management (APIM) as the shared application-facing inference gateway. Deploy self-hosted Envoy Gateway on AKS in-lieu of Azure Application Gateway for cost effectiveness: the required TLS termination and HTTP routing functionality is provided by open-source software without a gateway licence or Application Gateway service charge. AKS compute and Azure Load Balancer remain chargeable. [Envoy Gateway](https://github.com/envoyproxy/gateway).

### Why Foundry and Bedrock

| Requirement | Selected service and specific reason |
| --- | --- |
| GPT within the Azure platform | Foundry provides managed GPT deployments, Entra authentication and Private Link. Bedrock's GPT-6.1 Sol currently offers US/global inference, without a UK/EU route; it cannot replace Foundry for this requirement. [AWS GPT model card](https://docs.aws.amazon.com/bedrock/latest/userguide/model-card-openai-gpt-6-1-sol.html). |
| Claude with UK/EU processing | Foundry Claude documents Global Standard and selected US Data Zone deployments, without an EU Data Zone option. Bedrock Sonnet 5.5 provides `eu.anthropic.claude-sonnet-5-5` from London, routing to the UK and EU member states. This is the concrete reason for adding Bedrock. [Foundry Claude](https://learn.microsoft.com/en-us/azure/foundry/foundry-models/how-to/use-foundry-models-claude), [Bedrock Sonnet profile](https://docs.aws.amazon.com/bedrock/latest/userguide/model-card-anthropic-claude-sonnet-5-5.html). |
| Gemini with EU processing | Select Google Gemini Enterprise Agent Platform as the Gemini backend, using a Google Cloud project, billing account and scoped IAM access. Its residency table lists Gemini 3.8 Flash as supporting EU multi-region processing. Route through APIM and expose approved aliases to Foundry agents through a bring-your-own-model connection; verify the selected model, API and endpoint against the processing boundary before enabling the route. [Google model residency](https://docs.cloud.google.com/gemini-enterprise-agent-platform/resources/data-residency), [Google endpoints](https://docs.cloud.google.com/gemini-enterprise-agent-platform/resources/locations). |
| Cost-effective open-weight inference | Use Bedrock on-demand routes initially, reusing the AWS networking, IAM and monitoring already required for Claude. Qwen3 Next 80B A3B and Qwen3 Coder Next support in-region London inference and are candidates for later application evaluations. Model routes remain configurable; evaluations determine quality and cost per successful task. [Bedrock regional availability](https://docs.aws.amazon.com/bedrock/latest/userguide/models-region-compatibility.html), [pricing](https://aws.amazon.com/bedrock/pricing/). |

Model onboarding uses a versioned backend configuration containing the deployment/profile, API, processing scope and retention approval. Enable only UK/EU-approved inference routes in the UK environment; deny global deployments/profiles through deployment and runtime policies. GPT uses an approved geography-scoped Foundry deployment. EU Data Zone scope follows Microsoft's broader EU Data Boundary and is not the default for the strict UK/EU allowlist. [Foundry deployment types](https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/deployment-types).

Direct Anthropic is not selected because its documented inference locations are US/global. Direct OpenAI's European scope includes EEA and Switzerland, exceeding the selected UK/EU boundary. [Anthropic residency](https://platform.claude.com/docs/en/manage-claude/data-residency), [OpenAI residency](https://developers.openai.com/api/docs/guides/your-data).

Model-specific retention approvals include Bedrock's Fable review-retention requirements. The selected providers expose regional model access through cloud IAM, private networking and auditable billing; these controls fit the financial-services platform operating model. [Bedrock retention](https://docs.aws.amazon.com/bedrock/latest/userguide/abuse-detection.html).

### Deployment

| Component | UK implementation |
| --- | --- |
| Kubernetes ingress | AKS in UK South; Envoy Gateway and Azure Load Balancer |
| Model access | APIM Standard v2 in UK West, inbound Private Link and outbound VNet integration |
| Azure inference | Foundry in UK South, private endpoint and approved GPT deployment |
| AWS inference | VPC in `eu-west-2`, Bedrock Runtime and STS interface endpoints, private DNS and endpoint policies |
| Google inference | Gemini on Agent Platform using the EU jurisdictional endpoint, regional PSC in `europe-west4`, Google IAM and workload identity federation |
| Cross-cloud transport | ExpressRoute and Direct Connect through a UK cloud exchange, with IPsec overlay |
| Platform controls | Entra identities/RBAC, AWS IAM, Key Vault, private DNS, regional diagnostics and billing budgets |

APIM is placed in UK West because Microsoft's current availability table marks new v2 instances in UK South temporarily unavailable. Peer its UK West VNet with the UK South platform VNet. [APIM regional availability](https://learn.microsoft.com/en-us/azure/api-management/api-management-region-availability).

```mermaid
flowchart LR
    Client[Client] --> Envoy[Load Balancer and Envoy on AKS]
    Envoy --> App[Application: separate repository]
    App --> APIM[Private APIM]
    APIM --> Foundry[Foundry private endpoint]
    APIM --> Link[ExpressRoute / cloud exchange / Direct Connect\nIPsec overlay]
    Link --> Bedrock[London Bedrock private endpoint]
    FoundryAgent[Foundry agent: BYOM connection] --> APIM
    APIM --> Google[Agent Platform Gemini: approved UK/EU endpoint]
```

Terraform inputs specify regions, CIDRs, circuit references, endpoint/model approvals, quotas and diagnostics. Separate environment state and backend allowlists support later regional deployments without cross-boundary failover.

Azure applications call APIM for inference while their compute and storage remain in Azure. APIM routes each configured model alias to Foundry, Bedrock or the Agent Platform Gemini backend; Bedrock managed inference requires no application server or GPU deployment in AWS.

### Gemini backend and Foundry integration

Google renamed Vertex AI to Gemini Enterprise Agent Platform; the API service remains `aiplatform.googleapis.com`. Use the current product name in documentation and retain provider/API identifiers where required. [Google naming changes](https://docs.cloud.google.com/gemini-enterprise-agent-platform/release-notes).

Select Agent Platform for Gemini. Foundry agents use an admin-connected model alias through a bring-your-own-model connection to APIM: **Foundry agent → APIM → Agent Platform**. Applications can also invoke the same approved alias directly through APIM. Gemini inference remains on Google Cloud. The Foundry connection provides agent access to the external backend; it does not create an Azure-hosted Gemini model deployment. [Foundry BYOM connections](https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/ai-gateway).

Use the Agent Platform OpenAI-compatible Chat Completions API where the selected model and approved endpoint support it, matching the Foundry connection contract. Keep API format, model identifier, location and endpoint configurable. Validate streaming, supported features and error translation before onboarding. [Agent Platform authentication and endpoint configuration](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/migrate/openai/auth-and-credentials).

The Gemini Developer API used in Microsoft's example is not selected. Microsoft chose it for easy demonstration setup and free-tier access. Agent Platform better fits this platform's Google IAM, federated short-lived credentials and processing-location controls. [Microsoft multi-vendor BYOM sample](https://github.com/microsoft-foundry/foundry-samples/blob/main/infrastructure/infrastructure-setup-terraform/46-bring-your-own-models/README.md).

Agent Platform selection and routing through Foundry do not establish private connectivity or processing residency on their own. Approve the exact Google model and endpoint separately, block global routing and cross-boundary fallback, and verify private access through the chosen cross-cloud transport and Google API networking configuration before enabling workloads. The initial model is `gemini-3.8-flash`, with EU processing through `aiplatform.eu.rep.googleapis.com`; provision the regional private endpoint in `europe-west4`. Google documents regional PSC for this multi-region endpoint and explicitly excludes Private Google Access. The private endpoint location is separate from the model processing boundary. [Google model residency](https://docs.cloud.google.com/gemini-enterprise-agent-platform/resources/data-residency), [Private Service Connect for Gemini over hybrid connectivity](https://codelabs.developers.google.com/cloudnet-psc-hybridGemini).

### APIM and Envoy responsibilities

APIM validates Entra workload tokens, authorizes tenant access and routes configured aliases/task categories to approved backends. Policies provide request limits, supported token quotas, backend priorities, circuit breakers and bounded retries. Use the unified model API for supported OpenAI Chat Completions and Anthropic Messages backends. Retain provider-native routes for features and endpoints outside that translation scope, including Bedrock Runtime InvokeModel/Converse. Streaming routes disable response buffering; fallback is configured only between compatible backends before response output starts. [APIM capabilities](https://learn.microsoft.com/en-us/azure/api-management/genai-gateway-capabilities), [backend pools](https://learn.microsoft.com/en-us/azure/api-management/backends).

Select APIM's unified model API for this portfolio despite its preview status. It demonstrates a shared client-facing API, model aliases and supported cross-provider format translation. The portfolio explicitly accepts preview limitations; this selection is not a production recommendation for regulated financial services. Production adoption requires a separate review of support/SLA terms, API compatibility and organizational preview policy. [Unified model API status](https://learn.microsoft.com/en-us/azure/api-management/unified-model-api).

Envoy owns application TLS, HTTP routing and ingress traffic controls. Applications call private APIM directly for inference. Deploy pinned Envoy versions with multiple data-plane replicas. Public-ingress WAF is a separate security control; the current ingress scope is TLS and HTTP routing.

### Cross-cloud transport

Select redundant ExpressRoute/Direct Connect connections through a UK cloud exchange such as Megaport or Equinix. Run an IPsec overlay between network appliances in the two clouds and retain HTTPS to Bedrock. This combines a private underlay with encryption across the exchange. Route inference traffic only through the encrypted overlay; restrict AWS endpoint security groups to the authorized source path. Provision circuits through the exchange and reference their identifiers in Terraform. [Microsoft connectivity options](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/connectivity-to-other-providers), [private-path encryption](https://learn.microsoft.com/en-us/azure/networking/design-guide/cross-region).

| Alternative | Decision |
| --- | --- |
| Internet site-to-site IPsec VPN | Lower circuit cost and encrypted transport, but does not meet the selected private-underlay requirement |
| ExpressRoute/Direct Connect with TLS alone | Private transport, but the selected design also requires network-layer encryption across the exchange |
| Azure Multicloud Interconnect / AWS Interconnect | Managed private links with MACsec; currently preview, without an Azure preview SLA or UK region in the published availability list |
| SD-WAN/NVA tunnels over internet | Adds appliance operation without removing public-internet transport |

The managed interconnect is a real alternative, not a VPN-only limitation. Its published preview locations exclude the UK. [Interconnect security](https://learn.microsoft.com/en-us/azure/multicloud-interconnect/overview), [availability and SLA](https://learn.microsoft.com/en-us/azure/multicloud-interconnect/availability-limits).

### Identity

APIM uses a user-assigned managed identity and scoped Foundry RBAC. For Bedrock, implement Entra-to-AWS federation in APIM policy fragments:

1. Obtain an Entra token for a dedicated federation application using APIM managed identity.
2. Exchange it at regional AWS STS using `AssumeRoleWithWebIdentity`; IAM trust restricts issuer, audience and subject to that identity.
3. Sign Bedrock Runtime requests with SigV4 using the returned temporary credentials, including the session token. Cache credentials only until before expiration.

This composes documented APIM token acquisition, AWS Entra federation and APIM request-signing mechanisms; it is a policy implementation, not a built-in federation connector. Scope the role to approved model/profile resources and restrict policy editing to the platform deployment identity. [APIM identity policy](https://learn.microsoft.com/en-us/azure/api-management/authentication-managed-identity-policy), [AWS Entra federation](https://aws.amazon.com/blogs/apn/automating-openid-connect-based-aws-iam-web-identity-roles-with-microsoft-entra-id/), [APIM Bedrock signing](https://learn.microsoft.com/en-us/azure/api-management/amazon-bedrock-passthrough-llm-api).

For Agent Platform, retain the shared Azure user-assigned managed identity. Foundry authenticates to APIM with that identity; APIM validates its Entra token. Configure a separate Google workload identity federation trust with issuer, audience and subject restricted to the authorized Azure identity. APIM obtains an Entra token for the Google federation audience, exchanges it through Google STS, and obtains a short-lived Google OAuth access token, using scoped service-account impersonation where required. Grant only the inference permissions needed for the approved backend. Cache tokens only until before expiry and implement renewal in APIM policy fragments. This token exchange requires implementation and end-to-end validation; it is not an automatic Foundry connector capability. [Google federation with Azure workloads](https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-other-clouds), [Agent Platform OAuth authentication](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/migrate/openai/auth-and-credentials).

Use GitHub OIDC federation separately for Terraform deployment. Capture Google API enablement, IAM, federation and networking in reusable `platform-iac` modules, consumed by Model Gateway module calls and parameterized inputs. Do not create Google service-account keys or store provider credentials in tfvars, repositories or Terraform state. Pass cloud identifiers through external parameters; any future long-lived secret must be retrieved from the relevant cloud secret manager.

### Cost, tokens and audit

- Start open-weight models on pay-per-token inference. Keep model identifiers and routes configurable; application evaluations select the best value for each task. Reserved capacity and self-hosted GPU deployments are outside the initial implementation.
- Apply per-tenant/workload request limits, output-token caps and daily/monthly token allowances. Use `llm-token-limit` on supported API schemas; native Bedrock routes use request/output caps and provider quotas, with usage reporting from their native responses. Streaming estimates and concurrent overshoot preclude treating APIM quotas as an exact global spend ledger. [Token policy](https://learn.microsoft.com/en-us/azure/api-management/llm-token-limit-policy).
- Emit model, provider, workload, latency, errors and token usage to regional monitoring. Disable prompt/response logging and shared content caching. Use token metrics where the schema supports them. [Token metrics](https://learn.microsoft.com/en-us/azure/api-management/llm-emit-token-metric-policy).
- Tag resources and reconcile estimated inference spend with Azure/AWS billing exports. Configure monthly budgets, forecast notifications and anomaly alerts. Report platform spend separately: APIM, AKS/Load Balancer, exchange/circuits, IPsec appliances, endpoints, transfer and telemetry. Budgets notify; gateway quotas enforce consumption limits.

## Validation

Validate IaC and gateway policies; test unified API aliases and format translation, private DNS/transport, AWS STS and Google OAuth token renewal, Foundry BYOM Gemini aliases, denied identities/routes, streaming, throttling, token reporting and circuit/tunnel failure using synthetic requests. Confirm billing allocation and content-free audit records. Application behavior and model evaluations are tested in their own repository.

## Related decisions

[Azure Front Door incident](../research/azure-front-door-outage.md) informs ingress failure testing. [AWS recovery scope](../design/aws-failover.md) records the separate infrastructure recovery work.
