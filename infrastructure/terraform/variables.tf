variable "application_name" {
  description = "Unique Name for this deployment"
  type        = string 
}

variable "region" {  
  description = "Azure regions to deploy this application"
  type        = string
  default     = "centralus"
}

variable "postgresql_name" {
  description = "Azure PostgreSQL"
  type        = string
}

variable "postgresql_database_name" {
  description = "PostgreSQL Database Name"
  type        = string
  default     = "Transcripts"
}

variable "acr_account_name" {
  description = "Azure Container Repository"
  type        = string
}

variable "ai_account_name" {
  description = "Application Insights"
  type        = string
}

variable "loganalytics_account_name" {
  description = "Log Analytics"
  type        = string
}

variable "vnet_name" {
  description = "Virtual Network Name"
  type        = string
}

variable "service_bus_namespace_name" {
  description = "Service Bus Namespace"
  type        = string
}

variable "aks_name" {
  description = "AKS Cluster"
  type        = string
}

variable "ui_storage_name" {
  description = "Storage Account for the Application UI"
  type        = string
}

variable "mp3_storage_name " {
  description = "Storage Account for the mp3s transcribed"
  type        = string
}

variable "keyvault_name" {
  description = "Azure Key Vault"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH Public Key"
  type        = string
}

variable "api_server_authorized_ip_ranges" {
  description = "IP Range for K8S API Access"
  type        = string
}
