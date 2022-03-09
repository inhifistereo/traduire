variable "tenant_id" {
  description = "Azure AD Tenant ID"
  type        = string 
}

variable "admin_user_object_id" {
  description = "Azure AD Object ID of PostgreSQL Admin User"
  type        = string 
}

variable "admin_user_name" {
  description = "Azure AD UPN of PostgreSQL Admin User"
  type        = string 
}

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

variable "postgresql_user_name" {
  description = "Azure PostgreSQL User Name"
  type        = string
  default     = "manager"
}

variable "postgresql_database_name" {
  description = "PostgreSQL Database Name"
  type        = string
  default     = "transcriptsdb"
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

variable "mp3_storage_name" {
  description = "Storage Account for the mp3s transcribed"
  type        = string
}

variable "keyvault_name" {
  description = "Azure Key Vault"
  type        = string
}

variable "api_server_authorized_ip_ranges" {
  description = "IP Range for K8S API Access"
  type        = string
}

variable "service_bus_secret_name" {
  description = "Key Vault Secret Name for Service Bus Connection String"
  type        = string
  default     = "sbconnection"
}

variable "storage_secret_name" {
  description = "Key Vault Secret Name for Azure Storage Access Key"
  type        = string
  default     = "storagekey"
}

variable "postgresql_secret_name" {
  description = "Key Vault Secret Name for PostgreSQL Connection String"
  type        = string
  default     = "postgresqlconnection"
}

variable "cognitive_services_secret_name" {
  description = "Key Vault Secret Name for Cognitive Secret Primary Key"
  type        = string
  default     = "speech2textkey"
}

variable "pubsub_name" {
  description = "Azure Web Pubsub Name"
  type        = string
}

variable "pubsub_secret_name" {
  description = "Key Vault Secret Name for Web PubSub Primary Key"
  type        = string
  default     = "pubsubkey"
}