#!/usr/bin/env bash
# test-cockpit-who.sh — socle du cockpit : « au travail » et graphe Projet au contrat versionné
# vibeflow/cockpit-*@1 (P67-D-12, P67-D-14). Fixtures reconstruites dans mktemp à chaque appel.
#   W1 session fraîche listée (témoin positif) · W2 verrou via un driver-lock.sh de HOME
#   W3 graphe Projet d'un lab plat minimal · W4 validateur du contrat (et son refus de `doing`)
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"

WORK="$(mktemp -d)"
trap 'vf_hyg_fin; rm -rf "$WORK"' EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
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
    "{\"type\":\"assistant\",\"$2\":\"$LAB\",\"sessionId\":\"$SID\",\"timestamp\":\"2026-11-01T10:00:05Z\",\"gitBranch\":\"main\",\"version\":\"2.1.316\",\"message\":{\"content\":[{\"type\":\"tool_use\",\"name\":\"Bash\",\"input\":{\"description\":\"$3\",\"command\":\"$3\"}}]}}" > "$1"
}
# mk_sub <dossier> <id> <meta.json> : sous-agent à la forme réelle (meta + transcript dont la première ligne porte isSidechain et agentId)
mk_sub() { printf '%s\n' "$3" > "$1/agent-$2.meta.json"; mk_session "$1/agent-$2.jsonl" cwd "x"; sed -i.bak '1s/^{/{"isSidechain":true,"agentId":"'"$2"'",/' "$1/agent-$2.jsonl" && rm -f "$1/agent-$2.jsonl.bak"; }
META_REELLE='{"agentType":"vf-coder","description":"tâche","spawnDepth":1,"toolUseId":"toolu_x","requestShape":"background"}'
mk_session "$TRD/$SID.jsonl" cwd "MARQUEUR-DERNIERE-COMMANDE"

echo "=== W1 — session fraîche listée ==="
Q who "$LAB" "$HOME_T" "$NOSCRIPTS" > "$WORK/who.json"
assert_eq "W1.1 — schéma nommé VibeFlow" "$(G "$WORK/who.json" 'j.schema')" "vibeflow/cockpit-who@2"
assert_eq "W1.2 — la session fraîche est un travailleur kind=session" "$(G "$WORK/who.json" 'j.workers.filter(w=>w.kind==="session"&&w.id==="'$SID'").length')" "1"
assert_eq "W1.3 — source sessions lue" "$(G "$WORK/who.json" 'j.sources.sessions.etat')" "lue"

echo "=== W2 — verrou via le driver-lock.sh de HOME ==="
cat > "$HOME_T/.claude/scripts/driver-lock.sh" <<'SH'
#!/usr/bin/env bash
case "$1" in
  status) echo '{"present": true, "scope": "lab", "location": "git-common-dir", "legacy_lock": false, "locks": [{"present": true, "owner": "mgr-test", "step": "exec", "age_seconds": 10, "ttl": 1800, "stale": false, "generation": "g1", "session_ids": [], "lease_seconds": 5, "guard_effective": false, "progress_epoch": null, "progress_age_seconds": null, "children_running": 0, "scope": "depot", "ws": "", "location": "git-common-dir"}], "children_running": 0}' ;;
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
# vie d'une mission (VFSG-06, P68-D-29) : le graphe Projet lit le verrou de la phase d'une mission `running` ; ce lab n'en a pas, mais l'appel est épinglé quand même
# (HOME jetable ET dossier de scripts explicite, hors de toute disposition …/cockpit/scripts, portant un faux verrou tenu) pour ne jamais dépendre du poste.
# Le dossier n'est posé que sur cet appel en processus : les serveurs de la suite reçoivent leur propre VF_COCKPIT_SCRIPTS_DIR.
mkdir -p "$WORK/locks-pin"
printf '#!/usr/bin/env bash\ncase "$1" in status) echo "{\\"present\\": true, \\"ws\\": \\"\\", \\"stale\\": false, \\"ttl\\": 1800, \\"progress_age_seconds\\": 30}";; orphans) echo "{\\"orphans\\":[]}";; esac\n' > "$WORK/locks-pin/driver-lock.sh"; chmod +x "$WORK/locks-pin/driver-lock.sh"
HOME="$HOME_T" VF_COCKPIT_SCRIPTS_DIR="$WORK/locks-pin" Q project "$FLAT" > "$WORK/proj.json"
assert_eq "W3.1 — schéma Projet nommé VibeFlow" "$(G "$WORK/proj.json" 'j.schema')" "vibeflow/cockpit-project@1"
assert_eq "W3.2 — ph-1 est fait" "$(G "$WORK/proj.json" 'j.nodes.filter(n=>n.id==="ph-1").map(n=>n.st).join(",")')" "done"
assert_eq "W3.3 — le plan 01-01 est fait" "$(G "$WORK/proj.json" 'j.files.filter(f=>f.name.startsWith("01-01")).map(f=>f.st).join(",")')" "done"

