variable "region" { 
  description = "The AWS region to deploy to"
  type        = string
  default     = "us-east-1"  
}

variable "cluster_data" {
  description = "The EKS cluster data"
  type        = object({
    k8s_name = string
    k8s_version = string
  })
  default = {
    k8s_name = "lgc-eks-challenge"
    k8s_version = "1.25"
  }
}



variable "vpc_data" {
  description = "The VPC data"
  type        = object({
    cidr_block = string
    tags       = map(string)
    name       = string
    private_subnets = list(string)
    public_subnets  = list(string)
  })
  default = {
    cidr_block = "10.25.0.0/16"
    tags = {
      Name = "lgc-eks-challenge"
    }
    private_subnets = [ "10.25.0.0/18", "10.25.64.0/18" ]
    public_subnets = [ "10.25.128.0/18", "10.25.192.0/18" ]
    name = "vpc-lgc-eks-challenge"
  }
}


