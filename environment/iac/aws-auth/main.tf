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

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"  # Adjust the path if your kubeconfig is located elsewhere
}

provider "kubectl" {
  config_path = "~/.kube/config"  # Adjust the path if your kubeconfig is located elsewhere
}

resource "kubectl_manifest" "aws_auth" {
  yaml_body = <<YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: arn:aws:iam::ACCOUNT:role/eks-admin-role
      username: admin
      groups:
        - system:masters
    - rolearn: arn:aws:iam::ACCOUNT:role/eks-developer-role
      username: developer
      groups:
        - system:masters
YAML
}
