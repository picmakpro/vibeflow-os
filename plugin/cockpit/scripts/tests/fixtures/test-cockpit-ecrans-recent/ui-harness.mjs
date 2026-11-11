// Fait tourner un fichier ui/*.js du moteur dans un faux navigateur minimal et rend ce qu'il a posé.
// usage : node ui-harness.mjs <fichier.js> <données.json>   (stdout : JSON)
import fs from 'node:fs';
import vm from 'node:vm';
const [, , file, dataFile] = process.argv;
const data = JSON.parse(fs.readFileSync(dataFile, 'utf8'));
const el = () => { const e = { children: [], classList: { add() {}, remove() {}, contains: () => false, toggle() {} }, style: {}, dataset: {}, appendChild(c) { e.children.push(c); return c; }, addEventListener() {}, querySelector: (sel) => (sel === '.sc-l' ? (e._l = e._l || el()) : null), querySelectorAll: () => [], getBoundingClientRect: () => ({ right: 0, bottom: 0 }), set innerHTML(v) { e._html = v; }, get innerHTML() { return e._html || ''; }, contains: () => false, remove() {} }; return e; };
const out = { buttons: [], sections: [], boards: [], head: [], body: [] };
const ids = new Set(data.exists || []);
const SC = {
  graph: data.graph,
  h: (s) => String(s), plural: (n, w) => `${n} ${w}${n === 1 ? '' : 's'}`, iconI: () => '', icons: {},
  nodes: [], exists: (id) => ids.has(id), chain: (id) => data.chains?.[id] || [id], info: (id) => ({ name: id }),
  addHeaderButton: (o) => { const b = el(); b.opts = o; out.buttons.push(b); return b; },
  addPanelSection: (where, fn) => out.sections.push({ where, fn }),
  showBoard: (b) => out.boards.push(b),
};
const document = { createElement: () => el(), head: { appendChild: (c) => out.head.push(c) }, body: { appendChild: (c) => out.body.push(c), click() {} } };
const win = { Floorplan: SC, addEventListener() {}, innerWidth: 1280 };
vm.runInNewContext(fs.readFileSync(file, 'utf8'), { window: win, document, innerWidth: 1280, Date, Set, Map, Math, String, Number, Array });
const render = {
  buttons: out.buttons.map((b) => ({ id: b.opts.id, badge: b.children.map((c) => c.textContent).filter(Boolean) })),
  sections: out.sections.map((s) => { const arg = data.itemId; const r = s.fn(s.where === 'item' ? arg : undefined); return { where: s.where, html: r && r.html ? r.html : (r || null) }; }),
  menu: out.body.map((m) => m.innerHTML || ''),
};
// ouvre le menu des écrans s'il existe : rend ce que renderMenu() y écrit
if (out.buttons[0]?.opts?.onClick) { try { out.buttons[0].opts.onClick(); render.menuOuvert = out.body.map((m) => (m._l ? m._l.innerHTML : '')); } catch (e) { render.erreurOuverture = String(e.message); } }
console.log(JSON.stringify(render));
