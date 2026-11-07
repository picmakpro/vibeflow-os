# Panel d'utilisateurs — Équipe, Au travail, tiroir Git, terminal (2026-11-06)

Demande de Samuel (message direct en session principale, 2026-11-06) : faire juger la version validée
pour la release par des juges indépendants qui incarnent des utilisateurs potentiels, recueillir leurs avis
et leurs notes, puis globaliser les propositions pour les tâches rapides. Ce rapport couvre l'un des trois
périmètres : **Équipe, Au travail, tiroir Git, terminal**, et la façon dont ces tiroirs cohabitent.

- **Version jugée** : cockpit v1.4.0, code de `.claude/worktrees/cockpit-final`
  (branche `integration/cockpit-final`, HEAD `41b3af31`). C'est un commit de documentation au-dessus
  de `a95c018d`, cité dans le brief : `git diff a95c018d 41b3af31 -- plugin/cockpit` est vide.
- **Pas de verrou de mission ni de numéro de phase.** Rien n'a été écrit dans le code, STATE ou ROADMAP.
  Ce fichier est la seule écriture du manager dans ce worktree.
- **Juges** : quatre agents à contexte frais, en parallèle. Aucun ne voyait les autres, ni les attentes du
  manager, ni le code. Chacun avait son cockpit, son Chromium persistant (Playwright 1.60) et sa copie de
  lab. Au total, 299 captures.
- **Quatrième profil, ajouté par le manager** : l'utilisateur au clavier seul. Chaque tiroir a son
  raccourci (g, Ctrl+Maj+Espace, Échap, /) et le bandeau de lancement repose sur un double geste. Il
  fallait donc un juge qui vérifie l'atteignabilité, le focus et les conflits de touches. Les trois autres
  profils naviguent surtout à la souris.

## Montage (ce qui est réel, ce qui est fabriqué)

Tout vit dans le scratchpad de la session :
`<scratchpad>/panel-egt/`
(scripts `setup-lab.sh`, `fab.py`, `heartbeat.py`, `url.sh`, `stop.sh`, `bin/claude`).

- **4 copies de lab** (`lab-dev`, `lab-resp`, `lab-nouveau`, `lab-clavier`). Chacune est un clone du dépôt
  vibeflow-os sur `integration/cockpit-final`, tiré d'une copie nue locale (`origin.git`, aucun réseau). Il
  y a 4 cockpits avec `--terminal` sur les ports 4511 à 4514 ; un terminal n'accepte qu'une session par
  serveur, d'où un serveur par juge. Chaque cockpit tourne avec un `HOME` factice par juge.
- **État Git réel, fabriqué dans la copie** :
  - 6 arbres : l'arbre principal plus les worktrees `terminal-bandeau`, `design-tiroirs`, `parseurs`,
    `lancer-72` et `bisect-ci` (HEAD détaché) ;
  - `main` en retard de 38 sur `origin/main`, et `feat/phase-72-lancer-depuis-cartes` en avance de 1 et en
    retard de 2 ;
  - du travail non commité (fichiers modifiés et non suivis) dans l'arbre principal et dans deux worktrees ;
  - des commits du jour signés par trois auteurs (Samuel, Willy, Léa — fictive) ;
  - les branches et les 111 tags réels du dépôt.
- **État Équipe fabriqué** à partir de **vrais transcripts** de sous-agents (session `5237320c` du dépôt).
  Les chemins ont été réécrits vers la copie, les horodatages décalés, les états posés par le manager :
  - session A active, avec son vf-dev-manager actif ;
  - un vf-coder actif dans le worktree `terminal-bandeau` ;
  - un vf-auditer « sans nouvelle depuis 2 min 30 » (silencieux), tenu par une boucle de battement ;
  - un relecteur terminé, un généraliste arrêté à la main et un généraliste terminé ;
  - un design-manager terminé il y a 2 h, avec 2 crafters et 2 juges terminés ;
  - session B active dans `design-tiroirs` ;
  - session C fermée depuis 2 h, dont le manager d'arrière-plan travaille encore ;
  - session D finie il y a 5 h.
- **Verrous et registre fabriqués** avec `driver-lock.sh` dans la copie :
  - compartiment `fiabilite` tenu par la session A, battement toutes les 15 s ;
  - compartiment `gouvernance` périmé (dernier signe de vie 1 h 40 plus tôt), avec deux agents encore
    `running` au registre. Le collecteur les sort bien comme orphelins :
    `vf-cockpit-who.mjs` affiche `ORPHELIN`.
- **Faux `claude`** (`bin/claude`) : aucune IA. Il écrit un transcript minimal avec l'identifiant passé par
  `--session-id`, ce qui permet de tester « Lancée depuis la carte ». Il répond à `--version`.

**Effets du montage à connaître en lisant les avis**
- « tenu depuis 0 s / 6 s / 15 s » sur le verrou `fiabilite` : le chiffre repart à zéro à chaque battement.
  Ma boucle battait toutes les 15 s, plus souvent qu'un vrai manager ; le comportement de fond reste celui
  du produit.
- Les titres de tâches en anglais (« Replay CI gates job ») et l'agent terminé sans titre (forme
  « arrêté par l'utilisateur », sans `description`) viennent de **données Claude Code réelles**, pas du
  montage.
