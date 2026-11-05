#!/usr/bin/env bash
# test-cockpit-lancer-gabarit.sh — gabarit de la ligne lancée depuis une carte du cockpit (LANC-05, LANC-09 liste des modes ; P72-D-02, D-02bis, D-03, D-13, D-15, D-19).
#   G0  le module se charge, exporte exactement l'interface        G1  vingt lignes (5 verbes x 4 modes) égales à des littéraux écrits ici ; `herite` sans drapeau
#   G2  lab plat (ws null), phase décimale                         G3  intentions : alphabet, ASCII, jamais `gsd`
#   G4  table de refus à code fermé, jamais de ligne ni de valeur corrigée
#   G5  propriété : 20 000 entrées (graine 72) contre l'oracle de la suite ; couverture ; points de code 0 à 0x2FF ; chaînes de 5 Mo ; constantes normatives
#   G6  validerLigne s'accorde avec l'oracle de grammaire sur toute substitution, insertion, suppression d'un caractère
#   G7  lab fixture hostile lu par la VRAIE buildProjectGraph          G8  les lignes, évaluées par de VRAIS shells (sh, bash, zsh), donnent l'argv exact et aucun marqueur
#   G9  variante chat `-r '<uuid>' --fork-session`                    G10 lignesParModes        G11 listes gelées, modes de la CLI hors liste jamais émis
#   G12 nom du skill : installation réelle de dev-orchestrator dans un lab jetable                G13 environnement du shell sans CLAUDECODE ni CLAUDE_CODE_*
#   G14 module pur : moins de 300 lignes, aucune dépendance, aucun accès système (comptage par awk)
#   M-* douze mutants (copies sous $WORK/mut-<nom>/, jamais le module) : M-INTERPOLE, M-MOTIF-WS, M-MOTIF-PHASE, M-NETTOIE, M-ALPHABET-LARGE, M-MODE-BYPASS, M-HERITE-FLAG,
#       M-SANS-GUILLEMETS, M-CHAT-IGNORE, M-SESSION-LIBRE, M-SKILL-PREFIXE, M-ENV-CLAUDE-CODE
# Un mutant sans effet (ancre absente, ou groupes attendus non rougis) est un FAIL. Aucun processus n'est lancé en arrière-plan, aucun port n'est ouvert.
# Exit 0 si tout passe, 1 sinon. Compatible bash 3.2 (macOS) et bash 5 (Linux).
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
PLUGIN="$(cd "$SCRIPTS/../.." && pwd)"
GAB="$SCRIPTS/vf-cockpit-lancer-gabarit.mjs"; ENVM="$SCRIPTS/vf-cockpit-terminal-env.mjs"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$(court "$3")]"; echo "     obtenu:  [$(court "$2")]"; FAIL=$((FAIL+1)); fi; }
court() { if [ "${#1}" -gt 300 ]; then printf '%s […] %s' "${1:0:140}" "${1: -140}"; else printf '%s' "$1"; fi; }

