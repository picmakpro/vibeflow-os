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

## 43-07 : même dérive reproduite, confirmée hors périmètre de ce plan aussi

**Constaté pendant** : Tâche 2 du plan 43-07 (vérification du bump de `dev-orchestrator`).

**Symptôme identique** à celui documenté ci-dessus pour 43-03 :

```
[check-version-sync] ✗ README.md : '89 suites' ≠ réel=90 (find */tests/test-*.sh)
[check-version-sync] ✗ README.fr.md : '89 suites' ≠ réel=90 (find */tests/test-*.sh)
```

**Confirmation de la cause** : mesuré à `B43=22179fa50ad2c420ccdc6e3d7eb0fb6f0d054703` (base de
phase figée) via `git ls-tree -r --name-only $B43 -- plugin scripts | grep -E '/tests/test-.*\.sh$'
| wc -l` → **89**, exactement le compte que porte README.md/README.fr.md à cette base. La dérive
naît donc À L'INTÉRIEUR de la Phase 43 elle-même : le commit `ac0147a` (43-02, Tâche 2, FABR-07)
ajoute `plugin/conductor/scripts/tests/test-check-skills.sh`, portant le réel à 90 sans toucher les
2 README racine — ni `43-02` ni `43-07` (ni `43-06`, mêmes contraintes de `files_modified`) ne
portent ce fichier dans leur périmètre déclaré.

**Preuve que le bump de `dev-orchestrator` est correct malgré cet échec global** (mesuré
composant par composant, cette session) :

```
base (B43=22179fa…) plugin/dev-orchestrator/VERSION = v2.24.1
attendu (patch)                                      = v2.24.2
obtenu  plugin/dev-orchestrator/VERSION              = v2.24.2
obtenu  plugin/dev-orchestrator/module.json .version = v2.24.2
README.md ligne Version                              = v2.24.2 (alignée)
CHANGELOG.md tête                                    = ## [v2.24.2] (alignée)
check-version-sync.sh : triade par module OK, en-tête Version des README de modules OK — seul
le point 9 (compteur « N suites » des 2 README RACINE) rougit, sans rapport avec dev-orchestrator.
```

**Action requise** : inchangée — synchroniser le compteur de suites (90 réel) dans `README.md` et
`README.fr.md` racine avant la prochaine release, hors du périmètre de tout plan de cette phase
(`files_modified` d'aucun des 43-02/43-06/43-07 ne porte les 2 README racine).
