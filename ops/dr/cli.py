"""
CLI for disaster recovery: backup and restore stateful DBs (PostgreSQL, MySQL).
Usage:
  python -m ops.dr backup              # backup all targets
  python -m ops.dr backup --target orders-postgresql
  python -m ops.dr restore --target orders-postgresql --file ops/backups/orders-postgresql/dump_20250314T120000Z.sql
  python -m ops.dr list-backups        # list existing backups
"""
import argparse
import os
import sys

# Allow running as script from repo root: python -m ops.dr
if __name__ == "__main__" and __package__ is None:
    __package__ = "ops.dr"

from .config import DEFAULT_TARGETS, get_backup_dir
from .db_backup import run_backup
from .db_restore import run_restore


def cmd_backup(args: argparse.Namespace) -> int:
    targets = [t for t in DEFAULT_TARGETS if t.id == args.target] if args.target else DEFAULT_TARGETS
    try:
        paths = run_backup(targets=targets)
        print(f"Backed up {len(paths)} target(s)")
        return 0
    except Exception as e:
        print(f"Backup failed: {e}", file=sys.stderr)
        return 1


def cmd_restore(args: argparse.Namespace) -> int:
    if not args.file or not os.path.isfile(args.file):
        print(f"File not found: {args.file}", file=sys.stderr)
        return 1
    if not args.target:
        print("--target is required for restore (e.g. orders-postgresql, catalog-mysql)", file=sys.stderr)
        return 1
    try:
        run_restore(target_id=args.target, dump_path=args.file)
        return 0
    except Exception as e:
        print(f"Restore failed: {e}", file=sys.stderr)
        return 1


def cmd_list_backups(args: argparse.Namespace) -> int:
    base = get_backup_dir()
    if not os.path.isdir(base):
        print(f"No backup dir yet: {base}")
        return 0
    for target_id in [t.id for t in DEFAULT_TARGETS]:
        subdir = os.path.join(base, target_id)
        if not os.path.isdir(subdir):
            continue
        files = sorted(os.listdir(subdir))
        for f in files:
            if f.endswith(".sql"):
                print(os.path.join(subdir, f))
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description="Disaster recovery: backup and restore stateful DBs")
    sub = ap.add_subparsers(dest="cmd", required=True)
    # backup
    p_backup = sub.add_parser("backup", help="Backup stateful databases (run before deploy)")
    p_backup.add_argument("--target", choices=[t.id for t in DEFAULT_TARGETS], help="Backup only this target")
    p_backup.set_defaults(func=cmd_backup)
    # restore
    p_restore = sub.add_parser("restore", help="Restore from a backup file")
    p_restore.add_argument("--target", choices=[t.id for t in DEFAULT_TARGETS], required=True)
    p_restore.add_argument("--file", "-f", required=True, help="Path to dump .sql file")
    p_restore.set_defaults(func=cmd_restore)
    # list-backups
    p_list = sub.add_parser("list-backups", help="List existing backup files")
    p_list.set_defaults(func=cmd_list_backups)
    # parse and run
    args = ap.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
