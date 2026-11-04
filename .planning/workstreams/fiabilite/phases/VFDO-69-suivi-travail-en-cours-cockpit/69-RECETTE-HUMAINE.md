# 69 — Recette humaine de fin de phase (suivi du travail en cours dans le cockpit)

**Statut :** CLOSE — déroulée le 2026-11-04 par juges Playwright (arbitrage de méthode de Samuel, session principale Claude Code, 2026-11-04), 4 écarts corrigés

Ce fichier prépare la recette ; il ne la remplit pas. Elle se déroule une étape à la fois. Chaque étape dit ce que Samuel
fait, ce qu'il doit voir, et laisse une case de retour. La réponse est consignée **mot pour mot, avec son canal et sa date**
par la session principale, sous dictée (mémoire « arbitrage humain jamais inférable »). Aucune case n'est remplie par un
agent. Le tri se fait à la fin, jamais pendant le déroulé.

Exigences visées : CKPT-13 à CKPT-18 (avancement des phases) et CKPT-19 à CKPT-28 (équipe au travail). Décisions : `69-CONTEXT.md`
(P69-D-01 à P69-D-28).

Pré-requis : un vrai navigateur (Chrome, Safari ou Firefox), Node ≥ 22, la branche `feat/phase-69-suivi-travail` à son dernier
commit, une session Claude Code ouverte sur ce dépôt (la vôtre suffit) pour l'étape 5.

**Écart déjà connu, à ne pas signaler (P69-D-28)** : les onglets sont resserrés (police 12 px, padding 2 px) par rapport à la
direction artistique Graphite. Le retour aux valeurs DA revient à la Phase 70.

**Hors périmètre, à ne pas juger** : la mise en page mobile (Phase 70), le terminal intégré (Phase 71), lancer du travail depuis
une carte (Phase 72).

## Points que les workers n'ont pas pu vérifier à l'œil (à regarder en priorité)

Les plans ont été exécutés sans navigateur ; les assertions automatiques ne remplacent pas un regard. Trois points ne sont
couverts par rien d'autre :

1. **Tiroir « Au travail » réel et panneau d'un agent** dans un navigateur (69-08 ne les a couverts que par des assertions) : étapes 6, 7 et 8.
2. **Logos de l'en-tête en thème sombre** (69-05, page Équipe) : étape 4.
3. **Carte « à recetter » dans les deux thèmes** (69-01, aucune couleur en dur, jamais vue) : étape 3.

## 1. Lancer le cockpit

Depuis la racine du dépôt (là où se trouve `plugin/`) :

```bash
node plugin/cockpit/scripts/vf-cockpit.mjs open --rebuild
#    imprime : Cockpit : http://127.0.0.1:<port>/ (Code) · http://127.0.0.1:<port>/project.html (Projet)
```

