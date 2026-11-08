// vf-cockpit-equipe-carte — le graphe de l'onglet Équipe (69-05, P69-D-17), au format du viewer.
// Export : buildEquipeGraph(who, { nom, racine, logos, git, missions, lancees }) -> graphe vibeflow/cockpit-equipe@1 ; missionsEnCours(gp) -> libellés des missions actives (78-04).
// `lancees` (optionnel) : Map session -> { phase, ws, verbe } produite par le registre de vf-cockpit-lancer-suivi.mjs (72-07) ; elle ajoute
// la ligne « Lancée depuis la carte : … » sur la carte de SESSION concernée, valeurs revalidées. Absente ou invalide : sortie inchangée.
// Titre d'une carte de SESSION (PU-G-162, arbitrage Samuel, AskUserQuestion session principale, 2026-11-06) : `w.titre`, le `custom-title` du transcript (nom donné avec /rename, lu, nettoyé,
// masqué et borné à 80 caractères par la collecte `who`), sinon « Session principale · <branche> ». L'`ai-title` (texte du modèle), le dernier prompt et le premier message ne sont jamais lus ;
// l'identifiant de session passe dans le détail. Amendement de la liste blanche P69-D-19/P69-D-23 pour ce seul champ.
// Module pur (aucun fichier lu, aucun transcript ouvert) ; schéma vibeflow/cockpit-equipe@1 : seuls les champs de la collecte `who`
// (le titre de session et le reste, déjà nettoyés, bornés et masqués par collectWho) entrent dans une carte ; la branche repasse par `retireAffichage`. Les sortes de carte (session, agent, terminés) n'ont
// ni pictogramme ni couleur : le viewer prend son repli. Aucun fichier (`files` vide), aucun lien.
import { LIBELLES_VERBES, entreeLanceeValide } from './vf-cockpit-lancer-suivi.mjs';
import { retireAffichage, nettoieTitre } from './vf-cockpit-lecture.mjs';
const SORTES = new Set(['session', 'subagent']);
const clip = (s, n) => { const t = String(s ?? '').replace(/\s+/g, ' ').trim(); if (t.length <= n) return t; const c = t.charCodeAt(n - 2); return t.slice(0, c >= 0xd800 && c <= 0xdbff ? n - 2 : n - 1) + '…'; }; // jamais une moitié de paire de substitution
// PU-G-165 : un seul état par carte — « en attente » n'a pas de pastille (le pied le dit), il n'est jamais projeté sur « En cours » ; ui/71 (`st`) tient la même table
const ST = { actif: 'active', 'en-attente': undefined, termine: 'done', bloque: 'blocked' };
const GENERIQUE = 'lance une commande'; // l'action de presque tous : elle n'informe pas (même seuil que ui/71)
const ETAT = { actif: 'actif', 'en-attente': 'en attente', termine: 'terminé' };

// 78-04 : libellés des missions en cours (nœuds `mission` d'état `active` du graphe Projet), au plus 10, sans contrôle ni préfixe « Mission »
export function missionsEnCours(gp) {
  const out = [];
  for (const n of Array.isArray(gp?.nodes) ? gp.nodes : []) {
    if (out.length >= 10) break;
    if (n && n.kind === 'mission' && n.st === 'active' && typeof n.label === 'string') {
      // S6 (revue 2026-11-06) : même classe que `nettoie` (A8) — tout caractère de catégorie Cf, pas la seule plage bidi ; parité testée sur les quatre copies (test-cockpit-git-commandes.sh, R4.1)
      const l = clip(n.label.replace(/[\u0000-\u001f\u007f-\u009f\u2028\u2029\p{Cf}]/gu, '').replace(/^Mission\s+/, ''), 120);
      if (l) out.push(l);
    }
  }
  return out;
}

