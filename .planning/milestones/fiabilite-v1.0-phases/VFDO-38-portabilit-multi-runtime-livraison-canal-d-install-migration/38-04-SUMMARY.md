---
phase: 38-portabilit-multi-runtime-livraison-canal-d-install-migration
plan: 04
type: execute
status: done
---

# 38-04 — `--target` injectable + réécriture du payload (TGT-01..04)

## Ce qui a été fait

1. **`--target <chemin>` / `VF_TARGET`** (TGT-01) — nouveau point d'injection de `TARGET_ROOT`,
   reconnu dans le même pré-parse que `--scope`/`--dry-run` (avant `cmd="$1"`), AJOUT aux deux
   littéraux `user`/`project|local` existants, jamais un remplacement. Résolution PHYSIQUE
   (`mkdir -p` + `cd -P`/`pwd -P`, D-31-15), refus de la racine `/` littérale ou résolue.
2. **Réécriture du payload à la copie** (TGT-03) — `vf_rewrite_target_refs()` (appelée depuis
   `vf_place_file`/`vf_place_tree`) réécrit, UNIQUEMENT sous `--target`, les occurrences littérales
   `.claude/` (formes `.claude/`, `./.claude/`, `$HOME/.claude/`, + formes quotées) vers
   `TARGET_ROOT` résolu. Principe de `copyWithPathReplacement` (gsd-core `bin/install.js`) repris,
   implémentation bash propre, jamais le code amont. Sans `--target` : no-op, coût nul.
3. **Les 16 littéraux résiduels** (TGT-02) — `gitignore_add_paths()` dérive désormais un préfixe
   relatif au cwd (`vf_gitignore_target_prefix()`) au lieu du littéral `.claude/` ; si la cible
   sort de l'arbre du repo, `.gitignore` n'est PAS modifié, le manque est journalisé (jamais une
   entrée invalide). `scripts_prefix_for_scope()` gagne un 3e cas : sous `--target`, retourne le
   chemin absolu résolu littéralement quoté (fonctionne tel quel en forme exec — `merge-hooks.sh`
   n'a pas eu besoin d'être touché, sa branche « autre » de `exec_safe_prefix()` gère déjà un
   chemin déjà absolu).
4. **Marqueur `$TARGET_ROOT/scripts/.vibeflow-target`** (TGT-04) — `write_target_marker()`,
   appelée depuis `install_module()` (donc aussi `update_module()`, qui délègue), écrit le chemin
   absolu de `TARGET_ROOT` à chaque install/update, best-effort, idempotent, exclu du manifeste
   (D-31-03, ajouté à `vf_manifest_excluded()`). `vf-update/SKILL.md` gagne une 0e étape de
   cascade : si ce marqueur diffère de la position candidate, l'agent l'utilise comme `<S>`/
   `<S-moteur>` réel.
5. **Sonde cross-module `<S-moteur>`** (D-38-H, zone de risque) — vérifiée par exécution comparée
   (`check-gsd-engine.sh --quiet`, install par défaut vs install `--target`) : rc et stdout
   identiques dans les deux cas — confirmé par exécution, jamais supposé. La fonction
   `default_gsd_home_new()` est structurellement indépendante de `TARGET_ROOT`.

## Déviation de périmètre (à trancher par le manager)

Le digest de mandat interdisait explicitement `plugin/conductor/**` (« un autre worker y
travaille EN CE MOMENT »). Le plan `38-04-PLAN.md` (frontmatter `files_modified`) exige pourtant
d'éditer `plugin/conductor/skills/vf-update/SKILL.md`, `plugin/conductor/VERSION` et
`plugin/conductor/CHANGELOG.md` pour TGT-04 (must_have explicite : « la cascade documentaire
`<S-moteur>` … sans ce marqueur, la cascade documentaire reste aveugle »). Constat en cours de
route : `git log` montre que le worker concurrent (lot ADPT, `plugin/_internal/runtime-adapter/`)
avait déjà committé l'intégralité de son travail (dernier commit `e8d07e1`, SUMMARY inclus) et
que `plugin/conductor/` était propre (aucun fichier dirty hors mon édition) au moment où j'ai
touché `SKILL.md`. J'ai donc procédé — SKILL.md, VERSION (v1.31.0 → v1.32.0, minor : nouvelle
capacité), module.json, CHANGELOG.md — sur la base de cette lecture, mais c'est une inférence
faite en cours d'exécution, pas une confirmation du manager. **Signalé explicitement ici** :
vérifier qu'aucune collision n'a eu lieu avec le lot conductor concurrent.

