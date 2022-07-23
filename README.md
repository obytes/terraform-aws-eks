### Overview 

We are going to explore how to provision an EKS Fargate cluster with Terraform, and how to setup an AWS ALB Ingress controller serving K8S pods hosted in private subnets
[Article](https://www.obytes.com/blog/provisioning-a-production-ready-amazon-eks-fargate-cluster-using-terraform)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~>3.71 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | 3.7.0 |
| <a name="requirement_github"></a> [github](#requirement\_github) | 4.19.1 |
| <a name="requirement_random"></a> [random](#requirement\_random) | 3.1.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | 3.4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 3.75.2 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 3.4.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vpc"></a> [vpc](#module\_vpc) | github.com/obytes/terraform-aws-vpc.git | v1.0.5 |

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate._](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_cloudwatch_log_group._](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_codestarconnections_connection._](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codestarconnections_connection) | resource |
| [aws_eks_addon.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_cluster._](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster) | resource |
| [aws_eks_fargate_profile._](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_fargate_profile) | resource |
| [aws_iam_openid_connect_provider.oidc_provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_policy.alb_v1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.eks_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role._](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.alb_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.eks_fargate_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.eks_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment._](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.alb_v1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.eks_fargate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kms_alias._](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key._](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_security_group.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster_auth._](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_iam_policy_document._](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.alb_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.alb_eks_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.eks_assume_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.eks_fargate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.eks_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.kms_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [tls_certificate.this](https://registry.terraform.io/providers/hashicorp/tls/3.4.0/docs/data-sources/certificate) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cidr_block"></a> [cidr\_block](#input\_cidr\_block) | The main CIDR block of the VPC | `string` | `"172.19.0.0/18"` | no |
| <a name="input_cluster_ip_family"></a> [cluster\_ip\_family](#input\_cluster\_ip\_family) | The IP type of EKS Cluster | `string` | `"ipv4"` | no |
| <a name="input_cluster_timeouts"></a> [cluster\_timeouts](#input\_cluster\_timeouts) | Create, update, and delete timeout configurations for the cluster | `map(string)` | `{}` | no |
| <a name="input_create_acm_certificate"></a> [create\_acm\_certificate](#input\_create\_acm\_certificate) | Boolean, either to create a new ACM certificate or use existing one | `bool` | `true` | no |
| <a name="input_create_ecr_repository"></a> [create\_ecr\_repository](#input\_create\_ecr\_repository) | Boolean, either to create a new ECR repository or use existing one | `bool` | `true` | no |
| <a name="input_create_kms_key"></a> [create\_kms\_key](#input\_create\_kms\_key) | Boolean, either to create a new KMS key or use existing one | `bool` | `true` | no |
| <a name="input_create_public_subnets"></a> [create\_public\_subnets](#input\_create\_public\_subnets) | A Boolean, for creating public subnets | `bool` | `true` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | Domain Name to issue ACM Certificate | `string` | `"obytes.com"` | no |
| <a name="input_enable_dns_hostnames"></a> [enable\_dns\_hostnames](#input\_enable\_dns\_hostnames) | A Boolean to enable the dns hostname resolving | `bool` | `true` | no |
| <a name="input_enable_internet_gateway"></a> [enable\_internet\_gateway](#input\_enable\_internet\_gateway) | A Boolean either to create an internet GW for the public reachability | `string` | `true` | no |
| <a name="input_enable_nat_gateway"></a> [enable\_nat\_gateway](#input\_enable\_nat\_gateway) | A Boolean either to create a NAT GW in the VPC, used by the private subnets | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment id where those resources will be created such as stag, production, qa | `string` | `"stg"` | no |
| <a name="input_gh_branch"></a> [gh\_branch](#input\_gh\_branch) | GH Branch that will mapped to QA EKS Deployments | `string` | `"main"` | no |
| <a name="input_kubernetes_cidr"></a> [kubernetes\_cidr](#input\_kubernetes\_cidr) | Configuration block with kubernetes network configuration for the cluster | `string` | `"172.16.64.0/24"` | no |
| <a name="input_profile_name"></a> [profile\_name](#input\_profile\_name) | AWS Credentials profile name | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | The Project name | `string` | `"eks"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Region name | `string` | `"eu-west-1"` | no |
| <a name="input_single_nat_gateway"></a> [single\_nat\_gateway](#input\_single\_nat\_gateway) | A Boolean, either to create a single NAT GW for the VPC or to create a separate  NAT GW for each AZ | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_acm_details"></a> [acm\_details](#output\_acm\_details) | Details about the ACM certificate for generaltask.com |
| <a name="output_availability_zones"></a> [availability\_zones](#output\_availability\_zones) | List of Availability Zones where subnets were created |
| <a name="output_cluster_sg_id"></a> [cluster\_sg\_id](#output\_cluster\_sg\_id) | EKS Cluster security group |
| <a name="output_eks_cluster"></a> [eks\_cluster](#output\_eks\_cluster) | EKS Cluster information |
| <a name="output_elastc_ips"></a> [elastc\_ips](#output\_elastc\_ips) | AWS eip public ips |
| <a name="output_kms_alias_name"></a> [kms\_alias\_name](#output\_kms\_alias\_name) | KMS key alias |
| <a name="output_kms_arn"></a> [kms\_arn](#output\_kms\_arn) | KMS Key ARN |
| <a name="output_kms_id"></a> [kms\_id](#output\_kms\_id) | KMS Key ID |
| <a name="output_nat_gw_ids"></a> [nat\_gw\_ids](#output\_nat\_gw\_ids) | aws nat gateway id(s) |
| <a name="output_nat_ips"></a> [nat\_ips](#output\_nat\_ips) | IP Addresses in use for NAT |
| <a name="output_prv_route_table_ids"></a> [prv\_route\_table\_ids](#output\_prv\_route\_table\_ids) | private route table ids |
| <a name="output_prv_subnet_cidrs"></a> [prv\_subnet\_cidrs](#output\_prv\_subnet\_cidrs) | Private Subnet cidr\_blocks |
| <a name="output_prv_subnet_ids"></a> [prv\_subnet\_ids](#output\_prv\_subnet\_ids) | Private Subnet IDs |
| <a name="output_pub_route_table_ids"></a> [pub\_route\_table\_ids](#output\_pub\_route\_table\_ids) | Public route table ids |
| <a name="output_pub_subnet_cidrs"></a> [pub\_subnet\_cidrs](#output\_pub\_subnet\_cidrs) | Public Subnet cidr\_blocks |
| <a name="output_pub_subnet_ids"></a> [pub\_subnet\_ids](#output\_pub\_subnet\_ids) | Public Subnet IDs |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | CIDR Block of the VPC |
| <a name="output_vpc_dhcp_dns_list"></a> [vpc\_dhcp\_dns\_list](#output\_vpc\_dhcp\_dns\_list) | VPC DHCP DNS linst |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | VPC ID |
| <a name="output_vpc_sg_id"></a> [vpc\_sg\_id](#output\_vpc\_sg\_id) | Security Group ID of the VPC |
<!-- END_TF_DOCS -->
