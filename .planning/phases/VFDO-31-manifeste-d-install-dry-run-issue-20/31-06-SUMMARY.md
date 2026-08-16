# 31-06 — SUMMARY : câblage des skills consommateurs (D-31-10, MANI-02)

**Exécuté par** : `vf-coder` (inline, `execute-plan.md`), sur mandat de `vf-dev-manager`.
**Branche** : `feat/phase-31-manifeste-dry-run` (jamais `main`).
**Commit** : `6a715ce` — `feat(31-06): câble le plan --dry-run dans les deux skills consommateurs (D-31-10, MANI-02)`.

## Ce qui a été livré

1. **`plugin/installer/SKILL.md`, étape 5** (ligne 117 `5. **Install scopée…`) : nouvelle puce
   insérée **avant** la puce « Modules VibeFlow » existante (avant ligne 120 initiale, désormais
   ligne 120-124), qui relance la même invocation d'engine préfixée `--scope <s> --dry-run`,
   affiche la sortie telle quelle, et rappelle que `--dry-run` n'écrit rien et est refusé sur
   `uninstall`. La puce de pose réelle (`install --with-deps <module>`) suit, inchangée.
2. **`plugin/conductor/skills/vf-calibrate/SKILL.md`, étape 4 point 2** (ligne 69
   `### 4. Appliquer sous contrôle`, point 2 initialement ligne 72) : le point est dédoublé — un
   appel `--dry-run update <module>` d'abord (sortie montrée à l'utilisateur, rattachée
   explicitement au feu vert déjà exigé par l'étape 3/ADR-031 comme **contenu** du plan de
   migration, pas un second feu vert), puis la commande `update <module>` existante, inchangée.
3. **Bumps du module `conductor`** : `VERSION` v1.24.0 → v1.25.0 (minor), `CHANGELOG.md` (entrée
   en tête), `module.json` (`version`), `README.md` (en-tête `**Version**` ligne 9).
4. **`plugin/installer/` constaté non-module** : `ls plugin/installer/VERSION
   plugin/installer/module.json 2>/dev/null | wc -l` → `0`. Rien créé — décision D-31-10/plan
   respectée à la lettre.

## Où exactement l'appel est inséré

- `plugin/installer/SKILL.md:120-124` — nouvelle puce `**Plan avant pose (MANI-02, issue #20)**`,
  juste avant la puce `**Modules VibeFlow**` de la même étape 5. Aucune étape renumérotée
  (`grep -c '^5\. \*\*Install scopée' plugin/installer/SKILL.md` → `1`).
- `plugin/conductor/skills/vf-calibrate/SKILL.md:72-78` — le point 2 de l'étape « ### 4. Appliquer
  sous contrôle » est réécrit en deux phrases : dry-run d'abord, pose réelle ensuite (même
  numérotation `2.`, aucune étape renumérotée — `grep -c '^### 4\. Appliquer sous contrôle'` → `1`).

## Preuve que l'édition est minimale

- Lignes ajoutées (mesurées par `git diff HEAD~1 HEAD -- <fichier> | grep -c '^+'`, en-tête
  `+++` inclus dans le compte brut de la commande mais pas dans les chiffres ci-dessous) :
  - `plugin/installer/SKILL.md` : **5 lignes de contenu** ajoutées, 0 ligne supprimée (nouvelle
    puce insérée avant la puce existante, qui reste intacte).
  - `plugin/conductor/skills/vf-calibrate/SKILL.md` : le point 2 (1 ligne) est remplacé par
    6 lignes (dry-run + phrase de rattachement au feu vert existant + commande réelle inchangée) —
    **+5 lignes nettes**, 1 ligne supprimée, 6 ajoutées.
- **Aucun nouveau point de décision** : aucun nouvel `AskUserQuestion`, aucune nouvelle
  bifurcation UX introduite — les deux ajouts sont des affichages informatifs insérés en amont
  d'un feu vert déjà existant (ADR-031, étape 5 du récapitulatif d'installer / étape 3 de
  vf-calibrate). Vérifié par relecture des deux fichiers : aucune formulation de type « voulez-vous »,
  « choisissez », ou nouvelle option n'a été introduite.
- Aucune autre section des deux fichiers touchée (`git diff --stat` : 2 fichiers skill modifiés,
  hunks localisés aux étapes citées).

## Bumps effectués

