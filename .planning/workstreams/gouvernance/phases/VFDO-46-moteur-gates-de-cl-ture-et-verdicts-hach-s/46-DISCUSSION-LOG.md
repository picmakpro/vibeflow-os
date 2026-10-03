# Phase 46 — Discussion log

**Date :** 2026-10-03
**Manager :** `vf-dev-manager-p46-cadrage`
**Canal :** Willy, AskUserQuestion session principale, 2026-10-03. Les questions ont été relayées
par la session principale (repli D-09 : pas d'outil de question en sous-agent), et les réponses
rendues par le même relais.
**Feu vert de la mission :** Willy, message en session principale, 2026-10-03 (« go lance le
cadrage de 46 en parallèle »), pendant la relecture de la PR #124 par Samuel.

## Déroulé

1. Deux recherches parallèles en lecture seule :
   - doc des hooks Claude Code 2.1.288 (ADR-045) → `46-RECHERCHE-HOOKS.md` ;
   - état des lieux des acquis 44/45 → `46-SCOUTING.md`.

   La sonde `claude -p` du chercheur a été refusée par la garde d'isolation du worktree ; elle
   n'a pas été contournée (Q8).
2. Huit questions de zone grise envoyées d'un bloc à la session principale, avec les faits, les
   options et une recommandation par question, plus la liste des décisions que le manager
   prendrait lui-même.
3. Réponses de Willy : la recommandation sur les huit (Q7 = b, les autres = a). Les décisions du
   manager lui ont été signalées comme renversables.

## Questions, options, choix

| # | Question | Options | Choix |
|---|---|---|---|
| Q1 | Accroche de G3/G4 | (a) `PreToolUse` deny du hook central sur `CLOTURE.md`/`SUMMARY.md`, spec §5 amendée · (b) (a) + `TaskCompleted` en complément · (c) `TaskCompleted` seul, outils Task exigés | **(a)** |
| Q2 | G4′ : accroche et périmètre | (a) `PreToolUse(SubagentHandback)` + repli `SubagentStop`, workers et producteurs seuls, juges exclus · (b) idem, tous les sous-agents · (c) `SubagentStop` seul | **(a)** |
| Q3 | Ce que le verdict hache | (a) plan + livrables, vérifiés à `SUMMARY.md` · (b) plan seul · (c) livrables seuls | **(a)** |
| Q4 | « Verdict passé, SUMMARY absent » | (a) neuvième état `à clore` · (b) garder `indéterminé` | **(a)** |
| Q5 | Plafond de tentatives | (a) 3, constante du code, dérogation au-delà · (b) aucun · (c) dans `config.json` protégé | **(a)** |
| Q6 | Canary de juge C-16 | (a) contrat + vérificateur déterministe, « juge sans preuve » jamais vert, premier passage par le manager jusqu'à la 48 · (b) `claude -p` scripté · (c) reporter | **(a)** |
| Q7 | D1 | (a) `FileChanged` seul · (b) `FileChanged` + réconciliation par hash au `SessionStart` · (c) reporter | **(b)** |
| Q8 | Sonde refusée | (a) documentation + canaries, limites déclarées · (b) sonde jouée hors worktree | **(a)** |

## Décisions du manager signalées à Willy

Un script avec un mode par événement ; l'ordre d'armement prolongé ; la définition de « vide » ;
le seuil de juge renvoyé à la Phase 50 ; le bump mineur sans release ; le préfixe `CLOT`. Elles
deviennent P46-D-09 à P46-D-19 dans `46-CONTEXT.md`, avec les sous-décisions P46-D-02a, 03a, 03b,
06a et 07a.
