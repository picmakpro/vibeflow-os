// vf-cockpit-lancer-canal — registre de module du canal serveur P -> processus de Q (72-09 ; P72-D-09, P72-D-17).
// Exports : definir(canal), canal().
// Un canal est { etat(): 'actif'|'arrete'|'indisponible', envoyer(msg): boolean, abonner(fn): void, claude(): boolean, python3(): boolean }.
// Renseigné par preparerTerminal (vf-cockpit-terminal.mjs), qui n'est appelé que sous `--terminal` : sans le drapeau le registre reste VIDE et le lanceur
// (vf-cockpit-lancer.mjs) ne sert aucune route. Aucun effet de bord à l'import, rien n'est lu ni écrit.
let courant = null;
const FONCTIONS = ['etat', 'envoyer', 'abonner', 'claude', 'python3'];
export function definir(c) { courant = c && typeof c === 'object' && FONCTIONS.every((f) => typeof c[f] === 'function') ? c : null; }
export function canal() { return courant; }
