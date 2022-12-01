variable "location" {
  description = "The location for this application deployment"
  default = "southcentralus"
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

variable "pubsub_secret_name" {
  description = "Key Vault Secret Name for Web PubSub Primary Key"
  type        = string
  default     = "pubsubkey"
}