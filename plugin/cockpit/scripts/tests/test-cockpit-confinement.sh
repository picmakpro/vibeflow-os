#!/usr/bin/env bash
# test-cockpit-confinement.sh — confinement du lab et de l'export (lot 0 de l'audit du cockpit : AUDC-A-02, AUDC-B-01, AUDC-B-04).
#   A  un lien symbolique du lab vers l'extérieur n'est jamais suivi à l'assemblage : rien de sa cible dans les pages ni dans l'export (témoin positif : le même contenu, en fichier normal, y est)
#   B  un worktree déclaré mais non vérifié n'élargit pas la liste des arbres du lab (témoin positif : un vrai worktree y est)
#   D  l'export ne porte plus les clés vfTouch et vfGit (témoin positif : il garde les logos et l'onglet pour s'afficher)
#   GLOB  coût borné de la correspondance de motifs du moteur (79-21, SOCL-26) : équivalence à la copie gelée, croissance, plafonds, mutants
# Isolation git, aucun serveur ni navigateur. Exit 0 si tout passe, 1 sinon.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; SERVE_MODULE="$SCRIPTS/../skills/cockpit-moteur/assets/serve.mjs"   # 79-06 : l'export est celui du module, la sortie est son dernier argument
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"
cleanup() { if [ -n "${KEEP:-}" ]; then echo "WORK=$WORK"; else rm -rf "$WORK"; fi; }; trap cleanup EXIT
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [${2:0:300}]"; FAIL=$((FAIL+1)); fi; }
assert_ge() { if [ "${2:--1}" -ge "$3" ] 2>/dev/null; then echo "  ✅ PASS — $1 ($2 >= $3)"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (obtenu $2, attendu >= $3)"; FAIL=$((FAIL+1)); fi; }
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
node "$SERVE_MODULE" --export "$EXP" --include flows,notes,recent,health --sortie="$OUT" > "$WORK/export.out" 2>&1 || cat "$WORK/export.out"

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
  node "$SCRIPTS/vf-cockpit-build.mjs" "$L" --quiet > "$GEN/b-$1.out" 2>&1; node "$SERVE_MODULE" --export "$GEN/x-$1.html" --include flows,notes,recent,health --sortie="$O" > "$GEN/e-$1.out" 2>&1
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

# G14 : preuve générée depuis l'ÉNUMÉRATION d'un vrai dépôt (jamais une liste écrite à la main). Chaque chemin sous .git (fichier ou dossier ; échantillon d'au plus 200, au moins un par dossier)
# est remplacé, tour à tour, par un lien vers l'équivalent d'un dépôt extérieur : gitSortant doit refuser. Même chose en mode reftable si git le permet.
echo "=== G14 — énumération d'un vrai dépôt ==="
cat > "$WORK/enumerer.mjs" <<'JS'
import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [, , scripts, repo, ext, travail] = process.argv;
const { gitSortant } = await import(pathToFileURL(scripts + '/vf-cockpit-git-sortant.mjs').href);
const tous = [];
(function marche(d, rel) { for (const e of fs.readdirSync(d, { withFileTypes: true })) { if (e.isSymbolicLink()) continue; const r = rel ? rel + '/' + e.name : e.name; tous.push(r); if (e.isDirectory()) marche(path.join(d, e.name), r); } })(path.join(repo, '.git'), '');
let pris = tous;
if (tous.length > 200) { const vus = new Set(), un = new Set(); for (const r of tous) { const d = path.dirname(r); if (!vus.has(d)) { vus.add(d); un.add(r); } } const pas = Math.ceil(tous.length / (200 - un.size)); tous.forEach((r, i) => { if (i % pas === 0) un.add(r); }); pris = [...un]; }
const faux = []; const lab = path.join(travail, 'lab');
const temoin = gitSortant(repo);
for (const r of pris) {
  fs.rmSync(lab, { recursive: true, force: true }); fs.cpSync(repo, lab, { recursive: true, verbatimSymlinks: true });
  fs.rmSync(path.join(lab, '.git', r), { recursive: true, force: true }); fs.symlinkSync(path.join(ext, '.git', r), path.join(lab, '.git', r));
  if (!gitSortant(lab)) faux.push(r);
}
fs.rmSync(lab, { recursive: true, force: true });
const a = (re) => pris.some((r) => re.test(r));
console.log(JSON.stringify({ total: tous.length, essais: pris.length, temoin, faux, couvre: { worktree: a(/^worktrees\/[^/]+\/HEAD$/), logs: a(/^logs\//), tags: a(/^(refs\/tags\/|packed-refs$)/), reftable: a(/^reftable\/.+\.ref$/), pack: a(/^objects\/pack\/.+\.(pack|idx)$/) } }));
JS
mkenum() { # mkenum <dossier> [options init] : un vrai dépôt (commits, tags, stash, branche, worktree enregistré, refs empaquetées, paquet)
  local R="$1"; shift; mkdir -p "$R"; G "$R" init -q -b main "$@"; for i in 1 2 3; do printf 'v%s\n' "$i" > "$R/f$i.txt"; G "$R" add -A; G "$R" commit -q -m "c$i"; done
  G "$R" tag legere; G "$R" tag -a annotee -m "a"; G "$R" branch b2; printf 'sale\n' >> "$R/f1.txt"; G "$R" stash -q; G "$R" worktree add -q "$R-wt" -b bw 2> /dev/null
  G "$R" remote add origin https://exemple.invalid/x.git; G "$R" pack-refs --all 2> /dev/null; G "$R" branch b3; G "$R" repack -q -d 2> /dev/null; return 0; }
mkenum "$GEN/reel"; RES14="$(node "$WORK/enumerer.mjs" "$SCRIPTS" "$GEN/reel" "$EXTL" "$GEN/trav")"
assert_ge "G14a — témoin : l'énumération porte au moins quarante chemins et l'échantillon au moins quarante essais" "$(printf '%s' "$RES14" | node -e "let s='';process.stdin.on('data',c=>s+=c).on('end',()=>{const j=JSON.parse(s);console.log(j.total>=40&&j.essais>=40?j.essais:0)})")" 40
assert_eq "G14a2 — témoin : l'échantillon couvre worktrees/<id>/HEAD, logs, tags et paquets" "$(printf '%s' "$RES14" | node -e "let s='';process.stdin.on('data',c=>s+=c).on('end',()=>{const c=JSON.parse(s).couvre;console.log([c.worktree,c.logs,c.tags,c.pack].join())})")" "true,true,true,true"
assert_eq "G14 — chaque chemin énuméré sous .git remplacé par un lien vers l'extérieur : gitSortant refuse (rouge : chemins lus à tort) ; témoin : le dépôt réel est lu" "$(printf '%s' "$RES14" | node -e "let s='';process.stdin.on('data',c=>s+=c).on('end',()=>{const j=JSON.parse(s);console.log((j.temoin===false?'lu':'refuse')+' '+(j.faux.length?j.faux.join(','):'aucun'))})")" "lu aucun"
echo "  ($(printf '%s' "$RES14" | node -e "let s='';process.stdin.on('data',c=>s+=c).on('end',()=>{const j=JSON.parse(s);console.log(j.total+' chemins énumérés, '+j.essais+' essais')})"))"
if G "$WORK" init -q --ref-format=reftable "$GEN/rt-essai" 2> /dev/null; then
  mkenum "$GEN/reft" --ref-format=reftable; RT="$(node "$WORK/enumerer.mjs" "$SCRIPTS" "$GEN/reft" "$EXTL" "$GEN/trav")"
  assert_eq "G14b0 — témoin : l'échantillon reftable couvre les tables (*.ref)" "$(printf '%s' "$RT" | node -e "let s='';process.stdin.on('data',c=>s+=c).on('end',()=>console.log(JSON.parse(s).couvre.reftable))")" "true"
  assert_eq "G14b — mode reftable : chaque chemin énuméré remplacé par un lien vers l'extérieur est refusé ; témoin : le dépôt reftable est lu" "$(printf '%s' "$RT" | node -e "let s='';process.stdin.on('data',c=>s+=c).on('end',()=>{const j=JSON.parse(s);console.log((j.temoin===false?'lu':'refuse')+' '+(j.faux.length?j.faux.join(','):'aucun')+' '+(j.total>=20?'assez':'peu'))})")" "lu aucun assez"
else echo "  (git de ce poste sans reftable : G14b non joué)"; fi
# témoin : un lien dont la cible reste DANS le dossier git (le verrou de pilotage .git/vf-driver/…/DRIVER.lock) ne fait rien lire d'extérieur : le dépôt reste lu
LV="$GEN/lab-verrou"; rm -rf "$LV"; cp -R "$GEN/reel" "$LV"; mkdir -p "$LV/.git/vf-driver/ws"; : > "$LV/.git/vf-driver/ws/DRIVER.lock.gen.1"; ln -s DRIVER.lock.gen.1 "$LV/.git/vf-driver/ws/DRIVER.lock"
LX="$GEN/lab-verrou-ext"; rm -rf "$LX"; cp -R "$GEN/reel" "$LX"; mkdir -p "$LX/.git/vf-driver"; ln -s "$EXTL/.git/HEAD" "$LX/.git/vf-driver/DRIVER.lock"
printf '%s\n' "$(node "$WORK/sortant.mjs" "$SCRIPTS" "$LV" "$LX")" > "$WORK/verrou.txt"
assert_eq "G14c — lien relatif vers un voisin du dossier git (verrou de pilotage) : lu ; lien vers l'extérieur au même endroit : refusé" "$(cat "$WORK/verrou.txt")" "false,true"
# inclusions de configuration : un fichier hors du lab et du dossier git est refusé (include, includeIf, inclusion en chaîne) ; un fichier du lab est permis (témoin)
printf '[remote "origin"]\n\turl = https://MARQUEUR-F1-REMOTE.invalid/inc.git\n' > "$GEN/inclus-ext.cfg"; printf '[include]\n\tpath = %s\n' "$GEN/inclus-ext.cfg" > "$GEN/relais-ext.cfg"
for v in a b c d; do rm -rf "$GEN/lab-inc-$v"; cp -R "$GEN/reel" "$GEN/lab-inc-$v"; done
printf '[include]\n\tpath = %s\n' "$GEN/inclus-ext.cfg" >> "$GEN/lab-inc-a/.git/config"
printf '[includeIf "gitdir:**"]\n\tpath = %s\n' "$GEN/inclus-ext.cfg" >> "$GEN/lab-inc-b/.git/config"
printf '[include]\n\tpath = relais.cfg\n' >> "$GEN/lab-inc-c/.git/config"; cp "$GEN/relais-ext.cfg" "$GEN/lab-inc-c/.git/relais.cfg"
printf '[color]\n\tui = auto\n' > "$GEN/lab-inc-d/inclus-lab.cfg"; printf '[include]\n\tpath = %s\n' "$GEN/lab-inc-d/inclus-lab.cfg" >> "$GEN/lab-inc-d/.git/config"
assert_eq "G15 — include.path, includeIf et inclusion en chaîne vers un fichier hors du lab : refusés ; témoin : inclusion d'un fichier du lab : lue" "$(node "$WORK/sortant.mjs" "$SCRIPTS" "$GEN/lab-inc-a" "$GEN/lab-inc-b" "$GEN/lab-inc-c" "$GEN/lab-inc-d")" "true,true,true,false"
RI="$(mesurer "include" "$GEN/lab-inc-a")"
assert_eq "G15b — include.path extérieur : aucun marqueur (remote.origin.url extérieure) dans les pages, graph.json, l'export ni /api/vf/git" "${RI##*|}" "0"

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

# ---------- GLOB : coût borné de la correspondance de motifs (79-21, P79-D-32, SOCL-26) ----------
# Aucun serveur, aucun navigateur : scripts d'aide en heredoc dans $GL_AUX ; copie gelée de l'ancienne implémentation, équivalence générative à graine,
# banc de croissance validé sur témoin, plafonds nommés. Variables VF_GLOB_GRAINE (entier ou alea), VF_GLOB_N (nombre de motifs), VF_GLOB_FAMILLES.
GL_LIB="$(cd "$SCRIPTS/../skills/cockpit-moteur/scripts/lib" && pwd -P)"; GL_AUX="$WORK/gl"; mkdir -p "$GL_AUX"
GL_GRAINE_DEFAUT=79210101; GL_GRAINE="${VF_GLOB_GRAINE:-$GL_GRAINE_DEFAUT}"; [ "$GL_GRAINE" = alea ] && GL_GRAINE="$(date +%s)"; GL_N="${VF_GLOB_N:-4000}"
cat > "$GL_AUX/ancien.mjs" <<'JS'
// copie gelée de la base, ne se modifie jamais ; toute retouche est une décision de plan (79-21).
export const toPosix = (p) => p.replace(/\\/g, '/');
const GLOB_CHARS = /[*?{[]/;

export function globToRegExp(glob) {
  const g = toPosix(glob).replace(/^\.\//, '').replace(/\/$/, '');
  let re = '';
  let braces = 0;
  for (let i = 0; i < g.length; ) {
    const c = g[i];
    if (c === '*') {
      if (g[i + 1] === '*') {
        const atStart = i === 0 || g[i - 1] === '/';
        const atEnd = i + 2 === g.length || g[i + 2] === '/';
        if (atStart && atEnd) {
          if (i + 2 === g.length) { re += '.*'; i += 2; }
          else { re += '(?:.*/)?'; i += 3; }
          continue;
        }
        re += '.*'; i += 2; continue;
      }
      re += '[^/]*'; i++; continue;
    }
    if (c === '?') { re += '[^/]'; i++; continue; }
    if (c === '{') { braces++; re += '(?:'; i++; continue; }
    if (c === '}' && braces) { braces--; re += ')'; i++; continue; }
    if (c === ',' && braces) { re += '|'; i++; continue; }
    // a whole segment like [id], [...slug] or [[...slug]] is a folder name (Next.js, SvelteKit), not a character class
    if (c === '[' && (i === 0 || g[i - 1] === '/')) {
      const end = g.indexOf('/', i) < 0 ? g.length : g.indexOf('/', i);
      const seg = g.slice(i, end);
      if (/^\[\[?(\.\.\.)?[A-Za-z_$][\w$-]*\]\]?$/.test(seg)) { re += seg.replace(/[.[\]$\\]/g, '\\$&'); i = end; continue; }
    }
    if (c === '[') {
      const j = g.indexOf(']', i + 1);
      if (j > i) { re += '[' + g.slice(i + 1, j).replace(/^!/, '^').replace(/\\/g, '\\\\') + ']'; i = j + 1; continue; }
    }
    re += c.replace(/[.+^$()|\\\]]/g, '\\$&');
    i++;
  }
  return new RegExp('^' + re + '$');
}

/** Compile a glob. A pattern with no wildcards also matches everything under it as a directory. */
export function compileGlob(glob) {
  const g = toPosix(glob).replace(/^\.\//, '').replace(/\/$/, '');
  const literalPrefix = g.split(GLOB_CHARS)[0];
  if (!GLOB_CHARS.test(g)) {
    return { glob, specificity: g.length, test: (p) => p === g || p.startsWith(g + '/') };
  }
  // A glob that names directories (src/components/{a,b}) also matches everything beneath them.
  const re = globToRegExp(g);
  const under = globToRegExp(g + '/**');
  return { glob, specificity: literalPrefix.length, test: (p) => re.test(p) || under.test(p) };
}

export const source = (g) => globToRegExp(g).source;
JS
cat > "$GL_AUX/equiv.mjs" <<'JS'
// equiv.mjs <dossier lib> <copie gelée> <mode> <graine> <n> — équivalence de compileGlob contre la copie gelée de la base (79-21).
// Modes : couverture, equiv, invalides, nonchaines. Sortie : une ligne de verdict (la première contre-preuve, jamais plus de 300 caractères).
import { pathToFileURL } from 'node:url';
const [, , lib, gele, mode, graineArg, nArg] = process.argv;
const vieux = await import(pathToFileURL(gele).href);
const neuf = await import(pathToFileURL(lib + '/common.mjs').href);
const GRAINE = Number(graineArg), N = Number(nArg);
function mulberry32(a) { return () => { a |= 0; a = (a + 0x6d2b79f5) | 0; let t = Math.imul(a ^ (a >>> 15), 1 | a); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; };
const rnd = mulberry32(GRAINE);
const pick = (a) => a[Math.floor(rnd() * a.length)];
const chance = (p) => rnd() < p;
const esc = (s) => JSON.stringify(s);
const CAR = ['a', 'b', 'c', 'é', '-'];
const mot = () => { let s = ''; const n = Math.floor(rnd() * 4); for (let i = 0; i < n; i++) s += pick(CAR); return s; };
const motSlash = () => { let s = ''; const n = Math.floor(rnd() * 4); for (let i = 0; i < n; i++) s += chance(0.3) ? '/' : pick(CAR); return s; };
// jetons : { t: texte, k: classes, i: instanciation (chemin qui devrait correspondre) }
const lit = (t, k = []) => ({ t, k, i: () => t });
const arme = (t) => t.replace(/\*\*/g, () => motSlash()).replace(/\*/g, () => mot());
const acc = (arms, k) => ({ t: arms.t, k: ['accolades', ...k], i: () => arme(pick(arms.a)) });
const JOKERS = [
  { t: '*', k: ['etoile'], i: () => mot() }, { t: '**', k: ['dbl-isole', 'dbl'], i: () => motSlash() }, { t: '?', k: ['joker-point'], i: () => pick(CAR) },
  { t: '**/', k: ['dbl', 'dbl-isole'], i: () => (chance(0.5) ? '' : motSlash() + '/') }, { t: '/**', k: ['dbl', 'dbl-isole'], i: () => (chance(0.5) ? '' : '/' + motSlash()) },
];
const ACCOLADES = [
  acc({ t: '{a,b}', a: ['a', 'b'] }, []), acc({ t: '{a,b/c}', a: ['a', 'b/c'] }, []), acc({ t: '{a*,b}', a: ['a*', 'b'] }, []),
  acc({ t: '{*,**}', a: ['*', '**'] }, ['dbl']), acc({ t: '{a,{b,c}}', a: ['a', 'b', 'c'] }, ['accolades-imbriquees']),
];
const CLASSES = [
  { t: '[abc]', k: ['classe'], i: () => (chance(0.33) ? pick(['d', 'x', 'é']) : pick(['a', 'b', 'c'])) },
  { t: '[!a]', k: ['classe', 'classe-niee'], i: () => (chance(0.33) ? 'a' : pick(['b', 'c', 'é'])) },
  { t: '[a-c]', k: ['classe'], i: () => (chance(0.33) ? 'd' : pick(['a', 'b', 'c'])) },
];
const DYN = [
  { t: '[id]', k: ['dynamique'], i: () => (chance(0.5) ? '[id]' : mot() || 'z') }, { t: '[...slug]', k: ['dynamique'], i: () => (chance(0.5) ? '[...slug]' : mot() || 'z') },
  { t: '[[...slug]]', k: ['dynamique'], i: () => (chance(0.5) ? '[[...slug]]' : mot() || 'z') },
];
const SPECIAUX = ['.', '(', ')', '|', '+', '^', '$'].map((t) => lit(t, ['special']));
const LITS = ['a', 'b', 'c', 'é', '.', '-', ','].map((t) => lit(t, t === '.' ? ['special'] : []));
const SLASH = lit('/');
const DBL = [JOKERS[1], JOKERS[3], JOKERS[4]];
function jeton() {
  const r = rnd();
  if (r < 0.3) return pick(LITS);
  if (r < 0.45) return SLASH;
  if (r < 0.65) return pick(JOKERS);
  if (r < 0.75) return pick(ACCOLADES);
  if (r < 0.82) return pick(CLASSES);
  if (r < 0.87) return pick(DYN);
  return pick(SPECIAUX);
}
function motif() {
  const m = rnd();
  let js = [];
  if (m < 0.1) { const n = 1 + Math.floor(rnd() * 5); for (let i = 0; i < n; i++) js.push(chance(0.2) ? SLASH : pick([...LITS.slice(0, 5), ...SPECIAUX])); }
  else if (m < 0.2) { const n = 3 + Math.floor(rnd() * 2); for (let i = 0; i < n; i++) { js.push(pick(DBL)); js.push(pick(LITS.slice(0, 3))); js.push(SLASH); } }
  else { const n = 1 + Math.floor(rnd() * 7); for (let i = 0; i < n; i++) js.push(jeton()); }
  let t = js.map((j) => j.t).join('');
  const k = new Set(js.flatMap((j) => j.k));
  const joker = js.some((j) => /[*?{[]/.test(j.t));
  if (!joker) k.add('sans-joker');
  if (js.filter((j) => j.t.includes('**') || j === JOKERS[1]).length >= 3) k.add('trois-dbl');
  if (chance(0.25)) { t = './' + t; k.add('point-barre'); }
  if (chance(0.25)) { t += '/'; k.add('barre-finale'); }
  if (chance(0.06)) { t = t.replace(/\//g, '\\'); }
  return { t, k, js };
}
const PIECES = ['a', 'b', 'c', '/', '.js', 'é', '-', ',', '\n', '\r', '(', '|', '$', 'id'];
function chemins(m) {
  const out = [];
  for (let n = 0; n < 4; n++) {
    let p = m.js.map((j) => j.i()).join('');
    if (m.t.startsWith('./') || m.t.includes('\\')) p = p.replace(/\\/g, '/');
    if (chance(0.25)) { const r = Math.floor(rnd() * 4); if (r === 0) p += 'x'; else if (r === 1) p += '/'; else if (r === 2) p += '/z'; else if (p.length) { const q = Math.floor(rnd() * p.length); p = p.slice(0, q) + pick(['x', 'q', '/']) + p.slice(q + 1); } }
    out.push(p);
  }
  for (let n = 0; n < 4; n++) { let p = ''; const c = Math.floor(rnd() * 9); for (let i = 0; i < c; i++) p += pick(PIECES); out.push(p); }
  return out;
}
const tente = (f, g) => { try { return { v: f(g) }; } catch (e) { return { e: e.name + ': ' + e.message }; } };
const court = (s) => (s.length > 290 ? s.slice(0, 290) + '…' : s);
const verdict = (c, p) => { try { return String(c.test(p)); } catch (e) { return 'levée ' + e.name; } };
// première divergence d'une paire (motif, chemins), ou null
function ecart(g, ps) {
  const o = tente(vieux.compileGlob, g), n = tente(neuf.compileGlob, g);
  if (o.e !== undefined || n.e !== undefined) return o.e === n.e ? null : `graine=${GRAINE} motif=${esc(g)} message : attendu ${esc(o.e)} obtenu ${esc(n.e)}`;
  for (const champ of ['glob', 'specificity']) if (o.v[champ] !== n.v[champ]) return `graine=${GRAINE} motif=${esc(g)} champ ${champ} : attendu ${esc(o.v[champ])} obtenu ${esc(n.v[champ])}`;
  for (const p of ps) { const a = verdict(o.v, p), b = verdict(n.v, p); if (a !== b) return `graine=${GRAINE} motif=${esc(g)} chemin=${esc(p)} verdict : attendu ${a} obtenu ${b}`; }
  return null;
}
if (mode === 'couverture' || mode === 'equiv') {
  const cls = {};
  for (let i = 0; i < N; i++) {
    const m = motif(); const ps = chemins(m);
    if (mode === 'equiv') { const e = ecart(m.t, ps); if (e) { console.log(court(e)); process.exit(0); } continue; }
    const o = tente(vieux.compileGlob, m.t);
    for (const c of m.k) {
      const s = (cls[c] ||= { m: 0, oui: 0, non: 0 }); s.m++;
      if (o.v) for (const p of ps) { if (o.v.test(p)) s.oui++; else s.non++; }
    }
  }
  if (mode === 'equiv') console.log('identique');
  else {
    const tous = ['sans-joker', 'etoile', 'dbl-isole', 'joker-point', 'accolades', 'accolades-imbriquees', 'classe', 'classe-niee', 'dynamique', 'point-barre', 'barre-finale', 'trois-dbl', 'special'];
    const bas = tous.filter((c) => !cls[c] || cls[c].m < 150 || cls[c].oui < 20 || cls[c].non < 20);
    console.log(`graine=${GRAINE} motifs=${N} classes : ${tous.map((c) => `${c}=${cls[c]?.m ?? 0}/${cls[c]?.oui ?? 0}/${cls[c]?.non ?? 0}`).join(' ')}`);
    console.log(bas.length ? 'sous le minimum : ' + bas.join(' ') : 'complète');
  }
} else if (mode === 'nonchaines') {
  const motifs = ['*', '**', 'u*', '**/undefined', '{null,undefined}', '1?', '**/12', '?2', 'n*l', '*/*', '{a,b}', '[0-9]*', '**/[a-z]*', '.', '[object Object]', '**/object*', 'a/**', '{1,2}?', 'tr??', 'tr*e'];
  const sym = Symbol('s');
  const entrees = [undefined, null, 12, true, false, {}, [], ['a/b'], { toString() { return 'a/b'; } }, 0, -1, 1.5, 12n, sym, new String('abc')];
  let r = 'identique';
  fin: for (const g of motifs) {
    const o = tente(vieux.compileGlob, g), n = tente(neuf.compileGlob, g);
    for (const x of entrees) {
      const f = (c) => { try { return String(c.v.test(x)); } catch (e) { return 'levée ' + e.name; } };
      const a = f(o), b = f(n);
      if (a !== b) { r = court(`motif=${esc(g)} entrée=${typeof x === 'symbol' ? 'Symbol' : esc(String(x))} attendu ${a} obtenu ${b}`); break fin; }
    }
  }
  console.log(r);
} else if (mode === 'invalides') {
  const ERR = ['[', '{', '}', ',', ']'];
  const alpha = [...LITS, ...SPECIAUX, SLASH, ...JOKERS, ...CLASSES, ...DYN, ...ACCOLADES];
  // alternative de niveau supérieur dans une source de regex : barre verticale hors de tout groupe, hors classe, échappements sautés
  const hautNiveau = (s) => { let d = 0; for (let i = 0; i < s.length; i++) { const c = s[i]; if (c === '\\') { i++; continue; } if (c === '[') { i++; while (i < s.length && s[i] !== ']') { if (s[i] === '\\') i++; i++; } continue; } if (c === '(') d++; else if (c === ')') d--; else if (c === '|' && d === 0) return true; } return false; };
  const n3 = { leve: 0, haut: 0, autre: 0 };
  const fixes = [['a[{/*.js,/', 'zz/']];
  const biais = () => { const f = pick([() => '[', () => '{', () => '}', () => ',', () => ']']); return f(); };
  const motsInvalides = [];
  for (const [g] of fixes) motsInvalides.push(g);
  for (let i = 0; i < N; i++) {
    let g = '';
    if (chance(0.3)) g = pick(['a', '', 'b/']) + '[' + pick(['', 'a', '/']) + '{' + pick(['/', 'a/', '']) + pick(['*', '?', '**']) + pick(['.js', '', 'b']) + ',' + pick(['/', 'a', '']);
    else { const n = 1 + Math.floor(rnd() * 6); for (let j = 0; j < n; j++) g += chance(0.4) ? pick(ERR) : pick(alpha).t; }
    motsInvalides.push(g);
  }
  const res = { leve: 'identique', haut: 'identique', autre: 'identique' };
  const note = (k, m) => { if (res[k] === 'identique') res[k] = court(m); };
  for (const g of motsInvalides) {
    const o = tente(vieux.compileGlob, g);
    const ps = [...(g === fixes[0][0] ? [fixes[0][1]] : []), ...chemins({ t: g, js: [] }), 'a/b', 'a', '/', 'zz/', 'a/zz', 'a{/x.js', 'a[{/x.js,/'];
    if (o.e !== undefined) {
      n3.leve++;
      const n = tente(neuf.compileGlob, g);
      if (n.e !== o.e) note('leve', `graine=${GRAINE} motif=${esc(g)} message : attendu ${esc(o.e)} obtenu ${esc(n.e)}`);
      continue;
    }
    const haut = hautNiveau(vieux.source(g)) || hautNiveau(vieux.source(g + '/**'));
    const n = tente(neuf.compileGlob, g);
    if (n.e !== undefined) { note(haut ? 'haut' : 'autre', `graine=${GRAINE} motif=${esc(g)} levée neuve : ${esc(n.e)}`); continue; }
    if (haut) {
      n3.haut++;
      const mauvais = ps.find((p) => n.v.test(p));
      if (mauvais !== undefined) note('haut', `graine=${GRAINE} motif=${esc(g)} chemin=${esc(mauvais)} verdict : attendu false obtenu true (alternative de niveau supérieur)`);
      continue;
    }
    n3.autre++;
    const e = ecart(g, ps);
    if (e) note('autre', e);
  }
  if (n3.leve < 100) note('leve', `couverture insuffisante levées=${n3.leve}`);
  if (n3.haut < 10) note('haut', `couverture insuffisante niveau-supérieur=${n3.haut}`);
  if (n3.autre < 100) note('autre', `couverture insuffisante autres=${n3.autre}`);
  console.log(`leve: ${res.leve}`); console.log(`haut: ${res.haut}`); console.log(`autre: ${res.autre}`);
  console.log(`compteurs: levées=${n3.leve} niveau-supérieur=${n3.haut} autres=${n3.autre}`);
}
JS
cat > "$GL_AUX/perf.mjs" <<'JS'
// perf.mjs — croissance du coût de compileGlob (79-21). Modes : mesure <lib> <F> <N>, pilote <lib> <F>, banc.
// Les motifs, unités de répétition, tailles et jumeaux positifs des cinq familles vivent ICI et nulle part ailleurs.
import { pathToFileURL } from 'node:url';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
const [, , mode, a1, a2, a3] = process.argv;
const FAMILLES = {
  F1: { motif: '**/a/**/a/**/a/*.js', unite: 'a/', taille: 280, jumeau: 'a/a/a/x.js' },
  F2: { motif: '**/a/**/a/**/a/**/a/*.js', unite: 'a/', taille: 100, jumeau: 'a/a/a/a/x.js' },
  F3: { motif: '**/**/a/**/**/a/*.js', unite: 'a/', taille: 100, jumeau: 'a/a/x.js' },
  F4: { motif: '**/{a,a/a}/**/{a,a/a}/**/{a,a/a}/*.js', unite: 'a/', taille: 150, jumeau: 'a/a/a/x.js' },
  F5: { motif: 'a**a**a**a**b', unite: 'a', taille: 130, jumeau: 'aaaab' },
};
const chemin = (f, n) => (f.unite.repeat(n));
const mediane = (v) => [...v].sort((x, y) => x - y)[Math.floor(v.length / 2)];
const ns = () => process.hrtime.bigint();
// procédure commune : échauffement, lots d'au moins 20 ms, trois essais entrelacés (N, 2N, N, 2N…), médiane par taille ; ms par appel
function procedure(appelN, appel2N, petit) {
  let sink = 0;
  for (let i = 0; i < 3; i++) sink += petit() ? 1 : 0;
  sink += appelN() ? 1 : 0; sink += appel2N() ? 1 : 0;
  const calibre = (f) => { let r = 1; for (;;) { const t0 = ns(); for (let i = 0; i < r; i++) sink += f() ? 1 : 0; const d = Number(ns() - t0) / 1e6; if (d >= 20 || r >= 1 << 22) return r; r *= 2; } };
  const R1 = calibre(appelN), R2 = calibre(appel2N);
  const lot = (f, r) => { const t0 = ns(); for (let i = 0; i < r; i++) sink += f() ? 1 : 0; return Number(ns() - t0) / 1e6 / r; };
  const e1 = [], e2 = [];
  for (let k = 0; k < 3; k++) { e1.push(lot(appelN, R1)); e2.push(lot(appel2N, R2)); }
  if (sink < 0) console.error('x');
  return { t1: mediane(e1), t2: mediane(e2) };
}
if (mode === 'mesure') {
  const f = FAMILLES[a2]; const N = Number(a3);
  const { compileGlob } = await import(pathToFileURL(a1 + '/common.mjs').href);
  const c = compileGlob(f.motif);
  const p1 = chemin(f, N), p2 = chemin(f, 2 * N);
  if (c.test(p2) !== false) { console.log(JSON.stringify({ forme: 'le chemin mesuré correspond' })); process.exit(0); }
  console.log(JSON.stringify(procedure(() => c.test(p1), () => c.test(p2), () => c.test(chemin(f, Math.max(1, N >> 2))))));
} else if (mode === 'jumeau') {
  const { compileGlob } = await import(pathToFileURL(a1 + '/common.mjs').href);
  const f = FAMILLES[a2];
  const c = compileGlob(f.motif);
  console.log(c.test(f.jumeau) === true && c.test(chemin(f, FAMILLES[a2].taille)) === false ? 'ok' : 'forme');
} else if (mode === 'pilote') {
  const lib = a1; const selection = (process.env.VF_GLOB_FAMILLES || 'F1 F2 F3 F4 F5').split(/\s+/).filter(Boolean);
  const moi = fileURLToPath(import.meta.url);
  for (const nom of selection) {
    if (a2 && a2 !== nom) continue;
    const f = FAMILLES[nom];
    let meilleur = null, delai = false, forme = null;
    for (let s = 0; s < 3; s++) {
      let sortie;
      try { sortie = JSON.parse(execFileSync(process.execPath, [moi, 'mesure', lib, nom, String(f.taille)], { timeout: 20000, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] })); }
      catch (e) { if (e.code === 'ETIMEDOUT' || e.signal) { delai = true; break; } forme = 'échec ' + e.message.slice(0, 80); break; }
      if (sortie.forme) { forme = sortie.forme; break; }
      if (!meilleur || sortie.t2 / Math.max(sortie.t1, 1e-9) < meilleur.t2 / Math.max(meilleur.t1, 1e-9)) meilleur = sortie;
      if (sortie.t2 <= 2.5 * sortie.t1 + 1) break;
    }
    const fmt = (x) => x.toFixed(3);
    if (forme) console.log(`${nom} ratio=forme(${forme}) plafond=forme`);
    else if (delai && !meilleur) console.log(`${nom} ratio=délai plafond=délai`);
    else {
      const r = meilleur.t2 / Math.max(meilleur.t1, 1e-9);
      const rok = meilleur.t2 <= 2.5 * meilleur.t1 + 1;
      console.log(`${nom} ratio=${rok ? 'ok' : `rouge t1=${fmt(meilleur.t1)}ms t2=${fmt(meilleur.t2)}ms rapport=${r.toFixed(2)}`}${delai ? ' (délai)' : ''} plafond=${meilleur.t2 <= 250 ? 'ok' : `rouge t2=${fmt(meilleur.t2)}ms`}`);
    }
  }
} else if (mode === 'banc') {
  // deux fonctions de référence, mêmes procédure et critère : une linéaire, une quadratique ; chacune consomme son résultat
  const lin = (n) => () => { let s = 0; for (let i = 0; i < n; i++) s += (i * 7) ^ (s >>> 3); return s > 0; };
  const quad = (n) => () => { let s = 0; for (let i = 0; i < n; i++) for (let j = 0; j < n; j++) s += (i ^ j) & 3; return s > 0; };
  const serie = (g, n) => { const r = []; for (let k = 0; k < 3; k++) { const m = procedure(g(n), g(2 * n), g(n >> 2)); r.push(m); } return r; };
  const meilleurRapport = (rs) => Math.min(...rs.map((m) => m.t2 / Math.max(m.t1, 1e-9)));
  const critere = (rs) => rs.some((m) => m.t2 <= 2.5 * m.t1 + 1);
  const rl = serie(lin, 4000000), rq = serie(quad, 2500);
  console.log(`lineaire=${critere(rl) ? 'laisse-passer' : 'rouge'} quadratique=${meilleurRapport(rq) >= 3.2 ? 'vu' : 'aveugle'} (rapports ${meilleurRapport(rl).toFixed(2)} ${meilleurRapport(rq).toFixed(2)})`);
}
JS
cat > "$GL_AUX/plafonds.mjs" <<'JS'
// plafonds.mjs <dossier lib> <C0..C4> — plafonds nommés de la correspondance de motifs (79-21). Tailles dérivées des constantes exportées.
// Sortie : « ok » ou une phrase d'échec ; jamais d'exception qui interrompt la suite.
import { pathToFileURL } from 'node:url';
const [, , lib, cas] = process.argv;
const ms = (f) => { const t0 = process.hrtime.bigint(); const r = f(); return [r, Number(process.hrtime.bigint() - t0) / 1e6]; };
if (cas === 'C4') {
  const { compileGlob } = await import(pathToFileURL(lib + '/common.mjs').href);
  const m = '{'.repeat(500) + 'a' + '}'.repeat(500);
  try { const c = compileGlob(m); console.log(c.test('a') === true && c.test('b') === false ? 'ok' : 'échec : verdict'); } catch (e) { console.log('échec : ' + e.name); }
  process.exit(0);
}
let g;
try { g = await import(pathToFileURL(lib + '/vf-glob.mjs').href); } catch (e) { console.log('échec : module de correspondance absent ou illisible (' + e.code + ')'); process.exit(0); }
const { MAX_MOTIF, MAX_PAS, automateDe } = g;
if (cas === 'C0') {
  const entier = (x) => Number.isInteger(x);
  console.log(entier(MAX_MOTIF) && MAX_MOTIF >= 256 && MAX_MOTIF <= 4096 && entier(MAX_PAS) && MAX_PAS >= 1000000 && MAX_PAS <= 10000000 && typeof automateDe === 'function' ? 'ok' : `échec : constantes ${MAX_MOTIF} ${MAX_PAS} ${typeof automateDe}`);
  process.exit(0);
}
if (!Number.isInteger(MAX_MOTIF) || !Number.isInteger(MAX_PAS)) { console.log('échec : constantes absentes'); process.exit(0); }
const { compileGlob } = await import(pathToFileURL(lib + '/common.mjs').href);
if (cas === 'C1') {
  const c = compileGlob('a/**'); const p = 'a/' + 'x'.repeat(MAX_PAS - 2);
  const [v, t] = ms(() => c.test(p));
  console.log(v === false && t < 250 ? 'ok' : `échec : verdict ${v} en ${t.toFixed(1)} ms`);
} else if (cas === 'C2') {
  let c, r = 'ok';
  const m = 'a['.repeat(25000);
  try { c = compileGlob(m); if (c.test('a[') !== false || c.test(m) !== false) r = 'échec : le motif géant correspond'; } catch (e) { r = 'échec : levée ' + e.name; }
  console.log(r);
} else if (cas === 'C3') {
  const rep = [];
  const exact = 'a'.repeat(MAX_MOTIF - 1) + '*', plus = 'a'.repeat(MAX_MOTIF) + '*';
  const ce = compileGlob(exact), cp = compileGlob(plus);
  if (ce.test('a'.repeat(MAX_MOTIF - 1) + 'xy') !== true) rep.push('motif de MAX_MOTIF caractères inerte');
  if (cp.test('a'.repeat(MAX_MOTIF) + 'xy') !== false) rep.push('motif de MAX_MOTIF+1 caractères actif');
  const co = compileGlob('**/a/**/b/**/*.js');
  if (co.test('a/b/'.repeat(500) + 'x.js') !== true) rep.push('chemin ordinaire long jugé faux');
  if (co.test('a/b/'.repeat(500) + 'x.ts') !== false) rep.push('chemin ordinaire long jugé vrai à tort');
  console.log(rep.length ? 'échec : ' + rep.join(', ') : 'ok');
}
JS
glequiv() { node "$GL_AUX/equiv.mjs" "$GL_LIB" "$GL_AUX/ancien.mjs" "$1" "$GL_GRAINE" "$2" 2>&1; }
glligne() { awk -v k="$1" 'index($0, k ": ") == 1 { print substr($0, length(k) + 3) }'; }
echo "=== GLOB — coût borné de la correspondance de motifs (P79-D-32, SOCL-26) ==="
GL_COUV="$(glequiv couverture "$GL_N")"; echo "  $(printf '%s\n' "$GL_COUV" | head -1)"; echo "  rejeu : VF_GLOB_GRAINE=$GL_GRAINE VF_GLOB_N=$GL_N bash test-cockpit-confinement.sh"
assert_eq "GLOB.E0 — couverture de l'équivalence : chaque classe de motifs atteinte (150 motifs, 20 correspondances, 20 non-correspondances)" "$(printf '%s\n' "$GL_COUV" | tail -1)" "complète"
assert_eq "GLOB.E1 — équivalence : verdict, specificity et glob identiques à la copie gelée sur $GL_N motifs bien formés (huit chemins chacun)" "$(glequiv equiv "$GL_N" | head -1)" "identique"
assert_eq "GLOB.E2 — entrées non chaînes (undefined, null, nombre, objet) : verdict de la copie gelée" "$(glequiv nonchaines "$GL_N" | head -1)" "identique"
GL_INV="$(glequiv invalides 2000)"; echo "  $(printf '%s\n' "$GL_INV" | glligne compteurs)"
assert_eq "GLOB.E3a — motif malformé que l'ancienne compilation levait : la même SyntaxError, à la compilation" "$(printf '%s\n' "$GL_INV" | glligne leve | head -1)" "identique"
assert_eq "GLOB.E3b — motif malformé à alternative de niveau supérieur (a[{/*.js,/ et le chemin zz/) : inerte, ne correspond plus à rien" "$(printf '%s\n' "$GL_INV" | glligne haut | head -1)" "identique"
assert_eq "GLOB.E3c — tout autre motif malformé : équivalence exacte" "$(printf '%s\n' "$GL_INV" | glligne autre | head -1)" "identique"
GL_PO="$(for F in F1 F2 F3 F4 F5; do node "$GL_AUX/perf.mjs" jumeau "$GL_LIB" "$F" 2>&1 | head -1; done | sort -u | tr -d '\n')"
assert_eq "GLOB.P0 — forme des cinq familles : le jumeau positif est jugé vrai, le chemin mesuré est jugé faux" "$GL_PO" "ok"
GL_BANC="$(node "$GL_AUX/perf.mjs" banc 2>&1 | head -1)"; echo "  banc : $GL_BANC"
assert_eq "GLOB.P3 — banc de mesure : il laisse passer un coût linéaire et voit un coût quadratique" "$(printf '%s\n' "$GL_BANC" | awk '{print $1, $2}')" "lineaire=laisse-passer quadratique=vu"
if [ "$(printf '%s\n' "$GL_BANC" | awk '{print $1, $2}')" = "lineaire=laisse-passer quadratique=vu" ]; then GL_PIL="$(node "$GL_AUX/perf.mjs" pilote "$GL_LIB" 2>&1)"
else GL_PIL="$(printf 'F%s ratio=banc-invalide plafond=banc-invalide\n' 1 2 3 4 5)"; fi
for F in F1 F2 F3 F4 F5; do
  assert_eq "GLOB.P1.$F — rapport t(2N)/t(N) au plus 2,5 (plancher de bruit 1 ms, meilleure de trois séries)" "$(printf '%s\n' "$GL_PIL" | sed -n "s/^$F ratio=\(.*\) plafond=.*\$/\1/p")" "ok"
  assert_eq "GLOB.P2.$F — plafond absolu : t(2N) au plus 250 ms" "$(printf '%s\n' "$GL_PIL" | sed -n "s/^$F .* plafond=//p")" "ok"
done
for C in C0 C1 C3 C4; do
  case "$C" in
    C0) T="constantes MAX_MOTIF et MAX_PAS bornées et exportées, automateDe exporté";;
    C1) T="chemin au-delà du budget : le testeur rend faux, en moins de 250 ms";;
    C3) T="frontières : MAX_MOTIF caractères fonctionne, un de plus est inerte ; un chemin ordinaire très long est jugé juste";;
    C4) T="500 accolades imbriquées : compile et correspond sans dépassement de pile";;
  esac
  assert_eq "GLOB.$C — $T" "$(node "$GL_AUX/plafonds.mjs" "$GL_LIB" "$C" 2>&1 | head -1)" "ok"
done
GL_C2="$(node "$GL_AUX/plafonds.mjs" "$GL_LIB" C2 2> "$GL_AUX/c2.err" | head -1)"
GL_C2L="$(awk 'END{print NR}' "$GL_AUX/c2.err")"; GL_C2M="$(awk '{ if (length($0) > m) m = length($0) } END{print m + 0}' "$GL_AUX/c2.err")"
assert_eq "GLOB.C2 — motif géant de crochets non fermés : ne lève pas, rend faux, un avis d'une ligne de moins de 200 caractères sur stderr" "$GL_C2 / $GL_C2L ligne / $([ "$GL_C2M" -lt 200 ] && echo court || echo long)" "ok / 1 ligne / court"

echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
