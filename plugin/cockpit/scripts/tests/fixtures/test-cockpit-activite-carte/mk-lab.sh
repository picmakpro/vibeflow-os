# mk-lab.sh — le lab des témoins navigateur de test-cockpit-activite-carte.sh (à sourcer ; $SCRIPTS = scripts/ du module, $WORK posés par la suite).
#   mklab75 <dossier> : un nœud « src » de 33 fichiers (au-delà de GROUP_AT = 24 : deux dossiers virtuels src/a et src/b), des noms HOSTILES
#   (balises, très long, U+2028), deux plans non faits qui prévoient des fichiers absents (dont un hors de tout nœud : carte « non assignés »).
mklab75() {
  local L="$1" P="$1/.planning/phases/01-socle" i hostile long sep
  mkdir -p "$L/src/a" "$L/src/b" "$L/docs" "$P"
  for i in $(seq -w 1 14); do
    printf 'export const f%s = () => %s;\n' "$i" "$i" > "$L/src/a/m$i.js"
    printf 'import { f01 } from "../a/m01.js";\nexport const g%s = f01;\n' "$i" > "$L/src/b/n$i.js"
  done
  hostile='<img src=x onerror=window.__xss=1>.js'; long="$(printf 'l%.0s' $(seq 1 120)).js"; sep="x$(printf '\xe2\x80\xa8')y.js"
  printf 'export const h = 1;\n' > "$L/src/b/$hostile"; printf 'export const l = 1;\n' > "$L/src/b/$long"; printf 'export const s = 1;\n' > "$L/src/b/$sep"
  printf '# note\n' > "$L/docs/note.md"
  printf -- '- [ ] **Phase 1: Socle** - en cours\n' > "$L/.planning/ROADMAP.md"
  printf -- '---\nphase: 1\nplan: "02"\nwave: 1\nfiles_modified:\n  - src/a/neuf.mjs\n  - autre/orphelin.mjs\n---\n<objective>Premier plan</objective>\n' > "$P/01-02-PLAN.md"
  printf -- '---\nphase: 1\nplan: "03"\nwave: 1\nfiles_modified:\n  - src/a/neuf.mjs\n---\n<objective>Second plan</objective>\n' > "$P/01-03-PLAN.md"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  node "$SCRIPTS/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/build-$(basename "$L").out" 2>&1 || cat "$WORK/build-$(basename "$L").out"
}
