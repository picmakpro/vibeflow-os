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
commits: [7c404697, acf0fc84, d077cbff, 3e1cc33e, a8dcd9bb, 24f69cfc, 6884b590, e8a21ce6]
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

## Correction design (critique fraîche du 2026-11-06 ; P78-D-01, D-09, D-19, D-20, D-34, D-35)

Correction ciblée, une passe, fichiers : `assets/ui/76-vf-git-entete.js`, `test-cockpit-git-entete.sh`. Traces rouge puis vert : section « Correction design » de `78-04-RED-TRACE.md`. Suite : 98 PASS / 0 FAIL.

- **F1 (majeur, D-01, D-09)** : `76` pose `G.project.name` au nom du dépôt principal (suffixe retiré) juste après avoir écrit `#proj-name`. Le panneau lit ce nom : `depot` partout, plus de `wt-a`, `wt-a — Projet`, `wt-a — Équipe`, sur les trois onglets. Le titre de l'onglet est écrit AVANT par `00-vibeflow.js` et garde sa forme (nom du dossier du lab, `R6.1` vert) ; les clés enregistrées par nom (flux `flows:<nom>`, visite `tour-seen:<nom>`) lues au chargement gardent leur valeur : aucun utilisateur ne perd ses flux ni ne revoit la visite. Les sources serveur citées (`vf-cockpit-project.mjs:155`, `vf-cockpit-equipe-carte.mjs:61`, regex de `vf-cockpit-server.mjs:136`) n'ont PAS été touchées : y retirer le suffixe changeait ces clés pour rien, et le nom du dépôt n'y est pas connu (posé par `build.mjs` après coup, hors périmètre). Écart assumé : l'assertion H2.2 du titre comparait à `graph.project.name` ; elle comparait donc au nom que `76` remplace maintenant, ce qui la rendait fausse sans que le titre ait changé ; elle compare à `meta.rootName` (le nom du dossier du lab).
- **F3 (majeur, P78-D-34)** : seconde ligne masquée sous 1280 px, ouvreur icône de 44 px de 701 à 1279 px ; le nom et la ligne partent toujours ensemble sous 1000 px (ou tactile sous 1280 px), le nom reste de 1000 à 1279 px. Sans git, ni l'un ni l'autre (H5.1 inchangé, vert).
- **F5** : même seuil de passage sur deux rangées avec et sans git (870 px). La cause est la base flex de la zone de recherche `.hc` (le saut de ligne se décide sur les bases, pas sur la largeur de `#search-btn`) : elle cède les 48 px de l'icône sur la rangée repliable ; de 1000 à 1279 px (grille) c'est la largeur de la recherche, comme le viewer le fait déjà pour le bouton Thème.
- **F6** : « Branche indisponible » prend la couleur normale de la ligne (`--text-3`, déjà ≥ 4,5:1), règle `--text-4` retirée.
- **F8** : anneau de focus de la seconde ligne à l'intérieur de la pastille (décalage −2 px, comme celui du tiroir) : aire d'intersection avec le nom 279,7 → 0 px².
- **F9** : sous-titre du bloc de vue Projet = `Phase N en cours, k phases faites sur n.` (jalon actif, mêmes chiffres que le moteur), repli `n phases · m plans.` ; ne contient plus le titre ni le nom du jalon. Calculé côté page à partir de `meta.vf` : `G.project.summary`, lu ailleurs (visite, questions), n'est pas modifié.
- **F11 / P78-D-35** : HEAD détaché en texte neutre dans l'en-tête (règle `--warn-text` retirée ; la classe `vf-git-detache` reste, elle sert aux tests et à la sémantique).
- **F13** : le titre du bloc de vue est écrit en nœuds de texte séparés par des éléments `<wbr>` après chaque `/` et `-` (DOM, jamais d'`innerHTML`) : coupures mesurées uniquement après un séparateur ou une espace.

Valeurs posées : aucune valeur de padding, marge ou écart nouvelle ni modifiée (`css-jetons.mjs` rc 0, diff relu ligne à ligne) ; largeurs d'ouvreur et de recherche seules (`44px`, `calc(min(460px, 24vw) - 48px)`, `calc(36vw - 96px)`), sans jeton équivalent à échanger au rebase.
Hors mandat, non faits : F4, F7 (avis de Samuel attendu), F10 (se règle au rebase de la 71.5).

### Correction design : points ouverts remontés au manager

1. **`test-cockpit-responsive.sh` R1, R2, R8, R9 rouges à 1 024 px (onglet Code, pire en-tête réel)** : conflit entre P78-D-34 (icône de 44 px de 701 à 1279 px) et P70-D-16 (recherche d'au moins 200 px, `01-vf-responsive.js`). La ligne unique de bureau (hl ≥ 342, hc ≥ 200, hr = contenu) n'a plus que 1 034 px de contenu minimal avec les deux boutons optionnels et l'icône : sans autre geste, `#btn-panel` sort de la fenêtre de 10 px (998..1034 sur 1024) ; avec le plancher de la recherche abaissé à 152 px de 1000 à 1279 px (mon réglage actuel), l'en-tête tient mais R1/R2/R8/R9 disent « recherche : 174 px, minimum 200 ». Le plancher 200 est une décision P70 : à trancher (assouplir le plancher en présence de git, ou masquer un bouton optionnel, ou retirer l'icône de 1000 à 1279 px). Non tranché ici.
2. **`test-cockpit-projet.sh` O6.11 rouge (1440 et 390 px)**, vert sur HEAD (rejoué sur `git archive`) : le sous-titre court de F9 révèle une incohérence du viewer : après « Passer », la vue restaurée est cadrée avec une zone libre plus basse de 26 px (y 244) que celle de la vue d'avant la visite (y 218), alors que la hauteur du bloc de vue est la même (77 px) dans les deux états. Avec l'ancien sous-titre, plus long, les deux valeurs coïncidaient par hasard. Cause côté sauvegarde de vue de la visite (`40-tour.js` / viewer), hors de mes fichiers : non corrigée. Deux essais de recadrage dans `76` n'ont rien changé et ont été retirés.
3. **Fichiers hors liste touchés, par conséquence de F9** : `test-cockpit-chrome-fr.sh` F9.2 et `chrome-statut.mjs`. L'ancienne attente (« Jalon v1 · phase 1 (Socle) · prête à planifier. ») était la répétition du titre et du statut que F9 retire ; `sousTitre` est lu sur `#ctx-desc` et vaut « Phase 1, 0 phase faite sur 1. » (« en cours » seulement si le statut est actif) ; la pastille française garde sa garde, F9.1 (aucun statut brut visible) reste vert.

### Correction D-39 (mgr78-reprise, 2026-11-06) : FAITE

P78-D-39 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-06 : « Recherche à 152 px (Recommandé) »), amende P70-D-16. Traces : section « Correction D-39 » de `78-04-RED-TRACE.md`. Point 1 des « points ouverts » ci-dessus : fermé.
- **76-vf-git-entete.js** : 76 pose `data-vf-git` sur `header` tant que l'ouvreur est posé (retiré si l'état devient `absent`) et `data-vf-invite="Chercher…"` sur `#search-btn` (inerte hors requête). Dans `@media (min-width: 1000px) and (max-width: 1279px) and (not (pointer: coarse))` : `header[data-vf-git] .hc { min-width: 152px }`, et l'invite d'origine (`.st`, déjà traduite par 80) est masquée au profit de `#search-btn::after { content: attr(data-vf-invite) }`. Rien n'est réécrit : hors plage, ou sans Git (76 sort avant d'injecter le style), l'original et ses 200 px reviennent. `viewer.html`, `00-vibeflow.js` et `01-vf-responsive.js` non touchés ; 170 lignes.
- **test-cockpit-responsive.sh** : `viol.mjs` n'accepte la borne de 152 px que sous le drapeau `git` (labs avec dépôt) et de 1 000 à 1 279 px ; R1, R2, R8, R9 passent ce drapeau, 200 px restent exigés partout ailleurs. Lab neuf sans Git (`mklab … sans-git`) et bloc D39 (plancher calculé, invite, plancher mesuré, R1 sans drapeau à 1 024 et 1 280 px, mutants M1 et M2). 320 PASS / 0 FAIL.
- **Valeurs posées** : `152px` (largeur plancher, sans jeton équivalent : plancher mesuré de la recherche) ; aucun padding, marge ni écart nouveau ou modifié ; `css-jetons.mjs` rc 0 sur 76 et 77.
- **Déviations** : aucune. `chrome-responsive.mjs` (hors liste) non modifié : le plancher de 200 px reste son minimum, la borne conditionnelle vit dans le filtre `viol.mjs` de la suite.
- Mesure : à 1 024 px avec Git, la recherche mesure 174 px (onglet Code, tous les boutons optionnels) ; sans Git elle dépasse 200 px.
