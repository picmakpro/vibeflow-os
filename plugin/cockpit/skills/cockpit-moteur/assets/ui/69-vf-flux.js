// VibeFlow (79-14) : un seul flux d'événements par navigateur et par lab (SOCL-18, C4, P79-D-14). Un onglet élu par Web Locks tient l'unique
// EventSource et relaie chaque événement aux autres onglets du même lab par BroadcastChannel ; aucun jeton ne circule sur le canal.
// Sans ces primitives, hors contexte sûr ou sans empreinte du lab : un flux par page. Veille : au-delà de 45 s sans événement (vie compris)
// le flux est déclaré perdu, d'après des instants. Porte du magasin : window.VF_FLUX. Rien ne s'exécute avant ouvrir() (page exportée : aucun effet).
// vf-coquille: persistant
(() => {
  // 79-16 : ce que ce fichier pose APRÈS son élection (flux, veille, minuteries) passe par les primitives natives de la coquille :
  // la portée d'un onglet n'y touche pas
  const N = (typeof window !== 'undefined' && window.VF_COQUILLE && window.VF_COQUILLE.natif) || null;
  const SO = N ? N.setTimeout : (...a) => setTimeout(...a), SI = N ? N.setInterval : (...a) => setInterval(...a);
  const PREFIXE = 'vf-cockpit-flux:';
  const MAX_DONNEE = 1048576;
  const MAX_NOEUDS = 100000;
  const MAX_PROF = 64;
  const SILENCE_MS = 45000;
  const PONG_MS = 2000;
  const GIGUE_MS = 1000;
  const INTERDITS = ['doing', 'mandat', 'messages', 'outils', 'fil']; // garde:flux-interdits
  const EVENEMENTS = [ // garde:flux-evenements
    'etat',
    'frise',
    'graphe',
    'git',
    'hello',
    'lock',
    'patch',
    'reload',
    'structural',
    'vie',
    'who',
    // vf-repere-regle : chaque phase insère ses noms derrière son repère ; les repères sont retirés à la clôture du jalon.
    // vf-repere:phase-73
    // vf-repere:phase-74
    // vf-repere:phase-75
    // vf-repere:phase-76
    // vf-repere:phase-77
    // vf-repere:phase-80
    // vf-repere:phase-81
  ];
  const REJEU = ['hello', 'who', 'lock'];
  const CLES = { evt: 'data,nom,t,v', rejeu: 'a,data,nom,t,v', salut: 'id,t,v', ping: 'id,t,v', pong: 't,v', perdu: 't,v' };
  const S = { init: false, jeton: null, role: null, nom: null, bc: null, es: null, ac: null, conn: 'reprise', motif: null, derniere: 0, pong: false,
    tVol: null, id: Math.random().toString(36).slice(2, 10), sources: new Set(), mem: new Map(), abonnes: new Map(), cbConn: [],
    recus: {}, relayes: 0, refuses: 0 };

  // ---------- entrées : une donnée non fiable jusqu'à validation ----------
  const donneeValide = (brut) => { // objet simple, aucune clé interdite à toute profondeur, bornes de nœuds et de profondeur ; rend l'objet ou null
    if (typeof brut !== 'string' || brut.length > MAX_DONNEE) return null;
    let racine; try { racine = JSON.parse(brut); } catch { return null; }
    if (racine === null || typeof racine !== 'object' || Array.isArray(racine)) return null;
    const pile = [[racine, 1]]; let noeuds = 0;
    while (pile.length) {
      const [v, prof] = pile.pop();
      if (++noeuds > MAX_NOEUDS || prof > MAX_PROF) return null;
      if (v === null || typeof v !== 'object') continue;
      if (Array.isArray(v)) { for (const x of v) pile.push([x, prof + 1]); continue; }
      for (const k of Object.keys(v)) { if (INTERDITS.includes(k)) return null; pile.push([v[k], prof + 1]); }
    }
    return racine;
  };
  const messageValide = (m) => {
    if (m === null || typeof m !== 'object' || Array.isArray(m) || m.v !== 1 || typeof m.t !== 'string') return false;
    if (!Object.prototype.hasOwnProperty.call(CLES, m.t) || Object.keys(m).sort().join() !== CLES[m.t]) return false;
    if ('nom' in m && !(typeof m.nom === 'string' && EVENEMENTS.includes(m.nom))) return false;
    if ('data' in m && !donneeValide(m.data)) return false;
    for (const c of ['id', 'a']) if (c in m && !(typeof m[c] === 'string' && m[c].length > 0 && m[c].length <= 32)) return false;
    return true;
  };

  // ---------- connexion et abonnements ----------
  const majConn = (e) => {
    if (S.conn === e) return; S.conn = e;
    for (const f of [...S.cbConn]) { try { f(e); } catch { /* un rappel qui lève n'arrête rien */ } }
  };
  const livrerAbonnes = (nom, data, meta) => {
    const fs = S.abonnes.get(nom); if (!fs || !fs.size) return;
    const charge = donneeValide(data); if (!charge) return;
    for (const f of [...fs]) { try { f(charge, meta); } catch { /* idem */ } }
  };
  const diffuser = (nom, data, rejeu, relaye) => { // livre aux sources de la page (70) puis aux abonnés du magasin ; tout événement remet la veille à zéro
    S.recus[nom] = (S.recus[nom] || 0) + 1; S.derniere = Date.now(); majConn('ouvert');
    if (REJEU.includes(nom)) { S.mem.delete(nom); S.mem.set(nom, data); }
    for (const src of [...S.sources]) src._livrer(nom, data);
    livrerAbonnes(nom, data, { relaye, rejeu });
  };
  const creerSource = () => {
    const ecout = new Map();
    const src = { onerror: null, closed: false,
      addEventListener: (nom, f) => { if (!ecout.has(nom)) ecout.set(nom, new Set()); ecout.get(nom).add(f); },
      removeEventListener: (nom, f) => { const e = ecout.get(nom); if (e) e.delete(f); },
      close: () => { src.closed = true; S.sources.delete(src); if (S.conn === 'perdu') fermerReel(); }, // le consommateur ferme le flux perdu, comme avant
      _livrer: (nom, data) => { if (src.closed) return; for (const f of [...(ecout.get(nom) || [])]) { try { f({ type: nom, data }); } catch { /* idem */ } } },
      _perdu: () => { if (src.closed || typeof src.onerror !== 'function') return; try { src.onerror({ type: 'error' }); } catch { /* idem */ } } };
    return src;
  };

  // ---------- canal, relais, flux réel ----------
  const poster = (m) => { if (S.bc) { try { S.bc.postMessage(m); } catch { /* canal fermé */ } } };
  const fermerReel = () => { const e = S.es; S.es = null; if (e) { try { e.close(); } catch { /* déjà fermé */ } } };
  const declarerPerdu = (motif) => { // une seule déclaration par perte
    if (S.conn === 'perdu') return;
    S.motif = motif; majConn('perdu'); S.mem.clear();
    if (S.role === 'elu') poster({ v: 1, t: 'perdu' }); // garde:flux-perdu-relais
    for (const src of [...S.sources]) src._perdu();
  };
  const recu = (nom, data) => { // événement du flux réel de cet onglet
    if (typeof data !== 'string') return;
    const relayer = S.role === 'elu' && !!S.bc && !!donneeValide(data) && !data.includes(S.jeton); // garde:flux-relais-jeton
    if (relayer) { S.relayes++; poster({ v: 1, t: 'evt', nom, data }); }
    diffuser(nom, data, false, false);
  };
  const ouvrirReel = () => {
    if (S.es) return;
    const es = new (N && N.EventSource ? N.EventSource : EventSource)('/api/vf/events?token=' + encodeURIComponent(S.jeton));
    S.es = es;
    for (const nom of EVENEMENTS) es.addEventListener(nom, (e) => recu(nom, e.data));
    es.onerror = () => { if (S.es !== es) return; declarerPerdu('erreur'); };
  };
  const rejouerA = (id) => { for (const [nom, data] of S.mem) poster({ v: 1, t: 'rejeu', a: id, nom, data }); }; // garde:flux-rejeu
  const annulerVol = () => { if (S.tVol !== null) { clearTimeout(S.tVol); S.tVol = null; } };
  const surMessage = (ev) => {
    const m = ev && ev.data;
    if (!messageValide(m)) { S.refuses++; return; } // garde:flux-entree
    const suiveur = S.role === 'suiveur';
    if (m.t === 'salut' || m.t === 'ping') {
      if (S.role !== 'elu') return;
      if (m.t === 'salut') rejouerA(m.id); else poster({ v: 1, t: 'pong' }); // garde:flux-pong
    } else if (!suiveur) return;
    else if (m.t === 'pong') S.pong = true;
    else if (m.t === 'perdu') declarerPerdu('relais');
    else if (m.t === 'evt' || (m.t === 'rejeu' && m.a === S.id)) { S.pong = true; annulerVol(); diffuser(m.nom, m.data, m.t === 'rejeu', true); }
  };

  // ---------- élection ----------
  const supporte = () => typeof BroadcastChannel === 'function' && typeof navigator !== 'undefined' && !!navigator.locks && // garde:flux-repli
    typeof navigator.locks.request === 'function' && typeof isSecureContext !== 'undefined' && isSecureContext === true;
  const lireLab = (jeton) => {
    if (typeof fetch !== 'function') return Promise.resolve(null);
    return fetch('/api/vf/modeles', { headers: { 'x-vf-cockpit-token': jeton }, cache: 'no-store' })
      .then((r) => (r && r.ok ? r.json() : null))
      .then((j) => (j && typeof j.lab === 'string' && /^[0-9a-f]{12}$/.test(j.lab) ? j.lab : null)).catch(() => null);
  };
  const devenirElu = () => { // l'élu ne relâche jamais le verrou de lui-même : promesse jamais résolue
    S.role = 'elu'; S.derniere = Date.now(); majConn('reprise'); ouvrirReel(); return new Promise(() => {});
  };
  const abandonne = () => { // verrou volé : plus qu'un suiveur, remis en file
    fermerReel(); S.mem.clear(); S.role = 'suiveur'; S.derniere = Date.now(); majConn('reprise');
    poster({ v: 1, t: 'salut', id: S.id }); attendreVerrou();
  };
  const apresVerrou = (p) => p.catch((e) => { if (e && e.name === 'AbortError' && S.role === 'elu') abandonne(); });
  function attendreVerrou() { // file d'attente : le verrou descend la file à la fermeture de l'élu
    S.ac = new AbortController();
    apresVerrou(navigator.locks.request(S.nom, { signal: S.ac.signal }, () => devenirElu()));
  }
  const voler = () => { // élu muet : prise de force du verrou, un seul flux au final (l'ancien élu apprend l'abandon par AbortError)
    if (S.role !== 'suiveur') return;
    if (S.ac) S.ac.abort();
    apresVerrou(navigator.locks.request(S.nom, { steal: true }, () => devenirElu())); // garde:flux-vol
  };
  const interrogerElu = () => { // un suiveur dont la veille a coupé : ping, puis vol sans pong après PONG_MS plus une gigue
    S.pong = false; annulerVol(); poster({ v: 1, t: 'ping', id: S.id });
    const delai = PONG_MS + Math.floor(Math.random() * GIGUE_MS); // garde:flux-gigue
    S.tVol = SO(() => { S.tVol = null; if (!S.pong && S.role === 'suiveur' && S.conn !== 'ouvert') voler(); }, delai);
  };
  const elire = () => {
    apresVerrou(navigator.locks.request(S.nom, { ifAvailable: true }, (verrou) => {
      if (verrou) return devenirElu();
      S.role = 'suiveur'; poster({ v: 1, t: 'salut', id: S.id }); attendreVerrou(); return undefined;
    }));
  };
  const decider = () => {
    if (!supporte()) { S.role = 'page'; ouvrirReel(); return; }
    lireLab(S.jeton).then((lab) => {
      if (!lab) { S.role = 'page'; ouvrirReel(); return; } // jamais de partage sans preuve d'identité du lab
      S.nom = PREFIXE + lab; S.bc = new BroadcastChannel(S.nom); S.bc.onmessage = surMessage; elire();
    });
  };

  // ---------- veille ----------
  const verifier = () => { // des instants, jamais un compte de passages : un onglet de fond ou gelé est jugé au premier passage
    const maintenant = Date.now();
    if (maintenant < S.derniere) S.derniere = maintenant; // recul d'horloge
    if (S.conn !== 'perdu' && maintenant - S.derniere > SILENCE_MS) declarerPerdu('silence'); // garde:flux-silence
  };
  const demarrer = () => {
    S.derniere = Date.now();
    if (typeof setInterval === 'function') SI(verifier, 1000);
    if (typeof document !== 'undefined' && document && typeof document.addEventListener === 'function') {
      const veille = () => { if (document.visibilityState === 'visible') verifier(); };
      if (N) N.addEventListener(document, 'visibilitychange', veille); else document.addEventListener('visibilitychange', veille);
    }
    decider();
  };

  // ---------- interface ----------
  const ouvrir = (jeton) => {
    const premier = !S.init; S.jeton = jeton;
    for (const s of [...S.sources]) s.close();
    const src = creerSource(); S.sources.add(src);
    if (premier) { S.init = true; demarrer(); return src; }
    const rejouer = () => { for (const [nom, data] of S.mem) src._livrer(nom, data); }; // état connu, quand 70 a posé ses abonnements
    // 79-16 : sous la coquille, le rejeu attend le premier rendu de l'onglet (les éléments qui affichent l'état existent alors) :
    // un rappel de démarrage, défait avec l'onglet
    const C = typeof window !== 'undefined' ? window.VF_COQUILLE : null;
    if (C && typeof C.surOnglet === 'function') C.surOnglet(rejouer);
    else Promise.resolve().then(rejouer);
    S.derniere = Date.now(); if (S.conn === 'perdu') majConn('reprise');
    if (S.role === 'elu' || S.role === 'page') ouvrirReel();
    else if (S.role === 'suiveur' && S.motif === 'silence') interrogerElu();
    S.motif = null;
    return src;
  };
  const ecouter = (nom, rappel) => {
    if (!EVENEMENTS.includes(nom)) throw new RangeError('événement inconnu : ' + nom);
    if (typeof rappel !== 'function') throw new TypeError('rappel attendu');
    if (!S.abonnes.has(nom)) S.abonnes.set(nom, new Set());
    S.abonnes.get(nom).add(rappel);
    return () => { S.abonnes.get(nom).delete(rappel); };
  };
  const surConnexion = (rappel) => {
    if (typeof rappel !== 'function') throw new TypeError('rappel attendu');
    S.cbConn.push(rappel); return () => { S.cbConn = S.cbConn.filter((f) => f !== rappel); };
  };
  const diagnostic = () => ({ role: S.role, canal: S.nom, connexion: S.conn, recus: { ...S.recus }, relayes: S.relayes, refuses: S.refuses,
    derniereA: S.derniere || null });
  window.VF_FLUX = Object.freeze({ ouvrir, ecouter, surConnexion, diagnostic, connexion: () => S.conn, role: () => S.role,
    EVENEMENTS: Object.freeze(EVENEMENTS.slice()) });
})();
