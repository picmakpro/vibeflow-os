#!/usr/bin/env bash
# test-cockpit-git-entete.sh — en-tête Git du cockpit (78-04 ; GITC-01, 02, 03, 05, 12 ; P78-D-01, 02, 03, 09, 10, 11, 12, 19, 20).
#   H1 données (enteteGit) · H2 nom du dépôt sur les trois onglets · H3 seconde ligne et événements · H4 ouvreur mobile
#   H5 dégradation sans git, texte venu de git rendu en texte · H6 bloc de vue, retrait de « Repositories », feuille sans valeur en dur
#   Mutants : M-DEPOT, M-TEXTE, M-ABSENT. Chrome headless en CDP (SAUTÉ, jamais compté réussi, sans navigateur), ports éphémères.
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; }
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
HERE_T="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="$(cd "$HERE_T/.." && pwd)"
UI="$(cd "$SCRIPTS/.." && pwd)/skills/cockpit-moteur/assets/ui"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"
REAL_HOME="$HOME"; export HOME="$WORK/home"
PIDS=()
SRV=""
stop_srv() { [ -n "$SRV" ] && { vf_hyg_stop "$SRV"; }; SRV=""; }
trap 'stop_srv; vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"' EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init

PASS=0; FAIL=0; SKIP=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
skip() { echo "  ⏭️  SAUTÉ — $1 ($2)"; SKIP=$((SKIP+1)); }

CHROME=""
for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue
  if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
[ -n "${ENTETE_SANS_NAVIGATEUR:-}" ] && CHROME=""
echo "navigateur : ${CHROME:-aucun (les sections Chrome sont SAUTÉES)}"

# --- aides node ---
cat > "$AUX/json.mjs" <<'JS'
// json.mjs '<json>' '<expression sur j>' : évalue l'expression, imprime la chaîne ou le JSON
const j = JSON.parse(process.argv[2]);
const v = new Function('j', 'return (' + process.argv[3] + ')')(j);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/entete.mjs" <<'JS'
// entete.mjs <module> <dossier> : enteteGit(dossier) du module donné, une ligne JSON
const m = await import(process.argv[2]);
console.log(JSON.stringify(m.enteteGit(process.argv[3])));
JS
cat > "$AUX/cdp-run.mjs" <<'JS'
// cdp-run.mjs <chrome> <scenario.js> [args…] : joue le corps asynchrone du scénario avec (s, ARGS) après avoir posé les crochets de pre.js (VF_PRE) ; une ligne JSON
import fs from 'node:fs';
const { executer } = await import(process.env.VF_CS);
const [, , chrome, fichier, ...ARGS] = process.argv;
const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor;
const corps = new AsyncFunction('s', 'ARGS', fs.readFileSync(fichier, 'utf8'));
const PRE = process.env.VF_PRE ? fs.readFileSync(process.env.VF_PRE, 'utf8') : '';
await executer(chrome, async (s) => { if (PRE) await s.send('Page.addScriptToEvaluateOnNewDocument', { source: PRE }); return corps(s, ARGS); }, { csp: true });
JS
export VF_CS="$HERE_T/chrome-session.mjs"
cdp() { node "$AUX/cdp-run.mjs" "$CHROME" "$@"; } # cdp <scenario.js> [args…]
jq_() { node "$AUX/json.mjs" "$1" "$2"; }

NODE="$(command -v node)"; ENVX=""
GIT="git -c user.email=t@t -c user.name=t"
mk_lab() { # $1 = dossier : lab GSD minimal, un commit
  mkdir -p "$1/src" "$1/.planning/phases/01-x"
  printf 'export const util = () => 1;\n' > "$1/src/util.js"
  printf -- '- [x] **Phase 1: Socle** - premier jet\n- [ ] **Phase 2: Suite** - deuxième jet\n' > "$1/.planning/ROADMAP.md"
  printf -- '---\nstatus: executing\nmilestone: vibeflow-test\n---\n# State\n' > "$1/.planning/STATE.md"
  printf '<objective>Faire le socle</objective>\n' > "$1/.planning/phases/01-x/01-01-PLAN.md"; echo ok > "$1/.planning/phases/01-x/01-01-SUMMARY.md"
}
build_serve() { # $1 = lab, $2 = dossier de scripts (défaut : le module) ; $ENVX = préfixe d'environnement ; pose OUT, PORT ; démarre le serveur (SRV)
  env $ENVX "$NODE" "${2:-$SCRIPTS}/vf-cockpit-build.mjs" "$1" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
  OUT="$1/.vibeflow/cockpit"
  env $ENVX ${ENVS:-} "$NODE" "$OUT/serve.mjs" --no-open --port "$(libre)" > "$WORK/serve.out" 2>&1 &
  SRV=$!; PIDS+=("$SRV")
  for _ in $(seq 1 100); do [ -s "$OUT/.cache/server.json" ] && break; sleep 0.1; done
  PORT="$(node -e "console.log(JSON.parse(require('fs').readFileSync('$OUT/.cache/server.json','utf8')).port)" 2>/dev/null || echo 0)"
}

# faux driver-lock.sh TENU (comme projet-commun.sh, socle de test-cockpit-projet-graphe.sh) : une mission dont un nœud est running n'est « en cours » que si son verrou est vivant (P68-D-05) ;
# VF_COCKPIT_SCRIPTS_DIR n'est posé que pour le SERVEUR (ENVS), jamais pour le build
mkdir -p "$WORK/locks"
printf '#!/usr/bin/env bash\ncase "$1" in status) echo "{\\"present\\": true, \\"ws\\": \\"\\", \\"stale\\": false, \\"ttl\\": 1800, \\"progress_age_seconds\\": 30}";; orphans) echo "{\\"orphans\\":[]}";; esac\n' > "$WORK/locks/driver-lock.sh"; chmod +x "$WORK/locks/driver-lock.sh"

# --- dépôt jetable : `depot` (principal) et le worktree `wt-a` sur feat/x ---
DEPOT="$WORK/depot"; WT="$WORK/wt-a"
mk_lab "$DEPOT"
$GIT -C "$DEPOT" init -q -b main && $GIT -C "$DEPOT" add -A && $GIT -C "$DEPOT" commit -q -m init
$GIT -C "$DEPOT" worktree add -q -b feat/x "$WT" >/dev/null 2>&1

echo "=== H1 — enteteGit ==="
MOD="$SCRIPTS/vf-cockpit-git-entete.mjs"
H1W="$(node "$AUX/entete.mjs" "$MOD" "$WT" 2>&1 | tail -1)"
H1D="$(node "$AUX/entete.mjs" "$MOD" "$DEPOT" 2>&1 | tail -1)"
assert_eq "H1.1 — depuis le worktree : dépôt principal, branche, worktree" "$(jq_ "$H1W" '[j.etat,j.depot,j.branche,j.worktree,j.detache].join("|")' 2>/dev/null)" "ok|depot|feat/x|wt-a|false"
assert_eq "H1.1b — depuis l'arbre principal : pas de worktree" "$(jq_ "$H1D" '[j.etat,j.depot,j.branche,String(j.worktree)].join("|")' 2>/dev/null)" "ok|depot|main|null"

# H1.2 : git répond pour le dossier commun mais rien d'autre -> « indisponible », jamais une exception (sh injecté)
cat > "$AUX/indispo.mjs" <<'JS'
const { enteteGit } = await import(process.argv[2]);
const sh = (cmd, args) => (args.includes('--git-common-dir') ? '/x/depot/.git\n' : '');
console.log(JSON.stringify(enteteGit('/x/depot', { sh })));
JS
H12="$(node "$AUX/indispo.mjs" "$MOD" 2>&1 | tail -1)"
assert_eq "H3.2a — dépôt vu mais HEAD illisible : indisponible, nom du dépôt gardé" "$(jq_ "$H12" '[j.etat,j.depot,j.branche,j.detache].join("|")' 2>/dev/null)" "indisponible|depot||false"

# --- aides navigateur : crochets posés avant la page (erreurs, alert, fetch d'en-tête) ---
cat > "$AUX/pre.js" <<'JS'
window.__errs = [];
addEventListener('error', (e) => window.__errs.push(String(e.message)));
addEventListener('unhandledrejection', (e) => window.__errs.push('rejet ' + String(e.reason)));
{ const ce = console.error; console.error = (...a) => { window.__errs.push(a.map(String).join(' ')); ce.apply(console, a); }; }
window.__alerte = 0; window.alert = () => { window.__alerte++; };
window.__vfFetch = { reponse: null, appels: [] };
{ const f0 = window.fetch.bind(window);
  window.fetch = (u, i) => { const url = typeof u === 'string' ? u : u.url;
    if (/\/api\/vf\/git\/entete/.test(url) && window.__vfFetch.reponse) { window.__vfFetch.appels.push({ url, headers: (i && i.headers) || {} });
      return Promise.resolve(new Response(JSON.stringify(window.__vfFetch.reponse), { status: 200, headers: { 'content-type': 'application/json' } })); }
    return f0(u, i); }; }
JS
export VF_PRE="$AUX/pre.js"
PRET="document.readyState === 'complete' && !!document.querySelector('#proj-name') && !!window.VibeFlow"

