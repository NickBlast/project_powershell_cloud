# PowerShell IAM Inventory Tool

A PowerShell-only tool for extracting IAM-relevant inventory from AWS, Azure/Entra ID, and GCP cloud platforms. This repository provides deterministic, idempotent exports suitable for audit evidence, access decision support, and compliance reporting.

## 🎯 Purpose

This tool extracts identity and access management (IAM) data from major cloud platforms to support:
- **Audit evidence** (who has what, where, and why)
- **Access decision support** (access ↔ resources/services mapping)
- **Risk & posture improvements** aligned to security frameworks

## ✨ Key Features

- **PowerShell 7.4+** only (cross-platform compatible)
- **Multi-cloud support**: Azure/Entra ID, AWS, and GCP
- **Deterministic & Idempotent**: Re-running exports safely overwrites same-version outputs
- **Dual-format outputs**: CSV + JSON with schema validation
- **Bank-grade security**: AllSigned in CI, RemoteSigned in dev, SecretManagement for credentials
- **Compliance mapping**: NIST SP 800-53, CSA CCM, FFIEC CAT, and cloud Well-Architected guidance
- **Evidence-first design**: Traceable, timestamped, schema-validated outputs

## 📁 Repository Structure

```
├── /docs
│   ├── /schemas                # JSON schema manifests for each dataset
│   ├── /compliance             # Control mappings and evidence index
│   └── repo_contract.md        # Deterministic rules for tools & outputs
├── /modules
│   ├── /logging                # Structured logging + redaction
│   ├── /export                 # CSV/JSON/XLSX writers with schema validation
│   └── /connect                # Auth/context handling for clouds
├── /scripts
│   ├── ensure-prereqs.ps1      # Idempotent environment bootstrap
│   └── export-*.ps1            # Top-level entrypoints by dataset
├── /tests                      # Pester contract tests
├── /examples                   # Sample outputs and synthetic data
├── /.config
│   └── tenants.json            # Non-secret tenant descriptors
└── /ai
    └── contributing_ai.md      # Guardrails for AI/agents
```

## 🚀 Getting Started

### Prerequisites

- **PowerShell 7.4+** (cross-platform)
- Internet connectivity for module downloads

### Installation

1. Clone the repository
2. Run the prerequisites script:
   ```powershell
   pwsh -NoProfile -File scripts/ensure-prereqs.ps1
   ```

This script will:
- Verify PowerShell 7.4+ is installed
- Ensure PSResourceGet is available
- Install/upgrade required modules to CurrentUser scope
- Run PSScriptAnalyzer over the repository
- Generate a prerequisites report

### Required Modules

The tool uses these PowerShell modules:
- **Microsoft.Graph** (select submodules only)
- **Az.Accounts**, **Az.Resources** (select submodules only)
- **ImportExcel** (for Excel exports)
- **PSScriptAnalyzer**, **Pester** (quality gates)
- **Microsoft.PowerShell.SecretManagement** (credential abstraction)

## 📊 Supported Datasets

### Azure/Entra ID
- **Azure scopes hierarchy**: Management Groups, Subscriptions, Resource Groups
- **Azure RBAC**: Role definitions and assignments across all scopes
- **Entra directory roles**: Built-in tenant admin roles and assignments
- **Applications & Service Principals**: App registrations, API permissions, consents
- **Groups**: Cloud-only groups and membership listings

### AWS (Planned)
- Accounts, roles, policies, and trust relationships

### GCP (Planned)
- Projects, IAM bindings, and role assignments

## 🔧 Usage Examples

### Environment Setup
```powershell
# Install prerequisites
pwsh -NoProfile -File scripts/ensure-prereqs.ps1
```

### Running Exports
```powershell
# Export Azure RBAC assignments (example)
./scripts/export-azure_rbac_assignments.ps1 -OutputPath ./exports
```

### Authentication
The tool supports:
- **Device code flow** for interactive authentication
- **Service principal** for automated scenarios (preferred for automation)
- All authentication uses **read-only** scopes/roles

## 🔒 Security & Compliance

### Code Signing
- **CI/CD**: `AllSigned` policy enforced
- **Development**: `RemoteSigned` policy
- Only signed artifacts may be published

### Secret Management
- **No secrets on disk**: Uses SecretManagement vaults
- **Redaction**: Emails, secrets, tokens, and tenant-sensitive fields are redacted in logs
- **Least privilege**: Documented exact roles/permissions per dataset

### Evidence Requirements
All outputs include:
- `generated_at`: UTC ISO 8601 timestamp
- `tool_version`: Semantic version of this tool
- `dataset_version`: Schema version for the dataset
- Schema-validated columns and data types

## 🛠️ Development Guidelines

### Naming Conventions
- **Directories**: `lower_case_with_underscores`
- **PowerShell scripts**: `Verb-Noun` with underscores in Noun (e.g., `Export-Role_Assignments.ps1`)

### Quality Gates
- **PSScriptAnalyzer**: Must be clean (warnings fail CI)
- **Pester tests**: Contract-level testing required
- **Schema validation**: All exports validated against JSON schemas

### Branching & Commits
- **Branches**: `feat/<area>__<short>`, `fix/<area>__<short>`, `docs/<area>__<short>`
- **Commits**: Conventional Commits style, one concern per commit

## 🤝 Contributing

Before contributing, please read:
1. `docs/repo_contract.md` - Repository rules and constraints
2. `docs/repo_design/powershell_repo_design.md` - Design principles and structure
3. `ai/contributing_ai.md` - AI/agent guardrails

### AI/Agent Development
Agents must:
- Read all documentation before making changes
- Propose a short plan before implementation
- Not introduce external CLIs or unapproved modules
- Not weaken logging/redaction or bypass schema validation

## 📜 License

See [LICENSE](LICENSE) file for details.

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md) for release history.
