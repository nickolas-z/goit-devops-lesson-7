provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

data "terraform_remote_state" "eks" {
  count   = var.use_remote_state ? 1 : 0
  backend = "local"
  config = {
    path = var.eks_state_path
  }
}

locals {
  # Allows this module to run both from the root module and standalone after EKS exists.
  cluster_name                       = var.use_remote_state ? data.terraform_remote_state.eks[0].outputs.cluster_name : var.cluster_name
  cluster_endpoint                   = var.use_remote_state ? data.terraform_remote_state.eks[0].outputs.cluster_endpoint : var.cluster_endpoint
  cluster_certificate_authority_data = var.use_remote_state ? data.terraform_remote_state.eks[0].outputs.cluster_certificate_authority_data : var.cluster_certificate_authority_data
}

data "aws_eks_cluster_auth" "this" {
  name = local.cluster_name
}

provider "kubernetes" {
  host                   = local.cluster_endpoint
  cluster_ca_certificate = base64decode(local.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = local.cluster_endpoint
    cluster_ca_certificate = base64decode(local.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}
