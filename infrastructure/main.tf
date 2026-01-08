# Create k3d cluster (idempotent-ish: checks if it exists)
resource "null_resource" "k3d_cluster" {
  provisioner "local-exec" {
    command = <<EOT
set -e
if ! k3d cluster list | grep -q "^${var.cluster_name}"; then
  k3d cluster create ${var.cluster_name} \
    --agents 2 \
    -p "8080:80@loadbalancer" -p "443:443@loadbalancer"
fi
EOT
  }
}


# Build the Docker image for the frontend
resource "null_resource" "build_frontend" {
  triggers = {
    version = var.frontend_image_version
  }

  provisioner "local-exec" {
    command = "docker build -t frontend:${var.frontend_image_version} ${path.module}/../frontend/demo-ui"
  }
}

# Build the Docker image for the backend
resource "null_resource" "build_backend" {
  triggers = {
    version = var.backend_image_version
  }

  provisioner "local-exec" {
    command = "docker build -t backend:${var.backend_image_version} ${path.module}/../backend/Demo.Api"
  }
}

locals {
  frontend_image = "frontend:${var.frontend_image_version}"
  backend_image  = "backend:${var.backend_image_version}"

  images = [local.frontend_image, local.backend_image]
}

resource "null_resource" "k3d_load_images" {
  depends_on = [
    null_resource.k3d_cluster,
    null_resource.build_frontend,
    null_resource.build_backend
  ]

  triggers = {
    images = join(",", local.images)
  }

  provisioner "local-exec" {
    command = <<EOT
      k3d image load -c ${var.cluster_name} ${join(" ", local.images)}
    EOT
  }
}

resource "null_resource" "wait_for_kube_api" {
  depends_on = [null_resource.k3d_cluster]

  provisioner "local-exec" {
    command = <<EOT
set -e
CTX="k3d-${var.cluster_name}"

echo "Waiting for Kubernetes API for $CTX..."
for i in $(seq 1 60); do
  kubectl --context "$CTX" get --raw='/readyz' >/dev/null 2>&1 && exit 0
  sleep 2
done

echo "Kubernetes API not ready in time"
exit 1
EOT
  }
}

# Main Namespace
resource "kubernetes_namespace_v1" "demo" {
  depends_on = [null_resource.wait_for_kube_api]

  metadata {
    name = "demo"
  }
}

resource "random_password" "sql" {
  length  = 32
  special = true
}

resource "kubernetes_secret_v1" "mssql_password" {
  depends_on = [kubernetes_namespace_v1.demo]

  metadata {
    name      = "mssql-secret"
    namespace = kubernetes_namespace_v1.demo.metadata[0].name
  }

  type = "Opaque"

  data = {
    SA_PASSWORD = random_password.sql.result
  }
}

resource "null_resource" "apply_app_manifests" {
  depends_on = [
    kubernetes_namespace_v1.demo,
    kubernetes_secret_v1.mssql_password
  ]

  provisioner "local-exec" {
    command = <<EOT
set -e
kubectl apply -f ${path.module}/k8s/00-mssql.yaml
kubectl apply -f ${path.module}/k8s/10-backend.yaml
kubectl apply -f ${path.module}/k8s/20-frontend.yaml
kubectl apply -f ${path.module}/k8s/30-ingress.yaml
EOT
  }
}


# Monitoring
resource "kubernetes_namespace_v1" "monitoring" {
  depends_on = [null_resource.wait_for_kube_api]

  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "prometheus" {
  depends_on = [kubernetes_namespace_v1.monitoring]
  name       = "kps"
  namespace  = "monitoring"

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "57.2.0" # optional but recommended

  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
    value = "false"
  }

  set {
    name  = "prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues"
    value = "false"
  }
}

resource "null_resource" "apply_monitoring_manifests" {
  depends_on = [
    kubernetes_namespace_v1.monitoring,
    helm_release.prometheus,
    null_resource.apply_app_manifests
  ]

  provisioner "local-exec" {
    command = <<EOT
set -e
kubectl apply -f ${path.module}/k8s/40-backend-servicemonitor.yaml
EOT
  }
}
