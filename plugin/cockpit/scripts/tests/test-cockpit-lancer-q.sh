#!/usr/bin/env bash
# test-cockpit-lancer-q.sh — état de Q du lancement depuis les cartes : liste fermée, proposition unique, armement, expiration, consommation, variante chat
# (LANC-04, LANC-07, LANC-10 ; P72-D-02, D-03, D-10, D-12, D-13, D-14, D-16 ; plan 72-05). Module pur : ni navigateur, ni port, ni serveur ; l'horloge est fausse.
#   LQ1  liste fermée : sans liste, liste malformée (fail closed), liste mêlée, cibles malformées ou absentes, liste redéfinie sous une proposition armée
#   LQ2  composition : appels du gabarit (session UUID v4, champs), clés exactes de lire(), refus du gabarit, ligne refusée par validerLigne, identifiants, messages hors forme
#   LQ3  remplacement et armement (depuis le PREMIER affichage, jamais depuis la création), arme_apres_ms et expire_ms
#   LQ4  expiration (lire, consommer, rendre)
#   LQ5  consommation en deux temps (consommer, confirmer, rendre), rejeu, annulation, modes, bloquants, variante chat
#   LQ6  constantes ARME_MS et EXPIRE_MS et leur réglage de test par l'environnement (un processus par cas)
#   LQ7  pureté statique : seul import node:crypto, aucun accès disque ni réseau, aucun littéral d'alphabet, taille
#   M-*  dix-neuf mutants (copies du module, « mutant sans effet » = FAIL) : M-LISTE-OUVERTE, M-LISTE-PERIMEE, M-LISTE-LIRE, M-ENTREE-NON-VALIDEE, M-FORME-LIBRE,
#        M-COMPOSE-IGNOREE, M-LIGNE-NON-VALIDEE, M-SANS-CONFIRM-STATE, M-ARME-DEPUIS-CREATION, M-REJEU, M-EXPIRE-IGNOREE, M-MODE-LIBRE, M-REMPLACE-PAS,
#        M-RESERVATION-MULTIPLE, M-RENDRE-PERD, M-ENV-SANS-BORNE, M-CHAT-TYPE-LIBRE, M-CHAT-SANS-LIGNES, M-CHAT-LIGNE-FAUSSE
# Exit 0 si tout passe, 1 sinon.
set -uo pipefail
unset VF_COCKPIT_LANCER_ARME_MS VF_COCKPIT_LANCER_EXPIRE_MS
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
MOD="$SCRIPTS/vf-cockpit-lancer-q.mjs"; TAILLE="$SCRIPTS/../../software-architecture/scripts/check-file-size.sh"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0
court() { if [ "${#1}" -gt 300 ]; then printf '%s […] %s' "${1:0:140}" "${1: -140}"; else printf '%s' "$1"; fi; }
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$(court "$3")]"; echo "     obtenu:  [$(court "$2")]"; FAIL=$((FAIL+1)); fi; }

cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
# lq.mjs <module> : joue TOUS les cas LQ1 à LQ5 sur le module et imprime UNE ligne JSON { cas: valeur } ; module ou export absent -> {"absent":true}
cat > "$AUX/lq.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
let mod = null;
try { mod = await import(pathToFileURL(process.argv[2]).href); } catch { mod = null; }
if (!mod || typeof mod.creerEtatLancer !== 'function') { console.log('{"absent":true}'); process.exit(0); }
const MODES = ['default', 'acceptEdits', 'plan', 'herite'];
const VERBES = ['cadrer', 'planifier', 'executer', 'verifier', 'reprendre'];
const UUID4 = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;
const CHAT = '33333333-3333-4333-8333-333333333333';
const PREF = "claude --session-id '"; // la doublure porte SA copie du contrat §2
const S = (x) => (typeof x === 'string' ? x : JSON.stringify(x));
const dire = (f) => { try { return f(); } catch (e) { return '!exc:' + e.message; } };
const motif = (r) => (r && r.ok === true ? 'ok' : r && r.motif !== undefined ? r.motif : S(r));
const cles = (o) => (o && typeof o === 'object' ? Object.keys(o).sort().join(',') : String(o));
function gabarit(opt = {}) { // doublure du gabarit de 72-01 : compte ses appels, mémorise ses arguments et ce qu'elle a rendu
  const g = { appels: 0, args: [], rendus: [], MODES, VERBES };
  g.lignesParModes = (a) => {
    g.appels++; g.args.push({ ...a });
    if (opt.leve) throw new Error('gabarit');
    if (opt.refus) return { ok: false, motif: 'refus' };
    if (!/^\d+(?:\.\d+)?$/.test(a.phase) || !/^[a-z0-9][a-z0-9-]{0,39}$/.test(a.ws) || !VERBES.includes(a.verbe) || !UUID4.test(a.session)) return { ok: false, motif: 'entree' };
    const intention = `Cadre la Phase ${a.phase} du compartiment ${a.ws}`; const nom = `vf-phase-${a.phase.replace(/\./g, '-')}-${a.ws}`; const lignes = {};
    for (const m of MODES) lignes[m] = `claude --session-id '${a.session}'` + (a.chat ? ` -r '${a.chat}' --fork-session` : '') + ` -n '${nom}'` + (m !== 'herite' ? ` --permission-mode '${m}'` : '') + ` '/vf-dev ${intention}'`;
    const r = { ok: true, lignes, intention, nom }; g.rendus.push(JSON.parse(JSON.stringify(r)));
    return opt.post ? opt.post(r, a) : r;
  };
  g.validerLigne = (l) => {
    if (opt.valLeve) throw new Error('valider');
    if (typeof l !== 'string' || l.length > 400 || !l.startsWith(PREF) || !/^[A-Za-z0-9 ._:/'-]+$/.test(l) || !l.endsWith("'")) return { ok: false, motif: 'ligne' };
    return { ok: true };
  };
  return g;
}
const T0 = 1000000;
function mk(opt = {}) { let t = T0; const g = gabarit(opt); const h = { now: () => t, avance: (d) => { t += d; }, t: () => t }; return { e: mod.creerEtatLancer({ gabarit: g, maintenant: h.now }), g, h }; }
const ARME = mod.ARME_MS; const EXPIRE = mod.EXPIRE_MS;
const entree = (id, verbe, verbes, phase = '72', ws = 'alpha', kind = 'phase') => ({ id, verbe, verbes, phase, ws, kind });
const LISTE = [entree('ph-72', 'cadrer', ['cadrer', 'planifier', 'executer']), entree('ph-73', 'cadrer', ['cadrer', 'planifier']), entree('dag-m1', 'reprendre', ['reprendre'], '72', 'alpha', 'mission')];
const prop = (cible = 'ph-72', verbe = 'cadrer', x = {}) => ({ cible, verbe, bloquants: [], avertissements: [], ...x });
function pret(opt, x) { const s = mk(opt); s.e.definirCibles(LISTE); s.id = s.e.proposer(prop('ph-72', 'cadrer', x)).id; return s; }
function arme(opt, x) { const s = pret(opt, x); s.e.lire(); s.h.avance(ARME); return s; }
const C = {};
C['LQ1.1'] = () => { const { e } = mk(); return motif(e.proposer(prop())) + '|' + S(e.lire()); };
C['LQ1.2'] = () => [null, {}, 'x', 42, Array.from({ length: 501 }, () => LISTE[0])].map((b) => { const { e } = mk(); e.definirCibles(LISTE); const r = e.definirCibles(b); return S(r && r.ok) + '/' + motif(e.proposer(prop())); }).join(',');
C['LQ1.3'] = () => {
  const { e } = mk(); const ids = ['72;touch M', '$(touch M)', 'ph 74', 'k-1', 'v-1', 'v-2', 'v-3'];
  const r = e.definirCibles([LISTE[0], entree(ids[0], 'cadrer', ['cadrer']), entree(ids[1], 'cadrer', ['cadrer']), entree(ids[2], 'cadrer', ['cadrer']), entree(ids[3], 'cadrer', ['cadrer'], '72', 'alpha', 'zzz'),
    entree(ids[4], 'cadrer', []), entree(ids[5], 'cadrer', ['cadrer', 'cadrer']), entree(ids[6], 'cadrer', ['cadrer', 'detruire'])]);
  return `${r.ok},${r.retenues},${r.ecartees}|${motif(e.proposer(prop()))}|` + ids.map((i) => motif(e.proposer(prop(i)))).join(',');
};
C['LQ1.4'] = () => { const { e, g } = mk(); e.definirCibles(LISTE); const m = ['72;touch M', '$(touch M)'].map((c) => motif(e.proposer(prop(c)))).join(','); return `${m}|${S(e.lire())}|${g.appels}`; };
C['LQ1.5'] = () => { const { e } = mk(); e.definirCibles(LISTE); return [prop('ph-99'), prop('ph-72', 'verifier'), prop('dag-m1', 'cadrer')].map((p) => motif(e.proposer(p))).join(','); };
C['LQ1.6'] = () => { const { e } = mk(); e.definirCibles(LISTE); const r = e.proposer(prop()); return `${r.ok},${/^[0-9a-f]{32}$/.test(r.id)}`; };
C['LQ1.7a'] = () => { const s = pret(); s.e.lire(); s.h.avance(ARME); s.e.definirCibles([LISTE[1]]); return S(s.e.lire()); };
C['LQ1.7b'] = () => { const s = pret(); s.e.lire(); s.h.avance(ARME); s.e.definirCibles([LISTE[1]]); return motif(s.e.consommer(s.id, 'default')); };
C['LQ1.7c'] = () => { const s = arme(); return motif(s.e.consommer(s.id, 'default')); };
C['LQ2.1a'] = () => { const s = pret(); const l = s.e.lire(); const a = s.g.args[0]; return `appels=${s.g.appels};cles=${cles(a)};uuid4=${UUID4.test(a.session)};lignes=${S(l.lignes) === S(s.g.rendus[0].lignes)};modes=${Object.keys(l.lignes).join(',')}`; };
C['LQ2.1b'] = () => { const s = pret(undefined, { chat: CHAT }); const l = s.e.lire(); const [a, b] = s.g.args; return `appels=${s.g.appels};a=${cles(a)};b=${cles(b)};meme=${a.session === b.session};chatB=${b.chat === CHAT};lc=${S(l.lignes_chat) === S(s.g.rendus[1].lignes)}`; };
C['LQ2.2a'] = () => cles(pret().e.lire());
C['LQ2.2b'] = () => { const l = pret(undefined, { chat: CHAT }).e.lire(); return `${cles(l)}|chat=${l.chat}|lc=${Object.keys(l.lignes_chat).join(',')}|fuite=${S({ ...l, lignes_chat: undefined }).includes(CHAT)}`; };
C['LQ2.2d'] = () => { // LB1 PU-G-125 : Exécuter sur une phase sans plan (principal cadrer ou planifier) ajoute phase-sans-plan ; jamais pour le principal Exécuter ni pour un autre verbe
  const av = (principal, verbe, a = []) => { const s = mk(); s.e.definirCibles([entree('ph-72', principal, ['cadrer', 'planifier', 'executer', 'verifier'])]); s.e.proposer(prop('ph-72', verbe, { avertissements: a })); return S(s.e.lire().avertissements); };
  return [av('cadrer', 'executer'), av('planifier', 'executer'), av('executer', 'executer'), av('cadrer', 'planifier'), av('cadrer', 'executer', ['phase-sans-plan']), av('cadrer', 'executer', ['mission-vivante'])].join('|');
};
C['LQ2.2c'] = () => { const l = pret().e.lire(); return `etat=${l.etat};verbe=${l.verbe};phase=${l.phase};ws=${l.ws};intention=${l.intention};bloquants=${S(l.bloquants)};avertissements=${S(l.avertissements)}`; };
C['LQ2.3'] = () => [{ refus: true }, { leve: true }, { post: (r) => { delete r.lignes.plan; return r; } }, { post: (r) => { r.lignes.plan = 42; return r; } }, { post: (r) => { r.intention = 7; return r; } },
  { chat: true, post: (r, a) => { if (a.chat) r.intention += ' (autre)'; return r; } }].map((v) => { const s = mk(v); s.e.definirCibles(LISTE); const r = dire(() => s.e.proposer(prop('ph-72', 'cadrer', v.chat ? { chat: CHAT } : {}))); return motif(r) + '/' + S(dire(() => s.e.lire())); }).join(',');
const modif = (f) => ({ post: (r) => { r.lignes.plan = f(r.lignes.plan); return r; } });
C['LQ2.4a'] = () => [(b) => b.slice(0, -1) + ";'", (b) => b.slice(0, -1) + "$(x)'", (b) => b.slice(0, -1) + "`x`'", (b) => b.slice(0, -1) + "\r'", () => PREF + 'a'.repeat(401 - PREF.length - 1) + "'", (b) => 'x' + b,
  (b) => b.slice(0, -1), () => '', () => 42].map((f) => { const s = mk(modif(f)); s.e.definirCibles(LISTE); return motif(dire(() => s.e.proposer(prop()))); }).join(',');
C['LQ2.4b'] = () => { const s = mk({ valLeve: true }); s.e.definirCibles(LISTE); return motif(dire(() => s.e.proposer(prop()))); };
C['LQ2.4c'] = () => { const s = mk(modif(() => PREF + 'a'.repeat(400 - PREF.length - 1) + "'")); s.e.definirCibles(LISTE); return motif(dire(() => s.e.proposer(prop()))); };
C['LQ2.5'] = () => { const { e, g } = mk(); e.definirCibles(LISTE); const a = e.proposer(prop()); const b = e.proposer(prop()); const h = (x) => /^[0-9a-f]{32}$/.test(x.id); return `${h(a)},${h(b)};id=${a.id !== b.id};session=${g.args[0].session !== g.args[1].session}`; };
C['LQ2.6a'] = () => [{ bloquants: 'x' }, { bloquants: ['<img>'] }, { bloquants: Array.from({ length: 21 }, (_, i) => 'c' + i) }, { chat: 'x;touch M' }, { chat: '$(touch M)' }, { chat: CHAT + 'a' }, { chat: '' }, { chat: 5 },
  { chat: ['a'] }, { cible: 5 }, { avertissements: 'x' }].map((x) => { const { e } = mk(); e.definirCibles(LISTE); return motif(dire(() => e.proposer(prop('ph-72', 'cadrer', x)))); }).join(',');
C['LQ2.6b'] = () => { const { e } = mk(); e.definirCibles(LISTE); return motif(e.proposer(prop('ph-72', 'cadrer', { chat: CHAT }))); };
C['LQ2.6c'] = () => { const HEX = 'abcdefab-abcd-4bcd-8bcd-abcdefabcdef'; return [HEX.toUpperCase(), 'ABCDEFAB' + HEX.slice(8), HEX.slice(0, -1) + 'F'].map((c) => { const { e } = mk(); e.definirCibles(LISTE); return motif(e.proposer(prop('ph-72', 'cadrer', { chat: c }))); }).join(','); };
C['LQ3.1'] = () => { const { e } = mk(); e.definirCibles(LISTE); const a = e.proposer(prop()); const b = e.proposer(prop('ph-73')); const l = e.lire(); return `nouveau=${l.id === b.id};ancien=${motif(e.consommer(a.id, 'default'))}`; };
C['LQ3.2'] = () => { const s = pret(); const m = (x) => motif(s.e.consommer(s.id, 'default')); const avant = m(); s.e.lire(); const apres = m(); s.h.avance(ARME - 1); const limite = m(); s.h.avance(1); return `avant=${avant};apres=${apres};limite=${limite};arme=${m()}`; };
C['LQ3.3'] = () => { const s = pret(); s.h.avance(5000); s.e.lire(); s.h.avance(ARME - 1); const a = motif(s.e.consommer(s.id, 'default')); s.h.avance(1); return `${a},${motif(s.e.consommer(s.id, 'default'))}`; };
C['LQ3.4'] = () => { const s = pret(); const a = s.e.lire(); s.h.avance(1000); const b = s.e.lire(); return `arme=${a.arme_apres_ms === ARME};e0=${a.expire_ms === EXPIRE};e1=${b.expire_ms === EXPIRE - 1000};d=${a.duree_ms === EXPIRE && b.duree_ms === EXPIRE}`; };
C['LQ3.5'] = () => { const s = pret(); s.e.lire(); s.h.avance(ARME - 1); s.e.lire(); s.h.avance(1); return motif(s.e.consommer(s.id, 'default')); };
C['LQ4.1'] = () => {
  const a = pret(); a.e.lire(); a.h.avance(EXPIRE); const lire = S(a.e.lire()); const c1 = motif(a.e.consommer(a.id, 'default'));
  const b = pret(); b.e.lire(); b.h.avance(EXPIRE); const c2 = motif(b.e.consommer(b.id, 'default'));
  const c = arme(); c.e.consommer(c.id, 'default'); c.h.avance(EXPIRE); const r = c.e.rendre(c.id);
  return `${lire}|${c1}|${c2}|restauree=${r.restauree}|${S(c.e.lire())}`;
};
C['LQ4.2'] = () => { const s = pret(); s.e.lire(); s.h.avance(EXPIRE - 1); return motif(s.e.consommer(s.id, 'default')); };
C['LQ5.1'] = () => { const s = pret(); const l = s.e.lire(); s.h.avance(ARME); const n = s.g.appels; const r = s.e.consommer(s.id, 'plan'); return `${motif(r)};ligne=${r.ligne === l.lignes.plan};appels=${s.g.appels === n && n === 1};cible=${r.cible};verbe=${r.verbe};session=${r.session === s.g.args[0].session};cles=${cles(r)}`; };
C['LQ5.2'] = () => { const s = arme(); const c = s.e.consommer(s.id, 'plan'); s.h.avance(7); const m = s.e.confirmer(s.id); return `cles=${cles(m)};t=${m && m.t};cible=${m && m.cible};verbe=${m && m.verbe};session=${m && m.session === c.session};at=${m && m.at === s.h.t()};lire=${S(s.e.lire())}`; };
C['LQ5.3'] = () => { const s = arme(); s.e.consommer(s.id, 'plan'); s.e.confirmer(s.id); return `${motif(s.e.consommer(s.id, 'plan'))};confirmerDeNouveau=${S(s.e.confirmer(s.id))}`; };
C['LQ5.4'] = () => {
  const s = arme(); s.e.consommer(s.id, 'plan'); const rejeu = motif(s.e.consommer(s.id, 'plan'));
  const b = s.e.proposer(prop('ph-73')); s.e.lire(); s.h.avance(ARME); return `rejeu=${rejeu};seconde=${motif(s.e.consommer(b.id, 'plan'))}`;
};
C['LQ5.5a'] = () => { const s = arme(); const c1 = s.e.consommer(s.id, 'plan'); const r = s.e.rendre(s.id); const l = s.e.lire(); const c2 = s.e.consommer(s.id, 'plan'); return `restauree=${r.restauree};memeId=${l.id === s.id};memeSession=${c1.session === c2.session};ligne=${c1.ligne === c2.ligne};reconsommable=${motif(c2)}`; };
C['LQ5.5b'] = () => { const s = arme(); s.e.consommer(s.id, 'plan'); s.e.rendre(s.id); s.e.annuler(s.id); const r = s.e.rendre(s.id); return `${r.restauree};${S(s.e.lire())};${motif(s.e.consommer(s.id, 'plan'))}`; };
C['LQ5.5c'] = () => { const s = arme(); s.e.consommer(s.id, 'plan'); const b = s.e.proposer(prop('ph-73')); const r = s.e.rendre(s.id); return `${r.restauree};lireB=${s.e.lire().id === b.id}`; };
C['LQ5.6'] = () => { const s = pret(); const a = s.e.annuler(s.id); const c = motif(s.e.consommer(s.id, 'default')); const t = arme(); t.e.consommer(t.id, 'plan'); t.e.confirmer(t.id); return `${a.ok};${c};${s.e.annuler('inconnu').ok};${t.e.annuler(t.id).ok}`; };
C['LQ5.7'] = () => {
  const s = arme(); const inv = ['bypassPermissions', '__proto__', '', undefined, {}].map((m) => motif(s.e.consommer(s.id, m))).join(','); const puis = motif(s.e.consommer(s.id, 'plan')); const l = {};
  const ok = MODES.map((m) => { const t = arme(); const r = t.e.consommer(t.id, m); l[m] = r.ligne || ''; return motif(r); }).join(',');
  return `invalides=${inv};puis=${puis};valides=${ok};herite=${/--permission-mode/.test(l.herite) ? 'avec' : 'sans'};autres=${['default', 'acceptEdits', 'plan'].every((m) => l[m].includes(`--permission-mode '${m}'`)) ? 'avec' : 'sans'}`;
};
C['LQ5.8'] = () => { const s = pret(undefined, { bloquants: ['pas-de-claude'] }); const l = s.e.lire(); s.h.avance(ARME); return `${l.etat}|${S(l.bloquants)}|${motif(s.e.consommer(s.id, 'plan'))}|${s.e.lire().etat}`; };
C['LQ5.9a'] = () => { const sans = (r) => (r.ligne && !r.ligne.includes(' -r ') ? 'sans' : 'avec'); const x = arme(undefined, { chat: CHAT }); const y = arme(undefined, { chat: CHAT }); return `x=${sans(x.e.consommer(x.id, 'plan'))};y=${sans(y.e.consommer(y.id, 'plan', false))}`; };
C['LQ5.9b'] = () => { const s = pret(undefined, { chat: CHAT }); const l = s.e.lire(); s.h.avance(ARME); const r = s.e.consommer(s.id, 'plan', true); const li = r.ligne || ''; return `ligne=${li.includes(`-r '${CHAT}' --fork-session`)};session=${li.includes(r.session)};memeQueLire=${li === l.lignes_chat.plan}`; };
C['LQ5.9c'] = () => { const s = arme(undefined, { chat: CHAT }); return ['oui', 1, 0, null, {}, []].map((c) => motif(s.e.consommer(s.id, 'plan', c))).join(',') + '|puis=' + motif(s.e.consommer(s.id, 'plan', true)); };
C['LQ5.9d'] = () => { const s = arme(); return motif(s.e.consommer(s.id, 'plan', true)) + '|puis=' + motif(s.e.consommer(s.id, 'plan')); };
const out = {};
for (const k of Object.keys(C)) out[k] = (() => { try { return C[k](); } catch (e) { return 'EXC:' + e.message; } })();
console.log(JSON.stringify(out));
JS
cat > "$AUX/lq-env.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
try { const m = await import(pathToFileURL(process.argv[2]).href); console.log(`${m.ARME_MS},${m.EXPIRE_MS}`); } catch { console.log('ABSENT'); }
JS
cat > "$AUX/statique.mjs" <<'JS'
import fs from 'node:fs';
let s; try { s = fs.readFileSync(process.argv[2], 'utf8'); } catch { console.log('{"absent":true}'); process.exit(0); }
const n = (re) => (s.match(re) || []).length;
console.log(JSON.stringify({
  imports: [...s.matchAll(/\bfrom\s+['"]([^'"]+)['"]/g)].map((m) => m[1]).join(','), dyn: n(/\bimport\s*\(|\brequire\s*\(/g), console: n(/console\./g), exit: n(/process\.exit/g),
  io: n(/\b(?:readFileSync|writeFileSync|child_process|node:fs|node:http|node:net|spawn|fetch)\b/g),
  env: [...new Set([...s.matchAll(/process\.env\.([A-Za-z0-9_]+)/g)].map((m) => m[1]))].sort().join(',') + (n(/process\.env\[/g) ? '+dyn' : ''),
  alphabet: s.split('A-Za-z0-9 ._:/').length - 1, prefixe: s.split('claude --session-id').length - 1, noms: n(new RegExp('fiabil' + 'ite|gouvern' + 'ance', 'g')), // motif assemblé à l'exécution : la suite ne porte pas elle-même ces noms
}));
JS

AUC='{"etat":"aucune"}'
rep() { local s="" i; for i in $(seq 1 "$2"); do s="$s${s:+${3:-,}}$1"; done; printf '%s' "$s"; }
cas() { printf '%s' "$1" | node "$AUX/ev.mjs" "j.absent?\"ABSENT\":j[\"$2\"]"; }
attendu() { # valeur saine de chaque cas (une seule source, partagée par les sondes et les mutants)
  case "$1" in
    LQ1.1) printf 'liste-absente|%s' "$AUC" ;;
    LQ1.2) rep 'false/liste-absente' 5 ;;
    LQ1.3) printf 'true,1,7|ok|%s' "$(rep absente 7)" ;;
    LQ1.4) printf 'absente,absente|%s|0' "$AUC" ;;
    LQ1.5) rep absente 3 ;;
    LQ1.6) printf 'true,true' ;;
    LQ1.7a) printf '%s' "$AUC" ;;
    LQ1.7b) printf 'absente' ;;
    LQ1.7c) printf 'ok' ;;
    LQ2.1a) printf 'appels=1;cles=phase,session,verbe,ws;uuid4=true;lignes=true;modes=default,acceptEdits,plan,herite' ;;
    LQ2.1b) printf 'appels=2;a=phase,session,verbe,ws;b=chat,phase,session,verbe,ws;meme=true;chatB=true;lc=true' ;;
    LQ2.2a) printf 'arme_apres_ms,avertissements,bloquants,duree_ms,etat,expire_ms,id,intention,lignes,phase,verbe,ws' ;;
    LQ2.2b) printf 'arme_apres_ms,avertissements,bloquants,chat,duree_ms,etat,expire_ms,id,intention,lignes,lignes_chat,phase,verbe,ws|chat=true|lc=default,acceptEdits,plan,herite|fuite=false' ;;
    LQ2.2d) printf '["phase-sans-plan"]|["phase-sans-plan"]|[]|[]|["phase-sans-plan"]|["mission-vivante","phase-sans-plan"]' ;;
    LQ2.2c) printf 'etat=en-attente;verbe=cadrer;phase=72;ws=alpha;intention=Cadre la Phase 72 du compartiment alpha;bloquants=[];avertissements=[]' ;;
    LQ2.3) rep "compose/$AUC" 6 ;;
    LQ2.4a) rep compose 9 ;;
    LQ2.4b) printf 'compose' ;;
    LQ2.4c) printf 'ok' ;;
    LQ2.5) printf 'true,true;id=true;session=true' ;;
    LQ2.6a) rep forme 11 ;;
    LQ2.6b) printf 'ok' ;;
    LQ2.6c) rep forme 3 ;;
    LQ3.1) printf 'nouveau=true;ancien=remplacee' ;;
    LQ3.2) printf 'avant=pas-arme;apres=pas-arme;limite=pas-arme;arme=ok' ;;
    LQ3.3) printf 'pas-arme,ok' ;;
    LQ3.4) printf 'arme=true;e0=true;e1=true;d=true' ;;
    LQ3.5) printf 'ok' ;;
    LQ4.1) printf '%s|expiree|expiree|restauree=false|%s' "$AUC" "$AUC" ;;
    LQ4.2) printf 'ok' ;;
    LQ5.1) printf 'ok;ligne=true;appels=true;cible=ph-72;verbe=cadrer;session=true;cles=cible,ligne,ok,session,verbe' ;;
    LQ5.2) printf 'cles=at,cible,session,t,verbe;t=lancee;cible=ph-72;verbe=cadrer;session=true;at=true;lire=%s' "$AUC" ;;
    LQ5.3) printf 'consommee;confirmerDeNouveau=null' ;;
    LQ5.4) printf 'rejeu=consommee;seconde=occupee' ;;
    LQ5.5a) printf 'restauree=true;memeId=true;memeSession=true;ligne=true;reconsommable=ok' ;;
    LQ5.5b) printf 'false;%s;annulee' "$AUC" ;;
    LQ5.5c) printf 'false;lireB=true' ;;
    LQ5.6) printf 'true;annulee;false;false' ;;
    LQ5.7) printf 'invalides=mode,mode,mode,mode,mode;puis=ok;valides=ok,ok,ok,ok;herite=sans;autres=avec' ;;
    LQ5.8) printf 'en-attente|["pas-de-claude"]|bloquee|en-attente' ;;
    LQ5.9a) printf 'x=sans;y=sans' ;;
    LQ5.9b) printf 'ligne=true;session=true;memeQueLire=true' ;;
    LQ5.9c) printf 'chat,chat,chat,chat,chat,chat|puis=ok' ;;
    LQ5.9d) printf 'chat|puis=ok' ;;
  esac
}
HJ="$(node "$AUX/lq.mjs" "$MOD")"
chk() { assert_eq "$1 — $2" "$(cas "$HJ" "$1")" "$(attendu "$1")"; }

