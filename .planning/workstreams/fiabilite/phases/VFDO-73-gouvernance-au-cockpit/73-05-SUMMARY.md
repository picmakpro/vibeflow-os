# 73-05 — la régie dans la page Équipe (REGI-01, 02, 03, 06, 09, 11, 14, 15, 16)

Trace du rouge : `73-05-RED-TRACE.md`. Base : f8c91b29. Tête de reprise : 1efd1eb1 (VF_ETAT de 79-17 fusionné par le manager).

## Livré

- `ui/72-vf-regie-source.js` (184 lignes) : adaptateur unique (`VF_ETAT` : `lire('who'|'lock'|'connexion')`, `abonner`, `jeton`, `lireJson` ; repli `vf-who` + `__vfLive`), montage par
  `VF_COQUILLE.surOnglet(…, { cle: '72-vf-regie-source.js' })` (sans coquille : au chargement d'Équipe), nettoyage complet, registre `window.__vfEquipeVues = { declarer({ id, libelle, monter(conteneur), demonter() }), vues() }`,
  `window.__vfRegie = { arriver(r) → booléen, monte() }`, événements de document `vf-agent:ouvrir` `{ id, kind, declencheur: nom|ancre|rapport }` (annulable) et `vf-agent:lu` `{ id }`,
  écoute de `vf-regie:aller` `{ section }`, `vf-regie:redessiner`, `vf:onglet`, recherche (`#search`), Échap par crans, lecteur de repli `ouvrirRepli` (transcript réduit dans le panneau, `VF_SURCOUCHES.ouvrir` s'il existe),
  « Tout marquer comme relu » seulement si `window.__vfRegieLu.toutMarquer` existe et dès trois lignes à relire.
- `ui/72-vf-regie-rendu.js` (172 lignes) : en-tête, bascule `role=tablist` « Vue de l'équipe » (dès deux vues, position dans `sessionStorage` `vibeflow-cockpit:equipe-vue`), sections, lignes
  `li[data-vf-cle][data-vf-agent][data-vf-noeud][data-vf-etat]` mises à jour en place (une écriture seulement si le texte change), focus suivi par clé (titre de section si la ligne disparaît), région `aria-live`, filtre.
  Texte du disque en `textContent` seul, glyphes en nœuds SVG reposés depuis le tracé de 71 : aucun HTML construit.
- `ui/72-vf-regie-pied.js` (50 lignes) : `window.__vfRegiePied = { monter, maj, ajouter }` ; états « Lecture de l'équipe » (au-delà de 150 ms, `aria-busy`), « Aucun agent… », « Le direct n'est pas branché. »,
  « Source illisible : … », « Direct coupé : durées figées, données d'il y a … » (à 15 s, durées figées) ; `ajouter(bloc)` est le point de branchement du plan 73-07.
- `00-vibeflow.js` : une ligne existante modifiée (`TAB === 'equipe' && window.__vfRegie?.arriver(r)` avant le comportement existant), 298 lignes inchangé. `VENDORED.txt` : trois lignes `AJOUT` à leur place.
- Tests : `vm-dom.mjs`, `vm-regie-page.mjs`, `regie-page-commun.sh`, `chrome-regie.mjs`, `regie-rg-page.sh` (RG0.11, RG0.12, RG1.10 à RG1.12, RG1.20, RG2.1, RG6.20, RG9.20 à RG9.22, RG11.10, RG14.10, RG14.11, RG15.1 à RG15.10, RG16.1).

## Écarts

- Écart : ancres de RG15.4 sur `n:se-<id>` (seules des sessions entrent dans « À vous ») ; `n:ag-<id>` prouvé sur la ligne de l'arbre.
- Écart : l'arbre est une liste plate indentée par classe (`vf-rg-n1`, `vf-rg-n2`), pas des `ul` imbriquées (le filtre de recherche reste indépendant des parents).
- Écart : le détail en flux est `.vf-rg-plus` (la classe `.vf-rg-det` reste le « quoi » détaillé de la feuille de 73-04).
- Écart : RG1.12 porte deux témoins du même identifiant (fragment au retour de `vf:onglet` ; états de page) ; le premier est joué sur le repli (`vf:onglet` d'un événement de document), 80-10 n'étant pas livré : avec `VF_ONGLETS`, le fragment ne se lit qu'à `vf:onglet` (un chargement à froid sous `VF_ONGLETS` avec un fragment `#vf-…` n'est pas lu au montage : à revalider à l'arrivée de 80-10).
- Écart : RG6.20 : le verrou « réel » est un événement `lock` à forme projetée émis par l'`EventSource` enveloppé (patron de `chrome-verrou.mjs`), pas un `driver-lock.sh` réel posé dans le lab ; le témoin positif (ligne de mission affichée) précède le négatif.
- Écart : en source `vf-who` (repli), « Direct coupé » se lit aux poussées et aux 30 s (aucun événement de connexion) ; l'instant exact (15 s) n'est tenu qu'avec `VF_ETAT`.
- Écart : aucun mutant écrit sauf M-VERROU-PAGE-BRUT (régime allégé) ; il a été vu rouge. Le témoin RG9.22 a été vu sensible par un mutant jetable (3 appels `rerender` comptés).
- Écart : `70-vf-live.js` est à 300 lignes depuis 79-17 (bloquant de `check-file-size`, V4 de `test-cockpit-vendor.sh`), pas de mon fait.

## T27.B2 (demande du manager)

Cause examinée, pas le rendu de la régie : RG9.22 (sélection posée, événements `who`/`lock`/`connexion` des deux sources, minuterie de 30 s, puis rendu) ne compte **aucun appel au moteur** et laisse sélection et focus intacts
(vert ; un `rerender()` ajouté au rendu le rougit). Deux causes réelles, toutes deux déclarées : (1) `72-vf-equipe.js` rappelle `SC.rerender()` à chaque `vf-who` et toutes les 30 s (retiré au plan 73-08) ;
(2) la ligne d'arrivée de `00-vibeflow.js` rend la main à `__vfRegie.arriver(r)`, qui prend en charge l'ancre dès que la ligne existe (comportement voulu, RG15.4) : le clic sur une carte d'agent ne sélectionne alors plus rien dans le canevas,
sauf quand `who` n'est pas encore dessiné (course, d'où le un-sur-deux). Rejeu de `test-cockpit-transcript.sh` : 3 runs, T27.B2 vert, rouge, vert. À re-pointer au plan 73-10 sur l'ouverture de la ligne de la régie.

## Suites jouées (une fois sur la tête commitée ; échéance Chrome 30 s sauf mention)

- `test-cockpit-regie.sh` (toutes sections) : 214 PASS / 0 FAIL.
- `test-cockpit-chrome-fr.sh` : vert ; `test-cockpit-chaine-xss.sh` : 34 PASS / 0 FAIL ; `test-cockpit-accessibilite.sh` : 35 PASS / 0 FAIL.
- `test-cockpit-vendor.sh`, jouée seule : 251 PASS / 1 FAIL (V4 : `70-vf-live.js` à 300 lignes, hors plan).
- `check-file-size` (nouveaux fichiers, `00-vibeflow.js`, harnais) : OK ; `css-jetons.mjs` : 0 ; `check-machine-paths.sh` : OK ; `check-version-sync.sh` : seul écart, la ligne « suites » (230 pour 231, recomptée par le manager) ; `colonnes-cliquet.mjs verifier` : aucune hausse de mon fait.

## Rouges transitoires (fenêtre P73-D-39, mesurés)

| suite | identifiants rouges | re-pointage |
|-------|---------------------|-------------|
| `test-cockpit-equipe.sh` | EK10.2, EK13.0, EK13.3, EK14, EK14.2, EK18, EK18.1, EK18.2 | 73-08 |
| `test-cockpit-moteur-carte.sh` | K13.1, K13.2 | 73-08 |
| `test-cockpit-responsive.sh` | R14.1, R17.0, R17.1, R17.1b, R19.1, R19.2 | 73-09 |
| `test-cockpit-transcript.sh` | T27.B2 (un run sur trois) | 73-10 |

Mesurés verts malgré la liste déclarée : O6.14*, X4.0 à X4.2b, T26.8, T27.C1, T27.C2, T27.F1, EK1 à EK9 et EK11 à EK12, EK15 à EK17.

Rouges **hors liste**, non causés par la régie (à décider par le manager) :
- `test-cockpit-git-entete.sh` : 17 rouges identiques à 8 s et à 30 s (H2.3a, H2.3b, H9.2 et les mutants M-COUPURE, M-TABINDEX-DEFINITION, M-ARRIVER, M-TEXTE, M-ABSENT, M-MEMOIRE, M-MASQUE, M-REPOS, M-CHARGEMENT, M-DOUBLE-LECTURE, M-BLOC-VUE ×3, M-ECART) ;
  `76-vf-git-entete.js` n'a été touché depuis la base que par c411445f (73-06) ; H6.2, déclaré, n'a pas rougi.
- `test-cockpit-responsive.sh` : H0 (survivant d'hygiène à la fin de la suite) ; `test-cockpit-projet-visite.sh` : R3.18 (lecture du presse-papiers sur Projet, page sans régie), vu une fois à 8 s seulement, non rejoué.
- Les passes à 8 s ont produit des faux rouges (« coquille prête dépassée ») : écartées, la mesure retenue est celle de 30 s.

rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale)

## Correctifs de revue (point de fusion 2, relais du manager, commités avec 73-11)
- Ancre à froid : `__vfRegie.arriver(r)` rend true pour `^n:(se|ag)-` même non monté ; l'ancre est tenue et consommée au premier rendu où la ligne existe (défilement, focus), puis oubliée ; le fragment du montage la tient aussi si la ligne manque. Témoin RG17.R1 (rouge `false|false||true` puis vert), RG11.22 repasse au vert.
- Focus de « Tout marquer comme relu » : le bouton retiré alors qu'il porte le focus rend le focus au titre de « Terminé, à relire » (P73-D-29, UIFN-12). Témoin RG17.R2.
- « Tout marquer comme relu » marque tous les identifiants à relire (`ids` du modèle, +0 ligne), pas les huit affichés. Témoin RG17.R3 (rouge 8, vert 12).
Écart : un seul commit pour les trois points (même fichier, hunks entrelacés).

## Correctifs design de fin de phase
Six écarts du juge design de fin de phase (74/100) corrigés en une fois, plus un mineur ; témoins RG18.1 à RG18.7 (`regie-rg-pied.sh`, scénario `design` de `chrome-regie-pied.mjs`), mesures CDP à 1 440 px comparées aux jetons par sonde, vus rouges avant le correctif puis verts.
- Panneau latéral du moteur masqué sur Équipe (`#panel:not(.vf-rg-lecteur)`) ; le lecteur de repli pose la classe et la retire à sa fermeture, il reste affiché.
- Le nom est le bouton d'ouverture (`button.vf-rg-tog` enveloppe le nom) ; le caret (`.vf-rg-caret`) n'existe que sur un parent qui a des enfants, 44 × 44, nommé « Sous-agents, N », et replie ou rouvre ses sous-agents (ouvert par défaut). Lignes de 44 à 56 px.
- Caret nu, de la couleur du nom : les teintes d'état ne visent plus que le glyphe de tête de ligne.
- Détail `.vf-rg-plus` : `--raise`, `--r-ctl`, `--inset-box`, gap `--sp-8`, aligné sur la colonne du nom.
- Arbres de travail : lignes, repère d'ouverture (caret du tiroir dans le résumé), pastilles en texte neutre sans fond.
- Arbre : fil de 1 px (`--fil`) et coude de rayon 8 sur les niveaux 1 et 2, sans filet entre enfants.
- Mineur : « sans branche » remplace le tiret cadratin quand la branche manque.
Écart : le rendu visuel du fil sur plusieurs niveaux (continuations c1 et c2) n'est pas mesuré, seul le coude du premier niveau l'est.
rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale)
