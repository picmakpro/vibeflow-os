#!/usr/bin/env python3
"""
plan_migration.py — Genere un plan de migration pour un agent depassant les seuils ADR-029.

Usage:
    python3 plan_migration.py <path-to-agent.md>

Output: plan d'extraction markdown sur stdout. Distingue 3 categories :
  - GARDER : sections constitutives de l'identite de l'agent
  - EXTRAIRE : sections statiques vers _reference/<agent>-knowledge.md
  - TRANSFORMER : procedures reutilisables vers nouveau skill on-demand

Heuristiques :
  - Headings markdown (# / ## / ###) decoupent les sections
  - Sections "Checklist", "Exemple", "Reference", "How-to" → EXTRAIRE
  - Sections "Procedure", "Workflow detaille" ≥50L → TRANSFORMER (skill on-demand)
  - Sections "Mandat", "Iron Laws", "Perimetre", "Escalation" → GARDER
  - Code blocks longs (>30L) → EXTRAIRE
"""

from __future__ import annotations

import os
import re
import sys
from dataclasses import dataclass, field

# Seuils ADR-029
THRESHOLD_AGENT_LINES = 250
SECTION_SKILL_THRESHOLD = 50  # lignes mini pour suggerer skill on-demand
SECTION_BIG_THRESHOLD = 100   # lignes au-dela : extraction quasi obligatoire

KEEP_KEYWORDS = (
    "mandat", "perimetre", "périmètre", "iron law", "iron-law",
    "escalation", "escalade", "mission", "role", "rôle",
)
EXTRACT_KEYWORDS = (
    "checklist", "exemple", "example", "reference", "référence",
    "annexe", "appendix", "tableau", "matrix", "matrice",
    "cost", "cout", "coût", "quota", "anti-pattern",
)
SKILL_KEYWORDS = (
    "procedure", "procédure", "workflow detaille", "workflow détaillé",
    "how-to", "how to", "guide", "pipeline", "playbook", "runbook",
)


@dataclass
class Section:
    title: str
    level: int  # 1=#, 2=##, 3=###
    start_line: int
    end_line: int = 0
    content: list[str] = field(default_factory=list)

    @property
    def line_count(self) -> int:
        return self.end_line - self.start_line

    @property
    def title_lower(self) -> str:
        return self.title.lower()

    def classify(self) -> str:
        t = self.title_lower
        # GARDER : sections constitutives
        if any(k in t for k in KEEP_KEYWORDS):
            return "KEEP"
        # TRANSFORMER : procedure reutilisable assez longue
        if any(k in t for k in SKILL_KEYWORDS) and self.line_count >= SECTION_SKILL_THRESHOLD:
            return "TRANSFORM"
        # EXTRAIRE : contenu statique
        if any(k in t for k in EXTRACT_KEYWORDS):
            return "EXTRACT"
        # Heuristique taille : section > 100L probablement a extraire
        if self.line_count >= SECTION_BIG_THRESHOLD:
            return "EXTRACT"
        # Par defaut : garder (probablement workflow / contextuel)
        return "KEEP"

    def reason(self, kind: str) -> str:
        if kind == "KEEP":
            return f"Section constitutive de l'agent ({self.line_count} L)"
        if kind == "TRANSFORM":
            return f"Procedure reutilisable ≥{SECTION_SKILL_THRESHOLD}L — candidate skill on-demand"
        if kind == "EXTRACT":
            if self.line_count >= SECTION_BIG_THRESHOLD:
                return f"Section longue ({self.line_count}L) — extraction vers _reference/ recommandee"
            return f"Contenu statique de reference ({self.line_count}L)"
        return ""


def parse_sections(lines: list[str]) -> list[Section]:
    """Parse markdown sections (level 1-3 headings)."""
    sections: list[Section] = []
    current: Section | None = None
    in_frontmatter = False
    frontmatter_count = 0
    in_code_block = False

    for i, line in enumerate(lines, start=1):
        # Skip YAML frontmatter
        if line.strip() == "---":
            frontmatter_count += 1
            in_frontmatter = frontmatter_count == 1
            if frontmatter_count == 2:
                in_frontmatter = False
            continue
        if in_frontmatter:
            continue

        # Toggle code blocks (ne pas parser headings dans les fences)
        if line.lstrip().startswith("```"):
            in_code_block = not in_code_block
            if current is not None:
                current.content.append(line)
            continue

        if not in_code_block:
            m = re.match(r"^(#{1,3})\s+(.+?)\s*$", line)
            if m:
                if current is not None:
                    current.end_line = i - 1
                    sections.append(current)
                current = Section(
                    title=m.group(2).strip(),
                    level=len(m.group(1)),
                    start_line=i,
                )
                continue

        if current is not None:
            current.content.append(line)

    if current is not None:
        current.end_line = len(lines)
        sections.append(current)

    return sections


def count_body_lines(lines: list[str]) -> int:
    """Count lines outside frontmatter."""
    frontmatter_count = 0
    body = 0
    in_frontmatter = False
    for line in lines:
        if line.strip() == "---":
            frontmatter_count += 1
            in_frontmatter = frontmatter_count == 1
            if frontmatter_count == 2:
                in_frontmatter = False
            continue
        if not in_frontmatter:
            body += 1
    return body


