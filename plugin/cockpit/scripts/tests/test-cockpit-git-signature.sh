#!/usr/bin/env bash
# test-cockpit-git-signature.sh — signal Git du direct : signature bon marché dans le filet de 5 s (78-09 ; GITC-11 ; P78-D-15, P78-D-23).
#   R1 un commit arrive en événement `git` sur le flux SSE, sans changement : aucun événement
#   R2 worktrees, index, argv journalisé (jamais log/status/diff), coût de la signature · R3 relais vers la page (Chrome, SAUTÉ sans navigateur) · R4 lab hors dépôt
#   R5 audit 2026-11-06 (A5) : git muet (FIFO en include.path) — boucle libre, échéance globale, retrait, état distinct de lireGit
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
await s.attendre('!!(window.__vfLive && window.__vfLive.connected)', 'flux direct branché avant le commit'); // un commit joué avant l'abonnement du flux n'émet aucun signal
await s.ev(`(() => { window.__sig = 0; window.__marque = 1; document.addEventListener('vf-git:signal', () => { window.__sig++; }); })()`);
const { execFileSync } = await import('node:child_process');
execFileSync('git', ['-C', lab, 'commit', '-q', '--allow-empty', '-m', 'commit de R3.1'], { stdio: 'ignore' });
let atteint = true;
try { await s.attendre(`window.__sig >= 1`, 'vf-git:signal reçu', 10000); } catch { atteint = false; }
return await s.ev(`({ signaux: window.__sig, marque: window.__marque, atteint: ${atteint} })`);
JS
cdp31() { node "$AUX/cdp-run.mjs" "$CHROME" "$AUX/r31.js" "$@"; }
temps_sig() { # temps_sig <lab> : médiane de 7 appels de signatureGit (ms), 2 décimales
  node -e "import(process.argv[1]).then(async ({signatureGit})=>{const t=[];let ok=true;for(let i=0;i<8;i++){const a=process.hrtime.bigint();const s=await signatureGit(process.argv[2]);const b=process.hrtime.bigint();if(!s)ok=false;if(i)t.push(Number(b-a)/1e6)}t.sort((x,y)=>x-y);console.log((ok?'':'NULL ')+t[3].toFixed(2))})" "${2:-$SCRIPTS/vf-cockpit-git-signature.mjs}" "$1"
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
# R2 (revue serveur 2026-11-06, S3) : la mesure vise le dépôt de CETTE suite (celui qui contient le dossier du script), jamais un chemin de poste ; hors dépôt : SAUTÉ, jamais un PASS.
# Le plafond est large (250 ms sur la médiane de 7 appels, 3 git par appel) : il garde contre un coût démesuré, pas contre la charge de la machine (48 à 55 ms mesurés sous charge contre un plafond de 50).
# Ce qui rougit sur un `git log` dans la signature n'est pas le temps (un log coûte un git comme un for-each-ref) mais l'argv journalisé : R2.2b et M-LOG.
TF="$(temps_sig "$DEPOT")"
TOP_DEPOT="$("$GIT_REEL" -C "$SCRIPTS" rev-parse --show-toplevel 2>/dev/null || true)"
if [ -n "$TOP_DEPOT" ] && [ -d "$TOP_DEPOT" ]; then TR="$(temps_sig "$TOP_DEPOT")"; else TR=""; fi
echo "  coût mesuré de signatureGit (médiane de 7) : fixture ${TF} ms · dépôt de la suite ${TR:-sans objet} ms"
PLAFOND_SIG_MS=250
assert_eq "R2.3a — le coût de la signature sur la fixture reste sous ${PLAFOND_SIG_MS} ms" "$(node -e "const f=parseFloat(process.argv[1]);console.log(/NULL/.test(process.argv[1])?'nul':(f<${PLAFOND_SIG_MS}?'oui':'non'))" "$TF")" "oui"
if [ -z "$TR" ]; then skip "R2.3b" "la suite ne s'exécute pas dans un dépôt git : coût mesuré sur le dépôt de la suite sans objet"
else assert_eq "R2.3b — le coût de la signature sur le dépôt de la suite reste sous ${PLAFOND_SIG_MS} ms" "$(node -e "const r=parseFloat(process.argv[1]);console.log(/NULL/.test(process.argv[1])?'nul':(r<${PLAFOND_SIG_MS}?'oui':'non'))" "$TR")" "oui"; fi
# M-SIG-LENTE : une signature qui attend 400 ms (un coût démesuré, quel qu'en soit l'auteur) rougit le plafond de R2.3a ; la fixture seule suffit, et la mesure normale reste sous le plafond (témoin R2.3a)
MSL="$(mkmod lente)"; mutate "$MSL/vf-cockpit-git-signature.mjs" "const fin = finDans(echeanceMs);" "await new Promise((r) => setTimeout(r, 400)); const fin = finDans(echeanceMs);" || echo "  ❌ mutation M-SIG-LENTE impossible"
TL="$(temps_sig "$DEPOT" "$MSL/vf-cockpit-git-signature.mjs")"
assert_eq "M-SIG-LENTE — le plafond de ${PLAFOND_SIG_MS} ms rougit sur une signature de plus de 400 ms (mesure : ${TL} ms) : R2.3a rouge pour sa raison (coût), la fixture saine reste verte (${TF} ms)" "$(node -e "const l=parseFloat(process.argv[1]),f=parseFloat(process.argv[2]);console.log((l>=${PLAFOND_SIG_MS})+'|'+(f<${PLAFOND_SIG_MS}))" "$TL" "$TF")" "true|true"

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

echo "=== R5 — audit 2026-11-06 : A5 (git muet : la boucle reste libre, échéance globale, retrait, état distinct) ==="
# Un git qui ne répond pas : include.path de la configuration du dépôt vers un FIFO (git le lit à CHAQUE commande et bloque à l'ouverture). Le FIFO vit dans mktemp -d ; aucun lecteur ni écrivain ne le tient :
# le processus git bloqué est tué par le délai (SIGTERM sur le pid de l'emballage, exec'é en git), et la suite vérifie qu'aucun git du dépôt ne survit.
HG="$WORK/muet"; mkdir -p "$HG"; mk_lab "$HG/lab"; G_ -C "$HG/lab" init -q -b main && G_ -C "$HG/lab" add -A && G_ -C "$HG/lab" commit -q -m init
HGL="$(cd "$HG/lab" && pwd -P)"
mkfifo "$HG/ff"; printf '[include]\n\tpath = %s\n' "$HG/ff" >> "$HGL/.git/config"
mkdir -p "$WORK/bin-h"; printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "%s/hang.log"\nexec "%s" "$@"\n' "$WORK" "$GIT_REEL" > "$WORK/bin-h/git"; chmod +x "$WORK/bin-h/git"
cat > "$AUX/muet.mjs" <<'JS'
// muet.mjs <scripts> <lab> <mode seq|concurrent> <journal> : signatureGit sur un git muet ; une ligne JSON {…} (durées, battement d'un minuteur de 50 ms posé avant l'appel, lancements journalisés)
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , scripts, lab, mode, journal] = process.argv;
const sg = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-git-signature.mjs')).href);
const lancements = () => { try { return fs.readFileSync(journal, 'utf8').split('\n').filter(Boolean).length; } catch { return 0; } };
// battement : un minuteur de 50 ms posé AVANT l'appel ; il ne sonne à l'heure que si la boucle reste libre pendant que git travaille (un git synchrone le retarde de toute sa durée)
const opts = { commun: lab + '/.git', echeanceMs: 700 };
const t0 = Date.now(); let max = null; setTimeout(() => { max = Date.now() - t0; }, 50);
if (mode === 'concurrent') {
  const r = await Promise.all([sg.signatureGit(lab, opts), sg.signatureGit(lab, opts)]); await new Promise((ok) => setTimeout(ok, 150));
  console.log(JSON.stringify({ nulls: r.filter((x) => x === null).length, ms: Date.now() - t0, bloc: max, n: lancements() }));
} else {
  const s1 = await sg.signatureGit(lab, opts); const d1 = Date.now() - t0, n1 = lancements();
  const t1 = Date.now(); const s2 = await sg.signatureGit(lab, opts); const d2 = Date.now() - t1, n2 = lancements(); await new Promise((ok) => setTimeout(ok, 150));
  console.log(JSON.stringify({ s1: s1 === null ? null : 'hex', d1, n1, s2: s2 === null ? null : 'hex', d2, n2, bloc: max }));
}
JS
MUET() { : > "$WORK/hang.log"; PATH="$WORK/bin-h:$PATH" node "$AUX/muet.mjs" "$1" "$2" "$3" "$WORK/hang.log" 2>&1 | tail -1; }
SEQ="$(MUET "$SCRIPTS" "$HGL" seq)"
assert_eq "R5.0 — témoin : un git du dépôt muet ne répond pas ; l'emballage a vu son lancement (la sonde n'est pas aveugle)" "$(jq_ "$SEQ" 'j.n1 >= 1 ? "oui" : "non"')" "oui"
assert_eq "R5.1 — A5 : la signature d'un git muet rend null en moins de 3 s (échéance globale de 700 ms demandée, jamais 20 s) et la boucle reste libre (un minuteur de 50 ms posé avant l'appel sonne en moins de 300 ms)" "$(jq_ "$SEQ" '[j.s1, j.d1 < 3000, j.bloc < 300].join("|")')" "|true|true"
assert_eq "R5.2 — A5 : après l'échec, la signature est en RETRAIT : le second appel rend null sans lancer aucun git (même nombre de lancements, moins de 100 ms)" "$(jq_ "$SEQ" '[j.s2, j.d2 < 100, j.n2 === j.n1].join("|")')" "|true|true"
CON="$(MUET "$SCRIPTS" "$HGL" concurrent)"
assert_eq "R5.3 — A5 : deux ticks simultanés ne lancent qu'un seul jeu de git (le second rend null aussitôt, sans git) : 1 lancement, boucle libre" "$(jq_ "$CON" '[j.n, j.bloc < 300].join("|")')" "1|true"
SAIN="$(MUET "$SCRIPTS" "$DEPOT" seq)"
assert_eq "R5.4 — témoin : sur un dépôt sain, la signature est calculée deux fois de suite (pas de retrait sans git muet), sans latence" "$(jq_ "$SAIN" '[j.s1, j.s2, j.d1 < 1500].join("|")')" "hex|hex|true"
sleep 0.5
assert_eq "R5.5 — aucun git du dépôt muet ne survit aux appels (pgrep)" "$(pgrep -f "$HGL" | wc -l | tr -d ' ')" "0"
cat > "$AUX/lire-muet.mjs" <<'JS'
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , scripts, muet, hors] = process.argv;
const m = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-git.mjs')).href);
const t = Date.now(); const a = (await m.lireGit(muet)).etat; const ms = Date.now() - t; const b = (await m.lireGit(hors)).etat;
console.log(JSON.stringify({ muet: a, hors: b, borne: ms < 13000 }));
JS
mkdir -p "$WORK/sans-depot"
LM="$(node "$AUX/lire-muet.mjs" "$SCRIPTS" "$HGL" "$WORK/sans-depot" 2>&1 | tail -1)"
assert_eq "R5.6 — A5 : lireGit d'un git muet rend « indisponible » (jamais « absent ») dans l'échéance de 15 s (REG-D-01 : une seule borne de lancement de 10 s est subie, l'assemblage s'arrête sur un git muet) ; un lab hors dépôt reste « absent »" "$(jq_ "$LM" '[j.muet, j.hors, j.borne].join("|")')" "indisponible|absent|true"
sleep 0.5
assert_eq "R5.7 — aucun git du dépôt muet ne survit à lireGit (pgrep)" "$(pgrep -f "$HGL" | wc -l | tr -d ' ')" "0"
assert_eq "R5.8 — le direct appelle la signature en asynchrone, graine et filet (les deux appels de signatureGit portent .then) : un git muet ne gèle plus le serveur" "$(grep -c "signatureGit(root, " "$SCRIPTS/vf-cockpit-live.mjs" | tr -d ' ')|$(grep -c "signatureGit(root, { commun: common }).then(" "$SCRIPTS/vf-cockpit-live.mjs" | tr -d ' ')" "2|2"
# mutants A5 : chacun remet le défaut et rougit SA sonde de R5
MA="$(mkmod sansech)"; mutate "$MA/vf-cockpit-git-signature.mjs" "const fin = finDans(echeanceMs);" "const fin = finDans(60000);" || echo "  ❌ mutation M-SANS-ECHEANCE impossible"
R="$(MUET "$MA" "$HGL" seq)"
assert_eq "M-SANS-ECHEANCE — l'échéance globale du tick est retirée : rouge sur R5.1 (la signature d'un git muet dure plus de 3 s ; la boucle, elle, reste libre : le rouge vient de l'échéance)" "$(jq_ "$R" '[j.s1, j.d1 < 3000, j.bloc < 300].join("|")')" "|false|true"
MB="$(mkmod sansret)"; mutate "$MB/vf-cockpit-git-signature.mjs" "if (muet) {" "if (false) {" || echo "  ❌ mutation M-SANS-RETRAIT impossible"
R="$(MUET "$MB" "$HGL" seq)"
assert_eq "M-SANS-RETRAIT — le retrait est retiré : rouge sur R5.2 (le second appel relance un git : plus de lancements, plus de 100 ms)" "$(jq_ "$R" '[j.s2, j.d2 < 100, j.n2 === j.n1].join("|")')" "|false|false"
MC="$(mkmod sansvol)"; mutate "$MC/vf-cockpit-git-signature.mjs" "if (e.enVol || maintenant() < e.jusqu) return null;" "if (maintenant() < e.jusqu) return null;" || echo "  ❌ mutation M-RECOUVREMENT impossible"
R="$(MUET "$MC" "$HGL" concurrent)"
assert_eq "M-RECOUVREMENT — la garde contre le recouvrement est retirée : rouge sur R5.3 (deux jeux de git lancés au lieu d'un)" "$(jq_ "$R" 'j.n')" "2"
MD="$(mkmod syncsig)"
mutate "$MD/vf-cockpit-git-signature.mjs" "import { lancerGitAsync, finDans }" "import { lancerGit, lancerGitAsync, finDans }" && mutate "$MD/vf-cockpit-git-signature.mjs" "await lancerGitAsync(lab, ['for-each-ref', '--format=%(objectname) %(refname)'], { fin })" "lancerGit(lab, ['for-each-ref', '--format=%(objectname) %(refname)'])" || echo "  ❌ mutation M-SIGNATURE-SYNC impossible"
R="$(MUET "$MD" "$HGL" seq)"
assert_eq "M-SIGNATURE-SYNC — le git de la signature redevient synchrone : rouge sur R5.1 (la boucle est gelée : le minuteur de 50 ms ne sonne qu'après 300 ms)" "$(jq_ "$R" 'j.bloc < 300')" "false"
sleep 0.5
assert_eq "R5.9 — aucun git du dépôt muet ne survit aux mutants (pgrep)" "$(pgrep -f "$HGL" | wc -l | tr -d ' ')" "0"
# REG-D-01 : l'état distinct tient par TROIS gardes en profondeur (l'en-tête traduit un git muet en « indisponible », l'assemblage s'arrête dessus, la sonde A5 le redit) ; M-ABSENT les retire toutes
ME="$(mkmod sansdistinct)"; mutate "$ME/vf-cockpit-git.mjs" "if (sonde.delai) return" "if (false) return" && mutate "$ME/vf-cockpit-git.mjs" "vide(muet ? 'indisponible' : 'absent'" "vide('absent'" && mutate "$ME/vf-cockpit-git.mjs" "if (muet) return" "if (false) return" || echo "  ❌ mutation M-ABSENT impossible"
LM="$(node "$AUX/lire-muet.mjs" "$ME" "$HGL" "$WORK/sans-depot" 2>&1 | tail -1)"
assert_eq "M-ABSENT — l'état distinct est retiré : rouge sur R5.6 (un git muet redevient « absent »)" "$(jq_ "$LM" '[j.muet, j.hors].join("|")')" "absent|absent"
sleep 0.5
assert_eq "R5.10 — aucun git du dépôt muet ne survit à M-ABSENT (pgrep)" "$(pgrep -f "$HGL" | wc -l | tr -d ' ')" "0"

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
