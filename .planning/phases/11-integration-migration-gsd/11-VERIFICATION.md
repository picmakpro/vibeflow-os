---
phase: 11-integration-migration-gsd
verified: 2026-07-26T23:10:00Z
status: gaps_found
score: 3/3 critères de succès atteints sur leur périmètre nommé (3 résidus documentaires, aucun bloquant)
verifier: Claude (gsd-verifier) — vérification goal-backward, stance adverse
base_commit: e748915
head_commit: 3eeb142
scope_carve_out:
  must_have: "release bumpée + tag annoté poussé (scripts/check-release-tag.sh --remote → ✓)"
  reason: "Retiré du périmètre par mandat humain explicite de la mission verif-11 — réservé à validation humaine. Sa PRÉSENCE aurait été une violation. Vérifié absent : VERSION reste v2.38.0, aucun tag sur HEAD, plugin.json/marketplace.json intacts."
  accepted_by: "Samuel (mandat de mission)"
  accepted_at: "2026-07-26"
gaps:
  - truth: "Les références docs pointent la nouvelle source (`@opengsd/gsd-core`)"
    status: partial
    severity: warning
    reason: "INSTALL.md présente encore `npx get-shit-done-cc` comme le vecteur d'install courant du moteur GSD. Ce n'est ni de l'histoire datée, ni la fenêtre de compat, ni une étape de nettoyage affichée — c'est une instruction utilisateur vivante, et elle est doublement fausse (le paquet a changé ET VibeFlow installe désormais GSD lui-même via ensure-deps.sh)."
    preexisting: true
    evidence: "INSTALL.md l.140-141 ; fichier non touché depuis e748915 (git log e748915..HEAD -- INSTALL.md → vide). Seul fichier utilisateur restant : README.md, README.fr.md et les 17 README de modules sont propres."
    artifacts:
      - path: "INSTALL.md"
        issue: "l.140 `installé hors VibeFlow via npx get-shit-done-cc` — ancien paquet donné comme moteur installé courant"
    missing:
      - "Remplacer `npx get-shit-done-cc` par `npx -y @opengsd/gsd-core@latest --claude --global|--local` et corriger `~/.claude/get-shit-done/` → `~/.claude/gsd-core/` (mentionner l'ancien layout comme legacy)"
  - truth: "Le défaut documenté de GSD_HOME correspond au défaut réel du code"
    status: partial
    severity: warning
    reason: "L'en-tête de detect-gsd-engine.sh et STACK.md documentent le défaut `~/.claude/get-shit-done`, alors que la cascade posée par cette phase fait défaut sur `gsd-core`. Texte préexistant, rendu FAUX par la phase."
    preexisting: true
    evidence: "detect-gsd-engine.sh l.13 (identique à e748915) contredit le code l.33-47 (`else echo \"$claude_home/gsd-core\"`). STACK.md l.144 idem."
    artifacts:
      - path: "plugin/planning-core/scripts/detect-gsd-engine.sh"
        issue: "l.13 en-tête : `GSD_HOME (défaut $HOME/.claude/get-shit-done)` — le code fait défaut sur gsd-core"
      - path: ".planning/codebase/STACK.md"
        issue: "l.144 même défaut périmé"
    missing:
      - "Aligner les deux lignes sur le défaut réel (cascade 4 niveaux, défaut `gsd-core`)"
  - truth: "gsd-skills-index.md est un artefact auto-généré reproductible"
    status: partial
    severity: info
    reason: "Le fichier porte `auto-généré — NE PAS ÉDITER`, mais sa ligne de provenance a été éditée à la main (commit 0b383e6) pour masquer un chemin de scratchpad. Le fichier n'est donc plus reproductible octet-à-octet par build-gsd-index.sh, qui écrit `$SKILLS_DIR/gsd-*`. Les 71 entrées — la charge factuelle — sont intactes et prouvées conformes au paquet réel."
    preexisting: false
    evidence: "git show 0b383e6 : 1 insertion / 1 suppression, ligne 2 uniquement. build-gsd-index.sh l.110 écrit la provenance depuis $SKILLS_DIR."
    artifacts:
      - path: "plugin/dev-orchestrator/references/gsd-skills-index.md"
        issue: "ligne de provenance éditée manuellement dans un fichier marqué NE PAS ÉDITER"
    missing:
      - "Soit faire écrire à build-gsd-index.sh une provenance stable (nom+version du paquet), soit accepter la divergence explicitement"
