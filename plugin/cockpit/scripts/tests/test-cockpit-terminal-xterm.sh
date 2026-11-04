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
#   M-*  mutants (copies de la sortie ou du moteur, « mutant sans effet » = FAIL) : M-CTRLC (T13.8), M-DCS et M-WINOPT (T14.1, mesure de A2),
#        M-CLIP (T14.2), M-LIEN (T14.3/T14.4), M-BOITE (T15.1 : police des traits de boîte retirée de la page), M-PROTO (T16 : allowNonHttpProtocols ouvert)
# Chrome requis pour toutes les sections : sans lui la suite annonce « SUITE SAUTÉE (navigateur) », ne compte rien et sort 1 (anti-vert-à-vide).
# Limite assumée : Chrome headless Linux n'a pas de pointeur fin (pointer: none) et son presse-papiers n'est pas observable depuis la page ; on
# mesure donc les APPELS à navigator.clipboard.* et document.execCommand par espions posés avant la page, jamais le contenu du presse-papiers du poste.
# Variables : VF_XTERM_MS (échéance d'une attente navigateur, 20000 par défaut). Exit 0 si tout passe, 1 sinon.
set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; } # port libre choisi à l'exécution
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
ENG="$(cd "$SCRIPTS/../skills/cockpit-moteur" && pwd -P)"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude/scripts" "$WORK/bin" "$WORK/run" "$WORK/temoins"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
export CHROME_SESSION="$HERE_T/chrome-session.mjs"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0
court() { if [ "${#1}" -gt 300 ]; then printf '%s […] %s' "${1:0:140}" "${1: -140}"; else printf '%s' "$1"; fi; }
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$(court "$3")]"; echo "     obtenu:  [$(court "$2")]"; FAIL=$((FAIL+1)); fi; }
cp "$HERE_T/temoins/plein-ecran.py" "$WORK/temoins/plein-ecran.py"; cp "$HERE_T/temoins/hostile.py" "$WORK/temoins/hostile.py"

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
const { executer, pause } = await import(pathToFileURL(process.env.CHROME_SESSION).href);
const [, , chrome, mode, brut] = process.argv;
const { P, Q, amorce, plein, hostile, sortieHex, recepteurHex, avecRecepteur, densite, dossier } = JSON.parse(brut);
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
let ctx = 0;
const monde = async (sp, etendue = 600) => {
  let trouve = 0;
  for (let id = 1; id < etendue; id++) {
    const v = await sp.send('Runtime.evaluate', { contextId: id, expression: `location.origin === ${JSON.stringify(OQ)} && typeof window.vfTermVue === 'object'`, returnByValue: true }).then((x) => x && x.result && x.result.value, () => false);
    if (v === true) trouve = id;
  }
  return trouve;
};

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
    await sp.naviguer(`${OP}/project.html`); await sp.attendre(`document.readyState === 'complete'`, 'page P', MS);
    await sp.ev(`(() => { document.querySelectorAll('iframe[data-t]').forEach((f) => f.remove()); const f = document.createElement('iframe'); f.dataset.t = '1'; f.setAttribute('sandbox', ${JSON.stringify(SBX)});
      f.style.cssText = 'position:fixed;left:0;top:0;width:100vw;height:100vh;border:0;z-index:99999'; f.src = '${OQ}/?theme=dark'; document.body.appendChild(f); })()`);
    const fin = Date.now() + MS;
    let essais = 0;
    while (!ctx) { ctx = await monde(sp, 600 * 5 ** Math.min(essais++, 3)); if (!ctx) { if (Date.now() > fin) throw new Error('contexte du cadre de Q introuvable'); await pause(150); } }
    await attCadre(`!!document.querySelector('.xterm-helper-textarea') || !!document.querySelector('#etat:not([hidden])')`, 'terminal ou carte dans le cadre');
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
    await sp.naviguer(`${OQ}/#t=${amorce}`);
    await sp.attendre(`location.port === '${P}' && location.pathname === '/project.html' && document.readyState === 'complete'`, 'arrivée sur P', MS);
  });
  await essai('invite', async () => { await s.naviguer(); await att(`${TXT}.includes('VFP>')`, 'invite du shell'); r.invite = true; });
  if (!r.invite) return r;

  if (mode === 'collage') { // F2 (P71-D-26) : un texte à retour à la ligne ou à caractère de contrôle n'atteint le shell qu'après « Coller »
    const M = (n) => `${dossier}/${n}`, ent = () => s.ev(`window.__ent.join('')`), bandeau = () => s.ev(`!!document.getElementById('collage')`);
    const nb = () => s.ev(`document.querySelectorAll('#collage').length`);
    const coller = (t) => s.ev(`(() => { const dt = new DataTransfer(); dt.setData('text/plain', ${JSON.stringify(t)}); const ta = document.querySelector('.xterm-helper-textarea');
      ta.dispatchEvent(new ClipboardEvent('paste', { clipboardData: dt, bubbles: true, cancelable: true })); return true; })()`);
    const bouton = (nom) => s.ev(`[...document.querySelectorAll('#collage button')].find((b) => b.textContent === ${JSON.stringify(nom)}).click()`);
    const existe = async (n) => (await import('node:fs')).existsSync(M(n));
    await s.ev(`(() => { window.__ent = []; const f0 = window.fetch; window.fetch = function (u, o) { if (String(u) === '/entree' && o && o.body) window.__ent.push(new TextDecoder().decode(o.body)); return f0.apply(this, arguments); }; })()`);
    // une ligne collée sans Entrée reste dans la ligne de commande du shell : Ctrl+U la vide avant chaque cas qui crée un marqueur
    const vide = async () => { await touche({ key: 'u', code: 'KeyU', windowsVirtualKeyCode: 85, modifiers: 2 }); await pause(300); await s.ev(`window.__ent.length = 0`); };
    r.c = {};
    await essai('une-ligne', async () => { await coller('echo UNE""LIGNE'); await pause(400); r.c.une = { bandeau: await bandeau(), entre: (await ent()).includes('echo UNE""LIGNE') }; });
    await essai('multi', async () => {
      await vide(); await coller(`touch ${M('m1')}\n`); await pause(1200);
      r.c.multi = { bandeau: await bandeau(), entre: await ent(), marqueur: await existe('m1'), focus: await s.ev(`document.activeElement.textContent`),
        cibles: await s.ev(`[...document.querySelectorAll('#collage button')].map((b) => Math.round(b.getBoundingClientRect().height)).join(',')`) };
    });
    await essai('annuler', async () => { await bouton('Annuler'); await pause(1200); r.c.annuler = { bandeau: await bandeau(), entre: await ent(), marqueur: await existe('m1') }; });
    await essai('echap', async () => {
      await coller(`touch ${M('m2')}\n`); await pause(300); const avant = await bandeau();
      await touche({ key: 'Escape', code: 'Escape', windowsVirtualKeyCode: 27 }); await pause(1200);
      r.c.echap = { avant, bandeau: await bandeau(), entre: await ent(), marqueur: await existe('m2') };
    });
    await essai('remplace', async () => {
      await vide(); await coller(`touch ${M('rA')}\n`); await coller(`touch ${M('rB')}\n`); await pause(300); const n = await nb();
      await bouton('Coller'); await pause(2000);
      r.c.remplace = { bandeaux: n, A: await existe('rA'), B: await existe('rB') };
    });
    await essai('ligne-abandonne', async () => {
      await coller(`touch ${M('l1')}\n`); await pause(200); await coller('echo SUITE""OK'); await pause(500);
      r.c.abandonne = { bandeau: await bandeau(), entre: (await ent()).includes('echo SUITE""OK'), marqueur: await existe('l1') };
    });
    await essai('controle', async () => { await vide(); await coller('echo \u001b[31mx'); await pause(300); r.c.controle = { bandeau: await bandeau(), texte: await s.ev(`(document.querySelector('#collage .vf-q-texte') || {}).textContent`) }; await bouton('Annuler'); });
    await essai('html', async () => {
      await coller('<img src=x onerror=window.__pwn=1>\n'); await pause(500);
      r.c.html = { img: await s.ev(`document.querySelectorAll('#collage img, #collage script').length`), pwn: await s.ev(`window.__pwn === undefined`), litteral: await s.ev(`document.getElementById('collage').textContent.includes('<img src=x')` ), enfants: await s.ev(`document.getElementById('collage-apercu').children.length`) };
      await bouton('Annuler');
    });
    await essai('c12', async () => { // charge au-delà du 275e caractère : visible dans le DOM du bandeau AVANT le clic, rien d'exécuté avant le clic
      const charge = `touch ${M('c12')}`; await coller('a'.repeat(275) + '; ' + charge + '\n'); await pause(400);
      r.c.c12 = { visible: await s.ev(`document.getElementById('collage-apercu').textContent.includes(${JSON.stringify(charge)})`), marqueur: await existe('c12'),
        zone: await s.ev(`(() => { const z = document.getElementById('collage-apercu'); return z.tabIndex === 0 && getComputedStyle(z).overflowY === 'auto'; })()`) };
      await bouton('Annuler');
    });
    await essai('compte', async () => { await coller('ab\ncd\nef'); await pause(300); r.c.compte = await s.ev(`document.querySelector('#collage .vf-q-decompte').textContent`); await bouton('Annuler'); });
    await essai('invisibles', async () => { // U+202E et U+200B rendus visibles à l'affichage ; le texte envoyé reste octet pour octet l'original (sha256)
      await vide(); await s.ev(`window.__ent.length = 0`); const orig = 'echo a\u202eb\u200bc\n'; await coller(orig); await pause(300);
      const aff = await s.ev(`document.getElementById('collage-apercu').textContent`);
      await bouton('Coller'); await pause(800); const h = async (x) => (await import('node:crypto')).createHash('sha256').update(x, 'utf8').digest('hex');
      r.c.invis = { u202e: aff.includes('\u27e8U+202E\u27e9'), u200b: aff.includes('\u27e8U+200B\u27e9'), brut: !aff.includes('\u202e') && !aff.includes('\u200b'),
        sha: (await h(await ent())) === (await h(orig.replace(/\n/g, '\r'))) };
    });
    await essai('long', async () => { // borne d'affichage dite, et levée par « Tout afficher »
      await coller('z'.repeat(30000) + '\n'); await pause(600);
      const note = await s.ev(`(document.querySelector('#collage .vf-q-reste .vf-q-texte') || {}).textContent`); const avant = await s.ev(`document.getElementById('collage-apercu').textContent.length`);
      await bouton('Tout afficher'); const apres = await s.ev(`document.getElementById('collage-apercu').textContent.length`);
      r.c.long = { note, avant, apres, reste: await s.ev(`!!document.querySelector('#collage .vf-q-reste')`) }; await bouton('Annuler');
    });
    // N9 (P71-D-30) : UNE ligne portant un invisible ou un caractère de contrôle d'affichage demande confirmation ; « Coller » reste le seul chemin vers le shell
    const entree = () => touche({ key: 'Enter', code: 'Enter', windowsVirtualKeyCode: 13, text: '\r' });
    r.c.n9 = {};
    for (const [nom, car] of [['bidi', '\u202e'], ['zwsp', '\u200b'], ['tag', '\u{E0041}']]) {
      await essai(`n9-${nom}`, async () => {
        await vide(); const orig = `echo hello${car}; touch ${M('n9' + nom)}; `; await coller(orig); await pause(600);
        const sans = { bandeau: await bandeau(), marqueur: await existe('n9' + nom), entre: (await ent()) };
        await bouton('Coller'); await pause(600); await entree(); await pause(1500);
        r.c.n9[nom] = { ...sans, apres: await existe('n9' + nom) };
      });
    }
    await essai('n9-ordinaire', async () => { await vide(); await coller('echo café àî""OK'); await pause(500); r.c.n9.ordinaire = { bandeau: await bandeau(), entre: (await ent()).includes('café') }; });
    // N10 (P71-D-30) : ce qui est confirmé est visible sans défilement ; les suites de lignes vides sont repliées ; le dépassement est dit ; l'envoi reste l'original (sha256)
    await essai('n10', async () => {
      await vide(); const orig = '\n'.repeat(60) + `touch ${M('n10')}\n`; await coller(orig); await pause(600);
      const mesure = await s.ev(`(() => { const z = document.getElementById('collage-apercu'); return { txt: z.textContent, debord: z.scrollHeight > z.clientHeight + 1, avert: !!document.querySelector('#collage .vf-q-depasse'), focus: document.activeElement.textContent }; })()`);
      const sans = await existe('n10'); await bouton('Coller'); await pause(2500); const h = async (x) => (await import('node:crypto')).createHash('sha256').update(x, 'utf8').digest('hex');
      r.c.n10 = { replie: mesure.txt.includes('⟨' + 60 + ' lignes vides⟩'), charge: mesure.txt.includes(`touch ${M('n10')}`), debord: mesure.debord, avert: mesure.avert, focus: mesure.focus, longueur: mesure.txt.length,
        sans, apres: await existe('n10'), sha: (await h(await ent())) === (await h(orig.replace(/\n/g, '\r'))) };
    });
    await essai('n10-depasse', async () => {
      await vide(); await coller('ligne\n'.repeat(200)); await pause(600);
      r.c.n10d = await s.ev(`(() => { const z = document.getElementById('collage-apercu'); const w = document.querySelector('#collage .vf-q-depasse'); return { debord: z.scrollHeight > z.clientHeight + 1, texte: w ? w.textContent : '', focus: document.activeElement.textContent }; })()`);
      await bouton('Tout afficher').catch(() => {}); await bouton('Annuler');
    });
    await essai('depot', async () => {
      const lance = (code) => s.ev(`(() => { const ta = document.querySelector('.xterm-helper-textarea'); ${code} })()`);
      r.c.depot = { drop: await lance(`const dt = new DataTransfer(); dt.setData('text/plain', 'touch ${M('d1')}\\n'); return ta.dispatchEvent(new DragEvent('drop', { dataTransfer: dt, bubbles: true, cancelable: true }));`) };
      await pause(300); r.c.depot.bandeau = await bandeau(); if (r.c.depot.bandeau) await bouton('Annuler');
      r.c.depot.avant = await lance(`return ta.dispatchEvent(new InputEvent('beforeinput', { inputType: 'insertFromDrop', data: 'a\\nb', bubbles: true, cancelable: true }));`);
      await pause(300); r.c.depot.bandeau2 = await bandeau(); if (r.c.depot.bandeau2) await bouton('Annuler');
      await pause(500); r.c.depot.entre = (await ent()).includes('touch ' + M('d1')) || (await ent()).includes('a\rb') || (await ent()).includes('a\nb'); r.c.depot.marqueur = await existe('d1');
    });
    await essai('coller', async () => {
      await vide(); await coller(`touch ${M('ok')}\n`); await pause(300); r.c.avantColler = await existe('ok'); await bouton('Coller'); await pause(2500);
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
        await s.ev(`document.getElementById('terminal').style.top = '${ph}px'`); await pause(300);
        await taper(BOITE);
        const GEO = `(() => { const w = document.createTreeWalker(document.querySelector('.xterm-rows'), NodeFilter.SHOW_TEXT); let n, hit = null;
          while ((n = w.nextNode())) { const i = n.data.indexOf('╭──────╮'); if (i >= 0) hit = { n, i }; }
          if (!hit) return null; const rg = document.createRange(); rg.setStart(hit.n, hit.i); rg.setEnd(hit.n, hit.i + 1); const a = rg.getBoundingClientRect();
          rg.setStart(hit.n, hit.i + 7); rg.setEnd(hit.n, hit.i + 8); const b = rg.getBoundingClientRect(); const ligne = hit.n.parentElement.closest('.xterm-rows > div').getBoundingClientRect();
          return { ox: a.left, cw: (b.right - a.left) / 8, oy: ligne.top, ch: ligne.height, dpr: devicePixelRatio }; })()`;
        await att(`!!(${GEO})`, "boîte à l'écran");
        await pause(400); // la grille est posée : la capture suit
        const g = await s.ev(GEO), shot = await s.send('Page.captureScreenshot', { format: 'png' }), im = png(Buffer.from(shot.data, 'base64')), S = g.dpr;
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
        const pt = await s.ev(`(() => { const w = document.createTreeWalker(document.querySelector('.xterm-rows'), NodeFilter.SHOW_TEXT); let n, hit = null;
          while ((n = w.nextNode())) { const i = n.data.lastIndexOf(${JSON.stringify(lib)}); if (i >= 0 && n.data.indexOf('printf') < 0) hit = { n, i }; }
          if (!hit) return null; const rg = document.createRange(); rg.setStart(hit.n, hit.i + 1); rg.setEnd(hit.n, hit.i + 3); const b = rg.getBoundingClientRect(); return { x: b.left + b.width / 2, y: b.top + b.height / 2 }; })()`);
        if (!pt) throw new Error(`cellule ${lib} absente de la grille`);
        await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: pt.x - 2, y: pt.y }); await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: pt.x, y: pt.y }); await pause(150);
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
    r.e3 = {};
    for (const h of [160, 208, 280, 328, 570]) {
      await essai(`e3-${h}`, async () => {
        await cadre(600, h); await pause(900);
        r.e3[h] = await s.ev(`(() => { const l = document.querySelectorAll('.xterm-rows > div'), d = l[l.length - 1].getBoundingClientRect(), z = document.querySelector('.xterm-screen').getBoundingClientRect();
          return { bas: Math.round(d.bottom * 100) / 100, visible: window.innerHeight, lignes: l.length, ecran: Math.round(z.height) }; })()`);
      });
    }
    const barre = `(() => { const b = document.querySelector('.xterm-scrollable-element > .scrollbar.vertical'); return b ? getComputedStyle(b).opacity : 'absente'; })()`;
    await essai('barre', async () => {
      await cadre(600, 570); await pause(700);
      await taper('clear; seq 1 300'); await att(`${TXT}.includes('300')`, '300 lignes imprimées');
      await att(`${barre} !== 'absente'`, 'barre de défilement dans le DOM');
      r.g3 = { fin0: await s.ev(`${TXT}.includes('300')`) };
      await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: 900, y: 300 }); await pause(500); r.g3.dehors = await s.ev(barre); // pointeur hors du cadre
      await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: 300, y: 300 }); await pause(500); r.g3.survol = await s.ev(barre);
      await s.send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: 300, y: 300, deltaX: 0, deltaY: -400 }); await pause(500);
      r.g3.fin1 = await s.ev(`${TXT}.includes('300')`);
      await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: 900, y: 300 }); await pause(1600); r.g3.apres = await s.ev(barre);
      await touche({ key: 'PageUp', code: 'PageUp', windowsVirtualKeyCode: 33, modifiers: 8 }); await pause(400); r.g3.clavier = await s.ev(barre);
      await pause(1800); r.g3.repos = await s.ev(barre);
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
      await s.send('Emulation.setDeviceMetricsOverride', { width: 1400, height: 1000, deviceScaleFactor: 1, mobile: false });
      const cond = `(() => { const m = ${TXT}.match(/WINCH (\\d+)x(\\d+)/g); if (!m) return false; const d = m[m.length - 1].match(/(\\d+)x(\\d+)/); return Number(d[1]) === document.querySelector('.xterm-rows').childElementCount; })()`;
      await att(cond, 'WINCH <lignes>x<colonnes> aux dimensions de la grille');
      r.winch = await s.ev(`(() => { const m = ${TXT}.match(/WINCH (\\d+x\\d+)/g); return m[m.length - 1].slice(6); })()`);
      r.lignes = await s.ev(`document.querySelector('.xterm-rows').childElementCount`);
    });
    await essai('sigint', async () => {
      await touche({ key: 'c', code: 'KeyC', windowsVirtualKeyCode: 67, modifiers: 2 });
      await att(`${TXT}.includes('SIGINT-RECU')`, 'SIGINT-RECU');
      r.sigint = true;
      r.debutApres = await s.ev(`${TXT}.includes('TEMOIN-PLEIN-ECRAN-DEBUT')`);
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
    const pt = await s.ev(`(() => { const sp = [...document.querySelectorAll('.xterm-rows span')].find((x) => x.textContent.indexOf('LIEN') >= 0); if (!sp) return null; const b = sp.getBoundingClientRect(); return { x: b.left + b.width / 2, y: b.top + b.height / 2 }; })()`);
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
hx() { node "$AUX/hex.mjs" "$@"; }
amorce_neuve() { node -e "console.log(require('crypto').randomBytes(24).toString('hex'))"; }
mklab() {
  local L="$1" B="$1/.planning"; mkdir -p "$L/src" "$B/phases/01-socle"; printf 'export const u = 1;\n' > "$L/src/u.js"
  printf -- '## Phases\n\n- [x] **Phase 1: Socle** - premier jet\n\n### Phase 1: Socle\n**Goal**: Poser le socle\n' > "$B/ROADMAP.md"
  printf -- '---\nstatus: executing\ncurrent_phase: 1\nmilestone: v1.0 MVP\n---\n' > "$B/STATE.md"
  printf -- '---\nwave: 1\nfiles_modified: [src/u.js]\n---\n<objective>Poser le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  node "$SCRIPTS/vf-cockpit.mjs" build --lab "$L" > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
}
SRVN=0
srv() { # srv <sortie> [moteur] -> SRV_PORT SRV_PID SRV_O SRV_OUT QP AMORCE ; serveur lancé directement avec --terminal, comme le lanceur
  local o="$1" eng="${2:-$ENG}" lab; lab="$(cd "$1/../.." && pwd)"
  SRVN=$((SRVN+1)); SRV_O="$o"; SRV_OUT="$WORK/serve-$SRVN.out"; rm -f "$o/.cache/server.json" "$o/.cache/terminal-amorce"; mkdir -p "$o/.cache"
  AMORCE="$(amorce_neuve)"; (umask 077; printf '%s' "$AMORCE" > "$o/.cache/terminal-amorce")
  ( cd "$lab" && VF_COCKPIT_ENGINE_DIR="$eng" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS" exec node "$o/serve.mjs" --no-open --terminal --port "$(libre)" > "$SRV_OUT" 2>&1 ) </dev/null >/dev/null 2>&1 &
  SRV_PID=$!; PIDS+=($SRV_PID)
  for _ in $(seq 1 100); do grep -q '"terminal"' "$o/.cache/server.json" 2>/dev/null && break; sleep 0.1; done
  SRV_PORT="$(sj j.port)"; SRV_PORT="${SRV_PORT:-0}"; QP="$(sj '(j.terminal&&j.terminal.url)||"http://127.0.0.1:0"')"; QP="${QP##*:}"
}
sj() { node "$AUX/ev.mjs" "$1" < "$SRV_O/.cache/server.json" 2>/dev/null; }
unsrv() { vf_hyg_stop "$SRV_PID"; }
mutant() { # mutant <nom> <fichier-relatif-à-la-sortie> <expression-sed> -> MUT_OUT ; code 1 si la cible manque ou si la copie n'a pas changé
  local d="$WORK/mut-$1" f; rm -rf "$d"; mkdir -p "$d"; cp -R "$LAB/.planning" "$d/.planning"; cp -R "$LAB/.vibeflow" "$d/.vibeflow"
  MUT_OUT="$d/.vibeflow/cockpit"; f="$MUT_OUT/$2"; [ -f "$f" ] || return 1
  cp "$f" "$f.orig"; sed -i.bak "$3" "$f"; local r=0; cmp -s "$f" "$f.orig" && r=1; rm -f "$f.orig" "$f.bak"; return $r
}
mutant_eng() { # mutant_eng <nom> <expression-sed> -> MUT_ENG : copie du moteur dont l'assistant PTY est muté
  MUT_ENG="$WORK/eng-$1"; rm -rf "$MUT_ENG"; cp -R "$ENG" "$MUT_ENG"; local f="$MUT_ENG/terminal/vf-cockpit-pty.py"; [ -f "$f" ] || return 1
  cp "$f" "$f.orig"; sed -i.bak "$2" "$f"; local r=0; cmp -s "$f" "$f.orig" && r=1; rm -f "$f.orig" "$f.bak"; return $r
}
sans_effet() { assert_eq "$1 — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; }
rouge() { echo "     [mutant] obtenu $1, le code sain rend $2" >&2; [ "$1" != "$2" ] && echo rouge || echo "identique : $1"; }
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
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
