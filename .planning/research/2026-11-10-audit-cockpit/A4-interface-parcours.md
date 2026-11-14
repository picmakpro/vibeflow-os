# A4 — Interface : parcours en direct dans le navigateur

> Annexe de `.planning/research/2026-11-10-audit-cockpit-etude.md`. Rapport brut de l'agent de parcours (Playwright, 1440, 1024 et 390 px, clair et sombre, clavier seul). Les 85 captures citées (`ux-NN-…png`) ne sont pas versées, sauf les six de `page/` ; elles restent sur le poste de l'audit, dossier non suivi `.playwright-mcp/audit/` de l'arbre principal. Dans le registre, les mineurs m1 à m8 portent `AUDC-X1` à `AUDC-X8`. Rendu le 2026-11-10 sur `release/v2.77.0` (cockpit v1.4.0 et retours du panel non publiés). Texte de l'agent, chemins ramenés à la racine du dépôt. Les identifiants de suivi (`AUDC-…`) et la destination de chaque constat sont dans `REGISTRE.md`.

---

**Audit UX du cockpit VibeFlow — parcours Playwright en direct (1440, 1024, 390 ; clair et sombre)**

## À savoir d'abord
- **Aucune session Claude Code lancée.** Dans le shell : `echo test` seulement. « Lancer » : « Vérifier » (Phase 72) → bandeau lu → « Annuler » ; « Préparer dans le terminal » jamais cliqué.
- **Je n'ai pas joué `stop`.** La seule commande `open … --terminal` sur le serveur vivant (PID 95947 inchangé) a réarmé l'amorce. Dépôt intact (`git status` vide), aucun processus tué.
- **PTY** : vivant après fermeture du tiroir (PIDs 15322, 15364, zsh 15371), disparu ensuite sans geste de ma part. `ps` final : aucun `vf-cockpit-pty.py`.
- **`--idle-exit 60` vaut 60 minutes sans onglet ouvert** (serve.mjs:88 et 220), pas 60 s : invisible depuis une page par construction. La coupure vue de la page est en M9.
- **Non testés** : envoi « Demander », « Corriger avec Claude », « Demander un parcours », téléchargement de l'export, lecteur d'écran, Safari/Firefox. Un blocage de 30 min est venu de mon émulation tactile, pas du cockpit.

## A. Verdict
1. Graphite est tenu, surtout en sombre : calme, cohérent, états lisibles par forme et par mot.
2. Le canevas à cartes est appliqué partout, y compris où il échoue : Projet illisible à l'ouverture, Équipe vide, Backlog et Releases en vignettes.
3. Les meilleures surfaces sont les moins « graphe » : tiroir Git, terminal, bandeau de lancement, recherche.
4. Le clavier s'arrête au bord du canevas : aucune carte n'est atteignable.
5. Ordre de travail : lisibilité de Projet, clavier, puis honnêteté des états (coupure, terminal, santé).

Barème : 90 = livrable tel quel, 70 = utilisable avec frictions, 50 = tâche principale gênée, 30 = tâche principale en échec.

| Code | Projet | Équipe | Git | Terminal | Lancer | Mobile | Accessibilité | Graphite |
|---|---|---|---|---|---|---|---|---|
| 62 | 34 | 40 | 68 | 72 | 70 | 44 | 36 | 74 |

## B. Constats
Tout est observé et mesuré, sauf mention « supposé » ou « lu dans le code ».

### Bloquant
- **BL1 — Projet illisible à l'ouverture.** Cette vue ne permet pas de savoir où en est le jalon : zoomé à taille lisible, on ne voit que 3 phases. `ux-25`, `ux-27`, `ux-63-1024-projet`, `ux-71`.

  | Vue | Échelle | Titre de carte | Remarque |
  |---|---|---|---|
  | Vue d'ensemble, 1440 | 0,475 | 7,1 px | plus petit que la méta (9,0 px) ; cartes = 12 % de la zone libre |
  | Jalon vibeflow-v2.0, 1440 | 0,245 | 5,4 px | pastilles 4,2 px ; cartes = 4 % |
  | Vue d'ensemble, 1024 | 0,28 | 6,2 px | |
  | Téléphone | 0,167 puis 0,086 | 3,7 puis 1,9 px | cartes de 27×15 px dans le jalon |

  → Plancher de lisibilité (≥ 0,85), mise en page compacte (colonnes par état, écarts de 130 px réduits), vue liste par défaut sous 1 100 px.
