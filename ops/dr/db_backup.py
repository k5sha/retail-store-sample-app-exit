"""
Backup stateful databases (PostgreSQL, MySQL) via kubectl exec.
Writes timestamped dump files under DR_BACKUP_DIR.
"""
import base64
import os
import subprocess
import sys
from datetime import datetime

from .config import BACKUP_DIR, DEFAULT_TARGETS, DbTarget, get_backup_dir


def _run(cmd: list[str], capture: bool = True) -> tuple[int, str]:
    try:
        r = subprocess.run(
            cmd,
            capture_output=capture,
            text=True,
            timeout=300,
        )
        out = (r.stdout or "") + (r.stderr or "")
        return r.returncode, out
    except subprocess.TimeoutExpired:
        return -1, "Command timed out"
    except FileNotFoundError:
        return -1, "kubectl not found"


def _get_secret_value(namespace: str, secret_name: str, key: str) -> str:
    code, out = _run([
        "kubectl", "get", "secret", secret_name,
        "-n", namespace,
        "-o", f"jsonpath={{.data.{key}}}",
    ])
    if code != 0:
        raise RuntimeError(f"Failed to get secret {secret_name}/{key}: {out}")
    return base64.b64decode(out.strip()).decode("utf-8", errors="replace")


def _get_pod_name(namespace: str, service_name: str) -> str:
    # StatefulSet pod is typically {service_name}-0
    code, _ = _run(["kubectl", "get", "pod", f"{service_name}-0", "-n", namespace])
    if code == 0:
        return f"{service_name}-0"
    code2, out = _run([
        "kubectl", "get", "pods", "-n", namespace,
        "-o", "jsonpath={.items[0].metadata.name}",
    ])
    if code2 == 0 and out.strip():
        return out.strip()
    raise RuntimeError(f"Pod not found for {service_name} in {namespace}. Is the StatefulSet running?")


def backup_postgres_stream(target: DbTarget, out_path: str) -> None:
    """Run pg_dump inside pod and stream stdout to file via kubectl exec."""
    user = _get_secret_value(target.namespace, target.secret_name, target.user_key)
    password = _get_secret_value(target.namespace, target.secret_name, target.password_key)
    pod = _get_pod_name(target.namespace, target.service_name)
    container = target.container or "postgresql"
    with open(out_path, "w", encoding="utf-8") as f:
        p = subprocess.Popen(
            ["kubectl", "exec", "-n", target.namespace, pod, "-c", container, "--",
             "env", f"PGPASSWORD={password}", "pg_dump", "-U", user, "-d", target.database, "--no-owner", "--no-acl"],
            stdout=f,
            stderr=subprocess.PIPE,
            text=True,
        )
        _, err = p.communicate(timeout=300)
        if p.returncode != 0:
            raise RuntimeError(f"pg_dump failed: {err}")


def backup_mysql_stream(target: DbTarget, out_path: str) -> None:
    """Run mysqldump inside pod and stream stdout to file."""
    user = _get_secret_value(target.namespace, target.secret_name, target.user_key)
    password = _get_secret_value(target.namespace, target.secret_name, target.password_key)
    pod = _get_pod_name(target.namespace, target.service_name)
    container = target.container or "mysql"
    with open(out_path, "w", encoding="utf-8") as f:
        p = subprocess.Popen(
            ["kubectl", "exec", "-n", target.namespace, pod, "-c", container, "--",
             "mysqldump", "-u", user, f"--password={password}", "--single-transaction", "--routines", target.database],
            stdout=f,
            stderr=subprocess.PIPE,
            text=True,
        )
        _, err = p.communicate(timeout=300)
        if p.returncode != 0:
            raise RuntimeError(f"mysqldump failed: {err}")


def run_backup(targets: list[DbTarget] | None = None) -> list[str]:
    """Run backup for all (or given) targets. Returns list of created backup file paths."""
    targets = targets or DEFAULT_TARGETS
    base = get_backup_dir()
    ts = datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
    created = []
    for t in targets:
        subdir = os.path.join(base, t.id)
        os.makedirs(subdir, exist_ok=True)
        out_path = os.path.join(subdir, f"dump_{ts}.sql")
        try:
            if t.type == "postgresql":
                backup_postgres_stream(t, out_path)
            elif t.type == "mysql":
                backup_mysql_stream(t, out_path)
            else:
                raise ValueError(f"Unknown type: {t.type}")
            created.append(out_path)
            print(f"OK backup {t.id} -> {out_path}")
        except Exception as e:
            print(f"FAIL {t.id}: {e}", file=sys.stderr)
            raise
    return created
