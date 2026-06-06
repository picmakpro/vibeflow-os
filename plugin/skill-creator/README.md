# skill-creator — Pattern Agent Minimal + 2 Skills Composables

> **Module multi-composants** : 1 agent natif + 2 skills externes.
> Pattern issu de VideoFlow-Lab, généralisé Session 045 (LRN-101) puis packagé pour distribution cross-labs Session 047.

**Version** : v1.0.0
**Source originale** : `output/skill-creator-universal/` du VibeFlow Lab (LRN-101, Session 045)

---

## Quoi

Ce module installe le **pattern de référence pour créer/améliorer des skills** dans n'importe quel lab Claude Code :

```
.claude/
├── agents/
│   └── skill-creator.md              ← Agent minimal (85 lignes)
└── skills/
    ├── skill-creator/                 ← Skill officiel Anthropic (~248 KB) — NE PAS MODIFIER
    └── skill-creator-workflow/        ← Procédure 5 phases personnalisable
```

---

## Philosophie : 3 couches stables / mobiles

| Couche | Rôle | Qui peut modifier |
|--------|------|-------------------|
| **Agent** (85L) | Rôle + règles ABSOLUES + références vers les 2 skills | User (personnaliser nom Lab + orchestrating agent) |
| **Skill Anthropic** | Moteur officiel de drafting + grader + analyzer + 9 scripts Python | Anthropic uniquement |
| **Skill workflow** | Procédure 5 phases personnalisable (clarifier → planifier → drafter → tester → livrer) | User selon contexte Lab |

---

## Installation via vibeflow-update.sh

```bash
.claude/scripts/vibeflow-update.sh install skill-creator
```

L'installation copie :
- `AGENT.md` → `.claude/agents/skill-creator.md`
- `skills/skill-creator/` → `.claude/skills/skill-creator/`
- `skills/skill-creator-workflow/` → `.claude/skills/skill-creator-workflow/`

**Pré-requis** : `vibeflow-update.sh` v1.3.0+ (support multi-skills par module).

---

## Personnalisation post-install

Après installation, ouvrir `.claude/agents/skill-creator.md` et remplacer les marqueurs :

- `[NOM_LAB]` → nom du Lab (ex: `BusinessFlow`, `MarketingFlow`)
- `[ORCHESTRATING_AGENT]` → agent qui reçoit l'escalation Phase 5 (ex: `editor-architect`, `lead`, `architect`)

Optionnel : ajouter 1 skill de recherche spécifique au domaine dans le frontmatter `skills:` (ex: `marketing-research`, `urbanisme-research`).

---

## Usage

```
Invoque l'agent skill-creator pour créer un nouveau skill <nom-du-skill>.
```

L'agent suit le workflow 5 phases : clarifier le besoin → planifier les facettes → recherche parallèle adaptive → draft via skill-creator Anthropic → escalation orchestrating agent pour attribution.

**Règle ABSOLUE** : 1 skill par invocation, non-négociable.

---

## Voir aussi

- `INSTALL.md` — Guide d'install original du package universel (manuel, pas via vibeflow-update)
- LRN-101 du Lab VibeFlow — pattern "agent minimal + 2 skills composables" issu de VideoFlow-Lab
- Skill Anthropic officiel : https://github.com/anthropics/skills (skill-creator)

---

## Limites v1.0.0

- Pattern issu d'un Lab spécifique (VibeFlow), personnalisation manuelle requise au moment de l'install
- skill-creator (Anthropic) est figé — toute évolution Anthropic doit être re-packagée manuellement
- skill-creator-workflow contient des références à VibeFlow → à adapter pour Labs non-VibeFlow
