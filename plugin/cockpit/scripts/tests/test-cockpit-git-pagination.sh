#!/usr/bin/env bash
# test-cockpit-git-pagination.sh — tiroir Git : pagination, worktrees repliés, volet bas, poignée de largeur, ouvrirSur (80-06 ; FORM-13 ; P80-D-19, 25, 39).
#   GP1 rangées paginées et focus · GP2 worktrees repliés, volet bas · GP3 poignée de largeur · GP4 VFGitTiroir.ouvrirSur(sha) sur un dépôt réel
#   Mutants : M-TOUT, M-BORNE, M-POUSSE, M-EPUISE, M-PAGINE, M-MOTIF, M-VOLET-LIE, M-PASTILLE (copie du module dans $WORK, jamais le module).
#   Chrome headless en CDP (SAUTÉ sans navigateur), ports éphémères. GP_CAPTURES=<dossier> écrit des captures PNG. Exit 0 si tout passe, 1 sinon.
set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; }
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
HERE_T="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="$(cd "$HERE_T/.." && pwd)"
TEMOIN="$HERE_T/temoins/git-tiroir.json"; DETAILS="$HERE_T/temoins/git-tiroir-details.json"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"
export HOME="$WORK/home"; SRV=""
stop_srv() { [ -n "$SRV" ] && { vf_hyg_stop "$SRV"; }; SRV=""; }
trap 'stop_srv; vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"' EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0; SKIP=0
ok_() { echo "  ✅ PASS — $1"; PASS=$((PASS+1)); }
ko_() { echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); }
assert_eq() { if [ "$2" = "$3" ]; then ok_ "$1"; else ko_ "$1" "$2" "$3"; fi; }
# GP_SEULEMENT="GP3 GP4" : ne joue que ces sections (mise au point) ; vide : toute la suite
veut() { [ -z "${GP_SEULEMENT:-}" ] && return 0; case " $GP_SEULEMENT " in *" $1 "*) return 0;; esac; return 1; }
trace() { [ -n "${GP_TRACE:-}" ] && printf '%s\n' "$2" > "$GP_TRACE-$1.json"; return 0; }
skip() { echo "  ⏭️  SAUTÉ — $1 ($2)"; SKIP=$((SKIP+1)); }
CHROME=""
for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue
  if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
echo "navigateur : ${CHROME:-aucun (les sections Chrome sont SAUTÉES)}"
cat > "$AUX/json.mjs" <<'JS'
const j = JSON.parse(process.argv[2]);
const v = new Function('j', 'return (' + process.argv[3] + ')')(j);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/mut.mjs" <<'JS'
// mut.mjs <fichier> <ancien> <nouveau> : remplace UNE occurrence ; code 1 si l'ancien texte est absent ou multiple (un mutant mort ne prouve rien)
import fs from 'node:fs';
const [, , f, a, b] = process.argv; const t = fs.readFileSync(f, 'utf8');
if (!t.includes(a) || t.split(a).length !== 2) { console.error('mutation impossible : motif absent ou multiple : ' + a); process.exit(1); }
fs.writeFileSync(f, t.replace(a, () => b));
JS
export VF_CS="$HERE_T/chrome-session.mjs" VF_CDP_ECHEANCE_MS="${VF_CDP_ECHEANCE_MS:-25000}" VF_CDP_TAG=git-pagination
cdp() {
  local r; r="$(node "$HERE_T/chrome-git-pagination.mjs" "$CHROME" "$@" 2>&1 | tail -1)"
  case "$r" in *'"erreur"'*) echo "     (scénario interrompu : $r)" >&2;; esac
  printf '%s\n' "$r"
}
jq_() { node "$AUX/json.mjs" "$1" "$2"; }
mutate() { node "$AUX/mut.mjs" "$@"; }
NODE="$(command -v node)"; ENVX=""; GIT="git -c user.email=t@t -c user.name=t"
mk_lab() {
  mkdir -p "$1/src" "$1/.planning/phases/01-x"
  printf 'export const util = () => 1;\n' > "$1/src/util.js"
  printf -- '- [x] **Phase 1: Socle** - premier jet\n' > "$1/.planning/ROADMAP.md"
  printf -- '---\nstatus: executing\nmilestone: vibeflow-test\n---\n# State\n' > "$1/.planning/STATE.md"
  printf '<objective>Faire le socle</objective>\n' > "$1/.planning/phases/01-x/01-01-PLAN.md"; echo ok > "$1/.planning/phases/01-x/01-01-SUMMARY.md"
}
build_serve() { # $1 = lab, $2 = dossier de scripts (défaut : le module) ; pose OUT, PORT ; démarre le serveur (SRV)
  env $ENVX "$NODE" "${2:-${GP_SCRIPTS:-$SCRIPTS}}/vf-cockpit-build.mjs" "$1" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
  OUT="$1/.vibeflow/cockpit"
  env $ENVX ${ENVS:-} "$NODE" "$OUT/serve.mjs" --no-open --port "$(libre)" > "$WORK/serve.out" 2>&1 &
  SRV=$!
  for _ in $(seq 1 100); do [ -s "$OUT/.cache/server.json" ] && break; sleep 0.1; done
  PORT="$(node -e "console.log(JSON.parse(require('fs').readFileSync('$OUT/.cache/server.json','utf8')).port)" 2>/dev/null || echo 0)"
}
DEPOT="$WORK/depot"; mk_lab "$DEPOT"
$GIT -C "$DEPOT" init -q -b main && $GIT -C "$DEPOT" add -A && $GIT -C "$DEPOT" commit -q -m init

# crochets avant la page (pre-mock) : /api/vf/git et /commit remplacés par les témoins, rangées générées par __mk(n), erreurs, requêtes
{
  printf 'window.__vfGit = { reponse: '; cat "$TEMOIN"; printf ', delai: 0 };\n'
  printf 'window.__vfDet = '; cat "$DETAILS"; printf ';\n'
  cat <<'JS'

// la visite guidée et son ouverture automatique sont tenues pour déjà vues : elle ouvrirait ou fermerait le panneau en pleine mesure
{ const g0 = Storage.prototype.getItem;
  Storage.prototype.getItem = function (k) { return /^(tour-seen:|vibeflow-cockpit:visite)/.test(k) ? '1' : g0.call(this, k); }; }
window.__errs = []; window.__vfReqs = []; window.__TEMOIN_REF = JSON.parse(JSON.stringify(window.__vfGit.reponse));
window.__vfDet.erreurs = {}; window.__vfDetReqs = [];
addEventListener('error', (e) => window.__errs.push(String(e.message)));
addEventListener('unhandledrejection', (e) => window.__errs.push('rejet ' + String(e.reason)));
window.__alerte = 0; window.alert = () => { window.__alerte++; };
window.__couleur = (v) => { const p = document.createElement('i'); p.style.color = 'var(' + v + ')'; document.body.appendChild(p);
  const c = getComputedStyle(p).color; p.remove(); return c; };
window.__mk = (n) => { // n rangées linéaires, HEAD sur la première
  const b = JSON.parse(JSON.stringify(window.__TEMOIN_REF)), hx = (i) => (i + 1).toString(16).padEnd(40, '0');
  b.rangees = Array.from({ length: n }, (_, i) => ({ h: hx(i), col: 0, entrants: i ? [0] : [], sortants: [], largeur: 1, ouvertBas: [],
    fusion: false, racine: i === n - 1, suite: i < n - 1, h7: hx(i).slice(0, 7), p: i < n - 1 ? [hx(i + 1)] : [], at: 1794044000 - i * 60,
    an: 'Alice', s: 'Commit ' + i, teinte: 0,
    refs: i ? [] : [{ type: 'head', nom: 'HEAD', courante: true, worktree: null, commande: null }], refsPlus: 0 }));
  b.replies = 0; b.horsFenetre = []; return b;
};
{ const f0 = window.fetch.bind(window), rep = (st, o) => Promise.resolve(new Response(JSON.stringify(o),
    { status: st, headers: { 'content-type': 'application/json' } }));
  window.fetch = (u, i) => { const url = typeof u === 'string' ? u : u.url;
    if (/\/api\/vf\/git(\?|$)/.test(url)) { window.__vfReqs.push({ url });
      return new Promise((ok) => setTimeout(() => ok(rep(200, window.__vfGit.reponse)), window.__vfGit.delai || 0)); }
    const m = /^\/api\/vf\/git\/(commit|worktrees)(\?|$)/.exec(url);
    if (!m) return f0(u, i);
    window.__vfDetReqs.push({ url, route: m[1] });
    if (m[1] === 'worktrees') return rep(200, window.__vfDet.worktrees);
    const sha = decodeURIComponent((/sha=([^&]*)/.exec(url) || [])[1] || '');
    if (window.__vfDet.erreurs[sha]) return rep(window.__vfDet.erreurs[sha], { erreur: 'commit-inconnu' });
    const cmd = { show: 'git show --stat --end-of-options ' + sha.slice(0, 7), detacher: 'git switch --detach ' + sha.slice(0, 7) };
    return rep(200, Object.assign({}, window.__vfDet.commit, { h: sha, h7: sha.slice(0, 7), commandes: cmd })); }; }
JS
} > "$AUX/pre-mock.js"
# crochets avant la page (pre-reel) : dépôt réel, rien n'est remplacé ; erreurs de page et requêtes /api/vf/git* comptées
cat > "$AUX/pre-reel.js" <<'JS'
// la visite guidée et son ouverture automatique sont tenues pour déjà vues : elle ouvrirait ou fermerait le panneau en pleine mesure
{ const g0 = Storage.prototype.getItem;
  Storage.prototype.getItem = function (k) { return /^(tour-seen:|vibeflow-cockpit:visite)/.test(k) ? '1' : g0.call(this, k); }; }
