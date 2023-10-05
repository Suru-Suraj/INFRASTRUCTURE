# VPC Settings
variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Subnet Settings
variable "subnet_cidr_block" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_availability_zone" {
  description = "Availability Zone for the public subnet"
  type        = string
  default     = "us-east-1a"
}

# Security Group Settings
variable "allowed_ports" {
  description = "List of allowed ports for the security group"
  type        = list(number)
  default     = [22, 80, 443, 3000]
}

# EC2 Instance Settings
variable "instance_ami" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-053b0d53c279acc90"
}

variable "instance_key_name" {
  description = "Name of the EC2 key pair"
  type        = string
  default     = "capstone"
}

variable "instance_type" {
  description = "Instance type for the EC2 instance"
  type        = string
  default     = "t2.micro"
}
