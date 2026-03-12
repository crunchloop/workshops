# Remote state: GitHub OIDC Provider
data "terraform_remote_state" "oidc" {
  backend = "s3"
  config = {
    bucket  = "terraform-crunchloop-aws"
    key     = "crunchloop-oidc-dev.tfstate"
    region  = "us-east-1"
    profile = "crunchloop"
  }
}

# EKS deploy policy
data "aws_iam_policy_document" "workshops_github_deploy" {
  statement {
    effect = "Allow"
    actions = [
      "eks:DescribeCluster",
      "eks:ListClusters"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "workshops_github_deploy" {
  name        = "workshops-github-deploy-policy"
  description = "IAM policy for GitHub Actions to deploy workshops to EKS cluster"
  policy      = data.aws_iam_policy_document.workshops_github_deploy.json
}

# IAM role for GitHub Actions with OIDC trust policy
resource "aws_iam_role" "workshops_github_deploy" {
  name        = "workshops-github-deploy"
  description = "IAM role for GitHub Actions to deploy workshops to EKS with OIDC"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = data.terraform_remote_state.oidc.outputs.github_oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${local.github_repo}:*"
        }
      }
    }]
  })

  tags = {
    Name = "workshops-github-deploy"
  }
}

# Attach the custom policy to the IAM role
resource "aws_iam_role_policy_attachment" "workshops_github_deploy" {
  role       = aws_iam_role.workshops_github_deploy.name
  policy_arn = aws_iam_policy.workshops_github_deploy.arn
}
