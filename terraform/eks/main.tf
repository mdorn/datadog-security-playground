# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

# Filter out local zones, which are not currently supported 
# with managed node groups
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  cluster_name = "datadog-security-playground-eks-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "playground" {
  name               = "eks-pod-identity-playground"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_eks_pod_identity_association" "association" {
  cluster_name = local.cluster_name
  namespace = var.playground_namespace
  service_account = var.service_account_name
  role_arn = aws_iam_role.playground.arn
}

# Create Kubernetes namespace for the playground
resource "kubernetes_namespace" "playground" {
  metadata {
    name = var.playground_namespace
  }
}

# Create Kubernetes namespace for the Datadog agent
resource "kubernetes_namespace" "datadog" {
  metadata {
    name = var.datadog_namespace
  }
}

# Create Kubernetes service account
resource "kubernetes_service_account" "playground" {
  metadata {
    name      = var.service_account_name
    namespace = kubernetes_namespace.playground.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.playground.arn
    }
  }
}

# Create service account token
resource "kubernetes_secret" "playground_token" {
  depends_on = [kubernetes_service_account.playground]
  
  metadata {
    name      = "${var.service_account_name}-token"
    namespace = kubernetes_namespace.playground.metadata[0].name
    annotations = {
      "kubernetes.io/service-account.name" = var.service_account_name
    }
  }
  type = "kubernetes.io/service-account-token"
}

# Create Ubuntu pod for testing
resource "kubernetes_pod" "playground" {
  depends_on = [kubernetes_service_account.playground]
  
  metadata {
    name      = "ubuntu-test-pod"
    namespace = kubernetes_namespace.playground.metadata[0].name
  }
  
  spec {
    service_account_name = var.service_account_name
    
    container {
      name  = "ubuntu"
      image = "ubuntu:22.04"
      command = ["sleep", "36000"]  # Keep the pod running for 10 hours
      
      resources {
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
      }
    }
    
    restart_policy = "Never"
  }
}


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "datadog-security-playground-vpc"

  cidr = "10.0.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_name    = local.cluster_name
  cluster_version = "1.29"

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  # Enable audit logs only
  cluster_enabled_log_types              = ["audit"]
  cloudwatch_log_group_retention_in_days = 7

  cluster_addons = {
    eks-pod-identity-agent = {
      most_recent = true
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"

  }

  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }

    two = {
      name = "node-group-2"

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
  }
}

