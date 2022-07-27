terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

provider "kubernetes" {
  config_path    = "kubeconfig.yml"
}

# === Services ==============================================================
resource "kubernetes_namespace_v1" "apps" {
  metadata {
    generate_name = "apps"
  }
}

resource "kubernetes_pod_v1" "app-1" {
  metadata {
    name = "app-1"
    namespace = kubernetes_namespace_v1.apps.metadata[0].name
    labels = {
      app = "app-1"
    }
  }

  spec {
    container {
      image = "registry.gitlab.com/mage-sauce/dockerization/http-test-container:latest"
      name  = "app-1"

      image_pull_policy = "Always"

      env {
        name = "BIND"
        value = "0.0.0.0:8080"
      }

      port {
        container_port = 8080
      }
    }
  }
}
resource "kubernetes_pod_v1" "app-2" {
  metadata {
    name = "app-2"
    namespace = kubernetes_namespace_v1.apps.metadata[0].name
    labels = {
      app = "app-2"
    }
  }

  spec {
    container {
      image = "registry.gitlab.com/mage-sauce/dockerization/http-test-container:latest"
      name  = "app-2"
      image_pull_policy = "Always"

      env {
        name = "BIND"
        value = "0.0.0.0:8080"
      }

      port {
        container_port = 8080
      }
    }
  }
}

resource "kubernetes_service_v1" "app-1" {
  metadata {
    generate_name = "app-1"
    namespace = kubernetes_namespace_v1.apps.metadata[0].name
  }
  spec {
    selector = {
      app = kubernetes_pod_v1.app-1.metadata.0.labels.app
    }
    session_affinity = "ClientIP"
    port {
      target_port = kubernetes_pod_v1.app-1.spec[0].container[0].port[0].container_port
      port        = 80
    }

    type = "NodePort"
  }
}

resource "kubernetes_service_v1" "app-2" {
  metadata {
    generate_name = "app-2"
    namespace = kubernetes_namespace_v1.apps.metadata[0].name
  }
  spec {
    selector = {
      app = kubernetes_pod_v1.app-2.metadata.0.labels.app
    }
    session_affinity = "ClientIP"
    port {
      target_port = kubernetes_pod_v1.app-2.spec[0].container[0].port[0].container_port
      port        = 80
    }

    type = "NodePort"
  }
}

resource "kubernetes_ingress_v1" "app-1" {
  metadata {
    generate_name = "app-1"
    namespace = kubernetes_namespace_v1.apps.metadata[0].name
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target": "/$1"
    }
  }

  spec {
    default_backend {
      service {
        name = kubernetes_service_v1.app-1.metadata[0].name
        port {
          number = kubernetes_service_v1.app-1.spec[0].port[0].port
        }
      }
    }

    rule {
      http {
        path {
          path = "/${kubernetes_service_v1.app-1.metadata[0].generate_name}"
          backend {
            service {
              name = kubernetes_service_v1.app-1.metadata[0].name
              port {
                number = kubernetes_service_v1.app-1.spec[0].port[0].port
              }
            }
          }
        }

        path {
          path = "/${kubernetes_service_v1.app-1.metadata[0].generate_name}/(.*)"
          backend {
            service {
              name = kubernetes_service_v1.app-1.metadata[0].name
              port {
                number = kubernetes_service_v1.app-1.spec[0].port[0].port
              }
            }
          }
        }
      }
    }

  }
}

resource "kubernetes_ingress_v1" "app-2" {
  metadata {
    generate_name = "app-2"
    namespace = kubernetes_namespace_v1.apps.metadata[0].name
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target": "/$1"
    }
  }

  spec {

    rule {
      http {
        path {
          path = "/${kubernetes_service_v1.app-2.metadata[0].generate_name}"
          backend {
            service {
              name = kubernetes_service_v1.app-2.metadata[0].name
              port {
                number = kubernetes_service_v1.app-2.spec[0].port[0].port
              }
            }
          }
        }

        path {
          path = "/${kubernetes_service_v1.app-2.metadata[0].generate_name}/(.*)"
          backend {
            service {
              name = kubernetes_service_v1.app-2.metadata[0].name
              port {
                number = kubernetes_service_v1.app-2.spec[0].port[0].port
              }
            }
          }
        }
      }
    }
  }
}
