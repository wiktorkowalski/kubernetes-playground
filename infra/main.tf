provider "aws" {
  region = "eu-central-1"
}

data "aws_eks_cluster_auth" "auth" {
  name = aws_eks_cluster.playground.name
}

resource "aws_ecr_repository" "playground" {
  name = "playground"
}

resource "aws_eks_cluster" "playground" {
  name     = "playground"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = flatten([aws_subnet.playground.*.id])
    endpoint_private_access = true
    endpoint_public_access = false
    security_group_ids = [aws_security_group.playground.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.playground_eks_cluster_policy,
    aws_iam_role_policy_attachment.playground_eks_service_policy,
  ]
}

resource "aws_iam_role" "eks_cluster" {
  name = "playground_eks_cluster_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "playground_eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "playground_eks_service_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_vpc" "playground" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "playground" {
  count                   = 2
  vpc_id                  = aws_vpc.playground.id
  cidr_block              = "10.0.${count.index}.0/24"
  availability_zone       = element(split(",", var.availability_zones), count.index)
  map_public_ip_on_launch = true
}

resource "aws_security_group" "playground" {
  vpc_id = aws_vpc.playground.id
}

# resource "aws_instance" "playground" {
#   count = 2

#   instance_type = "t2.micro"
#   ami           = "ami-040236e9010f11804" # Change this to the latest EKS-optimized AMI ID
#   key_name      = "WiktorPC"

#   vpc_security_group_ids = [aws_security_group.playground.id]
#   subnet_id              = element(aws_subnet.playground.*.id, count.index)

#   tags = {
#     Name = "PlaygroundInstance${count.index}"
#   }

#   instance_market_options {
#     market_type = "spot"
#   }
# }

// node group

resource "aws_eks_node_group" "playground" {
  cluster_name    = aws_eks_cluster.playground.name
  node_group_name = "playground-node-group"
  node_role_arn   = aws_iam_role.eks_worker.arn
  subnet_ids      = flatten([aws_subnet.playground.*.id])

  scaling_config {
    desired_size = 2
    max_size     = 5
    min_size     = 1
  }

  instance_types = ["t3a.micro"]

  depends_on = [
    aws_eks_cluster.playground,
  ]

  capacity_type = "SPOT"
}

resource "aws_iam_role" "eks_worker" {
  name = "eks-worker-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "eks_worker_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_worker.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_worker.name
}

resource "aws_iam_role_policy_attachment" "eks_ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_worker.name
}

resource "aws_iam_instance_profile" "eks_worker" {
  name = "eks-worker-instance-profile"
  role = aws_iam_role.eks_worker.name
}

//

// addons

# resource "aws_eks_addon" "opentelemetry" {
#   cluster_name = aws_eks_cluster.playground.name
#   addon_name   = "adot"
#   addon_version = "v0.78.0-eksbuild.1"

# #   configuration_values = <<EOF
# #   {
# #     "apiServer": {
# #       "extraArgs": {
# #         "feature-gates": "EKS-AWS-ADDONS=true"
# #       }
# #     }
# #   }
# # EOF
# }

//

// fargate profile

resource "aws_eks_fargate_profile" "playground" {
  cluster_name          = aws_eks_cluster.playground.name
  fargate_profile_name  = "playground-fargate-profile"
  pod_execution_role_arn = aws_iam_role.playground_fargate_role.arn
  subnet_ids = flatten([aws_subnet.playground.*.id])

  selector {
    namespace = "default"
  }

  depends_on = [aws_eks_cluster.playground]
}

resource "aws_iam_role" "playground_fargate_role" {
  name = "playground-fargate-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks-fargate-pods.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "playground_fargate_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.playground_fargate_role.name
}


//

output "cluster_endpoint" {
  value = aws_eks_cluster.playground.endpoint
}

output "cluster_security_group_id" {
  value = aws_eks_cluster.playground.vpc_config[0].cluster_security_group_id
}

variable "availability_zones" {
  default = "eu-central-1a,eu-central-1b"
}
