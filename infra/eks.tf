
# EKS Cluster
resource "aws_eks_cluster" "fastfood-cluster" {
  name     = var.cluster_config.name
  role_arn = var.networking.fiap_role
  version  = var.cluster_config.version

  vpc_config {
    subnet_ids         = flatten([aws_subnet.public-subnet[*].id, aws_subnet.private-subnet[*].id])
    security_group_ids = flatten([for sec in var.security_groups : aws_security_group.fiap-sec-groups[sec.name].id])
    
    endpoint_private_access = true
    endpoint_public_access = true
  }
}

# NODE GROUP
resource "aws_eks_node_group" "node-ec2" {
  for_each        = { for node_group in var.node_groups : node_group.name => node_group }
  cluster_name    = aws_eks_cluster.fastfood-cluster.name
  node_group_name = each.value.name
  node_role_arn   = var.networking.fiap_role
  subnet_ids      = flatten(aws_subnet.private-subnet[*].id)

  scaling_config {
    desired_size = try(each.value.scaling_config.desired_size, 1)
    max_size     = try(each.value.scaling_config.max_size, 2)
    min_size     = try(each.value.scaling_config.min_size, 1)
  }

  update_config {
    max_unavailable = try(each.value.update_config.max_unavailable, 1)
  }

  ami_type       = each.value.ami_type
  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type
  disk_size      = each.value.disk_size
}

resource "aws_eks_addon" "addons" {
  for_each          = { for addon in var.addons : addon.name => addon }
  cluster_name      = aws_eks_cluster.fastfood-cluster.id
  addon_name        = each.value.name
  addon_version     = each.value.version
  resolve_conflicts = "OVERWRITE"
}

# # resource "aws_vpc" "eks_vpc" {
# #   cidr_block = "10.0.0.0/16"

# #   tags = {
# #     Name = "eks_vpc"
# #   }
# # }

# # resource "aws_subnet" "eks_subnet_a" {
# #   vpc_id            = aws_vpc.eks_vpc.id
# #   cidr_block        = "10.0.1.0/24"
# #   availability_zone = "us-east-1a"  # Change according to your region

# #   tags = {
# #     Name = "eks_subnet_a"
# #   }
# # }

# # resource "aws_subnet" "eks_subnet_b" {
# #   vpc_id            = aws_vpc.eks_vpc.id
# #   cidr_block        = "10.0.2.0/24"
# #   availability_zone = "us-east-1b"  # Change according to your region

# #   tags = {
# #     Name = "eks_subnet_b"
# #   }
# # }

# resource "aws_eks_cluster" "fastfood-cluster" {
#   name     = "fastfood-cluster"
#   role_arn = "arn:aws:iam::714167738697:role/LabRole"
#   vpc_config {
#     subnet_ids = [
#       aws_subnet.private-subnet-a.id,
#       aws_subnet.private-subnet-b.id,
#       aws_subnet.public-subnet-a.id,
#       aws_subnet.public-subnet-b.id
#     ]
#   }

#   bootstrap_self_managed_addons = true
# }

# resource "aws_eks_node_group" "fastood_node_group" {
#   cluster_name    = aws_eks_cluster.fastfood-cluster.name
#   node_group_name = "fastood_node_group"
#   node_role_arn   = "arn:aws:iam::714167738697:role/LabRole"
#   subnet_ids      = [
#     aws_subnet.private-subnet-a.id,
#     aws_subnet.private-subnet-b.id
#   ]

#   scaling_config {
#     desired_size = 1
#     max_size     = 2
#     min_size     = 1
#   }
# }

# output "cluster_name" {
#   value = aws_eks_cluster.fastfood-cluster.name
# }

# # output "cluster_endpoint" {
# #   value = aws_eks_cluster.fastfood-cluster.endpoint
# # }

# # module "eks" {
# #   source  = "terraform-aws-modules/eks/aws"
# #   version = "20.23.0"

# #   cluster_name                   = local.name
# #   cluster_endpoint_public_access = true
# #   cluster_endpoint_private_access = false

# #   cluster_addons = {
# #     coredns = {
# #       most_recent = true
# #     }
# #     kube-proxy = {
# #       most_recent = true
# #     }
# #     vpc-cni = {
# #       most_recent = true
# #     }
# #   }

# #   vpc_id                   = module.vpc.vpc_id
# #   subnet_ids               = module.vpc.private_subnets
# #   control_plane_subnet_ids = module.vpc.intra_subnets

# #   # EKS Managed Node Group(s)
# #   eks_managed_node_group_defaults = {
# #     ami_type       = "ami-0ae8f15ae66fe8cda"
# #     instance_types = ["t3.medium"]

# #     attach_cluster_primary_security_group = true
# #   }

# #   eks_managed_node_groups = {
# #     fastfood-node-group = {
# #       min_size     = 1
# #       max_size     = 2
# #       desired_size = 1

# #       instance_types = ["t3.medium"]
# #       capacity_type  = "ON_DEMAND"

# #       tags = {
# #         ExtraTag = "fastfood-instance"
# #       }
# #     }
# #   }

# #   tags = local.tags
# # }

# # module "aws_auth" {
# #   source = "terraform-aws-modules/eks/aws//modules/aws-auth"
# #   manage_aws_auth_configmap = true
# #   aws_auth_roles = [
# #     {
# #       rolearn  = data.aws_iam_role.karpenter_instance.arn
# #       username = "system:node:{{EC2PrivateDNSName}}"
# #       groups   = ["system:bootstrappers", "system:nodes"]
# #     },
# #   ]
# #   aws_auth_users = var.eks_additional_users
# # }