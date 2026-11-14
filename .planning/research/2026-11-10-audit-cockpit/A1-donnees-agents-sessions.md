# A1 — Chaîne de données « agents et sessions en cours »

> Annexe de `.planning/research/2026-11-10-audit-cockpit-etude.md`. Rapport brut de l'agent d'audit des données. Rendu le 2026-11-10 sur `release/v2.77.0` (cockpit v1.4.0 et retours du panel non publiés). Texte de l'agent, chemins ramenés à la racine du dépôt. Les identifiants de suivi (`AUDC-…`) et la destination de chaque constat sont dans `REGISTRE.md`.

---

# Audit — chaîne « agents et sessions en cours »

Lecture seule, rien modifié. Préfixes : `R/` = racine du dépôt ; `S/` = `R/plugin/cockpit/scripts/vf-cockpit-` ; `U/` = `R/plugin/cockpit/skills/cockpit-moteur/assets/ui/`. **[V]** = vérifié (code lu, mesure ou sonde exécutée), **[I]** = inféré.

Matière mesurée : 63 sessions (193 Mo) et 1 005 transcripts de sous-agents (2,42 Go) de ce dépôt. J'ai aussi fait tourner le collecteur réel sur un HOME factice, avec témoin positif.

## 1. Modèle de données actuel

