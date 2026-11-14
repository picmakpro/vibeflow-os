#!/usr/bin/env bash
# test-cockpit-lancer-mode.sh — le mode retenu survit aux relances du cockpit (LANC-09 ; P72-D-02bis, P72-D-20 ; plan 72-16).
# Support (AUDC-B-05 ; arbitrage Samuel, AskUserQuestion session principale, 2026-11-11) : un fichier d'UN mot dans le dossier d'état DU POSTE, projet par projet
# (<base>/<empreinte du lab>/terminal-mode, dossiers 0700, fichier 0600 ; base = $VF_COCKPIT_MODE_DIR ici, jamais l'état réel de l'utilisateur), tenu par le seul processus de Q
# (vf-cockpit-lancer-mode.mjs) : écrit par Q au POST /lancer ACCEPTÉ, lu une fois au démarrage, servi par GET /proposition (clé mode_retenu, état en-attente seulement).
# L'ancien <sortie>/.cache/terminal-mode n'est plus jamais lu (un lab reçu ne peut plus apporter de présélection) ; aucun fichier n'est créé sous le lab par un lancement accepté.
#   LM.S statique : module, frontière de P, table des routes de Q, client sans stockage du mode, aucun message IPC, aucun journal de valeur
#   LM.U module (node pur, doublures de fs) : revalidation, formes du chemin, écriture atomique, valeur gardée en mémoire, lecteur concurrent
#   LM.Q processus de Q réel (parent factice, vrai shell, faux claude) : survie à la relance (autre port, SIGKILL), forge avant démarrage, écriture seulement sur un lancement accepté
#   LM.P P réel (--terminal, Q réelle) : aucune route ne rend le fichier, aucune écriture par P, le mode ne figure dans aucune réponse de P
#   LM.G le support n'est pas dans le lab : chemin du poste, build rejoué, purge de serve.mjs · LM.C client (doublures Node) : présélection servie, stockage du navigateur absent du chemin du mode
#   M-* mutants (copies de la sortie ou des sources) : « mutant sans effet » = FAIL ; « non jouée : module absent » tant que le module n'existe pas
# Chaque refus a son témoin positif ; aucune attente d'armement n'est une durée codée en dur (arme_apres_ms est lu). Chrome non requis. Exit 0 si tout passe, 1 sinon.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"; export HERE_T; COCKPIT="$(cd "$SCRIPTS/.." && pwd)"
ENG="$(cd "$SCRIPTS/../skills/cockpit-moteur" && pwd -P)"; TA="$HERE_T/terminal-aux.mjs"; MOD="$SCRIPTS/vf-cockpit-lancer-mode.mjs"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; RUN="$WORK/run"; mkdir -p "$AUX" "$WORK/home" "$WORK/bin" "$WORK/fauxbin" "$RUN" "$WORK/temoins" "$WORK/u"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
STATE="$WORK/etat"; mkdir -p "$STATE"; chmod 700 "$STATE"; export VF_COCKPIT_MODE_DIR="$STATE"; unset XDG_CACHE_HOME # jamais le dossier d'état réel de l'utilisateur ni de la CI
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
. "$HERE_T/socle-serveur.sh"
PASS=0; FAIL=0; NONJOUE=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$(court "$3")]"; echo "     obtenu:  [$(court "$2")]"; FAIL=$((FAIL+1)); fi; }
court() { if [ "${#1}" -gt 300 ]; then printf '%s […] %s' "${1:0:140}" "${1: -140}"; else printf '%s' "$1"; fi; }
nonjouee() { echo "  ⊘ $1 — non jouée : $2"; NONJOUE=$((NONJOUE+1)); }
MODULE_OK=0; [ -f "$MOD" ] && MODULE_OK=1
# 79-06 : la sortie (MUT_OUT) ne porte que des données ; le code muté vit dans une COPIE du module (MUT_MOD), posée par mutant().
# mod_de <arg> : dossier de SCRIPTS dont une aide lit le code (la copie mutée si l'argument est MUT_OUT, sinon l'argument tel quel) ; scripts_de / eng_de / racine_de <sortie> : ce qui sert une sortie (le dépôt, sauf MUT_OUT)
MUT_OUT=""; MUT_MOD=""
mutee() { [ -n "$MUT_OUT" ] && [ -n "$MUT_MOD" ] && [ "$1" = "$MUT_OUT" ]; }
mod_de() { if mutee "$1"; then printf '%s\n' "$MUT_MOD/scripts"; else printf '%s\n' "$1"; fi; }
scripts_de() { if mutee "$1"; then printf '%s\n' "$MUT_MOD/scripts"; else printf '%s\n' "$SCRIPTS"; fi; }
eng_de() { if mutee "$1"; then printf '%s\n' "$MUT_MOD/skills/cockpit-moteur"; else printf '%s\n' "$ENG"; fi; }
racine_de() { if mutee "$1"; then printf '%s\n' "$MUT_MOD"; else printf '%s\n' "$COCKPIT"; fi; }

# ---- aides écrites par la suite (jamais dans le dépôt) ----
cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/sigf.mjs" <<'JS'
// sigf.mjs <fichier> : empreinte du fichier (inode, date de modification, droits, contenu) en JSON, ou « absent »
import fs from 'node:fs'; const f = process.argv[2];
try { const st = fs.lstatSync(f); console.log(JSON.stringify({ ino: st.ino, mtime: st.mtimeMs, perm: (st.mode & 0o777).toString(8), contenu: fs.readFileSync(f, 'utf8') })); } catch { console.log('absent'); }
JS
cat > "$AUX/parent.mjs" <<'JS'
// parent.mjs <sortie> <lab> <moteur> <travail> <dossier-de-scripts> : joue P. Lance le processus de Q du module (dossier de scripts), la sortie ne porte que des données (IPC json), lui envoie `init`, consigne ses messages (sauf `pret`) ;
// serveur de commande 127.0.0.1 : POST /send, GET /recus, POST /stop (message `arret`). Première ligne de sortie : PRET <Q> <commande> <P>.
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
cat > "$AUX/apres.mjs" <<'JS'
// apres.mjs <fichier> <marque> <sous-chaine> <ms> : TROUVE si la sous-chaîne paraît APRÈS la dernière occurrence de la marque, sinon ABSENT
import fs from 'node:fs';
const [, , f, marque, sous, ms] = process.argv; const fin = Date.now() + Number(ms);
for (;;) {
  let t = ''; try { t = fs.readFileSync(f).toString('latin1'); } catch {}
  const i = t.lastIndexOf(marque);
  if (i >= 0 && t.indexOf(sous, i + marque.length) >= 0) { console.log('TROUVE'); process.exit(0); }
  if (Date.now() >= fin) { console.log('ABSENT'); process.exit(1); }
  await new Promise((r) => setTimeout(r, 50));
}
JS
# u.mjs <dossier-du-module> <travail> <cas> : faits LM.U, une ligne JSON. Cas : tout · fifo (seul, car la FIFO peut BLOQUER un module sans O_NONBLOCK)
cat > "$AUX/u.mjs" <<'JS'
import fs from 'node:fs'; import path from 'node:path'; import { execFileSync, spawn } from 'node:child_process'; import { pathToFileURL } from 'node:url';
const [, , dir, travail, cas] = process.argv; process.umask(0o022); // umask connu : les droits constatés ne dépendent pas de celui de l'appelant
const M = await import(pathToFileURL(path.join(dir, 'vf-cockpit-lancer-mode.mjs')).href);
let n = 0; const frais = () => { const d = path.join(travail, 'x' + process.pid + '-' + (++n)); fs.mkdirSync(d, { recursive: true }); fs.chmodSync(d, 0o700); return d; };
const pose = (octets, droits = 0o600) => { const f = path.join(frais(), 'terminal-mode'); fs.writeFileSync(f, octets); fs.chmodSync(f, droits); return f; };
const lire = (f, opts = {}) => { try { return M.creerMemoireMode({ fichier: f, ...opts }).lire(); } catch (e) { return 'EXC:' + e.message; } };
const R = {};
if (cas === 'fifo') {
  const f = path.join(frais(), 'terminal-mode'); execFileSync('mkfifo', [f]);
  R.fifo = lire(f); console.log(JSON.stringify(R)); process.exit(0);
}
R.u1 = [lire(pose('plan')), lire(path.join(frais(), 'terminal-mode')), lire(pose('plan\n'))];
const forges = ['bypassPermissions', 'Plan', 'PLAN', 'plan plan', 'plan\nplan', 'plan\0', '', '\n', '{"mode":"plan"}', '["plan"]', '__proto__', 'constructor', 'toString', 'a'.repeat(33), 'a'.repeat(4096), 'plan\n' + 'x'.repeat(28), Buffer.from([0x70, 0x6c, 0xff, 0xfe])];
R.u2 = forges.map((v) => lire(pose(v)));
R.u2n = forges.length;
// mots valides entourés de blancs : seule la forme « mot » ou « mot + UN \n » est lue (un trim() les accepterait)
R.u2blancs = [' plan', 'plan ', 'plan \n', 'plan\n\n', 'plan\r\n', '\nplan'].map((v) => lire(pose(v)));
R.u2bom = lire(pose(Buffer.concat([Buffer.from([0xef, 0xbb, 0xbf]), Buffer.from('plan')])));
R.u2fin = [lire(pose('plan\n')), lire(pose('plan'))];
// borne de taille : un fichier DONT LE FSTAT annonce plus de 32 octets ne doit déclencher aucune lecture
const tracer = (extra = {}) => { const appels = []; const o = { ...fs }; for (const k of Object.keys(fs)) if (typeof fs[k] === 'function') o[k] = (...a) => { appels.push([k, ...a.map((x) => (typeof x === 'number' || typeof x === 'string' || typeof x === 'boolean' ? x : typeof x === 'object' && x !== null ? '{}' : typeof x))]); return fs[k](...a); }; Object.assign(o, extra); return { fs: o, appels }; };
{ const f = pose('plan'); const t = tracer({ fstatSync: (fd) => { const st = fs.fstatSync(fd); return { isFile: () => st.isFile(), uid: st.uid, mode: st.mode, size: 4096 }; } });
  const v = lire(f, { fs: t.fs }); const t2 = tracer(); const v2 = lire(pose('plan'), { fs: t2.fs });
  R.u2taille = [v, t.appels.filter((a) => a[0] === 'readSync').length, v2, t2.appels.filter((a) => a[0] === 'readSync').length]; }
// propriétaire : fstat simulé d'un autre uid (la vraie situation exige un privilège : non jouable ici, la doublure la remplace)
{ const f = pose('plan'); const t = tracer({ fstatSync: (fd) => { const st = fs.fstatSync(fd); return { isFile: () => st.isFile(), uid: st.uid + 1, mode: st.mode, size: st.size }; } });
  R.u3uid = [lire(f, { fs: t.fs }), lire(f)]; }
// formes du chemin
{ const cible = pose('plan'); const d = frais(); fs.symlinkSync(cible, path.join(d, 'terminal-mode')); R.u3lien = lire(path.join(d, 'terminal-mode')); }
{ const d = frais(); fs.mkdirSync(path.join(d, 'terminal-mode')); R.u3dossier = lire(path.join(d, 'terminal-mode')); }
R.u3droits = [lire(pose('plan', 0o644)), lire(pose('plan', 0o660)), lire(pose('plan', 0o640)), lire(pose('plan', 0o600)), lire(pose('plan', 0o400))];
// écriture : suite des opérations sur une doublure de fs
const noms = (t) => t.appels.map((a) => a[0]);
{ const d = frais(), f = path.join(d, 'terminal-mode'); const t = tracer(); const m = M.creerMemoireMode({ fichier: f, fs: t.fs });
  const dep = t.appels.length; const r = m.ecrire('plan'); const ops = t.appels.slice(dep);
  const ouverts = ops.filter((a) => a[0] === 'openSync'), ren = ops.filter((a) => a[0] === 'renameSync'), ecr = ops.filter((a) => /^(writeSync|writeFileSync|appendFileSync)$/.test(a[0]));
  const dirDe = (p) => path.dirname(String(p));
  R.u4 = { rend: r, lu: m.lire(), contenu: fs.readFileSync(f, 'utf8'), perm: (fs.statSync(f).mode & 0o777).toString(8),
    ouvertTemp: ouverts.length === 1 && ouverts[0][2] === 'wx' && ouverts[0][3] === 0o600 && dirDe(ouverts[0][1]) === d && ouverts[0][1] !== f,
    renomme: ren.length === 1 && ren[0][2] === f && ren[0][1] === ouverts[0][1], ecrit: ecr.length >= 1,
    cibleEcrite: ops.some((a) => /^(openSync|writeFileSync|appendFileSync|createWriteStream|truncateSync|copyFileSync)$/.test(a[0]) && a[1] === f),
    ordre: noms({ appels: ops }).filter((x) => /^(openSync|writeSync|writeFileSync|closeSync|renameSync)$/.test(x)).join(','), restes: fs.readdirSync(d).join(',') }; }
{ const d = frais(), f = path.join(d, 'terminal-mode'); const t = tracer({ renameSync: () => { throw new Error('rename refusé'); } }); const m = M.creerMemoireMode({ fichier: f, fs: t.fs });
  let exc = 'aucune'; let r; try { r = m.ecrire('plan'); } catch (e) { exc = e.message; }
  R.u4rename = { rend: r, exc, lu: m.lire(), restes: fs.readdirSync(d).join(','), cible: fs.existsSync(f) }; }
{ const d = frais(), f = path.join(d, 'terminal-mode'); const t = tracer(); const m = M.creerMemoireMode({ fichier: f, fs: t.fs }); const dep = t.appels.length; const rs = [];
  for (const v of ['bypassPermissions', 'toString', 42, undefined, null, 'Plan', ['plan']]) rs.push(m.ecrire(v));
  R.u4hors = { rend: rs.join(','), appels: t.appels.length - dep, lu: m.lire(), existe: fs.existsSync(f) }; }
// dossier support redirigé : .cache devenu un lien vers un autre dossier -> aucune écriture, aucune exception ; témoin : un vrai dossier -> écrit
{ const essai = (lien) => { const racine = frais(), cible = frais(), cache = path.join(racine, '.cache'); if (lien) fs.symlinkSync(cible, cache); else { fs.mkdirSync(cache); fs.chmodSync(cache, 0o700); }
    const m = M.creerMemoireMode({ fichier: path.join(cache, 'terminal-mode') }); let exc = 'aucune', r; try { r = m.ecrire('plan'); } catch (e) { exc = e.message; }
    return [r, exc, fs.readdirSync(cible).length, fs.readdirSync(cache).filter((x) => x === 'terminal-mode').length].join(','); };
  R.u4lien = essai(true); R.u4vrai = essai(false); }
// la valeur lue au démarrage reste celle de la mémoire
{ const f = pose('plan'); const m = M.creerMemoireMode({ fichier: f }); const a = m.lire(); fs.writeFileSync(f, 'acceptEdits\n'); R.u5 = [a, m.lire()]; }
// lecteur concurrent : un écrivain (autre processus) alterne 500 fois, le lecteur lit en boucle (cas « rapide » : omis, pour les mutants)
if (cas !== 'rapide') { const d = frais(), f = path.join(d, 'terminal-mode');
  const ecrivain = `import { pathToFileURL } from 'node:url'; const M = await import(pathToFileURL(${JSON.stringify(path.join(dir, 'vf-cockpit-lancer-mode.mjs'))}).href); const m = M.creerMemoireMode({ fichier: ${JSON.stringify(f)} }); for (let i = 0; i < 500; i++) m.ecrire(i % 2 ? 'plan' : 'acceptEdits');`;
  let fini = false; const c = spawn(process.execPath, ['--input-type=module', '-e', ecrivain], { stdio: 'ignore' }); c.on('exit', () => { fini = true; });
  const vus = new Set(); let lectures = 0, ko = 0; const fin = Date.now() + 60000;
  while (!fini && Date.now() < fin) { try { const t = fs.readFileSync(f, 'utf8'); lectures++; if (t === 'plan\n' || t === 'acceptEdits\n') vus.add(t.trim()); else ko++; } catch { /* pas encore créé */ } await new Promise((r) => setImmediate(r)); }
  R.u6 = { lectures, ko, vus: [...vus].sort().join(','), fini }; }
