# Argo CD "invalid ownership metadata" fix

If you see:
```
Error: ... exists and cannot be imported into the current release: invalid ownership metadata...
```
(e.g. ServiceAccount, **ClusterRole** "argocd-application-controller", CRD)

Argo CD was installed outside this Terraform. Helm cannot adopt those resources.

**Fix: clean reinstall — видалити namespace, CRD, ClusterRole і ClusterRoleBinding**

```bash
# 1. Delete the argocd namespace
kubectl delete namespace argocd

# 2. Delete Argo CD CRDs
kubectl get crd -o name | grep argoproj.io | xargs kubectl delete 2>/dev/null || true

# 3. Delete Argo CD ClusterRoleBindings and ClusterRoles (спочатку bindings)
kubectl get clusterrolebinding -o name | grep argocd | xargs kubectl delete 2>/dev/null || true
kubectl get clusterrole -o name | grep argocd | xargs kubectl delete 2>/dev/null || true

# 4. Переконайся, що все видалено
kubectl get namespace argocd   # "NotFound"
kubectl get clusterrole | grep argocd   # нічого

# 5. Terraform apply (з terraform/eks/staging або prod)
terraform apply
```

After apply, Terraform will install the Argo CD Helm release and apply the bootstrap Application; Argo CD will then sync all apps from Git.
