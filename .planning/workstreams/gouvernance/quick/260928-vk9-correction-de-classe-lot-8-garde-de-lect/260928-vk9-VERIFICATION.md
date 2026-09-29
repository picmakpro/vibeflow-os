---
phase: 260928-vk9-correction-de-classe-lot-8-garde-de-lect
verified: 2026-09-28T21:55:00Z
status: passed
score: 5/5 vérités observables vérifiées (aucune non passée en revue, aucune supposition acceptée sans exécution directe)
covered_files:
  - plugin/planning-core/scripts/recalc-planning.sh
  - plugin/planning-core/scripts/tests/test-recalc-planning.sh
  - plugin/planning-core/references/modele-cycles.md
  - plugin/planning-core/CHANGELOG.md
  - .planning/BACKLOG.md
  - .planning/workstreams/gouvernance/quick/260928-vk9-correction-de-classe-lot-8-garde-de-lect/260928-vk9-SUMMARY.md
---

# Vérification adversariale — lot 8, garde de lecture du détecteur (Phase 44)

**Commit vérifié :** `0c284e3` — « fix(44): garde de lecture du détecteur — correction de classe lot 8 »
**Méthode :** rejeu direct, aucune affirmation du commit/SUMMARY acceptée sans exécution réelle.

## A. Relecture du diff (recalc-planning.sh)

| Fix | Attendu | Constaté dans le diff | Statut |
|---|---|---|---|
| 1. Lien cassé = absent | `os.path.isfile` remplace `os.path.lexists` aux deux sites (racine ligne ~483, compartiment ligne ~544) | Confirmé, exact, pas de faute de frappe | ✓ VERIFIED |
| 2. FIFO non bloquante | `os.open(chemin, os.O_RDONLY \| os.O_NONBLOCK)` puis `os.fstat(fd)` + `stat.S_ISREG` dans un `try/finally` qui ferme le fd | Confirmé, `import stat` présent ligne 73 | ✓ VERIFIED |
| 3. Correction de prose | Commentaire disant que les classes structurelles du lot 6 sont fusionnées dans la même liste de décision, pas indépendantes | Confirmé | ✓ VERIFIED |
| Non-régression nominale | Un STATE.md régulier lisible reste lu normalement | Confirmé par exécution (lab E, voir ci-dessous) et par la suite de tests (313 OK) | ✓ VERIFIED |

## B. Rejeu des trois scénarios (exécution directe)

| # | Scénario | Commande | Résultat observé | Statut |
|---|---|---|---|---|
| 1 | Compartiment STATE.md en lien cassé, aucun marqueur GSD | `bash recalc-planning.sh --planning=.planning` depuis un lab minimal (`labA`) | `exit_code=0`, JSON `"mode": "ecriture"`, `"ecrits": ["INDEX.md"]` | ✓ VERIFIED — exit 0 attendu, confirmé |
| 2 | STATE.md racine en lien cassé | idem depuis `labB` | `exit_code=1`, stderr = `emplacement occupé par autre chose qu'un fichier régulier : .../labB/.planning/STATE.md` ; cible du lien (`/nonexistent/cible/absente-B`) jamais créée (`test -e` → absent) | ✓ VERIFIED — exit 1, « emplacement occupé », cible jamais créée |
| 3 | STATE.md racine en FIFO (`mkfifo`), exécution bornée via `subprocess.run(..., timeout=8)` (ni `timeout` ni `gtimeout` sur ce poste — confirmé, `which timeout gtimeout` → introuvables) | script Python dédié (`run_bounded.py`) | Terminé en **0.068 s**, `exit_code=1`, stderr = `emplacement occupé par autre chose qu'un fichier régulier` — **aucun blocage** | ✓ VERIFIED — pas de blocage, < 8 s |

**Non-régression nominale (complément, non demandé explicitement mais vérifié) :** `labE` — STATE.md racine ET de compartiment réguliers, lisibles, frontmatter valide → `exit_code=0`, réécriture normale de `STATE.md`/`INDEX.md`/`.recalc-cache.json`. Aucun faux refus « illisible ». ✓ VERIFIED.

### Observation notable (non bloquante) — mécanisme réel du scénario 3

