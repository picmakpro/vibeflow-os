// vf-cockpit-terminal-page — page servie par le serveur du terminal Q (71-01 pour l'amorce, 71-05 pour la page finale).
// Exports : EMPREINTES_XTERM · EMPREINTES_BOITE · preparerPage({ engineDir }) · pageTerminal({ theme, origineP }) -> { html, csp }.
// preparerPage lit le vendor xterm du moteur (VF_COCKPIT_ENGINE_DIR/assets/vendor/xterm) et le vérifie contre le code ET SHA256SUMS : une
// altération lève une erreur, et le serveur de Q refuse de démarrer (TERM-10). La vue, le client et la feuille de Q sont des fichiers du moteur
// (assets/ui/terminal/vue.js, client.js, q.css), lus comme texte par le lecteur fermé vf-cockpit-navigateur.mjs après les contrôles du vendor
// (79-11). pageTerminal assemble tout en ligne (P71-D-16) : deux <style>
// (polices et feuille de Q, puis xterm.css à l'octet), quatre <script> sans attribut (xterm, addon-fit, vue, client) dont la CSP porte les
// empreintes recalculées sur le texte final, aucun <link>, aucune police réseau. Le thème (P71-D-19) vaut `light` si la valeur reçue est exactement `light`,
// sinon sombre ; la valeur reçue n'est jamais insérée. Aucun autre paramètre d'adresse n'est lu (P71-D-15).
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { lireFeuille, lireFonction } from './vf-cockpit-navigateur.mjs';

// sha256 épinglés (@xterm/xterm 6.0.0, @xterm/addon-fit 0.11.0) ; 71-11 les vérifie aussi côté dépôt (V9)
export const EMPREINTES_XTERM = Object.freeze({
  'xterm.js': '14903579ff54664cd72f8e8699e6961a6272c21863ec1c3b118cdc8af5d4a972',
  'xterm.css': '854a7c0fb70e8b1a083c16797ab827299fb18744f5ad34f227b48337e33293c6',
  'addon-fit.js': 'ba3ea256ce0620a0992a197d6c9baea64823fc93d8da07a9e366ca9943c18527',
});
// JetBrains Mono 2.304 Regular (release officielle JetBrains/JetBrainsMono, OFL-1.1), fichier pris tel quel : il ne sert que pour les traits de boîte
// U+2500-259F (le sous-ensemble latin n'en porte aucun et Chrome les dessinait en police système : traits discontinus, UI-SPEC F3, J3 de la critique 71).
// La plage de poids déclarée (100 900) est celle des faces latines, et NON 400 : une face à poids exact change la police primaire du moteur DOM, la cellule
// passe de 17 à 15 px de haut (mesuré). Un seul fichier : ces traits n'ont pas de variante grasse.
export const EMPREINTES_BOITE = Object.freeze({
  'jetbrains-mono-2.304-regular.woff2': { sha: 'a9cb1cd82332b23a47e3a1239d25d13c86d16c4220695e34b243effa999f45f2' },
});
const PLAGE_BOITE = 'U+2500-259F';
const PLAGES = {
  latin: 'U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+0304,U+0308,U+0329,U+2000-206F,U+20AC,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD',
  'latin-ext': 'U+0100-02BA,U+02BD-02C5,U+02C7-02CC,U+02CE-02D7,U+02DD-02FF,U+0304,U+0308,U+0329,U+1D00-1DBF,U+1E00-1E9F,U+1EF2-1EFF,U+2020,U+20A0-20AB,U+20AD-20C0,U+2113,U+2C60-2C7F,U+A720-A7FF',
};
const sha256 = (b) => crypto.createHash('sha256').update(b).digest('hex');
let vendor = null; // { js, fit, css, polices, vue, client, styleQ } après preparerPage
const memo = new Map(); // CSP et page par thème et origine de P

