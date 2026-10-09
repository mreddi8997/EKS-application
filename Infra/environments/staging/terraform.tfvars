environment         = "staging"
vpc_cidr            = "10.30.0.0/16"
node_instance_types = ["t3.small"]
rds_instance_class  = "db.t3.micro"

node_capacity = {
  min     = 2
  max     = 4
  desired = 2
}
