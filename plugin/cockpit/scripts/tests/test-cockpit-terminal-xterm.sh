#!/usr/bin/env bash
# test-cockpit-terminal-xterm.sh — terminal réel dans Chrome : plein écran, touches, séquences hostiles
# (TERM-09 navigateur, TERM-10 comportement ; P71-D-06, D-16 ; plan 71-08, hypothèse A2 de 71-RESEARCH).
#   T13  programme plein écran témoin (temoins/plein-ecran.py) dans la page Q réelle : T13.6 grille (TEMOIN-PLEIN-ECRAN-DEBUT puis PRET),
#        T13.7 redimensionnement de la fenêtre -> WINCH <lignes>x<colonnes> dans la grille, T13.8 Ctrl-C -> SIGINT-RECU et retour à l'écran normal,
#        T13.9 touches : Échap, Tab, Ctrl+R, Ctrl+W, flèche haut atteignent le shell (récepteur d'entrée brute), Ctrl+Maj+Espace n'envoie aucun octet
#   T14  programme hostile (temoins/hostile.py : OSC 52, OSC 8, DCS, XTGETTCAP, CSI 21t/18t/14t/16t, DECRQSS puis DA1) : T14.1 l'entrée reçue est la réponse à DA1
#        SEULE (témoin T14.1a : elle est reçue), T14.2 aucun appel au presse-papiers, T14.3 ni window.open ni confirm sans clic, T14.4 un clic sur le lien
#        OSC 8 l'ouvre une fois en noopener sans confirm, T14.5 témoin de l'espion (un appel délibéré au presse-papiers est compté)
#   T15  traits de boîte (J3 de la critique 71) : ╭──╮│╰──╯ imprimée dans le shell de la page Q réelle, relevée par balayage de pixels le long de ses quatre
#        bords aux densités 1, 1.25, 1.5, 2 et 2.2 : aucun pixel de trou (T15.1, avec témoin : la boîte est trouvée et sa capture n'est pas vide)
#   T16  liens non http (F7 de l'audit, partie xterm) : un lien OSC 8 javascript: ou data: ne s'ouvre pas au clic, un lien https le fait dans la même scène (témoin)
#   M-*  mutants (copies du module par cockpit_module_muter, ou du moteur pour l'assistant ; « mutant sans effet » = FAIL) : M-CTRLC (T13.8), M-DCS et M-WINOPT (T14.1, mesure de A2),
#        M-CLIP (T14.2), M-LIEN (T14.3/T14.4), M-BOITE (T15.1 : police des traits de boîte retirée de la page), M-PROTO (T16 : allowNonHttpProtocols ouvert)
# Chrome requis pour toutes les sections : sans lui la suite annonce « SUITE SAUTÉE (navigateur) », ne compte rien et sort 1 (anti-vert-à-vide).
# Limite assumée : Chrome headless Linux n'a pas de pointeur fin (pointer: none) et son presse-papiers n'est pas observable depuis la page ; on
# mesure donc les APPELS à navigator.clipboard.* et document.execCommand par espions posés avant la page, jamais le contenu du presse-papiers du poste.
# Variables : VF_XTERM_MS (échéance d'une attente navigateur, 20000 par défaut). Exit 0 si tout passe, 1 sinon.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
ENG="$(cd "$SCRIPTS/../skills/cockpit-moteur" && pwd -P)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/tmp.XXXXXX")"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude/scripts" "$WORK/bin" "$WORK/run" "$WORK/temoins"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
export CHROME_SESSION="$HERE_T/chrome-session.mjs"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
. "$(dirname "$0")/socle-serveur.sh"
PASS=0; FAIL=0
court() { if [ "${#1}" -gt 300 ]; then printf '%s […] %s' "${1:0:140}" "${1: -140}"; else printf '%s' "$1"; fi; }
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$(court "$3")]"; echo "     obtenu:  [$(court "$2")]"; FAIL=$((FAIL+1)); fi; }
cp "$HERE_T/temoins/plein-ecran.py" "$WORK/temoins/plein-ecran.py"; cp "$HERE_T/temoins/hostile.py" "$WORK/temoins/hostile.py"
# récepteur du rejeu (R1) : écrit dans le journal chaque morceau d'entrée (« I <hex> »), « M » au premier silence, répond « q » par une question neuve, « x » l'arrête
cat > "$WORK/temoins/rejeu.py" <<'PY'
import os, select, sys, termios, time, tty
journal = sys.argv[1]
fd = sys.stdin.fileno()
ancien = termios.tcgetattr(fd)
def noter(s):
    with open(journal, 'a') as f:
        f.write(s + '\n')
try:
    tty.setraw(fd)
    sys.stdout.write('\033[c\033[>c\033[6n\033[?2004$p\033[5n')
    sys.stdout.write('REJEU-PRET\r\n')
    sys.stdout.flush()
    dernier, marque, limite = time.time(), False, time.time() + 120
    while time.time() < limite:
        pret, _, _ = select.select([fd], [], [], 0.1)
        if pret:
            d = os.read(fd, 4096); dernier = time.time(); noter('I ' + d.hex())
            if b'q' in d:
                sys.stdout.write('\033[c'); sys.stdout.flush()
            if b'g' in d:
                sys.stdout.write('GROS-DEBUT\r\n' + '\033[6n' * 60000 + 'GROS-PRET\r\n'); sys.stdout.flush()
            if b'x' in d:
                break
        elif not marque and time.time() - dernier > 0.6:
            marque = True; noter('M')
finally:
    termios.tcsetattr(fd, termios.TCSADRAIN, ancien)
PY

CHROME=""
for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue
  if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
if [ -z "$CHROME" ]; then echo "  ⊘ SUITE SAUTÉE (navigateur) : TERM-09 (navigateur) et TERM-10 (comportement) NON vérifiés, non comptés comme réussis"; exit 1; fi

# shell de test : marqué par son chemin (hygiene.sh le retrouve), bash interactif sans exec, invite « VFP> »
printf "PS1='VFP> '\nbind 'set enable-bracketed-paste off' 2>/dev/null\n" > "$WORK/rc"
printf '#!/bin/sh\nbash --rcfile "%s/rc" -i\n' "$WORK" > "$WORK/bin/shell-test"; chmod +x "$WORK/bin/shell-test"; export SHELL="$WORK/bin/shell-test"

cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/hex.mjs" <<'JS'
// hex.mjs <fichier> has <octets-hex> | re <expression régulière sur l'hexadécimal> | len : « oui »/« non » (len : le nombre d'octets) ; fichier absent : « absent »
import fs from 'node:fs';
const [, , f, cmd, arg] = process.argv; let h; try { h = fs.readFileSync(f, 'utf8').trim(); } catch { console.log('absent'); process.exit(0); }
if (cmd === 'has') console.log(Buffer.from(h, 'hex').includes(Buffer.from(arg, 'hex')) ? 'oui' : 'non');
else if (cmd === 're') console.log(new RegExp(arg).test(h) ? 'oui' : 'non');
else console.log(Buffer.from(h, 'hex').length);
JS
cat > "$AUX/chrome-xterm.mjs" <<'JS'
// chrome-xterm.mjs <chrome> <mode> <json> : scénarios navigateur du terminal réel ; UNE ligne JSON. Modes : plein · hostile · boite · liens.
// Q est jouée en PREMIER niveau (le secret est dans son stockage) après l'amorçage ; saisie par Input.insertText puis Entrée par dispatchKeyEvent.
// Chaque étape est isolée (essai) : une mesure indisponible est nommée dans `erreurs`, jamais un résultat vide. Amorçage et secret ne sont jamais rendus.
import { pathToFileURL } from 'node:url';
// décodeur PNG minimal (RGB/RGBA 8 bits, non entrelacé) : la capture de Chrome n'a pas d'autre forme
import zlib from 'node:zlib';
function png(buf) {
  let p = 8, w, h, ct; const idat = [];
  while (p < buf.length) { const len = buf.readUInt32BE(p), type = buf.toString('ascii', p + 4, p + 8), d = buf.subarray(p + 8, p + 8 + len);
    if (type === 'IHDR') { w = d.readUInt32BE(0); h = d.readUInt32BE(4); ct = d[9]; } if (type === 'IDAT') idat.push(d); p += 12 + len; }
  const bpp = ct === 6 ? 4 : 3, raw = zlib.inflateSync(Buffer.concat(idat)), st = w * bpp, px = Buffer.alloc(h * st);
  for (let y = 0; y < h; y++) { const f = raw[y * (st + 1)]; for (let x = 0; x < st; x++) { const a = x >= bpp ? px[y * st + x - bpp] : 0, b = y ? px[(y - 1) * st + x] : 0, c = x >= bpp && y ? px[(y - 1) * st + x - bpp] : 0;
      let v = raw[y * (st + 1) + 1 + x]; if (f === 1) v += a; else if (f === 2) v += b; else if (f === 3) v += (a + b) >> 1; else if (f === 4) { const q = a + b - c, pa = Math.abs(q - a), pb = Math.abs(q - b), pc = Math.abs(q - c); v += pa <= pb && pa <= pc ? a : pb <= pc ? b : c; } px[y * st + x] = v & 255; } }
  return { w, h, lum: (x, y) => { const i = y * st + x * bpp; return (px[i] + px[i + 1] + px[i + 2]) / 3; } };
}
// trous le long d'un trait : un pixel du trait sans encre (luminance > 60 dans ±2 densités autour de l'axe) est un trou
const PHASES = [0, 0.25, 0.5, 0.75];
const trous = (arr) => arr.reduce((n, v) => n + (v ? 0 : 1), 0);
const { executer, pause, stabiliser, attendreValeur, attendreEtStabiliser, AMORCE } = await import(pathToFileURL(process.env.CHROME_SESSION).href);
const [, , chrome, mode, brut] = process.argv;
const { P, Q, amorce, plein, hostile, sortieHex, recepteurHex, avecRecepteur, densite, dossier, journal, recepteurPy } = JSON.parse(brut);
const OQ = `http://127.0.0.1:${Q}`, MS = Number(process.env.VF_XTERM_MS) || 20000;
const erreurs = {};
const essai = async (nom, f) => { try { return await f(); } catch (e) { erreurs[nom] = String(e.message).slice(0, 140); return undefined; } };
const TXT = `((document.querySelector('.xterm-rows') || {}).textContent || '').replace(/\\u00a0/g, ' ')`;
// espions posés AVANT la page : presse-papiers (navigator.clipboard.*, document.execCommand), window.open, confirm
const ESPION = `(() => { const E = window.__esp = { clip: 0, exec: 0, confirm: 0, open: [] };
  const c = navigator.clipboard; if (c) for (const m of ['writeText', 'write', 'readText', 'read']) c[m] = function () { E.clip++; return Promise.resolve(m.indexOf('read') === 0 ? '' : undefined); };
  document.execCommand = function () { E.exec++; return false; };
  window.open = function () { E.open.push(Array.prototype.map.call(arguments, String)); return null; };
  window.confirm = function () { E.confirm++; return false; };
})()`;

// Q n'ouvre un shell que dans son cadre (F4, P71-D-25) : toute la suite joue Q dans un cadre sandbox de P, plein viewport, comme le tiroir.
// `sp` = session de P ; `s` = même interface, mais ev/attendre/naviguer visent le monde principal du cadre de Q (les espions et vfTermVue y vivent).
// Le contexte du cadre est retrouvé par sondage des identifiants (le socle n'expose pas les évènements) : le plus récent à porter window.vfTermVue.
const OP = `http://127.0.0.1:${P}`, SBX = 'allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox';
let ctx = 0, theme = 'dark';
// amorçage (Chrome à froid : premier chargement de P, du cadre de Q, premier terminal) : borné par AMORCE (échéance globale), jamais par MS ; les attentes suivantes restent à MS
let froid = true; const msA = () => (froid && !process.env.VF_XTERM_MS ? Math.max(MS, AMORCE) : MS); // VF_XTERM_MS posé (mutant M-CTRLC) : échéance courte voulue, comme dans les autres suites
const monde = async (sp, etendue = 600) => {
  let trouve = 0;
  for (let id = 1; id < etendue; id++) {
    const v = await sp.send('Runtime.evaluate', { contextId: id, expression: `location.origin === ${JSON.stringify(OQ)} && typeof window.vfTermVue === 'object'`, returnByValue: true }).then((x) => x && x.result && x.result.value, () => false);
    if (v === true) trouve = id;
  }
  return trouve;
};

