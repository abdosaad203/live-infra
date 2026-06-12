data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_security_group" "runner_sg" {
  name   = "${var.environment}-runner-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-runner-sg"
  }
}

resource "aws_iam_role" "runner_role" {
  name = "${var.environment}-runner-role"

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

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.runner_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ecr" {
  role       = aws_iam_role.runner_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy" "secrets_access" {
  name = "${var.environment}-runner-secrets-access"
  role = aws_iam_role.runner_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue"
        ]

        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "runner_profile" {
  name = "${var.environment}-runner-profile"
  role = aws_iam_role.runner_role.name
}

resource "aws_instance" "runner" {
  count = var.runner_count

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  key_name = var.key_name

  iam_instance_profile        = aws_iam_instance_profile.runner_profile.name
  associate_public_ip_address = true

  subnet_id = element(
    var.subnet_ids,
    count.index % length(var.subnet_ids)
  )

  vpc_security_group_ids = [
    aws_security_group.runner_sg.id
  ]

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.environment}-runner-${count.index + 1}"
  }
}