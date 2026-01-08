variable "cluster_name" {
  type = string
  default = "demo-cluster"
}

variable "frontend_image_version" {
  type        = string
  description = "Docker frontend image version tag (e.g. v1, v2, v3)"
}

variable "backend_image_version" {
  type        = string
  description = "Docker backend image version tag (e.g. v1, v2, v3)"
}
