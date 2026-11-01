---
phase: 67-cockpit-floorplan-socle-partage
plan: 01
status: complete
requirements: [CKPT-11]
commits: [0ac4e7f1, 5d535143, 3c30769b]
actuals:
  tasks: 3
---

# 67-01 SUMMARY — écriture atomique de save() (dag.sh)

`save()` écrit désormais dans un temporaire du même dossier (mkstemp, fsync, mode copié ou 0666 moins umask) puis `os.replace`, nettoyage sur exception. Validation ADR-031 limitée à ce correctif (P67-D-09, arbitrage Samuel, AskUserQuestion session principale, 2026-11-01). `conductor` v1.52.1, aucune release racine.

## Écart au plan

La suite joue trois `add` d'affilée (et non un) : avec un seul `add`, le correctif ne donnait que 16 lectures (< 20, témoin d'exposition rouge à tort). Le témoin rouge a été rejoué sur l'ancien `save()` avec la suite finale.

## Témoin rouge (ancien save(), suite initiale puis finale)
```
A1 compteurs : lectures=31 tronquees=14
  ❌ FAIL — A1.1 — aucune lecture tronquée
     attendu: [0]
     obtenu:  [14]
  Résultats : 5 PASS / 1 FAIL
--- suite finale (3 add) contre l ancien save() ---
A1 compteurs : lectures=65 tronquees=38
  ❌ FAIL — A1.1 — aucune lecture tronquée
  Résultats : 5 PASS / 1 FAIL
```

## Après correctif (vert)
```
A1 compteurs : lectures=33 tronquees=0
  Résultats : 6 PASS / 0 FAIL
```

## Mutant de copie du mode (annulé) — A3 rouge
```
A1 compteurs : lectures=191 tronquees=0
  ❌ FAIL — A3.1 — un DAG en 640 reste en 640
     attendu: [0o640]
     obtenu:  [0o600]
  Résultats : 5 PASS / 1 FAIL
```

## Témoin G-2
Avant trailer : `CHEMIN-NON-DECLARE: plugin/conductor/scripts/tests/test-dag-atomic-save.sh (statut A, classe suite)` ; après le commit 5d535143 : `DECLARE`.

## Non-régression
- `test-dag.sh` : 161 PASS / 0 FAIL sous HOME réel ; sous `HOME=$(mktemp -d)` 6 échecs T25/T26/T28 (calcul des `stages` : le moteur gsd-tools est cherché sous `$HOME`, artefact d'environnement, pas du correctif).
- `test-driver-lock-consumers-ws.sh` rc 0 ; `test-check-mission-exit.sh` 135 ok / 0 ko ; `check-python-isolation.sh --min-sites 40` rc 0.
- `check-version-sync.sh` : seules les deux lignes « 123 suites ≠ 124 » (tenues par 67-03).
- Suite : 129 lignes (≤ 300), aucune occurrence de `stat -f/-c` ni `timeout`.
