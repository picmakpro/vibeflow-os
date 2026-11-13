// vf-cockpit-cibles-suivi — lecture incrémentale EN MÉMOIRE des transcripts pour les cibles (79-13, SOCL-17 ; P79-D-04, P79-D-12, A22).
// Exports : creerSuivi({ limites }) -> { avancer({ voies, fichiers, arbres, maintenant, octets, ms, horloge }) -> { reste }, cibles(id), version(id),
//  reste(), oublier(ids) }.
// Un curseur par voie (fin de la dernière ligne COMPLÈTE), tranches bornées en octets et en temps (voies les plus récentes d'abord), reprise
//  depuis zéro quand
// le fichier raccourcit ou que sa tête change, plafond total d'entrées. Un fichier n'est jamais ouvert s'il n'est pas ordinaire (ni lien, ni tube)
//  ; l'ouverture
// ne suit pas de lien et ne bloque pas. Aucun fichier n'est écrit, aucun processus lancé, aucune variable d'environnement lue : tout reste dans ce module.
import fs from 'node:fs';
import crypto from 'node:crypto';
import { cibleVide, plierLigneCibles, listesDeCibles, LIMITES_CIBLES } from './vf-cockpit-cibles.mjs';
import { arbreDeNom } from './vf-cockpit-cible.mjs';

const BLOC = 1 << 20, LIGNE_MAX = 32 << 20, TETE = 1024;
const hash = (b) => crypto.createHash('sha256').update(b).digest('hex').slice(0, 16);
function teteDe(fd, taille) {
  const n = Math.min(taille, TETE), b = Buffer.alloc(n), k = n ? fs.readSync(fd, b, 0, n, 0) : 0, nl = b.subarray(0, k).indexOf(10);
  return nl >= 0 ? hash(b.subarray(0, nl)) : k >= TETE ? hash(b.subarray(0, k)) : null;
}
function ouvrir(f) {
  const k = fs.constants; let fd = null;
  try {
    if (!fs.lstatSync(f).isFile()) return null;
    fd = fs.openSync(f, k.O_RDONLY | (k.O_NOFOLLOW || 0) | (k.O_NONBLOCK || 0));
    const st = fs.fstatSync(fd); if (!st.isFile()) throw new Error('non ordinaire');
    return { fd, st };
  } catch { if (fd !== null) { try { fs.closeSync(fd); } catch { /* déjà fermé */ } } return null; }
}

