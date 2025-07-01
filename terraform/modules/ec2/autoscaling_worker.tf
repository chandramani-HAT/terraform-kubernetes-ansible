resource "aws_launch_template" "k8s_worker" {
  name_prefix   = "k8s-worker-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
#   user_data              = base64encode(file("${path.module}/user-data/worker.sh"))

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_type           = "gp3"
      delete_on_termination = false
      volume_size           = 30
      encrypted             = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name           = "${var.environment}-k8s-worker"
      Environment    = var.environment
      Owner          = var.owner
      Project        = var.project
      Classification = var.classification
      Role           = "worker"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.tags, {
      Name           = "${var.environment}-k8s-worker-root"
      Environment    = var.environment
      Owner          = var.owner
      Project        = var.project
      Classification = var.classification
    })
  }
  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.environment}-k8s-worker"
      Role = "worker"
    })
  }
}

resource "aws_autoscaling_group" "worker" {
  name                = "k8s-worker-asg"
  min_size            = 3
  max_size            = 3
  desired_capacity    = 3
  vpc_zone_identifier = var.subnet_ids
  
  launch_template {
    id      = aws_launch_template.k8s_worker.id
    version = "$Latest"
  }

  tag {
    key                 = "Role"
    value               = "worker"
    propagate_at_launch = true
  }
}

data "aws_instances" "worker" {
  instance_tags = {
    Role = "worker"
  }
  depends_on = [aws_autoscaling_group.worker]
}