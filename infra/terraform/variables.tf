variable "aws_account_id" {
  description = "Your personal sandbox AWS account ID (12 digits)"
  type        = string
}

variable "aws_region" {
  description = "AWS region for all sandbox resources"
  type        = string
  default     = "us-east-1"
}

variable "github_org" {
  description = "GitHub owner (user or org) for the OIDC trust policy"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (without owner prefix)"
  type        = string
}

variable "github_branch" {
  description = "Branch allowed to assume the GitHub Actions IAM role"
  type        = string
  default     = "main"
}

variable "app_name" {
  description = "Base name used for all sandbox resources — clearly test-labeled"
  type        = string
  default     = "sandbox-api-deploy"
}

variable "instance_type" {
  description = "EC2 instance type for test servers"
  type        = string
  default     = "t3.micro"
}

variable "instance_count" {
  description = "Number of EC2 instances in the deployment group (1 or 2)"
  type        = number
  default     = 2
}

variable "vpc_id" {
  description = "VPC ID to launch instances into (leave empty to use default VPC)"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "List of subnet IDs for instances (leave empty to use default subnets)"
  type        = list(string)
  default     = []
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH to the test instances"
  type        = string
  default     = "0.0.0.0/0"  # tighten this to your IP for real testing
}
