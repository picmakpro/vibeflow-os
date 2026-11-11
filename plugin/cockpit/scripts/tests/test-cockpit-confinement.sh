#!/usr/bin/env bash
# test-cockpit-confinement.sh — confinement du lab et de l'export (lot 0 de l'audit du cockpit : AUDC-A-02, AUDC-B-01, AUDC-B-04).
#   A  un lien symbolique du lab vers l'extérieur n'est jamais suivi à l'assemblage : rien de sa cible dans les pages ni dans l'export (témoin positif : le même contenu, en fichier normal, y est)
#   B  un worktree déclaré mais non vérifié n'élargit pas la liste des arbres du lab (témoin positif : un vrai worktree y est)
#   D  l'export ne porte plus les clés vfTouch et vfGit (témoin positif : il garde les logos et l'onglet pour s'afficher)
# Isolation git, aucun serveur ni navigateur. Exit 0 si tout passe, 1 sinon.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"
cleanup() { if [ -n "${KEEP:-}" ]; then echo "WORK=$WORK"; else rm -rf "$WORK"; fi; }; trap cleanup EXIT
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [${2:0:300}]"; FAIL=$((FAIL+1)); fi; }
G() { git -C "$1" -c user.email=t@t -c user.name=t "${@:2}"; }
wr() { mkdir -p "$(dirname "$1")"; cat > "$1"; }

# ---------- A : lab portant des liens symboliques sortants ----------
DEHORS="$WORK/dehors"; mkdir -p "$DEHORS"
MK_MD="MARQUEUR-EXT-JS"; MK_SH="MARQUEUR-EXT-SH"; MK_PLAN="MARQUEUR-EXT-PLAN"; MK_OK="MARQUEUR-DANS-LE-LAB"
printf '/** %s : module du poste hors du lab, décrit par son commentaire d en-tête. */\nexport const e = 1;\n' "$MK_MD" > "$DEHORS/ext.js"
printf '#!/bin/sh\n# %s : script du poste hors du lab, décrit par son en-tête.\necho ok\n' "$MK_SH" > "$DEHORS/ext.sh"
printf '<objective>%s : plan du poste hors du lab</objective>\n' "$MK_PLAN" > "$DEHORS/plan.md"

LAB="$WORK/lab"; B="$LAB/.planning"; mkdir -p "$LAB/src"
printf 'export const u = 1;\n' > "$LAB/src/u.js"
printf '#!/bin/sh\n# %s : script du lab lui-même, décrit par son en-tête.\necho ok\n' "$MK_OK" > "$LAB/src/normal.sh"
ln -s "$DEHORS/ext.js" "$LAB/src/ext.js"; ln -s "$DEHORS/ext.sh" "$LAB/src/ext.sh"
wr "$B/ROADMAP.md" <<'MD'
## Milestones

- 🚧 **v1.0 MVP** - Phases 1-2 (in progress)

## Phases

- [x] **Phase 1: Socle** - premier jet
- [ ] **Phase 2: Écran** - second jet

### Phase 1: Socle
**Goal**: Poser le socle
MD
printf -- '---\nstatus: executing\ncurrent_phase: 2\nmilestone: v1.0 MVP\n---\n' > "$B/STATE.md"
wr "$B/phases/01-socle/01-01-PLAN.md" <<'MD'
---
wave: 1
files_modified: [src/u.js]
---
<objective>Poser le socle</objective>
MD
echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
mkdir -p "$B/phases/02-ecran"; ln -s "$DEHORS/plan.md" "$B/phases/02-ecran/02-01-PLAN.md"
G "$LAB" init -q && G "$LAB" add -A && G "$LAB" commit -q -m init
node "$SCRIPTS/vf-cockpit-build.mjs" "$LAB" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
OUT="$LAB/.vibeflow/cockpit"
EXP="$WORK/export.html"
node "$OUT/serve.mjs" --export "$EXP" --include flows,notes,recent,health > "$WORK/export.out" 2>&1 || cat "$WORK/export.out"

compte() { cat "${@:2}" 2>/dev/null | grep -o "$1" | wc -l | tr -d ' '; }
echo "=== A — liens symboliques sortants ==="
assert_eq "A0 — l'assemblage et l'export ont produit leurs fichiers" "$([ -s "$OUT/graph.json" ] && [ -s "$OUT/project.html" ] && [ -s "$EXP" ] && echo oui || echo non)" "oui"
assert_eq "A1 — témoin positif : le contenu d'un fichier normal du lab est décrit dans la page Code" "$([ "$(compte "$MK_OK" "$OUT/index.html")" -ge 1 ] && echo oui || echo non)" "oui"
assert_eq "A2 — témoin positif : il est aussi dans l'export" "$([ "$(compte "$MK_OK" "$EXP")" -ge 1 ] && echo oui || echo non)" "oui"
for M in "$MK_MD" "$MK_SH"; do
  assert_eq "A3 — $M : ni dans les pages, ni dans graph.json, ni dans l'export" "$(compte "$M" "$OUT/index.html" "$OUT/project.html" "$OUT/graph.json" "$EXP")" "0"
