#!/usr/bin/env bash
# test-cockpit-lancer-chat.sh — option « continuer le chat » : observateur de fetch, corps du POST, variante chat de Q, case du bandeau
# (LANC-11 ; P72-D-03, D-09, D-12, D-13, D-14 ; plan 72-13).
#   TC.1  extraireSessionChat (pure)            TC.2  enveloppe de window.fetch (fenêtre factice)     TC.3  corpsProposition (pure)
#   TC.4  CHAT_LIVRE identique dans P et Q       TC.5  Q en boîte noire (processus de Q forké, shell témoin qui capture son entrée)
#   TC.6  case du bandeau sous Chrome (page hôte jetable qui exécute vueTerminal de la sortie)       TC.7  e2e : serveur --terminal réel, route de P, bandeau de Q, capture
#   M-*   six mutants par copie du module (« mutant sans effet » = FAIL) ; M-OPTION-SANS-SONDE est rejoué par la commande de la tâche 2 du plan
# Sans Chrome : TC.1 à TC.5 et les mutants sans navigateur tournent ; la suite annonce SUITE SAUTÉE (navigateur) pour TC.6 et TC.7.
# Ports libres choisis à l'exécution (jamais 4456). Exit 0 si tout passe, 1 sinon.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"; export HERE_T
ENG="$(cd "$SCRIPTS/../skills/cockpit-moteur" && pwd -P)"; TA="$HERE_T/terminal-aux.mjs"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; RUN="$WORK/run"; mkdir -p "$AUX" "$WORK/home" "$WORK/bin" "$WORK/fauxbin" "$RUN"
export REAL_HOME="$HOME"; export HOME="$WORK/home"; export CHROME_SESSION="$HERE_T/chrome-session.mjs"
export VF_COCKPIT_MODE_DIR="$WORK/etat"; unset XDG_CACHE_HOME # AUDC-B-05 : le mode retenu d'un lancement accepté va dans un dossier jetable, jamais dans le dossier d'état réel de l'utilisateur ni de la CI
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
. "$HERE_T/socle-serveur.sh"
# 79-06 : la sortie ne porte plus de code. mod_de <sortie> = racine du module dont le code sert cette sortie (le dépôt, sauf la copie posée par mutant()) ; la table est un fichier, lu aussi par les aides node (mod-de.mjs)
MODULE="$(cd "$SCRIPTS/.." && pwd -P)"; MODMAP="$WORK/modmap"; : > "$MODMAP"; export VF_MODMAP="$MODMAP" VF_MODULE_DEFAUT="$MODULE"; MUT_OUT=""; MUT_MOD=""
mod_poser() { printf '%s\t%s\n' "$1" "$2" >> "$MODMAP"; }
mod_de() { local m; m="$(awk -F'\t' -v s="$1" '$1==s{m=$2} END{print m}' "$MODMAP" 2>/dev/null)"; printf '%s\n' "${m:-$MODULE}"; }
PASS=0; FAIL=0
court() { if [ "${#1}" -gt 300 ]; then printf '%s […] %s' "${1:0:140}" "${1: -140}"; else printf '%s' "$1"; fi; }
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$(court "$3")]"; echo "     obtenu:  [$(court "$2")]"; FAIL=$((FAIL+1)); fi; }
sans_effet() { assert_eq "$1 — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; }

CHROME=""
for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue
  if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
if [ -z "$CHROME" ]; then echo "  ⊘ SUITE SAUTÉE (navigateur) : TC.6 et TC.7 NON vérifiés, non comptés comme réussis"; fi

# ---- aides écrites par la suite (jamais dans le dépôt) ----
cat > "$AUX/mod-de.mjs" <<'JS'
// mod-de.mjs : importer(<sortie>, <fichier de scripts>) importe le fichier du MODULE qui sert cette sortie (table VF_MODMAP, défaut VF_MODULE_DEFAUT) ; la sortie ne porte que des données
import fs from 'node:fs'; import { pathToFileURL } from 'node:url';
export const modDe = (s) => { let m = process.env.VF_MODULE_DEFAUT; try { for (const l of fs.readFileSync(process.env.VF_MODMAP, 'utf8').split('\n')) { const [a, b] = l.split('\t'); if (a === s && b) m = b; } } catch {} return m; };
export const importer = (s, f) => import(pathToFileURL(`${modDe(s)}/scripts/${f}`).href);
// 79-11 : la vue de Q est un fichier du moteur du module qui sert la sortie, lu comme texte
export const texteVue = async (s) => (await import(pathToFileURL(process.env.HERE_T + '/navigateur-charger.mjs').href)).texte(`${modDe(s)}/skills/cockpit-moteur/assets/ui/terminal/vue.js`);
JS
cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/harnais-pur.mjs" <<'JS'
// harnais-pur.mjs <sortie> <cas> : TC.1, TC.3, TC.4 — imports du MODULE qui sert la sortie ; « ok », « ECHECS : … » ou « ABSENT : <nom> »
import { importer } from './mod-de.mjs';
const [, , dossier, cas] = process.argv;
const m = await importer(dossier, 'vf-cockpit-lancer-ui.mjs');
const U = '7c7d7412-0a15-4407-939b-eacb01a8e345', V = '11111111-2222-3333-4444-555555555555';
const bloc = (ev, d) => `event: ${ev}\ndata: ${JSON.stringify(d)}\n\n`;
const rendre = (checks) => { const x = checks.filter((c) => !c[1]).map((c) => c[0]); console.log(x.length ? 'ECHECS : ' + x.join(' ; ') : 'ok'); };
const requis = (nom) => { if (typeof m[nom] !== 'function') { console.log('ABSENT : ' + nom); process.exit(0); } return m[nom]; };
const cles = (o) => Object.keys(o).join(',');
if (cas === 'tc1') {
  const ex = requis('extraireSessionChat'), t = (f) => { try { return f(); } catch (e) { return 'EXCEPTION'; } };
  rendre([
    ['UUID minuscule', ex(bloc('answer', { session: U })) === U], ['UUID majuscule : écarté (forme stricte minuscule du gabarit, S3)', ex(bloc('answer', { session: U.toUpperCase() })) === null],
    ['36 caractères qui ne sont pas un UUID (a x36, tirets x36, tirets mal placés) : écartés (S3)', ['a'.repeat(36), '-'.repeat(36), U.replace(/-/g, '').padEnd(35, 'a') + '-', '7c7d741-20a15-4407-939b-eacb01a8e345'].every((v) => ex(bloc('answer', { session: v })) === null)],
    ['un identifiant rejeté après un valide ne remplace pas le valide (les lancements suivants gardent la reprise)', ex(bloc('answer', { session: U }) + bloc('answer', { session: 'a'.repeat(36) })) === U],
    ['answer précédé d\'un progress', ex(bloc('progress', { text: 'Write' }) + bloc('answer', { title: 'OK', session: U })) === U],
    ['session absente', ex(bloc('answer', { title: 'x' })) === null], ['x;touch M', ex(bloc('answer', { session: 'x;touch M' })) === null],
    ['$(touch M)', ex(bloc('answer', { session: '$(touch M)' })) === null], ['hexadécimal de 16 caractères (Codex)', ex(bloc('answer', { session: '0123456789abcdef' })) === null],
    ['37 caractères', ex(bloc('answer', { session: U + 'a' })) === null], ['bloc progress portant un session', ex(bloc('progress', { session: U })) === null],
    ['session non chaîne (nombre, tableau)', ex(bloc('answer', { session: 5 })) === null && ex(bloc('answer', { session: [U] })) === null],
    ['texte non chaîne', [undefined, null, 5, {}, [U]].every((v) => t(() => ex(v)) === null)],
    ['deux answer : le dernier valide', ex(bloc('answer', { session: U }) + bloc('answer', { session: V })) === V],
    ['deux answer, le dernier invalide : le précédent reste', ex(bloc('answer', { session: U }) + bloc('answer', { session: 'x;touch M' })) === U],
    ['data illisible', ex('event: answer\ndata: {pas du json\n\n') === null],
    ['entrée de 300 000 caractères : bornée, sans exception', t(() => ex('a'.repeat(300000))) === null],
  ]);
} else if (cas === 'tc3') {
  const cp = requis('corpsProposition'), c = (o) => cp(Object.assign({ cible: 'ph-1', verbe: 'cadrer', livre: true }, o));
  rendre([
    ['livre faux : jamais de clé chat', cles(c({ chat: U, livre: false })) === 'cible,verbe'], ['livre non booléen : jamais de clé chat', cles(c({ chat: U, livre: 'true' })) === 'cible,verbe' && cles(c({ chat: U, livre: undefined })) === 'cible,verbe'],
    ['livre vrai et UUID valide', cles(c({ chat: U })) === 'cible,verbe,chat' && c({ chat: U }).chat === U],
    ['identifiants forgés écartés (x;touch M, $(touch M), 37 caractères, 36 non-UUID, majuscules, vide, nombre, tableau, null, absent)', ['x;touch M', '$(touch M)', U + 'a', 'a'.repeat(36), U.toUpperCase(), '', 5, [U], null, undefined].every((v) => cles(c({ chat: v })) === 'cible,verbe')],
    ['aucune autre clé (ligne, intention ignorées)', cles(c({ chat: U, ligne: 'claude x', intention: 'y' })) === 'cible,verbe,chat' && cles(c({ ligne: 'claude x' })) === 'cible,verbe'],
    ['cible et verbe repris tels quels', c({ chat: U }).cible === 'ph-1' && c({ chat: U }).verbe === 'cadrer'],
  ]);
} else if (cas === 'tc4') {
  const cp = typeof m.corpsProposition === 'function' ? m.corpsProposition : () => ({ absent: 1 }), h = typeof m.injectionLancer === 'function' ? m.injectionLancer() : '';
  console.log(JSON.stringify({ livre: m.CHAT_LIVRE, corps: cles(cp({ cible: 'ph-1', verbe: 'cadrer', chat: U, livre: m.CHAT_LIVRE })), cfgVrai: h.includes('"chatLivre":true'), cfgFaux: h.includes('"chatLivre":false') }));
}
JS
cat > "$AUX/harnais-fetch.mjs" <<'JS'
// harnais-fetch.mjs <sortie> : TC.2 — l'enveloppe de window.fetch sur une fenêtre factice ; « ok », « ECHECS : … » ou « ABSENT : … »
import { importer } from './mod-de.mjs';
const m = await importer(process.argv[2], 'vf-cockpit-lancer-ui.mjs');
if (typeof m.installerObservateurChat !== 'function') { console.log('ABSENT : installerObservateurChat'); process.exit(0); }
const U = '7c7d7412-0a15-4407-939b-eacb01a8e345', att = (ms) => new Promise((ok) => setTimeout(ok, ms));
const rejets = []; process.on('unhandledRejection', (e) => rejets.push(String(e)));
const SSE = `event: start\ndata: {}\n\nevent: progress\ndata: {"text":"Write"}\n\nevent: answer\ndata: ${JSON.stringify({ title: 'OK', answer: 'OK', items: [], session: U })}\n\n`;
const POST = (o) => ({ method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify(o) });
// F-1 (P72-D-21) : la fenêtre factice porte une activation utilisateur ; `act` la règle (true par défaut ; null = API absente ; 'sans-ua' = navigator sans userActivation)
const nav = (act) => (act === null ? undefined : act === 'sans-ua' ? {} : { userActivation: { isActive: act } });
const sc = async (nom, entree, init, attendu, fabrique = () => new Response(SSE, { status: 200 }), act = true) => {
  const retenus = [], appels = []; const ref = await fabrique().text();
  const fenetre = { location: { href: 'http://127.0.0.1:1/project.html' }, navigator: nav(act), fetch: (a, b) => { appels.push([a, b]); return Promise.resolve(fabrique()); } };
  const cles0 = Object.keys(fenetre).sort().join(',');
  m.installerObservateurChat(fenetre, (...x) => retenus.push(x));
  let corps = null, erreur = null;
  try { const rep = await fenetre.fetch(entree, init); corps = typeof rep.text === 'function' ? await rep.text() : 'sans-texte'; } catch (e) { erreur = String(e).slice(0, 80); }
  await att(80);
  const bon = JSON.stringify(retenus) === JSON.stringify(attendu.map((u) => [u])) && appels.length === 1 && appels[0][0] === entree && appels[0][1] === init && Object.keys(fenetre).sort().join(',') === cles0;
  return [nom, bon && erreur === null && corps === ref, `retenus=${JSON.stringify(retenus)} corps_intact=${corps === ref} erreur=${erreur}`];
};
const r = [
  await sc('POST /api/ask en mode ask retient l\'UUID', '/api/ask', POST({ question: 'q', mode: 'ask', session: undefined }), [U]),
  await sc('mode absent : retient l\'UUID', '/api/ask', POST({ question: 'q' }), [U]),
  await sc('adresse absolue du même chemin : retient', 'http://127.0.0.1:1/api/ask', POST({ question: 'q', mode: 'ask' }), [U]),
  await sc('autre chemin : rien', '/api/status', POST({ mode: 'ask' }), []), await sc('autre méthode : rien', '/api/ask', { method: 'GET' }, []),
  await sc('mode change : rien', '/api/ask', POST({ mode: 'change' }), []), await sc('mode flow : rien', '/api/ask', POST({ mode: 'flow' }), []),
  await sc('corps non JSON : rien', '/api/ask', { method: 'POST', body: 'pas du json' }, []), await sc('sans init : rien', '/api/ask', undefined, []),
  await sc('réponse sans session : rien', '/api/ask', POST({ mode: 'ask' }), [], () => new Response('event: answer\ndata: {"title":"x"}\n\n')),
  await sc('session forgée : rien', '/api/ask', POST({ mode: 'ask' }), [], () => new Response('event: answer\ndata: {"session":"x;touch M"}\n\n')),
  // F-1 : sans activation utilisateur réelle au moment de l'appel, rien n'est retenu ; la requête d'origine part et sa réponse est rendue intacte (sc le vérifie)
  await sc('activation absente (isActive faux) : rien', '/api/ask', POST({ mode: 'ask' }), [], undefined, false),
  await sc('API navigator absente : rien (échec fermé)', '/api/ask', POST({ mode: 'ask' }), [], undefined, null),
  await sc('navigator sans userActivation : rien (échec fermé)', '/api/ask', POST({ mode: 'ask' }), [], undefined, 'sans-ua'),
  await sc('isActive non booléen (truthy) : rien', '/api/ask', POST({ mode: 'ask' }), [], undefined, 'oui'),
];
// l'activation compte AU MOMENT DE L'APPEL : active à l'appel puis éteinte avant la réponse = retenu ; éteinte à l'appel puis active à la réponse = rien
{ const lecture = async (aAppel, aReponse) => { const ua = { isActive: aAppel }, retenus = [];
    const f = { location: { href: 'http://127.0.0.1:1/project.html' }, navigator: { userActivation: ua }, fetch: () => new Promise((ok) => setTimeout(() => { ua.isActive = aReponse; ok(new Response(SSE)); }, 30)) };
    m.installerObservateurChat(f, (x) => retenus.push(x)); await f.fetch('/api/ask', POST({ mode: 'ask' })); await att(80); return JSON.stringify(retenus); };
  r.push(['active à l\'appel, éteinte à la réponse : retenu', await lecture(true, false) === JSON.stringify([U]), '']);
  r.push(['éteinte à l\'appel, active à la réponse : rien', await lecture(false, true) === '[]', '']); }
// une requête sans activation n'efface ni ne remplace l'UUID déjà retenu par un geste humain (le rappel n'est jamais appelé avec autre chose qu'un UUID retenu)
{ const ua = { isActive: true }, retenus = [], V = '11111111-2222-3333-4444-555555555555'; let n = 0;
  const f = { location: { href: 'http://127.0.0.1:1/project.html' }, navigator: { userActivation: ua }, fetch: () => Promise.resolve(new Response(`event: answer\ndata: ${JSON.stringify({ session: n++ === 0 ? U : V })}\n\n`)) };
  m.installerObservateurChat(f, (x) => retenus.push(x)); await f.fetch('/api/ask', POST({ mode: 'ask' })); await att(60);
  ua.isActive = false; await f.fetch('/api/ask', POST({ mode: 'ask' })); await att(60);
  r.push(['requête sans activation après un geste humain : l\'UUID retenu reste (ni effacé ni remplacé, aucun rappel de plus)', JSON.stringify(retenus) === JSON.stringify([U]), JSON.stringify(retenus)]); }
// un clone qui lève ne casse pas la promesse d'origine : l'appelant reçoit l'objet réponse lui-même, aucun rejet non rattrapé
{ const retenus = [], rep = { ok: true, clone() { throw new Error('clone'); }, text: async () => SSE };
  const f = { location: { href: 'http://127.0.0.1:1/project.html' }, navigator: nav(true), fetch: () => Promise.resolve(rep) }; m.installerObservateurChat(f, (x) => retenus.push(x));
  const v = await f.fetch('/api/ask', POST({ mode: 'ask' })); await att(60);
  r.push(['clone qui lève : la promesse d\'origine rend la même réponse, rien retenu', v === rep && retenus.length === 0, `meme=${v === rep}`]); }
// un fetch natif qui rejette : le rejet arrive tel quel à l'appelant, l'enveloppe n'en crée aucun autre
{ const f = { location: { href: 'http://127.0.0.1:1/project.html' }, navigator: nav(true), fetch: () => Promise.reject(new Error('reseau')) }; m.installerObservateurChat(f, () => {});
  let e = null; try { await f.fetch('/api/ask', POST({ mode: 'ask' })); } catch (x) { e = String(x.message); } await att(60);
  r.push(['rejet réseau transmis tel quel, sans rejet supplémentaire', e === 'reseau' && rejets.length === 0, `e=${e} rejets=${rejets.length}`]); }
const x = r.filter((c) => !c[1]).map((c) => c[0] + ' (' + c[2] + ')');
console.log(x.length ? 'ECHECS : ' + x.join(' ; ') : 'ok');
JS
cat > "$AUX/verif-chat.mjs" <<'JS'
// verif-chat.mjs <sortie> <chat> : lit GET /proposition (stdin) ; compare les huit lignes à composerLigne du gabarit (72-01) ; « ok » ou la première raison de rougir
import fs from 'node:fs'; import { importer } from './mod-de.mjs';
const [, , sortie, chat] = process.argv; const g = await importer(sortie, 'vf-cockpit-lancer-gabarit.mjs');
let j; try { j = JSON.parse(fs.readFileSync(0, 'utf8')); } catch { console.log('corps non JSON'); process.exit(0); }
const verdict = () => {
  if (j.etat !== 'en-attente') return `etat ${j.etat}`;
  if (j.chat !== true || !j.lignes_chat) return `chat ${j.chat} lignes_chat ${typeof j.lignes_chat}`;
  if (Object.keys(j.lignes_chat).sort().join(',') !== [...g.MODES].sort().join(',')) return 'lignes_chat : modes';
  const uuid = /--session-id '([0-9a-f-]{36})'/.exec(j.lignes.herite || '')?.[1]; if (!uuid) return 'session introuvable dans lignes.herite';
  for (const mode of g.MODES) {
    const std = g.composerLigne({ session: uuid, verbe: j.verbe, mode, phase: j.phase, ws: j.ws, chat: undefined }), ch = g.composerLigne({ session: uuid, verbe: j.verbe, mode, phase: j.phase, ws: j.ws, chat });
    if (!std.ok || !ch.ok) return `gabarit refuse ${mode}`;
    if (j.lignes[mode] !== std.ligne) return `lignes.${mode} diffère du gabarit sans chat`;
    if (j.lignes_chat[mode] !== ch.ligne) return `lignes_chat.${mode} diffère du gabarit avec chat`;
    for (const l of [j.lignes[mode], j.lignes_chat[mode]]) if (l.length > 400 || !g.ALPHABET.test(l) || l.includes('\r') || !g.validerLigne(l).ok) return `ligne ${mode} hors alphabet, longueur ou grammaire`;
    if (/ -r /.test(j.lignes[mode]) || j.lignes[mode].includes('--fork-session') || j.lignes[mode].includes(chat)) return `lignes.${mode} porte la reprise`;
    if (!j.lignes_chat[mode].includes(` -r '${chat}' --fork-session`)) return `lignes_chat.${mode} sans reprise`;
  }
  return 'ok';
};
console.log(verdict());
JS
cat > "$AUX/capture.mjs" <<'JS'
// capture.mjs <fichier> <octets-avant> <attendu-json|-> <ms> : attend que la capture dépasse <octets-avant> (jusqu'à <ms>), puis rend « ok » si ce qui a été ajouté est EXACTEMENT la chaîne attendue,
// « inchange » si rien n'a été ajouté (attendu « - »), sinon « difference : … ». La borne attend la première arrivée, puis une stabilité de 400 ms.
import fs from 'node:fs';
const [, , f, av, att, ms] = process.argv; const lire = () => { try { return fs.readFileSync(f); } catch { return Buffer.alloc(0); } };
const fin = Date.now() + Number(ms); const pause = (t) => new Promise((r) => setTimeout(r, t));
let derniere = -1;
for (;;) { const n = lire().length; if (att !== '-' && n > Number(av) && n === derniere) break; if (Date.now() > fin) break; derniere = n; await pause(att === '-' ? 100 : 400); }
const ajoute = lire().subarray(Number(av)).toString('latin1');
if (att === '-') { console.log(ajoute.length === 0 ? 'inchange' : `difference : ${ajoute.length} octets : ${JSON.stringify(ajoute.slice(0, 120))}`); process.exit(0); }
const e = JSON.parse(att); console.log(ajoute === e ? 'ok' : `difference : attendu ${JSON.stringify(e)} obtenu ${JSON.stringify(ajoute)}`);
JS
cat > "$AUX/parent.mjs" <<'JS'
// parent.mjs <sortie> <lab> <moteur> <travail> <dossier-de-scripts> : joue P. Lance le processus de Q de la sortie (IPC json), lui envoie `init`, consigne ses messages (sauf `pret`) ;
// serveur de commande 127.0.0.1 : POST /send (retransmet le corps JSON), GET /recus, POST /stop. Première ligne de sortie : PRET <Q> <commande> <P>.
import { fork } from 'node:child_process'; import http from 'node:http'; import net from 'node:net';
const [, , sortie, lab, moteur, travail, scripts] = process.argv;
const libre = () => new Promise((r) => { const s = net.createServer().listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const portP = await libre(); const recus = []; let portQ = null, portC = null;
const enfant = fork(scripts + '/vf-cockpit-terminal-processus.mjs', [], { env: process.env, cwd: lab, stdio: ['inherit', 'inherit', 'inherit', 'ipc'], serialization: 'json' });
const pret = () => { if (portQ && portC) console.log(`PRET ${portQ} ${portC} ${portP}`); };
enfant.on('message', (m) => { if (m && m.t === 'pret') { portQ = m.port; pret(); } else recus.push(m); });
enfant.send({ t: 'init', engineDir: moteur, root: lab, here: sortie, jetons: [], portP, envOrigine: { ...process.env, PATH: travail + '/fauxbin:' + process.env.PATH } });
const srv = http.createServer((req, res) => { let b = ''; req.on('data', (c) => { b += c; }); req.on('end', () => {
  if (req.url === '/send' && req.method === 'POST') { try { enfant.send(JSON.parse(b)); res.writeHead(204); } catch { res.writeHead(400); } res.end(); }
  else if (req.url === '/recus') { res.writeHead(200, { 'Content-Type': 'application/json' }); res.end(JSON.stringify(recus)); }
  else if (req.url === '/stop') { res.writeHead(204); res.end(); try { enfant.send({ t: 'arret' }); } catch {} setTimeout(() => process.exit(0), 3500); }
  else { res.writeHead(404); res.end(); } }); });
srv.listen(0, '127.0.0.1', () => { portC = srv.address().port; pret(); });
enfant.on('exit', () => setTimeout(() => process.exit(0), 200));
JS
# shell témoin : le PID reste celui du shell (exec) ; il passe en `stty raw -echo` puis `exec cat >>` : la capture dit EXACTEMENT les octets reçus de Q (aucun écho, aucune édition de ligne)
cat > "$WORK/bin/shell-temoin" <<SH
#!/bin/sh
echo \$\$ > "$RUN/shell.pid"
printf 'VFP> ' # une sortie initiale : le flux de Q n'ouvre ses en-têtes qu'au premier octet
stty raw -echo
exec cat >> "$RUN/capture"
SH
cat > "$WORK/fauxbin/claude" <<SH
#!/bin/sh
exit 0
SH
chmod +x "$WORK/bin/shell-temoin" "$WORK/fauxbin/claude"; export SHELL="$WORK/bin/shell-temoin"
export PATH="$WORK/fauxbin:$PATH"

rq() { node "$TA" req "$@"; }
evj() { node "$AUX/ev.mjs" "$1"; }
mklab() {
  local L="$1" B="$1/.planning"; mkdir -p "$L/src" "$B/phases/01-socle" "$B/phases/02-suite"; printf 'export const u = 1;\n' > "$L/src/u.js"
  printf -- '## Phases\n\n- [ ] **Phase 1: Socle** - premier jet\n- [ ] **Phase 2: Suite** - second jet\n\n### Phase 1: Socle\n**Goal**: Poser le socle\n\n### Phase 2: Suite\n**Goal**: Poser la suite\n' > "$B/ROADMAP.md"
  printf -- '---\nstatus: executing\ncurrent_phase: 1\nmilestone: v1.0 MVP\n---\n' > "$B/STATE.md"
  printf -- '---\nwave: 1\nfiles_modified: [src/u.js]\n---\n<objective>Poser le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"
  printf -- '---\nwave: 1\nfiles_modified: [src/u.js]\n---\n<objective>Poser la suite</objective>\n' > "$B/phases/02-suite/02-01-PLAN.md"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  node "$SCRIPTS/vf-cockpit.mjs" build --lab "$L" > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
}
# mutant <nom> <fichier-du-module> <expression-sed>... -> MUT_OUT (données) + MUT_MOD (copie du module muté) ; code 1 si la cible manque ou si la copie n'a pas changé
mutant() {
  local d="$WORK/mut-$1" e x="" rel="$2"; shift 2; rm -rf "$d"; mkdir -p "$d"; cp -R "$LAB/.planning" "$d/.planning"; cp -R "$LAB/.vibeflow" "$d/.vibeflow"
  MUT_OUT="$d/.vibeflow/cockpit"; MUT_MOD=""
  for e in "$@"; do x="${x:+$x
}$e"; done
  cockpit_module_muter "$(basename "$d")" "$rel" "$x" || return 1
  MUT_MOD="$COCKPIT_MODULE"; unset COCKPIT_MODULE; mod_poser "$MUT_OUT" "$MUT_MOD"; return 0
}
LAB="$WORK/lab"; mklab "$LAB"; OUT="$LAB/.vibeflow/cockpit"
UUID_CHAT='7c7d7412-0a15-4407-939b-eacb01a8e345'
FORGES=('"x;touch M"' '"$(touch M)"' '"7c7d7412-0a15-4407-939b-eacb01a8e345a"' '""' '5' '[]' '"7c7d7412-0a15-4407-939b-eacb01a8e34;"' 'null')
echo "=== ST — la sortie existe et porte les modules du plan ==="
assert_eq "ST — la sortie du cockpit contient le script de P, la vue et le client de Q, le gabarit et l'état de Q" \
  "$(for f in scripts/vf-cockpit-lancer-ui.mjs skills/cockpit-moteur/assets/ui/terminal/vue.js skills/cockpit-moteur/assets/ui/terminal/client.js scripts/vf-cockpit-lancer-gabarit.mjs scripts/vf-cockpit-lancer-q.mjs scripts/vf-cockpit-lancer.mjs scripts/vf-cockpit-terminal-processus.mjs; do [ -f "$(mod_de "$OUT")/$f" ] && echo oui || echo "non:$f"; done | sort -u | tr '\n' ' ')" "oui "

# ---- TC.1 à TC.4 : sans navigateur ----
pur() { node "$AUX/harnais-pur.mjs" "$1" "$2" 2>&1 | tail -1; }
echo "=== TC.1 — extraireSessionChat ==="
assert_eq "TC.1 — l'UUID du bloc answer seul est rendu ; tout le reste (forgé, 16 hexadécimaux, 37 caractères, progress, non chaîne) donne null, sans exception" "$(pur "$OUT" tc1)" "ok"
echo "=== TC.3 — corpsProposition ==="
assert_eq "TC.3 — la clé chat n'apparaît que si livre est vrai ET l'UUID valide ; aucune autre clé" "$(pur "$OUT" tc3)" "ok"
echo "=== TC.2 — enveloppe de window.fetch ==="
assert_eq "TC.2 — POST /api/ask en mode ask retient l'UUID ; tout autre cas rien ; la réponse rendue est lisible en entier et identique ; un clone qui lève ou un rejet réseau ne casse rien" "$(node "$AUX/harnais-fetch.mjs" "$OUT" 2>&1 | tail -1)" "ok"
echo "=== TC.4 — CHAT_LIVRE identique dans P et Q ==="
VALEUR() { sed -nE 's/.*CHAT_LIVRE[[:space:]]*=[[:space:]]*(true|false).*/\1/p' "$1" | head -1; }
T4="$(pur "$OUT" tc4)"
assert_eq "TC.4 — CHAT_LIVRE : même valeur dans le script de P (importée) et dans la vue de Q (lue dans le texte de la fonction sérialisée), et la configuration servie la porte" \
  "$(VALEUR "$(mod_de "$OUT")/scripts/vf-cockpit-lancer-ui.mjs")/$(VALEUR "$(mod_de "$OUT")/skills/cockpit-moteur/assets/ui/terminal/vue.js")/$(printf '%s' "$T4" | evj 'String(j.livre)')/$(printf '%s' "$T4" | evj 'j.cfgVrai===(j.livre===true)&&j.cfgFaux===(j.livre===false)')" \
  "true/true/true/true"
assert_eq "TC.4 — valeur réelle : le corps porte chat quand CHAT_LIVRE est vraie" "$(printf '%s' "$T4" | evj 'j.corps')" "cible,verbe,chat"
if mutant fauxlivre vf-cockpit-lancer-ui.mjs 's/CHAT_LIVRE = true/CHAT_LIVRE = false/'; then
  assert_eq "TC.4 — copie où CHAT_LIVRE vaut faux : le corps n'a pas de clé chat et la configuration servie dit faux" "$(pur "$MUT_OUT" tc4 | evj 'j.livre+"/"+j.corps+"/"+j.cfgFaux')" "false/cible,verbe/true"
else sans_effet "TC.4 (CHAT_LIVRE faux, script de P)"; fi

# ---- TC.5 : Q en boîte noire ----
NM=0; QP=0; CP=0; PP=0; SECRET=""; PARENT=""; FPID=""; ARME=400
manche_debut() { # manche_debut <sortie> -> QP CP PP SECRET PARENT FPID ; parent factice, amorçage, flux de l'onglet A, shell témoin prêt
  NM=$((NM+1)); local s="$1" am="$WORK/amorce.$NM" po="$WORK/parent-$NM.out"; FLUX="$WORK/flux-$NM.out"; : > "$FLUX"; rm -f "$RUN/shell.pid" "$RUN/capture"; : > "$RUN/capture"; mkdir -p "$s/.cache"
  rm -f "$po" # 79-06 : tc5 tourne dans une substitution (NM repart de 1 à chaque manche) : un PRET resté du parent précédent serait lu comme celui du neuf (ports morts, ECONNREFUSED)
  node -e "console.log(require('crypto').randomBytes(24).toString('hex'))" > "$am.tmp"; (umask 077; tr -d '\n' < "$am.tmp" > "$s/.cache/terminal-amorce"; tr -d '\n' < "$am.tmp" > "$am")
  VF_COCKPIT_LANCER_ARME_MS=$ARME node "$AUX/parent.mjs" "$s" "$(cd "$s/../.." && pwd -P)" "$(mod_de "$s")/skills/cockpit-moteur" "$WORK" "$(mod_de "$s")/scripts" > "$po" 2>&1 < /dev/null & PARENT=$!; PIDS+=($PARENT)
  for _ in $(seq 1 100); do grep -q '^PRET ' "$po" 2>/dev/null && break; sleep 0.1; done
  read -r _ QP CP PP < <(grep '^PRET ' "$po" | head -1); QP="${QP:-0}"; CP="${CP:-0}"; PP="${PP:-0}"
  SECRET="$(node "$TA" amorcer "$QP" "$am" | sed -n 2p)"
  node "$TA" flux "$QP" "$SECRET" A "$FLUX" 150000 --taille 24x200 > "$WORK/flux-$NM.log" 2>&1 & FPID=$!; PIDS+=($FPID)
  for _ in $(seq 1 100); do [ -s "$RUN/shell.pid" ] && break; sleep 0.1; done
  sleep 0.6 # le temps du `stty raw` du shell témoin : avant lui, l'écho du terminal mêlerait des octets à la capture
}
manche_fin() { vf_hyg_stop "$FPID"; vf_hyg_stop "$PARENT"; for _ in $(seq 1 30); do [ -z "$(vf_hyg_vivants)" ] && break; sleep 0.2; done; }
pget() { rq "$QP" GET /proposition --sans-origin --entete 'sec-fetch-site:same-origin' --secret "$SECRET" --onglet A "$@"; }
pbody() { pget "$@" | sed '1,2d'; }
pl() { rq "$QP" POST /lancer --secret "$SECRET" --onglet A --corps "$1" | sed -n 1p; }
envoyer() { rq "$CP" POST /send --corps "$1" | sed -n 1p > /dev/null; sleep 0.25; }
prop() { printf '{"t":"proposition","cible":"%s","verbe":"%s","bloquants":[],"avertissements":[]%s}' "$1" "$2" "${3:-}"; }
CIBLES='{"t":"cibles","cibles":[{"id":"ph-1","kind":"phase","verbe":"cadrer","verbes":["cadrer","planifier"],"phase":"1","ws":"fiabilite"}]}'
taille_capture() { wc -c < "$RUN/capture" | tr -d ' '; }
attente_arme() { sleep "$(node -e "console.log(($1 + 300) / 1000)")"; }
marqueurs() { find "$WORK" -name M -not -path '*/node_modules/*' 2>/dev/null | head -3 | tr '\n' ' '; }

# tc5 <sortie> -> imprime des lignes « clé=valeur » ; une manche complète
tc5() {
  local s="$1" i lit av id corps
  manche_debut "$s"; envoyer "$CIBLES"
  echo "forge_aucune=$(for lit in "${FORGES[@]}"; do envoyer "$(prop ph-1 cadrer ",\"chat\":$lit")"; pbody; echo; done | grep -c '^{"etat":"aucune"}$')"
  echo "forge_lancer_404=$(for lit in "${FORGES[@]}"; do pl "$(printf '{"id":"inconnu","mode":"herite","chat":true}')"; done | sort -u | tr -d '\n ')"
  echo "forge_capture=$(taille_capture)"; echo "marqueurs=$(marqueurs)"
  envoyer "$(prop ph-1 cadrer ",\"chat\":\"$UUID_CHAT\"")"
  lit="$(pbody)"; id="$(printf '%s' "$lit" | evj 'j.id')"
  echo "verif=$(printf '%s' "$lit" | node "$AUX/verif-chat.mjs" "$s" "$UUID_CHAT")"
  echo "avant_arme=$(pl "$(printf '{"id":"%s","mode":"plan","chat":true}' "$id")")"
  attente_arme "$(printf '%s' "$lit" | evj 'j.arme_apres_ms')"
  av="$(taille_capture)"
  echo "refus_chat_chaine=$(pl "$(printf '{"id":"%s","mode":"plan","chat":"oui"}' "$id")")"; echo "refus_chat_nombre=$(pl "$(printf '{"id":"%s","mode":"plan","chat":1}' "$id")")"; echo "refus_champ_ligne=$(pl "$(printf '{"id":"%s","mode":"plan","chat":true,"ligne":"claude x"}' "$id")")"
  echo "refus_capture=$(node "$AUX/capture.mjs" "$RUN/capture" "$av" - 800)"
  corps="$(printf '%s' "$lit" | evj 'JSON.stringify("\u0003"+j.lignes_chat.plan)')"
  echo "lancer_chat=$(pl "$(printf '{"id":"%s","mode":"plan","chat":true}' "$id")")"
  echo "capture_chat=$(node "$AUX/capture.mjs" "$RUN/capture" "$av" "$corps" 8000)"
  # chat faux explicite, puis chat absent : la ligne standard, jamais -r
  for variante in 'false:,"chat":false' 'absent:'; do
    envoyer "$(prop ph-1 cadrer ",\"chat\":\"$UUID_CHAT\"")"; lit="$(pbody)"; id="$(printf '%s' "$lit" | evj 'j.id')"; attente_arme "$(printf '%s' "$lit" | evj 'j.arme_apres_ms')"; av="$(taille_capture)"
    corps="$(printf '%s' "$lit" | evj 'JSON.stringify("\u0003"+j.lignes.acceptEdits)')"
    echo "lancer_${variante%%:*}=$(pl "$(printf '{"id":"%s","mode":"acceptEdits"%s}' "$id" "${variante#*:}")")"; echo "capture_${variante%%:*}=$(node "$AUX/capture.mjs" "$RUN/capture" "$av" "$corps" 8000)"
  done
  echo "capture_sans_retour_chariot=$(tr -d '\r' < "$RUN/capture" | cmp -s - "$RUN/capture" && echo oui || echo non)"
  manche_fin
}
verdict_tc5() { # verdict_tc5 <sortie> -> $T5 (lignes clé=valeur)
  T5="$(tc5 "$1" 2>&1)"
}
v5() { printf '%s\n' "$T5" | sed -n "s/^$1=//p" | head -1; }
echo "=== TC.5 — Q en boîte noire (processus de Q forké, shell témoin) ==="
verdict_tc5 "$OUT"
assert_eq "TC.5b — chat forgé (x;touch M, \$(touch M), 37 caractères, vide, nombre, tableau, 35 caractères et point-virgule, null) : proposition ignorée, GET = aucune, pour les huit" "$(v5 forge_aucune)" "${#FORGES[@]}"
assert_eq "TC.5b — après les propositions forgées, POST /lancer rend 404, aucun octet capturé, aucun fichier marqueur M" "$(v5 forge_lancer_404)/$(v5 forge_capture)/$(v5 marqueurs)" "404/0/"
assert_eq "TC.5a — chat valide : GET /proposition porte chat:true et lignes_chat (quatre modes), égales à composerLigne du gabarit 72-01 pour la session relevée, dans l'alphabet, 400 caractères au plus ; lignes sans -r" "$(v5 verif)" "ok"
assert_eq "TC.5c — avant armement : 425" "$(v5 avant_arme)" "425"
assert_eq "TC.5c — chat chaîne : 400 ; chat nombre : 400 ; champ inconnu ligne : 400 ; aucun octet au PTY" "$(v5 refus_chat_chaine)/$(v5 refus_chat_nombre)/$(v5 refus_champ_ligne)/$(v5 refus_capture)" "400/400/400/inchange"
assert_eq "TC.5c — POST /lancer { id, mode, chat:true } : 204 et la capture est EXACTEMENT \\x03 puis lignes_chat[mode] (contrat §4 de 72-02)" "$(v5 lancer_chat)/$(v5 capture_chat)" "204/ok"
assert_eq "TC.5c — chat:false : 204 et la capture est EXACTEMENT \\x03 puis lignes[mode] (sans -r)" "$(v5 lancer_false)/$(v5 capture_false)" "204/ok"
assert_eq "TC.5c — chat absent : 204 et la capture est EXACTEMENT \\x03 puis lignes[mode] (sans -r)" "$(v5 lancer_absent)/$(v5 capture_absent)" "204/ok"
assert_eq "TC.5c — aucun retour chariot dans la capture entière" "$(v5 capture_sans_retour_chariot)" "oui"
LIGNE_TC5_OK="$([ "$(v5 verif)" = ok ] && echo oui || echo non)"

