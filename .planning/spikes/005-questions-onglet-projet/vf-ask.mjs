// Spike 005 — questions sur l'onglet Projet. Chargé par serve.mjs (patch P7) et par vf-query.mjs,
// copié à côté d'eux dans floorplan/ par build-cockpit.mjs. Deux voies, même format de réponse que
// floorplan ({ title, answer, items, steps, followups }, ids [[n:…]] / [[f:…]] cliquables) :
//   - answerLocally : les questions courantes, calculées sur le graphe Projet, sans LLM ;
//   - instructions  : le prompt de l'agent (claude -p) pour tout le reste, outillé par vf-query.mjs.
const A = '<script>window.FLOORPLAN = ', B = ';</script>';
export const extract = (html) => { const a = html.indexOf(A), b = html.indexOf(B, a); return JSON.parse(html.slice(a + A.length, b)); };

const ST = { done: 'fait', active: 'en cours', todo: 'à faire', blocked: 'bloqué' };
const fold = (s) => String(s || '').toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '');

export function projectIndex(G) {
  const N = new Map(G.nodes.map((n) => [n.id, n])), F = new Map(G.files.map((f) => [f.p, f]));
  const kids = new Map(), files = new Map();
  for (const n of G.nodes) if (n.parent) (kids.get(n.parent) || kids.set(n.parent, []).get(n.parent)).push(n);
  for (const f of G.files) (files.get(f.n) || files.set(f.n, []).get(f.n)).push(f);
  const ref = (x) => (x.p != null ? 'f:' + x.p : 'n:' + x.id);
  const label = (x) => x.label || x.name;
  const get = (id) => (id?.startsWith('f:') ? F.get(id.slice(2)) : N.get(String(id || '').replace(/^n:/, '')));
  // tout ce qui vit sous une carte (sous-cartes et éléments), elle comprise
  const under = (id) => { const out = []; const walk = (n) => { out.push(n); for (const f of files.get(n.id) || []) out.push(f); for (const k of kids.get(n.id) || []) walk(k); }; const n = N.get(id); if (n) walk(n); return out; };
  return { N, F, kids, files, ref, label, get, under };
}

const line = (I, x, note) => `- [[${I.ref(x)}]]${/\.req$/.test(x.id || '') ? ` (${String(x.id).slice(3, -4).replace(/^/, 'phase ')})` : ''} · ${ST[x.st] || 'sans statut'}${x.foot ? ' · ' + x.foot : ''}${note ? ' · ' + note : ''}`;
const item = (I, x, note) => ({ id: I.ref(x), note: (note || `${ST[x.st] || 'sans statut'}${x.foot ? ' · ' + x.foot : ''}`).slice(0, 90) });
const answer = (title, md, items, followups = []) => ({ title, answer: md, items: items.slice(0, 14), steps: [], followups, engine: 'local' });
const count = (xs) => { const c = {}; for (const x of xs) if (x.st) c[x.st] = (c[x.st] || 0) + 1; return Object.entries(c).map(([k, v]) => `${v} ${ST[k] || k}`).join(', ') || 'aucun statut'; };

