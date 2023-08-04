#############################
# VPC
#############################
output "vpc_id" {
  value = aws_vpc.app_vpc.id
}

#############################
# Internet Gateway
#############################
output "internet_gateway_id" {
  value = aws_internet_gateway.app_internet_gateway.id
}

#############################
# Subnet
#############################
output "subnet_id" {
  value = aws_subnet.app_subnet.id
}

#############################
# Route Table
#############################
output "route_table_id" {
  value = aws_route_table.app_route_table.id
}

#############################
# Security Group
#############################
output "security_group_id" {
  value = aws_security_group.app_security_group.id
}

#############################
# EC2
#############################
output "aws_instance_id" {
  value = aws_instance.app_server_instance.id
}

output "aws_instance_arn" {
  value = aws_instance.app_server_instance.arn
}

output "aws_instance_private_dns" {
  value = aws_instance.app_server_instance.private_dns
}

output "aws_instance_public_dns" {
  value = aws_instance.app_server_instance.public_dns
}

output "aws_instance_private_ip" {
  value = aws_instance.app_server_instance.private_ip
}

output "aws_instance_public_ip" {
  value = aws_instance.app_server_instance.public_ip
}

#############################
# EBS
#############################
output "ebs_volume_id" {
  description = "The ID of the EBS volume."
  value       = aws_ebs_volume.app_ebs_volume.id
}

output "ebs_volume_size" {
  description = "The size of the EBS volume in GB."
  value       = aws_ebs_volume.app_ebs_volume.size
}

#############################
# S3
#############################
output "s3_bucket_name" {
  value = aws_s3_bucket.app_artifacts_bucket.bucket
}

#############################
# CodeDeploy
#############################
output "code_deploy_app_name" {
  value = aws_codedeploy_app.app_codedeploy_app.name
}

output "code_deploy_deployment_group_name" {
  value = aws_codedeploy_deployment_group.app_codedeploy_deployment_group.deployment_group_name
}