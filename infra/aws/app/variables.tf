variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "sa-east-1"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
  default     = "176434290504"
}

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "k8-dev"
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "workshops"
}
