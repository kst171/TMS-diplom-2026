terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    # ДОБАВЛЕНО: Декларируем провайдер для управления правами внутри Kubernetes
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20.0"
    }
    # ДОБАВЛЕНО: Плагин для автоматической сборки secret.yaml на диске
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

# ДОБАВЛЕНО: Настройка подключения провайдера kubernetes к вашему реальному EKS
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  # Форсируем генерацию свежего токена суперадминистратора кластера через AWS CLI
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", "kst-diplom-eks-cluster", "--region", "eu-north-1"]
  }
}
