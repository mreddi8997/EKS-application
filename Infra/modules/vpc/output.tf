output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "rds_subnet_ids" {
  value = aws_subnet.rds[*].id
}

output "nat_gateway_id" {
  value = aws_nat_gateway.main.id
}

output "external_ip" {
  value = aws_eip.nat.public_ip
}

output "vpc_name" {
  value = var.vpc_name
}