---

# Phase 11 : Intégration migration GSD — Rapport de vérification

**Goal :** basculer les points d'install et l'index vers `@opengsd/gsd-core`, mettre à jour les
références, prouver la non-régression en isolé, documenter.
**Base :** `e748915` → **HEAD :** `3eeb142` (24 commits, arbre de travail propre).
**Vérifié :** 2026-07-26 — recette rejouée intégralement par le vérificateur, aucun rapport d'exécution repris sur parole.

## Verdict par critère de succès

| # | Critère | Verdict |
|---|---------|---------|
| 1 | `ensure-deps.sh` + pins `PROJECT.md` installent `@opengsd/gsd-core` (non-interactif, idempotent, fallback manuel) ; l'ancien paquet n'est plus le moteur installé | **PASS** (1 résidu doc hors périmètre nommé) |
| 2 | Index factuel régénéré depuis le nouveau paquet, zéro hallucination, références docs sur la nouvelle source | **PASS** (2 résidus doc mineurs) |
| 3 | Non-régression prouvée en isolé (dry-run 3 scopes + idempotence, vrai `~/.claude` intact) ; CHANGELOG/README à jour | **PASS** |

**Aucun BLOCKER.** Les 3 gaps sont documentaires, 2 sur 3 préexistants à la phase.

## Critère 1 — bascule du moteur installé

| Point de contrôle | Preuve | Statut |
|---|---|---|
| **Piège n°1 : aucun test de PATH dans `detect_gsd()`** | `grep -c 'command -v gsd' ensure-deps.sh` → **0**. À `e748915` : l.99 `command -v gsd-sdk … \|\| [ -f "$GSD_VERSION_FILE" ]`. Nouveau `detect_gsd()` (l.119-121) = cascade fichier VERSION pure. | ✓ NEUTRALISÉ |
| Install = nouveau paquet | l.163 `run_cmd npx -y @opengsd/gsd-core@latest --claude "$GSD_SCOPE_FLAG"` | ✓ |
| 3 scopes non-interactifs | Dry-run rejoué : `user→--global`, `project→--local`, `local→--local`, **exit 0 aux 3** | ✓ |
| Idempotence | VERSION gsd-core présent → `GSD déjà présent (skip)`, **0 occurrence de `npx`** ; runs 2 et 3 octet-identiques | ✓ |
| Garde Node ≥ 22 | l.149-160, bascule étape manuelle avant tout `npx` (T2e vert) | ✓ |
| Fallback manuel | l.140-147 (npm absent) et l.169-174 (échec install), jamais d'échec silencieux, exit 0 | ✓ |
| `GSD_VERSION_FILE_NEW` dérivé, pas figé `$HOME` | `default_gsd_home_new()` l.60-71 : projet-local `<racine>/.claude/gsd-core` prioritaire | ✓ |
| Pin `PROJECT.md` | l.61 → `@opengsd/gsd-core` ; l.43 (historique du milestone) inchangée au caractère près | ✓ |

**Occurrences légitimes de `get-shit-done` confirmées comme telles (pas des faux positifs) :**
`GSD_VERSION_FILE_LEGACY` l.72 (fenêtre de compat) et les 3 lignes `log` de nettoyage manuel
l.184-186.

**Preuve ADR-031 — le nettoyage est AFFICHÉ, JAMAIS EXÉCUTÉ.** Exécution en mode **réel** (pas
dry-run), HOME sandbox portant `~/.claude/get-shit-done/` + une sentinelle `CANARY.txt` :
les 3 commandes sont bien affichées, et `ls` post-run rend toujours `CANARY.txt` **et** `VERSION`.
Le `rm -rf` n'a pas été exécuté.

## Critère 2 — index factuel et références

