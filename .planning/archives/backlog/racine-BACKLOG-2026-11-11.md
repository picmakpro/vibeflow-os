## Cockpit : le `claude` lancé depuis le terminal reçoit `CLAUDE_EFFORT` et `CLAUDE_PID` de la session parente — NON VÉRIFIÉ (2026-11-06) — CLOS (2026-11-11, AUDC-B-06)

**Priorité : non fixée.** À vérifier avec le vrai binaire avant toute décision.

**Origine :** recette par juge de la Phase 72, 2026-11-06.
- **Observé :** le `claude` lancé depuis le terminal du cockpit reçoit `CLAUDE_EFFORT` et `CLAUDE_PID`, ceux de la session Claude Code qui a démarré le serveur du cockpit. Le filtre de `plugin/cockpit/scripts/vf-cockpit-terminal-env.mjs` (vers la l.18, Phase 71) retire `CLAUDE_CODE_*` et `CLAUDECODE`, mais pas ces deux variables.
- **NON vérifié :** que `CLAUDE_EFFORT` impose bien au `claude` lancé l'effort du parent (avec le vrai binaire).
- **Attention :** retirer tout `CLAUDE_*` enlèverait aussi des réglages voulus, comme `CLAUDE_CONFIG_DIR` ; le filtre doit rester nominatif.

**Clos (2026-11-11) :** AUDC-B-06 filtre nominativement les deux variables de l'environnement du terminal (commit 9d662c87, `.planning/research/2026-11-10-audit-cockpit/REGISTRE.md`). Non vérifié avec le vrai binaire : le filtre rend la question sans objet.

**Déclencheur de reprise :** une passe sur l'environnement du shell du terminal, ou un lancement dont l'effort surprend.

