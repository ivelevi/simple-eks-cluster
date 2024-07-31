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

# Admin role for yourself
resource "aws_iam_role" "eks_admin_role" {
  name = "eks-admin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = ["arn:aws:iam::ACCOUNT:user/YOUR-ADMIN-USER"]
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "eks-admin-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_admin_policy" {
  role       = aws_iam_role.eks_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Developer role for other team members
resource "aws_iam_role" "eks_developer_role" {
  name = "eks-developer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = ["arn:aws:iam::ACCOUNT:user/YOUR-ADMIN-USER", "arn:aws:iam::ACCOUNT:user/YOUR-DEV-USER"]
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "eks-developer-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_developer_policy" {
  role       = aws_iam_role.eks_developer_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "kubernetes_cluster_role_binding" "eks_admin_binding" {
  metadata {
    name = "eks-admin-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "User"
    name      = "arn:aws:iam::ACCOUNT:role/eks-admin-role"
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_cluster_role_binding" "eks_developer_binding" {
  metadata {
    name = "eks-developer-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "edit"
  }

  subject {
    kind      = "User"
    name      = "arn:aws:iam::ACCOUNT:role/eks-developer-role"
    api_group = "rbac.authorization.k8s.io"
  }
}
