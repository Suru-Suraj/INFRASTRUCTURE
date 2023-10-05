# Output values
output "private_ip" {
  value = aws_instance.CAPSTONE.private_ip
}

output "public_ip" {
  value = aws_instance.CAPSTONE.public_ip
}

output "instance_id" {
  description = "Instance ID of the EC2 instance"
  value       = aws_instance.CAPSTONE.id
}
