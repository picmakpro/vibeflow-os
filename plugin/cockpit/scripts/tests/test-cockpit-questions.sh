#!/usr/bin/env bash
# test-cockpit-questions.sh — questions de l'onglet Projet et agent confiné (CKPT-07 ; P67-D-01, P67-D-08, P67-D-15).
#   Q1 forme courante locale · Q2 raisonnement -> agent confiné (argv = combinaison mesurée) · Q3 onglet Code, même confinement
#   Q4 modèle : préséance et liste fermée · Q5 question piégée inoffensive · Q6 le modèle ne laisse aucune trace
#   Q7 seul Claude Code est lancé · Q8 syntaxe et jeton de /api/vf/modeles · Q9 CLI de requête · Q10 identité de phase
#   Q11 ARGS_CONFINEMENT = « Combinaison retenue » de la mesure (dépôt seulement)
# Faux binaires claude et codex (node) en tête du PATH ; aucun vrai appel. Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"; mkdir -p "$WORK/aux" "$WORK/home"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"
export HOME="$WORK/home"; NODE="$(command -v node)"
SRV=""
stop_srv() { [ -n "$SRV" ] && { kill "$SRV" 2>/dev/null; wait "$SRV" 2>/dev/null; }; SRV=""; }
trap 'stop_srv; [ -n "${KEEP:-}" ] || rm -rf "$WORK"' EXIT
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
  env PATH="$P" VF_FAKE_DIR="$FK" "$@" "$NODE" "$OUT/serve.mjs" --no-open --port $((4400 + RANDOM % 500)) > "$WORK/serve.out" 2>&1 &
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
MESURE=""; [ -f "$SCRIPTS/../amont/synchro.sh" ] && MESURE="$(find "$SCRIPTS/../../../.planning" -name '67-MESURE-claude-p.md' 2>/dev/null | head -1)"
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

echo "=== Q11 — constante = mesure ==="
if [ -n "$MESURE" ]; then
  assert_eq "Q11.1 — la liste extraite de la mesure compte au moins 3 éléments" "$([ "$(grep -c . "$WORK/attendu.txt")" -ge 3 ] && echo oui || echo non)" "oui"
  assert_eq "Q11.2 — ARGS_CONFINEMENT = Combinaison retenue, élément par élément et dans l'ordre" "$(cmp -s "$WORK/const.txt" "$WORK/attendu.txt" && echo identique || echo different)" "identique"
  sed '$d' "$WORK/attendu.txt" > "$WORK/amputee.txt"
  assert_eq "Q11.3 — témoin rouge : la même comparaison contre la liste amputée de son dernier élément signale l'écart" "$(cmp -s "$WORK/const.txt" "$WORK/amputee.txt" && echo identique || echo different)" "different"
  assert_eq "Q11.4 — la comparaison a porté sur une constante non vide et un fichier attendu non vide" "$([ -s "$WORK/const.txt" ] && [ -s "$WORK/attendu.txt" ] && echo oui || echo non)" "oui"
else echo "  ⊘ Q11 sauté : mesure absente du dépôt installé (non comptée comme réussie)"; fi

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
