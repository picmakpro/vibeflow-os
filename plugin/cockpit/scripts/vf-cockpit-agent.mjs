// vf-cockpit-agent — confinement et modèle de l'agent `claude -p` du cockpit (67-05, P67-D-15, P67-D-08 ; 79-06, P79-D-09, SOCL-09).
// Source du confinement : 79-MESURE-claude-p.md, dossier de la phase 79 sous .planning/ (le compartiment qui la porte n'est pas nommé ici)
// (2026-11-12, Claude Code 2.1.322, macOS, verdict CONFINABLE). ARGS_CONFINEMENT recopie sa « Combinaison retenue » telle quelle,
// élément par élément et dans l'ordre : aucun argument ajouté de mémoire. Les deux règles Bash portent le gabarit `<module>` (racine du
// module : voir vf-cockpit-module.mjs) à la place d'un chemin du poste ; argsAgent le remplace au lancement. Pourquoi chaque pièce (mesuré) :
//   - mode explicite `dontAsk` : un `bypassPermissions` de l'utilisateur défait toute liste sans mode explicite ;
//   - `Read/Grep/Glob(./**)` : les noms nus laissent lire hors de la racine du lab ;
//   - Bash limité aux deux scripts de requête DU MODULE (jamais un script de la sortie du lab, qui est inscriptible) : tout autre Bash,
//     composé compris, est refusé ; règle et commande portent le même chemin textuel ;
//   - `--setting-sources ""` (mesuré le 2026-11-01, correction 67-FIX-A, confirmé le 2026-11-12) : ni les hooks du lab, ni ceux de
//     l'utilisateur, ni aucune règle `permissions.allow` des réglages (utilisateur compris) ne sont chargés ; `--strict-mcp-config` : aucun
//     serveur MCP hors configuration explicite.
// Exports : MODELES, MODELE_DEFAUT, ARGS_CONFINEMENT, resoudreModele({ choix, env }), argsAgent(argsAmont, { modele, dossierModule }).
import { substituerModule } from './vf-cockpit-module.mjs';
export const MODELES = ['sonnet', 'opus', 'haiku'];
export const MODELE_DEFAUT = 'sonnet';

export const ARGS_CONFINEMENT = [
  '--permission-mode', 'dontAsk',
  '--tools', 'Read,Grep,Glob,Bash',
  '--allowedTools',
  'Bash(node <module>/scripts/vf-cockpit-query.mjs:*)', 'Bash(node <module>/skills/cockpit-moteur/assets/query-cli.mjs:*)',
  'Read(./**)', 'Grep(./**)', 'Glob(./**)',
  '--setting-sources', '',
  '--strict-mcp-config',
];

// Préséance : sélecteur (corps de la requête) > variable VF_COCKPIT_MODEL > sonnet. Le choix du sélecteur vient du navigateur :
// hors liste fermée il est refusé (jamais lancé) ; la variable hors liste est ignorée avec un avertissement.
export function resoudreModele({ choix, env = process.env } = {}) {
  if (choix !== undefined && choix !== null && choix !== '') {
    return typeof choix === 'string' && MODELES.includes(choix) ? { modele: choix, source: 'selecteur' } : { erreur: 'modele-refuse' };
  }
  const v = env.VF_COCKPIT_MODEL;
  if (v) {
    if (MODELES.includes(v)) return { modele: v, source: 'variable' };
    return { modele: MODELE_DEFAUT, source: 'defaut', avertissement: `VF_COCKPIT_MODEL=${String(v).slice(0, 40)} hors liste (${MODELES.join(', ')}) : ignorée, modèle ${MODELE_DEFAUT}` };
  }
  return { modele: MODELE_DEFAUT, source: 'defaut' };
}

// arguments de sortie et de schéma de l'amont conservés ; tout ce qui touche aux outils, aux permissions et au modèle est
// retiré puis remplacé par ARGS_CONFINEMENT et `--model`. Un drapeau à valeur garde sa valeur telle quelle, même si elle commence par `--`.
const A_VALEUR = new Set(['--output-format', '--json-schema', '--append-system-prompt', '--resume']);
const REMPLACES = new Set(['--tools', '--permission-mode', '--model']);
// `dossierModule` : racine réelle du module ; absent, relatif ou hors de l'alphabet mesuré : exception (message en français), l'argv n'est pas produit
export function argsAgent(argsAmont, { modele = MODELE_DEFAUT, dossierModule } = {}) {
  const out = [];
  for (let i = 0; i < argsAmont.length; i++) {
    const t = argsAmont[i];
    if (REMPLACES.has(t)) { i++; continue; }
    if (t === '--allowedTools') { while (i + 1 < argsAmont.length && !argsAmont[i + 1].startsWith('--')) i++; continue; }
    if (A_VALEUR.has(t)) { out.push(t, argsAmont[++i]); continue; }
    out.push(t);
  }
  return [...out, ...ARGS_CONFINEMENT.map((e) => substituerModule(e, dossierModule)), '--model', modele];
}
