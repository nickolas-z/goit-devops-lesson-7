module "vpc" {
  source = "./vpc"

  region          = var.region
  aws_profile     = var.aws_profile
  vpc_name        = var.vpc_name
  vpc_cidr        = var.vpc_cidr
  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  cluster_name    = var.cluster_name
}

module "eks" {
  source = "./eks"

  region             = var.region
  aws_profile        = var.aws_profile
  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version

  # VPC outputs passed directly from root — remote state not needed
  use_remote_state   = false
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  cpu_instance_type = var.cpu_instance_type
  gpu_instance_type = var.gpu_instance_type
  desired_size      = var.desired_size
  min_size          = var.min_size
  max_size          = var.max_size
}

module "argocd" {
  source = "./argocd"

  region      = var.region
  aws_profile = var.aws_profile

  # Use direct EKS outputs when deploying the full stack from the root module.
  use_remote_state                   = false
  cluster_name                       = module.eks.cluster_name
  cluster_endpoint                   = module.eks.cluster_endpoint
  cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data

  namespace     = var.argocd_namespace
  chart_version = var.argocd_chart_version
}
