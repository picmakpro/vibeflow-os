// vf-cockpit-git-details — détail d'un commit sans diff et état des worktrees, À LA DEMANDE (78-08 ; GITC-07, 08, 09 ; P78-D-06, D-13, D-14, D-21, D-23). LECTURE SEULE.
// Exports : detailCommit(lab, sha) -> { code, corps } · etatWorktrees(lab) -> corps · lireNumstat(sortie, { max }) · lireStatusV2(sortie, { max }) · BORNES_DETAILS
//   GET /api/vf/git/commit?sha=<40 hexa>  vibeflow/cockpit-git-commit@1   (le sha est la seule donnée de la page qui entre dans une ligne de commande git)
//   GET /api/vf/git/worktrees             vibeflow/cockpit-git-worktrees@1 (jamais dans le filet de 5 s : le status touche l'arbre de travail)
// Seul point de lancement : lancerGitAsync (environnement durci, --no-ext-diff --no-textconv, filtres du dépôt vidés pour status). Ni diff, ni e-mail, ni écriture.
import fs from 'node:fs';
import path from 'node:path';
import { lancerGitAsync, filtresDeclaresAsync, finDans } from './vf-cockpit-paths.mjs';
import { cheminPhysique } from './vf-cockpit-git-sortant.mjs';
import { nettoie, brancheBaseAsync } from './vf-cockpit-arbres.mjs';
import { masque } from './vf-cockpit-lecture.mjs';
import { MOTIF_SHA, lireWorktrees } from './vf-cockpit-git-graphe.mjs';
import { cmdCd, cmdShowStat, cmdDetacher } from './vf-cockpit-git-commandes.mjs';

// renommages : au-delà de `renommages` fichiers, git ne cherche plus de renommage (`-l<n>`, détection exhaustive coûteuse : 10 s sur 120 000 fichiers) et les rend en ajout + suppression ;
// la lecture entière est bornée en temps par `echeanceMs`, la boucle du serveur reste libre (lecture asynchrone). Sortie de diff-tree au plus `octetsNumstat` : au-delà, détail « indisponible ».
export const BORNES_DETAILS = { fichiers: 500, message: 8192, statut: 200, worktrees: 50, echeanceMs: 8000, renommages: 400, octetsNumstat: 16 << 20 };
const SCHEMA_COMMIT = 'vibeflow/cockpit-git-commit@1', SCHEMA_WT = 'vibeflow/cockpit-git-worktrees@1';
export const MENTION_APPROX = 'approximatif : filtres du dépôt non exécutés';
const MOTIF = (n) => new RegExp(`^[0-9a-f]{${n}}$`); // SHA-MOTIF : 40 (sha1) ou 64 (sha256), minuscules, rien d'autre
const net = (s) => nettoie(s, 200);
export const ILLISIBLE = /[\u0000-\u0008\u000b-\u001f\u007f-\u009f\u2028\u2029\p{Cf}]/u; // la classe de `nettoie` (A8 : tout caractère de catégorie Cf), moins la fin de ligne : un message en garde
const ILLISIBLE_G = new RegExp(ILLISIBLE.source, 'gu'); // usage interne : `replace` a besoin de g ; l'export, lui, n'a pas d'état (lastIndex)
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

