#!/usr/bin/env node
// terminal-aux.mjs — client de test commun des suites du terminal intégré du cockpit (Phase 71).
// Aucune dépendance, échéance propre à chaque appel, sortie 0 sauf `attendre` (1 si la sous-chaîne est absente).
// Sous-commandes :
//   req <port> <METHODE> <chemin> [options]   statut (ou « ERREUR <code> »), en-têtes JSON en minuscules, corps (64 Kio au plus)
//        options : --host H · --origin O · --sans-origin · --secret S (X-VF-Terminal) · --amorce A (X-VF-Amorce) · --onglet T (X-VF-Onglet)
//                  --jeton J (x-vf-cockpit-token) · --entete nom:valeur · --corps texte (\n \r \xNN) · --corps-octets n
//                  --corps-vers fichier (corps COMPLET écrit dans ce fichier) · --echeance ms (5000 par défaut)
//        défauts : Host 127.0.0.1:<port>, Origin http://127.0.0.1:<port>
//   amorcer <portQ> <fichier>                  POST /amorce, Origin de Q, amorçage lu dans le fichier : statut puis secret
//   flux <portQ> <secret> <onglet> <fichier> <duree-ms> [--taille LxC]   GET /flux : octets ajoutés au fichier, puis « FIN-FLUX <raison> »
//   entree <portQ> <secret> <onglet> <texte>   POST /entree (séquences \n \r \xNN interprétées) : statut
//   taille <portQ> <secret> <onglet> <l> <c>   POST /taille : statut
//   etat <portQ> <secret>                      GET /etat : statut puis corps
//   attendre <fichier> <sous-chaine> <ms>      lecture latin1 toutes les 50 ms : TROUVE (0) ou ABSENT (1)
//   ecoutes <pid>                              adresses en écoute du PID (lsof, sinon ss), sinon INDISPONIBLE
//   csp-v275 <fichier-html> <source>           CSP que la formule de v2.75.0 donne aux <script> sans attribut du fichier, plus la source du préfixe (79-16)
//   ligne-csp <serve.mjs>                      ligne qui commence par « const csp = » (deux espaces)
//   ligne-csp-v275                             la même ligne, copie figée de v2.75.0
import http from 'node:http';
import fs from 'node:fs';
import crypto from 'node:crypto';
import { execFileSync } from 'node:child_process';

const [, , cmd, ...args] = process.argv;

// copie figée de v2.75.0 (formule de pageCsp, serve.mjs) AVEC la seule source de script du préfixe de /_vf/ (79-16, A40 : `${source}` insérée après les empreintes) ; ne se met JAMAIS à jour avec le moteur
const LIGNE_CSP_V275 = "  const csp = `default-src 'none'; script-src ${[...new Set(hashes)].join(' ')} ${source}; style-src 'unsafe-inline'; img-src 'self' data:; font-src data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'; object-src 'none'`;";
const cspV275 = (html, source) => {
  const hashes = [...String(html).matchAll(/<script>([\s\S]*?)<\/script>/g)].map((m) => `'sha256-${crypto.createHash('sha256').update(m[1]).digest('base64')}'`);
  return `default-src 'none'; script-src ${[...new Set(hashes)].join(' ')} ${source}; style-src 'unsafe-inline'; img-src 'self' data:; font-src data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'; object-src 'none'`;
};

const interpreter = (t) => String(t).replace(/\\x([0-9a-fA-F]{2})/g, (_, h) => String.fromCharCode(parseInt(h, 16))).replace(/\\n/g, '\n').replace(/\\r/g, '\r');
const flag = (a, nom) => { const i = a.indexOf(nom); return i < 0 ? undefined : a[i + 1]; };
const a_ = (a, nom) => a.includes(nom);

function requete({ port, methode, chemin, host, origin, entetes = {}, corps, echeance = 5000, versFichier }) {
  return new Promise((resolve) => {
    const h = { Host: host ?? `127.0.0.1:${port}`, ...(origin ? { Origin: origin } : {}), ...entetes };
    if (corps !== undefined) h['Content-Length'] = Buffer.byteLength(corps);
    const r = http.request({ host: '127.0.0.1', port: Number(port), path: chemin, method: methode, headers: h, agent: false }, (res) => {
      const morceaux = [];
      res.on('data', (c) => morceaux.push(c));
      res.on('end', () => {
        const tout = Buffer.concat(morceaux);
        if (versFichier) fs.writeFileSync(versFichier, tout);
        resolve({ statut: res.statusCode, entetes: res.headers, corps: tout.subarray(0, 65536).toString('utf8') });
      });
      res.on('error', (e) => resolve({ erreur: e.code || 'ECHEC' }));
    });
    r.setTimeout(echeance, () => { r.destroy(); resolve({ erreur: 'ETIMEDOUT' }); });
    r.on('error', (e) => resolve({ erreur: e.code || 'ECHEC' }));
    if (corps !== undefined) r.write(corps);
    r.end();
  });
}
const afficher = (r) => {
  if (r.erreur) { console.log(`ERREUR ${r.erreur}`); return; }
  console.log(r.statut); console.log(JSON.stringify(r.entetes)); process.stdout.write(r.corps);
};
const enteteTerm = (secret, onglet) => ({ ...(secret ? { 'X-VF-Terminal': secret } : {}), ...(onglet ? { 'X-VF-Onglet': onglet } : {}) });
const origineQ = (port) => `http://127.0.0.1:${port}`;