// R1.3 (P71-D-36) : le test fait tomber la frappe EXACTEMENT entre l'arrivée du rejeu et son traitement (API d'xterm exposée ici seulement, injectée avant la page, origine de Q seulement) :
// les morceaux reçus sont retenus ; au dernier (GROS-PRET), un minuteur de frappe est posé AVANT la remise de la file à xterm, qui l'écrit aussitôt. La frappe s'exécute donc après l'écriture
// et avant le minuteur d'xterm qui analyse les 60000 questions : un minuteur de fermeture posé par l'événement passerait APRÈS celui d'xterm et laisserait toutes les réponses partir.
// moment relève si l'analyse était finie quand la frappe est tombée (« avant » : la fenêtre est bien celle-là)
const RALENTI = `(() => { if (location.origin !== ${JSON.stringify(OQ)}) return; let T; const E = window.__ralenti = { retenus: 0, cle: false, libere: false, traite: false, moment: '', file: [], queue: '' };
  Object.defineProperty(window, 'Terminal', { configurable: true, get() { return T; }, set(v) { T = class extends v {
    write(d, cb) {
      if (E.libere) return super.write(d, cb);
      // télémétrie seule : clôtures du client (write('') posées par son minuteur de silence, 150 ms) VUES avant la libération ; elles sont retenues comme toute écriture, puis rejouées dans l'ordre
      if (d === '') E.vides = (E.vides || 0) + 1;
      E.file.push([d, cb]); E.retenus++;
      if (!E.armee && typeof d !== 'string') { const t = E.queue + new TextDecoder('latin1').decode(d); E.queue = t.slice(-16);
        if (t.includes('GROS-PRET')) { E.armee = true;
          setTimeout(() => { E.moment = E.traite ? 'apres' : 'avant'; const ta = document.querySelector('.xterm-helper-textarea'); ta.dispatchEvent(new KeyboardEvent('keypress', { key: 'k', code: 'KeyK', keyCode: 107, charCode: 107, which: 107, bubbles: true, cancelable: true })); E.cle = true; }, 0);
          E.libere = true; E.file.forEach(([x, c]) => super.write(x, () => { E.traite = true; if (c) c(); })); } }
    } }; } }); })()`;
const OUVERTURE = `(() => { let T; Object.defineProperty(window, 'Terminal', { configurable: true, get() { return T; }, set(v) {
  T = class extends v { open(...a) { if (location.origin !== ${JSON.stringify(OP)}) window.__ouv = { police: document.fonts.check('13px "JetBrains Mono"'), statut: document.fonts.status }; return super.open(...a); } }; } }); })()`;