echo "=== W4 — validateur du contrat versionné ==="
assert_eq "W4.1 — sortie « au travail » conforme" "$(node "$AUX/validate.mjs" "$IFACE" vibeflow/cockpit-who@2 "$WORK/who2.json")" "OK"
assert_eq "W4.2 — graphe Projet conforme" "$(node "$AUX/validate.mjs" "$IFACE" vibeflow/cockpit-project@1 "$WORK/proj.json")" "OK"
node -e 'const fs=require("fs");const j=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));j.workers[0].doing="x";fs.writeFileSync(process.argv[2],JSON.stringify(j))' "$WORK/who2.json" "$WORK/who-doing.json"
R=$(node "$AUX/validate.mjs" "$IFACE" vibeflow/cockpit-who@2 "$WORK/who-doing.json"); RC=$?
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
mk_session "$TRD/$SID.jsonl" cwd "deploy $TOK1 puis $TOK2 fin"
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
mk_sub "$SD" ok "$META_REELLE"
mk_sub "$SD" bad '{"description":"sans type"}'
Q who "$LAB" "$H9" "$NOSCRIPTS" > "$WORK/who9.json"
assert_eq "W8.4 — témoin : le sous-agent conforme est listé, pas l'autre" "$(G "$WORK/who9.json" 'j.workers.filter(w=>w.kind==="subagent").map(w=>w.id).join(",")')" "ok"
assert_eq "W8.5 — le meta.json sans agentType compte en forme inconnue" "$(G "$WORK/who9.json" 'j.sources.sessions.formeInconnue')" "1"
assert_eq "W8.6 — un meta.json hors forme rend la source forme-inconnue (change de sens par conception, CKPT-27 : plus de « lue » tant qu'un sous-agent vivant est conforme)" "$(G "$WORK/who9.json" 'j.sources.sessions.etat')" "forme-inconnue"
H9B="$WORK/home9b"; mkdir -p "$H9B/.claude/projects/-lab/$SID/subagents"
mk_session "$H9B/.claude/projects/-lab/$SID.jsonl" cwd "x"
mk_sub "$H9B/.claude/projects/-lab/$SID/subagents" ok "$META_REELLE"
Q who "$LAB" "$H9B" "$NOSCRIPTS" > "$WORK/who9b.json"
assert_eq "W8.7 — témoin : un dossier de sous-agents tous conformes rend lue, sous-agent listé" "$(G "$WORK/who9b.json" 'j.sources.sessions.etat+"|"+j.workers.filter(w=>w.kind==="subagent").map(w=>w.id).join(",")')" "lue|ok"

echo "=== W9 — jamais de script pris dans l'arbre observé ==="
H0="$WORK/home0"; mkdir -p "$H0"
TRAP="$WORK/trap.sh"
cat > "$TRAP" <<SH
#!/usr/bin/env bash
touch "$WORK/EXECUTE"
case "\$1" in status) echo '{"present": true, "scope": "lab", "location": "git-common-dir", "legacy_lock": false, "locks": [{"present": true, "owner": "PIEGE", "step": "x", "age_seconds": 1, "ttl": 1800, "stale": false, "generation": "g1", "session_ids": [], "lease_seconds": 5, "guard_effective": false, "progress_epoch": null, "progress_age_seconds": null, "children_running": 0, "scope": "depot", "ws": "", "location": "git-common-dir"}], "children_running": 0}' ;; orphans) echo '{"orphans":[]}' ;; esac
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
assert_eq "W10.1 — schéma dans la sortie de la CLI" "$(grep -c '"schema": "vibeflow/cockpit-who@2"' "$WORK/cli.json")" "1"
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
  lignes.push(L({ type: 'assistant', message: { content: [{ type: 'tool_use', name: 'Bash', input: { description: 'echo bonjour', command: 'echo COMMANDE-E5' } }] } }, '2026-11-01T10:00:05Z'));
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

