# 76-02 — Trace rouge

Régime allégé : seul témoin exigé, le test vu rouge avant le code (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale).

## Tâche 1 — T5.1 (modules `vf-cockpit-registres.mjs` et `vf-cockpit-trace-git.mjs` absents)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-tracabilite-decisions.sh`

```
  ❌ FAIL — T5.1 — le commit qui cite ADR-001 est relié à la section (h7, jour, sujet) et son corps n'est pas servi
     attendu: [true|7|true|false]
     obtenu:  [absent]
  ✅ PASS — T5.2 — témoin positif : le corps du commit contient bien le marqueur dans git
  Résultats : 1 PASS / 1 FAIL
```

Rouge par l'assertion visée : le harnais attrape l'échec d'import et imprime `{"erreur":"module-absent"}`, rendu `absent`. T5.2 vert dès le départ (la fabrication du marqueur est prouvée).
