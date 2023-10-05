# Output the DNS name of the load balancer
output "lb_dns" {
  value = aws_lb.CAPSTONE.dns_name
}