# ---- TC.6 et TC.7 : navigateur ----
cat > "$AUX/page-vue.mjs" <<'JS'
// page-vue.mjs <sortie> <fichier-html> <fichier-json> : page hôte jetable (éléments terminal et etat) qui exécute vueTerminal du MODULE qui sert la sortie ; écrit la proposition de base (lignes du gabarit 72-01)
import { importer, texteVue } from './mod-de.mjs'; import fs from 'node:fs';
const [, , sortie, html, json] = process.argv;
const vue = await texteVue(sortie); const g = await importer(sortie, 'vf-cockpit-lancer-gabarit.mjs');
const S = '5b9c2e0a-7d41-4f3a-9c58-0e1d2f3a4b5c', C = '7c7d7412-0a15-4407-939b-eacb01a8e345';
const jeu = (chat) => Object.fromEntries(g.MODES.map((mode) => [mode, g.composerLigne({ session: S, verbe: 'cadrer', mode, phase: '72', ws: 'fiabilite', chat }).ligne]));
fs.writeFileSync(html, `<!doctype html><meta charset="utf-8"><body><div id="terminal"></div><div id="etat" hidden></div><script>(${vue})({});</script></body>`);
fs.writeFileSync(json, JSON.stringify({ id: 'a1b2c3d4e5f60718', verbe: 'cadrer', intention: 'Cadre la Phase 72 du compartiment fiabilite', phase: '72', ws: 'fiabilite', lignes: jeu(undefined), bloquants: [], avertissements: [], arme_apres_ms: 200, expire_ms: 100000, chat: true, lignesChat: jeu(C) }));
JS
cat > "$AUX/chrome-chat.mjs" <<'JS'
// chrome-chat.mjs <chrome> <mode> <json> : scénarios navigateur de l'option chat ; UNE ligne JSON. Modes : vue (TC.6) · e2e (TC.7). Gestes par Input.dispatchMouseEvent / Input.dispatchKeyEvent seulement
// (la case se coche par un clic de souris ; « Lancer » exige un clic de confiance). Chaque étape est isolée : une mesure indisponible est nommée dans `erreurs`.
import { pathToFileURL } from 'node:url'; import fs from 'node:fs'; import http from 'node:http';
const { executer, pause, stabiliser, attendreValeur, attendreEtStabiliser, positionPosee, AMORCE } = await import(pathToFileURL(process.env.CHROME_SESSION).href);
const [, , chrome, mode, brut] = process.argv; const A = JSON.parse(brut); const MS = Number(process.env.VF_CHAT_MS) || 20000;
const erreurs = {}; const essai = async (nom, f) => { try { return await f(); } catch (e) { erreurs[nom] = String(e.message).slice(0, 160); return undefined; } };
await executer(chrome, async (s) => {
  const r = { erreurs };
  await s.send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 800, deviceScaleFactor: 1, mobile: false });
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  const souris = (type, x, y) => s.send('Input.dispatchMouseEvent', { type, x, y, button: type === 'mouseMoved' ? 'none' : 'left', clickCount: 1 });
  const geste = async (c) => { if (!c) throw new Error('élément introuvable'); await souris('mouseMoved', c.x, c.y); await souris('mousePressed', c.x, c.y); await souris('mouseReleased', c.x, c.y); };
  const RECT = (sel) => `(() => { const e = ${sel}; if (!e) return null; const b = e.getBoundingClientRect(); return { x: b.left + b.width / 2, y: b.top + b.height / 2 }; })()`;
  if (mode === 'vue') {
    const ev = (x) => s.ev(x); const att = (x, n) => s.attendre(x, n, MS);
    const LANCER = `document.getElementById('proposition-lancer')`, CASE = `document.getElementById('proposition-chat')`, LIGNE = `document.getElementById('proposition-ligne')`, SEL = `document.getElementById('proposition-mode')`;
    const clic = async (sel) => { await ev(`(() => { const e = ${sel}; if (e) e.scrollIntoView({ block: 'center' }); return true; })()`); return geste(await ev(RECT(sel))); }; // LB3-S : « Préparer » est APRÈS la commande exacte et la case, dans la zone défilante du bandeau : l'utilisateur l'amène sous la souris avant de cliquer (comme clicQ, LB2)
    await s.naviguer(pathToFileURL(A.page).href); await att(`typeof window.vfTermVue === 'object'`, 'vue');
    await ev(`(() => { window.__T = { appels: [] }; window.__cb = { lancer: (m, c) => { __T.appels.push(JSON.stringify([m, c])); return new Promise(() => {}); }, annuler() {} };
      window.__base = ${JSON.stringify(A.base)}; window.__monter = (over) => { vfTermVue.proposition(Object.assign({}, __base, { modeInitial: 'default' }, over), __cb); return true; }; return true; })()`);
    const monter = (over = {}) => ev(`__monter(${JSON.stringify(over)})`);
    await essai('t1', async () => { // la case : présente, décochée, libellée, focalisable
      await monter({ id: 'c1aaaaaa11' });
      const f = await ev(`(() => { const c = ${CASE}; if (!c) return { existe: false }; c.focus(); const l = c.closest('label'); return { existe: true, type: c.type, coche: c.checked, texte: l ? l.textContent.trim() : null, focus: document.activeElement === c, nb: document.querySelectorAll('#proposition input').length }; })()`);
      r.t1 = [f.existe, f.type, f.coche, f.texte, f.focus, f.nb].join('|');
    });
    await essai('t2', async () => { // sans chat (absent, faux, ou sans lignesChat) : aucune case
      const nb = async (over) => { await monter(Object.assign({ id: 'c2aaaaaa22' }, over)); return ev(`document.querySelectorAll('#proposition input').length`); };
      r.t2 = [await nb({ chat: null, lignesChat: null }), await nb({ chat: false }), await nb({ chat: true, lignesChat: null }), await nb({ chat: 'oui' })].join('|');
    });
    await essai('t3', async () => { // la zone « Commande exacte » suit la case et le mode, pour les quatre modes
      await monter({ id: 'c3aaaaaa33' }); const ok = [];
      const ligne = () => ev(`${LIGNE}.textContent`); const choisir = (m) => ev(`(() => { const e = ${SEL}; e.value = ${JSON.stringify(m)}; e.dispatchEvent(new Event('change', { bubbles: true })); return e.value; })()`);
      for (const m of ['default', 'acceptEdits', 'plan', 'herite']) { await choisir(m); ok.push(await ligne() === A.base.lignes[m]); }
      await clic(CASE); ok.push(await ev(`${CASE}.checked`) === true);
      for (const m of ['herite', 'plan', 'acceptEdits', 'default']) { await choisir(m); ok.push(await ligne() === A.base.lignesChat[m]); }
      await clic(CASE); ok.push(await ev(`${CASE}.checked`) === false); ok.push(await ligne() === A.base.lignes.default);
      r.t3 = ok.filter(Boolean).length + '/' + ok.length;
    });
    await essai('t4', async () => { // rappel lancer(mode, avecChat) : faux par défaut, vrai après le clic sur la case
      const armee = () => att(`${LANCER}.getAttribute('aria-disabled') === 'false'`, 'armement');
      const appels = () => attendreEtStabiliser(() => ev(`__T.appels.slice()`), (v) => Array.isArray(v) && v.length >= 1, { pas: 300, max: 5000 }); // l'appel du rappel est lu une fois posé, plus après une pause fixe
      await ev(`(__T.appels.length = 0, true)`); await monter({ id: 'c4aaaaaa44' }); await armee(); await clic(LANCER); const a = await appels();
      await ev(`(__T.appels.length = 0, true)`); await monter({ id: 'c5aaaaaa55' }); await clic(CASE); await armee(); await clic(LANCER); const b = await appels();
      r.t4 = JSON.stringify([a, b]);
    });
    await essai('t5', async () => { // valeurs hostiles : aucun nœud, rien d'exécuté
      const H = '<img src=x onerror="window.__pwn=1">';
      await monter({ id: 'c6aaaaaa66', intention: H, lignesChat: Object.fromEntries(Object.keys(A.base.lignesChat).map((k) => [k, H])) }); await clic(CASE); await pause(300);
      r.t5 = await ev(`[document.querySelectorAll('img').length, String(window.__pwn), document.getElementById('proposition').textContent.includes(${JSON.stringify(H)}), document.getElementById('proposition-ligne').textContent === ${JSON.stringify(H)}].join('|')`);
    });
    return r;
  }
  // ---- e2e : serveur --terminal réel, amorçage par P, tiroir, proposition par la route de P, bandeau de Q ----
  const OP = `http://127.0.0.1:${A.P}`, OQ = `http://127.0.0.1:${A.Q}`;
  const post = (chemin, obj) => new Promise((ok) => { const c = JSON.stringify(obj);
    const q = http.request({ host: '127.0.0.1', port: A.P, path: chemin, method: 'POST', headers: { Host: `127.0.0.1:${A.P}`, Origin: OP, 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(c), 'x-vf-cockpit-token': A.ptok } }, (res) => { res.resume(); res.on('end', () => ok(res.statusCode)); });
    q.on('error', () => ok(0)); q.end(c); });
  const taille = () => { try { return fs.statSync(A.capture).size; } catch { return 0; } };
  const ESPION = `if (window.top === window) { window.__msgs = []; addEventListener('message', (e) => window.__msgs.push({ o: e.origin, d: typeof e.data === 'string' ? e.data.slice(0, 200) : '<' + typeof e.data + '>' })); }`;
  const MSG = (d) => `window.__msgs.some((m) => m.o === ${JSON.stringify(OQ)} && m.d === ${JSON.stringify(d)})`;
  const OUVERT = `(() => { const t = document.querySelector('.vf-term-tiroir'); return !!t && !t.hidden && t.getBoundingClientRect().height > 0; })()`;
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: ESPION });
  let cq = 0;
  const monde = async () => { const fin = Date.now() + MS; let essais = 0, c = 0;
    while (!c) { const et = 600 * 5 ** Math.min(essais++, 3);
      for (let id = 1; id < et && !c; id++) { const v = await s.send('Runtime.evaluate', { contextId: id, expression: `location.origin === ${JSON.stringify(OQ)} && typeof window.vfTermVue === 'object'`, returnByValue: true }).then((x) => x && x.result && x.result.value, () => false); if (v === true) c = id; }
      if (!c) { if (Date.now() > fin) throw new Error('contexte du cadre de Q introuvable'); await pause(150); } }
    return c; };
  const evQ = async (expression) => { const x = await s.send('Runtime.evaluate', { expression, contextId: cq, returnByValue: true, awaitPromise: true }); if (x && x.exceptionDetails) throw new Error('évaluation : ' + String((x.exceptionDetails.exception || {}).description || x.exceptionDetails.text).split('\n')[0].slice(0, 120)); return x && x.result && x.result.value; };
  const attQ = async (expr, nom, ms = MS) => { const fin = Date.now() + ms; let v; do { try { v = await evQ(expr); } catch { v = false; } if (v) return v; await pause(100); } while (Date.now() < fin); throw new Error(`attente de « ${nom} » dépassée (${ms} ms)`); };
  const CASE = `document.getElementById('proposition-chat')`, LANCER = `document.getElementById('proposition-lancer')`, LIGNE = `document.getElementById('proposition-ligne')`;
  const clicQ = async (sel) => { await evQ(`(() => { const e = ${sel}; if (e) e.scrollIntoView({ block: 'center' }); return true; })()`); /* LB2 : le bandeau, plus riche, défile dans le tiroir : l'utilisateur amène l'élément sous la souris avant de cliquer */
    /* PU-G-136 : une proposition remonte le tiroir à 300 px juste après que Q a rendu le bandeau ; le cadre bouge ET la mise en page de Q suit sa hauteur : la position visée est le composite (rect de l'élément dans Q + position du cadre dans P), lu jusqu'à deux lectures égales */
    const lireC = async () => { const c = await evQ(RECT(sel)); const f = await positionPosee(s.ev, `document.querySelector('.vf-term-tiroir iframe') || document.querySelector('iframe')`, { max: 1000 }); return c && f ? { x: c.x + f.x, y: c.y + f.y } : null; };
    await geste(await stabiliser(lireC, { pas: 120, max: 3000 })); };
  await essai('amorcage', async () => { await s.naviguer(`${OP}/project.html#t=${A.amorce}`); await s.attendre(`${MSG('ready')} && !location.hash`, 'cadre de Q prêt', process.env.VF_CHAT_MS ? MS : Math.max(MS, AMORCE)); }); // amorçage : borné par l'échéance globale (par défaut), sauf VF_CHAT_MS posée explicitement
  await essai('P', async () => { await s.naviguer(`${OP}/project.html`); await s.attendre(`!!document.querySelector('button.vf-term-pastille')`, 'pastille Terminal', MS);
    await s.ev(`(() => { const b = document.createElement('button'); b.id = 'temoin'; b.textContent = 't'; b.style.cssText = 'position:fixed;left:0;top:0;width:12px;height:12px;z-index:1'; document.body.appendChild(b); b.focus(); })()`);
    for (const type of ['keyDown', 'keyUp']) await s.send('Input.dispatchKeyEvent', { type, key: ' ', code: 'Space', windowsVirtualKeyCode: 32, modifiers: 10 });
    try { await s.attendre(`${OUVERT} && ${MSG('etat:connecte')}`, 'tiroir ouvert et terminal connecté', MS); } catch (e) { r.diag = await s.ev(`JSON.stringify({ ouvert: ${OUVERT}, msgs: window.__msgs.map((m) => m.d) })`); try { cq = await monde(); r.diagQ = await evQ(`(async () => JSON.stringify({ etat: document.getElementById('etat').innerText, hidden: document.getElementById('etat').hidden, xterm: !!document.querySelector('.xterm'), w: innerWidth, h: innerHeight, sec: !!localStorage.getItem('vf.terminal.secret'), et: await fetch('/etat', { headers: { 'X-VF-Terminal': localStorage.getItem('vf.terminal.secret'), 'X-VF-Onglet': sessionStorage.getItem('vf.terminal.onglet') } }).then((x) => x.text()), msgs: window.__fait }))()`); r.diagMsgs = await s.ev(`JSON.stringify(window.__msgs.map((m) => m.d))`); } catch (x) { r.diagQ = String(x.message); } throw e; }
    cq = await monde(); });
  const lancement = async (nom, cible, cocher) => essai(nom, async () => {
    const av = taille(); r[nom] = { statutP: await post('/api/vf/lancer', { cible, verbe: 'cadrer', chat: A.chat }) };
    await attQ(`!!${CASE}`, 'case dans le bandeau de Q'); r[nom].case = await evQ(`({ type: ${CASE}.type, coche: ${CASE}.checked, texte: ${CASE}.closest('label').textContent.trim() })`);
    if (cocher) await clicQ(CASE); r[nom].cocheApres = await evQ(`${CASE}.checked`); r[nom].affichee = await evQ(`${LIGNE}.textContent`);
    await attQ(`${LANCER}.getAttribute('aria-disabled') === 'false'`, 'bouton Lancer armé'); await clicQ(LANCER);
    await attendreEtStabiliser(async () => taille(), (n) => n > av, { pas: 500, max: MS }); /* ^C puis la ligne peuvent arriver en deux morceaux : la capture est lue une fois la taille posée */
    r[nom].capture = fs.readFileSync(A.capture).subarray(av).toString('latin1');
  });
  await lancement('e1', A.cibles[0], true); await attQ(`!document.getElementById('proposition')`, 'bandeau de e1 retiré'); await lancement('e2', A.cibles[1], false);
  r.csp = s.violations.slice(); return r;
}, { csp: true });
JS
rj() { printf '%s\n' "$1" | node "$AUX/ev.mjs" "$2" 2>/dev/null; }