- Le faux claude n'écrit qu'au démarrage. Une session lancée et restée muette plus de 3 min sans
  sous-agent sort de la collecte : c'est le comportement réel du collecteur pour une session silencieuse.
- « Git est indisponible » : le dépôt copié est gros (≈ 460 commits affichés, 111 tags, 6 worktrees). Quatre
  cockpits et quatre Chromium tournaient en même temps sur la machine. La charge a pu jouer, mais le juge
  développeur l'a reproduit 4 fois sur 4, et le dépôt réel de Samuel a la même taille.

## Notes

| Profil | Note | Utilité | Lisibilité | Confiance | Finition | Captures |
|---|---|---|---|---|---|---|
| Développeur | **61** | 18 | 15 | 12 | 16 | `captures/dev/` (66) |
| Utilisateur au clavier seul | **60** | 17 | 16 | 13 | 14 | `captures/clavier/` (94) |
| Responsable de lab non développeur | **57** | 16 | 11 | 14 | 16 | `captures/resp/` (61) |
| Nouvel arrivant | **56** | 15 | 12 | 12 | 17 | `captures/nouveau/` (78) |
| **Moyenne** | **58,5** | 16,5 | 13,5 | 12,75 | 15,75 | |

La **confiance** est la note la plus basse, chez tous les profils.

## Avis des juges (dans leurs mots, abrégés)

**Développeur (61)** — « Le cockpit sait des choses que mon terminal ne me donne pas d'un coup d'œil : pour
chaque agent, sa branche et son worktree ; Au travail affiche l'arbre session → manager → coder, et Git
montre les 6 worktrees avec leur état. Le lancement depuis une carte affiche la commande `claude …`
complète, et la session lancée se retrouve dans Équipe avec "Lancée depuis la carte". Ma confiance a pris
des coups : "Git est indisponible" à chaque premier chargement, "état illisible" sur tous les worktrees,
"Branche indisponible" pendant que je tapais `git log`, et une proposition qui disparaît alors que le
panneau dit encore "Confirmez-la dans le terminal". Pour repérer un agent bloqué ou orphelin, je dois
encore déduire moi-même. »

**Responsable de lab (57)** — « Le tiroir Au travail est la meilleure surprise : en un clic, je vois qui
travaille, sur quoi et depuis combien de temps. Mais dans l'onglet Équipe, je perds tout : "Session
79c70781 · Pas encore de description". Partout, des mots de développeur me barrent la route : "Driver",
"Verrous tenus", "non rattaché (sans-citation)", "HEAD détaché", "état illisible", "worktree". Le journal
d'un agent est un mur de texte technique. Le bandeau Lancer me montre une commande `claude --session-id …`,
puis il disparaît tout seul. Je n'ai jamais eu peur de casser quelque chose, mais je ne saurais pas
expliquer cet écran à mon équipe. »

**Nouvel arrivant (56)** — « À première vue, c'est beau et calme : graphite, cartes arrondies, une visite
guidée qui me montre le point "qui travaille". Au travail est ce que je comprends le mieux, et l'historique
Git ferait une très bonne capture. Mais dès que je creuse : jargon interne, markdown brut (`**`,
`<!-- vf-archive -->`), des sessions en hexadécimal suivies de "Pas encore de description", "Git est
indisponible" trois fois sur six, et "Lancer" qui ne lance rien. Je ne confierais pas encore la
surveillance de mon code à cet outil ; en démo, je montrerais seulement Au travail et Git. »

**Utilisateur au clavier (60)** — « Les tiroirs ont clairement été pensés pour le clavier. Git est le
meilleur élève : g l'ouvre, les flèches parcourent le graphe, Échap referme couche par couche et rend le
focus. Le terminal s'ouvre et se ferme avec Ctrl+Maj+Espace, et la poignée de hauteur se règle aux
flèches. Mais lancer une session depuis une carte est un parcours du combattant. Les cartes ne sont pas
focalisables, le terminal capte Tab et Maj+Tab, et le bouton Lancer ne s'atteint qu'à reculons, avec 26
Maj+Tab. Deux fois, le panneau m'a dit "Confirmez-la dans le terminal" sans aucun bandeau : c'est là que
j'ai perdu confiance. »

### Ce qui a aidé (cité par au moins deux profils)
- **Au travail** : l'arbre session → manager → agents, avec le worktree, la branche, la durée et « sans
  nouvelle depuis 3 min » (les 4 profils).
  `captures/dev/08-au-travail-1440.png`, `captures/resp/05-tiroir-au-travail-1280-clair.png`.
- **Visite « Par où commencer »**, qui mène au point « au travail » (responsable de lab, nouvel arrivant).
- **Git** :
  - cartes de worktree avec leur état et le détail de commit en ligne (développeur, nouvel arrivant,
    responsable de lab) ;
  - « Lecture seule. Chaque action est une commande à copier. » rassure (responsable de lab) ;
  - Échap par couches et retour du focus (clavier).
