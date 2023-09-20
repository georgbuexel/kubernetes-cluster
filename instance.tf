##################################################################################
# DATA
##################################################################################

# Get Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20230325"]
  }
}

# Get latest Windows Server 2019 AMI
data "aws_ami" "windows-2019" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base*"]
  }
}

# Get latest Windows Server 2022 AMI
data "aws_ami" "windows-2022" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base*"]
  }
}

##################################################################################
# RESOURCES
##################################################################################

# # PASSWORD #
# resource "random_string" "admin_pwd" {
#   length  = 16
#   special = false
#   #special          = true
#   #override_special = "_+?!-"
# }

# INSTANCES #
# Create Control Plane node
resource "aws_instance" "control_plane_node" {
  count         = var.control_plane_node_count
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public_subnets[(count.index % var.vpc_subnets_count)].id
  private_ip    = cidrhost(aws_subnet.public_subnets[(count.index % var.vpc_subnets_count)].cidr_block, floor(count.index / var.vpc_subnets_count) + 5)
  source_dest_check = false

  vpc_security_group_ids = [aws_security_group.control_plane_sg.id]
  # user_data              = templatefile("${path.module}/startup_script.tpl", {})

  user_data = templatefile("${path.module}/startup_linux_script.tpl", {
    hostname = "c1-cp${count.index + 1}"
  })

  tags = {
    Name = "${local.name_prefix}-node-${count.index}"
  }

}

# Create Linux worker nodes
resource "aws_instance" "linux_worker_node" {
  count         = var.linux_worker_node_count
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public_subnets[(count.index % var.vpc_subnets_count)].id
  private_ip    = cidrhost(aws_subnet.public_subnets[(count.index % var.vpc_subnets_count)].cidr_block, floor(count.index / var.vpc_subnets_count) + 128)
  source_dest_check = false

  vpc_security_group_ids = [aws_security_group.linux_node_sg.id]
  # user_data              = templatefile("${path.module}/startup_script.tpl", {})

  user_data = templatefile("${path.module}/startup_linux_script.tpl", {
    hostname = "c1-lin-node${count.index + 1}"
  })

  tags = {
    Name = "${local.name_prefix}-lin-node-${count.index + 1}"
  }

}

# Create Windows worker nodes
resource "aws_instance" "windows_worker_node" {
  count                  = var.windows_worker_node_count
  ami                    = data.aws_ami.windows-2022.id
  # instance_type          = var.instance_type
  # ami                    = data.aws_ami.windows-2019.id
  instance_type          = "t2.xlarge"
  subnet_id              = aws_subnet.public_subnets[(count.index % var.vpc_subnets_count)].id
  private_ip             = cidrhost(aws_subnet.public_subnets[(count.index % var.vpc_subnets_count)].cidr_block, floor(count.index / var.vpc_subnets_count) + 192)
  source_dest_check = false
  vpc_security_group_ids = [aws_security_group.aws_windows_sg.id]
  #  associate_public_ip_address = var.windows_associate_public_ip_address
  #  source_dest_check           = false
  key_name          = aws_key_pair.key_pair.key_name
  get_password_data = true
  user_data         = templatefile("${path.module}/startup_windows_script.tpl", {})
  # user_data = templatefile("${path.module}/startup_windows_script.tpl", {
  #   hostname = "c1-win-node${count.index + 1}"
  #   configfile = file("./tmp/config")
  # })

  # root disk
  root_block_device {
    volume_size           = var.windows_root_volume_size
    volume_type           = var.windows_root_volume_type
    encrypted             = true
    delete_on_termination = true
  }

  #   # Copies the myapp.conf file to /etc/myapp.conf
  #   provisioner "file" {
  # #    source      = "${path.module}/scripts/wait_for_cloud_init.ps1"
  #     source      = "${path.module}/scripts/test.txt"
  # #    destination = "C:\\wait_for_cloud_init.ps1"
  #     destination = "C:\\test.txt"
  #   }
  # 
  #   connection {
  #     type     = "winrm"
  #     user     = "Administrator"
  #     password = rsadecrypt(self.password_data, file(pathexpand("~/.ssh/id_rsa")))
  #     host     = self.public_ip
  #   }

  # extra disk
  #  ebs_block_device {
  #    device_name           = "/dev/xvda"
  #    volume_size           = var.windows_data_volume_size
  #    volume_type           = var.windows_data_volume_type
  #    encrypted             = true
  #    delete_on_termination = true
  #  }

  tags = {
    Name        = "${local.name_prefix}-win-node-${count.index + 1}"
    Environment = var.environment
  }

  depends_on = [null_resource.load_config]

}
