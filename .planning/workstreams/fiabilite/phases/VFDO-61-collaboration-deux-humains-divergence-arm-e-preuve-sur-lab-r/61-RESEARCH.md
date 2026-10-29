# Phase 61 — Recherche (courte, faits mesurés sur la branche feat/phase-61-collaboration, 2026-10-29)

Le chercheur délégué (`gsd-phase-researcher`, lancé 06:19) n'a rien écrit en deux heures ; décision du manager : recherche courte écrite par le planificateur. Seuls des faits sourcés ci-dessous ; rien n'est tranché ici.

## 1. Point d'armement (COLB-01, COLB-02, COLB-03)
- `role_apply()` : `plugin/_internal/vibeflow-update.sh:1331-1357`. Sorties anticipées : scope user (toujours `solo`), `--target` (aucun fichier posé), `solo` sans fichier de poste (sans `--changement`). Appelé à deux endroits : verbe `install` (l. 3468, une fois en tête) et verbe `role` (l. 3555, `--changement`).
- Résolution sans l'arbre du lab : `find_role_gate()` (l. 1268-1274) ne lit que `$CACHE_DIR/conductor/scripts/...`, jamais `$TARGET_ROOT/scripts` (audit M-2). `CACHE_DIR="${VIBEFLOW_CACHE:-.vibeflow-cache}"` (l. 406) : la valeur par défaut est RELATIVE au cwd. Le hook doit donc embarquer le chemin ABSOLU résolu (`cd "$CACHE_DIR" && pwd -P`) au moment de l'armement, et l'armement doit refuser (audiblement) un cache situé sous l'arbre versionné du lab.
- Désarmement : `role_apply` ne retire rien aujourd'hui ; le retour à `solo` passe par `role_apply --changement` (l. 3555). Le chemin de désinstallation est `uninstall_module` (l. 3127) et le cas `uninstall` du `case "$cmd"` (l. ~3500). Aucun point ne connaît encore un hook git : `git grep 'post-merge\|hooksPath' plugin/_internal/` (rc=1 selon le cadrage).
- Hook de référence (à ne pas modifier) : `scripts/hooks/post-merge:14-46`. Ancre `--git-common-dir` + `--show-toplevel` ; branchement 1 → crie, 0 et 3 → silence, autre → non vérifiable sans bloquer. NB : il résout l'exécutable depuis le dépôt principal, ce qui est SA source de confiance ; dans un lab, l'exécutable est dans le cache du plugin (P61-D-03), donc le hook posé diffère de ce modèle sur ce seul point.
- Suite de référence de l'engine : `plugin/_internal/tests/test-vibeflow-update-role.sh` (HOME jetable, cache jetable, `mktemp -d` + `git init -q`, `ok()/ko()`, comptages par awk, `cmp -s` ; mutants RV-Mn). Convention : suite NEUVE, jamais un ajout à `test-vibeflow-update.sh` (271 s).

## 2. Git : quels hooks se déclenchent (P61-D-05) — mesuré, git 2.50.1 (Apple Git-155)
- `git pull` (avance rapide) : `post-merge` se déclenche (argument `0`). `git merge --no-ff` : `post-merge` se déclenche.
- `git pull --rebase` avec commit local : seul `post-rewrite` (argument `rebase`) se déclenche ; `post-merge` NON. Réponse mesurée : sans `post-rewrite`, un `pull --rebase` échappe au filet.
- `git rev-parse --git-path hooks` rend `<dir commun>/hooks` aussi depuis un worktree lié ; `core.hooksPath` absent par défaut (rendu : rien). Un hook posé là sert le clone ET ses worktrees.
- Reste à mesurer à l'exécution : comportement du hook sous Git Bash et avec husky (`core.hooksPath` posé → le répertoire réel change ; l'armement doit lire `git rev-parse --git-path hooks` APRÈS cette config, jamais supposer `.git/hooks`).

