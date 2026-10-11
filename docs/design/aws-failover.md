# AWS infrastructure recovery scope

Status: Deferred infrastructure decision. Date: 2026-10-11. Companion to [ADR 0001](../adr/0001-model-gateway-architecture.md).

The initial deployment is in the UK using Azure AKS/Envoy, managed APIM and Foundry, with private access to Bedrock in AWS London. Bedrock supplies an inference path; recovering an Azure platform outage also requires a working ingress and inference gateway.

A subsequent recovery ADR will select:

- An AWS-hosted ingress and inference gateway with equivalent identity, routing, quota and audit controls.
- Independent DNS, certificates, deployment images/configuration and operator access.
- UK recovery capacity and approved inference endpoints, plus measured recovery objectives and cost.

Terraform modules will accept region and residency inputs so recovery infrastructure can be added without changing the initial UK environment. Applications, durable data replication and workflow recovery are designed in the separate application repository.

The [Front Door incident note](../research/azure-front-door-outage.md) supplies an ingress-failure scenario. Gateway policy compatibility, independent credentials and recovery readiness must be demonstrated before enabling automatic traffic failover.
