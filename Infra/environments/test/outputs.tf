output "vpc_id" {
  description = "Environment VPC ID"
  value       = module.vpc.vpc_id
}

output "eks_cluster_name" {
  description = "Environment EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Private Kubernetes API endpoint"
  value       = module.eks.cluster_endpoint
}

output "node_iam_role_arn" {
  description = "IAM role used by the managed node group"
  value       = module.eks.eks_managed_node_groups["standard"].iam_role_arn
}

output "database_endpoint" {
  description = "Application database endpoint"
  value       = module.rds.db_instance_endpoint
}

output "database_secret_arn" {
  description = "Secrets Manager ARN for database credentials"
  value       = module.rds.db_master_secret_arn
}
