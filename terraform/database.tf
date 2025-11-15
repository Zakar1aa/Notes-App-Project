# PersistentVolumeClaim for PostgreSQL
resource "kubernetes_persistent_volume_claim" "db_pvc" {
  metadata {
    name      = "db-pvc"
    namespace = kubernetes_namespace.notes_app.metadata[0].name
    
    labels = {
      app       = "notes-db"
      component = "database"
    }
  }
  
  spec {
    access_modes = ["ReadWriteOnce"]
    
    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
}

# ConfigMap for database initialization
resource "kubernetes_config_map" "db_init" {
  metadata {
    name      = "db-init-script"
    namespace = kubernetes_namespace.notes_app.metadata[0].name
  }
  
  data = {
    "init.sql" = <<-SQL
      CREATE TABLE IF NOT EXISTS notes (
          id SERIAL PRIMARY KEY,
          note TEXT NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
      
      CREATE INDEX IF NOT EXISTS idx_notes_created_at ON notes(created_at DESC);
      
      INSERT INTO notes (note) VALUES 
          ('Welcome to NotesApp!'),
          ('This is your first note'),
          ('You can add, view, and delete notes');
    SQL
  }
}
# Secret for database credentials
resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "db-credentials"
    namespace = kubernetes_namespace.notes_app.metadata[0].name
  }
  
  type = "Opaque"
  
  data = {
    POSTGRES_DB       = base64encode(var.db_name)
    POSTGRES_USER     = base64encode(var.db_user)
    POSTGRES_PASSWORD = base64encode(var.db_password)
  }
}

# PostgreSQL Deployment
resource "kubernetes_deployment" "db" {
  metadata {
    name      = "notes-db"
    namespace = kubernetes_namespace.notes_app.metadata[0].name
    
    labels = {
      app       = "notes-db"
      component = "database"
    }
  }
  
  spec {
    replicas = 1
    
    selector {
      match_labels = {
        app       = "notes-db"
        component = "database"
      }
    }
    
    template {
      metadata {
        labels = {
          app       = "notes-db"
          component = "database"
        }
      }
      
      spec {
        container {
          name  = "postgres"
          image = var.db_image
          
          port {
            container_port = 5432
            name          = "postgres"
          }
          
          env_from {
            secret_ref {
              name = kubernetes_secret.db_credentials.metadata[0].name
            }
          }
          
          volume_mount {
            name       = "db-data"
            mount_path = "/var/lib/postgresql/data"
            sub_path   = "postgres"
          }
          
          volume_mount {
            name       = "init-script"
            mount_path = "/docker-entrypoint-initdb.d"
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
            exec {
              command = ["pg_isready", "-U", var.db_user]
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }
          
          readiness_probe {
            exec {
              command = ["pg_isready", "-U", var.db_user]
            }
            initial_delay_seconds = 10
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }
        
        volume {
          name = "db-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.db_pvc.metadata[0].name
          }
        }
        
        volume {
          name = "init-script"
          config_map {
            name = kubernetes_config_map.db_init.metadata[0].name
          }
        }
      }
    }
  }
  
  depends_on = [
    kubernetes_persistent_volume_claim.db_pvc,
    kubernetes_secret.db_credentials,
    kubernetes_config_map.db_init
  ]
}

# PostgreSQL Service
resource "kubernetes_service" "db" {
  metadata {
    name      = "notes-db"
    namespace = kubernetes_namespace.notes_app.metadata[0].name
    
    labels = {
      app       = "notes-db"
      component = "database"
    }
  }
  
  spec {
    type = "ClusterIP"
    
    selector = {
      app       = "notes-db"
      component = "database"
    }
    
    port {
      name        = "postgres"
      port        = 5432
      target_port = 5432
      protocol    = "TCP"
    }
  }
  
  depends_on = [kubernetes_deployment.db]
}
