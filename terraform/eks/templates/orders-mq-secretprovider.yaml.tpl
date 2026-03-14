apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: orders-mq-spc
  namespace: orders
spec:
  provider: aws
  parameters:
    objects: |
      - objectName: "${mq_secret_arn}"
        objectType: "secretsmanager"
        jmesPath:
          - path: username
            objectAlias: username
          - path: password
            objectAlias: password
          - path: endpoint
            objectAlias: endpoint
  secretObjects:
    - secretName: orders-mq
      type: Opaque
      data:
        - objectName: endpoint
          key: RETAIL_ORDERS_MESSAGING_RABBITMQ_ADDRESSES
        - objectName: username
          key: RETAIL_ORDERS_MESSAGING_RABBITMQ_USERNAME
        - objectName: password
          key: RETAIL_ORDERS_MESSAGING_RABBITMQ_PASSWORD
