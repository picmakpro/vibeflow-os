# Mission — Phase 19 : Migration du moteur GSD pilotée par `/vf-update`

**Date :** 2026-07-28 · **Manager :** `vf-dev-manager` · **Mode :** autonome (aucun checkpoint humain)
**Milestone :** `gsd-migration` · **Verdict :** `19-VERIFICATION.md` **PASS, 6/7 critères**
**DAG :** `.planning/missions/dag-phase19.json` (5 nœuds, 1 `reopen`)
**Verrou de driver :** `mission-phase19`, tenu du plan à la clôture, heartbeat continu (leçon Phase 16)

---

## Plan de bataille (arrêté avant tout dispatch)

| Nœud | Étage | Périmètre déclaré | Dépendances |
|------|-------|-------------------|-------------|
| n1 | plan | `.planning/phases/VFDO-19-*/` | — |
| n2 | build | `plugin/dev-orchestrator/scripts/**`, `plugin/conductor/skills/vf-update/`, `docs/ADR.md`, release-meta des 2 modules | n1 |
| n3 | verify | gate portabilité Linux + macOS, read-only | n2 |
| n4 | verify | audit sécurité/infra, read-only | n2 |
| n5 | close | `VERIFICATION`, `STATE`/`ROADMAP`/`CONCERNS`, rapport | n3, n4 |

**Cadrage non refait.** `19-CONTEXT.md` portait 6 arbitrages tranchés par Samuel en conversation
(D-01 gate dédié + sonde best-effort · D-06 `--migrate-engine` sans sauvegarde tar · D-07 détection
moteur AVANT le stop de l'étape 1 · D-08 nettoyage proposé jamais exécuté · D-09 `--verify` ·
D-11 suite dédiée). Aucun panel, aucune re-soumission : la mission a démarré sur `gsd-plan-phase`.

**Pas de pipelining N/N+1** (une seule étape au périmètre), **pas d'étage design** (`design: off`,
phase 100 % bash + markdown).

---

## Ce qui est livré

| Artefact | Nature |
|---|---|
| `plugin/dev-orchestrator/scripts/check-gsd-engine.sh` | **créé** — gate à 3 états `absent`/`legacy`/`gsd-core`, exits `0`/`2`/`3` |
| `plugin/dev-orchestrator/scripts/tests/test-check-gsd-engine.sh` | **créé** — suite dédiée, 15 cas |
| `plugin/dev-orchestrator/scripts/ensure-deps.sh` | détecteur à 3 valeurs, fin du `skip` sur legacy, chemin `--migrate-engine` chaîné sur la ré-injection MCP, message de nettoyage exact et atteignable |
| `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` | mode `--verify` |
| `plugin/conductor/skills/vf-update/SKILL.md` | diagnostic à deux volets, ligne de confirmation moteur indépendante, §Garde-fous réécrit |
| `docs/ADR.md` | **ADR-058** — le moteur GSD entre dans le périmètre de `/vf-update` |
| release-meta | `dev-orchestrator` **v2.7.0**, `conductor` **v1.16.0** (premier cas à 2 modules dans une même phase) |

Le fait porteur de la phase est corrigé : sur un poste à jour côté plugin mais resté au moteur legacy
`1.42.3`, `/vf-update` ne s'arrête plus sur « VibeFlow est à jour » — il dit l'état du moteur **avant**
tout stop et propose la bascule, refusable sans effet de bord (ADR-031).

---

## Le défaut que trois étages ont laissé passer

Revue de code **PASS**, gate de portabilité **vert sur 3 OS**, audit sécurité **6/6 angles PASS** —
et pourtant `patch_gsd_executor_mcp()` appelait `inject-mcp-tools.sh --verify` **sans `--force`**,
alors que l'injection juste au-dessus le passait (obligatoire : `gsd-executor.md` ne porte pas le flag
`vf-mcp-consumer`). La cible était donc systématiquement écartée. Conséquence : le verdict sortait
**toujours en 3** — jamais `0` « conforme », jamais `1` « serveur manquant » — et un `ERROR` bruyant
tombait à chaque bootstrap sur tout lab sans `.mcp.json`, c'est-à-dire le cas le plus courant.
**Un garde-fou qui ne gardait rien** : exactement le motif que la phase entière corrige ailleurs.

Seul le vérificateur goal-backward l'a vu, **en mutant le bloc livré** : sa suppression complète
laissait la suite à **73 OK / 0 KO**. Deux causes nommables, réutilisables comme sondes :

1. **Le compte rendu prouvait une présence, pas un comportement** — `grep -c 'verify' → 7` cité comme
   justification de câblage.
