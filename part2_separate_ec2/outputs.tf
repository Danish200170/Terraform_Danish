output "vpc_id" { value = aws_vpc.main.id }
output "flask_instance_id" { value = aws_instance.flask.id }
output "express_instance_id" { value = aws_instance.express.id }
output "flask_private_ip" { value = aws_instance.flask.private_ip }
output "backend_url" { value = "http://${aws_instance.flask.public_ip}:5000" }
output "frontend_url" { value = "http://${aws_instance.express.public_ip}:3000" }
output "backend_api_url" { value = "http://${aws_instance.flask.public_ip}:5000/api/hello" }
