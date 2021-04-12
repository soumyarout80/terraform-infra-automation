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
###################################################################################
# Web_server LaunchConfiguration
###################################################################################


resource "aws_launch_configuration" "web" {
  name_prefix = "web-"

  image_id = "ami-0767046d1677be5a0" # Ubuntu server 20.4 LTS (HVM), SSD Volume Type
  instance_type = "t2.micro"
  key_name = "soumya-app"

  security_groups = [ aws_security_group.allow_http.id ]
  associate_public_ip_address = false

  user_data = filebase64("${path.module}/bootstrap-nginx.sh")
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
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = [var.private_subnets[0]]
  }
  egress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = [var.private_subnets[1]]
  }

  egress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = [var.private_subnets[2]]
  }

  tags = {
    Name = "Allow HTTP through ELB Security Group"
  }
}

resource "aws_lb" "alb_nginx" {
  name               = "alb-for-nginx"
  internal           = false
  load_balancer_type = "application"
  subnets            = aws_subnet.public.*.id
  security_groups    = [aws_security_group.elb_http.id]
}
resource "aws_lb_target_group" "alb_target" {
  name     = "alb-target-for-nginx"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.default.id
}
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb_nginx.id
  port              = 80
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.alb_target.id
    type             = "forward"
  }
}

###################################################################################
# Web_server asg Configuration
###################################################################################
# Create an ASG that ties all of this together
resource "aws_autoscaling_group" "my-alb-asg" {
  name = "my-alb-asg"
  min_size = "2"
  max_size = "3"
  launch_configuration = aws_launch_configuration.web.name
  termination_policies = [
    "OldestInstance",
    "OldestLaunchConfiguration",
  ]

  health_check_type = "ELB"
  vpc_zone_identifier  = aws_subnet.private.*.id

  depends_on = [
    aws_lb.alb_nginx,
  ]

  target_group_arns = [
    aws_lb_target_group.alb_target.arn
  ]

  lifecycle {
    create_before_destroy = true
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
  autoscaling_group_name = aws_autoscaling_group.my-alb-asg.name
}

resource "aws_autoscaling_policy" "web_policy_down" {
  name = "web_policy_down"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.my-alb-asg.name
}