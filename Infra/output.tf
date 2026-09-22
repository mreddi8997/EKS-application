output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_arn" {
  value = module.eks.cluster_arn
}

output "cluster_state" {
  value = module.eks.cluster_status
}

output "node_iam_role_arn" {
  value =  module.eks.eks_managed_node_groups["standard-node-group"].iam_role_arn
}

