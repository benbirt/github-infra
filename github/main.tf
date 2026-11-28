# OpenTofu configuration for the managed repositories in repos.jsonnet.
# See github/BUILD.bazel for the Bazel targets and repos.tf for the managed
# settings.

terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.13.0"
    }
  }

  # State lives in Cloudflare R2 over its S3-compatible API, locked with an S3
  # lockfile rather than DynamoDB. The skip_* flags disable AWS-specific checks
  # and checksums that R2 does not support. Run tools/r2-keys.sh to derive
  # AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY from CLOUDFLARE_API_TOKEN.
  backend "s3" {
    bucket                      = "github-infra-tofu-state"
    key                         = "github/terraform.tfstate"
    region                      = "auto"
    endpoints                   = { s3 = "https://5154cc96c06ec81c712d8fd51a642c9c.eu.r2.cloudflarestorage.com" }
    use_lockfile                = true
    use_path_style              = true
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
  }
}

# Authenticates from GITHUB_TOKEN (set from the ADMIN_TOKEN secret in CI).
provider "github" {
  owner = "benbirt"
}