window.__errs = []; window.__vfReqs = [];
addEventListener('error', (e) => window.__errs.push(String(e.message)));
addEventListener('unhandledrejection', (e) => window.__errs.push('rejet ' + String(e.reason)));
{ const f0 = window.fetch.bind(window);
  window.fetch = (u, i) => { const url = typeof u === 'string' ? u : u.url;
    if (/\/api\/vf\/git/.test(url)) window.__vfReqs.push({ url, methode: (i && i.method) || 'GET' });
    return f0(u, i); }; }
JS
export VF_PRE="$AUX/pre-mock.js"
# entrée commune des scénarios : page à 1440 x 900, seconde ligne visible
cat > "$AUX/entree.js" <<'JS'
export const LIGNE = `document.querySelector('#vf-git-ligne')`;
export const RANGEES = `document.querySelectorAll('#vf-git-tiroir li[role=option]')`;
export const pause = (ms) => new Promise((r) => setTimeout(r, ms));
export async function touche(s, key, code, vk, mods = 0) { // vraie touche au clavier (Entrée, Échap, Tab, flèches, Maj) par le protocole
  const base = { key, code, windowsVirtualKeyCode: vk, modifiers: mods };
  await s.send('Input.dispatchKeyEvent', Object.assign({ type: 'keyDown' }, base, key === 'Enter' ? { text: '\r' } : {}));
  await s.send('Input.dispatchKeyEvent', Object.assign({ type: 'keyUp' }, base));
}
export async function ouvrirPage(s, base, l = 1440, h = 900) {
  await s.naviguer(base + '/');
  await s.send('Emulation.setDeviceMetricsOverride', { width: l, height: h, deviceScaleFactor: 1, mobile: false });
  await s.attendre(`document.readyState === 'complete' && !!${LIGNE} && getComputedStyle(${LIGNE}).display !== 'none'`, 'seconde ligne');
}
JS
export GP_ENTREE="file://$AUX/entree.js"

echo "=== GP1 — rangées paginées, focus sur la première rangée ajoutée ==="
if ! veut GP1; then :; elif [ -z "$CHROME" ]; then skip "GP1" "pas de navigateur"; else
  build_serve "$DEPOT"; BASE="http://127.0.0.1:$PORT"
  cat > "$AUX/gp1.js" <<'JS'
const [base] = ARGS, { ouvrirPage, LIGNE, RANGEES } = await import(process.env.GP_ENTREE);
const ouvert = (n) => `${RANGEES}.length === ${n}`, out = {}, B = `document.querySelector('.vf-git-plus-b')`;
const att = (e, l) => s.attendre(e, l, 4000).catch(() => null); // un manque se lit dans la mesure, il n'interrompt pas la suite
const lire = (extra) => s.ev(`(() => { const T = document.querySelector('#vf-git-tiroir'), b = T.querySelector('.vf-git-plus-b'), L = [...${RANGEES}];
  const a = document.activeElement, i = L.indexOf(a), p = T.querySelector('.vf-git-pied');
  const l = T.querySelector('.vf-git-plus-l'), n = T.querySelector('.vf-git-plus-n');
  return { n: L.length, bouton: !!b, libelle: l && l.textContent, restants: n && n.textContent, pied: p && p.textContent, actif: i, corps: a === document.body,
    tab0: L.filter((x) => x.getAttribute('tabindex') === '0').length, live: T.querySelector('.vf-git-live').textContent }; })()`);
const ouvrirAvec = async (n) => { await ouvrirPage(s, base); await s.ev(`window.__vfGit.reponse = window.__mk(${n})`);
  await s.ev(`${LIGNE}.click()`); await s.attendre(`${RANGEES}.length > 0`, 'rangées'); };
await ouvrirAvec(612); out.a = await lire();                                      // GP1.1
await s.ev(`${B}?.click()`); await att(ouvert(200), '200 rangées'); out.b = await lire(); // GP1.2
await ouvrirAvec(105); out.c = await lire();                                      // GP1.3
await ouvrirAvec(210); out.d0 = await lire();                                     // GP1.4
await s.ev(`${B}?.click()`); await att(ouvert(200), '200 rangées'); out.d1 = await lire();
await s.ev(`${B}?.focus(); ${B}?.click()`);
await att(ouvert(210), '210 rangées'); out.d2 = await lire();
await ouvrirAvec(210);                                                            // GP1.5
await s.ev(`${B}?.focus(); window.__vfGit.reponse = window.__mk(105); window.VFGitTiroir.recharger()`);
await att(`${RANGEES}.length === 105 && !${B}`, 'rechargé à 105');
out.e = await lire(); out.errs = await s.ev(`window.__errs`);
return out;
JS
  R1="$(cdp "$AUX/gp1.js" "$BASE")"
  cat > "$AUX/gp1b.js" <<'JS'
const [base] = ARGS, { ouvrirPage, LIGNE, RANGEES, pause } = await import(process.env.GP_ENTREE);
const att = (e, l) => s.attendre(e, l, 4000).catch(() => null), out = {};
const SEC = { tags: ['vf-git-s-tags', '.vf-git-ligne-d'], stash: ['vf-git-s-stash', '.vf-git-st'], aut: ['vf-git-s-aut', '.vf-git-aut'] };
await ouvrirPage(s, base);
await s.ev(`(() => { const R = window.__vfGit.reponse, h = 'abcdef1', at = 1794000000;
  R.tags = Array.from({ length: 130 }, (_, i) => ({ nom: 't' + i, h7: h, at }));
  R.stash = Array.from({ length: 120 }, (_, i) => ({ ref: 'stash@{' + i + '}', h7: h, at, message: 'm' + i, branche: 'main',
    commande: "git stash show --stat 'stash@{" + i + "}'" }));
  R.auteurs = Array.from({ length: 115 }, (_, i) => ({ nom: 'a' + i, commits: i + 1, dernier: at })); })()`);
