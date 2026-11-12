#!/usr/bin/env bash
# test-cockpit-lecture-fil.sh — lot 0 de l'audit du cockpit, lignes AUDC-D5 à D8 : ce que la lecture rend du disque.
#   D5 les plans de mission nommés `dag-*.json` sont lus comme les `*.dag.json` (un lab d'essai aux deux nommages)
#   D6 « New session » (valeur par défaut de custom-title) n'est pas un nom choisi ; un vrai nom reste lu (PU-G-162 : jamais de titre généré)
#   D7 une session n'a pas de mandat ; aucun intertitre « Mandat » vide ; le mandat d'un agent reste lu
#   D8 le transcript réduit est UN fil ordonné et daté, sans sortie d'outil ni argument d'outil (P69-D-16, P69-D-19)
# Fixtures reconstruites dans mktemp, SYNTHÉTIQUES (aucun transcript réel n'est lu ni copié). Code testé chargé depuis l'emplacement de la suite.
# Exit 0 si tout passe, 1 sinon.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
UI="$SCRIPTS/../skills/cockpit-moteur/assets/ui"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
WORK="$(cd "$WORK" && pwd -P)"
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }

# --- D5 : deux nommages de plan de mission ---
echo "=== D5 — plans de mission : dag-*.json et *.dag.json ==="
LAB="$WORK/lab5"; mkdir -p "$LAB/.planning/missions" "$LAB/.planning/phases"
NOEUDS='{"nodes":[{"id":"n1","state":"done","depends":[]}]}'
echo "$NOEUDS" > "$LAB/.planning/missions/essai.dag.json"
echo "$NOEUDS" > "$LAB/.planning/missions/dag-essai2.json"
echo '{"pas":"un plan"}' > "$LAB/.planning/missions/dag-sans-noeuds.json"
echo '{ illisible' > "$LAB/.planning/missions/dag-casse.json"
echo "$NOEUDS" > "$LAB/.planning/missions/autre-nom.json"
cat > "$WORK/dags.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
const [, , scripts, lab] = process.argv;
const { lireDags } = await import(pathToFileURL(scripts + '/vf-cockpit-planning.mjs').href);
console.log(lireDags(lab).map((d) => d.name + '=' + d.file).sort().join(','));
JS
assert_eq "D5.1 — les deux nommages sont lus ; un fichier sans nœuds, illisible ou d'un autre nom ne l'est pas" "$(node "$WORK/dags.mjs" "$SCRIPTS" "$LAB")" "essai2=.planning/missions/dag-essai2.json,essai=.planning/missions/essai.dag.json"

# --- D6 : titre par défaut ---
echo "=== D6 — « New session » n'est pas un nom choisi ==="
ecrit() { printf '%s\n' "$2" > "$WORK/$1.jsonl"; }
ecrit defaut '{"type":"custom-title","customTitle":"New session","sessionId":"x"}'
ecrit choisi '{"type":"custom-title","customTitle":"Ma session de recette","sessionId":"x"}'
ecrit apres '{"type":"custom-title","customTitle":"Ma session de recette","sessionId":"x"}
{"type":"custom-title","customTitle":"New session","sessionId":"x"}'
ecrit genere '{"type":"ai-title","aiTitle":"Titre écrit par le modèle","sessionId":"x"}'
cat > "$WORK/titre.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
const [, , scripts, ...fichiers] = process.argv;
const { titreSession } = await import(pathToFileURL(scripts + '/vf-cockpit-lecture.mjs').href);
console.log(fichiers.map((f) => '[' + titreSession(f) + ']').join(''));
JS
assert_eq "D6.1 — titre par défaut : aucun titre ; nom choisi : lu ; défaut posé après un nom : aucun titre ; titre généré : jamais lu" "$(node "$WORK/titre.mjs" "$SCRIPTS" "$WORK/defaut.jsonl" "$WORK/choisi.jsonl" "$WORK/apres.jsonl" "$WORK/genere.jsonl")" "[][Ma session de recette][][]"

