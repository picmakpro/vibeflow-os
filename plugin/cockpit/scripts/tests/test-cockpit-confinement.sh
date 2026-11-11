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

cat > "$WORK/entete.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
const [, , scripts, lab] = process.argv;
const { enteteAsync } = await import(pathToFileURL(scripts + '/vf-cockpit-git.mjs').href);
const { finDans } = await import(pathToFileURL(scripts + '/vf-cockpit-paths.mjs').href);
const e = await enteteAsync(lab, finDans(8000)); console.log(e.etat + '|' + (e.branche || ''));
JS
assert_eq "G5 — témoin positif : l'en-tête Git en direct lit la branche du dépôt du lab" "$(node "$WORK/entete.mjs" "$SCRIPTS" "$L3")" "ok|MARQUEUR-DANS-LE-LAB-BRANCH"
assert_eq "G6 — l'en-tête Git en direct ne lit pas un .git du lab lié vers un dépôt extérieur" "$(node "$WORK/entete.mjs" "$SCRIPTS" "$L2")" "absent|"

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
# point central : tout lancement git du socle (shBorne, lancerGit, lancerGitAsync) refuse un dossier dont le .git désigne un dépôt hors du lab
cat > "$WORK/central.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
const [, , scripts, rogue, normal, wt, lab] = process.argv;
const P = await import(pathToFileURL(scripts + '/vf-cockpit-paths.mjs').href);
const { arbresGit } = await import(pathToFileURL(scripts + '/vf-cockpit-arbres.mjs').href);
const b = (o) => (o || '').trim();
const out = [];
for (const d of [rogue, normal]) out.push(b(P.lancerGit(d, ['symbolic-ref', '--quiet', '--short', 'HEAD']).sortie) || '-');
for (const d of [rogue, normal]) out.push(b((await P.lancerGitAsync(d, ['symbolic-ref', '--quiet', '--short', 'HEAD'], { fin: Date.now() + 8000 })).sortie) || '-');
for (const d of [rogue, normal]) out.push(b(P.shBorne('git', [...P.GIT_SUR, '-C', d, 'symbolic-ref', '--quiet', '--short', 'HEAD'], d, d)) || '-');
out.push(arbresGit(rogue).length + ':' + arbresGit(rogue)[0].chemin.includes('ext-depot'));
out.push(b(P.lancerGit(wt, ['symbolic-ref', '--quiet', '--short', 'HEAD'], { lab }).sortie) || '-');
console.log(out.join('|'));
JS
RES="$(node "$WORK/central.mjs" "$SCRIPTS" "$L2" "$L3" "$WORK/vrai" "$LAB")"
assert_eq "G7 — lancerGit, lancerGitAsync, shBorne et arbresGit : rien d'un .git sortant ; témoins : dépôt du lab et worktree vérifié lus" "$RES" "-|MARQUEUR-DANS-LE-LAB-BRANCH|-|MARQUEUR-DANS-LE-LAB-BRANCH|-|MARQUEUR-DANS-LE-LAB-BRANCH|1:false|vrai"


