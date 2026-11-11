// Mesure en lecture seule : latence d'un GET léger (404 statique) toutes les 100 ms pendant 32 s.
// Si la boucle d'événements du serveur est bloquée par le « filet » de 5 s, on voit des pics périodiques.
const base = process.argv[2]; const N = 320; const lat = [];
const t00 = Date.now();
for (let i = 0; i < N; i++) {
  const cible = t00 + i * 100; const d = cible - Date.now(); if (d > 0) await new Promise((r) => setTimeout(r, d));
  const t = performance.now();
  try { const r = await fetch(base + '/zz-sonde-audit', { cache: 'no-store' }); await r.arrayBuffer(); lat.push([Date.now() - t00, performance.now() - t, r.status]); } catch (e) { lat.push([Date.now() - t00, -1, 0]); }
}
const v = lat.map((x) => x[1]).filter((x) => x >= 0).sort((a, b) => a - b);
const q = (p) => v[Math.floor(p * (v.length - 1))].toFixed(1);
console.log(`n=${v.length} statut=${lat[0][2]} médiane=${q(0.5)} ms p90=${q(0.9)} p99=${q(0.99)} max=${v[v.length - 1].toFixed(0)} ms`);
const pics = lat.filter((x) => x[1] > 50);
console.log(`pics > 50 ms : ${pics.length} → [instant s, latence ms] ${pics.map((x) => `[${(x[0] / 1000).toFixed(1)}, ${x[1].toFixed(0)}]`).join(' ')}`);
const ecarts = pics.map((x, i) => (i ? (x[0] - pics[i - 1][0]) / 1000 : null)).filter((x) => x !== null && x > 1).map((x) => x.toFixed(1));
console.log(`écarts entre pics (s) : ${ecarts.join(' ')}`);