echo "── LQ1 liste fermée (LANC-04 ; P72-D-12) ──"
chk LQ1.1 "sans liste : proposer refusé (liste-absente), lire() aucune"
chk LQ1.2 "liste malformée (null, {}, 'x', 42, 501 entrées) : refusée ET la liste précédente est écartée (fail closed)"
chk LQ1.3 "liste mêlée : 1 retenue, 7 écartées (id à ;, \$(, espace, kind inconnu, verbes vide, doublon, verbe inconnu), seule la bonne est proposable"
chk LQ1.4 "cibles '72;touch M' et '\$(touch M)' : absente, lire() aucune, le gabarit appelé 0 fois"
chk LQ1.5 "ph-99 (bien formée, absente), verbe hors des verbes de l'entrée, verbe d'une autre entrée : absente"
chk LQ1.6 "ph-72/cadrer valide : {ok:true, id}"
chk LQ1.7a "proposition armée puis liste redéfinie sans la cible : lire() aucune"
chk LQ1.7b "idem : consommer -> absente (seule la revérification de la liste peut refuser une proposition armée)"
chk LQ1.7c "témoin : sans redéfinir la liste, la même proposition armée est consommable"

echo "── LQ2 composition (P72-D-13) ──"
chk LQ2.1a "sans chat : UN appel du gabarit, champs session,verbe,phase,ws seuls (pas de clé chat), session UUID v4, lignes = celles du gabarit"
chk LQ2.1b "avec chat : DEUX appels, le premier SANS clé chat, le second AVEC, la MÊME session, lignes_chat = celles du second appel"
chk LQ2.2a "sans chat : lire() expose exactement les douze clés du contrat §4 (dont duree_ms, la durée de vie totale servie : référence d'âge du client de Q, lot 8 LB3)"
chk LQ2.2b "avec chat : les douze clés plus chat (true) et lignes_chat (quatre clés) ; l'UUID du chat absent de tout le reste"
chk LQ2.2d "Exécuter sur une phase sans plan (principal cadrer ou planifier) : avertissement phase-sans-plan ajouté une fois ; aucun pour le principal Exécuter ni pour un autre verbe (LB1, PU-G-125)"
chk LQ2.2c "valeurs de lire() : état, verbe, phase, ws, intention du gabarit, bloquants, avertissements"
chk LQ2.3 "gabarit qui refuse, lève, rend des lignes incomplètes, une ligne non chaîne, une intention non chaîne ou divergente : compose, rien en attente"
chk LQ2.4a "validerLigne refuse (;, \$(, accent grave, retour chariot, 401 caractères, hors préfixe, sans apostrophe finale, vide, non chaîne) : compose"
chk LQ2.4b "validerLigne qui lève : compose"
chk LQ2.4c "ligne de 400 caractères conforme : acceptée"
chk LQ2.5 "identifiant de 32 hexadécimaux, différent à chaque proposition ; session différente à chaque proposition"
chk LQ2.6a "message hors forme (bloquants non tableau, code <img>, 21 codes, chat ;, \$(, 37 caractères, vide, 5, tableau, cible non chaîne, avertissements non tableau) : forme"
chk LQ2.6b "un chat UUID valide est accepté"
chk LQ2.6c "un chat aux majuscules (tout, un segment, un seul chiffre hexadécimal) : forme — même forme que le gabarit, minuscules 8-4-4-4-12"

