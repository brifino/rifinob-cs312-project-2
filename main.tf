terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

# Configure the AWS Provider
provider "aws" {
  region                   = "us-west-2"
  shared_credentials_files = ["./credentials"]
}

# Key pair for SSH access
resource "aws_key_pair" "minecraft_key" {
  key_name   = "minecraft_key"
  public_key = file("${path.module}/minecraft-key.pub")
}


# Security group for Minecraft server
resource "aws_security_group" "minecraft_security_group" {
  name        = "minecraft-security-group"
  description = "Allow inbound traffic on port 25565"

  # Ingress rule for SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound traffic on port 25565 - Minecraft server port
  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 instance for Minecraft server
resource "aws_instance" "minecraft_server" {
  ami                    = "ami-00a0b62a1660255c0"
  instance_type          = "t4g.small"
  key_name               = aws_key_pair.minecraft_key.key_name
  vpc_security_group_ids = [aws_security_group.minecraft_security_group.id]

  tags = {
    Name = "minecraft-server"
  }
}

