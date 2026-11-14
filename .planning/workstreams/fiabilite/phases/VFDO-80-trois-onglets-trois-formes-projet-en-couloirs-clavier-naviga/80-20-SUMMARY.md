# 80-20 — SUMMARY (l'en-tête et le titre de vue lisibles : zone du titre, trois groupes, chevron, icônes, ouvreur Git 36/44)

Régime : exécuté en ligne par vf-coder, nœud p20, tête de départ 64fad93da.
Rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale) : aucun mutant (M-TITRE-RECOUVRE, M-GROUPES, M-ZONE-APPUI, M-POINT-LIBELLE, M-CLE, M-OUVREUR non écrits), pas de preuve générative.

## Livré
- **P80-D-52, zone du titre** (`ui/01-vf-ensemble.js`) : le rectangle de `#context` (hauteur plafonnée à `min(130, hauteur du bloc)`, celle que `freeArea()` déduit) est un trou dans une découpe `clip-path: path(evenodd, …)` de `#svg`, recalculée au `render`, au redimensionnement et à chaque changement de taille du bloc. Aucune carte n'y est dessinée ni atteignable (EN1.1, 4 cas), `freeArea`, `fit`, flou et texte inchangés (EN1.2, EN1.2b), couloirs et liste sans découpe (`#context` masqué, EN1.3), zone basse inchangée (EN1.4). Idiome A51 : écouteur `resize` et `ResizeObserver` dans le rappel de `VF_COQUILLE.surOnglet(…, { cle: '01-vf-ensemble.js' })`, retirés avec la découpe (EN1.5, EN1.6).
- **P80-D-53, en-tête** : dès 1 280 px, trois groupes `role=group` libellés (Lire : Parcours, Écrans, Types de liens, Visite ; Suivre : Travail récent, Santé, au travail ; Affichage : Exporter, Thème, Détail), boutons déplacés jamais clonés, un bouton tardif rejoint son groupe par son id sinon « Affichage », rangement défait sous 1 280 px dans l'ordre d'origine (`ui/01-vf-responsive.js`, clé `01-vf-responsive.js`, écouteur `matchMedia` dans le rappel de `surOnglet`, aucun `MutationObserver` de plus : cliquet des observateurs conforme ; le rangement est rejoué par l'observateur existant de `.hr`). Libellés `Read`, `Follow`, `Display` ajoutés au dictionnaire (`78-vf-fr-dict-a.js`). Chevron `aria-hidden` du fil d'Ariane et nouveau tracé de Parcours (`viewer.html`), horloge pour Travail récent (`ui/25-recent.js`), glyphe de sessions (`clip-path`) pour le point réduit de `#vf-lock` sans toucher `70-vf-live.js`. Badge réduit de 701 à 1 639 px et troncature de la branche à 220 px inchangés (EN2.4b).
- **P80-D-56, ouvreur Git** (`ui/76-vf-git-entete.js`, `ui/03-vf-charte.js`) : dessiné à `--hdr-btn` (36 px au pointeur fin dès 1 000 px, 44 en dessous et au toucher), appui de 44 × 44 par un pseudo-élément posé à la position statique du bouton (ni `overflow`, ni `%` : le bouton n'est pas son bloc conteneur, `scrollWidth` reste la largeur dessinée, EN3.3).
- Suite `test-cockpit-entete.sh` (35 assertions) et pilote `chrome-entete.mjs` (252 lignes) ; `80-20-RED-TRACE.md`.
- **FI2.3** (finitions) et **H4.1** (git-entete, cinq cas) réécrites sur le contrat 36/44, ancien et nouveau libellé cités dans la trace, même nombre d'assertions, mêmes largeurs, mesures exactes.
- Demandes du manager en cours de route : `test-cockpit-finitions.sh` (15 lignes > 160 points repliées, commit `test(80-17)`, 23/0 avant et après) ; FI4.3 accepte `02-vf-ligne-echec.js` (liste toujours exacte) ; `01-vf-ensemble.js` et `01-vf-responsive.js` sans hausse de lignes longues (JT1.4 14/0, V4c.9a vert).

`<script>` nus de `viewer.html` : 6 à la base, 6 après. Aucune ligne `VENDORED.txt`, aucun fichier `ui/` neuf, aucune écriture de `colonnes-baseline.txt`.

## Écarts
- **Flou** : le plan parle d'un `backdrop-filter` sur `#context::before` ; c'est bien le cas (`blur(22px) saturate(1.6)`, `00-vibeflow.js`), EN1.2 le lit.
- **Icône `recent`** : elle est posée par `25-recent.js` (pas par la table du moteur de `viewer.html`) et seulement quand le lab a un travail récent : le fichier est donc touché, hors `files_modified`, et le lab de la suite porte un plan à `files_modified`.
- **`VF_ONGLETS.aller`** existe (80-10) : les allers-retours l'appellent.
- **Pas de vrai « glisser vers le bas »** : la suite glisse une carte au centre de la zone du titre (pointeur réel), puis « + ».
- **EN1.4** : `--vf-bas` n'est comparé en pixels qu'à 800 px ; à 390 px il suit la hauteur de la feuille (police), seule sa forme est comparée. Rectangles arrondis à l'entier, largeur de la pastille exclue (police).
- **Appui de l'ouvreur et R1** : deux tentatives rouges (pseudo-élément relatif : `scrollWidth 40 > 36`, 15 cas de test-cockpit-responsive à 1 024 px ; `overflow: clip` ne retire pas le débordement) avant la forme finale (position statique, 44 px fixes). Navigateurs : testé sous Chrome seul.
- **Sous charge** : `test-cockpit-finitions` FI3.1 (`#vf-lock` absent à la mesure) rouge une fois, 23/0 au rejeu seul.
- Commits : le trailer porte le nom demandé par le mandat (« Opus 5.5 »), le modèle réel est Sonnet 5.5.

## Rouges connus de test-cockpit-git-entete.sh (relevés AVANT le premier commit, sur la tête de départ)
119 / 17 : H2.3a, H2.3b, M-COUPURE, H9.2, M-TABINDEX-DEFINITION, M-ARRIVER, M-TEXTE, M-ABSENT, M-MEMOIRE, M-MASQUE, M-REPOS, M-CHARGEMENT, M-DOUBLE-LECTURE, M-BLOC-VUE (×3), M-ECART. Sur ma tête : les mêmes 17 (`comm` sur les libellés : aucun en plus, aucun en moins). Aucun des cas réécrits (H4.1) ne fait partie des 17.

## Suites (chacune sur un export de la tête commitée, ou sur l'arbre pour celles qui lisent l'historique git)
- test-cockpit-entete : 35 / 0 (65 s) · test-cockpit-finitions : 23 / 0 (rejeu seul au jeton ; 1re passe sous charge 22 / 1, FI3.1) · test-cockpit-jetons : 14 / 0
- test-cockpit-git-entete : 119 / 17 = les 17 hérités (383 s) · test-cockpit-vendor : 252 / 0 (V4c verts) · test-cockpit-surcouches : 48 / 0 · test-cockpit-equipe : rc 0 (271 s, sur l'arbre : ses témoins lisent `git show`) · test-cockpit-accessibilite : rc 0 · test-cockpit-sante-fr : rc 0 · test-cockpit-chrome-fr : rc 0
- test-cockpit-projet-visite : 114 / 1 (R3.18, presse-papiers), **rouge aussi sur la base** (copie du module de 64fad93da), hors de mes fichiers
- test-cockpit-responsive : base 379 / 0 ; ma tête, 1re passe sous charge 366 / 13 (D39.7b, D39m3, R15c.1 à R15c.9c) ; rejeu seul au jeton (1 843 s sur la 1re passe) : **379 / 0**, les 13 rouges de la 1re passe étaient des cas de charge (poste partagé)

## Ligne de CHANGELOG demandée par 80-18
- cockpit : en-tête et titre de vue lisibles (Phase 80, plan 20) : le bloc de titre a sa zone (aucune carte dessinée ni cliquable dessous), l'en-tête se range en trois groupes libellés dès 1 280 px, le fil d'Ariane a un chevron, Parcours, Travail récent et « au travail » ont des icônes justes, l'ouvreur Git est dessiné comme ses voisins avec une zone d'appui de 44 px

## À ajouter plus tard
- Rien : aucun cas ne dépendait d'un livrable absent.
