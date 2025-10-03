#!/usr/bin/env bash
set -euo pipefail

invoke_local_policy () {
  echo "[Local Policy] Start"
  # Orchestrator only; add PAM/sysctl/auditd rules later.
  echo "[Local Policy] Done"
}
