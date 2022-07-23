#=========#
#   VPC   #
#=========#


output "pub_subnet_ids" {
  description = "Public Subnet IDs"
  value       = module.vpc.pub_subnet_ids
}

output "prv_subnet_ids" {
  description = "Private Subnet IDs"
  value       = module.vpc.prv_subnet_ids
}

output "pub_subnet_cidrs" {
  description = "Public Subnet cidr_blocks"
  value       = module.vpc.pub_subnet_cidrs
}

output "prv_subnet_cidrs" {
  description = "Private Subnet cidr_blocks"
  value       = module.vpc.prv_subnet_cidrs
}

output "pub_route_table_ids" {
  description = "Public route table ids"
  value       = module.vpc.pub_route_table_ids
}

output "prv_route_table_ids" {
  description = "private route table ids"
  value       = module.vpc.prv_route_table_ids
}

output "nat_gw_ids" {
  description = "aws nat gateway id(s)"
  value       = module.vpc.nat_gw_ids
}

output "elastc_ips" {
  description = "AWS eip public ips"
  value       = module.vpc.elastc_ips
}

output "availability_zones" {
  description = "List of Availability Zones where subnets were created"
  value       = module.vpc.availability_zones
}

output "nat_ips" {
  description = "IP Addresses in use for NAT"
  value       = module.vpc.nat_ips
}

output "vpc_cidr_block" {
  value       = module.vpc.vpc_cidr_block
  description = "CIDR Block of the VPC"
}

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID"
}

output "vpc_sg_id" {
  value       = module.vpc.vpc_sg_id
  description = "Security Group ID of the VPC"
}

output "vpc_dhcp_dns_list" {
  value       = module.vpc.vpc_dhcp_dns_list
  description = "VPC DHCP DNS linst"
}

#=========#
#   KMS   #
#=========#

output "kms_arn" {
  value       = aws_kms_key._[0].arn
  description = "KMS Key ARN"
}
output "kms_alias_name" {
  value       = aws_kms_alias._[0].name
  description = "KMS key alias"
}
output "kms_id" {
  value       = aws_kms_key._[0].id
  description = "KMS Key ID"
}

#=========#
#   ACM   #
#=========#

output "acm_details" {
  value = {
    id                        = aws_acm_certificate._[0].id
    arn                       = aws_acm_certificate._[0].arn
    domain_validation_options = aws_acm_certificate._[0].domain_validation_options
    domain_name               = aws_acm_certificate._[0].domain_name
  }
  description = "Details about the ACM certificate for generaltask.com"
}

#=========#
#   EKS   #
#=========#

output "eks_cluster" {
  value = {
    name           = aws_eks_cluster._.name
    arn            = aws_eks_cluster._.arn
    endpoint       = aws_eks_cluster._.endpoint
    network_config = aws_eks_cluster._.kubernetes_network_config
  }
  description = "EKS Cluster information"
}

output "cluster_sg_id" {
  value       = aws_security_group.cluster.id
  description = "EKS Cluster security group"
}
