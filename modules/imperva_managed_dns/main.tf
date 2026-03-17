terraform {
  required_providers {
    terracurl = {
      source  = "devops-rob/terracurl"
      version = "2.1.0"
    }

  }
}

# request headers for API calls
locals {
  api_headers = {
    Content-Type = "application/json"
    x-API-Id     = var.api_id
    x-API-Key    = var.api_key
  }
}


