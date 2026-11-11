# Panel d'utilisateurs — onglet Code et coque (2026-11-06)

Mission : faire juger la version du cockpit validée pour la release par des juges indépendants, chacun dans la peau d'un utilisateur potentiel. Demande de Samuel, message direct en session principale, 2026-11-06. Ce manager est l'un des trois du panel ; les deux autres couvrent « onglet Projet » et « Équipe, Au travail, tiroir Git, terminal ». Rien n'a été trié ni écarté : toutes les propositions des juges sont dans la liste.

## Conditions du panel

- **Version jugée** : worktree cockpit-final, branche integration/cockpit-final, HEAD a95c018d (vérifié par git rev-parse), cockpit v1.4.0. Lu en lecture seule.
- **Lab** : un clone local de ce dépôt à a95c018d, posé dans le scratchpad sous le nom vibeflow-os. Il a un état Git réel : 2 fichiers modifiés (.planning/BACKLOG.md et plugin/cockpit/scripts/vf-cockpit-port.mjs), 1 fichier non suivi (notes-brouillon.txt) et un second worktree (feat/essai-panel). Le cockpit annonce « Code 782 fichiers (576 décrits sans modèle), Projet 180 cartes ». **Écart avec le brief** : le brief annonçait plus de 1 300 fichiers côté Code. Le dépôt en suit 2 867 (git ls-files), mais le cockpit n'en retient que 782. Le lab reste riche et réel, mais ce n'est pas le chiffre attendu.
- **Serveur** : un cockpit propre au panel, sur le port 4790, lancé avec --terminal. Ni le port 4456 ni la sortie de Samuel n'ont été touchés. Le serveur a été arrêté en fin de mission.
- **Juges** : quatre agents à contexte frais, dispatchés en parallèle. Chacun avait son propre Chromium (Playwright 1.60 du scratchpad) et ne voyait ni les autres juges ni les attentes du manager. Consignes communes : scratchpad/panel-code/consignes-communes.md. Interdits : envoyer une question, lancer un agent, taper dans le terminal, écrire dans le lab, lire le code du cockpit.
- **Quatrième profil ajouté (mobile, téléphone et tablette au doigt)** : la surface couvre la coque de 390 à 1 440 px. Les trois autres profils travaillent sur portable et ne passent par 390 px qu'en curiosité, à la souris. Sans ce profil, le tactile réel (pointer: coarse, tap, pincement), le paysage du téléphone et les tablettes de 768 et 1 000 px n'auraient été jugés par personne.

### Barème (identique pour les quatre juges, à reprendre tel quel par les deux autres managers)

| Critère | Points | Question posée au juge |
|---|---|---|
| Utilité pour le profil | /30 | Est-ce que ça t'aide à faire ce que TU veux faire ici ? |
| Lisibilité | /25 | Comprends-tu ce que tu regardes, sans effort, à chaque largeur et dans les deux thèmes ? |
| Confiance | /25 | L'outil te paraît-il juste, fiable, sérieux ; crois-tu ce qu'il affiche ? |
| Finition | /20 | Détails, alignements, états (survol, focus, vide, chargement), cohérence entre largeurs et thèmes |

**Captures** : <scratchpad>/panel-code/captures/<profil>/, soit dev (58 fichiers), lab (42), nouveau (41) et mobile (43). Le scratchpad est vidé au redémarrage de la machine : copier ce dossier s'il doit servir aux tâches rapides.

## Notes et avis des juges

| Juge | Utilité /30 | Lisibilité /25 | Confiance /25 | Finition /20 | **Total** |
|---|---|---|---|---|---|
| Développeur | 15 | 14 | 12 | 12 | **53** |
| Responsable de lab non développeur | 17 | 12 | 12 | 13 | **54** |
| Nouvel arrivant | 17 | 12 | 11 | 12 | **52** |
| Mobile (téléphone et tablette au doigt) | 17 | 12 | 16 | 10 | **55** |
| **Moyenne** | 16,5 | 12,5 | 12,75 | 11,75 | **53,5** |

**Développeur (53)** : « La recherche / et le tiroir Git sont rapides et justes. Mais l'outil ne me dit pas en dix secondes où en est mon dépôt : l'en-tête n'affiche que la branche, et la pastille "modifiés" sur la carte ne veut pas dire "modifié dans Git". Elle m'a menti deux fois. »
- Ce qui l'a aidé : la recherche au clavier, le panneau de détail (chemin copiable, lien vers l'éditeur, nombre de lignes exact), le tiroir Git (vérifié exact contre git status), les raccourcis + − F P, le retour arrière et l'URL profonde.
- Ce qui l'a perdu : un fichier modifié introuvable à la recherche (BACKLOG.md), les homonymes sans chemin, les cartes inaccessibles au clavier, Échap qui se comporte différemment selon l'endroit, les compteurs incohérents.

**Responsable de lab (54)** : « C'est joli et bien rangé, et le "Travail récent" me dit vraiment ce qui a bougé. Mais dès que j'ouvre une carte je tombe sur des mots d'ingénieur, des morceaux d'anglais et même un écran qui n'existe pas : je ne saurais pas l'expliquer à mon équipe sans un développeur à côté. »
- Ce qui l'a aidé : la visite guidée, la définition au survol de « route », Travail récent par phase, le menu du clic droit.
- Ce qui l'a gêné : le jargon non expliqué, l'impossibilité de lire le contenu d'un fichier, et une alerte de santé qui fait peur.

