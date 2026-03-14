resource "aws_kms_key" "secrets" {
  description             = "${var.environment_name} secrets CMK"
  deletion_window_in_days = 7
}

resource "aws_secretsmanager_secret" "catalog_db" {
  # Use name_prefix to avoid conflicts with secrets scheduled for deletion
  name_prefix = "${var.environment_name}-catalog-db-"
  kms_key_id = aws_kms_key.secrets.key_id
}

resource "aws_secretsmanager_secret_version" "catalog_db" {
  secret_id = aws_secretsmanager_secret.catalog_db.id

  secret_string = jsonencode({
    username = module.catalog_rds.cluster_master_username
    password = module.catalog_rds.cluster_master_password
    host     = module.catalog_rds.cluster_endpoint
    port     = module.catalog_rds.cluster_port
    database = module.catalog_rds.cluster_database_name
  })
}

resource "aws_secretsmanager_secret" "orders_db" {
  # Use name_prefix to avoid conflicts with secrets scheduled for deletion
  name_prefix = "${var.environment_name}-orders-db-"
  kms_key_id = aws_kms_key.secrets.key_id
}

resource "aws_secretsmanager_secret_version" "orders_db" {
  secret_id = aws_secretsmanager_secret.orders_db.id

  secret_string = jsonencode({
    username = module.orders_rds.cluster_master_username
    password = module.orders_rds.cluster_master_password
    host     = module.orders_rds.cluster_endpoint
    port     = module.orders_rds.cluster_port
    database = module.orders_rds.cluster_database_name
  })
}

resource "aws_secretsmanager_secret" "mq" {
  # Use name_prefix to avoid conflicts with secrets scheduled for deletion
  name_prefix = "${var.environment_name}-mq-"
  kms_key_id = aws_kms_key.secrets.key_id
}

resource "aws_secretsmanager_secret_version" "mq" {
  secret_id = aws_secretsmanager_secret.mq.id

  secret_string = jsonencode({
    username = local.mq_default_user
    password = random_password.mq_password.result
    endpoint = aws_mq_broker.mq.instances[0].endpoints[0]
  })
}