await executer(chrome, async (sp) => {
  const evCadre = async (expression) => { const x = await sp.send('Runtime.evaluate', { expression, contextId: ctx, returnByValue: true, awaitPromise: true }); return x && x.result && x.result.value; };
  const attCadre = async (expr, nom, ms = MS) => {
    const fin = Date.now() + ms; let v;
    do { try { v = await evCadre(expr); } catch { v = false; } if (v) return v; await pause(100); } while (Date.now() < fin);
    throw new Error(`attente de « ${nom} » dépassée (${ms} ms)`);
  };
  const ouvrirCadre = async () => {
    ctx = 0;
    await sp.naviguer(`${OP}/project.html`); await sp.attendre(`document.readyState === 'complete'`, 'page P', msA());
    await sp.ev(`(() => { document.querySelectorAll('iframe[data-t]').forEach((f) => f.remove()); const f = document.createElement('iframe'); f.dataset.t = '1'; f.setAttribute('sandbox', ${JSON.stringify(SBX)});
      f.style.cssText = 'position:fixed;left:0;top:0;width:100vw;height:100vh;border:0;z-index:99999'; f.src = '${OQ}/?theme=${theme}'; document.body.appendChild(f); })()`);
    const fin = Date.now() + msA();
    let essais = 0;
    while (!ctx) { ctx = await monde(sp, 600 * 5 ** Math.min(essais++, 3)); if (!ctx) { if (Date.now() > fin) throw new Error('contexte du cadre de Q introuvable'); await pause(150); } }
    await attCadre(`!!document.querySelector('.xterm-helper-textarea') || !!document.querySelector('#etat:not([hidden])')`, 'terminal ou carte dans le cadre', msA());
    await sp.ev(`document.querySelector('iframe[data-t]').focus()`); await evCadre(`(document.querySelector('.xterm-helper-textarea') || document.body).focus()`);
  };
  const s = { send: sp.send, ev: evCadre, attendre: attCadre, naviguer: ouvrirCadre };
  const att = (expr, nom) => s.attendre(expr, nom, MS);
  const r = { erreurs };
  const touche = async (o) => { await s.send('Input.dispatchKeyEvent', { type: 'keyDown', ...o }); await s.send('Input.dispatchKeyEvent', { type: 'keyUp', key: o.key, code: o.code, windowsVirtualKeyCode: o.windowsVirtualKeyCode, modifiers: o.modifiers }); };
  const taper = async (texte) => { await s.send('Input.insertText', { text: texte }); await touche({ key: 'Enter', code: 'Enter', windowsVirtualKeyCode: 13, text: '\r' }); };
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true }).catch(() => {});
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: ESPION });
  // T15 : à l'ouverture du terminal (premier chargement de Q), la police des cellules est-elle prête ? Relevé posé avant la page par un accesseur sur `Terminal`.
  if (mode === 'boite') await s.send('Page.addScriptToEvaluateOnNewDocument', { source: OUVERTURE });
  // T15 : la densité est posée AVANT le premier chargement de Q, qui est donc le chargement à froid mesuré (aucun rechargement pour « chauffer » la police)
  if (mode === 'boite') await s.send('Emulation.setDeviceMetricsOverride', { width: 700, height: 420, deviceScaleFactor: densite, mobile: false });

  // amorçage dans l'onglet puis Q dans son cadre jusqu'à l'invite du shell
  await essai('amorcage', async () => {
    // SAF-1 : l'amorçage passe par la page Projet, qui monte le cadre de Q ; l'échange se fait dans le cadre (prêt = message ready de Q, après son rechargement sans fragment)
    await sp.send('Page.addScriptToEvaluateOnNewDocument', { source: `if (window.top === window) { window.__prets = []; addEventListener('message', (e) => { if (typeof e.data === 'string') window.__prets.push(e.data); }); }` });
    await sp.naviguer(`http://127.0.0.1:${P}/project.html#t=${amorce}`);
    await sp.attendre(`window.__prets.includes('ready') && !location.hash`, 'cadre de Q prêt (échange fait dans le cadre)', msA());
  });
  await essai('invite', async () => { await s.naviguer(); await attCadre(`${TXT}.includes('VFP>')`, 'invite du shell', msA()); r.invite = true; });
  froid = false; // le terminal a répondu une fois (ou l'amorçage a échoué nommé) : tout ce qui suit est une attente ordinaire
  if (!r.invite) return r;

  if (mode === 'collage') { // F2 (P71-D-26) : un texte à retour à la ligne ou à caractère de contrôle n'atteint le shell qu'après « Coller »
    const M = (n) => `${dossier}/${n}`, ent = () => s.ev(`window.__ent.join('')`), bandeau = () => s.ev(`!!document.getElementById('collage')`);
    const nb = () => s.ev(`document.querySelectorAll('#collage').length`);
    const coller = (t) => s.ev(`(() => { const dt = new DataTransfer(); dt.setData('text/plain', ${JSON.stringify(t)}); const ta = document.querySelector('.xterm-helper-textarea');
      ta.dispatchEvent(new ClipboardEvent('paste', { clipboardData: dt, bubbles: true, cancelable: true })); return true; })()`);
    const bouton = (nom) => s.ev(`[...document.querySelectorAll('#collage button')].find((b) => b.textContent === ${JSON.stringify(nom)}).click()`);
    const existe = async (n) => (await import('node:fs')).existsSync(M(n));
    // on mesure une fois posé : l'attente est POSITIVE (bandeau, octet reçu, marqueur créé) ; les durées fixes qui suivent ne servent qu'à prouver une absence
    const attBandeau = () => attendreValeur(bandeau, (v) => v === true);
    const attEnt = (sous) => attendreValeur(ent, (v) => typeof v === 'string' && v.includes(sous));
    const attExiste = (n) => attendreValeur(() => existe(n), (v) => v === true);
    await s.ev(`(() => { window.__ent = []; const f0 = window.fetch; window.fetch = function (u, o) { if (String(u) === '/entree' && o && o.body) window.__ent.push(new TextDecoder().decode(o.body)); return f0.apply(this, arguments); }; })()`);
    // une ligne collée sans Entrée reste dans la ligne de commande du shell : Ctrl+U la vide avant chaque cas qui crée un marqueur
    const vide = async () => { await touche({ key: 'u', code: 'KeyU', windowsVirtualKeyCode: 85, modifiers: 2 }); await attEnt('\u0015'); await s.ev(`window.__ent.length = 0`); };
    r.c = {};
    await essai('une-ligne', async () => { await coller('echo UNE""LIGNE'); await attEnt('echo UNE""LIGNE'); r.c.une = { bandeau: await bandeau(), entre: (await ent()).includes('echo UNE""LIGNE') }; });
    await essai('multi', async () => {
      await vide(); await coller(`touch ${M('m1')}\n`); await attBandeau(); await pause(1200);
      r.c.multi = { bandeau: await bandeau(), entre: await ent(), marqueur: await existe('m1'), focus: await s.ev(`document.activeElement.textContent`),
        cibles: await s.ev(`[...document.querySelectorAll('#collage button')].map((b) => Math.round(b.getBoundingClientRect().height)).join(',')`) };
    });
    await essai('annuler', async () => { await bouton('Annuler'); await pause(1200); r.c.annuler = { bandeau: await bandeau(), entre: await ent(), marqueur: await existe('m1') }; });
    await essai('echap', async () => {
      await coller(`touch ${M('m2')}\n`); await attBandeau(); const avant = await bandeau();
      await touche({ key: 'Escape', code: 'Escape', windowsVirtualKeyCode: 27 }); await pause(1200);
      r.c.echap = { avant, bandeau: await bandeau(), entre: await ent(), marqueur: await existe('m2') };
    });
    await essai('remplace', async () => {
      await vide(); await coller(`touch ${M('rA')}\n`); await coller(`touch ${M('rB')}\n`); await attendreValeur(nb, (v) => v === 1); const n = await nb();
      await bouton('Coller'); await attExiste('rB'); await pause(2000);
      r.c.remplace = { bandeaux: n, A: await existe('rA'), B: await existe('rB') };
    });
    await essai('ligne-abandonne', async () => {
      await coller(`touch ${M('l1')}\n`); await attBandeau(); await coller('echo SUITE""OK'); await attEnt('echo SUITE""OK'); await pause(600); // attente positive faite : la fenêtre fixe prouve que l'ancien texte (touch l1) n'est PAS envoyé
      r.c.abandonne = { bandeau: await bandeau(), entre: (await ent()).includes('echo SUITE""OK'), marqueur: await existe('l1') };
    });
    await essai('controle', async () => { await vide(); await coller('echo \u001b[31mx'); await attBandeau(); r.c.controle = { bandeau: await bandeau(), texte: await s.ev(`(document.querySelector('#collage .vf-q-texte') || {}).textContent`) }; await bouton('Annuler'); });
    await essai('html', async () => {
      await coller('<img src=x onerror=window.__pwn=1>\n'); await attBandeau(); await pause(500);
      r.c.html = { img: await s.ev(`document.querySelectorAll('#collage img, #collage script').length`), pwn: await s.ev(`window.__pwn === undefined`), litteral: await s.ev(`document.getElementById('collage').textContent.includes('<img src=x')` ), enfants: await s.ev(`document.getElementById('collage-apercu').children.length`) };
      await bouton('Annuler');
    });
    await essai('c12', async () => { // charge au-delà du 275e caractère : visible dans le DOM du bandeau AVANT le clic, rien d'exécuté avant le clic
      const charge = `touch ${M('c12')}`; await coller('a'.repeat(275) + '; ' + charge + '\n'); await attBandeau(); await pause(400);
      r.c.c12 = { visible: await s.ev(`document.getElementById('collage-apercu').textContent.includes(${JSON.stringify(charge)})`), marqueur: await existe('c12'),
        zone: await s.ev(`(() => { const z = document.getElementById('collage-apercu'); return z.tabIndex === 0 && getComputedStyle(z).overflowY === 'auto'; })()`) };
      await bouton('Annuler');
    });
    await essai('compte', async () => { await coller('ab\ncd\nef'); await attBandeau(); r.c.compte = await s.ev(`document.querySelector('#collage .vf-q-decompte').textContent`); await bouton('Annuler'); });
    await essai('invisibles', async () => { // U+202E et U+200B rendus visibles à l'affichage ; le texte envoyé reste octet pour octet l'original (sha256)
      await vide(); await s.ev(`window.__ent.length = 0`); const orig = 'echo a\u202eb\u200bc\n'; await coller(orig); await attBandeau();
      const aff = await s.ev(`document.getElementById('collage-apercu').textContent`);
      await bouton('Coller'); await attendreEtStabiliser(ent, (v) => typeof v === 'string' && v.length > 0); const h = async (x) => (await import('node:crypto')).createHash('sha256').update(x, 'utf8').digest('hex');
      r.c.invis = { u202e: aff.includes('\u27e8U+202E\u27e9'), u200b: aff.includes('\u27e8U+200B\u27e9'), brut: !aff.includes('\u202e') && !aff.includes('\u200b'),
        sha: (await h(await ent())) === (await h(orig.replace(/\n/g, '\r'))) };
    });
    await essai('long', async () => { // borne d'affichage dite, et levée par « Tout afficher »
      await coller('z'.repeat(30000) + '\n'); await attBandeau();
      const note = await s.ev(`(document.querySelector('#collage .vf-q-reste .vf-q-texte') || {}).textContent`); const avant = await s.ev(`document.getElementById('collage-apercu').textContent.length`);
      await bouton('Tout afficher'); const apres = await attendreValeur(() => s.ev(`document.getElementById('collage-apercu').textContent.length`), (v) => v >= 30000);
      r.c.long = { note, avant, apres, reste: await s.ev(`!!document.querySelector('#collage .vf-q-reste')`) }; await bouton('Annuler');
    });
    // N9 (P71-D-30) : UNE ligne portant un invisible ou un caractère de contrôle d'affichage demande confirmation ; « Coller » reste le seul chemin vers le shell
    const entree = () => touche({ key: 'Enter', code: 'Enter', windowsVirtualKeyCode: 13, text: '\r' });
    r.c.n9 = {};
    for (const [nom, car] of [['bidi', '\u202e'], ['zwsp', '\u200b'], ['tag', '\u{E0041}']]) {
      await essai(`n9-${nom}`, async () => {
        await vide(); const orig = `echo hello${car}; touch ${M('n9' + nom)}; `; await coller(orig); await attBandeau(); await pause(600);
        const sans = { bandeau: await bandeau(), marqueur: await existe('n9' + nom), entre: (await ent()) };
        await bouton('Coller'); await attEnt('hello'); await entree(); await attExiste('n9' + nom);
        r.c.n9[nom] = { ...sans, apres: await existe('n9' + nom) };
      });
    }
    await essai('n9-ordinaire', async () => { await vide(); await coller('echo café àî""OK'); await attEnt('café'); r.c.n9.ordinaire = { bandeau: await bandeau(), entre: (await ent()).includes('café') }; });
    // N10 (P71-D-30) : ce qui est confirmé est visible sans défilement ; les suites de lignes vides sont repliées ; le dépassement est dit ; l'envoi reste l'original (sha256)
    await essai('n10', async () => {
      await vide(); const orig = '\n'.repeat(60) + `touch ${M('n10')}\n`; await coller(orig); await attBandeau();
      const mesure = await stabiliser(() => s.ev(`(() => { const z = document.getElementById('collage-apercu'); return { txt: z.textContent, debord: z.scrollHeight > z.clientHeight + 1, avert: !!document.querySelector('#collage .vf-q-depasse'), focus: document.activeElement.textContent }; })()`));
      await pause(600); // fenêtre d'absence après le bandeau : rien ne doit avoir tourné avant « Coller »
      const sans = await existe('n10'); await bouton('Coller'); await attExiste('n10'); const h = async (x) => (await import('node:crypto')).createHash('sha256').update(x, 'utf8').digest('hex');
      r.c.n10 = { replie: mesure.txt.includes('⟨' + 60 + ' lignes vides⟩'), charge: mesure.txt.includes(`touch ${M('n10')}`), debord: mesure.debord, avert: mesure.avert, focus: mesure.focus, longueur: mesure.txt.length,
        sans, apres: await existe('n10'), sha: (await h(await ent())) === (await h(orig.replace(/\n/g, '\r'))) };
    });
    await essai('n10-depasse', async () => {
      await vide(); await coller('ligne\n'.repeat(200)); await attBandeau();
      r.c.n10d = await stabiliser(() => s.ev(`(() => { const z = document.getElementById('collage-apercu'); const w = document.querySelector('#collage .vf-q-depasse'); return { debord: z.scrollHeight > z.clientHeight + 1, texte: w ? w.textContent : '', focus: document.activeElement.textContent }; })()`));
      await bouton('Tout afficher').catch(() => {}); await bouton('Annuler');
    });
    await essai('depot', async () => {
      const lance = (code) => s.ev(`(() => { const ta = document.querySelector('.xterm-helper-textarea'); ${code} })()`);
      r.c.depot = { drop: await lance(`const dt = new DataTransfer(); dt.setData('text/plain', 'touch ${M('d1')}\\n'); return ta.dispatchEvent(new DragEvent('drop', { dataTransfer: dt, bubbles: true, cancelable: true }));`) };
      await attBandeau(); r.c.depot.bandeau = await bandeau(); if (r.c.depot.bandeau) await bouton('Annuler');
      r.c.depot.avant = await lance(`return ta.dispatchEvent(new InputEvent('beforeinput', { inputType: 'insertFromDrop', data: 'a\\nb', bubbles: true, cancelable: true }));`);
      await attBandeau(); r.c.depot.bandeau2 = await bandeau(); if (r.c.depot.bandeau2) await bouton('Annuler');
      await pause(500); r.c.depot.entre = (await ent()).includes('touch ' + M('d1')) || (await ent()).includes('a\rb') || (await ent()).includes('a\nb'); r.c.depot.marqueur = await existe('d1');
    });
    await essai('coller', async () => {
      await vide(); await coller(`touch ${M('ok')}\n`); await attBandeau(); r.c.avantColler = await existe('ok'); await bouton('Coller'); await attExiste('ok');
      r.c.coller = { marqueur: await existe('ok'), bandeau: await bandeau(), entree_ok: (await ent()) === 'touch ' + M('ok') + '\r' };
    });
    return r;
  }
  if (mode === 'boite') { // une boîte de 8 colonnes sur 4 lignes dans le shell réel, une page neuve par densité de pixels
    const BOITE = "clear; printf '\\342\\225\\255\\342\\224\\200\\342\\224\\200\\342\\224\\200\\342\\224\\200\\342\\224\\200\\342\\224\\200\\342\\225\\256\\n\\342\\224\\202      \\342\\224\\202\\n\\342\\224\\202      \\342\\224\\202\\n\\342\\225\\260\\342\\224\\200\\342\\224\\200\\342\\224\\200\\342\\224\\200\\342\\224\\200\\342\\224\\200\\342\\225\\257\\n'";
    r.boite = {}; const d = densite; // la densité est celle du navigateur lui-même (--force-device-scale-factor, posé par le lanceur de la suite)
    await essai(`boite-${d}`, async () => {
      // xterm mesure la cellule une fois, à l'ouverture : mesurée avant la police (15 px au lieu de 17), elle n'est jamais remesurée. Le premier chargement doit donc donner 17 px.
      await att(`document.fonts.status === 'loaded' && document.fonts.check('13px "JetBrains Mono"')`, 'polices chargées');
      r.froid = await s.ev(`document.querySelector('.xterm-rows > div').getBoundingClientRect().height`); // hauteur de LIGNE posée par xterm à l'ouverture (l'élément de mesure, lui, suit la police et dirait 17 après coup)
      r.ouverture = await s.ev(`window.__ouv || null`);
      if (!(r.froid >= 16.5)) throw new Error(`cellule à froid de ${r.froid} px : mesurée avant JetBrains Mono (premier chargement)`);
      r.boite[d] = { pixels: 0, trous: 0, phases: {}, cellule: 0 };
      // la phase est le décalage vertical sous-pixel de la grille (px CSS) : à densité fractionnaire, les coutures entre lignes en dépendent
      for (const ph of PHASES) {
        await s.ev(`document.getElementById('terminal').style.top = '${ph}px'`);
        const GEO = `(() => { const w = document.createTreeWalker(document.querySelector('.xterm-rows'), NodeFilter.SHOW_TEXT); let n, hit = null;
          while ((n = w.nextNode())) { const i = n.data.indexOf('╭──────╮'); if (i >= 0) hit = { n, i }; }
          if (!hit) return null; const rg = document.createRange(); rg.setStart(hit.n, hit.i); rg.setEnd(hit.n, hit.i + 1); const a = rg.getBoundingClientRect();
          rg.setStart(hit.n, hit.i + 7); rg.setEnd(hit.n, hit.i + 8); const b = rg.getBoundingClientRect(); const ligne = hit.n.parentElement.closest('.xterm-rows > div').getBoundingClientRect();
          return { ox: a.left, cw: (b.right - a.left) / 8, oy: ligne.top, ch: ligne.height, dpr: devicePixelRatio }; })()`;
        await taper('clear'); await att(`!(${GEO})`, 'boîte de la phase précédente effacée'); // sinon l\'attente suivante trouverait l\'ancienne boîte (phases 2 à 4)
        await taper(BOITE);
        await att(`!!(${GEO})`, "boîte à l'écran");
        const g = await stabiliser(() => s.ev(GEO)); // la grille est posée (deux lectures identiques) : la capture suit
        const shot = await s.send('Page.captureScreenshot', { format: 'png' }), im = png(Buffer.from(shot.data, 'base64')), S = g.dpr;
        const encre = (x, y, axe) => { for (let k = -2 * S; k <= 2 * S; k++) { const X = Math.round(axe === 'v' ? x + k : x), Y = Math.round(axe === 'v' ? y : y + k); if (im.lum(X, Y) > 60) return true; } return false; };
        const vert = (col) => { const a = [], x = (g.ox + (col + 0.5) * g.cw) * S; for (let y = Math.ceil((g.oy + 0.5 * g.ch) * S) + 2 * S; y < (g.oy + 3.5 * g.ch) * S - 2 * S; y++) a.push(encre(x, y, 'v')); return a; };
        const hori = (row) => { const a = [], y = (g.oy + (row + 0.5) * g.ch) * S; for (let x = Math.ceil((g.ox + 0.5 * g.cw) * S) + 2 * S; x < (g.ox + 7.5 * g.cw) * S - 2 * S; x++) a.push(encre(x, y, 'h')); return a; };
        const bords = [vert(0), vert(7), hori(0), hori(3)], px = bords.reduce((n, a) => n + a.length, 0), tr = bords.reduce((n, a) => n + trous(a), 0);
        r.boite[d].cellule = g.ch; r.boite[d].phases[ph] = tr; r.boite[d].pixels += px; r.boite[d].trous += tr; r.boite[d].echelle = S;
      }
    });
    return r;
  }
  if (mode === 'liens') { // trois liens OSC 8 dans le shell réel : https (témoin), javascript: et data:
    await essai('liens', async () => {
      const L = (u, t) => `\\033]8;;${u}\\033\\\\${t}\\033]8;;\\033\\\\`;
      await taper(`clear; printf '${L('https://ok.test/', 'LIENOK')} ${L('javascript:void(0)', 'LIENJS')} ${L('data:text/html,x', 'LIENDATA')}\\n'`);
      await att(`${TXT}.includes('LIENOK') && ${TXT}.includes('LIENDATA') && !${TXT}.includes('printf')`, "trois liens à l'écran");
      for (const lib of ['LIENOK', 'LIENJS', 'LIENDATA']) {
        const pt = await stabiliser(() => s.ev(`(() => { const w = document.createTreeWalker(document.querySelector('.xterm-rows'), NodeFilter.SHOW_TEXT); let n, hit = null;
          while ((n = w.nextNode())) { const i = n.data.lastIndexOf(${JSON.stringify(lib)}); if (i >= 0 && n.data.indexOf('printf') < 0) hit = { n, i }; }
          if (!hit) return null; const rg = document.createRange(); rg.setStart(hit.n, hit.i + 1); rg.setEnd(hit.n, hit.i + 3); const b = rg.getBoundingClientRect(); return { x: b.left + b.width / 2, y: b.top + b.height / 2 }; })()`));
        if (!pt) throw new Error(`cellule ${lib} absente de la grille`);
        await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: pt.x - 2, y: pt.y }); await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: pt.x, y: pt.y });
        if (lib === 'LIENOK') await attendreValeur(() => s.ev(`!!document.querySelector('.xterm-cursor-pointer')`), (v) => v === true, { max: 3000 }); else await pause(150); // seul le lien https est un lien survolable : les deux autres n'ont aucun état à attendre
        await s.send('Input.dispatchMouseEvent', { type: 'mousePressed', x: pt.x, y: pt.y, button: 'left', clickCount: 1 });
        await s.send('Input.dispatchMouseEvent', { type: 'mouseReleased', x: pt.x, y: pt.y, button: 'left', clickCount: 1 });
        await pause(300);
      }
      r.ouvertures = await s.ev(`JSON.parse(JSON.stringify(window.__esp.open))`);
    });
    return r;
  }

  if (mode === 'ecran') { // E3 (hauteur utile) et G3 (barre de défilement discrète) : le cadre de Q est redimensionné, la grille et la barre sont mesurées dans la page réelle
    await s.send('Emulation.setDeviceMetricsOverride', { width: 1000, height: 700, deviceScaleFactor: 1, mobile: false });
    const cadre = (w, h) => sp.ev(`document.querySelector('iframe[data-t]').style.cssText = 'position:fixed;left:0;top:0;width:${w}px;height:${h}px;border:0;z-index:99999'`);
    await s.ev(`(() => { const b = [...document.querySelectorAll('#accueil button')].find((x) => x.textContent === 'Compris'); if (b) b.click(); return true; })()`); await attendreValeur(() => s.ev(`!document.getElementById('accueil')`), (v) => v === true, { max: 3000 }); // LB3-S2 : l'accueil, dans la colonne, retire sa hauteur au terminal ; E3 mesure la hauteur utile du terminal SEUL (l'accueil a son témoin : LB.V20)
    r.e3 = {};
    for (const h of [160, 208, 280, 328, 570]) {
      await essai(`e3-${h}`, async () => {
        await cadre(600, h);
        r.e3[h] = await attendreEtStabiliser(() => s.ev(`(() => { const l = document.querySelectorAll('.xterm-rows > div'), d = l[l.length - 1].getBoundingClientRect(), z = document.querySelector('.xterm-screen').getBoundingClientRect();
          return { bas: Math.round(d.bottom * 100) / 100, visible: window.innerHeight, lignes: l.length, ecran: Math.round(z.height) }; })()`), (v) => v && v.visible === h, { pas: 300, max: 6000 });
      });
    }
    const CURSEUR = `(() => { const sl = document.querySelector('.xterm-scrollable-element > .scrollbar.vertical > .slider'); if (!sl) return null;
      const c = (v) => { const m = String(v).match(/[\\d.]+/g).map(Number); return { r: m[0], g: m[1], b: m[2], a: m.length > 3 ? m[3] : 1 }; };
      const f = c(getComputedStyle(document.getElementById('terminal')).backgroundColor), k = c(getComputedStyle(sl).backgroundColor);
      const m = (x, y) => x * k.a + y * (1 - k.a), e = { r: m(k.r, f.r), g: m(k.g, f.g), b: m(k.b, f.b) };
      const L = (o) => { const u = [o.r, o.g, o.b].map((v) => { v /= 255; return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); }); return 0.2126 * u[0] + 0.7152 * u[1] + 0.0722 * u[2]; };
      const a = L(e), b = L(f); return { alpha: k.a, couleur: getComputedStyle(sl).backgroundColor, contraste: Math.round((Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05) * 100) / 100 }; })()`;
    const barre = `(() => { const b = document.querySelector('.xterm-scrollable-element > .scrollbar.vertical'); return b ? getComputedStyle(b).opacity : 'absente'; })()`;
    await essai('barre', async () => {
      await cadre(600, 570); await pause(700);
      await taper('clear; seq 1 300'); await att(`${TXT}.includes('300')`, '300 lignes imprimées');
      await att(`${barre} !== 'absente'`, 'barre de défilement dans le DOM');
      r.g3 = { fin0: await s.ev(`${TXT}.includes('300')`) };
      await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: 900, y: 300 }); await pause(500); r.g3.dehors = await s.ev(barre); // pointeur hors du cadre
      await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: 300, y: 300 }); r.g3.survol = await attendreValeur(() => s.ev(barre), (v) => v === '1');
      r.g5 = { sombre: await attendreEtStabiliser(() => s.ev(CURSEUR), (v) => v !== null && v !== undefined) };
      await s.send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: 300, y: 300, deltaX: 0, deltaY: -400 });
      r.g3.fin1 = await attendreValeur(() => s.ev(`${TXT}.includes('300')`), (v) => v === false);
      await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: 900, y: 300 }); await pause(1600); /* durée du retardateur produit conservée : l'état de départ de G3.5 (xterm natif replié) en dépend */ r.g3.apres = await attendreValeur(() => s.ev(barre), (v) => v === '0', { max: 2500 }); // minuteur produit 1 000 ms (vf-cockpit-terminal-client.mjs, montrerBarre) : déjà écoulé après la pause, borne ~2,5x
      await touche({ key: 'PageUp', code: 'PageUp', windowsVirtualKeyCode: 33, modifiers: 8 }); await pause(400); r.g3.clavier = await s.ev(barre); // échantillon FIXE conservé : la barre native d'xterm se montre aussi au défilement, un sondage jusqu'à « 1 » verrait le mutant (montrerBarre retiré) lui aussi — M-BARRE-CLAVIER perdrait sa discrimination
      r.g3.repos = await attendreValeur(() => s.ev(barre), (v) => v === '0', { max: 2500 }); // ~1 000 ms de minuteur produit depuis PageUp (déjà 400 ms écoulées), borne ~2,5x : une régression du retardateur reste rouge
    });
    // R2 : tout l'espace du cadre suit le fond du thème (le fond de la zone de défilement de xterm est noir par défaut) — styles calculés et colonne de pixels, dans les deux thèmes
    r.fond = {};
    await essai('accueil-range', async () => { await s.ev(`(() => { const b = [...document.querySelectorAll('#accueil button')].find((x) => x.textContent === 'Compris'); if (b) b.click(); return true; })()`); await attendreValeur(() => s.ev(`!document.getElementById('accueil')`), (v) => v === true, { max: 3000 }); }); // LB3 (PU-G-140) : la phrase d'accueil de la première ouverture se pose sur le bas du cadre ; R2 mesure le fond du cadre une fois rangée, comme le fait un utilisateur
    const FOND = `(() => { const t = getComputedStyle(document.getElementById('terminal')).backgroundColor, v = getComputedStyle(document.querySelector('.xterm-viewport')).backgroundColor; return { terminal: t, viewport: v }; })()`;
    for (const th of ['dark', 'light']) {
      if (th !== theme) { theme = th; await s.naviguer(); }
      r.fond[th] = {};
      for (const h of [160, 208, 280, 328, 570]) {
        await essai(`fond-${th}-${h}`, async () => {
          await cadre(600, h); await attendreEtStabiliser(() => s.ev(`window.innerHeight`), (v) => v === h, { max: 5000 });
          const st = await stabiliser(() => s.ev(FOND)), shot = await s.send('Page.captureScreenshot', { format: 'png', clip: { x: 0, y: 0, width: 600, height: h, scale: 1 } }), im = png(Buffer.from(shot.data, 'base64'));
          const attendu = th === 'light' ? 255 : 25; let hors = 0, bas = -1;
          for (let y = 0; y < Math.min(h, im.h); y++) { const l = im.lum(560, y); if (Math.abs(l - attendu) > 6) hors++; bas = l; }
          r.fond[th][h] = { ...st, hors, bas: Math.round(bas), attendu: th === 'light' ? 'rgb(255, 255, 255)' : 'rgb(25, 25, 25)' };
        });
      }
    }
    // G5 : le curseur de la barre, au survol, est nettement visible dans le thème clair aussi (le sombre est mesuré avec la barre plus haut)
    await essai('curseur-clair', async () => {
      await cadre(600, 570); await pause(700);
      await taper('clear; seq 1 300'); await att(`${TXT}.includes('300')`, '300 lignes imprimées (clair)');
      await att(`${barre} !== 'absente'`, 'barre de défilement dans le DOM (clair)');
      await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: 300, y: 300 });
      r.g5.clair = await attendreEtStabiliser(() => s.ev(CURSEUR), (v) => v !== null && v !== undefined);
    });
    return r;
  }

  if (mode === 'rejeu') { // R1 : le tampon rejoué à chaque rechargement du cadre ne fait répondre xterm à aucune question dans l'entrée du PTY
    // le récepteur (recepteurPy) pose des questions, relève chaque morceau d'entrée dans le journal (une ligne « I <hex> »), écrit « M » au premier silence, et pose une question neuve sur « q »
    r.rejeu = {};
    const lire = async () => { try { return (await import('node:fs')).readFileSync(journal, 'utf8').split('\n').filter(Boolean); } catch { return []; } };
    await essai('rejeu', async () => {
      await taper(`python3 -I ${recepteurPy} ${journal}`);
      await att(`${TXT}.includes('REJEU-PRET')`, 'REJEU-PRET');
      const fin = Date.now() + MS; while (!(await lire()).includes('M') && Date.now() < fin) await pause(100);
      r.rejeu.marqueur = (await lire()).includes('M');
      r.rejeu.initial = (await lire()).filter((l) => l.startsWith('I ')).map((l) => l.slice(2)).join('');
      const n0 = (await lire()).length;
      for (let i = 0; i < 5; i++) { theme = i % 2 ? 'dark' : 'light'; await s.naviguer(); await att(`${TXT}.includes('REJEU-PRET')`, 'tampon rejoué'); await pause(900); }
      r.rejeu.recharges = 5;
      r.rejeu.avant = (await lire()).slice(n0).filter((l) => l.startsWith('I ')).map((l) => l.slice(2)).join('');
      const n1 = (await lire()).length;
      await s.send('Input.insertText', { text: 'q' });
      const dep = async () => (await lire()).slice(n1).filter((l) => l.startsWith('I ')).map((l) => l.slice(2)).join('');
      await attendreValeur(dep, (t) => t.startsWith('71') && /1b5b3f/.test(t));
      const apres = (await lire()).slice(n1).filter((l) => l.startsWith('I ')).map((l) => l.slice(2));
      r.rejeu.apres = apres.join(''); r.rejeu.frappe = apres.join('').startsWith('71');
      // R1 (réserve) : une frappe pendant un gros rejeu (60000 questions CPR dans le tampon) : xterm fait stopPropagation, l'autorisation « humaine » ne doit pas survivre à l'événement
      const ng = (await lire()).length;
      await s.send('Input.insertText', { text: 'g' }); await att(`${TXT}.includes('GROS-PRET')`, 'GROS-PRET');
      // ce qui s'ÉCOULE, pas seulement ce qui apparaît : les 60000 réponses VIVES (ESC[ligne;colonneR) du premier `g` traversent encore tampons Node, tube, assistant PTY et tty quand GROS-PRET est à l'écran. n2 n'est relevé qu'une fois le compte exact atteint (sinon leur fin, « 1R… », serait lue comme une fuite du cadre suivant). L'ancienne pause(1200) de R1.2 les laissait s'écouler sans le dire.
      const vives = async () => (await lire()).slice(ng).filter((l) => l.startsWith('I ')).map((l) => Buffer.from(l.slice(2), 'hex').toString('latin1')).join('').split('R').length - 1;
      const nVives = await attendreValeur(vives, (v) => v >= 60000, { pas: 500, max: 60000 });
      if (!(nVives >= 60000)) throw new Error(`réponses vives du premier gros rejeu : ${nVives} sur 60000 relevées en 60 s`);
      let tai = -1, stab = 0; const fin2 = Date.now() + 30000; while (stab < 12 && Date.now() < fin2) { const t = (await lire()).length; if (t === tai) stab++; else { stab = 0; tai = t; } await pause(100); }
      const n2 = (await lire()).length;
      await s.send('Page.addScriptToEvaluateOnNewDocument', { source: RALENTI });
      theme = 'light'; await s.naviguer();
      await att(`!!(window.__ralenti && window.__ralenti.libere && window.__ralenti.cle && window.__ralenti.traite)`, 'rejeu rendu à xterm, frappe tombée, analyse finie');
      r.rejeu.ralenti = await s.ev(`(() => { const e = window.__ralenti; return 'cle=' + e.cle + ' libere=' + e.libere + ' moment=' + e.moment; })()`);
      console.error('DIAG R1.3 vides=' + await s.ev(`window.__ralenti.vides || 0`).catch(() => 'illisible')); // télémétrie seule (stderr) : combien de clôtures de silence le ralentisseur a rejetées ; hors du JSON jugé
      tai = -1; stab = 0; const fin3 = Date.now() + 30000; while (stab < 12 && Date.now() < fin3) { const t = (await lire()).length; if (t === tai) stab++; else { stab = 0; tai = t; } await pause(100); }
      const gros = (await lire()).slice(n2).filter((l) => l.startsWith('I ')).map((l) => l.slice(2)).join('');
      // la sortie du navigateur passe par un tube de 64 Ko que process.exit() tronque : un relevé de fuite (60000 réponses) est borné, jamais recopié en entier
      r.rejeu.gros = gros.length > 400 ? gros.slice(0, 200) + '…' + gros.length / 2 + ' octets' : gros;
      console.error('DIAG R1.3 reponses-vives=' + nVives + ' journal@n2=' + n2 + ' journal@jugement=' + (await lire()).length); // télémétrie (stderr) : un futur rouge dit s'il restait un écoulement
      // R1.4 : une frappe RÉELLE (CDP, événement de confiance) après le rejeu arrive au shell, seule
      const n3 = (await lire()).length;
      for (const type of ['keyDown', 'keyUp']) await s.send('Input.dispatchKeyEvent', { type, key: 'k', code: 'KeyK', text: type === 'keyDown' ? 'k' : undefined, windowsVirtualKeyCode: 75 });
      await attendreValeur(async () => (await lire()).slice(n3).filter((l) => l.startsWith('I ')).map((l) => l.slice(2)).join(''), (t) => t.includes('6b'));
      await pause(1500); // la fenêtre fixe reste : elle prouve qu'aucun octet de plus n'arrive
      r.rejeu.reelle = (await lire()).slice(n3).filter((l) => l.startsWith('I ')).map((l) => l.slice(2)).join('');
      await s.send('Input.insertText', { text: 'x' });
    });
    return r;
  }

  if (mode === 'plein') {
    await essai('plein-ecran', async () => {
      await taper(`python3 -I ${plein}`);
      await att(`${TXT}.includes('TEMOIN-PLEIN-ECRAN-DEBUT') && ${TXT}.includes('PRET')`, 'TEMOIN-PLEIN-ECRAN-DEBUT puis PRET dans la grille');
      r.debut = true; r.pret = true;
      r.taille0 = await s.ev(`(${TXT}.match(/TAILLE (\\d+x\\d+)/) || [])[1] || ''`);
    });
    await essai('winch', async () => { // fenêtre agrandie -> ResizeObserver -> POST /taille -> SIGWINCH -> WINCH dans la grille
      const LIRE = `(() => { const m = ${TXT}.match(/WINCH (\\d+x\\d+)/g) || []; return { winch: m.length ? m[m.length - 1].slice(6) : '', n: m.length, lignes: document.querySelector('.xterm-rows').childElementCount }; })()`;
      const avant = await s.ev(LIRE); // état relevé AVANT le geste : seul un WINCH postérieur à l'agrandissement vaut mesure
      await s.send('Emulation.setDeviceMetricsOverride', { width: 1400, height: 1000, deviceScaleFactor: 1, mobile: false });
      const cond = `(() => { const m = ${TXT}.match(/WINCH (\\d+)x(\\d+)/g); if (!m) return false; const d = m[m.length - 1].match(/(\\d+)x(\\d+)/); return Number(d[1]) === document.querySelector('.xterm-rows').childElementCount; })()`;
      await att(cond, 'WINCH <lignes>x<colonnes> aux dimensions de la grille');
      // les deux valeurs se lisent dans le même instant, et seulement une fois posées : l'agrandissement produit parfois deux WINCH (la grille se réajuste après le premier), et une lecture prise entre les deux les désaccordait une fois sur deux en CI Linux (runs 42386847278, 42396920032, 42400570610)
      const lu = await attendreEtStabiliser(() => s.ev(LIRE), (v) => v && (v.n > avant.n || v.winch !== avant.winch), { pas: 400, max: 10000 });
      r.winch = lu && lu.winch; r.lignes = lu && lu.lignes;
    });
    await essai('sigint', async () => {
      await touche({ key: 'c', code: 'KeyC', windowsVirtualKeyCode: 67, modifiers: 2 });
      await att(`${TXT}.includes('SIGINT-RECU')`, 'SIGINT-RECU');
      r.sigint = true;
      r.debutApres = await attendreValeur(() => s.ev(`${TXT}.includes('TEMOIN-PLEIN-ECRAN-DEBUT')`), (v) => v === false);
    });
    if (avecRecepteur) await essai('touches', async () => {
      await att(`${TXT}.includes('VFP>')`, 'invite du shell après Ctrl-C');
      await taper(`python3 -I ${hostile} --recepteur ${recepteurHex} 30`);
      await att(`${TXT}.includes('RECEPTEUR-PRET')`, 'RECEPTEUR-PRET');
      await touche({ key: 'Escape', code: 'Escape', windowsVirtualKeyCode: 27 });
      await touche({ key: 'Tab', code: 'Tab', windowsVirtualKeyCode: 9 });
      await touche({ key: 'r', code: 'KeyR', windowsVirtualKeyCode: 82, modifiers: 2 });
      await touche({ key: 'w', code: 'KeyW', windowsVirtualKeyCode: 87, modifiers: 2 });
      await touche({ key: 'ArrowUp', code: 'ArrowUp', windowsVirtualKeyCode: 38 });
      await touche({ key: ' ', code: 'Space', windowsVirtualKeyCode: 32, modifiers: 10 }); // Ctrl+Maj+Espace : aucun octet
      await touche({ key: 'z', code: 'KeyZ', windowsVirtualKeyCode: 90, text: 'z' }); // sentinelle : fin de la lecture
      await att(`${TXT}.includes('RECEPTEUR-FIN')`, 'RECEPTEUR-FIN');
      r.touches = true;
    });
    return r;
  }

  // mode hostile : témoin de l'espion (un appel délibéré compte), puis le programme hostile, puis le clic sur le lien OSC 8
  await essai('temoin-espion', async () => {
    await s.ev(`navigator.clipboard.writeText('temoin')`);
    r.clipTemoin = await s.ev(`window.__esp.clip`);
    await s.ev(`window.__esp.clip = 0`);
  });
  await essai('hostile', async () => {
    await taper(`python3 -I ${hostile} ${sortieHex} 6`);
    await att(`${TXT}.includes('HOSTILE-FIN')`, 'HOSTILE-FIN');
    r.avant = await s.ev(`JSON.parse(JSON.stringify(window.__esp))`);
  });
  await essai('lien', async () => {
    const pt = await stabiliser(() => s.ev(`(() => { const sp = [...document.querySelectorAll('.xterm-rows span')].find((x) => x.textContent.indexOf('LIEN') >= 0); if (!sp) return null; const b = sp.getBoundingClientRect(); return { x: b.left + b.width / 2, y: b.top + b.height / 2 }; })()`));
    if (!pt) throw new Error('cellule LIEN absente de la grille');
    r.cellule = true;
    await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: pt.x - 3, y: pt.y });
    await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: pt.x, y: pt.y });
    await att(`!!document.querySelector('.xterm-cursor-pointer')`, 'survol du lien (curseur main)');
    await s.send('Input.dispatchMouseEvent', { type: 'mousePressed', x: pt.x, y: pt.y, button: 'left', clickCount: 1 });
    await s.send('Input.dispatchMouseEvent', { type: 'mouseReleased', x: pt.x, y: pt.y, button: 'left', clickCount: 1 });
    await att(`window.__esp.open.length + window.__esp.confirm >= 1`, 'ouverture du lien (window.open ou confirm)');
  });
  r.apres = await s.ev(`JSON.parse(JSON.stringify(window.__esp))`).catch(() => null);
  return r;
}, { csp: false });
JS

