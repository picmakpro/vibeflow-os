# Deferred items — Phase 43

## 43-03 : `scripts/check-version-sync.sh` échoue pour une cause hors périmètre

**Constaté pendant** : Tâche 2 du plan 43-03 (vérification du bump de `skill-creator`).

**Symptôme** : `bash scripts/check-version-sync.sh` sort `rc=1` :

```
[check-version-sync] ✗ README.md : '89 suites' ≠ réel=90 (find */tests/test-*.sh)
[check-version-sync] ✗ README.fr.md : '89 suites' ≠ réel=90 (find */tests/test-*.sh)
```

**Pourquoi hors périmètre** : le script inchangé (comparé à `25a916b`), et cette dérive
préexiste déjà à la base du worktree de ce plan (commit `25a916b`, avant toute écriture de
43-03) — un compteur de suites de tests dans les README racine (`README.md`, `README.fr.md`),
aucun des deux fichiers déclarés dans `files_modified` de 43-03. Corriger ce compte exigerait de
toucher `README.md`/`README.fr.md` racine, hors du périmètre strict de ce plan (`files_modified`
limité aux six fichiers de `skill-creator`).

**Preuve que le bump de `skill-creator` est correct malgré cet échec global** (mesuré
manuellement, composant par composant, cette session) :

```
base (B43=22179fa…) plugin/skill-creator/VERSION = v1.0.4
attendu (mineure)                                 = v1.1.0
obtenu  plugin/skill-creator/VERSION              = v1.1.0
obtenu  plugin/skill-creator/module.json .version = v1.1.0
README.md ligne Version                           = v1.1.0 (alignée)
CHANGELOG.md tête                                 = ## [v1.1.0] (alignée)
```

**Action requise** : synchroniser le compteur de suites (90 réel) dans `README.md` et
`README.fr.md` racine avant la prochaine release — hors du périmètre de ce plan, à traiter par
un plan/commit séparé (mise à jour de doc, sans rapport avec FABR-08).
