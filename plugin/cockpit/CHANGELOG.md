# Changelog — cockpit

## Non publié

Retours du panel d'utilisateurs du cockpit (2026-11-06, registre `.planning/missions/2026-11-06-panel-utilisateurs-GLOBAL.md`, PU-G-001 à PU-G-204) : correctifs et réglages, aucune capacité nouvelle, aucun bump de version à ce stade. Réponses de Samuel aux 14 questions du registre, formulaire unique : arbitrage Samuel, AskUserQuestion session principale, 2026-11-06. Libellés choisis : Q1 « Icônes dans le menu ⋯ », Q3 « Termes Git + définition », Q4 « Préparer, puis Entrée », Q5 « Non, annoncé seulement », Q6 « Tout visible, expliqué », Q7 « Oui, 120 s visibles », Q8 « Non, Projet et Code », Q9 « Règle actuelle », Q10 « Flou gardé, texte court », Q11 « Inchangés » (et PU-G-045 « Fermer sous 1000 px », même jour), Q12 « Un seul latéral sous 1280 px » puis « Non, lecture étroite », Q13 « Inchangé, mieux dit », Q14 « Oui pour ces trois ». Même canal et même jour : PU-G-162 « Branche + ton nom /rename », DG-09 « Non, garder l'exclusion », PU-G-026 « Projet sans plancher », PU-G-001 « Garder ce compromis », PU-G-086 « Rien ne change », focus sur « Annuler » « Garder l'exception », Entrée tenue « Corriger maintenant », masque des secrets « Corriger maintenant ». Même canal, 2026-11-07 : Entrée tenue « Étendre à tous ».

### Ajouté
- **Carte lisible à l'ouverture (onglet Code)** : zoom initial plancher, liaisons discrètes au repos, molette et toucher réglés pour la carte (PU-G-026 sur Code seulement, Projet sans plancher).
- **Infobulle, description et chemins** : l'infobulle se range quand la carte se décale, la description d'un module tient sur trois lignes avec « Lire la suite » / « Réduire », les chemins se coupent après les « / » (Q10 « Flou gardé, texte court »).
- **Recherche** : focus posé, croix tactile, dossier parent sous le nom des homonymes.
- **Fenêtre d'export au clavier, état réel des nœuds, anneau de focus de l'en-tête** à toutes les largeurs ; halo de la carte remplacé par un contour de 2 px.
- **Bouton de copie de la commande de relance du cockpit** (`/vf-cockpit build`, Q14) : jamais un lancement ; le passage « pas de repli copier la commande » du README nomme cette exception.
- **Panneau de détail fermé par défaut sous 1 000 px** (PU-G-045) ; **onglet Équipe sur une colonne à 390 px** (PU-G-176, limité à l'onglet Équipe).
- **Bouton de thème avec son état** (mot du thème quand la place le permet, `aria-label` et `title` toujours) ; **visite cadrée**, en feuille au téléphone, avec une seule touche Échap pour la fermer (DG-05) ; la feuille de visite laisse libre la pastille Terminal.
- **Santé** : compte exact, clés factices signalées comme telles, fichiers tiers écartés des conseils « découper » et « supprimer », services cités seulement s'ils sont utilisés ; suite neuve `test-cockpit-sante.sh`.
- **Onglet Projet : états et exigences** (PU-G-093, 097, 098, 099) : « Maintenant », la visite et le sous-titre suivent l'état de la carte ; « STATE.md semble périmé : il dit « … » » quand `STATE.md` diverge ; « N exigences non cochées » ; « Reste : cadrage, plan, exécution, … » ; « Hors jalon ».
- **Panneau Format de la planification** (PU-G-151 à 160) : « Copier » copie exactement la commande, commande de correctif complète avec chemins absolus (témoins espace et apostrophe) ; « Détails techniques » repliés (PU-G-104, repli seulement).
- **Chat** (PU-G-096, 147, 150) : réponses non coupées en plein mot ; une expression régulière quadratique rendue linéaire (témoin).
- **Lancer et bandeau** (PU-G-110 à 141) : remontée sous le titre, « Chargement des actions… », « Préparée depuis la carte. » à la place de « Lancée » sans signal, message d'envoi borné à 120 s, expiration identique dans la page et dans le terminal, cartes d'état, « Copier la commande » (un seul `execCommand('copy')`, PU-G-141).
- **Bouton « Préparer dans le terminal »** posé après la commande exacte, la case du chat et les modes ; la carte d'état n'est jamais masquée par une proposition.
- **Terminal : taille renvoyée au PTY à la reconnexion** (DG-08), accueil qui se range à la première frappe.
- **Onglet Équipe, lot 9 « Au travail » et « Qui a la main »** (PU-G-134, 163 à 190) : « Aucune commande récente » sans saut, regroupement « × n » des répétitions de commandes, glyphe et mot neutres pour l'état (Q9 A), seuil de commande longue à 15 min, titre de session (/rename), « orphelin ? » et « aucune session active » ; nouveau fichier `ui/73-vf-tiroir-travail.js`. La commande reste abrégée et masquée (Q13 A).
- **Onglet Équipe, lot 10 « tiroir Git »** (PU-G-042, 166, 192 à 201) : étiquette complète au survol et au focus, états sans couleur (Q9 A), termes Git avec leur définition au survol et au focus (Q3 A) ; le chemin vient après le nom.
- **Coque étroite** (Q1 « Icônes dans le menu ⋯ », PU-G-001, 002, 007, 008, 011, 012, 142) : menu « ⋯ » jusqu'à 999 px, qui amende P70-D-01 ; PU-G-001 : « Garder ce compromis ».
- **Un seul tiroir latéral sous 1 280 px** (Q12 « Un seul latéral sous 1280 px », PU-G-203) : ouvrir le tiroir Git replie « Au travail », et inversement, le focus va au tiroir qui s'ouvre ; « Non, lecture étroite » (seul le contenu « Au travail » compte) ; l'option « le tiroir pousse la carte » est écartée (PU-G-204). Preuve : `test-cockpit-equipe.sh` (EK16).
- **Titre de session `custom-title`** (PU-G-162 « Branche + ton nom /rename ») : la liste blanche du transcript, fermée par P69-D-19 et P69-D-23, est amendée pour ce seul champ ; `ai-title` reste refusé.
- **Suites neuves** : `test-cockpit-sante.sh`, `test-cockpit-ecrans-recent.sh`, `test-cockpit-moteur-carte.sh`, `test-cockpit-visite-retours.sh`.
- **Tiroir terminal rouvert à 300 px au moins sur une proposition** (PU-G-136) : une proposition qui arrive sur un tiroir plus bas le remonte à 300 px, sans écraser la hauteur choisie par l'utilisateur, jamais en plein écran (3ee4c300).
- **Pied du panneau Santé en français** (PU-G-080) : « elle vérifie le code avant de rien modifier » et « elle explique le choix et met le plan à jour une fois que vous avez décidé ».
- **« Clic droit : plus d'actions »** (PU-G-036) : le deux-points est posé dans les infobulles de carte, de connexion et dans le pied d'aide (6b3d90ee).
- **Libellé « Utilisé par »** (PU-G-100) : sur l'onglet Projet, le panneau d'une phase et les titres de colonnes lisent « Dépend de » / « Utilisé par » dans le bon sens ; le lien et l'ordre des cartes ne changent pas (6b3d90ee). Le panneau d'un fichier-plan et l'infobulle d'arête restent à l'ancien sens (BACKLOG).

### Corrigé
- **Écran fantôme** (DG-02) : `findScreens` lisait `createFileRoute` dans un commentaire ; à 0 écran, le bouton « Écrans » n'est plus posé.
- **Compteurs de Travail récent alignés** (DG-03) : le badge comptait des entrées et non des cartes ; « 24 sur 41 cartes ».
- **Vue de réponse remise à zéro** (DG-04) : `go()` emportait `q:answer`, l'état de réponse périmé.
- **Colonne des cartes sans lien** (DG-12) : `separateConnectedComponents` isolait une carte sans lien.
- **Exigences lues deux fois** (DG-10) : compartiment et archive, 184 doublons ; compteurs 627/660 devenus 444/476.
- **Proposition gardée 120 s** (DG-07) : elle l'était depuis sa création, toutes visites confondues.
- **Bloc « Santé » masqué sur l'onglet Projet** (DG-15) : il ne lit que le code, pas la planification. Changement visible.
- **Git indisponible** (DG-01, PU-G-191, PU-G-003) : `/api/vf/git` lançait douze à treize commandes git en série sous une seule échéance de 5 s ; l'échéance passe à 15 s, une seule lecture à la fois (REG-D-01, décision de manager, qui étend P78-D-41 ; pas un arbitrage humain). Un git muet est dit `indisponible`, jamais `absent` ; le tiroir relance une fois seul et donne une raison en clair ; l'en-tête garde la dernière branche, marquée « non confirmée ».
- **Orphelins et durée « tenu depuis »** (DG-06, PU-G-179, PU-G-182) : `who.mjs` écartait les orphelins (`stale` valait toujours `orphan`) et la durée lisait `age_seconds` au lieu de `lease_seconds`.
- **Masque des secrets** : un secret collé à un mot (`xxxghp_…`, `key_sk-…`) est désormais masqué (3ca3cd91, témoin W24 de `test-cockpit-who.sh`) ; antérieur à la mission, il touchait tous les appelants.
- **Retenue de l'Entrée tenue** : une Entrée maintenue n'exécute plus la ligne qui vient d'être écrite au retour du focus du terminal ; la retenue se pose sur toute prise de focus (Préparer, Annuler, Abandonner, Coller, Relancer le shell, pastille du tiroir, retour d'onglet). Sécurité du double geste. Le focus sur « Annuler » du collage est gardé.
- **Libellés français** : Non classés, Demande d'origine, récent, liens, Module ; résumés sans « > » ni HTML, marqués « extrait brut ».