async function main() {
  if (cmd === 'req') {
    const [port, methode, chemin, ...o] = args;
    const entetes = { ...enteteTerm(flag(o, '--secret'), flag(o, '--onglet')) };
    if (flag(o, '--amorce')) entetes['X-VF-Amorce'] = flag(o, '--amorce');
    if (flag(o, '--jeton')) entetes['x-vf-cockpit-token'] = flag(o, '--jeton');
    const e = flag(o, '--entete'); if (e) { const i = e.indexOf(':'); entetes[e.slice(0, i)] = e.slice(i + 1); }
    let corps = flag(o, '--corps') !== undefined ? interpreter(flag(o, '--corps')) : undefined;
    if (flag(o, '--corps-octets')) corps = 'x'.repeat(Number(flag(o, '--corps-octets')));
    afficher(await requete({ port, methode, chemin, host: flag(o, '--host'), origin: a_(o, '--sans-origin') ? null : (flag(o, '--origin') ?? origineQ(port)), entetes, corps, echeance: Number(flag(o, '--echeance') || 5000), versFichier: flag(o, '--corps-vers') }));
  } else if (cmd === 'amorcer') {
    const [port, fichier] = args;
    let amorce = ''; try { amorce = fs.readFileSync(fichier, 'utf8').trim(); } catch {}
    const r = await requete({ port, methode: 'POST', chemin: '/amorce', origin: origineQ(port), entetes: { 'X-VF-Amorce': amorce } });
    if (r.erreur) { console.log(`ERREUR ${r.erreur}`); return; }
    let secret = ''; try { secret = JSON.parse(r.corps).secret || ''; } catch {}
    console.log(r.statut); console.log(secret);
  } else if (cmd === 'flux') {
    const [port, secret, onglet, fichier, duree, ...o] = args;
    const entetes = enteteTerm(secret, onglet); if (flag(o, '--taille')) entetes['X-VF-Taille'] = flag(o, '--taille');
    await new Promise((resolve) => {
      let fini = false; const clore = (raison) => { if (fini) return; fini = true; console.log(`FIN-FLUX ${raison}`); resolve(); };
      const r = http.request({ host: '127.0.0.1', port: Number(port), path: '/flux', method: 'GET', agent: false, headers: { Host: `127.0.0.1:${port}`, Origin: origineQ(port), ...entetes } }, (res) => {
        if (res.statusCode !== 200) { res.resume(); clore(`statut ${res.statusCode}`); return; }
        res.on('data', (c) => fs.appendFileSync(fichier, c));
        res.on('end', () => clore('fin'));
        res.on('error', () => clore('erreur'));
      });
      r.on('error', (e) => clore(`erreur ${e.code || 'ECHEC'}`));
      setTimeout(() => { r.destroy(); clore('duree'); }, Number(duree)).unref?.();
      r.end();
      // la minuterie ne doit pas garder le processus ouvert si la réponse s'est terminée avant
    });
    process.exit(0);
  } else if (cmd === 'entree') {
    const [port, secret, onglet, texte] = args;
    const r = await requete({ port, methode: 'POST', chemin: '/entree', origin: origineQ(port), entetes: enteteTerm(secret, onglet), corps: interpreter(texte) });
    console.log(r.erreur ? `ERREUR ${r.erreur}` : r.statut);
  } else if (cmd === 'taille') {
    const [port, secret, onglet, l, c] = args;
    const r = await requete({ port, methode: 'POST', chemin: '/taille', origin: origineQ(port), entetes: enteteTerm(secret, onglet), corps: `${l} ${c}` });
    console.log(r.erreur ? `ERREUR ${r.erreur}` : r.statut);
  } else if (cmd === 'etat') {
    const [port, secret] = args;
    afficher(await requete({ port, methode: 'GET', chemin: '/etat', origin: origineQ(port), entetes: enteteTerm(secret) }));
  } else if (cmd === 'attendre') {
    const [fichier, sous, ms] = args; const fin = Date.now() + Number(ms);
    for (;;) {
      let t = ''; try { t = fs.readFileSync(fichier).toString('latin1'); } catch {}
      if (t.includes(sous)) { console.log('TROUVE'); process.exit(0); }
      if (Date.now() >= fin) { console.log('ABSENT'); process.exit(1); }
      await new Promise((r) => setTimeout(r, 50));
    }
  } else if (cmd === 'ecoutes') {
    const [pid] = args; let sortie = null;
    try { sortie = execFileSync('lsof', ['-nP', '-a', '-p', pid, '-iTCP', '-sTCP:LISTEN'], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }); } catch (e) { if (e.status === 1) sortie = ''; }
    if (sortie !== null) {
      const lignes = sortie.split('\n').filter((l) => /\(LISTEN\)/.test(l));
      console.log(lignes.map((l) => (l.match(/(\S+:\d+) \(LISTEN\)/) || [])[1]).filter(Boolean).sort().join('\n'));
      return;
    }
    try {
      const ss = execFileSync('ss', ['-ltnpH'], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] });
      console.log(ss.split('\n').filter((l) => new RegExp(`pid=${pid},`).test(l)).map((l) => l.trim().split(/\s+/)[3]).filter(Boolean).sort().join('\n'));
    } catch { console.log('INDISPONIBLE'); }
  } else if (cmd === 'csp-v275') {
    console.log(cspV275(fs.readFileSync(args[0], 'utf8'), args[1] || ''));
  } else if (cmd === 'ligne-csp') {
    const l = fs.readFileSync(args[0], 'utf8').split('\n').find((x) => x.startsWith('  const csp = '));
    console.log(l ?? 'ABSENTE');
  } else if (cmd === 'ligne-csp-v275') {
    console.log(LIGNE_CSP_V275);
  } else {
    console.error('usage : terminal-aux.mjs {req|amorcer|flux|entree|taille|etat|attendre|ecoutes|csp-v275|ligne-csp|ligne-csp-v275} …'); process.exit(64);
  }
}
main().then(() => { if (cmd !== 'flux') process.exitCode = process.exitCode || 0; });
