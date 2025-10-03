# Global config (keep minimal; students can extend later)

# Where to write docs/artifacts if needed later
DOC_OUTPUT_DIR="${DOC_OUTPUT_DIR:-/var/tmp/linux-hardening-docs}"

# Package manager hint (not used yet; helpful for later tasks)
if command -v apt-get >/dev/null 2>&1; then
  PKG_MGR="apt"
elif command -v dnf >/dev/null 2>&1; then
  PKG_MGR="dnf"
elif command -v yum >/dev/null 2>&1; then
  PKG_MGR="yum"
elif command -v zypper >/dev/null 2>&1; then
  PKG_MGR="zypper"
else
  PKG_MGR="unknown"
fi
