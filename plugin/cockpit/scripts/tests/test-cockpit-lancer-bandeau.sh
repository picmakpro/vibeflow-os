#!/usr/bin/env bash
# test-cockpit-lancer-bandeau.sh — bandeau de proposition de la page Q : armement, clic de confiance, mode retenu dans Q, lecture et écriture contre un serveur
# factice du contrat §4, message fixe vers P (LANC-07, LANC-09 ; P72-D-02, D-02bis, D-09, D-13, D-14 ; amendement du 2026-11-05 ; plan 72-08).
#   LB.S  statique (page servie, scripts propres = vue et client) : LB.S1 non-régression (adresse, écouteurs, style, couleurs), LB.S2 table MESSAGES et postMessage,
#         LB.S3 tailles, LB.S4 noms de compartiments et appels interdits
#   LB.V  vue sous Chrome (Q factice dans un cadre sandbox de P factice, appels directs à vfTermVue.proposition) : DOM, pré-vols, armement, clic de confiance,
#         textes hostiles, collage au-dessus, statuts, retrait
#   LB.C  client sans navigateur (doublures Node, minuteur accéléré) : sondage précoce, formes refusées, écriture { id, mode }, mode retenu, aucun octet au PTY,
#         annulation, cas froid (cadre masqué)
#   LB.E  client réel + serveur factice du contrat §4 + faux P sous Chrome (E1 à E7, E9 à E11, puis E8 cadre masqué)
#   LB.F  F1 (focus) : faux P à champ de saisie, frappes abc, fenêtre focalisée puis non focalisée ; SP-1 : clic Lancer, tiroir fermé, le bandeau apparaît dans Q
#   LB.P  le serveur factice écoute un port >= 4600 et différent de 4456
#   M-*   vingt-six mutants, plus six du lot 8 LB3-S, plus huit de la revue du 2026-11-08 (S1, S2, S3, S4, P5), plus quatre du 3e tour (F2, F4, F6b ; le mutant de réserve M-RESERVE-PIED vise désormais F3) (copies des sources, « mutant sans effet » = FAIL)
# Sans Chrome : les sections statiques et les doublures tournent, la suite annonce SUITE SAUTÉE (navigateur) pour V et E.
# Variables : VF_CLIENT_MS (échéance d'une attente navigateur, 20000 par défaut) · VF_LB_PORTS=bas-haut (plage de ports du serveur factice ; sinon ports libres du système).
# Exit 0 si tout passe, 1 sinon.
set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; } # port libre choisi à l'exécution
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
ENG="$SCRIPTS/../skills/cockpit-moteur"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home" "$WORK/run"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
export CHROME_SESSION="$HERE_T/chrome-session.mjs"; export LB_DONNEES="$AUX/donnees.mjs"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0
court() { if [ "${#1}" -gt 300 ]; then printf '%s […] %s' "${1:0:140}" "${1: -140}"; else printf '%s' "$1"; fi; }
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$(court "$3")]"; echo "     obtenu:  [$(court "$2")]"; FAIL=$((FAIL+1)); fi; }
sans_effet() { assert_eq "$1 — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; }

CHROME=""
for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue
  if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
if [ -z "$CHROME" ]; then echo "  ⊘ SUITE SAUTÉE (navigateur) : LB.V et LB.E NON vérifiés, non comptés comme réussis"; fi

# ports : plage VF_LB_PORTS=bas-haut (un port à la fois, sans sous-shell) ou, sans plage, un port libre choisi par le système
PORT_LO=4600; PORT_HI=0; if [ -n "${VF_LB_PORTS:-}" ]; then PORT_LO="${VF_LB_PORTS%-*}"; PORT_HI="${VF_LB_PORTS#*-}"; fi; PORT_NEXT="$PORT_LO"; PORT=0
port() {
  if [ -z "${VF_LB_PORTS:-}" ]; then PORT="$(libre)"; return; fi
  while [ "$PORT_NEXT" -le "$PORT_HI" ]; do
    local p="$PORT_NEXT"; PORT_NEXT=$((PORT_NEXT+1))
    if node -e "const s=require('net').createServer();s.once('error',()=>process.exit(1));s.listen($p,'127.0.0.1',()=>s.close(()=>process.exit(0)))"; then PORT="$p"; return; fi
  done
  PORT=0
}

cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/donnees.mjs" <<'JS'
// donnees.mjs : données communes des sondes (proposition valide, textes attendus mot pour mot)
export const ID_A = 'a1b2c3d4e5f60718293a4b5c6d7e8f90';
export const ID = (n) => ('p' + String(n)).padEnd(32, 'e');
export const ligne = (mode) => `claude --session-id '5b9c2e0a-7d41-4f3a-9c58-0e1d2f3a4b5c' -n 'vf-phase-72-alpha' ${mode ? `--permission-mode '${mode}' ` : ''}'/vf-dev Planifie la Phase 72 du compartiment alpha'`;
export const valide = (id = ID_A, over = {}) => Object.assign({
  etat: 'en-attente', id, verbe: 'planifier', intention: 'Planifie la Phase 72 du compartiment alpha', phase: '72', ws: 'alpha',
  lignes: { default: ligne('default'), acceptEdits: ligne('acceptEdits'), plan: ligne('plan'), herite: ligne('') },
  bloquants: [], avertissements: [], arme_apres_ms: 1500, expire_ms: 100000, duree_ms: 120000,
}, over);
export const NOTE = "Aucun mode n'est imposé : Claude Code suit les réglages de votre poste ou du projet ; un projet ne peut imposer ni « tout autoriser » ni auto (Claude Code 2.1.257 et plus).";
export const MOTIFS = {
  'phase-finie': 'La phase est terminée.', 'terminal-absent': 'Le terminal est indisponible sur ce poste.', 'terminal-arrete': 'Le terminal est arrêté. Relancez /vf-cockpit --terminal.',
  'premier-plan-occupe': 'Un programme occupe déjà le terminal.', 'claude-introuvable': 'La commande claude est introuvable.', 'python3-absent': 'Python 3 est introuvable sur ce poste.',
  'phase-hors-motif': "Le numéro de phase n'est pas lançable.", 'compartiment-hors-motif': "Le nom du compartiment n'est pas lançable.",
  'mission-hors-phase': "Cette mission n'est rattachée à aucune phase : le lancement depuis une carte ne part que d'un numéro de phase. Pour la reprendre, ouvrez une session Claude Code dans le terminal, tapez /vf-dev et nommez la mission.",
  'dependance-non-close': 'Une phase dont celle-ci dépend n\'est pas close (lecture de la prose du ROADMAP, indicative).', 'mission-vivante': 'Une mission vivante travaille déjà sur cette phase.',
  'phase-plus-avancee-ailleurs': "Une version plus récente de ce travail existe à part (autre arbre de travail). Le lancement part du dossier principal, qui n'a pas cette avance : consultez cette version avant de lancer.", 'phase-sans-plan': "Aucun plan à exécuter pour cette phase : cadrez puis planifiez d'abord.", 'lancement-recent': 'Cette cible a déjà été lancée récemment.',
  'travail-non-commite': "Du travail non commité existe dans l'arbre de travail.",
};
export const INCONNU = 'Contrôle non reconnu.';
export const MSG = {
  occupe: 'Le terminal n\'a pas pris la demande (programme au premier plan, autre lancement, autre onglet ou contrôle bloquant). Rien n\'a été écrit ; vérifiez, puis cliquez sur Préparer dans le terminal.', attendre: 'Patientez un instant, puis cliquez de nouveau sur Préparer dans le terminal.',
  'sans-session': 'Aucune session de terminal n\'est ouverte : relancez le shell, puis réessayez.', refus: 'Le lancement a été refusé.', reseau: 'Le terminal ne répond pas.',
};
JS
cat > "$AUX/pagegen.mjs" <<'JS'
// pagegen.mjs <dossier-des-modules> <moteur> <theme> <fichier> : page rendue par le module du dossier (sans serveur)
import { pathToFileURL } from 'node:url'; import fs from 'node:fs';
const [, , sortie, moteur, theme, out] = process.argv;
const m = await import(pathToFileURL(`${sortie}/vf-cockpit-terminal-page.mjs`).href);
m.preparerPage({ engineDir: moteur }); fs.writeFileSync(out, m.pageTerminal({ theme, origineP: 'http://127.0.0.1:4242' }).html);
JS
cat > "$AUX/stat.mjs" <<'JS'
// stat.mjs <page.html> : faits statiques des deux scripts propres (vue = 3e, client = 4e <script>), motifs tolérants
import fs from 'node:fs';
const h = fs.readFileSync(process.argv[2], 'utf8');
const s = [...h.matchAll(/<script>([\s\S]*?)<\/script>/g)].map((m) => m[1]);
const p = s.slice(2).join('\n'), c = s[3] || '';
const n = (re) => (p.match(re) || []).length;
const bloc = (c.match(/const MESSAGES = Object\.freeze\(\{([\s\S]*?)\}\)/) || [, ''])[1];
const cles = [...bloc.matchAll(/([A-Za-z]+)\s*:\s*'/g)].map((m) => m[1]);
const appels = [...c.matchAll(/postMessage\s*\(([^)]*)\)/g)].map((m) => m[1].trim());
console.log(JSON.stringify({
  scripts: s.length, propres: p.length,
  search: n(/location\.search/g), urlsp: n(/URLSearchParams/g), searchp: n(/searchParams/g), href: n(/location\.href/g),
  ecoute: n(/addEventListener\(\s*['"]message['"]|\bonmessage\s*=/g), postmsg: n(/\bpostMessage\s*\(/g), etoile: n(/postMessage\s*\([^)]*['"]\*['"]/g),
  html: n(/\.(innerHTML|outerHTML)\s*=|insertAdjacentHTML/g), confirm: n(/\bconfirm\s*\(/g),
  cles: cles.length, proposition: cles.includes('proposition'), cible: appels.length === 1 && /cfg\.origineP$/.test(appels[0]),
}));
JS
cat > "$AUX/lignes.mjs" <<'JS'
// lignes.mjs <fichier> : faits par fichier (LB.S1 par fichier, LB.S3, LB.S4) — nombres de LIGNES concernées
import fs from 'node:fs';
const l = fs.readFileSync(process.argv[2], 'utf8').split('\n'); if (l[l.length - 1] === '') l.pop();
const n = (re) => l.filter((x) => re.test(x)).length;
console.log(JSON.stringify({
  lignes: l.length, couleur: n(/#[0-9a-fA-F]{3,8}([^0-9a-zA-Z_-]|$)/), style: n(/\.style\b/), css: n(/cssText/), rgb: n(/(rgb|hsl)a?\(/), px: n(/[0-9]px/),
  compartiments: n(/fiabilite|gouvernance/), confirm: n(/\bconfirm\s*\(/),
}));
JS
cat > "$AUX/doubles.mjs" <<'JS'
// doubles.mjs <client.mjs> <scenario> : le client de Q joué sans navigateur (doublures de window, document, Terminal, fetch ; minuteur accéléré de 1/50).
// Scénarios : precoce · formes · suivi · retard · statuts · mode · focus · annuler · froid. Une ligne JSON de faits, ou { erreur } (attente dépassée : le client n'a pas fait ce qui est attendu).
import { pathToFileURL } from 'node:url';
const { ID_A, ID, valide } = await import(pathToFileURL(process.env.LB_DONNEES).href);
const [, , chemin, sc] = process.argv;
const J = { vue: [], msgs: [], journal: [], stockage: [], periodes: [], focus: 0, terms: 0, rejets: 0 };
process.on('unhandledRejection', () => { J.rejets++; });
const att = (ms) => new Promise((ok) => setTimeout(ok, ms));
const souple = async (f, ms) => { const fin = Date.now() + ms; while (!f() && Date.now() < fin) await att(10); return f(); }; // attente qui ne lève pas : l'absence d'effet se mesure, elle ne fait pas planter la sonde
const until = async (f, nom, ms = 3000) => { const fin = Date.now() + ms; for (;;) { if (f()) return; if (Date.now() > fin) throw new Error(`attente de « ${nom} » dépassée`); await att(10); } };
const el = () => ({ addEventListener() {}, setAttribute() {}, querySelector: () => null, classList: { add() {}, remove() {} }, style: {}, textContent: '' });
globalThis.getComputedStyle = () => ({ paddingTop: '0', paddingBottom: '0' });
const memoire = (spy) => { const m = new Map(); return { getItem: (k) => { if (spy) spy('get', k); return m.has(k) ? m.get(k) : null; }, setItem: (k, v) => { if (spy) spy('set', k); m.set(k, String(v)); }, removeItem: (k) => { if (spy) spy('del', k); m.delete(k); }, brut: (k, v) => { m.set(k, v); } }; };
// P72-D-20 : le stockage du navigateur n'est plus la source du mode ; toute opération sur LocalStorage est consignée (op, clé)
globalThis.localStorage = memoire((op, k) => { J.stockage.push([op, k]); }); globalThis.sessionStorage = memoire();
localStorage.brut('vf.terminal.secret', 'a'.repeat(64));
const W = {
  top: {}, opener: null, innerWidth: 800, innerHeight: 600, addEventListener() {}, parent: { postMessage: (m, o) => J.msgs.push({ m, o }) },
  vfTermVue: { theme: () => ({}), carte() {}, effacer() {}, bandeau() {}, collage() {}, invisible: () => false, proposition: (p, cb) => J.vue.push(p === null ? null : { p, cb }) },
};
globalThis.window = W;
globalThis.document = { fonts: { load: () => Promise.resolve(), ready: Promise.resolve() }, getElementById: el, addEventListener() {} };
globalThis.location = { hash: '', pathname: '/', search: '' };
globalThis.history = { replaceState() {} };
globalThis.ResizeObserver = class { observe() {} };
globalThis.requestAnimationFrame = () => 0;
globalThis.FitAddon = { FitAddon: class { fit() {} } };
globalThis.Terminal = class {
  constructor() { J.terms++; this.rows = 24; this.cols = 80; this.parser = { registerDcsHandler() {} }; this.textarea = { addEventListener() {} }; }
  loadAddon() {} open() {} attachCustomKeyEventHandler() {} focus() { J.focus++; } write() {} paste() {} reset() {} resize() {} onData() {} onBinary() {}
};
const realSI = globalThis.setInterval;
globalThis.setInterval = (f, ms, ...a) => { J.periodes.push(ms); return realSI(f, Math.max(5, Math.round(ms / 50)), ...a); };
const AUCUNE = { etat: 'aucune' };
const S = { prop: AUCUNE, propStatut: 200, lancer: 204, hold: false, held: [] };
const rep = (status, corps) => ({ status, ok: status >= 200 && status < 300, json: async () => corps, body: { getReader: () => ({ read: async () => ({ done: true }) }) } });
globalThis.fetch = (u, o = {}) => {
  const url = String(u);
  const b = typeof o.body === 'string' ? o.body : o.body ? Buffer.from(o.body).toString('hex') : '';
  J.journal.push({ m: o.method || 'GET', u: url, h: Object.assign({}, o.headers), b });
  if (url === '/proposition') {
    const r = rep(S.propStatut, JSON.parse(JSON.stringify(S.prop))); // la réponse est figée À LA REQUÊTE : retenue puis rendue, elle porte l'ancienne proposition
    return S.hold ? new Promise((ok) => S.held.push(() => ok(r))) : Promise.resolve(r);
  }
  if (url === '/lancer') return S.lancer === 'throw' ? Promise.reject(new Error('réseau')) : Promise.resolve(rep(S.lancer, null));
  if (url === '/flux') return new Promise(() => {});
  return Promise.resolve(rep(204, null));
};
const m = await import(pathToFileURL(chemin).href);
const demarrer = () => m.clientTerminal({ origineP: 'http://127.0.0.1:1', theme: 'dark' });
const nData = () => J.vue.filter(Boolean).length, nNull = () => J.vue.filter((x) => x === null).length;
const nMsg = () => J.msgs.filter((x) => x.m === 'proposition').length;
const nProp = () => J.journal.filter((r) => r.u === '/proposition').length;
const dernier = () => J.vue.filter(Boolean).slice(-1)[0];
const afficher = async (id, over) => { const n = nData(); S.prop = valide(id, over); await until(() => nData() > n, `affichage de ${id}`); return dernier(); };
const autres = () => J.journal.filter((r) => r.u !== '/proposition' && r.u !== '/flux');

const SCEN = {
  async precoce() { // LB.C1
    S.hold = true; demarrer(); await souple(() => nProp() >= 1, 3000); await att(500);
    const r = J.journal.filter((x) => x.u === '/proposition'), h = (r[0] || { h: {} }).h;
    return { premiere: (J.journal[0] || {}).u, n: r.length, secret: h['X-VF-Terminal'], onglet: /^[0-9a-f]{32}$/.test(h['X-VF-Onglet'] || ''), periode: J.periodes[0], periodes: J.periodes.length };
  },
  async formes() { // LB.C2 : réponses hors forme
    demarrer();
    const base = valide(ID_A), mod = (f) => { const x = JSON.parse(JSON.stringify(base)); f(x); return x; };
    const cas = [['null', null], ['tableau', []], ['sans-champs', { etat: 'en-attente' }], ['id-hostile', mod((x) => { x.id = '../../x"><b>'; })], ['id-court', mod((x) => { x.id = 'abc'; })],
      ['ligne-manquante', mod((x) => { delete x.lignes.plan; })], ['ligne-controle', mod((x) => { x.lignes.default = 'claude\u0007x'; })], ['ligne-401', mod((x) => { x.lignes.herite = 'a'.repeat(401); })],
      ['bloquants-non-tableau', mod((x) => { x.bloquants = 'phase-finie'; })], ['code-41', mod((x) => { x.avertissements = ['a'.repeat(41)]; })],
      ['arme-negatif', mod((x) => { x.arme_apres_ms = -1; })], ['arme-10001', mod((x) => { x.arme_apres_ms = 10001; })], ['expire-nul', mod((x) => { x.expire_ms = 0; })]];
    const f = { cas: [] };
    for (const [nom, corps] of cas) { const n0 = nProp(); S.prop = corps; await until(() => nProp() >= n0 + 3, `sondages (${nom})`); f.cas.push([nom, nProp() - n0, nData(), nNull()].join(':')); }
    f.rejete = cas.length === f.cas.filter((x) => { const [, s, d, nl] = x.split(':'); return Number(s) >= 3 && d === '0' && nl === '0'; }).length;
    const v = await afficher(ID_A); // témoin positif : la réponse valide, elle, s'affiche
    f.valide = { n: nData(), id: v.p.id, modeInitial: typeof v.p.modeInitial, cb: typeof v.cb.lancer + '/' + typeof v.cb.annuler };
    return f;
  },
  async suivi() { // LB.C2 : une fois par identifiant, retrait sur `aucune`, statut non OK sans retrait, un message par identifiant nouveau
    demarrer(); const f = {};
    await afficher(ID_A); await att(150); f.a1 = { n: nData(), msgs: nMsg() };
    await att(150); f.a2 = { n: nData(), msgs: nMsg() };
    await afficher(ID(2)); f.b = { n: nData(), msgs: nMsg() };
    S.prop = AUCUNE; await souple(() => J.vue[J.vue.length - 1] === null, 1500); f.c = { n: nData(), nulls: nNull(), msgs: nMsg() };
    await afficher(ID(3)); const avant = J.vue.length;
    for (const st of [404, 401, 403]) { S.propStatut = st; await att(120); } S.propStatut = 200; f.d = { ajout: J.vue.length - avant };
    S.prop = AUCUNE; await souple(() => J.vue[J.vue.length - 1] === null, 1500); f.e = { nulls: nNull() };
    const m = J.msgs.filter((x) => x.m === 'proposition'); f.msg = { n: m.length, strict: m.every((x) => x.m === 'proposition' && x.o === 'http://127.0.0.1:1'), etoile: J.msgs.some((x) => x.o === '*'), autres: J.msgs.filter((x) => x.m !== 'proposition').map((x) => x.m).join(',') };
    return f;
  },
  async retard() { // LB.C2 : une réponse de sondage en retard ne remonte pas une proposition consommée, annulée ou refusée
    demarrer(); const f = {};
    const cas = async (id, action) => {
      S.hold = false; await afficher(id);
      const avant = { v: J.vue.length, m: nMsg() }, n0 = S.held.length;
      S.hold = true; await until(() => S.held.length > n0, 'sondage retenu');
      const st = await action(dernier().cb);
      S.prop = AUCUNE; S.hold = false; S.held.splice(0).forEach((g) => g()); await att(200);
      return { st, dv: J.vue.length - avant.v, dm: nMsg() - avant.m };
    };
    f.ok = await cas(ID(11), (cb) => { S.lancer = 204; return cb.lancer('default'); });
    f.annule = await cas(ID(12), (cb) => { cb.annuler(); return 'annule'; });
    f.absente = await cas(ID(13), (cb) => { S.lancer = 404; return cb.lancer('default'); });
    const n = nData(); await afficher(ID(14)); f.temoin = nData() - n;
    return f;
  },
  async statuts() { // LB.C3
    demarrer(); const f = { cas: [] };
    const liste = [[204, 'ok'], [409, 'occupe'], [425, 'attendre'], [404, 'absente'], [410, 'sans-session'], [400, 'refus'], [500, 'refus'], ['throw', 'reseau']];
    let k = 20;
    for (const [code, attendu] of liste) {
      const v = await afficher(ID(++k)); const marque = J.journal.length; S.lancer = code;
      const st = await v.cb.lancer('acceptEdits'); const reqs = autres().filter((r) => J.journal.indexOf(r) >= marque);
      if (code === 204 || code === 404) S.prop = AUCUNE;
      f.cas.push({ code, st, attendu, nreq: reqs.length, req: reqs[0] && { m: reqs[0].m, u: reqs[0].u, ct: reqs[0].h['Content-Type'], sec: reqs[0].h['X-VF-Terminal'], ong: /^[0-9a-f]{32}$/.test(reqs[0].h['X-VF-Onglet'] || ''), b: reqs[0].b, id: v.p.id } });
    }
    const v = await afficher(ID(40)); const marque = J.journal.length; S.lancer = 204;
    f.hors = { st: await v.cb.lancer('bypassPermissions'), reqs: autres().filter((r) => J.journal.indexOf(r) >= marque).length };
    return f;
  },
  async mode() { // LB.C4 : la présélection vient de mode_retenu servi (relu contre la liste fermée) ; le client n'écrit ni ne lit AUCUNE clé « mode » (P72-D-20)
    demarrer(); const f = { lu: [] };
    const valeurs = [null, 'bypassPermissions', 'HERITE', 'default ', '__proto__', 'constructor', 'x'.repeat(5000), '', 'default', 'acceptEdits', 'plan', 'herite'];
    let k = 50;
    for (const v of valeurs) { const r = await afficher(ID(++k), v === null ? {} : { mode_retenu: v }); f.lu.push([v === null ? 'absent' : v.length > 20 ? 'long' : v, r.p.modeInitial].join('=>')); }
    S.lancer = 204;
    const r1 = await afficher(ID(70), { mode_retenu: 'plan' }); f.st204 = await r1.cb.lancer('plan'); S.prop = AUCUNE;
    const r2 = await afficher(ID(71), { mode_retenu: 'plan' }); f.suivant = r2.p.modeInitial; f.inchange = [];
    for (const code of [409, 425, 400, 500]) { const r = await afficher(ID(72 + f.inchange.length), { mode_retenu: 'acceptEdits' }); S.lancer = code; await r.cb.lancer('plan'); f.inchange.push(code + ':' + r.p.modeInitial); }
    f.opsMode = J.stockage.filter((x) => /mode/i.test(x[1])).map((x) => x.join(':')); f.secretLu = J.stockage.some((x) => x[0] === 'get' && x[1] === 'vf.terminal.secret');
    return f;
  },
  async focus() { // LB.C5 : aucun octet au PTY après un lancement accepté, le terminal reprend le focus
    demarrer(); const v = await afficher(ID_A); const f0 = J.focus; S.lancer = 204; const st = await v.cb.lancer('default'); S.prop = AUCUNE; await att(1500); await souple(() => J.focus - f0 >= 1, 3000);
    return { st, entrees: J.journal.filter((r) => r.u === '/entree').length, focus: J.focus - f0 };
  },
  async annuler() { // LB.C6
    demarrer(); const v = await afficher(ID_A); const marque = J.journal.length, n = J.vue.length, mm = nMsg(); v.cb.annuler(); await att(400);
    const reqs = autres().filter((r) => J.journal.indexOf(r) >= marque);
    const f = { reqs: reqs.map((r) => r.m + ' ' + r.u + ' ' + r.b), vue: J.vue.length - n, msgs: nMsg() - mm }; // le serveur factice sert encore la même proposition : elle ne revient pas
    const t = nData(); await afficher(ID(2)); f.temoin = nData() - t; return f;
  },
  async froid() { // LB.C7 : cadre masqué, la proposition est annoncée avant visible(), rien d'autre ne démarre
    W.innerWidth = 0; S.prop = valide(ID_A); demarrer();
    await souple(() => nProp() >= 1, 1500); await att(500);
    const f = { masque: { sondage: nProp() >= 1, msgs: nMsg(), data: nData(), terms: J.terms, interdit: J.journal.filter((r) => ['/flux', '/lancer', '/entree'].includes(r.u)).length, origine: J.msgs.filter((x) => x.m === 'proposition').map((x) => x.o).join(',') } };
    W.innerWidth = 800; W.innerHeight = 600;
    await until(() => J.terms === 1 && nData() === 1, 'terminal et bandeau après visible()', 4000); await att(400);
    f.ouvert = { terms: J.terms, data: nData(), msgs: nMsg(), memeId: dernier().p.id === ID_A };
    return f;
  },
};
let f;
try { if (!SCEN[sc]) throw new Error('scénario inconnu ' + sc); f = await SCEN[sc](); f.rejets = J.rejets; } catch (e) { f = { erreur: String(e.message) }; }
console.log(JSON.stringify(f)); process.exit(0);
JS
cat > "$AUX/faux.mjs" <<'JS'
// faux.mjs <dossier-des-modules> <moteur> <portQ> <portP> <secret> <run> : UN processus, deux serveurs de la forme du contrat §4 (aucun code du serveur réel).
// Q factice : GET / (page rendue par le module du dossier), /flux, /etat, /taille, /entree (octets consignés en hexadécimal dans <run>/entree.log), /proposition, /lancer, /annuler,
// avec les contrôles de Q (Host exact, secret 401, Origin exacte pour tout POST 403, GET admis sans Origin si Sec-Fetch-Site vaut same-origin) et l'armement côté serveur (425).
// P factice : page vide à espion de messages ; POST /__scenario { prop, lancers } et GET /__journal (hors de la table fermée de Q).
import http from 'node:http'; import fs from 'node:fs'; import { pathToFileURL } from 'node:url';
const [, , dossier, moteur, portQ, portP, secret, run] = process.argv;
const page = await import(pathToFileURL(`${dossier}/vf-cockpit-terminal-page.mjs`).href);
page.preparerPage({ engineDir: moteur });
const OQ = `http://127.0.0.1:${portQ}`, OP = `http://127.0.0.1:${portP}`;
const journal = [], premiere = {}; let scen = { prop: null, lancers: [] }, finEtat = false; // scen.fin : le premier /flux se termine aussitôt et /etat dit la session terminée (bouton « Relancer le shell »)
const lire = (req) => new Promise((ok) => { const c = []; req.on('data', (d) => c.push(d)); req.on('end', () => ok(Buffer.concat(c))); });
const q = http.createServer(async (req, res) => {
  const chemin = new URL(req.url, OQ).pathname, corps = await lire(req);
  const note = (st, extra) => journal.push(Object.assign({ m: req.method, u: chemin, st, b: corps.toString('utf8').slice(0, 300) }, extra));
  const fin = (st, h, txt) => { note(st); res.writeHead(st, h || {}); res.end(txt); };
  if (req.headers.host !== `127.0.0.1:${portQ}`) return fin(421);
  if (req.method === 'GET' && chemin === '/') {
    const { html, csp } = page.pageTerminal({ theme: new URL(req.url, OQ).searchParams.get('theme'), origineP: OP });
    return fin(200, { 'Content-Type': 'text/html; charset=utf-8', 'Content-Security-Policy': csp, 'Cache-Control': 'no-store' }, html);
  }
  if (req.headers['x-vf-terminal'] !== secret) return fin(401);
  if (req.method === 'POST' && req.headers.origin !== OQ) return fin(403);
  if (req.method === 'GET' && (req.headers.origin ? req.headers.origin !== OQ : req.headers['sec-fetch-site'] !== 'same-origin')) return fin(403);
  const json = (st, o) => fin(st, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' }, JSON.stringify(o));
  if (req.method === 'GET' && chemin === '/etat') return json(200, finEtat ? { etat: 'ok', session: 'terminee', code: 0 } : { etat: 'ok', session: 'vivante' });
  if (req.method === 'GET' && chemin === '/flux') { note(200); res.writeHead(200, { 'Content-Type': 'application/octet-stream', 'Cache-Control': 'no-store' }); if (scen.fin) { scen.fin = false; finEtat = true; return res.end(); } finEtat = false; res.write('$ '); return; }
  if (req.method === 'POST' && chemin === '/taille') return fin(204);
  if (req.method === 'POST' && chemin === '/entree') { fs.appendFileSync(`${run}/entree.log`, corps.toString('hex') + '\n'); return fin(204); }
  if (req.method === 'GET' && chemin === '/proposition') {
    if (!scen.prop) return json(200, { etat: 'aucune' });
    if (!premiere[scen.prop.id]) premiere[scen.prop.id] = Date.now();
    const mr = 'mode_retenu' in scen ? scen.mode_retenu : 'default'; // contrat §4 (72-16) : valeur réglable par scénario (défaut : premier lancement), « __absent__ » = clé omise
    return json(200, mr === '__absent__' ? scen.prop : Object.assign({}, scen.prop, { mode_retenu: mr }));
  }
  if (req.method === 'POST' && chemin === '/lancer') {
    let o = null; try { o = JSON.parse(corps.toString('utf8')); } catch { o = null; }
    if (!o || typeof o.id !== 'string' || typeof o.mode !== 'string') return fin(400);
    if (!scen.prop || scen.prop.id !== o.id) return fin(404);
    if (Date.now() - premiere[o.id] < scen.prop.arme_apres_ms) { note(425, { tot: true }); res.writeHead(425); return res.end(); }
    const st = scen.lancers.length ? scen.lancers.shift() : 204;
    if (st === 204) scen.prop = null;
    return fin(st);
  }
  if (req.method === 'POST' && chemin === '/annuler') { try { if (scen.prop && scen.prop.id === JSON.parse(corps.toString('utf8')).id) scen.prop = null; } catch { /* corps invalide */ } return fin(204); }
  return fin(404);
});
// SP-1 : page Projet factice (tiroir + interface de lancement RÉELS lus dans FAUX_INJ, faux window.VibeFlow, routes du contrat) servie sur /project.html?sp1=1 seulement
let injPage = '';
if (process.env.FAUX_INJ) {
  const t = await import(pathToFileURL(`${process.env.FAUX_INJ}/vf-cockpit-terminal-tiroir.mjs`).href), l = await import(pathToFileURL(`${process.env.FAUX_INJ}/vf-cockpit-lancer-ui.mjs`).href);
  injPage = t.injectionTiroir({}) + l.injectionLancer({});
}
const CIBLES = { actif: true, cibles: [{ id: 'ph-1', kind: 'phase', principal: 'planifier', verbes: ['planifier'], bloquants: [], avertissements: [], lancee: false }] };
const pageSp1 = () => `<!doctype html><title>P factice</title><script>window.VF_COCKPIT_SERVER={token:'t'};window.__msgs=[];addEventListener('message',function(e){window.__msgs.push({o:e.origin,d:String(e.data).slice(0,60)})});window.__secs=[];window.VibeFlow={addPanelSection:function(w,f){window.__secs.push(f)}};</script><div id="panel"></div>${injPage}<script>(function t(){var f=window.__secs[0];if(!f)return void setTimeout(t,50);var r=f('n:ph-1'),z=document.getElementById('panel');z.innerHTML=r.html;r.bind(z)})()</script>`;
const p = http.createServer(async (req, res) => {
  const chemin = new URL(req.url, OP).pathname;
  if (req.method === 'GET' && chemin === '/api/vf/terminal') { res.writeHead(200, { 'Content-Type': 'application/json' }); return res.end(JSON.stringify({ etat: 'actif', port: Number(portQ) })); }
  if (req.method === 'GET' && chemin === '/api/vf/lancer/cibles') { res.writeHead(200, { 'Content-Type': 'application/json' }); return res.end(JSON.stringify(CIBLES)); }
  if (req.method === 'POST' && chemin === '/api/vf/lancer') { await lire(req); scen.prop = scen.apres || null; res.writeHead(202, { 'Content-Type': 'application/json' }); return res.end('{"propose":true}'); }
  if (req.method === 'GET' && chemin === '/project.html' && new URL(req.url, OP).searchParams.get('sp1') === '1') { res.writeHead(200, { 'Content-Type': 'text/html' }); return res.end(pageSp1()); }
  if (req.method === 'POST' && chemin === '/__scenario') { scen = JSON.parse((await lire(req)).toString('utf8')); scen.lancers = scen.lancers || []; res.writeHead(204); return res.end(); }
  if (req.method === 'GET' && chemin === '/__journal') { res.writeHead(200, { 'Content-Type': 'application/json' }); return res.end(JSON.stringify(journal)); }
  res.writeHead(200, { 'Content-Type': 'text/html' });
  res.end(`<!doctype html><title>P factice</title><script>window.__msgs=[];addEventListener('message',function(e){window.__msgs.push({o:e.origin,t:typeof e.data,d:String(typeof e.data==='string'?e.data:JSON.stringify(e.data)).slice(0,200)})})</script>`);
});
await new Promise((ok) => q.listen(Number(portQ), '127.0.0.1', ok)); await new Promise((ok) => p.listen(Number(portP), '127.0.0.1', ok));
fs.writeFileSync(`${run}/pret`, `${process.pid}\n`);
JS
cat > "$AUX/chrome-bandeau.mjs" <<'JS'
// chrome-bandeau.mjs <chrome> <mode> <json> : scénarios navigateur du bandeau de proposition ; UNE ligne JSON. Modes : vue (LB.V) · client (LB.E1 à E7) · froid (LB.E8).
// Q factice dans un cadre sandbox de P factice, plein viewport (ou de taille nulle), secret posé dans le stockage de Q ; gestes par Input.dispatchMouseEvent seulement.
// Chaque étape est isolée (essai) : une mesure indisponible est nommée dans `erreurs`, jamais un résultat vide.
// Bornes d'attente : les plafonds d'attente POSITIVE sont à MS (20 s par défaut) : sur un produit cassé, N essais perdus × 20 s peuvent dépasser l'échéance globale de la session (VF_CDP_GLOBAL_MS, 600 s) ;
// la sonde est alors interrompue (la suite voit un scénario sans résultat). Le diagnostic se lit par cas perdu (`erreurs`, « attente de … dépassée »), pas sur la durée. Une borne qui EST l'objet d'une assertion ne se relève jamais.
import { pathToFileURL } from 'node:url'; import fs from 'node:fs';
const { executer, pause, stabiliser, attendreValeur, attendreEtStabiliser, positionPosee, AMORCE } = await import(pathToFileURL(process.env.CHROME_SESSION).href);
const { valide, ID_A, ID, NOTE, MOTIFS, INCONNU, MSG, ligne } = await import(pathToFileURL(process.env.LB_DONNEES).href);
const [, , chrome, mode, brut] = process.argv;
const { P, Q, secret, run, only = null, emu = false, codes = [] } = JSON.parse(brut);
const OP = `http://127.0.0.1:${P}`, OQ = `http://127.0.0.1:${Q}`, MS = Number(process.env.VF_CLIENT_MS) || 20000;
const AM = process.env.VF_CLIENT_MS ? MS : Math.max(MS, AMORCE); // première attente après l'ouverture de Chrome (amorçage à froid, CI PR #219) : bornée par AMORCE ; un VF_CLIENT_MS posé (mutants) la ramène à MS
const LISTE = ['ready', 'etat:connecte', 'etat:reconnexion', 'etat:termine', 'etat:refuse', 'etat:expire', 'etat:arrete', 'toggle'];
const erreurs = {};
const essai = async (nom, f) => { if (only && !only.includes(nom)) return; try { return await f(); } catch (e) { erreurs[nom] = String(e.message).slice(0, 160); return undefined; } };
const SBXQ = 'allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox';
let ctx = 0;
const mondeQ = async (s, etendue = 600) => {
  let trouve = 0;
  for (let id = 1; id < etendue; id++) {
    const v = await s.send('Runtime.evaluate', { contextId: id, expression: `location.origin === ${JSON.stringify(OQ)} && typeof window.vfTermVue === 'object'`, returnByValue: true }).then((x) => x && x.result && x.result.value, () => false);
    if (v === true) trouve = id;
  }
  return trouve;
};
const trouverCtx = async (s, borne = MS) => {
  const fin = Date.now() + borne; let essais = 0; ctx = 0;
  while (!ctx) { ctx = await mondeQ(s, 600 * 5 ** Math.min(essais++, 3)); if (!ctx) { if (Date.now() > fin) throw new Error('contexte du cadre de Q introuvable'); await pause(150); } }
};
const facadeQ = (s) => {
  const ev = async (expression) => { const x = await s.send('Runtime.evaluate', { expression, contextId: ctx, returnByValue: true, awaitPromise: true }); if (x && x.exceptionDetails) throw new Error(String((x.exceptionDetails.exception || {}).description || x.exceptionDetails.text).split('\n')[0].slice(0, 140)); return x && x.result && x.result.value; };
  const attendre = async (expr, nom, ms = MS) => {
    const fin = Date.now() + ms; let v;
    do { try { v = await ev(expr); } catch { v = false; } if (v) return v; await pause(100); } while (Date.now() < fin);
    throw new Error(`attente de « ${nom} » dépassée (${ms} ms)`);
  };
  // naviguer(url, taille) : secret posé dans le stockage de Q (premier niveau), puis Q dans un cadre sandbox de P ; taille 'nulle' = cadre masqué (tiroir jamais ouvert)
  let froid = true; // la première navigation d'un Chrome est l'amorçage à froid : ses attentes sont bornées par AM
  const naviguer = async (url = `${OQ}/?theme=dark`, taille = 'plein') => {
    const lim = froid ? AM : MS; froid = false; ctx = 0;
    await s.naviguer(`${OQ}/`); await s.ev(`localStorage.setItem('vf.terminal.secret', ${JSON.stringify(secret)})`);
    await s.naviguer(`${OP}/project.html`); await s.attendre(`document.readyState === 'complete'`, 'page P', lim);
    const dim = taille === 'nulle' ? 'width:0;height:0' : 'width:100vw;height:100vh';
    await s.ev(`(() => { const f = document.createElement('iframe'); f.dataset.t = '1'; f.setAttribute('sandbox', ${JSON.stringify(SBXQ)}); f.style.cssText = 'position:fixed;left:0;top:0;${dim};border:0;z-index:99999'; f.src = ${JSON.stringify(url)}; document.body.appendChild(f); })()`);
    await trouverCtx(s, lim);
    if (taille !== 'nulle') await attendre(`!!document.querySelector('.xterm-helper-textarea')`, 'terminal dans le cadre', lim);
  };
  const recharger = async (url) => { ctx = 0; await s.ev(`document.querySelector('iframe[data-t]').src = ${JSON.stringify(url)}`); await pause(300); await trouverCtx(s); await attendre(`!!document.querySelector('.xterm-helper-textarea')`, 'terminal après rechargement'); };
  return { ev, attendre, naviguer, recharger };
};
const scenario = (o) => fetch(`${OP}/__scenario`, { method: 'POST', body: JSON.stringify(o) }).then((x) => { if (x.status !== 204) throw new Error('scénario refusé ' + x.status); });
const journal = () => fetch(`${OP}/__journal`).then((x) => x.json());
const entrees = () => { try { return fs.readFileSync(`${run}/entree.log`, 'utf8').split('\n').filter(Boolean).length; } catch { return 0; } };
const retours = () => { try { return (fs.readFileSync(`${run}/entree.log`, 'utf8').replace(/\s/g, '').match(/(..)/g) || []).filter((o) => o === '0d').length; } catch { return 0; } }; // nombre d'octets \r reçus par l'entrée du shell factice

await executer(chrome, async (s) => {
  const q = facadeQ(s), r = { erreurs }; let vu = false; // vu : le bandeau s'est affiché au moins une fois (témoin positif des sondes négatives E4 et E7)
  await s.send('Emulation.setDeviceMetricsOverride', { width: 1000, height: 700, deviceScaleFactor: 1, mobile: false });
  const centre = async (expr) => { const p = await positionPosee(q.ev, expr); return p && { x: p.cx, y: p.cy }; }; // la position se lit une fois posée (deux rects égaux, aide commune) : un bandeau qui vient de monter bouge encore (défilement, accueil retiré) et un geste visé trop tôt tombe à côté (LB.V15 c, CI Linux, run 42392202936)
  const clic = async (expr) => {
    const c = await centre(expr); if (!c) throw new Error('élément introuvable : ' + expr.slice(0, 60));
    await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: c.x, y: c.y });
    await s.send('Input.dispatchMouseEvent', { type: 'mousePressed', x: c.x, y: c.y, button: 'left', clickCount: 1 });
    await s.send('Input.dispatchMouseEvent', { type: 'mouseReleased', x: c.x, y: c.y, button: 'left', clickCount: 1 });
  };
  const LANCER = `document.getElementById('proposition-lancer')`, SEL = `document.getElementById('proposition-mode')`;
  const ANNULER = `[...document.querySelectorAll('#proposition button')].find((b) => b.textContent === 'Annuler')`;
  const arme = () => q.ev(`(${LANCER} || { getAttribute: () => null }).getAttribute('aria-disabled')`);
  const attendreArme = (ms = MS) => q.attendre(`${LANCER}.getAttribute('aria-disabled') === 'false'`, 'armement du bouton Lancer', ms);
  const choisir = (m) => q.ev(`(() => { const e = ${SEL}; e.value = ${JSON.stringify(m)}; e.dispatchEvent(new Event('change', { bubbles: true })); return e.value; })()`);

  if (mode === 'vue') {
    await scenario({ prop: null }); await q.naviguer();
    await q.ev(`(() => {
      window.__T = { appels: [], annuler: 0, resolve: null };
      window.__cb = { lancer: (m) => { __T.appels.push(m); return new Promise((ok) => { __T.resolve = ok; }); }, annuler: () => { __T.annuler++; } };
      window.__erreurs = []; addEventListener('error', (e) => __erreurs.push(String(e.message)));
      window.__base = ${JSON.stringify(valide(ID_A))};
      window.__monter = (over) => { window.__t0 = performance.now(); vfTermVue.proposition(Object.assign({}, __base, { modeInitial: 'default' }, over), __cb); return true; };
      return true; })()`);
    const monter = (over = {}) => q.ev(`__monter(${JSON.stringify(over)})`);
    const raz = () => q.ev(`(() => { __T.appels.length = 0; vfTermVue.proposition(null); return true; })()`);
    const lg = valide(ID_A).lignes;
    await essai('v1', async () => { // DOM, sélecteur, commande exacte, note du mode hérité
      await monter({ id: ID(11), modeInitial: 'default' });
      const f = await q.ev(`(() => { const b = document.getElementById('proposition'), sel = ${SEL}; return { cls: b.className, role: b.getAttribute('role'), label: b.getAttribute('aria-label'), selLabel: sel.getAttribute('aria-label'),
        opts: [...sel.options].map((o) => o.value + '|' + o.textContent).join(';'), ligne: document.getElementById('proposition-ligne').textContent, zone: document.getElementById('proposition-ligne').getAttribute('aria-label'),
        texte: b.querySelector('.vf-q-texte').textContent, btns: [...b.querySelectorAll('button')].map((x) => x.textContent).join(','), note0: b.textContent.includes(${JSON.stringify(NOTE)}) }; })()`);
      const ligneDe = async (m) => { await choisir(m); return q.ev(`({ l: document.getElementById('proposition-ligne').textContent, note: document.getElementById('proposition').textContent.includes(${JSON.stringify(NOTE)}) })`); };
      const a = await ligneDe('acceptEdits'), h = await ligneDe('herite'), p0 = await ligneDe('plan');
      await monter({ id: ID(12), modeInitial: 'plan' });
      const pre = await q.ev(`({ val: ${SEL}.value, ligne: document.getElementById('proposition-ligne').textContent })`);
      r.v1 = [f.cls, f.role, f.label, f.selLabel, f.opts, f.ligne === lg.default, f.zone, f.texte, f.btns, f.note0, a.l === lg.acceptEdits, a.note, h.l === lg.herite, h.l.includes('--permission-mode'), h.note, p0.l === lg.plan, p0.note, pre.val, pre.ligne === lg.plan].join('/');
      await raz();
    });
    await essai('v2', async () => { // pré-vols : bloquants, avertissements, code inconnu
      await monter({ id: ID(21), arme_apres_ms: 400, bloquants: ['phase-finie', 'terminal-absent'] }); await pause(900);
      const b = await q.ev(`({ bloq: [...document.querySelectorAll('#proposition .vf-q-erreur-texte')].map((e) => e.textContent).join('|'), arme: ${LANCER}.getAttribute('aria-disabled') })`);
      await monter({ id: ID(22), arme_apres_ms: 400, avertissements: ['dependance-non-close'] }); await attendreArme(MS);
      const a = await q.ev(`[...document.querySelectorAll('#proposition .vf-q-attention-texte')].map((e) => e.textContent).join('|')`);
      await monter({ id: ID(23), arme_apres_ms: 400, bloquants: ['zz-inconnu'], avertissements: ['yy-inconnu'] });
      const u = await q.ev(`document.getElementById('proposition').textContent`);
      r.v2 = [b.bloq === `Bloquant : ${MOTIFS['phase-finie']}|Bloquant : ${MOTIFS['terminal-absent']}`, b.arme, a === `Attention : ${MOTIFS['dependance-non-close']}`,
        u.includes(`Bloquant : ${INCONNU}`) && u.includes(`Attention : ${INCONNU}`), u.includes('zz-inconnu') || u.includes('yy-inconnu')].join('/');
      await raz();
    });
    await essai('v3', async () => { // armement : un clic de confiance avant l'armement est ignoré, après il part UNE fois, un second pendant le vol est ignoré
      await raz(); await monter({ id: ID(31), arme_apres_ms: 1500 });
      await clic(LANCER); const tot = await q.ev('Math.round(performance.now() - __t0)'); await pause(200);
      const avant = await q.ev('__T.appels.length');
      await attendreArme(); await clic(LANCER); await pause(100); await clic(LANCER); await pause(200);
      r.v3 = `${tot < 1500 ? 'tôt' : 'tard:' + tot}/${avant}/${await q.ev('JSON.stringify(__T.appels)')}`;
      await raz();
    });
    await essai('v4', async () => { // clic non fiable ignoré même armé, puis le clic de confiance part (témoin)
      await raz(); await monter({ id: ID(41), arme_apres_ms: 400 }); await attendreArme(MS);
      await q.ev(`${LANCER}.click()`); await pause(200); const a0 = await q.ev('__T.appels.length');
      await clic(LANCER); r.v4 = `${a0}/${await attendreEtStabiliser(() => q.ev('__T.appels.length'), (n) => n >= 1, { pas: 200 })}`; // l'appel de confiance se lit une fois parti, puis stable (un second appel se verrait)
      await raz();
    });
    await essai('v5', async () => { // textes hostiles : littéraux, aucun nœud créé, aucune exécution, aucun style, aucune violation de CSP
      await raz(); const intention = '<img src=x onerror=window.__M72=1>', hostile = `claude '; touch M #'`;
      await monter({ id: ID(51), intention, lignes: { default: hostile, acceptEdits: hostile + ' a', plan: hostile + ' b', herite: hostile + ' c' }, bloquants: ['<b>x</b>'], avertissements: ['<i>y</i>'] });
      await pause(400);
      const f = await q.ev(`(() => { const b = document.getElementById('proposition'); return { lit: b.textContent.includes(${JSON.stringify(intention)}), ligne: document.getElementById('proposition-ligne').textContent, img: b.querySelectorAll('img').length, m72: typeof window.__M72,
        styles: b.querySelectorAll('[style]').length + (b.hasAttribute('style') ? 1 : 0), brut: b.textContent.includes('<b>x</b>') || b.textContent.includes('<i>y</i>'), noeuds: b.querySelectorAll('b, i, script, a').length + [...b.querySelectorAll('svg')].filter((x) => !x.closest('.vf-q-risque')).length }; })()`); // LB2 : le seul svg admis est le glyphe du risque (LB.V11 le dénombre), jamais un nœud sorti d'un texte hostile
      r.v5 = [f.lit, f.ligne === hostile, f.img, f.m72, f.styles, f.brut, f.noeuds, s.violations.length].join('/');
      await raz();
    });
    await essai('v6', async () => { // le bandeau est inséré AVANT le collage : le collage reste au-dessus et atteignable
      await raz(); await q.ev(`vfTermVue.collage('a\\nb', () => {}, () => {})`);
      await monter({ id: ID(61), modeInitial: 'herite', bloquants: ['phase-finie', 'terminal-absent'], avertissements: ['mission-vivante', 'lancement-recent'],
        lignes: { default: ligne('default') + ' ' + 'x'.repeat(120), acceptEdits: ligne('acceptEdits'), plan: ligne('plan'), herite: ligne('') + ' ' + 'y'.repeat(120) } });
      const f = await q.ev(`(() => { const c = document.getElementById('collage'), p = document.getElementById('proposition'), btn = [...c.querySelectorAll('button')].find((b) => b.textContent === 'Coller'), b = btn.getBoundingClientRect(),
        at = document.elementFromPoint(b.left + b.width / 2, b.top + b.height / 2); return { avant: !!(p.compareDocumentPosition(c) & Node.DOCUMENT_POSITION_FOLLOWING), dessus: !!(at && at.closest('#collage')) }; })()`);
      r.v6 = `${f.avant}/${f.dessus}`; await q.ev(`(() => { vfTermVue.collage(null); return true; })()`); await raz();
    });
    await essai('v7', async () => { // statuts rendus par cb.lancer
      const attendu = (st, f) => (st === 'ok' || st === 'absente') ? f.present === false
        : st === 'attendre' ? f.present && f.msg === MSG.attendre && f.arme === 'true' && f.rearme === true : f.present && f.msg === MSG[st] && f.arme === 'false';
      const sortie = []; let k = 70;
      for (const st of ['ok', 'attendre', 'occupe', 'sans-session', 'refus', 'reseau', 'absente']) {
        await raz(); await monter({ id: ID(++k), arme_apres_ms: 400 }); await attendreArme(MS); await clic(LANCER);
        await q.attendre('__T.appels.length === 1', 'appel de lancer', MS); await q.ev(`__T.resolve(${JSON.stringify(st)})`);
        const f = await attendreValeur(() => q.ev(`(() => { const b = document.getElementById('proposition'); return b ? { present: true, msg: document.getElementById('proposition-message').textContent, arme: ${LANCER}.getAttribute('aria-disabled') } : { present: false }; })()`),
          (x) => (st === 'ok' || st === 'absente') ? x.present === false : x.present && x.msg === MSG[st] && x.arme === (st === 'attendre' ? 'true' : 'false')); // le statut se rend après la résolution de la promesse : on lit l'état une fois posé
        if (st === 'attendre') f.rearme = await attendreArme(MS).then(() => true, () => false);
        sortie.push(`${st}=${attendu(st, f) ? 'ok' : 'KO ' + JSON.stringify(f)}`);
      }
      r.v7 = sortie.join(';'); await raz();
    });
    await essai('v8', async () => { // retrait sans exception tardive, remplacement, focus au premier affichage seulement (F1 : Annuler ne prend le focus que si le cadre de Q l'a déjà : le cadre est focalisé ici)
      await s.send('Emulation.setFocusEmulationEnabled', { enabled: true }); await s.ev(`document.querySelector('iframe[data-t]').focus()`); await q.ev(`document.body.focus()`); await q.attendre(`document.hasFocus()`, 'focus du cadre de Q'); // la vue ne prend le focus que si le cadre l'a (hasFocus au montage)
      await raz(); await monter({ id: ID(81), arme_apres_ms: 500 });
      await q.ev(`window.__vieux = ${LANCER}; vfTermVue.proposition(null); true`); await pause(900);
      const f1 = await q.ev(`({ present: !!document.getElementById('proposition'), vieux: __vieux.getAttribute('aria-disabled'), erreurs: __erreurs.length })`);
      await monter({ id: ID(82) }); await monter({ id: ID(83) });
      const f2 = await q.ev(`({ n: document.querySelectorAll('#proposition').length, id: document.getElementById('proposition').dataset.id, focus: document.activeElement && document.activeElement.textContent })`);
      await q.ev(`(() => { ${LANCER}.focus(); return true; })()`); await monter({ id: ID(83) });
      const f3 = await q.ev(`(document.activeElement && document.activeElement.textContent) || ''`);
      r.v8 = [f1.present, f1.vieux, f1.erreurs, f2.n, f2.id === ID(83), f2.focus, f3 !== 'Annuler'].join('/'); await raz();
    });
    await essai('v9', async () => { // ST-2 : chaque code de la table de cibles (liste DÉRIVÉE du module, passée par la suite, jamais un littéral) a un texte dans la vue
      const sans = [];
      for (const [i, c] of codes.entries()) {
        await raz(); await monter({ id: ID(90 + i), bloquants: [c] });
        const t = await q.ev(`(document.querySelector('#proposition .vf-q-erreur-texte') || {}).textContent || ''`);
        if (t === '' || t.includes(INCONNU)) sans.push(c);
      }
      r.v9 = codes.length + '/' + sans.join(','); await raz();
    });
    await essai('v10', async () => { // LB2 (PU-G-112, 120, 124) : accents à l'AFFICHAGE seulement, phrase en clair avant la commande, bouton « Préparer dans le terminal », phrase d'Entrée
      const sortie = [];
      for (const [verbe, affiche, intention, inf] of [['cadrer', 'Cadre', 'Cadre', 'cadrer'], ['planifier', 'Planifie', 'Planifie', 'planifier'], ['executer', 'Exécute', 'Execute', 'exécuter'], ['verifier', 'Vérifie', 'Verifie', 'vérifier'], ['reprendre', 'Reprends', 'Reprends', 'reprendre']]) {
        await raz(); await monter({ id: ID(100), verbe, intention: `${intention} la Phase 72 du compartiment alpha` });
        const f = await q.ev(`(() => { const b = document.getElementById('proposition'), ph = document.getElementById('proposition-phrase'), l = document.getElementById('proposition-ligne');
          return { texte: b.querySelector('.vf-q-texte').textContent, phrase: ph.textContent, avant: !!(ph.compareDocumentPosition(l) & Node.DOCUMENT_POSITION_FOLLOWING), bouton: document.getElementById('proposition-lancer').textContent,
            entree: document.getElementById('proposition-entree').textContent, ascii: /^[\\x20-\\x7e]+$/.test(l.textContent) }; })()`);
        sortie.push([f.texte === `Lancement proposé : ${affiche} la Phase 72 du compartiment alpha`, f.phrase.startsWith(`L’assistant va ${inf} la phase 72 du compartiment alpha : `), f.avant, f.bouton, f.entree.includes('Appuyez sur Entrée dans le terminal pour démarrer.'), f.ascii].join('.'));
      }
      r.v10 = sortie.join(';'); await raz();
    });
    await essai('v11', async () => { // LB2 (PU-G-121, 122 ; Q9) : une ligne par mode, « Risqué » (glyphe + mot, couleur neutre) sur « Accepter les modifications » seulement, « votre dernier choix » seulement pour un mode retenu autre que « Par défaut »
      await raz(); await monter({ id: ID(110), modeInitial: 'default' });
      const a = await q.ev(`(() => { const li = [...document.querySelectorAll('#proposition-modes li')], cs = (e) => getComputedStyle(e), nom = (x) => x.querySelector('.vf-q-mode-nom').textContent, risque = document.querySelector('.vf-q-risque');
        return { modes: li.map((x) => x.dataset.mode).join('|'), noms: li.map(nom).join('|'), aides: li.every((x) => x.textContent.length > nom(x).length + 20),
          risques: li.filter((x) => x.querySelector('.vf-q-risque')).map((x) => x.dataset.mode + ':' + x.querySelector('.vf-q-risque').textContent + ':' + x.querySelectorAll('.vf-q-risque svg').length).join('|'),
          neutre: !!risque && cs(risque).color === cs(document.querySelector('.vf-q-mode-nom')).color && cs(risque.querySelector('svg')).stroke === cs(risque).color,
          decrit: document.getElementById('proposition-mode').getAttribute('aria-describedby') === 'proposition-modes', dernier: document.getElementById('proposition-modes').textContent.includes('dernier choix') }; })()`);
      await monter({ id: ID(111), modeInitial: 'plan' });
      const b = await q.ev(`document.querySelector('#proposition-modes li[data-mode="plan"] .vf-q-mode-nom').textContent + '/' + document.getElementById('proposition-modes').textContent.split('dernier choix').length`);
      r.v11 = [a.modes, a.noms, a.aides, a.risques, a.neutre, a.decrit, a.dernier, b].join('/'); await raz();
    });
    await essai('v12', async () => { // LB2 (PU-G-123 ; Q6) : case du chat décochée par défaut, ce que fait la reprise et son risque écrits SANS exposer « -r … --fork-session » dans la phrase ; la commande, elle, change à la coche
      const lc = (m) => ligne(m) + " -r '0b8c7d6e-1111-4222-8333-444455556666' --fork-session";
      await raz(); await monter({ id: ID(120), chat: true, lignesChat: { default: lc('default'), acceptEdits: lc('acceptEdits'), plan: lc('plan'), herite: lc('') } });
      const f = await q.ev(`(() => { const c = document.getElementById('proposition-chat'), a = document.getElementById('proposition-chat-aide'); return { coche: c.checked, desc: c.getAttribute('aria-describedby'), aide: a.textContent, ligne0: document.getElementById('proposition-ligne').textContent }; })()`);
      await q.ev(`(() => { const c = document.getElementById('proposition-chat'); c.checked = true; c.dispatchEvent(new Event('change', { bubbles: true })); return true; })()`);
      const l1 = await q.ev(`document.getElementById('proposition-ligne').textContent`);
      r.v12 = [f.coche, f.desc, f.aide.includes('Reprend le fil de votre conversation'), f.aide.includes('Risque : la session lancée relit toute cette conversation'), !/--fork-session|-r '/.test(f.aide), !f.ligne0.includes('--fork-session'), l1.includes('--fork-session') && l1.includes("-r '0b8c7d6e")].join('/'); await raz();
    });
    await essai('v13', async () => { // LB2 (PU-G-114) : compte à rebours depuis expire_ms ; à l'échéance « Proposition expirée — la renvoyer. » (annoncé, seul « Fermer » reste) ; proposition(null) ne l'efface pas ; une disparition annoncée à moins de 3 s de l'échéance vaut expiration, pas à 100 s
      await raz(); await monter({ id: ID(130), expire_ms: 90000 });
      const c0 = await q.ev(`(() => { const e = document.getElementById('proposition-expire'), a = document.getElementById('annonce'); return e.textContent + '|' + e.getAttribute('role') + '|' + a.getAttribute('aria-live') + '|' + a.textContent; })()`);
      await monter({ id: ID(131), expire_ms: 2500, arme_apres_ms: 400 });
      await q.attendre(`(document.getElementById('proposition') || {}).getAttribute && document.getElementById('proposition').getAttribute('data-etat') === 'expiree'`, 'bandeau expiré', 8000);
      const e1 = await q.ev(`(() => { const b = document.getElementById('proposition'); return b.querySelector('.vf-q-texte').textContent + '|' + [...b.querySelectorAll('button')].map((x) => x.textContent).join(',') + '|' + !!document.getElementById('proposition-lancer') + '|' + document.getElementById('annonce').textContent; })()`);
      await q.ev(`(() => { vfTermVue.proposition(null); return true; })()`); await pause(200);
      const reste = await q.ev(`!!document.getElementById('proposition')`);
      await clic(`[...document.querySelectorAll('#proposition button')].find((b) => b.textContent === 'Fermer')`);
      const ferme = await attendreValeur(() => q.ev(`!document.getElementById('proposition')`), (v) => v === true);
      await monter({ id: ID(132), expire_ms: 2000 }); await q.ev(`(() => { vfTermVue.proposition(null); return true; })()`);
      const proche = await q.ev(`(document.getElementById('proposition') || { getAttribute: () => 'absent' }).getAttribute('data-etat')`);
      await raz(); await monter({ id: ID(133), expire_ms: 100000 }); await q.ev(`(() => { vfTermVue.proposition(null); return true; })()`);
      const loin = await q.ev(`!document.getElementById('proposition')`);
      r.v13 = [c0, e1, reste, ferme, proche, loin].join('/'); await raz();
    });
    await essai('v14', async () => { // LB2 (PU-G-117 ; Q5) : le bandeau est avant la saisie dans l'ordre de la page, après la région annoncée (live, polie) qui le dit
      await raz(); await monter({ id: ID(140) });
      r.v14 = await q.ev(`(() => { const b = document.getElementById('proposition'), t = document.getElementById('terminal'), a = document.getElementById('annonce'), F = Node.DOCUMENT_POSITION_FOLLOWING;
        return [!!(b.compareDocumentPosition(t) & F), !!(a.compareDocumentPosition(b) & F), a.getAttribute('role'), a.getAttribute('aria-live'), a.textContent.startsWith('Lancement proposé')].join('/'); })()`); await raz();
    });
    await essai('v15', async () => { // LB2 (PU-G-119) : un bandeau manipulé (sélecteur focalisé ET touche tapée il y a moins de 3 s, ou bouton de souris enfoncé dans le bandeau) n'est jamais remplacé ; un focus posé SANS geste ne protège rien ; libre, il est remplacé
      await s.send('Emulation.setFocusEmulationEnabled', { enabled: true }); await s.ev(`document.querySelector('iframe[data-t]').focus()`); await q.attendre(`document.hasFocus()`, 'focus du cadre de Q');
      await pause(3200); // un geste d'une étape précédente ne doit plus compter
      await raz(); await monter({ id: ID(150) });
      const nouvelle = (id) => q.ev(`(() => { const x = vfTermVue.proposition(Object.assign({}, __base, { id: ${JSON.stringify(id)}, modeInitial: 'default' }), __cb); return String(x) + ':' + document.getElementById('proposition').dataset.id; })()`);
      await q.ev(`(() => { ${SEL}.focus(); return true; })()`);
      const z = await nouvelle(ID(149)); // focus sans geste : remplacé
      await q.ev(`(() => { ${SEL}.focus(); return true; })()`);
      await s.send('Input.dispatchKeyEvent', { type: 'keyDown', key: 'ArrowDown', code: 'ArrowDown', windowsVirtualKeyCode: 40 }); await s.send('Input.dispatchKeyEvent', { type: 'keyUp', key: 'ArrowDown', code: 'ArrowDown', windowsVirtualKeyCode: 40 });
      const a = await nouvelle(ID(151)); // touche tapée dans le sélecteur : refusé
      await q.ev(`(() => { document.activeElement.blur(); return true; })()`);
      const b = await nouvelle(ID(151)); // focus rendu : remplacé
      const c0 = await centre(`document.querySelector('#proposition .vf-q-texte')`);
      await s.send('Input.dispatchMouseEvent', { type: 'mousePressed', x: c0.x, y: c0.y, button: 'left', clickCount: 1 });
      const c = await nouvelle(ID(152)); // souris enfoncée : refusé
      await s.send('Input.dispatchMouseEvent', { type: 'mouseReleased', x: c0.x, y: c0.y, button: 'left', clickCount: 1 });
      const d = await nouvelle(ID(152)); // relâchée : remplacé
      r.v15 = [z === `undefined:${ID(149)}`, a === `false:${ID(149)}`, b === `undefined:${ID(151)}`, c === `false:${ID(151)}`, d === `undefined:${ID(152)}`].join('/'); await raz();
    });
    await essai('v16', async () => { // LB3 (PU-G-136) : cadre bas (124 px, le plus petit tiroir) : la proposition prend sa place SOUS le terminal au lieu de le recouvrir ; retirée, le terminal reprend toute la hauteur
      await s.ev(`document.querySelector('iframe[data-t]').style.height = '124px'`);
      await raz(); await monter({ id: ID(160) });
      r.v16 = await attendreEtStabiliser(() => q.ev(`(() => { const t = document.getElementById('terminal').getBoundingClientRect(), b = document.getElementById('proposition').getBoundingClientRect(), H = innerHeight; return [H, t.height >= 24, t.bottom <= b.top + 0.5, b.height <= H * 0.6 + 1, b.bottom <= H].join('/'); })()`), (v) => typeof v === 'string' && v.startsWith('124/') && !v.includes('false'), { max: 4000 }); // la géométrie se juge une fois posée (redimensionnement du cadre, fit du terminal)
      await raz();
      r.v16 += '/' + (await attendreValeur(() => q.ev(`document.getElementById('terminal').getBoundingClientRect().height >= 120`), (v) => v === true, { max: 4000 }));
      await s.ev(`document.querySelector('iframe[data-t]').style.height = '100vh'`); await pause(200);
    });
    await essai('v21', async () => { // PU-G-136 (recette du 2026-11-08) : à la hauteur du tiroir à l'arrivée d'une proposition (300 px), le bandeau le plus long (case du chat comprise) défile, et « Préparer dans le terminal » reste VISIBLE sans défiler (collé au bas du bandeau), défilement au repos
      const lc = (m) => ligne(m) + " -r '0b8c7d6e-1111-4222-8333-444455556666' --fork-session";
      await s.ev(`document.querySelector('iframe[data-t]').style.height = '300px'`);
      await raz(); await monter({ id: ID(210), chat: true, lignesChat: { default: lc('default'), acceptEdits: lc('acceptEdits'), plan: lc('plan'), herite: lc('') } });
      r.v21 = await attendreEtStabiliser(() => q.ev(`(() => { const p = document.getElementById('proposition'), l = document.getElementById('proposition-lancer'), a = p.getBoundingClientRect(), b = l.getBoundingClientRect(), H = innerHeight; return [H, p.scrollTop, p.scrollHeight > p.clientHeight + 1, b.top >= a.top - 0.5, b.bottom <= a.bottom + 0.5, b.bottom <= H + 0.5].join('/'); })()`), (v) => typeof v === 'string' && v.startsWith('300/'), { max: 4000 }); // la géométrie se juge une fois posée (cadre redimensionné, fit du terminal)
      await raz(); await s.ev(`document.querySelector('iframe[data-t]').style.height = '100vh'`); await pause(200);
    });
    const v22run = async (tactile) => { // PU-G-136 / WCAG 2.4.11 (revue du 2026-11-08, S1) : au focus CLAVIER (vraies touches Tab et Maj+Tab), chaque arrêt dans le bandeau est visible, hors du pied collé, à 124, 300 et 450 px ; un arrêt dans le pied (Préparer) est visible dans le bandeau
      await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
      if (tactile) await s.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 }); // J7 : toucher RÉEL émulé (pointer: coarse), la réserve de 52 px du pied à 44 px
      const lc = (m) => ligne(m) + " -r '0b8c7d6e-1111-4222-8333-444455556666' --fork-session";
      const arret = () => q.ev(`(() => { const p = document.getElementById('proposition'), f = document.activeElement; if (!f || !p.contains(f)) return 'hors'; const pied = p.querySelector('.vf-q-pied'), a = p.getBoundingClientRect(), r = f.getBoundingClientRect(), d = pied.getBoundingClientRect(), H = innerHeight;
        const utile = d.top - a.top, vis = Math.min(r.bottom, d.top) - Math.max(r.top, a.top); // fenêtre utile = au-dessus du pied ; un élément plus haut qu'elle (la commande exacte à 124 px) doit la remplir, un autre doit y tenir entier
        const vu = pied.contains(f) ? (r.top >= a.top - 0.5 && r.bottom <= a.bottom + 0.5) : vis >= Math.min(r.height, utile) - 0.5; return (f.id || f.tagName + '=' + (f.textContent || '').trim()) + ':' + (vu && r.bottom <= H + 0.5) + ':' + Math.round(p.scrollTop) + ':' + Math.round(r.top) + '-' + Math.round(r.bottom) + '/' + Math.round(d.top); })()`);
      const sortie = [];
      for (const H of [124, 300, 450]) {
        await s.ev(`document.querySelector('iframe[data-t]').style.height = '${H}px'`);
        await raz(); await monter({ id: ID(220 + (H % 7)), chat: true, lignesChat: { default: lc('default'), acceptEdits: lc('acceptEdits'), plan: lc('plan'), herite: lc('') } });
        await attendreEtStabiliser(() => q.ev(`(() => { const p = document.getElementById('proposition'), t = document.getElementById('terminal'); return [innerHeight, !!p, p && Math.round(p.getBoundingClientRect().top), t && Math.round(t.getBoundingClientRect().height)].join('/'); })()`), (v) => typeof v === 'string' && v.startsWith(H + '/true'), { max: 4000 });
        await s.ev(`document.querySelector('iframe[data-t]').focus()`); await q.attendre(`document.hasFocus()`, 'focus du cadre de Q');
        const frappe = async (shift) => { const base = { key: 'Tab', code: 'Tab', windowsVirtualKeyCode: 9, nativeVirtualKeyCode: 9, modifiers: shift ? 8 : 0 }; await s.send('Input.dispatchKeyEvent', { type: 'rawKeyDown', ...base }); await s.send('Input.dispatchKeyEvent', { type: 'keyUp', ...base }); };
        // F3 (3e tour) : deux parcours réels, chacun partant d'un élément DU bandeau (Maj+Tab depuis le terminal sortait du cadre : la moitié restait vide) : Tab depuis le sélecteur de mode (Annuler, commande, case du chat, Préparer),
        // Maj+Tab depuis Préparer (case du chat, commande, Annuler, sélecteur de mode). Chaque arrêt est nommé : un parcours qui ne traverse pas le bandeau ne peut plus passer pour un parcours vert.
        const parcours = async (depart, shift) => {
          await q.ev(`(() => { const p = document.getElementById('proposition'); p.scrollTop = 0; document.getElementById('${depart}').focus(); return true; })()`);
          await stabiliser(arret, { pas: 80, max: 2000 });
          const arrets = []; for (let i = 0; i < 4; i++) { await frappe(shift); arrets.push(await stabiliser(arret, { pas: 80, max: 2000 })); } return arrets;
        };
        const tab = await parcours('proposition-mode', false), maj = await parcours('proposition-lancer', true);
        const noms = (l) => l.map((a) => a.split(':')[0]).join('>'), mal = [...tab, ...maj].filter((a) => a === 'hors' || a.split(':')[1] !== 'true');
        sortie.push(`${H}/${noms(tab)}/${noms(maj)}/${mal.length ? '[' + mal.join(',') + ']' : 'true'}`);
      }
      const coarse = tactile ? 'coarse=' + await q.ev(`matchMedia('(pointer: coarse)').matches`) + ';' : ''; // J7 : le témoin que le média est vrai (sans lui, le parcours tactile jugerait la souris)
      if (tactile) await s.send('Emulation.setTouchEmulationEnabled', { enabled: false });
      await raz(); await s.ev(`document.querySelector('iframe[data-t]').style.height = '100vh'`); await pause(200);
      return coarse + sortie.join(';');
    };
    await essai('v22', async () => { r.v22 = await v22run(false); });
    await essai('v22c', async () => { r.v22c = await v22run(true); });
    await essai('v23', async () => { // S3 (revue du 2026-11-08) : le pied collé a un fond OPAQUE (ce qui défile dessous ne doit pas transparaître derrière « Préparer »)
      await s.ev(`document.querySelector('iframe[data-t]').style.height = '300px'`);
      await raz(); await monter({ id: ID(230), chat: true, lignesChat: { default: ligne('default'), acceptEdits: ligne('acceptEdits'), plan: ligne('plan'), herite: ligne('') } });
      r.v23 = await attendreEtStabiliser(() => q.ev(`(() => { const d = document.querySelector('#proposition .vf-q-pied'), c = getComputedStyle(d); return [c.position, /^rgb\\(/.test(c.backgroundColor)].join('/') + '/' + c.backgroundColor; })()`), (v) => typeof v === 'string' && v.startsWith('sticky/'), { max: 4000 }).then((v) => v.split('/').slice(0, 2).join('/'));
      await raz(); await s.ev(`document.querySelector('iframe[data-t]').style.height = '100vh'`); await pause(200);
    });
    await essai('v24', async () => { // S2 (revue du 2026-11-08) : après un refus de lancement, la raison est VISIBLE sans défiler, à 300 px avec la case du chat (elle se range sous le pied, le défilement l'y ramène) et distincte du pied
      await s.ev(`document.querySelector('iframe[data-t]').style.height = '300px'`);
      await raz(); await monter({ id: ID(240), arme_apres_ms: 400, chat: true, lignesChat: { default: ligne('default'), acceptEdits: ligne('acceptEdits'), plan: ligne('plan'), herite: ligne('') } });
      await attendreArme(MS); await clic(LANCER); await q.attendre('__T.appels.length === 1', 'appel de lancer', MS); await q.ev(`__T.resolve('occupe')`);
      r.v24 = await attendreEtStabiliser(() => q.ev(`(() => { const p = document.getElementById('proposition'), m = document.getElementById('proposition-message'), d = p.querySelector('.vf-q-pied').getBoundingClientRect(), a = p.getBoundingClientRect(), b = m.getBoundingClientRect(), H = innerHeight;
        return [H, m.textContent === ${JSON.stringify(MSG.occupe)}, b.height > 0 && b.top >= a.top - 0.5 && b.bottom <= a.bottom + 0.5 && b.bottom <= H + 0.5, b.top >= d.bottom - 0.5 || b.bottom <= d.top + 0.5].join('/'); })()`), (v) => typeof v === 'string' && v.startsWith('300/true'), { max: 4000 });
      await raz(); await s.ev(`document.querySelector('iframe[data-t]').style.height = '100vh'`); await pause(200);
    });
    await essai('v25', async () => { // P5 (revue du 2026-11-08, seconde réserve de PU-G-136) : une fois la commande préparée, la consigne « Appuyez sur Entrée » reste VISIBLE (pas seulement annoncée) jusqu'à Entrée dans le terminal, ou jusqu'à la fin du compte à rebours de la proposition
      await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
      const consigne = () => q.ev(`(() => { const c = document.getElementById('consigne'); if (!c) return 'absente'; const b = c.getBoundingClientRect(); return (b.height > 0 && b.bottom <= innerHeight + 0.5 ? 'visible:' : 'cachee:') + c.textContent + '|proposition=' + !!document.getElementById('proposition'); })()`);
      const DIT = 'visible:Commande préparée dans le terminal. Appuyez sur Entrée dans le terminal pour démarrer.|proposition=false';
      const sortie = [];
      for (const fin of ['entree', 'compte-a-rebours']) {
        await raz(); await monter({ id: ID(fin === 'entree' ? 250 : 251), arme_apres_ms: 400, expire_ms: fin === 'entree' ? 100000 : 6000 });
        await attendreArme(MS); await clic(LANCER); await q.attendre('__T.appels.length === 1', 'appel de lancer', MS); await q.ev(`__T.resolve('ok')`);
        const vu = await attendreValeur(consigne, (v) => v === DIT, { max: 3000 });
        await pause(fin === 'entree' ? 1500 : 300); const encore = await consigne(); // toujours là sans rien faire (hors échéance), tant qu'Entrée n'est pas tapée
        if (fin === 'entree') {
          await s.ev(`document.querySelector('iframe[data-t]').focus()`); await q.attendre(`document.hasFocus()`, 'focus du cadre de Q'); await q.ev(`document.querySelector('.xterm-helper-textarea').focus()`);
          const base = { key: 'Enter', code: 'Enter', windowsVirtualKeyCode: 13, nativeVirtualKeyCode: 13 };
          await s.send('Input.dispatchKeyEvent', { type: 'rawKeyDown', ...base }); await s.send('Input.dispatchKeyEvent', { type: 'char', text: '\r', ...base }); await s.send('Input.dispatchKeyEvent', { type: 'keyUp', ...base });
        }
        const apres = await attendreValeur(consigne, (v) => v === 'absente', { max: 8000 });
        sortie.push([fin, vu === DIT, encore === DIT, apres].join(':'));
      }
      r.v25 = sortie.join(';'); await raz();
    });
    await essai('v25b', async () => { // 3e tour de la recette du 2026-11-08 : F2 une Entrée TENUE (répétitions, autoRepeat) dans le terminal ne retire pas la consigne, seule une Entrée fraîche la retire ; F4 une nouvelle proposition, puis une carte, REMPLACENT la consigne ; F6b la consigne est entièrement visible au-dessus du bandeau d'état fixe
      await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
      const consigne = () => q.ev(`(() => { const c = document.getElementById('consigne'); if (!c) return 'absente'; const b = c.getBoundingClientRect(); return (b.height > 0 && b.bottom <= innerHeight + 0.5 ? 'visible:' : 'cachee:') + c.textContent; })()`);
      const DIT = 'visible:Commande préparée dans le terminal. Appuyez sur Entrée dans le terminal pour démarrer.';
      let n = 0;
      const preparer = async () => { await raz(); await monter({ id: ID(260 + (++n)), arme_apres_ms: 400, expire_ms: 100000 }); await attendreArme(MS); await clic(LANCER); await q.attendre('__T.appels.length === 1', 'appel de lancer', MS); await q.ev(`__T.resolve('ok')`); return attendreValeur(consigne, (v) => v === DIT, { max: 3000 }); };
      const entree = async (repetition) => {
        const base = { key: 'Enter', code: 'Enter', windowsVirtualKeyCode: 13, nativeVirtualKeyCode: 13, autoRepeat: repetition };
        await s.send('Input.dispatchKeyEvent', { type: 'rawKeyDown', ...base }); await s.send('Input.dispatchKeyEvent', { type: 'char', text: '\r', ...base }); await s.send('Input.dispatchKeyEvent', { type: 'keyUp', ...base });
      };
      const sortie = [];
      // F2 : trois répétitions d'Entrée (touche tenue) : la consigne reste ; une pression fraîche la retire
      let vu = await preparer();
      await s.ev(`document.querySelector('iframe[data-t]').focus()`); await q.attendre(`document.hasFocus()`, 'focus du cadre de Q'); await q.ev(`document.querySelector('.xterm-helper-textarea').focus()`);
      for (let i = 0; i < 3; i++) await entree(true);
      await pause(400); const tenue = await consigne();
      await entree(false); const fraiche = await attendreValeur(consigne, (v) => v === 'absente', { max: 4000 });
      sortie.push('tenue:' + (vu === DIT) + ':' + (tenue === DIT) + ':' + fraiche);
      // F4 : une nouvelle proposition remplace la consigne affichée
      vu = await preparer(); await monter({ id: ID(290 + n) });
      sortie.push('proposition:' + (vu === DIT) + ':' + await attendreValeur(consigne, (v) => v === 'absente', { max: 3000 }));
      // F4 : une carte (« Serveur arrêté ») remplace la consigne affichée
      vu = await preparer(); await q.ev(`(() => { vfTermVue.carte('arrete'); return true; })()`);
      sortie.push('carte:' + (vu === DIT) + ':' + await attendreValeur(consigne, (v) => v === 'absente', { max: 3000 }));
      // F6b : avec le bandeau d'état fixe (44 px + 8 de marge), la consigne se pose au-dessus ; mesurée à 124, 300 px et pleine hauteur
      for (const h of ['124px', '300px', '100vh']) {
        await s.ev(`document.querySelector('iframe[data-t]').style.height = '${h}'`);
        vu = await preparer(); await q.ev(`(() => { vfTermVue.bandeau('reconnexion'); return true; })()`);
        const au_dessus = await attendreEtStabiliser(() => q.ev(`(() => { const c = document.getElementById('consigne'), e = document.querySelector('#etat .vf-q-bandeau'); if (!c || !e) return 'absent'; const a = c.getBoundingClientRect(), b = e.getBoundingClientRect(); return String(a.height > 0 && a.bottom <= b.top + 0.5); })()`), (v) => v === 'true' || v === 'false', { max: 4000 });
        sortie.push('etat-' + h + ':' + (vu === DIT) + ':' + au_dessus);
      }
      r.v25b = sortie.join(';'); await q.ev(`(() => { vfTermVue.effacer(); return true; })()`); await raz(); await s.ev(`document.querySelector('iframe[data-t]').style.height = '100vh'`); await pause(200);
    });
    await essai('v26', async () => { // S4 (revue du 2026-11-08, PU-G-139) : à l'EXÉCUTION, le champ de saisie du vrai xterm s'annonce « Saisie du terminal » (l'inventaire F15 de chrome-fr ne lit que le texte du client : une ligne commentée ou posée après open() le laissait vert)
      r.v26 = await attendreValeur(() => q.ev(`(document.querySelector('.xterm-helper-textarea') || { getAttribute: () => 'absent' }).getAttribute('aria-label')`), (v) => typeof v === 'string' && v !== 'absent', { max: 4000 });
    });
    await essai('v17', async () => { // LB3 (PU-G-141 ; Q14) : la carte reste entière dans un cadre bas (marge de 8 px, sans défilement) ; « Copier la commande » copie EXACTEMENT la commande affichée, annonce le résultat ; aucun bouton de copie sur une proposition de lancement
      await s.ev(`document.querySelector('iframe[data-t]').style.height = '124px'`);
      await q.ev(`(() => { vfTermVue.carte('arrete'); window.__copie = null; document.addEventListener('copy', () => { window.__copie = String(getSelection()); }, true); return true; })()`);
      const geo = (await attendreEtStabiliser(() => q.ev(`(() => { const k = document.querySelector('.vf-q-carte'), b = k.getBoundingClientRect(), H = innerHeight; return { H, g: [b.top >= 7.5, b.bottom <= H - 7.5, k.scrollHeight <= k.clientHeight + 1].join('/') }; })()`), (v) => !!v && v.H === 124 && !v.g.includes('false'), { max: 4000 })).g; // cadre à 124 px posé, carte jugée une fois entière
      await clic(`[...document.querySelectorAll('.vf-q-carte button')].find((x) => x.textContent === 'Copier la commande')`);
      // la copie est synchrone dans le clic ; « Copiée » se rétablit au bout de 2,5 s (vue) : on lit dès que l'évènement copy est passé, jamais plus tard
      const ap = await attendreValeur(() => q.ev(`({ copie: window.__copie, affichee: document.querySelector('.vf-q-commande').textContent, bouton: [...document.querySelectorAll('.vf-q-carte button')].map((x) => x.textContent).join(','), annonce: document.getElementById('annonce').textContent })`), (a) => a.copie !== null, { pas: 50, max: 2000 });
      await q.ev(`(() => { vfTermVue.effacer(); return true; })()`); await raz(); await monter({ id: ID(170) });
      const sansCopie = await q.ev(`![...document.querySelectorAll('#proposition button')].some((x) => /copi/i.test(x.textContent))`); await raz();
      r.v17 = [geo, ap.copie === ap.affichee && ap.affichee === '/vf-cockpit --terminal', ap.bouton, ap.annonce, sansCopie].join('|');
      await s.ev(`document.querySelector('iframe[data-t]').style.height = '100vh'`); await pause(200);
    });
    await essai('v18', async () => { // LB3 (PU-G-140) : accueil de la première ouverture : effaçable, jamais d'octet au shell ni de focus pris ; une proposition ou une carte le remplace ; « Compris » le range pour de bon
      await q.ev(`(() => { localStorage.removeItem('vf.terminal.accueil'); vfTermVue.proposition(null); return true; })()`);
      const foc = () => q.ev(`document.activeElement ? document.activeElement.tagName + '#' + document.activeElement.id : ''`);
      await q.ev(`(() => { const x = document.getElementById('accueil'); if (x) x.remove(); document.querySelector('.xterm-helper-textarea').focus(); return true; })()`); // état connu : pas d'accueil, le focus sur la saisie du terminal
      const foc0 = await foc(), n0 = entrees();
      await q.ev(`(() => { vfTermVue.effacer(); return true; })()`);
      const a = await q.ev(`(() => { const e = document.getElementById('accueil'); return e ? [e.getAttribute('role'), e.textContent.includes('Vous n’en avez pas besoin pour suivre le travail dans le cockpit'), [...e.querySelectorAll('button')].map((x) => x.textContent).join(',')].join('|') : 'absent'; })()`);
      const foc1 = await foc(); await pause(300); const n1 = entrees();
      await monter({ id: ID(180) }); const remplace = await q.ev(`!document.getElementById('accueil')`); await raz();
      await q.ev(`(() => { vfTermVue.effacer(); return true; })()`); const revient = await q.ev(`!!document.getElementById('accueil')`);
      await q.ev(`(() => { vfTermVue.carte('refuse'); return true; })()`); const carte = await q.ev(`!document.getElementById('accueil')`);
      await q.ev(`(() => { vfTermVue.effacer(); return true; })()`);
      await clic(`[...document.querySelectorAll('#accueil button')].find((x) => x.textContent === 'Compris')`);
      const ferme = await attendreValeur(() => q.ev(`!document.getElementById('accueil') && localStorage.getItem('vf.terminal.accueil') === '1'`), (v) => v === true);
      await q.ev(`(() => { vfTermVue.effacer(); return true; })()`); const nonRevenu = await q.ev(`!document.getElementById('accueil')`);
      r.v18 = [a === 'status|true|Compris', foc0 === foc1, n0 === n1, remplace, revient, carte, ferme, nonRevenu].join('/');
    });
    await essai('v20', async () => { // LB3-S2 (F3, PU-G-140) : l'accueil ne masque ni la sortie ni l'invite (le terminal rétrécit, comme pour la proposition) ; il se range à la première frappe dans le terminal SANS la retenir ni la modifier (UN octet « x » au shell, celui de la frappe), le focus reste où il était ; « Compris » à la souris ne prend jamais le focus
      await q.ev(`(() => { localStorage.removeItem('vf.terminal.accueil'); vfTermVue.proposition(null); const x = document.getElementById('accueil'); if (x) x.remove(); return true; })()`);
      const foc = () => q.ev(`document.activeElement ? document.activeElement.className : ''`);
      const lignesLog = () => { try { return fs.readFileSync(`${run}/entree.log`, 'utf8').split('\n').filter(Boolean); } catch { return []; } };
      await q.ev(`(() => { vfTermVue.effacer(); return true; })()`); await q.attendre(`!!document.getElementById('accueil')`, 'accueil monté');
      await clic(`document.querySelector('.xterm-screen')`);
      const foc0 = await attendreValeur(foc, (v) => v === 'xterm-helper-textarea'), n0 = lignesLog().length;
      const geo = (await attendreEtStabiliser(() => q.ev(`(() => { const a = document.getElementById('accueil'), t = document.getElementById('terminal').getBoundingClientRect(), b = a.getBoundingClientRect(); return { H: innerHeight, g: [t.bottom <= b.top + 1, b.bottom <= innerHeight + 1, t.height > 24, a.querySelector('button').tabIndex === -1].join('.') }; })()`), (v) => !!v && v.H === 700 && !v.g.includes('false'), { max: 4000 })).g; // pleine hauteur de la fenêtre émulée (700 px)
      await s.send('Input.dispatchKeyEvent', { type: 'keyDown', key: 'x', code: 'KeyX', text: 'x', windowsVirtualKeyCode: 88 }); await s.send('Input.dispatchKeyEvent', { type: 'keyUp', key: 'x', code: 'KeyX', windowsVirtualKeyCode: 88 });
      // la frappe traverse POST /entree et le rangement de l'accueil : on lit une fois l'octet arrivé et l'accueil rangé, puis stable (un second octet se verrait)
      const apres = await attendreEtStabiliser(async () => ({ rangee: await q.ev(`!document.getElementById('accueil') && localStorage.getItem('vf.terminal.accueil') === '1'`), octets: lignesLog().slice(n0), foc: await foc() }), (a) => a.rangee === true && a.octets.length >= 1 && a.octets[0] === '78', { pas: 500, max: 6000 }); // pas 500 : fenêtre de silence d'origine (un second octet se verrait)
      const rangee = apres.rangee, octets = apres.octets, focFin = apres.foc;
      await q.ev(`(() => { localStorage.removeItem('vf.terminal.accueil'); vfTermVue.effacer(); return true; })()`); await q.attendre(`!!document.getElementById('accueil')`, 'accueil remonté');
      await clic(`document.querySelector('.xterm-screen')`); const focS = await stabiliser(foc, { max: 3000 });
      await clic(`[...document.querySelectorAll('#accueil button')].find((x) => x.textContent === 'Compris')`);
      const finale = await attendreValeur(async () => !(await q.ev(`!!document.getElementById('accueil')`)) && (await foc()) === focS, (v) => v === true, { max: 5000 });
      r.v20 = [geo, foc0 === 'xterm-helper-textarea' && foc0 === focFin, rangee, octets.length === 1 && octets[0] === '78', finale].join('/');
    });
    await essai('v19', async () => { // LB3-S (revue LB1-LB2, findings b et a) : « Préparer » vient APRÈS la commande exacte et la case du chat dans l'ordre du document (donc de tabulation et de lecture) ; la carte et le bandeau d'état ne sont jamais masqués par la proposition, à 124 px comme à pleine hauteur
      const lc = (m) => ligne(m) + " -r '0b8c7d6e-1111-4222-8333-444455556666' --fork-session";
      await raz(); await monter({ id: ID(190), chat: true, lignesChat: { default: lc('default'), acceptEdits: lc('acceptEdits'), plan: lc('plan'), herite: lc('') } });
      const ordre = await q.ev(`(() => { const f = (id) => document.getElementById(id), apres = (a, b) => !!(f(a).compareDocumentPosition(f(b)) & Node.DOCUMENT_POSITION_FOLLOWING); return [apres('proposition-ligne', 'proposition-lancer'), apres('proposition-chat', 'proposition-lancer'), apres('proposition-entree', 'proposition-lancer'), apres('proposition-modes', 'proposition-lancer'), !!document.querySelector('#proposition-modes li[data-mode="acceptEdits"] .vf-q-risque')].join('.'); })()`);
      const masque = async (h, appel) => {
        await s.ev(`document.querySelector('iframe[data-t]').style.height = '${h}'`); await raz(); await monter({ id: ID(191) }); await q.ev(`(() => { ${appel}; return true; })()`);
        const v = await attendreEtStabiliser(() => q.ev(`(() => { const e = document.querySelector('#etat .vf-q-bandeau, #etat .vf-q-carte'), b = e.getBoundingClientRect(), pts = [[(b.left + b.right) / 2, (b.top + b.bottom) / 2], [b.left + 24, b.bottom - 14], [b.left + 24, b.top + 14]]; return pts.every(([x, y]) => { const h = document.elementFromPoint(x, y); return !!h && !h.closest('#proposition'); }); })()`), (x) => x === true, { max: 3000 }); // jugé une fois la géométrie posée (hauteur du cadre, carte/bandeau montés)
        await q.ev(`(() => { vfTermVue.effacer(); vfTermVue.proposition(null); return true; })()`); return v === true;
      };
      const m = [await masque('124px', `vfTermVue.bandeau('reconnexion')`), await masque('124px', `vfTermVue.carte('arrete')`), await masque('100vh', `vfTermVue.bandeau('reconnexion')`), await masque('100vh', `vfTermVue.carte('arrete')`)];
      r.v19 = [ordre, ...m].join('/');
      await s.ev(`document.querySelector('iframe[data-t]').style.height = '100vh'`); await pause(200);
    });
    return JSON.parse(JSON.stringify(r).split(secret).join('<secret>'));
  }

  if (mode === 'client') {
    await scenario({ prop: valide(ID_A), lancers: [] }); await q.naviguer();
    await essai('e1', async () => { // proposition servie : bandeau, commande exacte du serveur, UN message fixe vers P
      await q.attendre(`!!document.getElementById('proposition')`, 'bandeau de proposition', MS); vu = true;
      const ligneQ = await q.ev(`document.getElementById('proposition-ligne').textContent`);
      const msgs = await attendreEtStabiliser(async () => JSON.parse(await s.ev('JSON.stringify(window.__msgs)')), (m) => m.some((x) => x.d === 'proposition')), props = msgs.filter((m) => m.d === 'proposition'); // le message vers P arrive dans une tâche suivante : lu une fois reçu, puis stable
      r.e1 = [ligneQ === valide(ID_A).lignes.default, props.length, props.every((m) => m.o === OQ && m.t === 'string'), msgs.every((m) => m.o === OQ && (LISTE.includes(m.d) || m.d === 'proposition')),
        !JSON.stringify(msgs).includes(ID_A) && !JSON.stringify(msgs).includes(secret) && !JSON.stringify(msgs).includes('claude')].join('/');
    });
    await essai('e2', async () => { // clic avant l'armement : aucun POST ; après : UN POST de clés exactes id,mode, jamais d'octet au PTY
      // Proposition NEUVE d'armement long : le minuteur du bandeau d'e1 court depuis son affichage, et sous charge (CI Linux) il était déjà échu quand ce clic « avant l'armement » partait
      // (204 au lieu d'un clic ignoré, bandeau retiré, attente d'armement vaine). Le témoin `desarme` (premier terme du résultat) reste exigé : un bandeau déjà armé rougit.
      await scenario({ prop: valide(ID(35), { arme_apres_ms: 3000 }), lancers: [] });
      await q.attendre(`(document.getElementById('proposition') || {}).dataset && document.getElementById('proposition').dataset.id === ${JSON.stringify(ID(35))}`, 'bandeau de la proposition neuve', 5000);
      const desarme = await arme() === 'true'; await clic(LANCER); await pause(400);
      const tot = (await journal()).filter((x) => x.u === '/lancer').length;
      await attendreArme(MS); await choisir('acceptEdits'); await clic(LANCER);
      await q.attendre(`!document.getElementById('proposition')`, 'bandeau retiré après 204', MS);
      const l = (await journal()).filter((x) => x.u === '/lancer');
      r.e2 = [desarme, tot, l.length, l[0] && Object.keys(JSON.parse(l[0].b)).sort().join(','), l[0] && !l[0].b.includes('claude'), l[0] && l[0].st, entrees(), String(await q.ev(`localStorage.getItem('vf.terminal.mode')`))].join('/');
    });
    await essai('e3', async () => { // 409 : message, 0 octet, le bandeau reste, un second clic armé aboutit
      const n0 = (await journal()).filter((x) => x.u === '/lancer').length;
      await scenario({ prop: valide(ID(32), { arme_apres_ms: 600 }), lancers: [409] });
      await q.attendre(`(document.getElementById('proposition') || {}).dataset && document.getElementById('proposition').dataset.id === ${JSON.stringify(ID(32))}`, 'bandeau de la seconde proposition', 5000);
      await attendreArme(); await clic(LANCER);
      const msgOk = await q.attendre(`document.getElementById('proposition-message').textContent === ${JSON.stringify(MSG.occupe)}`, 'message occupé', MS).then(() => true, () => false);
      const present = await q.ev(`!!document.getElementById('proposition')`), rearme = (await arme()) === 'false', e0 = entrees();
      await clic(LANCER); const parti = await q.attendre(`!document.getElementById('proposition')`, 'bandeau retiré après le second clic', MS).then(() => true, () => false);
      r.e3 = [msgOk, e0, present, rearme, parti, (await journal()).filter((x) => x.u === '/lancer').slice(n0).map((x) => x.st).join(',')].join('/');
    });
    await essai('e4', async () => { // après usage le serveur dit aucune : bascule de thème, puis plus aucun bandeau
      await q.recharger(`${OQ}/?theme=light`); await pause(3500);
      r.e4 = [vu, await q.ev(`document.querySelectorAll('#proposition').length`), await q.ev(`document.documentElement.getAttribute('data-theme')`)].join('/');
    });
    await essai('e7', async () => { // messages entrants de P : aucun effet
      const n0 = (await journal()).filter((x) => x.u === '/lancer').length;
      await s.ev(`(() => { const w = document.querySelector('iframe[data-t]').contentWindow; w.postMessage('proposition', '*'); w.postMessage({ id: 'zzz' }, '*'); w.postMessage('{"id":"zzz","mode":"plan"}', '*'); return true; })()`); await pause(900);
      r.e7 = [vu, await q.ev(`document.querySelectorAll('#proposition').length`), (await journal()).filter((x) => x.u === '/lancer').length - n0].join('/');
    });
    await essai('e5', async () => { // stockage de Q illisible depuis P ; mode servi relu contre la liste fermée (P72-D-20 : le stockage ne porte plus le mode)
      const sec = await s.ev(`(() => { try { void document.querySelector('iframe[data-t]').contentWindow.localStorage; return 'lu'; } catch (e) { return e.name; } })()`);
      const temoinSecret = await q.ev(`localStorage.getItem('vf.terminal.secret') !== null`); // W-3 : le stockage de Q n'est pas vide (il porte le secret) et P n'y accède pourtant pas
      await scenario({ prop: valide(ID(52), { arme_apres_ms: 600 }), lancers: [], mode_retenu: 'acceptEdits' });
      await q.attendre(`(document.getElementById('proposition') || {}).dataset && document.getElementById('proposition').dataset.id === ${JSON.stringify(ID(52))}`, 'bandeau du témoin', 5000);
      const temoin = await q.ev(`${SEL}.value`);
      await scenario({ prop: valide(ID(51), { arme_apres_ms: 600 }), lancers: [], mode_retenu: 'bypassPermissions' });
      await q.attendre(`(document.getElementById('proposition') || {}).dataset && document.getElementById('proposition').dataset.id === ${JSON.stringify(ID(51))}`, 'bandeau de la proposition suivante', 5000);
      r.e5 = [sec, temoinSecret ? 'secret' : 'sans-secret', temoin, await q.ev(`${SEL}.value`)].join('/');
    });
    await essai('e6', async () => { // paramètres d'adresse : jamais lus (le serveur factice sert plan : un paramètre lu donnerait acceptEdits)
      await scenario({ prop: valide(ID(51), { arme_apres_ms: 600 }), lancers: [], mode_retenu: 'plan' });
      const n0 = (await journal()).filter((x) => x.u === '/lancer').length;
      await q.recharger(`${OQ}/?theme=dark&mode=acceptEdits&lancer=1&id=zzz`);
      await q.attendre(`!!document.getElementById('proposition')`, 'bandeau après rechargement', MS); await pause(800);
      r.e6 = [await q.ev(`${SEL}.value`), (await journal()).filter((x) => x.u === '/lancer').length - n0].join('/');
    });
    await essai('e9', async () => { // LB2 (Q7 ; PU-G-118 et PU-G-119) : une proposition d'une visite précédente (cadre NEUF, 115 s d'âge) n'est jamais montrée ni annoncée et est effacée dans Q ; le MÊME cadre rechargé dans la même visite la retrouve
      await scenario({ prop: valide(ID(91), { expire_ms: 5000, arme_apres_ms: 600 }), lancers: [] });
      const n0 = (await journal()).filter((x) => x.u === '/annuler').length;
      await q.naviguer(); await pause(3500);
      const annule = await attendreValeur(async () => (await journal()).filter((x) => x.u === '/annuler').length - n0, (n) => n >= 1); // l'effacement part du client : attendu, jamais supposé arrivé en 3,5 s
      const msgs = JSON.parse(await s.ev('JSON.stringify(window.__msgs)')).filter((m) => m.d === 'proposition').length;
      const nul = await q.ev(`document.querySelectorAll('#proposition').length`);
      await scenario({ prop: valide(ID(92), { expire_ms: 5000, arme_apres_ms: 600 }), lancers: [] });
      await q.recharger(`${OQ}/?theme=light`); const garde = await q.attendre(`!!document.getElementById('proposition')`, 'proposition gardée', MS).then(() => true, () => false);
      r.e9 = [nul, msgs, annule >= 1, garde].join('/');
    });
    const ENTREE_TOUCHE = (type, extra = {}) => s.send('Input.dispatchKeyEvent', Object.assign({ type, key: 'Enter', code: 'Enter', windowsVirtualKeyCode: 13 }, extra)), SUR_TERMINAL = `!!document.activeElement && document.activeElement.className === 'xterm-helper-textarea'`;
    const TERMINAL_FOCALISE = `document.hasFocus() && document.activeElement && document.activeElement.className === 'xterm-helper-textarea'`;
    // reprises(r0, pret) : pret = TERMINAL_FOCALISE (élément actif ET fenêtre focalisée) sous émulation de focus (E13, E14) ; SUR_TERMINAL par défaut (E10, E10b, E12) : sans émulation la fenêtre n'a pas le focus par construction, hasFocus() y est faux
    // reprises(r0) : six répétitions de l'Entrée tenue (cadence d'auto-répétition, 40 ms : c'est l'entrée testée) → 0 octet CR attendu après 400 ms ; puis Entrée fraîche → l'octet arrive PUIS reste stable (LB.E14, run 42405220695 : après 500 ms il arrivait parfois plus tard en CI Linux)
    const reprises = async (r0, pret = SUR_TERMINAL) => { await q.ev(`(() => { window.__kj = []; if (!window.__kjOn) { window.__kjOn = true; ['keydown', 'keyup'].forEach((t) => window.addEventListener(t, (e) => window.__kj.push(e), true)); } return true; })()`); for (let i = 0; i < 6; i++) { await ENTREE_TOUCHE('keyDown', { text: '\r', autoRepeat: true }); await pause(40); } await pause(400); const tenue = retours() - r0; await ENTREE_TOUCHE('keyUp'); await pause(100); await q.attendre(`window.__kj.some((e) => e.type === 'keyup')`, 'relâchement reçu par Q avant l\'Entrée fraîche'); await q.attendre(pret, 'saisie du terminal focalisée avant l\'Entrée fraîche'); const n1 = (await journal()).filter((x) => x.u === '/entree').length; await ENTREE_TOUCHE('keyDown', { text: '\r' }); await ENTREE_TOUCHE('keyUp'); await pause(500); const fraiche = await attendreEtStabiliser(() => retours() - r0 - tenue, (n) => n >= 1, { max: 3000 });
      if (fraiche < 1) { const e = await q.ev(`({ focus: document.hasFocus(), actif: document.activeElement && document.activeElement.className, vis: document.visibilityState, touches: (window.__kj || []).map((x) => x.type + (x.repeat ? ':repeat' : '') + (x.defaultPrevented ? ':annulee' : '')).join(',') })`).catch(() => null); const j = await journal(); console.error('DIAG reprises : Entrée fraîche perdue ; état de Q ' + JSON.stringify(e) + ' ; POST /entree avant/après la fraîche ' + n1 + '/' + j.filter((x) => x.u === '/entree').length + ' ; dernières requêtes ' + j.slice(-8).map((x) => x.m + ' ' + x.u + ' ' + x.st).join(', ')); } // trace (stderr, jamais dans le verdict) : où se perd l'octet
      return tenue + '/' + fraiche; };
    await essai('e10', async () => { // LB3-S (arbitrage Samuel, AskUserQuestion session principale, 2026-11-06, remarque du relecteur de LB1-LB2) : Entrée TENUE sur « Préparer » ; le focus revient au terminal après la réponse, les répétitions de la touche ne l'atteignent pas ; Entrée relâchée puis pressée de nouveau passe
      await scenario({ prop: valide(ID(101), { arme_apres_ms: 600 }), lancers: [] }); await q.naviguer();
      await q.attendre(`!!document.getElementById('proposition')`, 'bandeau de la proposition', MS); await attendreArme();
      await clic(`document.getElementById('proposition-phrase')`); await q.ev(`${LANCER}.focus()`);
      const touche = (type, extra = {}) => s.send('Input.dispatchKeyEvent', Object.assign({ type, key: 'Enter', code: 'Enter', windowsVirtualKeyCode: 13 }, extra));
      const r0 = retours(); await touche('keyDown', { text: '\r' });
      await q.attendre(`!document.getElementById('proposition')`, 'bandeau retiré après 204', MS);
      const foc = await q.attendre(`document.activeElement && document.activeElement.className`, 'focus rendu au terminal', MS);
      r.e10 = foc + '/' + await reprises(r0);
    });
    await essai('e10b', async () => { // LB3-S2 (F2) : le cas du TAP — aucune touche n'a été tenue au clavier sur « Préparer » (clic de souris : le relâchement de touche est parti au bouton, ou n'a jamais existé) ; le focus revient au terminal ; une Entrée FRAÎCHE y passe : exactement UN octet CR, jamais avalé par la retenue
      await scenario({ prop: valide(ID(102), { arme_apres_ms: 600 }), lancers: [] }); await q.naviguer();
      await q.attendre(`!!document.getElementById('proposition')`, 'bandeau de la proposition', MS); await attendreArme();
      const r0 = retours(); await clic(LANCER);
      await q.attendre(`!document.getElementById('proposition')`, 'bandeau retiré après 204', MS); await q.attendre(SUR_TERMINAL, 'focus rendu au terminal', MS);
      await ENTREE_TOUCHE('keyDown', { text: '\r' }); await ENTREE_TOUCHE('keyUp');
      r.e10b = String(await attendreEtStabiliser(() => retours() - r0, (n) => n >= 1, { pas: 500, max: 10000 })); // l'octet frais se lit une fois arrivé, puis 500 ms sans second octet
    });
    await essai('e11', async () => { // LB3-S (finding c) : la référence d'âge est la durée servie par Q (duree_ms), pas une constante : une proposition FRAÎCHE d'une durée courte est montrée ; une ancienne d'une durée longue est effacée
      await scenario({ prop: valide(ID(111), { duree_ms: 10000, expire_ms: 9000, arme_apres_ms: 600 }), lancers: [] }); await q.naviguer();
      const courte = await q.attendre(`!!document.getElementById('proposition')`, 'proposition fraîche, durée courte', MS).then(() => true, () => false);
      await scenario({ prop: valide(ID(112), { duree_ms: 600000, expire_ms: 300000, arme_apres_ms: 600 }), lancers: [] }); const n0 = (await journal()).filter((x) => x.u === '/annuler').length;
      await q.naviguer(); await pause(3500);
      const annule = await attendreValeur(async () => (await journal()).filter((x) => x.u === '/annuler').length - n0, (n) => n >= 1), nul = await q.ev(`document.querySelectorAll('#proposition').length`);
      await scenario({ prop: valide(ID(113), { duree_ms: 600000, expire_ms: 599000, arme_apres_ms: 600 }), lancers: [] });
      const temoin = await q.attendre(`!!document.getElementById('proposition')`, 'témoin : proposition fraîche, durée longue', MS).then(() => true, () => false);
      r.e11 = [courte, nul, annule >= 1, temoin].join('/');
    });
    await essai('e12', async () => { // LB3-S2 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-07, option A) : la retenue de l'Entrée tenue couvre CHAQUE bouton qui rend le focus au terminal (Annuler, Abandonner, Coller, Relancer le shell) ; Entrée maintenue sur le bouton, répétitions après le retour du focus : 0 CR ; puis Entrée fraîche : exactement 1
      const cycle = async (focaliser) => {
        const r0 = retours(); await focaliser(); await ENTREE_TOUCHE('keyDown', { text: '\r' });
        await q.attendre(SUR_TERMINAL, 'focus rendu au terminal', MS);
        return reprises(r0);
      };
      const bouton = (zone, texte) => `[...document.querySelectorAll('${zone} button')].find((x) => x.textContent === ${JSON.stringify(texte)})`;
      const coller = async () => { await q.ev(`(() => { const dt = new DataTransfer(); dt.setData('text/plain', 'a\\u200bb'); document.getElementById('terminal').dispatchEvent(new ClipboardEvent('paste', { clipboardData: dt, bubbles: true, cancelable: true })); return true; })()`); await q.attendre(`!!document.getElementById('collage')`, 'bandeau du collage', MS); };
      const sortie = [];
      await scenario({ prop: valide(ID(121), { arme_apres_ms: 600 }), lancers: [] }); await q.naviguer(); await q.attendre(`!!document.getElementById('proposition')`, 'bandeau de la proposition', MS);
      sortie.push('annuler:' + await cycle(async () => { await clic(`document.getElementById('proposition-phrase')`); await q.ev(`${ANNULER}.focus()`); }));
      await scenario({ prop: null }); await q.naviguer(); await coller();
      sortie.push('abandonner:' + await cycle(async () => { await clic(`document.querySelector('#collage .vf-q-texte')`); await q.ev(`${bouton('#collage', 'Annuler')}.focus()`); }));
      await coller();
      sortie.push('coller:' + await cycle(async () => { await clic(`document.querySelector('#collage .vf-q-texte')`); await q.ev(`${bouton('#collage', 'Coller')}.focus()`); }));
      await scenario({ prop: null, fin: true }); await q.naviguer(); await q.attendre(`!!${bouton('#etat', 'Relancer le shell')}`, 'bandeau du shell terminé', MS);
      sortie.push('relancer:' + await cycle(async () => { await clic(`document.querySelector('#etat .vf-q-texte')`); await q.ev(`${bouton('#etat', 'Relancer le shell')}.focus()`); }));
      r.e12 = sortie.join('|');
    });
    // LB3-S3 (F1 de la revue de a83890da..45a2396e ; arbitrage Samuel, AskUserQuestion session principale, 2026-11-07, « et tout autre bouton du même genre ») : la retenue est posée sur la PRISE DE FOCUS du terminal lui-même, pas sur chaque appelant.
    // Le vrai client de Q tourne dans l'iframe de P ; P est ici une page minimale qui reproduit `cadre.focus()` de la pastille du tiroir (vf-cockpit-terminal-tiroir.mjs, ouvrir(true)) : un bouton de P dont l'Entrée (keydown) donne le focus à l'iframe.
    const PASTILLE = `(() => { const b = document.createElement('button'); b.id = 'pastille-t'; b.textContent = 'Terminal'; b.style.cssText = 'position:fixed;right:0;bottom:0;z-index:100000'; b.addEventListener('keydown', (e) => { if (e.key === 'Enter') document.querySelector('iframe[data-t]').focus(); }); document.body.appendChild(b); b.focus(); return document.activeElement.id; })()`;
    await essai('e13', async () => { // chemin PARENT : Entrée tenue sur la pastille de P, qui donne le focus à l'iframe de Q ; les répétitions qui suivent n'atteignent pas le shell ; puis Entrée fraîche : 1
      await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
      await scenario({ prop: null, lancers: [] }); await q.naviguer(); await s.ev(`document.querySelector('iframe[data-t]').focus()`); await q.attendre(TERMINAL_FOCALISE, 'terminal focalisé', MS);
      const sur = await s.ev(PASTILLE); const r0 = retours();
      await ENTREE_TOUCHE('keyDown', { text: '\r' }); await q.attendre(TERMINAL_FOCALISE, 'focus donné au terminal par le parent', MS);
      const premiere = retours() - r0;
      r.e13 = [sur, premiere, await reprises(r0 + premiere, TERMINAL_FOCALISE)].join('/');
    });
    await essai('e14', async () => { // chemin « retour d'onglet » : le focus quitte le terminal, une Entrée est tenue, l'événement focus de la fenêtre de Q redonne le focus au terminal (écouteur window.focus du client) ; répétitions : 0 ; fraîche : 1
      await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
      await scenario({ prop: null, lancers: [] }); await q.naviguer(); await s.ev(`document.querySelector('iframe[data-t]').focus()`); await q.attendre(TERMINAL_FOCALISE, 'terminal focalisé', MS);
      await q.ev(`(() => { document.querySelector('.xterm-helper-textarea').blur(); return true; })()`);
      const r0 = retours(); await ENTREE_TOUCHE('keyDown', { text: '\r' });
      await q.ev(`(() => { window.dispatchEvent(new Event('focus')); return true; })()`); await q.attendre(TERMINAL_FOCALISE, 'focus rendu au terminal par la fenêtre', MS);
      r.e14 = await reprises(r0, TERMINAL_FOCALISE);
      await s.send('Emulation.setFocusEmulationEnabled', { enabled: false });
    });
    return JSON.parse(JSON.stringify(r).split(secret).join('<secret>'));
  }

  if (mode === 'focus') {
    // F1 (audit) : le scénario de l'audit. Faux P avec un champ de saisie FOCALISÉ avant la création du cadre de Q ; le cadre démarre, une proposition arrive, des frappes partent.
    // emu : émulation de focus de Chrome (fenêtre focalisée) ; sans elle, fenêtre non focalisée. Dans les deux cas : les frappes vont au champ de P, jamais à l'entrée du shell de Q.
    await scenario({ prop: null });
    if (emu) await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
    await s.naviguer(`${OQ}/`); await s.ev(`localStorage.setItem('vf.terminal.secret', ${JSON.stringify(secret)})`);
    await s.naviguer(`${OP}/project.html`); await s.attendre(`document.readyState === 'complete'`, 'page P', MS);
    await s.ev(`(() => { const i = document.createElement('input'); i.id = 'champP'; i.style.cssText = 'position:fixed;left:0;top:0'; document.body.appendChild(i); i.focus();
      const f = document.createElement('iframe'); f.dataset.t = '1'; f.setAttribute('sandbox', ${JSON.stringify(SBXQ)}); f.style.cssText = 'position:fixed;left:0;bottom:0;width:100vw;height:300px;border:0'; f.src = ${JSON.stringify(OQ + '/?theme=dark')}; document.body.appendChild(f); return true; })()`);
    await essai('f1', async () => {
      await s.attendre(`window.__msgs.some((m) => m.d === 'ready')`, 'cadre de Q prêt', AM);
      const fin = Date.now() + MS; while (Date.now() < fin && !(await journal()).some((x) => x.u === '/flux')) await pause(100); // le terminal de Q est démarré
      await pause(600);
      await scenario({ prop: valide(ID_A), lancers: [] });
      await s.attendre(`window.__msgs.some((m) => m.d === 'proposition')`, 'message proposition', MS);
      await trouverCtx(s); await q.attendre(`!!document.getElementById('proposition')`, 'bandeau dans Q', MS);
      await pause(500);
      for (const ch of 'abc') { await s.send('Input.dispatchKeyEvent', { type: 'keyDown', key: ch, text: ch, code: 'Key' + ch.toUpperCase() }); await s.send('Input.dispatchKeyEvent', { type: 'keyUp', key: ch, code: 'Key' + ch.toUpperCase() }); }
      await pause(1200);
      const champ = await s.ev(`document.getElementById('champP').value`), actif = await s.ev(`document.activeElement.id || document.activeElement.tagName`);
      r.f1 = [champ, actif, entrees()].join('/');
    });
    return JSON.parse(JSON.stringify(r).split(secret).join('<secret>'));
  }

  if (mode === 'focusvue') {
    // L2 (audit du lot 3) : carte « refuse » et bandeau « termine » montés par la vue dans le cadre de Q, sans geste, pendant qu'un champ de P est focalisé : les frappes abc puis Entrée vont au champ de P,
    // aucun bouton du cadre ne s'active. cadre:true (témoin positif) : P donne d'abord le focus au cadre, la vue prend alors le focus de son bouton (comportement de la Phase 71).
    const { quoi = 'carte', cadre = false } = JSON.parse(brut);
    await scenario({ prop: null });
    if (emu) await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
    await s.naviguer(`${OQ}/`); await s.ev(`localStorage.setItem('vf.terminal.secret', ${JSON.stringify(secret)})`);
    await s.naviguer(`${OP}/project.html`); await s.attendre(`document.readyState === 'complete'`, 'page P', MS);
    await s.ev(`(() => { const i = document.createElement('input'); i.id = 'champP'; i.style.cssText = 'position:fixed;left:0;top:0'; document.body.appendChild(i); i.focus();
      const f = document.createElement('iframe'); f.dataset.t = '1'; f.setAttribute('sandbox', ${JSON.stringify(SBXQ)}); f.style.cssText = 'position:fixed;left:0;bottom:0;width:100vw;height:300px;border:0'; f.src = ${JSON.stringify(OQ + '/?theme=dark')}; document.body.appendChild(f); return true; })()`);
    await essai('l2', async () => {
      await s.attendre(`window.__msgs.some((m) => m.d === 'ready')`, 'cadre de Q prêt', AM);
      const fin = Date.now() + MS; while (Date.now() < fin && !(await journal()).some((x) => x.u === '/flux')) await pause(100);
      await pause(600); await trouverCtx(s);
      if (cadre) await s.ev(`document.querySelector('iframe[data-t]').focus()`); else await s.ev(`document.getElementById('champP').focus()`);
      if (emu) await q.attendre(cadre ? `document.hasFocus()` : `!document.hasFocus()`, cadre ? 'focus du cadre de Q' : 'focus rendu à P'); else await pause(300); // la vue ne prend le focus de son bouton que si le cadre l'a (hasFocus au montage)
      await q.ev(`window.__act = 0; window.vfTermVue.${quoi === 'carte' ? "carte('refuse'" : "bandeau('termine'"}, ${quoi === 'carte' ? '' : '{ code: 0 }, '}() => { window.__act++; }); true`);
      await pause(500);
      for (const ch of 'abc') { await s.send('Input.dispatchKeyEvent', { type: 'keyDown', key: ch, text: ch, code: 'Key' + ch.toUpperCase() }); await s.send('Input.dispatchKeyEvent', { type: 'keyUp', key: ch, code: 'Key' + ch.toUpperCase() }); }
      await s.send('Input.dispatchKeyEvent', { type: 'keyDown', key: 'Enter', code: 'Enter', windowsVirtualKeyCode: 13 }); await s.send('Input.dispatchKeyEvent', { type: 'keyUp', key: 'Enter', code: 'Enter', windowsVirtualKeyCode: 13 });
      await pause(800);
      const champ = await s.ev(`document.getElementById('champP').value`), actif = await s.ev(`document.activeElement.id || document.activeElement.tagName`);
      const bouton = await q.ev(`document.activeElement.tagName === 'BUTTON'`), act = await q.ev(`window.__act`), montee = await q.ev(`!!document.querySelector('#zone-etat button, .vf-q-carte button, .vf-q-bandeau button')`);
      r.l2 = [champ, actif, bouton, act, montee].join('/');
    });
    return JSON.parse(JSON.stringify(r).split(secret).join('<secret>'));
  }

  if (mode === 'sp1') {
    // SP-1 : rechargement sans fragment, tiroir fermé (aucun cadre de Q), clic « Lancer » sur une carte : le POST rend 202, le tiroir s'ouvre, le bandeau apparaît dans Q, sans prendre le focus de P.
    await scenario({ prop: null, apres: valide(ID_A) });
    if (emu) await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
    await s.naviguer(`${OQ}/`); await s.ev(`localStorage.setItem('vf.terminal.secret', ${JSON.stringify(secret)})`);
    await s.naviguer(`${OP}/project.html?sp1=1`); await s.attendre(`document.readyState === 'complete'`, 'page P', MS);
    await essai('sp1', async () => {
      await s.attendre(`!!document.querySelector('#panel button')`, 'carte avec son bouton Lancer', MS);
      const avant = await s.ev(`document.querySelectorAll('iframe').length`);
      const p = await positionPosee(s.ev, `document.querySelector('#panel button')`), c = { x: p.cx, y: p.cy }; // la carte se pose avant qu'on y vise le clic
      await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: c.x, y: c.y });
      await s.send('Input.dispatchMouseEvent', { type: 'mousePressed', x: c.x, y: c.y, button: 'left', clickCount: 1 });
      await s.send('Input.dispatchMouseEvent', { type: 'mouseReleased', x: c.x, y: c.y, button: 'left', clickCount: 1 });
      await s.attendre(`/Confirmez-la dans le terminal/.test(document.getElementById('panel').textContent)`, 'message de la carte', MS);
      const cadre = await s.attendre(`document.querySelectorAll('iframe').length === 1`, 'cadre de Q monté', MS).then(() => true, () => false);
      let bandeau = false; if (cadre) { await trouverCtx(s).catch(() => {}); if (ctx) bandeau = await q.attendre(`!!document.getElementById('proposition')`, 'bandeau dans Q', MS).then(() => true, () => false); }
      const focusP = await s.ev(`document.activeElement.tagName !== 'IFRAME'`);
      r.sp1 = [avant, cadre, bandeau, focusP].join('/');
    });
    return JSON.parse(JSON.stringify(r).split(secret).join('<secret>'));
  }

  if (mode === 'froid') {
    await scenario({ prop: valide(ID_A), lancers: [] }); await q.naviguer(`${OQ}/?theme=dark`, 'nulle');
    const recus = async () => JSON.parse(await s.ev('JSON.stringify(window.__msgs)')).filter((m) => m.d === 'proposition');
    await essai('e8', async () => { // cadre masqué : une annonce avant visible(), rien d'autre ne démarre ; agrandi : bandeau, flux, toujours UNE annonce
      const fin = Date.now() + MS; let n = 0; while (Date.now() < fin && (n = (await recus()).length) < 1) await pause(100);
      await pause(1500);
      const msgs = await recus(), j = await journal();
      const dans = await q.ev(`({ xterm: document.querySelectorAll('.xterm').length, prop: document.querySelectorAll('#proposition').length })`);
      const masque = [msgs.length, msgs.every((m) => m.o === OQ), dans.xterm, dans.prop, j.filter((x) => ['/flux', '/lancer', '/entree'].includes(x.u)).length, j.filter((x) => x.u === '/proposition').length >= 1].join('/');
      await s.ev(`(() => { const f = document.querySelector('iframe[data-t]'); f.style.width = '100vw'; f.style.height = '100vh'; return true; })()`);
      await q.attendre(`!!document.getElementById('proposition')`, 'bandeau après agrandissement', MS);
      const ap = await attendreEtStabiliser(async () => ({ flux: (await journal()).filter((x) => x.u === '/flux').length >= 1, n: (await recus()).length }), (a) => a.flux && a.n >= 1); // flux ouvert par visible() : lu une fois ouvert
      r.e8 = [masque, ap.flux, ap.n].join('|');
    });
    return JSON.parse(JSON.stringify(r).split(secret).join('<secret>'));
  }
  return { erreur: 'mode inconnu ' + mode };
}, { csp: true });
JS

# --- outils de la suite ---------------------------------------------------------------------------------------------------------------------------------
rj() { printf '%s\n' "$1" | node "$AUX/ev.mjs" "$2" 2>/dev/null; }
# verdict d'une sonde : « sain » si l'expression est vraie, « rouge » si elle est fausse, « plante » si le scénario a rendu une erreur (jamais un rouge pour une mauvaise raison)
verdict() { rj "$1" "(j.erreur ? 'plante: ' + j.erreur : ($2) ? 'sain' : 'rouge')"; }
mutant() { # mutant <nom> <fichier> <expression-sed> -> MUT_DIR ; code 1 si la cible manque ou si la copie n'a pas changé
  local d="$WORK/mut-$1" f; rm -rf "$d"; mkdir -p "$d"
  for x in page style vue client; do cp "$SCRIPTS/vf-cockpit-terminal-$x.mjs" "$d/"; done
  MUT_DIR="$d"; f="$d/$2"; [ -f "$f" ] || return 1
  cp "$f" "$f.orig"; sed -i.bak "$3" "$f"; local r=0; cmp -s "$f" "$f.orig" && r=1; rm -f "$f.orig" "$f.bak"; return $r
}
doubles() { node "$AUX/doubles.mjs" "$1/vf-cockpit-terminal-client.mjs" "$2" 2>&1 | tail -1; } # doubles <dossier> <scénario>
FN=0; VF_CLIENT_MS0="${VF_CLIENT_MS:-}"
faux() { # faux <dossier-des-modules> -> FQ FP FSEC FRUN FPID ; un seul processus, deux ports
  # un mutant (modules ou injection copiés) peut casser l'amorçage : ses attentes restent à 20 s (jamais l'AMORCE de 600 s) ; la suite normale garde l'amorçage large
  if [ "$1" != "$SCRIPTS" ] || [ "${FAUX_INJ:-$SCRIPTS}" != "$SCRIPTS" ]; then export VF_CLIENT_MS=20000; elif [ -n "$VF_CLIENT_MS0" ]; then export VF_CLIENT_MS="$VF_CLIENT_MS0"; else unset VF_CLIENT_MS; fi
  port; FQ="$PORT"; port; FP="$PORT"; FSEC="$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")"
  FN=$((FN+1)); FRUN="$WORK/run/$FN"; mkdir -p "$FRUN"
  FAUX_INJ="${FAUX_INJ:-}" node "$AUX/faux.mjs" "$1" "$ENG" "$FQ" "$FP" "$FSEC" "$FRUN" > "$FRUN/faux.out" 2>&1 < /dev/null &
  FPID=$!; PIDS+=($FPID)
  for _ in $(seq 1 100); do [ -s "$FRUN/pret" ] && break; sleep 0.1; done
}
unfaux() { vf_hyg_stop "$FPID"; PORT_NEXT="$PORT_LO"; }
navig() { node "$AUX/chrome-bandeau.mjs" "$CHROME" "$1" "{\"P\":$FP,\"Q\":$FQ,\"secret\":\"$FSEC\",\"run\":\"$FRUN\"${2:+,$2}}"; } # navig <mode> [json-supplémentaire]
V22_SAIN='124/BUTTON=Annuler>proposition-ligne>proposition-chat>proposition-lancer/proposition-chat>proposition-ligne>BUTTON=Annuler>proposition-mode/true;300/BUTTON=Annuler>proposition-ligne>proposition-chat>proposition-lancer/proposition-chat>proposition-ligne>BUTTON=Annuler>proposition-mode/true;450/BUTTON=Annuler>proposition-ligne>proposition-chat>proposition-lancer/proposition-chat>proposition-ligne>BUTTON=Annuler>proposition-mode/true' # LB.V22 et son mutant : les arrêts nommés de chaque parcours, puis « true » (tous visibles, hors du pied)
V25B_SAIN='tenue:true:true:absente;proposition:true:absente;carte:true:absente;etat-124px:true:true;etat-300px:true:true;etat-100vh:true:true' # LB.V25b et ses mutants
run_vue() { faux "$1"; VJ="$(navig vue "${2:-}")"; unfaux; } # run_vue <dossier> [json]

# --- LB.S : statique ------------------------------------------------------------------------------------------------------------------------------------
echo "=== LB.S — scripts propres de la page servie (statique) ==="
node "$AUX/pagegen.mjs" "$SCRIPTS" "$ENG" dark "$WORK/page.html"; ST="$(node "$AUX/stat.mjs" "$WORK/page.html")"
LV="$(node "$AUX/lignes.mjs" "$SCRIPTS/vf-cockpit-terminal-vue.mjs")"; LC="$(node "$AUX/lignes.mjs" "$SCRIPTS/vf-cockpit-terminal-client.mjs")"
assert_eq "LB.S0 — témoin : la page de Q a ses quatre <script> et ses scripts propres sont vivants (propres > 200)" "$(rj "$ST" 'j.scripts+"/"+(j.propres>200)')" "4/true"
assert_eq "LB.S1 — adresse : location.search = 2, URLSearchParams = 0, searchParams = 0, location.href = 0 (baselines mesurées avant ce plan)" "$(rj "$ST" 'j.search+"/"+j.urlsp+"/"+j.searchp+"/"+j.href')" "2/0/0/0"
assert_eq "LB.S1 — canal : écouteurs de messages entrants = 0, postMessage( = 1 (dans emettre), postMessage avec l'étoile = 0" "$(rj "$ST" 'j.ecoute+"/"+j.postmsg+"/"+j.etoile')" "0/1/0"
assert_eq "LB.S1 — aucune écriture innerHTML, outerHTML ni insertAdjacentHTML ; aucun appel à confirm(" "$(rj "$ST" 'j.html+"/"+j.confirm')" "0/0"
assert_eq "LB.S1 — lignes de littéral de couleur : vue 6 / client 0 ; .style : 0 / 0 ; cssText : 0 / 0 ; rgb( ou hsl( : vue 3 / client 0 ; <chiffre>px : vue 0 / client 1" \
  "$(rj "$LV" 'j.couleur+"/"+j.style+"/"+j.css+"/"+j.rgb+"/"+j.px')|$(rj "$LC" 'j.couleur+"/"+j.style+"/"+j.css+"/"+j.rgb+"/"+j.px')" "6/0/0/3/0|0/0/0/0/1"
assert_eq "LB.S2 — la table MESSAGES a exactement neuf clés dont proposition ; l'unique postMessage( vise cfg.origineP" "$(rj "$ST" 'j.cles+"/"+j.proposition+"/"+j.cible')" "9/true/true"
assert_eq "LB.S3 — client <= 290 lignes, vue <= 302 lignes (le chiffre mesuré : client $(rj "$LC" j.lignes), vue $(rj "$LV" j.lignes)) ; le plafond a été relevé de 280/215 par le lot 8 (LB2), qui ajoute à la vue les phrases en clair, une explication par mode et pour la case du chat, le compte à rebours et le bandeau expiré ; celui de la vue est passé de 290 à 310 pour la consigne « Appuyez sur Entrée » qui reste visible après la préparation (P5, revue du 2026-11-08 : décision déléguée par Samuel, message session principale, 2026-11-08, consignée en § 10 du rapport GLOBAL, 599a42a5, option recommandée : relever le plafond plutôt que compresser le code) ; F6c (3e tour) : remis au plus juste, 301 lignes mesurées plus une ligne d'avance, car les correctifs F2, F4 et F6b tiennent dans des lignes existantes ou dans la feuille de style (décision déléguée par Samuel, message session principale, 2026-11-08, consignée en § 10 du rapport GLOBAL, 599a42a5, option recommandée : remettre le plafond au plus juste après les ajouts)" "$(rj "$LC" 'j.lignes<=290')/$(rj "$LV" 'j.lignes<=302')" "true/true"
assert_eq "LB.S4 — aucun fiabilite ni gouvernance dans la vue ni le client ; aucun appel confirm(" "$(rj "$LV" 'j.compartiments+"/"+j.confirm')|$(rj "$LC" 'j.compartiments+"/"+j.confirm')" "0/0|0/0"
regles_prop() { grep -F '#proposition' "$1"; } # les règles de la proposition dans la feuille de Q : toutes portent #proposition
# LB3-S2 (F6) : R3 du plan 72-08 (« seulement les variables CSS existantes ») couvre TOUTES les règles que le lot a ajoutées : #proposition, #accueil, .vf-lancer-armement, la carte tassée (.vf-q-carte { max-height … } et sa requête de média)
regles_lot() { grep -E '#proposition|#accueil|vf-lancer-armement|vf-q-carte \{ max-height|@media \(max-height' "$1"; }
# LB3-S3 (F3) : liste noire des couleurs dans les règles du lot : hexadécimaux, rgb( hsl( hwb( lab( lch( oklab( oklch( color-mix( color( light-dark( device-cmyk(, et tous les NOMS de couleur CSS (transparent et currentColor compris) ; hors usage autorisé : « stroke: currentColor » (le picto, préexistant, mesuré : seul emploi d'un mot-couleur dans le lot)
NOMS_COULEUR='aliceblue|antiquewhite|aqua|aquamarine|azure|beige|bisque|black|blanchedalmond|blue|blueviolet|brown|burlywood|cadetblue|chartreuse|chocolate|coral|cornflowerblue|cornsilk|crimson|cyan|darkblue|darkcyan|darkgoldenrod|darkgray|darkgreen|darkgrey|darkkhaki|darkmagenta|darkolivegreen|darkorange|darkorchid|darkred|darksalmon|darkseagreen|darkslateblue|darkslategray|darkslategrey|darkturquoise|darkviolet|deeppink|deepskyblue|dimgray|dimgrey|dodgerblue|firebrick|floralwhite|forestgreen|fuchsia|gainsboro|ghostwhite|gold|goldenrod|gray|green|greenyellow|grey|honeydew|hotpink|indianred|indigo|ivory|khaki|lavender|lavenderblush|lawngreen|lemonchiffon|lightblue|lightcoral|lightcyan|lightgoldenrodyellow|lightgray|lightgreen|lightgrey|lightpink|lightsalmon|lightseagreen|lightskyblue|lightslategray|lightslategrey|lightsteelblue|lightyellow|lime|limegreen|linen|magenta|maroon|mediumaquamarine|mediumblue|mediumorchid|mediumpurple|mediumseagreen|mediumslateblue|mediumspringgreen|mediumturquoise|mediumvioletred|midnightblue|mintcream|mistyrose|moccasin|navajowhite|navy|oldlace|olive|olivedrab|orange|orangered|orchid|palegoldenrod|palegreen|paleturquoise|palevioletred|papayawhip|peachpuff|peru|pink|plum|powderblue|purple|rebeccapurple|red|rosybrown|royalblue|saddlebrown|salmon|sandybrown|seagreen|seashell|sienna|silver|skyblue|slateblue|slategray|slategrey|snow|springgreen|steelblue|tan|teal|thistle|tomato|turquoise|violet|wheat|white|whitesmoke|yellow|yellowgreen|transparent|currentcolor|canvas|canvastext|accentcolor|accentcolortext|highlight|highlighttext|buttonface|buttontext|linktext|field|fieldtext'
couleurs_lot() { regles_lot "$1" | sed -E 's/stroke: *currentColor//g' | grep -ciE "#[0-9a-f]{3,8}([^0-9a-z_-]|\$)|(^|[^a-z0-9_-])(rgb|hsl|hwb|lab|lch|oklab|oklch|color-mix|color|light-dark|device-cmyk)a?\(|(^|[^a-z0-9_.#-])($NOMS_COULEUR)([^a-z0-9_-]|\$)" || true; }
px_lot() { regles_lot "$1" | grep -oE '[0-9]+(\.[0-9]+)?px' | LC_ALL=C sort | tr '\n' ' '; } # tous les littéraux en px des règles du lot, triés
echem_prop() { regles_prop "$1" | grep -cE '(font-size|width|height): *[0-9.]+em' || true; }
nb_prop() { [ "$(regles_prop "$1" | wc -l | tr -d ' ')" -ge 8 ] && echo ok || echo vide; } # témoin : les règles sont bien trouvées (jamais un zéro obtenu sur une sélection vide)
nb_lot() { [ "$(regles_lot "$1" | wc -l | tr -d ' ')" -ge 15 ] && echo ok || echo vide; }
# EXCEPTIONS NOMMÉES : les seuls px du lot sans variable équivalente (aucun nouveau jeton, DESIGN.md) ; égalité d'ensemble, jamais une liste noire : un px de plus OU de moins rougit
#  12.5px x2 : taille du texte courant dense (DESIGN.md §3), aide et liste des modes ; la feuille n'a aucune variable de taille de police
#  44px x1   : hauteur du bandeau d'état (valeur de .vf-q-bandeau, préexistante), dans la marge de la proposition ; aucune variable
#  560px x1  : largeur de la carte sur un cadre bas ; aucune variable
#  240px x1  : seuil de la requête de média (max-height) ; une propriété personnalisée ne s'emploie pas dans une requête de média
EXC_PX_LOT="12.5px 12.5px 240px 44px 560px "
assert_eq "LB.S4 — aucune valeur de style en dur (R3, plan 72-08, élargi au lot 8 LB3-S2) : (1) aucun littéral de couleur, rgb( ni hsl( dans les règles ajoutées par le lot (témoin : elles sont trouvées) ; (2) leurs littéraux en px sont EXACTEMENT les exceptions nommées (12.5px x2 taille de texte, 44px hauteur du bandeau d'état, 560px largeur de carte, 240px seuil de média) ; (3) la page et le tiroir ne sont pas modifiés (git)" "$(nb_lot "$SCRIPTS/vf-cockpit-terminal-style.mjs")/$(couleurs_lot "$SCRIPTS/vf-cockpit-terminal-style.mjs")/$(px_lot "$SCRIPTS/vf-cockpit-terminal-style.mjs")/$(git -C "$SCRIPTS" status --porcelain -- vf-cockpit-terminal-page.mjs vf-cockpit-terminal-tiroir.mjs | wc -l | tr -d ' ')" "ok/0/$EXC_PX_LOT/0"
assert_eq "LB.S5 — échelle de DESIGN.md (§3 texte courant dense 12-12,5 px, §7 pictos 16 x 16) : aucune taille en em dans les règles de la proposition ; témoin : l'aide et les modes sont à 12.5px et le picto à 16 px par le jeton --sp-16 (F6 : plus de littéral)" "$(echem_prop "$SCRIPTS/vf-cockpit-terminal-style.mjs")/$(regles_prop "$SCRIPTS/vf-cockpit-terminal-style.mjs" | grep -c 'font-size: 12.5px')/$(regles_prop "$SCRIPTS/vf-cockpit-terminal-style.mjs" | grep -c 'svg.i { width: var(--sp-16); height: var(--sp-16)')" "0/2/1"

# --- LB.C : client sans navigateur -----------------------------------------------------------------------------------------------------------------------
echo "=== LB.C — client de Q, doublures sans navigateur ==="
CJ="$(doubles "$SCRIPTS" precoce)"
assert_eq "LB.C1 — GET /proposition part dès l'initialisation, avec X-VF-Terminal et X-VF-Onglet (période entre 500 et 2000 ms, une seule requête en vol : réponse jamais rendue)" \
  "$(verdict "$CJ" 'j.premiere==="/proposition" && /^a{64}$/.test(j.secret) && j.onglet && j.periode>=500 && j.periode<=2000 && j.n===1')" "sain"
CJ="$(doubles "$SCRIPTS" formes)"
assert_eq "LB.C2 — réponses hors forme (null, tableau, sans champs, id hostile ou court, ligne manquante ou à caractère de contrôle ou de 401 caractères, bloquants non tableau, code de 41 caractères, arme_apres_ms hors bornes, expire_ms nul) : vue.proposition jamais appelée ; témoin : la valide s'affiche une fois" \
  "$(verdict "$CJ" 'j.rejete===true && j.valide.n===1 && j.valide.id==="a1b2c3d4e5f60718293a4b5c6d7e8f90" && j.valide.modeInitial==="string" && j.valide.cb==="function/function"')" "sain"
CJ="$(doubles "$SCRIPTS" suivi)"
assert_eq "LB.C2 — même identifiant aux sondages suivants : une seule fois ; identifiant nouveau : seconde fois ; un message proposition par identifiant nouveau" \
  "$(verdict "$CJ" 'j.a1.n===1 && j.a1.msgs===1 && j.a2.n===1 && j.a2.msgs===1 && j.b.n===2 && j.b.msgs===2')" "sain"
assert_eq "LB.C2 — aucune alors que le client a affiché : vue.proposition(null) ; statut non OK (404, 401, 403) : rien retiré ; message strictement proposition, origine cible = cfg.origineP, jamais d'étoile" \
  "$(verdict "$CJ" 'j.c.nulls===1 && j.c.n===2 && j.c.msgs===2 && j.d.ajout===0 && j.e.nulls===2 && j.msg.n===3 && j.msg.strict && !j.msg.etoile && j.msg.autres==="ready"')" "sain"
CJ="$(doubles "$SCRIPTS" retard)"
assert_eq "LB.C2 — un sondage en retard (réponse retenue puis rendue après le 204, l'annulation ou un 404) ne remonte pas le bandeau et n'émet rien ; témoin : une proposition d'identifiant nouveau s'affiche" \
  "$(verdict "$CJ" 'j.ok.st==="ok" && j.ok.dv===0 && j.ok.dm===0 && j.annule.dv===0 && j.annule.dm===0 && j.absente.st==="absente" && j.absente.dv===0 && j.absente.dm===0 && j.temoin===1')" "sain"
CJ="$(doubles "$SCRIPTS" statuts)"
assert_eq "LB.C3 — cb.lancer('acceptEdits') : POST /lancer, Content-Type application/json, secret et onglet, corps EXACTEMENT {\"id\":…,\"mode\":\"acceptEdits\"}, aucune autre requête" \
  "$(verdict "$CJ" 'j.cas[0].nreq===1 && j.cas[0].req.m==="POST" && j.cas[0].req.u==="/lancer" && j.cas[0].req.ct==="application/json" && /^a{64}$/.test(j.cas[0].req.sec) && j.cas[0].req.ong && j.cas[0].req.b===JSON.stringify({id:j.cas[0].req.id,mode:"acceptEdits"})')" "sain"
assert_eq "LB.C3 — statuts : 204 ok, 409 occupe, 425 attendre, 404 absente, 410 sans-session, 400 refus, 500 refus, exception reseau" \
  "$(verdict "$CJ" 'j.cas.length===8 && j.cas.every((c)=>c.st===c.attendu && c.nreq===1)')" "sain"
assert_eq "LB.C3 — un mode hors liste (bypassPermissions) rend refus SANS requête" "$(verdict "$CJ" 'j.hors.st==="refus" && j.hors.reqs===0')" "sain"
CJ="$(doubles "$SCRIPTS" mode)"
assert_eq "LB.C4 — présélection servie par Q (mode_retenu) : absence, valeurs forgées (bypassPermissions, HERITE, « default », __proto__, constructor, 5000 caractères, vide) = default ; valeurs valides retenues (même liste de douze valeurs qu'avant le plan 72-16, servie au lieu d'être lue du stockage)" \
  "$(verdict "$CJ" 'j.lu.join("|")==="absent=>default|bypassPermissions=>default|HERITE=>default|default =>default|__proto__=>default|constructor=>default|long=>default|=>default|default=>default|acceptEdits=>acceptEdits|plan=>plan|herite=>herite"')" "sain"
assert_eq "LB.C4 — le client n'écrit NI ne lit AUCUNE clé de stockage dont le nom contient « mode » (get, set, del) : ni avant, ni après un 204, ni après 409, 425, 400, 500 (zéro opération au lieu d'une seule écriture) ; témoin : le secret, lui, est lu ; le bandeau suivant le 204 présélectionne le mode servi (plan), inchangé après les échecs" \
  "$(verdict "$CJ" 'j.st204==="ok" && j.suivant==="plan" && j.opsMode.length===0 && j.secretLu===true && j.inchange.join(",")==="409:acceptEdits,425:acceptEdits,400:acceptEdits,500:acceptEdits"')" "sain"
CJ="$(doubles "$SCRIPTS" focus)"
assert_eq "LB.C5 — après le 204 : aucune requête /entree pendant 1,5 s (ni \\r, ni aucun octet) ; le focus du terminal est repris (témoin)" "$(verdict "$CJ" 'j.st==="ok" && j.entrees===0 && j.focus>=1')" "sain"
CJ="$(doubles "$SCRIPTS" annuler)"
assert_eq "LB.C6 — cb.annuler() : POST /annuler de corps EXACTEMENT {\"id\":…}, le bandeau ne revient pas (le serveur factice sert encore la même proposition) ; témoin : un identifiant nouveau s'affiche" \
  "$(verdict "$CJ" 'j.reqs.length===1 && j.reqs[0]==="POST /annuler {\"id\":\"a1b2c3d4e5f60718293a4b5c6d7e8f90\"}" && j.vue===0 && j.msgs===0 && j.temoin===1')" "sain"
CJ="$(doubles "$SCRIPTS" froid)"
assert_eq "LB.C7 — cas froid : fenêtre de taille nulle, une proposition servie : GET /proposition est parti, EXACTEMENT UN message proposition (origine cfg.origineP), vue.proposition PAS appelée, aucun Terminal, aucune requête /flux, /lancer ni /entree" \
  "$(verdict "$CJ" 'j.masque.sondage && j.masque.msgs===1 && j.masque.origine==="http://127.0.0.1:1" && j.masque.data===0 && j.masque.terms===0 && j.masque.interdit===0')" "sain"
assert_eq "LB.C7 — la fenêtre prend une taille : Terminal construit UNE fois, vue.proposition appelée UNE fois avec la même proposition, toujours UN seul message (aucune seconde émission)" \
  "$(verdict "$CJ" 'j.ouvert.terms===1 && j.ouvert.data===1 && j.ouvert.memeId && j.ouvert.msgs===1')" "sain"

CODES="$(node --input-type=module -e "import * as c from '$SCRIPTS/vf-cockpit-lancer-cibles.mjs'; console.log(JSON.stringify([...c.BLOQUANTS, ...c.AVERTISSEMENTS, ...c.AVERTISSEMENTS_RESERVES]))")" # ST-2 : liste des codes DÉRIVÉE du module de cibles réel
NCODES="$(node -e "console.log(JSON.parse(process.argv[1]).length)" "$CODES")"
# --- LB.V, LB.E, LB.P : navigateur ----------------------------------------------------------------------------------------------------------------------
if [ -n "$CHROME" ]; then
  echo "=== LB.V — vue du bandeau sous Chrome ==="
  run_vue "$SCRIPTS" "\"codes\":$CODES"; VJ0="$VJ"
  vv() { rj "$VJ0" "(j.erreur ? 'plante: ' + j.erreur : j.$1 !== undefined ? j.$1 : 'erreur: ' + ((j.erreurs || {}).$1 || 'étape absente'))"; }
  H="Lancement à confirmer"
  assert_eq "LB.V1 — #proposition : classes vf-q-bandeau vf-q-collage, role group, libellé de groupe ; sélecteur à quatre options dans l'ordre ; zone « Commande exacte » = lignes.default puis acceptEdits, herite (avec la note, sans --permission-mode), plan ; présélection modeInitial" \
    "$(vv v1)" "vf-q-bandeau vf-q-collage/group/$H/Mode de permission/default|Par défaut;acceptEdits|Accepter les modifications;plan|Plan (lecture seule);herite|Hérité du poste/true/Commande exacte/Lancement proposé : Planifie la Phase 72 du compartiment alpha/Annuler,Préparer dans le terminal/false/true/false/true/false/true/true/false/plan/true"
  assert_eq "LB.V2 — bloquants phase-finie et terminal-absent : deux lignes « Bloquant : <motif> », Lancer reste aria-disabled=true après arme_apres_ms ; avertissement : « Attention : <motif> » et Lancer s'arme ; code inconnu : « Contrôle non reconnu. » jamais le code brut" "$(vv v2)" "true/true/true/true/false"
  assert_eq "LB.V3 — clic de confiance à arme_apres_ms / 3 : cb.lancer jamais appelé ; après armement : appelé UNE fois avec le mode choisi ; un second clic pendant que la promesse est en vol : ignoré" "$(vv v3)" 'tôt/0/["default"]'
  assert_eq "LB.V4 — un click() programmatique (non fiable) sur Lancer armé : ignoré ; puis le clic de confiance part (témoin)" "$(vv v4)" "0/1"
  assert_eq "LB.V5 — intention et lignes hostiles : textes littéraux, aucun nœud créé, window.__M72 jamais posé, aucun attribut style, 0 violation de CSP" "$(vv v5)" "true/true/0/undefined/0/false/0/0"
  assert_eq "LB.V6 — avec un #collage ouvert, le bandeau est inséré AVANT lui : l'élément au centre du bouton « Coller » est dans #collage" "$(vv v6)" "true/true"
  assert_eq "LB.V7 — ok retire ; attendre : message, bouton redésarmé puis ré-armé ; occupe, sans-session, refus, reseau : message exact et Lancer actif, bandeau conservé ; absente retire" \
    "$(vv v7)" "ok=ok;attendre=ok;occupe=ok;sans-session=ok;refus=ok;reseau=ok;absente=ok"
  assert_eq "LB.V8 — proposition(null) retire sans exception tardive (minuterie arrêtée) ; un identifiant nouveau remplace (un seul #proposition) ; le focus va à Annuler au premier affichage seulement" "$(vv v8)" "false/true/0/1/true/Annuler/true"
  assert_eq "LB.V9 — ST-2 : la liste des codes de pré-vol est DÉRIVÉE du module de cibles (non vide : $NCODES codes) et chaque code a un texte dans la vue (aucun « Contrôle non reconnu. »)" "$([ "$NCODES" -ge 14 ] && echo "$(vv v9)" || echo "liste trop courte: $NCODES")" "$NCODES/"
  assert_eq "LB.V10 — LB2 (PU-G-112, 120, 124) : pour chacun des cinq verbes, l'intention AFFICHÉE porte les accents (Exécute, Vérifie) alors que la ligne de commande reste en ASCII ; la phrase en clair « L’assistant va <infinitif> la phase 72 du compartiment alpha : … » précède la commande ; le bouton s'appelle « Préparer dans le terminal » ; la phrase « Appuyez sur Entrée dans le terminal pour démarrer. » est écrite" "$(vv v10)" "true.true.true.Préparer dans le terminal.true.true;true.true.true.Préparer dans le terminal.true.true;true.true.true.Préparer dans le terminal.true.true;true.true.true.Préparer dans le terminal.true.true;true.true.true.Préparer dans le terminal.true.true"
  assert_eq "LB.V11 — LB2 (PU-G-121, 122 ; Q9) : une ligne d'explication par mode, dans l'ordre ; « Risqué » (glyphe svg + mot, couleur identique au texte neutre, trait en currentColor) sur « Accepter les modifications » seulement ; aucun « dernier choix » pour « Par défaut » ; « Plan (lecture seule) — votre dernier choix » exactement une fois pour un mode retenu" "$(vv v11)" "default|acceptEdits|plan|herite/Par défaut|Accepter les modifications|Plan (lecture seule)|Hérité du poste/true/acceptEdits:Risqué:1/true/true/false/Plan (lecture seule) — votre dernier choix/2"
  assert_eq "LB.V12 — LB2 (PU-G-123 ; Q6) : case du chat décochée par défaut, liée à sa phrase ; la phrase dit ce que fait la reprise et écrit « Risque : la session lancée relit toute cette conversation » sans « -r » ni « --fork-session » ; la commande exacte reste sans reprise tant que la case est décochée, puis porte « -r … --fork-session »" "$(vv v12)" "false/proposition-chat-aide/true/true/true/true/true"
  assert_eq "LB.V13 — LB2 (PU-G-114) : compte à rebours « Expire dans 1 min 30 s » (role timer) et annonce polie ; à l'échéance « Proposition expirée — la renvoyer. » (seul bouton : Fermer, plus de bouton de lancement) ; proposition(null) ne l'efface pas, « Fermer » oui ; une disparition annoncée à 2 s de l'échéance vaut expiration, à 100 s elle retire" "$(vv v13)" "Expire dans 1 min 30 s|timer|polite|Lancement proposé : Planifie la Phase 72 du compartiment alpha. Expire dans 1 min 30 s./Proposition expirée — la renvoyer.|Fermer|false|Proposition expirée — la renvoyer./true/true/expiree/true"
  assert_eq "LB.V14 — LB2 (PU-G-117 ; Q5) : le bandeau précède #terminal dans l'ordre de la page, la région #annonce (role status, aria-live polite) le précède et annonce « Lancement proposé… »" "$(vv v14)" "true/true/status/polite/true"
  assert_eq "LB.V15 — LB2 (PU-G-119) : proposition() rend false et garde le bandeau tant qu'une touche vient d'être tapée dans le sélecteur de mode focalisé ou qu'un bouton de souris est enfoncé dans le bandeau ; un focus sans geste, ou un bandeau libre, est remplacé" "$(vv v15)" "true/true/true/true/true"
  assert_eq "LB.V16 — LB3 (PU-G-136) : dans un cadre de 124 px (le plus petit tiroir), la proposition prend sa place sous le terminal (terminal d'au moins 24 px, son bas au-dessus du haut du bandeau, bandeau d'au plus 60 % du cadre, dans le cadre) ; retirée, le terminal reprend au moins 120 px" "$(vv v16)" "124/true/true/true/true/true"
  assert_eq "LB.V21 — PU-G-136 (recette du 2026-11-08) : dans un cadre de 300 px (hauteur du tiroir à l'arrivée d'une proposition), le bandeau le plus long défile (témoin : plus haut que sa fenêtre) et « Préparer dans le terminal » est visible sans défiler : défilement à 0, haut et bas du bouton dans le bandeau, bas du bouton dans le cadre" "$(vv v21)" "300/0/true/true/true/true"
  assert_eq "LB.V22 — S1 (revue du 2026-11-08 ; WCAG 2.4.11) puis F3 (3e tour) : au focus clavier réel, dans un cadre de 124, 300 et 450 px, avec la case du chat, DEUX parcours qui traversent le bandeau — Tab depuis le sélecteur de mode (Annuler, commande, case du chat, Préparer) et Maj+Tab depuis Préparer (case du chat, commande, Annuler, sélecteur de mode) — dont chaque arrêt est nommé et visible, hors du pied collé (Annuler compris : 2 à 4 px sous le pied à 124 px avant F3 ; un arrêt dans le pied : visible dans le bandeau)" "$(vv v22)" "$V22_SAIN"
  assert_eq "LB.V22c — J7 (passe de suivi) : les mêmes deux parcours Tab / Maj+Tab sous pointer: coarse RÉEL (émulation CDP du toucher ; témoin : matchMedia('(pointer: coarse)') est vrai, « coarse=true » en tête) : au toucher le pied fait 44 px et la réserve de défilement monte à 52 px ; chaque arrêt est nommé, visible, hors du pied" "$(vv v22c)" "coarse=true;$V22_SAIN"
  assert_eq "LB.V23 — S3 (revue du 2026-11-08) : le pied collé de la proposition est positionné (sticky) et son fond est OPAQUE (rgb, jamais rgba ni transparent)" "$(vv v23)" "sticky/true"
  assert_eq "LB.V24 — S2 (revue du 2026-11-08) : après un refus de lancement (occupe), à 300 px avec la case du chat, la raison est visible dans le bandeau et dans le cadre, sans recouvrir le pied ni être recouverte par lui" "$(vv v24)" "300/true/true/true"
  assert_eq "LB.V25 — P5 (revue du 2026-11-08) : après « ok », la consigne « Commande préparée dans le terminal. Appuyez sur Entrée dans le terminal pour démarrer. » est visible alors que la proposition est retirée, y reste sans rien faire, puis disparaît à Entrée dans le terminal (échéance de 100 s) ou à la fin du compte à rebours (échéance de 6 s)" "$(vv v25)" "entree:true:true:absente;compte-a-rebours:true:true:absente"
  assert_eq "LB.V25b — F2, F4, F6b (3e tour de la recette du 2026-11-08) : (F2) trois répétitions d'Entrée tenue dans le terminal (autoRepeat) ne retirent PAS la consigne, une Entrée fraîche la retire ; (F4) une nouvelle proposition, puis une carte « Serveur arrêté », la remplacent ; (F6b) avec le bandeau d'état fixe, la consigne reste entièrement au-dessus de lui, à 124 px, 300 px et pleine hauteur (chaque segment commence par le témoin : la consigne était visible)" "$(vv v25b)" "$V25B_SAIN"
  assert_eq "LB.V26 — S4 (revue du 2026-11-08) : le champ de saisie du xterm réel a pour nom accessible « Saisie du terminal » (jamais « Terminal input »)" "$(vv v26)" "Saisie du terminal"
  assert_eq "LB.V17 — LB3 (PU-G-141 ; Q14) : la carte « Serveur arrêté » reste entière dans un cadre de 124 px (marge de 8 px en haut et en bas, sans défilement) ; « Copier la commande » copie EXACTEMENT /vf-cockpit --terminal (la sélection au moment de la copie est le texte affiché), le bouton dit « Copiée » et la région polie annonce « Commande copiée. » ; aucun bouton de copie sur une proposition de lancement" "$(vv v17)" "true/true/true|true|Copiée|Commande copiée.|true"
  assert_eq "LB.V18 — LB3 (PU-G-140) : accueil à la première ouverture (role status, phrase « pas besoin pour suivre le travail », bouton Compris), aucun focus pris, aucun octet au terminal ; une proposition puis une carte le remplacent ; il revient tant qu'il n'est pas rangé ; « Compris » le range pour de bon (clé du stockage de Q posée, plus de retour)" "$(vv v18)" "true/true/true/true/true/true/true/true"
  assert_eq "LB.V19 — LB3-S (revue LB1-LB2) : « Préparer » est APRÈS la commande exacte, la phrase d'Entrée, la case du chat ET la liste des modes (dont le « Risqué » d'acceptEdits, F8 du LB3-S2) dans l'ordre du document ; la carte « Serveur arrêté » et le bandeau « Reconnexion… » ne sont jamais masqués par la proposition (trois points de l'élément d'état testés), cadre de 124 px et pleine hauteur" "$(vv v19)" "true.true.true.true.true/true/true/true/true"
  assert_eq "LB.V20 — LB3-S2 (F3, PU-G-140) : l'accueil se pose DANS la colonne (le bas du terminal est au-dessus de son haut, il tient dans le cadre, le terminal garde plus de 24 px, « Compris » n'est pas dans l'ordre de tabulation) ; à la première frappe dans le terminal il est rangé pour de bon (clé du stockage posée), la frappe arrive au shell intacte (UN seul envoi, l'octet 78), le focus du terminal reste ; « Compris » à la souris ne déplace pas le focus" "$(vv v20)" "true.true.true.true/true/true/true/true"

  echo "=== LB.E — client réel, serveur factice du contrat §4, faux P ==="
  faux "$SCRIPTS"; FQ0="$FQ"; FP0="$FP"; EJ="$(navig client)"; unfaux
  ev_() { rj "$EJ" "(j.erreur ? 'plante: ' + j.erreur : j.$1 !== undefined ? j.$1 : 'erreur: ' + ((j.erreurs || {}).$1 || 'étape absente'))"; }
  assert_eq "LB.E1 — proposition servie : bandeau en moins de 4 s, commande exacte du serveur, UN message proposition d'origine Q (aucune donnée : ni identifiant, ni ligne, ni secret)" "$(ev_ e1)" "true/1/true/true/true"
  assert_eq "LB.E2 — clic de confiance avant l'armement : aucun POST /lancer ; après armement : UN POST de clés exactes id,mode sans « claude », 204, bandeau retiré, aucun octet à /entree, la clé vf.terminal.mode du stockage de Q reste absente (le mode retenu vit côté serveur : LM.Q)" "$(ev_ e2)" "true/0/1/id,mode/true/204/0/null"
  assert_eq "LB.E3 — 409 une fois : message « Le terminal n'a pas pris la demande… », 0 octet à /entree, le bandeau reste, Lancer de nouveau actif, un second clic armé aboutit (204)" "$(ev_ e3)" "true/0/true/true/true/409,204"
  assert_eq "LB.E4 — après usage le serveur dit aucune : le cadre rechargé en ?theme=light, puis après trois sondages aucun #proposition" "$(ev_ e4)" "true/0/light"
  assert_eq "LB.E5 — depuis P, iframe.contentWindow.localStorage lève SecurityError (témoin : le stockage de Q porte le secret) ; le serveur factice sert acceptEdits : présélection acceptEdits (témoin) ; il sert bypassPermissions (forgé) : présélection default" "$(ev_ e5)" "SecurityError/secret/acceptEdits/default"
  assert_eq "LB.E6 — cadre chargé avec ?theme=dark&mode=acceptEdits&lancer=1&id=zzz, le serveur factice servant plan : présélection plan (un paramètre d'adresse lu donnerait acceptEdits), aucune requête /lancer" "$(ev_ e6)" "plan/0"
  assert_eq "LB.E7 — postMessage('proposition', '*') puis postMessage({ id: 'zzz' }, '*') du faux P vers le cadre : aucun nouveau bandeau, aucun POST /lancer" "$(ev_ e7)" "true/0/0"
  assert_eq "LB.E9 — LB2 (Q7) : proposition d'une visite précédente (cadre neuf, 115 s d'âge) : aucun bandeau, aucun message proposition, POST /annuler parti ; le même cadre rechargé dans la même visite retrouve sa proposition" "$(ev_ e9)" "0/0/true/true"
  assert_eq "LB.E10 — LB3-S, Entrée TENUE sur « Préparer » (arbitrage Samuel, AskUserQuestion session principale, 2026-11-06) : après le retour du focus au terminal, six répétitions de la touche (autoRepeat) n'envoient AUCUN octet \\r au shell ; Entrée relâchée puis pressée de nouveau : UN \\r (témoin)" "$(ev_ e10)" "xterm-helper-textarea/0/1"
  assert_eq "LB.E10b — LB3-S2 (F2), le cas du TAP : « Préparer » au clic de souris (aucune Entrée tenue, le relâchement est parti au bouton ou n'a jamais existé), focus rendu au terminal, une Entrée FRAÎCHE : EXACTEMENT un \\r — la clause « pression fraîche » de la retenue ne l'avale jamais" "$(ev_ e10b)" "1"
  assert_eq "LB.E12 — LB3-S2 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-07, option A) : Entrée TENUE sur chaque bouton qui rend le focus au terminal (Annuler de la proposition, Annuler du collage, Coller, Relancer le shell) : six répétitions après le retour du focus = 0 octet \\r ; puis une Entrée fraîche = 1 (témoin) ; cadre par bouton : <répétitions>/<fraîche>" "$(ev_ e12)" "annuler:0/1|abandonner:0/1|coller:0/1|relancer:0/1"
  assert_eq "LB.E13 — LB3-S3 (F1, arbitrage Samuel, AskUserQuestion session principale, 2026-11-07), chemin PARENT : Entrée tenue sur un bouton de P qui appelle iframe.focus() au keydown (reproduit la pastille du tiroir ; le vrai client de Q est dans l'iframe) : la première pression n'envoie aucun \\r (le focus a changé entre keydown et keypress), six répétitions = 0 octet \\r, puis Entrée fraîche = 1 (témoin) ; cadre : <bouton focalisé>/<première pression>/<répétitions>/<fraîche>" "$(ev_ e13)" "pastille-t/0/0/1"
  assert_eq "LB.E14 — LB3-S3 (F1), chemin « retour d'onglet » : le terminal a perdu le focus, une Entrée est tenue, l'événement focus de la fenêtre de Q (écouteur window.focus du client) lui rend le focus : six répétitions = 0 octet \\r, puis Entrée fraîche = 1 (témoin)" "$(ev_ e14)" "0/1"
  assert_eq "LB.E11 — LB3-S (c), référence d'âge servie par Q : proposition fraîche d'une durée courte (duree_ms 10 s) montrée ; ancienne d'une durée longue (600 s, 300 s restantes) effacée dans Q (aucun bandeau, POST /annuler parti) ; témoin : une fraîche de durée longue est montrée" "$(ev_ e11)" "true/0/true/true"
  faux "$SCRIPTS"; FJ="$(navig froid)"; unfaux
  assert_eq "LB.E8 — cadre masqué : UN message proposition d'origine Q en moins de 4 s, aucun .xterm ni #proposition, aucune requête /flux, /lancer, /entree ; cadre agrandi : bandeau, /flux demandé, TOUJOURS UN seul message" \
    "$(rj "$FJ" "(j.erreur ? 'plante: ' + j.erreur : j.e8 !== undefined ? j.e8 : 'erreur: ' + ((j.erreurs || {}).e8 || 'étape absente'))")" "1/true/0/0/0/true|true|1"
  faux "$SCRIPTS"; FJ1="$(navig focus '"emu":true')"; unfaux
  assert_eq "LB.F1 — F1, fenêtre FOCALISÉE (émulation de focus) : champ de saisie de P focalisé, cadre de Q créé, proposition reçue, frappes abc : le champ de P les reçoit, le focus reste au champ de P, AUCUN octet à /entree" \
    "$(rj "$FJ1" "(j.erreur ? 'plante: ' + j.erreur : j.f1 !== undefined ? j.f1 : 'erreur: ' + ((j.erreurs || {}).f1 || 'étape absente'))")" "abc/champP/0"
  faux "$SCRIPTS"; FJ2="$(navig focus '"emu":false')"; unfaux
  assert_eq "LB.F2 — F1, fenêtre NON focalisée (sans émulation) : même scénario, mêmes attentes" \
    "$(rj "$FJ2" "(j.erreur ? 'plante: ' + j.erreur : j.f1 !== undefined ? j.f1 : 'erreur: ' + ((j.erreurs || {}).f1 || 'étape absente'))")" "abc/champP/0"
  l2() { faux "${3:-$SCRIPTS}"; LJ="$(navig focusvue "\"emu\":$1,\"quoi\":\"$2\"${4:+,$4}")"; unfaux; rj "$LJ" "(j.erreur ? 'plante: ' + j.erreur : j.l2 !== undefined ? j.l2 : 'erreur: ' + JSON.stringify(j.erreurs))"; } # l2 <emu> <carte|bandeau> [dossier] [json] ; abc/champP/<bouton focalisé>/<activations>/<montée>
  verdict_l2() { case "$1" in abc/champP/false/0/true) echo sain ;; */true) echo rouge ;; *) echo "plante: $1" ;; esac; } # rouge seulement si l'élément est monté (dernier champ true) ET que la forme saine est perdue
  assert_eq "LB.F4 — L2, carte « refuse » (bouton « Réessayer ») montée sans geste, fenêtre FOCALISÉE (émulation) : les frappes abc et Entrée vont au champ de P, le focus reste au champ de P, aucun bouton du cadre focalisé ni activé (témoin : la carte est montée)" "$(l2 true carte)" "abc/champP/false/0/true"
  assert_eq "LB.F5 — L2, carte « refuse », fenêtre NON focalisée : mêmes attentes" "$(l2 false carte)" "abc/champP/false/0/true"
  assert_eq "LB.F6 — L2, bandeau « termine » (Relancer le shell) monté sans geste, fenêtre focalisée : mêmes attentes" "$(l2 true bandeau)" "abc/champP/false/0/true"
  assert_eq "LB.F7 — L2, bandeau « termine », fenêtre non focalisée : mêmes attentes" "$(l2 false bandeau)" "abc/champP/false/0/true"
  assert_eq "LB.F8 — L2, témoin positif : le cadre a le focus (P le lui a donné) : la vue focalise le bouton de la carte (comportement de la Phase 71 inchangé), le champ de P ne reçoit rien (la touche Entrée synthétique du harnais ne déclenche pas le clic : activations 0)" "$(l2 true carte "$SCRIPTS" '"cadre":true')" "/IFRAME/true/0/true"
  FAUX_INJ="$SCRIPTS" faux "$SCRIPTS"; SJ1="$(navig sp1 '"emu":true')"; unfaux
  assert_eq "LB.F3 — SP-1 : page rechargée sans fragment, tiroir fermé (aucun cadre avant), clic Lancer sur une carte : 202, cadre de Q monté, bandeau dans Q, le focus de P n'est pas pris par le cadre" \
    "$(rj "$SJ1" "(j.erreur ? 'plante: ' + j.erreur : j.sp1 !== undefined ? j.sp1 : 'erreur: ' + ((j.erreurs || {}).sp1 || 'étape absente'))")" "0/true/true/true"
  assert_eq "LB.P — le serveur factice écoute des ports >= 4600 et différents de 4456 (Q $FQ0, P $FP0)" "$([ "$FQ0" -ge 4600 ] && [ "$FP0" -ge 4600 ] && [ "$FQ0" -ne 4456 ] && [ "$FP0" -ne 4456 ] && [ "$FQ0" -ne "$FP0" ] && echo oui || echo non)" "oui"
fi

# --- mutants ---------------------------------------------------------------------------------------------------------------------------------------------
echo "=== M-* — vingt-six mutants, plus six de LB3-S (copies des sources) ==="
if mutant entree-auto vf-cockpit-terminal-client.mjs "/garde:apres-usage/s#.*#if (terminal) terminal.focus(); fetch('/entree', { method: 'POST', headers: entetes(), body: new Uint8Array([13]) });#"; then
  assert_eq "M-ENTREE-AUTO — le mutant rougit LB.C5 : un octet part à /entree après le 204 (témoin : le scénario s'exécute, le lancement est accepté)" "$(verdict "$(doubles "$MUT_DIR" focus)" 'j.st==="ok" && j.entrees===0')" "rouge"
else sans_effet "M-ENTREE-AUTO"; fi
if mutant armement-ignore vf-cockpit-terminal-vue.mjs "/garde:armement/s/'true'/'false'/"; then
  [ -n "$CHROME" ] && { run_vue "$MUT_DIR" '"only":["v3"]'; assert_eq "M-ARMEMENT-IGNORE — le mutant rougit LB.V3 : un clic avant l'armement appelle cb.lancer (témoin : le bandeau s'affiche, la sonde s'exécute)" "$(rj "$VJ" "(j.erreur ? 'plante: ' + j.erreur : j.v3 === 'tôt/0/[\"default\"]' ? 'sain' : j.v3 ? 'rouge' : 'plante: ' + JSON.stringify(j.erreurs))")" "rouge"; }
else sans_effet "M-ARMEMENT-IGNORE"; fi
if mutant texte-serveur vf-cockpit-terminal-client.mjs "/garde:corps-lancer/s/{ id: courante, mode }/{ id: courante, mode, ligne: 'claude --session-id' }/"; then
  assert_eq "M-TEXTE-AU-SERVEUR — le mutant rougit LB.C3 : le corps de POST /lancer n'est plus {id,mode} (témoin : la requête part)" "$(verdict "$(doubles "$MUT_DIR" statuts)" 'j.cas[0].nreq===1 && j.cas[0].req.b===JSON.stringify({id:j.cas[0].req.id,mode:"acceptEdits"})')" "rouge"
else sans_effet "M-TEXTE-AU-SERVEUR"; fi
if mutant mode-non-relu vf-cockpit-terminal-client.mjs "/garde:mode-relu/s#.*#return v || 'default';#"; then
  assert_eq "M-MODE-NON-RELU — le mutant rougit LB.C4 : bypassPermissions devient la présélection (témoin : les valeurs valides sont lues)" "$(verdict "$(doubles "$MUT_DIR" mode)" 'j.lu[1]==="bypassPermissions=>default" && j.lu[9]==="acceptEdits=>acceptEdits"')" "rouge"
else sans_effet "M-MODE-NON-RELU"; fi
if mutant message-avec-donnees vf-cockpit-terminal-client.mjs "/garde:emission/s#emettre('proposition')#window.parent.postMessage('proposition:' + p.id, cfg.origineP)#"; then
  assert_eq "M-MESSAGE-AVEC-DONNEES — le mutant rougit LB.C2 : le message porte l'identifiant (témoin : la proposition s'affiche)" "$(verdict "$(doubles "$MUT_DIR" suivi)" 'j.a1.n===1 && j.msg.n===3 && j.msg.strict')" "rouge"
  node "$AUX/pagegen.mjs" "$MUT_DIR" "$ENG" dark "$WORK/m-donnees.html"; assert_eq "M-MESSAGE-AVEC-DONNEES — le mutant rougit aussi LB.S2 : le postMessage( ne vise plus la seule émission fixe (deux appels)" "$(rj "$(node "$AUX/stat.mjs" "$WORK/m-donnees.html")" 'j.postmsg===1 && j.cible')" "false"
else sans_effet "M-MESSAGE-AVEC-DONNEES"; fi
if mutant message-repete vf-cockpit-terminal-client.mjs "/garde:emission/s/if (nouveau) //"; then
  assert_eq "M-MESSAGE-REPETE — le mutant rougit LB.C2 : un message à chaque sondage au lieu d'un par identifiant (témoin : la proposition s'affiche)" "$(verdict "$(doubles "$MUT_DIR" suivi)" 'j.a1.n===1 && j.a2.msgs===1 && j.b.msgs===2')" "rouge"
else sans_effet "M-MESSAGE-REPETE"; fi
if mutant usage-reste vf-cockpit-terminal-vue.mjs "/garde:retrait-usage/s/st === 'ok' || //"; then
  [ -n "$CHROME" ] && { run_vue "$MUT_DIR" '"only":["v7"]'; assert_eq "M-USAGE-RESTE — le mutant rougit LB.V7 : le bandeau reste après un lancement accepté (témoin : les autres statuts s'exécutent)" "$(rj "$VJ" "(j.erreur ? 'plante: ' + j.erreur : /^ok=KO/.test(j.v7 || '') && /;occupe=ok;/.test(j.v7) ? 'rouge' : j.v7 ? 'sain' : 'plante: ' + JSON.stringify(j.erreurs))")" "rouge"; }
else sans_effet "M-USAGE-RESTE"; fi
if mutant aucune-ignoree vf-cockpit-terminal-client.mjs "/garde:aucune/d"; then
  assert_eq "M-AUCUNE-IGNOREE — le mutant rougit LB.C2 : « aucune » ne retire plus le bandeau (témoin : le bandeau s'est affiché)" "$(verdict "$(doubles "$MUT_DIR" suivi)" 'j.a1.n===1 && j.c.nulls===1')" "rouge"
else sans_effet "M-AUCUNE-IGNOREE"; fi
if mutant clic-non-fiable vf-cockpit-terminal-vue.mjs "/garde:clic-fiable/s/ev.isTrusted !== true || //"; then
  [ -n "$CHROME" ] && { run_vue "$MUT_DIR" '"only":["v4"]'; assert_eq "M-CLIC-NON-FIABLE — le mutant rougit LB.V4 : un click() programmatique appelle cb.lancer (témoin : le bandeau est affiché et armé, la sonde s'exécute)" "$(rj "$VJ" "(j.erreur ? 'plante: ' + j.erreur : j.v4 === '0/1' ? 'sain' : j.v4 ? 'rouge' : 'plante: ' + JSON.stringify(j.erreurs))")" "rouge"; }
else sans_effet "M-CLIC-NON-FIABLE"; fi
if mutant innerhtml vf-cockpit-terminal-vue.mjs "/garde:texte/s|.*|const t = el('span', 'vf-q-texte'); t.innerHTML = 'Lancement proposé : ' + p.intention; b.appendChild(t);|"; then
  [ -n "$CHROME" ] && { run_vue "$MUT_DIR" '"only":["v5"]'; assert_eq "M-INNERHTML — le mutant rougit LB.V5 : l'intention hostile devient un nœud img (témoin : le bandeau s'affiche, la sonde s'exécute)" "$(rj "$VJ" "(j.erreur ? 'plante: ' + j.erreur : j.v5 === 'true/true/0/undefined/0/false/0/0' ? 'sain' : j.v5 ? 'rouge' : 'plante: ' + JSON.stringify(j.erreurs))")" "rouge"; }
else sans_effet "M-INNERHTML"; fi
if mutant prop-au-dessus vf-cockpit-terminal-vue.mjs "/garde:collage-dessus/s|.*|document.body.appendChild(b);|"; then
  [ -n "$CHROME" ] && { run_vue "$MUT_DIR" '"only":["v6"]'; assert_eq "M-PROP-AU-DESSUS — le mutant rougit LB.V6 : le bandeau passe au-dessus du collage (témoin : les deux sont affichés)" "$(rj "$VJ" "(j.erreur ? 'plante: ' + j.erreur : j.v6 === 'true/true' ? 'sain' : j.v6 ? 'rouge' : 'plante: ' + JSON.stringify(j.erreurs))")" "rouge"; }
else sans_effet "M-PROP-AU-DESSUS"; fi
if mutant param-url vf-cockpit-terminal-client.mjs "/garde:mode-lecture/s#.*#const v = new URLSearchParams(location.search).get('mode') || p.mode_retenu; // garde:mode-lecture#"; then
  node "$AUX/pagegen.mjs" "$MUT_DIR" "$ENG" dark "$WORK/m-url.html"; assert_eq "M-PARAM-URL — le mutant rougit LB.S1 : URLSearchParams lu dans le client (témoin : la page est vivante)" "$(rj "$(node "$AUX/stat.mjs" "$WORK/m-url.html")" '(j.urlsp===0 && j.search===2) ? "sain" : (j.propres>200 ? "rouge" : "plante")')" "rouge"
  if [ -n "$CHROME" ]; then faux "$MUT_DIR"; MJ="$(navig client '"only":["e6"]')"; unfaux
    assert_eq "M-PARAM-URL — le mutant rougit aussi LB.E6 (Chrome) : la présélection suit le paramètre d'adresse (acceptEdits/0 au lieu de plan/0 ; témoin : la sonde s'exécute)" "$(rj "$MJ" "(j.erreur ? 'plante: ' + j.erreur : j.e6 !== undefined ? j.e6 : 'erreur: ' + ((j.erreurs || {}).e6 || 'étape absente'))")" "acceptEdits/0"; fi
else sans_effet "M-PARAM-URL"; fi
if mutant sondage-apres-visible vf-cockpit-terminal-client.mjs "/garde:sondage-precoce/d;/garde:pret/s/afficher();/lire(); setInterval(lire, PROPOSITION_MS); afficher();/"; then
  assert_eq "M-SONDAGE-APRES-VISIBLE — le mutant rougit LB.C7 : aucun message ne part pendant la phase masquée (témoin : après l'ouverture la proposition s'affiche)" "$(verdict "$(doubles "$MUT_DIR" froid)" 'j.masque.msgs===1')" "rouge"
else sans_effet "M-SONDAGE-APRES-VISIBLE"; fi
if mutant retard-reaffiche vf-cockpit-terminal-client.mjs "/garde:fermee/d"; then
  assert_eq "M-RETARD-REAFFICHE — le mutant rougit LB.C2 : un sondage en retard remonte la proposition consommée (témoin : le lancement est accepté)" "$(verdict "$(doubles "$MUT_DIR" retard)" 'j.ok.st==="ok" && j.ok.dv===0 && j.ok.dm===0')" "rouge"
else sans_effet "M-RETARD-REAFFICHE"; fi

if mutant visite-ignoree vf-cockpit-terminal-client.mjs "/garde:visite/d"; then
  [ -n "$CHROME" ] && { faux "$MUT_DIR"; MJ="$(navig client '"only":["e9"]')"; unfaux; assert_eq "M-VISITE-IGNOREE — le mutant rougit LB.E9 : la proposition d'une visite précédente est montrée puis remplacée (témoin : la sonde s'exécute et le même cadre rechargé la retrouve)" "$(rj "$MJ" "(j.erreur ? 'plante: ' + j.erreur : j.e9 === undefined ? 'plante: ' + JSON.stringify(j.erreurs) : j.e9 === '0/0/true/true' ? 'sain' : 'rouge')")" "rouge"; }
else sans_effet "M-VISITE-IGNOREE"; fi
if mutant bandeau-fixe vf-cockpit-terminal-style.mjs "s|body #proposition { position: static;|body #proposition { position: fixed;|"; then
  [ -n "$CHROME" ] && { run_vue "$MUT_DIR" '"only":["v16"]'; assert_eq "M-BANDEAU-FIXE — le mutant (le bandeau recouvre de nouveau le terminal) rougit LB.V16 (témoin : la sonde s'exécute et rend un résultat)" "$(rj "$VJ" "(j.erreur ? 'plante: ' + j.erreur : j.v16 === undefined ? 'plante: ' + JSON.stringify(j.erreurs) : j.v16 === '124/true/true/true/true/true' ? 'sain' : 'rouge')")" "rouge"; }
else sans_effet "M-BANDEAU-FIXE"; fi
if mutant entree-tenue vf-cockpit-terminal-client.mjs "/entreeTenue) { if (e.type/d"; then
  [ -n "$CHROME" ] && { faux "$MUT_DIR"; MJ="$(navig client '"only":["e10"]')"; unfaux; assert_eq "M-ENTREE-TENUE — le mutant (la retenue des répétitions d'Entrée est retirée) rougit LB.E10 : des octets CR atteignent le shell (témoin : la sonde s'exécute et rend un résultat)" "$(rj "$MJ" "(j.erreur ? 'plante: ' + j.erreur : j.e10 === undefined ? 'plante: ' + JSON.stringify(j.erreurs) : j.e10 === 'xterm-helper-textarea/0/1' ? 'sain' : 'rouge')")" "rouge"; }
else sans_effet "M-ENTREE-TENUE"; fi
if mutant pression-fraiche vf-cockpit-terminal-client.mjs "s/if (e.type === 'keyup' || !e.repeat) entreeTenue = false;/if (e.type === 'keyup') entreeTenue = false;/"; then
  [ -n "$CHROME" ] && { faux "$MUT_DIR"; MJ="$(navig client '"only":["e10b"]')"; unfaux; assert_eq "M-PRESSION-FRAICHE — le mutant (la retenue ne se lève plus à une pression fraîche, seulement au relâchement) rougit LB.E10b : l'Entrée fraîche du cas du tap est avalée, 0 \\r au lieu de 1 (témoin : la sonde s'exécute)" "$(rj "$MJ" "(j.erreur ? 'plante: ' + j.erreur : j.e10b === undefined ? 'plante: ' + JSON.stringify(j.erreurs) : j.e10b === '1' ? 'sain' : 'rouge')")" "rouge"; }
else sans_effet "M-PRESSION-FRAICHE"; fi
e12_verdict() { rj "$1" "(j.erreur ? 'plante: ' + j.erreur : j.e12 === undefined ? 'plante: ' + JSON.stringify(j.erreurs) : j.e12.split('|').map((x) => x.split(':')[1] === '0/1' ? 'sain' : 'rouge').join(','))"; }
# LB3-S3 (F1, F2) : la retenue n'a plus qu'un point d'armement, la prise de focus du terminal (l'événement focus de son textarea) ; les gardes restantes sont la clause de la touche (M-ENTREE-TENUE) et la pression fraîche (M-PRESSION-FRAICHE)
# UN mutant retire le point fixe : il doit rougir le témoin de CHAQUE chemin de prise de focus (Préparer E10, les quatre boutons de Q E12, le bouton du parent E13, le retour d'onglet E14), et lui seul laisse sain le cas du tap E10b
if mutant point-fixe-focus vf-cockpit-terminal-client.mjs "/term.textarea.addEventListener('focus'/d"; then
  [ -n "$CHROME" ] && { faux "$MUT_DIR"; MJ="$(navig client '"only":["e10","e10b","e12","e13","e14"]')"; unfaux
    assert_eq "M-POINT-FIXE-PREPARER — le mutant (la prise de focus du terminal n'arme plus la retenue) rougit LB.E10, « Préparer » (témoin : E10b, le cas du tap, reste sain)" "$(rj "$MJ" "(j.erreur ? 'plante: ' + j.erreur : j.e10 === undefined || j.e10b === undefined ? 'plante: ' + JSON.stringify(j.erreurs) : (j.e10 === 'xterm-helper-textarea/0/1' ? 'sain' : 'rouge') + '/' + (j.e10b === '1' ? 'sain' : 'rouge'))")" "rouge/sain"
    assert_eq "M-POINT-FIXE-BOUTONS-Q — le même mutant rougit LB.E12 pour CHACUN des quatre boutons de Q (annuler, abandonner, coller, relancer)" "$(e12_verdict "$MJ")" "rouge,rouge,rouge,rouge"
    assert_eq "M-POINT-FIXE-PARENT — le même mutant rougit LB.E13 (bouton de P qui appelle iframe.focus())" "$(rj "$MJ" "(j.erreur ? 'plante: ' + j.erreur : j.e13 === undefined ? 'plante: ' + JSON.stringify(j.erreurs) : j.e13 === 'pastille-t/0/0/1' ? 'sain' : 'rouge')")" "rouge"
    assert_eq "M-POINT-FIXE-ONGLET — le même mutant rougit LB.E14 (retour d'onglet, événement focus de la fenêtre)" "$(rj "$MJ" "(j.erreur ? 'plante: ' + j.erreur : j.e14 === undefined ? 'plante: ' + JSON.stringify(j.erreurs) : j.e14 === '0/1' ? 'sain' : 'rouge')")" "rouge"; }
else sans_effet "M-POINT-FIXE-FOCUS"; fi
if mutant ref-constante vf-cockpit-terminal-client.mjs "s#p.duree_ms - p.expire_ms > VISITE_MS#120000 - p.expire_ms > VISITE_MS#"; then
  [ -n "$CHROME" ] && { faux "$MUT_DIR"; MJ="$(navig client '"only":["e11"]')"; unfaux; assert_eq "M-REF-CONSTANTE — le mutant (référence d'âge codée à 120 s au lieu de la durée servie) rougit LB.E11 (témoin : la sonde s'exécute)" "$(rj "$MJ" "(j.erreur ? 'plante: ' + j.erreur : j.e11 === undefined ? 'plante: ' + JSON.stringify(j.erreurs) : j.e11 === 'true/0/true/true' ? 'sain' : 'rouge')")" "rouge"; }
else sans_effet "M-REF-CONSTANTE"; fi
if mutant preparer-avant vf-cockpit-terminal-vue.mjs "s#b.appendChild(pied); b.appendChild(msg);#b.insertBefore(pied, b.children[3]); b.appendChild(msg);#"; then
  [ -n "$CHROME" ] && { run_vue "$MUT_DIR" '"only":["v19"]'; assert_eq "M-PREPARER-AVANT — le mutant (Préparer remonte avant la commande exacte) rougit LB.V19 (témoin : la sonde s'exécute)" "$(rj "$VJ" "(j.erreur ? 'plante: ' + j.erreur : j.v19 === undefined ? 'plante: ' + JSON.stringify(j.erreurs) : j.v19 === 'true.true.true.true.true/true/true/true/true' ? 'sain' : 'rouge')")" "rouge"; }
else sans_effet "M-PREPARER-AVANT"; fi
if mutant etat-recouvert vf-cockpit-terminal-style.mjs "s#order: 2; z-index: auto;#order: 2; z-index: 1;#"; then
  [ -n "$CHROME" ] && { run_vue "$MUT_DIR" '"only":["v19"]'; assert_eq "M-ETAT-RECOUVERT — le mutant (la proposition reprend un z-index) rougit LB.V19 : elle masque la carte ou le bandeau d'état (témoin : la sonde s'exécute)" "$(rj "$VJ" "(j.erreur ? 'plante: ' + j.erreur : j.v19 === undefined ? 'plante: ' + JSON.stringify(j.erreurs) : j.v19 === 'true.true.true.true.true/true/true/true/true' ? 'sain' : 'rouge')")" "rouge"; }
else sans_effet "M-ETAT-RECOUVERT"; fi
if mutant pied-colle vf-cockpit-terminal-style.mjs "s#.vf-q-pied { position: sticky; bottom: 0;#.vf-q-pied { position: static; bottom: 0;#"; then
  [ -n "$CHROME" ] && { run_vue "$MUT_DIR" '"only":["v21"]'; assert_eq "M-PIED-COLLE — le mutant (le pied n'est plus collé au bas du bandeau) rougit LB.V21 : « Préparer dans le terminal » repasse sous le pli à 300 px (témoin : la sonde s'exécute)" "$(rj "$VJ" "(j.erreur ? 'plante: ' + j.erreur : j.v21 === undefined ? 'plante: ' + JSON.stringify(j.erreurs) : j.v21 === '300/0/true/true/true/true' ? 'sain' : 'rouge')")" "rouge"; }
else sans_effet "M-PIED-COLLE"; fi
if mutant etat-sous-pied vf-cockpit-terminal-style.mjs "s#\#etat .vf-q-bandeau, \#etat .vf-q-carte { z-index: 1; }#\#etat .vf-q-bandeau, \#etat .vf-q-carte { z-index: auto; }#"; then
  [ -n "$CHROME" ] && { run_vue "$MUT_DIR" '"only":["v19"]'; assert_eq "M-ETAT-SOUS-PIED — le mutant (la carte et le bandeau d'état perdent leur z-index) rougit LB.V19 : le pied collé, élément positionné, les recouvre (témoin : la sonde s'exécute)" "$(rj "$VJ" "(j.erreur ? 'plante: ' + j.erreur : j.v19 === undefined ? 'plante: ' + JSON.stringify(j.erreurs) : j.v19 === 'true.true.true.true.true/true/true/true/true' ? 'sain' : 'rouge')")" "rouge"; }
else sans_effet "M-ETAT-SOUS-PIED"; fi
if mutant reserve-pied vf-cockpit-terminal-style.mjs 's#^\#proposition { scroll-padding-bottom: calc(var(--sp-32) + var(--sp-8)); }#\#proposition { }#'; then
  [ -n "$CHROME" ] && { run_vue "$MUT_DIR" '"only":["v22"]'; assert_eq "M-RESERVE-PIED — le mutant (la fenêtre de défilement n'a plus de réserve sous le pied) rougit LB.V22 : un arrêt de Tab passe sous le pied collé (case du chat à 300 px, 124 px) (témoin : la sonde s'exécute)" "$(rj "$VJ" "(j.erreur ? 'plante: ' + j.erreur : j.v22 === undefined ? 'plante: ' + JSON.stringify(j.erreurs) : j.v22 === '$V22_SAIN' ? 'sain' : 'rouge')")" "rouge"; }
else sans_effet "M-RESERVE-PIED"; fi
if mutant reserve-pied-tactile vf-cockpit-terminal-style.mjs 's#^@media (pointer: coarse) { \#proposition { scroll-padding-bottom: calc(var(--sp-32) + var(--sp-12) + var(--sp-8)); } }#@media (pointer: coarse) { \#proposition { } }#'; then
  [ -n "$CHROME" ] && { run_vue "$MUT_DIR" '"only":["v22c"]'; assert_eq "M-RESERVE-PIED-TACTILE — le mutant (la règle pointer: coarse du remplissage de défilement est vidée : 52 px deviennent 40) rougit LB.V22c : un arrêt de Tab passe sous le pied de 44 px (témoin : la sonde s'exécute et le média est vrai)" "$(rj "$VJ" "(j.erreur ? 'plante: ' + j.erreur : j.v22c === undefined ? 'plante: ' + JSON.stringify(j.erreurs) : j.v22c === 'coarse=true;$V22_SAIN' ? 'sain' : 'rouge')")" "rouge"; }
else sans_effet "M-RESERVE-PIED-TACTILE"; fi
if mutant pied-sans-fond vf-cockpit-terminal-style.mjs 's#sticky; bottom: 0; background: var(--raise); }#sticky; bottom: 0; }#'; then
  [ -n "$CHROME" ] && { run_vue "$MUT_DIR" '"only":["v23"]'; assert_eq "M-PIED-SANS-FOND — le mutant (le pied collé perd son fond) rougit LB.V23 : le fond n'est plus opaque (témoin : la sonde s'exécute)" "$(rj "$VJ" "(j.erreur ? 'plante: ' + j.erreur : j.v23 === undefined ? 'plante: ' + JSON.stringify(j.erreurs) : j.v23 === 'sticky/true' ? 'sain' : 'rouge')")" "rouge"; }
else sans_effet "M-PIED-SANS-FOND"; fi
if mutant refus-sans-defilement vf-cockpit-terminal-vue.mjs '/msg.scrollIntoView/d'; then
  [ -n "$CHROME" ] && { run_vue "$MUT_DIR" '"only":["v24"]'; assert_eq "M-REFUS-SANS-DEFILEMENT — le mutant (la raison du refus n'est plus ramenée dans le champ) rougit LB.V24 : elle reste sous le pli à 300 px (témoin : la sonde s'exécute)" "$(rj "$VJ" "(j.erreur ? 'plante: ' + j.erreur : j.v24 === undefined ? 'plante: ' + JSON.stringify(j.erreurs) : j.v24 === '300/true/true/true' ? 'sain' : 'rouge')")" "rouge"; }
else sans_effet "M-REFUS-SANS-DEFILEMENT"; fi
for m in "consigne-absente|s#annoncer(ANNONCE_PREPAREE); montrerConsigne(rest); }#annoncer(ANNONCE_PREPAREE); }#|la consigne n'est jamais montrée" "consigne-sans-entree|s#(ev.key === 'Enter' \&\& !ev.repeat \&\& ev.target#(false \&\& ev.target#|Entrée ne retire plus la consigne" "consigne-sans-echeance|s#if (reste > 0) finConsigne = setTimeout(retirerConsigne, reste);##|la fin du compte à rebours ne retire plus la consigne"; do
  MN="${m%%|*}"; MR="${m#*|}"; MS_="${MR%%|*}"; MD="${MR#*|}"; MU="$(printf %s "$MN" | tr a-z A-Z)" # bash 3.2 : pas de ${var^^}
  if mutant "$MN" vf-cockpit-terminal-vue.mjs "$MS_"; then
    [ -n "$CHROME" ] && { run_vue "$MUT_DIR" '"only":["v25"]'; assert_eq "M-${MU} — le mutant ($MD) rougit LB.V25 (témoin : la sonde s'exécute)" "$(rj "$VJ" "(j.erreur ? 'plante: ' + j.erreur : j.v25 === undefined ? 'plante: ' + JSON.stringify(j.erreurs) : j.v25 === 'entree:true:true:absente;compte-a-rebours:true:true:absente' ? 'sain' : 'rouge')")" "rouge"; }
  else sans_effet "M-${MU}"; fi
done
# 3e tour (F2, F4, F6b) : un mutant par garde, chacun doit rougir LB.V25b (la consigne survit à une Entrée tenue ; une proposition puis une carte la remplacent ; elle reste au-dessus du bandeau d'état)
for m in "consigne-tenue|s#(ev.key === 'Enter' \&\& !ev.repeat \&\& ev.target#(ev.key === 'Enter' \&\& ev.target#|une Entrée tenue retire la consigne" "proposition-garde-consigne|s#retirerProposition(); retirerAccueil(); retirerConsigne();#retirerProposition(); retirerAccueil();#|une nouvelle proposition laisse la consigne" "carte-garde-consigne|/const c = CARTES\[type\]/{n;s#retirerConsigne();##;}|une carte laisse la consigne"; do
  MN="${m%%|*}"; MR="${m#*|}"; MS_="${MR%%|*}"; MD="${MR#*|}"; MU="$(printf %s "$MN" | tr a-z A-Z)"
  if mutant "$MN" vf-cockpit-terminal-vue.mjs "$MS_"; then
    [ -n "$CHROME" ] && { run_vue "$MUT_DIR" '"only":["v25b"]'; assert_eq "M-${MU} — le mutant ($MD) rougit LB.V25b (témoin : la sonde s'exécute)" "$(rj "$VJ" "(j.erreur ? 'plante: ' + j.erreur : j.v25b === undefined ? 'plante: ' + JSON.stringify(j.erreurs) : j.v25b === '$V25B_SAIN' ? 'sain' : 'rouge')")" "rouge"; }
  else sans_effet "M-${MU}"; fi
done
if mutant consigne-sous-etat vf-cockpit-terminal-style.mjs 's#, body:has(\#etat .vf-q-bandeau) \#consigne { margin-bottom#  { margin-bottom#'; then
  [ -n "$CHROME" ] && { run_vue "$MUT_DIR" '"only":["v25b"]'; assert_eq "M-CONSIGNE-SOUS-ETAT — le mutant (la consigne perd la marge du bandeau d'état) rougit LB.V25b : elle passe dessous (témoin : la sonde s'exécute)" "$(rj "$VJ" "(j.erreur ? 'plante: ' + j.erreur : j.v25b === undefined ? 'plante: ' + JSON.stringify(j.erreurs) : j.v25b === '$V25B_SAIN' ? 'sain' : 'rouge')")" "rouge"; }
else sans_effet "M-CONSIGNE-SOUS-ETAT"; fi
if mutant strings-commente vf-cockpit-terminal-client.mjs 's#^\( *\)if (Terminal.strings)#\1// if (Terminal.strings)#'; then
  [ -n "$CHROME" ] && { run_vue "$MUT_DIR" '"only":["v26"]'; assert_eq "M-STRINGS-COMMENTE — le mutant (la ligne Terminal.strings est commentée) rougit LB.V26 : le champ s'annonce « Terminal input » (témoin : la sonde s'exécute)" "$(rj "$VJ" "(j.erreur ? 'plante: ' + j.erreur : j.v26 === undefined ? 'plante: ' + JSON.stringify(j.erreurs) : j.v26 === 'Saisie du terminal' ? 'sain' : 'rouge')")" "rouge"; }
else sans_effet "M-STRINGS-COMMENTE"; fi
if mutant strings-apres-open vf-cockpit-terminal-client.mjs '/^ *if (Terminal.strings)/{h;d;};/term.open(/G'; then
  [ -n "$CHROME" ] && { run_vue "$MUT_DIR" '"only":["v26"]'; assert_eq "M-STRINGS-APRES-OPEN — le mutant (la ligne Terminal.strings est posée après term.open()) rougit LB.V26 : le champ est déjà nommé en anglais (témoin : la sonde s'exécute)" "$(rj "$VJ" "(j.erreur ? 'plante: ' + j.erreur : j.v26 === undefined ? 'plante: ' + JSON.stringify(j.erreurs) : j.v26 === 'Saisie du terminal' ? 'sain' : 'rouge')")" "rouge"; }
else sans_effet "M-STRINGS-APRES-OPEN"; fi
if mutant couleur-proposition vf-cockpit-terminal-style.mjs "s|^#proposition-mode { border: thin solid|#proposition-mode { color: #fff; border: thin solid|"; then
  assert_eq "M-COULEUR-PROPOSITION — le mutant (un littéral de couleur dans une règle de la proposition) rougit LB.S4 (témoin : les règles sont trouvées)" "$(nb_lot "$MUT_DIR/vf-cockpit-terminal-style.mjs")/$(couleurs_lot "$MUT_DIR/vf-cockpit-terminal-style.mjs")" "ok/1"
else sans_effet "M-COULEUR-PROPOSITION"; fi
if mutant couleur-accueil vf-cockpit-terminal-style.mjs "s|^#accueil .vf-q-texte { font-weight: 400;|#accueil .vf-q-texte { background: rgba(0, 0, 0, .5); font-weight: 400;|"; then
  assert_eq "M-COULEUR-ACCUEIL — le mutant (un rgba( dans la règle de l'accueil, hors #proposition) rougit LB.S4 élargi (témoin : les règles sont trouvées)" "$(nb_lot "$MUT_DIR/vf-cockpit-terminal-style.mjs")/$(couleurs_lot "$MUT_DIR/vf-cockpit-terminal-style.mjs")" "ok/1"
else sans_effet "M-COULEUR-ACCUEIL"; fi
if mutant couleur-nom vf-cockpit-terminal-style.mjs "s|^#proposition-mode { border: thin solid|#proposition-mode { color: red; border: thin solid|"; then
  assert_eq "M-COULEUR-NOM — le mutant (un nom de couleur, red, dans une règle de la proposition) rougit LB.S4 (témoin : les règles sont trouvées)" "$(nb_lot "$MUT_DIR/vf-cockpit-terminal-style.mjs")/$(couleurs_lot "$MUT_DIR/vf-cockpit-terminal-style.mjs")" "ok/1"
else sans_effet "M-COULEUR-NOM"; fi
if mutant couleur-transparent vf-cockpit-terminal-style.mjs "s|^#accueil .vf-q-texte { font-weight: 400;|#accueil .vf-q-texte { background: transparent; font-weight: 400;|"; then
  assert_eq "M-COULEUR-TRANSPARENT — le mutant (transparent dans la règle de l accueil) rougit LB.S4 (témoin : les règles sont trouvées)" "$(nb_lot "$MUT_DIR/vf-cockpit-terminal-style.mjs")/$(couleurs_lot "$MUT_DIR/vf-cockpit-terminal-style.mjs")" "ok/1"
else sans_effet "M-COULEUR-TRANSPARENT"; fi
if mutant couleur-courante vf-cockpit-terminal-style.mjs "s|^#proposition-mode { border: thin solid|#proposition-mode { color: currentColor; border: thin solid|"; then
  assert_eq "M-COULEUR-COURANTE — le mutant (currentColor hors du picto, « stroke: currentColor » restant seul autorisé) rougit LB.S4 (témoin : les règles sont trouvées)" "$(nb_lot "$MUT_DIR/vf-cockpit-terminal-style.mjs")/$(couleurs_lot "$MUT_DIR/vf-cockpit-terminal-style.mjs")" "ok/1"
else sans_effet "M-COULEUR-COURANTE"; fi
if mutant couleur-oklch vf-cockpit-terminal-style.mjs "s|^#proposition-mode { border: thin solid|#proposition-mode { color: oklch(60% .1 20); border: thin solid|"; then
  assert_eq "M-COULEUR-OKLCH — le mutant (une fonction moderne, oklch() rougit LB.S4 (témoin : les règles sont trouvées)" "$(nb_lot "$MUT_DIR/vf-cockpit-terminal-style.mjs")/$(couleurs_lot "$MUT_DIR/vf-cockpit-terminal-style.mjs")" "ok/1"
else sans_effet "M-COULEUR-OKLCH"; fi
if mutant couleur-color-mix vf-cockpit-terminal-style.mjs "s|^#proposition-mode { border: thin solid|#proposition-mode { color: color-mix(in srgb, var(--text) 50%, var(--on)); border: thin solid|"; then
  assert_eq "M-COULEUR-COLOR-MIX — le mutant (color-mix() rougit LB.S4 (témoin : les règles sont trouvées)" "$(nb_lot "$MUT_DIR/vf-cockpit-terminal-style.mjs")/$(couleurs_lot "$MUT_DIR/vf-cockpit-terminal-style.mjs")" "ok/1"
else sans_effet "M-COULEUR-COLOR-MIX"; fi
if mutant px-proposition vf-cockpit-terminal-style.mjs "s|#proposition .vf-q-pied { justify-content: flex-end; }|#proposition .vf-q-pied { justify-content: flex-end; padding: 6px; }|"; then
  assert_eq "M-PX-PROPOSITION — le mutant (un px de plus dans une règle de la proposition) rougit LB.S4 : l'ensemble des px n'est plus celui des exceptions nommées (témoin : les règles sont trouvées)" "$(nb_lot "$MUT_DIR/vf-cockpit-terminal-style.mjs")/$(px_lot "$MUT_DIR/vf-cockpit-terminal-style.mjs")" "ok/12.5px 12.5px 240px 44px 560px 6px "
else sans_effet "M-PX-PROPOSITION"; fi
if mutant px-carte vf-cockpit-terminal-style.mjs "s|.vf-q-carte { max-height: calc(100% - var(--sp-16));|.vf-q-carte { max-height: calc(100% - 16px);|"; then
  assert_eq "M-PX-CARTE — le mutant (la carte tassée repasse en 16px au lieu du jeton --sp-16) rougit LB.S4 (témoin : les règles sont trouvées)" "$(nb_lot "$MUT_DIR/vf-cockpit-terminal-style.mjs")/$(px_lot "$MUT_DIR/vf-cockpit-terminal-style.mjs")" "ok/12.5px 12.5px 16px 240px 44px 560px "
else sans_effet "M-PX-CARTE"; fi
if mutant px-svg vf-cockpit-terminal-style.mjs "s|#proposition svg.i { width: var(--sp-16); height: var(--sp-16);|#proposition svg.i { width: 16px; height: var(--sp-16);|"; then
  assert_eq "M-PX-SVG — le mutant (le picto repasse en 16px) rougit LB.S4 et LB.S5 (témoin : les règles sont trouvées)" "$(nb_lot "$MUT_DIR/vf-cockpit-terminal-style.mjs")/$(px_lot "$MUT_DIR/vf-cockpit-terminal-style.mjs")/$(regles_prop "$MUT_DIR/vf-cockpit-terminal-style.mjs" | grep -c 'svg.i { width: var(--sp-16); height: var(--sp-16)')" "ok/12.5px 12.5px 16px 240px 44px 560px /0"
else sans_effet "M-PX-SVG"; fi
if mutant taille-em vf-cockpit-terminal-style.mjs "s|#proposition .vf-q-aide { font-size: 12.5px;|#proposition .vf-q-aide { font-size: .92em;|"; then
  assert_eq "M-TAILLE-EM — le mutant (la taille de l'aide repasse en .92em) rougit LB.S5 (témoin : les règles sont trouvées)" "$(nb_prop "$MUT_DIR/vf-cockpit-terminal-style.mjs")/$(echem_prop "$MUT_DIR/vf-cockpit-terminal-style.mjs")" "ok/1"
else sans_effet "M-TAILLE-EM"; fi
if mutant copie-autre-texte vf-cockpit-terminal-vue.mjs "s|r.selectNodeContents(k.querySelector('.vf-q-commande'))|r.selectNodeContents(k.querySelector('.vf-q-titre'))|"; then
  [ -n "$CHROME" ] && { run_vue "$MUT_DIR" '"only":["v17"]'; assert_eq "M-COPIE-AUTRE-TEXTE — le mutant (le bouton copie un autre texte que la commande affichée) rougit LB.V17 (témoin : la sonde s'exécute)" "$(rj "$VJ" "(j.erreur ? 'plante: ' + j.erreur : j.v17 === undefined ? 'plante: ' + JSON.stringify(j.erreurs) : j.v17 === 'true/true/true|true|Copiée|Commande copiée.|true' ? 'sain' : 'rouge')")" "rouge"; }
else sans_effet "M-COPIE-AUTRE-TEXTE"; fi
if mutant accueil-recouvre vf-cockpit-terminal-style.mjs "s|body #accueil { position: static;|body #accueil { position: fixed;|"; then
  [ -n "$CHROME" ] && { run_vue "$MUT_DIR" '"only":["v20"]'; assert_eq "M-ACCUEIL-RECOUVRE — le mutant (l'accueil recouvre de nouveau le bas du terminal) rougit LB.V20 (témoin : la sonde s'exécute)" "$(rj "$VJ" "(j.erreur ? 'plante: ' + j.erreur : j.v20 === undefined ? 'plante: ' + JSON.stringify(j.erreurs) : j.v20 === 'true.true.true.true/true/true/true/true' ? 'sain' : 'rouge')")" "rouge"; }
else sans_effet "M-ACCUEIL-RECOUVRE"; fi
if mutant accueil-sans-frappe vf-cockpit-terminal-vue.mjs "s/ if (n === 'keydown' \&\& ev.target.*closest('#terminal')) fermerAccueil();//"; then
  [ -n "$CHROME" ] && { run_vue "$MUT_DIR" '"only":["v20"]'; assert_eq "M-ACCUEIL-SANS-FRAPPE — le mutant (la première frappe ne range plus l'accueil) rougit LB.V20 (témoin : la sonde s'exécute)" "$(rj "$VJ" "(j.erreur ? 'plante: ' + j.erreur : j.v20 === undefined ? 'plante: ' + JSON.stringify(j.erreurs) : j.v20 === 'true.true.true.true/true/true/true/true' ? 'sain' : 'rouge')")" "rouge"; }
else sans_effet "M-ACCUEIL-SANS-FRAPPE"; fi
if mutant accueil-range-deplace-focus vf-cockpit-terminal-vue.mjs "s/ retirerAccueil(); }; \/\/ première frappe/ retirerAccueil(); document.activeElement.blur(); }; \/\/ première frappe/"; then
  [ -n "$CHROME" ] && { run_vue "$MUT_DIR" '"only":["v20"]'; assert_eq "M-ACCUEIL-RANGE-DEPLACE-FOCUS — le mutant (ranger l'accueil retire le focus au terminal : la frappe est perdue) rougit LB.V20 (témoin : la sonde s'exécute)" "$(rj "$VJ" "(j.erreur ? 'plante: ' + j.erreur : j.v20 === undefined ? 'plante: ' + JSON.stringify(j.erreurs) : j.v20 === 'true.true.true.true/true/true/true/true' ? 'sain' : 'rouge')")" "rouge"; }
else sans_effet "M-ACCUEIL-RANGE-DEPLACE-FOCUS"; fi
if mutant accueil-compris-focalise vf-cockpit-terminal-vue.mjs "s/ c.addEventListener('mousedown', (ev) => ev.preventDefault());//"; then
  [ -n "$CHROME" ] && { run_vue "$MUT_DIR" '"only":["v20"]'; assert_eq "M-ACCUEIL-COMPRIS-FOCALISE — le mutant (« Compris » reprend le focus au clic puis disparaît avec lui) rougit LB.V20 (témoin : la sonde s'exécute)" "$(rj "$VJ" "(j.erreur ? 'plante: ' + j.erreur : j.v20 === undefined ? 'plante: ' + JSON.stringify(j.erreurs) : j.v20 === 'true.true.true.true/true/true/true/true' ? 'sain' : 'rouge')")" "rouge"; }
else sans_effet "M-ACCUEIL-COMPRIS-FOCALISE"; fi
if mutant modes-apres vf-cockpit-terminal-vue.mjs "s#b.appendChild(pied); b.appendChild(msg);#b.appendChild(pied); b.appendChild(msg); b.appendChild(modes);#"; then
  [ -n "$CHROME" ] && { run_vue "$MUT_DIR" '"only":["v19"]'; assert_eq "M-MODES-APRES — le mutant (la liste des modes, dont le « Risqué », revient APRÈS « Préparer ») rougit LB.V19 (témoin : la sonde s'exécute)" "$(rj "$VJ" "(j.erreur ? 'plante: ' + j.erreur : j.v19 === undefined ? 'plante: ' + JSON.stringify(j.erreurs) : j.v19 === 'true.true.true.true.true/true/true/true/true' ? 'sain' : 'rouge')")" "rouge"; }
else sans_effet "M-MODES-APRES"; fi
if mutant accueil-focus vf-cockpit-terminal-vue.mjs "s|'vf-q-secondaire')); document.body.appendChild(b);|'vf-q-secondaire')); document.body.appendChild(b); b.querySelector('button').focus();|"; then
  [ -n "$CHROME" ] && { run_vue "$MUT_DIR" '"only":["v18"]'; assert_eq "M-ACCUEIL-FOCUS — le mutant (l'accueil prend le focus) rougit LB.V18 (témoin : la sonde s'exécute)" "$(rj "$VJ" "(j.erreur ? 'plante: ' + j.erreur : j.v18 === undefined ? 'plante: ' + JSON.stringify(j.erreurs) : j.v18 === 'true/true/true/true/true/true/true/true' ? 'sain' : 'rouge')")" "rouge"; }
else sans_effet "M-ACCUEIL-FOCUS"; fi
if mutant manipule-ignore vf-cockpit-terminal-vue.mjs "/garde:manipule/d"; then
  [ -n "$CHROME" ] && { run_vue "$MUT_DIR" '"only":["v15"]'; assert_eq "M-MANIPULE-IGNORE — le mutant rougit LB.V15 : un bandeau manipulé est remplacé sous la main (témoin : le bandeau s'affiche et la sonde s'exécute)" "$(rj "$VJ" "(j.erreur ? 'plante: ' + j.erreur : j.v15 === undefined ? 'plante: ' + JSON.stringify(j.erreurs) : j.v15 === 'true/true/true/true/true' ? 'sain' : 'rouge')")" "rouge"; }
else sans_effet "M-MANIPULE-IGNORE"; fi
if mutant expiration-silencieuse vf-cockpit-terminal-vue.mjs "s/const EXPIRE_PROCHE_MS = 3000;/const EXPIRE_PROCHE_MS = -1;/"; then
  [ -n "$CHROME" ] && { run_vue "$MUT_DIR" '"only":["v13"]'; assert_eq "M-EXPIRATION-SILENCIEUSE — le mutant rougit LB.V13 : une disparition annoncée à 2 s de l'échéance efface le bandeau sans le dire (témoin : le compte à rebours et le message d'expiration existent)" "$(rj "$VJ" "(j.erreur ? 'plante: ' + j.erreur : j.v13 === undefined ? 'plante: ' + JSON.stringify(j.erreurs) : /^Expire dans 1 min 30 s\|timer/.test(j.v13) && /expiree\/true$/.test(j.v13) ? 'sain' : /^Expire dans 1 min 30 s\|timer/.test(j.v13) ? 'rouge' : 'plante: ' + j.v13)")" "rouge"; }
else sans_effet "M-EXPIRATION-SILENCIEUSE"; fi
mutant_inj() { # mutant_inj <nom> <fichier> <expression-sed> -> MUT_DIR ; copie du tiroir et de l'interface de lancement ; code 1 si la cible manque ou n'a pas changé
  local d="$WORK/mut-$1" f x; rm -rf "$d"; mkdir -p "$d"
  for x in terminal-tiroir terminal-tiroir-ui terminal-tiroir-style lancer-ui lancer-style; do cp "$SCRIPTS/vf-cockpit-$x.mjs" "$d/"; done
  MUT_DIR="$d"; f="$d/$2"; [ -f "$f" ] || return 1
  cp "$f" "$f.orig"; sed -i.bak "$3" "$f"; local r=0; cmp -s "$f" "$f.orig" && r=1; rm -f "$f.orig" "$f.bak"; return $r
}
rouge_f1() { rj "$1" "(j.erreur ? 'plante: ' + j.erreur : j.f1 === undefined ? 'plante: ' + JSON.stringify(j.erreurs) : j.f1 === 'abc/champP/0' ? 'sain' : 'rouge')"; }
rouge_sp1() { rj "$1" "(j.erreur ? 'plante: ' + j.erreur : j.sp1 === undefined ? 'plante: ' + JSON.stringify(j.erreurs) : j.sp1 === '0/true/true/true' ? 'sain' : 'rouge')"; }
if [ -n "$CHROME" ]; then
  if mutant focus-client vf-cockpit-terminal-client.mjs "s/if (!document.hasFocus || document.hasFocus()) term.focus();/term.focus();/"; then
    faux "$MUT_DIR"; MJ="$(navig focus '"emu":false')"; unfaux
    assert_eq "M-FOCUS-CLIENT — le mutant rougit LB.F2 : le client reprend le focus sans condition, les frappes de P atteignent le shell (témoin : le scénario s'exécute jusqu'aux frappes)" "$(rouge_f1 "$MJ")" "rouge"
  else sans_effet "M-FOCUS-CLIENT"; fi
  if mutant focus-vue vf-cockpit-terminal-vue.mjs "s/if (premier \&\& document.hasFocus()) annuler.focus();/if (premier) annuler.focus();/"; then
    faux "$MUT_DIR"; MJ="$(navig focus '"emu":true')"; unfaux
    assert_eq "M-FOCUS-VUE — le mutant rougit LB.F1 : Annuler prend le focus au champ de P à l'arrivée d'une proposition (témoin : le scénario s'exécute jusqu'aux frappes)" "$(rouge_f1 "$MJ")" "rouge"
  else sans_effet "M-FOCUS-VUE"; fi
  if mutant focus-carte vf-cockpit-terminal-vue.mjs "s/if (document.hasFocus()) (b || k).focus();/(b || k).focus();/"; then
    assert_eq "M-FOCUS-CARTE — le mutant rougit LB.F5 : la carte prend le focus de P, les frappes ne vont plus au champ de P (témoin : la carte est montée, le scénario va jusqu'aux frappes)" "$(verdict_l2 "$(l2 false carte "$MUT_DIR")")" "rouge"
  else sans_effet "M-FOCUS-CARTE"; fi
  if mutant focus-bandeau-vue vf-cockpit-terminal-vue.mjs "s/if (r \&\& document.hasFocus()) r.focus();/if (r) r.focus();/"; then
    assert_eq "M-FOCUS-BANDEAU — le mutant rougit LB.F7 : le bandeau prend le focus de P, les frappes ne vont plus au champ de P (témoin : le bandeau est monté, le scénario va jusqu'aux frappes)" "$(verdict_l2 "$(l2 false bandeau "$MUT_DIR")")" "rouge"
  else sans_effet "M-FOCUS-BANDEAU"; fi
  if mutant_inj sp1-signal vf-cockpit-lancer-ui.mjs '/garde:propose/d'; then
    FAUX_INJ="$MUT_DIR" faux "$SCRIPTS"; MJ="$(navig sp1 '"emu":true')"; unfaux
    assert_eq "M-SP1-SIGNAL — le mutant rougit LB.F3 : le 202 ne signale rien au tiroir, aucun cadre de Q, aucun bandeau (témoin : la carte a affiché « Confirmez-la dans le terminal »)" "$(rouge_sp1 "$MJ")" "rouge"
  else sans_effet "M-SP1-SIGNAL"; fi
  if mutant_inj sp1-ecoute vf-cockpit-terminal-tiroir.mjs "/addEventListener('vf-lancer-propose'/d"; then
    FAUX_INJ="$MUT_DIR" faux "$SCRIPTS"; MJ="$(navig sp1 '"emu":true')"; unfaux
    assert_eq "M-SP1-ECOUTE — le mutant rougit LB.F3 : le tiroir n'écoute plus le signal (témoin : la carte a affiché le message d'envoi)" "$(rouge_sp1 "$MJ")" "rouge"
  else sans_effet "M-SP1-ECOUTE"; fi
  if mutant texte-retire vf-cockpit-terminal-vue.mjs "s/'lancement-recent': 'Cette cible a déjà été lancée récemment.', //"; then
    run_vue "$MUT_DIR" "\"only\":[\"v9\"],\"codes\":$CODES"
    assert_eq "M-ST2-TEXTE — le mutant rougit LB.V9 : un code de la table de cibles n'a plus de texte dans la vue (témoin : la liste dérivée a ses $NCODES codes et la sonde s'exécute)" "$(rj "$VJ" "(j.erreur ? 'plante: ' + j.erreur : j.v9 === '$NCODES/' ? 'sain' : /^$NCODES\\/./.test(j.v9 || '') ? 'rouge' : 'plante: ' + JSON.stringify(j.erreurs))")" "rouge"
  else sans_effet "M-ST2-TEXTE"; fi
  if mutant note-ancienne vf-cockpit-terminal-vue.mjs "s/Claude Code suit les réglages de votre poste ou du projet ; un projet ne peut imposer ni « tout autoriser » ni auto (Claude Code 2\.1\.257 et plus)\./le réglage de votre poste s'applique, y compris « tout autoriser » s'il est configuré./"; then
    run_vue "$MUT_DIR" '"only":["v1"]'
    assert_eq "M-NOTE-ANCIENNE — le mutant rougit LB.V1 : l'ancienne note du mode hérité (faux pour le mode venu du projet) n'est plus celle attendue (témoin : le bandeau s'affiche, la sonde s'exécute)" "$(m1="$(rj "$VJ" 'j.v1')"; if [ -z "$m1" ] || [ "$m1" = "undefined" ]; then echo plante; elif [ "$m1" = "$(vv v1)" ]; then echo sain; else echo rouge; fi)" "rouge"
  else sans_effet "M-NOTE-ANCIENNE"; fi
  if mutant occupe-ancien vf-cockpit-terminal-vue.mjs "s/occupe: \"Le terminal n'a pas pris la demande (programme au premier plan, autre lancement, autre onglet ou contrôle bloquant). Rien n'a été écrit ; vérifiez, puis cliquez sur Préparer dans le terminal.\"/occupe: \"Un programme occupe le terminal : quittez-le, puis cliquez sur Préparer dans le terminal. Rien n'a été écrit.\"/"; then
    run_vue "$MUT_DIR" '"only":["v7"]'
    assert_eq "M-OCCUPE-ANCIEN — le mutant rougit LB.V7 : l'ancien texte du 409, qui nomme une cause unique, n'est plus celui attendu (témoin : les autres statuts s'exécutent)" "$(rj "$VJ" "(j.erreur ? 'plante: ' + j.erreur : /;sans-session=ok;/.test(j.v7 || '') ? (/occupe=ok;/.test(j.v7) ? 'sain' : 'rouge') : 'plante: ' + JSON.stringify(j.erreurs))")" "rouge"
  else sans_effet "M-OCCUPE-ANCIEN"; fi
fi

vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
