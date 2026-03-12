locals {
  oidc_provider     = replace(data.aws_eks_cluster.k8_dev.identity[0].oidc[0].issuer, "https://", "")
  github_oidc_arn   = "arn:aws:iam::${var.aws_account_id}:oidc-provider/token.actions.githubusercontent.com"
}

# IAM role for GitHub Actions to deploy to EKS
resource "aws_iam_role" "github_deploy" {
  name = "workshops-github-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = local.github_oidc_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:crunchloop/workshops:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_deploy_eks" {
  name = "eks-access"
  role = aws_iam_role.github_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      }
    ]
  })
}
