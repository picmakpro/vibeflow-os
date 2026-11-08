#!/usr/bin/env bash
# test-cockpit-terminal-xss.sh — la chaîne XSS prolongée jusqu'au terminal : « page P compromise -> serveur Q du terminal -> shell »
# (TERM-12, T16 ; P71-D-10, D-13, D-15, D-18 ; plan 71-08 ; O11 : renvoi depuis l'en-tête de test-cockpit-chaine-xss.sh).
# Hypothèse de T16 : la charge S'EXÉCUTE dans P (échappement et CSP retirés — mutants M-ESC et M-CSP recopiés de test-cockpit-chaine-xss.sh, même
# lab piégé : un PLAN.md dont `wave:` porte une balise <img onerror>). Elle tente, avec le jeton de P : fetch/POST no-cors vers Q, fetch avec
# en-têtes forgés vers Q, lecture du stockage d'un cadre de Q, window.open vers Q (et lecture de son stockage), postMessage vers le cadre. Une
# session légitime (client Node, onglet A, secret de Q) tient le shell ; le succès de la chaîne est un fichier marqueur créé PAR LE SHELL.
# Les trois contrôles de Q sont ceux de controle() et de la session : Origin exacte, secret de session, onglet propriétaire.
#   C0t témoin : Q privée de ses trois contrôles (M-ORIGINE-TERM, M-SECRET-TERM, M-ONGLET-TERM) -> la chaîne ABOUTIT (T16.6) ; sans lui, rien d'autre ne prouve
#   C1t code livré : aucun marqueur, aucun assistant de plus, stockage de Q illisible, postMessage sans effet (T16.1-T16.5)
#   C2t Origin SEULE gardée · C3t secret SEUL gardé · C4t onglet SEUL gardé : chacun, seul, casse la chaîne (T16.7)
# Sans Chrome (ou CHAINE_SANS_NAVIGATEUR=1) : SIMULATION FIDÈLE de la partie HTTP (un client node envoie les mêmes requêtes, Origin de P, jeton de P,
# en-têtes forgés) ; la partie navigateur (T16.0, T16.3-T16.5 : stockage, fenêtre, messages) est annoncée « ⊘ … NON vérifiée, non comptée ».
# Exit 0 si tout passe, 1 sinon.
set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; } # port libre choisi à l'exécution
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"; TA="$HERE_T/terminal-aux.mjs"
ENG="$(cd "$SCRIPTS/../skills/cockpit-moteur" && pwd -P)"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude/scripts" "$WORK/bin"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
export CHROME_SESSION="$HERE_T/chrome-session.mjs"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0; NONVERIF=0
court() { if [ "${#1}" -gt 300 ]; then printf '%s […] %s' "${1:0:140}" "${1: -140}"; else printf '%s' "$1"; fi; }
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$(court "$3")]"; echo "     obtenu:  [$(court "$2")]"; FAIL=$((FAIL+1)); fi; }
nonverif() { echo "  ⊘ $1 — NON vérifiée sans navigateur, non comptée comme réussie"; NONVERIF=$((NONVERIF+1)); }

CHROME=""
for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue
  if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
[ -n "${CHAINE_SANS_NAVIGATEUR:-}" ] && CHROME=""
echo "navigateur : ${CHROME:-aucun (simulation fidèle de la partie HTTP)}"

# shell de test : marqué par son chemin (hygiene.sh le retrouve), bash interactif sans exec, invite « VFP> »
printf "PS1='VFP> '\n" > "$WORK/rc"
printf '#!/bin/sh\nbash --rcfile "%s/rc" -i\n' "$WORK" > "$WORK/bin/shell-test"; chmod +x "$WORK/bin/shell-test"; export SHELL="$WORK/bin/shell-test"
MARQUEUR="$WORK/MARQUEUR-TERMINAL-XSS"