// ---- support du poste (AUDC-B-05) : clé, base, droits, dossiers forgés, ancien fichier jamais lu (un module sans ce support ne fait plus planter les faits U1 à U6 : perr)
try { const crypto = await import('node:crypto'); const sha = (c) => crypto.createHash('sha256').update(c, 'utf8').digest('hex').slice(0, 32);
  const racine = frais(), autre = frais(), lienRacine = path.join(frais(), 'lien'); fs.symlinkSync(racine, lienRacine);
  const rr = fs.realpathSync(racine), ra = fs.realpathSync(autre);
  R.p1 = { egalSha: M.cleProjet(racine) === sha(rr), long: M.cleProjet(racine).length, hex: /^[0-9a-f]{32}$/.test(M.cleProjet(racine)), autre: M.cleProjet(autre) !== M.cleProjet(racine), lien: M.cleProjet(lienRacine) === M.cleProjet(racine), absente: M.cleProjet(path.join(racine, 'nexiste-pas')), egalAutre: M.cleProjet(autre) === sha(ra) };
  const env = (base) => ({ VF_COCKPIT_MODE_DIR: base });
  const mode = (m) => (fs.statSync(m).mode & 0o777).toString(8);
  const base = path.join(frais(), 'etat'), dossier = path.join(base, M.cleProjet(racine)), fichier = path.join(dossier, 'terminal-mode');
  const m1 = M.creerMemoireModePoste({ racine, env: env(base) }); const w1 = m1.ecrire('acceptEdits');
  const m2 = M.creerMemoireModePoste({ racine, env: env(base) }); const mA = M.creerMemoireModePoste({ racine: autre, env: env(base) });
  R.p2 = { ecrit: w1, fichier: fs.existsSync(fichier), contenu: fs.readFileSync(fichier, 'utf8').trim(), permF: mode(fichier), permD: mode(dossier), permB: mode(base), relu: m2.lire(), autreProjet: mA.lire(), nomSansChemin: path.basename(dossier) === M.cleProjet(racine) && !dossier.endsWith(rr) && !fs.readdirSync(base).some((x) => x.includes(path.basename(rr))), aucunSousRacine: fs.readdirSync(racine).length };
  mA.ecrire('plan'); R.p2.deux = [M.creerMemoireModePoste({ racine, env: env(base) }).lire(), M.creerMemoireModePoste({ racine: autre, env: env(base) }).lire()].join(',');
  // l'ancien fichier du lab n'est jamais lu, ni retiré, ni réécrit
  { const lab = frais(), b = path.join(frais(), 'etat'); const vieux = path.join(lab, '.vibeflow', 'cockpit', '.cache', 'terminal-mode'); fs.mkdirSync(path.dirname(vieux), { recursive: true, mode: 0o700 }); fs.chmodSync(path.dirname(vieux), 0o700);
    const lus = ['herite', 'acceptEdits', 'plan'].map((v) => { fs.writeFileSync(vieux, v + '\n', { mode: 0o600 }); fs.chmodSync(vieux, 0o600); return M.creerMemoireModePoste({ racine: lab, env: env(b) }).lire(); });
    const memo = M.creerMemoireModePoste({ racine: lab, env: env(b) }); memo.ecrire('plan');
    R.p3 = { lus: lus.join(','), vieuxIntact: fs.readFileSync(vieux, 'utf8').trim(), vieuxDroits: mode(vieux), nouveau: fs.existsSync(path.join(b, M.cleProjet(lab), 'terminal-mode')) }; }
  // base forgée ou inutilisable : lecture default, écriture fausse, aucune exception, RIEN sous la racine du lab
  const essaiBase = (prepare) => { const lab = frais(), cible = frais(), b = path.join(frais(), 'etat'); const fe = prepare({ lab, cible, b }); const k = M.cleProjet(lab); let exc = 'aucune', w, lu; try { const m = M.creerMemoireModePoste({ racine: lab, env: env(b) }); lu = m.lire(); w = m.ecrire('acceptEdits'); } catch (e) { exc = e.message; }
    return [lu, w, exc, fs.readdirSync(lab).length, fs.readdirSync(cible).length, (() => { try { return fs.readFileSync(path.join(b, k || 'x', 'terminal-mode'), 'utf8').trim(); } catch { return 'absent'; } })()].join(','); };
  const poseValide = (b, k) => { fs.mkdirSync(path.join(b, k), { recursive: true, mode: 0o700 }); fs.chmodSync(b, 0o700); fs.chmodSync(path.join(b, k), 0o700); fs.writeFileSync(path.join(b, k, 'terminal-mode'), 'plan\n', { mode: 0o600 }); };
  R.p4 = {
    temoin: essaiBase(({ lab, b }) => { poseValide(b, M.cleProjet(lab)); }),
    baseLien: essaiBase(({ cible, b }) => { fs.symlinkSync(cible, b); }),
    baseLarge: essaiBase(({ lab, b }) => { poseValide(b, M.cleProjet(lab)); fs.chmodSync(b, 0o755); }),
    cleLien: essaiBase(({ lab, cible, b }) => { fs.mkdirSync(b, { mode: 0o700 }); fs.chmodSync(b, 0o700); fs.writeFileSync(path.join(cible, 'terminal-mode'), 'plan\n', { mode: 0o600 }); fs.symlinkSync(cible, path.join(b, M.cleProjet(lab))); }),
    cleLarge: essaiBase(({ lab, b }) => { poseValide(b, M.cleProjet(lab)); fs.chmodSync(path.join(b, M.cleProjet(lab)), 0o755); }),
    baseFichier: essaiBase(({ b }) => { fs.writeFileSync(b, 'x'); }),
    baseInscriptible: essaiBase(({ b }) => { fs.mkdirSync(b, { mode: 0o500 }); fs.chmodSync(b, 0o500); }),
  };
  for (const k of ['baseInscriptible']) { const fin = R.p4[k]; if (typeof process.getuid === 'function' && process.getuid() === 0) R.p4[k] = 'root:' + fin; }
  const relatif = M.creerMemoireModePoste({ racine, env: { VF_COCKPIT_MODE_DIR: 'relatif/etat' } }); R.p5 = { relatifLu: relatif.lire(), relatifEcrit: relatif.ecrire('plan'), racineAbsente: M.creerMemoireModePoste({ racine: path.join(racine, 'absente'), env: env(base) }).ecrire('plan'), sousRacine: fs.readdirSync(racine).length, sousCwd: fs.existsSync(path.join(process.cwd(), 'relatif')) };
  // convention : XDG_CACHE_HOME, puis $HOME/.cache, sous vibeflow/cockpit-mode ; XDG relatif ignoré ; surcharge prioritaire
  R.p6 = [M.baseEtat({ env: { XDG_CACHE_HOME: '/x/y', HOME: '/h' } }), M.baseEtat({ env: { HOME: '/h' } }), M.baseEtat({ env: { XDG_CACHE_HOME: 'rel', HOME: '/h' } }), M.baseEtat({ env: { VF_COCKPIT_MODE_DIR: '/s', XDG_CACHE_HOME: '/x', HOME: '/h' } }), M.baseEtat({ env: { VF_COCKPIT_MODE_DIR: 'rel', HOME: '/h' } })].join(' | ');
  // confinement (AUDC-B-05, correction ciblée) : base ET dossier du projet, jugés sur leur chemin RÉEL, jamais sous la racine réelle du lab ni égaux à elle, quelle que soit la source de la base
  const confine = (fab) => { const lab = frais(), hors = frais(), k = M.cleProjet(lab); const { env, dir } = fab({ lab, hors }); fs.mkdirSync(path.join(dir, k), { recursive: true, mode: 0o700 }); fs.chmodSync(dir, 0o700); fs.chmodSync(path.join(dir, k), 0o700);
    const f = path.join(dir, k, 'terminal-mode'); fs.writeFileSync(f, 'plan\n', { mode: 0o600 }); fs.chmodSync(f, 0o600);
    const m = M.creerMemoireModePoste({ racine: lab, env }); const lu = m.lire(), w = m.ecrire('acceptEdits'); return [lu, w, fs.readFileSync(f, 'utf8').trim()].join(','); };
  R.p7 = [
    confine(({ lab }) => ({ env: { VF_COCKPIT_MODE_DIR: path.join(lab, 'etat') }, dir: path.join(lab, 'etat') })),
    confine(({ lab }) => ({ env: { XDG_CACHE_HOME: path.join(lab, 'xdg'), HOME: '/nulle/part' }, dir: path.join(lab, 'xdg', 'vibeflow', 'cockpit-mode') })),
    confine(({ lab }) => ({ env: { HOME: path.join(lab, 'h') }, dir: path.join(lab, 'h', '.cache', 'vibeflow', 'cockpit-mode') })),
    confine(({ lab }) => ({ env: { VF_COCKPIT_MODE_DIR: lab }, dir: lab })),
    confine(({ lab, hors }) => { fs.mkdirSync(path.join(lab, 'reel'), { mode: 0o700 }); fs.symlinkSync(path.join(lab, 'reel'), path.join(hors, 'lien')); return { env: { VF_COCKPIT_MODE_DIR: path.join(hors, 'lien', 'sous') }, dir: path.join(lab, 'reel', 'sous') }; }),
    confine(({ hors }) => ({ env: { VF_COCKPIT_MODE_DIR: path.join(hors, 'etat') }, dir: path.join(hors, 'etat') })),
  ].join(' ');
  // clause « propriétaire » des dossiers d'état : lstat simulé d'un autre uid -> refus en lecture et en écriture ; le même uid -> accepté
  { const d = frais(), f = path.join(d, 'terminal-mode'); fs.writeFileSync(f, 'plan\n', { mode: 0o600 }); fs.chmodSync(f, 0o600); const mien = fs.lstatSync(d).uid;
    const autre = (uid) => ({ ...fs, lstatSync: (x, ...a) => { const st = fs.lstatSync(x, ...a); return x === d ? { isSymbolicLink: () => st.isSymbolicLink(), isDirectory: () => st.isDirectory(), uid, mode: st.mode } : st; } });
    const mu = (fsx) => { const m = M.creerMemoireMode({ fichier: f, fs: fsx }); return [m.lire(), m.ecrire('acceptEdits')].join(','); };
    R.p7uid = [mu(autre(mien + 1)), mu(autre(mien))].join('|'); }
  // ---- confinement par IDENTITÉ (AUDC-B-05, tour 2) : la garde ne dépend d'aucune forme textuelle de chemin
  const swap = (x) => x.split('').map((c) => (c === c.toUpperCase() ? c.toLowerCase() : c.toUpperCase())).join('');
  const sonde = frais(); R.fsci = swap(sonde) !== sonde && fs.existsSync(swap(sonde)); // système de fichiers insensible à la casse ?
  const labAcc = path.join(travail, 'é-' + process.pid + '-' + (++n)); fs.mkdirSync(labAcc, { mode: 0o700 }); R.nfdok = labAcc.normalize('NFD') !== labAcc && fs.existsSync(labAcc.normalize('NFD')); // insensible à la normalisation ?
  const prepose = (phys, lab) => { const k = M.cleProjet(lab); fs.mkdirSync(path.join(phys, k), { recursive: true, mode: 0o700 }); fs.chmodSync(phys, 0o700); fs.chmodSync(path.join(phys, k), 0o700); const f = path.join(phys, k, 'terminal-mode'); fs.writeFileSync(f, 'plan\n', { mode: 0o600 }); fs.chmodSync(f, 0o600); };
  const entrees = (lab) => fs.readdirSync(lab, { recursive: true }).length;
  const essai = (lab, baseStr, phys) => { if (phys) prepose(phys, lab); const avant = entrees(lab); const m = M.creerMemoireModePoste({ racine: lab, env: { VF_COCKPIT_MODE_DIR: baseStr } }); const lu = m.lire(), w = m.ecrire('acceptEdits'); return [lu, w, entrees(lab) - avant].join(','); };
  R.p8 = {};
  R.p8.casse = R.fsci ? [
    (() => { const lab = frais(); return essai(lab, swap(lab) + '/etat', lab + '/etat'); })(),
    (() => { const lab = path.join(frais(), 'sous'); fs.mkdirSync(lab, { mode: 0o700 }); return essai(lab, swap(path.dirname(lab)) + '/sous/etat', lab + '/etat'); })(),
  ].join(' ') : 'nonjouable';
  R.p8.nfd = R.nfdok ? essai(labAcc, (labAcc + '/etat').normalize('NFD'), labAcc + '/etat') : 'nonjouable';
  R.p8.freres = (() => { const par = frais(), lab = path.join(par, 'lab'), f1 = path.join(par, 'lab-frere'), f2 = path.join(par, 'labo'); for (const d of [lab, f1, f2]) fs.mkdirSync(d, { mode: 0o700 }); return [essai(lab, f1 + '/etat', null), essai(lab, f2 + '/etat', null)].join(' '); })();
  R.p8.illisible = (typeof process.getuid === 'function' && process.getuid() === 0) ? 'root' : (() => { const par = frais(), lab = path.join(par, 'lab'), ferme = path.join(par, 'ferme'); fs.mkdirSync(lab, { mode: 0o700 }); fs.mkdirSync(ferme, { mode: 0o700 }); fs.chmodSync(ferme, 0o000); try { return essai(lab, ferme + '/etat', null); } finally { fs.chmodSync(ferme, 0o700); } })();
  // nouveau jugement juste avant l'écriture : un ancêtre du support devient un lien vers l'intérieur du lab APRÈS le premier jugement (pendant la création des dossiers) ; aucun fichier ne doit être écrit
  { const lab = frais(), hors = frais(); fs.mkdirSync(path.join(lab, 'reel'), { mode: 0o700 }); const lien = path.join(hors, 'lien2');
    const fsx = { ...fs, mkdirSync: (d, o) => { if (!fs.existsSync(lien)) fs.symlinkSync(path.join(lab, 'reel'), lien); return fs.mkdirSync(d, o); } };
    const m = M.creerMemoireModePoste({ racine: lab, env: { VF_COCKPIT_MODE_DIR: path.join(lien, 'etat') }, fs: fsx }); const w = m.ecrire('acceptEdits');
    R.p8.rejuge = [w, fs.readdirSync(lab, { recursive: true }).filter((x) => path.basename(x).startsWith('terminal-mode')).length].join(','); }
  // premier jugement de ecrire : la base devient un lien vers l'intérieur du lab APRÈS la création de la mémoire et AVANT l'écriture : AUCUNE entrée (dossiers compris) ne doit apparaître sous le lab
  { const lab = frais(), hors = frais(); fs.mkdirSync(path.join(lab, 'reel'), { mode: 0o700 }); const lien = path.join(hors, 'lien3');
    const m = M.creerMemoireModePoste({ racine: lab, env: { VF_COCKPIT_MODE_DIR: path.join(lien, 'etat') } }); fs.symlinkSync(path.join(lab, 'reel'), lien);
    const avant = entrees(lab); const w = m.ecrire('acceptEdits'); R.p8.jug1 = [w, entrees(lab) - avant].join(','); }
  // preuve générative légère : graine fixe, formes de chemin vers l'intérieur du lab (casse par composant, NFC/NFD, `.`, `..`, lien d'ancêtre) et vers l'extérieur (frères à préfixe commun, cousins)
  { const GRAINE = 20261111, N = 60; let a = GRAINE; const rng = () => { a |= 0; a = (a + 0x6D2B79F5) | 0; let t = Math.imul(a ^ (a >>> 15), 1 | a); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; };
    const pick = (l) => l[Math.floor(rng() * l.length)];
    const casse = (x) => x.split('/').map((c) => pick([c, c.toUpperCase(), c.toLowerCase(), swap(c)])).join('/');
    const gen = path.join(travail, 'gen-' + process.pid + '-' + (++n)); fs.mkdirSync(gen, { mode: 0o700 });
    const G = { graine: GRAINE, n: N, dedans: 0, dehors: 0, formes: {}, ko: [] };
    for (let i = 0; i < N; i++) {
      const dedans = i % 2 === 0; const accent = rng() < 0.5; const lab = path.join(gen, (accent ? 'é' : 'l') + 'ab' + i); fs.mkdirSync(lab, { mode: 0o700 });
      let forme, base, phys = lab + '/etat', attendu;
      if (dedans) {
        forme = pick(['casse', 'nfd', 'point', 'pointpoint', 'lien', 'combo']); attendu = 'default,false,0';
        if (forme === 'casse' && !R.fsci) forme = 'point'; if (forme === 'combo' && !R.fsci) forme = 'pointpoint'; if (forme === 'nfd' && !(accent && R.nfdok)) forme = 'point';
        if (forme === 'casse') base = casse(lab) + '/etat'; else if (forme === 'nfd') base = (lab + '/etat').normalize('NFD'); else if (forme === 'point') base = lab + '/./etat';
        else if (forme === 'pointpoint') base = lab + '/etat/../etat'; else if (forme === 'combo') base = casse(lab) + '/./etat/../etat';
        else { const hors = path.join(gen, 'h' + i); fs.mkdirSync(hors, { mode: 0o700 }); fs.mkdirSync(path.join(lab, 'reel'), { mode: 0o700 }); fs.symlinkSync(path.join(lab, 'reel'), path.join(hors, 'l')); base = path.join(hors, 'l', 'etat'); phys = path.join(lab, 'reel', 'etat'); }
        G.dedans++;
      } else {
        forme = pick(['frere', 'cousin', 'prefixe', 'frere-casse']); attendu = 'default,true,0'; phys = null;
        let sib; if (forme === 'cousin') { const c = path.join(gen, 'c' + i); fs.mkdirSync(c, { mode: 0o700 }); sib = path.join(c, path.basename(lab)); } else sib = lab + (forme === 'prefixe' ? '-bis' : 'x');
        fs.mkdirSync(sib, { mode: 0o700 }); base = (forme === 'frere-casse' && R.fsci ? casse(sib) : sib) + '/etat'; G.dehors++;
      }
      G.formes[(dedans ? 'dedans/' : 'dehors/') + forme] = 1 + (G.formes[(dedans ? 'dedans/' : 'dehors/') + forme] || 0);
      const res = essai(lab, base, phys); if (res !== attendu) G.ko.push(i + ':' + (dedans ? 'dedans/' : 'dehors/') + forme + '=' + res);
    }
    R.gen = G; }
} catch (e) { R.perr = e.message; }
console.log(JSON.stringify(R));
JS
cat > "$AUX/borne.sh" <<'SH'
#!/usr/bin/env bash
# borne.sh <secondes> <commande...> : sortie de la commande, ou « TIMEOUT » si elle dépasse (la commande est alors tuée)
d="$1"; shift; out="$(mktemp)"; "$@" > "$out" 2>&1 & p=$!
for _ in $(seq 1 $((d * 10))); do kill -0 "$p" 2>/dev/null || break; sleep 0.1; done
if kill -0 "$p" 2>/dev/null; then kill -9 "$p" 2>/dev/null; echo TIMEOUT; else cat "$out"; fi; rm -f "$out"
SH
chmod +x "$AUX/borne.sh"
# cdoubles.mjs <client.mjs> : le client de Q joué sans navigateur (doublures de window, document, Terminal, fetch ; minuteur accéléré). Une ligne JSON de faits (LM.C).
cat > "$AUX/cdoubles.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
const [, , chemin] = process.argv;
const att = (ms) => new Promise((ok) => setTimeout(ok, ms));
const until = async (f, nom, ms = 3000) => { const fin = Date.now() + ms; for (;;) { if (f()) return; if (Date.now() > fin) throw new Error(`attente de « ${nom} » dépassée`); await att(10); } };
const el = () => ({ addEventListener() {}, setAttribute() {}, querySelector: () => null, classList: { add() {}, remove() {} }, style: {}, textContent: '' });
const J = { vue: [], stockage: [], journal: [] };
const memoire = () => { const m = new Map(); return { getItem: (k) => { J.stockage.push(['get', k]); return m.has(k) ? m.get(k) : null; }, setItem: (k, v) => { J.stockage.push(['set', k]); m.set(k, String(v)); }, removeItem: (k) => { J.stockage.push(['del', k]); m.delete(k); }, brut: (k, v) => { m.set(k, v); } }; };
globalThis.getComputedStyle = () => ({ paddingTop: '0', paddingBottom: '0' });
globalThis.localStorage = memoire(); globalThis.sessionStorage = memoire(); localStorage.brut('vf.terminal.secret', 'a'.repeat(64));
globalThis.window = { top: {}, opener: null, innerWidth: 800, innerHeight: 600, addEventListener() {}, parent: { postMessage() {} },
  vfTermVue: { theme: () => ({}), carte() {}, effacer() {}, bandeau() {}, collage() {}, invisible: () => false, proposition: (p, cb) => J.vue.push(p === null ? null : { p, cb }) } };
