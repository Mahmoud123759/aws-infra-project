output "vpc_id" {
  value = module.vpc.vpc_id
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "cloudfront_domain_name" {
  value = module.cloudfront.distribution_domain_name
}

output "rds_endpoint" {
  value     = module.rds.db_endpoint
  sensitive = true
}

output "asg_name" {
  value = module.asg.asg_name
}

output "sns_topic_arn" {
  value = module.sns.topic_arn
}

output "cloudwatch_dashboard_name" {
  value = module.monitoring.dashboard_name
}

output "waf_web_acl_arn" {
  value = module.waf.web_acl_arn
}

output "route53_record_fqdn" {
  value = var.domain_name != "" ? aws_route53_record.root[0].fqdn : null
}
