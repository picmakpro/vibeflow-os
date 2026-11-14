// vf-glob.mjs — correspondance de motifs du moteur SANS retour arrière : automate fini simulé par ensemble d'états (marque vibeflow SOCL-26).
// Coût par appel : au plus états × (longueur + 1) visites, jamais plus de MAX_PAS ; au-delà du budget, un chemin ne correspond à rien.
// Appelé seulement par compileGlob (lib/common.mjs, point unique des sites d'appel) avec les sources de regex que globSource produit ; aucun import.
// Non ré-entrant : tampons réutilisés d'un appel à l'autre, usage synchrone seulement.
export const MAX_MOTIF = 1024; // longueur maximale d'un motif normalisé (lue par compileGlob, avant toute traduction)
export const MAX_PAS = 4194304; // visites d'états au plus par appel de test (états × (longueur + 1))

const CAR = 0, ANY = 1, NSL = 2, CLS = 3, SPL = 4, FIN = 5;

// Lit une source de regex (dialecte que globSource émet) : alternative, groupe (?:…), quantificateurs * et ?, point, classe, échappement.
function analyser(src, ctx) {
  let i = 0;
  const fin = () => i >= src.length;
  function alternative(prof) {
    const bras = [sequence(prof)];
    while (src[i] === '|') { i++; bras.push(sequence(prof)); }
    if (prof === 0 && bras.length > 1) ctx.inerte = true; // alternative de niveau supérieur : motif malformé, testeur inerte
    return bras.length === 1 ? bras[0] : { k: 'alt', a: bras };
  }
  function sequence(prof) {
    const a = [];
    while (!fin() && src[i] !== '|' && !(src[i] === ')' && prof > 0)) {
      const c = src[i];
      let n;
      if (c === '(' && src.startsWith('(?:', i)) { i += 3; n = alternative(prof + 1); if (src[i] === ')') i++; }
      else if (c === '[' && src.indexOf(']', i + 1) > 0) {
        let j = i + 1;
        while (j < src.length && src[j] !== ']') j += src[j] === '\\' ? 2 : 1;
        const corps = src.slice(i + 1, j); i = j + 1;
        n = corps === '^/' ? { k: 'nsl' } : { k: 'cls', corps };
      }
      else if (c === '\\' && i + 1 < src.length) { n = { k: 'car', v: src.charCodeAt(i + 1) }; i += 2; }
      else if (c === '.') { n = { k: 'any' }; i++; }
      else { n = { k: 'car', v: src.charCodeAt(i) }; i++; }
      while (src[i] === '*' || src[i] === '?') { n = { k: src[i] === '*' ? 'star' : 'opt', n }; i++; }
      a.push(n);
    }
    return a.length === 1 ? a[0] : { k: 'seq', a };
  }
  return alternative(0);
}

// Construit les tables de l'automate ; les listes de travail ne survivent pas à l'appel (la mémoire par motif reste celle des tables).
function construire(arbres) {
  const T = [], A = [], X = [], Y = [], RE = [], CORPS = new Map(); // une seule RegExp par corps de classe (mémoire bornée par motif)
  const etat = (t, a, x, y) => { T.push(t); A.push(a); X.push(x); Y.push(y); return T.length - 1; };
  const bati = (n, suite) => {
    if (n.k === 'car') return etat(CAR, n.v, suite, -1);
    if (n.k === 'any') return etat(ANY, 0, suite, -1);
    if (n.k === 'nsl') return etat(NSL, 0, suite, -1);
    if (n.k === 'cls') {
      let idx = CORPS.get(n.corps);
      if (idx === undefined) { idx = RE.push(new RegExp('[' + n.corps + ']')) - 1; CORPS.set(n.corps, idx); }
      return etat(CLS, idx, suite, -1);
    }
    if (n.k === 'seq') { let e = suite; for (let k = n.a.length - 1; k >= 0; k--) e = bati(n.a[k], e); return e; }
    if (n.k === 'alt') {
      const bras = n.a.map((b) => bati(b, suite));
      let e = bras[bras.length - 1];
      for (let k = bras.length - 2; k >= 0; k--) e = etat(SPL, 0, bras[k], e);
      return e;
    }
    if (n.k === 'opt') return etat(SPL, 0, bati(n.n, suite), suite);
    const s = etat(SPL, 0, -1, suite); X[s] = bati(n.n, s); return s; // star : boucle sur l'atome, sortie vers la suite
  };
  const final = etat(FIN, 0, -1, -1);
  let debut = bati(arbres[arbres.length - 1], final);
  for (let k = arbres.length - 2; k >= 0; k--) debut = etat(SPL, 0, bati(arbres[k], final), debut);
  const nE = T.length, IA = nE < 32000 ? Int16Array : Int32Array; // largeur des indices d'états : moitié moins de mémoire par motif
  const tt = Uint8Array.from(T), aa = Uint16Array.from(A), xx = IA.from(X), yy = IA.from(Y);
  return { nE, IA, tt, aa, xx, yy, debut, RE };
}

