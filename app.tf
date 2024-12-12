locals {
  public_subnet_ids  = aws_subnet.public[*].id
  private_subnet_ids = aws_subnet.private[*].id
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  owners = ["amazon"]
}

# Security Group for App
resource "aws_security_group" "app_sg" {
  name        = "serrakhiApp-app-sg"
  description = "Security group for serrakhiApp Application"
  vpc_id      = aws_vpc.main.id

  # Allow HTTP/HTTPS access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outbound access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "serrakhiApp App Security Group"
  }
}

# Load Balancer
resource "aws_lb" "app_alb" {
  name               = "serrakhiApp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app_sg.id]
  subnets            = local.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name = "serrakhiApp-ALB"
  }
}

# Target Group
resource "aws_lb_target_group" "app_tg" {
  name        = "serrakhiApp-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    protocol            = "HTTP"
  }

  tags = {
    Name = "serrakhiApp Target Group"
  }
}

# Load Balancer Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# Launch Template
resource "aws_launch_template" "app_lt" {
  name          = "serrakhiApp-lt"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.key_name

  network_interfaces {
    security_groups = [aws_security_group.app_sg.id]
    associate_public_ip_address = true
  }

  user_data = base64encode(templatefile("scripts/app_setup.sh", {}))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "serrakhiApp Instance"
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "app_asg" {
  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  min_size         = 1
  max_size         = 3
  desired_capacity = 1

  vpc_zone_identifier = local.public_subnet_ids
  target_group_arns    = [aws_lb_target_group.app_tg.arn]

  # Example of the correct tagging format
  tag {
    key                 = "Name"
    value               = "serrakhiApp ASG Instance"
    propagate_at_launch = true
  }
}


# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "scale_up" {
  alarm_name          = "serrakhiApp-scale-up"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }
}

resource "aws_cloudwatch_metric_alarm" "scale_down" {
  alarm_name          = "serrakhiApp-scale-down"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 30
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }
}

# Scaling Policies
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "serrakhiApp-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "serrakhiApp-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
}
