# ConfigMap for API configuration
resource "kubernetes_config_map" "api_config" {
  metadata {
    name      = "api-config"
    namespace = kubernetes_namespace.notes_app.metadata[0].name
  }
  
  data = {
    DB_HOST = kubernetes_service.db.metadata[0].name
    DB_PORT = "5432"
    DB_NAME = var.db_name
  }
}

# API Deployment
resource "kubernetes_deployment" "api" {
  metadata {
    name      = "notes-api"
    namespace = kubernetes_namespace.notes_app.metadata[0].name
    
    labels = {
      app       = "notes-api"
      component = "backend"
    }
  }
  
  spec {
    replicas = 2
    
    selector {
      match_labels = {
        app       = "notes-api"
        component = "backend"
      }
    }
    
    template {
      metadata {
        labels = {
          app       = "notes-api"
          component = "backend"
        }
      }
      
      spec {
        container {
          name  = "api"
          image = var.api_image
          
          port {
            container_port = 5000
            name          = "http"
          }
          
          env {
            name = "DB_HOST"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.api_config.metadata[0].name
                key  = "DB_HOST"
              }
            }
          }
          
          env {
            name = "DB_PORT"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.api_config.metadata[0].name
                key  = "DB_PORT"
              }
            }
          }
          
          env {
            name = "DB_NAME"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.api_config.metadata[0].name
                key  = "DB_NAME"
              }
            }
          }
          
          env {
            name = "DB_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db_credentials.metadata[0].name
                key  = "POSTGRES_USER"
              }
            }
          }
          
          env {
            name = "DB_PASS"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db_credentials.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }
          
          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
          
          liveness_probe {
            http_get {
              path = "/health"
              port = 5000
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }
          
          readiness_probe {
            http_get {
              path = "/health"
              port = 5000
            }
            initial_delay_seconds = 10
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }
        
        # Wait for database to be ready
        init_container {
          name  = "wait-for-db"
          image = "busybox:1.36"
          
          command = [
            "sh",
            "-c",
            "until nc -z ${kubernetes_service.db.metadata[0].name} 5432; do echo waiting for db; sleep 2; done"
          ]
        }
      }
    }
  }
  
  depends_on = [
    kubernetes_service.db,
    kubernetes_config_map.api_config
  ]
}

# API Service
resource "kubernetes_service" "api" {
  metadata {
    name      = "notes-api"
    namespace = kubernetes_namespace.notes_app.metadata[0].name
    
    labels = {
      app       = "notes-api"
      component = "backend"
    }
  }
  
  spec {
    type = "ClusterIP"
    
    selector = {
      app       = "notes-api"
      component = "backend"
    }
    
    port {
      name        = "http"
      port        = 5000
      target_port = 5000
      protocol    = "TCP"
    }
  }
  
  depends_on = [kubernetes_deployment.api]
}