### Modifié
- **`test-cockpit-projet.sh` découpée en trois suites** (arbitrage Samuel, AskUserQuestion session principale, 2026-11-07 : « Oui, découper projet ») pour tenir la durée d'un job de CI (la suite seule dépassait 16 à 25 min) : `test-cockpit-projet-graphe.sh` (moteur, parseurs, P1 à P9, P10.1, P10.2, P10.4, P10.5), `test-cockpit-projet-visite.sh` (le bloc Chrome : O4, O5, O6.5 à O6.19, R3.13 à R3.22 ; « SUITE SAUTÉE » sans navigateur) et `test-cockpit-projet-croissance.sh` (P10.3, le mutant le plus long). Socle commun sourcé `projet-commun.sh` (hors du motif `test-*.sh`) et harnais de croissance en un seul fichier versionné `projet-croissance.mjs` ; même nombre d'assertions et mêmes neuf mutants qu'avant, répartis.
- **Aides « mesurer une fois posé » des sondes Chrome** (`stabiliser`, `attendreValeur`, `attendreEtStabiliser`, `positionPosee` dans `chrome-session.mjs`) et suite neuve `test-cockpit-sondes-stables.sh` qui les éprouve (partie pure, partie Chrome, mutants) : les lectures des suites Chrome se prennent une fois la valeur posée, jamais après une pause fixe.
- **Q1 « Icônes dans le menu ⋯ »** : le menu « ⋯ » monte de 700 à 999 px (amende P70-D-01).
- **Limites consignées au BACKLOG** : états « annulée/expirée/remplacée » du lancement, état « bloqué » sans source, titres de santé à variables, 40-tour.js à 298 lignes (seuil 300) — voir `.planning/BACKLOG.md`.

## v1.4.0 — 2026-11-06 — non publié

Phase 78 « Git dans le cockpit » (jalon vibeflow-v2.0, compartiment fiabilité) : nouvelle capacité, version mineure. Arbitrages de Samuel : P78-D-01 à P78-D-10 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 ; P78-D-10 au second tour, même canal et même date), P78-D-20, P78-D-21 et P78-D-25 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05, troisième tour) ; puis P78-D-34 (ratification), P78-D-36, P78-D-37 et P78-D-39 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-06 : « Valider le seuil (Recommandé) », « Garder le plafond (Recommandé) », « Garder tel quel (Recommandé) », « Recherche à 152 px (Recommandé) »). Les décisions techniques du manager portent leur propre préfixe.

