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
  PORT="$("$NODE" "$AUX/json.mjs" "$OUT/.cache/server.json" 'j.port' 2>/dev/null || echo 0)"
  TOK="$("$NODE" "$AUX/token.mjs" "$PORT" /)"
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
