// VibeFlow (73-04) : modèle pur de la régie (onglet Équipe) : sections, lignes, mots, durées, clés, tri d'« À vous », liste blanche du verrou.
// Aucun DOM, aucun réseau. Pose window.__vfRegieModele ; lit window.__vfEquipeRendu à l'appel (glyphes, garde d'orphelin, seuils : jamais recopiés).
(() => {
  const R = () => window.__vfEquipeRendu;
  const NB = ' ', DP = ' :', GEN = 'lance une commande', JOUR = 86400;
  const nbf = (v) => typeof v === 'number' && Number.isFinite(v) && v >= 0;
  const num = (v) => (nbf(v) ? v : null), nombre = (a, b) => (nbf(a) ? a : num(b));
  const sans = (v) => (typeof v === 'string' ? v.replace(/[\p{Cc}\p{Cf}]/gu, '').trim() : '');
  // champ d'un verrou : une FORME ADMISE (jeu de caractères et longueur bornés), jamais un refus par préfixe : une valeur hors forme (chemin au milieu,
  // relatif, file:, ../, ~) devient vide et ne s'affiche pas. Sans contrôle ni classe Cf (U+202E compris) ; la borne coupe avant l'épreuve de forme.
  const admis = (v, forme, n) => { const s = sans(v).slice(0, n); return forme.test(s) ? s : ''; };
  // owner, étape : aucun séparateur (release-bump, exec-73, vf-dev-manager-p73, identifiants hexadécimaux)
  const libre = (v) => admis(v, /^[A-Za-z0-9][A-Za-z0-9_-]*$/, 80);
  const wsOk = (v) => admis(v, /^[a-z0-9-]+$/, 80), phaseOk = (v) => admis(v, /^[0-9]+(\.[0-9]+)?$/, 12);
  const scopeOk = (v) => admis(v, /^(depot|compartiment|phase|mission|lab)$/, 12), dagOk = (v) => admis(v, /^[A-Za-z0-9][A-Za-z0-9._-]*$/, 200);

  // ---------- le verrou : liste blanche champ par champ (la forme brute de driver-lock.sh et la forme projetée donnent le même objet) ----------
  const verrouBlanc = (e) => {
    e = e && typeof e === 'object' ? e : {};
    const o = { ws: wsOk(e.ws), scope: scopeOk(e.scope), phase: phaseOk(e.phase), step: libre(e.step), // garde:verrou-liste-blanche
      tenu: e.tenu === true || e.present === true, stale: e.stale === true, ageS: nombre(e.ageS, e.age_seconds), ttl: num(e.ttl),
      progressAgeS: nombre(e.progressAgeS, e.progress_age_seconds), owner: libre(e.owner),
      childrenRunning: nombre(e.childrenRunning, e.children_running), leaseS: nombre(e.leaseS, e.lease_seconds),
      sansSession: typeof e.sansSession === 'boolean' ? e.sansSession : null };
    const dag = dagOk(e.dag); if (dag) o.dag = dag;
    return o;
  };
  const entrees = (l) => (Array.isArray(l) ? l : l && typeof l === 'object'
    ? [l.verrous && l.verrous.liste, l.verrous, l.liste, l.locks].find(Array.isArray) || ('owner' in l || 'present' in l ? [l] : []) : []);
  const verrous = (l) => entrees(l).filter((e) => e && typeof e === 'object').map(verrouBlanc).filter((v) => v.tenu);

  // ---------- durées et mots ----------
  const D = (s) => (s == null ? '' : String(R().duree(Math.round(s))).replace(/ /g, NB));
  const nds = (n) => `${n}${NB}nœud${n > 1 ? 's' : ''}`;
  const plur = (n, un, plu) => (n > 1 ? plu : un);
  const impactDe = (w) => { const r = w && w.retient; return r && Number.isInteger(r.n) && r.n >= 0 ? r : null; };
  const impactMot = (r) => (!r ? 'impact inconnu' : r.n === 0 ? 'ne retient rien'
    : r.portee === 'mission' ? `retient toute la mission · ${nds(r.n)}` : `retient ${nds(r.n)}`);
  // fenêtre de stall : celle du contexte, sinon celle du `who` ; inconnue = null (aucune marque de progrès, jamais « suspect »)
  const fenetreDe = (c, who) => { const v = c && c.fenetre !== undefined ? c.fenetre : who && who.fenetreStallS; return nbf(v) ? v : null; };
  const ecoule = (w, c) => (w.etat !== 'termine' && nbf(c.now) && nbf(c.recuA) ? Math.max(0, Math.round((c.now - c.recuA) / 1000)) : 0);
  const verbeDe = (w) => {
    const a = w.action || {};
    return typeof a.verbe === 'string' && a.verbe !== GEN ? [a.verbe, a.cible].filter((x) => typeof x === 'string' && x).join(' ') : '';
  };
  const arbreDe = (w) => {
    const t = String(w.tree || '').replace(/^\.claude\/worktrees\//, '');
    return !t || t === '.' || t === 'arbre principal' ? 'main' : t;
  };
  const S = (etat, mot, poids, detail, prefixe, valeur) => ({ etat, mot, poids, detail, duree: { prefixe, valeur } });
  const attendA = (w) => w.kind === 'session' && !['actif', 'termine', 'attend', 'bloque'].includes(w.etat)
    && Number.isInteger(w.attendAgents) && w.attendAgents > 0;

  // P73-D-11, D-12, D-13, D-15 : l'état en mots d'un agent (glyphes du lot 0 repris de 71, jamais recopiés)
  function etatVivant(w, c) {
    c = c || {};
    const r = R(), G = r.GLYPHE_ETAT, fen = fenetreDe(c), age = nbf(w.ageS) ? w.ageS + ecoule(w, c) : null;
    const tenue = nbf(w.dureeS) ? w.dureeS + ecoule(w, c) : null, depuis = tenue != null ? tenue : age;
    if (w.etat === 'termine') {
      const mot = w.finMotif === 'echec' ? 'échec' : w.finMotif === 'arret' ? 'arrêté' : w.kind === 'subagent' && !c.grise ? 'rapport rendu' : 'terminé';
      return S(G.termine, mot, 400, age == null ? '' : `il y a ${D(age)}`, 'a duré', D(w.dureeS));
    }
    if (r.estOrphelin(w, c.parent)) return S('orphelin', 'orphelin', 600, 'son parent est terminé, cet agent travaille encore', 'depuis', D(depuis));
    if (attendA(w)) return S(G['en-attente'], `attend ses agents (${w.attendAgents})`, 400, '', 'depuis', D(age));
    if (w.etat === 'attend') return S(G.attend, 'vous attend', 400, impactMot(impactDe(w)), 'attend depuis', D(age));
    if (w.etat === 'au-repos') {
      return S(G['au-repos'], 'au repos', 400, arbreDe(w) === 'main' ? '' : `autre arbre${DP} ${arbreDe(w)}`, 'au repos depuis', D(age));
    }
    if (w.etat === 'en-attente') return S(G['en-attente'], 'en attente', 400, '', 'depuis', D(depuis));
    if (w.etat === 'bloque') return S(G.bloque, 'bloqué', 400, '', 'depuis', D(depuis));
    const cmd = w.etat === 'actif' && (w.enCours === true || (w.action || {}).verbe === GEN);
    if (cmd && age != null && age >= r.LONGUE_S) return S('surveiller', `commande longue${DP} ${D(age)}`, 600, '', 'depuis', D(age));
    if (!cmd && age != null && age >= r.CALME_S) {
      if (fen != null && age > fen) return S('surveiller', `suspect${DP} aucun signe de vie depuis ${D(age)}`, 600, '', 'écrit il y a', D(age));
      return S('surveiller', `silencieux depuis ${D(age)}`, 400, '', 'écrit il y a', D(age));
    }
    const sorte = (w.action || {}).verbe === GEN ? 'commande' : 'outil';
    const detail = cmd && age != null && age >= r.CALME_S ? `${sorte} en cours depuis ${D(age)}` : '';
    return S(G.actif, verbeDe(w) || 'au travail', 400, detail, tenue != null ? 'depuis' : 'écrit il y a', D(tenue != null ? tenue : age));
  }

  // P73-D-07 : trois rangs (impact connu > 0 décroissant, inconnu, connu = 0), puis la plus ancienne attente, le nom, l'identifiant ; comparateur total
  const rangDe = (l) => (l.impact == null ? 1 : l.impact > 0 ? 0 : 2);
  const rangT = (l) => (l.kind === 'question' ? l.rang - 1 : rangDe(l)); // 73-11 : une question prend le rang 2 ou 3
  const cmp = (a, b) => (a < b ? -1 : a > b ? 1 : 0);
  const trierAVous = (ls) => ls.slice().sort((a, b) => rangT(a) - rangT(b) || (rangT(a) === 0 ? b.impact - a.impact : 0)
    || (a.kind === 'question') - (b.kind === 'question') || (a.kind === 'question' ? a.ordre - b.ordre : 0) // à ancienneté d'abord, puis les questions
    || (b.age || 0) - (a.age || 0) || cmp(a.nom, b.nom) || cmp(a.id, b.id));

  const phasesDe = (who) => (who && Array.isArray(who.phasesHumaines) ? who.phasesHumaines : [])
    .filter((p) => p && typeof p === 'object' && (typeof p.phase === 'string' || typeof p.phase === 'number')
      && String(p.phase) !== '' && typeof (p.ws || '') === 'string');
  const sessionsQuiAttendent = (who) => (who && Array.isArray(who.workers) ? who.workers : [])
    .filter((w) => w && w.kind === 'session' && w.etat === 'attend' && typeof w.id === 'string');
  const aVous = (who) => sessionsQuiAttendent(who).length + phasesDe(who).length;

  const VERBES = { cadrer: 'cadrer', planifier: 'planifier', executer: 'exécuter', verifier: 'vérifier', reprendre: 'reprendre' };
  const lancement = (l) => (l && typeof l === 'object' && /^[0-9]+(\.[0-9]+)*$/.test(String(l.phase)) && Object.hasOwn(VERBES, l.verbe)
    && /^[A-Za-z0-9._-]{0,80}$/.test(l.ws || '')
    ? `Lancée depuis la carte${DP} Phase ${l.phase}${l.ws ? ` · ${l.ws}` : ''} · ${VERBES[l.verbe]}` : '');
  const court = (o) => (/^[0-9a-f-]{16,}$/i.test(o) ? o.slice(0, 8) : o);
  const LIMITE = "L'impact compte les nœuds du plan, pas leur durée ni leur importance.";
  // une ligne de la régie : tous les champs, ceux qui ne servent pas à un genre de ligne gardent leur valeur vide
  const VIDE = { role: '', etat: '', mot: '', poids: 400, detail: '', ligne2: [], duree: { prefixe: '', valeur: '' }, action: null, niveau: 0,
    parent: null, grise: false, noeud: '', age: null, lien: '', impact: null, infobulle: '' };
  const rangee = (o, agent) => ({ ...VIDE, ligne2: [], duree: { prefixe: '', valeur: '' }, ...o,
    attrs: { agent: agent || '', noeud: o.noeud || '', etat: o.etat || '' } });
  const ref = (v) => `project.html#r=${encodeURIComponent(v)}`;

  function modele(who, lock, ctx) {
    const c = Object.assign({}, ctx), r = R(), nc = c.nonCommite && typeof c.nonCommite === 'object' ? c.nonCommite : {};
    const W = (who && Array.isArray(who.workers) ? who.workers : [])
      .filter((w) => w && (w.kind === 'session' || w.kind === 'subagent') && typeof w.id === 'string');
    c.fenetre = fenetreDe(c, who);
    const noms = r.nommer(W), par = new Map(W.map((w) => [w.id, w]));
    const lus = new Set(c.lus instanceof Set || Array.isArray(c.lus) ? [...c.lus] : c.lus && typeof c.lus === 'object' ? Object.keys(c.lus) : []);
    const nomDe = (w) => (w.kind === 'session' ? noms.get(w.id) || 'Session principale'
      : w.task || (w.etat === 'termine' ? `${w.role || 'Agent'} · ${String(w.id).slice(0, 8)}` : w.role || 'Agent'));
    const enfants = new Map();
    for (const w of W) {
      const p = w.kind === 'subagent' && w.parent !== w.id && par.has(w.parent) ? w.parent : null;
      if (p) enfants.set(p, [...(enfants.get(p) || []), w]);
    }
    const vivant = (w) => ['actif', 'bloque', 'en-attente', 'attend'].includes(w.etat) || attendA(w);
    const porte = (w, d = 0) => vivant(w) || (d < 8 && w.etat !== 'au-repos' && (enfants.get(w.id) || []).some((k) => porte(k, d + 1)));
    const rendu = (w) => vivant(w) || (w.etat === 'termine' && porte(w));

    const ligne = (w, sec, o = {}) => {
      const sess = w.kind === 'session', rat = w.rattachement, n = rat && rat.etat === 'rattache' ? rat : null, fini = w.etat === 'termine';
      const e = etatVivant(w, { ...c, parent: o.parent, grise: o.grise }), lire = !!o.lire, raison = rat && rat.raison;
      const impact = sec === 'a-vous' ? impactDe(w) : null, nm = nc[w.branch] > 0 ? `${nc[w.branch]} modifié${plur(nc[w.branch], '', 's')}` : '';
      const horsPhase = !raison || raison === 'inconnu' || raison === 'sans-citation' ? 'non lié à une phase du projet' : `non rattaché (${raison})`;
      const arbre = o.sansArbre ? '' : sess || !o.parent || arbreDe(o.parent) !== arbreDe(w) ? `arbre ${arbreDe(w)}` : '';
      const ligne2 = [n ? `nœud ${n.noeud}` : w.kind === 'subagent' && !fini ? horsPhase : '', nm, arbre,
        sess && w.branch ? `branche ${w.branch}` : '', sess ? lancement(w.lancee) : ''].filter(Boolean);
      return rangee({ cle: `${sec}:${w.id}`, id: w.id, kind: w.kind, nom: nomDe(w), role: !sess && w.task ? w.role || 'Agent' : '',
        etat: e.etat, mot: e.mot, poids: e.poids, detail: sec === 'au-travail' && w.etat === 'attend' ? '' : e.detail, ligne2, duree: e.duree,
        action: lire ? 'lire-rapport' : null, niveau: o.niveau || 0, parent: o.parent ? o.parent.id : null, grise: !!o.grise,
        noeud: n ? String(n.noeud) : '', age: nbf(w.ageS) ? w.ageS + ecoule(w, c) : null, lien: n ? ref(`f:${n.dag}#${n.noeud}`) : '',
        impact: impact ? impact.n : null, infobulle: sec === 'a-vous' && !impact ? LIMITE : '' }, w.id);
    };
    const lignePhase = (p) => {
      const id = `phase:${p.ws || ''}:${p.phase}`, etat = r.GLYPHE_ETAT.attend, aRef = typeof p.ref === 'string';
      return rangee({ cle: `a-vous:${id}`, id, kind: 'phase', nom: `Phase ${p.phase}${DP} vérification humaine demandée`, etat, mot: 'vous attend',
        detail: 'impact inconnu', ligne2: aRef ? ['carte de la phase'] : [], lien: aRef ? ref(p.ref) : '', infobulle: LIMITE });
    };

    // À vous : sessions qui attendent, phases à vérification humaine, et (73-11, P73-D-37) questions en attente des cadrages quand le contexte les porte
    const Q = window.__vfRegieQuestions, qs = c.questions && Q ? Q.lignes(c.questions) : [];
    const avous = trierAVous([...sessionsQuiAttendent(who).map((w) => ligne(w, 'a-vous')), ...phasesDe(who).map(lignePhase), ...qs]);

    // Au travail : lignes de mission (verrous tenus hors dépôt), puis l'arbre, deux niveaux au plus
    const vs = verrous(lock), glyphe = 'surveiller';
    const marques = (v) => [
      v.stale ? { texte: 'verrou abandonné', glyphe, infobulle: '' } : null,
      v.progressAgeS != null && c.fenetre != null && v.progressAgeS > c.fenetre
        ? { texte: `aucun nœud marqué depuis ${D(v.progressAgeS)}`, glyphe,
          infobulle: 'Compté sur les nœuds marqués du plan, pas sur les commits.' } : null,
    ].filter(Boolean);
    const texteV = (v, pre) => [`${pre} ${(v.sansSession !== true && noms.get(v.owner)) || court(v.owner) || 'détenteur inconnu'}`, v.step,
      v.leaseS != null ? `tenu depuis ${D(v.leaseS)}` : '', v.ageS != null ? `dernier signe il y a ${D(v.ageS)}` : ''].filter(Boolean).join(' · ');
    const missions = vs.filter((v) => v.scope !== 'depot').sort((a, b) => cmp(a.ws, b.ws) || cmp(a.phase, b.phase)).map((v) => {
      const id = `mission:${v.ws}:${v.phase}`;
      return { ...rangee({ cle: `au-travail:${id}`, id, kind: 'mission', nom: texteV(v, `verrou${DP}`) }), marques: marques(v) };
    });
    const depot = vs.find((v) => v.scope === 'depot');
    const verrouDepot = depot ? { texte: texteV(depot, `Verrou du dépôt${DP}`), marques: marques(depot) } : null;
    const travail = [], pose = (w, niveau, parent) => {
      if (niveau > 8) return;
      travail.push(ligne(w, 'au-travail', { niveau: Math.min(niveau, 2), parent, grise: w.etat === 'termine' }));
      const fils = (enfants.get(w.id) || []).filter(rendu).sort((a, b) => (b.dureeS || 0) - (a.dureeS || 0) || cmp(a.id, b.id));
      for (const k of fils) pose(k, niveau + 1, w);
    };
    const racines = W.filter((w) => rendu(w) && !(w.kind === 'subagent' && par.has(w.parent) && w.parent !== w.id && rendu(par.get(w.parent))));
    for (const w of racines.sort((a, b) => cmp(nomDe(a), nomDe(b)) || cmp(a.id, b.id))) pose(w, 0, null);

    // Terminé, à relire : sous-agents terminés de moins de 24 h hors « lus » ; Au repos : sessions vivantes sans activité
    const frais = (w) => !nbf(w.ageS) || w.ageS < JOUR, vieux = (w) => (nbf(w.ageS) ? w.ageS : Infinity);
    const recents = (a, b) => vieux(a) - vieux(b) || cmp(a.id, b.id);
    const finis = W.filter((w) => w.kind === 'subagent' && w.etat === 'termine' && frais(w)).sort(recents);
    const closes = W.filter((w) => w.kind === 'session' && w.etat === 'termine' && frais(w)).sort(recents);
    const aRelire = finis.filter((w) => !lus.has(w.id)), relus = [...finis.filter((w) => lus.has(w.id)), ...closes];
    const repos = W.filter((w) => w.kind === 'session' && w.etat === 'au-repos' && !attendA(w)).sort(recents);
    const reste = (tot, max) => ({ n: Math.max(0, tot - max), texte: tot - max > 1 ? `Les ${tot - max} autres` : tot - max === 1 ? 'Un autre' : '' });
    const rr = reste(aRelire.length, 8), rp = reste(repos.length, 6), ms = who && who.sortisSilence;
    const muets = Number.isInteger(ms) && ms > 0 ? ms : 0;
    const sec = (id, titre, vide, lignes, o = {}) => ({ id, titre, aide: '', compte: lignes.filter((l) => l.kind !== 'mission').length, vide, lignes,
      autres: 0, autresTexte: '', relus: [], relusTitre: '', pied: '', ...o });
    const sections = [
      sec('a-vous', 'À vous', c.questions && Q ? Q.vide(c.questions) : 'Rien ne vous attend.', avous,
        { questions: c.questions && Q ? Q.bloc(c.questions) : null, aide: 'classé par ce que chaque attente retient dans le plan',
          pied: `${LIMITE} Sans plan visible, il n'est pas mesuré.` }),
      sec('au-travail', 'Au travail', 'Personne ne travaille en ce moment.', [...missions, ...travail],
        { pied: muets ? `${muets} muet${plur(muets, '', 's')} depuis plus de 30${NB}min, retiré${plur(muets, '', 's')}` : '' }),
      sec('a-relire', 'Terminé, à relire', 'Aucun rapport à relire.', aRelire.slice(0, 8).map((w) => ligne(w, 'a-relire', { lire: true })),
        { compte: aRelire.length, ids: aRelire.map((w) => w.id), autres: rr.n, autresTexte: rr.texte, relus: relus.map((w) => ligne(w, 'a-relire')),
          relusTitre: `Relus ou sans rapport · ${relus.length}` }),
      sec('au-repos', 'Au repos', 'Aucune session au repos.', repos.slice(0, 6).map((w) => ligne(w, 'au-repos', { sansArbre: true })),
        { compte: repos.length, autres: rp.n, autresTexte: rp.texte }),
    ];
    const enVie = W.filter((w) => w.etat !== 'termine').length, p = avous.length - qs.length, q = aRelire.length;
    const sousTitre = [enVie > 0 ? `${enVie} ${plur(enVie, 'agent', 'agents')}` : 'Aucun agent en vie',
      p ? `${p} ${plur(p, 'vous attend', 'vous attendent')}` : '', q ? `${q} à relire` : ''].filter(Boolean).join(' · ');
    const h1 = r.titreEquipe(c.missions, { actif: W.filter(r.actif).length });
    return { entete: { h1, sousTitre, verrouDepot }, sections, etatPage: W.length ? '' : 'Aucun agent dans les dernières 24 h.' };
  }

  window.__vfRegieModele = { modele, aVous, verrouBlanc, verrous, trierAVous, etatVivant };
})();
