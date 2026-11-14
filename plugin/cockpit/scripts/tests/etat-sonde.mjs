// etat-sonde.mjs — préchargement de test (node --import) : enregistre toute connexion sortante dans $ETAT_SONDE_SORTIE (une ligne JSON par tentative),
// laisse passer 127.0.0.1, refuse tout le reste sans l'ouvrir (79-12, E10). L'hôte « localhost » n'est pas laissé passer : l'émetteur ne s'en sert jamais.
import fs from 'node:fs';
import net from 'node:net';

const sortie = process.env.ETAT_SONDE_SORTIE;
const connecter = net.Socket.prototype.connect;
net.Socket.prototype.connect = function (...args) {
  const premier = Array.isArray(args[0]) ? args[0][0] : args[0]; // Node passe parfois les arguments déjà normalisés : [options, rappel]
  const o = premier && typeof premier === 'object' ? premier : null;
  const port = o ? o.port : (typeof premier === 'number' ? premier : null), hote = o ? (o.host ?? 'localhost') : (typeof args[1] === 'string' ? args[1] : 'localhost');
  const local = !(o && o.path) && hote === '127.0.0.1';
  if (sortie) fs.appendFileSync(sortie, JSON.stringify({ hote, port: Number(port) || null, chemin: o && o.path ? true : false, refuse: !local }) + '\n');
  if (!local) { process.nextTick(() => this.destroy(Object.assign(new Error('connexion refusée par la sonde'), { code: 'ECONNREFUSED' }))); return this; }
  return connecter.apply(this, args);
};
