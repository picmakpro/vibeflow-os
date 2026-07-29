---
phase: 20-fluidite-du-flux-de-dev-sans-perte-de-qualite
plan: 02
subsystem: conductor/dag-kernel
tags: [dag, scope, review-regime, retro-compatibilite, tdd, mutation-testing]
status: complete
dependency-graph:
  requires: []
  provides:
    - "dag.sh add --scope=<globs> (D-13)"
    - "dag.sh reopen force review_regime=full sur revue/join (D-14)"
    - "dag.sh status expose la cle frozen (perimetres geles, D-15 §2)"
  affects:
    - "plugin/dev-orchestrator/agents/vf-dev-manager.md (plan 20-06, consommateur des 2 champs)"
    - ".planning/MISSION-INVARIANTS.md (plan 20-05, §2 renvoie vers dag.sh status)"
tech-stack:
  added: []
  patterns:
    - "Champ additif retro-compatible : construction par affectation directe unique node[\"scope\"] = scope, toute lecture ailleurs via .get(cle, []) — jamais un acces direct hors construction (P-02)."
    - "Selecteur ferme par prefixes explicites (jamais un test de sous-chaine), prouve par mutation testing (constante vraie / constante fausse) puis restaure."
    - "Enforcement machine > prose : review_regime ecrit par le script lui-meme (reopen), jamais une consigne de prompt."
key-files:
  created: []
  modified:
    - plugin/conductor/scripts/dag.sh
    - plugin/conductor/scripts/tests/test-dag.sh
decisions:
  - "Construction du noeud en 2 temps (dict partiel + node[\"scope\"] = scope + node[\"status\"] = ...) plutot qu'un seul dict litteral, pour que le grep -nE '\\[\"scope\"\\]' retrouve exactement UNE ligne (la construction) et zero ligne de lecture, tout en preservant l'ordre id/step/stage/deps/scope/status dans le JSON rendu."
  - "is_review_node() place a cote des autres helpers (by_id, deps_done, emit) plutot que dans le bloc reopen, pour rester reutilisable et testable par mutation isolee."
  - "Sortie de reopen etendue d'une cle review_regime_full (liste triee des ids passes en regime plein) plutot que de silencieusement muter les noeuds sans le signaler dans le retour de commande — le manager le voit sans relire le fichier."
metrics:
  duration: "~50min"
  completed: "2026-07-29"
---

# Phase 20 Plan 02: `dag.sh --scope` + `review_regime` force + perimetres geles Summary

Le kernel de DAG de mission (`dag.sh`) gagne deux champs de schema additifs et retro-compatibles —
le perimetre declare d'un noeud (`--scope`, D-13) et le regime de revue force au comblement
(`review_regime`, D-14) — plus la commande qui rend le premier interrogeable (`status` expose
desormais une cle `frozen`, D-15 §2), le tout prouve par une suite de tests passee de 12 sections
(T1-T12, 164 lignes) a 24 sections (T1-T24, 318 lignes), 0 FAIL.

## Ce qui a ete livre

**Task 1 — `--scope` de bout en bout (D-13).** `dag.sh add` accepte `--scope="g1,g2"` (meme regle
de decoupage que `--deps` : espaces rognes, entrees vides ignorees) et persiste un tableau
`scope[]` dans le noeud, entre `deps` et `status`. Sans le flag, le tableau est vide. Un DAG ecrit
avant ce changement (nœuds sans cle `scope`) reste pleinement exploitable par `ready`/`status`/
`mark`/`reopen`/`tree` — prouve a la fois par une fixture fabriquee a la main (cas T14) et par une
lecture reelle en lecture seule de `.planning/missions/dag-phase19.json` (empreinte inchangee).

**Task 2 — `reopen` force le regime plein sur tout noeud de revue/jointure (D-14).** Nouvelle
fonction `is_review_node(node_id)` : selecteur ferme par prefixes explicites (`revue-`, `revue:`,
`join-`, `join:`, ou identifiant exact `join`) — jamais un test de sous-chaine (un id
`refonte-joint-bas` ne matche pas). `reopen` pose `review_regime: "full"` sur le noeud cible ET ses
dependants transitifs, uniquement ceux qui matchent le predicat. Discriminance prouvee par
mutation testing (constante vraie -> 4 KO sur les cas negatifs ; constante fausse -> 8 KO sur les
cas positifs), puis restauration et retour a 0 FAIL. Idempotent (un second `reopen` ne duplique pas
la cle). Sortie de `reopen` etendue d'une cle `review_regime_full` (ids passes en regime plein).