/** Réponse calculée, ou null si la question sort des formes connues (→ agent). */
export function answerLocally(G, question) {
  const I = projectIndex(G), q = fold(question), vf = G.meta?.vf || {};
  // une question de raisonnement (pourquoi, comment, risque, conseil) n'a pas de réponse calculable : l'agent
  if (/\b(pourquoi|comment|explique|quel(le)? risque|faut-il|devrai|conseill|compare|difference|impact)/.test(q)) return null;
  // cibles nommées dans la question
  const ph = /\bphase\s+(\d+(?:\.\d+)?)\b/.exec(q)?.[1];
  const phase = ph && I.N.get('ph-' + ph);
  const msKey = (vf.milestones || []).map((m) => m.key).filter((k) => q.includes(fold(k))).sort((a, b) => b.length - a.length)[0];
  const ms = msKey ? I.N.get('ms-' + msKey) : /jalon (en cours|actuel|courant)/.test(q) ? I.N.get('ms-' + vf.milestone) : null;
  const mi = /\bmission\s+([\w.-]+)/.exec(q)?.[1];
  const mission = mi && (I.N.get('dag-MISSION-' + mi.toUpperCase()) || I.N.get('dag-MISSION-' + mi));
  const reqId = /\b([A-Z][A-Z0-9]{1,7}-\d{2,3})\b/.exec(question)?.[1];
  const req = reqId && I.F.get('req/' + reqId);
  const pathHit = /([\w.-]+\/[\w./-]+\.(?:sh|md|mjs|js|json|ts|yml))/.exec(question)?.[1];
  const target = phase || mission || ms;
  if (/\bphase\s+\d/.test(q) && !phase) return answer(`Phase ${ph} introuvable`, `Aucune carte « Phase ${ph} » dans le graphe Projet (ni ROADMAP active, ni jalon archivé).`, []);

  if (req) {
    const owner = I.N.get(req.n), phaseNode = owner?.parent && I.N.get(owner.parent);
    return answer(reqId, `**${reqId}** · ${ST[req.st] || 'sans statut'}${phaseNode ? ` · portée par [[${I.ref(phaseNode)}]]` : ''}.\n\n${req.d || ''}`,
      [item(I, req), ...(phaseNode ? [item(I, phaseNode)] : [])], phaseNode ? [`Qu'est-ce qui reste dans la ${phaseNode.label.split(' · ')[0].toLowerCase()} ?`] : []);
  }
  if (pathHit) {
    const plans = G.files.filter((f) => (f.touched || []).includes(pathHit));
    if (!plans.length) return answer('Aucun plan', `Aucun plan ni nœud de mission ne déclare avoir touché \`${pathHit}\` (champ \`files_modified\`).`, []);
    return answer(`Qui a touché ${pathHit.split('/').pop()}`, `${plans.length} plan(s) déclarent \`${pathHit}\` :\n${plans.slice(0, 12).map((p) => line(I, p)).join('\n')}`, plans.map((p) => item(I, p)));
  }
  const pool = target ? I.under(target.id) : [...G.nodes, ...G.files];
  const scope = target ? ` dans [[${I.ref(target)}]]` : '';
  if (/bloqu|coince|en echec|echoue/.test(q)) {
    const xs = pool.filter((x) => x.st === 'blocked');
    if (!xs.length) { const act = pool.filter((x) => x.st === 'active'); return answer('Rien de bloqué', `Rien n'est bloqué${scope}. En cours : ${act.length}.\n${act.slice(0, 8).map((x) => line(I, x)).join('\n')}`, act.map((x) => item(I, x))); }
    return answer(`${xs.length} bloqué(s)`, `${xs.length} élément(s) bloqué(s)${scope} (étape de mission en échec) :\n${xs.map((x) => line(I, x, I.label(I.N.get(x.n || x.parent) || {}) || '')).join('\n')}`, xs.map((x) => item(I, x)));
  }
  if (/en cours|actif|au travail|qui travaille/.test(q)) {
    const xs = pool.filter((x) => x.st === 'active');
    return answer(`${xs.length} en cours`, xs.length ? `En cours${scope} :\n${xs.slice(0, 12).map((x) => line(I, x)).join('\n')}` : `Rien en cours${scope} d'après .planning/. Pour les agents réellement au travail, voir le badge d'en-tête.`, xs.map((x) => item(I, x)));
  }
  if (/reste|a faire|prochain|suivant|restant|ensuite|next/.test(q)) {
    const t = target || I.N.get('ms-' + vf.milestone);
    const xs = (t ? I.under(t.id) : pool).filter((x) => x !== t && (x.st === 'todo' || x.st === 'active') && (x.id ? /^ph-[\d.]+$/.test(x.id) || /^dag-/.test(x.id) : !x.p.startsWith('req/') || /^ph-/.test(t?.id || '')));
    return answer(`Reste${t ? ' · ' + I.label(t).split(' · ')[0] : ''}`, `${xs.length} à finir dans [[${I.ref(t)}]]${t?.foot ? ` (${t.foot})` : ''} :\n${xs.slice(0, 12).map((x) => line(I, x)).join('\n')}${xs.length > 12 ? `\n- … et ${xs.length - 12} autre(s)` : ''}`,
      [item(I, t), ...xs.map((x) => item(I, x))], xs[0] ? [`Qu'est-ce qui bloque dans ${I.label(t).split(' · ')[0]} ?`] : []);
  }
  if (/exigence/.test(q) && phase) {
    const xs = I.files.get(phase.id + '.req') || [];
    return answer(`Exigences · Phase ${ph}`, `${xs.length} exigence(s) pour [[${I.ref(phase)}]] (${count(xs)}) :\n${xs.slice(0, 14).map((x) => line(I, x, x.d?.slice(0, 70))).join('\n')}`, xs.map((x) => item(I, x)));
  }
  if (target) {
    const sub = I.under(target.id).filter((x) => x !== target);
    const direct = [...(I.kids.get(target.id) || []), ...(I.files.get(target.id) || [])];
    return answer(I.label(target).split(' · ')[0], `[[${I.ref(target)}]] · ${ST[target.st] || 'sans statut'}${target.foot ? ' · ' + target.foot : ''}.\n\n${target.summary || ''}\n\nContenu : ${sub.length ? count(sub) : 'rien encore (pas de plan)'}.\n${direct.slice(0, 10).map((x) => line(I, x)).join('\n')}`,
      [item(I, target), ...direct.map((x) => item(I, x))], [`Qu'est-ce qui reste dans ${I.label(target).split(' · ')[0]} ?`, `Qu'est-ce qui bloque dans ${I.label(target).split(' · ')[0]} ?`]);
  }
  if (/ou en (est|sommes)|on en est|etat|avancement|resume|statut|progression/.test(q)) {
    const cur = I.N.get('ms-' + vf.milestone), p = I.N.get('ph-' + vf.phase);
    const nexts = cur ? I.under(cur.id).filter((x) => /^ph-[\d.]+$/.test(x.id || '') && x.st !== 'done') : [];
    return answer('Où on en est', `Jalon en cours : [[${I.ref(cur || {})}]]${cur?.foot ? ` (${cur.foot})` : ''}. Dernière phase : ${p ? `[[${I.ref(p)}]]` : vf.phase} · ${vf.status || ''}, le ${vf.lastActivity || '?'}.\n\nÀ finir dans le jalon :\n${nexts.slice(0, 8).map((x) => line(I, x)).join('\n')}`,
      [cur, p, ...nexts].filter(Boolean).map((x) => item(I, x)), ["Qu'est-ce qui bloque ?", "Qu'est-ce qui est en cours ?"]);
  }
  return null;
}