# --- aides node ---
cat > "$AUX/charge.js" <<'JS'
(async () => {
  const X = window.__xss = { debut: true };
  const att = (ms) => new Promise((r) => setTimeout(r, ms));
  try {
    const tok = window.VF_COCKPIT_SERVER.token; X.jeton = !!tok;
    const e = await (await fetch('/api/vf/terminal', { headers: { 'x-vf-cockpit-token': tok } })).json();
    X.etat = e.etat; X.q = e.port; const Q = 'http://127.0.0.1:' + e.port;
    const CMD = 'touch __MARQUEUR__\r';
    try { await fetch(Q + '/entree', { method: 'POST', mode: 'no-cors', body: CMD }); X.nocors = 'envoye'; } catch (x) { X.nocors = x.name; }
    try { const r = await fetch(Q + '/entree', { method: 'POST', headers: { 'X-VF-Terminal': tok, 'X-VF-Onglet': 'forge' }, body: CMD }); X.jetonP = 'reponse ' + r.status; } catch (x) { X.jetonP = x.name; }
    const f = document.createElement('iframe'); f.src = Q + '/?theme=dark';
    await new Promise((ok) => { f.onload = ok; document.body.appendChild(f); setTimeout(ok, 8000); });
    try { f.contentWindow.localStorage.getItem('vf.terminal.secret'); X.stockageCadre = 'lisible'; } catch (x) { X.stockageCadre = x.name; }
    try { f.contentWindow.postMessage('toggle', '*'); f.contentWindow.postMessage('etat:connecte', '*'); X.postMessage = 'envoye'; } catch (x) { X.postMessage = x.name; }
    const w = window.open(Q + '/', '_blank'); X.open = w ? 'ouvert' : 'bloque';
    if (w) { for (let i = 0; i < 80; i++) { try { void w.location.href; } catch (e) { break; } await att(100); } try { w.localStorage.getItem('vf.terminal.secret'); X.stockageFenetre = 'lisible'; } catch (x) { X.stockageFenetre = x.name; } try { w.postMessage('toggle', '*'); } catch (x) { void x; } }
  } catch (x) { X.erreur = String((x && x.message) || x); }
  X.fin = true;
})()
JS
sed "s|__MARQUEUR__|$MARQUEUR|" "$AUX/charge.js" > "$AUX/charge-lab.js"
cat > "$AUX/payload.mjs" <<'JS'
// payload.mjs <charge.js> : la balise <img onerror=eval(atob('…'))> (base64 sans remplissage : la charge est complétée en multiple de 3 octets)
import fs from 'node:fs';
let js = fs.readFileSync(process.argv[2], 'utf8').replace(/\s*\n\s*/g, ' ').trim(); while (Buffer.byteLength(js) % 3) js += ' ';
console.log(`<img src=x onerror=eval(atob('${Buffer.from(js).toString('base64')}'))>`);
JS
cat > "$AUX/xss.mjs" <<'JS'
// xss.mjs <chrome> <url> : ouvre la page P piégée en Chrome headless, attend la fin de la charge (window.__xss.fin), rend window.__xss (UNE ligne JSON)
import { pathToFileURL } from 'node:url';
const { executer } = await import(pathToFileURL(process.env.CHROME_SESSION).href);
const [, , chrome, url] = process.argv;
await executer(chrome, async (s) => {
  await s.naviguer(url);
  await s.attendre('!!(window.__xss && window.__xss.debut)', 'la charge de P s\'exécute (window.__xss.debut)', 25000);
  await s.attendre('!!window.__xss.fin', 'fin de la charge de P (window.__xss.fin)', 40000);
  const res = await s.ev('JSON.parse(JSON.stringify(window.__xss))');
  // la même tentative window.open, cette fois avec un geste utilisateur (le bloqueur de fenêtres de Chrome ne l'arrête plus) : la fenêtre s'ouvre-t-elle, son stockage est-il lisible ?
  const g = await s.send('Runtime.evaluate', { userGesture: true, awaitPromise: true, returnByValue: true, expression: `(async () => {
    const w = window.open('http://127.0.0.1:' + window.__xss.q + '/', '_blank'); if (!w) return { open: 'bloque' };
    for (let i = 0; i < 80; i++) { try { void w.location.href; } catch (e) { break; } await new Promise((r) => setTimeout(r, 100)); } let st; try { w.localStorage.getItem('vf.terminal.secret'); st = 'lisible'; } catch (x) { st = x.name; }
    try { w.postMessage('toggle', '*'); } catch (x) { void x; } return { open: 'ouvert', stockage: st }; })()` });
  res.geste = g && g.result && g.result.value;
  return res;
}, { csp: false });
JS
cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
rj() { printf '%s\n' "$1" | node "$AUX/ev.mjs" "$2" 2>/dev/null; }

