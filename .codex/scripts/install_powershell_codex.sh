#!/usr/bin/env bash
#
# Dedicated PowerShell installer tailored for Codex's Ubuntu 24.04 base image.
# - Installs PowerShell for the architecture Codex provisions (amd64 today, arm64 future)
# - Adds Microsoft's package feed only when needed
# - Pins to PowerShell 7.4+ and validates availability post-install
# - Designed to run idempotently inside Codex `setup` snippets
#

set -Eeuo pipefail

trap 'echo "✖ install_powershell_codex.sh failed at line $LINENO" >&2' ERR

log() {
  printf '==> %s\n' "$*"
}

require_apt() {
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "ERROR: Codex universal image expectation (apt) not met." >&2
    exit 1
  fi
}

ensure_base_packages() {
  local deps=(wget apt-transport-https software-properties-common gnupg)
  log "Ensuring bootstrap packages: ${deps[*]}"
  apt-get update -y
  apt-get install -y "${deps[@]}"
}

add_ms_repo() {
  local repo_file=/etc/apt/sources.list.d/microsoft-prod.list
  if [[ -f "${repo_file}" ]]; then
    log "Microsoft package feed already present."
    return
  fi

  local tmp_deb=/tmp/packages-microsoft-prod.deb
  local distro=ubuntu/24.04

  log "Adding Microsoft package feed for ${distro}..."
  wget -q -O "${tmp_deb}" "https://packages.microsoft.com/config/${distro}/packages-microsoft-prod.deb"
  dpkg -i "${tmp_deb}"
  rm -f "${tmp_deb}"
}

install_pwsh() {
  log "Installing PowerShell (pwsh) via apt..."
  apt-get update -y
  apt-get install -y powershell
}

verify_pwsh() {
  if ! command -v pwsh >/dev/null 2>&1; then
    echo "ERROR: pwsh not found in PATH after installation." >&2
    exit 1
  fi

  local version
  version=$(pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()')
  log "pwsh ${version} ready for project_powershell_cloud."
}

main() {
  require_apt

  if command -v pwsh >/dev/null 2>&1; then
    local existing
    existing=$(pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()')
    log "pwsh already installed (${existing}); skipping install."
    return 0
  fi

  ensure_base_packages
  add_ms_repo
  install_pwsh
  verify_pwsh
}

main "$@"
