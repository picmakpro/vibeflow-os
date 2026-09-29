---
status: complete
quick_id: 260928-uu0
---

# SUMMARY — Correction de portabilité GNU/BSD (R14/MUT-CHMOD/MUT-CHMOD-JOURNAL)

## Fait

- Ajouté `mode_octal()` dans `plugin/planning-core/scripts/tests/test-recalc-planning.sh`, juste
  après la détection de `$PYBIN` : lit `os.stat(...).st_mode & 0o777` en Python, formaté en octal.
  Commentaire en tête explique le motif (divergence GNU/BSD de `stat -f`).
- Remplacé les 3 sites `MODE=$(stat -f "%Lp" ... 2>/dev/null || stat -c "%a" ... 2>/dev/null)` par
  `MODE=$(mode_octal "<chemin>")` : R14 (permissions umask 0077), MUT-CHMOD (mode INDEX.md),
  MUT-CHMOD-JOURNAL (mode cloture.log).
- Balayé le reste du fichier (4005 lignes) pour d'autres constructions GNU/BSD divergentes —
  résultat détaillé dans le rapport final au manager (`portabilite` du bloc typé) : aucune autre
  correction nécessaire.

## Preuve

- `bash -n` : syntaxe valide.
- `bash plugin/planning-core/scripts/tests/test-recalc-planning.sh` sous macOS : `313 OK · 0 KO`
  (compte exact, inchangé).
- R14 et MUT-CHMOD/MUT-CHMOD-JOURNAL nominalement verts dans cette exécution (lignes dédiées
  vérifiées individuellement dans le log).
- Les 8 suites sœurs de `plugin/planning-core/scripts/tests/tests/` (test-check-planning-state,
  test-detect-gsd-engine, test-detect-planning-debt, test-planning-context-hardening,
  test-planning-core, test-planning-hooks, test-workstream-policy,
  test-workstream-symlink-escape) tournées individuellement : toutes exit 0, aucune régression,
  aucune modifiée (`git diff --stat` confirme scope limité au fichier cible).
- Simulation du défaut original : faux `stat` GNU-like placé en tête de PATH (`-f` imprime un bloc
  `File:`/`ID:`/`Type:` puis échoue ; `-c "%a"` rend le mode réel). Rejoué contre l'ancienne ligne
  et la nouvelle voie côte à côte :
  ```
  === ANCIENNE LIGNE (stat -f ... || stat -c ...) ===
  --- MODE_OLD brut (entre crochets) ---
  [  File: ".../testfile"
      ID: deadbeef Namelen: 255     Type: apfs
  644]
  OLD: KO (attendu 644, obtenu ci-dessus)

  === NOUVELLE VOIE (mode_octal, Python) ===
  --- MODE_NEW brut (entre crochets) ---
  [644]
  NEW: OK (644)
  ```
  Confirme : l'ancienne ligne produit une chaîne multi-ligne polluée par le faux `stat -f`
  (reproduisant exactement le défaut R14 mesuré en CI) ; `mode_octal()` ignore totalement le
  binaire `stat` du PATH et rend un mode propre.
- Preuve finale (CI Linux réelle) hors périmètre de ce mandat : le push et la vérification CI
  restent au manager/head.

## Périmètre respecté

Seul `plugin/planning-core/scripts/tests/test-recalc-planning.sh` modifié.
`recalc-planning.sh`, `detect-gsd-engine.sh`, `workstream-policy.sh` et les 8 suites sœurs intacts.
