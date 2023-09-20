output "control_plane_ip_addr" {
  value = aws_instance.control_plane_node[0].public_ip
}

output "linux_worker_node_ip" {
  value = aws_instance.linux_worker_node[0].public_ip
}

output "windows_worker_node_id" {
  value = aws_instance.windows_worker_node[0].id
}

output "windows_worker_node_ip_addr" {
  value = aws_instance.windows_worker_node[0].public_ip
}

output "windows_worker_node_password" {
  value = rsadecrypt(aws_instance.windows_worker_node[0].password_data, file(pathexpand("~/.ssh/id_rsa")))
}

output "db_ip_addr" {
  value = aws_db_instance.db.address
}

output "db_password" {
  value = random_string.dbpwd.result
}

# output "mssql_db_ip_addr" {
#   value = aws_db_instance.mssql_db.address
# }
