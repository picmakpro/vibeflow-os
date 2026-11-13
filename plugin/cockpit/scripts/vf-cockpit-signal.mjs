#!/usr/bin/env node
// vf-cockpit-signal — l'émetteur JSON unique du socle, schéma vibeflow/cockpit-signal@1 (VFSG-03, VFSG-11 ; P68-D-02, P68-D-15). Lecture seule.
// Exports : collectSignal(root, { home, now, scriptsDir, echeanceMs, equipe, verrous }) -> objet signal@1 (échéance globale : F-06 ; `equipe` et
//           `verrous` : lectures déjà faites par la collecte du serveur, jamais relues ici) ; projeterVerrous(verrous) -> { etat, plat, liste } en liste
//           blanche (A15) ; assainir ; CLI ci-dessous.
// Sources : readPlanning (phases + avancement@2, jalons, missions et leur vie), lireVerrous, arbresGit/brancheBase/retard/phaseActive, collectWho (équipe who@2).
// Sérialise, ne recalcule rien ; aucune lecture réseau ; jamais de clé doing, mandat, messages, outils.
// Toute chaîne de la sortie, quel que soit le champ, traverse `nettoie` (contrôles retirés, secrets masqués) et une borne : bornes serrées par champ connu, puis une passe finale
// (`assainir`) sur l'objet entier, filet de tout champ ajouté plus tard (F-02, ADR-035 : une chaîne issue du disque ou d'un fichier du lab n'est jamais de confiance).
// CLI : node vf-cockpit-signal.mjs <root>   (JSON sur une ligne ; exit 2 sur usage invalide ; aucune option, P68-D-28)
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { planningLayout, gitCommonDir, avecEcheance } from './vf-cockpit-paths.mjs';
import { readPlanning, lireConfine } from './vf-cockpit-planning.mjs';
import { fusionner } from './vf-cockpit-ailleurs.mjs';
import { LIBELLES_ETAT, LIBELLES_MISSION } from './vf-cockpit-avancement.mjs';
import { lireVerrous, dagDe } from './vf-cockpit-vie.mjs';
import { arbresGit, brancheBase, retard, phaseActive, nettoie } from './vf-cockpit-arbres.mjs';
import { collectWho } from './vf-cockpit-who.mjs';

export const SCHEMA = 'vibeflow/cockpit-signal@1';
const ETATS_AVEC_NOEUDS = new Set(['running', 'abandonnee', 'inconnu', 'failed']);
const chaine = (v, n) => (typeof v === 'string' ? nettoie(v, n) : null);
export const BORNE_GENERALE = 1024;
// passe finale : chaque chaîne de l'objet (récursif, tableaux compris) est nettoyée et bornée ; les nombres, booléens et null passent tels quels
export const assainir = (v) => (typeof v === 'string' ? nettoie(v, BORNE_GENERALE) : Array.isArray(v) ? v.map(assainir) : v && typeof v === 'object' ? Object.fromEntries(Object.entries(v).map(([k, x]) => [k, assainir(x)])) : v);

const noeud = (n) => ({ id: chaine(n?.id, 128) ?? '', status: chaine(n?.status, 20) ?? '', step: chaine(n?.step, 100) ?? '', stage: chaine(n?.stage, 80) ?? '', deps: (Array.isArray(n?.deps) ? n.deps : []).filter((x) => typeof x === 'string').map((x) => nettoie(x, 128)) });
const dagP = (d) => { const r = dagDe(d); return r ? { dag: r } : {}; };
const nb = (v) => (typeof v === 'number' && Number.isFinite(v) ? v : null), bool = (v) => (typeof v === 'boolean' ? v : null);
const opt = (k, v) => (v === null ? {} : { [k]: v });
// A15 : l'entrée d'un verrou est construite champ par champ (quatorze clés), jamais recopiée : aucun chemin, aucun emplacement de verrou, aucune liste
// d'identifiants de session. Les cinq derniers sont facultatifs au contrat (`step`, `childrenRunning`, `dag`, `leaseS`, `sansSession`) : absents
// quand la source ne les dit pas.
const verrou = (l) => ({ ws: chaine(l.ws, 80) ?? '', scope: chaine(l.scope, 40), phase: chaine(l.phase, 40), // garde:verrou-liste-blanche
  tenu: l.tenu === true, stale: bool(l.stale), ageS: nb(l.ageS), ttl: nb(l.ttl), progressAgeS: nb(l.progressAgeS), owner: chaine(l.owner, 80),
  ...opt('step', chaine(l.step, 80)), ...opt('childrenRunning', nb(l.childrenRunning)), ...opt('leaseS', nb(l.leaseS)),
  ...dagP(l.dag), // garde:verrou-dag
  ...opt('sansSession', bool(l.sansSession)) });
const ETATS_VERROUS = ['lue', 'absente', 'erreur'];
export const projeterVerrous = (v) => ({
  etat: ETATS_VERROUS.includes(v?.etat) ? v.etat : 'erreur', plat: v?.plat === true,
  liste: (Array.isArray(v?.liste) ? v.liste : []).filter((l) => l && typeof l === 'object').slice(0, 500).map(verrou),
});
const nomBorne = (p) => (p ? { ...p, nom: chaine(p.nom, 90) } : p);
const meme = (a, b) => { try { return fs.realpathSync(a) === fs.realpathSync(b); } catch { return path.resolve(a) === path.resolve(b); } };

