# A7 — Antériorité : ce qui existe, ce qui est tranché, ce qui est inscrit

> Annexe de `.planning/research/2026-11-10-audit-cockpit-etude.md`. Digest de l'agent d'antériorité et de ses deux lecteurs de registres (panel du 2026-11-06, recette du 2026-11-08, registres des Phases 67 à 78, BACKLOG, Phases 73 à 77). Rendu le 2026-11-10 sur `release/v2.77.0` (cockpit v1.4.0 et retours du panel non publiés). Texte de l'agent, chemins ramenés à la racine du dépôt. Les identifiants de suivi (`AUDC-…`) et la destination de chaque constat sont dans `REGISTRE.md`.

---

**Antériorité du cockpit, lue le 2026-11-10 sur `release/v2.77.0`**

Tout est lu dans le fichier cité, sauf mention « inféré ». † : registre de phase (`*-CONTEXT.md`) lu par un lecteur délégué, recoupé sur six identifiants. [M] : décision de manager, pas un arbitrage de Samuel. Sigles en fin de rapport.

**Trois prémisses à rectifier**
- Phases 73 à 77 : aucune exigence CKPT. Chacune porte « Requirements: TBD — posées au cadrage », « Non cadrée », 0 plan, sans dossier de phase ni CONTEXT (ROADMAP § Phase 73 à 77). Les CKPT s'arrêtent à CKPT-28 (Phases 67 et 69).
- « 127 livrées » date de la recette du 2026-11-08 (RECETTE § Comptes). Régressions, promesses rompues et plusieurs partiels ont été corrigés ensuite (CHANGELOG § Non publié), sans recomptage.
- Publié : v2.76.0, cockpit v1.4.0. Le retour du panel est en « Non publié », sans bump.

## 1. Ce qui existe (README, sauf mention)
- **Code** : carte des fichiers et des liens d'appel (moteur floorplan vendorisé), recherche, panneau de détail, Travail récent, Santé, visite, export.
- **Projet** : jalons, phases, plans, exigences et missions lus dans `.planning/`. Quatre états dérivés, avancement lu dans les worktrees, panneau « Format de la planification ».
- **Équipe** : arbre session, manager, workers, actifs et terminés depuis moins de 24 h. Dernière action, nœud de mission, transcript réduit à la demande. Durées ponctuelles seulement (« au travail depuis », « a duré », PU-G-173). Tiroir « Au travail » : verrous (« Qui a la main ») et orphelins.
- **Git** : seconde ligne d'en-tête et tiroir. Graphe borné, détail de commit sans diff, état de chaque worktree, tags, stash, auteurs.
- **Terminal** : tiroir bas sur Projet et Code, macOS et Linux.
- **Lancer** : cartes de phase et de mission. Proposition, bandeau (commande exacte, pré-vols, quatre modes, 120 s), puis Entrée humaine.
- **Demander** : formes courantes répondues sur place, sinon `claude -p` confiné.
- **vf-signal** : pane dans Claude Code à trois vues. Seul endroit qui montre un coût : contexte, dollars et limites de la session courante (SIGNAL, `refresh.ts`, l. 46-57). « Arbitrage attendu » y est déduit du nom d'un nœud de DAG (`derive.ts`, l. 17 et 128).
- **Mobile** : menu « ⋯ » jusqu'à 999 px, panneau de détail fermé sous 1 000 px, feuille du bas sous 701 px, un seul tiroir latéral sous 1 280 px.

