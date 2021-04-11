output "id" {
  value       = module.vpc.*.vpc_id
  description = "The ID of the VPC."
}


