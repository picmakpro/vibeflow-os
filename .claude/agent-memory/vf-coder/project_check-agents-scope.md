---
name: check-agents-scope
description: check-agents.sh audite .claude/agents du lab courant, pas les agents versionnés sous plugin/ — sur vibeflow-os il ne vérifie rien
metadata:
  type: project
---

`plugin/conductor/scripts/check-agents.sh` audite **`.claude/agents/` du lab courant**. Sur le repo
`vibeflow-os` lui-même, ce dossier est vide : le script sort *« aucun agent dans .claude/agents —
rien a verifier »* et renvoie **vert sans rien avoir contrôlé**.

**Why:** le `CLAUDE.md` racine annonce « tout agent posé passe `check-agents.sh` » (ADR-044), ce qui
laisse croire à une garantie machine sur les agents versionnés (`plugin/*/AGENT.md`,
`plugin/dev-orchestrator/agents/*.md`). Ce n'est vrai que dans un lab où les agents ont été
*installés*, pas dans le repo de distribution. Constaté le 2026-07-25 en exécutant le plan 12-01.

**How to apply:** ne jamais présenter « `check-agents.sh` vert » comme une preuve de conformité
ADR-044 quand on travaille dans `vibeflow-os`. La vraie couverture des agents versionnés vient de
`plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` (T8/T8b : frontmatter
`description`/`model`/`memory`, densité ≤ 250 L, `vf-internal` sur les workers). Sur toute étape qui
touche un `AGENT.md`, s'appuyer sur T8 — ou lancer `check-agents.sh` depuis un lab de test où le
module est réellement installé.

**Le contournement légitime — et son piège de syntaxe.** On peut viser le dossier versionné avec
`--agents-dir`, mais l'option n'existe qu'en forme **collée** : `--agents-dir=plugin/…/agents`.
Passée en deux arguments (`--agents-dir plugin/…/agents`), elle est **silencieusement ignorée**, le
script retombe sur `.claude/agents` et sort en **rc=3 « INDETERMINE »**. Le gate ne se replie donc
pas en vert (bon comportement, cf. [[gate-jamais-de-repli]]) — mais un mandat qui lirait « rc≠0 =
KO » y instruirait un faux bloquant. Forme correcte, celle du bloc T8c :
`bash plugin/conductor/scripts/check-agents.sh --strict --agents-dir=<path>` → rc=0, avec le nombre
d'agents balayés et d'entrées d'allowlist résolues affiché (vérifier qu'il est **non nul** avant de
croire le vert). Mesuré le 2026-08-03 sur la Phase 23.

Voir aussi [[index-gsd-regenere-a-l-install]].
