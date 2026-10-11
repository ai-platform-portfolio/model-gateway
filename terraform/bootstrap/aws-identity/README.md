# AWS deployment identity bootstrap

This root only calls the shared platform-iac identity module. Its separate Azure
state prevents workload Apply from modifying the roles used to authenticate it.
The normal workload pipeline remains Plan and Apply; this is a one-time bootstrap,
not another deployment workflow.

Use an existing AWS administrator session and Azure CLI login. Pass account ID,
exact GitHub environment OIDC subjects and the Entra issuer through `TF_VAR_*`
environment variables. Pass backend resource group, storage account and container
through init arguments or environment-held configuration. Do not create credential
tfvars, JSON input files or access-key secrets.

Run `terraform init -backend-config=backend.hcl` with the external backend values,
then `terraform plan -var-file=bootstrap.tfvars -out=APPROVED_PLAN_PATH`.
Review the IAM changes before applying that saved plan. Keep saved plans outside
the repository because they include identity metadata.

After approval and apply, configure the sensitive output role ARNs in the matching
GitHub environments, with the externally supplied expected account ID. Enable
`aws-region` in the existing infrastructure caller only after the roles exist.
The runtime boundary permits model invocation in the listed UK/EU regions; runtime
policies will narrow that further to the chosen model profiles and private endpoint.

Private AWS endpoints alone do not connect Azure to AWS. Transport, private DNS and
runtime federation must be completed before APIM can invoke Bedrock privately.

Bootstrap applied on 2026-10-11: six IAM resources created and the follow-up plan
reported no changes. Account and environment-specific role references are stored
as GitHub environment secrets. Future bootstrap changes use this same Terraform
root and remote state with an administrator session; workload roles cannot modify
their own deployment permissions.
