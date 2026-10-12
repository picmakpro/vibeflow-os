---
phase: 57-verrou-de-driver-par-compartiment
verified: 2026-10-12T17:50:00Z
status: passed
score: 13/13 critères atteints (5 clauses de l'objectif ROADMAP + DLWS-01..08)
covered_files:
  - ".planning/workstreams/fiabilite/phases/VFDO-57-verrou-de-driver-par-compartiment/57-01-PLAN.md"
  - ".planning/workstreams/fiabilite/phases/VFDO-57-verrou-de-driver-par-compartiment/57-01-SUMMARY.md"
  - ".planning/workstreams/fiabilite/phases/VFDO-57-verrou-de-driver-par-compartiment/57-02-PLAN.md"
  - ".planning/workstreams/fiabilite/phases/VFDO-57-verrou-de-driver-par-compartiment/57-02-SUMMARY.md"
  - ".planning/workstreams/fiabilite/phases/VFDO-57-verrou-de-driver-par-compartiment/57-03-PLAN.md"
  - ".planning/workstreams/fiabilite/phases/VFDO-57-verrou-de-driver-par-compartiment/57-03-SUMMARY.md"
  - ".planning/workstreams/fiabilite/phases/VFDO-57-verrou-de-driver-par-compartiment/57-04-PLAN.md"
  - ".planning/workstreams/fiabilite/phases/VFDO-57-verrou-de-driver-par-compartiment/57-04-SUMMARY.md"
  - ".planning/workstreams/fiabilite/phases/VFDO-57-verrou-de-driver-par-compartiment/57-05-PLAN.md"
  - ".planning/workstreams/fiabilite/phases/VFDO-57-verrou-de-driver-par-compartiment/57-05-SUMMARY.md"
  - ".planning/workstreams/fiabilite/phases/VFDO-57-verrou-de-driver-par-compartiment/57-06-PLAN.md"
  - ".planning/workstreams/fiabilite/phases/VFDO-57-verrou-de-driver-par-compartiment/57-06-SUMMARY.md"
  - ".planning/workstreams/fiabilite/phases/VFDO-57-verrou-de-driver-par-compartiment/57-07-PLAN.md"
  - ".planning/workstreams/fiabilite/phases/VFDO-57-verrou-de-driver-par-compartiment/57-07-SUMMARY.md"
  - ".planning/workstreams/fiabilite/phases/VFDO-57-verrou-de-driver-par-compartiment/57-08-PLAN.md"
  - ".planning/workstreams/fiabilite/phases/VFDO-57-verrou-de-driver-par-compartiment/57-08-SUMMARY.md"
  - ".planning/workstreams/fiabilite/phases/VFDO-57-verrou-de-driver-par-compartiment/57-09-PLAN.md"
  - ".planning/workstreams/fiabilite/phases/VFDO-57-verrou-de-driver-par-compartiment/57-09-SUMMARY.md"
  - ".planning/workstreams/fiabilite/phases/VFDO-57-verrou-de-driver-par-compartiment/57-10-PLAN.md"
  - ".planning/workstreams/fiabilite/phases/VFDO-57-verrou-de-driver-par-compartiment/57-10-SUMMARY.md"
  - ".planning/workstreams/fiabilite/phases/VFDO-57-verrou-de-driver-par-compartiment/57-11-PLAN.md"
  - ".planning/workstreams/fiabilite/phases/VFDO-57-verrou-de-driver-par-compartiment/57-11-SUMMARY.md"
  - ".planning/workstreams/fiabilite/phases/VFDO-57-verrou-de-driver-par-compartiment/57-12-PLAN.md"
  - ".planning/workstreams/fiabilite/phases/VFDO-57-verrou-de-driver-par-compartiment/57-12-SUMMARY.md"
  - ".planning/workstreams/fiabilite/phases/VFDO-57-verrou-de-driver-par-compartiment/57-13-PLAN.md"
  - ".planning/workstreams/fiabilite/phases/VFDO-57-verrou-de-driver-par-compartiment/57-13-SUMMARY.md"
  - ".planning/workstreams/fiabilite/phases/VFDO-57-verrou-de-driver-par-compartiment/57-14-PLAN.md"
  - ".planning/workstreams/fiabilite/phases/VFDO-57-verrou-de-driver-par-compartiment/57-14-SUMMARY.md"
  - ".planning/workstreams/fiabilite/phases/VFDO-57-verrou-de-driver-par-compartiment/57-15-PLAN.md"
  - ".planning/workstreams/fiabilite/phases/VFDO-57-verrou-de-driver-par-compartiment/57-15-SUMMARY.md"
  - ".planning/workstreams/fiabilite/phases/VFDO-57-verrou-de-driver-par-compartiment/57-16-PLAN.md"
  - ".planning/workstreams/fiabilite/phases/VFDO-57-verrou-de-driver-par-compartiment/57-16-SUMMARY.md"
  - "CLAUDE.md"
  - "docs/ADR.md"
  - "plugin/conductor/scripts/check-branch-claim.sh"
  - "plugin/conductor/scripts/check-guard-health.sh"
  - "plugin/conductor/scripts/dag.sh"
  - "plugin/conductor/scripts/driver-lock.sh"
  - "plugin/conductor/scripts/guard-driver-lock.sh"
  - "plugin/conductor/scripts/tests/test-driver-lock-consumers-ws.sh"
  - "plugin/conductor/scripts/tests/test-driver-lock-ws.sh"
  - "plugin/conductor/scripts/tests/test-guard-driver-lock-ws.sh"
  - "plugin/dev-orchestrator/scripts/check-mission-exit.sh"
  - "plugin/dev-orchestrator/scripts/tests/test-check-mission-exit-ws.sh"
covered_digest: "v3:sha256:ed0e1f3ee37d9140d05d34f24b72ed8695e4ba335ca2bc028118d334d8bd53c6"
behavior_unverified: 0
overrides_applied: 0
warnings: 6   # aucun ne compromet un critère ; voir « Constats »
---

# Phase 57 : Verrou de driver par compartiment, rapport de vérification

**Objectif (ROADMAP) :** `driver-lock.sh` devient compartiment-aware (un verrou nommé par workstream), un amendement
daté d'ADR-053 change l'invariant en « un manager par compartiment », `guard-driver-lock.sh` est aligné, le head passe
`--ws` et un `GSD_SESSION_KEY` distinct par manager, un lab non partitionné garde exactement le comportement d'aujourd'hui.
**Vérifié :** 2026-10-12, HEAD `b66a73af`, branche `feat/phase-57-verrou-compartiment`, base `dae0147b`.
**Statut :** passed. **Re-vérification :** non (première vérification).
**Vérificateur :** gsd-verifier. Rien n'a été écrit hors ce fichier ; aucune sonde sur le vrai `.git/vf-driver` (structure
relue avant/après : même génération `1791818875.71214`), tout l'exécutable a tourné dans des dépôts jetables sous
`HOME` jetable.