rq() { node "$HERE_T/terminal-aux.mjs" req "$@"; }
rj() { printf '%s\n' "$1" | node "$AUX/ev.mjs" "$2" 2>/dev/null; }
rjs() { rj "$@" || echo ILLISIBLE; } # comme rj, mais un relevé illisible (JSON tronqué, champ absent) se dit ILLISIBLE au lieu d'une chaîne vide qui ressemble à « rien reçu »
hx() { node "$AUX/hex.mjs" "$@"; }
amorce_neuve() { node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"; }
mklab() {
  local L="$1" B="$1/.planning"; mkdir -p "$L/src" "$B/phases/01-socle"; printf 'export const u = 1;\n' > "$L/src/u.js"
  printf -- '## Phases\n\n- [x] **Phase 1: Socle** - premier jet\n\n### Phase 1: Socle\n**Goal**: Poser le socle\n' > "$B/ROADMAP.md"
  printf -- '---\nstatus: executing\ncurrent_phase: 1\nmilestone: v1.0 MVP\n---\n' > "$B/STATE.md"
  printf -- '---\nwave: 1\nfiles_modified: [src/u.js]\n---\n<objective>Poser le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  node "$SCRIPTS/vf-cockpit.mjs" build --lab "$L" > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
}
SRVN=0
# 79-06 : le code ne vit plus dans la sortie. MOD_DEPOT = racine du module du dépôt ; mod_de <sortie> = racine du module que COMMANDE cette sortie
# (table posée par mutant() : sortie TAB module ; par défaut le module du dépôt).
MOD_DEPOT="$(cd "$SCRIPTS/.." && pwd -P)"; MODS_TABLE="$WORK/.mods"; : > "$MODS_TABLE"; export MODS_TABLE MOD_DEPOT
mod_de() { local m; m="$(awk -F'\t' -v s="${1:-}" '$1==s{m=$2} END{print m}' "$MODS_TABLE" 2>/dev/null)"; printf '%s\n' "${m:-$MOD_DEPOT}"; }
srv() { # srv <sortie> [moteur] -> SRV_PORT SRV_PID SRV_O SRV_OUT QP AMORCE ; serveur du MODULE de la sortie visée, lancé avec --terminal par l'aide ; un moteur copié = une copie du module dont le moteur est celui-là
  local o="$1" eng="${2:-$ENG}" lab mod; lab="$(cd "$1/../.." && pwd)"; mod="$(mod_de "$o")"
  if [ "$eng" != "$ENG" ]; then local mc="$WORK/modsrv-$((SRVN+1))"; rm -rf "$mc"; mc="$(cockpit_module_copie "$mc")" || return 1
    ( cd "$mod/scripts" && tar -cf - --exclude=tests . ) | ( cd "$mc/scripts" && tar -xf - ) && rm -rf "$mc/skills/cockpit-moteur" && cp -R "$eng" "$mc/skills/cockpit-moteur" || return 1; mod="$mc"; fi
  SRVN=$((SRVN+1)); SRV_O="$o"; SRV_OUT="$WORK/serve-$SRVN.out"; rm -f "$o/.cache/server.json" "$o/.cache/terminal-amorce"; mkdir -p "$o/.cache"
  AMORCE="$(amorce_neuve)"; (umask 077; printf '%s' "$AMORCE" > "$o/.cache/terminal-amorce")
  COCKPIT_MODULE="$mod" COCKPIT_PRET=terminal COCKPIT_LOG="$SRV_OUT" cockpit_lancer "$lab" --terminal
  SRV_PID="$VF_PID"
  SRV_PORT="${VF_PORT:-0}"; QP="$(sj '(j.terminal&&j.terminal.url)||"http://127.0.0.1:0"')"; QP="${QP##*:}"
}
sj() { node "$AUX/ev.mjs" "$1" < "$SRV_O/.cache/server.json" 2>/dev/null; }
unsrv() { vf_hyg_stop "$SRV_PID"; }
mutant() { # mutant <nom> <fichier> <expression-sed> -> MUT_OUT (copie du lab : données) et MUT_MOD (racine de la copie du module) ; code 1 si la cible manque ou si la copie n'a pas changé
  local d="$WORK/mut-$1" f; rm -rf "$d" "$WORK/mod-$1"; mkdir -p "$d"; cp -R "$LAB/.planning" "$d/.planning"; cp -R "$LAB/.vibeflow" "$d/.vibeflow"
  MUT_OUT="$d/.vibeflow/cockpit"; MUT_MOD=""
  case "$(basename "$2")" in
    serve.mjs|graph-query.js|query-cli.mjs|vf-cockpit-*) cockpit_module_muter "$1" "$2" "$3" || return 1; MUT_MOD="$COCKPIT_MODULE"; unset COCKPIT_MODULE; printf '%s\t%s\n' "$MUT_OUT" "$MUT_MOD" >> "$MODS_TABLE"; return 0 ;;
  esac
  f="$d/.vibeflow/cockpit/$2"; [ -f "$f" ] || return 1   # page de la copie du lab (donnée) : même chemin que MUT_OUT/<fichier>
  cp "$f" "$f.orig"; sed -i.bak "$3" "$f"; local r=0; cmp -s "$f" "$f.orig" && r=1; rm -f "$f.orig" "$f.bak"; return $r
}
mutant_eng() { # mutant_eng <nom> <expression-sed> -> MUT_ENG : copie du moteur dont l'assistant PTY est muté
  MUT_ENG="$WORK/eng-$1"; rm -rf "$MUT_ENG"; cp -R "$ENG" "$MUT_ENG"; local f="$MUT_ENG/terminal/vf-cockpit-pty.py"; [ -f "$f" ] || return 1
  cp "$f" "$f.orig"; sed -i.bak "$2" "$f"; local r=0; cmp -s "$f" "$f.orig" && r=1; rm -f "$f.orig" "$f.bak"; return $r
}
sans_effet() { assert_eq "$1 — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; }
rouge() { echo "     [mutant] obtenu $1, le code sain rend $2" >&2; [ "$1" != "$2" ] && echo rouge || echo "identique : $1"; }
rougelu() { case "$1" in *ILLISIBLE*) echo "illisible : $1" ;; *) rouge "$@" ;; esac; } # rouge, mais seulement si le relevé du mutant est lisible : un relevé illisible n'est pas une preuve
navig() { node "$AUX/chrome-xterm.mjs" "$CHROME" "$@"; } # navig <mode> <json>
run_plein() { # run_plein <sortie> <moteur> <avecRecepteur 0|1> -> PJ ; un serveur neuf, un amorçage neuf, un Chrome neuf
  rm -f "$WORK/rec.hex"; srv "$1" "$2"
  PJ="$(navig plein "{\"P\":$SRV_PORT,\"Q\":$QP,\"amorce\":\"$AMORCE\",\"plein\":\"$WORK/temoins/plein-ecran.py\",\"hostile\":\"$WORK/temoins/hostile.py\",\"recepteurHex\":\"$WORK/rec.hex\",\"avecRecepteur\":$3}")"; unsrv
}
run_hostile() { # run_hostile <sortie> -> HJ ; le relevé hexadécimal de l'entrée reçue est dans $WORK/hostile.hex
  rm -f "$WORK/hostile.hex"; srv "$1"
  HJ="$(navig hostile "{\"P\":$SRV_PORT,\"Q\":$QP,\"amorce\":\"$AMORCE\",\"hostile\":\"$WORK/temoins/hostile.py\",\"sortieHex\":\"$WORK/hostile.hex\"}")"; unsrv
}