# G8-G14 : le critère porte sur le dossier git que git lit RÉELLEMENT (dossier git et dossier commun résolus), jamais sur la forme de `.git`
echo "=== G8 — dossier git et dossier commun résolus ==="
L8="$WORK/lab-g8"; mkplan "$L8"; G "$L8" init -q; mkdir -p "$L8/sub3"; G "$L8/sub3" init -q; printf '%s\n' "$EXT/.git" > "$L8/sub3/.git/commondir"; printf 'ref: refs/heads/MARQUEUR-EXT-BRANCH\n' > "$L8/sub3/.git/HEAD"   # .git est un DOSSIER, son dossier commun est un dépôt extérieur
node "$SCRIPTS/vf-cockpit-build.mjs" "$L8" --quiet > "$WORK/build-g8.out" 2>&1 || cat "$WORK/build-g8.out"
O8="$L8/.vibeflow/cockpit"
assert_eq "G8 — un dépôt imbriqué dont le .git est un dossier au dossier commun extérieur n'est pas lu (assemblage)" "$(compte 'MARQUEUR-EXT' "$O8/project.html" "$O8/index.html" "$O8/graph.json")" "0"
# gitfile vers un dossier INTERNE au lab qui porte un commondir extérieur
mkdir -p "$L8/interne/admin" "$L8/sub4"; cp -R "$L8/sub3/.git/." "$L8/interne/admin/"; printf 'gitdir: %s\n' "$L8/interne/admin" > "$L8/sub4/.git"
# sous-module légitime comme LAB (gitfile vers parent/.git/modules/x, core.worktree vers le lab) : son git reste lu
SUBSRC="$WORK/subsrc"; mkdir -p "$SUBSRC"; G "$SUBSRC" init -q; echo s > "$SUBSRC/s"; G "$SUBSRC" add -A; G "$SUBSRC" commit -q -m s; G "$SUBSRC" branch -m MARQUEUR-DANS-LE-LAB-SUBMOD
PAR="$WORK/parent-sm"; mkdir -p "$PAR"; G "$PAR" init -q; echo p > "$PAR/p"; G "$PAR" add -A; G "$PAR" commit -q -m p
G "$PAR" -c protocol.file.allow=always submodule add -q "$SUBSRC" sm > /dev/null 2>&1
# dépôt --separate-git-dir : aucun lien retour vers le lab
SEP="$WORK/sep-work"; SEPD="$WORK/sep-gitd"; G "$WORK" init -q --separate-git-dir="$SEPD" "$SEP"
# faux worktree : une entrée d'un dépôt extérieur dont le lien retour désigne ce .git mais dont le dossier commun est un autre dépôt
FW="$WORK/faux-wt2"; mkdir -p "$FW" "$EXT/.git/worktrees/forge2"; printf 'gitdir: %s\n' "$EXT/.git/worktrees/forge2" > "$FW/.git"
printf '%s\n' "$FW/.git" > "$EXT/.git/worktrees/forge2/gitdir"; printf 'ref: refs/heads/MARQUEUR-EXT-BRANCH\n' > "$EXT/.git/worktrees/forge2/HEAD"; printf '%s\n' "$AUTRE/.git" > "$EXT/.git/worktrees/forge2/commondir"
cat > "$WORK/sortant-lab.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
const [, , scripts, dir, lab] = process.argv;
const { gitSortant } = await import(pathToFileURL(scripts + '/vf-cockpit-git-sortant.mjs').href);
console.log(String(gitSortant(dir, lab)));
JS
assert_eq "G9 — gitSortant : .git dossier + commondir extérieur = vrai ; gitfile interne + commondir extérieur = vrai ; faux worktree à dossier commun étranger = vrai" "$(node "$WORK/sortant.mjs" "$SCRIPTS" "$L8/sub3" "$FW"),$(node "$WORK/sortant-lab.mjs" "$SCRIPTS" "$L8/sub4" "$L8")" "true,true,true"
assert_eq "G10 — témoins : sous-module lu comme lab (gitfile vers parent/.git/modules, core.worktree vers le lab) = faux ; dépôt ordinaire = faux ; vrai worktree = faux" "$(node "$WORK/sortant.mjs" "$SCRIPTS" "$PAR/sm" "$L3" "$WORK/vrai")" "false,false,false"
assert_eq "G11 — un dépôt --separate-git-dir sans lien retour vers le lab est ignoré (limite assumée)" "$(node "$WORK/sortant.mjs" "$SCRIPTS" "$SEP")" "true"
RESG="$(node "$WORK/central.mjs" "$SCRIPTS" "$L8/sub3" "$PAR/sm" "$WORK/vrai" "$LAB")"
assert_eq "G12 — lancerGit : le dépôt à dossier commun extérieur ne rend rien ; témoin : le sous-module lab est lu (HEAD)" "$(printf '%s' "$RESG" | cut -d'|' -f1,2)" "-|MARQUEUR-DANS-LE-LAB-SUBMOD"

