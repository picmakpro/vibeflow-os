# Template — Entrée de mémoire vivante (`.claude/memory/knowledge/`)

> **Couche mémoire vivante** (ADR-052) — distincte des registres d'audit tabulaires
> (`DECISIONS.md`, `LEARNINGS.md`…). Ici, **une entrée = un fichier** `.md` au format frontmatter
> natif Claude Code, portant le **savoir vivant** de l'agent sur le lab (qui est l'utilisateur, ses
> préférences, faits projet, pointeurs). Sa fiabilité **décroît dans le temps** ; elle est entretenue
> par la passe `decay-pass.sh` du `consolidator` (pilier 5). **Ne mettez pas ici** une décision datée
> ou un learning acquis — ceux-là vont dans les registres d'audit (ils ne « perdent pas en confiance »).

## Arborescence

```
.claude/memory/knowledge/
  MEMORY.md            # index : une ligne par entrée active (- [Titre](slug.md) — accroche)
  <slug>.md            # une entrée = un fait
  archive/             # entrées superseded (conservées, jamais supprimées)
```

## Frontmatter d'une entrée

```yaml
---
name: <slug-kebab-case>
description: "résumé d'une ligne — sert au rappel de pertinence"
metadata:
  node_type: memory
  type: user | feedback | project | reference   # détermine la demi-vie de décroissance
trust: high | medium | low        # qui l'affirme : high=dit par l'user / medium=observé / low=inféré
confidence: 0.0–1.0               # BASE posée à la création/renforcement — jamais écrasée par la passe
created: YYYY-MM-DD               # ancre de la décroissance
status: active | superseded       # supersession non destructive
superseded_by:                    # slug de l'entrée qui remplace (vide si active)
---

<le fait, en clair. Liens vers d'autres entrées avec [[slug]].>
```

Deux champs **dérivés** sont ajoutés/recalculés automatiquement par la passe — **ne pas les saisir à la main** :

```yaml
effective_confidence: 0.0–1.0     # = confidence × 0.5 ^ (age_jours / demi_vie[type])
last_decay_pass: YYYY-MM-DD       # traçabilité de la dernière passe
needs_review: true | false        # true si effective_confidence < seuil (0.2) — flag, PAS suppression
```

## Types et demi-vies (ADR-052, post-panel)

| `type`       | Rôle                                              | Demi-vie |
|--------------|---------------------------------------------------|----------|
| `feedback`   | corrections / guidance validées par l'utilisateur | **365 j** |
| `user`       | préférences, rôle, positionnement                 | **180 j** |
| `reference`  | pointeurs vers systèmes externes (dashboards…)    | **120 j** |
| `project`    | état / faits d'un projet (deadlines, sprints)     | **30 j**  |

Un type inconnu retombe sur la demi-vie la plus courte (`project`, 30 j).

## Cycle de vie

- **Décroissance** : à chaque passe (`/consolidate`, batch — pas par tour), `effective_confidence` est
  recalculée. Une entrée sous le seuil est **flaggée `needs_review`**, jamais supprimée.
- **Supersession** : pour remplacer une entrée, renseignez `superseded_by: <nouveau-slug>` (ou
  `status: superseded`). La passe la **déplace vers `archive/`** en conservant le contenu (ADR-031 :
  jamais de destruction sans humain).

## Exemple

```yaml
---
name: commits-en-francais
description: "Samuel veut les messages de commit en français"
metadata:
  node_type: memory
  type: feedback
trust: high
confidence: 0.95
created: 2026-07-22
status: active
superseded_by:
---

Tous les commits de ce lab sont rédigés en français, cohérents avec l'historique. Voir [[user-samuel]].
```
