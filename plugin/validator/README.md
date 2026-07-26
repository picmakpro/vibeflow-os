# validator — Agent Garant d'Alignement Lab ↔ Méthodologie

> Agent natif Claude Code (`vibeflow-validator`) qui orchestre les **5 audits** de conformité du
> lab — infrastructure, densité/conformité agents, dette documentaire + mémoire, architecture des
> process, synthèse — pour garantir qu'un lab reste fidèle à la méthodologie VibeFlow malgré
> l'évolution Anthropic, l'append-only des registres et la dette inévitable.

**Version** : v1.3.1
**Type** : agent-only
**Densité** : `AGENT.md` = 249 lignes — le plafond ADR-029 est ≤ 250 : le module est **à 1 ligne
du plafond**, tout ajout passe par un délestage préalable.
**Iron Law** : *« Détecter et signaler. Ne jamais corriger sans validation humaine. »* (ADR-031)

---

## Pourquoi

Sans agent garant, la dette s'accumule silencieusement :

- Agents qui dépassent 250 lignes (perte de focus, ADR-029)
- Agents non conformes ADR-044 (description / model / memory manquants)
- Registres mémoire qui explosent (pollution contexte)
- Hooks deprecated qui ne s'exécutent plus (régression silencieuse)
- Briques de debug qui partent en empirique sans recherche documentaire (ADR-045)
- Process générateurs sans structure d'audit multi-couches (ADR-036)
- Drift méthodo ↔ lab (modules vibeflow-os out-of-date)

L'agent `vibeflow-validator` orchestre 5 audits complémentaires en une seule invocation et produit
un rapport actionnable.

---

## Installation

Pré-requis (`module.json` → `requires`) : modules **`consolidator`**, **`infrastructure-audit`**
et **`audit-architecture`** installés — ce dernier porte la Phase 4 (ADR-036). Le script
`check-agents.sh` (module `conductor`, socle mandatory) doit aussi être présent.

```bash
.claude/scripts/vibeflow-update.sh install consolidator
.claude/scripts/vibeflow-update.sh install infrastructure-audit
.claude/scripts/vibeflow-update.sh install audit-architecture
.claude/scripts/vibeflow-update.sh install validator
```

L'install copie :
- `validator/AGENT.md` → `.claude/agents/validator.md` (le **fichier** prend le nom du module ;
  le **nom d'agent** reste `vibeflow-validator`, porté par le frontmatter)

L'agent devient disponible immédiatement dans le lab.

---

## Usage

### Invocation

Via `/vf-audit` (la commande délègue à l'agent), ou directement via Task :

```python
Task(subagent_type="vibeflow-validator", prompt="Audit complet")
```

### Cas d'usage

- **À chaque `/vf-audit`** (audit complet)
- **Après update Claude Code** (snapshot infra + diff)
- **Avant release module vibeflow-os** (gate qualité)
- **Quand un agent semble dériver** (premier suspect = densité)
- **Périodique** — cadence proportionnée au lab : à chaque release ou gros jalon (lab solo) ;
  mensuel pour les labs d'équipe actifs

### Gouvernance proportionnée au profil

L'ampleur de l'audit suit le **profil de rigueur** du lab (clé `"profile"` de
`.planning/config.json`, posée par `vf-planning`) :

- **`leger`** : Phases 1-3 + 5 — la Phase 4 est **sautée** (opt-in), activable via `--full`.
  Le score est **renormalisé** sur les phases réellement exécutées (jamais de pénalité fantôme).
- **`standard` / `complet`** (ou `--full`, ou config absente) : les 5 phases.

### Output

Rapport `reports/validator/YYYY-MM-DD-validator.md` avec :

- Score global 0-100 (calculé sur les phases exécutées uniquement)
- Status PASS / WARN / FAIL — un **FAIL bloque le gate `/vf-audit` en cours** et exige une
  remédiation humaine
- Findings par phase (une phase sautée est mentionnée comme telle, jamais silencieuse)
- Actions recommandées par priorité

---

## Phases d'audit

| Phase | Délégué à | Quoi |
|-------|-----------|------|
| 1 | skill `infrastructure-audit` (`audit-infra.sh`) | Version Claude Code, hooks valides, scripts intègres, drift snapshot — **bloquant** si ERROR |
| 2 | scripts `check-agents.sh --strict` + `check-debug-research.sh` | Conformité agents (ADR-044), densité ADR-029 (agents ≤ 250L, skills ≤ 500L, bootstrap ≤ 2000 tokens), recherche-doc avant debug (ADR-045) |
| 3 | grille des 7 signaux + `consolidator --audit` + `detect-planning-debt.sh` | Dette documentaire, cohérence index ↔ body des registres, 8e signal dette de planning (advisory, ADR-040) |
| 4 | skill `audit-architecture` (mode scan) | Architecture d'audit des process générateurs (ADR-036) — **opt-in selon profil**, sautée en `leger` |
| 5 | _synthèse_ | Score renormalisé + status + actions recommandées |

L'agent ne réimplémente RIEN : il délègue aux skills et scripts outillés (la grille des 7 signaux
est appliquée directement depuis le template de la méthodologie). Si un besoin émerge sans skill
correspondant, il passe par `skill-creator` — jamais de logique codée dans l'agent.

---

## Iron Laws

1. Détecter, jamais corriger sans validation humaine (ADR-031)
2. Déléguer aux skills, ne pas réimplémenter (LRN-105, ADR-030 révisée)
3. Snapshot avant audit, snapshot après (traçabilité)
4. Score reproductible (même état = même score)

---

## Contenu du module

```
validator/
├── AGENT.md        # l'agent vibeflow-validator (frontmatter skills: consolidator,
│                   #   infrastructure-audit, audit-architecture)
├── CHANGELOG.md
├── module.json     # type agent-only, requires: consolidator + infrastructure-audit
│                   #   + audit-architecture
├── README.md
└── VERSION
```

---

## Limites

- Pas d'auto-fix (par design, ADR-031)
- Le rapport est en markdown statique (pas de dashboard temps réel)
- Les skills délégués doivent être installés au préalable (pas de résolution automatique des
  dépendances par `vibeflow-update.sh`)
- Le score 0-100 reste indicatif hors gate : seul un status FAIL bloque `/vf-audit`

---

## Références

- ADR-029 — Charte densité
- ADR-030 (révisée) — Architecture skills natifs
- ADR-031 — Jamais de fix sans validation humaine
- ADR-032 — Consolidation Mémoire 4 piliers
- ADR-036 — Doctrine Audit Architecture (Phase 4)
- ADR-040 — Dette de planning, 8e signal
- ADR-044 — Agents natifs machine-enforced (`check-agents.sh`)
- ADR-045 — Recherche documentaire avant debug (Phase 2)
- ADR-056 — Vigilance support runtime (ex-second emploi d'ADR-031, scindé en v2.32.0)
- LRN-105 — 4 piliers complémentaires
- LRN-106 — Audit avant fix