- **BL2 — Canevas hors clavier et hors arbre d'accessibilité.** 0 carte parmi 54 (Code), 22 (Projet) et 17 (Équipe) arrêts de tabulation. Les cartes sont des `div` sans rôle, nom ni tabindex, dans un SVG sans rôle. Flèches et Entrée sont sans effet ; seule la recherche `/` atteint un nœud. → `role=button`, nom accessible, tabindex itinérant, flèches entre voisins, Entrée = plonger.

### Majeur
- **M1 — « Vue d'ensemble » ne montre pas l'ensemble (Code).** « Ajuster » plafonne à 0,846 : 6 cartes sur 26 entièrement visibles à 1440 (2 à 1024), 16 hors écran, 2 sous l'inspecteur. Après plongée, la colonne de droite reste coupée, panneau fermé compris. La molette déplace : six crans et le canevas est vide, sans rappel. `ux-01`, `ux-06`, `ux-37`. → Ajuster sur la zone libre, minicarte, compteur « N cartes hors champ ».
- **M2 — Bloc de titre sans fond sur le canevas.** Il se superpose aux cartes : `ux-22-etape2`, `ux-30` (« Lire la suite » sur la carte 72-03), `ux-38`, `ux-67`. → Zone réservée, ou titre dans l'en-tête.
- **M3 — Équipe dit l'inverse de ce qu'elle montre.** « Aucune mission en cours » avec 7 agents actifs, une carte sur un canevas vide à 93 %. « Santé : aucun problème trouvé » quand Code affiche 4 points. Ni « Demander » ni terminal sur cet onglet. `ux-39`, `ux-48`. → Titre « 7 agents actifs », arbre des agents dès l'ouverture, santé alignée ou retirée.
- **M4 — Détail de session et transcript pauvres.** Branche répétée 3 fois ; ni modèle, ni durée, ni jetons, ni fichiers ; chaque ligne d'agent répète son titre en sous-titre. Le transcript est une boîte de 320 px à défilement imbriqué, large de 308 px, en markdown brut (`**…**`), avec mandat, messages et outils en trois listes sans heure. Sur la session principale il était déjà affiché et « Lire le transcript » n'a rien changé de visible. `ux-40` à `ux-46`. → Lecteur large, fil chronologique unique, bandeau de faits.
- **M5 — En-tête difficile à décoder.** 9 icônes sans libellé sur Code, 7 ailleurs. ▶ ouvre « Parcours » (un menu d'une entrée), l'icône « Travail récent » ressemble à un chargement, un point beige vaut « N au travail ». « Vue d'ensemble » est à 8 px des onglets, dans le même corps. La branche est tronquée « release/v2… » malgré la place. Le menu téléphone, lui, libelle tout (`ux-68`). `ux-03`. → Trois groupes libellés au-delà de 1 280 px, fil d'Ariane avec chevron.
- **M6 — Surcouches sans piège à focus.** Recherche : Tab sort de la palette restée ouverte, puis Échap ne la ferme plus (reproduit deux fois, `ux-77`). Export : Tab sort de la modale. Visite : le focus n'y entre pas. Panneau fermé (P) : 43 arrêts invisibles (`ux-76`). → `inert` sur ce qui est masqué ou derrière, Échap au niveau du document.
- **M7 — Gel de 2,3 s.** Ouvrir un résultat de recherche dans un niveau de 70 cartes bloque le fil principal 2 347 ms, canevas blanc ; « Mise en page… » ne s'affiche jamais. `ux-11`. ELK tourne sur le fil principal (lu dans le code). → Worker, indicateur posé avant le calcul.
- **M8 — Santé en anglais, affirmation douteuse.** Les constats sortent en anglais (« 3 keys in … are probably fake ») dans une interface française. L'introduction affirme « ce projet utilise Supabase, Firebase, Stripe » (faux positif, supposé). `ux-16`. → Traduire les gabarits, fonder la détection sur les dépendances.
- **M9 — Coupure du serveur muette 5 minutes** (simulée : réseau coupé et crochet de perte de flux). La pastille « au travail » ne change ni de classe, ni de libellé, ni d'infobulle. La bannière n'arrive qu'à 300 s et reste après le retour du réseau, jusqu'au clic « Réessayer » (`ux-80`, `ux-81`). Au redémarrage réel (vu dans la console), la page se recharge seule ; l'adresse (niveau et sélection) est conservée, les tiroirs ouverts, le zoom et le transcript chargé ne le sont pas (supposé). → « Direct coupé » à 5 s, bannière à 15 s.
- **M10 — Terminal : absence muette, puis message trompeur.**
  - Sans `--terminal` : ni pastille ni section « Lancer du travail », aucune explication (`ux-01` contre `ux-18`).
  - Avec le drapeau, onglet ouvert à la main : « Terminal non disponible dans cet onglet — ne s'ouvre que depuis un cockpit lancé avec le terminal » (`ux-52`), alors que le serveur l'a. La vraie cause est l'amorce à usage unique de 60 s : l'onglet ne l'obtient jamais par lui-même. Le remède affiché est juste (relancer la commande réarme sans redémarrer).
  - Fermer le tiroir ne termine pas le shell (point de 6 px, `ux-62`) et aucun contrôle ne le permet.
  
  → Dire la cause, pastille désactivée et expliquée sans drapeau, action « Terminer la session ».
- **M11 — Bandeau de lancement rogné, état périmé.** À la hauteur par défaut, il prend 173 px sur 288 : la phrase « écrit cette ligne sans la lancer » est coupée, les modes sont sous le pli (`ux-60`). Après « Annuler », le panneau affiche toujours « Proposition envoyée… Confirmez-la » (`ux-61`). « Rien ne démarre avant votre confirmation » n'existe qu'en infobulle avant le clic. → Tiroir qui s'ajuste au bandeau, statut remis à zéro, phrase visible.
- **M12 — Tiroir Git étroit.** À 1024×768 les worktrees occupent tout : un seul commit visible (`ux-64`). Le détail s'ouvre en ligne sous le pli, sur 313 px (`ux-50`). Les sujets sont coupés vers 22 caractères. 653 rangées sont rendues d'un coup (9 138 nœuds, DOM × 7,5). → Worktrees repliés, détail dans l'inspecteur, liste virtualisée, largeur réglable.

### Mineur
- **m1** — Vocabulaire du Code sur le planning (« Élément », « module », « Utilisé par »). Le panneau d'un plan ou d'une exigence n'affiche ni statut ni vague (`ux-31`, `ux-33`). Même texte trois fois à l'écran (`ux-27`).
- **m2** — Backlog et Releases en vignettes à 8 px qui doublent la liste du panneau ; « DIFFÉRÉ » et « À faire » sur la même carte (`ux-34`, `ux-35`).
- **m3** — Le zoom « + » vise le centre de l'écran : la carte sélectionnée sort du champ (`ux-28`). `+`/`-` non documentés, pas d'aide `?`.
- **m4** — Deux anneaux de focus (jeton `--ring`, et bleu du navigateur sur onglets, fil d'Ariane, « Demander ») ; aucun sur le champ de question (`ux-75`). Pas d'`aria-current`, pas de `<main>`.
- **m5** — Thème clair : carte active grise (#f1f1ef sur #f3f3f1), lue comme désactivée (`ux-48`). Glyphe « En cours » à 3,01:1 ; cartes estompées en sombre à 2,97:1.
- **m6** — Mouvement réduit : la plongée garde son fondu (0,5 s), 23 animations actives.
- **m7** — Trois formats de `<title>`. Le tiroir Git se ferme au changement d'onglet (rechargement complet, 2,5 à 3,6 Mo).
- **m8** — Téléphone : zoom et pastille Terminal recouvrent la carte sélectionnée (`ux-67`) ; onglets hauts de 26 px.

### Finition
Triangles natifs de `<details>` et `<select>` natif du bandeau ; trois styles de bouton dans le panneau Équipe ; bouton thème de 44 px parmi des 36 ; chiffres mono dans des phrases en sans (« 19 s ») ; pastilles ambre et verte au bureau, noires au téléphone ; « Verifie » sans accent dans la commande ; historique du terminal perdu au changement d'onglet.

## C. Direction artistique
- **Hiérarchie** : le même titre apparaît trois fois (fil d'Ariane, H1 flottant, panneau), la description deux. Les paliers de zoom grossissent méta et pastille, pas le titre.
- **Densité** : deux extrêmes. Canevas vide à 70-95 %, panneau en murs de prose (ROADMAP recopié). Les écarts de 130 px font la largeur, donc l'échelle.
- **Typographie** : Inter et JetBrains Mono bien tenus, deux graisses. La troncature coupe la partie qui distingue (« 72-04 — Poser le… »).
- **Couleur et états** : le couple glyphe + mot est la signature la plus solide. En sombre tout tient (6 à 15:1). En clair, « actif = gris » inverse le signal. Seules couleurs libres : liens violets et barre de langages arc-en-ciel, héritées du moteur.
- **Mouvement** : le fondu de plongée (≈ 600 ms) et la caméra de la visite ont du caractère. Le gel de 2,3 s et le zoom qui perd la sélection le défont.
- **Iconographie** : trois faux amis — « fichier » pour sessions et agents, ▶ pour « Parcours », roue pour « récent ».
- **Cohérence entre onglets** : jeu d'icônes variable (9 ou 7), santé contradictoire, « Demander » et terminal absents d'Équipe.
- **Générique** : la grille de cartes sur fond pointillé, pour tout.
- **Caractère** : le graphite sombre, les glyphes d'état, le tiroir Git « lecture seule, chaque action est une commande à copier », le lancement en deux temps.

## D. Dix idées
1. **Feuille de route en couloirs** : phases en colonnes par état, barre d'avancement par jalon. Le projet se lit d'un regard, à toute largeur.
2. **Palette de commandes (⌘K)** : nœuds, phases, agents et actions dans un seul champ. Le clavier atteint tout.
3. **Frise d'équipe** : une ligne par agent, outils en repères, curseur temporel. On voit qui fait quoi, depuis quand.
4. **Mode focus** : sélectionner recompose le seul voisinage, à échelle lisible. Fin du « sélectionner puis zoomer ».
5. **Minicarte et repères de bord** (« 16 cartes → »). On ne se perd plus.
6. **Bascule liste/tableau (touche `v`)** à chaque niveau, triable. Défaut au téléphone ; les exigences se lisent comme une liste à cocher.
7. **Lecteur de transcript plein cadre** : fil horodaté, filtres messages/outils/erreurs, suivi en direct.
8. **Barre d'état en pied** : branche entière, état du direct, shell vivant avec « Terminer », dernière actualisation. La confiance sans chercher.
9. **Onglets sans rechargement et liens de vue** : tiroirs et zoom conservés, « copier le lien de cette vue ».
10. **« Depuis votre dernière visite »** : phases qui ont changé d'état, commits, agents terminés. Le cockpit devient un rendez-vous.

## Observé ou supposé
- **Supposé** : faux positif Supabase/Firebase/Stripe ; ce que le rechargement fait perdre (tiroirs, zoom, transcript) ; cause de la fin du PTY (onglet fermé).
- **Lu dans le code, non observé** : ELK sur le fil principal ; délais 1 s, 5 s, 300 s ; une session de terminal bloque l'arrêt sur inactivité.

## Captures (85)
```
ux-01-code-defaut-1440.png
ux-02-code-module-selectionne.png
ux-03-entete-clair-1440.png
ux-04-code-plongee-cockpit.png
ux-05-code-plongee-ajuste-F.png
ux-06-code-plongee-panneau-ferme.png
ux-07-code-recherche-vide.png
ux-08-code-recherche-terminal.png
ux-09-code-recherche-aucun-resultat.png
ux-10-code-recherche-focus-echappe.png
ux-11-code-resultat-ouvert.png
ux-12-code-resultat-ouvert-stable.png
ux-13-code-ensemble-apres-remontee.png
ux-14-code-types-de-liens.png
ux-15-code-parcours.png
ux-16-code-sante.png
ux-17-code-travail-recent.png
ux-18-code-avec-terminal-clair.png
ux-19-code-sombre-1440.png
ux-20-code-au-travail-sombre.png
ux-21-code-visite-etape1-sombre.png
ux-22-code-visite-etape2-sombre.png
ux-22-code-visite-etape3-sombre.png
ux-22-code-visite-etape4-sombre.png
ux-23-code-clic-droit-sombre.png
ux-24-code-export-sombre.png
ux-25-projet-defaut-clair-1440.png
ux-26-projet-jalon-selectionne-clair.png
ux-27-projet-jalon-v2-plonge-clair.png
ux-28-projet-phases-zoomees-clair.png
ux-29-projet-phase72-lancer-panneau-clair.png
ux-30-projet-phase72-plongee-clair.png
ux-31-projet-plan-72-09-clair.png
ux-32-projet-exigences-plongee-clair.png
ux-33-projet-exigence-detail-clair.png
ux-34-projet-backlog-clair.png
ux-35-projet-releases-clair.png
ux-36-projet-defaut-sombre-1440.png
ux-37-projet-cartes-zoom-molette-sombre.png
ux-38-projet-cartes-lisibles-sombre.png
ux-39-equipe-defaut-sombre-1440.png
ux-40-equipe-session-selectionnee-sombre.png
ux-41-equipe-session-activite-sombre.png
ux-42-equipe-transcript-sombre.png
ux-43-equipe-session-plongee-sombre.png
ux-44-equipe-clic-droit-sombre.png
ux-45-equipe-agent-detail-sombre.png
ux-46-equipe-agent-transcript-sombre.png
ux-47-equipe-session-plongee-clair.png
ux-48-equipe-defaut-clair-1440.png
ux-49-git-tiroir-clair-1440.png
ux-50-git-detail-commit-clair.png
ux-51-git-detail-commit-defile-clair.png
ux-52-terminal-ouvert-clair-1440.png
ux-53-terminal-agrandi-glisser-clair.png
ux-54-terminal-hauteur-max-clair.png
ux-55-terminal-plein-ecran-clair.png
ux-56-terminal-session-clair.png
ux-57-terminal-echo-test-clair.png
ux-58-terminal-session-sombre.png
ux-59-lancer-avant-clic-sombre.png
ux-60-lancer-bandeau-proposition-sombre.png
ux-61-lancer-apres-annulation-sombre.png
ux-62-terminal-ferme-session-en-cours-sombre.png
ux-63-1024-code-clair.png
ux-63-1024-equipe-clair.png
ux-63-1024-projet-clair.png
ux-64-1024-projet-git-clair.png
ux-65-1024-projet-terminal-clair.png
ux-66-tel-code-clair.png
ux-67-tel-code-carte-touchee-clair.png
ux-68-tel-menu-plus-clair.png
ux-69-tel-projet-clair.png
ux-70-tel-projet-jalon-touche-clair.png
ux-71-tel-projet-jalon-plonge-clair.png
ux-72-tel-equipe-clair.png
ux-73-tel-git-clair.png
ux-74-tel-terminal-clair.png
ux-75-clavier-focus-demander-clair.png
ux-76-clavier-focus-panneau-ferme-clair.png
ux-77-clavier-palette-focus-echappe-clair.png
ux-78-coupure-avant-clair.png
ux-79-coupure-4s-clair.png
ux-80-coupure-flux-perdu-clair.png
ux-81-coupure-banniere-clair.png
```