# --- copies privées du module pour les mutants et le témoin (VENDORED non nécessaire : le build lit assets/ui/*.js) ---
mkmod() { # $1 = nom ; rend le dossier des scripts de la copie (frère : skills/cockpit-moteur)
  local d="$WORK/mod-$1"; mkdir -p "$d/scripts" "$d/skills"
  cp "$SCRIPTS"/*.mjs "$SCRIPTS"/*.json "$d/scripts/"; cp -R "$SCRIPTS/../skills/cockpit-moteur" "$d/skills/cockpit-moteur"
  echo "$d/scripts"
}
cat > "$AUX/mut.mjs" <<'JS'
// mut.mjs <fichier> <ancien> <nouveau> : remplace UNE occurrence ; échoue (code 1) si l'ancien texte est absent (un mutant mort ne prouve rien)
import fs from 'node:fs';
const [, , f, a, b] = process.argv; const t = fs.readFileSync(f, 'utf8');
if (!t.includes(a) || t.split(a).length !== 2) { console.error('mutation impossible : motif absent ou multiple : ' + a); process.exit(1); }
fs.writeFileSync(f, t.replace(a, () => b));
JS
mutate() { node "$AUX/mut.mjs" "$@"; }

echo "=== H2 — nom du dépôt sur les trois onglets ==="
if [ -z "$CHROME" ]; then skip "H2, H3, H4, H5" "pas de navigateur"; else
  build_serve "$WT"; BASE="http://127.0.0.1:$PORT"
  cat > "$AUX/h2.js" <<'JS'
const [base, page] = ARGS;
await s.naviguer(base + page);
await s.attendre(`document.readyState === 'complete' && !!document.querySelector('#proj-name') && !!window.VibeFlow`, 'page rendue');
return await s.ev(`(() => ({ nom: document.querySelector('#proj-name').textContent, entete: document.querySelector('header').textContent,
  titre: document.title, attendu: window.VibeFlow.graph.meta.rootName,
  ligne: (document.querySelector('.vf-git-ligne') || {}).textContent || null }))()`);
JS
  for pg in / /project.html /equipe.html; do
    R="$(cdp "$AUX/h2.js" "$BASE" "$pg" 2>&1 | tail -1)"
    assert_eq "H2.2 — $pg : #proj-name = depot" "$(jq_ "$R" 'j.nom' 2>/dev/null)" "depot"
    assert_eq "H2.2 — $pg : aucun suffixe « — Projet » ni « — Équipe » dans l'en-tête" "$(jq_ "$R" '/ — (Projet|Équipe)/.test(j.entete) ? "suffixe" : "propre"' 2>/dev/null)" "propre"
    assert_eq "H2.2 — $pg : la seconde ligne dit la branche" "$(jq_ "$R" '/feat\/x/.test(j.ligne||"") ? "oui" : "non"' 2>/dev/null)" "oui"
    case "$pg" in /project.html) assert_eq "H2.2 — titre de l'onglet du navigateur inchangé (R6.1)" "$(jq_ "$R" 'j.titre === j.attendu + " — Projet" ? "inchangé" : j.titre' 2>/dev/null)" "inchangé";; esac
  done
  # H2.3 : une réécriture de project.html par le direct garde le nom du dépôt
  printf '<objective>Second plan ajouté par le test H2.3</objective>\n' > "$WT/.planning/phases/01-x/01-02-PLAN.md" # un plan neuf change la structure : le direct réécrit project.html
  for _ in $(seq 1 150); do grep -q 'Second plan ajouté par le test H2.3' "$OUT/project.html" 2>/dev/null && break; sleep 0.2; done
  assert_eq "H2.3a — témoin : project.html a bien été réécrit par le direct" "$(grep -c 'Second plan ajouté par le test H2.3' "$OUT/project.html")" "1"
  assert_eq "H2.3b — la page réécrite porte toujours meta.vfGit" "$(grep -c '"vfGit":{"etat":"ok"' "$OUT/project.html")" "1"
  R="$(cdp "$AUX/h2.js" "$BASE" /project.html 2>&1 | tail -1)"
  assert_eq "H2.3c — après réécriture, #proj-name = depot" "$(jq_ "$R" 'j.nom' 2>/dev/null)" "depot"

  echo "=== H3 — seconde ligne, événements, ouvreur ==="
  cat > "$AUX/h3.js" <<'JS'
const [base] = ARGS;
const { stabiliser, attendreValeur, attendreEtStabiliser, positionPosee } = await import(process.env.VF_CS); // aides communes (chrome-session.mjs) : on mesure une fois posé
await s.naviguer(base + '/');
await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false }); // la fenêtre headless par défaut est sous 1000 px : la seconde ligne y est masquée
await s.attendre(`document.readyState === 'complete' && !!document.querySelector('.vf-git-ligne') && getComputedStyle(document.querySelector('.vf-git-ligne')).display !== 'none'`, 'seconde ligne visible');
const out = {};
const ligne = () => `document.querySelector('.vf-git-ligne')`;
await s.attendre(`performance.getEntriesByType('resource').some((e) => e.name.includes('/api/vf/git/entete'))`, 'lecture du chargement terminée'); // sa réponse réelle, tardive sous charge, écraserait sinon les événements simulés ci-dessous
await stabiliser(() => s.ev(`(${ligne()} || {}).textContent`), { max: 10000 });
const evt = (nom, d) => s.ev(`window.dispatchEvent(new CustomEvent('${nom}', { detail: ${JSON.stringify(d)} }))`);
// Revue de code S2 (P78-D-15) : 70-vf-live.js émet `vf-git:signal` sur `document`, SANS bubbles (contrat de 78-09), exactement comme ici. L'ancienne forme (window.dispatchEvent) atteignait un écouteur posé sur window
// que le vrai émetteur n'atteint jamais : H3.4b était vert alors que l'en-tête ne se relisait pas sur le signal réel.
const signal = () => s.ev(`document.dispatchEvent(new CustomEvent('vf-git:signal', { detail: { sig: 'abc' } }))`);
// H3.3 : noms longs
const longB = 'feature/' + 'b'.repeat(112), longW = 'w'.repeat(60);
await evt('vf-git:entete', { etat: 'ok', depot: 'depot', branche: longB, worktree: longW, detache: false });
// la ligne se redessine après l'événement, pas dans la même tâche : on attend la valeur postérieure à l'événement (titre = noms longs), puis on la lit posée (CI Linux, run 42408767738)
out.longs = await attendreEtStabiliser(() => s.ev(`(() => { const l = ${ligne()}; if (!l) return null; const b = l.querySelector('.vf-git-branche'), w = l.querySelector('.vf-git-wt');
  return { ellipseB: b.scrollWidth > b.clientWidth, ellipseW: w.scrollWidth > w.clientWidth, titre: l.title, largeur: l.getBoundingClientRect().width }; })()`), (v) => !!v && v.titre.includes(longW), { max: 10000 });
out.longs = out.longs || { titre: '' };
out.longs.complet = out.longs.titre.includes(longB) && out.longs.titre.includes(longW);
// H3.4 : l'événement met la ligne à jour
await evt('vf-git:entete', { etat: 'ok', depot: 'depot', branche: 'autre' });
out.evt = await attendreEtStabiliser(() => s.ev(`(() => ({ texte: ${ligne()}.querySelector('.vf-git-branche').textContent, wt: ${ligne()}.querySelector('.vf-git-wt').textContent }))()`), (v) => v.texte === 'autre', { max: 10000 }); // redessin hors de la tâche de l'événement
// H3.4b : signal -> relecture de /api/vf/git/entete avec le jeton ; réponse hors schéma refusée
await s.ev(`window.__vfFetch.reponse = { schema: 'vibeflow/cockpit-git-entete@1', etat: 'ok', depot: 'depot', branche: 'via-signal', worktree: null, detache: false }`);
await signal();
await s.attendre(`${ligne()}.textContent.includes('via-signal')`, 'relecture sur signal');
out.signal = await s.ev(`(() => ({ appels: window.__vfFetch.appels.length, jeton: window.__vfFetch.appels[0].headers['x-vf-cockpit-token'] === window.VF_COCKPIT_SERVER.token && !!window.VF_COCKPIT_SERVER.token }))()`);
await s.ev(`window.__vfFetch.reponse = { schema: 'autre@1', etat: 'ok', depot: 'depot', branche: 'pirate' }`);
await signal();
await s.attendre(`window.__vfFetch.appels.length === 2`, 'second appel');
await s.ev(`new Promise((r) => setTimeout(r, 400))`);
out.horsSchema = await s.ev(`${ligne()}.querySelector('.vf-git-branche').textContent`);
// H3.2b : état indisponible -> texte et ouvreur présent
await evt('vf-git:entete', { etat: 'indisponible', depot: 'depot' });
out.indispo = await attendreEtStabiliser(() => s.ev(`(() => ({ texte: ${ligne()}.querySelector('.vf-git-branche').textContent, ouvreur: !!document.querySelector('#vf-git-ouvreur') }))()`), (v) => /^○/.test(v.texte), { max: 10000 }); // redessin hors de la tâche de l'événement
// H3.5 : clic -> basculer ; etat -> aria-expanded
await s.ev(`window.__bas = []; window.addEventListener('vf-git:basculer', (e) => window.__bas.push(e.detail && e.detail.source))`);
await s.ev(`${ligne()}.click(); (document.querySelector('#vf-git-ouvreur') || { click() {} }).click()`);
out.basculer = await s.ev(`window.__bas`);
await evt('vf-git:etat', { ouvert: true });
out.ouvert = await s.ev(`[${ligne()}.getAttribute('aria-expanded'), (document.querySelector('#vf-git-ouvreur') || { getAttribute() { return null; } }).getAttribute('aria-expanded')]`);
await evt('vf-git:etat', { ouvert: false });
out.ferme = await s.ev(`${ligne()}.getAttribute('aria-expanded')`);
out.aria = await s.ev(`[${ligne()}.getAttribute('aria-controls'), (document.querySelector('#vf-git-ouvreur') || { getAttribute() { return null; } }).getAttribute('aria-controls')]`);
out.errs = await s.ev(`window.__errs`);
return out;
JS
  R="$(cdp "$AUX/h3.js" "$BASE" 2>&1 | tail -1)"
  assert_eq "H3.3 — noms longs : branche tronquée par ellipse" "$(jq_ "$R" 'j.longs.ellipseB' 2>/dev/null)" "true"
  assert_eq "H3.3 — noms longs : worktree tronqué par ellipse" "$(jq_ "$R" 'j.longs.ellipseW' 2>/dev/null)" "true"
  assert_eq "H3.3 — noms longs : texte complet dans title" "$(jq_ "$R" 'j.longs.complet' 2>/dev/null)" "true"
  assert_eq "H3.3 — noms longs : la ligne tient dans 220 px" "$(jq_ "$R" 'j.longs.largeur <= 221' 2>/dev/null)" "true"
  assert_eq "H3.4 — vf-git:entete met la ligne à jour (sans worktree)" "$(jq_ "$R" '[j.evt.texte, j.evt.wt].join("|")' 2>/dev/null)" "autre|"
  assert_eq "H3.4 — vf-git:signal relit l'en-tête avec le jeton" "$(jq_ "$R" '[j.signal.appels, j.signal.jeton].join("|")' 2>/dev/null)" "1|true"
  assert_eq "H3.4 — une réponse hors schéma est refusée" "$(jq_ "$R" 'j.horsSchema' 2>/dev/null)" "via-signal"
  assert_eq "H3.2b — indisponible APRÈS une lecture réussie (PU-G-003) : la dernière branche reste, grisée d'un glyphe (« ○ via-signal »), ouvreur présent ; « Branche indisponible » n'est plus que la première lecture sans valeur connue (H9.2)" "$(jq_ "$R" '[j.indispo.texte, j.indispo.ouvreur].join("|")' 2>/dev/null)" "○ via-signal|true"
  assert_eq "H3.5 — clic sur la ligne et sur l'ouvreur : vf-git:basculer" "$(jq_ "$R" 'j.basculer.join(",")' 2>/dev/null)" "ligne,ouvreur"
  assert_eq "H3.5 — vf-git:etat ouvert : aria-expanded sur les deux" "$(jq_ "$R" 'j.ouvert.join(",")' 2>/dev/null)" "true,true"
  assert_eq "H3.5 — vf-git:etat fermé : aria-expanded false" "$(jq_ "$R" 'j.ferme' 2>/dev/null)" "false"
  assert_eq "H3.5 — aria-controls = vf-git-tiroir (ligne et ouvreur)" "$(jq_ "$R" 'j.aria.join(",")' 2>/dev/null)" "vf-git-tiroir,vf-git-tiroir"
  assert_eq "H3.x — aucune erreur de page pendant ces scénarios" "$(jq_ "$R" 'j.errs.length' 2>/dev/null)" "0"

  echo "=== H4 — ouvreur mobile et masquage de la seconde ligne ==="
  cat > "$AUX/h4.js" <<'JS'
const [base] = ARGS;
await s.naviguer(base + '/');
await s.attendre(`document.readyState === 'complete' && !!document.querySelector('.vf-git-ligne')`, 'seconde ligne');
const res = {};
for (const w of [375, 700, 768, 999, 1000, 1100, 1279, 1280, 1440]) {
  await s.send('Emulation.setDeviceMetricsOverride', { width: w, height: 800, deviceScaleFactor: 1, mobile: false });
  res[w] = await s.stable(`(() => { const l = document.querySelector('.vf-git-ligne'), o = document.querySelector('#vf-git-ouvreur'), h = document.querySelector('header');
    const r = o ? o.getBoundingClientRect() : { width: 0, height: 0 };
    return { ligneVisible: getComputedStyle(l).display !== 'none' && l.getBoundingClientRect().width > 0, ouvreurVisible: !!o && getComputedStyle(o).display !== 'none' && r.width > 0,
      w: Math.round(r.width), h: Math.round(r.height), debord: h.scrollWidth > h.clientWidth + 1, premier: o ? o.parentElement.firstElementChild === o && o.parentElement.classList.contains('hr') : false,
      rangees: h.getBoundingClientRect().height > 80 ? 2 : 1,
      hors: [...document.querySelectorAll('header .hr > *')].filter((e) => e.getClientRects().length).filter((e) => e.getBoundingClientRect().right > innerWidth + 0.5).length,
      chevauche: (() => { const k = [...document.querySelectorAll('header .hr > *')].filter((e) => e.getClientRects().length).map((e) => e.getBoundingClientRect()); let n = 0;
        for (let i = 0; i < k.length; i++) for (let j = i + 1; j < k.length; j++) if (k[i].left < k[j].right - 0.5 && k[j].left < k[i].right - 0.5 && k[i].top < k[j].bottom - 0.5 && k[j].top < k[i].bottom - 0.5) n++; return n; })() }; })()`, 'mesure à ' + w);
}
// téléphone (≤ 700 px) : l'ouvreur quitte la rangée et vit dans le menu « ⋯ » (02-vf-telephone.js, P70-D-01) ; l'entrée relaie le clic
await s.send('Emulation.setDeviceMetricsOverride', { width: 375, height: 800, deviceScaleFactor: 1, mobile: false });
await s.attendre(`!!document.querySelector('#vf-plus') && getComputedStyle(document.querySelector('#vf-plus')).display !== 'none'`, 'bouton ⋯');
await s.ev(`window.__bas = []; window.addEventListener('vf-git:basculer', (e) => window.__bas.push(e.detail && e.detail.source)); document.querySelector('#vf-plus').click()`);
res.menu = await s.stable(`(() => ({ entrees: [...document.querySelectorAll('#vf-plus-menu [role="menuitem"]')].map((e) => e.textContent.trim()) }))()`, 'menu ouvert');
await s.ev(`[...document.querySelectorAll('#vf-plus-menu [role="menuitem"]')].find((e) => e.textContent.trim() === 'Historique Git').click()`);
res.menu.basculer = await s.ev(`window.__bas`);
return res;
JS
  R="$(cdp "$AUX/h4.js" "$BASE" 2>&1 | tail -1)"
  for w in 768 999 1000 1100 1279; do
    assert_eq "H4.1 — ${w} px : ligne masquée, ouvreur 44 × 44 en tête de .hr (P78-D-34, icône de 701 à 1279 px)" "$(jq_ "$R" "[j['$w'].ligneVisible, j['$w'].ouvreurVisible, j['$w'].w, j['$w'].h, j['$w'].premier].join('|')" 2>/dev/null)" "false|true|44|44|true"
  done
  for w in 375 700; do
    assert_eq "H4.1 — ${w} px (téléphone) : ligne masquée, ouvreur absent de la rangée" "$(jq_ "$R" "[j['$w'].ligneVisible, j['$w'].ouvreurVisible].join('|')" 2>/dev/null)" "false|false"
  done
  assert_eq "H4.1 — téléphone : l'ouvreur est une entrée du menu « ⋯ » et son clic émet vf-git:basculer" "$(jq_ "$R" '[j.menu.entrees.includes("Historique Git"), j.menu.basculer.join(",")].join("|")' 2>/dev/null)" "true|ouvreur"
  for w in 1280 1440; do
    assert_eq "H4.1 — ${w} px : ligne visible, ouvreur caché (P78-D-34, seconde ligne dès 1280 px)" "$(jq_ "$R" "[j['$w'].ligneVisible, j['$w'].ouvreurVisible].join('|')" 2>/dev/null)" "true|false"
  done
  assert_eq "H4.1 — aucun débordement horizontal de l'en-tête (largeurs mesurées)" "$(jq_ "$R" 'Object.values(j).filter((m) => m.debord).length' 2>/dev/null)" "0"
  for w in 1000 1100 1279 1280 1440; do
    assert_eq "H4.1 — ${w} px : une seule rangée, aucun bouton hors fenêtre ni superposé dans .hr" "$(jq_ "$R" "[j['$w'].rangees, j['$w'].hors, j['$w'].chevauche].join('|')" 2>/dev/null)" "1|0|0"
  done
  stop_srv

  echo "=== H3.1 — branche détachée ==="
  WTD="$WORK/wt-d"; $GIT -C "$DEPOT" worktree add -q --detach "$WTD" >/dev/null 2>&1
  SHA7="$($GIT -C "$WTD" rev-parse --short=7 HEAD)"
  build_serve "$WTD"; BASE="http://127.0.0.1:$PORT"
  cat > "$AUX/h31.js" <<'JS'
const [base] = ARGS;
await s.naviguer(base + '/');
await s.attendre(`document.readyState === 'complete' && !!document.querySelector('.vf-git-ligne')`, 'seconde ligne');
return await s.ev(`(() => { const l = document.querySelector('.vf-git-ligne'); return { texte: l.querySelector('.vf-git-branche').textContent + l.querySelector('.vf-git-wt').textContent, detache: l.classList.contains('vf-git-detache'), couleur: getComputedStyle(l).color, aria: l.getAttribute('aria-label') }; })()`);
JS
  R="$(cdp "$AUX/h31.js" "$BASE" 2>&1 | tail -1)"
  assert_eq "H3.1 — la ligne dit « HEAD détaché · <sha7> »" "$(jq_ "$R" 'j.texte.replace(/ · worktree .*/, "")' 2>/dev/null)" "HEAD détaché · $SHA7"
  assert_eq "H3.1 — marquée détachée (classe ; la couleur reste neutre, voir H7.11)" "$(jq_ "$R" 'j.detache' 2>/dev/null)" "true"
  stop_srv

  echo "=== H5 — dégradation sans git, texte venu de git rendu en texte ==="
  cat > "$AUX/struct.js" <<'JS'