echo "── LQ3 remplacement, armement (LANC-07 ; P72-D-10, D-14) ──"
chk LQ3.1 "une seconde proposition remplace la première : nouvel id, l'ancien est refusé (remplacee)"
chk LQ3.2 "pas-arme avant tout lire(), juste après le premier lire(), à ARME_MS-1 ; ok à ARME_MS"
chk LQ3.3 "armement depuis le premier affichage (jamais depuis la création) : créée à t0, lue à t0+5000, refusée à +ARME_MS-1, acceptée à +ARME_MS"
chk LQ3.4 "arme_apres_ms = ARME_MS, expire_ms = durée de vie restante (décroît avec l'horloge), duree_ms = durée totale (constante)"
chk LQ3.5 "un second lire() ne repousse pas l'armement"

echo "── LQ4 expiration (P72-D-10) ──"
chk LQ4.1 "à EXPIRE_MS : lire() aucune, consommer expiree (avec ou sans lire() entre), rendre d'une réservation expirée ne restaure rien"
chk LQ4.2 "à EXPIRE_MS-1 : encore consommable (armée)"

echo "── LQ5 consommation en deux temps (LANC-10 ; P72-D-02, D-16) ──"
chk LQ5.1 "consommer rend {ok, ligne, session, cible, verbe}, ligne identique à lire().lignes[mode], gabarit non rappelé"
chk LQ5.2 "confirmer rend {t:'lancee', cible, verbe, session, at} (at = horloge fausse), lire() aucune"
chk LQ5.3 "rejeu après confirmation : consommee ; confirmer d'une proposition déjà confirmée : null"
chk LQ5.4 "rejeu pendant la réservation refusé (consommee) ; seconde proposition consommée pendant une réservation : occupee"
chk LQ5.5a "rendre après écriture refusée : même id, même session, même ligne, de nouveau consommable"
chk LQ5.5b "rendre après annulation ne ressuscite rien"
chk LQ5.5c "rendre après remplacement ne ressuscite rien"
chk LQ5.6 "annuler -> ok puis consommer annulee ; annuler(inconnu) et annuler après usage : ok false"
chk LQ5.7 "mode bypassPermissions, __proto__, '', undefined, objet : mode (sans consommer) ; quatre modes valides ; herite sans --permission-mode"
chk LQ5.8 "bloquants non vide : consommer bloquee, lire() montre toujours la proposition avec ses bloquants"
chk LQ5.9a "chat absent ou false sur une proposition à chat : la ligne standard (sans -r)"
chk LQ5.9b "chat true : lignes_chat[mode] (-r '<chat>' --fork-session, même session)"
chk LQ5.9c "chat valant 'oui', 1, 0, null, {}, [] : chat (sans consommer)"
chk LQ5.9d "chat true sur une proposition SANS chat : chat (aucune ligne inventée)"

