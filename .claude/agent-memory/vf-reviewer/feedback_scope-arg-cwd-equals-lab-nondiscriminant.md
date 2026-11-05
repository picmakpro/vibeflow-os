---
name: feedback-scope-arg-cwd-equals-lab-nondiscriminant
description: Revue fraiche Phase 68 (68-11) : un argument de portee (lab) passe a shBorne n'est pas discrimine quand les suites tournent avec cwd == lab ; deux mutants survivants dans test-cockpit-path-enfants.sh
metadata:
  type: feedback
---

Un argument optionnel qui defaut sur `cwd` (ex. `shBorne(cmd, args, cwd, lab = cwd)`) n'est jamais discrimine par une suite qui lance tout depuis la racine du lab : retirer `lab: root` de `retard()` (signal.mjs) ou le `root` des trois appels git de `who.mjs` laisse `test-cockpit-path-enfants.sh` a 35/35.

**Why:** le code est juste aujourd'hui, mais le correctif H-1 (#201) repose sur la lecture seule de ces 4e arguments ; une regression future (worktree sous le lab, dossier DAG sous le git-common-dir hors lab) passerait la suite.

**How to apply:** sur toute garde "PATH sans element du lab", muter l'argument de portee et exiger un cas ou cwd != lab (worktree distinct, dossier de DAG hors racine). Meme famille : la branche `sous(c, base)` de `admis` (actions.ts) survit si aucun test ne donne un realPath different du chemin pour la racine du lab. Voir aussi [[feedback_constant-flag-matrix-nondiscriminant]].
