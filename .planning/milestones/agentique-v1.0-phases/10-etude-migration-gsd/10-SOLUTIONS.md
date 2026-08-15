# Phase 10 — Solutions de migration approfondies (spike prouvé + carte d'adoption)

**Date :** 2026-07-26 · **Complète :** `10-ETUDE.md` · **Règle d'arbitrage (Samuel) :** en cas de
conflit/recouvrement, privilégier la solution **la plus complète et la plus compatible** — jamais
deux briques concurrentes silencieuses (ADR-057).

**Méthode :** (1) spike sur **install réelle sandbox** de `@opengsd/gsd-core` v1.8.0 (HOME isolé,
vrai `~/.claude` prouvé intact avant/après) ; (2) analyse d'adoption sur les **sources du tarball**
(commands/, agents/, hooks/, workflows/, bin/install.js).

---

## 1. Ce que le spike a PROUVÉ (l'étude § risques est levée en grande partie)

| Point | Résultat prouvé |
|---|---|
| Install non-interactive | `npx --yes @opengsd/gsd-core@latest --claude --global` → exit 0, zéro prompt, flags `--global`/`--local` identiques |
| Skills | **71 skills `gsd-*`** posés sous `~/.claude/skills/`, frontmatter identique — `build-gsd-index.sh` sort **exit 0, 71 lignes**, format conforme (D4 intact) |
| SDK | Le binaire **`gsd-sdk` existe toujours** (`@opengsd/gsd-sdk` v1.1.0) ; les 3 requêtes VibeFlow (`init.progress`, `roadmap.analyze`, `state-snapshot`) → **exit 0, JSON à parité** (champs attendus présents). `vf-auto` et `mission-contracts.md` sont **transparents** |
| Layout | `~/.claude/get-shit-done/` **disparaît** → `~/.claude/gsd-core/` (bin/, workflows/ ×91, VERSION=1.8.0). `detect-gsd-engine.sh` avec le défaut actuel → **exit 1 (faux négatif) prouvé** |
| Hooks | L'installeur pose **15+ entrées** dans `settings.json` (guards, context-monitor, scanners) + une `statusLine` + un bloc `permissions` — additifs, pas de collision destructive avec les hooks VibeFlow (matchers différents, Claude Code exécute tous les hooks d'un event) |

**Bilan de casse** : la migration mécanique se réduit à **4 correctifs de chemins/nom de paquet** —
`ensure-deps.sh` (paquet l.120/128 + `GSD_VERSION_FILE` l.53), `detect-gsd-engine.sh` (défaut
`GSD_HOME` l.24, double-chemin), `build-gsd-index.sh` (`WORKFLOWS_DIR` l.27, dégradation douce).
Tout le reste est prouvé transparent.

## 2. Carte d'adoption — les 5 verdicts (règle « plus complet et compatible »)

