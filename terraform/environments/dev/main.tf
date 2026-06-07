module "vpc" {
  source = "../../modules/vpc"
}

resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "eks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "worker_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecr_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

module "eks_staging" {
  source = "../../modules/eks"

  cluster_name = "staging-cluster"

  cluster_role_arn = aws_iam_role.eks_cluster_role.arn
  node_role_arn    = aws_iam_role.eks_node_role.arn

  subnet_ids = [
    module.vpc.private_subnet_1_id,
    module.vpc.private_subnet_2_id
  ]

  cluster_role_dependency = aws_iam_role_policy_attachment.eks_cluster_policy

  node_role_dependency = [
    aws_iam_role_policy_attachment.worker_node_policy,
    aws_iam_role_policy_attachment.cni_policy,
    aws_iam_role_policy_attachment.ecr_policy
  ]
}

resource "aws_eks_access_entry" "ops1_staging" {
  cluster_name  = module.eks_staging.cluster_name
  principal_arn = "arn:aws:iam::526015996702:user/ops1"

  depends_on = [
    module.eks_staging
  ]
}

resource "aws_eks_access_policy_association" "ops1_staging_admin" {

  depends_on = [
    aws_eks_access_entry.ops1_staging
  ]

  cluster_name  = module.eks_staging.cluster_name
  principal_arn = "arn:aws:iam::526015996702:user/ops1"

  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

module "eks_production" {
  source = "../../modules/eks"

  cluster_name = "production-cluster"

  cluster_role_arn = aws_iam_role.eks_cluster_role.arn
  node_role_arn    = aws_iam_role.eks_node_role.arn

  subnet_ids = [
    module.vpc.private_subnet_1_id,
    module.vpc.private_subnet_2_id
  ]

  cluster_role_dependency = aws_iam_role_policy_attachment.eks_cluster_policy

  node_role_dependency = [
    aws_iam_role_policy_attachment.worker_node_policy,
    aws_iam_role_policy_attachment.cni_policy,
    aws_iam_role_policy_attachment.ecr_policy
  ]
}

resource "aws_eks_access_entry" "ops1_production" {
  cluster_name  = module.eks_production.cluster_name
  principal_arn = "arn:aws:iam::526015996702:user/ops1"

  depends_on = [
    module.eks_production
  ]
}
resource "aws_eks_access_policy_association" "ops1_production_admin" {
  depends_on = [
    aws_eks_access_entry.ops1_production
  ]

  cluster_name  = module.eks_production.cluster_name
  principal_arn = "arn:aws:iam::526015996702:user/ops1"

  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}
module "rds" {
  source = "../../modules/rds"

  vpc_id = module.vpc.vpc_id

  private_subnet_ids = [
    module.vpc.private_subnet_1_id,
    module.vpc.private_subnet_2_id
  ]
}

module "runner" {
  source = "../../modules/runner"

  vpc_id = module.vpc.vpc_id

  subnet_ids = [
    module.vpc.public_subnet_1_id,
    module.vpc.public_subnet_2_id
  ]

  instance_type = "t3.large"

  runner_count = 4

  key_name = "depi-key"
}

resource "local_file" "ansible_inventory" {
  content = templatefile(
    "${path.module}/../../../ansible/inventory.tpl",
    {
      runner_ips = module.runner.public_ips
    }
  )

  filename = "${path.module}/../../../ansible/inventory.ini"
}

resource "null_resource" "run_ansible" {

  depends_on = [
    module.runner,
    local_file.ansible_inventory
  ]

  provisioner "local-exec" {
    command = "sleep 120 && ansible-playbook -i ../../../ansible/inventory.ini ../../../ansible/playbooks/github-runner.yml"
  }
}

data "aws_eks_cluster" "production" {
  name = module.eks_production.cluster_name
}

data "aws_eks_cluster_auth" "production" {
  name = module.eks_production.cluster_name
}

provider "kubernetes" {

  host = data.aws_eks_cluster.production.endpoint

  cluster_ca_certificate = base64decode(
    data.aws_eks_cluster.production.certificate_authority[0].data
  )

  token = data.aws_eks_cluster_auth.production.token
}

provider "helm" {

  kubernetes {

    host = data.aws_eks_cluster.production.endpoint

    cluster_ca_certificate = base64decode(
      data.aws_eks_cluster.production.certificate_authority[0].data
    )

    token = data.aws_eks_cluster_auth.production.token
  }
}

data "tls_certificate" "production_oidc" {
  url = module.eks_production.oidc_issuer
}

resource "aws_iam_openid_connect_provider" "production" {

  url = module.eks_production.oidc_issuer

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    data.tls_certificate.production_oidc.certificates[0].sha1_fingerprint
  ]
}

module "production_addons" {

  source = "../../modules/addons"

  cluster_name = module.eks_production.cluster_name

  oidc_issuer = module.eks_production.oidc_issuer

  oidc_provider_arn = aws_iam_openid_connect_provider.production.arn

  vpc_id = module.vpc.vpc_id

  depends_on = [
    module.eks_production
  ]
}