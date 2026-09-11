output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer. Open this in a browser."
  value       = aws_lb.app.dns_name
}

output "vpc_id" {
  description = "ID of the created VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (ALB)."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (EC2 instances)."
  value       = aws_subnet.private[*].id
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group."
  value       = aws_autoscaling_group.app.name
}

output "target_group_arn" {
  description = "ARN of the ALB target group."
  value       = aws_lb_target_group.app.arn
}

output "app_url" {
  description = "Convenience URL to open the application."
  value       = "http://${aws_lb.app.dns_name}"
}
