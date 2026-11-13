# 76-01 — Témoins rouges (joués avant le code)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-tracabilite-chaine.sh` (régime allégé : pas de mutant, le témoin rouge est le seul témoin exigé).

## Tâche 1 — chaîne d'une exigence (T1.1, T1.2)

Les modules `vf-cockpit-trace-*.mjs` n'existent pas encore : le harnais attrape l'échec d'import et imprime `{"erreur":"module-absent"}`,
`assert_eq` rend « obtenu : absent » (échec d'assertion, pas plantage de la suite).

```
=== T1 — une exigence de bout en bout ===
  ❌ FAIL — T1.1 REQ-01 : mot de ligne = manque VERIFICATION (rien n'existe au-delà du SUMMARY) — attendu: [verification/manque] obtenu: [absent]
  ❌ FAIL — T1.1b REQ-01 : plan lu au niveau exigence — attendu: [lu/exigence] obtenu: [absent]
  ❌ FAIL — T1.1c REQ-01 : SUMMARY lu au niveau exigence (requirements-completed scalaire) — attendu: [lu/exigence] obtenu: [absent]
  ❌ FAIL — T1.1d REQ-01 : VERIFICATION et recette manquent — attendu: [manque/- manque/-] obtenu: [absent absent]
  ❌ FAIL — T1.2 REQ-02 : VERIFICATION citée dans la table, lue au niveau exigence (témoin positif voisin) — attendu: [lu/exigence] obtenu: [absent]

Résultats : 0 passés, 5 échoués
```

## Tâche 2 — tableaux de `reste()` capturés AVANT la modification de `vf-cockpit-avancement.mjs`

Base `faed809d`. `reste({ ph: { done: false }, fichiers: ['01-PLAN.md', '01-CONTEXT.md', '01-RECETTE-HUMAINE.md'], lire: () => <forme>, vivante: false })` :

| forme | texte du fichier de recette | `reste()` |
|-------|-----------------------------|-----------|
| 1 | `**Statut : FAITE — close le 2026-11-05.` | `["verification","cloture"]` |
| 2 | `**Statut :** CLOSE — recette terminée` | `["recette","verification","cloture"]` |
| 3 | `Statut : recette jouée, tout est bon` (sans gras) | `["recette","verification","cloture"]` |
| 4 | aucune ligne `**Statut :` | `["recette","verification","cloture"]` |
