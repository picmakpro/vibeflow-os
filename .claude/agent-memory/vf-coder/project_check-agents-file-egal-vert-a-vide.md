---
name: check-agents-file-egal-vert-a-vide
description: check-agents.sh exige --agents-dir=<v> (forme `=` SEULE) et --file <v> (deux args SEULS) — chaque forme fautive dégrade en cible vide, silencieusement
metadata:
  type: project
---

`check-agents.sh` parse ses options de façon **asymétrique** :

- `--agents-dir=<valeur>` — **forme `=` obligatoire**. `--agents-dir <valeur>` n'est pas reconnu.
- `--file <valeur>` — **deux arguments obligatoires**. `--file=<valeur>` n'est pas reconnu.

L'asymétrie est **inversée d'une option à l'autre** : ce qui marche pour l'une casse l'autre. Les
deux échouent de la même façon — silencieusement, sur la cible par défaut.

Écrire `--file=x.md` ne produit **aucune erreur** : la cible reste le défaut `.claude/agents`, vide
en contexte de dépôt, et le script rend **0** avec « aucun agent — rien à vérifier ». Un gate écrit
ainsi est **vert à vide**.

`--strict` est le garde-fou : il transforme la cible vide en **exit 3** (INDÉTERMINÉ), audible.

**Why:** ce piège s'est déclenché en écrivant une étape CI censée durcir un balayage — le gate
neuf serait passé pour vert sans jamais lire un fichier. Rencontré le 2026-08-04.

**Le faux rouge du 2026-08-04 (Phase 24-08).** Une baseline prise en `--agents-dir "$d"` (espace) a
rendu **exit 3 sur les 6 dossiers** — lu au premier coup d'œil comme « le parc entier est
non-conforme ». Il n'en était rien : la cible était vide. Reprise en `--agents-dir="$d"`, la
baseline réelle était **6/6 à zéro**. Un exit 3 uniforme sur toutes les cibles doit faire suspecter
l'appel avant le parc.

**How to apply:** toujours `--file <path>` en deux arguments, `--agents-dir=<path>` en un seul, et
**toujours** avec `--strict` quand
le gate doit prouver qu'il a regardé quelque chose. Plus généralement sur ce dépôt : après avoir
câblé un gate, vérifier qu'il sait **rougir** (le muter, ou le pointer sur une cible fautive connue)
— cf. [[mutation-test-discriminating-cases]] et [[gate-jamais-de-repli]].