await s.ev(`${LIGNE}.click()`); await att(`${RANGEES}.length > 0`, 'rangées');
for (const [k, [id, sel]] of Object.entries(SEC)) {
  await s.ev(`document.querySelector('[aria-controls=${id}]').click()`); await pause(100);
  const B = `document.querySelector('#${id} .vf-git-plus-b')`, N = `document.querySelectorAll('#${id} ${sel}').length`;
  out[k] = await s.ev(`({ n0: ${N}, lib: ${B}?.querySelector('.vf-git-plus-l').textContent, rest: ${B}?.querySelector('.vf-git-plus-n').textContent })`);
  await s.ev(`${B}?.click()`); await pause(200);
  Object.assign(out[k], await s.ev(`({ n1: ${N}, bouton: !!${B}, focus: [...document.querySelectorAll('#${id} ${sel}')].indexOf(document.activeElement),
    live: document.querySelector('#vf-git-tiroir .vf-git-live').textContent })`));
}
out.errs = await s.ev(`window.__errs`);
return out;
JS
  R1B="$(cdp "$AUX/gp1b.js" "$BASE")"
  trace gp1 "$R1"
  assert_eq "GP1.1 — 612 commits : 100 rangées à l'ouverture, « 512 restants », pied « 100 commits affichés sur 612 »" \
    "$(jq_ "$R1" '[j.a.n, j.a.libelle, j.a.restants, j.a.pied].join("|")' 2>/dev/null)" \
    "100|Afficher 100 de plus|512 restants|100 commits affichés sur 612"
  assert_eq "GP1.2 — « Afficher 100 de plus » : 200 rangées, focus sur la 101e, un seul arrêt itinérant, annonce polie" \
    "$(jq_ "$R1" '[j.b.n, j.b.actif, j.b.tab0, j.b.restants, j.b.live].join("|")' 2>/dev/null)" \
    "200|100|1|412 restants|100 commits de plus affichés, 412 restants"
  assert_eq "GP1.3 — 105 commits : tout est rendu, aucun bouton, pied « Tous les 105 commits sont affichés »" \
    "$(jq_ "$R1" '[j.c.n, j.c.bouton, j.c.pied].join("|")' 2>/dev/null)" \
    "105|false|Tous les 105 commits sont affichés"
  assert_eq "GP1.4 — 210 commits : 100 rangées puis « 110 restants » ; au 1er clic « Afficher les 10 derniers » (10 restants)" \
    "$(jq_ "$R1" '[j.d0.n, j.d0.restants, j.d1.n, j.d1.actif, j.d1.libelle, j.d1.restants].join("|")' 2>/dev/null)" \
    "100|110 restants|200|100|Afficher les 10 derniers|10 restants"
  assert_eq "GP1.4 — le clic qui épuise la liste : 210 rangées, focus sur la 201e (jamais body), un seul arrêt, bouton retiré, pied complet" \
    "$(jq_ "$R1" '[j.d2.n, j.d2.actif, j.d2.corps, j.d2.tab0, j.d2.bouton, j.d2.pied].join("|")' 2>/dev/null)" \
    "210|200|false|1|false|Tous les 210 commits sont affichés"
  assert_eq "GP1.5 — bouton disparu sans clic (rechargement à 105) : focus sur la dernière rangée (voisin précédent), jamais body" \
    "$(jq_ "$R1" '[j.e.n, j.e.actif, j.e.corps].join("|")' 2>/dev/null)" \
    "105|104|false"
  GP16="100,30 restants,130,false,100,30 lignes de plus affichées, 0 restant"
  GP16="$GP16|100,20 restants,120,false,100,20 lignes de plus affichées, 0 restant"
  GP16="$GP16|100,15 restants,115,false,100,15 lignes de plus affichées, 0 restant"
  assert_eq "GP1.6 — Tags, Stash, Auteurs au-delà de 110 lignes : 100 d'abord, reste au clic, focus sur la première ajoutée, annonce" \
    "$(jq_ "$R1B" '["tags", "stash", "aut"].map((k) => { const o = j[k];
      return [o.n0, o.rest, o.n1, o.bouton, o.focus, o.live].join(","); }).join("|")' 2>/dev/null)" "$GP16"
  assert_eq "GP1 — aucune erreur de page" "$(jq_ "$R1" 'j.errs.length' 2>/dev/null)" "0"
  stop_srv
fi

echo "=== GP2 — worktrees repliés, volet bas du détail d'un commit ==="
if ! veut GP2; then :; elif [ -z "$CHROME" ]; then skip "GP2" "pas de navigateur"; else
  build_serve "$DEPOT"; BASE="http://127.0.0.1:$PORT"
  cat > "$AUX/gp2.js" <<'JS'
const [base] = ARGS, { ouvrirPage, LIGNE, RANGEES, pause, touche } = await import(process.env.GP_ENTREE);
const out = {}, VOL = `document.querySelector('#vf-git-tiroir .vf-git-detail')`;
const REG = `document.querySelector('#vf-git-tiroir .vf-git-detail [role=region]')`;
const att = (e, l, ms = 4000) => s.attendre(e, l, ms).catch(() => null); // un manque se lit dans la mesure
const rangee = (i) => `document.querySelectorAll('#vf-git-tiroir li[role=option]')[${i}]`;
await ouvrirPage(s, base);
await s.ev(`window.__vfDet.commit.auteur = '<img src=x onerror=alert(3)>'`);
await s.ev(`window.__vfDet.commit.message = 'Sujet\\n\\n<script>alert(4)</script>'`);
await s.ev(`window.__copies = [];
  navigator.clipboard.writeText = (t) => { window.__copies.push(t); return window.__refuse ? Promise.reject(new Error('x')) : Promise.resolve(); }`);
await s.ev(`${LIGNE}.click()`);
await att(`${RANGEES}.length === 40`, '40 rangées');
out.secs = await s.ev(`[...document.querySelectorAll('#vf-git-tiroir .vf-git-sec > button')].map((b) =>
  [b.querySelector('.vf-git-sec-n').textContent, b.getAttribute('aria-expanded'), (b.querySelector('.meta') || { textContent: '' }).textContent].join(':'))`);
out.nom = await s.ev(`document.querySelector('#vf-git-tiroir .vf-git-sec > button').getAttribute('aria-label')`);
out.avant = await s.ev(`({ n: ${RANGEES}.length, vol: !!${VOL} })`);
await s.ev(`${rangee(2)}.focus()`); await touche(s, 'Enter', 'Enter', 13);
await att(`!!${REG}`, 'volet ouvert');
out.volet = await s.ev(`(() => { const r = ${REG}, v = ${VOL}, a = document.activeElement, L = [...${RANGEES}];
  return { nom: r.getAttribute('aria-label'), sha7: L[2].dataset.h.slice(0, 7), n: L.length, actif: L.indexOf(a), parent: v.parentNode.id,
    dansListe: !!v.closest('[role=listbox]'), controle: L[2].getAttribute('aria-controls') === r.id,
    nb: document.querySelectorAll('.vf-git-detail').length, tiroir: !document.querySelector('#vf-git-tiroir').hidden }; })()`);
let k = 0, dedans = false;
for (; k < 20 && !dedans; k++) {
  await touche(s, 'Tab', 'Tab', 9);
  dedans = await s.ev(`!!document.activeElement.closest('.vf-git-detail')`);
}
out.tab = { dedans, appuis: k };
await touche(s, 'Escape', 'Escape', 27); await pause(150);
out.echap = await s.ev(`({ volets: document.querySelectorAll('.vf-git-detail').length, actif: [...${RANGEES}].indexOf(document.activeElement),
  tiroir: !document.querySelector('#vf-git-tiroir').hidden })`);
