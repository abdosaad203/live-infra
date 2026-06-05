output "public_ips" {
  value = aws_instance.runner[*].public_ip
}

output "private_ips" {
  value = aws_instance.runner[*].private_ip
}

output "instance_ids" {
  value = aws_instance.runner[*].id
}