terraform {
  required_version = ">= 0.13"
  required_providers {
    null = {
      source = "hashicorp/null"
    }
    time = {
      source = "hashicorp/time"
    }
    rke = {
      source = "rancher/rke"
    }
  }
}