Le scénario 3 (FIFO racine) ne bloque pas, mais **pas grâce au fix `O_NONBLOCK` de `_ouvrable`** dans le cas testé : `os.path.isfile()` sur une FIFO rend `False`, donc `_ouvrable` n'est **jamais appelée** sur la FIFO aux deux sites d'appel gardés (racine ligne 483, compartiment ligne 544) — c'est en réalité la garde B (`appliquer_ecritures`, `lstat`, refus « emplacement occupé ») qui intercepte, sans jamais ouvrir le fichier. Vérifié par grep (`_ouvrable(` : 3 sites d'appel seulement, tous gardés par `isfile`/`scandir`) et confirmé par le nom même des tests du lot 8 (`R-LOT8-FIFO-RACINE : refus RAPIDE (garde B)` vs `R-LOT8-OUVRABLE-FIFO : _ouvrable appelée DIRECTEMENT sur une FIFO (contourne le garde amont)`).

**Ce n'est pas un gap** : `modele-cycles.md` (lignes 199-203) documente cette nuance avec une précision totale — « `os.path.isfile` (point 1) suffit déjà, seul, à éviter d'appeler `_ouvrable` sur une FIFO depuis les deux sites d'appel actuels [...] le durcissement `O_NONBLOCK` reste une défense en profondeur ». Le fix `O_NONBLOCK` protège une fenêtre TOCTOU résiduelle (fichier régulier remplacé par une FIFO entre le `isfile()` et l'`open()`) et tout appel futur à `_ouvrable` qui ne passerait pas par ce même filtre — il est réellement exercé et prouvé par un test dédié (`R-LOT8-OUVRABLE-FIFO`, appel direct à `_ouvrable(FIFO)`) et un mutant qui, une fois `O_NONBLOCK` retiré, bloque réellement 6.00 s avant d'être tué par le harnais borné (`MUT-LOT8-ONONBLOCK`). Documentation fidèle au comportement réel, pas une paraphrase optimiste — voir section E.

## C. Suite de tests complète

```
cd plugin/planning-core/scripts/tests && bash test-recalc-planning.sh
```

Résultat : **`== Résultat : 313 OK · 0 KO ==`** (confirmé, 38.5 s réelles). Correspond exactement à la revendication du commit (313 OK/0 KO, 303 avant ce lot). ✓ VERIFIED.

## D. Fichiers du détecteur inchangés

```
git diff --stat 424cb23..HEAD -- plugin/planning-core/scripts/detect-gsd-engine.sh plugin/planning-core/scripts/workstream-policy.sh
```

Sortie : **vide**. Confirmé — `detect-gsd-engine.sh` et `workstream-policy.sh` octet pour octet inchangés depuis ce commit de référence, tel qu'annoncé (P44-D-01b). ✓ VERIFIED.

## E. Fidélité documentaire et absence de bump de version

- `modele-cycles.md` (lignes 178-227) : décrit fidèlement « lien cassé = absent » et « FIFO refusée sans blocage », avec une précision supérieure au commit (nuance isfile/O_NONBLOCK ci-dessus, section « Résidus acceptés » sur la fenêtre TOCTOU garde/détecteur mesurée 1/15). Pas une paraphrase optimiste. ✓ VERIFIED.
- `CHANGELOG.md` : entrée lot 8 ajoutée en tant que puce sous la section `## [v2.8.0]` déjà existante — **aucun nouveau header de version**. ✓ VERIFIED.
- `git show HEAD --stat --name-only` : aucune occurrence de `VERSION`, `plugin.json` ou `module.json`. Confirmé par recherche `grep -iE "^VERSION$|plugin\.json|module\.json"` sur la liste des fichiers touchés → vide. `plugin/planning-core/VERSION` = `v2.8.0`, dernier commit qui le touche = `fda472a` (≠ HEAD). `plugin/planning-core/module.json` : `"version": "v2.8.0"`, non touché par HEAD. VERSION racine = `v2.66.0`, non touché. ✓ VERIFIED — aucun bump de version.

## Verdict

**PASSED.** Les deux corrections de classe (lien cassé traité comme `[ -f ]`, FIFO non bloquante via `O_NONBLOCK`+`fstat`) sont présentes, correctes, et vérifiées par exécution directe indépendante du SUMMARY — pas seulement par lecture du diff. La suite de tests complète rend exactement 313 OK/0 KO. `detect-gsd-engine.sh` et `workstream-policy.sh` sont intacts. La documentation est fidèle au comportement réel (et va au-delà en documentant une nuance que l'exécution directe a également révélée). Aucun bump de version.

Aucun gap. Une observation non bloquante documentée ci-dessus (mécanisme réel du non-blocage en scénario FIFO racine — déjà transparent dans `modele-cycles.md`).

---

_Vérifié : 2026-09-28T21:55:00Z_
_Vérificateur : Claude (gsd-verifier)_
