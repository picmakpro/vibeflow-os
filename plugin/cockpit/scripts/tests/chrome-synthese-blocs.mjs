#!/usr/bin/env node
// chrome-synthese-blocs.mjs — outils du banc des blocs 2 et 3 de la Synthèse (77-06) ; importe le banc de 77-05 tel quel, ne le modifie pas.
// Outils (chacun a sa sonde positive dans test-cockpit-synthese-blocs.sh) :
//   labBlocs(dossier, variante)   le lab fixture du banc, dont le ROADMAP porte cinq phases DATÉES : variante « normal » ou « sansdate » (une phase close sans date)
//   AMORCE_MQ                     écouteurs vivants des listes de requêtes média : window.__nbMQ()
//   fauxGates(dossier)            écrit check-method-budget.sh et check-instruction-budget.sh (FAUX_METHODE : ok | xss | 64 ; FAUX_DENSITE : ok | tiers | 64 ; FAUX_DELAI en secondes ; vide = gates mixtes)
//   copieBlocs(copie)             retire de la copie du module tout frère 74-vf-synthese-* hors burnup et jauges, y pose le bloc témoin et les faux gates
// CLI : lab <dossier> <variante> (imprime le lab) · copie <copie du module> · scenario <chrome> <port> <nom> (une ligne JSON)
import fs from 'node:fs'; import path from 'node:path';
import { labFixture } from './chrome-synthese.mjs';

const put = (f, t) => { fs.mkdirSync(path.dirname(f), { recursive: true }); fs.writeFileSync(f, t); };
const PHASES = [[1, 'Socle', '2026-11-01', '2026-11-03', 'fait'], [2, 'Suite', '2026-11-01', '2026-11-05', 'fait'], [3, 'Milieu', '2026-11-03', null, 'en-cours'],
  [4, 'Fin', '2026-11-05', null, 'a-faire'], [5, 'Reste', null, null, 'a-faire']];
export function labBlocs(dossier, variante = 'normal') {
  const lab = labFixture(dossier), pl = path.join(lab, '.planning');
  const ligne = ([n, nom, ins, clo, etat]) => `- [${etat === 'fait' ? 'x' : ' '}] **Phase ${n}: ${nom}** - jet (${ins ? `inscrite ${ins}, ` : ''}jalon démo)`
    + (etat === 'fait' && !(variante === 'sansdate' && n === 2) ? ` — complete ${clo}` : '');
  put(path.join(pl, 'ROADMAP.md'), `# Roadmap\n\n## Jalon démo\n\n${PHASES.map(ligne).join('\n')}\n`);
  for (const [n, nom, , , etat] of PHASES) {
    const d = path.join(pl, 'phases', `0${n}-${nom.toLowerCase()}`);
    put(path.join(d, `0${n}-01-PLAN.md`), '<objective>Faire</objective>\n');
    if (etat === 'fait') put(path.join(d, `0${n}-01-SUMMARY.md`), 'ok\n');
  }
  return lab;
}

export const AMORCE_MQ = `(() => { const a = EventTarget.prototype.addEventListener, r = EventTarget.prototype.removeEventListener, L = [];
  EventTarget.prototype.addEventListener = function (t, f, o) { if (this instanceof MediaQueryList) L.push([this, t, f]); return a.call(this, t, f, o); };
  EventTarget.prototype.removeEventListener = function (t, f, o) { if (this instanceof MediaQueryList) { const i = L.findIndex((e) => e[0] === this && e[1] === t && e[2] === f); if (i >= 0) L.splice(i, 1); } return r.call(this, t, f, o); };
  window.__nbMQ = () => L.length; })();`;

