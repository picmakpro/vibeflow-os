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

## Tâche 2 — T7.3 à T7.9 (code de la tâche 1 en place)

Seuls les nombres de liens (T7.7) manquaient au code de la tâche 1 : le module git a été écrit complet dès la tâche 1 (filtre de profondeur, comptes des non suivis, borne, chemin
relatif), et le harnais lit sous `lireConfine`, de sorte que T7.3 à T7.6, T7.8 et T7.9 sont verts d'emblée. Pas de mutant (régime allégé, plan non marqué pour audit de sécurité) :
les témoins positifs de chaque « jamais » (fichier local suivi par git, lien rendant le marqueur au shell, trois noms listés par `ls`) sont dans la suite.

```
  ❌ FAIL — T7.7 nombre de liens sortants (une cible citée deux fois compte une fois) — attendu: [2] obtenu: [absent]
  ❌ FAIL — T7.7 nombre de liens entrants — attendu: [1] obtenu: [absent]
=== Bilan : 29 passés, 2 échoués ===
```

## Tâche 3 — T8.1 à T8.7 (code de la tâche 2 en place ; 14 rouges, T8.6 et T8.7 verts d emblée : le module ne produit ni péremption ni description)

```
  ❌ FAIL — T8.1 seul le lien hors code est retenu — attendu: [["entree-b"]] obtenu: [["entree-b",":alpha:","dans-bloc","entre-accents"]]
  ❌ FAIL — T8.2 états dans l'ordre de citation — attendu: [["resolu","resolu-par-nom","casse","resolu"]] obtenu: [["resolu","resolu","resolu","resolu"]]
  ❌ FAIL — T8.2 cible par nom de fichier — attendu: [vf-coder/c.md] obtenu: [absent]
  ❌ FAIL — T8.2 compteurs resolusParNom et liensCasses du lab — attendu: [[1,1]] obtenu: [[null,null]]
  ❌ FAIL — T8.2 compteurs de l'agent — attendu: [[1,1,3]] obtenu: [absent]
  ❌ FAIL — T8.3 a.md hors index (aa.md ne l'indexe pas) — attendu: [true] obtenu: [absent]
  ❌ FAIL — T8.3 aa.md indexé — attendu: [false] obtenu: [absent]
  ❌ FAIL — T8.3 b.md indexé malgré le ./ initial — attendu: [false] obtenu: [absent]
  ❌ FAIL — T8.3 compteur horsIndex — attendu: [1] obtenu: [absent]
  ❌ FAIL — T8.4 citée par l'index et par elle-même : sans lien entrant — attendu: [true] obtenu: [absent]
  ❌ FAIL — T8.4 citée par une autre entrée : avec lien entrant — attendu: [false] obtenu: [absent]
  ❌ FAIL — T8.4 compteur sansEntrant (x et z) — attendu: [2] obtenu: [absent]
  ❌ FAIL — T8.5 supprimé et déplacé listés, relatifs, triés — attendu: [["docs/ancien.md","docs/vieux.md"]] obtenu: [absent]
  ❌ FAIL — T8.5 compteur : deux chemins distincts — attendu: [2] obtenu: [absent]
=== Bilan : 41 passés, 14 échoués ===
```
