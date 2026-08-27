output "s3_artifact_bucket" {
  description = "S3 bucket name for build artifacts"
  value       = aws_s3_bucket.artifacts.bucket
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions to assume via OIDC"
  value       = aws_iam_role.github_actions.arn
}

output "codedeploy_app_name" {
  description = "CodeDeploy application name"
  value       = aws_codedeploy_app.api.name
}

output "codedeploy_deployment_group" {
  description = "CodeDeploy deployment group name"
  value       = aws_codedeploy_deployment_group.api.deployment_group_name
}

output "instance_public_ips" {
  description = "Public IPs of sandbox EC2 instances (direct access)"
  value       = aws_instance.api_server[*].public_ip
}

output "alb_dns_name" {
  description = "ALB DNS name — use this URL to access the API"
  value       = "http://${aws_lb.api.dns_name}"
}
