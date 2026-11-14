# 77-06 — Blocs « Burn-up du jalon » et « Santé de la méthode » : SUMMARY

## Livré

- `ui/74-vf-synthese-burnup.js` (141 lignes, aucune ligne au-delà de 160 points de code) : bloc `burnup` inscrit au registre de la coquille ; tête « N sur M · P % » recopiée de
  `meta.vf.burnup` ; courbe SVG en escalier à deux séries neutres (clôtures en trait plein `--text-3`, périmètre en tirets `--text-4`), étiquettes directes, sans légende ni dégradé ;
  `aria-label` complet ; liste datée en repli fermé (au téléphone, ≤ 700 px, la liste seule, par `matchMedia` dont l'écouteur est retiré au nettoyage) ; notes des phases closes ou
  inscrites sans date, jamais estimées ; états « Aucun jalon en cours » et « Burn-up indisponible ». `window.__vfSyntheseBurnup` gelé : `tete`, `courbe`, `liste`, `notes`, `ariaLabel`.
  `meta.vf` relu à chaque rendu ; abonnement à `VF_ETAT` (`graphe`) posé par `installer`, rendu par son nettoyage, qui redessine en place seulement si ce que le bloc montre a changé.
- `ui/74-vf-synthese-jauges.js` (185 lignes) : bloc `methode` ; une seule lecture de `GET /api/vf/methode` par ouverture (`ctx.lireJson`, jamais à `installer`) ; onze jauges en trois
  groupes à l'ordre fixe, nom, « valeur sur budget », barre neutre (hachurée et pleine au dépassement, par masque `data:`), verdict par glyphe et mot, raisons de la liste fermée, sous-liste
  de cinq mesures puis « et N autres », bilan, pied « Mesuré à … », annonce unique ; erreur de route et « Relire les jauges » (`aria-disabled`, focus gardé) ; une seule phrase quand
  tout est indisponible. `window.__vfSyntheseJauges` gelé : `NOMS`, `GROUPES`, `MOTS`, `RAISONS`, `valeurTexte`, `bilan`. Le chemin, texte libre venu du lab, est posé par `poserTexte`
  (`textContent`), jamais en balisage, et un chemin commençant par `/` ou `~` n'est jamais affiché (la ligne dit « Format non reconnu »).
- Suite `test-cockpit-synthese-blocs.sh` (59 assertions : CS1, BG1 à BG8 sous `vm`, W8.1 à W8.10, W9.1 à W9.5, JA1 à JA8, W4b à W7b, W14b, W16b, OB, BO1, E0, M-INNERHTML) et son banc propre
  `chrome-synthese-blocs.mjs` + `chrome-synthese-blocs-scen.mjs` (le banc de 77-05 est importé tel quel, jamais modifié). Lignes `AJOUT` de `VENDORED.txt`, durée de CI, entrée de CHANGELOG
  du cockpit, compteur « 245 suites » des deux README (remesuré sous verrou), `77-06-RED-TRACE.md`. Aucune `VERSION` bumpée ; coquille de 77-05 inchangée.

## Écarts

- Écart : le socle est en DEPASSE en permanence sur le dépôt source (2610 pour 2000) alors que la baseline le tient pour égal : arbitrage délégué, option recommandée du manager. La jauge dit « Dépassé »
  (verdict de la route, jamais recalculé) et sa ligne 3 ajoute « Ligne de baseline : 2 610 jetons, mesure égale. » depuis `baseline.relation` (`egale`, `au-dessus`, `en-dessous`).
- Écart : les vrais gates ne sont pas joués dans le navigateur : la copie du module (`cockpit_module_copie`) ne porte pas le conductor voisin, donc deux faux gates sont posés DANS la copie
  (modes par variables d'environnement : mixte, tout dans le budget, ancien code 64, hors dépôt de distribution). W9 « lab sans corpus de densité » se prouve par le faux gate qui rend le code 2 et
  `NON-APPLICABLE`, comme `test-cockpit-jauges.sh` ; la traduction du vrai TSV reste prouvée par 77-03.
- Écart : tâches 1 et 2 du plan (tracer puis courbe) livrées dans un seul commit de code avec la tâche 3 : le burn-up est écrit en une fois, les jauges de même ; commits : test (rouge), feat
  (deux fichiers, `VENDORED.txt`, ajustements de la suite), docs (CHANGELOG, durée de CI). La ligne `AJOUT` entre avec son fichier (un `AJOUT` sans fichier rougit la suite du plafond).
- Écart : la liste datée rend des objets `{ d, date, texte }` (et non des chaînes) pour poser un `<time datetime>` ; `MOTS[verdict]` = `[mot, classe de glyphe]` ; `RAISONS` = `{ na, indispo: { absent, ancien,
  delai, format, defaut }, format }`.
- Écart : « Aucun jalon en cours » s'affiche aussi quand tous les jalons sont clos et que le champ `burnup` est absent (le burn-up n'est servi que pour le jalon mis en avant) ; « Burn-up indisponible » sinon.
- Écart : le bilan et l'annonce comptent le verdict AFFICHÉ (une ligne dont le chemin est refusé compte en « format non reconnu »), non le jeton brut ; le chemin « . » du contrôle des worktrees n'est pas affiché.
- Écart : après une relecture réussie le bouton « Relire les jauges » disparaît ; si le focus y était, il passe au `h3` du bloc (jamais sur le corps de la page).
- Écart : `.vf-sy details.vf-tech > summary { font-size: 12.5px !important }` : la règle du viewer `#panel details.vf-tech > summary` (12 px, spécificité d'identifiant) sort de la grille des tailles ; aucune règle n'est écrite
  sur `#panel`.
- Écart : la sonde d'écouteurs de média (BO1) ne compte que les écouteurs dont le rappel nomme `corpsCourant` (ceux du bloc burn-up) : d'autres scripts de page laissent leurs écouteurs de média après un
  changement d'onglet (+16 par cycle, avant ce plan : limite écrite de `vf-coquille-portee.js`), hors périmètre. Les mesures de style se font dans le thème par défaut du poste.
- Écart : correction ciblée du juge de design (2026-11-14). Décompte sans aucune date au ROADMAP : le contrat ne traitait pas ce cas ; la tête reste et le bloc dit « Courbe indisponible : aucune date écrite au ROADMAP. » (plus « Burn-up indisponible », réservé à l'absence du champ) ; « Inscrites sans date » ne liste plus les phases closes. Témoin W8.11, rouge vu sur la tête précédente (obtenu : « Burn-up indisponible » et « Phases 1, 2 et 3 »), vert ensuite (60 PASS / 0 FAIL, 22 s). Mineurs sans témoin : espace insécable entre nombre et nom dans le bilan, marge de 8 px au-dessus de « Relire les jauges ».
- Contrat consommé par une autre phase : aucun changé. `window.__vfSyntheseBlocs` et `ctx` utilisés tels que 77-05 les a précisés.

rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale) : mutants M-COULEUR, M-LEGENDE, M-ESTIME, M-RECALCUL, M-ZERO, M-TRI, M-CHARGE,
M-FOCUS et M-NETTOIE-MQ non joués ; seule la garde du chemin (M-INNERHTML) garde son témoin rouge ET son mutant ; revue et audit non lancés.

## Suites jouées (tête commitée)

- `test-cockpit-synthese-blocs.sh` : 59 PASS / 0 FAIL (26 s). Rouge d'abord : 2 PASS / 57 FAIL (52 s).
- `test-cockpit-synthese-page.sh` : 38 PASS / 0 FAIL (26 s), sans modification. `test-cockpit-chrome-fr.sh` : 141 PASS / 0 FAIL (40 s). `test-cockpit-vendor.sh` : 252 PASS / 0 FAIL (110 s).
- `css-jetons.mjs` sur les deux fichiers : 0 (CS1.3). `scripts/tests/test-ci-shard-suites.sh` : 22 PASS / 0 FAIL. `scripts/check-version-sync.sh` : vert (245 suites).
- Rouges connus non rencontrés (F.1 de routes, inventaires de la 74, `robustesse`, `git-entete`, R3.18, T24F4.1) : aucune de ces suites n'a été jouée.

Correction après CI (C2 de test-cockpit-magasin.sh) : mesuré, la cause n'était pas une fuite d'abonnés. Sur Projet, le compte est constant à chaque visite (etat, frise, git, graphe à 1, who à 2) et diffère de celui de Code (n0) parce que la Synthèse s'y abonne, par construction ; la sonde comparait Projet au compte de Code. Elle compare désormais chaque onglet à son chargement à froid (Code et Équipe à n0, Projet à sa première visite) : magasin-chrome.mjs. Burn-up et jauges retirent en plus l'entrée précédente du registre avant `R.push`, comme visite et coût (hygiène : le registre est neuf à chaque onglet, un mutant sans ce retrait reste vert, donc aucun cas n'est ajouté).
