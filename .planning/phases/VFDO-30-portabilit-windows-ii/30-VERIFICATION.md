---
phase: 30-portabilit-windows-ii
verified: 2026-08-16T01:10:00Z
status: gaps_found
score: 6/8 exigences vérifiées PASS (PORT-01, PORT-02, PORT-03, PORT-04, LEDG-03, WKTR-03) — 1 BLOCKER (PORT-05), 1 WARNING documentaire (4 mineurs de revue introuvables)
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "PORT-05 — la portabilité est prouvée EN CI sur un lab frais (settings.json/settings.local.json posés en forme exec, chemin absolu, zéro placeholder)."
    status: failed
    reason: >
      Le SEUL run CI réel sur le tip poussé de cette branche (commit dcd9eb5, run GitHub Actions
      31917741411, 2026-08-16T00:39:25Z) est ROUGE, précisément sur l'étape « Forme exec telle
      qu'installée (PORT-05) » du job « Lab frais armé » : "5 entrée(s) VF posée(s), attendu 6 —
      présentes : ['check-dev-bootstrap.sh', 'check-doc-drift.sh', 'check-gsd-config.sh',
      'check-hook-paths.sh', 'discover-unintegrated-docs.sh']". Cause racine reproduite en local à
      l'identique (bash -c, closure = resolve-deps.sh dev-orchestrator → 9 modules, SANS
      software-architecture — aucune arête `requires` ne l'y amène) : la constante EXPECT_TOTAL=6
      du plan 30-08 décrivait un univers (dev-orchestrator + software-architecture installés à la
      main) que ce job n'installe JAMAIS réellement. Un correctif LOCAL existe (commit 4edc9688,
      "fix(30-08): dériver l'attendu de la forme exec depuis la fermeture installée, pas un
      littéral (CI 31917741411)") qui dérive l'attendu des hooks.json de la fermeture réellement
      résolue — logique re-simulée bout-en-bout ici (expect_total=5, 5 entrées posées, match) et
      paraissant correcte. MAIS ce commit n'est PAS poussé (`git status` : "ahead of origin by 1
      commit") : aucun run CI réel ne l'a encore validé. Le plan 30-08 exige explicitement (tâche
      3, checkpoint:human-verify BLOQUANT) qu'un humain pousse, constate le vert réel, et consigne
      l'identifiant d'exécution dans le SUMMARY — geste non fait : `30-08-SUMMARY.md` est
      INEXISTANT (les deux autres SUMMARY manquants du DAG, 30-02 et 30-07, ont été comblés par le
      commit 193b252 ; 30-08 ne l'a pas été).
    artifacts:
      - path: ".github/workflows/ci.yml"
        issue: "Étape PORT-05 du job lab-frais-arme : correctif écrit et logiquement validé en local, mais jamais éprouvé par un run CI réel (non poussé)."
      - path: ".planning/phases/VFDO-30-portabilit-windows-ii/30-08-SUMMARY.md"
        issue: "Fichier absent — aucune des 3 tâches du plan 30-08 (dont le checkpoint humain bloquant de la tâche 3) n'a de trace de complétion."
    missing:
      - "Pousser le commit 4edc9688 (ou un équivalent) sur origin/feat/phase-30-portabilite-windows-ii."
      - "Constater un run CI réellement vert sur le job « Lab frais armé » (les deux étapes PORT-05) — pas une simulation locale."
      - "Créer 30-08-SUMMARY.md consignant le verdict par job et l'identifiant d'exécution CI, conformément à l'acceptance criteria de la tâche 3 du plan 30-08 (checkpoint bloquant)."
deferred: []
---

# Phase 30 : Portabilité Windows II — Rapport de vérification

**Objectif de phase (ROADMAP.md) :** Réécrire le substrat des hooks pour qu'une install VibeFlow
sur Windows pose des hooks qui fonctionnent — `merge-hooks.sh` apprend la forme exec, les codes de
sortie sont normalisés vers le harness, les entrées hooks.json du périmètre dev passent en forme
exec, la lib partagée `vf-portable.sh` est écrite et consommée par le lot PYBIN. Plus deux gestes
jour 1 : RFC upstream (LEDG-03) et veille de release gsd-core (WKTR-03).

**Vérifié le :** 2026-08-16
**Statut :** gaps_found — 1 BLOCKER (PORT-05, CI réelle rouge sur le tip poussé), 1 WARNING
documentaire (4 mineurs de revue mentionnés par le mandat introuvables dans le dépôt).
**Branche :** `feat/phase-30-portabilite-windows-ii`, HEAD local `4edc9688` (1 commit en avance sur
`origin` au moment de la vérification — non poussé).

---

## Exigences — verdict un par un

### PORT-01 — lib partagée `vf-portable.sh` conforme au contrat PR #29 — ✅ PASS

**Preuve directe (code lu, pas relayé) :**
- `plugin/_internal/lib/vf-portable.sh` (158 lignes) expose EXACTEMENT les 5 symboles du contrat :
  `vf_resolve_python` (l.88), `vf_python` (l.111), `vf_py_probe` (l.55), `jqx` (l.121),
  `vf_guard_unavailable` (l.145). Sourcée jamais exécutée (pas de bit +x, aucun `set -e`/`exit` au
  chargement, cf. l.6-8).
- Bloc localisateur à **4 candidats** entre marqueurs `# >>> vf-portable:locator` /
  `# <<< vf-portable:locator`, reproduit à l'identique dans 4 consommateurs réels :
  `guard-file-size.sh`, `inject-mcp-tools.sh`, `test-dev-orchestrator.sh`,
  `check-hook-paths.sh` (le 4e, ajouté par le plan 30-09).
- Sémantique `vf_py_probe` conforme : présence + rejet stub `*WindowsApps*` + sonde d'exécution
  réelle (gardée par `timeout` si dispo), avec un profil `--fast` (zéro spawn) documenté et
  distinct pour les gardes PreToolUse (D-02).
- `copy_engine_lib()` implémentée dans `vibeflow-update.sh` (l.319+), posée à plat, PAS de
  `chmod +x`, propagation d'échec via `set -e` (jamais un `return 0` silencieux — VG-3).
- `merge-hooks.sh` lui-même N'EST PAS un consommateur de la lib — vérifié conforme au contrat :
  `docs/CONTRAT-PORTABILITE.md` §7 (branche `gouvernance/contrat-portabilite`, lu directement)
  ne nomme QUE `guard-file-size.sh` et `inject-mcp-tools.sh` pour la polarité dev ; la migration de
  `merge-hooks.sh` lui-même relève de la polarité gouvernance / plan `01-03` (hors périmètre Phase
  30). Ce n'est pas un oubli malgré ce que suggérait PATTERNS.md — le plan 30-05 a scopé
  correctement contre le contrat réel, documenté dans `30-RELIQUATS.md`.

**Tests exécutés en direct (pas relu depuis un SUMMARY) :**
```
bash plugin/_internal/tests/test-vf-portable.sh → 13 ok · 0 ko · 0 skip
```
T12 (identité du bloc par somme de contrôle) confirme une SEULE somme pour les 4 consommateurs
réels : `fe93197b...` — preuve machine, pas relecture.

---

### PORT-02 — `merge-hooks.sh` apprend la forme exec (`args`) — ✅ PASS

**Preuve directe :** `frag_basenames()` (l.108-116) et `references()` (l.117-140) de
`plugin/_internal/merge-hooks.sh` parcourent désormais `command` ET chaque élément d'`args`
séparément (frontière de mot par lookaround négatif conservée). Substitution `{{VF_SCRIPTS}}`
appliquée élément par élément dans `args` (l.309-320). Les hooks.json du périmètre dev sont
effectivement en forme exec :
- `plugin/dev-orchestrator/hooks/hooks.json` : 5 entrées `SessionStart`, `command: "{{VF_BASH}}"`
  (ou `"bash"` nu pour la dérogation nommée `check-hook-paths.sh`) + `args: [...]`.
- `plugin/software-architecture/hooks/hooks.json` : 1 entrée `PreToolUse`, même gabarit.

**Tests exécutés en direct :**
```
bash plugin/_internal/tests/test-merge-hooks.sh → 25 OK · 0 KO
```
Dédup cross-forme (T9/T10), routage `--settings-local` par `{{VF_BASH}}` (T15-T18), matrice de
séquences avec 4 cas discriminants prouvés par mutation (T21a/b/c) — mutation testing réel, pas une
suite qui passe par construction.

---

### PORT-03 — codes de sortie normalisés vers le harness (0 = silence) — ✅ PASS

**Preuve directe :** `docs/HOOKS-CONTRAT-SORTIE.md` (195 lignes, lu intégralement) documente le
contrat (0/non-nul/2 réservé au blocage) et un inventaire machine-recompté de **26 entrées** (25
recomptées le 2026-08-15 par le plan 30-04 + 1 posée par le plan 30-09,
`check-hook-paths.sh`). Recomptage exécuté en direct :
```
python3 -c "...n=26; assert n==26, n" → 26 (0 erreur)
```
Les 2 entrées correctement EXCLUES de la normalisation sont bien nommées et justifiées :
`guard-file-size.sh` (bloque par décision JSON, sort toujours 0) et `guard-planning-updated.sh`
(bloque VOLONTAIREMENT par exit 2, jamais à normaliser).

**Tests exécutés en direct :**
```
bash scripts/tests/test-hook-exit-parc.sh → 42 OK / 0 KO — 8 script(s) exercé(s)
```
Discriminance par mutation sur 5 scripts distincts (check-registres, seed-registres,
check-planning-state, detect-planning-debt, audit-infra), garde anti-vert-à-vide (mutation m3)
prouvée. `test-dev-orchestrator.sh` (184 cas, dont la normalisation `--hook` des 4 scripts
dev-orchestrator) : 184 OK / 0 KO en exécution directe.

---

### PORT-04 — affectation §3.2 tranchée et documentée — ✅ PASS

**Preuve directe :**
- `resolve_bash_abs()` dans `merge-hooks.sh` (l.96-112) : cascade `VF_BASH_BIN` (surcharge
  autoritaire) → `$BASH` → `command -v bash`, candidat retenu SEULEMENT s'il commence par `/`,
  existe et est exécutable — conforme à D-01/ADR-070 (confinement borné, jamais un repli déguisé).
- `docs/ADR.md` — ADR-071 (l.2256-2359, lu intégralement) grave la décision et son addendum du
  2026-08-15 pour la dérogation `check-hook-paths.sh` (nom nu, paradoxe d'amorçage), scope
  explicitement borné à cette seule entrée.
- Spec amendée : `docs/superpowers/specs/2026-08-02-portabilite-windows-ii-design.md:217`,
  encart « ✅ TRANCHÉ le 2026-08-15 (Samuel, cadrage Phase 30 — PORT-04) » — vérifié sur pièce.
- Commentaire informatif posté sur PR #29 (`gh pr view 29 --json comments`) — confirmé présent,
  daté 2026-08-15T18:58:58Z, contenu conforme à D-03.

---

### PORT-05 — portabilité prouvée en CI sur lab frais — ❌ FAIL (BLOCKER)

**Ce que le pushed HEAD montre réellement :** un seul run CI existe pour cette branche
(`gh run list --branch feat/phase-30-portabilite-windows-ii`) : `31917741411`, conclusion
`failure`, sur `headSha dcd9eb5b99d92c2901f82340e1f711fa4a58f7cc` — le tip d'`origin` au moment de
la vérification. Le job `Lab frais arme (as-installed testing — le gate installe, sur un univers
non vide, #38)` échoue précisément à l'étape `Forme exec telle qu'installée (PORT-05)` :
```
##[error]5 entrée(s) VF posée(s), attendu 6 — présentes :
['check-dev-bootstrap.sh', 'check-doc-drift.sh', 'check-gsd-config.sh',
 'check-hook-paths.sh', 'discover-unintegrated-docs.sh']
```

**Cause racine, reproduite en local (bash explicite, pas zsh — le word-splitting diffère) :**
```
$ bash plugin/_internal/resolve-deps.sh dev-orchestrator
audit-architecture conductor consolidator design-orchestrator dev-orchestrator
infrastructure-audit planning-core skill-creator validator
```
`software-architecture` n'apparaît dans AUCUN `requires` de cette fermeture (vérifié module.json
par module.json). Le job CI installe cette fermeture (9 modules) — jamais `software-architecture`
— donc `guard-file-size.sh` (seule entrée de ce module) n'est JAMAIS posé par ce job. La constante
`EXPECT_TOTAL = 6` écrite par le plan 30-08 (commit `7f1ea41`) décrivait un univers vérifié « à la
main » par une install DIRECTE des deux modules dev (`dev-orchestrator` + `software-architecture`,
per l'acceptance criteria du plan : *« install réelle des deux modules dans un mktemp -d »*) — un
chemin de vérification manuelle différent du mécanisme RÉEL de la CI (résolution de fermeture).
C'est exactement le mode d'échec « testé la mauvaise chose » que la phase elle-même existe pour
fermer (régression #38).

**Un correctif existe mais n'est PAS validé par CI réelle :** commit local `4edc9688`
(*"fix(30-08): dériver l'attendu de la forme exec depuis la fermeture installée, pas un littéral
(CI 31917741411)"*) — présent sur le HEAD local, **absent d'origin** (`git status` : *"Your branch
is ahead of 'origin/feat/phase-30-portabilite-windows-ii' by 1 commit"*). Il dérive `expect_total`
des `hooks.json` sources de la fermeture réellement résolue, au lieu d'un littéral. J'ai
re-simulé cette logique bout-en-bout en local (fermeture réelle + install réelle + assertion) :
```
expect_total=5
OK: 5 entries match expected 5
```
Le correctif semble techniquement correct — mais **aucun run CI ne l'a encore éprouvé**, et le
plan 30-08 a une tâche 3 explicitement `checkpoint:human-verify gate="blocking"` dont
l'acceptance criteria exige : *« La réponse humaine est consignée dans le SUMMARY avec la date,
l'identifiant de l'exécution CI et le verdict par job »*. **`30-08-SUMMARY.md` n'existe pas** —
ni pour les tâches 1/2 (assertions CI, gates locaux), ni pour la tâche 3 (constat CI verte). Les
deux autres SUMMARY manquants découverts en reprise de moteur (30-02, 30-07) ont été comblés par
le commit `193b252` ; 30-08 ne l'a pas été.

**Honnêteté de la simulation (repli ADR-054) — vérifiée, correcte :** le commentaire de l'étape
« Conditions Windows simulées » (`.github/workflows/ci.yml`) nomme explicitement l'absence de
runner Windows réel et le repli par simulation ; le plan 30-08 le porte dans ses `must_haves`
(*« Aucun runner Windows réel n'existe dans ce dépôt »*) et son threat model (T-30-08-03, accepté et
borné). Aucune sur-affirmation « prouvé sur Windows » trouvée nulle part dans les docs de phase.
Ce point-là est net — le gap porte uniquement sur le mécanisme de comptage, pas sur l'honnêteté de
la preuve.

**Verdict :** BLOCKER. La phase ne peut pas revendiquer PORT-05 tant que (a) le correctif n'est pas
poussé, (b) un run CI réel n'a pas montré le job vert, et (c) `30-08-SUMMARY.md` ne consigne pas ce
constat avec l'identifiant d'exécution — exactement ce que le plan lui-même exige comme geste de
clôture.

---

### LEDG-03 — RFC upstream `open-gsd/gsd-core` déposée — ✅ PASS

**Preuve directe (requête GitHub réelle, pas relayée) :**
```
$ gh issue view 3556 --repo open-gsd/gsd-core --json title,state,url,createdAt
{"createdAt":"2026-08-15T20:50:53Z","state":"OPEN",
 "title":"Make REQUIREMENTS.md deletion optional at milestone completion (currently unconditional)",
 "url":"https://github.com/open-gsd/gsd-core/issues/3556"}
```
Titre et corps conformes au draft consigné dans `30-RFC-UPSTREAM.md`. Traçabilité D-11 posée aux
deux endroits requis : `.planning/REQUIREMENTS.md:839` (ligne LEDG-03) et `.planning/STATE.md:331`
(entrée datée avec repli GO-RÉDUIT écrit). Seule nuance cosmétique : la case à cocher de
`.planning/REQUIREMENTS.md:934` reste `[ ]` non cochée malgré l'URL déjà renseignée — sans impact
fonctionnel, signalé pour mémoire.

---

### WKTR-03 — veille de release gsd-core > 1.10.0 active — ✅ PASS

**Preuve directe :** `scripts/check-gsd-core-update.sh` implémenté conforme à D-10 : interroge
`npm view @opengsd/gsd-core version` (jamais `next`), comparaison `sort -V` (piège lexical évité),
cache quotidien, fail-open silencieux hors ligne (jamais de cache réécrit sur échec réseau).
```
bash scripts/tests/test-check-gsd-core-update.sh → 13 OK / 0 KO
```
avec 3 mutations prouvées discriminantes (comparaison lexicale, cache réécrit sur échec réseau,
gate d'âge retiré). `30-VEILLE-GSD-CORE.md` documente honnêtement le caractère machine-local
(non distribué) et la leçon déjà payée (« armement sans précondition distribuée », régression #38)
— **et** l'armement est effectivement ACTIF sur cette machine au moment de la vérification :
```
$ cat .claude/settings.json
{"hooks":{"SessionStart":[{"matcher":"startup","hooks":[{"type":"command",
"command":"/bin/bash","args":["/Users/samuel/.../scripts/check-gsd-core-update.sh","--hook"]}]}]}}
```

---

## Décisions D-01 à D-11 (`30-CONTEXT.md`) — reflétées dans le code livré

| # | Décision | Statut | Preuve |
|---|----------|--------|--------|
| D-01 | Phase 30 porte tout `merge-hooks.sh` + résolution bash absolue | ✅ | `resolve_bash_abs()` l.96-112, ADR-071 |
| D-02 | Exit `vf_guard_unavailable` non nul ≠ 2 | ✅ | `VF_GUARD_UNAVAILABLE_EXIT_CODE=17` (vf-portable.sh:130) |
| D-03 | Amendement spec + commentaire PR #29 | ✅ | spec l.217, commentaire PR posté 2026-08-15T18:58:58Z |
| D-04 | Phase 30 écrit `vf-portable.sh` + `copy_engine_lib()` | ✅ | PORT-01 ci-dessus |
| D-05 | Hook doctor conductor différé, dépendance guard-file-size levée | ✅ | `30-RELIQUATS.md` reliquat 1, marqueurs fail-safe en place |
| D-06 | Normalisation dans chaque script, pas de `run-hook.sh` | ✅ | `docs/HOOKS-CONTRAT-SORTIE.md` §2, code lu (check-dev-bootstrap.sh etc.) |
| D-07 | Périmètre normalisation = tout le parc (26 entrées) | ✅ | `test-hook-exit-parc.sh` 42/42, exclusions nommées |
| D-08 | Inventaire 25→26, plan fait foi | ✅ | recompte machine = 26 |
| D-09 | RFC draft validé par Samuel avant post | ✅ | `30-RFC-UPSTREAM.md` §Statut, issue postée identique au draft |
| D-10 | Veille SessionStart advisory, cache quotidien, jamais `next`, repo-local | ✅ | script + tests + armement constaté actif |
| D-11 | Traçabilité STATE.md + REQUIREMENTS.md | ✅ | les deux fichiers portent l'entrée LEDG-03 |

---

## Addendum humain du 2026-08-15 (option A)

| Item | Statut | Preuve |
|---|---|---|
| Routage borné du chemin machine vers `settings.local.json` | ✅ PASS | `is_local_entry()`/`split_fragment_hooks()` dans merge-hooks.sh, `--settings-local` câblé dans vibeflow-update.sh (l.383-424), tests T15-T21c (test-merge-hooks.sh) |
| Amendement LOCK-02 de la Phase 32 | ✅ PASS | `.planning/ROADMAP.md:636-650`, texte exact vérifié (« arbitré par Samuel le 2026-08-15… ») |
| Correction du trou `.gitignore` en scope local | ✅ PASS | `gitignore_add_one ".claude/settings.local.json"` + `".claude/scripts/vf-portable.sh"` (vibeflow-update.sh l.226-241), tests T3c/T3c-négatif verts |
| Filet SessionStart de détection des chemins périmés (plan 30-09, `bash` nu, paradoxe d'amorçage gravé en ADR) | ✅ PASS | `check-hook-paths.sh` existe (26e entrée), `hooks.json` porte `"command": "bash"` littéral, ADR-071 addendum documente exactement ce cas, T9 (test-check-hook-paths.sh) discriminance par mutation m3 |

---

## Reliquats connus — traçabilité

| Reliquat | Documenté où | Statut |
|---|---|---|
| Hook doctor `conductor` différé (D-05) | `30-RELIQUATS.md` reliquat 1 | ✅ tracé |
| `test-dev-orchestrator.sh` migré hors contrat §7 | `30-RELIQUATS.md` reliquat 2 | ✅ tracé |
| Écart de comptage settings.json (~12 vs 2) | `30-05-SUMMARY.md` §Décisions/D-05 | ✅ tracé |
| ADR-071 absente de la dérogation `check-hook-paths.sh` avant addendum | `docs/HOOKS-CONTRAT-SORTIE.md` §4 (« Reliquat »), soldé par le commit `193b252` | ✅ tracé et soldé |
| **4 mineurs de revue** (séparateur `\t` non échappé, branches défensives non couvertes, `mk_settings()` sans échappement, `--help` verbeux à 94 lignes) | **INTROUVABLE** — recherche exhaustive sur `30-VALIDATION.md`, les 9 `*-SUMMARY.md`, `30-RELIQUATS.md`, `docs/ADR.md`, `docs/HOOKS-CONTRAT-SORTIE.md`, les messages de commit du DAG | ⚠️ **WARNING — non tracé** |

Le dernier point est un manquement à la discipline même que `30-RELIQUATS.md` revendique
explicitement (« rien de différé ne reste tacite ») : ces 4 constats de revue mineurs, mentionnés
au mandat de vérification, ne sont matérialisés nulle part dans le dépôt à ma recherche — ni comme
reliquat, ni comme item de dette, ni comme mention dans un commit. Soit ils proviennent d'une revue
externe (ex. `/code-review`) dont la sortie n'a jamais été persistée dans le dépôt, soit ils n'ont
jamais été consignés. Recommandation : les faire écrire (même a posteriori, dans
`30-RELIQUATS.md` ou une nouvelle entrée), ou confirmer qu'ils sont déjà corrigés ailleurs — je n'ai
trouvé trace ni de la correction ni de la dette.

---

## Suites de tests exécutées en direct pendant cette vérification (jamais relayées d'un SUMMARY)

| Suite | Résultat |
|---|---|
| `test-vf-portable.sh` | 13 OK / 0 KO |
| `test-merge-hooks.sh` | 25 OK / 0 KO |
| `test-hook-exit-parc.sh` | 42 OK / 0 KO |
| `test-check-gsd-core-update.sh` | 13 OK / 0 KO |
| `test-dev-orchestrator.sh` | 184 OK / 0 KO |
| `test-vibeflow-update.sh` | 19 OK / 0 KO |
| Passe complète (61 suites, `find plugin scripts -path '*/tests/test-*.sh'`) | 61/61 vertes localement, 0 échec |
| `check-version-sync.sh` | 0 (vert) |
| `check-machine-paths.sh` | 0 (vert) |
| `check-state-integrity.sh` | 0 (vert) |
| `check-agents.sh --strict` (6 répertoires `plugin/*/agents`) | 0 partout |
| **Run CI réel (`gh run view 31917741411`)** | **failure — job "Lab frais armé", étape PORT-05** |

La divergence entre « 61/61 vertes en local » et « CI rouge sur le tip poussé » est exactement le
motif des quatre faux verts précédents de cette phase : les suites locales ne couvrent PAS le
mécanisme de résolution de fermeture que la CI exerce spécifiquement pour PORT-05 (as-installed
testing, patron né de la régression #38) — un vert local ne suffit donc pas à certifier PORT-05.

---

## Observations mineures (non bloquantes)

- `.planning/STATE.md` (`stopped_at: Phase 30 context gathered`, « Current focus… à cadrer ») est
  périmé par rapport à l'avancement réel (9 plans exécutés) — probablement à mettre à jour au
  ship, signalé pour mémoire.
- `.planning/REQUIREMENTS.md` liste encore PORT-01/02/03/05 et WKTR-03 comme « Pending » — cohérent
  avec une phase non encore shippée, pas un gap en soi.
- Case à cocher LEDG-03 non cochée dans `REQUIREMENTS.md:934` malgré l'URL déjà renseignée.

---

## Résumé du verdict

**PASS net :** PORT-01, PORT-02, PORT-03, PORT-04, LEDG-03, WKTR-03, les 11 décisions D-01..D-11,
les 4 items de l'addendum humain du 2026-08-15, les 4 reliquats structurels déjà connus. Preuves
fortes : code lu ligne à ligne, tests rejoués en direct (pas relayés), mutation testing vérifié,
requêtes GitHub réelles (issue + PR).

**BLOCKER :** PORT-05 — la preuve CI, telle qu'elle existe RÉELLEMENT sur `origin` au moment de
cette vérification, est rouge. Un correctif local non poussé semble techniquement juste (vérifié
par simulation indépendante) mais n'a jamais été éprouvé par un run CI réel, et le geste humain de
clôture exigé par le plan 30-08 (`30-08-SUMMARY.md` avec l'identifiant d'exécution) n'existe pas.

**WARNING :** les « 4 mineurs de revue » mentionnés au mandat de vérification sont introuvables
dans le dépôt — ni corrigés de façon visible, ni tracés comme dette.

**Action recommandée avant tout re-passage au vert :** pousser le correctif, constater un run CI
réel vert (les deux étapes PORT-05 du job « Lab frais armé », plus le reste du parc), écrire
`30-08-SUMMARY.md` avec l'ID d'exécution et le verdict par job, et retrouver ou consigner les 4
mineurs de revue portés disparus.

---

## Addendum — 2026-08-16

Cet addendum ne modifie AUCUN constat ci-dessus : le BLOCKER PORT-05 rapporté était **vrai à sa
date** (run `31917741411`, commit `dcd9eb5`, correctif local non poussé). Il est ajouté pour
consigner ce qui s'est produit depuis, sans réécrire l'historique du rapport d'origine.

**Le correctif nommé ci-dessus (commit `4edc9688`... — hash exact `4edc968`) a été poussé.** Un
nouveau run CI a été déclenché et est **vert sur ses 4 jobs** : `gh run view 31918283177` →
`Suites de tests`, `Lab frais`, `Gates de qualité (mode strict)`, `Lab frais armé` — tous en
succès. Preuves nommées, extraites du journal de ce run :

- `== attendu dérivé des hooks.json de la fermeture : 5 entrée(s) VF ==`
- `== forme exec telle qu'installée : 5 entrée(s) VF, command absolu+exécutable (sauf dérogation
  nommée check-hook-paths.sh), aucun placeholder, aucune construction shell ==`
- `test-windows-crlf.sh` et `test-windows-guards.sh` nommés dans le journal, chacun étiqueté
  « simulation — pas de poste Windows réel »
- `== 61 suite(s) découverte(s) ==`

**PORT-05 est donc PROUVÉ** : la mécanique en défaut au run rouge (un attendu codé en dur décrivant
un univers — dev-orchestrator + software-architecture — que le job « lab frais armé » n'installe
jamais réellement, lui qui installe la seule fermeture résolue de `dev-orchestrator`) a été
corrigée en dérivant l'attendu, à chaque exécution, des `hooks.json` sources de la fermeture
réellement résolue (`resolve-deps.sh`), avec deux gardes indépendantes (`dev-orchestrator ∈
$closure`, `attendu > 0`) qui empêchent la mesure de se satisfaire elle-même à vide. Le geste
humain de clôture du plan 30-08 (checkpoint bloquant, tâche 3) est désormais consigné dans
`.planning/phases/VFDO-30-portabilit-windows-ii/30-08-SUMMARY.md`, avec l'identifiant d'exécution
et le verdict par job.

**Le BLOCKER PORT-05 est donc LEVÉ.**

Le WARNING sur les « 4 mineurs de revue introuvables » était **juste** — ils n'étaient effectivement
tracés nulle part sur disque au moment de cette vérification. Il est désormais **soldé** : les 4
mineurs sont consignés dans `.planning/phases/VFDO-30-portabilit-windows-ii/30-RELIQUATS.md`
(section « Reliquats de revue — solde de la clôture de phase, 2026-08-16 »), chacun avec son
fichier, sa raison de non-correction et son risque résiduel — pas corrigés, mais plus « disparus ».

**Verdict final de phase, à la date de cet addendum :** les 8 exigences visées par cette
vérification (PORT-01, PORT-02, PORT-03, PORT-04, PORT-05, LEDG-03, WKTR-03, et la couverture des
11 décisions D-01..D-11 + l'addendum humain du 2026-08-15) sont **PASS**. Aucun BLOCKER restant.
