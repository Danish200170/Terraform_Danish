
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "app" {
  name        = "${var.project_name}-sg"
  description = "Assignment app ports"

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  dynamic "ingress" {
    for_each = var.key_name == "" ? [] : [1]

    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.allowed_cidr]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name               = var.key_name != "" ? var.key_name : null

  user_data = <<-USERDATA
    #!/bin/bash
    set -euxo pipefail
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y python3 python3-pip python3-venv nodejs npm

    mkdir -p /opt/terraform-app/flask /opt/terraform-app/express

    cat > /opt/terraform-app/flask/app.py <<'PYTHON'
    from flask import Flask, jsonify
    from flask_cors import CORS
    app = Flask(__name__)
    CORS(app)

    @app.get("/")
    def home():
        return jsonify({"service": "flask-backend", "status": "ok"})

    @app.get("/api/hello")
    def hello():
        return jsonify({"message": "Hello from Flask backend!"})
    PYTHON

    printf 'Flask\nflask-cors\ngunicorn\n' > /opt/terraform-app/flask/requirements.txt
    python3 -m venv /opt/terraform-app/flask/venv
    /opt/terraform-app/flask/venv/bin/pip install -r /opt/terraform-app/flask/requirements.txt

    cat > /opt/terraform-app/express/server.js <<'JS'
    const express = require("express");
    const app = express();
    app.get("/", (req, res) => res.json({service:"express-frontend",status:"ok"}));
    app.listen(3000, "0.0.0.0");
    JS

    cd /opt/terraform-app/express
    npm init -y
    npm install express

    cat > /etc/systemd/system/terraform-flask.service <<'SERVICE'
    [Unit]
    Description=Flask backend
    After=network.target
    [Service]
    WorkingDirectory=/opt/terraform-app/flask
    ExecStart=/opt/terraform-app/flask/venv/bin/gunicorn --bind 0.0.0.0:5000 app:app
    Restart=always
    [Install]
    WantedBy=multi-user.target
    SERVICE

    cat > /etc/systemd/system/terraform-express.service <<'SERVICE'
    [Unit]
    Description=Express frontend
    After=network.target
    [Service]
    WorkingDirectory=/opt/terraform-app/express
    ExecStart=/usr/bin/node /opt/terraform-app/express/server.js
    Restart=always
    [Install]
    WantedBy=multi-user.target
    SERVICE

    systemctl daemon-reload
    systemctl enable --now terraform-flask.service
    systemctl enable --now terraform-express.service
  USERDATA

  tags = {
    Name = var.project_name
  }
}
