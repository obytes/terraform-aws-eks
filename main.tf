####################
# VPC
####################
module "vpc" {
  source                  = "github.com/obytes/terraform-aws-vpc.git?ref=v1.0.5"
  environment             = var.environment
  region                  = var.region
  project_name            = var.project_name
  cidr_block              = var.cidr_block
  enable_dns_hostnames    = var.enable_dns_hostnames
  enable_nat_gateway      = var.enable_nat_gateway
  enable_internet_gateway = var.enable_internet_gateway
  create_public_subnets   = var.create_public_subnets
  single_nat_gateway      = var.single_nat_gateway
  map_public_ip_on_lunch  = true
  additional_public_subnet_tags = {
    "kubernetes.io/cluster/${join("-", [local.prefix, "backend"])}" = "shared"
    "kubernetes.io/role/elb"                                        = 1
  }
  additional_private_subnet_tags = {
  }
}


####################
# ECR
####################
resource "aws_ecr_repository" "this" {
  count = var.create_ecr_repository ? 1 : 0
  name  = local.prefix

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  count      = var.create_ecr_repository ? 1 : 0
  repository = aws_ecr_repository.this[count.index].name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep images tagged as prod for 1 year",
            "selection": {
                "tagStatus": "tagged",
                "tagPrefixList": ["prod"],
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 365
            },
            "action": {
                "type": "expire"
            }
        },
        {
            "rulePriority": 2,
            "description": "Keep images tagged as qa for 1 year",
            "selection": {
                "tagStatus": "tagged",
                "tagPrefixList": ["qa"],
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 365
            },
            "action": {
                "type": "expire"
            }
        },
        {
            "rulePriority": 3,
            "description": "Keep images tagged as stg for 1 year",
            "selection": {
                "tagStatus": "tagged",
                "tagPrefixList": ["stg"],
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 365
            },
            "action": {
                "type": "expire"
            }
        },
        {
            "rulePriority": 4,
            "description": "Keep images tagged as adm for 1 year",
            "selection": {
                "tagStatus": "tagged",
                "tagPrefixList": ["adm"],
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 365
            },
            "action": {
                "type": "expire"
            }
        },
        {
            "rulePriority": 5,
            "description": "Expire images older than 30 days",
            "selection": {
                "tagStatus": "any",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 30
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

####################
# KMS
####################

resource "aws_kms_key" "_" {
  count                   = var.create_kms_key ? 1 : 0
  description             = "AWS KMS for ${local.prefix}"
  is_enabled              = true
  deletion_window_in_days = 7
  tags                    = local.common_tags
  policy                  = data.aws_iam_policy_document.kms_policy[count.index].json
}

resource "aws_kms_alias" "_" {
  count         = var.create_kms_key ? 1 : 0
  target_key_id = aws_kms_key._[count.index].id
  name          = "alias/${local.prefix}"
}

data "aws_iam_policy_document" "kms_policy" {
  count = var.create_kms_key ? 1 : 0
  statement {
    sid    = "KeyOwnerPolicy"
    effect = "Allow"
    actions = ["kms:*"
    ]
    resources = ["*"]
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
      type        = "AWS"
    }
  }

  statement {
    sid    = "AllowCloudTrailAccessKMSKey"
    effect = "Allow"
    actions = [
      "kms:DescribeKey",
      "kms:GenerateDataKey*",
      "kms:Decrypt",
    ]
    principals {
      identifiers = ["cloudtrail.amazonaws.com"]
      type        = "Service"
    }
    resources = ["*"]
  }

  statement {
    sid    = "EnableCloudWatchAccessKMSKey"
    effect = "Allow"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    principals {
      identifiers = ["logs.${var.region}.amazonaws.com"]
      type        = "Service"
    }
    resources = [
      "*"
    ]
  }

  statement {
    sid    = "AllowAccessForSecretsManager"
    effect = "Allow"
    principals {
      identifiers = ["*"]
      type        = "AWS"
    }
    actions   = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:CreateGrant", "kms:DescribeKey"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      values   = ["secretsmanager.${var.region}.amazonaws.com"]
      variable = "kms:ViaService"
    }
  }

  statement {
    sid    = "AllowCodeStartNotificationsToUseKMSKey"
    effect = "Allow"
    principals {
      identifiers = ["codestar-notifications.amazonaws.com"]
      type        = "Service"
    }
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]
    resources = [
      "*"
    ]
    condition {
      test     = "StringEquals"
      values   = ["sns.${local.common_tags["region"]}.amazonaws.com"]
      variable = "kms:ViaService"
    }
  }

}


