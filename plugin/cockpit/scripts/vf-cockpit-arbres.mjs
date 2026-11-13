#!/usr/bin/env node
// vf-cockpit-arbres — arbres git du lab, branche de base, retard sans réseau, phase active (socle du cockpit, VFSG-05 ; P68-D-04). Lecture seule.
// Exports : GIT_SUR (préfixe d'arguments de chaque appel git), arbresGit(root, { sh }) -> [{ chemin, branche, principal }], arbresGitAsync(root, { fin }) -> Promise de la même liste,
//           brancheBase(root, { sh }) -> nom | null, brancheBaseAsync(root, { fin }) -> Promise<nom | null>, retard({ chemin, base, commonDir, now, sh, lab }) -> { base, main, origin, fetchAgeS },
//           phaseActive({ phases, branche }) -> { key, n, nom, etat } | null, nettoie(s, n) -> chaîne sans caractère de contrôle, masquée, bornée
// Aucune sous-commande réseau (ni fetch, pull, ls-remote, remote) ; git sans fsmonitor ; sous-commandes qui ne lisent ni l'index ni l'arbre de travail ;
// chaînes d'arbre et de branche nettoyées avant d'être affichées. Un retard inconnu est `null`, jamais 0.
import fs from 'node:fs';
import path from 'node:path';
import { masque } from './vf-cockpit-lecture.mjs';
import { normNum } from './vf-cockpit-planning.mjs';
import { GIT_SUR, shBorne, lancerGitAsync } from './vf-cockpit-paths.mjs';
import { worktreeVerifie } from './vf-cockpit-git-details.mjs';

// GIT_SUR (défini dans vf-cockpit-paths.mjs, partagé par toute la chaîne de l'émetteur : F-03) neutralise un core.fsmonitor exécutable du .git/config (T-68-04)
export { GIT_SUR };
const shDefaut = shBorne; // timeout et échéance globale : un git bloqué ne gèle pas la boucle (F-06)
// `lab` : racine du lab, dont aucun dossier ne doit rester dans le PATH de l'enfant (H-1, vf-cockpit-env.mjs) ; par défaut le dossier de travail de la commande
const git = (sh, dir, lab, ...args) => sh('git', [...GIT_SUR, '-C', dir, ...args], dir, lab);
const existe = (sh, dir, lab, ref) => git(sh, dir, lab, 'show-ref', '--verify', ref).trim() !== ''; // show-ref --verify imprime « sha ref » si la référence existe, rien sinon
const entier = (s) => (/^\d+$/.test(String(s).trim()) ? Number(String(s).trim()) : null);

// arbres du lab, dans l'ordre de `git worktree list` : le premier est l'arbre principal ; arbres existants seulement, chemins résolus ; repli [root] si la liste est vide.
// Les chaînes rendues sont brutes (le chemin sert à comparer des cwd) : c'est l'émetteur qui les passe par `nettoie` avant affichage.
export function arbresGit(root, { sh = shDefaut } = {}) {
  root = path.resolve(root);
  const arbres = [];
  // AUDC-B-01 (même contrôle que le tiroir Git, P78-D-38) : un arbre déclaré dont le lien retour n'est pas vérifié n'élargit pas la liste ; sans dossier commun lisible, seul l'arbre principal reste
  let commun; // lu à la première entrée non principale seulement (un lab à un seul arbre ne paie aucun appel de plus)
  const dossierCommun = () => { if (commun === undefined) { commun = null; try { const c = git(sh, root, root, 'rev-parse', '--path-format=absolute', '--git-common-dir').trim(); commun = c ? fs.realpathSync(c) : null; } catch {} } return commun; };
  for (const b of git(sh, root, root, 'worktree', 'list', '--porcelain').split('\n\n')) {
    const t = /^worktree (.*)$/m.exec(b)?.[1];
    if (!t || !fs.existsSync(t)) continue;
    if (arbres.length > 0 && !(dossierCommun() && worktreeVerifie(commun, t))) continue;
    const branche = /^branch refs\/heads\/(.*)$/m.exec(b)?.[1] || (b.includes('detached') ? '(détachée)' : '');
    arbres.push({ chemin: fs.realpathSync(t), branche, principal: arbres.length === 0 });
  }
  return arbres.length ? arbres : [{ chemin: root, branche: '', principal: true }];
}

