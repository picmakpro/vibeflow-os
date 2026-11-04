---
phase: 69-suivi-travail-en-cours-cockpit
plan: 06
requirements: [CKPT-21, CKPT-22, CKPT-24, CKPT-28]
---

# 69-06 — dernière action, rattachement, réducteur de transcript (bibliothèque)

## Livré
- `vf-cockpit-transcript.mjs` (neuf, 100 lignes) : `VERBES` (table fermée, prototype nul), `etiquette`, `derniereAction`, `citationsDuMandat`, `reduireTranscript`.
- `vf-cockpit-equipe.mjs` : champ `action` des agents `actif` (session ou sous-agent), `indexDesNoeuds`, `rattacher`.
- `vf-cockpit-who.mjs` : `contexte()` extrait de `gather` (partagé avec `agentsConnus`), `agentsConnus`, `revealTranscript`, rattachement branché dans `gather`, source 4 (DAG `running`) lue par `lireDags` (+ dossiers `vf-driver/ws/*` et `vf-driver/repo`).

## Décisions du manager appliquées
- OQ-4 / OQ-5 : registre décisif sans repli sur le mandat ; mandat par citation structurée, unicité stricte.
- OQ-7 : Bash = « lance une commande », cible vide.

## Table des verbes à valider (P69-PL-19, provisoire)
Read lit · Write/Edit/MultiEdit/NotebookEdit modifie · Grep/Glob cherche dans · Bash/bash lance une commande · Agent/Task lance un agent (cible = subagent_type) · SendMessage écrit à (to) · WebFetch consulte une page (hôte) · WebSearch cherche sur le web · Skill utilise le skill (skill) · mcp__<serveur>__* utilise (serveur) · autre : utilise un outil.

## Écarts et limites
- `masque()` borne son entrée à `MAX_MASQUE` (4 000) : le mandat est donc effectivement tronqué à 4 000 caractères (et non 8 000) ; `tronque` passe à vrai dans ce cas. Pas de découpage en fenêtres (un secret à cheval sur deux fenêtres échapperait au masque).
- La cible d'un chemin n'est « dans le lab » que sous la racine passée (pas les autres arbres git du lab) : sinon « un fichier hors du lab ».
- `sources.dags.files` compte désormais aussi les DAG des dossiers de phase et de compartiment (découverte unique `lireDags`).
- L'export de la carte privée `_registre` n'a pas été nécessaire : `revealTranscript` n'en dépend pas.
- Le commit de la tâche 2 contient déjà `agentsConnus`/`revealTranscript` (même fichier).

## Témoins
E21.0-E21.7, E22.0-E22.10, E28, EP, E0/E19/E20 verts ; T0, T24.1-T24.16 verts ; who 69/0, sécurité 88/0, réseau 14/0. E23/EUI et T25/T26 restent rouges (69-05/07/08).

## Correction d'audit (fix-69-lecture, mandat du vf-dev-manager)

Quatre findings de gravité basse de l'audit anticipé, chacun avec un témoin rouge avant le code (fixtures synthétiques).

