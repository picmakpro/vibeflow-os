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

Une erreur mecanique devient un controle execute, pas une ligne de regle de plus. Le script pose `nature` par une **heuristique lexicale grossiere** : les indices sont portes par l'**apprentissage** (titre et prose, jamais les lignes de metadonnees du registre) et se limitent a des motifs de controle sans ambiguite (lint, regex, grep, console.log, frontmatter, job ci, extension de script `.sh .json .yml .ts .js .py …`). Un mot courant (fichier, commit, chemin, import, hook, `.md`) **ne suffit pas**. **Le defaut est `jugement`** ; un faux `mecanique` reste possible (l'heuristique ne comprend pas la phrase), d'ou un tri humain avant tout controle (Phases C et D). Un cluster n'est `mecanique` que si tous ses membres le sont.

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

`findings` est un tableau (vide quand le depot porte au moins un garde-fou). `depot_sans_garde_fou` est **mesure** par le script sur la racine du lab du registre analyse (parent de `.claude/memory`) : aucun `.github/workflows/*.yml|*.yaml`, aucun `check-*.sh` sous `.claude/scripts/` ou `scripts/`, aucune configuration `.pre-commit-config.yaml`, `.husky/pre-commit` ou `.githooks/pre-commit`, aucun `.claude/settings.json` (ou `settings.local.json`) declarant au moins une **entree de hook non vide** — `{"hooks": {}}` n'en est pas une.

### Phase B — Draft auto (LLM)

Pour chaque candidat de nature `jugement`, l'agent (Claude) genere un draft `.claude/rules/_draft/[slug].md`. Pour un candidat `mecanique`, il genere un **brouillon de check** dans le meme dossier `_draft/`, sous `check-[slug].md` — jamais une prose de regle. Le brouillon nomme : le **type** (lint, hook ou job CI), le **motif exact** detecte, la **commande** qui le verifie et l'**emplacement cible** du controle (ex. `scripts/check-[slug].sh`, une entree de hook dans `.claude/settings.json`, un job de `.github/workflows/*.yml`). Il est soumis a la validation humaine (Phase C). Le draft de rule porte :

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

- ✅ Accepter, selon la nature :
  - `jugement` -> `mv _draft/[slug].md ../[slug].md` (la rule devient active) ;
  - `mecanique` -> le brouillon `check-[slug].md` est la **proposition de controle** : l'acceptation valide le controle et son emplacement cible, elle ne deplace **rien** sous `.claude/rules/`. Le controle (script `check-*.sh`, entree de hook, job CI) est ensuite pose a l'emplacement nomme par un geste humain ou un mandat de dev — jamais par la promotion — avec sa suite de test (trois issues et un mutant rouge) ; le brouillon est supprime une fois le controle pose.
- ❌ Rejeter -> garder en draft ou supprimer
- 🔄 Editer puis accepter

Cette etape est **obligatoire** et **non-automatisable** : rien n'est pose automatiquement, ni rule ni controle. Une rule active modifie le comportement de tous les futurs agents qui matchent son `paths:` ; un controle pose bloque ou avertit des gestes reels.

### Phase D — Mise a jour LEARNINGS

Pour chaque rule promue :

1. Les learnings sources sont mis a jour : `Encode dans: .claude/rules/[slug].md`
2. Si les learnings sont strictement contenus dans la rule -> archivage (pilier 2)
3. Sinon -> conserves en L2 (peuvent etre referenced dans contextes precis hors rule)

Pour chaque **controle pose** (candidate `mecanique`) : les learnings sources sont mis a jour avec `Encode dans: [chemin du controle]` (ex. `scripts/check-[slug].sh`) — jamais `.claude/rules/…`. Tant que le controle n'est pas pose a son emplacement, les learnings restent `Non encode` : une proposition acceptee mais non posee n'encode rien.

## Criteres pour une bonne rule (jugement)

Avant d'accepter un draft, verifier :

- [ ] **Concise** : ≤ 50 lignes (ADR-029 charte densite)
- [ ] **Imperative** : instructions, pas explications
- [ ] **Scopee** : `paths:` precis (pas trop large)
- [ ] **Sources tracees** : LRN-XXX cite en bas
- [ ] **Sans duplication** : ne contredit ni n'ecrase une rule existante

Pour un brouillon de **check** (mecanique) : [ ] type et emplacement cible nommes · [ ] verdict deterministe (code de sortie) · [ ] motif exact et commande de verification · [ ] cas rouge et cas vert prevus (un controle qui ne peut pas echouer ne prouve rien).
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