globalThis.document = { fonts: { load: () => Promise.resolve(), ready: Promise.resolve() }, getElementById: el, addEventListener() {} };
globalThis.location = { hash: '', pathname: '/', search: '' }; globalThis.history = { replaceState() {} }; globalThis.ResizeObserver = class { observe() {} }; globalThis.requestAnimationFrame = () => 0;
globalThis.FitAddon = { FitAddon: class { fit() {} } };
globalThis.Terminal = class { constructor() { this.rows = 24; this.cols = 80; this.parser = { registerDcsHandler() {} }; this.textarea = { addEventListener() {} }; } loadAddon() {} open() {} attachCustomKeyEventHandler() {} focus() {} write() {} paste() {} reset() {} resize() {} onData() {} onBinary() {} };
const realSI = globalThis.setInterval; globalThis.setInterval = (f, ms, ...a) => realSI(f, Math.max(5, Math.round(ms / 50)), ...a);
const ligne = (m) => `claude --session-id '5b9c2e0a-7d41-4f3a-9c58-0e1d2f3a4b5c' -n 'vf-phase-72-alpha' ${m ? `--permission-mode '${m}' ` : ''}'/vf-dev Planifie la Phase 72 du compartiment alpha'`;
const ID = (n) => ('p' + String(n)).padEnd(32, 'e');
const valide = (id, over = {}) => Object.assign({ etat: 'en-attente', id, verbe: 'planifier', intention: 'Planifie la Phase 72 du compartiment alpha', phase: '72', ws: 'alpha',
  lignes: { default: ligne('default'), acceptEdits: ligne('acceptEdits'), plan: ligne('plan'), herite: ligne('') }, bloquants: [], avertissements: [], arme_apres_ms: 1500, expire_ms: 100000, duree_ms: 120000 }, over);
const S = { prop: { etat: 'aucune' }, lancer: 204 };
const rep = (status, corps) => ({ status, ok: status >= 200 && status < 300, json: async () => corps, body: { getReader: () => ({ read: async () => ({ done: true }) }) } });
globalThis.fetch = (u, o = {}) => { const url = String(u); J.journal.push({ m: o.method || 'GET', u: url, b: typeof o.body === 'string' ? o.body : '' });
  if (url === '/proposition') return Promise.resolve(rep(200, JSON.parse(JSON.stringify(S.prop)))); if (url === '/lancer') return Promise.resolve(rep(S.lancer, null));
  if (url === '/flux') return new Promise(() => {}); return Promise.resolve(rep(204, null)); };
