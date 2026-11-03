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
