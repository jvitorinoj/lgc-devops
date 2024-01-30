terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

provider aws  {
    region = var.region
    profile = "default"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = var.vpc_data.name
  cidr = var.vpc_data.cidr_block
  azs  = slice(data.aws_availability_zones.available.names, 0, 2)

  private_subnets = var.vpc_data.private_subnets
  public_subnets  = var.vpc_data.public_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_data.k8s_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_data.k8s_name}" = "shared"    
  }
  tags = {
        environment = "dev"
    }
}


module "eks" {
    source = "terraform-aws-modules/eks/aws"
    version = "~> 19.0"

    cluster_name = var.cluster_data.k8s_name
    cluster_version = var.cluster_data.k8s_version    
    cluster_endpoint_public_access = true  # set to false to make it private
    cluster_addons = {
        coredns = {
            most_recent = true
        }
        kube-proxy = {
            most_recent = true
        }
    }
    vpc_id = module.vpc.vpc_id
    subnet_ids = module.vpc.private_subnets

    eks_managed_node_group_defaults = {
        ami_type       = "AL2_x86_64"
        instance_types = ["t2.micro", "t2.small", "t3.micro"]
        am_role_attach_cni_policy = true
    }
    
    eks_managed_node_groups = {
        blue = {
            min_size     = 0  # It requires a extra work to scale from 0 instances using autoscaler
            max_size     = 2
            desired_size = 1      
            capacity_type  = "SPOT"            
        }
        green = {
            min_size     = 1
            max_size     = 2
            desired_size = 1      
            capacity_type  = "SPOT"
    }
  }
}


