#!/usr/bin/env bash
# test-cockpit-git-signature.sh — signal Git du direct : signature bon marché dans le filet de 5 s (78-09 ; GITC-11 ; P78-D-15, P78-D-23).
#   R1 un commit arrive en événement `git` sur le flux SSE, sans changement : aucun événement
#   R2 worktrees, index, argv journalisé (jamais log/status/diff), coût de la signature · R3 relais vers la page (Chrome, SAUTÉ sans navigateur) · R4 lab hors dépôt
#   Mutants : M-POLL, M-LOG, M-RELAIS. Ports éphémères, jamais 4456. Exit 0 si tout passe, 1 sinon.

set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; }
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t.test GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t.test
HERE_T="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="$(cd "$HERE_T/.." && pwd)"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home" "$WORK/bin"
REAL_HOME="$HOME"; export HOME="$WORK/home"
GIT_REEL="$(command -v git)"
PIDS=()
SRV=""
stop_srv() { [ -n "$SRV" ] && { vf_hyg_stop "$SRV"; }; SRV=""; }
trap 'stop_srv; vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"' EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init

PASS=0; FAIL=0; SKIP=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
skip() { echo "  ⏭️  SAUTÉ — $1 ($2)"; SKIP=$((SKIP+1)); }
G_() { "$GIT_REEL" "$@"; }
maintenant() { node -e 'console.log(Date.now())'; }

CHROME=""
for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue
  if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
[ -n "${SIGNAL_SANS_NAVIGATEUR:-}" ] && CHROME=""
echo "navigateur : ${CHROME:-aucun (R3 est SAUTÉE)}"