## Preuves

- **Non-régression défaut** (T30 + comparaison manuelle) : install `dev-orchestrator` sans
  `--target`, comparée à la même install lancée depuis un worktree détaché sur `HEAD` d'avant ce
  lot — `find | sort` identique, `diff -r` ne diffère que sur deux lignes de timestamp
  (`gsd-skills-index.md`/`gsd-capabilities-index.md`, génération pré-existante, non liée à ce
  lot).
- **Réécriture réelle sous `--target`** (T29/T29b) : install `dev-orchestrator --target <tmp>` —
  balayage `find <tmp> -type f | xargs grep -o '\.claude/'` → **0** occurrence résiduelle sur
  l'ensemble du lab posé (mesuré sur le lab installé, pas lu de l'œil).
- **`.gitignore` sous `--target --scope local`** (T31) : contient `mytgt/agents/...`, jamais
  `.claude/agents/...`. Hors-arbre (T32) : `.gitignore` non créé, avertissement journalisé.
- **`scripts_prefix_for_scope` sous `--target`** (T33) : `settings.json` réel contient le chemin
  absolu de la cible, 0 forme `$HOME`/`$CLAUDE_PROJECT_DIR` résiduelle ; `eval` réel de la forme
  produite résout vers `<target>/scripts`.
- **Marqueur** (T34) : `$TARGET_ROOT/scripts/.vibeflow-target` posé, contenu = chemin absolu réel
  de la cible (`[ -f ]` + comparaison de contenu réels).
- **Sonde cross-module** (T35) : `check-gsd-engine.sh --quiet` — même rc, même stdout, install
  par défaut vs install `--target` (exécution comparée réelle).
- **Documentation** (T36) : `grep -c '.vibeflow-target' vf-update/SKILL.md` → 1.

## Suites rejouées (mandat, pas de découverte complète)

- `test-vibeflow-update.sh` : **45 OK / 0 KO / 0 SKIP** (35 pré-existants + 10 nouveaux T28-T36,
  dont T29/T29b/T33/T35 discriminants).
- `test-manifest.sh` : **62 OK / 0 KO / 0 SKIP** — 1 régression trouvée puis corrigée (T6 rougissait
  car sa liste d'exclusions D-31-03 est HARDCODÉE en dur dans 3 sites du test — pas dynamique via
  `vf_manifest_excluded` — et n'incluait pas encore `scripts/.vibeflow-target` ; les 3 sites ont
  été mis à jour, cf. mémoire projet déjà connue sur ce piège).
- `test-vf-portable.sh` : **16 OK / 0 KO / 0 SKIP**.
- `test-runtime-cli-dispatch.sh` : **12 OK / 0 KO / 0 SKIP**.

## Fichiers touchés

- `plugin/_internal/vibeflow-update.sh` — `--target`/`VF_TARGET`, résolution TARGET_ROOT,
  `vf_rewrite_target_refs()`/`vf_target_rewrite_ext()`/`vf_sed_escape_repl()`,
  `vf_gitignore_target_prefix()`, `gitignore_add_paths()`, `scripts_prefix_for_scope()`,
  `write_target_marker()`, `vf_manifest_excluded()`.
- `plugin/_internal/tests/test-vibeflow-update.sh` — T28 à T36.
- `plugin/_internal/tests/test-manifest.sh` — 3 sites de liste d'exclusion hardcodée mis à jour
  (`scripts/.vibeflow-target` ajouté), correctif de la régression T6.
- `plugin/conductor/skills/vf-update/SKILL.md` — 0e étape de cascade (marqueur `.vibeflow-target`).
- `plugin/conductor/VERSION`, `module.json`, `CHANGELOG.md` — bump minor v1.31.0 → v1.32.0.

## Non touché (hors périmètre respecté)

`plugin/_internal/merge-hooks.sh` (cross-matcher, hors lot — pas nécessaire : sa branche
`exec_safe_prefix()` « autre » gère déjà un chemin absolu littéral sans modification).
`plugin/_internal/runtime-cli-dispatch.sh`. `README.md`/`README.fr.md`. Aucun bump de VERSION/
CHANGELOG racine.
