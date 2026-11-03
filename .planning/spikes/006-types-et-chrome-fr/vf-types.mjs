// Spike 006 — les types de cartes de l'onglet Projet : un pictogramme (SVG 24×24, trait du viewer) et une
// couleur claire / sombre par type. Le générateur pose KIND_ICONS dans meta.kindIcons (lu par le patch P8
// du viewer) ; 80-vf-fr.js pose les couleurs (--n-<type>). Le libellé affiché est le nom du type lui-même,
// mis en capitale par le viewer : un type nommé en français s'affiche en français.
export const KIND_ICONS = {
  historique: '<rect x="3" y="4" width="18" height="5" rx="1"/><path d="M5 9v10a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V9M10 13h4"/>',
  jalon: '<path d="M5 21V4M5 4h11l-2 4 2 4H5"/>',
  phase: '<path d="m12 3 9 5-9 5-9-5z"/><path d="m3 13 9 5 9-5"/>',
  exigences: '<path d="M9 6h11M9 12h11M9 18h11"/><path d="m3 6 1.5 1.5L7 5M3 12l1.5 1.5L7 11M3 18l1.5 1.5L7 17"/>',
  mission: '<circle cx="12" cy="12" r="8"/><circle cx="12" cy="12" r="4"/><circle cx="12" cy="12" r=".5"/>',
  backlog: '<path d="M4 13h4l1.5 3h5L16 13h4"/><path d="M4 13 6.5 5h11L20 13v6H4z"/>',
  graine: '<path d="M12 21v-8"/><path d="M12 13c0-4 3-7 8-7 0 4-3 7-8 7zM12 15c0-3-2-5-6-5 0 3 2 5 6 5z"/>',
  release: '<path d="M3 12V4h8l10 10-8 8z"/><circle cx="7.5" cy="8.5" r="1.2"/>',
};
// [clair, sombre] — teintes distinctes, contraste vérifié à l'œil sur les deux thèmes du viewer
export const KIND_COLORS = {
  historique: ['#6b7280', '#9ca3af'], jalon: ['#b45309', '#f0b45a'], phase: ['#6a45d6', '#b49cff'],
  exigences: ['#0b7f6b', '#63d2b8'], mission: ['#c43a85', '#f19ac7'], backlog: ['#4f5661', '#a3a3a3'],
  graine: ['#3f7d20', '#8fd16a'], release: ['#1f5fd6', '#7aa7ff'],
};
