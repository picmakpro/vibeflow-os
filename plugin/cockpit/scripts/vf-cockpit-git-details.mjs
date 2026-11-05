// vf-cockpit-git-details — détail d'un commit sans diff et état des worktrees, À LA DEMANDE (78-08 ; GITC-07, 08, 09 ; P78-D-06, D-13, D-14, D-21, D-23). LECTURE SEULE.
// Exports : detailCommit(lab, sha) -> { code, corps } · etatWorktrees(lab) -> corps · lireNumstat(sortie, { max }) · lireStatusV2(sortie, { max }) · BORNES_DETAILS
//   GET /api/vf/git/commit?sha=<40 hexa>  vibeflow/cockpit-git-commit@1   (le sha est la seule donnée de la page qui entre dans une ligne de commande git)
//   GET /api/vf/git/worktrees             vibeflow/cockpit-git-worktrees@1 (jamais dans le filet de 5 s : le status touche l'arbre de travail)
// Seul point de lancement : lancerGit (environnement durci, --no-ext-diff --no-textconv, filtres du dépôt vidés pour status). Ni diff, ni e-mail, ni écriture.
import path from 'node:path';
import { lancerGit, filtresDeclares, avecEcheance } from './vf-cockpit-paths.mjs';
import { nettoie, brancheBase } from './vf-cockpit-arbres.mjs';
import { masque } from './vf-cockpit-lecture.mjs';
import { MOTIF_SHA, lireWorktrees } from './vf-cockpit-git-graphe.mjs';
import { cmdCd, cmdShowStat, cmdDetacher } from './vf-cockpit-git-commandes.mjs';

export const BORNES_DETAILS = { fichiers: 500, message: 8192, statut: 200, worktrees: 50, echeanceMs: 8000 };
const SCHEMA_COMMIT = 'vibeflow/cockpit-git-commit@1', SCHEMA_WT = 'vibeflow/cockpit-git-worktrees@1';
export const MENTION_APPROX = 'approximatif : filtres du dépôt non exécutés';
const MOTIF = (n) => new RegExp(`^[0-9a-f]{${n}}$`); // SHA-MOTIF : 40 (sha1) ou 64 (sha256), minuscules, rien d'autre
const net = (s) => nettoie(s, 200);
const ILLISIBLE = /[\u0000-\u0008\u000b-\u001f\u007f-\u009f\u2028\u2029\u202a-\u202e\u2066-\u2069]/g; // la classe de `nettoie`, moins la fin de ligne : un message en garde
const ko = (raison) => ({ ok: false, raison });
const motifLong = (s) => /^[0-9a-f]{40}$|^[0-9a-f]{64}$/.test(s);

// `diff-tree -r -z --numstat -M` : `plus\tmoins\tchemin\0` ; binaire `-\t-\tchemin\0` ; renommage `plus\tmoins\t\0ancien\0nouveau\0`
export function lireNumstat(sortie, { max = BORNES_DETAILS.fichiers } = {}) {
  if (typeof sortie !== 'string') return ko('sortie absente');
  const j = sortie.split('\0');
  if (j.pop() !== '') return ko('sortie coupée');
  const fichiers = []; let total = 0;
  for (let i = 0; i < j.length;) {
    const m = /^(-|\d+)\t(-|\d+)\t([^]*)$/.exec(j[i]);
    if (!m) return ko('entrée mal formée');
    const renomme = m[3] === '';
    if (renomme && i + 2 >= j.length) return ko('renommage coupé');
    const binaire = m[1] === '-' || m[2] === '-';
    total++;
    if (fichiers.length < max) fichiers.push({ chemin: net(renomme ? j[i + 2] : m[3]), ancien: renomme ? net(j[i + 1]) : null, plus: binaire ? null : Number(m[1]), moins: binaire ? null : Number(m[2]), binaire });
    i += renomme ? 3 : 1;
  }
  return { ok: true, fichiers, total };
}