**Nouvel arrivant (52)** : « Ça a l'air soigné et sérieux au premier coup d'œil, et la recherche est excellente. Mais la carte d'ouverture est un plat de spaghettis illisible. Dès que je creuse, je tombe sur de l'anglais, des chiffres qui ne collent pas et une "santé" qui m'alarme pour ce qui ressemble à de faux secrets de test. J'hésiterais à l'installer tel quel. »
- Sa réaction à chaud à l'ouverture : « propre et calme », mais pas d'entrée évidente, et dix icônes muettes.

**Mobile (55)** : « Au téléphone en portrait, je retrouve un fichier et je lis son détail sans peine grâce à la loupe et à la feuille du bas. En revanche la carte reste un timbre-poste illisible, et en paysage l'écran devient inutilisable. »
- Ce qui l'a aidé : la recherche, la feuille de détail, le menu « ⋯ » (lignes de 44 px) et les boutons de zoom à 44 px.
- Ce qui l'a gêné : les noms de cartes rendus à 2,9 px, la poignée de feuille décorative, les aides clavier affichées sur un écran tactile, et le paysage et la tablette de 768 px mal servis.

Rapports intégraux des juges : rendus au manager dans leurs messages de fin. Leurs points sont tous repris ci-dessous ; les captures citées sont celles des juges.

## Propositions dédupliquées

Profils : **D** développeur, **L** responsable de lab, **N** nouvel arrivant, **M** mobile. Taille : **réglage** = un commit ; **plus** = plusieurs commits, ou une donnée ou un parseur à revoir. Drapeau : ⚑ = contredit ou touche DESIGN.md (direction Graphite) ou un arbitrage déjà rendu par Samuel, à trancher par lui. Une proposition qui rapproche l'existant de DESIGN.md est signalée « écart constaté ».

### A. Carte du code (vue d'ensemble et vue d'un module)

| Id | Élément et écran | Changement demandé | Profils | Capture | Taille | Drapeau |
|---|---|---|---|---|---|---|
| PU-CODE-01 | Carte de la vue d'ensemble à l'ouverture, toutes largeurs | Zoom initial plancher qui garde les noms de cartes à 11-12 px au moins, quitte à ne pas tout montrer. Aujourd'hui ils font environ 7 px à 1 440, 4 px à 1 000 et 2,9 px à 390. | D L N M | <scratchpad>/panel-code/captures/nouveau/01-ouverture-1440.png · <scratchpad>/panel-code/captures/dev/30-accueil-1000-clair.png · <scratchpad>/panel-code/captures/mobile/03-carte-sans-visite-390-clair.png | réglage (plus si la disposition doit changer) | |
| PU-CODE-02 | Traits de liaison de la vue d'ensemble, toutes largeurs | Les atténuer fortement, ou les masquer au repos, et ne les montrer qu'au survol ou à la sélection | L N | <scratchpad>/panel-code/captures/lab/24-1000-sombre-retour-carte.png · <scratchpad>/panel-code/captures/nouveau/01-ouverture-1440.png | réglage | |
| PU-CODE-03 | Cartes non sélectionnées pendant une sélection, thème sombre, 1 440 | Moins les atténuer, pour que leurs noms restent lisibles | D N | <scratchpad>/panel-code/captures/dev/23-vue-ensemble-sombre-1440.png · <scratchpad>/panel-code/captures/nouveau/22-sombre-clic-cockpit-1440.png | réglage | |
| PU-CODE-04 | Cartes au clavier, 1 440 | Rendre les cartes atteignables par Tab, déplacer la sélection aux flèches, ouvrir avec Entrée | D L | <scratchpad>/panel-code/captures/dev/14-focus-noeud-1440.png · <scratchpad>/panel-code/captures/lab/36-1440-focus-clavier.png | plus | |
| PU-CODE-05 | Molette sur la carte, 1 366 | Zoomer seulement avec Ctrl ou au pincement et faire défiler sinon, ou zoomer plus doucement | L | <scratchpad>/panel-code/captures/lab/17-types-de-liens.png | réglage | |
| PU-CODE-06 | Bouton « Ajuster à l'écran » (en bas à gauche), 1 440 | Ajuster en gardant les noms lisibles, ou proposer « Ajuster à la sélection » | N | <scratchpad>/panel-code/captures/nouveau/14-detail-technique-ajuste-1440.png | réglage | |
| PU-CODE-07 | Carte au téléphone, 390, deux thèmes | Sous environ 600 px, ouvrir par défaut sur une vue liste des ensembles (le contenu du panneau « Base de code »), avec la carte en option | M N | <scratchpad>/panel-code/captures/mobile/03-carte-sans-visite-390-clair.png · <scratchpad>/panel-code/captures/nouveau/24-sombre-390-clic-carte.png | plus | |
| PU-CODE-08 | Zones tactiles de la carte, 390 | Donner la priorité au toucher d'une carte sur celui d'un lien, et agrandir la zone de toucher des cartes | N | <scratchpad>/panel-code/captures/nouveau/24-sombre-390-clic-carte.png | réglage | |
| PU-CODE-09 | Info-bulle de survol d'une carte, 1 440, sombre | La masquer dès que la carte se décale (ouverture du panneau, clic). Aujourd'hui elle reste sur README.md alors que le panneau montre README.fr.md | D | <scratchpad>/panel-code/captures/dev/40-readme-racine-panneau-sombre.png | réglage | |
| PU-CODE-10 | Info-bulle d'un module au bord droit (« _internal »), 1 440 | La placer à gauche de la carte quand le panneau de détail la masquerait | D | <scratchpad>/panel-code/captures/dev/06-survol-noeud-1440.png | réglage | |
| PU-CODE-11 | Zone sous l'en-tête, 1 440 et 1 000, deux thèmes | Empêcher la carte de passer sous la barre d'en-tête transparente, ou donner un fond opaque à l'en-tête | D | <scratchpad>/panel-code/captures/dev/12-entete-chevauchement-1440.png · <scratchpad>/panel-code/captures/dev/49-fichier-1000-sombre.png | réglage | ⚑ DESIGN §5 : panneaux en verre (--elev). Un fond opaque d'en-tête est à confirmer |
| PU-CODE-12 | Titre et description d'un module ouvert, 1 000 à 1 440 et 390 | Limiter la description à 2 ou 3 lignes avec « Lire la suite », ou décaler le cadre de la carte. Aujourd'hui elle recouvre la carte « Skills », les titres de colonnes et le trait « Dans … ». À 390, transformer le « Plus » nu en vrai bouton | L D M | <scratchpad>/panel-code/captures/lab/30-1000-clair-content-bundle-panneau.png · <scratchpad>/panel-code/captures/dev/21-readme-ouvert-1440.png · <scratchpad>/panel-code/captures/mobile/08-apres-ouvrir-390-clair.png | réglage | |
| PU-CODE-13 | Carte « Skills » d'un module ouvert (design-orchestrator), 1 366, sombre | La ranger dans la colonne « Dans … » et non sous « Utilisé par ». Agrandir les titres de colonnes, qui font environ 6 px | L | <scratchpad>/panel-code/captures/lab/40-1366-sombre-design-orchestrator.png | réglage | |
| PU-CODE-14 | Bloc titre de page au-dessus de la carte, 390 (sous-vue Scripts) | Fond sous le titre, ou carte qui commence sous lui. Aujourd'hui « Gates, moteurs et outils en shell. » se superpose à la carte « Notify » | M N | <scratchpad>/panel-code/captures/mobile/14-fichier-driver-lock-detail-390-clair.png · <scratchpad>/panel-code/captures/nouveau/27-sombre-390-fichier-ouvert.png | réglage | ⚑ si la solution est un dégradé : DESIGN §9 interdit le dégradé décoratif |
| PU-CODE-15 | Mot souligné « route » du sous-titre, 390 tactile | Placer le sous-titre au-dessus du SVG, pour que le toucher ouvre la définition | M | <scratchpad>/panel-code/captures/mobile/34-tap-mot-route-390-clair.png | réglage | |

