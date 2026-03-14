# -----------------------------------------------------------------------------
# Argo CD — встановлюється разом з кластером; bootstrap Application синхронізує
# мікросервіси з Git (deploy/gitops). У проді: один apply піднімає кластер + Argo CD,
# далі Argo CD сам деплоїть ui, catalog, cart, orders, checkout з репо.
# -----------------------------------------------------------------------------

locals {
  gitops_ok = var.gitops_enabled && var.gitops_repo_url != ""
  # Prod: тільки *-application.yaml без "staging"; staging: тільки *-staging-application.yaml
  gitops_dir_include  = var.gitops_target_revision == "staging" ? "*staging*.yaml" : "*.yaml"
  gitops_dir_exclude  = var.gitops_target_revision == "staging" ? "" : "*staging*"
}

resource "helm_release" "argocd" {
  count = local.gitops_ok ? 1 : 0

  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.7.10"
  namespace        = "argocd"
  create_namespace = true

  # Чекаємо, поки addons (LB controller, cert-manager тощо) будуть готові
  depends_on = [null_resource.addons_blocker]

  # Мінімальні values для прод-подібного запуску: server без TLS (або ingress окремо)
  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }
  set {
    name  = "configs.params.server.insecure"
    value = "true"
  }
}

resource "time_sleep" "argocd_crd" {
  count = local.gitops_ok ? 1 : 0

  create_duration = "45s"
  depends_on     = [helm_release.argocd[0]]
}

# AppProject "gitops" — дозволяє bootstrap Application створювати дочірні Application (app-of-apps).
# Проект "default" у деяких версіях Argo CD не дозволяє sync ресурсів kind: Application.
locals {
  argocd_project_gitops_yaml = local.gitops_ok ? yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = "gitops"
      namespace = "argocd"
    }
    spec = {
      description = "Allows app-of-apps to create child Application resources"
      sourceRepos = ["*"]
      destinations = [{ server = "https://kubernetes.default.svc", namespace = "*" }]
      namespaceResourceWhitelist = [
        { group = "argoproj.io", kind = "Application" },
        { group = "", kind = "*" }
      ]
      clusterResourceWhitelist = [{ group = "", kind = "Namespace" }]
    }
  }) : ""

  argocd_bootstrap_yaml = local.gitops_ok ? yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "retail-store-gitops"
      namespace = "argocd"
    }
    spec = {
      project = "gitops"
      source = {
        repoURL        = var.gitops_repo_url
        targetRevision = var.gitops_target_revision
        path           = var.gitops_path
        directory = merge(
          { include = local.gitops_dir_include },
          local.gitops_dir_exclude != "" ? { exclude = local.gitops_dir_exclude } : {}
        )
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "argocd"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
      }
    }
  }) : ""

  argocd_bootstrap_combined_yaml = local.gitops_ok ? "${local.argocd_project_gitops_yaml}\n---\n${local.argocd_bootstrap_yaml}" : ""
}

resource "null_resource" "argocd_gitops_bootstrap" {
  count = local.gitops_ok ? 1 : 0

  triggers = {
    yaml = local.argocd_bootstrap_combined_yaml
  }

  provisioner "local-exec" {
    command     = "aws eks update-kubeconfig --region ${data.aws_region.current.name} --name ${module.eks_cluster.cluster_name} && echo \"$YAML\" | base64 -d | kubectl apply -f -"
    environment = {
      YAML = base64encode(local.argocd_bootstrap_combined_yaml)
    }
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [time_sleep.argocd_crd[0]]
}

# Застосування дочірніх Application (ui, catalog, cart, orders, checkout) з локальної директорії.
# Використовується, коли directory sync не створює їх (обмеження Argo CD). Подальші оновлення — з Git через retail-store-gitops.
resource "null_resource" "argocd_child_apps_apply" {
  count = local.gitops_ok && var.gitops_manifests_local_path != "" ? 1 : 0

  triggers = {
    path   = var.gitops_manifests_local_path
    rev    = var.gitops_target_revision
    cluster = module.eks_cluster.cluster_name
  }

  provisioner "local-exec" {
    command     = <<-EOT
      set -e
      aws eks update-kubeconfig --region ${data.aws_region.current.name} --name ${module.eks_cluster.cluster_name}
      DIR="$DIR"
      REV="$REV"
      if [ ! -d "$DIR" ]; then echo "Directory not found: $DIR"; exit 1; fi
      shopt -s nullglob
      if [ "$REV" = "staging" ]; then
        for f in "$DIR"/*staging*.yaml; do kubectl apply -f "$f" || exit 1; done
      else
        for f in "$DIR"/*.yaml; do
          case "$f" in *staging*) continue ;; esac
          kubectl apply -f "$f" || exit 1
        done
      fi
    EOT
    environment = {
      DIR = var.gitops_manifests_local_path
      REV = var.gitops_target_revision
    }
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [null_resource.argocd_gitops_bootstrap[0]]
}