# --- D7 et D8 : le transcript d'une session et d'un agent, par la route (revealTranscript) ---
echo "=== D7/D8 — transcript : fil daté, mandat d'agent seulement ==="
LABT="$WORK/labt"; HOME_T="$WORK/home"; SID="11111111-2222-3333-4444-555555555555"; mkdir -p "$LABT/src"
git -C "$LABT" init -q && git -C "$LABT" -c user.email=t@t -c user.name=t commit -q --allow-empty -m i
cat > "$WORK/mk.mjs" <<'JS'
// mk.mjs <home> <lab> <sid> <nowMs> : une session (dont la première ligne est un prompt d'utilisateur en chaîne : la forme que l'ancien code prenait pour un mandat) et un sous-agent (mandat en première ligne), horodatés
import fs from 'node:fs';
import path from 'node:path';
const [, , home, lab, sid, nowMs] = process.argv; const now = Number(nowMs);
const dir = path.join(home, '.claude', 'projects', '-lab'), sub = path.join(dir, sid, 'subagents'); fs.mkdirSync(sub, { recursive: true });
const iso = (s) => new Date(now - s * 1000).toISOString();
const b = (o) => ({ cwd: lab, sessionId: sid, gitBranch: 'main', version: '2.1.317', ...o });
const A = (s, content) => b({ type: 'assistant', timestamp: iso(s), message: { role: 'assistant', content } });
const U = (s, content) => b({ type: 'user', timestamp: iso(s), message: { role: 'user', content } });
const side = (o) => ({ ...o, isSidechain: true, agentId: 'ag1' });
const put = (f, ls, ageS) => { fs.writeFileSync(f, ls.map((l) => JSON.stringify(l)).join('\n') + '\n'); const t = (now - ageS * 1000) / 1000; fs.utimesSync(f, t, t); };
put(path.join(dir, sid + '.jsonl'), [
  U(300, 'PROMPT-DE-SESSION-FORME-CHAINE'),
  A(250, [{ type: 'text', text: 'MSG-SESSION-1' }]),
  A(200, [{ type: 'tool_use', id: 't1', name: 'Read', input: { file_path: lab + '/src/a.js' } }]),
  U(190, [{ type: 'tool_result', tool_use_id: 't1', content: 'SORTIE-OUTIL-SECRETE' }]),
  A(100, [{ type: 'text', text: 'MSG-SESSION-2' }]),
], 100);
fs.writeFileSync(path.join(sub, 'agent-ag1.meta.json'), JSON.stringify({ agentType: 'vf-coder', toolUseId: 'toolu_ag1', description: 'tâche synthétique', spawnDepth: 1, requestShape: 'background', requestNonInteractive: true }));
put(path.join(sub, 'agent-ag1.jsonl'), [
  side(U(280, 'MANDAT-DE-AGENT')),
  side(A(270, [{ type: 'text', text: 'MSG-AGENT-1' }, { type: 'tool_use', id: 'u1', name: 'Bash', input: { command: 'echo ARG-SECRET' } }])),
  side(U(260, [{ type: 'tool_result', tool_use_id: 'u1', content: 'SORTIE-OUTIL-SECRETE' }])),
  side(A(150, [{ type: 'tool_use', id: 'u2', name: 'Read', input: { file_path: lab + '/src/b.js' } }])),
  side(A(120, [{ type: 'text', text: 'MSG-AGENT-2' }])),
], 120);
JS
NOW="$(node -e 'console.log(Date.now())')"
node "$WORK/mk.mjs" "$HOME_T" "$LABT" "$SID" "$NOW"
cat > "$WORK/rev.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
const [, , scripts, lab, home, id, now] = process.argv;
const { revealTranscript } = await import(pathToFileURL(scripts + '/vf-cockpit-who.mjs').href);
console.log(JSON.stringify(revealTranscript(lab, id, { home, now: Number(now), fresh: 3600 })));
JS
node "$WORK/rev.mjs" "$SCRIPTS" "$LABT" "$HOME_T" ag1 "$NOW" > "$WORK/t-agent.json"
node "$WORK/rev.mjs" "$SCRIPTS" "$LABT" "$HOME_T" "$SID" "$NOW" > "$WORK/t-session.json"
cat > "$WORK/jg.mjs" <<'JS'
import fs from 'node:fs';
let j; try { j = JSON.parse(fs.readFileSync(process.argv[2], 'utf8')); } catch { console.log('non-json'); process.exit(0); }
try { const v = new Function('j', 'return (' + process.argv[3] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v)); } catch (e) { console.log('erreur : ' + e.message); }
JS
G() { node "$WORK/jg.mjs" "$@"; }
ENT='(j.fil||[]).map((e)=>(e.genre==="message"?"m:"+e.texte:"o:"+e.outil+"/"+e.verbe+"/"+e.cible)).join(",")'
assert_eq "D8.0 — témoin : la route rend un agent connu (pas d'erreur)" "$(G "$WORK/t-agent.json" 'j.erreur||"ok"')" "ok"
assert_eq "D8.1 — agent : le champ fil est UN tableau ordonné, messages et outils entrelacés dans l'ordre du fichier" "$(G "$WORK/t-agent.json" "Array.isArray(j.fil)?$ENT:\"pas de tableau fil\"")" "m:MSG-AGENT-1,o:Bash/lance une commande/,o:Read/lit/src/b.js,m:MSG-AGENT-2"
assert_eq "D8.2 — une heure (ISO 8601) par ligne, croissante" "$(G "$WORK/t-agent.json" '(()=>{const f=j.fil;if(!Array.isArray(f)||!f.length)return "pas de fil";const ok=f.every((e)=>typeof e.t==="string"&&/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(\.\d+)?Z$/.test(e.t)&&!isNaN(Date.parse(e.t)));const cr=f.every((e,i)=>i===0||Date.parse(f[i-1].t)<=Date.parse(e.t));return ok&&cr?"ok":"heures : "+f.map((e)=>e.t).join(",")})()')" "ok"
assert_eq "D8.3 — plus de deux listes séparées (ni messages ni outils), schéma @2 (forme cassante : messages et outils retirés)" "$(G "$WORK/t-agent.json" 'Array.isArray(j.fil)?("messages" in j)+"|"+("outils" in j)+"|"+j.schema:"pas de fil"')" "false|false|vibeflow/cockpit-transcript@2"
assert_eq "D8.4 — aucune sortie d'outil ni argument d'outil, aucune clé input (apparié aux positifs)" "$(G "$WORK/t-agent.json" '(()=>{const s=JSON.stringify(j);if(!(s.includes("MSG-AGENT-1")&&s.includes("MANDAT-DE-AGENT")))return "positifs absents";const f=(o)=>!!o&&typeof o==="object"&&Object.entries(o).some(([k,v])=>k==="input"||f(v));return s.includes("SORTIE-OUTIL-SECRETE")||s.includes("ARG-SECRET")||f(j)?"fuite":"ok"})()')" "ok"
assert_eq "D7.1 — agent : le mandat est lu dans son dispatch" "$(G "$WORK/t-agent.json" 'j.mandat')" "MANDAT-DE-AGENT"
assert_eq "D7.2 — session : aucun mandat (témoin : le fil de la session est rendu)" "$(G "$WORK/t-session.json" '(()=>{if(!(j.fil||[]).some((e)=>e.texte==="MSG-SESSION-2"))return "fil absent";return JSON.stringify(j.mandat||"")})()')" '""'
assert_eq "D8.5 — session : même forme de fil daté, la première ligne user n'en est pas un message" "$(G "$WORK/t-session.json" "(()=>{const f=j.fil;if(!Array.isArray(f))return 'pas de fil';return $ENT+'|'+f.every((e)=>typeof e.t==='string'&&!isNaN(Date.parse(e.t)))})()")" "m:MSG-SESSION-1,o:Read/lit/src/a.js,m:MSG-SESSION-2|true"

