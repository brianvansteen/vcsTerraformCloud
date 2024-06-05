terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "Daiqlos"
    workspaces {
      name = "vcsTerraformCloud"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "aws" {
  # profile = "default"
  region = "us-east-2"
  alias  = "east"
}

provider "aws" {
  # profile = "default"
  region = "us-west-1"
  alias  = "west"
}

locals {
  ingress_rules = [{
    port        = 443
    description = "HTTPS 443"
    },
    {
      port        = 80
      description = "HTTP 80"
  }]
}

data "aws_vpc" "main" { # data sources defined outside of Terraform
  id = "vpc-da5530bc"
}



resource "aws_security_group" "inbound" {
  name = "security_group"
  # vpc_id = data.aws_vpc.main.id
  vpc_id = var.vpc_id
  dynamic "ingress" {
    for_each = local.ingress_rules
    content {
      description      = ingress.value.description
      from_port        = ingress.value.port
      to_port          = ingress.value.port
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = ["sg-a77e10db"]
      self             = false
    }
  }

}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer_key"
  public_key = var.public_key
}

data "aws_ami" "east-amazon-linux-2" {
  provider    = aws.east
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

data "aws_ami" "west-amazon-linux-2" {
  provider    = aws.west
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_instance" "my_east_server" {
  ami           = data.aws_ami.east-amazon-linux-2.id
  instance_type = "t2.micro"
  provider      = aws.east
  tags = {
    Name = "Server-East"
  }
}

resource "aws_instance" "my_west_server" {
  ami           = data.aws_ami.west-amazon-linux-2.id
  instance_type = "t2.micro"
  provider      = aws.west
  tags = {
    Name = "Server-East"
  }
  lifecycle {
    prevent_destroy = false
  }
}
























output "east_public_ip" {
  value = aws_instance.my_east_server.public_ip
}
output "west_public_ip" {
  value = aws_instance.my_west_server.public_ip
}