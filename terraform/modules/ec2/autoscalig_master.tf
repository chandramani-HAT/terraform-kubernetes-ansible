resource "aws_launch_template" "k8s_master" {
  name_prefix   = "k8s-master"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  iam_instance_profile {
    name = aws_iam_instance_profile.k8s_master_profile.name
  }
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
#   user_data              = base64encode(file("${path.module}/user-data/master.sh"))

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
      Name           = "${var.environment}-k8s-master"
      Environment    = var.environment
      Owner          = var.owner
      Project        = var.project
      Classification = var.classification
      Role           = "master"
    })
  }
  tag_specifications {
    resource_type = "volume"
    tags = merge(var.tags, {
      Name           = "${var.environment}-k8s-master-root"
      Environment    = var.environment
      Owner          = var.owner
      Project        = var.project
      Classification = var.classification
    })
  }
}

resource "aws_autoscaling_group" "master" {
  name                = "k8s-master-asg"
  min_size            = 1
  max_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = var.subnet_ids
  
  launch_template {
    id      = aws_launch_template.k8s_master.id
    version = "$Latest"
  }

  tag {
    key                 = "Role"
    value               = "master"
    propagate_at_launch = true
  }
}

data "aws_instances" "master" {
  instance_tags = {
    Role = "master"
  }
  depends_on = [aws_autoscaling_group.master]
}