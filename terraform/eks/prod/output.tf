output "configure_kubectl" {
  description = "Command to update kubeconfig for this cluster"
  value       = module.retail_app_eks.configure_kubectl
}

output "retail_app_url" {
  description = "URL to access the retail store application (GitOps: ui-prod LB, else: ui LB)"
  value = var.gitops_enabled ? (
    data.external.ui_prod_lb_hostname[0].result.hostname != "" ? "http://${data.external.ui_prod_lb_hostname[0].result.hostname}" : (
      try(
        "http://${data.kubernetes_service.ui_prod_service[0].status[0].load_balancer[0].ingress[0].hostname}",
        "LoadBalancer provisioning - run: kubectl get svc -n ui-prod"
      )
    )
    ) : (
    try(
      "http://${data.kubernetes_service.ui_service[0].status[0].load_balancer[0].ingress[0].hostname}",
      "LoadBalancer provisioning - run: kubectl get svc -n ui ui"
    )
  )
}
