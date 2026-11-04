#!/usr/bin/env node
// vf-cockpit-arbres — arbres git du lab, branche de base, retard sans réseau, phase active (socle du cockpit, VFSG-05 ; P68-D-04). Lecture seule.
// Exports : GIT_SUR (préfixe d'arguments de chaque appel git), arbresGit(root, { sh }) -> [{ chemin, branche, principal }],
//           brancheBase(root, { sh }) -> nom | null, retard({ chemin, base, commonDir, now, sh }) -> { base, main, origin, fetchAgeS },
//           phaseActive({ phases, branche }) -> { key, n, nom, etat } | null, nettoie(s, n) -> chaîne sans caractère de contrôle, masquée, bornée
// Aucune sous-commande réseau (ni fetch, pull, ls-remote, remote) ; git sans fsmonitor ; sous-commandes qui ne lisent ni l'index ni l'arbre de travail ;
// chaînes d'arbre et de branche nettoyées avant d'être affichées. Un retard inconnu est `null`, jamais 0.
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { masque } from './vf-cockpit-lecture.mjs';

// un `.git/config` écrit par d'autres peut déclarer un core.fsmonitor exécutable : chaque appel le neutralise (T-68-04)
export const GIT_SUR = ['-c', 'core.fsmonitor=false'];
const shDefaut = (cmd, args, cwd) => { try { return execFileSync(cmd, args, { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'], timeout: 10000 }); } catch (e) { return e.stdout || ''; } }; // timeout : un git bloqué ne gèle pas la boucle
const git = (sh, dir, ...args) => sh('git', [...GIT_SUR, '-C', dir, ...args], dir);
const existe = (sh, dir, ref) => git(sh, dir, 'show-ref', '--verify', ref).trim() !== ''; // show-ref --verify imprime « sha ref » si la référence existe, rien sinon
const entier = (s) => (/^\d+$/.test(String(s).trim()) ? Number(String(s).trim()) : null);

// branche de base : cible de refs/remotes/origin/HEAD privée de `origin/`, sinon `main` local s'il existe, sinon null (P68-PL-05)
export function brancheBase(root, { sh = shDefaut } = {}) {
  const t = git(sh, root, 'symbolic-ref', '--quiet', '--short', 'refs/remotes/origin/HEAD').trim();
  if (t.startsWith('origin/') && t.length > 7) return t.slice(7);
  return existe(sh, root, 'refs/heads/main') ? 'main' : null;
}

// retard d'un arbre sur la base locale et sur origin/<base> LOCAL (lu, jamais rafraîchi), âge du dernier fetch (date de FETCH_HEAD du dossier git commun)
export function retard({ chemin, base, commonDir, now = Date.now(), sh = shDefaut } = {}) {
  const compte = (ref) => entier(git(sh, chemin, 'rev-list', '--count', `HEAD..${ref}`));
  const main = base ? compte(base) : null;
  const origin = base && existe(sh, chemin, `refs/remotes/origin/${base}`) ? compte(`origin/${base}`) : null;
  let fetchAgeS = null;
  if (commonDir) { try { fetchAgeS = Math.max(0, Math.floor((now - fs.statSync(path.join(commonDir, 'FETCH_HEAD')).mtimeMs) / 1000)); } catch {} }
  return { base: base ?? null, main, origin, fetchAgeS };
}

// toute chaîne d'arbre ou de branche qui sort du socle : contrôles retirés (C0, DEL, C1), masque des secrets, borne à n caractères
export const nettoie = (s, n = 200) => masque(String(s ?? '').replace(/[\u0000-\u001f\u007f-\u009f]/g, '')).slice(0, n);