# --- lab piégé (celui de test-cockpit-chaine-xss.sh, charge différente) ---
PAYLOAD="$(node "$AUX/payload.mjs" "$AUX/charge-lab.js")"
LAB="$WORK/lab"; mkdir -p "$LAB/src" "$LAB/.planning/phases/01-x"
printf 'export const util = () => 1;\n' > "$LAB/src/util.js"
printf -- '- [ ] **Phase 1: Socle** - premier jet\n' > "$LAB/.planning/ROADMAP.md"
printf -- '---\nwave: %s\n---\n<objective>Faire le socle</objective>\n' "$PAYLOAD" > "$LAB/.planning/phases/01-x/01-01-PLAN.md"
git -C "$LAB" init -q && git -C "$LAB" add -A && git -C "$LAB" -c user.email=t@t -c user.name=t commit -q -m init
node "$SCRIPTS/vf-cockpit-build.mjs" "$LAB" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
SORTIE="$LAB/.vibeflow/cockpit"
[ -f "$SORTIE/vf-cockpit-terminal.mjs" ] || echo "  ❌ la sortie construite ne porte pas vf-cockpit-terminal.mjs" >&2

# mutant <sortie> <M-ESC|M-CSP|M-ORIGINE-TERM|M-SECRET-TERM|M-ONGLET-TERM> : échoue si rien n'a changé (jamais un mutant sans effet)
mutant() {
  local o="$1" m="$2" before after
  before="$(cat "$o/serve.mjs" "$o/index.html" "$o/project.html" "$o/vf-cockpit-terminal-processus.mjs" "$o/vf-cockpit-terminal-session.mjs" | cksum)"
  case "$m" in
    M-ESC) for f in index.html project.html; do sed -i.bak 's#<span class="meta">${h(size)}</span>#<span class="meta">${size}</span>#' "$o/$f"; done ;;
    M-CSP) sed -i.bak "s#res.setHeader('Content-Security-Policy'#res.setHeader('X-Mutant-Csp'#g" "$o/serve.mjs" ;;
    M-ORIGINE-TERM) sed -i.bak "s/if (!page \&\& !navigateur) return /if (false) return /; s/else if (o !== origineQ())/else if (false)/" "$o/vf-cockpit-terminal-processus.mjs" ;;
    M-SECRET-TERM) sed -i.bak "s/if (!egal(req.headers\['x-vf-terminal'\], secret)) return refus(res, 401, 'secret');//" "$o/vf-cockpit-terminal-processus.mjs" ;;
    M-ONGLET-TERM) sed -i.bak "s/if (s.onglet !== onglet) return 409;//g" "$o/vf-cockpit-terminal-session.mjs" ;;
  esac
  after="$(cat "$o/serve.mjs" "$o/index.html" "$o/project.html" "$o/vf-cockpit-terminal-processus.mjs" "$o/vf-cockpit-terminal-session.mjs" | cksum)"
  [ "$before" != "$after" ] || { echo "  ❌ mutant $m sans effet (motif absent de la sortie)" >&2; return 1; }
}
nassistants() { ps -eo pid=,ppid=,args= | awk -v p="$1" '$2 == p && /vf-cockpit-pty\.py/ { n++ } END { print n + 0 }'; } # assistants du serveur (ancien étage)
# P71-D-33 : les assistants sont désormais enfants du processus du terminal, lui-même enfant du serveur
assistants_srv() { local c n=0; for c in $(pgrep -P "$1" 2>/dev/null); do ps -o command= -p "$c" 2>/dev/null | grep -q 'vf-cockpit-terminal-processus.mjs' && n=$((n + $(nassistants "$c"))); done; echo $((n + $(nassistants "$1"))); }

