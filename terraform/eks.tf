# eks.tf

module "eks" {
  source = "./modules/eks"

  name               = "kst-diplom-eks-cluster"
  kubernetes_version = "1.31" 

  endpoint_public_access = true
  
  # Интеграция прав администратора для вашей учетной записи
  enable_cluster_creator_admin_permissions = true

  # Авторизация в гибридный режим, чтобы ноды могли пройти аутентификацию
  authentication_mode = "API_AND_CONFIG_MAP"

  # Включает механизм доверия OIDC/IRSA для авторизации подов
  enable_irsa = true

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  # Встроенные сетевые аддоны (используем вашу структуру переменных)
  addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent    = true
      before_compute = true # Критично для правильной инициализации сети нод
    }
    eks-pod-identity-agent = {
      most_recent = true
    }  
  }

  eks_managed_node_groups = {
    main = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_types = ["c7i-flex.large"] 
      capacity_type  = "ON_DEMAND"        

      # Явно разрешаем AWS автоматически подключить ноды к Access Entries
      create_access_entry = true

      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        AmazonEKS_CNI_Policy               = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
        AmazonEBSCSIDriverPolicy           = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }
    }
  }

  tags = {
    Environment = "diplom"
    Project     = "fs_support_app"
  }
}
