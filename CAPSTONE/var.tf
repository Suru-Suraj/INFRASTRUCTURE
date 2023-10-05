# AWS Region
variable "aws_region" {
  description = "The AWS region where resources will be created."
  default     = "us-east-1"
}

# VPC CIDR Block
variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC."
  default     = "10.0.0.0/16"
}

# Subnet CIDR Blocks
variable "subnet_cidr_blocks" {
  description = "A map of subnet CIDR blocks."
  type        = map(string)
  default = {
    public1 = "10.0.1.0/24"
    public2 = "10.0.2.0/24"
    private = "10.0.3.0/24"
  }
}

# Availability Zones
variable "availability_zones" {
  description = "A list of availability zones for subnets."
  type        = list(string)
  default = [
    "us-east-1a",
    "us-east-1b",
    "us-east-1c",
  ]
}

variable "instance_key_name" {
  description = "Name of the EC2 key pair"
  type        = string
  default     = "capstone"
}

# Instance Type
variable "instance_type" {
  description = "The EC2 instance type."
  default     = "t2.micro"
}

# AMI ID
variable "ami_id" {
  description = "The ID of the Amazon Machine Image (AMI)."
}