// `status --porcelain=v2 --branch -z -unormal` : en-têtes `# …`, `1`/`2` (modifié ; `2` suivi du chemin d'origine), `u` (conflit), `?` (non suivi), `!` (ignoré, jamais demandé) ; au plus `max` entrées comptées
export function lireStatusV2(sortie, { max = BORNES_DETAILS.statut } = {}) {
  if (typeof sortie !== 'string') return ko('sortie absente');
  const j = sortie.split('\0'), coupee = j.pop() !== ''; // dernier jeton non terminé : sortie tronquée, il est écarté
  const r = { ok: true, modifies: 0, nonSuivis: 0, conflits: 0, plus: coupee, oid: null, tete: null };
  for (let i = 0; i < j.length; i++) {
    const t = j[i];
    if (t.startsWith('# ')) { const m = /^# branch\.(oid|head) (.*)$/.exec(t); if (m) r[m[1] === 'oid' ? 'oid' : 'tete'] = m[2]; continue; }
    if (r.modifies + r.nonSuivis + r.conflits >= max) { r.plus = true; break; }
    if (t.startsWith('1 ')) r.modifies++;
    else if (t.startsWith('2 ')) { r.modifies++; i++; }
    else if (t.startsWith('u ')) r.conflits++;
    else if (t.startsWith('? ')) r.nonSuivis++;
    else if (!t.startsWith('! ')) return ko('entrée de status inconnue');
  }
  return r;
}

function tronqueOctets(texte, max) {
  if (Buffer.byteLength(texte) <= max) return { texte, tronque: false };
  return { texte: Buffer.from(texte).subarray(0, max).toString('utf8').replace(/�+$/, ''), tronque: true }; // une coupe au milieu d'un caractère n'en laisse pas de fragment
}

export function detailCommit(lab, sha) {
  const invalide = { code: 400, corps: { schema: SCHEMA_COMMIT, etat: 'sha-invalide' } };
  if (typeof sha !== 'string' || !motifLong(sha)) return invalide; // 1) motif strict, avant tout appel : « HEAD », « v1 », un sha court, « --all » n'atteignent jamais git
  const git = (...a) => lancerGit(lab, a);
  const fmt = git('rev-parse', '--show-object-format');
  if (!fmt.ok) return { code: 200, corps: { schema: SCHEMA_COMMIT, etat: 'indisponible' } };
  if (!MOTIF(fmt.sortie.trim() === 'sha256' ? 64 : 40).test(sha)) return invalide;
  const v = git('rev-parse', '--verify', '--quiet', '--end-of-options', `${sha}^{commit}`); // 2) existence ET identité : un tag, un arbre, un blob ne rendent pas ce sha
  if (v.sortie.trim() !== sha) return { code: 404, corps: { schema: SCHEMA_COMMIT, etat: 'commit-inconnu' } };
  const ko200 = { code: 200, corps: { schema: SCHEMA_COMMIT, etat: 'indisponible' } };
  const lg = git('log', '-1', '-z', '--no-show-signature', '--format=%H%x00%P%x00%an%x00%aI%x00%cn%x00%cI%x00%B', '--end-of-options', sha);
  const c = lg.sortie.split('\0');
  if ((!lg.ok && !lg.tronque) || c.length < 7 || c[0] !== sha) return ko200;
  const p = c[1] === '' ? [] : c[1].split(' ');
  if (!p.every(motifLong)) return ko200;
  const brut = c.slice(6).join('\0').replace(/\0$/, '').replace(/\s+$/, '');
  const m = tronqueOctets(masque(brut.replace(ILLISIBLE, ''), BORNES_DETAILS.message * 2), BORNES_DETAILS.message);
  const dt = git('diff-tree', '-r', '-z', '--numstat', '-M', '--no-commit-id', ...(p.length ? [`${sha}^1`, sha] : ['--root', sha])); // merge : contre le PREMIER parent seulement ; racine : --root
  const ns = dt.ok ? lireNumstat(dt.sortie) : ko('diff-tree');
  if (!ns.ok) return ko200;
  const h7 = sha.slice(0, 7);
  return { code: 200, corps: { schema: SCHEMA_COMMIT, etat: 'ok', h: sha, h7, p, auteur: net(c[2]), date: c[3], committer: net(c[4]), dateCommit: c[5], message: m.texte, tronque: m.tronque || lg.tronque,
    fichiers: ns.fichiers, total: ns.total, commandes: { show: cmdShowStat(h7), detacher: cmdDetacher(h7) } } };
}

const compteLR = (lab, base, oid) => { // [avance, retard] de `oid` sur `base` ; null si inconnu
  const r = lancerGit(lab, ['rev-list', '--left-right', '--count', '--end-of-options', `${base}...${oid}`]);
  const m = /^(\d+)\t(\d+)\n$/.exec(r.sortie);
  return r.ok && m ? [Number(m[2]), Number(m[1])] : null;
};
const sha = (lab, ref) => { const r = lancerGit(lab, ['rev-parse', '--verify', '--quiet', '--end-of-options', `${ref}^{commit}`]); const s = r.sortie.trim(); return r.ok && MOTIF_SHA.test(s) ? s : null; };

export function etatWorktrees(lab) {
  const ind = (etat) => ({ schema: SCHEMA_WT, etat });
  try {
    return avecEcheance(BORNES_DETAILS.echeanceMs, () => {
      const wl = lancerGit(lab, ['worktree', 'list', '--porcelain', '-z']);
      const lw = wl.ok ? lireWorktrees(wl.sortie) : ko('worktree list');
      if (!lw.ok) return ind('indisponible');
      const approximatif = filtresDeclares(lab).length > 0;
      const nomBase = brancheBase(lab);
      const locale = nomBase ? sha(lab, `refs/heads/${nomBase}`) : null, distante = nomBase ? sha(lab, `refs/remotes/origin/${nomBase}`) : null;
      const refBase = locale ? `refs/heads/${nomBase}` : distante ? `refs/remotes/origin/${nomBase}` : null;
      const refOrigine = locale && distante && locale !== distante ? `refs/remotes/origin/${nomBase}` : null; // distante seulement quand elle diverge de la locale
      const worktrees = lw.worktrees.slice(0, BORNES_DETAILS.worktrees).map((w) => {
        const st = lancerGit(w.chemin, ['status', '--porcelain=v2', '--branch', '-z', '-unormal'], { lab, maxBuffer: 1 << 20 });
        const s = st.ok || st.tronque ? lireStatusV2(st.sortie) : ko('status');
        const oid = s.ok && MOTIF_SHA.test(s.oid ?? '') ? s.oid : MOTIF_SHA.test(w.head) ? w.head : null;
        const base = oid && refBase ? compteLR(lab, refBase, oid) : null, orig = oid && refOrigine ? compteLR(lab, refOrigine, oid) : null;
        const cd = cmdCd(w.chemin);
        return { chemin: net(w.chemin), nom: net(path.basename(w.chemin)), modifies: s.ok ? s.modifies + s.conflits : null, nonSuivis: s.ok ? s.nonSuivis : null, plus: s.ok ? s.plus : false,
          propre: s.ok ? s.modifies + s.conflits + s.nonSuivis === 0 : null, avance: base?.[0] ?? null, retard: base?.[1] ?? null, avanceOrigin: orig?.[0] ?? null, retardOrigin: orig?.[1] ?? null,
          commande: cd !== null && masque(w.chemin) === w.chemin ? cd : null }; // P78-D-27 : la commande n'est servie que si l'écran dirait la même chose
      });
      return { schema: SCHEMA_WT, etat: 'ok', approximatif, mention: approximatif ? MENTION_APPROX : null, tronque: lw.worktrees.length > BORNES_DETAILS.worktrees, worktrees };
    });
  } catch { return ind('indisponible'); }
}
