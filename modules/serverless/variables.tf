variable "project_id" {
  type = string
}
variable "environment" {
  type = string
}
variable "region" {
  type    = string
  default = "us-central1"
}
variable "api_service_sa_email" {
  type = string
}
variable "vpc_connector_network" {
  type = string
}
