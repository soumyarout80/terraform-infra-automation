resource "aws_eip" "db" {
  count=3
  vpc = true

  tags = {
    "Name" = "db-static-ip"
  }
}

resource "aws_eip_association" "db_ip" {
  count = 1
  instance_id = aws_instance.db_instance.id
  allocation_id = aws_eip.db[0].id
}

resource "aws_eip_association" "db_ip1" {
  count = 1
  instance_id = aws_instance.db_instance1.id
  allocation_id = aws_eip.db[1].id
}
resource "aws_eip_association" "db_ip2" {
  count = 1
  instance_id = aws_instance.db_instance2.id
  allocation_id = aws_eip.db[2].id
}

resource "aws_security_group" "allow_app" {
  name = "allow_http"
  description = "Allow HTTP inbound connections"
  vpc_id = aws_vpc.default.id

  ingress {
    from_port = 27017
    to_port = 27017
    protocol = "tcp"
    security_groups = [aws_security_group.allow_http_app.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  tags = {
    Name = "Allow HTTP Security Group"
  }
}

resource "aws_instance" "db_instance" {
  instance_type = "t2.micro"
  subnet_id = aws_subnet.database[0].id
  security_groups = [aws_security_group.allow_app.id]
  user_data = filebase64("${path.module}/bootstrap-node-js-app.sh")
  ami = "ami-0767046d1677be5a0" # Ubuntu server 20.4 LTS (HVM), SSD Volume Type
  key_name = "soumya-app"
  tags     = merge({ Name = "db-server-master" }, var.tags)
}

resource "aws_instance" "db_instance1" {
  instance_type = "t2.micro"
  subnet_id = aws_subnet.database[1].id
  security_groups = [aws_security_group.allow_app.id]
  user_data = filebase64("${path.module}/bootstrap-node-js-app.sh")
  ami = "ami-0767046d1677be5a0" # Ubuntu server 20.4 LTS (HVM), SSD Volume Type
  key_name = "soumya-app"
  tags     = merge({ Name = "db-server-slave-1" }, var.tags)
}

resource "aws_instance" "db_instance2" {
  instance_type = "t2.micro"
  subnet_id = aws_subnet.database[2].id
  security_groups = [aws_security_group.allow_app.id]
  user_data = filebase64("${path.module}/bootstrap-node-js-app.sh")
  ami = "ami-0767046d1677be5a0" # Ubuntu server 20.4 LTS (HVM), SSD Volume Type
  key_name = "soumya-app"
  tags     = merge({ Name = "db-server-slave-2" }, var.tags)
}