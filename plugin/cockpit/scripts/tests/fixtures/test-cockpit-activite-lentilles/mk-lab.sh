# mk-lab.sh — le lab de test-cockpit-activite-lentilles.sh (à sourcer ; $SCRIPTS = scripts/ du module, $WORK posés par la suite).
#   mklentilles <dossier> : un lab AVEC historique git sur 14 fichiers (couplage : m01 avec m02 et m03 ; paliers de points chauds), une garde
#   (scripts/check-lab.sh), une suite (scripts/tests/test-lab.sh) qui nomme m01 et m02, un nœud « src » de 28 fichiers (deux dossiers virtuels),
#   un plan non fait qui prévoit un fichier absent. Le graphe est construit à la fin (le lab est un lab VibeFlow : `gardes` est lu).
mklentilles() {
  local L="$1" P="$1/.planning/phases/01-socle" i k c n
  mkdir -p "$L/src/a" "$L/src/b" "$L/scripts/tests" "$P"
  git -C "$L" init -q
  git -C "$L" config user.email t@t; git -C "$L" config user.name t
  for i in $(seq -w 1 14); do
    printf 'export const f%s = () => %s;\nexport const g%s = () => %s;\nexport const h%s = () => %s;\n' "$i" "$i" "$i" "$i" "$i" "$i" > "$L/src/a/m$i.js"
    printf 'import { f01 } from "../a/m01.js";\nexport const g%s = f01;\n' "$i" > "$L/src/b/n$i.js"
  done
  printf '#!/usr/bin/env bash\necho garde\n' > "$L/scripts/check-lab.sh"
  printf '#!/usr/bin/env bash\n# nomme src/a/m01.js et src/a/m02.js\nsrc/a/m01.js src/a/m02.js\n' > "$L/scripts/tests/test-lab.sh"
  printf -- '- [ ] **Phase 1: Socle** - en cours\n' > "$L/.planning/ROADMAP.md"
  printf -- '---\nphase: 1\nplan: "02"\nwave: 1\nfiles_modified:\n  - src/a/neuf.mjs\n---\n<objective>Premier plan</objective>\n' > "$P/01-02-PLAN.md"
  git -C "$L" add -A && git -C "$L" commit -q -m init
  # l'historique : m01 avec m02 (6 fois) et avec m03 (5 fois) ; m04 à m14 seuls, un nombre de fois croissant (paliers)
  c=0
  for k in 1 2 3 4 5 6; do c=$((c+1)); echo "// r$c" >> "$L/src/a/m01.js"; echo "// r$c" >> "$L/src/a/m02.js"; [ "$k" -le 5 ] && echo "// r$c" >> "$L/src/a/m03.js"; git -C "$L" commit -q -am "c$c"; done
  for i in 04 05 06 07 08 09 10 11 12 13 14; do
    n=$((10#$i - 3))
    for k in $(seq 1 "$n"); do c=$((c+1)); echo "// r$c" >> "$L/src/a/m$i.js"; git -C "$L" commit -q -am "c$c"; done
  done
  node "$SCRIPTS/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/build-$(basename "$L").out" 2>&1 || cat "$WORK/build-$(basename "$L").out"
}
