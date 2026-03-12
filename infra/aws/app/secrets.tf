# GHCR token for pulling container images
resource "aws_secretsmanager_secret" "ghcr_token" {
  name = "/workshops/ghcr-token"
}
