module "dns_site" {
  source         = "./modules/imperva_managed_dns"
  domain_name    = "examplesite.com"
  owner_email    = "example@email.com"
  ddos_threshold = 50
  default_ttl    = 3600
  min_ttl        = 60
  api_id         = var.api_id
  api_key        = var.api_key
}
