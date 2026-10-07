# Mission 2026-10-07 — Phase 46.1 (gouvernance) : cadrage et planification de l'armement de G4 et G4′

**Manager :** `vf-dev-manager-p461-cadrage`
**Feu vert :** Willy, message en session principale, 2026-10-07 (« Oui lance »).
**Branche :** `gouvernance/phase-46.1-cadrage`, partie de `origin/gouvernance/phase-46-execution` @
`78808126` (PR #136, empilée #133 → #124), worktree `.claude/worktrees/gouvernance-46-1`.
**Compartiment :** `gouvernance` (`--ws gouvernance`).
**Verrou :** acquis, génération `DRIVER.lock.gen.1791361612.53884`, 0 orphelin ; relâché en fin de
session (attente humaine).
**Invariants :** `check-mission-invariants.sh` → 3 (SAIN).
**Flags d'enchaînement :** `workflow._auto_chain_active` et `workflow.auto_advance` déjà à `false`,
vérifiés par lecture de `.planning/config.json` (`gsd_run` non résolu sur ce poste).
**Budget :** snapshot posé (`check-mission-exit.sh --budget-snapshot`, fichier
`/Users/makwilmak/vibeflow-os/.git/vf-mission-budget.snap`, partagé entre worktrees : une autre
session peut l'écraser).
**Issue :** `human_needed` — cadrage gelé dans l'attente des réponses de Willy à Q1-Q5.

## Plan de bataille (DAG `2026-10-07-gouvernance-46-1-cadrage.dag.json`)

`scouting-461` ∥ `recherche-461` → `discuss-461` → `plan-461` → `plancheck-461` → `suivi-461` →
`pr-461`

## Déroulé

1. **Relevés parallèles, lecture seule** (commit `28b7d782`) :
   - `46.1-SCOUTING.md` : les 343 refus G4 de l'étape 5 sont tous des réécritures à l'identique,
     par `Write`, de `SUMMARY.md` existants sur `~/jarvis-keystone` (336 niveau plan, 7 niveau
     phase), dans des unités sans `VERDICT.md` ni `CLOTURE.md` ; le banc n'a aucun cas
     `doit-refuser` sur un `SUMMARY.md` existant ; ces 343 bloquent aussi l'étape 6. A2, A3, A4, P1,
     remèdes de D1 et (bu) établis chemin:ligne.
   - `46.1-RECHERCHE-HOOKS.md` (Claude Code 2.1.292) : le payload ne dit pas quel fichier de
     définition est chargé ; `cwd` suit les `cd`, `CLAUDE_PROJECT_DIR` est fixe mais = dossier de
     lancement ; **le compteur de relances natif repart à zéro à chaque appel d'outil** (le
     plafond de 8 ne borne pas une boucle G4′ qui fait lancer Bash) ; `stop_hook_active`
     absent/null au premier passage ; `SubagentHandback` seulement en auto mode.
2. **Cadrage** : cinq questions envoyées d'un bloc par `SendMessage(main)` (repli D-09), avec
   recommandation — détail et options : `46.1-DISCUSSION-LOG.md` (commit `42bf54c4`). Aucune
   réponse reçue après environ cinq heures d'attente au premier plan ; nœud `discuss-461` gelé,
   aucune décision humaine supposée.

## Questions en attente (Willy)

Q1 unités antérieures à G4 (recommandé : exemption étroite de la réécriture sans `VERDICT.md` ni
`CLOTURE.md`) · Q2 A2 (recommandé : jugé dès ambiguïté) · Q3 A3 (recommandé : union `cwd` /
`CLAUDE_PROJECT_DIR`) · Q4 A4/P1 (recommandé : compteur par agent_id sous verrou, un blocage puis
passage tracé, panne du cœur fail-open tracé) · Q5 D1 (recommandé : N-5 et A5 dans la 46.1, le
reste en limites + BACKLOG).

## Décisions du manager annoncées (renversables)

(bu) par script de décision versionné et testé ; ordre P46-D-11 (5b puis 6) avec checkpoint humain
au moment de chaque rejeu réel et armement ; aucune sonde `claude -p` ; `planning-core` v2.11.0
sans release ; préfixe `ARMG` (vérifié libre par `git grep`), décisions `P461-D-xx`.

## Constats à relayer

- La recherche a observé que la session de mission tourne en `bypassPermissions` (0 hand-back sur
  60 sous-agents) : observation de poste, aucun drapeau posé par un worker.
- Écarts documentaires de la 46 non corrigés (lecture seule) : `modele-cycles.md:1147` (« relevé
  de l'étape 6 à venir ») contredit `:1059` ; `46-RESEARCH.md:379` démenti par le relevé de
  l'étape 5. À prendre dans les plans de la 46.1.

## Décompte

Mandats émis : 2 (`general-purpose` scouting, 313 952 jetons ; `general-purpose` recherche,
178 134 jetons), 0 reprise. Tours de revue : 0. Commits : `28b7d782`, `42bf54c4`, plus celui de ce
rapport.

## Preuves E6

Aucune : aucun sprint `vf-coder` exécuté dans cette mission.

## Next step

Relayer Q1-Q5 à Willy (AskUserQuestion), puis relancer la mission sur les réponses : écriture de
`46.1-CONTEXT.md`, exigences `ARMG`, puis `plan-461` (`vf-coder`, `gsd-plan-phase 46.1 --ws
gouvernance`), plan-check frais, PR empilée sur #136.
