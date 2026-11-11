# Phase 73: Gouvernance au cockpit — arbitrages en attente, worktrees et verrous - Context

**Gathered:** 2026-11-11
**Status:** Cadrée (2026-11-11) — frontière de questions vide ; questions non bloquantes à Samuel en fin de fichier

Cadrage porté par le manager de la mission Phase 73 (`vf-dev-manager`, mode autonome, design forcé ; worktree
`.claude/worktrees/phase-73`, branche `feat/phase-73-gouvernance-regie`, base `f763b556` = `integration/cockpit-audit` :
release v2.77.0 + lot 0 de l'audit). Jalon `vibeflow-v2.0`, compartiment `fiabilite`. Cadrée en même temps que les
Phases 74, 75, 76, 77, 79 et 80 (vague lancée par Samuel le 2026-11-11). Entrées : étude
`.planning/research/2026-11-10-audit-cockpit-etude.md` § 8.2 (bloc Phase 73) et § 9 ; `REGISTRE.md`, `DESIGNS.md` § 1-3
et § 9 du dossier `.planning/research/2026-11-10-audit-cockpit/` ; note `.planning/notes/2026-11-03-cockpit-idees-recherche.md`
(idées 9, 13, 4) ; rapport du lot 0 `.planning/missions/2026-11-11-audit-cockpit-lot-0.md` ; contrats de la Phase 79
(`79-CONTEXT.md` § « Contrats fournis », branche `feat/phase-79-socle-cockpit`, commit `3119d82a`) ; `74-CONTEXT.md`
(P74-D-02 à D-04, branche `feat/phase-74-…`, commit `f87ae937`) ; `DESIGN.md` direction « Graphite ».
Trois éclaireurs en lecture seule (code de l'onglet Équipe, sources de gouvernance, arbitrages en vigueur) et un panel
de trois chercheurs (« À vous » et impact ; architecture de la page ; état « relu », notifications, « ailleurs ») ont
établi les faits ; la spec d'interface `73-UI-SPEC.md` a été écrite en parallèle et se conforme à ce fichier.

**Exigences :** REGI-01 à REGI-16. Préfixe neuf, vérifié libre le 2026-11-11 dans tous les ledgers
`.planning/workstreams/*/REQUIREMENTS.md`, dans le dépôt (`git grep`) et sur les branches des Phases 7x/8x, d'intégration
et `main` (témoin positif du même contrôle : `REG-D-01` trouvé).

<domain>
## Phase Boundary

L'onglet Équipe cesse d'être un canevas : il devient une **régie**, une liste par état en quatre sections — « À vous »
(ce qui attend une décision humaine, classé par ce que l'attente retient en aval), « Au travail » (l'arbre session →
manager → workers, le tenant du verrou et l'alerte du watchdog posés sur la mission), « Terminé, à relire » (agents finis
dont le transcript n'a pas été ouvert), « Au repos ». Un bloc replié en pied de page dit les worktrees et leur travail non
commité, lus par les routes de la Phase 78. Le titre de l'onglet dit « (N) vous attendent ». Une ligne « ailleurs sur ce
poste » dit qu'une session d'un autre lab attend (nombre et nom du lab seulement). Tout est en lecture seule ; la seule
action d'une ligne est « Lire le rapport ».

Le but inscrit au ROADMAP le 2026-11-03 est inchangé ; l'audit y ajoute une forme (la régie), pas un autre but.

**Hors périmètre :**
- « Répondre », « Ouvrir », « Recetter », « Demander l'arrêt » d'un orphelin, toute action sur une session : AUDC-Q3
  (Samuel, 2026-11-11 : plus tard) → Phase 81.
- L'axe du temps (frise), la fiche d'agent, le lecteur plein cadre : Phase 74 (P74-D-02 à D-04). La 73 pose les points
  d'accroche (P73-D-20), pas leur contenu.
- La collecte, le flux, la route d'état, la coquille statique : Phase 79 (contrats C0-C6). La régie ne les attend pas.
- Relire git : les données de worktrees viennent des routes de la Phase 78 (P78-D-08, P78-D-32).
- La notification du système (API Notification) : reportée (P73-D-15).
- Terminal, « Demander » et bloc Santé sur l'onglet Équipe : Q8 / P71-D-08, plan 69-05, lot 0 (AUDC-M3).

**Retraits (un ajout = un retrait, registre § 3, étude § 9) :** le canevas de l'onglet Équipe (graphe ELK, cartes
`se-`/`ag-`, rechargement de page quand l'ensemble des cartes change) ; le nom d'un agent écrit trois fois (titre de
carte, description, titre de panneau) ; la carte « Terminés depuis moins de 24 h » et le pli homonyme du tiroir « Au
travail » ; le panneau d'item d'Équipe et ses trois styles de bouton ; la section Santé encore calculée et injectée sur
Équipe (masquée en CSS seulement depuis le lot 0) ; la règle P70-D-20 (zoom d'Équipe en bas à gauche) et UIFN-14, devenues
sans objet.
</domain>

<decisions>
## Implementation Decisions

### Décisions déjà rendues sur lesquelles la phase se bâtit (rappel, jamais rouvertes)

- **Direction « régie »** retenue par Samuel le 2026-11-11 (registre § 5.1, relayée par le brief de mission : « Régie,
  frise, fiche d'agent et Projet en couloirs sont retenus comme direction ; leur détail reste à recetter »). Elle
  **amende P69-D-17** (« Équipe en carte comme Code et Projet ») : la carte de l'onglet Équipe est remplacée par la régie.
- **AUDC-Q4** (Samuel, 2026-11-11) : `claude agents --json` source de référence de l'état, derrière le contrat de forme,
  transcripts en repli. **AUDC-Q3** : actions sur une session reportées. **AUDC-Q2** : fenêtre de 24 h gardée.
- **Lot 0** (« Décisions » du rapport) : « vous attend » et « close » d'une session ne viennent que de l'état officiel ;
  un état vivant n'est jamais écrasé ; titre « N agents actifs » ; santé retirée d'Équipe ; glyphes du lot 0.
- Bornes du jalon : P67-D-14, P69-D-15, P69-D-16, P69-D-18, P69-D-19, P69-D-23, P68-D-03, P78-D-04, P78-D-07, Q5, Q8,
  Q9, Q11, Q12, P71.5-D-01, PU-G-162 (table complète : section « Bornes contrôlées » plus bas).

### Décisions du manager (toutes : décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée)

Chaque décision ci-dessous est une décision déléguée par Samuel (message session principale, 2026-11-08), option
recommandée ; l'option recommandée vient du panel ou de l'éclaireur cité. Aucune ne vaut arbitrage de Samuel.

**Forme de la page**

- **P73-D-01 (régie, quatre sections).** Ordre fixe : « À vous », « Au travail », « Terminé, à relire », « Au repos »
  (DESIGNS § 3). Un agent qui attend figure dans « À vous » ET à sa place dans l'arbre « Au travail ». Les compteurs de
  section comptent les lignes ; le sous-titre de l'onglet compte les agents distincts en vie (spec C-16). Section vide :
  une ligne d'état vide, jamais une section masquée (sauf « À vous » vide : « Rien ne vous attend »).
- **P73-D-02 (rendu côté page).** Le serveur ne produit plus de cartes pour Équipe ; la régie est dessinée par la page à
  partir de l'objet `who@2` et du flux `lock`. La fonction de rendu prend un objet `who` et un objet `lock` et ne sait pas
  d'où ils viennent ; un adaptateur unique lit `window.VF_ETAT.lire('who')` / `abonner` s'il existe (coquille de la
  Phase 79, C4/C5), sinon l'événement de document `vf-who` et `window.__vfLive` (état présent). Motif : livrer sans
  attendre la 79 et lui laisser un rendu indépendant de la source (panel B, B1).
- **P73-D-03 (schéma `cockpit-equipe@1` gardé).** L'enveloppe d'Équipe garde son schéma `@1` : `nodes` toujours vide,
  `meta` conservée (`vfTab`, `vfGit`, `vf.missions`, `vf.compte`) parce que l'en-tête (`76-vf-git-entete.js`) et la parité
  R4.1 la lisent. Aucun champ n'est retiré, donc pas de bump (règle C0 de la 79) ; la route C5
  `GET /api/vf/graphe?onglet=equipe` de la 79 reste stable. La description du schéma (`vf-cockpit-interface.json`,
  README du module) dit « coquille sans cartes depuis la Phase 73 ». Le panel recommandait `@2` ; écarté sur le contrat C5
  arrivé après lui.
- **P73-D-04 (témoins re-pointés, jamais supprimés pour verdir).** Les témoins du canevas d'Équipe (`test-cockpit-equipe.sh`
  E23.3-5, EUI2.10-16, EK10/13/14/17 ; `chrome-moteur-carte.mjs` sur `equipe.html` ; `test-cockpit-who.sh:613-681` ;
  `test-cockpit-equipe-etats.sh` M3.6, M3.8, D2c ; `test-cockpit-lecture-fil.sh:147`) sont mis en conformité : chaque
  propriété testée suit son nouveau support. La copie figée de `vf-cockpit-equipe-carte.mjs` et son SHA256
  (`test-cockpit-lancer-suivi.sh:30-41`, LE.0-LE.5) n'est ni re-figée ni supprimée : LE.* deviennent LR.* sur le nouveau
  support de la ligne de lancement (P73-D-21), même propriété, correspondance LE → LR écrite dans l'en-tête de la suite et
  au CHANGELOG.
- **P73-D-05 (une seule suite neuve au plus).** Les témoins de la régie vivent dans une suite neuve
  `test-cockpit-regie.sh` (harnais VM Node + Chrome headless des suites existantes) ; le compteur gaté « 213 suites » des
  deux README passe à 214, recompté au rebase de la dernière vague (la 74, la 79 et la 80 le touchent aussi).

**« À vous » et ce qu'elle bloque**

- **P73-D-06 (sources de « À vous »).** Deux sources en Phase 73 : (a) les sessions à l'état officiel `attend` (« vous
  attend », lot 0, inchangé) ; (b) les phases dont un `*-VERIFICATION.md` porte `status: human_needed` dans son en-tête,
  lues en en-tête seul (aujourd'hui seule la présence du fichier est lue), rendues en ligne de niveau phase « Phase N :
  vérification humaine demandée » reliée à la carte de la phase dans Projet. Écartées : une question `AskUserQuestion`
  sans réponse lue au transcript (rouvrirait la décision D2 du lot 0, voir « À Samuel » S-2) ; les sections « À Samuel »
  des CONTEXT et des rapports (prose sans forme commune) ; les points d'arrêt des plans (disent « s'arrêtera », pas
  « attend ») ; les escalades `SendMessage` (pas sur disque) ; « à recetter » (reste à Projet ; doublon avec « Terminé, à
  relire »). Une ligne de session et une ligne de phase de la même phase restent deux lignes (P69-D-15).
- **P73-D-07 (classement par impact, AUDC-I02).** L'aval d'une attente = nombre de nœuds non terminés atteignables en
  aval de son nœud dans un DAG de mission déjà découvert par le cockpit (fermeture transitive inverse des `deps`, fonction
  pure). Le nœud d'une session se lit par le rattachement existant (registre du verrou, puis mandat), jamais deviné
  (P69-D-15). Une session détentrice du verrou d'une mission sans nœud rattaché : « retient toute la mission » = nombre de
  nœuds non terminés de ce DAG, seulement s'il est visible. Tri en trois rangs : impact connu > 0 (décroissant), impact
  inconnu, impact connu = 0 ; dans un rang, la plus ancienne attente d'abord. Libellés : « retient N nœuds », « retient
  toute la mission · N nœuds », « impact inconnu ». Une ligne de niveau phase (`human_needed`) porte « impact inconnu » : aucun plan de mission
  ne la rattache à un nœud. Source des DAG : le résumé de plan publié à côté du verrou par la 79 (amendement A16, plan 79-03 :
  identifiants, dépendances, statut, compartiment et phase, jamais le texte des nœuds), désigné par le champ `dag` de
  l'état des verrous (A15) ; en plus, les DAG déjà découverts aujourd'hui. Une mission sans plan publié reste « impact
  inconnu ». Plans dépendants marqués « à revalider » jusqu'à la fusion de 79-03.

**Gouvernance de la mission**

- **P73-D-08 (tenant du verrou).** Affiché par mission, sur la ligne de mission de la section « Au travail » (« verrou :
  <owner réduit> · <étape> · depuis N ») ; une ligne d'en-tête pour le seul verrou de dépôt. Source : l'événement `lock`
  et le champ `lock` de `hello` dans la forme projetée par la 79 (amendement A15 : `{seq, at, verrous}`, chaque entrée en
  liste blanche `ws`, `scope`, `phase`, `step`, `tenu`, `stale`, `ageS`, `ttl`, `progressAgeS`, `owner` ≤ 80 caractères,
  `childrenRunning`, `dag`) ; avant la fusion de A15, la régie lit les mêmes champs dans la forme brute présente
  (`age_seconds`, `progress_age_seconds`, `children_running`). La page garde sa propre liste blanche de ces champs, en
  défense de plus : aucun autre champ n'entre dans le DOM, le stockage ou l'export. Classe de risque : exposition
  d'identifiants du poste vers un client local. Les
  règles de vivacité de mission du socle (P68-D-05, D-22, D-23, D-26, D-27) s'appliquent telles quelles.
- **P73-D-09 (alerte du watchdog sur le nœud).** « Verrou abandonné » vient de `stale` (le critère exact du watchdog).
  « Sans progrès depuis N min » se dit quand `progress_age_seconds` dépasse la fenêtre de stall, au conditionnel de la
  source (« aucun nœud marqué depuis N min ») : le watchdog compte aussi les commits récents, que la page ne lit pas — on
  n'invente pas un verdict qu'il n'a pas rendu. La marque se pose sur la ligne de mission, et sur les nœuds `running` du
  DAG quand il est visible. Fenêtre en une seule source : `VF_STALL_WINDOW` de l'environnement du serveur, sinon la
  valeur par défaut extraite de la ligne `STALL_WINDOW=` de `plugin/conductor/scripts/check-guard-health.sh` ; extraction
  impossible = seuil « inconnu », rien n'est marqué. Témoin : muter cette ligne fait rougir la suite. Texte neutre, ne
  reclasse rien (spec C-11). Mot d'interface : « veilleur » n'est pas retenu ; la ligne dit « sans progrès » / « verrou
  abandonné », sans nommer l'outil.
- **P73-D-10 (worktrees).** Bloc replié en pied de régie, « Arbres de travail (N) », lu à l'ouverture et au déclenchement
  de l'événement `git`, par jointure sur le chemin de `GET /api/vf/git` (branche) et `GET /api/vf/git/worktrees`
  (comptes : modifiés, non suivis, propre, avance/retard) — aucun appel git neuf. Pastilles neutres sur la régie (Q9).
  Ce n'est pas une cinquième section : ce ne sont pas des agents. Un worktree non vérifié dit « non vérifié » (P78-D-38).

**États des agents**

- **P73-D-11 (vivacité, AUDC-I03).** Décroissance « au travail » → « silencieux » (> 120 s sans outil en cours ni
  écriture, `CALME_S`) → « suspect » (> fenêtre de stall, même source que P73-D-09, 900 s par défaut). Une commande en
  cours reste « au travail » jusqu'à 15 min (seuil existant Q13). « Suspect » n'existe qu'en dessous de 1 800 s :
  au-delà, la collecte retire l'agent (`SILENCE_MAX_S`), elle n'est pas modifiée en Phase 73 ; le compteur
  `sortisSilence` de `who@2` (amendement A20 de la 79) est dit en pied de « Au travail » (« N muets depuis plus de 30 min,
  retirés ») quand il est présent et non nul. Mot neutre, pas de corail (Q9 ; spec C-03).
- **P73-D-12 (« attend ses agents », AUDC-I38).** Champ facultatif `attendAgents` de `who@2` : nombre lu sur la dernière
  ligne `system`/`turn_duration` (`pendingBackgroundAgentCount`, absent = 0), pour une session seulement, affiché
  « attend ses agents (N) » si N > 0, si la session n'est pas `actif` et si cette ligne est la dernière écriture.
  `waitingFor` de l'état officiel : non observé, hors cadrage. Clôt le sujet BACKLOG #223 cause 3 (registre § 4).
- **P73-D-13 (orphelin en ligne de régie, reste de AUDC-D4).** Un agent vivant dont le parent est terminé (règle du lot
  0) figure dans « Au travail » sous la ligne grisée de son parent, avec le mot « orphelin » (neutre) ; aucune action
  (Q3, P68-D-03). Le garde du lot 0 qui nomme l'orphelin est réutilisé, pas recopié.
- **P73-D-19 (glyphes).** Le jeu de glyphes du lot 0 et du tiroir « Au travail » est gardé tel quel, y compris
  « vous attend » en `--text-2` ; la proposition jaune `--st-recette` de la spec (C-01) et les glyphes de la maquette de
  l'audit (DESIGNS § 2) ne sont pas retenus : un seul jeu de formes, aucune couleur d'alerte (Q9).

**Relire, notifier, ailleurs**

- **P73-D-14 (« Terminé, à relire » et le tiroir « Au travail »).** « Rapport » = le transcript réduit
  (`/api/vf/transcript`, `cockpit-transcript@2`, P69-D-19/D-23). « Lu » = ouvert explicitement dans ce navigateur :
  `localStorage`, une clé par lab, identifiants et heure seulement, purge des entrées de plus de 24 h au chargement,
  jamais exporté, repli sans stockage = tout terminé < 24 h est « à relire ». Marqué à l'ouverture du lecteur, jamais au
  survol. « Tout marquer comme relu » (spec C-08) : retenu, même style. Aucune route d'écriture (le serveur refuse tout
  ce qui n'est pas GET hors `--terminal`). Le tiroir « Au travail » (P69-D-14) reste sur Projet et Code et n'est plus
  ouvert sur Équipe (le bouton « N au travail » y mène à la section) ; son pli « Terminés depuis moins de 24 h »
  devient le lien « N à relire dans Équipe ».
- **P73-D-15 (notifications, AUDC-I09 partiel).** Titre d'onglet « (N) vous attendent » où N = lignes de « À vous » ;
  pastille de favicon en `data:` (chiffre ou point neutre, ton Graphite). Un seul compositeur du titre remplace les trois
  écrivains actuels (`00-vibeflow.js:13`, `76-vf-git-entete.js:19`, observateur de `80-vf-fr.js:147`) ; témoin : le
  préfixe survit à un événement `git` et à la traduction. Le titre ne compte que « vous attend » ; « fin » et
  « échec » ne changent ni le titre ni la pastille : ils s'écrivent sur la ligne de « Terminé, à relire » (mot « échec »
  ou « arrêté » quand `finMotif` de `who@2`, amendement A20, vaut `echec` ou `arret` ; rien sinon). Jamais de focus volé
  (Q5). La notification du système est reportée (BACKLOG, « À verser »).
- **P73-D-16 (« ailleurs sur ce poste », AUDC-I10).** Une fonction exportée `ailleurs()` posée en fin de
  `vf-cockpit-etat-officiel.mjs` (amendement A18 de la 79), sans toucher `formeEtats` : elle lit `cwd` dans la liste officielle (qui couvre tout le
  poste), compte les sessions `attend` hors des arbres du lab, et ne rend que `[{lab, n}]`. Nom du lab = dernier segment
  du chemin après retrait d'un suffixe `/.claude/worktrees/<n>` ; dossier personnel, un de ses ancêtres ou chemin trop
  court → « un autre dossier ». `cwd` ne sort jamais du module ; jamais de git dans un autre dépôt ; jamais de titre ni de
  nom de session ; sans état officiel, pas de ligne (pas de « 0 »). **Le nom d'un autre lab ne vit que dans la page
  servie** (borne relayée par la session principale le 2026-11-11 depuis la coordination avec la Phase 79) : jamais dans
  l'export, jamais dans un fichier du lab (cache du cockpit compris), jamais dans `who@2`, `cockpit-signal@1`,
  `cockpit-state@1` ni aucun flux lu par `vf-signal`. Il est donc servi par sa propre route à la demande
  `GET /api/vf/ailleurs` (`vibeflow/cockpit-ailleurs@1`, `[{lab, n}]`), inscrite dans la table des routes et derrière la
  fonction d'accès unique de la 79 (amendement A10/A11) quand elle existe, sinon derrière les contrôles présents de
  `serve.mjs` ; lue par la page à l'ouverture de l'onglet et sur l'événement `who`. Témoin de non-fuite à sentinelles
  (identifiant, titre, chemin complet, dossier parent, nom du lab) : témoin positif d'abord (la page affiche « 1 » et le
  nom), puis absence du nom et des autres sentinelles dans l'export, dans tout fichier écrit sous le lab pendant le test,
  dans les trames du flux, dans `who@2` et dans l'objet d'état ; `/api/vf/transcript` refuse l'identifiant sentinelle ; un
  faux `git` qui journalise son répertoire n'est jamais appelé hors des arbres du lab ; mutant qui laisse passer `cwd` ou
  qui verse la liste dans `who@2` → rouge. Compatible avec AUDC-B-01 (aucun transcript d'un autre projet n'entre) et
  AUDC-V10 (source officielle seule).

**Boutons, santé, accroches, lancement**

- **P73-D-17 (un style de bouton, AUDC-F2).** Les actions de la régie prennent le seul style `.btn` doux du viewer ;
  les boutons-icônes du tiroir restent une catégorie distincte, documentée. Les styles `[data-vf-doing]` /
  `[data-vf-transcript]` partent avec le panneau d'Équipe. EK1 est ré-ancré sur l'action de la ligne de régie ; EK8
  (tiroir, Projet) ne change pas.
- **P73-D-18 (santé sur Équipe).** La section Santé n'est plus calculée ni injectée sur Équipe (aujourd'hui masquée en
  CSS seulement) ; M3.8 suit le nouveau support.
