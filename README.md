![Context Engineering Kit](./media/logo_small.webp)

# 🧭 Context Engineering Kit

*Context-first workflows for AI-assisted delivery.*

[![Release](https://github.com/Calel33/CE-spec-kit/actions/workflows/release.yml/badge.svg)](https://github.com/Calel33/CE-spec-kit/actions/workflows/release.yml)

---

## Table of Contents

- [Why Context Engineering?](#why-context-engineering)
- [Supported Workflows](#supported-workflows)
- [Install the CLI](#install-the-cli)
- [Initialize a Project](#initialize-a-project)
- [Slash Command Reference](#slash-command-reference)
- [Directory Layout](#directory-layout)
- [Automation & Scripts](#automation--scripts)
- [Multi-Agent Support](#multi-agent-support)
- [Release Packaging](#release-packaging)
- [Changelog & License](#changelog--license)

## Why Context Engineering?

Traditional Spec-Driven Development stops once the specification exists. Context Engineering keeps context alive throughout delivery so AI assistants can make informed decisions at every step. The Context Engineering Kit (CEK) gives you:

- A unified CLI (specify) that provisions workflows and directories under .context-eng/.
- Templated slash commands that keep specification, research, planning, and execution artifacts in sync.
- Automation scripts (Bash + PowerShell) that adapt to the active workflow and selected AI agent.
- Release tooling that publishes ready-to-use templates for every supported assistant.

## Supported Workflows

| Workflow | Command Path | Primary Artifact | When to Use |
|----------|--------------|------------------|-------------|
| **Free-Style Context Engineering** | /specify → /research → /create-plan → /implement | specs/NNN-feature/context-spec.md | Exploratory or greenfield features needing progressive context gathering. |
| **PRP (Product Requirement Prompts)** | /specify → /generate-prp → /execute-prp → /implement | PRPs/INITIAL.md + PRPs/NNN-feature.md | When stakeholders hand off formal requirement prompts that drive execution. |
| **All-in-One Context Engineering** | /specify → /context-engineer | context-eng/all-in-one/NNN-feature/record.md | Rapid iterations where research, planning, and execution live in a single artifact. |

Switch workflows at init time with --workflow and the CLI will scaffold directories, templates, and metadata automatically.

## Install the CLI

The CLI is published as specify-cli. Use [uv](https://github.com/astral-sh/uv) for fastest results:

```bash
uv tool install specify-cli --from git+https://github.com/Calel33/CE-spec-kit.git
# or run once without installing
uvx --from git+https://github.com/Calel33/CE-spec-kit.git specify -- --help
```

Verify installation:

```bash
specify --help
specify check
```

## Initialize a Project

Provision a brand-new project or retrofit an existing directory:

```bash
# Create a new PRP-focused project
specify init context-kit-demo --workflow prp --ai claude

# Initialize in the current folder, merging files when necessary
specify init . --workflow free-style --ai copilot --force
```

During init you will choose:

1. **Workflow** – free-style, prp, or all-in-one.
2. **AI assistant** – Claude, Gemini, Copilot, Cursor, Qwen, opencode, Codex, Windsurf, Kilocode, Auggie, or Roo.
3. **Script flavor** – POSIX (sh) or PowerShell (ps).

The CLI writes .context-eng/workflow.json with the selected workflow, assistant, and script type, and ensures workflow-specific directories (specs, PRPs, context-eng/all-in-one) exist.

## Slash Command Reference

| Command | Workflow(s) | Purpose |
|---------|-------------|---------|
| /specify | All | Bootstrap the workflow, populate the primary artifact using the correct template, and recommend next steps. |
| /research | Free-Style, PRP | Capture signals, links, and risks in 
research.md. |
| /create-plan | Free-Style | Generate a cross-layer implementation plan (plan.md) with full checklist coverage. |
| /generate-prp | PRP | Transform INITIAL briefs into per-feature PRPs using .context-eng/workflows/prp/templates/prp-template.md. |
| /execute-prp | PRP | Convert the PRP into actionable tasks and plan updates. |
| /context-engineer | All-in-One | Drive discovery, planning, execution, and validation inside the all-in-one record. |
| /implement | All | Execute tasks while keeping plan/PRP notes synchronized and reporting validation evidence. |
| /clarify, /analyze, /tasks | All (optional) | Targeted clarifications, cross-artifact analysis, and task generation. |

Slash command prompts call workflow-aware helper scripts:

- `scripts/bash/context-feature-info.sh` / `scripts/powershell/context-feature-info.ps1`
- `scripts/bash/context-plan-setup.sh` / `scripts/powershell/context-plan-setup.ps1`

These scripts:
- Read `.context-eng/workflow.json` to determine the active workflow
- Set `CONTEXT_FEATURE=<NNN-slug>` environment variable
- Emit standardized JSON describing active artifacts (`PRIMARY_FILE`, `PLAN_FILE`, `PRP_FILE`, `TASKS_FILE`)
- Support both `.context-eng/` (new) and `.specify/` (legacy) directory structures

## Directory Layout

The Context Engineering Kit uses a dual directory structure:

- **`.context-eng/`** – Configuration, templates, scripts, and workflow metadata (hidden directory)
- **`context-eng/`** – Workspace for execution artifacts like plans and records (visible directory)

```
<project>/
├── .context-eng/                    # Configuration & templates (hidden)
│   ├── workflow.json                # Active workflow selection
│   ├── checklists/
│   │   └── full-implementation-checklist.md
│   ├── workflows/                   # Workflow-specific templates
│   │   ├── free-style/
│   │   ├── prp/
│   │   └── all-in-one/
│   └── scripts/                     # Helper automation scripts
│       ├── context-feature-info.sh  # (also .ps1)
│       ├── context-plan-setup.sh    # (also .ps1)
│       └── update-agent-context.sh  # (also .ps1)
├── specs/                           # Context specifications (free-style)
│   └── 001-example/
│       └── context-spec.md
├── PRPs/                            # Product Requirement Prompts (PRP workflow)
│   ├── INITIAL.md
│   └── 002-example.md
└── context-eng/                     # Execution workspace (visible)
    ├── prp/
    │   └── 002-example/
    │       ├── plan.md
    │       ├── research.md
    │       └── tasks.md
    └── all-in-one/
        └── 003-example/
            └── record.md
```

**Note**: Legacy projects may still use `.specify/` instead of `.context-eng/` for configuration. The CLI supports both for backwards compatibility.

All helper scripts write absolute paths and set `CONTEXT_FEATURE=<NNN-slug>` for downstream commands.

## Automation & Scripts

- `scripts/bash/common.sh` / `scripts/powershell/common.ps1` expose cross-platform helpers to read workflow metadata and compute artifact paths.
- `scripts/bash/create-new-feature.sh` and its PowerShell twin set up branches, copy workflow templates, and emit JSON used by `/specify`.
- `scripts/bash/check-prerequisites.sh` and `scripts/powershell/check-prerequisites.ps1` validate that required artifacts exist (primary file, plan, tasks) before running commands like `/implement` or `/analyze`.
- Agent context updaters now source `.context-eng/templates/agent-file-template.md` and work across all assistants.

## Multi-Agent Support

The Context Engineering Kit supports multiple AI coding assistants:

| Agent | Key | Directory | CLI Tool | Type |
|-------|-----|-----------|----------|------|
| GitHub Copilot | `copilot` | `.github/prompts/` | N/A | IDE-based |
| Claude Code | `claude` | `.claude/commands/` | `claude` | CLI |
| Gemini CLI | `gemini` | `.gemini/commands/` | `gemini` | CLI |
| Cursor | `cursor` | `.cursor/commands/` | `cursor-agent` | IDE-based |
| Qwen Code | `qwen` | `.qwen/commands/` | `qwen` | CLI |
| opencode | `opencode` | `.opencode/command/` | `opencode` | CLI |
| Codex CLI | `codex` | `.codex/prompts/` | `codex` | CLI |
| Windsurf | `windsurf` | `.windsurf/workflows/` | N/A | IDE-based |
| Kilo Code | `kilocode` | `.kilocode/commands/` | `kilocode` | CLI |
| Auggie CLI | `auggie` | `.augment/commands/` | `auggie` | CLI |
| Roo Code | `roo` | `.roo/commands/` | `roo` | CLI |

Slash commands reference `.context-eng/scripts/` (new) with backwards compatibility for `.specify/scripts/` (legacy). The packaging pipeline rewrites script paths automatically per agent and script flavor.

## Release Packaging

`.github/workflows/scripts/create-release-packages.sh` builds release artifacts named:

```
.genreleases/ce-kit-template-<agent>-<sh|ps>-vX.Y.Z.zip
```

Each archive contains:

- `.context-eng/` templates, checklists, scripts, and workflow metadata
- Agent-specific prompts/commands generated from `templates/commands/*.md`
- Optional helper files (e.g., GEMINI.md, QWEN.md) when agents require them

`create-github-release.sh` uploads these packages via `gh release create`.

**Backwards Compatibility**: The CLI will fall back to legacy `spec-kit-template-*` archives if `ce-kit-template-*` packages are not found in the release.

## Changelog & License

- Version history lives in [CHANGELOG.md](./CHANGELOG.md). Current release: **0.0.18**.
- Licensed under the [MIT License](./LICENSE).