| Finding | Correction | Témoin (rouge sur l'ancien code -> vert) |
|---|---|---|
| F1 masque après la coupe | `masqueCoupe(t, n)` dans `vf-cockpit-lecture.mjs` : masque d'une tranche élargie de `MARGE_MASQUE` (700), puis coupe. Le mandat passe de 4 000 à 8 000 caractères effectifs. | T24F1.1 à .5 (secret à 10 caractères de 4 000, 8 000 et 2 000) : 5 rouges -> verts |
| F2 champs libres | `collectWho` : tout champ libre est une chaîne masquée et bornée, sinon absent ; nombres finis ou absents ; identifiant hors `ID_RE` exclu (`collecteAgents`, registre, sortie) | E29.1, E29.2, E29.3 (mutants rejoués : retirer la suppression des champs non chaînes fait rougir E29.1 et E29.2 ; retirer les deux gardes ID_RE ensemble fait rougir E29.3 ; les gardes redondantes sont listées dans la section suivante) |
| F3 forme typée | `formeOk` exige des chaînes ; `inScope` robuste ; dernière ligne d'un sous-agent contrôlée ; corps de boucle de `collecteAgents` sous try (compté en forme inconnue) ; `revealTranscript` ne lève jamais | E29.4, E29.6 |
| F4 coût | `readJson(f, max)` (meta.json > 256 Kio : forme inconnue) ; `reduireTranscript` n'analyse que, masque et étiquette (realpath) que les 50 messages et 200 outils gardés ; `isFile()` avant ouverture (cherche, premiereLigne) | E29.5 ; T24F4.1 (10,5 s -> < 2 s) |

Limites : T24F4.2 (8,5 Mio de tool_use) passait déjà sur l'ancien code (0,8 s) : il garde la borne sans la discriminer. Le coût d'un `meta.json` est borné par `META_MAX` mais `premiereLigne` garde son cache d'échec (consigné, hors périmètre). Le motif de masque `=\S+` rend, au point de coupe, `[masqué]` d'un seul bloc.

## Correction de revue fraîche (fix-69-lecture-2)

Dix mineurs d'une revue sur l'arbre 02145ab3. Mutants rejoués sur une copie (scratchpad), assertions rougies entre crochets.

| Point | Correction | Mutant rejoué -> assertions rouges |
|---|---|---|
| 1 masque raccourci | `masqueCoupe` garde le plus long préfixe commun au masque de [0, n) et au masque de [0, n + marge) : aucun caractère de la zone d'extension n'est rendu | « coupe avant masque » -> T24F1.1 à .5 et T24G1.2 ; « tranche élargie seule » -> T24G1.1 |
| 2 coupe avant masque (`task` d'un nœud) | plus de `slice(0, 100)` avant le masque ; borne de 100 appliquée après | E30.5 |
| 3 champs imbriqués | `rattachement` et `action` : chaque clé chaîne masquée et bornée ; `trees` borné | E30.3 |
| 4 `readJson` sans `isFile` | contrôle `isFile()` ; même garde dans la fenêtre de lecture du transcript | `readJson` sans garde -> E30.1 ; fenêtre sans garde -> T24G5 |
| 5 témoins de tube | `mkfifo` (meta.json, transcript de sous-agent, session, transcript direct), enfant borné par `spawnSync` + SIGKILL, tubes supprimés | `premiereLigne` ou `cherche` sans garde -> E30.1 |
| 6 marge | témoin de portée 385 (identifiants d'URL) ; fixtures F1 repositionnées à 16 caractères de la borne : les 5 rougissent sur « couper puis masquer » | marge 300 ou 50 -> T24G1.2 |
| 7 affirmation du SUMMARY | corrigée dans la section précédente | voir ci-dessous |
| 8 cache `premiereLigne` | invalidé par date et taille | « cache sans mtime » -> T24G4 |
| 9 T24F4.2 | renommé « garde non discriminante » ; vrai témoin T24G2 (nombre d'appels à `realpath`) | « étiqueter tous les outils » -> T24F4.0 et T24G2 |
| 10 première ligne trop longue | `tronque` vrai quand la fenêtre de tête coupe la première ligne | « sans tronque » -> T24G3 |

Nombres du registre (`NOMBRES`) : témoin E30.4, mutant « sans NOMBRES » -> E30.4. Défenses redondantes SANS témoin propre : `ID_RE` de `charge` (compensée par le filtre `IDS` de `collectWho`, et inversement), le `try` de `collecteAgents` et celui de `revealTranscript` (aucune fixture bon marché ne fait lever le corps), le bornage de `trees` (valeur dérivée des chemins d'arbres git). La borne de `meta.json` est 256 Kio (la section précédente nommait une fixture de 512 Kio).

## Dernière passe (mineurs 5 et 6)
- Point 5 : E30.6 à E30.8 — l'identifiant d'un nœud rattaché porte un jeton ; `rattachement.noeud` sort masqué ; mutant `bornes(o[k], n)` -> `o[k].slice(0, n)` détecté (jeton en clair).
- Point 6 : `read()` de `vf-cockpit-planning.mjs` n'ouvre plus qu'un fichier régulier d'au plus 8 Mio (`statSync().isFile()`). Témoins E31.0 à E31.2 : un `*.dag.json` en tube et un lien vers `/dev/zero` ne bloquent plus la collecte (enfant borné, SIGKILL, tubes supprimés) ; mutant sans contrôle -> collecte bloquée. Le `read` local de `vf-cockpit-project.mjs` (STATE, PLAN, sans DAG) a la même forme et n'est pas dans ce périmètre.
