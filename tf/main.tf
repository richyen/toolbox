provider "aws" {
  region = var.aws_region
}                          

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
    }
  }
}

locals {
  cluster_name = terraform.workspace
}

terraform {
  backend "s3" {
    bucket = "richyen-dev"
    key    = "richyen-dev-tfstate"
    region = "us-west-1"
  }
}

resource "aws_security_group" "rules" {
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [var.public_cidrblock]
  }

  dynamic "ingress" {
    for_each = var.service_ports
    iterator = service_port
    content {
      from_port = service_port.value.port
      to_port   = service_port.value.port
      protocol  = service_port.value.protocol
      description = service_port.value.description
      // This means, all ip address are allowed !
      // Not recommended for production.
      // Limit IP Addresses in a Production Environment !
      cidr_blocks = [var.public_cidrblock]
    }
  }

  tags = {
    Name = format("%s_%s", local.cluster_name, "security_rules")
  }
}

resource "tls_private_key" "aws_ec2" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content         = tls_private_key.aws_ec2.private_key_pem
  filename        = "aws_ec2.pem"
  file_permission = "0600"
}

resource "aws_key_pair" "key_pair" {
  public_key = tls_private_key.aws_ec2.public_key_openssh
  key_name = var.key_name
}

data "aws_subnet" "selected" {
  vpc_id            = var.vpc_id
  availability_zone = var.az
  cidr_block        = var.cidr_block
}

resource "aws_instance" "machine" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.key_pair.id
  subnet_id              = data.aws_subnet.selected.id
  vpc_security_group_ids = [aws_security_group.rules.id]

  root_block_device {
    volume_type = "gp2"
    volume_size = 50
  }

  tags = {
    Name       = local.cluster_name
    Created_By = var.created_by
  }
}

resource "null_resource" "configure" {
  connection {
    user = "ubuntu"
    host = aws_instance.machine.public_ip
    private_key="${file(local_file.private_key.filename)}"
    agent = true
    timeout = "3m"
  }

  provisioner "file" {
    source      = "/home/richyen/.ssh/id_rsa"
    destination = "/home/${var.ssh_user}/.ssh/id_rsa"
  }

  provisioner "remote-exec" {
    inline = [
      "git clone https://github.com/richyen/dotfiles.git",
      "./dotfiles/bootstrap.sh --force",
      "chmod 600 .ssh/id_rsa"
    ]
  }

  provisioner "file" {
    source      = "/home/richyen/.exports_local"
    destination = "/home/${var.ssh_user}/.exports_local"
  }
}

resource "local_file" "servers_yml" {
  filename        = "${abspath(path.root)}/servers.yml"
  file_permission = "0600"
  content         = <<-EOT
---
servers:
    type: ${var.instance_type}
    region: ${var.aws_region}
    az: ${var.az}
    public_ip: ${aws_instance.machine.public_ip}
    private_ip: ${aws_instance.machine.private_ip}
    public_dns: ${aws_instance.machine.public_dns}
EOT
}

output "ec2_public_ip" {
  value = aws_instance.machine.public_ip
}