const [base] = ARGS;
await s.naviguer(base + '/');
await s.attendre(`document.readyState === 'complete' && !!document.querySelector('#proj-name') && !!window.VibeFlow`, 'page rendue');
await s.ev(`new Promise((r) => setTimeout(r, 600))`);
return await s.ev(`(() => ({ struct: [...document.querySelectorAll('header, header *')].map((e) => e.tagName + '#' + e.id + '.' + (typeof e.className === 'string' ? e.className : '')).join('\\n'),
  nom: document.querySelector('#proj-name').textContent, ligne: !!document.querySelector('.vf-git-ligne'), ouvreur: !!document.querySelector('#vf-git-ouvreur'), bloc: !!document.querySelector('.vf-nom'),
  errs: window.__errs, texteLigne: document.querySelector('.vf-git-ligne') ? document.querySelector('.vf-git-ligne .vf-git-branche').textContent + document.querySelector('.vf-git-ligne .vf-git-wt').textContent : null,
  svgEntete: document.querySelectorAll('header svg').length, scripts: document.querySelectorAll('header script').length, alerte: window.__alerte }))()`);
JS
  # témoin : le même lab construit avec une copie du module privée de ui/76-vf-git-entete.js
  M76="$(mkmod sans76)"; rm -f "$M76/../skills/cockpit-moteur/assets/ui/76-vf-git-entete.js"
  NOGIT="$WORK/hors-depot"; mk_lab "$NOGIT"
  NOGIT_T="$WORK/hors-depot-temoin"; mk_lab "$NOGIT_T"
  build_serve "$NOGIT_T" "$M76"; RT="$(cdp "$AUX/struct.js" "http://127.0.0.1:$PORT" 2>&1 | tail -1)"; stop_srv
  build_serve "$NOGIT"; RN="$(cdp "$AUX/struct.js" "http://127.0.0.1:$PORT" 2>&1 | tail -1)"; stop_srv
  assert_eq "H5.1 — témoin positif : le témoin est construit sans le fichier 76" "$(ls "$M76/../skills/cockpit-moteur/assets/ui/" | grep -c '^76-')" "0"
  assert_eq "H5.1 — lab hors dépôt : ni .vf-git-ligne, ni #vf-git-ouvreur, ni .vf-nom" "$(jq_ "$RN" '[j.ligne, j.ouvreur, j.bloc].join("|")' 2>/dev/null)" "false|false|false"
  assert_eq "H5.1 — 0 erreur console" "$(jq_ "$RN" 'j.errs.length' 2>/dev/null)" "0"
  jq_ "$RN" 'j.struct' > "$WORK/struct-nogit.txt" 2>/dev/null; jq_ "$RT" 'j.struct' > "$WORK/struct-temoin.txt" 2>/dev/null
  assert_eq "H5.1 — structure de l'en-tête identique au témoin sans le fichier 76 (cmp)" "$(cmp -s "$WORK/struct-nogit.txt" "$WORK/struct-temoin.txt" && [ -s "$WORK/struct-temoin.txt" ] && echo identique || echo différente)" "identique"
  assert_eq "H5.1 — le nom est celui du dossier du lab (à défaut de dépôt)" "$(jq_ "$RN" 'j.nom' 2>/dev/null)" "hors-depot"

  # git introuvable : DEVELOPER_DIR invalide fait échouer le shim de /usr/bin/git (macOS) ; ailleurs le cas n'est pas masquable
  if ! env PATH=/nonexistent DEVELOPER_DIR=/nonexistent /usr/bin/git --version >/dev/null 2>&1; then
    NOPATH="$WORK/depot-sans-git"; mk_lab "$NOPATH"; $GIT -C "$NOPATH" init -q -b main && $GIT -C "$NOPATH" add -A && $GIT -C "$NOPATH" commit -q -m init
    ENVX="PATH=/nonexistent DEVELOPER_DIR=/nonexistent" build_serve "$NOPATH"; RP="$(cdp "$AUX/struct.js" "http://127.0.0.1:$PORT" 2>&1 | tail -1)"; stop_srv
    assert_eq "H5.1b — PATH sans git : ni ligne, ni ouvreur, ni .vf-nom, 0 erreur" "$(jq_ "$RP" '[j.ligne, j.ouvreur, j.bloc, j.errs.length].join("|")' 2>/dev/null)" "false|false|false|0"
  else skip "H5.1b" "git ne peut pas être masqué sur ce poste"; fi

  # H5.2 : nom de branche hostile, vrai dépôt
  HOST='<svg/onload=alert(1)>'
  HX="$WORK/depot-hostile"; mk_lab "$HX"; $GIT -C "$HX" init -q -b "$HOST" && $GIT -C "$HX" add -A && $GIT -C "$HX" commit -q -m init
  build_serve "$HX"; RH="$(cdp "$AUX/struct.js" "http://127.0.0.1:$PORT" 2>&1 | tail -1)"; stop_srv
  build_serve "$DEPOT"; RB="$(cdp "$AUX/struct.js" "http://127.0.0.1:$PORT" 2>&1 | tail -1)"; stop_srv
  assert_eq "H5.2 — témoin positif : la branche hostile est bien lue par git" "$(jq_ "$RH" 'j.texteLigne' 2>/dev/null)" "$HOST"
  assert_eq "H5.2 — aucun svg ni script neuf dans l'en-tête, aucune alerte" "$(jq_ "$RH" 'JSON.stringify([j.svgEntete, j.scripts, j.alerte])' 2>/dev/null)" "$(jq_ "$RB" 'JSON.stringify([j.svgEntete, j.scripts, j.alerte])' 2>/dev/null)"

  echo "=== H6 — bloc de vue racine, retrait de « Repositories » ==="
  cat > "$AUX/h6.js" <<'JS'
