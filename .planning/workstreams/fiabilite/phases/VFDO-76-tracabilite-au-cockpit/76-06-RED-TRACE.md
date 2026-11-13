BASE=5b5efe73920ca8878af04c5775fac4c6906c0fa9

# 76-06 — trace rouge (régime allégé : test d'abord, vu ROUGE)

## Tâche 1 — C1.0 à C1.2 (code de page absent : aucun `ui/74-vf-trace*.js` dans l'arbre)

Suite jouée : `bash plugin/cockpit/scripts/tests/test-cockpit-tracabilite-page.sh` (serveur réel sur une copie du module, Chrome sans tête). C0 vert (témoin : serveur et première collecte).

```
  ❌ FAIL — C1.0 — fichier neuf servi : /_vf/…/74-vf-trace.js répond 200, première ligne « // VibeFlow ( »
     attendu: [200|// VibeFlow (]
     obtenu:  [non demandé]
  ❌ FAIL — C1.0b — un 74-vf-trace-intrus.js planté après le démarrage répond 404 (liste fermée au démarrage)
     attendu: [404]
     obtenu:  [non demandé]
  ❌ FAIL — C1.1 — select(n:ph-2) : #vf-trace-phase, h3 « Traçabilité », ligne REQ-01 (un button) au mot « manque : VERIFICATION »
     attendu: [true|Traçabilité|BUTTON:REQ-01:manque : VERIFICATION]
     obtenu:  [false|null|]
  ❌ FAIL — C1.1b — la requête vue au réseau est GET /api/vf/tracabilite?vue=phase&cle=ph-2
     attendu: [true]
     obtenu:  [false]
  ❌ FAIL — C1.2 — témoin positif voisin : select(n:ph-3), REQ-02 à chaîne complète, mot « chaîne complète »
     attendu: [true|chaîne complète]
     obtenu:  [false|]
  ✅ PASS — C1.x — aucune section n'a échoué par erreur de harnais
```

Rouge par l'assertion visée (« obtenu : absent »), jamais par un plantage de Chrome. Les mutants (M-MOT-VERIF et suivants) sont levés : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale).
