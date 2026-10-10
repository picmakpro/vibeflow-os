---
phase: 57-verrou-de-driver-par-compartiment
plan: 08
subsystem: conductor
tags: [guard, driver-lock, workstream, fail-closed, hooks, git]
requires:
  - phase: 57-05
    provides: guard-driver-lock.sh jugeant les Write/Edit par compartiment, fail-closed, git_hardened, discover_locks
provides:
  - "volet Bash du guard partitionné : jugement de commit sur l'union des sources, trois classes de gestes, même worktree"
key-files:
  modified: [plugin/conductor/scripts/guard-driver-lock.sh, plugin/conductor/scripts/tests/test-guard-driver-lock-ws.sh]
key-decisions:
  - "Aucun verrou tenu par autrui : sortie avant tout git diff (DLWS-06 « empty », volet commit)"
  - "Cartographie des chemins en octets (sortie -z découpée sur NUL, aucune normalisation) ; motif : 3 chemins max, json.dumps ASCII, 120 caractères"
requirements-completed: [DLWS-02, DLWS-06]
status: complete
completed: 2026-10-10
---

# Phase 57 Plan 08: Volet Bash du guard par compartiment Summary

**Un commit est jugé sur ce qu'il embarque (index, -a/pathspec, HEAD sous --amend, git add de la même commande), les gestes git sont répartis en arbre / commit / dépôt, et toute source illisible rend un refus JSON, jamais une ouverture ; lab plat inchangé.**

## Cas ajoutés (suite neuve : 71 -> 160 assertions, 14 s)
GW-C-IDX · GW-C-EMPTY · GW-NOLOCK (sonde git factice : aucun `diff`, témoin `rev-parse` vu) · GW-C-REN · GW-C-NONASCII · GW-C-ALL · GW-C-PATH · GW-C-AMEND · GW-C-ADD · GW-C-REL (VERSION, docs/ADR.md, .planning/BACKLOG.md) · GW-C-CORRUPT · GW-C-NOGITBIN · GW-T-SAME · GW-T-OTHERWT · GW-T-EXEMPT · GW-T-REMOVE · GW-T-C · GW-D-PUSH · GW-D-TAG · GW-MARK-B. Chacun avec sa contre-épreuve (détenteur, voisin, forme sans `-a`).

## Déviations
1. **P57-D-33 : aucune déviation.** Précision de lecture : `-C` vers un dossier hors du lab reste permis par C7 (inchangé) ; la règle « cible incertaine = refus » ne joue que pour une cible dans le périmètre du lab (GW-T-C-3).
2. **Fixture GW-T-C** rouge à la première exécution (cwd = l'autre worktree, donc cible hors périmètre, C7) : corrigée dans la suite, aucun défaut du guard.
3. **Mutations** : non rejouées ici, prouvées par 57-11 (GW-M-a, b, e, f, i, j, k) ; les contre-épreuves ci-dessus tiennent lieu de discriminance en attendant.
4. Un `grep -v` proxifié par rtk a écrasé la suite en cours de rédaction ; restaurée depuis HEAD (aucune perte, rien de commité).

## Commits
`6bebf12f` RED tâche 1 · `d86851bf` GREEN tâche 1 · `ff491c2b` RED tâche 2 · `2210d4f6` GREEN tâche 2

## Self-Check: PASSED
Suite neuve 160/0 ; `test-guard-driver-lock.sh` 103/0 ; `test-driver-lock-ws.sh` 492/0 ; `test-hook-exit-contract.sh` 40/0 ; `test-hook-exit-parc.sh` 42/0 ; diff vide des deux suites existantes et de `plugin/conductor/hooks` contre la base. `check-version-sync.sh` rouge (compte de suites) : attendu jusqu'à 57-15.
