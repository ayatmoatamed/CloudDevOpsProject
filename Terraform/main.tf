module "Network" {
  source = "./modules/Network"
}

module "Server" {
  source    = "./modules/Server"
  public_subnet_id = module.Network.public_subnet_id
  vpc_id    = module.Network.vpc_id
  
}

module "EKS" {
  source = "./modules/EKS"

  vpc_id = module.Network.vpc_id

  private_subnet_ids = module.Network.private_subnet_ids
}

module "ECR" {
  source = "./modules/ECR"
}