echo "── LQ6 constantes (P72-D-14) ──"
envval() { local m="$1"; shift; env "$@" node "$AUX/lq-env.mjs" "$m"; }
env63() { # env63 <module> : dix cas, séparés par « ; » ; la variable posée vide l'est vraiment
  local m="$1" v o=""
  for v in 0 99 10001 -5 1.5 abc ''; do o="$o$(envval "$m" "VF_COCKPIT_LANCER_ARME_MS=$v");"; done
  for v in 999 600001; do o="$o$(envval "$m" "VF_COCKPIT_LANCER_EXPIRE_MS=$v");"; done
  o="$o$(envval "$m" VF_COCKPIT_LANCER_ARME_MS=5000 VF_COCKPIT_LANCER_EXPIRE_MS=3000)"; printf '%s' "$o"
}
assert_eq "LQ6.1 — défauts : ARME_MS = 1000, EXPIRE_MS = 120000" "$(envval "$MOD" X=1)" "1000,120000"
assert_eq "LQ6.2 — VF_COCKPIT_LANCER_ARME_MS=5000 -> 5000 (l'environnement RALLONGE le délai d'armement)" "$(envval "$MOD" VF_COCKPIT_LANCER_ARME_MS=5000)" "5000,120000"
assert_eq "LQ6.2 — VF_COCKPIT_LANCER_EXPIRE_MS=5000 -> 5000" "$(envval "$MOD" VF_COCKPIT_LANCER_EXPIRE_MS=5000)" "1000,5000"
env64() { local v o=""; for v in 100 250 999 1000 1001; do o="$o$(envval "$1" "VF_COCKPIT_LANCER_ARME_MS=$v");"; done; printf '%s' "$o"; }
E64ATT="1000,120000;1000,120000;1000,120000;1000,120000;1001,120000;"
assert_eq "LQ6.4 — l'environnement ne peut jamais abaisser l'armement sous la valeur de production : 100, 250, 999 -> 1000 ; 1000 -> 1000 ; 1001 -> 1001 (témoin : il rallonge)" "$(env64 "$MOD")" "$E64ATT"
E63ATT="$(rep '1000,120000' 10 ';')"
assert_eq "LQ6.3 — valeurs hors bornes, non entières ou vides (0, 99, 10001, -5, 1.5, abc, ''; 999, 600001; EXPIRE <= ARME) : les défauts" "$(env63 "$MOD")" "$E63ATT"

