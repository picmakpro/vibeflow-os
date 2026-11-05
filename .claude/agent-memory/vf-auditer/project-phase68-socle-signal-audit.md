---
name: project-phase68-socle-signal-audit
description: Audit securite socle Phase 68 (emetteur signal@1, vie, arbres), HEAD 0f016873, 2026-11-04 : fsmonitor ouvert via who.mjs, chaines non nettoyees hors champs nommes par le plan, lock plante ferme
metadata:
  type: project
---

Audit 68-01/02/03 (vf-cockpit-vie/arbres/signal.mjs), 2026-11-04, HEAD 0f016873, sondes sous scratchpad/p68.

**Ferme, sonde avec temoin positif** : script driver-lock.sh plante dans le lab (.claude/scripts, plugin/conductor, .vibeflow/cockpit, HOME=lab, lien symbolique depuis HOME) jamais execute ; arbres.mjs sans fsmonitor (git status nu = marqueur, emetteur sans DAG running = pas de marqueur) ; arguments git de arbres.mjs prefixes (HEAD..x, refs/...) et -C recoit un chemin absolu realpath ; --plugin-root exit 2 ; garde des champs du verrou (proto, types faux, null litteral) ; borne 10 s par appel (git qui dort 30 s : 10 appels = 100 s).

**Ouvert** : (1) who.mjs:111 ?? .planning/archives/stash/2026-08-16-MISSION-COCKPIT.dag.json
?? .planning/archives/stash/2026-10-22-phase-59-bundle-produit.dag.json
?? .planning/archives/stash/2026-10-29-phase-59-config-parallelisation.patch
?? .planning/archives/stash/2026-11-03-rangement-avant-retour-sur-main.patch
?? .planning/archives/stash/2026-11-03-worktree-etude-floorplan-non-commite.patch
?? .planning/workstreams/fiabilite/config.json
?? .planning/workstreams/fiabilite/milestone.lock
?? .planning/workstreams/fiabilite/state.json
?? .playwright-mcp/
?? python3 sans GIT_SUR, atteint par collectSignal via collectWho quand un DAG a un noeud running frais : le core.fsmonitor de .git/config s execute (marqueur ecrit). T-68-04 ne cadrait que arbres.mjs. (2) 22 chaines avec controles C0/C1 apres JSON.parse : phases.key/ws, layout.actif, missions.ws/phaseKey, jalons.ws, avancement.mission.nom, arbres.phaseActive.key/nom, equipe.* (task/role/id/dag/tree) ; JSON.stringify laisse U+0080-009F bruts ; la suite S7 ne couvre que l etape de noeud et le nom de worktree. (3) missions.ws et avancement.mission.nom sans masque ni borne (3 Mo emis, jeton ghp_ en clair).

**Why:** le plan listait des champs nommes, pas un invariant sur toute la sortie ; la suite verte ne testait que les champs nommes.

**How to apply:** sur un futur emetteur/mod du cockpit, fuzzer TOUTES les sources texte avec un marqueur ESC+U+009B et parcourir le JSON parse, jamais lire la liste des champs nettoyes. Outil : fuzz.mjs/secret.mjs (a refaire, scratchpad ephemere).
