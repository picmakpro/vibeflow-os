// vf-cockpit-terminal-page — page servie par le serveur du terminal (amorce posée par 71-01, complétée par 71-05).
// Exports : preparerPage({ engineDir }) · pageTerminal({ theme, origineP }) -> { html, csp }.
// Ici : une page minimale en français, sans script ; la page complète (xterm, thème, intégrité du vendor) vient avec 71-05.
export function preparerPage() {}

export function pageTerminal({ theme, origineP } = {}) {
  const sombre = theme !== 'light';
  const html = `<!doctype html>\n<html lang="fr"><head><meta charset="utf-8"><title>Terminal</title><style>body{font:14px system-ui,sans-serif;margin:16px;background:${sombre ? '#16181d' : '#f6f7f9'};color:${sombre ? '#e6e8ec' : '#1b1d22'}}</style></head><body><p>Terminal du cockpit.</p></body></html>\n`;
  const csp = `default-src 'none'; script-src 'none'; style-src 'unsafe-inline'; frame-ancestors ${origineP || "'none'"}; base-uri 'none'; form-action 'none'; object-src 'none'`;
  return { html, csp };
}
