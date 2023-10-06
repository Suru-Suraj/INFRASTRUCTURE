# Create the VPC
resource "aws_vpc" "CAPSTONE" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"

  tags = {
    Name = "CAPSTONE"
  }
}

# Create public subnets
resource "aws_subnet" "PUBLIC-1" {
  vpc_id                  = aws_vpc.CAPSTONE.id
  cidr_block              = var.subnet_cidr_blocks["public1"]
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "PUBLIC-1"
  }
}

resource "aws_subnet" "PUBLIC-2" {
  vpc_id                  = aws_vpc.CAPSTONE.id
  cidr_block              = var.subnet_cidr_blocks["public2"]
  availability_zone       = var.availability_zones[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "PUBLIC-2"
  }
}

# Create private subnet
resource "aws_subnet" "PRIVATE" {
  vpc_id          = aws_vpc.CAPSTONE.id
  cidr_block      = var.subnet_cidr_blocks["private"]
  availability_zone = var.availability_zones[2]

  tags = {
    Name = "PRIVATE"
  }
}

# Create route tables
resource "aws_route_table" "PUBLIC" {
  vpc_id = aws_vpc.CAPSTONE.id

  tags = {
    Name = "PUBLIC"
  }
}

resource "aws_route_table" "PRIVATE" {
  vpc_id = aws_vpc.CAPSTONE.id

  tags = {
    Name = "PRIVATE"
  }
}

# Create route table associations
resource "aws_route_table_association" "PUBLIC-1" {
  subnet_id      = aws_subnet.PUBLIC-1.id
  route_table_id = aws_route_table.PUBLIC.id
}

resource "aws_route_table_association" "PUBLIC-2" {
  subnet_id      = aws_subnet.PUBLIC-2.id
  route_table_id = aws_route_table.PUBLIC.id
}

resource "aws_route_table_association" "PRIVATE" {
  subnet_id      = aws_subnet.PRIVATE.id
  route_table_id = aws_route_table.PRIVATE.id
}

# Create an internet gateway
resource "aws_internet_gateway" "CAPSTONE" {
  vpc_id = aws_vpc.CAPSTONE.id

  tags = {
    Name = "CAPSTONE"
  }
}

# Create a route for internet traffic
resource "aws_route" "internet_gateway_route" {
  route_table_id         = aws_route_table.PUBLIC.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.CAPSTONE.id
}

# Create an Elastic IP
resource "aws_eip" "CAPSTONE" {
  domain = "vpc"

  tags = {
    Name = "CAPSTONE"
  }
}

# Create a NAT gateway
resource "aws_nat_gateway" "CAPSTONE" {
  allocation_id = aws_eip.CAPSTONE.id
  subnet_id     = aws_subnet.PUBLIC-1.id

  tags = {
    Name = "CAPSTONE"
  }
}

# Create a route for private subnet traffic through the NAT gateway
resource "aws_route" "CAPSTONE" {
  route_table_id          = aws_route_table.PRIVATE.id
  destination_cidr_block  = "0.0.0.0/0"
  nat_gateway_id          = aws_nat_gateway.CAPSTONE.id
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
  ami           = var.ami_id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.CAPSTONE.id]
  subnet_id = aws_subnet.PRIVATE.id
  key_name = var.instance_key_name

  tags = {
    Name = "CAPSTONE-PRIVATE"
  }
}

# Create a Application load balancer
resource "aws_lb" "CAPSTONE" {
  name               = "CAPSTONE"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.CAPSTONE.id]
  subnets            = [aws_subnet.PRIVATE.id, aws_subnet.PUBLIC-2.id, aws_subnet.PUBLIC-1.id]
  enable_cross_zone_load_balancing = true
  enable_deletion_protection = false
  tags = {
    Environment = "production"
  }
}

# Create a listener for the ALB
resource "aws_lb_listener" "CAPSTONE" {
  load_balancer_arn = aws_lb.CAPSTONE.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.CAPSTONE.arn
  }
}

# Create a target group for the ALB
resource "aws_lb_target_group" "CAPSTONE" {
  name        = "CAPSTONE"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.CAPSTONE.id
  target_type = "instance"
  health_check {
    port     = 80
    protocol = "HTTP"
  }
}

# Register instances with the target group (e.g., your EC2 instances)
resource "aws_lb_target_group_attachment" "CAPSTONE" {
  count             = aws_autoscaling_group.CAPSTONE.desired_capacity
  target_group_arn  = aws_lb_target_group.CAPSTONE.arn
  target_id         = aws_instance.CAPSTONE.id
}

# Create a launch template
resource "aws_launch_template" "CAPSTONE" {
  name_prefix   = "CAPSTONE"
  image_id      = var.ami_id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.CAPSTONE.id]
  key_name = var.instance_key_name
}

# Update your autoscaling group to use the NLB target group
resource "aws_autoscaling_group" "CAPSTONE" {
  vpc_zone_identifier = [aws_subnet.PRIVATE.id]
  desired_capacity   = 2
  max_size           = 3
  min_size           = 2

  target_group_arns = [aws_lb_target_group.CAPSTONE.arn]

  launch_template {
    id      = aws_launch_template.CAPSTONE.id
    version = "$Latest"
  }
}