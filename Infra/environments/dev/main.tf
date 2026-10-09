locals {
  name = "eks-application-${var.environment}"
  azs  = ["us-east-2a", "us-east-2b"]
}

module "vpc" {
  source = "../../modules/vpc"

  vpc_name           = local.name
  vpc_cidr           = var.vpc_cidr
  availability_zones = local.azs

  public_subnets = [
    cidrsubnet(var.vpc_cidr, 8, 1),
    cidrsubnet(var.vpc_cidr, 8, 2)
  ]

  private_subnets = [
    cidrsubnet(var.vpc_cidr, 8, 3),
    cidrsubnet(var.vpc_cidr, 8, 4)
  ]

  rds_subnets = [
    cidrsubnet(var.vpc_cidr, 8, 5),
    cidrsubnet(var.vpc_cidr, 8, 6)
  ]
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.25.3"

  iam_role_name            = "${local.name}-cluster"
  iam_role_use_name_prefix = false
  encryption_policy_name   = "${local.name}-cluster-encryption"

  name               = local.name
  kubernetes_version = "1.35"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  endpoint_private_access = true
  endpoint_public_access  = false

  enable_cluster_creator_admin_permissions = false

 kms_key_administrators = [
  "arn:aws:iam::431445718171:role/github-eks-application-dev-apply"
 ]

 access_entries = {
  deployment_admin = {
    principal_arn = "arn:aws:iam::431445718171:role/github-eks-application-dev-apply"
    type          = "STANDARD"

    policy_associations = {
      cluster_admin = {
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

        access_scope = {
          type = "cluster"
        }
      }
    }
  }
}

  addons = {
    vpc-cni = {
      before_compute = true
    }
    coredns    = {}
    kube-proxy = {}
  }

  eks_managed_node_groups = {
    standard = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types

      iam_role_name            = "${local.name}-nodes"
      iam_role_use_name_prefix = false

      min_size     = var.node_capacity.min
      max_size     = var.node_capacity.max
      desired_size = var.node_capacity.desired
    }
  }
}

module "rds" {
  source = "../../modules/rds"

  vpc_name                    = local.name
  vpc_id                      = module.vpc.vpc_id
  rds_db_subnet_ids            = module.vpc.rds_subnet_ids
  rds_allowed_security_groups = [module.eks.node_security_group_id]

  rds_db_name        = "application"
  rds_username       = "appadmin"
  rds_instance_class = var.rds_instance_class
}
