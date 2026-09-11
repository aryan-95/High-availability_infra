resource "aws_cloudwatch_log_group" "app" {
  name              = "/ha-deploy/${var.environment}/app"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-log-group"
  }
}

# Alarm on ALB target health: fires when any registered target is unhealthy,
# giving early visibility into instance failures before/alongside ASG action.
resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${var.project_name}-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "One or more targets behind the ALB are unhealthy"

  dimensions = {
    TargetGroup  = aws_lb_target_group.app.arn_suffix
    LoadBalancer = aws_lb.app.arn_suffix
  }
}

# Alarm on ASG group-level instance count dropping below desired minimum.
resource "aws_cloudwatch_metric_alarm" "asg_low_capacity" {
  alarm_name          = "${var.project_name}-asg-low-capacity"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "GroupInServiceInstances"
  namespace           = "AWS/AutoScaling"
  period              = 60
  statistic           = "Average"
  threshold           = var.asg_min_size

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  alarm_description = "In-service instance count fell below the configured minimum"
}
