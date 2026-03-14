# Argo CD "invalid ownership metadata" fix

If you see:
```
Error: ServiceAccount "argocd-application-controller" in namespace "argocd" exists and cannot be imported into the current release: invalid ownership metadata...
```

Argo CD was installed outside this Terraform (e.g. manually or by an older run). Helm cannot adopt those resources.

**Fix: clean reinstall**

```bash
# 1. Delete the existing argocd namespace (Applications are in Git and will be recreated)
kubectl delete namespace argocd

# 2. Wait until the namespace is gone
kubectl get namespace argocd  # should be "NotFound"

# 3. Run Terraform again
terraform apply
```

After apply, Terraform will install the Argo CD Helm release and apply the bootstrap Application; Argo CD will then sync all apps from Git.