# ---------- oracle : les littéraux de la SUITE, indépendants du module ----------
cat > "$AUX/oracle.mjs" <<'JS'
// oracle.mjs : motifs, listes, alphabet, grammaire entière de la ligne et constructeur de ligne attendue, écrits ici et nulle part ailleurs (P72-D-13)
export const MOT = { phase: /^\d+(?:\.\d+)?$/, ws: /^[a-z0-9][a-z0-9-]{0,39}$/, v4: /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/, uuid: /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/ };
export const VERBES = ['cadrer', 'planifier', 'executer', 'verifier', 'reprendre'];
export const MODES = ['default', 'acceptEdits', 'plan', 'herite'];
export const IMP = { cadrer: 'Cadre', planifier: 'Planifie', executer: 'Execute', verifier: 'Verifie', reprendre: 'Reprends' };
export const ALPHA_CLASSE = "[A-Za-z0-9 ._:/'-]";
export const ALPHA = /^[A-Za-z0-9 ._:/'-]+$/;
export const SKILL = 'vf-dev';
export const REFUS = ['phase', 'compartiment', 'verbe', 'mode', 'session', 'chat', 'forme'];
const str = (x) => typeof x === 'string';
export function decide(e) {
  const { session, verbe, mode, phase, ws, chat } = e;
  if (!(str(phase) && phase.length <= 16 && MOT.phase.test(phase))) return { ok: false, motif: 'phase' };
  if (!(ws === null || (str(ws) && ws.length <= 40 && MOT.ws.test(ws)))) return { ok: false, motif: 'compartiment' };
  if (!VERBES.includes(verbe)) return { ok: false, motif: 'verbe' };
  if (!MODES.includes(mode)) return { ok: false, motif: 'mode' };
  if (!(str(session) && session.length <= 36 && MOT.v4.test(session))) return { ok: false, motif: 'session' };
  if (!(chat === undefined || chat === null || (str(chat) && chat.length <= 36 && MOT.uuid.test(chat)))) return { ok: false, motif: 'chat' };
  const intention = `${IMP[verbe]} la Phase ${phase}` + (ws === null ? '' : ` du compartiment ${ws}`);
  const nom = 'vf-phase-' + phase.replace('.', '-') + (ws === null ? '' : '-' + ws);
  const ligne = `claude --session-id '${session}'` + (chat ? ` -r '${chat}' --fork-session` : '') + ` -n '${nom}'` + (mode === 'herite' ? '' : ` --permission-mode '${mode}'`) + ` '/${SKILL} ${intention}'`;
  return { ok: true, ligne, intention, nom };
}
export const argvDe = (e, d) => ['--session-id', e.session, ...(e.chat ? ['-r', e.chat, '--fork-session'] : []), '-n', d.nom, ...(e.mode === 'herite' ? [] : ['--permission-mode', e.mode]), `/${SKILL} ${d.intention}`];
const WS = '[a-z0-9][a-z0-9-]{0,39}', V4 = '[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}', UU = '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}';
const GRAMMAIRE = new RegExp("^claude --session-id '" + V4 + "'(?: -r '" + UU + "' --fork-session)? -n 'vf-phase-\\d+(?:-\\d+)?(?:-" + WS + ")?'(?: --permission-mode '(?:default|acceptEdits|plan)')? '/vf-dev (?:Cadre|Planifie|Execute|Verifie|Reprends) la Phase \\d+(?:\\.\\d+)?(?: du compartiment " + WS + ")?'$");
export function valider(l) {
  if (!str(l)) return { ok: false, motif: 'type' };
  if (l.length === 0 || l.length > 400) return { ok: false, motif: 'longueur' };
  if (!ALPHA.test(l)) return { ok: false, motif: 'alphabet' };
  if (!GRAMMAIRE.test(l)) return { ok: false, motif: 'forme' };
  return { ok: true };
}
JS

# ---------- mutants : copies, jamais le module ----------
cat > "$AUX/mut.mjs" <<'JS'
// mut.mjs <nom> <gabarit> <env> <dest> : écrit sous <dest> la copie mutée ; code 3 = ancre absente ou mutation sans effet
import fs from 'node:fs';
const [, , nom, srcG, srcE, dest] = process.argv; fs.mkdirSync(dest, { recursive: true });
const KO = (m) => { console.log('ancre absente ou sans effet : ' + m); process.exit(3); };
let g = fs.existsSync(srcG) ? fs.readFileSync(srcG, 'utf8') : null; const g0 = g;
const constante = (n, rempl) => { if (g === null) KO('module absent'); const re = new RegExp('^export const ' + n + ' = .*$', 'm'); if (!re.test(g)) KO('export const ' + n); g = g.replace(re, () => rempl); };
const enveloppe = (f, corps) => { if (g === null) KO('module absent'); const re = new RegExp('^export function ' + f + '\\(', 'm'); if (!re.test(g)) KO('export function ' + f); g = g.replace(re, () => 'export function ' + f + '_orig(') + '\n' + corps + '\n'; };
const COMPOSER = 'export function composerLigne(e) { ';
const M = {
  'M-INTERPOLE': () => enveloppe('composerLigne', COMPOSER + "const r = composerLigne_orig(e); if (r.ok && e && typeof e.titre === 'string') { r.intention += ' ' + e.titre; r.ligne = r.ligne.replace(/'$/, ' ' + e.titre + \"'\"); } return r; }"),
  'M-MOTIF-WS': () => constante('MOTIF_COMPARTIMENT', 'export const MOTIF_COMPARTIMENT = /^.{1,40}$/s;'),
  'M-MOTIF-PHASE': () => constante('MOTIF_PHASE', 'export const MOTIF_PHASE = /^\\d/;'),
  'M-NETTOIE': () => enveloppe('composerLigne', COMPOSER + "let r = composerLigne_orig(e); if (!r.ok && (r.motif === 'phase' || r.motif === 'compartiment')) r = composerLigne_orig({ ...e, phase: typeof e.phase === 'string' ? e.phase.replace(/[^0-9.]/g, '') : e.phase, ws: typeof e.ws === 'string' ? e.ws.replace(/[^a-z0-9-]/g, '') : e.ws }); return r; }"),
  'M-ALPHABET-LARGE': () => constante('ALPHABET', 'export const ALPHABET = /^[ -~]+$/;'),
  'M-MODE-BYPASS': () => constante('MODES', "export const MODES = Object.freeze(['default', 'acceptEdits', 'plan', 'herite', 'bypassPermissions']);"),
  'M-HERITE-FLAG': () => enveloppe('composerLigne', COMPOSER + "return composerLigne_orig(e && e.mode === 'herite' ? { ...e, mode: 'default' } : e); }"),
  'M-SANS-GUILLEMETS': () => enveloppe('composerLigne', COMPOSER + "const r = composerLigne_orig(e); if (r.ok) r.ligne = r.ligne.replace(/'/g, ''); return r; }"),
  'M-CHAT-IGNORE': () => enveloppe('composerLigne', COMPOSER + "const r = composerLigne_orig(e); return !r.ok && r.motif === 'chat' ? composerLigne_orig({ ...e, chat: null }) : r; }"),
  'M-SESSION-LIBRE': () => constante('MOTIF_UUID_V4', 'export const MOTIF_UUID_V4 = /^.+$/;'),
  'M-SKILL-PREFIXE': () => constante('NOM_SKILL', "export const NOM_SKILL = 'vibeflow:vf-dev';"),
};
if (nom === 'M-ENV-CLAUDE-CODE') {
  const e0 = fs.readFileSync(srcE, 'utf8'); const e1 = e0.replace(" || k.startsWith('CLAUDE_CODE_')", ''); if (e1 === e0) KO('startsWith CLAUDE_CODE_');
  fs.writeFileSync(dest + '/vf-cockpit-terminal-env.mjs', e1);
} else {
  if (!M[nom]) KO('mutant inconnu ' + nom); M[nom](); if (g === g0) KO('aucun changement');
  fs.writeFileSync(dest + '/vf-cockpit-lancer-gabarit.mjs', g);
}
JS

# ---------- lab fixture hostile (G7) ----------
cat > "$AUX/mklab.mjs" <<'JS'
// mklab.mjs <lab1> <lab2> : lab 1 partitionné (fiabilite, gouvernance sains ; a$(id) hostile) ; lab 2 : un seul compartiment `Fiabilite` (la casse le distingue de `fiabilite` seulement sur un système de fichiers sensible à la casse : d'où deux labs)
import fs from 'node:fs'; import path from 'node:path'; import { execFileSync } from 'node:child_process';
const [, , lab1, lab2] = process.argv;
const roadmap = (titres) => '## Phases\n\n' + titres.map(([n, t]) => `- [ ] Phase ${n}: ${t}`).join('\n') + '\n\n' + titres.map(([n, t]) => `### Phase ${n}: ${t}\n**Goal:** ${t} — but de la phase ${n}.\n`).join('\n');
const comp = (lab, ws, titres) => { const d = path.join(lab, '.planning', 'workstreams', ws); fs.mkdirSync(d, { recursive: true }); fs.writeFileSync(path.join(d, 'ROADMAP.md'), roadmap(titres)); fs.writeFileSync(path.join(d, 'STATE.md'), '---\ncurrent_phase: 1\nstatus: executing\n---\n'); };
for (const lab of [lab1, lab2]) { fs.mkdirSync(lab, { recursive: true }); execFileSync('git', ['init', '-q', lab]); }
comp(lab1, 'fiabilite', [[1, 'Sain'], [2, '"; touch M #'], [3, '<img src=x onerror=alert(1)>'], [4, '$(touch M)'], [5, "'x'; touch M; '"]]);
comp(lab1, 'gouvernance', [[1, 'Sain aussi'], [2, 'Autre']]);
comp(lab1, 'a$(id)', [[1, 'Dans un compartiment hostile']]);
comp(lab2, 'Fiabilite', [[1, 'Majuscule']]);
JS

# ---------- sondes : toutes les assertions G0 à G13 sur un module donné (le vrai, ou un mutant) ----------
cat > "$AUX/sondes.mjs" <<'JS'
// sondes.mjs <gabarit> <env> <lab1> <lab2> <install> <rc-install> <plugin> <shells> <travail> : une ligne `PROBE<TAB>id<TAB>PASS|FAIL<TAB>libellé<TAB>détail` par sonde
import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url'; import { spawnSync } from 'node:child_process';
import * as O from './oracle.mjs';
const [, , GAB, ENVM, LAB1, LAB2, INST, INSTRC, PLUGIN, SHELLS, WORKD] = process.argv;
let M = null, merr = ''; try { M = await import(pathToFileURL(GAB).href); } catch (e) { merr = String((e && e.message) || e).split('\n')[0]; }
const need = () => { if (!M) throw new Error('module absent : ' + merr); return M; };
async function P(id, libelle, fn) {
  let r; try { r = await fn(); } catch (e) { r = 'exception : ' + String((e && e.message) || e).split('\n')[0]; }
  console.log(['PROBE', id, r === true ? 'PASS' : 'FAIL', libelle, r === true ? '' : String(r).replace(/[\t\n\r]/g, ' ').slice(0, 420)].join('\t'));
}
const J = (x) => JSON.stringify(x);
const norm = (r) => J(Object.keys(r || {}).sort().map((k) => [k, r[k]])); // égalité stricte, clés supplémentaires comprises
const S1 = '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d', C1 = '11111111-2222-3333-4444-555555555555';
const base = (o = {}) => ({ session: S1, verbe: 'cadrer', mode: 'default', phase: '72', ws: 'fiabilite', ...o });
const EXTRAS = { titre: '"; touch M #ZZTITRE', goal: '$(touch M)ZZGOAL', nom: 'ZZNOMZZ', mission: 'ZZMISSIONZZ', details: '<img src=x onerror=alert(1)>ZZDETAILS', label: '`id`ZZLABEL' };
const CHAMPS = { phase: 'phase', ws: 'compartiment', verbe: 'verbe', mode: 'mode', session: 'session', chat: 'chat' };
const EXPORTS = ['NOM_SKILL', 'MOTIF_PHASE', 'MOTIF_COMPARTIMENT', 'MOTIF_UUID_V4', 'MOTIF_UUID', 'VERBES', 'MODES', 'ALPHABET', 'ALPHABET_CLASSE', 'LIGNE_MAX', 'PREFIXE_LIGNE', 'MOTIFS_REFUS', 'intentionDe', 'nomSession', 'composerLigne', 'lignesParModes', 'validerLigne'];

// G1 : vingt littéraux écrits en dur (jamais calculés)
const G1T = [
  ['cadrer', 'default', "claude --session-id '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d' -n 'vf-phase-72-fiabilite' --permission-mode 'default' '/vf-dev Cadre la Phase 72 du compartiment fiabilite'"],
  ['cadrer', 'acceptEdits', "claude --session-id '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d' -n 'vf-phase-72-fiabilite' --permission-mode 'acceptEdits' '/vf-dev Cadre la Phase 72 du compartiment fiabilite'"],
  ['cadrer', 'plan', "claude --session-id '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d' -n 'vf-phase-72-fiabilite' --permission-mode 'plan' '/vf-dev Cadre la Phase 72 du compartiment fiabilite'"],
  ['cadrer', 'herite', "claude --session-id '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d' -n 'vf-phase-72-fiabilite' '/vf-dev Cadre la Phase 72 du compartiment fiabilite'"],
  ['planifier', 'default', "claude --session-id '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d' -n 'vf-phase-72-fiabilite' --permission-mode 'default' '/vf-dev Planifie la Phase 72 du compartiment fiabilite'"],
  ['planifier', 'acceptEdits', "claude --session-id '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d' -n 'vf-phase-72-fiabilite' --permission-mode 'acceptEdits' '/vf-dev Planifie la Phase 72 du compartiment fiabilite'"],
  ['planifier', 'plan', "claude --session-id '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d' -n 'vf-phase-72-fiabilite' --permission-mode 'plan' '/vf-dev Planifie la Phase 72 du compartiment fiabilite'"],
  ['planifier', 'herite', "claude --session-id '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d' -n 'vf-phase-72-fiabilite' '/vf-dev Planifie la Phase 72 du compartiment fiabilite'"],
  ['executer', 'default', "claude --session-id '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d' -n 'vf-phase-72-fiabilite' --permission-mode 'default' '/vf-dev Execute la Phase 72 du compartiment fiabilite'"],
  ['executer', 'acceptEdits', "claude --session-id '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d' -n 'vf-phase-72-fiabilite' --permission-mode 'acceptEdits' '/vf-dev Execute la Phase 72 du compartiment fiabilite'"],
  ['executer', 'plan', "claude --session-id '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d' -n 'vf-phase-72-fiabilite' --permission-mode 'plan' '/vf-dev Execute la Phase 72 du compartiment fiabilite'"],
  ['executer', 'herite', "claude --session-id '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d' -n 'vf-phase-72-fiabilite' '/vf-dev Execute la Phase 72 du compartiment fiabilite'"],
  ['verifier', 'default', "claude --session-id '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d' -n 'vf-phase-72-fiabilite' --permission-mode 'default' '/vf-dev Verifie la Phase 72 du compartiment fiabilite'"],
  ['verifier', 'acceptEdits', "claude --session-id '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d' -n 'vf-phase-72-fiabilite' --permission-mode 'acceptEdits' '/vf-dev Verifie la Phase 72 du compartiment fiabilite'"],
  ['verifier', 'plan', "claude --session-id '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d' -n 'vf-phase-72-fiabilite' --permission-mode 'plan' '/vf-dev Verifie la Phase 72 du compartiment fiabilite'"],
  ['verifier', 'herite', "claude --session-id '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d' -n 'vf-phase-72-fiabilite' '/vf-dev Verifie la Phase 72 du compartiment fiabilite'"],
  ['reprendre', 'default', "claude --session-id '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d' -n 'vf-phase-72-fiabilite' --permission-mode 'default' '/vf-dev Reprends la Phase 72 du compartiment fiabilite'"],
  ['reprendre', 'acceptEdits', "claude --session-id '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d' -n 'vf-phase-72-fiabilite' --permission-mode 'acceptEdits' '/vf-dev Reprends la Phase 72 du compartiment fiabilite'"],
  ['reprendre', 'plan', "claude --session-id '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d' -n 'vf-phase-72-fiabilite' --permission-mode 'plan' '/vf-dev Reprends la Phase 72 du compartiment fiabilite'"],
  ['reprendre', 'herite', "claude --session-id '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d' -n 'vf-phase-72-fiabilite' '/vf-dev Reprends la Phase 72 du compartiment fiabilite'"],
];

// corpus hostile fixe (G4, G5) : métacaractères de shell, guillemets, retours, NUL, tirets, chemins, Unicode trompeur, types non chaîne
const H = ['', ' ', '  ', ';', '&', '&&', '|', '||', '$', '$(id)', '$(touch M)', '${IFS}', '`id`', '`touch M`', '(', ')', '{', '}', '[', ']', '<', '>', '>>', '<<', '*', '?', '!', '#', '~', '\\', '\\n',
  '"', "'", '"; touch M #', "'; touch M; '", "'x'; touch M; '", 'a"b', "a'b", '\n', '\r', '\r\n', 'a\nb', 'a\rb', '\t', 'a\tb', '\0', 'a\0b', '-', '--', '-x', '--help', '-r', '--fork-session', '- x', '../x', '../../etc/passwd', '..', '.', '/', '/etc/passwd', '~/x', 'a/../b',
  ' ', ' ', 'a b', '‪', '‫', '‬', '‭', '‮', 'a‮b', '​', 'a​b', '﻿', 'a﻿b', '；', '＄', '72；', '７２', 'é', 'Ç', '日本', '😀', 'a😀', '١٢',
  'x'.repeat(70), '1'.repeat(70), '9'.repeat(17), '<img src=x onerror=alert(1)>', '<script>alert(1)</script>', 'null', 'undefined', 'true', 'NaN', 'Infinity', '0x10', '1e3', '1_0', '+1', '-1', '1.', '.1', '.5', '1.2.3', '1..2', '1,2', ' 72', '72 ', '72\n', '\n72', '72;touch M',
  'Fiabilite', 'FIABILITE', 'a_b', 'a b', 'a.b', 'a:b', '-a', 'a$(id)', 'a;b', 'a`b', 'a|b', 'a&b', 'a>b', 'a<b', 'a(b', 'a)b', 'a*b', 'a?b', 'a#b', 'a~b', 'a!b', 'a\\b',
  'Default', 'PLAN', 'bypassPermissions', 'auto', 'dontAsk', 'manual', 'acceptedits', 'cadrer ', 'Cadrer', 'cadre', 'executer;', 'GSD', 'gsd-execute-phase', 'herite ',
  '00000000-0000-0000-0000-000000000000', '0A1B2C3D-4E5F-4A6B-8C7D-9E0F1A2B3C4D', '0a1b2c3d-4e5f-1a6b-8c7d-9e0f1a2b3c4d', '0a1b2c3d-4e5f-4a6b-7c7d-9e0f1a2b3c4d', '0a1b2c3d4e5f4a6b8c7d9e0f1a2b3c4d', '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4', '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d0', "0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d'",
  72, 7.2, true, false, null, undefined, [], ['cadrer'], {}, { toString: () => 'cadrer' }];

// générateur déterministe (graine 72)
function mulberry32(a) { return function () { a |= 0; a = (a + 0x6D2B79F5) | 0; let t = Math.imul(a ^ (a >>> 15), 1 | a); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }
const rnd = mulberry32(72); const pick = (a) => a[Math.floor(rnd() * a.length)];
const hex = (n) => Array.from({ length: n }, () => '0123456789abcdef'[Math.floor(rnd() * 16)]).join('');
const v4 = () => `${hex(8)}-${hex(4)}-4${hex(3)}-${'89ab'[Math.floor(rnd() * 4)]}${hex(3)}-${hex(12)}`;
const uu = () => `${hex(8)}-${hex(4)}-${hex(4)}-${hex(4)}-${hex(12)}`;
const VALIDE = { phase: () => pick(['72', '1', '71.5', '0', '100.25', '3', '007', '12.0']), ws: () => pick([null, 'fiabilite', 'gouvernance', 'a', 'a-b-c', '0', '9x', 'abc-', 'z' + 'y'.repeat(39)]), verbe: () => pick(O.VERBES), mode: () => pick(O.MODES), session: v4, chat: () => pick([undefined, null, uu(), uu()]) };
const JETONS = H.filter((x) => typeof x === 'string' && x.length < 8);
const insere = (v) => { if (typeof v !== 'string') return pick(JETONS); const t = pick(JETONS), p = pick(['tete', 'milieu', 'queue']); const i = p === 'tete' ? 0 : p === 'queue' ? v.length : v.length >> 1; return v.slice(0, i) + t + v.slice(i); };
const ENTREES = [];
for (let i = 0; i < 20000; i++) {
  const e = {};
  for (const f of Object.keys(CHAMPS)) { const v = VALIDE[f](), r = rnd(); e[f] = r < 0.78 ? v : r < 0.89 ? pick(H) : insere(v); }
  ENTREES.push({ ...e, ...EXTRAS });
}

// ----- G0 -----
await P('G0.1', 'le module se charge', () => (M ? true : 'module absent : ' + merr));
await P('G0.2', 'toutes les exportations nommées existent', () => { const m = need(); const manque = EXPORTS.filter((n) => !(n in m)); return manque.length === 0 || 'manquent : ' + manque.join(','); });
await P('G0.3', "le module n'exporte rien d'autre que l'interface", () => { const m = need(); const en_trop = Object.keys(m).filter((n) => !EXPORTS.includes(n)); return en_trop.length === 0 || 'en trop : ' + en_trop.join(','); });

// ----- G1 -----
await P('G1.1', 'vingt lignes (cinq verbes x quatre modes) égales octet pour octet à des littéraux', () => {
  const m = need(); if (G1T.length !== 20) return 'table de littéraux incomplète';
  for (const [verbe, mode, attendu] of G1T) { const r = m.composerLigne(base({ verbe, mode })); if (!r || r.ok !== true || r.ligne !== attendu) return `${verbe}/${mode} : obtenu ${J(r)} attendu ${attendu}`; }
  return true;
});
await P('G1.2', 'herite : aucun --permission-mode ; les autres modes en portent exactement un', () => {
  const m = need(); let n = 0;
  for (const verbe of O.VERBES) for (const mode of O.MODES) {
    const l = m.composerLigne(base({ verbe, mode })).ligne; const c = l.split('--permission-mode').length - 1; n++;
    if (mode === 'herite' ? c !== 0 : (c !== 1 || !l.includes(`--permission-mode '${mode}' `))) return `${verbe}/${mode} : ${c} drapeau(x) dans ${l}`;
  }
  return n === 20 || 'couverture ' + n;
});

// ----- G2 -----
await P('G2.1', 'lab plat (ws null) : intention sans compartiment, nom vf-phase-<n>', () => {
  const m = need(); const r = m.composerLigne(base({ ws: null }));
  return (r.ok === true && r.intention === 'Cadre la Phase 72' && r.nom === 'vf-phase-72' && r.ligne.endsWith(" -n 'vf-phase-72' --permission-mode 'default' '/vf-dev Cadre la Phase 72'") && m.intentionDe('verifier', '72', null) === 'Verifie la Phase 72' && m.nomSession('72', null) === 'vf-phase-72') || J(r);
});
await P('G2.2', 'phase décimale 71.5 : vf-phase-71-5-<ws>', () => {
  const m = need(); const r = m.composerLigne(base({ phase: '71.5', verbe: 'planifier' }));
  return (r.ok === true && r.nom === 'vf-phase-71-5-fiabilite' && r.intention === 'Planifie la Phase 71.5 du compartiment fiabilite' && m.nomSession('71.5', 'gouvernance') === 'vf-phase-71-5-gouvernance' && m.nomSession('72;x', 'a') === null && m.nomSession('72', undefined) === null && m.intentionDe('cadrer', '72', undefined) === null && m.intentionDe('cadre', '72', null) === null) || J(r);
});

// ----- G3 -----
await P('G3.1', "chaque intention dans l'alphabet, ASCII, sans apostrophe ni accent, égale à l'impératif attendu", () => {
  const m = need(); let n = 0;
  for (const v of O.VERBES) for (const ws of [null, 'fiabilite']) for (const ph of ['72', '71.5']) {
    const i = m.intentionDe(v, ph, ws); const att = `${O.IMP[v]} la Phase ${ph}` + (ws === null ? '' : ` du compartiment ${ws}`); n++;
    if (i !== att || !O.ALPHA.test(i) || i.includes("'") || !/^[\x20-\x7e]+$/.test(i)) return `${v}/${ph}/${ws} : ${J(i)} attendu ${att}`;
  }
  return n === 20 || 'couverture ' + n;
});
await P('G3.2', 'aucune intention ne contient gsd', () => {
  const m = need(); let n = 0; for (const v of O.VERBES) { const i = m.intentionDe(v, '72', 'fiabilite'); n++; if (typeof i !== 'string' || /gsd/i.test(i)) return `${v} : ${J(i)}`; } return n === 5 || 'couverture ' + n;
});

// ----- G4 -----
const REFUSES = [];
for (const p of ['72;touch M', '$(touch M)', '1e3', '72.', '.5', ' 72', '', '72\n', 72, null, undefined]) REFUSES.push([{ phase: p }, 'phase']);
for (const w of ['a$(id)', 'Fiabilite', '-x', 'a b', 'a'.repeat(41), '', undefined, '../x', 'a;b', 'é', 'a\nb', 7]) REFUSES.push([{ ws: w }, 'compartiment']);
for (const v of ['cadre', 'GSD', 'executer;', 'Cadrer', '', null, undefined, 'gsd-execute-phase']) REFUSES.push([{ verbe: v }, 'verbe']);
for (const mo of ['bypassPermissions', 'auto', 'dontAsk', 'manual', 'Default', '', null, undefined, 'plan ']) REFUSES.push([{ mode: mo }, 'mode']);
for (const s of ['0a1b2c3d-4e5f-1a6b-8c7d-9e0f1a2b3c4d', '0A1B2C3D-4E5F-4A6B-8C7D-9E0F1A2B3C4D', '0a1b2c3d-4e5f-4a6b', '', 'x', "0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d'", null, undefined, 42]) REFUSES.push([{ session: s }, 'session']);
for (const c of ['ABCDEF12-2222-3333-4444-555555555555', 'x', '11111111-2222-3333-4444-55555555555', '', "11111111-2222-3333-4444-555555555555'; touch M", 7, true, {}]) REFUSES.push([{ chat: c }, 'chat']);
REFUSES.push([{ phase: ';', mode: 'auto' }, 'phase'], [{ ws: '$', verbe: 'x' }, 'compartiment'], [{ verbe: 'x', mode: 'x', session: 'x' }, 'verbe'], [{ mode: 'x', session: 'x', chat: 'x' }, 'mode'], [{ session: 'x', chat: 'x' }, 'session']);
await P('G4.1', 'table de refus : toujours ok:false avec le code attendu, jamais une ligne, jamais une valeur corrigée', () => {
  const m = need(); let n = 0;
  for (const [o, code] of REFUSES) { const r = m.composerLigne(base(o)); n++; if (!r || r.ok !== false || r.motif !== code || 'ligne' in r || 'intention' in r || 'nom' in r || Object.keys(r).length !== 2) return `${J(o)} : obtenu ${J(r)} attendu motif ${code}`; }
  const rl = m.lignesParModes({ session: S1, verbe: 'cadrer', phase: '72;x', ws: 'fiabilite' }); if (rl.ok !== false || rl.motif !== 'phase' || 'lignes' in rl) return 'lignesParModes : ' + J(rl);
  return n >= 60 || 'couverture ' + n;
});

// ----- G5 -----
console.error('G5 : graine 72, 20000 entrées');
let acceptees = 0, refusees = 0;
await P('G5.1', '20 000 entrées hostiles : même décision, même ligne, même clés que l\'oracle ; alphabet, 400 au plus, aucun champ supplémentaire, validerLigne ok', () => {
  const m = need(); let mal = 0, premier = '';
  for (const e of ENTREES) {
    const r = m.composerLigne(e), d = O.decide(e);
    let bon = norm(r) === norm(d);
    if (bon && d.ok) {
      const l = r.ligne;
      bon = O.ALPHA.test(l) && l.length <= 400 && !l.includes('ZZ') && !r.intention.includes('ZZ') && !r.nom.includes('ZZ') && m.validerLigne(l).ok === true && m.validerLigne(l + ';').motif === 'alphabet' && (e.chat ? true : !/ -r | --fork-session/.test(l));
    }
    if (!bon) { mal++; if (!premier) premier = J({ e: { ...e, ...Object.fromEntries(Object.keys(EXTRAS).map((k) => [k, undefined])) }, obtenu: r, attendu: d }); }
    if (r && r.ok === true) acceptees++; else refusees++;
  }
  return mal === 0 || `${mal} écart(s) ; premier : ${premier}`;
});
await P('G5.2', 'couverture : au moins 1 000 lignes acceptées et 1 000 refus', () => { need(); return (acceptees >= 1000 && refusees >= 1000) || `acceptées ${acceptees}, refus ${refusees}`; });
await P('G5.3', 'énumération des points de code 0 à 0x2FF et seize points choisis, en tête, au milieu et en queue de chaque champ : même décision que l\'oracle', () => {
  const m = need(); const pts = []; for (let c = 0; c <= 0x2FF; c++) pts.push(c);
  pts.push(0x2028, 0x2029, 0x202A, 0x202B, 0x202C, 0x202D, 0x202E, 0x200B, 0xFEFF, 0xFF1B, 0xFF04, 0x1F600, 0x1F4A9, 0xFFFF, 0x10FFFF, 0xD7FF);
  const b = base({ mode: 'plan', chat: C1 }); let n = 0;
  for (const c of pts) for (const f of Object.keys(CHAMPS)) for (const pos of [0, 1, 2]) {
    const ch = String.fromCodePoint(c), v = b[f], i = pos === 0 ? 0 : pos === 1 ? v.length >> 1 : v.length; const e = { ...b, [f]: v.slice(0, i) + ch + v.slice(i) };
    const r = m.composerLigne(e), d = O.decide(e); n++;
    if (norm(r) !== norm(d)) return `U+${c.toString(16)} dans ${f}@${pos} : obtenu ${J(r)} attendu ${J(d)}`;
  }
  return n > 14000 || 'couverture ' + n;
});
await P('G5.4', 'trois chaînes de 5 Mo par champ : refus à code fermé, sans lenteur', () => {
  const m = need(); const grosses = ['a'.repeat(5e6), '1'.repeat(5e6), '-a'.repeat(2.5e6)]; const t0 = performance.now(); let n = 0;
  for (const f of Object.keys(CHAMPS)) for (const s of grosses) { const r = m.composerLigne({ ...base({ mode: 'plan' }), [f]: s }); n++; if (!r || r.ok !== false || r.motif !== CHAMPS[f]) return `${f} : obtenu ${J(r && { ok: r.ok, motif: r.motif })} attendu ${CHAMPS[f]}`; }
  const dt = performance.now() - t0; return (n === 18 && dt < 3000) || `${n} cas en ${Math.round(dt)} ms`;
});
await P('G5.5', "constantes normatives : motifs phase et compartiment, alphabet, longueur, préfixe, codes de refus égaux aux littéraux de la suite", () => {
  const m = need();
  const att = { MOTIF_PHASE: O.MOT.phase.source, MOTIF_COMPARTIMENT: O.MOT.ws.source, ALPHABET: O.ALPHA.source, ALPHABET_CLASSE: O.ALPHA_CLASSE, LIGNE_MAX: 400, PREFIXE_LIGNE: "claude --session-id '" };
  for (const k of Object.keys(att)) { const v = m[k] instanceof RegExp ? m[k].source : m[k]; if (v !== att[k]) return `${k} : obtenu ${J(v)} attendu ${J(att[k])}`; }
  return J([...m.MOTIFS_REFUS]) === J(O.REFUS) || 'MOTIFS_REFUS : ' + J(m.MOTIFS_REFUS);
});

// ----- G6 -----
await P('G6.1', "validerLigne s'accorde avec l'oracle de grammaire sur toute substitution, insertion et suppression d'un caractère (corpus de 40) dans 30 lignes valides", () => {
  const m = need(); const ws = [null, 'fiabilite', 'gouvernance', 'a', 'x-y-1'], ph = ['72', '1', '71.5', '100', '0.5', '3'];
  const corpus = [';', '$', '`', '(', ')', '"', '<', '>', '|', '&', '\\', '!', '*', '?', '#', '~', '\n', '\r', '\t', '\0', 'é', ' ', '‮', '​', '；', "'", ' ', '-', '.', '/', ':', 'a', 'Z', '0', '9', '4', '_', '8', 'b', 'd'];
  if (corpus.length !== 40) return 'corpus de ' + corpus.length;
  const lignes = [];
  for (let i = 0; i < 30; i++) {
    const e = base({ verbe: O.VERBES[i % 5], mode: O.MODES[i % 4], phase: ph[i % 6], ws: ws[(i * 3 + 1) % 5], session: i % 2 ? '9f8e7d6c-5b4a-4c3d-9e2f-1a0b9c8d7e6f' : S1, chat: i % 3 === 0 ? C1 : undefined });
    const r = m.composerLigne(e), d = O.decide(e); if (norm(r) !== norm(d)) return `ligne de base ${i} : obtenu ${J(r)} attendu ${J(d)}`; lignes.push(d.ligne);
  }
  const comp = (x) => { const a = m.validerLigne(x), b = O.valider(x); return a && a.ok === b.ok && a.motif === b.motif ? null : `${J(x)} : obtenu ${J(a)} attendu ${J(b)}`; };
  let n = 0, mal = null;
  for (const x of ['', 'x'.repeat(401), null, undefined, 42, [], {}, "claude --session-id '"]) { n++; mal = mal || comp(x); }
  for (const l of lignes) {
    mal = mal || comp(l); n++;
    for (let i = 0; i <= l.length && !mal; i++) {
      if (i < l.length) { mal = comp(l.slice(0, i) + l.slice(i + 1)); n++; }
      for (const c of corpus) { if (mal) break; mal = comp(l.slice(0, i) + c + l.slice(i)); n++; if (i < l.length && !mal) { mal = comp(l.slice(0, i) + c + l.slice(i + 1)); n++; } }
    }
    if (mal) break;
  }
  return mal === null && n > 400000 ? true : mal || 'couverture ' + n;
});

// ----- G7 : lab hostile lu par la vraie chaîne -----
const { buildProjectGraph } = await import(pathToFileURL(path.join(PLUGIN, 'cockpit/scripts/vf-cockpit-project.mjs')).href);
const cartes = (lab) => buildProjectGraph(lab).nodes.filter((n) => n.kind === 'phase');
const C_LAB1 = cartes(LAB1), C_LAB2 = cartes(LAB2);
await P('G7.0', 'témoin : les libellés des cartes du lab fixture portent bien touch M et onerror', () => {
  const l = C_LAB1.map((c) => c.label).join('\n');
  return (l.includes('touch M') && l.includes('onerror') && C_LAB1.some((c) => c.label.includes('$(touch M)')) && C_LAB1.some((c) => c.ws === 'a$(id)') && C_LAB2.some((c) => c.ws === 'Fiabilite') && C_LAB1.filter((c) => c.id.includes('@')).length >= 4) || 'lab non hostile : ' + J(C_LAB1.map((c) => [c.id, c.ws, c.label]));
});
const extrasCarte = (c) => ({ titre: c.label, goal: c.summary, details: c.details, label: c.label, nom: c.label, mission: c.label });
const saines = C_LAB1.filter((c) => c.ws === 'fiabilite' || c.ws === 'gouvernance');
const entreesCartes = saines.map((c, i) => ({ session: S1, verbe: O.VERBES[i % 5], mode: 'plan', phase: c.num, ws: c.ws, ...extrasCarte(c) }));
await P('G7.1', 'cartes de compartiments sains : ligne égale à l\'oracle malgré titre, goal, details hostiles passés en champs supplémentaires', () => {
  const m = need(); if (saines.length < 7) return 'cartes saines : ' + saines.length;
  for (const e of entreesCartes) { const r = m.composerLigne(e), d = O.decide(e); if (norm(r) !== norm(d) || !d.ok || /touch|onerror|img/.test(r.ligne)) return `${e.phase}@${e.ws} : obtenu ${J(r)} attendu ${J(d)}`; }
  return true;
});
await P('G7.2', 'compartiments a$(id) et Fiabilite : refusés, code compartiment', () => {
  const m = need(); const h = [...C_LAB1.filter((c) => c.ws === 'a$(id)'), ...C_LAB2.filter((c) => c.ws === 'Fiabilite')]; if (h.length < 2) return 'cartes hostiles : ' + h.length;
  for (const c of h) { const r = m.composerLigne({ session: S1, verbe: 'cadrer', mode: 'plan', phase: c.num, ws: c.ws, ...extrasCarte(c) }); if (!r || r.ok !== false || r.motif !== 'compartiment' || 'ligne' in r) return `${c.ws} : ${J(r)}`; }
  return true;
});

// ----- G8 : de vrais shells -----
const SHS = SHELLS.split(',').filter(Boolean); const FLAGS = { sh: [], bash: ['--noprofile', '--norc'], zsh: ['-f'] };
function lancer(sh, ligne, cwd, sortie) {
  fs.rmSync(sortie, { force: true }); fs.rmSync(path.join(cwd, 'M'), { force: true });
  spawnSync(sh, [...FLAGS[sh], '-c', `claude() { for a in "$@"; do printf '%s\\0' "$a"; done > "$OUT"; }; ${ligne}`], { cwd, env: { PATH: process.env.PATH, OUT: sortie }, stdio: 'ignore' });
  let brut = null; try { brut = fs.readFileSync(sortie, 'utf8'); } catch {}
  const marqueur = fs.existsSync(path.join(cwd, 'M')); fs.rmSync(path.join(cwd, 'M'), { force: true });
  return { argv: brut === null ? null : brut.split('\0').slice(0, -1), marqueur };
}
const cwdDe = (sh) => { const d = path.join(WORKD, 'sh-' + sh); fs.mkdirSync(d, { recursive: true }); return d; };
await P('G8.0', "témoin : une ligne injectée volontairement crée le marqueur dans chaque shell (sinon la sonde est aveugle)", () => {
  if (!SHS.length) return 'aucun shell présent'; console.error('G8 : shells exercés : ' + SHS.join(' '));
  for (const sh of SHS) { const r = lancer(sh, "claude -n 'a'; touch M; echo 'b'", cwdDe(sh), path.join(WORKD, 'argv-' + sh)); if (!r.marqueur) return `${sh} : marqueur absent, sonde aveugle`; }
  return true;
});
await P('G8.1', "lignes acceptées (cartes du lab hostile + 40 lignes générées) évaluées par chaque shell présent : argv exact de l'oracle, aucun marqueur", () => {
  const m = need(); if (!SHS.length) return 'aucun shell présent';
  const gen = ENTREES.filter((e) => O.decide(e).ok).slice(0, 40); const toutes = [...entreesCartes, ...gen]; let n = 0;
  if (gen.length !== 40) return 'lignes générées : ' + gen.length;
  for (const sh of SHS) for (const e of toutes) {
    const d = O.decide(e), r = m.composerLigne(e); n++;
    if (!r || r.ok !== true) return `${sh} : refus inattendu ${J(r)}`;
    const x = lancer(sh, r.ligne, cwdDe(sh), path.join(WORKD, 'argv-' + sh));
    if (x.marqueur) return `${sh} : marqueur créé par ${r.ligne}`;
    if (J(x.argv) !== J(O.argvDe(e, d))) return `${sh} : argv ${J(x.argv)} attendu ${J(O.argvDe(e, d))} pour ${r.ligne}`;
  }
  return n === SHS.length * toutes.length || 'couverture ' + n;
});

// ----- G9 -----
await P('G9.1', 'variante chat composée et valide', () => {
  const m = need(); let n = 0;
  for (const mode of O.MODES) { const e = base({ mode, chat: C1 }), r = m.composerLigne(e), d = O.decide(e); n++; if (norm(r) !== norm(d) || !r.ligne.includes(` -r '${C1}' --fork-session -n `) || !O.ALPHA.test(r.ligne) || m.validerLigne(r.ligne).ok !== true) return `${mode} : ${J(r)} attendu ${J(d)}`; }
  return n === 4 || 'couverture ' + n;
});
await P('G9.2', 'sans chat (absent, null, undefined) : jamais -r ni --fork-session', () => {
  const m = need(); for (const o of [{}, { chat: null }, { chat: undefined }]) { const r = m.composerLigne(base(o)); if (!r.ok || / -r |--fork-session/.test(r.ligne)) return `${J(o)} : ${J(r)}`; } return true;
});
await P('G9.3', 'chat hors motif : refus chat, jamais écarté en silence', () => {
  const m = need(); for (const c of ['x', 'ABCDEF12-2222-3333-4444-555555555555', '11111111-2222-3333-4444-55555555555', '', 7, "11111111-2222-3333-4444-555555555555'"]) { const r = m.composerLigne(base({ chat: c })); if (r.ok !== false || r.motif !== 'chat') return `${J(c)} : ${J(r)}`; } return true;
});

// ----- G10 -----
await P('G10.1', 'lignesParModes : quatre lignes égales à composerLigne par mode', () => {
  const m = need(); const e = { session: S1, verbe: 'reprendre', phase: '72', ws: 'fiabilite', chat: C1 }; const r = m.lignesParModes(e);
  if (!r || r.ok !== true || J(Object.keys(r.lignes)) !== J(O.MODES) || r.intention !== 'Reprends la Phase 72 du compartiment fiabilite' || r.nom !== 'vf-phase-72-fiabilite') return J(r);
  for (const mode of O.MODES) { const c = m.composerLigne({ ...e, mode }), d = O.decide({ ...e, mode }); if (r.lignes[mode] !== c.ligne || r.lignes[mode] !== d.ligne) return `${mode} : ${r.lignes[mode]}`; }
  return true;
});
await P('G10.2', 'lignesParModes propage le premier refus', () => {
  const m = need(); const e = { session: S1, verbe: 'cadrer', phase: '72', ws: 'fiabilite' };
  for (const [o, code] of [[{ phase: '7;2' }, 'phase'], [{ ws: 'A' }, 'compartiment'], [{ verbe: 'x' }, 'verbe'], [{ session: 'x' }, 'session'], [{ chat: 'x' }, 'chat']]) { const r = m.lignesParModes({ ...e, ...o }); if (!r || r.ok !== false || r.motif !== code || 'lignes' in r) return `${J(o)} : ${J(r)}`; }
  return true;
});

// ----- G11 -----
await P('G11.1', 'VERBES et MODES exactement les listes du contrat, gelées', () => {
  const m = need(); return (J([...m.VERBES]) === J(O.VERBES) && J([...m.MODES]) === J(O.MODES) && Object.isFrozen(m.VERBES) && Object.isFrozen(m.MODES)) || J([m.VERBES, m.MODES, Object.isFrozen(m.VERBES), Object.isFrozen(m.MODES)]);
});
await P('G11.2', 'balayage des six modes de la CLI : seuls acceptEdits et plan passent (plus default et herite) ; aucun autre mode jamais émis', () => {
  const m = need();
  for (const mode of ['acceptEdits', 'auto', 'bypassPermissions', 'manual', 'dontAsk', 'plan', 'default', 'herite']) {
    const r = m.composerLigne(base({ mode })), voulu = ['acceptEdits', 'plan', 'default', 'herite'].includes(mode);
    if (voulu !== (r.ok === true)) return `${mode} : ${J(r)}`;
    if (r.ok && /'(auto|manual|dontAsk|bypassPermissions)'/.test(r.ligne)) return `mode interdit dans ${r.ligne}`;
  }
  return true;
});

// ----- G12 -----
const NAME = (f) => { try { return (/^name:\s*(\S+)\s*$/m.exec(fs.readFileSync(f, 'utf8').split('\n---')[0]) || [])[1] || null; } catch { return null; } };
await P('G12.1', 'NOM_SKILL égale vf-dev', () => (need().NOM_SKILL === 'vf-dev') || J(M.NOM_SKILL));
await P('G12.2', 'témoin : le name: de plugin/dev-orchestrator/skills/vf-dev/SKILL.md égale vf-dev', () => NAME(path.join(PLUGIN, 'dev-orchestrator/skills/vf-dev/SKILL.md')) === 'vf-dev' || J(NAME(path.join(PLUGIN, 'dev-orchestrator/skills/vf-dev/SKILL.md'))));
await P('G12.3', "après installation réelle, .claude/skills/<NOM_SKILL>/SKILL.md existe et son name: égale NOM_SKILL", () => {
  const m = need(); const f = path.join(INST, '.claude/skills', m.NOM_SKILL, 'SKILL.md'); return (INSTRC === '0' && fs.existsSync(f) && NAME(f) === m.NOM_SKILL) || `installation rc=${INSTRC}, ${f} : ${fs.existsSync(f) ? 'name ' + NAME(f) : 'absent'}`;
});
await P('G12.4', "témoin : l'installation réelle pose .claude/skills/vf-dev/SKILL.md", () => (INSTRC === '0' && NAME(path.join(INST, '.claude/skills/vf-dev/SKILL.md')) === 'vf-dev') || `installation rc=${INSTRC}`);
await P('G12.5', 'plugin/.claude-plugin/plugin.json n\'expose que ./installer', () => { const j = JSON.parse(fs.readFileSync(path.join(PLUGIN, '.claude-plugin/plugin.json'), 'utf8')); return j.skills === './installer' || J(j.skills); });

// ----- G13 -----
const E = await import(pathToFileURL(ENVM).href);
const BRUT = { PATH: process.env.PATH, HOME: process.env.HOME || '/tmp', CLAUDECODE: '1', CLAUDE_CODE_ENTRYPOINT: 'cli', CLAUDE_CODE_SSE_PORT: '1234', CLAUDE_CODE_SESSION: 'x', CLAUDE_CODE_FOO: 'y', CLAUDE_CODE_BAR: 'z', AUTRE: 'ok' };
const envEnfant = (env) => { const r = spawnSync('/bin/sh', ['-c', 'env'], { env, encoding: 'utf8' }); return r.status === 0 ? r.stdout.split('\n') : null; };
await P('G13.0', 'témoin : un enfant lancé avec l\'environnement brut voit au moins trois variables CLAUDE_CODE_*', () => { const l = envEnfant(BRUT); return (l && l.filter((x) => x.startsWith('CLAUDE_CODE_')).length >= 3 && l.includes('CLAUDECODE=1')) || J(l && l.length); });
await P('G13.1', 'envShell ne laisse passer ni CLAUDECODE ni CLAUDE_CODE_* et garde PATH, HOME', () => {
  const f = E.envShell(BRUT, []); const k = Object.keys(f).filter((x) => x === 'CLAUDECODE' || x.startsWith('CLAUDE_CODE_'));
  return (k.length === 0 && f.PATH === BRUT.PATH && f.HOME === BRUT.HOME && f.AUTRE === 'ok') || J({ k, PATH: f.PATH === BRUT.PATH, HOME: f.HOME === BRUT.HOME });
});
await P('G13.2', "un vrai processus enfant lancé avec envShell(...) n'en voit aucune", () => { const l = envEnfant(E.envShell(BRUT, [])); return (l && l.some((x) => x.startsWith('HOME=')) && !l.some((x) => x.startsWith('CLAUDE_CODE_') || x.startsWith('CLAUDECODE='))) || J(l && l.filter((x) => /CLAUDE/.test(x))); });
JS

# ---------- préparation : lab hostile, installation réelle de dev-orchestrator, shells présents ----------
node "$AUX/mklab.mjs" "$WORK/lab1" "$WORK/lab2" > "$WORK/mklab.out" 2>&1 || { echo "  ❌ FAIL — préparation du lab fixture"; cat "$WORK/mklab.out"; FAIL=$((FAIL+1)); }
mkdir -p "$WORK/cache" "$WORK/instlab" "$WORK/insthome" "$WORK/g8"
cp -R "$PLUGIN/dev-orchestrator" "$WORK/cache/dev-orchestrator"
( cd "$WORK/instlab" && git init -q && HOME="$WORK/insthome" VIBEFLOW_CACHE="$WORK/cache" bash "$PLUGIN/_internal/vibeflow-update.sh" install dev-orchestrator > "$WORK/inst.out" 2>&1 ); INSTRC=$?
SHELLS_PRESENT=""; for s in sh bash zsh; do command -v "$s" >/dev/null 2>&1 && SHELLS_PRESENT="${SHELLS_PRESENT:+$SHELLS_PRESENT,}$s"; done
echo "  (shells présents : ${SHELLS_PRESENT:-aucun} ; installation de dev-orchestrator : rc=$INSTRC)"

# sondes <gabarit> <env> <fichier de sortie>
sondes() { node "$AUX/sondes.mjs" "$1" "$2" "$WORK/lab1" "$WORK/lab2" "$WORK/instlab" "$INSTRC" "$PLUGIN" "$SHELLS_PRESENT" "$WORK/g8" > "$3" 2> "$3.err"; }
groupes_rouges() { awk -F'\t' '$1 == "PROBE" && $3 == "FAIL" { split($2, a, "."); print a[1] }' "$1" | LC_ALL=C sort -u; }

echo "== G0 à G13 : sondes sur le module (graine 72 pour G5) =="
sondes "$GAB" "$ENVM" "$WORK/base.out"
NB="$(awk -F'\t' '$1 == "PROBE"' "$WORK/base.out" | wc -l | tr -d ' ')"
assert_eq "S0 — les sondes ont rendu leurs 36 verdicts (aucune interruption)" "$NB" "36"
while IFS=$'\t' read -r tag id verdict libelle detail; do
  [ "$tag" = "PROBE" ] || continue
  if [ "$verdict" = "PASS" ]; then echo "  ✅ PASS — $id — $libelle"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $id — $libelle"; echo "     détail: $(court "$detail")"; FAIL=$((FAIL+1)); fi
done < "$WORK/base.out"
[ -s "$WORK/base.out.err" ] && sed 's/^/     /' "$WORK/base.out.err" | head -4

echo "== G14 : module pur (comptage par awk) =="
if [ -f "$GAB" ]; then G14="$(awk 'BEGIN{n=0} /^import /{n++} /import\(|require\(|process\.|Date\.|Math\.random|node:|[( ]fs\.|readFileSync/{n++} END{print (NR > 0 && NR < 300 && n == 0) ? "ok" : "lignes=" NR " interdits=" n}' "$GAB")"; else G14="module absent"; fi
assert_eq "G14.1 — le module existe, a moins de 300 lignes, aucune dépendance, aucun accès système" "$G14" "ok"

echo "== Mutants (copies sous \$WORK/mut-<nom>/) : un mutant doit rougir au moins ses groupes de sondes =="
mutant() { # <nom> <groupes attendus, séparés par des espaces>
  local nom="$1" attendu="$2" d="$WORK/mut-$1" g gab env nouveaux manque
  node "$AUX/mut.mjs" "$nom" "$GAB" "$ENVM" "$d" > "$d.log" 2>&1
  if [ $? -ne 0 ]; then echo "  ❌ FAIL — $nom — mutant sans effet : $(cat "$d.log")"; FAIL=$((FAIL+1)); return; fi
  gab="$d/vf-cockpit-lancer-gabarit.mjs"; env="$d/vf-cockpit-terminal-env.mjs"; [ -f "$gab" ] || gab="$GAB"; [ -f "$env" ] || env="$ENVM"
  sondes "$gab" "$env" "$d.out"
  groupes_rouges "$d.out" > "$d.rouges"; groupes_rouges "$WORK/base.out" > "$d.base"
  nouveaux="$(LC_ALL=C comm -13 "$d.base" "$d.rouges" | tr '\n' ' ')"; manque=""
  for g in $attendu; do case " $nouveaux " in *" $g "*) ;; *) manque="$manque $g" ;; esac; done
  assert_eq "$nom — rougit $attendu (groupes rougis par le mutant : ${nouveaux:-aucun})" "${manque:-aucun manque}" "aucun manque"
}
mutant M-INTERPOLE "G5 G7 G8"
mutant M-MOTIF-WS "G4 G5 G7"
mutant M-MOTIF-PHASE "G4 G5"
mutant M-NETTOIE "G4 G5 G7"
mutant M-ALPHABET-LARGE "G5 G6"
mutant M-MODE-BYPASS "G4 G11"
mutant M-HERITE-FLAG "G1"
mutant M-SANS-GUILLEMETS "G1 G6 G8"
mutant M-CHAT-IGNORE "G4 G9"
mutant M-SESSION-LIBRE "G4"
mutant M-SKILL-PREFIXE "G12"
mutant M-ENV-CLAUDE-CODE "G13"

vf_hyg_assert
echo ""; echo "Résultats : $PASS PASS / $FAIL FAIL"
[ "$FAIL" -eq 0 ]
