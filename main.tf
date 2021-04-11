# Managed By : Soumya Ranjan Rout
# Description : This Script is used to create VPC, Subnet, Internet Gateway and EC2 instances.

###################################################################################
#Module      : VPC
#Description : Terraform module to create VPC resource on AWS.
###################################################################################
resource "aws_vpc" "default" {

  cidr_block                       = var.cidr_block
  instance_tenancy                 = var.instance_tenancy
  enable_dns_hostnames             = var.enable_dns_hostnames
  enable_dns_support               = var.enable_dns_support
  enable_classiclink               = var.enable_classiclink
  enable_classiclink_dns_support   = var.enable_classiclink_dns_support
  assign_generated_ipv6_cidr_block = true
  tags = {
    "Name" = "my-test-vpc"
  }
}
###################################################################################
#Module      : Elastic IP
#Description : Terraform module which creates Elastic IP resources on AWS
###################################################################################
resource "aws_eip" "nat" {
  vpc = true

  tags = {
    "Name" = "Nat-elastic-ip"
  }
}
###################################################################################
#Module      : NAT GATEWAY
#Description : Terraform module which creates Nat Geteway resources on AWS
###################################################################################
resource "aws_nat_gateway" "default" {
  allocation_id = aws_eip.nat.id
  subnet_id = aws_subnet.public.id

  tags = {
    "Name" =  format("%s-nat", var.name)
  }

  depends_on = [aws_internet_gateway.default]
}
###################################################################################
#Module      : INTERNET GATEWAY
#Description : Terraform module which creates Internet Geteway resources on AWS
###################################################################################
resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
  tags = merge(
    var.tags,
    {
      "Name" = format("%s-igw", var.name)
    }
  )
}

###################################################################################
# Database subnet
###################################################################################
resource "aws_subnet" "database" {
  count = 3

  vpc_id                          = aws_vpc.default.id
  cidr_block                      = element(concat(var.database_subnets, [""]), count.index)
  availability_zone               = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null


  tags = {
      "Name" = format(
        "%s-${var.database_subnet_suffix}-%s",
        var.name,
        element(var.azs, count.index),
      )
    }
}
###################################################################################
# Database routes
###################################################################################
resource "aws_route_table" "database" {
  count = 1
  vpc_id = aws_vpc.default.id
  tags = {
    "Name" = "database-route-table"
  }

}
resource "aws_route" "database_nat_gateway" {
  count = 1

  route_table_id         = element(aws_route_table.database.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.default.*.id, count.index)

  timeouts {
    create = "5m"
  }
}

###################################################################################
# Database routes
###################################################################################
resource "aws_route_table" "private" {
  count = 1
  vpc_id = aws_vpc.default.id
  tags = {
    "Name" = "private-route-table"
  }

}
resource "aws_route" "private_nat_gateway" {
  count = 1

  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.default.*.id, count.index)

  timeouts {
    create = "5m"
  }
}
###################################################################################
# Route table association
###################################################################################
resource "aws_route_table_association" "private" {
  count = 3

  subnet_id = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(
    aws_route_table.private.*.id,
    count.index,
  )
}

resource "aws_route_table_association" "database" {
  count = 3

  subnet_id = element(aws_subnet.database.*.id, count.index)
  route_table_id = element(
    coalescelist(aws_route_table.database.*.id, aws_route_table.private.*.id),
    count.index,
  )
}
###################################################################################
# Private subnet
###################################################################################
resource "aws_subnet" "private" {
  count = 3

  vpc_id                          = aws_vpc.default.id
  cidr_block                      = element(concat(var.private_subnets, [""]), count.index)
  availability_zone               = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null


  tags = {
      "Name" = format(
        "%s-${var.private_subnets_suffix}-%s",
        var.name,
        element(var.azs, count.index),
      )
    }
}

###################################################################################
# Private subnet
###################################################################################
resource "aws_subnet" "public" {
  vpc_id                          = aws_vpc.default.id
  cidr_block                      = var.public_subnets
  availability_zone               = var.azs[0]


  tags = {
      "Name" = format(
        "%s-${var.public_subnets_suffix}-%s",
        var.name,
        var.azs[0]
      )
    }
}

###################################################################################
# Web_server SecurityGroup
###################################################################################
resource "aws_security_group" "allow_http" {
  name = "allow_http"
  description = "Allow HTTP inbound connections"
  vpc_id = aws_vpc.default.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
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
###################################################################################
# Web_server LaunchConfiguration
###################################################################################


resource "aws_launch_configuration" "web" {
  name_prefix = "web-"

  image_id = "ami-0767046d1677be5a0" # Ubuntu server 20.4 LTS (HVM), SSD Volume Type
  instance_type = "t2.micro"
  key_name = "soumya-app"

  security_groups = [ aws_security_group.allow_http.id ]
  associate_public_ip_address = true

  user_data = filebase64("${path.module}/bootstrap.sh")
  lifecycle {
    create_before_destroy = true
  }
}


###################################################################################
# Web_server ELB Configuration
###################################################################################

resource "aws_security_group" "elb_http" {
  name        = "elb_http"
  description = "Allow HTTP traffic to instances through Elastic Load Balancer"
  vpc_id = aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow HTTP through ELB Security Group"
  }
}

resource "aws_elb" "web_elb" {
  name = "web-elb"
  security_groups = [
    aws_security_group.elb_http.id
  ]
  subnets = aws_subnet.private.*.id


  cross_zone_load_balancing   = true

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:80/"
  }

  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "80"
    instance_protocol = "http"
  }

}

###################################################################################
# Web_server asg Configuration
###################################################################################
resource "aws_autoscaling_group" "web" {
  name = "${aws_launch_configuration.web.name}-asg"

  min_size             = 1
  desired_capacity     = 1
  max_size             = 1

  health_check_type    = "ELB"
  load_balancers = [aws_elb.web_elb.id ]

  launch_configuration = aws_launch_configuration.web.name

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  metrics_granularity = "1Minute"

  vpc_zone_identifier  = aws_subnet.private.*.id


  # Required to redeploy without an outage.
  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "web"
    propagate_at_launch = true
  }

}

###################################################################################
# Web_server asg policy
###################################################################################

resource "aws_autoscaling_policy" "web_policy_up" {
  name = "web_policy_up"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}

resource "aws_autoscaling_policy" "web_policy_down" {
  name = "web_policy_down"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}
