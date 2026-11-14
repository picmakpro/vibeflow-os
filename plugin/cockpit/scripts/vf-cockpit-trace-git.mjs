// vf-cockpit-trace-git — sha de HEAD et commits qui citent une ADR ou une décision préfixée (76-02 ; TRAC-06 ; P76-D-09, D-10). LECTURE SEULE.
// Exports : BORNES_TRACE, teteSha(root, { fin }) -> { sha | null, absent },
//   commitsCitants(root, sha, { fin, max }) -> { commits: [{ h7, jour, sujet, adr, decisions }], tronque, absent }.
// Seul point de lancement de git : lancerGitAsync (vf-cockpit-paths.mjs : environnement durci, GIT_* retirés, filtres vidés, sortie tronquée signalée).
// Référence résolue en sha de 40 caractères, `--end-of-options` puis le sha puis `--`, jamais `--all`.
// Le corps d'un message sert à extraire les identifiants (citations) puis est JETÉ : seuls sha court, jour, sujet nettoyé sont rendus.
// `fin` est reçue de l'appelant (date butoir posée une fois par calcul) : ce module n'en fixe aucune.
// Borne atteinte, délai ou sortie tronquée -> `tronque: true`, jamais une liste donnée pour complète.
import { lancerGitAsync } from './vf-cockpit-paths.mjs';
import { nettoie } from './vf-cockpit-arbres.mjs';
import { citations, PREFIXE } from './vf-cockpit-registres.mjs';

export const BORNES_TRACE = { commits: 2000, echeanceMs: 10000, tampon: 8 << 20, sujet: 200 };
const SHA40 = /^[0-9a-f]{40}$/;
const GREP = `ADR-[0-9]{3}|${PREFIXE}-D-[0-9]+`;

export async function teteSha(root, { fin } = {}) {
  let r;
  const args = ['rev-parse', '--verify', '--end-of-options', 'HEAD'];
  try { r = await lancerGitAsync(root, args, { fin, maxBuffer: 1 << 16 }); } catch { return { sha: null, absent: true }; }
  const sha = String(r.sortie ?? '').trim();
  return r.ok && SHA40.test(sha) ? { sha, absent: false } : { sha: null, absent: true };
}

export async function commitsCitants(root, sha, { fin, max = BORNES_TRACE.commits } = {}) {
  if (!SHA40.test(String(sha))) return { commits: [], tronque: false, absent: true };
  let r;
  const args = ['log', '-E', `--grep=${GREP}`, `--max-count=${max}`, '--format=%H%x00%ad%x00%s%x00%B%x1e', '--date=short', '--end-of-options', sha, '--'];
  try {
    r = await lancerGitAsync(root, args, { fin, maxBuffer: BORNES_TRACE.tampon });
  } catch { return { commits: [], tronque: true, absent: false }; }
  if (r.absent) return { commits: [], tronque: false, absent: true };
  const commits = [];
  for (const rec of String(r.sortie ?? '').split('\x1e')) {
    const [h, jour, sujet, corps = ''] = rec.replace(/^\n/, '').split('\x00');
    if (!SHA40.test(h ?? '')) continue;
    const c = citations(`${sujet}\n${corps}`); // le corps est lu ici, puis jeté : il n'entre dans aucune entrée rendue
    const entree = { h7: h.slice(0, 7), jour: String(jour ?? ''), sujet: nettoie(sujet, BORNES_TRACE.sujet), adr: c.adr, decisions: c.decisions };
    commits.push(entree);
  }
  return { commits, tronque: Boolean(r.tronque || r.delai || !r.ok || commits.length >= max), absent: false };
}