export function automateDe(...sources) {
  for (const src of sources) new RegExp('^' + src + '$'); // validation d'abord : même SyntaxError qu'avant, au même moment (à la compilation)
  const ctx = { inerte: false };
  const arbres = sources.map((src) => analyser(src, ctx));
  if (ctx.inerte) return () => false;
  const { nE, IA, tt, aa, xx, yy, debut, RE } = construire(arbres), memo = [];
  let marque, pile, cur, nxt, gen = 0; // tampons de simulation, créés au premier appel de test seulement
  const enClasse = (idx, u) => {
    const t = u < 256 ? (memo[idx] ||= new Int8Array(256)) : null; // table de la classe, créée à la première lecture
    const m = t ? t[u] : 0;
    if (m) return m === 1;
    const v = RE[idx].test(String.fromCharCode(u)) ? 1 : 2;
    if (t) t[u] = v;
    return v === 1;
  };
  const ajouter = (liste, n, s) => { // ajoute s et tout ce qu'on atteint sans lire d'unité (chaque état au plus une fois par génération)
    let sp = 0;
    if (marque[s] !== gen) { marque[s] = gen; pile[sp++] = s; }
    while (sp > 0) {
      const e = pile[--sp];
      if (tt[e] === SPL) {
        const a = xx[e], b = yy[e];
        if (marque[a] !== gen) { marque[a] = gen; pile[sp++] = a; }
        if (marque[b] !== gen) { marque[b] = gen; pile[sp++] = b; }
      } else liste[n++] = e;
    }
    return n;
  };
  return (chemin) => {
    const s = `${chemin}`;
    const L = s.length;
    if (nE * (L + 1) > MAX_PAS) return false; // budget de pas : au-delà, ne correspond à rien
    if (!marque) { marque = new Int32Array(nE); pile = new IA(nE + 1); cur = new IA(nE); nxt = new IA(nE); }
    if (gen > 2000000000 - L) { marque.fill(0); gen = 0; }
    gen++;
    let n = ajouter(cur, 0, debut);
    for (let k = 0; k < L && n > 0; k++) {
      const u = s.charCodeAt(k);
      gen++;
      let m = 0;
      for (let q = 0; q < n; q++) {
        const e = cur[q], t = tt[e];
        let ok = false;
        if (t === CAR) ok = u === aa[e];
        else if (t === ANY) ok = u !== 10 && u !== 13 && u !== 0x2028 && u !== 0x2029;
        else if (t === NSL) ok = u !== 47;
        else if (t === CLS) ok = enClasse(aa[e], u);
        if (ok) m = ajouter(nxt, m, xx[e]);
      }
      const z = cur; cur = nxt; nxt = z; n = m;
    }
    for (let q = 0; q < n; q++) if (tt[cur[q]] === FIN) return true;
    return false;
  };
}
