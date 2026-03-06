variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "tier" {
  description = "Cloud SQL machine tier"
  type        = string
  default     = "db-f1-micro"
}

variable "disk_size" {
  description = "Initial disk size in GB"
  type        = number
  default     = 10
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "appdb"
}

variable "database_user" {
  description = "Database user name"
  type        = string
  default     = "appuser"
}

variable "vpc_id" {
  description = "VPC network ID for private IP"
  type        = string
}

variable "private_vpc_connection" {
  description = "Private VPC connection dependency"
  type        = string
}

variable "deletion_protection" {
  description = "Enable deletion protection on the instance"
  type        = bool
  default     = false
}