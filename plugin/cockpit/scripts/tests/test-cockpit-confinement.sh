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
MK_MOD="MARQUEUR-EXT-MOD"; MK_VER="MARQUEUR-EXT-VER"; MK_DAG="MARQUEUR-EXT-DAG"; MK_OKMOD="MARQUEUR-DANS-LE-LAB-MOD"; MK_OKVER="MARQUEUR-DANS-LE-LAB-VER"; MK_OKDAG="MARQUEUR-DANS-LE-LAB-DAG"
printf '/** %s : module du poste hors du lab, décrit par son commentaire d en-tête. */\nexport const e = 1;\n' "$MK_MD" > "$DEHORS/ext.js"
printf '#!/bin/sh\n# %s : script du poste hors du lab, décrit par son en-tête.\necho ok\n' "$MK_SH" > "$DEHORS/ext.sh"
printf '<objective>%s : plan du poste hors du lab</objective>\n' "$MK_PLAN" > "$DEHORS/plan.md"
printf '{"type":"agent","description":"%s : module du poste hors du lab, décrit par son module.json."}\n' "$MK_MOD" > "$DEHORS/module.json"
printf '9.9.9-%s\n' "$MK_VER" > "$DEHORS/VERSION"
printf '{"nodes":[{"id":"%s","status":"running","step":"x"}]}\n' "$MK_DAG" > "$DEHORS/ext.dag.json"

LAB="$WORK/lab"; B="$LAB/.planning"; mkdir -p "$LAB/src"
printf 'export const u = 1;\n' > "$LAB/src/u.js"
printf '#!/bin/sh\n# %s : script du lab lui-même, décrit par son en-tête.\necho ok\n' "$MK_OK" > "$LAB/src/normal.sh"
ln -s "$DEHORS/ext.js" "$LAB/src/ext.js"; ln -s "$DEHORS/ext.sh" "$LAB/src/ext.sh"
# modules du lab (page Code VibeFlow : module.json et VERSION lus hors du scan) : m1 lié hors du lab, m2 normal (témoin positif)
mkdir -p "$LAB/plugin/m1" "$LAB/plugin/m2"; ln -s "$DEHORS/module.json" "$LAB/plugin/m1/module.json"; ln -s "$DEHORS/VERSION" "$LAB/plugin/m1/VERSION"
printf '{"type":"agent","description":"%s : module du lab lui-même."}\n' "$MK_OKMOD" > "$LAB/plugin/m2/module.json"; printf '1.2.3-%s\n' "$MK_OKVER" > "$LAB/plugin/m2/VERSION"
# DAG de mission : un lien sortant (ext) et un fichier du lab (ok), tous deux avec un nœud en cours
mkdir -p "$LAB/.planning/missions"; ln -s "$DEHORS/ext.dag.json" "$LAB/.planning/missions/ext.dag.json"
printf '{"nodes":[{"id":"%s","status":"running","step":"x"}]}\n' "$MK_OKDAG" > "$LAB/.planning/missions/ok.dag.json"
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
assert_eq "A1b — témoin positif : le module et la version du lab sont décrits dans la page Code" "$([ "$(compte "$MK_OKMOD" "$OUT/index.html")" -ge 1 ] && [ "$(compte "$MK_OKVER" "$OUT/index.html")" -ge 1 ] && echo oui || echo non)" "oui"
for M in "$MK_MD" "$MK_SH" "$MK_MOD" "$MK_VER"; do
  assert_eq "A3 — $M : ni dans les pages, ni dans graph.json, ni dans l'export" "$(compte "$M" "$OUT/index.html" "$OUT/project.html" "$OUT/graph.json" "$OUT/architecture.json" "$EXP")" "0"
done
assert_eq "A4 — $MK_PLAN (lien dans .planning/) : ni dans la page Projet, ni dans l'export" "$(compte "$MK_PLAN" "$OUT/project.html" "$OUT/index.html" "$EXP")" "0"
assert_eq "A5 — le contenu planning du lab reste lu (témoin : plan du lab dans la page Projet)" "$([ "$(compte 'Poser le socle' "$OUT/project.html")" -ge 1 ] && echo oui || echo non)" "oui"
cat > "$WORK/qui.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
const [, , scripts, lab, home] = process.argv;
const { collectWho } = await import(pathToFileURL(scripts + '/vf-cockpit-who.mjs').href);
console.log(JSON.stringify(collectWho(lab, { home })));
JS
mkdir -p "$WORK/home"; QUI="$(node "$WORK/qui.mjs" "$SCRIPTS" "$LAB" "$WORK/home")"
assert_eq "A6 — témoin positif : le DAG du lab alimente l'équipe" "$(printf '%s' "$QUI" | grep -o "$MK_OKDAG" | wc -l | tr -d ' ' | awk '{print ($1>=1)?"oui":"non"}')" "oui"
assert_eq "A7 — un DAG lié hors du lab n'alimente pas l'équipe" "$(printf '%s' "$QUI" | grep -o "$MK_DAG" | wc -l | tr -d ' ')" "0"

