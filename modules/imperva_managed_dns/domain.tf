
# Get domains onboarded to Imperva Managed DNS
data "terracurl_request" "get_domain" {
  name = "Get domains"

  # https://docs-cybersec.thalesgroup.com/bundle/api-docs/page/dns-api-definition.htm?operationId=operations-Protected_Domain_V3-getAllProtectedDomains
  url            = "https://api.imperva.com/dns/v3/domains/primary"
  method         = "GET"
  headers        = local.api_headers
  response_codes = [200]
}

# Finds the ID for the `domain_name` give as an input, null if not found/onboarded
locals {
  domain_map = {
    for d in jsondecode(data.terracurl_request.get_domain.response).data :
    d.name => d.id
  }

  managed_dns_domain_id = lookup(local.domain_map, var.domain_name, null)
}

# Resource for Create or Edit domains, if `local.managed_dns_domain_id` is null, creates a new one, otherwise assumes the domain was onboarded 
resource "terracurl_request" "managed_dns" {
  name = var.domain_name

  # POST https://docs-cybersec.thalesgroup.com/bundle/api-docs/page/dns-api-definition.htm?operationId=operations-Protected_Domain_V3-addProtectedDomain
  # PUT https://docs-cybersec.thalesgroup.com/bundle/api-docs/page/dns-api-definition.htm?operationId=operations-Protected_Domain_V3-fullEditProtectedDomain

  url            = "https://api.imperva.com/dns/v3/domains/primary${local.managed_dns_domain_id == null ? "" : "/${local.managed_dns_domain_id}"}"
  method         = local.managed_dns_domain_id == null ? "POST" : "PUT"
  headers        = local.api_headers
  response_codes = [201, 200]

  request_body = jsonencode({
    name          = var.domain_name
    ddosThreshold = var.ddos_threshold
    ownerEmail    = var.owner_email
    defaultTtl    = var.default_ttl
    minTtl        = var.min_ttl
  })

  lifecycle {
    ignore_changes = [url, method]
  }
}

#Dummy resource to be able to destroy the resource, upon creations just get the list of onboarded sites, unpon deletion deletes `local.managed_dns_domain_id`
resource "terracurl_request" "managed_dns_destroy" {
  name = "Get domains"

  # This is a dummy request to get the domains just to be able to have the domain destroyed, when this resoursce is destroyed
  # https://docs-cybersec.thalesgroup.com/bundle/api-docs/page/dns-api-definition.htm?operationId=operations-Protected_Domain_V3-getAllProtectedDomains
  url            = "https://api.imperva.com/dns/v3/domains/primary"
  method         = "GET"
  headers        = local.api_headers
  response_codes = [200]
  max_retry      = 1

  # This is the actual good stuff, when destroying this resource, the API call to delete the domain is done.
  # https://docs-cybersec.thalesgroup.com/bundle/api-docs/page/dns-api-definition.htm?operationId=operations-Protected_Domain_V3-deleteProtectedDomain
  destroy_url            = "https://api.imperva.com/dns/v3/domains/primary/${local.managed_dns_domain_id == null ? "" : local.managed_dns_domain_id}"
  destroy_method         = "DELETE"
  destroy_headers        = local.api_headers
  destroy_response_codes = [200]
  destroy_max_retry      = 1

  lifecycle {
    ignore_changes = [url, destroy_url]
  }
}

# locals to be used for outputs
locals {
  configuration_status_details = jsondecode(terracurl_request.managed_dns.response).data[0].configurationStatusDetails
  domain_name                  = var.domain_name
}
