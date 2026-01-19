
# Production: EFS File System for Persistent Storage
resource "aws_efs_file_system" "eks_efs" {
  creation_token = "eks-efs"
  encrypted      = true
  tags = {
    Name = "eks-efs"
  }
}

# EFS Security Group
resource "aws_security_group" "efs" {
  name        = "efs-sg"
  description = "Allow NFS traffic from VPC"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "NFS from VPC"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    cidr_blocks     = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EFS Mount Targets (One per Private Subnet)
resource "aws_efs_mount_target" "this" {
  count           = length(module.vpc.private_subnets)
  file_system_id  = aws_efs_file_system.eks_efs.id
  subnet_id       = module.vpc.private_subnets[count.index]
  security_groups = [aws_security_group.efs.id]
}

# Output EFS ID
output "efs_id" {
  value = aws_efs_file_system.eks_efs.id
}

# Output EFS DNS Name
output "efs_dns_name" {
  value = aws_efs_file_system.eks_efs.dns_name
}
