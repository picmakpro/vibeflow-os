// index-generateur — générateur de transcripts à graine pour la propriété d'incrémentalité de l'index (79-08, tâche 3). Autonome : n'importe aucun module de l'index.
// Exports : T0, CLASSES, rng, gen(seed, opts) -> { buf, lignes, oracle }, coupes(g, r, nb, mode), classesDeCoupe(g, coupes, bloc), manque(comptes, seuil)
// L'oracle (plages d'octets, appels ouverts, fin de tour, jetons, compteurs) est tenu par le générateur lui-même, jamais par l'index.
export const T0 = Date.parse('2026-11-01T09:00:00Z');
export const CLASSES = ['milieu-de-ligne', 'entre-lignes', 'entre-lignes-meme-message', 'appel-ouvert', 'apres-fin-de-tour', 'dans-un-ecart-long', 'avant-premiere-ligne', 'ligne-geante', 'bloc-coupe-une-ligne'];
export function rng(seed) { let a = seed >>> 0; return () => { a = (a + 0x6D2B79F5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }

export function gen(seed, { lab, id, abandonne = false }) {
  const r = rng(seed), int = (a, b) => a + Math.floor(r() * (b - a + 1)), pick = (a) => a[Math.floor(r() * a.length)];
  const L = [], ouverts = [], jet = new Map(), o = { appels: 0, erreurs: 0, questions: 0, compactions: 0, tours: 0, refus: 0 };
  let t = 0, cum = 0, fin = false, derniere = null, nMsg = 0, nAppel = 0;
  const ligne = (obj, meta) => { const g = L.length ? t - L[L.length - 1].t : 0; L.push({ s: typeof obj === 'string' ? obj : JSON.stringify(obj), t, ouverts: ouverts.length, finTour: fin, gapAvant: meta.dated ? g : 0, ...meta }); };
  const daté = (type, extra) => ({ cwd: lab, sessionId: id, version: '2.1.322', timestamp: new Date(T0 + t).toISOString(), type, ...extra });
  const ecart = () => { let g = pick([1000, 30000, 179000, 180000, 181000, 400000, 3600000, 1000, 2000]); if (cum + g > 20 * 3600e3) g = 1000; cum += g; t += g; };
  const resultat = (erreur) => { const i = int(0, ouverts.length - 1), [cid] = ouverts.splice(i, 1); if (erreur) o.erreurs++; fin = false; ligne(daté('user', { message: { role: 'user', content: [{ type: 'tool_result', tool_use_id: cid, ...(erreur ? { is_error: true } : {}), content: 'MARQ-SORTIE' }] }, toolUseResult: 'MARQ-TUR' }), { type: 'user', dated: true }); };
  const message = (forceAppel) => {
    const mid = `msg_${seed}_${++nMsg}`, k = int(1, 8), base = { i: int(1, 5000), cr: int(0, 9000), cc: int(0, 800) }; let sortie = 0;
    for (let j = 0; j < k; j++) {
      sortie += int(1, 90); const dernier = j === k - 1, blocs = [{ type: 'text', text: 'MARQ-TEXTE' }];
      if (dernier || r() < 0.4 || forceAppel) { const nom = pick(['Read', 'Bash', 'Agent', 'Task', 'SendMessage', 'AskUserQuestion', 'SubagentHandback', 'mcp__s__f', 'Write']); const cid = `toolu_${seed}_${++nAppel}`; ouverts.push(cid); o.appels++; if (nom === 'AskUserQuestion') o.questions++; blocs.push({ type: 'tool_use', id: cid, name: nom, input: { command: 'MARQ-COMMANDE', file_path: `${lab}/MARQ-CIBLE.js` } }); }
      const stop = dernier ? pick([null, 'tool_use', 'end_turn']) : pick([null, 'tool_use']);
      fin = stop === 'end_turn'; jet.set(mid, { entree: base.i, sortie, cacheLu: base.cr, cacheCree: base.cc }); derniere = mid;
      ligne(daté('assistant', { message: { id: mid, model: 'claude-test-1', role: 'assistant', stop_reason: stop, usage: { input_tokens: base.i, output_tokens: sortie, cache_read_input_tokens: base.cr, cache_creation_input_tokens: base.cc }, content: blocs } }), { type: 'assistant', msg: mid, dated: true });
      if (!dernier && ouverts.length && r() < 0.4) { t += int(100, 900); resultat(r() < 0.3); }
      t += int(100, 900);
    }
  };
  const N = int(18, 40);
  for (let i = 0; i < N; i++) {
    ecart(); const x = r();
    if (i === 0 || x < 0.12) { fin = false; ligne(daté('user', { origin: { kind: 'human' }, message: { role: 'user', content: 'MARQ-TEXTE' } }), { type: 'user', dated: true }); }
    else if (x < 0.55) message(false);
    else if (x < 0.75 && ouverts.length) resultat(r() < 0.3);
    else if (x < 0.80) { o.compactions++; ligne(daté('system', { subtype: 'compact_boundary' }), { type: 'system' }); }
    else if (x < 0.86) { o.tours++; fin = true; ligne(daté('system', { subtype: 'turn_duration', pendingBackgroundAgentCount: int(0, 3) }), { type: 'system' }); }
    else if (x < 0.91) ligne({ type: 'attachment', sessionId: id, note: 'MARQ-TEXTE' }, { type: 'bruit' });
    else if (x < 0.945) { fin = false; ligne(daté('user', { message: { role: 'user', content: 'x'.repeat(5000) } }), { type: 'user', geante: true }); }
    else { fin = false; const refus = r() < 0.4; if (refus) o.refus++; ligne(daté('user', { message: { role: 'user', content: 'MARQ-TEXTE' }, ...(refus ? { permissionDecision: { decision: 'reject' } } : {}) }), { type: 'user', dated: true }); }
  }
  if (abandonne) { ecart(); message(true); }
  let pos = 0; for (const l of L) { l.debut = pos; pos += Buffer.byteLength(l.s) + 1; l.fin = pos; }
  const sommes = { entree: 0, sortie: 0, cacheLu: 0, cacheCree: 0 }; let ctxMax = 0;
  for (const u of jet.values()) { for (const k of Object.keys(sommes)) sommes[k] += u[k]; ctxMax = Math.max(ctxMax, u.entree + u.cacheLu + u.cacheCree); }
  const dernierU = jet.get(derniere);
  return { buf: Buffer.from(L.map((l) => l.s).join('\n') + '\n'), lignes: L, tFin: Math.max(...L.map((l) => l.t), 0),
    oracle: { jetons: { ...sommes, contexteMax: ctxMax, contexteDernier: dernierU ? dernierU.entree + dernierU.cacheLu + dernierU.cacheCree : 0 }, compteurs: { appels: o.appels, erreurs: o.erreurs, refus: o.refus, questions: o.questions, compactions: o.compactions, tours: o.tours, reponsesApi: jet.size }, ouvertsFin: ouverts.length } };
}

// positions de coupe (octets, strictement avant la fin du fichier), sorted ; mode : 'varie' (toutes les classes), 'fins-de-ligne', 'aucune'
export function coupes(g, r, nb, mode = 'varie') {
  const L = g.lignes, pickL = (f) => { const c = L.filter(f); return c.length ? c[Math.floor(r() * c.length)] : L[Math.floor(r() * L.length)]; };
  if (mode === 'aucune') return [];
  if (mode === 'fins-de-ligne') return [...new Set(Array.from({ length: nb }, () => pickL(() => true).fin).filter((p) => p < g.buf.length))].sort((a, b) => a - b);
  const feuilles = [
    () => { const l = pickL((x) => x.fin - x.debut > 4); return l.debut + 1 + Math.floor(r() * (l.fin - l.debut - 2)); },
    () => pickL(() => true).fin,
    () => { const i = Math.floor(r() * (L.length - 1)); const c = L.map((x, k) => k).filter((k) => k + 1 < L.length && L[k].type === 'assistant' && L[k + 1].type === 'assistant' && L[k].msg === L[k + 1].msg); const k = c.length ? c[Math.floor(r() * c.length)] : i; return L[k].fin; },
    () => pickL((x) => x.ouverts > 0).fin,
    () => pickL((x) => x.finTour).fin,
    () => { const k = L.findIndex((x, i) => i > 0 && x.gapAvant > 180000 && r() < 0.5); return (k > 0 ? L[k - 1] : pickL(() => true)).fin; },
    () => Math.floor(r() * L[0].fin),
    () => { const l = pickL((x) => x.geante); return l.debut + 1 + Math.floor(r() * (l.fin - l.debut - 2)); },
  ];
  return [...new Set(Array.from({ length: nb }, (_, i) => Math.max(0, Math.min(g.buf.length - 1, feuilles[(i + Math.floor(r() * 3)) % feuilles.length]()))))].sort((a, b) => a - b);
}

// classes des coupes intermédiaires (le dernier ajout, fin du fichier, ne compte pas) : calculées de la plage d'octets du générateur
export function classesDeCoupe(g, cs, bloc) {
  const L = g.lignes, n = new Map(); const inc = (k) => n.set(k, (n.get(k) || 0) + 1);
  let prec = 0;
  for (const c of cs) {
    const complet = L.filter((l) => l.fin <= c), idx = complet.length, dedans = L.find((l) => l.debut < c && c < l.fin), suivante = dedans || L[idx];
    if (dedans) inc('milieu-de-ligne');
    if (idx > 0 && complet[idx - 1].fin === c) inc('entre-lignes');
    if (idx > 0 && !dedans && L[idx] && complet[idx - 1].type === 'assistant' && L[idx].type === 'assistant' && complet[idx - 1].msg === L[idx].msg) inc('entre-lignes-meme-message');
    if (idx > 0 && complet[idx - 1].ouverts > 0) inc('appel-ouvert');
    if (idx > 0 && complet[idx - 1].finTour) inc('apres-fin-de-tour');
    if (suivante && suivante.gapAvant > 180000) inc('dans-un-ecart-long');
    if (c < L[0].fin) inc('avant-premiere-ligne');
    if (dedans && dedans.geante) inc('ligne-geante');
    if (L.some((l) => l.type === 'assistant' && l.fin <= c && L.some((m) => m.type === 'assistant' && m.msg === l.msg && m.fin > c))) inc('message-a-cheval'); // un message réparti sur plusieurs lignes dont la coupe tombe au milieu (hors liste de couverture)
    const o0 = L.filter((l) => l.fin <= prec).length ? L.filter((l) => l.fin <= prec).slice(-1)[0].fin : 0;
    for (let q = o0 + bloc; q < c; q += bloc) if (L.some((l) => l.debut < q && q < l.fin)) { inc('bloc-coupe-une-ligne'); break; }
    prec = c;
  }
  return n;
}
export const manque = (comptes, seuil = 8) => CLASSES.filter((k) => (comptes.get ? comptes.get(k) || 0 : comptes[k] || 0) < seuil);
