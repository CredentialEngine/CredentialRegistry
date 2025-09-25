# modules/vpc/outputs.tf
output "vpc_id" {
  value = aws_vpc.app_vpc.id

}
output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private_app_vpc[*].id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public_app_vpc[*].id
}

