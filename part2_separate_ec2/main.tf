terraform {
  required_version = ">= 1.5.0"
  required_providers { aws = { source = "hashicorp/aws", version = "~> 5.0" } }
}
provider "aws" { region = var.aws_region }
data "aws_availability_zones" "available" { state = "available" }
data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"]
  filter { name = "name" values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"] }
  filter { name = "virtualization-type" values = ["hvm"] }
}
resource "aws_vpc" "main" {
  cidr_block = "10.20.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = { Name = "${var.project_name}-vpc" }
}
resource "aws_internet_gateway" "igw" { vpc_id = aws_vpc.main.id tags = { Name = "${var.project_name}-igw" } }
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.20.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = { Name = "${var.project_name}-public" }
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route { cidr_block = "0.0.0.0/0" gateway_id = aws_internet_gateway.igw.id }
  tags = { Name = "${var.project_name}-public-rt" }
}
resource "aws_route_table_association" "public" { subnet_id = aws_subnet.public.id route_table_id = aws_route_table.public.id }
resource "aws_security_group" "flask" {
  name = "${var.project_name}-flask-sg" vpc_id = aws_vpc.main.id description = "Flask backend"
  ingress { from_port = 5000 to_port = 5000 protocol = "tcp" cidr_blocks = [var.allowed_cidr] }
  ingress { from_port = 5000 to_port = 5000 protocol = "tcp" security_groups = [aws_security_group.express.id] }
  dynamic "ingress" { for_each = var.key_name == "" ? [] : [1] content { from_port = 22 to_port = 22 protocol = "tcp" cidr_blocks = [var.allowed_cidr] } }
  egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
}
resource "aws_security_group" "express" {
  name = "${var.project_name}-express-sg" vpc_id = aws_vpc.main.id description = "Express frontend"
  ingress { from_port = 3000 to_port = 3000 protocol = "tcp" cidr_blocks = [var.allowed_cidr] }
  dynamic "ingress" { for_each = var.key_name == "" ? [] : [1] content { from_port = 22 to_port = 22 protocol = "tcp" cidr_blocks = [var.allowed_cidr] } }
  egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
}
resource "aws_instance" "flask" {
  ami = data.aws_ami.ubuntu.id instance_type = var.instance_type subnet_id = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.flask.id]
  key_name = var.key_name == "" ? null : var.key_name
  user_data = <<-USERDATA
    #!/bin/bash
    set -euxo pipefail
    exec > >(tee -a /var/log/user-data-apps.log) 2>&1
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-venv python3-pip
    mkdir -p /opt/flask-app
    cat > /opt/flask-app/app.py <<'PY'
    from flask import Flask, jsonify
    app=Flask(__name__)
    @app.get("/")
    def home(): return jsonify(service="flask-backend",status="ok")
    @app.get("/api/hello")
    def hello(): return jsonify(message="Hello from separate Flask EC2!",status="ok")
    PY
    python3 -m venv /opt/flask-app/venv
    /opt/flask-app/venv/bin/pip install Flask gunicorn
    cat > /etc/systemd/system/flask-app.service <<'UNIT'
    [Unit]
    Description=Flask assignment app
    After=network-online.target
    [Service]
    WorkingDirectory=/opt/flask-app
    ExecStart=/opt/flask-app/venv/bin/gunicorn --bind 0.0.0.0:5000 app:app
    Restart=always
    [Install]
    WantedBy=multi-user.target
    UNIT
    systemctl daemon-reload
    systemctl enable --now flask-app
  USERDATA
  tags = { Name = "${var.project_name}-flask" }
}
resource "aws_instance" "express" {
  ami = data.aws_ami.ubuntu.id instance_type = var.instance_type subnet_id = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.express.id]
  key_name = var.key_name == "" ? null : var.key_name
  user_data = templatefile("${path.module}/express_user_data.sh.tftpl", { flask_private_ip = aws_instance.flask.private_ip })
  tags = { Name = "${var.project_name}-express" }
}
