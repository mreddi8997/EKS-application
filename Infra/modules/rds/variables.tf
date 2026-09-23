variable "rds_db_name" {
  description = "The name of the RDS database"
  type        = string
  nullable    = false

  validation {
    condition     = length(var.rds_db_name) > 0
    error_message = "The database name cannot be empty."
  }
}

variable "rds_instance_class" {
  description = "The instance class for the RDS database"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "The allocated storage (in GB) for the RDS database"
  type        = number
  default     = 20
}

variable "rds_engine" {
  description = "The database engine for the RDS instance"
  type        = string
  default     = "postgres"
}

variable "rds_storage_type" {
  description = "The storage type for the RDS instance"
  type        = string
  default     = "gp3"
}

variable "rds_engine_version" {
  description = "The engine version for the RDS instance"
  type        = string
  default     = "15.3"
}

variable "rds_parameter_group_name" {
  description = "The name of the RDS parameter group"
  type        = string
  default     = "default.postgres15"
}

variable "rds_skip_final_snapshot" {
  description = "Whether to skip the final snapshot when deleting the RDS instance"
  type        = bool
  default     = true
}

variable "rds_allowed_security_groups" {
  description = "List of security group IDs allowed to access the RDS instance"
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.rds_allowed_security_groups) > 0
    error_message = "At least one security group must be specified to allow access to the RDS instance."
  }
}

variable "vpc_name" {
  type        = string
  description = "The name of the VPC"
}

variable "rds_db_subnet_ids" {
  description = "List of subnet IDs for the RDS database"
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.rds_db_subnet_ids) > 0
    error_message = "At least one subnet ID must be specified for the RDS database."
  }
}

variable "rds_username" {
  description = "specify the db username"
  type        = string
}

variable "vpc_id" {
  type = string
}
