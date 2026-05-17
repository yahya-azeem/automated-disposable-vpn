terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# Fetch the latest official Alpine Linux AMI based on instance architecture
data "aws_ami" "alpine" {
  most_recent = true
  owners      = ["538276064493"] # Official Alpine Linux AMI Owner

  filter {
    name   = "name"
    values = ["alpine-3.*"]
  }

  filter {
    name   = "architecture"
    values = [length(regexall("^t4g", var.instance_type)) > 0 ? "arm64" : "x86_64"]
  }
}

# Minimal VPC dedicated to the disposable VPN node
resource "aws_vpc" "vpn" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = merge(var.tags, { Name = "trusttunnel-vpc-${var.region}" })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.vpn.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags                    = merge(var.tags, { Name = "trusttunnel-subnet-${var.region}" })
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpn.id
  tags   = merge(var.tags, { Name = "trusttunnel-igw-${var.region}" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpn.id
  tags   = merge(var.tags, { Name = "trusttunnel-rt-${var.region}" })
}

resource "aws_route" "internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group allowing TrustTunnel endpoint port and SSH
resource "aws_security_group" "vpn" {
  name        = "trusttunnel-sg-${var.region}"
  description = "Security group for TrustTunnel VPN node"
  vpc_id      = aws_vpc.vpn.id

  ingress {
    description = "TrustTunnel VPN Endpoint Port (TCP)"
    from_port   = var.endpoint_port
    to_port     = var.endpoint_port
    protocol    = "tcp"
    cidr_blocks = [var.allowed_client_ip_range]
  }

  ingress {
    description = "TrustTunnel VPN Endpoint Port (UDP)"
    from_port   = var.endpoint_port
    to_port     = var.endpoint_port
    protocol    = "udp"
    cidr_blocks = [var.allowed_client_ip_range]
  }

  ingress {
    description = "SSH access for Ansible provisioning"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "trusttunnel-sg-${var.region}" })
}

resource "aws_key_pair" "vpn" {
  count      = var.ssh_public_key != "" ? 1 : 0
  key_name   = "trusttunnel-key-${var.region}"
  public_key = var.ssh_public_key
  tags       = var.tags
}

# IAM Role for AWS Systems Manager (SSM) Session Manager access
resource "aws_iam_role" "ssm" {
  name = "trusttunnel-ssm-role-${var.region}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "trusttunnel-ssm-profile-${var.region}"
  role = aws_iam_role.ssm.name
  tags = var.tags
}

# The single micro EC2 instance for the active VPN node
resource "aws_instance" "vpn" {
  ami                  = data.aws_ami.alpine.id
  instance_type        = var.instance_type
  subnet_id            = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.vpn.id]
  iam_instance_profile = aws_iam_instance_profile.ssm.name
  key_name             = var.ssh_public_key != "" ? aws_key_pair.vpn[0].key_name : null

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  tags = merge(var.tags, { Name = "trusttunnel-node-${var.region}" })
}
