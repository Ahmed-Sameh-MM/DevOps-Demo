output "prometheus_port_forward" {
  value = "kubectl -n monitoring port-forward svc/kps-kube-prometheus-stack-prometheus 9090:9090"
}

output "grafana_port_forward" {
  value = "kubectl -n monitoring port-forward svc/kps-grafana 3000:80"
}

output "grafana_admin_password_cmd" {
  value = "kubectl -n monitoring get secret kps-grafana -o jsonpath='{.data.admin-password}' | base64 -d; echo"
}
