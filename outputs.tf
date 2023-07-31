################################################################################
# EC2
################################################################################
output "id" {
  value = aws_instance.app_server.id
}

output "arn" {
  value = aws_instance.app_server.arn
}

output "private_dns" {
  value = aws_instance.app_server.private_dns
}

output "public_dns" {
  value = aws_instance.app_server.public_dns
}

output "private_ip" {
  value = aws_instance.app_server.private_ip
}

output "public_ip" {
  value = aws_instance.app_server.public_ip
}

################################################################################
# Block Devices
################################################################################
output "ebs_volume_id" {
  description = "The ID of the EBS volume."
  value       = aws_ebs_volume.app_server.id
}

output "ebs_volume_size" {
  description = "The size of the EBS volume in GB."
  value       = aws_ebs_volume.app_server.size
}