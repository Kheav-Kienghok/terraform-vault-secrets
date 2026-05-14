data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_security_group" "vault" {
  name        = "vault-demo-sg"
  description = "Vault demo instance: SSH and Vault UI/API"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Vault API and UI"
    from_port   = 8200
    to_port     = 8200
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
    Name = "vault-demo-sg"
  }
}

resource "aws_instance" "vault" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.vault.id]
  user_data              = file("${path.module}/userdata.sh")

  tags = {
    Name = "vault-demo"
  }
}

resource "aws_eip" "vault" {
  instance = aws_instance.vault.id

  tags = {
    Name = "vault-demo-eip"
  }
}