Le port est stable pour un lab donné (plage 4378 à 4477). L'onglet **Équipe** se trouve à l'adresse `/equipe.html` du même serveur
(ou par le lien « Équipe » de l'en-tête). Pour arrêter : `node plugin/cockpit/scripts/vf-cockpit.mjs stop --lab .` (le serveur
s'arrête aussi seul 60 minutes après la fermeture du dernier onglet). `--rebuild` est nécessaire : sans lui, un serveur vivant
d'avant la phase serait réutilisé avec l'ancien code.

**Étape 1 — Lancer.**
- Faire : lancer la commande ci-dessus, ouvrir l'adresse « Projet » imprimée.
- Voir : la commande imprime les deux adresses sans erreur ; la page Projet s'affiche, trois onglets dans l'en-tête (Code, Projet, Équipe).

| Retour de Samuel (mot pour mot) | Canal | Date |
|---|---|---|
| (capture d'écran, sans texte : onglet Équipe ouvert, onglets Code / Projet / Équipe visibles dans l'en-tête) | session principale Claude Code | 2026-11-04 |

## 2. Onglet Projet — avancement des phases (CKPT-13 à CKPT-18)

**Étape 2 — Phases, décompte, missions, pied du jalon.**
- Faire : sur Projet, ouvrir le jalon `vibeflow-v2.0` ; lire la carte de la Phase 67, celle de la Phase 69, puis le pied du jalon.
- Voir :
  - la Phase 67 n'est plus « à faire » : son décompte se lit « 7/7 plans · N correctifs » (les `67-FIX-*-SUMMARY.md` forment la ligne à part des correctifs, ils ne gonflent plus le total des plans ; plus de « 11/7 ») ;
  - une phase dont tous les plans sont exécutés mais non close porte le mot « à recetter » en tête de son pied ;
  - la Phase 69 doit se lire « en cours » ou « à recetter » selon que le plan 69-09 a son SUMMARY ou non ; noter ce qui est affiché ;
  - la mission de la Phase 67 (`2026-11-01-v2-cockpit.dag.json`, ligne `phase` posée) apparaît **sous la Phase 67**, plus dans « Missions hors phase » ;
  - le pied du jalon se lit sous la forme « N clos · [N en cours ·] N à recetter · N à faire · N % » ; le pourcentage ne compte que les phases closes (jamais pondéré). Le jalon n'est plus « à faire » dès qu'une de ses phases est en cours ou à recetter, quel que soit le STATE ;
  - la ligne d'exigences d'une phase non close reste « 0/N » : voulu, les exigences ne se cochent qu'à la clôture (C5).
- Voir aussi (reste à faire, P69-D-07) : une phase à recetter dont le fichier `*-RECETTE-HUMAINE.md` n'est pas clos affiche la recette parmi ce qu'il reste ; celle-ci (Phase 69) en est le cas. Aucune mention de PR, de CI, de merge ni de release : le cockpit ne lit pas le réseau.

| Retour de Samuel (mot pour mot) | Canal | Date |
|---|---|---|
| | | |

Verdict des juges (Playwright, 2026-11-04) : OK (67 : « 7/7 plans · 4 correctifs », mission rattachée ; 69 : « à recetter · 9/9 plans · 0/16 exigences » ; jalon « 1 clos · 1 à recetter · 4 à faire · 17 % »). Constat : « Dépend de : Phase 67, 68, 10 » faux, et pied des cartes masqué au zoom d'ouverture du jalon (corrigés dans la Phase 69, voir Tri).

Verdict des juges (Playwright, 2026-11-04) : OK (adresses imprimées lues par `status`, rc 0 ; trois onglets Code / Projet / Équipe, 0 erreur console).

**Étape 3 — Carte « à recetter » dans les deux thèmes (point non vérifié, 69-01).**
- Faire : repérer une carte « à recetter » (Phase 67 ou 69). Basculer le thème sombre puis clair (commande de thème de la page), regarder la carte et le pied du jalon à chaque fois.
- Voir : la carte « à recetter » prend la couleur de l'état « en cours » avec le mot « à recetter » en tête du pied (P69-D-25, pas de couleur propre : une distinction visuelle relève de la Phase 70). Texte lisible, contraste correct, rien de blanc sur blanc ni de noir sur noir, dans les deux thèmes.

| Retour de Samuel (mot pour mot) | Canal | Date |
|---|---|---|
| | | |

Verdict des juges (Playwright, 2026-11-04) : KO (thème clair : pastille « En cours » orange `#F59E0B` sur fond orange pâle, 1,9:1 ; sombre 8,2:1 ; corrigé, voir Tri).

## 3. Troisième onglet « Équipe », thèmes sombre et clair (CKPT-23)

**Étape 4 — Ouvrir l'onglet Équipe dans les deux thèmes (point non vérifié, 69-05).**
- Faire : cliquer « Équipe » dans l'en-tête ; regarder la page en thème sombre, puis en thème clair. Regarder tout particulièrement les **logos de l'en-tête en thème sombre**.
- Voir : une carte (même présentation que Code et Projet) montre les sessions et agents ; les logos VibeFlow de l'en-tête sont visibles et lisibles en thème sombre (pas de logo noir sur fond sombre, pas de carré vide) ; le titre de l'onglet du navigateur est correct ; l'onglet actif est signalé. Pas de barre de question ni de bouton de santé sur cette page (masqués exprès). Écart connu et accepté : la page peut encore afficher la section « Santé » du viewer (« Aucun problème trouvé »), sans objet pour l'équipe ; la signaler seulement si elle gêne.
- Rappel : l'écart des onglets resserrés avec la DA est connu (P69-D-28), ne pas le signaler.

| Retour de Samuel (mot pour mot) | Canal | Date |
|---|---|---|
| | | |

Verdict des juges (Playwright, 2026-11-04) : OK (cartes Session et agents, logos visibles en sombre, titre et onglet actif corrects, ni barre de question ni bouton de santé).

## 4. Tiroir « Au travail » : l'arbre vivre (CKPT-19 à CKPT-22)

**Étape 5 — Lancer une vraie mission pendant la recette.**
- Faire : laisser le cockpit ouvert sur l'onglet Projet. Dans une session Claude Code ouverte sur ce dépôt, lancer un travail qui crée un manager et au moins un worker (par exemple demander à `vibeflow-head` une petite tâche courte qui passe par `vf-coder`, ou n'importe quelle mission qui dispatche des sous-agents). Garder la session active pendant les étapes 6 à 8.
- Voir : le badge « au travail » de l'en-tête s'allume et son nombre suit les agents actifs.

