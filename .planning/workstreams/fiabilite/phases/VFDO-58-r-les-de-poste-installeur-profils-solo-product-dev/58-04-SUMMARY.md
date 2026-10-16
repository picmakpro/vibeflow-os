---
phase: 58
plan: 04
status: complete
requirements: [RLPO-03, RLPO-08, RLPO-09]
---
# 58-04 — gate `check-role-consistency.sh` et contexte « Poste : X » (P58-D-09, P58-D-10, P58-PL-01, P58-PL-08..10)

- Codes (en-tête de `plugin/conductor/scripts/check-role-consistency.sh`) : 0 poste dans `vf_roles` ; 1 hors liste ou valeur invalide ; 3 silence (aucune source, pas de config.json, pas de clé) ; 5 erreur d'analyse bruyante (jamais traduite) ; 17 Python indisponible ; 64 usage ; 2 jamais émis. Options `--path`, `--role`, `--hook` (seul le 3 devient 0).
- `Poste : <X>` : valeur validée uniquement, hors `solo`, imprimée avant les verdicts 0/1/3, jamais sur le code 5 ni 17 (interprétation retenue de « sans erreur d'analyse » : lecteur ET config.json).
- Hook : un groupe `SessionStart` propre sans matcher dans `plugin/conductor/hooks/hooks.json`, forme exec ; CR-HOOK-POSE : l'engine l'écrit dans `.claude/settings.local.json` du lab (args `${CLAUDE_PROJECT_DIR}/.claude/scripts/check-role-consistency.sh`, `--hook`), le script posé rend `Poste : product`.
- `docs/HOOKS-CONTRAT-SORTIE.md` : 31 → 32 (`assert n==32`, ligne n°32, conductor 11, §5 : total 32, 25 advisory) ; §6 inchangé (conductor garde 6 entrées shell, mesuré `11 6`). T12 `ok` (test-check-hook-paths 17/0).
- Suite `plugin/conductor/scripts/tests/test-check-role-consistency.sh` : 38 ok / 0 ko (bash courant et /bin/bash 3.2), CR-17 mesuré (rc 17, PATH sans interpréteur), CR-RO par empreinte, codes observés {0,1,3,5,64}+17.
- Mutants tués (cmp -s différent, bash -n valide, attendu/obtenu imprimés, original revérifié vert) : MUT-liste-hors, MUT-silence, MUT-analyse, MUT-hook, MUT-cle, MUT-brut, MUT-analyse-hook.
- Voisines vertes : test-merge-hooks 39/0, test-hook-exit-parc 42/0, test-hook-exit-contract 40/0, test-manifest 62/0, test-vibeflow-update 93/0, test-vf-update 13/0, test-vf-role 26/0, test-vf-portable 16/0, check-planning-consumers-registered exit 0.
- Les deux tâches sont livrées en un seul commit.
