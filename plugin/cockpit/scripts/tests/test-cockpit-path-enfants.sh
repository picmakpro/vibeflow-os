#!/usr/bin/env bash
# test-cockpit-path-enfants.sh — audit H-1 (hérité de la Phase 67, présent dans v2.75.0) : le serveur du cockpit et ses modules appellent des
# outils par leur NOM (which, claude, git, bash, awk, tr, ps…). Un PATH avec « . », un élément relatif, un élément vide ou un dossier du lab
# fait exécuter à leur place un programme posé dans le lab.
#   U l'utilitaire (assainirPath, envEnfant) : vide, relatif, sous le lab, lien symbolique, repli sûr, PATH du processus intact
#   F fonctions du module (gitCommonDir, collectWho) lancées depuis le lab avec un PATH piégé : aucun marqueur
#   G socle vf-signal (collectSignal, arbresGit, brancheBase, retard, lireVerrous) : idem (Phase 68)
#   S serveur lancé depuis le lab (which, claude --version, direct, verrous) avec un PATH piégé : aucun marqueur, et le serveur répond
#   L lanceur `open` / `stop` (construction du moteur, ps, serveur détaché)
# Chaque piège est transparent (il écrit son marqueur puis délègue à l'outil réel) : un correctif ne se paie jamais d'un faux vert par un outil cassé.
# VF_COCKPIT_SUT=<dossier plugin/> rejoue la suite contre une copie antérieure (témoin rouge). Exit 0 si tout passe.
set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; }
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
HERE_T="$(cd "$(dirname "$0")" && pwd)"
if [ -n "${VF_COCKPIT_SUT:-}" ]; then SCRIPTS="$VF_COCKPIT_SUT/cockpit/scripts"; else SCRIPTS="$(cd "$HERE_T/.." && pwd)"; fi
ENG="$SCRIPTS/../skills/cockpit-moteur"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; mkdir -p "$WORK/home/.claude/scripts"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
NODE="$(command -v node)"; REAL_PATH="$PATH"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
. "$HERE_T/socle-serveur.sh"
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }

# --- le lab de fixture : un dépôt git minimal avec un planning, et des outils piégés à la racine (« . ») et dans bin/ ---
LAB="$WORK/lab"; MARK="$WORK/marqueurs"; mkdir -p "$LAB/.planning" "$LAB/bin" "$MARK"
printf '## Milestones\n\n- 🚧 **v1** — Phase 1\n\n### Phase 1: Une\n**Goal**: g\n' > "$LAB/.planning/ROADMAP.md"
printf -- '---\ncurrent_phase: 1\n---\n' > "$LAB/.planning/STATE.md"
git -C "$LAB" init -q && git -C "$LAB" add -A && git -C "$LAB" -c user.email=t@t -c user.name=t commit -q -m init
cp "$SCRIPTS/../../conductor/scripts/driver-lock.sh" "$WORK/home/.claude/scripts/driver-lock.sh" 2>/dev/null || true
piege() { # piege <dossier> <nom> : le marqueur <nom> est écrit dans $MARK, puis l'outil réel s'exécute (claude : aucun réel, faux)
  local d="$1" n="$2" r; r="$(PATH="$REAL_PATH" command -v "$n" 2>/dev/null || true)"
  { printf '#!/bin/sh\n: > "%s/%s"\n' "$MARK" "$n"
    if [ "$n" = claude ]; then printf 'echo "9.9.9 (fake)"\n'; elif [ -n "$r" ]; then printf 'exec "%s" "$@"\n' "$r"; else printf 'exit 127\n'; fi; } > "$d/$n"; chmod +x "$d/$n"
}
for n in git bash awk tr which claude ps sed date; do piege "$LAB" "$n"; piege "$LAB/bin" "$n"; done
marqueurs() { ls "$MARK" 2>/dev/null | sort | tr '\n' ' ' | sed 's/ $//'; }
vider() { rm -f "$MARK"/* 2>/dev/null; true; }

echo "=== U — l'utilitaire ==="
cat > "$WORK/u.mjs" <<'JS'
import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [, , scripts, lab] = process.argv;
let m; try { m = await import(pathToFileURL(scripts + '/vf-cockpit-env.mjs').href); } catch (e) { console.log(JSON.stringify({ absent: String(e.message).slice(0, 80) })); process.exit(0); }
const { assainirPath: a, envEnfant, PATH_REPLI } = m, D = path.delimiter;
fs.symlinkSync(path.join(lab, 'bin'), lab + '-lien');
const avant = process.env.PATH;
const r = {
  point: a(['.', '/usr/bin', '/bin'].join(D), lab),
  vide: a(['', '/usr/bin'].join(D), lab),
  fin: a(['/usr/bin', ''].join(D), lab),
  relatif: a(['bin', './bin', '../x', '/usr/bin'].join(D), lab),
  tilde: a(['~/bin', '/usr/bin'].join(D), lab),
  sousLab: a([path.join(lab, 'bin'), path.join(lab, 'a', 'b'), lab, '/usr/bin'].join(D), lab),
  lien: a([lab + '-lien', '/usr/bin'].join(D), lab),
  voisin: a([lab + 'x/bin', '/usr/bin'].join(D), lab),
  garde: a(['/usr/bin', '/bin', '/usr/local/bin'].join(D), lab),
  videTotal: a('', lab), sansPath: a(undefined, lab), tousRelatifs: a(['.', 'bin', ''].join(D), lab),
  repli: PATH_REPLI,
  copie: (() => { const e = { PATH: '.' + D + '/usr/bin', X: '1' }; const o = envEnfant(lab, e); return { x: o.X, path: o.PATH, intact: e.PATH === '.' + D + '/usr/bin' }; })(),
  processusIntact: process.env.PATH === avant,
};
console.log(JSON.stringify(r));
JS
U="$("$NODE" "$WORK/u.mjs" "$SCRIPTS" "$LAB" 2>&1)"
ev() { printf '%s' "$U" | "$NODE" -e "const j=JSON.parse(require('fs').readFileSync(0,'utf8'));const v=(function(j){return $1})(j);console.log(typeof v==='string'?v:JSON.stringify(v))" 2>/dev/null || echo "illisible"; }
assert_eq "U0 — témoin : l'utilitaire existe" "$(ev '"absent" in j')" "false"
assert_eq "U1 — « . » est retiré" "$(ev 'j.point')" "/usr/bin:/bin"
assert_eq "U2 — élément vide (début ou fin) retiré" "$(ev 'j.vide+"|"+j.fin')" "/usr/bin|/usr/bin"
assert_eq "U3 — éléments relatifs retirés (bin, ./bin, ../x, ~/bin)" "$(ev 'j.relatif+"|"+j.tilde')" "/usr/bin|/usr/bin"
assert_eq "U4 — dossiers du lab retirés (racine, bin, sous-dossier), un voisin de même préfixe gardé" "$(ev 'j.sousLab+"|"+j.voisin')" "/usr/bin|${LAB}x/bin:/usr/bin"
assert_eq "U5 — un lien symbolique vers le lab est retiré" "$(ev 'j.lien')" "/usr/bin"
assert_eq "U6 — témoin : des éléments absolus sains sont gardés tels quels" "$(ev 'j.garde')" "/usr/bin:/bin:/usr/local/bin"
assert_eq "U7 — PATH vide, absent ou tout relatif : repli sûr" "$(ev 'j.videTotal+"|"+j.sansPath+"|"+j.tousRelatifs')" "$(printf '%s|%s|%s' /usr/bin:/bin:/usr/sbin:/sbin /usr/bin:/bin:/usr/sbin:/sbin /usr/bin:/bin:/usr/sbin:/sbin)"
assert_eq "U8 — envEnfant rend une copie : le reste de l'environnement est gardé, l'entrée n'est pas modifiée" "$(ev 'j.copie')" '{"x":"1","path":"/usr/bin","intact":true}'
assert_eq "U9 — le PATH du processus n'est jamais modifié" "$(ev 'j.processusIntact')" "true"

# --- les scénarios de PATH piégé, rejoués pour chaque famille ---
declare -a NOMS=("point" "relatif" "vide" "lab-absolu")
chemin_de() { case "$1" in point) printf '.:%s' "$REAL_PATH";; relatif) printf 'bin:%s' "$REAL_PATH";; vide) printf '';; lab-absolu) printf '%s/bin:%s' "$LAB" "$REAL_PATH";; esac; }

echo "=== F — fonctions du module (gitCommonDir, collectWho) depuis le lab ==="
cat > "$WORK/f.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
const [, , scripts, lab] = process.argv, u = (f) => pathToFileURL(scripts + '/' + f).href;
const p = await import(u('vf-cockpit-paths.mjs')), w = await import(u('vf-cockpit-who.mjs')), pl = await import(u('vf-cockpit-project.mjs'));
const out = { git: !!p.gitCommonDir(lab) };
try { w.collectWho(lab, { scriptsDir: scripts, home: process.env.HOME }); out.who = true; } catch (e) { out.who = String(e.message).slice(0, 80); }
console.log(JSON.stringify(out));
JS
for s in "${NOMS[@]}"; do
  vider; R="$(cd "$LAB" && env PATH="$(chemin_de "$s")" "$NODE" "$WORK/f.mjs" "$SCRIPTS" "$LAB" 2>&1 | tail -1)"
  assert_eq "F-$s — aucun outil du lab exécuté par les fonctions du module" "[$(marqueurs)]" "[]"
done
vider; R="$(cd "$LAB" && env PATH="$REAL_PATH" "$NODE" "$WORK/f.mjs" "$SCRIPTS" "$LAB" 2>&1 | tail -1)"
assert_eq "F-témoin — PATH sain : git trouvé, rien n'est cassé par le correctif" "$R" '{"git":true,"who":true}'

echo "=== G — socle vf-signal (collectSignal : arbres git, base, retard, verrous bash, tags) depuis le lab ==="
# phase 68 : arbresGit, brancheBase, retard, lireVerrous et la lecture des tags passent par shBorne ; chacun doit hériter du PATH assaini
cat > "$WORK/g.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
const [, , scripts, lab] = process.argv, u = (f) => pathToFileURL(scripts + '/' + f).href;
const s = await import(u('vf-cockpit-signal.mjs')), a = await import(u('vf-cockpit-arbres.mjs')), v = await import(u('vf-cockpit-vie.mjs'));
const out = {};
try { const r = s.collectSignal(lab, { scriptsDir: scripts, home: process.env.HOME }); out.signal = Array.isArray(r.arbres) && r.arbres.length >= 1; } catch (e) { out.signal = String(e.message).slice(0, 80); }
out.arbres = a.arbresGit(lab).length >= 1; out.base = a.brancheBase(lab); out.retard = typeof a.retard({ chemin: lab, base: out.base, lab }) === 'object';
out.verrous = v.lireVerrous(lab, { scriptsDir: scripts, home: process.env.HOME }).etat;
console.log(JSON.stringify(out));
JS
for s in "${NOMS[@]}"; do
  vider; R="$(cd "$LAB" && env PATH="$(chemin_de "$s")" "$NODE" "$WORK/g.mjs" "$SCRIPTS" "$LAB" 2>&1 | tail -1)"
  assert_eq "G-$s — aucun outil du lab exécuté par le socle vf-signal (git des arbres, bash du verrou)" "[$(marqueurs)]" "[]"
done
vider; R="$(cd "$LAB" && env PATH="$REAL_PATH" "$NODE" "$WORK/g.mjs" "$SCRIPTS" "$LAB" 2>&1 | tail -1)"
assert_eq "G-témoin — PATH sain : le socle rend ses arbres et lit les verrous (rien n'est cassé par l'assainissement)" "$(printf '%s' "$R" | "$NODE" -e "const j=JSON.parse(require('fs').readFileSync(0,'utf8'));console.log([j.signal,j.arbres,j.retard,j.verrous!=='absente'].join(','))" 2>/dev/null || echo "illisible: $R")" "true,true,true,true"

echo "=== H — le 4e argument « lab » de shBorne est discriminé (cwd de l'enfant ≠ lab) ==="
# Les sections F et G lancent tout avec un cwd égal au lab : sans le 4e argument, `lab` retombe sur `cwd` et le même résultat sort. Ici l'enfant tourne ailleurs que la racine :
#   - un arbre git (worktree) posé SOUS le lab : le retard de cet arbre s'exécute avec cwd = l'arbre, et le PATH piégé (LAB2/bin, absolu, construit relativement au LAB) doit être assaini par rapport au LAB ;
#   - un DAG « running » frais dans le dossier git commun (LAB2/.git/vf-driver/repo) : les git de collectWho s'exécutent avec cwd = ce dossier, hors de la racine du travail.
# Une copie où `lab` n'est pas transmis (signal sans `lab: root`, who sans `root`) laisse LAB2/bin dans le PATH : le marqueur apparaît (voir la mutation dans la trace de la phase).
LAB2="$WORK/lab2"; mkdir -p "$LAB2/.planning" "$LAB2/bin"
cp "$LAB/.planning/ROADMAP.md" "$LAB2/.planning/ROADMAP.md"; cp "$LAB/.planning/STATE.md" "$LAB2/.planning/STATE.md"
git -C "$LAB2" init -q -b main && git -C "$LAB2" add -A && git -C "$LAB2" -c user.email=t@t -c user.name=t commit -q -m init
git -C "$LAB2" worktree add -q "$LAB2/wt" -b autre >/dev/null 2>&1
mkdir -p "$LAB2/.git/vf-driver/repo"
printf '{"nodes":[{"id":"n1","status":"running","stage":"coder","step":"x"}]}\n' > "$LAB2/.git/vf-driver/repo/m.dag.json"
# piège journalisé : chaque exécution d'un outil de LAB2/bin écrit sa ligne de commande dans h.log (il délègue ensuite à l'outil réel)
HLOG="$WORK/h.log"
for n in git bash awk tr which claude ps sed date; do
  r="$(PATH="$REAL_PATH" command -v "$n" 2>/dev/null || true)"
  { printf '#!/bin/sh\necho "%s $*" >> "%s"\n' "$n" "$HLOG"; if [ "$n" = claude ]; then printf 'echo "9.9.9 (fake)"\n'; elif [ -n "$r" ]; then printf 'exec "%s" "$@"\n' "$r"; else printf 'exit 127\n'; fi; } > "$LAB2/bin/$n"; chmod +x "$LAB2/bin/$n"
done
cat > "$WORK/h.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
const [, , scripts, lab] = process.argv, u = (f) => pathToFileURL(scripts + '/' + f).href;
const s = await import(u('vf-cockpit-signal.mjs')), w = await import(u('vf-cockpit-who.mjs'));
const out = {};
try { const r = s.collectSignal(lab, { scriptsDir: scripts, home: process.env.HOME }); out.arbres = r.arbres.length; } catch (e) { out.arbres = String(e.message).slice(0, 80); }
try { const r = w.collectWho(lab, { scriptsDir: scripts, home: process.env.HOME }); out.dag = (r.workers || []).filter((x) => x.kind === 'dag-node').length; } catch (e) { out.dag = String(e.message).slice(0, 80); }
console.log(JSON.stringify(out));
JS
# Aucune tolérance : le `lab` passé à shBorne est toujours la racine du LAB observé, jamais celle d'un sous-arbre. La lecture des tags d'un arbre sous le lab
# (`git … for-each-ref … refs/tags/v*`, readPlanning(<arbre>)) ne doit pas laisser LAB2/bin dans son PATH : tout appel d'un outil du lab est un échec.
: > "$HLOG"; R="$(cd "$WORK" && env PATH="$LAB2/bin:$REAL_PATH" "$NODE" "$WORK/h.mjs" "$SCRIPTS" "$LAB2" 2>&1 | tail -1)"
assert_eq "H-lab-absolu — cwd de l'enfant ≠ lab (arbre sous le lab, DAG du dossier git commun) : aucun outil du lab exécuté (lecture des tags de l'arbre sous le lab comprise)" "[$(tr '\n' '|' < "$HLOG")]" "[]"
assert_eq "H-témoin — les deux chemins ont bien tourné (2 arbres lus, 1 nœud DAG running) : le test atteint les appels discriminés" "$R" '{"arbres":2,"dag":1}'

echo "=== S — serveur lancé depuis le lab avec un PATH piégé ==="
"$NODE" "$SCRIPTS/vf-cockpit-build.mjs" "$LAB" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
OUT="$LAB/.vibeflow/cockpit"
cat > "$WORK/req.mjs" <<'JS'
import http from 'node:http'; const [, , port, p] = process.argv;
http.get({ host: '127.0.0.1', port: Number(port), path: p, headers: { Host: `127.0.0.1:${port}` } }, (r) => { let b = ''; r.on('data', (c) => (b += c)); r.on('end', () => console.log(r.statusCode + ' ' + b.length)); }).on('error', (e) => console.log('ERR ' + e.code));
JS
for s in "${NOMS[@]}"; do
  vider; rm -f "$OUT/.cache/server.json"
  COCKPIT_LOG="$WORK/serve-$s.out" cockpit_lancer "$LAB" PATH="$(chemin_de "$s")" VF_COCKPIT_ENGINE_DIR="$ENG" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS" || true
  SP="$VF_PID"
  PORT="$VF_PORT"
  "$NODE" "$WORK/req.mjs" "$PORT" /project.html > "$WORK/rep.out"; "$NODE" "$WORK/req.mjs" "$PORT" / >> "$WORK/rep.out"; sleep 3
  vf_hyg_stop "$SP"
  assert_eq "S-$s — aucun outil du lab exécuté au démarrage ni par le direct (which, claude, git, bash, awk, tr…)" "[$(marqueurs)]" "[]"
  assert_eq "S-$s — témoin : le serveur a répondu (200 sur les deux pages)" "$(sed 's/ [0-9]*$//' "$WORK/rep.out" | tr '\n' ' ')" "200 200 "
done

echo "=== L — lanceur open / stop ==="
for s in "point" "vide"; do
  vider; rm -rf "$OUT"
  LO="$(cd "$LAB" && env PATH="$(chemin_de "$s")" "$NODE" "$SCRIPTS/vf-cockpit.mjs" open --no-open --port "$(libre)" 2>&1 | tail -3)"
  sleep 3
  LS="$(cd "$LAB" && env PATH="$(chemin_de "$s")" "$NODE" "$SCRIPTS/vf-cockpit.mjs" stop 2>&1 | tail -1)"
  for _ in $(seq 1 30); do [ "$(cd "$LAB" && env PATH="$REAL_PATH" "$NODE" "$SCRIPTS/vf-cockpit.mjs" status 2>&1 | tail -1)" = "Cockpit arrêté." ] && break; sleep 0.2; done
  assert_eq "L-$s — aucun outil du lab exécuté par le lanceur (construction, ps, serveur)" "[$(marqueurs)]" "[]"
  case "$LO" in *"Cockpit :"*) assert_eq "L-$s — témoin : le serveur a démarré" "ok" "ok";; *) assert_eq "L-$s — témoin : le serveur a démarré" "$LO" "Cockpit : …";; esac
  assert_eq "L-$s — témoin : le lanceur a arrêté son serveur" "$LS" "Cockpit arrêté."
done

vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