DENS="1 1.25 1.5 2 2.2"
run_boite() { # run_boite <sortie> <étiquette> -> $WORK/boite-<étiquette>-<d>.json ; un serveur neuf, un amorçage neuf, un Chrome neuf par densité
  local d
  for d in $DENS; do
    srv "$1"
    node "$AUX/chrome-xterm.mjs" "$CHROME" boite "{\"P\":$SRV_PORT,\"Q\":$QP,\"amorce\":\"$AMORCE\",\"densite\":$d}" > "$WORK/boite-$2-$d.json"
    unsrv
  done
}
mesure_boite() { rj "$(cat "$WORK/boite-$1-$2.json")" "$3"; } # mesure_boite <étiquette> <d> <expression sur j>
resume_boite() { local d; for d in $DENS; do printf 'd%s=%s ' "$d" "$(mesure_boite "$1" "$d" 'j.boite&&j.boite["'"$d"'"]?j.boite["'"$d"'"].trous:"absente"')"; done; }
run_liens() { # run_liens <sortie> -> LJ
  srv "$1"
  LJ="$(navig liens "{\"P\":$SRV_PORT,\"Q\":$QP,\"amorce\":\"$AMORCE\"}")"; unsrv
}
run_collage() { # run_collage <sortie> -> CJ ; un serveur neuf, un amorçage neuf, un Chrome neuf ; les marqueurs de « shell exécuté » sont créés dans $WORK/collage
  rm -rf "$WORK/collage"; mkdir -p "$WORK/collage"; srv "$1"
  CJ="$(navig collage "{\"P\":$SRV_PORT,\"Q\":$QP,\"amorce\":\"$AMORCE\",\"dossier\":\"$WORK/collage\"}")"; unsrv
}
run_rejeu() { # run_rejeu <sortie> -> RJ ; le journal des octets reçus par le PTY est dans $WORK/rejeu.log
  rm -f "$WORK/rejeu.log"; srv "$1"
  RJ="$(navig rejeu "{\"P\":$SRV_PORT,\"Q\":$QP,\"amorce\":\"$AMORCE\",\"journal\":\"$WORK/rejeu.log\",\"recepteurPy\":\"$WORK/temoins/rejeu.py\"}")"; unsrv
}
run_ecran() { # run_ecran <sortie> -> EJ
  srv "$1"
  EJ="$(navig ecran "{\"P\":$SRV_PORT,\"Q\":$QP,\"amorce\":\"$AMORCE\"}")"; unsrv
}
LAB="$WORK/lab"; mklab "$LAB"; OUT="$LAB/.vibeflow/cockpit"

