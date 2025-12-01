output "db_instance_id" {
  value = aws_db_instance.this.id
}
output "db_instance_arn" {
  value = aws_db_instance.this.arn
}
output "endpoint" {
  value = aws_db_instance.this.endpoint
}
output "address" {
  value = aws_db_instance.this.address
}
output "port" {
  value = aws_db_instance.this.port
}
output "username" {
  value = aws_db_instance.this.username
}
output "password" {
  value     = try(random_password.this[0].result, null)
  sensitive = true
}
output "db_subnet_group_name" {
  value = local.subnet_group_name
}
output "parameter_group_name" {
  value = aws_db_parameter_group.this.name
}
output "option_group_name" {
  value = try(aws_db_option_group.this[0].name, null)
}
