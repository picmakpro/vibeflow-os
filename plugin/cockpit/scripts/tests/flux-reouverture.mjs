// flux-reouverture.mjs <69-vf-flux.js> — ui/69-vf-flux.js dans le navigateur simulé (flux-monde.mjs) : un onglet élu (ou en repli « page »)
// dont la page rouvre sa source (ce que fait ui/70-vf-live.js, ré-exécuté à chaque changement d'onglet sous la coquille) ne construit pas de second EventSource :
// un seul flux ouvert après trois réouvertures, et le flux d'origine n'est pas abandonné ouvert.
// Sortie : une ligne JSON, code 0 si les deux cas passent, 1 sinon, 2 si l'aide ne s'exécute pas.
import { pathToFileURL } from 'node:url';
const f69 = process.argv[2];
try {
  const { creerMonde } = await import(new URL('./flux-monde.mjs', import.meta.url).href);
  const R = {};
  for (const [nom, opts] of [['elu', {}], ['page', { locks: false }]]) {
    const m = creerMonde(); const t = m.ouvrirOnglet(f69, { jeton: 'jeton-sonde-xxxxxxxx', ...opts }); t.ouvrir(); await m.vide(); await m.vide();
    const role = t.vm.role(); const avant = m.fluxOuverts().length;
    for (let i = 0; i < 3; i++) { t.ouvrir(); await m.vide(); await m.vide(); }
    R[nom] = { role, avant, apres: m.fluxOuverts().length, construits: m.M.flux.length };
    R[nom].ok = R[nom].role === nom && avant === 1 && R[nom].apres === 1 && R[nom].construits === 1;
  }
  console.log(JSON.stringify(R)); process.exit(R.elu.ok && R.page.ok ? 0 : 1);
} catch (e) { console.log(JSON.stringify({ erreur: 'exécution : ' + String(e && e.message).slice(0, 200) })); process.exit(2); }