// GP2.5 : contenu hostile en texte
await s.ev(`${rangee(2)}.focus()`); await touche(s, 'Enter', 'Enter', 13);
await att(`!!${REG} && !!${VOL}.querySelector('.vf-git-d-fichiers')`, 'détail lu');
out.hostile = await s.ev(`(() => { const v = ${VOL}, x = v.textContent;
  return { balises: v.querySelectorAll('img, script, iframe, [onerror], [onload]').length,
    lit: x.includes('<img src=x onerror=alert(3)>') && x.includes('<script>alert(4)</script>'), alerte: window.__alerte }; })()`);
// GP2.4 : copie du sha
const copie = `[...${VOL}.querySelectorAll('button')].find((b) => /^Cop/.test(b.textContent))`;
const t0 = Date.now(); await s.ev(`${copie}?.click()`); await att(`/^Copié$/.test(${copie}?.textContent)`, 'Copié');
out.copie = await s.ev(`({ lib: ${copie}?.textContent, spy: window.__copies[0], sha: ${VOL}.querySelector('.vf-git-d-sha code').textContent,
  live: document.querySelector('#vf-git-tiroir .vf-git-live').textContent })`);
await att(`${copie}?.textContent === 'Copier le sha'`, 'libellé revenu', 6000); out.copie.dt = Date.now() - t0;
await s.ev(`window.__refuse = true; ${copie}?.click()`);
await att(`/Copie impossible/.test(${copie}?.textContent)`, 'refus', 3000);
out.refus = await s.ev(`({ lib: ${copie}?.textContent, sel: String(window.getSelection()), sha: ${VOL}?.querySelector('.vf-git-d-sha code').textContent })`);
// GP2.3 : 1024 x 768, panneau ouvert
await s.send('Emulation.setDeviceMetricsOverride', { width: 1024, height: 768, deviceScaleFactor: 1, mobile: false }); await pause(600);
out.petit = await s.ev(`(() => { const T = document.querySelector('#vf-git-tiroir'), v = ${VOL}, c = T.querySelector('.vf-git-corps');
  const z = v.querySelector('.vf-git-det'), h = (e) => Math.round(e.getBoundingClientRect().height);
  const tx = [...v.querySelectorAll('*')].filter((e) => [...e.childNodes].some((n) => n.nodeType === 3 && n.textContent.trim()));
  return { l: Math.round(T.getBoundingClientRect().width), h: h(v), corps: h(c), wt: document.querySelector('#vf-git-s-wt').hidden,
    police: Math.min(...tx.map((e) => parseFloat(getComputedStyle(e).fontSize))),
    debord: v.scrollWidth > v.clientWidth || z.scrollWidth > z.clientWidth,
    // diagnostic (jamais une borne) : de quoi se compose la hauteur du tiroir, imprimé à chaque rejeu pour lire la CI Linux
    mesures: { tiroir: h(T), barre: h(T.querySelector('.vf-git-barre')), aide: h(T.querySelector('.vf-git-aide')), corps: h(c), volet: h(v),
      haut: Math.round(T.getBoundingClientRect().top), fenetre: [innerWidth, innerHeight], hh: getComputedStyle(document.body).getPropertyValue('--hh') } }; })()`);
// GP2.6 : le détail s'ouvre, Graphe est replié, « Fermer le détail » : un focus visible (le titre du tiroir), jamais body
await s.ev(`document.querySelector('[aria-controls=vf-git-s-graphe]').click()`);
await s.ev(`${VOL}?.querySelector('.vf-git-fermer')?.click()`); await pause(200);
out.repli = await s.ev(`({ corps: document.activeElement === document.body, titre: document.activeElement.classList.contains('vf-git-titre-t'),
  volets: document.querySelectorAll('.vf-git-detail').length })`);
out.errs = await s.ev(`window.__errs`);
return out;
JS
  R2="$(cdp "$AUX/gp2.js" "$BASE")"
  assert_eq "GP2.1 — Worktrees repliée au départ « Worktrees · 3 », Graphe ouverte, Tags, Stash, Auteurs fermées" \
    "$(jq_ "$R2" '[j.secs.join("|"), j.nom].join("#")' 2>/dev/null)" \
    "Worktrees:false:3|Graphe:true:|Tags:false:2|Stash:false:2|Auteurs et activité:false:3#Worktrees · 3"
  assert_eq "GP2.2 — Entrée : volet region « Détail du commit », hors de la liste, aucune rangée perdue, focus resté sur la rangée" \
    "$(jq_ "$R2" '(() => { const v = j.volet, a = j.avant;
      return [v.nom === "Détail du commit " + v.sha7, v.n, a.n, v.actif, v.parent, v.dansListe, v.controle, v.nb].join("|"); })()' 2>/dev/null)" \
    "true|40|40|2|vf-git-tiroir|false|true|1"
  assert_eq "GP2.2 — Tab depuis la liste entre dans le volet ; Échap : volet fermé, focus sur la rangée, tiroir ouvert" \
    "$(jq_ "$R2" '[j.tab.dedans, j.echap.volets, j.echap.actif, j.echap.tiroir].join("|")' 2>/dev/null)" \
    "true|0|2|true"
  assert_eq "GP2.3 — 1024 x 768 : tiroir 352 px, volet entre 192 et 256, texte >= 12 px, sans débord, liste >= 240 px, Worktrees fermé" \
    "$(jq_ "$R2" '(() => { const p = j.petit;
      return [p.l, p.h >= 192 && p.h <= 256, p.police >= 12, p.debord, p.corps >= 240, p.wt].join("|"); })()' 2>/dev/null)" \
    "352|true|true|false|true|true"
  echo "     GP2.3 mesuré (diagnostic) : $(jq_ "$R2" 'JSON.stringify(j.petit.mesures)' 2>/dev/null)"
  assert_eq "GP2.4 — Copier le sha : « Copié » puis le libellé revient après 2 s (entre 1,5 et 3,5 s), région vive « Sha copié »" \
    "$(jq_ "$R2" '[j.copie.lib, j.copie.live, j.copie.spy === j.copie.sha, j.copie.dt >= 1500 && j.copie.dt <= 3500].join("|")' 2>/dev/null)" \
    "Copié|Sha copié|true|true"
  assert_eq "GP2.4 — presse-papiers refusé : « Copie impossible » et le sha est sélectionné" \
    "$(jq_ "$R2" '[j.refus.lib, j.refus.sel === j.refus.sha].join("|")' 2>/dev/null)" \
    "Copie impossible|true"
  assert_eq "GP2.5 — contenu hostile rendu en texte : 0 img, script, onerror créé, aucune alerte" \
    "$(jq_ "$R2" '[j.hostile.balises, j.hostile.lit, j.hostile.alerte].join("|")' 2>/dev/null)" \
    "0|true|0"
  assert_eq "GP2.6 — Fermer le détail avec la rangée dans une section repliée : le focus va au titre du tiroir, jamais à body" \
    "$(jq_ "$R2" '[j.repli.corps, j.repli.titre, j.repli.volets].join("|")' 2>/dev/null)" "false|true|0"
  assert_eq "GP2 — aucune erreur de page" "$(jq_ "$R2" 'j.errs.length' 2>/dev/null)" "0"
  stop_srv
fi

echo "=== GP4 — VFGitTiroir.ouvrirSur(sha), dépôt réel de 130 commits et un commit orphelin ==="
if ! veut GP4; then :; elif [ -z "$CHROME" ]; then skip "GP4" "pas de navigateur"; else
  LAB4="$WORK/lab4"; mk_lab "$LAB4"; $GIT -C "$LAB4" init -q -b main && $GIT -C "$LAB4" add -A && $GIT -C "$LAB4" commit -q -m init
  for i in $(seq 1 129); do $GIT -C "$LAB4" commit -q --allow-empty -m "commit $i"; done
  RACINE="$($GIT -C "$LAB4" rev-list --max-parents=0 HEAD)"; ORPH="$($GIT -C "$LAB4" commit-tree 'HEAD^{tree}' -m orphelin)"
  build_serve "$LAB4"; BASE="http://127.0.0.1:$PORT"
  cat > "$AUX/gp4.js" <<'JS'
