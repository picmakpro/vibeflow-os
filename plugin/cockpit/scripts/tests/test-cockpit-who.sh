#!/usr/bin/env bash
# test-cockpit-who.sh — socle du cockpit : « au travail » et graphe Projet au contrat versionné
# vibeflow/cockpit-*@1 (P67-D-12, P67-D-14). Fixtures reconstruites dans mktemp à chaque appel.
#   W1 session fraîche listée (témoin positif) · W2 verrou via un driver-lock.sh de HOME
#   W3 graphe Projet d'un lab plat minimal · W4 validateur du contrat (et son refus de `doing`)
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
AUX="$WORK/aux"; HOME_T="$WORK/home"; NOSCRIPTS="$WORK/noscripts"
mkdir -p "$AUX" "$HOME_T/.claude/scripts" "$NOSCRIPTS"

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_not() { if [[ "$2" != *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (a trouvé [$3])"; FAIL=$((FAIL+1)); fi; }

# --- outils node écrits par la suite (jamais de long node -e) ---
cat > "$AUX/q.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const [, , scripts, what, root, home, scriptsDir, extra] = process.argv;
const imp = (f) => import(pathToFileURL(path.join(scripts, f)).href);
if (what === 'who') { const m = await imp('vf-cockpit-who.mjs'); console.log(JSON.stringify(m.collectWho(root, { home, scriptsDir }))); }
else if (what === 'reveal') { const m = await imp('vf-cockpit-who.mjs'); console.log(JSON.stringify(m.revealDoing(root, extra, { home, scriptsDir }))); }
else if (what === 'project') { const m = await imp('vf-cockpit-project.mjs'); console.log(JSON.stringify(m.buildProjectGraph(root))); }
JS
cat > "$AUX/get.mjs" <<'JS'
import fs from 'node:fs';
const j = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const v = new Function('j', 'return (' + process.argv[3] + ')')(j);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/validate.mjs" <<'JS'
// validate.mjs <interface.json> <schemaId> <sortie.json> — clés requises et typées, clés interdites à toute profondeur
import fs from 'node:fs';
const [, , ifaceF, id, outF] = process.argv;
const spec = JSON.parse(fs.readFileSync(ifaceF, 'utf8')).schemas[id];
const out = JSON.parse(fs.readFileSync(outF, 'utf8'));
const errs = [];
const type = (v) => (Array.isArray(v) ? 'array' : v === null ? 'null' : typeof v);
for (const [k, t] of Object.entries(spec.requis || {})) {
  if (!(k in out)) errs.push(`clé requise absente : ${k}`);
  else if (t !== 'any' && type(out[k]) !== t) errs.push(`type de ${k} : ${type(out[k])} au lieu de ${t}`);
}
if (out.schema !== id) errs.push(`schema = ${out.schema}`);
const deep = (o, f) => { if (o && typeof o === 'object') for (const [k, v] of Object.entries(o)) { f(k); deep(v, f); } };
deep(out, (k) => { if ((spec.interdits || []).includes(k)) errs.push(`clé interdite présente : ${k}`); });
for (const w of out.workers || []) {
  for (const k of spec.travailleur.requis) if (!(k in w)) errs.push(`travailleur ${w.id} : clé ${k} absente`);
  if (!spec.kinds.includes(w.kind)) errs.push(`kind inconnu : ${w.kind}`);
}
for (const s of Object.values(out.sources || {})) if (!spec.etatsSource.includes(s.etat)) errs.push(`état de source inconnu : ${s.etat}`);
for (const n of out.nodes || []) for (const k of spec.noeud?.requis || []) if (!(k in n)) errs.push(`nœud ${n.id} : clé ${k} absente`);
for (const f of out.files || []) for (const k of spec.element?.requis || []) if (!(k in f)) errs.push(`élément ${f.p} : clé ${k} absente`);
for (const l of out.links || []) for (const k of spec.lien?.requis || []) if (!(k in l)) errs.push(`lien : clé ${k} absente`);
for (const k of spec.meta?.requis || []) if (!(k in (out.meta || {}))) errs.push(`meta.${k} absente`);
console.log(errs.length ? 'KO ' + errs.join(' | ') : 'OK');
process.exit(errs.length ? 1 : 0);
JS
cat > "$AUX/stdin-get.mjs" <<'JS'
import fs from 'node:fs';
const j = JSON.parse(fs.readFileSync(0, 'utf8'));
const v = new Function('j', 'return (' + process.argv[2] + ')')(j);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
Q() { node "$AUX/q.mjs" "$SCRIPTS" "$@"; }
G() { node "$AUX/get.mjs" "$@"; }
IFACE="$SCRIPTS/vf-cockpit-interface.json"

# --- fixture : lab git jetable + session Claude Code fraîche ---
LAB="$WORK/lab"; mkdir -p "$LAB"; git -C "$LAB" init -q
SID="aaaa1111-2222-3333-4444-555566667777"
TRD="$HOME_T/.claude/projects/-lab"; mkdir -p "$TRD"
mk_session() { # $1 = fichier, $2 = clé du cwd, $3 = description du dernier appel
  printf '%s\n' "{\"type\":\"user\",\"$2\":\"$LAB\",\"sessionId\":\"$SID\",\"timestamp\":\"2026-11-01T10:00:00Z\",\"gitBranch\":\"main\",\"version\":\"2.1.316\",\"message\":{\"content\":\"salut\"}}" \
    "{\"type\":\"assistant\",\"$2\":\"$LAB\",\"sessionId\":\"$SID\",\"timestamp\":\"2026-11-01T10:00:05Z\",\"gitBranch\":\"main\",\"version\":\"2.1.316\",\"message\":{\"content\":[{\"type\":\"tool_use\",\"name\":\"Bash\",\"input\":{\"description\":\"$3\"}}]}}" > "$1"
}
mk_session "$TRD/$SID.jsonl" cwd "MARQUEUR-DERNIERE-COMMANDE"

echo "=== W1 — session fraîche listée ==="
Q who "$LAB" "$HOME_T" "$NOSCRIPTS" > "$WORK/who.json"
assert_eq "W1.1 — schéma nommé VibeFlow" "$(G "$WORK/who.json" 'j.schema')" "vibeflow/cockpit-who@1"
assert_eq "W1.2 — la session fraîche est un travailleur kind=session" "$(G "$WORK/who.json" 'j.workers.filter(w=>w.kind==="session"&&w.id==="'$SID'").length')" "1"
assert_eq "W1.3 — source sessions lue" "$(G "$WORK/who.json" 'j.sources.sessions.etat')" "lue"

echo "=== W2 — verrou via le driver-lock.sh de HOME ==="
cat > "$HOME_T/.claude/scripts/driver-lock.sh" <<'SH'
#!/usr/bin/env bash
case "$1" in
  status) echo '{"locks":[{"present":true,"owner":"mgr-test","step":"exec","ws":"","scope":"repo","age_seconds":10,"stale":false,"children_running":0}]}' ;;
  orphans) echo '{"orphans":[]}' ;;
esac
SH
Q who "$LAB" "$HOME_T" "$NOSCRIPTS" > "$WORK/who2.json"
assert_eq "W2.1 — un travailleur kind=lock" "$(G "$WORK/who2.json" 'j.workers.filter(w=>w.kind==="lock").map(w=>w.id).join(",")')" "mgr-test"
assert_eq "W2.2 — source locks lue" "$(G "$WORK/who2.json" 'j.sources.locks.etat')" "lue"

echo "=== W3 — graphe Projet d'un lab plat minimal ==="
FLAT="$WORK/flat"; mkdir -p "$FLAT/.planning/phases/01-x"
cat > "$FLAT/.planning/ROADMAP.md" <<'MD'
# Roadmap
- [x] **Phase 1: Socle** - premier jet
MD
printf '%s\n' '<objective>Faire le socle</objective>' > "$FLAT/.planning/phases/01-x/01-01-PLAN.md"
printf '%s\n' 'ok' > "$FLAT/.planning/phases/01-x/01-01-SUMMARY.md"
Q project "$FLAT" > "$WORK/proj.json"
assert_eq "W3.1 — schéma Projet nommé VibeFlow" "$(G "$WORK/proj.json" 'j.schema')" "vibeflow/cockpit-project@1"
assert_eq "W3.2 — ph-1 est fait" "$(G "$WORK/proj.json" 'j.nodes.filter(n=>n.id==="ph-1").map(n=>n.st).join(",")')" "done"
assert_eq "W3.3 — le plan 01-01 est fait" "$(G "$WORK/proj.json" 'j.files.filter(f=>f.name.startsWith("01-01")).map(f=>f.st).join(",")')" "done"

echo "=== W4 — validateur du contrat versionné ==="
assert_eq "W4.1 — sortie « au travail » conforme" "$(node "$AUX/validate.mjs" "$IFACE" vibeflow/cockpit-who@1 "$WORK/who2.json")" "OK"
assert_eq "W4.2 — graphe Projet conforme" "$(node "$AUX/validate.mjs" "$IFACE" vibeflow/cockpit-project@1 "$WORK/proj.json")" "OK"
node -e 'const fs=require("fs");const j=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));j.workers[0].doing="x";fs.writeFileSync(process.argv[2],JSON.stringify(j))' "$WORK/who2.json" "$WORK/who-doing.json"
R=$(node "$AUX/validate.mjs" "$IFACE" vibeflow/cockpit-who@1 "$WORK/who-doing.json"); RC=$?
assert_has "W4.3 — témoin : un champ doing ajouté est refusé" "$R" "clé interdite présente : doing"
assert_eq "W4.4 — témoin : code de sortie non nul" "$RC" "1"

echo "=== W5 — la collecte ne porte jamais la dernière commande ==="
MARK="MARQUEUR-DERNIERE-COMMANDE"
assert_eq "W5.1 — aucune clé doing à aucune profondeur" "$(grep -c '"doing"' "$WORK/who.json")" "0"
assert_eq "W5.2 — le marqueur est absent de la collecte" "$(grep -c "$MARK" "$WORK/who.json")" "0"
Q reveal "$LAB" "$HOME_T" "$NOSCRIPTS" "$SID" > "$WORK/rev.json"
assert_has "W5.3 — témoin positif : revealDoing rend le marqueur" "$(G "$WORK/rev.json" 'j.doing')" "$MARK"
assert_eq "W5.4 — schéma de la révélation" "$(G "$WORK/rev.json" 'j.schema')" "vibeflow/cockpit-doing@1"

echo "=== W6 — identifiant strict ==="
assert_eq "W6.1 — traversée refusée" "$(Q reveal "$LAB" "$HOME_T" "$NOSCRIPTS" '../../etc/passwd' | node "$AUX/stdin-get.mjs" 'j.erreur')" "id-invalide"
assert_eq "W6.2 — identifiant bien formé absent de la collecte" "$(Q reveal "$LAB" "$HOME_T" "$NOSCRIPTS" 'inconnu-1234' | node "$AUX/stdin-get.mjs" 'j.erreur')" "inconnu"

echo "=== W7 — masquage des jetons ==="
TOK1="ghp_$(printf 'a%.0s' $(seq 1 36))"; TOK2="sk-$(printf 'b%.0s' $(seq 1 24))"
mk_session "$TRD/$SID.jsonl" cwd "deploy avec $TOK1 puis $TOK2 fin"
R=$(Q reveal "$LAB" "$HOME_T" "$NOSCRIPTS" "$SID" | node "$AUX/stdin-get.mjs" 'j.doing')
assert_has "W7.1 — [masqué] à la place des jetons" "$R" "[masqué]"
assert_eq "W7.2 — aucun jeton ghp_ ni sk- dans la révélation" "$(printf '%s' "$R" | grep -cE 'ghp_|sk-')" "0"
mk_session "$TRD/$SID.jsonl" cwd "$MARK"

echo "=== W8 — forme inconnue d'un transcript ou d'un meta.json ==="
H8="$WORK/home8"; mkdir -p "$H8/.claude/projects/-lab"
mk_session "$H8/.claude/projects/-lab/$SID.jsonl" workdir "x"
Q who "$LAB" "$H8" "$NOSCRIPTS" > "$WORK/who8.json"
assert_eq "W8.1 — la session à clé renommée n'est pas listée" "$(G "$WORK/who8.json" 'j.workers.filter(w=>w.kind==="session").length')" "0"
assert_eq "W8.2 — état forme-inconnue" "$(G "$WORK/who8.json" 'j.sources.sessions.etat')" "forme-inconnue"
assert_eq "W8.3 — compteur >= 1" "$(G "$WORK/who8.json" 'j.sources.sessions.formeInconnue>=1')" "true"
H9="$WORK/home9"; mkdir -p "$H9/.claude/projects/-lab/$SID/subagents"
mk_session "$H9/.claude/projects/-lab/$SID.jsonl" cwd "x"
SD="$H9/.claude/projects/-lab/$SID/subagents"
echo '{"agentType":"vf-coder","description":"tâche","spawnDepth":2}' > "$SD/agent-ok.meta.json"; mk_session "$SD/agent-ok.jsonl" cwd "x"
echo '{"description":"sans type"}' > "$SD/agent-bad.meta.json"; mk_session "$SD/agent-bad.jsonl" cwd "x"
Q who "$LAB" "$H9" "$NOSCRIPTS" > "$WORK/who9.json"
assert_eq "W8.4 — témoin : le sous-agent conforme est listé, pas l'autre" "$(G "$WORK/who9.json" 'j.workers.filter(w=>w.kind==="subagent").map(w=>w.id).join(",")')" "ok"
assert_eq "W8.5 — le meta.json sans agentType compte en forme inconnue" "$(G "$WORK/who9.json" 'j.sources.sessions.formeInconnue')" "1"
assert_eq "W8.6 — témoin : la fixture conforme rend lue" "$(G "$WORK/who9.json" 'j.sources.sessions.etat')" "lue"

echo "=== W9 — jamais de script pris dans l'arbre observé ==="
H0="$WORK/home0"; mkdir -p "$H0"
TRAP="$WORK/trap.sh"
cat > "$TRAP" <<SH
#!/usr/bin/env bash
touch "$WORK/EXECUTE"
case "\$1" in status) echo '{"locks":[{"present":true,"owner":"PIEGE","step":"x","ws":"","scope":"repo","age_seconds":1,"stale":false}]}' ;; orphans) echo '{"orphans":[]}' ;; esac
SH
mkdir -p "$LAB/plugin/conductor/scripts"; cp "$TRAP" "$LAB/plugin/conductor/scripts/driver-lock.sh"
Q who "$LAB" "$H0" "$NOSCRIPTS" > "$WORK/who-w9.json"
assert_eq "W9.1 — source locks absente" "$(G "$WORK/who-w9.json" 'j.sources.locks.etat')" "absente"
assert_eq "W9.2 — aucun travailleur PIEGE" "$(G "$WORK/who-w9.json" 'j.workers.filter(w=>w.id==="PIEGE").length')" "0"
assert_eq "W9.3 — le script piégé n'a jamais été exécuté" "$([ -e "$WORK/EXECUTE" ] && echo oui || echo non)" "non"
OKD="$WORK/okdir"; mkdir -p "$OKD"; cp "$TRAP" "$OKD/driver-lock.sh"
Q who "$LAB" "$H0" "$OKD" > "$WORK/who-w9b.json"
assert_eq "W9.4 — témoin positif : le même script hors de l'arbre est exécuté" "$(G "$WORK/who-w9b.json" 'j.workers.filter(w=>w.id==="PIEGE").length')" "1"

