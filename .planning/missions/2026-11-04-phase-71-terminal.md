# Mission Phase 71 — terminal intégré au cockpit (2026-11-03 → 2026-11-04)

Manager : `vf-dev-manager` (`mgr71`), worktree `.claude/worktrees/phase-71`, branche `feat/phase-71-terminal` (base `7370d604`).
Jalon `vibeflow-v2.0`, compartiment `fiabilite`. Verrou de phase `--ws=fiabilite --phase=71`, génération `DRIVER.lock.gen.1793730559.13649`.
Périmètre : cadrage, plan validé par plan-checker, exécution, revue, audit de sécurité complet, rejeu du job `gates`, push sans PR ni release.

## Plan de bataille (DAG `MISSION-71.dag.json`)

research-71 (panel 2 chercheurs + spike Chrome) → ask-71 (Q1-Q7 à Samuel) → discuss-71 (cadrage par le manager) → plan-71 (vf-coder, 3 tours de
plan-checker internes + 2 passages frais) ∥ craft-terminal (vf-crafter) → ex-01 → {ex-02, ex-03, ex-04, ex-10, ex-11} → ex-05 → ex-06 →
{ex-07, ex-08} → ex-09 ; revue-71 ∥ audit-71 ∥ critique-terminal ; fix-pty, fix-origin (en cours d'exécution) ; fix-a1 ∥ fix-a2 ; fix-b (B1 ∥ B2 ∥ B3,
après validation de Samuel) ; rejuge (re-revue ∥ re-audit) ∥ docs ; fix-c ; fix-n1 ∥ fix-n2 ; reaudit-n ; fix-d ; fix-e ; push-71.

## Arbitrages de Samuel (AskUserQuestion, session principale Claude Code, relayés au manager)

P71-D-01 à D-08 (2026-11-03, Q1-Q7), P71-D-23 (Q8, 2026-11-03), P71-D-25 à D-28 (Q9-Q12, 2026-11-04), P71-D-29 (Q13, 2026-11-04).
Décisions du manager : P71-D-09 à D-22, D-24 (amende D-10). Q14 (N9, N10) envoyée le 2026-11-04, sans réponse au moment du push.

## Verdicts

- Plan-checker : passage frais n°1 ISSUES FOUND (2 bloquants), corrigés ; passage frais n°2 sur `122c769a` : 0 bloquant (2 avertissements, 1 info, transmis).
- Critique design : 77/100, passed (seuil 70).
- Revue (`227be6c5`) : gaps_found (S1/Sp1, S2 majeurs) → re-revue (`502b354b`) : passed sur les deux axes, 7 mineurs → tous fermés au tour C.
- Audit de sécurité (`227be6c5`) : gaps_found, 0 bloquant, 2 majeurs (F1, F2) → re-audit (`502b354b`) : F1 à F8 fermés, N1, N2 neufs → re-audit n°2
  (`c023f54a`) : N1, N2 fermés, aucun majeur dans le périmètre ; N8, N11 (régressions de la phase) fermés au lot D ; N9, N10 en question Q14 ; H-1 hérité
  de la 67. Détail : `phases/VFDO-71-terminal-integre-cockpit/71-SECURITY.md`.
- Rejeu du job `gates` (`.github/workflows/ci.yml`) par `replay-ci-jobs.sh --job gates` : 20 étapes rejouées, 0 échec, 3 sautées (conditionnelles).
- Non-régression complète du module (27 suites `test-cockpit-*.sh` + `test-vibeflow-update-cockpit.sh`) sur `54cd2b8e` : 27 vertes, 1 rouge
  (témoin M-CONTREPRESSION dépendant de la charge, rendu déterministe en `2af9c68b`, 10/10 verts dont 5 sous charge ajoutée).

## Points ouverts

1. Recette humaine `71-RECETTE-HUMAINE.md` (17 étapes, macOS, dont `claude` dans le terminal, Safari/Firefox, marge basse) : à jouer par Samuel.
2. Q14 : N9 (bandeau non déclenché par un collage d'une ligne qui ne porte que des caractères bidi ou invisibles) et N10 (charge sous le pli de l'aperçu).
3. H-1 (hérité de la 67, majeur par la grille) : le serveur vendorisé lance `which`, `claude --version`, les outils de `driver-lock.sh` et `git` par nom ;
   mandat séparé proposé.
