variable "project_name" {
  type        = string
  description = "The Project name"
  default     = "eks"
}

variable "environment" {
  type        = string
  description = "The environment id where those resources will be created such as stag, production, qa"
  default     = "stg"
}

variable "cidr_block" {
  type        = string
  description = "The main CIDR block of the VPC"
  default     = "172.19.0.0/18"
}

variable "region" {
  type        = string
  description = "AWS Region name"
  default     = "us-east-1"
}

variable "enable_dns_hostnames" {
  type        = bool
  description = "A Boolean to enable the dns hostname resolving"
  default     = true
}

variable "enable_nat_gateway" {
  type        = bool
  description = "A Boolean either to create a NAT GW in the VPC, used by the private subnets"
  default     = true
}

variable "enable_internet_gateway" {
  type        = string
  description = "A Boolean either to create an internet GW for the public reachability"
  default     = true
}

variable "create_public_subnets" {
  type        = bool
  description = "A Boolean, for creating public subnets"
  default     = true
}

variable "single_nat_gateway" {
  type        = bool
  description = "A Boolean, either to create a single NAT GW for the VPC or to create a separate  NAT GW for each AZ"
  default     = true
}

variable "kubernetes_cidr" {
  type        = string
  description = "Configuration block with kubernetes network configuration for the cluster"
  default     = "172.16.64.0/24"
}

variable "cluster_timeouts" {
  description = "Create, update, and delete timeout configurations for the cluster"
  type        = map(string)
  default     = {}
}

variable "gh_branch" {
  type        = string
  description = "GH Branch that will mapped to QA EKS Deployments"
  default     = "main"
}

variable "create_ecr_repository" {
  type        = bool
  default     = true
  description = "Boolean, either to create a new ECR repository or use existing one"
}

variable "create_kms_key" {
  type        = bool
  default     = true
  description = "Boolean, either to create a new KMS key or use existing one"
}

variable "create_acm_certificate" {
  type        = bool
  default     = true
  description = "Boolean, either to create a new ACM certificate or use existing one"
}

variable "domain" {
  type        = string
  description = "Domain Name to issue ACM Certificate"
  default     = "example.org"
}

variable "cluster_ip_family" {
  type        = string
  description = "The IP type of EKS Cluster"
  default     = "ipv4"
}
