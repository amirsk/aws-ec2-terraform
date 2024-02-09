output "ec2_id" {
  value = aws_instance.web.id
}

output "public_dns" {
  value = aws_instance.web.public_dns
}

output "ami_id" {
  value = data.aws_ami.latest_amazon.id
}

output "ec2_key_name" {
  value = data.aws_key_pair.infra_key.key_name
}

output "vpc_id" {
  value = aws_vpc.web.id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.web.id
}

output "subnet_id" {
  value = aws_subnet.web.id
}

output "route_table_id" {
  value = aws_route_table.web.id
}

output "security_group_id" {
  value = aws_security_group.web.id
}

output "ingress_rule_id" {
  value = [for k, v in aws_vpc_security_group_ingress_rule.ingress_rule : v.id]
}

output "egress_rule_id" {
  value = [for k, v in aws_vpc_security_group_egress_rule.egress_rule : v.id]
}

output "role_id" {
  value = aws_iam_role.ec2_role.id
}

output "policy_id" {
  value = aws_iam_policy.iam_allow.id
}

output "web_instance_profile_id" {
  value = aws_iam_instance_profile.web.id
}