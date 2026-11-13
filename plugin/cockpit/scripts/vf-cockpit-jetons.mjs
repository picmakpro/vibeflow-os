// vf-cockpit-jetons — jetons d'un transcript dédoublonnés par message (P79-D-03, C1). Pur, sans lecture ni écriture ; exporté pour la Phase 74.
// Exports : jetonsVides() -> sommes à zéro, contexteDe(usage) -> entrée + cache lu + cache créé,
//           plierMessage(jetons, curseur, id, usage) -> vrai quand la ligne ouvre un nouveau message.
// Un message Claude Code s'écrit sur plusieurs lignes `assistant` de même `message.id` : la dernière ligne remplace l'usage du message
// (l'ancien usage est retiré des sommes), jamais deux fois. `curseur` porte { dernierMsgId, usage, maxClos }.
export const jetonsVides = () => ({ entree: 0, sortie: 0, cacheLu: 0, cacheCree: 0, contexteMax: 0, contexteDernier: 0 });
const n = (v) => (typeof v === 'number' && Number.isFinite(v) ? v : 0);
export const contexteDe = (u) => (u ? n(u.entree) + n(u.cacheLu) + n(u.cacheCree) : 0);
const somme = (j, u, signe) => { j.entree += signe * n(u?.entree); j.sortie += signe * n(u?.sortie); j.cacheLu += signe * n(u?.cacheLu); j.cacheCree += signe * n(u?.cacheCree); };

export function plierMessage(jetons, curseur, id, usage) {
  const nouveau = curseur.dernierMsgId !== id;
  if (nouveau) { if (curseur.dernierMsgId) curseur.maxClos = Math.max(curseur.maxClos || 0, contexteDe(curseur.usage)); }
  else somme(jetons, curseur.usage, -1);
  somme(jetons, usage, 1);
  curseur.dernierMsgId = id; curseur.usage = { entree: n(usage.entree), sortie: n(usage.sortie), cacheLu: n(usage.cacheLu), cacheCree: n(usage.cacheCree) };
  jetons.contexteDernier = contexteDe(usage); jetons.contexteMax = Math.max(curseur.maxClos || 0, jetons.contexteDernier);
  return nouveau;
}
