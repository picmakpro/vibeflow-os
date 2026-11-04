# 70-CAPTURES — captures avant / après de la Phase 70 (UIFN-10)

Aucun PNG n'est versionné et aucun chemin absolu n'est écrit ici (P70-D-17 : « Non, hors dépôt (Recommandé) », arbitrage Samuel,
AskUserQuestion session principale Claude Code, 2026-11-03). Les captures vivent dans le scratchpad de la session d'exécution ;
chaque dossier est cité par son nom, chaque capture par son nom de fichier et ce qu'elle montre.

## Méthode

- Outil : la bibliothèque `playwright` de node, dans un Chromium headless propre à chaque juge (jamais le MCP Playwright partagé, P70-D-19).
- Thèmes : sombre et clair (posés dans le stockage local avant le chargement). Largeurs : 390, 768, 1 024, 1 440 px.
- Prises par le manager et ses juges, pas par l'exécuteur de ce plan : l'exécuteur n'a relancé ni capture ni juge et n'a pas rejoué
  les « après » (consigne du mandat). Les empreintes SHA-256 prévues par le plan ne sont donc pas consignées : le plan les croisait
  avec une prise par l'exécuteur ; les noms de fichiers et les mesures JSON font ici foi. Écart assumé.
- Base de l'« avant » : `794c6dba` (Phase 69 mergée, module `v1.1.1`), lab jetable d'un projet nommé `wt-avant` (ou `wt`).
- Têtes de l'« après » : `779bee45` pour Code et Projet (juge A), `cf6983ac` pour Équipe (juge Équipe). Des corrections ont suivi
  ces têtes (voir `70-RECETTE-JUGES.md`) ; leurs preuves sont les témoins rouge puis vert des SUMMARY, pas une nouvelle capture.

## Dossiers (scratchpad de la session d'exécution)

| Dossier | Contenu |
|---|---|
| `captures-70-avant/` | AVANT sur 794c6dba : 40 PNG + `mesures.json` (en-tête, zoom, onglets, recouvrements, par onglet, thème et largeur) |
| `juge-A/p70/captures/` | APRÈS Code et Projet (tête 779bee45) : 107 PNG + 5 JSON (`mesures-base`, `-francais`, `-interactions`, `-sondes`, `-visite`) |
| `juge-equipe2/captures/` | APRÈS Équipe (tête cf6983ac) : 79 PNG + 8 JSON `mesures-<thème>-<largeur>` + 4 `clavier-*` |

Un premier juge Équipe s'est figé (script interrompu sur une couleur nulle) : il n'a rendu aucune mesure exploitable et a été
remplacé par le juge `juge-equipe2` ; seul ce dernier est cité.

## Captures « avant » (`captures-70-avant/`)

| Onglet | Fichiers (thème sombre `-sombre-`, clair `-clair-`) | Ce qu'ils montrent |
|---|---|---|
| Code | `code-{sombre,clair}-{390,768,1024,1440}.png` | en-tête à 390 px sur 3 rangées ; zoom en colonne au milieu du canevas à 768 et 1 024 px |
| Code, visite | `code-sombre-390-visite1/2.png`, `code-sombre-1440-visite1/2.png` | textes de visite tronqués (cause relevée en 70-03 : coupure à 170 caractères) |
| Projet | `projet-{sombre,clair}-{390,768,1024,1440}.png` | en-tête sur 2 rangées à 390 px, statuts en couleurs fixes |
| Équipe | `equipe-{sombre,clair}-{390,768,1024,1440}.png` | titre et première carte superposés ; zoom sur une carte à 768 px |
| Équipe, interactions | `equipe-*-{390,1024}-agent.png`, `-tiroir.png`, `-tiroir-qui.png` | tiroir d'un agent et tiroir « qui est au travail » |

## Captures « après »

