variable "environment" {
  description = "Deployment environment (dev, staging, production)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used as prefix for resource naming"
  type        = string
  default     = "traqora"
}

variable "backend_image" {
  description = "Docker image for the backend ECS service"
  type        = string
  default     = "traqora/backend:latest"
}

variable "db_password" {
  description = "PostgreSQL password for the RDS instance"
  type        = string
  sensitive   = true
}
