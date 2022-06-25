## EKS Cluster IAM Role
## https://docs.aws.amazon.com/eks/latest/userguide/getting-started-console.html#eks-create-cluster
data "aws_iam_policy_document" "_" {
  statement {
    sid     = "EKSClusterAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "eks.amazonaws.com",
        "eks-fargate-pods.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "_" {
  name               = join("-", [local.prefix, "role"])
  assume_role_policy = data.aws_iam_policy_document._.json
  description        = "AWS IAM role for EKS Cluster"
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "_" {
  for_each   = local.eks_iam_polices
  policy_arn = each.value
  role       = aws_iam_role._.name
}


## EKS Fargate IAM Roles
## https://docs.aws.amazon.com/eks/latest/userguide/pod-execution-role.html#check-pod-execution-role

data "aws_iam_policy_document" "eks_fargate" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["eks-fargate-pods.amazonaws.com"]
      type        = "Service"
    }
    actions = [
      "sts:AssumeRole"
    ]
  }
}

resource "aws_iam_role" "eks_fargate_role" {
  assume_role_policy = data.aws_iam_policy_document.eks_fargate.json
  name               = join("-", [local.prefix, "fargate-role"])
  description        = "EKS Fargate pod execution role for ${local.prefix}"
  tags               = merge(local.common_tags, tomap({ Role = "EKS FargatePOD Execution Role" }))
}

resource "aws_iam_role_policy_attachment" "eks_fargate" {
  for_each   = local.eks_fargate_iam_policies
  policy_arn = each.value
  role       = aws_iam_role.eks_fargate_role.name
}


# AWS Application Load Balancer Controller IAM Policy and Roles
# curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.3.1/docs/install/iam_policy.json
# curl -o iam_policy_v1_to_v2_additional.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.3.1/docs/install/iam_policy_v1_to_v2_additional.json

data "aws_iam_policy_document" "alb_eks_ingress" {
  statement {
    effect = "Allow"
    actions = [
      "iam:CreateServiceLinkedRole"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      values   = ["elasticloadbalancing.amazonaws.com"]
      variable = "iam:AWSServiceName"
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeVpcs",
      "ec2:DescribeVpcPeeringConnections",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeInstances",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeTags",
      "ec2:GetCoipPoolUsage",
      "ec2:DescribeCoipPools",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeListenerCertificates",
      "elasticloadbalancing:DescribeSSLPolicies",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:DescribeTags",
      "ec2:DescribeAvailabilityZones"
    ]
    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "cognito-idp:DescribeUserPoolClient",
      "acm:ListCertificates",
      "acm:DescribeCertificate",
      "iam:ListServerCertificates",
      "iam:GetServerCertificate",
      "waf-regional:GetWebACL",
      "waf-regional:GetWebACLForResource",
      "waf-regional:AssociateWebACL",
      "waf-regional:DisassociateWebACL",
      "wafv2:GetWebACL",
      "wafv2:GetWebACLForResource",
      "wafv2:AssociateWebACL",
      "wafv2:DisassociateWebACL",
      "shield:GetSubscriptionState",
      "shield:DescribeProtection",
      "shield:CreateProtection",
      "shield:DeleteProtection"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress"
    ]
    resources = ["*"]
  }
  statement {
    actions = [
      "ec2:CreateSecurityGroup",
    ]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:security-group/*"]
    actions = [
      "ec2:CreateTags"
    ]
    condition {
      test     = "StringEquals"
      values   = ["CreateSecurityGroup"]
      variable = "ec2:CreateAction"
    }
    condition {
      test     = "Null"
      values   = ["false"]
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
    }
  }
  statement {
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:security-group/*"]
    actions = [
      "ec2:CreateTags",
      "ec2:DeleteTags"
    ]
    condition {
      test     = "Null"
      values   = ["true"]
      variable = "aws:RequestTag/elbv2.k8s.aws/cluste"
    }
    condition {
      test     = "Null"
      values   = ["false"]
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:DeleteSecurityGroup"
    ]
    resources = ["*"]
    condition {
      test     = "Null"
      values   = ["false"]
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateTargetGroup"
    ]
    resources = [
      "*"
    ]
    condition {
      test     = "Null"
      values   = ["false"]
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
    }
  }
  statement {
    actions = [
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:DeleteRule"
    ]
    resources = ["*"]
  }
  statement {
    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags"
    ]
    resources = [
      "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
      "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
      "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
    ]
    condition {
      test     = "Null"
      values   = ["true"]
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
    }
    condition {
      test     = "Null"
      values   = ["false"]
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
    }
  }
  statement {
    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags"
    ]
    resources = [
      "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
      "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
      "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
      "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
    ]
  }
  statement {
    actions = [
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:DeleteTargetGroup"
    ]
    resources = ["*"]
    condition {
      test     = "Null"
      values   = ["false"]
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
    }
  }
  statement {
    actions = [
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets"
    ]
    resources = [
      "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
    ]
  }
  statement {
    actions = [
      "elasticloadbalancing:SetWebAcl",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:AddListenerCertificates",
      "elasticloadbalancing:RemoveListenerCertificates",
      "elasticloadbalancing:ModifyRule"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "alb_v1" {
  policy = data.aws_iam_policy_document.alb_eks_ingress.json
  tags   = merge(local.common_tags, tomap({ "Type" = "EKS Cluster ALB Controller V1" }))
  name   = join("-", [local.prefix, "alb-cont"])
}

data "aws_iam_policy_document" "alb_assume_role" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(aws_eks_cluster._.identity[0].oidc[0].issuer, "https://", "")}"]
      type        = "Federated"
    }
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    condition {
      test     = "StringEquals"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
      variable = "${replace(aws_eks_cluster._.identity[0].oidc[0].issuer, "https://", "")}:sub"
    }
  }
}

resource "aws_iam_role" "alb_role" {
  assume_role_policy = data.aws_iam_policy_document.alb_assume_role.json
  name               = join("-", [local.prefix, "alb-role"])
  description        = "ALB controller role for ${local.prefix}"
  tags               = merge(local.common_tags, tomap({ Role = "EKS ALB controller role" }))
}

resource "aws_iam_role_policy_attachment" "alb_v1" {
  policy_arn = aws_iam_policy.alb_v1.arn
  role       = aws_iam_role.alb_role.name
}


## IAM STS ASSUME ROLE FOR CODEBUILD
data "aws_iam_policy_document" "eks_assume_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
      ]
    }
  }
}

data "aws_iam_policy_document" "eks_policy" {
  statement {
    effect = "Allow"
    actions = [
      "eks:Describe*",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "eks_policy" {
  policy = data.aws_iam_policy_document.eks_policy.json
  name   = join("-", [local.prefix, "eks-policy"])
}

resource "aws_iam_role" "eks_role" {
  assume_role_policy = data.aws_iam_policy_document.eks_assume_policy.json
  path               = "/"
  name               = join("-", [local.prefix, "eks-role"])
}

resource "aws_iam_role_policy_attachment" "eks" {
  policy_arn = aws_iam_policy.eks_policy.arn
  role       = aws_iam_role.eks_role.name
}