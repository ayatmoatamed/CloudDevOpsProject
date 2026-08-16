module "Network" {
  source = "./modules/Network"
}

module "Server" {
  source           = "./modules/Server"
  public_subnet_id = module.Network.public_subnet_ids[0]
  vpc_id           = module.Network.vpc_id
}

module "EKS" {
  source = "./modules/EKS"

  private_subnet_ids = module.Network.private_subnet_ids
}

module "ECR" {
  source = "./modules/ECR"
}

moved {
  from = module.Network.aws_subnet.public_subnet
  to   = module.Network.aws_subnet.public_subnet_1
}