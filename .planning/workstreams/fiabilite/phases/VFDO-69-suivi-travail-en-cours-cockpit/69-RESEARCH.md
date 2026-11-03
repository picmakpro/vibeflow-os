# Phase 69: Suivi du travail en cours dans le cockpit - Research

**Researched:** 2026-11-03
**Domain:** module `plugin/cockpit` (bibliothèque Node du socle, serveur local, couche d'interface vendorisée), suites bash, format interne non documenté de Claude Code
**Confidence:** HIGH sur le code lu dans ce worktree (branche `feat/phase-69-suivi-travail`) ; MEDIUM sur la mise à jour en direct de l'onglet « Équipe » (limite du viewer, voir Pitfall 11) ; ASSUMED là où c'est écrit.

Conventions de preuve de ce fichier. **CONFIRMED** = lu ou mesuré dans ce worktree pendant cette session (chemin:ligne, valeurs citées telles quelles) ; **ASSUMED** = déduit ou non vérifié, à confirmer. Aucun chemin absolu de machine n'est écrit ici (gate `check-machine-paths`) : tous les chemins sont relatifs à la racine du worktree ou à `~`.

<user_constraints>
## User Constraints (from CONTEXT.md)

Source : `69-CONTEXT.md` (copié sans reformulation ; le fichier ne porte pas de section « Claude's Discretion » nommée, voir plus bas).

### Locked Decisions

Registre de la phase : identifiants préfixés `P69-D-NN` (convention CLAUDE.md, ADR-075).

**Arbitrage de Samuel (AskUserQuestion session principale, 2026-11-03)**

- **P69-D-01 (option A retenue, B écartée).** Statut de phase dérivé dans la lib de lecture, objet versionné, rien d'autre. Coût estimé : une vingtaine de lignes, affichage existant réutilisé, 4 cas de test.

**Règles de l'option A (note § 2)**

- **P69-D-02 (objet `avancement`).** `readPlanning` expose par phase `{ "version": 1, "etat": …, "plans": {"faits","total"}, "correctifs": N, "mission": {"nom","etat"}, "reste": […] }` (CKPT-13). Il sera consommé par `vf-signal` (Phase 68).
- **P69-D-03 (quatre états, chacun avec sa preuve locale).** `a-faire` : aucun SUMMARY de plan ; `en-cours` : au moins un plan fait, ou mission rattachée avec un nœud `running` ; `a-recetter` : tous les plans faits, phase non cochée ; `fait` : case de ROADMAP cochée (CKPT-13). « À recetter » se déduit de « tous les plans faits et phase non close », jamais de « PR ouverte ».
- **P69-D-04 (décompte des plans, C2).** Un plan est fait s'il a un `*-PLAN.md` **et** son `*-SUMMARY.md`. Les SUMMARY sans PLAN forment une ligne à part, « 4 correctifs » (CKPT-14).
- **P69-D-05 (rattachement des missions, C4).** Dans l'ordre : (1) champ `phase` du DAG s'il existe, (2) nom `MISSION-<n>`, (3) DAG situé dans le dossier de la phase. Le cas de la 67 se règle par (1) : une ligne `"phase": "67"` dans son DAG (CKPT-15). Poser cette ligne dans le DAG de la 67 est un geste de mission, hors de cette phase documentaire.
- **P69-D-06 (jalon et pied).** Le jalon est `en-cours` dès qu'une de ses phases est `en-cours` ou `a-recetter`, quel que soit le STATE. Pied : « 0 clos · 1 à recetter · 1 à faire · 0 % ». Le pourcentage reste strict (phases closes seulement), jamais pondéré (CKPT-16).
- **P69-D-07 (`reste`, traces locales seulement).** Recette humaine : un `*-RECETTE-HUMAINE.md` dont le statut n'est pas « FAITE » ; vérification : pas de `*-VERIFICATION.md` ; clôture : case de ROADMAP non cochée. CI, merge et release ne sont **pas** affichés ; au mieux la release se lira depuis un tag local, « à voir plus tard » (CKPT-17).
- **P69-D-08 (retrait, un ajout = un retrait).** On supprime la règle `ph.n === curPhase` : le STATE ne pilote plus le statut d'une phase sur la carte, c'est la seule source qui ment ici (CKPT-18).

**Limite de fond**

- **P69-D-09 (aucune lecture réseau).** Le cockpit ne fait aucun appel réseau (recette 67, point 5 ; P67-D-02). L'état d'une PR, de la CI ou d'un merge n'est donc **pas lisible** : « PR ouverte » ne peut venir que d'une trace locale, et la carte ne prétend jamais savoir ce qu'elle ne peut pas lire.

**Quatre témoins rouges (fixtures de lab, un par règle, joués avant le code)**

| # | Fixture | Attendu | Aujourd'hui (rouge) |
|---|---|---|---|
| a | 7 PLAN, 7 SUMMARY et 4 SUMMARY de correctif | `7/7 plans · 4 correctifs` | 11/7 |
| b | STATE sur une autre phase, plans faits | `a-recetter` | à faire |
| c | DAG avec `phase: 67` | rattaché à la 67 | hors phase |
| d | Jalon `📋` avec une phase `a-recetter` | jalon `en-cours` | à faire |

Un témoin « décompte faussé par un nœud DAG » serait vert dès aujourd'hui et ne prouverait rien : le bon témoin du décompte est un SUMMARY sans PLAN (note § 3 bis). Le retrait de la règle STATE (CKPT-18) se prouve par le témoin (b) plus un test qui rougit si `curPhase` redevient une source de statut.

**Arbitrages ultérieurs de Samuel (AskUserQuestion session principale, 2026-11-03)**

- **P69-D-10 (ordre 69 avant 68).** Réponse de Samuel, mot pour mot : « 69 avant 68 (Recommandé) ». La Phase 68 dépend de la 69 : « Depends on » de la 68 mis à jour dans le ROADMAP ; la 68 consomme `avancement`.
- **P69-D-11 (refonte mobile hors 69).** Réponse de Samuel : « Phase à part (Recommandé) ». La refonte mobile, I1 et O5 relèvent de la Phase 70 « Finitions UI du cockpit » (inscrite 2026-11-03) ; les déclencheurs des deux entrées BACKLOG du cockpit y renvoient. La 69 n'a aucune exigence sur ce sujet.

**Mise à jour du cadrage — équipe au travail (arbitrages Samuel, AskUserQuestion session principale, 2026-11-03)**

Réponses de Samuel consignées mot pour mot ; canal et date : AskUserQuestion, session principale, 2026-11-03.

- **P69-D-12 (découpage).** Réponses : « 69 = avancement + équipe, terminal en 71 (Recommandé) », puis « Oui, 69 / 71 / 72 (Recommandé) ». La 69 couvre l'avancement des phases (option A, P69-D-01..09, inchangée) **et** l'équipe au travail. La Phase 71 porte le terminal intégré ; la Phase 72, lancer du travail depuis les cartes.
- **P69-D-13 (ordre du jalon).** Réponse : « 69 → 68 → 70 → 71 → 72 (Recommandé) ». Prolonge P69-D-10 ; la 72 dépend de la 71.
- **Affichage de l'équipe.** Réponse, les quatre retenus : « Arbre dans le tiroir, Lien vers les nœuds de DAG, Fil d'Ariane d'activité, Vue dédiée plein écran ».
  - **P69-D-14 (arbre).** Arbre session → manager → workers dans le tiroir « Au travail », avec type, description, état et durée (CKPT-19). Retrait associé (un ajout = un retrait) : la liste plate des sous-agents du tiroir.
  - **P69-D-15 (lien vers les nœuds de DAG).** Chaque agent rattaché au nœud de mission qu'il exécute, cliquable dans les deux sens (CKPT-21). Sources, dans l'ordre : registre de `driver-lock.sh` (`--node`), puis nom de nœud cité dans le mandat (premier message du transcript, souvent « Nœud `revue-p3` ») et présent dans un DAG connu ; jamais deviné.
  - **P69-D-16 (fil d'Ariane).** Pour chaque agent actif, sa dernière action lisible (« lit X », « lance les tests »), sans le détail des commandes (CKPT-22).
  - **P69-D-17 (vue dédiée).** Un troisième onglet « Équipe », en carte comme Code et Projet (CKPT-23).
  - **Validation des choix du manager dans P69-D-14 à P69-D-16** : retrait de la liste plate (D-14), ordre des sources de rattachement sans jamais deviner (D-15), fil d'Ariane réduit au verbe et à la cible, jamais l'argument d'une commande (D-16). Réponse de Samuel, mot pour mot : « je valide D14 D15 D16 » (session principale Claude Code, 2026-11-03). La planification peut partir.
- **P69-D-18 (historique).** Réponse : « Actifs + terminés récents (collapsable) ». Les agents en cours, plus ceux finis dans les dernières 24 h, grisés et repliables (CKPT-20).
- **P69-D-19 (transcripts).** Réponse, mot pour mot : « Message et action, sans les sorties. Je veux aussi anticiper à l'intégration prochaine terminale et de pouvoir travailler directement dans le cockpit, c'est-à-dire que on a déjà un chat qui est prévu enfin qui est actuellement dans l'application, ils permet de poser des questions mais pas forcément de lancer du travail, il faudrait qu'on puisse aussi lancer du travail éventuellement donc ça sera l'idée d'avoir une session Claude code qui tourne dans le code une session de terminale dans l'idéal, et ça permettrait de lancer par exemple depuis les cartes ou depuis le cockpit du travail soit en cliquant sur les cartes de phase ou de mission ou peu importe. Bien sûr, il faudrait qu'on anticipe les manque, les dépendances manquantes donc ça empêcherait l'exécution, il faudrait qu'on anticipe aussi et les impossibilité voilà qu'on qu'on fasse pas de but en blanc donc ça potentiellement le chat qui permet de poser des questions permet déjà d'avoir le contexte et puis ensuite on pourrait éventuellement lancer du travail depuis le cockpit donc c'est-à-dire avec la méthode Vilo avec le Fail système qui vit qui vit littéralement sur le PC et donc il peut travailler sur les work qui peut faire des poches qui peut écrire dans des fichiers qui s'ouvre avec déjà le contexte, projets, les skis etc. cetera »
  - Ce que la 69 en retient : le mandat, les messages de l'agent et la liste de ses outils (une commande réduite comme « Voir la dernière commande », règle F-B de `v2.75.0`). Jamais les sorties d'outils ni le contenu des fichiers lus. Local, à la demande, jamais exporté (CKPT-24, CKPT-25).
  - Le reste, lancer du travail, est la vision des Phases 71 et 72 (lecture de la transcription vocale : « Vilo » = VibeFlow, « Fail système » = file system, « work » = worktrees, « poches » = PR, « skis » = skills).
- **P69-D-20 (terminal, hors 69).** Réponse : « Terminal intégré dans la page » (xterm.js et une PTY native). C'est la Phase 71, avec un audit de sécurité complet : elle change le modèle de menace du cockpit (un shell complet derrière le serveur local).
- **P69-D-21 (lancer du travail, hors 69).** La Phase 72 porte la vision de P69-D-19 : lancer du travail depuis les cartes de phase ou de mission, en anticipant les dépendances manquantes et les impossibilités, avec le contexte du chat. Dépend de la 71.

**Faits mesurés (session principale, 2026-11-03)**

- **P69-D-22 (format Claude Code non documenté, test de forme étendu).** Pour chaque sous-agent, Claude Code écrit `~/.claude/projects/<slug>/<session>/subagents/agent-<id>.meta.json` (`agentType`, `description`, `parentAgentId`, `spawnDepth`, `finished`, `toolUseId`, `requestShape`) et `agent-<id>.jsonl` (transcript, avec `isSidechain` et `agentId` ; son premier message est le mandat). Mesure sur une session réelle : 39 sous-agents, dont 37 avec un `parentAgentId`. `vf-cockpit-who.mjs` lit déjà ces fichiers (lignes 82-107) mais les aplatit en liste. Ce format n'est pas documenté : le test de forme de CKPT-01 couvre chaque champ nouvellement lu et rougit si l'un disparaît (CKPT-27).

**Contraintes de doctrine du cockpit (équipe au travail)**

- **P69-D-23.** Calcul dans la bibliothèque du socle (`readPlanning`, `who`), sous un JSON versionné ; aucune requête réseau ; un ajout = un retrait (SOBR) ; aucune couche de synonymes ; XSS et CSP inchangés ; transcripts jamais exportés ni présents dans le flux SSE sans requête authentifiée (CKPT-25, CKPT-26, CKPT-28).
- **P69-D-24 (un témoin rouge par règle).** Chaque exigence CKPT-19..28 porte son témoin rouge, joué avant le code. Un helper de test qui tue des processus passe la marque par `awk -v`, refuse une marque vide, plafonne le nombre de processus tués, garde un leurre vivant et ne fait jamais de `pkill -f` par motif.

### Claude's Discretion

`69-CONTEXT.md` ne contient aucune section « Claude's Discretion ». Les seuls points laissés ouverts par le cadrage sont : **« Point ouvert — Ligne `phase` du DAG de la 67 : à poser côté mission 67 (Samuel la traite, même date). »** (voir R4.3 : déjà posée sur cette branche) ; tout le reste de la conception (nom des modules, forme interne des objets, découpage en plans) est laissé au planificateur, dans les limites des décisions ci-dessus.

### Deferred Ideas (OUT OF SCOPE)

- « **Hors périmètre :** option B ; toute lecture réseau ; release (geste humain) ; le terminal intégré (Phase 71) ; lancer du travail depuis le cockpit (Phase 72). »
- « **Points écartés (option B, note § 3)** » : pourcentage de jalon pondéré ; état d'exigence intermédiaire « livré, non vérifié » (`- [~]`) ; liste d'étapes déclarée en frontmatter (`etapes:`) et cochée à la main ; « B pourra revenir pièce par pièce si un besoin réel apparaît après la Phase 68. »
- Refonte mobile, I1, O5 : Phase 70 (P69-D-11). Exigence C5 « exigences 0/12 » : « voulu, rien à changer ».
</user_constraints>

## Project Constraints (from CLAUDE.md)

Directives de `CLAUDE.md` du worktree (lu) qui s'appliquent à cette phase :

- **Release = un tag** : toute version racine porte un tag annoté `vX.Y.Z` ; une release ne se déclenche que pour une évolution fonctionnelle, par geste humain (ne pas planifier de bump racine, de tag ni de `gh release` dans les plans). [CONFIRMED: CLAUDE.md l. 13-62]
- **Densité (ADR-029)** : agents avertis dès 251 lignes, bloqués au-delà de 300 ; skills <= 500. Pour le code du cockpit, la même limite de 300 lignes par fichier est machine-enforced par `test-cockpit-vendor.sh` V4 (voir Pitfall 1). [CONFIRMED: CLAUDE.md l. 66 ; `plugin/cockpit/scripts/tests/test-cockpit-vendor.sh:53`]
- **Jamais de fix sans validation humaine (ADR-031)** : aucun correctif non arbitré ; toute question de conception non tranchée par `69-CONTEXT.md` va à Samuel (section « Open Questions for Samuel »).
- **Commits en français**, cohérents avec l'historique ; un commit qui invoque une décision humaine nomme **canal et date** (« arbitrage Samuel, AskUserQuestion session principale, 2026-11-03 »). Identifiants de décision préfixés (`P69-D-NN`, `P69-PL-NN` pour les choix du planificateur). [CONFIRMED: CLAUDE.md l. 71-87]
- **Gardes in-repo** : G-1 (baseline d'instructions), G-2 (`Gate-Touche:` pour gate/suite/CI/hook/fixtures des suites surveillées), G-3 (push sans PR). Les suites du cockpit ne sont pas dans la surface G-2 (voir R9). [CONFIRMED: CLAUDE.md l. 112-137 ; `scripts/check-gate-touche.sh:21-44`]
- **Mémoire utilisateur applicable** (non versionnée) : parallélisme d'agents plafonné à 2 ; `rtk` écrase les sorties vides (mesurer en `rtk proxy` ou rediriger vers un fichier) ; une preuve doit pouvoir rendre rouge ; ne pas supprimer pour verdir ; arbitrage humain jamais inférable ; aucun manager ne s'autorise `/gsd-ship`. [CITED: mémoire projet MEMORY.md]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CKPT-13 | `readPlanning` expose `avancement` v1, quatre états | R1.1 (phaseStatus), R1.2 (readPlanning), P1 ; témoin (b) rouge reproduit (R6) |
| CKPT-14 | Plan fait = PLAN + SUMMARY ; SUMMARY sans PLAN = correctifs | R1.1 (`sums` l. 66), témoin (a) rouge `11/7 plans` reproduit (R6) |
| CKPT-15 | Rattachement mission : champ `phase`, `MISSION-<n>`, dossier de phase | R1.1 (l. 90), R4.2-R4.3 ; `readPlanning` jette `phase` (l. 107) ; témoin (c) rouge reproduit |
| CKPT-16 | Jalon `en-cours` dès qu'une phase l'est ; pied « N clos · N à recetter · N à faire · N % » | R1.1 (l. 47, 56) ; témoin (d) rouge reproduit ; format du pied non spécifié pour `en-cours` (OQ-3) |
| CKPT-17 | `reste` depuis des traces locales seulement, aucune lecture réseau | R4.4 (formes de fichiers réelles), Pitfall 6 ; test réseau CKPT-03 rejoué |
| CKPT-18 | Retrait de `ph.n === curPhase` | R1.1 (l. 36) ; assertions P1.1/P1.2/P1.5 à réécrire par conception (R2.3) ; test par mutation |
| CKPT-19 | Arbre session -> manager -> workers dans le tiroir, liste plate retirée | R1.3 (who l. 82-107), R5.1 (profondeurs réelles), Pitfalls 7-9 ; témoin rouge reproduit (R6) |
| CKPT-20 | Actifs + terminés < 24 h, grisés/repliés | R1.3 (l. 88 écarte `finished`), R5.1 (`finished` absent quand actif), A2 ; témoin rouge reproduit |
| CKPT-21 | Agent <-> nœud de DAG, deux sens, jamais deviné | R4.1-R4.2 (registre, collisions d'identifiants de nœud), R1.5 (UI), Pitfalls 8-10 |
| CKPT-22 | Dernière action lisible, jamais d'argument de commande | R5.2 (table d'outils réelle), R1.3 (`cherche`, `lastCommand`), Pitfall 12 |
| CKPT-23 | Troisième onglet « Équipe », libellés français | R1.5 (onglets = pages), R1.4 (patch serve.mjs), Pitfalls 10-11 ; inventaire FR n'inspecte pas les extensions VibeFlow (R2.4) |
| CKPT-24 | Transcript réduit à la demande | R5.1 (lignes `api-request-blob` qui dupliquent les sorties), R5.3 (endpoint), Pitfall 13 |
| CKPT-25 | Transcript servi par requête authentifiée, jamais SSE/fichiers/export | R1.4 (modèle d'authentification), R5.3, S5-S8 + DO comme gabarit de tests ; témoin « sans jeton -> 403 » déjà vert (Pitfall 14) |
| CKPT-26 | Rendu texte, CSP inchangée | R1.5 (`h()`, `textContent`), R1.4 (`pageCsp`), Pitfall 15 |
| CKPT-27 | Test de forme étendu aux champs nouvellement lus | R3 (aucun test ne garde ces champs aujourd'hui), R5.1 (présence mesurée), Pitfalls 7 |
| CKPT-28 | Calcul dans `who`, schéma versionné qui monte, témoin réseau rejoué | R1.3, R3, R2.3 (assertions `who@1` à changer), `test-cockpit-reseau.sh` |
</phase_requirements>

## Summary

La phase a deux volets indépendants jusqu'au bout. **Avancement** : tout le calcul vit dans `readPlanning` (`vf-cockpit-planning.mjs`), la carte Projet (`vf-cockpit-project.mjs`) le projette ; quatre témoins sont reproduits rouges sur le code actuel (R6). **Équipe** : `vf-cockpit-who.mjs` aplatit aujourd'hui les sous-agents (`parent` = identifiant de session pour tous) et écarte tout agent `finished` ; il faut un arbre, une fenêtre de 24 h, un rattachement aux nœuds de DAG, une dernière action, un endpoint de transcript à la demande et un troisième onglet.

La recherche corrige ou précise sept points du cadrage, mesurés sur le disque (R5, R4) : (1) `finished` est **absent** des `meta.json` d'un agent actif (il n'apparaît qu'à `true`) ; (2) `parentAgentId` est absent à `spawnDepth` 1 (agents lancés directement par la session), présent à partir de 2 ; (3) la profondeur du registre `driver-lock.sh` n'est pas `spawnDepth` (le registre dit 2 pour un agent que Claude Code compte à 3) ; (4) le DAG de la 67 porte **déjà** `"phase": "67"` sur cette branche (commit `40bc239c`) ; (5) la découverte de DAG de `who` ignore les DAG des dossiers de compartiment (donc `MISSION-69.dag.json` et son nœud `plan-69` en cours) alors que `readPlanning` les lit ; (6) les identifiants de nœud se **répètent** d'un DAG à l'autre (28 identifiants sur 355 dans plus d'un des 27 DAG ; `docs` dans 22) : « présent dans un DAG connu » ne suffit pas à lier, il faut l'unicité ; (7) les transcripts contiennent des lignes `api-request-blob` qui recopient les sorties d'outils : un réducteur doit être une liste blanche de types de ligne, jamais une liste noire.

Deux contraintes de structure pèsent sur le plan : (i) un troisième onglet « en carte » est une troisième page HTML ; `serve.mjs` (vendorisé) ne sait servir en mémoire avec CSP à empreintes que `/project.html`, donc il faut un nouveau patch vendorisé (P24) rejoué par `synchro.sh`, et le viewer construit ses index `nodes`/`files` une seule fois (un agent nouveau = rechargement de page) ; (ii) toute suite nouvelle change le nombre de suites que `check-version-sync.sh` compare aux deux README racine (142 aujourd'hui).

**Primary recommendation:** planifier en deux chantiers parallélisables (au plus 2 workers) — Avancement (module `vf-cockpit-avancement.mjs` + `readPlanning` + projection Projet, suite `test-cockpit-avancement.sh`) et Équipe (`who` v2 + interface versionnée + endpoint `GET /api/vf/transcript` + UI + page `equipe.html`, suites dédiées) — en commençant chaque chantier par une vague 0 de tests rouges conservés (trace `assertion / attendu / obtenu`), et en laissant à Samuel les arbitrages listés en « Open Questions for Samuel » (vocabulaire de `a-recetter` sur les cartes, mécanisme du troisième onglet, lien des agents terminés, bump du module).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| État d'avancement dérivé d'une phase (`avancement`) | Bibliothèque du socle (`readPlanning` + nouveau module) | — | P69-D-01/D-23 : calcul en lib, JSON versionné, consommable par `vf-signal` sans navigateur |
| Décompte plans / correctifs, `reste` | Bibliothèque du socle | — | Lecture de fichiers de phase uniquement (aucun réseau, P69-D-09) |
| Rattachement mission -> phase | Bibliothèque du socle | Projection Projet (`vf-cockpit-project.mjs`) | Les DAG sont lus par `readPlanning` ; `project.mjs` place la carte |
| Pied et statut du jalon | Projection Projet | Navigateur (affichage) | Le pied est une chaîne du graphe ; le navigateur ne recalcule rien |
| Arbre d'équipe, état, durée | Bibliothèque du socle (`who`) | Serveur (diffusion SSE `who`) | Le serveur ne fait que diffuser ; le navigateur ne lit jamais `~/.claude` |
| Rattachement agent -> nœud de DAG | Bibliothèque du socle | Registre `driver-lock.sh` (lecture via `orphans`) | Jointure registre + mandat + index des DAG ; jamais côté navigateur |
| Dernière action lisible | Bibliothèque du socle | Serveur (SSE : libellé seulement) | Réduite avant diffusion ; l'argument d'une commande ne quitte jamais la lib |
| Transcript réduit (mandat, messages, outils) | Bibliothèque du socle (fonction de révélation) | Serveur (endpoint authentifié, à la demande) | Même patron que `revealDoing` : identifiant connu d'une collecte fraîche, aucun chemin construit depuis l'entrée |
| Rendu texte des contenus d'agents | Navigateur | — | `h()`/`textContent` uniquement, CSP inchangée |
| Onglet « Équipe » (page) | Serveur (route + CSP + jeton) | Navigateur (couche d'interface), socle (graphe) | Une page de plus à servir ; patch vendorisé de `serve.mjs` requis |
| Forme du format Claude Code | Contrat versionné (`vf-cockpit-interface.json`) + collecteur | Suites de test | « `forme-inconnue` plutôt qu'un arbre faux » |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Node.js (modules intégrés : `fs`, `path`, `os`, `crypto`, `child_process`, `http`, `url`) | local 26.5.0 [CONFIRMED: `node --version`] ; CI 24 [CONFIRMED: `.github/workflows/ci.yml:112` `node-version: "24"`] | Tout le code du cockpit | Le module n'a aucune dépendance (`requires: []`) [CONFIRMED: `plugin/cockpit/module.json`] |
| bash (suites) | local 3.2.57 [CONFIRMED: `bash --version`] ; CI : bash de ubuntu-latest | Suites `test-cockpit-*.sh` | Style des 17 suites existantes ; compatible bash 3.2 (pas de tableaux associatifs, `${A[@]+"${A[@]}"}` comme dans `hygiene.sh`) |
| Chrome headless via CDP maison | local : présent [CONFIRMED: chemin macOS] ; CI : ASSUMED présent sur ubuntu-latest | Mesures d'interface | `tests/chrome-session.mjs` / `chrome-cdp.mjs` sans dépendance ; suites sautées audiblement sans navigateur |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `plugin/cockpit/scripts/tests/hygiene.sh` | module | Marque `tmp.<alnum>`, arrêt des seuls processus marqués, plafond 20, leurre | Toute suite qui lance un serveur ou un Chrome (D-24) ; ne pas écrire un second tueur de processus |
| `plugin/cockpit/scripts/vf-cockpit-embed.mjs` (`extraireGraphe`, `insererGraphe`) | module | Lire/écrire la zone de données d'une page | Page `equipe.html` et tests de page |
| `validate.mjs` (outil écrit dans chaque suite) | suites `who` et `projet` | Valide un JSON contre `vf-cockpit-interface.json` | À étendre pour `who@2`, `avancement`, `interdits` |
| `vf-cockpit-fr-inventaire.mjs` (`litteraux`, `estAnglais`) | module | Détection de chaînes anglaises | Réutiliser pour le chrome de l'onglet « Équipe » (R2.4) |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Page `equipe.html` servie en mémoire (patch `serve.mjs` P24) | Vue plein écran interne à `project.html` (panneau), sans nouveau patch vendorisé | Moins de maintenance de synchro amont, mais ce n'est plus « une carte comme Code et Projet » (CKPT-23, P69-D-17) : à arbitrer par Samuel (OQ-2) |
| Lire le registre par le verbe `orphans` | Parser `DRIVER.lock.children.jsonl` à la main | Le script interdit le parse à la main (`registry_fold` « unique lecteur ») ; `orphans` ne rend que les agents `running` (OQ-4) |

**Installation :** aucune. `npm install` n'est jamais appelé.

**Version verification :** non applicable (aucun paquet). Versions d'outillage relevées ci-dessus.

## Package Legitimacy Audit

Aucun paquet externe n'est installé par cette phase (`module.json` : `"requires": []`, aucun `package.json` sous `plugin/cockpit/`). [CONFIRMED: `ls plugin/cockpit` ; `plugin/cockpit/module.json`] La commande `package-legitimacy check` n'a donc rien à juger ; ne pas introduire de dépendance (le moteur d'affichage est une copie vendorisée MIT, déjà auditée en Phase 67, `LICENCES-TIERCES.txt`).

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
 Disque du lab                                  Disque de l'utilisateur
 .planning/**/ROADMAP.md  phases/NN-x/*-PLAN|SUMMARY|VERIFICATION|RECETTE-HUMAINE.md     ~/.claude/projects/<slug>/<session>.jsonl
 .planning/**/*.dag.json  (champ phase, ws, nodes[])                                     ~/.claude/projects/<slug>/<session>/subagents/agent-<id>.{meta.json,jsonl}
 <git-common-dir>/vf-driver/**/DRIVER.lock.children.jsonl (registre)                           |
        |                                                                                        |
        v                                                                                        v
 ┌───────────────────────────────┐                                         ┌─────────────────────────────────────────────┐
 │ readPlanning(root,layout)     │                                         │ who.gather() : sessions, sous-agents,       │
 │  phases, phaseDirs, dags(+phase)                                         │  verrous/registre (bash orphans), DAG running│
 │  + avancement(ph) [nouveau]   │                                         │  + arbre (parentAgentId/spawnDepth) [neuf]  │
 └───────────────┬───────────────┘                                         │  + fenêtre 24 h, dernière action [neufs]    │
                 |                                                         │  + jointure agent -> nœud (D-15) [neuve]    │
                 v                                                         └───────────────┬─────────────────────────────┘
 ┌───────────────────────────────┐                                                         |
 │ buildProjectGraph             │   st/foot/summary des cartes                            |  collectWho (public, borné+masqué) / revealTranscript (à la demande)
 │  phaseStatus <- avancement    │───────────────┐                                         |
 │  pied du jalon, mission->phase│               |                                         |
 └───────────────┬───────────────┘               v                                         v
                 |                      ┌──────────────────────────────────────────────────────────────┐
                 +--------------------->│ vf-cockpit-live.mjs : diff st/foot/sum -> patch/structural ;  │
                                        │  who (SSE) quand la signature change (whoSig à étendre)       │
                                        └───────────────┬──────────────────────────────────────────────┘
                                                        v
                                        ┌──────────────────────────────────────────────────────────────┐
   navigateur  <───── HTML (CSP à       │ serve.mjs (vendorisé) : Host + jeton + même origine, puis    │
   ui/00 onglets  empreintes) + SSE ────│ vf-cockpit-server.mjs : /api/vf/{events,etat,journal,doing,  │
   ui/70 tiroir                          │  modeles} + /api/vf/transcript [neuf] ; garde porteDoing     │
   ui/7x équipe [neuf]                  └──────────────────────────────────────────────────────────────┘
   clic "Transcript" -> GET /api/vf/transcript?id=  (en-tête x-floorplan-token) -> JSON no-store -> textContent
```

Flux principal à suivre : fichiers du lab -> `readPlanning` -> `avancement` -> `phaseStatus`/pied -> graphe Projet -> `live` (patch) -> navigateur. Flux équipe : `~/.claude/projects` -> `gather` -> arbre + action -> `collectWho` -> SSE `who` -> tiroir/onglet ; transcript : clic -> requête authentifiée -> `revealTranscript` -> JSON réduit -> `textContent`.

### Recommended Project Structure

```
plugin/cockpit/scripts/
├── vf-cockpit-planning.mjs      # readPlanning : garde `phase`/`ws` du DAG, appelle avancement (<= 250 lignes)
├── vf-cockpit-avancement.mjs    # NEUF : états, décompte plans/correctifs, rattachement mission, reste (module pur, testable sans disque lab)
├── vf-cockpit-project.mjs       # phaseStatus <- avancement ; pied du jalon ; rattachement mission via avancement
├── vf-cockpit-who.mjs           # collecteur : DOIT rester <= 300 lignes -> extraire
├── vf-cockpit-equipe.mjs        # NEUF : arbre, fenêtre 24 h, jointure agent -> nœud, graphe de la page Équipe
├── vf-cockpit-transcript.mjs    # NEUF : réducteur à liste blanche (mandat, messages, outils), dernière action
├── vf-cockpit-server.mjs        # route /api/vf/transcript, garde d'émission généralisée (interdits)
├── vf-cockpit-interface.json    # who@2, avancement, claudeCode étendu, interdits
└── tests/test-cockpit-*.sh      # voir R2.5
plugin/cockpit/skills/cockpit-moteur/assets/ui/
├── 70-vf-live.js                # tiroir : liste plate retirée, arbre
└── 7x-vf-equipe.js              # NEUF (AJOUT dans VENDORED.txt, marqueur « // VibeFlow ( » en tête)
```

Tout nouveau fichier `vf-cockpit-*.mjs` est recopié dans la sortie par `fichiersExecution` (motif `^vf-cockpit-.*\.mjs$` moins les outils d'assemblage) ; un module nommé autrement ne serait **pas** copié et le serveur installé échouerait à l'import. [CONFIRMED: `plugin/cockpit/scripts/vf-cockpit-build.mjs:19-20`]

### Pattern 1: module pur + projection (avancement)

**What:** `vf-cockpit-avancement.mjs` exporte une fonction pure `avancement({ ph, dir, files, dags, ... })` qui ne lit que ce qu'on lui passe ; `readPlanning` pose le résultat sur l'entrée de phase (`phases.get(key).avancement`) ; `buildProjectGraph` n'a plus de règle de statut propre.
**When to use:** CKPT-13..18. Garde `readPlanning` sous 250 lignes (avertissement ADR-035) et rend la règle testable par fixtures sans serveur.
**Example:** voir « Code Examples ».

### Pattern 2: révélation à la demande (transcript)

**What:** copier le patron de `revealDoing` : identifiant au format strict (`ID_RE`) **et** présent dans une collecte fraîche ; le chemin du transcript vient de la collecte, jamais de l'entrée. [CONFIRMED: `plugin/cockpit/scripts/vf-cockpit-who.mjs:220-229`]
**When to use:** CKPT-24/25.

### Pattern 3: témoin rouge intégré à la suite

**What:** une suite joue le code livré, puis le même scénario sur une **copie mutée** du module (`sed` sur une copie dans `$WORK`, jamais sur le dépôt) et exige le rouge ; patron de `test-cockpit-securite.sh` H6, `test-cockpit-chaine-xss.sh` M-ESC/M-CSP/M-GARDE, `test-cockpit-hygiene.sh` H-mut. [CONFIRMED: en-têtes de ces suites]
**When to use:** CKPT-18 (réintroduire `ph.n === curPhase` dans une copie de `project.mjs` -> témoin (b) rouge), CKPT-25/26 (retirer le contrôle de jeton / `h()` dans une copie de la sortie).

### Anti-Patterns to Avoid

- **Liste noire de types de ligne de transcript** : refuser `tool_result` et laisser passer le reste ferait passer `api-request-blob` (R5.1). Écrire une liste blanche (`user` première ligne = mandat, `assistant` blocs `text` et `tool_use` nom seulement).
- **Index par identifiant dans un objet ordinaire** : `ID_RE` accepte `constructor` et `toString`. Utiliser `Map` ou `Object.create(null)` (précédent : `touch` dans `vf-cockpit-build.mjs`, test K de la suite robustesse). [CONFIRMED: `vf-cockpit-who.mjs:220` ; `vf-cockpit-build.mjs:76`]
- **Construire une RegExp à partir d'un identifiant de nœud lu dans un DAG du lab** (le lab est non fiable, 67-SECURITY) : comparer par égalité sur un `Set`.
- **Modifier `driver-lock.sh`** pour obtenir un verbe « tout lister » : déclenche le job `tests-mutants` (17 min mesurées) et sort du périmètre « lecture seule » ; voir OQ-4.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Lire la fin d'un jsonl volumineux | Un nouveau lecteur | `cherche(f, accepte)` avec ses fenêtres 256 Kio / 2 Mio / 8 Mio (`who.mjs:28-48`) | Il traite déjà la ligne plus longue que la fenêtre (cause E-5) ; attention : le plus gros transcript mesuré fait 8,8 Mo, **plus** que la dernière fenêtre (R5.1) |
| Masquer des secrets dans un texte libre | Nouvelles regex | `masque()` + `MAX_MASQUE` (`who.mjs:165-183`) | Bornes anti-quadratique déjà prouvées (M-1) ; best effort, pas une garantie (Pitfall 16) |
| Réduire une commande | Un nouveau résumé | `commandeAffichee` (`who.mjs:211`) **derrière le bouton existant** | CKPT-24 : la commande seulement derrière « Voir la dernière commande » ; la liste d'outils du transcript n'en porte jamais le texte |
| Tuer des processus de test | `pkill -f`, `kill $(pgrep …)` | `hygiene.sh` (`vf_hyg_init/stop/assert/fin`) | Incident du 2026-11-02 (marque vide qui tuait toute la machine) ; garde G1-G5, M1, m1, m2 déjà sous test (`test-cockpit-hygiene.sh`) |
| Lire le registre des agents | `awk` sur `DRIVER.lock.children.jsonl` | `driver-lock.sh orphans` via `driverLockScript` (résolu hors de l'arbre observé, T-67-06) | `registry_fold` est le « unique lecteur » ; le script résolu est la seule source de confiance |
| Valider un JSON contre le contrat | Un validateur de plus | `validate.mjs` des suites, étendu | Lit déjà `requis`, `interdits`, `kinds`, `etatsSource` |
| Échapper pour l'affichage | `escape` local | `h()` du viewer (`SC.h`) et `textContent` | Convention XSS du module (audit 67-SECURITY B2) |

**Key insight:** ce module a payé cher chaque « presque pareil » (fuite de commande, marque vide, XSS stockée). Réutiliser les mécanismes testés, étendre leurs tests, ne pas dupliquer.

## Faits mesurés dans le worktree (réponses aux dix points demandés)

### R1. Code existant (point 1)

**R1.1 `vf-cockpit-project.mjs`** [CONFIRMED]
- `phaseStatus` (l. 36) : `const phaseStatus = (ph) => ph.done ? 'done' : (ph.n === curPhase && state.status !== 'closed' && (!activeWs || ph.ws === activeWs)) ? 'active' : 'todo';` -> la règle à retirer inclut la condition `activeWs` (compartiment actif) et `state.status`.
- `sums` (l. 66) : `new Set(ls(dir).filter((f) => /-SUMMARY\.md$/.test(f)).map((f) => f.replace('-SUMMARY.md', '')))` ; le pied de phase (l. 70) : `foot: [planFiles.length ? \`${sums.size}/${planFiles.length} plans\` : '', …]` -> source de `11/7`. Le statut d'un plan (l. 75) : `st: sums.has(pid) || ph.done ? 'done' : st === 'active' ? 'active' : 'todo'` -> tout plan non fait d'une phase `active` devient `active` : avec `en-cours` calculé, il faut décider ce que devient un plan non fait (OQ-6).
- Jalon : statut l. 47 `ms.icon === '✅' ? 'done' : done > 0 && done < ks.length ? 'active' : done === ks.length && ks.length ? 'done' : ms.icon === '🚧' || (ms.synthetic && ks.length) ? 'active' : 'todo'` ; pied l. 56 `foot: \`${ms.done}/${ms.ks.length} phases · ${pct(ms.done, ms.ks.length)} %\``.
- Rattachement des missions (l. 90-93) : `const k = /^MISSION-(\d+(?:\.\d+)?)/.exec(d.name)?.[1]; const tp = k ? findPhase(k, d.ws) : null;` sinon carte `missions` (« Missions hors phase »). `DST` (l. 16) : `{ done: 'done', running: 'active', ready: 'todo', blocked: 'todo', failed: 'blocked' }`.
- `curPhase` sert encore à `meta.vf.phase` et au sous-titre (`resume`) : ne pas le retirer, seulement de `phaseStatus` (le panneau « Maintenant » lit `V.phase`/`V.status`, `00-vibeflow.js:86`).
- Sur le worktree réel, aujourd'hui : `ph-67 | done | 11/7 plans · 12/12 exigences` (C2 reproduit hors fixture) et `dag-2026-11-01-v2-cockpit` sous `missions` (C4 reproduit) ; C1 et C3 ne se reproduisent que sur fixture (la 67 est cochée, le STATE pointe 69). [CONFIRMED: exécution de `buildProjectGraph`]

**R1.2 `vf-cockpit-planning.mjs` (`readPlanning`)** [CONFIRMED]
- Retourne `{ phases, phaseDirs, reqs, milestones, state, dags, backlog, seeds, tags, projectName, activeKeys, rel }` (l. 119). Les entrées de phase : `{ key, n, ws, name, done, line, roadmap, goal, depends[, archive] }`.
- `phaseDirs` : clé `<ws>|<n>` ou repli `*|<n>` (archives) (l. 82-86).
- DAG (l. 102-109) : lus dans chaque dossier de compartiment, dans `.planning`, dans `.planning/missions`. L'enregistrement gardé est `{ name, ws, file, nodes }` : **`j.phase` et `j.ws` sont jetés** (l. 107 `dags.push({ name: f.replace(/\.dag\.json$/, ''), ws, file: rel(...), nodes: j.nodes })`). CKPT-15 exige de les conserver. Le `ws` d'un DAG de `.planning/missions` est `null` (déduit du dossier), alors que le fichier peut porter `"ws"`.
- Aucun DAG n'est cherché dans les dossiers de phase (règle (3) de D-05) : aucun DAG de phase n'existe aujourd'hui (R4.3), la règle est donc testable par fixture seulement.

**R1.3 `vf-cockpit-who.mjs`** (239 lignes) [CONFIRMED]
- Aplatissement des sous-agents (l. 84-108) : pour chaque `*.meta.json`, `if (meta.finished || sAge >= fresh) continue;` (l. 88) -> un agent terminé, **et** un agent non terminé silencieux depuis 180 s, sont écartés ; `if (!REQ_META.every((k) => k in meta))` (l. 89) -> seules `agentType` et `description` sont exigées (`REQ_META` l. 26) ; le travailleur est `{ kind: 'subagent', id, parent: id /* identifiant de SESSION */, role, task, depth: meta.spawnDepth ?? null, background: meta.requestShape === 'background', tree, treeBy, branch, ageS, source: 'subagent-meta', _tr }` (l. 106). Donc `parent` vaut toujours la session : l'arbre n'est pas reconstructible aujourd'hui.
- Session racine : le travailleur `session` n'est poussé que si `age <= fresh` (l. 98) ; `if (age > fresh && !subs.length) continue;` (l. 92) garde les sessions calmes qui ont des sous-agents vivants mais **sans** les lister comme racine.
- Registre : `for (const a of o.orphans || []) { reg++; workers.push({ kind: 'registered', id: a.agent_id, role: a.role, task: a.node || '', parent: a.parent || '', depth: a.depth ?? null, … }) }` (l. 129) : `task` d'une ligne `registered` est le **nom de nœud**.
- DAG running : `dagDirs = [.planning, .planning/missions, <common>/vf-driver/ws/*, <common>/vf-driver/repo]` (l. 135) : **n'inclut pas** `.planning/workstreams/<ws>/`.
- Durée de lecture : `collectWho` mesuré à ~244 ms par appel (2 agents vivants, 60 dossiers de projet) ; `revealDoing` ~246 ms (rejoue toute la collecte). [CONFIRMED: chronométrage local]
- Sortie publique : `bornes()` masque et coupe `task` (160), `cwd` (200), `role` (80) ; le schéma est `'vibeflow/cockpit-who@1'` (l. 160).
- Constat live (cette session) : un même agent figure **deux fois** dans la liste plate (`subagent` + `registered`, même identifiant) ; un agent terminé selon son `meta.json` reste « running » dans le registre (« statut consigné, pas statut runtime », `driver-lock.sh` commentaire du registre). [CONFIRMED: sortie de `collectWho` sur ce worktree]

**R1.4 Serveur, SSE, HTTP, CSP** [CONFIRMED]
- `serve.mjs` (vendorisé, 610 lignes) : en-têtes de toute réponse `BASE_CSP = "default-src 'none'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'"` (l. 487) ; contrôle du Host `[\`127.0.0.1:${port}\`, \`localhost:${port}\`]` (l. 505) ; pour `/api/*` : `given = req.headers['x-floorplan-token'] || (… '/api/vf/events' ? url.searchParams.get('token') : null)` (l. 510) puis 403 si `!sameOrigin || (given !== token && !VF?.jetonValide(given))` (l. 511) ; seuls `events` prennent le jeton en query (EventSource n'envoie pas d'en-tête). Une route inconnue sous `/api/vf/` sans jeton donne **403**, avec jeton 404 (`vf-cockpit-server.mjs:89`).
- Pages : `if (url.pathname === '/project.html' && VF?.pageProjet()) return sendPage(res, VF.pageProjet());` (l. 568) ; `sendPage` calcule `pageCsp(html)` = `default-src 'none'; script-src <sha256 de chaque script en ligne>; style-src 'unsafe-inline'; img-src 'self' data:; font-src data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'; object-src 'none'` (l. 487-497). Un `.html` servi comme fichier statique (l. 578) ne reçoit que `BASE_CSP` : ses scripts sont bloqués. **Conséquence : une page `equipe.html` ne peut exister sans nouveau patch de `serve.mjs`** (P24 : la dernière numérotation est P23 dans `VENDORED.txt`).
- Jetons : `token` (page Code) et `ptoken` (page Projet, `vf-cockpit-server.mjs:27`, `jetonValide`) ; `ptoken` identifie l'onglet Projet pour les questions (`avantQuestion`, l. 94). Une page Équipe a besoin de son jeton (réutiliser `ptoken` ferait traiter ses questions comme des questions Projet ; en ajouter un nécessite `inject.replace(token, …)` comme `load()` l. 32).
- Diffusion : `diffuser(nom, data)` refuse tout objet portant la clé `doing` à toute profondeur (`porteDoing`, l. 23 ; l. 48-53) et `hello` de même (l. 68). La liste d'interdits est **codée en dur** dans le serveur, alors que `interdits: ["doing"]` figure aussi dans `interface.json` : deux sources.
- `GET /api/vf/doing?id=` : `ID_RE.test(id)` sinon 400 `{erreur:'id-invalide'}` ; `json(res, 200, revealDoing(root, id, { scriptsDir }))` ; `Cache-Control: no-store`, « jamais journalisée ni écrite » (l. 77-83). Toute route `/api/vf/*` est GET seulement (405 sinon, l. 63).
- Direct : `whoSig = JSON.stringify((w.workers || []).map((x) => [x.kind, x.id, x.tree, x.branch || '', !!x.stale, x.task || '']))` (`vf-cockpit-live.mjs:65`) -> un changement de parent, d'état terminé, d'action ou de lien **ne déclenche aucun événement `who`** tant que la signature n'est pas étendue. `index(g)` du graphe ne diffe que `st`, `foot`, `summary` (l. 21-26) : toute information d'avancement à rafraîchir en direct doit passer par ces trois champs.
- Résidu connu M7 : le jeton est servi à tout processus local par `GET /` (67-SECURITY M7, accepté, hypothèse mono-utilisateur). Un endpoint de transcript hérite de cette limite. [CONFIRMED: `67-SECURITY.md` l. 118-120]

**R1.5 Couche d'interface** [CONFIRMED]
- Les onglets sont des **pages distinctes** : `tabs.innerHTML = '<a href="index.html" …>Code</a><a href="project.html" …>Projet</a>'` (`ui/00-vibeflow.js:66`). Un troisième onglet = `equipe.html` (même coque `viewer.html`, autres données).
- Tiroir : `whoPanel` (`ui/70-vf-live.js:50-59`), `KIND` (l. 48), `row(w)` (l. 52-56) avec `data-vf-doing`, révélation `fetch('/api/vf/doing?id=' + encodeURIComponent(…), { headers: { 'x-floorplan-token': SRV.token } })` (l. 67), texte posé par `zone.textContent` (l. 70). Tout champ interpolé dans un gabarit passe par `h()`.
- Le viewer construit `const nodes = new Map(G.nodes.map(...))` et `files` **une seule fois** au chargement (`viewer.html:696-697`) ; `Floorplan.rerender()` ne les reconstruit pas. Les patchs de statut agissent en place (mêmes objets) ; un nœud ajouté ou retiré exige un rechargement (c'est le mécanisme `structural` existant, `ui/70-vf-live.js:157`).
- `window.Floorplan` expose `addHeaderButton`, `showPanel`, `addPanelSection('item', fn)`, `reveal`, `on('ready')`, `rerender`, `toast`, `h` ; passerelle entre onglets : liens `href="project.html#r=<ref>"` et l'écouteur `#r=` (`00-vibeflow.js:121-127`) -> le lien « nœud -> agent » peut passer par `addPanelSection('item', …)` lisant `window.__vfLive.who`.
- « Prochaines phases » affiche un libellé **figé** `À faire` (`00-vibeflow.js:82` : `<span class="vst vst-todo">À faire</span>`) pour toute phase non faite : une phase `a-recetter` y serait mal nommée.
- Pastille de statut du viewer : `({ done: 'Fait', active: 'En cours', todo: 'À faire', blocked: 'Bloqué' })[vst] || vst` (`viewer.html:932`) : un `st` hors de ces quatre valeurs s'afficherait brut (`a-recetter`) avec une classe CSS sans couleur. `interface.json` : `"statuts": ["done", "active", "todo", "blocked"]`.
- CSS/CSP : `style-src 'unsafe-inline'` ; scripts par empreinte -> tout nouveau JS d'interface change l'empreinte mais pas la forme de la CSP.

### R2. Suites de tests (point 2)

**R2.1 Découverte et exécution** [CONFIRMED]
- Découverte : `discover() { find plugin scripts -type f -path '*/tests/test-*.sh' | LC_ALL=C sort; }` (`scripts/ci-shard-suites.sh:22`). Toute suite nommée `plugin/cockpit/scripts/tests/test-*.sh` est découverte sans autre déclaration. `hygiene.sh` et `chrome-*.mjs` ne sont pas des suites (nom hors motif).
- Exécution : job `tests-shard` (7 shards), étape **« Lancer les suites du shard »** (`.github/workflows/ci.yml:285`) : `bash "$t" </dev/null` pour chaque suite du shard (`GW_MODE: sans-mutants`) ; job agrégateur `tests` (nom exact exigé par le ruleset) rejoue la partition et exige union = découverte.
- Aucune suite du cockpit n'est nommée dans le job `gates` ; `ci.yml` ne contient pas le mot « cockpit ».
- Répartition actuelle (calcul de `ci-shard-suites.sh 0..6 7`) : shard 2 = assemblage, marque-blanche, reseau, vendor ; shard 3 = chaine-xss, onglet-code, responsive, who ; shard 4 = chrome-fr, projet, robustesse ; shard 5 = direct, questions, securite ; shard 6 = hygiene, reconnexion, serveur. 17 suites au total. Ajouter des suites décale le tourniquet alphabétique des suivantes (sans conséquence fonctionnelle).
- Suite d'installation liée : `plugin/_internal/tests/test-vibeflow-update-cockpit.sh` (I1-I8) compare à l'octet les fichiers texte posés dans les trois scopes ; un fichier nouveau sous `plugin/cockpit/` est copié par l'engine sans déclaration.

**R2.2 En-têtes des suites (aucune ne se déclare « gelée »)** [CONFIRMED : lecture des en-têtes ; recherche de « gelé / frozen / immuable » dans `tests/` : aucun résultat]

| Suite | Couvre | Jouée seule | Notes |
|-------|--------|-------------|-------|
| `test-cockpit-assemblage.sh` | A1 sortie, A2 données des deux pages, A3 serveur/Host, A4 refus en français, A5 liste du code d'exécution (fixture synthétique) | `bash plugin/cockpit/scripts/tests/test-cockpit-assemblage.sh` | A2.2 : `vibeflow/cockpit-project@1` |
| `test-cockpit-chaine-xss.sh` | lab piégé -> page -> jeton -> POST `/api/plan/undo` ; mutants M-ESC, M-CSP, M-GARDE | idem | simulation node si pas de Chrome |
| `test-cockpit-chrome-fr.sh` | F1-F8 : inventaire FR, dictionnaire, exclusions | idem | n'inspecte que `index.html` et `project.html` |
| `test-cockpit-direct.sh` | D1-D5 : SSE, patch, structural, hystérésis, scrutation | idem | D2.2/D2.6 : phase 2 `done` |
| `test-cockpit-hygiene.sh` | garde-fous de `hygiene.sh` (sonde + mutations) | idem | ne rien tuer de réel (`VF_HYG_DRY=1`) |
| `test-cockpit-marque-blanche.sh` | M1-M4 | idem | |
| `test-cockpit-onglet-code.sh` | C1-C4 | idem | |
| `test-cockpit-projet.sh` | P1 lab plat, P2 partitionné, P3 sans jalons avec missions, P4 contrat, P5 identité de phase | idem (35 PASS, 21 s mesurés) | **P1.1, P1.2, P1.5 encodent la règle STATE** (R2.3) |
| `test-cockpit-questions.sh` | Q1-Q12 : réponses locales, agent confiné | idem | Q10-Q12 lisent `st` `todo`/`active` |
| `test-cockpit-reconnexion.sh` | N1-N4 : recul de reconnexion | idem | sautée sans Chrome |
| `test-cockpit-reseau.sh` | R1-R3 : aucune connexion sortante | idem | **témoin réseau de CKPT-03, à rejouer sur la phase (CKPT-28)** |
| `test-cockpit-responsive.sh` | R1-R5 : 1 024-2 560 px | idem | sautée sans Chrome |
| `test-cockpit-robustesse.sh` | S1, S3, P1, F, B, K, U, V, W | idem | K : `files_modified: [constructor]` |
| `test-cockpit-securite.sh` | H en-têtes, X, B, S, J, M masque, L, Y, E, C, T, R | idem | **H1 liste en dur `/ /project.html /graph.json /inexistant /api/vf/etat`** (R2.4) |
| `test-cockpit-serveur.sh` | S1-S9, PS, DO : jetons, Host, cachés, CORS, flux sans `doing`, révélation, fichiers générés, export, journal, port stable | idem | gabarit direct de CKPT-25 |
| `test-cockpit-vendor.sh` | V1-V8 : licence, tailles (**300 lignes**), amont retrouvé à l'octet, ajouts/patchs/retraits | idem | V7 exige un diff par ligne `PATCH` et chaque `AJOUT` présent |
| `test-cockpit-who.sh` | W1-W16 : collecte, verrou, graphe Projet, validateur du contrat, forme inconnue (**W8**), masque, tiroir | idem | **W1.1, W4.1, W4.3, W10.1 citent `who@1`** |

Toutes se rejouent avec `bash <suite>` (code 0 = vert ; une suite sans navigateur annonce « SAUTÉE » et sort 0).

**R2.3 Assertions qui changent de sens par conception (à réécrire dans le même commit que le retrait, avec la raison dans le message — doctrine « ne pas supprimer pour verdir »)** [CONFIRMED]
- `test-cockpit-projet.sh` P1.1 `ph-1:done,ph-2:active` (fixture `current_phase: 2`, plan sans SUMMARY -> devient `a-faire`/`todo`), P1.2 `01-01:done,02-01:active`, P1.5 `active|1/2 phases · 50 %` (nouveau pied du jalon).
- `test-cockpit-who.sh` W1.1 (`vibeflow/cockpit-who@1`), W4.1, W4.3, W10.1 si le schéma passe à `@2` (CKPT-28 : « dont la version monte »).
- À rejouer pour vérifier qu'elles tiennent : `test-cockpit-direct.sh` (D2, D5 : `done`), `test-cockpit-questions.sh` (Q10-Q12), `test-cockpit-serveur.sh` (S5.1/S5.2 : forme de `hello.who.workers`), `test-cockpit-assemblage.sh`.

**R2.4 Sondes qui ne gardent rien aujourd'hui** [CONFIRMED]
- Aucune suite ne lit `parentAgentId`, `toolUseId`, `isSidechain` (recherche dans `scripts/` : aucune occurrence hors `interface.json`) ; `requestShape` et `spawnDepth` ne sont lus que pour être recopiés, jamais exigés.
- `interface.json` : les listes `attendus`, `drapeauFin` et `verifieSur` ne sont lues par aucun code (`CC.transcript?.requis` et `CC.metaSousAgent?.requis` seuls le sont, `who.mjs:25-26`). Les listes `travailleur.optionnels` ne sont pas appliquées par `validate.mjs` (il ne vérifie que `requis`) : un champ ajouté ou retiré passe sans bruit.
- L'inventaire du chrome français ignore les blocs d'extension VibeFlow : `MARQUEURS_FR = /^\s*(?:\/\* ui\/[\w.-]+ \*\/\s*)?\/\/ (?:vibeflow:fr|vibeflow:allow-large-file|VibeFlow \()…/` (`vf-cockpit-fr-inventaire.mjs:113`) et ne lit que `index.html`/`project.html` (l. 152). Un libellé anglais dans la couche de l'équipe ne rougirait **aucune** suite ; CKPT-23 demande un test qui rougit : écrire une sonde dédiée avec `litteraux()` + `estAnglais()` (exportées).
- `test-cockpit-securite.sh` H1/H4 : liste de pages en dur ; une page `/equipe.html` et une route `/api/vf/transcript` ne seraient pas contrôlées avant d'y être ajoutées.
- `test-cockpit-assemblage.sh` A5.1 travaille sur un dossier synthétique de faux modules : ajouter des modules `vf-cockpit-*.mjs` ne le casse pas, mais ne prouve pas non plus qu'ils sont recopiés (à prouver dans une suite nouvelle : `fichiersExecution(scriptsDir réel)` contient les nouveaux modules).

**R2.5 Où loger les tests nouveaux sans toucher une suite verte** (proposition, ASSUMED sur les noms)
- `test-cockpit-avancement.sh` (CKPT-13..18) : labs jetables a-d, rattachements, retrait de la règle STATE par mutation, aucun réseau.
- `test-cockpit-equipe.sh` (CKPT-19, 20, 21, 22, 28) : HOME jetable portant sessions et sous-agents à trois niveaux, registre factice.
- `test-cockpit-forme-claude.sh` (CKPT-27) : forme de `meta.json` et du transcript, une fixture conforme + une fixture amputée par champ.
- `test-cockpit-transcript.sh` (CKPT-24, 25, 26) : endpoint, SSE, fichiers générés, export, rendu texte.
- CKPT-23 : une sonde dans la suite de l'équipe (onglet présent, chrome sans anglais) ; ne pas modifier `chrome-fr` (son inventaire est volontairement limité).
- Chaque suite nouvelle change le compte vérifié par `check-version-sync.sh` (R9) : mettre à jour **les deux README racine** dans le même plan (+4 -> 146 si quatre suites).

**R2.6 Fixtures et helpers existants** [CONFIRMED]
- Style de fixture : labs écrits dans `mktemp -d` par `wr <fichier> <<'MD'`, `git init -q` pour les tests de worktree, HOME jetable (`export HOME="$WORK/home"`), `GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null`, port libre par `node -e "net.createServer().listen(0…)"`.
- Helpers : `mk_session` (session Claude Code fraîche, `test-cockpit-who.sh`), `mk-d3.mjs`, `ev.mjs`/`get.mjs`/`stdin-get.mjs`/`pg.mjs` (expressions JS évaluées sur un JSON), `sse.mjs` (client SSE auto-borné), `post.mjs`, `scan.sh` (balayage d'un dossier pour un marqueur), `chrome-cdp.mjs` (`CDP_VIEWPORT`, `CDP_PRET`).
- Helper de kill : **`hygiene.sh` uniquement**. Règles D-24 présentes et sous test : marque passée à `awk` par l'environnement (`ps … | VF_T="$VF_HYG_TAG" … awk`) ; marque invalide refusée (`vf_hyg_tag_ok`, `tmp.` + >= 6 alphanumériques, longueur >= 10) ; plafond `VF_HYG_MAX=20` ; jamais `$$`, `$PPID`, ancêtres, pid <= 1 ; contrôle `vf_hyg_marque_p` avant chaque signal ; `VF_HYG_DRY=1`. Aucun `pkill`. Le « leurre vivant » est un processus étranger créé par la sonde de `test-cockpit-hygiene.sh` (pid étranger jamais visé) et par `PS.7` de `test-cockpit-serveur.sh`.

### R3. Test de forme CKPT-01 et `interface.json` (point 3)

- Le test de forme est **W8** de `test-cockpit-who.sh` (`:144`) : une session dont la clé `cwd` est renommée n'est pas listée et la source passe `forme-inconnue` (W8.1-W8.3) ; un `meta.json` sans `agentType` compte `formeInconnue` = 1 tandis que le sous-agent conforme est listé (W8.4-W8.6). Fixture de `meta.json` conforme : `{"agentType":"vf-coder","description":"tâche","spawnDepth":2}`.
- Source des clés exigées : `interface.json` `claudeCode` (l. 27-38), citée telle quelle :
  - `"verifieSur": "2.1.316"`
  - `"transcript": { "requis": ["cwd", "type", "message", "timestamp", "sessionId"], "attendus": ["gitBranch", "version"] }`
  - `"metaSousAgent": { "requis": ["agentType", "description"], "attendus": ["spawnDepth", "parentAgentId", "toolUseId"], "drapeauFin": ["finished"] }`
- Le code n'applique que `requis` (`REQ_TR`, `REQ_META`, l. 25-26 de `who.mjs`). `formeInconnue` est compté mais **`sources.sessions.etat` ne passe à `forme-inconnue` que si `formeInconnue > 0 && live + subLive === 0`** (l. 111) : si une session valide est vue en même temps, un sous-agent à forme inconnue est seulement compté. CKPT-27 exige « un champ disparu rend la source `forme-inconnue`, jamais un arbre faux » : écrire explicitement le comportement (source dégradée ET agents concernés absents de l'arbre) et le tester séparément.
- Extension requise pour CKPT-27, **avec les conditions mesurées** (R5.1) :
  - `parentAgentId` : requis **seulement** si `spawnDepth >= 2` ; absent légitime à `spawnDepth` 1.
  - `finished` : booléen **facultatif** (absent = actif, `true` = terminé) ; une autre valeur est une forme inconnue. Ne pas l'ajouter à `requis`.
  - `toolUseId`, `spawnDepth`, `requestShape` : présents 40/40 sur l'échantillon -> exigibles ; valeur de `requestShape` observée : `background` seulement (ne pas énumérer une liste fermée sans autre mesure).
  - Transcript de sous-agent : `isSidechain` (booléen `true`) et `agentId` (chaîne égale à l'identifiant du fichier) sur la première ligne ; nouveau bloc `claudeCode.transcriptSousAgent.requis`.
  - Mettre à jour `verifieSur` (la mesure ci-dessous est faite sur Claude Code 2.1.317, `claude --version` et champ `version` des lignes) : [CONFIRMED].
- Le contrat de sortie : `interface.json` `schemas["vibeflow/cockpit-who@1"]` (l. 5-14) cite `travailleur.requis: ["kind","id","tree","source"]`, `kinds`, `etatsSource`, `interdits: ["doing"]`. `validate.mjs` (outil de `test-cockpit-who.sh`/`projet.sh`) échoue sur : clé requise absente, type, `schema` différent, clé interdite à toute profondeur, `kind` inconnu, état de source inconnu.

### R4. Registre `driver-lock.sh` et DAG (point 4)

**R4.1 Registre** [CONFIRMED: `plugin/conductor/scripts/driver-lock.sh`]
- Usage (en-tête l. 33-35, cité) : `driver-lock.sh register --agent=<id> --role=<role> [--node=<id DAG>] [--parent=<id>] [--depth=<n>] [--owner=<id>]` · `driver-lock.sh close --agent=<id> --status=done|failed|stopped` · `driver-lock.sh orphans`.
- Fichier : `<git-common-dir>/vf-driver/ws/<sujet>/DRIVER.lock.children.jsonl` en lab partitionné, `…/repo/…` pour le dépôt, `.planning/DRIVER.lock.children.jsonl` en lab plat ou `VF_DRIVER_CHILDREN` (mode verrou unique). Sur ce poste : un fichier, `vf-driver/ws/fiabilite/DRIVER.lock.children.jsonl`, 2 lignes `register`.
- Forme d'une ligne `register` : `{"event": "register", "agent_id": "…", "parent": "…", "role": "…", "node": "…", "owner": "…", "generation": "…", "status": "running", "dispatched_at": "…", "epoch": N[, "depth": N]}` ; `close` : `{"event": "close", "agent_id", "status", "closed_at", "epoch"}`. JSON Lines append-only ; état courant = dernière ligne par `agent_id` (`registry_fold`, l. 636).
- **`orphans` ne rend que les entrées `running`** (`orphans_tsv` : `$10 == "running"`) : `{"present": true, "registry": "…", "count": N, "orphans": [{agent_id, parent, role, node, owner, generation, dispatched_at, age_seconds, depth, status:"running"}]}`. Il n'existe **aucun verbe pour lister les entrées fermées**. Un agent terminé depuis < 24 h n'a donc pas son `--node` disponible par le seul verbe public (OQ-4).
- `agent_id` du registre = identifiant de fichier de Claude Code (`agent-<id>`) : 2 entrées sur 2 de ce poste ont leur identifiant parmi les `meta.json` du projet (17 caractères, ex. forme `a7ba1f4e81cdf5b14`). Échantillon minuscule : à reconfirmer en test. [CONFIRMED sur 2 entrées ; reste ASSUMED en général]
- **La profondeur du registre n'est pas `spawnDepth`** : l'agent `gsd-phase-researcher` de cette session est `spawnDepth: 3` dans son `meta.json` et `"depth": 2` dans le registre. Ne jamais mélanger les deux ; l'arbre utilise `spawnDepth` et `parentAgentId`.
- Résolution du script : `driverLockScript({ scriptsDir, labRoot, home })` (`paths.mjs`), jamais un script du lab (T-67-06). Le verbe est appelé avec `bash <script> orphans [--ws=<ws>]` pour `['', …ls(vf-driver/ws)]` (`who.mjs:124-130`).

**R4.2 DAG** [CONFIRMED]
- Forme : `{ "nodes": [ { id, step, stage, deps[], scope[], status } ] }` plus, facultatif, `"ws"` (posé par `dag.sh init --ws`) et `"phase"` (**posé à la main**, aucun verbe de `dag.sh` ne l'écrit). Statuts valides : `VALID = {"blocked", "ready", "running", "done", "failed"}` (`plugin/conductor/scripts/dag.sh:124`). Clés de tête mesurées sur 27 DAG : 24 avec `nodes` seul, 2 avec `nodes,ws`, 1 avec `phase,nodes,ws`.
- Emplacements sur le disque : `.planning/MISSION-*.dag.json` (17), `.planning/missions/*.dag.json` (7), `.planning/workstreams/fiabilite/*.dag.json` (3, dont `MISSION-69.dag.json`) ; aucun sous `phases/`.
- **Les identifiants de nœud ne sont pas uniques entre DAG** : sur 27 DAG, 355 identifiants distincts dont 28 présents dans plusieurs DAG (`docs` dans 22, `plan` 8, `revue` 7, `discuss` 6, `plancheck` 5, `gates` 2, `exec-01` 3…). `plan-69` est unique (1 DAG) ; `revue-p3` et `exec-p3a` (cités par d'anciens mandats) n'existent dans aucun DAG de ce worktree. Conséquence : pour la chaîne D-15, un nom de nœud n'est un lien que s'il se résout à **un seul** DAG parmi ceux du compartiment/du lab ; un nom ambigu ou inconnu donne « non rattaché », jamais un choix.
- Les mandats réels citent le nœud sous plusieurs formes (mesure sur 40 mandats : 38 contiennent « nœud … ») : « Nœud \`revue-p3\` », « nœud fix-revue », « nœud : plugin », et des faux positifs (« noeuds_debloques » est un nom de champ de protocole). Le motif de citation doit être structuré (marqueur « nœud » ou « --node= » suivi immédiatement d'un identifiant borné) **et** l'identifiant doit exister dans l'index des DAG ; les mots courants (`docs`, `plan`) ne doivent jamais lier par simple présence dans le texte.
- Chaîne D-15 proposée : (1) registre `--node` (agent encore `running`) -> identifiant de nœud ; (2) sinon citation structurée dans le mandat ; (3) dans les deux cas, résolution dans l'index `Map<id, [DAG…]>` construit depuis **`readPlanning().dags` + les DAG que lit déjà `who` (vf-driver)** ; (4) un seul DAG candidat (ou un seul où le nœud n'est pas `done`) -> lien `{dag, node}` ; sinon `{ rattache: false, raison: 'inconnu'|'ambigu' }`. [Proposition ASSUMED ; l'ordre des sources est verrouillé par D-15, la règle d'unicité est la lecture de « jamais deviné » à confirmer : OQ-5.]

**R4.3 Ligne `phase` du DAG de la 67** [CONFIRMED]
- `.planning/missions/2026-11-01-v2-cockpit.dag.json` porte déjà `"phase": "67"` et `"ws": "fiabilite"` (commit `40bc239c` « champ phase 67 dans le DAG de la mission 67 »). Le « point ouvert » du cadrage est donc fermé sur cette branche ; `buildProjectGraph` l'ignore encore (nœud `dag-2026-11-01-v2-cockpit` sous `missions`).
- `MISSION-69.dag.json` (compartiment `fiabilite`, modifié non commité par l'orchestrateur) : 2 nœuds, `cadrage-69` `done`, `plan-69` `running` ; il se rattache par la règle (2) (`MISSION-69` -> phase 69).

**R4.4 Fichiers de preuve de `reste`** [CONFIRMED]
- Recette humaine : `67-RECETTE-HUMAINE.md` existe ; sa ligne 3 : `**Statut : FAITE — close le 2026-11-03 (passes 1 à 4 ; …).**`. Règle de lecture proposée : première ligne qui commence par `**Statut :` ; « FAITE » dedans -> faite ; autre ou absente -> à faire. (ASSUMED : aucune autre phase n'a de fichier de ce nom à comparer ; trouvé : un seul `*RECETTE-HUMAINE*`.)
- Vérification : motif `*-VERIFICATION.md` (nombreux : `01-VERIFICATION.md`, `28-01-VERIFICATION.md`, `40.1-VERIFICATION.md`…) ; la 67 n'en a pas.
- Clôture : case de ROADMAP non cochée (`ph.done`). La 67 dispose aussi de `67-CLOTURE.md` (ne pas s'en servir : D-07 ne le cite pas).

### R5. Format du transcript, F-B, endpoint, menace (point 5)

**R5.1 Format observé sur Claude Code 2.1.317** [CONFIRMED: lecture de la structure (clés et types seulement) de 40 sous-agents d'une session et de 516 fichiers pour les tailles]
- `meta.json` : clés `agentType` (chaîne), `isBuiltIn`, `launchedWithDefaults`, `description`, `toolUseId`, `parentAgentId` (37/40), `spawnDepth` (nombre : 1, 2 et 3 observés), `requestShape` (`background`), `requestNonInteractive`, `finished` (booléen).
- **`finished` est absent sur les agents actifs** (deux `meta.json` actifs de cette session n'ont pas la clé ; le troisième, terminé, porte `finished: true`). **`parentAgentId` est absent à `spawnDepth` 1** (les 3 absents sur 40 sont : 2 `vf-dev-manager` et 1 `vf-coder` à profondeur 1) et présent, désignant un autre agent du même dossier, à profondeur >= 2 (0 parent hors ensemble). Profondeur 3 existe (ce chercheur).
- `meta.json` ne porte aucune date : l'heure de fin d'un agent terminé = `mtime` de son `.jsonl` (ASSUMED : l'agent n'écrit plus après `finished`) ; sa durée = dernière date - date de la première ligne.
- `.jsonl` : lignes de types `user`, `assistant`, `attachment`, `api-request-shape`, `api-request-blob`, `api-request`. Première ligne : `type: "user"`, `isSidechain: true`, `agentId` (= identifiant du fichier), `parentUuid: null`, `message.content` **chaîne** = le mandat (2,3 à 7 Ko sur l'échantillon). Les lignes `user` suivantes portent `message.content` en tableau de `tool_result` et un champ de tête `toolUseResult` (objet) : **les sorties d'outils sont à deux endroits**. Les lignes `api-request-blob` recopient `text`, `thinking`, `tool_use` **et `tool_result`** de la requête : une seconde copie des sorties. Les blocs `assistant` sont `thinking`, `tool_use` (clés `type,id,name,input,caller`) et `text`.
- Outils appelés (22 008 `Bash`, 1 123 `Read`, 611 `Write`, 494 `Edit`, 441 `Agent`, 139 `SendMessage`, 42 `WebSearch`, 27 `Monitor`, 26 `WebFetch`, 21 `Skill`, 20 `ToolSearch`, 20 `bash` en minuscules, 15 `Grep`, 11 `TaskStop`, `mcp__playwright__*`, `SubagentHandback`) ; clés d'entrée : `Bash` -> `command` (+ `description` dans ~30 % des appels, `timeout`, `run_in_background`) ; `Read`/`Write`/`Edit` -> `file_path` ; `Grep` -> `pattern`,`path` ; `Agent` -> `description`,`subagent_type`,`prompt` ; `WebFetch` -> `url` ; `Skill` -> `skill` ; `SendMessage` -> `to`,`message`.
- Tailles : 516 transcripts de sous-agents ; médiane 1,17 Mo ; p90 2,26 Mo ; **max 8,83 Mo** (> 8 Mio, la dernière fenêtre de `cherche`). 60 dossiers de session pour ce projet.

**R5.2 « Dernière action lisible » et règle F-B** [CONFIRMED]
- F-B : décision de Samuel « N'afficher que le programme (Recommandé) » (AskUserQuestion session principale, 2026-11-02) : `67-RECETTE-HUMAINE.md` l. 110-112 ; code `resume()`/`commandeAffichee` (`who.mjs:192-211`), `lastCommand` (`who.mjs:212`), bouton `data-vf-doing` (`ui/70-vf-live.js:61-73`), CHANGELOG « « Voir la dernière commande » (D3) ».
- Aujourd'hui seule la dernière commande **Bash** est lue (`lastDoing` cherche `name=Bash`). CKPT-22 demande le dernier appel d'outil **quelconque**. Proposition (ASSUMED, compatible D-16) : table fermée nom d'outil -> verbe (`Read` « lit », `Write`/`Edit` « modifie », `Grep` « cherche dans », `Bash` « lance une commande », `Agent` « lance un agent », `SendMessage` « écrit à », `WebFetch` « consulte une page », `WebSearch` « cherche sur le web », `Skill` « utilise le skill », `mcp__*` « utilise <nom> », inconnu « utilise un outil »). Cible : chemin **relatif au lab** pour `Read`/`Write`/`Edit`/`Grep` ; hors lab -> « un fichier hors du lab » ; `WebFetch` -> nom d'hôte seul (jamais chemin, requête ni identifiants) ; `Bash` -> jamais `command` ; sa `description`, texte libre écrit par le modèle, n'est reprise que masquée et bornée si l'on veut un libellé plus parlant (choix à confirmer, OQ-7).

**R5.3 Endpoint de transcript : conception** (ASSUMED, patron de `/api/vf/doing`)
- `GET /api/vf/transcript?id=<agentId>` sous `VF.route` (donc après Host + même origine + jeton en en-tête) ; `ID_RE` sinon 400 `{erreur:'id-invalide'}` ; id absent de la collecte (fenêtre 24 h comprise) -> 200 `{erreur:'inconnu'}` comme `doing` ; réponse `Cache-Control: no-store`, jamais journalisée.
- Réponse (schéma versionné, p. ex. `vibeflow/cockpit-transcript@1`) : `{ schema, id, mandat, messages[], outils[], tronque }`. `mandat` = première ligne `user` si `content` est une chaîne ; `messages` = blocs `assistant` `text` seulement ; `outils` = `[{ outil, verbe, cible }]` du réducteur de R5.2, jamais `input` brut ; bornes (p. ex. 8 000 caractères de mandat, 50 messages de 2 000, 200 outils) et tête/queue de fichier lues avec une fenêtre bornée (pas de `readFileSync` d'un fichier de 8,8 Mo sur la boucle du serveur).
- Gardes : généraliser `porteDoing` en `porteInterdit` lisant `interdits` de `interface.json` (au moins `doing`, `mandat`, `messages`, `outils`, `transcript`) ; appliquer au `hello` et à chaque `diffuser` ; la route de transcript n'est jamais appelée par le flux.
- Calcul : la collecte entière (`gather`, ~245 ms, appelle `git`, `bash` x N) tourne pour valider l'identifiant ; extraire une fonction de collecte des seules sessions (sans verrous ni DAG) pour que le clic ne bloque pas la boucle (qui diffuse aussi le SSE).

**R5.4 Fuites à interdire (tests)** : flux SSE (`hello`, `who`, `patch`, `lock`), journal `/api/vf/journal`, fichiers de `.vibeflow/cockpit/` (`project.html`, `equipe.html` s'il est écrit, `graph.json`, `.cache/*`), export `POST /api/export`, `serveur.log`. Gabarit : S5/S7/S8 et DO de `test-cockpit-serveur.sh`, balayage `scan.sh`.

### R6. Les quatre témoins en fixtures et traces rouges (point 6)

Fixtures reproduites hors dépôt (brouillon de recherche) ; lab plat, ROADMAP à deux phases non cochées, jalon `📋`, `STATE.md` `current_phase: 9`, dossier de phase 1 avec 7 `*-PLAN.md` + 7 `*-SUMMARY.md` + 4 `1-FIX-{A..D}-SUMMARY.md`, DAG `{"phase":"1","ws":null,"nodes":[…]}` sous `.planning/missions/` nommé `2026-11-01-v-cockpit`. Sortie **réelle** sur le code actuel (format `verdict | assertion | attendu | obtenu`) :

```
ROUGE | a foot ph-1 | attendu: 7/7 plans · 4 correctifs | obtenu: 11/7 plans
ROUGE | a avancement.plans/correctifs | attendu: [{"faits":7,"total":7},4] | obtenu: undefined
ROUGE | b etat (STATE sur la phase 9) | attendu: a-recetter | obtenu: (avancement absent)
ROUGE | b st carte ph-1 (STATE ailleurs) | attendu: (non-todo : a-recetter se projette en active ou autre) | obtenu: todo
ROUGE | c parent de la mission (champ phase) | attendu: ph-1 | obtenu: missions
ROUGE | d statut du jalon 📋 | attendu: active | obtenu: todo
ROUGE | d pied du jalon | attendu: 0 clos · 1 à recetter · 1 à faire · 0 % | obtenu: 0/2 phases · 0 %
```

Leçon de la première exécution : une fixture mal formée (dossier de phase non créé) a produit `pas de plan` — un rouge **pour la mauvaise raison**. Chaque témoin doit s'accompagner d'un contrôle positif vert (« la fixture contient bien 7 PLAN, 7 SUMMARY et 4 correctifs ») avant l'assertion rouge, et le premier témoin doit porter sur un champ **existant** (`foot` : `11/7`) plutôt que sur une clé absente.

Autres traces rouges déjà reproduites sur le code actuel (équipe) : fixture à trois niveaux (session -> `mgr1` -> `w1`) : `w1.parent` = identifiant de **session** (`parent=aaaa1111-…`) au lieu de `mgr1` (CKPT-19) ; `fin2h` (terminé depuis 2 h) **absent** de la liste, attendu présent et marqué terminé (CKPT-20) ; `sansparent` (`spawnDepth: 2` sans `parentAgentId`) **listé** avec `sources.sessions.etat = lue` et `formeInconnue = 0`, attendu `forme-inconnue` (CKPT-27). `schema` rendu : `vibeflow/cockpit-who@1`, attendu `@2` (CKPT-28).

Pièges de témoin vert par construction (à ne pas écrire seuls) : « sans jeton -> 403 » sur `/api/vf/transcript` est **déjà vert** (le contrôle de jeton précède le routage, `serve.mjs:511`) ; « le secret est absent de `who` » est déjà vert tant que l'action n'existe pas. Toujours apparier un témoin négatif à un témoin positif sur le même chemin (avec jeton -> 200 et marqueur présent ; libellé présent ET secret absent).

**Conservation de la trace rouge** (proposition) : chaque suite imprime nativement `❌ FAIL — <libellé> / attendu: [...] / obtenu: [...]` ; la vague 0 de chaque chantier (a) écrit les suites, (b) enregistre leur sortie rouge dans `69-RED-TRACE.md` (un bloc par exigence : commande, libellé, attendu, obtenu, empreinte du commit de test), (c) committe tests et trace **avant** le code (deux commits distincts). Cette trace doit être citée dans chaque SUMMARY.

### R7. Contrat consommateur de la Phase 68 (point 7)

Le bloc Phase 68 du ROADMAP est « **Non cadrée** » : `Requirements: TBD`, aucune forme de consommation écrite ; ses seules exigences vis-à-vis de la 69 : « Depends on: Phase 69 » et P69-D-10 « la 68 consomme `avancement` ». Le point à cadrer de la 68 demande que `vf-signal` signale un arbre en retard sur `main`, voie la phase active d'un worktree et ne prenne pas une mission aux nœuds jamais refermés pour la mission en cours. [CONFIRMED: ROADMAP.md bloc Phase 68]
Pour que `avancement` v1 reste compatible sans que la 68 soit cadrée : forme exacte de CKPT-13 (`version`, `etat`, `plans:{faits,total}`, `correctifs`, `mission:{nom,etat}`, `reste`) ; `etat` ∈ `a-faire|en-cours|a-recetter|fait` (fermé) ; ajouts de champs seulement (version 1 inchangée), tout retrait ou renommage -> version 2 ; accrocher l'objet à `readPlanning(root, layout).phases.get(key).avancement` (ASSUMED : la 68 importera la lib, qui vit hors du dépôt dans `~/.claude/mods`) ; déclarer le bloc dans `vf-cockpit-interface.json` (états, vocabulaire de `reste`) et le valider par la suite ; `mission` sans DAG rattaché : valeur à fixer (OQ-3). Ne pas faire dépendre `etat` du compartiment actif ni du STATE (c'est tout l'objet de CKPT-18) — la 68 en a besoin pour une phase d'un worktree.

### R8. Portabilité des commandes de test (point 8)

- Lancer les suites avec `bash <suite>` (jamais `sh`), depuis la racine ; `zsh` n'est que le shell interactif de l'exécuteur. Pas de `for x in $var` non découpé : utiliser un fichier de liste et `while IFS= read -r t; do … done < "$LISTE"` (bash 3.2 et zsh), ou une glob (`for t in plugin/cockpit/scripts/tests/test-cockpit-*.sh; do …`) dont les correspondances existent.
- Pas de `timeout`/`gtimeout` (absents de macOS) : les suites bornent leurs attentes par `sleep 0.1` en boucle et par des clients node auto-bornés. Ne pas relayer la sortie d'une suite dans `| head`/`| tail` : un serveur ou Chrome fils garde le tube ouvert (les suites tuent les leurs à la sortie, mais une suite qui échoue tôt…). Rediriger vers un fichier puis lire le fichier. Sous `rtk`, ne pas conclure d'un `| wc -l` (une sortie vide devient une ligne) : `rtk proxy` ou fichier.
- macOS : `sed -i.bak` (BSD) comme les suites existantes ; awk 20200816 refuse un saut de ligne dans `-v` (cf. commentaire de `ci-shard-suites.sh`) ; `mktemp -d` donne `tmp.XXXXXXXX` (la marque de `hygiene.sh`) ; bash 3.2 sans `declare -A`, `mapfile`, `${var,,}` ; `${PIDS[@]+"${PIDS[@]}"}` sous `set -u`.
- Linux CI (ubuntu-latest = 26.04 depuis le 2026-10-19, coreutils uutils [CITED: mémoire projet « CI sous Ubuntu 26 »]) : `ln -sh`/`mv -h` se comportent comme `--help` -> aucune dépendance à ces options dans les suites ou les fixtures ; Chrome présent sur ubuntu-latest (ASSUMED) ; node 24.
- Une suite qui dépend de Chrome doit déclarer « SAUTÉE » (exit 0) sans navigateur : une règle de rendu critique (CKPT-26) doit donc aussi être prouvée **sans navigateur** (extraire la fonction de rendu et l'exécuter dans `vm`, comme F6 pour `__vfFrTraduire`, ou simulation fidèle comme `chaine-xss`), sinon le vert peut être un vert à vide en CI.
- Parallélisme local : au plus 2 suites simultanées (mémoire projet : 7 agents morts ensemble) ; les suites du cockpit lancent serveurs et Chrome.

### R9. Porte de phase : étapes du job `gates` applicables (point 9)

Découverte complète des suites du cockpit (à rejouer) : `bash scripts/ci-shard-suites.sh --all | awk '/plugin\/cockpit\//'` (17 aujourd'hui, + `plugin/_internal/tests/test-vibeflow-update-cockpit.sh` pour l'installation). Les suites ne sont pas dans `gates` mais dans `tests-shard` (R2.1) ; les étapes du job **`Gates de qualité (mode strict)`** (`.github/workflows/ci.yml:393`) qui peuvent rougir sur un changement du cockpit, par nom d'étape exact et commande sur l'arbre réel [CONFIRMED : lignes de `ci.yml`] :

| Étape (nom exact) | Commande sur l'arbre réel | `ci.yml` | Pertinence |
|---|---|---|---|
| check-agents --strict sur chaque plugin/*/agents (découverte non vide) | `bash plugin/conductor/scripts/check-agents.sh --strict --manifest-freshness=strict --agents-dir="$d"` (boucle sur `plugin/*/agents`) | 415 | inchangé si aucun agent touché |
| check-agents --strict sur chaque plugin/*/AGENT.md (module mono-agent) | `… --file "$f"` | 445 | idem |
| check-agents --resolve-agents=strict (monde fermé — union de tous les plugin/*/agents) | `… --resolve-agents=strict … "${registry_args[@]}"` | 473 | idem |
| check-skills (classe d'invocation des skills — POCK-07, étape propre) | `bash plugin/conductor/scripts/check-skills.sh --strict --skills-dir=plugin --callers-root=plugin` | 504 | seulement si `skills/vf-cockpit/SKILL.md` change |
| check-blueprints (le frontmatter cible passe le gate qu'il vise) | `bash plugin/conductor/scripts/check-blueprints.sh` | 569 | inchangé |
| check-version-sync (canon VERSION ↔ plugin.json ↔ marketplace ↔ badges ↔ triade par module) | `bash scripts/check-version-sync.sh` | 572 | **applique** : compte de suites des deux README (`:131-139`), triade `VERSION`/`module.json`/`CHANGELOG` du module si bump (OQ-8) |
| check-state-integrity (anti-régression du frontmatter .planning/STATE.md, ADR-063) | `. plugin/conductor/scripts/fanout-state-integrity.sh` puis `fanout_check_state_integrity "."` | 605, 667 | applique (l'orchestrateur écrit STATE.md) |
| check-capability-activation (une entrée de doc ne promet pas un geste inerte, GSDA-09) | `bash plugin/dev-orchestrator/scripts/check-capability-activation.sh` | 746 | si la doc du module promet un geste |
| check-machine-paths (aucun chemin absolu de machine dans les fichiers versionnés) | `bash scripts/check-machine-paths.sh` | 763 | **applique à ce fichier et aux fixtures** : jamais `/Users/<nom>/` ni `/home/<nom>/` dans un test, un plan ou un SUMMARY (compte placeholder, `<user>` ou marqueur `vf-allow-machine-path`) |
| check-python-isolation (aucune invocation inline de Python non isolée — hotfix H-1) | `bash scripts/check-python-isolation.sh --min-sites 40` | 773 | sans objet (pas de Python) |
| check-instruction-budget (BUDG-01/02/04/05, ADR-029 machine-enforced) | `bash plugin/conductor/scripts/check-instruction-budget.sh` (arbre réel) | 916 | sans objet (agents seulement) |
| Gates workstream-aware sur un arbre RÉELLEMENT partitionné (fixture jetable) + non-régression racine | `check-dev-bootstrap.sh --path .`, `check-workstream-pointer.sh --path .` | 1223, 1329 | planning |
| check-divergence.sh en CI (C17, 2026-09-10) — mutation rouge sur fixture divergente, pas seulement présence du gate | `bash plugin/conductor/scripts/check-divergence.sh --path .` | 1448 | planning (dossiers de phase vs ROADMAP) |
| check-planning-consumers-registered (D-03 — un consommateur de chemin de planning oublié est VU) | `bash plugin/conductor/scripts/check-planning-consumers-registered.sh` (arbre réel : `bash "$GATE"`) | 1523 | ne balaie que les `*.sh` hors `tests/` ; le `.mjs` du cockpit n'est pas visé |
| check-baseline-arbitrage (G-1, PROT-04 — hausse de baseline sans arbitrage cité) | `bash scripts/check-baseline-arbitrage.sh` | 1700 | sans objet si la baseline n'est pas touchée |
| check-gate-touche (G-2, PROT-05 — la PR modifie ce qui la juge) | `bash scripts/check-gate-touche.sh` | 1818 | sans objet si ni gate, ni `ci.yml`, ni hook, ni fixtures `plugin/conductor/scripts/tests/fixtures`/`scripts/tests/fixtures` touchés |
| check-ajout-retrait (SOBR-05, consultatif — un ajout à la méthode dit ce qu'il retire) | `bash plugin/conductor/scripts/check-ajout-retrait.sh --ci` | 1847 | consultatif ; SKILL.md de plugin/ surveillés |
| check-affirmation-non-mesuree (G-4 — affirmation de prose non mesurée) | `bash scripts/check-affirmation-non-mesuree.sh` | 1946 | consultatif ; ne pas affirmer au présent une protection serveur non mesurée |
| check-manual (cohérence du manuel utilisateur FR+EN — manual/.tools/check-manual.sh) | `bash manual/.tools/check-manual.sh` | 1968 | si le manuel (`manual/{fr,en}/…/catalogue`, `skills`) décrit les onglets |
| check-push-sans-pr (G-3 …) / check-release-tag (main uniquement …) | `bash scripts/check-push-sans-pr.sh …` ; `bash scripts/check-release-tag.sh --remote` | 2048, 2079 | `main` seulement ; la release est un geste humain |

Règle de la mémoire projet appliquée : la porte du dernier plan **rejoue les commandes de `ci.yml`**, jamais la liste de ce tableau. Les blocs de bascule sur fixtures de chaque étape se rejouent en extrayant les `run:` de l'étape.

### R10 : voir « Validation Architecture » ci-dessous.

## Common Pitfalls

### Pitfall 1: plafond de 300 lignes par fichier
**What goes wrong:** `test-cockpit-vendor.sh` V4 compte les lignes de chaque `scripts/*.mjs` et de chaque `AJOUT` JS ; au-delà de 300, rouge (et `check-file-size.sh` avertit dès 250). `vf-cockpit-who.mjs` fait déjà 239 lignes très longues, `vf-cockpit-planning.mjs` 120, `70-vf-live.js` 161.
**Why it happens:** les lignes du module sont denses ; ajouter arbre + action + jointure + transcript dans `who.mjs` dépasse vite 300.
**How to avoid:** nouveaux modules (`avancement`, `equipe`, `transcript`) ; nouveaux fichiers d'interface `ui/7x-*.js`, déclarés `AJOUT` dans `VENDORED.txt` (V7 vérifie leur présence) et commençant par `// VibeFlow (` (sinon l'inventaire FR les lit).
**Warning signs:** `trop long : <fichier>` dans la sortie de V4.

### Pitfall 2: le nombre de suites est vérifié contre les README
**What goes wrong:** `check-version-sync.sh` (l. 131-139) rougit si le premier « N suites » de `README.md` ou `README.fr.md` diffère du nombre de `*/tests/test-*.sh` (142 aujourd'hui, mesuré vert).
**How to avoid:** mettre à jour les deux README dans le plan qui ajoute des suites ; rejouer `bash scripts/check-version-sync.sh`.

### Pitfall 3: le cockpit installé exécute la copie dans `.vibeflow/cockpit/`
**What goes wrong:** le serveur importe `vf-cockpit-server.mjs` et ses voisins depuis la sortie ; un module hors motif `vf-cockpit-*.mjs` n'y est pas copié.
**How to avoid:** nommer tout module d'exécution `vf-cockpit-<x>.mjs`, prouver par `fichiersExecution(<scripts réels>)`.

### Pitfall 4: tests qui changent de sens par conception
**What goes wrong:** retirer la règle STATE rend P1.1/P1.2/P1.5 faux ; réécrire l'attendu sans le dire ressemble à « supprimer pour verdir ».
**How to avoid:** changer l'assertion dans le commit du retrait, avec la raison (CKPT-18) ; ajouter le témoin (b) rouge avant.

### Pitfall 5: `a-recetter` n'est pas un statut du viewer
**What goes wrong:** la pastille affiche la chaîne brute (`viewer.html:932`), la couleur manque, les questions locales (`ST` de `ask.mjs:9`) répondent « sans statut », « Prochaines phases » écrit « À faire » (`00-vibeflow.js:82`).
**How to avoid:** décider de la projection (OQ-1) avant de coder ; si un statut hors des quatre est retenu, patcher `viewer.html` (nouveau patch P-n, diff régénéré par `synchro.sh regenerer-patch`), `ask.mjs`, `interface.json`, `00-vibeflow.js`.

### Pitfall 6: `reste` ne doit rien lire d'externe
**What goes wrong:** une idée « utile » (dernier tag, état d'une PR) viole P69-D-09/CKPT-17.
**How to avoid:** n'ouvrir que `<dossier de phase>/*`, `ROADMAP`, éventuellement un tag local pour « à voir plus tard » ; test qui interdit tout `fetch`/`http` (le témoin réseau de CKPT-03 est à rejouer).

### Pitfall 7: `finished` et `parentAgentId` ne sont pas toujours là
**What goes wrong:** exiger `finished` ou `parentAgentId` (R5.1) classerait tout agent actif et tout manager en `forme-inconnue` : un arbre vide en usage réel, alors que la fixture « conforme » de la suite serait verte.
**How to avoid:** `finished` facultatif ; `parentAgentId` requis seulement à `spawnDepth >= 2` ; une fixture **réelle** (copie réduite et anonymisée d'un `meta.json` actif et d'un manager) parmi les fixtures conformes.

### Pitfall 8: agents en double et profondeurs qui divergent
**What goes wrong:** un agent apparaît comme `subagent` et comme `registered` (même `agent_id`) ; la profondeur du registre ≠ `spawnDepth`.
**How to avoid:** fusionner par identifiant ; l'arbre se bâtit sur `meta.json` (`parentAgentId`, `spawnDepth`) ; le registre ne sert qu'au nœud.

### Pitfall 9: parents silencieux disparus de l'arbre
**What goes wrong:** `sAge >= fresh` écarte tout agent sans écriture depuis 180 s, y compris un manager qui attend ses workers ; l'enfant actif se retrouve sans parent. La session racine n'est pas poussée si elle est calme (l. 98).
**How to avoid:** fermer l'arbre par ses ancêtres (tout agent actif ramène sa chaîne `parentAgentId` jusqu'à la session, marquée « en attente » plutôt que supprimée) ; synthétiser la racine session depuis `parent` quand elle est calme.

### Pitfall 10: découverte de DAG incohérente et identifiants non uniques
**What goes wrong:** `who` ne voit pas les DAG de `.planning/workstreams/<ws>/` (le nœud `plan-69` en cours est invisible dans `dag-node`) ; des identifiants comme `docs` lient n'importe quoi.
**How to avoid:** un seul index de nœuds construit depuis `readPlanning().dags` (qui couvre les compartiments) ∪ les DAG de `vf-driver` ; lien uniquement si l'identifiant se résout à un seul DAG ; sinon « non rattaché (ambigu) » ; test avec `docs` présent dans deux DAG.

### Pitfall 11: le viewer ne sait pas ajouter une carte en direct
**What goes wrong:** un agent nouveau ne s'affiche pas tant que la page n'est pas rechargée (`nodes`/`files` construits une fois, `viewer.html:696-697`) ; un rechargement à chaque apparition d'agent est pénible.
**How to avoid:** patcher en place `st`/`foot` pour les changements d'état ; recharger (hash conservé) uniquement quand l'ensemble des identifiants change, avec une anti-rafale ; faire d'abord un mini-spike « page Équipe qui reçoit un `who` et se met à jour » (vague 0 de l'interface) ; sinon l'onglet reste statique avec un bouton d'actualisation (à arbitrer, OQ-2).

### Pitfall 12: la dernière action peut fuir un secret ou un chemin
**What goes wrong:** « lit X » avec X = chemin hors du lab ; « lance … » avec l'argument de la commande ; `description` de Bash écrite par le modèle.
**How to avoid:** table fermée de verbes ; chemin relatif au lab sinon « un fichier hors du lab » ; hôte seul pour `WebFetch` ; pas de `command` ; `masque()` + borne sur tout texte libre ; test avec un secret factice dans `command`, dans `file_path` hors lab et dans `url`.

### Pitfall 13: le réducteur de transcript est une liste blanche
**What goes wrong:** les sorties d'outils sont dans `tool_result`, dans `toolUseResult` (champ de tête) **et** dans les lignes `api-request-blob`.
**How to avoid:** ne retenir que : première ligne `user` à contenu chaîne (mandat), blocs `assistant` de type `text`, noms d'outils des blocs `tool_use` ; ignorer tout autre type de ligne et de bloc (y compris `thinking`) ; test dont la fixture met un marqueur dans chacun de ces emplacements (sortie d'outil, `toolUseResult`, blob, fichier lu) et exige 0 occurrence dans la réponse.

### Pitfall 14: témoins verts par construction
**What goes wrong:** « sans jeton -> refus » sur une route neuve est vert avant tout code ; « secret absent » est vert avant l'existence du libellé.
**How to avoid:** apparier témoin négatif et témoin positif sur le même chemin ; écrire le rouge attendu *avant* (R6).

### Pitfall 15: rendu texte, mais testé à côté de l'image du logo
**What goes wrong:** « aucun nœud `img` créé » : le logo `header .brand .mark` est une `img` légitime ; compter les `img` du document donne toujours 1.
**How to avoid:** compter dans le conteneur du transcript/de l'équipe ; contrôler `textContent` égal à la source ; comparer l'en-tête CSP **modulo les empreintes** (les directives, pas les `sha256-`).

### Pitfall 16: secrets en texte libre dans mandats et messages
**What goes wrong:** les masques (`ghp_`, `sk-`, `NOM=valeur`…) ne couvrent pas un `mot de passe : hunter2` en prose ; `masque()` coupe à 4 000 caractères.
**How to avoid:** affichage local, authentifié, à la demande, jamais persisté ni exporté ; appliquer `masque()` en best effort et le dire dans la doc du module (limite connue) ; arbitrage de Samuel (OQ-9).

### Pitfall 17: coût de la collecte toutes les 5 s
**What goes wrong:** `collectWho` pèse ~245 ms synchrone ; ajouter lecture d'ouverture/queue de chaque transcript terminé < 24 h (40 par session) l'alourdit.
**How to avoid:** `stat` avant de lire ; cache par `(chemin, mtime, taille)` pour les agents terminés ; lire un transcript seulement pour les agents actifs (dernière action) ; mesurer (`collectWho` ≤ ~500 ms sur la fixture de 40 agents).

## Code Examples

### Décompte des plans et correctifs (esquisse, ASSUMED)
```js
// vf-cockpit-avancement.mjs — module pur ; les noms sont ceux de CKPT-13 / P69-D-02
export function decompte(fichiers) {            // fichiers = noms du dossier de phase
  const plans = new Set(fichiers.filter((f) => /-PLAN\.md$/.test(f)).map((f) => f.replace(/-PLAN\.md$/, '')));
  const sums = new Set(fichiers.filter((f) => /-SUMMARY\.md$/.test(f)).map((f) => f.replace(/-SUMMARY\.md$/, '')));
  const faits = [...plans].filter((p) => sums.has(p)).length;
  const correctifs = [...sums].filter((s) => !plans.has(s)).length;   // SUMMARY sans PLAN
  return { plans: { faits, total: plans.size }, correctifs };
}
// etat : fait (ph.done) > a-recetter (total>0 && faits===total) > en-cours (faits>0 || mission running) > a-faire
```
Ordre d'évaluation à confirmer en test : une phase cochée est `fait` quelle que soit la mission ; une mission `running` sur une phase sans plan fait donne `en-cours` (cas réel : phase 69 elle-même, `MISSION-69`, nœud `plan-69`).

### Réducteur de transcript à liste blanche (esquisse, ASSUMED)
```js
// Source : formes mesurées en R5.1 — jamais les types api-request-blob / attachment / tool_result / toolUseResult / thinking
for (const ligne of lignes) {
  const d = parse(ligne); if (!d) continue;
  if (d.type === 'user' && premiereLigne && typeof d.message?.content === 'string') mandat = d.message.content;
  else if (d.type === 'assistant' && Array.isArray(d.message?.content))
    for (const b of d.message.content) {
      if (b.type === 'text') messages.push(b.text);
      else if (b.type === 'tool_use') outils.push(etiquette(b.name, b.input));   // verbe + cible, jamais input.command
    }
}
```

### Fixture du témoin (a), style des suites (extrait)
```bash
wr() { mkdir -p "$(dirname "$1")"; cat > "$1"; }
D="$B/phases/01-cockpit"; mkdir -p "$D"
for i in 01 02 03 04 05 06 07; do printf '<objective>Plan %s</objective>\n' "$i" > "$D/1-$i-PLAN.md"; echo ok > "$D/1-$i-SUMMARY.md"; done
for x in A B C D; do echo ok > "$D/1-FIX-$x-SUMMARY.md"; done      # correctifs : SUMMARY sans PLAN
assert_eq "A0 — fixture bien formée (7 PLAN, 11 SUMMARY)" "$(ls "$D" | grep -c PLAN)/$(ls "$D" | grep -c SUMMARY)" "7/11"
assert_eq "A1 — pied de phase" "$(G "$WORK/g.json" 'j.nodes.find(n=>n.id==="ph-1").foot')" "7/7 plans · 4 correctifs"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Statut de phase = case cochée ∨ `current_phase` du STATE | Statut dérivé de traces locales (`avancement`) | Phase 69 | Le STATE ne ment plus sur la carte |
| Liste plate des sous-agents, `finished` écarté | Arbre `parentAgentId`/`spawnDepth`, fenêtre 24 h | Phase 69 | Lecture du travail en cours par rôle |
| Dernière commande Bash seule, à la demande | + dernière action de tout outil (verbe, cible) dans la collecte ; transcript réduit à la demande | Phase 69 | Nouvelle surface d'information : voir Security Domain |
| Format Claude Code vérifié sur 2.1.316 | Mesuré sur 2.1.317 (`claude --version`, champ `version` des lignes) | 2026-11-03 | `verifieSur` à mettre à jour |

**Deprecated/outdated:** la liste `attendus`/`drapeauFin`/`verifieSur` de `interface.json` est décorative tant qu'aucun code ne la lit (R2.4).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Chrome est préinstallé sur le runner ubuntu-latest | Standard Stack, R8 | Les suites de rendu sont sautées en CI : preuve à vide si seul le navigateur prouve CKPT-23/26 -> prévoir la preuve sans navigateur |
| A2 | La date de fin d'un agent terminé = `mtime` de son `.jsonl` (le `meta.json` n'a aucune date) | R5.1, CKPT-20 | Fenêtre de 24 h décalée si Claude Code réécrit le fichier après `finished` |
| A3 | L'`agent_id` du registre égale toujours l'identifiant de fichier de Claude Code (vérifié sur 2 entrées) | R4.1 | Lien registre -> agent manqué ; vérifier par test sur un registre réel |
| A4 | Un message de suivi envoyé à un agent (SendMessage) n'est pas une ligne `user` à contenu chaîne en tête de fichier | R5.1 | Le « mandat » serait pris pour un message ultérieur ; ne retenir que la **première** ligne |
| A5 | Le format observé (2.1.317) vaut pour 2.1.316 et les versions voisines | R3 | `forme-inconnue` à tort ou arbre faux après une mise à jour de Claude Code ; c'est justement l'objet du test de forme |
| A6 | `readPlanning(...).phases.get(key).avancement` est le point d'accès que la 68 utilisera | R7 | La 68 devra adapter son import ; cadrage 68 non écrit |
| A7 | Ligne de statut de `*-RECETTE-HUMAINE.md` : `**Statut : FAITE …**` (un seul fichier de ce nom connu) | R4.4 | `reste` mal calculé si d'autres phases écrivent le statut autrement |
| A8 | Le nom `vibeflow/cockpit-who@2` et un schéma `vibeflow/cockpit-transcript@1` | R5.3, CKPT-28 | Aucun consommateur externe n'existe encore : coût de renommage faible |
| A9 | Table de verbes par outil (R5.2) | R5.2 | Libellés à valider par Samuel (D-16 fixe seulement « verbe + cible ») |
| A10 | Un seul `DAG` candidat suffit à lier ; deux candidats = « non rattaché » | R4.2 | Lecture de « jamais deviné » : OQ-5 |

## Open Questions for Samuel

(Aucune n'est tranchée par la recherche ; chacune a une recommandation, qui n'est pas une décision.)

1. **OQ-1 — Comment `a-recetter` s'affiche-t-il sur une carte ?** (vocabulaire du viewer : `done|active|todo|blocked`).
   - Savoir : un `st` hors de ces quatre valeurs s'affiche brut et sans couleur ; « Prochaines phases » écrit « À faire » en dur ; les questions locales disent « sans statut ».
   - Options : (a) `st:"active"` + mot « à recetter » dans le pied (aucun patch du viewer, mais l'état exact n'est dans aucun champ typé) ; (b) cinquième statut `a-recetter` avec patch vendorisé de `viewer.html` (pastille, couleur) + `ask.mjs` + `interface.json`.
   - Recommandation : (b) si le critère de succès 1 (« l'état « à recetter » ») doit être visible comme état et non comme texte ; (a) sinon. Coût de (b) : un patch P24 de `viewer.html`.
2. **OQ-2 — Mécanisme du troisième onglet « en carte ».** Une vraie page `equipe.html` exige un nouveau patch vendorisé de `serve.mjs` (route + CSP à empreintes + jeton, P24) et se met à jour par rechargement quand un agent apparaît ; une vue plein écran interne à `project.html` évite le patch mais n'est plus « une carte comme Code et Projet ». Recommandation : page `equipe.html` servie en mémoire (jamais écrite sur disque), spike de mise à jour en direct en vague 0.
3. **OQ-3 — Détails de `avancement` non couverts par P69-D-02/D-06.** (i) valeur de `mission` quand aucun DAG n'est rattaché (`null` ?) ; (ii) vocabulaire de `reste` : libellés français comme dans la note (`"recette humaine"`, `"clôture"`) ou codes stables (`recette`, `verification`, `cloture`) — la 68 consommera ce contrat ; (iii) pied de jalon avec des phases `en-cours` (D-06 cite trois compteurs : « 0 clos · 1 à recetter · 1 à faire · 0 % ») : où compter « en cours » ? Recommandation : `null`, codes stables avec libellés dérivés, quatre compteurs affichés seulement s'ils sont non nuls.
4. **OQ-4 — Lien registre -> agent terminé.** Le verbe `orphans` ne rend que les agents `running`. Pour un agent terminé depuis < 24 h, soit on n'utilise que la citation dans le mandat (D-15, source 2), soit on lit aussi le fichier du registre, soit on ajoute un verbe de lecture à `driver-lock.sh` (déclenche `tests-mutants`, ~17 min, et sort du « lecture seule »). Recommandation : première option.
5. **OQ-5 — « Jamais deviné » et identifiants de nœud répétés.** Des identifiants comme `docs` existent dans 22 DAG. Confirmer qu'un nom présent dans plusieurs DAG candidats donne « non rattaché (ambigu) » et qu'une citation de mandat doit être structurée (« Nœud `x` », `--node=x`) plutôt qu'un mot trouvé n'importe où.
6. **OQ-6 — Statut d'un plan non fait dans une phase `en-cours`.** Aujourd'hui `active` pour tous (conséquence de la règle STATE). Recommandation : `todo` sauf si un nœud de mission `running` désigne ce plan ; à confirmer (P1.2 change).
7. **OQ-7 — Libellé de la dernière action de `Bash`.** « lance une commande » seulement, ou la `description` que l'agent écrit lui-même (texte libre masqué et borné) ? D-16 interdit « l'argument d'une commande », pas la description.
8. **OQ-8 — Version du module et release.** La phase modifie le comportement du module `cockpit` (v1.0.0 aujourd'hui) : bump `v1.1.0` (triade `VERSION`, `module.json`, `CHANGELOG`) dans les plans, ou à la release ? Rappel CLAUDE.md : la release racine est un geste humain, jamais planifié ici.
9. **OQ-9 — Risque accepté des secrets en prose.** Le transcript montre mandats et messages ; les masques sont best effort ; le jeton de la page est lisible par tout processus local (M7, accepté en Phase 67). Confirmer que ce niveau de risque est accepté pour cet affichage local à la demande.
10. **OQ-10 — Règle (3) de D-05 (DAG dans un dossier de phase).** Aucun DAG ne vit sous `phases/` aujourd'hui : l'implémenter par fixture seulement, ou la différer ?

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | cockpit, suites | ✓ | 26.5.0 (CI 24) | — |
| bash | suites | ✓ | 3.2.57 (macOS) | — (écrire pour 3.2) |
| git | `readPlanning` (tags), worktree list | ✓ | présent | — |
| jq | quelques suites / CI | ✓ | présent | — |
| python3 | CI (dépendances) | ✓ | 3.14 local | sans objet pour le cockpit |
| Google Chrome (headless, CDP) | suites de rendu/responsive/reconnexion/W16 | ✓ local | application macOS | suite « SAUTÉE » sans navigateur (preuve sans navigateur à prévoir) |
| `claude` CLI | non requis (faux binaires dans les suites) | ✓ | 2.1.317 | — |
| `ps` (procps / BSD) | `hygiene.sh` | ✓ | BSD local ; procps CI | `hygiene.sh` refuse (H-0) si `ps` inutilisable |
| `timeout`/`gtimeout` | — | ✗ (macOS) | — | ne pas utiliser ; attentes bornées par `sleep 0.1` |

**Missing dependencies with no fallback:** aucune.
**Missing dependencies with fallback:** Chrome en CI (ASSUMED présent) ; `timeout` absent par conception.

## Validation Architecture

Activé : `workflow.nyquist_validation: true` (`.planning/workstreams/fiabilite/config.json`). [CONFIRMED]

### Test Framework

| Property | Value |
|----------|-------|
| Framework | suites bash maison (`assert_eq`/`assert_has`/`assert_ge`), sondes node écrites par la suite, `hygiene.sh` |
| Config file | aucun ; découverte par `find plugin scripts -path '*/tests/test-*.sh'` |
| Quick run command | `bash plugin/cockpit/scripts/tests/test-cockpit-<suite>.sh` |
| Full suite command | `bash scripts/ci-shard-suites.sh --all \| awk '/plugin\/cockpit\//' > "$TMP/liste"` puis `while IFS= read -r t; do bash "$t" </dev/null > "$TMP/out" 2>&1; echo "rc=$? $t"; done < "$TMP/liste"` (séquentiel ; + `bash plugin/_internal/tests/test-vibeflow-update-cockpit.sh`) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | Direction d'échec (ce qui doit rougir) | Témoin rouge avant code (observé / attendu) | File Exists? |
|--------|----------|-----------|-------------------|----------------------------------------|----------------------------------------------|--------------|
| CKPT-13 | `avancement` v1, 4 états | unit (lab jetable) | `bash …/test-cockpit-avancement.sh` | `etat` ≠ attendu ; clé absente | (b) `(avancement absent)` / `a-recetter` ; mutation : copie de `project.mjs` avec `ph.n === curPhase` -> (b) rouge | ❌ Wave 0 |
| CKPT-14 | décompte plans / correctifs | unit | idem | `foot` ≠ `7/7 plans · 4 correctifs` ; correctifs ≠ 4 | (a) `11/7 plans` / `7/7 plans · 4 correctifs` | ❌ Wave 0 |
| CKPT-15 | rattachement mission (3 règles) | unit | idem | parent ≠ `ph-N` ; DAG resté sous `missions` | (c) `missions` / `ph-1` ; règle (2) : `MISSION-<n>` (vert déjà : contrôle positif) ; règle (3) fixture DAG dans le dossier de phase | ❌ Wave 0 |
| CKPT-16 | jalon `en-cours`, pied, % strict | unit | idem | `ms.st` ≠ `active` ; pied ≠ format | (d) `todo` / `active` ; `0/2 phases · 0 %` / `0 clos · 1 à recetter · 1 à faire · 0 %` ; % jamais pondéré (phase 7/7 non cochée -> 0 %) | ❌ Wave 0 |
| CKPT-17 | `reste` local, aucun réseau | unit + réseau | idem + `bash …/test-cockpit-reseau.sh` | `reste` ≠ liste attendue ; toute connexion sortante | `reste` absent / `[…]` ; sonde réseau de R1 rejouée sur le serveur de la phase | ❌ Wave 0 (réseau ✅) |
| CKPT-18 | règle STATE retirée | mutation | idem | témoin (b) vert sur le module muté ⇒ la suite est aveugle | (b) rouge ; P1.1/P1.2/P1.5 réécrits dans le même commit | ✅ (P1 à modifier) + ❌ |
| CKPT-19 | arbre à trois niveaux | unit (HOME jetable) | `bash …/test-cockpit-equipe.sh` | `parent` d'un worker ≠ son manager ; profondeur ≠ `spawnDepth` | `w1.parent = <session>` / `mgr1` | ❌ Wave 0 |
| CKPT-20 | actifs + terminés < 24 h | unit | idem | `fin2h` absent ou non marqué terminé ; `fin25h` présent | `fin2h` absent / présent+terminé | ❌ Wave 0 |
| CKPT-21 | lien agent <-> nœud, jamais deviné | unit + DOM | idem | lien posé sans citation, ou absent avec citation valide ; `docs` ambigu lié | aucun lien / lien `revue-p3` ; contrôles : nom inconnu -> aucun lien, nom dans 2 DAG -> « ambigu » | ❌ Wave 0 |
| CKPT-22 | dernière action sans argument | unit + flux | idem | secret ou chemin hors lab dans `who` ou le flux | libellé absent / présent ET secret absent (apparier) | ❌ Wave 0 |
| CKPT-23 | onglet « Équipe », FR | assemblage + sonde de libellés | idem | onglet absent ; libellé anglais | pas de lien `equipe.html` / présent ; sonde : chaîne anglaise injectée -> rouge | ❌ Wave 0 |
| CKPT-24 | transcript réduit | serveur + fixture à marqueurs | `bash …/test-cockpit-transcript.sh` | marqueur de sortie/`toolUseResult`/blob/fichier lu dans la réponse | route 404 / 200 avec mandat+messages+outils ; 0 marqueur | ❌ Wave 0 |
| CKPT-25 | endpoint authentifié, jamais SSE/fichiers/export | serveur | idem (+ S5/S7/S8 en gabarit) | 200 sans jeton ; id `../` accepté ; marqueur dans flux, `.vibeflow/cockpit/`, export | avec jeton : 404 / 200 ; « sans jeton 403 » déjà vert (apparier) | ❌ Wave 0 |
| CKPT-26 | rendu texte, CSP inchangée | DOM (`vm` + Chrome) | idem | `img` créé dans le conteneur ; CSP différente (hors empreintes) | rendu absent / texte égal à la source | ❌ Wave 0 |
| CKPT-27 | forme étendue | unit (fixtures amputées par champ) | `bash …/test-cockpit-forme-claude.sh` | champ disparu sans `forme-inconnue` ; fixture réelle (actif, manager) classée inconnue à tort | `sansparent` listé, `lue`, `formeInconnue=0` / `forme-inconnue` | ❌ Wave 0 |
| CKPT-28 | schéma qui monte, réseau | unit + réseau | `…/test-cockpit-equipe.sh` + `test-cockpit-reseau.sh` | schéma ≠ `who@2` ; connexion sortante | `who@1` / `who@2` | ✅ (réseau) + ❌ |

### Sampling Rate
- **Per task commit:** la suite de l'exigence touchée (`bash …/test-cockpit-<x>.sh`), 20 à 60 s chacune (projet : 21 s mesurés).
- **Per wave merge:** toutes les suites du cockpit + `test-vibeflow-update-cockpit.sh`, séquentiel (au plus 2 en parallèle).
- **Phase gate:** découverte complète des suites + étapes de R9 rejouées depuis `ci.yml`, avant `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `plugin/cockpit/scripts/tests/test-cockpit-avancement.sh` — CKPT-13..18 (labs a-d + mutation)
- [ ] `plugin/cockpit/scripts/tests/test-cockpit-equipe.sh` — CKPT-19..22, 23 (sonde), 28
- [ ] `plugin/cockpit/scripts/tests/test-cockpit-forme-claude.sh` — CKPT-27 (fixtures conformes issues de formes réelles)
- [ ] `plugin/cockpit/scripts/tests/test-cockpit-transcript.sh` — CKPT-24..26
- [ ] `69-RED-TRACE.md` — sortie rouge de chaque suite avant le code (commit de tests distinct)
- [ ] Mise à jour de `README.md` et `README.fr.md` (compte de suites) dans le plan qui ajoute les suites
- [ ] Framework : aucune installation

## Security Domain

Activé : `security_enforcement: true`, `security_asvs_level: 1`, `security_block_on: high`. [CONFIRMED: config du compartiment]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | non (pas de compte) | jeton de session de page existant |
| V3 Session Management | oui, hérité | `token`/`ptoken` aléatoires (`crypto.randomBytes`), `server.json` en 0600 |
| V4 Access Control | oui | contrôle du Host + même origine + `x-floorplan-token` avant tout `/api/*` (`serve.mjs:505-511`) |
| V5 Input Validation | oui | `ID_RE`, appartenance à une collecte fraîche, citations de nœud bornées, comparaisons par égalité (pas de RegExp issue du lab) |
| V6 Cryptography | non (aucune nouvelle primitive) | — |
| V7 Error Handling & Logging | oui | ne jamais journaliser un transcript ; erreurs nommées sans contenu |
| V8 Data Protection | oui | `no-store`, à la demande, jamais persisté ni exporté, jamais dans SSE |
| V12 Files | oui | chemin de transcript issu de la collecte uniquement ; aucune écriture de transcript ; `lstat` des liens symboliques de `~/.claude` (ASSUMED : faible) |
| V13 API | oui | GET seul, JSON, bornes de taille |
| V14 Configuration | oui | CSP à empreintes inchangée ; pas de `unsafe-inline` pour les scripts |

### Known Threat Patterns for ce module (identifiants proposés, ASSUMED)

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| T-69-01 Fuite du transcript dans SSE / fichiers générés / export | Information disclosure | garde d'émission généralisée (`interdits` du contrat), route à la demande seulement, balayage des fichiers et de l'export (gabarit S5/S7/S8, DO) |
| T-69-02 Traversée par l'identifiant d'agent ou le slug | Tampering | `ID_RE` + présence dans la collecte ; le chemin vient du disque, jamais de la requête ; `Map` pour les index |
| T-69-03 XSS stockée par description/mandat/message/étape de DAG/champ `phase` du lab | Tampering / EoP | `h()` ou `textContent` seulement, jamais `md()` ; CSP à empreintes ; test `<img src=x onerror=…>` |
| T-69-04 DNS rebinding / CSRF sur la route neuve | Spoofing | Host strict + même origine + jeton en en-tête, hérités ; apparier un témoin positif |
| T-69-05 Jeton lisible par tout processus local (M7) | Information disclosure | accepté en Phase 67 ; plus lourd ici (transcripts) : OQ-9 |
| T-69-06 Déni de service : transcript de 8,8 Mo, 40 agents, collecte synchrone toutes les 5 s | DoS | bornes de lecture, cache `mtime`, collecte des sessions seules pour le clic |
| T-69-07 Secret en prose dans mandat/message | Information disclosure | `masque()` best effort + limite documentée |
| T-69-08 Lab non fiable (DAG, meta, noms de fichiers de phase) qui pilote le rattachement ou l'affichage | Tampering | égalité sur `Set`, pas de RegExp d'identifiants du lab, chaînes d'affichage échappées, noms de fichiers de `reste` jamais interprétés |
| T-69-09 Pollution de prototype par identifiants (`constructor`, `__proto__`) | Tampering | `Map`/`Object.create(null)` pour toute table indexée par identifiant d'agent, de nœud ou de fichier |

## Sources

### Primary (HIGH confidence) — lus dans ce worktree
- `plugin/cockpit/scripts/vf-cockpit-project.mjs`, `-planning.mjs`, `-who.mjs`, `-server.mjs`, `-live.mjs`, `-build.mjs`, `-paths.mjs`, `-interface.json`, `-ask.mjs` (en-têtes et lignes citées)
- `plugin/cockpit/skills/cockpit-moteur/assets/serve.mjs`, `viewer.html` (l. 696-697, 932, 2335-2382), `ui/00-vibeflow.js`, `ui/70-vf-live.js`, `VENDORED.txt`, `amont/SYNCHRO.md`, `amont/synchro.sh`
- `plugin/cockpit/scripts/tests/*` (17 suites + `hygiene.sh`, `chrome-cdp.mjs`)
- `plugin/conductor/scripts/driver-lock.sh` (en-tête, `register`, `close`, `orphans`, `registry_fold`), `dag.sh` (statuts)
- `.github/workflows/ci.yml` (jobs `tests-shard`, `tests`, `gates`), `scripts/ci-shard-suites.sh`, `scripts/check-version-sync.sh`, `scripts/check-gate-touche.sh`, `scripts/check-machine-paths.sh`
- `69-CONTEXT.md`, `REQUIREMENTS.md` (CKPT-01, 13-28), `ROADMAP.md` (blocs 68-69), `STATE.md`, `.planning/notes/2026-11-03-cockpit-progression-en-cours.md`, `67-RECETTE-HUMAINE.md`, `67-SECURITY.md`
- Mesures locales : structure (clés et types, jamais contenu) de 40 sous-agents et tailles de 516 transcripts sous `~/.claude/projects` ; registre `vf-driver/ws/fiabilite/DRIVER.lock.children.jsonl` ; `collectWho` et `buildProjectGraph` exécutés sur le worktree ; `test-cockpit-projet.sh` (35 PASS) et `check-version-sync.sh` (vert) exécutés

### Secondary (MEDIUM confidence)
- Mémoire projet (`MEMORY.md`) : uutils sous ubuntu 26, parallélisme à 2, `rtk`, incident `hygiene.sh`

### Tertiary (LOW confidence)
- Aucune source web : la phase ne dépend d'aucune bibliothèque ni documentation externe (la recherche par `research-plan`/`context7` n'a pas été utilisée, faute de question de bibliothèque)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — aucun paquet ; outillage relevé.
- Architecture: HIGH pour l'avancement et le collecteur (code lu, témoins reproduits) ; MEDIUM pour la page Équipe en direct (limite du viewer mesurée, spike recommandé).
- Pitfalls: HIGH — chacun relié à une ligne de code, une mesure ou une sortie réelle.

**Research date:** 2026-11-03
**Valid until:** 2026-11-17 (le format de Claude Code et le moteur gsd-core bougent vite ; rejouer la mesure du format avant l'exécution si Claude Code a changé de version)
