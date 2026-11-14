// chrome-git-pagination.mjs <chrome> <scenario.js> [args...] : pilote de test-cockpit-git-pagination.sh (80-06).
// Joue le corps asynchrone du scenario avec (s, ARGS, cap) apres avoir pose les crochets VF_PRE ; une ligne JSON.
// cap(nom) : capture PNG de la page dans le dossier GP_CAPTURES (absent : rien n'est ecrit).
import fs from 'node:fs';
import path from 'node:path';
const { executer } = await import(process.env.VF_CS);
const [, , chrome, fichier, ...ARGS] = process.argv;
const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor;
const corps = new AsyncFunction('s', 'ARGS', 'cap', fs.readFileSync(fichier, 'utf8'));
const PRE = process.env.VF_PRE ? fs.readFileSync(process.env.VF_PRE, 'utf8') : '';
await executer(chrome, async (s) => {
  const perms = ['clipboardReadWrite', 'clipboardSanitizedWrite'];
  await s.send('Browser.grantPermissions', { permissions: perms }).catch(() => {});
  if (PRE) await s.send('Page.addScriptToEvaluateOnNewDocument', { source: PRE });
  if (process.env.VF_MEDIA) {
    const features = process.env.VF_MEDIA.split(',').map((x) => { const [name, value] = x.split('='); return { name, value }; });
    await s.send('Emulation.setEmulatedMedia', { features });
  }
  const cap = async (nom) => {
    const d = process.env.GP_CAPTURES;
    if (!d) return null;
    fs.mkdirSync(d, { recursive: true });
    const r = await s.send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(d, nom + '.png'), Buffer.from(r.data, 'base64'));
    return nom;
  };
  return corps(s, ARGS, cap);
}, { csp: true });
