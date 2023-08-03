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

  iam_instance_profile = aws_iam_instance_profile.ec2_s3_access_profile.name

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y ruby
              sudo yum install -y wget
              cd /home/ec2-user
              wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
              chmod +x ./install
              sudo ./install auto
              EOF

  tags = {
    Type = "Terraform"
    Name = "app_server"
  }
}

# Create an IAM role for EC2 instances with access to Amazon S3
resource "aws_iam_role" "ec2_s3_access_role" {
  name = "CodeDeployDemo-EC2-Instance-Profile"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach a policy to the IAM role to grant S3 access
resource "aws_iam_role_policy" "ec2_s3_access_policy" {
  name = "CodeDeployDemo-EC2-Permissions"
  role = aws_iam_role.ec2_s3_access_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:Get*", "s3:List*"]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach the AmazonSSMManagedInstanceCore policy to the IAM role
resource "aws_iam_role_policy_attachment" "ec2_ssm_managed_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ec2_s3_access_role.name
}

# Create an IAM instance profile and associate it with the IAM role
resource "aws_iam_instance_profile" "ec2_s3_access_profile" {
  name = "CodeDeployDemo-EC2-Instance-Profile"
  role = aws_iam_role.ec2_s3_access_role.name
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

# Create an S3 Bucket for storing the application artifacts
resource "aws_s3_bucket" "app_server" {
  bucket = "aws-ec2-starter"

  tags = {
    Type = "Terraform"
    Name = "app_server"
  }
}

# Create an IAM service role for AWS CodeDeploy
resource "aws_iam_role" "codedeploy_service_role" {
  name = "code_deploy_service_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the AWSCodeDeployRole policy to the IAM role
resource "aws_iam_role_policy_attachment" "codedeploy_service_role_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.codedeploy_service_role.name
}

# Create an AWS CodeDeploy application
resource "aws_codedeploy_app" "aws-ec2-starter-app" {
  name             = "aws-ec2-starter"
  compute_platform = "Server"
}

# Create an AWS CodeDeploy deployment group
resource "aws_codedeploy_deployment_group" "aws-ec2-starter-deployment_group" {
  app_name              = aws_codedeploy_app.aws-ec2-starter-app.name
  deployment_group_name = "AwsEc2StarterDeploymentGroup"

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Type"
      type  = "KEY_AND_VALUE"
      value = "Terraform"
    }
  }

  service_role_arn = aws_iam_role.codedeploy_service_role.arn

  deployment_config_name = "CodeDeployDefault.OneAtATime"

  # Specify the S3 bucket and object key where deployment artifacts are stored


}