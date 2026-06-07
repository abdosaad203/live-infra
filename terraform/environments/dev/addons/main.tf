data "terraform_remote_state" "infra" {

  backend = "s3"

  config = {
    bucket = "route-state"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_eks_cluster" "production" {
  name = data.terraform_remote_state.infra.outputs.production_cluster_name
}

data "aws_eks_cluster_auth" "production" {
  name = data.terraform_remote_state.infra.outputs.production_cluster_name
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
  url = data.terraform_remote_state.infra.outputs.production_oidc_issuer
}

resource "aws_iam_openid_connect_provider" "production" {

  url = data.terraform_remote_state.infra.outputs.production_oidc_issuer

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    data.tls_certificate.production_oidc.certificates[0].sha1_fingerprint
  ]
}

module "production_addons" {

  source = "../../../modules/addons"

  cluster_name = data.terraform_remote_state.infra.outputs.production_cluster_name

  oidc_issuer = data.terraform_remote_state.infra.outputs.production_oidc_issuer

  oidc_provider_arn = aws_iam_openid_connect_provider.production.arn

  vpc_id = data.terraform_remote_state.infra.outputs.vpc_id
}