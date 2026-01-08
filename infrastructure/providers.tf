data "local_file" "kubeconfig" {
  depends_on = [null_resource.k3d_cluster]
  filename   = pathexpand("~/.kube/config")
}

provider "kubernetes" {
  config_path = pathexpand("~/.kube/config")
}

provider "helm" {
  kubernetes {
    config_path = pathexpand("~/.kube/config")
  }
}
