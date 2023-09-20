locals {
  # cidr_block_office = "0.0.0.0/0"
  cidr_block_office = "81.221.124.210/32"
  name_prefix = "${var.name_prefix}-${lower(var.environment)}"
}