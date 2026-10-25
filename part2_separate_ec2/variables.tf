variable "aws_region" { type = string default = "ap-south-1" }
variable "instance_type" { type = string default = "t3.micro" }
variable "key_name" { type = string default = "" description = "Existing EC2 key pair; blank disables SSH ingress" }
variable "allowed_cidr" { type = string default = "0.0.0.0/0" description = "Use your public IP/32 for safer testing" }
variable "project_name" { type = string default = "terraform-danish-separate" }
