module "vpc" {
  source = "../"
  name        = "homelike-vpc"
  environment = "test"
  label_order = ["name", "environment"]
  cidr_block = "20.10.0.0/16" # 10.0.0.0/8 is reserved for EC2-Classic

  azs                 = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  private_subnets     = ["20.10.1.0/24", "20.10.2.0/24", "20.10.3.0/24"]
  public_subnets      = ["20.10.11.0/24", "20.10.12.0/24", "20.10.13.0/24"]
  database_subnets    = ["20.10.21.0/24", "20.10.22.0/24", "20.10.23.0/24"]

  vpc_enabled         = true
}
