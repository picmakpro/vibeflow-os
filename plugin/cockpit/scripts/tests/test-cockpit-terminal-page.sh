#!/usr/bin/env bash
# test-cockpit-terminal-page.sh — page du terminal servie par Q : assemblage, CSP, thème, variables Graphite, police,
# intégrité du vendor au démarrage (TERM-05, TERM-10, T18 de TERM-12 ; P71-D-15, D-16, D-19 ; UI-SPEC F3, F7).
#   PQ  assemblage : quatre <script> sans attribut, le moteur xterm dans le premier, xterm.css dans un <style>, aucun <link>
#   T9  en-têtes de GET / de Q : directives exactes, aucun X-Frame-Options, nosniff / no-referrer / no-store, thème clair idem
#   TS  aucun <script> à attribut ; le <style> de xterm a le sha256 épinglé de xterm.css
#   TH  thème par ?theme= à liste fermée, valeur jamais reflétée, aucun autre paramètre ne change la page
#   TF  JetBrains Mono embarquée en data:font/woff2 (latin, latin-ext, traits de boîte 2.304), octets égaux aux fichiers vendorisés
#   TV  un octet du vendor (ou SHA256SUMS) altéré : le terminal refuse de démarrer
#   T18 parité des 41 variables (25 Graphite + 16 d'espacement 71.5) avec viewer.html, sombre et clair, jamais sur un ensemble vide
#   T19 parité de la palette xterm de vue.mjs avec viewer.html (J10 de la critique 71 : les 15 couleurs de l'UI-SPEC §4.2 qui ont une variable Graphite
#       d'origine, par thème, jamais sur un ensemble vide)
#   M-* mutants (copies de la sortie) : M-ANCETRES, M-XFO, M-EMPREINTE, M-THEME, M-PARITE (a à f), M-PALETTE (a à d)
# Aucun navigateur : serveur lancé directement avec --terminal, pages lues par terminal-aux.mjs. Exit 0 si tout passe, 1 sinon.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
ENG="$SCRIPTS/../skills/cockpit-moteur"; TA="$HERE_T/terminal-aux.mjs"; VIEWER="$ENG/assets/viewer.html"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude/scripts" "$WORK/run"
export HOME="$WORK/home"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
. "$(dirname "$0")/socle-serveur.sh"
# écouteurs du serveur ET de son processus du terminal (Q y écoute, P71-D-33) ; lignes vides écartées
ecoutes_srv() { local c; { node "$TA" ecoutes "$1"; for c in $(command pgrep -P "$1"); do ps -o command= -p "$c" 2>/dev/null | grep -q 'vf-cockpit-terminal-processus.mjs' && node "$TA" ecoutes "$c"; done; } | sed '/^$/d'; }
PASS=0; FAIL=0
court() { if [ "${#1}" -gt 300 ]; then printf '%s […] %s' "${1:0:140}" "${1: -140}"; else printf '%s' "$1"; fi; }
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$(court "$3")]"; echo "     obtenu:  [$(court "$2")]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [$(court "$2")]"; FAIL=$((FAIL+1)); fi; }
assert_not() { if [[ "$2" != *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     sous-chaîne interdite: [$3]"; echo "     obtenu:  [$(court "$2")]"; FAIL=$((FAIL+1)); fi; }

cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/csp.mjs" <<'JS'
// csp.mjs <cmd> … : lectures de la page de Q, recalculées ici (jamais par le module testé)
import fs from 'node:fs'; import crypto from 'node:crypto';
const [, , cmd, ...a] = process.argv;
const sha = (b) => crypto.createHash('sha256').update(b).digest('hex');
const html = () => fs.readFileSync(a[0], 'utf8');
const scripts = (h) => [...h.matchAll(/<script>([\s\S]*?)<\/script>/g)].map((m) => m[1]);
if (cmd === 'carte') { // CSP -> « directive: valeurs triées », une par ligne, triées
  console.log(a[0].split(';').map((s) => s.trim()).filter(Boolean).map((s) => { const i = s.indexOf(' '); return i < 0 ? `${s}:` : `${s.slice(0, i)}: ${s.slice(i + 1).trim().split(/\s+/).sort().join(' ')}`; }).sort().join('\n'));
} else if (cmd === 'attendue') { // a = page, b = origine de P
  const h = [...new Set(scripts(html()).map((s) => `'sha256-${crypto.createHash('sha256').update(s).digest('base64')}'`))].join(' ');
  console.log(`default-src 'none'; script-src ${h}; style-src 'unsafe-inline'; connect-src 'self'; font-src data:; img-src data:; frame-ancestors ${a[1]}; base-uri 'none'; form-action 'none'; object-src 'none'`);
} else if (cmd === 'scripts') {
  const h = html(), s = scripts(h);
  console.log(`n=${s.length} autres=${(h.match(/<script\b(?!>)/gi) || []).length} s1=${s[0] === undefined ? '' : sha(s[0])} s2=${s[1] === undefined ? '' : sha(s[1])}`);
} else if (cmd === 'styles') { for (const m of html().matchAll(/<style>([\s\S]*?)<\/style>/g)) console.log(sha(m[1]));
} else if (cmd === 'dansstyle') { console.log([...html().matchAll(/<style>([\s\S]*?)<\/style>/g)].filter((m) => m[1].includes(a[1])).length);
} else if (cmd === 'liens') { console.log((html().match(/<link\b/gi) || []).length);
} else if (cmd === 'balise') { console.log((html().match(/<html[^>]*>/) || ['aucune'])[0]);
} else if (cmd === 'polices') {
  const h = html(); const n = (h.match(/@font-face\s*\{[^}]*font-family:\s*"JetBrains Mono"[^}]*src:\s*url\(data:font\/woff2;base64,/g) || []).length;
  console.log(`n=${n}`); console.log([...h.matchAll(/url\(data:font\/woff2;base64,([A-Za-z0-9+/=]+)\)/g)].map((m) => sha(Buffer.from(m[1], 'base64'))).sort().join('\n'));
} else if (cmd === 'sha') { console.log(sha(fs.readFileSync(a[0])));
} else { process.exit(64); }
JS
cat > "$AUX/parite.mjs" <<'JS'
// parite.mjs <viewer.html> <page.html> : valeur effective des 41 variables recopiées, par thème (sombre = :root, clair = :root puis la redéclaration)
import fs from 'node:fs';
const NOMS = ['--ink', '--surface', '--raise', '--raise-2', '--hair', '--hair-2', '--text', '--text-2', '--text-3', '--text-4', '--on', '--on-hover', '--on-text', '--ring', '--recent', '--sev-medium', '--sev-high', '--warn-bg', '--warn-text', '--err-text', '--r-card', '--r-ctl', '--sans', '--mono', '--ease',
  '--sp-2', '--sp-4', '--sp-6', '--sp-8', '--sp-12', '--sp-16', '--sp-20', '--sp-24', '--sp-32', '--edge', '--inset-panel', '--gap-section', '--inset-card', '--inset-box', '--inset-row', '--inset-pill'];
const decl = (css, sel) => Object.fromEntries([...(new RegExp(sel.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '\\s*{([^}]*)}').exec(css)?.[1] || '').matchAll(/(--[\w-]+)\s*:\s*([^;]+);/g)].map((m) => [m[1], m[2].trim().toLowerCase().replace(/\s+/g, ' ')]));
const lire = (f) => { const css = fs.readFileSync(f, 'utf8').replace(/\/\*[\s\S]*?\*\//g, ''); return { s: decl(css, ':root'), c: decl(css, ':root[data-theme="light"]') }; };
const V = lire(process.argv[2]), Q = lire(process.argv[3]);
const eff = (S, theme, nom) => (theme === 'clair' && nom in S.c ? S.c[nom] : S.s[nom]);
const n = { sombre: 0, clair: 0 };
for (const theme of ['sombre', 'clair']) for (const nom of NOMS) {
  const v = eff(V, theme, nom), q = eff(Q, theme, nom);
  if (v === undefined || q === undefined) { if (v === undefined) console.log(`ABSENTE ${nom} viewer.html ${theme}`); if (q === undefined) console.log(`ABSENTE ${nom} Q ${theme}`); continue; }
  n[theme]++; if (v !== q) console.log(`variable ${nom} (${theme}) : viewer.html=${v}, Q=${q}`);
}
console.log(`PARITE ${n.sombre}/${n.clair}`);
JS
cat > "$AUX/palette.mjs" <<'JS'
// palette.mjs <viewer.html> <vue.mjs> : la palette xterm de vue.mjs contre les variables Graphite de viewer.html, par thème. Seules les couleurs que l'UI-SPEC §4.2
// donne comme venant d'une variable (colonne « Origine ») sont comparées ; les autres (éclaircies, voiles) n'ont pas de variable d'origine.
// 71.5 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-06 : « Adoucir le terminal seul ») : en SOMBRE, yellow (#f0d17c, 11,8:1 sur --surface) et brightYellow (#e3df78, 12,6:1) ne sont plus liés à --sev-medium / --warn-text : une origine `=#rrggbb` est une valeur attendue littérale, comparée telle quelle ; le jeton de l'interface garde #ffe08a.
// 71.5 : une origine `[sombre, clair]` est sensible au thème (l'ANSI clair est du TEXTE : red, green, yellow lisent les variantes --*-text, 4,5:1 ; le contrôle reste, il compare une autre variable).
import fs from 'node:fs'; import { pathToFileURL } from 'node:url';
const ORIGINE = { background: '--surface', foreground: '--text', cursor: '--on', cursorAccent: '--on-text', red: ['--sev-high', '--err-text'], green: ['--recent', '--recent-text'], yellow: ['=#f0d17c', '--warn-text'],
  blue: '--k-http', magenta: '--k-call', cyan: '--k-data', white: '--text-2', brightBlack: '--text-3', brightRed: '--err-text', brightYellow: ['=#e3df78', '--warn-text'], brightWhite: '--text' };
const norm = (v) => { v = String(v).trim().toLowerCase().replace(/\s+/g, ' '); const m = /^#([0-9a-f])([0-9a-f])([0-9a-f])$/.exec(v); return m ? `#${m[1]}${m[1]}${m[2]}${m[2]}${m[3]}${m[3]}` : v; };
const decl = (css, sel) => Object.fromEntries([...(new RegExp(sel.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '\\s*{([^}]*)}').exec(css)?.[1] || '').matchAll(/(--[\w-]+)\s*:\s*([^;]+);/g)].map((m) => [m[1], norm(m[2])]));
const css = fs.readFileSync(process.argv[2], 'utf8').replace(/\/\*[\s\S]*?\*\//g, ''); const V = { s: decl(css, ':root'), c: decl(css, ':root[data-theme="light"]') };
globalThis.window = {}; const m = await import(pathToFileURL(process.argv[3]).href); m.vueTerminal({});
const n = { sombre: 0, clair: 0 };
for (const theme of ['sombre', 'clair']) {
  const pal = window.vfTermVue.theme(theme === 'clair');
  for (const [cle, orig] of Object.entries(ORIGINE)) {
    const nom = Array.isArray(orig) ? orig[theme === 'clair' ? 1 : 0] : orig;
    const v = nom.startsWith('=') ? norm(nom.slice(1)) : theme === 'clair' && nom in V.c ? V.c[nom] : V.s[nom], q = pal[cle] === undefined ? undefined : norm(pal[cle]);
    if (v === undefined) { console.log(`ABSENTE ${nom} viewer.html ${theme}`); continue; }
    if (q === undefined) { console.log(`ABSENTE ${cle} palette ${theme}`); continue; }
    n[theme]++; if (v !== q) console.log(`couleur ${cle} (${theme}) : viewer.html ${nom}=${v}, palette=${q}`);
  }
}
console.log(`PALETTE ${n.sombre}/${n.clair}`);
JS
cat > "$AUX/pagegen.mjs" <<'JS'
// pagegen.mjs <sortie> <moteur> <theme> <fichier> : page et CSP rendues par le module de la sortie (sans serveur) ; CSP dans <fichier>.csp
import { pathToFileURL } from 'node:url'; import fs from 'node:fs';
const [, , sortie, moteur, theme, out] = process.argv;
const m = await import(pathToFileURL(`${sortie}/vf-cockpit-terminal-page.mjs`).href);
m.preparerPage({ engineDir: moteur }); const r = m.pageTerminal({ theme, origineP: 'http://127.0.0.1:4242' });
fs.writeFileSync(out, r.html); fs.writeFileSync(`${out}.csp`, r.csp);
JS

rq() { node "$TA" req "$@"; }
amorce_neuve() { node -e "console.log(require('crypto').randomBytes(24).toString('hex'))"; }
mklab() {
  local L="$1" B="$1/.planning"; mkdir -p "$L/src" "$B/phases/01-socle"; printf 'export const u = 1;\n' > "$L/src/u.js"
  printf -- '## Phases\n\n- [x] **Phase 1: Socle** - premier jet\n\n### Phase 1: Socle\n**Goal**: Poser le socle\n' > "$B/ROADMAP.md"
  printf -- '---\nstatus: executing\ncurrent_phase: 1\nmilestone: v1.0 MVP\n---\n' > "$B/STATE.md"
  printf -- '---\nwave: 1\nfiles_modified: [src/u.js]\n---\n<objective>Poser le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  node "$SCRIPTS/vf-cockpit.mjs" build --lab "$L" > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
}
SRVN=0
srv() { # srv <sortie> <0|1 terminal> [moteur] -> SRV_PORT SRV_PID SRV_O SRV_OUT
  local o="$1" term="${2:-0}" eng="${3:-$ENG}" lab; lab="$(cd "$1/../.." && pwd)"
  SRVN=$((SRVN+1)); SRV_O="$o"; SRV_OUT="$WORK/serve-$SRVN-$RANDOM.out"; rm -f "$o/.cache/server.json" "$o/.cache/terminal-amorce"
  local flag=(); mkdir -p "$o/.cache"
  if [ "$term" = 1 ]; then flag=(--terminal); (umask 077; amorce_neuve > "$o/.cache/terminal-amorce"); fi
  COCKPIT_LOG="$SRV_OUT" cockpit_lancer "$lab" VF_COCKPIT_ENGINE_DIR="$eng" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS" ${flag[@]+"${flag[@]}"}
  if [ "$term" = 1 ]; then attendre 5 grep -qs '"terminal"' "$o/.cache/server.json"; fi # la clé terminal manque quand le moteur refuse l'assistant : attente bornée, sans échec
  SRV_PID="$VF_PID"; SRV_PORT="${VF_PORT:-0}"; SRV_TOK="$VF_JETON"
}
sj() { node "$AUX/ev.mjs" "$1" < "$SRV_O/.cache/server.json" 2>/dev/null; }
unsrv() { vf_hyg_stop "$SRV_PID"; }
nlignes() { printf '%s\n' "$1" | grep -c . ; }
mutant() { # mutant <nom> <fichier-relatif-à-la-sortie> <expression-sed> -> MUT_OUT ; code 1 si la cible manque ou si la copie n'a pas changé
  local d="$WORK/mut-$1" f; rm -rf "$d"; mkdir -p "$d"; cp -R "$LAB/.planning" "$d/.planning"; cp -R "$LAB/.vibeflow" "$d/.vibeflow"
  MUT_OUT="$d/.vibeflow/cockpit"; f="$MUT_OUT/$2"; [ -f "$f" ] || return 1
  cp "$f" "$f.orig"; sed -i.bak "$3" "$f"; local r=0; cmp -s "$f" "$f.orig" && r=1; rm -f "$f.orig" "$f.bak"; return $r
}
carte() { node "$AUX/csp.mjs" carte "$1"; }
entete() { sed -n 2p "$1" | node "$AUX/ev.mjs" "$2"; } # entete <sortie de rq> <expression sur j>
etat_p() { rq "$SRV_PORT" GET /api/vf/terminal --jeton "$SRV_TOK" | sed '1,2d'; }
LAB="$WORK/lab"; mklab "$LAB"; OUT="$LAB/.vibeflow/cockpit"
PIN_JS=14903579ff54664cd72f8e8699e6961a6272c21863ec1c3b118cdc8af5d4a972; PIN_CSS=854a7c0fb70e8b1a083c16797ab827299fb18744f5ad34f227b48337e33293c6; PIN_FIT=ba3ea256ce0620a0992a197d6c9baea64823fc93d8da07a9e366ca9943c18527

echo "=== PQ / T9 / TS / TH / TF / T18 — page de Q servie ==="
srv "$OUT" 1; P=$SRV_PORT; QURL="$(sj '(j.terminal&&j.terminal.url)||"absente"')"; Q="${QURL##*:}"; OP="http://127.0.0.1:$P"
assert_eq "PQ.0 — témoin : Q répond (clé terminal de server.json)" "$([[ "$QURL" =~ ^http://127\.0\.0\.1:[0-9]+$ ]] && echo oui || echo "non : $QURL")" "oui"
Q="${Q:-1}"; PG="$WORK/q"; mkdir -p "$PG"
page() { rq "$Q" GET "$2" --corps-vers "$PG/$1.html" > "$PG/$1.out"; } # page <nom> <chemin>
page dark /; page light '/?theme=light'
CSP="$(entete "$PG/dark.out" 'j["content-security-policy"]')"; CSPL="$(entete "$PG/light.out" 'j["content-security-policy"]')"
assert_eq "PQ.1 — GET / de Q : quatre <script> sans attribut, aucun autre, le 1er = xterm.js et le 2e = addon-fit.js (sha256 épinglés)" "$(node "$AUX/csp.mjs" scripts "$PG/dark.html")" "n=4 autres=0 s1=$PIN_JS s2=$PIN_FIT"
assert_eq "PQ.1 — la CSP porte quatre empreintes recalculées" "$(printf '%s' "$CSP" | grep -o "'sha256-" | grep -c .)" "4"
assert_eq "PQ.2 — xterm.css est dans un <style> (sélecteur .xterm-helper-textarea) et aucun <link>" "dansstyle=$(node "$AUX/csp.mjs" dansstyle "$PG/dark.html" .xterm-helper-textarea) liens=$(node "$AUX/csp.mjs" liens "$PG/dark.html")" "dansstyle=1 liens=0"
for t in dark light; do
  C="$CSP"; N=""; [ "$t" = light ] && { C="$CSPL"; N=" (?theme=light)"; }
  assert_eq "T9.1$N — directives exactes (carte nom -> valeurs), frame-ancestors = origine de P" "$(carte "$C")" "$(carte "$(node "$AUX/csp.mjs" attendue "$PG/$t.html" "$OP")")"
  assert_eq "T9.2$N — aucun x-frame-options (témoin : la CSP est là)" "$(entete "$PG/$t.out" '"xfo="+Object.keys(j).filter(k=>k==="x-frame-options").length+" csp="+Object.keys(j).filter(k=>k==="content-security-policy").length')" "xfo=0 csp=1"
  assert_eq "T9.3$N — nosniff, no-referrer, no-store" "$(entete "$PG/$t.out" 'j["x-content-type-options"]+","+j["referrer-policy"]+","+j["cache-control"]')" "nosniff,no-referrer,no-store"
  assert_not "T9.1$N — aucun unsafe-eval" "$C" "unsafe-eval"
done
assert_eq "T9.4 — le thème clair ne change pas les directives (hors empreintes)" "$(carte "$CSPL" | grep -v '^script-src')" "$(carte "$CSP" | grep -v '^script-src')"
assert_eq "TS.1 — aucun <script> à attribut ni externe (autres=0, avec 4 scripts)" "$(node "$AUX/csp.mjs" scripts "$PG/dark.html" | sed 's/ s1=.*//')" "n=4 autres=0"
assert_eq "TS.2 — un <style> a le sha256 épinglé de xterm.css (octet pour octet)" "$(node "$AUX/csp.mjs" styles "$PG/dark.html" | grep -c -x "$PIN_CSS")" "1"
assert_eq "TH.1 — ?theme=light : <html> porte data-theme=\"light\"" "$(node "$AUX/csp.mjs" balise "$PG/light.html")" '<html lang="fr" data-theme="light">'
page dark2 '/?theme=dark'
assert_eq "TH.2 — thème absent et dark : aucun data-theme" "$(node "$AUX/csp.mjs" balise "$PG/dark.html") | $(node "$AUX/csp.mjs" balise "$PG/dark2.html")" '<html lang="fr"> | <html lang="fr">'
MARQ="th-$RANDOM$RANDOM"; page maj '/?theme=LIGHT'; page vide '/?theme='; page bal "/?theme=%22%3E%3Cb%3E$MARQ"
assert_eq "TH.3 — LIGHT, vide, valeur balisée : sombre (aucun data-theme)" "$(for n in maj vide bal; do node "$AUX/csp.mjs" balise "$PG/$n.html"; done | sort -u)" '<html lang="fr">'
assert_eq "TH.3 — la valeur balisée n'est reflétée nulle part (corps)" "$(grep -c -F "$MARQ" "$PG/bal.html" || true)" "0"
page orig "/?origineP=http://evil.test:9&theme=dark"
assert_eq "TH.4 — ?origineP=… sans effet : même page, même CSP" "$(node "$AUX/csp.mjs" sha "$PG/orig.html") $(entete "$PG/orig.out" 'j["content-security-policy"]')" "$(node "$AUX/csp.mjs" sha "$PG/dark.html") $CSP"
POL="$(node "$AUX/csp.mjs" polices "$PG/dark.html")"
assert_eq "TF.1 — trois @font-face JetBrains Mono en data:font/woff2;base64 (latin, latin-ext, traits de boîte)" "$(printf '%s\n' "$POL" | sed -n 1p)" "n=3"
V1="$ENG/assets/vendor/fonts/jetbrains-mono-latin-wght-normal.woff2"; V2="$ENG/assets/vendor/fonts/jetbrains-mono-latin-ext-wght-normal.woff2"; V3="$ENG/assets/vendor/fonts/jetbrains-mono-2.304-regular.woff2"
assert_eq "TF.2 — octets décodés = fichiers vendorisés latin, latin-ext et traits de boîte 2.304 (sha256)" "$(printf '%s\n' "$POL" | sed 1d | grep . | tr '\n' ' ')" "$(printf '%s\n%s\n%s\n' "$(node "$AUX/csp.mjs" sha "$V1")" "$(node "$AUX/csp.mjs" sha "$V2")" "$(node "$AUX/csp.mjs" sha "$V3")" | sort | tr '\n' ' ')"
assert_eq "TF.3 — la face des traits de boîte couvre U+2500-259F, avec la plage de poids 100 900 des faces latines (un poids exact change la police primaire de xterm : cellule de 15 px au lieu de 17)" "$(grep -o '@font-face{[^}]*unicode-range:U+2500-259F[^}]*}' "$PG/dark.html" | sed 's/src:url([^)]*)/src:URL/')" '@font-face{font-family:"JetBrains Mono";font-style:normal;font-display:block;font-weight:100 900;unicode-range:U+2500-259F;src:URL format("woff2")}'
PAR="$(node "$AUX/parite.mjs" "$VIEWER" "$PG/dark.html")"
assert_eq "T18.0 — les 41 noms sont présents dans les deux sources, par thème (anti-vide)" "$(printf '%s\n' "$PAR" | grep '^PARITE ')" "PARITE 41/41"
echo "  mesure : $(printf '%s\n' "$PAR" | grep '^PARITE ') (viewer.html contre la page servie)"
assert_eq "T18.1 — parité sombre : aucun écart ni variable absente" "$(printf '%s\n' "$PAR" | grep -E '\(sombre\)| sombre$' || true)" ""
assert_eq "T18.2 — parité claire (valeur effective) : aucun écart ni variable absente" "$(printf '%s\n' "$PAR" | grep -E '\(clair\)| clair$' || true)" ""
PAL="$(node "$AUX/palette.mjs" "$VIEWER" "$OUT/vf-cockpit-terminal-vue.mjs")"
assert_eq "T19.0 — les 15 couleurs de la palette qui ont une variable d'origine sont présentes dans les deux sources, par thème (anti-vide)" "$(printf '%s\n' "$PAL" | grep '^PALETTE ')" "PALETTE 15/15"
echo "  mesure : $(printf '%s\n' "$PAL" | grep '^PALETTE ') (viewer.html contre la palette xterm de vue.mjs)"
assert_eq "T19.1 — parité de la palette xterm, sombre et clair : aucun écart ni couleur absente" "$(printf '%s\n' "$PAL" | grep -v '^PALETTE ' || true)" ""
unsrv

echo "=== M-ANCETRES / M-EMPREINTE / M-THEME — mutants de la page ==="
if mutant ancetres vf-cockpit-terminal-page.mjs 's|frame-ancestors \${origineP}|frame-ancestors *|'; then
  node "$AUX/pagegen.mjs" "$MUT_OUT" "$ENG" dark "$WORK/m-anc.html"
  assert_has "M-ANCETRES — le mutant rougit T9.1 : frame-ancestors *" "$(cat "$WORK/m-anc.html.csp")" "frame-ancestors *;"
else assert_eq "M-ANCETRES — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
if mutant empreinte vf-cockpit-terminal-page.mjs 's|const csp = cspDe(html);|const csp = cspDe(html); html = html.replace("</body>", "<script>0</script></body>");|'; then
  node "$AUX/pagegen.mjs" "$MUT_OUT" "$ENG" dark "$WORK/m-emp.html"
  assert_eq "M-EMPREINTE — le mutant rougit T9.1 : la CSP ne couvre pas le cinquième script" "$([ "$(carte "$(cat "$WORK/m-emp.html.csp")")" != "$(carte "$(node "$AUX/csp.mjs" attendue "$WORK/m-emp.html" http://127.0.0.1:4242)")" ] && echo rouge || echo vert)" "rouge"
else assert_eq "M-EMPREINTE — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
if mutant theme vf-cockpit-terminal-page.mjs "s|const attr = clair ? ' data-theme=\"light\"' : '';|const attr = \` data-theme=\"\${theme}\"\`;|"; then
  node "$AUX/pagegen.mjs" "$MUT_OUT" "$ENG" "\"><b>$MARQ" "$WORK/m-the.html"
  assert_eq "M-THEME — le mutant rougit TH.3 : la valeur est reflétée dans la page" "$(grep -c -F "$MARQ" "$WORK/m-the.html" || true)" "1"
else assert_eq "M-THEME — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi

echo "=== M-XFO — X-Frame-Options posé par Q ==="
if mutant xfo vf-cockpit-terminal-processus.mjs "s/'Content-Security-Policy': csp }/'Content-Security-Policy': csp, 'X-Frame-Options': 'DENY' }/"; then
  srv "$MUT_OUT" 1; QM="$(sj '(j.terminal&&j.terminal.url)||"1"')"; QM="${QM##*:}"; rq "$QM" GET / > "$WORK/m-xfo.out"
  assert_eq "M-XFO — le mutant rougit T9.2 : x-frame-options présent" "$(entete "$WORK/m-xfo.out" 'Object.keys(j).filter(k=>k==="x-frame-options").length')" "1"; unsrv
else assert_eq "M-XFO — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi

echo "=== M-PARITE — six variantes ==="
if mutant paritea vf-cockpit-terminal-style.mjs 's/--surface: #191919/--surface: #191918/'; then
  node "$AUX/pagegen.mjs" "$MUT_OUT" "$ENG" dark "$WORK/m-pa.html"
  assert_has "T18.3 — (a) --surface sombre de Q changé" "$(node "$AUX/parite.mjs" "$VIEWER" "$WORK/m-pa.html")" "variable --surface (sombre) : viewer.html=#191919, Q=#191918"
else assert_eq "T18.3 — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
if mutant paritebis vf-cockpit-terminal-style.mjs 's/--ring:[^;]*;//g'; then
  node "$AUX/pagegen.mjs" "$MUT_OUT" "$ENG" dark "$WORK/m-pb.html"
  assert_has "T18.4 — (b) --ring retiré de Q" "$(node "$AUX/parite.mjs" "$VIEWER" "$WORK/m-pb.html")" "ABSENTE --ring Q sombre"
else assert_eq "T18.4 — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
sed 's/--text-2: #c6c6c6/--text-2: #c6c6c7/' "$VIEWER" > "$WORK/viewer-mut.html"
if ! cmp -s "$VIEWER" "$WORK/viewer-mut.html"; then
  node "$AUX/pagegen.mjs" "$OUT" "$ENG" dark "$WORK/m-pc.html"
  assert_has "T18.5 — (c) --text-2 sombre de viewer.html changé (l'amont dérive)" "$(node "$AUX/parite.mjs" "$WORK/viewer-mut.html" "$WORK/m-pc.html")" "variable --text-2 (sombre) : viewer.html=#c6c6c7, Q=#c6c6c6"
else assert_eq "T18.5 — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
if mutant pariteter vf-cockpit-terminal-style.mjs 's/--text: #161616/--text: #161617/'; then
  node "$AUX/pagegen.mjs" "$MUT_OUT" "$ENG" dark "$WORK/m-pd.html"
  assert_has "T18.6 — (d) --text clair de Q seul changé" "$(node "$AUX/parite.mjs" "$VIEWER" "$WORK/m-pd.html")" "variable --text (clair) : viewer.html=#161616, Q=#161617"
else assert_eq "T18.6 — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
if mutant paritesp vf-cockpit-terminal-style.mjs 's/--sp-8: 8px/--sp-8: 9px/'; then
  node "$AUX/pagegen.mjs" "$MUT_OUT" "$ENG" dark "$WORK/m-pe.html"
  assert_has "T18.7 — (e) --sp-8 de Q seul changé (espacement 71.5)" "$(node "$AUX/parite.mjs" "$VIEWER" "$WORK/m-pe.html")" "variable --sp-8 (sombre) : viewer.html=8px, Q=9px"
else assert_eq "T18.7 — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
if mutant pariteca vf-cockpit-terminal-style.mjs 's/--inset-card: var(--sp-16)/--inset-card: var(--sp-12)/'; then
  node "$AUX/pagegen.mjs" "$MUT_OUT" "$ENG" dark "$WORK/m-pf.html"
  assert_has "T18.7 — (f) --inset-card de Q seul changé (jeton sémantique)" "$(node "$AUX/parite.mjs" "$VIEWER" "$WORK/m-pf.html")" "variable --inset-card (sombre) : viewer.html=var(--sp-16), Q=var(--sp-12)"
else assert_eq "T18.7 — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi

echo "=== M-PALETTE — quatre variantes (J10) ==="
if mutant paletta vf-cockpit-terminal-vue.mjs "s/green: '#9ece6a'/green: '#9ece6b'/"; then
  assert_has "T19.2 — (a) vert sombre de la palette changé" "$(node "$AUX/palette.mjs" "$VIEWER" "$MUT_OUT/vf-cockpit-terminal-vue.mjs")" "couleur green (sombre) : viewer.html --recent=#9ece6a, palette=#9ece6b"
else assert_eq "T19.2 — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
if mutant palettb vf-cockpit-terminal-vue.mjs "s/brightRed: '#da1637',//"; then
  assert_has "T19.3 — (b) brightRed retiré de la palette claire" "$(node "$AUX/palette.mjs" "$VIEWER" "$MUT_OUT/vf-cockpit-terminal-vue.mjs")" "ABSENTE brightRed palette clair"
else assert_eq "T19.3 — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
sed 's/--recent: #9ece6a;/--recent: #9ece69;/' "$VIEWER" > "$WORK/viewer-pal.html"
if ! cmp -s "$VIEWER" "$WORK/viewer-pal.html"; then
  assert_has "T19.4 — (c) --recent sombre de viewer.html changé (l'amont dérive)" "$(node "$AUX/palette.mjs" "$WORK/viewer-pal.html" "$OUT/vf-cockpit-terminal-vue.mjs")" "couleur green (sombre) : viewer.html --recent=#9ece69, palette=#9ece6a"
else assert_eq "T19.4 — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
if mutant palettd vf-cockpit-terminal-vue.mjs "s/cursorAccent: '#ffffff'/cursorAccent: '#fffffe'/"; then
  assert_has "T19.5 — (d) cursorAccent clair seul changé (#fff de viewer.html contre #fffffe)" "$(node "$AUX/palette.mjs" "$VIEWER" "$MUT_OUT/vf-cockpit-terminal-vue.mjs")" "couleur cursorAccent (clair) : viewer.html --on-text=#ffffff, palette=#fffffe"
else assert_eq "T19.5 — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi

echo "=== TV — intégrité du vendor au démarrage (TERM-10) ==="
copie() { rm -rf "$WORK/moteur-$1"; cp -R "$ENG" "$WORK/moteur-$1"; } # copie du moteur, modifiable sans toucher au dépôt
verdict() { # verdict <nom> : démarre Q sur la copie, rend « etat/écouteurs »
  srv "$OUT" 1 "$WORK/moteur-$1"; VERD="$(etat_p | node "$AUX/ev.mjs" j.etat)/$(nlignes "$(ecoutes_srv "$SRV_PID")")"; VJ="$(cat "$SRV_OUT")"; unsrv; }
copie intact; verdict intact
assert_eq "TV.0b — témoin : moteur intact -> actif, deux écouteurs" "$VERD" "actif/2"
copie octet; node -e "const f=process.argv[1],b=require('fs').readFileSync(f);b[1000]^=1;require('fs').writeFileSync(f,b)" "$WORK/moteur-octet/assets/vendor/xterm/xterm.js"
verdict octet
assert_eq "TV.1 — un octet de xterm.js changé : arrete, un seul écouteur" "$VERD" "arrete/1"
assert_has "TV.1 — le journal dit « fichiers xterm altérés »" "$VJ" "fichiers xterm altérés"
copie sommes; sed -i.bak 's/^854a7c0f/954a7c0f/' "$WORK/moteur-sommes/assets/vendor/xterm/SHA256SUMS"; verdict sommes
assert_eq "TV.2 — SHA256SUMS incohérent : arrete, un seul écouteur" "$VERD" "arrete/1"
copie absent; rm -f "$WORK/moteur-absent/assets/vendor/xterm/xterm.js"; verdict absent
assert_eq "TV.3 — xterm.js absent : arrete" "$VERD $(printf '%s' "$VJ" | grep -c 'fichiers xterm absents')" "arrete/1 1"

copie fonte; node -e "const f=process.argv[1],b=require('fs').readFileSync(f);b[2000]^=1;require('fs').writeFileSync(f,b)" "$WORK/moteur-fonte/assets/vendor/fonts/jetbrains-mono-2.304-regular.woff2"
verdict fonte
assert_eq "TV.4 — un octet de la police des traits de boîte changé : arrete, un seul écouteur" "$VERD" "arrete/1"
assert_has "TV.4 — le journal dit « fichiers xterm altérés »" "$VJ" "fichiers xterm altérés"
copie sommesfonte; sed -i.bak 's/^a9cb1cd8/b9cb1cd8/' "$WORK/moteur-sommesfonte/assets/vendor/fonts/SHA256SUMS"; verdict sommesfonte
assert_eq "TV.5 — SHA256SUMS des polices incohérent : arrete, un seul écouteur" "$VERD" "arrete/1"

vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
