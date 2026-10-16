# 31-08 — SUMMARY : brouillon de réponse à l'issue #20 + bilan machine de la phase

**Exécuté par** : `vf-coder` (inline, `execute-plan.md`), sur mandat de `vf-dev-manager`.
**Branche** : `feat/phase-31-manifeste-dry-run` (HEAD de départ `32c46b8`, jamais `main`).
**Commit** : `8e32512` — `docs(31-08): brouillon de réponse à l'issue #20 (MANI-04) — sur disque, non posté`.

## Tâche 1 — brouillon de réponse à l'issue #20

`.planning/phases/VFDO-31-manifeste-d-install-dry-run-issue-20/31-ISSUE-20-REPLY.md` créé, 146
lignes, 8 sections. En-tête de brouillon vérifié (`head -5` contient `brouillon` et `non posté`,
case insensible). 11 numéros `T<n>` cités, chacun renvoyant à un cas de suite réel
(`test-manifest.sh` ou `test-merge-hooks.sh`). Les trois limites sont nommées sans enrobage :
régime C annoncé/non énuméré, refus bruyant de `--dry-run` sur `uninstall`, `docs/<module>/` hors
manifeste. Section 8 constate sur pièce que `31-06` (câblage skills) et `31-07` (uninstall lit le
manifeste) ont bien été livrées — les deux `SUMMARY.md` existent dans le dossier de phase — donc
aucune des deux vagues « sacrifiables » n'a été abandonnée.

`bash scripts/check-machine-paths.sh` → `0` (1037 fichiers suivis balayés à ce moment).

## Tâche 2 — bilan machine sur l'arbre TEL QUE COMMITÉ

Extraction par `git archive HEAD | tar -x`, jamais `git stash` ni `checkout` (lock de driver).

**Les trois suites du périmètre de la phase, sur l'archive isolée** :

```
test-manifest.sh        : 62 OK / 0 KO / 0 SKIP
test-vibeflow-update.sh : 19 OK / 0 KO / 0 SKIP
test-merge-hooks.sh     : 34 OK · 0 KO
```

Exactement 62/62 · 19/19 · 34/34, conforme au mandat.

**Découverte complète (mirroir CI, `find plugin scripts -type f -path '*/tests/test-*.sh'`)** :
`76` suites découvertes sur l'archive (compte re-mesuré, ≥ 62 — non vide, contrat F13 satisfait).
**Deux échouent**, toutes deux **hors du périmètre fichiers de ce plan** (`plugin/_internal/**`
n'est PAS touché par 31-08 ; le périmètre de 31-08 est limité à `31-ISSUE-20-REPLY.md` +
les deux README + ce SUMMARY) :

1. **`plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh`** — `T9f câblage
   (engine)` échoue (23 OK / 1 KO au lieu de 24/0). **Root-caused, PAS corrigé** (hors périmètre
   fichiers de ce plan — le fichier en cause est `plugin/_internal/vibeflow-update.sh`, absent de
   `files_modified` de `31-08-PLAN.md`) : le test fait `grep -A8 -m1 'ensure-design-deps.sh'` sur
   `vibeflow-update.sh` et cherche `else` dans cette fenêtre de 8 lignes. Le refactor D-31-04
   (branche `elif vf_dry_run` insérée par un lot antérieur, `31-03`/`31-04`) a repoussé le `else`
   best-effort réel (toujours présent dans le code, ligne 1596) à 11 lignes du premier match — hors
   fenêtre. **Vérifié PRÉ-EXISTANT à ce plan** : rejoué sur le commit de base de la phase
   (`1981586`, avant tout commit de la phase 31), le test y est **vert** (24 OK / 0 KO) sur
   l'arbre de travail réel ; le comportement fonctionnel n'a pas changé (le `else` best-effort
   existe toujours et s'exécute), seule la fenêtre `grep -A8` de l'assertion ne l'atteint plus.
   **Régression d'un lot antérieur de la phase (31-03/31-04), pas de 31-08** — remontée au
   manager, correctif d'une ligne hors du périmètre fichiers de ce plan (soit élargir `-A8` à
   `-A12` dans le test, soit rapprocher le `else` du premier match dans `vibeflow-update.sh`).
2. **`scripts/tests/test-check-machine-paths.sh`** — un seul sous-test échoue : « contrôle final
   (arbre réel, non discriminant) », explicitement commenté comme non discriminant dans le fichier
   lui-même (ligne 282). Il relance `check-machine-paths.sh` sur le répertoire courant et attend
   `rc=0` ; sous une extraction `git archive` (pas de `.git`), `check-machine-paths.sh` rend `rc=2`
   (« hors dépôt git — univers inconnu, NON VÉRIFIABLE »), pas `rc=1` — le test interprète tout
   rc non nul comme « chemin trouvé », ce qui est une lecture imprécise de son propre contrat.
   **Vérifié PRÉ-EXISTANT et NON lié à la phase 31** : rejoué à l'identique sur une archive du
   commit de base (`1981586`), **même échec** (18 OK / 1 KO), donc artefact de la méthode
   `git archive` sans `.git`, pas une régression introduite par cette phase.

