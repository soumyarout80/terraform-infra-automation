###################################################################################
# Web_server SecurityGroup
###################################################################################
resource "aws_security_group" "allow_http_app" {
  name = "allow_http"
  description = "Allow HTTP inbound connections"
  vpc_id = aws_vpc.default.id

  ingress {
    from_port = 5000
    to_port = 5000
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


resource "aws_launch_configuration" "app" {
  name_prefix = "app-"

  image_id = "ami-0767046d1677be5a0" # Ubuntu server 20.4 LTS (HVM), SSD Volume Type
  instance_type = "t2.micro"
  key_name = "soumya-app"

  security_groups = [ aws_security_group.allow_http_app.id ]
  associate_public_ip_address = false

  user_data = filebase64("${path.module}/bootstrap-node-js-app.sh")
  lifecycle {
    create_before_destroy = true
  }
}


###################################################################################
# Web_server ELB Configuration
###################################################################################
resource "aws_security_group" "elb_http_app" {
  name        = "elb_http"
  description = "Allow HTTP traffic to instances through Elastic Load Balancer"
  vpc_id = aws_vpc.default.id

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    cidr_blocks     = [var.private_subnets[0]]
  }
  egress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    cidr_blocks     = [var.private_subnets[1]]
  }

  egress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    cidr_blocks     = [var.private_subnets[2]]
  }

  tags = {
    Name = "Allow HTTP through ELB Security Group"
  }
}

resource "aws_lb" "alb_node_js_app" {
  name               = "alb-node-js-app"
  internal           = true
  load_balancer_type = "application"
  subnets            = aws_subnet.private.*.id
  security_groups    = [aws_security_group.elb_http_app.id]
}
resource "aws_lb_target_group" "alb_target_app" {
  name     = "alb-target-for-node-js"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.default.id
}
resource "aws_lb_listener" "listener_app" {
  load_balancer_arn = aws_lb.alb_node_js_app.id
  port              = 5000
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.alb_target_app.id
    type             = "forward"
  }
}

###################################################################################
# Web_server asg Configuration
###################################################################################
# Create an ASG that ties all of this together
resource "aws_autoscaling_group" "app-alb-asg" {
  name = "app-alb-asg"
  min_size = "3"
  max_size = "3"
  launch_configuration = aws_launch_configuration.app.name
  termination_policies = [
    "OldestInstance",
    "OldestLaunchConfiguration",
  ]

  health_check_type = "ELB"
  vpc_zone_identifier  = aws_subnet.private.*.id

  depends_on = [
    aws_lb.alb_node_js_app,
  ]

  target_group_arns = [
    aws_lb_target_group.alb_target_app.arn
  ]

  lifecycle {
    create_before_destroy = true
  }
}

###################################################################################
# Web_server asg policy
###################################################################################

resource "aws_autoscaling_policy" "app_policy_up" {
  name = "app_policy_up"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.app-alb-asg.name
}

resource "aws_autoscaling_policy" "app_policy_down" {
  name = "app_policy_down"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.app-alb-asg.name
}