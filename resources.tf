##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "eu-central-1"
}

##################################################################################
# DATA
##################################################################################

data "aws_availability_zones" "available" {}

##################################################################################
# RESOURCES
##################################################################################

# NETWORKING #
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = "Terraform"

  cidr            = "10.0.0.0/16"
  azs             = ["eu-central-1a"]
  public_subnets  = ["10.0.0.1/24"]
  private_subnets = ["10.0.105.0/24"]

  enable_nat_gateway = false

  create_database_subnet_group = false

  tags {}
}

module "ec2" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name           = "Web Server"
  instance_count = 1

  ami                         = "ami-5055cd3f"
  instance_type               = "t2.micro"
  key_name                    = "newKey"
  vpc_security_group_ids      = ["${module.aws_security_group.this_security_group_id}"]
  subnet_id                   = "${module.vpc.public_subnets[0]}"
  associate_public_ip_address = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "ec2_db" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name           = "Database"
  instance_count = 1

  ami                         = "ami-5055cd3f"
  instance_type               = "t2.micro"
  key_name                    = "newKey"
  vpc_security_group_ids      = ["${module.aws_db_security_group.this_security_group_id}"]
  subnet_id                   = "${module.vpc.private_subnets[0]}"
  associate_public_ip_address = false

  tags = {
    Terraform   = "true"
    Environment = "DB"
  }
}

#SG
module "aws_security_group" {
  source = "terraform-aws-modules/security-group/aws//modules/ssh"

  name        = "SSH-SG"
  description = "Security group with port 22 open to the world"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress_cidr_blocks = ["0.0.0.0/0"]
}

module "aws_db_security_group" {
  source = "terraform-aws-modules/security-group/aws//modules/mysql"

  name        = "DB-SG"
  description = "Security group for DB"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress_cidr_blocks = ["195.212.29.82/32"]
}