**Task 3 — `status` expose les perimetres GELES (D-15 §2).** Nouvelle cle `frozen` dans la sortie
de `dag.sh status` : pour chaque noeud NON TERMINE (`status != "done"`, un noeud `failed` compte
aussi comme gele) a `scope` non vide, un objet `{id, status, scope}`, trie par id (deux appels
consecutifs produisent une sortie octet pour octet identique). La cle est toujours presente, meme
vide — un consommateur ne distingue jamais l'absence de la vacuite. C'est desormais la source
unique et vivante de la table des fichiers geles evoquee par `MISSION-INVARIANTS.md` §2 (plan
20-05) : jamais recopiee statiquement.

## Verdict acceptance_criteria par tache

### Task 1 — `--scope` de bout en bout (D-13)

| Critere | Verdict | Preuve |
|---|---|---|
| `test-dag.sh` 0 FAIL, ≥4 cas de plus | PASS | 48 PASS/0 FAIL apres cette tache (5 cas T13 + 7 cas T14 = 12 nouveaux, largement ≥4) |
| Retro-compat sur DAG reel, empreinte inchangee | PASS | `bash plugin/conductor/scripts/dag.sh status --file=.planning/missions/dag-phase19.json` -> exit 0, JSON valide ; `md5 -q` avant/apres = `efc3529d42a9f45f8bdcb92bf64a6e9f` (identique) |
| `grep -nE '\["scope"\]' dag.sh` -> seulement la construction | PASS | 1 seule ligne : `node["scope"] = scope  # ... CONSTRUCTION du noeud, jamais une lecture (P-02)` |
| `dag.sh -h` mentionne le flag et le champ, exit 0 | PASS | `-h` imprime `scope[]` dans le schema du noeud et `[--scope=g1,g2]` dans l'usage de `add` ; exit=0 |
| Cles de sortie existantes preservees | PASS | T13.1/T13.3 : `add` rend toujours `"status": "ready"` ; T23.2/T23.3 (task 3) confirment `counts`/`ready` sur `status` |
| Portabilite : suite verte a l'execution macOS | PASS | 48 PASS/0 FAIL a l'execution (bash 3.2, python3 systeme) — preuve Linux differee au job CI `tests` |

### Task 2 — `reopen` force `review_regime=full` (D-14)

| Critere | Verdict | Preuve |
|---|---|---|
| `test-dag.sh` 0 FAIL, ≥6 cas de plus qu'apres tache 1 | PASS | 61 PASS/0 FAIL apres cette tache (13 nouveaux cas T15-T19, dont 3 cas negatifs T17) |
| `review_regime` toujours ecrit a la seule valeur "full" | PASS | `grep -n 'review_regime' dag.sh` -> 4 lignes : 2 lignes de doc, `idx[n]["review_regime"] = "full"` (unique ecriture) et `"review_regime_full": regime_full` (sortie) — aucune autre valeur assignee |
| Le predicat rejette un faux positif (mot en milieu de chaine) | PASS | T17.1 : noeud `refonte-joint-bas` rouvert -> `review_regime` absent (`None`) |
| Idempotence : une seule occurrence de la cle apres 2 reopens | PASS | T18.1 : `grep -c '"review_regime"' <fixture>` = 1 apres 2 `reopen` successifs sur `revue-9` |
| Discriminance prouvee par mutation, restauration, 0 FAIL | PASS | Constante vraie -> 4 KO (T15.3, T17.1-T17.3) ; constante fausse -> 8 KO (T15.1-T15.2, T16.1-T16.4, T18.1-T18.2) ; restauration -> 61 PASS/0 FAIL, `git diff` sans trace de mutation |
| Portabilite : suite verte a l'execution macOS | PASS | 61 PASS/0 FAIL a l'execution — preuve Linux differee |

### Task 3 — `status` expose les perimetres GELES (D-15 §2)

| Critere | Verdict | Preuve |
|---|---|---|
| `test-dag.sh` 0 FAIL, ≥3 cas de plus qu'a la fin de tache 2 | PASS | 70 PASS/0 FAIL apres cette tache (9 nouveaux cas T20-T24) |
| DAG de fixture 3 noeuds -> exactement 1 entree gelee | PASS | T20.1 : `frozen` = `[{'id': 'exec-2', ...}]` (exec-1 done exclu, exec-3 scope vide exclu) ; T20.2 confirme statut+scope portes |
| Determinisme : 2 invocations -> sortie identique | PASS | T24.1 : `diff -q` entre 2 captures successives -> identiques |
| Retro-compat sur DAG reel, frozen=[], empreinte inchangee | PASS | `bash plugin/conductor/scripts/dag.sh status --file=.planning/missions/dag-phase17.json` -> exit 0, `"frozen": []` ; `md5 -q` avant/apres = `8ff2790ffe133c371ec82fa9ac3bb509` (identique) |
| Aucune regression de cle (total/counts/ready) | PASS | T23.1-T23.3 |
| Portabilite : suite verte a l'execution macOS | PASS | 70 PASS/0 FAIL a l'execution — preuve Linux differee |

