variable "aws_region" { type = string default = "ap-south-1" }
variable "project_name" { type = string default = "terraform-danish" }
variable "vpc_cidr" { type = string default = "10.30.0.0/16" }
variable "flask_image_tag" { type = string default = "latest" }
variable "express_image_tag" { type = string default = "latest" }
variable "container_cpu" { type = number default = 256 }
variable "container_memory" { type = number default = 512 }
