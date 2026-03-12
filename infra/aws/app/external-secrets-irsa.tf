# External Secrets policy
data "aws_iam_policy_document" "workshops_external_secrets" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [
      "arn:aws:secretsmanager:sa-east-1:${data.aws_caller_identity.current.account_id}:secret:/workshops/*",
      "arn:aws:secretsmanager:sa-east-1:${data.aws_caller_identity.current.account_id}:secret:workshops/*"
    ]
  }
}

resource "aws_iam_policy" "workshops_external_secrets" {
  name        = "workshops-external-secrets-policy"
  description = "IAM policy for External Secrets to read workshops secrets"
  policy      = data.aws_iam_policy_document.workshops_external_secrets.json
}

# IAM role for External Secrets Operator
resource "aws_iam_role" "workshops_external_secrets" {
  name        = "workshops-external-secrets"
  description = "IAM role for External Secrets Operator in workshops namespace"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = data.terraform_remote_state.eks.outputs.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(data.terraform_remote_state.eks.outputs.oidc_provider_arn, "/^(.*provider/)/", "")}:sub" = "system:serviceaccount:${var.namespace}:external-secrets"
          "${replace(data.terraform_remote_state.eks.outputs.oidc_provider_arn, "/^(.*provider/)/", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = {
    Name = "workshops-external-secrets"
  }
}

resource "aws_iam_role_policy_attachment" "workshops_external_secrets" {
  role       = aws_iam_role.workshops_external_secrets.name
  policy_arn = aws_iam_policy.workshops_external_secrets.arn
}