const [base, page] = ARGS;
const { stabiliser, attendreValeur, attendreEtStabiliser, positionPosee } = await import(process.env.VF_CS); // aides communes (chrome-session.mjs)
await s.naviguer(base + page);
await s.attendre(`document.readyState === 'complete' && !!document.querySelector('#context h1') && !!window.VibeFlow`, 'bloc de vue rendu');
return await stabiliser(() => s.ev(`(() => { const c = document.querySelector('#context'), G = window.VibeFlow.graph;
  return { k: c.querySelector('.k').textContent, h1: c.querySelector('h1').textContent, p: (c.querySelector('p') || {}).textContent || '', cls: c.querySelector('h1').className,
    nomProjet: String(G.project.name || '').replace(/ — (Projet|Équipe)$/, ''), resume: G.project.summary,
    sections: [...document.querySelectorAll('#panel h3')].map((h) => h.textContent), depots: document.querySelectorAll('#panel .rp').length }; })()`), { max: 10000 }); // mesure posée (deux relevés identiques), plus de délai fixe
JS
  ENVS="VF_COCKPIT_SCRIPTS_DIR=$WORK/locks" build_serve "$WT"; BASE="http://127.0.0.1:$PORT"
  R="$(cdp "$AUX/h6.js" "$BASE" / 2>&1 | tail -1)"
  assert_eq "H6.1 — Code : surtitre = Code" "$(jq_ "$R" 'j.k' 2>/dev/null)" "Code"
  assert_eq "H6.1 — Code : titre = Le code, branche feat/x" "$(jq_ "$R" 'j.h1' 2>/dev/null)" "Le code, branche feat/x"
  assert_eq "H6.1 — Code : sous-titre = nombre, puis « lus dans le dépôt. »" "$(jq_ "$R" '/^[0-9]+ .*lus dans le dépôt\.$/.test(j.p) ? "ok" : j.p' 2>/dev/null)" "ok"
  assert_eq "H6.3 — Code : le titre ne répète ni le nom du projet ni celui du dépôt, classe vf-ctx-titre" "$(jq_ "$R" '[j.h1.includes(j.nomProjet), j.h1.includes("depot"), /vf-ctx-titre/.test(j.cls)].join("|")' 2>/dev/null)" "false|false|true"
  assert_eq "H6.5 — témoin positif : graph.json garde la donnée repos" "$(node -e "console.log(JSON.parse(require('fs').readFileSync('$OUT/graph.json','utf8')).meta.repos.length > 0)")" "true"
  assert_eq "H6.5 — témoin positif : le panneau d'ensemble est rendu (des sections)" "$(jq_ "$R" 'j.sections.length > 0' 2>/dev/null)" "true"
  assert_eq "H6.5 — aucun titre « Repositories » ni « Dépôts » dans le panneau, aucune ligne « branche @ sha »" "$(jq_ "$R" '[j.sections.filter((t) => /^(Repositories|Dépôts)/.test(t)).length, j.depots].join("|")' 2>/dev/null)" "0|0"
  R="$(cdp "$AUX/h6.js" "$BASE" /project.html 2>&1 | tail -1)"
  assert_eq "H6.2 — Projet : surtitre, titre « Jalon <jalon> », sous-titre = phases faites (le titre n'y est plus répété, voir H7.9)" "$(jq_ "$R" '[j.k, j.h1, j.p].join("|")' 2>/dev/null)" "Projet|Jalon vibeflow-test|1 phase faite sur 2."
  assert_eq "H6.3 — Projet : le titre ne répète pas le nom du projet" "$(jq_ "$R" '[j.h1.includes(j.nomProjet), /vf-ctx-titre/.test(j.cls)].join("|")' 2>/dev/null)" "false|true"
  R="$(cdp "$AUX/h6.js" "$BASE" /equipe.html 2>&1 | tail -1)"
  assert_eq "H6.2 — Équipe sans mission : « Aucune mission en cours », « L'équipe est au repos. »" "$(jq_ "$R" '[j.k, j.h1, j.p].join("|")' 2>/dev/null)" "Équipe|Aucune mission en cours|L'équipe est au repos."
  mkdir -p "$WT/.planning/missions"; printf '{"nodes":[{"id":"a","step":"s","deps":[],"status":"running"}]}\n' > "$WT/.planning/missions/MISSION-x.dag.json"
  for _ in $(seq 1 40); do R="$(cdp "$AUX/h6.js" "$BASE" /equipe.html 2>&1 | tail -1)"; [ "$(jq_ "$R" 'j.h1' 2>/dev/null)" = "Mission : x" ] && break; sleep 0.5; done
  assert_eq "H6.2 — Équipe avec une mission en cours : « Mission : x »" "$(jq_ "$R" 'j.h1' 2>/dev/null)" "Mission : x"
  printf '{"nodes":[{"id":"a","step":"s","deps":[],"status":"running"}]}\n' > "$WT/.planning/missions/MISSION-y.dag.json"
  for _ in $(seq 1 40); do R="$(cdp "$AUX/h6.js" "$BASE" /equipe.html 2>&1 | tail -1)"; [ "$(jq_ "$R" 'j.h1' 2>/dev/null)" = "2 missions en cours" ] && break; sleep 0.5; done
  assert_eq "H6.2 — Équipe avec deux missions : « 2 missions en cours »" "$(jq_ "$R" 'j.h1' 2>/dev/null)" "2 missions en cours"
  assert_eq "H6.2 — PU-G-166 : sous le titre des missions, les agents sont nommés et comptés à part (« Agents : … actif · … en attente · … terminé »), jamais « actifs » seul" "$(jq_ "$R" 'j.p' 2>/dev/null)" "Agents : 0 actif · 0 en attente · 0 terminé depuis moins de 24 h."
  cat > "$AUX/h64.js" <<'JS'
const [base] = ARGS;
const { stabiliser, attendreValeur, attendreEtStabiliser, positionPosee } = await import(process.env.VF_CS); // aides communes (chrome-session.mjs)
await s.naviguer(base + '/project.html');
await s.attendre(`document.readyState === 'complete' && !!document.querySelector('#context h1') && !!window.VibeFlow`, 'page Projet');
const lire0 = () => s.ev(`(() => ({ k: document.querySelector('#context .k').textContent, h1: document.querySelector('#context h1').textContent, cls: document.querySelector('#context h1').className }))()`);
const lire = () => stabiliser(lire0, { max: 10000 }); // relevé posé (le bloc est réécrit après l'arrivée de l'en-tête git)
const racine = await lire();
const noeud = await s.ev(`(() => { const n = window.VibeFlow.graph.nodes.find((x) => x.kind === 'phase') || window.VibeFlow.graph.nodes[0]; window.VibeFlow.go('n:' + n.id); return { id: n.id, label: n.label }; })()`);
await s.attendre(`document.querySelector('#context h1').textContent === ${JSON.stringify(noeud.label)}`, 'sous-vue du nœud');
const dedans = await lire();
await s.ev(`window.VibeFlow.go('root')`);
await s.attendre(`document.querySelector('#context h1').textContent === ${JSON.stringify(racine.h1)}`, 'retour à la racine');
return { racine, noeud, dedans, retour: await lire() };
JS
  R="$(cdp "$AUX/h64.js" "$BASE" 2>&1 | tail -1)"
  assert_eq "H6.4 — dans un nœud : le bloc est celui du viewer (nom du nœud, sans classe vf-ctx-titre)" "$(jq_ "$R" '[j.dedans.h1 === j.noeud.label, /vf-ctx-titre/.test(j.dedans.cls), j.dedans.k !== "Projet"].join("|")' 2>/dev/null)" "true|false|true"
  assert_eq "H6.4 — retour à la racine : le bloc réécrit" "$(jq_ "$R" '[j.retour.k, j.retour.h1 === j.racine.h1, /vf-ctx-titre/.test(j.retour.cls)].join("|")' 2>/dev/null)" "Projet|true|true"
  stop_srv
  build_serve "$NOGIT"; R="$(cdp "$AUX/h6.js" "http://127.0.0.1:$PORT" / 2>&1 | tail -1)"; stop_srv
  assert_eq "H6.1 — Code sans git : « Le code du projet », « … lus dans le dossier. »" "$(jq_ "$R" '[j.k, j.h1, /^[0-9]+ .*lus dans le dossier\.$/.test(j.p)].join("|")' 2>/dev/null)" "Code|Le code du projet|true"

  echo "=== H7 — correction design de la critique fraîche (78-04 : F1, F5, F6, F8, F9, F11, F13 ; F3 est dans H4) ==="
  PRETH7="document.readyState === 'complete' && !!document.querySelector('#proj-name') && !!window.VibeFlow"
  # F1 : un seul nom, celui du dépôt principal, dans tout le cockpit (panneau compris), sans suffixe ; le titre de l'onglet garde le nom du dossier du lab (inchangé)
  cat > "$AUX/h7-nom.js" <<'JS'
const [base, page] = ARGS;
const { stabiliser, attendreValeur, attendreEtStabiliser, positionPosee } = await import(process.env.VF_CS); // aides communes (chrome-session.mjs)
await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
await s.naviguer(base + page);
await s.attendre(`document.readyState === 'complete' && !!document.querySelector('#proj-name') && !!window.VibeFlow && !!document.querySelector('#panel .pt')`, 'page et panneau rendus');
return await stabiliser(() => s.ev(`(() => { const G = window.VibeFlow.graph, T = G.meta.vfTab, p = document.querySelector('#panel');
  return { nom: document.querySelector('#proj-name').textContent, pt: [...p.querySelectorAll('.pt')].map((e) => e.textContent), panneauWt: /wt-a/.test((() => { const c = p.cloneNode(true); c.querySelectorAll('.vf-cmd').forEach((e) => e.remove()); return c.textContent; })()), /* hors la commande de correctif du panneau Format, qui cite le chemin absolu du lab (PU-G-153) ; le titre et les en-têtes restent jugés */ suffixe: / — (Projet|Équipe)/.test(p.innerText),
    titre: document.title, attendu: T === 'equipe' ? 'Équipe · ' + G.meta.rootName : G.meta.rootName + ' — ' + (T === 'project' ? 'Projet' : 'Code') }; })()`), { max: 10000 }); // mesure posée (deux relevés identiques), plus de délai fixe
JS
  ENVS="VF_COCKPIT_SCRIPTS_DIR=$WORK/locks" build_serve "$WT"; BASE="http://127.0.0.1:$PORT"
  for pg in / /project.html /equipe.html; do
    R="$(cdp "$AUX/h7-nom.js" "$BASE" "$pg" 2>&1 | tail -1)"
    assert_eq "H7.1 — $pg (lab dans un worktree wt-a) : le panneau dit « depot », sans « wt-a » ni suffixe « — Projet » / « — Équipe »" "$(jq_ "$R" '[j.nom, j.pt.join("+"), j.panneauWt, j.suffixe].join("|")' 2>/dev/null)" "depot|depot|false|false"
    assert_eq "H7.1 — $pg : le titre de l'onglet garde sa forme (nom du dossier du lab, R6.1 inchangé)" "$(jq_ "$R" 'j.titre === j.attendu ? "inchangé" : j.titre + " ≠ " + j.attendu' 2>/dev/null)" "inchangé"
  done
  # F6, F8, F11 : couleurs et anneau de focus de la seconde ligne
  cat > "$AUX/h7-ligne.js" <<'JS'
