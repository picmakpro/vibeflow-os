// vf-cockpit-ask — questions sur l'onglet Projet (67-05, promu du spike 005). Chargé par le serveur (vf-cockpit-server.mjs) et
// par vf-cockpit-query.mjs. Deux voies, même format de réponse que le moteur
// ({ title, answer, items, steps, followups }, ids [[n:…]] / [[f:…]] cliquables) :
//   - answerLocally : les questions courantes, calculées sur le graphe Projet, sans modèle ni jeton ;
//   - instructions  : la consigne de l'agent (claude -p) pour tout le reste, outillé par vf-cockpit-query.mjs ; elle porte le jeton `<module>`
//     (racine du module, voir vf-cockpit-module.mjs) que le serveur remplace au lancement : la fonction reste pure.
// Identité d'une phase = (compartiment, numéro) : « phase N » se résout par le champ `num` des nœuds de phase ; si plusieurs
// compartiments portent ce numéro, la réponse les liste avec leur compartiment et ne choisit pas au hasard.
// Les exigences n'ont pas de carte (76-08, P76-D-25) : elles se lisent dans `meta.vf.trace.exigences`, et la réponse ne cite que la carte de leur phase.
// Exports : projectIndex(G), answerLocally(G, question), instructions(G).
import { statutLisible } from './vf-cockpit-project.mjs';
const ST = { done: 'fait', active: 'en cours', todo: 'à faire', blocked: 'bloqué', recette: 'à recetter' };
// coupe au mot entier (jamais « rech », « gau ») : au plus n caractères, « … » compris ; un seul mot plus long que n est coupé net
const coupe = (s, n) => {
  s = String(s ?? ''); if (s.length <= n) return s;
  let c = s.slice(0, n - 1);
  if (/\S/.test(c.at(-1)) && /\S/.test(s[n - 1])) { const m = c.replace(/\s*\S+$/, ''); if (m) c = m; }
  return c.replace(/[\s,;:·(–—-]+$/, '') + '…';
};
// un seul état par carte : le mot de son statut, puis son pied sans répéter ce mot (le pied d'une phase en recette commence déjà par « à recetter »)
const etat = (x) => {
  const lab = ST[x.st] || 'sans statut'; let foot = String(x.foot || '');
  if (ST[x.st] && (foot === lab || foot.startsWith(lab + ' · '))) foot = foot.slice(lab.length).replace(/^ · /, '');
  return foot ? `${lab} · ${foot}` : lab;
};
// accord réel (arbitrage Samuel, AskUserQuestion session principale, 2026-11-08, consigné en § 10 du rapport GLOBAL de la recette (3da818fe)) : « 1 bloqué », « 4 bloqués », jamais « bloqué(s) » ; même règle que le panneau (ui/00-vibeflow.js)
const pl = (n, un, plus) => (n > 1 ? plus : un);
// « dans la Phase 72 ? », « dans la Mission 414 ? » : l'article devant un nom de phase ou de mission (arbitrage Samuel, AskUserQuestion session principale, 2026-11-08, consigné en § 10 du rapport GLOBAL de la recette (3f67e7aa)) ; un jalon ou une autre carte garde sa forme
const dans = (label) => (/^(Phase|Mission)\b/.test(label) ? `dans la ${label}` : `dans ${label}`);
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

const line = (I, x, note) => `- [[${I.ref(x)}]] · ${etat(x)}${note ? ' · ' + note : ''}`;
// les exigences du graphe (champ facultatif posé par la collecte ; absent ou en erreur : aucune) et la carte de phase qui les porte
// (une exigence d'archive : le nœud que la collecte a désigné)
// une exigence d'archive (ws '*') jumelle d'une exigence vivante de même identifiant n'est pas une exigence distincte
// (la collecte la rattache à la vivante : 438a2ef6)
const exigencesDe = (G) => {
  const xs = Array.isArray(G.meta?.vf?.trace?.exigences) ? G.meta.vf.trace.exigences : [];
  const vivantes = new Set(xs.filter((e) => e.ws !== '*').map((e) => e.id));
  return xs.filter((e) => e.ws !== '*' || !vivantes.has(e.id));
};
const phaseDe = (G, e) => G.nodes.find((n) => n.kind === 'phase'
  && (e.ws === '*' ? e.cleNoeud === `${n.ws || ''}|${n.num}` : String(n.num) === String(e.phase) && (n.ws || null) === (e.ws || null)));
const caseDe = (e) => (e.coche ? 'cochée' : 'non cochée');
const ligneExigence = (I, G, e, avecWs) => {
  const p = phaseDe(G, e), ws = avecWs && e.ws && e.ws !== '*' ? ` · compartiment ${e.ws}` : '';
  return `- **${e.id}** · ${caseDe(e)}${p ? ` · portée par [[${I.ref(p)}]]` : ''}${ws}${e.libelle ? ` · ${coupe(e.libelle, 70)}` : ''}`;
};
const item = (I, x, note) => ({ id: I.ref(x), note: coupe(note || etat(x), 90) });
const answer = (title, md, items, followups = []) => ({ title, answer: md, items: items.slice(0, 14), steps: [], followups, engine: 'local' });
// accord des statuts (L1, arbitrage Samuel, AskUserQuestion session principale, 2026-11-08, consigné en § 10 du rapport GLOBAL de la recette (3da818fe)) : « 1 bloqué », « 4 bloqués », « 27 faits » ; « en cours », « à faire », « à recetter » sont invariables
const ACCORD = { fait: 'faits', 'bloqué': 'bloqués' };
const count = (xs) => { const c = {}; for (const x of xs) if (x.st) c[x.st] = (c[x.st] || 0) + 1; return Object.entries(c).map(([k, v]) => `${v} ${pl(v, ST[k] || k, ACCORD[ST[k] || k] || ST[k] || k)}`).join(', ') || 'aucun statut'; };

// Réponse sur les « lignes non comprises » du panneau Format, en langage courant. Jointure avec le panneau (vf-cockpit-project.mjs) : seuls les
// CHIFFRES et les positions de meta.vf.drift sont lus (nonComprisesN, nonComprises[{fichier, ligne, extrait}], corrigeable, regles[].regle/.n) ;
// aucun libellé du panneau n'est repris, la formule est la nôtre.
function reponseFormat(d) {
  const lignes = Array.isArray(d?.nonComprises) ? d.nonComprises : [], n = Number(d?.nonComprisesN) || lignes.length;
  const autres = (Array.isArray(d?.regles) ? d.regles : []).filter((r) => r?.regle !== 'ligne-non-comprise').reduce((t, r) => t + (Number(r?.n) || 0), 0);
  const suite = ['Rien n\'est modifié dans les fichiers de .planning/ par cette lecture.', 'Ouvre le panneau Format du planning pour le détail et pour le correctif proposé.', 'Il se relit puis s\'applique à la main.'];
  if (!n) return answer('Lignes du planning non lues', `Aucune ligne du planning n'est mise de côté : le cockpit les a toutes lues${autres ? ` (${autres} ligne${autres > 1 ? 's' : ''} avec une petite différence de forme, sans conséquence sur la carte)` : ''}.\n\nLe panneau Format du planning ne s'affiche que s'il y a quelque chose à signaler.`, [], ['Où en est le jalon ?']);
  const liste = lignes.slice(0, 5).map((l) => `- \`${l.fichier}:${l.ligne}\`${l.extrait ? ` · ${coupe(String(l.extrait).replace(/\s+/g, ' ').trim(), 70)}` : ''}`).join('\n');
  return answer('Lignes du planning non lues', `Le cockpit lit le planning ligne par ligne. Une « ligne non lue » (le panneau Format du planning dit « Non lu ») ressemble à un champ qu'il sait lire (titre de phase, objectif, dépendances, exigence…) mais n'a pas la forme attendue : il la laisse de côté. La phase ou l'exigence correspondante peut alors manquer ou rester incomplète sur la carte.\n\n${n} ligne${n > 1 ? 's' : ''} dans ce projet${lignes.length < n ? ` (les ${lignes.length} premières ci-dessous)` : ''} :\n${liste}${autres ? `\n\nPar ailleurs, ${autres} ligne${autres > 1 ? 's sont lues' : ' est lue'} malgré une petite différence de forme.` : ''}\n\n${suite[0]}${d?.corrigeable ? ` ${suite[1]} ${suite[2]}` : ''}`, [], ['Où en est le jalon ?']);
}

/** Réponse calculée, ou null si la question sort des formes connues (→ agent). */
export function answerLocally(G, question) {
  const I = projectIndex(G), q = fold(question), vf = G.meta?.vf || {};
  // PU-G-150 : « lignes du planning non comprises / non lues / pas lues », « chiffres incomplets » (panneau Format, qui dit « Non lu ») : expliquée avant la garde de raisonnement, car « pourquoi » y est la forme naturelle
  // R2 (revue de 82de0712..3f972a6b) : une question qui porte sur une phase numérotée, une exigence, un plan ou une commande n'est pas celle du panneau Format
  // M4 : « la commande pour corriger les lignes non comprises » est celle du panneau Format (elle reste ici) ; une ligne de commande ou de CODE est un autre objet
  const autreObjet = /\bphases?\s*\d|\bexigences?\b|\bplans?\b|\bcode\b|\b[a-z]{2,6}-\d+\b/.test(q) || (/\bcommandes?\b/.test(q) && !/\bcorrig|\bcorrect/.test(q));
  if (!autreObjet && ((/\blignes?\b/.test(q) && /\b(non|pas) (compris|lu)(es|e|s)?\b/.test(q)) || (/\bincomplets?\b/.test(q) && /\b(chiffres?|nombres?|comptes?|totaux)\b/.test(q)) || /\bnon comprises?\b|lignes? (ignoree|mise de cote)|format (de la |du )?(planification|planning)/.test(q))) return reponseFormat(vf.drift); // pas de `[^.?!]*` entre deux mots : quadratique sur « ligne ligne ligne… »
  // une question de raisonnement (pourquoi, comment, risque, conseil) n'a pas de réponse calculable : l'agent
  if (/\b(pourquoi|comment|explique|quel(le)? risque|faut-il|devrai|conseill|compare|difference|impact)/.test(q)) return null;
  // cibles nommées dans la question
  const ph = /\bphase\s+(\d+(?:\.\d+)?)\b/.exec(q)?.[1];
  const phases = ph ? G.nodes.filter((n) => n.kind === 'phase' && String(n.num) === ph) : [];
  const byWs = phases.filter((p) => p.ws && q.includes(fold(p.ws)));
  const phase = phases.length === 1 ? phases[0] : byWs.length === 1 ? byWs[0] : null;
  const nodeOf = (m) => I.N.get(String(m.id).replace(/^n:/, ''));
  const msHit = (vf.milestones || []).filter((m) => q.includes(fold(m.key))).sort((a, b) => b.key.length - a.key.length)[0];
  const curMs = (() => { const m = (vf.milestones || []).find((x) => x.key === vf.milestone); return m ? nodeOf(m) : I.N.get('ms-' + vf.milestone); })();
  const ms = msHit ? nodeOf(msHit) : /jalon (en cours|actuel|courant)/.test(q) ? curMs : null;
  const mi = /\bmission\s+([\w.-]+)/.exec(q)?.[1];
  const mission = mi && (I.N.get('dag-MISSION-' + mi.toUpperCase()) || I.N.get('dag-MISSION-' + mi));
  const reqId = /\b([A-Z][A-Z0-9]{1,7}-\d{2,3})\b/.exec(question)?.[1];
  const reqs = reqId ? exigencesDe(G).filter((e) => e.id === reqId) : [];
  const req = reqs.length === 1 ? reqs[0] : null;
  // chemin ancré (début ou séparateur avant, fin ou ponctuation après), segments séparés par `/` : borné, jamais de retour arrière en cascade
  const pathHit = /(?:^|[\s'"`(])([\w.-]+(?:\/[\w.-]+)+\.(?:sh|md|mjs|js|json|ts|yml))(?=$|[\s'"`),;:?!])/.exec(question)?.[1];
  const target = phase || mission || ms;
  // plusieurs compartiments portent ce numéro : on les liste, on ne choisit pas
  if (phases.length > 1 && !phase) {
    return answer(`Phase ${ph} : ${phases.length} compartiments`, `Plusieurs compartiments portent une « Phase ${ph} » ; dis lequel :\n${phases.map((p) => line(I, p, `compartiment ${p.ws || 'racine'}`)).join('\n')}`,
      phases.map((p) => item(I, p, `compartiment ${p.ws || 'racine'}`)), phases.map((p) => `Qu'est-ce qui reste dans la phase ${ph} du compartiment ${p.ws || 'racine'} ?`));
  }
  if (reqs.length > 1) return answer(reqId, `${reqs.length} exigences portent l'identifiant **${reqId}** (une par compartiment) :\n${reqs.map((e) => ligneExigence(I, G, e, true)).join('\n')}`, reqs.map((e) => phaseDe(G, e)).filter(Boolean).map((p) => item(I, p)));
  if (/\bphase\s+\d/.test(q) && !phase) return answer(`Phase ${ph} introuvable`, `Aucune carte « Phase ${ph} » dans le graphe Projet (ni ROADMAP active, ni jalon archivé).`, []);

  if (req) {
    const phaseNode = phaseDe(G, req);
    return answer(reqId, `**${reqId}** · ${caseDe(req)}${phaseNode ? ` · portée par [[${I.ref(phaseNode)}]]` : ''}.\n\n${req.libelle || ''}`,
      phaseNode ? [item(I, phaseNode)] : [], phaseNode ? [`Qu'est-ce qui reste dans la ${phaseNode.label.split(' · ')[0].toLowerCase()} ?`] : []);
  }
  if (pathHit) {
    const plans = G.files.filter((f) => (f.touched || []).includes(pathHit));
    if (!plans.length) return answer('Aucun plan', `Aucun plan ni nœud de mission ne déclare avoir touché \`${pathHit}\` (champ \`files_modified\`).`, []);
    return answer(`Qui a touché ${pathHit.split('/').pop()}`, `${plans.length} ${pl(plans.length, 'plan déclare', 'plans déclarent')} \`${pathHit}\` :\n${plans.slice(0, 12).map((p) => line(I, p)).join('\n')}`, plans.map((p) => item(I, p)));
  }
  const pool = target ? I.under(target.id) : [...G.nodes, ...G.files];
  const scope = target ? ` dans [[${I.ref(target)}]]` : '';
  if (/bloqu|coince|en echec|echoue/.test(q)) {
    const xs = pool.filter((x) => x.st === 'blocked');
    if (!xs.length) { const act = pool.filter((x) => x.st === 'active'); return answer('Rien de bloqué', `Rien n'est bloqué${scope}. En cours : ${act.length}.\n${act.slice(0, 8).map((x) => line(I, x)).join('\n')}`, act.map((x) => item(I, x))); }
    return answer(`${xs.length} ${pl(xs.length, 'bloqué', 'bloqués')}`, `${xs.length} ${pl(xs.length, 'élément bloqué', 'éléments bloqués')}${scope} (étape de mission en échec) :\n${xs.map((x) => line(I, x, I.label(I.N.get(x.n || x.parent) || {}) || '')).join('\n')}`, xs.map((x) => item(I, x)));
  }
  if (/en cours|actif|au travail|qui travaille/.test(q)) {
    const xs = pool.filter((x) => x.st === 'active');
    return answer(`${xs.length} en cours`, xs.length ? `En cours${scope} :\n${xs.slice(0, 12).map((x) => line(I, x)).join('\n')}` : `Rien en cours${scope} d'après .planning/. Pour les agents réellement au travail, voir le badge d'en-tête.`, xs.map((x) => item(I, x)));
  }
  if (/reste|a faire|prochain|suivant|restant|ensuite|next/.test(q)) {
    // CKPT-07 : sans jalon courant reconnu (STATE `milestone: v1.0` sans section homonyme), le jalon UNIQUE du ROADMAP ; à défaut, les phases à finir
    const jalons = G.nodes.filter((n) => /^ms-/.test(n.id || '')), t = target || curMs || (jalons.length === 1 ? jalons[0] : null);
    if (!t) {
      const phases = G.nodes.filter((n) => n.kind === 'phase'); if (!phases.length) return null; // rien à calculer : c'est à l'agent de lire le planning
      const reste = phases.filter((x) => x.st === 'todo' || x.st === 'active');
      return answer('Reste', reste.length ? `${reste.length} ${pl(reste.length, 'phase', 'phases')} à finir (aucun jalon courant reconnu) :\n${reste.slice(0, 12).map((x) => line(I, x)).join('\n')}${reste.length > 12 ? `\n- … et ${reste.length - 12} ${pl(reste.length - 12, 'autre', 'autres')}` : ''}` : 'Toutes les phases du planning sont terminées.', reste.map((x) => item(I, x)));
    }
    const xs = (t ? I.under(t.id) : pool).filter((x) => x !== t && (x.st === 'todo' || x.st === 'active') && (x.id ? x.kind === 'phase' || /^dag-/.test(x.id) : true));
    return answer(`Reste${t ? ' · ' + I.label(t).split(' · ')[0] : ''}`, `${xs.length} à finir dans [[${I.ref(t)}]]${t?.foot ? ` (${t.foot})` : ''} :\n${xs.slice(0, 12).map((x) => line(I, x)).join('\n')}${xs.length > 12 ? `\n- … et ${xs.length - 12} ${pl(xs.length - 12, 'autre', 'autres')}` : ''}`,
      [item(I, t), ...xs.map((x) => item(I, x))], xs[0] ? [`Qu'est-ce qui bloque ${dans(I.label(t).split(' · ')[0])} ?`] : []);
  }
  if (/exigence/.test(q) && phase) {
    const xs = exigencesDe(G).filter((e) => phaseDe(G, e) === phase), faites = xs.filter((e) => e.coche).length;
    return answer(`Exigences · Phase ${ph}`, `${xs.length} ${pl(xs.length, 'exigence', 'exigences')} pour [[${I.ref(phase)}]] (${faites} ${pl(faites, 'cochée', 'cochées')}) :\n${xs.slice(0, 14).map((e) => `- **${e.id}** · ${caseDe(e)}${e.libelle ? ` · ${coupe(e.libelle, 70)}` : ''}`).join('\n')}`, [item(I, phase)]);
  }
  if (target) {
    const sub = I.under(target.id).filter((x) => x !== target);
    const direct = [...(I.kids.get(target.id) || []), ...(I.files.get(target.id) || [])];
    return answer(I.label(target).split(' · ')[0], `[[${I.ref(target)}]] · ${etat(target)}.\n\n${target.summary || ''}\n\nContenu : ${sub.length ? count(sub) : 'rien encore (pas de plan)'}.\n${direct.slice(0, 10).map((x) => line(I, x)).join('\n')}`,
      [item(I, target), ...direct.map((x) => item(I, x))], [`Qu'est-ce qui reste ${dans(I.label(target).split(' · ')[0])} ?`, `Qu'est-ce qui bloque ${dans(I.label(target).split(' · ')[0])} ?`]);
  }
  if (/ou en (est|sommes)|on en est|etat|avancement|resume|statut|progression/.test(q)) {
    const cur = curMs, p = I.N.get('ph-' + vf.phase) || G.nodes.find((n) => n.kind === 'phase' && String(n.num) === String(vf.phase));
    const nexts = cur ? I.under(cur.id).filter((x) => x.kind === 'phase' && x.st !== 'done') : [];
    const jalon = cur ? `[[${I.ref(cur)}]]${cur.foot ? ` (${cur.foot})` : ''}` : `${vf.milestone ? `« ${vf.milestone} » (aucune carte de jalon ne porte ce nom dans le ROADMAP)` : 'non reconnu'}`;
    const aucunState = !vf.milestone && !vf.phase && !vf.status && !vf.lastActivity;
    const reste = (aucunState ? G.nodes.filter((n) => n.kind === 'phase' && n.st !== 'done') : nexts).filter((x) => x !== p); // la dernière phase est dite une fois, dans la phrase
    const autresJalons = G.nodes.filter((n) => /^ms-/.test(n.id || '') && n.st === 'active' && n !== cur);
    const st = statutLisible(vf.status);
    const phrase = [
      aucunState ? 'Pas de STATE.md dans ce lab : le jalon et la phase courants ne sont pas suivis.' : '',
      !aucunState && (cur || vf.milestone) ? `Jalon en cours : ${jalon}.` : '',
      // une phase connue du graphe porte SON état (celui de sa carte) ; le statut de STATE.md est dit à part, comme celui du projet
      !aucunState && p ? `Dernière phase : [[${I.ref(p)}]]${p.st ? ` · ${etat(p)}` : ''}${vf.lastActivity ? `, le ${vf.lastActivity}` : ''}.${st ? ` Statut noté dans STATE.md : ${st}${vf.stateStale ? ' (STATE.md semble périmé)' : ''}.` : ''}` : '',
      !aucunState && !p && vf.phase ? `Dernière phase : ${[vf.phase, st].filter(Boolean).join(' · ')}${vf.lastActivity ? `, le ${vf.lastActivity}` : ''}.` : '',
      !aucunState && autresJalons.length ? `Autres jalons en cours : ${autresJalons.map((m) => `[[${I.ref(m)}]]${m.foot ? ` (${m.foot})` : ''}`).join(', ')}.` : '',
      !aucunState && !p && !vf.phase && (st || vf.lastActivity) ? `${[st, vf.lastActivity && `le ${vf.lastActivity}`].filter(Boolean).join(', ')}.` : '',
    ].filter(Boolean).join(' ');
    return answer('Où on en est', `${phrase}${reste.length ? `\n\n${aucunState ? 'Phases à finir (d\'après le ROADMAP)' : 'À finir dans le jalon'} :\n${reste.slice(0, 8).map((x) => line(I, x)).join('\n')}` : ''}`,
      [cur, p, ...autresJalons, ...reste].filter(Boolean).map((x) => item(I, x)), ["Qu'est-ce qui bloque ?", "Qu'est-ce qui est en cours ?"]);
  }
  return null;
}

/** Prompt de l'agent pour l'onglet Projet (voie LLM). */
export function instructions(G) {
  return [
    `Tu réponds à des questions sur l'avancement du projet « ${G.project.name} » (méthode VibeFlow, planning dans .planning/), pour quelqu'un qui explore la carte interactive de ce planning. Réponds en français.`,
    'Cartes de la carte : jalons (n:ms-<clé>), phases (n:ph-<N>), missions (n:dag-MISSION-<N>), Historique, Backlog, Graines, Releases ; éléments : plans (f:<chemin du PLAN.md>), étapes de mission, entrées de backlog, tags (f:tag/<vX>). Les exigences n\'ont pas de carte : elles se lisent dans meta.vf.trace.exigences ou dans REQUIREMENTS.md.',
    'Chaque carte porte un statut st (done = fait, active = en cours, todo = à faire, blocked = étape de mission en échec) et un pied foot (progression, vague, nombre de fichiers). « blocked » de dag.sh (attend ses dépendances) est déjà ramené à todo.',
    'Interroge la carte depuis le shell : `node <module>/scripts/vf-cockpit-query.mjs overview`, `find "<mots>"`, `show <id>`, ' +
    '`status <done|active|todo|blocked> [--in <id>]`, `path <idA> <idB>`. Chaque résultat est du JSON avec ids et statuts. ' +
    'Lis les fichiers de .planning/ (ROADMAP, PLAN, SUMMARY, STATE) seulement pour un détail que la carte n\'a pas.',
    'Quelques requêtes, pas des dizaines. Puis réponds en JSON seulement : {"title", "answer", "items", "steps", "followups"}.',
    '- answer : Markdown, ~180 mots au plus, concret. Cite les cartes en ligne sous la forme [[id]] (elles deviennent cliquables).',
    '- items : les 3 à 14 cartes qui montrent la réponse, la plus importante d\'abord, chacune avec une note de 15 mots au plus.',
    '- steps : une suite ordonnée quand la réponse est une séquence (enchaînement de phases, étapes d\'une mission) ; sinon [].',
    '- followups : 2 ou 3 questions de suite, courtes, en français.',
    'N\'utilise que des ids rendus par la carte.',
  ].join('\n');
}
