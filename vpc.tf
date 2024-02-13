resource "aws_vpc" "web" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "HelloWorld"
  }
}

resource "aws_internet_gateway" "web" {
  vpc_id = aws_vpc.web.id

  tags = {
    Name = "HelloWorld"
  }
}

resource "aws_subnet" "web" {
  count = length(var.public_subnet_cidr_block)

  vpc_id                  = aws_vpc.web.id
  cidr_block              = element(var.public_subnet_cidr_block, count.index)
  availability_zone       = element(var.availability_zone, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "HelloWorld${count.index}"
  }
}

resource "aws_route_table" "web" {
  count = length(var.public_subnet_cidr_block)

  vpc_id = aws_vpc.web.id

  tags = {
    Name = "HelloWorld${count.index}"
  }
}

resource "aws_route" "web" {
  count = length(var.public_subnet_cidr_block)

  route_table_id         = element(aws_route_table.web[*].id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.web.id
}

resource "aws_route_table_association" "app_server" {
  count = length(var.public_subnet_cidr_block)

  subnet_id      = element(aws_subnet.web[*].id, count.index)
  route_table_id = element(aws_route_table.web[*].id, count.index)
}

resource "aws_security_group" "web" {
  name        = "Web"
  description = "Web Security Group"
  vpc_id      = aws_vpc.web.id

  tags = {
    Name = "HelloWorldWeb"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ingress_rule" {
  security_group_id = aws_security_group.web.id

  for_each = { for idx, item in var.ingress_rules : idx => item }

  cidr_ipv4   = each.value.cidr_ipv4
  from_port   = each.value.from_port
  ip_protocol = each.value.ip_protocol
  to_port     = each.value.to_port
  description = each.value.description

  tags = {
    Name = "HelloWorldWeb"
  }
}

resource "aws_vpc_security_group_egress_rule" "egress_rule" {
  security_group_id = aws_security_group.web.id

  for_each = { for idx, item in var.egress_rules : idx => item }

  cidr_ipv4   = each.value.cidr_ipv4
  ip_protocol = each.value.ip_protocol
  description = each.value.description

  tags = {
    Name = "HelloWorldWeb"
  }
}

resource "aws_security_group" "efs" {
  name        = "EFS"
  description = "EFS Security Group"
  vpc_id      = aws_vpc.web.id

  tags = {
    Name = "HelloWorldEFS"
  }
}

resource "aws_vpc_security_group_ingress_rule" "efs_ingress_rule" {
  security_group_id            = aws_security_group.efs.id
  referenced_security_group_id = aws_security_group.web.id
  ip_protocol                  = var.efs_ingress_rules.ip_protocol
  from_port                    = var.efs_ingress_rules.from_port
  to_port                      = var.efs_ingress_rules.to_port
  description                  = var.efs_ingress_rules.description

  tags = {
    Name = "HelloWorldEFS"
  }
}