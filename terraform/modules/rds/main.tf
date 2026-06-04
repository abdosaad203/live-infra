resource "random_password" "db_password" {
  length  = 24
  special = true
}
resource "aws_secretsmanager_secret" "db_secret" {
  name = "ecommerce-db-credentials"
}
resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id = aws_secretsmanager_secret.db_secret.id

  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
  })
}
resource "aws_db_subnet_group" "this" {
  name = "ecommerce-db-subnet-group"

  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "ecommerce-db-subnet-group"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "ecommerce-rds-sg"
  description = "Allow MySQL access"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "this" {
  identifier = "ecommerce-db"

  allocated_storage = 20
  engine            = "mysql"
  engine_version    = "8.0"

  instance_class = "db.t3.micro"

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  publicly_accessible = false
  skip_final_snapshot = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  backup_retention_period = 0

  tags = {
    Name = "ecommerce-db"
  }
}