srvn=0
srv() { # srv <sortie> -> SRV_PORT SRV_PID QP AMORCE ; serveur --terminal lancé depuis le module qui sert la sortie (le dépôt ou une copie mutée)
  local o="$1" lab; lab="$(cd "$o/../.." && pwd -P)"; srvn=$((srvn+1)); SRV_O="$o"; local so="$WORK/serve-$srvn.out"; rm -f "$o/.cache/server.json" "$o/.cache/terminal-amorce"; mkdir -p "$o/.cache"
  AMORCE="$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")"; (umask 077; printf '%s' "$AMORCE" > "$o/.cache/terminal-amorce")
  rm -f "$RUN/shell.pid" "$RUN/capture"; : > "$RUN/capture"
  local mod cm=""; mod="$(mod_de "$o")"; [ "$mod" = "$MODULE" ] || cm="$mod"   # copie mutée : l'aide vérifie que le serveur lancé la charge (code 5 sinon)
  COCKPIT_MODULE="$cm" COCKPIT_PRET=terminal COCKPIT_LOG="$so" cockpit_lancer "$lab" VF_COCKPIT_ENGINE_DIR="$mod/skills/cockpit-moteur" VF_COCKPIT_SCRIPTS_DIR="$mod/scripts" --terminal
  SRV_PID="$VF_PID"; SRV_PORT="${VF_PORT:-0}"
  QP="$(node "$AUX/ev.mjs" '(j.terminal&&j.terminal.url)||"http://127.0.0.1:0"' < "$o/.cache/server.json" 2>/dev/null)"; QP="${QP##*:}"
  rq "$SRV_PORT" GET /project.html --corps-vers "$WORK/page-$srvn.html" > /dev/null
  PTOK="$(node -e "const m=/VF_COCKPIT_SERVER=\{\"token\":\"([0-9a-f]+)\"/.exec(require('fs').readFileSync(process.argv[1],'utf8'));console.log(m?m[1]:'')" "$WORK/page-$srvn.html")"
}
unsrv() { vf_hyg_stop "$SRV_PID"; }
cibles_libres() { rq "$SRV_PORT" GET /api/vf/lancer/cibles --jeton "$PTOK" | sed '1,2d' | evj '(j.cibles||[]).filter((c)=>c.bloquants.length===0&&c.verbes.includes("cadrer")).map((c)=>c.id)'; }

