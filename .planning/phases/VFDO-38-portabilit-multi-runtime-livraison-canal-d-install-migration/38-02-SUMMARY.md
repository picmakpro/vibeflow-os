---
plan: 38-02
requirements: [RUNT-01, RUNT-02]
status: complete
---

# Phase 38 Plan 02: Installeur multi-runtime — Summary

**Les sites CLI-couplés ne sont plus figés sur `claude` : une détection de runtime + une table de
dispatch portent les 4 verbes (`list --json`, `install`, `enable`, `marketplace add`) sur les
4 fichiers concernés, et un runtime non supporté produit une dégradation DÉCLARÉE (étapes manuelles
affichées, code de sortie propre) — jamais un échec silencieux.**

> ⚠️ **Ce SUMMARY est écrit APRÈS coup (2026-08-29), à la clôture de la phase.** Le lot a été livré
> puis corrigé par des mandats ciblés successifs (revue, revue de jointure, mesure OpenCode/kimi),
> et le cycle plan→exécution ne s'est jamais refermé sur lui — d'où l'absence initiale. Le contenu
> ci-dessous est reconstitué **sur pièces** (commits, suites rejouées à la clôture), jamais de
> mémoire.

## Accomplishments

- **RUNT-01** — `plugin/_internal/runtime-cli-dispatch.sh` (**script partagé neuf**) porte la
  détection de runtime et la table de dispatch. Les sites CLI-couplés de
  `plugin/dev-orchestrator/scripts/ensure-deps.sh`, `plugin/design-orchestrator/scripts/ensure-design-deps.sh`,
  `plugin/conductor/scripts/check-plugin-update.sh` et `plugin/conductor/scripts/vf-update-run.sh`
  y passent.
  ⚠️ **Le périmètre réel était plus large que le cadrage** : l'étude 37 annonçait 11 sites sur
  2 fichiers (motif `claude plugin install|command -v claude`) — exact **sur son propre motif**,
  mais le couplage porte sur **4 verbes** et **12 sites exécutables sur 4 fichiers**.
- **RUNT-02** — runtime non détecté ou non supporté → **dégradation déclarée**, vérifiée en
  exécution (runtime inconnu, runtime absent, verbe inconnu, aucun verbe) : sortie propre, jamais
  de crash.
- **Préconditions Codex** — `features.multi_agent_v2` posé/vérifié (sans lui **aucun outil de spawn
  n'existe**), et `trust_level` **DÉCLARÉ sans jamais être auto-écrit** (ADR-031 : écrire dans la
  config de confiance de l'utilisateur à sa place est hors limites ; aucune commande `codex trust`
  n'a été mesurée).

## Task Commits

| commit | objet |
|---|---|
| `2d392a7` | `runtime-cli-dispatch.sh` + `test-runtime-cli-dispatch.sh` (script partagé neuf) |
| `877a97d` | `ensure-deps.sh` routé par le dispatch · bump `dev-orchestrator` |
| `d6ff0d4` | `ensure-design-deps.sh` (5 sites), `check-plugin-update.sh`, `vf-update-run.sh` · bumps `design-orchestrator` et `conductor` |
| `f9f7dc4` | compteur de suites des deux README (commit **séparé**, comme exigé) |

### Correctifs post-revue (mandats ciblés, hors cycle du plan)

| commit | objet |
|---|---|
| `40c8f0f` | garde T9e resserré à la ligne exacte · « confirmé » → « assumé, non mesuré » · test T9h exerçant le chemin dispatch réel |
| `c6e5c60` | T9e raisonne à l'**occurrence** et non à la ligne physique — **preuve générative** : 60 combinaisons, **8 rouges avant / 0 après** |
| `c8dea13` | 🔴 **bloquant de la revue de jointure** — `runtime-cli-dispatch.sh` n'était **posé nulle part** sous `$TARGET_ROOT/scripts/` |
| `45cb868` | alignement de la résolution de racine `trust_level` entre les deux gardes |
| `f0973f1` | sonde **kimi-code par capacité** (`--output-format`), plus par nom de binaire |

## Files Created/Modified

`plugin/_internal/runtime-cli-dispatch.sh` (**neuf**) · `plugin/_internal/tests/test-runtime-cli-dispatch.sh` (**neuf**) ·
`plugin/dev-orchestrator/scripts/ensure-deps.sh` · `plugin/design-orchestrator/scripts/ensure-design-deps.sh` ·
`plugin/conductor/scripts/check-plugin-update.sh` · `plugin/conductor/scripts/vf-update-run.sh` ·
`plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh` · `README.md` · `README.fr.md` ·
triades de version de `dev-orchestrator`, `design-orchestrator`, `conductor`.

## Decisions Made

- **Sonde `kimi-code` par CAPACITÉ, pas par nom de binaire.** Le binaire réel s'appelle `kimi`, et
  `kimi` (Python, kimi-cli) **partage ce nom** — sonder `kimi` confondrait deux produits distincts.
  Retenue : la sonde `command-capability` déjà définie par gsd-core (`binary: "kimi"`,
  needle `--output-format`), **validée contre le binaire réel** (kimi 0.39.1) par le manager.
- **`trust_level` déclaré, jamais écrit** (ADR-031).
- **Aucune grammaire d'install Codex inventée.** La mesure de bout en bout a démenti l'hypothèse
  « même grammaire que `claude` » : `codex plugin install` et `marketplace add --scope` **n'existent
  pas**. L'erreur est **relayée**, jamais avalée.

## Deviations from Plan

**1. [Garde de doctrine desserré dans le commit qui en bénéficie]** — `d6ff0d4` a modifié le garde
T9e (autonomie D-04) de `test-design-orchestrator.sh` **et** le code que ce garde protège, en
affirmant au CHANGELOG « sans affaiblir la garde ». La revue en régime plein a prouvé **par
mutation** que la garde **était** affaiblie (filtre par sous-chaîne, puis par ligne physique).
→ Exception **ratifiée** par Samuel (**D-38-M** : `plugin/_internal/` est le socle, hors D-04 — ni
`VERSION`, ni `module.json`, ni `CHANGELOG.md` ; précédent `find_engine_lib()`/`find_hooks_merger()`),
garde **resserré à l'occurrence**, et **règle de procédure D-38-N** posée au kernel : *un lot ne
desserre jamais son propre garde dans le commit qui en bénéficie*.

**2. [Écriture hors périmètre déclaré]** — deux fichiers **neufs** créés sous `plugin/_internal/`
malgré l'interdit du mandat. Constaté par le manager : **aucune collision** (`vibeflow-update.sh`
jamais touché) — l'interdit du manager était **trop large**, il visait un seul fichier.

**Total deviations :** 2, toutes deux **déclarées par le worker**, aucune tue.

## Non-régression (rejouée à la clôture, 2026-08-29)

`test-runtime-cli-dispatch.sh` **15 OK / 0 KO** · `test-design-orchestrator.sh` **29 OK / 0 KO** ·
`test-dev-orchestrator.sh` **188 OK / 0 KO**. Découverte complète du dépôt : **75 suites / 0 échec**.

## Next Phase Readiness

RUNT-01/02 sont livrés et vérifiés côté Claude et Codex. ⚠️ **Ce qui reste non prouvé** : la
commande d'install Codex **après** `codex plugin marketplace add` — l'enchaînement complet jusqu'à
une dépendance réellement posée n'a jamais été exercé (les 4 dépendances design étaient
**manquantes** à la mesure de bout en bout). Les commandes OpenCode et kimi-code restent
**documentaires**.