echo "=== W15 — D3 : « la dernière commande » est la dernière commande Bash, jamais le texte de l'assistant ==="
cat > "$AUX/mk-d3.mjs" <<'JS'
// mk-d3.mjs <fichier> <cwd> <forme> : transcript Claude Code.
//   · cmd-puis-texte : assistant tool_use Bash (commande), résultat d'outil, PUIS message texte de l'assistant en markdown (la forme constatée en recette)
//   · texte-seul : que du texte d'assistant, aucun appel Bash · autre-outil : un appel Read (pas Bash) puis du texte
import fs from 'node:fs';
const [, , f, cwd, forme] = process.argv;
const base = { cwd, sessionId: 'aaaa1111-2222-3333-4444-555566667777', gitBranch: 'main', version: '2.1.316' };
const L = (o, t) => JSON.stringify({ ...base, timestamp: t, ...o });
const texte = { type: 'assistant', message: { content: [{ type: 'text', text: "J'ai consigné l'étape 3. **Verdict :** TEXTE-ASSISTANT-D3" }] } };
const lignes = [L({ type: 'user', message: { content: 'salut' } }, '2026-11-01T10:00:00Z')];
if (forme === 'cmd-puis-texte') {
  lignes.push(L({ type: 'assistant', message: { content: [{ type: 'tool_use', name: 'Bash', input: { description: 'DESC-D3', command: 'echo COMMANDE-BASH-D3 reste de la commande' } }] } }, '2026-11-01T10:00:05Z'));
  lignes.push(L({ type: 'user', message: { content: [{ type: 'tool_result', tool_use_id: 'x', content: 'ok' }] } }, '2026-11-01T10:00:06Z'));
} else if (forme === 'deux-bash-un-message') { // F-2 : deux appels Bash dans UN message, le dernier du tableau est le plus récent
  lignes.push(L({ type: 'assistant', message: { content: [{ type: 'tool_use', name: 'Bash', input: { command: 'echo PREMIER-D3' } }, { type: 'tool_use', name: 'Bash', input: { command: 'echo SECOND-D3' } }] } }, '2026-11-01T10:00:05Z'));
} else if (forme === 'deux-messages-bash') { // F-2 : deux messages Bash successifs, séparés par un résultat d'outil ; le plus récent gagne
  lignes.push(L({ type: 'assistant', message: { content: [{ type: 'tool_use', name: 'Bash', input: { command: 'echo ANCIEN-D3' } }] } }, '2026-11-01T10:00:05Z'));
  lignes.push(L({ type: 'user', message: { content: [{ type: 'tool_result', tool_use_id: 'x', content: 'ok' }] } }, '2026-11-01T10:00:06Z'));
  lignes.push(L({ type: 'assistant', message: { content: [{ type: 'tool_use', name: 'Bash', input: { command: 'echo RECENT-D3' } }] } }, '2026-11-01T10:00:07Z'));
  lignes.push(L({ type: 'user', message: { content: [{ type: 'tool_result', tool_use_id: 'y', content: 'ok' }] } }, '2026-11-01T10:00:08Z'));
} else if (forme === 'jeton-a-cheval') { // F-2 : un jeton sk- que la coupe d'affichage (80 car.) partagerait ; masqué AVANT la coupe, sa partie restante (12 car. de jeton) ne ressemble plus à un jeton
  lignes.push(L({ type: 'assistant', message: { content: [{ type: 'tool_use', name: 'Bash', input: { command: 'echo ' + 'a'.repeat(59) + ':sk-' + 'b'.repeat(24) + ' fin' } }] } }, '2026-11-01T10:00:05Z'));
} else if (forme === 'mot-geant') { // décision du 2026-11-02 : une borne de longueur sur l'affichage, même pour un seul mot de 4 000 caractères
  lignes.push(L({ type: 'assistant', message: { content: [{ type: 'tool_use', name: 'Bash', input: { command: 'echo ' + 'm'.repeat(4000) } }] } }, '2026-11-01T10:00:05Z'));
} else if (forme === 'autre-outil') {
  lignes.push(L({ type: 'assistant', message: { content: [{ type: 'tool_use', name: 'Read', input: { file_path: '/x/LECTURE-D3' } }] } }, '2026-11-01T10:00:05Z'));
}
lignes.push(L(texte, '2026-11-01T10:00:07Z'));
fs.writeFileSync(f, lignes.join('\n') + '\n');
JS
H15D="$WORK/home15d"; mkdir -p "$H15D/.claude/projects/-lab"
node "$AUX/mk-d3.mjs" "$H15D/.claude/projects/-lab/$SID.jsonl" "$LAB" cmd-puis-texte
R15="$(Q reveal "$LAB" "$H15D" "$NOSCRIPTS" "$SID")"
assert_has "W15.1 — un appel Bash suivi d'un message texte : on rend la commande Bash" "$(printf '%s' "$R15" | node "$AUX/stdin-get.mjs" 'j.doing')" "COMMANDE-BASH-D3"
assert_eq "W15.1b — décision du 2026-11-02 (Samuel, AskUserQuestion session principale) : le programme et son premier argument seulement, rien au-delà" "$(printf '%s' "$R15" | node "$AUX/stdin-get.mjs" 'j.doing')" "echo COMMANDE-BASH-D3 …"
assert_not "W15.2 — le texte de l'assistant n'apparaît pas" "$(printf '%s' "$R15" | node "$AUX/stdin-get.mjs" 'j.doing')" "TEXTE-ASSISTANT-D3"
assert_not "W15.3 — la description de l'appel n'est pas présentée comme la commande" "$(printf '%s' "$R15" | node "$AUX/stdin-get.mjs" 'j.doing')" "DESC-D3"
for forme in texte-seul autre-outil; do
  node "$AUX/mk-d3.mjs" "$H15D/.claude/projects/-lab/$SID.jsonl" "$LAB" "$forme"
  R15="$(Q reveal "$LAB" "$H15D" "$NOSCRIPTS" "$SID")"
  assert_eq "W15.4 — forme « $forme » : aucune commande Bash, doing nul et cause nommée (jamais le texte en repli)" "$(printf '%s' "$R15" | node "$AUX/stdin-get.mjs" '[j.doing,j.erreur]')" '[null,"sans-action"]'
done

# F-2 (revue de D3) : trois mutants de D3 survivaient (ordre dans un message, ordre entre messages, coupe à 120 avant le masque)
for forme in deux-bash-un-message deux-messages-bash jeton-a-cheval mot-geant; do
  node "$AUX/mk-d3.mjs" "$H15D/.claude/projects/-lab/$SID.jsonl" "$LAB" "$forme"
  D15="$(Q reveal "$LAB" "$H15D" "$NOSCRIPTS" "$SID" | node "$AUX/stdin-get.mjs" 'j.doing')"
  case "$forme" in
    deux-bash-un-message) assert_has "W15.5 — deux appels Bash dans un message : le DERNIER du tableau" "$D15" "SECOND-D3"; assert_not "W15.5b — ... et pas le premier" "$D15" "PREMIER-D3" ;;
    deux-messages-bash) assert_has "W15.6 — deux messages Bash successifs : le plus RÉCENT" "$D15" "RECENT-D3"; assert_not "W15.6b — ... et pas l'ancien" "$D15" "ANCIEN-D3" ;;
    jeton-a-cheval) assert_not "W15.7 — un jeton que la coupe de 80 caractères partagerait : aucune partie ne fuit (masque AVANT la coupe)" "$D15" "sk-bbbb"; assert_has "W15.7b — témoin : le jeton est remplacé par [masqué]" "$D15" "[masqué]" ;;
    mot-geant) assert_eq "W15.8 — un premier argument de 4 000 caractères ne sort pas entier : affichage borné à 80 caractères" "$(printf '%s' "$D15" | wc -m | tr -d ' ')" "80" ;;
  esac
done

echo "=== W12 — E-7 : un nœud running d'un DAG sous .planning/missions apparaît « au travail » ==="
LABM="$WORK/labm"; mkdir -p "$LABM/.planning/missions"; git -C "$LABM" init -q
printf '{"nodes":[{"id":"b","step":"seconde étape","stage":"","deps":[],"scope":[],"status":"running"}]}\n' > "$LABM/.planning/missions/demo.dag.json"
Q who "$LABM" "$H0" "$NOSCRIPTS" > "$WORK/whom.json"
assert_eq "W12.1 — le nœud running du DAG de mission est un travailleur dag-node" "$(G "$WORK/whom.json" 'j.workers.filter(w=>w.kind==="dag-node").map(w=>w.id).join(",")')" "b"

