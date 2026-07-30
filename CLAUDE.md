# CLAUDE.md — vibeflow-os

Guidance pour Claude Code quand il travaille **sur ce repo** (le repo de distribution du plugin
VibeFlow, pas un lab qui l'installe).

## Ce qu'est ce repo

Marketplace + plugin Claude Code à **modules toggables** sous `plugin/`. Chaque module a son
`VERSION`, son `module.json`, son `CHANGELOG.md`, son `README.md`. L'engine d'install scopé vit
dans `plugin/_internal/vibeflow-update.sh`. La doc méthodologique de référence (Core, patterns) est
dans `plugin/reference/`. Le socle de gouvernance est le module `conductor`.

## Règle non négociable — Discipline de release : toute version = un tag

> **Toute release (bump de la `VERSION` racine) DOIT créer et pousser un tag git annoté `vX.Y.Z`
> pointant sur le commit de release.**

Une version sans tag n'est ni traçable ni installable par référence. C'est précisément ce qui a
fait diverger `main` en juillet 2026 : v2.10.0 → v2.16.0 publiées sans jamais être taggées, états
intermédiaires irretrouvables.

**À chaque release :**

1. **Bump cohérent** du même numéro dans les trois fichiers : `VERSION`,
   `plugin/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` — plus l'historique des
   deux README (`README.md` **et** `README.fr.md`, badges inclus).
2. **Après le merge sur `main`**, crée et pousse le tag annoté :
   ```bash
   git tag -a vX.Y.Z -m "vX.Y.Z — <résumé>" <commit-de-release>
   git push origin vX.Y.Z
   ```
3. **Crée la release GitHub** sur le tag (titre court, notes = résumé du tag + commits couverts) :
   ```bash
   gh release create vX.Y.Z --title "vX.Y.Z — <résumé court>" --notes "<résumé + liste des commits depuis le tag précédent>" --verify-tag
   ```
   Un tag sans release GitHub rend la page Releases mensongère — c'est ce qui s'est produit de
   v2.29.0 à v2.39.0 (14 versions taggées, page bloquée sur v2.28.0, rattrapage le 2026-07-26).
4. **Vérifie** : `bash scripts/check-release-tag.sh --remote` → doit sortir `✓` (le gate vérifie
   le tag local, le tag poussé **et** la release GitHub).

**Garde-fou machine** : `scripts/check-release-tag.sh` échoue (exit 1) si la `VERSION` courante n'a
pas son tag. Câblage `pre-push` optionnel (bloque uniquement les push vers `main`) :
`git config core.hooksPath scripts/hooks` (une seule fois par clone).

**Numérotation** : `vMAJOR.MINOR.PATCH`. Nouveau module / nouvelle capacité → **minor** ;
correctif / doc / durcissement → **patch**. Le tag reprend **exactement** la valeur de `VERSION`
(préfixe `v` inclus).

### Le bump ne se fait jamais dans une branche de travail

> **Les trois fichiers de version — `VERSION`, `plugin/.claude-plugin/plugin.json`,
> `.claude-plugin/marketplace.json` — ne sont bumpés que dans un commit de release DÉDIÉ, sur
> `main`, par une seule personne à la fois.**

Le dépôt est développé sur deux polarités parallèles (gouvernance/métier et dev — voir
`.github/CODEOWNERS`). Ces trois fichiers sont touchés par *toute* release : les bumper dans une
branche de travail garantit un conflit à chaque merge, sur des fichiers où un mauvais arbitrage
casse la traçabilité de version. Une branche de travail ne contient donc **jamais** de bump ; elle
livre la capacité, et la release qui la publie est un commit séparé.

## Cohabitation des deux polarités

- **Séparer les commits `plugin/` et `.planning/`.** Ne jamais mélanger code de module et artefacts
  de planning dans un même commit : c'est la condition pour que `/gsd-pr-branch` puisse produire
  une branche de PR filtrée de `.planning/`, où le relecteur ne voit que le code.
- **Fusion des fichiers append-only** : `.gitattributes` applique `merge=union` à `MILESTONES.md`,
  `BACKLOG.md` et aux `CHANGELOG.md`. Ne **jamais** l'étendre à `ROADMAP.md` ni `STATE.md`, qui
  sont réécrits en place.
- **États parallèles** : `ROADMAP.md`/`STATE.md` sont mono-position et ne peuvent pas décrire deux
  chantiers simultanés. Le planning est donc **partitionné en workstreams** :
  `.planning/workstreams/<nom>/` porte `ROADMAP.md`, `STATE.md`, `REQUIREMENTS.md` et `phases/`,
  tandis que `PROJECT.md`, `BACKLOG.md`, `MILESTONES.md`, `config.json`, `codebase/`, `research/`
  et `missions/` restent **partagés**.

### Règles d'usage des workstreams (vérifiées en bac à sable le 2026-07-30)

Le mécanisme est sain sur son cœur — migration sans perte (checksums identiques), isolation réelle
entre workstreams — mais il a des angles morts documentés. Ces quatre règles ne sont pas
optionnelles :

1. **Toujours passer `--ws <nom>` explicitement** sur toute commande qui écrit. Ne jamais compter
   sur le pointeur de session implicite : il est résolu depuis `CLAUDE_CODE_SSE_PORT`, or un port
   TCP est **recyclé par l'OS** et le code ne vérifie ni horodatage ni liveness — une session peut
   hériter silencieusement du workstream d'une session morte.
2. **Une clé de session stable par personne** : exporter `GSD_SESSION_KEY=<prénom>` dans son shell,
   ce qui prime sur le port dans la cascade de résolution et supprime le risque ci-dessus.
3. **`/gsd-complete-milestone` est INTERDIT en mode workstream** tant qu'il n'est pas corrigé en
   amont : son workflow ne contient aucune référence au workstream actif et code en dur
   `.planning/ROADMAP.md`, `.planning/phases/` et un `git rm .planning/REQUIREMENTS.md` (vérifié
   sur gsd-core v1.8.0 — 0 occurrence de `GSD_WS`, contre 15 dans `execute-phase`, 29 dans
   `progress`). En mode workstream ces chemins n'existent plus à la racine.
4. **`workstream.complete` n'est PAS un retour arrière** malgré son `reverted_to_flat: true` : il
   archive au lieu de restaurer. Le seul rollback fiable est
   `git reset --hard <commit-pré-migration> && git clean -fd` — le `reset` seul laisse des
   dossiers non suivis. C'est pourquoi une migration se committe **seule et immédiatement**.

Nommer les workstreams en **ASCII simple** : le slugifieur perd une majuscule accentuée en tête de
nom au lieu de la translittérer.

## Conventions transverses

- **Densité** (ADR-029) : agents ≤ 250 lignes, skills ≤ 500, bootstrap ≤ 2000 tokens.
- **Jamais de fix sans validation humaine** (ADR-031).
- **Agents natifs machine-enforced** (ADR-044) : tout agent posé passe `plugin/conductor/scripts/check-agents.sh`
  (description + model + memory requis). Un worker **interne** (dispatché uniquement par un
  orchestrateur) déclare `vf-internal: true` → pas de commande d'incarnation exposée (Pattern 12).
- **Commits** : messages en français, cohérents avec l'historique du repo.