// Variante ASYNCHRONE d'arbresGit (constat d'audit 73-02, même raison que P78-D-41) : mêmes lectures, mêmes contrôles de lien retour, par `lancerGitAsync` ;
// la boucle du serveur reste libre pendant que git travaille. Git muet ou en échec : la liste se réduit à l'arbre principal [root], jamais une liste inventée.
export async function arbresGitAsync(root, { fin } = {}) {
  root = path.resolve(root);
  const arbres = [];
  let commun; // lu à la première entrée non principale seulement
  const dossierCommun = async () => { if (commun === undefined) { commun = null; try { const c = (await lancerGitAsync(root, ['rev-parse', '--path-format=absolute', '--git-common-dir'], { fin })).sortie.trim(); commun = c ? fs.realpathSync(c) : null; } catch {} } return commun; };
  for (const b of (await lancerGitAsync(root, ['worktree', 'list', '--porcelain'], { fin })).sortie.split('\n\n')) {
    const t = /^worktree (.*)$/m.exec(b)?.[1];
    if (!t || !fs.existsSync(t)) continue;
    if (arbres.length > 0 && !(await dossierCommun() && worktreeVerifie(commun, t))) continue;
    const branche = /^branch refs\/heads\/(.*)$/m.exec(b)?.[1] || (b.includes('detached') ? '(détachée)' : '');
    arbres.push({ chemin: fs.realpathSync(t), branche, principal: arbres.length === 0 });
  }
  return arbres.length ? arbres : [{ chemin: root, branche: '', principal: true }];
}

// branche de base : cible de refs/remotes/origin/HEAD privée de `origin/`, sinon `main` local s'il existe, sinon null (P68-PL-05)
export function brancheBase(root, { sh = shDefaut } = {}) {
  const t = git(sh, root, root, 'symbolic-ref', '--quiet', '--short', 'refs/remotes/origin/HEAD').trim();
  if (t.startsWith('origin/') && t.length > 7) return t.slice(7);
  return existe(sh, root, root, 'refs/heads/main') ? 'main' : null;
}

// Variante ASYNCHRONE (P78-D-41) : mêmes deux lectures, par `lancerGitAsync` (la boucle du serveur reste libre), échéance `fin` de l'appelant ; sortie vide si git ne répond pas (null, jamais une base inventée).
export async function brancheBaseAsync(root, { fin } = {}) {
  const r = path.resolve(root);
  const t = (await lancerGitAsync(r, ['symbolic-ref', '--quiet', '--short', 'refs/remotes/origin/HEAD'], { fin })).sortie.trim();
  if (t.startsWith('origin/') && t.length > 7) return t.slice(7);
  return (await lancerGitAsync(r, ['show-ref', '--verify', 'refs/heads/main'], { fin })).sortie.trim() !== '' ? 'main' : null;
}

// retard d'un arbre sur la base locale et sur origin/<base> LOCAL (lu, jamais rafraîchi), âge du dernier fetch (date de FETCH_HEAD du dossier git commun)
export function retard({ chemin, base, commonDir, now = Date.now(), sh = shDefaut, lab = chemin } = {}) {
  const compte = (ref) => entier(git(sh, chemin, lab, 'rev-list', '--count', `HEAD..${ref}`, '--'));
  const main = base ? compte(base) : null;
  const origin = base && existe(sh, chemin, lab, `refs/remotes/origin/${base}`) ? compte(`origin/${base}`) : null;
  let fetchAgeS = null;
  if (commonDir) { try { fetchAgeS = Math.max(0, Math.floor((now - fs.statSync(path.join(commonDir, 'FETCH_HEAD')).mtimeMs) / 1000)); } catch {} }
  return { base: base ?? null, main, origin, fetchAgeS };
}

// toute chaîne d'arbre ou de branche qui sort du socle : contrôles retirés (C0, DEL, C1), masque des secrets, borne à n caractères
// A8 : tout caractère de catégorie Unicode Cf (format : bidi U+202A-202E et U+2066-2069, espaces de largeur nulle U+200B-200F, U+2060, U+FEFF, U+061C…) est retiré, avec les contrôles et U+2028/2029
export const nettoie = (s, n = 200) => masque(String(s ?? '').replace(/[\u0000-\u001f\u007f-\u009f\u2028\u2029\p{Cf}]/gu, '')).slice(0, n);

// phase active d'un arbre (P68-PL-04), fonction pure : (1) la phase dont le numéro suit le motif fixe `phase-<n>` du nom de branche, si elle existe ;
// (2) sinon la dernière phase (ordre de la feuille de route) portant une mission `running` ; (3) sinon la dernière phase `en-cours` ; (4) sinon null.
// Jamais `current_phase` du STATE ni le compartiment actif. Une phase portant le même numéro dans deux compartiments : la première de la feuille de route.
const PHASE_BRANCHE = /phase-(\d+(?:\.\d+)?)/;
export function phaseActive({ phases, branche } = {}) {
  const l = Array.isArray(phases) ? phases : [];
  const dernier = (f) => l.filter(f).at(-1);
  const m = PHASE_BRANCHE.exec(String(branche ?? ''));
  const p = (m && l.find((x) => normNum(x?.n) === normNum(m[1]))) || dernier((x) => x?.avancement?.mission?.etat === 'running') || dernier((x) => x?.avancement?.etat === 'en-cours');
  return p ? { key: p.key, n: p.n, nom: p.name, etat: p.avancement?.etat } : null;
}