echo "── LQ7 pureté statique ──"
ST="$(node "$AUX/statique.mjs" "$MOD")"
assert_eq "LQ7.1 — le seul import du module est node:crypto, aucun import dynamique" "$(printf '%s' "$ST" | node "$AUX/ev.mjs" 'j.absent?"ABSENT":"imports="+j.imports+";dyn="+j.dyn')" "imports=node:crypto;dyn=0"
assert_eq "LQ7.2 — aucun console., process.exit, accès disque ni réseau ; deux clés d'environnement ; aucun littéral d'alphabet ni de préfixe de ligne ; aucun nom de compartiment" \
  "$(printf '%s' "$ST" | node "$AUX/ev.mjs" 'j.absent?"ABSENT":"console="+j.console+";exit="+j.exit+";io="+j.io+";env="+j.env+";alphabet="+j.alphabet+";prefixe="+j.prefixe+";noms="+j.noms')" \
  "console=0;exit=0;io=0;env=VF_COCKPIT_LANCER_ARME_MS,VF_COCKPIT_LANCER_EXPIRE_MS;alphabet=0;prefixe=0;noms=0"
# témoin : check-file-size.sh rend 0 pour un fichier absent, donc l'existence du module est constatée à part (jamais un vert à vide)
TREC=absent; [ -f "$MOD" ] && { bash "$TAILLE" "$MOD" > "$WORK/taille.out" 2>&1; TREC=$?; }
assert_eq "LQ7.3 — le module existe et check-file-size.sh rend exit 0 (sous 300 lignes)" "$TREC" "0"

