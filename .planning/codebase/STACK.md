# Technology Stack

**Analysis Date:** 2026-06-04

## Languages

**Primary:**
- Bash 4+ - Shell scripts for module installation, auditing, and automation (`_internal/vibeflow-update.sh`, `consolidator/scripts/`, `infrastructure-audit/scripts/`, `software-architecture/scripts/`)
- Python 3.8+ - Evaluation loops, skill generation, and processing utilities (`skill-creator/skills/skill-creator/scripts/`, reference templates)

**Secondary:**
- Markdown - Core documentation and specification format (all `*.md` files including SKILL.md, AGENT.md, SKILL.md)

## Runtime

**Environment:**
- Bash 4+ (macOS/Linux)
- Python 3.8+
- Claude Code CLI (`claude` command available in PATH)

**Package Manager:**
- None - Zero external package dependencies
- Lockfile: Not applicable

## Frameworks

**Core:**
- Claude Code (Anthropic's agent framework) - Primary runtime for all skills and agents
- VibeFlow Methodology - Process framework for AI-assisted software delivery

**Automation:**
- Shell scripting (`bash`, `awk`, `grep`, `sed`) - Module installation, auditing, consolidation
- subprocess (Python) - Claude Code invocation from Python scripts

**Build/Dev:**
- None detected

## Key Dependencies

**Runtime Requirements:**
- `git` - Repository management for vibeflow-update.sh cache operations (`_internal/vibeflow-update.sh`)
- `python3` - For skill-creator evaluation loops and template processing
- `bash 4+` - Script portability across macOS and Linux
- Standard Unix utilities: `awk`, `grep`, `sed`, `jq`, `date` - Text processing and auditing

**Module-Specific:**
- None external (all dependencies are standard Unix tools or Claude Code internal)

## Configuration

**Environment:**
- No `.env` files or environment variable configuration required for core operation
- Optional environment variables for audit gates:
  - `VF_ARCH_WARN` (default 250) - File size warning threshold
  - `VF_ARCH_BLOCK` (default 300) - File size blocking threshold
  - `VIBEFLOW_CACHE` (default `.vibeflow-cache`) - Cache directory location
  - `MEMORY_DIR` (default `.claude/memory`) - Lab memory directory
  - `CLAUDE_DIR` (default `.claude`) - Claude Code configuration directory

**Build:**
- No build system
- No compilation required
- Installation via `vibeflow-update.sh` script

## Platform Requirements

**Development:**
- Bash 4+ (macOS/Linux only)
- Python 3.8+
- `gh` CLI (optional, for GitHub authentication if cloning privately)
- Git 2.0+
- Standard POSIX utilities (`date`, `stat`, `wc`, `head`, `tail`, `grep`, `sed`, `awk`)

**Production:**
- Not applicable - this is a module distribution repository, not a deployed application
- Deployed into Claude Code labs as skills and agents
- Target: Lab VibeFlow and downstream labs using vibeflow-update.sh

## Module Distribution

**Module Types Supported (v2.0.0+):**
- **single-skill**: SKILL.md + optional references/, scripts/
- **multi-skills**: skills/<name>/SKILL.md (multiple)
- **agent-only**: AGENT.md + optional sub-skills
- **doc-only**: content/ directory structure
- **rules**: rules/*.md (path-scoped)
- **Composable**: skill + rules + scripts together

**Versioning:**
- Semantic versioning per module (MAJOR.MINOR.PATCH)
- MAJOR: breaking changes (convention, format, structure)
- MINOR: new modules or major capabilities
- PATCH: bugfixes, documentation improvements

---

*Stack analysis: 2026-06-04*
