# Create the VPC
resource "aws_vpc" "CAPSTONE" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"

  tags = {
    Name = "CAPSTONE"
  }
}

# Create the public subnet
resource "aws_subnet" "PUBLIC" {
  vpc_id     = aws_vpc.CAPSTONE.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.subnet_availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "PUBLIC-1"
  }
}

# Create the route table for the public subnet
resource "aws_route_table" "PUBLIC" {
  vpc_id = aws_vpc.CAPSTONE.id

  tags = {
    Name = "PUBLIC"
  }
}

# Associate the route table with the public subnet
resource "aws_route_table_association" "PUBLIC" {
  subnet_id      = aws_subnet.PUBLIC.id
  route_table_id = aws_route_table.PUBLIC.id
}

# Create an internet gateway
resource "aws_internet_gateway" "CAPSTONE" {
  vpc_id = aws_vpc.CAPSTONE.id

  tags = {
    Name = "CAPSTONE"
  }
}

# Create a default route to the internet via the internet gateway
resource "aws_route" "CAPSTONE" {
  route_table_id         = aws_route_table.PUBLIC.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.CAPSTONE.id
}

# Create a security group
resource "aws_security_group" "CAPSTONE" {
  name        = "CAPSTONE"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.CAPSTONE.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "Custom port 3000 from VPC"
    from_port        = 3000
    to_port          = 3000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "CAPSTONE"
  }
}

# Create an EC2 key pair
resource "aws_key_pair" "capstone" {
  key_name   = var.instance_key_name
  public_key = tls_private_key.capstone.public_key_openssh
}

# Create a TLS private key
resource "tls_private_key" "capstone" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create a local file containing the private key
resource "local_file" "capstone" {
  content  = tls_private_key.capstone.private_key_pem
  filename = "capstone.pem"
}

# Create an EC2 instance
resource "aws_instance" "CAPSTONE" {
  ami           = var.instance_ami
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.CAPSTONE.id]
  subnet_id     = aws_subnet.PUBLIC.id
  key_name      = var.instance_key_name

  tags = {
    Name = "CAPSTONE-PUBLIC"
  }
}