def render_plan(agent_path: str, sections: list[Section], body_lines: int) -> str:
    """Render the migration plan as markdown to stdout."""
    agent_name = os.path.splitext(os.path.basename(agent_path))[0]

    keep, extract, transform = [], [], []
    for s in sections:
        kind = s.classify()
        if kind == "KEEP":
            keep.append(s)
        elif kind == "EXTRACT":
            extract.append(s)
        elif kind == "TRANSFORM":
            transform.append(s)

    out: list[str] = []
    out.append(f"# Plan de Migration — Agent `{agent_name}`")
    out.append("")
    out.append(f"**Path** : `{agent_path}`")
    out.append(f"**Lignes body actuelles** : {body_lines}")
    out.append(f"**Seuil ADR-029** : ≤ {THRESHOLD_AGENT_LINES} lignes")
    over = body_lines - THRESHOLD_AGENT_LINES
    if over > 0:
        out.append(f"**Depassement** : +{over} lignes ({over * 12} tokens estimes a couper)")
    else:
        out.append("**Statut** : Conforme — refacto non requise (plan informatif)")
    out.append("")
    out.append(f"**Sections detectees** : {len(sections)} "
               f"(GARDER : {len(keep)} | EXTRAIRE : {len(extract)} | TRANSFORMER : {len(transform)})")
    out.append("")

    out.append("## 1. GARDER dans le prompt systeme")
    out.append("")
    out.append("Sections constitutives de l'identite de l'agent. A conserver tel quel ou condenser si possible.")
    out.append("")
    if not keep:
        out.append("_(aucune section detectee comme constitutive — relire l'anatomie cible)_")
    else:
        for s in keep:
            out.append(f"- `## {s.title}` (L{s.start_line}-L{s.end_line}, {s.line_count}L) — {s.reason('KEEP')}")
    out.append("")

    out.append(f"## 2. EXTRAIRE vers `_reference/{agent_name}-knowledge.md`")
    out.append("")
    out.append("Contenu statique de reference, charge a la demande quand l'agent en a besoin.")
    out.append("")
    if not extract:
        out.append("_(aucune section a extraire detectee)_")
    else:
        total_extract = sum(s.line_count for s in extract)
        out.append(f"**Total a extraire** : {total_extract} lignes (~{total_extract * 12} tokens economises)")
        out.append("")
        for s in extract:
            out.append(f"- `## {s.title}` (L{s.start_line}-L{s.end_line}, {s.line_count}L) — {s.reason('EXTRACT')}")
    out.append("")

    out.append("## 3. TRANSFORMER en skills on-demand")
    out.append("")
    out.append("Procedures reutilisables assez longues pour justifier un skill autonome (cf. `skill-creator`).")
    out.append("")
    if not transform:
        out.append("_(aucune procedure candidate detectee)_")
    else:
        for s in transform:
            slug = re.sub(r"[^a-z0-9-]+", "-", s.title_lower).strip("-")[:40]
            out.append(f"- `## {s.title}` (L{s.start_line}-L{s.end_line}, {s.line_count}L) "
                       f"→ skill propose : `.claude/skills/{slug}/SKILL.md`")
            out.append(f"  - Raison : {s.reason('TRANSFORM')}")
            out.append(f"  - Action : invoquer `skill-creator` avec le contenu de cette section comme draft")
    out.append("")

    out.append("## 4. Prochaines actions")
    out.append("")
    out.append("1. Revoir ce plan avec l'utilisateur (sections ambigues → escalader)")
    out.append(f"2. Creer `_reference/{agent_name}-knowledge.md` avec les sections EXTRAIRE")
    out.append("3. Pour chaque section TRANSFORMER, invoquer `skill-creator`")
    out.append("4. Mettre a jour le frontmatter `skills:` natif de l'agent (ADR-031) :")
    out.append("   - Ajouter les nouveaux skills crees a la liste `skills:` (liste plate)")
    out.append("   - Ne PAS utiliser `bootstrap_skills` ou `on_demand_skills` (deprecated ADR-031, ignores par Claude Code)")
    out.append("   - Les skills universels (safe-execute, verification-before-completion, dette-detector, when-stuck) sont charges via SessionStart hook — ne pas les declarer ici")
    out.append("5. Re-lancer `measure.sh` pour valider la conformite ≤ 250L")
    out.append(f"6. Re-lancer `validate_gate.sh` pour confirmer (exit 0 attendu)")
    out.append("")
    out.append("---")
    out.append("")
    out.append("_Genere par `agent-density-auditor` — references : ADR-029, ADR-030_")

    return "\n".join(out)


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: python3 plan_migration.py <path-to-agent.md>", file=sys.stderr)
        return 0

    agent_path = sys.argv[1]
    if not os.path.isfile(agent_path):
        print(f"File not found: {agent_path}", file=sys.stderr)
        return 0

    with open(agent_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    body_lines = count_body_lines(lines)
    sections = parse_sections(lines)
    plan = render_plan(agent_path, sections, body_lines)
    print(plan)
    return 0


if __name__ == "__main__":
    sys.exit(main())