echo "=== W10 — la CLI --json ne porte jamais la dernière commande ==="
HOME="$HOME_T" node "$SCRIPTS/vf-cockpit-who.mjs" "$LAB" --json > "$WORK/cli.json"
assert_eq "W10.1 — schéma dans la sortie de la CLI" "$(grep -c '"schema": "vibeflow/cockpit-who@1"' "$WORK/cli.json")" "1"
assert_eq "W10.2 — aucune clé doing" "$(grep -c '"doing"' "$WORK/cli.json")" "0"
assert_eq "W10.3 — le marqueur est absent" "$(grep -c "$MARK" "$WORK/cli.json")" "0"

echo "=== W11 — E-5 : la dernière action d'une session active, dernière ligne = résultat d'outil ==="
cat > "$AUX/mk-e5.mjs" <<'JS'
// mk-e5.mjs <fichier> <cwd> <forme> : transcript Claude Code. forme = outil (assistant tool_use puis user tool_result court)
//   · geant (… puis un tool_result de 300 Kio sur UNE ligne) · sansaction (que des lignes user)
import fs from 'node:fs';
const [, , f, cwd, forme] = process.argv;
const base = { cwd, sessionId: 'aaaa1111-2222-3333-4444-555566667777', gitBranch: 'main', version: '2.1.316' };
const L = (o, t) => JSON.stringify({ ...base, timestamp: t, ...o });
const lignes = [L({ type: 'user', message: { content: 'salut' } }, '2026-11-01T10:00:00Z')];
if (forme !== 'sansaction') {
  lignes.push(L({ type: 'assistant', message: { content: [{ type: 'tool_use', name: 'Bash', input: { description: 'COMMANDE-E5', command: 'echo bonjour' } }] } }, '2026-11-01T10:00:05Z'));
  lignes.push(L({ type: 'user', message: { content: [{ type: 'tool_result', tool_use_id: 'x', content: forme === 'geant' ? 'x'.repeat(300 * 1024) : 'ok' }] } }, '2026-11-01T10:00:06Z'));
} else lignes.push(L({ type: 'user', message: { content: [{ type: 'tool_result', tool_use_id: 'x', content: 'ok' }] } }, '2026-11-01T10:00:06Z'));
fs.writeFileSync(f, lignes.join('\n') + '\n');
JS
H11="$WORK/home11"; mkdir -p "$H11/.claude/projects/-lab"
for forme in outil geant; do
  node "$AUX/mk-e5.mjs" "$H11/.claude/projects/-lab/$SID.jsonl" "$LAB" "$forme"
  assert_has "W11 — forme « $forme » : la dernière action est rendue (pas « indisponible »)" "$(Q reveal "$LAB" "$H11" "$NOSCRIPTS" "$SID" | node "$AUX/stdin-get.mjs" 'j.doing')" "COMMANDE-E5"
