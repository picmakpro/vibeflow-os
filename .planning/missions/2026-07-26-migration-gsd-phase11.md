# Mission — Phase 11 « Intégration migration GSD »

**Date :** 2026-07-26 · **Manager :** `vf-dev-manager` · **Mode :** autonome ·
**Base :** `e748915` → **HEAD :** `8fe404d` · **25 commits** · Requirements : GSDM-04/05/06.

---

## Plan de bataille (DAG, 16 nœuds)

Sérialisation imposée par un fichier partagé (`test-dev-orchestrator.sh` : fixtures 11-01,
whitelist SDK 11-02, whitelist T14 11-03) ; une seule vraie lane parallèle (`plugin/_internal/`).

```
plan-11 ─┬─ exec-11-01 ─ rev-11-01 ─ exec-11-02 ─ exec-11-03 ─ rev-11-03 ─ exec-11-05 ─┐
         │                                                                             ├─ exec-11-06 ─┬─ verif-11 ─┐
         └─ exec-11-04 ─ harden-11-04 ─ rev-11-04 ────────────────────────────────────┘              ├─ audit-11 ─┴─ fix-entete
                                                                              docs-update ───────────┘
amend-plan (D1-D5) intercalé avant exec-11-01
```

**Baseline relevée par le manager AVANT dispatch** (contre `e748915`, jamais contre le worktree) :
38 suites · `check-version-sync` vert · `test-dev-orchestrator`, `test-detect-gsd-engine`,
`test-check-overlaps`, `test-merge-hooks` tous verts · SKIP T6 **préexistant**.

## Résultat par vague

| Vague | Verdict | Preuve retenue |
|---|---|---|
| 11-01 Bascule mécanique | ✅ PASS | Piège n°1 mort (`grep -c 'command -v gsd'` → 0) ; 19 + 41 cas ; **lab standard** |
| 11-02 SDK → gsd-tools | ✅ PASS | Cascade 3 candidats dont projet-local ; fallback sur `.error` ; T4c dé-tautologisé en revue |
| 11-03 Routage & frontières | ✅ PASS | T14b/T15/T16 prouvés par mutation ; index 71 entrées ; AGENT.md 162 L |
| 11-04 Cohabitation | ✅ PASS | T4/T5 **rouges avant / verts après** ; 8/8 + 8/8 |
| — durcissement `references()` | ✅ PASS | Frontière par négation du jeu fermé `[A-Za-z0-9._-]` ; 8 cas, contre-exemples tenus |
| 11-05 Doctrine modèles | ✅ PASS | Bloquant ADR-031 attrapé en revue (formulation « j'asserte ») |
| 11-06 Non-régression + docs | ✅ PASS | 3 scopes + idempotence en HOME isolé ; `~/.claude` prouvé intact |

**Vérification goal-backward** (`11-VERIFICATION.md`) : **PASS sur les 3 critères**, aucun blocker.
**39/39 suites vertes**, `check-version-sync` entièrement vert.
ADR-031 prouvé **par sentinelle** : `CANARY.txt` posé dans l'arbre legacy, `ensure-deps.sh` lancé en
mode réel → les 3 commandes destructives s'affichent, le canari survit.
Index diffé nom par nom contre les 71 répertoires du payload réel 1.8.0 : **identique**.

**Audit sécurité** : aucun bloquant. ADR-031 conforme sur tous les chemins (succès, échec npm/node,
échec npx, GSD déjà présent) — aucun `eval`/substitution/heredoc n'exécute les commandes.
`merge-hooks.sh` conforme au merge comme au remove.

## Décisions prises en autonomie

- **D1-D5 — résolution `gsd-tools` par cascade** (panel : `gsd-advisor-researcher`). Le chemin en
  dur prescrit par le dossier d'étude casse **dès aujourd'hui** sur le scope `--local` de gsd-core.
  Corollaires : tester le JSON (`.error`) et non `$?` ; `VERSION` dérivé du chemin résolu ; jamais
  `@next` (dist-tag amont périmé).
- **Non-mixité générale des groupes de hooks** (arbitrage manager, cf. STATE `### Decisions`).
- **3 corrections de plans** faites par le manager : recette 11-01 (les références legacy
  *affichées* sont légitimes — ADR-031), sonde 11-02 (accolade de `${CLAUDE_CONFIG_DIR:-…}`),
  et un nœud d'hygiène final sur 5 artefacts descriptifs rendus faux par la phase.

## ⚠️ Remonte à l'humain

**Posture de chaîne d'approvisionnement (majeur, non bloquant).** L'install est en
`@opengsd/gsd-core@latest`, sans plafond de version majeure ni vérification d'intégrité répétée.
L'audit relève que le risque a **augmenté** : on quitte un paquet mort (dépôt verrouillé, surface
nulle) pour un fork de 2 mois activement publié, 3 mainteneurs npm non vérifiés. Un `2.0.0` cassant
ou compromis s'installerait seul au prochain run.
Non tranché par le manager **délibérément** : ce n'est pas un bug, le pin `@latest` est un arbitrage
humain explicite de la Phase 10 (« un pin enterré dans un `.sh` est le pin qui pourrit »), et c'est
une décision de posture sécurité. Option à arbitrer : plafond semver (`@^1`) et/ou contrôle
post-install de la `VERSION` installée.

## Écarts & dette laissée

- `brick_routed()` (`test-dev-orchestrator.sh`) fait un grep textuel naïf : T14 reste vert si l'on
  retire **une seule** des deux gardes. **Préexistant** (même motif que `DESIGN_DELEGATED`) → backlog.
- `--scripts-prefix` non validé défensivement dans `merge-hooks.sh:167` — **préexistant**, non
  exploitable (l'unique appelant ne retourne que 2 littéraux fixes) → backlog.
- Migration réelle de cette machine : elle porte encore le layout legacy. Geste **utilisateur**,
  post-release.

## Carve-out release — respecté

`VERSION` = `v2.38.0` (inchangé), `plugin.json` et `marketplace.json` intacts, **aucun tag**,
**rien poussé**. Triades bumpées : `dev-orchestrator` v2.3.0 (minor), `planning-core` v2.5.2,
`conductor` v1.14.2. `plugin/_internal/` n'appartient à aucun module.

## Leçon de mission

Les 6 vagues n'ont produit **aucun défaut de code**. Les trois arrêts, et les cinq correctifs
d'hygiène finaux, portent tous sur des **artefacts qui décrivent le code** — recettes de plan,
sondes `grep`, en-têtes de commentaires, docs `codebase/`. Aucun test ne les lit, et ils se
propagent : un en-tête périmé a servi de « preuve » à un worker pour laisser une mention obsolète
ailleurs. Sur les 4 findings remontés en `ask-user` par les workers, **zéro** relevait de l'humain.
