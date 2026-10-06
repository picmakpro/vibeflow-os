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

#### Grille de tri (POCK-05)

Chaque candidat est trie par sa **nature** (champ `nature`), qui decide de la **proposition** :

| Nature | Reconnaissable a | Proposition (Phase B) |
|--------|------------------|-----------------------|
| `mecanique` | motif syntaxique, API ou commande bannie, emplacement ou nom de fichier, format | `check` : un controle deterministe (lint, hook ou job CI), jamais une prose de regle |
| `jugement` | coherence entre fichiers, choix de conception, arbitrage de contexte | `brouillon-regle` : un draft de rule, comme avant |

Une erreur mecanique devient un controle execute, pas une ligne de regle de plus. Le script pose `nature` par une **heuristique lexicale** (indices dans le titre et les 500 premiers caracteres : lint, hook, regex, grep, commit, chemin, fichier, import, console.log, frontmatter, job ci, extension de fichier) ; **le defaut est `jugement`** — on ne propose jamais un check a tort. Un cluster n'est `mecanique` que si tous ses membres le sont. L'heuristique est un tri, pas un verdict : le tri final reste humain (Phase C).

Output JSON :

```json
{
  "candidates": [
    {
      "type": "operational_single",
      "lrn_id": "LRN-032",
      "title": "Console.log en production = bloque",
      "rule_slug": "no-console-in-prod",
      "nature": "mecanique",
      "proposition": "check",
      "confidence": 0.85
    },
    {
      "type": "frequency_cluster",
      "category": "Architecture",
      "lrn_ids": "LRN-099,LRN-100,LRN-101",
      "rule_slug": "cluster-architecture",
      "nature": "jugement",
      "proposition": "brouillon-regle",
      "confidence": 0.7
    }
  ],
  "findings": [
    {"type": "depot_sans_garde_fou", "detail": "aucun workflow CI, aucun script check-*.sh, aucun hook declare"}
  ]
}
```

`findings` est un tableau (vide quand le depot porte au moins un garde-fou). `depot_sans_garde_fou` est **mesure** par le script dans le repertoire courant : aucun `.github/workflows/*.yml|*.yaml`, aucun `check-*.sh` sous `.claude/scripts/` ou `scripts/`, aucun `.claude/settings.json` declarant `"hooks"`.

### Phase B — Draft auto (LLM)

Pour chaque candidat de nature `jugement`, l'agent (Claude) genere un draft `.claude/rules/_draft/[slug].md`. Pour un candidat `mecanique`, il genere un **brouillon de check** (type lint, hook ou job CI ; motif exact detecte ; commande qui le verifie) dans le meme dossier `_draft/`, sous `check-[slug].md`, soumis a la meme validation (Phase C) — jamais une prose de regle. Le draft de rule porte :

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
- LRN-032 (operational, mecanique) -> brouillon de check .claude/rules/_draft/check-no-console-in-prod.md
- LRN-099 + LRN-100 (cluster density, jugement) -> draft .claude/rules/_draft/agent-density-ceiling.md
- LRN-019 (operational mais deja partiellement encode dans ADR-009) -> skip

### Findings
- depot_sans_garde_fou : aucun workflow CI, aucun check-*.sh, aucun hook declare
- no-op : la regle X (LRN-0NN) n'a change aucune session observee

### Status drafts
- [ ] check-no-console-in-prod.md (en attente validation user)
- [ ] agent-density-ceiling.md (en attente validation user)

### Action user requise
Revoir .claude/rules/_draft/, valider/rejeter, deplacer vers .claude/rules/
```

#### Findings

Deux constats vont au rapport, sous « Findings », en plus des candidats :

- **Depot sans garde-fou** (`depot_sans_garde_fou`) — **mesure** : champ `findings` du JSON de `detect-promotions.sh`. Sans garde-fou mesurable, aucun check promu n'a de cible a laquelle s'ajouter : le rapport le dit.
- **Instruction sans effet (no-op)** — **jugement de l'agent**, jamais calcule par le script : une regle ou une consigne dont aucune session ne montre l'effet (jamais citee, jamais respectee ni enfreinte, aucun comportement qui differe). Elle est **signalee au rapport**, jamais retiree sans validation humaine (ADR-031).

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
