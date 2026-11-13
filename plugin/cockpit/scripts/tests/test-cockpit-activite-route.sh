#!/usr/bin/env bash
# test-cockpit-activite-route.sh — Phase 75, plan 75-05 (ACTV-04, ACTV-08, ACTV-10, ACTV-12 ; P75-D-09, P75-D-22, P75-D-23, A10, A11, A25, A31, A45, A47) :
# la route GET /api/vf/activite, son schéma, son cache par signature, son mono-vol, ses dégradations et l'export autonome qui reste fermé.
#   R1-R4 route, accès, table, schéma (serveur lancé) · R5-R17 assemblage, cache, mono-vol, clés, dégradations, bornes (module en node, hors serveur)
#   X1-X3 l'export autonome ne porte rien de l'activité (A25), avec son témoin positif
# Mutants : une copie des scripts, l'ancre à exactement une occurrence, `node --check` prouve que la copie charge ; le témoin rejoué DOIT rougir.
# Sortie : « PASS — <id> : … », « ❌ FAIL — <id> : … », « MUTANT-ROUGE — <nom> », « BILAN : n PASS, m FAIL » ; code non nul au premier FAIL.
# Lab neutre dans mktemp, HOME jetable, isolation git. Le code testé est celui du dossier de cette suite.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE GIT_CEILING_DIRECTORIES
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
TESTS="$SCRIPTS/tests"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/tmp.XXXXXXXXXX")"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home" "$WORK/mut"
export HOME="$WORK/home"
trap 'vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"' EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
. "$(dirname "$0")/socle-serveur.sh"
NB=0; NF=0; NM=0
ok() { # ok <id> <texte> <obtenu> <attendu>
  if [ "$3" = "$4" ]; then echo "PASS — $1 : $2"; NB=$((NB+1))
  else echo "❌ FAIL — $1 : $2"; echo "     attendu: [${4:0:400}]"; echo "     obtenu:  [${3:0:400}]"; NF=$((NF+1)); echo "BILAN : $NB PASS, $NF FAIL"; exit 1; fi
}
assert_eq() { ok "${1%% — *}" "${1#* — }" "$2" "$3"; } # forme attendue par hygiene.sh (vf_hyg_assert)
rouge() { echo "MUTANT-ROUGE — $1"; NM=$((NM+1)); }
jf() { node -e "const j=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'));const v=new Function('j','return ('+process.argv[2]+')')(j);console.log(typeof v==='string'?v:JSON.stringify(v))" "$1" "$2" 2>/dev/null || echo illisible; }