const m = (await import(pathToFileURL(process.env.HERE_T + '/navigateur-charger.mjs').href)).chargerFonctions([chemin]); // 79-11 : le client est un fichier du moteur
m.clientTerminal({ origineP: 'http://127.0.0.1:1', theme: 'dark' });
const nData = () => J.vue.filter(Boolean).length;
let k = 100; const afficher = async (over) => { const n = nData(); S.prop = valide(ID(++k), over); await until(() => nData() > n, 'affichage'); return J.vue.filter(Boolean).slice(-1)[0]; };
const servis = [['(absent)', undefined], ['bypassPermissions', 'bypassPermissions'], ['Plan', 'Plan'], ['nombre', 7], ['tableau', ['plan']], ['objet', { a: 1 }], ['__proto__', '__proto__'], ['constructor', 'constructor'], ['HERITE', 'HERITE'], ['default ', 'default '], ['x10000', 'x'.repeat(10000)], ['vide', '']];
const R = { forges: [] };
for (const [nom, v] of servis) { const over = v === undefined ? {} : { mode_retenu: v }; const r = await afficher(over); R.forges.push(nom + '=>' + r.p.modeInitial); }
R.valides = []; for (const v of ['default', 'acceptEdits', 'plan', 'herite']) { const r = await afficher({ mode_retenu: v }); R.valides.push(v + '=>' + r.p.modeInitial); }
// un lancement accepté (204), avec puis sans chat : corps de POST /lancer, stockage observé
const a = await afficher({ mode_retenu: 'plan' }); S.lancer = 204; R.st204 = await a.cb.lancer('plan'); S.prop = { etat: 'aucune' };
const corps1 = J.journal.filter((r) => r.u === '/lancer').map((r) => r.b);
const b = await afficher({ mode_retenu: 'plan', chat: true, lignes_chat: { default: ligne('default'), acceptEdits: ligne('acceptEdits'), plan: ligne('plan'), herite: ligne('') } }); S.lancer = 204; await b.cb.lancer('acceptEdits', true); S.prop = { etat: 'aucune' };
R.corps = J.journal.filter((r) => r.u === '/lancer').map((r) => r.b.replace(/"id":"[^"]*"/, '"id":"…"'));
for (const code of [409, 425, 400, 500]) { const c = await afficher({ mode_retenu: 'plan' }); S.lancer = code; await c.cb.lancer('plan'); S.prop = { etat: 'aucune' }; }
R.opsMode = J.stockage.filter((x) => /mode/i.test(x[1])).map((x) => x.join(':'));
R.secretLu = J.stockage.some((x) => x[0] === 'get' && x[1] === 'vf.terminal.secret');
R.corps1 = corps1;
console.log(JSON.stringify(R)); process.exit(0);
JS
cat > "$AUX/stat.mjs" <<'JS'
// stat.mjs <fichier-processus> <fichier-client> : faits statiques (LM.S3 à LM.S5) en une ligne JSON
import fs from 'node:fs';
const [, , proc, cli] = process.argv; const P = fs.readFileSync(proc, 'utf8'), C = fs.readFileSync(cli, 'utf8');
const m = /const routes = \{([^}]*)\}/.exec(P); const routes = m ? [...m[1].matchAll(/'([^']+)':\s*'([A-Z]+)'/g)].map((x) => x[1] + ':' + x[2]).sort().join(',') : 'introuvable';
const env = P.split('\n').filter((l) => /process\.send\(/.test(l));
const compte = (t, re) => (t.match(re) || []).length;
console.log(JSON.stringify({ routes, envoisMode: env.filter((l) => /mode/i.test(l)).length, envois: env.length,
  cliCleMode: compte(C, /vf\.terminal\.mode/g) + compte(C, /CLE_MODE/g), cliSession: compte(C, /sessionStorage/g), cliSecret: compte(C, /CLE_SECRET/g) }));
JS

# ---- shell de test, faux claude, lab jetable ----
cat > "$WORK/bin/rc" <<SH
PS1='VFP> '; unset PROMPT_COMMAND; bind 'set enable-bracketed-paste off' 2>/dev/null
PATH="$WORK/fauxbin:\$PATH"; export PATH
SH
cat > "$WORK/bin/shell-test" <<SH
#!/bin/sh
echo \$\$ > "$RUN/shell.pid"
exec /bin/bash --rcfile "$WORK/bin/rc" -i
SH
cat > "$WORK/fauxbin/claude" <<SH
#!/bin/sh
printf '%s\\0' "\$@" > "$RUN/argv.tmp" && mv "$RUN/argv.tmp" "$RUN/argv"
SH
chmod +x "$WORK/bin/shell-test" "$WORK/fauxbin/claude"; cp "$HERE_T/temoins/hostile.py" "$WORK/temoins/hostile.py"
export SHELL="$WORK/bin/shell-test"
rq() { node "$TA" req "$@"; }
sta() { rq "$@" | sed -n 1p; }
evj() { node "$AUX/ev.mjs" "$1"; }
mklab() { local L="$1" B="$1/.planning"; mkdir -p "$L/src" "$B/phases/01-socle"; printf 'export const u = 1;\n' > "$L/src/u.js"
  printf -- '## Phases\n\n- [ ] **Phase 1: Socle** - premier jet\n\n### Phase 1: Socle\n**Goal**: Poser le socle\n' > "$B/ROADMAP.md"
  printf -- '---\nstatus: executing\ncurrent_phase: 1\nmilestone: v1.0 MVP\n---\n' > "$B/STATE.md"
  printf -- '---\nwave: 1\nfiles_modified: [src/u.js]\n---\n<objective>Poser le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  node "$SCRIPTS/vf-cockpit.mjs" build --lab "$L" > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"; }
cle_de() { node -e "console.log(require('crypto').createHash('sha256').update(require('fs').realpathSync(process.argv[1]),'utf8').digest('hex').slice(0,32))" "$1"; } # dérivation INDÉPENDANTE du module (le contrat : sha256 du chemin réel, 32 hexadécimaux)
fm_de() { echo "$STATE/$(cle_de "$1")/terminal-mode"; }
LAB="$WORK/lab"; mklab "$LAB"; OUT="$LAB/.vibeflow/cockpit"; FM="$(fm_de "$LAB")"; FM_VIEUX="$OUT/.cache/terminal-mode" # FM_VIEUX : l'ancien emplacement (dans le lab), plus jamais lu
etat_dirs() { local d; d="$(dirname "${1:-$FM}")"; mkdir -p "$STATE" "$d"; chmod 700 "$STATE" "$d"; } # dossiers du support, posés comme Q les poserait (0700)
lab_liste() { /usr/bin/find "$1" -path "$1/.git" -prune -o -print | sort; } # tout ce qui existe sous le lab (hors .git)
etat_liste() { /usr/bin/find "$STATE" 2>/dev/null | sort | tr '\n' ';'; }
# mutant <nom> <fichier-du-module> <expression-sed>... -> MUT_OUT (sortie : données et chemin dont dérive la clé du mode retenu) + MUT_MOD (copie du module muté) ; code 1 si le module manque, la cible manque ou la copie n'a pas changé
mutant() {
  [ "$MODULE_OK" = 1 ] || return 1 # tant que le module n'existe pas, aucun mutant ne se joue (« non jouée : module absent »)
  local d="$WORK/mut-$1" e x=""; local nom="$1" cible="$2"; shift 2; rm -rf "$d"; mkdir -p "$d"; cp -R "$LAB/.planning" "$d/.planning"; cp -R "$LAB/.vibeflow" "$d/.vibeflow"
  MUT_OUT="$d/.vibeflow/cockpit"; MUT_MOD=""
  for e in "$@"; do x="${x:+$x
}$e"; done
  cockpit_module_muter "$nom" "$cible" "$x" || return 1
  MUT_MOD="$COCKPIT_MODULE"; unset COCKPIT_MODULE; return 0
}
# sans_effet <nom> : « module absent » tant que le module n'existe pas (non jouée), sinon FAIL « mutant sans effet »
sans_effet() { if [ "$MODULE_OK" = 0 ]; then nonjouee "$1" "module absent"; else assert_eq "$1 — mutant sans effet (ancre absente ou inchangée)" "sans effet" "effet"; fi; }
# faits U : un module (dossier) -> JSON ; module absent : { erreur }
facts_u() { local c; c="$(mod_de "$1")"; if [ -f "$c/vf-cockpit-lancer-mode.mjs" ]; then node "$AUX/u.mjs" "$c" "$WORK/u" "${2:-tout}" 2>&1 | tail -1; else echo '{"erreur":"module absent"}'; fi; }
uq() { printf '%s\n' "$1" | node "$AUX/ev.mjs" "(j.erreur ? 'plante: ' + j.erreur : ($2))" 2>/dev/null || echo "illisible"; }
fifo_u() { local c; c="$(mod_de "$1")"; if [ -f "$c/vf-cockpit-lancer-mode.mjs" ]; then "$AUX/borne.sh" 20 node "$AUX/u.mjs" "$c" "$WORK/u" fifo | tail -1; else echo '{"erreur":"module absent"}'; fi; }
# faits client : (dossier-du-client) -> JSON des doublures
facts_c() { node "$AUX/cdoubles.mjs" "$(mod_de "$1")/../skills/cockpit-moteur/assets/ui/terminal/client.js" 2>&1 | tail -1; }
cq() { uq "$1" "$2"; }
uqp() { uq "$1" "(j.perr ? 'plante: ' + j.perr : ($2))"; } # faits du support du poste (LM.U7 à LM.U12) : la cause de l'échec reste lisible
PLANPUR='plan'

echo "=== LM.S — statique : module, frontière de P, routes de Q, client, IPC, journal ==="
if [ "$MODULE_OK" = 1 ]; then
  assert_eq "LM.S1 — vf-cockpit-lancer-mode.mjs exporte FICHIER_MODE === 'terminal-mode' et MODES (les quatre mots du gabarit)" "$(node --input-type=module -e "const m = await import('$MOD'); console.log(m.FICHIER_MODE + '/' + m.MODES.join(','))" 2>&1 | tail -1)" "terminal-mode/default,acceptEdits,plan,herite"
else assert_eq "LM.S1 — vf-cockpit-lancer-mode.mjs existe et exporte FICHIER_MODE === 'terminal-mode' (module absent)" "absent" "terminal-mode"; fi
# fichiers côté P : TOUS les .mjs du module cockpit (scripts et moteur, hors tests) sauf le module lui-même et son seul importeur ; liste dérivée, jamais tenue à la main
p_refs() { # p_refs <dossier> -> « <nombre de fichiers examinés>:<nombre de références à terminal-mode ou lancer-mode hors module et importeur> »
  local n=0 r=0 f b; while IFS= read -r f; do b="$(basename "$f")"; case "$b" in vf-cockpit-lancer-mode.mjs|vf-cockpit-terminal-processus.mjs) continue ;; esac
    n=$((n+1)); r=$((r + $(grep -c -e 'terminal-mode' -e 'lancer-mode' "$f" | tr -d ' '))); done < <(/usr/bin/find "$(racine_de "$1")" -name '*.mjs' -not -path '*/tests/*' -not -path '*/node_modules/*' | sort); echo "$n:$r"
}
importeurs() { local f; while IFS= read -r f; do grep -q "from './vf-cockpit-lancer-mode.mjs'" "$f" && basename "$f"; done < <(/usr/bin/find "$1" -name '*.mjs' -not -path '*/tests/*' | sort) | sort | tr '\n' ',' ; }
if [ "$MODULE_OK" = 1 ]; then
  PR="$(p_refs "$COCKPIT")"
  assert_eq "LM.S2 — frontière statique : aucun fichier côté P ne nomme terminal-mode ni lancer-mode (témoin : au moins 15 fichiers examinés, liste dérivée par find)" "$([ "${PR%%:*}" -ge 15 ] && echo "assez:${PR##*:}" || echo "trop peu (${PR%%:*}):${PR##*:}")" "assez:0"
  assert_eq "LM.S2 — le seul importeur du module est vf-cockpit-terminal-processus.mjs (égalité d'ensemble ; témoin : le processus nomme bien le module)" "$(importeurs "$COCKPIT") $([ "$(grep -c 'lancer-mode' "$SCRIPTS/vf-cockpit-terminal-processus.mjs" | tr -d ' ')" -ge 1 ] && echo nomme)" "vf-cockpit-terminal-processus.mjs, nomme"
else nonjouee "LM.S2" "module absent (elle s'écrit avec le module)"; fi
# LM.S7 : la ligne garde:mode-support du processus (code, sans le commentaire) ne nomme ni la sortie (here), ni .cache, ni FICHIER_MODE : le support n'est plus dans le lab
SUPPORT_CODE="$(grep 'garde:mode-support' "$SCRIPTS/vf-cockpit-terminal-processus.mjs" | sed 's#//.*##')"
assert_eq "LM.S7 — la ligne garde:mode-support (code, hors commentaire) construit le support du poste par la racine seule : ni here, ni .cache, ni FICHIER_MODE, ni path.join (témoin : la ligne existe et appelle creerMemoireModePoste)" "$(printf '%s' "$SUPPORT_CODE" | grep -c -E 'here|\.cache|FICHIER_MODE|path\.join' | tr -d ' ') $(printf '%s' "$SUPPORT_CODE" | grep -c 'creerMemoireModePoste' | tr -d ' ')" "0 1"
SF="$(node "$AUX/stat.mjs" "$SCRIPTS/vf-cockpit-terminal-processus.mjs" "$ENG/assets/ui/terminal/client.js")"
ROUTES_BASE='/amorce:POST,/annuler:POST,/entree:POST,/etat:GET,/flux:GET,/lancer:POST,/proposition:GET,/taille:POST'
if [ "$MODULE_OK" = 1 ]; then assert_eq "LM.S3 — la table fermée routes de Q : mêmes clés et méthodes que la base (huit routes, aucune de plus)" "$(uq "$SF" j.routes)" "$ROUTES_BASE"
else nonjouee "LM.S3" "module absent"; fi
assert_eq "LM.S4 — le client ne contient plus vf.terminal.mode ni CLE_MODE (0 occurrence) ; il garde sessionStorage et CLE_SECRET (témoins : au moins 1 chacun)" "$(uq "$SF" 'j.cliCleMode + "/" + (j.cliSession >= 1) + "/" + (j.cliSecret >= 1)')" "0/true/true"
if [ "$MODULE_OK" = 1 ]; then
  assert_eq "LM.S5 — le processus n'envoie le mode par aucun process.send( (0 ligne d'envoi portant « mode » ; témoin : au moins 2 envois)" "$(uq "$SF" '(j.envois >= 2 ? "assez" : "trop peu") + ":" + j.envoisMode')" "assez:0"
  assert_eq "LM.S6 — aucune ligne console.error( ou log( du module n'interpole une valeur ni une erreur (accolade-dollar, String(, .message : 0) ; témoin : le module journalise au moins une fois" "$(g="$(grep -E 'console\.error\(|\blog\(' "$MOD")"; echo "$(printf '%s\n' "$g" | grep -c -E '\$\{|String\(|\.message' | tr -d ' ') $([ -n "$g" ] && echo journalise || echo muet)")" "0 journalise"
else nonjouee "LM.S5 / LM.S6" "module absent"; fi

echo "=== LM.U — le module (node pur, doublures de fs) ==="
UF="$(facts_u "$SCRIPTS")"
assert_eq "LM.U1 — témoin : fichier valide « plan » -> plan ; fichier absent -> default ; « plan » + un retour à la ligne -> plan" "$(uq "$UF" 'j.u1.join(",")')" "plan,default,plan"
assert_eq "LM.U2 — dix-sept contenus forgés (bypassPermissions, Plan, PLAN, plan plan, plan\\nplan, plan\\0, vide, un retour à la ligne, JSON, tableau JSON, __proto__, constructor, toString, 33 octets, 4096 octets, plan+28 octets, non UTF-8) : tous default, aucune exception" "$(uq "$UF" 'j.u2.length + ":" + j.u2.filter((x) => x === "default").length')" "17:17"
assert_eq "LM.U2 — mot valide entouré de blancs (' plan', 'plan ', 'plan \\n', 'plan\\n\\n', 'plan\\r\\n', '\\nplan') : tous default ; 'plan\\n' et 'plan' : plan" "$(uq "$UF" 'j.u2blancs.join(",") + "|" + j.u2fin.join(",")')" "default,default,default,default,default,default|plan,plan"
assert_eq "LM.U2 — un BOM devant le mot (EF BB BF + plan) : default (égalité stricte)" "$(uq "$UF" 'j.u2bom')" "default"
assert_eq "LM.U4 — .cache devenu un lien vers un autre dossier : ecrire rend false, sans exception, le dossier visé reste vide, rien n'est écrit ; témoin : un vrai dossier -> true, écrit" "$(uq "$UF" 'j.u4lien + "|" + j.u4vrai')" "false,aucune,0,0|true,aucune,0,1"
assert_eq "LM.U2 — borne de taille avant toute lecture : un fstat annonçant 4096 octets rend default SANS aucun readSync (témoin : la même doublure sur la taille réelle lit une fois et rend plan)" "$(uq "$UF" 'j.u2taille.join(",")')" "default,0,plan,1"
assert_eq "LM.U3 — fichier d'un autre propriétaire (fstat simulé, la vraie situation exige un privilège : non jouable sans lui) -> default ; le vrai propriétaire -> plan" "$(uq "$UF" 'j.u3uid.join(",")')" "default,plan"
assert_eq "LM.U3 — lien symbolique vers un fichier plan valide -> default ; répertoire -> default" "$(uq "$UF" 'j.u3lien + "," + j.u3dossier')" "default,default"
assert_eq "LM.U3 — droits 0644, 0660, 0640 -> default ; 0600, 0400 -> plan" "$(uq "$UF" 'j.u3droits.join(",")')" "default,default,default,plan,plan"
FU="$(fifo_u "$SCRIPTS")"
assert_eq "LM.U3 — FIFO à l'emplacement du fichier -> default SANS bloquer (échéance de 20 s)" "$(uq "$FU" 'j.fifo')" "default"
assert_eq "LM.U4 — écriture : le temporaire s'ouvre en wx droits 0600 dans le MÊME dossier que la cible, UN rename(temporaire, cible), au moins une écriture, AUCUNE ouverture ni écriture de la cible ; fichier final 0600 portant le seul mot, aucun reste" "$(uq "$UF" '[j.u4.rend, j.u4.lu, j.u4.contenu.trim(), j.u4.perm, j.u4.ouvertTemp, j.u4.renomme, j.u4.ecrit, j.u4.cibleEcrite, j.u4.restes].join("/")')" "true/plan/plan/600/true/true/true/false/terminal-mode"
assert_eq "LM.U4 — échec du rename : le temporaire est retiré (aucun reste, aucune cible), ecrire rend faux, lire() rend tout de même la nouvelle valeur, aucune exception" "$(uq "$UF" '[j.u4rename.rend, j.u4rename.exc, j.u4rename.lu, j.u4rename.restes === "", j.u4rename.cible].join("/")')" "false/aucune/plan/true/false"
assert_eq "LM.U4 — ecrire(bypassPermissions | toString | 42 | undefined | null | Plan | tableau) : faux, AUCUN appel de fs, mémoire inchangée (default), aucun fichier" "$(uq "$UF" '[j.u4hors.rend, j.u4hors.appels, j.u4hors.lu, j.u4hors.existe].join("/")')" "false,false,false,false,false,false,false/0/default/false"
assert_eq "LM.U5 — la valeur lue au démarrage reste celle de la mémoire : fichier réécrit de l'extérieur après la création, lire() inchangé" "$(uq "$UF" 'j.u5.join(",")')" "plan,plan"
assert_eq "LM.U6 — lecteur concurrent pendant 500 écritures alternées (deux processus) : chaque lecture vaut plan ou acceptEdits, jamais vide ni autre chose (témoin : au moins 100 lectures réussies, les deux valeurs vues)" "$(uq "$UF" '[j.u6.fini, j.u6.lectures >= 100, j.u6.ko, j.u6.vus].join("/")')" "true/true/0/acceptEdits,plan"
assert_eq "LM.U7 — clé du projet : sha256 du chemin RÉEL (calculé ici indépendamment), 32 hexadécimaux, deux dossiers -> deux clés, un lien vers le dossier -> la même clé, racine absente -> null" "$(uqp "$UF" '[j.p1.egalSha, j.p1.long, j.p1.hex, j.p1.autre, j.p1.lien, String(j.p1.absente), j.p1.egalAutre].join("/")')" "true/32/true/true/true/null/true"
assert_eq "LM.U8 — support du poste : <base>/<clé>/terminal-mode créé par l'écriture, fichier 0600, dossier du projet 0700, base 0700 (créée) ; relu par une autre mémoire ; l'autre projet ne le voit pas ; le nom du dossier n'est pas le chemin ; rien sous la racine ; deux projets gardent chacun leur mot" "$(uqp "$UF" '[j.p2.ecrit, j.p2.fichier, j.p2.contenu, j.p2.permF, j.p2.permD, j.p2.permB, j.p2.relu, j.p2.autreProjet, j.p2.nomSansChemin, j.p2.aucunSousRacine, j.p2.deux].join("/")')" "true/true/acceptEdits/600/700/700/acceptEdits/default/true/0/acceptEdits,plan"
assert_eq "LM.U9 — l'ancien <sortie>/.cache/terminal-mode (herite, acceptEdits, plan ; 0600) n'est JAMAIS lu : default ; une écriture ne le retire ni ne le réécrit (contenu et droits inchangés) et crée bien le nouveau fichier" "$(uqp "$UF" 'j.p3.lus + "/" + j.p3.vieuxIntact + "/" + j.p3.vieuxDroits + "/" + j.p3.nouveau')" "default,default,default/plan/600/true"
assert_eq "LM.U10 — dossier d'état forgé ou inutilisable (lecture, écriture, exception, entrées du lab, entrées de la cible, contenu du fichier du projet après coup) : témoin valide -> plan,true puis acceptEdits ; base lien -> default,false ; base 0755 -> default,false, contenu intact ; dossier du projet = lien -> default,false, cible intacte ; dossier du projet 0755 -> default,false ; base = fichier ordinaire ; base 0500 -> default,false ; jamais d'exception, jamais rien sous le lab" "$(uqp "$UF" 'Object.values(j.p4).map((x) => x.replace(/^root:/, "")).join(" ")')" "plan,true,aucune,0,0,acceptEdits default,false,aucune,0,0,absent default,false,aucune,0,0,plan default,false,aucune,0,1,plan default,false,aucune,0,0,plan default,false,aucune,0,0,absent default,false,aucune,0,0,absent"
assert_eq "LM.U11 — base relative (surcharge) -> aucun support : default, écriture fausse, rien sous la racine ni dans le dossier courant ; racine introuvable -> écriture fausse" "$(uqp "$UF" '[j.p5.relatifLu, j.p5.relatifEcrit, j.p5.racineAbsente, j.p5.sousRacine, j.p5.sousCwd].join("/")')" "default/false/false/0/false"
assert_eq "LM.U12 — convention de base : XDG_CACHE_HOME/vibeflow/cockpit-mode, sinon HOME/.cache/vibeflow/cockpit-mode, XDG relatif ignoré, surcharge VF_COCKPIT_MODE_DIR prioritaire, surcharge relative -> aucune base" "$(uqp "$UF" 'j.p6 + "<fin>"')" "/x/y/vibeflow/cockpit-mode | /h/.cache/vibeflow/cockpit-mode | /h/.cache/vibeflow/cockpit-mode | /s | <fin>"
assert_eq "LM.U13 — confinement : base sous le lab par la surcharge, par XDG_CACHE_HOME, par HOME, base égale à la racine, base atteinte par un lien d'un ancêtre vers l'intérieur du lab (fichier plan préposé) : default, écriture fausse, fichier préposé intact ; témoin : base hors du lab -> plan, true, acceptEdits" "$(uqp "$UF" 'j.p7')" "default,false,plan default,false,plan default,false,plan default,false,plan default,false,plan plan,true,acceptEdits"
assert_eq "LM.U14 — clause propriétaire du dossier d'état : lstat simulé d'un autre uid -> default et écriture fausse ; le même uid -> plan, true (témoin)" "$(uqp "$UF" 'j.p7uid')" "default,false|plan,true"
FSCI="$(uqp "$UF" 'j.fsci')"; NFDOK="$(uqp "$UF" 'j.nfdok')"
assert_eq "LM.U15 — confinement par identité, casse : base sous le lab écrite dans une autre casse (chemin entier, puis un ancêtre du lab seul) : default, écriture fausse, 0 entrée créée sous le lab (système de fichiers insensible à la casse : $FSCI ; sinon non jouable, dit)" "$(uqp "$UF" 'j.p8.casse')" "$([ "$FSCI" = true ] && echo 'default,false,0 default,false,0' || echo nonjouable)"
assert_eq "LM.U15 — confinement par identité, Unicode : base en NFD face à un lab accentué : default, écriture fausse, 0 entrée créée (insensible à la normalisation : $NFDOK ; sinon non jouable, dit)" "$(uqp "$UF" 'j.p8.nfd')" "$([ "$NFDOK" = true ] && echo 'default,false,0' || echo nonjouable)"
assert_eq "LM.U15 — frontière de composant : un frère dont le nom commence comme le lab (lab-frere, labo) est ACCEPTÉ (support écrit hors du lab, 0 entrée sous le lab)" "$(uqp "$UF" 'j.p8.freres')" "default,true,0 default,true,0"
assert_eq "LM.U15 — un ancêtre illisible (stat refusée) : aucun support, default, écriture fausse, 0 entrée sous le lab" "$(uqp "$UF" 'j.p8.illisible')" "$([ "$(id -u)" = 0 ] && echo root || echo 'default,false,0')"
assert_eq "LM.U16 — nouveau jugement avant l'écriture : un ancêtre du support devient un lien vers l'intérieur du lab pendant la création des dossiers : écriture fausse, aucun fichier terminal-mode sous le lab" "$(uqp "$UF" 'j.p8.rejuge')" "false,0"
assert_eq "LM.U17 — preuve générative (graine 20261111, 60 cas alternés dedans/dehors : casse par composant, NFC/NFD, point, point-point, lien d'ancêtre ; frères à préfixe, cousins) : dedans -> default, écriture fausse, 0 entrée créée sous le lab ; dehors -> support accepté ; aucun écart" "$(uqp "$UF" 'j.gen.graine + "/" + j.gen.n + "/" + (j.gen.dedans >= 25) + "/" + (j.gen.dehors >= 25) + "/" + (Object.keys(j.gen.formes).length >= 6) + "/" + j.gen.ko.join(";")')" "20261111/60/true/true/true/"
assert_eq "LM.U16 — premier jugement de l'écriture : la base devient un lien vers l'intérieur du lab entre la création de la mémoire et l'écriture : écriture fausse et AUCUNE entrée créée sous le lab, dossiers compris" "$(uqp "$UF" 'j.p8.jug1')" "false,0"

echo "=== LM.C — client (doublures Node) : présélection servie, stockage du navigateur hors du chemin du mode ==="
CF="$(facts_c "$SCRIPTS")"
C2EXPR='j.forges.length === 12 && j.forges.every((x) => x.endsWith("=>default")) && j.valides[2] === "plan=>plan"'
C3EXPR='j.opsMode.length + "/" + j.secretLu'
assert_eq "LM.C1 — mode_retenu servi (default, acceptEdits, plan, herite) : vue.proposition reçoit modeInitial égal" "$(cq "$CF" 'j.valides.join(",")')" "default=>default,acceptEdits=>acceptEdits,plan=>plan,herite=>herite"
assert_eq "LM.C2 — mode_retenu absent, bypassPermissions, Plan, nombre, tableau, objet, __proto__, constructor, HERITE, « default », 10000 caractères, vide : modeInitial default (témoin positif : plan servi donne plan)" "$(cq "$CF" "$C2EXPR")" "true"
assert_eq "LM.C3 — AUCUN getItem, setItem ni removeItem sur une clé contenant « mode », avant, pendant ni après un POST /lancer 204 (ni après 409, 425, 400, 500) ; témoin : le secret, lui, est lu" "$(cq "$CF" "$C3EXPR")" "0/true"
assert_eq "LM.C4 — le corps de POST /lancer reste exactement { id, mode } (chat:true seulement s'il est coché) ; le 204 rend ok" "$(cq "$CF" 'j.st204 + "|" + j.corps.slice(0, 2).join("|")')" 'ok|{"id":"…","mode":"plan"}|{"id":"…","mode":"acceptEdits","chat":true}'

echo "=== LM.G — le support n'est pas dans le lab : build rejoué, ancien fichier laissé, purge de serve.mjs ==="
mkdir -p "$OUT/.cache"; printf 'herite\n' > "$FM_VIEUX"; chmod 600 "$FM_VIEUX"; etat_dirs; printf 'plan\n' > "$FM"; chmod 600 "$FM"
node "$SCRIPTS/vf-cockpit.mjs" build --lab "$LAB" > "$WORK/build2.out" 2>&1
assert_eq "LM.G2 — build REJOUÉ sur ce lab : le fichier du poste existe encore (plan) ; l'ancien fichier du lab, lui, n'est ni lu ni retiré par le build (herite, 0600)" "$(cat "$FM" 2>/dev/null | tr -d '\n') $(cat "$FM_VIEUX" 2>/dev/null | tr -d '\n') $(node -e "console.log((require('fs').statSync(process.argv[1]).mode & 0o777).toString(8))" "$FM_VIEUX" 2>/dev/null)" "plan herite 600"
SERVE="$COCKPIT/skills/cockpit-moteur/assets/serve.mjs"
assert_eq "LM.G3 — serve.mjs : aucun rmSync du dossier .cache entier (0) ; sa purge nomme skill.json et history (témoins : 1 et 1)" "$(grep -c "rmSync(path.join(here, '.cache')" "$SERVE" | tr -d ' ') $(grep -c "rmSync(path.join(here, '.cache', 'skill.json')" "$SERVE" | tr -d ' ') $(grep -c "rmSync(historyDir" "$SERVE" | tr -d ' ')" "0 1 1"
rm -f "$FM" "$FM_VIEUX"

# ---- manche : un parent sur la sortie voulue, amorçage, [flux de l'onglet A, invite] ----
NM=0; QP=0; CP=0; PP=0; SECRET=""; PARENT=""; FPID=""; FLUX=""; QPID=""; ARME=2000
manche_debut() { # manche_debut <sortie> [sans-flux] -> QP CP PP SECRET PARENT QPID FPID FLUX
  NM=$((NM+1)); local s="$1" am="$WORK/amorce.$NM" po="$WORK/parent-$NM.out"; FLUX="$WORK/flux-$NM.out"; : > "$FLUX"; FPID=""; rm -f "$RUN/argv" "$RUN/argv.tmp" "$RUN/recept.hex"; mkdir -p "$s/.cache"
  node -e "console.log(require('crypto').randomBytes(24).toString('hex'))" > "$am.tmp"; (umask 077; tr -d '\n' < "$am.tmp" > "$s/.cache/terminal-amorce"; tr -d '\n' < "$am.tmp" > "$am")
  VF_COCKPIT_LANCER_ARME_MS=$ARME node "$AUX/parent.mjs" "$s" "${MLAB:-$LAB}" "$(eng_de "$s")" "$WORK" "$(scripts_de "$s")" > "$po" 2>&1 < /dev/null & PARENT=$!; PIDS+=($PARENT)
  for _ in $(seq 1 100); do grep -q '^PRET ' "$po" 2>/dev/null && break; sleep 0.1; done
  read -r _ QP CP PP < <(grep '^PRET ' "$po" | head -1); QP="${QP:-0}"; CP="${CP:-0}"; PP="${PP:-0}"
  QPID="$(command pgrep -P "$PARENT" | head -1)"
  SECRET="$(node "$TA" amorcer "$QP" "$am" | sed -n 2p)"
  if [ "${2:-}" != sans-flux ]; then
    node "$TA" flux "$QP" "$SECRET" A "$FLUX" 150000 --taille 24x400 > "$WORK/flux-$NM.log" 2>&1 & FPID=$!; PIDS+=($FPID)
    node "$TA" attendre "$FLUX" 'VFP> ' 10000 > /dev/null
  fi
}
manche_fin() { [ -n "$FPID" ] && vf_hyg_stop "$FPID"; vf_hyg_stop "$PARENT"; for _ in $(seq 1 30); do [ -z "$(vf_hyg_vivants)" ] && break; sleep 0.2; done; }
pget() { rq "$QP" GET /proposition --sans-origin --entete 'sec-fetch-site:same-origin' --secret "$SECRET" --onglet "${ONG:-A}" "$@"; }
pbody() { pget "$@" | sed '1,2d'; }
plx() { local sec="$1" ong="$2" corps="$3"; shift 3; rq "$QP" POST /lancer --secret "$sec" --onglet "$ong" --corps "$corps" "$@"; }
pl() { local c="$1"; shift; plx "$SECRET" A "$c" "$@" | sed -n 1p; }
lj() { printf '{"id":"%s","mode":"%s"%s}' "$1" "$2" "${3:-}"; }
envoyer() { rq "$CP" POST /send --corps "$1" | sed -n 1p; sleep 0.2; }
prop() { printf '{"t":"proposition","cible":"%s","verbe":"%s","bloquants":[],"avertissements":[]%s}' "$1" "$2" "${3:-}"; }
recus() { rq "$CP" GET /recus | sed '1,2d'; }
attente_arme() { sleep "$(node -e "console.log(($1 + 300) / 1000)")"; }
CIBLES='{"t":"cibles","cibles":[{"id":"ph-1","kind":"phase","verbe":"cadrer","verbes":["cadrer","planifier","executer"],"phase":"1","ws":"fiabilite"}]}'
ID=""; ARME_LU=0
proposer() { envoyer "$CIBLES" > /dev/null; envoyer "$(prop ph-1 cadrer)" > /dev/null; local b; b="$(pbody)"; ID="$(printf '%s' "$b" | evj 'j.id' 2>/dev/null)"; ARME_LU="$(printf '%s' "$b" | evj 'j.arme_apres_ms' 2>/dev/null)"; ARME_LU="${ARME_LU:-2000}"; }
mode_servi() { pbody | evj 'j.etat === "en-attente" ? j.mode_retenu : "(" + j.etat + ")"' 2>/dev/null; }
sigf() { node "$AUX/sigf.mjs" "$FM"; }
pose_mode() { etat_dirs; rm -f "$FM"; printf '%s' "$1" > "$FM"; chmod "${2:-600}" "$FM"; }
sigfacts() { printf '%s' "$1" | evj "$2" 2>/dev/null; }
attendre_q_sortie() { local i; for i in $(seq 1 80); do kill -0 "$1" 2>/dev/null || return 0; sleep 0.2; done; return 1; }

echo "=== LM.Q — le processus de Q réel : survie, forge, écriture seulement sur un lancement accepté ==="
SHPID_LU() { cat "$RUN/shell.pid" 2>/dev/null; }
rm -f "$FM"; manche_debut "$OUT"
assert_eq "LM.Q0 — témoin : parent, Q prête (ports distincts, jamais 4456), amorçage (secret de 64 hexadécimaux), invite VFP> atteinte, GET /proposition rend aucune" "$([ "$QP" -ge 4600 ] && [ "$QP" != 4456 ] && [ "$QP" != "$PP" ] && echo ports) $([[ "$SECRET" =~ ^[0-9a-f]{64}$ ]] && echo secret) $(grep -c 'VFP> ' "$FLUX" | tr -d ' ' | sed 's/^[1-9][0-9]*$/invite/') $(pbody)" 'ports secret invite {"etat":"aucune"}'
assert_eq "LM.Q1 — premier démarrage (aucun fichier) : la réponse aucune n'a QUE la clé etat (pas de mode_retenu)" "$(pbody | evj 'Object.keys(j).join(",")')" "etat"
proposer; BQ="$(pbody)"
assert_eq "LM.Q1 — premier démarrage, aucun fichier : mode_retenu vaut default (témoin : la proposition est en attente)" "$(printf '%s' "$BQ" | evj 'j.etat + "/" + j.mode_retenu')" "en-attente/default"
assert_eq "LM.Q2 — clés de la réponse en-attente = celles du contrat §4 plus mode_retenu (égalité d'ensemble)" "$(printf '%s' "$BQ" | evj 'Object.keys(j).sort().join(",")')" "arme_apres_ms,avertissements,bloquants,duree_ms,etat,expire_ms,id,intention,lignes,mode_retenu,phase,verbe,ws"
# LM.Q6 : le fichier est posé à « plan » ; aucune requête refusée ne le touche (inode, date, droits, contenu)
pose_mode $'plan\n'; SIG0="$(sigf)"
S425="$(pl "$(lj "$ID" acceptEdits)")"; attente_arme "$ARME_LU"
SHPID="$(SHPID_LU)"
R6="$(pl "$(lj inconnu acceptEdits)") $(pl "$(lj "$ID" bypassPermissions)") $(pl "$(lj "$ID" acceptEdits ',"ligne":"x"')") $(plx "$(printf 'f%.0s' $(seq 1 64))" A "$(lj "$ID" acceptEdits)" | sed -n 1p) $(pl "$(lj "$ID" acceptEdits)" --origin "http://127.0.0.1:$PP") $(plx "$SECRET" B "$(lj "$ID" acceptEdits)" | sed -n 1p) $(pl "$(lj "$ID" acceptEdits ',"chat":"oui"')")"
pget > /dev/null; pget > /dev/null; pget > /dev/null
assert_eq "LM.Q6 — refus avant armement 425 · id inconnu 404 · mode hors liste 400 · champ ligne 400 · sans secret valide 401 · Origin de P 403 · autre onglet 409 · chat non booléen 400 ; trois GET /proposition de plus : le fichier est inchangé (inode, date, droits, contenu) et la proposition reste en attente" "$S425 $R6 $([ "$(sigf)" = "$SIG0" ] && echo inchange || echo "change: $(sigf)") $(pbody | evj 'j.etat + "/" + (j.id === "'"$ID"'")')" "425 404 400 400 401 403 409 400 inchange en-attente/true"
node "$TA" entree "$QP" "$SECRET" A "python3 -I $WORK/temoins/hostile.py --recepteur $RUN/recept.hex 8\\r" > /dev/null
PRET6="$(node "$TA" attendre "$FLUX" RECEPTEUR-PRET 10000)"; REC=""; for _ in $(seq 1 30); do REC="$(command pgrep -P "$SHPID" | head -1)"; [ -n "$REC" ] && break; sleep 0.1; done
S409="$(pl "$(lj "$ID" acceptEdits)")"; VIV="$(kill -0 "${REC:-0}" 2>/dev/null && echo vivant || echo mort)"
assert_eq "LM.Q6 — programme au premier plan (témoin : récepteur prêt) : POST /lancer 409, le programme vit, fichier inchangé, proposition conservée" "$PRET6 $S409 $VIV $([ "$(sigf)" = "$SIG0" ] && echo inchange || echo change) $(pbody | evj 'j.id === "'"$ID"'"')" "TROUVE 409 vivant inchange true"
node "$TA" attendre "$FLUX" RECEPTEUR-FIN 15000 > /dev/null; node "$AUX/apres.mjs" "$FLUX" RECEPTEUR-FIN 'VFP> ' 10000 > /dev/null
ANN="$(rq "$QP" POST /annuler --secret "$SECRET" --onglet A --corps "{\"id\":\"$ID\"}" | sed -n 1p)"
assert_eq "LM.Q6 — POST /annuler {id} : 204 (la proposition est retirée) et le fichier reste inchangé" "$ANN $([ "$(sigf)" = "$SIG0" ] && echo inchange || echo change)" "204 inchange"
proposer; attente_arme "$ARME_LU"; S204="$(pl "$(lj "$ID" acceptEdits)")"; SIG1="$(sigf)"
assert_eq "LM.Q6 — témoin positif : un POST /lancer ACCEPTÉ en acceptEdits rend 204 et change le fichier (contenu acceptEdits, droits 600, inode DIFFÉRENT : le rename)" "$S204 $(sigfacts "$SIG1" 'j.contenu.trim() + "/" + j.perm') $([ "$(sigfacts "$SIG1" j.ino)" != "$(sigfacts "$SIG0" j.ino)" ] && echo inode-change || echo meme-inode)" "204 acceptEdits/600 inode-change"
for _ in $(seq 1 30); do [ "$(recus | evj 'j.filter((m) => m.t === "lancee").length')" = 1 ] && break; sleep 0.1; done
IPC="$(recus)"
assert_eq "LM.Q9 — aucun message IPC ne porte le mode : le message lancee (témoin : un seul) n'a que les clés t, cible, verbe, session, at ; aucune occurrence de mode, acceptEdits, plan ou herite dans les messages reçus par P" "$(printf '%s' "$IPC" | evj 'j.filter((m) => m.t === "lancee").length + "/" + Object.keys(j.filter((m) => m.t === "lancee")[0] || {}).sort().join(",")') $(printf '%s' "$IPC" | grep -c -i -E 'mode|acceptEdits|"plan"|herite' | tr -d ' ')" "1/at,cible,session,t,verbe 0"
manche_fin

echo "--- LM.Q3 — survie à une relance réelle, sur un autre port"
rm -rf "$STATE"; manche_debut "$OUT"; QPB="$QP"; QPIDB="$QPID"; proposer; attente_arme "$ARME_LU"; LISTE_LAB0="$(lab_liste "$LAB")"; S3="$(pl "$(lj "$ID" plan)")"; SIGB="$(sigf)"
assert_eq "LM.Q3 — lancement accepté en plan (204) : le fichier existe À L'EMPLACEMENT du poste (clé dérivée ici indépendamment), vaut plan, droits 0600" "$S3 $(sigfacts "$SIGB" 'j.contenu.trim() + "/" + j.perm')" "204 plan/600"
assert_eq "LM.Q3 — droits constatés sur ce que Q a créé (la base du poste n'existait pas) : fichier 600, dossier du projet 700, base 700" "$(node -e "const f=require('fs'),m=(p)=>(f.statSync(p).mode&0o777).toString(8);console.log([m(process.argv[1]),m(require('path').dirname(process.argv[1])),m(process.argv[2])].join('/'))" "$FM" "$STATE")" "600/700/700"
assert_eq "LM.Q3 — aucun fichier ni dossier créé sous le lab par un lancement accepté (liste de tout ce que contient le lab, hors .git : identique avant et après) ; le dossier d'état ne contient que la clé et le fichier" "$([ "$LISTE_LAB0" = "$(lab_liste "$LAB")" ] && echo lab-inchange || echo lab-change) $(find "$STATE" -mindepth 1 | sed "s#^$STATE/##" | sort | sed "s#$(cle_de "$LAB")#CLE#" | tr '\n' ',')" "lab-inchange CLE,CLE/terminal-mode,"
rq "$CP" POST /stop > /dev/null; attendre_q_sortie "$QPIDB" > /dev/null; manche_fin
manche_debut "$OUT" sans-flux; QPC="$QP"; QPIDC="$QPID"; proposer
assert_eq "LM.Q3 — après arrêt (message arret) puis relance sur la même sortie : PORT DIFFÉRENT (témoin de la prémisse : le stockage du navigateur de l'origine Q ne survit pas) et mode_retenu vaut plan" "$([ "$QPC" != "$QPB" ] && echo autre-port) $(mode_servi)" "autre-port plan"
manche_fin
manche_debut "$OUT"; QPIDC="$QPID"; QPC="$QP"; proposer; attente_arme "$ARME_LU"; S4="$(pl "$(lj "$ID" acceptEdits)")"
kill -9 "$QPIDC" 2>/dev/null; attendre_q_sortie "$QPIDC" > /dev/null; manche_fin
manche_debut "$OUT" sans-flux; proposer
assert_eq "LM.Q4 — second lancement en acceptEdits (204) puis mort de Q par SIGKILL : après relance (autre port) acceptEdits (le dernier gagne ; le fichier est celui du dernier 204, jamais d'un temporaire : aucun .tmp)" "$S4 $([ "$QP" != "$QPC" ] && echo autre-port) $(mode_servi) $(/bin/ls -a "$(dirname "$FM")" | grep -c 'terminal-mode.*tmp' | tr -d ' ')" "204 autre-port acceptEdits 0"
manche_fin

echo "--- LM.Q5 — fichier forgé AVANT le démarrage : jamais la valeur forgée"
forge_cas() { # forge_cas <nom> -> mode servi par une Q démarrée sur ce fichier forgé
  case "$1" in
    bypass) pose_mode $'bypassPermissions\n' ;; json) pose_mode '{"mode":"plan"}' ;; long) pose_mode "plan$(printf 'x%.0s' $(seq 1 40))" ;;
    lien) pose_mode ''; rm -f "$FM"; printf 'plan\n' > "$WORK/cible-plan"; chmod 600 "$WORK/cible-plan"; ln -s "$WORK/cible-plan" "$FM" ;;
    droits) pose_mode $'plan\n' 644 ;; valide) pose_mode $'acceptEdits\n' ;;
    dirlarge) pose_mode $'plan\n'; chmod 755 "$(dirname "$FM")" ;;
    dirlien) rm -rf "$(dirname "$FM")"; etat_dirs; rm -rf "$(dirname "$FM")"; rm -rf "$WORK/cle-cible"; mkdir -p "$WORK/cle-cible"; chmod 700 "$WORK/cle-cible"; printf 'plan\n' > "$WORK/cle-cible/terminal-mode"; chmod 600 "$WORK/cle-cible/terminal-mode"; ln -s "$WORK/cle-cible" "$(dirname "$FM")" ;;
  esac
  manche_debut "$OUT" sans-flux; proposer; local r; r="$(mode_servi)"; manche_fin; echo "$r"
  rm -rf "$(dirname "$FM")" # dirlien : retire le lien seul ; les autres : repart d'un dossier neuf
}
QF=""; for c in bypass json long lien droits dirlarge dirlien valide; do QF="$QF $(forge_cas "$c")"; done
assert_eq "LM.Q5 — fichier forgé avant le démarrage (bypassPermissions, JSON hostile, plan + 40 octets, lien vers un fichier plan, droits 0644, dossier du projet en 0755, dossier du projet remplacé par un lien) : mode_retenu default, jamais la valeur forgée ; témoin positif : acceptEdits valide rend acceptEdits" "${QF# }" "default default default default default default default acceptEdits"
rm -f "$FM"

