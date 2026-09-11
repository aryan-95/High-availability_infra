# Latest Amazon Linux 2023 AMI, resolved automatically (no hardcoded AMI ID).
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  user_data = base64encode(templatefile("${path.module}/../scripts/install_app.sh", {
    app_version  = var.app_version
    environment  = var.environment
    app_repo_url = var.app_repo_url
  }))
}

# Immutable infrastructure: every new version/config change produces a NEW
# launch template version -> new instances are launched from it -> old
# instances are drained and terminated. Nobody SSHes in to patch code in place.
resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.al2023.id
  instance_type = var.instance_type
  key_name      = var.enable_ssh && var.key_name != "" ? var.key_name : null

  vpc_security_group_ids = [aws_security_group.ec2.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # enforce IMDSv2
    http_put_response_hop_limit = 2
  }

  monitoring {
    enabled = true # detailed CloudWatch monitoring (1-min metrics)
  }

  user_data = local.user_data

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-instance"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
