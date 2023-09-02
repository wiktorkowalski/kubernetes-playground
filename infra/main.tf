provider "aws" {
  region = "eu-central-1"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  name = "playground"
  enable_nat_gateway = true
  enable_vpn_gateway = true
  cidr = "10.0.0.0/16"

  azs             = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  map_public_ip_on_launch = true
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"

  cluster_name    = "playground"
  cluster_version = "1.27"

  cluster_endpoint_public_access  = true

  cluster_addons = {
    # coredns = {
    #   most_recent = true
    # }
    # kube-proxy = {
    #   most_recent = true
    # }
    # vpc-cni = {
    #   most_recent = true
    # }
    # adot = {
    #   most_recent = true
    # }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.public_subnets
  control_plane_subnet_ids = module.vpc.public_subnets

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["t3a.micro", "t3.micro", "t3a.small", "t3.small"]
  }

  eks_managed_node_groups = {
    default = {
      min_size     = 1
      max_size     = 10
      desired_size = 2

      instance_types = ["t3a.micro"]
      capacity_type  = "SPOT"
      
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
    Project     = "playground"
  }
}