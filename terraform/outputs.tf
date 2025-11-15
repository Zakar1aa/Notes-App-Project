output "namespace" {
  description = "Kubernetes namespace"
  value       = kubernetes_namespace.notes_app.metadata[0].name
}

output "application_url" {
  description = "Application URL"
  value       = "http://notes.${var.vm_ip}.nip.io"
}

output "frontend_service" {
  description = "Frontend service name"
  value       = kubernetes_service.frontend.metadata[0].name
}

output "api_service" {
  description = "API service name"
  value       = kubernetes_service.api.metadata[0].name
}

output "db_service" {
  description = "Database service name"
  value       = kubernetes_service.db.metadata[0].name
}

output "ingress_host" {
  description = "Ingress hostname"
  value       = "notes.${var.vm_ip}.nip.io"
}