#####################
## Key Pair - Main ##
#####################

# Generates a secure private key and encodes it as PEM
# resource "tls_private_key" "key_pair" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

# Create the Key Pair
resource "aws_key_pair" "key_pair" {
  key_name   = "${lower(local.name_prefix)}-windows-${lower(var.aws_region)}"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0YlYQ6TcFvUxOhVlRERYEdl5XaoPIjdQ0cLOk40tBt2vpAx0ms3v20GakgI5YcqGEnEF+tRoVpUIllorurRUkMUifwOeRaJkCSsZQ91tNa3/vM3etEJKPI1WuaDeP+B+CDRq6W897DSHvQCHzfZbwdR8BnVnL18KmPvVo5rZDYEZgl6aXPTv+mrJ1qXdbo7HQCqnJwVwSd+lV2drMgEWt66rHmLrs/ozg+Dxgowc4r8i5MGi2mV5WK60wnl+qYg7UPOEZkRNcnjl289cciQKcBYqmtKiH07g93LHn/0mr8PZzrtFURqMgB0DAcmh4pjt6/L9QegJ1R+c3KQ5SK+U9 ubuntu@node"
  #  public_key = tls_private_key.key_pair.public_key_openssh
}

# Save file
# resource "local_file" "ssh_key" {
#   filename = "${aws_key_pair.key_pair.key_name}.pem"
#   content  = tls_private_key.key_pair.private_key_pem
# }