echo "--- LM.Q7 — course entre deux onglets ; LM.Q8 — armement et Entrée dus avec herite"
pose_mode $'plan\n'; manche_debut "$OUT"; proposer; attente_arme "$ARME_LU"
( for _ in $(seq 1 15); do ONG=B pbody; echo; sleep 0.05; done > "$WORK/q7.out" ) & WB=$!
SA="$(pl "$(lj "$ID" acceptEdits)")"; SBR="$(plx "$SECRET" B "$(lj "$ID" plan)" | sed -n 1p)"; wait "$WB"
Q7="$(node -e "const L=require('fs').readFileSync(process.argv[1],'utf8').split('\n').filter(Boolean).map((l)=>JSON.parse(l)); const ok=L.filter((j)=>j.etat==='aucune'||(j.etat==='en-attente'&&['plan','acceptEdits'].includes(j.mode_retenu))).length; console.log(L.length>=10 && ok===L.length ? 'ok' : 'ko '+ok+'/'+L.length)" "$WORK/q7.out")"
assert_eq "LM.Q7 — deux onglets : GET /proposition pendant un lancement (quinze réponses : plan, acceptEdits ou aucune, jamais autre chose) ; l'onglet propriétaire lance (204), l'autre reçoit 409 et le fichier vaut acceptEdits (celui du propriétaire)" "$Q7 $SA $SBR $(sigfacts "$(sigf)" 'j.contenu.trim()')" "ok 204 409 acceptEdits"
manche_fin
pose_mode $'herite\n'; manche_debut "$OUT"; proposer; LH="$(pbody | evj 'j.lignes.herite')"; LH="${LH:-LIGNE-ABSENTE-DU-CORPS}"; SZ="$(wc -c < "$FLUX" | tr -d ' ')"
Q8A="$(mode_servi) $(pl "$(lj "$ID" herite)") $([ "$(wc -c < "$FLUX" | tr -d ' ')" = "$SZ" ] && echo flux-inchange || echo flux-change)"
attente_arme "$ARME_LU"; Q8B="$(pl "$(lj "$ID" herite)") $(node "$TA" attendre "$FLUX" "$LH" 8000)"; sleep 2; Q8C="$([ -e "$RUN/argv" ] && echo claude-a-tourne || echo claude-absent)"
assert_eq "LM.Q8 — fichier à herite : présélection herite servie ; avant armement POST /lancer rend 425 et 0 octet au shell ; après armement 204, la ligne paraît à l'invite et le faux claude n'a PAS tourné (aucun retour chariot ; l'Entrée reste un geste du client, Chrome : LB.E2)" "$Q8A / $Q8B $Q8C" "herite 425 flux-inchange / 204 TROUVE claude-absent"
manche_fin; rm -f "$FM"