echo "=== W13 — M-1 : le masque reste linéaire sur un mot géant ; M-2 : un meta.json qui n'est pas un objet ne fait pas lever ==="
cat > "$AUX/mk-mot.mjs" <<'JS'
// mk-mot.mjs <fichier> <cwd> <taille> : transcript dont la dernière commande est UN mot de <taille> caractères de mot, suivi d'un jeton nu (premier argument ; un « NOM=valeur » ne s'afficherait plus, règle « = »)
import fs from 'node:fs';
const [, , f, cwd, taille] = process.argv; const base = { cwd, sessionId: 'aaaa1111-2222-3333-4444-555566667777', gitBranch: 'main', version: '2.1.316' };
const L = (o, t) => JSON.stringify({ ...base, timestamp: t, ...o });
fs.writeFileSync(f, [L({ type: 'user', message: { content: 'salut' } }, '2026-11-01T10:00:00Z'),
  L({ type: 'assistant', message: { content: [{ type: 'tool_use', name: 'Bash', input: { command: 'a'.repeat(Number(taille)) + ' ghp_abcdefghijklmnopqrstuvwx' } }] } }, '2026-11-01T10:00:05Z')].join('\n') + '\n');
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
mk_sub "$SD14" ok "$META_REELLE"
for brut in 5 '[]' '"x"' null; do mk_sub "$SD14" bad "$brut"
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