| Point de contrôle | Preuve | Statut |
|---|---|---|
| **71 entrées** | `awk '/^\| gsd-/' \| wc -l` → **71** | ✓ |
| **Zéro hallucination / zéro omission** | Diff de l'ensemble des noms de l'index contre les 71 répertoires `skills/` du payload réel `@opengsd/gsd-core@1.8.0` → **IDENTIQUE** | ✓ |
| 4 skills nommés présents | `gsd-onboard` (l.47), `gsd-next` (l.40), `gsd-mempalace-capture` (l.34), `gsd-mempalace-recall` (l.35) | ✓ |
| Cascade sans chemin en dur — `build-gsd-index.sh` | `default_workflows_dir()` l.31-45, 4 niveaux (projet-local → `$CLAUDE_CONFIG_DIR\|$HOME` gsd-core → legacy → défaut gsd-core) | ✓ |
| Cascade — `detect-gsd-engine.sh` | `default_gsd_home()` l.33-47, mêmes 4 niveaux, résolue **seulement** si `GSD_HOME` non fourni (les 12 cas historiques restent verts, 19 ok / 0 ko) | ✓ |
| Cascade `gsd-tools` (scope `--local`) | `mission-contracts.md` l.74-87 : `$_GSD_ROOT/gsd-core/bin` → `$_GSD_ROOT/.claude/gsd-core/bin` → `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/gsd-core/bin` → `command -v gsd-tools` en dernier recours. **Aucun chemin `$HOME`-only.** | ✓ |
| **Succès testé sur le JSON, jamais sur `$?`** | `mission-contracts.md` l.93-96, littéral : « `gsd-tools` sort exit 0 même en erreur métier … Ne jamais tester uniquement le code de sortie du processus. » Fallback grep élargi au champ `.error`. | ✓ |
| `@latest` uniquement, jamais `@next` | `grep '@next' mission-contracts.md` → **0** ; écart D4 documenté l.98-100 | ✓ |
| Plus de `gsd-sdk` vivant | Aucune occurrence dans `skills/` ni `references/` — restent seulement le garde-fou T4b et un commentaire explicatif d'`ensure-deps.sh` l.117. Test T4b vert. | ✓ |
| `vf-auto` bascule | `SKILL.md` l.18 → `gsd-tools roadmap analyze` | ✓ |
| Docs codebase sur la nouvelle source | `STACK.md` l.109-118 et `INTEGRATIONS.md` l.25-30 réécrits (commit `3eeb142`) | ✓ |

### Frontières ADR-057

| Point de contrôle | Preuve | Statut |
|---|---|---|
| Canal 4 « Non routé — une seule voix » | `intent-routing.md` l.152-159, nomme `gsd-next`, `gsd-mempalace-capture`, `gsd-mempalace-recall` par leur nom exact, avec justification | ✓ |
| Réellement absents des tables de routage | `grep -E '^\|.*(gsd-next\|gsd-mempalace)'` sur `intent-routing.md` → **aucune ligne** (déclarés non routés ET effectivement non routés) | ✓ |
| 3 paires dans `check-overlaps.sh` | l.65 `consolidator\|gsd-mempalace-capture`, l.66 `consolidator\|gsd-mempalace-recall`, l.67 `vibeflow-dev\|gsd-next` — littérales, aucun glob | ✓ |
| Couverture par test | T15 (deux côtés → 3 frontières) et T16 (un seul côté → aucune) verts | ✓ |
| Routage `gsd-onboard` | `intent-routing.md` l.53 avec fallback `gsd-map-codebase` → `gsd-new-project` ; T14 : « 71 skill(s) de l'index tous routés » | ✓ |
| Sonde discriminante T14b | `gsd-next` exempté et non signalé ; `gsd-inconnu-xyz` non exempté → **signalé manquant** (le test peut échouer) | ✓ |

## Critère 3 — non-régression en isolé

### Les 39 suites — exécutées en SÉQUENTIEL par le vérificateur

**39 vertes / 0 rouge / 0 SKIP de suite.** Aucune suite rouge à nommer.

> Note d'exécution : un premier passage a rendu `rc=127` sur les 39 — bug de mon harnais
> (`timeout` absent de macOS), pas un échec de test. Rejoué sans `timeout` : 39/39 à `rc=0`.