| Onglet | Fichiers | Ce qu'ils montrent |
|---|---|---|
| Code | `code-{sombre,clair}-{390,768,1024,1440}.png` (juge A) | en-tête d'une rangée à 390 px, onglets à 13 px / 3 px ; 768 à 1 440 px inchangés |
| Code, menu et tiroir (390 px) | `code-{sombre,clair}-390-menu.png`, `-tiroir-carte.png`, `-tiroir-titre.png`, `-tiroir-vide.png` | menu « ⋯ », tiroir ouvert par une carte et par le titre, tiroir fermé |
| Code, visite | `code-{sombre,clair}-{390,1440}-visite1..4.png`, `-recharge1-visite1.png`, `-recharge2-visite1.png`, `-apres-visite.png` | quatre étapes, texte entier, rechargement sans dérive, retour à la vue d'avant |
| Code, français | `code-sombre-1440-fr-*.png` (santé, récent, écrans, exporter, recherche, survol, clic droit, types de liens…) | chrome sans anglais résiduel, « clic droit » |
| Projet | `projet-{sombre,clair}-{390,768,1024,1440}.png` | une rangée à 390 px ; statuts lisibles dans le thème clair |
| Projet, menu et tiroir (390 px) | `projet-{sombre,clair}-390-menu.png`, `-tiroir-*.png` | idem Code |
| Projet, visite | `projet-{sombre,clair}-{390,1440}-visite1..4.png`, `-recharge*`, `-apres-visite.png` | visite propre à Projet : jalon, phase, mission, « au travail » |
| Projet, français | `projet-sombre-1440-fr-*.png`, `projet-clair-1440-ajuste.png`, `-sombre-1440-ajuste.png` | « Où en est-on ? » sans STATE, vue ajustée |
| Équipe | `equipe-{sombre,clair}-{390,768,1024,1440}.png` | zoom en bas à gauche dès 701 px, titre sans recouvrement |
| Équipe, interactions | `equipe-*-agent.png`, `-agent-montrer.png`, `-session.png`, `-tiroir*.png`, `-lien-{survol,focus,clic}.png`, `-transcript-clavier.png`, `-tiroir-commande-clavier.png`, `-termines-ajuste.png`, `-badge-sonde.png` | boutons stylés, lien « Nœud » distinct, focus gardé après redessin, badge dans la carte |

## Mesures avant → après

Sources : `mesures.json` (avant), `mesures-base.json` (juge A) et `mesures-<thème>-<largeur>.json` (juge Équipe). Identiques en sombre et en clair.

| Mesure | Avant (794c6dba) | Après |
|---|---|---|
| En-tête de Code à 390 px | 3 rangées, 148 px | 1 rangée, 56 px |
| En-tête de Projet et Équipe à 390 px | 2 rangées, 100 px | 1 rangée, 56 px |
| Zoom à 390 px | dans l'en-tête, rangée de 132 x 44 px à x 202 | pile verticale 52 x 144 px à x 16, y 582 (Code, Projet) ou y 684 (Équipe) |
| Zoom à 768 px (Code, Projet) | colonne 52 x 144 px à x 308, y 108 | inchangé (tablette) |
| Zoom à 768 px (Équipe) | colonne x 308, y 108 : une carte recouverte | rangée 144 x 52 px à x 16, y 956 ; 0 carte recouverte |
| Zoom à 1 024 px (Équipe) | colonne 42 x 114 px à x 574, y 72 | rangée 114 x 42 px à x 16, y 710 ; 0 carte recouverte |
| Titre / 1re carte d'Équipe | 22 752 px² (390), 17 408 (768), 17 400 (1 024 et 1 440) ; 70-12 a relevé 26 100 à 1 024 et 1 440 px sur son propre lab | 0 partout (`titreCarte1` à 0 aux 4 largeurs, deux thèmes) |
| Onglets à 390 px | 12 px, piste 2 px | 13 px, piste 3 px, padding 5 x 8 px, aucun rogné |
| Onglets à 768, 1 024, 1 440 px | 12 px, piste 2 px | 12 px, piste 2 px : NON résolu (écart connu, R13.4) |
| Débordement horizontal | aucun | aucun, aux 4 largeurs |
| Erreurs JS | aucune | aucune |

Contrastes du thème clair (`mesures-sondes.json`, juge A, 1 440 px) : pastilles « Fait » 6,81:1, « En cours » 6,70:1, « À faire » 7,01:1,
« prêt à planifier » 6,07:1 ; thème sombre : 8,38 / 8,69 / 4,59 / 7,29 (le minimum, « À faire » sombre, tient 4,5:1).

## Observation par exigence

- **UIFN-01 (en-tête)** : voir les mesures ; trois onglets lisibles à 13 px à 390 px, menu « ⋯ » (`*-390-menu.png`). Aux autres largeurs l'en-tête n'a pas changé.
- **UIFN-02 (zoom)** : pile à gauche au-dessus de la barre de question à 390 px ; tablette inchangée sur Code et Projet ; Équipe en bas à gauche dès 701 px (P70-D-20).
- **UIFN-03 (tiroir)** : poignée, croix, titre cliquable, Échap et tap dans le vide (`*-390-tiroir-*.png`).
- **UIFN-04 (visite, Code)** : cible, texte entier, « Passer », « n sur N », aucun anglais (`code-*-visite1..4.png`).
- **UIFN-05 (visite, Projet)** : étapes propres au projet, la dernière nomme l'onglet Équipe (`projet-*-visite1..4.png`).
- **UIFN-09 (couleurs de statut, thème clair)** : `--st-active`, `--st-blocked` suivent le thème ; contrastes ci-dessus.
- **UIFN-11 (finitions d'Équipe)** : badge dans la carte, « non rattaché » sur une ligne, boutons stylés, champs en paragraphes, lien « Nœud » distinct.
- **UIFN-14 (zoom et titre d'Équipe)** : voir les mesures.
