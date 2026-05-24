---
name: agent-density-auditor
description: Audit, plan migration, applique et garde la densite des prompts systeme d'agents Claude Code selon la charte VibeFlow ADR-029 (Agent ≤250L / SKILL.md ≤500L / Bootstrap SessionStart ≤2000 tokens). Use this skill whenever the user mentions agent density, agent too long, heavy agent, prompt size, agent refactoring, agent diet, "reduire prompt systeme", "couper un agent", "alleger agent", OR whenever creating/editing files in `.claude/agents/*.md`, OR whenever auditing a VibeFlow / DevFlow project, OR when the user invokes `/checkpoint`, OR when Initializer generates new agents and needs a validation gate. Even if the user doesn't say "density" explicitly, trigger if they show a long agent file (>250 lines) or ask why an agent "hallucinates" / "drifts" — density bloat is the most common root cause per ADR-029.
model: sonnet
---

# Agent Density Auditor

## Mission

Garantir que les prompts systeme d'agents Claude Code dans tout projet VibeFlow (Lab, methodology templates, projets derives) respectent la **charte de densite ADR-029** : Agent ≤ 250 lignes, SKILL.md ≤ 500 lignes, Bootstrap SessionStart ≤ 2000 tokens. La sur-densite est empiriquement liee aux hallucinations et au context rot (Chroma 2025, Anthropic). Ce skill outille la mesure, la planification de migration et la validation continue.

## Quand utiliser ce skill

Quatre modes selon le besoin :

| Mode | Quand l'utiliser | Output |
|------|------------------|--------|
| **measure** | Audit ponctuel d'un agent ou d'un dossier `.claude/agents/` | Tableau densite + classification |
| **plan** | Un agent depasse les seuils → besoin d'un plan d'extraction | Plan de migration markdown |
| **apply** | Plan valide → executer la migration (extraction skills + `_reference/`) | Patches diff + nouveaux fichiers |
| **gate** | Validation automatique post-edit (hook PreToolUse, Initializer) | Exit 0 (conforme) / 1 (violation) |

**Triggers explicites** :
- `/checkpoint` → mode `measure` sur tout `.claude/agents/`
- Initializer apres generation agents → mode `gate` (bloque si violation)
- User : "mon agent backend est trop long" → mode `plan`
- User : "applique le plan de migration" → mode `apply`

## Iron Laws (ADR-029)

Ces seuils sont **non negociables**. Toute violation doit etre tracee dans `.claude/memory/BLOCKERS.md` si conservee, sinon refactoree.

1. **Agent ≤ 250 lignes** (hors frontmatter). Source : reverse-engineering Claude Code + Superpowers v5.1 (152K stars).
2. **SKILL.md ≤ 500 lignes**. Source : Anthropic officiel (skill authoring guidelines).
3. **Bootstrap SessionStart ≤ 2000 tokens**. Source : Superpowers v5.1 (ADR-021).
4. **Description frontmatter ≤ 1024 caracteres**. Source : runtime Claude Code.
5. **Toute violation passee inapercue est une dette** — tracer dans EVALS ou refactorer immediatement.

> Voir `references/thresholds.md` pour le detail des sources et classifications (acceptable / lourd / critique).

## Anatomie cible d'un agent (80-200L)

```
---
Frontmatter (name + description + model + skills — convention native Claude Code, ADR-031)
---
# Mandat (≤3 phrases)
# Perimetre (ce qu'il fait / ne fait pas)
# Iron Laws (≤5 puces — regles non negociables)
# Workflow minimal (≤5 etapes — pointer vers skills pour le detail)
# Skills disponibles (table : nom → trigger)
# Escalation (quand s'arreter et remonter)
```

Detail complet avec exemple : voir `references/agent_anatomy.md`.

## Patterns d'extraction

Quand un agent depasse 250L, l'extraction se decide par categorie de contenu :

| Si tu vois dans l'agent | Deplacer vers | Pourquoi |
|------------------------|---------------|----------|
| Checklist exhaustive (regulatory, security, OWASP) | `_reference/<agent>-knowledge.md` | Lecture a la demande, pas permanente |
| Procedure how-to reutilisable ≥50L | Nouveau skill on-demand `.claude/skills/<nom>/SKILL.md` | Reutilisable entre agents (DRY) |
| Exemples de code etendus | `_reference/<agent>-knowledge.md` | Charges seulement si pertinent |
| Tableau de couts / quotas | `_reference/<agent>-knowledge.md` | Donnees statiques |
| Documentation de reference | `_reference/<agent>-knowledge.md` | |
| Anti-patterns critiques courts | Garder dans agent (Iron Laws) | Garde-fou systematique |
| Mandat / perimetre / escalation | Garder dans agent | Identite de l'agent |

Detail avec exemples concrets : voir `references/migration_patterns.md`.

## Comment invoquer les scripts

Les scripts sont dans `scripts/`. Ils sont idempotents et n'ont pas d'effets de bord destructeurs.

