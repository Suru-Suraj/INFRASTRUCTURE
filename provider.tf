terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
      region = "us-east-1"
    }
    local = {
      source = "hashicorp/local"
      version = "~> 3.0"
    }
    tls = {
      source = "hashicorp/tls"
      version = "~> 3.0"
    }
  }
}
