variable "aws_region" {
  type        = string
  description = "Region for AWS Resources"
  default     = "eu-central-1"
}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR Block for VPC"
  default     = "10.1.0.0/16"
}

variable "enable_dns_hostnames" {
  type        = bool
  description = "Should be true to enable DNS hostnames in the VPC"
  default     = true
}

variable "name_prefix" {
  type        = string
  description = "Name prefix for resources"
  default     = "btc"
}

variable "environment" {
  type        = string
  description = "Application environment"
  default     = "dev"
}

variable "vpc_subnets_count" {
  type        = number
  description = "Number of public/private subnets in VPC"
  default     = 2
}

variable "instance_type" {
  type        = string
  description = "Type for ghost EC2 instances"
  #  default     = "t2.micro"
  default = "t3.medium"
}

variable "control_plane_node_count" {
  type        = number
  description = "Number of control plane nodes to create in public subnets"
  default     = 1
}

variable "linux_worker_node_count" {
  type        = number
  description = "Number of linux worker nodes to create in public subnets"
  default     = 3
}

variable "windows_worker_node_count" {
  type        = number
  description = "Number of linux worker nodes to create in public subnets"
  default     = 1
}

variable "map_public_ip_on_launch" {
  type        = bool
  description = "Map a public IP address for Public Subnet instances"
  default     = true
}

variable "windows_root_volume_size" {
  type        = number
  description = "Volumen size of root volumen of Windows Server"
  default     = "30"
}

variable "windows_data_volume_size" {
  type        = number
  description = "Volumen size of data volumen of Windows Server"
  default     = "10"
}

variable "windows_root_volume_type" {
  type        = string
  description = "Volumen type of root volumen of Windows Server. Can be standard, gp3, gp2, io1, sc1 or st1"
  default     = "gp2"
}

variable "windows_data_volume_type" {
  type        = string
  description = "Volumen type of data volumen of Windows Server. Can be standard, gp3, gp2, io1, sc1 or st1"
  default     = "gp2"
}
