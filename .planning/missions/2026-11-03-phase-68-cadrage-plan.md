# Mission 2026-11-03 — Phase 68 : cadrage et planification (vf-signal embarqué)

**Manager :** vf-dev-manager (`mgr68`) · **Compartiment :** `fiabilite` · **Branche :** `feat/phase-68-vf-signal`
(worktree `.claude/worktrees/phase-68`, base `7370d604`) · **DAG :** `.planning/workstreams/fiabilite/MISSION-68.dag.json`
· **Périmètre :** cadrage + plans validés, aucune exécution (la 68 dépend de la 69, P69-D-10).

## Plan de bataille

`rech-mod` ∥ `rech-socle` ∥ `rech-pack` (lecture seule) → `arbitrages` (un seul envoi à Samuel, 8 questions)
∥ `sonde-node` → `discuss-68` (CONTEXT, VFSG, blocs 68 de ROADMAP et STATE) → `plan-68` (vf-coder, gsd-plan-phase)
→ `plancheck-68` (gsd-plan-checker externe frais) → `revalid-68` (après merge de la 69 et de la PR #196).

## Résultats

- **Cadrage :** `68-CONTEXT.md`. P68-D-01..08 : arbitrage Samuel, AskUserQuestion, session principale Claude Code,
  2026-11-03, « Tout accepter (Recommandé) », relayé par la session principale. P68-D-09..10 : conditions
  d'exécution. P68-D-11..21 : décisions techniques du manager, prises sur mesure.
- **Exigences :** VFSG-01..13. La famille a été vérifiée libre.
- **Plans :** 68-01..11, en 9 vagues. Le plan-checker interne a rendu PASSED en 2 passes.
- **Plan-checker externe frais :** PASSED (0 BLOCKER, 3 WARNING), lecture de phase-69b à `2177a34f`.
  - W1 : 68-04 est trop large (24 fichiers).
  - W2 : le témoin I9 « cache réel » n'a de valeur qu'après l'import.
  - W3 : le SHA de la 69 cité dans le CONTEXT a été dépassé.
  - Ces trois points sont reportés à `revalid-68`.
- **Workers :** 7 agents dispatchés (3 recherches, 1 sonde, 1 vf-coder, 1 plan-checker), tous inscrits au
  registre puis clos. Le vf-coder a ouvert 4 enfants (cartographe, planner, deux checkers), inscrits et clos.

## Points ouverts (à trancher avant l'exécution)

1. Les sept hypothèses écrites par le planner (`68-01-PLAN.md` P68-PL-02, 03, 11, 12 ; T-68-12) :
   - deux missions du même compartiment partagent un verrou ;
   - un verrou illisible donne `running` ou `abandonnee` ;
   - le bloc backlog de la vue macro est retiré avec `disk.ts` ;
   - ordre de résolution du lanceur du cockpit ;
   - version minimale de Claude Code ;
   - délai de revue de Willy (68-09) ;
   - les identifiants `who@2` / `$.agent.list()` restent à constater à la recette.
2. Conditions d'exécution : la 69 et la PR #196 doivent être mergées, puis rebase et plan-checker frais (`revalid-68`).
3. La preuve CI sous Linux de `claude plugin validate/test` (68-09) n'existe pas encore.
4. Le gate natif de couverture des décisions rend `could-not-parse` sur les identifiants préfixés `P6x-D-NN`. C'est le
   même constat que sur la 69 ; la couverture a été vérifiée à la main.

## Preuves E6

Aucune preuve d'exécution : la mission ne produit que des plans, et aucun bloc typé de vf-coder ne porte de `preuves`.

## Next step

Après le merge de la Phase 69 et de la PR #196 : rebase de `feat/phase-68-vf-signal` sur `main`, plan-checker frais
(nœud `revalid-68`), puis exécution de la 68.
