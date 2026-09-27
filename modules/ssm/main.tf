# Optional: Interface VPC Endpoints for Systems Manager.
# Not strictly required when private subnets already egress via NAT Gateway,
# but recommended to keep Session Manager traffic on the AWS private network.
resource "aws_security_group" "vpce" {
  count       = var.enable_vpc_endpoints ? 1 : 0
  name        = "${var.project_name}-vpce-sg"
  description = "Allow HTTPS from VPC to SSM VPC endpoints"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project_name}-vpce-sg" })
}

resource "aws_vpc_endpoint" "ssm" {
  for_each            = var.enable_vpc_endpoints ? toset(["ssm", "ssmmessages", "ec2messages"]) : []
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpce[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, { Name = "${var.project_name}-${each.value}-endpoint" })
}