export async function detailCommit(lab, sha) {
  const invalide = { code: 400, corps: { schema: SCHEMA_COMMIT, etat: 'sha-invalide' } };
  if (typeof sha !== 'string' || !motifLong(sha)) return invalide; // 1) motif strict, avant tout appel : « HEAD », « v1 », un sha court, « --all » n'atteignent jamais git
  const ko200 = { code: 200, corps: { schema: SCHEMA_COMMIT, etat: 'indisponible' } };
  try {
    const fin = finDans(BORNES_DETAILS.echeanceMs); // A4 : lecture asynchrone et bornée en temps ; la boucle du serveur reste libre
    const git = (a, opts = {}) => lancerGitAsync(lab, a, { fin, ...opts });
    const fmt = await git(['rev-parse', '--show-object-format']);
    if (!fmt.ok) return ko200;
    if (!MOTIF(fmt.sortie.trim() === 'sha256' ? 64 : 40).test(sha)) return invalide;
    const v = await git(['rev-parse', '--verify', '--quiet', '--end-of-options', `${sha}^{commit}`]); // 2) existence ET identité : un tag, un arbre, un blob ne rendent pas ce sha (rev-parse --verify ne confond jamais une révision avec un fichier)
    if (v.sortie.trim() !== sha) return v.delai || v.echeance ? ko200 : { code: 404, corps: { schema: SCHEMA_COMMIT, etat: 'commit-inconnu' } };
    const lg = await git(['log', '-1', '-z', '--no-show-signature', '--format=%H%x00%P%x00%an%x00%aI%x00%cn%x00%cI%x00%B', '--end-of-options', sha, '--']); // `--` : la révision n'est jamais prise pour un fichier de l'arbre (A6)
    const c = lg.sortie.split('\0');
    if ((!lg.ok && !lg.tronque) || c.length < 7 || c[0] !== sha) return ko200;
    const p = c[1] === '' ? [] : c[1].split(' ');
    if (!p.every(motifLong)) return ko200;
    const brut = c.slice(6).join('\0').replace(/\0$/, '').replace(/\s+$/, '');
    const m = tronqueOctets(masque(brut.replace(ILLISIBLE_G, ''), BORNES_DETAILS.message * 2), BORNES_DETAILS.message);
    const dt = await git(['diff-tree', '-r', '-z', '--numstat', '-M', `-l${BORNES_DETAILS.renommages}`, '--no-commit-id', ...(p.length ? [`${sha}^1`, sha] : ['--root', sha]), '--'], { maxBuffer: BORNES_DETAILS.octetsNumstat }); // merge : contre le PREMIER parent seulement ; racine : --root
    const ns = dt.ok ? lireNumstat(dt.sortie) : ko('diff-tree');
    if (!ns.ok) return ko200;
    const h7 = sha.slice(0, 7);
    return { code: 200, corps: { schema: SCHEMA_COMMIT, etat: 'ok', h: sha, h7, p, auteur: net(c[2]), date: c[3], committer: net(c[4]), dateCommit: c[5], message: m.texte, tronque: m.tronque || lg.tronque,
      fichiers: ns.fichiers, total: ns.total, commandes: { show: cmdShowStat(h7), detacher: cmdDetacher(h7) } } };
  } catch { return ko200; }
}

const compteLR = async (lab, base, oid, fin) => { // [avance, retard] de `oid` sur `base` ; null si inconnu
  const r = await lancerGitAsync(lab, ['rev-list', '--left-right', '--count', '--end-of-options', `${base}...${oid}`, '--'], { fin });
  const m = /^(\d+)\t(\d+)\n$/.exec(r.sortie);
  return r.ok && m ? [Number(m[2]), Number(m[1])] : null;
};
const sha = async (lab, ref, fin) => { const r = await lancerGitAsync(lab, ['rev-parse', '--verify', '--quiet', '--end-of-options', `${ref}^{commit}`], { fin }); const s = r.sortie.trim(); return r.ok && MOTIF_SHA.test(s) ? s : null; };

// P78-D-38 (A3, audit 2026-11-06) : un worktree n'est lu que si son lien retour est vérifié. `git worktree list` rend le chemin écrit dans `<commun>/worktrees/<id>/gitdir`, fichier qu'un dépôt
// piégé peut forger pour désigner un dossier arbitraire du poste. Vérifié = `<chemin>/.git` est (a) le dépôt principal : un dossier (jamais un lien symbolique) dont le chemin réel est le dossier commun,
// ou (b) un fichier `gitdir: <X>` dont X, résolu, est EXACTEMENT `<commun>/worktrees/<id>` et dont le fichier `gitdir` désigne en retour ce `.git`. Tout le reste : « non vérifié » (lecture seule, fs seul, aucun git).
const joindre = (base, valeur) => (path.isAbsolute(valeur) ? valeur : base + path.sep + valeur); // sans normalisation : le noyau résout
// SOCL-10 : la résolution physique unique (nul = non résolu). Le nom et les lignes qui l'emploient sont gardés : ancres de mutation de
// test-cockpit-git-details.sh (X7).
const reelOuNull = (p) => cheminPhysique(p);
export function worktreeVerifie(communReel, chemin) {
  if (typeof communReel !== 'string' || typeof chemin !== 'string') return false;
  communReel = reelOuNull(communReel); // chaque comparaison porte sur des chemins résolus par le noyau ; un échec = non vérifié
  if (communReel === null) return false;
  if (reelOuNull(chemin) === communReel) return true; // dépôt nu : le dossier commun lui-même
  const dotgit = path.join(chemin, '.git');
  try {
    const st = fs.lstatSync(dotgit);
    if (st.isDirectory()) return reelOuNull(dotgit) === communReel;
    if (!st.isFile() || st.size > 4096) return false;
    const m = /^gitdir: (.+)$/.exec(fs.readFileSync(dotgit, 'utf8').replace(/\r?\n$/, ''));
    if (!m) return false;
    const admin = reelOuNull(joindre(chemin, m[1]));
    if (!admin || path.dirname(admin) !== path.join(communReel, 'worktrees')) return false;
    const retour = fs.readFileSync(path.join(admin, 'gitdir'), 'utf8').replace(/\r?\n$/, '');
    return reelOuNull(retour) === reelOuNull(dotgit) && reelOuNull(dotgit) !== null;
  } catch { return false; }
}

