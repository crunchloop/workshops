resource "aws_iam_role" "external_secrets" {
  name = "workshops-external-secrets"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.terraform_remote_state.eks.outputs.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_issuer}:sub" = "system:serviceaccount:${var.namespace}:external-secrets"
            "${local.oidc_issuer}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Project = "workshops"
  }
}

resource "aws_iam_role_policy" "external_secrets" {
  name = "workshops-secrets-access"
  role = aws_iam_role.external_secrets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:${local.region}:${local.account_id}:secret:/workshops/*",
          "arn:aws:secretsmanager:${local.region}:${local.account_id}:secret:workshops/*"
        ]
      }
    ]
  })
}
