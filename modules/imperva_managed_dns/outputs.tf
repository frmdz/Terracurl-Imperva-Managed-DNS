output "domain" {
  description = "Domain Name."
  value       = local.domain_name
}

output "managed_dns_domain_id" {
  description = "The ID of the managed DNS domain in Imperva."
  value       = local.managed_dns_domain_id
}

output "nameservers_records" {
  description = "Imperva nameservers for validation and onboarding."
  value       = local.configuration_status_details.impervaNsRecords
}

output "validation_records" {
  description = "Imperva records for domain validation."
  value       = local.configuration_status_details.validationRecord
}

output "configuration_status" {
  description = "Domain configuration status."
  value       = local.configuration_status_details.configurationStatus
}