# ---------- aides ----------
cat > "$AUX/mut.mjs" <<'JS'
// mut.mjs <scripts> <dst> <fichier> <de> <vers> [<de> <vers>…] : copie les .mjs et le contrat, remplace chaque ancre EXACTEMENT une fois (code 3 sinon), la copie doit charger
import fs from 'node:fs'; import path from 'node:path'; import { execFileSync } from 'node:child_process';
const [, , src, dst, fichier, ...paires] = process.argv;
fs.rmSync(dst, { recursive: true, force: true }); fs.mkdirSync(dst, { recursive: true });
for (const f of fs.readdirSync(src)) if (/\.mjs$|\.json$/.test(f)) fs.copyFileSync(path.join(src, f), path.join(dst, f));
const cible = path.join(dst, fichier); let t = fs.readFileSync(cible, 'utf8');
for (let i = 0; i < paires.length; i += 2) {
  const n = t.split(paires[i]).length - 1;
  if (n !== 1) { console.error(`ancre « ${paires[i].slice(0, 60)} » : ${n} occurrence(s)`); process.exit(3); }
  t = t.replace(paires[i], () => paires[i + 1]);
}
fs.writeFileSync(cible, t);
if (/\.mjs$/.test(fichier)) try { execFileSync(process.execPath, ['--check', cible], { stdio: 'pipe' }); } catch (e) { console.error('la copie ne charge pas : ' + String(e.stderr).slice(0, 200)); process.exit(4); }
JS
mutant() { # mutant <nom> <fichier> <de> <vers> [...] -> chemin de la copie sur la sortie standard ; un mutant invalide est un FAIL, jamais un rouge
  local nom="$1"; shift; node "$AUX/mut.mjs" "$SCRIPTS" "$WORK/mut/$nom" "$@" > /dev/null 2> "$WORK/mut/$nom.err" || { echo "❌ FAIL — mutant $nom invalide : $(cat "$WORK/mut/$nom.err")"; echo "BILAN : $NB PASS, $((NF+1)) FAIL"; exit 1; }
  echo "$WORK/mut/$nom"
}
# validateur INDÉPENDANT de la suite : clés requises typées, énumérations du bloc, interdits absents à toute profondeur, clés dynamiques exclues
cat > "$AUX/valide.mjs" <<'JS'
// valide.mjs <contrat> <fichier> : OK, ou KO et les écarts
import fs from 'node:fs';
const [, , ifaceF, outF] = process.argv, id = 'vibeflow/cockpit-activite@1';
let spec, out;
try { spec = JSON.parse(fs.readFileSync(ifaceF, 'utf8')).schemas[id]; } catch { spec = null; }
if (!spec) { console.log('KO schéma absent du contrat'); process.exit(1); }
try { out = JSON.parse(fs.readFileSync(outF, 'utf8')); } catch { console.log('KO sortie illisible'); process.exit(1); }
const errs = [], type = (v) => (Array.isArray(v) ? 'array' : v === null ? 'null' : typeof v);
for (const [k, t] of Object.entries(spec.requis || {})) { if (!(k in out)) errs.push(`absente : ${k}`); else if (type(out[k]) !== t) errs.push(`type de ${k} : ${type(out[k])}`); }
if (out.schema !== id) errs.push(`schema = ${out.schema}`);
if (JSON.stringify(spec.interdits) !== JSON.stringify(['doing', 'mandat', 'messages', 'outils', 'fil'])) errs.push('interdits du bloc non recopiés');
const deep = (o, f) => { if (o && typeof o === 'object') for (const [k, v] of Object.entries(o)) { if (!Array.isArray(o)) f(k); deep(v, f); } }; // les indices d'un tableau ne sont pas des clés
deep(out, (k) => { if ((spec.interdits || []).includes(k)) errs.push(`interdite : ${k}`); });
const cles = new Set(spec.cles || []); deep(out, (k) => { if (!cles.has(k)) errs.push(`clé hors contrat : ${String(k).slice(0, 40)}`); });
const dans = (v, l, nom) => { if (!(l || []).includes(v)) errs.push(`${nom} = ${v}`); };
dans(out.etat, spec.etats, 'etat'); dans(out.calcul, spec.calcul, 'calcul');
for (const s of ['git', 'branches', 'gardes', 'empreinte']) if (out[s]) dans(out[s].etat, (spec[s] || {}).etats, `${s}.etat`);
for (const t of out.collisions || []) { if (!Array.isArray(t) || t.length !== 4) errs.push('tuple de collision'); else dans(t[1], spec.collisions && spec.collisions.sources, 'source'); }
for (const r of (out.radar || {}).raisons || []) dans(r, spec.radar && spec.radar.raisons, 'raison');
console.log(errs.length ? 'KO ' + [...new Set(errs)].join(' | ') : 'OK'); process.exit(errs.length ? 1 : 0);
JS
valide() { node "$AUX/valide.mjs" "${2:-$SCRIPTS}/vf-cockpit-interface.json" "$1" 2>&1; }