Suites clés (décomptes internes) :

| Suite | Résultat interne |
|---|---|
| `test-dev-orchestrator.sh` | **41 OK / 0 KO / 0 SKIP** |
| `test-detect-gsd-engine.sh` | 19 ok / 0 ko (cas 18 projet-local, cas 19 `CLAUDE_CONFIG_DIR`) |
| `test-check-overlaps.sh` | vert, T15 + T16 inclus |
| `test-merge-hooks.sh` | vert (T1-T7 intacts) |
| `test-gsd-cohabitation.sh` (NOUVEAU) | 8 ok / 0 ko — T1 merge sans perte, T2 remove restaurateur, T3 idempotence, T4 non-mixité, **T5 `gsd-archive.sh` survit au merge ET au remove d'un fragment `archive.sh`** |

**T6 : aucune régression — mieux que la baseline.** Attendu SKIP (préexistant à `e748915`), observé
**vert** : `✓ T6 install e2e : agent + references + 2 skills présents, aucun artefact de façade`.
**Aucune régression** sur les 4 suites de baseline (`test-dev-orchestrator`, `test-detect-gsd-engine`,
`test-check-overlaps`, `test-merge-hooks`) : toutes vertes avant comme après.

**Décompte de suites : 38 → 39** (ajout de `test-gsd-cohabitation.sh`), cohérent avec le compteur
README synchronisé.

### `scripts/check-version-sync.sh` — **entièrement vert (exit 0)**

```
✓ plugin.json 2.38.0            ✓ marketplace.json 2.38.0
✓ README.md badge version 2.38.0  ✓ README.fr.md badge version 2.38.0
✓ README.md badge modules 17      ✓ README.fr.md badge modules 17
✓ README.md texte 17 modules      ✓ README.fr.md texte 17 modules
✓ triade par module : 17 modules VERSION ↔ module.json alignés
✓ README.md historique en tête v2.38.0   ✓ README.fr.md historique en tête v2.38.0
✓ en-tête Version des README de modules : 17 déclarés, tous alignés
✓ README.md suites 39             ✓ README.fr.md suites 39
✓ sources synchronisées (v2.38.0, 17 modules)
```

### Le vrai `~/.claude` n'a jamais été touché

Snapshot avant/après encadrant l'exécution des 39 suites :

| Mesure | Résultat |
|---|---|
| Arborescence `~/.claude` (maxdepth 2, modifiée ce jour) — 111 entrées | **diff vide — IDENTIQUE** |
| `shasum ~/.claude/settings.json` | `b3603cc8…` avant **et** après — **IDENTIQUE** |
| `~/.claude/gsd-core` créé ? | **Non** (absent avant, absent après) |

Contexte notable : la machine d'exécution porte `~/.claude/get-shit-done` (legacy) et **pas** de
`gsd-core` — c'est exactement le cas que le piège n°1 condamnait à ne jamais migrer. Le shim legacy
n'a plus aucun effet sur la détection.

Aucune install réelle n'a été tentée : scan préalable des 39 suites pour `npx|npm install|npm
uninstall|rm -rf $HOME` → seules des occurrences en commentaires et chaînes de test. Les dry-runs
n'écrivent que dans leur sandbox (`$SB/.claude/.claude.json` + backup, produits par la CLI `claude`
appelée en détection).

### Release — carve-out respecté, aucune violation

| Contrôle | Attendu | Observé |
|---|---|---|
| `VERSION` racine | reste `v2.38.0` | **`v2.38.0`** (identique à `e748915`) |
| Tag sur HEAD | aucun | **aucun** (`git tag --points-at HEAD` vide) |
| `plugin.json` / `marketplace.json` | intacts | **intacts** (diff vide) |

### Livraison documentaire

| Module | VERSION | module.json | README | CHANGELOG |
|---|---|---|---|---|
| dev-orchestrator | v2.3.0 | v2.3.0 | v2.3.0 | `## [v2.3.0] — 2026-07-26` |
| planning-core | v2.5.2 | v2.5.2 | v2.5.2 | `## [v2.5.2] — 2026-07-26` |
| conductor | v1.14.2 | v1.14.2 | v1.14.2 | `## [v1.14.2] — 2026-07-26` |

