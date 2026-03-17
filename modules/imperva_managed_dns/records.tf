

# Gets the records
# https://docs-cybersec.thalesgroup.com/bundle/api-docs/page/dns-api-definition.htm?operationId=operations-Primary_%28managed%29_Domain_DNS_Records-getRecords
data "terracurl_request" "get_dns_records" {
  name           = "Get DNS Records"
  url            = "https://api.imperva.com/dns/domain/${local.managed_dns_domain_id}/records"
  method         = "GET"
  headers        = local.api_headers
  response_codes = [200]

  depends_on = [data.terracurl_request.get_domain]
}

# Creates records
# https://docs-cybersec.thalesgroup.com/bundle/api-docs/page/dns-api-definition.htm?operationId=operations-Primary_%28managed%29_Domain_DNS_Records-addRecords
data "terracurl_request" "dns_create" {
  count          = length(local.records_to_create) > 0 ? 1 : 0
  name           = "Create DNS records"
  url            = "https://api.imperva.com/dns/domain/${local.managed_dns_domain_id}/records"
  method         = "POST"
  headers        = local.api_headers
  request_body   = jsonencode(local.records_to_create)
  response_codes = [200]

  depends_on = [data.terracurl_request.get_dns_records, data.terracurl_request.get_domain]
}

# Updates Records
# https://docs-cybersec.thalesgroup.com/bundle/api-docs/page/dns-api-definition.htm?operationId=operations-Primary_%28managed%29_Domain_DNS_Records-editRecords
data "terracurl_request" "dns_update" {
  count          = length(local.records_to_update) > 0 ? 1 : 0
  name           = "Update DNS records"
  url            = "https://api.imperva.com/dns/domain/${local.managed_dns_domain_id}/records"
  method         = "PUT"
  headers        = local.api_headers
  request_body   = jsonencode(local.records_to_update)
  response_codes = [200]

  depends_on = [data.terracurl_request.get_dns_records, data.terracurl_request.get_domain]
}

# Deletes Records
# https://docs-cybersec.thalesgroup.com/bundle/api-docs/page/dns-api-definition.htm?operationId=operations-Primary_%28managed%29_Domain_DNS_Records-deleteRecords
data "terracurl_request" "dns_delete" {
  count          = length(local.records_to_delete) > 0 ? 1 : 0
  name           = "Delete DNS records"
  url            = "https://api.imperva.com/dns/domain/${local.managed_dns_domain_id}/records?${join("&", [for r in local.records_to_delete : "record-ids=${r.id}"])}"
  method         = "DELETE"
  headers        = local.api_headers
  response_codes = [200]

  depends_on = [data.terracurl_request.get_dns_records, data.terracurl_request.get_domain]
}


locals {

  #Records normalized, the ones from the "vars", the ones you set on the code
  records_normalized = {
    for k, r in var.records :
    k => {
      name      = lower(trimsuffix(r.name, ".")) #removes the last "." if present
      type      = lower(r.type)
      classType = r.classType
      ttl       = r.ttl == null ? var.default_ttl : r.ttl
      data      = [r.data]
      comment   = r.comment != null && r.comment != "" ? r.comment : ""
    }
  }

  #Adds an "effective" id to the records_normalized, to allow for finding wheter the record is on the API results or not
  records_effective = {
    for k, r in local.records_normalized :
    k => merge(
      r,
      {
        effective_id = try(
          local.dns_records_by_identity[
            "${r.name}|${r.type}|${join(",", r.data)}"
          ].id,
          null
        )
      }
    )
  }

  #Maps the "identity" key we use to identify the records across both the API and code
  dns_records_by_identity = {
    for r in local.raw_records_normalized :
    "${r.name}|${r.type}|${join(",", tolist(r.data))}" => r
  }

  #Raw records, the ones obtained from the API
  dns_records_raw = jsondecode(data.terracurl_request.get_dns_records.response).value.dnsRecords

  #Raw records normalized
  raw_records_normalized = {
    for k, r in local.dns_records_raw :
    k => {
      id        = r.id
      name      = lower(trimsuffix(r.name, "."))
      type      = lower(r.type)
      classType = r.classType
      ttl       = r.ttl == null ? var.default_ttl : r.ttl
      data      = r.data
      comment   = r.comment
    }
  }

  #Records to create, if r.effective_id is null it means is not on the API result
  records_to_create = [
    for r in local.records_effective : {
      id        = 1
      name      = "${r.name}."
      type      = upper(r.type)
      classType = r.classType
      ttl       = r.ttl
      data      = r.data
      #Comment used as a workaround to only manage those records
      comment = length(r.comment) > 0 ? "${r.comment} | managed-by=terraform" : "managed-by=terraform"
    } if r.effective_id == null
  ]

  #Recrods to update, if r.effective_id is not null it means it was found on the API result
  records_to_update = [
    for r in local.records_effective : {
      id        = r.effective_id
      name      = "${r.name}."
      type      = upper(r.type)
      classType = r.classType
      ttl       = r.ttl
      data      = r.data
      #Comment used as a workaround to only manage those records
      comment = length(r.comment) > 0 ? "${r.comment}| managed-by=terraform" : "managed-by=terraform"
    } if r.effective_id != null
  ]

  #Intermediate value for a clean records_to_delete 
  desired_identities = [
    for r in local.records_effective :
    "${r.name}|${r.type}|${join(",", tolist(r.data))}"
  ]

  #If the record to add conteains the "magic comment" and is not on the effective records, then I can delete it it
  records_to_delete = [
    for r in local.raw_records_normalized :
    r if length(regexall("managed-by=terraform", r.comment)) > 0 &&
    !contains(local.desired_identities,
    "${r.name}|${r.type}|${join(",", sort(r.data))}")
  ]

  debug = jsonencode(local.records_to_create)

}
