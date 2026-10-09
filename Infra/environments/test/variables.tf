variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition = contains(
      ["dev", "test", "staging", "production"],
      var.environment
    )
    error_message = "Use dev, test, staging, or production."
  }
}

variable "vpc_cidr" {
  description = "Environment VPC CIDR block"
  type        = string
}

variable "node_instance_types" {
  description = "EC2 instance types for EKS nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_capacity" {
  description = "EKS managed node group capacity"
  type = object({
    min     = number
    max     = number
    desired = number
  })

  default = {
    min     = 2
    max     = 4
    desired = 2
  }

  validation {
    condition = (
      var.node_capacity.min >= 0 &&
      var.node_capacity.min <= var.node_capacity.desired &&
      var.node_capacity.desired <= var.node_capacity.max
    )
    error_message = "Capacity must satisfy 0 <= min <= desired <= max."
  }
}

variable "rds_instance_class" {
  description = "RDS database instance class"
  type        = string
  default     = "db.t3.micro"
}
