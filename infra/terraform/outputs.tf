output "public_url" {
  value = "http://${aws_instance.app.public_ip}:8000"
}
output "expires_at" {
  value = var.expires_at
}
