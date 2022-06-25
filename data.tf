data "aws_caller_identity" "current" {

}

data "aws_partition" "current" {

}

data "aws_eks_cluster_auth" "_" {
  name = aws_eks_cluster._.name
}


data "tls_certificate" "this" {
  url = aws_eks_cluster._.identity[0].oidc[0].issuer
}