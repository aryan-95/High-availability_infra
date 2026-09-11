resource "aws_lb_target_group" "app" {
  name     = "${var.project_name}-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 15
    matcher             = "200"
  }

  # Give new instances time to finish bootstrapping before being deregistered
  # too eagerly, and let existing connections drain during rolling replacement.
  deregistration_delay = 30

  tags = {
    Name = "${var.project_name}-tg"
  }
}
