---
quick_id: 261002-brz
workstream: gouvernance
phase: 45
type: quick
description: pré-filtre hors adhésion dans la commande enregistrée du hook central (revue Samuel, PR #124)
autonomous: true
---

# Quick 261002-brz — pré-filtre hors adhésion (revue Samuel, PR #124)

Origine : revue CHANGES_REQUESTED de Samuel du 2026-10-01 (le hook coûte ~82 ms par Write, ~52 ms par Bash, ~50 ms par Agent
dans un lab non adhérent, pour finir sur `sys.exit(0)`). Arbitrage de Willy (AskUserQuestion session principale, 2026-10-02) :
le pré-filtre seul, Bash RESTE dans le matcher, le matcher n'est pas touché. Décisions actives : Q-ARM (Willy, AskUserQuestion
session principale, 2026-09-30 : aucun cas ni mutant supprimé ou affaibli), GATE-03, GATE-10, P45-D-10.

Note d'exécution : le plan a été écrit par le worker lui-même, sans gsd-planner ni gsd-plan-checker (aucun sous-agent n'a été
lancé pour la planification) ; la vérification post-exécution (--validate) est rendue par gsd-verifier, voir le SUMMARY.

## Tâches

1. Pré-filtre shell `vf_pre` en tête de la commande de `plugin/planning-core/hooks/hooks.json`, avant tout lancement du script,
   de mktemp ou de python3 ; même texte dans `COMMANDE_REFERENCE` de `check-gates-alive.sh`. Règle : court-circuit UNIQUEMENT si
   le lab est certainement non adhérent ; sinon chemin d'avant inchangé octet pour octet. Plus conservateur que le cœur.
2. Garde d'équivalence `test-planning-prefilter.sh` : (A) SHORT ⇒ sortie vide, rc 0 (sans pré-filtre et complète, script présent
   et absent) ; (B) jamais SHORT là où le cœur juge adhérent ; (C) quatre shells d'accord ; (D) différés par construction ;
   (E) DEFER ⇒ sortie identique à la commande sans pré-filtre ; corpus : banc, arbres adverses, valeurs longues, arbres aléatoires ;
   mutants (i) sortie trop tôt, (ii) sans résolution physique, (iii) valeur longue ou échappée acceptée.
3. Suites existantes : les mutants de la couche shell et du cœur rejouent la commande sans le bloc ; la commande complète est
   ajoutée en regard ; R-REFERENCE étendu.
4. Mesure avant/après (Write, Bash, Agent ; ≥ 30 rejeux ; dépôt et lab adhérent synthétique).
5. Doc : modele-cycles.md, HOOKS-CONTRAT-SORTIE.md n°32, CHANGELOG v2.9.0. Pas de bump.
6. Non-régression des suites listées ; rejeu réel en lecture seule (conditions de repos).

## Critères de succès

- Zéro désaccord sur tout le corpus ; chaque mutant rougit la garde avec sa trace.
- Dépôt (lab dev) : six outils, script présent et absent → rc 0, 0 octet.
- Suites vertes ; `45-CONTROLE-MARQUEUR.sh` → sans-marqueur=0.
