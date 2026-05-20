# vpc.tf

module "vpc" {
  source = "./modules/vpc"

  name = "diplom-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-north-1a", "eu-north-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  intra_subnets   = ["10.0.201.0/24", "10.0.202.0/24"]

  # NAT Gateway для безопасного выхода приватной зоны в интернет
  enable_nat_gateway     = true
  single_nat_gateway     = true # Оптимизация бюджета для диплома
  one_nat_gateway_per_az = false

  # Обязательные теги для интеграции вашего VPC с AWS EKS
  private_subnet_tags = {
    "kubernetes.io/cluster/kst-diplom-eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/kst-diplom-eks-cluster" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }
}
