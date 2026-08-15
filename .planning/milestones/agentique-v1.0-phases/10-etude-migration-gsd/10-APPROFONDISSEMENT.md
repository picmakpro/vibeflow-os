# Phase 10 — Approfondissement final : specs prêtes à planifier

**Date :** 2026-07-26 · **Complète :** `10-ETUDE.md` + `10-SOLUTIONS.md` · **Sources :** deep-dive
cohabitation hooks (dry-run réel sur le settings.json sandbox), specs d'implémentation (lecture
intégrale ensure-deps / merge-hooks / install.js / legacy-cleanup.cjs / model-profiles.md),
arbitrage SDK vérifié sur le registre npm + parité re-prouvée empiriquement.

---

## 0. Arbitrage SDK — conflit entre volets, TRANCHÉ

Deux constats contradictoires : le spike a prouvé `@opengsd/gsd-sdk` fonctionnel (bin `gsd-sdk`,
3 requêtes vertes) ; les specs affirmaient le paquet inexistant. Vérification registre :
**le paquet existe (v1.1.0) MAIS il est DÉPRÉCIÉ** (« Package no longer supported » — cohérent
avec l'issue #518 : le SDK est absorbé dans gsd-core sous `gsd-tools`).

**Décision (règle « plus complet et compatible ») : `gsd-tools` gagne.** S'appuyer sur un paquet
déprécié recréerait la situation get-shit-done-cc. Parité **prouvée empiriquement** sur la
fixture sandbox :

| Référence VibeFlow actuelle | Équivalent gsd-tools (prouvé exit 0, JSON conforme) |
|---|---|
| `gsd-sdk query init.progress` | `gsd-tools init progress` |
| `gsd-sdk query roadmap.analyze` | `gsd-tools roadmap analyze` |
| `gsd-sdk query state-snapshot` | `gsd-tools state json` (snapshot court) / `state load` (complet) |

Invocation canonique (celle des workflows gsd-core eux-mêmes) :
`node "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/gsd-core/bin/gsd-tools.cjs" <cmd>` — aucun paquet npm
supplémentaire à installer, le runtime arrive avec l'installeur. Sites à migrer :
`vf-auto/SKILL.md:18`, `references/mission-contracts.md:72-73`, whitelist
`test-dev-orchestrator.sh:260`.

## 1. Cohabitation settings.json — verdicts prouvés (dry-run réel)

- **(a) merge VibeFlow par-dessus gsd-core → SAIN** : 0 entrée gsd perdue, statusLine/permissions
  byte-identiques. Réserve : 3 « groupes mixtes » créés (append dans un groupe de même matcher).
- **(b) uninstall VibeFlow → SAIN** : hooks restaurés deep-equal à l'origine.
- **(c) double re-merge → SAIN** : idempotent, zéro doublon.
- **(d) re-run installeur gsd-core par-dessus VibeFlow → SAIN** (additif, `managed-hooks-registry`
  borne son périmètre, uninstall gsd granulaire par hook) — 2 risques latents liés aux groupes
  mixtes : migration #338 (scope local) peut déplacer des entrées entières vers
  `settings.local.json` → double exécution après re-merge VF ; `cleanupOrphanedHooks` supprime
  des entrées entières → perte collatérale d'un hook VF co-localisé.
- Stop bloquant (`guard-planning-updated` VF) × Stop advisory gsd : cumul sans conflit — sur
  projet GSD le garde est quasi désamorcé par le signal mtime `.planning` (esprit ADR-055).
- Double bandeau update : non — `gsd-check-update` est silencieux (statusline), un seul
  `systemMessage` VibeFlow.

**Correctif préventif spécifié** (`plugin/_internal/merge-hooks.sh`, bloc Python) :
1. *Matching ancré* : remplacer le test sous-chaîne (`b in command`) par une regex ancrée aux
   frontières de chemin (miroir d'`isManagedHookCommand`) — aujourd'hui `archive.sh` détruirait
   une entrée tierce `gsd-archive.sh`.
2. *Fin de la co-location* : ne réutiliser un groupe de même matcher que s'il est possédé par VF
   (tous ses hooks ∈ fragment), sinon créer un groupe — neutralise les 2 risques latents.

**Suite de test spécifiée** : `plugin/_internal/tests/test-gsd-cohabitation.sh` + fixture
`fixtures/gsd-core-settings.json` (copie du settings sandbox) — T1 merge sans perte (ensemble
(event, commande) gsd ⊂ résultat, statusLine/permissions deep-equal) · T2 remove restaurateur ·
T3 idempotence · T4 non-mixité post-correctif · T5 anti-collision suffixe (`gsd-archive.sh`
survit au merge consolidator).

## 2. Runbook labs legacy — séquence et piège n°1

**Piège n°1 de toute la phase** : `detect_gsd()` teste `command -v gsd-sdk` — le shim legacy
(`@gsd-build/sdk` 1.42.3, npm -g sous préfixe Homebrew, symlinké dans le cache npx) reste sur le
PATH après migration → la détection serait toujours vraie et **gsd-core ne serait jamais
installé**. Le test PATH DOIT disparaître de `detect_gsd` (remplacé par les VERSION files
`~/.claude/gsd-core/VERSION` puis `./.claude/gsd-core/VERSION`).

Séquence de transition (pseudo-diff complet dans le rapport de specs, repris au plan 11-01) :
1. `vf-update` pose le module migré ; 2. `ensure-deps` migré installe
   `npx -y @opengsd/gsd-core@latest --claude $GSD_SCOPE_FLAG` (BOOT-01, non-interactif — prouvé) ;
   l'installeur amont nettoie hooks/commands/skills legacy dans le même geste ;
3. `detect_gsd_legacy()` (nouveau) **affiche sans jamais exécuter** les 3 étapes manuelles
   (ADR-031) : `npm uninstall -g get-shit-done-cc` · `npm uninstall -g @gsd-build/sdk` ·
   `rm -rf ~/.claude/get-shit-done` (arbre mort NON supprimé par l'installeur) ;
4. `patch_gsd_executor_mcp` inchangé (chemin agents/ conservé) ; 5. l'index régénéré inclut
   onboard/next/mempalace → **les specs routage/frontières doivent shipper dans la même release**
   (sinon T14 casse).

**Pin** : rester `@latest` + détection par VERSION file (un pin enterré dans un `.sh` est
exactement le pin qui pourrit — preuve : 1.40.0 vs 1.42.3) ; garde-fou Node ≥ 22 ajouté au
message de fallback manuel.

## 3. model-profiles — la doctrine devient machine-enforced

La doctrine « planner=opus, executor/verifier=sonnet » **est littéralement le profil
`balanced`** — qui est le défaut GSD (confirmé empiriquement : `gsd-tools state load` →
`"model_profile": "balanced"`). Le poser **explicitement** dans `.planning/config.json` protège
d'un changement de défaut amont et du piège `inherit` (un worker sonnet qui invoque
`gsd-plan-phase` tirerait gsd-planner vers sonnet).

- **Nouveau lab** : assertion d'une ligne par `vibeflow-dev` après `gsd-new-project` (section
  hygiène documentaire d'`AGENT.md`).
- **Lab existant** : étape `vf-calibrate` (proposer, validation humaine).
- **Frontière** : le `model:` frontmatter de nos agents vf-* (processus Claude Code) et le profil
  GSD (sous-agents gsd-*) sont des couches indépendantes — la chaîne
  `vf-coder (sonnet) → gsd-plan-phase → gsd-planner (opus)` est le comportement voulu. Une
  phrase dans `GSD-PIPELINE.md`.

## 4. Routage onboard + frontières — diffs exacts prêts

- `AGENT.md` FIRST-02 (158 L, marge 92) : proposer `gsd-onboard` si du code existe (détection
  d'absence via l'index `gsd-skills-index.md`, fallback map-codebase → new-project), BOOT-04
  intact, markers T7 conservés. Diff exact dans le rapport de specs.
- `intent-routing.md` : ligne « onboarde ce codebase / repo légué » → `gsd-onboard` + **canal 4
  « Non routé — une seule voix (ADR-057) »** : `gsd-next` (le next step est porté par l'agent)
  et `gsd-mempalace-*` (mémoire = chasse gardée du consolidator).
- `check-overlaps.sh` : 3 lignes KNOWN_PAIRS exactes (mempalace-capture, mempalace-recall,
  gsd-next — pas de glob supporté, paires éclatées) + tests T15/T16 spécifiés.
- T14 (exhaustivité) : `gsd-next`/`gsd-mempalace-*` entrent dans l'exception écrite ET la
  whitelist du test — la règle du fichier exige les deux.

## 5. Plan de Phase 11 — révision finale (6 vagues)

1. **11-01 Bascule mécanique** : ensure-deps (paquet ×2, VERSION dual, `detect_gsd` sans PATH,
   `detect_gsd_legacy` + 3 étapes manuelles loguées, garde Node ≥ 22), detect-gsd-engine dual,
   build-gsd-index WORKFLOWS_DIR dual, fixtures double-layout.
2. **11-02 Références SDK → gsd-tools** : vf-auto, mission-contracts, whitelist test (mapping
   prouvé §0).
3. **11-03 Routage & frontières** : AGENT.md FIRST-02, intent-routing (onboard + canal 4),
   check-overlaps 3 paires + T15/T16, whitelist T14 — même release que 11-01 (contrainte index).
4. **11-04 Cohabitation settings.json** : correctif merge-hooks (matching ancré + non-mixité) +
   suite test-gsd-cohabitation T1-T5 + fixture sandbox.
5. **11-05 Doctrine modèles** : assertion `model_profile: balanced` (AGENT.md hygiène +
   vf-calibrate + phrase GSD-PIPELINE).
6. **11-06 Non-régression + docs** (GSDM-06) : dry-run 3 scopes, idempotence, vrai `~/.claude`
   intact, purge références legacy vivantes, CHANGELOG/README modules, note de transition labs.
   **Release racine : préparée mais HORS mandat mission (validation humaine).**

---
*Artefacts de preuve conservés dans le scratchpad de session : sandbox `gsd-spike/` (home isolé,
fixtures, index généré), tarball `gsd-adoption/gsd-core/`, dry-runs `cohab-dryrun/`.*
