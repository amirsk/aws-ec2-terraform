terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"

}

provider "aws" {
  region = "us-east-1"
}

locals {
  availability_zone = "us-east-1a"
}

# Create a VPC
resource "aws_vpc" "app_server" {
  cidr_block = "10.0.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Type = "Terraform"
    Name = "app_server"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "app_server" {
  vpc_id = aws_vpc.app_server.id

  tags = {
    Type = "Terraform"
    Name = "app_server"
  }
}

# Create a subnet within the VPC
resource "aws_subnet" "app_server" {
  vpc_id            = aws_vpc.app_server.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = local.availability_zone

  tags = {
    Type = "Terraform"
    Name = "app_server"
  }
}

# Create a route table
resource "aws_route_table" "app_server" {
  vpc_id = aws_vpc.app_server.id

  # Add a route to the Internet Gateway for public internet access
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app_server.id
  }
}

# Associate the route table with the subnet to enable outbound internet access for instances in the subnet
resource "aws_route_table_association" "app_server" {
  route_table_id = aws_route_table.app_server.id
  subnet_id      = aws_subnet.app_server.id
}

# Create a security group that allows incoming traffic
resource "aws_security_group" "app_server" {
  name   = "app_server"
  vpc_id = aws_vpc.app_server.id

  tags = {
    Type = "Terraform"
    Name = "app_server"
  }
}

# Define ingress rules for the security group
resource "aws_security_group_rule" "ssh_ingress" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app_server.id
}

resource "aws_security_group_rule" "http_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app_server.id
}

resource "aws_security_group_rule" "https_ingress" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app_server.id
}

# Define egress rule for the security group
resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app_server.id
}

data "aws_ami" "latest_amazon" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0*x86_64-gp2"]
  }
}

# Create an EC2 instance with an IAM role for AWS Session Manager access
resource "aws_instance" "app_server" {
  ami           = data.aws_ami.latest_amazon.id
  instance_type = "t2.micro"

  availability_zone           = local.availability_zone
  associate_public_ip_address = true

  subnet_id              = aws_subnet.app_server.id
  vpc_security_group_ids = [aws_security_group.app_server.id]

  tags = {
    Type = "Terraform"
    Name = "app_server"
  }
}

# Create an Elastic Block Store (EBS) volume
resource "aws_ebs_volume" "app_server" {
  availability_zone = local.availability_zone
  size              = 5

  tags = {
    Type = "Terraform"
    Name = "app_server"
  }
}

# Attach the EBS volume to the EC2 instance
resource "aws_volume_attachment" "app_server" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.app_server.id
  instance_id = aws_instance.app_server.id
}