# ---------- G : dépôt git dont le dossier git sort du lab ----------
echo "=== G — dépôt git extérieur ==="
EXT="$WORK/ext-depot"; mkdir -p "$EXT"; G "$EXT" init -q; echo x > "$EXT/f"; G "$EXT" add -A; G "$EXT" commit -q -m "MARQUEUR-EXT-MSG"
G "$EXT" branch -m MARQUEUR-EXT-BRANCH; G "$EXT" tag -a MARQUEUR-EXT-TAG -m "MARQUEUR-EXT-TAGMSG"
mkplan() { wr "$1/.planning/ROADMAP.md" <<'MD'
## Phases

- [ ] **Phase 1: Socle** - premier jet

### Phase 1: Socle
**Goal**: Poser le socle
MD
  printf -- '---\nstatus: executing\ncurrent_phase: 1\n---\n' > "$1/.planning/STATE.md"; mkdir -p "$1/src"; printf 'export const u = 1;\n' > "$1/src/u.js"; }
L2="$WORK/lab-g2"; mkplan "$L2"; ln -s "$EXT/.git" "$L2/.git"   # le .git du lab est un lien vers un dépôt extérieur
node "$SCRIPTS/vf-cockpit-build.mjs" "$L2" --quiet > "$WORK/build-g2.out" 2>&1 || cat "$WORK/build-g2.out"
L3="$WORK/lab-g3"; mkplan "$L3"; G "$L3" init -q && G "$L3" add -A && G "$L3" commit -q -m init; G "$L3" branch -m MARQUEUR-DANS-LE-LAB-BRANCH
L5="$WORK/lab-g5"; mkplan "$L5"   # dossier de projets sans dépôt à la racine : les dépôts imbriqués sont découverts
mkdir -p "$L5/sub" "$L5/sub2"; echo y > "$L5/sub/g.js"; printf 'gitdir: %s\n' "$EXT/.git" > "$L5/sub/.git"   # gitfile désignant un dépôt extérieur
G "$L5/sub2" init -q; echo z > "$L5/sub2/h.js"; G "$L5/sub2" add -A; G "$L5/sub2" commit -q -m s; G "$L5/sub2" branch -m MARQUEUR-DANS-LE-LAB-SUBBRANCH   # dépôt imbriqué normal : témoin positif
node "$SCRIPTS/vf-cockpit-build.mjs" "$L5" --quiet > "$WORK/build-g5.out" 2>&1 || cat "$WORK/build-g5.out"
node "$SCRIPTS/vf-cockpit-build.mjs" "$L3" --quiet > "$WORK/build-g3.out" 2>&1 || cat "$WORK/build-g3.out"
O2="$L2/.vibeflow/cockpit"; O3="$L3/.vibeflow/cockpit"; O5="$L5/.vibeflow/cockpit"
assert_eq "G0 — les deux assemblages ont produit leurs pages" "$([ -s "$O2/project.html" ] && [ -s "$O3/project.html" ] && [ -s "$O5/project.html" ] && echo oui || echo non)" "oui"
assert_eq "G1 — témoin positif : la branche du dépôt du lab est lue" "$([ "$(compte 'MARQUEUR-DANS-LE-LAB-BRANCH' "$O3/project.html" "$O3/index.html" "$O3/graph.json")" -ge 1 ] && echo oui || echo non)" "oui"
assert_eq "G2 — témoin positif : un dépôt imbriqué normal du lab est lu" "$([ "$(compte 'MARQUEUR-DANS-LE-LAB-SUBBRANCH' "$O5/project.html" "$O5/index.html" "$O5/graph.json")" -ge 1 ] && echo oui || echo non)" "oui"
assert_eq "G3 — un .git du lab lié vers un dépôt extérieur n'est pas lu (branche, tag, message, sha)" "$(compte 'MARQUEUR-EXT' "$O2/project.html" "$O2/index.html" "$O2/graph.json")" "0"
assert_eq "G4 — un dépôt imbriqué dont le gitfile désigne un dépôt extérieur n'est pas lu" "$(compte 'MARQUEUR-EXT' "$O5/project.html" "$O5/index.html" "$O5/graph.json")" "0"