- **P73-D-20 (accroches de la Phase 74).** Contrat déclaré par la 73, sans fichier de la 73 à retoucher par la 74 :
  conteneur `section#vf-equipe` injecté en JS (le `#stage` du canevas masqué sur Équipe), en-tête `#vf-equipe-entete`,
  vues `.vf-vue[data-vf-vue="regie"]` ; registre `window.__vfEquipeVues.declarer({id, libelle, monter(el), demonter()})` ;
  la bascule « Régie · Frise » (P74-D-02) est dessinée par la 73 dès que deux vues sont déclarées, donc jamais de bouton
  mort ; ouverture d'un agent = événement de document annulable `vf-agent:ouvrir` `{id, kind, declencheur}` — sans
  `preventDefault`, la 73 ouvre le lecteur actuel (repli) ; la 74 l'annule et ouvre sa fiche (P74-D-03/04) ; événement
  `vf-agent:lu {id}` pour « Terminé, à relire » ; chaque ligne porte `data-vf-agent`, `data-vf-noeud`, `data-vf-etat` ;
  les ancres `#r=n:se-<id>` / `n:ag-<id>` ne changent pas de forme et, sur Équipe, sont traitées par la régie
  (défilement + focus sur la ligne) au lieu du canevas — garde `TAB==='equipe'` posée sur une ligne existante de
  `00-vibeflow.js` (298 lignes, plafond 300). La spec § 9 se conforme à ces noms.
