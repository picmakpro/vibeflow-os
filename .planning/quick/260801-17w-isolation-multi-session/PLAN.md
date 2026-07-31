---
quick_id: 260801-17w
slug: isolation-multi-session
date: 2026-08-01
mode: quick
---

# Quick 260801-17w : un écrivain = un worktree, et une branche revendiquée se dit

## Le trou, tel qu'il a été constaté

Le 2026-07-31 entre 18h52 et 19h06, **deux sessions ont écrit sur la même branche**
(`feat/phase-22-hygiene-doc`) sans le savoir. L'une était une mission pilotée par
`vf-dev-manager`, l'autre une session conversationnelle. Résultat : 3 commits hors périmètre
poussés dans la PR d'une mission qui ne les avait pas produits, et un manager obligé de geler sa
lane le temps de comprendre ce qui bougeait sous ses pieds.

Le constat de cause racine, formulé par le manager lui-même :

> le verrou de driver protège la même **étape** contre deux pilotes, rien ne protège la même
> **branche** contre deux écrivains.

C'est exact, et il faut ajouter le point qui fait vraiment mal : **`driver-lock.sh` n'est consulté
que par les managers**. La session qui est passée par-dessus n'en était pas un — elle n'avait
aucune raison de regarder un verrou dont rien ne lui parlait. Un verrou que seule une catégorie
d'acteurs interroge ne protège pas contre les autres.

## Ce qu'on emprunte, et à qui

- **`shanraisshan/claude-code-best-practice`** (lu le 2026-08-01, sur indication de Samuel) —
  prescrit le **git worktree** comme mécanisme d'isolation de premier rang pour le parallélisme
  (`--worktree`/`-w`, `isolation: "worktree"`, `.worktreeinclude`, hooks
  `WorktreeCreate`/`WorktreeRemove`). L'isolation y est **physique**, pas conventionnelle : deux
  arbres de travail distincts ne peuvent pas se marcher dessus, quoi que fassent leurs occupants.
- **`1jehuang/jcode`** (étude Phase 9, ADR-053) — d'où vient déjà notre verrou de driver : claim
  unique sous verrou, récupération de claim périmé, DAG à frontière. On ne le remplace pas, on
  **étend son claim** : il revendiquait une étape, il revendiquera aussi une branche et un arbre.

## Ce qu'on fait

**T1 — le claim dit sur QUOI il porte.** `driver-lock.sh acquire` enregistre dans son `meta` la
branche git courante et le chemin du worktree. Champs additifs (`branch=`, `worktree=`) : le
contrat de sortie JSON existant ne perd rien, les consommateurs actuels ne bougent pas.

**T2 — un gate qui constate, et qui parle à TOUT LE MONDE.** Nouveau
`plugin/conductor/scripts/check-branch-claim.sh` : la branche courante est-elle revendiquée par un
lock **actif** (non périmé) posé depuis **un autre arbre de travail** ? Il CONSTATE, il ne décide
pas — même distinction FAIT/JUGEMENT que `check-doc-drift.sh` et `check-mission-invariants.sh`.
Contrat de sortie à 4 codes, sur le patron maintenant établi dans ce dépôt :

| Code | Sens |
|---|---|
| `0` | Branche revendiquée par un autre arbre — signal `[branch-claim]` émis |
| `3` | SAIN — vérifié, personne d'autre ne revendique cette branche |
| `4` | INDÉTERMINÉ — rien n'a pu être vérifié (hors dépôt git, lock illisible) |
| `64` | Erreur d'usage |

**T3 — le signal atteint la session conversationnelle.** Fragment `SessionStart` dans
`plugin/conductor/hooks/`, advisory et en lecture seule, silencieux en nominal. C'est le geste qui
ferme réellement le trou : la session qui nous est passée dessus aurait vu une ligne au démarrage.

**T4 — la doctrine.** ADR-064 : **un écrivain = un worktree**, en complément d'ADR-059 (une
mission = une branche). ADR-059 laissait explicitement `isolation: worktree` en décision ouverte —
on la tranche. `mission-contracts.md` §Isolation de branche porte la règle opérationnelle.

**T5 — tests.** Suite dédiée pour le gate (4 codes de sortie discriminés), et extension de la
suite `driver-lock` pour les deux champs additifs.

## Ce qu'on ne fait pas

- **Aucun blocage dur.** Le gate est advisory. Un hook qui refuserait d'écrire sur une branche
  revendiquée casserait le cas légitime — deux sessions volontairement sur la même branche, ce que
  Samuel fait couramment. ADR-031 : on constate et on prévient, on n'arbitre pas à la place de
  l'humain.
- **Pas de `.worktreeinclude`** ni de hooks `WorktreeCreate`/`WorktreeRemove` : ce sont des
  mécanismes du harness Claude Code, pas du nôtre. On prescrit l'usage de `isolation: worktree`,
  on ne réimplémente pas ce que le harness fournit déjà.
- **Pas de verrou par fichier.** Le grain juste est la branche : c'est là que la collision s'est
  produite, et un verrou par fichier serait une usine à faux positifs.

## Vérification

- Les 4 codes du gate prouvés par exécution sur cas discriminants, pas par lecture.
- Silence nominal du hook prouvé (stdout strictement vide quand personne ne revendique).
- Suites vertes, `check-agents --strict` sur les 6 dossiers, invariants SAIN.
