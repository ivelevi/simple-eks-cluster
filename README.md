# EKS Cluster Deployment

This repository contains the necessary Terraform configurations to deploy an EKS cluster along with essential add-ons.

## Prerequisites

- Terraform installed
- AWS CLI configured with appropriate permissions
- Git installed

## Steps to Deploy

1. **Clone the Repository**

```sh
git clone https://github.com/ivelevi/simple-eks-cluster
cd simple-eks-cluster
```
2. **Update Variables**

Update the variables in the .tf files located in each folder with your values (account, region, etc).

3. **Deploy the Infrastructure**

Follow these steps in sequence:

State
Navigate to the state folder and run Terraform.

```sh
cd \environment\iac\state
terraform init
terraform apply
```

Network
Navigate to the network folder and run Terraform.

```sh
cd ../network
terraform init
terraform apply
```

EKS
Navigate to the eks folder and run Terraform.

```sh
cd ../eks
terraform init
terraform apply
```

Accessing the EKS Cluster

After deploying the EKS cluster, update your kubeconfig file to access the cluster:

```sh
aws eks update-kubeconfig --region <region> --name <cluster-name>
```

RBAC
Navigate to the rbac folder and run Terraform.

```sh
cd ../rbac
terraform init
terraform apply
```

AWS Auth
Navigate to the aws-auth folder and run Terraform.

```sh
cd ../aws-auth
terraform init
terraform apply
```

Add-ons
Navigate to the addons folder and run Terraform for each add-on.

NGINX

```sh
cd ../addons/nginx
terraform init
terraform apply
```

Cert-Manager

```sh
cd ../addons/cert-manager
terraform init
terraform apply
```

Prometheus
```sh
cd ../addons/prometheus
terraform init
terraform apply
```

# Notes
Ensure that you have the correct AWS permissions to create the resources.
Review the Terraform plans before applying to understand the changes being made.
Monitor the deployment process and verify the resources once created.
