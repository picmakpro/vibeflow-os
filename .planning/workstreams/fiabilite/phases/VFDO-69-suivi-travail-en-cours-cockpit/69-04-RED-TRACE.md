# 69-04 — Trace du rouge : transcript à la demande, onglet Équipe, rendu de l'arbre (P69-D-24)

Date : 2026-11-03. Code testé : celui de la branche `feat/phase-69-suivi-travail` à la tête `3b364ad1` (équipe) puis `443277bb` (transcript), aucun
fichier de code modifié par ce plan. Les suites ont été écrites AVANT tout code de `vf-cockpit-transcript.mjs`, de la route `/api/vf/transcript`, de
`/equipe.html`, de `ui/71-vf-equipe-rendu.js` et `ui/72-vf-equipe.js` (aucun n'existe).

Commits des suites :
- `3b364ad1` — `test-cockpit-equipe.sh` : sections E23 et EUI ajoutées (160 insertions, 0 retrait).
- `443277bb` — `test-cockpit-transcript.sh` créée (T0, T24, T25 dont M-JETON et M-PORTE, T26).

Commandes rejouées :
- `bash plugin/cockpit/scripts/tests/test-cockpit-transcript.sh` -> `25 PASS / 35 FAIL`, code 1, 36 s.
- `bash plugin/cockpit/scripts/tests/test-cockpit-equipe.sh` -> sections E23 et EUI : 4 PASS / 14 FAIL (le reste de la suite évolue avec 69-03, hors de ce plan).

Fixtures : synthétiques (marqueurs `*-69`, jeton factice `ghp_abcdefghijklmnopqrstuvwx`) ; aucun transcript réel lu ni copié.
Les temporaires vivent dans `mktemp`, leur arrêt passe par `hygiene.sh` seul (`vf_hyg_stop`, `vf_hyg_assert` : `H0` vert, leurre vivant T25.14).

## Contrôles positifs verts (la fixture et le harnais fonctionnent)

| Libellé | Ce qu'il prouve |
|---|---|
| T0.1 à T0.8 | chacun des huit marqueurs négatifs (PENSEE, FICHIER-LU, TOOLUSERESULT, SORTIE-OUTIL, ATTACHMENT, COMMANDE-SECRETE, DESCRIPTION, SUIVI) est dans la fixture |
| T0.9 à T0.12 | jeton factice présent ; types de lignes réels ; emplacements `tool_result` / `toolUseResult` / `thinking` ; fixture `--gros` > 9 Mio |
| T25.0 | serveur démarré, jeton lu, leurre vivant, la fixture du HOME porte les 8 marqueurs |
| T25.3 | sans jeton : 403 (apparié au 200 attendu de T25.1) |
| T25.9 | POST avec jeton : 405 |
| T25.10 | hello liste `ag1`, un événement `who` arrive, 0 fuite dans le flux |
| T25.11a, T25.11b, T25.11 | le balayage voit >= 5 fichiers, trouve les marqueurs injectés (témoin), 0 marqueur dans `.vibeflow/cockpit/` et la sortie du serveur, `equipe.html` non écrit |
| T25.12, T25.13 | journal : 200 et >= 1 événement, 0 marqueur ; export : 200 et données du lab, 0 marqueur |
| T25.14 | le leurre est vivant après l'arrêt du serveur |
| T25.16a | un hello propre part, puis hello et patch propres dans le flux (double de `vf-cockpit-live.mjs`) |
| T26.0 | CSP réduite de `/project.html` = chaîne de v2.75.0 |
| E23.0, E23.8a, E23.8, E23.9 | serveur et `/project.html` ; sonde sans bruit sur le tiroir tel quel ; la sonde voit « Show the transcript now » ; `equipe.html` jamais sur disque, `project.html` présent |

## Témoins rouges (attendu / obtenu recopiés)

Raison commune : la règle visée est absente (module, route, page, couche d'affichage inexistants), jamais une fixture morte ni une erreur de syntaxe
(`bash -n` vert, positifs verts à côté).

### Réducteur (CKPT-24)
- **T24.1 à T24.16** — attendu : mandat, messages, outils visibles, aucune sortie d'outil, `tronque`, bornes ; obtenu : `[module absent]` pour chacun
  (T24.5 à T24.12 : le négatif est apparié aux positifs T24.1 et T24.3, jamais un vert à vide ; la valeur `module absent` les fait échouer).
  Contrôle de capacité (hors dépôt, copie de travail jetable avec un réducteur et une couche d'affichage minimaux) : T24.1 à T24.13, T24.15, T24.16 et
  T26.1 à T26.4 passent ; T24.14 a rougi sur la durée (2 028 ms pour un parse complet de 9,5 Mio) : l'assertion sait donc rougir, un vrai
  réducteur borné doit tenir la fenêtre (tête 256 Kio, queue 8 Mio).

### Route authentifiée (CKPT-25)
- **T25.1** — attendu `200|vibeflow/cockpit-transcript@1|true` ; obtenu `404|non-json|non-json` (route absente).
- **T25.2** — attendu `pos=2|neg=0` ; obtenu `pos=0|neg=0` (les positifs manquent : le négatif ne se contente pas du vide).
- **T25.4** — attendu `400|id-invalide` ; obtenu `404|non-json`.
- **T25.5** — attendu `200|inconnu` ; obtenu `404|non-json`.
- **T25.6** — attendu `200|true` ; obtenu `404|non-json`.
- **T25.7** — attendu `200|inconnu` ; obtenu `404|non-json` (apparié à T25.6).
- **T25.8** — attendu `no-store` ; obtenu `undefined` (la réponse 404 n'a pas d'en-tête).
- **T25.15 (M-JETON)** — le mutant est appliqué (`appliqué:1`, `if (false)` à la place du contrôle du jeton dans la copie de la sortie) ;
  attendu `appliqué:1|sans-jeton:200` ; obtenu `appliqué:1|sans-jeton:404` (la route n'existe pas encore).
- **T25.16** — attendu `0,true` ; obtenu `1,false` : un snapshot portant `mandat` est encore émis dans le hello (seule `doing` est refusée).
- **T25.16b** — attendu `patch` ; obtenu `patch,who,patch,who` : les événements portant `mandat`, `outils` et `messages` passent dans le flux.
- **T25.16c** — attendu `false` ; obtenu `true` : la valeur interdite sort du serveur.
- **T25.17 (M-PORTE)** — le mutant (garde `porte*` rendue toujours fausse dans une copie de `vf-cockpit-server.mjs`) est appliqué ;
  attendu `appliqué|copie:1|original:0` ; obtenu `appliqué|copie:1|original:1` : l'original ne se distingue pas encore du mutant, faute de la
  clé `mandat` dans sa liste de refus (C8). Rouge pour la bonne raison ; il passera quand l'original refusera, sans cesser de voir le mutant.
  Limite : la mutation vise une constante `porte*` sur une seule ligne ; si 69-05 à 69-08 renomment ou découpent la garde, `appliqué` deviendra
  `non-appliqué` et la suite rougira nommément.

### Rendu et CSP (CKPT-26)
- **T26.1 à T26.4** — obtenu `[fichier absent]` (la couche d'affichage n'existe pas) ; attendu `ok`, `true`, `0`, `true|true`.
- **T26.5** — attendu la chaîne de v2.75.0 (`default-src 'none'; script-src ; style-src 'unsafe-inline'; …; object-src 'none'`) ;
  obtenu `default-src 'none'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'` (404, CSP de base).
- **T26.6** — attendu = CSP réduite de `/project.html` ; obtenu la CSP de base (mêmes raisons).
- **T26.7** — ligne affichée : jouée (Chrome présent), non sautée. Attendu `img=0|texte=true` ; obtenu `bouton Lire le transcript absent`
  (la page `/equipe.html` est un 404, le bouton `[data-vf-transcript]` n'existe pas).

### Onglet Équipe (CKPT-23) — `test-cockpit-equipe.sh`, section E23
- **E23.1** — attendu `200` ; obtenu `404`.
- **E23.2** — attendu `VibeFlow · Équipe` ; obtenu `aucun titre`.
- **E23.3** — attendu `vibeflow/cockpit-equipe@1|equipe` ; obtenu `graphe illisible : zone de données introuvable : marqueur de début absent`.
- **E23.4** — attendu `-|se-<SID>|ag-mgr1|ag-mgr1|ag-mgr1~termines|active|done|0` ; obtenu la même erreur de graphe.
- **E23.5** — attendu `OK` ; obtenu `KO clé requise absente : schema | meta | project | nodes | files | links | flows | schema = undefined`.
- **E23.6** — attendu `vfTab|lien|intitule` ; obtenu `||` (`00-vibeflow.js` ne connaît ni `equipe`, ni `equipe.html`, ni « Équipe »).
- **E23.7** — attendu `aucune` ; obtenu `fichier absent : 71-vf-equipe-rendu.js` / `fichier absent : 72-vf-equipe.js`.
  La sonde compare les littéraux jugés anglais par `litteraux` + `estAnglais` à la liste de ceux que `estAnglais` signalait déjà dans
  `70-vf-live.js` et `00-vibeflow.js` à v2.75.0 (du français sans accent : « Session », « Verrou »…) ; E23.8a le vérifie.

### Rendu de l'arbre (CKPT-19 à 22) — section EUI (vm, `71-vf-equipe-rendu.js` absent)
- **EUI.1** — attendu `mgr1,<SID>` ; obtenu `aucun élément data-vf-agent : fichier absent`.
- **EUI.2** — attendu `appelle` ; obtenu `non` (le tiroir n'appelle pas `__vfEquipeRendu.arbre`).
- **EUI.3** — attendu `ferme|resume` ; obtenu `aucun élément data-vf-agent : fichier absent`.
- **EUI.4** — attendu le lien `href="project.html#r=f%3A.planning%2Fmissions%2Fm1.dag.json%23revue-p3"` ; obtenu `fichier absent`.
- **EUI.5** — attendu `true|""` ; obtenu `fichier absent`.
- **EUI.6** — attendu `true|true` ; obtenu `fichier absent`.
- **EUI.7** — attendu `5` ; obtenu `0`.

## Surfaces fixées pour 69-05 à 69-08

`reduireTranscript(fichier, { root })` (async admis) rend `{ schema, id, mandat, messages, outils, tronque }` ; `GET /api/vf/transcript` (en-tête
`x-vf-cockpit-token` sur la sortie assemblée, renommé de `x-floorplan-token`) ; `/equipe.html` en mémoire, jamais écrit ; `window.__vfEquipeRendu
= { arbre, agentsDuNoeud, transcript, pied }` ; `[data-vf-transcript]` et `.vf-transcript` ; les clés `mandat`, `messages`, `outils` refusées à toute
profondeur du flux et du hello (C8). Le harnais `porte.mjs` pose `VF_COCKPIT_SCRIPTS_DIR` sur le dossier de scripts testé : le contrat de C8 doit
se lire par `resolveScriptsDir`.
