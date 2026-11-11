# projet-commun.sh — socle COMMUN des trois suites du graphe Projet (test-cockpit-projet-graphe.sh, -visite.sh, -croissance.sh), SOURCÉ par elles ;
# nom hors du motif test-*.sh : ce n'est pas une suite. Découpe de l'ancien test-cockpit-projet.sh (arbitrage Samuel, AskUserQuestion session principale, 2026-11-07) :
# préambule (SCRIPTS, WORK jetable et son trap, HOME jetable, faux driver-lock.sh, PASS/FAIL, assert_eq, aux node, Q, G, wr, graph), DR, borne/mutsub/mut7, mk_r3, bilan.
# La suite garde son propre `set -uo pipefail` ; le harnais de croissance est UN fichier versionné (projet-croissance.mjs), partagé par P10.1 et les mutants P10.x.

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS="$(cd "$TESTS_DIR/.." && pwd)"
CROISSANCE="$TESTS_DIR/projet-croissance.mjs"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home" "$WORK/locks" "$WORK/locks-abs" "$WORK/locks-vide"
# vie d'une mission (VFSG-06, P68-D-29) : HOME jetable ET dossier de scripts explicite hors de toute disposition …/cockpit/scripts,
# portant un faux driver-lock.sh TENU ; sans dossier explicite le conductor voisin du dépôt serait trouvé. Le dossier n'est posé QUE sur les appels
# en processus de Q : le vrai lanceur (vf-cockpit.mjs, section O4) en fait le dossier de scripts du MODULE, il ne doit pas le voir.
export HOME="$WORK/home"
printf '#!/usr/bin/env bash\ncase "$1" in status) echo "{\\"present\\": true, \\"ws\\": \\"\\", \\"stale\\": false, \\"ttl\\": 1800, \\"progress_age_seconds\\": 30}";; orphans) echo "{\\"orphans\\":[]}";; esac\n' > "$WORK/locks/driver-lock.sh"
printf '#!/usr/bin/env bash\ncase "$1" in status) echo "{\\"present\\": false}";; orphans) echo "{\\"orphans\\":[]}";; esac\n' > "$WORK/locks-abs/driver-lock.sh"
chmod +x "$WORK/locks/driver-lock.sh" "$WORK/locks-abs/driver-lock.sh"

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
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
Q() { VF_COCKPIT_SCRIPTS_DIR="${VF_PIN:-$WORK/locks}" node "$AUX/q.mjs" "$SCRIPTS" "$@"; }
G() { node "$AUX/get.mjs" "$@"; }
IFACE="$SCRIPTS/vf-cockpit-interface.json"
wr() { mkdir -p "$(dirname "$1")"; cat > "$1"; }   # wr <fichier> < contenu
graph() { Q project "$1" > "$2"; }
DR="$SCRIPTS/vf-cockpit-drift.mjs"
cat > "$AUX/borne.mjs" <<'JS'
// borne.mjs <ms> <commande node et arguments...> : enfant node borné par une limite de temps (SIGKILL, sans tube) ; une ligne JSON { timedOut, status, out }
import { spawnSync } from 'node:child_process';
const [, , ms, ...args] = process.argv;
const r = spawnSync(process.execPath, args, { timeout: Number(ms), killSignal: 'SIGKILL', encoding: 'utf8', maxBuffer: 64 << 20 });
console.log(JSON.stringify({ timedOut: r.error?.code === 'ETIMEDOUT', status: r.status, out: r.stdout || '' }));
JS
cat > "$AUX/mutsub.mjs" <<'JS'
// mutsub.mjs <fichier> — remplace UNE occurrence exacte de $FROM par $TO dans une COPIE ; "ancre absente" si $FROM n'y est pas
import fs from 'node:fs';
const f = process.argv[2]; const t = fs.readFileSync(f, 'utf8');
if (!t.includes(process.env.FROM)) { console.log('ancre absente'); process.exit(1); }
fs.writeFileSync(f, t.replace(process.env.FROM, () => process.env.TO)); console.log('muté');
JS
mut7() { local d="$WORK/mut-$1"; rm -rf "$d"; mkdir -p "$d"; cp "$SCRIPTS"/*.mjs "$SCRIPTS/vf-cockpit-interface.json" "$d/"; FROM="$3" TO="$4" node "$AUX/mutsub.mjs" "$d/$2"; }
# fixture R3 (lab de dérive : 1 toléré, 3 lignes non lues au ROADMAP et 1 aux exigences, la phase 3 hors jalon) ; le dossier est un argument
mk_r3() { local L3="$1" B="$1/.planning"; mkdir -p "$B"
printf '%s\n' '# Roadmap' '' '## Milestones' '' '- 🚧 **v1.0 Démo** - Phases 1-2 (in progress)' '' '## Phases' '' '- [x] **Phase 1: Socle** - a' '- [ ] **Phase 2: Écran** - b' '- [ ] **Phase 3: Orpheline** - c' '' \
  '### Phase 1: Socle' '**Goal**: g1' '' '### Phase 2 : Écran' '**Goal** — g2' 'Dépends sur : Phase 1' '' '##### Phase 4: trop profond' > "$B/ROADMAP.md"
printf '%s\n' '- [ ] **AUTH-01**: ok' '- [ ] **Req_02** illisible' > "$B/REQUIREMENTS.md"
printf -- '---\nstatus: executing\ncurrent_phase: 2\nmilestone: v1.0 Démo\n---\n' > "$B/STATE.md"
printf '<objective>Socle</objective>\n' | wr "$B/phases/01-socle/01-01-PLAN.md"; echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
git -C "$L3" init -q && git -C "$L3" add -A && git -C "$L3" -c user.email=t@t -c user.name=t commit -qm init
}
bilan() {
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
}
