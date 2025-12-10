resource "aws_eks_access_entry" "admin" {
  cluster_name      = aws_eks_cluster.studysync_cluster.name
  principal_arn     = "arn:aws:iam::118162274891:user/tochi-admin"
  kubernetes_groups = []
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin" {
  cluster_name  = aws_eks_cluster.studysync_cluster.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = "arn:aws:iam::118162274891:user/tochi-admin"

  access_scope {
    type       = "cluster"
  }
    depends_on = [aws_eks_access_entry.admin]
}