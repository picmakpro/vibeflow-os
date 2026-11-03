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
| F2 champs libres | `collectWho` : tout champ libre est une chaîne masquée et bornée, sinon absent ; nombres finis ou absents ; identifiant hors `ID_RE` exclu (`collecteAgents`, registre, sortie) | E29.1, E29.2, E29.3 (mutants : chaque garde retirée fait rougir son témoin) |
| F3 forme typée | `formeOk` exige des chaînes ; `inScope` robuste ; dernière ligne d'un sous-agent contrôlée ; corps de boucle de `collecteAgents` sous try (compté en forme inconnue) ; `revealTranscript` ne lève jamais | E29.4, E29.6 |
| F4 coût | `readJson(f, max)` (meta.json > 256 Kio : forme inconnue) ; `reduireTranscript` n'analyse que, masque et étiquette (realpath) que les 50 messages et 200 outils gardés ; `isFile()` avant ouverture (cherche, premiereLigne) | E29.5 ; T24F4.1 (10,5 s -> < 2 s) |

Limites : T24F4.2 (8,5 Mio de tool_use) passait déjà sur l'ancien code (0,8 s) : il garde la borne sans la discriminer. Le coût d'un `meta.json` est borné par `META_MAX` mais `premiereLigne` garde son cache d'échec (consigné, hors périmètre). Le motif de masque `=\S+` rend, au point de coupe, `[masqué]` d'un seul bloc.