done
node "$AUX/mk-e5.mjs" "$H11/.claude/projects/-lab/$SID.jsonl" "$LAB" sansaction
R11="$(Q reveal "$LAB" "$H11" "$NOSCRIPTS" "$SID")"
assert_eq "W11.3 — sans aucune action de l'assistant : doing nul, cause nommée" "$(printf '%s' "$R11" | node "$AUX/stdin-get.mjs" '[j.doing,j.erreur]')" '[null,"sans-action"]'

echo "=== W12 — E-7 : un nœud running d'un DAG sous .planning/missions apparaît « au travail » ==="
LABM="$WORK/labm"; mkdir -p "$LABM/.planning/missions"; git -C "$LABM" init -q
printf '{"nodes":[{"id":"b","step":"seconde étape","stage":"","deps":[],"scope":[],"status":"running"}]}\n' > "$LABM/.planning/missions/demo.dag.json"
Q who "$LABM" "$H0" "$NOSCRIPTS" > "$WORK/whom.json"
assert_eq "W12.1 — le nœud running du DAG de mission est un travailleur dag-node" "$(G "$WORK/whom.json" 'j.workers.filter(w=>w.kind==="dag-node").map(w=>w.id).join(",")')" "b"

echo "=== W13 — M-1 : le masque reste linéaire sur un mot géant ; M-2 : un meta.json qui n'est pas un objet ne fait pas lever ==="
cat > "$AUX/mk-mot.mjs" <<'JS'
// mk-mot.mjs <fichier> <cwd> <taille> : transcript dont la dernière commande est UN mot de <taille> caractères de mot, suivi d'un secret
import fs from 'node:fs';
const [, , f, cwd, taille] = process.argv; const base = { cwd, sessionId: 'aaaa1111-2222-3333-4444-555566667777', gitBranch: 'main', version: '2.1.316' };
const L = (o, t) => JSON.stringify({ ...base, timestamp: t, ...o });
fs.writeFileSync(f, [L({ type: 'user', message: { content: 'salut' } }, '2026-11-01T10:00:00Z'),
  L({ type: 'assistant', message: { content: [{ type: 'tool_use', name: 'Bash', input: { command: 'a'.repeat(Number(taille)) + ' GITHUB_TOKEN=ghp_abcdefghijklmnopqrstuvwx' } }] } }, '2026-11-01T10:00:05Z')].join('\n') + '\n');
