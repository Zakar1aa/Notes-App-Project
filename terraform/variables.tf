variable "vm_ip" {
  description = "VM IP address for nip.io DNS"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for the application"
  type        = string
  default     = "notes-app"
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "notesdb"
}

variable "db_user" {
  description = "PostgreSQL database user"
  type        = string
  default     = "notesuser"
}

variable "db_password" {
  description = "PostgreSQL database password"
  type        = string
  default     = "notespass"
  sensitive   = true
}

variable "frontend_image" {
  description = "Docker image for frontend"
  type        = string
  default     = "zakaria529/notes-frontend:latest"
}

variable "api_image" {
  description = "Docker image for API"
  type        = string
  default     = "zakaria529/notes-api:latest"
}

variable "db_image" {
  description = "Docker image for database"
  type        = string
  default     = "postgres:15-alpine"
}