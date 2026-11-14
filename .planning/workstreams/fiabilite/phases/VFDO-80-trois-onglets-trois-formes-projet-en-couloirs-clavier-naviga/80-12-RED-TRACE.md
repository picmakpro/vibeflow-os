# 80-12 — trace du rouge (base : `c` ne fait rien)

Suite `test-cockpit-cadrer.sh` jouée avant tout code : 11 PASS / 6 FAIL.

- FAIL CA1.1 : `[4,false,true,false,true]` — le groupe compte 4 cartes, mais `state.t` n'égale pas `VibeFlow.cadrage({ ids })` et le groupe n'est pas dans le champ de lecture.
- FAIL CA1.2 : `[false,false]` — pas de cadrage avec Maj, le focus n'est pas sur la carte sélectionnée.
- FAIL CA1.3 : `[true,true,[],false]` — coin et tiroir présents, la vue n'a pas bougé.
- FAIL CA2.5 : `[[0,0,0,0],false]` — aucun écouteur de la touche, `c` ne cadre pas.
- FAIL CA1.4 (tactile, feuille fermée) : la carte sélectionnée touche `#zoom` et la pastille « Terminal » (`selLibre` faux).
- FAIL CA1.4 (moyen, feuille fermée) : `k` différent de celui de `cadrage({ ids })` (rien n'a cadré).
- Verts à vide sur la base, comme prévu (témoins de garde, rien ne bouge sans la touche) : CA2.1 à CA2.4, et CA1.4 feuille ouverte (le groupe y est déjà libre).

rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale)