if [ -n "$CHROME" ]; then
  echo "=== TC.6 — case du bandeau sous Chrome ==="
  run_vue() { # run_vue <sortie> -> VJ
    node "$AUX/page-vue.mjs" "$1" "$WORK/page-vue.html" "$WORK/base.json" || { VJ='{"erreur":"page-vue"}'; return; }
    VJ="$(node "$AUX/chrome-chat.mjs" "$CHROME" vue "{\"page\":\"$WORK/page-vue.html\",\"base\":$(cat "$WORK/base.json")}")"
  }
  run_vue "$OUT"; VJ0="$VJ"
  vv() { rj "$VJ0" "(j.erreur ? 'plante: ' + j.erreur : j.$1 !== undefined ? j.$1 : 'erreur: ' + ((j.erreurs || {}).$1 || 'étape absente'))"; }
  assert_eq "TC.6 — proposition avec chat:true : UNE case à cocher, décochée par défaut, libellée « Continuer la conversation du chat », focalisable" "$(vv t1)" "true|checkbox|false|Continuer la conversation du chat|true|1"
  assert_eq "TC.6 — sans chat (absent, faux, sans lignesChat, valeur non booléenne) : aucune case" "$(vv t2)" "0|0|0|0"
  assert_eq "TC.6 — « Commande exacte » : lignes[mode] case décochée, lignesChat[mode] case cochée, pour les quatre modes et à chaque changement (4 + 1 + 4 + 2 contrôles)" "$(vv t3)" "11/11"
  assert_eq "TC.6 — le rappel lancer reçoit (mode, false) par défaut, (mode, true) après le clic sur la case" "$(vv t4)" '[["[\"default\",false]"],["[\"default\",true]"]]'
  assert_eq "TC.6 — valeur hostile dans la proposition : aucun nœud img, rien d'exécuté, le texte est posé tel quel (intention et ligne)" "$(vv t5)" "0|undefined|true|true"

  echo "=== TC.7 — e2e : serveur --terminal réel, route de P, bandeau de Q, capture du shell témoin ==="
  run_e2e() { # run_e2e <sortie> -> EJ ; un serveur neuf, un amorçage neuf, un Chrome neuf
    srv "$1"; local ids; ids="$(cibles_libres)"; E2E_IDS="$ids"
    EJ="$(node "$AUX/chrome-chat.mjs" "$CHROME" e2e "{\"P\":$SRV_PORT,\"Q\":$QP,\"amorce\":\"$AMORCE\",\"ptok\":\"$PTOK\",\"chat\":\"$UUID_CHAT\",\"cibles\":$(printf '%s' "${ids:-[]}" | evj 'j.length>=2?j.slice(0,2):["ph-1","ph-2"]'),\"capture\":\"$RUN/capture\"}")"; unsrv
  }
  run_e2e "$OUT"; EJ0="$EJ"
  ee() { rj "$EJ0" "(j.erreur ? 'plante: ' + j.erreur : $1)"; }
  assert_eq "TC.7 — pré-vols de P : deux cibles lançables avec le verbe cadrer (témoin positif des deux lancements)" "$(printf '%s' "$E2E_IDS" | evj 'j.length>=2')" "true"
  assert_eq "TC.7 — POST /api/vf/lancer { cible, verbe, chat } avec le jeton de page : 202 (e1 puis e2)" "$(ee 'String((j.e1||{}).statutP)+"/"+String((j.e2||{}).statutP)')" "202/202"
  assert_eq "TC.7 — la case apparaît dans le bandeau de Q, décochée par défaut (e1 et e2), libellée" "$(ee 'JSON.stringify([(j.e1||{}).case,(j.e2||{}).case])')" '[{"type":"checkbox","coche":false,"texte":"Continuer la conversation du chat"},{"type":"checkbox","coche":false,"texte":"Continuer la conversation du chat"}]'
  assert_eq "TC.7 — e1 cochée puis « Lancer » : le shell témoin capture \\x03 puis la ligne affichée, avec -r '<chat>' --fork-session, sans retour chariot" "$(ee '(j.e1&&j.e1.cocheApres===true&&j.e1.capture==="\u0003"+j.e1.affichee&&j.e1.capture.includes(" -r '"'$UUID_CHAT'"' --fork-session")&&!j.e1.capture.includes("\r")&&j.e1.capture.startsWith("\u0003claude --session-id ")&&j.e1.capture.length<=400)?"ok":JSON.stringify([j.erreurs,j.e1])')" "ok"
  assert_eq "TC.7 — e2 non cochée puis « Lancer » : la ligne standard est capturée, sans -r ni --fork-session, sans retour chariot" "$(ee '(j.e2&&j.e2.cocheApres===false&&j.e2.capture==="\u0003"+j.e2.affichee&&!j.e2.capture.includes(" -r ")&&!j.e2.capture.includes("--fork-session")&&!j.e2.capture.includes("\r")&&j.e2.capture.startsWith("\u0003claude --session-id "))?"ok":JSON.stringify([j.erreurs,j.e2])')" "ok"
  assert_eq "TC.7 — aucun nom d'étape en échec ni violation de politique de contenu" "$(rj "$EJ0" 'JSON.stringify([j.erreurs||j.erreur, j.csp])')" "[{},[]]"