### Ajouté
- **En-tête Git** (P78-D-01, P78-D-02, P78-D-03) : le titre est le nom du dossier du dépôt principal sur Code, Projet et Équipe (dans un worktree, « vibeflow-os », pas « phase-78 ») ; une seconde ligne dit la branche et, hors de l'arbre principal, le worktree ; le bloc de vue dit ce que montre la vue au lieu de répéter le nom du projet. Branche détachée en texte neutre (P78-D-35, jetons figés de la 71.5 : arbitrage Samuel, AskUserQuestion session principale, 2026-11-05).
- **Tiroir Git en lecture seule** (P78-D-04, P78-D-05, P78-D-06, P78-D-10) : tiroir vertical à gauche, ouvert au clic sur la seconde ligne et par la touche `g` ; graphe en couloirs des branches locales, des branches distantes déjà connues et des worktrees (jamais de `fetch`), détail d'un commit sans diff, état de chaque worktree, tags, stash, auteurs et activité ; commandes exactes à copier (P78-D-07, P78-D-14), jamais exécutées par le cockpit. Ouvreur : seconde ligne, icône de 44 px de 701 à 1279 px (P78-D-20, P78-D-34), entrée « Historique Git » du menu « ⋯ » sous 700 px (P78-D-30).
- **Routes GET** (P78-D-13) : `/api/vf/git`, `/api/vf/git/entete`, `/api/vf/git/commit?sha=`, `/api/vf/git/worktrees`, derrière les contrôles Host, Origin et jeton existants ; aucune route non GET ajoutée par la phase (405 sinon). Schémas `vibeflow/cockpit-git@1`, `-entete@1`, `-commit@1`, `-worktrees@1` dans `vf-cockpit-interface.json`.
- **Signal** (P78-D-15, P78-D-23) : événement `git` sur le flux en direct, calculé dans le filet de 5 s sur une signature bon marché (refs, worktrees, index) ; le tiroir ouvert relit une fois par rafale, sans polling.
- **Lecture des worktrees non bloquante** (P78-D-32 : décision du manager de reprise, 2026-11-06) : `GET /api/vf/git/worktrees` passe en asynchrone, le flux SSE et le terminal ne gèlent plus (~1,2 s synchrones mesurées sur ce dépôt).
- **Pastilles d'état des worktrees en texte neutre** (P78-D-33) : glyphe et mot, sans fond teinté ni couleur d'état (jetons figés de la 71.5, arbitrage Samuel, AskUserQuestion session principale, 2026-11-05).
- **Seconde ligne masquée sous 1280 px** (P78-D-34) : sur la délégation de P78-D-19 (« sauf avis contraire du juge de design »), la critique du 2026-11-06 la mesure illisible de 1000 à 1279 px ; l'icône de 44 px la remplace de 701 à 1279 px. Seuil ratifié par Samuel (« Valider le seuil (Recommandé) », arbitrage Samuel, AskUserQuestion session principale, 2026-11-06), sans retour en arrière.
- **Lecture du graphe et détail d'un commit non bloquants** (P78-D-41, étend P78-D-32 : décision du manager de reprise, 2026-11-06) : `GET /api/vf/git` et `GET /api/vf/git/commit` passent en asynchrone (362 ms de boucle gelée mesurés sur ce dépôt, jusqu'à 5 s sur un git muet).
- **Seconde ligne plafonnée à 220 px** (P78-D-36, arbitrage Samuel, AskUserQuestion session principale, 2026-11-06) : le texte complet reste dans l'infobulle, le titre de l'onglet Code et le tiroir. **« g » découvert au survol ou au focus** (P78-D-37, arbitrage Samuel, AskUserQuestion session principale, 2026-11-06) : ligne sobre au repos.
- **Plancher de la recherche à 152 px** (P78-D-39, amende P70-D-16 : arbitrage Samuel, AskUserQuestion session principale, 2026-11-06) : de 1000 à 1279 px et seulement avec Git, texte d'invite plus court ; 200 px partout ailleurs et sans Git.
- **Libellé « Par branche — avance sur la base »** (P78-D-40 : décision du manager de reprise, 2026-11-06) : plus de fenêtre de 30 jours, la section montre la date de la pointe et l'avance sur la base.
- **Correctifs de la revue de delta et de la recette du 2026-11-06** : `avance` inconnu (null) s'affiche « — » avec le libellé « avance inconnue », jamais « 0 commit » (ni « ↑0 » sur un worktree) ; `GET /api/vf/git/entete` et la lecture de la branche de base des worktrees passent en asynchrone (aucune route du tiroir Git ne lance de git synchrone, P78-D-41 étendue à l'en-tête et à la base ; le filet de 5 s, `whoNow` et le signal, garde ses lectures existantes) ; l'export `ILLISIBLE` n'a plus de drapeau `g` (plus d'alternance de `.test`) ; l'en-tête relit la branche réelle une fois au chargement de chaque onglet et le bloc de vue Code la cite (P78-D-43 ; plus de branche périmée après un `git switch`) ; écart visible autour du point médian de la seconde ligne ; barres d'activité des auteurs en texte neutre ; contrastes d'au moins 4,5:1 (« Aucune commande proposée », pilules, touche « g ») ; une seule région vive dans le tiroir et coche le temps du « Copiée ».
- **Dépôt sans branche de base** (P78-D-42, précise P78-D-11 et P78-D-23) : sans `main` ni `origin/HEAD`, le graphe est rendu sans comptes d'avance, au lieu de « indisponible ».
- **Suites** : `test-cockpit-git-e2e.sh` (serveur réel, page en Chrome CDP : B1 à B5, mutants de jonction M-ROUTE, M-SIGNAL, M-OUVREUR, captures pour le juge de design), volet git C0g à C4g de `test-cockpit-chaine-xss.sh`.

### Sécurité
- **Environnement git unique** (P78-D-21, P78-D-22, P78-D-25) : tous les appels git du socle passent par `envGit` / `shBorne` : variables `GIT_*` héritées retirées, `core.fsmonitor=false`, `GIT_OPTIONAL_LOCKS=0`, `--no-ext-diff --no-textconv --no-show-signature`, aucun filtre déclaré par le dépôt exécuté (la mention « approximatif : filtres du dépôt non exécutés » le dit). Corrige la faille préexistante de `vf-cockpit-who.mjs` (`status --porcelain` qui exécutait un filtre du dépôt) et étend la protection à `vf-cockpit-arbres.mjs`, `vf-cockpit-planning.mjs` et `vf-cockpit-paths.mjs` (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05, « Corriger avant la release »).
- **Moteur vendorisé fermé par défaut** (P78-D-25) : patch P27 de `scripts/lib/common.mjs` : `git()` ne lit rien sans `VF_COCKPIT_GIT_DURCI=1`. Un moteur lancé à la main hors de l'assemblage n'a donc plus de liste git (documenté au README).
- **Commandes à copier** (P78-D-14, P78-D-27, P78-D-29) : un nom de branche hostile ne produit jamais une commande qui fait autre chose que celle affichée ; aucune commande si le nom est masqué, ni pour `-` et `@`.
- **Chaîne XSS étendue aux données git** (P78-D-17) : un nom de branche, un message de commit, un auteur ou un stash hostiles n'aboutissent à rien ; chaque maillon (rendu en `textContent`, CSP, garde du moteur) casse la chaîne seul.

- **Worktree « non vérifié »** (P78-D-38 : décision du manager de reprise, 2026-11-06) : un worktree dont le lien retour n'est pas celui du dépôt lu n'est jamais lu (`status` non lancé) ; champ `verifie` ajouté aux entrées de `/api/vf/git` et `/api/vf/git/worktrees`, comptes et commande `cd` à `null`.
- **Durcissements de l'audit en lecture du 2026-11-06 (A1 à A8)** :
  - A1 : plus de troncature de la liste des filtres déclarés ; au-delà de 256 filtres, ou liste illisible, `status`, `diff`, `ls-files` et `stash` ne sont pas lancés (refus fail-closed, comptes « inconnus »).
  - A2 : `--ignore-submodules=all` sur tout `status` et tout `diff` (l'état modifié d'un sous-module n'est plus compté).
  - A3 : vérification du lien retour de chaque worktree avant lecture (P78-D-38).
  - A4 : `detailCommit` asynchrone, échéance globale de 8 s, sortie bornée à 16 Mio, détection de renommages bornée ; un délai rend `indisponible`, jamais « commit-inconnu ».
  - A5 : `signatureGit` asynchrone, échéance de tick de 2 s, jamais deux ticks en vol, retrait après un git muet.
  - A6 : `--` ajouté à toutes les lectures qui passent une révision.
  - A7 : garde E6 de `test-cockpit-git-env.sh` en liste blanche des importeurs de `child_process`, balayage récursif de `plugin/cockpit/`.
  - A8 : `\p{Cf}` neutralise les caractères de formatage invisibles (U+200B, bidi, U+FEFF, U+00AD, etc.) dans les noms affichés ; les noms accentués gardent leur commande.
  - Revue de delta (2026-11-06) : **fermeture du moteur** : quand la liste des filtres déclarés est illisible ou dépasse 256 filtres, le moteur vendorisé est lancé sans `VF_COCKPIT_GIT_DURCI` (donc sans git), le résumé de l'assemblage dit « git du moteur fermé (cause) » et l'assemblage rend le champ `gitFerme` ; **contrat `worktrees` nullable** : `modifies`, `nonSuivis`, `propre`, `avance`, `retard`, `avanceOrigin`, `retardOrigin` et `commande` valent `null` quand la valeur est inconnue (worktree non vérifié, lecture en échec), et la page les affiche comme inconnus, jamais « 0 » ; **classe `\p{Cf}` étendue à la carte Équipe** (libellés de mission) : mêmes points de code refusés que les noms de branche, sans espace laissé (parité testée sur U+0000 à U+10FFFF).

### Modifié
- **Attribution des sous-agents au worktree** (P78-D-26 : décision d'ordonnancement de la session principale, 2026-11-05) : `byActivity` de `vf-cockpit-who.mjs` retient le dernier worktree cité sur l'ensemble des appels de l'agent, au lieu de la seule dernière ligne du transcript.
- **Retiré** (P78-D-09) : la liste « Repositories » de l'onglet Code et les suffixes « — Projet » / « — Équipe » du titre.

Phase 72 : lancer du travail depuis les cartes du cockpit (jalon vibeflow-v2.0, compartiment fiabilité), avec `--terminal` seulement. Un clic sur une carte propose, le terminal dispose : rien ne s'exécute sans un geste dans le terminal. Numéro de version recalculé à la fusion (P71-PL-12) : mineure suivante de la v1.3.3 de `origin/main`. Les gestes de release racine (version, tag, release GitHub) restent humains.

Décisions : arbitrage Samuel, AskUserQuestion session principale Claude Code, 2026-11-05, pour P72-D-01 à P72-D-07 (Q2, mode de permission, réponse libre mot pour mot : « choix + hérité don bypass ») ; décisions d'ordonnancement de la session principale pour P72-D-08 ; décisions du manager (vf-dev-manager, 2026-11-05) pour P72-D-09 à P72-D-19 ; arbitrage Samuel, AskUserQuestion session principale Claude Code, 2026-11-06, pour P72-D-20 (« Fichier du lab (Recommandé) »), P72-D-21 (« Geste humain exigé (Recommandé) ») et P72-D-22 (« Garder, risque écrit (Recommandé) »).

### Ajouté — Lancer du travail depuis les cartes (Phase 72)
- **Cartes** (LANC-01, LANC-02) : action principale selon l'état de la phase et menu des autres verbes sur les cartes de phase et de mission. Sans `--terminal` : aucun bouton, aucune route `POST`, aucun script ajouté, politique de contenu identique (P72-D-17).
- **Route et canal** (LANC-03, LANC-04) : `POST /api/vf/lancer` (`Host`, `Origin` exacte, jeton en temps constant, JSON borné, schéma fermé) ; proposition transmise par l'IPC du serveur au processus du terminal ; liste des cibles calculée par le serveur depuis le disque.
- **Gabarit et double geste** (LANC-05 à LANC-07) : ligne fermée `claude --session-id '<uuid>' -n '<nom>' [--permission-mode '<mode>'] '/vf-dev <intention>'`, alphabet revalidé par l'assistant PTY ; bouton armé après 1 s ; ligne écrite sans retour chariot, terminal au repos seulement ; refus `ecriture` (410) quand la ligne n'a pas pu être écrite.
- **Pré-vols** (LANC-08) : bloquants et avertissements de P72-D-06 ; emplacement « travail non commité » inactif (P72-D-07, Phase 78).
- **Mode de permission** (LANC-09) : `default`, `acceptEdits`, `plan` et « hérité du poste » (aucun drapeau) ; le dernier mode choisi est présélectionné, gardé dans un fichier du lab tenu par le processus du terminal (P72-D-02bis, P72-D-20).
- **Suivi** (LANC-10) : identifiant de session généré, carte « lancée » rattachée à l'onglet Équipe.
- **Continuer le chat** (LANC-11) : case décochée par défaut, reprise par `claude -r '<uuid>' --fork-session` ; sonde A5 verte sur Claude Code 2.1.318 ; geste humain exigé pour retenir l'identifiant (P72-D-21) ; résiduel d'un script de la page Projet accepté et écrit au README (P72-D-22).
- **Suites** (LANC-12) : `test-cockpit-lancer-gabarit.sh`, `-cibles.sh`, `-post.sh`, `-q.sh`, `-ui.sh`, `-suivi.sh`, `-bandeau.sh`, `-serveur.sh`, `-processus.sh`, `-pty.sh`, `-xss.sh`, `-bout-en-bout.sh`, `-chat.sh`, `-mode.sh`.

Parseurs tolérants du planning et diagnostic des lignes non comprises (constat du lab portfolio, 2026-11-05 : « **Depends on :** Phase 02 (…) » ne donnait aucun lien dans le graphe Projet). Arbitrage : Samuel, AskUserQuestion en session principale, 2026-11-05 — hotfix et chantier de fond traités ensemble, release minor.

### Corrigé — dépendances (hotfix)
- `**Depends on :**` (espace, U+00A0 ou U+202F avant « : »), deux-points dans le gras ou dehors, gras ou non, puce « - », casse, `Dépend de` / `Dépendance(s)` / `Dependency` / `Dependencies` / `Depends` : lus. Les coupures existantes (« · », champ gras suivant, « La Phase 68 en dépend ») sont intactes. Valeur portée par les puces qui suivent : lue.

### Ajouté — normalisation partagée (`vf-cockpit-formats.mjs`, module pur)
- Une grammaire commune à la lecture (`vf-cockpit-planning.mjs`) et au diagnostic (`vf-cockpit-drift.mjs`) : titres de phase (`##`, `###`, `####`, `Phase N:`, `Phase N :`, `Phase N —`, 01 = 1, décimales, gras autour du titre), cases `[ ]` `[x]` `[X]` avec puces `-` `*` `+`, `Goal` / `Objectif` / `Objective`, exigences `**REQ-01**:` `**REQ-01:**` `REQ-01:`, statut STATE normalisé (« In Progress » → `in_progress`), `current_phase` entre guillemets ou « Phase 2 », CRLF et BOM.
- La case « - [x] Phase 3 - Trois » ou « **Phase 2 — Deux** » (tiret au lieu des deux-points) est lue, état coché compris (arbitrage Samuel, AskUserQuestion session principale, 2026-11-06).
- **Limite assumée** : la tolérance des titres est large (`##` à `####`, tiret) ; un intertitre de prose « ### Phase N — … » est donc lu comme une phase (arbitrage Samuel, AskUserQuestion session principale, 2026-11-06).
- Un nom de case vide reste vide (« - [ ] Phase 1: » puis « - [ ] Phase 2: B » donnent deux phases) ; BACKLOG.md, seeds et plans en CRLF/BOM sont lus comme en LF ; `## Phase N: …` posé sur la dernière ligne d'un ROADMAP sans saut de ligne final est désormais lu (changement voulu, auparavant ignoré).
- Coût linéaire : toutes les regex lues sur le planning (titres, cases, dépendances, Goal, exigences, jalons, STATE, BACKLOG, objectif de plan) restent linéaires en la longueur de la ligne, y compris les suites de 100 000 caractères pathologiques (lecture et diagnostic) ; un test de croissance générique (44 formes, 21 caractères dont U+2028/U+2029, lecture, diagnostic et graphe Projet) en garde la classe. Les puces qui suivent un « Depends on » vide se lisent avec ou sans ligne vide ; une dépendance répétée ne donne qu'un lien. STATE.md en CRLF/BOM est lu comme en LF (jalons-absents).

### Ajouté — diagnostic « lignes non comprises »
- Règle `ligne-non-comprise` (niveau « ignoré », une par ligne, jamais de correctif proposé ; « Depends on Phase 3 » sans deux-points est signalée, jamais lue ; un mot-clé collé à un trait d'union comme « goal-backward » n'est pas un champ) dans `vf-cockpit-drift.mjs` : une ligne qui ressemble à un champ lu (titre de phase, Goal, Depends on, case d'exigence, `current_phase`) sans qu'aucun lecteur la reconnaisse. Prose libre, tables, plans et blocs de code ne sont jamais signalés.
- Sortie du build : « N ligne(s) non comprise(s) du planning : fichier:ligne … », au premier assemblage et à chaque `build --rebuild`. Panneau « Lignes du planning non comprises » dans l'interface (20 premières lignes, fichier:ligne sans coupure et extrait). Le cockpit n'écrit toujours rien dans `.planning/`.
- Suites : `test-cockpit-projet.sh` P8 (matrice générée de 1052 variantes, P9 corrections de revue, P10 croissance générique de 2712 cas (ratio 2N/N, lecture et diagnostic), mutants), `test-cockpit-assemblage.sh` A6.

## v1.3.4 — 2026-11-06 — non publié

Phase 71.5 : réexamen du design system du cockpit (espacements, couleurs, onglet « Au travail »). Mission de `vf-design-manager`, registre `P71.5-D-xx` dans `71.5-CONTEXT.md`. Demande d'origine : Samuel, session principale Claude Code, 2026-11-05. Les gestes de release racine (version, tag, release GitHub) restent humains : cette entrée part avec la release groupée après les Phases 72 et 78.

### Changé — grille d'espacement fermée et jetons (D-01 à D-11)
- **Échelle fermée « 8 avec demi-pas »** : 2, 4, 6, 8, 12, 16, 20, 24, 32 (`--sp-*`) et sept jetons sémantiques (`--edge`, `--inset-panel`, `--gap-section`, `--inset-card`, `--inset-box`, `--inset-row`, `--inset-pill`) ; exceptions en liste fermée. Appliquée à la coque, aux cartes du moteur, aux pages Projet et Équipe, au tiroir du terminal, à la visite guidée.
- **Valeurs tranchées** : panneaux à 20 sur leurs quatre bords (D-02), cartes à 16 avec un gap de 8 (D-03), titre de vue au bord à 16 (D-04), rail des onglets à 4 px (D-05), gouttière du graphe à 24 avec `GUTTER = 24` (D-09). Délégués à la session principale par Samuel : arbitrage Samuel, AskUserQuestion, session principale, 2026-11-05 (« choisi »).
- **Pastille « Terminal »** : elle ne recouvre plus la barre de question ni la feuille de détail (D-06, décision d'ordonnancement, pas un arbitrage). Défaut existant laissé au backlog : cartes du téléphone trop larges (D-10).

### Changé — jeu de couleurs « pastel lumineux » et règles anti-slop (D-18 à D-30)
- **Jeu de couleurs** : retour à Graphite, les palettes A2 et B2 étant rejetées (D-12) ; teintes d'état « pastel lumineux » (D-27, arbitrage Samuel, AskUserQuestion, session principale, 2026-11-05, réponse définitive « (d) Pastel lumineux ») ; jaune sombre appliqué tel que choisi, `#ffe08a` (D-30) ; `--ok` et `--recent` fusionnés (D-26). Aucun jeton supprimé ni renommé : `--ok`, `--ok-bg`, `--warn-sheet` restent des alias (D-29).
- **Anti-slop** (D-18 à D-28, mêmes canal et date) : plus de liserés ni de bordures colorés, plus de bandeau coloré du message principal ; pastille de statut sans fond (glyphe coloré, mot neutre) ; « à recetter » en glyphe et mot propres ; barres neutres sauf « en cours » ; carte bloquée en symbole et mot seuls, sans anneau ; surtitre de Projet supprimé ; corrections AA appliquées.
- **Terminal** : palette xterm sur le jeu 71.5, ANSI clair en texte lisible.

### Changé — « Au travail » en fils de liaison (D-14, D-23, D-24)
- **Tiroir refondu** : un fil relie chaque point, l'actif respire, les terminés sont regroupés et repliables, la durée figure sur la ligne de tâche, le texte complet de la tâche s'affiche au survol. Direction approuvée par Samuel (message direct, session principale, 2026-11-05) puis « Fils de liaison » (arbitrage Samuel, AskUserQuestion, session principale, 2026-11-05).

### Changé — finitions et arbitrages du 2026-11-06 (D-34 à D-36)
- **Jaune du terminal adouci, terminal seul** (D-34) : ANSI sombre `yellow` `#f0d17c`, `brightYellow` `#e3df78` ; `--sev-medium` garde `#ffe08a`. Arbitrage Samuel, AskUserQuestion, session principale, 2026-11-06 : « Adoucir le terminal seul ».
- **Points des phases grisés** (D-35) : les points des listes de phases passent à `--text-4`. Arbitrage Samuel, AskUserQuestion, session principale, 2026-11-06 : « Griser les points seuls ».
- **Conformité DESIGN.md §9** (D-36, sans arbitrage) : glyphe actif qui respire par l'échelle, plus de fils entre les terminés, bloqué jamais atténué, pastille d'état jamais soulignée, glyphe d'état à 16 px. Les points du tiroir (pastille fermée et barre : connecté, reconnexion, refusé, arrêté, expiré) n'ont plus de teinte d'état sur `--raise` en clair : variantes `--recent-text`, `--warn-text`, `--err-text` (4,3:1 au lieu de 2,9, 2,9 et 3,2:1) ; sombre inchangé, aucun jeton `:root` ajouté.
- **Juges de rendu frais** (seuil 70) : coque 85, Code 79, Projet 76, Équipe + « Au travail » 74, tiroir 84. Retour de Samuel : « Ça me convient » (AskUserQuestion, session principale, 2026-11-06).

### Suites
- `test-cockpit-terminal-tiroir.sh` : T23.1 (point de la pastille, mutant `M-POINT-RECENT`) et T23.2 (six points d'état de la barre, douze mesures, mutants `M-ETAT-RECENT` et `M-ETAT-MEDIUM`), suites du tiroir « Au travail » alignées sur le balisage en fils.
- Suivent le nouveau balisage ou les nouvelles valeurs, sans assertion affaiblie : `-terminal-page`, `-equipe`, `-avancement`, `-responsive`, `-securite`, `-who`, `-direct`, `-ailleurs`, `-transcript`, `-chrome-fr`, `chrome-verrou*.mjs` et trois tests `signal/tests/`.
- Le moteur vendorisé change par ses patchs (`amont/patches/`), pas par une édition du vendor.

## v1.3.3 — 2026-11-05 — non publié

Réglage visuel (demande de Samuel, session principale, 2026-11-05) : tiroir fermé, la pastille « Terminal » se place sous les boutons de zoom (− ▢ +), au plus bas à gauche, et les boutons de zoom remontent au-dessus d'elle ; plus de chevauchement. Tiroir ouvert, rien ne change. Vaut pour les pages Projet et Code.
- **Placement** : `vf-cockpit-terminal-tiroir.mjs` ne remonte plus la pastille ; si elle recouvre `#zoom`, c'est `#zoom` qui reçoit un `bottom` en ligne juste au-dessus d'elle (retiré à l'ouverture du tiroir, à chaque recalcul). La puce « Terminal indisponible » garde l'ancienne règle.
- **Suite** : `test-cockpit-terminal-tiroir.sh` (T21.1) exige désormais, quand la pastille et le zoom se partagent la même colonne, la pastille sous le zoom, en plus du non-chevauchement ; le mutant `M-PASTILLE-SUR-ZOOM` vise la nouvelle ligne.

## v1.3.2 — 2026-11-05 — non publié

Correctif hors phase (jalon vibeflow-v2.0, compartiment fiabilité) : le terminal intégré fonctionne sous Safari. Arbitrages : arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 (SAF-1 « connexion dans le cadre », SAF-2 « les deux preuves »).

### Corrigé — « Session expirée » sous Safari (SAF-1)
- **Cause** : Safari découpe le `localStorage` d'un cadre par origine de premier niveau, port compris (Chrome et Firefox par site, port ignoré). Le terminal échangeait l'amorçage au premier niveau et y rangeait le secret ; le cadre du terminal sous la page Projet (autre port) lisait un stockage vide.
- **L'échange se fait dans le cadre** : la page de redirection du lanceur mène à `http://127.0.0.1:<port>/project.html#t=<amorçage>`. La page Projet lit le fragment avant tout autre traitement, l'efface, n'en retient que le format exact (64 chiffres hexadécimaux), monte le cadre du terminal au chargement (tiroir fermé) avec l'amorçage dans le fragment de son adresse (jamais dans un attribut `src`). Le cadre efface son fragment, fait `POST /amorce`, range le secret dans son stockage et se recharge sans fragment ; il ne navigue plus vers la page Projet. Le shell ne démarre qu'à l'ouverture du tiroir (le cadre attend une taille non nulle).
- **Renforcé** : une adresse du terminal ouverte seule avec un amorçage n'échange plus rien (« Terminal indisponible »). Propriétés inchangées : pas de cookie, secret jamais dans une adresse ni lisible par la page Projet, usage unique, 60 s, `Origin` exacte.
- **Limites écrites au README** : le script de la page Projet voit passer l'amorçage (jamais le secret) moins de 60 s ; sous Safari le stockage du cadre est effacé à la fermeture du navigateur (relancer `/vf-cockpit --terminal`).
- **Suites** : `test-cockpit-terminal-lanceur.sh` (L6, L12b, L12c, L15, M-OUVRE-Q), `-client.sh` (T6.1, T6.1b, T6.1c, T6.3, T6.9, mutants M-STOCKAGE, M-PREMIER-NIVEAU, M-SANS-AMORCE), `-tiroir.sh` et `-xterm.sh` (amorçage par la page Projet) jouent le nouveau contrat.

## v1.3.1 — 2026-11-05 — non publié

Correctif hors phase (jalon vibeflow-v2.0, compartiment fiabilité) : le terminal intégré ne laisse plus de survivants quand son assistant PTY plante.

### Corrigé — survivants après le plantage de l'assistant PTY
- **Un gardien ramasse la session** : si l'assistant `vf-cockpit-pty.py` meurt sans passer par `arreter()` (SIGKILL, SIGSEGV, exception Python non rattrapée), les travaux qui ignorent le SIGHUP du noyau (`nohup … & disown`, `(trap '' HUP; exec sleep) &`) restaient rattachés à `ppid=1`. Un petit processus gardien, forké avant le pseudo-terminal (il ne détient jamais le maître), sorti de la session par `setsid`, détecte la fin du tube sans le mot `OK` de l'arrêt propre, puis rejoue SIGHUP, la grâce de 3 s et le SIGKILL répété sur les membres de la session (getsid relu avant chaque envoi). Il sort dès que la session est vide. Limites écrites dans l'en-tête du module : un gardien tué lui-même laisse les survivants, un processus sorti de la session par `setsid` y échappe.
- **Suite `test-cockpit-terminal-pty-plantage.sh`** : T12.8a (SIGKILL) et T12.8b (exception injectée dans une copie) au vert, témoins T12.8c sains, deux mutants (`M-GARDIEN-ABSENT`, `M-GARDIEN-SANS-SID`) qui rougissent T12.8a avec les survivants `nohup` et `trap`. Aucun changement de comportement hors de ce ramassage.

## v1.3.0 — 2026-11-04 — non publié

Phase 71 : terminal intégré. Décisions : arbitrages Samuel, AskUserQuestion session principale Claude Code, 2026-11-03,
pour P71-D-01 à P71-D-08 et P71-D-23 ; décisions du manager (vf-dev-manager, 2026-11-03) pour P71-D-09 à P71-D-22 et P71-D-24
(O1 à O11 tranchées par P71-D-20 et P71-D-21 ; P71-D-22, d'abord provisoire, est devenue définitive par P71-D-23). Les gestes de
release racine (version, tag, release GitHub) restent humains. Numéro de version recalculé à la fusion avec les Phases 68 et 70 (P71-PL-12) : mineure suivante de la v1.2.1 de main.

### Corrigé — recette par juges, lots W1 à W4, et rebase sur H-1
Arbitrages de Samuel, AskUserQuestion session principale Claude Code, 2026-11-04 : P71-D-33 (« Terminal dans son processus (Recommandé) »), P71-D-34 (« Corriger E2 à E5 (Recommandé) »), P71-D-35 (« G1 tiroir et cadrage, G2 arrêt immédiat, G3 défilement discret »).
- **Le serveur du terminal tourne dans son propre processus** (E1, P71-D-33) : un travail synchrone du serveur (le calcul de qui travaille sur le lab) gelait les frappes ; Q est désormais un enfant (`child_process.fork`, `vf-cockpit-terminal-processus.mjs`), l'interface exportée par `vf-cockpit-terminal.mjs` et le patch `P26` de `serve.mjs` sont inchangés. Si le serveur du cockpit meurt, même par SIGKILL, l'enfant, l'assistant et le shell s'arrêtent avec lui.
- **Arrêt volontaire dit, Python 3 absent dit** (G2, E4, P71-D-34 et D-35) : `GET /etat` rend `{"etat":"arret"}` pendant environ 2,5 s après un arrêt volontaire et `{"etat":"indisponible","raison":"python3-absent"}` sans `python3` (autres routes 503, une ligne dans `serveur.log`). La page affiche « Serveur arrêté » aussitôt, ou une carte « Terminal indisponible » avec la marche à suivre, sans boucle de reconnexion ; une coupure inattendue garde la reconnexion pendant 30 s.
- **Lanceur** (E4, E5) : sans `python3`, `--terminal` le dit et le cockpit s'ouvre sans terminal (code 0) ; il attend le serveur jusqu'à 30 s (au lieu de 10) et dit « démarrage lent » après 5 s ; le code 5 ne vient qu'au-delà.
- **Tiroir** (E2, G1) : la pastille ne recouvre plus les boutons de zoom ; tiroir ouvert, la carte s'arrête au-dessus du tiroir (« Ajuster » et le cadrage en tiennent compte, ouvrir, fermer ou régler le tiroir recadre la carte), la barre de question se range, la visite guidée se ferme.
- **Page du terminal** (E3, G3) : le nombre de lignes de la grille se calcule sur la hauteur utile du cadre, la dernière ligne ne déborde plus ; la barre de défilement n'apparaît qu'au survol ou pendant un défilement.
- **Rebase sur H-1 (v1.1.2)** : le `PATH` assaini de `vf-cockpit-env.mjs` remplace les variantes N2 de `vf-cockpit-build.mjs`, `-live.mjs`, `-planning.mjs` et `-who.mjs` ; `gitCommonDir` tient N2 et H-1 ensemble. Le shell du terminal garde le `PATH` d'origine du lanceur, transporté par `VF_COCKPIT_PATH_ORIGINE` (limite : un serveur lancé hors du lanceur donne au shell le `PATH` assaini). Le patch du terminal est renuméroté `P26` (le `P25` est celui de H-1). Le moteur d'assemblage reçoit le repli `/usr/bin:/bin:/usr/sbin:/sbin` (et non plus `/usr/bin:/bin`) quand plus rien n'est sûr. Ceci remplace les phrases du tour D qui disaient H-1 renvoyée à un mandat séparé.

### Corrigé — tour de correction E de la Phase 71 (N9, N10)
- **Collage d'une ligne invisible ou de contrôle d'affichage confirmé** (N9 ; P71-D-30, arbitrage Samuel, AskUserQuestion session principale
  Claude Code, 2026-11-04 : « Corriger avant la PR (Recommandé) ») : xterm réordonnait visuellement le texte bidi, `echo hello<U+202E>; touch m; `
  s'affichait à l'envers et Entrée exécutait `touch m`. Une ligne portant un caractère de la classe Cf (bidi, zéro largeur), un caractère Tag ou
  un contrôle C0/C1 ouvre désormais le bandeau « Annuler / Coller », par la même définition que le marquage ⟨U+XXXX⟩ de l'aperçu.
- **Collage confirmé : ce qui est confirmé est visible** (N10 ; même arbitrage) : les suites d'au moins trois lignes vides ou blanches sont
  repliées à l'affichage (⟨N lignes vides⟩), un avertissement dit quand l'aperçu dépasse sa zone ; le texte envoyé reste l'original (sha256).

### Corrigé — tour de correction D de la Phase 71 (N8, N11, documentation)
- **Un `PATH` assaini vide n'est plus transmis au moteur d'assemblage** (N8, régression de N2 ; P71-D-29, arbitrage Samuel, AskUserQuestion, session
  principale Claude Code, 2026-11-04 : « le lanceur n'exécute jamais un binaire du lab ») : sans `PATH` ou avec un `PATH` entièrement relatif
  (`env -i`, `PATH=.`), Node posait `PATH=''` et libuv le lisait comme le dossier courant, donc le `git` du lab était exécuté (6 fois pendant
  `build`). Le moteur reçoit désormais `/usr/bin:/bin` (sous Windows, la clé est omise).
- **File d'entrée du terminal** (N11) : un morceau vide est retiré sans envoi ; il bouclait en POST vides (plus de 20 000 en 300 ms).
- **Sans `ps`, le refus d'arrêt est dit une seule fois** (au lieu d'une centaine pendant l'attente du terminal).
- **Documentation** : le README dit que le lanceur n'exécute jamais un binaire par son nom mais que le serveur vendorisé et le moteur ne sont pas assainis (H-1,
  mandat séparé) ; le docstring de l'assistant PTY dit la vraie garantie de `killpg` après le réapage du chef.

### Corrigé — dernier tour de mineurs de la Phase 71 (lot C)
- **Chaque branche d'arrêt de l'assistant tue la session** (M1) : sortie du shell, SIGTERM et fin du descripteur 0 portent chacune une
  assertion avec un `nohup` ; un relevé de processus qui ne contient pas l'assistant (`/proc` vide) vaut « impossible » et déclenche le
  repli sur les groupes (M2) ; un zombie n'est plus un membre vivant (M3) ; le PID du chef de session n'est plus signalé une fois le chef
  réapé (N4).
- **Fermeture bornée** (M3, N5) : au-delà de la borne de fermeture, le serveur escalade en SIGKILL sur l'assistant et rend la place ; le
  README dit la vraie borne (8 s au pire, la grâce de 3 s en pratique).
- **Saisie découpée** (M4, N6c) : jamais de corps de plus de 64 Kio sur l'entrée, une grosse saisie part en tranches dans l'ordre ; un 413
  réduit la tranche puis, à un octet, s'écrit dans le terminal, jamais silencieux.
- **Ouverture du terminal annoncée** (M6, N6b) : l'erreur asynchrone de l'ouvreur est rattrapée ; si l'amorçage n'est pas échangé dans les
  15 s, le lanceur le dit avec la page à ouvrir à la main ; limite Linux écrite au README (P71-D-27 inchangée).
- **Aucune trace au lanceur** (N6a) : un lien symbolique planté sur le chemin de sortie, serveur réutilisé, sort en code 4 avec un message.

### Corrigé — audit de sécurité de la Phase 71 (lot B1 : lanceur et amorçage)
- **Le lanceur n'ouvre plus une adresse lue dans le lab** (F1, majeur ; P71-D-25, validation de Samuel, AskUserQuestion, session
  principale Claude Code, 2026-11-04) : seuls des ports entiers sont lus dans `server.json`, l'adresse est reconstruite en
  `http://127.0.0.1:<port>`, et seulement si le processus est le serveur de la sortie ; un `server.json` planté ne remet rien à l'ouvreur.
- **L'amorçage n'est plus dans l'argv de l'ouvreur** (F6 ; P71-D-27, validation de Samuel, même canal, 2026-11-04) : page de redirection
  0600 en création exclusive, dont seul le chemin est remis à l'ouvreur, supprimée à l'échange et balayée à 60 s ; l'amorçage expire
  60 s après sa création, côté serveur. Limite résiduelle : lisible d'un processus du même compte pendant 60 s au plus.
- **Documentation alignée** (README) : Q n'a aucun écouteur `message` propre, le vendor xterm en garde un interne (F5, P71-D-15
  reformulée) ; réponses de format fixe d'xterm réinjectées (F8).
- **Limite signalée (B1-1)** : un `server.json` planté qui désigne un processus vivant étranger fait sortir `open` et `stop` en code 5
  tant qu'il n'est pas supprimé ; marche à suivre au README.

### Corrigé — audit de sécurité de la Phase 71 (lots B2 et B3)
- **Arrêt de toute la session du terminal** (S1 ; P71-D-28, validation de Samuel, AskUserQuestion, session principale Claude Code,
  2026-11-04) : SIGHUP puis SIGKILL à chaque membre de la session relevé à l'arrêt ; `nohup`, `disown` et `&` sont tués ; un
  processus sorti par `setsid` (ou double fork + `setsid`) survit ; repli sur les groupes si ni `/proc` ni `ps` ne sont lisibles.
- **`python3` résolu en chemin absolu** (F3 ; P71-D-25) : seuls les éléments absolus du `PATH` sont consultés, un `python3` du lab
  n'est jamais exécuté ; un élément absolu du `PATH` situé dans le lab reste consulté (limite). Le `PATH` du shell est inchangé.
- **Le lanceur n'exécute jamais un binaire du lab** (N2 ; P71-D-29, validation de Samuel, AskUserQuestion, session principale Claude Code,
  2026-11-04) : lancé depuis la racine du lab, sous un `PATH` à élément relatif ou vide (`.`, `:` en tête ou en queue, `bin`), il exécutait un
  `open`, `xdg-open`, `ps` ou `git` posé dans le lab. `open`, `xdg-open`, `ps`, `git` et `bash` sont maintenant résolus en chemin absolu dans
  les seuls éléments absolus du `PATH` ; le moteur d'assemblage reçoit un `PATH` assaini ; le serveur n'ouvre plus le navigateur lui-même
  (le lanceur le fait, y compris sans `--terminal`). Binaire introuvable : échec dit en clair, jamais un repli sur le dossier courant. Le
  `PATH` du shell du terminal est inchangé (P71-D-03).
- **Collage confirmé** (F2 ; P71-D-26, même canal, même date) : un collage ou un dépôt à retour à la ligne ou caractère de contrôle
  n'atteint le shell qu'après « Coller » dans un bandeau « Annuler / Coller » ; Échap annule, Tab puis Entrée valide, aucune touche de
  confirmation directe exprès ; une ligne simple passe.
- **Collage confirmé : aperçu intégral** (correction N1 ; P71-D-29, arbitrage Samuel, AskUserQuestion session principale Claude Code,
  2026-11-04) : le bandeau montrait 200 caractères coupés par une ellipse alors que « Coller » envoyait tout. Il montre désormais le texte
  intégral (zone défilante, texte seulement, décompte de lignes et de caractères), les caractères invisibles ou de contrôle d'affichage en
  marqueur ⟨U+XXXX⟩ ; le texte envoyé reste l'original ; une coupure d'affichage (au-delà de 20 000 caractères) est dite et levable.
- **Terminal limité à son cadre** (F4 ; P71-D-25) : un popup ou une ouverture seule de la page du terminal affiche « Terminal
  indisponible » (ni secret lu, ni flux, ni shell).
- **Police attendue au premier chargement** (2,5 s au plus) avant de mesurer la grille ; pastille du tiroir à 44 px sur écran tactile.

### Ajouté — Terminal intégré (Phase 71)
- **`--terminal`** — le lanceur ouvre un shell de votre compte dans un tiroir en bas des pages Projet et Code, dans la même
  fenêtre : `$SHELL -l` dans la racine du lab, `claude` y tourne avec son `CLAUDE.md` et ses skills (P71-D-01, D-03, D-04, D-06,
  D-08). Désactivé par défaut : sans le drapeau, aucun port, aucune route, aucun tiroir, politique de contenu de la v1.0.x
  (P71-D-02).
- **Second serveur d'une autre origine** (`127.0.0.1`, port éphémère) rendu dans un cadre ; sortie par `fetch` en flux, entrées
  par `POST`, pas de WebSocket (P71-D-09) ; `Host`, `Origin` et secret contrôlés sur chaque requête (P71-D-10, P71-D-24).
- **Amorçage à usage unique** (fichier 0600 effacé à l'échange, fragment d'adresse effacé), secret de session dans le stockage de
  la page du terminal, jamais de cookie (P71-D-11 à D-13).
- **Assistant PTY en Python standard** lancé isolé (`python3 -I`), redimensionnement, Ctrl-C ; une session, grâce de 30 s,
  tampon de reprise de 256 Kio en mémoire ; `TERM=xterm-256color` et `COLORTERM=truecolor` posés toujours (P71-D-05, D-06,
  D-23). Windows : indisponible (P71-D-07).
- **xterm.js 6.0.0 et addon-fit 0.11.0 vendorisés** (MIT, sha256, licences), aucun addon presse-papiers, séquences OSC 52,
  OSC 8, DCS et DECRQSS neutralisées (P71-D-16) ; canal de la page du terminal vers la page Projet limité à une liste fermée de
  valeurs fixes (P71-D-18) ; thème par paramètre d'adresse (P71-D-19).
- **Patch amont `P26` de `serve.mjs`** (`vibeflow P26`, diff dans `amont/patches/`), `AJOUT` des fichiers xterm et de l'assistant
  dans `VENDORED.txt`.
- **Suites** : `test-cockpit-terminal-activation.sh`, `-serveur.sh`, `-pty.sh`, `-session.sh`, `-page.sh`, `-client.sh`,
  `-tiroir.sh`, `-xterm.sh`, `-xss.sh`, `-lanceur.sh` (dix suites) ; `test-cockpit-chaine-xss.sh` et `test-cockpit-vendor.sh`
  étendues.

### Limites connues
- Voir la section « Limites connues » du README : limite de fond (votre compte, dépôt potentiellement hostile, extensions de
  navigateur), processus détachés, reprise du plein écran, déni de service du cadre par la page Projet, Windows, Safari et Firefox
  non mesurés.

## v1.2.2 — 2026-11-04

Phase 70 : finitions de l'interface. Décisions : P70-D-01 à P70-D-07 et P70-D-16, arbitrages Samuel, AskUserQuestion session principale,
2026-11-03 ; P70-D-09, P70-D-10, P70-D-13, P70-D-20 et P70-D-21, choix du manager (pas des arbitrages de Samuel) ; P70-D-19, arbitrage de
méthode de Samuel, session principale Claude Code, 2026-11-04 (recette jouée par des juges qui prennent des captures). Pas de release racine.

### Corrigé
- **Français** : plus d'anglais résiduel ni de coquille dans le chrome (« clic droit », « Dans … », « Mis à jour il y a … », « d'equipe-… », « 1 fichier de code »),
  fil d'Ariane sans doublon, durées et textes de la visite jamais coupés.
- **« Où en est-on ? »** sans `STATE.md` : réponse construite des seuls champs présents, plus de statut brut (`ready_to_execute`) affiché.
- **Couleurs de statut** du thème clair : suivent le thème, contrastes d'au moins 4,5:1 (mesurés de 6,07 à 7,01:1 en clair).
- **Visite** : texte entier, « Passer » à chaque étape, centrage de la première étape stable au rechargement, grandes cartes cadrées, contour de l'étape sur un élément du chrome.
- **Onglet Équipe** : badge d'état dans sa carte, « non rattaché » sur une ligne, boutons au style du tiroir (sans toucher aux boutons du viewer), champs en paragraphes,
  lien « Nœud » distinct, titre sans recouvrement de la première carte, focus clavier gardé sur « Lire le transcript » et « Voir la dernière commande » après redessin.

### Modifié
- **Téléphone** : en-tête sur une rangée avec menu « ⋯ », zoom en pile verticale à gauche, tiroir à poignée, croix et titre cliquable, onglets à 13 px / 3 px (390 px).
- **Visite de l'onglet Projet** : propre au projet (jalon, phase, mission, « au travail »), sans mention de code.
- **Zoom de l'onglet Équipe** : en bas à gauche dès 701 px (P70-D-20).

### Limites
- Onglets à 12 px / 2 px à 1 024 et 1 440 px (R13.4 rouge, six lignes) : arbitrage de Samuel en attente.
- Carte Session « en attente » avec badge « En cours » (défaut de la Phase 69, au BACKLOG).
- Tri de goût (12 questions) en attente de Samuel : `70-RECETTE-JUGES.md`.

## v1.2.1 — 2026-11-04

Correctif : l'onglet Projet voit les phases en cours dans des worktrees (N5 de la recette de la Phase 68). Arbitrage Samuel,
AskUserQuestion session principale Claude Code, 2026-11-04 : « Correctif juste après la 68 (Recommandé) ». Pas de release racine.

### Corrigé
- **Phases menées dans un worktree** : la carte Projet (et la vue macro du jalon, et les phases de `signal@1`) lisait le ROADMAP et les dossiers de phase
  de l'arbre courant seulement ; une phase en exécution dans `.claude/worktrees/phase-70` s'affichait « À faire · pas de plan ». Elle prend désormais l'avancement
  du worktree (état, décompte de plans, reste) et la carte le dit : « dans worktree phase-70 ». Nouveau module `vf-cockpit-ailleurs.mjs`.
- **Règle de priorité** : l'état le plus avancé gagne (à faire < en cours < à recetter) ; un état clos sur l'arbre courant reste clos ; une clôture lue
  seulement dans un worktree vaut « à recetter » ; à égalité l'arbre courant garde la main.
- **Rien sous le lab** (P68-D-34) : les fichiers d'un worktree sont lus, jamais exécutés, et chaque lecture est confinée à la racine réelle de son arbre
  (`lireConfine`) : un lien symbolique sortant n'est pas suivi. Git passe par `arbresGit` (préfixe sûr, environnement assaini).
- Suite `test-cockpit-ailleurs.sh` (témoin rouge avant, vert après ; priorités ; lien symbolique sortant, prouvé par mutation).

## v1.2.0 — 2026-11-04

Phase 68 (vf-signal embarqué, socle partagé). Module monté seul ; le bump racine est reporté à la release groupée (P68-D-31 :
arbitrage Samuel, AskUserQuestion session principale Claude Code, 2026-11-04, « Module seul, racine groupée (Recommandé) »).
Publiée dans VibeFlow vX.Y.Z (mention à compléter par le geste de release groupée). Autres décisions : P68-D-08 et P68-D-21
(arbitrage Samuel, AskUserQuestion session principale Claude Code, 2026-11-03).

### Ajouté
- **Mod vf-signal embarqué** : pane terminal affichée par Claude Code, gatée (elle ne s'affiche que si `cockpit=` est posé), bouton
  « Ouvrir le cockpit ».
- **Émetteur `signal@1`** : état du travail publié pour la pane (mission vivante, retard sur la base, worktrees).
- **Socle partagé** : calcul de la vie d'une mission (`mission.vie`), lecture des arbres git (`arbresGit`) et émetteur, communs au cockpit et au mod.
- **Cascade de vie (P68-D-33)** : verrou de phase, puis verrou du compartiment, puis verrou de dépôt (et l'ancien `.planning/DRIVER.lock`) ;
  un verrou présent, même périmé, arrête la cascade (P68-D-27, P68-D-36), et la mission est `abandonnee` s'il est périmé ou si aucun
  verrou n'existe ; une source illisible donne `inconnu`.
- **Lanceur et repli de l'élagage (P68-D-34)** : le mod n'exécute aucun fichier du compte ou du plugin dont le chemin ou le realpath
  tombe sous le lab (la racine du plugin n'est refusée que sous `<lab>/.vibeflow`) ; lanceur pris dans le compte (`~/.claude/scripts`)
  puis dans le plugin, `driver-lock.sh` de l'élagage pris dans le plugin puis dans le compte. Un fichier existant dont le realpath est
  inconnu est refusé, et les lancements partent hors du lab avec un PATH assaini (P68-D-37).

### Modifié
- **`avancement@1` devient `avancement@2`** : états de mission `abandonnee` et `inconnu` et champ `mission.vie` (vocabulaire de mission
  fermé élargi) ; `who` lit les arbres par `arbresGit`.
- Corrections issues de la recette de la Phase 68 (revues du socle, du mod et du web).
- **Tiroir « Au travail »** : l'âge d'un verrou se retrouve par correspondance exacte sur la portée et le compartiment, plus par sous-chaîne
  (deux compartiments dont l'un est préfixe de l'autre, `fiabilite` et `fiabilite-2`, gardent chacun leur âge).
- **README de la pane** : règle de rafraîchissement (P68-D-41 : arbitrage Samuel, AskUserQuestion session principale Claude Code, 2026-11-04),
  coût remesuré, version vérifiée de Claude Code (2.1.318 ; non chargée sous 2.1.181, plancher exact non mesuré) et cockpit installé sans `conductor` (« état inconnu »).
- **Environnement des lancements du mod (P68-D-40, P68-D-42)** : le mod vide `VF_COCKPIT_SCRIPTS_DIR`, `NODE_OPTIONS`, `BASH_ENV` et `ENV`
  dans l'environnement de ses lancements (émetteur, lanceur du cockpit, élagage), pour que rien sous le lab ne s'exécute par leur biais.
- **Cadence (P68-D-41)** : pane fermée, le bandeau peut afficher un état vieux d'une minute ou plus ; une horloge qui recule compte comme une minute échue
  (FND-3), et le minuteur de 10 s est annulé avant d'être reposé (FND-4).

### Retiré
- Lecture maison du planning par le mod (remplacée par le socle partagé).
- Couleurs « Signal » du mod.
- Bloc backlog de la vue macro.

## v1.1.2 — 2026-11-04

Correctif de sécurité H-1 (héritée de la Phase 67, présente dès v2.75.0), sur arbitrage de Samuel (AskUserQuestion, session
principale Claude Code, 2026-11-04 : « Mandat séparé maintenant (Recommandé) »). Pas de release racine.

### Corrigé
- **Outils du lab exécutés par le serveur** : le serveur et ses modules appellent des outils par leur nom (`which`, `claude`, `git`, `bash`,
  puis `awk`, `tr`, `ps` par `driver-lock.sh`). Avec un `PATH` contenant `.`, un élément relatif ou vide (que libuv lit comme le dossier
  courant), ou un dossier du lab, un programme piégé posé dans le lab s'exécutait à leur place.
- Un seul utilitaire, `vf-cockpit-env.mjs` (`assainirPath`, `envEnfant`) : retire du `PATH` tout élément vide, relatif ou situé sous le lab
  (lien symbolique résolu), avec le repli `/usr/bin:/bin:/usr/sbin:/sbin` si plus rien ne reste. Il s'applique à l'environnement de chaque enfant
  (`git`, `bash`, `ps`, moteur de construction, serveur détaché du lanceur) et, par le patch P25 de `serve.mjs`, au processus du serveur
  lui-même (donc à `which`, `claude --version`, l'agent et l'ouverture du navigateur). Le `PATH` du shell de l'utilisateur n'est jamais modifié.

### Ajouté
- `test-cockpit-path-enfants.sh` : l'utilitaire (U), les fonctions du module (F), le serveur (S) et le lanceur (L) lancés depuis un lab dont les
  outils sont piégés, avec `PATH=.:…`, un `PATH` relatif, vide et absolu sous le lab. Rouge avant le correctif (outils du lab exécutés), vert après.

## v1.1.1 — 2026-11-04

Correctifs de la recette de la Phase 69, sur arbitrage de Samuel (AskUserQuestion, session principale Claude Code,
2026-11-04 : « « Dépend de » faux, Verrou « Driver libre », Contraste « En cours », Pied caché, ligne anglaise »). Pas de release racine.

### Corrigé
- **« Dépend de »** : la valeur de `Depends on` perd ses parenthèses, ses identifiants `Pnn-D-nn` et tout ce qui suit la première phrase ;
  une phase dépendante (« La Phase 68 en dépend ») ou le 10 de `P69-D-10` ne sont plus lus comme des dépendances.
- **Verrou « Driver libre »** : le script du conductor voisin (`…/plugin/conductor/scripts`) passe avant la copie de `~/.claude/scripts`,
  qui peut dater d'avant les verrous par phase ; la copie installée ne sert plus que de repli.
- **Contraste des statuts** : `--st-active` et `--st-blocked` suivent le thème (`--sev-medium`, `--sev-high`) au lieu de `#f59e0b` et `#ef4444` en dur ;
  le texte des pastilles est teinté vers `--text` (au moins 4,5:1 dans les deux thèmes) ; `--text-1`, qui n'existait pas, devient `--text`.
- **Pied des cartes de phase** : lisible au zoom d'ouverture d'un jalon (pied agrandi, description masquée à ce niveau).
- **Export de l'onglet Code** : « Ce qui vient de changer, et pourquoi. » remplace la ligne anglaise.

## v1.1.0 — 2026-11-03

Phase 69 : suivi du travail en cours. Décision du bump : arbitrage Samuel, AskUserQuestion session principale,
2026-11-03 (P69-D-26, « Bump v1.1.0 »). Les gestes de release racine (version, tag, release GitHub) restent humains.

### Ajouté
- **État d'avancement dérivé des phases** (CKPT-13 à CKPT-18) — « à faire », « en cours », « à recetter », « fait », calculé
  depuis les plans et leurs SUMMARY ; plans de correction comptés à part ; missions rattachées à leur phase ; contrat `avancement@1`.
- **Équipe en arbre avec historique de 24 h** (CKPT-19, CKPT-20, CKPT-27, CKPT-28) — session -> manager -> workers, terminés
  repliés ; forme des sous-agents de Claude Code mesurée (2.1.317) et stricte (`forme-inconnue` plutôt qu'un mensonge) ;
  contrat `vibeflow/cockpit-who@2` (remplace `@1`) et `vibeflow/cockpit-equipe@1`.
- **Onglet « Équipe »** (CKPT-23) — troisième onglet, page `/equipe.html` servie en mémoire, mise à jour en place.
- **Dernière action lisible et lien vers le nœud de mission** (CKPT-21, CKPT-22) — table fermée de verbes (libellés provisoires) ;
  un agent non rattaché dit pourquoi.
- **Transcript à la demande** (CKPT-24 à CKPT-26) — réduit au mandat, aux messages et à la liste des outils, masque des
  secrets au mieux, route `GET /api/vf/transcript` authentifiée, jamais dans le flux, les fichiers, le journal ni l'export,
  garde d'émission lue du contrat et fermée par défaut ; contrat `vibeflow/cockpit-transcript@1`.

### Modifié
- Forme Claude Code étendue et mesurée (fenêtre de 24 h, aucune lecture hors fenêtre).
- Onglets resserrés pour tenir à trois dans l'en-tête (borne `.hl` 264 -> 280 px) ; retour aux valeurs d'origine en Phase 70 (P69-D-28).

### Limites
- Masque des secrets au mieux sur la prose des mandats et des messages ; jeton lisible par tout processus local : risque accepté
  (P69-D-27, arbitrage Samuel, AskUserQuestion session principale, 2026-11-03).

## v1.0.2 — 2026-11-03 — non publié

### Ajouté
- **Verrous de phase dans « qui est au travail »** : `vf-cockpit-who.mjs` affiche `compartiment <sujet> phase <N>` et lit le
  registre des agents de chaque phase tenue (`orphans --ws --phase`). Règle de Samuel, session principale, 2026-11-03.

## v1.0.1 — 2026-11-03

Publiée dans VibeFlow v2.75.1.

### Corrigé
- **ROADMAP écrit à la française lu par l'onglet Projet** — `Phase N : nom` (espace avant les deux-points, insécable
  comprise) était ignoré : le lab Scroll-Off n'affichait aucune phase de son jalon en cours (constaté le 2026-11-03).
  La ligne `**Depends on**: rien · **Parallélisable avec**: Phase 4` ne crée plus de dépendance à la Phase 4 ;
  `## Jalons` vaut `## Milestones`, `**Objectif**` vaut `**Goal**`, `**Dépend de**` vaut `**Depends on**`.

### Ajouté
- **Détection de dérive de format avant la lecture** (`scripts/vf-cockpit-drift.mjs`) — quatre règles
  (`phases-illisibles` bloquant, `phase-deux-points` et `depends-on` tolérés, `jalons-absents` et
  `phase-courante-absente` en info). Le panneau d'ensemble de l'onglet Projet les affiche dans une section « Format de
  la planification » (`meta.vf.drift`). `--diff` propose un correctif au format unifié vers le gabarit GSD, jamais
  écrit sur disque : on le relit puis on l'applique avec `git apply` (ADR-031). Suite `test-cockpit-projet.sh` (P6.1 à P6.14, dont les mineurs F1 à F5 de la relecture adverse SOBR-04).

## v1.0.0 — 2026-11-01

Première version du module (publiée dans VibeFlow v2.75.0). Décisions : arbitrages Samuel,
AskUserQuestion session principale, 2026-11-01.

### Ajouté
- **Socle partagé à interface versionnée** (P67-D-12) — collecteur « au travail », lecture de la planification, verrou et
  chemins du lab ; schémas `vibeflow/cockpit-*@1` consignés dans `scripts/vf-cockpit-interface.json`, destinés à `vf-signal`.
- **Moteur d'affichage vendorisé et rejouable** (P67-D-07, P67-D-11) — copie du moteur floorplan v0.6.0 @ 92d6854 (MIT)
  sous `skills/cockpit-moteur/`, patchs listés dans `VENDORED.txt`, procédure de synchro hors réseau (`amont/SYNCHRO.md`).
- **Marque blanche par renommage de la sortie** (P67-D-03, P67-D-04) — aucune mention du produit amont dans ce que voit
  l'utilisateur ; logo et favicon VibeFlow.
- **Cloud retiré, aucun appel sortant hors l'agent** (P67-D-02) — la fonction Cloud du moteur est retirée, le test réseau
  enregistre 0 connexion sortante.
- **Serveur unique avec direct et repli** (P67-D-13, P67-D-16) — flux d'événements, surveillance récursive de `.planning/`
  avec repli par scrutation, anti-rebond et hystérésis.
- **Dernière commande masquée** (P67-D-14) — jamais diffusée ; révélée à la demande dans la page.
- **Questions locales et agent confiné, modèle réglable** (P67-D-08, P67-D-15) — réponses calculées sur place pour les
  formes courantes, sinon `claude -p` confiné (mesure `67-MESURE-claude-p.md`) ; `sonnet` par défaut, liste fermée,
  `VF_COCKPIT_MODEL` et sélecteur de la page.
- **Onglet Code conditionnel** (P67-D-17) — extracteur VibeFlow sur un lab à modules, architecture brute ailleurs.
- **Verbe `/vf-cockpit`** (P67-D-05) — skill de classe utilisateur (`open`, `build`, `stop`, `status`), pour tous les
  postes (P67-D-01) ; aucun fichier sous `plugin/commands/`.
- **Sortie sous `.vibeflow/cockpit/`** (P67-D-06) — ignorée par git, ce dossier compris.
- **Chrome en français, test d'inventaire qui rougit** (CKPT-09, P67-D-03, P67-D-18) — dictionnaire (deux fichiers `assets/ui/78` et `79`), gabarits à variables, motifs et fonction pure `window.__vfFrTraduire` (`80-vf-fr.js`) ; inventaire déterministe des chaînes anglaises du rendu servi (`vf-cockpit-fr-inventaire.mjs`) comparé au dictionnaire, aux gabarits, aux motifs et aux exclusions justifiées (`vf-cockpit-fr-exclusions.json`) ; statuts de STATE affichés en français ; direction artistique du moteur conservée.

### Interface ajustable et corrections de la recette (correction B de la Phase 67, avant toute publication)
- **Fenêtre ajustable de 1 024 à 2 560 px** (CKPT-12, P67-D-21 ; demande de Samuel, message session principale, 2026-11-01) — en-tête en ligne souple
  (`assets/ui/01-vf-responsive.js`) : nom de projet tronqué avec une ellipse, recherche gardée à 200 px, boutons d'action en icône seule sous 1 600 px,
  barre de question sur une ligne, zoom au-dessus de la barre jusqu'à 1 279 px ; la règle de grille de `80-vf-fr.js` qui écrasait la recherche est retirée.
  Suite `test-cockpit-responsive.sh` (boîtes mesurées dans Chrome headless, redimensionnement à chaud, témoin rouge intégré).
- **Logo VibeFlow lisible** (il était inversé par le viewer : un tiret orange) ; titre d'onglet « <nom> — Code » ; export nommé « …-carte.html » (P20).
- **Lab sans `STATE.md`** : plus de « ? » ni de parenthèses vides dans le sous-titre et le panneau d'ensemble.
- **« Au travail »** : badge compact (le détail du verrou est dans l'infobulle et le panneau) ; les nœuds `running` de `.planning/missions/*.dag.json` sont lus ;
  la dernière commande d'une session très active est retrouvée (remontée jusqu'au dernier appel Bash, fenêtres jusqu'à 8 Mio : un gros résultat
  d'outil en dernière ligne rendait « Indisponible » et pouvait cacher la session) ; journal minimal authentifié `GET /api/vf/journal`.
- **Reconnexion à recul** (E-6, P21) : serveur arrêté, la page sonde une fois par seconde pendant 30 s, puis toutes les 5 s, puis s'arrête avec un message
  et « Réessayer » (un seul sondage pour les deux flux, au lieu de deux requêtes par seconde sans fin). Suite `test-cockpit-reconnexion.sh`.
- **Direct** : le résumé d'une carte de mission suit le statut de ses nœuds ; « Thinking… » traduit avant la peinture.

### Corrigé (recette humaine du 2026-11-02, avant toute publication)
- **En-tête à 1 024 px** (R8, R9) — la mise en page souris est conditionnée à `not (pointer: coarse)` au lieu de `(pointer: fine)` : Chrome headless sous Linux n'annonce aucun pointeur, la règle souris ne s'appliquait donc pas et l'en-tête restait dans la grille du viewer ; tests R8 et R9 ajoutés. Source : recette humaine du 2026-11-02.
- **« Voir la dernière commande »** (D3) — montre la dernière commande Bash de la session, plus le dernier message de l'assistant, et au plus le programme et son premier argument (« git push … »), programme seul si ce premier argument commence par `-`, contient `=` ou un caractère hors liste blanche (`redis-cli -a …`, `env DB_PASS=…`, `export KEY=…`, chaîne de requête `?key=…`, mot cité) ; liste blanche (lettres ASCII, chiffres, `_ . / : @ % + , ~ -`) à la place de la lecture des guillemets : une affectation de tête n'est sautée que si elle vaut `NOM=<mot simple ou vide>` ; un mot de tête qui n'est pas une telle affectation est le programme, et rend « … » s'il n'est pas simple ; la découpe en mots se fait sur espace, tabulation et retour à la ligne seulement (`\r`, `\f`, `\v` restent dans le mot, donc non simple) (vérifié sur 6 000 commandes générées, graine fixe). Limite acceptée : un secret passé en premier argument positionnel simple reste visible (`ls Secret99`, et surtout une URL ou un hôte en premier argument dont le jeton est dans le chemin ou dans l'userinfo (seul `schéma://utilisateur:mot-de-passe@` est masqué) ; ex. `curl https://api.telegram.org/bot<id>:<jeton>/getMe`, `curl https://<jeton>@hôte`, `curl user:pass@hôte`). Les masques `mysql -p` et `sshpass -p` sont conservés pour task/cwd/role (décision de Samuel, « N'afficher que le programme », AskUserQuestion session principale, 2026-11-02). Source : recette humaine du 2026-11-02.
- **Tiroir « Au travail »** (D2) — marge et hauteur ajustées. Source : recette humaine du 2026-11-02.
- **« Où en est-on ? » après une réponse de l'agent** (V1) — les formes courantes répondent sur place même une fois l'agent intervenu : la voie locale ne dépend plus de l'absence de session. Effet de bord arbitré : une relance qui dépend du fil et contient un mot de la voie locale reçoit la réponse locale (arbitrage Samuel, option A, AskUserQuestion session principale, 2026-11-02). Source : recette humaine du 2026-11-02.
- **Parcours « Trajectoire »** (D1) — à la dernière étape, le chevron « suivant » est inactif et il ne reste qu'une croix. Source : recette humaine du 2026-11-02.
- **Vue d'ensemble** (I2) — léger flou et fond translucide derrière le titre et le sous-titre. Source : recette humaine du 2026-11-02.
- **Mise à jour en direct** (I3) — la carte ne rejoue plus son animation d'apparition ; seules les cartes basculées clignotent. Source : recette humaine du 2026-11-02.
- **Types de carte en français** — « Library » et ses pairs sont traduits dans le chrome de l'onglet Code. Source : recette humaine du 2026-11-02.
- **Onglet Code, dossiers de `plugin/` sans `module.json`** — ils ont désormais leur nœud (kind infra, outillage) au lieu de tomber dans « non assigné » ; règle générique, sans liste de noms. Source : recette humaine du 2026-11-02 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-02).

### Corrigé (recette 3, 2026-11-03, avant toute publication ; arbitrage Samuel, AskUserQuestion session principale, 2026-11-03)
- **« Voir la dernière commande » derrière un `cd`** (O1) — `cd <chemin> && git status` affichait « … » seul (ou « cd … ») alors que c'est la forme la plus fréquente : un `cd` simple (un seul mot simple, `&&` ou `;` en mot séparé ou collé à la fin du chemin) s'efface et la règle s'applique une fois à la commande qui suit (« git status ») ; le chemin du `cd` ne sort jamais, tout autre `cd` (chemin cité, `||`, option, second `cd`) rend « … ».
- **Port stable par lab, visite sans cookie** (O4, arbitrage Samuel, « C : port stable par lab (Recommandé) », AskUserQuestion session principale, 2026-11-03) — le cockpit d'un lab prend un port préféré dérivé de la racine réelle du lab (sha1, 100 valeurs à partir de 4378), le même à chaque lancement quel que soit l'ordre ; repli port+1 (20 essais) de `serve.mjs` en cas de collision. La marque « vue » de la visite « Par où commencer » reste en localStorage par lab (`vibeflow-cockpit:visite:<lab>`), l'origine étant désormais stable ; plus de cookie. Nouveau module `vf-cockpit-port.mjs`, variable de test `VF_COCKPIT_PORT_BASE`. Suites `test-cockpit-serveur.sh` (PS.*) et `test-cockpit-projet.sh` (O4).
- **Vue d'ensemble, matériau à la iOS** (I2, retour de Samuel, saisie texte, session principale, 2026-11-03 : « le flou sous le titre est trop dense, il faut aussi qu'il ai un radius fort en haut faible en bas, il doit etre comparable au blur iOS ») — `#context` : `blur(24px) saturate(1.8)` (la recette de `.glass`), fond à 30 % d'opacité (55 % avant), coins 22 px en haut et 6 px en bas, filet de lumière ; les deux thèmes. Source : `assets/ui/00-vibeflow.js`. **Reprise (avis de Samuel, Wispr Flow, session principale, 2026-11-03 : « pas de bordure, un flou dégradé qui part du haut gauche et descend, comme le header, en mode iOS 26 »)** : plus de carte, ni bordure, ni rayon, ni ombre ; `#context::before` porte un flou progressif (`blur(22px) saturate(1.6)`, fond `--bg-rgb` à 28 %) masqué par un dégradé radial ancré en haut à gauche (`mask-image` et `-webkit-mask-image`), plein derrière le début du titre, estompé vers le bas et la droite. **Seconde reprise (avis de Samuel, Wispr Flow, session principale, 2026-11-03 : « il y a un gap où il n'y a pas de flou entre le texte vue d'ensemble et le header […] allonger un petit peu le flou pour qu'il aille jusqu'au header »)** : la couche monte jusqu'au haut de l'en-tête, derrière lui (inset haut relatif à `--hh`, jamais une valeur calée sur une largeur), car le dégradé de l'en-tête s'estompe sur sa hauteur et laissait voir la carte nette entre les deux ; le masque (deux couches) garde l'aspect d'avant autour du titre.
- **Fil d'Ariane jamais rogné à tort** (O2, budget revu après la revue de la recette 3) — un segment de moins de 12 caractères (11 au plus) n'est jamais rogné ; la troncature commence par le milieu (segments longs, plancher de 64 px), puis le premier et le dernier ; si le fil déborde encore, les segments du milieu se replient derrière « … » (infobulle : leurs noms). Dès 1 280 px la colonne gauche prend sa largeur naturelle et la recherche cède la première (jamais sous 200 px), puis le nom du projet : plus aucun `min-width` dérivé de la largeur du fil, donc plus de bouton d'en-tête hors de la fenêtre à 1 280-1 320 px (revue F1/F2). Source : `assets/ui/01-vf-responsive.js`.
- **Italique rendu dans les réponses de l'agent** (O3) — `*…*` et `_…_` deviennent `<em>` après l'échappement, hors des spans de code ; bornes de mot : ni `a * b * c`, ni `snake_case_var`, ni `**/*.js`, ni `2*3*4`, ni liste à puces. Patch P23 de `viewer.html`.
- **Chevrons de la Trajectoire nommés** (O6) — « Étape précédente » / « Étape suivante » (aria-label et infobulle ; dictionnaire `78-vf-fr-dict-a.js`). Patch P23.

### Sécurité et robustesse (correction A de la Phase 67, avant toute publication)
- **Chaîne lab piégé -> XSS -> jeton -> exécution de code rompue à trois endroits** — échappement de tout champ du graphe (patch P16), Content-Security-Policy
  par empreintes avec `connect-src 'self'` et en-têtes `nosniff`/`DENY` (P17), « modifier le plan » durci : seuls `plan.mjs` et `build.mjs` du moteur du module
  s'exécutent, jamais un script désigné par un `.cache/` du lab (P15). Suite `test-cockpit-chaine-xss.sh` (navigateur headless, mutants).
- **Aucun script du lab exécuté** — plus de `driver-lock.sh` pris sous le lab, arrêt du serveur par signal sur un PID vérifié, aucune écriture ni lecture à travers un lien symbolique.
- **`claude -p` confiné aussi côté réglages** — `--setting-sources ""` (ni hooks du lab ou de l'utilisateur, ni règle `allow`) et `--strict-mcp-config`, mesurés.
- **Robustesse** — une question courante ne fait plus tomber le serveur, la page rechargée est à jour après un patch, verrou tenu visible en lab plat,
  lab sans code assemblé, masque des secrets étendu, corps JSON non objet refusé, `<!--` neutralisé, timeouts partout.

### Corrigé (relecture adverse SOBR-04 de v2.75.0, avant la publication ; arbitrage Samuel, AskUserQuestion session principale, 2026-11-03, « Corriger maintenant »)
- **`--port` borné à 1024..65515** (65515 = 65535 − 20 essais de repli de serve.mjs : au-delà, le repli sortait de la plage, erreur avalée, serveur orphelin) (F1) — `--port 99999` lançait un serveur qui ne pouvait pas écouter, survivait sans `server.json` et échappait à `stop` ; le lanceur refuse maintenant tout port hors bornes (code 64) avant de lancer quoi que ce soit. Test `PS.12` de `test-cockpit-serveur.sh`.
- **Mode de question hors liste** (F2, patch P14) — `constructor`, `__proto__`, `toString` ou `hasOwnProperty` en `mode` lançaient l'agent avec `--json-schema undefined` ; seuls les modes propres de la table comptent, le reste retombe sur `ask`. Test `Q4b` de `test-cockpit-questions.sh`.
- **Ceinture `doing` éprouvée** (F3) — le refus d'émettre un objet portant une clé `doing` (flux et hello, à toute profondeur) n'était tué par aucune suite ; test `DO` de `test-cockpit-serveur.sh` (le serveur réel, le collecteur seul remplacé par un double).
