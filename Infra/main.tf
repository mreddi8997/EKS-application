module "vpc" {
  source = "./modules/vpc"
}

module "rds" {
  source = "./modules/rds"
  vpc_name                    = module.vpc.vpc_name
  rds_db_subnet_ids           = module.vpc.rds_subnet_ids
  rds_allowed_security_groups = [module.eks.node_security_group_id]
  rds_db_name                 = "customer_feedback_db"
  rds_username                = "feedbackuser"

  depends_on = [module.vpc, module.eks]
}


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.25.3"
  name   = "Customer-feedback-application-cluster"
  kubernetes_version = "1.35"
  node_security_group_name = "Customer-feedback-application-node-sg"
  security_group_name = "Customer-feedback-application-sg"
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids


  endpoint_public_access = true
  

   eks_managed_node_groups = {
    standard-node-group = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.small"]

      min_size     = 2
      max_size     = 4
      desired_size = 2
    }
  }
}
