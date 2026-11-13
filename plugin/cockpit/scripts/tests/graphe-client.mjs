#!/usr/bin/env node
// graphe-client.mjs — aide de test-cockpit-graphe.sh (79-15) : un GET brut ou un flux d'événements, sans dépendance. Rien n'est évalué.
//   get <port> <chemin> [jeton] [hôte] [Nom=valeur…]  écrit une ligne JSON { statut, entetes, corps } ; en-têtes supplémentaires en arguments ;
//       GRAPHE_METHODE (méthode) et GRAPHE_CORPS (corps) en environnement
//   sse <port> <jeton> <maxMs> <arret> <fichier>      une ligne JSON par événement ({ abs, event, data }) ; s'arrête sur l'événement <arret> ou après maxMs
import http from 'node:http';
import fs from 'node:fs';

const [, , mode, port, a1, a2, a3, ...reste] = process.argv;
if (mode === 'get') {
  const [chemin, jeton, hote] = [a1, a2, a3];
  const entetes = { Host: hote || `127.0.0.1:${port}`, ...(jeton ? { 'x-vf-cockpit-token': jeton } : {}) };
  for (const r of reste) { const i = r.indexOf('='); if (i > 0) entetes[r.slice(0, i)] = r.slice(i + 1); }
  const req = http.request({ host: '127.0.0.1', port: Number(port), path: chemin, method: process.env.GRAPHE_METHODE || 'GET', headers: entetes }, (res) => {
    const morceaux = []; res.on('data', (c) => morceaux.push(c));
    res.on('end', () => { console.log(JSON.stringify({ statut: res.statusCode, entetes: res.headers, corps: Buffer.concat(morceaux).toString('utf8') })); });
  });
  req.on('error', (e) => { console.log(JSON.stringify({ statut: 0, erreur: e.message })); });
  if (process.env.GRAPHE_CORPS) req.write(process.env.GRAPHE_CORPS); // corps d'une requête POST (GRAPHE_METHODE)
  req.end();
} else if (mode === 'sse') {
  const [jeton, maxMs, arret, sortie] = [a1, a2, a3, reste[0]];
  const noter = (o) => fs.appendFileSync(sortie, JSON.stringify({ abs: Date.now(), ...o }) + '\n');
  const fin = () => { try { req.destroy(); } catch {} process.exit(0); };
  const req = http.get({ host: '127.0.0.1', port: Number(port), path: '/api/vf/events', headers: { Host: `127.0.0.1:${port}`, 'x-vf-cockpit-token': jeton } }, (res) => {
    noter({ statut: res.statusCode });
    let tampon = '';
    res.on('data', (c) => {
      tampon += c; let i;
      while ((i = tampon.indexOf('\n\n')) >= 0) {
        const bloc = tampon.slice(0, i); tampon = tampon.slice(i + 2);
        const ev = /^event: (.*)$/m.exec(bloc)?.[1], dt = /^data: (.*)$/m.exec(bloc)?.[1];
        if (!ev) continue;
        let data = null; try { data = JSON.parse(dt); } catch {}
        noter({ event: ev, data: ev === 'hello' ? { seq: data?.seq } : data });
        if (ev === arret) fin();
      }
    });
  });
  req.on('error', (e) => { noter({ erreur: e.message }); process.exit(0); });
  setTimeout(fin, Number(maxMs));
}
