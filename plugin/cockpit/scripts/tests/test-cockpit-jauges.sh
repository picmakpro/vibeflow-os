#!/usr/bin/env bash
# test-cockpit-jauges.sh — GET /api/vf/methode : les jauges de la Santé de la méthode, lues dans les deux gates du conductor en TSV (77-03 ; P77-D-03, P77-D-04,
# P77-D-05, P77-D-20, P77-D-36 ; SYNT-03, SYNT-04). Les gates : check-method-budget.sh et check-instruction-budget.sh (contrat `#vf-budget@1`, plan 77-01).
#   JP  module pur de traduction (vf-cockpit-jauges.mjs)          JH  la route : accès, méthode, en-têtes, schéma
#   JR1 réseau · JR2 lecture seule · JR3 hors boucle, un seul lancement, cache · JR4 non-gel · JR5 chemins du poste · JR6 lab tiers · JR7 contrat des gates
#   JR8 copie ancienne, version inconnue, échéance · JR9 script de l'arbre observé · JR10 programme déclaré par le lab (git, environnement, dépôt sortant)
#   mutants (régime allégé de la Phase 77 : seuls les gardes M-CHEMIN, M-AUTO, M-TSV-RANGEMENT et M-ENV-GIT) : sur copie du module ou du conductor.
# Faux gates, faux `gh`, faux `git`, faux `bash` : HORS du lab. Le serveur se lance par l'aide commune (socle-serveur.sh), jamais par serve.mjs en direct.
# Exit 0 si tout passe, 1 sinon.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
TESTS="$SCRIPTS/tests"
CONDUCTOR="$(cd "$SCRIPTS/../../conductor/scripts" && pwd -P)"
mkdir -p "${TMPDIR:-/tmp}"; WORK="$(mktemp -d "${TMPDIR:-/tmp}/tmp.XXXXXXXXXX")"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"
export HOME="$WORK/home"
trap 'vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"' EXIT
. "$TESTS/hygiene.sh"; vf_hyg_init
. "$TESTS/socle-serveur.sh"
PASS=0; FAIL=0
court() { if [ "${#1}" -gt 300 ]; then printf '%s […] %s' "${1:0:140}" "${1: -140}"; else printf '%s' "$1"; fi; }
assert_eq() { if [ "$#" -ne 3 ]; then echo "  ❌ FAIL — $1 (assert_eq a reçu $# arguments au lieu de 3)"; FAIL=$((FAIL+1)); elif [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$(court "$3")]"; echo "     obtenu:  [$(court "$2")]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [$(court "$2")]"; FAIL=$((FAIL+1)); fi; }
assert_no() { if [[ "$2" != *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     sous-chaîne interdite présente: [$3]"; FAIL=$((FAIL+1)); fi; }

# ---- outils node écrits par la suite ----
cat > "$AUX/ev.mjs" <<'JS'
// ev.mjs <fichier|-> <expression sur j> : lit un JSON (fichier ou entrée standard)
import fs from 'node:fs';
let j; try { j = JSON.parse(fs.readFileSync(process.argv[2] === '-' ? 0 : process.argv[2], 'utf8')); } catch { console.log('illisible'); process.exit(0); }
let v; try { v = new Function('j', 'return (' + process.argv[3] + ')')(j); } catch (e) { v = 'erreur: ' + e.message; }
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/req.mjs" <<'JS'
// req.mjs <port> <chemin> <méthode> <jeton|-> <hôte|-> : une requête, une ligne JSON { status, cc, ct, body }
import http from 'node:http';
const [, , port, p, method, token, host] = process.argv;
const headers = { Host: host === '-' ? `127.0.0.1:${port}` : host };
if (token !== '-') headers['x-vf-cockpit-token'] = token;
const r = http.request({ host: '127.0.0.1', port: Number(port), path: p, method, headers, agent: false }, (res) => {
  let b = ''; res.on('data', (c) => (b += c)); res.on('end', () => console.log(JSON.stringify({ status: res.statusCode, cc: res.headers['cache-control'] || '', ct: res.headers['content-type'] || '', body: b })));
});
r.on('error', (e) => console.log(JSON.stringify({ status: 0, erreur: e.code }))); r.end();
JS
cat > "$AUX/conc.mjs" <<'JS'
// conc.mjs <port> <jeton> non-gel | rafale <n> : non-gel = un GET methode en vol et cinq GET etat chronométrés ; rafale = n GET methode simultanés
import http from 'node:http';
const [, , port, token, mode, n] = process.argv;
const get = (p) => new Promise((res) => { const t0 = Date.now();
  const r = http.get({ host: '127.0.0.1', port: Number(port), path: p, headers: { Host: `127.0.0.1:${port}`, 'x-vf-cockpit-token': token }, agent: false }, (q) => { let b = ''; q.on('data', (c) => (b += c)); q.on('end', () => res({ status: q.statusCode, ms: Date.now() - t0, body: b })); });
  r.on('error', () => res({ status: 0, ms: Date.now() - t0, body: '' })); });
const pause = (ms) => new Promise((r) => setTimeout(r, ms));
if (mode === 'rafale') { const rs = await Promise.all(Array.from({ length: Number(n) }, () => get('/api/vf/methode'))); console.log(JSON.stringify({ statuts: rs.map((x) => x.status) })); }
else { const m = get('/api/vf/methode'); await pause(150); const etat = []; for (let i = 0; i < 5; i++) { etat.push(await get('/api/vf/etat')); await pause(60); } const r = await m;
  console.log(JSON.stringify({ methodeMs: r.ms, methodeStatut: r.status, etatMs: etat.map((x) => x.ms), etatStatuts: etat.map((x) => x.status) })); }
JS
cat > "$AUX/validate.mjs" <<'JS'
// validate.mjs <interface.json> <schemaId> <sortie.json> : clés requises et typées, listes fermées, clés interdites à toute profondeur
import fs from 'node:fs';
const [, , ifaceF, id, outF] = process.argv;
const spec = JSON.parse(fs.readFileSync(ifaceF, 'utf8')).schemas?.[id];
if (!spec) { console.log('KO schéma non déclaré'); process.exit(1); }
const out = JSON.parse(fs.readFileSync(outF, 'utf8')), errs = [];
const type = (v) => (Array.isArray(v) ? 'array' : v === null ? 'null' : typeof v);
for (const [k, t] of Object.entries(spec.requis || {})) { if (!(k in out)) errs.push(`clé requise absente : ${k}`); else if (type(out[k]) !== t) errs.push(`type de ${k}`); }
if (out.schema !== id) errs.push(`schema = ${out.schema}`);
const deep = (o, f) => { if (o && typeof o === 'object') for (const [k, v] of Object.entries(o)) { f(k); deep(v, f); } };
deep(out, (k) => { if ((spec.interdits || []).includes(k)) errs.push(`clé interdite : ${k}`); });
for (const g of out.jauges || []) {
  for (const k of spec.jauge?.requis || []) if (!(k in g)) errs.push(`jauge ${g.type} : ${k} absente`);
  if (!(spec.types || []).includes(g.type)) errs.push(`type inconnu ${g.type}`);
  if (!(spec.verdicts || []).includes(g.verdict)) errs.push(`verdict inconnu ${g.verdict}`);
  if (g.cause !== null && !(spec.causes || []).includes(g.cause)) errs.push(`cause inconnue ${g.cause}`);
}
console.log(errs.length ? 'KO ' + errs.join(' | ') : 'OK'); process.exit(errs.length ? 1 : 0);
JS
# jp.mjs <scripts> : le module pur, cas par cas ; une ligne JSON { JPn: booléen }
cat > "$AUX/jp.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
const M = await import(pathToFileURL(process.argv[2] + '/vf-cockpit-jauges.mjs').href);
const { lireTsv, etatSource, assembler, TYPES, ENTETE } = M, r = {};
const MET = 'check-method-budget', INS = 'check-instruction-budget';
const tsv = (g, lignes, ent = `${ENTETE}\t${g}`) => [ent, ...lignes.map((l) => l.join('\t'))].join('\n') + '\n';
const L = (type, chemin, valeur, budget, unite, verdict) => [type, chemin, valeur, budget, unite, verdict];
const lig = (g, l) => lireTsv(tsv(g, l), g).lignes;
const tr = lig(INS, [L('agent', 'a', '1', '300', 'lignes', 'OK'), L('agent', 'b', '251', '300', 'lignes', 'AVERTISSEMENT'), L('agent', 'c', '301', '300', 'lignes', 'DEPASSE'),
  L('agent', 'd', '-', '300', 'lignes', 'NON-APPLICABLE'), L('agent', 'e', '-', '300', 'lignes', 'NON-VERIFIABLE'), L('agent', 'f', '1', '300', 'lignes', 'BIZARRE')]);
r.JP1 = JSON.stringify(tr.map((x) => x.verdict)) === JSON.stringify(['ok', 'surveiller', 'depasse', 'na', 'indispo', 'format']);
r.JP2 = [lireTsv('', MET), lireTsv(`#vf-budget@9\t${MET}\n`, MET), lireTsv(`${ENTETE}\t${INS}\n`, MET), lireTsv(`${ENTETE} ${MET}\n`, MET)].every((x) => x.ok === false && x.cause === 'format') && lireTsv(`${ENTETE}\t${MET}\n`, MET).ok === true;
const ch = lig(MET, [L('roadmap', '/x', '1', '2', 'Ko', 'OK'), L('roadmap', '~/x', '1', '2', 'Ko', 'OK'), L('roadmap', 'a/../b', '1', '2', 'Ko', 'OK'), L('roadmap', 'C:\\x', '1', '2', 'Ko', 'OK'),
  L('roadmap', '..', '1', '2', 'Ko', 'OK'), L('roadmap', '.planning/ROADMAP.md', '1', '2', 'Ko', 'OK'), L('roadmap', '.', '1', '2', 'Ko', 'OK')]);
r.JP3 = ch.slice(0, 5).every((x) => x.verdict === 'format' && x.chemin === null) && ch[5].chemin === '.planning/ROADMAP.md' && ch[5].verdict === 'ok' && ch[6].chemin === '.';
const cinq = lireTsv(`${ENTETE}\t${MET}\nstate\t.\t1\t2\tKo\n`, MET).lignes[0];
r.JP4 = cinq.verdict === 'format' && cinq.valeur === null;
const mal = lig(MET, [L('state', '.', 'x', '2', 'Ko', 'OK'), L('state', '.', '-', '2', 'Ko', 'OK'), L('state', '.', '1', '2', 'lignes', 'OK'), L('state', '.', '1', '-', 'Ko', 'OK'), L('state', '.', '1', '2', 'Ko', 'OK')]);
r.JP5 = mal.slice(0, 4).every((x) => x.verdict === 'format') && mal[4].verdict === 'ok';
const mes = (...l) => assembler({ methode: { etat: 'ok', cause: null, lignes: [] }, densite: { etat: 'ok', cause: null, lignes: lig(INS, l) }, at: 'T' }).jauges.find((g) => g.type === 'agent').mesures;
const ordre = mes(L('agent', 'ok1', '100', '300', 'lignes', 'OK'), L('agent', 'ok2', '200', '300', 'lignes', 'OK'), L('agent', 'dep', '301', '300', 'lignes', 'DEPASSE'), L('agent', 'surv', '251', '300', 'lignes', 'AVERTISSEMENT'),
  L('agent', 'indis', '-', '300', 'lignes', 'NON-VERIFIABLE'), L('agent', 'fmt', '1', '300', 'lignes', 'ZZ'), L('agent', 'ok0', '200', '300', 'lignes', 'OK')).map((m) => m.chemin);
r.JP6 = JSON.stringify(ordre) === JSON.stringify(['dep', 'surv', 'indis', null, 'ok0', 'ok2', 'ok1']);
const beaucoup = Array.from({ length: 250 }, (_, i) => L('agent', `a${String(i).padStart(3, '0')}`, String(i), '300', 'lignes', 'OK'));
const jb = assembler({ methode: { etat: 'ok', cause: null, lignes: [] }, densite: { etat: 'ok', cause: null, lignes: lig(INS, beaucoup) }, at: 'T' }).jauges.find((g) => g.type === 'agent');
r.JP7 = jb.mesures.length === 200 && jb.tronque === true;
const enorme = lireTsv(tsv(INS, Array.from({ length: 2500 }, (_, i) => L('agent', `a${i}`, '1', '300', 'lignes', 'OK'))), INS);
r.JP8 = enorme.lignes.length === 2000 && enorme.tronque === true;
const bs = (v) => assembler({ methode: { etat: 'ok', cause: null, lignes: [] }, densite: { etat: 'ok', cause: null, lignes: lig(INS, [L('socle', '.', '1500', '2000', 'jetons', 'OK'), L('socle-baseline', '.', '1500', '-', 'jetons', v)]) }, at: 'T' }).jauges.find((g) => g.type === 'socle');
r.JP9 = JSON.stringify([bs('EGALE').baseline, bs('AU-DESSUS').baseline.relation, bs('EN-DESSOUS').baseline.relation]) === JSON.stringify([{ valeur: 1500, relation: 'egale' }, 'au-dessus', 'en-dessous'])
  && assembler({ methode: { etat: 'ok', cause: null, lignes: [] }, densite: { etat: 'ok', cause: null, lignes: lig(INS, [L('socle', '.', '1500', '2000', 'jetons', 'OK')]) }, at: 'T' }).jauges.find((g) => g.type === 'socle').baseline === null;
const att = ['state', 'state-prose', 'backlog-ouverts', 'backlog-entree', 'backlog-clos', 'roadmap', 'memory-index', 'worktrees', 'agent', 'skill', 'socle'];
const vide = assembler({ methode: { etat: 'ok', cause: null, lignes: [] }, densite: { etat: 'ok', cause: null, lignes: [] }, at: 'T' });
r.JP10 = JSON.stringify(TYPES.map((t) => (typeof t === 'string' ? t : t.type))) === JSON.stringify(att) && JSON.stringify(vide.jauges.map((g) => g.type)) === JSON.stringify(att) && vide.schema === 'vibeflow/cockpit-jauges@1'
  && JSON.stringify(vide.jauges.map((g) => g.groupe)) === JSON.stringify(['planning', 'planning', 'planning', 'planning', 'planning', 'planning', 'memoire', 'memoire', 'instructions', 'instructions', 'instructions']);
const ind = assembler({ methode: { etat: 'ok', cause: null, lignes: [] }, densite: { etat: 'indisponible', cause: 'ancien', lignes: [] }, at: 'T' });
r.JP11 = ind.jauges.filter((g) => g.groupe === 'instructions').every((g) => g.verdict === 'indispo' && g.cause === 'ancien' && g.mesures.length === 0) && ind.sources.densite.etat === 'indisponible' && ind.sources.densite.cause === 'ancien' && ind.jauges[0].verdict === 'na';
const na = assembler({ methode: { etat: 'ok', cause: null, lignes: [] }, densite: { etat: 'non-applicable', cause: null, lignes: lig(INS, [L('agent', '-', '-', '300', 'lignes', 'NON-APPLICABLE')]) }, at: 'T' });
r.JP12 = na.jauges.filter((g) => g.groupe === 'instructions').every((g) => g.verdict === 'na') && !JSON.stringify(na.jauges).includes('"valeur":0');
const lan = (o) => ({ sortie: '', code: 0, tronque: false, absent: false, echeance: false, delai: false, ...o });
const bon = tsv(MET, [L('state', '.', '1', '2', 'Ko', 'OK')]);
const es = (l, g = MET) => { const x = etatSource(l, g); return `${x.etat}/${x.cause}`; };
r.JP13 = [es(null), es(lan({ absent: true })), es(lan({ delai: true, echeance: true })), es(lan({ code: 64 })), es(lan({ sortie: '', code: 0 })), es(lan({ sortie: `#vf-budget@9\t${MET}\n` })),
  es(lan({ sortie: bon, tronque: true })), es(lan({ sortie: bon })), es(lan({ sortie: tsv(INS, [L('agent', '-', '-', '300', 'lignes', 'NON-APPLICABLE')]), code: 2 }), INS), es(lan({ sortie: tsv(INS, [L('agent', 'a', '1', '300', 'lignes', 'OK')]), code: 2 }), INS)].join(' ')
  === 'indisponible/absent indisponible/absent indisponible/delai indisponible/ancien indisponible/format indisponible/format indisponible/echec ok/null non-applicable/null ok/null';
// JR7a : un échantillon figé par gate, tous les types ; aucune mesure format, un jeton inconnu en donne une
const fig = { [MET]: [L('state', '.planning/STATE.md', '12', '40', 'Ko', 'OK'), L('state-prose', '.planning/STATE.md', '5', '12', 'lignes', 'OK'), L('backlog-ouverts', '.planning/BACKLOG.md', '3', '50', 'sujets', 'OK'),
  L('backlog-entree', '.planning/BACKLOG.md', '45', '40', 'lignes', 'DEPASSE'), L('backlog-clos', '.planning/BACKLOG.md', '0', '0', 'sujets', 'OK'), L('roadmap', '.planning/ROADMAP.md', '30', '60', 'Ko', 'AVERTISSEMENT'),
  L('memory-index', 'MEMORY.md', '120', '200', 'lignes', 'OK'), L('worktrees', '.', '2', '5', 'worktrees', 'OK')],
  [INS]: [L('agent', 'plugin/x/agents/a.md', '251', '300', 'lignes', 'AVERTISSEMENT'), L('skill', 'plugin/x/skills/s/SKILL.md', '100', '500', 'lignes', 'OK'), L('socle', '.', '1500', '2000', 'jetons', 'OK'), L('socle-baseline', '.', '1500', '-', 'jetons', 'EGALE')] };
const fa = assembler({ methode: { etat: 'ok', cause: null, lignes: lig(MET, fig[MET]) }, densite: { etat: 'ok', cause: null, lignes: lig(INS, fig[INS]) }, at: 'T' });
r.JR7a = fa.jauges.every((g) => g.mesures.length > 0 && g.mesures.every((m) => m.verdict !== 'format')) && lig(MET, [L('state', '.', '1', '2', 'Ko', 'INCONNU')])[0].verdict === 'format';
console.log(JSON.stringify(r));
JS
# m3.mjs <scripts> <dossier des gates> <lab> : cache, lancement partagé, échéance, au niveau du module (horloge et lanceur injectés)
cat > "$AUX/m3.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
const [, , scripts, gates, lab] = process.argv, M = await import(pathToFileURL(scripts + '/vf-cockpit-methode.mjs').href);
const ENT = '#vf-budget@1', out = {};
const sortie = (g) => g.endsWith('check-method-budget.sh') ? `${ENT}\tcheck-method-budget\nstate\t.\t1\t2\tKo\tOK\n` : `${ENT}\tcheck-instruction-budget\nagent\ta\t1\t300\tlignes\tOK\n`;
let n = 0; const fins = []; let dort = 0;
const lancer = async (cmd, args, cwd, env, max, fin) => { n++; fins.push(fin); if (dort) await new Promise((r) => setTimeout(r, dort)); return { sortie: sortie(args[0]), code: 0, tronque: false, absent: false, echeance: false, delai: false }; };
let t = 1000; const now = () => t;
const m = M.creerMethode({ root: lab, scriptsDir: gates, home: lab + '/nohome', lancer, now });
out.aucunALaCreation = n === 0;
await m.lire(); out.premier = n;            // deux gates
t += 1000; await m.lire(); out.cache1s = n;
t += 58000; await m.lire(); out.apres59s = n; t += 2000; await m.lire(); out.apres61s = n; // 61 s après le premier : relancé
dort = 300; t += 61000; const [a, b] = await Promise.all([m.lire(), m.lire()]); out.simultanes = n; out.memeObjet = a === b;
const att = n; t += 61000; const [c, d] = await Promise.all([m.lire(), m.lire(), m.lire()]); out.troisSimultanes = n - att;
out.fin = fins.every((f) => Math.abs(f - (Date.now() + M.ECHEANCE_MS)) < 2500);
out.ttl = M.TTL_MS; out.echeance = M.ECHEANCE_MS;
// JR8 : délai
const lanD = async () => ({ sortie: '', code: null, tronque: false, absent: false, echeance: true, delai: true });
const md = M.creerMethode({ root: lab, scriptsDir: gates, home: lab + '/nohome', lancer: lanD, now });
const o = await md.lire(); out.delai = o.jauges.every((g) => g.verdict === 'indispo' && g.cause === 'delai');
// jamais de rejet : un lanceur qui lève
const mr = M.creerMethode({ root: lab, scriptsDir: gates, home: lab + '/nohome', lancer: async () => { throw new Error('x'); }, now });
const or = await mr.lire(); out.leve = or.jauges.every((g) => g.verdict === 'indispo' && g.cause === 'echec');
console.log(JSON.stringify(out));
JS
cat > "$AUX/dl.mjs" <<'JS'
// dl.mjs <scripts> <scriptsDir> <lab> <home> <nom> : driverLockScript paramétré par le nom du fichier
import { pathToFileURL } from 'node:url';
const [, , scripts, sd, lab, home, nom] = process.argv, m = await import(pathToFileURL(scripts + '/vf-cockpit-paths.mjs').href);
const r = m.driverLockScript({ scriptsDir: sd === '-' ? undefined : sd, labRoot: lab, home, ...(nom === '-' ? {} : { nom }) });
console.log(JSON.stringify({ etat: r.etat, base: r.chemin ? r.chemin.split('/').pop() : null }));
JS

# ---- faux gates (HORS du lab), pilotés par l'environnement du serveur : FAUX_ARGV, FAUX_COMPTE, FAUX_ENV, FAUX_DELAI, FAUX_MODE (64 | version | tiers | abs) ----
faux_gates() { # <dossier>
  mkdir -p "$1"
  cat > "$1/check-method-budget.sh" <<'SH'
#!/usr/bin/env bash
g="$(basename "$0" .sh)"
[ -z "${FAUX_ARGV:-}" ] || printf '%s %s\n' "$g" "$*" >> "$FAUX_ARGV"
[ -z "${FAUX_COMPTE:-}" ] || echo "$g" >> "$FAUX_COMPTE"
[ -z "${FAUX_ENV:-}" ] || { env | LC_ALL=C sort > "$FAUX_ENV"; git rev-parse --show-toplevel >> "$FAUX_ENV" 2>&1; }
[ -z "${FAUX_DELAI:-}" ] || sleep "$FAUX_DELAI"
case "${FAUX_MODE:-}" in
  64) echo "usage" >&2; exit 64 ;;
  version) printf '#vf-budget@9\t%s\n' "$g"; exit 0 ;;
esac
printf '#vf-budget@1\t%s\n' "$g"
if [ "$g" = check-method-budget ]; then
  printf 'state\t.planning/STATE.md\t12\t40\tKo\tOK\nstate-prose\t.planning/STATE.md\t5\t12\tlignes\tOK\nbacklog-ouverts\t.planning/BACKLOG.md\t3\t50\tsujets\tOK\n'
  printf 'backlog-entree\t.planning/BACKLOG.md\t45\t40\tlignes\tDEPASSE\nbacklog-clos\t.planning/BACKLOG.md\t0\t0\tsujets\tOK\nroadmap\t.planning/ROADMAP.md\t30\t60\tKo\tAVERTISSEMENT\n'
  printf 'memory-index\tMEMORY.md\t120\t200\tlignes\tOK\nworktrees\t.\t2\t5\tworktrees\tOK\n'
  [ "${FAUX_MODE:-}" != abs ] || printf 'roadmap\t%s/.planning/ROADMAP.md\t31\t60\tKo\tOK\n' "$PWD"
else
  if [ "${FAUX_MODE:-}" = tiers ]; then
    printf 'agent\t-\t-\t300\tlignes\tNON-APPLICABLE\nskill\t-\t-\t500\tlignes\tNON-APPLICABLE\nsocle\t-\t-\t2000\tjetons\tNON-APPLICABLE\n'; exit 2
  fi
  printf 'agent\tplugin/x/agents/a.md\t251\t300\tlignes\tAVERTISSEMENT\nskill\tplugin/x/skills/s/SKILL.md\t100\t500\tlignes\tOK\nsocle\t.\t1500\t2000\tjetons\tOK\nsocle-baseline\t.\t1500\t-\tjetons\tEGALE\n'
fi
exit 0
SH
  cp "$1/check-method-budget.sh" "$1/check-instruction-budget.sh"
}
GATES="$WORK/gates"; faux_gates "$GATES"
E() { node "$AUX/ev.mjs" "$1" "$2"; }
srv() { # <lab> [NOM=valeur…] : lab neuf (fixture, build), serveur lancé ; VF_PORT et VF_JETON posés
  local l="$1" nom; nom="$(basename "$(dirname "$1")")-$(basename "$1")"; shift
  [ -d "$l/.planning" ] || node "$TESTS/collecte-labo.mjs" lab "$l" > /dev/null
  [ -f "$l/.vibeflow/cockpit/index.html" ] || node "$SCRIPTS/vf-cockpit-build.mjs" "$l" --quiet > /dev/null 2>&1
  COCKPIT_LOG="$WORK/serve-$nom.out" cockpit_lancer "$l" "$@"
}
methode() { cockpit_get /api/vf/methode > "$1"; } # <fichier> : le corps ; le code reste dans VF_CODE

# ===== JP — le module pur =====
echo "=== JP — traduction pure du TSV ==="
JP="$(node "$AUX/jp.mjs" "$SCRIPTS" 2>&1)"
[ -n "$JP" ] && [[ "$JP" == "{"* ]] || { echo "  ❌ FAIL — JP — le module pur ne charge pas : $(court "$JP")"; FAIL=$((FAIL+1)); JP='{}'; }
jp() { assert_eq "$1" "$(printf '%s' "$JP" | node "$AUX/ev.mjs" - "j.$2 === true")" "true"; }
jp "JP1 — chaque jeton de verdict est traduit (OK, AVERTISSEMENT, DEPASSE, NON-APPLICABLE, NON-VERIFIABLE) et tout autre jeton donne « format »" JP1
jp "JP2 — en-tête exact exigé : vide, version @9, autre gate, séparateur espace : « format » ; l'en-tête exact est accepté" JP2
jp "JP3 — chemins rejetés (/x, ~/x, a/../b, C:\\x, ..) : mesure « format », chemin null ; chemin relatif et « . » conservés" JP3
jp "JP4 — une ligne à cinq champs est « format » (valeur jamais lue)" JP4
jp "JP5 — valeur non entière, « - » avec un verdict de mesure, unité qui ne correspond pas au type, budget « - » hors baseline : « format »" JP5
jp "JP6 — ordre des mesures : dépassé, à surveiller, indisponible, format, ok ; puis rapport valeur/budget décroissant, puis chemin" JP6
jp "JP7 — au plus 200 mesures par jauge, « tronque » vrai au-delà" JP7
jp "JP8 — lecture bornée à 2 000 lignes, « tronque » vrai au-delà" JP8
jp "JP9 — baseline du socle : egale, au-dessus, en dessous ; null sans ligne de baseline" JP9
jp "JP10 — onze jauges dans l'ordre de TYPES, groupes planning, memoire, instructions ; objet de schéma vibeflow/cockpit-jauges@1" JP10
jp "JP11 — source indisponible : ses jauges sont « indispo » avec la cause de la source, sans mesure ; l'autre source reste mesurée" JP11
jp "JP12 — lab tiers : jauges de densité « na », aucune valeur à 0" JP12
jp "JP13 — état d'une source : absent, délai, échéance, 64 (ancien), en-tête absent ou inconnu (format), tronquée (echec), code 2 avec NON-APPLICABLE (non-applicable), sinon ok" JP13
JPF="$SCRIPTS/vf-cockpit-jauges.mjs"
assert_eq "JP14 — pureté : aucun import, process, Date, Math.random, fs ni require dans vf-cockpit-jauges.mjs ; moins de 200 lignes ; lignes de 160 points de code au plus" \
  "$([ -f "$JPF" ] && ! /usr/bin/grep -nE '^[[:space:]]*import |process\.|Date\b|Math\.random|\bfs\b|require\(' "$JPF" | /usr/bin/grep -v '^[0-9]*:[[:space:]]*//' | /usr/bin/grep -q . && [ "$(awk 'END{print NR}' "$JPF")" -lt 200 ] && [ "$(LC_ALL=en_US.UTF-8 awk 'length($0)>160' "$JPF" | wc -l | tr -d ' ')" = 0 ] && echo pur || echo impur-ou-absent)" "pur"

# ===== JH et JR1a — la route sur faux gates =====
echo "=== JH — la route ==="
LA="$WORK/a/lab"; ARGV="$WORK/argv-a"; : > "$ARGV"
srv "$LA" VF_COCKPIT_SCRIPTS_DIR="$GATES" FAUX_ARGV="$ARGV"; RCA=$?
assert_eq "JH0 — le serveur de la section est lancé (code de cockpit_lancer)" "$RCA" "0"
methode "$WORK/a.json"
assert_eq "JH1 — GET /api/vf/methode avec le jeton : 200, schema vibeflow/cockpit-jauges@1, onze jauges dans l'ordre de TYPES" "$VF_CODE|$(E "$WORK/a.json" 'j.schema+" "+j.jauges.map(g=>g.type).join(",")')" "200|vibeflow/cockpit-jauges@1 state,state-prose,backlog-ouverts,backlog-entree,backlog-clos,roadmap,memory-index,worktrees,agent,skill,socle"
R="$(node "$AUX/req.mjs" "$VF_PORT" /api/vf/methode GET - -)"
assert_eq "JH2a — sans jeton : 403" "$(printf '%s' "$R" | node "$AUX/ev.mjs" - j.status)" "403"
R="$(node "$AUX/req.mjs" "$VF_PORT" /api/vf/methode GET "$VF_JETON" evil.example:80)"
assert_eq "JH2b — hôte faux : 403 (sonde positive : JH1, avec le jeton et le bon hôte, rend 200)" "$(printf '%s' "$R" | node "$AUX/ev.mjs" - j.status)" "403"
R="$(node "$AUX/req.mjs" "$VF_PORT" /api/vf/methode POST "$VF_JETON" -)"
assert_eq "JH3 — POST : 405 (fait par le répartiteur)" "$(printf '%s' "$R" | node "$AUX/ev.mjs" - j.status)" "405"
R="$(node "$AUX/req.mjs" "$VF_PORT" /api/vf/methode GET "$VF_JETON" -)"
assert_eq "JH4 — Cache-Control: no-store, type JSON, aucun en-tête CORS" "$(printf '%s' "$R" | node "$AUX/ev.mjs" - 'j.cc+"|"+j.ct')" "no-store|application/json"
assert_eq "JH5 — l'objet valide vibeflow/cockpit-jauges@1 (clés requises typées, listes fermées, clés interdites)" "$(node "$AUX/validate.mjs" "$SCRIPTS/vf-cockpit-interface.json" vibeflow/cockpit-jauges@1 "$WORK/a.json")" "OK"
assert_eq "JH6 — route inconnue à la base du chemin : 404 (sonde : /api/vf/methodes)" "$(node "$AUX/req.mjs" "$VF_PORT" /api/vf/methodes GET "$VF_JETON" - | node "$AUX/ev.mjs" - j.status)" "404"
assert_eq "JR1a — argv des deux gates : --root <lab> --no-remote --format=tsv, et --path <lab> --format=tsv" "$(sort "$ARGV" | tr '\n' '|')" "check-instruction-budget --path $LA --format=tsv|check-method-budget --root $LA --no-remote --format=tsv|"
cockpit_arreter

# ===== JR3 — hors boucle, un seul lancement, cache =====
echo "=== JR3 — aucun sous-processus hors demande, un seul lancement, cache ==="
compte() { /usr/bin/grep -c '^check-method-budget$' "$1" 2>/dev/null || true; }
C3="$WORK/c3"; : > "$C3"
srv "$WORK/c3l/lab" VF_COCKPIT_SCRIPTS_DIR="$GATES" FAUX_COMPTE="$C3"
assert_eq "JR3.0 — avant toute demande, après le démarrage du serveur : 0 lancement" "$(compte "$C3")" "0"
methode "$WORK/c3.json"
assert_eq "JR3.1 — sonde positive : un GET lance les gates, compteur 1" "$(compte "$C3")" "1"
python3 -c 'import time; time.sleep(1)'; methode "$WORK/c3b.json"
assert_eq "JR3.2 — deux GET à 1 s d'écart : toujours 1 lancement (cache de 60 s)" "$(compte "$C3")" "1"
cockpit_arreter
C3B="$WORK/c3b"; : > "$C3B"; LB3="$WORK/c3bl/lab"
srv "$LB3" VF_COCKPIT_SCRIPTS_DIR="$GATES" FAUX_COMPTE="$C3B"
cockpit_get /project.html > /dev/null
seq0="$(cockpit_get /api/vf/etat | node "$AUX/ev.mjs" - j.seq)"
seq_gt() { [ "$(cockpit_get /api/vf/etat | node "$AUX/ev.mjs" - j.seq)" -gt "$1" ] 2> /dev/null; }
for i in 1 2 3; do printf '\n- ligne %s\n' "$i" >> "$LB3/.planning/ROADMAP.md"; attendre 20 seq_gt "$((seq0 + i - 1))"; done
seq1="$(cockpit_get /api/vf/etat | node "$AUX/ev.mjs" - j.seq)"
assert_eq "JR3.3 — trois tours de collecte prouvés par la montée de seq (au moins 3) et la page chargée : compteur 0" "$([ "$((seq1 - seq0))" -ge 3 ] && echo "seq+$((seq1 - seq0))>=3" || echo "seq+$((seq1 - seq0))<3")|$(compte "$C3B")" "seq+$((seq1 - seq0))>=3|0"
cockpit_arreter
C3C="$WORK/c3c"; : > "$C3C"
srv "$WORK/c3cl/lab" VF_COCKPIT_SCRIPTS_DIR="$GATES" FAUX_COMPTE="$C3C" FAUX_DELAI=1
R="$(node "$AUX/conc.mjs" "$VF_PORT" "$VF_JETON" rafale 2)"
assert_eq "JR3.4 — deux GET simultanés (gate qui dort 1 s) : 200 chacun et 1 seul lancement" "$(printf '%s' "$R" | node "$AUX/ev.mjs" - 'j.statuts.join(",")')|$(compte "$C3C")" "200,200|1"
cockpit_arreter
mkdir -p "$WORK/m3lab"
M3="$(node "$AUX/m3.mjs" "$SCRIPTS" "$GATES" "$WORK/m3lab" 2>&1)"
assert_eq "JR3.5 — au niveau du module (horloge injectée) : aucun lancement à la création, 2 à la première lecture, toujours 2 à +1 s et +59 s, 4 à +61 s (cache de 60 s)" "$(printf '%s' "$M3" | node "$AUX/ev.mjs" - 'j.aucunALaCreation+" "+j.premier+" "+j.cache1s+" "+j.apres59s+" "+j.apres61s+" "+j.ttl')" "true 2 2 2 4 60000"
assert_eq "JR3.6 — au niveau du module : lectures simultanées partagent UNE promesse (un seul objet, deux gates lancés une fois)" "$(printf '%s' "$M3" | node "$AUX/ev.mjs" - 'j.memeObjet+" "+j.troisSimultanes')" "true 2"

# ===== JR4 — non-gel =====
echo "=== JR4 — le serveur ne gèle pas pendant un gate ==="
srv "$WORK/c4l/lab" VF_COCKPIT_SCRIPTS_DIR="$GATES" FAUX_DELAI=2
R="$(node "$AUX/conc.mjs" "$VF_PORT" "$VF_JETON" non-gel)"
assert_eq "JR4 — pendant que les gates dorment 2 s, cinq GET /api/vf/etat répondent chacun en moins de 200 ms" "$(printf '%s' "$R" | node "$AUX/ev.mjs" - 'j.etatStatuts.every(s=>s===200) && j.etatMs.every(ms=>ms<200)')" "true"
assert_eq "JR4 — sonde positive : le GET /api/vf/methode a duré au moins 2 s (le gate a bien dormi)" "$(printf '%s' "$R" | node "$AUX/ev.mjs" - 'j.methodeStatut===200 && j.methodeMs>=2000')" "true"
cockpit_arreter

# ===== JR5 — aucun chemin du poste =====
echo "=== JR5 — aucun chemin du poste dans le corps ==="
LAB5="$WORK/RACINE-MARQUEUR-77/lab"; HOME5="$WORK/home-MARQUEUR-77"; mkdir -p "$HOME5"
node "$TESTS/collecte-labo.mjs" lab "$LAB5" > /dev/null
TXT5="$(bash "$CONDUCTOR/check-method-budget.sh" --root "$LAB5" --no-remote 2>&1)"
assert_has "JR5.0 — sonde positive : la sortie TEXTE du vrai gate sur ce lab porte la racine (RACINE-MARQUEUR-77)" "$TXT5" "RACINE-MARQUEUR-77"
srv "$LAB5" VF_COCKPIT_SCRIPTS_DIR="$GATES" HOME="$HOME5"
methode "$WORK/c5.json"
C5="$(cat "$WORK/c5.json")"
assert_eq "JR5a — corps de la route (200) sans la racine du lab ni le HOME du serveur" "$VF_CODE|$([[ "$C5" == *RACINE-MARQUEUR-77* || "$C5" == *home-MARQUEUR-77* ]] && echo fuite || echo propre)" "200|propre"
cockpit_arreter
srv "$LAB5" VF_COCKPIT_SCRIPTS_DIR="$GATES" HOME="$HOME5" FAUX_MODE=abs
methode "$WORK/c5b.json"
C5B="$(cat "$WORK/c5b.json")"
assert_eq "JR5b — un faux gate qui émet un chemin absolu : la mesure est « format », son chemin null, le marqueur absent du corps" "$([[ "$C5B" == *RACINE-MARQUEUR-77* ]] && echo fuite || echo propre)|$(printf '%s' "$C5B" | node "$AUX/ev.mjs" - 'j.jauges.find(g=>g.type==="roadmap").mesures.filter(m=>m.verdict==="format" && m.chemin===null).length')" "propre|1"
cockpit_arreter
if cockpit_module_muter m-chemin vf-cockpit-jauges.mjs "s#c.startsWith('/') ||#false ||#"; then
  MUT_C="$COCKPIT_MODULE"
  srv "$LAB5" VF_COCKPIT_SCRIPTS_DIR="$GATES" HOME="$HOME5" FAUX_MODE=abs; RCM=$?
  methode "$WORK/c5m.json"; C5M="$(cat "$WORK/c5m.json")"
  assert_eq "M-CHEMIN — le rejet des chemins absolus retiré (copie du module chargée) : le marqueur sort dans le corps, JR5b rougit" "$RCM|$([[ "$C5M" == *RACINE-MARQUEUR-77* ]] && echo fuite || echo propre)" "0|fuite"
  cockpit_arreter; unset COCKPIT_MODULE
else assert_eq "M-CHEMIN — construction du mutant" "échec" "ok"; fi

# ===== JR6 — lab tiers =====
echo "=== JR6 — lab tiers ==="
srv "$WORK/c6l/lab" VF_COCKPIT_SCRIPTS_DIR="$GATES" FAUX_MODE=tiers
methode "$WORK/c6.json"
assert_eq "JR6 — jauges agent, skill, socle : « na », aucune valeur servie ni 0 ; jauges du gate de méthode mesurées (jamais « indispo »)" "$VF_CODE|$(E "$WORK/c6.json" 'j.jauges.filter(g=>["agent","skill","socle"].includes(g.type)).every(g=>g.verdict==="na" && g.mesures.every(m=>m.valeur===null)) && j.jauges.filter(g=>g.groupe!=="instructions").every(g=>g.verdict!=="indispo" && g.verdict!=="na") && j.sources.densite.etat==="non-applicable" && j.sources.methode.etat==="ok"')" "200|true"
cockpit_arreter

# ===== JR8 — copie ancienne, version inconnue, échéance =====
echo "=== JR8 — copie ancienne, version inconnue, échéance ==="
srv "$WORK/c8l/lab" VF_COCKPIT_SCRIPTS_DIR="$GATES" FAUX_MODE=64
methode "$WORK/c8a.json"
assert_eq "JR8a — faux gate qui rend 64 en --format=tsv : toutes les jauges « indispo », cause « ancien », aucune valeur" "$VF_CODE|$(E "$WORK/c8a.json" 'j.jauges.every(g=>g.verdict==="indispo" && g.cause==="ancien" && g.mesures.length===0)')" "200|true"
cockpit_arreter
srv "$WORK/c8m/lab" VF_COCKPIT_SCRIPTS_DIR="$GATES" FAUX_MODE=version
methode "$WORK/c8b.json"
assert_eq "JR8b — en-tête #vf-budget@9 : « indispo », cause « format »" "$VF_CODE|$(E "$WORK/c8b.json" 'j.jauges.every(g=>g.verdict==="indispo" && g.cause==="format")')" "200|true"
cockpit_arreter
assert_eq "JR8c — au niveau du module, lanceur injecté qui rend « délai » : « indispo », cause « delai » ; les gates reçoivent une échéance de maintenant + 10 000 ms ; un lanceur qui lève ne rejette jamais (cause « echec »)" "$(printf '%s' "$M3" | node "$AUX/ev.mjs" - 'j.delai+" "+j.fin+" "+j.echeance+" "+j.leve')" "true true 10000 true"

# ===== JR9 — le script de l'arbre observé n'est jamais lancé =====
echo "=== JR9 — script de l'arbre observé ==="
TRAP9="$WORK/trap9.sh"; printf '#!/usr/bin/env bash\ntouch "%s/EXEC-$(basename "$(dirname "$0")")"\nexit 0\n' "$WORK" > "$TRAP9"
LB9="$WORK/c9l/lab"; node "$TESTS/collecte-labo.mjs" lab "$LB9" > /dev/null; node "$SCRIPTS/vf-cockpit-build.mjs" "$LB9" --quiet > /dev/null 2>&1 # la sortie est construite AVANT les pièges
mkdir -p "$LB9/.claude/scripts" "$LB9/.vibeflow/cockpit" "$LB9/plugin/x" "$LB9/bin" "$WORK/vide9" "$WORK/home9/.claude"
for g in check-method-budget check-instruction-budget; do cp "$TRAP9" "$LB9/.claude/scripts/$g.sh"; cp "$TRAP9" "$LB9/.vibeflow/cockpit/$g.sh"; cp "$TRAP9" "$LB9/plugin/x/$g.sh"; done
ln -s "$LB9/plugin/x" "$WORK/home9/.claude/scripts"
srv "$LB9" VF_COCKPIT_SCRIPTS_DIR="$WORK/vide9" HOME="$WORK/home9"
methode "$WORK/c9a.json"
assert_eq "JR9a — scripts piégés sous <lab>/.claude/scripts, <lab>/.vibeflow/cockpit et via un HOME dont .claude/scripts est un lien vers le lab : aucun exécuté, jauges « indispo » cause « absent »" "$VF_CODE|$(ls "$WORK" | /usr/bin/grep -c '^EXEC-' || true)|$(E "$WORK/c9a.json" 'j.jauges.every(g=>g.verdict==="indispo" && g.cause==="absent")')" "200|0|true"
cockpit_arreter
mkdir -p "$WORK/module9"; for g in check-method-budget check-instruction-budget; do cp "$TRAP9" "$WORK/module9/$g.sh"; done
srv "$LB9" VF_COCKPIT_SCRIPTS_DIR="$WORK/module9" HOME="$WORK/home9"
methode "$WORK/c9b.json"
assert_eq "JR9b — sonde positive : le même piège dans un dossier de module HORS du lab est exécuté (marqueur EXEC-module9)" "$([ -e "$WORK/EXEC-module9" ] && echo exécuté || echo absent)" "exécuté"
cockpit_arreter
mkdir -p "$WORK/fauxbin9"; printf '#!/bin/bash\ntouch "%s/EXEC-bash-$(basename "$(dirname "$0")")"\nexec /bin/bash "$@"\n' "$WORK" > "$LB9/bin/bash"; cp "$LB9/bin/bash" "$WORK/fauxbin9/bash"; chmod +x "$LB9/bin/bash" "$WORK/fauxbin9/bash"
srv "$LB9" VF_COCKPIT_SCRIPTS_DIR="$GATES" HOME="$WORK/home9" PATH="$LB9/bin:$PATH"
methode "$WORK/c9c.json"
assert_eq "JR9c — faux bash sous <lab>/bin en tête du PATH du serveur : jamais exécuté, et les gates ont bien tourné (jauges mesurées)" "$([ -e "$WORK/EXEC-bash-bin" ] && echo exécuté || echo jamais)|$(E "$WORK/c9c.json" 'j.jauges[0].verdict')" "jamais|ok"
cockpit_arreter
rm -f "$WORK/EXEC-bash-bin"
srv "$LB9" VF_COCKPIT_SCRIPTS_DIR="$GATES" HOME="$WORK/home9" PATH="$WORK/fauxbin9:$PATH"
methode "$WORK/c9d.json"
assert_eq "JR9d — sonde positive : le même faux bash dans un dossier hors du lab (fauxbin9) est exécuté, puis relaie au vrai bash (jauges mesurées)" "$([ -e "$WORK/EXEC-bash-fauxbin9" ] && echo exécuté || echo absent)|$(E "$WORK/c9d.json" 'j.jauges[0].verdict')" "exécuté|ok"
cockpit_arreter
D1="$(node "$AUX/dl.mjs" "$SCRIPTS" "$WORK/module9" "$LB9" "$WORK/home9" check-method-budget.sh)"; D2="$(node "$AUX/dl.mjs" "$SCRIPTS" "$LB9/.vibeflow/cockpit" "$LB9" "$WORK/home9" check-method-budget.sh)"; D3="$(node "$AUX/dl.mjs" "$SCRIPTS" - "$LB9" "$WORK/home9" check-method-budget.sh)"; D4="$(node "$AUX/dl.mjs" "$SCRIPTS" "$WORK/module9" "$LB9" "$WORK/home9" -)"
assert_eq "JR9e — driverLockScript : l'argument « nom » est honoré (module hors lab), un dossier sous .vibeflow/ du lab et un HOME lié au lab sont refusés, le nom par défaut reste driver-lock.sh" "$D1 $D2 $D3 $D4" '{"etat":"trouve","base":"check-method-budget.sh"} {"etat":"absent","base":null} {"etat":"absent","base":null} {"etat":"absent","base":null}'

# ===== JR10c — l'enfant ne reçoit aucun GIT_* hérité =====
echo "=== JR10 — programme déclaré par le lab ==="
git init -q "$WORK/leurre" 2> /dev/null
ENV10="$WORK/env10"
srv "$WORK/c10l/lab" VF_COCKPIT_SCRIPTS_DIR="$GATES" FAUX_ENV="$ENV10" GIT_DIR="$WORK/leurre/.git" GIT_WORK_TREE="$WORK/leurre" GIT_INDEX_FILE="$WORK/leurre-index"
methode "$WORK/c10c.json"
attendre 10 test -s "$ENV10"
assert_eq "JR10c — variables GIT_* posées dans l'environnement du serveur (dont GIT_DIR vers un dépôt leurre) : le faux gate n'en voit aucune, GIT_CONFIG_COUNT est posé, et son git rev-parse désigne le dépôt du lab" "$(/usr/bin/grep -c 'leurre' "$ENV10" || true)|$(/usr/bin/grep -c '^GIT_CONFIG_COUNT=' "$ENV10" || true)|$(tail -n 1 "$ENV10")" "0|1|$WORK/c10l/lab"
cockpit_arreter
if cockpit_module_muter m-env-git vf-cockpit-methode.mjs 's#envGit(root)#process.env#'; then
  srv "$WORK/c10l/lab" VF_COCKPIT_SCRIPTS_DIR="$GATES" FAUX_ENV="$ENV10" GIT_DIR="$WORK/leurre/.git" GIT_WORK_TREE="$WORK/leurre" GIT_INDEX_FILE="$WORK/leurre-index"; RCM=$?
  rm -f "$ENV10"; methode "$WORK/c10m.json"; attendre 10 test -s "$ENV10"
  assert_eq "M-ENV-GIT — l'enfant lancé sous l'environnement du serveur (copie du module chargée) : le faux gate voit les GIT_* hérités, JR10c rougit" "$RCM|$([ "$(/usr/bin/grep -c 'leurre' "$ENV10" || true)" -gt 0 ] && echo hérité || echo propre)" "0|hérité"
  cockpit_arreter; unset COCKPIT_MODULE
else assert_eq "M-ENV-GIT — construction du mutant" "échec" "ok"; fi

vf_hyg_assert
echo "== Résultats : $PASS PASS / $FAIL FAIL =="
[ "$PASS" -gt 0 ] || { echo "garde anti-vert-à-vide : aucune assertion jouée"; exit 1; }
[ "$FAIL" -eq 0 ]
