BASE=39300871800fbfa0aa74c19850577f836af96c2a

# 76-07 — trace rouge (régime allégé : test d'abord, vu ROUGE)

## Tâche 1 — C3.1 et C3.2 (aucun `ui/74-vf-trace-decisions.js` dans l'arbre : section « Décisions » absente)

Suite jouée : `bash plugin/cockpit/scripts/tests/test-cockpit-tracabilite-panneaux.sh` (serveur réel sur une copie du module, Chrome sans tête, lab fabriqué dans `$WORK`).
C0 vert (témoin : le serveur écoute et la route sert `ADR-001`).

```
  ❌ FAIL — C3.1a — section « Décisions » repliée par défaut, aucune requête vue=adr avant l'ouverture, une seule à l'ouverture
     attendu: [true|0|1]
     obtenu:  [absent : Cannot read properties of undefined (reading 'req')]
  ❌ FAIL — C3.1b — bilan « 2 ADR · 3 décisions · 1 registre de phase », compteur « 2 ADR », une ligne par ADR avec section (ADR-007 sans section n'en a pas)
     attendu: [2 ADR · 3 décisions · 1 registre de phase|2 ADR|ADR-001,ADR-002]
     obtenu:  [absent : Cannot read properties of undefined (reading 'bilan')]
  ❌ FAIL — C3.1c — Entrée sur ADR-001 : panneau d'ADR, titre « ADR-001 », id vf-trace-adr-ADR-001, data-trace adr:ADR-001, étiquette « ADR »
     attendu: [ADR-001|vf-trace-adr-ADR-001|adr:ADR-001|ADR]
     obtenu:  [absent : Cannot read properties of undefined (reading 'titre')]
  ❌ FAIL — C3.2 — témoin voisin : ADR-002 sans commit : « Aucun commit ne cite cet objet. Un message de commit qui nomme son identifiant le relierait. »
     attendu: [ADR-002|true|0]
     obtenu:  [absent : Cannot read properties of undefined (reading 'titre')]
  ❌ FAIL — C3.x — aucune section n'a échoué par erreur de harnais
     attendu: [{}]
     obtenu:  [{"d1":"clic : « #panel details[data-vf-trace-decisions] > summary » absent"}]
```

Rouge par l'assertion visée (la section n'existe pas), jamais par un plantage de Chrome. Vert après le code : 9 PASS / 0 FAIL (12 s).
Les mutants (M-NUE-PAGE, M-PLAFOND-30, …) sont levés : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale).
