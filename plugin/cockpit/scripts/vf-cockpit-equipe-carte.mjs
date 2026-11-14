// vf-cockpit-equipe-carte — l'enveloppe de l'onglet Équipe (69-05, P69-D-17), au format du viewer : une COQUILLE sans cartes depuis la Phase 73 (P73-D-03).
// Export : buildEquipeGraph(who, { nom, racine, logos, git, missions }) -> enveloppe vibeflow/cockpit-equipe@1 ; missionsEnCours(gp) -> libellés des missions actives (78-04).
// Les cartes d'agents, de sessions et de « Terminés » ont disparu avec le canevas : `nodes` est vide, la liste des agents se lit dans la régie (ui/72-vf-regie-*.js, depuis `who`).
// Le schéma ne change pas : aucun champ requis retiré, `meta` conservée (vfTab, vf.compte, vf.fenetre, vf.sources, vf.missions, vfGit, kindLabels) ; `meta.vf.compte` est celui de la
// construction (la page ne le lit plus : la régie compte depuis le `who` vivant). La ligne « Lancée depuis la carte » n'est plus portée ici : le serveur la pose sur le `who` du direct (P73-D-21).
// Module pur (aucun fichier lu, aucun transcript ouvert) ; seuls des comptes et des états de source (champs de la collecte `who`, déjà bornés et masqués) entrent dans l'enveloppe.
const SORTES = new Set(['session', 'subagent']);
const clip = (s, n) => { const t = String(s ?? '').replace(/\s+/g, ' ').trim(); if (t.length <= n) return t; const c = t.charCodeAt(n - 2); return t.slice(0, c >= 0xd800 && c <= 0xdbff ? n - 2 : n - 1) + '…'; }; // jamais une moitié de paire de substitution

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

export function buildEquipeGraph(who, { nom = 'Projet', racine, logos, git, missions } = {}) {
  const travailleurs = (Array.isArray(who?.workers) ? who.workers : []).filter((w) => w && SORTES.has(w.kind) && typeof w.id === 'string');
  const compte = { actif: 0, enAttente: 0, auRepos: 0, attend: 0, termine: 0 };
  for (const w of travailleurs) {
    if (w.etat === 'termine') compte.termine++; else if (w.etat === 'en-attente') compte.enAttente++; else if (w.etat === 'au-repos') compte.auRepos++; else if (w.etat === 'attend') compte.attend++; else compte.actif++;
  }
  const etatSource = (s) => ({ etat: s?.etat === 'lue' || s?.etat === 'absente' || s?.etat === 'erreur' || s?.etat === 'forme-inconnue' ? s.etat : 'absente' });
  const sources = {};
  for (const k of Object.keys(who?.sources || {})) sources[k] = etatSource(who.sources[k]);
  return {
    schema: 'vibeflow/cockpit-equipe@1',
    meta: { generatedAt: new Date().toISOString(), rootName: nom, root: racine, vfLogos: logos, audience: 'everyone', agent: 'claude', repos: [], counts: { files: 0, loc: 0 }, vfTab: 'equipe',
      kindLabels: { import: 'Dépend de', event: 'Enchaînement', data: 'Couvre', queue: 'Étape suivante', call: 'Dispatche', contains: 'Contient' },
      vf: { compte, fenetre: who?.fenetre ?? null, sources, missions: Array.isArray(missions) ? missions : [] }, ...(git ? { vfGit: git } : {}) },
    project: { name: `${nom} — Équipe`, summary: `${compte.actif} actifs · ${compte.enAttente} en attente${compte.attend ? ` · ${compte.attend} vous attendent` : ''}${compte.auRepos ? ` · ${compte.auRepos} au repos` : ''} · ${compte.termine} terminés depuis moins de 24 h.` },
    nodes: [], files: [], links: [], flows: [], routes: [], tour: [],
  };
}
