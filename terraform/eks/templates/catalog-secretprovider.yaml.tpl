apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: catalog-db-spc
  namespace: catalog
spec:
  provider: aws
  parameters:
    objects: |
      - objectName: "${catalog_db_secret_arn}"
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
    - secretName: catalog-db
      type: Opaque
      data:
        - objectName: username
          key: RETAIL_CATALOG_PERSISTENCE_USER
        - objectName: password
          key: RETAIL_CATALOG_PERSISTENCE_PASSWORD
        - objectName: host
          key: RETAIL_CATALOG_PERSISTENCE_ENDPOINT
        - objectName: database
          key: RETAIL_CATALOG_PERSISTENCE_DB_NAME
