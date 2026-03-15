# Ingress для публічного доступу до n8n (HTTPS). Cert ARN з Terraform.
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: n8n
  namespace: n8n
  labels:
    app.kubernetes.io/name: n8n
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/healthcheck-path: /healthz
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: "15"
    alb.ingress.kubernetes.io/healthcheck-timeout-seconds: "5"
    alb.ingress.kubernetes.io/healthy-threshold-count: "2"
    alb.ingress.kubernetes.io/unhealthy-threshold-count: "2"
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
    alb.ingress.kubernetes.io/ssl-redirect: "443"
    alb.ingress.kubernetes.io/certificate-arn: ${cert_arn}
spec:
  ingressClassName: alb
  rules:
    - host: n8n.staging.zipzip.online
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: n8n
                port:
                  number: 5678
