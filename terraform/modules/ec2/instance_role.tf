resource "aws_iam_role" "k8s_master_role" {
  name = "${var.environment}-k8s-master-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.tags, {
    Name           = "${var.environment}-k8s-master-role",
    Environment    = var.environment,
    Owner          = var.owner,
    Project        = var.project,
    Classification = var.classification
  })
}

resource "aws_iam_role_policy_attachment" "k8s_master_ec2_full" {
  role       = aws_iam_role.k8s_master_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "k8s_master_eks_cluster" {
  role       = aws_iam_role.k8s_master_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "k8s_master_ecr_readonly" {
  role       = aws_iam_role.k8s_master_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECRReadOnly"
}

resource "aws_iam_role_policy_attachment" "k8s_master_route53_full" {
  role       = aws_iam_role.k8s_master_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
}

resource "aws_iam_role_policy_attachment" "k8s_master_eks_service" {
  role       = aws_iam_role.k8s_master_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

resource "aws_iam_role_policy_attachment" "k8s_master_eks_cni" {
  role       = aws_iam_role.k8s_master_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_instance_profile" "k8s_master_profile" {
  name = "${var.environment}-k8s-master-profile"
  role = aws_iam_role.k8s_master_role.name
}
# ===========================================================================
# Kubernetes Worker Node IAM Role and Policies


resource "aws_iam_role" "k8s_worker_role" {
  name = "${var.environment}-k8s-worker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.tags, {
    Name           = "${var.environment}-k8s-worker-role",
    Environment    = var.environment,
    Owner          = var.owner,
    Project        = var.project,
    Classification = var.classification
  })
}

resource "aws_iam_role_policy_attachment" "k8s_worker_ec2_full" {
  role       = aws_iam_role.k8s_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "k8s_worker_eks_worker" {
  role       = aws_iam_role.k8s_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "k8s_worker_eks_cni" {
  role       = aws_iam_role.k8s_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "k8s_worker_ecr_readonly" {
  role       = aws_iam_role.k8s_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECRReadOnly"
}

resource "aws_iam_role_policy_attachment" "k8s_worker_ebs_csi" {
  role       = aws_iam_role.k8s_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_iam_instance_profile" "k8s_worker_profile" {
  name = "${var.environment}-k8s-worker-profile"
  role = aws_iam_role.k8s_worker_role.name
}
