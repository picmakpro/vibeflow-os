# Recette du panel d'utilisateurs sur la version jointe du cockpit (PR #218) — synthèse (2026-11-08)

Version recettée : branche `feat/cockpit-retours-utilisateurs`, commit `a286f0fa`. Référence avant/après : v2.76.0 (`main`, `de19669b`). Registre : `2026-11-06-panel-utilisateurs-GLOBAL.md` (PU-G-001 à PU-G-204, DG-01 à DG-15). Mission : vf-design-manager, dispatch de la session principale, 2026-11-08. Aucune correction faite : le produit n'a pas été modifié.

## Banc

- Huit cockpits assemblés depuis `git archive` des deux commits (version jointe : ports 4461 à 4464 ; v2.76.0 : ports 4481 à 4484). Chacun lit sa copie de lab : un clone du dépôt nommé `vibeflow-os`, avec un état Git sale, cinq worktrees, des sessions et agents d'équipe fabriqués (dont deux titres /rename), deux verrous (un tenu, un périmé avec orphelins), des secrets factices dans des commandes d'agents actifs, et une dérive de format injectée.
- `HOME` isolé, terminal `--terminal`, **faux `claude`** en tête du PATH (le `.zshrc`, le `.zlogin` et le `.zprofile` du HOME isolé le remettent devant `/usr/local/bin`). Contrôle fait dans le terminal de la page : `command -v claude` → `…/recette/bin/claude`. Aucune vraie session et aucun modèle appelés.
- Les cockpits de Samuel (4456, 4457) n'ont été ni sondés ni touchés.
- Quatre juges general-purpose outillés en Playwright 1.60.0. Ils ne connaissaient ni le processus ni les rapports des groupes : seulement le registre, l'état attendu de chaque proposition (dérivé des commits, du CHANGELOG § Non publié, du BACKLOG et de la PR #218) et le produit.
- Charge machine : un autre manager faisait tourner ses suites et la charge est montée entre 12 et 44. Les juges ont attendu avant leurs séries lourdes, puis enchaîné des scripts courts, l'un après l'autre. Les mesures de durée (PU-G-047, 127) en sont faussées.

## Rapports des juges

| Profil | Rapport | Périmètre | Note /100 |
|---|---|---|---|
| Utilisateur non technique | `2026-11-08-recette-panel-nontech.md` | 001-019, 085-092, 111-142, DG-05, 07, 08, 11 (59 + 4) | **75** (Utilité 24, Lisibilité 17, Confiance 21, Finition 13) |
| Développeur solo | `2026-11-08-recette-panel-dev.md` | 026-084, DG-02, 03, 04, 09, 12 (59 + 5) | **74** |
| Accessibilité et clavier | `2026-11-08-recette-panel-a11y.md` | 020-025, 177-204, DG-01, 06, plus une contre-vérification clavier transverse (34 + 2) | **64** (21, 17, 15, 11) |
| Responsable de lab | **non rendu** | 093-110, 143-176, DG-10, 13, 14, 15 (52 + 4) | — |

**Le juge « responsable de lab » n'a pas rendu.** Il a produit 50 captures (sous `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/lab/`, surtout le panneau Format, PU-G-151 à 155), puis il est resté bloqué sur une attente en arrière-plan à partir de 01:56. Il a été arrêté. Son périmètre n'est **pas jugé** : onglet Projet (vérité des états, panneau de droite, barre de question), panneau « Format de la planification », onglet Équipe et « Qui a la main », masque des secrets. Constat du manager, sans valeur de verdict : la capture de fumée `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/manager/projet-etats-et-terminal-faux-claude-1440.png` montre « STATE.md semble périmé : il dit « prête à planifier ». », la carte « Hors jalon », « 4 lignes du planning non lues — chiffres peut-être incomplets · Voir » et les compteurs 444/476. Il faut un nouveau passage de juge sur ce périmètre (voir la fin du document).

## Comptes (152 propositions jugées sur 204, 11 diagnostics sur 15)

