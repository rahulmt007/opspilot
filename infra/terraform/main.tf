data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_vpc" "main" {
  # checkov:skip=CKV2_AWS_11: Flow-log storage adds cost to this short-lived free-tier showcase.
  cidr_block           = "10.42.0.0/16"
  enable_dns_hostnames = true
}
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id
}
resource "aws_internet_gateway" "main" { vpc_id = aws_vpc.main.id }
resource "aws_subnet" "public" {
  # checkov:skip=CKV_AWS_130: Public addressing avoids a paid NAT Gateway for this ephemeral demo.
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.42.1.0/24"
  map_public_ip_on_launch = true
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
resource "aws_security_group" "app" {
  # checkov:skip=CKV_AWS_24: Optional SSH ingress is disabled by default and restricted to validated /32 CIDRs.
  name_prefix = "opspilot-"
  description = "OpsPilot ephemeral showcase access"
  vpc_id      = aws_vpc.main.id
  ingress {
    description = "demo HTTP"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  dynamic "ingress" {
    for_each = length(var.ssh_cidrs) == 0 ? [] : [1]
    content {
      description = "temporary SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.ssh_cidrs
    }
  }
  egress {
    description = "HTTPS package and container downloads"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_key_pair" "deployer" {
  count           = var.public_key == "" ? 0 : 1
  key_name_prefix = "opspilot-"
  public_key      = var.public_key
}
resource "aws_instance" "app" {
  # checkov:skip=CKV_AWS_126: Detailed monitoring adds cost to this short-lived free-tier showcase.
  # checkov:skip=CKV2_AWS_41: The instance needs no AWS API access, so attaching an IAM role adds needless privilege.
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name               = var.public_key == "" ? null : aws_key_pair.deployer[0].key_name
  ebs_optimized          = true
  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }
  root_block_device {
    encrypted   = true
    volume_size = var.root_volume_gb
    volume_type = "gp3"
  }
  user_data_replace_on_change = true
  user_data                   = <<-EOF
    #!/bin/bash
    dnf install -y docker
    systemctl enable --now docker
    docker run --pull always -d --restart unless-stopped --name opspilot -p 8000:8000 ${var.image_repository}@${var.image_digest}
  EOF
}
resource "aws_budgets_budget" "monthly" {
  name         = "${var.project}-monthly"
  budget_type  = "COST"
  limit_amount = tostring(var.budget_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  dynamic "notification" {
    for_each = var.budget_email == "" ? [] : [1]
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = 80
      threshold_type             = "PERCENTAGE"
      notification_type          = "FORECASTED"
      subscriber_email_addresses = [var.budget_email]
    }
  }
}
