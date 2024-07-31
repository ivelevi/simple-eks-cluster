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

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "helm_release" "kube-prometheus-stack" {
  name = "prometheus-stack"

  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "" # Your namespace
  create_namespace = true
  version          = "58.1.2"

  values = [
    "${file("values.yaml")}"
  ]
}
