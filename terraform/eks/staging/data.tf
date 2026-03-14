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

# UI service when GitOps is enabled (Argo CD deploys to ui-staging with LoadBalancer)
data "kubernetes_service" "ui_staging_service" {
  count = var.gitops_enabled ? 1 : 0

  metadata {
    name      = "retail-store-ui-staging"
    namespace = "ui-staging"
  }
}