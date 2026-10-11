# Model Gateway

Infrastructure for governed model access using Azure API Management, Microsoft Foundry and Amazon Bedrock, with Envoy Gateway on AKS for application ingress. Separate US and UK/EU deployments enforce approved endpoint boundaries. Google Cloud inference is an additional integration for Gemini.

This repository owns Terraform infrastructure, Kubernetes platform configuration, gateway policies, networking, identity and infrastructure observability. Applications, agents and evaluations belong in a separate repository. No custom FastAPI inference proxy is selected.

The repository currently contains design documents; infrastructure has not been deployed.

- [ADR 0001: Foundry, Bedrock, APIM and Envoy infrastructure](docs/adr/0001-model-gateway-architecture.md)
- [Model availability and hosting evidence](docs/research/model-availability.md)
- [Azure Front Door incident and recovery implications](docs/research/azure-front-door-outage.md)
- [Earlier AWS failover exploration, outside the adopted scope](docs/design/aws-failover.md)

Model availability, API features and geography require approval per exact endpoint. A private endpoint or catalogue listing does not establish inference residency.
