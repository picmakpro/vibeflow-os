---
quick_id: 260928-q6h
status: complete
date: 2026-09-28
---

# Summary — garde de fidélité d'énumération, lot 6, Phase 44

Mandat vf-coder, mission `mgr-44-reprise`, nœud `exec-44` rouvert, mode autonome. Correction CIBLÉE
sur le constat HIGH de l'audit (masquage de compartiment de workstream à l'énumération), plus
quatre constats mineurs de revue (WR-02, WR-03, IN-01, IN-02) — pas un cycle complet. Exécuté
directement par vf-coder, pas par le cycle planner/executor standard : même écart de méthode
assumé que les lots 4 et 5 (`260928-mgu-SUMMARY.md` § Écart de méthode assumé, `260928-ol3-SUMMARY.md`) —
le dispatch `gsd-executor` en worktree isolé ne voit pas l'arbre de travail de ce worktree tel
qu'il se trouve avant tout commit de ce lot. Trois commits atomiques (fix/test/docs), comme les
lots 1-4, plutôt qu'un seul comme le lot 5 : la garde ajoutée est isolée dans une nouvelle fonction
autonome (`_enumeration_workstreams_fidele`), se découpe donc proprement de ses tests et de sa
documentation sans fragmenter la trace rouge/verte.

## Ce qui a été fait

**Commit `2886fe3`** (fix) — `plugin/planning-core/scripts/recalc-planning.sh` seul :

- Dérivé par exécution, dans l'environnement maîtrisé exact du moteur (fixtures scratch,
  `git show 0be13a9:...` pour la trace rouge sur le code original), les classes réelles de
  compartiments de `.planning/workstreams/` qu'une énumération ligne-par-ligne ne restitue pas
  fidèlement : nom de compartiment à saut de ligne, nom de compartiment caché (point), chemin du
  dossier de planning lui-même à saut de ligne. Une quatrième classe candidate (retour chariot
  isolé dans un nom) mesurée NON masquante — pas gardée (F1, ne pas sur-refuser). Une cinquième
  (lien symbolique) confirmée déjà exclue explicitement, avec avertissement, par le détecteur
  lui-même — pas gardée non plus.
- Ajouté `_enumeration_workstreams_fidele(planning_abs)` : fonction structurelle, appelée dans
  `detection_gsd()` AVANT tout appel au sous-processus détecteur. Ne relit aucun `STATE.md`, ne
  cherche aucun marqueur `gsd_state_version` — juge uniquement si l'énumération peut restituer
  fidèlement ce qui est réellement sur le disque sous `workstreams/`. `detect-gsd-engine.sh` et
  `workstream-policy.sh` restent INCHANGÉS (P44-D-01b) : diff vide confirmé.
