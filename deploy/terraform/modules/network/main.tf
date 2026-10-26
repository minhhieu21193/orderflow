# VPC across `az_count` AZs with public subnets (ALB, NAT) and private subnets
# (tasks, RDS). Outbound internet for private subnets is a cost lever:
#   nat_gateway_mode = "single"  one NAT for all AZs (cheapest with NAT)
#                    = "per_az"  one NAT per AZ (no cross-AZ dependency)
#                    = "none"    no NAT; set enable_interface_endpoints so tasks
#                                can still reach ECR and CloudWatch Logs
# The S3 gateway endpoint is always on: it is free and keeps ECR image layer
# downloads (served from S3) off the NAT.

data "aws_region" "current" {}

# Allowlist the candidate AZs by name so the subnet layout never shifts when
# AWS adds a zone to the region.
data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "zone-name"
    values = local.candidate_azs
  }
}

locals {
  candidate_azs = length(var.availability_zones) > 0 ? var.availability_zones : [
    for suffix in ["a", "b", "c"] : "${data.aws_region.current.region}${suffix}"
  ]

  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # /20 subnets: public from the bottom of the range, private from the middle.
  public_cidrs  = [for i in range(var.az_count) : cidrsubnet(var.cidr, 4, i)]
  private_cidrs = [for i in range(var.az_count) : cidrsubnet(var.cidr, 4, i + 8)]

  nat_count = {
    none   = 0
    single = 1
    per_az = var.az_count
  }[var.nat_gateway_mode]

  interface_endpoints = var.enable_interface_endpoints ? toset(["ecr.api", "ecr.dkr", "logs", "secretsmanager"]) : toset([])
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = var.name }

  lifecycle {
    precondition {
      condition     = var.nat_gateway_mode != "none" || var.enable_interface_endpoints
      error_message = "With nat_gateway_mode = \"none\", enable_interface_endpoints must be true or tasks cannot pull images."
    }
  }
}

# Remove all rules from the default security group so nothing uses it by accident.
resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-default-deny" }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = var.name }
}

resource "aws_subnet" "public" {
  count = var.az_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.public_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = { Name = "${var.name}-public-${local.azs[count.index]}", Tier = "public" }
}

resource "aws_subnet" "private" {
  count = var.az_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.private_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = { Name = "${var.name}-private-${local.azs[count.index]}", Tier = "private" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-public" }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count = var.az_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  count = local.nat_count

  domain = "vpc"
  tags   = { Name = "${var.name}-nat-${count.index}" }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count = local.nat_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags          = { Name = "${var.name}-${local.azs[count.index]}" }
}

# One private route table per AZ, so switching between single and per-AZ NAT
# only changes routes, never subnet associations.
resource "aws_route_table" "private" {
  count = var.az_count

  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-private-${local.azs[count.index]}" }
}

resource "aws_route" "private_nat" {
  count = local.nat_count > 0 ? var.az_count : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[min(count.index, local.nat_count - 1)].id
}

resource "aws_route_table_association" "private" {
  count = var.az_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.private[*].id
  tags              = { Name = "${var.name}-s3" }
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoints

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.endpoints[0].id]
  tags                = { Name = "${var.name}-${each.key}" }
}

resource "aws_security_group" "endpoints" {
  count = var.enable_interface_endpoints ? 1 : 0

  name        = "${var.name}-endpoints"
  description = "HTTPS from inside the VPC to interface endpoints"
  vpc_id      = aws_vpc.this.id
}

resource "aws_vpc_security_group_ingress_rule" "endpoints_https" {
  count = var.enable_interface_endpoints ? 1 : 0

  security_group_id = aws_security_group.endpoints[0].id
  description       = "HTTPS from the VPC"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = var.cidr
}

# ---- VPC flow logs (rejected traffic only, to keep ingestion cheap) ---------

resource "aws_flow_log" "this" {
  count = var.enable_flow_logs ? 1 : 0

  vpc_id               = aws_vpc.this.id
  traffic_type         = "REJECT"
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.flow_logs[0].arn
  iam_role_arn         = aws_iam_role.flow_logs[0].arn
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0
  #checkov:skip=CKV_AWS_338:Retention is deliberately short (var.log_retention_days) to keep a demo cheap.

  name              = "/vpc/${var.name}/flow-logs"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
}

resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name_prefix        = "${var.name}-flow-logs-"
  assume_role_policy = data.aws_iam_policy_document.flow_logs_assume.json
}

data "aws_iam_policy_document" "flow_logs_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name = "write-flow-logs"
  role = aws_iam_role.flow_logs[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogStreams"]
      Resource = "${aws_cloudwatch_log_group.flow_logs[0].arn}:*"
    }]
  })
}