### B. Justesse des données affichées (confiance)

| Id | Élément et écran | Changement demandé | Profils | Capture | Taille | Drapeau |
|---|---|---|---|---|---|---|
| PU-CODE-16 | Bouton « Écrans » de l'en-tête, 1 280 et 1 440 | Ne rien proposer quand le dépôt a 0 route, et afficher « Aucun écran détecté dans ce dépôt ». Aujourd'hui « /products/:id » est proposé alors que l'en-tête dit « 0 route » ; c'est vraisemblablement un commentaire de code vendorisé lu comme une route, origine à diagnostiquer | D L N | <scratchpad>/panel-code/captures/dev/44-ecrans-sombre-1280.png · <scratchpad>/panel-code/captures/lab/33-1440-ecrans-clic.png · <scratchpad>/panel-code/captures/nouveau/18-ecrans-1440.png | réglage (plus si c'est le parseur) | |
| PU-CODE-17 | Vue « Écran : Écrans » ouverte, 1 440 | Traduire « Everything behind… » et « The screen itself ». Ne pas prendre le pragma « vibeflow:allow-large-file… » pour un résumé | L N | <scratchpad>/panel-code/captures/lab/35-1440-ecran-products-id.png · <scratchpad>/panel-code/captures/nouveau/20-ecran-products-id-1440.png | réglage | |
| PU-CODE-18 | Badge « 44 » de Travail récent contre « Travail récent · 24 cartes », toutes largeurs (dont le menu « ⋯ » à 390) | Afficher le même nombre aux deux endroits, ou expliquer l'écart (« 44 changements sur 24 fichiers ») | D L N M | <scratchpad>/panel-code/captures/dev/42-travail-recent-sombre-1440.png · <scratchpad>/panel-code/captures/lab/38-1280-sombre-bouton-travail-recent.png · <scratchpad>/panel-code/captures/nouveau/17-travail-recent-1440.png · <scratchpad>/panel-code/captures/mobile/26-travail-recent-390-sombre.png | réglage | |
| PU-CODE-19 | Pastilles « N modifiés » des modules et « Modifié » des fichiers, toutes largeurs | Renommer ce qui veut dire « touché par une phase récente » (« récent », « touché par 60/61 ») et réserver « modifié » à l'état Git réel, avec un repère distinct. Aujourd'hui deux README propres dans Git sont marqués « Modifié », et le fichier réellement modifié ne l'est nulle part | D N (L s'en sert, voir Désaccords) | <scratchpad>/panel-code/captures/dev/38-racine-sombre-1440.png · <scratchpad>/panel-code/captures/nouveau/31-clair-1440-tiroir-git.png | réglage pour le libellé, plus pour le repère Git | ⚑ Le repère Git doit suivre l'arbitrage « glyphe + mot en texte neutre », sans fond ni liseré coloré |
| PU-CODE-20 | Compteur de « conductor » : « 10 modifiés » sur la carte, « 11 » dans le panneau, 1 280, clair | Aligner les deux compteurs | D | <scratchpad>/panel-code/captures/dev/47-conductor-selection-1280-clair.png | réglage | |
| PU-CODE-21 | Statistiques et libellés du détail d'un fichier quand on active « détail technique », 1 440 | Garder les mêmes statistiques et les mêmes libellés : « 56 utilisé par » devient « 0 exports », « Utilise » devient « Importations » | N L | <scratchpad>/panel-code/captures/nouveau/14-detail-technique-ajuste-1440.png · <scratchpad>/panel-code/captures/lab/18-detail-technique-on.png | réglage | |
| PU-CODE-22 | Panneau de droite après Échap sur Travail récent, ou après un clic sur « Vue d'ensemble », 1 440 | Remettre le panneau « Base de code » dès que la carte revient à la vue d'ensemble. Aujourd'hui il reste sur « Travail récent » ou sur « Answer / Écrans » | N | <scratchpad>/panel-code/captures/nouveau/21-sombre-vue-ensemble-1440.png · <scratchpad>/panel-code/captures/nouveau/18-ecrans-1440.png | réglage | |
| PU-CODE-23 | Panneau de détail d'un fichier, sous le chemin, 1 440 | Afficher l'état Git du fichier (modifié, non suivi, +1 −0) | D | <scratchpad>/panel-code/captures/dev/11-fichier-ouvert-1440.png | plus | ⚑ même règle que PU-CODE-19 (glyphe + mot neutre) |
| PU-CODE-24 | Recherche « / », 1 440 | Indexer .planning/ et les fichiers de la racine, ou au moins tous les fichiers modifiés dans Git. Aujourd'hui « BACKLOG.md », pourtant modifié, ne donne « Aucun résultat » | D | <scratchpad>/panel-code/captures/dev/19-rech-0.png | plus | |
| PU-CODE-25 | Panneau Contrôle de santé, titre, 1 440 | Faire concorder « 4 points à traiter » avec la somme de la légende (3 + 1 + 1 = 5) | N | <scratchpad>/panel-code/captures/nouveau/15-sante-1440.png | réglage | |
| PU-CODE-26 | Panneau Contrôle de santé, tous les constats | Tout traduire en français, y compris la phrase qui bascule en anglais au milieu (« …dans Claude Code ; it checks the code before changing anything ») | D L N | <scratchpad>/panel-code/captures/dev/41-sante-sombre-1440.png · <scratchpad>/panel-code/captures/lab/37-1440-controle-sante.png · <scratchpad>/panel-code/captures/nouveau/16-sante-suite-1440.png | réglage | |
| PU-CODE-27 | Contrôle de santé, alertes « secrets » | Signaler quand le fichier est un test ou une fixture (« probablement factice ») et baisser le ton (« get into AWS as you » sur test-cockpit-securite.sh) | L N | <scratchpad>/panel-code/captures/lab/37-1440-controle-sante.png · <scratchpad>/panel-code/captures/nouveau/16-sante-suite-1440.png | plus | |
| PU-CODE-28 | Contrôle de santé, conseils « very large » et « unused » | Exclure les fichiers tiers (dossier vendor, *.bundled.js) des conseils « découper » et « supprimer » | N | <scratchpad>/panel-code/captures/nouveau/16-sante-suite-1440.png | réglage | |
| PU-CODE-29 | Contrôle de santé, texte d'introduction | Ne citer Supabase, Firebase ou Stripe que si le dépôt les utilise | N | <scratchpad>/panel-code/captures/nouveau/15-sante-1440.png | réglage | |

