variable "environment" {
  type = string
}

variable "db_name" {
  type    = string
  default = "ecommerce"
}

variable "db_username" {
  type    = string
  default = "admin"
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "allowed_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "deletion_protection" {
  type    = bool
  default = false
}