"""
Disaster recovery configuration for stateful workloads.
Backup/restore targets: PostgreSQL (orders), MySQL (catalog).
"""
import os
from dataclasses import dataclass, field
from typing import Literal

BACKUP_DIR = os.environ.get("DR_BACKUP_DIR", os.path.join(os.path.dirname(__file__), "..", "backups"))


@dataclass
class DbTarget:
    """Single stateful DB target for backup/restore."""
    id: str
    type: Literal["postgresql", "mysql"]
    namespace: str
    # StatefulSet / service base name (pod will be {name}-0)
    service_name: str
    database: str
    secret_name: str
    user_key: str
    password_key: str
    # Optional: container name if not default
    container: str = ""


# Default targets aligned with helm charts: orders (postgresql), catalog (mysql).
# Namespace: Argo CD uses "orders"/"catalog". Helmfile uses "default" — set DR_*_NAMESPACE=default.
# Service name: Argo CD release can be "retail-store-orders" → pod retail-store-orders-orders-postgresql-0;
# set DR_ORDERS_POSTGRESQL_SERVICE_NAME / DR_CATALOG_MYSQL_SERVICE_NAME if needed.
DEFAULT_TARGETS = [
    DbTarget(
        id="orders-postgresql",
        type="postgresql",
        namespace=os.environ.get("DR_ORDERS_NAMESPACE", "orders"),
        service_name=os.environ.get("DR_ORDERS_POSTGRESQL_SERVICE_NAME", "orders-postgresql"),
        database="orders",
        secret_name="orders-db",
        user_key="RETAIL_ORDERS_PERSISTENCE_USERNAME",
        password_key="RETAIL_ORDERS_PERSISTENCE_PASSWORD",
        container="postgresql",
    ),
    DbTarget(
        id="catalog-mysql",
        type="mysql",
        namespace=os.environ.get("DR_CATALOG_NAMESPACE", "catalog"),
        service_name=os.environ.get("DR_CATALOG_MYSQL_SERVICE_NAME", "catalog-mysql"),
        database="catalog",
        secret_name="catalog-db",
        user_key="RETAIL_CATALOG_PERSISTENCE_USER",
        password_key="RETAIL_CATALOG_PERSISTENCE_PASSWORD",
        container="mysql",
    ),
]


def get_backup_dir() -> str:
    os.makedirs(BACKUP_DIR, exist_ok=True)
    return BACKUP_DIR
