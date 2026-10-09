environment         = "dev"
vpc_cidr            = "10.10.0.0/16"
node_instance_types = ["t3.medium"]
rds_instance_class  = "db.t3.micro"

node_capacity = {
  min     = 2
  max     = 4
  desired = 2
}
