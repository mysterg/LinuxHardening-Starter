#!/usr/bin/env bash
# 01-document_system.sh
# Collects baseline system information for later comparison.
# Designed to be *sourced* by a menu script (e.g., harden.sh).
# Strict mode is enabled only when executed directly.

# Enable strict mode only when run directly, not when sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
fi

invoke_document_system() {
  echo "Running Documenting System..."

  # Resolve output directory (caller can export DOCS; else default)
  local outdir
  outdir="${DOCS:-/root/system-docs}"
  mkdir -p "$outdir" || true

  # 1) Users and admin groups
  cut -d: -f1 /etc/passwd > "$outdir/users.txt" 2>/dev/null || true
  { getent group sudo 2>/dev/null || true; getent group wheel 2>/dev/null || true; } > "$outdir/admin_groups.txt"

  # 2) Package inventories (Debian/Ubuntu, RPM, Snap, Flatpak)
  if command -v dpkg >/dev/null 2>&1;   then dpkg -l   > "$outdir/packages_dpkg.txt"   2>/dev/null || true; fi
  if command -v rpm  >/dev/null 2>&1;   then rpm -qa    > "$outdir/packages_rpm.txt"    2>/dev/null || true; fi
  if command -v snap >/dev/null 2>&1;   then snap list  > "$outdir/snap.txt"            2>/dev/null || true; fi
  if command -v flatpak >/dev/null 2>&1;then flatpak list > "$outdir/flatpak.txt"       2>/dev/null || true; fi

  # 3) Listening sockets and associated processes
  if command -v ss >/dev/null 2>&1; then
    ss -plnt > "$outdir/ss_plnt.txt" 2>/dev/null || true

    # Extract unique process names from users:(("proc","pid=..."))
    awk 'NR>1{print $0}' "$outdir/ss_plnt.txt" 2>/dev/null \
      | grep -oE 'users:\(\(.*\)\)' 2>/dev/null \
      | sed 's/users:(('//;s/))//' 2>/dev/null \
      | tr ',' '\n' \
      | sed -E 's/.*"([^"]+)".*/\1/' \
      | sort -u > "$outdir/listening_services.txt" 2>/dev/null || true

    # Pre-malware detail: for each listening PID, capture exe/cmdline
    : > "$outdir/premalware.txt"
    grep -oE 'pid=[0-9]+' "$outdir/ss_plnt.txt" 2>/dev/null \
      | cut -d= -f2 \
      | sort -u \
      | while read -r pid; do
          [[ -n "$pid" ]] || continue
          exe=$(readlink -f "/proc/$pid/exe" 2>/dev/null || true)
          cmdline=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null || true)
          comm=$(cat "/proc/$pid/comm" 2>/dev/null || true)
          {
            echo "PID: $pid"
            echo "  Command: $comm"
            echo "  Executable: $exe"
            echo "  Cmdline: $cmdline"
            echo
          } >> "$outdir/premalware.txt"
        done
  fi

  # 4) Cron documentation (user and system)
  : > "$outdir/cron.txt"
  cut -f1 -d: /etc/passwd | while read -r u; do
    {
      echo "Cron jobs for user: $u"
      crontab -u "$u" -l 2>/dev/null || true
      echo
    } >> "$outdir/cron.txt"
  done
  {
    echo "=== /etc/crontab ==="
    cat /etc/crontab 2>/dev/null || true
    echo
    echo "=== /etc/cron.d/* ==="
    cat /etc/cron.d/* 2>/dev/null || true
  } >> "$outdir/cron.txt"

  # 5) Compare current packages to a VANILLA baseline, if provided
  # Expect caller to set:
  #   CURDPKG  -> whitespace-separated list of current packages
  #   VANILLA  -> baseline list/concatenation to compare against
  if [[ -n "${CURDPKG:-}" && -n "${VANILLA:-}" ]]; then
    : > "$outdir/suspackages.txt"
    for I in ${CURDPKG:-}; do
      if [[ "${VANILLA:-}" != *"$I"* ]]; then
        echo "$I" >> "$outdir/suspackages.txt"
      fi
    done
  fi

  echo "Documentation written to: $outdir"
  return 0
}

# If executed directly, run the function immediately.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  invoke_document_system
fi