fi

# ---- TC.7 sans navigateur : la route de P refuse un chat forgé ----
echo "=== TC.7 — route de P (sans navigateur) : chat forgé refusé ==="
tc7p() { # tc7p <sortie> -> « statut-témoin statut-forgé1 … » (1 témoin positif, puis les forgés)
  srv "$1"; local ids id out; ids="$(cibles_libres)"; id="$(printf '%s' "$ids" | evj 'j[0]||"ph-1"')"
  out="$(rq "$SRV_PORT" POST /api/vf/lancer --jeton "$PTOK" --entete 'Content-Type:application/json' --corps "{\"cible\":\"$id\",\"verbe\":\"cadrer\",\"chat\":\"$UUID_CHAT\"}" | sed -n 1p)"
  for f in "x;touch M" '$(touch M)' "${UUID_CHAT}a" ""; do out="$out $(rq "$SRV_PORT" POST /api/vf/lancer --jeton "$PTOK" --entete 'Content-Type:application/json' --corps "{\"cible\":\"$id\",\"verbe\":\"cadrer\",\"chat\":\"${f}\"}" | sed -n 1p)"; done
  unsrv; echo "$out"
}
assert_eq "TC.7 — chat valide : 202 (témoin) ; x;touch M, \$(touch M), 37 caractères, chaîne vide : refusés (statut 4xx, jamais 202)" "$(tc7p "$OUT" | tr ' ' '\n' | awk 'NR==1{t=$0; next} {if ($0 ~ /^4[0-9][0-9]$/) n++} END{print t "/" n}')" "202/4"

