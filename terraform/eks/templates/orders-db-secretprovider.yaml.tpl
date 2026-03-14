apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: orders-db-spc
  namespace: orders
spec:
  provider: aws
  parameters:
    objects: |
      - objectName: "${orders_db_secret_arn}"
        objectType: "secretsmanager"
        jmesPath:
          - path: username
            objectAlias: username
          - path: password
            objectAlias: password
          - path: host
            objectAlias: host
          - path: port
            objectAlias: port
          - path: database
            objectAlias: database
  secretObjects:
    - secretName: orders-db
      type: Opaque
      data:
        - objectName: username
          key: RETAIL_ORDERS_PERSISTENCE_USERNAME
        - objectName: password
          key: RETAIL_ORDERS_PERSISTENCE_PASSWORD
        - objectName: host
          key: RETAIL_ORDERS_PERSISTENCE_ENDPOINT
        - objectName: database
          key: RETAIL_ORDERS_PERSISTENCE_NAME