| Verdict | Non technique | Développeur | Accessibilité | **Total** |
|---|---|---|---|---|
| livré | 31 | 39 | 19 | **89** |
| partiel | 10 | 5 | 9 | **24** |
| non livré | 6 | 11 | 1 | **18** |
| régression | 1 | 1 | 0 | **2** (+ 1 hors registre) |
| clos par arbitrage, vérifié | 2 | 2 | 1 | **5** |
| mis de côté, constaté | 2 | 0 | 1 | **3** |
| non reproduit | 7 | 1 | 2 | **10** |
| constat de classe C | — | — | 1 | **1** |
| non jugé (juge lab) | | | | **52** |

Diagnostics : livrés DG-02, 03, 04, 06, 07, 08, 12 ; partiels DG-05 (régression au téléphone, ci-dessous) et DG-11 (attendu) ; clos DG-09 ; non reproduit DG-01 (v2.76.0 ne reproduit pas non plus l'échec Git sur ce banc) ; non jugés DG-10, 13, 14, 15.

**Lecture des non livrés.** 16 des 18 visent des propositions que la mission n'a jamais promises : classe C hors lots (016, 028, 031, 033, 046, 053, 056, 065, 069, 073, 075, 076, 088, 129, 185) ou Q2 restée sans réponse (004, 005). Une seule est une **promesse rompue** : **PU-G-137**. La réponse Q8 A « Non, Projet et Code » comportait « on empêche seulement la frappe de déclencher le canevas » ; or sur l'onglet Équipe, à 1 440 px, après un clic sur le fond, les touches p, g, + et − déplacent et zooment toujours le canevas (translate de 106 à 302 px, échelle de 1,1 à 1,32). Capture : `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/nontech/PU-G-137-equipe-apres-frappes-1440.png`.

## 1. Régressions (marchait en v2.76.0, ne marche plus)

1. **PU-G-090 / DG-05 : au téléphone, le texte de la visite guidée est caché.** Deux juges l'ont reproduit chacun de leur côté.
   - Geste : contexte neuf à 390 × 844, tactile, sur Code ou Projet ; la visite s'ouvre d'office ; avancer avec « Suivant » de l'étape 1 à l'étape 4.
   - Constat : la feuille du bas est figée à 120 px (y de 552 à 672). Le titre est coupé et toute la description passe sous la rangée « Passer / Suivant ». Même résultat en clair et en sombre, en tactile et à la souris.
   - v2.76.0 : la bulle montrait le titre et toute la description.
   - Captures : `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/nontech/DG-05-feuille-code-etape1-390.png` contre `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/nontech/DG-05-feuille-code-etape1-390-v2760.png` ; `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/dev/PU-G-026-ouverture-code-jointe-390.png` contre `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/dev/PU-G-026-ouverture-code-v2760-390.png`.
2. **PU-G-035 : l'infobulle de carte reste affichée après une navigation par la recherche.**
   - Geste : 1 440 × 900, clair ; survoler « Racine du dépôt », puis « / », taper « vf-cockpit.mjs », Entrée.
   - Constat : l'infobulle de Racine reste affichée (`display: block`) et se pose sur la carte choisie. Même défaut à 768 px. Le même symptôme a été vu sur Projet par un second juge (infobulle « Phase 71.5 » par-dessus la Phase 52).
   - v2.76.0 : même geste, infobulle fermée.
   - Captures : `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/dev/PU-G-035-infobulle-apres-recherche-jointe-1440.png` contre `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/dev/PU-G-035-infobulle-apres-recherche-v2760-1440.png`.
3. **Hors registre : les titres de la recherche de l'onglet Projet sont devenus des noms de fichier.**
   - Geste : `/project.html`, 1 440 px, « / », taper « format ».
   - Constat : on lit « BACKLOG.md#formats-de-sortie-hétérogènes-… », « …dag.json#propositions », « 20-04-PLAN.md », et le dossier s'affiche « planning. » au lieu de « .planning ».
   - v2.76.0 : titres lisibles (« Formats de sortie hétérogènes entre les 12 suites… »).
   - Cause probable, à confirmer : PU-G-050 (vrai nom de fichier en titre) s'applique aussi à Projet, où les éléments ne sont pas des fichiers.
   - Captures : `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/dev/projet-recherche-format-jointe-1440.png` contre `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/dev/projet-recherche-format-v2760-1440.png`.

Un retrait n'est **pas** une régression : le bouton « Écrans » a disparu de l'en-tête et du menu ⋯. C'est l'effet voulu de DG-02 (à 0 écran, le bouton n'est plus posé). La visite de PU-G-089 ne le cite plus, ce qui reste à confirmer côté contenu.

## 2. Promesses tenues en partie (les parts manquantes qui comptent)

- **PU-G-021, zone basse** : de 701 à 1 279 px, le zoom reste une pile verticale en haut à droite (52 × 144 px, x de 633 à 931 ; 42 × 114 px de 1 000 à 1 279), au même endroit qu'en v2.76.0. La zone basse n'est alignée qu'à partir de 1 280 px (détail en section 4).
- **PU-G-203** : sous 1 280 px, rouvrir « Au travail » replie bien Git, mais le focus reste sur le bouton « 8 au travail » : il faut 15 à 20 Tab pour entrer dans le tiroir. Le CHANGELOG promettait « le focus va au tiroir qui s'ouvre ». Capture : `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/a11y/PU-G-203-travail-rouvert-1024.png`.
- **PU-G-193 et 196** : les définitions Git (« HEAD détaché », ↑/↓) ne passent que par `title`. Elles s'affichent au survol, jamais au focus clavier, alors que Q3 A promettait « au survol et au focus ». Capture : `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/a11y/PU-G-193-git-tiroir-lu-1440.png`.
- **Panneau de détail entre 600 et 999 px** : il est bien fermé par défaut, mais choisir une carte ou un fichier **ne l'ouvre jamais**, à la souris comme au toucher. À 390 px, la feuille s'ouvre. Capture : `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/dev/PU-G-045-fichier-choisi-jointe-768.png`.
- **PU-G-020** : l'en-tête passe d'abord dans l'ordre de tabulation, mais les cartes ne sont jamais atteintes et la pastille Terminal vient en dernier. **PU-G-189** : Échap dans « Au travail » ferme aussi une visite ouverte. **PU-G-188** : le tiroir n'a pas de bouton de fermeture. **PU-G-179** : le verrou périmé de `sess-willy-gouv`, sans session connue, n'est pas signalé.
- **PU-G-038** : la limite à 3 lignes manque sur la vue Phase de Travail récent (5 lignes, sans « Lire la suite »). **PU-G-041** : « route » reçoit le toucher à 390 px mais n'affiche pas de définition. **PU-G-066** : la liste « Fichiers » affiche encore « 4.0k ». **PU-G-068** : la fiche de `driver-lock.sh` n'a pas la mention « extrait brut ». **PU-G-080** : constats de santé et demande « Corriger avec Claude » en anglais (partiel attendu, BACKLOG).
- **PU-G-009** : le mot du thème (« Thème : Auto ») n'apparaît que dans le menu ⋯ ; dès 1 000 px, le bouton montre seulement une icône.
- **PU-G-002** : à 1 000 px, avec un fichier ouvert, le nom du dépôt tombe à « v » et le fil d'Ariane est rogné (« Gates du dépô »). Capture : `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/nontech/PU-G-002-fil-ariane-fichier-1000.png`.

## 3. Ce qui est livré et vérifié (points de Samuel)

- **Carte Code lisible à l'ouverture** : les noms de cartes sont rendus à **12,69 px** à 1 440, 1 280, 1 000 et 768 px (minimum = médiane = maximum), contre 6,39, 5,38, 3,62 et 2,16 px en v2.76.0. Contrepartie : on ne voit que 4 à 7 cartes sur 27 à l'ouverture. Captures : `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/dev/PU-G-026-ouverture-code-jointe-1440.png`, `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/dev/PU-G-026-ouverture-code-v2760-1440.png`.
- **Panneau de détail fermé sous 1 000 px** : fermé à 390, 768 et 999 px, ouvert à 1 000 et 1 280 px (voir la réserve en section 2).
- **Menu ⋯ jusqu'à 999 px** : présent à 390, 700, 701, 768 et 999 px, absent à 1 000 et 1 280 px. Une icône par ligne, une légende « 8 au travail » en tête, un fond opaque en sombre (rgb(15,15,15), contre 0,94 de transparence en v2.76.0). Capture : `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/nontech/PU-G-008-menu-plus-768-sombre.png`.
- **« Préparer dans le terminal » puis Entrée** :
  - le bouton porte ce nom et écrit la ligne sans l'exécuter ;
  - le bandeau dit d'appuyer sur Entrée, la phrase en clair est comprise par le juge non technique, et le compte à rebours de 120 s est visible ;
  - la case « Continuer la conversation du chat » est **décochée** et expliquée (elle n'apparaît qu'après une question au chat) ;
  - Entrée exécute bien la ligne (faux claude affiché) ;
  - réserves : à la hauteur par défaut du tiroir, le bouton est sous le pli, et la consigne « Appuyez sur Entrée » disparaît après la préparation. Capture : `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/nontech/PU-G-136-bandeau-hauteur-par-defaut-1440.png`.
- **Retenue de l'Entrée tenue** : tenue dans les trois cas (focus clavier sur « Préparer », clic souris puis Entrée tenue, Entrée tenue sur « Annuler »), avec 28 répétitions en 1 s. Rien ne s'exécute, et un appui frais exécute la ligne. Captures avant et après sous `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/nontech/` (nommées `retenue-entree-…`).
- **« Au travail » et « Qui a la main »** : en français ; « Session qui pilote », « Qui a la main » et « orphelin ? » s'affichent ; titres /rename présents ; « tenu depuis » stable.
- **Tiroir Git** : étiquette complète au survol et au focus ; pilotage au clavier (`g`, Échap qui rend le focus, y compris à 390 px) ; copies nommées et annoncées.
- **Santé** : compte exact (4 = 3 à corriger + 1 mineur), clés de test signalées, plus de conseil « découper » ou « supprimer » sur le fichier vendorisé.
- **Chiffres** : « 24 sur 41 cartes », conductor 10/10, vue d'un module juste (DG-03, DG-12).
- **Contre-vérification clavier** : tenus PU-G-014 (fenêtre d'export), 018 (noms accessibles), 019 (recherche « / »), 116 (« Préparation… », `aria-busy`, focus gardé) ; 117 tenu en partie (Maj+Tab depuis la saisie du terminal ne remonte pas au bandeau) ; non tenus 031 et 139, deux propositions de classe C non promises.

## 4. Zone basse : alignement mesuré de 390 à 1 440 px

Mesures du juge accessibilité, recoupées par une mesure indépendante du manager sur les deux versions (`/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/manager/zone-basse-jointe-{390,768,1024,1440}.png` et `…-v2760-…`). `--edge` vaut 16 px partout. Code et Projet donnent les mêmes nombres.

| Largeur | Bord gauche zoom / pastille / saisie | Hauteur de la barre | Larg. pastille / larg. zoom | Verdict sur l'attendu de Samuel |
|---|---|---|---|---|
| 390-700 | 8 / 8 / 8 | 92 | 101,6 / 52 | même bord, mais 8 px et non `--edge` ; barre sur deux rangées |
| 701-999 | **633-931 (haut droite)** / 16 / 16 | **92** | 101,6 / 52 | zoom hors axe, barre à 92 px, largeurs différentes |
| 1 000-1 279 | **550-829 (haut droite)** / 16 / 16 | 40 | 101,6 / 42 | barre tenue ; zoom hors axe, largeurs différentes |
| 1 280-1 440 | 16 / 16 / **160-174** | 40 | 114 / 114 | zoom et pastille tenus ; saisie décalée après la colonne de gauche |

Gains par rapport à v2.76.0 : la saisie revient au bord de 16 px de 701 à 1 279 px (avant : 4 à 143,5 px), la barre perd 14 px au-dessus de 1 000 px (54 → 40), et les trois éléments partagent un bord à 390 px. En revanche, **le zoom n'a pas bougé de 701 à 1 279 px**, et la pastille n'a la largeur du zoom qu'à partir de 1 280 px. Ce n'est pas une régression (même état qu'en v2.76.0) ; c'est la principale attente de Samuel qui n'est pas tenue.

## 5. Avis de goût regroupés

| Thème | Point | Note /10 | Avis (juge) |
|---|---|---|---|
| Carte | Composition de l'ouverture (noms lisibles, 4 à 7 cartes visibles) | 6 | « Je perds la carte d'ensemble que je venais chercher » (dev) |
| Carte | Traits au repos (PU-G-029) | 8 | La carte respire, la sélection rallume les traits (dev) |
| Carte | Cartes atténuées en sombre (PU-G-030) | 8 | On lit les voisines sans perdre la mise en avant (dev) |
| Carte | Bloc de titre (PU-G-038) | 6 | « Lire la suite » est propre, mais le paragraphe de 5 lignes de la vue Phase écrase la carte (dev) |
| Mots | « récents » au lieu de « modifié » (PU-G-055) | 8 | Juste, et laisse « modifié » libre pour Git (dev) |
| Mots | Libellé court « Ensemble » de la vue | 4 | Seul, il ne dit pas « vue d'ensemble » (non technique) |
| Coque | Menu ⋯ (icônes, fond opaque, légende) | 8 | Net et rassurant (non technique) |
| Zone basse | Zoom et pastille | 6 | Net à 1 280 px et plus ; en dessous, « deux îlots qui ne se répondent pas » (accessibilité) |
| Lancement | Densité du bandeau | 6 | Tout est expliqué, mais c'est long et le bouton tombe hors de vue (non technique) |
| Terminal | Phrase d'accueil | 8 | « Elle répond exactement à ma peur » (non technique) |
| Visite | Feuille au téléphone, forme seule | 7 | Bonne forme, il lui manque la place pour le texte (non technique) |
| Au travail | Œil « voir la dernière commande » (PU-G-187) | 8 | Dit « regarder » sans évoquer un terminal (accessibilité) |
| Au travail | Titre figé sans fond opaque (PU-G-188) | 7 | Rassurant, mais le texte qui défile se devine derrière (accessibilité) |

## 6. Mots anglais vus

- **Interface (à traduire)** :
  - `aria-label="Terminal input"` sur la saisie du terminal, annoncé par un lecteur d'écran à chaque entrée ;
  - les 4 constats de santé, « One file is very large », « 1,146 lines » et la demande « Corriger avec Claude » entière (BACKLOG, PU-G-080 part C) ;
  - les nombres au format anglais « 4.0k » à « 1.0k » dans la liste « Fichiers » d'un module ;
  - la page transitoire au chargement de Code et au passage Projet → Code (de 60 à plus de 600 ms selon la charge, déjà présente en v2.76.0, PU-G-017 classe C) : « Search files, routes, modules », « Flows », « Ask anything about this codebase... », « checking... », « Laying out… », et les titres de fenêtre « vibeflow-os map » et « VibeFlow · Code ».
- **Données affichées telles quelles** :
  - titres de tâches d'agents : « Replay CI gates job », « Review machine-paths fix diff », « Fix check-machine-paths awk macOS » (PU-G-185) ;
  - descriptions de fichiers : « Code of conduct », « Security », « Contributing », « [English](./README.md) » (PU-G-065) ;
  - jargon du lab dans la visite : skills, gates, dispatch, first-use, superpowers.
- **Termes acceptés** : « Worktrees » comme titre de section Git (Q3 A, défini en `title`), et les noms de produit et de modèle « Claude Code », « sonnet », « opus », « haiku ».

## 7. Constats hors registre utiles

- **Visite et en-tête** :
  - la visite Projet présente « Mission 68 » marquée « À faire », à 50 étapes sur 51 ;
  - le titre de la vue chevauche les cartes pendant la visite et sur un jalon.
- **Terminal et lancement** :
  - « Un terminal est déjà ouvert dans un autre onglet » reste affiché 10 à 30 s après la fermeture du seul autre onglet ;
  - le panneau dit « Lancée : session en cours » en même temps que « Proposition envoyée… », alors que la session est terminée ;
  - « Proposition expirée — la renvoyer. » n'offre aucun bouton pour la renvoyer.
- **Accessibilité** :
  - l'`aria-label` du bouton Git reste « Ouvrir » quand le tiroir est ouvert ;
  - le tiroir « Au travail » n'a pas de nom accessible ;
  - l'infobulle de « 8 au travail » garde un identifiant de session brut ;
  - la saisie du chat a un anneau de focus de 1 px, contre 2 px ailleurs.
- **Cartes** : deux cartes « Readme » homonymes dans « Racine du dépôt ». Le détail et les captures sont dans les rapports des juges.

## 8. Ce que Samuel doit regarder lui-même (goût pur, dix points)

1. **La zone basse sous 1 280 px** : le zoom en pile en haut à droite, loin de la pastille, qui est deux fois plus large. Acceptable, ou à ancrer en bas à gauche comme à 1 280 px ? Captures : `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/manager/zone-basse-jointe-768.png`, `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/a11y/PU-G-021-zone-basse-code-1024.png`.
2. **La zone basse à 1 280 px et plus** : zoom et pastille en colonne à gauche, saisie décalée à 160-174 px. Est-ce l'« axe commun » voulu ? Capture : `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/manager/zone-basse-jointe-1440.png`.
3. **L'ouverture de la carte Code** : noms lisibles, mais 4 à 7 cartes visibles sur 27 et un grand vide. Captures : `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/dev/PU-G-026-ouverture-code-jointe-1440.png` contre `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/dev/PU-G-026-ouverture-code-v2760-1440.png`.
4. **Le libellé « Ensemble »** pour la vue (701-999 px, et sur Projet et Équipe dès 1 000 px). Capture : `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/nontech/PU-G-002-fil-ariane-fichier-1000.png`.
5. **La densité du bandeau de lancement** et le bouton sous le pli. Capture : `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/nontech/PU-G-136-bandeau-hauteur-par-defaut-1440.png`.
6. **La feuille de visite au téléphone** : la forme plaît au juge ; sa hauteur est un défaut (régression 1). Capture : `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/nontech/DG-05-feuille-code-etape3-390.png`.
7. **Les traits au repos et les cartes atténuées en sombre**. Captures : `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/dev/PU-G-029-liens-au-repos-jointe-1440-sombre.png`, `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/dev/PU-G-030-selection-cockpit-jointe-1440-sombre.png`.
8. **Le bloc de titre de la vue Phase** (paragraphe de 5 lignes). Capture : `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/dev/PU-G-038-travail-recent-titre-jointe-1440.png`.
9. **Le menu ⋯ opaque, avec icônes et légende**. Captures : `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/nontech/PU-G-008-menu-plus-768-sombre.png`, `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/nontech/PU-G-008-menu-plus-390-sombre.png`.
10. **Le tiroir « Au travail »** : titre figé sans fond opaque, et l'œil « dernière commande ». Captures : `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/a11y/PU-G-188-au-travail-defile-1440.png`, `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/panel-captures-2026-11-06/recette-2026-11-08/a11y/PU-G-187-oeil-derniere-commande-1440.png`.

## 9. Reste à faire

Il faut un second passage du juge « responsable de lab » sur son périmètre non jugé (PU-G-093 à 110, 143 à 176, DG-10, 13, 14, 15) : états vrais de l'onglet Projet, « STATE.md semble périmé », « Hors jalon », panneau Format et commande copiable, « Qui a la main », masque des secrets. Le banc se remonte avec `scratchpad/recette/setup-lab.sh lab` et `lab-old`, puis `cockpit.sh lab open` et `lab-old open`. Ce passage doit précéder toute correction des régressions 1 à 3 et de PU-G-137.