export function creerSuivi({ limites } = {}) {
  const L = { ...LIMITES_CIBLES, ...(limites || {}) }, etats = new Map(), somme = { n: 0 };
  let purgeA = 0, resteVrai = false;
  const neuf = () => ({ taille: -1, mtimeMs: -1, tete: null, curseur: 0, saut: false, complet: false, etat: 'en-construction', cibles: cibleVide(), ver: 0 });
  const compte = (c) => c.ecritures.size + c.lectures.size;
  const reinit = (st) => {
    somme.n -= compte(st.cibles); st.cibles = cibleVide(); st.curseur = 0; st.saut = false; st.complet = false; st.etat = 'en-construction'; st.ver++;
  };

  function purger(limite) {
    for (const st of etats.values()) {
      let n = 0;
      for (const m of [st.cibles.ecritures, st.cibles.lectures]) for (const [k, e] of m) if (e.dernierMs < limite) { m.delete(k); somme.n--; n++; }
      if (n) st.ver++;
    }
  }

  // lit les octets ajoutés d'une voie jusqu'à épuisement de la tranche (au moins une ligne complète par visite, pour toujours avancer)
  function lire(st, fd, taille, ctx) {
    const { budget, octets, arbres, defaut, maintenant, cache } = ctx;
    let pos = st.curseur, pend = Buffer.alloc(0), saut = st.saut, lignes = 0, change = false;
    while (pos < taille && !(budget() && lignes > 0)) {
      const n = Math.min(BLOC, taille - pos, Math.max(65536, octets - ctx.lus)), b = Buffer.alloc(n), k = fs.readSync(fd, b, 0, n, pos);
      if (!k) break;
      pos += k; ctx.lus += k;
      let chunk = b.subarray(0, k);
      if (saut) { const i = chunk.indexOf(10); if (i < 0) continue; chunk = chunk.subarray(i + 1); saut = false; }
      const tout = Buffer.concat([pend, chunk]), dernier = tout.lastIndexOf(10);
      pend = dernier < 0 ? tout : tout.subarray(dernier + 1);
      if (dernier >= 0) for (const l of tout.subarray(0, dernier).toString('utf8').split('\n')) {
        lignes++;
        if (!l.includes('"tool_use"') || l.length > LIGNE_MAX) continue;
        let d; try { d = JSON.parse(l); } catch { continue; }
        const [vus, perdu] = plierLigneCibles(st.cibles, d, arbres, defaut, maintenant, cache);
        if (perdu) st.cibles.tronque = true; // garde:cibles-tronque
        if (vus) change = true;
      }
      if (pend.length > LIGNE_MAX) { pend = Buffer.alloc(0); saut = true; }
    }
    const fin = saut ? pos : pos - pend.length;
    st.curseur = fin; // garde:cibles-curseur
    st.saut = saut;
    return { complet: pos >= taille, change };
  }

  return {
    avancer({ voies, fichiers, arbres, maintenant = Date.now(), octets = 8 << 20, ms = 150, horloge = Date.now }) {
      const t0 = horloge(), ctx = { lus: 0, octets, arbres, maintenant, cache: { limites: L, somme, reduits: new Map() } };
      ctx.budget = () => ctx.lus >= octets || horloge() - t0 >= ms; // garde:cibles-tranche
      if (maintenant - purgeA >= 60000 || maintenant < purgeA) { purgeA = maintenant; purger(maintenant - L.fenetreMs); }
      let reste = false;
      for (const v of [...voies].sort((a, b) => (b.fin ?? 0) - (a.fin ?? 0))) {
        const f = fichiers.get(v.id);
        if (!f) continue;
        let st = etats.get(v.id);
        if (!st) { st = neuf(); etats.set(v.id, st); }
        let ls; try { ls = fs.lstatSync(f); } catch { continue; }
        if (!ls.isFile()) continue;
        if (st.complet && st.taille === ls.size && st.mtimeMs === ls.mtimeMs) continue;
        if (ctx.budget()) { reste = true; continue; }
        const o = ouvrir(f);
        if (!o) continue;
        try {
          const tete = teteDe(o.fd, o.st.size);
          if (st.taille >= 0 && (o.st.size < st.curseur || (st.tete !== null && tete !== st.tete))) reinit(st);
          ctx.defaut = arbreDeNom(arbres, v.arbre);
          const r = lire(st, o.fd, o.st.size, ctx);
          st.tete = tete; st.taille = o.st.size; st.mtimeMs = ls.mtimeMs; st.complet = r.complet;
          if (r.change) st.ver++;
          if (r.complet && st.etat !== 'ok') { st.etat = 'ok'; st.ver++; }
          if (!r.complet) reste = true;
        } finally { try { fs.closeSync(o.fd); } catch { /* déjà fermé */ } }
      }
      resteVrai = reste;
      return { reste };
    },
    cibles(id) { // garde:cibles-memoire
      const st = etats.get(id);
      return st ? { etat: st.etat, tronque: st.cibles.tronque, ...listesDeCibles(st.cibles) } : null;
    },
    version: (id) => (etats.has(id) ? etats.get(id).ver : 0),
    reste: () => resteVrai,
    total: () => somme.n,
    oublier(gardes) { for (const [id, st] of etats) if (!gardes.has(id)) { somme.n -= compte(st.cibles); etats.delete(id); } },
  };
}
