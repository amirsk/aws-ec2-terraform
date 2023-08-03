#############################
# VPC
#############################
output "vpc_id" {
  value = aws_vpc.app_server.id
}

#############################
# Internet Gateway
#############################
output "internet_gateway_id" {
  value = aws_internet_gateway.app_server.id
}

#############################
# Subnet
#############################
output "subnet_id" {
  value = aws_subnet.app_server.id
}

#############################
# Route Table
#############################
output "route_table_id" {
  value = aws_route_table.app_server.id
}

#############################
# Security Group
#############################
output "security_group_id" {
  value = aws_security_group.app_server.id
}

#############################
# EC2
#############################
output "aws_instance_id" {
  value = aws_instance.app_server.id
}

output "aws_instance_arn" {
  value = aws_instance.app_server.arn
}

output "aws_instance_private_dns" {
  value = aws_instance.app_server.private_dns
}

output "aws_instance_public_dns" {
  value = aws_instance.app_server.public_dns
}

output "aws_instance_private_ip" {
  value = aws_instance.app_server.private_ip
}

output "aws_instance_public_ip" {
  value = aws_instance.app_server.public_ip
}

#############################
# EBS
#############################
output "ebs_volume_id" {
  description = "The ID of the EBS volume."
  value       = aws_ebs_volume.app_server.id
}

output "ebs_volume_size" {
  description = "The size of the EBS volume in GB."
  value       = aws_ebs_volume.app_server.size
}

#############################
# S3
#############################
output "s3_bucket_name" {
  value = aws_s3_bucket.app_server.bucket
}

#############################
# CodeDeploy
#############################
output "code_deploy_app_name" {
  value = aws_codedeploy_app.aws-ec2-starter-app.name
}

output "code_deploy_deployment_group_name" {
  value = aws_codedeploy_deployment_group.aws-ec2-starter-deployment_group.deployment_group_name
}