- **Terminal** :
  - un vrai shell ; poignée de hauteur à la souris et au clavier (développeur, clavier) ;
  - double geste « la ligne est écrite, c'est moi qui fais Entrée » (développeur, responsable de lab) ;
  - « Lancée depuis la carte » retrouvée dans Équipe (développeur, nouvel arrivant, clavier).
- **Thème sombre** soigné (responsable de lab, nouvel arrivant).

## Propositions dédupliquées

Colonnes :
- **Profils** : D développeur, R responsable de lab, N nouvel arrivant, C clavier.
- **Taille** : « réglage » tient en un commit ; « plus » demande davantage.
- **Drapeau** : contradiction possible avec DESIGN.md (Graphite) ou avec un arbitrage déjà rendu. Une
  proposition signalée n'est pas écartée : Samuel tranche.

Les captures sont relatives à
`<scratchpad>/panel-egt/captures/`.
**Attention : ce scratchpad est vidé au redémarrage de macOS.**

### Onglet Équipe

| ID | Élément · écran | Changement demandé | Profils | Capture | Taille | Drapeau |
|---|---|---|---|---|---|---|
| PU-EGT-01 | Titre des cartes de session · toutes largeurs | Remplacer « Session 79c70781 » par la tâche principale (celle que Au travail connaît déjà) ou par le nom `-n` de la session ; garder l'identifiant en petit | R, N, D | `resp/12-equipe-1280-clair.png`, `nouveau/04-apres-clic-equipe.png` | plus | — |
| PU-EGT-02 | « Pas encore de description » sur toutes les cartes · toutes largeurs | Masquer la ligne vide, ou y mettre la dernière action | N, R | `nouveau/21-equipe-1440-sombre.png` | réglage | — |
| PU-EGT-03 | Carte de session · 1440 | Afficher la branche et le worktree sur la carte (aujourd'hui, seulement au clic) | D | `dev/02-equipe-1440-clair.png` | réglage | — |
| PU-EGT-04 | Carte « en attente · 2 h » qui porte aussi la pastille « En cours » · 1280-1440, deux thèmes | Un seul état par carte | R, N | `resp/12-equipe-1280-clair.png`, `nouveau/21-equipe-1440-sombre.png` | réglage | — |
| PU-EGT-05 | Titre « 2 missions en cours », à côté de 4-5 cartes et de « 8 actifs » · 1440 | Aligner le compteur sur ce qui est affiché, ou expliquer missions et sessions | R, D, N | `dev/55-session-lancee-detail.png`, `nouveau/04-apres-clic-equipe.png` | réglage | — |
| PU-EGT-06 | « non rattaché (inconnu) / (sans-citation) » dans le panneau d'agent | Le dire en clair (« pas lié à une phase du projet ») ou le masquer | R, D, N | `dev/07-manager-ouvert.png`, `resp/18-equipe-dans-manager.png` | réglage | — |
| PU-EGT-07 | Transcript (« Lire le transcript ») | Rendre le markdown : tableaux, gras, code | D, N, R | `dev/05-transcript-session.png`, `nouveau/08-agent-journal.png` | plus | — |
| PU-EGT-08 | Transcript d'agent | D'abord un résumé de 2-3 phrases (mission, où il en est), le mandat brut derrière « Voir le détail technique » | R | `resp/19-equipe-journal-agent-auditer.png` | plus | — |
| PU-EGT-09 | Liste « Outils » du journal (14 fois « lance une commande (Bash) ») | Montrer le début de chaque commande et regrouper les répétitions | N | `nouveau/09-agent-journal-scrolle.png` | plus | — |
| PU-EGT-10 | « Voir la dernière commande » (« rtk proxy … », « until … », « … ») · Équipe et Au travail | Montrer la commande entière, repliable ; « Aucune commande récente » si elle est vide ; « Lire le transcript » ne doit plus sauter sous le résultat | D, N, R | `dev/05-transcript-session.png`, `nouveau/11-derniere-commande-haut.png`, `resp/08b-au-travail-derniere-commande-clic.png` | réglage | — |
| PU-EGT-11 | « Lire le transcript » · 1440 | Indicateur de chargement (≈ 3 s de silence aujourd'hui) | D | `dev/05-transcript-session.png` | réglage | — |
| PU-EGT-12 | Durées « actif · 11 s » (session) et « actif · 38 min » (agent) | Distinguer « dernière activité il y a 11 s » de « au travail depuis 38 min » | N | `nouveau/06-equipe-session-dedans.png` | réglage | — |
| PU-EGT-13 | Ligne « Lancée depuis la carte » (panneau) | Ajouter le mode de permission choisi et le nom de session | D | `dev/55-session-lancee-detail.png` | réglage | — |
| PU-EGT-14 | Carte de la session lancée | Mettre aussi une petite étiquette « depuis Phase 71.5 » sur la carte, pas seulement dans le panneau | N | `nouveau/50-session-lancee-carte.png` | réglage | — |
| PU-EGT-15 | Session lancée qui disparaît quelques minutes plus tard (terminal vierge au retour) · 390 | Ne pas la faire disparaître sans un mot, ou prévenir. Voir les effets du montage : une session muette sans sous-agent sort de la collecte | N | `nouveau/59-equipe-390-clair.png`, `nouveau/61-projet-390-clair.png` | plus | — |
| PU-EGT-16 | Passage d'un onglet à l'autre (Projet → Équipe) · 1440 | Ne plus montrer la coquille vide de la page Code en anglais (« Search files, routes, modules », « Ask anything… ») ; squelette en français | N | `nouveau/03-equipe-1440-clair.png` | plus | touche la coque (autre panel) |
| PU-EGT-17 | Infobulle « 2×clic ouvrir / clic droit plus » | Elle masque la carte. La retirer sur écran tactile, ou dire « toucher deux fois » | N | `nouveau/60-session-tap-390-clair.png` | réglage | — |
| PU-EGT-18 | Cartes de session et d'agent du canevas · clavier | Les rendre focalisables (focus mobile aux flèches, Entrée pour entrer, Échap pour remonter) ; aujourd'hui la recherche « / » est le seul chemin | C | `clavier/04-equipe-1440-arrivee.png` | plus | — |
| PU-EGT-19 | Liste « Contenu » du panneau (vf-coder…, vf-auditer…) | Chaque entrée devient un bouton ou un lien atteignable au Tab | C | `clavier/10a-equipe-1440-transcript.png` | réglage | — |
| PU-EGT-20 | Échap avec le focus hors du canevas | Ne remonter d'un niveau que si le focus est dans le canevas : aujourd'hui, le résultat de « Voir la dernière commande » est perdu | C | `clavier/10z-equipe-1440-apres-voir-commande.png` | réglage | — |
| PU-EGT-21 | Grille de cartes · 390 | Une seule colonne : la deuxième est coupée à droite | N | `nouveau/51-equipe-390-sombre.png` | réglage | — |
| PU-EGT-22 | Mot « Plus » orphelin sous le sous-titre · 390 | Le supprimer, ou en faire un vrai bouton | R | `resp/53-equipe-390-clair.png` | réglage | — |
| PU-EGT-23 | Menu « … » · 390 sombre | Fond opaque : le titre se lit à travers | N | `nouveau/53-menu-plus-390.png` | réglage | vérifier le fond prévu (`--menu-solid`, DESIGN §5) |
| PU-EGT-24 | Panneau de détail · 768 | Il couvre la moitié des cartes : le fermer par défaut ou décaler la grille | N | `nouveau/64-equipe-768-clair.png` | réglage | — |
| PU-EGT-25 | Panneau de jalon ou de phase (vu en route, onglet Projet) | Rendre le markdown et masquer les `<!-- vf-archive … -->` | R, N | `resp/29-jalon-v2-phases.png`, `nouveau/02-tour-2.png` | réglage | hors périmètre (Projet), gardé |
| PU-EGT-26 | Statut de la Phase 72 (vu en route) | Harmoniser « prête à planifier » (visite, panneau) et « À recetter » (carte) | N | `nouveau/01-projet-1440-premiere.png` | réglage | hors périmètre (Projet), gardé |
| PU-EGT-27 | Infobulle de la carte Releases (vue en route) | Retirer « 0 Lignes » | N | `nouveau/66-cohab-trois-tiroirs-1440-clair.png` | réglage | hors périmètre (Projet), gardé |

### Tiroir « Au travail »

| ID | Élément · écran | Changement demandé | Profils | Capture | Taille | Drapeau |
|---|---|---|---|---|---|---|
| PU-EGT-28 | Ligne « Driver 88f83d8b-65ec-… tenu depuis 12 s » | La dire en clair (« Session qui pilote : Correctif terminal sous Safari »), sans identifiant | R, N | `resp/05-tiroir-au-travail-1280-clair.png`, `nouveau/13-tiroir-au-travail-1440.png` | réglage | — |
| PU-EGT-29 | Section « Verrous tenus » | La renommer (« Qui a la main ») et ajouter une phrase d'aide (« rien à faire de votre côté ») | R | `resp/07-au-travail-fin.png` | réglage | — |
| PU-EGT-30 | « tenu depuis » qui repart à 0 à chaque battement ; verrou `gouvernance` dont le détenteur n'apparaît dans aucune session | Afficher la date de prise du verrou ; marquer un verrou au détenteur introuvable | D | `dev/10-au-travail-verrous.png` | réglage | — |
| PU-EGT-31 | Pied « Sessions et sous-agents : lue · Verrous du dépôt : lue · … » | Le masquer quand tout va bien ; ne parler que d'une source illisible | R | `resp/07-au-travail-fin.png` | réglage | — |
| PU-EGT-32 | En tête du tiroir | Une ligne « À surveiller » qui remonte les agents silencieux, « en couleur d'alerte » | R | `resp/07-au-travail-fin.png` | plus | **drapeau** : la couleur d'alerte contredit l'arbitrage « état = glyphe et mot en texte neutre ». La ligne elle-même est compatible |
| PU-EGT-33 | Orphelins et sessions en attente avec enfants actifs | Marquer « orphelin ? » un enfant actif dont la session parente attend ou se tait depuis plus de 30 min. **Constat du manager** : les deux orphelins du registre, que le collecteur sort bien, n'apparaissent jamais dans le tiroir. `70-vf-live.js`, `htmlTiroir`, garde `autres = reste.filter(… && !w.stale …)` ; un orphelin du registre a `stale: true`. Aucun juge n'a vu d'orphelin | D (+ C en non jugé) | `dev/08-au-travail-1440.png`, `dev/10-au-travail-verrous.png` | plus | — |
| PU-EGT-34 | Agent qui « lance une commande » depuis 62 min | Signaler une commande longue au-delà d'un seuil, « en couleur d'alerte » | D | `dev/07-manager-ouvert.png` | réglage | **drapeau** : couleur d'alerte (même arbitrage que PU-EGT-32). Un glyphe et un mot suffiraient |
| PU-EGT-35 | Terminé sans titre (✓ « a duré 6 min ») | Nom de repli : rôle + identifiant court | R, D, C | `dev/11-au-travail-termines.png`, `resp/11-au-travail-termines.png` | réglage | — |
| PU-EGT-36 | Titres de tâches en anglais (« Replay CI gates job ») | Langue du lab, ou au moins le rôle en français | R | `resp/11-au-travail-termines.png` | plus | la source est la description écrite au lancement par le manager |
| PU-EGT-37 | Plusieurs lignes « Session principale » | Distinguer : nom `-n`, arbre ou identifiant court | D, N | `dev/60-trois-tiroirs-1280-sombre.png`, `nouveau/13-tiroir-au-travail-1440.png` | réglage | — |
| PU-EGT-38 | Icône « >_ » de « Voir la dernière commande » | Une icône qui ne fait pas penser à « ouvrir un terminal », ou un libellé | N | `nouveau/14-au-travail-bas.png` | réglage | — |
| PU-EGT-39 | Titre du tiroir au défilement | Garder « Au travail · N actifs » et le bouton de fermeture visibles en haut | N | `nouveau/14-au-travail-bas.png` | réglage | — |
| PU-EGT-40 | Échap | Échap ferme seulement le tiroir, même avec le focus dans l'en-tête, sans faire remonter le canevas, et rend le focus au bouton « N au travail » | R, C | `resp/52-git-1280-sombre.png`, `clavier/15c-autravail-1440-echap1.png`, `clavier/68b-autravail-768-sombre-apres-echap.png` | réglage | — |
| PU-EGT-41 | Bouton « N au travail » | `aria-expanded` et `aria-controls`, comme la ligne Git | C | `clavier/12-autravail-1440-ouvert.png` | réglage | — |

### Tiroir Git

| ID | Élément · écran | Changement demandé | Profils | Capture | Taille | Drapeau |
|---|---|---|---|---|---|---|
| PU-EGT-42 | Premier chargement : « Git est indisponible — … échoué ou dépassé le délai » | Relancer seul une fois, ou allonger le délai du premier appel ; donner une raison humaine. Reproduit 4/4 chez le développeur, 3/6 chez le nouvel arrivant | D, R, N | `dev/16-git-charge-1440.png`, `resp/20-git-tiroir-1280-clair.png`, `nouveau/17-tiroir-git-charge.png` | plus | — |
| PU-EGT-43 | « état illisible » sur les 6 worktrees | « lecture… » ou squelette tant que l'état n'est pas lu ; un mot qui ne suggère pas une corruption | R, D | `dev/17-git-reessayer.png`, `resp/22-git-apres-attente.png` | réglage | — |
| PU-EGT-44 | Seconde ligne de l'en-tête : « Branche indisponible », ou ligne disparue après rechargement | Garder la dernière branche connue, grisée, et toujours une entrée vers Git | R, D, N, C | `dev/34-terminal-commandes-projet.png`, `resp/42-terminal-apres-rechargement.png`, `nouveau/23-jalon-v2-sombre.png`, `clavier/30-projet-1440-apres-rechargement-raccourci.png` | réglage | — |
| PU-EGT-45 | Jargon « Worktrees », « HEAD détaché », chemin `/private/tmp/…` en premier | Mots simples (« copie de travail », « pas sur une branche ») avec une infobulle ; le chemin après le nom | R, N | `resp/22-git-apres-attente.png`, `nouveau/54-git-390-sombre.png` | réglage | désaccord avec D (voir plus bas) |
| PU-EGT-46 | `git switch --detach …` au même rang que `git show` (détail de commit) | L'étiqueter « change votre copie de travail » et le séparer des commandes de lecture, « en couleur d'avertissement » | R | `resp/24-git-detail-changement.png` | réglage | **drapeau** : couleur d'avertissement (arbitrage « état neutre »). Le classement reste compatible avec l'arbitrage « Git en lecture seule, commandes à copier » |
| PU-EGT-47 | Étiquettes de branche du graphe tronquées (« fea… », « orig… ») | Tiroir élargissable, ou étiquette complète au survol et sur une ligne à part | D | `dev/18-git-graphe.png` | plus | — |
| PU-EGT-48 | Indicateurs ↑ / ↓ des worktrees | Infobulle « 312 commits d'avance sur main » | D | `dev/22-git-worktrees-etats.png` | réglage | — |
| PU-EGT-49 | Section « Auteurs et activité » sous ≈ 450 commits, qui s'ouvre hors écran | La placer avant le graphe, ou faire défiler jusqu'à elle à l'ouverture | D | `dev/29-git-auteurs-clavier.png` | réglage | — |
| PU-EGT-50 | Titre « Historique Git » focalisé après g (et le cadre du terminal) | Anneau de focus visible (`--ring`), ou focus sur le premier contrôle | C | `clavier/16a-git-1440-ouvert.png` | réglage | conforme à DESIGN §9 (focus visible) |
| PU-EGT-51 | Région « Détail du commit » imbriquée dans la liste « Commits » | La sortir de la liste et la relier par `aria-controls` | C | `clavier/19a-git-1440-detail-charge.png` | réglage | — |
| PU-EGT-52 | Boutons Copier | Nom court (« Copier la commande cd vers bisect-ci ») ; résultat annoncé dans une région live | C | `clavier/20a-git-1440-copie.png` | réglage | — |
| PU-EGT-53 | Échap à 390 | Échap ferme Git comme à 1440 ; focus rendu à « Plus d'actions » | D, C | `dev/64-390-apres-echap.png`, `clavier/65a-git-390-echap2.png` | réglage | — |
| PU-EGT-54 | Serveur arrêté | Git dit « serveur arrêté » et non « Git est indisponible » ; l'état se propage à l'en-tête | D | `dev/67-serveur-arrete-git.png` | plus | — |

### Terminal et bandeau de lancement

| ID | Élément · écran | Changement demandé | Profils | Capture | Taille | Drapeau |
|---|---|---|---|---|---|---|
| PU-EGT-55 | Message du panneau « Proposition envoyée… Confirmez-la dans le terminal » | Le mettre à jour quand le bandeau expire, est annulé ou disparaît (« Proposition retirée, rien n'a été lancé ») | R, D, C | `dev/46-etat-bandeau-apres-30s.png`, `resp/40-bandeau-annule.png`, `clavier/41a-terminal-1440-bandeau.png` | réglage | — |
| PU-EGT-56 | Expiration du bandeau | Compte à rebours visible ; à l'expiration, le dire | D, R | `dev/46-etat-bandeau-apres-30s.png`, `resp/34a-etat-bandeau.png` | réglage | — |
| PU-EGT-57 | Bandeau perdu après fermeture et réouverture du terminal | Le garder tant qu'il n'est ni lancé ni annulé | C | `clavier/49-terminal-1440-rouvert-bandeau.png` | réglage | — |
| PU-EGT-58 | Clic sur Planifier ou Vérifier : 4 à 13 s sans retour, puis focus perdu | Retour immédiat (« Préparation… », `aria-busy`) ; focus gardé sur le bouton ou envoyé au bandeau | R, C | `resp/32-bandeau-lancer-planifier.png`, `clavier/35b-projet-1440-apres-verifier.png` | plus | envoyer le focus au bandeau : voir PU-EGT-59 |
| PU-EGT-59 | Bandeau inatteignable au Tab (26 Maj+Tab) | Le placer avant la saisie dans l'ordre du DOM et y déplacer le focus à son apparition | C | `clavier/48b-terminal-1440-tab-dans-bandeau.png`, `clavier/51a-terminal-1440-bandeau-atteint.png` | réglage | **drapeau** : le README P72 pose « Une proposition ne prend jamais le focus clavier ». Seule la partie ordre du DOM ne contredit rien |
| PU-EGT-60 | Planifier avec le terminal fermé : rien ne bouge | Ouvrir le terminal avec le bandeau visible. Le bandeau n'apparaissait qu'après une frappe : constaté en Chromium sans affichage, à confirmer dans un vrai navigateur | N | `nouveau/27-apres-planifier.png`, `nouveau/43-apres-ls-t500.png` | réglage | — |
| PU-EGT-61 | Contenu du bandeau | Une phrase simple d'abord (« Un agent va planifier la Phase 71.5, en lecture seule ») ; la commande brute repliée derrière « Voir la commande » | R, N | `resp/37-bandeau-lancement-propose.png`, `nouveau/29-terminal-ouvert-1440-sombre.png` | réglage | désaccord avec D ; replier la commande touche à P72-D-14 (« commande exacte » visible avant le geste) : à trancher |
| PU-EGT-62 | Menu « Mode de permission » | Libellés en langage simple ; dire ce que vaut « Par défaut » | R, N | `resp/39-bandeau-mode-lecture-seule.png` | réglage | — |
| PU-EGT-63 | Bandeau qui recouvre la sortie du shell (à 160 px, il masque tout) | Pousser la sortie vers le haut, ou agrandir le terminal à ≥ 300 px quand le bandeau apparaît | D, N | `dev/43-apres-planifier-attente.png`, `nouveau/44-bandeau-revu.png` | réglage | — |
| PU-EGT-64 | Bouton « Lancer » qui colle sans exécuter | Exécuter réellement, ou renommer en « Préparer dans le terminal » | N | `nouveau/46-lancer-t5.png` | réglage | **drapeau** : exécuter contredit P72-D-09 et P72-D-14 (double geste, rien sans Entrée). Renommer est compatible |
| PU-EGT-65 | Section « Lancer du travail » enfouie en bas du panneau de phase | La remonter sous le titre de la phase | D, N | `dev/40-detail-phase-bas.png`, `nouveau/26-panneau-lancer-du-travail.png` | réglage | — |
| PU-EGT-66 | Terminal absent de l'onglet Équipe (Ctrl+Maj+Espace sans effet, frappe captée par le canevas) | Pastille et raccourci aussi sur Équipe | D, C | `dev/32-terminal-commandes.png`, `clavier/22-equipe-1440-raccourci-terminal.png` | plus | **drapeau** périmètre : P71 pose le tiroir sur Projet et Code seulement. Au minimum, empêcher la frappe de déclencher le canevas |
| PU-EGT-67 | Reconnexion après rechargement ou changement d'onglet : écran vide, sortie du claude lancé perdue | Réafficher les dernières lignes (le README annonce un tampon de reprise de 256 Kio) | D | `dev/58-rechargement-4s.png` | plus | désaccord : C dit l'historique conservé |
| PU-EGT-68 | Piège clavier : Tab, Maj+Tab, Échap, F6 restent dans le terminal (F6 écrit « 7~ ») | Une touche de sortie qui rend le focus à la page sans fermer, écrite dans la barre « Terminal · Connecté » | C | `clavier/28-terminal-1440-tentatives-sortie.png` | plus | — |
| PU-EGT-69 | Première ouverture : invite nue | Une phrase d'accueil effaçable (ce qu'est cet outil, qu'on n'en a pas besoin pour suivre le travail) | R | `resp/27-terminal-ouvert-1280-clair.png` | réglage | — |
| PU-EGT-70 | « Session expirée — Relancez /vf-cockpit --terminal. » sans session préalable | Message juste (« terminal non disponible dans cet onglet ») ; dire où taper la commande | R | `resp/43-terminal-sans-amorcage.png` | réglage | — |
| PU-EGT-71 | Bulle « Serveur arrêté » qui déborde du tiroir | La garder entière dans le tiroir ; bouton copier sur `/vf-cockpit --terminal` | D | `dev/66-serveur-arrete-projet.png` | réglage | **à vérifier** : le refus d'un repli « copier la commande » (motif ClickFix, P72) vise la commande de lancement, pas a priori celle-ci |
| PU-EGT-72 | Poignée « Hauteur du terminal » | `aria-valuetext` avec unité (« 324 px ») | C | `clavier/32c-terminal-1440-poignee-end.png` | réglage | — |
| PU-EGT-73 | Pastille Terminal et « au travail » à plus de 8 s après rechargement | Les afficher dès le premier rendu, en état « connexion… » | C | `clavier/29a-terminal-1440-apres-rechargement.png` | réglage | zone de la pastille, voir PU-EGT-77 |

### Cohabitation et transverse

| ID | Élément · écran | Changement demandé | Profils | Capture | Taille | Drapeau |
|---|---|---|---|---|---|---|
| PU-EGT-74 | Plusieurs tiroirs ouverts sous 1280 (768 : la page disparaît ; 1024 : la carte devient un timbre-poste) | Un seul tiroir latéral à la fois sous 1280, ou replier Git quand le terminal s'ouvre, ou terminal réduit à une barre | R, D, C | `resp/46-cohab-768-trois-tiroirs.png`, `dev/60-trois-tiroirs-1024-sombre.png`, `clavier/62a-cohabitation-1024-clair-git-terminal-projet.png` | plus | — |
| PU-EGT-75 | Tiroir Git qui recouvre les cartes de session · 1440 | Décaler ou recentrer la carte, comme le fait le terminal | D | `dev/65-equipe-git-autravail-1440-clair.png` | plus | désaccord avec N |
| PU-EGT-76 | En-tête à 1024 : « lab-d… », « V… » (Vue d'ensemble) | Ne pas tronquer : recherche réduite à une loupe, ou nom du lab sur deux lignes | R, D, N, C | `resp/54-au-travail-1024-clair.png`, `nouveau/65-cohab-autravail-git-1024-clair.png` | réglage | — |
| PU-EGT-77 | Boutons de zoom : colonne au milieu de la carte à 768 ; bloc trop gros à 390 | Les ancrer en bas à gauche comme à 1280 ; les réduire à 390 | R, N | `resp/49-768-au-travail-seul.png`, `nouveau/59-equipe-390-clair.png` | réglage | **zone du codeur** qui revoit l'alignement zoom, pastille et chat. Arbitrage « pastille Terminal sous les boutons de zoom, tiroir fermé » à respecter |
| PU-EGT-78 | Ordre de Tab sur Projet et Équipe (zoom et barre de question avant l'en-tête) | L'en-tête d'abord, puis le canevas, puis la barre de question et le zoom | C | `clavier/02-projet-1440-tab22.png` | réglage | même zone que PU-EGT-77 |
| PU-EGT-79 | Boutons sans nom accessible : croix de la visite, flèche d'envoi de la question au premier rendu, copie du chemin de phase | Les nommer (« Fermer la visite », « Demander », …) | C | `clavier/01-projet-1440-arrivee.png` | réglage | — |
| PU-EGT-80 | Recherche « / » | Après Échap, rendre le focus à l'élément d'origine ; après Entrée, le mettre sur l'élément ouvert | C | `clavier/21-equipe-1440-g-dans-recherche.png` | réglage | — |
| PU-EGT-81 | Graphe de Projet à 390 (vu en route) | S'ouvrir sur une liste lisible (jalons puis phases) plutôt que sur le graphe dézoomé | N | `nouveau/63-projet-390-clair-sans-terminal.png` | plus | hors périmètre (Projet), gardé |

**Total : 81 propositions** (27 Équipe, 14 Au travail, 13 Git, 19 Terminal, 8 Cohabitation).
- **Drapeaux d'arbitrage** :
  - PU-EGT-32, 34 et 46 : couleur d'alerte ou d'avertissement ;
  - PU-EGT-59 : le bandeau prendrait le focus ;
  - PU-EGT-64 : Lancer exécuterait ;
  - PU-EGT-66 : terminal sur Équipe, contre le périmètre P71 ;
  - PU-EGT-61 : commande repliée.
- **À vérifier** : PU-EGT-71 (bouton copier, motif ClickFix) et PU-EGT-23 (fond du menu).
- **Zone du codeur** (zoom, pastille Terminal, chat) : PU-EGT-73, 77 et 78.

### Les plus portées (nombre de profils)
1. **PU-EGT-44** — « Branche indisponible », ou ligne d'en-tête disparue : 4 profils.
2. **PU-EGT-76** — en-tête tronqué à 1024 : 4 profils.
3. **PU-EGT-42** — « Git est indisponible » au premier chargement : 3 profils, le signal de confiance le plus cité.
4. **PU-EGT-01** — cartes de session en hexadécimal, « Pas encore de description » : 3 profils.
5. **PU-EGT-55** — « Confirmez-la dans le terminal » affiché sans bandeau : 3 profils.

À égalité, à 3 profils : PU-EGT-05, 06, 07, 10, 35 et 74.

## Désaccords entre juges, tels quels

- **Cohabitation à 1440** :
  - N : « Les trois tiroirs ouverts ensemble à 1440 sans se chevaucher » (dans ce qui l'a aidé).
  - D : « le tiroir Git recouvre les cartes au lieu de décaler la carte ».
- **Commande brute dans le bandeau** :
  - D : « Bandeau de proposition qui affiche la commande `claude …` en entier, avec 4 modes lisibles » (aidé).
  - R : « la commande brute me fait peur au moment même où je dois décider ».
  - N : « la ligne de commande brute fait peur ».
- **Double geste « Lancer » puis Entrée** :
  - D : « la ligne est écrite mais pas exécutée, c'est moi qui fais Entrée » (aidé).
  - R : « le bandeau exige une confirmation… "Annuler" n'a rien lancé » (aidé).
  - N : « "Lancer" qui ne lance pas trahit la promesse ».
- **Jargon Git** :
  - R et N demandent de renommer « Worktrees » et « HEAD détaché ».
  - D s'appuie sur ces mêmes cartes (« HEAD détaché · propre · ↑0 ↓5 ») comme sur ce qui l'aide le plus.
- **Reconnexion du terminal** :
  - C : « La reconnexion après rechargement garde l'historique du terminal ».
  - D : « le shell survit mais l'écran repart vide, j'ai perdu la sortie du claude lancé ».
  - N : « le terminal était vierge au retour ».
- **Fiabilité de Git** :
  - D : indisponible « à chaque premier chargement (reproduit 4 fois) ».
  - N : « À 390 et à 1024, Git s'est chargé correctement ».
- **Échap sur Au travail** :
  - R : « Échap ne ferme pas le tiroir » (1280 sombre).
  - C : il le ferme, mais remonte aussi le canevas d'un niveau (1440 clair), et ne le ferme pas depuis
    l'en-tête à 768.

## Ce qui n'a pas pu être jugé

- **Orphelins et « bloqué » dans Au travail.** Le collecteur en sort deux, mais le tiroir les écarte (voir
  PU-EGT-33). Aucun juge n'a donc vu d'orphelin. Quant à l'état `bloque`, aucune source de la collecte ne
  le produit : le vocabulaire existe dans le rendu, pas dans les données. Le seul signal de blocage visible
  a été « sans nouvelle depuis … ».
- **« Terminal indisponible : Python 3 est introuvable »** : pas reproductible sans retirer `/usr/bin` du
  `PATH`. L'état « serveur arrêté » a été vu par D ; « Session expirée » par R.
- **Presse-papiers réel** : les Chromium sans affichage le refusent. Seul le repli « Copie impossible,
  commande sélectionnée » a été vu.
- **Infobulles natives** (`title`) : invisibles en capture sans affichage.
- **Vrai lecteur d'écran** (VoiceOver), Safari, Firefox : le juge clavier n'a jugé que les noms, rôles et
  régions exposés.
- **Vrai `claude`** : faux binaire, donc pas de sous-agents réels sous une session lancée depuis une carte.
- **Combinaisons non couvertes** : 768 clair et 1280 clair terminal ouvert chez D ; sombre hors 1280 chez R ;
  bandeau à 390 chez N.
- **Hors surface** : l'onglet Code et le chat. Les quelques remarques sur Projet (PU-EGT-25 à 27, 81) sont
  gardées pour l'autre panel.