# ---- mutants ----
echo "=== Mutants (copies de la sortie) ==="
if mutant uivalid vf-cockpit-lancer-ui.mjs 's/\^\[0-9a-f\]{8}-\[0-9a-f\]{4}-\[0-9a-f\]{4}-\[0-9a-f\]{4}-\[0-9a-f\]{12}\$/^.+$/g'; then
  assert_eq "M-CHAT-NON-VALIDE-UI — le mutant (extracteur et constructeur sans le test d'UUID) rougit TC.1 : x;touch M passe" "$(pur "$MUT_OUT" tc1 | sed 's/^ECHECS.*/rouge/;s/^ok$/vert/')" "rouge"
  assert_eq "M-CHAT-NON-VALIDE-UI — le mutant rougit TC.3 : un identifiant forgé entre dans le corps" "$(pur "$MUT_OUT" tc3 | sed 's/^ECHECS.*/rouge/;s/^ok$/vert/')" "rouge"
else sans_effet "M-CHAT-NON-VALIDE-UI"; fi
if mutant motiflache vf-cockpit-lancer-ui.mjs 's#/\^\[0-9a-f\]{8}-\[0-9a-f\]{4}-\[0-9a-f\]{4}-\[0-9a-f\]{4}-\[0-9a-f\]{12}\$/#/^[0-9a-f-]{36}$/i#g'; then
  assert_eq "M-MOTIF-LACHE (S3) — l'ancien motif /^[0-9a-f-]{36}$/i remis rougit TC.1 ET TC.3 : un 36 caractères non-UUID ou des majuscules sont de nouveau retenus" "$(pur "$MUT_OUT" tc1 | sed 's/^ECHECS.*/rouge/;s/^ok$/vert/')/$(pur "$MUT_OUT" tc3 | sed 's/^ECHECS.*/rouge/;s/^ok$/vert/')" "rouge/rouge"
