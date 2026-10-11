# Model Gateway Azure deployment

This root calls platform-iac network, identity and APIM modules at a full commit SHA.
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
on the integration subnet. The network module owns its NSG and optional routes. The APIM NSG explicitly
allows Key Vault and Entra HTTPS. Azure-provided DNS is platform traffic and
is not subject to ordinary NSG rules; AzurePlatformDNS supports explicit denial,
not Allow rules. No platform-DNS deny is configured. An explicit
priority-4096 deny overrides the broad default VNet/internet outbound allows.
Backend destinations must be allowed before introducing inference workloads.
No route table is created until a next hop is required. The private DNS zone is
linked to this VNet; remote clients will need DNS forwarding/linking and network
connectivity to reach the private endpoint. This does not create cross-cloud transport.

A separate identity module creates the shared environment identity alongside the
network; APIM receives its ID. Future Azure resources can use the same identity
and narrowly scoped role assignments. APIM is StandardV2_1 in UK West, with an
inbound private endpoint and outbound VNet integration. Public access is disabled
after endpoint creation. Service operation timeouts use module defaults and can
be overridden through `apim.timeouts`.

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
Review the live plan before deployment. The existing network is deployed; this APIM change has not applied resources.

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

## APIM publisher inputs (AI-33)

Configure `publisher_name` and `publisher_email` in `environments/uk-west.tfvars`.
These are publisher contact metadata. Credentials and cloud identity values
remain external. The existing reusable workflow reads the environment tfvars;
no additional secret or JSON file is required.

APIM backend policies and scoped AI platform access follow in AI-34; this stage
creates no inference APIs. All three module calls pin the same merged
platform-iac revision.

## Baseline private endpoint security

The private endpoint subnet uses `NetworkSecurityGroupEnabled` and a dedicated
NSG. It initially denies all client access and new outbound connections; stateful
responses to subsequently allowed inbound connections do not require a new
outbound allow. Add higher-priority inbound TCP 443 rules for confirmed Envoy or
other approved client subnet CIDRs when those clients are introduced. There is
currently no deployed AKS cluster in the selected subscription, so no client CIDR
is invented. A closed gateway can be provisioned before workloads are configured.

The live plan must retain the existing UK West network and add the identity,
NSGs, DNS link, APIM and private endpoint. No classic APIM management bypass
route or broad AzureCloud/internet allow is added. This baseline creates no
firewall, peering or external client DNS path. Validate private connectivity from
an explicitly allowed client when it is configured, and confirm public requests
are rejected after deployment.

The subnet policy enhancement is platform-iac PR #20; merge it before this
consumer PR. The shared workflow failure-propagation fix is already merged in
ops-shared PR #8. Dummy publisher metadata is configured in the environment tfvars as authorised
for this demo. Replace it with a monitored contact before production use.

## Azure AI platform (AI-34, first cloud)

The Foundry module creates a private AIServices account and project in UK South,
reusing the environment managed identity. Its endpoint lives in a dedicated UK
West subnet (`10.60.5.0/24`) with only APIM-to-Foundry TCP 443 permitted. The network
module creates and links all three Foundry private DNS zones.

The environment selects a pinned `gpt-4.1-mini` regional `Standard` deployment
with capacity 10. Live UK South availability and unused quota were checked on
2026-10-11. The model map remains replaceable; no global or data-zone processing
is approved by this environment. Account keys and public access are disabled;
APIM's shared identity receives account-scoped inference access.

Apply provisions inference infrastructure. APIM backend APIs and managed-identity
policies, AWS/GCP federation and cross-cloud transport remain subsequent AI-34
work. Private inference and DNS need runtime validation from a connected client;
GitHub-hosted runners cannot reach these private endpoints. Terraform planning
uses Azure's control plane and does not require model API keys.
## AWS Bedrock foundation (AI-34)

The AWS network and Bedrock modules use the same existing workload pipeline and
Azure backend state. `AWS_ACCOUNT_ID` comes from the GitHub environment, with
separate OIDC Plan/Apply roles. No access keys, profile ARN/account IDs or JSON
variable files are committed.

The London VPC uses `10.70.0.0/16`, separate from the Azure networks, with private
endpoint subnets in two availability zones. Bedrock Runtime and regional STS
interface endpoints accept HTTPS only from the APIM subnet. Both endpoint policies
explicitly deny all access until the separately provisioned runtime federation role
is wired in. The Claude application inference profile copies the reviewed EU
system profile, with every live target model region checked against the tfvars
processing allowlist.

This provisions the private AWS foundation only. Private circuits/IPsec, routing,
DNS forwarding, Entra federation, APIM signing/renewal and model agreement/inference
entitlement checks remain necessary before runtime use. No public fallback is
created. Interface endpoints incur charges when deployed; no model capacity is
reserved and this configuration does not send inference requests.

The client CIDRs derive from the configured APIM subnet; an explicit override is
available when private transport applies source NAT. Before workload Apply, review
and apply the bootstrap root's single inline-policy update for owned network
dependency permissions. The bootstrap state and workload state remain separate.
