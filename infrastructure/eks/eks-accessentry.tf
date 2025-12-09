resource "aws_eks_access_entry" "admin" {
  cluster_name      = aws_eks_cluster.studysync_cluster.name
  principal_arn     = aws_iam_role.cluster.arn
  kubernetes_groups = ["group-1", "group-2"]
  type              = "STANDARD"
}