# Phase 10 — Étude de migration GSD : `get-shit-done-cc` → `@opengsd/gsd-core`

**Date :** 2026-07-26 · **Couvre :** GSDM-01 (surface d'usage), GSDM-02 (caractérisation cible),
GSDM-03 (note go/no-go) · **Méthode :** inventaire sur disque + recherche sourcée (npm, GitHub,
inspection directe du tarball 1.8.0).

---

## 1. Surface d'usage GSD dans VibeFlow (GSDM-01)

État local au 2026-07-26 : GSD `1.42.3` (`~/.claude/get-shit-done/VERSION`), binaire `gsd-sdk`
v1.42.3, **67 skills `gsd-*`** sous `~/.claude/skills/`.

| Point de contact | Usage actuel | Changement attendu |
|---|---|---|
| `plugin/dev-orchestrator/scripts/ensure-deps.sh` (l.5, 120, 128) | `npx -y get-shit-done-cc@latest --claude $GSD_SCOPE_FLAG` | Package → `@opengsd/gsd-core@latest`. Flags `--claude`/`--global`/`--local` **conservés** à l'identique. Prévoir le nettoyage des artefacts legacy (l'installeur 1.8.0 le fait lui-même). |
| `plugin/planning-core/scripts/detect-gsd-engine.sh` (l.13, 24) | `GSD_HOME=$HOME/.claude/get-shit-done` | **Chemin cassé** : le payload devient `~/.claude/gsd-core/`. Détection à double-chemin pendant la fenêtre de compat, puis bascule. |
| `plugin/dev-orchestrator/scripts/build-gsd-index.sh` | Scan `$HOME/.claude/skills` pour les `gsd-*` (VF_GSD_SKILLS_DIR) | **A priori inchangé** — les skills restent sous `~/.claude/skills` avec le préfixe `gsd-`. À re-prouver sur une install réelle (l'index est le filet anti-hallucination). |
| Binaire `gsd-sdk` — `vf-auto/SKILL.md:18`, `references/mission-contracts.md:72`, whitelist `test-dev-orchestrator.sh:260` | `gsd-sdk query roadmap.analyze`, `init.progress`, `state-snapshot` | **Bin disparu sous ce nom.** gsd-core expose `gsd-core` / `gsd-tools` / `gsd_run` / `gsd-mcp-server` ; le SDK vit dans le package séparé `@opengsd/gsd-sdk` (v1.1.0). **Parité de l'API `query` à prouver en Phase 11** (spike ciblé). |
| Pins & docs — `.planning/PROJECT.md:43,61`, docs génériques | `get-shit-done-cc` nommé | Renommage simple. |

Aucun autre point de contact vivant (les mentions restantes sont dans CHANGELOG/specs/archives,
à leur place).

## 2. Caractérisation de `@opengsd/gsd-core` (GSDM-02)

- **Identité** : continuation communautaire de GSD après l'abandon de l'original — mainteneur
  original injoignable depuis le 2026-04-01 (token `$GSD` rug-pull, repo verrouillé) ; fork
  lancé le 2026-05-22 par trek-e (collaborateur du projet original) sous l'org `open-gsd`,
  code MIT miroité bit-for-bit, 3 mainteneurs npm. Sources : Discussion #109, issue #518.
- **Maturité** : v1.8.0 (2026-07-22), 32 versions en 8 semaines, **10 499 téléchargements/sem
  — il a dépassé l'original déprécié** (10 280). ~7,2 k stars, communauté active.
  ⚠️ versionnage **reparti à 1.x** — ne jamais comparer à `get-shit-done-cc@1.42.3`.
- **Parité** : vérifiée dans le tarball 1.8.0 — 61 commandes `gsd-*` (sur-ensemble strict du
  set VibeFlow) + 34 agents. Flags d'install conservés.
- **Dépréciation amont** : `get-shit-done-cc` est déprécié sur **toutes** ses versions
  (libellé staff npm), dernière publication 2026-05-17. Guide de migration officiel :
  Discussion #433 (uninstall propre → nettoyage artefacts → `npx --yes @opengsd/gsd-core@latest`).
  Coexistence non supportée (l'installeur purge les artefacts legacy).

## 3. Ce qui est mieux / nouveau

1. **Maintenance vivante** vs package mort : releases hebdomadaires, issues traitées, Discord —
   l'original n'aura plus jamais ni fix ni compat Claude Code.
2. **Multi-runtime** (~15 runtimes : Claude Code, Codex, Cursor, OpenCode, Copilot…) avec
   conversion de frontmatter — aligné avec la promesse multi-métier/multi-contexte de VibeFlow.
3. **EoS (Embeddable Orchestration System)** v1.7/1.8 : hook bus, model adapters, modules MCP —
   et un **serveur MCP compagnon** (`gsd-mcp-server`), intéressant pour l'injection MCP ADR-051.
4. **Nouvelles commandes** : `/gsd:onboard` (brownfield), `/gsd:next`, et le système mémoire
   `mempalace-capture`/`mempalace-recall` + agent `gsd-mempalace-curator` — recouvrement
   potentiel avec le pilier 5 du consolidator, à cartographier (ADR-057, check-overlaps).
5. **Sécurité de la chaîne** : rester sur un package npm déprécié au mainteneur disparu dans un
   contexte de compromission est le vrai risque — la migration le solde.

## 4. Risques & écarts

| Risque | Sévérité | Mitigation |
|---|---|---|
| Chemin `~/.claude/get-shit-done/` → `~/.claude/gsd-core/` | Certain | `detect-gsd-engine.sh` à double-chemin + fixtures ; bascule en Phase 11 |
| `gsd-sdk` disparu (bins renommés, SDK séparé) | Certain | Spike de parité `@opengsd/gsd-sdk` sur les 3 requêtes utilisées (`init.progress`, `roadmap.analyze`, `state-snapshot`) AVANT toute bascule |
| Référentiel de versions reparti à 1.x | Certain | Purger tout comparateur/pin fondé sur 1.42.x |
| Recouvrement mempalace ↔ consolidator pilier 5 | Possible | `check-overlaps.sh` (ADR-057) après install ; pas de désactivation silencieuse |
| Fork jeune (2 mois), leadership de fait | Faible | 3 mainteneurs, org dédiée, communauté basculée ; réévaluer au premier signal de ralentissement |
| Labs existants avec l'ancien layout | Réel | L'installeur amont purge le legacy ; `vf-update`/`vf-calibrate` doivent accompagner la transition des labs |

## 5. Note go/no-go (GSDM-03)

**Recommandation : GO — migrer, avec fenêtre de compatibilité.** Rester est le scénario le plus
risqué (package déprécié, mainteneur disparu, zéro correctif à venir), la cible est à parité
fonctionnelle stricte-supérieure et désormais dominante en adoption.

**Stratégie proposée (Phase 11, conditionnée à la validation humaine de ce GO) :**
1. **Spike de parité SDK** (bloquant) : installer `@opengsd/gsd-core` + `@opengsd/gsd-sdk` en
   environnement isolé, prouver les 3 requêtes `query` et l'index (`build-gsd-index.sh`) sur
   l'install réelle.
2. **Fenêtre de compat** : `detect-gsd-engine.sh` accepte les deux `GSD_HOME` ; `ensure-deps.sh`
   bascule sur `@opengsd/gsd-core` ; les références `gsd-sdk` migrent vers le nouveau binaire
   prouvé au spike.
3. **Non-régression isolée** (GSDM-06) : dry-run 3 scopes + idempotence, vrai `~/.claude`
   intact, puis release bumpée + tag.
4. **Post-bascule** : `check-overlaps.sh` sur mempalace, purge des références legacy, note de
   transition pour les labs via `vf-update`.

**Déclencheur de réévaluation si NO-GO retenu malgré tout** : premier incident de compat
Claude Code non corrigeable sur `get-shit-done-cc` (il ne le sera jamais en amont).

---
*Sources : npm @opengsd/gsd-core + registre brut · repo open-gsd/gsd-core · Discussions #109,
#433 · Issue #518 · docs install-on-your-runtime · api.npmjs.org (downloads) · tarball 1.8.0
(commandes, agents, install.js) · npm get-shit-done-cc (dépréciation).*