## 3. `check-divergence.sh` (COLB-04, COLB-07)
- Contrat : `plugin/conductor/scripts/check-divergence.sh:1-70` ; `--path <dir>` ; codes 0 conforme, 1 divergence (S2 orphelin, S4 roadmap, S5 racine), 2 non vérifiable, 3 silence (dépôt non partitionné), 64 usage. Le commentaire l. 61-62 (« exit 3 = état nominal de ce dépôt ») est périmé (la racine est partitionnée) : à corriger si la phase touche le fichier — alors trailer `Gate-Touche`.
- Suite existante : `plugin/conductor/scripts/tests/test-check-divergence.sh` (21,9 K) : ni clone ni merge ; aucune suite n'exerce un hook `post-merge` aujourd'hui. Précédent hook armé sur dépôt jetable : Phase 39, `39-01-SUMMARY` (`GATE_FIRED`).
- Fabrique de divergence : S2 = deux dossiers de phase du même compartiment avec le même préfixe numérique (un clone crée `phases/05-x`, l'autre `phases/05-y`, la fusion est sans conflit textuel).

## 4. Journal (COLB-04)
- Précédent d'emplacement : verrou et registre d'enfants sous le répertoire git commun (`<git-common-dir>/vf-driver/...`, par exemple `DRIVER.lock.children.jsonl`). Non versionné, partagé par les worktrees du clone. Format ligne par ligne, ajout seul (`>>`), pas de rotation requise.

## 5. Registres (COLB-06)
- Gabarits : source `plugin/reference/content/methodology/templates/memory/{decisions,learnings,blockers}-template.md` ; copies `plugin/consolidator/references/templates-memoire/` — MESURÉ : les deux emplacements DIFFÈRENT déjà (`cmp` : decisions, learnings, blockers, evals différents). La « règle SYNC » ne vaut donc pas copie octet à octet : ajouter la même ligne `**Role** :` aux deux, sans écraser l'une par l'autre.
- Format d'entrée existant : lignes `**Champ** : valeur` (DECISIONS : Date, Statut, Decideur, Contexte, Thinking Level ; LEARNINGS : Date, Categorie, Decouvert lors de, Encode dans ; BLOCKERS : Date, Sprint, Statut, Temps Perdu, Severite, Source, Learning associe).
- Parseurs sous `plugin/consolidator/scripts/` : `check-registres.sh`, `reindex.sh` (l. 150 : `**Date** :` ; l. 180 : saute les lignes `**`), `archive.sh` (l. 175-264 : `**Date**`, `**Statut**` par awk), `detect-duplicates.sh`, `detect-promotions.sh`. Aucun ne cible `**Role**` aujourd'hui : l'optionnalité est à PROUVER par suite (`test-check-registres.sh`, `test-consolidator.sh`, fixtures du dossier `tests/fixtures`), avec et sans le champ.
- Lecteur du poste : `plugin/conductor/scripts/vf-role.sh get [--path <dir>]` — codes 0 valeur, 1 invalide, 5 illisible, 64 usage (l. 18-47) ; priorité `VF_ROLE` > `.claude/vibeflow-role` > `solo`. Suite : `plugin/conductor/scripts/tests/test-vf-role.sh`.

## 6. CI, gates, livraison (COLB-09)
- Découverte des suites : `find plugin scripts -type f -path '*/tests/test-*.sh'` (`.github/workflows/ci.yml:218`), refus d'un verdict vide (l. 223). Une suite neuve sous `*/tests/` est découverte sans câblage.
- Modules touchés (bump `VERSION`, `CHANGELOG.md`, `module.json`, `README.md`) : conductor v1.51.0, consolidator v1.11.3, reference v2.5.8, le module porteur de l'engine `plugin/_internal/` (à identifier à la planification : pas de `VERSION` propre mesuré). README de conductor : `check-divergence.sh` décrit l. 241-245 comme consommé par `scripts/hooks/post-merge` « opt-in » ; le compte de suites du README racine bouge avec toute suite neuve.
- Précédents de plans : `.planning/workstreams/fiabilite/phases/VFDO-60-*/60-0x-PLAN.md` ; porte de phase 60-09 (rejeu `replay-ci-jobs.sh --job gates` sous `.planning/milestones/fiabilite-v1.0-phases/VFDO-40.1-*/tools/`, arrêt avant PR). Suites rejouées une à une ; ledger à la main.

## 7. Questions ouvertes (à écrire en bloqueurs par le planificateur si 61-CONTEXT.md n'a pas de défaut)
- Q1 : forme exacte du désarmement quand un hook existant a été fusionné à la main par l'utilisateur (reconnaissance du hook « nôtre » : marqueur textuel versionné dans le fichier).
- Q2 : seuil du cache « sous l'arbre versionné » (chemin relatif `.vibeflow-cache` par défaut, l. 406) : refuser ou résoudre ?
- Q3 : module porteur du bump de l'engine `plugin/_internal/` ; manuel FR+EN : page(s) à mettre à jour (à repérer par `check-manual.sh`).

## Validation Architecture
| Exigence | Commande automatisée | Direction d'échec observable |
|---|---|---|
| COLB-01, 02, 05 | suite neuve d'engine `plugin/_internal/tests/test-vibeflow-update-hook.sh` (poste product/dev arme ; solo non ; hook tiers préservé ; opt-out) | un `ko` ; exit 1 |
| COLB-03 | même suite : hook exécuté depuis un clone dont l'arbre contient un `check-divergence.sh` piégé ; le piège ne s'exécute pas | marqueur du piège présent dans la sortie → ko |
| COLB-04 | même suite + 2 clones : ligne de journal, code 1/0/3/autre, `post-rewrite` | journal vide ou rc faux → ko |
| COLB-06 | `bash plugin/consolidator/scripts/tests/test-consolidator.sh` et `test-check-registres.sh` étendues (avec/sans champ) | un parseur rouge sur entrée avec champ |
| COLB-07 | suite à deux clones jetables par le vrai chemin d'installation + mutants (hook désarmé, exécutable muté) | le témoin muté doit rougir |
| COLB-08 | document de recette présent et complet (grep des rubriques) ; case décochée | rubrique absente |
| COLB-09 | `check-instruction-budget.sh`, `check-agents.sh --strict`, `check-manual.sh`, `replay-ci-jobs.sh --job gates` | rc != 0 |
