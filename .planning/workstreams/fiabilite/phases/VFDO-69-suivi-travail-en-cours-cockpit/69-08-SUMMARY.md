---
phase: 69-suivi-travail-en-cours-cockpit
plan: 08
requirements: [CKPT-19, CKPT-20, CKPT-21, CKPT-22, CKPT-23, CKPT-26]
commits: [9061cde2, cdef292c]
---

# 69-08 — rendu de l'équipe dans l'interface

## Livré
- `71-vf-equipe-rendu.js` (neuf, ligne `AJOUT` de `VENDORED.txt`) : `window.__vfEquipeRendu = { arbre, agentsDuNoeud, transcript, pied, duree }`. Arbre session -> manager -> workers, terminés repliés dans `details.vf-termines` fermé, liens agent -> nœud et « non rattaché (raison) », pied d'action en texte brut, transcript par `createElement` + `textContent`.
- `70-vf-live.js` : le tiroir « Au travail » rend l'arbre à la place de la liste plate (retrait de `age`, remplacé par `duree`) ; lignes verrou, nœud de DAG et registre sous « Verrous et nœuds » ; N et badge = agents `actif` non périmés ; section « Agents sur ce nœud » dans l'onglet Projet ; classes `vf-arbre-enfants`, `vf-termines`, `vf-pied`, `vf-transcript`.
- `72-vf-equipe.js` : pied sur les cartes, panneau d'agent (état, durée, dernière action, nœud, « Voir la dernière commande », « Lire le transcript »), requête `/api/vf/transcript` avec `x-floorplan-token`, réponse jamais conservée (le DOM du transcript lu passe d'un panneau à l'autre au redessin), `hashchange` pour les liens internes à la page.

## Témoins
EUI.1 à 7, E23.7, T26.1 à 4 verts ; T26.7 jouée dans Chrome et verte (la route de 69-07 était présente). W16 jouée dans Chrome (non sautée), verte.

## Écarts au plan
- Le conteneur `.vf-transcript` n'est pas posé caché dans le panneau : T26.7 l'attend absent avant le clic (`if (!document.querySelector('.vf-transcript'))` clique alors le bouton). Il est créé au clic, après son bouton.
- Libellés : la sonde E23.7 juge anglais « Session », « Mandat », « en attente », « {} min » dans un fichier neuf (liste `CONNU` du test limitée à 70 et 00). Les mots sont écrits en minuscules et mis en capitale à l'affichage (`cap`), l'unité de durée assemblée sans gabarit. Plus propre : déclarer ces littéraux dans `CONNU` pour 71 (suite hors périmètre).
- En-tête du jeton : `x-floorplan-token` (celui que le serveur lit), pas `x-vf-cockpit-token`.

estimate: tokens 90000 / actuals non mesuré.

## Correction de revue