export function buildEquipeGraph(who, { nom = 'Projet', racine, logos, git, missions, lancees } = {}) {
  const travailleurs = (Array.isArray(who?.workers) ? who.workers : []).filter((w) => w && SORTES.has(w.kind) && typeof w.id === 'string');
  const idCarte = (w) => (w.kind === 'session' ? 'se-' : 'ag-') + w.id;
  const parId = new Map(); // identifiant de travailleur -> carte (Map : jamais un objet indexé par une valeur lue sur disque, T-69-09)
  for (const w of travailleurs) if (!parId.has(w.id)) parId.set(w.id, idCarte(w));
  const compte = { actif: 0, enAttente: 0, termine: 0 };
  const nodes = [];
  const termines = new Map(); // carte parente -> nombre d'enfants terminés
  const base = { tags: [], paths: [], packages: [], hosts: [], stats: { files: 0, loc: 0, langs: {}, repos: ['.'] } };

  for (const w of travailleurs) {
    if (w.etat === 'termine') compte.termine++; else if (w.etat === 'en-attente') compte.enAttente++; else compte.actif++;
    const sous = w.kind === 'subagent';
    const parent = sous ? parId.get(w.parent) ?? null : null;
    const fini = w.etat === 'termine';
    if (fini && parent) termines.set(parent, (termines.get(parent) || 0) + 1);
    const branche = retireAffichage(w.branch); // S6 : la branche passe par la même classe d'affichage que le titre (contrôles, Cf, bidi)
    const lignes = [];
    if (w.role) lignes.push(`Rôle : ${w.role}`);
    lignes.push(`État : ${ETAT[w.etat] || 'actif'}`);
    if (!sous) lignes.push(`Identifiant : ${w.id.slice(0, 8)}`);
    const l = lancees instanceof Map && w.kind === 'session' ? lancees.get(w.id) : undefined; // garde:lancees
    const t = l && entreeLanceeValide(l) ? `Lancée depuis la carte : Phase ${l.phase}${l.ws ? ` · ${l.ws}` : ''} · ${LIBELLES_VERBES[l.verbe]}` : ''; // garde:ligne-valide
    if (t) lignes.push(t); // garde:ligne-insert
    if (branche) lignes.push(`Branche : ${branche}`);
    if (w.tree) lignes.push(`Arbre : ${w.tree}`);
    if (w.rattachement?.etat === 'rattache') lignes.push(`Nœud de mission : ${w.rattachement.noeud} (${w.rattachement.dag})`);
    // PU-G-134/163/164 : la description d'une carte n'est plus vide — étiquette de lancement, tâche (à défaut la dernière action si elle informe), puis branche et arbre d'une session
    const a = w.action || {}, act = a.verbe && a.verbe !== GENERIQUE ? [a.verbe, a.cible].filter((x) => typeof x === 'string' && x).join(' ') : '';
    const arbre = !sous && w.tree ? (w.tree === 'arbre principal' ? w.tree : `arbre ${String(w.tree).replace(/^\.claude\/worktrees\//, '')}`) : '';
    const lieu = !sous ? [branche ? `Branche ${branche}` : '', arbre].filter(Boolean).join(' · ') : '';
    // PU-G-163 (recette du 2026-11-08) : un agent ou une session sans rien à dire ne montre plus « Pas encore de description » — le repli dit ce qui est connu (nature, état)
    const resume = [t ? `Depuis Phase ${l.phase}` : '', w.task || act, lieu].filter(Boolean).join(' · ') || `${sous ? 'Agent sans tâche annoncée' : 'Session sans tâche annoncée'} · ${ETAT[w.etat] || 'actif'}`;
    nodes.push({ ...base, id: idCarte(w), parent: fini && parent ? `${parent}~termines` : parent, kind: sous ? 'agent' : 'session',
      label: sous ? clip([w.role, w.task].filter(Boolean).join(' · ') || 'Agent', 80) : clip(typeof w.titre === 'string' && w.titre.trim() ? w.titre : ['Session principale', nettoieTitre(branche)].filter(Boolean).join(' · '), 80),
      summary: clip(resume, 200), details: lignes.join('\n\n'), st: Object.hasOwn(ST, w.etat) ? ST[w.etat] : 'active', foot: '' });
  }
  for (const [carte, n] of termines) {
    nodes.push({ ...base, id: `${carte}~termines`, parent: carte, kind: 'terminés', label: `Terminés depuis moins de 24 h (${n})`, summary: `${n} agent${n > 1 ? 's' : ''} de cette session, terminé${n > 1 ? 's' : ''} depuis moins de 24 h.`, details: '', st: 'done', foot: '' });
  }
  const etatSource = (s) => ({ etat: s?.etat === 'lue' || s?.etat === 'absente' || s?.etat === 'erreur' || s?.etat === 'forme-inconnue' ? s.etat : 'absente' });
  const sources = {};
  for (const k of Object.keys(who?.sources || {})) sources[k] = etatSource(who.sources[k]);
  return {
    schema: 'vibeflow/cockpit-equipe@1',
    meta: { generatedAt: new Date().toISOString(), rootName: nom, root: racine, vfLogos: logos, audience: 'everyone', agent: 'claude', repos: [], counts: { files: 0, loc: 0 }, vfTab: 'equipe',
      kindLabels: { import: 'Dépend de', event: 'Enchaînement', data: 'Couvre', queue: 'Étape suivante', call: 'Dispatche', contains: 'Contient' },
      vf: { compte, fenetre: who?.fenetre ?? null, sources, missions: Array.isArray(missions) ? missions : [] }, ...(git ? { vfGit: git } : {}) },
    project: { name: `${nom} — Équipe`, summary: `${compte.actif} actifs · ${compte.enAttente} en attente · ${compte.termine} terminés depuis moins de 24 h.` },
    nodes, files: [], links: [], flows: [], routes: [], tour: [],
  };
}