echo "--- LM.Q10 — l'ancien fichier du lab n'est plus jamais lu ; deux projets ne partagent pas leur mode ; rien de l'emplacement n'est servi (AUDC-B-05)"
q_vieux() { # q_vieux <sortie> -> mode servi avec un ancien fichier « herite » préposé, statut du lancement en plan, contenu final de l'ancien fichier, contenu du nouveau
  local s="$1" vieux="$1/.cache/terminal-mode" r st; rm -rf "$STATE"; mkdir -p "$s/.cache"; chmod 700 "$s/.cache"; printf 'herite\n' > "$vieux"; chmod 600 "$vieux"
  manche_debut "$s"; proposer; r="$(mode_servi)"; attente_arme "$ARME_LU"; st="$(pl "$(lj "$ID" plan)")"; manche_fin
  echo "$r $st $(tr -d '\n' < "$vieux") $([ -f "$FM" ] && tr -d '\n' < "$FM" || echo absent)"
}
q_aucun() { # q_aucun <sortie> -> statut du lancement, « lab-inchange » si rien n'est apparu sous le lab, mode du fichier du poste
  local s="$1" lab st l0 l1; lab="$(cd "$s/../.." && pwd -P)"; rm -rf "$STATE"; mkdir -p "$s/.cache"; chmod 700 "$s/.cache"; rm -f "$s/.cache/terminal-mode"
  manche_debut "$s"; proposer; attente_arme "$ARME_LU"; l0="$(lab_liste "$lab")"; st="$(pl "$(lj "$ID" acceptEdits)")"; l1="$(lab_liste "$lab")"; manche_fin
  echo "$st $([ "$l0" = "$l1" ] && echo lab-inchange || echo lab-change) $([ -f "$FM" ] && tr -d '\n' < "$FM" || echo absent)"
}
LAB2="$WORK/lab2"; mklab "$LAB2"; OUT2="$LAB2/.vibeflow/cockpit"; FM2="$(fm_de "$LAB2")"
q_deux() { # q_deux <sortie> -> « <mode servi à LAB2 avant tout lancement> <mode servi à LAB> <mode servi à LAB2> » après plan sur LAB puis acceptEdits sur LAB2
  local s="$1" a b c; rm -rf "$STATE"
  manche_debut "$s"; proposer; attente_arme "$ARME_LU"; pl "$(lj "$ID" plan)" > /dev/null; manche_fin
  MLAB="$LAB2" manche_debut "$s"; proposer; a="$(mode_servi)"; attente_arme "$ARME_LU"; pl "$(lj "$ID" acceptEdits)" > /dev/null; manche_fin
  manche_debut "$s" sans-flux; proposer; b="$(mode_servi)"; manche_fin
  MLAB="$LAB2" manche_debut "$s" sans-flux; proposer; c="$(mode_servi)"; manche_fin
  echo "$a $b $c"
}
QV="$(q_vieux "$OUT")"
assert_eq "LM.Q10 — (a) lab reçu avec l'ancien fichier préréglé sur herite : Q présélectionne default, le lancement en plan rend 204, l'ancien fichier n'est ni lu, ni retiré, ni réécrit (herite) et le nouveau vaut plan" "$QV" "default 204 herite plan"
QVA=""; for v in acceptEdits herite; do rm -rf "$STATE"; mkdir -p "$OUT/.cache"; printf '%s\n' "$v" > "$FM_VIEUX"; chmod 600 "$FM_VIEUX"; manche_debut "$OUT" sans-flux; proposer; QVA="$QVA $(mode_servi)"; manche_fin; done
rm -f "$FM_VIEUX"
assert_eq "LM.Q10 — (a) ancien fichier acceptEdits puis herite (0600), état du poste vide : default les deux fois" "${QVA# }" "default default"
QA="$(q_aucun "$OUT")"
assert_eq "LM.Q10 — un lancement accepté (acceptEdits) ne crée AUCUN fichier ni dossier sous le lab et pose le mot au seul emplacement du poste" "$QA" "204 lab-inchange acceptEdits"
QD="$(q_deux "$OUT")"
assert_eq "LM.Q10 — (c) deux projets : plan lancé sur l'un ne présélectionne rien sur l'autre (default) ; acceptEdits lancé sur l'autre ne change pas le premier (plan) ; chacun garde le sien après relance ; les deux fichiers sont distincts" "$QD $([ "$FM" != "$FM2" ] && [ -f "$FM" ] && [ -f "$FM2" ] && echo fichiers-distincts)" "default plan acceptEdits fichiers-distincts"
q_confine() { # q_confine <sortie> -> « <mode servi> <statut du lancement en plan> <contenu final du fichier préposé sous le lab> » : surcharge pointée SOUS le lab, ancien mot herite préposé
  local s="$1" K B r st; K="$(cle_de "$LAB")"; B="$LAB/etat-forge"; rm -rf "$B"; mkdir -p "$B/$K"; chmod 700 "$B" "$B/$K"; printf 'herite\n' > "$B/$K/terminal-mode"; chmod 600 "$B/$K/terminal-mode"
  export VF_COCKPIT_MODE_DIR="$B"; manche_debut "$s"; proposer; r="$(mode_servi)"; attente_arme "$ARME_LU"; st="$(pl "$(lj "$ID" plan)")"; manche_fin; export VF_COCKPIT_MODE_DIR="$STATE"
  echo "$r $st $(tr -d '\n' < "$B/$K/terminal-mode") $(/usr/bin/find "$B" | wc -l | tr -d ' ')"; rm -rf "$B"
}
QC="$(q_confine "$OUT")"
assert_eq "LM.Q10 — (f) surcharge pointée sous le lab avec un mot herite préposé : Q présélectionne default, le lancement en plan rend 204, le fichier préposé reste herite et rien de plus n'apparaît sous le lab (deux entrées : dossier et fichier de la clé, plus la base)" "$QC" "default 204 herite 3"
# rien de l'emplacement dans ce que Q sert à la page : la proposition, /etat et la page, avant puis après un lancement
rm -rf "$STATE"; pose_mode $'plan\n'; manche_debut "$OUT"; proposer; QCLE="$(cle_de "$LAB")"
SERVI="$(pget; pget; rq "$QP" GET /etat --sans-origin --entete 'sec-fetch-site:same-origin' --secret "$SECRET" --onglet A; rq "$QP" GET / --corps-vers "$WORK/q-page.html" --secret "$SECRET" --onglet A; cat "$WORK/q-page.html" 2>/dev/null)"
attente_arme "$ARME_LU"; pl "$(lj "$ID" plan)" > /dev/null; SERVI="$SERVI $(pget; rq "$QP" GET /etat --sans-origin --entete 'sec-fetch-site:same-origin' --secret "$SECRET" --onglet A)"
assert_eq "LM.Q10 — (e, Q) ni le chemin du dossier d'état, ni celui du lab, ni du poste, ni l'empreinte, ni cockpit-mode ne figurent dans ce que Q sert à la page (proposition, /etat, page, avant et après un lancement ; témoin : mode_retenu est bien servi, la réponse n'est pas vide)" "$(printf '%s' "$SERVI" | grep -c -a -F -e "$STATE" -e "$WORK" -e "$REAL_HOME" -e "$QCLE" -e cockpit-mode | tr -d ' ') $(printf '%s' "$SERVI" | grep -c -a 'mode_retenu' | tr -d ' ' | sed 's/^[1-9][0-9]*$/servi/')" "0 servi"
manche_fin; rm -rf "$STATE"

