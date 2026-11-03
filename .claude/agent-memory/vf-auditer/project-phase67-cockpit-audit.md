---
name: project-phase67-cockpit-audit
description: Audit sécurité Phase 67 (cockpit local floorplan, HEAD eb2e786d, 2026-11-01) — XSS stockée par foot, hooks du lab dans claude -p, famille « lab piégé » ; ce qui est fermé et comment c'est sondé
metadata:
  type: project
---

Audit du cockpit (serveur 127.0.0.1, SSE, agent `claude -p` confiné), 2026-11-01, HEAD eb2e786d.

**Fermé, sondé** : CSRF cross-origin, DNS rebinding (Host étranger), accès sans jeton, `.cache/server.json` et traversée `%2e%2e` = 403/404. Confinement `claude -p` : Bash hors liste refusé, Read hors racine refusé y compris par symlink (témoin positif : fichier ordinaire dedans lisible). `body.session` = `--dangerously-skip-permissions` n'injecte rien : la CLI 2.1.316 sort en erreur (`--resume` sans valeur), fail-closed. D-14 (dernière commande) : aucune fuite SSE/fichier/log.

**Ouvert** : (1) XSS stockée réelle, sink = `foot` non échappé dans le patch P2 de `cardFoot` (viewer.html), alimenté par `wave:` d'un PLAN.md, `stage` d'un .dag.json, statut BACKLOG ; aucune CSP, donc exfiltration du jeton vers une origine tierce prouvée. (2) hooks de `<lab>/.claude/settings.json` exécutés par `claude -p` sans dialogue de confiance (témoin : hookRan true ; `--setting-sources user` le ferme). (3) une règle `permissions.allow` Bash côté utilisateur défait le confinement (la mesure 67 ne testait que bypassPermissions). (4) famille « lab piégé » : `<lab>/.claude/scripts/driver-lock.sh` exécuté à l'ouverture si conductor absent (install cockpit seul = flux testé), `stop`/`--rebuild` exécutent le serve.mjs de la sortie du lab, build écrit à travers des symlinks de `.vibeflow/cockpit/` (nouveau site du motif CONCERNS « confinement de chemin »). (5) corps JSON `null` sur /api/ask tue le serveur.

**Why:** le threat model 67 ne listait ni XSS par données du lab ni exécution de config du lab ; T-67-06 n'excluait que `<lab>/plugin/`.

**How to apply:** sur un futur audit de ce cockpit, rejouer d'abord le fuzz « un marqueur onerror par champ planning » (CDP + Chrome headless ; `--dump-dom` ne rend pas la main à cause du SSE) ; ne pas croire `h()` partout dans le viewer : les ajouts VibeFlow (P2, `foot`) sont le maillon faible. Outil : pas de `Write` dans ce rôle, écrire la mémoire et le rapport par heredoc Bash.