| Affiché | Source | Preuve |
|---|---|---|
| Sessions et sous-agents | balayage de **tous** les `~/.claude/projects/*` (140 dossiers, 213 sessions, 1 587 `meta.json` par tour), puis filtre `cwd` ∈ `git worktree list` | `S/equipe.mjs:35-57`, `S/who.mjs:59-65` |
| État | `.jsonl` modifié depuis moins de 180 s = actif ; `meta.finished` = terminé ; sinon en attente | `S/equipe.mjs:61,86`, `S/who.mjs:82,89` |
| « dernière activité il y a N s » | `now − mtime`, calculé côté serveur | `S/equipe.mjs:39` |
| Titre | dernière ligne `custom-title`, sinon « Session principale · branche » | `S/lecture.mjs:93-98`, `S/equipe-carte.mjs:68` |
| Arbre, branche | worktree cité dans le transcript, sinon `cwd` ; branche de l'arbre déduit | `S/who.mjs:62,68-75` |
| « utilise playwright » | dernier `tool_use` : verbe d'une table fermée, cible réduite ; agents actifs seuls | `S/transcript.mjs:36-60` |
| Rôle, tâche, parent, durée | `agent-<id>.meta.json`, première ligne et mtime du `.jsonl` | `S/equipe.mjs:43-52,92-97` |
| Nœud de mission | `driver-lock.sh orphans`, sinon citation « nœud \`id\` » du mandat | `S/who.mjs:113-127` |
| « Aucune mission en cours » | nœuds `mission` actifs du graphe Projet, figés au chargement | `S/equipe-carte.mjs:21-32`, `U/76-vf-git-entete.js:38-41` |
| Dernière commande | `GET /api/vf/doing` : dernier `Bash`, programme et premier argument | `S/who.mjs:180-216` |
| Transcript | `GET /api/vf/transcript` : première ligne, puis 8 Mo de fin, 50 messages, 200 outils | `S/transcript.mjs:88-115` |

Transport [V] :
- **Collecte** : synchrone, toutes les 5 s (`S/live.mjs:142-153`). `collectWho` prend environ 270 ms, sous-processus `git` et `driver-lock.sh` compris.
- **Flux** : SSE `who` (liste entière) quand la signature change (`S/live.mjs:51,145`) ; 35 événements en 230 s observés.
- **Page** : `/equipe.html` (2,4 Mo) est reconstruite à chaque GET (`S/server.mjs:136-143`) et **rechargée** dès que l'ensemble des agents change, au plus toutes les 15 s (`U/72-vf-equipe.js:43-53,137`).
- **Panneau `vf-signal`** : relance `vf-cockpit-signal.mjs` toutes les 10 s pane ouverte (`R/plugin/cockpit/signal/hooks/register.tsx:68`). Il écoute aussi `tool.call`, `turn.complete`, `agent.spawn` et `$.session.usage()`, pour la seule session courante.

## 2. Défauts

| Id | Gravité | Constat, preuve | Conséquence visible |
|---|---|---|---|
| D1 | Critique | Un sous-agent non fini, muet depuis 180 s, est exclu ; sa session aussi si rien d'autre n'est inclus (`S/equipe.mjs:72-76`). Sonde [V] : worker en `Bash` depuis 10 min → `busy=false`, 0 agent ; avec un frère terminé, tout s'affiche sauf lui. `vf-signal` hérite du trou alors que `$.agent.list()` connaît le statut (`R/plugin/cockpit/signal/hooks/views/equipe.tsx:53-66`). | L'agent qui travaille (tests longs) disparaît, « Personne au travail », dernière commande « Plus active ». 35 % des sous-agents ont connu un silence de plus de 180 s (attentes légitimes comprises), 133 de plus de 10 min. |
| D2 | Majeur | Les 24 h ne valent que pour les sous-agents ; une session a 3 minutes (`S/equipe.mjs:76,83`). [V] 4 sessions du dépôt écrites depuis moins de 24 h (14 min, 84 min…) sont absentes ; l'une est pourtant vivante, `idle`, dans `~/.claude/sessions`. | Cause des « sessions des autres worktrees absentes » : la portée par worktree est correcte (3 arbres vus), ces sessions sont au repos. Aucun état « attend l'humain » ; une session au repos dont des agents ont fini est dite « terminé » (`:86`). |
| D3 | Majeur | « À surveiller » et « commande en cours depuis 15 min » exigent `actif` avec `ageS ≥ 120` ou `900` (`U/71-vf-equipe-rendu.js:55-61,109-113`) ; le collecteur borne `actif` à 180 s. Les tests passent sur des fixtures écrites à la main (`R/plugin/cockpit/scripts/tests/test-cockpit-equipe.sh:1146,1158`). `ageS` est figé entre deux poussées (admis `U/70-vf-live.js:65`). | Alerte inatteignable de bout en bout ; âges affichés périmés. |
| D4 | Majeur | Worker actif sous manager terminé : sa carte part dans « Terminés » (`S/equipe-carte.mjs:47-49,67`) ; « orphelin ? » ne regarde qu'un parent-session (`U/71-vf-equipe-rendu.js:85`) ; un agent du registre présent en collecte n'est jamais `orphan` (`S/who.mjs:118`). Sonde [V]. | Le cas « workers orphelins après un manager » est invisible. |
| D5 | Majeur | 143 mandats sur 1 005 citent un nœud (14 %) ; le registre n'est lu que pour ses entrées `running` et il est supprimé au relâchement (`R/plugin/conductor/scripts/driver-lock.sh:1240`) ; 20 DAG sur 55 se nomment `dag-*.json`, seul `*.dag.json` est lu (`S/planning.mjs:98`, `S/who.mjs:132`). | « pas lié à une phase », « Aucune mission en cours » avec des agents actifs. |
| D6 | Moyen | « New session » est une valeur de `custom-title` (407 lignes dans une session qui porte `entrypoint: claude-desktop`), prise pour un `/rename` (`S/lecture.mjs:96`) ; origine cliente [I]. | Titre par défaut affiché comme un nom choisi. |
| D7 | Moyen | Mandat = première ligne si `user` (`S/transcript.mjs:95`) ; 0 session sur 63 commence par `user` (`last-prompt`, `queue-operation`…) ; l'intertitre est toujours imprimé (`U/71-vf-equipe-rendu.js:146`). | Mandat vide par construction. |
| D8 | Moyen | Le réducteur sépare messages et outils et jette l'heure (`S/transcript.mjs:99-114`), alors que `timestamp` est sur 100 % des lignes. Le graphe n'a aucun lien (`S/equipe-carte.mjs:83`) : la hiérarchie est un emboîtement. | Ni entrelacement ni horodatage ; deux cartes sur un canevas vide. |
| D9 | Mineur | Arbre « par activité » : un chemin de worktree cité réattribue session et branche [I] ; `dureeS` inclut les veilles d'un agent réveillé (jusqu'à 101 h) ; `bloque` jamais produit ; `finished` absent pour 38 agents sur 888 depuis la 2.1.308. | États et durées approximatifs. |

Non observé à l'écran (aucun navigateur piloté) : le rendu de D3 et D4, et le faux positif de D9.

## 3. Données disponibles, non exploitées

| Champ (présence mesurée) | Ce qu'on en tire | Fiabilité |
|---|---|---|
| `~/.claude/sessions/<pid>.json` : `status` busy/idle, `statusUpdatedAt`, `pid`, `sessionId`, `name`, `nameSource`, `startedAt` (aucune référence dans le cockpit) | session occupée, au repos ou close ; titre et sa provenance | Fiable (pid vérifiable) ; format interne |
| `timestamp` des lignes `user` et `assistant` | début, fin, segments d'activité | Fiable |
| `tool_use.id` ↔ `tool_result.tool_use_id` | durée de chaque outil, outil en cours | Fiable (appariement complet) |
| `message.usage.*`, `message.model` | jetons par tour, modèle réel | Fiable **après dédoublonnage par `message.id`** (2 à 8 lignes par message) |
| `input + cache_read + cache_creation` du dernier message | taille du contexte | Fiable ; le pourcentage est heuristique (fenêtre absente) |
| `cost-state` : `totalCostUSD`, `modelUsage` | coût réel, sous-agents compris (montant relevé sur une session, non reproduit ici) | Fiable mais rare (6 lignes sur 4 sessions, en fin de fichier [I]) ; par agent : estimation |
| `system` `compact_boundary` : `preTokens`, `postTokens`, `trigger` | compactions | Fiable |
| `system` `turn_duration` : `durationMs`, `pendingBackgroundAgentCount` | fin de tour, « attend ses agents » | Fiable, sessions seules |
| `origin.kind`, `turnOrigin` : human, peer, task-notification | qui a déclenché le tour | Fiable |
| `meta.toolUseId`, `toolUseResult.agentId`, `parentAgentId` | arbre, instant du dispatch | Fiable (248 sur 248) |
| `AskUserQuestion` sans résultat ; `permissionDecision.source`, `toolDenialKind` | attente d'une réponse ; permission, refus | Fiable ; attente de permission heuristique |
| `tool_result.is_error`, `timedOutAfterMs`, `backgroundTaskId` | erreurs, dépassements, tâches de fond | Fiable |
| `file_path` d'`Edit` et `Write`, `structuredPatch` | fichiers touchés, lignes ajoutées | Fiable ; écritures par Bash invisibles |
| registre `children.jsonl` : `node`, `dispatched_at`, `closed_at` | agent ↔ nœud, daté | Fiable, éphémère |
| mod : `$.session.usage()`, `turn.complete` | contexte en %, coût, limites | Fiable ; session courante, non partagé avec la page |

## 4. Pour un graphe ou une frise

- **Index** : une voie par transcript, incrémentale par décalage d'octets ; le patron existe (`S/who.mjs:38-54`). Chaque voie porte parent, rôle, modèle, début, fin, compteurs et segments (modèle, outil, attente humaine, attente d'agents, silence). Prototype mesuré : 147 Ko pour 1 068 transcripts, 3 244 segments.
- **Coût** : un passage complet de 2,6 Go prend 9,4 s (280 Mo/s, un fil). Il faut le sortir de la boucle du serveur et le borner à la fenêtre affichée ; ensuite seuls les octets ajoutés sont lus [I]. La lecture de fin de fichier ne suffit pas : elle ne donne ni début ni segments.
- **Route** : `GET /api/vf/frise?depuis=&jusqua=`, authentifiée, à la demande, plus un événement SSE sans contenu (patron `git`, `S/live.mjs:148-150`). Cela supprime les rechargements de page.
- **Format** : interne et mouvant (23 types de ligne, `finished` apparu en 2.1.308). Tout champ lu passe par le contrat de forme (`S/interface.json:92-113`, vérifié sur 2.1.317 alors que les sessions tournent en 2.1.322).
- **Limites déjà posées** :
  - dernière commande jamais dans le flux, un fichier ou l'export (P67-D-14, `R/.planning/workstreams/fiabilite/phases/VFDO-67-cockpit-floorplan-socle-partage/67-CONTEXT.md:98`) ;
  - verbe et cible réduite, jamais un argument (P69-D-16) ;
  - messages et actions sans sorties d'outil, à la demande, jamais exportés (P69-D-19, P69-D-23) ;
  - titre par `custom-title` seul, jamais `ai-title` (PU-G-162) ;
  - clés `doing`, `mandat`, `messages`, `outils` refusées à l'émission (`S/server.mjs:33-35`).
- Heures, durées, jetons et verbes tiennent dans ces limites. **Persister l'index sur disque reste un arbitrage à poser.**
- **Phase 74** : inscrite (`R/.planning/workstreams/fiabilite/ROADMAP.md:544`). Sa note donne `meta.json` pour source des horodatages ; il n'en porte aucun [V], ils viennent des transcripts.

## 5. Recommandations

1. **État réel des sessions (S)** : lire `~/.claude/sessions/*.json` ; états « occupée », « attend l'humain », « close ». Corrige D2 et D6.
2. **Un agent non fini reste affiché (S)** tant que sa session vit, avec « outil en cours depuis N » tiré du `tool_use` sans résultat ; âge recalculé dans la page. Corrige D1 et D3.
3. **Index incrémental et route de frise (M)** : socle de la Phase 74 ; durée, jetons, contexte, erreurs, fichiers.
4. **Transcript en fil daté (S)** : un seul tableau ordonné, pas de mandat pour une session. Corrige D7 et D8.
5. **Rattachement durable (M)** : lire `dag-*.json`, conserver le registre après relâchement, orphelin = parent terminé. Corrige D4 et D5.

Scripts de mesure, versés avec cette annexe :
- `sondes/index-proto.mjs`
- `sondes/sonde-visibilite.mjs`

Détail utile aux autres audits : la copie déployée attend l'en-tête `x-vf-cockpit-token`, pas le `x-floorplan-token` des sources.
