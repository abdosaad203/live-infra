output "runner_public_ips" {
  value = module.runner.public_ips
}

output "runner_private_ips" {
  value = module.runner.private_ips
}

output "staging_cluster_name" {
  value = module.eks_staging.cluster_name
}

output "staging_cluster_endpoint" {
  value = module.eks_staging.cluster_endpoint
}

output "staging_cluster_ca" {
  value = module.eks_staging.cluster_ca
}

output "staging_oidc_issuer" {
  value = module.eks_staging.oidc_issuer
}

output "production_cluster_name" {
  value = module.eks_production.cluster_name
}

output "production_cluster_endpoint" {
  value = module.eks_production.cluster_endpoint
}

output "production_cluster_ca" {
  value = module.eks_production.cluster_ca
}

output "production_oidc_issuer" {
  value = module.eks_production.oidc_issuer
}

output "vpc_id" {
  value = module.vpc.vpc_id
}