output "security_group_id" {
  description = "ID of the EC2 security group"
  value       = aws_security_group.ec2_security_group.id
}

output "master_ips" {
  value = data.aws_instances.master.public_ips
}

output "worker_ips" {
  value = data.aws_instances.worker.public_ips
}