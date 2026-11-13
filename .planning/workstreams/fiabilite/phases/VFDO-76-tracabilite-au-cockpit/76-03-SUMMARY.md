---
phase: 76
plan: "03"
requirements-completed: [TRAC-07, TRAC-08]
---

# 76-03 — Mémoire des agents lue en structure : SUMMARY

## Livré

Deux modules neufs sous `plugin/cockpit/scripts/` (72 et 123 lignes, aucune ligne au-delà de 160 points de code) et une suite de 55 assertions.

- `vf-cockpit-trace-memoire-git.mjs` : `BORNES_MEMOIRE`, `fichiersSuivis`, `nonSuivis`, `cheminsHead`, `cheminsSupprimes`, `joursMemoire`. Seul lanceur : `lancerGitAsync` ; sha de 40 caractères, `--end-of-options`, `--`.
  Pathspec `.claude/agent-memory/` plus filtre de profondeur agent/fichier (la mémoire locale n'est jamais nommée dans le module) ; les non suivis sont comptés par deux passages (`-o`, puis `-o -i`), noms jetés dans la fonction ;
  borne de 2 000 entrées (les `MEMORY.md` ne comptent pas dans la borne), `tronque` sur borne, délai, échec ou sortie tronquée.
- `vf-cockpit-trace-memoire.mjs` (pur) : `liensDe`, `MOTIF_CHEMIN`, `entreesMemoire`. Entrée servie : `cle`, `chemin` (relatif au dépôt), `agent`, `name`, `type` (par `valeurImbriquee`), `jour`, `sortants`, `entrants`, `nbSortants`, `nbEntrants`, `horsIndex`, `sansEntrant`,
  `cheminsAbsents` ; jamais `description`, corps ni texte. Résolution par `name` (agent, puis lab), puis par nom de fichier (`resolu-par-nom`), sinon `casse` ; plusieurs candidates = `resolu` sans `vers`. Hors index par égalité exacte sur l'ensemble des noms de liens d'index (`./` retiré).
  Compteurs : `{ entrees, agents, horsIndex, liensCasses, sansEntrant, cheminsAbsents, resolusParNom, entreesCitantAbsent }`, par unité (entrées, liens, chemins distincts), sans somme ; mêmes champs par agent (sans `entreesCitantAbsent`).
- `tests/test-cockpit-tracabilite-memoire.sh` : T7.1 à T7.9 et T8.1 à T8.7 sur treize labs fabriqués (suivi, local, lien symbolique sortant et voisin, `.claude/` ignoré, borne, index, déplacement et suppression) et sur le dépôt réel en lecture seule. Chaque « jamais » a son témoin positif dans le même lab.

## Écarts (aucun ne change un contrat consommé par une autre phase)

- Écart : `cheminsHead` passe par `git diff-tree -r -z --name-only` contre l'arbre vide SHA-1, et non par `ls-tree` : `ls-tree` n'est pas dans la liste fermée `SOUS_COMMANDES_AUTORISEES` du lanceur durci (`vf-cockpit-git-durci.mjs`, hors périmètre). Un HEAD illisible rend un ensemble vide et `entreesMemoire` ne juge alors aucun chemin absent. Limite : un dépôt SHA-256 rendrait un ensemble vide (même effet, pas de faux positif).
- Écart : `cheminsSupprimes` lit `--format=%x01` pour compter les commits lus et fixer `tronque` à la borne (le plan ne disait pas comment la constater).
- Écart : `nbSortants` et `nbEntrants` ajoutés à l'entrée (le plan les dit « nombres de liens » sans nommer les champs) ; `entreesCitantAbsent` ajouté aux compteurs. `compteurs.cheminsAbsents` compte des chemins distincts (UI-SPEC § 5.4 : « 4 chemins cités absents »), `entreesCitantAbsent` des entrées.
- Écart : sans `MEMORY.md` pour un agent, ses entrées sont toutes `horsIndex` (rien ne les indexe).
- Écart : le module git a été écrit complet dès la tâche 1 ; la tâche 2 n'a donc rouge que sur les nombres de liens (voir `76-03-RED-TRACE.md`).
- `includes(` apparaît une fois dans `vf-cockpit-trace-memoire.mjs` : dédoublonnage d'un lien entrant, pas un jugement d'index.
- `vf-cockpit-frontmatter.mjs` lu, non modifié.

## Rituels levés

- rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale) — les sept mutants du plan (M-DESCRIPTION, M-LOCAL, M-NOMS, M-SOUSCHAINE, M-CODE, M-RENAMES, M-DATE) ne sont pas joués ; le seul témoin exigé est le rouge d'assertion consigné avant chaque code. Plan non marqué pour audit de sécurité.
- rituel levé : régime allégé (même consigne) — pas de triple passe, pas de rejeu suite par suite, pas de gate de compteur (`check-version-sync.sh` § 9 reste rouge jusqu'à 76-08, attendu).

## Suites jouées (une fois, sur la tête commitée)

| Suite | Verdict | Durée |
|-------|---------|-------|
| `test-cockpit-tracabilite-memoire.sh` | 55 passés, 0 échoués (exit 0) | 6 s |
| `test-cockpit-vendor.sh` | 252 PASS / 0 FAIL (exit 0) | 99 s |

## À verser par la jointure

1. `check-method-budget.sh` juge « hors index » par sous-chaîne (`grep -qF`) alors que la 76 juge par égalité exacte (témoin `a.md` contre `aa.md`, T8.3) : constat pour le BACKLOG (P76-D-23).
2. Les compteurs de mémoire servis par la route (76-05) sont le contrat fourni à la Phase 77 : `{ entrees, agents, horsIndex, liensCasses, sansEntrant, cheminsAbsents, resolusParNom, entreesCitantAbsent }`, unités dites en tête de `vf-cockpit-trace-memoire.mjs`.
3. Pour 76-05 : appeler les passages git d'abord (asynchrones), puis lire les fichiers suivis et les `MEMORY.md` dans UN appel synchrone `lireConfine` (modèle : le harnais de la suite) ; passer `head` (`cheminsHead`), `historique` (`cheminsSupprimes(...).chemins`), `jours` (`joursMemoire`) et `fm` à `entreesMemoire`.