else sans_effet "M-MOTIF-LACHE"; fi
if mutant pvalid vf-cockpit-lancer.mjs 's/if (chat !== undefined && !UUID.test(chat))/if (false)/'; then
  assert_eq "M-CHAT-NON-VALIDE-P — le mutant rougit TC.7 : la route de P accepte un identifiant forgé (le témoin positif rend 202, le nombre de refus tombe sous 4)" "$(tc7p "$MUT_OUT" | tr ' ' '\n' | awk 'NR==1{t=$0; next} {if ($0 ~ /^4[0-9][0-9]$/) n++} END{print t "/" (n<4 ? "rouge" : "vert")}')" "202/rouge"
else sans_effet "M-CHAT-NON-VALIDE-P"; fi
if mutant qvalid vf-cockpit-lancer-q.mjs 's/UUID_RE\.test(m\.chat)/true/'; then
  verdict_tc5 "$MUT_OUT"
  assert_eq "M-CHAT-NON-VALIDE-Q — Q sans son propre test d'UUID : la proposition forgée reste ignorée (défense en profondeur : le gabarit refuse l'identifiant), aucun octet" "$(v5 forge_aucune)/$(v5 forge_capture)" "${#FORGES[@]}/0"
else sans_effet "M-CHAT-NON-VALIDE-Q"; fi
if mutant consomme vf-cockpit-lancer-ui.mjs 's/reponse\.clone()/reponse/'; then
  assert_eq "M-ENVELOPPE-CONSOMME — le mutant (lecture de la réponse d'origine) rougit TC.2 : le viewer ne peut plus lire sa réponse" "$(node "$AUX/harnais-fetch.mjs" "$MUT_OUT" 2>&1 | tail -1 | awk '/^ECHECS.*corps_intact=false/ {print "rouge"; next} {print "autre : " substr($0, 1, 120)}')" "rouge"