echo "=== W16 — D2/D3 dans le navigateur : le tiroir « Au travail » a sa marge, sa hauteur au contenu, et rend la commande Bash ==="
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi; done
if [ -z "$CHROME" ]; then echo "  ⊘ W16 SAUTÉ : aucun navigateur (Chrome, Chromium) — D2 et la commande dans le tiroir NON vérifiés, non comptés comme réussis"; else
ENG="$SCRIPTS/../skills/cockpit-moteur"
LABD="$WORK/labd"; mkdir -p "$LABD/src" "$LABD/.planning/phases/01-socle" "$LABD/.planning/missions"
printf 'export const u = () => 1;\n' > "$LABD/src/util.js"
printf '# Roadmap\n\n## Jalon démo\n\n- [ ] **Phase 1: Socle** - premier jet\n' > "$LABD/.planning/ROADMAP.md"
printf '<objective>Faire le socle</objective>\n' > "$LABD/.planning/phases/01-socle/01-01-PLAN.md"
git -C "$LABD" init -q && git -C "$LABD" add -A && git -C "$LABD" -c user.email=t@t -c user.name=t commit -q -m init
LABD="$(cd "$LABD" && pwd -P)"
node "$SCRIPTS/vf-cockpit-build.mjs" "$LABD" --quiet > "$WORK/build-d.out" 2>&1 || cat "$WORK/build-d.out"
HD="$WORK/homed"; mkdir -p "$HD/.claude/projects/-lab"
node "$AUX/mk-d3.mjs" "$HD/.claude/projects/-lab/$SID.jsonl" "$LABD" cmd-puis-texte
PORTD="$(node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})")"
OUTD="$LABD/.vibeflow/cockpit"
( cd "$LABD" && HOME="$HD" VF_COCKPIT_ENGINE_DIR="$ENG" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS" exec node "$OUTD/serve.mjs" --no-open --port "$PORTD" > "$WORK/serve-d.out" 2>&1 ) </dev/null >/dev/null 2>&1 &
SRVD=$!; PIDS+=($SRVD)
for _ in $(seq 1 100); do grep -q '"port"' "$OUTD/.cache/server.json" 2>/dev/null && break; sleep 0.1; done
PORTD="$(node -e "console.log(JSON.parse(require('fs').readFileSync('$OUTD/.cache/server.json','utf8')).port)" 2>/dev/null || echo 0)"
cat > "$AUX/tiroir.js" <<'JS'
(async () => {
  const SC = window.VibeFlow || window.Floorplan, pa = document.getElementById('panel');
  const att = async (f) => { for (let i = 0; i < 100; i++) { const v = f(); if (v) return v; await new Promise((r) => setTimeout(r, 50)); } return null; };
  const pause = (ms) => new Promise((r) => setTimeout(r, ms));
  // panneau de référence : un panneau ouvert par SC.showPanel avec le gabarit commun (.sec), mesuré dans le même Chrome
  SC.showPanel('<div class="sec"><h3>Référence</h3><p>x</p></div>'); await pause(700);
  const refMarge = Math.round(pa.querySelector('.sec h3').getBoundingClientRect().left - pa.getBoundingClientRect().left);
  document.getElementById('vf-lock').click();
  const w = await att(() => pa.querySelector('.vf-whop'));
  const bouton = await att(() => pa.querySelector('[data-vf-doing]'));
  if (!w || !bouton) return { erreur: 'tiroir ou bouton absent : ' + pa.innerText.slice(0, 120) };
  bouton.click();
  const zone = bouton.nextElementSibling;
  await att(() => !zone.hidden && zone.textContent);
  await pause(700);
  const tr = pa.getBoundingClientRect(), h3 = w.querySelector('h3'), hr = h3.getBoundingClientRect();
  const m = { vh: innerHeight, vw: innerWidth, refMarge, marge: Math.round(hr.left - tr.left), h3Dedans: hr.left >= tr.left && hr.right <= tr.right && hr.top >= tr.top,
    h3Rogne: h3.scrollWidth > h3.clientWidth + 1, debordeX: pa.scrollWidth > pa.clientWidth + 1, hauteur: Math.round(tr.height), doing: zone.textContent, overflowY: getComputedStyle(pa).overflowY, titre: h3.textContent };
  for (let i = 0; i < 40; i++) { const d = document.createElement('div'); d.className = 'vf-who'; d.textContent = 'ligne ' + i; w.appendChild(d); }
  await pause(100);
  const tl = pa.getBoundingClientRect();
  Object.assign(m, { longHauteur: Math.round(tl.height), longBas: Math.round(tl.bottom), longScroll: pa.scrollHeight > pa.clientHeight + 1 });
  return m;
})()
JS
XD="$(CDP_VIEWPORT=1280x800 CDP_PRET="document.readyState === 'complete' && !!document.getElementById('vf-lock') && /travail/.test(document.getElementById('vf-lock').textContent)" node "$SCRIPTS/tests/chrome-cdp.mjs" "$CHROME" 300 "$(cat "$AUX/tiroir.js")" "http://127.0.0.1:$PORTD/index.html")"
vf_hyg_stop "$SRVD"
[ -z "${KEEPXD:-}" ] || echo "$XD" > "$KEEPXD"
V='j.resultats[0].valeur'
assert_eq "W16.0 — témoin : la mesure a eu lieu (aucune erreur) et le tiroir est ouvert" "$(printf '%s' "$XD" | node "$AUX/stdin-get.mjs" '(j.erreur||"")+"|"+('$V'.erreur||"")+"|"+'$V'.titre')" "||Au travail (1)"
assert_eq "W16.1 — D3 dans le tiroir : « Voir la dernière commande » montre la commande Bash" "$(printf '%s' "$XD" | node "$AUX/stdin-get.mjs" "$V.doing")" "echo COMMANDE-BASH-D3 …"
assert_eq "W16.2 — témoin : le panneau de référence a une marge gauche (>= 16 px)" "$(printf '%s' "$XD" | node "$AUX/stdin-get.mjs" "$V.refMarge >= 16")" "true"
assert_eq "W16.3 — D2 : la marge gauche du titre du tiroir est au moins celle du panneau de référence" "$(printf '%s' "$XD" | node "$AUX/stdin-get.mjs" "$V.marge >= $V.refMarge")" "true"
assert_eq "W16.4 — D2 : le titre est contenu dans le tiroir et non rogné, aucun débordement horizontal" "$(printf '%s' "$XD" | node "$AUX/stdin-get.mjs" "[$V.h3Dedans, $V.h3Rogne, $V.debordeX]")" "[true,false,false]"
assert_eq "W16.5 — D2 : contenu court, la hauteur du tiroir suit le contenu (< 60 % de la fenêtre)" "$(printf '%s' "$XD" | node "$AUX/stdin-get.mjs" "$V.hauteur < $V.vh * 0.6")" "true"
assert_eq "W16.6 — D2 : contenu long, le tiroir reste dans la fenêtre et défile" "$(printf '%s' "$XD" | node "$AUX/stdin-get.mjs" "[$V.longBas <= $V.vh, $V.longHauteur < $V.vh, $V.overflowY, $V.longScroll]")" '[true,true,"auto",true]'
fi
# ---------- W17 — verrous de PHASE : libellé, registre par phase, grammaire des arguments (merge 69 / PR #197) ----------
# Le verrou et le registre viennent du VRAI driver-lock.sh (acquire --ws --phase, register), dans un dépôt git jetable ; un faux driver-lock.sh
# journalise ses arguments et rend un `status` hostile. Grammaire = celle de driver-lock.sh : ws = vf_ws_name_valid (alphanumérique en tête, puis
# alphanumérique . _ -, jamais `..`), phase = vf_dl_phase_valid (chiffres séparés par des points, `1.2.3` accepté, jamais `..` ni point en tête ou en queue).
echo "=== W17 — verrous de phase dans « qui est au travail » ==="
cat > "$AUX/mutsub.mjs" <<'JS'
import fs from 'node:fs';
const f = process.argv[2]; const t = fs.readFileSync(f, 'utf8');
if (!t.includes(process.env.FROM)) { console.log('ancre absente'); process.exit(1); }
fs.writeFileSync(f, t.replace(process.env.FROM, () => process.env.TO)); console.log('muté');
JS
mut17() { local d="$WORK/mut17-$1"; rm -rf "$d"; mkdir -p "$d"; cp "$SCRIPTS"/*.mjs "$SCRIPTS/vf-cockpit-interface.json" "$d/"; FROM="$3" TO="$4" node "$AUX/mutsub.mjs" "$d/$2"; }
DLREEL="$(cd "$SCRIPTS/../../conductor/scripts" && pwd)"
L17="$WORK/lab-w17"; mkdir -p "$L17/.planning/workstreams/x" "$L17/.planning/workstreams/v1.2"; git -C "$L17" init -q
( cd "$L17" && bash "$DLREEL/driver-lock.sh" acquire --ws=x --phase=5 --owner=mgr-p5 --step=exec >/dev/null 2>&1 \
  && bash "$DLREEL/driver-lock.sh" register --ws=x --phase=5 --agent=ag-p5 --role=vf-coder --node=n1 --depth=2 >/dev/null 2>&1 \
  && bash "$DLREEL/driver-lock.sh" acquire --ws=v1.2 --phase=1.2.3 --owner=mgr-v --step=exec >/dev/null 2>&1 \
  && bash "$DLREEL/driver-lock.sh" register --ws=v1.2 --phase=1.2.3 --agent=ag-v --role=vf-coder --node=n2 --depth=2 >/dev/null 2>&1 )
assert_eq "W17.0 — contrôle positif : les deux verrous de phase et leurs agents existent (vrai driver-lock.sh)" "$(ls "$L17/.git/vf-driver/ws/x/phases/5" "$L17/.git/vf-driver/ws/v1.2/phases/1.2.3" | grep -c 'children.jsonl')" "2"
Q who "$L17" "$HOME_T" "$DLREEL" > "$WORK/who17.json"
assert_eq "W17.1 — le verrou de phase est libellé « compartiment x phase 5 »" "$(G "$WORK/who17.json" 'j.workers.filter(w=>w.kind==="lock"&&w.id==="mgr-p5").map(w=>w.tree).join("|")')" "compartiment x phase 5"
assert_eq "W17.2 — l'agent enregistré sous la phase 5 est vu, rattaché à sa phase et tenu (non orphelin)" "$(G "$WORK/who17.json" 'j.workers.filter(w=>w.id==="ag-p5").map(w=>w.tree+"/"+w.orphan).join("|")')" "compartiment x phase 5/false"
assert_eq "W17.3 — ws « v1.2 » (point) et phase « 1.2.3 » (deux niveaux) : verrou libellé juste" "$(G "$WORK/who17.json" 'j.workers.filter(w=>w.kind==="lock"&&w.id==="mgr-v").map(w=>w.tree).join("|")')" "compartiment v1.2 phase 1.2.3"
assert_eq "W17.4 — l'agent enregistré sous ws=v1.2 phase=1.2.3 est vu" "$(G "$WORK/who17.json" 'j.workers.filter(w=>w.id==="ag-v").map(w=>w.tree).join("|")')" "compartiment v1.2 phase 1.2.3"
# faux driver-lock.sh : journalise ses arguments, `status` hostile (ws et phases qui n'ont rien à faire dans une ligne de commande)
HOS="$WORK/hostile17"; mkdir -p "$HOS"; LOG17="$WORK/hostile17.log"
cat > "$HOS/driver-lock.sh" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$HOSTILE_LOG"
case "$1" in
  status) cat <<'JSON'
{"locks":[
{"present":true,"owner":"h1","step":"s","ws":"../x","phase":"5","scope":"phase","age_seconds":1,"stale":false},
{"present":true,"owner":"h2","step":"s","ws":"$(id)","phase":"5","scope":"phase","age_seconds":1,"stale":false},
{"present":true,"owner":"h3","step":"s","ws":"x","phase":"1;rm","scope":"phase","age_seconds":1,"stale":false},
{"present":true,"owner":"h4","step":"s","ws":"x","phase":"5 --all","scope":"phase","age_seconds":1,"stale":false},
{"present":true,"owner":"h5","step":"s","ws":"x","phase":"1..2","scope":"phase","age_seconds":1,"stale":false},
{"present":true,"owner":"h6","step":"s","ws":"a/b","phase":".5","scope":"phase","age_seconds":1,"stale":false},
{"present":true,"owner":"h7","step":"s","ws":"x","phase":7,"scope":"phase","age_seconds":1,"stale":false},
{"present":true,"owner":"h8","step":"s","ws":"v1.2","phase":"1.2.3","scope":"phase","age_seconds":1,"stale":false}]}
JSON
  ;;
  orphans) echo '{"orphans":[]}' ;;
esac
SH
L18="$WORK/lab-w17h"; mkdir -p "$L18"; git -C "$L18" init -q
mkdir -p "$L18/.git/vf-driver/ws/ok1" "$L18/.git/vf-driver/ws/..x" "$L18/.git/vf-driver/ws/a b" "$L18/.git/vf-driver/ws/x;y" "$L18/.git/vf-driver/ws/.caché" "$L18/.git/vf-driver/ws/v1.2"
mkdir -p "$L18/.git/vf-driver/ws/--all"
run18() { : > "$LOG17"; HOSTILE_LOG="$LOG17" Q who "$1" "$HOME_T" "$2" > "$WORK/who18.json"; }
run18 "$L18" "$HOS"
BADARGS="$(grep '^orphans' "$LOG17" | grep -cvE '^orphans( --ws=[A-Za-z0-9][A-Za-z0-9._-]*( --phase=[0-9]+(\.[0-9]+)*)?)?$')"
assert_eq "W17.5 — aucun ws ni numéro de phase hostile n'arrive en argument de driver-lock.sh" "$BADARGS" "0"
assert_eq "W17.6 — témoin : les cibles valides ont bien été interrogées (x phase 5 absent du status, v1.2 phase 1.2.3 et ok1 présents)" "$(grep -cE '^orphans --ws=(v1\.2 --phase=1\.2\.3|ok1|v1\.2)$' "$LOG17")" "3"
assert_eq "W17.7 — les phases hostiles ne sont pas libellées (« 5 --all », « 1;rm », « 1..2 »)" "$(G "$WORK/who18.json" 'j.workers.filter(w=>w.kind==="lock"&&["h3","h4","h5"].includes(w.id)).map(w=>w.tree).join("|")')" "compartiment x|compartiment x|compartiment x"
assert_eq "W17.8 — une phase numérique (7) du status est ramenée à une chaîne valide et interrogée" "$(grep -c '^orphans --ws=x --phase=7$' "$LOG17")" "1"
M1="$(mut17 sansfiltre vf-cockpit-who.mjs "ok = (ws, ph) => (ws === '' || WS_RE.test(ws) && !ws.includes('..')) && (ph === '' || PH_RE.test(ph));" "ok = () => true;")"
run18 "$L18" "$HOS" ; : > "$LOG17"; HOSTILE_LOG="$LOG17" node "$AUX/q.mjs" "$WORK/mut17-sansfiltre" who "$L18" "$HOME_T" "$HOS" > /dev/null
assert_eq "W17.9 — mutant (filtre ok() supprimé, ancre présente) : des arguments hostiles arrivent au script, détecté" "$M1|$(grep '^orphans' "$LOG17" | grep -cvE '^orphans( --ws=[A-Za-z0-9][A-Za-z0-9._-]*( --phase=[0-9]+(\.[0-9]+)*)?)?$' | awk '{print ($1>0)?"rougit":"vert"}')" "muté|rougit"
M2="$(mut17 sanslibelle vf-cockpit-who.mjs '${l.phase && PH_RE.test(String(l.phase)) ? ` phase ${l.phase}` : '"''"'}' "")"
assert_eq "W17.10 — mutant (libellé « phase N » supprimé) : W17.1 rougit" "$M2|$(node "$AUX/q.mjs" "$WORK/mut17-sanslibelle" who "$L17" "$HOME_T" "$DLREEL" | node "$AUX/stdin-get.mjs" 'j.workers.filter(w=>w.kind==="lock"&&w.id==="mgr-p5").map(w=>w.tree).join("|")')" "muté|compartiment x"
M3="$(mut17 sanscible vf-cockpit-who.mjs ".filter((x) => x.present && x.phase && typeof x.ws === 'string')" ".filter(() => false)")"
assert_eq "W17.11 — mutant (cibles de phase supprimées) : l'agent enregistré sous la phase 5 disparaît" "$M3|$(node "$AUX/q.mjs" "$WORK/mut17-sanscible" who "$L17" "$HOME_T" "$DLREEL" | node "$AUX/stdin-get.mjs" 'j.workers.filter(w=>w.id==="ag-p5").length')" "muté|0"
M4="$(mut17 grammaireetroite vf-cockpit-who.mjs "WS_RE = /^[A-Za-z0-9][A-Za-z0-9._-]*\$/" "WS_RE = /^[A-Za-z0-9][A-Za-z0-9_-]*\$/")"
assert_eq "W17.12 — mutant (ws sans point, ancien ID_RE) : l'agent de ws=v1.2 disparaît" "$M4|$(node "$AUX/q.mjs" "$WORK/mut17-grammaireetroite" who "$L17" "$HOME_T" "$DLREEL" | node "$AUX/stdin-get.mjs" 'j.workers.filter(w=>w.id==="ag-v").length')" "muté|0"
M5="$(mut17 phaseunniveau vf-cockpit-who.mjs "PH_RE = /^[0-9]+(\\.[0-9]+)*\$/" "PH_RE = /^[0-9]{1,4}(\\.[0-9]{1,3})?\$/")"
assert_eq "W17.13 — mutant (phase à un seul niveau décimal) : le verrou 1.2.3 perd sa phase" "$M5|$(node "$AUX/q.mjs" "$WORK/mut17-phaseunniveau" who "$L17" "$HOME_T" "$DLREEL" | node "$AUX/stdin-get.mjs" 'j.workers.filter(w=>w.id==="mgr-v").map(w=>w.tree).join("|")')" "muté|compartiment v1.2"


# ---------- W18 — le driver-lock.sh du plugin passe avant la copie installée (recette 69, 2026-11-04 : « Driver libre » alors qu'un verrou de phase est tenu) ----------
# La copie de ~/.claude/scripts datait d'avant les verrous par phase : son `status --all` ne les liste pas. Le module cockpit voisin du conductor
# (…/plugin/cockpit/scripts -> …/plugin/conductor/scripts) fournit le script à jour ; la copie de HOME ne sert plus qu'en repli.
echo "=== W18 — le script du conductor voisin prime sur la copie installée ==="
H18="$WORK/home18"; mkdir -p "$H18/.claude/scripts"
cat > "$H18/.claude/scripts/driver-lock.sh" <<'SH'
#!/usr/bin/env bash
case "$1" in status) echo '{"present": false, "locks": [], "children_running": 0}' ;; orphans) echo '{"orphans":[]}' ;; esac
SH
PLUG="$WORK/plug18"; mkdir -p "$PLUG/cockpit/scripts"; ln -s "$(cd "$SCRIPTS/../../conductor" && pwd)" "$PLUG/conductor"
Q who "$L17" "$H18" "$PLUG/cockpit/scripts" > "$WORK/who18.json"
assert_eq "W18.1 — verrous de phase tenus comptés (held >= 1) avec le conductor voisin" "$(G "$WORK/who18.json" 'j.workers.filter(w=>w.kind==="lock").length>=1')" "true"
assert_eq "W18.2 — le verrou de phase 5 est libellé « compartiment x phase 5 »" "$(G "$WORK/who18.json" 'j.workers.filter(w=>w.kind==="lock"&&w.id==="mgr-p5").map(w=>w.tree).join("|")')" "compartiment x phase 5"
NOPLUG="$WORK/noplug18/cockpit/scripts"; mkdir -p "$NOPLUG"
Q who "$L17" "$H18" "$NOPLUG" > "$WORK/who18b.json"
assert_eq "W18.3 — repli : sans conductor voisin, la copie de HOME répond (aucun verrou listé, source lue)" "$(G "$WORK/who18b.json" 'j.workers.filter(w=>w.kind==="lock").length+"/"+j.sources.locks.etat')" "0/lue"
# le voisin n'est cherché que depuis un dossier …/cockpit/scripts : un dossier de scripts quelconque ne désigne jamais un frère piégé
mkdir -p "$WORK/trap18/x/scripts" "$WORK/trap18/conductor/scripts"; cp "$TRAP" "$WORK/trap18/conductor/scripts/driver-lock.sh"; rm -f "$WORK/EXECUTE"
Q who "$L17" "$H18" "$WORK/trap18/x/scripts" > "$WORK/who18c.json"
assert_eq "W18.4 — un frère de n'importe quel dossier « scripts » n'est pas exécuté" "$([ -e "$WORK/EXECUTE" ] && echo oui || echo non)|$(G "$WORK/who18c.json" 'j.workers.filter(w=>w.id==="PIEGE").length')" "non|0"

# ---------- W19 — toute commande git de la chaîne de l'émetteur neutralise fsmonitor (F-03 ; T-68-04) ----------
# Un `.git/config` écrit par d'autres peut déclarer un core.fsmonitor exécutable. Lab jetable, DAG commité (donc suivi et propre : le chemin
# `ls-files` + `status --porcelain` + `log` est parcouru) portant un nœud running frais ; le script de fsmonitor laisse un fichier témoin s'il s'exécute.
echo "=== W19 — un core.fsmonitor du .git/config n'est jamais exécuté par la chaîne de l'émetteur ==="
L19="$WORK/lab19"; mkdir -p "$L19/.planning/missions"; git -C "$L19" init -q
printf -- '- [ ] **Phase 1: Un** - a\n' > "$L19/.planning/ROADMAP.md"
printf '{"nodes":[{"id":"n19","step":"s","stage":"exec","deps":[],"scope":[],"status":"running"}]}\n' > "$L19/.planning/missions/MISSION-1.dag.json"
git -C "$L19" add -A; git -C "$L19" -c user.email=t@t -c user.name=t commit -q -m c0
MARK19="$WORK/FSMONITOR-EXECUTE"
printf '#!/bin/sh\ntouch "%s"\nexit 0\n' "$MARK19" > "$WORK/fsmon19.sh"; chmod +x "$WORK/fsmon19.sh"
git -C "$L19" config core.fsmonitor "$WORK/fsmon19.sh"
rm -f "$MARK19"; git -C "$L19" status --porcelain >/dev/null 2>&1
assert_eq "W19.0 — témoin positif : le script de fsmonitor s'exécute quand git status tourne sans précaution" "$([ -e "$MARK19" ] && echo exécuté || echo muet)" "exécuté"
rm -f "$MARK19"
Q who "$L19" "$HOME_T" "$NOSCRIPTS" > "$WORK/who19.json"
assert_eq "W19.1 — collectWho : le nœud running frais est lu (chemin git parcouru)" "$(G "$WORK/who19.json" 'j.workers.filter(w=>w.kind==="dag-node").map(w=>w.id).join(",")')" "n19"
assert_eq "W19.2 — collectWho : le script de fsmonitor n'a jamais été exécuté" "$([ -e "$MARK19" ] && echo exécuté || echo intact)" "intact"
rm -f "$MARK19"
HOME="$HOME_T" node "$SCRIPTS/vf-cockpit-signal.mjs" "$L19" > "$WORK/sig19.json" 2>/dev/null
assert_eq "W19.3 — l'émetteur entier sur ce lab : sortie signal@1 produite, script de fsmonitor jamais exécuté" "$(G "$WORK/sig19.json" 'j.schema')|$([ -e "$MARK19" ] && echo exécuté || echo intact)" "vibeflow/cockpit-signal@1|intact"

# ---------- W20 — audit F-9, F-6, F-5 : DAG mal formé, `--` devant le chemin, git en lecture seule ----------
echo "=== W20 — nœud nul dans un DAG, ls-files sans option injectable, .git/index intact ==="
L20="$WORK/lab20"; mkdir -p "$L20/.planning/missions"; git -C "$L20" init -q
printf -- '- [ ] **Phase 1: Un** - a\n' > "$L20/.planning/ROADMAP.md"
printf '{"nodes":[null,3,"x",{"id":"n20","step":"s","stage":"exec","deps":[],"scope":[],"status":"running"}]}\n' > "$L20/.planning/missions/MISSION-1.dag.json"
printf '{"nodes":[{"id":"z","step":"s","stage":"exec","deps":[],"scope":[],"status":"running"}]}\n' > "$L20/.planning/missions/-opt.dag.json"
git -C "$L20" add -A; git -C "$L20" -c user.email=t@t -c user.name=t commit -q -m c0
HOME="$HOME_T" node "$SCRIPTS/vf-cockpit-signal.mjs" "$L20" > "$WORK/sig20.json" 2>"$WORK/sig20.err"; RC20=$?
assert_eq "W20.1 — F-9 : un DAG à nœuds nuls ne fait pas planter l'émetteur (exit 0, signal@1)" "$RC20|$(G "$WORK/sig20.json" 'j.schema' 2>/dev/null)" "0|vibeflow/cockpit-signal@1"
Q who "$L20" "$HOME_T" "$NOSCRIPTS" > "$WORK/who20.json" 2>/dev/null
assert_eq "W20.2 — F-9 : les nœuds valides du même DAG sont encore lus" "$(G "$WORK/who20.json" 'j.workers.filter(w=>w.kind==="dag-node").map(w=>w.id).sort().join(",")' 2>/dev/null)" "n20,z"
assert_eq "W20.3 — F-6 : chaque ls-files --error-unmatch de who.mjs met -- devant le chemin" "$(grep -c "'ls-files', '--error-unmatch', '--', f" "$SCRIPTS/vf-cockpit-who.mjs")" "1"
git -C "$L20" status >/dev/null 2>&1; touch -t 202001010000 "$L20/.git/index"; M0="$(stat -f %m "$L20/.git/index" 2>/dev/null || stat -c %Y "$L20/.git/index")"
printf '\n' >> "$L20/.planning/ROADMAP.md"   # sale : git status voudrait rafraîchir l'index
HOME="$HOME_T" node "$SCRIPTS/vf-cockpit-signal.mjs" "$L20" > /dev/null 2>&1
M1="$(stat -f %m "$L20/.git/index" 2>/dev/null || stat -c %Y "$L20/.git/index")"
assert_eq "W20.4 — F-5 : la date de modification de .git/index ne bouge pas après l'émetteur" "$M1" "$M0"

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