const [base] = ARGS;
const { stabiliser, attendreValeur, attendreEtStabiliser, positionPosee } = await import(process.env.VF_CS); // aides communes (chrome-session.mjs)
await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
await s.naviguer(base + '/');
await s.attendre(`document.readyState === 'complete' && !!document.querySelector('.vf-git-ligne') && getComputedStyle(document.querySelector('.vf-git-ligne')).display !== 'none'`, 'seconde ligne visible');
const out = {};
const evt = (nom, d) => s.ev(`window.dispatchEvent(new CustomEvent('${nom}', { detail: ${JSON.stringify(d)} }))`);
const mesure = `(() => { const rgb = (c) => c.match(/[\\d.]+/g).slice(0, 3).map(Number), lum = ([r, g, b]) => { const f = (v) => { v /= 255; return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); }; return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b); };
  const l = document.querySelector('.vf-git-ligne'), a = lum(rgb(getComputedStyle(l).color)), b = lum(rgb(getComputedStyle(document.body).backgroundColor)), h = Math.max(a, b), c = Math.min(a, b);
  const t = document.createElement('i'); t.style.color = 'var(--text-3)'; document.body.appendChild(t); const neutre = getComputedStyle(t).color; t.remove();
  return { ratio: (h + 0.05) / (c + 0.05), couleur: getComputedStyle(l).color, neutre, bgOpaque: !/rgba\\(.*, 0\\)$/.test(getComputedStyle(document.body).backgroundColor) }; })()`;
// F6 : « Branche indisponible », deux thèmes
const texteLigne = () => s.ev(`(document.querySelector('.vf-git-ligne') || {}).textContent || ''`);
await s.attendre(`performance.getEntriesByType('resource').some((e) => e.name.includes('/api/vf/git/entete'))`, 'lecture du chargement terminée'); // sa réponse réelle, tardive sous charge, écraserait sinon les événements simulés
await stabiliser(texteLigne, { max: 10000 });
await evt('vf-git:entete', { etat: 'indisponible', depot: 'depot' });
await attendreValeur(texteLigne, (v) => /indisponible/.test(v), { max: 10000 }); // la ligne se redessine après l'événement : on mesure la ligne postérieure à lui
out.indispo = {};
for (const t of ['dark', 'light']) { await s.ev(`document.documentElement.setAttribute('data-theme', '${t}')`); out.indispo[t] = await stabiliser(() => s.ev(mesure), { max: 10000 }); }
// F11 : HEAD détaché, texte neutre
await evt('vf-git:entete', { etat: 'ok', depot: 'depot', branche: null, detache: true, sha7: 'abc1234', worktree: null });
await attendreValeur(texteLigne, (v) => /abc1234/.test(v), { max: 10000 }); // ligne « HEAD détaché · abc1234 » rendue avant toute mesure
out.detache = {};
for (const t of ['dark', 'light']) { await s.ev(`document.documentElement.setAttribute('data-theme', '${t}')`); out.detache[t] = await stabiliser(() => s.ev(mesure), { max: 10000 }); }
// F8 : anneau de focus au clavier
await evt('vf-git:entete', { etat: 'ok', depot: 'depot', branche: 'feat/x', detache: false, sha7: null, worktree: null });
await attendreValeur(texteLigne, (v) => /feat\/x/.test(v), { max: 10000 }); // ligne redessinée avant le focus et la mesure de l'anneau
await s.ev(`document.querySelector('#vf-git-ligne').focus()`);
await s.send('Input.dispatchKeyEvent', { type: 'keyDown', key: 'Shift', code: 'ShiftLeft' }); await s.send('Input.dispatchKeyEvent', { type: 'keyUp', key: 'Shift', code: 'ShiftLeft' });
await s.ev(`document.activeElement.blur(); document.querySelector('#vf-git-ligne').focus()`);
out.anneau = await stabiliser(() => s.ev(`(() => { const l = document.querySelector('#vf-git-ligne'), n = document.querySelector('#proj-name'), cs = getComputedStyle(l), e = parseFloat(cs.outlineOffset) + parseFloat(cs.outlineWidth), r = l.getBoundingClientRect(), m = n.getBoundingClientRect();
  const boite = { l: r.left - e, t: r.top - e, r: r.right + e, b: r.bottom + e }, x = Math.min(boite.r, m.right) - Math.max(boite.l, m.left), y = Math.min(boite.b, m.bottom) - Math.max(boite.t, m.top);
  return { focusVisible: l.matches(':focus-visible'), style: cs.outlineStyle, aire: Math.max(0, x) * Math.max(0, y) }; })()`), { max: 10000 });
return out;
JS
  R="$(cdp "$AUX/h7-ligne.js" "$BASE" 2>&1 | tail -1)"
  assert_eq "H7.6 — « Branche indisponible » : contraste ≥ 4,5:1 dans les deux thèmes (fond du corps opaque)" "$(jq_ "$R" '[Math.min(j.indispo.dark.ratio, j.indispo.light.ratio) >= 4.5, j.indispo.dark.bgOpaque, j.indispo.light.bgOpaque].join("|")' 2>/dev/null)" "true|true|true"
  assert_eq "H7.11 — HEAD détaché : texte neutre (même couleur que var(--text-3)) dans les deux thèmes" "$(jq_ "$R" '[j.detache.dark.couleur === j.detache.dark.neutre, j.detache.light.couleur === j.detache.light.neutre].join("|")' 2>/dev/null)" "true|true"
  assert_eq "H7.8 — anneau de focus : témoin :focus-visible vrai et contour tracé" "$(jq_ "$R" '[j.anneau.focusVisible, j.anneau.style].join("|")' 2>/dev/null)" "true|solid"
  assert_eq "H7.8 — anneau de focus de la seconde ligne : aucune intersection avec la boîte du nom (aire en px²)" "$(jq_ "$R" 'j.anneau.aire' 2>/dev/null)" "0"
  # F5 : même seuil de passage sur deux rangées avec et sans git (701 à 1000 px). Depuis la coque étroite (menu « ⋯ » dès 999 px, fil d'Ariane entier) l'en-tête racine tient
  # sur une rangée à toute largeur : le repli ne se mesure plus à la racine mais dans la vue d'un fichier (fil d'Ariane long), où il existe encore. Les deux labs portent
  # le MÊME nom de dossier (« depot ») : un nom plus long avancerait le repli de lui-même et fausserait la comparaison.
  cat > "$AUX/h7-seuil.js" <<'JS'
const [base, vue] = ARGS;
await s.naviguer(base + '/' + (vue || ''));
await s.attendre(`document.readyState === 'complete' && !!document.querySelector('#proj-name') && !!window.VibeFlow`, 'page rendue');
const res = [];
for (let w = 700; w <= 1000; w += 10) {
  await s.send('Emulation.setDeviceMetricsOverride', { width: w, height: 800, deviceScaleFactor: 1, mobile: false });
  res.push([w, (await s.stable(`document.querySelector('header').getBoundingClientRect().height > 80 ? 2 : 1`, 'rangées à ' + w))]);
}
return res;
JS
  NOG7="$WORK/hors-depot-7/depot"; mk_lab "$NOG7"; VUE7="#v=f%3Asrc%2Futil.js"
  stop_srv; build_serve "$NOG7"; RS0="$(cdp "$AUX/h7-seuil.js" "http://127.0.0.1:$PORT" 2>&1 | tail -1)"; RD0="$(cdp "$AUX/h7-seuil.js" "http://127.0.0.1:$PORT" "$VUE7" 2>&1 | tail -1)"; stop_srv
  ENVS="VF_COCKPIT_SCRIPTS_DIR=$WORK/locks" build_serve "$WT"; RS1="$(cdp "$AUX/h7-seuil.js" "http://127.0.0.1:$PORT" 2>&1 | tail -1)"; RD1="$(cdp "$AUX/h7-seuil.js" "http://127.0.0.1:$PORT" "$VUE7" 2>&1 | tail -1)"
  assert_eq "H7.5 — témoin : le lab sans git passe d'une rangée double à une rangée simple dans la plage mesurée (vue d'un fichier : le fil d'Ariane long replie encore l'en-tête)" "$(jq_ "$RD0" 'j.some((m) => m[1] === 2) && j.some((m) => m[1] === 1) ? "deux régimes" : "un seul : " + JSON.stringify(j)' 2>/dev/null)" "deux régimes"
  assert_eq "H7.5 — de 700 à 1000 px, l'en-tête racine passe sur les mêmes rangées avec et sans git (une rangée partout depuis la coque étroite)" "$(jq_ "$RS1" 'j.map((m) => m.join(":")).join(" ")' 2>/dev/null)" "$(jq_ "$RS0" 'j.map((m) => m.join(":")).join(" ")' 2>/dev/null)"
  assert_eq "H7.5b — de 700 à 1000 px, dans la vue d'un fichier, l'en-tête passe sur deux rangées aux mêmes largeurs avec et sans git" "$(jq_ "$RD1" 'j.map((m) => m.join(":")).join(" ")' 2>/dev/null)" "$(jq_ "$RD0" 'j.map((m) => m.join(":")).join(" ")' 2>/dev/null)"
  # F13 : le bloc de vue Code ne se coupe qu'après « / » ou « - » (ou une espace), jamais en plein mot ; branche longue, 768 px
  WTL="$WORK/wt-long"; $GIT -C "$DEPOT" worktree add -q -b "feat/phase-78-git-cockpit-corrections-de-la-critique-fraiche" "$WTL" >/dev/null 2>&1
  cat > "$AUX/h7-coupure.js" <<'JS'
const [base] = ARGS;
const { stabiliser, attendreValeur, attendreEtStabiliser, positionPosee } = await import(process.env.VF_CS); // aides communes (chrome-session.mjs)
await s.send('Emulation.setDeviceMetricsOverride', { width: 768, height: 900, deviceScaleFactor: 1, mobile: false });
await s.naviguer(base + '/');
await s.attendre(`document.readyState === 'complete' && !!document.querySelector('#context h1') && /feat/.test(document.querySelector('#context h1').textContent)`, 'bloc de vue Code');
return await stabiliser(() => s.ev(`(() => { const h = document.querySelector('#context h1'), box = h.getBoundingClientRect(), w = document.createTreeWalker(h, NodeFilter.SHOW_TEXT), coupes = []; let prev = null, tout = '', lignes = new Set();
  for (let n = w.nextNode(); n; n = w.nextNode()) for (let i = 0; i < n.data.length; i++) {
    const r = document.createRange(); r.setStart(n, i); r.setEnd(n, i + 1); const b = r.getBoundingClientRect(); tout += n.data[i];
    if (!b.height || b.top >= box.bottom - 1) { prev = null; continue; } // hors du cadre (ligne écrêtée) ou sans boîte
    lignes.add(Math.round(b.top));
    if (prev !== null && b.top > prev.top + 2) coupes.push({ avant: tout[tout.length - 2], apres: n.data[i] });
    prev = { top: b.top }; }
  return { texte: h.textContent, lignes: lignes.size, coupes, enPleinMot: coupes.filter((c) => !/[\\/\\- ]/.test(c.avant)).map((c) => c.avant + '|' + c.apres), wbr: h.querySelectorAll('wbr').length }; })()`), { max: 10000 }); // mesure posée (deux relevés identiques), plus de délai fixe
