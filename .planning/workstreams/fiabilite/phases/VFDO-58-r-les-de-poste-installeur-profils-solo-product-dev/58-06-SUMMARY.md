---
phase: 58
plan: 06
status: complete
requirements: [RLPO-01, RLPO-03, RLPO-06]
---
# 58-06 — pose du poste par l'engine (P58-D-01, P58-D-04, P58-D-09, P58-D-13, P58-D-16, P58-D-18, P58-PL-02, P58-PL-07)

- `--role`/`VF_ROLE` : pré-parse, validation fermée `solo|product|dev` sur `install` seulement, valeur jamais réimprimée ; `--role` hors `install` refusé, `VF_ROLE` hérité ignoré ailleurs. Fonctions `role_apply [--changement]`, `role_gitignore_rule`, `role_write_file`, `find_role_gate`, drapeau `VF_ROLE_WILL_EXIST`, `vibeflow-role` ajouté à `vf_manifest_excluded`. Aucun écrivain de `vf_roles` (`config.json` identique à l'octet : RV-CONFIG).
- Plan `--dry-run` (lignes exactes) : `[plan] ~ ./.gitignore  .claude/vibeflow-role` ; `[plan] + ./.claude/vibeflow-role  (poste du lab : <poste>, fichier local non versionné)` ; `[plan] ~|+ ./.worktreeinclude`. Sans poste : aucune de ces trois lignes, `.worktreeinclude` à 4 lignes, aucun `.gitignore` en scope project (RV-TRACE-2).
- `gitignore_add_paths()` identique à la merge-base (`awk` + `cmp -s`) ; appels `ensure_worktreeinclude_entries` : `1 1` ; `ensure-deps.sh` non appelé (0) ; `test-vibeflow-update.sh` non touché.
- Suite neuve `test-vibeflow-update-role.sh` : 20 ok / 0 ko, bash courant et `/bin/bash` 3.2, 7-8 s. Mutants tués (attendu / obtenu) : RV-M1 `.claude/vibeflow-role|` / `absent` ; RV-M2 `4` / `5` ; RV-M7 `declare` / `silence` ; RV-M4 `rc=1 pose=non` / `rc=0 pose=oui`.
- `test-vibeflow-update.sh` : 93 OK / 0 KO, 415 s (alarme 600 s). `test-manifest.sh` 62/0 (17 s), `test-merge-hooks.sh` 39/0 (7 s), les deux sous bash courant et 3.2.
- Constat (hors périmètre, gate de 58-04) : `check-role-consistency.sh` lancé depuis un cache sans `_internal/lib/vf-portable.sh` sort 1, indiscernable d'un « hors liste » ; l'engine refuse (échec fermé) avec le message « hors de la liste ». Le cache réel du plugin porte `_internal/` ; la suite copie `vf-portable.sh` dans son cache pour que RV-REFUS-1 refuse pour la bonne raison (témoin positif RV-REFUS-2).
- Les deux tâches sont livrées en un commit (le refus à la pose partage les fonctions du tracer).
