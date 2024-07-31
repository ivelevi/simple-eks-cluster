provider "aws" {
  region = "" # Your Region 
}

# Configure the S3 backend
terraform {
  backend "s3" {
    bucket         = "" # Your state bucket
    key            = "YOURFOLDER/terraform.tfstate" # Be aware of the state folder, good practice to use the same name of this terraform folder
    region         = ""  # Your Region
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

# Data source to get remote state from network
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "autopilot-terraformstate"
    key    = "network/terraform.tfstate"
    region = "us-east-2"  # Replace with your desired AWS region
  }
}


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "autopilot-prod"
  cluster_version = "1.30"

  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  vpc_id                    = data.terraform_remote_state.network.outputs.vpc_id
  subnet_ids                = data.terraform_remote_state.network.outputs.subnet_ids
  control_plane_subnet_ids  = data.terraform_remote_state.network.outputs.subnet_ids

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["m5.large", "m5n.large", "m5zn.large"]
  }

  eks_managed_node_groups = {
    example = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["m5.xlarge"]

      min_size     = 1
      max_size     = 10
      desired_size = 1
    }
  }

  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true
  access_entries = {
    example = {
      kubernetes_groups = []
      principal_arn     = "arn:aws:iam::ACCOUNT:role/eks-adm"

      policy_associations = {
        example = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
          access_scope = {
            namespaces = ["default"]
            type       = "namespace"
          }
        }
      }
    }
  }

  tags = {
    Environment = "env"
    Terraform   = "true"
  }
}