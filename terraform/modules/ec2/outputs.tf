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

output "master_private_ip" {
  description = "Private IP of the master node"
  value       = data.aws_instances.master.private_ips[0]  # For ASG
  # value     = aws_instance.master.private_ip            # For single instance
}
