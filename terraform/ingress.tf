# Ingress resource for external access
resource "kubernetes_ingress_v1" "notes" {
  metadata {
    name      = "notes-ingress"
    namespace = kubernetes_namespace.notes_app.metadata[0].name
    
    labels = {
      app = "notes-app"
    }
    
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/$2"
      "nginx.ingress.kubernetes.io/use-regex"      = "true"
    }
  }
  
  spec {
    ingress_class_name = "nginx"
    
    rule {
      host = "notes.${var.vm_ip}.nip.io"
      
      http {
        # Frontend route
        path {
          path      = "/()(.*)"
          path_type = "ImplementationSpecific"
          
          backend {
            service {
              name = kubernetes_service.frontend.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
        
        # API route
        path {
          path      = "/api(/|$)(.*)"
          path_type = "ImplementationSpecific"
          
          backend {
            service {
              name = kubernetes_service.api.metadata[0].name
              port {
                number = 5000
              }
            }
          }
        }
      }
    }
  }
  
  depends_on = [
    kubernetes_service.frontend,
    kubernetes_service.api
  ]
}