JS
  stop_srv; build_serve "$WTL"; R="$(cdp "$AUX/h7-coupure.js" "http://127.0.0.1:$PORT" 2>&1 | tail -1)"; stop_srv
  assert_eq "H7.13 — témoin : le titre du bloc de vue Code passe bien sur deux lignes à 768 px (au moins une coupure mesurée)" "$(jq_ "$R" 'j.lignes >= 2 && j.coupes.length >= 1 ? "oui" : "non : " + j.lignes + " ligne(s)"' 2>/dev/null)" "oui"
  assert_eq "H7.13 — aucune coupure en plein mot dans le titre du bloc de vue (coupures hors « / », « - », espace)" "$(jq_ "$R" 'j.enPleinMot.join(",")' 2>/dev/null)" ""
  # PU-G-042 : à 390 px, « integration/cockpit-final » se coupe sur « / », jamais sur le trait d'union ; PU-G-193 : le titre porte une définition constante (title), jamais le nom de branche
  DI="$WORK/depot-int"; mk_lab "$DI"; $GIT -C "$DI" init -q -b "integration/cockpit-final" && $GIT -C "$DI" add -A && $GIT -C "$DI" commit -q -m init
  cat > "$AUX/h7-coupure390.js" <<'JS'
const [base, largeur] = ARGS;
const { stabiliser, attendreValeur, attendreEtStabiliser, positionPosee } = await import(process.env.VF_CS); // aides communes (chrome-session.mjs)
await s.send('Emulation.setDeviceMetricsOverride', { width: Number(largeur), height: 900, deviceScaleFactor: 1, mobile: false });
await s.naviguer(base + '/');
await s.attendre(`document.readyState === 'complete' && !!document.querySelector('#context h1') && /integration|svg/.test(document.querySelector('#context h1').textContent)`, 'bloc de vue Code');
return await stabiliser(() => s.ev(`(() => { const h = document.querySelector('#context h1'), box = h.getBoundingClientRect(), w = document.createTreeWalker(h, NodeFilter.SHOW_TEXT), coupes = []; let prev = null, tout = '';
  for (let n = w.nextNode(); n; n = w.nextNode()) for (let i = 0; i < n.data.length; i++) {
    const r = document.createRange(); r.setStart(n, i); r.setEnd(n, i + 1); const b = r.getBoundingClientRect(); tout += n.data[i];
    if (!b.height || b.top >= box.bottom - 1) { prev = null; continue; }
    if (prev !== null && b.top > prev.top + 2) coupes.push(tout[tout.length - 2]);
    prev = { top: b.top }; }
  return { texte: h.textContent, coupes, enfants: [...new Set([...h.children].map((e) => e.tagName))].sort().join(','), svg: h.querySelector('svg') !== null, title: h.getAttribute('title') }; })()`), { max: 10000 }); // mesure posée (deux relevés identiques), plus de délai fixe
JS
  stop_srv; build_serve "$DI"; RI="$(cdp "$AUX/h7-coupure390.js" "http://127.0.0.1:$PORT" 390 2>&1 | tail -1)"; stop_srv
  assert_eq "H7.14 — PU-G-042 : à 390 px le titre « Le code, branche integration/cockpit-final » passe sur deux lignes, coupé sur « / » et jamais sur « - »" "$(jq_ "$RI" '[j.texte, [...new Set(j.coupes)].join("")].join("|")' 2>/dev/null)" "Le code, branche integration/cockpit-final|/"
  MCO="$(mkmod mcoupure)"
  mutate "$MCO/../skills/cockpit-moteur/assets/ui/76-vf-git-entete.js" "display: inline-block;" "display: inline;" || echo "  ❌ FAIL — M-COUPURE : mutation impossible" >&2
  build_serve "$DI" "$MCO"; RMC="$(cdp "$AUX/h7-coupure390.js" "http://127.0.0.1:$PORT" 390 2>&1 | tail -1)"; stop_srv
  assert_eq "M-COUPURE — rougit H7.14 (sans bloc insécable, le titre se recoupe sur le trait d'union comme avant)" "$(jq_ "$RMC" '[...new Set(j.coupes)].join("") === "/" ? "vert" : "rouge"' 2>/dev/null)" "rouge"
  stop_srv; build_serve "$HX"; RHX="$(cdp "$AUX/h7-coupure390.js" "http://127.0.0.1:$PORT" 1440 2>&1 | tail -1)"; stop_srv
  assert_eq "H7.15 — branche hostile : le titre l'écrit en texte (aucun svg, seulement des WBR) et son title est la définition constante, sans le nom" "$(jq_ "$RHX" '[j.texte.includes("<svg/onload=alert(1)>"), j.svg, j.enfants, j.title.includes("svg"), j.title.startsWith("Branche : une ligne de travail")].join("|")' 2>/dev/null)" "true|false|WBR|false|true"
  # F9 : bloc de vue Projet, sous-titre qui résume la vue sans répéter le titre
  P97="$WORK/depot-f9"; mk_lab "$P97"; printf -- '---\nstatus: executing\nmilestone: vibeflow-test\ncurrent_phase: 2\n---\n# State\n' > "$P97/.planning/STATE.md"
  $GIT -C "$P97" init -q -b main && $GIT -C "$P97" add -A && $GIT -C "$P97" commit -q -m init
  build_serve "$P97"; R="$(cdp "$AUX/h6.js" "http://127.0.0.1:$PORT" /project.html 2>&1 | tail -1)"; stop_srv
  assert_eq "H7.9 — Projet : le sous-titre ne contient ni le titre ni le nom du jalon" "$(jq_ "$R" '[j.p.includes(j.h1), j.p.includes("vibeflow-test")].join("|")' 2>/dev/null)" "false|false"
  assert_eq "H7.9 — Projet : le sous-titre résume la vue (« Phase N en cours, k phases faites sur n. »)" "$(jq_ "$R" 'j.p' 2>/dev/null)" "Phase 2 en cours, 1 phase faite sur 2."

  echo "=== H9 — PU-G-003 : une lecture « indisponible » n'efface ni la branche ni l'ouvreur ==="
  cat > "$AUX/h9.js" <<'JS'