# ---------- serveur lancé : lab neutre, assemblage, démarrage ----------
LAB="$WORK/lab"
node "$TESTS/frise-labo.mjs" lab "$LAB"
node "$SCRIPTS/vf-cockpit-build.mjs" "$LAB" --quiet > "$WORK/build.out" 2>&1 || { echo "❌ FAIL — R0 : assemblage du lab"; cat "$WORK/build.out"; echo "BILAN : $NB PASS, $((NF+1)) FAIL"; exit 1; }
cockpit_lancer "$LAB"
ok R0 "témoin : le serveur est lancé, le jeton est lu" "$([ "${VF_PORT:-0}" -gt 0 ] && [ "${#VF_JETON}" -ge 16 ] && echo oui || echo non)" "oui"
gc() { node "$TESTS/graphe-client.mjs" "$@"; }

echo "=== R1-R4 — la route, ses contrôles, la table, le schéma ==="
cockpit_get /api/vf/activite > "$WORK/r1.json" 2> /dev/null; R1_CODE="$VF_CODE"
ok R1 "GET /api/vf/activite : 200, JSON, les neuf champs de l'objet" "$R1_CODE|$(jf "$WORK/r1.json" '[j.schema,typeof j.at,typeof j.etat,typeof j.calcul,typeof j.git,typeof j.branches,typeof j.gardes,typeof j.empreinte,Array.isArray(j.collisions),typeof j.radar].join(",")')" "200|vibeflow/cockpit-activite@1,string,string,string,object,object,object,object,true,object"
J="$VF_JETON"; P="$VF_PORT"
R2="$(gc get "$P" /api/vf/activite "" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(JSON.parse(s).statut))')"
R2b="$(gc get "$P" /api/vf/activite "$J" "evil.example:$P" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(JSON.parse(s).statut))')"
R2c="$(gc get "$P" /api/vf/activite "$J" "" "Origin=http://evil.example" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(JSON.parse(s).statut))')"
R2d="$(gc get "$P" /api/vf/activite "faux-jeton-faux-jeton-00000000" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(JSON.parse(s).statut))')"
R2e=""; for m in POST PUT DELETE; do R2e="$R2e $(GRAPHE_METHODE=$m gc get "$P" /api/vf/activite "$J" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(JSON.parse(s).statut))')"; done
R2f="$(gc get "$P" /api/vf/activite "$J" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const j=JSON.parse(s);console.log(j.statut+"|"+j.entetes["cache-control"]+"|"+Object.keys(j.entetes).filter(k=>k.startsWith("access-control")).length)})')"
R2_SRC="$(grep -c -E 'x-vf-cockpit-token|Host' "$SCRIPTS/vf-cockpit-activite.mjs" 2>/dev/null || true)"
ok R2 "accès par la réponse gardée : sans jeton, Host étranger, Origin étrangère, faux jeton = 403 ; POST, PUT, DELETE = 405 ; 200 no-store sans CORS ; aucun contrôle recopié dans le module" "$R2 $R2b $R2c $R2d$R2e|$R2f|$R2_SRC" "403 403 403 403 405 405 405|200|no-store|0|0"
STAT_ROUTES="$(node --input-type=module -e "const m=await import('file://$SCRIPTS/vf-cockpit-server.mjs');const a=await import('file://$SCRIPTS/vf-cockpit-activite.mjs');const c=m.ROUTES.map((l)=>l[0]);const L=m.ROUTES.filter((l)=>l[0]==='/api/vf/activite');console.log([L.length,c.indexOf('/api/vf/activite')===0,JSON.stringify(c)===JSON.stringify([...c].sort()),L[0]&&L[0][1]===a.routeActivite,L[0]&&L[0].length].join(','))" 2>/dev/null || echo absent)"
ok R3 "la table importée : UNE ligne /api/vf/activite, en tête de l'ordre alphabétique, ordre trié, lecteur = routeActivite, aucun régime" "$STAT_ROUTES" "1,true,true,true,2"
node "$AUX/valide.mjs" "$SCRIPTS/vf-cockpit-interface.json" "$WORK/r1.json" > "$WORK/r4.out" 2>&1; ok R4 "le bloc vibeflow/cockpit-activite@1 est déclaré, interdits recopiés, la réponse réelle est conforme (clés, énumérations)" "$(cat "$WORK/r4.out")" "OK"
cockpit_arreter

# ---- mutants de la tâche 1 (quatre) ----
M="$(mutant ligne-double vf-cockpit-server.mjs "  ['/api/vf/activite', routeActivite]," "  ['/api/vf/activite', routeActivite],
  ['/api/vf/activite', routeActivite],")"
[ "$(node --input-type=module -e "const m=await import('file://$M/vf-cockpit-server.mjs');console.log(m.ROUTES.filter((l)=>l[0]==='/api/vf/activite').length===1)" 2>/dev/null)" = "true" ] || rouge "ligne-en-double"
M="$(mutant ligne-hors-ordre vf-cockpit-server.mjs "  ['/api/vf/activite', routeActivite],
  ['/api/vf/doing', lireDoing, HISTORIQUE]," "  ['/api/vf/doing', lireDoing, HISTORIQUE],
  ['/api/vf/activite', routeActivite],")"
[ "$(node --input-type=module -e "const m=await import('file://$M/vf-cockpit-server.mjs');const c=m.ROUTES.map((l)=>l[0]);console.log(JSON.stringify(c)===JSON.stringify([...c].sort()))" 2>/dev/null)" = "true" ] || rouge "ligne-hors-ordre"
M="$(mutant controle-recopie vf-cockpit-activite.mjs "export const routeActivite" "const _faux = (r) => r.headers['x-vf-cockpit-token'];
export const routeActivite")"
[ "$(grep -c -E 'x-vf-cockpit-token|Host' "$M/vf-cockpit-activite.mjs")" = "0" ] || rouge "controle-recopie-dans-le-module"
M="$(mutant schema-sans-interdits vf-cockpit-interface.json '"interdits": ["doing", "mandat", "messages", "outils", "fil"]
    },
    "vibeflow/cockpit-git@1"' '"interdits": []
    },
    "vibeflow/cockpit-git@1"')"
[ "$(node "$AUX/valide.mjs" "$M/vf-cockpit-interface.json" "$WORK/r1.json" 2>&1)" = "OK" ] || rouge "bloc-sans-interdits"

# --- FIN-SECTIONS ---
vf_hyg_assert
echo "MUTANTS : $NM rouges"
echo "BILAN : $NB PASS, $NF FAIL"
[ "$NF" -eq 0 ]
