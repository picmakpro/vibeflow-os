// vm-dom.mjs : DOM réduit pour les harnais vm du cockpit (Phase 73, plan 73-05). Pas de HTML analysé : seuls les noeuds que la page crée elle-même.
// creerDom(horloge) rend { document, window (prête à servir de contexte vm), cible, horloge, ecouteurs(), violations }.
// Couvert : éléments et textes, attributs, classList, dataset, textContent, arbre, sélecteurs simples (tag, #id, .classe, [attr], [attr=val], :scope, « , », « > », descendant),
// focus et activeElement, événements (capture, cible, remontée, stopPropagation, preventDefault sur événement annulable), minuteries et horloge factices.
// `innerHTML` et `insertAdjacentHTML` ne sont JAMAIS exécutés : ils s'écrivent dans `violations` (la page ne pose aucun HTML construit).
const decouper = (s) => s.split(',').map((x) => x.trim()).filter(Boolean);
export function creerDom(horloge = { now: 1_000_000 }) {
  const violations = [], defilements = [], appels = {}; let ecritures = 0; // ecritures : chaque appel d'écriture du DOM, même à valeur identique ; appels : appels d'écouteurs hors harnais (marqués _h)
  class Evt {
    constructor(type, o = {}) { this.type = type; this.bubbles = !!o.bubbles; this.cancelable = !!o.cancelable; this.detail = o.detail; this.key = o.key; this.defaultPrevented = false; this._stop = false; }
    preventDefault() { if (this.cancelable) this.defaultPrevented = true; }
    stopPropagation() { this._stop = true; }
  }
  class Cible {
    constructor() { this._l = []; }
    addEventListener(t, f, o) { this._l.push({ t, f, capture: o === true || !!(o && o.capture) }); }
    removeEventListener(t, f, o) { const c = o === true || !!(o && o.capture); const i = this._l.findIndex((x) => x.t === t && x.f === f && x.capture === c); if (i >= 0) this._l.splice(i, 1); }
    _parentEvt() { return this.parentNode || null; }
    dispatchEvent(ev) {
      const chemin = []; for (let n = this; n; n = n._parentEvt()) chemin.push(n);
      ev.target = this;
      const jouer = (n, capture, cible) => { ev.currentTarget = n; for (const l of n._l.slice()) if (l.t === ev.type && (cible || l.capture === capture)) { if (!l.f._h) appels[ev.type] = (appels[ev.type] || 0) + 1; l.f.call(n, ev); } };
      for (let i = chemin.length - 1; i > 0 && !ev._stop; i--) jouer(chemin[i], true, false);
      if (!ev._stop) jouer(chemin[0], false, true);
      if (ev.bubbles) for (let i = 1; i < chemin.length && !ev._stop; i++) jouer(chemin[i], false, false);
      return !ev.defaultPrevented;
    }
  }
  class Texte { constructor(d) { this.nodeType = 3; this.data = String(d); this.parentNode = null; } get textContent() { return this.data; } }
  const FOCALISABLE = /^(BUTTON|A|INPUT|SELECT|TEXTAREA|SUMMARY)$/;
  let focus = null;
  const racine = (n) => { while (n.parentNode) n = n.parentNode; return n; };
  // sélecteurs
  const composant = (s) => {
    const c = { tag: null, id: null, cls: [], attrs: [], scope: false };
    for (const m of s.matchAll(/^([a-zA-Z][\w-]*)|#([\w-]+)|\.([\w-]+)|\[([\w-]+)(?:=(?:"([^"]*)"|'([^']*)'|([^\]]*)))?\]|(:scope)/g)) {
      if (m[1]) c.tag = m[1].toUpperCase(); else if (m[2]) c.id = m[2]; else if (m[3]) c.cls.push(m[3]);
      else if (m[4]) c.attrs.push([m[4], m[5] ?? m[6] ?? m[7] ?? null]); else if (m[8]) c.scope = true;
    }
    return c;
  };
  const parse = (sel) => { const t = sel.trim().replace(/\s*>\s*/g, ' > ').split(/\s+/); const parts = []; let comb = ' '; for (const x of t) { if (x === '>') comb = '>'; else { parts.push({ c: composant(x), comb }); comb = ' '; } } return parts; };
  const ok = (el, c, scope) => el.nodeType === 1 && (!c.tag || el.tagName === c.tag) && (!c.id || el.id === c.id) && c.cls.every((k) => el.classList.contains(k))
    && c.attrs.every(([a, v]) => el.hasAttribute(a) && (v === null || el.getAttribute(a) === v)) && (!c.scope || el === scope);
  const suit = (el, parts, i, scope) => {
    if (!ok(el, parts[i].c, scope)) return false;
    if (i === 0) return true;
    if (parts[i].comb === '>') { const p = el.parentNode; return !!p && suit(p, parts, i - 1, scope); }
    for (let p = el.parentNode; p; p = p.parentNode) if (suit(p, parts, i - 1, scope)) return true;
    return false;
  };
  const trouve = (el, sel, scope) => decouper(sel).some((s) => { const p = parse(s); return suit(el, p, p.length - 1, scope); });
  class El extends Cible {
    constructor(tag) { super(); this.nodeType = 1; this.tagName = String(tag).toUpperCase(); this.localName = String(tag).toLowerCase(); this._a = new Map(); this.childNodes = []; this.parentNode = null; this.style = { setProperty() {} }; this._value = ''; }
    get children() { return this.childNodes.filter((n) => n.nodeType === 1); }
    get firstChild() { return this.childNodes[0] || null; }
    get parentElement() { return this.parentNode && this.parentNode.nodeType === 1 ? this.parentNode : null; }
    get isConnected() { return racine(this) === document; }
    get id() { return this._a.get('id') || ''; } set id(v) { ecritures++; this._a.set('id', String(v)); }
    get className() { return this._a.get('class') || ''; } set className(v) { ecritures++; this._a.set('class', String(v)); }
    get hidden() { return this._a.has('hidden'); } set hidden(v) { ecritures++; if (v) this._a.set('hidden', ''); else this._a.delete('hidden'); }
    get classList() { const e = this, l = () => e.className.split(/\s+/).filter(Boolean); const w = (a) => { e.className = a.join(' '); };
      return { add: (...k) => w([...new Set([...l(), ...k])]), remove: (...k) => w(l().filter((x) => !k.includes(x))), contains: (k) => l().includes(k),
        toggle: (k, f) => { const a = l().includes(k), v = f === undefined ? !a : !!f; w(v ? [...new Set([...l(), k])] : l().filter((x) => x !== k)); return v; },
        replace: (a, b) => { const x = l(); if (!x.includes(a)) return false; w(x.map((k) => (k === a ? b : k))); return true; } }; }
    get dataset() { const e = this; return new Proxy({}, { get: (_, k) => { const v = e._a.get('data-' + String(k).replace(/[A-Z]/g, (m) => '-' + m.toLowerCase())); return v === undefined ? undefined : v; },
      set: (_, k, v) => { ecritures++; e._a.set('data-' + String(k).replace(/[A-Z]/g, (m) => '-' + m.toLowerCase()), String(v)); return true; } }); }
    getAttribute(n) { return this._a.has(n) ? this._a.get(n) : null; } setAttribute(n, v) { ecritures++; this._a.set(n, String(v)); } removeAttribute(n) { ecritures++; this._a.delete(n); } hasAttribute(n) { return this._a.has(n); }
    get attributs() { return [...this._a.entries()]; }
    get tabIndex() { return this._a.has('tabindex') ? Number(this._a.get('tabindex')) : FOCALISABLE.test(this.tagName) ? 0 : -1; } set tabIndex(v) { this._a.set('tabindex', String(v)); }
    get value() { return this._value; } set value(v) { this._value = String(v); }
    get textContent() { return this.childNodes.map((n) => n.textContent).join(''); }
    set textContent(v) { ecritures++; for (const n of this.childNodes) n.parentNode = null; this.childNodes = []; if (v !== '' && v != null) this._ajouter(new Texte(v)); }
    set innerHTML(v) { violations.push('innerHTML'); } get innerHTML() { return ''; }
    insertAdjacentHTML() { violations.push('insertAdjacentHTML'); }
    _ajouter(n, avant) {
      ecritures++;
      if (n && n.tagName === '#FRAGMENT') { for (const k of n.childNodes.slice()) this._ajouter(k, avant); return n; }
      if (typeof n === 'string') n = new Texte(n);
      if (n.parentNode) n.parentNode.removeChild(n);
      n.parentNode = this; const i = avant ? this.childNodes.indexOf(avant) : -1;
      if (i >= 0) this.childNodes.splice(i, 0, n); else this.childNodes.push(n);
      return n;
    }
    appendChild(n) { return this._ajouter(n); } append(...ns) { for (const n of ns) this._ajouter(n); } prepend(...ns) { const p = this.childNodes[0]; for (const n of ns) this._ajouter(n, p); }
    insertBefore(n, ref) { return this._ajouter(n, ref); }
    removeChild(n) { ecritures++; const i = this.childNodes.indexOf(n); if (i >= 0) { this.childNodes.splice(i, 1); n.parentNode = null; } return n; }
    replaceChildren(...ns) { ecritures++; for (const n of this.childNodes) n.parentNode = null; this.childNodes = []; for (const n of ns) this._ajouter(n); }
    remove() { if (this.parentNode) this.parentNode.removeChild(this); if (focus && (focus === this || this.contains(focus))) focus = null; }
    contains(n) { for (; n; n = n.parentNode) if (n === this) return true; return false; }
    closest(sel) { for (let n = this; n && n.nodeType === 1; n = n.parentNode) if (trouve(n, sel, null)) return n; return null; }
    matches(sel) { return trouve(this, sel, this); }
    querySelectorAll(sel) { const r = []; const v = (n) => { for (const k of n.childNodes) if (k.nodeType === 1) { if (trouve(k, sel, this)) r.push(k); v(k); } }; v(this); return r; }
    querySelector(sel) { return this.querySelectorAll(sel)[0] || null; }
    focus() { if (this.isConnected) { const av = focus; focus = this; if (av && av !== this) av.dispatchEvent(new Evt('blur')); this.dispatchEvent(new Evt('focus')); } }
    blur() { if (focus === this) focus = null; }
    click() { const e = new Evt('click', { bubbles: true, cancelable: true }); return this.dispatchEvent(e); }
    scrollIntoView(o) { defilements.push({ el: this, o }); }
    getClientRects() { return this.isConnected ? [{}] : []; } getBoundingClientRect() { return { top: 0, left: 0, width: 1, height: 1 }; }
  }
  class Fragment extends El { constructor() { super('#fragment'); } }
  const document = new (class extends Cible {
    constructor() { super(); this.nodeType = 9; this.parentNode = null; this.readyState = 'complete'; }
    _parentEvt() { return window; }
    createElement(t) { return new El(t); } createElementNS(_, t) { return new El(t); } createTextNode(t) { return new Texte(t); } createDocumentFragment() { return new Fragment(); }
    get documentElement() { return html; } get head() { return head; } get body() { return body; } get childNodes() { return [html]; }
    get activeElement() { return focus && focus.isConnected ? focus : body; }
    getElementById(id) { return (html.id === id ? html : html.querySelector('#' + id)); }
    querySelector(s) { return html.matches(s) ? html : html.querySelector(s); } querySelectorAll(s) { return html.querySelectorAll(s); }
    contains(n) { return racine(n) === this; }
  })();
  const html = new El('html'), head = new El('head'), body = new El('body'); html.append(head, body); html.parentNode = document;
  const fenetre = new Cible(); const window = fenetre;
  // minuteries et horloge
  const minuteries = new Map(); let seq = 0;
  const poser = (fn, ms, every) => { const id = ++seq; minuteries.set(id, { fn, at: horloge.now + (ms || 0), every: every ? Math.max(1, ms || 1) : 0 }); return id; };
  const avancer = (ms) => { const fin = horloge.now + ms; for (;;) {
    const prochain = [...minuteries.entries()].filter(([, t]) => t.at <= fin).sort((a, b) => a[1].at - b[1].at || a[0] - b[0])[0];
    if (!prochain) break; const [id, t] = prochain; horloge.now = Math.max(horloge.now, t.at);
    if (t.every) t.at += t.every; else minuteries.delete(id);
    t.fn();
  } horloge.now = fin; };
  const Date_ = class extends Date { constructor(...a) { if (a.length) super(...a); else super(horloge.now); } static now() { return horloge.now; } };
  const ecouteurs = () => { let n = fenetre._l.length + document._l.length; const v = (e) => { for (const k of e.childNodes) if (k.nodeType === 1) { n += k._l.length; v(k); } }; v(html); return n; };
  Object.assign(fenetre, { document, Event: Evt, CustomEvent: Evt, Date: Date_, URLSearchParams, console,
    setTimeout: (fn, ms) => poser(fn, ms, false), setInterval: (fn, ms) => poser(fn, ms, true), clearTimeout: (i) => minuteries.delete(i), clearInterval: (i) => minuteries.delete(i),
    requestAnimationFrame: (fn) => poser(fn, 16, false), cancelAnimationFrame: (i) => minuteries.delete(i),
    matchMedia: () => ({ matches: false, addEventListener() {}, removeEventListener() {} }), getComputedStyle: () => ({ visibility: 'visible' }),
    performance: { now: () => horloge.now }, CSS: { escape: (s) => String(s) } });
  const types = () => { const r = {}; const c = (l) => { for (const x of l) r[x.t] = (r[x.t] || 0) + 1; }; c(fenetre._l); c(document._l); const v = (e) => { for (const k of e.childNodes) if (k.nodeType === 1) { c(k._l); v(k); } }; v(html); return r; };
  return { types, appels, ecritures: () => ecritures, razEcritures: () => { ecritures = 0; }, document, window: fenetre, Evt, horloge, avancer, ecouteurs, minuteries: () => minuteries.size, violations, defilements, focusDe: () => focus, html, head, body, El };
}