export const ECHEANCE_MS = 15000;
// F-06 : tous les sous-processus (git, driver-lock.sh) partagent UNE échéance globale (15 s par défaut), indépendante du
// nombre d'arbres ; passé ce délai plus rien n'est lancé et ce qui n'est pas calculé vaut null (retard, verrous illisibles -> missions inconnu), jamais 0. La liste des arbres, une seule commande
// avant l'échéance, reste l'ossature de la sortie.
export function collectSignal(root, { home, now = Date.now(), scriptsDir, echeanceMs = ECHEANCE_MS, equipe, verrous } = {}) {
  root = path.resolve(root);
  const tous = arbresGit(root);
  return avecEcheance(echeanceMs, () => construire(root, tous, { home, now, scriptsDir, equipe, verrous }));
}

function construire(root, tous, { home, now, scriptsDir, equipe, verrous: injectes }) {
  const layout = planningLayout(root);
  const verrous = injectes ?? lireVerrous(root, { scriptsDir, home }); // verrous de la racine : ceux de la sortie, et ceux de tous les arbres d'un lab partitionné (F-05)
  const P = readPlanning(root, layout, { verrous });
  const base = brancheBase(root), common = gitCommonDir(root);
  const lus = tous.map((a) => {
    // F-05 : en lab partitionné le dossier des verrous est le dossier git commun, le même pour tous les arbres (lecture unique, partagée) ;
    // en lab plat le verrou est propre à chaque checkout (.planning/DRIVER.lock) : la vie d'une mission d'un arbre se lit sur le verrou de CET arbre (lecture paresseuse, faite par readPlanning à sa racine)
    // N5 : lecture confinée à la racine réelle de l'arbre (lireConfine), sans tags
    const pl = meme(a.chemin, root) ? P : lireConfine(a.chemin, () => readPlanning(a.chemin, planningLayout(a.chemin), { ...(verrous.plat ? { scriptsDir, home } : { verrous }), lab: root, sansTags: true }));
    return { a, pl };
  });
  // les phases de la sortie : celles de l'arbre courant, reprises d'un worktree où elles sont plus avancées (règle de vf-cockpit-ailleurs.mjs) ; les lignes d'arbre, elles, gardent l'état de leur propre arbre
  const phases = [...fusionner(P.phases, lus.filter(({ a }) => !meme(a.chemin, root)).map(({ a, pl }) => ({ chemin: a.chemin, nom: nettoie(path.basename(a.chemin), 80), branche: nettoie(a.branche, 80), pl }))).values()].filter((p) => !p.archive);
  const arbres = lus.map(({ a, pl }) => {
    const actifs = [...pl.phases.values()].filter((p) => !p.archive);
    return {
      label: a.principal ? 'arbre principal' : nettoie(path.relative(tous[0].chemin, a.chemin) || a.chemin, 200), branche: nettoie(a.branche, 80), principal: a.principal, courant: meme(a.chemin, root),
      phaseActive: nomBorne(phaseActive({ phases: actifs, branche: a.branche })), retard: retard({ chemin: a.chemin, base, commonDir: common, now, lab: root }),
    };
  });
  return assainir({
    schema: SCHEMA,
    at: new Date(now).toISOString(),
    root,
    projet: nettoie(P.projectName, 120),
    layout: { forme: layout.forme, actif: chaine(layout.actif, 80) },
    phases: phases.map((p) => ({ key: p.key, n: p.n, ws: chaine(p.ws, 80), nom: nettoie(p.name, 90), fait: p.done, avancement: p.avancement, libelle: LIBELLES_ETAT[p.avancement.etat] })),
    jalons: P.milestones.map((m) => ({ key: nettoie(m.key, 80), icone: nettoie(m.icon, 16), texte: nettoie(m.text, 300), ws: chaine(m.ws, 80), phases: [...m.phases] })),
    missions: P.dags.map((d) => ({
      nom: nettoie(d.name, 80), fichier: nettoie(d.file, 200), phaseKey: d.phaseKey, ws: chaine(d.ws ?? d.wsDeclare, 80), etat: d.etat, libelle: LIBELLES_MISSION[d.etat], vie: d.vie ?? null,
      ...(ETATS_AVEC_NOEUDS.has(d.etat) ? { noeuds: d.nodes.map(noeud) } : {}),
    })),
    verrous: projeterVerrous(verrous),
    arbres,
    equipe: equipe ?? collectWho(root, { home, now, scriptsDir }),
  });
}

if (process.argv[1] && import.meta.url === pathToFileURL(fs.realpathSync(process.argv[1])).href) {
  const args = process.argv.slice(2);
  const usage = (msg) => { console.error(`${msg}\nusage : node vf-cockpit-signal.mjs <racine-du-lab>   (aucune option)`); process.exit(2); };
  if (args.length !== 1 || args[0].startsWith('-')) usage(args.length ? 'argument invalide' : 'racine manquante');
  let ok = false; try { ok = fs.statSync(args[0]).isDirectory(); } catch {}
  if (!ok) usage(`racine introuvable : ${args[0].slice(0, 120)}`);
  console.log(JSON.stringify(collectSignal(args[0])));
}