| # | Confrontation | Verdict |
|---|---|---|
| 1 | **mempalace** vs consolidator 5 piliers | **Composables, périmètres disjoints** : mempalace est opt-in (éteint par défaut), exige le produit tiers MemPalace, mémorise des artefacts de *phase GSD* via le loop-bus interne ; le consolidator reste **le canon de la mémoire de lab** (in-repo, machine-enforced, ADR-052). Ne pas activer, ne pas répliquer — frontière documentée + paire `check-overlaps` |
| 2 | **gsd-mcp-server** vs `inject-mcp-tools.sh` (ADR-051) | **Sans rapport** : sortant (exposer GSD à d'autres runtimes) vs entrant (donner les MCP du lab aux workers). ADR-051 reste indispensable |
| 3 | **/gsd:onboard** vs route first-use (map-codebase → new-project) | **onboard gagne le brownfield** : notre séquence est un sous-ensemble manuel (il ajoute ingestion des docs existants, planning partiel, idempotence, SUMMARY d'onboarding) et il est gated/interactif → BOOT-04 conservé. Router « projet existant avec du code » dessus, fallback ancien chemin si skill absent |
| 4 | **/gsd:next** vs `gsd-progress --next` + agent | **Ne pas router `gsd-next`** : c'est la front door de GSD pour qui n'a PAS d'agent routeur — `vibeflow-dev` EST la front door du lab (empiler deux routeurs = recréer la couche que v2.33.0 a tuée). smart-entry lui-même documente cette frontière |
| 5 | **EoS / hooks / model adapters** vs hooks VibeFlow | **Composition sans collision.** Gain majeur : **model-profiles** (`model_profile`/`models` dans `.planning/config.json`, résolution 3 couches) = la doctrine « opus orchestre, sonnet exécute » enfin **machine-enforced côté moteur**. Vigilance : le merge VibeFlow de settings.json ne doit jamais retirer une entrée `gsd-*` |

## 3. Gains gratuits à l'install (aucun conflit, rien à câbler)

- `gsd-prompt-guard` (anti-injection sur écritures `.planning/`) + `gsd-read-injection-scanner`
  (Read/WebFetch/WebSearch) — une couche sécurité que VibeFlow n'avait pas.
- `gsd-context-monitor` — l'agent est averti des seuils de contexte (pas seulement la statusline).
- `response_language` — workflows GSD en français pour les labs FR.
- Nettoyage automatique des artefacts `get-shit-done-cc` par l'installeur (#607).
- Loop hook bus (`loop-hook-dispatch.md`) — futur point d'extension VibeFlow dans la boucle GSD
  sans fork (ex. capture consolidator à `ship:post`).

## 4. Plan d'intégration Phase 11 (révisé — le spike bloquant est DÉJÀ fait)

Vagues proposées pour `plan-phase 11` :

1. **11-01 — Bascule mécanique** (GSDM-04 partiel) : `ensure-deps.sh` (paquet + VERSION_FILE
   double-chemin), `detect-gsd-engine.sh` (GSD_HOME dual `gsd-core` → legacy), `build-gsd-index.sh`
   (WORKFLOWS_DIR dual) + fixtures de tests à double-layout. Fenêtre de compat : les deux layouts
   détectés tant que des labs legacy existent.
2. **11-02 — Routage amélioré** : `AGENT.md` FIRST-02 → propose `gsd-onboard` sur code existant
   (fallback map+new-project) ; `intent-routing.md` + ligne onboard + note frontière `gsd-next` ;
   paires `consolidator|gsd-mempalace-*` et `vibeflow-dev|gsd-next` dans `check-overlaps.sh`.
3. **11-03 — Cohabitation settings.json** : test machine prouvant que `merge-hooks.sh` /
   `vibeflow-update.sh` n'altèrent jamais les entrées `gsd-*` (référence :
   `managed-hooks-registry.cjs` du tarball) ; vérif `patch_gsd_executor_mcp` sur le nouvel
   `agents/gsd-executor.md`.
4. **11-04 — Doctrine modèles** : `model_profile`/`models` posés par `vf-calibrate`/doctrine dans
   le `.planning/config.json` des labs (enforcement « workers sonnet ») + doc.
5. **11-05 — Non-régression + release** (GSDM-06) : dry-run 3 scopes, idempotence, vrai `~/.claude`
   intact, purge des références legacy vivantes, note de transition labs via `vf-update`, release
   minor + tag.

## 5. Note go/no-go renforcée (GSDM-03)

**GO — confirmé et dérisqué.** L'étude recommandait GO sous réserve du spike de parité SDK : ce
spike est fait et **entièrement vert**. Il ne reste aucun inconnu bloquant ; le coût de bascule
mécanique est de l'ordre de 4 correctifs + tests, et la migration apporte des gains nets
(sécurité, model-profiles, onboard, maintenance vivante). La décision humaine d'ouvrir la
Phase 11 reste le gate (ADR-031).

---
*Preuves : rapport de spike sandbox (HOME isolé, diff ~/.claude vierge) · tarball
`@opengsd/gsd-core@1.8.0` + `@opengsd/gsd-sdk@1.1.0` extraits dans le scratchpad de session ·
sources croisées dans `10-ETUDE.md`.*
