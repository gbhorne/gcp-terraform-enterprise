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

variable "machine_type" {
  description = "GCE machine type"
  type        = string
  default     = "e2-micro"
}

variable "vpc_name" {
  description = "VPC network name"
  type        = string
}

variable "subnet_name" {
  description = "Subnetwork name for instances"
  type        = string
}

variable "service_account_email" {
  description = "Service account email for instances"
  type        = string
}

variable "min_replicas" {
  description = "Minimum number of instances"
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Maximum number of instances"
  type        = number
  default     = 3
}