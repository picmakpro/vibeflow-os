# Reference — Pilier 3 : Fusion LLM-based

> Sous-document du skill `consolidator`. Detail technique du pilier Fusion.

## Probleme resolu

Trois sources de doublons dans les registres :

1. **Collisions d'IDs** : 2 sessions paralleles attribuent le meme ID a 2 entrees distinctes (ex : LRN-090 vu en double dans le Lab).
2. **Doublons semantiques** : 3 learnings differents capturent essentiellement la meme idee (ex : "tests integration > mocks", "ne pas mocker la DB", "verifier en conditions reelles").
3. **Doublons de blockers** : meme erreur rencontree dans 2 sprints, capturee 2 fois sans cross-reference.

## Approche : LLM trie, pas ML

Pourquoi pas d'embeddings + clustering ?
- **Surdimensionne** pour registres < 500 entrees
- **Stack supplementaire** a maintenir (sentence-transformers, sklearn, vectordb)
- **Faux positifs frequents** sur similarites de surface

Pourquoi LLM ?
- **Anthropic Auto Dream phase 3 (2026)** valide l'approche en production
- **dream-skill (45K stars)** utilise grep + LLM avec succes
- **Contexte semantique** : le LLM comprend "tests integration" et "verifier en conditions reelles" comme equivalents

## Pipeline 3 phases

### Phase A — Detection (script bash)

`detect-duplicates.sh` sort un JSON de **candidats** selon signaux faciles, sans LLM :

1. **IDs identiques** : collision -> bloquant, action obligatoire
2. **Titres tres similaires** : Jaccard tokens > 0.7
3. **Meme tag + meme categorie + dates < 7j**
4. **Memes mots-cles d'introduction** (3 premiers tokens du body identiques)

Output :

```json
{
  "collisions": [
    {"id": "LRN-090", "occurrences": 2, "lines": [1299, 1617]}
  ],
  "similar": [
    {
      "candidates": ["LRN-014", "LRN-088"],
      "similarity_score": 0.78,
      "reason": "Jaccard tokens titre > 0.7"
    }
  ]
}
```

### Phase B — Proposition (LLM)

L'agent (Claude) lit les candidats et propose pour chacun :

- **Merge** : fusionner en une seule entree. ID conserve = le plus ancien. Body fusionne (le LLM redige).
- **Keep** : faux positif, garder distincts (raison explicitee).
- **Archive** : l'un des deux est obsolete vs l'autre. Le plus recent est conserve, l'autre archive.

Prompt type pour le LLM :

```
Tu lis 2 entrees du registre LEARNINGS.md d'un lab VibeFlow.
Decide si elles capturent la meme idee (Merge), des nuances differentes (Keep), ou si l'une est obsolete vs l'autre (Archive).

Critere Merge : les 2 entrees changent la meme decision/action future. Le merge ne perd aucune information.
Critere Keep : les 2 entrees apportent des nuances que tu ne voudrais pas perdre.
Critere Archive : l'une des 2 est strictement contenue dans l'autre OU contredit par la realite actuelle.

[ENTREE 1]
{contenu LRN-XXX}

[ENTREE 2]
{contenu LRN-YYY}

Reponds en JSON : {"action": "Merge|Keep|Archive", "reason": "...", "merged_body": "..." (si Merge), "kept_id": "..." (si Archive)}
```

### Phase C — Application

Apres validation humaine :

1. **Merge** :
   - Body fusionne ecrit a la place du plus ancien
   - L'autre entree est archivee avec note `merged_into: LRN-XXX`
   - Index regenere (`reindex.sh`)
2. **Keep** : pas d'action, just log
3. **Archive** : entree obsolete deplacee vers `archive/`, l'autre reste

## Cas particulier : collision d'IDs

C'est un bug structurel a corriger en priorite. Le script propose :

```
LRN-090 a 2 occurrences :
  - Line 1299 : "Mobile = fork structurel (35-40% nouveau)"
  - Line 1617 : "Packaging boilerplate v4.1-pc — pattern snapshot"

Resolution : renommer le plus recent en LRN-096 (premier ID libre)
  - Line 1617 : LRN-090 -> LRN-096
  - Cross-references mises a jour
```

## Quand declencher

- **Au /vf-audit** : detection automatique, propositions affichees au user
- **Manuel** : `/consolidate --pillar=fusion`
- **Apres un /session-close** ou apparait une nouvelle entree avec ID conflictuel : detection immediate

## Anti-patterns

- ❌ Auto-merge sans validation (perte d'information possible)
- ❌ Embeddings vectoriels (over-engineering)
- ❌ Merge cross-categorie (ex : un BLK et un LRN ne se mergent pas — ils sont relies)
- ❌ Merge cross-registre (ADR-022 et LRN-082 ne se mergent jamais, meme si themes proches)

## Output rapport

`reports/consolidation/YYYY-MM-DD-consolidation.md` section Pilier 3 :

```markdown
## Pilier 3 — Fusion

### Collisions resolues
- LRN-090 (Line 1617) renomme en LRN-096 ✅
- LRN-091 (Line 1649) renomme en LRN-097 ✅

### Merges appliques (1)
- LRN-014 + LRN-088 -> LRN-014 (verification multi-niveaux)
  Reason : memes patterns, LRN-088 est une precision tactique de LRN-014.
  Body fusionne : voir LRN-014 mis a jour.

### Keeps (3)
- LRN-019 vs LRN-058 : nuances importantes (architecture vs articulation)
- ...
```

## Limites connues

- **Detection grossiere** : un titre tres different qui cache le meme apprentissage echappera a la phase A.
- **LLM peut hesiter** : si phase B retourne `confidence < 0.7`, marquer comme `Keep` par defaut.
- **Cout LLM** : sur 100 candidats, ~$0.05-0.10 si Sonnet (acceptable au rythme mensuel).
