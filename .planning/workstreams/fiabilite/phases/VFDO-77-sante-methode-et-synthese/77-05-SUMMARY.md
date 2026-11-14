# 77-05 — Coquille de la Synthèse : SUMMARY

## Livré

- `ui/74-vf-synthese.js` (129 lignes, aucune ligne au-delà de 160 points de code) : bouton « Synthèse » juste après `#btn-health`, panneau à blocs ordonnés, registre
  `window.__vfSyntheseBlocs` (sans réaffectation, ordre fixe visite, burnup, methode, cout, id inconnu ignoré), ligne-résumé `button.row.vf-rep[data-vf-sy-resume]` en tête de
  l'aperçu (muette sans texte de `majResume`), focus sur le `h2`, Échap, fermeture sur sélection d'une carte, zone vive, feuille propre (`vf-sy-coquille`). Installation par
  `VF_COQUILLE.surOnglet(…, { cle: '74-vf-synthese.js' })` sur l'onglet `projet` servi seulement, nettoyage rendu. Aucune lecture du jeton hors de `VF_ETAT`, aucun POST, aucun stockage.
- Banc `tests/chrome-synthese.mjs` (outils : `labFixture`, `AMORCE_ECOUTEURS`, `AMORCE_VISITE`, `ecrireStockageAvantChargement`, `journalReseau`, `sondeStyle`, `mesurerUneFoisPose`,
  `sourceTemoin`/`ecrireBlocTemoin`) et ses scénarios ; suite `test-cockpit-synthese-page.sh` : B1 à B9, W1 à W3, W10, W11a, W13a, W14, W16, W18 à W20, RB1, O1, R1, CS1, E0.
- Ligne `AJOUT assets/ui/74-vf-synthese.js` de `VENDORED.txt`, ligne de durée de la suite dans `scripts/ci-shard-suites.sh`, compteur « 241 suites » des deux README racine,
  `77-05-RED-TRACE.md`.

## Contrat pour 77-06, 77-07 et 77-08 (précisions)

- `rendre(corps, ctx)` et `ouvrir(corps, ctx)` reçoivent le conteneur du bloc SOUS son `h3` (`.vf-sy-corps`), jamais la `section` : la coquille pose le `h3` (`id="vf-sy-t-<id>"`,
  `tabindex="-1"`, titre = `bloc.titre` par `textContent`) ; un bloc qui doit rendre le focus à son titre prend `corps.parentElement.querySelector('h3')`.
