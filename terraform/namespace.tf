# Create namespace for the application
resource "kubernetes_namespace" "notes_app" {
  metadata {
    name = var.namespace
    
    labels = {
      name        = var.namespace
      environment = "development"
      app         = "notes-app"
    }
  }
}