| Fichier | Avant | Après |
|---|---|---|
| `plugin/conductor/VERSION` | v1.24.0 | v1.25.0 |
| `plugin/conductor/module.json` (`version`) | v1.24.0 | v1.25.0 |
| `plugin/conductor/CHANGELOG.md` | — | entrée `## [v1.25.0] — 2026-08-16` ajoutée en tête |
| `plugin/conductor/README.md` (ligne 9, en-tête `**Version**`) | v1.24.0 | v1.25.0 |

**Déviation signalée (zone grise, tranchée par nécessité mécanique du gate) :** le périmètre
fichiers énuméré dans le mandat listait uniquement `VERSION` + `CHANGELOG.md` pour `conductor`. En
exécutant la tâche 2 j'ai découvert que `scripts/check-version-sync.sh` gate **aussi** :
(§7) la triade `VERSION` ↔ `module.json` par module, et (§8) l'en-tête `**Version**` du `README.md`
de chaque module qui en déclare un — les deux contrôles rougissaient sans les bumps
correspondants (`plugin/conductor : VERSION=1.25.0 ≠ module.json=1.24.0`, capturé en trace avant
correction). Ces deux fichiers (`module.json`, `README.md`) ne sont pas dans les 4 fichiers listés
par le mandat/plan `files_modified`, mais l'acceptance criterion « `check-version-sync.sh` sort 0 »
est explicite et non satisfiable sans eux. Je les ai bumpés à l'identique du geste `VERSION`, en
suivant la discipline de release habituelle du repo (bump cohérent des fichiers qui portent le
même numéro), et je le remonte ici en zone grise plutôt que de le trancher en silence — aucune
mention `.claude-plugin`, `VERSION` racine ou `marketplace.json` touchée (vérifié par `git diff
--name-only`).

## Statut de `plugin/installer/`

```
$ ls plugin/installer/VERSION plugin/installer/module.json 2>/dev/null | wc -l
0
```
Confirmé non-module (ni `VERSION` ni `module.json`) : rien créé, conformément à D-31-10.

## Gates lancés nus

```
$ bash scripts/check-version-sync.sh >/dev/null 2>&1; echo $?
0
$ bash scripts/check-machine-paths.sh >/dev/null 2>&1; echo $?
0
```
(1035 fichiers suivis balayés, aucun chemin absolu de machine.)

## Trois suites — sur l'arbre TEL QUE COMMITÉ (`git archive HEAD` isolé)

```
test-manifest.sh        : 46 OK / 0 KO / 0 SKIP
test-vibeflow-update.sh : 19 OK / 0 KO / 0 SKIP
test-merge-hooks.sh     : 34 OK · 0 KO
```
`check-version-sync.sh` rejoué sur l'archive isolée : `0`. `check-machine-paths.sh` sur l'archive
isolée rend `rc=2` (« n'est pas un dépôt git — univers inconnu, NON VÉRIFIABLE ») — attendu et non
un défaut : le script utilise `git ls-files` pour énumérer les fichiers suivis, absent d'un
`tar -x` sans `.git`. La vérification faisant foi est celle lancée **dans le repo réel**
(ci-dessus, rc=0, 1035 fichiers). Signalé pour transparence plutôt que tu, conformément à la
consigne « ne jamais fabriquer une preuve ».

## Critères d'acceptation de la tâche 1 — vérifiés

- `grep -c 'dry-run' plugin/installer/SKILL.md` → `3` (≥ 2 ✓)
- `grep -c 'dry-run' plugin/conductor/skills/vf-calibrate/SKILL.md` → `2` (≥ 2 ✓)
- `grep -c '^5\. \*\*Install scopée' plugin/installer/SKILL.md` → `1` ✓
- `grep -c '^### 4\. Appliquer sous contrôle' plugin/conductor/skills/vf-calibrate/SKILL.md` → `1` ✓
- Ligne ajoutée dans `installer/SKILL.md` contient `_internal/vibeflow-update.sh` et `--scope` ✓
- `check-machine-paths.sh` → `0` ✓
- `[ "$(git diff | grep -c '^+.*gh issue')" = 0 ]` → rc `0` (aucun appel GitHub introduit) ✓

## Ce que je n'ai PAS fait

- Aucun PR, merge, release, bump de la `VERSION` racine ni de `plugin.json`/`marketplace.json`.
- Aucun appel `gh`.
- Aucune écriture dans `plugin/_internal/` (lecture seule respectée — deux juges y lisent en
  parallèle sur le lot précédent).
- Aucune écriture sous `.planning/` autre que ce fichier.
