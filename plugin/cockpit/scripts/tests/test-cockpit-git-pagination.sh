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
export async function ouvrirPage(s, base, l = 1440, h = 900) {
  await s.naviguer(base + '/');
  await s.send('Emulation.setDeviceMetricsOverride', { width: l, height: h, deviceScaleFactor: 1, mobile: false });
  await s.attendre(`document.readyState === 'complete' && !!${LIGNE} && getComputedStyle(${LIGNE}).display !== 'none'`, 'seconde ligne');
}
JS

echo "=== GP1 — rangées paginées, focus sur la première rangée ajoutée ==="
if [ -z "$CHROME" ]; then skip "GP1, GP2, GP3" "pas de navigateur"; else
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
  export GP_ENTREE="file://$AUX/entree.js"
  R1="$(cdp "$AUX/gp1.js" "$BASE")"
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
  assert_eq "GP1 — aucune erreur de page" "$(jq_ "$R1" 'j.errs.length' 2>/dev/null)" "0"
  stop_srv
fi

vf_hyg_assert
echo; echo "Résultats : $PASS réussis, $FAIL échoués, $SKIP sautés"
[ "$FAIL" -eq 0 ]