export function preparerPage({ engineDir } = {}) {
  const dir = path.join(String(engineDir || ''), 'assets', 'vendor');
  const lire = (...p) => { try { return fs.readFileSync(path.join(dir, ...p)); } catch { throw new Error('fichiers xterm absents du moteur du cockpit : réinstaller le module cockpit.'); } };
  const fichiers = Object.fromEntries(Object.keys(EMPREINTES_XTERM).map((nom) => [nom, lire('xterm', nom)]));
  const sommes = lire('xterm', 'SHA256SUMS').toString('utf8');
  for (const [nom, buf] of Object.entries(fichiers)) {
    const h = sha256(buf);
    if (h !== EMPREINTES_XTERM[nom]) throw new Error(`fichiers xterm altérés : ${nom}`);
    if (!sommes.split('\n').some((l) => l.trim().split(/\s+/).join(' ') === `${h} ${nom}`)) throw new Error(`fichiers xterm altérés : SHA256SUMS (${nom})`);
  }
  const sommesP = lire('fonts', 'SHA256SUMS').toString('utf8');
  const boite = Object.entries(EMPREINTES_BOITE).map(([nom, { sha: pin }]) => {
    const buf = lire('fonts', nom), h = sha256(buf);
    if (h !== pin) throw new Error(`fichiers xterm altérés : ${nom}`);
    if (!sommesP.split('\n').some((l) => l.trim().split(/\s+/).join(' ') === `${h} ${nom}`)) throw new Error(`fichiers xterm altérés : SHA256SUMS des polices (${nom})`);
    return `@font-face{font-family:"JetBrains Mono";font-style:normal;font-display:block;font-weight:100 900;unicode-range:${PLAGE_BOITE};src:url(data:font/woff2;base64,${buf.toString('base64')}) format("woff2")}`;
  });
  const polices = Object.entries(PLAGES).map(([sous, plage]) =>
    `@font-face{font-family:"JetBrains Mono";font-style:normal;font-display:block;font-weight:100 900;unicode-range:${plage};src:url(data:font/woff2;base64,${lire('fonts', `jetbrains-mono-${sous}-wght-normal.woff2`).toString('base64')}) format("woff2")}`).concat(boite).join('\n');
  let q;
  try {
    const moteur = engineDir;
    q = {
      vue: lireFonction('terminal', 'vue.js', { moteur }),
      client: lireFonction('terminal', 'client.js', { moteur }),
      styleQ: lireFeuille('terminal', 'q.css', { moteur }),
    };
  } catch { throw new Error('fichiers du terminal absents du moteur du cockpit : réinstaller le module cockpit.'); }
  const [js, fit, css] = ['xterm.js', 'addon-fit.js', 'xterm.css'].map((nom) => fichiers[nom].toString('utf8'));
  vendor = { js, fit, css, polices, ...q };
  memo.clear();
}

export function pageTerminal({ theme, origineP = "'none'" } = {}) {
  if (!vendor) throw new Error('page du terminal non préparée');
  const clair = theme === 'light';
  const cle = `${clair ? 'light' : 'dark'}|${origineP}`;
  if (memo.has(cle)) return memo.get(cle);
  // même formule que pageCsp de serve.mjs pour les scripts ; le reste est la CSP de Q (71-RESEARCH §4.5), sans X-Frame-Options
  const cspDe = (corps) => {
    const empreintes = [...String(corps).matchAll(/<script>([\s\S]*?)<\/script>/g)].map((m) => `'sha256-${crypto.createHash('sha256').update(m[1]).digest('base64')}'`);
    return `default-src 'none'; script-src ${[...new Set(empreintes)].join(' ')}; style-src 'unsafe-inline'; connect-src 'self'; font-src data:; img-src data:; frame-ancestors ${origineP}; base-uri 'none'; form-action 'none'; object-src 'none'`;
  };
  const attr = clair ? ' data-theme="light"' : '';
  const cfg = JSON.stringify({ origineP, theme: clair ? 'light' : 'dark' }).replace(/</g, '\\u003c'); // jamais une valeur d'adresse
  let html = `<!doctype html>\n<html lang="fr"${attr}><head><meta charset="utf-8"><meta name="referrer" content="no-referrer"><title>Terminal</title>\n`
    + `<style>${vendor.polices}\n${vendor.styleQ}</style>\n<style>${vendor.css}</style>\n</head><body><div id="annonce" class="vf-q-sr" role="status" aria-live="polite"></div><div id="terminal"></div><div id="etat" hidden></div>\n`
    + `<script>${vendor.js}</script>\n<script>${vendor.fit}</script>\n<script>(${vendor.vue})(${cfg});</script>\n<script>(${vendor.client})(${cfg});</script>\n</body></html>\n`;
  const csp = cspDe(html);
  const r = { html, csp };
  memo.set(cle, r);
  return r;
}
