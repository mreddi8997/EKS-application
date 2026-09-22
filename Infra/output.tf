output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_arn" {
  value = module.eks.cluster_arn
}

output "cluster_state" {
  value = module.eks.cluster_state
}

output "node_iam_role_arn" {
  value = module.eks.node_iam_role_arn
}

