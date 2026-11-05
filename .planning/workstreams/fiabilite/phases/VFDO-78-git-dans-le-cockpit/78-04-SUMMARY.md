---
phase: 78
plan: "04"
subsystem: cockpit
requirements-completed: [GITC-01, GITC-02, GITC-03, GITC-05, GITC-12]
key-files:
  created:
    - plugin/cockpit/scripts/vf-cockpit-git-entete.mjs
    - plugin/cockpit/skills/cockpit-moteur/assets/ui/76-vf-git-entete.js
    - plugin/cockpit/scripts/tests/test-cockpit-git-entete.sh
    - plugin/cockpit/scripts/tests/css-jetons.mjs
  modified:
    - plugin/cockpit/scripts/vf-cockpit-build.mjs
    - plugin/cockpit/scripts/vf-cockpit-live.mjs
    - plugin/cockpit/scripts/vf-cockpit-server.mjs
    - plugin/cockpit/scripts/vf-cockpit-equipe-carte.mjs
    - plugin/cockpit/skills/cockpit-moteur/VENDORED.txt
commits: [7c404697, acf0fc84, d077cbff, 3e1cc33e, a8dcd9bb, 24f69cfc]
---

# Phase 78 Plan 04 : en-tête Git du cockpit — Summary

Le nom du dossier du dépôt principal sur les trois onglets, la branche et le worktree sur une seconde ligne (bouton), un ouvreur icône sous 1000 px, le bloc de vue racine qui dit ce que montre la vue, la liste « Repositories » retirée. Sans git : ni ligne, ni ouvreur, ni bloc `.vf-nom`. `viewer.html` et `00-vibeflow.js` n'ont pas bougé (diff vide contre `main`).

Preuves : `78-04-RED-TRACE.md` (rouge avant le code, par tâche, avec les obtenus). Suite `test-cockpit-git-entete.sh` : 74 réussis, 0 échoué, 0 sauté ; sections H1 à H6, mutants M-DEPOT, M-TEXTE, M-ABSENT, M-REPOS, et cinq témoins de `css-jetons.mjs`.

## Accroches dans les fichiers partagés (une ligne chacune, à garder au rebase des plans 05 et 09)

| Fichier | Accroche | Repère |
|---|---|---|
| `vf-cockpit-live.mjs` (`ecrirePage`) | `g.meta.vfGit = old.meta?.vfGit;` à côté de `root` et `vfLogos` | commentaire `/* 78-04 */` |
| `vf-cockpit-server.mjs` | import de `missionsEnCours` ; `pageEquipe` passe `git: GP?.meta?.vfGit, missions: missionsEnCours(GP)` à `buildEquipeGraph` | commentaire `78-04 : en-tête Git et bloc de vue` |
| `vf-cockpit-equipe-carte.mjs` | `missionsEnCours(gp)` (neuf), options `git` et `missions`, `meta.vfGit` et `meta.vf.missions` | commentaire `78-04` |
| `vf-cockpit-build.mjs` | `g.meta.vfGit = enteteGit(lab)`, `project.meta.vfGit = g.meta.vfGit`, page d'index avec `repos: []` (graph.json garde `repos`) | commentaire `78-04` |
| `VENDORED.txt` | une ligne `AJOUT assets/ui/76-vf-git-entete.js`, rangée dans le bloc des AJOUT (après 75), non en fin de fichier | |

## Contrat d'événements DOM (consommé par 78-06, 78-09, 78-10)

Tous sur `window` (`CustomEvent`).

| Événement | Sens | `detail` |
|---|---|---|
| `vf-git:basculer` | émis par la ligne et l'ouvreur au clic | `{ source: 'ligne' \| 'ouvreur' }` |
| `vf-git:etat` | reçu (émis par le tiroir) | `{ ouvert: boolean }` : tient `aria-expanded` des deux boutons |
| `vf-git:entete` | reçu | objet d'en-tête `{ etat: 'ok'\|'indisponible'\|'absent', depot, branche, worktree, detache, sha7 }` ; `absent` masque la ligne et l'ouvreur (attribut `hidden`) |
| `vf-git:signal` | reçu (émis par `70-vf-live.js` au plan 78-09) | rien : relit `GET /api/vf/git/entete` avec l'en-tête `x-floorplan-token` (renommé `x-vf-cockpit-token` dans la page construite) si `FLOORPLAN_SERVER.token` existe ; réponse refusée hors schéma |

Éléments : `button#vf-git-ligne.vf-git-ligne` (spans `.vf-git-branche`, `.vf-git-wt`, `.kbd` « g »), `button.btn.icon#vf-git-ouvreur` en tête de `.hr`, `aria-controls="vf-git-tiroir"` sur les deux. La touche `g` n'est pas câblée ici (plan 78-06).

## Schéma attendu de `GET /api/vf/git/entete` (route posée au plan 78-05)

