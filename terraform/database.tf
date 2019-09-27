######################################################
## RDS, based on PostgreSQL
######################################################
## DATABASE.PLAN
## terraform plan -target=module.db -out 3dat.plan && terraform apply 3dat.plan

module "db" {
  source            = "terraform-aws-modules/rds/aws"
  version           = "~> 2.0"
  identifier        = "db"
  engine            = "postgres"
  engine_version    = "10"
  instance_class    = "db.t2.micro"
  allocated_storage = 5

  name     = "ruby"
  username = "root"
  password = "password"
  port     = "5432"

  iam_database_authentication_enabled = true
  vpc_security_group_ids              = ["${aws_security_group.sg_db.id}"]
  maintenance_window                  = "Mon:00:00-Mon:03:00"
  backup_window                       = "03:00-06:00"
  # monitoring_interval = "30"
  monitoring_role_name   = "MyRDSMonitoringRole"
  create_monitoring_role = true
  family                 = "postgres10"

  tags = {
    Owner       = "user"
    Environment = "dev"
  }
  subnet_ids          = ["${aws_subnet.priv-1.id}","${aws_subnet.priv-2.id}"]
  deletion_protection = false
}