####################
# ACM
####################

resource "aws_acm_certificate" "_" {
  count                     = var.create_acm_certificate ? 1 : 0
  domain_name               = var.domain
  subject_alternative_names = [join(".", ["*", var.domain])]
  tags                      = merge(local.common_tags, tomap({ DomainName = var.domain, Name = local.prefix }))
  validation_method         = "DNS"
}

####################
# EKS
####################

resource "aws_eks_cluster" "_" {
  name     = join("-", [local.prefix, "backend"])
  role_arn = aws_iam_role._.arn
  vpc_config {
    subnet_ids              = module.vpc.prv_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.cluster.id]
  }
  kubernetes_network_config {
    service_ipv4_cidr = var.kubernetes_cidr
  }
  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = aws_kms_key._[0].arn
    }
  }
  enabled_cluster_log_types = ["api", "audit"]

  depends_on = [
    aws_iam_role_policy_attachment._["eks_cluster"],
    aws_iam_role_policy_attachment._["vpc_resource_controller"],
    aws_iam_role_policy_attachment.eks_fargate["fargate_execution"],
    aws_cloudwatch_log_group._,
    aws_iam_role._,
    aws_iam_role.eks_fargate_role
  ]
  timeouts {
    create = lookup(var.cluster_timeouts, "create", null)
    delete = lookup(var.cluster_timeouts, "update", null)
    update = lookup(var.cluster_timeouts, "delete", null)
  }
  version = "1.21"
}

resource "aws_iam_openid_connect_provider" "oidc_provider" {

  client_id_list  = ["sts.${data.aws_partition.current.dns_suffix}"]
  thumbprint_list = [data.tls_certificate.this.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster._.identity[0].oidc[0].issuer

  tags = merge(
    {
    Name = "${aws_eks_cluster._.name}-irsa" },
    local.common_tags
  )
}

resource "aws_eks_addon" "this" {
  for_each = { for k, v in local.cluster_addons : k => v }

  cluster_name = aws_eks_cluster._.name
  addon_name   = try(each.value.name, each.key)

  addon_version            = lookup(each.value, "addon_version", null)
  resolve_conflicts        = lookup(each.value, "resolve_conflicts", null)
  service_account_role_arn = lookup(each.value, "service_account_role_arn", null)

  lifecycle {
    ignore_changes = [
      modified_at
    ]
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "_" {
  name              = join("/", ["/aws/eks", local.prefix])
  retention_in_days = 30

  tags = local.common_tags
}

resource "aws_eks_fargate_profile" "_" {
  for_each               = { for k, v in local.fargate_profiles : k => v }
  cluster_name           = aws_eks_cluster._.name
  fargate_profile_name   = each.value.name
  pod_execution_role_arn = aws_iam_role.eks_fargate_role.arn
  subnet_ids             = module.vpc.prv_subnet_ids
  dynamic "selector" {
    for_each = each.value.selectors
    content {
      namespace = selector.value.namespace
      labels    = lookup(selector.value, "labels", {})
    }
  }
}

#https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html#cluster-sg
resource "aws_security_group" "cluster" {
  name        = join("-", [local.prefix, "sg"])
  description = join(" ", [local.prefix, "node ECS service"])
  vpc_id      = element(module.vpc.vpc_id, 0)


  tags = merge(local.common_tags, tomap({ "Name" = join("-", [local.prefix, "sg"]) }))
}

resource "aws_security_group_rule" "cluster" {
  for_each = local.cluster_security_group_rules

  security_group_id        = aws_security_group.cluster.id
  protocol                 = each.value.protocol
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  type                     = each.value.type
  self                     = try(each.value.self, null)
  ipv6_cidr_blocks         = try(each.value.ipv6_cidr_blocks, null)
  source_security_group_id = try(each.value.source_node_security_group, null)
  cidr_blocks              = try(each.value.cidr_blocks, null)
}