`{ schema: 'vibeflow/cockpit-git-entete@1', ...enteteGit(root) }`, soit `etat`, `depot`, `branche`, `worktree`, `detache`, `sha7`. La page n'applique une réponse que si `schema` vaut exactement cette chaîne et `etat` est `ok`, `indisponible` ou `absent`.

## Écarts et choix à connaître

1. **Noms de la page construite.** L'assemblage renomme `Floorplan` en `VibeFlow`, `FLOORPLAN_SERVER` en `VF_COCKPIT_SERVER`, `x-floorplan-token` en `x-vf-cockpit-token`. Le fichier 76 s'écrit avec les noms amont (comme `00-vibeflow.js`) ; la suite, qui parle à la page construite, emploie les noms renommés.
2. **Sous-titre Code : « fichiers » et non « modules ».** Le décompte est `G.files.length` (tous les fichiers lus), « modules » aurait été inexact. H6.1 n'exige qu'un nombre et le suffixe « lus dans le dépôt. ».
3. **Largeur de 1000 px.** La requête media du viewer (`max-width: 999px`, ou tactile sous 1280 px) ne s'applique pas à 1000 px en pointeur fin : H4.1 mesure 375, 700, 768, 999 (ligne masquée, ouvreur 44 × 44) puis 1000 et 1440 (ligne visible, ouvreur caché). Le tactile n'est pas émulable avec `chrome-session.mjs`.
4. **Déclencheur de H2.3.** Modifier l'objectif d'un plan existant ne réécrit pas `project.html` (aucun patch) : le témoin ajoute un `01-02-PLAN.md`. Le témoin positif H2.3a prouve que la réécriture a eu lieu.
5. **Mission « en cours » (H6.2).** Un nœud `running` ne fait une mission `active` que si son verrou est vivant (P68-D-05). La suite sert le cockpit avec `VF_COCKPIT_SCRIPTS_DIR` pointant un faux `driver-lock.sh` tenu (même fixture que `test-cockpit-projet.sh`), pour le serveur seulement.
6. **Course au premier rendu.** Le premier rendu du viewer peut précéder l'exécution du fichier 76 (le test H6.1 a rougi une fois sur quatre). Le bloc de vue est donc réécrit à l'arrivée du fichier, sur `ready` et sur `render` ; quatre rejeux de H6, quatre verts. La cause n'est pas rejouable à la demande.
7. **Mutant M-REPOS ajouté** (non demandé) : H6.5 était vert d'emblée (le retrait de « Repositories » est posé par la tâche 1) ; M-REPOS prouve que le témoin sait rougir.
8. **Témoin « PATH sans git »** : `PATH=/nonexistent DEVELOPER_DIR=/nonexistent` fait échouer le shim `/usr/bin/git` (macOS) ; sur un poste où git ne peut pas être masqué, la suite annonce H5.1b SAUTÉ, jamais réussi.
9. **Dégradation, périmètre de la preuve** : la structure comparée au témoin (cmp) est celle de l'en-tête (`header` et ses descendants : balise, id, classes), 0 erreur de page et 0 violation CSP ; le reste de la page n'est pas comparé octet pour octet (horodatages, verrous).
10. **Téléphone (≤ 700 px) : écart à l'UI-SPEC §5 et à P78-D-20.** L'icône de 44 px dans `.hr` cassait `test-cockpit-responsive.sh` (6 rouges : R3, R13.2, R20 à 390 px, cf. `78-04-RED-TRACE.md`) : l'en-tête du téléphone tient sur une rangée et range ses actions dans le menu « ⋯ » (P70-D-01, arbitrage Samuel, AskUserQuestion session principale, 2026-11-03). Sous 700 px l'ouvreur est donc une entrée « Historique Git » du menu « ⋯ » (reprise générique par `02-vf-telephone.js`, clic relayé) ; l'icône de 44 px en tête de `.hr` ne vaut que de 701 à 999 px. À confirmer par le juge de design.
11. **Texte par défaut sans git** : `#proj-name` reçoit le nom du dossier du lab, ce qui change le nom affiché par rapport à avant (c'est l'objet de GITC-01), jamais la structure.

## Captures

Aucune capture produite par ce plan : la preuve est dans les mesures CDP de la suite (rectangles, `scrollWidth`, `getComputedStyle`). Les captures du juge de design sont à la charge du manager (P78-D-16, UI-SPEC §8.2).

## Suites rejouées

`test-cockpit-git-entete.sh`, `test-cockpit-vendor.sh`, `test-cockpit-assemblage.sh`, `test-cockpit-marque-blanche.sh`, `test-cockpit-onglet-code.sh`, `test-cockpit-chrome-fr.sh`, `test-cockpit-projet.sh`, `test-cockpit-equipe.sh`, `test-cockpit-serveur.sh`, `test-cockpit-direct.sh` : 0. `test-cockpit-responsive.sh` : 0 après la correction du téléphone (rouge avant, voir ci-dessus). Les suites projet, équipe, serveur, direct ont été rejouées avant cette correction ; elles ne lisent pas le bouton.