- Correctifs de revue, comportement inchangé : commentaire ajouté sur `--noprofile`/`--norc`
  (WR-02, la protection contre `BASH_ENV`/`ENV` vient exclusivement de l'environnement maîtrisé) ;
  message stderr explicité + doc pour la conséquence fail-closed totale de `CANDIDATS_BASH` sur un
  système sans `/bin/bash` ni `/usr/bin/bash` (WR-03) ; commentaire « priorité 2bis SAUTÉE »
  réaligné sur une seule ligne (IN-01) ; `assert jeton` remplacé par une exception explicite
  toujours active, y compris sous `python -O` (IN-02).

**Commit `a1401a7`** (test) — `plugin/planning-core/scripts/tests/test-recalc-planning.sh` seul :

- `R-ENUM-FIDELE-LF`, `R-ENUM-FIDELE-CACHE`, `R-ENUM-FIDELE-CHEMIN` : chacune code de sortie 3,
  stderr nomme la classe masquante, empreinte `.planning/` identique avant/après.
- `R-ENUM-FIDELE-SYMLINK` : non-régression, un lien symbolique reste une exclusion déclarée du
  détecteur, jamais classé masquant par cette garde.
- `R-ENUM-FIDELE-NOMINAL` : non-régression, compartiments réels aux noms sans piège sans marqueur
  GSD — écriture inchangée (code 0, les trois fichiers générés).
- `MUT-ENUM-FIDELE` (`if not fidele:` -> `if False:`) : tué, code de sortie 3 -> 0, régression
  exacte de l'audit reproduite sur le mutant.
- Suite complète rejouée : `285 OK · 0 KO` (270 avant ce lot, +15).

**Commit `770c35b`** (docs) — `plugin/planning-core/CHANGELOG.md`,
`plugin/planning-core/references/modele-cycles.md`, `.planning/BACKLOG.md` :

- `modele-cycles.md` : paragraphe « Conséquence non documentée de `CANDIDATS_BASH` (WR-03) » et
  paragraphe « Garde de fidélité d'énumération (P44-D-02a, lot 6) », sous la section détection GSD
  existante.
- `CHANGELOG.md` : paragraphe « Lot 6 » ajouté sous l'entrée `[v2.8.0]` existante — aucun bump
  (VERSION/module.json inchangés, cohérent avec les lots 1-5).
- `.planning/BACKLOG.md` : une entrée pour Samuel (propriétaire de `workstream-policy.sh`,
  Phase 41.1), fin de fichier — le trou racine (`vf_ws_enumerate` ne restitue pas fidèlement un
  compartiment à saut de ligne), même primitive dans `check-planning-state.sh`, motif du report
  P44-D-01b.

## Preuve différentielle (rouge avant / vert après)

Extrait de `recalc-planning.sh`/`detect-gsd-engine.sh`/`workstream-policy.sh` à `0be13a9`
(`git show`) dans un lab scratch (`mktemp -d`), compartiment
`.planning/workstreams/compartiment-un<LF>marqueur-cache/STATE.md` portant `gsd_state_version` :

- **Avant (0be13a9)** : `exit=0`, stderr vide, `INDEX.md`/`STATE.md`/`.recalc-cache.json` écrits —
  violation P44-D-02a reproduite.
- **Après (ce lot)** : `exit=3`, stderr nomme `nom-compartiment-saut-de-ligne`, aucun fichier écrit
  (empreinte identique avant/après).

Même paire de traces pour le compartiment caché (`.hidden-compartment`) et pour le chemin de
planning lui-même à saut de ligne.

## Contrôles rejoués

- `bash plugin/planning-core/scripts/tests/test-recalc-planning.sh` : `285 OK · 0 KO`, rc=0.
- `git diff --stat 424cb23..HEAD -- .../detect-gsd-engine.sh .../workstream-policy.sh` : vide.
- 8 suites sœurs, une exécution chacune : `19 ok/0 ko`, `26 ok/0 ko`, `10 passés/0 échoués`,
  `38 passés/0 échoués`, `14 passés/0 échoués`, `42 PASS/0 FAIL`, `22 ok/0 ko/0 skip`, `10 ok/0 ko`
  — comptes identiques à la mesure précédente (lot 5).
- Sonde PY39 : `PY39-SYNTAXE-OK` (`ast.parse(feature_version=(3,9))` sur le corps extrait) ;
  `--help` sous `bash` et `/bin/zsh` : sortie identique (`cmp -s`).
- Aucun motif dangereux introduit (`grep -nE 'import yaml|shell=True|eval\(|exec\(|gsd-core|gsd-tools|get-shit-done|phases_trace'` : rien).
- `bash scripts/check-version-sync.sh` : `✓ sources synchronisées`.
- `bash scripts/check-machine-paths.sh` (après le commit fix/test/docs) : `✓ 1698 fichier(s) suivi(s) balayé(s), aucun chemin absolu de machine`.
- `bash plugin/conductor/scripts/check-planning-consumers-registered.sh` : `✓ ... 21 consommateur(s) détecté(s), tous recensés`.
- `bash scripts/check-gate-touche.sh` : `RIEN-A-JUGER: aucun chemin de la surface surveillee n'est touche entre 424cb23... et HEAD`.
- `git diff --stat 0be13a9..HEAD` (avant le commit final de ce quick) : exactement les 5 fichiers
  autorisés — `.planning/BACKLOG.md`, `CHANGELOG.md`, `modele-cycles.md`, `recalc-planning.sh`,
  `test-recalc-planning.sh`.

## Décisions du manager relayées (discrétion technique déléguée)

Ajout d'une garde fail-closed de plus côté moteur, sans toucher au détecteur ni à
`workstream-policy.sh` — ne modifie aucune décision de la Phase 44, prolonge P44-D-02a exactement
comme prévu.
