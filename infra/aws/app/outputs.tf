output "deploy_role_arn" {
  description = "ARN of the GitHub Actions deploy role"
  value       = aws_iam_role.github_deploy.arn
}

output "external_secrets_role_arn" {
  description = "ARN of the External Secrets role"
  value       = aws_iam_role.external_secrets.arn
}
