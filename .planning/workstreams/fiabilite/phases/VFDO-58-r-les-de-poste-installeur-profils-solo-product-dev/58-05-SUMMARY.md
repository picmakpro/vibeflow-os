---
phase: 58
plan: 05
status: complete
requirements: [RLPO-05]
---
# 58-05 — catalogue filtré par poste `build-module-catalog.sh --role` (P58-D-17, P58-PL-03)

- `--role <poste>` / `--role=<poste>` puis `VF_ROLE` (le drapeau l'emporte) ; valeur hors `solo|product|dev`, `--role` sans valeur, argument inconnu : erreur code 1, valeur jamais réimprimée. `product`/`dev` délèguent à `module-roles.sh list` (chemin relatif au script, `VF_MODULES_ROOT` transmis) ; `solo` et sans poste ne lancent rien. Variable interne renommée `statut`.
- Copie gelée `fixtures/build-module-catalog-pre-58.sh` = octets de `a2ed5094` ; sortie sans poste identique à l'octet (cmp -s) sur le dépôt réel ET la fixture isolée.
- CAT-PRODUCT : `comm -23` (sans poste moins product) = `dev-orchestrator mobile-test mobile-test-team` ; `comm -13` vide. `--role dev` et `solo` = sortie sans poste.
- CAT-INTEGRITE : mesuré (a2ed5094 lisible), copie gelée identique ; ligne SKIP seulement en clone superficiel.
- Suite `test-build-module-catalog-role.sh` : 15 ok / 0 ko (bash courant et /bin/bash 3.2). Mutants tués : CAT-MUT-1 filtre inversé, CAT-MUT-2 priorité inversée, CAT-MUT-3 solo filtré comme product (cmp -s différent, bash -n valide, original revérifié vert).
- `test-build-module-catalog.sh` inchangé : 14 ok. Job lab-frais : `$3 == "mandatory"` rend `conductor consolidator`. `ci.yml` et la suite d'origine non touchés (git diff --quiet exit 0).
- Les deux tâches sont livrées en un seul commit.