done
assert_eq "A4 — $MK_PLAN (lien dans .planning/) : ni dans la page Projet, ni dans l'export" "$(compte "$MK_PLAN" "$OUT/project.html" "$OUT/index.html" "$EXP")" "0"
assert_eq "A5 — le contenu planning du lab reste lu (témoin : plan du lab dans la page Projet)" "$([ "$(compte 'Poser le socle' "$OUT/project.html")" -ge 1 ] && echo oui || echo non)" "oui"

# ---------- B : worktree déclaré non vérifié ----------
echo "=== B — arbres du lab ==="
AUTRE="$WORK/autre"; mkdir -p "$AUTRE"; G "$AUTRE" init -q; echo x > "$AUTRE/f"; G "$AUTRE" add -A; G "$AUTRE" commit -q -m autre
G "$LAB" worktree add -q "$WORK/vrai" -b vrai > /dev/null 2>&1
mkdir -p "$LAB/.git/worktrees/forge"
printf '%s\n' "$AUTRE/.git" > "$LAB/.git/worktrees/forge/gitdir"; printf 'ref: refs/heads/forge\n' > "$LAB/.git/worktrees/forge/HEAD"; printf '../..\n' > "$LAB/.git/worktrees/forge/commondir"
LISTE="$(G "$LAB" worktree list --porcelain)"
assert_eq "B0 — le fixture est vivant : git liste bien l'entrée déclarée" "$(printf '%s\n' "$LISTE" | grep -c "^worktree $AUTRE\$")" "1"
cat > "$WORK/arbres.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
const [, , scripts, lab] = process.argv;
const { arbresGit } = await import(pathToFileURL(scripts + '/vf-cockpit-arbres.mjs').href);
console.log(arbresGit(lab).map((a) => a.chemin).join('\n'));
JS
ARB="$(node "$WORK/arbres.mjs" "$SCRIPTS" "$LAB")"
assert_eq "B1 — l'entrée déclarée mais non vérifiée n'est pas un arbre du lab" "$(printf '%s\n' "$ARB" | grep -c "^$AUTRE\$")" "0"
assert_eq "B2 — témoin positif : le vrai worktree reste un arbre du lab" "$(printf '%s\n' "$ARB" | grep -c "^$WORK/vrai\$")" "1"
assert_eq "B3 — témoin positif : l'arbre principal reste le premier" "$(printf '%s\n' "$ARB" | head -1)" "$LAB"

# ---------- D : métadonnées VibeFlow de l'export ----------
echo "=== D — export ==="
cat > "$WORK/cles.mjs" <<'JS'
import fs from 'node:fs';
// la page exportée est celle de la sortie (marque blanche) : sa zone de données commence par window.VF_COCKPIT
const h = fs.readFileSync(process.argv[2], 'utf8'); const D = '<script>window.VF_COCKPIT = ';
const a = h.indexOf(D), b = h.indexOf(';</script>', a);
if (a < 0 || b < 0) { console.log('ZONE-DE-DONNEES-INTROUVABLE'); process.exit(0); }
const g = JSON.parse(h.slice(a + D.length, b));
console.log(Object.keys(g.meta).filter((k) => /^vf/.test(k)).sort().join(','));
JS
node -e "const g=JSON.parse(require('fs').readFileSync('$OUT/graph.json','utf8'));console.log(Object.keys(g.meta).filter(k=>k==='vfTouch'||k==='vfGit').sort().join(','))" > "$WORK/source.txt"
assert_eq "D0 — témoin : la page servie porte bien vfTouch et vfGit (sinon le test ne prouve rien)" "$(cat "$WORK/source.txt")" "vfGit,vfTouch"
CLES="$(node "$WORK/cles.mjs" "$EXP")"
assert_eq "D1 — l'export ne porte ni vfTouch ni vfGit" "$(printf '%s' "$CLES" | tr ',' '\n' | grep -cE '^(vfTouch|vfGit)$')" "0"
assert_eq "D2 — témoin positif : il garde les logos et l'onglet pour s'afficher" "$(printf '%s' "$CLES" | tr ',' '\n' | grep -cE '^(vfLogos|vfTab)$')" "2"

echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
