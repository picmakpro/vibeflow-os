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

## Tour de révision (2026-11-03, même jour)

- P68-D-22..25 consignés dans `68-CONTEXT.md` : arbitrage Samuel, AskUserQuestion, session principale Claude Code,
  2026-11-03, relayé par la session principale. Les points 5 à 7 sont documentés comme procédure, sans arbitrage.
- Révision ciblée des plans : `de439110`, puis `1a5508ec` après deux avertissements sur 68-01. Le verrou est lu
  sur la phase de la mission et comparé en chaîne normalisée. L'état `inconnu` est ajouté. Les points 3 et 4 sont
  retirés des points à décider. Le témoin I9 rougit vraiment après l'import.
- `reste` pour une phase `a-faire` : la 69 rend `["verification","cloture"]`. Aucun des onze plans de la 68 ne lit
  cette valeur : elle est sérialisée telle quelle, donc conforme.
- Plan-checker frais sur l'ensemble : PASSED, 0 BLOCKER, 2 WARNING, tous deux corrigés. Plan-checker frais ciblé
  sur 68-01 : PASSED, 0 BLOCKER, 2 WARNING, reportés à `revalid-68` :
  - type gardé du champ `phase` du verrou (chaîne ou nombre) ;
  - règle de choix quand `phases/069` et `phases/69` coexistent, et le témoin qui la prouve.
- Point ouvert relevé par le correcteur : au sens littéral de P68-D-22, une mission conduite sous un verrou de
  compartiment nu (la forme d'avant la PR #197) s'affiche `abandonnee` alors qu'elle vit. C'est à confirmer par
  Samuel avant l'exécution.

## Tour P68-D-26 (2026-11-03)

- P68-D-26 : « Repli sur le verrou du compartiment (Recommandé) » (arbitrage Samuel, AskUserQuestion, session
  principale Claude Code, 2026-11-03, relayé par la session principale). Le point ouvert précédent est fermé.
- Commit `d46e915e` (68-01, 68-03, PATTERNS). La cascade est : verrou de phase, puis verrou de compartiment, puis
  absence ; une source illisible donne `inconnu`. Nouveaux témoins : V10.1 à V10.4, avec la copie mutée V10.3, qui
  retire le repli. Deux avertissements de la passe précédente sont fermés : V9.4b (phase en chaîne seulement), puis
  V9.6 et V9.7 (`069` et `69` coexistants).
- Plan-checker frais ciblé : PASSED, 0 BLOCKER, 1 WARNING, 1 INFO.
  - WARNING : un verrou de phase présent mais périmé, alors que le compartiment est tenu, donne `abandonnee`. C'est
    la lecture du planificateur, P68-D-26 ne le dit pas, et aucun témoin ne couvre le cas. Il faut le faire
    confirmer.
  - INFO : le texte du `fails_when` de la tâche 1 de 68-01 ne cite pas V9 ni V10. Reporté à `revalid-68`.

## À jouer au nœud `revalid-68` (consigne de la session principale, 2026-11-03)

- P68-D-27 (décision du manager, consignée dans le CONTEXT) : ajouter à 68-01 un témoin qui fige le cas « verrou de
  phase présent mais périmé + compartiment tenu → `abandonnee` », avec une copie mutée qui ferait gagner le repli.
- INFO du dernier checker : aligner le texte du `fails_when` de la tâche 1 de 68-01 sur V0 à V10.
- Plus les reports déjà notés : rebase sur `main` après le merge de la 69 et de la PR #196, puis un plan-checker frais.

## Preuves E6

Aucune preuve d'exécution : la mission ne produit que des plans, et aucun bloc typé de vf-coder ne porte de `preuves`.

## Next step

Après le merge de la Phase 69 et de la PR #196 : rebase de `feat/phase-68-vf-signal` sur `main`, plan-checker frais
(nœud `revalid-68`), puis exécution de la 68.