# --- D7 : le rendu ne pose jamais un intertitre « Mandat » vide ---
cat > "$WORK/vm-rendu.mjs" <<'JS'
// vm-rendu.mjs <couche.js> <pilote.js> : la couche d'affichage hors navigateur ; sortie { titres: [h4...], textes: [...] }
import fs from 'node:fs';
import vm from 'node:vm';
const [, , couche, pilote] = process.argv; const j = { titres: [], textes: [] };
function elt(tag) {
  const o = { tag, children: [], attrs: {}, className: '', style: {}, dataset: {}, _t: '' };
  Object.defineProperty(o, 'textContent', { get: () => o._t, set: (v) => { o._t = String(v); j.textes.push(String(v)); if (tag === 'h4') j.titres.push(String(v)); } });
  for (const k of ['innerHTML', 'outerHTML']) Object.defineProperty(o, k, { get: () => '', set: () => {} });
  o.appendChild = (c) => { o.children.push(c); return c; }; o.append = (...cs) => { o.children.push(...cs); };
  o.setAttribute = (k, v) => { o.attrs[k] = String(v); }; o.getAttribute = (k) => o.attrs[k] ?? null; o.addEventListener = () => {};
  o.classList = { add() {}, remove() {}, toggle() {}, contains: () => false };
  return o;
}
const document = { createElement: (t) => elt(String(t).toLowerCase()), createDocumentFragment: () => elt('#fragment'), createTextNode: (s) => ({ nodeValue: String(s) }) };
const ctx = vm.createContext({ window: {}, document, h: (s) => String(s), console });
try { vm.runInContext(fs.readFileSync(couche, 'utf8'), ctx, { timeout: 5000 }); vm.runInContext(fs.readFileSync(pilote, 'utf8'), ctx, { timeout: 5000 }); console.log(JSON.stringify(j)); }
catch (e) { console.log(JSON.stringify({ erreur: 'exécution : ' + String(e.message).slice(0, 120) })); }
JS
rend() { printf '__r = !!window.__vfEquipeRendu.transcript(%s, document);\n' "$1" > "$WORK/pilote.js"; node "$WORK/vm-rendu.mjs" "$UI/71-vf-equipe-rendu.js" "$WORK/pilote.js" > "$WORK/vm.json"; }
FIL='[{"t":"2026-11-10T10:00:00.000Z","genre":"message","texte":"MSG-RENDU"},{"t":"2026-11-10T10:00:05.000Z","genre":"outil","outil":"Read","verbe":"lit","cible":"src/a.js"}]'
rend "{\"mandat\":\"\",\"fil\":$FIL,\"tronque\":false}"
assert_eq "D7.3 — mandat vide : aucun intertitre « Mandat » (témoin : le fil est rendu)" "$(G "$WORK/vm.json" 'j.erreur||(j.textes.some((t)=>t.includes("MSG-RENDU"))?String(j.titres.includes("Mandat")):"fil non rendu")')" "false"
rend "{\"mandat\":\"MANDAT-RENDU\",\"fil\":$FIL,\"tronque\":false}"
assert_eq "D7.4 — mandat présent : l'intertitre et le texte sont rendus" "$(G "$WORK/vm.json" 'j.erreur||(String(j.titres.includes("Mandat"))+"|"+String(j.textes.includes("MANDAT-RENDU")))')" "true|true"
assert_eq "D8.6 — le rendu dit l'heure de chaque ligne du fil, du message comme de l'outil" "$(G "$WORK/vm.json" 'j.erreur||(()=>{const l=j.textes.filter((t)=>t.includes("MSG-RENDU")||t.includes("(Read)"));return l.length===2&&l.every((t)=>/\d\d:\d\d:\d\d/.test(t))?"ok":JSON.stringify(l)})()')" "ok"
rend '{"mandat":"","fil":[],"tronque":false}'
assert_eq "D7.5 — fil vide et mandat vide : pas d'exception, aucun intertitre (ni « Mandat » ni « Fil des échanges »)" "$(G "$WORK/vm.json" 'j.erreur||JSON.stringify(j.titres)')" "[]"
rend '{"mandat":"","fil":[{"t":null,"genre":"message","texte":"MSG-SANS-HEURE"},{"t":"pas une date","genre":"message","texte":"MSG-HEURE-ILLISIBLE"}],"tronque":false}'
assert_eq "D8.8 — une ligne sans heure lisible n'en affiche aucune (jamais l'heure de l'époque), témoin : les deux lignes sont rendues" "$(G "$WORK/vm.json" 'j.erreur||JSON.stringify(j.textes.filter((t)=>t.includes("MSG-")))')" '["MSG-SANS-HEURE","MSG-HEURE-ILLISIBLE"]'

