---
quick_id: 261002-brz
status: incomplete
commit: 06cafdda
---

# Quick 261002-brz — pré-filtre hors adhésion (revue Samuel, PR #124)

Arbitrage de Willy (AskUserQuestion session principale, 2026-10-02) : pré-filtre seul, Bash reste dans le matcher.

## Livré (commit 06cafdda, non poussé)

- `vf_pre && exit 0` en tête de la commande de `hooks.json` et de `COMMANDE_REFERENCE` (check-gates-alive.sh), texte identique.
  Règle : court-circuit seulement si toutes les valeurs file_path / notebook_path / cwd, `$PWD` et le cwd physique sont absolues, propres,
  de 4096 caractères au plus, sans antislash ni `/.vol`, JSON sur une ligne sans échappement `\u00xx` ; et si chaque ancêtre (lexical
  et physique) n'a aucun `.planning/config.json` portant `cycles-v1` (casse ignorée) ou illisible / non régulier. Plus conservateur que le cœur.
- Garde `test-planning-prefilter.sh` : 19 OK / 0 KO ; équivalence sans désaccord sur banc (1308 cas, 210 court-circuits), arbres adverses
  (7595, 315), générateur de valeurs longues (300, 0), arbres aléatoires (1200, 345), shells sh/dash/bash/zsh ; 12 mutants tués avec trace.
- Suites existantes adaptées sans rien supprimer ; doc (modele-cycles.md, HOOKS-CONTRAT-SORTIE.md n°32, CHANGELOG v2.9.0).

## Mesure (/bin/sh, 40 rejeux entrelacés par outil, avant = e65c73f4, médiane / p90 en ms)

Dépôt : Write 45,0/46,1 → 12,4/12,7 ; Bash 45,0/46,8 → 12,1/12,4 ; Agent 45,3/46,6 → 12,1/12,3.
Lab adhérent synthétique : Write 45,2/45,8 → 49,4/50,1 ; Bash 45,2/48,8 → 49,4/51,0 ; Agent 45,3/50,6 → 49,4/59,1 (+4 ms, coût du pré-filtre qui différe).
Load average 7,2 au lancement (machine pas au repos).

## Non-régression (après le dernier changement de code)

test-planning-gates 461/0 ; test-planning-hook-registered 90/0 ; test-rejeu-gates 91/0 ; test-planning-hook-installed 23/0 ;
test-role-hook-vs-check-agents 6/0 ; test-recalc-planning 358/0 ; test-check-hook-paths 17/0 ; check-machine-paths vert ;
45-CONTROLE-MARQUEUR : sans-marqueur=0.

## Non abouti

- Vérification gsd-verifier (--validate) : interrompue par la limite de compte (HTTP 429), aucun rapport produit.
- Rejeu réel : NON joué, laboratoires actifs au contrôle de repos du 2026-10-02 20:38 (processus avec cwd sous BusinessFlow-Lab : 11 ;
  transcripts de moins de 30 min : 2 ; jarvis-keystone : 0 processus, 0 fichier ouvert). Statut blocked, à rejouer lab au repos.