const [base, racine, orph] = ARGS, { ouvrirPage, LIGNE, RANGEES, pause } = await import(process.env.GP_ENTREE);
const out = {}, VOL = `document.querySelector('#vf-git-tiroir .vf-git-detail')`, REG = `${VOL}?.querySelector('[role=region]')`;
const T = `document.querySelector('#vf-git-tiroir')`, OS = (sha) => `window.VFGitTiroir.ouvrirSur(${JSON.stringify(sha)})`;
const CORPS = `${T}.querySelector('.vf-git-corps')`;
const git = `window.__vfReqs.filter((q) => /\\/api\\/vf\\/git(\\?|$)/.test(q.url)).length`;
const comm = `window.__vfReqs.filter((q) => /\\/api\\/vf\\/git\\/commit/.test(q.url)).map((q) => q.url)`;
const ouvertSur = async () => {
  await ouvrirPage(s, base); await s.ev(`${LIGNE}.click()`);
  await s.attendre(`${RANGEES}.length > 0`, 'rangées'); await pause(700);
};
// GP4.1 : tiroir fermé, commit racine (130e rangée, non rendue)
await ouvrirPage(s, base);
out.a = { r: await s.ev(OS(racine)) }; await pause(1500);
Object.assign(out.a, await s.ev(`({ ouvert: !${T}.hidden, nom: ${REG}?.getAttribute('aria-label'), texte: ${REG}?.textContent,
  rangees: ${RANGEES}.length, porte: [...${RANGEES}].some((l) => l.dataset.h === '${racine}'),
  git: ${git}, commit: ${comm}, errs: window.__errs.length })`));
// GP4.2 : shas refusés, tiroir fermé
await ouvrirPage(s, base);
out.b = await s.ev(`(async () => { const r = [], exc = [], neuf = (q) => !/\\/entete/.test(q.url);
  const bad = ['', 'HEAD', '${racine.slice(0, 7)}', '${racine.toUpperCase()}', '${racine}\\n', undefined, null, 42, {}];
  for (const x of bad) { try { r.push(await window.VFGitTiroir.ouvrirSur(x)); } catch (e) { exc.push(String(e)); } }
  return { r, exc, ouvert: !${T}.hidden, reqs: window.__vfReqs.filter(neuf).length, errs: window.__errs.length }; })()`);
// GP4.3 : valide mais absent du dépôt
await ouvrirPage(s, base); const zeros = '0'.repeat(40);
out.c = { r: await s.ev(OS(zeros)) }; await pause(500);
Object.assign(out.c, await s.ev(`({ commit: ${comm}, ouvert: !${T}.hidden, indispo: /Indisponible/.test(${REG}?.textContent || ''),
  reessayer: [...(${VOL}?.querySelectorAll('button') || [])].some((b) => b.textContent.trim() === 'Réessayer'),
  errs: window.__errs.length })`));
// GP4.4 : rangée rendue (la 100e), tiroir ouvert
await ouvertSur();
await s.ev(`${CORPS}.scrollTop = 0; window.__av = document.activeElement; window.__sha100 = [...${RANGEES}][99].dataset.h`);
out.d = { r: await s.ev(`window.VFGitTiroir.ouvrirSur(window.__sha100)`) }; await pause(600);
Object.assign(out.d, await s.ev(`(() => { const L = [...${RANGEES}], li = L[99], c = ${CORPS}.getBoundingClientRect(), b = li.getBoundingClientRect();
  return { sel: li.getAttribute('aria-selected'), tab0: L.filter((x) => x.getAttribute('tabindex') === '0').length,
    tabLi: li.getAttribute('tabindex'), visible: b.top >= c.top - 1 && b.bottom <= c.bottom + 1,
    focus: document.activeElement === window.__av, nom: ${REG}?.getAttribute('aria-label'),
    anim: document.getAnimations().filter((a) => a.playState === 'running').length }; })()`));
// GP4.5 : deux appels d'affilée
await ouvertSur();
out.e = await s.ev(`(async () => { const L = [...${RANGEES}], a = L[3].dataset.h, b = L[5].dataset.h;
  const x = window.VFGitTiroir.ouvrirSur(a), y = window.VFGitTiroir.ouvrirSur(b), r = await Promise.all([x, y]);
  return { r, volets: document.querySelectorAll('.vf-git-detail').length, nom: ${REG}?.getAttribute('aria-label'), b7: b.slice(0, 7) }; })()`);
// GP4.6 : persistance (orphelin), puis disparition d'un commit présent dans la lecture précédente
await ouvertSur();
out.f = { r1: await s.ev(OS(orph)) };
await s.ev(`document.dispatchEvent(new CustomEvent('vf-git:signal'))`); await pause(1500);
out.f.orphelin = await s.ev(`${REG}?.getAttribute('aria-label') === 'Détail du commit ' + '${orph}'.slice(0, 7)`);
out.f.r2 = await s.ev(OS(racine));
out.f.stub = await s.ev(`(() => { const rep = JSON.parse(JSON.stringify(window.VFGitTiroir.donnees())), f0 = window.fetch.bind(window);
  const avant = rep.rangees.length;
  rep.rangees = rep.rangees.filter((r) => r.h !== '${racine}');
  const ok = () => Promise.resolve(new Response(JSON.stringify(rep), { status: 200, headers: { 'content-type': 'application/json' } }));
  window.fetch = (u, i) => (/\\/api\\/vf\\/git(\\?|$)/.test(typeof u === 'string' ? u : u.url) ? ok() : f0(u, i));
  return [avant, rep.rangees.length]; })()`);
await s.ev(`document.dispatchEvent(new CustomEvent('vf-git:signal'))`); await pause(1500);
out.f.replie = await s.ev(`document.querySelectorAll('.vf-git-detail').length`);
out.f.errs = await s.ev(`window.__errs.length`);
return out;
JS
  R4="$(VF_PRE="$AUX/pre-reel.js" cdp "$AUX/gp4.js" "$BASE" "$RACINE" "$ORPH")"
  trace gp4 "$R4"
  assert_eq "GP4.1 — commit hors des 100 rangées : true, tiroir ouvert, volet sur ce commit (sujet lu), requête du commit, 1 lecture de la liste" \
    "$(jq_ "$R4" '(() => { const a = j.a;
      return [a.r, a.ouvert, /^Détail du commit /.test(a.nom), /init/.test(a.texte), a.commit.length, a.git].join("|"); })()' 2>/dev/null)" \
    "true|true|true|true|1|1"
  assert_eq "GP4.1 — jamais de pagination : 100 rangées, aucune ne porte ce sha, aucune erreur de page" \
    "$(jq_ "$R4" '[j.a.rangees, j.a.porte, j.a.errs].join("|")' 2>/dev/null)" \
    "100|false|0"
  assert_eq "GP4.2 — neuf shas refusés : chaque appel rend false sans exception, 0 requête, tiroir fermé, 0 erreur de page" \
    "$(jq_ "$R4" '[j.b.r.join(","), j.b.exc.length, j.b.reqs, j.b.ouvert, j.b.errs].join("|")' 2>/dev/null)" \
    "false,false,false,false,false,false,false,false,false|0|0|false|0"
  assert_eq "GP4.3 — sha valide mais absent du dépôt : false, une requête du commit, « Indisponible » et « Réessayer », tiroir ouvert" \
    "$(jq_ "$R4" '(() => { const c = j.c; return [c.r, c.commit.length, c.commit[0] && c.commit[0].endsWith("sha=" + "0".repeat(40)),
      c.indispo, c.reessayer, c.ouvert, c.errs].join("|"); })()' 2>/dev/null)" \
    "false|1|true|true|true|true|0"
  assert_eq "GP4.4 — rangée rendue : true, sélectionnée, seule à tabindex 0, visible, focus inchangé, volet nommé, aucune animation" \
    "$(jq_ "$R4" '(() => { const d = j.d;
      return [d.r, d.sel, d.tab0, d.tabLi, d.visible, d.focus, /^Détail du commit /.test(d.nom), d.anim].join("|"); })()' 2>/dev/null)" \
    "true|true|1|0|true|true|true|0"
  assert_eq "GP4.5 — deux appels d'affilée : la première promesse rend false (remplacée), la seconde true, un seul volet, nommé d'après le second" \
    "$(jq_ "$R4" '[j.e.r.join(","), j.e.volets, j.e.nom === "Détail du commit " + j.e.b7].join("|")' 2>/dev/null)" \
    "false,true|1|true"
  assert_eq "GP4.6 — commit que la liste ne porte pas : le volet survit à la relecture ; disparu de la lecture : il se replie" \
    "$(jq_ "$R4" '[j.f.r1, j.f.orphelin, j.f.r2, j.f.stub.join(), j.f.replie, j.f.errs].join("|")' 2>/dev/null)" \
    "true|true|true|130,129|0|0"
  stop_srv