- **P73-D-21 (ligne « Lancée depuis la carte », 72-07).** Champ facultatif `lancee` `{phase, ws, verbe}` de `who@2`,
  revalidé à l'émission par la même garde qu'aujourd'hui ; rendu sur la ligne de session.
- **P73-D-22 (nettoyage d'affichage de la branche).** Le retrait des caractères de contrôle et de sens d'écriture sur
  la branche et le titre passe à l'émission (`vf-cockpit-who.mjs`) au lieu de vivre dans `vf-cockpit-equipe-carte.mjs` ;
  les mutants de `test-cockpit-who.sh:679-681` sont re-pointés.
- **P73-D-25 (export et recherche sur Équipe).** L'export de l'onglet Équipe n'emporte rien de la régie (l'enveloppe
  seule) ; la recherche filtre les lignes de la régie par nom et rôle visibles, côté page.
- **P73-D-27 (colonne « contexte »).** Absente en Phase 73 : aucune source n'émet un taux de remplissage du contexte ;
  la Phase 74 lit les jetons depuis l'index de la 79 (C6). Spec C-04 sans objet ici.

**Vagues et coexistence avec les autres phases**

- **P73-D-23 (vagues).** Vague 1, données pures : module de gouvernance neuf (« À vous », aval, vivacité, attend ses
  agents, orphelin), branchement dans `who.mjs`, champs facultatifs de `who@2` dans `vf-cockpit-interface.json`,
  `ailleurs()`. Vague 2, rendu : fichiers d'interface neufs de la régie, contrat P73-D-20, compositeur du titre, style
  de bouton. Vague 3, retraits et témoins : coquille d'Équipe (`pageEquipe` / enveloppe `@1` sans cartes), réduction de
  `vf-cockpit-equipe-carte.mjs` à la coquille et aux missions, retrait du canevas dans `72-vf-equipe.js`, garde du tiroir
  dans `70-vf-live.js`, santé, témoins re-pointés, LR.*, README (compteur), CHANGELOG. La vague 3 concentre les fichiers
  partagés et se joue après rebase sur la 79 ou la 80, selon celle qui fusionne la première. Chaque plan dit ce qui
  change s'il passe avant ou après la coquille de la 79 (C5) : avant, l'enveloppe d'Équipe sort de `pageEquipe`
  (`vf-cockpit-server.mjs`) ; après, de la route `GET /api/vf/graphe?onglet=equipe` — même constructeur, même schéma.
