#!/usr/bin/env bash
# Run backup of stateful DBs (PostgreSQL, MySQL) then run deploy.
# Use this before every deploy to satisfy "backup before each deploy" requirement.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

echo "=== Step 1: Backup stateful databases ==="
export PYTHONPATH="${REPO_ROOT}:${PYTHONPATH:-}"
python -m ops.dr backup
echo ""

echo "=== Step 2: Deploy ==="
if [ -n "${DEPLOY_CMD:-}" ]; then
  eval "$DEPLOY_CMD"
elif command -v argocd &>/dev/null; then
  echo "Syncing Argo CD applications (set DEPLOY_CMD to override)..."
  for app in retail-store-orders retail-store-catalog; do
    if argocd app get "$app" &>/dev/null; then
      argocd app sync "$app" --async || true
    fi
  done
  echo "Done. Check Argo CD UI for sync status."
else
  echo "Run your deploy manually (e.g. helmfile apply, or argocd app sync)."
  echo "Or set DEPLOY_CMD='your deploy command' before running this script."
fi
