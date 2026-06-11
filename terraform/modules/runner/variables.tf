variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "instance_type" {
  type    = string
  default = "t3.large"
}

variable "runner_count" {
  type    = number
  default = 4
}

variable "key_name" {
  type = string
}

variable "environment" {
  type = string
}