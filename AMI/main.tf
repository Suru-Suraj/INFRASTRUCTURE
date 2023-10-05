resource "aws_ami_from_instance" "CAPSTONE" {
  name               = "CAPSTONE"
  source_instance_id = var.source_instance_id
}