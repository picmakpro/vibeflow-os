#!/usr/bin/env bash
# test-cockpit-questions.sh — questions de l'onglet Projet et agent confiné (CKPT-07 ; P67-D-01, P67-D-08, P67-D-15).
#   Q1 forme courante locale · Q2 raisonnement -> agent confiné (argv = combinaison mesurée) · Q3 onglet Code, même confinement
#   Q4 modèle : préséance et liste fermée · Q5 question piégée inoffensive · Q6 le modèle ne laisse aucune trace
#   Q7 seul Claude Code est lancé · Q8 syntaxe et jeton de /api/vf/modeles · Q9 CLI de requête · Q10 identité de phase
#   Q11 ARGS_CONFINEMENT = « Combinaison retenue » de la mesure (dépôt seulement)
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
assert_eq "Q16.2 — la réponse locale porte le libellé français « prêt à exécuter »" "$(H json "$WORK/q16.json" '/prêt à exécuter/.test(j.answer)')" "true"
"$NODE" "$SCRIPTS/vf-cockpit-project.mjs" "$WORK/q16" > "$WORK/q16g.json"
assert_eq "Q16.3 — sous-titre du graphe (CLI) : libellé français, aucun tiret bas" "$(H json "$WORK/q16g.json" '/prêt à exécuter/.test(j.project.summary)&&!/_/.test(j.project.summary)')" "true"
mkq "$WORK/q16b" statut_inventé; "$NODE" "$SCRIPTS/vf-cockpit-project.mjs" "$WORK/q16b" > "$WORK/q16bg.json"
assert_eq "Q16.4 — statut inconnu : omis du sous-titre, jamais affiché brut" "$(H json "$WORK/q16bg.json" '/inventé|statut_/.test(j.project.summary)')" "false"
assert_eq "Q17.1 — mêmes clés : table serveur STATUTS et table navigateur STATUT" "$("$NODE" --input-type=module -e "
import fs from 'fs'; import { pathToFileURL } from 'url';
const S = (await import(pathToFileURL('$SCRIPTS/vf-cockpit-project.mjs').href)).STATUTS || {};
const src = fs.readFileSync('$SCRIPTS/../skills/cockpit-moteur/assets/ui/00-vibeflow.js', 'utf8');
const m = /const STATUT = \{([^}]*)\}/.exec(src); const B = {}; for (const e of (m?.[1] || '').matchAll(/(\w+):\s*'([^']*)'/g)) B[e[1]] = e[2];
const a = Object.keys(S).sort().join(','), b = Object.keys(B).sort().join(',');
console.log(a && a === b && Object.keys(S).every((k) => S[k] === B[k]) ? 'identiques' : 'divergent ' + a + ' | ' + b);")" "identiques"

echo "=== Q11 — constante = mesure ==="
if [ -n "$MESURE" ]; then
  assert_eq "Q11.1 — la liste extraite de la mesure compte au moins 3 éléments" "$([ "$(grep -c . "$WORK/attendu.txt")" -ge 3 ] && echo oui || echo non)" "oui"
  assert_eq "Q11.2 — ARGS_CONFINEMENT = Combinaison retenue, élément par élément et dans l'ordre" "$(cmp -s "$WORK/const.txt" "$WORK/attendu.txt" && echo identique || echo different)" "identique"
  sed '$d' "$WORK/attendu.txt" > "$WORK/amputee.txt"
  assert_eq "Q11.3 — témoin rouge : la même comparaison contre la liste amputée de son dernier élément signale l'écart" "$(cmp -s "$WORK/const.txt" "$WORK/amputee.txt" && echo identique || echo different)" "different"
  assert_eq "Q11.4 — la comparaison a porté sur une constante non vide et un fichier attendu non vide" "$([ -s "$WORK/const.txt" ] && [ -s "$WORK/attendu.txt" ] && echo oui || echo non)" "oui"
else echo "  ⊘ Q11 sauté : mesure absente du dépôt installé (non comptée comme réussie)"; fi

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
