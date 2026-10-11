# Azure network deployment (AI-32)

This root calls the existing platform-iac network module at a full commit SHA.
It creates a fresh UK South resource group, VNet, dedicated APIM integration
subnet and separate undelegated private-endpoint subnet.
Resource definitions stay in platform-iac; environment settings are in
`environments/uk-south.tfvars`. The proposed `10.60.0.0/16` allocation differs
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
regional availability are addressed in AI-33 before APIM deployment. The ADR
currently places APIM in UK West; AI-33 must reconcile that placement with this
UK South VNet before enabling integration. Private DNS zones remain empty
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

## PR plan comments (AI-37)

The PR caller reuses `ops-shared/.github/workflows/terraform.yml` at an immutable
revision, selecting OpenTofu 1.12.3, this root and the UK South variables file.
It updates one redacted bot comment per PR, checks the current head before
posting, reports failures and deletes saved plans. It creates no plan artifacts
and enables no apply job. The stable `infrastructure-plan-required` result can
be required by repository rules.

`opentofu.lock.hcl` is the separate preview lock; the shared action copies it to
the active lock only on the runner. Terraform's checked-in lock is unchanged.
`backend.hcl` selects this environment's state key. The federation contract in
`.github/federation.json` contains public GitHub repository identity metadata,
not cloud credentials; its immutable subject matches this repository's OIDC
configuration.

The repository has an ungated `central-plan` environment matching platform-iac.
Before a successful live plan, it also needs
access to the six organization identity/backend secrets passed by the workflow,
and matching Azure planning federation. Environments belong to the caller
repository even when orchestration is shared. Platform-iac automatic enrollment
adds apply trust; planning trust requires explicit onboarding. Organization
secret access and Azure trust must be verified by a successful backend-connected
PR plan. No deployment workflow is enabled by this caller.