## Contrat vérifié

`roadmap.get-phase 57 --ws=fiabilite` ne porte aucun `success_criteria` : le contrat est l'objectif (cinq clauses,
G1 à G5) plus les huit exigences DLWS-01..08 de `REQUIREMENTS.md`, soit **13 critères**. Les SUMMARY n'ont pas été
crus : chaque ligne ci-dessous cite du code lu ou une exécution que j'ai moi-même rejouée.

## Critères

| # | Critère | Statut | Preuve (code lu, ou exécution rejouée par moi) |
|---|---------|--------|------------------------------------------------|
| G1 | `driver-lock.sh` : un verrou nommé par compartiment | ✓ VERIFIED | `driver-lock.sh:260-346` (`vf_dl_resolve`; l.318 `LOCK_DIR="$LOCK_ROOT/ws/$WS/DRIVER.lock"`). Sonde e2e : A prend `alpha`, B prend `beta` (acquired:true), B sur `alpha` refusé `held`. Suite `test-driver-lock-ws.sh` 528/0 |
| G2 | Amendement daté d'ADR-053 : « un manager par compartiment, un seul geste de dépôt à la fois » | ✓ VERIFIED | `docs/ADR.md:621` « Amendement du 2026-10-10 », sous ADR-053 (l.575), invariant réécrit, décisions citées avec canal et date. Constat C5 (mesures périmées) non bloquant |
| G3 | `guard-driver-lock.sh` aligné | ✓ VERIFIED | Résolution au même endroit que le script (`guard-driver-lock.sh:629` `discover_locks`, `:677` `held_by_other`, `:1057` `decide_partitioned`), fail-closed. Sonde e2e : une vingtaine de verdicts conformes (écritures par compartiment, commits sur l'index, push/checkout sous verrou de dépôt, `worktree add` exempté). Suite 240/0, mutants 23/23 |
| G4 | Le head passe `--ws` et un `GSD_SESSION_KEY` distinct par manager | ✓ VERIFIED (doctrine) | Cohérents dans `head-governance.md:98-105`, `intent-routing.md:66`, `mission-flow.md:111-146`, `vf-dev-manager.md:30,49`, `team-kernel.md:278-292`, 3 managers de bundles + design-manager. Contrat de prose, non vérifiable par machine ; la conformité d'exécution du head relève de la Phase 61 (hors périmètre déclaré) |
| G5 | Lab non partitionné inchangé | ✓ VERIFIED | Voir DLWS-03 |
| DLWS-01 | Verrou par compartiment, deux compartiments en parallèle, même compartiment refusé | ✓ VERIFIED | Sonde e2e (G1). `WS-CONC-ACQ` : 5 tours × (24 alpha + 24 omega), « rounds hors contrat : 0 ». Mutants DL-M 10/10 + mes mutants `ws_to_repo` (51 KO) et `depot_dir_ws` (20 KO) tués |
| DLWS-02 | Verrou de dépôt distinct, deux gestes de dépôt jamais ensemble | ✓ VERIFIED | `driver-lock.sh:318,326` (`repo/` distinct de `ws/<sujet>/`). Sonde e2e : A tient `alpha` + dépôt, B refusé sur `--depot` (`held`). `WS-CONC-DEPOT` 0 round hors contrat. Doctrine : `CLAUDE.md` (release en deux gestes courts sous `acquire --depot`), `SKILL.md` de `vf-split-planning`, `mission-flow.md:125-127` |
| DLWS-03 | Lab plat inchangé au bit près | ✓ VERIFIED | `git diff --quiet dae0147b -- test-driver-lock.sh test-guard-driver-lock.sh` : vide (aucune suite existante modifiée sur toute la plage ; seules 3 suites + 2 fixtures ajoutées). Fixtures gelées = `git show dae0147b:` octet pour octet (`cmp`). `test-driver-lock` 243/0, `test-guard-driver-lock` 103/0 ; A/B `IDENTIQUE` des deux suites ws. A/B indépendant (mon script, 18 verbes) : seules diffèrent les options neuves `--ws`/`--depot`/`--all` (P57-D-31), tous les verbes historiques identiques |
| DLWS-04 | Résolution explicite, jamais d'export ni de pointeur ; sans `--ws` = dépôt + JSON | ✓ VERIFIED | Sonde : `GSD_WORKSTREAM=beta VF_WORKSTREAM=beta` sans `--ws` → `scope: depot`, `scope_reason: ws-absent`. Refus nommés `unknown-ws`, `ws-invalid` (`../x`), `not-at-lab-root` (P57-D-39, aucun `.planning/` parasite dans le sous-dossier). Mutant `e` (dérivation par env) tué |
| DLWS-05 | Emplacement au niveau du clone, partage entre worktrees, repli hors git, guard au même endroit | ✓ VERIFIED | `.git/vf-driver/{ws/<s>,repo}` ; worktree lié voit `alpha` tenu (`held`). Hors git : `location: checkout`, repli `.planning/DRIVER.lock.d`, guard hors git : DENY sur compartiment tenu, ALLOW sur le libre. Mutants `a` (suite) et `hors_git_fallback` (le mien, 7 KO) tués. Lab installé via l'installeur (7 modules) : `workstream-policy.sh` posé à plat, acquire/status --all fonctionnent |
| DLWS-06 | Guard par compartiment ; commits sur l'index, illisible = refus ; checkout/switch refusés ; exemptions D-32-06 | ✓ VERIFIED | Sonde e2e (G3) + `--pathspec-from-file` DENY, `.PLANNING` (F-1) DENY. Mutants guard : sur 14 des miens, 10 tués (`depot_all`, `casefold_w`, `unreadable_allow`, `map_path_root`, `stale_ttl`, `uncert`, `lower_planning`, `exc_allow`, `lsfiles_o`, `shortpath_pathspec`), 4 survivants analysés en C3 (dont 1 équivalent). Les 23 mutants GW-M de la suite : 23/23 |
| DLWS-07 | Amendement ADR-053, consommateurs alignés et vérifiés | ✓ VERIFIED | Consommateurs recensés (`DRIVER.lock\|driver-lock.sh\|VF_DRIVER_LOCK`) tous traités : `check-guard-health.sh` (`status --all`, entrée la plus grave), `dag.sh` (`init --ws`, `mark-progress --ws`), `check-branch-claim.sh`, `check-mission-exit.sh` (E1/identité E7/E4 par `--ws`), managers dev/design/business/content/growth, `mission-flow.md`, `workstream-planning-consumers.md`, manuel FR+EN. Suite consommateurs 30/0, mutants 7/7 ; `check-mission-exit-ws` 54/0, mutants 5/5. E1 vérifié par moi dans un lab jetable (`present`, génération lue, `?` si script ancien) |
| DLWS-08 | Preuve de mécanisme et QUAL-01 | ✓ VERIFIED (réserve C3) | Concurrence 24×5 sur 4 scénarios (compartiments, périmé, dépôt, checkout+worktree) 0 round hors contrat, A/B, repli, refus du guard selon l'index : tout rejoué. Mutants de la suite : 10 + 23 + 7 + 5 = 45/45 tués. Réserve : six branches défensives sans mutant (C3) |

## Rejeu de la porte de phase (élément 1)

- **Job `gates`** : `replay-ci-jobs.sh --job gates` (étapes extraites de `ci.yml` par le script de l'outil, identique à la
  copie du scratchpad), HOME jetable : `19 rejouée(s), 3 sautée(s), 0 en échec` (les 3 sautées : action + 2 étapes
  conditionnelles `push` sur `main`). Confirmé.
- **102 suites** (`find plugin scripts -path "*/tests/test-*.sh"` = 102) : 15 suites propres/consommateurs rejouées une à
  une puis les 87 autres en boucle, HOME jetable : 100 vertes, 2 rouges.
  - `test-driver-lock` 243/0 · `test-guard-driver-lock` 103/0 · `test-driver-lock-ws` 528/0 (111 s) ·
    `test-guard-driver-lock-ws` 240/0 (168 s) · `test-driver-lock-consumers-ws` 30/0 · `test-check-mission-exit-ws` 54/0 ·
    `test-check-mission-exit` 135/0 · `test-check-branch-claim` 18/0 · `test-check-guard-health` 78/0 · `test-dag` 161/0 ·
    `test-check-planning-consumers-registered` 7/0 · `test-split-planning` 69/0 · `test-vf-split-planning` 40/0.
  - **Deux rouges environnementales confirmées** : `test-check-description-fidelity` (8 OK / 36 KO, PyYAML introuvable) et
    `test-quick-validate` (1 ok / 4 ko, `No module named 'yaml'`). Vrai HOME sur HEAD : 56/0 et 5/0. Base `dae0147b`
    (`git archive`) : vrai HOME 56/0 et 5/0 ; HOME jetable 8/36 et 1/4, même rouge. Rouge de HOME, pas de code.
- **Témoins DLWS-03** : intacts (voir tableau). Objets `e8771d94` et `cff1e2af` présents, ancêtres de la base ; aucune ligne SKIP.

## Mutations rejouées par moi (les témoins peuvent-ils rougir ?)

Les résultats d'un passage précédent trouvés au scratchpad (survivants `stale_ttl`, `uncert`, `lower_planning`, `exc_allow`, etc.)
étaient antérieurs à la correction R-3 : rejoués à HEAD (`GW_MODE=matrice GW_GUARD=<copie mutée>`), ils sont **tués**
(`GW-TTL-1..3`, `GW-UNC-*`, `GW-C-CASE-1`, `GW-C-GEN-1..3`), le témoin non muté rend 209/0. Ces traces anciennes n'ont donc pas été reprises.
- Guard, 14 mutants : tués 10 ; survivants 4 (`incertain_none`, `pathspec_blind`, `retrait`, `toplevel_none`).
- Driver, 12 mutants (matrice 510 cas, témoin 510/0) : tués 9 ; survivants 3 (`acq_fallback`, `fallback_depotpresent`, `skip_link_d`).
- Équivalent prouvé par lecture : `retrait` (la classe retombe dans le `else: add(held)` final, même verdict).

## Éléments à re-vérifier

1. **Porte de phase** : confirmée (ci-dessus).
2. **57-REVIEW / 57-SECURITY** : R-1 (hint de `takeover` porte `--ws=alpha`, hint rejoué littéralement reprend bien `alpha` : rejoué par moi), R-2, R-3 (mutants désormais tués), F-1 (`.PLANNING` refusé : sonde), F-2 (`not-at-lab-root` : sonde) corrigés ; les 13 SHA de correction sont ancêtres de HEAD ; P57-D-38 et P57-D-39 portent canal et date (`57-CONTEXT.md`). R-4..R-7 et F-3 sont consignés dans `57-REVIEW.md` / `57-SECURITY.md` et ne compromettent aucun critère (voir C4).
3. **Observation `check-mission-exit.sh --budget-snapshot` « génération du verrou : ? »** : **reproduite** dans un dépôt jetable.
   Cause confirmée : `resolve_S` (l.179) place `$HOME/.claude/scripts` avant le module voisin, et ce dossier porte un
   `driver-lock.sh` d'avant la phase (838 lignes, 0 occurrence de `--ws`) qui refuse `--ws=` (rc 1) → `?`. Avec un HOME
   « à jour » ou un `ROOT/.claude/scripts` à jour (lab installé), la génération est lue correctement (cas B et F). Dans le
   gate complet, E1 devient `indet` (« code non nul (1) ») et E7 « snapshot d'une autre mission » : **fail-closed, jamais vert**
   (le juge de sécurité l'avait vu : T-57-23). **Classement : dette non bloquante du dépôt source** ; elle ne touche pas
   un lab installé à jour, et se résorbe avec la release suivante et `/vf-update`. Aucun critère n'en dépend (E1/E7 par `--ws`
   sont prouvés par la suite 54/0 et par mon lab jetable à scripts à jour). Non corrigé, conformément à la consigne.
4. **Compteurs `progress` de STATE (105/115)** : n'incluent pas la Phase 57, comme avant la phase. Hors objectif ; signalé seulement.
5. **Jobs `lab-frais` / `lab-frais-arme`** : ne prouvent rien de propre aux DLWS (baseline, Gate C, gate installé). Aucun critère
   ne dépend d'eux ; pas d'item `human_needed`. Pour mémoire, j'ai joué moi-même l'équivalent as-installed : fermeture de
   `conductor` (7 modules) installée dans un lab jetable, `workstream-policy.sh` posé à plat, acquire et `status --all` fonctionnent.

## Constats

| # | Gravité | Constat | Action |
|---|---------|---------|--------|
| C1 | WARNING (non bloquant) | `resolve_S` préfère `$HOME/.claude/scripts` : dans le dépôt source, E1 est `indet` et l'identité d'E7 vaut `?` tant que le poste n'a pas reçu la nouvelle version. Fail-closed. | no-op (se résorbe à la release + `/vf-update`) ; amélioration facultative : préférer le module voisin quand `--root` est le dépôt source |
| C2 | WARNING (non bloquant) | `check-mission-exit.sh --ws` ne passe pas `--ws` à `check-method-budget.sh` (E7 et `--budget-snapshot`). Sans `GSD_WORKSTREAM` exporté, E7 rend « ARCHIVAGE NON TENTÉ » → verdict `INDÉTERMINÉ` (rc 4), observé. Le flux réel du manager exporte `GSD_WORKSTREAM` (`vf-dev-manager.md:30`), et P57-D-35 ne promet que E1, l'identité d'E7 et E4. | ask-user : ajouter `--ws "$WS"` aux deux appels du budget (une ligne chacun) ou assumer |
| C3 | WARNING (réserve DLWS-08) | QUAL-01 « mutation rouge pour chaque comportement neuf » n'est pas exhaustif : survivent `acq_fallback` (suffixe JSON seul), `fallback_depotpresent` (clause « verrou de dépôt absent » de P57-D-24), `skip_link_d` (lien symbolique ignoré par `status --all`), et côté guard `pathspec_blind` (`--pathspec-from-file`, `--only`, `--include`), `incertain_none` (chemin « incertain » dans un commit), `toplevel_none`. Le code est correct (sondes : `--pathspec-from-file` refusé) ; seul le témoin manque. | ask-user : six mutants à ajouter dans une correction courte, ou consigner au BACKLOG |
| C4 | WARNING (non bloquant, consigné) | F-3 réel : `git --no-pager commit -am x` est ALLOW sous verrou d'autrui (vérifié ; ligne héritée Phase 32, catégorie A du guard). R-4/R-5 annoncés « limite écrite » dans la revue mais **absents** de tout livrable (le terme `GIT_INDEX_FILE` n'apparaît dans aucun fichier du dépôt) ; F-3 « à consigner dans CONCERNS.md » : CONCERNS.md ne porte aucune entrée Phase 57. | auto-fix documentaire (CONCERNS.md ou BACKLOG), sans toucher au code |
| C5 | WARNING (faible) | L'amendement d'ADR-053 (daté 2026-10-10) a des « Mesures » périmées par les corrections de revue (492 assertions → 528, mutants 9 → 10, guard 180 → 240 et 12 → 23) alors qu'il les dit « recopiées des SUMMARY », et sa liste « Décisions citées » n'énumère pas P57-D-38/39 avec leur canal et leur date (citées en ligne l.645 et l.652 seulement). | auto-fix (édition d'ADR, datée) |
| C6 | INFO | `57-VALIDATION.md` reste `status: draft`, `nyquist_compliant: false`, `wave_0_complete: false` (jamais mis à jour). Compteurs `progress` de STATE : voir élément 4. | no-op (`/gsd-validate-phase` si on veut le clore) |

Aucun marqueur `TBD/FIXME/XXX/TODO/HACK/PLACEHOLDER` n'est ajouté par la phase (lignes `+` de `dae0147b..HEAD`). Aucune release ni bump racine
(`VERSION`, `plugin.json`, `marketplace.json` inchangés, P57-D-30) ; cinq modules bumpés sans release, `check-version-sync` vert.

## Réserves traitées (2026-10-12)

Mandat de correction ciblée (vf-dev-manager → vf-coder), HEAD de départ `4262516a`. Le statut du rapport reste `passed`.

| Réserve | Traitement | Commit |
|---------|-----------|--------|
| C1 | Renvoyée à `.planning/codebase/CONCERNS.md` (entrée « Phase 57 », point 7) ; aucun code | `c15e08ba` |
| C2 | Corrigée : `check-mission-exit.sh` transmet `--ws <sujet>` à `check-method-budget.sh` dans E7 et `--budget-snapshot` (sans `--ws`, lignes d'origine conservées à l'octet). RED : cas EW-BWS-1..3 rouges (trace de l'assertion, de l'attendu et de l'obtenu dans le message du commit). GREEN : suite `-ws` 61/0, mutants 7/7 dont EW-M-f (snapshot) et EW-M-g (E7) ; `test-check-mission-exit.sh` 135/0, sans diff contre le merge-base | RED `0722a581`, GREEN `9197ce01` |
| C3 | Renvoyée à CONCERNS.md (point 6, six branches défensives sans mutant) ; aucun mutant ajouté | `c15e08ba` |
| C4 | Corrigée : entrée « Phase 57 » de CONCERNS.md (F-3, R-4, R-5, R-6, R-7, C3, C1, chacun avec sa source) | `c15e08ba` |
| C5 | Corrigée : « Mesures » de l'amendement d'ADR-053 rejouées et recopiées (528/0 et 10/10, 240/0 et 23/23, 61/0 et 7/7, 30/0 et 7/7) ; P57-D-38 et P57-D-39 cités avec canal et date ; CHANGELOG dev-orchestrator v2.28.0 aligné (manuel FR/EN : aucune mesure citée) | `b3ba334a` |
| C6 | Laissée telle quelle (`57-VALIDATION.md` non touché) | — |

## Résumé

Treize critères sur treize atteints. Le mécanisme est réel : le script résout un verrou par compartiment et par dépôt au
niveau du clone, refuse nommément, partage entre worktrees, replie hors git ; le guard juge sur ce qui est tenu par
autrui et sur l'index, fail-closed ; le lab plat est identique au bit près (suites historiques non modifiées, fixtures
gelées égales à la base, A/B). Les six constats sont des réserves ou de la dette documentaire, aucun n'invalide un critère.
L'usage concurrent réel à deux humains reste, comme annoncé, à la Phase 61.

---

_Vérifié : 2026-10-12_
_Vérificateur : Claude (gsd-verifier)_

## Corrections du 2026-10-12

Arbitrage Samuel (AskUserQuestion, session principale, 2026-10-12) : solder la dette avant la PR (rattachement sans bump, P57-D-40). Le statut reste `passed`. Complète « Réserves traitées (2026-10-12) » ci-dessus, dont les lignes C1, C3 et C4 (renvois à CONCERNS) sont dépassées sur ces points.

| Réserve | Commits | Preuve |
|---------|---------|--------|
| C1 (`resolve_S` préfère `$HOME/.claude/scripts`) | `fc763a72` RED (cas EW-SRC), `dcba414d` GREEN | `check-mission-exit.sh` préfère le module conductor voisin quand le gate est dans le dépôt source |
| C3 (six branches défensives sans mutant) | `6333d8e4`, `1f6b555b` | six mutants ajoutés (`acq_fallback`, `fallback_depotpresent`, `skip_link_d`, `pathspec_blind`, `incertain_none`, `toplevel_none`), total driver 16, ensembles complétés |
| C4 (F-3 rejoué) | `c5ccbab7`, `63d5cc4c` | F-3 refusé en lab partitionné ; lab plat inchangé (P57-D-42) |
| Annexe (suite flaky) | `c580b45e` | `test-check-description-fidelity.sh` stabilisée (T9 tmpdir privé, T10 miroir), `check-description-fidelity.sh` respecte `TMPDIR` ; 20/30 rouges avant, 0/30 après (`.planning/debug/flaky-description-fidelity.md`) |
