variable "api_id" {
  type        = string
  description = "API ID for Imperva API authentication."
  sensitive   = true
}

variable "api_key" {
  type        = string
  description = "API Key for Imperva API authentication."
  sensitive   = true
}

variable "domain_name" {
  type        = string
  description = "Domain name to manage in Imperva Managed DNS."
}

variable "ddos_threshold" {
  type        = number
  default     = 677
  description = "DDOS threshold for the managed domain."
}

variable "owner_email" {
  type        = string
  description = "Owner email for the managed domain."
}

variable "default_ttl" {
  type        = number
  default     = 200
  description = "Default TTL for DNS records."
}

variable "min_ttl" {
  type        = number
  default     = 10
  description = "Minimum TTL for DNS records."
}

variable "records" {
  type = map(object({
    id        = optional(number)
    name      = string
    type      = string
    classType = string
    ttl       = optional(number)
    data      = string
    comment   = optional(string)
  }))
  default = {}
}
