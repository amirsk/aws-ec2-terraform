variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "availability_zone" {
  type        = list(string)
  description = "Availability Zone"
}

variable "instance_type" {
  type        = string
  description = "EC2 Instance Type"
}

variable "key_name" {
  type        = string
  description = "AWS EC2 Key Name"
}

variable "vpc_cidr_block" {
  type        = string
  description = "VPC CIDR block"
}

variable "public_subnet_cidr_block" {
  type        = list(string)
  description = "Public Subnet CIDR block"
}

variable "ingress_rules" {
  type        = list(map(string))
  description = "Ingress Rules"
}

variable "egress_rules" {
  type        = list(map(string))
  description = "Egress Rules"
}

variable "efs_ingress_rules" {
  type        = map(string)
  description = "EFS Ingress Rules"
}

variable "user_data" {
  type        = string
  description = "Path to EC2 User Data"
}

variable "ebs_size" {
  type        = number
  description = "EBS Size in GB"
}

variable "ebs_type" {
  type        = string
  description = "EBS Type"
}

variable "device_name" {
  type        = string
  description = "EBS Device Name"
}

variable "transition_to_ia" {
  type        = string
  description = "EFS transition to IA time"
}

variable "throughput_mode" {
  type        = string
  description = "EFS throughput mode"
}

variable "performance_mode" {
  type        = string
  description = "EFS performance mode"
}

variable "efs_encrypted" {
  type        = bool
  description = "EFS encrypted"
}