### C. Langue, libellés et contenus

| Id | Élément et écran | Changement demandé | Profils | Capture | Taille | Drapeau |
|---|---|---|---|---|---|---|
| PU-CODE-30 | Module « Unassigned » sur la carte et dans le panneau | Le nommer « Non classés » ou « Non rattachés » et remplacer « Files no node claims. Add globs in architecture.json… » par une phrase simple en français | D L N | <scratchpad>/panel-code/captures/lab/31-1440-clair-unassigned.png · <scratchpad>/panel-code/captures/nouveau/03-panneau-fin-1440.png | réglage | |
| PU-CODE-31 | Info-bulle de survol d'un module | « Readme and 7 more » devient « Readme et 7 autres » | D L N | <scratchpad>/panel-code/captures/nouveau/04-survol-conductor-1440.png · <scratchpad>/panel-code/captures/lab/03-module-conductor-clair.png | réglage | |
| PU-CODE-32 | Vue « Travail récent : Phase 61 », titre et panneau | « You asked: » devient « Vous avez demandé : », comme sur l'accueil | L N | <scratchpad>/panel-code/captures/nouveau/33-clair-1440-afficher-17-cartes.png · <scratchpad>/panel-code/captures/lab/22-sombre-afficher-cartes.png | réglage | |
| PU-CODE-33 | « Vous avez demandé » dans Travail récent et dans la fiche d'un fichier | Écrire « Demande d'origine », avec la personne ou la date | L | <scratchpad>/panel-code/captures/lab/09-readme-selection.png | réglage | |
| PU-CODE-34 | Feuille du bas « Calls connection / 9 connections », 390 | Traduire (« Appels entre modules · 9 liens ») | N | <scratchpad>/panel-code/captures/nouveau/24-sombre-390-clic-carte.png | réglage | |
| PU-CODE-35 | Descriptions de fichiers générées en anglais (« Fallback human-readable names… », « Show the map to the user… ») | Les produire et les afficher en français | N | <scratchpad>/panel-code/captures/nouveau/27-sombre-390-fichier-ouvert.png | plus | |
| PU-CODE-36 | Chiffres de l'info-bulle et du panneau | Écrire « 1,3 k », « 115 fichiers · 48 k lignes » (sans majuscule) et « 1 ligne » au singulier | D L | <scratchpad>/panel-code/captures/lab/31-1440-clair-unassigned.png · <scratchpad>/panel-code/captures/dev/07-survol-conductor-1440.png | réglage | |
| PU-CODE-37 | Résumés de fichiers (carte, recherche, panneau) | Retirer le « > » initial et ne jamais afficher de HTML brut (« <picture> <source… ») | D L | <scratchpad>/panel-code/captures/lab/15-resultat-design-ouvert.png · <scratchpad>/panel-code/captures/dev/40-readme-racine-panneau-sombre.png | réglage | |
| PU-CODE-38 | Description d'un fichier dans la feuille de détail, 390 | Afficher une description propre (accents, casse) ou la marquer « extrait brut ». Aujourd'hui on lit « Empeche … MEME etape » | M | <scratchpad>/panel-code/captures/mobile/17-fichier-apres-tap-carte-390-clair.png | réglage | |
| PU-CODE-39 | Homonymes dans la recherche, les cartes de Travail récent et « Utilisé par » | Afficher le dossier parent sous le nom (« Readme · growth-bundle ») quand plusieurs éléments portent le même nom | D L N | <scratchpad>/panel-code/captures/dev/19-rech-3.png · <scratchpad>/panel-code/captures/lab/14-recherche-design.png · <scratchpad>/panel-code/captures/nouveau/33-clair-1440-afficher-17-cartes.png | réglage | |
| PU-CODE-40 | Ligne de résultat de la recherche | Afficher en titre le vrai nom de fichier (vf-cockpit-port.mjs plutôt que « Vf cockpit port ») et le dossier à droite, à la place du mot « fichier » | D | <scratchpad>/panel-code/captures/dev/17-recherche-vfcockpit-1440.png | réglage | |
| PU-CODE-41 | Mots du panneau d'un module sans définition (dispatch, gates, Skills, Trouvé par, points d'accès, Appels, shell, hook) | Les ajouter au glossaire au survol, comme « route » et « scripts » | L | <scratchpad>/panel-code/captures/lab/04-module-conductor-panneau-bas.png | plus | |
| PU-CODE-42 | Ligne « Trouvé par #v1.53.2 » ou « #v1.4.0 » du panneau | L'expliquer (« détecté via le tag v1.4.0 ») ou la masquer hors du détail technique | L N | <scratchpad>/panel-code/captures/lab/04-module-conductor-panneau-bas.png · <scratchpad>/panel-code/captures/nouveau/22-sombre-clic-cockpit-1440.png | réglage | |
| PU-CODE-43 | Type « Service » affiché pour les modules | Écrire « Module », ou un type plus parlant | L | <scratchpad>/panel-code/captures/lab/27-1000-clair-survol-content-bundle.png | réglage | |
| PU-CODE-44 | Section « Dépend de 56 » et « Appels » de la fiche d'un document (Readme) | Pour un document, écrire « Mentionne », avec une phrase d'explication | L | <scratchpad>/panel-code/captures/lab/10-readme-panneau-bas.png | réglage | |
| PU-CODE-45 | Description d'un module dans le panneau | Commencer par une phrase « En clair : à quoi ça sert », avant la description technique | L | <scratchpad>/panel-code/captures/lab/30-1000-clair-content-bundle-panneau.png | plus | |
| PU-CODE-46 | Mot « branche » dans la ligne sous le nom du dépôt et dans le titre « Le code, branche … » | Écrire « Version de travail : … », avec une définition de « branche » au survol | L | <scratchpad>/panel-code/captures/lab/01-accueil-1366-clair.png | réglage | voir Désaccords (D veut plus de vocabulaire Git) |
| PU-CODE-47 | Encart « 206 fichiers… Relancez le skill pour les décrire » du panneau Base de code | Nommer le skill et la commande, avec un bouton « copier la commande », et expliquer « noms générés » | L N | <scratchpad>/panel-code/captures/lab/01-accueil-1366-clair.png · <scratchpad>/panel-code/captures/nouveau/01-ouverture-1440.png | réglage | |
| PU-CODE-48 | Cartes de phase de Travail récent dans le panneau | Afficher la date ou l'ancienneté de chaque phase et de chaque modification | L | <scratchpad>/panel-code/captures/lab/01-accueil-1366-clair.png | plus | |
| PU-CODE-49 | Fiche d'un fichier (DESIGN.md) | Ajouter un aperçu lisible du contenu, en plus de « Ouvrir dans l'éditeur » | L | <scratchpad>/panel-code/captures/lab/15-resultat-design-ouvert.png | plus | |