| Retour de Samuel (mot pour mot) | Canal | Date |
|---|---|---|
| | | |

Verdict des juges (Playwright, 2026-11-04) : OK (le badge « au travail » s'allume et son nombre suit les agents actifs : 4, 6, 5, 5 ; 6 → 5 en direct sans rechargement).

**Étape 6 — Le tiroir en arbre (point non vérifié, 69-08).**
- Faire : ouvrir le tiroir « Au travail » (badge de l'en-tête) pendant que la mission tourne.
- Voir :
  - un **arbre session → manager → workers** (plus la liste plate d'avant), chaque ligne avec son type, sa description, son état et sa durée ;
  - l'arbre se met à jour seul quand un agent démarre ou finit, sans recharger la page ;
  - les agents **terminés récents** (dernières 24 h) sont **repliés** dans un bloc « terminés », grisés, dépliable d'un clic ; les agents actifs ne sont jamais dans ce bloc ;
  - le tiroir a sa marge intérieure, son titre est entier, sa hauteur suit le contenu (les défauts D2 de la Phase 67 ne reviennent pas) ;
  - des lignes « Verrous et nœuds » (verrou, nœud de DAG, registre) sous l'arbre ;
  - **dernière action lisible** par agent actif, sous forme de verbe et de cible (« lit X », « modifie X », « lance une commande »), sans argument de commande ni secret.

| Retour de Samuel (mot pour mot) | Canal | Date |
|---|---|---|
| | | |

Verdict des juges (Playwright, 2026-11-04) : KO (arbre, terminés repliés, marge et titre OK ; mais le verrou tenu n'apparaît pas : `status --ws=fiabilite --phase=71` dit `present: true` alors que le tiroir dit « Driver libre » — copie installée de `driver-lock.sh` d'avant les verrous par phase ; corrigé, voir Tri).

**Étape 7 — Lien agent ↔ nœud de DAG (CKPT-21).**
- Faire : sur un agent qui exécute un nœud de la mission, cliquer son lien vers le nœud ; puis, depuis l'onglet Projet, ouvrir ce nœud et chercher la section « Agents sur ce nœud ».
- Voir : le lien mène au nœud (la page se positionne dessus) ; le nœud liste en retour l'agent qui l'exécute. Un agent dont le nœud ne se retrouve pas porte « non rattaché (raison) » : jamais un lien deviné. Noter, pour chaque agent, s'il est rattaché ou non et si c'est exact.

| Retour de Samuel (mot pour mot) | Canal | Date |
|---|---|---|
| | | |

Verdict des juges (Playwright, 2026-11-04) : OK (clic « Nœud exec-69 » → nœud ; le nœud liste l'agent en retour ; « non rattaché (raison) » exact sur 98 + 5 + 2 + 22). Limite : aucun agent actif rattaché, chemin positif prouvé sur des agents terminés seulement.

## 5. Panneau d'un agent et transcript (CKPT-24 à CKPT-26)

**Étape 8 — Panneau d'un agent (point non vérifié, 69-08).**
- Faire : dans l'onglet Équipe, cliquer un agent (carte `ag-`) pour ouvrir son panneau.
- Voir : état, durée, dernière action, nœud rattaché, bouton « Voir la dernière commande » (programme et premier argument seulement, règle F-B de la Phase 67) et bouton « Lire le transcript ». Texte entier, rien de rogné, marge intérieure correcte, dans les thèmes sombre et clair.

| Retour de Samuel (mot pour mot) | Canal | Date |
|---|---|---|
| | | |

Verdict des juges (Playwright, 2026-11-04) : OK (état, durée 9 h, dernière action, nœud rattaché, « Voir la dernière commande » = programme seul, aucun débordement, deux thèmes).

**Étape 9 — Lire le transcript (rendu en texte, aucune sortie d'outil).**
- Faire : cliquer « Lire le transcript » sur un manager ou un worker qui a déjà travaillé ; lire ce qui s'affiche ; passer à un autre agent et revenir.
- Voir :
  - le transcript n'apparaît **qu'après le clic** ; il porte le mandat (premier message), les messages de l'agent et ses actions (verbe et cible) ;
  - **aucune sortie d'outil** : ni résultat de commande, ni contenu de fichier lu, ni extrait de test ;
  - un rendu en **texte** (pas de HTML interprété : un `<b>` ou un lien dans un message s'affiche tel quel) ;
  - un mandat très long est coupé avec une mention de troncature ;
  - en passant à un autre agent, le transcript précédent ne reste pas affiché.

| Retour de Samuel (mot pour mot) | Canal | Date |
|---|---|---|
| | | |

Verdict des juges (Playwright, 2026-11-04) : OK (transcript absent avant le clic, mandat/messages/outils, aucune sortie d'outil, rendu en texte sans HTML, mandat tronqué avec mention, disparaît au changement d'agent).

## 6. Sécurité perçue (CKPT-25, CKPT-26, P69-D-27)

**Étape 10 — Pas de transcript tant qu'on ne clique pas.**
- Faire : recharger la page Équipe sans cliquer aucun « Lire le transcript ». Ouvrir les outils réseau du navigateur (onglet Réseau, filtre « tout »), recharger, chercher `transcript`. Cliquer ensuite « Lire le transcript » une fois.
- Voir : avant le clic, **aucune requête** vers `/api/vf/transcript` et aucun texte de transcript dans la page (rechercher un mot du mandat avec la recherche du navigateur : zéro résultat) ; après le clic, une seule requête `/api/vf/transcript?id=…` vers le même hôte et le même port que le cockpit, et aucune autre requête vers un autre hôte ou un autre port. Un export téléchargé (« Exporter », onglet Code) ne contient aucun transcript.
- Risque résiduel accepté, à lire sans le contester ici (P69-D-27, « J'accepte », Samuel, AskUserQuestion session principale, 2026-11-03) : le transcript réduit reste lisible par tout processus local qui lit le jeton de la page ; un secret écrit en prose est masqué au mieux, pas à coup sûr.

| Retour de Samuel (mot pour mot) | Canal | Date |
|---|---|---|
| | | |

Verdict des juges (Playwright, 2026-11-04) : OK (0 requête transcript et 0 extrait de mandat avant le clic ; une seule requête 127.0.0.1:4455 après ; l'export de l'onglet Code n'en contient aucun).

## 7. Largeurs 390, 1 024 et 1 440 px

On note le rendu, sans juger la mise en page mobile (Phase 70). Redimensionner la fenêtre, ou l'émulation d'appareil du navigateur, aux trois largeurs, sur **Projet** et sur **Équipe**, avec le tiroir « Au travail » ouvert.

**Étape 11 — 1 440 px.**
- Voir : en-tête entier avec ses trois onglets, fil d'Ariane lisible, tiroir et panneau d'agent sans rognure.

| Retour de Samuel (mot pour mot) | Canal | Date |
|---|---|---|
| | | |

Verdict des juges (Playwright, 2026-11-04) : OK (en-tête entier, tiroir x 1064 à 1424, panneau d'agent sans rognure).

**Étape 12 — 1 024 px.**
- Voir : rien ne se superpose (onglets, recherche, zoom), tiroir et panneau lisibles. À 1 024 px l'en-tête tenait avant le troisième onglet ; il doit encore tenir.

| Retour de Samuel (mot pour mot) | Canal | Date |
|---|---|---|
| | | |

Verdict des juges (Playwright, 2026-11-04) : OK (rien ne se superpose, trois onglets entiers, tiroir lisible) ; défaut D connu de la Phase 70 : boutons de zoom au milieu du canevas.

**Étape 13 — 390 px.**
- Faire : seulement décrire ce qu'on voit : l'arbre du tiroir, le panneau d'agent, l'accès au transcript, l'en-tête.
- Ne pas juger : la hiérarchie d'information mobile est le sujet de la Phase 70. Dire seulement si quelque chose est **inutilisable** (bouton hors écran, texte coupé sans défilement).

| Retour de Samuel (mot pour mot) | Canal | Date |
|---|---|---|
| | | |

Verdict des juges (Playwright, 2026-11-04) : Constat : rien d'inutilisable (en-tête sur deux rangées, aucun bouton hors écran, tiroir et panneau en feuille défilable, « Lire le transcript » atteignable en défilant).

## 8. Fin de recette

**Clôture (2026-11-04).** Recette déroulée par deux juges Playwright, selon l'arbitrage de méthode de Samuel (session principale Claude Code, 2026-11-04, consigné dans « Tri »). Les quatre écarts relevés (« Dépend de », verrou « Driver libre », contraste de « En cours », pied des cartes et ligne anglaise de l'export) sont corrigés par les commits `36acb0af`, `63b7869f`, `db8f6736`, `f66ba2f2`, `1e820393`, selon le tri de Samuel (AskUserQuestion, session principale Claude Code, 2026-11-04). Les étapes 3 et 6 portent encore leur verdict KO d'origine : leurs correctifs sont couverts par des suites vertes (vérification `69-VERIFICATION.md`, 21 suites du module à 0) mais n'ont pas été rejoués à l'œil par un juge. Le cas d'un agent actif relié à son nœud n'est couvert que par fixture (E21). Les colonnes « Retour de Samuel » restent vides : aucun avis humain n'a été dicté, aucune n'a été remplie par un agent.

**Étape 14 — Arrêter.**
- Faire : `node plugin/cockpit/scripts/vf-cockpit.mjs stop --lab .`
- Voir : la commande confirme l'arrêt. Terminer la session de test si elle a créé des fichiers dont on ne veut pas.

| Retour de Samuel (mot pour mot) | Canal | Date |
|---|---|---|
| | | |

Verdict des juges (Playwright, 2026-11-04) : OK (arrêt joué par la session principale : « Cockpit arrêté. », rc 0).

## Retours de Samuel

À remplir par la session principale, sous la dictée de Samuel, mot pour mot, avec le canal et la date. Ne pas trier ici.

| Étape | Réponse mot pour mot | Canal | Date |
|-------|----------------------|-------|------|
| | | | |

## Tri

Rempli après le déroulé complet, jamais pendant. Classer chaque retour : défaut à corriger dans la Phase 69, défaut renvoyé à la Phase 70, amélioration au backlog, ou écart accepté. Chaque décision de tri porte son canal et sa date.

| Retour | Classement | Décision (canal, date) |
|--------|------------|------------------------|
| « Dépend de » faux, Verrou « Driver libre », Contraste « En cours », Pied caché, ligne anglaise (réponse de Samuel, mot pour mot) | quatre défauts à corriger dans la Phase 69, avant le merge (« Dépend de » ; verrou « Driver libre » ; contraste de la pastille « En cours » ; pied des cartes masqué au zoom d'ouverture et ligne anglaise de l'export) | AskUserQuestion, session principale Claude Code, 2026-11-04 |
| « si c'est pour me demande ca ca sert a rien, lance des juge qui prenne des screenshot pour les tests, appele moi seulement si tu ne peux pas faire (gout, avis humain indispensable) » (arbitrage de méthode, mot pour mot) | méthode : la recette se joue par des juges qui prennent des captures ; Samuel n'est appelé que pour le goût ou un avis humain indispensable | session principale Claude Code, 2026-11-04 |