4. Linux non exécuté (seulement simulé : faux `/proc`, faux `ps`, faux `xdg-open`) : la CI Linux tranchera.
5. Sondes à fenêtre fixe T12.5 et T12.3 : un échec chacune sous charge synthétique extrême (moyenne > 200).
6. B1-1 : un `server.json` planté qui désigne un processus étranger vivant bloque le lancement (code 5) jusqu'à suppression (comportement de la 67, documenté).
7. Fusion : `71-BRANCHEMENTS-MERGE.md` (17 fichiers existants touchés, conflits certains avec la 69 sur `serve.mjs`, `VENDORED.txt`, `vf-cockpit.mjs`,
   `who`, `live`, `planning`, README, CHANGELOG, VERSION, `module.json`, nombre de suites des README racine).
8. Gate de sortie E3 (PR ouverte) : non satisfait par construction, la mission s'arrête avant la PR.
10. Gate de sortie (rejoué sur le HEAD final) : E3 attendu (pas de PR) ; E1 compte 2 agents « running » du registre de compartiment, consignés par une autre mission (registre de phase 71 vide) ; E7 désigne une mémoire de la Phase 68 hors git ; le snapshot de budget partagé a été réécrit par une autre mission à 2026-11-04T04:38Z.
9. Lot D (N8, N11, I-doc) : trois commits `7bbb06e7`, `6b678c46`, `54cd2b8e`, vérifiés par la non-régression complète du manager ; l'exécuteur n'a rendu ni SUMMARY ni bloc typé (relancé deux fois) — `71-FIX-D-SUMMARY.md` absent.

## Preuves E6

```json
{
 "preuves": [
  {
   "verdict": "gates",
   "commande": "bash .planning/milestones/fiabilite-v1.0-phases/VFDO-40.1-r-vision-adr-029-et-du-gate-du-budget-d-instructions/tools/replay-ci-jobs.sh --job gates",
   "exit_code": 0,
   "sha": "c023f54a"
  },
  {
   "verdict": "non-regression",
   "commande": "for t in plugin/cockpit/scripts/tests/test-cockpit-*.sh plugin/_internal/tests/test-vibeflow-update-cockpit.sh; do bash $t; done (27 rc=0, 1 rc=1 : témoin de charge)",
   "exit_code": 1,
   "sha": "54cd2b8e"
  },
  {
   "verdict": "temoin-contrepression",
   "commande": "bash plugin/cockpit/scripts/tests/test-cockpit-terminal-session.sh (10 rejeux, dont 5 sous charge ajoutée)",
   "exit_code": 0,
   "sha": "2af9c68b"
  },
  {
   "verdict": "revue",
   "commande": "bash plugin/cockpit/scripts/tests/test-cockpit-terminal-pty.sh (x5, à froid, en série)",
   "exit_code": 0,
   "sha": "502b354b"
  },
  {
   "verdict": "audit",
   "commande": "bash plugin/cockpit/scripts/tests/test-cockpit-terminal-lanceur.sh (sur git archive c023f54a)",
   "exit_code": 0,
   "sha": "c023f54a"
  },
  {
   "verdict": "audit",
   "commande": "bash plugin/cockpit/scripts/tests/test-cockpit-terminal-pty.sh (sur git archive c023f54a)",
   "exit_code": 0,
   "sha": "c023f54a"
  },
  {
   "verdict": "design",
   "commande": "bash plugin/cockpit/scripts/tests/test-cockpit-terminal-tiroir.sh",
   "exit_code": 0,
   "sha": "227be6c5"
  }
 ]
}
```

## Décompte

Mandats émis par le manager : 37 Task (2 chercheurs, 1 spike, 1 crafter, 1 planificateur relancé 2 fois, 2 plan-checkers, 11 exécuteurs de plan,
1 juge design, 1 réviseur + 1 re-réviseur, 1 auditeur + 2 re-auditeurs, 1 chercheur doc, 12 correcteurs : PTY, A1, A2, B1, B2, B3, docs, C, N1, N2, D, E ; le correcteur PTY a aussi porté P71-D-24 sur réveil). Questions à Samuel : 4 envois (Q1-Q7, Q8,
Q9-Q12, Q13) plus Q14 en attente.