const GATE = `#!/usr/bin/env bash
g="$(basename "$0" .sh)"; if [ "$g" = check-method-budget ]; then m="\${FAUX_METHODE:-}"; else m="\${FAUX_DENSITE:-}"; fi
[ -z "\${FAUX_DELAI:-}" ] || sleep "$FAUX_DELAI"
[ "$m" != 64 ] || { echo "usage" >&2; exit 64; }
printf '#vf-budget@1\\t%s\\n' "$g"
if [ "$g" = check-method-budget ]; then
  p=".planning/STATE.md"; [ "$m" != xss ] || p='<img src=x onerror=window.__xss=1>'
  printf 'state\\t%s\\t12\\t40\\tKo\\tOK\\nstate-prose\\t.planning/STATE.md\\t5\\t12\\tlignes\\tOK\\nbacklog-ouverts\\t.planning/BACKLOG.md\\t3\\t50\\tsujets\\tOK\\n' "$p"
  if [ "$m" = ok ] || [ "$m" = xss ]; then printf 'backlog-entree\\t.planning/BACKLOG.md\\t30\\t40\\tlignes\\tOK\\nroadmap\\t.planning/ROADMAP.md\\t30\\t64\\tKo\\tOK\\n'
  else
    printf 'backlog-entree\\tgouvernance/doc/BACKLOG.md\\t45\\t40\\tlignes\\tDEPASSE\\nstate\\tgouvernance/doc/STATE.md\\t21\\t8\\tKo\\tDEPASSE\\nroadmap\\t.planning/ROADMAP.md\\t60\\t64\\tAVERTISSEMENT\\n'
    for i in 1 2 3 4 5 6 7; do printf 'state\\tx/a%s/STATE.md\\t9\\t8\\tKo\\tDEPASSE\\n' "$i"; done
  fi
  printf 'backlog-clos\\t.planning/BACKLOG.md\\t0\\t0\\tsujets\\tOK\\nmemory-index\\tMEMORY.md\\t120\\t200\\tlignes\\tOK\\nworktrees\\t.\\t2\\t3\\tworktrees\\tOK\\n'
else
  if [ "$m" = tiers ]; then printf 'agent\\t-\\t-\\t300\\tlignes\\tNON-APPLICABLE\\nskill\\t-\\t-\\t500\\tlignes\\tNON-APPLICABLE\\nsocle\\t-\\t-\\t2000\\tjetons\\tNON-APPLICABLE\\n'; exit 2; fi
  printf 'agent\\tplugin/x/agents/a.md\\t251\\t300\\tlignes\\tAVERTISSEMENT\\nskill\\tplugin/x/skills/s/SKILL.md\\t100\\t500\\tlignes\\tOK\\n'
  if [ "$m" = ok ] || [ "$m" = xss ]; then printf 'socle\\t.\\t1500\\t2000\\tjetons\\tOK\\n'; else printf 'socle\\t.\\t2610\\t2000\\tjetons\\tDEPASSE\\n'; fi
  printf 'socle-baseline\\t.\\t2610\\t-\\tjetons\\tEGALE\\n'
fi
exit 0
`;
export function fauxGates(scripts) {
  for (const n of ['check-method-budget.sh', 'check-instruction-budget.sh']) put(path.join(scripts, n), GATE);
}
export function copieBlocs(copie) {
  const ui = path.join(copie, 'skills/cockpit-moteur/assets/ui');
  for (const f of fs.readdirSync(ui)) if (/^74-vf-synthese-/.test(f) && !/-(burnup|jauges)\.js$/.test(f)) fs.rmSync(path.join(ui, f));
  fauxGates(path.join(copie, 'scripts'));
}

if (process.argv[1] && path.resolve(process.argv[1]) === path.resolve(new URL(import.meta.url).pathname)) {
  const [, , mode, ...a] = process.argv;
  if (mode === 'lab') console.log(labBlocs(a[0], a[1]));
  else if (mode === 'copie') copieBlocs(a[0]);
  else if (mode === 'scenario') import('./chrome-synthese-blocs-scen.mjs').then(({ jouer }) => jouer(...a));
  else { console.error('usage : lab <dossier> <variante> | copie <copie du module> | scenario <chrome> <port> <nom>'); process.exit(2); }
}
