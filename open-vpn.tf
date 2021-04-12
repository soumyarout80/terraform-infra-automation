resource "aws_security_group" "vpn_access_server" {
  name        = "tf-sg-vpn-access-server"
  description = "Security group for VPN access server"
  vpc_id      = aws_vpc.default.id

  tags = {
    Name = "tf-sg-vpn-access-server"
  }

  ingress {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol  = "tcp"
    from_port = 943
    to_port   = 943
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol  = "tcp"
    from_port = 443
    to_port   = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol  = "udp"
    from_port = 1194
    to_port   = 1194
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_instance" "vpn_access_server" {
  ami                         = "ami-0e6f16fc977e61dd5"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  key_name               = "soumya-app"
  vpc_security_group_ids = [aws_security_group.vpn_access_server.id]
  subnet_id              = aws_subnet.public[0].id
  tags                   = merge({ Name = "openvpn-server" }, var.tags)
}

resource "aws_eip" "vpn_access_server" {
  instance = aws_instance.vpn_access_server.id
  vpc = true
}
