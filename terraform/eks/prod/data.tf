data "aws_eks_cluster_auth" "this" {
  name = module.retail_app_eks.eks_cluster_id

  depends_on = [
    null_resource.cluster_blocker
  ]
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.retail_app_eks.eks_cluster_id
}

# UI service when GitOps is disabled (Terraform deploys UI to namespace ui)
data "kubernetes_service" "ui_service" {
  count = var.gitops_enabled ? 0 : 1

  depends_on = [helm_release.ui]

  metadata {
    name      = "ui"
    namespace = "ui"
  }
}

# UI service when GitOps is enabled (Argo CD deploys to ui-prod with LoadBalancer)
data "kubernetes_service" "ui_prod_service" {
  count = var.gitops_enabled ? 1 : 0

  metadata {
    name      = "retail-store-ui-prod"
    namespace = "ui-prod"
  }
}

# Live hostname from cluster (kubectl) so output shows URL as soon as LB is ready
data "external" "ui_prod_lb_hostname" {
  count = var.gitops_enabled ? 1 : 0

  program = ["sh", "-c", "hn=$(kubectl get svc -n ui-prod retail-store-ui-prod -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null); echo \"{\\\"hostname\\\": \\\"$${hn:-}\\\"}\""]
}
