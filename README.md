# Model Gateway

Infrastructure for governed AI model access in regulated financial services environments.

- Microsoft Foundry for GPT; Amazon Bedrock for Claude and approved open models.
- Azure API Management for inference authentication, routing, consumption limits and audit, including the unified model API preview.
- Envoy Gateway on AKS for application ingress, in-lieu of Azure Application Gateway to avoid its service charge.
- Private Azure–AWS connectivity through ExpressRoute/Direct Connect with an IPsec overlay.

Deploy into the UK initially. Terraform modules will parameterize regions, networking, backend approvals and quotas for additional environments. Applications and evaluations are maintained in a separate repository. Gemini is an additional Google Cloud inference integration.

[ADR 0001](docs/adr/0001-model-gateway-architecture.md) contains the architecture, provider evidence, alternatives and cost/token controls. Supporting notes cover the [Azure Front Door incident](docs/research/azure-front-door-outage.md) and [AWS infrastructure recovery scope](docs/design/aws-failover.md).

This portfolio intentionally uses the unified model API preview to demonstrate model aliases and supported cross-provider translation. Preview use is not a production recommendation for regulated financial services.

Current state: design documents only. Infrastructure, gateway policies and integration tests have not yet been deployed or run.
