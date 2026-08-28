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
  description = "Public IPs of sandbox API EC2 instances (direct access)"
  value       = aws_instance.api_server[*].public_ip
}

output "haproxy_public_ip" {
  description = "HAProxy public IP — use this to access the API"
  value       = aws_instance.haproxy.public_ip
}

output "haproxy_url" {
  description = "API base URL via HAProxy"
  value       = "http://${aws_instance.haproxy.public_ip}"
}

output "haproxy_stats_url" {
  description = "HAProxy stats page (admin/sandbox123)"
  value       = "http://${aws_instance.haproxy.public_ip}:8404/stats"
}