echo "=== LM.P — P réel (--terminal, Q réelle) : aucune route ne rend le fichier, aucune écriture par P, aucun mode dans ses réponses ==="
cat > "$AUX/ptok.mjs" <<'JS'
import fs from 'node:fs'; const m = /VF_COCKPIT_SERVER=\{"token":"([0-9a-f]+)"/.exec(fs.readFileSync(process.argv[2], 'utf8')); console.log(m ? m[1] : '');
JS
cat > "$AUX/sse.mjs" <<'JS'
// sse.mjs <port> <jeton> <fichier> <ms> : capture bornée du flux SSE de P
import http from 'node:http'; import fs from 'node:fs'; const [, , port, jeton, fichier, ms] = process.argv; fs.writeFileSync(fichier, '');
const r = http.request({ host: '127.0.0.1', port: Number(port), path: `/api/vf/events?token=${jeton}`, headers: { Host: `127.0.0.1:${port}` }, agent: false }, (res) => { res.on('data', (c) => fs.appendFileSync(fichier, c)); });
r.on('error', () => {}); r.end(); setTimeout(() => { r.destroy(); process.exit(0); }, Number(ms));
JS
SENT="SENTINELLE-72-16-A-NE-PAS-SERVIR"; JSONH='Content-Type:application/json'
PS_PID=0; PS_PORT=0; PS_QP=0; PS_TOK=""; PS_N=0
psrv_debut() { # psrv_debut <sortie> -> PS_PID PS_PORT PS_QP PS_TOK PS_N (serveur réel --terminal ; le fichier du mode est posé par l'appelant)
  PS_N=$((PS_N+1)); NM=$((NM+1)); local o="$1" lab am; PS_OUT="$1"; lab="$(cd "$1/../.." && pwd)"; am="$WORK/amorce.$NM"
  rm -f "$RUN/shell.pid" "$RUN/argv" "$o/.cache/server.json" "$o/.cache/terminal-amorce"; mkdir -p "$o/.cache"
  node -e "console.log(require('crypto').randomBytes(32).toString('hex'))" > "$am.tmp"; (umask 077; tr -d '\n' < "$am.tmp" > "$o/.cache/terminal-amorce"; tr -d '\n' < "$am.tmp" > "$am")
  local cm=""; mutee "$o" && cm="$MUT_MOD"   # copie mutée : l'aide vérifie que le serveur lancé la charge (code 5 sinon)
  COCKPIT_MODULE="$cm" COCKPIT_PRET=terminal COCKPIT_LOG="$WORK/serve-$NM.out" cockpit_lancer "$lab" VF_COCKPIT_PATH_ORIGINE="$WORK/fauxbin:$PATH" VF_COCKPIT_LANCER_ARME_MS=$ARME VF_COCKPIT_ENGINE_DIR="$(eng_de "$o")" VF_COCKPIT_SCRIPTS_DIR="$(scripts_de "$o")" --terminal
  PS_PID="$VF_PID"; PS_SERVE="$WORK/serve-$NM.out"; PS_AM="$am"
  PS_PORT="${VF_PORT:-0}"
  PS_QP="$(node "$AUX/ev.mjs" '(j.terminal&&j.terminal.url)||""' < "$o/.cache/server.json" 2>/dev/null)"; PS_QP="${PS_QP##*:}"; PS_QP="${PS_QP:-0}"
  rq "$PS_PORT" GET /project.html --corps-vers "$WORK/page-$NM.html" > /dev/null; PS_TOK="$(node "$AUX/ptok.mjs" "$WORK/page-$NM.html")"
}
psrv_fin() { [ -n "$FPID" ] && vf_hyg_stop "$FPID"; FPID=""; vf_hyg_stop "$PS_PID"; for _ in $(seq 1 30); do [ -z "$(vf_hyg_vivants)" ] && break; sleep 0.2; done; }
gp() { local p="$1"; shift; rq "$PS_PORT" GET "$p" --jeton "$PS_TOK" --echeance 3000 "$@"; }
# p1_run <sortie> -> « <nombre de chemins> <statuts de traversée> <occurrences de la sentinelle> » : GET de chaque chemin de P dérivé du disque, puis des sondes de traversée
p1_run() {
  local o="$1" paths="$WORK/p1-paths.$PS_N" f n=0 tot=0 trav="" st c
  { grep -oh "pathname === '[^']*'" "$SERVE" | sed "s/.*'\(.*\)'/\1/"; node --input-type=module -e "import('file://$SCRIPTS/vf-cockpit-server.mjs').then((m) => { for (const l of m.ROUTES) console.log(l[0]); })"; printf '%s\n' / /index.html /project.html /api/vf/etat /.cache/server.json /api/vf/lancer/cibles /api/vf/terminal; } | sort -u | grep -v '/api/vf/events' > "$paths"
  while IFS= read -r f; do n=$((n+1)); gp "$f" --corps-vers "$WORK/p1.body" > "$WORK/p1.out"; c="$(grep -c -a "$SENT" "$WORK/p1.body" "$WORK/p1.out" | awk -F: '{s+=$NF} END {print s+0}')"; tot=$((tot + c)); done < "$paths"
  local cle; cle="$(cle_de "$(cd "$o/../.." && pwd -P)")"
  for f in /.cache/terminal-mode /..%2F.cache/terminal-mode //.cache/terminal-mode /%2e%2e/.cache/terminal-mode /api/vf/../.cache/terminal-mode "/$cle/terminal-mode" "/cockpit-mode/$cle/terminal-mode" "/$cle"; do
    gp "$f" --corps-vers "$WORK/p1.body" > "$WORK/p1.out"; st="$(sed -n 1p "$WORK/p1.out")"; c="$(grep -c -a "$SENT" "$WORK/p1.body" "$WORK/p1.out" | awk -F: '{s+=$NF} END {print s+0}')"; tot=$((tot + c)); trav="$trav$st,"
  done
  echo "$n ${trav%,} $tot"
}
{
  pose_mode "$SENT"$'\n'; SIGP="$(sigf)"; ETP="$(etat_liste)"
  psrv_debut "$OUT"; FPID=""
  assert_eq "LM.P0 — témoin : P répond (port et jeton), GET /api/vf/lancer/cibles rend 200, la sortie du serveur n'est pas vide" "$([ "$PS_PORT" -gt 0 ] && echo port) $([ -n "$PS_TOK" ] && echo jeton) $(sta "$PS_PORT" GET /api/vf/lancer/cibles --jeton "$PS_TOK")" "port jeton 200"
  P1="$(p1_run "$OUT")"; read -r P1N P1T P1S <<< "$P1"
  assert_eq "LM.P1 — GET de chaque chemin de P dérivé du disque (au moins 5 : témoin) et de cinq sondes de traversée (/.cache/terminal-mode, /..%2F…, //…, /%2e%2e/…, /api/vf/../…) : aucune réponse ne contient la sentinelle ; aucune sonde de traversée ne rend 200 (huit sondes : l'ancien chemin, ses variantes encodées, et l'emplacement du poste par la clé)" "$([ "${P1N:-0}" -ge 5 ] && echo assez || echo "trop peu (${P1N:-0})") $(printf '%s' "${P1T:-}" | grep -c 200 | tr -d ' ') ${P1S:-?}" "assez 0 0"
  P2="$(for r in /api/vf/lancer /api/vf/doing /api/vf/etat /api/vf/journal /api/vf/transcript /; do for b in '{"mode":"plan"}' '{"mode":"bypassPermissions"}'; do rq "$PS_PORT" POST "$r" --jeton "$PS_TOK" --entete "$JSONH" --corps "$b" --echeance 3000; done; done)"
  assert_eq "LM.P2 — POST sur les routes de P (jeton de P, corps {mode:plan} ou {mode:bypassPermissions}) : le fichier est octet pour octet inchangé, le dossier d'état n'a reçu ni fichier ni dossier, et aucune réponse ne contient la sentinelle" "$([ "$(sigf)" = "$SIGP" ] && echo inchange || echo change) $([ "$(etat_liste)" = "$ETP" ] && echo etat-inchange || echo etat-change) $(printf '%s' "$P2" | grep -c -a "$SENT" | tr -d ' ')" "inchange etat-inchange 0"
  # LM.P3 : un lancement accepté de bout en bout, puis aucune réponse de P ne porte le mode
  p3_run() { # p3_run -> P3R « lancee=<oui|non> fuites=<n> » (variable globale : jamais en sous-shell, il y vit des processus) ; nécessite psrv_debut déjà fait
    local sec c id vb cibles ln i
    sec="$(node "$TA" amorcer "$PS_QP" "$PS_AM" | sed -n 2p)"; FLUX="$WORK/flux-p$PS_N.out"; : > "$FLUX"
    node "$TA" flux "$PS_QP" "$sec" A "$FLUX" 150000 --taille 24x400 > "$WORK/flux-p$PS_N.log" 2>&1 & FPID=$!; PIDS+=($FPID); node "$TA" attendre "$FLUX" 'VFP> ' 10000 > /dev/null
    cibles="$(gp /api/vf/lancer/cibles | sed '1,2d')"; id="$(printf '%s' "$cibles" | evj 'j.cibles[0].id' 2>/dev/null)"; vb="$(printf '%s' "$cibles" | evj 'j.cibles[0].principal || j.cibles[0].verbes[0]' 2>/dev/null)"
    rq "$PS_PORT" POST /api/vf/lancer --jeton "$PS_TOK" --entete "$JSONH" --corps "{\"cible\":\"$id\",\"verbe\":\"$vb\"}" > /dev/null
    local pid2=""; for i in $(seq 1 40); do c="$(rq "$PS_QP" GET /proposition --sans-origin --entete 'sec-fetch-site:same-origin' --secret "$sec" --onglet A | sed '1,2d')"; [ "$(printf '%s' "$c" | evj 'j.etat' 2>/dev/null)" = en-attente ] && break; sleep 0.1; done
    pid2="$(printf '%s' "$c" | evj 'j.id' 2>/dev/null)"; ln="$(printf '%s' "$c" | evj 'j.arme_apres_ms' 2>/dev/null)"; sleep "$(node -e "console.log((${ln:-2000} + 300) / 1000)")"
    rq "$PS_QP" POST /lancer --secret "$sec" --onglet A --corps "{\"id\":\"$pid2\",\"mode\":\"plan\"}" > /dev/null
    local vue=non; for i in $(seq 1 40); do [ "$(gp /api/vf/lancer/cibles | sed '1,2d' | evj '(j.cibles[0] && j.cibles[0].lancee) ? "oui" : "non"' 2>/dev/null)" = oui ] && { vue=oui; break; }; sleep 0.1; done
    node "$AUX/sse.mjs" "$PS_PORT" "$PS_TOK" "$WORK/sse-p.out" 2500 &
    local tout="$WORK/p3.all"; : > "$tout"; for r in /api/vf/lancer/cibles /api/vf/etat /api/vf/journal /api/vf/terminal /project.html /index.html; do gp "$r" >> "$tout"; done; wait $! 2>/dev/null
    cat "$WORK/sse-p.out" "$PS_OUT/.cache/server.json" "$PS_SERVE" >> "$tout" 2>/dev/null
    P3R="lancee=$vue fuites=$(grep -c -a -E 'mode_retenu|"mode" *: *"(default|acceptEdits|plan|herite)"' "$tout" | tr -d ' ')"
  }
  P3R=""; p3_run; P3="$P3R"
  assert_eq "LM.P3 — après un lancement accepté de bout en bout (cible marquée lancée : témoin que le message est arrivé à P) : aucune réponse de P (cibles, état, journal, terminal, page Projet, export, SSE) ne porte mode_retenu ni un champ mode" "$P3" "lancee=oui fuites=0"
  assert_eq "LM.P4 — server.json et la sortie du serveur ne contiennent ni la sentinelle ni mode_retenu" "$(cat "$PS_OUT/.cache/server.json" "$PS_SERVE" 2>/dev/null | grep -c -a -E "$SENT|mode_retenu" | tr -d ' ')" "0"
  psrv_fin; rm -f "$FM"
}

# ---- mutants : chacun joué sur une copie de la sortie (ou des sources) ; l'attendu est l'observable du DÉFAUT, jamais « pas le sain » ----
FM_OUT="$FM"; sur() { :; }; sur_out() { FM="$FM_OUT"; }; surp() { FM="$(fm_de "$(cd "$1/../.." && pwd -P)")"; } # Q de manche : la racine est toujours $LAB (même fichier) ; P réel : la racine est le lab muté (surp)
MODF=vf-cockpit-lancer-mode.mjs; PROCF=vf-cockpit-terminal-processus.mjs
mut_forge() { # mut_forge <sortie> <contenu|LIEN> -> mode servi par une Q démarrée sur la sortie mutée avec ce fichier
  sur "$1"; if [ "$2" = LIEN ]; then pose_mode ''; rm -f "$FM"; printf 'plan\n' > "$WORK/cible-plan"; chmod 600 "$WORK/cible-plan"; ln -s "$WORK/cible-plan" "$FM"; else pose_mode "$2"; fi
  manche_debut "$1" sans-flux; proposer; local r; r="$(mode_servi)"; manche_fin; sur_out; echo "$r"
}
echo "=== M-SANS-REVALIDATION — lire rend le contenu brut (LM.U2, LM.Q5) ==="
if mutant sans-reval "$MODF" 's#return modes.indexOf(mot) >= 0 ? mot : DEFAUT; // garde:mode-valide#return mot; // garde:mode-valide#'; then
  assert_eq "M-SANS-REVALIDATION — sous le mutant LM.U2 rougit (les dix-sept contenus forgés ne valent plus tous default)" "$(uq "$(facts_u "$MUT_OUT" rapide)" 'j.u2.filter((x) => x === "default").length < 17')" "true"
  assert_eq "M-SANS-REVALIDATION — sous le mutant LM.Q5 rougit : un fichier bypassPermissions est servi tel quel" "$(mut_forge "$MUT_OUT" $'bypassPermissions\n')" "bypassPermissions"
else sans_effet "M-SANS-REVALIDATION"; fi
echo "=== M-TRIM — la lecture tolère les blancs au lieu d'un seul retour final (LM.U2) ==="
if mutant trim "$MODF" "s#const mot = txt.endsWith('\\\\n') ? txt.slice(0, -1) : txt;#const mot = txt.trim();#"; then
  assert_eq "M-TRIM — sous le mutant LM.U2 rougit : les mots entourés de blancs sont lus comme plan" "$(uq "$(facts_u "$MUT_OUT" rapide)" 'j.u2blancs.join(",")')" "plan,plan,plan,plan,plan,plan"
else sans_effet "M-TRIM"; fi
echo "=== M-BOM — le BOM est retiré par le décodeur (LM.U2) ==="
if mutant bom "$MODF" 's#{ fatal: true, ignoreBOM: true }#{ fatal: true }#'; then
  assert_eq "M-BOM — sous le mutant LM.U2 rougit : un BOM devant plan est lu plan" "$(uq "$(facts_u "$MUT_OUT" rapide)" 'j.u2bom')" "plan"
else sans_effet "M-BOM"; fi
echo "=== M-DOSSIER-LIEN — contrôle du dossier support retiré (LM.U4) ==="
if mutant dossier-lien "$MODF" "s#if (ls.isSymbolicLink() || !ls.isDirectory()) return 'ko';##" "s#if (typeof os.getuid === 'function' && (ls.uid !== os.getuid() || (ls.mode & 0o077) !== 0)) return 'ko';##"; then
  assert_eq "M-DOSSIER-LIEN — sous le mutant LM.U4 rougit : l'écriture traverse le lien (true, un fichier dans le dossier visé)" "$(uq "$(facts_u "$MUT_OUT" rapide)" 'j.u4lien')" "true,aucune,1,1"
else sans_effet "M-DOSSIER-LIEN"; fi
echo "=== M-SUIT-LIEN — O_NOFOLLOW retiré (LM.U3, LM.Q5) ==="
if mutant suit-lien "$MODF" 's#const noFollow = c.O_NOFOLLOW || 0;#const noFollow = 0;#'; then
  assert_eq "M-SUIT-LIEN — sous le mutant LM.U3 rougit : le lien symbolique est suivi (plan au lieu de default)" "$(uq "$(facts_u "$MUT_OUT" rapide)" 'j.u3lien')" "plan"
  assert_eq "M-SUIT-LIEN — sous le mutant LM.Q5 rougit : un lien vers un fichier plan est servi (plan au lieu de default)" "$(mut_forge "$MUT_OUT" LIEN)" "plan"
else sans_effet "M-SUIT-LIEN"; fi
echo "=== M-DROITS-IGNORES — contrôle des droits retiré (LM.U3) ==="
if mutant droits "$MODF" '/garde:mode-droits/d'; then
  assert_eq "M-DROITS-IGNORES — sous le mutant LM.U3 rougit : droits 0644, 0660, 0640 lus comme plan" "$(uq "$(facts_u "$MUT_OUT" rapide)" 'j.u3droits.join(",")')" "plan,plan,plan,plan,plan"
else sans_effet "M-DROITS-IGNORES"; fi
echo "=== M-PROPRIETAIRE — contrôle du propriétaire retiré (LM.U3, fstat simulé) ==="
if mutant proprio "$MODF" '/garde:mode-uid/d'; then
  assert_eq "M-PROPRIETAIRE — sous le mutant LM.U3 rougit : le fichier d'un autre propriétaire est lu (plan)" "$(uq "$(facts_u "$MUT_OUT" rapide)" 'j.u3uid.join(",")')" "plan,plan"
else sans_effet "M-PROPRIETAIRE"; fi
echo "=== M-TAILLE — borne de 32 octets retirée (LM.U2) ==="
if mutant taille "$MODF" '/garde:mode-taille/d'; then
  assert_eq "M-TAILLE — sous le mutant LM.U2 rougit : un fstat annonçant 4096 octets déclenche tout de même une lecture" "$(uq "$(facts_u "$MUT_OUT" rapide)" 'j.u2taille.join(",")')" "plan,1,plan,1"
else sans_effet "M-TAILLE"; fi
echo "=== M-BLOQUANT — O_NONBLOCK retiré (LM.U3, FIFO) ==="
if mutant bloquant "$MODF" 's#const nonBlock = c.O_NONBLOCK || 0;#const nonBlock = 0;#'; then
  assert_eq "M-BLOQUANT — sous le mutant LM.U3 rougit : l'ouverture d'une FIFO bloque (échéance de 20 s dépassée)" "$(fifo_u "$MUT_OUT")" "TIMEOUT"
else sans_effet "M-BLOQUANT"; fi
echo "=== M-ECRITURE-DIRECTE — la cible écrite sans temporaire ni rename (LM.U4, LM.Q6) ==="
if mutant ecr-directe "$MODF" "s#fs.openSync(tmp, 'wx', 0o600)#fs.openSync(fichier, 'w', 0o600)#" '/garde:mode-rename/d'; then
  assert_eq "M-ECRITURE-DIRECTE — sous le mutant LM.U4 rougit : la cible est ouverte en écriture et aucun temporaire ni rename" "$(uq "$(facts_u "$MUT_OUT" rapide)" '[j.u4.cibleEcrite, j.u4.ouvertTemp, j.u4.renomme].join("/")')" "true/false/false"
  sur "$MUT_OUT"; pose_mode $'plan\n'; SIGM0="$(sigf)"; manche_debut "$MUT_OUT"; proposer; attente_arme "$ARME_LU"; pl "$(lj "$ID" acceptEdits)" > /dev/null; SIGM1="$(sigf)"
  assert_eq "M-ECRITURE-DIRECTE — sous le mutant le témoin positif de LM.Q6 rougit : un lancement accepté réécrit le MÊME inode (le rename n'a plus lieu)" "$(sigfacts "$SIGM1" 'j.contenu.trim()') $([ "$(sigfacts "$SIGM1" j.ino)" = "$(sigfacts "$SIGM0" j.ino)" ] && echo meme-inode || echo inode-change)" "acceptEdits meme-inode"; manche_fin; sur_out
else sans_effet "M-ECRITURE-DIRECTE"; fi
echo "=== M-TEMPORAIRE-RESTE — le temporaire n'est plus retiré sur échec (LM.U4) ==="
if mutant tmp-reste "$MODF" '/garde:mode-unlink/d'; then
  assert_eq "M-TEMPORAIRE-RESTE — sous le mutant LM.U4 rougit : après l'échec du rename un temporaire reste dans le dossier" "$(uq "$(facts_u "$MUT_OUT" rapide)" 'j.u4rename.restes.indexOf(".tmp") >= 0')" "true"
else sans_effet "M-TEMPORAIRE-RESTE"; fi
echo "=== M-RELECTURE-A-CHAQUE-SONDAGE — lire relit le disque (LM.U5) ==="
if mutant relecture "$MODF" 's#lire: () => memoire,#lire: () => charger(fichier, dirs, fs, modes, os),#'; then
  assert_eq "M-RELECTURE-A-CHAQUE-SONDAGE — sous le mutant LM.U5 rougit : le fichier réécrit de l'extérieur est relu (acceptEdits)" "$(uq "$(facts_u "$MUT_OUT" rapide)" 'j.u5.join(",")')" "plan,acceptEdits"
else sans_effet "M-RELECTURE-A-CHAQUE-SONDAGE"; fi
echo "=== M-ECRITURE-A-LA-DEMANDE — l'écriture part à la réception de POST /lancer, avant consommer (LM.Q6) ==="
if mutant ecr-demande "$PROCF" 's#const idDemande = demande.id;#memoireMode.ecrire(demande.mode); const idDemande = demande.id;#'; then
  sur "$MUT_OUT"; pose_mode $'plan\n'; manche_debut "$MUT_OUT"; proposer; attente_arme "$ARME_LU"; RM="$(pl "$(lj inconnu acceptEdits)")"
  assert_eq "M-ECRITURE-A-LA-DEMANDE — sous le mutant LM.Q6 rougit : un id inconnu (404) réécrit pourtant le fichier (acceptEdits au lieu de plan)" "$RM $(sigfacts "$(sigf)" 'j.contenu.trim()')" "404 acceptEdits"; manche_fin; sur_out
else sans_effet "M-ECRITURE-A-LA-DEMANDE"; fi
echo "=== M-ECRITURE-AVANT-LE-SHELL — l'écriture précède le test de w.ok (LM.Q6) ==="
STUB_ECR="s#const w = await sessions.lancer(ligneQ, onglet);#const w = { ok: false, motif: 'ecriture' };#"
if mutant stub-ecriture "$PROCF" "$STUB_ECR"; then
  sur "$MUT_OUT"; pose_mode $'plan\n'; SIGS="$(sigf)"; manche_debut "$MUT_OUT"; proposer; attente_arme "$ARME_LU"; RS="$(pl "$(lj "$ID" acceptEdits)")"
  assert_eq "LM.Q6 — session doublée sur le motif ecriture (le shell refuse la ligne) : 410 et le fichier est inchangé" "$RS $([ "$(sigf)" = "$SIGS" ] && echo inchange || echo change)" "410 inchange"; manche_fin; sur_out
else sans_effet "LM.Q6 (doublure ecriture)"; fi
if mutant avant-shell "$PROCF" "s#const w = await sessions.lancer(ligneQ, onglet);#const w = { ok: false, motif: 'ecriture' }; memoireMode.ecrire(demande.mode);#" '/garde:mode-ecrit/d'; then
  sur "$MUT_OUT"; pose_mode $'plan\n'; manche_debut "$MUT_OUT"; proposer; attente_arme "$ARME_LU"; RM="$(pl "$(lj "$ID" acceptEdits)")"
  assert_eq "M-ECRITURE-AVANT-LE-SHELL — sous le mutant LM.Q6 rougit : le refus du shell (410) laisse pourtant le fichier réécrit (acceptEdits au lieu de plan)" "$RM $(sigfacts "$(sigf)" 'j.contenu.trim()')" "410 acceptEdits"; manche_fin; sur_out
else sans_effet "M-ECRITURE-AVANT-LE-SHELL"; fi
echo "=== M-MODE-DANS-AUCUNE — mode_retenu ajouté à la réponse aucune (LM.Q1) ==="
if mutant mode-aucune "$PROCF" '/garde:mode-servi/s#.*#const lireProposition = () => ({ ...lq.lire(), mode_retenu: memoireMode.lire() }); // garde:mode-servi#'; then
  sur "$MUT_OUT"; rm -f "$FM"; manche_debut "$MUT_OUT" sans-flux
  assert_eq "M-MODE-DANS-AUCUNE — sous le mutant LM.Q1 rougit : la réponse aucune porte mode_retenu (clés etat,mode_retenu)" "$(pbody | evj 'Object.keys(j).join(",")')" "etat,mode_retenu"; manche_fin; sur_out
else sans_effet "M-MODE-DANS-AUCUNE"; fi
echo "=== M-NOUVELLE-ROUTE — une route POST /mode ajoutée à routes (LM.S3) ==="
if mutant route "$PROCF" "s#'/annuler': 'POST' };#'/annuler': 'POST', '/mode': 'POST' };#"; then
  assert_eq "M-NOUVELLE-ROUTE — sous le mutant LM.S3 rougit : la table de routes compte une route de plus" "$(node "$AUX/stat.mjs" "$MUT_MOD/scripts/$PROCF" "$MUT_MOD/skills/cockpit-moteur/assets/ui/terminal/client.js" | evj j.routes)" "/amorce:POST,/annuler:POST,/entree:POST,/etat:GET,/flux:GET,/lancer:POST,/mode:POST,/proposition:GET,/taille:POST"
else sans_effet "M-NOUVELLE-ROUTE"; fi
echo "=== M-MODE-VERS-P — le mode ajouté au message lancee (LM.S5, LM.P3) ==="
if mutant mode-vers-p "$PROCF" 's#process.send(msg);#process.send({ ...msg, mode: demande.mode });#'; then
  assert_eq "M-MODE-VERS-P — sous le mutant LM.S5 rougit : une ligne process.send( porte le mode" "$(node "$AUX/stat.mjs" "$MUT_MOD/scripts/$PROCF" "$MUT_MOD/skills/cockpit-moteur/assets/ui/terminal/client.js" | evj j.envoisMode)" "1"
  surp "$MUT_OUT"; pose_mode "$SENT"$'\n'; psrv_debut "$MUT_OUT"; P3R=""; p3_run
  assert_eq "M-MODE-VERS-P — sous le mutant LM.P3 rougit : P refuse le message lancee à clé de plus (forme fermée) : la cible n'est jamais marquée lancée (son témoin positif)" "$P3R" "lancee=non fuites=0"; psrv_fin; sur_out
else sans_effet "M-MODE-VERS-P"; fi
echo "=== M-P-LIT-LE-FICHIER — une route de P répond le contenu du fichier (LM.P1, LM.S2) ==="
if mutant p-lit "vf-cockpit-server.mjs" "s#  \['/api/vf/journal', lireJournal, HISTORIQUE\],#  ['/api/vf/journal', (c) => { const B = process.env.VF_COCKPIT_MODE_DIR; return { contenu: fs.readdirSync(B).map((k) => { try { return fs.readFileSync(path.join(B, k, 'terminal-mode')); } catch (e) { return ''; } }).join('') }; }, HISTORIQUE],#"; then
  if [ "$MODULE_OK" = 1 ]; then assert_eq "M-P-LIT-LE-FICHIER — sous le mutant LM.S2 rougit : le fichier de P nomme terminal-mode (au moins une référence)" "$(p_refs "$MUT_OUT" | awk -F: '{print ($2 >= 1) ? "reference" : "aucune"}')" "reference"
  else nonjouee "M-P-LIT-LE-FICHIER (LM.S2)" "module absent"; fi
  surp "$MUT_OUT"; pose_mode "$SENT"$'\n'; psrv_debut "$MUT_OUT"; P1M="$(p1_run "$MUT_OUT")"; read -r _ _ P1MS <<< "$P1M"
  assert_eq "M-P-LIT-LE-FICHIER — sous le mutant LM.P1 rougit : la route servie rend la sentinelle (au moins une occurrence)" "$([ "${P1MS:-0}" -ge 1 ] && echo sentinelle-servie || echo "rien (${P1MS:-?})")" "sentinelle-servie"; psrv_fin; sur_out
else sans_effet "M-P-LIT-LE-FICHIER"; fi
echo "=== M-ANCIEN-FICHIER — le support revient dans le lab : l'ancien fichier est relu et réécrit (LM.Q10, LM.Q3) ==="
if mutant ancien "$PROCF" "s#creerMemoireModePoste({ racine: root })#creerMemoireMode({ fichier: path.join(here, '.cache', 'terminal-mode') })#" "s#import { creerMemoireModePoste }#import { creerMemoireMode }#"; then
  assert_eq "M-ANCIEN-FICHIER — sous le mutant LM.Q10 (a) rougit : l'ancien fichier herite est servi, puis réécrit par le lancement (plan)" "$(q_vieux "$MUT_OUT")" "herite 204 plan absent"
  assert_eq "M-ANCIEN-FICHIER — sous le mutant LM.Q10 (aucun fichier sous le lab) rougit : le lancement crée le fichier sous le lab, rien au poste" "$(q_aucun "$MUT_OUT")" "204 lab-change absent"
  assert_eq "M-ANCIEN-FICHIER — sous le mutant LM.S7 rougit : la ligne garde:mode-support nomme here, .cache et path.join" "$(grep 'garde:mode-support' "$MUT_MOD/scripts/$PROCF" | sed 's#//.*##' | grep -c -E 'here|\.cache|path\.join' | tr -d ' ')" "1"
else sans_effet "M-ANCIEN-FICHIER"; fi
echo "=== M-CLE-COMMUNE — la clé ne dépend plus du projet (LM.U7, LM.U8, LM.Q10) ==="
if mutant cle-commune "$MODF" "s#update(fs.realpathSync(racine), 'utf8')#update('commun', 'utf8')#"; then
  assert_eq "M-CLE-COMMUNE — sous le mutant LM.U7 / LM.U8 rougissent : deux dossiers donnent la même clé, l'autre projet lit le mot du premier" "$(uq "$(facts_u "$MUT_OUT" rapide)" 'j.p1.autre + "/" + j.p1.egalSha + "/" + j.p2.autreProjet')" "false/false/acceptEdits"
  assert_eq "M-CLE-COMMUNE — sous le mutant LM.Q10 (c) rougit : le second projet présélectionne le mot du premier (plan au lieu de default)" "$(q_deux "$MUT_OUT")" "plan acceptEdits acceptEdits"
else sans_effet "M-CLE-COMMUNE"; fi
echo "=== M-DROITS-0644 — le fichier est créé en 0644 (LM.U4, LM.U8) ==="
if mutant droits-0644 "$MODF" "s#fs.openSync(tmp, 'wx', 0o600)#fs.openSync(tmp, 'wx', 0o644)#"; then
  assert_eq "M-DROITS-0644 — sous le mutant LM.U4 / LM.U8 rougissent : le fichier final est 644" "$(uq "$(facts_u "$MUT_OUT" rapide)" 'j.u4.perm + "/" + j.p2.permF')" "644/644"
else sans_effet "M-DROITS-0644"; fi
echo "=== M-DOSSIER-DROITS — le contrôle des droits du dossier d'état est retiré (LM.U10) ==="
if mutant dossier-droits "$MODF" "s# || (ls.mode & 0o077) !== 0##"; then
  assert_eq "M-DOSSIER-DROITS — sous le mutant LM.U10 rougit : une base en 0755 et un dossier de projet en 0755 sont lus (plan) et écrits (acceptEdits)" "$(uq "$(facts_u "$MUT_OUT" rapide)" '[j.p4.baseLarge, j.p4.cleLarge].join(" ")')" "plan,true,aucune,0,0,acceptEdits plan,true,aucune,0,0,acceptEdits"
else sans_effet "M-DOSSIER-DROITS"; fi
echo "=== M-CONFINEMENT — la garde de confinement de la base est retirée (LM.U13, LM.Q10 f) ==="
if mutant confinement "$MODF" 's#const garde = () => horsDuLab(base, racine, fs) && horsDuLab(dossier, racine, fs);#const garde = () => true;#'; then
  assert_eq "M-CONFINEMENT — sous le mutant LM.U13 rougit : toutes les bases sous le lab sont lues (plan) et écrites (acceptEdits)" "$(uq "$(facts_u "$MUT_OUT" rapide)" 'j.p7')" "plan,true,acceptEdits plan,true,acceptEdits plan,true,acceptEdits plan,true,acceptEdits plan,true,acceptEdits plan,true,acceptEdits"
  assert_eq "M-CONFINEMENT — sous le mutant LM.Q10 (f) rougit : Q présélectionne herite depuis le lab et y réécrit plan" "$(q_confine "$MUT_OUT")" "herite 204 plan 3"
else sans_effet "M-CONFINEMENT"; fi
echo "=== M-IDENTITE-PAR-CHAINE — le confinement est jugé sur la forme textuelle du chemin, sans identité (LM.U15, LM.U17) ==="
if mutant garde-chaine "$MODF" 's#if (st.dev === rid.dev && st.ino === rid.ino) return false;#if (p === path.resolve(racine)) return false;#' 's#for (const depart of \[e, resolu\])#for (const depart of [e])#'; then
  MF="$(facts_u "$MUT_OUT" rapide)"
  assert_eq "M-IDENTITE-PAR-CHAINE — sous le mutant LM.U15 rougit : la base écrite dans une autre casse est acceptée, lue (plan) et réécrite" "$(uqp "$MF" 'j.p8.casse')" "$([ "$FSCI" = true ] && echo 'plan,true,0 plan,true,0' || echo nonjouable)"
  GEN_LIEN="$(uqp "$UF" '(j.gen.formes["dedans/lien"] || 0) > 0 || j.fsci')" # le mutant laisse passer les formes lien (toujours) et la casse (si le système y est insensible) : l'attendu suit ce que le générateur a réellement produit
  assert_eq "M-IDENTITE-PAR-CHAINE — sous le mutant LM.U17 rougit : la preuve générative trouve au moins un écart (le générateur a produit des formes que le mutant laisse passer : $GEN_LIEN)" "$(uqp "$MF" 'j.gen.ko.length > 0')" "$GEN_LIEN"
else sans_effet "M-IDENTITE-PAR-CHAINE"; fi
echo "=== M-SANS-PREMIER-JUGEMENT — le jugement avant création est retiré (LM.U16 premier jugement) ==="
if mutant sans-jugement-1 "$MODF" '/garde:mode-jugement-1/d'; then
  assert_eq "M-SANS-PREMIER-JUGEMENT — sous le mutant le témoin du premier jugement rougit : les dossiers sont créés sous le lab (le nouveau jugement refuse seulement le fichier)" "$(uqp "$(facts_u "$MUT_OUT" rapide)" 'j.p8.jug1')" "false,2"
else sans_effet "M-SANS-PREMIER-JUGEMENT"; fi
echo "=== M-SANS-REJUGEMENT — le jugement avant l'écriture est retiré (LM.U16) ==="
if mutant sans-rejuge "$MODF" '/garde:mode-rejuge/d'; then
  assert_eq "M-SANS-REJUGEMENT — sous le mutant LM.U16 rougit : le fichier est écrit sous le lab" "$(uqp "$(facts_u "$MUT_OUT" rapide)" 'j.p8.rejuge')" "true,1"
else sans_effet "M-SANS-REJUGEMENT"; fi
echo "=== M-DOSSIER-PROPRIETAIRE — la seule clause propriétaire du dossier d'état est retirée (LM.U14) ==="
if mutant dossier-proprio "$MODF" "s#ls.uid !== os.getuid() || ##"; then
  assert_eq "M-DOSSIER-PROPRIETAIRE — sous le mutant LM.U14 rougit : un dossier d'un autre uid est lu (plan) et écrit (le même fichier relu donne acceptEdits)" "$(uq "$(facts_u "$MUT_OUT" rapide)" 'j.p7uid')" "plan,true|acceptEdits,true"
else sans_effet "M-DOSSIER-PROPRIETAIRE"; fi
echo "=== M-STOCKAGE-RESTE — repli sur le stockage du navigateur (LM.S4, LM.C3) ==="
if mutant stockage-reste client.js "/garde:mode-lecture/s#.*#const v = p.mode_retenu !== undefined ? p.mode_retenu : localStorage.getItem('vf.terminal.mode'); // garde:mode-lecture#"; then
  assert_eq "M-STOCKAGE-RESTE — sain/mutant/occurrences : LM.C3 sain sur le client livré, rouge sous le mutant (getItem d'une clé mode) ; LM.S4 compte 1 occurrence sous le mutant" "$(cq "$CF" "$C3EXPR")/$(cq "$(facts_c "$MUT_OUT")" "$C3EXPR")/$(node "$AUX/stat.mjs" "$MUT_MOD/scripts/$PROCF" "$MUT_MOD/skills/cockpit-moteur/assets/ui/terminal/client.js" | evj j.cliCleMode)" "0/true/1/true/1"
else sans_effet "M-STOCKAGE-RESTE"; fi
echo "=== M-SERVI-NON-RELU — la valeur servie n'est pas relue contre la liste (LM.C2) ==="
if mutant servi-non-relu client.js "/garde:mode-relu/s#.*#return v;#"; then
  assert_eq "M-SERVI-NON-RELU — sain/mutant : LM.C2 sain sur le client livré, rouge sous le mutant (bypassPermissions devient la présélection)" "$(cq "$CF" "$C2EXPR")/$(cq "$(facts_c "$MUT_OUT")" "$C2EXPR")" "true/false"
else sans_effet "M-SERVI-NON-RELU"; fi

vf_hyg_assert
echo "Résultats : $PASS PASS, $FAIL FAIL ($NONJOUE non jouées, dites)"
[ $((PASS+FAIL)) -ge 55 ] || { echo "  ❌ FAIL — anti-vert-à-vide : moins de 55 assertions jouées"; exit 1; }
[ "$FAIL" -eq 0 ]
