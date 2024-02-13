resource "aws_efs_file_system" "web" {
  lifecycle_policy {
    transition_to_ia = var.transition_to_ia
  }
  encrypted        = var.efs_encrypted
  throughput_mode  = var.throughput_mode
  performance_mode = var.performance_mode

  tags = {
    Name = "HelloWorld"
  }
}

resource "aws_efs_mount_target" "web" {
  count = length(var.availability_zone)

  file_system_id = aws_efs_file_system.web.id
  subnet_id      = element(aws_subnet.web[*].id, count.index)
  security_groups = [
    aws_security_group.web.id,
    aws_security_group.efs.id
  ]
}

resource "aws_efs_backup_policy" "web" {
  file_system_id = aws_efs_file_system.web.id
  backup_policy {
    status = "DISABLED"
  }
}