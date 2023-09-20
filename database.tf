##################################################################################
# RESOURCES
##################################################################################

# PASSWORD #
resource "random_string" "dbpwd" {
  length  = 16
  special = false
  #special          = true
  #override_special = "_+?!-"
}

# INSTANCES #
resource "aws_db_instance" "db" {
  allocated_storage      = 10
  identifier             = "${local.name_prefix}-db"
  db_name                = "phplogin"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = "dbuser"
  password               = random_string.dbpwd.result
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.db.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  availability_zone      = data.aws_availability_zones.available.names[0]
  publicly_accessible    = true
  # backup_retention_period = 14
  # publicly_accessible = true

  # provisioner "file" {
  #   connection {
  #     user        = "ubuntu"
  #     host        = aws_instance.control_plane_node[0].public_ip
  #     private_key = file(pathexpand("~/.ssh/id_rsa"))
  #   }

  #   source      = "./scripts/schema.sql"
  #   destination = "~"
  # }

  # provisioner "remote-exec" {
  #   connection {
  #     user        = "ubuntu"
  #     host        = aws_instance.control_plane_node[0].public_ip
  #     private_key = file(pathexpand("~/.ssh/id_rsa"))
  #   }

  #   inline = ["mysql --host=${self.address} --port=${self.port} --user=${self.username} --password=${self.password} < ~/schema.sql"]
  # }
}

# resource "aws_db_instance" "mssql_db" {
#   allocated_storage      = 160
#   identifier             = "${local.name_prefix}-mssql-db"
#   engine           = "sqlserver-se"
#   engine_version       = "15.00.4073.23.v1"
#   instance_class   = "db.t3.xlarge"
#   # allocated_storage = 20
#   # identifier       = "my-mssql-instance"
#   # db_name             = "kta"
#   username         = "db_admin_user"
#   # password         = "MySecurePassword123"
#   # db_name                = "phplogin"
#   # engine                 = "mysql"
#   # engine_version         = "8.0"
#   # instance_class         = "db.t3.micro"
#   # username               = "dbuser"
#   password               = random_string.dbpwd.result
#   # parameter_group_name   = "sqlserver-se-15.0"
#   license_model        = "license-included"
#   skip_final_snapshot    = true
#   db_subnet_group_name   = aws_db_subnet_group.db.name
#   vpc_security_group_ids = [aws_security_group.db_sg.id]
#   availability_zone      = data.aws_availability_zones.available.names[0]
#   publicly_accessible    = true
#   # backup_retention_period = 14
#   # publicly_accessible = true

#   # provisioner "file" {
#   #   connection {
#   #     user        = "ubuntu"
#   #     host        = aws_instance.control_plane_node[0].public_ip
#   #     private_key = file(pathexpand("~/.ssh/id_rsa"))
#   #   }

#   #   source      = "./scripts/schema.sql"
#   #   destination = "~"
#   # }

#   # provisioner "remote-exec" {
#   #   connection {
#   #     user        = "ubuntu"
#   #     host        = aws_instance.control_plane_node[0].public_ip
#   #     private_key = file(pathexpand("~/.ssh/id_rsa"))
#   #   }

#   #   inline = ["mysql --host=${self.address} --port=${self.port} --user=${self.username} --password=${self.password} < ~/schema.sql"]
#   # }
# }

# resource "aws_db_instance" "replica" {
#  allocated_storage      = 10
#  identifier             = "${local.name_prefix}-db-replica"
#  replicate_source_db    = aws_db_instance.db.id
#  instance_class         = "db.t3.micro"
#  parameter_group_name   = "default.mysql8.0"
#  skip_final_snapshot    = true
#  db_subnet_group_name   = aws_db_subnet_group.db.name
#  vpc_security_group_ids = [aws_security_group.db_sg.id]
#  availability_zone      = data.aws_availability_zones.available.names[1]
#  publicly_accessible    = true
# }

# NETWORKING #
resource "aws_db_subnet_group" "db" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.private_subnets[*].id
}

resource "null_resource" "sql_script" {
  #Run on control plane (master) node (the first one)
  connection {
    host        = aws_instance.control_plane_node[0].public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(pathexpand("~/.ssh/id_rsa"))
  }

  # Define the file provisioner block.
  provisioner "file" {
    source      = "./scripts/schema.sql"
    destination = "schema.sql"
  }
  depends_on = [aws_db_instance.db]
}

resource "null_resource" "schema_setup" {

  #Run on control plane (master) node (the first one)
  connection {
    host        = aws_instance.control_plane_node[0].public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(pathexpand("~/.ssh/id_rsa"))
  }

  provisioner "remote-exec" {
    # Initialize the clutser
    inline = ["mysql --host=${aws_db_instance.db.address} --port=${aws_db_instance.db.port} --user=${aws_db_instance.db.username} --password=${random_string.dbpwd.result} < ~/schema.sql"]
  }

  depends_on = [null_resource.sql_script]

}
