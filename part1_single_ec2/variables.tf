variable "aws_region" { description = "AWS region" type = string default = "ap-south-1" }
variable "instance_type" { description = "EC2 instance type" type = string default = "t3.micro" }
variable "key_name" { description = "Existing EC2 key pair name for SSH; leave blank to disable SSH ingress" type = string default = "" }
variable "allowed_cidr" { description = "CIDR allowed to access app ports and SSH (use your IP/32)" type = string default = "0.0.0.0/0" }
variable "project_name" { type = string default = "terraform-danish-single" }
