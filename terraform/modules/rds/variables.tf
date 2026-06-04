variable "db_name" {
  default = "ecommerce"
}

variable "db_username" {
  default = "admin"
}


variable "private_subnet_ids" {
  type = list(string)
}

variable "vpc_id" {}

variable "allowed_cidr" {
  default = "10.0.0.0/16"
}