fi

echo "=== GP3 — poignée de largeur : clavier, bornes, mémoire par lab, carte jamais poussée ==="
if ! veut GP3; then :; elif [ -z "$CHROME" ]; then skip "GP3" "pas de navigateur"; else
  build_serve "$DEPOT"; BASE="http://127.0.0.1:$PORT"
  cat > "$AUX/gp3.js" <<'JS'
const [base] = ARGS, { ouvrirPage, LIGNE, RANGEES, pause, touche } = await import(process.env.GP_ENTREE);
const out = { k: {} }, T = `document.querySelector('#vf-git-tiroir')`, P = `${T}.querySelector('.vf-git-poignee')`;
const att = (e, l) => s.attendre(e, l, 4000).catch(() => null);
const lire = () => s.ev(`(() => { const p = ${P}, t = ${T};
  return p && { now: Number(p.getAttribute('aria-valuenow')), max: Number(p.getAttribute('aria-valuemax')),
    min: Number(p.getAttribute('aria-valuemin')), txt: p.getAttribute('aria-valuetext'), larg: Math.round(t.getBoundingClientRect().width) }; })()`);
const rouvrir = async () => { await ouvrirPage(s, base); await s.ev(`${LIGNE}.click()`); await att(`${RANGEES}.length > 0`, 'rangées'); };
const k = async (nom, key, vk, mods = 0) => { await touche(s, key, key, vk, mods); out.k[nom] = await lire(); };
await rouvrir();
out.id = await s.ev(`(() => { const p = ${P}; return p && { role: p.getAttribute('role'), ori: p.getAttribute('aria-orientation'),
  nom: p.getAttribute('aria-label'), tab: p.tabIndex }; })()`);
const PW = `parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--panel-w')) || 360`;
out.attMax = await s.ev(`Math.max(280, innerWidth - (${PW}) - 312)`);
await s.ev(`${P}?.focus()`); out.depart = await lire();
await k('droite', 'ArrowRight', 39); await k('maj', 'ArrowRight', 39, 8);
await k('fin', 'End', 35); await k('finDroite', 'ArrowRight', 39);
await k('origine', 'Home', 36); await k('origineGauche', 'ArrowLeft', 37); await k('entree', 'Enter', 13);
await k('memoire', 'ArrowRight', 39, 8);                                            // GP3.2 : 360 + 64 = 424, mémorisée
out.cle = await s.ev(`Object.keys(localStorage).filter((x) => x.startsWith('vf-git-largeur:'))`);
await rouvrir(); out.restauree = await lire();
await s.ev(`localStorage.setItem(${JSON.stringify(out.cle[0])}, '99999')`); await rouvrir(); out.haut = await lire();
await s.ev(`localStorage.setItem(${JSON.stringify(out.cle[0])}, 'abc')`); await rouvrir(); out.texte = await lire();
// GP3.3 : ouvrir, paginer, redimensionner, fermer : la carte et la zone libre ne bougent pas (PU-G-204)
const SNAP = `JSON.stringify([window.VibeFlow.state.t, window.VibeFlow.freeArea()])`;
await pause(400); out.avant = await s.ev(SNAP);
await s.ev(`${LIGNE}.click()`); await pause(300); await s.ev(`${LIGNE}.click()`); await pause(300);
await s.ev(`${P}?.focus()`);
await touche(s, 'ArrowRight', 'ArrowRight', 39, 8); await touche(s, 'ArrowRight', 'ArrowRight', 39, 8);
out.pas = await lire(); out.foc = await s.ev(`document.activeElement === ${P}`);
await s.ev(`window.__vfGit.reponse = window.__mk(300); window.VFGitTiroir.recharger()`);
await att(`${RANGEES}.length === 100`, '100 rangées');
await s.ev(`document.querySelector('.vf-git-plus-b')?.click()`); await pause(300);
await s.ev(`${LIGNE}.click()`); await pause(300); await s.ev(`${LIGNE}.click()`); await pause(1200);
out.apres = await s.ev(SNAP); out.maj = await lire();
// GP3.5 : la barre de défilement du corps reste saisissable, la poignée est en retrait (2 px, 24 px en haut et en bas)
out.barre = await s.ev(`(() => { const c = ${T}.querySelector('.vf-git-corps'), r = c.getBoundingClientRect(), t = ${T}.getBoundingClientRect();
  const p = ${P}.getBoundingClientRect(), e = document.elementFromPoint(r.right - 3, r.top + r.height / 2);
  return { poignee: !!(e && e.closest('.vf-git-poignee')), droite: Math.round(t.right - p.right), haut: Math.round(p.top - t.top),
    bas: Math.round(t.bottom - p.bottom), defile: c.scrollHeight > c.clientHeight }; })()`);
// GP3.6 : la largeur choisie revient quand la place revient (Fin, fenêtre étroite, fenêtre large)
await s.ev(`${P}?.focus()`); await touche(s, 'End', 'End', 35); out.rev = { fin: (await lire()).now };
await s.send('Emulation.setDeviceMetricsOverride', { width: 1100, height: 900, deviceScaleFactor: 1, mobile: false }); await pause(600);
out.rev.petit = (await lire()).now;
await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false }); await pause(600);
out.rev.retour = (await lire()).now;
// GP3.4 : 900 px, aucune poignée ; mouvement réduit : glisser à la souris sans animation
await s.send('Emulation.setDeviceMetricsOverride', { width: 900, height: 900, deviceScaleFactor: 1, mobile: false }); await pause(500);
out.petit = await s.ev(`(() => { const p = ${P}; return { present: !!p, visible: !!p && p.getClientRects().length > 0 }; })()`);
await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false }); await pause(500);
const r = await s.ev(`(() => { const b = ${P}.getBoundingClientRect(), t = ${T}.getBoundingClientRect();
  return { x: b.left + b.width / 2, y: b.top + b.height / 2, g: t.left }; })()`);
