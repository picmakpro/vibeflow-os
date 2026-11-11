#!/usr/bin/env bash
# test-cockpit-questions.sh — questions de l'onglet Projet et agent confiné (CKPT-07 ; P67-D-01, P67-D-08, P67-D-15).
#   Q1 forme courante locale · Q2 raisonnement -> agent confiné (argv = combinaison mesurée) · Q3 onglet Code, même confinement
#   Q4 modèle : préséance et liste fermée · Q5 question piégée inoffensive · Q6 le modèle ne laisse aucune trace
#   Q7 seul Claude Code est lancé · Q8 syntaxe et jeton de /api/vf/modeles · Q9 CLI de requête · Q10 identité de phase
#   Q11 ARGS_CONFINEMENT = « Combinaison retenue » de la mesure la plus récente (dépôt de dev seulement ; Q11.0 : jamais sautée dans le dépôt)
#   Q18 retours panel lot 7 (PU-G-096 un état par phase · PU-G-147 coupe au mot · PU-G-150 lignes non comprises)
#   Q15 « Où en est-on ? » sans STATE.md · Q16 statut lisible (réponse locale, sous-titre) · Q17 parité des tables de statuts
# Faux binaires claude et codex (node) en tête du PATH ; aucun vrai appel. Exit 0 si tout passe, 1 sinon.

set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; } # port libre choisi à l'exécution (jamais un tirage au hasard : trois suites en parallèle se heurtaient)
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"; mkdir -p "$WORK/aux" "$WORK/home"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"
export HOME="$WORK/home"; NODE="$(command -v node)"
SRV=""
stop_srv() { [ -n "$SRV" ] && { vf_hyg_stop "$SRV"; }; SRV=""; }
trap 'stop_srv; vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"' EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }

# --- outils node : ask (POST /api/ask), ev (expression sur les événements), call (appel consigné), tok, loc (réponse locale), cst (constante) ---
cat > "$AUX/h.mjs" <<'JS'
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , cmd, ...a] = process.argv;
const J = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
if (cmd === 'body') { const [qf, extra] = a; console.log(JSON.stringify({ question: fs.readFileSync(qf, 'utf8'), mode: 'ask', ...JSON.parse(extra || '{}') })); }
else if (cmd === 'ask') { // ask <port> <jeton> <corps> <sortie>
  const [port, token, bf, out] = a; fs.writeFileSync(out, '');
  const req = http.request({ host: '127.0.0.1', port: Number(port), path: '/api/ask', method: 'POST', headers: { Host: `127.0.0.1:${port}`, 'content-type': 'application/json', 'x-vf-cockpit-token': token } }, (res) => {
    let buf = '';
    res.on('data', (c) => { buf += c; let i; while ((i = buf.indexOf('\n\n')) >= 0) { const b = buf.slice(0, i); buf = buf.slice(i + 2); const ev = /^event: (.*)$/m.exec(b)?.[1], dt = /^data: (.*)$/m.exec(b)?.[1]; if (ev) fs.appendFileSync(out, JSON.stringify({ event: ev, data: JSON.parse(dt) }) + '\n'); } });
    res.on('end', () => process.exit(0));
  });
  req.end(fs.readFileSync(bf)); setTimeout(() => process.exit(0), 20000);
} else if (cmd === 'ev') { const E = fs.readFileSync(a[0], 'utf8').split('\n').filter(Boolean).map((l) => JSON.parse(l)); const v = new Function('E', 'return (' + a[1] + ')')(E); console.log(typeof v === 'string' ? v : JSON.stringify(v)); }
else if (cmd === 'call') { const v = new Function('c', 'return (' + a[2] + ')')(J(path.join(a[0], `call-${a[1]}.json`))); console.log(typeof v === 'string' ? v : JSON.stringify(v)); }
else if (cmd === 'ncalls') console.log(fs.readdirSync(a[0]).filter((f) => /^call-\d+\.json$/.test(f)).length);
else if (cmd === 'tok') http.get({ host: '127.0.0.1', port: Number(a[0]), path: a[1], headers: { Host: `127.0.0.1:${a[0]}` } }, (r) => { let b = ''; r.on('data', (c) => (b += c)); r.on('end', () => console.log(/VF_COCKPIT_SERVER=\{"token":"([0-9a-f]+)"/.exec(b)?.[1] || '')); });
else if (cmd === 'get') http.get({ host: '127.0.0.1', port: Number(a[0]), path: a[1], headers: { Host: `127.0.0.1:${a[0]}`, ...(a[2] ? { 'x-vf-cockpit-token': a[2] } : {}) } }, (r) => { let b = ''; r.on('data', (c) => (b += c)); r.on('end', () => { console.log(r.statusCode); process.stdout.write(b); }); });
else if (cmd === 'json') console.log(String(new Function('j', 'return (' + a[1] + ')')(J(a[0]))));
else if (cmd === 'loc') { const g = (await import(pathToFileURL(path.join(a[0], 'vf-cockpit-project.mjs')).href)).buildProjectGraph(a[1]); console.log(JSON.stringify((await import(pathToFileURL(path.join(a[0], 'vf-cockpit-ask.mjs')).href)).answerLocally(g, a[2]))); }
else if (cmd === 'locg') console.log(JSON.stringify((await import(pathToFileURL(path.join(a[0], 'vf-cockpit-ask.mjs')).href)).answerLocally(J(a[1]), a[2]))); // locg <scripts> <graphe.json> <question> : réponse locale sur un graphe fabriqué
else if (cmd === 'cst') console.log((await import(pathToFileURL(path.join(a[0], 'vf-cockpit-agent.mjs')).href)).ARGS_CONFINEMENT.join('\n'));
else if (cmd === 'sub') { // sub <call.json> <liste-attendue> : la liste est-elle une sous-suite contiguë, dans l'ordre, de l'argv ?
  const argv = J(a[0]).argv, want = fs.readFileSync(a[1], 'utf8').split('\n'); if (want.at(-1) === '') want.pop(); // un élément vide est légitime (--setting-sources "") : seul le saut de ligne final disparaît
  console.log(want.length > 0 && argv.some((_, i) => want.every((w, k) => argv[i + k] === w)));
}
JS
H() { "$NODE" "$AUX/h.mjs" "$@"; }
# faux binaires : consignent argv, dossier courant et entrée standard dans $VF_FAKE_DIR/call-N.json, puis répondent
mkfake() { # mkfake <dossier> <nom>
  mkdir -p "$1"; printf '#!%s\n' "$NODE" > "$1/$2"; cat >> "$1/$2" <<'JS'
const fs = require('fs'); const D = process.env.VF_FAKE_DIR;
const n = fs.readdirSync(D).filter((f) => /^call-\d+\.json$/.test(f)).length + 1;
if (process.argv[2] === '--version') { fs.writeFileSync(`${D}/call-${n}.json`, JSON.stringify({ argv: ['--version'] })); console.log('2.1.316 (Claude Code)'); process.exit(0); }
if (process.argv[2] === 'agents') process.exit(1); // la lecture de l'état officiel des sessions (onglet Équipe) n'est pas une demande à l'agent : ni consignée, ni comptée (jointure)
let stdin = ''; process.stdin.on('data', (c) => (stdin += c));
process.stdin.on('end', () => { fs.writeFileSync(`${D}/call-${n}.json`, JSON.stringify({ argv: process.argv.slice(2), cwd: process.cwd(), stdin })); console.log(JSON.stringify({ type: 'result', is_error: false, result: JSON.stringify({ title: 'Faux', answer: 'FAUX-AGENT-REPONSE', items: [], steps: [], followups: [] }), session_id: 'fake-session' })); });
JS
  chmod +x "$1/$2"
}
# --- lab neutre assemblé ---
LAB="$WORK/lab"; mkdir -p "$LAB/src" "$LAB/.planning/phases/01-x"
printf 'export const util = () => 1;\n' > "$LAB/src/util.js"
printf -- '- [x] **Phase 1: Socle** - premier jet\n- [ ] **Phase 2: Suite** - deuxième jet\n' > "$LAB/.planning/ROADMAP.md"
printf '<objective>Faire le socle</objective>\n' > "$LAB/.planning/phases/01-x/01-01-PLAN.md"; echo ok > "$LAB/.planning/phases/01-x/01-01-SUMMARY.md"
git -C "$LAB" init -q && git -C "$LAB" add -A && git -C "$LAB" -c user.email=t@t -c user.name=t commit -q -m init
node "$SCRIPTS/vf-cockpit-build.mjs" "$LAB" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
OUT="$LAB/.vibeflow/cockpit"; LABR="$(cd "$LAB" && pwd -P)"
demarrer() { # demarrer <dossier-faux> <PATH> [VAR=val ...] -> PORT, TOK, PTOK ; VF_FAKE_DIR = <dossier-faux>
  local FK="$1" P="$2"; shift 2; stop_srv; rm -f "$OUT/.cache/server.json"; [ -n "${NOCLEAR:-}" ] || rm -f "$FK"/call-*.json
  env PATH="$P" VF_FAKE_DIR="$FK" "$@" "$NODE" "$OUT/serve.mjs" --no-open --port $(libre) > "$WORK/serve.out" 2>&1 &
  SRV=$!
  for _ in $(seq 1 100); do [ -s "$OUT/.cache/server.json" ] && break; sleep 0.1; done
  PORT=$(H json "$OUT/.cache/server.json" 'j.port' 2>/dev/null || echo 0); TOK=$(H tok "$PORT" /); PTOK=$(H tok "$PORT" /project.html)
  [ -n "${NOCLEAR:-}" ] || rm -f "$FK"/call-*.json # le --version du démarrage n'est pas une question
}
poser() { # poser <jeton> <question> [extra-json] -> $WORK/ev.jsonl
  printf '%s' "$2" > "$WORK/q.txt"; H body "$WORK/q.txt" "${3:-}" > "$WORK/body.json"; H ask "$PORT" "$1" "$WORK/body.json" "$WORK/ev.jsonl"
}
FK="$WORK/fk"; mkfake "$FK" claude; BASEPATH="$FK:$PATH"
# --- combinaison attendue : extraite de la mesure (dépôt) ou comparée à la constante (lab) ---
# racine_depot : racine du dépôt de dev quand le module est posé sous plugin/cockpit de cette racine ET qu'elle porte .planning/ ; rien sinon
racine_depot() { local m r; m="$(cd "$SCRIPTS/.." && pwd -P)"; r="$(cd "$SCRIPTS/../../.." 2>/dev/null && pwd -P)"; [ -n "$r" ] && [ "$m" = "$r/plugin/cockpit" ] && [ -d "$r/.planning" ] && printf '%s' "$r"; }
DEPOT="$(racine_depot)"
# mesure_de <racine> : la mesure du confinement au plus grand numéro de phase sous .planning/ (tri numérique du préfixe, jamais lexical ni par date) ; rien s'il n'y en a pas
mesure_de() { find "$1/.planning" -name '*-MESURE-claude-p.md' 2>/dev/null | awk -F/ '{ n=$NF; sub(/-.*/, "", n); printf "%012d\t%s\n", n+0, $0 }' | LC_ALL=C sort | tail -1 | cut -f2-; }
MESURE=""; [ -n "$DEPOT" ] && MESURE="$(mesure_de "$DEPOT")"
H cst "$SCRIPTS" > "$WORK/const.txt"
if [ -n "$MESURE" ]; then awk '/^## Combinaison retenue$/{f=1;next} /^## /{f=0} f && /^- `/' "$MESURE" | sed 's/^- `//; s/`$//' > "$WORK/attendu.txt"; echo "  (combinaison attendue lue dans la mesure)"
else cp "$WORK/const.txt" "$WORK/attendu.txt"; echo "  (mesure absente : comparaison à la constante)"; fi

demarrer "$FK" "$BASEPATH"
echo "=== Q1 — forme courante : locale, sans agent ==="
poser "$PTOK" "Où en est-on ?"
assert_eq "Q1.1 — réponse locale (engine local)" "$(H ev "$WORK/ev.jsonl" 'E.filter(e=>e.event==="answer").map(e=>e.data.engine).join(",")')" "local"
assert_eq "Q1.2 — le faux claude n'est pas appelé" "$(H ncalls "$FK")" "0"
echo "=== Q2 — raisonnement : agent confiné ==="
poser "$PTOK" "Pourquoi la phase 1 a-t-elle ce statut ?"
assert_eq "Q2.1 — le faux claude est appelé une fois" "$(H ncalls "$FK")" "1"
assert_eq "Q2.2 — l'argv contient la combinaison attendue, contiguë et dans l'ordre" "$(H sub "$FK/call-1.json" "$WORK/attendu.txt")" "true"
echo "     argv consigné : $(H call "$FK" 1 'JSON.stringify(c.argv.map(x=>x.length>48?x.slice(0,36)+"…":x))')"
assert_eq "Q2.3 — mode de permission explicite, aucun Bash nu" "$(H call "$FK" 1 'c.argv.includes("--permission-mode")&&!c.argv.includes("Bash")')" "true"
assert_eq "Q2.4 — tout Bash( désigne l'un des deux scripts de requête" "$(H call "$FK" 1 'c.argv.filter(x=>x.startsWith("Bash(")).every(x=>/^Bash\(node \.vibeflow\/cockpit\/(vf-cockpit-)?query\.mjs:\*\)$/.test(x))')" "true"
assert_eq "Q2.5 — dossier courant = racine du lab" "$(H call "$FK" 1 'c.cwd')" "$LABR"
assert_eq "Q2.6 — la réponse du faux agent est relayée" "$(H ev "$WORK/ev.jsonl" 'E.filter(e=>e.event==="answer").map(e=>e.data.answer).join(",")')" "FAUX-AGENT-REPONSE"
assert_eq "Q2.7 — l'onglet Projet reçoit la consigne Projet (le script de requête VibeFlow)" "$(H call "$FK" 1 'c.argv.some(x=>x.includes("vf-cockpit-query.mjs overview"))')" "true"
echo "=== Q2b — la forme courante reste locale en pleine conversation avec l'agent (recette 67, V1 : le navigateur renvoie la session après toute réponse de l'agent) ==="
SESS="$(H ev "$WORK/ev.jsonl" 'E.filter(e=>e.event==="answer").map(e=>e.data.session||"").join(",")')"
assert_eq "Q2b.1 — la réponse de l'agent porte un identifiant de session (témoin : la suite plus bas est bien envoyée avec une session)" "$([ -n "$SESS" ] && echo oui || echo non)" "oui"
poser "$PTOK" "Où en est-on ?" "{\"session\":\"$SESS\"}"
assert_eq "Q2b.2 — « Où en est-on ? » avec une session ouverte : réponse locale (engine local)" "$(H ev "$WORK/ev.jsonl" 'E.filter(e=>e.event==="answer").map(e=>e.data.engine).join(",")')" "local"
assert_eq "Q2b.3 — le faux claude n'est pas rappelé (toujours 1 appel : celui de Q2)" "$(H ncalls "$FK")" "1"
echo "=== Q3 — onglet Code : même confinement ==="
poser "$TOK" "Combien de fichiers de code ?"
assert_eq "Q3.1 — l'agent est appelé (aucune voie locale côté Code)" "$(H ncalls "$FK")" "2"
assert_eq "Q3.2 — même combinaison de confinement" "$(H sub "$FK/call-2.json" "$WORK/attendu.txt")" "true"
assert_eq "Q3.3 — l'onglet Code garde sa consigne (pas celle du Projet)" "$(H call "$FK" 2 'c.argv.some(x=>x.includes("vf-cockpit-query.mjs overview"))')" "false"

echo "=== Q4 — modèle : préséance et liste fermée ==="
assert_eq "Q4.1 — ni sélecteur ni variable : --model sonnet" "$(H call "$FK" 2 'c.argv.slice(-2).join(" ")')" "--model sonnet"
mkfake "$WORK/fk2" claude; demarrer "$WORK/fk2" "$WORK/fk2:$PATH" VF_COCKPIT_MODEL=haiku
poser "$PTOK" "Pourquoi ?"
assert_eq "Q4.2 — VF_COCKPIT_MODEL=haiku : --model haiku" "$(H call "$WORK/fk2" 1 'c.argv.slice(-2).join(" ")')" "--model haiku"
poser "$PTOK" "Pourquoi ?" '{"model":"opus"}'
assert_eq "Q4.3 — sélecteur opus > variable haiku : --model opus" "$(H call "$WORK/fk2" 2 'c.argv.slice(-2).join(" ")')" "--model opus"
poser "$PTOK" "Pourquoi ?" '{"model":"gpt; rm -rf /"}'
assert_eq "Q4.4 — hors liste : failure modele_refuse" "$(H ev "$WORK/ev.jsonl" 'E.filter(e=>e.event==="failure").map(e=>e.data.code).join(",")')" "modele_refuse"
assert_eq "Q4.5 — le faux claude n'a pas été lancé pour le refus" "$(H ncalls "$WORK/fk2")" "2"
MODELES_REP="$(H get "$PORT" /api/vf/modeles "$TOK")"
assert_has "Q4.6 — /api/vf/modeles rend la liste fermée, opus compris" "$MODELES_REP" '"modeles":["sonnet","opus","haiku"]'
mkfake "$WORK/fk3" claude; demarrer "$WORK/fk3" "$WORK/fk3:$PATH" VF_COCKPIT_MODEL=foo
poser "$PTOK" "Pourquoi ?"
assert_eq "Q4.7 — VF_COCKPIT_MODEL=foo : --model sonnet" "$(H call "$WORK/fk3" 1 'c.argv.slice(-2).join(" ")')" "--model sonnet"
assert_has "Q4.8 — un avertissement nomme la variable sur la sortie du serveur" "$(cat "$WORK/serve.out")" "VF_COCKPIT_MODEL=foo hors liste"

echo "=== Q4b — mode hors liste : jamais une clé de prototype (relecture SOBR-04 de v2.75.0, F2) ==="
mkfake "$WORK/fk6" claude; demarrer "$WORK/fk6" "$WORK/fk6:$PATH"
poser "$PTOK" "Pourquoi ?"
assert_eq "Q4b.0 — témoin : le mode ask (défaut) lance l'agent, avec --json-schema et --append-system-prompt" "$(H ncalls "$WORK/fk6")|$(H call "$WORK/fk6" 1 'c.argv.includes("--json-schema")&&c.argv.includes("--append-system-prompt")')" "1|true"
ARGV0="$(H call "$WORK/fk6" 1 'JSON.stringify(c.argv)')"; N6=1
for m in constructor __proto__ toString hasOwnProperty; do
  N6=$((N6+1)); poser "$PTOK" "Pourquoi ?" "{\"mode\":\"$m\"}"
  assert_eq "Q4b.$N6 — mode=$m : l'agent est lancé avec l'argv du mode par défaut (consigne et schéma présents, aucun « undefined »)" "$(H ncalls "$WORK/fk6")|$(H call "$WORK/fk6" "$N6" 'c.argv.includes("undefined")')|$([ "$(H call "$WORK/fk6" "$N6" 'JSON.stringify(c.argv)')" = "$ARGV0" ] && echo identique)" "$N6|false|identique"
done
echo "=== Q5 — question piégée : aucun effet ==="
demarrer "$FK" "$BASEPATH"
cat > "$WORK/piege.txt" <<'TXT'
$(touch PWNED1); `touch PWNED2`; touch PWNED3
TXT
printf '%s' "$(cat "$WORK/piege.txt")" > "$WORK/piege-exact.txt"
H body "$WORK/piege-exact.txt" '' > "$WORK/body.json"; H ask "$PORT" "$PTOK" "$WORK/body.json" "$WORK/ev.jsonl"
assert_eq "Q5.1 — l'agent a été appelé" "$(H ncalls "$FK")" "1"
assert_eq "Q5.2 — aucun fichier PWNED* (lab, dossier de travail, suite)" "$(find "$LAB" "$WORK" -name 'PWNED*' 2>/dev/null | grep -c .)" "0"
printf '%s' "$(H call "$FK" 1 'c.stdin')" > "$WORK/stdin-vu.txt"
assert_eq "Q5.3 — l'entrée standard porte la question octet pour octet" "$(cmp -s "$WORK/stdin-vu.txt" "$WORK/piege-exact.txt" && echo identique || echo different)" "identique"

echo "=== Q6 — le modèle ne laisse aucune trace ==="
demarrer "$WORK/fk2" "$WORK/fk2:$PATH"; node "$OUT/serve.mjs" --export "$WORK/export-avant.html" > /dev/null 2>&1
poser "$PTOK" "Pourquoi ?" '{"model":"opus"}'
node "$OUT/serve.mjs" --export "$WORK/export-apres.html" > /dev/null 2>&1
TRACES=$(grep -rl '"model"[[:space:]]*:[[:space:]]*"opus"' "$OUT" 2>/dev/null | grep -c .); OPUS=$(grep -l 'opus' "$OUT/graph.json" "$OUT"/.cache/*.json 2>/dev/null | grep -c .)
assert_eq "Q6.1 — aucun fichier de la sortie ne garde le choix (clé model, graph.json, .cache)" "$TRACES$OPUS" "00"
sed 's/"at":"[^"]*"//g' "$WORK/export-avant.html" > "$WORK/ea.html"; sed 's/"at":"[^"]*"//g' "$WORK/export-apres.html" > "$WORK/eb.html" # seul l'horodatage de l'export diffère
assert_eq "Q6.2 — l'export est identique avant et après le choix du modèle (hors horodatage)" "$(cmp -s "$WORK/ea.html" "$WORK/eb.html" && echo identique || echo different)" "identique"
assert_eq "Q6.3 — témoin : la question a bien été posée avec opus" "$(H call "$WORK/fk2" 1 'c.argv.slice(-2).join(" ")')" "--model opus"

echo "=== Q7 — seul Claude Code est lancé ==="
mkfake "$WORK/fkx" codex; VF_FAKE_DIR="$WORK/fkx" "$WORK/fkx/codex" --version > /dev/null
assert_eq "Q7.0 — témoin : le faux codex consigne un appel direct" "$(H ncalls "$WORK/fkx")" "1"
NOCLEAR=1 demarrer "$WORK/fkx" "$WORK/fkx:/usr/bin:/bin"
poser "$PTOK" "Pourquoi ?"
assert_eq "Q7.1 — sans claude : failure nommé cli_missing" "$(H ev "$WORK/ev.jsonl" 'E.filter(e=>e.event==="failure").map(e=>e.data.code).join(",")')" "cli_missing"
assert_eq "Q7.2 — le faux codex n'a jamais été lancé par le serveur (1 appel : le témoin)" "$(H ncalls "$WORK/fkx")" "1"

echo "=== Q8 — syntaxe et jeton ==="
assert_eq "Q8.1 — node --check vf-cockpit-agent.mjs" "$(node --check "$SCRIPTS/vf-cockpit-agent.mjs" 2>&1 >/dev/null; echo $?)" "0"
assert_eq "Q8.2 — node --check 75-vf-modele.js" "$(node --check "$SCRIPTS/../skills/cockpit-moteur/assets/ui/75-vf-modele.js" 2>&1 >/dev/null; echo $?)" "0"
assert_eq "Q8.3 — /api/vf/modeles sans jeton : 403" "$(H get "$PORT" /api/vf/modeles | sed -n 1p)" "403"
stop_srv

echo "=== Q9 — CLI de requête ==="
cd "$LAB"
assert_eq "Q9.1 — overview : JSON à clé now, exit 0" "$(node .vibeflow/cockpit/vf-cockpit-query.mjs overview > "$WORK/o.json"; echo $?)$(H json "$WORK/o.json" '"now" in j')" "0true"
assert_eq "Q9.2 — status done : JSON à clé items, exit 0" "$(node .vibeflow/cockpit/vf-cockpit-query.mjs status done > "$WORK/s.json"; echo $?)$(H json "$WORK/s.json" 'Array.isArray(j.items)&&j.items.length>0')" "0true"
assert_eq "Q9.3 — commande inconnue : exit 1" "$(node .vibeflow/cockpit/vf-cockpit-query.mjs nimporte > /dev/null 2>&1; echo $?)" "1"
cd "$WORK"

echo "=== Q10 — identité de phase ==="
L5="$WORK/part"; for w in un deux; do mkdir -p "$L5/.planning/workstreams/$w/phases/01-a"; printf -- '- [ ] **Phase 1: Premiere** - une phase\n' > "$L5/.planning/workstreams/$w/ROADMAP.md"; printf '<objective>Plan %s</objective>\n' "$w" > "$L5/.planning/workstreams/$w/phases/01-a/01-01-PLAN.md"; done
H loc "$SCRIPTS" "$L5" "Qu'est-ce qui reste dans la phase 1 ?" > "$WORK/l5.json"
assert_eq "Q10.1 — deux compartiments : réponse locale qui liste les deux phases" "$(H json "$WORK/l5.json" 'j.engine+" "+j.items.map(i=>i.id).sort().join(",")')" "local n:ph-1@deux,n:ph-1@un"
assert_eq "Q10.2 — la réponse nomme les deux compartiments" "$(H json "$WORK/l5.json" '/compartiment un/.test(j.answer)&&/compartiment deux/.test(j.answer)')" "true"
H loc "$SCRIPTS" "$L5" "Qu'est-ce qui reste dans la phase 1 du compartiment deux ?" > "$WORK/l5b.json"
assert_eq "Q10.3 — le compartiment nommé lève l'ambiguïté (vise cette phase seule)" "$(H json "$WORK/l5b.json" 'j.items[0].id')" "n:ph-1@deux"
H loc "$SCRIPTS" "$LAB" "Qu'est-ce qui reste dans la phase 2 ?" > "$WORK/l1.json"
assert_eq "Q10.4 — numéro unique : la réponse vise directement ph-2" "$(H json "$WORK/l1.json" 'j.items[0].id')" "n:ph-2"

echo "=== Q12 — CKPT-07 : « ce qui reste » sans jalon courant reconnu reste local (jamais un appel à l'agent) ==="
mkl() { # mkl <dir> <nbJalons> : STATE.md dont le jalon (v9.9) n'existe pas dans le ROADMAP ; phases 2i-1 (faite) et 2i (à faire) par jalon ji
  local D="$1" N="$2" i; mkdir -p "$D/.planning/phases/01-x"; printf '# Roadmap\n\n## Milestones\n\n' > "$D/.planning/ROADMAP.md"
  for i in $(seq 1 "$N"); do printf -- '- 🚧 **j%s** - Phases %s-%s\n' "$i" "$((i*2-1))" "$((i*2))" >> "$D/.planning/ROADMAP.md"; done
  printf '\n## Phases\n\n' >> "$D/.planning/ROADMAP.md"
  for i in $(seq 1 "$N"); do printf -- '- [x] **Phase %s: Socle %s** - fait\n- [ ] **Phase %s: Suite %s** - à faire\n' "$((i*2-1))" "$i" "$((i*2))" "$i" >> "$D/.planning/ROADMAP.md"; done
  printf -- '---\nmilestone: v9.9\nstatus: executing\n---\n# State\n' > "$D/.planning/STATE.md"; printf '<objective>x</objective>\n' > "$D/.planning/phases/01-x/01-01-PLAN.md"
  git -C "$D" init -q && git -C "$D" add -A && git -C "$D" -c user.email=t@t -c user.name=t commit -q -m init
}
mkl "$WORK/m1" 1; H loc "$SCRIPTS" "$WORK/m1" "Qu'est-ce qui reste ?" > "$WORK/m1.json"
assert_eq "Q12.1 — jalon unique non reconnu par le STATE : réponse locale sur ce jalon (le jalon et sa phase à faire)" "$(H json "$WORK/m1.json" 'j&&j.engine+" "+j.items.map(i=>i.id).join(",")')" "local n:ms-j1,n:ph-2"
mkl "$WORK/m2" 2; H loc "$SCRIPTS" "$WORK/m2" "prochaine étape ?" > "$WORK/m2.json"
assert_eq "Q12.2 — deux jalons, aucun reconnu : réponse locale sur le pool des phases à faire (les deux sont listées)" "$(H json "$WORK/m2.json" 'j&&j.engine+" "+j.items.map(i=>i.id).sort().join(",")')" "local n:ph-2,n:ph-4"
mkl "$WORK/m3" 2; sed -i.bak 's/^milestone: v9.9$/milestone: j1/' "$WORK/m3/.planning/STATE.md"; H loc "$SCRIPTS" "$WORK/m3" "reste" > "$WORK/m3.json"
assert_eq "Q12.3 — témoin : jalon courant reconnu (j1 parmi deux), comportement inchangé : ce jalon seul" "$(H json "$WORK/m3.json" 'j&&j.engine+" "+j.items.map(i=>i.id).join(",")')" "local n:ms-j1,n:ph-2"
mkdir -p "$WORK/m4/.planning"; printf '# vide\n' > "$WORK/m4/.planning/ROADMAP.md"; git -C "$WORK/m4" init -q; H loc "$SCRIPTS" "$WORK/m4" "Qu'est-ce qui reste ?" > "$WORK/m4.json"
assert_eq "Q12.4 — aucune phase du tout : rien à calculer, la question repart à l'agent (null)" "$(cat "$WORK/m4.json")" "null"

echo "=== Q15 à Q17 — UIFN-08, UIFN-06 : « Où en est-on ? » sans STATE, statuts lisibles, parité des tables (P70-D-04, P70-D-05) ==="
mkq() { # mkq <dir> [statut] : ROADMAP à une phase ; STATE.md seulement si un statut est donné
  local D="$1"; mkdir -p "$D/.planning/phases/01-x"; printf '# Roadmap\n\n## Milestones\n\n- 🚧 **j1** - Phases 1-2\n\n## Phases\n\n- [x] **Phase 1: Socle** - fait\n- [ ] **Phase 2: Suite** - à faire\n' > "$D/.planning/ROADMAP.md"
  printf '<objective>x</objective>\n' > "$D/.planning/phases/01-x/01-01-PLAN.md"
  [ -n "${2:-}" ] && printf -- '---\nmilestone: j1\nstatus: %s\ncurrent_phase: 1\nlast_activity: 2026-11-01\n---\n# State\n' "$2" > "$D/.planning/STATE.md"
  git -C "$D" init -q && git -C "$D" add -A && git -C "$D" -c user.email=t@t -c user.name=t commit -q -m init
}
mkq "$WORK/q15"; H loc "$SCRIPTS" "$WORK/q15" "Où en est-on ?" > "$WORK/q15.json"
assert_eq "Q15.1 — lab sans STATE.md : réponse locale non nulle" "$(H json "$WORK/q15.json" 'j?"oui":"non"')" "oui"
assert_eq "Q15.2 — aucun « ? » en valeur, aucune virgule orpheline, aucun « le . »" "$(H json "$WORK/q15.json" '/\?\s*[,.]|·\s*,|le \.|: \?|phase \?/.test(j.answer.replace(/Où en est-on \?/g,""))')" "false"
assert_eq "Q15.3 — la réponse dit qu'il n'y a pas de STATE.md" "$(H json "$WORK/q15.json" '/pas de STATE\.md/i.test(j.answer)')" "true"
assert_eq "Q15.4 — pas de titre « À finir » suivi d'une liste vide" "$(H json "$WORK/q15.json" 'j.answer.split("\n").map((l,i,a)=>/^À finir/.test(l)&&!/^- /.test(a.slice(i+1).find(x=>x.trim())||"")).some(Boolean)')" "false"
mkq "$WORK/q16" ready_to_execute; H loc "$SCRIPTS" "$WORK/q16" "Où en est-on ?" > "$WORK/q16.json"
assert_eq "Q16.1 — la réponse locale n'a aucun statut brut (mot à tiret bas)" "$(H json "$WORK/q16.json" '/\b[a-z]+_[a-z_]+\b/.test(j.answer)')" "false"
assert_eq "Q16.2 — la réponse locale dit l'état de la CARTE (« fait »), cite le statut de STATE.md en français à part (« prête à exécuter »), et signale qu'ils divergent (« STATE.md semble périmé »), comme le panneau" "$(H json "$WORK/q16.json" '/Dernière phase : \[\[n:ph-1\]\] · fait/.test(j.answer)&&/Statut noté dans STATE\.md : prête à exécuter/.test(j.answer)&&/STATE\.md semble périmé/.test(j.answer)')" "true"
"$NODE" "$SCRIPTS/vf-cockpit-project.mjs" "$WORK/q16" > "$WORK/q16g.json"
assert_eq "Q16.3 — sous-titre du graphe (CLI) : état de la carte de la phase courante (PU-G-093, P69-D-08), libellé français, aucun tiret bas, jamais le statut brut de STATE.md" "$(H json "$WORK/q16g.json" '/phase 1 · fait\./.test(j.project.summary)&&!/_|prête à exécuter/.test(j.project.summary)')" "true"
mkq "$WORK/q16c" ready_to_execute; sed -i.bak 's/^- \[x\] \*\*Phase 1/- [ ] **Phase 1/' "$WORK/q16c/.planning/ROADMAP.md"; H loc "$SCRIPTS" "$WORK/q16c" "Où en est-on ?" > "$WORK/q16c.json"
assert_eq "Q16.5 — témoin d'accord : carte et STATE.md concordent, la réponse ne crie pas « périmé »" "$(H json "$WORK/q16c.json" '/Statut noté dans STATE\.md : prête à exécuter/.test(j.answer)&&!/semble périmé/.test(j.answer)')" "true"
mkq "$WORK/q16b" statut_inventé; "$NODE" "$SCRIPTS/vf-cockpit-project.mjs" "$WORK/q16b" > "$WORK/q16bg.json"
assert_eq "Q16.4 — statut inconnu : omis du sous-titre, jamais affiché brut" "$(H json "$WORK/q16bg.json" '/inventé|statut_/.test(j.project.summary)')" "false"
mkdir -p "$WORK/q16d/.planning/phases/01-x"; printf -- '# Roadmap\n\n## Phases\n\n- [x] **Phase 1 : Socle** - fait\n- [ ] **Phase 2: Suite** - à faire\n\n### Phase 2: Suite\n**Goal** ok\n**Depends on** Phase 1 et plus\n' > "$WORK/q16d/.planning/ROADMAP.md"; printf -- '---\nstatus: executing\n---\n' > "$WORK/q16d/.planning/STATE.md"
H loc "$SCRIPTS" "$WORK/q16d" "Que veut dire lignes non comprises ?" > "$WORK/q16d.json"
assert_eq "Q16.6 — jointure lot 6 / lot 7 : sur un VRAI graphe (dérive mesurée par le panneau, champs ajoutés au lot 6), la réponse « lignes non comprises » donne le bon nombre (1), le bon fichier:ligne (ROADMAP.md:10) et le compte des autres écarts (3)" "$(H json "$WORK/q16d.json" '/\n1 ligne dans ce projet/.test(j.answer)&&/`\.planning\/ROADMAP\.md:10`/.test(j.answer)&&/3 lignes sont lues malgré/.test(j.answer)')" "true"
assert_eq "Q17.1 — mêmes clés : table serveur STATUTS et table navigateur STATUT" "$("$NODE" --input-type=module -e "
import fs from 'fs'; import { pathToFileURL } from 'url';
const S = (await import(pathToFileURL('$SCRIPTS/vf-cockpit-project.mjs').href)).STATUTS || {};
const src = fs.readFileSync('$SCRIPTS/../skills/cockpit-moteur/assets/ui/00-vibeflow.js', 'utf8');
const m = /const STATUT = \{([^}]*)\}/.exec(src); const B = {}; for (const e of (m?.[1] || '').matchAll(/(\w+):\s*'([^']*)'/g)) B[e[1]] = e[2];
const a = Object.keys(S).sort().join(','), b = Object.keys(B).sort().join(',');
console.log(a && a === b && Object.keys(S).every((k) => S[k] === B[k]) ? 'identiques' : 'divergent ' + a + ' | ' + b);")" "identiques"

echo "=== Q11 — constante = mesure ==="
if [ -n "$DEPOT" ]; then
  assert_eq "Q11.0a — dépôt de dev : la mesure du confinement est trouvée (un saut ici passerait pour un vert)" "$([ -n "$MESURE" ] && echo oui || echo non)" "oui"
fi
# Q11.0b : la mesure retenue est celle au plus grand numéro de phase (tri numérique : un tri lexical rendrait 9)
FD="$WORK/fauxdepot"; mkdir -p "$FD/.planning/a" "$FD/.planning/b" "$FD/.planning/c"
AVANT="$(mesure_de "$FD")"; [ -n "$AVANT" ] && AVANT=trouvée || AVANT=vide
: > "$FD/.planning/a/9-MESURE-claude-p.md"; : > "$FD/.planning/b/67-MESURE-claude-p.md"; : > "$FD/.planning/c/100-MESURE-claude-p.md"
assert_eq "Q11.0b — mesure_de : vide sans fichier, puis le plus grand numéro de phase (9, 67, 100)" "$AVANT|$(basename "$(mesure_de "$FD")")" "vide|100-MESURE-claude-p.md"
if [ -n "$MESURE" ]; then
  assert_eq "Q11.1 — la liste extraite de la mesure compte au moins 3 éléments" "$([ "$(grep -c . "$WORK/attendu.txt")" -ge 3 ] && echo oui || echo non)" "oui"
  assert_eq "Q11.2 — ARGS_CONFINEMENT = Combinaison retenue, élément par élément et dans l'ordre" "$(cmp -s "$WORK/const.txt" "$WORK/attendu.txt" && echo identique || echo different)" "identique"
  sed '$d' "$WORK/attendu.txt" > "$WORK/amputee.txt"
  assert_eq "Q11.3 — témoin rouge : la même comparaison contre la liste amputée de son dernier élément signale l'écart" "$(cmp -s "$WORK/const.txt" "$WORK/amputee.txt" && echo identique || echo different)" "different"
  assert_eq "Q11.4 — la comparaison a porté sur une constante non vide et un fichier attendu non vide" "$([ -s "$WORK/const.txt" ] && [ -s "$WORK/attendu.txt" ] && echo oui || echo non)" "oui"
else echo "  ⊘ Q11 sauté : mesure absente du dépôt installé (non comptée comme réussie)"; fi

echo "=== Q18 — retours panel lot 7 : un état par phase, coupe au mot, lignes non comprises (PU-G-096, 147, 150) ==="
"$NODE" --input-type=module -e "
import fs from 'fs';
const nd = (id, o) => ({ id, label: id, kind: 'phase', st: 'todo', parent: null, ...o });
const foot72 = '16/16 plans · ' + 'mot '.repeat(15) + 'interminément long';
const G = { nodes: [
  nd('ms-v2', { kind: 'milestone', label: 'v2', st: 'active', foot: '5 clos · 1 à recetter · 0 à faire · 83 %' }),
  nd('ms-v3', { kind: 'milestone', label: 'v3', st: 'active', foot: '1 clos · 3 à faire · 25 %' }),
  nd('ph-1', { label: 'Phase 1 · Fondations', num: '1', st: 'done', parent: 'ms-v2', foot: '2/2 plans' }),
  nd('ph-72', { label: 'Phase 72 · Lancer le travail', num: '72', st: 'recette', parent: 'ms-v2', foot: 'à recetter · ' + foot72 }),
  nd('ph-1.req', { kind: 'exigences', label: 'Exigences', st: 'active', parent: 'ph-1', foot: '1/2' }),
], files: [
  { p: 'req/AA-01', n: 'ph-1.req', name: 'AA-01', st: 'active', d: 'mot '.repeat(15) + 'centralisation de la suite' },
], links: [], meta: { vf: { milestone: 'v2', phase: '72', status: 'ready_to_plan', lastActivity: '2026-11-05', milestones: [{ key: 'v2', id: 'n:ms-v2' }, { key: 'v3', id: 'n:ms-v3' }], drift: { nonComprisesN: 4, corrigeable: true, regles: [{ regle: 'ligne-non-comprise', n: 4 }, { regle: 'autre', n: 2 }], nonComprises: [{ fichier: '.planning/ROADMAP.md', ligne: 486, extrait: 'Une ligne qui ressemble à un champ mais qui n est pas lisible ' + 'x'.repeat(30) + 'gauche ensuite' }, { fichier: '.planning/REQUIREMENTS.md', ligne: 12, extrait: 'court' }] } } } };
fs.writeFileSync('$WORK/q18g.json', JSON.stringify(G));
const H = JSON.parse(JSON.stringify(G)); H.meta.vf.drift = { nonComprisesN: 0, regles: [], nonComprises: [] }; fs.writeFileSync('$WORK/q18h.json', JSON.stringify(H));
"
assert_eq "Q18.0 — témoin vivant : le pied de la phase dépasse 90 caractères et la coupe tombe dans un mot" "$(H json "$WORK/q18g.json" "(() => { const f = j.nodes.find((n) => n.id === 'ph-72').foot; return f.length > 90 && /[a-z]/.test(f[89]) && /[a-z]/.test(f[90]) })()")" "true"
H locg "$SCRIPTS" "$WORK/q18g.json" "Où en est le jalon ?" > "$WORK/q18a.json"
assert_eq "Q18.1 — « Où en est le jalon ? » : aucun « sans statut », ni dans le texte ni dans les notes" "$(H json "$WORK/q18a.json" '/sans statut/.test(j.answer + j.items.map((i) => i.note).join())')" "false"
assert_eq "Q18.2 — la Phase 72 n'est citée qu'une fois dans le texte" "$(H json "$WORK/q18a.json" "j.answer.split('[[n:ph-72]]').length - 1")" "1"
assert_eq "Q18.3 — chaque carte n'est listée qu'une fois dans le tableau" "$(H json "$WORK/q18a.json" 'j.items.length === new Set(j.items.map((i) => i.id)).size')" "true"
assert_eq "Q18.4 — les autres jalons en cours sont cités et listés" "$(H json "$WORK/q18a.json" "j.answer.includes('[[n:ms-v3]]') && j.items.some((i) => i.id === 'n:ms-v3')")" "true"
assert_eq "Q18.5 — la phase en recette ne répète pas « à recetter » dans sa propre ligne" "$(H json "$WORK/q18a.json" "!/recetter · à recetter/.test(j.answer + j.items.map((i) => i.note).join('|'))")" "true"
H locg "$SCRIPTS" "$WORK/q18g.json" "Que contient la phase 72 ?" > "$WORK/q18p.json"
assert_eq "Q18.6 — la carte d'une phase en recette : « à recetter » une fois, pas « sans statut »" "$(H json "$WORK/q18p.json" "!/sans statut|recetter · à recetter/.test(j.answer)")" "true"
H locg "$SCRIPTS" "$WORK/q18g.json" "Qu'est-ce qui est en cours ?" > "$WORK/q18c.json"
assert_eq "Q18.7 — « en cours » : aucune exigence d'une phase faite" "$(H json "$WORK/q18c.json" "!j.answer.includes('ph-1.req') && !j.items.some((i) => i.id.includes('ph-1.req') || i.id.includes('req/AA-01'))")" "true"
assert_eq "Q18.8 — « en cours » : les jalons en cours restent listés" "$(H json "$WORK/q18c.json" "j.answer.includes('[[n:ms-v3]]') && j.answer.includes('[[n:ms-v2]]')")" "true"
H locg "$SCRIPTS" "$WORK/q18g.json" "Quelles sont les exigences de la phase 1 ?" > "$WORK/q18r.json"
assert_eq "Q18.9 — témoin rouge/vert PU-G-147 : la coupe à 70 caractères ne laisse pas de mot tronqué (« centr »)" "$(H json "$WORK/q18r.json" '!/centr/.test(j.answer)')" "true"
assert_eq "Q18.10 — la coupe à 90 caractères d'une note s'arrête sur un mot entier (« … mot… », jamais « … in… »)" "$(H json "$WORK/q18a.json" "(() => { const n = j.items.find((i) => i.id === 'n:ph-72').note; return n.endsWith(' mot…') })()")" "true"
assert_eq "Q18.11 — une note coupée reste sous 90 caractères" "$(H json "$WORK/q18a.json" 'j.items.every((i) => i.note.length <= 90)')" "true"
for fq in "qu'est-ce que ça veut dire, « lignes du planning non comprises » ?" "Pourquoi des lignes non comprises dans le planning ?" "C'est quoi les lignes non comprises ?"; do
  H locg "$SCRIPTS" "$WORK/q18g.json" "$fq" > "$WORK/q18f.json"
  assert_eq "Q18.12 — réponse locale à « $fq »" "$(H json "$WORK/q18f.json" 'j !== null && j.engine === "local"')" "true"
done
assert_eq "Q18.13 — la réponse donne le nombre, un fichier:ligne et dit que rien n'est modifié" "$(H json "$WORK/q18f.json" "/4 ligne/.test(j.answer) && j.answer.includes('.planning/ROADMAP.md:486') && /rien n.est modifi/i.test(j.answer)")" "true"
assert_eq "Q18.14 — l'extrait long est coupé au mot (le mot trop long est retiré, jamais tronqué en « xxxx »)" "$(H json "$WORK/q18f.json" '!/xxx/.test(j.answer)')" "true"
assert_eq "Q18.15 — aucun mot de l'intérieur du panneau (clé de règle, « null », « undefined ») dans la réponse" "$(H json "$WORK/q18f.json" '!/ligne-non-comprise|null|undefined/.test(j.answer)')" "true"
H locg "$SCRIPTS" "$WORK/q18h.json" "lignes du planning non comprises ?" > "$WORK/q18z.json"
assert_eq "Q18.16 — aucune ligne non comprise : la réponse le dit, sans liste vide" "$(H json "$WORK/q18z.json" "/aucune ligne/i.test(j.answer) && !/Lignes? concern/.test(j.answer)")" "true"

assert_eq "Q18.17 — témoin de linéarité : 40 000 « ligne » sans « non compris » se traitent en moins de 2 s (le motif de PU-G-150 n'est pas quadratique ; mesuré avant correction : 38 s)" "$("$NODE" --input-type=module -e "
import { answerLocally } from '$SCRIPTS/vf-cockpit-ask.mjs';
const t = Date.now(); answerLocally({ nodes: [], files: [], links: [], meta: { vf: {} } }, 'ligne '.repeat(40000) + 'x'); console.log(Date.now() - t < 2000);")" "true"

# Q18.18 — PU-G-147 (recette du 2026-11-08) : le pied d'une exigence (sentence, 120 car.) se coupe au mot entier ; témoin rouge sur 82de0712 : « … puis avec le vr… »
assert_eq "Q18.18 — la phrase d'une exigence coupée à 120 caractères ne finit pas dans un mot (« vr… » pour « vrai »), et reste sous 120" "$("$NODE" --input-type=module -e "
import { sentence } from '$SCRIPTS/vf-cockpit-planning.mjs';
const t = 'Usage réel et non-régression : de bout en bout dans Chromium avec un faux claude dans le PATH (suites), puis avec le vrai claude local.';
const a = sentence(t, 120), mot = a.replace(/…\$/, '').split(' ').pop();
console.log(a.endsWith('…') && a.length <= 120 && t.split(' ').includes(mot) && /\\S…\$/.test(a));")" "true"

# Q18.19 à Q18.21 — PU-G-150 (recette du 2026-11-08) : la réponse « Format » répond aussi aux formulations naturelles et au mot du panneau (« Non lu »), sans capter une question sans rapport
for fq in "Quelle est la commande pour corriger les lignes non comprises ?" "Quelles lignes du planning ne sont pas comprises ?" "Quelles lignes du planning ne sont pas lues ?" "Pourquoi les chiffres sont-ils peut-être incomplets ?" "Quelles lignes sont non lues ?"; do
  H locg "$SCRIPTS" "$WORK/q18g.json" "$fq" > "$WORK/q18n.json"
  assert_eq "Q18.19 — réponse locale « Format » à « $fq »" "$(H json "$WORK/q18n.json" 'j !== null && j.engine === "local" && /4 ligne/.test(j.answer)')" "true"
done
assert_eq "Q18.20 — le vocabulaire de la réponse est celui du panneau : « non lue » et « Non lu », plus « ligne non comprise »" "$(H json "$WORK/q18n.json" "/non lue/.test(j.answer + j.title) && /Non lu/.test(j.answer) && !/non compris/i.test(j.answer + j.title)")" "true"
for fq in "Pourquoi la phase 72 est-elle en recette ?" "Quelles sont les lignes de commande de la phase 72 ?" "Le plan est-il incomplet ?" "Pourquoi le nombre de plans de la phase 72 est-il incomplet ?" "La ligne de commande du lanceur n'est pas comprise" "Quelle ligne de la phase 3 n'est pas lue ?" "La phase 3 n'est pas lundi, quelle ligne ?" "Quelles lignes de code ne sont pas comprises ?"; do
  H locg "$SCRIPTS" "$WORK/q18g.json" "$fq" > "$WORK/q18m.json"
  assert_eq "Q18.21 — témoin négatif : « $fq » ne déclenche pas la réponse « Format »" "$(H json "$WORK/q18m.json" 'j === null || !/Lignes du planning non lues/.test(j.title)')" "true"
done

# Q19 — libellés du Projet tranchés par Samuel (arbitrage Samuel, AskUserQuestion session principale, 2026-11-08, consigné en § 10 du rapport GLOBAL de la recette (3da818fe)) : accord réel des compteurs (L1)
"$NODE" --input-type=module -e "
import fs from 'node:fs';
const nd = (id, o) => ({ id, label: id, kind: 'phase', st: 'todo', parent: null, ...o });
const bl = (n) => Array.from({ length: n }, (_, i) => ({ p: 'dag/' + i, n: 'ph-2', name: 'b' + i, st: 'blocked', d: 'x' }));
const mk = (nb) => ({ nodes: [nd('ms-v2', { kind: 'milestone', label: 'v2', st: 'active' }), nd('ph-2', { label: 'Phase 2 · Deux', num: '2', st: 'active', parent: 'ms-v2' }), nd('ph-2.req', { kind: 'exigences', label: 'Exigences', st: 'active', parent: 'ph-2' })],
  files: [...bl(nb), { p: 'req/B-01', n: 'ph-2.req', name: 'B-01', st: 'todo', d: 'un' }, { p: 'req/B-02', n: 'ph-2.req', name: 'B-02', st: 'todo', d: 'deux' }], links: [], meta: { vf: { milestone: 'v2', phase: '2' } } });
fs.writeFileSync('$WORK/q19-1.json', JSON.stringify(mk(1))); fs.writeFileSync('$WORK/q19-4.json', JSON.stringify(mk(4)));"
H locg "$SCRIPTS" "$WORK/q19-4.json" "Qu'est-ce qui bloque ?" > "$WORK/q19a.json"
H locg "$SCRIPTS" "$WORK/q19-1.json" "Qu'est-ce qui bloque ?" > "$WORK/q19b.json"
assert_eq "Q19.1 — L1 : 4 éléments bloqués -> « 4 bloqués » et « 4 éléments bloqués », jamais « (s) »" "$(H json "$WORK/q19a.json" "j.title === '4 bloqués' && j.answer.startsWith('4 éléments bloqués') && !/\\(s\\)/.test(j.title + j.answer)")" "true"
assert_eq "Q19.2 — L1 : 1 élément bloqué -> « 1 bloqué » et « 1 élément bloqué »" "$(H json "$WORK/q19b.json" "j.title === '1 bloqué' && j.answer.startsWith('1 élément bloqué ') && !/\\(s\\)/.test(j.title + j.answer)")" "true"
H locg "$SCRIPTS" "$WORK/q19-1.json" "Quelles sont les exigences de la phase 2 ?" > "$WORK/q19c.json"
assert_eq "Q19.3 — L1 : compteur voisin, 2 exigences -> « 2 exigences pour », sans « (s) »" "$(H json "$WORK/q19c.json" "j.answer.startsWith('2 exigences pour') && !/\\(s\\)/.test(j.answer)")" "true"
H locg "$SCRIPTS" "$WORK/q18g.json" "Quelles sont les exigences de la phase 1 ?" > "$WORK/q19d.json"
assert_eq "Q19.4 — L1 : compteur voisin, 1 exigence -> « 1 exigence pour »" "$(H json "$WORK/q19d.json" "j.answer.startsWith('1 exigence pour')")" "true"

# Q19.5 à Q19.6 — L2 (même arbitrage, § 10) : la pastille de relance d'une phase dit « dans la Phase 2 ? » avec l'article ; un jalon garde sa forme
H locg "$SCRIPTS" "$WORK/q19-1.json" "Que contient la phase 2 ?" > "$WORK/q19e.json"
assert_eq "Q19.5 — L2 : relances d'une phase -> « Qu'est-ce qui reste dans la Phase 2 ? » et « Qu'est-ce qui bloque dans la Phase 2 ? »" "$(H json "$WORK/q19e.json" "j.followups.includes(\"Qu'est-ce qui reste dans la Phase 2 ?\") && j.followups.includes(\"Qu'est-ce qui bloque dans la Phase 2 ?\")")" "true"
H locg "$SCRIPTS" "$WORK/q19-1.json" "Qu'est-ce qui reste dans le jalon v2 ?" > "$WORK/q19f.json"
assert_eq "Q19.6 — L2 : témoin, la relance d'un jalon reste « dans v2 » (pas d'article inventé)" "$(H json "$WORK/q19f.json" "j.followups.includes(\"Qu'est-ce qui bloque dans v2 ?\")")" "true"

# Q20 — revue de 82de0712..3f972a6b : R1 (aucun libellé affiché ne se coupe en plein mot) et R3 (coupe exactement sur un espace)
mkdir -p "$WORK/lab20/.planning/phases/01-premiere"
printf '# Roadmap\n\n## Milestone v1\n\n### Phase 1: Premiere\n**Goal:** faire la chose\n' > "$WORK/lab20/.planning/ROADMAP.md"
printf -- '---\nphase: 01\nplan: 01\n---\n<objective>\nScaffolder le monorepo, le packaging et la chaîne de construction afin de livrer une première version installable et lisible\n</objective>\n' > "$WORK/lab20/.planning/phases/01-premiere/01-01-PLAN.md"
assert_eq "Q20.1 — R1 : le nom d'un plan de plus de 70 caractères se coupe au mot entier (« … construction… », jamais « … afi… »), et reste sous 70" "$("$NODE" --input-type=module -e "
import { buildProjectGraph } from '$SCRIPTS/vf-cockpit-project.mjs';
const g = buildProjectGraph('$WORK/lab20'), f = g.files.find((x) => x.name.startsWith('01-01'));
const obj = 'Scaffolder le monorepo, le packaging et la chaîne de construction afin de livrer une première version installable et lisible';
const part = f.name.split(' — ').slice(1).join(' — '), tete = part.replace(/…\$/, '');
console.log(part.endsWith('…') && part.length <= 70 && obj.startsWith(tete) && obj[tete.length] === ' ');")" "true"
assert_eq "Q20.2 — R1 : la coupe du pied d'exigence et celle du nom sont la MÊME fonction (clip = clipMot sur 5 longueurs)" "$("$NODE" --input-type=module -e "
import { clip, clipMot } from '$SCRIPTS/vf-cockpit-planning.mjs';
const t = 'un deux trois quatre cinq six sept huit neuf dix onze douze';
console.log([5, 12, 20, 33, 80].every((n) => clip(t, n) === clipMot(t, n)));")" "true"
assert_eq "Q20.3 — R3 : une coupe qui tombe exactement sur une espace garde le mot entier avant elle (« aaaa bbbb… »), une coupe dans un mot le retire (« aaaa… »)" "$("$NODE" --input-type=module -e "
import { clipMot } from '$SCRIPTS/vf-cockpit-planning.mjs';
console.log(clipMot('aaaa bbbb cccc', 10) + '|' + clipMot('aaaa bbbbb', 9));")" "aaaa bbbb…|aaaa…"

# Q19.7 — M1 (contre-revue) : le compteur de statuts de « Que contient la phase ? » s'accorde aussi (arbitrage de L1, § 10 du rapport GLOBAL, 3da818fe)
"$NODE" --input-type=module -e "
import fs from 'node:fs';
const nd = (id, o) => ({ id, label: id, kind: 'phase', st: 'todo', parent: null, ...o });
const f = (n, st, k) => Array.from({ length: n }, (_, i) => ({ p: 'p/' + st + k + i, n: 'ph-3', name: st + i, st, d: 'x' }));
const mk = (a, b, c) => ({ nodes: [nd('ph-3', { label: 'Phase 3 · Trois', num: '3', st: 'active' })], files: [...f(a, 'blocked', 'b'), ...f(b, 'done', 'd'), ...f(c, 'active', 'a')], links: [], meta: { vf: {} } });
fs.writeFileSync('$WORK/q19-c1.json', JSON.stringify(mk(1, 1, 1))); fs.writeFileSync('$WORK/q19-c4.json', JSON.stringify(mk(4, 27, 2)));"
H locg "$SCRIPTS" "$WORK/q19-c4.json" "Que contient la phase 3 ?" > "$WORK/q19g.json"
H locg "$SCRIPTS" "$WORK/q19-c1.json" "Que contient la phase 3 ?" > "$WORK/q19h.json"
assert_eq "Q19.7 — M1 : n > 1 -> « 4 bloqués », « 27 faits », « 2 en cours » (invariable) ; n = 1 -> « 1 bloqué », « 1 fait », « 1 en cours »" "$(H json "$WORK/q19g.json" "/4 bloqués/.test(j.answer) && /27 faits/.test(j.answer) && /2 en cours/.test(j.answer)")|$(H json "$WORK/q19h.json" "/1 bloqué[,.]/.test(j.answer) && /1 fait,/.test(j.answer) && /1 en cours/.test(j.answer) && !/1 (bloqués|faits)/.test(j.answer)")" "true|true"

# Q19.8 — M2 : l'article s'étend aux missions (arbitrage Samuel, AskUserQuestion session principale, 2026-11-08, consigné en § 10 du rapport GLOBAL de la recette (3f67e7aa)) ; la phase (Q19.5) et le jalon (Q19.6) ne bougent pas
"$NODE" --input-type=module -e "
import fs from 'node:fs';
const g = JSON.parse(fs.readFileSync('$WORK/q19-1.json', 'utf8'));
g.nodes.push({ id: 'dag-MISSION-414', label: 'Mission 414', kind: 'mission', st: 'active', parent: 'ms-v2' });
fs.writeFileSync('$WORK/q19-m.json', JSON.stringify(g));"
H locg "$SCRIPTS" "$WORK/q19-m.json" "Que contient la mission 414 ?" > "$WORK/q19i.json"
assert_eq "Q19.8 — M2 : relances d'une mission -> « … reste dans la Mission 414 ? » et « … bloque dans la Mission 414 ? »" "$(H json "$WORK/q19i.json" "j.followups.includes(\"Qu'est-ce qui reste dans la Mission 414 ?\") && j.followups.includes(\"Qu'est-ce qui bloque dans la Mission 414 ?\")")" "true"

# Q18.22 — M7c : sentence() du build (descriptions de l'onglet Code) coupe au mot entier ; rouge sur 82de0712 (« … avec le vr… »)
assert_eq "Q18.22 — M7c : la phrase d'une description de fichier (build) coupée à 120 caractères ne finit pas dans un mot, et reste sous 120" "$("$NODE" --input-type=module -e "
import { sentence } from '$SCRIPTS/vf-cockpit-build.mjs';
const t = 'Usage réel et non-régression : de bout en bout dans Chromium avec un faux claude dans le PATH (suites), puis avec le vrai claude local.';
const a = sentence(t, 120), mot = a.replace(/…\$/, '').split(' ').pop();
console.log(a.endsWith('…') && a.length <= 120 && t.split(' ').includes(mot));")" "true"

vf_hyg_assert
echo ""
echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
TOTAL=$((PASS+FAIL))
if [ "$TOTAL" -eq 0 ]; then
  echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée, résultat non fiable"
  exit 1
fi
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
