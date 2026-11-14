// vf-cockpit-registre — lecture bornée et revalidée du registre du verrou pour le rattachement des agents CLOS (79-09, D5, P79-D-17).
// Exports : lireRegistre({ chemin, racine, sh }) -> { etat: 'lue' | 'absente' | 'erreur',
//             agents: Map id -> { noeud, role, parent, ws, phase, status, epoch } },
//           fusionnerRegistre(carte, presents, lu) -> carte (ajoute à la carte privée de rattachement les agents clos et présents qui portent un nœud).
// Le verbe est `registry --all` (79-03) : le registre courant ET l'archive de 24 h, un objet par verrou. Une sortie vide est un script d'avant le
// verbe (`absente`, le rattachement retombe sur les citations du mandat) ; une sortie illisible ou qui n'est pas un objet est `erreur`. Rien
// n'est jamais levé. Tout est revalidé et reconstruit, jamais recopié : identifiant par `ID_RE`, statut de liste fermée, chaînes nettoyées
// (contrôles retirés, secrets masqués) et bornées, `ws` et `phase` par les grammaires du script de verrou, 5 000 agents au plus ;
// un doublon garde l'entrée `running`, sinon l'`epoch` le plus grand.
import { shBorne } from './vf-cockpit-paths.mjs';
import { ID_RE } from './vf-cockpit-lecture.mjs';
import { nettoie } from './vf-cockpit-arbres.mjs';

export const MAX_AGENTS = 5000;
const STATUTS = new Set(['running', 'done', 'failed', 'stopped']);
const WS_RE = /^[A-Za-z0-9][A-Za-z0-9._-]*$/, PH_RE = /^[0-9]+(\.[0-9]+)*$/;
const objet = (v) => !!v && typeof v === 'object' && !Array.isArray(v);
const texte = (v, n) => (typeof v === 'string' ? nettoie(v, n) : '');
const meilleur = (a, b) => ((a.status === 'running') !== (b.status === 'running') ? a.status === 'running' : a.epoch > b.epoch);

export function lireRegistre({ chemin, racine, sh = shBorne }) {
  const vide = (etat) => ({ etat, agents: new Map() });
  let brut; try { brut = String(sh('bash', [chemin, 'registry', '--all'], racine, racine) ?? ''); } catch { return vide('erreur'); }
  if (!brut.trim()) return vide('absente');
  let j; try { j = JSON.parse(brut); } catch { return vide('erreur'); }
  if (!objet(j) || !(Array.isArray(j.registries) || Array.isArray(j.agents))) return vide('erreur');
  const agents = new Map();
  for (const reg of Array.isArray(j.registries) ? j.registries : [j]) {
    if (!objet(reg) || !Array.isArray(reg.agents)) continue;
    const ws = typeof reg.ws === 'string' && WS_RE.test(reg.ws) && !reg.ws.includes('..') ? reg.ws : '';
    const phase = typeof reg.phase === 'string' && PH_RE.test(reg.phase) ? reg.phase : '';
    for (const a of reg.agents) {
      if (!objet(a) || typeof a.agent_id !== 'string' || !ID_RE.test(a.agent_id) || !STATUTS.has(a.status)) continue;
      const e = { noeud: texte(a.node, 128), role: texte(a.role, 80), parent: texte(a.parent, 128), ws, phase, status: a.status };
      e.epoch = Number.isFinite(a.epoch) ? a.epoch : 0;
      const avant = agents.get(a.agent_id);
      if (avant ? !meilleur(e, avant) : agents.size >= MAX_AGENTS) continue;
      agents.set(a.agent_id, e);
    }
  }
  return { etat: 'lue', agents };
}

// la carte privée de rattachement (`orphans` : agents vivants) reçoit les agents CLOS présents dans la collecte qui portent un nœud ;
// une entrée de `orphans` n'est jamais écrasée
export function fusionnerRegistre(carte, presents, lu) {
  if (lu?.etat !== 'lue') return carte;
  for (const [id, a] of lu.agents) {
    if (presents.has(id) && !carte.has(id) && a.status !== 'running' && a.noeud) carte.set(id, { noeud: a.noeud, role: a.role, ws: a.ws });
  }
  return carte;
}