/** Prompt de l'agent pour l'onglet Projet (voie LLM). */
export function instructions(G) {
  return [
    `Tu réponds à des questions sur l'avancement du projet « ${G.project.name} » (méthode VibeFlow, planning dans .planning/), pour quelqu'un qui explore la carte interactive de ce planning. Réponds en français.`,
    'Cartes de la carte : jalons (n:ms-<clé>), phases (n:ph-<N>), groupe des exigences d\'une phase (n:ph-<N>.req), missions (n:dag-MISSION-<N>), Historique, Backlog, Graines, Releases ; éléments : plans (f:<chemin du PLAN.md>), exigences (f:req/<ID>), étapes de mission, entrées de backlog, tags (f:tag/<vX>).',
    'Chaque carte porte un statut st (done = fait, active = en cours, todo = à faire, blocked = étape de mission en échec) et un pied foot (progression, vague, nombre de fichiers). « blocked » de dag.sh (attend ses dépendances) est déjà ramené à todo.',
    'Interroge la carte depuis le shell : `node floorplan/vf-query.mjs overview`, `find "<mots>"`, `show <id>`, `status <done|active|todo|blocked> [--in <id>]`, `path <idA> <idB>`. Chaque résultat est du JSON avec ids et statuts. Lis les fichiers de .planning/ (ROADMAP, PLAN, SUMMARY, STATE) seulement pour un détail que la carte n\'a pas.',
    'Quelques requêtes, pas des dizaines. Puis réponds en JSON seulement : {"title", "answer", "items", "steps", "followups"}.',
    '- answer : Markdown, ~180 mots au plus, concret. Cite les cartes en ligne sous la forme [[id]] (elles deviennent cliquables).',
    '- items : les 3 à 14 cartes qui montrent la réponse, la plus importante d\'abord, chacune avec une note de 15 mots au plus.',
    '- steps : une suite ordonnée quand la réponse est une séquence (enchaînement de phases, étapes d\'une mission) ; sinon [].',
    '- followups : 2 ou 3 questions de suite, courtes, en français.',
    'N\'utilise que des ids rendus par la carte.',
  ].join('\n');
}