const anim = () => s.ev(`document.getAnimations().filter((a) => a.playState === 'running').length`);
const souris = (type, x) => s.send('Input.dispatchMouseEvent', { type, x, y: r.y, button: 'left', buttons: type === 'mouseReleased' ? 0 : 1, clickCount: 1 });
out.anims = [];
await souris('mousePressed', r.x); out.anims.push(await anim());
for (const w of [380, 400, 420]) { await souris('mouseMoved', r.g + w); out.anims.push(await anim()); }
await souris('mouseReleased', r.g + 420); await pause(200); out.anims.push(await anim()); out.glisse = await lire();
out.errs = await s.ev(`window.__errs`);
return out;
JS
  R3="$(VF_MEDIA="prefers-reduced-motion=reduce" cdp "$AUX/gp3.js" "$BASE")"
  trace gp3 "$R3"
  assert_eq "GP3.1 — séparateur vertical nommé, 360 px à 1440 ; → 376 ; Maj+→ 440 ; Origine 280 ; Entrée 360" \
    "$(jq_ "$R3" '(() => { const k = j.k, i = j.id, d = j.depart;
      return [i.role, i.ori, i.nom, i.tab, d.now, d.txt, k.droite.now, k.maj.now, k.origine.now, k.entree.now].join("|"); })()' 2>/dev/null)" \
    "separator|vertical|Largeur de l'historique Git|0|360|360 pixels|376|440|280|360"
  assert_eq "GP3.1 — bornes : Fin = max(280, 1440 - panneau - 312), jamais dépassées par → ni par ←, largeur réelle égale à la valeur" \
    "$(jq_ "$R3" '(() => { const k = j.k, M = j.attMax;
      return [k.fin.now === M, k.fin.max === M, k.finDroite.now === M, k.origine.min, k.origineGauche.now,
        k.maj.larg === k.maj.now, k.fin.larg === M].join("|"); })()' 2>/dev/null)" \
    "true|true|true|280|280|true|true"
  assert_eq "GP3.2 — largeur mémorisée sous une clé qui porte le nom du lab (depot), restaurée au rechargement ; valeur hostile ramenée aux bornes" \
    "$(jq_ "$R3" '[j.cle.join() === "vf-git-largeur:depot", j.k.memoire.now, j.restauree.now,
      j.haut.now === j.attMax, j.texte.now].join("|")' 2>/dev/null)" \
    "true|424|424|true|360"
  assert_eq "GP3.2 — aucun fichier écrit sous .planning/ du dépôt" "$($GIT -C "$DEPOT" status --porcelain -- .planning | wc -l | tr -d ' ')" "0"
  assert_eq "GP3.3 — ouvrir, paginer, redimensionner et fermer : transformation de la carte et zone libre identiques (PU-G-204)" \
    "$(jq_ "$R3" '[typeof j.avant, j.avant === j.apres, j.maj.now].join("|")' 2>/dev/null)" "string|true|488"
  assert_eq "GP3.4 — 900 px : aucune poignée visible ; mouvement réduit : 0 animation active pendant le glisser, largeur suivie (420)" \
    "$(jq_ "$R3" '[j.petit.visible, j.anims.join(), j.glisse.now, j.glisse.larg].join("|")' 2>/dev/null)" \
    "false|0,0,0,0,0|420|420"
  assert_eq "GP3.5 — la barre de défilement n'est pas recouverte par la poignée, qui est en retrait de 2 px et de 24 px en haut et en bas" \
    "$(jq_ "$R3" '[j.barre.defile, j.barre.poignee, j.barre.droite, j.barre.haut, j.barre.bas].join("|")' 2>/dev/null)" "true|false|2|24|24"
  assert_eq "GP3.6 — fenêtre à 1100 px : 428 ; retour à 1440 px : la largeur choisie (maximum) revient" \
    "$(jq_ "$R3" '[j.rev.fin, j.rev.petit, j.rev.retour].join("|")' 2>/dev/null)" "768|428|768"
  assert_eq "GP3 — aucune erreur de page" "$(jq_ "$R3" 'j.errs.length' 2>/dev/null)" "0"
  stop_srv
fi

echo "=== GP5 — pastilles « modifiés » neutres (P78-D-33, P73-D-10, Q9) : témoin D8.2 rejoué, captures ==="
if ! veut GP5; then :; elif [ -z "$CHROME" ]; then skip "GP5, GP6" "pas de navigateur"; else
  build_serve "$DEPOT"; BASE="http://127.0.0.1:$PORT"
  cat > "$AUX/gp5.js" <<'JS'
const [base, mode] = ARGS, { ouvrirPage, LIGNE, RANGEES, pause } = await import(process.env.GP_ENTREE);
const att = (e, l) => s.attendre(e, l, 6000).catch(() => null);
const out = {}, WT = `document.querySelector('#vf-git-s-wt')`;
await ouvrirPage(s, base); await s.ev(`${LIGNE}.click()`); await att(`${RANGEES}.length === 40`, '40 rangées');
await s.ev(`(() => { const b = document.querySelector('[aria-controls=vf-git-s-wt]');
  if (b.getAttribute('aria-expanded') !== 'true') b.click(); })()`);
await att(`/modifiés/.test(${WT}.textContent)`, 'pastilles « modifiés » lues');
out.mention = await s.ev(`${WT}.textContent.includes('approximatif : filtres du dépôt non exécutés')`);
out.couleurs = await s.ev(`(() => { const P = [...document.querySelectorAll('#vf-git-s-wt .vf-git-pastille')];
  const mod = P.find((p) => /modifiés/.test(p.textContent)), pro = P.find((p) => p.textContent === 'propre');
  const N = window.__couleur('--text-2'), g = (p) => getComputedStyle(p, '::before').content;
  const ok = (p) => { const c = getComputedStyle(p);
    return c.color === N && (c.backgroundColor === 'rgba(0, 0, 0, 0)' || c.backgroundColor === 'transparent') && c.backgroundImage === 'none'; };
  return { mod: ok(mod), pro: ok(pro), tous: P.every(ok), gl: g(mod).includes('◐') && g(pro).includes('✓') }; })()`);
if (mode === 'cap') {
  for (const [theme, nom] of [['light', 'clair'], ['dark', 'sombre']]) {
    await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-color-scheme', value: theme }] }); await pause(500);
    await cap('tiroir-git-worktrees-modifies-' + nom + '-v2');
  }
}
return out;
JS
  R5="$(cdp "$AUX/gp5.js" "$BASE")"
  assert_eq "GP5.1 — D8.2 rejouée sur le vrai module : « modifiés » et « propre » en texte neutre (--text-2) sur fond transparent, glyphes ◐ et ✓" \
    "$(jq_ "$R5" '[j.mention, j.couleurs.mod, j.couleurs.pro, j.couleurs.tous, j.couleurs.gl].join("|")' 2>/dev/null)" \
    "true|true|true|true|true"
  if [ -n "${GP_CAPTURES:-}" ]; then
    cdp "$AUX/gp5.js" "$BASE" cap > /dev/null
    cat > "$AUX/gp6.js" <<'JS'
const [base] = ARGS, { ouvrirPage, LIGNE, RANGEES, pause, touche } = await import(process.env.GP_ENTREE);
const att = (e, l) => s.attendre(e, l, 6000).catch(() => null);
const themes = [['light', 'clair'], ['dark', 'sombre']];
await ouvrirPage(s, base); await s.ev(`window.__vfGit.reponse = window.__mk(612)`);
await s.ev(`${LIGNE}.click()`); await att(`${RANGEES}.length === 100`, '100 rangées');
await s.ev(`document.querySelector('.vf-git-plus-b').scrollIntoView({ block: 'center' })`); await pause(400);
for (const [t, n] of themes) {
  await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-color-scheme', value: t }] }); await pause(500);
  await cap('tiroir-git-pagination-' + n + '-v2');
}
await s.send('Emulation.setDeviceMetricsOverride', { width: 1024, height: 768, deviceScaleFactor: 1, mobile: false });
await s.ev(`document.querySelector('#vf-git-tiroir .vf-git-corps').scrollTop = 0; document.querySelectorAll('#vf-git-tiroir li[role=option]')[2].focus()`);
await touche(s, 'Enter', 'Enter', 13); await att(`!!document.querySelector('.vf-git-detail .vf-git-d-fichiers')`, 'détail lu'); await pause(400);
for (const [t, n] of themes) {
  await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-color-scheme', value: t }] }); await pause(500);
  await cap('tiroir-git-volet-1024-' + n + '-v2');
}
await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
await s.ev(`window.VFGitTiroir.fermer(); document.querySelector('#vf-git-ligne').click()`); await pause(500);
await s.ev(`document.querySelector('.vf-git-poignee').focus()`); await touche(s, 'ArrowRight', 'ArrowRight', 39, 8); await pause(300);
for (const [t, n] of themes) {
  await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-color-scheme', value: t }] }); await pause(500);
  await cap('tiroir-git-poignee-' + n + '-v2');
}
return {};
JS
    cdp "$AUX/gp6.js" "$BASE" > /dev/null
  fi
  stop_srv
