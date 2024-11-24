output "development_instance_public_ip" {
  value = aws_instance.development.public_ip
}

output "database_instance_private_ip" {
  value = aws_instance.database.private_ip
}
