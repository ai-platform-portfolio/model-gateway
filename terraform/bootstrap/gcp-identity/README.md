# Google identity bootstrap

Thin calls to platform-iac modules enable the Agent Platform and supporting APIs,
create separate GitHub Plan/Apply federation identities, and configure the shared
Azure managed identity for inference using a dedicated Entra audience, Google
workload identity federation and an inference-only service account. No client
secret, service-account key or new Azure managed identity is created.

Use the existing administrator Google and Azure CLI sessions. Pass project ID,
managed identity object ID, exact customized GitHub subjects and immutable
repository/owner IDs through `TF_VAR_*`. Supply the short-lived Google access
token through `GOOGLE_OAUTH_ACCESS_TOKEN` in process memory. Backend metadata is
also supplied externally. Do not write credential tfvars or JSON variable files.

Initialize with `backend.hcl` plus external Azure backend arguments, then plan
with `bootstrap.tfvars` and a saved plan outside the repository. Review and apply
that Terraform plan using the administrator sessions. This root uses separate
remote state; it is not another workload deployment workflow. Workload Apply
cannot change project IAM, federation trust or its own privileges.

Store `GOOGLE_PROJECT_ID`, the phase-specific `GOOGLE_WORKLOAD_IDENTITY_PROVIDER`,
and `GOOGLE_PLAN_SERVICE_ACCOUNT`/`GOOGLE_APPLY_SERVICE_ACCOUNT` in the matching
GitHub environments after bootstrap. The official Google authentication action
obtains short-lived tokens without writing a credential file, and the normal
reusable workflow retains exactly Plan and manually approved main-only Apply.

Runtime output metadata is for the later APIM policy fragments: acquire the
dedicated Entra audience token, exchange with Google STS, impersonate the scoped
inference account, and renew OAuth tokens before expiry. Private cross-cloud
transport, DNS forwarding, APIM model routing and Foundry BYOM connections must be
completed before application workloads can use Gemini through the gateway.
