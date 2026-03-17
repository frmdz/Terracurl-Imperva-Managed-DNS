output "domain" {
  description = "Domain Name."
  value       = module.dns_site.domain
}

output "managed_dns_domain_id" {
  description = "The ID of the managed DNS domain in Imperva."
  value       = module.dns_site.managed_dns_domain_id
}

output "nameservers_records" {
  description = "Imperva nameservers for validation and onboarding."
  value       = module.dns_site.nameservers_records
}

output "validation_records" {
  description = "Imperva records for domain validation."
  value       = module.dns_site.validation_records
}

output "configuration_status" {
  description = "Domain configuration status."
  value       = module.dns_site.configuration_status
}


