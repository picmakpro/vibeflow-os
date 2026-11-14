#!/usr/bin/env node
// vf-cockpit-git-commandes — commandes à copier du tiroir Git (GITC-10 ; P78-D-07, P78-D-14). Fonctions pures : le module ne lance rien.
// Exports : citer(s) -> s cité pour le shell (seule citation du module), AFFICHAGE_REFUSE (ce que `nettoie` retire de l'affichage),
//           cmdCd, cmdSwitch, cmdDetacher, cmdBranchSupprimer, cmdShowStat, cmdStashShow, cmdCommitInitial, cmdStatus -> chaîne | null
// Un nom, un chemin ou une ref qui répond à AFFICHAGE_REFUSE, vide, de plus de 200 caractères ou non chaîne n'a PAS de commande (null) :
// la commande copiée est toujours celle qui est affichée. Toute ref est précédée de --end-of-options (un nom en « - » n'est jamais une option).
// Formes sondées sur git 2.50 (suite C2) : branch -d, show, switch --detach et switch acceptent --end-of-options.

// la citation : entre guillemets simples ; chaque guillemet simple devient '\'' et chaque barre oblique inverse '\\' (une barre non quotée, lue telle quelle),
// identique sous bash, zsh, sh et fish (sous fish, « \' » et « \\ » sont des échappements DANS les guillemets simples : une barre finale ou doublée y changerait de sens)
export const citer = (s) => "'" + s.replace(/['\\]/g, (c) => "'\\" + c + "'") + "'";

// classe de `nettoie` (vf-cockpit-arbres.mjs) : C0, DEL et C1, U+2028/2029 et tout caractère de catégorie Cf (A8 : bidi, largeur nulle, U+FEFF, U+061C…) ; écrite en échappements, jamais en caractères
export const AFFICHAGE_REFUSE = /[\u0000-\u001f\u007f-\u009f\u2028\u2029\p{Cf}]/u;

const MAX = 200;
const texte = (s) => (typeof s === 'string' && s.length > 0 && s.length <= MAX && !AFFICHAGE_REFUSE.test(s) ? s : null);
const motif = (s, re) => (typeof s === 'string' && re.test(s) ? s : null);
const avec = (fabrique, valeur) => (valeur === null ? null : fabrique(valeur));

export const cmdCd = (chemin) => avec((t) => `cd -- ${citer(t)}`, texte(chemin));
// `git switch` lit « - » (branche précédente) et « @ » (HEAD) comme des raccourcis, même après --end-of-options : ces deux noms n'ont pas de commande
const RACCOURCI = /^[-@]$/;
export const cmdSwitch = (nom) => avec((t) => `git switch --end-of-options ${citer(t)}`, RACCOURCI.test(String(nom)) ? null : texte(nom));
export const cmdDetacher = (sha) => avec((t) => `git switch --detach --end-of-options ${t}`, motif(sha, /^[0-9a-f]{7,64}$/));
export const cmdBranchSupprimer = (nom) => avec((t) => `git branch -d --end-of-options ${citer(t)}`, texte(nom));
export const cmdShowStat = (sha) => avec((t) => `git show --stat --end-of-options ${t}`, motif(sha, /^[0-9a-f]{7,64}$/));
export const cmdStashShow = (ref) => avec((t) => `git stash show --stat ${citer(t)}`, motif(ref, /^stash@\{\d{1,4}\}$/));
export const cmdCommitInitial = () => 'git commit -m "premier commit"';
export const cmdStatus = () => 'git status';
