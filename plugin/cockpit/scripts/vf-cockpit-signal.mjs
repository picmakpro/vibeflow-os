#!/usr/bin/env node
// vf-cockpit-signal — l'émetteur JSON unique du socle, schéma vibeflow/cockpit-signal@1 (VFSG-03, VFSG-11 ; P68-D-02, P68-D-15). Lecture seule.
// Exports : collectSignal(root, { home, now, scriptsDir }) -> objet signal@1 ; CLI ci-dessous.
// Sources : readPlanning (phases + avancement@2, jalons, missions et leur vie), lireVerrous, arbresGit/brancheBase/retard/phaseActive, collectWho (équipe who@2).
// Sérialise, ne recalcule rien ; aucune lecture réseau ; jamais de clé doing, mandat, messages, outils.
// Toute chaîne de la sortie, quel que soit le champ, traverse `nettoie` (contrôles retirés, secrets masqués) et une borne : bornes serrées par champ connu, puis une passe finale
// (`assainir`) sur l'objet entier, filet de tout champ ajouté plus tard (F-02, ADR-035 : une chaîne issue du disque ou d'un fichier du lab n'est jamais de confiance).
// CLI : node vf-cockpit-signal.mjs <root>   (JSON sur une ligne ; exit 2 sur usage invalide ; aucune option, P68-D-28)
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { planningLayout, gitCommonDir } from './vf-cockpit-paths.mjs';
import { readPlanning } from './vf-cockpit-planning.mjs';
import { LIBELLES_ETAT, LIBELLES_MISSION } from './vf-cockpit-avancement.mjs';
import { lireVerrous } from './vf-cockpit-vie.mjs';
import { arbresGit, brancheBase, retard, phaseActive, nettoie } from './vf-cockpit-arbres.mjs';
import { collectWho } from './vf-cockpit-who.mjs';

export const SCHEMA = 'vibeflow/cockpit-signal@1';
const ETATS_AVEC_NOEUDS = new Set(['running', 'abandonnee', 'inconnu', 'failed']);
const chaine = (v, n) => (typeof v === 'string' ? nettoie(v, n) : null);
export const BORNE_GENERALE = 1024;
// passe finale : chaque chaîne de l'objet (récursif, tableaux compris) est nettoyée et bornée ; les nombres, booléens et null passent tels quels
export const assainir = (v) => (typeof v === 'string' ? nettoie(v, BORNE_GENERALE) : Array.isArray(v) ? v.map(assainir) : v && typeof v === 'object' ? Object.fromEntries(Object.entries(v).map(([k, x]) => [k, assainir(x)])) : v);

const noeud = (n) => ({ id: chaine(n?.id, 128) ?? '', status: chaine(n?.status, 20) ?? '', step: chaine(n?.step, 100) ?? '', stage: chaine(n?.stage, 80) ?? '', deps: (Array.isArray(n?.deps) ? n.deps : []).filter((x) => typeof x === 'string').map((x) => nettoie(x, 128)) });
const verrou = (l) => ({ ...l, ws: chaine(l.ws, 80) ?? '', scope: chaine(l.scope, 40), phase: chaine(l.phase, 40), owner: chaine(l.owner, 80) });
const nomBorne = (p) => (p ? { ...p, nom: chaine(p.nom, 90) } : p);
const meme = (a, b) => { try { return fs.realpathSync(a) === fs.realpathSync(b); } catch { return path.resolve(a) === path.resolve(b); } };

export function collectSignal(root, { home, now = Date.now(), scriptsDir } = {}) {
  root = path.resolve(root);
  const layout = planningLayout(root);
  const verrous = lireVerrous(root, { scriptsDir, home }); // une seule lecture, partagée par tous les arbres
  const P = readPlanning(root, layout, { verrous });
  const phases = [...P.phases.values()].filter((p) => !p.archive);
  const base = brancheBase(root), common = gitCommonDir(root), tous = arbresGit(root);
  const arbres = tous.map((a) => {
    const pl = meme(a.chemin, root) ? P : readPlanning(a.chemin, planningLayout(a.chemin), { verrous }); // le dossier commun des verrous est le même pour tous les arbres
    const actifs = [...pl.phases.values()].filter((p) => !p.archive);
    return {
      label: a.principal ? 'arbre principal' : nettoie(path.relative(tous[0].chemin, a.chemin) || a.chemin, 200), branche: nettoie(a.branche, 80), principal: a.principal, courant: meme(a.chemin, root),
      phaseActive: nomBorne(phaseActive({ phases: actifs, branche: a.branche })), retard: retard({ chemin: a.chemin, base, commonDir: common, now }),
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
    verrous: { etat: verrous.etat, plat: verrous.plat, liste: verrous.liste.map(verrou) },
    arbres,
    equipe: collectWho(root, { home, now, scriptsDir }),
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