// P78-D-32 : asynchrone — tous les git de la lecture passent par `lancerGitAsync` (même point unique, mêmes options), la boucle du serveur reste libre.
export async function etatWorktrees(lab) {
  const ind = (etat) => ({ schema: SCHEMA_WT, etat });
  try {
    const fin = finDans(BORNES_DETAILS.echeanceMs);
    const wl = await lancerGitAsync(lab, ['worktree', 'list', '--porcelain', '-z'], { fin });
    const lw = wl.ok ? lireWorktrees(wl.sortie) : ko('worktree list');
    if (!lw.ok) return ind('indisponible');
    const cm = await lancerGitAsync(lab, ['rev-parse', '--path-format=absolute', '--git-common-dir'], { fin });
    const commun = cm.ok ? reelOuNull(cm.sortie.trim()) : null;
    if (!commun) return ind('indisponible');
    const approximatif = (await filtresDeclaresAsync(lab, lab, fin)).length > 0;
    const nomBase = await brancheBaseAsync(lab, { fin });
    const locale = nomBase ? await sha(lab, `refs/heads/${nomBase}`, fin) : null, distante = nomBase ? await sha(lab, `refs/remotes/origin/${nomBase}`, fin) : null;
    const refBase = locale ? `refs/heads/${nomBase}` : distante ? `refs/remotes/origin/${nomBase}` : null;
    const refOrigine = locale && distante && locale !== distante ? `refs/remotes/origin/${nomBase}` : null; // distante seulement quand elle diverge de la locale
    const worktrees = [];
    for (const w of lw.worktrees.slice(0, BORNES_DETAILS.worktrees)) {
      if (!worktreeVerifie(commun, w.chemin)) { // P78-D-38 : lien retour non vérifié, ni status, ni compte, ni commande `cd`
        worktrees.push({ chemin: net(w.chemin), nom: net(path.basename(w.chemin)), verifie: false, modifies: null, nonSuivis: null, plus: false, propre: null, avance: null, retard: null, avanceOrigin: null, retardOrigin: null, commande: null });
        continue;
      }
      const st = await lancerGitAsync(w.chemin, ['status', '--porcelain=v2', '--branch', '-z', '-unormal'], { lab, maxBuffer: 1 << 20, fin });
      const s = st.ok || st.tronque ? lireStatusV2(st.sortie) : ko('status');
      const oid = s.ok && MOTIF_SHA.test(s.oid ?? '') ? s.oid : MOTIF_SHA.test(w.head) ? w.head : null;
      const base = oid && refBase ? await compteLR(lab, refBase, oid, fin) : null, orig = oid && refOrigine ? await compteLR(lab, refOrigine, oid, fin) : null;
      const cd = cmdCd(w.chemin);
      worktrees.push({ chemin: net(w.chemin), nom: net(path.basename(w.chemin)), verifie: true, modifies: s.ok ? s.modifies + s.conflits : null, nonSuivis: s.ok ? s.nonSuivis : null, plus: s.ok ? s.plus : false,
        propre: s.ok ? s.modifies + s.conflits + s.nonSuivis === 0 : null, avance: base?.[0] ?? null, retard: base?.[1] ?? null, avanceOrigin: orig?.[0] ?? null, retardOrigin: orig?.[1] ?? null,
        commande: cd !== null && masque(w.chemin) === w.chemin ? cd : null }); // P78-D-27 : la commande n'est servie que si l'écran dirait la même chose
    }
    return { schema: SCHEMA_WT, etat: 'ok', approximatif, mention: approximatif ? MENTION_APPROX : null, tronque: lw.worktrees.length > BORNES_DETAILS.worktrees, worktrees };
  } catch { return ind('indisponible'); }
}
