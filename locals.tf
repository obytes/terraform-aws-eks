locals {
  prefix = join("-", [var.environment, var.project_name, replace(var.region, "-", "")])
  common_tags = {
    env     = var.environment
    project = var.project_name
    region  = var.region
  }
  eks_iam_polices = {
    eks_cluster             = join("/", ["arn:${data.aws_partition.current.partition}:iam::aws:policy", "AmazonEKSClusterPolicy"])
    vpc_resource_controller = join("/", ["arn:${data.aws_partition.current.partition}:iam::aws:policy", "AmazonEKSVPCResourceController"])
  }
  eks_fargate_iam_policies = {
    fargate_execution = join("/", ["arn:${data.aws_partition.current.partition}:iam::aws:policy", "AmazonEKSFargatePodExecutionRolePolicy"])
  }
  cluster_addons = {
    # Note: https://docs.aws.amazon.com/eks/latest/userguide/fargate-getting-started.html#fargate-gs-coredns
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {

    }
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }
  # README
  # https://docs.aws.amazon.com/eks/latest/userguide/fargate-getting-started.html#fargate-gs-coredns
  fargate_profiles = {
    default = {
      name = local.prefix
      selectors = [
        {
          namespace = "default"
          labels = {
            Application = join("-", [local.prefix, "core"])
          }
        }
      ]
      tags = merge(local.common_tags, tomap({ Namespace = "Default" }))
      timeouts = {
        create = "20m"
        delete = "20m"
      }
    },
    backend = {
      name = join("-", [local.prefix, "core"])
      selectors = [
        {
          namespace = local.prefix
          labels = {
            "app.kubernetes.io/name" = "core"
          }
        }
      ]
      tags = merge(local.common_tags, tomap({ Namespace = "Default" }))
      timeouts = {
        create = "20m"
        delete = "20m"
      }
    },
    coredns = {
      name = "CoreDNS"
      selectors = [
        {
          namespace = "kube-system"
          labels = {
            k8s-app = "kube-dns"
          }
        }
      ]
      tags     = merge(local.common_tags, tomap({ Namespace = "CoreDNS" }))
      timeouts = {}
    },
    kube-system = {
      name = join("-", [local.prefix, "kube"])
      selectors = [
        {
          namespace = "kube-system"
        }
      ]
      tags     = merge(local.common_tags, tomap({ Namespace = "kube-system" }))
      timeouts = {}
    },
    backend-kube-system = {
      name = join("-", [local.prefix, "kube-system"])
      selectors = [
        {
          namespace = "kube-system"
          labels = {
            "app.kubernetes.io/instance" = "aws-load-balancer-controller"
            "app.kubernetes.io/name"     = "aws-load-balancer-controller"
          }
        }
      ]
      tags     = merge(local.common_tags, tomap({ Namespace = "CoreDNS" }))
      timeouts = {}
    }
  }
  kube_config_folder    = "kubernetes/manifests/prod/"
  cluster_security_group_rules = {
    ingress_nodes_443 = {
      description = "Node groups to cluster API"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      self        = true
    }
    #FIXME: Add CodeBuild and CodePipeline for CI/CD process
#    ingress_codebuild_deploy = {
#      description                = "CodeBuild Deploy Security Group"
#      protocol                   = "tcp"
#      from_port                  = 0
#      to_port                    = 65535
#      type                       = "ingress"
#      source_node_security_group = module.codebuild_cd.codebuild_sg_id
#    }
    egress_nodes_443 = {
      description = "Cluster API to node groups"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "egress"
      self        = true
    }
    egress_nodes_kubelet = {
      description = "Cluster API to node kubelets"
      protocol    = "tcp"
      from_port   = 10250
      to_port     = 10250
      type        = "egress"
      self        = true
    }
    ingress_nodes_dns = {
      description = "Cluster API to node dns"
      protocol    = "tcp"
      from_port   = 53
      to_port     = 53
      type        = "ingress"
      self        = true
    }
    ingress_nodes_dns_udp = {
      description = "Cluster API to node dns"
      protocol    = "udp"
      from_port   = 53
      to_port     = 53
      type        = "ingress"
      self        = true
    }
    egress_nodes_dns = {
      description = "Cluster API to node dns"
      protocol    = "tcp"
      from_port   = 53
      to_port     = 53
      type        = "egress"
      self        = true
    }
    egress_nodes_dns_udp = {
      description = "Cluster API to node dns"
      protocol    = "udp"
      from_port   = 53
      to_port     = 53
      type        = "egress"
      self        = true
    }
    egress_ntp_tcp = {
      description      = "Egress NTP/TCP to internet"
      protocol         = "tcp"
      from_port        = 123
      to_port          = 123
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = var.cluster_ip_family == "ipv6" ? ["::/0"] : null
    }
    egress_ntp_udp = {
      description      = "Egress NTP/UDP to internet"
      protocol         = "udp"
      from_port        = 123
      to_port          = 123
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = var.cluster_ip_family == "ipv6" ? ["::/0"] : null
    }
  }
}