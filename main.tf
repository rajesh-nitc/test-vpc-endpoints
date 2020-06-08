provider "aws" {
  version = "~> 2.0"
  region  = "ap-south-1"
}

locals {
  ports = {
    Http   = "80"
    Ssh = "22"
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_s3_endpoint = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

resource "aws_instance" "test_instance" {
  count = 2

  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = "monitoring" 
  vpc_security_group_ids = [
      aws_security_group.test.id,
  ]

  user_data = templatefile("${path.module}/templates/sample.tmpl", {})
  iam_instance_profile = aws_iam_instance_profile.test_profile.name

  subnet_id = count.index == 0 ? element(module.vpc.public_subnets,0) : element(module.vpc.private_subnets,0)

  tags = {
    Name   = count.index == 0 ? "Public" : "Private"
  }

}

resource "aws_security_group" "test" {
  name   = "allow_all"
  vpc_id      = module.vpc.vpc_id
  
  dynamic "ingress" {
    for_each = local.ports
    content {
      from_port = ingress.value
      to_port = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_instance_profile" "test_profile" {
  name = "test_profile"
  role = aws_iam_role.role.name
}

resource "aws_iam_role" "role" {
  name = "test_role"
  path = "/"

  assume_role_policy = templatefile("${path.module}/iam/assume-role-policy.tmpl", {})
}

resource "aws_iam_policy" "policy" {
  name        = "test-policy"
  policy      = templatefile("${path.module}/iam/iam-policy.tmpl", {})
}

resource "aws_iam_policy_attachment" "test-attach" {
  name       = "test-attachment"
  roles      = [aws_iam_role.role.name]
  policy_arn = aws_iam_policy.policy.arn
}