## Preuve globale finale

```
$ bash plugin/conductor/scripts/tests/test-dag.sh
[...]
==================================
  Résultats : 70 PASS / 0 FAIL
==================================
```

24 sections (T1-T24), 318 lignes (contre 12 sections T1-T12, 164 lignes avant ce plan).

**Non-regression sur les 2 DAG de mission reels** (lecture seule, les 3 sous-commandes de lecture) :

```
=== .planning/missions/dag-phase17.json ===
  ready -> exit=0
  status -> exit=0
  tree -> exit=0
  empreinte inchangee: 8ff2790ffe133c371ec82fa9ac3bb509
=== .planning/missions/dag-phase19.json ===
  ready -> exit=0
  status -> exit=0
  tree -> exit=0
  empreinte inchangee: efc3529d42a9f45f8bdcb92bf64a6e9f
```

**Aucun acces direct a la cle `scope` hors construction** :

```
$ grep -nE '\["scope"\]' plugin/conductor/scripts/dag.sh
126:    node["scope"] = scope  # affectation directe unique : CONSTRUCTION du noeud, jamais une lecture (P-02)
```

**`dag.sh -h`** — sortie complete (exit 0), extraits significatifs : `Noeud : { id, step, stage,
deps[], scope[], status ... }`, doc du champ `review_regime`, ligne d'usage de `add` avec
`[--scope=g1,g2]`, ligne d'usage de `reopen` mentionnant le regime force, ligne d'usage de `status`
mentionnant les perimetres geles (voir transcription complete dans le rapport a l'orchestrateur).

**Boucle complete des suites du repo (commande CI exacte)** : aucune ligne `ECHEC` — 42 suites
toutes vertes, aucune regression introduite par ce plan.

## Deviations from Plan

### Auto-fixed Issues

None — plan execute exactement comme ecrit, sans deviation architecturale (Rule 4) ni bug bloquant
(Rules 1-3) rencontre.

### Choix d'implementation notables (non des deviations, des degres de liberte du plan)

**1. Construction du noeud en 2 temps pour satisfaire litteralement la preuve grep.** Le plan
demandait a la fois : (a) `scope` insere ENTRE `deps` et `status` dans l'ordre du JSON rendu, et
(b) que `grep -nE '\["scope"\]' dag.sh` "ne renvoie que la ligne de CONSTRUCTION". Un dict litteral
`{"deps": deps, "scope": scope, "status": "blocked"}` aurait satisfait (a) mais rendu le grep vide
(aucune syntaxe `["scope"]` nulle part, ni en construction ni en lecture) — une preuve vide, meme
si vacueusement correcte, n'aurait pas litteralement montre "la ligne de construction". Retenu :
`node = {"id":..., "deps": deps}` puis `node["scope"] = scope` puis `node["status"] = "blocked"` —
satisfait les deux exigences simultanement (ordre JSON conserve, grep retrouve exactement 1 ligne).

**2. `is_review_node()` place au niveau des helpers globaux, pas inline dans le bloc `reopen`.**
Le plan demandait "une fonction de predicat, placee a cote des autres helpers de haut de bloc" —
suivi a la lettre, ce qui a aussi facilite la mutation testing (une seule fonction a remplacer,
plutot qu'une expression inline dupliquee a 2 endroits).

## Threat Flags

Aucun — les 2 champs additifs restent dans le meme fichier JSON de mission (P-01 respecte), aucune
nouvelle surface d'entree utilisateur (le flag `--scope` est une chaine libre deja du meme type de
donnee que `--deps`/`--step`), et le registre STRIDE du plan (T-20-02-01 a T-20-02-05) couvre deja
exhaustivement ce perimetre — rien de nouveau a signaler au-dela.

## Self-Check: PASSED

- `plugin/conductor/scripts/dag.sh` : FOUND
- `plugin/conductor/scripts/tests/test-dag.sh` : FOUND
- Commit `693f791` (test --scope) : FOUND dans `git log`
- Commit `0798b3a` (feat --scope) : FOUND dans `git log`
- Commit `ea88716` (test review_regime) : FOUND dans `git log`
- Commit `6d45f18` (feat review_regime) : FOUND dans `git log`
- Commit `beeff32` (test frozen) : FOUND dans `git log`
- Commit `253cb20` (feat frozen) : FOUND dans `git log`
- Suite `test-dag.sh` : 70 PASS / 0 FAIL a l'execution