# manche <étiquette> <mutants...> : sortie copiée, mutants posés, serveur avec --terminal, session légitime, charge jouée, effets relevés
# résultat : R_MARQUEUR R_AV R_AP R_ETAT R_XSS (JSON de la charge, ou { erreur })
manche() {
  local label="$1"; shift
  local o="$WORK/sortie-$label"; rm -rf "$o"; cp -R "$SORTIE" "$o"
  local m; for m in "$@"; do mutant "$o" "$m" || { R_MARQUEUR="mutant-sans-effet"; return; }; done
  rm -f "$MARQUEUR" "$o/.cache/server.json"; mkdir -p "$o/.cache"
  local amorce; amorce="$(node -e "console.log(require('crypto').randomBytes(24).toString('hex'))")"; (umask 077; printf '%s' "$amorce" > "$o/.cache/terminal-amorce"; printf '%s' "$amorce" > "$WORK/amorce.copy")
  ( cd "$LAB" && VF_COCKPIT_ENGINE_DIR="$ENG" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS" exec node "$o/serve.mjs" --no-open --terminal --port "$(libre)" > "$WORK/serve-$label.out" 2>&1 ) </dev/null >/dev/null 2>&1 &
  local pid=$!; PIDS+=($pid)
  for _ in $(seq 1 100); do grep -q '"terminal"' "$o/.cache/server.json" 2>/dev/null && break; sleep 0.1; done
  local port q sec _c; port="$(node "$AUX/ev.mjs" j.port < "$o/.cache/server.json")"; q="$(node "$AUX/ev.mjs" '(j.terminal&&j.terminal.url)||""' < "$o/.cache/server.json")"; q="${q##*:}"
  read -r _c sec < <(node "$TA" amorcer "$q" "$WORK/amorce.copy" | tr '\n' ' ')
  [[ "$sec" =~ ^[0-9a-f]{64}$ ]] || { R_MARQUEUR="session-impossible"; vf_hyg_stop "$pid"; return; }
  node "$TA" flux "$q" "$sec" onglet-A "$WORK/flux-$label.bin" 120000 > "$WORK/flux-$label.log" 2>&1 & local fpid=$!; PIDS+=($fpid)
  [ "$(node "$TA" attendre "$WORK/flux-$label.bin" 'VFP> ' 15000)" = TROUVE ] || { R_MARQUEUR="pas-d-invite"; vf_hyg_stop "$fpid"; vf_hyg_stop "$pid"; return; }
  R_AV="$(assistants_srv "$pid")"
  if [ -n "$CHROME" ]; then
    R_XSS="$(node "$AUX/xss.mjs" "$CHROME" "http://127.0.0.1:$port/project.html#v=n:ph-1")"
  else
    # simulation : les requêtes HTTP de la charge, avec l'Origin de P, sans secret (no-cors) puis avec le jeton de P et un onglet forgé
    local tok; tok="$(node -e "
      const http=require('http');http.get({host:'127.0.0.1',port:$port,path:'/project.html',headers:{Host:'127.0.0.1:$port'}},r=>{let b='';r.on('data',c=>b+=c);r.on('end',()=>{const m=/VF_COCKPIT_SERVER=\{\"token\":\"([0-9a-f]*)\"/.exec(b);console.log(m?m[1]:'')})})")"
    local a b
    a="$(node "$TA" req "$q" POST /entree --origin "http://127.0.0.1:$port" --corps "touch $MARQUEUR\\r" | sed -n 1p)"
    b="$(node "$TA" req "$q" POST /entree --origin "http://127.0.0.1:$port" --secret "$tok" --onglet forge --corps "touch $MARQUEUR\\r" | sed -n 1p)"
    R_XSS="{\"simule\":true,\"nocors\":\"$a\",\"jetonP\":\"$b\",\"jeton\":$([ -n "$tok" ] && echo true || echo false)}"
  fi
  # l'effet (fichier créé par le shell) est ATTENDU quand la manche doit l'obtenir, sinon on laisse seulement une courte grâce pour constater l'absence
  local fin=$((SECONDS + 3)); [ "$label" = "temoin" ] && fin=$((SECONDS + ${VF_CDP_ECHEANCE_S:-30}))
  while [ "$SECONDS" -lt "$fin" ] && [ ! -e "$MARQUEUR" ]; do sleep 0.2; done
  R_MARQUEUR=non; [ -e "$MARQUEUR" ] && R_MARQUEUR=oui
  R_AP="$(assistants_srv "$pid")"
  R_ETAT="$(node "$TA" etat "$q" "$sec" | sed -n 3p | node "$AUX/ev.mjs" 'j.session' 2>/dev/null)"
  echo "     [$label] mesure : marqueur-créé-par-le-shell=$R_MARQUEUR assistants=$R_AV/$R_AP session=$R_ETAT charge=${R_XSS:0:300}"
  vf_hyg_stop "$fpid"; vf_hyg_stop "$pid"
}
charge_ok() { if [ -n "$CHROME" ]; then assert_eq "T16.0 [$1] — la charge s'exécute dans P compromise (drapeau posé par la charge, jeton de P lu, état du terminal lu)" "$(rj "$R_XSS" 'j.erreur||("debut="+j.debut+" jeton="+j.jeton+" terminal="+j.etat)')" "debut=true jeton=true terminal=actif"; else nonverif "T16.0 [$1] la charge s'exécute dans P"; fi; }

echo "=== C0t — témoin : Q privée de ses trois contrôles (Origin, secret, onglet), la chaîne doit ABOUTIR ==="
manche temoin M-ESC M-CSP M-ORIGINE-TERM M-SECRET-TERM M-ONGLET-TERM
assert_eq "C0t — la manche s'est jouée (mutants avec effet, session légitime établie)" "$([ "$R_MARQUEUR" = oui ] || [ "$R_MARQUEUR" = non ] && echo oui || echo "$R_MARQUEUR")" "oui"
charge_ok C0t
assert_eq "T16.6 — Q sans ses trois contrôles : le marqueur est créé PAR LE SHELL (la chaîne peut aboutir : sans ce témoin, les manches suivantes ne prouvent rien)" "$R_MARQUEUR" "oui"
if [ "$R_MARQUEUR" != oui ]; then echo "  ❌ chaîne incapable d'aboutir : les autres manches ne prouvent rien" >&2; fi

echo "=== C1t — code livré (P compromise : M-ESC et M-CSP) : la chaîne n'aboutit pas ==="
manche livre M-ESC M-CSP
charge_ok C1t
assert_eq "T16.1 — aucun marqueur créé par le shell (no-cors, jeton de P, en-têtes forgés)" "$R_MARQUEUR" "non"
assert_eq "T16.2 — nombre d'assistants PTY inchangé (1 avant la charge, 1 après)" "$R_AV/$R_AP" "1/1"
if [ -n "$CHROME" ]; then
  assert_eq "T16.3 — depuis P, le stockage du cadre de Q lève SecurityError (le secret de Q reste illisible)" "$(rj "$R_XSS" 'j.stockageCadre')" "SecurityError"
  assert_eq "T16.4a — window.open de la charge (sans geste) vers Q : bloqué par Chrome, ou stockage de la fenêtre en SecurityError" "$(rj "$R_XSS" 'j.open==="bloque"||j.stockageFenetre==="SecurityError"')" "true"
  assert_eq "T16.4 — window.open vers Q AVEC geste (le bloqueur ne l'arrête plus) : la fenêtre s'ouvre (témoin) et son stockage lève SecurityError ; aucun assistant de plus, aucun marqueur" "$(rj "$R_XSS" '(j.geste&&j.geste.open)+"/"+(j.geste&&j.geste.stockage)')/$R_AV/$R_AP/$R_MARQUEUR" "ouvert/SecurityError/1/1/non"
  assert_eq "T16.5 — postMessage de la charge vers le cadre de Q : envoyé sans effet (session toujours vivante, aucun marqueur)" "$(rj "$R_XSS" 'j.postMessage')/$R_ETAT/$R_MARQUEUR" "envoye/vivante/non"
else nonverif "T16.3-T16.5 (stockage, fenêtre, messages)"; fi

echo "=== C2t-C4t — un seul contrôle de Q gardé : chacun, seul, casse la chaîne ==="
manche origine M-ESC M-CSP M-SECRET-TERM M-ONGLET-TERM
charge_ok C2t
assert_eq "T16.7 [C2t] — Origin SEULE gardée (secret et onglet retirés) : aucun marqueur" "$R_MARQUEUR" "non"
manche secret M-ESC M-CSP M-ORIGINE-TERM M-ONGLET-TERM
charge_ok C3t
assert_eq "T16.7 [C3t] — secret SEUL gardé (Origin et onglet retirés) : aucun marqueur" "$R_MARQUEUR" "non"
manche onglet M-ESC M-CSP M-ORIGINE-TERM M-SECRET-TERM
charge_ok C4t
assert_eq "T16.7 [C4t] — onglet SEUL gardé (Origin et secret retirés) : aucun marqueur" "$R_MARQUEUR" "non"

vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL ($NONVERIF non vérifiées sans navigateur)"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
