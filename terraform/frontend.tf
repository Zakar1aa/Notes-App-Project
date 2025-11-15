# Frontend Deployment
resource "kubernetes_deployment" "frontend" {
  metadata {
    name      = "notes-frontend"
    namespace = kubernetes_namespace.notes_app.metadata[0].name
    
    labels = {
      app       = "notes-frontend"
      component = "frontend"
    }
  }
  
  spec {
    replicas = 2
    
    selector {
      match_labels = {
        app       = "notes-frontend"
        component = "frontend"
      }
    }
    
    template {
      metadata {
        labels = {
          app       = "notes-frontend"
          component = "frontend"
        }
      }
      
      spec {
        container {
          name  = "frontend"
          image = var.frontend_image
          
          port {
            container_port = 80
            name          = "http"
          }
          
          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
          
          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }
          
          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }
      }
    }
  }
}

# Frontend Service
resource "kubernetes_service" "frontend" {
  metadata {
    name      = "notes-frontend"
    namespace = kubernetes_namespace.notes_app.metadata[0].name
    
    labels = {
      app       = "notes-frontend"
      component = "frontend"
    }
  }
  
  spec {
    type = "ClusterIP"
    
    selector = {
      app       = "notes-frontend"
      component = "frontend"
    }
    
    port {
      name        = "http"
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }
  }
  
  depends_on = [kubernetes_deployment.frontend]
}