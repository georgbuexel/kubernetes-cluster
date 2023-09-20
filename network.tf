##################################################################################
# DATA
##################################################################################

data "aws_availability_zones" "available" {}

##################################################################################
# RESOURCES
##################################################################################

# NETWORK #
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

resource "aws_subnet" "public_subnets" {
  count                   = var.vpc_subnets_count
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 8, count.index)
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = var.map_public_ip_on_launch
  availability_zone       = data.aws_availability_zones.available.names[count.index % 3]

  tags = {
    Name = "${local.name_prefix}-public-subnet-${count.index}"
  }
}

resource "aws_subnet" "private_subnets" {
  count             = var.vpc_subnets_count
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 8, count.index + 128)
  vpc_id            = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index % 3]

  tags = {
    Name = "${local.name_prefix}-private-subnet-${count.index}"
  }
}

# ROUTING #
resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${local.name_prefix}-rtb"
  }
}

resource "aws_route_table_association" "rta-subnets" {
  count          = var.vpc_subnets_count
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.rtb.id
}

resource "aws_route_table_association" "rta-private-subnets" {
  count          = var.vpc_subnets_count
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.rtb.id
}

# SECURITY GROUPS #
# Control plane security group 
resource "aws_security_group" "control_plane_sg" {
  name   = "${local.name_prefix}-control-plane-sg"
  vpc_id = aws_vpc.vpc.id

  # All ports from VPC
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # SSH access from office
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.cidr_block_office]
  }

  # kubectl access from office
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [local.cidr_block_office]
  }

  # NodePort access from anywhere
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # # All ports for Kubernetes
  # ingress {
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"
  #   cidr_blocks = ["10.0.0.0/8"]
  # }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# Linux Node security group 
resource "aws_security_group" "linux_node_sg" {
  name   = "${local.name_prefix}-linux-node-sg"
  vpc_id = aws_vpc.vpc.id

  # All ports from VPC
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # SSH access from office
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.cidr_block_office]
  }

  # NodePort access from anywhere
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # # All ports for Kubernetes
  # ingress {
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"
  #   cidr_blocks = ["10.0.0.0/8"]
  # }
  
  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# Security group for the Windows server
resource "aws_security_group" "aws_windows_sg" {
  name        = "${local.name_prefix}-windows-sg"
  description = "Allow incoming connections"
  vpc_id      = aws_vpc.vpc.id

  # All ports from VPC
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # SSH access from office
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.cidr_block_office]
  }

  # WinRM access from office
  ingress {
    from_port   = 5985
    to_port     = 5985
    protocol    = "tcp"
    cidr_blocks = [local.cidr_block_office]
  }

  # Remote Desktop from office
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [local.cidr_block_office]
  }

  # NodePort access from anywhere
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # # All ports for Kubernetes
  # ingress {
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"
  #   cidr_blocks = ["10.0.0.0/8"]
  # }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.name_prefix}-windows-sg"
    Environment = var.environment
  }
}


# DB security group 
resource "aws_security_group" "db_sg" {
  name   = "${local.name_prefix}-db-sg"
  vpc_id = aws_vpc.vpc.id

  # DB access from Server
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.control_plane_sg.id, aws_security_group.linux_node_sg.id, aws_security_group.aws_windows_sg.id]
#    security_groups = [aws_security_group.control_plane_sg.id, aws_security_group.linux_node_sg.id]
  }

  # DB access from Lambda
  # ingress {
  #   from_port   = 3306
  #   to_port     = 3306
  #   protocol    = "tcp"
  #   cidr_blocks = aws_subnet.private_subnets[*].cidr_block
  # }

  # DB access from anywhere
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # DB access from anywhere
  ingress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}