2. **Les tests exerçaient une forme que la production n'émet jamais** — `inject-mcp-tools.sh
   --force --verify` invoqué à la main, quand le chaînage réel émettait `--verify` seul.

**Correctif** (`94587c5`) : `--force` sur la vérification, contrat de relais F13 explicite (seul
`rc=1` alarme ; `rc=3` INDÉTERMINÉ devient informatif, plus une alarme), et cas **T2m** qui exerce le
chaînage réel via un stub co-localisé — létal sur 3 mutations (suppression du bloc, retrait du
`--force`, branche `rc=1` rendue muette). Contrefactuel décisif du juge, `--force` en seule variable :
`rc=0 conforme` contre `rc=3 INDÉTERMINÉ`. Une passe **test-only** supplémentaire (`edb9c77`, cas
**T2n**) a fermé la dernière mutation survivante — la moitié « `rc=3` n'alarme pas » du contrat F13,
jusque-là établie par une sonde manuelle du juge et par aucun test. Létale sur macOS et Linux, sans
la moindre ligne de comportement modifiée.

C'est la **troisième occurrence** du motif « test tautologique derrière un décompte vert » sur ce
repo (Phase 13, Phase 17 cas 7, Phase 19). Le contre-poison qui a marché à chaque fois est la
**mutation du bloc livré**, jamais la relecture.

---

## Contrôle de flux — ce qui a été tranché

- **Fusion des deux juges, un seul `reopen`.** Les findings de n3 et n4 ont été fusionnés avant toute
  décision ; le `reopen` de n2 n'a été déclenché qu'après le verdict de vérification, une seule fois.
- **Compteur « N suites » des README racine : rouge assumé.** Classé `auto-fix` majeur par le gate de
  portabilité, refusé en connaissance de cause — le rattrapage voyage avec le commit de release
  racine (patron Phases 13 et 17), explicitement hors périmètre de la mission. **Leçon de méthode :**
  un juge frais ignore les déférés qu'on ne lui nomme pas ; le mandat doit les lui dire, sinon il les
  remonte en faux positif.
- **Bug antérieur non corrigé, délibérément.** La ligne `ensure-deps.sh:~398` (« serveurs MCP du lab
  injectés » émise même sans serveur) a été attribuée par le juge comme **antérieure à la phase** :
  la corriger aurait été une extension de périmètre. Signalée, laissée en l'état.
- **Deux findings d'audit en `no-op`**, aucun reopen : disposition « accept » de 3 menaces
  `Information Disclosure` low jamais formalisée (aucun `SECURITY.md` dans le repo), et fragilité de
  la sonde cross-module — cette dernière **inscrite à `CONCERNS.md`** (`164ff35`).

---

## Gouvernance

- **Portabilité prouvée par exécution**, pas par lecture : macOS bash 3.2.57, Ubuntu 24.04, Debian 12.
  `test-check-gsd-engine.sh` 15/0 · `test-inject-mcp-tools.sh` 12/0 · `test-dev-orchestrator.sh`
  74 OK/0 KO (1 SKIP environnemental nommé en conteneur). Aucun test sauté silencieusement.
- `check-agents.sh --strict` exit 0 · idiomes ADR-054 respectés · aucune édition de `ci.yml`
  (les suites sont ramassées par `ci.yml:32`).
- `check-version-sync.sh` : **12 ✓ dont les 17 triades par module**, 2 ✗ = uniquement le compteur de
  suites des README racine (déféré).
- Commits en français, `type(scope): résumé`. **Aucun push, aucun tag, aucune release** — conforme au
  périmètre.

---

## Reste-à-faire, réservé à validation humaine

1. **Release racine** : bump `VERSION` + `plugin/.claude-plugin/plugin.json` +
   `.claude-plugin/marketplace.json` + historique des 2 README (badges inclus), **avec** le rattrapage
   du compteur 41 → 42 suites ; puis tag annoté poussé, release GitHub, `check-release-tag.sh
   --remote` → ✓. Elle couvrirait **deux phases non shippées** : la 17 et la 19.
2. **Recette humaine SC2** : parcours `/vf-update` sur un poste réellement legacy — acceptation
   **puis** refus de la ligne moteur.
3. **Arbitrage remonté, non tranché seul** : absence d'`isolation: worktree` sur les vagues
   parallèles. Aucune collision constatée (périmètres disjoints et déclarés), mais la garantie vient
   de la déclaration, pas de la construction.
4. **Non instruit, à arbitrer séparément** : `.planning/missions/2026-07-28-audit-externe-fluidite.md`
   (révision d'ADR-051, gradation de la revue par risque, `MISSION-INVARIANTS.md`, `--exclude` sur
   `check-agents.sh`). Rien n'en a été pris dans cette mission.

## Incident d'outillage — troisième occurrence du jour

`gsd-tools query state.*` a **de nouveau** écrasé le frontmatter de `.planning/STATE.md` en cours
d'exécution (`current_phase` 19→17, `total_phases` 19→18, `completed_phases` 10→8, `total_plans`
53→42, `completed_plans` 35→21, bannière narrative rétrogradée à « 50 % »). Restauré en `63aca55`,
après `ef8826c` et `f9a0f45` plus tôt dans la journée. Cause : la comptabilité des plans est tenue à
la main et couvre les **archives de jalon**, quand l'outil recalcule depuis le seul `ROADMAP.md`
courant — il ne peut que sous-compter, et le chiffre faux a l'air plausible. Parade appliquée : la
baseline des 4 compteurs est inscrite dans **chaque** mandat de worker, et les outils `state.*` sont
interdits aux juges read-only.
