output "vpc_id" {
  value = aws_vpc.this.id
}

output "vpc_cidr" {
  value = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  value = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  value = [for s in aws_subnet.private : s.id]
}

output "database_subnet_ids" {
  value = [for s in aws_subnet.database : s.id]
}

output "private_subnet_ids_map" {
  value = { for k, s in aws_subnet.private : k => s.id }
}

output "nat_gateway_ids" {
  value = { for k, n in aws_nat_gateway.this : k => n.id }
}