`CHANGELOG.md` racine : entrée non versionnée l.10 « Correctif `_internal/merge-hooks.sh` (vague
11-04) ». README.md / README.fr.md : compteur 39 (validé par les points 13-14 du gate).
`.planning/config.json` de ce repo : **non modifié** (vibeflow-os n'est pas un lab consommateur).
Doctrine modèles : `AGENT.md` (1 réf), `migration-playbook.md` (3 réfs), `GSD-PIPELINE.md` §8
frontière `model:` vs `model_profile` (l.130-140).

## Anti-patterns

| Scan | Portée | Résultat |
|---|---|---|
| `TBD` / `FIXME` / `XXX` | 43 fichiers modifiés par la phase | **0** |
| `TODO` / `HACK` / `PLACEHOLDER` | idem | **0** |
| ADR-029 densité | `AGENT.md` = **165 lignes** (≤ 250) | ✓ |
| ADR-044 agents natifs | `check-agents.sh` exit 0 | ✓ |

## Anomalies — préexistante vs introduite

| # | Anomalie | Verdict | Preuve |
|---|---|---|---|
| 1 | `INSTALL.md` l.140-141 donne `npx get-shit-done-cc` comme vecteur d'install courant | **PRÉEXISTANTE** (non corrigée) | Fichier inchangé depuis `e748915` |
| 2 | Défaut `GSD_HOME` documenté `~/.claude/get-shit-done` (en-tête `detect-gsd-engine.sh` l.13, `STACK.md` l.144) alors que le code fait défaut sur `gsd-core` | **PRÉEXISTANTE, rendue fausse par la phase** | `git show e748915:…` → l.13 identique ; code l.33-47 nouveau |
| 3 | Ligne de provenance de `gsd-skills-index.md` éditée à la main dans un fichier « NE PAS ÉDITER » | **INTRODUITE** | commit `0b383e6`, 1 ligne |
| 4 | Message du commit `0ac3c1e` : « purge **la dernière** référence legacy vivante » — factuellement faux au moment du commit | **INTRODUITE** (cosmétique) | `STACK.md`/`INTEGRATIONS.md` corrigés 5 commits plus tard (`3eeb142`) ; `INSTALL.md` toujours ouvert |

## Synthèse

Le cœur de la phase est **atteint et prouvé** : le piège n°1 est neutralisé (0 test de PATH, contre
un `command -v gsd-sdk` à la base), l'install bascule sur `@opengsd/gsd-core@latest` sur les 3
scopes de façon idempotente et non-interactive, le nettoyage legacy est affiché sans jamais être
exécuté (preuve par sentinelle en mode réel), la résolution de `gsd-tools` passe par une vraie
cascade couvrant le scope `--local`, la doctrine « succès sur le JSON, jamais sur `$?` » est écrite
noir sur blanc, l'index porte 71 entrées dont l'ensemble est **strictement identique** aux 71 skills
du payload réel, les frontières ADR-057 sont à la fois déclarées et effectives, les 39 suites sont
vertes en séquentiel, `check-version-sync.sh` est entièrement vert, et le vrai `~/.claude` est
octet-pour-octet intact. Le carve-out release est respecté sans la moindre violation.

Restent **trois résidus documentaires**, dont deux préexistants, aucun bloquant : une ligne
d'`INSTALL.md` qui présente encore l'ancien paquet comme le moteur installé, un défaut `GSD_HOME`
documenté que la phase a rendu obsolète en deux endroits, et un index auto-généré dont la ligne de
provenance a été retouchée à la main. Ils n'empêchent ni la migration ni le passage à la phase
suivante ; ils méritent une passe d'hygiène documentaire.

---

_Vérifié le 2026-07-26 — recette intégralement rejouée (39 suites en séquentiel, dry-run 3 scopes,
idempotence, sentinelle ADR-031, diff index/payload, snapshot `~/.claude`)._
_Vérificateur : Claude (gsd-verifier)_