# --- contrat : le contenu de transcript transite sous fil, les gardes-fous le connaissent ---
cat > "$WORK/interdits.mjs" <<'JS'
import fs from 'node:fs';
const c = JSON.parse(fs.readFileSync(process.argv[2] + '/vf-cockpit-interface.json', 'utf8')).schemas;
console.log(Object.entries(c).filter(([, v]) => Array.isArray(v.interdits) && v.interdits.includes('messages')).map(([k, v]) => k.split('/')[1] + ':' + v.interdits.includes('fil')).sort().join(','));
JS
assert_eq "D8.9 — les cinq schémas (equipe, git, index, signal, who) qui interdisent messages et outils interdisent aussi fil (tripwire du flux ; cockpit-index@1 ajouté par 79-08, changement de contrat voulu)" "$(node "$WORK/interdits.mjs" "$SCRIPTS")" "cockpit-equipe@1:true,cockpit-git@1:true,cockpit-index@1:true,cockpit-signal@1:true,cockpit-who@2:true"
# témoin D8.9b : un contrat où cockpit-index@1 n'interdit plus `fil` (copie jetable) est vu par le détecteur, pour la bonne raison
mkdir -p "$WORK/mut-fil" && node -e 'const fs=require("fs");const j=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));const i=j.schemas["vibeflow/cockpit-index@1"].interdits;i.splice(i.indexOf("fil"),1);fs.writeFileSync(process.argv[2],JSON.stringify(j))' "$SCRIPTS/vf-cockpit-interface.json" "$WORK/mut-fil/vf-cockpit-interface.json"
assert_eq "D8.9b — mutant : sans fil dans les interdits de cockpit-index@1, le détecteur rend cockpit-index@1:false (et D8.9 rougit)" "$(node "$WORK/interdits.mjs" "$WORK/mut-fil")" "cockpit-equipe@1:true,cockpit-git@1:true,cockpit-index@1:false,cockpit-signal@1:true,cockpit-who@2:true"

echo; echo "Résultat : $PASS réussis, $FAIL échoués"
[ "$FAIL" -eq 0 ]