- `installer(ctx)` est appelé à chaque arrivée sur l'onglet Projet (avant toute ouverture) ; `rendre` puis `ouvrir` à l'ouverture ; `rendre` seul si le viewer redessine le panneau
  ouvert (le focus et `ouvrir` ne sont donnés qu'à la première ouverture).
- `majResume({ texte, titre })` : `texte` = la ligne-résumé (affichée par `textContent`), `titre` = le résumé du nom accessible (« Synthèse : {titre} depuis votre dernière visite ») ;
  sans `titre`, le nom est « Synthèse : {texte} » ; sans texte, « Synthèse du projet » et pas de ligne. Mise à jour en place : jamais de `showPanel` de rafraîchissement.
- Les suites des plans suivants qui veulent les VRAIS blocs prennent une copie complète du module ; la suite de ce plan retire les frères `74-vf-synthese-*.js` de ses copies
  (« nue » et « témoin ») pour que la coquille se prouve seule, quel que soit l'état des plans suivants.
- Le banc : `node chrome-synthese.mjs lab <dossier>` (lab fixture), `temoin <copie>` (bloc témoin), `scenario <chrome> <port> <nue|temoin> [<export>]` ; les mesures propres à un
  plan s'ajoutent à `chrome-synthese-temoin.mjs` (ou à un fichier voisin importé par les scénarios). `mklab`, `copie_sans_freres` et le lancement par `cockpit_lancer` sont dans la suite.

## Écarts

- Écart : le banc est en trois fichiers (`chrome-synthese.mjs`, `chrome-synthese-scenarios.mjs`, `chrome-synthese-temoin.mjs`), chacun sous 100 lignes, au lieu d'un seul ; `lancer` et
  `copieMutee` sont des fonctions du shell de la suite (elles appellent `cockpit_lancer` et `cockpit_module_muter_page`, du bash) : leurs sondes positives sont B3 et B4.
- Écart : le test `window.FLOORPLAN_SERVER` du plan devient `VF_ETAT.jeton() !== null` et la page se lit sous `window.VibeFlow` (la page servie est renommée ; 70-vf-etat.js fait de même).
- Écart : le traceur (tâche 1) et la coquille complète (tâche 2) sont dans un seul commit de code ; la ligne `AJOUT` de `VENDORED.txt` y entre avec le fichier (un `AJOUT` sans fichier
  rougirait la suite du plafond au commit précédent).
- Écart : à 800 px (taille par défaut de Chrome headless) le bouton vit dans le menu « ⋯ » (`display: none` en en-tête sous 1 000 px) et l'ouverture d'un panneau fermé pousse la carte :
  les scénarios posent d'abord un poste de bureau (1 440 px) ; W16 mesure le bouton en le forçant visible à 800 px.
- Écart : le viewer écrit lui-même la clé `vf-cockpit:panel` (état ouvert du panneau) à l'ouverture de TOUT panneau : W11a l'écarte de la comparaison du stockage ; elle ne vient pas de la Synthèse.
- Écart : la mesure « un seul rappel de `surOnglet` vivant » n'est pas directe (la coquille n'expose pas son compte) ; elle se lit par ses effets (un bouton, une ligne, chaque bloc installé et
  rendu une fois, écouteurs de `document` et de `window` égaux après deux cycles d'onglets, même `performance.timeOrigin`).
- Écart : 77-08 devra tenir compte de W18.2 : la ligne-résumé « sans fournisseur » se prouve sur une copie sans les frères `74-vf-synthese-*.js` ; elle n'a pas de sens sur le module complet
  une fois le bloc « visite » livré.

## Suites jouées (tête commitée)

- `test-cockpit-synthese-page.sh` : 38 PASS / 0 FAIL (27 à 36 s).
- `css-jetons.mjs` sur `74-vf-synthese.js` : 0 ; `test-cockpit-chrome-fr.sh` : 141 PASS / 0 FAIL (76 s).
- `test-cockpit-vendor.sh` : 251 PASS / 1 FAIL — V4 « check-file-size.sh sur tout le code du module » : le fichier fautif est `ui/70-vf-live.js` (exactement 300 lignes, sans marqueur, posé par 79-17),
  hors plan ; aucun fichier de ce plan n'est en cause (le plafond de lignes, le cliquet de 160 colonnes et la ligne `AJOUT` passent).
- `scripts/check-version-sync.sh` : vert (241 suites).
- `test-cockpit-projet-visite.sh` : 114 PASS / 1 FAIL, deux fois (916 s puis rejeu) ; le rouge est R3.18 (presse-papiers de « Copier ») ; le MÊME rouge (114 / 1) sort d'une extraction de la base
  (`git archive` de la tête de départ, sans `74-vf-synthese.js`) : il préexiste, hors plan. L'onglet Projet reste inchangé hors ajouts.
- `test-cockpit-transcript.sh` : 110 PASS / 1 FAIL, deux fois ; T24F4.1 (8,5 Mio de blocs en moins de 2 000 ms : 6 832 ms obtenus sous une charge de 120 sur le poste) ; borne de durée, route de
  transcript du serveur, aucun lien avec `ui/` : hors plan.

rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale) — mutants non joués (M-BADGE, M-POUSSE, M-DOUBLE, M-SHOWPANEL,
M-ECHAP, M-REGISTRE, M-ONGLET, M-SANS-CLE) ; la coquille ne rend aucun texte venu du serveur (`textContent` partout, aucune garde d'échappement à muter).

Correction après CI (EK15.3 de test-cockpit-equipe.sh) : le littéral « panneau.addEventListener('keydown', echap); » figurait deux fois dans la page (73 et 74) et rendait « ancre ambiguë » ; la fonction de la Synthèse est renommée `fermerAuClavier`, sans changement de comportement.

Correction après CI (R21 et R22 de test-cockpit-responsive.sh) : le libellé « Synthèse » (visible dès 1 600 px) rognait le fil d'Ariane de Projet, hors de portée du repli mesuré qui ne réduit que le badge « au travail ». Le bouton est icône seule à toute largeur (règle `#btn-synthese .bl` dans la feuille de la coquille ; nom au title et à l'aria-label) : écart à l'UI-SPEC § 2 (libellé dès 1 600 px). Aucun fichier de l'en-tête hors 77 touché. Local : rouge reproduit (377 PASS / 2 FAIL), puis R21 et R22 verts (378 PASS / 1 FAIL : R19.1, Équipe 390 px, mesure d'aire sous charge 120, onglet où la Synthèse ne rend rien, vert au premier passage).

Correction après CI (O1.1 et O1.2 de test-cockpit-magasin.sh, cliquet des observateurs) : la coquille tenait `aria-expanded` du bouton par un `MutationObserver` (HAUSSE 74-vf-synthese.js réel=1 baseline=0). Retiré, sans hausse de la baseline, comme 79-17 : l'événement `panel` du moteur (`SC.on('panel', …)`, synchrone après chaque dessin, donc ouverture, fermeture par `closePanel` et redessin) plus un écouteur de clic et de clavier sur le document, posé à l'installation et retiré au nettoyage, pour le bouton du panneau qui ferme sans redessiner. Suites : `observateurs-cliquet.mjs juger` conforme ; `test-cockpit-synthese-page.sh` 38 PASS / 0 FAIL.
