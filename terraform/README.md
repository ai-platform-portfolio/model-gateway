# Azure network deployment

This root calls the existing platform-iac network module at a full commit SHA.
It creates a fresh UK West resource group, VNet, dedicated APIM integration
subnet and separate undelegated private-endpoint subnet.
Resource definitions stay in platform-iac; environment settings are in
`environments/uk-west.tfvars`. The proposed `10.60.0.0/16` allocation differs
from the central VNet's `10.50.0.0/16`; check the complete Azure/AWS/GCP address
inventory before applying or configuring interconnects.

`resource_group_name` and `location` are top-level environment inputs reused by
subsequent modules. The network module creates the shared resource group; later
modules must reference it without creating it again, with dependencies on the
network module where needed.

The APIM subnet is `10.60.0.0/24`, delegated to `Microsoft.Web/serverFarms` for
Standard v2 outbound VNet integration. The private-endpoint subnet is
`10.60.4.0/24`. [APIM integration requirements](https://learn.microsoft.com/en-us/azure/api-management/integrate-vnet-outbound)
require the instance and VNet in the same region and subscription and an NSG
on the integration subnet. NSG provisioning, endpoint/DNS wiring and APIM
regional availability are addressed in AI-33 before APIM deployment. APIM and the VNet will both be in UK West. Private DNS zones remain empty
until endpoint selection. This stage does not provide cross-cloud transport.

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
terraform -chdir=terraform plan -var-file=environments/uk-west.tfvars
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

## Pipeline

The single infrastructure workflow calls ops-shared. PRs run OpenTofu and post
one plan comment. Main and manual pipelines create a Terraform plan; Apply runs
only on main, after manual approval in `central-apply`, using that saved plan.
The main plan artifact expires after one day. Identity and backend values remain
external GitHub secrets and authentication uses OIDC.

## Move to UK West (AI-42)

`environments/uk-west.tfvars` moves the shared resource group and network to
UK West so Standard v2 APIM can use its dedicated subnet in the same region.
Terraform replaces the UK South resource group, VNet and subnets; this is not
an in-place regional move. This PR does not provision APIM.

Keep the historical backend key `model-gateway/uk-south.tfstate` during this move.
It tracks the deployed resources despite its name. Changing the key would create
an empty state and leave the old UK South network unmanaged. Review the replacement plan
before approving Apply; complete this stage before adding APIM in AI-33.
