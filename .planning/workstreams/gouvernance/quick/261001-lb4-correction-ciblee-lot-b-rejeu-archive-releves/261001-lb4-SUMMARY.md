---
quick_id: 261001-lb4
status: complete
description: Correction ciblée du lot B de la Phase 45 (outillage de rejeu, archive du socle v2, relevés) — H3, M3/m8, B2/m7, B3 (partie rejeu)
base: e13a426
commits: [10b1f5f, 239a1e5, 1ec75c1]
---

# Quick 261001-lb4 — correction ciblée, lot B (nœud fix-45-B)

Décisions du manager (vf-dev-manager, 2026-10-01), renversables. Chaque constat : test rouge sur la version précédente,
correctif, vert, preuve par mutation. Aucun cas supprimé, aucun mutant retiré.

| Id | Correctif | Rouge -> vert | Mutants | Commit |
|----|-----------|---------------|---------|--------|
| H3 | `sous_copie` (realpath sous la copie, code 1) avant tout makedirs/open/rename ; payload par lstat + régulier ; refus préalable de `rejeu-reel.sh` | 11 rouges -> 0 | REJEU-GARDE-LIEN, REJEU-LECTURE-REGULIER, REJEU-AGENTS-LIEN, REEL-LIEN-SORTANT | 10b1f5f |
| B2 | `<lab-N>` hors HOME, caractères de contrôle échappés, rapport sous un lab par `samefile` | 9 rouges -> 0 | REJEU/REEL-GENERIQUE, REJEU/REEL-NEUTRALISER, REEL-SAMEFILE | 10b1f5f, 1ec75c1 (relevés) |
| B3 | parcours itératif de `rejeu-reel.sh`, RecursionError et OSError rattrapées | 3 rouges -> 0 | REJEU-RECURSION, REEL-PROFONDEUR | 10b1f5f |
| M3/m8 | gardes d'écriture avant l'archivage, archive tout ou rien, nom suffixé, jamais de réécriture | 6 rouges -> 0 | GATE14-DEJA, -PREALABLES, -GENERE, -RENAME, -ECRASE (adapté) | 239a1e5 |

## Adaptations d'attendus (dites, non silencieuses)

- R-GATE14-ARCHIVE « second passage » et « cible préexistante » : leur attendu (`_archive` identique, aucune archive en plus)
  documentait la perte du manuscrit ; désormais archive existante intacte ET manuscrit archivé sous `socle-v2.2`.
- MUT-GATE14-ECRASE : motif déplacé sur le choix du nom de la nouvelle archive (l'ancienne ligne n'existe plus) ; attendu « SENTINELLE
  intacte » conservé, complété par `socle-v2.2`.

## Décisions de conception à valider par le manager

- Un STATE.md/INDEX.md qui porte la marque de génération de recalc-planning n'est pas « manuscrit » et n'est pas archivé (sinon un
  instantané par passage). Limite : un manuscrit qui imiterait la marque ne serait pas copié.
- Liens refusés par `rejeu-reel.sh` seulement sur les chemins que le rejeu écrit ou lit (cycles/, phases/, STATE.md & noms G6,
  config.json, CADRAGE.md, PLAN.md, VERDICT.md, `.claude`, `.claude/agents`) ; un lien sortant ailleurs ne bloque pas (témoin).
- Un lien dont la cible résout DANS le lab est suivi ; la garde protège la copie, pas l'existence du lien.

## Limites déclarées

- Volume (25 000 fichiers, plus de 300 s) : non optimisé, comme demandé.
- `parcourir` de `rejeu-gates.sh` reste récursif : erreur propre (code 1, message), pas de parcours itératif.
- Mutants conditionnels à la plateforme : REEL-SAMEFILE (système de fichiers insensible à la casse, APFS ici) et REEL-PROFONDEUR
  (PATH_MAX < longueur de l'arbre de 1 600 niveaux) ; sur une autre plateforme la suite l'annonce « non applicable ». Le test
  d'itération (limite de récursion abaissée) est, lui, portable.
- L'historique git garde les anciennes versions des relevés (nom de compte, PID) ; aucune réécriture d'historique.
- Un OSError tardif d'`appliquer_ecritures` après archivage laisse une archive (copie fidèle du manuscrit encore en place), jamais une perte.

Exécution directe par vf-coder, worktree partagé avec le lot A ; aucun exécuteur isolé.
