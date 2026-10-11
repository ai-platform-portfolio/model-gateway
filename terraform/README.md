# Azure network deployment (AI-32)

This root calls the existing platform-iac network module at a full commit SHA.
It creates a fresh UK South resource group, VNet and two undelegated subnets.
Resource definitions stay in platform-iac; environment settings are in
`environments/uk-south.tfvars`. The proposed `10.60.0.0/16` allocation differs
from the central VNet's `10.50.0.0/16`; check the complete Azure/AWS/GCP address
inventory before applying or configuring interconnects.

The AKS subnet reserves space for future ingress compute; it creates no cluster.
Private DNS zones are empty until the APIM and AI stages select their actual
endpoints. APIM region, integration subnet, NSG, peering and DNS links are part
of AI-33; this stage does not provide backend access or cross-cloud transport.

## Identity and state

Use a separate state key, such as `model-gateway/uk-south.tfstate`. Never initialize
this root with platform-iac's central state key. Supply backend resource group,
storage account and container externally at initialization. Use the existing
approved state service with Entra data-plane access, not an account key.

Supply `ARM_SUBSCRIPTION_ID`, `ARM_TENANT_ID` and, for CI, `ARM_CLIENT_ID` from
external configuration. CI should use GitHub OIDC (`ARM_USE_OIDC=true`) with
approved planning/apply environments; this root does not provision that trust.
For local work, use an authenticated Azure CLI session. Never commit identity
values, credential JSON, client secrets, cloud tokens or backend account keys.

```sh
terraform -chdir=terraform init \
  -backend-config="resource_group_name=$TF_STATE_RESOURCE_GROUP" \
  -backend-config="storage_account_name=$TF_STATE_STORAGE_ACCOUNT" \
  -backend-config="container_name=$TF_STATE_CONTAINER" \
  -backend-config="key=model-gateway/uk-south.tfstate"
terraform -chdir=terraform plan -var-file=environments/uk-south.tfvars
```

These commands assume the external variables are already configured; they
contain no credential literals. Authenticate module fetching separately if
the source repository requires it; never include a token in its source URL.
Review the live plan before deployment. This change has not applied resources.

## Secrets and later stages

Cloud account/project/subscription identifiers stay external even when they
are not secrets. Runtime secrets use cloud secret-manager references and
workload identity; Terraform must not read their plaintext values. Helm values
will carry references rather than credential or certificate material.

Build sequentially: network (AI-32), APIM (AI-33), AI providers (AI-34), then
Envoy chart resources (AI-35). The network module remains available at its
pinned revision after removal of the unrelated legacy OpenAI/AKS-nodepool modules.
