output "vpc_endpoint_ids" {
  value = { for k, e in aws_vpc_endpoint.ssm : k => e.id }
}
