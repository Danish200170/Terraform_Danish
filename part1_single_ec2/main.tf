terraform {
  required_version = ">= 1.5.0"
  required_providers { aws = { source = "hashicorp/aws", version = "~> 5.0" } }
}
provider "aws" { region = var.aws_region }
data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"]
  filter { name = "name" values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"] }
  filter { name = "virtualization-type" values = ["hvm"] }
}
resource "aws_security_group" "app" {
  name = "${var.project_name}-sg"
  description = "Assignment app ports"
  ingress { from_port = 3000 to_port = 3000 protocol = "tcp" cidr_blocks = [var.allowed_cidr] }
  ingress { from_port = 5000 to_port = 5000 protocol = "tcp" cidr_blocks = [var.allowed_cidr] }
  dynamic "ingress" {
    for_each = var.key_name == "" ? [] : [1]
    content { from_port = 22 to_port = 22 protocol = "tcp" cidr_blocks = [var.allowed_cidr] }
  }
  egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
  tags = { Name = "${var.project_name}-sg" }
}
resource "aws_instance" "app" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name = var.key_name == "" ? null : var.key_name
  vpc_security_group_ids = [aws_security_group.app.id]
  user_data = <<-USERDATA
    #!/bin/bash
    set -euxo pipefail
    exec > >(tee -a /var/log/user-data-apps.log) 2>&1
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-venv python3-pip nodejs npm
    mkdir -p /opt/terraform-danish/flask /opt/terraform-danish/express
    cat > /opt/terraform-danish/flask/app.py <<'PY'
    from flask import Flask, jsonify
    app = Flask(__name__)
    @app.get("/")
    def home(): return jsonify(service="flask-backend", status="ok")
    @app.get("/api/hello")
    def hello(): return jsonify(message="Hello from Flask!", status="ok")
    PY
    python3 -m venv /opt/terraform-danish/flask/venv
    /opt/terraform-danish/flask/venv/bin/pip install Flask gunicorn
    cat > /etc/systemd/system/flask-app.service <<'UNIT'
    [Unit]
    Description=Flask assignment app
    After=network-online.target
    [Service]
    WorkingDirectory=/opt/terraform-danish/flask
    ExecStart=/opt/terraform-danish/flask/venv/bin/gunicorn --bind 0.0.0.0:5000 app:app
    Restart=always
    [Install]
    WantedBy=multi-user.target
    UNIT
    cat > /opt/terraform-danish/express/server.js <<'JS'
    const express = require('express'); const app = express();
    app.get('/', (_q,r)=>r.send('<h1>Express frontend is running</h1><p><a href="/api/hello">Test Flask API</a></p>'));
    app.get('/api/hello', async (_q,r)=>{try { const x=await fetch('http://127.0.0.1:5000/api/hello'); r.status(x.status).send(await x.text()); } catch(e) { r.status(502).json({error:e.message}); }});
    app.listen(3000,'0.0.0.0',()=>console.log('Express listening on 3000'));
    JS
    cd /opt/terraform-danish/express
    npm init -y
    npm install express
    cat > /etc/systemd/system/express-app.service <<'UNIT'
    [Unit]
    Description=Express assignment app
    After=network-online.target flask-app.service
    [Service]
    WorkingDirectory=/opt/terraform-danish/express
    ExecStart=/usr/bin/node /opt/terraform-danish/express/server.js
    Restart=always
    [Install]
    WantedBy=multi-user.target
    UNIT
    systemctl daemon-reload
    systemctl enable --now flask-app express-app
  USERDATA
  user_data_replace_on_change = true
  tags = { Name = "${var.project_name}-ec2" }
}