- **P73-D-24 (moteur vendorisé).** Ni `viewer.html` ni un autre fichier du moteur ne sont modifiés : aucun diff de patch à
  régénérer, neutre vis-à-vis du retrait de `plugin/cockpit/amont/` par la 79 (C6). Un fichier d'interface neuf prend sa
  ligne `AJOUT` dans `VENDORED.txt`, à sa place dans le tri, ou rien si la 79 a déjà réduit `VENDORED.txt` à l'origine.
- **P73-D-26 (plafond des fichiers d'interface).** Chaque fichier `ui/*.js` neuf ou touché reste ≤ 300 lignes
  (`70-vf-live.js` est à 285, `00-vibeflow.js` à 298) : les ajouts vont dans des fichiers neufs ; dans 00 et 70, seules
  des lignes existantes sont modifiées (aucun ajout net de ligne), au plus deux par fichier (titre et garde d'ancre dans
  00 ; pli du tiroir et bouton « N au travail » dans 70). La contrainte qui fait foi est le plafond, mesuré par la suite
  de vendorisation. Précisé le 2026-11-11 après la critique de la spec (tour 2, finding 8).
- **P73-D-28 (règles communes de la Phase 79, amendement `2ae6607a`).** Toute route posée par la 73 (seule
  `GET /api/vf/ailleurs`) prend une ligne de la table des routes, en ordre alphabétique, et passe par la fonction
  d'accès exportée unique (contrôles, garde d'émission, 503) si le plan 79-05 a fusionné (A10/A11) ; côté page, le jeton
  ne se lit que par `VF_ETAT.jeton()` / `VF_ETAT.lireJson(chemin)` quand le magasin existe (A13) ; les suites neuves
  lancent le serveur par l'aide commune `plugin/cockpit/scripts/tests/socle-serveur.sh` si elle existe (A6), sinon par
  le lanceur présent. Les six points envoyés à la 79 le 2026-11-11 sont tous retenus par son second amendement
  (`6f66d878`, A15 à A20) : flux `lock` projeté (A15), résumé de plan publié et champ `dag` (A16), signature de `who`
  couvrant les champs ajoutés (A17), fonction d'AUDC-I10 en fin de `vf-cockpit-etat-officiel.mjs` (A18), `cockpit-equipe@1`
  servi tel quel (A19), `sortisSilence` et `finMotif` dans `who@2` (A20). Un plan qui lit A15, A16 ou A20 est marqué
  « à revalider » tant que le plan correspondant de la 79 n'a pas fusionné, et dit son repli sur la forme présente.

