---
name: project-phase71-terminal-cockpit-audit
description: Audit sécurité Phase 71 (terminal intégré au cockpit, code 227be6c5, 2026-11-04) — shell derrière origine Q ; ce qui est fermé par sonde, les 2 majeurs (server.json→ouvreur, pastejacking) et les pièges de sonde
metadata:
  type: project
---

Audit 2026-11-04, worktree phase-71, code figé 227be6c5 (HEAD ultérieur = docs seulement). Sondes sous scratchpad `audit-71/probes/` (p1..p13, harnais CDP `cdp.mjs`, mutants par `git archive` + `mut2.py`).

**Fermé, sondé avec témoin positif ET mutant qui rougit** : site tiers (no-cors, preflight, EventSource, WS, form, frame-ancestors, rebinding via `--host-resolver-rules`), XSS-de-P jusqu'au shell (même CSP contournée par `Page.setBypassCSP`), sorties xterm (seules DA1/DA2/DSR/CPR/DECRQM/couleurs OSC reviennent, formats fixes ; OSC 52 inerte ; liens non-http bloqués par `allowNonHttpProtocols:false` — mutant true ouvre data:/vbscript:/blob:), fuites (aucun secret ni frappe dans journal/SSE/export/fichiers/ps), cycle de vie (tout meurt sauf `nohup`, documenté A5), CSP/page de P identiques à v2.75.0 sans `--terminal`, vendor xterm = tarball npm à l'octet (sha512 = integrity), pas d'advisory GHSA/OSV pour @xterm/xterm 6.0.0.

**Ouvert** : (1) MAJEUR `vf-cockpit.mjs:154` branche O2c : `server.json` du lab (non fiable) → `terminal.url` passé à l'ouvreur système sans `estNotre` ni validation (file:///…Calculator.app capturé par faux `open`) ; recoupé par gsd-security-auditor (U-1). (2) MAJEUR conditionnel B2 : pastejacking, P écrit le presse-papiers sur geste, collage dans le tiroir = exécution (bash 3.2 immédiat, zsh à Entrée). (3) mineurs : PATH relatif/vide → `spawn('python3')` exécute `<lab>/python3` (cwd=lab) ; `window.open` de P copie sessionStorage → même `onglet` → popup prend la session ; xterm.js garde un listener `message` sans contrôle de source (planificateur VS Code) ; A4 dit « du compte » alors que `ps` est lisible de tout utilisateur (course amorçage via argv prouvée, même compte).

**Why:** le threat model 71 décrivait l'isolation Q/P mais pas les canaux non liés à l'origine (presse-papiers, opener/sessionStorage) ni la confiance accordée aux fichiers d'état du lab par le lanceur (famille M3 de la 67, nouveau site).

**How to apply:** pour tout futur audit de ce cockpit, rejouer d'abord (a) le `server.json` piégé avec faux `open`, (b) le collage multi-lignes, (c) le balayage de fuite avec mutant « journalise la sortie ». Piège de sonde : mon helper `req` posait un délai de 4 s qui coupait le flux `/flux` et faisait expirer la session (grâce) — vérifier qu'un flux de test est LU et sans délai avant de conclure sur un cycle de vie ; l'en-tête de jeton de P est `x-vf-cockpit-token` (marque blanche), pas `x-floorplan-token` (sinon export = 403 vide, balayage faux) ; `serveur.log` est en append : un mutant qui journalise pollue le témoin suivant, vider le journal. Outil : pas de `Write` dans ce rôle, heredoc `cat <<'EOF'` marche hors worktree (cwd scratchpad).
