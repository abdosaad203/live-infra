output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "oidc_issuer" {
  value = module.eks.oidc_issuer
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "db_endpoint" {
  value = module.rds.db_endpoint
}