JS
cat > "$AUX/temps.mjs" <<'JS'
// temps.mjs <scripts> <lab> <home> <scriptsDir> <id> : durée de revealDoing (ms) et résultat
import { pathToFileURL } from 'node:url'; import path from 'node:path';
const [, , scripts, root, home, scriptsDir, id] = process.argv; const m = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-who.mjs')).href);
const t = Date.now(); const r = m.revealDoing(root, id, { home, scriptsDir }); console.log(JSON.stringify({ ms: Date.now() - t, doing: r.doing, erreur: r.erreur }));
JS
H13="$WORK/home13"; mkdir -p "$H13/.claude/projects/-lab"
node "$AUX/mk-mot.mjs" "$H13/.claude/projects/-lab/$SID.jsonl" "$LAB" 100000
T13="$(node "$AUX/temps.mjs" "$SCRIPTS" "$LAB" "$H13" "$NOSCRIPTS" "$SID")"
assert_eq "W13.1 — témoin : la session est trouvée et sa dernière action rendue" "$(printf '%s' "$T13" | node "$AUX/stdin-get.mjs" 'typeof j.doing')" "string"
assert_eq "W13.2 — un mot de 100 000 caractères est masqué en moins de 1 500 ms (17 s avant la borne)" "$(printf '%s' "$T13" | node "$AUX/stdin-get.mjs" 'j.ms < 1500')" "true"
node "$AUX/mk-mot.mjs" "$H13/.claude/projects/-lab/$SID.jsonl" "$LAB" 20
assert_has "W13.3 — témoin : le secret placé après un mot court est toujours masqué" "$(node "$AUX/temps.mjs" "$SCRIPTS" "$LAB" "$H13" "$NOSCRIPTS" "$SID")" "[masqué]"
H14="$WORK/home14"; mkdir -p "$H14/.claude/projects/-lab/$SID/subagents"; SD14="$H14/.claude/projects/-lab/$SID/subagents"
mk_session "$H14/.claude/projects/-lab/$SID.jsonl" cwd "x"
echo '{"agentType":"vf-coder","description":"tâche","spawnDepth":2}' > "$SD14/agent-ok.meta.json"; mk_session "$SD14/agent-ok.jsonl" cwd "x"
for brut in 5 '[]' '"x"' null; do echo "$brut" > "$SD14/agent-bad.meta.json"; mk_session "$SD14/agent-bad.jsonl" cwd "x"
  Q who "$LAB" "$H14" "$NOSCRIPTS" > "$WORK/who14.json" 2>"$WORK/who14.err"
  assert_eq "W13.4 — meta.json « $brut » : pas d'exception, le sous-agent conforme reste listé, l'autre compte en forme inconnue" "$(G "$WORK/who14.json" '[j.workers.filter(w=>w.kind==="subagent").map(w=>w.id).join(","), j.sources.sessions.formeInconnue].join("|")' 2>&1)" "ok|1"
