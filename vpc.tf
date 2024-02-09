resource "aws_vpc" "web" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_internet_gateway" "web" {
  vpc_id = aws_vpc.web.id
}

resource "aws_subnet" "web" {
  vpc_id                  = aws_vpc.web.id
  cidr_block              = var.public_subnet_cidr_block
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true
}

resource "aws_route_table" "web" {
  vpc_id = aws_vpc.web.id
  route {
    cidr_block = var.public_route_table_cidr_block
    gateway_id = aws_internet_gateway.web.id
  }
}

resource "aws_route_table_association" "app_server" {
  route_table_id = aws_route_table.web.id
  subnet_id      = aws_subnet.web.id
}

resource "aws_security_group" "web" {
  name        = "Web"
  description = "Web Security Group"
  vpc_id      = aws_vpc.web.id
}

resource "aws_vpc_security_group_ingress_rule" "ingress_rule" {
  security_group_id = aws_security_group.web.id

  for_each = { for idx, item in var.ingress_rules : idx => item }

  cidr_ipv4   = each.value.cidr_ipv4
  from_port   = each.value.from_port
  ip_protocol = each.value.ip_protocol
  to_port     = each.value.to_port
  description = each.value.description
}

resource "aws_vpc_security_group_egress_rule" "egress_rule" {
  security_group_id = aws_security_group.web.id

  for_each = { for idx, item in var.egress_rules : idx => item }

  cidr_ipv4   = each.value.cidr_ipv4
  ip_protocol = each.value.ip_protocol
  description = each.value.description
}