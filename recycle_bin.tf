resource "aws_rbin_rule" "web" {
  description   = "Test Rule"
  resource_type = "EBS_SNAPSHOT"

  retention_period {
    retention_period_value = var.recycle_ebs_retention_period
    retention_period_unit  = "DAYS"
  }
}