# ---------- N : noms listés et pointeur de compartiment ----------
echo "=== N — noms et pointeur ==="
mkdir -p "$DEHORS/dossier-phase"; printf '<objective>x</objective>\n' > "$DEHORS/dossier-phase/01-99-PLAN.md"
L4="$WORK/lab-n"; mkplan "$L4"; printf -- '- [ ] **Phase 2: Écran** - second\n' >> "$L4/.planning/ROADMAP.md"
mkdir -p "$L4/.planning/phases/02-ecran"; printf '<objective>ok</objective>\n' > "$L4/.planning/phases/02-ecran/02-01-PLAN.md"; ln -s "$DEHORS/dossier-phase" "$L4/.planning/phases/01-socle"
G "$L4" init -q && G "$L4" add -A && G "$L4" commit -q -m init
L6="$WORK/lab-n2"; mkplan "$L6"; mkdir -p "$L6/.planning/workstreams/alpha" "$L6/.planning/workstreams/beta"
for w in alpha beta; do printf -- '- [ ] **Phase 1: Un** - a\n' > "$L6/.planning/workstreams/$w/ROADMAP.md"; done
printf 'beta\n' > "$DEHORS/pointeur"; ln -s "$DEHORS/pointeur" "$L6/.planning/active-workstream"
L7="$WORK/lab-n3"; mkplan "$L7"; mkdir -p "$L7/.planning/workstreams/alpha" "$L7/.planning/workstreams/beta"
for w in alpha beta; do printf -- '- [ ] **Phase 1: Un** - a\n' > "$L7/.planning/workstreams/$w/ROADMAP.md"; done
printf 'beta\n' > "$L7/.planning/active-workstream"
cat > "$WORK/noms.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
const [, , scripts, lab] = process.argv;
const { buildProjectGraph } = await import(pathToFileURL(scripts + '/vf-cockpit-project.mjs').href);
const { planningLayout } = await import(pathToFileURL(scripts + '/vf-cockpit-paths.mjs').href);
const g = buildProjectGraph(lab);
console.log(JSON.stringify({ exterieur: JSON.stringify(g).includes('01-99-PLAN'), interieur: JSON.stringify(g).includes('02-01-PLAN'), actif: planningLayout(lab).actif }));
JS
assert_eq "N0 — témoin positif : le plan d'un dossier de phase du lab est listé" "$(node "$WORK/noms.mjs" "$SCRIPTS" "$L4" | grep -c '"interieur":true')" "1"
assert_eq "N1 — un dossier de phase lié hors du lab n'est pas listé (aucun nom de plan extérieur dans le graphe)" "$(node "$WORK/noms.mjs" "$SCRIPTS" "$L4" | grep -c '"exterieur":true')" "0"
assert_eq "N2 — un pointeur active-workstream lié hors du lab est ignoré comme absent" "$(node "$WORK/noms.mjs" "$SCRIPTS" "$L6" | grep -c '"actif":"beta"')" "0"
assert_eq "N3 — témoin positif : un pointeur du lab est lu" "$(node "$WORK/noms.mjs" "$SCRIPTS" "$L7" | grep -c '"actif":"beta"')" "1"

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
cat > "$WORK/sortant.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
const [, , scripts, ...dirs] = process.argv;
const { gitSortant } = await import(pathToFileURL(scripts + '/vf-cockpit-git-sortant.mjs').href);
console.log(dirs.map((d) => gitSortant(d)).join(','));
JS
printf 'gitdir: %s\n' "$AUTRE/.git" > "$WORK/gitfile-forge"; mkdir -p "$WORK/faux-wt"; cp "$WORK/gitfile-forge" "$WORK/faux-wt/.git"
assert_eq "B4 — gitSortant : dépôt du lab, vrai worktree = faux ; .git lié vers l'extérieur, gitfile forgé vers un autre dépôt = vrai" "$(node "$WORK/sortant.mjs" "$SCRIPTS" "$LAB" "$WORK/vrai" "$L2" "$WORK/faux-wt")" "false,false,true,true"

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
