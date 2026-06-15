data "terraform_remote_state" "shared" {

  backend = "s3"

  config = {
    bucket = "route-state"
    key    = "shared/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_iam_role" "eks_cluster_role" {
  name = "production-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "eks.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "eks_node_role" {
  name = "production-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ec2.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "worker_nodes" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecr" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

module "eks" {
  source = "../../modules/eks"

  cluster_name = "production-cluster"

  cluster_role_arn = aws_iam_role.eks_cluster_role.arn
  node_role_arn    = aws_iam_role.eks_node_role.arn

  subnet_ids = [
    data.terraform_remote_state.shared.outputs.private_subnet_1_id,
    data.terraform_remote_state.shared.outputs.private_subnet_2_id
  ]

  cluster_role_dependency = aws_iam_role_policy_attachment.eks_cluster_policy

  node_role_dependency = [
    aws_iam_role_policy_attachment.worker_nodes,
    aws_iam_role_policy_attachment.cni,
    aws_iam_role_policy_attachment.ecr
  ]
}

module "addons" {
  source = "../../modules/addons"

  cluster_name      = module.eks.cluster_name
  oidc_issuer       = module.eks.oidc_issuer
  oidc_provider_arn = module.eks.oidc_provider_arn

  vpc_id = data.terraform_remote_state.shared.outputs.vpc_id
}

module "rds" {
  source = "../../modules/rds"

  environment = "production"
  deletion_protection = true

  vpc_id = data.terraform_remote_state.shared.outputs.vpc_id

  private_subnet_ids = [
    data.terraform_remote_state.shared.outputs.private_subnet_1_id,
    data.terraform_remote_state.shared.outputs.private_subnet_2_id
  ]
}