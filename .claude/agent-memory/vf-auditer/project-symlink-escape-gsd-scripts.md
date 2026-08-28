---
name: project-symlink-escape-gsd-scripts
description: CLOS (recoupé 2026-08-06) — build-gsd-capabilities-index.sh a depuis posé une garde de confinement réel (vf_realpath + ancre) fermant le symlink-escape trouvé en 2026-08-04 sur ce script ; check-gsd-config.sh non re-vérifié
metadata:
  type: project
---

**Mise à jour 2026-08-06** : le volet `build-gsd-capabilities-index.sh` de ce finding (2026-08-04)
est CLOS. Le script pose désormais une « Garde de CONFINEMENT DE CHEMIN » explicite (lignes ~160-192) :
`vf_realpath()` (via `node -e require('fs').realpathSync`, pas de `require()` sur le contenu) résout
le chemin RÉEL du registre et de l'ancre (`CORE_ANCHOR`), puis refuse la lecture si le chemin réel du
registre n'est pas SOUS le chemin réel de l'ancre (`case "$real_registry" in "$real_anchor"/*)`). Le
commentaire du script se nomme lui-même « troisième passage de ce motif dans ce dépôt ; il se ferme
ici » — cohérent avec le comptage de `.planning/codebase/CONCERNS.md`. Ce durcissement date de la
Phase 24 (commit `d588546`, antérieur à la Phase 27) — donc déjà en place avant l'audit qui l'a
recoupé, pas un effet de cette session. Confirmé par lecture directe le 2026-08-06 (pas re-testé par
PoC symlink cette fois — la lecture du code de garde est explicite et auto-descriptive, contrairement
au cas dag.sh qui nécessitait une exécution pour trancher).

**Volet NON re-vérifié à cette occasion** : `check-gsd-config.sh` (même famille, mentionné dans la
version originale de ce finding) — si un futur audit le recroise, vérifier séparément s'il porte la
même garde `vf_realpath`/ancre ou s'il reste ouvert.

Voir [[project-symlink-escape-dag-sh-5eme-passage]] (même famille, 5ᵉ passage, closed séparément
le même jour) et [[feedback-execute-dont-trust-green]].