# --- aides node écrites par la suite ---
cat > "$AUX/json.mjs" <<'JS'
import fs from 'node:fs';
const j = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
console.log(String(new Function('j', 'return (' + process.argv[3] + ')')(j)));
JS
cat > "$AUX/token.mjs" <<'JS'
import http from 'node:http';
const [, , port, p] = process.argv;
http.get({ host: '127.0.0.1', port: Number(port), path: p, headers: { Host: `127.0.0.1:${port}` } }, (r) => { let b = ''; r.on('data', (c) => (b += c)); r.on('end', () => console.log(/VF_COCKPIT_SERVER=\{"token":"([0-9a-f]+)"/.exec(b)?.[1] || '')); });
JS
# sse.mjs <port> <jeton> <durée ms> <sortie> : écoute le flux ; une ligne « horodatage<TAB>nom<TAB>données » par événement
cat > "$AUX/sse.mjs" <<'JS'
import http from 'node:http';
import fs from 'node:fs';
const [, , port, token, maxMs, out] = process.argv;
fs.writeFileSync(out, '');
let buf = '';
const req = http.get({ host: '127.0.0.1', port: Number(port), path: '/api/vf/events?token=' + token, headers: { Host: `127.0.0.1:${port}` } }, (res) => {
  res.setEncoding('utf8');
  res.on('data', (c) => {
    buf += c; let i;
    while ((i = buf.indexOf('\n\n')) >= 0) {
      const bloc = buf.slice(0, i); buf = buf.slice(i + 2);
      const nom = /^event: (.*)$/m.exec(bloc)?.[1], data = /^data: (.*)$/m.exec(bloc)?.[1];
      if (nom) fs.appendFileSync(out, `${Date.now()}\t${nom}\t${data || ''}\n`);
    }
  });
});
req.on('error', () => process.exit(0));
setTimeout(() => process.exit(0), Number(maxMs));
JS
cat > "$AUX/cdp-run.mjs" <<'JS'
// cdp-run.mjs <chrome> <scenario.js> [args…] : joue le corps asynchrone du scénario avec (s, ARGS) ; une ligne JSON
import fs from 'node:fs';
const { executer } = await import(process.env.VF_CS);
const [, , chrome, fichier, ...ARGS] = process.argv;
const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor;
const corps = new AsyncFunction('s', 'ARGS', fs.readFileSync(fichier, 'utf8'));
await executer(chrome, async (s) => corps(s, ARGS), { csp: true });
JS
export VF_CS="$HERE_T/chrome-session.mjs"
cat > "$AUX/jqs.mjs" <<'JS'
// jqs.mjs '<json>' '<expression sur j>' : évalue l'expression sur la ligne JSON donnée
const j = JSON.parse(process.argv[2]);
console.log(String(new Function('j', 'return (' + process.argv[3] + ')')(j)));
JS
jq_() { node "$AUX/jqs.mjs" "$1" "$2"; }
cat > "$AUX/mut.mjs" <<'JS'
// mut.mjs <fichier> <ancien> <nouveau> : remplace UNE occurrence ; échoue (code 1) si l'ancien texte est absent (un mutant mort ne prouve rien)
import fs from 'node:fs';
const [, , f, a, b] = process.argv; const t = fs.readFileSync(f, 'utf8');
if (!t.includes(a) || t.split(a).length !== 2) { console.error('mutation impossible : motif absent ou multiple : ' + a); process.exit(1); }
fs.writeFileSync(f, t.replace(a, () => b));
JS
mutate() { node "$AUX/mut.mjs" "$@"; }
# emballage git : journalise l'argv puis exécute le vrai git (sur le PATH du serveur seulement)
cat > "$WORK/bin/git" <<EOT
#!/bin/sh
printf '%s\n' "\$*" >> "$WORK/git.log"
exec "$GIT_REEL" "\$@"
EOT
chmod +x "$WORK/bin/git"
NODE="$(command -v node)"
mkmod() { # $1 = nom ; rend le dossier des scripts de la copie (frère : skills/cockpit-moteur)
  local d="$WORK/mod-$1"; mkdir -p "$d/scripts" "$d/skills"
  cp "$SCRIPTS"/*.mjs "$SCRIPTS"/*.json "$d/scripts/"; cp -R "$SCRIPTS/../skills/cockpit-moteur" "$d/skills/cockpit-moteur"
  echo "$d/scripts"
}
mk_lab() { # $1 = dossier : lab GSD minimal
  mkdir -p "$1/src" "$1/.planning/phases/01-x"
  printf 'export const util = () => 1;\n' > "$1/src/util.js"
  printf -- '- [x] **Phase 1: Socle** - premier jet\n' > "$1/.planning/ROADMAP.md"
  printf -- '---\nstatus: executing\nmilestone: vibeflow-test\n---\n# State\n' > "$1/.planning/STATE.md"
  printf '<objective>Faire le socle</objective>\n' > "$1/.planning/phases/01-x/01-01-PLAN.md"; echo ok > "$1/.planning/phases/01-x/01-01-SUMMARY.md"
}
build_serve() { # $1 = lab, $2 = dossier de scripts (défaut : le module) ; pose OUT, PORT, TOK ; démarre le serveur (SRV), git emballé
  "$NODE" "${2:-$SCRIPTS}/vf-cockpit-build.mjs" "$1" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
  OUT="$1/.vibeflow/cockpit"; rm -f "$OUT/.cache/server.json"
  PATH="$WORK/bin:$PATH" "$NODE" "$OUT/serve.mjs" --no-open --port "$(libre)" > "$WORK/serve.out" 2>&1 &
  SRV=$!; PIDS+=("$SRV")
  for _ in $(seq 1 100); do [ -s "$OUT/.cache/server.json" ] && break; sleep 0.1; done
  PORT=0; TOK=""
  for _ in $(seq 1 50); do # le fichier peut être lu à moitié écrit : on relit jusqu'à un port valide et un jeton
    PORT="$("$NODE" "$AUX/json.mjs" "$OUT/.cache/server.json" 'j.port' 2>/dev/null || echo 0)"
    [ "${PORT:-0}" != 0 ] && TOK="$("$NODE" "$AUX/token.mjs" "$PORT" / 2>/dev/null)"
    [ -n "$TOK" ] && break; sleep 0.2
  done
}
ecouter() { # $1 = durée ms, $2 = fichier de sortie : lance le client SSE en fond (PID dans CLI)
  "$NODE" "$AUX/sse.mjs" "$PORT" "$TOK" "$1" "$2" & CLI=$!; PIDS+=("$CLI")
  for _ in $(seq 1 50); do grep -q "	hello	" "$2" 2>/dev/null && break; sleep 0.1; done # le client est branché quand le `hello` est arrivé
}
nb_git() { grep -c "	git	" "$1" 2>/dev/null || true; }

# --- dépôt jetable : `depot` (principal, branche main) et le worktree `wt-a` (feat/x) ---
DEPOT="$WORK/depot"; WT="$WORK/wt-a"
mk_lab "$DEPOT"
G_ -C "$DEPOT" init -q -b main && G_ -C "$DEPOT" add -A && G_ -C "$DEPOT" commit -q -m init
G_ -C "$DEPOT" worktree add -q -b feat/x "$WT" >/dev/null 2>&1

echo "=== R1 — un commit dans le lab arrive en événement git ==="
build_serve "$DEPOT"
assert_eq "R1.0 — témoin : serveur démarré, jeton obtenu, git emballé" "$([ "$PORT" != 0 ] && [ -n "$TOK" ] && [ -x "$WORK/bin/git" ] && echo oui || echo non)" "oui"
: > "$WORK/git.log"
ecouter 11000 "$WORK/w0.sse"; wait "$CLI" 2>/dev/null
assert_eq "R1.0b — témoin : le client reçoit le hello du flux" "$(grep -c "	hello	" "$WORK/w0.sse")" "1"
assert_eq "R1.1 — 11 s sans changement : aucun événement git" "$(nb_git "$WORK/w0.sse")" "0"

ecouter 10000 "$WORK/w1.sse"; T1="$(maintenant)"
G_ -C "$DEPOT" commit -q --allow-empty -m "un commit du test"
wait "$CLI" 2>/dev/null
N1="$(nb_git "$WORK/w1.sse")"
assert_eq "R1.2a — un commit dans le lab : au moins un événement git" "$([ "$N1" -ge 1 ] && echo oui || echo non)" "oui"
L1="$(grep "	git	" "$WORK/w1.sse" | head -1)"
assert_eq "R1.2b — la charge ne porte que seq, at, sig (sig de 16 hexadécimaux)" "$(node -e "const j=JSON.parse(process.argv[1].split('\t')[2]||'null'); console.log(j&&Object.keys(j).sort().join(',')+'|'+/^[0-9a-f]{16}\$/.test(j.sig))" "$L1" 2>/dev/null)" "at,seq,sig|true"
LAT="$(node -e "console.log(Number(process.argv[1].split('\t')[0])-Number(process.argv[2]))" "$L1" "$T1" 2>/dev/null)"
assert_eq "R1.2c — l'événement arrive en moins de 8 s après le commit" "$([ -n "$L1" ] && [ "$LAT" -ge 0 ] 2>/dev/null && [ "$LAT" -lt 8000 ] && echo oui || echo non)" "oui"
stop_srv

# --- aides des sections R2 à R4 ---
# fenetre <durée ms> <fichier> [commande…] : écoute le flux, joue la commande une fois branché, rend la main à la fin de la fenêtre
fenetre() { local d="$1" o="$2"; shift 2; ecouter "$d" "$o"; [ "$#" -gt 0 ] && "$@"; wait "$CLI" 2>/dev/null; }
cat > "$AUX/r31.js" <<'JS'
// r31.js <base> <page> <lab> : compte les vf-git:signal de la page ; un commit dans le lab ; attend un signal (échéance 10 s) ; la page ne s'est pas rechargée
const [base, page, lab] = ARGS;
await s.naviguer(base + page);
await s.attendre(`document.readyState === 'complete' && !!window.VibeFlow`, 'page rendue');
await s.ev(`(() => { window.__sig = 0; window.__marque = 1; document.addEventListener('vf-git:signal', () => { window.__sig++; }); })()`);
const { execFileSync } = await import('node:child_process');
execFileSync('git', ['-C', lab, 'commit', '-q', '--allow-empty', '-m', 'commit de R3.1'], { stdio: 'ignore' });
let atteint = true;
try { await s.attendre(`window.__sig >= 1`, 'vf-git:signal reçu', 10000); } catch { atteint = false; }
return await s.ev(`({ signaux: window.__sig, marque: window.__marque, atteint: ${atteint} })`);
JS
cdp31() { node "$AUX/cdp-run.mjs" "$CHROME" "$AUX/r31.js" "$@"; }
temps_sig() { # temps_sig <lab> : médiane de 7 appels de signatureGit (ms), 2 décimales
  node -e "import(process.argv[1]).then(({signatureGit})=>{const t=[];let ok=true;for(let i=0;i<8;i++){const a=process.hrtime.bigint();const s=signatureGit(process.argv[2]);const b=process.hrtime.bigint();if(!s)ok=false;if(i)t.push(Number(b-a)/1e6)}t.sort((x,y)=>x-y);console.log((ok?'':'NULL ')+t[3].toFixed(2))})" "$SCRIPTS/vf-cockpit-git-signature.mjs" "$1"
}

# sous_cmds <journal> : la sous-commande de chaque ligne d'argv, options globales (--no-optional-locks, -c <v>, -C <dir>) écartées
sous_cmds() { awk '{ i=1; while (i<=NF) { if ($i=="-c"||$i=="-C") i+=2; else if ($i ~ /^--/ && $i!="") i++; else break } print $i }' "$1"; }
echo "=== R2 — worktrees, index, argv journalisé, coût ==="
build_serve "$DEPOT"
fenetre 10000 "$WORK/w2a.sse" G_ -C "$WT" switch -q -c autre
assert_eq "R2.1a — git switch -c dans un worktree du lab : un événement git" "$([ "$(nb_git "$WORK/w2a.sse")" -ge 1 ] && echo oui || echo non)" "oui"
printf 'neuf\n' > "$DEPOT/src/neuf.js"
fenetre 11000 "$WORK/w2b.sse" true
assert_eq "R2.1b — témoin : un fichier neuf non ajouté ne produit aucun événement" "$(nb_git "$WORK/w2b.sse")" "0"
fenetre 10000 "$WORK/w2c.sse" G_ -C "$DEPOT" add src/neuf.js
assert_eq "R2.1c — git add dans l'arbre principal : un événement git" "$([ "$(nb_git "$WORK/w2c.sse")" -ge 1 ] && echo oui || echo non)" "oui"
printf 'export const util = () => 2;\n' > "$DEPOT/src/util.js"
fenetre 11000 "$WORK/w2d.sse" true
assert_eq "R2.1d — un fichier suivi modifié sans add : aucun événement (limite assumée)" "$(nb_git "$WORK/w2d.sse")" "0"
: > "$WORK/git.log"
fenetre 11000 "$WORK/w2e.sse" true
assert_eq "R2.2a — témoin : le journal d'argv voit les appels de la signature (for-each-ref)" "$([ "$(sous_cmds "$WORK/git.log" | grep -c '^for-each-ref$')" -ge 1 ] && echo oui || echo non)" "oui"
assert_eq "R2.2b — 11 s sans changement : aucune sous-commande log, status ni diff" "$(sous_cmds "$WORK/git.log" | grep -cE '^(log|status|diff)$')" "0"
assert_eq "R2.2c — sous-commandes vues : seulement for-each-ref, worktree, show-ref, symbolic-ref, rev-list, rev-parse" "$(sous_cmds "$WORK/git.log" | sort -u | grep -vxE 'for-each-ref|worktree|show-ref|symbolic-ref|rev-list|rev-parse' | tr '\n' ' ')" ""
stop_srv
TF="$(temps_sig "$DEPOT")"; TR="$(temps_sig "$REAL_HOME/Documents/dev/vibeflow-os")"
echo "  coût mesuré de signatureGit (médiane de 7) : fixture ${TF} ms · ce dépôt ${TR} ms"
assert_eq "R2.3 — le coût de la signature reste sous 50 ms (fixture et ce dépôt)" "$(node -e "const f=parseFloat(process.argv[1]),r=parseFloat(process.argv[2]);console.log(/NULL/.test(process.argv[1]+process.argv[2])?'nul':(f<50&&r<50?'oui':'non'))" "$TF" "$TR")" "oui"

echo "=== R3 — relais vers la page (vf-git:signal) ==="
if [ -z "$CHROME" ]; then skip "R3.1" "pas de navigateur"; else
  for pg in / /project.html; do
    build_serve "$DEPOT"; R="$(cdp31 "http://127.0.0.1:$PORT" "$pg" "$DEPOT" 2>&1 | tail -1)"; stop_srv
    assert_eq "R3.1 — $pg : un commit dans le lab donne au moins un vf-git:signal en moins de 10 s" "$(jq_ "$R" 'j.atteint && j.signaux >= 1 ? "oui" : "non"' 2>/dev/null)" "oui"
    assert_eq "R3.1 — $pg : la page ne s'est pas rechargée sur l'événement git" "$(jq_ "$R" 'j.marque' 2>/dev/null)" "1"
  done
fi

echo "=== R4 — lab hors dépôt ==="
HORS="$WORK/hors-depot"; mk_lab "$HORS"
build_serve "$HORS"
fenetre 11000 "$WORK/w4.sse" true
assert_eq "R4.0 — témoin : le client hors dépôt reçoit le hello" "$(grep -c "	hello	" "$WORK/w4.sse")" "1"
assert_eq "R4.1a — hors dépôt : aucun événement git" "$(nb_git "$WORK/w4.sse")" "0"
assert_eq "R4.1b — hors dépôt : aucune erreur dans la sortie du serveur" "$(grep -ciE 'error|erreur|TypeError|Unhandled' "$WORK/serve.out")" "0"
stop_srv

echo "=== Mutants ==="
# M-POLL : émission à chaque tick -> R1.1 rougit
MP="$(mkmod poll)"; mutate "$MP/vf-cockpit-live.mjs" "if (gs && gs !== gitSig) {" "if (gs) {" || echo "  ❌ mutation M-POLL impossible"
build_serve "$DEPOT" "$MP"; fenetre 11000 "$WORK/wmp.sse" true; stop_srv
NMP="$(nb_git "$WORK/wmp.sse")"
assert_eq "M-POLL — témoin : le mutant reçoit le hello (le test n'est pas vide)" "$(grep -c "	hello	" "$WORK/wmp.sse")" "1"
assert_eq "M-POLL — l'émission à chaque tick rougit R1.1 (événements git sans changement > 0)" "$([ "$NMP" -gt 0 ] && echo rouge || echo vert)" "rouge"
# M-LOG : signature faite d'un log -1 --all -> R2.2b rougit
ML="$(mkmod log)"; mutate "$ML/vf-cockpit-git-signature.mjs" "['for-each-ref', '--format=%(objectname) %(refname)']" "['log', '-1', '--all', '--format=%H']" || echo "  ❌ mutation M-LOG impossible"
build_serve "$DEPOT" "$ML"; : > "$WORK/git.log"; fenetre 11000 "$WORK/wml.sse" true; stop_srv
assert_eq "M-LOG — témoin : le mutant a bien tourné (journal d'argv non vide)" "$([ -s "$WORK/git.log" ] && echo oui || echo non)" "oui"
assert_eq "M-LOG — un log dans la signature rougit R2.2b (log vus > 0)" "$([ "$(sous_cmds "$WORK/git.log" | grep -c '^log$')" -gt 0 ] && echo rouge || echo vert)" "rouge"
# M-RELAIS : écouteur git retiré de la page -> R3.1 rougit
if [ -z "$CHROME" ]; then skip "M-RELAIS" "pas de navigateur"; else
  MR="$(mkmod relais)"; mutate "$(dirname "$MR")/skills/cockpit-moteur/assets/ui/70-vf-live.js" "es.addEventListener('git'," "es.addEventListener('git-retire'," || echo "  ❌ mutation M-RELAIS impossible"
  build_serve "$DEPOT" "$MR"; R="$(cdp31 "http://127.0.0.1:$PORT" / "$DEPOT" 2>&1 | tail -1)"; stop_srv
  assert_eq "M-RELAIS — l'écouteur retiré rougit R3.1 (aucun vf-git:signal reçu)" "$(jq_ "$R" 'j.atteint === false && j.signaux === 0 ? "rouge" : "vert"' 2>/dev/null)" "rouge"
fi

vf_hyg_assert
echo ""
echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL${SKIP:+ / $SKIP SAUTÉ}"
echo "=================================="
TOTAL=$((PASS+FAIL))
if [ "$TOTAL" -eq 0 ]; then
  echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée, résultat non fiable"
  exit 1
fi
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
