resource "aws_codestarconnections_connection" "_" {
  name          = local.prefix
  provider_type = "GitHub"
  tags          = local.common_tags
}