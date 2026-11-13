// vf-cockpit-signal-serveur — l'émetteur de vf-signal lit la route d'état d'un serveur du lab VIVANT et RECONNU (79-12, SOCL-16 ; C2, P68-D-41).
// Tout ce qui vient du lab ou de la réponse est NON FIABLE : le fichier d'état (régulier, 16 Kio au plus, ni lien ni autre type), le PID (reconnu par la ligne
// de commande du processus : serve.mjs du module de l'émetteur et `--sortie=` exact), la réponse (état 200, schéma, conformité au contrat, racine du lab,
// fraîcheur, état de collecte, taille et durée bornées). Un doute vaut `null` : l'appelant se replie sur sa collecte locale. Aucune écriture, aucune exception.
// Exports : FRAICHEUR_MAX_MS, DELAI_HTTP_MS, MAX_OCTETS, conforme(signal, contrat), lireEtatHttp({ port, jeton, delaiMs, maxOctets }),
//   signalDuServeur(racine, { schema, dossierScripts, contrat, maintenant }) -> { signal } | null.
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import { serveurVivant, identiteServeur, estNotre, etatFile } from './vf-cockpit-serveur-vivant.mjs';
import { shBorne, avecEcheance, resoudreBinaire, pathAssaini } from './vf-cockpit-paths.mjs';
import { ENTETE_JETON } from './vf-cockpit-lancer-post.mjs';

export const FRAICHEUR_MAX_MS = 20000, DELAI_HTTP_MS = 1500, MAX_OCTETS = 2 << 20;
const PROFONDEUR_MAX = 20, NOEUDS_MAX = 200000, ETAT_MAX = 16384, SCHEMA_ETAT = 'vibeflow/cockpit-state@1';
const TYPES = { string: (v) => typeof v === 'string', number: (v) => typeof v === 'number' && Number.isFinite(v), boolean: (v) => typeof v === 'boolean',
  object: (v) => !!v && typeof v === 'object' && !Array.isArray(v), array: Array.isArray, any: () => true };
const porte = (o, ks) => !!o && typeof o === 'object' && Object.entries(o).some(([k, v]) => ks.includes(k) || porte(v, ks));

// conformité d'un `signal` au contrat : type de chaque clé requise, clés requises de chaque élément des listes, aucune clé interdite à aucun niveau ;
// les clés en plus sont tolérées (les ajouts facultatifs des autres phases ne rejettent rien)
export function conforme(signal, contrat) {
  const spec = contrat && contrat.schemas && contrat.schemas['vibeflow/cockpit-signal@1'];
  if (!spec || !TYPES.object(signal) || !Array.isArray(spec.interdits) || !spec.interdits.length) return false;
  for (const [k, t] of Object.entries(spec.requis || {})) if (!(k in signal) || !(TYPES[t] || (() => false))(signal[k])) return false;
  if (porte(signal, spec.interdits)) return false;
  const cles = (nom) => (spec[nom] || {}).requis || [], tab = (x) => (Array.isArray(x) ? x : []);
  const ok = (liste, nom) => liste.every((o) => TYPES.object(o) && cles(nom).every((k) => k in o)); // garde:signal-sous-schemas
  const arbres = tab(signal.arbres), missions = tab(signal.missions);
  return ok(tab(signal.phases), 'phase') && ok(tab(signal.jalons), 'jalon') && ok(missions, 'mission') && ok(tab(signal.verrous.liste), 'verrou')
    && ok(missions.flatMap((m) => tab(m.noeuds)), 'noeud') && ok(arbres, 'arbre') && ok(arbres.map((x) => x.retard).filter(Boolean), 'retard');
}

// borne de la réponse (itérative : jamais une récursion sur une forme forgée) : profondeur et nombre de noeuds
const borne = (racine) => {
  let n = 0; const pile = [[racine, 1]];
  while (pile.length) {
    const [v, d] = pile.pop();
    if (d > PROFONDEUR_MAX || ++n > NOEUDS_MAX) return false;
    if (v && typeof v === 'object') for (const x of Object.values(v)) pile.push([x, d + 1]);
  }
  return true;
};
// projection par liste blanche : seules les clés du contrat sortent, au premier niveau et dans chaque élément des listes
const garder = (o, noms) => Object.fromEntries(noms.filter((k) => k in o).map((k) => [k, o[k]]));
export function projeter(sg, contrat) {
  const spec = contrat.schemas['vibeflow/cockpit-signal@1'], noms = (n) => [...(spec[n].requis || []), ...(spec[n].optionnels || [])];
  const liste = (l, n) => l.map((o) => garder(o, noms(n)));
  const p = garder(sg, Object.keys(spec.requis));
  p.phases = liste(sg.phases, 'phase'); p.jalons = liste(sg.jalons, 'jalon');
  p.missions = sg.missions.map((m) => ({ ...garder(m, noms('mission')), ...(Array.isArray(m.noeuds) ? { noeuds: liste(m.noeuds, 'noeud') } : {}) }));
  p.verrous = { ...garder(sg.verrous, ['etat', 'plat']), liste: liste(sg.verrous.liste || [], 'verrou') };
  p.arbres = sg.arbres.map((a) => ({ ...garder(a, noms('arbre')), retard: a.retard ? garder(a.retard, noms('retard')) : a.retard }));
  return p;
}
// identité STRICTE (jamais la forme de la version précédente de estNotre) : serve.mjs du module en mot entier ET `--sortie=<chemin réel>` en fin de ligne
const strict = (cmd, id) => {
  const c = typeof cmd === 'string' ? cmd.trimEnd() : '';
  return !!id && c.includes(` ${id.serve} `) && c.endsWith(` --sortie=${id.sortie}`);
};