else sans_effet "M-ENVELOPPE-CONSOMME"; fi
if mutant activation vf-cockpit-lancer-ui.mjs 's/const humain = actif();/const humain = true;/'; then
  assert_eq "M-ACTIVATION-RETIREE — le mutant (garde d'activation retirée) rougit TC.2 : une requête sans activation retient de nouveau l'UUID" "$(node "$AUX/harnais-fetch.mjs" "$MUT_OUT" 2>&1 | tail -1 | awk '/^ECHECS.*(activation absente|navigator|isActive|éteinte)/ {print "rouge"; next} {print "autre : " substr($0, 1, 160)}')" "rouge"
else sans_effet "M-ACTIVATION-RETIREE"; fi
if [ -n "$CHROME" ]; then
  if mutant toujours vue.js '/garde:chat-offre/s/CHAT_LIVRE && p\.chat === true && [^;]*;/true;/'; then
    run_vue "$MUT_OUT"
    assert_eq "M-CASE-TOUJOURS — le mutant (case offerte sans chat) rougit TC.6 : une case existe sans conversation" "$(rj "$VJ" '(j.erreur ? "plante" : (/^[0-9]\|[0-9]\|[0-9]\|[0-9]$/.test(j.t2 || "") && j.t2 !== "0|0|0|0") ? "rouge" : "autre : " + j.t2)')" "rouge"
  else sans_effet "M-CASE-TOUJOURS"; fi
  if mutant force client.js '/garde:corps-lancer/s/avecChat === true ? { chat: true } : {}/{ chat: true }/'; then
    VF_CHAT_MS=20000 run_e2e "$MUT_OUT"
    assert_eq "M-CLIENT-CHAT-FORCE — le mutant (chat:true même case décochée) rougit TC.7 non cochée : la ligne de reprise part alors que la ligne standard était affichée" "$(rj "$EJ" '(j.erreur ? "plante" : (j.e2 && j.e2.cocheApres === false && typeof j.e2.capture === "string" && j.e2.capture.includes(" -r ") && j.e2.capture !== "\u0003" + j.e2.affichee) ? "rouge" : "autre : " + JSON.stringify(j.e2 || j.erreurs))')" "rouge"
  else sans_effet "M-CLIENT-CHAT-FORCE"; fi
fi

vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