echo "=== T13 — programme plein écran témoin dans la page Q réelle (TERM-09 navigateur) ==="
run_plein "$OUT" "$ENG" true; J="$PJ"
assert_eq "T13.0 — témoin : le scénario n'a pas échoué (aucune erreur nommée)" "$(rj "$J" 'j.erreur||JSON.stringify(j.erreurs)')" "{}"
assert_eq "T13.6 — TEMOIN-PLEIN-ECRAN-DEBUT puis PRET dans la grille xterm (témoin : l'invite du shell a précédé)" "invite=$(rj "$J" 'j.invite') debut=$(rj "$J" 'j.debut') pret=$(rj "$J" 'j.pret')" "invite=true debut=true pret=true"
assert_eq "T13.7 — fenêtre agrandie : WINCH <lignes>x<colonnes> dans la grille, lignes = celles de la grille, différent de la taille de départ (TAILLE)" "$(rj "$J" '"winch_lignes_egal="+(!!j.winch&&j.winch.split("x")[0]===String(j.lignes))+" change="+(!!j.winch&&j.winch!==j.taille0)')" "winch_lignes_egal=true change=true"
assert_eq "T13.8 — Ctrl-C : SIGINT-RECU, et retour à l'écran normal (TEMOIN-PLEIN-ECRAN-DEBUT n'est plus à l'écran)" "$(rj "$J" '"sigint="+j.sigint+" debut_apres="+j.debutApres')" "sigint=true debut_apres=false"
assert_eq "T13.9 — touches : le récepteur a reçu EXACTEMENT Échap 1b, Tab 09, Ctrl+R 12, Ctrl+W 17, flèche haut 1b5b41 (ou 1b4f41), puis la sentinelle 7a ; Ctrl+Maj+Espace n'a envoyé aucun octet (pas de 00)" "$(hx "$WORK/rec.hex" re '^1b0912171b(5b|4f)417a$')/nul=$(hx "$WORK/rec.hex" has 00)" "oui/nul=non"

echo "=== T14 — séquences hostiles : rien n'est réinjecté, rien ne sort (TERM-10 ; P71-D-16) ==="
run_hostile "$OUT"; H="$HJ"; HEX="$WORK/hostile.hex"
assert_eq "T14.0 — témoin : le scénario n'a pas échoué (aucune erreur nommée)" "$(rj "$H" 'j.erreur||JSON.stringify(j.erreurs)')" "{}"
assert_eq "T14.1a — témoin : la réponse à DA1 (ESC[?…c) a été reçue par le programme (sans elle, l'absence du reste ne prouve rien)" "$(hx "$HEX" has 1b5b3f)/$(hx "$HEX" re '63$')" "oui/oui"
assert_eq "T14.1 — l'entrée réinjectée dans le PTY est la réponse à DA1 SEULE (1b5b3f…63) : ni 1b50 (DCS) ni 1b5d (OSC)" "$(hx "$HEX" re '^1b5b3f([0-9a-f]{2})+63$')/dcs=$(hx "$HEX" has 1b50)/osc=$(hx "$HEX" has 1b5d)" "oui/dcs=non/osc=non"
assert_eq "T14.5 — témoin de l'espion : un appel délibéré à navigator.clipboard.writeText est compté" "$(rj "$H" 'j.clipTemoin')" "1"
assert_eq "T14.2 — presse-papiers : 0 appel (navigator.clipboard.*, document.execCommand) après OSC 52 écriture et lecture" "$(rj "$H" 'j.avant.clip+"/"+j.avant.exec')" "0/0"
assert_eq "T14.3 — sans clic : 0 window.open, 0 confirm" "$(rj "$H" 'j.avant.open.length+"/"+j.avant.confirm')" "0/0"
assert_eq "T14.4 — clic sur la cellule LIEN : un seul window.open('https://exemple.test/', '_blank', 'noopener'), 0 confirm" "cellule=$(rj "$H" 'j.cellule') $(rj "$H" 'JSON.stringify(j.apres.open)') confirm=$(rj "$H" 'j.apres.confirm')" 'cellule=true [["https://exemple.test/","_blank","noopener"]] confirm=0'

echo "=== T15 — traits de boîte continus à toutes les densités (J3 de la critique 71, UI-SPEC F3) ==="
run_boite "$OUT" sain
assert_eq "T15.0 — témoin : aucun scénario n'a échoué, et chaque densité a livré une mesure (boîte trouvée, capture à l'échelle de la densité, des centaines de pixels balayés)" "$(for d in $DENS; do mesure_boite sain "$d" 'j.erreur||JSON.stringify(j.erreurs)'; done | tr '\n' ' ')$(for d in $DENS; do mesure_boite sain "$d" 'j.boite&&j.boite["'"$d"'"]?(Math.abs(j.boite["'"$d"'"].echelle-'"$d"')<0.01&&j.boite["'"$d"'"].pixels>150):"absente"'; done | tr '\n' ' ')" "{} {} {} {} {} true true true true true "
assert_eq "T15.2 — F-A1-1 : au PREMIER chargement de Q (Chrome neuf, police jamais servie, aucun rechargement), la cellule est mesurée en JetBrains Mono (lignes de >= 16,5 px de haut, et non 15 en police de secours), aux cinq densités ; et la police était prête (document.fonts.check) AU MOMENT où xterm a ouvert le terminal" "$(for d in $DENS; do mesure_boite sain "$d" '(j.froid>=16.5)+"/"+(j.ouverture&&j.ouverture.police)'; done | tr '\n' ' ')" "true/true true/true true/true true/true true/true "
assert_eq "T15.1 — le balayage de pixels le long des quatre bords de ╭──╮│╰──╯ ne trouve aucun trou aux densités 1, 1.25, 1.5, 2 et 2.2" "$(resume_boite sain)" "d1=0 d1.25=0 d1.5=0 d2=0 d2.2=0 "

echo "=== T16 — liens non http : rien ne s'ouvre (F7 de l'audit, partie xterm ; P71-D-16) ==="
run_liens "$OUT"; LK="$LJ"
assert_eq "T16.0 — témoin : le scénario n'a pas échoué" "$(rj "$LK" 'j.erreur||JSON.stringify(j.erreurs)')" "{}"
assert_eq "T16.1 — après un clic sur chacun des trois liens (https, javascript:, data:), un seul window.open : celui du lien https, en noopener (témoin : le lien https s'ouvre dans la même scène)" "$(rj "$LK" 'JSON.stringify(j.ouvertures)')" '[["https://ok.test/","_blank","noopener"]]'

echo "=== T21 — collage et dépôt de texte : rien n'atteint le shell sans « Coller » (F2 de l'audit, P71-D-26) ==="
run_collage "$OUT"; CL="$CJ"
assert_eq "T21.0 — témoin : le scénario n'a pas échoué (aucune erreur nommée)" "$(rj "$CL" 'j.erreur||JSON.stringify(j.erreurs)')" "{}"
assert_eq "T21.1 — un collage d'une seule ligne sans caractère de contrôle passe directement : pas de bandeau, le texte est envoyé" "$(rj "$CL" '"bandeau="+j.c.une.bandeau+" entre="+j.c.une.entre')" "bandeau=false entre=true"
assert_eq "T21.2 — un collage terminé par un retour à la ligne : bandeau Coller / Annuler, RIEN envoyé au shell, aucun marqueur créé, focus sur « Annuler », deux cibles de 24 px ou plus" "$(rj "$CL" '"bandeau="+j.c.multi.bandeau+" entre=["+j.c.multi.entre+"] marqueur="+j.c.multi.marqueur+" focus="+j.c.multi.focus+" cibles="+j.c.multi.cibles.split(",").every(x=>Number(x)>=24)')" "bandeau=true entre=[] marqueur=false focus=Annuler cibles=true"
assert_eq "T21.3 — « Annuler » abandonne : bandeau retiré, rien envoyé, aucun marqueur" "$(rj "$CL" '"bandeau="+j.c.annuler.bandeau+" entre=["+j.c.annuler.entre+"] marqueur="+j.c.annuler.marqueur')" "bandeau=false entre=[] marqueur=false"
assert_eq "T21.4 — Échap abandonne : bandeau présent avant, retiré après, rien envoyé, aucun marqueur" "$(rj "$CL" '"avant="+j.c.echap.avant+" bandeau="+j.c.echap.bandeau+" entre=["+j.c.echap.entre+"] marqueur="+j.c.echap.marqueur')" "avant=true bandeau=false entre=[] marqueur=false"
assert_eq "T21.5 — un nouveau collage remplace le précédent : un seul bandeau, et « Coller » n'envoie que le dernier (B créé, A jamais)" "$(rj "$CL" '"bandeaux="+j.c.remplace.bandeaux+" A="+j.c.remplace.A+" B="+j.c.remplace.B')" "bandeaux=1 A=false B=true"
assert_eq "T21.6 — un collage d'une ligne pendant un bandeau abandonne l'ancien texte puis passe : bandeau retiré, ligne envoyée, aucun marqueur de l'ancien" "$(rj "$CL" '"bandeau="+j.c.abandonne.bandeau+" entre="+j.c.abandonne.entre+" marqueur="+j.c.abandonne.marqueur')" "bandeau=false entre=true marqueur=false"
assert_eq "T21.7 — un caractère de contrôle (ESC) sans retour à la ligne demande aussi confirmation" "$(rj "$CL" '"bandeau="+j.c.controle.bandeau+" texte="+j.c.controle.texte')" "bandeau=true texte=Le texte contient un caractère de contrôle."
assert_eq "T21.8 — le texte collé n'est jamais du HTML : aucune balise ni script dans le bandeau, aucune charge exécutée, la balise est lisible en texte" "$(rj "$CL" '"img="+j.c.html.img+" intacte="+j.c.html.pwn+" litteral="+j.c.html.litteral')" "img=0 intacte=true litteral=true"
assert_eq "T21.9 — dépôt de texte dans la zone de saisie : l'évènement drop et le beforeinput insertFromDrop sont annulés (le navigateur n'insère rien), chacun ouvre le bandeau, rien n'est envoyé ni créé" "$(rj "$CL" '"drop_annule="+(j.c.depot.drop===false)+" bandeau="+j.c.depot.bandeau+" beforeinput_annule="+(j.c.depot.avant===false)+" bandeau2="+j.c.depot.bandeau2+" entre="+j.c.depot.entre+" marqueur="+j.c.depot.marqueur')" "drop_annule=true bandeau=true beforeinput_annule=true bandeau2=true entre=false marqueur=false"
assert_eq "T21.11 — C12 : une charge placée après le 275e caractère est dans le DOM de l'aperçu AVANT le clic (aperçu défilant, atteignable au clavier), rien n'est exécuté avant" "$(rj "$CL" '"visible="+j.c.c12.visible+" marqueur="+j.c.c12.marqueur+" zone="+j.c.c12.zone')" "visible=true marqueur=false zone=true"
assert_eq "T21.12 — le décompte de lignes et de caractères est présent et juste (ab/cd/ef : 3 lignes, 8 caractères)" "$(rj "$CL" 'j.c.compte')" "3 lignes · 8 caractères"
assert_eq "T21.13 — U+202E et U+200B apparaissent en marqueur visible dans l'aperçu (jamais bruts), et le texte envoyé est identique octet pour octet à l'original (sha256)" "$(rj "$CL" '"u202e="+j.c.invis.u202e+" u200b="+j.c.invis.u200b+" brut="+j.c.invis.brut+" sha="+j.c.invis.sha')" "u202e=true u200b=true brut=true sha=true"
assert_eq "T21.14 — un texte de 30 001 caractères : la borne est dite (10 001 caractères non affichés), « Tout afficher » montre tout" "$(rj "$CL" '"note="+j.c.long.note+" avant="+j.c.long.avant+" apres>=30000="+(j.c.long.apres>=30000)+" reste="+j.c.long.reste')" "note=10001 caractères non affichés. avant=20000 apres>=30000=true reste=false"
assert_eq "T21.16 — N9 : une seule ligne portant U+202E, U+200B ou un caractère Tag ouvre le bandeau, rien n'est envoyé ni créé avant « Coller » ; témoin positif : après « Coller » puis Entrée le marqueur existe (la sonde sait voir l'exécution)" "$(rj "$CL" '["bidi","zwsp","tag"].map(k=>k+":"+j.c.n9[k].bandeau+"/"+j.c.n9[k].marqueur+"/["+j.c.n9[k].entre+"]/"+j.c.n9[k].apres).join(" ")')" "bidi:true/false/[]/true zwsp:true/false/[]/true tag:true/false/[]/true"
assert_eq "T21.17 — N9 : une ligne ordinaire accentuée passe sans bandeau et part au shell" "$(rj "$CL" '"bandeau="+j.c.n9.ordinaire.bandeau+" entre="+j.c.n9.ordinaire.entre')" "bandeau=false entre=true"
assert_eq "T21.18 — N10 : 60 lignes vides puis une commande : l'aperçu replie la suite en ⟨60 lignes vides⟩, la commande est visible SANS défilement ni avertissement, le focus reste sur « Annuler », rien n'est créé avant « Coller », et le texte envoyé est identique à l'original (sha256) et s'exécute" "$(rj "$CL" '"replie="+j.c.n10.replie+" charge="+j.c.n10.charge+" debord="+j.c.n10.debord+" avert="+j.c.n10.avert+" focus="+j.c.n10.focus+" sans="+j.c.n10.sans+" apres="+j.c.n10.apres+" sha="+j.c.n10.sha')" "replie=true charge=true debord=false avert=false focus=Annuler sans=false apres=true sha=true"
assert_eq "T21.19 — N10 : quand l'aperçu dépasse sa zone, l'avertissement explicite est affiché (le focus reste sur « Annuler »)" "$(rj "$CL" '"debord="+j.c.n10d.debord+" texte="+j.c.n10d.texte+" focus="+j.c.n10d.focus')" "debord=true texte=Le texte dépasse la zone : faites défiler avant de coller. focus=Annuler"
assert_eq "T21.15 — le HTML collé ne crée aucun nœud dans l'aperçu" "$(rj "$CL" 'j.c.html.enfants')" "0"
assert_eq "T21.10 — témoin positif : « Coller » envoie le texte (avec son retour chariot) et le shell l'exécute : le marqueur n'existait pas avant le clic, il existe après (la sonde sait voir l'exécution)" "$(rj "$CL" '"avant="+j.c.avantColler+" marqueur="+j.c.coller.marqueur+" bandeau="+j.c.coller.bandeau+" envoye="+j.c.coller.entree_ok')" "avant=false marqueur=true bandeau=false envoye=true"

