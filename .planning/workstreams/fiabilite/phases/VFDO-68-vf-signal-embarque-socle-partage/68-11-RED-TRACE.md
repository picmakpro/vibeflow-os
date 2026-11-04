# 68-11 — Trace du rouge du bump du module (VFSG-13), tâche 1

Base : `a82e2ca0` (branche `feat/phase-68-bump`, rebasée sur main `19393cc3`). Version de départ du module `cockpit` : v1.1.2 (posée par la PR #201, faille H-1) ; version visée : v1.2.0 (minor : nouvelle capacité). Écart avec le plan, qui annonçait v1.1.1.

## R1 — bump partiel de `plugin/cockpit/VERSION` seul (triade du module cassée)

Commande : `bash scripts/check-version-sync.sh` -> **exit 1**

```
[check-version-sync] ✗ plugin/cockpit : VERSION=1.2.0 ≠ module.json=1.1.2
[check-version-sync] ✗ plugin/cockpit/README.md : en-tête Version v1.1.2 ≠ VERSION v1.2.0
[check-version-sync] dérive détectée — synchroniser AVANT release (canon = VERSION racine).
```

Rouge attendu : la triade `VERSION` <-> `module.json` (point 6) et l'en-tête du README (point 8) dérivent.

## Vert — `module.json` et en-tête Version du README alignés sur v1.2.0

Commande : `bash scripts/check-version-sync.sh` -> **exit 0**

```
[check-version-sync] ✓ sources synchronisées (v2.75.1, 19 modules)
```

## R2 — sources racine intactes

`git diff --stat` ne porte que `plugin/cockpit/{VERSION,module.json,README.md,CHANGELOG.md}` ; aucun fichier racine, aucun tag, aucun verrou.