### D. Visite guidée « Par où commencer »

| Id | Élément et écran | Changement demandé | Profils | Capture | Taille | Drapeau |
|---|---|---|---|---|---|---|
| PU-CODE-50 | Toutes les étapes, toutes largeurs | Zoomer et centrer la carte sur l'élément présenté, et placer la bulle hors de lui. À l'étape 3, la bulle cache aujourd'hui dev-orchestrator au téléphone | D N M L | <scratchpad>/panel-code/captures/dev/29-visite-3-1280.png · <scratchpad>/panel-code/captures/nouveau/06-visite-etape2-1440.png · <scratchpad>/panel-code/captures/mobile/02-visite-etape3-390-clair.png | réglage ou plus | |
| PU-CODE-51 | Déclenchement de la visite | La lancer de façon fiable au premier chargement : chez N, elle n'est apparue qu'au deuxième. Ne plus l'ouvrir d'office ensuite, ou proposer « ne plus montrer » | N D | <scratchpad>/panel-code/captures/nouveau/06-visite-etape2-1440.png · <scratchpad>/panel-code/captures/dev/01-accueil-1440.png | réglage | voir Désaccords |
| PU-CODE-52 | Étape 3 « dev-orchestrator » | Remplacer le jargon (gsd-*, superpowers, first-use) par une phrase pour débutant | N | <scratchpad>/panel-code/captures/nouveau/06-visite-etape3-1440.png | réglage | |
| PU-CODE-53 | Étape 4 | Montrer réellement le bouton qui relance la visite et « Écrans », et cadrer les services extérieurs (Claude Code, GSD) plutôt que le titre | L N M | <scratchpad>/panel-code/captures/lab/02-visite-etape4.png · <scratchpad>/panel-code/captures/nouveau/06-visite-etape4-1440.png · <scratchpad>/panel-code/captures/mobile/02-visite-etape4-390-clair.png | réglage | |
| PU-CODE-54 | Bulle de visite au téléphone, 390 | En faire une feuille pleine largeur en bas, avec « Étape 1 sur 4 » sur une seule ligne (aujourd'hui « 1 / sur / 4 » sur trois lignes) | M | <scratchpad>/panel-code/captures/mobile/01-accueil-390-clair.png | réglage | |
| PU-CODE-55 | Cadre noir épais autour du bloc « Le code, branche … », au chargement et aux étapes 1 et 4 | Le supprimer, ou en faire une mise en évidence expliquée ; il est lu comme un focus parasite. Il oblige aussi à appuyer deux fois sur Échap (voir PU-CODE-64) | D N M (L : « le cadre reste sur le titre ») | <scratchpad>/panel-code/captures/dev/29-visite-4-1280.png · <scratchpad>/panel-code/captures/nouveau/04-survol-conductor-1440.png · <scratchpad>/panel-code/captures/mobile/02-visite-etape4-390-clair.png | réglage | écart constaté : DESIGN §4 nomme un « halo du titre », l'arbitrage récent dit « pas de halo » ; le retrait va dans le sens de l'arbitrage |

### E. Coque : en-tête, onglets, thèmes, clavier

| Id | Élément et écran | Changement demandé | Profils | Capture | Taille | Drapeau |
|---|---|---|---|---|---|---|
| PU-CODE-56 | Ligne Git sous « vibeflow-os », 1 280 à 1 440, deux thèmes | Ajouter à la branche un résumé « 2 M · 1 ? · ↑274 » et un repère « +1 worktree » | D | <scratchpad>/panel-code/captures/dev/02-header-zoom-1440.png | réglage ou plus | ⚑ Arbitrage : seconde ligne plafonnée à 220 px |
| PU-CODE-57 | En-tête du téléphone, 390 | Ajouter sous le titre une ligne Git compacte (« 2 modifiés · 1 non suivi · ↑274 ») qui ouvre l'historique Git au toucher | M | <scratchpad>/panel-code/captures/mobile/03-carte-sans-visite-390-clair.png | réglage | ⚑ Arbitrage : seconde ligne masquée sous 1 280 px |
| PU-CODE-58 | Nom du dépôt, branche et « Vue d'ensemble » à 1 000, 1 100, 1 280 (sous-vue) et 768 | Ne jamais tronquer le nom du dépôt (« vibef… ») ni « Vue d'ensemble » (« V… », « Vue d'ensem… », réduit à 16 px de large à 1 000). Priorité : nom du dépôt, puis branche, puis fil d'Ariane | D L N M | <scratchpad>/panel-code/captures/lab/26-1000-clair-panneau-masque-ajuste.png · <scratchpad>/panel-code/captures/nouveau/23-sombre-1000.png · <scratchpad>/panel-code/captures/mobile/23-detail-tablette-1000-clair.png · <scratchpad>/panel-code/captures/dev/43-parcours-sombre-1280.png | réglage | ⚑ À ne pas résoudre en réduisant la recherche (arbitrage : recherche à 152 px de 1 000 à 1 279 px avec Git) |
| PU-CODE-59 | Fil d'Ariane à 1 000 avec un fichier ouvert, et en paysage 844 | Garder au moins le dernier niveau en entier (« ‹ Scripts ») ; aujourd'hui une flèche seule, ou « V…/ c../ S. » | D M | <scratchpad>/panel-code/captures/dev/49-fichier-1000-sombre.png · <scratchpad>/panel-code/captures/mobile/33-fichier-detail-paysage-844-sombre.png | réglage | |
| PU-CODE-60 | Rangée de 9 à 11 icônes en haut à droite, 768 à 1 440 | Libellés courts visibles, ou infobulle stylée immédiate (au doigt, il n'y a pas de survol). Légende pour les badges « 4 » et « 44 ». À 1 000, l'icône qui remplace la branche doit aussi avoir une infobulle visible | L N M (D pour l'icône de branche) | <scratchpad>/panel-code/captures/lab/32-1440-survol-icone-ecrans.png · <scratchpad>/panel-code/captures/nouveau/12-survol-icone-types-liens-1440.png · <scratchpad>/panel-code/captures/mobile/22-carte-tablette-768-clair.png · <scratchpad>/panel-code/captures/dev/33-survol-icone-branche-1000.png | plus | |
| PU-CODE-61 | Icônes secondaires de l'en-tête, tablettes et 1 000 | Les regrouper dans « ⋯ » plus tôt, comme au téléphone | N M | <scratchpad>/panel-code/captures/nouveau/23-sombre-1000.png · <scratchpad>/panel-code/captures/mobile/22-carte-tablette-768-clair.png | réglage | |
| PU-CODE-62 | Bouton de thème de l'en-tête | Afficher l'état courant en texte (Auto, Clair, Sombre) : depuis Auto, il faut deux clics pour passer en sombre sans savoir où l'on est | L | <scratchpad>/panel-code/captures/lab/20-sombre-vue-ensemble.png | réglage | |
| PU-CODE-63 | Texte d'aide du champ de recherche, 1 000 | Le raccourcir (« Chercher… ») : aujourd'hui « Chercher un fichi… » | M | <scratchpad>/panel-code/captures/mobile/23-detail-tablette-1000-clair.png | réglage | compatible avec la largeur de 152 px arbitrée |
| PU-CODE-64 | Tiroir Historique Git, 1 440 | Un seul Échap doit le fermer ; le premier retire aujourd'hui le cadre du titre | D (N l'a fermé d'un seul Échap, voir Désaccords) | <scratchpad>/panel-code/captures/dev/05-echap-git-reste-ouvert.png | réglage | |
| PU-CODE-65 | Fenêtre « Exporter une copie », 1 280 à 1 440 | La fermer par Échap et par un clic sur le fond, et placer le focus dans la fenêtre à l'ouverture | D N | <scratchpad>/panel-code/captures/dev/48-export-echap-ne-ferme-pas-1280.png · <scratchpad>/panel-code/captures/nouveau/34-clair-1440-exporter-reste-ouvert.png | réglage | |
| PU-CODE-66 | Ordre de tabulation, 1 440 | Commencer par l'en-tête (onglets, recherche) avant les boutons de zoom du bas | N | <scratchpad>/panel-code/captures/nouveau/30-clair-1440-focus-tab6.png | réglage | |
| PU-CODE-67 | Bouton de visite (boussole), 1 000 à 1 280 | Anneau de focus seulement au clavier (:focus-visible) ; aujourd'hui il reste après un clic souris | D | <scratchpad>/panel-code/captures/dev/30-accueil-1000-clair.png | réglage | compatible avec DESIGN §9 (focus visible au clavier) |
| PU-CODE-68 | Menu « ⋯ », 390, sombre | Fond opaque (le titre transparaît derrière « Historique Git » et « Thème ») et une icône par ligne | M | <scratchpad>/panel-code/captures/mobile/25-menu-plus-390-sombre.png | réglage | écart constaté : DESIGN §5 veut des menus en --menu-solid |
| PU-CODE-69 | Pastille sur « ⋯ » et point gris « Personne au travail », 390 | Ajouter un libellé court (« 0 actif ») ou une légende, ou retirer la pastille | M N | <scratchpad>/panel-code/captures/mobile/24-carte-390-sombre.png · <scratchpad>/panel-code/captures/nouveau/23-sombre-390.png | réglage | |

### F. Contrôles flottants, tactile et petites largeurs

| Id | Élément et écran | Changement demandé | Profils | Capture | Taille | Drapeau |
|---|---|---|---|---|---|---|
| PU-CODE-70 | Pied de la fenêtre de recherche, tactile | Remplacer les aides clavier (« ↑↓ naviguer · ↵ ouvrir · échap fermer ») par une croix « Fermer » de 44 px | M | <scratchpad>/panel-code/captures/mobile/10-recherche-driver-lock-390-clair.png | réglage | |
| PU-CODE-71 | Résultat de recherche au toucher, 390 | Ouvrir directement la feuille de détail après le cadrage, raccourcir l'animation (plus de 1,5 s aujourd'hui) et accepter le toucher pendant | M | <scratchpad>/panel-code/captures/mobile/14-fichier-driver-lock-detail-390-clair.png | réglage | écart constaté : DESIGN §6 plafonne les animations à 700 ms |
| PU-CODE-72 | Bouton flottant « Terminal », 390 (feuille ouverte) et 1 000 | Le masquer ou le rentrer quand une feuille est ouverte, et ne pas le poser sur une carte | D M | <scratchpad>/panel-code/captures/mobile/30-fichier-detail-390-sombre.png · <scratchpad>/panel-code/captures/dev/49-fichier-1000-sombre.png | réglage | |
| PU-CODE-73 | Boutons de zoom : en haut à droite de la carte à 1 000 et 768, en pilule verticale à 390 | Les garder en bas à gauche, hors des cartes, et en barre horizontale compacte au téléphone | N D | <scratchpad>/panel-code/captures/nouveau/28-clair-1000-dev-orchestrator.png · <scratchpad>/panel-code/captures/dev/34-accueil-390-clair.png | réglage | |
| PU-CODE-74 | Poignée de la feuille de détail, 390, deux thèmes | La rendre active : tirer vers le haut pour le plein écran, vers le bas pour fermer | M | <scratchpad>/panel-code/captures/mobile/31-feuille-tiree-haut-390-sombre.png · <scratchpad>/panel-code/captures/mobile/32-feuille-tiree-bas-390-sombre.png | réglage ou plus | |
| PU-CODE-75 | Téléphone en paysage, 844 × 390 | Choisir la mise en page selon la hauteur (moins de 500 px : celle du téléphone), replier la barre de question en un bouton, détail en feuille. Aujourd'hui la carte n'a plus que 40 px de haut | M | <scratchpad>/panel-code/captures/mobile/22-carte-paysage-844-clair.png · <scratchpad>/panel-code/captures/mobile/21-accueil-paysage-844-clair.png | plus | ⚑ touche les points de rupture de DESIGN §4 |
| PU-CODE-76 | Panneau de détail, tablette 768 en portrait | Le passer en feuille du bas repliable : aujourd'hui la carte n'a que la moitié de la largeur, avec des cartes de 30 × 15 px | N M | <scratchpad>/panel-code/captures/nouveau/29-clair-768-dev-orchestrator.png · <scratchpad>/panel-code/captures/mobile/23-detail-tablette-768-clair.png | plus | ⚑ touche les points de rupture de DESIGN §4 (≤ 999 px) |
| PU-CODE-77 | Zone transparente de la barre de question, tablette 768 | Ne plus intercepter les touchers destinés à la carte au-dessus | M | <scratchpad>/panel-code/captures/mobile/22-carte-tablette-768-clair.png | réglage | |
| PU-CODE-78 | Titre « Le code, branche integration/cockpit-final », 390 | Couper sur le « / » et non sur le trait d'union (« cockpit- / final ») | D N | <scratchpad>/panel-code/captures/dev/34-accueil-390-clair.png · <scratchpad>/panel-code/captures/nouveau/23-sombre-390.png | réglage | |
| PU-CODE-79 | Chemin dans le panneau de détail, 1 000, sombre | Couper le chemin sur les « / », pas au milieu de l'extension (« .m / js ») | D | <scratchpad>/panel-code/captures/dev/49-fichier-1000-sombre.png | réglage | |

**Total : 79 propositions.** Tailles : 60 réglages d'un commit, 13 « plus », 6 mixtes (réglage ou plus selon la cause). Drapeaux : 9 ⚑ — 5 touchent un arbitrage rendu (PU-CODE-19, 23, 56, 57, 58) et 4 touchent DESIGN.md (PU-CODE-11, 14, 75, 76) — et 3 « écart constaté » où la proposition rapproche l'existant de DESIGN.md ou d'un arbitrage (PU-CODE-55, 68, 71).

**Les plus portées** :
- par les quatre profils : PU-CODE-01 (zoom initial lisible), PU-CODE-18 (44 contre 24), PU-CODE-50 (la visite cadre l'élément présenté), PU-CODE-58 (troncatures de l'en-tête) ;
- par trois profils, et quatre pour le cadre si l'on compte la remarque de L : PU-CODE-60 (icônes sans libellé), PU-CODE-16 (écran fantôme « /products/:id »), PU-CODE-26 (santé en anglais), PU-CODE-30 et PU-CODE-31 (Unassigned, « and 7 more »), PU-CODE-39 (homonymes), PU-CODE-55 (cadre noir du titre).

## Désaccords entre juges (tels quels)

1. **Pastilles « N modifiés »** :
   - L : « Pastilles "N modifiés" sur les cartes de modules : je vois tout de suite où ça bouge » (dans ce qui l'a aidé).
   - D : « la pastille "modifiés" sur la carte ne veut pas dire "modifié dans Git". Elle m'a menti deux fois. »
   - N : « "modifiés" veut dire deux choses différentes à deux endroits. »
   - M : « l'état Git est cohérent » (via le tiroir).
2. **Visite guidée** :
   - L la range dans ce qui l'a aidé : « quatre étapes courtes, le module concerné est mis en avant ».
   - D, N et M la jugent mal cadrée.
   - Sur son déclenchement, D demande : « Ne pas l'ouvrir d'office une fois le dépôt déjà visité ». N demande l'inverse au premier passage : « La lancer au premier chargement, toujours » (elle ne lui est apparue qu'au deuxième).
3. **Thème sombre** :
   - L : « le thème sombre est aussi lisible que le clair ».
   - N : « propre et cohérent ».
   - D et N : en sombre, les modules non sélectionnés sont « presque invisibles ».
4. **Échap sur le tiroir Git** :
   - D : « Deux Échap nécessaires, le premier agit sur le titre ».
   - N : « Tiroir Git ouvert puis fermé avec Échap », et « le focus qui revient sur le bon bouton après Échap ».
   - Probable dépendance à la présence du cadre noir (PU-CODE-55).
5. **Vocabulaire Git dans l'en-tête** :
   - L : « "Branche" n'est pas un mot de mon métier » ; il veut « Version de travail ».
   - D veut au contraire plus d'état Git brut dans l'en-tête (« 2 M · 1 ? · ↑274 »).
6. **Traits de liaison** :
   - L et N veulent les masquer au repos.
   - D et M citent la sélection qui colore les voisins comme une aide (« On voit d'un coup d'œil à qui il parle »). Pas de contradiction frontale, mais deux regards différents sur la même carte.
7. **Confiance** :
   - M note 16/25 : « Les chemins et compteurs paraissent justes et l'état Git est cohérent ».
   - D, L et N notent 11 à 12, à cause de l'écran fantôme, de 44 contre 24 et de « Modifié » contre git status. M n'a pas ouvert « Écrans » ni le contrôle de santé.

## Ce qui n'a pas pu être jugé

- **Actions qui lancent de vrais agents ou écrivent**, interdites par les consignes et seulement regardées : envoi dans « Posez une question… », « Demander un parcours… », « Corriger avec Claude », « Télécharger » de l'export, « Ouvrir dans l'éditeur ». D a seulement vérifié le lien vscode://…:1.
- **Infobulles natives (attribut title)** : invisibles dans un Chromium sans écran. Leur existence réelle n'est pas jugée, d'où la prudence sur PU-CODE-60.
- **Rafraîchissement en direct de l'état Git** (un fichier qui change pendant que la page est ouverte) : il aurait fallu écrire dans le lab observé.
- **Thème Auto avec un système en sombre** : le navigateur de test était en clair.
- **Déclencheur exact de la visite** au tout premier lancement : comportement divergent entre juges.
- **Justesse des alertes de santé** (vrais secrets ou fixtures) : il aurait fallu lire le code, ce qui était interdit aux juges.
- **Mobile** : le clavier logiciel réel (iOS, Android), l'usage en extérieur et le geste retour système.
- **Volume** : le lab compte 782 fichiers côté Code et non plus de 1 300 comme le brief l'attendait (voir Conditions).
- **Onglets Projet et Équipe, terminal, Au travail** : hors surface, couverts par les deux autres managers. D, L et M ont seulement relevé que le tiroir Git est lisible, mais chargé de jargon pour L (« Worktrees », « HEAD »).
