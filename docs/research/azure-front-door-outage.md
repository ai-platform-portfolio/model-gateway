# Azure Front Door outage: 29–30 October 2025

Research date: 2026-10-11. Incident: YKYN-BWZ.

## Verified incident facts

Microsoft reports impact from 15:41 UTC October 29 to 00:05 UTC October 30. Valid configuration changes spanning two control-plane builds generated incompatible metadata. Delayed asynchronous processing crashed edge services after deployment health gates had passed; the problematic configuration also entered the last-known-good snapshot. Edge-hosted DNS was affected. Microsoft edited the snapshot and recovered the fleet gradually. Some improvement began at 18:30; full mitigation came at 00:05. Azure Portal failed away from Front Door, while some dependent features remained affected. Repairs included longer rollout observation and synchronous validation. Dates for additional planned repairs in the original report are not evidence of their completion.

Source: [Microsoft post-incident review](https://azure.status.microsoft/en-us/status/history/?trackingId=YKYN-BWZ).

## Relevance to the selected infrastructure

The incident demonstrates a shared ingress failure while origins may remain healthy. The platform selected in [ADR 0001](../adr/0001-model-gateway-architecture.md) uses Envoy Gateway on AKS; Front Door is not in the initial ingress path.

Test DNS/TLS, Envoy ingress, APIM and provider reachability independently. Roll out gateway policy changes with delayed-failure observation and retain immutable rollback versions. Operator runbooks use preconfigured CLI/API access rather than depending on Azure Portal.

Independent AWS ingress/gateway recovery is a [separate infrastructure decision](../design/aws-failover.md). Application data and workflow recovery belong in the application repository.
