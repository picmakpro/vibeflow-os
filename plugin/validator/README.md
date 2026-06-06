# validator — Agent Garant d'Alignement Lab ↔ Méthodologie

> Agent natif Claude Code qui orchestre les 4 audits du package vibeflow-os pour garantir qu'un lab reste fidèle à la méthodologie VibeFlow malgré l'évolution Anthropic, l'append-only des registres et la dette inévitable.

**Version** : v1.0.0
**Densité** : 183 lignes (charte ADR-029 ≤250L)
**Iron Law** : *"Détecter et signaler. Ne jamais corriger sans validation humaine."* (ADR-031)

---

## Pourquoi

Sans agent garant, la dette s'accumule silencieusement :

- Agents qui dépassent 250L (perte de focus)
- Registres mémoire qui explosent (pollution contexte)
- Hooks deprecated qui ne s'exécutent plus (régression silencieuse)
- Drift méthodo ↔ lab (modules vibeflow-os out-of-date)

L'agent vibeflow-validator orchestre 4 audits complémentaires en une seule invocation et produit un rapport actionnable.

---

## Installation

Pré-requis : modules `consolidator` + `infrastructure-audit` installés via vibeflow-update.sh.

```bash
.claude/scripts/vibeflow-update.sh install consolidator
.claude/scripts/vibeflow-update.sh install infrastructure-audit
.claude/scripts/vibeflow-update.sh install validator
```

L'install copie :
- `validator/AGENT.md` → `.claude/agents/vibeflow-validator.md`

L'agent devient disponible immédiatement dans le lab.

---

## Usage

### Invocation directe

```
Tu es vibeflow-validator. Lance audit complet.
```

OU via Task tool :

```python
Task(subagent_type="vibeflow-validator", prompt="Audit complet")
```

### Cas d'usage

- **À chaque /checkpoint** (auto via trigger update)
- **Après update Claude Code** (snapshot infra + diff)
- **Avant release module vibeflow-os** (gate qualité)
- **Quand un agent semble dériver** (premier suspect = densité)
- **Périodique** (recommandé 1×/mois pour labs actifs)

### Output

Rapport `reports/validator/YYYY-MM-DD-validator.md` avec :

- Score global 0-100
- Status PASS / WARN / FAIL
- Findings par phase (infrastructure, densité, dette, recommandations)
- Actions prioritaires

---

## Architecture

```
vibeflow-validator (Opus, project memory)
├── skills: consolidator (mémoire 4 piliers)
├── skills: infrastructure-audit (drift Anthropic)
├── skills: agent-density-auditor (charte ADR-029)
├── skills: dette-detector (7 signaux dette)
└── skills: checkpoint (cohérence Lab)

→ 4 phases d'audit séquentielles
→ Rapport synthétique
→ Aucune correction sans validation humaine
```

L'agent ne réimplémente RIEN. Il délègue 100% aux skills outillés.

---

## Phases d'audit

| Phase | Skill délégué | Quoi |
|-------|---------------|------|
| 1 | `infrastructure-audit` | Version Claude Code, hooks valides, scripts intègres, drift snapshot |
| 2 | `agent-density-auditor` | Agents ≤250L, skills ≤500L, bootstrap ≤2000 tokens |
| 3a | `dette-detector` | 7 signaux dette documentaire |
| 3b | `consolidator --audit` | Cohérence index ↔ body, collisions, promotions en attente |
| 4 | _synthèse_ | Score + actions recommandées |

---

## Iron Laws

1. Détecter, jamais corriger sans validation humaine (ADR-031)
2. Déléguer aux skills, ne pas réimplémenter (LRN-105)
3. Snapshot avant audit, snapshot après (traçabilité)
4. Score reproductible (même état = même score)

---

## Limites v1.0.0

- Pas d'auto-fix (par design, ADR-031)
- Le rapport est en markdown statique (pas de dashboard temps réel)
- Skills déléguées doivent être installés au préalable
- Score 0-100 est indicatif (pas de gate auto-bloquant — c'est au user de décider)

---

## Références

- ADR-029 — Charte densité
- ADR-030 (révisée) — Architecture skills natifs
- ADR-031 — Vigilance support runtime
- ADR-032 — Consolidation Mémoire
- LRN-105 — 4 piliers complémentaires
- LRN-106 — Audit avant fix
