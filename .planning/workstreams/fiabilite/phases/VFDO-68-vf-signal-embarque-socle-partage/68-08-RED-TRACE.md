# 68-08 — Trace du rouge (VFSG-07, VFSG-06 ; P68-D-05, P68-D-06, P68-D-17, P68-PL-10)

Claude Code 2.1.318. Branche `feat/phase-68-w08`, partie de `f0a850bd`. Témoins joués avant tout code (commit `fb49f6eb`).

## Empreinte de `DESIGN.md` lu

Précondition P68-D-09 : `git cat-file -e main:DESIGN.md` et `origin/main:DESIGN.md` réussissent ; le fichier contient « Graphite » et la table « Statuts de travail » ; `git diff main -- DESIGN.md` est vide. Dernier commit de `main` touchant le fichier : `db8f6736`. `shasum DESIGN.md` : `eb6928e61288eee5d10ad82e0bc501e2538f1ad1`.

## `claude plugin test plugin` (sortie : `68-08-t1-rouge.out`)

54 pass (les tests de 68-04 à 68-07 et E1..E4b, inchangés) / 9 fail (tous les témoins neufs). `verdict.sh <sortie> <id> echec` rend 0 pour chacun.

| Test | Assertion | Attendu | Obtenu (avant le code) |
|------|-----------|---------|------------------------|
| R8-G1 | couleur du `Text` « mission MISSION-68 · abandonnée, nœuds non refermés » (en-tête) | `#5c5c5c` (st-todo sombre) | `#8E96A2` (ancien `C.fg2`) : `every(...)` faux |
| R8-G1b | idem « mission MISSION-70 · état inconnu » | `#5c5c5c` | `#8E96A2` |
| R8-G2 | `Text` « (à recetter) » seul, en `st-active` | trouvé, `#f0c36b` | aucun `Text` ne porte ce libellé seul (la parenthèse est dans la ligne de l'arbre) : `length > 0` faux. Les deux autres assertions (retard, erreur) ne sont pas atteintes : leur rouge est prouvé par les mutants de la trace du vert |
| R8-G3 | mêmes éléments, thème `light` | valeurs claires | `#8E96A2` au lieu de `#666666` (thème ignoré) |
| R8-G3b | thème `dark` | `#f0c36b` | même absence que G2 |
| R8-G4 | nœuds `running`/`failed`/`done`/`pending`, fil | `#f0c36b`, `#f28b8b`, `#4ade80`, `#5c5c5c` ; fil dans {text, text-3, text-4} | cyan `#3AC7FF`, orange `#FF9500`, gris `#8E96A2` (ancienne palette) |
| R8-G4b | nœud et ligne de mission d'une mission abandonnée | `#5c5c5c` | `#4B525C` (ancien `C.fg3`) |
| R8-G5 | vue macro : phase faite, phase à recetter | `#4ade80`, `#f0c36b` | `#8E96A2` / `#4B525C` |
| R8-G5b | vue équipe : actif, terminé, orphelin | `#f0c36b`, `#5c5c5c`, `#f0c36b` | cyan, `#4B525C`, orange |

## Suite statique (`test-cockpit-signal-mod.sh`, sortie : `68-08-t1-m-rouge.out`)

37 ok / 2 ko : les deux ko sont les témoins neufs, pour la bonne raison.

- `M9 — aucun hex hors de tokens.ts (attendu [], obtenu [ds.ts,])` : la palette « Signal » de `ds.ts`.
- `M10 — hooks/tokens.ts absent`.

Contrôles positifs de ces sections, verts dès le départ : M9.0 (le motif voit `#rrggbb` en code et `#rgb` en commentaire, pas `#12` ni un fichier vide), M9.1 (16 fichiers balayés), M10.0a (fixture fidèle : 4 valeurs comparées, majuscules ignorées, 0 écart), M10.0b (fixture dérivée d'un chiffre : exactement l'écart nommé).