const [base, mode] = ARGS;
const { stabiliser, attendreValeur, attendreEtStabiliser, positionPosee } = await import(process.env.VF_CS); // aides communes (chrome-session.mjs)
if (mode === 'premiere') await s.send('Page.addScriptToEvaluateOnNewDocument', { source: `window.__vfFetch.reponse = { schema: 'vibeflow/cockpit-git-entete@1', etat: 'indisponible', depot: 'depot', branche: null, worktree: null, detache: false, sha7: null }` }); // la lecture du chargement dit « indisponible » aussi : jamais de valeur connue
await s.naviguer(base + '/');
await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
await s.attendre(`document.readyState === 'complete' && !!document.querySelector('.vf-git-ligne') && getComputedStyle(document.querySelector('.vf-git-ligne')).display !== 'none'`, 'seconde ligne visible');
const out = {};
const L = `document.querySelector('.vf-git-ligne')`;
if (mode === 'connue') await s.attendre(`performance.getEntriesByType('resource').some((e) => e.name.includes('/api/vf/git/entete'))`, 'lecture du chargement terminée'); // sa réponse réelle, tardive sous charge, écraserait sinon la simulation
else { await attendreValeur(() => s.ev(`window.__vfFetch.appels.length`), (n) => n >= 1, { max: 10000 }); await stabiliser(() => s.ev(`${L}.querySelector('.vf-git-branche').textContent`), { max: 10000 }); } // la lecture du chargement (simulée) est faite et appliquée avant la simulation
const signal = () => s.ev(`document.dispatchEvent(new CustomEvent('vf-git:signal', { detail: { sig: 'abc' } }))`);
const lecture = async (rep) => { // une lecture du serveur (réponse simulée) ; rend l'état de la page une fois la réponse appliquée
  const n = await s.ev(`window.__vfFetch.appels.length`);
  await s.ev(`window.__vfFetch.reponse = ${JSON.stringify(Object.assign({ schema: 'vibeflow/cockpit-git-entete@1', depot: 'depot', branche: null, worktree: null, detache: false, sha7: null }, rep))}`);
  await signal();
  await s.attendre(`window.__vfFetch.appels.length === ${n + 1}`, 'lecture faite');
  // la réponse s'applique après l'appel du mock : on attend la valeur postérieure (branche de la réponse, ligne masquée sur « absent »), puis on la lit posée
  const lire = () => s.ev(`(() => { const l = ${L}, o = document.querySelector('#vf-git-ouvreur'), cs = getComputedStyle(l), t = document.createElement('i'); t.style.color = 'var(--text-3)'; document.body.appendChild(t); const neutre = getComputedStyle(t).color; t.remove();
    return { branche: l.querySelector('.vf-git-branche').textContent, wt: l.querySelector('.vf-git-wt').textContent, etat: l.querySelector('.vf-git-ligne-etat').textContent, ligneCachee: l.hidden || cs.display === 'none',
      ouvreurCache: !o || o.hidden, dataGit: document.querySelector('header').hasAttribute('data-vf-git'), titre: l.title, aria: l.getAttribute('aria-label'), largeur: l.getBoundingClientRect().width,
      neutre: cs.color === neutre, halo: cs.boxShadow !== 'none' || cs.borderTopWidth !== '0px' || cs.backgroundColor !== 'rgba(0, 0, 0, 0)' }; })()`);
  return attendreEtStabiliser(lire, (v) => rep.etat === 'ok' ? v.branche.includes(rep.branche) : rep.etat === 'absent' ? v.ligneCachee : /indisponible/.test(v.branche) || /^○/.test(v.branche), { max: 10000 }); // « indisponible » : « Branche indisponible » (aucune valeur connue) ou « ○ <dernière branche> » (non confirmée) — jamais l'état d'avant la réponse
};
if (mode === 'connue') {
  out.avant = await lecture({ etat: 'ok', branche: 'feat/memoire', worktree: 'wt-m' });
  out.muet = await lecture({ etat: 'indisponible' });
  out.encore = await lecture({ etat: 'indisponible' });
  out.revenue = await lecture({ etat: 'ok', branche: 'autre', worktree: null });
  out.absent = await lecture({ etat: 'absent' });
  out.apresAbsent = await lecture({ etat: 'indisponible' });
} else {
  out.premiere = await s.ev(`(() => ({ branche: ${L}.querySelector('.vf-git-branche').textContent, etat: ${L}.querySelector('.vf-git-ligne-etat').textContent, cachee: ${L}.hidden, ouvreurCache: document.querySelector('#vf-git-ouvreur').hidden }))()`);
  out.muet = await lecture({ etat: 'indisponible' });
  out.ok = await lecture({ etat: 'ok', branche: 'revenue', worktree: null });
}
out.errs = await s.ev(`window.__errs`);
return out;
JS
  build_serve "$WT"; BASE="http://127.0.0.1:$PORT"
  R9="$(cdp "$AUX/h9.js" "$BASE" connue 2>&1 | tail -1)"; stop_srv
  assert_eq "H9.1 — branche et worktree connus, puis deux lectures « indisponible » : la dernière valeur reste (« ○ feat/memoire », « · worktree wt-m »), le mot « non confirmée » s'ajoute, la ligne et l'ouvreur restent, data-vf-git reste posé" "$(jq_ "$R9" '[j.muet, j.encore].map((x) => [x.branche, x.wt, x.etat, x.ligneCachee, x.ouvreurCache, x.dataGit].join("|")).join(" // ")' 2>/dev/null)" "○ feat/memoire| · worktree wt-m| · non confirmée|false|false|true // ○ feat/memoire| · worktree wt-m| · non confirmée|false|false|true"
  assert_eq "H9.1b — état non confirmé : texte neutre (--text-3), ni halo ni liseré ni fond, la ligne tient dans 220 px ; le nom complet et le mot sont dans le title et le nom accessible" "$(jq_ "$R9" '[j.muet.neutre, j.muet.halo, j.muet.largeur <= 221, j.muet.titre.includes("feat/memoire") && j.muet.titre.includes("non confirmée"), /feat\/memoire.*non confirmée/.test(j.muet.aria)].join("|")' 2>/dev/null)" "true|false|true|true|true"
  assert_eq "H9.1c — la lecture suivante réussie remplace tout (« autre », plus de mot, plus de worktree) ; « absent » (vrai « pas un dépôt ») masque toujours la ligne et l'ouvreur" "$(jq_ "$R9" '[j.revenue.branche, j.revenue.etat, j.revenue.wt, j.absent.ligneCachee, j.absent.ouvreurCache, j.absent.dataGit].join("|")' 2>/dev/null)" "autre|||true|true|false"
  assert_eq "H9.1e — après « absent » puis « indisponible » : aucune ancienne branche ne réapparaît comme non confirmée (« Branche indisponible », sans mot)" "$(jq_ "$R9" '[j.apresAbsent.branche, j.apresAbsent.etat].join("|")' 2>/dev/null)" "Branche indisponible|"
  assert_eq "H9.1d — aucune erreur de page" "$(jq_ "$R9" 'j.errs.length' 2>/dev/null)" "0"
  # première lecture SANS valeur connue : la page servie dit déjà « indisponible » (le HTML posé est réécrit pour le test) -> « Branche indisponible », jamais masquée
  env $ENVX "$NODE" "$SCRIPTS/vf-cockpit-build.mjs" "$WT" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
  OUT="$WT/.vibeflow/cockpit"
  node "$AUX/mut.mjs" "$OUT/index.html" '"vfGit":{"etat":"ok"' '"vfGit":{"etat":"indisponible"' > "$WORK/h92.out" 2>&1 || cat "$WORK/h92.out"
  env $ENVX ${ENVS:-} "$NODE" "$OUT/serve.mjs" --no-open --port "$(libre)" > "$WORK/serve.out" 2>&1 &
  SRV=$!; PIDS+=("$SRV")
  for _ in $(seq 1 100); do [ -s "$OUT/.cache/server.json" ] && break; sleep 0.1; done
  PORT="$(node -e "console.log(JSON.parse(require('fs').readFileSync('$OUT/.cache/server.json','utf8')).port)" 2>/dev/null || echo 0)"; BASE="http://127.0.0.1:$PORT"
  R92="$(cdp "$AUX/h9.js" "$BASE" premiere 2>&1 | tail -1)"; stop_srv
  assert_eq "H9.2 — première lecture sans valeur connue : « Branche indisponible », sans mot ajouté, ligne et ouvreur présents ; la lecture réussie suivante donne la branche" "$(jq_ "$R92" '[j.premiere.branche, j.premiere.etat, j.premiere.cachee, j.premiere.ouvreurCache, j.muet.branche, j.muet.ligneCachee, j.ok.branche].join("|")' 2>/dev/null)" "Branche indisponible||false|false|Branche indisponible|false|revenue"

  echo "=== Mutants ==="
  # M-DEPOT : le nom du dépôt pris de --show-toplevel (le worktree) -> H1.1 et H2.2 rougissent
  MD="$(mkmod mdepot)"
  mutate "$MD/vf-cockpit-git-entete.mjs" "const racine = path.basename(commun) === '.git' ? path.dirname(commun) : commun.replace(/[\\\\/]+\$/, '').replace(/\\.git\$/, '');" "const racine = git('rev-parse', '--show-toplevel') || commun;" || echo "  ❌ FAIL — M-DEPOT : mutation impossible" >&2
  RM="$(node "$AUX/entete.mjs" "$MD/vf-cockpit-git-entete.mjs" "$WT" 2>&1 | tail -1)"
  assert_eq "M-DEPOT — rougit H1.1 (le dépôt devient le worktree)" "$(jq_ "$RM" 'j.depot' 2>/dev/null)" "wt-a"
  WTM="$WORK/wt-m"; $GIT -C "$DEPOT" worktree add -q -b feat/m "$WTM" >/dev/null 2>&1
  build_serve "$WTM" "$MD"; RM2="$(cdp "$AUX/h2.js" "http://127.0.0.1:$PORT" / 2>&1 | tail -1)"; stop_srv
  assert_eq "M-DEPOT — rougit H2.2 (#proj-name = le worktree)" "$(jq_ "$RM2" 'j.nom' 2>/dev/null)" "wt-m"
  # M-TEXTE : seconde ligne écrite par innerHTML -> H5.2 rougit (un svg neuf apparaît, l'alerte part)
  MT="$(mkmod mtexte)"
  mutate "$MT/../skills/cockpit-moteur/assets/ui/76-vf-git-entete.js" "spBranche.textContent = texteBranche;" "spBranche.innerHTML = texteBranche;" || echo "  ❌ FAIL — M-TEXTE : mutation impossible" >&2
  HX2="$WORK/depot-hostile2"; mk_lab "$HX2"; $GIT -C "$HX2" init -q -b "$HOST" && $GIT -C "$HX2" add -A && $GIT -C "$HX2" commit -q -m init
  build_serve "$HX2" "$MT"; RMT="$(cdp "$AUX/struct.js" "http://127.0.0.1:$PORT" 2>&1 | tail -1)"; stop_srv
  assert_eq "M-TEXTE — rougit H5.2 (le mutant fabrique un svg dans l'en-tête)" "$(jq_ "$RMT" 'j.svgEntete > 0 && j.texteLigne !== "'"$HOST"'" ? "rouge" : "vert"' 2>/dev/null)" "rouge"
  # M-ABSENT : la ligne est créée même en « absent » -> H5.1 rougit
  MA="$(mkmod mabsent)"
  mutate "$MA/../skills/cockpit-moteur/assets/ui/76-vf-git-entete.js" "if (!V || V.etat === 'absent' || !V.depot) return;" "if (!V || !V.depot) return;" || echo "  ❌ FAIL — M-ABSENT : mutation impossible" >&2
  NOGIT_M="$WORK/hors-depot-mutant"; mk_lab "$NOGIT_M"
  build_serve "$NOGIT_M" "$MA"; RMA="$(cdp "$AUX/struct.js" "http://127.0.0.1:$PORT" 2>&1 | tail -1)"; stop_srv
  assert_eq "M-ABSENT — rougit H5.1 (la ligne et le bloc existent sans git)" "$(jq_ "$RMA" '[j.ligne, j.bloc].join("|")' 2>/dev/null)" "true|true"
  # M-MEMOIRE : la lecture « indisponible » remplace de nouveau la branche connue -> H9.1 rougit
  MM="$(mkmod mmemoire)"
  mutate "$MM/../skills/cockpit-moteur/assets/ui/76-vf-git-entete.js" "const indispo = d.etat === 'indisponible' && !connue;" "const indispo = d.etat === 'indisponible';" || echo "  ❌ FAIL — M-MEMOIRE : mutation impossible" >&2
  build_serve "$WT" "$MM"; RMM="$(cdp "$AUX/h9.js" "http://127.0.0.1:$PORT" connue 2>&1 | tail -1)"; stop_srv
  assert_eq "M-MEMOIRE — rougit H9.1 (la branche connue est écrasée par « Branche indisponible »)" "$(jq_ "$RMM" 'j.muet.branche' 2>/dev/null)" "Branche indisponible"
  # M-MASQUE : une lecture « indisponible » masque de nouveau la ligne et l'ouvreur (comme l'ancien « absent » sur git muet) -> H9.1 rougit
  MK="$(mkmod mmasque)"
  mutate "$MK/../skills/cockpit-moteur/assets/ui/76-vf-git-entete.js" "if (d.etat === 'absent') { connue = null; ligne.hidden = true;" "if (d.etat === 'absent' || d.etat === 'indisponible') { connue = null; ligne.hidden = true;" || echo "  ❌ FAIL — M-MASQUE : mutation impossible" >&2
  build_serve "$WT" "$MK"; RMK="$(cdp "$AUX/h9.js" "http://127.0.0.1:$PORT" connue 2>&1 | tail -1)"; stop_srv
  assert_eq "M-MASQUE — rougit H9.1 (la ligne et l'ouvreur disparaissent sur une lecture non confirmée)" "$(jq_ "$RMK" '[j.muet.ligneCachee, j.muet.ouvreurCache].join("|")' 2>/dev/null)" "true|true"
  # M-REPOS : l'index garde la liste des dépôts (retrait annulé dans une copie du build) -> H6.5 rougit
  MR="$(mkmod mrepos)"
  mutate "$MR/vf-cockpit-build.mjs" "insererGraphe(html, { ...g, meta: { ...g.meta, repos: [] } })" "insererGraphe(html, g)" || echo "  ❌ FAIL — M-REPOS : mutation impossible" >&2
  REPOS="$WORK/depot-repos"; mk_lab "$REPOS"; $GIT -C "$REPOS" init -q -b main && $GIT -C "$REPOS" add -A && $GIT -C "$REPOS" commit -q -m init
  build_serve "$REPOS" "$MR"; RMR="$(cdp "$AUX/h6.js" "http://127.0.0.1:$PORT" / 2>&1 | tail -1)"; stop_srv
  assert_eq "M-REPOS — rougit H6.5 (la liste « Dépôts » ou ses lignes réapparaissent)" "$(jq_ "$RMR" '(j.sections.filter((t) => /^(Repositories|Dépôts)/.test(t)).length + j.depots) > 0 ? "rouge" : "vert"' 2>/dev/null)" "rouge"
  # H8 (78-04, recette G1 à G3) : la page rendue après un `git switch` dit la branche RÉELLE au chargement (une seule lecture de /api/vf/git/entete, jamais une par tick), le bloc de vue Code la cite,
  # le signal les met à jour, et un écart visible et symétrique entoure le point médian de la seconde ligne. Lab jetable avec un vrai worktree : assemblé sur feat/x, puis basculé sur feat/y SANS réassembler.
  DEP8="$WORK/depot8"; WT8="$WORK/wt8"; mk_lab "$DEP8"
  $GIT -C "$DEP8" init -q -b main && $GIT -C "$DEP8" add -A && $GIT -C "$DEP8" commit -q -m init
  $GIT -C "$DEP8" worktree add -q -b feat/x "$WT8" >/dev/null 2>&1
  cat > "$AUX/h8.js" <<'JS'
