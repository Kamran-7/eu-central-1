output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC ID"
}

output "vpc_cidr" {
  value       = aws_vpc.main.cidr_block
  description = "VPC CIDR block"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "Public subnet IDs"
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "Private subnet IDs"
}

output "public_subnet_cidrs" {
  value       = aws_subnet.public[*].cidr_block
  description = "Public subnet CIDR blocks"
}

output "private_subnet_cidrs" {
  value       = aws_subnet.private[*].cidr_block
  description = "Private subnet CIDR blocks"
}

output "nat_gateway_id" {
  value       = aws_nat_gateway.main.id
  description = "NAT Gateway ID"
}

output "nat_gateway_public_ip" {
  value       = aws_eip.nat.public_ip
  description = "NAT Gateway public IP"
}

output "internet_gateway_id" {
  value       = aws_internet_gateway.main.id
  description = "Internet Gateway ID"
}

output "db_subnet_ids" {
  description = "DB subnet IDs"
  value       = aws_subnet.db[*].id
}

