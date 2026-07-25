# Reference — Pilier 4 : Promotion learning -> rule (semi-auto)

> Sous-document du skill `consolidator`. Detail technique du pilier Promotion.

## Probleme resolu

Le template `learnings-template.md` prevoit le champ `Encode dans:` pour referencer une rule qui encode le learning. Audit Lab Session 046 :

- 101 learnings capitalises
- 3 rules Lab actives (lab-global, methodology-guard, reports)
- **0 learning** avec champ `Encode dans:` non vide

Le pipeline `learning -> rule` est dormant alors que c'est le mecanisme qui transforme la memoire en **comportement** (un learning capitalise reste passif tant qu'il n'est pas promu en rule).

## Vigilance ADR-031

> **Aucune primitive native Anthropic ne fait la promotion automatique**. Le pattern le plus proche publie est MindStudio "Learnings Loop" (semi-auto, validation humaine). Auto-write dans `.claude/rules/` sans validation = anti-pattern (risque pollution silencieuse, drift comportemental non-trace).

**Iron Law promotion** : *Aucun ecriture dans `.claude/rules/*.md` final sans validation humaine. Les drafts vont exclusivement dans `.claude/rules/_draft/`.*

## Pipeline 4 phases

### Phase A — Detection (script bash)

`detect-promotions.sh` scanne LEARNINGS.md et sort des candidats selon 3 criteres OR :

| Critere | Mesure | Seuil |
|---------|--------|-------|
| Frequence | Nb learnings partageant tag/theme | ≥ 3 |
| Operationnel | Presence de mots-cles d'instruction | `toujours`, `jamais`, `eviter`, `forcer`, `obligatoire`, `interdire`, `prefer` |
| Non-encode | Champ `Encode dans:` = `Non encode` ou absent | true |

Un candidat satisfait `(Frequence OR Operationnel) AND Non-encode`.

Output JSON :

```json
{
  "candidates": [
    {
      "type": "operational_single",
      "lrn_id": "LRN-032",
      "title": "Console.log en production = bloque",
      "rule_slug": "no-console-in-prod",
      "rule_path_proposed": "src/**/*.{ts,tsx,js,jsx}",
      "confidence": 0.9
    },
    {
      "type": "frequency_cluster",
      "lrn_ids": ["LRN-099", "LRN-100"],
      "common_theme": "agent density",
      "rule_slug": "agent-density-ceiling",
      "confidence": 0.85
    }
  ]
}
```

### Phase B — Draft auto (LLM)

Pour chaque candidat, l'agent (Claude) genere un draft `.claude/rules/_draft/[slug].md` avec :

- **Frontmatter** : `paths:` (scope where the rule applies)
- **Contenu** : reformulation imperative du learning (instructions courtes, claires)
- **Sources** : liens vers LRN-XXX a la fin

Prompt type :

```
Tu generes un brouillon de rule contextuelle pour Claude Code a partir d'un ou plusieurs learnings.

Sources :
{contenu LRN-XXX}

Format de sortie (markdown) :
---
description: [titre court de la rule]
paths:
  - "[glob path qui declenche la rule]"
---

# [Titre de la rule]

[Instructions imperatives, courtes, sans justification].

## Sources
- LRN-XXX : [titre du learning]
```

### Phase C — Validation humaine

Le user revoit chaque draft dans `.claude/rules/_draft/` :

- ✅ Accepter -> `mv _draft/[slug].md ../[slug].md`
- ❌ Rejeter -> garder en draft ou supprimer
- 🔄 Editer puis accepter

Cette etape est **obligatoire** et **non-automatisable**. Une rule active modifie le comportement de tous les futurs agents qui matchent son `paths:`.

### Phase D — Mise a jour LEARNINGS

Pour chaque rule promue :

1. Les learnings sources sont mis a jour : `Encode dans: .claude/rules/[slug].md`
2. Si les learnings sont strictement contenus dans la rule -> archivage (pilier 2)
3. Sinon -> conserves en L2 (peuvent etre referenced dans contextes precis hors rule)

## Criteres pour une bonne rule

Avant d'accepter un draft, verifier :

- [ ] **Concise** : ≤ 50 lignes (ADR-029 charte densite)
- [ ] **Imperative** : instructions, pas explications
- [ ] **Scopee** : `paths:` precis (pas trop large)
- [ ] **Sources tracees** : LRN-XXX cite en bas
- [ ] **Sans duplication** : ne contredit ni n'ecrase une rule existante
- [ ] **Testable** : on peut verifier si elle est respectee ou non

## Anti-patterns

- ❌ Promouvoir un learning unique sans operationnel (un learning informatif n'est pas une rule)
- ❌ Promouvoir sans `paths:` ou avec `paths: ["**"]` (rules trop larges = bruit dans toutes les sessions)
- ❌ Auto-promotion sans validation (ADR-031)
- ❌ Promouvoir un learning encore en debat (Statut: En discussion)
- ❌ Cumuler des rules contradictoires (ex : "always X" et "never X" coexistent)

## Quand declencher

- **Trimestriel** ou au /vf-audit majeur
- **Manuel** : `/consolidate --pillar=promote`
- **Apres un cluster de learnings sur meme theme** : la detection sort souvent un candidat naturel

## Output rapport

`reports/consolidation/YYYY-MM-DD-consolidation.md` section Pilier 4 :

```markdown
## Pilier 4 — Promotion

### Candidats detectes (3)
- LRN-032 (operational) -> draft .claude/rules/_draft/no-console-in-prod.md
- LRN-099 + LRN-100 (cluster density) -> draft .claude/rules/_draft/agent-density-ceiling.md
- LRN-019 (operational mais deja partiellement encode dans ADR-009) -> skip

### Status drafts
- [ ] no-console-in-prod.md (en attente validation user)
- [ ] agent-density-ceiling.md (en attente validation user)

### Action user requise
Revoir .claude/rules/_draft/, valider/rejeter, deplacer vers .claude/rules/
```

## Workflow recommande

```
1. /consolidate --pillar=promote --dry-run
   -> liste candidats, drafts generes mais pas appliques

2. User revoit chaque draft
   -> edite si necessaire

3. mv .claude/rules/_draft/<slug>.md .claude/rules/<slug>.md
   -> promotion effective

4. /consolidate --pillar=promote --finalize
   -> met a jour `Encode dans:` dans LEARNINGS.md des sources
```

## Lien avec EVALS (P8 VIBEFLOW_CORE)

Une rule promue doit etre auditee dans EVALS.md apres 1-2 mois d'usage :
- A-t-elle effectivement change le comportement ?
- Le LLM la respecte-t-il ou la contourne-t-il ?
- Faut-il la renforcer (hook bloquant) ou la retirer (pollution) ?

Cette boucle ferme la consolidation : `learning -> rule -> eval -> learning ou archive`.
