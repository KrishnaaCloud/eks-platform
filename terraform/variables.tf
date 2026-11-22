variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "aws_account_id" {
  description = "AWS account ID allowed for provisioning"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-platform"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
}

variable "my_ip_cidr" {
  description = "CIDR block for operator IP allowed to access the EKS cluster public API endpoint"
  type        = string
}
