---
name: borne-longue-reduction-deux-formes
description: Un correctif « borne puis doute » sur un chemin long doit être prouvé par différentiel contre l'analyse exacte ; la réduction lexicale seule régresse (`..` après un lien), il faut aussi la forme physique en temps linéaire.
metadata:
  type: project
---

Phase 45, planning-hook.sh, quick 261002-3rx : l'aiguillage « valeur > 4096 caractères → décision dans le doute sur le nom » (N2-01) a ouvert un trou (lien dur, lien symbolique, juge derrière un rembourrage). La réduction lexicale (`posixpath.normpath`) seule régresse encore : `src/cyc/../STATE.md` avec `cyc` -> sous-dossier gardé est refusé par la résolution physique, pas par la lexicale (7 régressions au premier différentiel).

**Why:** le coût quadratique vient de `realpath` + `racine_lab` sur des composants ABSENTS ; on peut résoudre physiquement en temps linéaire (pile + `lstat` seulement quand tous les ancêtres existent), égal à `realpath` sur 20 000 chemins au hasard.

**How to apply:** pour toute borne de longueur sur un chemin, (1) construire un différentiel 3 versions (avant la borne, avec la borne, nouveau) sur lab réel avec lien dur / lien symbolique / `..` sous un lien dans les DEUX sens ; (2) lire la valeur sous les deux formes et refuser si l'une refuse ; (3) un cas « tué par l'horloge » est acceptable seulement s'il est aussi tué par le verdict (boucle de liens : rc 73 ≠ verdict du jumeau court). Les mutants existants de `main()` (`sys.exit(0)  # non-adherent`, la ligne `adherent = racine is not None and …`) exigent que ces deux lignes gardent leur forme : restructurer autour d'elles, pas à leur place.