Mandat de correction ciblée (revue de l'onglet Équipe sur 945613b6, F1 à F6 ; F7 renvoyé par P69-D-28).

- **F1** (`72-vf-equipe.js`) : `dansCarte()` exclut les cartes-blocs `<carte>~termines`, qui ne sont pas des agents. Rouge avant : un agent actif et un terminé donnaient 1 rechargement au premier `vf-who` (attendu 0). Témoins : EUI2.10 (0 rechargement, 1 rendu), EUI2.12 (borne : 1, 1, 2 rechargements autour de l'échéance de 15 s). Mutants : EUI2.11 (bloc compté) et EUI2.13 (`PAUSE_MS = 0`).
- **F2** (`72-vf-equipe.js`, pas de patch du viewer vendu) : l'arrivée sur `#r=n:<carte>` est traitée après le premier rendu qui aboutit (`arrivee()`, une fois par page), ce qui couvre le cas où `ready` n'est jamais émis ; si `ready` a eu lieu, `00-vibeflow.js` l'a traitée et 72 ne la rejoue pas. Témoins : EUI2.14, EUI2.15 (vm, ordre forcé), T26.8 (Chrome, `state.selected`). Mutant : EUI2.16. Mesuré : sans l'appel `arrivee();`, T26.7 et T26.8 rougissent en Chrome et EUI2.14 rougit en vm (EUI2.16 le prouve par mutant). L'ordre de livraison du flux n'est pas pilotable en Chrome, mais depuis F1 il est défavorable de façon reproductible (le premier `vf-who` lance un `rerender()` pendant le premier rendu).
- **F3** (`test-cockpit-transcript.sh`) : T24F1.* ne couvrait que le message coupé et le mandat. Ajouts : T24F3.0 à T24F3.4 (message, cible d'outil, nom d'outil ; trois mutants) et T25.9b (la route, agent `xsec`, 3 masques).
- **F4, F5b** (`71-vf-equipe-rendu.js`) : témoins EUI2.1 à EUI2.9 (id, rôle, branche, cible, raison, tâche piégés dans l'arbre, le pied, la liste d'un nœud et le panneau de 72 ; un agent non rattaché n'a jamais de lien). `versNoeud()` est désormais unique (arbre et panneau). Mutants : EUI2.2 à EUI2.7, EUI2.9.
- **F5a** (`70-vf-live.js`) : EUI2.17 (un actif, un terminé, un en attente : « 1 au travail », « Au travail (1) »), mutant EUI2.18.
- **F6** : les libellés sont écrits tels qu'affichés ; les huit littéraux français de 71 que la sonde prend pour de l'anglais sont déclarés dans `CONNU` (rien d'autre) ; EUI2.19 prouve que la sonde voit encore un libellé anglais ajouté à 71.
- Note de harnais : sous Chrome le viewer est exposé en `window.VibeFlow` (le `Floorplan` des sources est renommé à l'assemblage).

### Dernière passe (6 mineurs)
- Point 1 : EUI2.25 (un agent passe d'actif à terminé : 1 rechargement, puis aucun avant 15 s) ; mutant EUI2.26 (`fini ? '~' : ''` retiré de `signature()` : 0|0).
- Point 2 : le piège de EUI2.1 porte `noeud` et `dag` piégés ; EUI2.22 (mutant `h()` retiré sur le nœud, arbre), EUI2.23 et EUI2.24 (panneau).
- Point 3 : EUI2.20 (libellés exacts : Session, Sous-agent, en attente, terminé, bloc « Terminés depuis moins de 24 h (1) ») ; mutant EUI2.21 (`'en-attente'`).
- Point 4 : la phrase de F2 ci-dessus est corrigée.

## Correction de recette

Recette 69 déroulée dans un vrai navigateur (tête 410e73a9). Témoins `T27.*` de `test-cockpit-transcript.sh` : vrai Chrome, vrais scripts de la page, flux `who` livré à la main par un `EventSource` enveloppé (script injecté avant ceux de la page). Chacun a été rouge sur HEAD, puis vert, puis rougi par un mutant rejoué sur le serveur réel.

- **A (tiroir figé)** — cause : `whoPanel` ne dessinait le tiroir qu'au clic ; aucun `who` ne le redessinait. Fix : `redessiner()` à chaque `showLock`, sans image identique, défilement et blocs « Terminés » conservés (le bloc est repéré par l'agent qui le porte). Rouge : `Au travail (3)` ne bouge pas. Mutants : plus de redessin, état replié perdu. Invisible : aucune suite ne livrait un second `who` à un tiroir ouvert (EUI2.17 appelait `whoPanel` une fois). Note : la visite guidée du premier passage remplace le panneau par la vue d'ensemble ; les témoins ouvrent la page avec un fragment pour l'éviter.
- **B (lien de la même page)** — cause : un changement de fragment ne rejoue pas `ready` et le viewer, à `popstate`, revient à la vue d'ensemble ; seule l'arrivée à froid révélait la cible. Fix : `00-vibeflow.js` traite `#r=` aussi à `hashchange` (le gestionnaire propre à 72 disparaît). Mutant : écouteur retiré (B1 et B2 rouges). Invisible : EUI.4 et EUI.5 ne lisent que le `href`, T26.8 charge la page à froid.
- **C (contenu demandé effacé)** — causes : (1) le panneau d'un agent est redessiné à chaque `who` et la réponse arrivée pendant le redessin tombait dans une ligne détachée (la restauration de 72 copiait le contenu au début du redessin, trop tôt) ; (2) un rechargement de la page (structure de l'équipe changée, « Map updated ») efface tout. Je n'ai pas pu observer le rechargement du réel ; il est établi par le code (`recharger()`, borné à 1 par 15 s) et couvert par un témoin. Fix : transcript et commande gardés en mémoire de la page (jamais dans le graphe, le stockage ni l'export), reposés par un `MutationObserver` quand le bouton réapparaît ; ils disparaissent quand le panneau montre un autre agent ; l'identifiant (jamais le contenu) du transcript ouvert est gardé dans `sessionStorage` pour le redemander après un rechargement. Rouge : `transcript lu=false`. Mutants : observateur du transcript, observateur de la commande, marque de rechargement. Limite : une commande demandée n'est pas redemandée après un rechargement. Invisible : T26.7 ne livrait aucun `who` après la lecture et la fixture n'en émettait pas pendant la requête.

### Décisions F (P69-D-33)
- **F1** badge = agents actifs (`R.actif`, même prédicat que les effectifs de l'onglet Équipe) ; plus de verrou, de nœud de DAG, d'enregistrement ni de test de péremption. Rouge : badge 9, actifs 6. Mutants EUI2.18, 2.18b (verrous et nœuds comptés : 6). Invisible : la fixture de EUI2.17 ne contenait que des agents. `vf-cockpit-who.mjs` non touché.
- **F2** titre « Équipe · <nom> », `<nom>` = nom du projet affiché par la page Projet (`project.name` sans « — Projet »), plus le nom du dossier. Le `<title>` statique du serveur reste le repli d'avant script. Rouge : « labsrv — Équipe ». Mutant : nom du dossier rétabli. Invisible : E23.2 lisait le titre statique, et la fixture avait le même nom que le dossier.
- **F3** retenu : libellé adapté, champ conservé. Mesuré : une saisie de rôle (`vf-dev-manager`) rend des résultats, la recherche trouve donc des agents et des sessions ; « Chercher un agent ou une session » (bouton et infobulle), champ « Chercher par nom, rôle ou description ». Mutant : libellé non posé.
- **F4** un message ou un mandat coupé se termine par « … (tronqué, N caractères) », N lu dans la constante (`BORNE_MESSAGE`, `BORNE_MANDAT`), mention après `masqueCoupe` (seule voie de coupe). T24.16 retire la mention avant de mesurer la borne. Mutants : borne des messages à 1 500, borne du mandat à 5 000, mention absente. Témoins F1 de la lecture (secret à la borne) verts. Rouge sur HEAD : `false|true|true|false`.

### Reste ouvert après la recette (hors périmètre de ce mandat)
- `test-cockpit-responsive.sh` : 176 PASS / 10 FAIL depuis F1 (R4.2, R7.0 à R7.4 Code et Projet). Cause établie : le lab de ces mesures n'a qu'un verrou ou un nœud de DAG, que le badge comptait (« N au travail ») ; il dit désormais « Personne », et la suite attend `/travail/` (ligne 137 et ligne 294) et mesure R4.2 avec un badge large. Preuve : la même suite, `/travail/` remplacé par `/travail|Personne/` dans une copie, rend 185/1 (R4.2 reste rouge : sa mesure suppose un badge large). Réparation : un agent actif dans la fixture de ce lab ; la suite n'est pas dans le périmètre, remontée au manager.
- Les observateurs de 70 et 72 regardaient d'abord tout le document ; sur la carte du code du dépôt (milliers d'éléments redessinés en rafale) ils ralentissaient la page. Ils ne regardent plus que `#panel` (commit séparé).
