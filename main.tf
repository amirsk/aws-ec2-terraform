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
resource "aws_vpc" "app_vpc" {
  cidr_block = "10.0.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Type = "Terraform"
    Name = "app_vpc"
  }
}

# Create an Internet Gateway for the VPC
resource "aws_internet_gateway" "app_internet_gateway" {
  vpc_id = aws_vpc.app_vpc.id

  tags = {
    Type = "Terraform"
    Name = "app_internet_gateway"
  }
}

# Create a subnet within the VPC
resource "aws_subnet" "app_subnet" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = local.availability_zone

  tags = {
    Type = "Terraform"
    Name = "app_server"
  }
}

# Create a route table for the VPC
resource "aws_route_table" "app_route_table" {
  vpc_id = aws_vpc.app_vpc.id

  # Add a route to the Internet Gateway for public internet access
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app_internet_gateway.id
  }
}

# Associate the route table with the subnet to enable outbound internet access for instances in the subnet
resource "aws_route_table_association" "app_server" {
  route_table_id = aws_route_table.app_route_table.id
  subnet_id      = aws_subnet.app_subnet.id
}

# Create a security group that allows incoming traffic
resource "aws_security_group" "app_security_group" {
  name   = "app_security_group"
  vpc_id = aws_vpc.app_vpc.id

  tags = {
    Type = "Terraform"
    Name = "app_security_group"
  }
}

# Define ingress rules for the security group
resource "aws_security_group_rule" "ssh_ingress" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app_security_group.id
}

resource "aws_security_group_rule" "http_ingress_80" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app_security_group.id
}

resource "aws_security_group_rule" "http_ingress_8080" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app_security_group.id
}

resource "aws_security_group_rule" "https_ingress" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app_security_group.id
}

# Define egress rule for the security group
resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app_security_group.id
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

# Create an EC2 instance with an IAM role for AWS Systems Manager Session Manager access
resource "aws_instance" "app_server_instance" {
  ami           = data.aws_ami.latest_amazon.id
  instance_type = "t2.micro"

  availability_zone           = local.availability_zone
  associate_public_ip_address = true

  subnet_id              = aws_subnet.app_subnet.id
  vpc_security_group_ids = [aws_security_group.app_security_group.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_s3_access_profile.name

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y

              # Install and configure the CodeDeploy
              sudo yum install -y ruby
              sudo yum install -y wget
              cd /home/ec2-user
              wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
              chmod +x ./install
              sudo ./install auto

              # Install and configure the unified CloudWatch agent
              sudo yum install -y amazon-cloudwatch-agent
              # Create the CloudWatch agent configuration file
              sudo tee /opt/aws/amazon-cloudwatch-agent/bin/config.json > /dev/null <<EOF_CONFIG
              {
                "logs": {
                  "logs_collected": {
                    "files": {
                      "collect_list": [
                        {
                          "file_path": "/home/ec2-user/app/log/app.log",
                          "log_group_name": "${aws_cloudwatch_log_group.app_server_logs.name}",
                          "log_stream_name": "${aws_cloudwatch_log_stream.app_server_log_stream.name}"
                        }
                      ]
                    }
                  }
                }
              }
              EOF_CONFIG
              # Start the CloudWatch agent
              sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s

              # Install and configure the the X-Ray daemon
              curl https://s3.dualstack.us-east-1.amazonaws.com/aws-xray-assets.us-east-1/xray-daemon/aws-xray-daemon-3.x.rpm -o /tmp/xray.rpm
              rpm -i /tmp/xray.rpm
              # Start the X-Ray daemon
              start /usr/bin/xray

              EOF

  tags = {
    Type = "Terraform"
    Name = "app_server_instance"
  }
}

# Create an IAM role for EC2 instances with access to Amazon S3
resource "aws_iam_role" "ec2_s3_access_role" {
  name = "EC2S3AccessRole"

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
  name = "EC2S3AccessPolicy"
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

# Create an IAM policy for CloudWatch Logs permissions
resource "aws_iam_role_policy" "ec2_cloudwatch_access_policy" {
  name = "EC2CloudWatchLogsPolicy"
  role = aws_iam_role.ec2_s3_access_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Create an IAM policy for XRay permissions
resource "aws_iam_role_policy" "ec2_xray_access_policy" {
  name = "EC2XRayAccessPolicy"
  role = aws_iam_role.ec2_s3_access_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
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

# Attach the AWSXRayDaemonWriteAccess policy to the IAM role
resource "aws_iam_role_policy_attachment" "xray_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
  role       = aws_iam_role.ec2_s3_access_role.name
}

# Create an IAM instance profile and associate it with the IAM role
resource "aws_iam_instance_profile" "ec2_s3_access_profile" {
  name = "EC2S3AccessProfile"
  role = aws_iam_role.ec2_s3_access_role.name
}

# Create an Elastic Block Store (EBS) volume
resource "aws_ebs_volume" "app_ebs_volume" {
  availability_zone = local.availability_zone
  size              = 5

  tags = {
    Type = "Terraform"
    Name = "app_ebs_volume"
  }
}

# Attach the EBS volume to the EC2 instance
resource "aws_volume_attachment" "app_ebs_attachment" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.app_ebs_volume.id
  instance_id = aws_instance.app_server_instance.id
}

# Create an S3 Bucket for storing the application artifacts
resource "aws_s3_bucket" "app_artifacts_bucket" {
  bucket = "aws-ec2-starter"

  tags = {
    Type = "Terraform"
    Name = "app_artifacts_bucket"
  }
}

# Create an IAM service role for AWS CodeDeploy
resource "aws_iam_role" "codedeploy_service_role" {
  name = "CodeDeployServiceRole"

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
resource "aws_codedeploy_app" "app_codedeploy_app" {
  name             = "aws-ec2-starter"
  compute_platform = "Server"
}

# Create an AWS CodeDeploy deployment group
resource "aws_codedeploy_deployment_group" "app_codedeploy_deployment_group" {
  app_name              = aws_codedeploy_app.app_codedeploy_app.name
  deployment_group_name = "AppDeploymentGroup"

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
}

# Create an AWS CloudWatch Logs log group
resource "aws_cloudwatch_log_group" "app_server_logs" {
  name              = "/EC2HelloWorld/Applogs"
  retention_in_days = 30
  tags = {
    Type = "Terraform"
    Name = "app_server_logs"
  }
}

# Create a log stream within the log group
resource "aws_cloudwatch_log_stream" "app_server_log_stream" {
  name           = "app-log-stream"
  log_group_name = aws_cloudwatch_log_group.app_server_logs.name
}