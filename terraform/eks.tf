module "eks" {
  source = "./modules/eks"

  name               = "kst-diplom-eks-cluster"
  kubernetes_version = "1.31" 

  endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true
  authentication_mode = "API_AND_CONFIG_MAP"
  enable_irsa = true

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent    = true
      before_compute = true
    }
    eks-pod-identity-agent = {
      most_recent = true
    }  
  }

  eks_managed_node_groups = {
    main = {
      min_size     = 1
      max_size     = 2
      desired_size = 1

      instance_types = ["c7i-flex.large"] 
      capacity_type  = "ON_DEMAND"        

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

resource "kubernetes_config_map_v1_data" "aws_auth" {
  force = true
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = "[]"
    
    mapUsers = <<YAML
- userarn: arn:aws:iam::${var.aws_account_id}:user/github-actions-user
  username: github-actions-user
  groups:
    - system:masters
YAML
  }

  depends_on = [module.eks]
}

resource "kubernetes_cluster_role_binding_v1" "github_actions_arn_binding" {
  metadata {
    name = "github-actions-arn-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "User"
    name      = "arn:aws:iam::${var.aws_account_id}:user/github-actions-user"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "User"
    name      = "github-actions-user"
    api_group = "rbac.authorization.k8s.io"
  }

  depends_on = [module.eks]
}