echo "=== T22 — hauteur utile de la grille et barre de défilement discrète (E3, G3 ; P71-D-34, D-35) ==="
E3_EXPR='[160,208,280,328,570].map(h=>{const m=(j.e3||{})[h];return m?h+":"+(m.bas<=m.visible+0.01?"ok":"deborde de "+(m.bas-m.visible))+"/lignes>0="+(m.lignes>0):h+":absente"}).join(" ")'
E3_OK="160:ok/lignes>0=true 208:ok/lignes>0=true 280:ok/lignes>0=true 328:ok/lignes>0=true 570:ok/lignes>0=true"
run_ecran "$OUT"; EC="$EJ"
assert_eq "T22.0 — témoin : le scénario n'a pas échoué (aucune erreur nommée), la barre a été mesurée" "$(rj "$EC" 'j.erreur||JSON.stringify(j.erreurs)')/$(rj "$EC" '(j.g3&&j.g3.survol)||"absente"')" "{}/1"
assert_eq "E3.1 — aux hauteurs de tiroir 160, 208, 280, 328 et 570 px, le bas de la dernière ligne ne dépasse jamais la hauteur visible du cadre" "$(rj "$EC" "$E3_EXPR")" "$E3_OK"
assert_eq "E3.2 — la hauteur utile (marge haute de 8 px déduite) donne plus d'une ligne et la grille tient dans le cadre : 570 px donne au moins 20 lignes" "$(rj "$EC" '((j.e3||{})[570]||{}).lignes>=20')" "true"
assert_eq "G3.1 — la barre de défilement n'apparaît pas hors survol (opacité 0, pointeur hors du cadre, 300 lignes dans l'historique)" "$(rj "$EC" 'j.g3.dehors')" "0"
assert_eq "G3.2 — elle apparaît au survol du terminal (opacité 1)" "$(rj "$EC" 'j.g3.survol')" "1"
assert_eq "G3.3 — le défilement à la molette reste possible barre masquée ou non (la dernière ligne imprimée était à l'écran, la molette la fait sortir)" "$(rj "$EC" 'j.g3.fin0+"/"+j.g3.fin1')" "true/false"
assert_eq "G3.4 — le pointeur parti, la barre se retire (opacité 0 après la molette)" "$(rj "$EC" 'j.g3.apres')" "0"
assert_eq "G3.5 — au clavier (Maj+PageUp) hors survol, la barre se montre pendant le défilement (opacité 1) puis se retire (0)" "$(rj "$EC" 'j.g3.clavier+"/"+j.g3.repos')" "1/0"

assert_eq "R2.1 — tout l'espace du cadre suit le fond du thème, sombre et clair, aux hauteurs 160, 208, 280, 328 et 570 px : le fond de la zone de défilement de xterm est celui du terminal (jamais le noir de xterm.css), et aucun pixel de la colonne mesurée n'a une autre couleur" "$(rj "$EC" '["dark","light"].map(t=>[160,208,280,328,570].map(h=>{const m=((j.fond||{})[t]||{})[h];return m?(m.viewport===m.terminal&&m.terminal===m.attendu&&m.hors===0?"ok":"KO "+t+h+" "+m.viewport+"/"+m.terminal+"/hors="+m.hors):"absente"}).join(" ")).join(" ")')" "ok ok ok ok ok ok ok ok ok ok"
assert_eq "R2.2 — le pixel le plus bas du cadre a la couleur du thème (clair : blanc, sombre : #191919), à chaque hauteur" "$(rj "$EC" '["dark","light"].map(t=>[160,208,280,328,570].map(h=>{const m=((j.fond||{})[t]||{})[h];return m&&Math.abs(m.bas-(t==="light"?255:25))<=6?"ok":"KO"}).join(" ")).join(" ")')" "ok ok ok ok ok ok ok ok ok ok"
assert_eq "G5.1 — le curseur de la barre est nettement visible au survol : contraste >= 2 contre le fond du terminal, sombre et clair (l'ancien 10 % donnait environ 1,3)" "$(rj "$EC" '["sombre","clair"].map(t=>{const m=(j.g5||{})[t];return m&&m.contraste>=2?"ok":"KO "+(m?m.contraste:"absent")}).join(" ")')" "ok ok"

echo "=== T23 — rejeu du tampon : xterm ne répond à aucune question restée dans le tampon (R1 ; P71-D-36) ==="
run_rejeu "$OUT"; RJ0="$RJ"
assert_eq "R1.0 — témoin : aucune erreur nommée, le récepteur a relevé les réponses VIVES aux questions (DA1 ESC[?…c reçue), le premier silence est marqué, cinq rechargements du cadre faits" "$(rj "$RJ0" 'j.erreur||JSON.stringify(j.erreurs)')/marqueur=$(rj "$RJ0" 'j.rejeu.marqueur')/da1=$(rj "$RJ0" '/1b5b3f/.test(j.rejeu.initial)')/recharges=$(rj "$RJ0" 'j.rejeu.recharges')" "{}/marqueur=true/da1=true/recharges=5"
assert_eq "R1.1 — après cinq rechargements du cadre (thèmes alternés), le tampon contenant ESC[c ESC[>c ESC[6n ESC[?2004\$p ESC[5n est rejoué : le PTY ne reçoit AUCUN octet de réponse" "[$(rjs "$RJ0" 'j.rejeu.avant')]" "[]"
assert_eq "R1.2 — témoin positif : une question émise APRÈS le rejeu reçoit sa réponse (frappe puis ESC[?…c) : les réponses ne sont pas coupées en général" "frappe=$(rj "$RJ0" 'j.rejeu.frappe') da1=$(rj "$RJ0" '/1b5b3f/.test(j.rejeu.apres)')" "frappe=true da1=true"
assert_eq "R1.3t — témoin de la fenêtre : la frappe tombe dans la page APRÈS l'écriture du rejeu dans xterm et AVANT son analyse (moment=avant)" "$(rjs "$RJ0" 'j.rejeu.ralenti')" "cle=true libere=true moment=avant"
assert_eq "R1.3 — une frappe tombée entre l'arrivée et l'analyse d'un gros rejeu (60000 questions) arrive au shell et AUCUNE réponse d'xterm : le PTY reçoit exactement 6b (l'autorisation humaine ne survit pas à son événement)" "[$(rjs "$RJ0" 'j.rejeu.gros')]" "[6b]"
assert_eq "R1.4 — une frappe réelle (CDP, événement de confiance) après le rejeu arrive au shell, seule : 6b" "[$(rjs "$RJ0" 'j.rejeu.reelle')]" "[6b]"

echo "=== M-* — mutants : chaque protection rougit sa sonde ==="
if mutant_eng ctrlc 's/^                vers_shell += donnees$/                vers_shell += donnees.replace(b"\\x03", b"")/'; then
  VF_XTERM_MS=6000 run_plein "$OUT" "$MUT_ENG" false
  assert_eq "M-CTRLC — le mutant retire 0x03 de l'entrée : SIGINT-RECU n'arrive jamais, T13.8 rouge" "$(rouge "sigint=$(rj "$PJ" 'j.sigint') debut_apres=$(rj "$PJ" 'j.debutApres')" "sigint=true debut_apres=false")" "rouge"
else sans_effet "M-CTRLC"; fi
if mutant dcs vf-cockpit-terminal-client.mjs "s|term.parser.registerDcsHandler({ intermediates: '\$', final: 'q' }, () => true);||"; then
  run_hostile "$MUT_OUT"
  assert_eq "M-DCS — gestionnaire DECRQSS non enregistré : xterm répond ESC P (1b50) dans l'entrée du PTY, T14.1 rouge (mesure de A2 : le gestionnaire du client est ce qui l'empêche)" "$(rouge "dcs=$(hx "$WORK/hostile.hex" has 1b50)" "dcs=non")" "rouge"
else sans_effet "M-DCS"; fi
if mutant winopt vf-cockpit-terminal-client.mjs 's|windowOptions: {}|windowOptions: { getWinTitle: true, getWinSizeChars: true, getWinSizePixels: true, getCellSizePixels: true }|'; then
  run_hostile "$MUT_OUT"
  assert_eq "M-WINOPT — windowOptions ouvertes (getWinTitle, getWinSizeChars…) : CSI 18t reçoit la réponse ESC [ 8 ; (1b5b383b) dans l'entrée du PTY, T14.1 rouge (le xterm.js livré ne répond pas à 21t même ouvert : 18t est la sonde qui discrimine)" "$(rouge "taille=$(hx "$WORK/hostile.hex" has 1b5b383b)" "taille=non")" "rouge"
else sans_effet "M-WINOPT"; fi
if mutant clip vf-cockpit-terminal-client.mjs "s|const fit = new FitAddon.FitAddon();|const fit = new FitAddon.FitAddon(); term.parser.registerOscHandler(52, (d) => { navigator.clipboard.writeText(d); return true; });|"; then
  run_hostile "$MUT_OUT"
  assert_eq "M-CLIP — un gestionnaire OSC 52 écrit dans navigator.clipboard : 1 appel compté, T14.2 rouge" "$(rouge "clip=$(rj "$HJ" 'j.avant.clip')" "clip=0")" "rouge"
