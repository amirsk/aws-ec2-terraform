resource "aws_instance" "web" {
  ami           = data.aws_ami.latest_amazon.id
  instance_type = var.instance_type
  key_name      = data.aws_key_pair.infra_key.key_name

  subnet_id              = aws_subnet.web.id
  vpc_security_group_ids = [aws_security_group.web.id]

  iam_instance_profile = aws_iam_instance_profile.web.name

  user_data = file(var.user_data)

  tags = {
    Name = "HelloWorld"
  }
}