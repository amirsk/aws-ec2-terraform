resource "aws_ebs_volume" "web" {
  availability_zone = var.availability_zone
  size              = var.ebs_size
  type              = var.ebs_type
}

resource "aws_volume_attachment" "web_ebs" {
  device_name = var.device_name
  instance_id = aws_instance.web.id
  volume_id   = aws_ebs_volume.web.id
}

resource "aws_ebs_snapshot" "web_snapshot" {
  volume_id   = aws_ebs_volume.web.id
  description = "Test Snapshot"
}