else sans_effet "M-CLIP"; fi
if mutant lien vf-cockpit-terminal-client.mjs 's|^ *linkHandler: .*$||'; then
  run_hostile "$MUT_OUT"
  assert_eq "M-LIEN — linkHandler retiré (comportement natif de xterm) : le clic appelle confirm, T14.4 rouge" "$(rouge "confirm=$(rj "$HJ" 'j.apres&&j.apres.confirm')" "confirm=0")" "rouge"
else sans_effet "M-LIEN"; fi

if mutant boite vf-cockpit-terminal-page.mjs "s|const PLAGE_BOITE = 'U+2500-259F';|const PLAGE_BOITE = 'U+E000';|"; then
  run_boite "$MUT_OUT" mutant
  assert_eq "M-BOITE — police des traits de boîte retirée de la page (plage sans caractère) : des trous apparaissent (T15.1 rouge) ; le mutant est mesuré aux cinq densités" "$(rouge "$(resume_boite mutant)" "d1=0 d1.25=0 d1.5=0 d2=0 d2.2=0 ")" "rouge"
else sans_effet "M-BOITE"; fi
if mutant proto vf-cockpit-terminal-client.mjs 's|allowNonHttpProtocols: false|allowNonHttpProtocols: true|'; then
  run_liens "$MUT_OUT"
  assert_eq "M-PROTO — allowNonHttpProtocols ouvert : les liens javascript: et data: s'ouvrent au clic, T16.1 rouge" "$(rouge "$(rj "$LJ" 'j.ouvertures.length')" "1")" "rouge"
else sans_effet "M-PROTO"; fi

if mutant collage-sans-bandeau vf-cockpit-terminal-client.mjs 's|if (!SUR.test(t) && !vue.invisible(t)) { term.paste(t); return; }|term.paste(t); return;|'; then
  run_collage "$MUT_OUT"
  assert_eq "M-COLLAGE-BANDEAU — le collage multi-lignes est envoyé sans confirmation : le shell reçoit le texte et crée le marqueur, T21.2 rouge" "$(rouge "entre=[$(rj "$CJ" 'j.c.multi.entre')] marqueur=$(rj "$CJ" 'j.c.multi.marqueur')" "entre=[] marqueur=false")" "rouge"
else sans_effet "M-COLLAGE-BANDEAU"; fi
if mutant collage-ecoute vf-cockpit-terminal-client.mjs "s|^ *zone.addEventListener('paste'.*\$||"; then
  run_collage "$MUT_OUT"
  assert_eq "M-COLLAGE-ECOUTE — l'écoute du collage retirée (collage natif d'xterm) : le texte part sans bandeau, T21.2 rouge" "$(rouge "bandeau=$(rj "$CJ" 'j.c.multi.bandeau') entre=[$(rj "$CJ" 'j.c.multi.entre')]" "bandeau=true entre=[]")" "rouge"
else sans_effet "M-COLLAGE-ECOUTE"; fi
if mutant depot vf-cockpit-terminal-client.mjs "/addEventListener('drop'/d; /addEventListener('beforeinput'/,/^ *}, true);/d"; then
  run_collage "$MUT_OUT"
  assert_eq "M-DEPOT — écoutes de dépôt retirées : drop et beforeinput ne sont plus annulés (le navigateur insérerait le texte dans la zone de saisie), T21.9 rouge" "$(rouge "drop_annule=$(rj "$CJ" 'j.c.depot.drop===false') beforeinput_annule=$(rj "$CJ" 'j.c.depot.avant===false')" "drop_annule=true beforeinput_annule=true")" "rouge"
else sans_effet "M-DEPOT"; fi
if mutant abandon-envoie vf-cockpit-terminal-client.mjs 's|const abandonner = () => { if (propose !== null) { propose = null;|const abandonner = () => { if (propose !== null) { term.paste(propose); propose = null;|'; then
  run_collage "$MUT_OUT"
  assert_eq "M-ABANDON-ENVOIE — abandonner() envoie l'ancien texte au lieu de l'oublier : « touch l1 » part au shell quand une ligne remplace le bandeau, T21.6 rouge (la fenêtre d'absence de 600 ms laisse le marqueur apparaître)" "$(rouge "marqueur=$(rj "$CJ" 'j.c.abandonne.marqueur')" "marqueur=false")" "rouge"
else sans_effet "M-ABANDON-ENVOIE"; fi

if mutant n9-sans-cf vf-cockpit-terminal-vue.mjs 's|const INVISIBLE = /\[\\p{Cc}\\p{Cf}\\p{Cs}\\u{E0000}-\\u{E007F}\]/u;|const INVISIBLE = /[\\p{Cc}\\p{Cs}]/u;|'; then
  run_collage "$MUT_OUT"
  assert_eq "M-N9-SANS-CF — le déclencheur et le marquage perdent la classe Cf et les Tag : une ligne à U+202E passe sans bandeau et crée le marqueur, T21.16 rouge" "$(rouge "bidi=$(rj "$CJ" 'j.c.n9.bidi.bandeau')/$(rj "$CJ" 'j.c.n9.bidi.marqueur')" "bidi=true/false")" "rouge"
else sans_effet "M-N9-SANS-CF"; fi
if mutant n10-sans-repli vf-cockpit-terminal-vue.mjs 's|if (e - k >= 3) {|if (e - k >= 3 \&\& false) {|'; then
  run_collage "$MUT_OUT"
  assert_eq "M-N10-SANS-REPLI — les lignes vides ne sont plus repliées : la commande est hors de la zone, T21.18 rouge" "$(rouge "replie=$(rj "$CJ" 'j.c.n10.replie') charge=$(rj "$CJ" 'j.c.n10.charge') debord=$(rj "$CJ" 'j.c.n10.debord')" "replie=true charge=true debord=false")" "rouge"
else sans_effet "M-N10-SANS-REPLI"; fi
if mutant n10-sans-avertissement vf-cockpit-terminal-vue.mjs 's|const depasse = () => {|const depasse = () => { return;|'; then
  run_collage "$MUT_OUT"
  assert_eq "M-N10-SANS-AVERTISSEMENT — le dépassement n'est plus dit : T21.19 rouge" "$(rouge "texte=$(rj "$CJ" 'j.c.n10d.texte')" "texte=Le texte dépasse la zone : faites défiler avant de coller.")" "rouge"
else sans_effet "M-N10-SANS-AVERTISSEMENT"; fi

if mutant apercu-coupe vf-cockpit-terminal-vue.mjs 's|const LIMITE = 20000|const LIMITE = 200|'; then
  run_collage "$MUT_OUT"
  assert_eq "M-APERCU-COUPE — retour de la coupure à 200 caractères : la charge après 275 caractères n'est plus dans le DOM, T21.11 rouge" "$(rouge "visible=$(rj "$CJ" 'j.c.c12.visible')" "visible=true")" "rouge"
else sans_effet "M-APERCU-COUPE"; fi
if mutant neutralisation vf-cockpit-terminal-vue.mjs "s|const neutre = (t) => .*\$|const neutre = (t) => t;|"; then
  run_collage "$MUT_OUT"
  assert_eq "M-NEUTRALISATION — l'aperçu affiche le texte brut : U+202E et U+200B ne sont plus des marqueurs, T21.13 rouge" "$(rouge "u202e=$(rj "$CJ" 'j.c.invis.u202e') brut=$(rj "$CJ" 'j.c.invis.brut')" "u202e=true brut=true")" "rouge"
else sans_effet "M-NEUTRALISATION"; fi
if mutant envoi-neutralise vf-cockpit-terminal-client.mjs 's|if (x !== null) term.paste(x);|if (x !== null) term.paste(x.replace(/[\\u202e\\u200b]/g, ""));|'; then
  run_collage "$MUT_OUT"
  assert_eq "M-ENVOI-NEUTRALISE — « Coller » envoie le texte privé de ses invisibles au lieu de l'original : le sha256 diffère, T21.13 rouge" "$(rouge "sha=$(rj "$CJ" 'j.c.invis.sha')" "sha=true")" "rouge"
else sans_effet "M-ENVOI-NEUTRALISE"; fi
if mutant sans-marge vf-cockpit-terminal-client.mjs 's|z.clientHeight - parseFloat(cs.paddingTop) - parseFloat(cs.paddingBottom)|z.clientHeight|'; then
  run_ecran "$MUT_OUT"
  assert_eq "M-SANS-MARGE — la hauteur utile ne déduit plus les marges (le code d'avant) : la dernière ligne déborde du cadre, E3.1 rouge" "$(rouge "$(rj "$EJ" "$E3_EXPR")" "$E3_OK")" "rouge"
else sans_effet "M-SANS-MARGE"; fi
if mutant barre-visible vf-cockpit-terminal-style.mjs 's|^#terminal .xterm-scrollable-element > .scrollbar { opacity: 0;.*$||'; then
  run_ecran "$MUT_OUT"
  assert_eq "M-BARRE-VISIBLE — la règle qui masque la barre est retirée : elle reste visible hors survol, G3.1 rouge" "$(rouge "$(rj "$EJ" 'j.g3.dehors')" "0")" "rouge"
else sans_effet "M-BARRE-VISIBLE"; fi
if mutant barre-jamais vf-cockpit-terminal-style.mjs 's|^#terminal:hover .xterm-scrollable-element.*$||'; then
  run_ecran "$MUT_OUT"
  assert_eq "M-BARRE-JAMAIS — la règle qui la montre au survol est retirée : la barre ne se montre jamais, G3.2 rouge" "$(rouge "$(rj "$EJ" 'j.g3.survol')" "1")" "rouge"
else sans_effet "M-BARRE-JAMAIS"; fi
if mutant barre-clavier vf-cockpit-terminal-client.mjs "s|montrerBarre();|void 0;|g"; then
  run_ecran "$MUT_OUT"
  assert_eq "M-BARRE-CLAVIER — la barre n'est plus montrée pendant le défilement : G3.5 rouge" "$(rouge "$(rj "$EJ" 'j.g3.clavier')" "1")" "rouge"
else sans_effet "M-BARRE-CLAVIER"; fi
if mutant rejeu-sans-garde vf-cockpit-terminal-client.mjs 's|if (rejeu \&\& !humain) return;||'; then
  run_rejeu "$MUT_OUT"
  assert_eq "M-REJEU-SANS-GARDE — la garde du rejeu est retirée (le code d'avant) : les réponses du tampon partent dans l'entrée du PTY, R1.1 rouge" "$(rougelu "[$(rjs "$RJ" 'j.rejeu.avant')]" "[]")" "rouge"
else sans_effet "M-REJEU-SANS-GARDE"; fi
if mutant rejeu-humain-colle vf-cockpit-terminal-client.mjs 's|if (e.target \&\& e.target.addEventListener) e.target.addEventListener(t, () => { humain = false; }, { once: true });|void 0;|'; then
  run_rejeu "$MUT_OUT"
  assert_eq "M-REJEU-HUMAIN-COLLE — l'autorisation humaine ne se referme plus avec son événement, seul reste le minuteur (le code d'avant) : des réponses d'xterm partent pendant le rejeu, R1.3 rouge" "$(rougelu "[$(rjs "$RJ" 'j.rejeu.gros')]" "[6b]")" "rouge"
else sans_effet "M-REJEU-HUMAIN-COLLE"; fi
if mutant rejeu-jamais-clos vf-cockpit-terminal-client.mjs "s|term.write('', () => { rejeu = false; });|void 0;|"; then
  run_rejeu "$MUT_OUT"
  assert_eq "M-REJEU-JAMAIS-CLOS — le rejeu ne se clôt jamais : la question neuve ne reçoit plus sa réponse, R1.2 rouge (la garde ne coupe pas les réponses en général)" "$(rougelu "da1=$(rjs "$RJ" '/1b5b3f/.test(j.rejeu.apres)')" "da1=true")" "rouge"
else sans_effet "M-REJEU-JAMAIS-CLOS"; fi
if mutant fond-noir vf-cockpit-terminal-style.mjs 's|^#terminal .xterm .xterm-viewport.*$||'; then
  run_ecran "$MUT_OUT"
  assert_eq "M-FOND-NOIR — la règle du fond de la zone de défilement est retirée (le code d'avant) : bande noire, R2.1 rouge" "$(rouge "$(rj "$EJ" '["dark","light"].map(t=>[160,208,280,328,570].map(h=>{const m=((j.fond||{})[t]||{})[h];return m&&m.viewport===m.terminal&&m.hors===0?"ok":"KO"}).join(" ")).join(" ")')" "ok ok ok ok ok ok ok ok ok ok")" "rouge"
else sans_effet "M-FOND-NOIR"; fi
if mutant curseur-pale vf-cockpit-terminal-vue.mjs 's|rgba(${ink}, .4)|rgba(${ink}, .1)|'; then
  run_ecran "$MUT_OUT"
  assert_eq "M-CURSEUR-PALE — le curseur retrouve ses 10 % : contraste insuffisant, G5.1 rouge" "$(rouge "$(rj "$EJ" '["sombre","clair"].map(t=>{const m=(j.g5||{})[t];return m&&m.contraste>=2?"ok":"KO"}).join(" ")')" "ok ok")" "rouge"
else sans_effet "M-CURSEUR-PALE"; fi
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