# G13 : règle à point fixe, preuve GÉNÉRATIVE. Pour chaque membre des métadonnées que git ouvre (premier niveau, refs/, objects/ avec info et pack), un lab dont CE membre est un lien
# vers un dépôt extérieur marqué ; plus alternates et core.worktree étrangers. Aucun marqueur ne doit sortir (pages, graph.json, export, /api/vf/git) et gitSortant doit refuser.
echo "=== G13 — liens dans les métadonnées git (preuve générative) ==="
GEN="$WORK/gen"; mkdir -p "$GEN"; EXTL="$GEN/extl"; mkdir -p "$EXTL"
G "$EXTL" init -q -b MARQUEUR-F1-BRANCH; printf 'f\n' > "$EXTL/MARQUEUR-F1-FILE"; G "$EXTL" add -A; G "$EXTL" commit -q -m "MARQUEUR-F1-SUBJ"; G "$EXTL" tag MARQUEUR-F1-TAG
G "$EXTL" remote add origin "https://MARQUEUR-F1-REMOTE.invalid/x.git"; E1="$(G "$EXTL" rev-parse HEAD)"
printf '%s\n' "$E1" > "$EXTL/.git/shallow"; printf '[x]\n\ty = MARQUEUR-F1-CFGWT\n' > "$EXTL/.git/config.worktree"; printf 'MARQUEUR-F1-EXCLUDE\n' >> "$EXTL/.git/info/exclude"
EXTP="$GEN/extp"; cp -R "$EXTL" "$EXTP"; G "$EXTP" gc -q 2> /dev/null   # dépôt empaqueté : packed-refs et objects/pack
LABG="$GEN/labg"; mkplan "$LABG"; G "$LABG" init -q -b main; G "$LABG" add -A; G "$LABG" commit -q -m "lab-base"; printf '%s\n' "$E1" > "$LABG/.git/refs/heads/main"   # main désigne un objet que seul le dépôt extérieur porte
FAN="${E1:0:2}"
cat > "$WORK/lire.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
const [, , scripts, lab] = process.argv;
const { lireGit } = await import(pathToFileURL(scripts + '/vf-cockpit-git.mjs').href);
const { gitSortant } = await import(pathToFileURL(scripts + '/vf-cockpit-git-sortant.mjs').href);
console.log(JSON.stringify({ sortant: gitSortant(lab), git: JSON.stringify(await lireGit(lab)) }));
JS
mesurer() { # mesurer <nom> <lab> : « sortant|nombre de marqueurs » (pages, graph.json, export, /api/vf/git)
  local L="$2" O="$2/.vibeflow/cockpit" R
  node "$SCRIPTS/vf-cockpit-build.mjs" "$L" --quiet > "$GEN/b-$1.out" 2>&1; node "$O/serve.mjs" --export "$GEN/x-$1.html" --include flows,notes,recent,health > "$GEN/e-$1.out" 2>&1
  R="$(node "$WORK/lire.mjs" "$SCRIPTS" "$L")"
  echo "$(printf '%s' "$R" | grep -o '"sortant":[a-z]*' | cut -d: -f2)|$(( $(printf '%s' "$R" | grep -o 'MARQUEUR-F1' | wc -l) + $(compte 'MARQUEUR-F1' "$O/project.html" "$O/index.html" "$O/graph.json" "$O/architecture.json" "$GEN/x-$1.html") ))"
}
fabriquer() { # fabriquer <membre relatif à .git> <dépôt source> : lab dont ce membre est un lien vers le même membre du dépôt source
  local nom="${1//\//_}" L="$GEN/lab-${1//\//_}"; rm -rf "$L"; cp -R "$LABG" "$L"
  mkdir -p "$(dirname "$L/.git/$1")"; rm -rf "$L/.git/$1"; ln -s "$2/.git/$1" "$L/.git/$1"; echo "$L"
}
NMEM=0; BADU=""; BADM=""
membre() { local L; L="$(fabriquer "$1" "$2")"; local R; R="$(mesurer "${1//\//_}" "$L")"; NMEM=$((NMEM+1)); [ "${R%%|*}" = "true" ] || BADU="$BADU $1"; [ "${R##*|}" = "0" ] || BADM="$BADM $1(${R##*|})"; }
for m in HEAD config index info shallow config.worktree objects refs objects/info refs/heads refs/tags refs/remotes refs/heads/main "objects/$FAN"; do
  src="$EXTL"; [ "$m" = "refs/heads/main" ] && { mkdir -p "$EXTL/.git/refs/heads"; cp "$EXTL/.git/refs/heads/MARQUEUR-F1-BRANCH" "$EXTL/.git/refs/heads/main"; }
  membre "$m" "$src"
done
membre packed-refs "$EXTP"; membre objects/pack "$EXTP"
# alternates et core.worktree étrangers (config puis config.worktree)
LA="$GEN/lab-alt"; rm -rf "$LA"; cp -R "$LABG" "$LA"; printf '%s\n' "$EXTL/.git/objects" > "$LA/.git/objects/info/alternates"
LC="$GEN/lab-cw"; rm -rf "$LC"; cp -R "$LABG" "$LC"; printf '[core]\n\tworktree = %s\n' "$EXTL" >> "$LC/.git/config"
LD="$GEN/lab-cwt"; rm -rf "$LD"; cp -R "$LABG" "$LD"; printf '[core]\n\tworktree = %s\n' "$EXTL" > "$LD/.git/config.worktree"
for pair in "alternates:$LA" "core.worktree:$LC" "config.worktree:$LD"; do
  R="$(mesurer "${pair%%:*}" "${pair#*:}")"; NMEM=$((NMEM+1)); [ "${R%%|*}" = "true" ] || BADU="$BADU ${pair%%:*}"; [ "${R##*|}" = "0" ] || BADM="$BADM ${pair%%:*}(${R##*|})"
done
# copie vendorisée (discover du moteur, dépôts imbriqués) : un dépôt imbriqué dont refs/ et objects/ sont des liens vers l'extérieur n'est pas lu à l'assemblage
LN="$GEN/lab-nested"; mkplan "$LN"; mkdir -p "$LN/sub5"; cp -R "$GEN/lab-objects/.git" "$LN/sub5/.git"; rm -rf "$LN/sub5/.git/refs"; ln -s "$EXTL/.git/refs" "$LN/sub5/.git/refs"; printf 'z\n' > "$LN/sub5/z.js"
node "$SCRIPTS/vf-cockpit-build.mjs" "$LN" --quiet > "$GEN/b-nested.out" 2>&1; ON="$LN/.vibeflow/cockpit"
assert_eq "G13d — dépôt imbriqué aux métadonnées liées vers l'extérieur : aucun marqueur dans les pages ni graph.json (copie vendorisée)" "$(compte 'MARQUEUR-F1' "$ON/project.html" "$ON/index.html" "$ON/graph.json" "$ON/architecture.json")" "0"
assert_eq "G13e — la copie du moteur (lib/vf-git-sortant.mjs) est octet pour octet celle du socle (une seule règle)" "$(cmp -s "$SCRIPTS/vf-cockpit-git-sortant.mjs" "$SCRIPTS/../skills/cockpit-moteur/scripts/lib/vf-git-sortant.mjs" && echo identique || echo differe)" "identique"
assert_ge "G13a — témoin : au moins dix-huit membres générés (la boucle n'est pas vide)" "$NMEM" 18
assert_eq "G13 — chaque membre lié vers l'extérieur : gitSortant refuse (rouge : liste des membres lus)" "${BADU:-aucun}" "aucun"
assert_eq "G13b — aucun marqueur du dépôt extérieur dans les pages, graph.json, l'export ni /api/vf/git (rouge : membres fuyants)" "${BADM:-aucun}" "aucun"
# témoins positifs : dépôt normal (cp du dépôt du lab), lab sous-module, worktree vérifié — le même pipeline lit leur branche
RN="$(node "$WORK/lire.mjs" "$SCRIPTS" "$L3")"; RS="$(node "$WORK/lire.mjs" "$SCRIPTS" "$PAR/sm")"; RW="$(node "$WORK/lire.mjs" "$SCRIPTS" "$WORK/vrai")"
assert_eq "G13c — témoins : dépôt normal, lab sous-module et worktree vérifié sont lus (branche vue, rien de refusé)" "$(printf '%s\n' "$RN" "$RS" "$RW" | grep -c '"sortant":false')|$(printf '%s' "$RN" | grep -c 'MARQUEUR-DANS-LE-LAB-BRANCH')|$(printf '%s' "$RS" | grep -c 'MARQUEUR-DANS-LE-LAB-SUBMOD')" "3|1|1"

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

# ---------- H : journal du lanceur et fichier d'état écrits dans la sortie du lab, jamais à travers un lien (AUDC-H3) ----------
echo "=== H — journal du lanceur ==="
LH="$WORK/lab-h"; mkplan "$LH"; SH="$LH/.vibeflow/cockpit"; mkdir -p "$SH/.cache"; printf '// serve factice\n' > "$SH/serve.mjs"
sleep 600 & SLP=$!
etat_h() { printf '{"pid":%s,"port":5000,"hash":"%s"}\n' "$SLP" "$1" > "$SH/.cache/server.json"; }
lancer_h() { node "$SCRIPTS/vf-cockpit.mjs" open --lab "$LH" --no-open > "$WORK/h.out" 2>&1; echo $?; }
LOGH="$SH/.cache/serveur.log"
etat_h abcdef012345; RC=$(lancer_h)
assert_eq "H0 — témoin positif : le journal normal s'écrit (relance, empreinte lue, une ligne datée)" "$(grep -c 'lanceur : relance : serveur PID '"$SLP"' remplacé (code du serveur changé, empreinte abcdef012345 -> ' "$LOGH")" "1"
assert_eq "H0b — le serveur du lab n'est pas reconnu (sleep) : sortie 5, rien d'arrêté" "$RC $(kill -0 "$SLP" 2>/dev/null && echo vivant || echo mort)" "5 vivant"
# lien symbolique vers un fichier extérieur, puis vers un fichier interne du lab : jamais suivi, jamais écrit
: > "$WORK/cible-ext.log"; : > "$SH/.cache/autre-interne.log"; rm -f "$LOGH"
ln -s "$WORK/cible-ext.log" "$LOGH"; etat_h abcdef012345; lancer_h > /dev/null
assert_eq "H1 — journal lié vers un fichier extérieur : la cible reste vide" "$(wc -c < "$WORK/cible-ext.log" | tr -d ' ')" "0"
rm -f "$LOGH"; ln -s "$SH/.cache/autre-interne.log" "$LOGH"; etat_h abcdef012345; lancer_h > /dev/null
assert_eq "H2 — journal lié vers un fichier interne du lab : la cible reste vide aussi" "$(wc -c < "$SH/.cache/autre-interne.log" | tr -d ' ')" "0"
assert_eq "H2b — le lien lui-même est resté un lien (non remplacé)" "$([ -L "$LOGH" ] && echo lien || echo autre)" "lien"
# valeur de server.json sans forme valide : jamais reprise dans une ligne, jamais de retour à la ligne injecté
rm -f "$LOGH"; printf '{"pid":%s,"port":5000,"hash":"zz\\nFORGE-LIGNE 1999-01-01 lanceur : arrêt"}\n' "$SLP" > "$SH/.cache/server.json"; lancer_h > /dev/null
assert_eq "H3 — hash illisible : aucun octet de sa valeur au journal" "$(grep -c 'FORGE' "$LOGH")" "0"
assert_eq "H3b — chaque ligne du journal commence par une date (aucune ligne injectée)" "$(grep -vc '^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}T' "$LOGH")" "0"
assert_eq "H3c — la relance est tout de même journalisée (hash illisible = code inconnu, serveur à remplacer)" "$(grep -c 'relance : serveur PID' "$LOGH")" "1"
kill "$SLP" 2>/dev/null; wait "$SLP" 2>/dev/null
# reprise d'un serveur orphelin : server.json écrit dans la sortie, jamais à travers un lien, et sans valeur sans forme
cat > "$WORK/orphelin.mjs" <<'JS'
import http from 'node:http'; import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [, , scripts, lab, hash] = process.argv;
const { serveurOrphelin } = await import(pathToFileURL(scripts + '/vf-cockpit-lanceur-verrou.mjs').href);
const srv = http.createServer((q, r) => { if (q.url === '/api/status') { r.end(JSON.stringify({ pid: process.pid, root: lab, hash })); } else r.end('<script>window.VF_COCKPIT_SERVER={"token":"abc123"}</script>'); });
await new Promise((ok) => srv.listen(0, '127.0.0.1', ok));
const sortie = path.join(lab, '.vibeflow', 'cockpit'); const etatFile = (s) => path.join(s, '.cache', 'server.json');
await serveurOrphelin(lab, sortie, srv.address().port, { estNotre: () => true, etatFile, adresseLocale: (p) => `http://127.0.0.1:${p}`, serveurVivant: () => null, noter: () => {} });
srv.close(); process.exit(0);
JS
LO="$WORK/lab-o"; mkplan "$LO"; SO="$LO/.vibeflow/cockpit"; mkdir -p "$SO/.cache"
node "$WORK/orphelin.mjs" "$SCRIPTS" "$LO" abcdef012345; J="$(cat "$SO/.cache/server.json" 2>/dev/null)"
assert_eq "H4 — témoin positif : un orphelin du lab repris, server.json écrit avec son empreinte" "$(printf '%s' "$J" | grep -c '"hash": "abcdef012345"')" "1"
rm -f "$SO/.cache/server.json"; : > "$WORK/etat-ext.json"; ln -s "$WORK/etat-ext.json" "$SO/.cache/server.json"
node "$WORK/orphelin.mjs" "$SCRIPTS" "$LO" abcdef012345
assert_eq "H5 — server.json lié vers un fichier extérieur : la cible reste vide" "$(wc -c < "$WORK/etat-ext.json" | tr -d ' ')" "0"
rm -f "$SO/.cache/server.json"; node "$WORK/orphelin.mjs" "$SCRIPTS" "$LO" 'zz
FORGE'
assert_eq "H6 — empreinte annoncée sans forme valide : aucun octet de sa valeur dans server.json" "$(grep -c 'FORGE' "$SO/.cache/server.json")" "0"
# H7-H9 : rien n'est modifié ni bloqué AVANT le contrôle du type et du nombre de liens ; aucun composant du chemin n'est un lien
printf 'PRECIEUX\n' > "$LO/precieux.txt"; rm -f "$SO/.cache/server.json"; ln "$LO/precieux.txt" "$SO/.cache/server.json"   # lien dur vers un fichier du lab
node "$WORK/orphelin.mjs" "$SCRIPTS" "$LO" abcdef012345
assert_eq "H7 — server.json à deux liens durs : le fichier lié n'est pas tronqué ni réécrit (refus avant toute troncature)" "$(cat "$LO/precieux.txt")" "PRECIEUX"
cat > "$WORK/noter.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
const [, , scripts, sortie] = process.argv;
const { noter } = await import(pathToFileURL(scripts + '/vf-cockpit-lanceur-verrou.mjs').href);
noter(sortie, 'essai'); process.exit(0);
JS
LF8="$WORK/lab-f8"; mkplan "$LF8"; SF8="$LF8/.vibeflow/cockpit"; mkdir -p "$SF8/.cache"; mkfifo "$SF8/.cache/serveur.log"   # tube nommé à la place du journal
node "$WORK/noter.mjs" "$SCRIPTS" "$SF8" > /dev/null 2>&1 & FP=$!
sleep 3; assert_eq "H8 — journal remplacé par un tube nommé : le lanceur n'est pas figé (il refuse et rend la main)" "$(kill -0 "$FP" 2>/dev/null && echo fige || echo libre)" "libre"
kill -9 "$FP" 2> /dev/null; wait "$FP" 2> /dev/null
LF9="$WORK/lab-f9"; mkplan "$LF9"; SF9="$LF9/.vibeflow/cockpit"; mkdir -p "$SF9" "$LF9/autre-dossier"; ln -s "$LF9/autre-dossier" "$SF9/.cache"   # .cache lié vers un dossier INTERNE du lab
node "$WORK/noter.mjs" "$SCRIPTS" "$SF9"
assert_eq "H9 — .cache lié vers un dossier interne du lab : rien n'y est écrit (aucun composant du chemin n'est un lien)" "$(ls "$LF9/autre-dossier" | wc -l | tr -d ' ')" "0"
LF10="$WORK/lab-f10"; mkplan "$LF10"; SF10="$LF10/.vibeflow/cockpit"; mkdir -p "$SF10/.cache"; node "$WORK/noter.mjs" "$SCRIPTS" "$SF10"
assert_eq "H10 — témoin positif : sans lien ni tube, le journal s'écrit" "$(grep -c 'lanceur : essai' "$SF10/.cache/serveur.log")" "1"

echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