// une requête locale vers 127.0.0.1 seulement, hôte explicite, aucune en-tête d'origine, aucune réutilisation de connexion, échéance TOTALE
export function lireEtatHttp({ port, jeton, delaiMs = DELAI_HTTP_MS, maxOctets = MAX_OCTETS }) {
  return new Promise((resolve) => {
    let fini = false, minuterie = null;
    const fin = (v) => { if (!fini) { fini = true; clearTimeout(minuterie); resolve(v); } };
    const entetes = { Host: `127.0.0.1:${port}`, [ENTETE_JETON]: jeton, Connection: 'close' };
    const r = http.get({ host: '127.0.0.1', port, path: '/api/vf/state', agent: false, headers: entetes }, (res) => {
      let n = 0; const morceaux = [];
      res.on('data', (c) => { n += c.length; if (n > maxOctets) { r.destroy(); fin(null); } else morceaux.push(c); }); // garde:signal-plafond
      res.on('end', () => fin({ code: res.statusCode, corps: Buffer.concat(morceaux).toString('utf8') }));
      res.on('error', () => fin(null));
    });
    minuterie = setTimeout(() => { r.destroy(); fin(null); }, delaiMs); // garde:signal-delai
    r.on('error', () => fin(null));
  });
}

// la ligne de commande d'un PID par `ps`, lancé par le lancement borné du socle, sous une échéance de 1,5 s ; le lanceur n'a pas besoin de la lire seul
const lireCommande = (pid, lab) => {
  const ps = resoudreBinaire('ps', pathAssaini());
  return ps ? avecEcheance(1500, () => shBorne(ps, ['-ww', '-o', 'command=', '-p', String(pid)], lab, lab)) : null;
};

export async function signalDuServeur(racine, { schema, dossierScripts, contrat, maintenant } = {}) {
  try {
    const sortie = path.join(racine, '.vibeflow', 'cockpit'), fichier = etatFile(sortie);
    const st = fs.lstatSync(fichier);
    if (!st.isFile() || st.size > ETAT_MAX) return null; // garde:signal-lien
    const s = serveurVivant(sortie);
    if (!s || !/^[0-9a-f]{8,128}$/.test(String(s.token))) return null;
    const ident = identiteServeur(dossierScripts, sortie);
    const cmd = lireCommande(s.pid, racine); // un seul `ps` : lu pour `estNotre` et pour l'identité stricte
    const reconnu = estNotre(s.pid, ident, racine, () => cmd) && strict(cmd, ident);
    if (!reconnu) return null; // garde:signal-estnotre
    const r = await lireEtatHttp({ port: s.port, jeton: s.token });
    if (!r || r.code !== 200) return null; // garde:signal-code
    const o = JSON.parse(r.corps);
    if (!o || o.schema !== SCHEMA_ETAT) return null; // garde:signal-schema
    if (!borne(o)) return null; // garde:signal-borne
    const sg = o.signal;
    if (!(sg && sg.schema === schema && conforme(sg, contrat))) return null; // garde:signal-conforme
    let a = null, b = null;
    try { a = fs.realpathSync(sg.root); b = fs.realpathSync(racine); } catch { return null; } // fermé par défaut : une racine qui ne se résout pas vaut refus
    if (a !== b) return null; // garde:signal-racine
    if (!['ok', 'partielle'].includes(o.collecte && o.collecte.etat)) return null; // garde:signal-collecte
    const now = typeof maintenant === 'function' ? maintenant() : (maintenant ?? Date.now()), age = now - Date.parse(sg.at);
    if (!(age > -1000 && age < FRAICHEUR_MAX_MS)) return null; // garde:signal-fraicheur
    return { signal: projeter(sg, contrat) }; // garde:signal-projection
  } catch { return null; }
}