## 2. Proposé, pas livré
Les 34 « plus grosses qu'un commit » (PANEL § 3.5) portent un astérisque. État : RECETTE § Comptes et BACKLOG.
- **Clavier** : 031* (cartes atteignables au clavier), 139* (le terminal piège le clavier), 025*.
- **Mobile** : 033* (liste par défaut), 046*, 028*.
- **Texte en clair sans source** : 065*, 073*, 088*, 169*, 185*, 069*, 017*, 104, 080 part C (titres Santé en anglais).
- **Git et Code** : 004 et 005 (Q2 jamais répondue, piste ouverte), 056* (état Git par fichier), 195, 202*, 075* (dates du Travail récent), 076*, 053*, 016*, 007* (partielle).
- **Projet** : 094* et 146* (partielles), 095*, 108*, 109* (« Décisions attendues »), 145*, 157*.
- **Lancement** : 113* (fin d'une proposition, partielle), 129* (lancer dans un worktree, fermé par P72-D-19 [M]), 131*, 135*, 133, 110, 015. Hors périmètre de la 72† : bouton global d'en-tête, « Reprendre » sur les cartes Équipe, lancement en arrière-plan.
- **Équipe** : 168* (markdown du transcript), état « bloqué » sans source dans `who@2`, « attend une tâche de fond » contre « terminé » (#223). Livrées depuis : 162*, 203*.
- **Partiels sans correctif postérieur** (inféré : RECETTE § 2 moins CHANGELOG § Non publié) : 002, 009, 020, 038, 041, 066, 068, 117, 179 (verrou périmé non signalé), 188, 189.
- **Hors panel** (BACKLOG) : `POST /api/ask` pilotable par script, R8 (panneau muet sur l'état de la mission, P70-D-24†).
- **Étude floorplan** (ÉTUDE § 4, § 8) : cartes « prévues » depuis `files_modified`, agent par zone, findings de l'auditeur sur les cartes.

## 3. Tranché par Samuel
Q1 à Q14 : AskUserQuestion, session principale, 2026-11-06 (CHANGELOG § Non publié, premier paragraphe). Canal et date des autres : registres cités.
- **Double geste** : le bouton n'exécute jamais (Q4), une proposition ne prend jamais le focus (Q5), commande et identifiant de reprise restent visibles (Q6), expiration à 120 s (Q7). Raison : seule l'Entrée humaine sépare un clic d'une exécution (P72-D-14 [M]).
- **Copie de commande** : trois boutons, jamais pour un lancement (Q14, motif ClickFix, P72-D-17 [M]).
- **Terminal** : rien sans `--terminal` (P71-D-02†), absent de l'onglet Équipe (Q8). Une session par serveur (P71-D-05†), mais Samuel en demande plusieurs (BACKLOG, 2026-11-05).
- **Modes de lancement** : `default`, `acceptEdits`, `plan` et « hérité du poste », qui peut valoir `bypassPermissions`. La réponse libre de Samuel, « choix + hérité don bypass », a été lue ainsi par le manager, sans nouvelle question (72-CONTEXT, P72-D-02).
- **Couleur** : ni couleur d'alerte, ni pastille orange, ni fond teinté. Glyphe et mot neutre (Q9, DESIGN § 9). Palettes A2 et B2 rejetées (P71.5-D-12†), « pastel lumineux » retenu (CHANGELOG § v1.3.4), « le halo ne revient pas »†.
- **Mise en page** : flou sans fond sous le titre (Q10), points de rupture inchangés (Q11), un tiroir latéral ne pousse jamais la carte (Q12 ; précision de la session principale du 2026-11-11 : le tiroir du terminal, lui, réserve sa place sous la carte, P71-D-35), termes Git gardés avec définition (Q3).
- **Git** : pas de quatrième onglet, jamais de `fetch`, détail de commit sans diff, lecture seule et commandes à copier (P78-D-04 à P78-D-07, CHANGELOG § v1.4.0). Actions Git et revue de diff renvoyées à une phase ultérieure (78-CONTEXT § Deferred Ideas†).
- **Commandes et transcripts** : commande jamais entière (Q13, P67-D-01†), transcript sans sortie d'outil (P69-D-19†), agents terminés visibles 24 h (P69-D-18†).
- **Réseau** : aucun appel sortant hors l'agent des questions (P67-D-02†), donc CI, PR et merge jamais lus (README § Limites connues).
- **Avancement** : option B écartée, donc ni pourcentage pondéré, ni marqueur `[~]`, ni étapes cochées à la main (P69-D-01†, NOTE-69 § 3).
- **vf-signal** : « voir » et « demander l'arrêt » réservés aux agents de la session courante (P68-D-03†).
- **Langue** : choix français ou anglais sorti de la Phase 70 (P70-D-03†, SEED-005), constats de Santé laissés en anglais (P70-D-04†).
- **Divers** : `.planning/` exclu de la recherche Code (DG-09), zoom plancher sur Code seul (PU-G-026), déclenchement de la visite inchangé (PU-G-086).
- **Risques acceptés** : P72-D-22, P69-D-27, jeton lisible par tout processus local (P67-D-19†).
- Depuis le 2026-11-08, les détails sont délégués à l'option recommandée. Gel, merge, release et goût pur restent à Samuel (RECETTE § 10).

## 4. Phases 73 à 77 (ROADMAP § Phase 73 à 77, IDÉES § Les 16 idées)
Contraintes communes : traces locales, aucune lecture réseau, lecture seule, un ajout = un retrait. Ordre arbitré : 73 après la 69, le reste après la 72.
- **73, Gouvernance** : arbitrages en attente reliés à leur phase (idée 9), verrou de driver, worktrees et travail non commité, serveurs orphelins (13), alerte du watchdog sur le nœud (4). Déjà là : « Qui a la main » et l'état des worktrees, recoupement « à trancher au cadrage » (ROADMAP § Phase 78).
- **74, L'équipe dans le temps** : une ligne par agent sur un axe de temps, colorée par nœud de DAG (idée 1, source `meta.json`). Coût en jetons et en durée par mission, phase et agent (2, champ `usage` des transcripts). Replay d'une mission au curseur (3, transitions des DAG, historique git).
- **75, Activité sur le code** : hotspots (5), couplage de changement (6), carte des gardes (7), empreinte des agents (8).
- **76, Traçabilité** : exigence, plan, SUMMARY, VERIFICATION, recette (10), graphe des décisions (11), graphe de la mémoire (14).
- **77, Santé de la méthode** : jauges (12), « depuis ta dernière visite » (15), burn-up en pourcentage strict (16).

Pour la 74 :
- Lu : `who@2` expose `dureeS`, `finAt`, `lastAt`, `ageS` et trois états. Le contrat de forme de Claude Code ne lit ni `usage` ni horodatage de `meta.json` (CONTRAT, clés `schemas` et `claudeCode`). Les registres 67 à 72 et 78 ne disent rien d'une frise ni des coûts†.
- Inféré : aucun code de frise, de coût ni de replay côté web (recherche dans `plugin/cockpit/scripts` et `assets/ui`). Lire `usage` demande d'étendre ce contrat. « Colorée par nœud » heurte DESIGN § 9 et Q9. Une frise au-delà de 24 h rouvre P69-D-18, et aucun historique n'est persisté.

## 5. Limites déclarées et dettes
- README (§ Limites connues, § Les trois onglets) : Windows non mesuré, sortie du terminal non lue par un lecteur d'écran (F6), avertissement « travail non commité » inactif (P72-D-07), onglets à 12 px à 1 024 et 1 440 px en attente d'arbitrage.
- BACKLOG : LANC-12 et onze UIFN non cochées (STATE § Pending Todos), `CLAUDE_EFFORT` et `CLAUDE_PID` hérités (non vérifié).
- Mesuré : 19 fichiers de patch du moteur vendorisé, `00-vibeflow.js` à 298 lignes pour un seuil de 300 (BACKLOG).

## 6. Juges
- Panel du 2026-11-06 (PANEL § 1) : moyenne 53,25. Développeur 55,3, responsable de lab 51,7, nouvel arrivant 52,7, mobile 55, clavier 60, associé ou client 45. Utilité 52 %, lisibilité 48 %, confiance 48 %, finition 68 %.
- Recette du 2026-11-08 (RECETTE § Rapports des juges) : non technique 75, développeur 74, accessibilité 64, responsable de lab 79. Juge de design : 84.

Cinq reproches récurrents (PANEL § 1) :
1. Une vérité lue à deux sources : deux statuts pour la Phase 72, 44 contre 24 (PU-G-093, 054).
2. Un état affirmé sans être suivi : « Confirmez-la » après annulation, « Git est indisponible » (PU-G-113, 191).
3. Du bruit affiché comme du produit : jargon, anglais, markdown brut, sessions en hexadécimal (PU-G-102, 162).
4. Une mise en page tenue à 1 440 px seulement : en-tête tronqué pour 12 juges sur 12, noms de cartes de 3 à 7 px pour 8 (PU-G-001, 026).
5. Le clavier : cartes inatteignables, terminal qui piège, bandeau à 26 Maj+Tab (PU-G-031, 139, 117).

**Chemins**
- PANEL : `.planning/missions/2026-11-06-panel-utilisateurs-GLOBAL.md`
- RECETTE : `.planning/missions/2026-11-08-recette-panel-GLOBAL.md`
- ROADMAP, STATE : `.planning/workstreams/fiabilite/ROADMAP.md`, `.planning/workstreams/fiabilite/STATE.md`
- Registres † : `.planning/workstreams/fiabilite/phases/`
- BACKLOG : `.planning/BACKLOG.md`
- IDÉES, NOTE-69 : `.planning/notes/2026-11-03-cockpit-idees-recherche.md`, `.planning/notes/2026-11-03-cockpit-progression-en-cours.md`
- README, CHANGELOG, CONTRAT : `plugin/cockpit/README.md`, `plugin/cockpit/CHANGELOG.md`, `plugin/cockpit/scripts/vf-cockpit-interface.json`
- SIGNAL : `plugin/cockpit/signal/hooks/`
- DESIGN : `DESIGN.md`
- ÉTUDE : `docs/research/2026-11-01-etude-floorplan-cockpit.md`

## Lecture des registres des Phases 67 à 70

Sept fichiers lus en entier sous `.planning/workstreams/fiabilite/phases/`. Tout est « lu », sauf mention « inféré ».

**Phase 67** — `67-CONTEXT.md`, `67-RECETTE-HUMAINE.md`

Arbitrages de Samuel :
- `P67-D-02`, `P67-D-03` (§ Arbitrages ; « contrainte Samuel, message session principale, 2026-11-01 ») : aucun appel réseau sortant hors l'agent `claude -p`, Cloud retiré ; zéro « Floorplan » visible, export compris.
- `P67-D-01` (AskUserQuestion session principale, 2026-11-01) : dernière commande masquée, jamais exportée.
- `P67-D-06` : sortie dans `.vibeflow/cockpit/` ; aucun `floorplan/` ni `CLAUDE.local.md` écrit dans le lab.
- Recette § 4 (AskUserQuestion session principale, 2026-11-02) : « le MCP Wispr Flow n'est pas retenu » ; D4, I4-I6, I1 reportés, puis repris en 70 avec O5 (`P69-D-11`). § 5 : F-4 « Acceptable » (flèche droite en fin de Trajectoire).

Choix du manager validés par Samuel (section distincte) : `P67-D-14` (`doing` jamais en SSE ni export), `P67-D-15` (agent confiné), `P67-D-17` (aucun LLM à l'assemblage).

Hors périmètre : enrichir l'onglet Code par stack, PR amont des patchs, synchro floorplan v0.6.1 (`P67-D-11`, Samuel).

Risques acceptés : jeton servi à tout processus local (`P67-D-19`, § Addendum) ; secret en premier argument visible (F-B, recette § 5).

**Phase 68** — `68-CONTEXT.md`

Arbitrages de Samuel :
- « Tout accepter (Recommandé) » (AskUserQuestion, session principale Claude Code, 2026-11-03) : `P68-D-03` gestes « voir » et « demander l'arrêt » limités aux agents de la session courante ; `P68-D-04` retard sur `main` sans réseau ; `P68-D-05` élagage par bouton humain.
- Même canal : `P68-D-24`, bloc backlog de la vue macro retiré.
- 2026-11-04 : `P68-D-34` « Rien sous le lab » (aucun fichier du lab exécuté) ; `P68-D-35` R8 → Phase 70, R15 (VS Code, mobile) après la PR ; `P68-D-38` N4-N6 au BACKLOG, N7 (badge « Personne ») inchangé ; `P68-D-41` rafraîchissement continu seulement pane ouverte.

Choix du manager (pas des arbitrages) : `P68-D-11` à `P68-D-21`, `P68-D-27` à `P68-D-30`, `P68-D-36`, `P68-D-37`, `P68-D-39`, `P68-D-42`.

Hors périmètre : retard sur `main` et worktrees dans le cockpit web ; lecture réseau, `git fetch` compris. § Points de procédure : croisement `who@2` / `$.agent.list()` « pas tranché d'avance ».

**Phase 69** — `69-CONTEXT.md`, `69-RECETTE-HUMAINE.md`

Arbitrages de Samuel (AskUserQuestion session principale, 2026-11-03) :
- `P69-D-01` : option A, B écartée. § Points écartés : pourcentage pondéré (précision fausse), état `- [~]` (couche de synonymes), `etapes:` cochées à la main (vert déclaré) ; « B pourra revenir pièce par pièce ».
- `P69-D-18` : actifs + terminés des dernières 24 h.
- `P69-D-19` : transcript sans sorties d'outils, jamais exporté.
- `P69-D-11`, `P69-D-25`, `P69-D-28`, `P69-D-31`, `P69-D-34` : mobile et finitions → 70 ; `P69-D-20` terminal → 71 ; `P69-D-21` lancer du travail → 72.
- `P69-D-15`, `P69-D-16` (manager, validés « je valide D14 D15 D16 ») : lien jamais deviné, jamais l'argument d'une commande.

Hors arbitrage étiqueté : `P69-D-07` (CI, merge, release non affichés ; tag local « à voir plus tard »), `P69-D-08` (statut jamais tiré du STATE), `P69-D-09` (aucune lecture réseau). OQ-2 à OQ-7, OQ-10 : décisions du manager, rouvrables « sur simple objection ».

Risques : `P69-D-27` « J'accepte » (secret en prose, jeton de page). Recette : aucun avis humain dicté ; correctifs des étapes 3 et 6 non rejoués à l'œil ; agent actif relié à son nœud : fixture seulement.

**Phase 70** — `70-CONTEXT.md`, `70-RECETTE-JUGES.md`

Arbitrages de Samuel :
- « Tout accepter (Recommandé) » (AskUserQuestion, session principale Claude Code, 2026-11-03) : `P70-D-03` langue FR/EN hors 70, `?lang=en` non touché ; `P70-D-04` constats de Santé laissés en anglais.
- 2026-11-04, réponses relayées par le manager (§ Tri) : `P70-D-22` badge « au travail » réduit à son point ; `P70-D-23` conserve le centrage borné de la visite, l'éclairage sans sélection, « composant » et « prioritaire ».

Choix du manager : `P70-D-09` à `P70-D-15`, `P70-D-20`, `P70-D-21`, `P70-D-24`. Alertes :
- `P70-D-24` envoie au BACKLOG le R8 que Samuel avait passé en 70 (`P68-D-35` ; panneau web muet sur l'état de la mission).
- `P70-D-22` et `P70-D-23` : rangées sous « Choix du manager », mais dites arbitrages de Samuel ; l'extension de `P70-D-22` à 701-1 599 px « n'est pas un nouvel arbitrage » (session principale).

Écart connu (recette) : carte Session « en attente » à badge « En cours », au BACKLOG.

**Sujets transverses** (négatifs vérifiés par mots-clés)
- Suivi dans le temps : borné à 24 h (`P69-D-18`, `P68-D-03`). Frise, timeline : rien trouvé.
- Coûts, jetons LLM : rien trouvé (« jeton » = authentification, « coût » = rafraîchissement).
- Réseau, CI, PR : fermé par `P67-D-02` (Samuel), repris par `P69-D-09` ; voir `P68-D-04`, `P69-D-07`.
- Écriture dans `.planning/` : aucune règle explicite trouvée ; seule borne, `P67-D-06`.
- Actions : pane seulement (`P68-D-03`, `P68-D-05`) ; côté web, renvoi aux Phases 71 et 72 (inféré). « kill » : un helper de test uniquement (`P69-D-24`).
- Langue : entrée BACKLOG ouverte (`P70-D-03`). `P67-D-20` : l'anglais « peut etre un des langues autorisées » (Samuel) ; la suite est une « lecture, pas arbitrage ».
- Export : uniquement des exclusions (`P67-D-01`, `P67-D-14`, `P69-D-19`).
- Multi-lab : rien trouvé ; seulement un port stable par lab (recette 67 § 7).

## Lecture des registres des Phases 71 à 78

Tout est **lu**, rien n'est inféré. AUQ = « AskUserQuestion, session principale [Claude Code] ». **[M]** = décision du manager, pas un arbitrage humain. Raisons : seulement celles écrites. Section « Deferred Ideas » : 78 seulement ; « Points ouverts » : aucune.

## Phase 71
- **Samuel** (§ Arbitrages de Samuel, AUQ, 2026-11-03) : `P71-D-02` rien sans `--terminal` ; `P71-D-05` une seule session par serveur ; `P71-D-07` Windows hors périmètre.
- **Samuel** (§ … sur l'audit et § … sur la recette par juges, AUQ, 2026-11-04) : `P71-D-28` à l'arrêt, toute la session meurt, `nohup` et `disown` compris ; `setsid` = limite écrite au README ; `P71-D-37` « G6 écarté par Samuel » (cran minimal du tiroir, 10 lignes pour `claude`).
- **[M]** `P71-D-09` pas de WebSocket ; `P71-D-13` jamais de cookie (non cloisonné par port) ; `P71-D-15` sens P → Q fermé, déni de service accepté (amendée par `P72-D-09`).
- **Hors périmètre** (§ Phase Boundary) : plusieurs sessions ou onglets de terminal, modèle de sécurité de la page Projet.
- **Risque** : § Limite de fond (dépôt hostile, extension de navigateur).
- **71-RECETTE-HUMAINE.md**, § Recette jouée par Samuel le 2026-11-05 : « il faudrait pouvoir en ouvrir plusieurs », « inscrit au BACKLOG par la PR #208 ». § Rejeux réduits : « Goût résiduel » sans arbitrage cité (texte des cartes petit en 1280×720, tiroir ouvert) ; « le serveur du cockpit se bloque toujours toutes les 5 s » (`P71-D-33` : minuterie de la 69 non touchée).

## Phase 71.5
- **Samuel**, § Retour de Samuel sur le lot de goût (« Session principale Claude Code, 2026-11-05, dicté ») : `P71.5-D-12` palettes A2 « Graphite vivant » et B2 « Signal tempéré » rejetées, retour à Graphite (« les couleurs sont mieux avant ») ; `P71.5-D-13` liserés et bordures colorés, bandeau coloré du message principal : alternative sobre exigée.
- **Samuel**, § Lot de goût tranché (AUQ, 2026-11-05) : `P71.5-D-18` tous les motifs de `anti-slop.md` ; `P71.5-D-19` pastille sans fond teinté ; `P71.5-D-21` barres neutres sauf en cours ; `P71.5-D-28` plus d'anneau coloré ; `P71.5-D-27` « (b) Vifs propres » remplacé par « (d) Pastel lumineux ».
- **Samuel**, § Espacements (AUQ, 2026-11-05) : `P71.5-D-01` grille fermée, « ni 10, ni 14, ni 22 ».
- § Rendu jugé et arbitrages du 2026-11-06, message direct, non numéroté : « le halo ne revient pas » (« dommage […] mais on peut faire avec »).
- **[M]** `P71.5-D-08` direction C « Atelier » écartée (64/100) ; `P71.5-D-10` cartes du téléphone trop larges, « consigné pour le backlog ».

## Phase 72
- **Samuel** (§ Arbitrages de Samuel, AUQ, 2026-11-05) : `P72-D-01` « Terminal au repos seulement » ; `P72-D-02` modes `default`, `acceptEdits`, `plan`, « hérité du poste » (qui peut valoir `bypassPermissions`) : la règle du panel « bypassPermissions jamais depuis une carte » est **levée** (réponse libre « choix + hérité don bypass », « Lecture confirmée par le manager ») ; `P72-D-02bis` présélection du dernier mode, risque de détournement de clic connu ; `P72-D-07` avertissement « travail non commité » prévu, inactif, à alimenter par la 78.
- **Samuel** (AUQ, 2026-11-06 ; rangé sous § Décisions techniques du manager) : `P72-D-22` « Garder, risque écrit » : un script de la page Projet peut proposer la reprise d'une conversation qu'il a écrite ; options B' et D écartées.
- **[M]** `P72-D-14` double geste (délai d'armement, Entrée), dû « dans tous les cas » (`P72-D-02bis`) ; `P72-D-13` aucun texte du lab dans le shell ; `P72-D-15` lancement à la racine du lab ; `P72-D-17` pas de repli « copier la commande » (motif ClickFix).
- **Hors périmètre** (§ Phase Boundary, sans arbitrage numéroté) : bouton global d'en-tête, « Reprendre » sur les cartes Équipe, plusieurs sessions, lancement en arrière-plan sans terminal, routes agissant sur Git. BACKLOG : `POST /api/ask`.
- **72-RECETTE-REGLAGES.md** : aucune décision de Samuel.

## Phase 78
- **Samuel** (§ Arbitrages de Samuel, AUQ, 2026-11-05) : `P78-D-04` pas de 4ᵉ onglet (« trois onglet sont suffisant et git peut ne pas etre installé ») ; `P78-D-07` lecture seule, commande à copier ; `P78-D-05` jamais de `fetch` ; `P78-D-06` détail de commit « sans diff ».
- **Samuel** (AUQ, 2026-11-06 ; rangés sous § Décisions du manager pendant l'exécution) : `P78-D-34` seconde ligne masquée sous 1280 px, « pas de retour en arrière » ; `P78-D-37` découvrabilité gardée telle quelle.
- **[M]** `P78-D-21` `git diff` contre l'arbre de travail proscrit, compte de fichiers « approximatif » (ratifiée par Samuel) ; `P78-D-41` filet de 5 s synchrone « assumé ».
- **§ Deferred Ideas** : « Actions Git exécutées par le cockpit (fetch, branche, worktree…) : phase ultérieure, après recette (P78-D-07) » ; « Revue de diff complète ». Verrous, watchdog, hotspots : Phases 73 et 75 (`P78-D-08`).

## Point 4 : le reste
- `commit`, `push`, `checkout` comme actions : rien trouvé ; bascule de branche : commande `git switch` à copier (`P78-D-07`, `P78-D-29` [M]).
- Autre worktree : aucun arbitrage de Samuel ; `P72-D-15` [M] ; `P71-D-04` (`cwd` racine, `cd` libre).
- `auto` : hors liste des modes ; cité seulement au réglage 5 de 72-RECETTE-REGLAGES.md, sans arbitrage.
- Suivi des sessions dans le temps : rien trouvé hors `P72-D-16` [M].
- Coûts, jetons : rien trouvé.

Fichiers lus :
- .planning/workstreams/fiabilite/phases/VFDO-71-terminal-integre-cockpit/71-CONTEXT.md
- .planning/workstreams/fiabilite/phases/VFDO-71-terminal-integre-cockpit/71-RECETTE-HUMAINE.md
- .planning/workstreams/fiabilite/phases/VFDO-71.5-unslop-espacements-cockpit/71.5-CONTEXT.md
- .planning/workstreams/fiabilite/phases/VFDO-72-lancer-travail-depuis-cartes-cockpit/72-CONTEXT.md
- .planning/workstreams/fiabilite/phases/VFDO-72-lancer-travail-depuis-cartes-cockpit/72-RECETTE-REGLAGES.md
- .planning/workstreams/fiabilite/phases/VFDO-78-git-dans-le-cockpit/78-CONTEXT.md