echo "── Mutants (copies du module ; « mutant sans effet » = FAIL) ──"
mutj() { # mutj <nom> <expression-sed> -> MUT, MUTJ ; code 1 si la cible manque ou si la copie n'a pas changé
  local d="$WORK/mut-$1"; rm -rf "$d"; mkdir -p "$d"; MUT="$d/vf-cockpit-lancer-q.mjs"; MUTJ=""
  [ -f "$MOD" ] || return 1
  cp "$MOD" "$MUT"; cp "$MUT" "$MUT.orig"; sed -i.bak "$2" "$MUT"; local r=0; cmp -s "$MUT" "$MUT.orig" && r=1; rm -f "$MUT.orig" "$MUT.bak"
  [ "$r" = 0 ] && MUTJ="$(node "$AUX/lq.mjs" "$MUT")"; return $r
}
sans_effet() { assert_eq "$1 — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; }
mutrouge() { # mutrouge <NOM> <libellé> <cas>... : rouge = un cas diverge du sain ; témoin = le scénario s'exécute (ni module absent, ni exception de cas)
  local nom="$1" lib="$2" r=false t=true k o; shift 2
  for k in "$@"; do o="$(cas "$MUTJ" "$k")"; [ "$o" = "$(attendu "$k")" ] || r=true; case "$o" in EXC:*|ABSENT) t=false ;; esac; done
  assert_eq "$nom — $lib (témoin : le scénario s'exécute, aucune exception de cas)" "rouge=$r temoin=$t" "rouge=true temoin=true"
}
mut() { # mut <NOM> <expression-sed> <libellé> <cas>...
  local nom="$1" ex="$2" lib="$3"; shift 3
  if mutj "$nom" "$ex"; then mutrouge "$nom" "le mutant rougit $*: $lib" "$@"; else sans_effet "$nom"; fi
}
mut M-LISTE-OUVERTE '/garde:liste-proposer/d' "une cible hors liste produit une ligne" LQ1.4 LQ1.5
mut M-LISTE-PERIMEE '/garde:liste-consommer/d' "consommer ne revérifie plus la liste courante" LQ1.7b
mut M-LISTE-LIRE '/garde:liste-lire/d' "lire() montre une proposition dont la cible a quitté la liste" LQ1.7a
mut M-ENTREE-NON-VALIDEE '/garde:entree-forme/d' "une entrée hors forme entre dans la liste" LQ1.3
mut M-UUID-MAJUSCULES '/^const UUID_RE/s/0-9a-f/0-9a-fA-F/g' "le motif d'UUID de Q accepte les majuscules que le gabarit refuse" LQ2.6c
mut M-FORME-LIBRE '/garde:forme/d' "un message hors forme est accepté" LQ2.6a
mut M-COMPOSE-IGNOREE '/garde:compose/d' "un refus ou une composition incomplète du gabarit est ignoré" LQ2.3
mut M-LIGNE-NON-VALIDEE '/garde:alphabet/d' "une ligne que validerLigne refuse est retenue" LQ2.4a
mut M-SANS-CONFIRM-STATE '/garde:arme/d' "consommer ne refuse plus avant l'armement" LQ3.2
mut M-ARME-DEPUIS-CREATION '/garde:vue-null/s/vue_a: null/vue_a: maintenant()/' "l'armement part de la création" LQ3.3
mut M-REJEU '/garde:usage-unique/d' "la proposition consommée reste rejouable" LQ5.3
mut M-EXPIRE-IGNOREE '/garde:expire/d' "la proposition n'expire plus" LQ4.1
mut M-MODE-LIBRE '/garde:mode/d' "un mode hors liste est accepté" LQ5.7
mut M-REMPLACE-PAS '/garde:remplace/s/attente = nouvelle;/if (!attente) attente = nouvelle;/' "la seconde proposition ne remplace plus la première" LQ3.1
mut M-RESERVATION-MULTIPLE '/garde:occupee/d' "deux réservations à la fois" LQ5.4
mut M-RENDRE-PERD '/garde:rendre/d' "rendre ne remet plus la proposition en attente" LQ5.5a LQ5.5b
if mutj M-ENV-SANS-BORNE '/garde:env-bornes/s/n >= min && n <= max/true/'; then
  assert_eq "M-ENV-SANS-BORNE — le mutant rougit LQ6.3 : une valeur hors bornes est retenue" "$([ "$(env63 "$MUT")" = "$E63ATT" ] && echo 'rouge=false' || echo 'rouge=true') temoin=$(envval "$MUT" VF_COCKPIT_LANCER_ARME_MS=5000 | grep -q '^5000,' && echo true || echo false)" "rouge=true temoin=true"
else sans_effet M-ENV-SANS-BORNE; fi
if mutj M-ARME-ABAISSABLE '/garde:plancher/s/Math.max(ARME_DEF,/Math.max(0,/'; then
  assert_eq "M-ARME-ABAISSABLE — le mutant rougit LQ6.4 : l'environnement abaisse l'armement sous la valeur de production" "$([ "$(env64 "$MUT")" = "$E64ATT" ] && echo 'rouge=false' || echo 'rouge=true') temoin=$(envval "$MUT" VF_COCKPIT_LANCER_ARME_MS=5000 | grep -q '^5000,' && echo true || echo false)" "rouge=true temoin=true"
else sans_effet M-ARME-ABAISSABLE; fi
mut M-CHAT-TYPE-LIBRE '/garde:chat-type/d' "un chat qui n'est pas un booléen est accepté" LQ5.9c
mut M-CHAT-SANS-LIGNES '/garde:chat-absent/d' "chat true est accepté sans lignes de reprise" LQ5.9d
mut M-CHAT-LIGNE-FAUSSE '/garde:chat-ligne/s/chat === true ?/attente.lignes_chat ?/' "la ligne de reprise est choisie sans le booléen" LQ5.9a

vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
