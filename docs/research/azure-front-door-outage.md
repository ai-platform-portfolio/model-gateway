# Azure Front Door outage: 29–30 October 2025

Research date: 2026-10-11. Incident: YKYN-BWZ.

## Verified incident facts

Microsoft reports impact from 15:41 UTC October 29 to 00:05 UTC October 30. Valid configuration changes spanning two control-plane builds generated incompatible metadata. Delayed asynchronous processing crashed edge services after deployment health gates had passed; the problematic configuration also entered the last-known-good snapshot. Edge-hosted DNS was affected. Microsoft edited the snapshot and recovered the fleet gradually. Some improvement began at 18:30; full mitigation came at 00:05. Azure Portal failed away from Front Door, while some dependent features remained affected. Repairs included longer rollout observation and synchronous validation. Dates for additional planned repairs in the original report are not evidence of their completion.

Source: [Microsoft post-incident review](https://azure.status.microsoft/en-us/status/history/?trackingId=YKYN-BWZ).

## Engineering interpretation

This is a global edge/configuration failure scenario, not evidence that all customer databases or compute failed. Switching Azure application regions behind the same edge service would not address the shared ingress dependency. Inference running in another cloud can remain healthy while users cannot reach the application.

The important deployment lesson applies to the gateway's own registry: a quick healthy signal is insufficient when configuration errors surface later. Validate compatibility across old/new code versions, use representative requests, observe canaries longer than delayed failure windows, and keep multiple immutable known-good versions. Do not replace rollback state immediately after an apparently successful rollout.

## Proposed controls for this project

- Probe the public user journey and a secured origin journey separately from outside the primary cloud. Alert on DNS, TLS, HTTP, identity, application, and inference failures independently.
- Preconfigure a second ingress route with equivalent TLS, authentication, authorization, WAF, and rate limiting. It must not rely on Front Door to reach the origin.
- Separate ingress-only recovery from application/database promotion. If Azure origins remain healthy, use the alternate edge path and retain the primary writer.
- Use an independent DNS/recovery control and a runbook that works without Azure Portal. Account for resolver caching and reconnect streaming clients explicitly.
- Keep status communications outside the application failure path. Test the ability to publish updates and operate cloud APIs during edge failure.
- Exercise the AWS standby with Azure unavailable, including secrets, image retrieval, identity renewal, job replay, artifacts, and audit delivery.

These controls are proposed engineering responses, not claims about the affected service's mitigation or commitments.

## Drill scenarios

| Injected failure | Expected response | Evidence to collect |
| --- | --- | --- |
| Public edge/DNS fails; Azure origin healthy | Switch secured ingress; keep Azure database authoritative | Recovery time, TLS/auth/WAF equivalence, reconnect success |
| Azure application region unavailable | Fence primary and promote AWS only after recovery checks | Writer fencing, replication lag, job/artifact consistency |
| Model provider unavailable | Use eligible inference fallback only | Policy decision, retry spend, duplicate-action prevention |
| Azure portal unavailable | Use preconfigured APIs and recovery credentials | Runbook completion without portal |
| Delayed bad registry configuration | Stop canary and restore earlier immutable version | Detection time, limited blast radius, rollback correctness |

Microsoft discusses parallel global ingress designs and their security/operational costs in [Mission-critical global HTTP ingress](https://learn.microsoft.com/en-us/azure/architecture/guide/networking/global-web-applications/mission-critical-global-http-ingress).

## Follow-up questions

What outage duration is acceptable? Can recovery credentials and DNS controls be reached independently? Does the alternate path preserve origin restrictions? Do customer SSO dependencies survive? Can recovery safely stop at read-only mode when writer ownership is uncertain?
