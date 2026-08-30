output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "backend_service_name" {
  description = "Name of the ECS backend service"
  value       = aws_ecs_service.backend.name
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.backend.name
}

output "db_endpoint" {
  description = "RDS endpoint for the backend database"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}
