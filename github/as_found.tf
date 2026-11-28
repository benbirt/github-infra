# Settings as they exist on GitHub today where they differ from the defaults in
# repos.tf, so the initial import changes nothing. Remove each entry in its own
# pull request to review the change; delete this file once both locals are
# empty.

locals {
  as_found = {
    "git-witness" = {
      ruleset = false
    }
    # Trailing slash differs from repos.tf's https://<pages.domain>.
    eavesbard     = { homepage_url = "https://eavesbard.com/" }
    "tlog-viewer" = { homepage_url = "https://tlog.benbirt.io/" }
  }
}
