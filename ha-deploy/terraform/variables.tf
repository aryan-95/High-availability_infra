# ---------------------------------------------------------------------------
# Variables the student SHOULD review / customize are marked "CONFIGURE".
# ---------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region to deploy into. CONFIGURE if not us-east-1."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name used for tagging (e.g. dev, demo, prod)."
  type        = string
  default     = "demo"
}

variable "project_name" {
  description = "Short project name used as a resource-name prefix."
  type        = string
  default     = "ha-deploy"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the two public subnets (ALB)."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the two private subnets (EC2)."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "instance_type" {
  description = "EC2 instance type for the Auto Scaling Group. CONFIGURE if needed."
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Existing EC2 KeyPair name for SSH access (only used if enable_ssh = true). CONFIGURE."
  type        = string
  default     = ""
}

variable "enable_ssh" {
  description = "Whether to allow SSH (port 22) to instances. Keep false unless debugging."
  type        = bool
  default     = false
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to SSH into instances, only used when enable_ssh = true. CONFIGURE to your IP/32."
  type        = string
  default     = "0.0.0.0/0"
}

variable "asg_min_size" {
  description = "Minimum number of instances in the Auto Scaling Group."
  type        = number
  default     = 2
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in the Auto Scaling Group."
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of instances in the Auto Scaling Group."
  type        = number
  default     = 6
}

variable "scale_out_cpu_threshold" {
  description = "Average CPU % above which the ASG scales OUT."
  type        = number
  default     = 70
}

variable "scale_in_cpu_threshold" {
  description = "Average CPU % below which the ASG scales IN."
  type        = number
  default     = 30
}

variable "app_version" {
  description = "Application version deployed to instances (passed to user_data)."
  type        = string
  default     = "1.0.0"
}

variable "app_repo_url" {
  description = "Git repository URL that instances pull the Flask app from. CONFIGURE to your GitHub repo."
  type        = string
  default     = "https://github.com/CHANGE-ME/ha-deploy.git"
}
