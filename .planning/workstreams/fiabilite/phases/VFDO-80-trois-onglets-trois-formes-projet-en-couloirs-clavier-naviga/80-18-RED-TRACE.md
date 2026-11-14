# 80-18 — trace du rouge (compteur de suites des README)

Commande : `bash scripts/check-version-sync.sh` sur la branche intégrée, avant l'écriture (exit 1).

```
[check-version-sync] ✗ README.md : '244 suites' ≠ réel=257 (find */tests/test-*.sh)
[check-version-sync] ✗ README.fr.md : '244 suites' ≠ réel=257 (find */tests/test-*.sh)
[check-version-sync] dérive détectée — synchroniser AVANT release (canon = VERSION racine).
```

N = 257, lu dans la sortie du gate ; recoupé par `scripts/ci-shard-suites.sh --all` (257 lignes).