done

echo "=== W14 — R-2 : la branche d'un arbre connu vient de « git worktree list », jamais du gitBranch du transcript (celui de l'arbre de lancement) ==="
LABT="$WORK/labt"; mkdir -p "$LABT"; git -C "$LABT" init -q; git -C "$LABT" -c user.email=t@t -c user.name=t commit -q --allow-empty -m i; git -C "$LABT" branch -m principale
git -C "$LABT" worktree add -q "$WORK/labt-wt" -b feat/travail; LABT="$(cd "$LABT" && pwd -P)"; WT="$(cd "$WORK/labt-wt" && pwd -P)"
cat > "$AUX/mk-rattache.mjs" <<'JS'
// mk-rattache.mjs <fichier> <cwd> <cdVers|-> : session dont le gitBranch (docs/autre) est celui de l'arbre de lancement ; cdVers = chemin cité par la dernière action
import fs from 'node:fs'; const [, , f, cwd, cd] = process.argv; const base = { cwd, sessionId: 'aaaa1111-2222-3333-4444-555566667777', gitBranch: 'docs/autre', version: '2.1.316' };
const L = (o, t) => JSON.stringify({ ...base, timestamp: t, ...o });
fs.writeFileSync(f, [L({ type: 'user', message: { content: 'salut' } }, '2026-11-01T10:00:00Z'),
  L({ type: 'assistant', message: { content: [{ type: 'tool_use', name: 'Bash', input: { command: cd === '-' ? 'ls' : 'cd ' + cd + ' && ls' } }] } }, '2026-11-01T10:00:05Z')].join('\n') + '\n');
