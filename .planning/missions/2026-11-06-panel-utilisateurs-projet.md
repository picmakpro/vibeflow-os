# Panel d'utilisateurs — cockpit, onglet Projet (2026-11-06)

Demande de Samuel, message direct en session principale, 2026-11-06 : « on lance des design manager avec plusisieurs juge indépendent qui represente les potentiellement utilisateur (dev, lab, autre) et il devront apporter des avis et une note. Ensuite on globalise les proposition puis on fais des gsd-quick pour avoir une version avec toutes les proposition. »

Ce rapport couvre l'un des trois volets : **l'onglet Projet**. Il a été produit par `vf-design-manager`, qui n'a ni designé ni codé : il a seulement monté le banc, fait juger et consolidé.

## Banc de test

- **Version jugée** : `integration/cockpit-final` à `a95c018d` (cockpit v1.4.0, Phases 71.5, 78, 72 et parseurs). Instantané figé par `git archive`, de sorte que le worktree `cockpit-final` n'a jamais été touché.
- **Lab** : quatre copies du dépôt réel, une par juge. Chacune est un clone de `main` (57e7957f), avec le `.planning/` du poste recopié par-dessus pour y inclure les fichiers non suivis. On y compte 174 cartes, 9 jalons dans l'historique, 77 phases, 356 plans et 602/634 exigences. Les états présents d'origine : 4 cartes bloquées, 1 phase à recetter, 12 en cours, des missions.
- **États fabriqués dans les copies** (rien de tout cela n'existe dans le vrai dépôt) :
  - Trois worktrees ont été ajoutés dans chaque copie : `phase-72`, `phase-78` et `phase-71-5`, sur leurs vraies branches. Ils reproduisent l'état réel du poste ; aucune donnée n'a été inventée.
  - Au tour 2 uniquement, une dérive de format a été injectée. Elle comprend une forme tolérée (`### Phase 66 : …`, avec une espace avant les deux-points) et quatre lignes non comprises : trois en fin de ROADMAP `fiabilite`, une en fin de REQUIREMENTS. Sans cela, le panneau « Format de la planification » ne s'affichait pas : le lab est conforme, et aucun des quatre juges n'a pu le juger au tour 1.
- **Faux `claude`** : placé en tête du PATH, avec un zsh isolé (`ZDOTDIR`). Avant le dispatch, j'ai vérifié que `command -v claude` dans le terminal de la page désigne bien le faux. Aucune vraie session n'a été lancée : les argv reçus sont consignés dans `faux-sorties/` (lancements `--session-id …`, dont deux avec `-r … --fork-session`, et des `--version`). Les réponses du chat qui passent par le modèle étaient simulées ; les réponses calculées localement sont réelles.
- **Serveurs** : un par juge, sur les ports 47821 à 47824, chacun avec son Chromium (Playwright, profil persistant). Le cockpit de Samuel sur le port 4456 n'a pas été touché.
- **Captures** : 416 PNG, sous `<scratchpad>/panel-projet/captures/`, un dossier par juge (`j1/` à `j4/`). Dans ce rapport, une capture s'écrit `jN/fichier.png`, relativement à ce dossier.
  - **Attention** : le scratchpad est effacé au redémarrage de macOS. Copiez ce dossier ailleurs si les captures doivent servir aux tâches rapides.

## Les juges

Les quatre juges sont des agents à contexte frais. Ils ont été dispatchés en parallèle, sans se voir entre eux et sans recevoir mes attentes. Après le tour 2, chacun a rendu un addendum sur le panneau « Format de la planification ».

| Juge | Profil | Note tour 1 | Note finale | Utilité | Lisibilité | Confiance | Finition |
|---|---|---|---|---|---|---|---|
| j1 | Développeur multi-sessions et multi-worktrees | 52 | **52** | 18 | 13 | 10 | 11 |
| j2 | Responsable de lab non développeuse | 47 | **44** | 13 | 7 | 10 | 14 |
| j3 | Nouvel arrivant, sans contexte | 51 | **50** | 14 | 9 | 12 | 15 |
| j4 | Associé ou client, qui veut seulement « voir où ça en est » (profil ajouté) | 47 | **45** | 12 | 11 | 9 | 13 |

**Pourquoi un quatrième profil.** La barre du haut propose « Exporter une copie » et le cockpit se montre en capture. Un lecteur qui ne lance jamais rien, regarde vite et parfois sur un petit écran est donc un usage réel. Ses questions (quand est-ce livré, dois-je décider quelque chose) ne sont portées par aucun des trois autres profils.

### Avis en quelques lignes, dans leurs mots

- **j1, développeur (52)** : « Lancer une session depuis une carte avec le bon verbe, le bon mode et la reprise du chat, c'est exactement ce que je veux, et ça marche. » Mais aussi : « En dix secondes, je lis deux états contradictoires pour la même phase. Deux phases en cours manquent. Le chat affirme qu'il n'y a "rien en cours". […] Je ne peux plus croire le tableau sans tout revérifier. » Sur le panneau Format : « Le diagnostic est exact sur ce qui compte […] Le panneau en dit moins que l'outil qu'il cite. »
- **j2, responsable non dev (44)** : « Aurais-je osé lancer ? Non, pas seule. […] Je n'ai pas compris ce qui serait modifié, ni si c'était réversible. » Et encore : « La vue d'ensemble et les compteurs me disent "où on en est" en gros, mais pas "quoi faire" ni "pourquoi c'est bloqué". » Sur le panneau Format : « Le panneau signale un vrai problème, mais je ne peux rien en faire seule. »
- **j3, nouvel arrivant (50)** : « Pendant les 10 premières secondes, je vois un fond pointillé avec des cartes délavées, presque illisibles. […] Je ne sais toujours pas ce que fait VibeFlow, ni ce qu'est un "jalon". » Ce qui le rassure : « La proposition dans le terminal : je vois la commande exacte, le mode et les avertissements avant d'agir, et c'est ce qui me rassure le plus. »
- **j4, associé ou client (45)** : « La vue "combien c'est fini" est bonne, mais les trois questions clés d'un associé (quand c'est livré, qu'est-ce qui coince et pourquoi, dois-je décider) n'ont pas de réponse fiable. » Et : « Un inventaire servi comme réponse sur les risques trompe. »

## Propositions dédupliquées

**Colonnes** :
- **Profils** : les juges qui portent la proposition.
- **Taille** : « 1 commit » pour un réglage local ; « plus » quand il faut de la donnée, du routage ou un suivi d'état.
- **Drapeau** :
  - **⚑ DESIGN** : touche une règle de `DESIGN.md` (Graphite) ou un arbitrage déjà rendu par Samuel ;
  - **⚑ frontière** : touche probablement la surface d'un autre manager ;
  - **⚑ banc** : constat peut-être influencé par le banc de test.

Rien n'est écarté ni trié : 75 propositions.

### A. Vérité des états et des chiffres

| ID | Élément et écran | Changement demandé | Profils | Capture | Taille | Drapeau |
|---|---|---|---|---|---|---|
| PU-PROJ-01 | Badge du bloc « Maintenant » (vue d'ensemble) et étape 2 de « Par où commencer » : Phase 72 « prête à planifier » | Un seul statut pour la Phase 72 : celui de la carte et de « Prochaines phases » (« À recetter »). Sinon, signaler que STATE.md est périmé. | j1 j2 j3 j4 | j1/03-etat.png, j2/01-arrivee.png, j3/01-premiere-vue.png, j4/01-arrivee-1440.png, j2/07-visite-etape2.png | 1 commit | |
| PU-PROJ-02 | Carte du jalon vibeflow-v2.0, en-tête « 5 phases faites sur 6 », recherche `/` | Lire aussi le ROADMAP des worktrees, afficher les Phases 71.5 et 78 avec la mention « dans worktree … », recompter. | j1 (j2 dans la réponse « on en est où ») | j1/04-jalon-v2.png, j1/58-recherche-71-5.png | plus | |
| PU-PROJ-03 | Réponse locale à « Quelles phases sont en cours dans d'autres worktrees ? » (« Rien en cours ») | Interroger les worktrees et lister 71.5, 72 et 78 avec leur branche. | j1 | j1/25-question1-reponse.png | plus | |
| PU-PROJ-04 | Réponse « Où en est le jalon ? » / « on en est où ? » et réponse « Qu'est-ce qui est en cours ? » | Un seul état par phase, sans « sans statut · à recetter ». Ne pas lister la Phase 72 deux fois. Inclure les autres jalons en cours ainsi que 71.5 et 78. Ne pas citer les exigences d'une phase faite comme « en cours ». | j2 j3 j4 | j2/17-question1-reponse.png, j3/20-chip-ou-en-est-le-jalon.png, j3/76-1024-question-en-cours.png, j4/11-question-ou-en-est-on.png | 1 commit | |
| PU-PROJ-05 | Cartes « Phase 70 · Fait · 3/14 exigences » (aussi Phase 60 à 9/11, Phase 61 à 7/9) | Nuancer : « Fait · 11 exigences non cochées », ou expliquer l'écart. | j1 j2 j3 j4 | j1/04-jalon-v2.png, j2/09-dans-jalon-v2.png, j2/91-clair-1280-jalon-equipe-produit.png, j3/09-dans-le-jalon-v2.png, j4/07-phase72-clic-simple.png | 1 commit | ⚑ DESIGN : j1 demande une « pastille d'alerte ». Elle doit rester un glyphe et un mot en texte neutre, sans fond teinté. |
| PU-PROJ-06 | Ligne « Reste : vérification, clôture. » du panneau d'une phase « pas de plan » (Phases 51, 52, 53, 66) | Écrire « Reste : cadrage, plan, exécution, vérification, clôture ». | j1 j2 j3 j4 | j1/36-phase66-lancer.png, j2/57-phase51-lancer.png, j3/72-sombre-phase51-lancer.png, j4/19-autres-actions-ouvert.png | 1 commit | |
| PU-PROJ-07 | Pseudo-jalon « Phases » (seule Phase 36 RÉSERVÉ, « 1/1 · 100 % · Fait ») dans « Historique » et dans « Jalons 13 » | Le retirer ou le renommer, et corriger les compteurs. | j1 j2 j3 j4 | j1/50-pseudo-jalon-phases.png, j2/70-apercu-panneau-bas.png, j3/26-panneau-droit-scroll1.png, j4/69-jalon-nomme-phases.png | 1 commit | |
| PU-PROJ-08 | « Utilisé par : Phase 71 » dans le panneau de la Phase 72 | Corriger le sens : « Dépend de : Phase 71 ». | j2 j3 | j2/11-panneau-phase72-lancer.png, j3/13-phase72-lancer-du-travail.png | 1 commit | |
| PU-PROJ-09 | Étape 3 de « Par où commencer » : Mission 59 abandonnée, d'un ancien jalon (« 11 nœuds faits sur 15 », « 31 missions » contre la carte « 10 missions ») | Montrer une mission active du jalon en cours, aligner les comptes, dire « étapes » plutôt que « nœuds ». | j2 j3 j4 | j2/07-visite-etape3.png, j3/07-tour-etape-3.png, j4/03-visite-3.png | 1 commit | |

### B. Panneau de droite (contenu)

| ID | Élément et écran | Changement demandé | Profils | Capture | Taille | Drapeau |
|---|---|---|---|---|---|---|
| PU-PROJ-10 | Description d'un jalon ou d'une phase dans le panneau | Rendre le markdown (`**`, accents graves) et masquer les commentaires `<!-- vf-archive … -->`. | j1 j2 j3 j4 | j1/04-jalon-v2.png, j2/09-dans-jalon-v2.png, j3/07-tour-etape-2.png, j4/03-visite-2.png | 1 commit | |
| PU-PROJ-11 | Description de la Phase 72, affichée deux fois (tronquée puis complète) | N'en garder qu'une. | j1 j2 j3 j4 | j1/05-clic-phase72.png, j2/10-carte-phase72-selection.png, j3/12-dans-phase72.png, j4/08-phase72-selectionnee.png | 1 commit | |
| PU-PROJ-12 | « Source », « Ligne de ROADMAP », chemins `.planning/…`, worktree et branche dans le panneau | Les regrouper sous un repli « Détails techniques » et commencer par un résumé en langage courant. | j2 j4 | j2/10-carte-phase72-selection.png, j4/03-visite-2.png | 1 commit (repli) ; plus (résumé) | |
| PU-PROJ-13 | Petit « 0 » à droite des éléments d'une mission (infobulle « 0 Lignes »), Mission 414 | Remplacer par l'état réel du nœud (fait, en échec, en attente) sous forme de glyphe et de mot. | j1 j2 j3 | j1/33-mission414-panneau.png, j2/28-mission414-ouverte.png, j3/10b-panneau-jalon-fin.png | 1 commit | ⚑ DESIGN : j2 et j1 demandent de « colorer » chaque élément. Couleur sur le glyphe seulement, jamais en fond. |
| PU-PROJ-14 | Cartes « Exigences » (UIFN-xx) qui affichent « REQUIREMENTS.md » | Afficher la phrase de l'exigence. | j3 | j3/80-exigences-phase70.png | 1 commit | |
| PU-PROJ-15 | Aide « Double-clic sur une carte pour plonger », tout en bas du panneau | La remonter en haut, ou la mettre dans la visite. | j3 | j3/26-panneau-droit-scroll1.png | 1 commit | |
| PU-PROJ-16 | En-tête « Jalon vibeflow-v2.0 » et lignes « Jalons » | Afficher une date prévue ou une release cible, ou « pas de date fixée ». | j4 | j4/05b-panneau-droit-bas.png | plus (donnée absente du planning) | |
| PU-PROJ-17 | Panneau de la vue d'ensemble, sous « Maintenant » | Ajouter un encart « Décisions attendues », même vide (« Rien à décider »). | j4 | j4/01-arrivee-1440.png | plus | |
| PU-PROJ-18 | Chaîne de jalons de la vue d'ensemble (ecc-inspiration « À faire », 0 %, placé entre deux jalons en cours) | Revoir l'ordre, ou l'expliquer. | j4 | j4/01-arrivee-1440.png | 1 commit | |

### C. Lancer du travail depuis une carte, jusqu'au terminal

| ID | Élément et écran | Changement demandé | Profils | Capture | Taille | Drapeau |
|---|---|---|---|---|---|---|
| PU-PROJ-19 | Section « Lancer du travail » sous la ligne de flottaison du panneau (1440×900) ; menu du clic droit sans action de lancement | La remonter sous le titre et ajouter l'action principale (Vérifier, Cadrer…) au menu du clic droit. | j1 j2 j3 | j1/05-clic-phase72.png, j1/06-clic-droit-phase72.png, j2/58-clic-droit-carte.png, j3/13-phase72-lancer-du-travail.png | 1 commit | |
| PU-PROJ-20 | Boutons « Vérifier », « Cadrer », « Planifier », « Exécuter », « Reprendre » | Une phrase d'aide par action, au survol. | j2 j3 j4 | j2/13-survol-verifier.png, j3/15-autres-actions.png, j4/18-survol-cadrer.png | 1 commit | |
| PU-PROJ-21 | Bouton « Lancer » du bandeau « Lancement proposé » : il écrit la commande sans l'exécuter | Le renommer (« Écrire dans le terminal » ou « Préparer dans le terminal ») et ajouter « Appuyez sur Entrée dans le terminal pour démarrer ». Variante : qu'il exécute vraiment. | j1 j2 j3 j4 | j1/20-apres-lancer.png, j2/69-lancer-un-clic-7s.png, j3/63-apres-lancer-faux-claude.png, j4/44-apres-lancer-commande-tapee.png | 1 commit (libellé) | |
| PU-PROJ-22 | Messages du panneau « Proposition envoyée au terminal… Confirmez-la » et « Lancée : … en attente de la session » | Les synchroniser avec l'état réel : annulée, expirée, session expirée, démarrée. N'écrire « Lancée » qu'après exécution. | j1 j2 j3 j4 | j1/19-etat.png, j2/90-annuler-proposition.png, j3/68-sombre-apres-annuler.png, j3/67-sombre-proposition-planifier.png, j4/41-panneau-phase51.png, j4/78-900-sombre-apres-annuler.png | plus | |
| PU-PROJ-23 | Proposition non validée qui disparaît en 30 à 60 s, sans trace | Afficher « Proposition expirée — la renvoyer » dans le terminal et dans le panneau. | j1 j2 | j1/12-terminal-ouvert-apres-verifier.png, j2/48-proposition-disparue.png | 1 commit | |
| PU-PROJ-24 | Clic sur « Cadrer » quand le terminal est fermé : aucun retour, et la proposition ressurgit plus tard | Ouvrir le tiroir au premier clic, ou dire tout de suite « Ouvrez le terminal pour confirmer ». | j2 j4 | j2/86-sombre-1024-cadrer-avec-chat.png, j4/21-apres-clic-cadrer.png, j4/34-ouverture-proposition-en-attente.png | 1 commit | ⚑ DESIGN : l'ouverture automatique est à confronter à l'arbitrage « terminal au repos seulement pour lancer ». |
| PU-PROJ-25 | Bandeau « Lancement proposé » : une proposition ancienne reste affichée, puis est remplacée sous le clic et revient en mode « Par défaut » | Effacer ou dater les propositions d'une visite précédente, et ne jamais remplacer le bandeau pendant qu'on le manipule. | j4 | j4/30-apres-cadrer-t1.png, j4/31-mode-plan-lecture-seule.png, j4/33-apres-lancer-faux-claude.png | plus | ⚑ banc : j3 a observé que chaque reconnexion de son script rechargeait le cadre du terminal. |
| PU-PROJ-26 | Envoi vers un terminal en « Session expirée — Relancez /vf-cockpit --terminal » ; tiroir expiré qui se rouvre seul à l'arrivée | Refuser l'envoi si la session est expirée, proposer un bouton « Reconnecter » plutôt qu'une commande, et ne pas rouvrir automatiquement un tiroir expiré. | j1 j2 j4 | j2/34-apres-clic-verifier-4s.png, j1/12-terminal-ouvert-apres-verifier.png, j4/F-01-arrivee.png | plus | ⚑ frontière (tiroir du terminal) |
| PU-PROJ-27 | Avertissement « La phase est plus avancée dans un autre arbre de travail » ; la session part dans l'arbre principal | Nommer le worktree et proposer « Lancer dans worktree phase-72 ». | j1 | j1/17-apres-attente.png | plus | |
| PU-PROJ-28 | Même avertissement, côté lecture | Le dire en langage courant (« une version plus récente de ce travail existe à part ») et dire quoi faire. | j2 | j2/12-autres-actions.png | 1 commit | |
| PU-PROJ-29 | Liste des modes « Par défaut / Accepter les modifications / Plan (lecture seule) / Hérité du poste » | Une ligne d'explication par mode, en signalant que « Accepter les modifications » est le mode risqué. | j2 j4 | j2/44-mode-plan-lecture-seule.png, j4/29-proposition-cadrer.png | 1 commit | |
| PU-PROJ-30 | Ligne de commande brute `claude --session-id …` dans la proposition | Commencer par une phrase en clair (« L'assistant va vérifier la phase 72… ») et replier la commande sous « Voir la commande ». | j2 j4 | j2/43-verifier-apres-5s.png, j4/29-proposition-cadrer.png | 1 commit | Désaccord : j1 et j3 s'appuient sur la commande visible (voir plus bas). |
| PU-PROJ-31 | Mode repris du choix précédent (« Plan » présélectionné sans le dire) | Le signaler : « Plan (lecture seule) — votre dernier choix ». | j3 j4 | j3/67-sombre-proposition-planifier.png, j4/43-proposition-executer-phase52.png | 1 commit | Désaccord : j1 apprécie que le mode soit retenu. |
| PU-PROJ-32 | Case « Continuer la conversation du chat » | Citer la conversation reprise et dire en une phrase ce que fait la reprise, sans exposer `-r … --fork-session`. La masquer, ou avertir, si le chat ne porte pas sur la carte lancée. | j2 j3 j4 | j2/89-sombre-1024-continuer-chat-coche.png, j3/62-proposition-mode-plan-continuer-chat.png, j4/F-28-proposition-case-continuer.png, j4/F-30-case-continuer-cochee.png | 1 commit | ⚑ DESIGN : touche un élément arbitré (case décochée par défaut, risque écrit). L'explication est compatible ; le masquage conditionnel est à trancher. |
| PU-PROJ-33 | Libellé de la proposition et prompt envoyé : « Verifie la Phase 72 du compartiment fiabilite » | Rétablir les accents : « Vérifie », « fiabilité ». | j1 j2 j3 | j3/61-verifier-une-seule-connexion.png, j2/43-verifier-apres-5s.png, j1/55-sombre-phase-selection.png | 1 commit | À vérifier : si l'ASCII est voulu dans l'argv, garder l'ASCII dans la commande et accentuer seulement le libellé affiché. |
| PU-PROJ-34 | « Autres actions › Exécuter » sur une phase sans plan (Phase 52) | Avertir (« cadrer d'abord ») ou griser. | j4 | j4/42-survol-executer-phase52-sans-plan.png, j4/43-proposition-executer-phase52.png | 1 commit | |
| PU-PROJ-35 | Mission hors phase : « Reprendre » grisé, « Bloqué : … ne se lance pas depuis sa carte » ; panneau de la Mission 414 | Dire où et comment la reprendre, et donner la raison du blocage. | j2 j3 | j3/74-sombre-mission-partition-bas.png, j2/28-mission414-ouverte.png, j2/29-mission414-bas-panneau.png | 1 commit | Désaccord : j1 et j4 jugent ce garde-fou clair. |
| PU-PROJ-36 | État « Prêt dans un instant » avec « Lancer » grisé, observé plus de 20 s | Dire ce qu'on attend, ou abréger l'attente. | j4 | j4/F-25-proposition-apres-chat-modele.png | 1 commit | j1 et j2 jugent ce délai rassurant ; seule sa durée est en cause. |
| PU-PROJ-37 | Phase « À faire » (Phase 51) sans section « Lancer du travail », d'après j3 | Proposer au moins « Cadrer » sur une phase à faire. | j3 | j3/72-sombre-phase51-lancer.png | à vérifier | Désaccord factuel : j2 et j4 ont lancé « Cadrer » sur la Phase 51. |

### D. Barre de question et chat

| ID | Élément et écran | Changement demandé | Profils | Capture | Taille | Drapeau |
|---|---|---|---|---|---|---|
| PU-PROJ-38 | Titre du tableau de réponse (« 4 bloqué(s) ») resté sur la question précédente | Le mettre à jour ou le vider à chaque nouvelle question. | j2 j3 j4 | j2/25-question4-reponse.png, j3/22-question2-que-lancer.png, j4/13-question-quand-livre.png | 1 commit | |
| PU-PROJ-39 | Bouton « Afficher le tableau de réponse » : erreur JS `Cannot read properties of undefined (reading 'items')` qui vide le plan de travail, puis panneau « Answer » en anglais après Échap | Corriger l'erreur, traduire en « Réponse » et vider le contenu périmé. | j1 j3 | j1/26-tableau-reponse-q1.png, j1/27-apres-echap-tableau.png, j3/25-clic-pastille-claude-code.png | 1 commit | |
| PU-PROJ-40 | Barre « Posez une question sur ce projet… » qui disparaît quand le terminal est ouvert ; « Poser une question sur ceci » sans effet visible | Garder la barre accessible, ou réduire le terminal quand on pose une question. | j2 j4 | j2/60-question-sur-ceci-reponse.png, j4/22-terminal-ouvert.png | 1 commit ou plus | ⚑ frontière (tiroir) |
| PU-PROJ-41 | Questions que le calcul local ne sait pas traiter (risques et date de livraison, « que dois-je faire aujourd'hui », « ça me sert à quoi », questions composées) mais auxquelles il répond par un inventaire ou une réponse partielle | Les passer au modèle, ou dire « je ne sais pas calculer ça ». Répondre à toutes les parties d'une question composée (« combien de plans »). | j1 j2 j4 | j4/47-reponse-modele-chat.png, j2/22-question3-reponse.png, j2/64-question-sur-ceci-reponse.png, j1/29-q2-reponse.png | plus | |
| PU-PROJ-42 | Réponse « Qu'est-ce qui bloque ? » (Mission 414, revue-w1, revue-t4…) | Pour chaque blocage : la cause en une phrase, depuis quand, qui doit agir, et une action proposée. Inclure les nœuds `blocked` des DAG (Missions 59 et 71). | j1 j2 j4 | j1/32-q4-bloque.png, j2/19-question2-reponse.png, j4/12-question-bloque.png | plus | |
| PU-PROJ-43 | Réponses du chat coupées en plein mot (« rech », « gau », « centr ») | Couper au mot entier. | j1 | j1/29-q2-reponse.png | 1 commit | |
| PU-PROJ-44 | Bouton « Retour à la carte » | Revenir à la carte d'où partait la question, et lever le double sens de « carte » (carte ou plan). | j2 | j2/64-question-sur-ceci-reponse.png, j2/66-cadrer-proposition.png | 1 commit | |
| PU-PROJ-45 | Bulle ou carte de réponse qui couvre le canevas (1024, 1280×720, 900, changement de jalon) | Limiter sa hauteur, la loger dans le panneau, ou la refermer quand on change de jalon. | j2 j3 j4 | j3/76-1024-question-en-cours.png, j3/77-1280x720-apres-question.png, j2/91-clair-1280-jalon-equipe-produit.png, j4/73-900-reponse-ou-en-est-on.png | 1 commit | |
| PU-PROJ-46 | Question sur les « lignes du planning non comprises » | Prévoir une réponse locale qui reprend le panneau Format en langage courant. | j2 | j2/F-07-question-format.png | 1 commit | |

### E. Panneau « Format de la planification » (tour 2, dérive injectée)

| ID | Élément et écran | Changement demandé | Profils | Capture | Taille | Drapeau |
|---|---|---|---|---|---|---|
| PU-PROJ-47 | Section « Format de la planification », sous les 13 barres de jalons, sans aucun signal à l'arrivée | Signaler l'écart en tête du panneau (sous « Maintenant ») ou dans la barre du haut (« 5 lignes du planning non lues — chiffres peut-être incomplets »), avec un lien vers la section. | j1 j2 j3 j4 | j1/F-01-arrivee-1440.png, j2/F-01-arrivee.png, j3/F-01-arrivee-1440-clair.png, j4/F-01-arrivee.png | 1 commit | ⚑ DESIGN : j3 et j4 demandent une pastille « orange ». Selon la règle, ce serait un glyphe et un mot en texte neutre, sans fond teinté. |
| PU-PROJ-48 | Bloc « Santé : Aucun problème trouvé », juste sous la section | Y intégrer les écarts de format, ou préciser « (sécurité seulement) ». | j1 j2 j3 j4 | j1/F-02-panneau-bas-1440.png, j2/F-12-sombre-1024-lignes.png, j3/F-03-panneau-defile-fin.png, j4/F-02-panneau-droit-bas.png | 1 commit | |
| PU-PROJ-49 | Liste « Lignes du planning non comprises » : le chemin occupe 317 à 359 px, le texte est écrasé en 1 à 3 caractères, un débordement horizontal fait glisser tout le panneau, le numéro de ligne est coupé (deux thèmes, toutes tailles) | Chemin et numéro sur une ligne (en petit), puis le texte de la ligne en pleine largeur avec retour à la ligne, sans défilement horizontal. | j1 j2 j3 j4 | j1/F-11-sombre-lignes-1440.png, j2/F-08-panneau-defile-horizontal.png, j3/F-09-lignes-non-comprises-visibles.png, j4/F-10-1440-clair-defilement-horizontal.png | 1 commit | |
| PU-PROJ-50 | « Correctif proposé, jamais appliqué d'ici : node vf-cockpit-drift.mjs <lab> --diff… git apply » : échoue telle qu'écrite (MODULE_NOT_FOUND, `zsh: no such file`) | Donner la commande complète avec le chemin réel (comme la CLI) et un bouton Copier ; mieux, un bouton « Préparer la correction » qui propose la commande au terminal avec confirmation. | j1 j2 j3 j4 | j1/F-05-commande-telle-quelle.png, j2/F-09-essai-correctif-terminal.png, j3/F-11-essai-commande-correctif-terminal.png, j4/F-08-clic-ligne-486.png | 1 commit (copier) ; plus (proposition au terminal) | |
| PU-PROJ-51 | Lignes et règles surlignées au survol mais non cliquables | Au clic, ouvrir un détail (ce qui était attendu, un exemple corrigé), copier `chemin:ligne`, ouvrir l'onglet Code à la ligne, ou mener à la carte concernée. Sinon, retirer le surlignage. | j1 j2 j3 j4 | j1/F-08-survol-ligne.png, j2/F-06-clic-ligne-non-comprise.png, j3/F-07-clic-ligne-non-comprise.png, j4/F-08-clic-ligne-486.png | 1 commit à plus | |
| PU-PROJ-52 | Compteur « Format de la planification 5 » contre « Lignes… 4 » | Écrire « 5 écarts : 1 toléré, 4 ignorés », lister la ligne tolérée, fusionner la règle « ignoré » avec la liste. | j1 j2 j3 | j1/F-12-sombre-1024.png, j2/F-03-format-entete.png, j3/F-05-panneau-format-titre.png | 1 commit | |
| PU-PROJ-53 | Règle « ignoré (4 · ROADMAP.md) » alors que la répartition est 3 ROADMAP + 1 REQUIREMENTS ; règle « toléré » sans numéro de ligne | Corriger la répartition par fichier, indiquer ROADMAP.md:390 pour la règle tolérée, dire ce que le diff couvre et que les lignes ignorées se corrigent à la main. | j1 | j1/F-03-section-format-1440.png, j1/F-10-sombre-format-1440.png | 1 commit | |
| PU-PROJ-54 | Conséquence des écarts, aujourd'hui non dite | Une phrase d'impact : « 1 phase (66) et 1 exigence (GRIL_01) ne sont pas comptées ; le reste est juste ». | j2 j3 j4 | j4/F-03-panneau-format-1440.png, j3/F-05-panneau-format-titre.png, j2/F-06-clic-ligne-non-comprise.png | plus | |
| PU-PROJ-55 | Vocabulaire du panneau : « gabarit GSD », « Goal », « Depends on », « current_phase », « toléré », « ignoré », « aucun lecteur ne reconnaît » | Employer les mots du cockpit (« objectif », « dépend de », « phase en cours » ; « Lu malgré une petite différence » et « Non lu — à corriger »), ajouter des infobulles, et replier le jargon sous « Détails pour l'équipe ». | j2 j3 j4 | j2/F-03-format-entete.png, j3/F-17-clair-1024-panneau-format.png, j4/F-07-survol-tolere.png | 1 commit | |
| PU-PROJ-56 | Icônes de « toléré » et « ignoré » : même rond vide que le statut « À faire » des cartes | Leur donner un glyphe de forme distincte. | j3 | j3/F-13-sombre-1440-panneau-format.png | 1 commit | ⚑ DESIGN : j3 demande aussi une « couleur d'avertissement ». La forme du glyphe suffit ; la couleur, si elle est retenue, ne va que sur le glyphe. |
| PU-PROJ-57 | Recherche `/` : « format », « non compris », « écart » ne donnent rien | Faire remonter la section Format dans la recherche. | j4 | j4/F-05-recherche-non-comprises.png | 1 commit | |
| PU-PROJ-58 | Section masquée quand le lab est conforme : impossible de savoir si le diagnostic a tourné | Toujours l'afficher, par exemple dans « Santé » : « Conforme · 0 ligne non comprise ». Y signaler aussi le pseudo-jalon « Phases » (PU-PROJ-07). | j1 (j2 j3 j4 ne l'ont pas trouvée au tour 1) | j1/48-sante.png, j1/F-03-section-format-1440.png | 1 commit | |

### F. Lisibilité, mise en page, clavier, visite

| ID | Élément et écran | Changement demandé | Profils | Capture | Taille | Drapeau |
|---|---|---|---|---|---|---|
| PU-PROJ-59 | Texte des cartes du canevas à environ 6-9 px en vue ajustée (vue d'ensemble, jalon v2.0, Historique, 1024) | Taille minimale d'environ 11 px, ou zoom de départ plus fort. Ne pas couper le titre de la phase en cours. | j1 j2 j3 j4 | j3/09-dans-le-jalon-v2.png, j3/75-1024-vue-ensemble-clair.png, j2/77-vue-historique.png, j4/01-arrivee-1440.png | 1 commit ou plus | |
| PU-PROJ-60 | Onglet « Vue d'ensemble » tronqué en « V… » à 1024 et 900 px | Ne pas tronquer : icône avec infobulle, ou libellé court. | j1 j2 j3 j4 | j1/56-sombre-1024-vue-ensemble.png, j2/79-sombre-1024-apercu.png, j3/75-1024-vue-ensemble-clair.png, j4/73-900-vue-ensemble.png | 1 commit | ⚑ frontière (barre du haut = coque) |
| PU-PROJ-61 | Infobulle de carte (« 2×clic ouvrir, clic droit · plus ») rognée par le panneau de droite, ou restée affichée après un déplacement | La placer à gauche près du panneau, la fermer au déplacement, écrire « Clic droit : plus d'actions ». | j1 j2 j3 j4 | j1/05-clic-phase72.png, j2/10-carte-phase72-selection.png, j3/08-clic-carte-jalon-v2.png, j4/04-survol-carte-jalon.png | 1 commit | |
| PU-PROJ-62 | Fenêtres étroites (1024 et 900) : boutons de zoom flottants, pastille « Terminal » qui chevauche une carte ou la réponse, pastilles coupées | Ancrer le zoom, éviter le chevauchement, faire passer les pastilles à la ligne. | j2 j3 j4 | j2/85-sombre-1024-reponse-modele.png, j3/75-1024-vue-ensemble-clair.png, j4/73-900-vue-ensemble.png | 1 commit | |
| PU-PROJ-63 | Cartes du canevas qui passent par-dessus le titre et la description du jalon | Réserver la zone du titre. | j3 | j3/78-phase70-ouverte.png | 1 commit | |
| PU-PROJ-64 | Thème sombre : cartes non sélectionnées quasi invisibles | Monter leur contraste. | j3 | j3/64-sombre-vue-ensemble.png | 1 commit | Désaccord : j1, j2 et j4 jugent le thème sombre propre et lisible. |
| PU-PROJ-65 | Jalon gouvernance-labs-v1.0 : 9 phases sur une seule ligne, illisibles | Disposer sur deux lignes, ou adapter le zoom. | j4 | j4/71-jalon-gouvernance.png | 1 commit ou plus | |
| PU-PROJ-66 | Cartes non focalisables au clavier ; les flèches ne déplacent rien | Rendre les cartes focalisables (Tab ou flèches), avec Entrée pour plonger et Espace pour sélectionner. | j1 | j1/52-tab-focus-carte.png | plus | |
| PU-PROJ-67 | Échap ne ferme pas « Exporter une copie » ; les popovers « Au travail », « Parcours » et « Types de liens » s'empilent | Échap ferme ; un popover ferme le précédent. | j4 | j4/60-parcours.png, j4/61-types-de-liens.png | 1 commit | ⚑ frontière (barre du haut) |
| PU-PROJ-68 | Icônes de la barre du haut sans libellé ; « Aucun verrou de driver tenu », « Driver libre », « Verrous du dépôt : lue » | Libellé court visible en grand écran ; « Personne ne travaille en ce moment ». | j2 j3 | j2/05-survol-point-personne.png, j3/81-point-personne-au-travail.png | 1 commit | ⚑ frontière (« Au travail » relève de l'autre volet) |
| PU-PROJ-69 | Étape 1 de « Par où commencer » | Une phrase sur ce que fait VibeFlow, puis « jalon = …, phase = …, mission = … ». | j3 | j3/06-tour-etape-1.png | 1 commit | |
| PU-PROJ-70 | Étape 4 de la visite (« Rejouez cette visite… depuis le bouton de visite ») | Montrer l'icône de la visite ou la mettre en surbrillance. | j2 | j2/07-visite-etape4.png | 1 commit | |
| PU-PROJ-71 | Vocabulaire général : worktree, branche, compartiment, nœuds, PR #…, release groupée, recette humaine, Graines, correctifs, exigences, Pattern F, vf-reviewer… | Glossaire, ou équivalents courants pour les profils non développeurs. | j2 (j3) | j2/10-carte-phase72-selection.png, j2/07-visite-etape2.png | plus | |

### G. Coquilles et divers

| ID | Élément et écran | Changement demandé | Profils | Capture | Taille | Drapeau |
|---|---|---|---|---|---|---|
| PU-PROJ-72 | Coquilles et anglicismes : pastille « Qu est-ce qui bloque ? », « Dépend de · 1 connection », « revue complète de security » (Santé), « Exported » (export), « 319 Éléments », « Answer » | « Qu'est-ce qui bloque ? », « 1 lien », « revue de sécurité complète », « Exporté le », « 319 éléments », « Réponse ». | j1 j2 j3 j4 | j3/19-question1-reponse.png, j1/31-q3-reponse.png, j2/76-sante-ouverte.png, j4/70-sante.png, j4/04-survol-carte-jalon.png | 1 commit | Le « n a été » relevé par j1 vient du texte du faux claude du banc, pas du produit : exclu. |
| PU-PROJ-73 | Recherche `/` : doublons RND-02 et PHIL-02 | Dédoublonner. | j2 j3 j4 | j3/38-recherche-format.png, j4/68-recherche-format.png, j2/75-recherche-format.png | 1 commit | |
| PU-PROJ-74 | « Exporter une copie » : exporte la carte du Code, pas la vue Projet ; dans l'export, l'onglet Projet mène à « fichier introuvable » | Exporter la vue active, ou laisser choisir ; réparer le lien Projet de l'export. | j4 | j4/58-exporter.png, j4/63-export-ouvert-hors-ligne.png, j4/65-export-onglet-projet.png | plus | ⚑ frontière (coque) |
| PU-PROJ-75 | « Branche indisponible » affiché par moments à la place de « main » dans l'en-tête | À diagnostiquer, puis stabiliser. | j4 | j4/41-panneau-phase51.png | à diagnostiquer | ⚑ frontière (en-tête, tiroir Git) ; ⚑ banc possible (copie du lab avec worktrees) |

### Les plus portées

Dix-sept propositions sont portées par les **quatre** profils : PU-PROJ-01, 05, 06, 07, 10, 11, 21, 22, 47, 48, 49, 50, 51, 59, 60, 61 et 72. Parmi elles, celles que les juges citent comme ce qui leur coûte le plus de confiance :

1. **PU-PROJ-01** : la Phase 72 porte deux statuts sur le même écran (« prête à planifier » contre « À recetter »).
2. **PU-PROJ-22** : les messages du panneau après un lancement mentent (« Confirmez-la » après Annuler ou après expiration, « Lancée » avant toute exécution).
3. **PU-PROJ-21** : le bouton « Lancer » n'exécute pas, et rien ne dit d'appuyer sur Entrée.
4. **PU-PROJ-05 et 06** : la carte dit « Fait » alors que des exigences ne sont pas cochées, et la ligne « Reste : vérification, clôture » s'affiche sur des phases sans plan.
5. **PU-PROJ-49, avec 47, 48 et 50** : la liste des lignes non comprises est illisible, le panneau est invisible à l'arrivée et contredit « Santé », et le correctif proposé échoue tel qu'écrit.

## Désaccords entre juges, tels quels

- **Commande brute visible dans la proposition.**
  - j3 : « je vois la commande exacte, le mode et les avertissements avant d'agir, et c'est ce qui me rassure le plus ».
  - j1 compte la commande affichée et mise à jour parmi ce qui l'aide.
  - j2 et j4 demandent de la replier sous « Voir la commande » et de commencer par une phrase en clair (PU-PROJ-30).
- **Mode mémorisé.**
  - j1 : « le mode est retenu », cité comme une aide.
  - j3 et j4 : un mode inattendu peut passer inaperçu, il faut le signaler (PU-PROJ-31).
- **Mission hors phase au « Reprendre » grisé.**
  - j1 et j4 y voient un garde-fou clair (« une mission hors phase dit clairement qu'elle ne se lance pas depuis sa carte »).
  - j2 et j3 y voient une impasse sans alternative (PU-PROJ-35).
- **Délai « Prêt dans un instant ».**
  - j1 : « empêche un clic trop rapide ». j2 : « ça rassure ».
  - j4 : resté plus de 20 s, il faut en dire la cause (PU-PROJ-36).
- **Thème sombre.**
  - j1, j2 et j4 : propre et lisible.
  - j3 : les cartes non sélectionnées sont « presque invisibles » (PU-PROJ-64).
- **Phase 51 « À faire ».**
  - j3 n'y a trouvé aucune section « Lancer du travail ».
  - j2 et j4 y ont lancé « Cadrer » (PU-PROJ-37). Constat factuel divergent, à vérifier.
- **Option « continuer le chat ».**
  - j1, j2 et j3 l'ont trouvée au tour 1.
  - j4 ne l'a pas trouvée au tour 1. Au tour 2, il l'a trouvée seulement après une question passée par le modèle : elle n'apparaît pas après une réponse locale.
- **Découverte du panneau Format** (tour 2) : 1 geste et environ 8 s pour j1, 2 gestes et environ 10 s pour j2 et j3, 3 gestes et environ 15 s pour j4. Tous disent qu'ils ne l'auraient pas cherché sans savoir qu'il existe.
- **Correctif du panneau Format.**
  - j1 veut la commande exacte et un bouton Copier, la proposition au terminal n'étant qu'un « idéalement ».
  - j2 préfère « Demander à l'assistant de corriger » ou « Préparer la correction ».
  - j3 veut une proposition au terminal avec la même confirmation que « Lancer du travail ».

## Ce qui n'a pas pu être jugé

- **Le contenu des réponses du chat passant par le modèle** : elles étaient simulées par le banc. Seule l'interface autour a été jugée (attente « Réflexion… », affichage, relances).
- **Une vraie session Claude Code après le lancement** : le faux `claude` a reçu les bons argv, dont `--permission-mode plan` et `-r … --fork-session`, mais rien au-delà. Le suivi d'une session lancée relève de l'onglet Équipe.
- **Le panneau « Format de la planification » sur une dérive réelle** : il n'a été jugé que sur la dérive injectée au tour 2. Sur le lab réel, conforme, il reste invisible ; c'est en soi le constat PU-PROJ-58.
- **Le profil « responsable de lab non développeur » sur un vrai lab non dev** : faute de lab non dev riche, j2 a jugé sur le planning de ce dépôt, très technique. Une partie du jargon relevé tient à ce lab.
- **Le tiroir du terminal lui-même** : il revient à l'autre volet. Seul le passage de la carte au terminal a été jugé ici. PU-PROJ-26 et 40 débordent sur sa frontière.
- **Mobile et petits écrans réels** : seulement des fenêtres de 1024, 900 et 1280×720 px.
- **Le nœud en échec `parite-fr-en` (`missions/dag-phase26.json`)** : j1 ne l'a pas trouvé dans le cockpit et n'a pas cherché à savoir si c'est voulu.
- **Réserve de banc** : chaque reconnexion d'un script Playwright au navigateur rechargeait le cadre du terminal (j3). Des propositions effacées ou ressurgies, côté j3 et j4 (PU-PROJ-25), peuvent en partie venir de là. Refait dans une seule connexion, le parcours de lancement de j3 fonctionnait.

## Ménage du banc

- Les quatre serveurs (47821 à 47824) sont arrêtés.
- Aucun Chromium de test ni aucun faux `claude` ne tourne encore.
- Le cockpit de Samuel (4456, PID 73670) n'a pas été touché.
- Les copies de lab restent dans `<scratchpad>/panel-projet/`, de `lab-j1` à `lab-j4`, avec la dérive injectée, pour qui voudrait rejouer. Le relais de lancement s'y trouve aussi : `cockpit.sh open|url|stop <lab> <port> <dossier-sorties>`.
- Aucun fichier n'a été écrit dans un worktree, hormis ce rapport. Aucun verrou pris, aucun commit.
