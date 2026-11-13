# 76-03 — Trace rouge (régime allégé : le seul témoin exigé est le rouge d'assertion avant chaque code)

Le harnais attrape l'échec d'import des modules absents et imprime `{"erreur":"module-absent"}` ; chaque assertion rend donc `obtenu : absent` (ou `vide`), jamais un plantage de la suite.

## Tâche 1 — T7.1, T7.2 (modules `vf-cockpit-trace-memoire*.mjs` absents)

```
=== T7 — une entrée de mémoire lue en structure seule ===
  ❌ FAIL — T7.1 name lu — attendu: [entree-a] obtenu: [absent]
  ❌ FAIL — T7.1 agent = le dossier — attendu: [vf-coder] obtenu: [absent]
  ❌ FAIL — T7.1 metadata.type imbriqué — attendu: [project] obtenu: [absent]
  ❌ FAIL — T7.1 jour du dernier commit — attendu: [2026-01-10] obtenu: [absent]
  ❌ FAIL — T7.1 lien résolu par name — attendu: [[{"cible":"entree-b","etat":"resolu","vers":"vf-coder/b.md"}]] obtenu: [absent]
  ❌ FAIL — T7.1 lien entrant de b — attendu: [["vf-coder/a.md"]] obtenu: [absent]
  ✅ PASS — T7.2 témoin positif : description et corps sont dans le fichier du lab
  ❌ FAIL — T7.2 ni description ni corps dans la sortie (sortie non vide) — attendu: [ok] obtenu: [vide]
=== Bilan : 1 passés, 7 échoués ===
```
