name_prefix = "model-gateway"
region      = "eu-west-2"

processing_regions = [
  "eu-central-1",
  "eu-north-1",
  "eu-south-1",
  "eu-south-2",
  "eu-west-1",
  "eu-west-2",
  "eu-west-3",
]

ownership_tag = {
  key   = "project"
  value = "model-gateway"
}

tags = {
  project    = "model-gateway"
  managed_by = "terraform"
}
