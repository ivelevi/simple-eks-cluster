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

resource "helm_release" "external_nginx" {
  name = "external"

  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress"
  create_namespace = true
  version          = "4.8.0"

  values = [file("${path.module}/values.yaml")]
}