- **P73-D-29 (clé de ligne, critique tour 2).** Un agent affiché deux fois (« À vous » et l'arbre) a deux lignes ; la
  clé de mise à jour et de focus est `section + identifiant`, jamais l'identifiant seul ; l'ancre `#r=n:…` cible la ligne
  de « À vous » si elle existe, sinon celle de l'arbre ; une ligne qui change de section garde le focus sur la ligne de
  même section si elle subsiste, sinon le rend au titre de la section (`tabindex="-1"`), jamais à la jumelle.
- **P73-D-30 (ligne 2 d'une session, critique tour 2).** Ordre de priorité de la seconde ligne, du premier au dernier
  coupé : nœud, travail non commité (« N modifiés »), arbre, « Lancée depuis la carte » ; le détail déplié (§ 7 de la
  spec) reprend tous ces champs, rien n'est seulement dans une ellipse.
- **P73-D-31 (fenêtre de stall inconnue).** Quand la fenêtre est inconnue (P73-D-09), l'état « suspect » n'est pas
  émis : la décroissance s'arrête à « silencieux ».
- **P73-D-32 (contrôles secondaires, critique tour 2).** « Les N autres », les `summary` (« Relus… », « Arbres de
  travail ») et les liens en ligne sont des liens au style lien existant ou des `.btn` doux, jamais un quatrième style ;
  cible de 44 px en `pointer: coarse` ; place dans l'ordre de tabulation ; `section#vf-equipe` porte `role="main"` ;
  chaque message d'état (« Source illisible », « Direct coupé », « Aucun agent ne correspond ») dit sa résolution en une
  demi-phrase. Les autres mineurs de la critique (échelle typographique, contraste à recalculer, tiroir Git sur la
  colonne de droite entre 1 000 et 1 370 px) sont traités dans le plan d'interface.

- **P73-D-33 (surcouches et objet global du moteur, information de la Phase 80, 2026-11-11).** La régie ne pose
  aucune surcouche propre : le détail de ligne est en flux, la fiche de la 74 n'est pas une surcouche (P74-D-03). Le seul
  cas est le repli de `vf-agent:ouvrir` (lecteur actuel dans le panneau latéral) : s'il existe, il passe par la pile de
  la Phase 80 `window.VF_SURCOUCHES.ouvrir(el, {modale, ouvreur, fermer})` (P80-D-33..41, `80-CONTEXT.md` sur
  `feat/phase-80-trois-formes`, SHA à vérifier à la jointure) pour le focus et l'Échap, sinon il garde le comportement
  présent. La régie n'ajoute rien à l'objet global du moteur (gelé par la 80) : ses contrats vivent sous ses propres
  globales (`window.__vfEquipeVues`) et les événements de document de P73-D-20 ; `select(id)` et `reveal(id)` ne sont
  pas utilisés par la régie (l'ancre est traitée par la régie, P73-D-20). Plan concerné marqué « à revalider » jusqu'à
  la fusion de la 80.

- **P73-D-34 (initialisation par onglet, règle commune A30 de la Phase 79, `74501bb0`).** Les modules de page de la
  régie s'initialisent par `VF_COQUILLE.surOnglet(rappel)` quand la coquille de la 79 existe : `rappel({onglet})` monte
  la régie quand l'onglet vaut Équipe et rend une fonction de nettoyage (écouteurs, abonnements `VF_ETAT`, minuteries,
  DOM posé) appelée avant le changement d'onglet suivant ; jamais d'initialisation au seul chargement de la page. Avant la
  coquille, la régie garde l'initialisation présente (au chargement de `equipe.html`) ; chaque plan d'interface écrit les
  deux cas dans sa dépendance envers la 79 et est marqué « à revalider » jusqu'à la fusion de la coquille.

### Claude's Discretion

Noms internes des fonctions et modules neufs, découpage fin des fichiers d'interface, forme exacte des fixtures (noms
inventés seulement : dépôt public), ordre des tâches dans une vague.
</decisions>

<code_context>
## Existing Code Insights (état présent après le lot 0, `f763b556`)

- Collecte : `plugin/cockpit/scripts/vf-cockpit-equipe.mjs` (fenêtre 24 h, `fresh` 180 s, `SILENCE_MAX_S` 1 800 s,
  orphelin l.116) ; état officiel `vf-cockpit-etat-officiel.mjs` (asynchrone, 1 appel / 10 s, forme `formeEtats`) ;
  assemblage `vf-cockpit-who.mjs` → `cockpit-who@2` (contrat `vf-cockpit-interface.json:26-40`, clés interdites) ; flux
  `vf-cockpit-live.mjs` (`whoSig` l.51 n'inclut ni `enCours`, ni `orphan`, ni les durées).
- Page Équipe : gabarit `project.html` + graphe injecté (`vf-cockpit-server.mjs:143-155`, `buildEquipeGraph`,
  `vf-cockpit-equipe-carte.mjs` → `cockpit-equipe@1`) ; rendu `skills/cockpit-moteur/assets/ui/71-vf-equipe-rendu.js`,
  `72-vf-equipe.js`, `70-vf-live.js` (tiroir « Au travail »), `76-vf-git-entete.js` (en-tête) ; tous les `ui/*.js` sont
  inlinés dans les trois pages par ordre de nom (`build.mjs:448`).
- Routes de la Phase 78 : `GET /api/vf/git`, `GET /api/vf/git/worktrees` (`cockpit-git-worktrees@1`), événement `git`.
- Verrou : flux `lock` = `driver-lock.sh status --all` brut ; watchdog = `plugin/conductor/scripts/check-guard-health.sh`
  (STALL / ABANDON, sans trace persistée).
- Dictionnaire FR : `ui/78-vf-fr-dict-a.js`, `79-vf-fr-dict-b.js`, `80-vf-fr.js`, `scripts/vf-cockpit-fr-exclusions.json`.
- Harnais : VM Node (`vm-rendu.mjs`, `vm72.mjs`) et Chrome headless CDP (`chrome-session.mjs`, `chrome-equipe-clavier.mjs`)
  dans les suites ; aucun navigateur de poste.
</code_context>

<canonical_refs>
## Canonical References

- `.planning/research/2026-11-10-audit-cockpit-etude.md` § 8.2 (bloc Phase 73), § 9
- `.planning/research/2026-11-10-audit-cockpit/REGISTRE.md` — AUDC-I01, I02, I03, I09, I10, I21, I34, I38, D4, M3, F2 ; § 3, § 4, § 5
- `.planning/research/2026-11-10-audit-cockpit/DESIGNS.md` § 1-3, § 9 ; maquette `page/audit-cockpit.html`
- `.planning/missions/2026-11-11-audit-cockpit-lot-0.md` — Décisions, Limites, Fichiers par sous-lot
- `79-CONTEXT.md` § Contrats fournis et « Amendement du 2026-11-11 » (branche `feat/phase-79-socle-cockpit`, `3119d82a`, `2ae6607a`, `6f66d878`) ; `74-CONTEXT.md` P74-D-02..04 (`f87ae937`)
- `73-UI-SPEC.md` (ce dossier) — se conforme aux décisions ci-dessus ; en cas d'écart, ce fichier fait foi
- `DESIGN.md` (racine), direction « Graphite »
</canonical_refs>

## Bornes contrôlées (chaque décision vérifiée contre elles)

| Borne | Tenue par |
|---|---|
| P67-D-14 dernière commande jamais dans flux/fichier/export | aucune ligne de régie ne porte de commande ; « commande en cours depuis N » = verbe seul |
| P69-D-16 verbe + cible réduite | inchangé ; la régie réutilise `action{verbe,cible}` |
| P69-D-15 rattachement jamais deviné | P73-D-07 (impact inconnu), P73-D-09 |
| P69-D-18 / AUDC-Q2 24 h | « Terminé, à relire » et le stockage « lu » purgés à 24 h |
| P69-D-19 / D-23 transcript sans sortie, jamais exporté | « Lire le rapport » = lecteur existant ; P73-D-25 |
| P68-D-03 / AUDC-Q3 aucun geste sur une session | seule action : « Lire le rapport » |
| Q8 / P71-D-08 pas de terminal sur Équipe ; plan 69-05 pas de « Demander » | rien ajouté |
| Q9 ni couleur d'alerte ni fond teinté | P73-D-11, P73-D-19, P73-D-10 (pastilles neutres) |
| Q12 un seul tiroir latéral, ne pousse pas la carte | P73-D-14 (tiroir « Au travail » hors Équipe) ; la fiche de la 74 n'est pas un tiroir |
| Q5 jamais voler le focus | P73-D-15 |
| Q11 points de rupture ; P71.5-D-01 grille fermée | spec § 11, § 15 |
| P78-D-04 pas de 4ᵉ onglet ; P78-D-07 lecture seule | régie dans Équipe ; aucune route d'écriture |
| aucun appel réseau sortant ; lecture seule sur `.planning/` | P73-D-06 lit l'en-tête des VERIFICATION ; P73-D-15 sans réseau |
| PU-G-162 titre par `custom-title` seul | nom écrit une fois par ligne |

## À Samuel (questions non bloquantes ; l'arbitrage en vigueur tient, le plan se bâtit dessus)

- **S-1 — pastilles du tiroir Git sur `--warn-bg`.** Le tiroir Git de la Phase 78 pose « modifiés » sur un fond
  d'avertissement, en tension avec Q9 (« ni fond teinté »). La régie les rend neutres ; le tiroir n'est pas touché ici.
  Options : (a) laisser tel quel ; (b) neutraliser dans un correctif du tiroir Git. **Recommandation : (b)**, hors de la 73.
- **S-2 — question en suspens au transcript.** Une session bloquée sur une question de l'assistant (outil de question
  sans réponse) passe aujourd'hui pour « au travail » quand l'état officiel est absent. La lire au transcript rouvrirait la
  décision D2 du lot 0 (« vous attend » vient seulement de l'état officiel). Options : (a) garder D2 ; (b) admettre ce
  repli. **Recommandation : (a)** — la source officielle couvre le cas quand elle est disponible.
- **S-3 — « arbitrages en attente » écrits dans les CONTEXT.** Le but dit « arbitrages en attente reliés à leur phase » ;
  la Phase 73 n'en lit que les formes structurées (sessions qui attendent, `human_needed`). Les sections « À Samuel »
  sont en prose. Options : (a) en rester là ; (b) une convention structurée (marqueur d'en-tête dans le CONTEXT), lue
  ensuite par le cockpit — touche la doctrine de cadrage. **Recommandation : (b), plus tard**, en sujet de BACKLOG.
- **S-4 — notification du système.** Reportée (P73-D-15). Options : (a) reporter ; (b) l'ajouter en option éteinte par
  défaut dans la 73. **Recommandation : (a)** — elle écrit du texte hors de la page (centre de notifications du système),
  ce qui demande son propre examen de bornes.

<deferred>
## Deferred Ideas

- Notification du système (AUDC-I09, part).
- Convention structurée pour les arbitrages en attente écrits dans les CONTEXT (S-3).
- Actions sur une session, dont « Demander l'arrêt » d'un orphelin et « Répondre » (Phase 81, AUDC-Q3).
</deferred>

---

*Phase: 73-gouvernance-au-cockpit*
*Context gathered: 2026-11-11*
