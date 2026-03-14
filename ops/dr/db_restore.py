"""
Restore stateful databases from backup dumps (PostgreSQL, MySQL).
"""
import subprocess
import sys

from .config import DEFAULT_TARGETS, DbTarget
from .db_backup import _get_pod_name, _get_secret_value


def _run(cmd: list[str], stdin=None, timeout: int = 600) -> tuple[int, str]:
    try:
        r = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout,
            stdin=stdin,
        )
        out = (r.stdout or "") + (r.stderr or "")
        return r.returncode, out
    except subprocess.TimeoutExpired:
        return -1, "Command timed out"
    except FileNotFoundError:
        return -1, "kubectl not found"


def restore_postgres(target: DbTarget, dump_path: str) -> None:
    """Restore PostgreSQL from dump file into pod via kubectl exec + psql."""
    user = _get_secret_value(target.namespace, target.secret_name, target.user_key)
    password = _get_secret_value(target.namespace, target.secret_name, target.password_key)
    pod = _get_pod_name(target.namespace, target.service_name)
    container = target.container or "postgresql"
    with open(dump_path, "r", encoding="utf-8") as f:
        content = f.read()
    p = subprocess.Popen(
        ["kubectl", "exec", "-i", "-n", target.namespace, pod, "-c", container, "--",
         "env", f"PGPASSWORD={password}", "psql", "-U", user, "-d", target.database],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    out, err = p.communicate(input=content, timeout=600)
    if p.returncode != 0:
        raise RuntimeError(f"psql restore failed: {err or out}")


def restore_mysql(target: DbTarget, dump_path: str) -> None:
    """Restore MySQL from dump file into pod via kubectl exec + mysql."""
    user = _get_secret_value(target.namespace, target.secret_name, target.user_key)
    password = _get_secret_value(target.namespace, target.secret_name, target.password_key)
    pod = _get_pod_name(target.namespace, target.service_name)
    container = target.container or "mysql"
    with open(dump_path, "r", encoding="utf-8") as f:
        content = f.read()
    p = subprocess.Popen(
        ["kubectl", "exec", "-i", "-n", target.namespace, pod, "-c", container, "--",
         "mysql", "-u", user, f"--password={password}", target.database],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    out, err = p.communicate(input=content, timeout=600)
    if p.returncode != 0:
        raise RuntimeError(f"mysql restore failed: {err or out}")


def run_restore(target_id: str, dump_path: str, targets: list[DbTarget] | None = None) -> None:
    """Restore one target from a dump file. target_id e.g. 'orders-postgresql', 'catalog-mysql'."""
    targets = targets or DEFAULT_TARGETS
    t = next((x for x in targets if x.id == target_id), None)
    if not t:
        raise ValueError(f"Unknown target: {target_id}. Choose from: {[x.id for x in targets]}")
    if t.type == "postgresql":
        restore_postgres(t, dump_path)
    elif t.type == "mysql":
        restore_mysql(t, dump_path)
    else:
        raise ValueError(f"Unknown type: {t.type}")
    print(f"OK restored {target_id} from {dump_path}")