### Mode measure — Mesurer la densite

Un agent unique :
```bash
bash scripts/measure.sh .claude/agents/backend.md
```

Tout un dossier (output tableau) :
```bash
bash scripts/measure.sh .claude/agents/
```

Sortie type :
```
PATH                       LINES  BODY   TOKENS_EST  STATUS
.claude/agents/backend.md  928    915    10980       CRITICAL
.claude/agents/lead.md     556    540    6480        CRITICAL
.claude/agents/explorer.md 178    165    1980        OK
```

Classification :
- ≤ 200L → `OK`
- 201-250L → `WARN` (marge faible)
- 251-400L → `HEAVY` (refacto recommandee)
- > 400L → `CRITICAL` (refacto obligatoire)

### Mode plan — Planifier la migration

```bash
python3 scripts/plan_migration.py .claude/agents/backend.md > /tmp/plan-backend.md
```

Le script genere un plan d'extraction par sections detectees (headings markdown, code blocks, checklists). L'utilisateur revoit le plan avant `apply`. Le plan distingue :

- **GARDER** dans le prompt systeme (mandat, perimetre, iron laws, workflow, escalation)
- **EXTRAIRE** vers `_reference/<agent>-knowledge.md` (statique, lecture a la demande)
- **TRANSFORMER** en skill on-demand (procedure reutilisable ≥50L)

### Mode apply — Appliquer la migration

L'application est manuelle et controlee. Le skill ne supprime jamais sans confirmation. Workflow recommande :

1. Lire le plan genere
2. Pour chaque section "EXTRAIRE" : creer/completer `_reference/<agent>-knowledge.md` puis supprimer du prompt
3. Pour chaque section "TRANSFORMER" : invoquer `skill-creator` pour le nouveau skill on-demand, puis l'ajouter au frontmatter `skills:` natif (ADR-031, pas de champ `on_demand_skills` invente)
4. Re-lancer `measure.sh` pour valider la conformite

### Mode gate — Valider la conformite

Utilise par le hook PreToolUse (Edit/Write sur `.claude/agents/*.md`) et par Initializer :
```bash
bash scripts/validate_gate.sh .claude/agents/backend.md
echo $?  # 0 = conforme, 1 = violation
```

Verifications :
- Lignes hors frontmatter ≤ 250
- Frontmatter contient `description` ≤ 1024 caracteres
- Frontmatter utilise `skills:` natif Claude Code (ADR-031) — pas de champ invente (`bootstrap_skills`, `on_demand_skills` deprecated)
- Aucune section unique > 100 lignes (signal extraction necessaire)

Integration hook (extrait `hooks-ci-cd-template.json`) :
```json
"PreToolUse": [{
  "matcher": "Edit|Write",
  "filter": ".claude/agents/*.md",
  "command": "bash methodology/templates/skills/agent-density-auditor/scripts/validate_gate.sh $TOOL_INPUT_FILE_PATH"
}]
```

## Quand escalader

Certains cas ne sont pas tranchables automatiquement. Remonter a l'Architect / utilisateur si :

- **Checklist metier RGPD/OWASP** sur 80L : `_reference/` ou skill on-demand ? → depend de la frequence d'usage (>1 par sprint = skill, sinon `_reference/`).
- **Workflow lui-meme > 5 etapes** : signal de mandat trop large, l'agent doit etre split (creer un sous-agent).
- **Iron Laws > 5 puces** : prioriser les 5 critiques, les autres deviennent une checklist de skill.
- **Description frontmatter trop courte** : risque de undertriggering du skill — proposer une description "pushy" (cf. skill-creator).
- **Bootstrap SessionStart > 2000 tokens mais tous les skills sont legitimes** : reviser la liste `universal:` du hook SessionStart (peut-etre certains skills devraient passer en `contextual:`).

## References

- `references/thresholds.md` — Tous les seuils ADR-029 documentes avec sources
- `references/migration_patterns.md` — Guide d'extraction concret avec exemples
- `references/agent_anatomy.md` — Structure cible 80-200L avec exemple complet
- ADR-029 : Charte densite agents (`.claude/memory/ADR.md`)
- ADR-030 : Bootstrap-skills vs On-demand skills
- ADR-021 : Import patterns Superpowers v5.1 (precedent)
- Anthropic : skill authoring best practices, effective context engineering
- Chroma 2025 : context rot research (18 modeles, –30% precision a 113K tokens)
- Superpowers v5.1 : `bootstrap.md` SessionStart pattern, 1% Rule

## Notes d'usage

- **Idempotence** : tous les scripts peuvent etre relances sans degats. `measure.sh` est read-only. `plan_migration.py` ecrit uniquement sur stdout.
- **Langue** : output francais (rapports), code/frontmatter en anglais (convention Claude Code).
- **Iteration** : prefere appliquer un agent a la fois, mesurer, ajuster. Ne pas tenter de migrer tous les agents en une seule passe (perte de visibilite des regressions).
