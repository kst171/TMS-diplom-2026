output "zabbix_public_ip" {
  value = aws_instance.zabbix_server.public_ip
}

output "database_primary_ip" {
  value = aws_instance.app_database.private_ip
}

output "database_replica_ip" {
  value = aws_instance.app_database_replica.private_ip
}