fi

echo "=== Mutants (copie du module dans \$WORK, jamais le module) ==="
if ! veut MUTANTS; then :; elif [ -z "$CHROME" ]; then skip "mutants" "pas de navigateur"; else
  mkmod() { local d="$WORK/mod-$1"; mkdir -p "$d/scripts" "$d/skills"; cp "$SCRIPTS"/*.mjs "$SCRIPTS"/*.json "$d/scripts/"
    cp -R "$SCRIPTS/../skills/cockpit-moteur" "$d/skills/cockpit-moteur"; echo "$d/scripts"; }
  mutlab() { local L="$WORK/lab-$1"; mk_lab "$L"; $GIT -C "$L" init -q -b main && $GIT -C "$L" add -A && $GIT -C "$L" commit -q -m init; echo "$L"; }
  # mutant <nom> <fichier ui> <ancien> <nouveau> <scénario> <lab ou -> <pre> [arguments du scénario] -> RM ; une mutation qui ne s'applique pas est un échec
  mutant() {
    local nom="$1" f="$2" a="$3" b="$4" sc="$5" lab="$6" pre="$7" M L; shift 7
    [ -z "${GP_MUT:-}" ] || [ "$GP_MUT" = "$nom" ] || { RM="{}"; return; } # GP_MUT=M-POUSSE : ne joue que ce mutant (mise au point)
    M="$(mkmod "$nom")"; if [ "$lab" = "-" ]; then L="$(mutlab "$nom")"; else L="$lab"; fi
    if ! mutate "$M/../skills/cockpit-moteur/assets/ui/$f" "$a" "$b"; then ko_ "$nom : mutation impossible" "impossible" "appliquée"; RM="{}"; return; fi
    if cmp -s "$M/../skills/cockpit-moteur/assets/ui/$f" "$SCRIPTS/../skills/cockpit-moteur/assets/ui/$f"; then
      ko_ "$nom : la copie n'a pas changé" "identique" "différente"; RM="{}"; return; fi
    build_serve "$L" "$M"; RM="$(VF_PRE="$AUX/$pre" cdp "$AUX/$sc" "http://127.0.0.1:$PORT" "$@")"; stop_srv
    rm -rf "$WORK/mod-$nom"; [ "$lab" = "-" ] && rm -rf "$L"
  }
  mutant M-TOUT 77-vf-git-rendu.js "Math.max(et.n || 0, total <= SEUIL ? total : PAGE)" "total" gp1.js - pre-mock.js
  assert_eq "M-TOUT — le mutant rougit GP1.1 (toutes les rangées rendues d'un coup, ni bouton) alors que 105 rangées se rendent toujours" \
    "$(jq_ "$RM" '[j.a.n, j.a.bouton, j.c.n].join("|")' 2>/dev/null)" "612|false|105"
  mutant M-EPUISE 77-vf-git-rendu.js "if (fruit[0]) fruit[0].focus({ preventScroll: false });" \
    "if (fruit[0] && reste > 0) fruit[0].focus({ preventScroll: false });" gp1.js - pre-mock.js
  assert_eq "M-EPUISE — le mutant rougit GP1.4 (le clic qui épuise la liste laisse le focus sur body) alors que GP1.2 et le premier clic tiennent" \
    "$(jq_ "$RM" '[j.b.actif, j.d1.actif, j.d2.corps].join("|")' 2>/dev/null)" "100|100|true"
  mutant M-BORNE 77-vf-git-poignee.js "const borner = (v) => Math.max(MIN, Math.min(maximum(), Math.round(v)));" \
    "const borner = (v) => Math.round(v);" gp3.js - pre-mock.js
  assert_eq "M-BORNE — le mutant rougit GP3.1 (→ après Fin dépasse le maximum, ← après Origine passe sous 280) alors que le départ reste à 360" \
    "$(jq_ "$RM" '[j.k.finDroite.now > j.attMax, j.k.origineGauche.now < 280, j.depart.now].join("|")' 2>/dev/null)" "true|true|360"
  mutant M-POUSSE 77-vf-git-poignee.js "tiroir.style.setProperty('--vf-git-l', w + 'px');" \
    "tiroir.style.setProperty('--vf-git-l', w + 'px'); document.documentElement.style.setProperty('--panel-w', w + 'px');" gp3.js - pre-mock.js
  trace mpousse "$RM"
  assert_eq "M-POUSSE — le mutant rougit GP3.3 (le redimensionnement pousse le panneau, donc la zone libre de la carte) alors que la largeur suit (488)" \
    "$(jq_ "$RM" '[typeof j.avant, j.avant === j.apres, j.maj.now].join("|")' 2>/dev/null)" "string|false|488"
  NP="const p = V.ouvrir(sha, li); (async () => { for (let n = 0; n < 20; n++) {"
  NP="$NP await new Promise((r) => setTimeout(r, 100)); if (rangeDe(sha)) break;"
  NP="$NP const b = corps.querySelector('.vf-git-plus-b'); if (b) b.click(); } })();"
  mutant M-PAGINE 77-vf-git-tiroir.js "const p = V.ouvrir(sha, li);" "$NP" gp4.js "$LAB4" pre-reel.js "$RACINE" "$ORPH"
  assert_eq "M-PAGINE — le mutant rougit GP4.1 (la recherche de la rangée pagine : plus de 100 rangées) alors que ouvrirSur rend encore true" \
    "$(jq_ "$RM" '[j.a.r, j.a.rangees > 100].join("|")' 2>/dev/null)" "true|true"
  mutant M-MOTIF 77-vf-git-rendu.js "motifSha: /^[0-9a-f]{40}\$/" "motifSha: /^[\\s\\S]*\$/" gp4.js "$LAB4" pre-reel.js "$RACINE" "$ORPH"
  assert_eq "M-MOTIF — le mutant rougit GP4.2 (un sha refusé ouvre le tiroir et part en requête) alors que GP4.1 reste vert" \
    "$(jq_ "$RM" '[j.b.ouvert, j.b.reqs > 0, j.a.r].join("|")' 2>/dev/null)" "true|true|true"
  mutant M-VOLET-LIE 77-vf-git-vue-detail.js "const disparu = !!v && !!prec && prec.has(v) && !maint.has(v);" \
    "const disparu = !!v && !lignes().some((l) => l.dataset.h === v);" gp4.js "$LAB4" pre-reel.js "$RACINE" "$ORPH"
  assert_eq "M-VOLET-LIE — le mutant rougit GP4.6 (le volet d'un commit sans rangée se ferme à la relecture) alors que D9.2 tient" \
    "$(jq_ "$RM" '[j.f.r1, j.f.orphelin, j.f.replie].join("|")' 2>/dev/null)" "true|false|0"
  mutant M-PASTILLE 77-vf-git-vue-detail.js ".vf-git-p-lecture::before { content: '◌ ' / ''; }" \
    ".vf-git-p-lecture::before { content: '◌ ' / ''; } .vf-git-p-warn { background: var(--warn-bg); }" gp5.js - pre-mock.js
  assert_eq "M-PASTILLE — le mutant rougit la mesure de D8.2 (fond teinté sur « modifiés » : false en position 2) alors que « propre » reste neutre" \
    "$(jq_ "$RM" '[j.mention, j.couleurs.mod, j.couleurs.pro, j.couleurs.tous, j.couleurs.gl].join("|")' 2>/dev/null)" "true|false|true|false|true"
fi

vf_hyg_assert
echo; echo "Résultats : $PASS réussis, $FAIL échoués, $SKIP sautés"
[ "$FAIL" -eq 0 ]