JS
H15="$WORK/home15"; mkdir -p "$H15/.claude/projects/-lab"
node "$AUX/mk-rattache.mjs" "$H15/.claude/projects/-lab/$SID.jsonl" "$LABT" "$WT"
Q who "$LABT" "$H15" "$NOSCRIPTS" > "$WORK/who15.json"
assert_eq "W14.1 — cwd = arbre principal, arbre déduit de l'activité : branche de l'arbre déduit" "$(G "$WORK/who15.json" 'j.workers.filter(w=>w.kind==="session").map(w=>w.treeBy+"|"+w.branch).join(",")')" "activité|feat/travail"
node "$AUX/mk-rattache.mjs" "$H15/.claude/projects/-lab/$SID.jsonl" "$WT" "-"
Q who "$LABT" "$H15" "$NOSCRIPTS" > "$WORK/who15b.json"
assert_eq "W14.2 — cwd dans le worktree : la branche est celle du worktree, pas le gitBranch périmé du transcript" "$(G "$WORK/who15b.json" 'j.workers.filter(w=>w.kind==="session").map(w=>w.treeBy+"|"+w.branch).join(",")')" "cwd|feat/travail"
node "$AUX/mk-rattache.mjs" "$H15/.claude/projects/-lab/$SID.jsonl" "$LABT" "-"
Q who "$LABT" "$H15" "$NOSCRIPTS" > "$WORK/who15c.json"
assert_eq "W14.3 — cwd = arbre principal : sa branche vient aussi de git" "$(G "$WORK/who15c.json" 'j.workers.filter(w=>w.kind==="session").map(w=>w.treeBy+"|"+w.branch).join(",")')" "cwd|principale"

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
