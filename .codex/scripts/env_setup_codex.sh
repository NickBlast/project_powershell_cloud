#!/usr/bin/env bash
#
# project_powershell_cloud :: Environment bootstrap
# - Ensures PowerShell is installed
# - Trusts PSGallery
# - Runs scripts/ensure-prereqs.ps1 (if present)
# - Validates required PowerShell modules
# - Provides a simple progress bar and clear error reporting
#

set -Eeuo pipefail

#######################################
# Error handling
#######################################
on_error() {
  local exit_code=$1
  local line_no=$2

  echo
  echo "✖ Environment setup failed (exit code ${exit_code}) at line ${line_no}." >&2
  if [[ -n "${BASH_COMMAND:-}" ]]; then
    echo "  Last command: ${BASH_COMMAND}" >&2
  fi
  echo "  Check the log above for details." >&2
}

trap 'on_error $? $LINENO' ERR

#######################################
# Minimal logging + progress bar
#######################################
TOTAL_STEPS=6
CURRENT_STEP=0

log() {
  # single, simple log format
  printf '==> %s\n' "$*"
}

progress() {
  local msg=$1
  ((CURRENT_STEP++)) || true

  local bar_width=30
  local pct=$(( CURRENT_STEP * 100 / TOTAL_STEPS ))
  local filled=$(( bar_width * pct / 100 ))
  local empty=$(( bar_width - filled ))

  # build bar segments
  local bar_filled bar_empty
  bar_filled=$(printf '%*s' "${filled}" '' | tr ' ' '#')
  bar_empty=$(printf '%*s' "${empty}" '' | tr ' ' '-')

  printf '[%s%s] %3d%% - %s\n' "${bar_filled}" "${bar_empty}" "${pct}" "${msg}"
}

#######################################
# Helpers
#######################################
ensure_powershell() {
  if command -v pwsh >/dev/null 2>&1; then
    local ver
    ver=$(pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()')
    log "PowerShell found (pwsh ${ver})."
    progress "PowerShell ready"
    return 0
  fi

  log "PowerShell (pwsh) not found. Attempting installation..."

  local sudo_cmd=""
  if [[ "$(id -u)" -ne 0 ]]; then
    sudo_cmd="sudo"
  fi

  if command -v apt-get >/dev/null 2>&1; then
    # Debian/Ubuntu path (like your devcontainers)
    $sudo_cmd apt-get update -y
    $sudo_cmd apt-get install -y wget apt-transport-https software-properties-common gnupg
    local tmp_deb=/tmp/packages-microsoft-prod.deb
    wget -q -O "${tmp_deb}" "https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb"
    $sudo_cmd dpkg -i "${tmp_deb}"
    rm -f "${tmp_deb}"
    $sudo_cmd apt-get update -y
    $sudo_cmd apt-get install -y powershell
  else
    log "ERROR: Automatic PowerShell installation is only implemented for apt-based systems."
    log "       Please install PowerShell 7.4+ (pwsh) manually and re-run this script."
    exit 1
  fi

  if ! command -v pwsh >/dev/null 2>&1; then
    log "ERROR: PowerShell installation completed but pwsh is still not available in PATH."
    exit 1
  fi

  local ver
  ver=$(pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()')
  log "PowerShell installed (pwsh ${ver})."
  progress "PowerShell ready"
}

ensure_repo_root() {
  # Require running from repo root so paths stay simple and predictable
  if [[ -f "scripts/ensure-prereqs.ps1" ]]; then
    log "Detected scripts/ensure-prereqs.ps1 in current directory (repo root)."
    progress "Repository ready"
    return 0
  fi

  log "ERROR: scripts/ensure-prereqs.ps1 not found in current directory."
  log "       Run this script from the project_powershell_cloud repository root."
  exit 1
}

trust_psgallery() {
  log "Marking PSGallery as a trusted repository in PowerShell..."
  pwsh -NoProfile -Command '
    $ErrorActionPreference = "Stop"
    $VerbosePreference = "SilentlyContinue"

    # PSResourceGet (modern)
    if (Get-Command Get-PSResourceRepository -ErrorAction SilentlyContinue) {
      $repo = Get-PSResourceRepository -Name "PSGallery" -ErrorAction SilentlyContinue
      if (-not $repo) {
        Register-PSResourceRepository -Name "PSGallery" -PSGallery -Trusted
      }
      elseif (-not $repo.Trusted) {
        Set-PSResourceRepository -Name "PSGallery" -Trusted
      }
    }
    # Legacy PowerShellGet fallback
    elseif (Get-Command Get-PSRepository -ErrorAction SilentlyContinue) {
      $repo = Get-PSRepository -Name "PSGallery" -ErrorAction SilentlyContinue
      if (-not $repo) {
        Register-PSRepository -Name "PSGallery" `
          -SourceLocation "https://www.powershellgallery.com/api/v2" `
          -InstallationPolicy Trusted
      }
      elseif ($repo.InstallationPolicy -ne "Trusted") {
        Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
      }
    }
  '
  progress "PSGallery trusted"
}

run_ensure_prereqs_ps1() {
  if [[ ! -f "scripts/ensure-prereqs.ps1" ]]; then
    # Already checked in ensure_repo_root, but guard anyway.
    log "WARNING: scripts/ensure-prereqs.ps1 missing; skipping prereq script."
    progress "Skipped ensure-prereqs.ps1"
    return 0
  fi

  log "Running scripts/ensure-prereqs.ps1 (quiet VERBOSE)..."
  set +e
  pwsh -NoProfile -Command '
    $ErrorActionPreference = "Stop"
    $VerbosePreference = "SilentlyContinue"
    & "scripts/ensure-prereqs.ps1"
  '
  local exit_code=$?
  set -e

  if [[ "${exit_code}" -ne 0 ]]; then
    log "WARNING: scripts/ensure-prereqs.ps1 exited with code ${exit_code}."
    log "         Environment setup will continue; module validation will enforce readiness."
  fi

  progress "Module install step completed"
}

ensure_outputs_dir() {
  mkdir -p outputs
  progress "outputs/ directory ensured"
}

validate_modules() {
  local required_modules=(
    Az.Accounts
    Az.Resources
    Microsoft.Graph
    Microsoft.PowerShell.SecretManagement
    PSScriptAnalyzer
    Pester
    ImportExcel
  )

  log "Validating required PowerShell modules:"
  printf '   %s\n' "${required_modules[@]}"

  pwsh -NoProfile -Command '
    $ErrorActionPreference = "Stop"
    $VerbosePreference     = "SilentlyContinue"

    $modules = @(
      "Az.Accounts",
      "Az.Resources",
      "Microsoft.Graph",
      "Microsoft.PowerShell.SecretManagement",
      "PSScriptAnalyzer",
      "Pester",
      "ImportExcel"
    )

    foreach ($m in $modules) {
      if (-not (Get-Module -ListAvailable -Name $m)) {
        Write-Error "Required module ''$m'' is not installed or discoverable."
      }
    }

    Write-Information "All required modules are available."
  '

  progress "Module validation passed"
}

#######################################
# Main
#######################################
main() {
  printf '===========================================\n'
  printf ' project_powershell_cloud :: env-setup\n'
  printf '===========================================\n'

  ensure_powershell
  ensure_repo_root
  trust_psgallery
  run_ensure_prereqs_ps1
  ensure_outputs_dir
  validate_modules

  printf '%s\n' "-------------------------------------------"
  printf '%s\n' "✔ Environment setup completed successfully."
  printf '%s\n' "   Next steps: see ./README.md and ./ai_agent_setup.md"
  printf '%s\n' "-------------------------------------------"
}

main "$@"