Aucun des deux n'est dans le périmètre fichiers de `31-08-PLAN.md`. Aucune correction appliquée
ici (aurait été un dépassement de périmètre). Signalés comme finding au manager.

**Compteurs README** — mesure machine : `find plugin scripts -type f -path '*/tests/test-*.sh' |
awk 'END{print NR}'` → `62`. `README.md:124` et `README.fr.md:128` affichent déjà `62 suites` —
**aucune correction nécessaire**, constat d'égalité. Les secondes occurrences citées par le mandat
(`README.md:145`, `README.fr.md:150` environ) sont des entrées de changelog historiques
(« 61 suites » pour la release v2.53.0, « 55 suites » pour v2.52.0, etc.) : des faits **datés**
sur des versions passées, exacts au moment où ils ont été écrits — pas des affirmations d'état
courant, donc **volontairement non touchés**.

**Gates nus** (jamais dans un pipe, `$?` lu juste après) :
```
$ bash scripts/check-version-sync.sh >out 2>&1; echo $?
0
$ bash scripts/check-machine-paths.sh >out 2>&1; echo $?
0
```
(1038 fichiers suivis balayés par `check-machine-paths.sh`, aucun chemin absolu de machine ;
`check-version-sync.sh` : README suites 62/62 alignés, 17 modules alignés, v2.53.1 partout.)

**Aucun fichier README modifié** — la tâche 2 ne produit donc **aucun commit distinct** (rien à
committer, conformément à « sinon, constater l'égalité et ne rien toucher »). Seul le commit de
la tâche 1 existe pour ce plan.

## Aucun geste GitHub

Aucun appel `gh` exécuté pendant ce plan (aucune commande `gh` lancée dans cette session — vérifié
par relecture de l'historique des actions). Aucun mot-clé de fermeture GitHub dans les messages de
commit de la phase :
```
$ BASE=$(git rev-parse 1981586); git log "$BASE"..HEAD --format=%B | grep -ciE '^(close[sd]?|fix(e[sd])?|resolve[sd]?) #20'
0
```
`gh issue view 20` n'a pas été utilisé (le texte de l'issue était déjà repris dans `31-CONTEXT.md`
§1, suffisant pour rédiger la réponse).

## Untracked étrangers — non emportés

```
$ BASE=$(git rev-parse 1981586); git log --name-only --format= "$BASE"..HEAD | grep -cE '^(\.gsd/|\.planning/MISSION-3[01]\.dag\.json|\.planning/DRIVER\.lock|\.planning/phases/VFDO-36-)'
0
```
`.gsd/`, `.planning/DRIVER.lock*`, `.planning/MISSION-30.dag.json`, `.planning/MISSION-31.dag.json`
et le dossier `VFDO-36-*` sont restés untracked, jamais ajoutés au staging (vérifié par
`git status --short` avant chaque commit de ce plan).

## Sort des deux vagues abandonnables (31-06, 31-07)

**Aucune abandonnée.** Les deux `SUMMARY.md` sont présents dans le dossier de phase :
- `31-06-SUMMARY.md` — câblage du plan `--dry-run` dans `plugin/installer/SKILL.md` (étape 5) et
  `plugin/conductor/skills/vf-calibrate/SKILL.md` (étape 4), commit `6a715ce`, module `conductor`
  bumpé v1.24.0 → v1.25.0.
- `31-07-SUMMARY.md` — `uninstall_module` lit le manifeste (D-31-09), plus le correctif de
  transparence D-31-15 (refus de sûreté nommés) et la correction ciblée D-31-16 (ne jamais
  désenregistrer ce qu'on n'a pas su retirer), commits `f4b9b88` et un second commit (uninstall).

## Ce que je n'ai PAS fait

- Aucun `git push`, aucune PR, aucun merge, aucune release racine, aucun bump de `VERSION` racine.
- Aucun appel `gh` de quelque nature que ce soit.
- Aucune correction dans `plugin/_internal/vibeflow-update.sh` ni `plugin/design-orchestrator/`
  (hors périmètre fichiers de ce plan) malgré la régression identifiée — signalée, pas corrigée.
- Aucune modification des deux README (compteurs déjà exacts).

## Points nécessitant l'attention du manager

1. **Régression T9f de `test-design-orchestrator.sh`**, introduite par un lot antérieur de la
   phase (`31-03`/`31-04`, refactor D-31-04 du hook `ensure-design-deps.sh`) : le test cherche un
   `else` dans une fenêtre `grep -A8` qui n'atteint plus la branche réelle (déplacée à la ligne
   11 relative au premier match par l'ajout de la branche `elif vf_dry_run`). Comportement
   fonctionnel intact, seule l'assertion du test ne suit plus la structure du code. Correctif
   d'une ligne, dans un fichier hors périmètre de ce plan — à trancher par le manager (élargir la
   fenêtre du test, ou rapprocher le `else` dans le moteur).
2. **`test-check-machine-paths.sh`** échoue sous `git archive` (pas de régression, artefact de
   méthode — confirmé identique au commit de base de la phase). Aucune action requise pour la
   phase 31 ; à noter si un futur gate CI venait à réutiliser `git archive` sans `.git` pour ses
   propres vérifications internes.