const [base, page, branche] = ARGS; const out = {};
const { stabiliser, attendreValeur, attendreEtStabiliser, positionPosee } = await import(process.env.VF_CS); // aides communes (chrome-session.mjs)
const pause = (ms) => new Promise((r) => setTimeout(r, ms));
await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
await s.naviguer(base + page);
await s.attendre(`document.readyState === 'complete' && !!document.querySelector('.vf-git-ligne') && getComputedStyle(document.querySelector('.vf-git-ligne')).display !== 'none'`, 'seconde ligne visible');
const lue = () => s.ev(`document.querySelector('.vf-git-branche').textContent`);
const txt = await attendreValeur(lue, (v) => v === branche, { pas: 100, max: 2000 }); // « en moins de 2 s » est l'attendu : borne inchangée
out.ligne = txt;
await pause(500);
out.lectures = await s.ev(`performance.getEntriesByType('resource').filter((e) => e.name.includes('/api/vf/git/entete')).length`);
out.h1 = await s.ev(`(document.querySelector('#context h1') || {}).textContent || null`);
out.ecart = await stabiliser(() => s.ev(`(() => { const b = document.querySelector('.vf-git-branche'), w = document.querySelector('.vf-git-wt'), n = w.firstChild, r = document.createRange();
  const rect = (a, z) => { r.setStart(n, a); r.setEnd(n, z); return r.getBoundingClientRect(); }, txt = n.textContent, i = txt.indexOf('worktree');
  const point = rect(txt.indexOf('·'), txt.indexOf('·') + 1), mot = rect(i, i + 1), B = b.getBoundingClientRect();
  return { texte: txt, avant: Math.round((point.left - B.right) * 10) / 10, apres: Math.round((mot.left - point.right) * 10) / 10 }; })()`), { max: 10000 }); // écart mesuré une fois posé
if (page === '/' && process.env.H8_SIGNAL) {
  (await import('node:child_process')).execFileSync('git', ['-C', process.env.H8_LAB, 'switch', '-q', '-c', process.env.H8_SIGNAL], { stdio: 'ignore' }); // la branche change APRÈS le chargement de la page
  await s.ev(`document.dispatchEvent(new CustomEvent('vf-git:signal', { detail: { sig: 'x' } }))`);
  const h = await attendreValeur(() => s.ev(`document.querySelector('#context h1').textContent`), (v) => !!v && v.includes(process.env.H8_SIGNAL), { pas: 100, max: 2000 });
  out.h1Signal = h; out.ligneSignal = await lue();
}
out.errs = await s.ev(`window.__errs`);
return out;
JS
  build_serve "$WT8"; B8="http://127.0.0.1:$PORT"
  $GIT -C "$WT8" switch -q -c feat/y
  # le serveur a été lancé AVANT le switch : son filet (NET_MS = 5 s, vf-cockpit-live.mjs:148-150) émet un événement `git` au premier tick qui voit le switch, et la page ouverte à ce moment relirait
  # l'en-tête une 2e fois (diagnostic H8.1). On laisse donc le filet absorber le switch AVANT les chargements : attente OBSERVABLE du premier événement `git` du flux direct (borne 15 s = 3 ticks).
  # Sans événement en 15 s, la graine du filet est postérieure au switch (rien à absorber) : on continue, ce que le script dit (« aucun »).
  cat > "$AUX/attendre-git.mjs" <<'JS'
// attendre-git.mjs <port> <jeton> <maxMs> : s'abonne à /api/vf/events, imprime « git » au premier événement `git`, « aucun » à l'échéance, « erreur » si l'abonnement échoue
import http from 'node:http';
const [, , port, jeton, max] = process.argv; let tampon = '';
const fin = (m) => { console.log(m); process.exit(0); };
setTimeout(() => fin('aucun'), Number(max));
http.get({ host: '127.0.0.1', port: Number(port), path: '/api/vf/events?token=' + encodeURIComponent(jeton) }, (r) => { r.on('data', (c) => { tampon += c; if (/^event: git$/m.test(tampon)) fin('git'); }); }).on('error', () => fin('erreur'));
JS
  absorber_filet() { # absorber_filet <étiquette> : après un git switch, attend le premier événement `git` du filet (serveur courant : $OUT, $PORT) ; avertit si rien, FAIL nommé si l'outil d'attente échoue
    local tok g; tok="$(node -e "console.log(JSON.parse(require('fs').readFileSync('$OUT/.cache/server.json','utf8')).token)" 2>/dev/null)"
    g="$(node "$AUX/attendre-git.mjs" "$PORT" "$tok" 15000 2>&1 | tail -1)"
    case "$g" in
      git) echo "     filet [$1] : événement git absorbé" >&2 ;;
      aucun) echo "     ⚠ filet [$1] : aucun événement git en 15 s — graine postérieure au switch (rien à absorber) ou filet muet ; la mesure continue" >&2 ;;
      *) echo "  ❌ FAIL — H8.0 [$1] — l'attente d'absorption du filet a échoué (« $g ») : la mesure qui suit n'est pas fiable" >&2; echo "$1" >> "$WORK/absorption-ratee.txt" ;; # le FAIL est compté une fois, après les mutants (un sous-shell $(…) ne remonte pas FAIL)
    esac
  }
  absorber_filet principal
  for pg in / /project.html /equipe.html; do
    R8="$(cdp "$AUX/h8.js" "$B8" "$pg" feat/y 2>&1 | tail -1)"
    assert_eq "H8.1 — $pg : après un switch sans réassemblage, la seconde ligne dit la branche réelle (feat/y) en moins de 2 s" "$(jq_ "$R8" 'j.ligne' 2>/dev/null)" "feat/y"
    assert_eq "H8.1 — $pg : une seule lecture de /api/vf/git/entete au chargement" "$(jq_ "$R8" 'j.lectures' 2>/dev/null)" "1"
    assert_eq "H8.3 — $pg : écart visible et symétrique autour du point médian (>= 4 px, écart de côté à côté <= 2 px)" "$(jq_ "$R8" '[j.ecart.avant >= 4, Math.abs(j.ecart.avant - j.ecart.apres) <= 2].join("|")' 2>/dev/null)" "true|true"
    case "$pg" in /) assert_eq "H8.2 — Code : le bloc de vue cite la branche réelle (« Le code, branche feat/y »)" "$(jq_ "$R8" 'j.h1' 2>/dev/null)" "Le code, branche feat/y";; esac
  done
  R8="$(H8_LAB="$WT8" H8_SIGNAL=feat/z cdp "$AUX/h8.js" "$B8" / feat/y 2>&1 | tail -1)"
  assert_eq "H8.2 — Code : au signal, le bloc de vue et la seconde ligne suivent la branche (feat/z)" "$(jq_ "$R8" '[j.h1Signal, j.ligneSignal].join("|")' 2>/dev/null)" "Le code, branche feat/z|feat/z"
  assert_eq "H8.x — aucune erreur de page" "$(jq_ "$R8" 'j.errs.length' 2>/dev/null)" "0"
  stop_srv
  # mutants H8 : copie du module mutée, lab neuf assemblé sur feat/x puis basculé sur feat/y (le défaut de chaque mutant ne rougit que SON témoin)
  h8mut() { # h8mut <nom> <ancien> <nouveau> : rend la ligne JSON de h8.js sur / (« {} » si la mutation est impossible)
    local M D W; M="$(mkmod "$1")"; D="$WORK/depot-$1"; W="$WORK/wt-$1"; mk_lab "$D"
    $GIT -C "$D" init -q -b main && $GIT -C "$D" add -A && $GIT -C "$D" commit -q -m init
    $GIT -C "$D" worktree add -q -b feat/x "$W" >/dev/null 2>&1
    mutate "$M/../skills/cockpit-moteur/assets/ui/76-vf-git-entete.js" "$2" "$3" || { echo "  ❌ FAIL — $1 : mutation impossible" >&2; echo '{}'; return; }
    build_serve "$W" "$M"; $GIT -C "$W" switch -q -c feat/y; absorber_filet "$1"
    cdp "$AUX/h8.js" "http://127.0.0.1:$PORT" / feat/y 2>&1 | tail -1; stop_srv
  }
  RM="$(h8mut m-chargement "  relire(); // chargement : la page assemblée peut dater d'avant un \`git switch\`, une seule lecture par chargement
" "")"
  assert_eq "M-CHARGEMENT — rougit H8.1 (sans la lecture au chargement, la seconde ligne garde feat/x et aucune lecture ne part) alors que l'écart du point médian est là" "$(jq_ "$RM" '[j.ligne, j.lectures, j.ecart.avant >= 4].join("|")' 2>/dev/null)" "feat/x|0|true"
  RM="$(h8mut m-double "  relire(); // chargement : la page assemblée peut dater d'avant un \`git switch\`, une seule lecture par chargement
" "  relire(); relire(); // mutant : deux lectures au chargement
")"
  assert_eq "M-DOUBLE-LECTURE — témoin : une DOUBLE lecture au chargement rend H8.1 rouge (obtenu 2 ou plus au lieu de 1) : la mesure sait voir un doublon" "$(jq_ "$RM" 'j.lectures >= 2 ? "rouge" : "vert (lectures=" + j.lectures + ")"' 2>/dev/null)" "rouge"
  RM="$(h8mut m-bloc "    if (change && TAB === 'code') ecrireEtRecadrer(); // le bloc de vue Code cite la branche de la même lecture que la seconde ligne
" "")"
  assert_eq "M-BLOC-VUE — rougit H8.2 (le bloc de vue garde feat/x alors que la seconde ligne dit feat/y)" "$(jq_ "$RM" '[j.ligne, j.h1].join("|")' 2>/dev/null)" "feat/y|Le code, branche feat/x"
  RM="$(h8mut m-ecart "flex: 0 2 auto; white-space: pre; }" "flex: 0 2 auto; }")"
  assert_eq "M-ECART — rougit H8.3 (plus d'écart avant le point médian) alors que la branche est à jour" "$(jq_ "$RM" '[j.ecart.avant >= 4, j.ligne].join("|")' 2>/dev/null)" "false|feat/y"
  [ ! -s "$WORK/absorption-ratee.txt" ] || { echo "  ❌ FAIL — H8.0 — l'attente d'absorption du filet a échoué ($(tr '\n' ' ' < "$WORK/absorption-ratee.txt")) : leurs mesures ne sont pas fiables"; FAIL=$((FAIL+1)); } # FAIL posé dans un sous-shell $(…) ne remonte pas : relayé par fichier
fi

echo "=== H6.6 — la feuille de 76 n'emploie que des variables et des valeurs existantes (P78-D-12) ==="
JET="$HERE_T/css-jetons.mjs"
node "$JET" "$UI/76-vf-git-entete.js" > "$WORK/jetons.out" 2>&1; RCJ=$?
assert_eq "H6.6 — la feuille de 76 : aucune valeur en dur (couleur, espacement, rayon)" "$RCJ $(cat "$WORK/jetons.out" | head -3)" "0 "
# témoins : chaque famille de valeur fautive est refusée, nommée, sur une copie de 76 (jamais le fichier lui-même)
for cas in "padding: 2px 6px;|padding: 5px 6px;|5px" "cursor: pointer;|cursor: pointer; color: #123456;|#123456" "border-radius: 999px;|border-radius: 50%;|50%" "background: transparent;|background: rgba(1, 2, 3, .5);|rgba(" "margin-left: -6px;|margin-left: -7px;|-7px"; do
  ANC="${cas%%|*}"; RESTE="${cas#*|}"; NOUV="${RESTE%%|*}"; NOM="${RESTE#*|}"
  cp "$UI/76-vf-git-entete.js" "$WORK/76-fautif.js"; mutate "$WORK/76-fautif.js" "$ANC" "$NOUV" || echo "  ❌ FAIL — H6.6 : mutation impossible ($ANC)" >&2
  node "$JET" "$WORK/76-fautif.js" > "$WORK/jetons-fautif.out" 2>&1; RCF=$?
  assert_eq "H6.6 — témoin « $NOM » : refusé (code 1) et nommé" "$RCF $(grep -cF -- "$NOM" "$WORK/jetons-fautif.out")" "1 1"
done

vf_hyg_assert
echo; echo "Résultats : $PASS réussis, $FAIL échoués, $SKIP sautés"
[ "$FAIL" -eq 0 ]
