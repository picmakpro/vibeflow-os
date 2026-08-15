# Phase 27: Parallélisation d'exécution — granulaire, simple, sans collision d'écriture - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-05
**Phase:** 27-Parallélisation d'exécution — granulaire, simple, sans collision d'écriture
**Areas discussed:** Aucune — cadrage non interactif, voir note ci-dessous.

---

## Note de méthode — pourquoi ce cadrage n'a pas utilisé `AskUserQuestion`

Ce cadrage a été produit par `vf-coder`, un worker interne du team-kernel sans outil de question
interactive (ADR-053 : un worker interne ne parle pas à l'utilisateur). Contrairement à la Phase 24
(où 6 zones grises ont dû être instruites puis remontées en arbitrage séparé), la Phase 27 arrive avec
un pré-cadrage déjà très détaillé — ROADMAP §Phase 27 (110 lignes), une spec de design dédiée
(225 lignes), une recherche dédiée (497 lignes) — et **deux décisions déjà tranchées par Samuel**
(décisions A et B, injectées par le digest de mission du manager).

**Démarche appliquée en lieu et place de l'`AskUserQuestion` interactif du workflow standard :**
1. Chaque gray area potentielle a été identifiée par lecture croisée du ROADMAP, de la spec et de la
   recherche.
2. Chacune a été répondue depuis une source citée (fichier + ligne), jamais inventée.
3. Les faits cités ont été **re-vérifiés sur disque ce jour** (2026-08-05) quand cela restait dans le
   périmètre du cadrage : lignes de `team-kernel.md:64-68`, contenu de `.planning/config.json`,
   absence de `worktree` dans `.gitignore`, absence de `.worktreeinclude`, gate `isolation` de
   `check-agents.sh`, `0/25` agents déclarant `isolation`.
4. Une vérification explicite « aucune escalade nécessaire » a été menée question par question — voir
   `<escalations>` de `27-CONTEXT.md`. Aucune zone grise résiduelle n'a résisté aux sources
   disponibles.

**Résultat :** aucun `AskUserQuestion` n'a été nécessaire, et aucun fichier d'arbitrage séparé
(`27-ARBITRAGES.md`) n'a été produit — il n'y avait rien à arbitrer.

---

## Claude's Discretion

Voir `27-CONTEXT.md` §`<decisions>` → « Claude's Discretion » pour la liste complète (mécanisme de
câblage `dag.sh` ↔ `partitionStages()`, contenu du `.worktreeinclude`, liste exacte des agents
recevant `isolation: worktree`, design du spike, corpus de mesure du gain, découpage en plans).

## Deferred Ideas

Voir `27-CONTEXT.md` §`<deferred>` (Option 3 en réserve, remontée upstream, item `STATE.md:768-772`
à clore en fin de phase).
