# 78-04 — Trace des témoins rouges

Commande commune : `bash plugin/cockpit/scripts/tests/test-cockpit-git-entete.sh` (Chrome headless en CDP, port éphémère, jamais 4456).
Chaque rouge est joué sur la base, avant le code correspondant ; le vert suit dans la même tâche.

## Tâche 1 (tracer)

| Témoin | Assertion | Attendu | Obtenu sur la base (rouge) | Vert après |
|---|---|---|---|---|
| H1.1 | `enteteGit(<wt-a>)` | `ok\|depot\|feat/x\|wt-a\|false` | `` (module `vf-cockpit-git-entete.mjs` absent, l'import échoue) | oui |
| H1.1b | `enteteGit(<depot>)` | `ok\|depot\|main\|null` | `` (module absent) | oui |
| H2.1 | `#proj-name` sur `index.html`, cockpit construit dans le worktree | `depot` | `wt-a` (le nom du moteur, dossier du worktree) | oui |
| H2.1b | `.vf-git-ligne` contient `feat/x` et `wt-a` | `oui` | `non` (aucune seconde ligne) | oui |
