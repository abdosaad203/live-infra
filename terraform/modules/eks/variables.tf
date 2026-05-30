variable "cluster_name" {
  type = string
}

variable "cluster_role_arn" {
  type = string
}

variable "node_role_arn" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "cluster_role_dependency" {
}

variable "node_role_dependency" {
}