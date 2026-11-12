#!/usr/bin/env bash
# test-cockpit-git-e2e.sh — la Phase 78 de bout en bout, sur le SERVEUR RÉEL (build, serve, flux SSE, page en Chrome headless) : GITC-01, 02, 04 à 07, 09, 11, 13
# (P78-D-07, 11, 13, 17, 25). Aucune réponse figée, aucun `fetch` remplacé : la page parle au vrai serveur qui lit un vrai dépôt fabriqué ici.
#   MJ mutants de jonction, joués d'abord (chacun doit rougir la section qu'il vise : un mutant sans effet ou rouge pour une autre raison ne compte pas)
#       M-ROUTE   l'accroche `routeGit` retirée du serveur (copie de la sortie)        -> rougit B2
#       M-SIGNAL  le relais de l'événement `git` retiré de la page (copie de la sortie) -> rougit B3
#       M-ECOUTEUR l'écouteur de `vf-git:signal` de l'en-tête remis sur window (le défaut S2) -> rougit B3b (tiroir fermé) seulement
#       M-OUVREUR le nom d'événement `vf-git:basculer` changé dans l'en-tête (copie)    -> rougit B2
#   B1 nom du dépôt sur les trois onglets, seconde ligne · B2 tiroir réel (clic, touche g, graphe = route, détail = route, worktrees = git status)
#   B3 rafraîchissement réel : un commit puis un `git switch` faits PENDANT la séance · B4 lab hors dépôt · B5 lab piégé, GIT_DIR leurre exporté
#   CAPT captures PNG (375, 700, 768, 1000, 1440 px ; clair et sombre ; fermé, ouvert, détail ; Terminal ouvert si `--terminal` se lance) sous ${TMPDIR:-/tmp}/78-captures/ (jamais commitées)
# Les assertions visent des PROPRIÉTÉS (contrats de route, identifiants, lecture seule, flux), jamais un seuil de largeur ni un nom de classe.
# E2E_SECTIONS="MJ B1 …" limite les sections jouées (défaut : toutes). Chrome headless en CDP (SAUTÉ, jamais compté réussi, sans navigateur), ports éphémères, jamais un port fixe.
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; }
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t.test GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t.test
HERE_T="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="$(cd "$HERE_T/.." && pwd)"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; MARQ="$WORK/marques"; PROGS="$WORK/progs"
mkdir -p "$AUX" "$WORK/home" "$MARQ" "$PROGS"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
GIT_REEL="$(command -v git)"
SRV=""; PIDS=()
stop_srv() { [ -n "$SRV" ] && { vf_hyg_stop "$SRV"; }; SRV=""; }
trap 'stop_srv; vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"' EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
. "$HERE_T/socle-serveur.sh"

PASS=0; FAIL=0; SKIP=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
skip() { echo "  ⏭️  SAUTÉ — $1 ($2)"; SKIP=$((SKIP+1)); }
joue() { case " ${E2E_SECTIONS:-MJ B1 B2 B3 B4 B5 CAPT} " in *" $1 "*) return 0 ;; esac; return 1; }

CHROME=""
for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue
  if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
[ -n "${E2E_SANS_NAVIGATEUR:-}" ] && CHROME=""
echo "navigateur : ${CHROME:-aucun (les sections Chrome sont SAUTÉES, jamais comptées réussies)}"
SIG_MS="${E2E_SIGNAL_MS:-10000}" # P78-D-15 : le filet est de 5 s, la page relit après une rafale de 300 ms ; « en moins de 10 s »

cat > "$AUX/json.mjs" <<'JS'
const j = JSON.parse(process.argv[2]);
const v = new Function('j', 'return (' + process.argv[3] + ')')(j);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/cdp-run.mjs" <<'JS'
// cdp-run.mjs <chrome> <scenario.js> [args…] : joue le corps asynchrone du scénario avec (s, ARGS) après avoir posé les crochets de pre.js (VF_PRE) ; une ligne JSON
import fs from 'node:fs';
const { executer } = await import(process.env.VF_CS);
const [, , chrome, fichier, ...ARGS] = process.argv;
const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor;
const corps = new AsyncFunction('s', 'ARGS', fs.readFileSync(fichier, 'utf8'));
const PRE = process.env.VF_PRE ? fs.readFileSync(process.env.VF_PRE, 'utf8') : '';
await executer(chrome, async (s) => {
  await s.send('Browser.grantPermissions', { permissions: ['clipboardReadWrite', 'clipboardSanitizedWrite'] }).catch(() => {});
  if (PRE) await s.send('Page.addScriptToEvaluateOnNewDocument', { source: PRE });
  return corps(s, ARGS);
}, { csp: true });
JS
cat > "$AUX/mut.mjs" <<'JS'
// mut.mjs <fichier> <ancien> <nouveau> : remplace UNE occurrence ; échoue (code 1) si l'ancien texte est absent ou multiple (un mutant mort ne prouve rien)
import fs from 'node:fs';
const [, , f, a, b] = process.argv; const t = fs.readFileSync(f, 'utf8');
if (!t.includes(a) || t.split(a).length !== 2) { console.error('mutation impossible : motif absent ou multiple : ' + a); process.exit(1); }
fs.writeFileSync(f, t.replace(a, () => b));
JS
cat > "$AUX/empreinte.mjs" <<'JS'
// empreinte.mjs <dossier .git> <sortie> : chemin, taille et date de chaque entrée (lstat), triés ; deux empreintes se comparent par cmp -s
import fs from 'node:fs'; import path from 'node:path';
const [, , racine, sortie] = process.argv; const l = [];
const marche = (d) => { for (const e of fs.readdirSync(d).sort()) { const p = path.join(d, e); const st = fs.lstatSync(p); l.push(`${path.relative(racine, p)} ${st.size} ${st.mtimeMs}`); if (st.isDirectory()) marche(p); } };
marche(racine); fs.writeFileSync(sortie, l.join('\n') + '\n'); console.log(l.length);
JS
export VF_CS="$HERE_T/chrome-session.mjs"; export VF_CDP_ECHEANCE_MS="${VF_CDP_ECHEANCE_MS:-25000}" VF_CDP_TAG="$VF_HYG_TAG"
cdp() { local r; r="$(node "$AUX/cdp-run.mjs" "$CHROME" "$@" 2>&1 | tail -1)"; case "$r" in *'"erreur"'*) echo "     (scénario interrompu : $r)" >&2;; esac; printf '%s\n' "$r"; }
jq_() { node "$AUX/json.mjs" "$1" "$2"; }
mutate() { node "$AUX/mut.mjs" "$@"; }

# aides de scénario recopiées en tête de chaque corps (concaténées par aide.js)
cat > "$AUX/aide.js" <<'JS'
const pause = (ms) => new Promise((r) => setTimeout(r, ms));
const fenetre = (w, h = 900) => s.send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: false });
const KV = { g: [71, 'KeyG', 'g'] };
const touche = async (key) => { const [vk, code, text] = KV[key]; for (const type of ['keyDown', 'keyUp']) await s.send('Input.dispatchKeyEvent', { type, key, code, windowsVirtualKeyCode: vk, ...(type === 'keyDown' && text ? { text } : {}) }); };
const OUVERT = `(() => { const t = document.querySelector('#vf-git-tiroir'); return !!t && !t.hidden && t.getBoundingClientRect().width > 0 && getComputedStyle(t).display !== 'none'; })()`;
const VISIBLE = (sel) => `(() => { const e = document.querySelector('${sel}'); return !!e && !e.hidden && e.getClientRects().length > 0 && getComputedStyle(e).display !== 'none' && getComputedStyle(e).visibility !== 'hidden'; })()`;
const att = async (out, nom, expr, ms) => { const t0 = Date.now(); try { await s.attendre(expr, nom, ms || 8000); out.ok[nom] = Date.now() - t0; return true; } catch { out.ok[nom] = false; return false; } };
JS
# crochets posés avant la page : erreurs de page seulement (aucun fetch remplacé)
cat > "$AUX/pre.js" <<'JS'
window.__errs = [];
addEventListener('error', (e) => window.__errs.push(String(e.message)));
addEventListener('unhandledrejection', (e) => window.__errs.push('rejet ' + String(e.reason)));
{ const ce = console.error; console.error = (...a) => { window.__errs.push(a.map(String).join(' ')); ce.apply(console, a); }; }
window.__alerte = 0; window.alert = () => { window.__alerte++; };
JS
export VF_PRE="$AUX/pre.js"

NODE="$(command -v node)"; ENVX=""
GT() { git -c user.email=t@t.test -c user.name=t "$@"; }
mk_lab() { # $1 = dossier : lab GSD minimal
  mkdir -p "$1/src" "$1/.planning/phases/01-x"
  printf 'export const util = () => 1;\n' > "$1/src/util.js"
  printf -- '- [x] **Phase 1: Socle** - premier jet\n- [ ] **Phase 2: Suite** - deuxième jet\n' > "$1/.planning/ROADMAP.md"
  printf -- '---\nstatus: executing\nmilestone: vibeflow-test\n---\n# State\n' > "$1/.planning/STATE.md"
  printf '<objective>Faire le socle</objective>\n' > "$1/.planning/phases/01-x/01-01-PLAN.md"; echo ok > "$1/.planning/phases/01-x/01-01-SUMMARY.md"
}
mk_depot() { # $1 = racine : `depot` (principal, main), `wt-a` (feat/x, le LAB), `wt-b` (feat/b, sale : 1 modifié, 2 non suivis), un merge, un tag, un stash, deux auteurs
  local R="$1" D="$1/depot"; mkdir -p "$R"
  mk_lab "$D"; GT -C "$D" init -q -b main; printf '.vibeflow\n' >> "$D/.git/info/exclude"
  GT -C "$D" add -A; GT -C "$D" commit -q -m "init"
  GT -C "$D" commit -q --allow-empty -m "second"
  GT -C "$D" switch -q -c feat/y; printf 'y\n' > "$D/y.txt"; GT -C "$D" add y.txt; GT -C "$D" commit -q -m "y1"
  GT -C "$D" switch -q main; GT -C "$D" merge -q --no-ff feat/y -m "fusion de feat/y"
  GT -C "$D" tag v1
  printf 'm\n' > "$D/main.txt"; GT -C "$D" add main.txt; GIT_AUTHOR_NAME=Bob GT -C "$D" commit -q -m "après la fusion"
  GT -C "$D" worktree add -q -b feat/x "$R/wt-a" >/dev/null 2>&1
  local i; for i in 1 2; do echo "export const v$i = $i;" >> "$R/wt-a/src/util.js"; GT -C "$R/wt-a" commit -q -am "x$i"; done
  echo "export const v3 = 3;" >> "$R/wt-a/src/util.js"; printf 'neuf\n' > "$R/wt-a/src/neuf.js"; GT -C "$R/wt-a" add -A
  GIT_AUTHOR_NAME=Alice GT -C "$R/wt-a" commit -q -m "sujet-de-tete" -m "corps ligne 2"
  GT -C "$D" worktree add -q -b feat/b "$R/wt-b" >/dev/null 2>&1
  echo "// sale" >> "$R/wt-b/src/util.js"; printf 'u1\n' > "$R/wt-b/u1.txt"; printf 'u2\n' > "$R/wt-b/u2.txt"
  echo "stash" >> "$D/main.txt"; GT -C "$D" stash push -q -m "mon stash"
}
build_lab() { env $ENVX "$NODE" "$SCRIPTS/vf-cockpit-build.mjs" "$1" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"; }
serve_out() { # $1 = dossier de sortie (contient serve.mjs), $2.. = options de serve.mjs ; $ENVX, $ENVS ; pose PORT et SRV
  local o="$1"; shift; rm -f "$o/.cache/server.json"
  COCKPIT_MODULE="${MUT_MOD:-}" COCKPIT_SORTIE="$o" COCKPIT_LOG="$WORK/serve.out" cockpit_lancer "$o/../.." $ENVX ${ENVS:-} "$@" || true   # MUT_MOD : copie du module muté (79-06), vide = le module du dépôt
  SRV="$VF_PID"
  PORT="$VF_PORT"
}

# --- B2 + B3 : un seul parcours, une seule session, sur le vrai serveur ---
cat "$AUX/aide.js" - > "$AUX/parcours.js" <<'JS'
const [base, lab, wtbMod, wtbNon] = ARGS;
const cp = await import('node:child_process');
const git = (...a) => cp.execFileSync('git', ['-c', 'user.email=t@t.test', '-c', 'user.name=t', '-C', lab, ...a], { encoding: 'utf8' });
const out = { ok: {} };
const reponse = (u) => `(async () => { const r = await fetch('${u}', { headers: { 'x-vf-cockpit-token': window.VF_COCKPIT_SERVER.token } }); let j = null; try { j = await r.json(); } catch {} return { status: r.status, j }; })()`;
await fenetre(1440); await s.naviguer(base + '/');
await s.attendre(`document.readyState === 'complete' && !!window.VibeFlow && !!document.querySelector('#vf-git-ligne')`, 'page et seconde ligne');
// la route réelle, lue par la page avec son jeton
out.api = await s.ev(`(async () => { const a = await ${reponse('/api/vf/git')}; const j = a.j || {};
  return { status: a.status, schema: j.schema, etat: j.etat, n: (j.rangees || []).length, h: j.rangees && j.rangees[0] && j.rangees[0].h, h7: j.rangees && j.rangees[0] && j.rangees[0].h7, entete: j.entete }; })()`);
// B2 : ouverture au clic, graphe = route
await s.ev(`document.querySelector('#vf-git-ligne').click()`);
await att(out, 'ouvert-clic', OUVERT);
const rangees = `document.querySelectorAll('#vf-git-tiroir li[role=option]').length`;
await att(out, 'rangees', `${rangees} > 0`);
out.rangees = await s.ev(rangees);
out.premier = await s.ev(`(document.querySelector('#vf-git-tiroir li[role=option]') || { getAttribute: () => '' }).getAttribute('aria-label')`);
out.expanded = await s.ev(`document.querySelector('#vf-git-ligne').getAttribute('aria-expanded')`);
// détail d'un commit : la page lit la route réelle, le détail porte le message et les fichiers de la route
await s.ev(`window.__h = ${JSON.stringify(out.api.h || '')}`);
out.det = await s.ev(`(async () => { const r = await fetch('/api/vf/git/commit?sha=' + window.__h, { headers: { 'x-vf-cockpit-token': window.VF_COCKPIT_SERVER.token } }); let j = null; try { j = await r.json(); } catch {} return { status: r.status, j }; })()`);
await s.ev(`document.querySelector('#vf-git-tiroir li[role=option]').click()`);
await att(out, 'detail', `(() => { const r = document.querySelector('#vf-git-tiroir [role=region][aria-label^="Détail du commit"]'); return !!r && r.textContent.length > 0 && !/Lecture du détail/.test(r.textContent); })()`);
out.detail = await s.ev(`(() => { const r = document.querySelector('#vf-git-tiroir [role=region][aria-label^="Détail du commit"]'); return r ? r.textContent : ''; })()`);
// worktrees : les pastilles disent ce que dit git status (la route réelle ET le dépôt)
out.wt = await s.ev(reponse('/api/vf/git/worktrees'));
await att(out, 'pastilles', `/propre/.test(document.querySelector('#vf-git-tiroir').textContent) && /non suivi/.test(document.querySelector('#vf-git-tiroir').textContent)`);
out.tiroirTexte = await s.ev(`document.querySelector('#vf-git-tiroir') ? document.querySelector('#vf-git-tiroir').textContent : ''`);
// touche g : ferme puis rouvre (aucun champ n'a le focus)
await s.ev(`document.activeElement && document.activeElement.blur && document.activeElement.blur(); document.body.focus()`);
await touche('g'); await att(out, 'ferme-g', `!(${OUVERT})`);
await touche('g'); await att(out, 'ouvert-g', OUVERT);
// B3 : sélection posée sur la 2e rangée, puis un commit fait PENDANT la séance
await att(out, 'rangees-b3', `${rangees} > 1`);
await s.ev(`document.querySelectorAll('#vf-git-tiroir li[role=option]')[1].click()`);
await att(out, 'selection', `document.querySelectorAll('#vf-git-tiroir li[role=option][aria-selected=true]').length === 1`);
out.sel7 = await s.ev(`document.querySelector('#vf-git-tiroir li[role=option][aria-selected=true]').getAttribute('aria-label').split(',')[0]`);
out.avant = await s.ev(rangees);
git('commit', '--allow-empty', '-q', '-m', 'nouveau commit e2e');
await att(out, 'rangee-neuve', `(document.querySelector('#vf-git-tiroir li[role=option]') || { getAttribute: () => '' }).getAttribute('aria-label').indexOf('nouveau commit e2e') >= 0`, Number(process.env.E2E_SIGNAL_MS) || 10000);
out.apres = await s.ev(rangees);
out.selConservee = await s.ev(`(() => { const l = [...document.querySelectorAll('#vf-git-tiroir li[role=option]')].find((x) => (x.getAttribute('aria-label') || '').split(',')[0] === ${JSON.stringify(out.sel7)}); return !!l && l.getAttribute('aria-selected') === 'true'; })()`);
// un `git switch -c` : la seconde ligne le dit
out.avantLigne = await s.ev(`document.querySelector('#vf-git-ligne').textContent`);
git('switch', '-q', '-c', 'autre');
await att(out, 'ligne-autre', `/autre/.test(document.querySelector('#vf-git-ligne').textContent)`, Number(process.env.E2E_SIGNAL_MS) || 10000);
out.ligne = await s.ev(`document.querySelector('#vf-git-ligne').textContent`);
// B3b (revue S2, P78-D-15) : tiroir FERMÉ, sur le flux réel : un `git switch -c` change la seconde ligne sans que le tiroir ne relise rien (70-vf-live émet sur document, sans bubbles)
await s.ev(`document.activeElement && document.activeElement.blur && document.activeElement.blur(); document.body.focus()`);
await touche('g'); await att(out, 'ferme-b3b', `!(${OUVERT})`);
git('switch', '-q', '-c', 'troisieme');
await att(out, 'ligne-fermee', `/troisieme/.test(document.querySelector('#vf-git-ligne').textContent)`, Number(process.env.E2E_SIGNAL_MS) || 10000);
out.ligneFermee = await s.ev(`document.querySelector('#vf-git-ligne').textContent`);
out.errs = await s.ev(`window.__errs`); out.violations = [...s.violations];
return out;
JS
# vérifie un parcours : ligne « B2 » et « B3 » ; $1 = JSON ; imprime les propriétés fausses de la section (« » si tout est vrai)
faux_b2() { jq_ "$1" '(() => { const f = []; const o = j.ok || {};
  if (j.erreur) f.push("erreur:" + j.erreur);
  if (!j.api || j.api.status !== 200 || j.api.schema !== "vibeflow/cockpit-git@1" || j.api.etat !== "ok") f.push("route /api/vf/git:" + JSON.stringify(j.api && [j.api.status, j.api.schema, j.api.etat]));
  if (o["ouvert-clic"] === false) f.push("tiroir non ouvert au clic");
  if (!j.api || j.rangees !== j.api.n || !(j.rangees > 0)) f.push("rangées " + j.rangees + " != route " + (j.api && j.api.n));
  if (j.api && j.api.h7 && !String(j.premier || "").startsWith(j.api.h7)) f.push("première rangée != route");
  if (o["ferme-g"] === false || o["ouvert-g"] === false) f.push("touche g sans effet");
  return f.join("; "); })()'; }
faux_b3() { jq_ "$1" '(() => { const f = []; const o = j.ok || {};
  if (j.erreur) f.push("erreur:" + j.erreur);
  if (o["rangee-neuve"] === false) f.push("aucune rangée neuve en tête sous " + "'"$SIG_MS"'" + " ms (rangées " + j.avant + " -> " + j.apres + ")");
  if (o["rangee-neuve"] !== false && !j.selConservee) f.push("sélection perdue");
  if (o["ligne-autre"] === false) f.push("seconde ligne inchangée : " + j.ligne);
  if (o["ferme-b3b"] === false) f.push("tiroir non fermé avant B3b");
  if (o["ligne-fermee"] === false) f.push("seconde ligne inchangée, tiroir fermé : " + j.ligneFermee);
  return f.join("; "); })()'; }

# --- jonction : sortie copiée DANS le lab (racine = deux niveaux au-dessus), mutant posé, parcours rejoué ---
MUT_OUT=""; MUT_MOD=""
mutant_jonction() { # $1 = nom, $2 = fichier(s) à muter, $3 = ancien, $4 = nouveau, $5 = faux_b2|faux_b3 ; rend les mesures dans RM. Un fichier de code (vf-cockpit-*.mjs) est muté dans une COPIE du module (MUT_MOD) ; une page, dans la copie de la sortie (MUT_OUT, des données)
  local nom="$1" R="$WORK/mj-$1"; mk_depot "$R"; build_lab "$R/wt-a"
  local o="$R/wt-a/.vibeflow/cockpit"; MUT_OUT="$o"; MUT_MOD=""   # 79-06 : serve.mjs exige --sortie=<lab>/.vibeflow/cockpit ; un dépôt neuf par mutant (mk_depot), la sortie de ce lab est donc déjà sa propre copie
  local f; for f in $2; do
    case "$f" in
      vf-cockpit-*) [ -n "$MUT_MOD" ] || { rm -rf "$WORK/mod-$nom"; MUT_MOD="$(cockpit_module_copie "$WORK/mod-$nom")" || { RM='{"erreur":"copie du module impossible"}'; MUT_MOD=""; return; }; }; mutate "$MUT_MOD/scripts/$f" "$3" "$4" ;;
      *) mutate "$o/$f" "$3" "$4" ;;
    esac || { RM='{"erreur":"mutation impossible"}'; MUT_MOD=""; return; }
  done
  serve_out "$o"; RM="$(cdp "$AUX/parcours.js" "http://127.0.0.1:$PORT" "$R/wt-a" 1 2)"; stop_srv; MUT_MOD=""
}

if joue MJ; then
echo "=== MJ — mutants de jonction (chacun rougit sa section, pour la bonne raison) ==="
if [ -z "$CHROME" ]; then skip "MJ" "pas de navigateur"; else
  mutant_jonction M-ROUTE "vf-cockpit-server.mjs" "if (routeGit(req, res, url, { root, json })) return true;" "if (false) return true;" faux_b2
  echo "     M-ROUTE : B2 -> [$(faux_b2 "$RM")]"; echo "     M-ROUTE : mesure ${RM:0:420}"
  assert_eq "M-ROUTE — rougit B2 (la route réelle ne répond plus : 404, aucune rangée) alors que la page, la seconde ligne et le tiroir existent" "$(jq_ "$RM" '[ (j.api||{}).status !== 200, (j.rangees||0) === 0, (j.ok||{})["ouvert-clic"] !== false ].join("|")' 2>/dev/null)" "true|true|true"
  mutant_jonction M-SIGNAL "index.html project.html" "es.addEventListener('git'," "es.addEventListener('git-mort'," faux_b3
  echo "     M-SIGNAL : B3 -> [$(faux_b3 "$RM")]"; echo "     M-SIGNAL : mesure ${RM:0:420}"
  assert_eq "M-SIGNAL — rougit B3 (aucune rangée neuve, la seconde ligne ne bouge pas) alors que B2 est vert sur le même serveur" "$(jq_ "$RM" '[ (j.ok||{})["rangee-neuve"] === false, (j.ok||{})["ligne-autre"] === false ].join("|")' 2>/dev/null)|$(faux_b2 "$RM")" "true|true|"
  mutant_jonction M-ECOUTEUR "index.html project.html" "document.addEventListener('vf-git:signal', () => { // relecture de l'en-tête" "window.addEventListener('vf-git:signal', () => { // relecture de l'en-tête" faux_b3
  echo "     M-ECOUTEUR : B3 -> [$(faux_b3 "$RM")]"; echo "     M-ECOUTEUR : mesure ${RM:0:420}"
  assert_eq "M-ECOUTEUR — rougit B3b (la seconde ligne ne bouge pas tiroir fermé) alors que le tiroir ouvert suit (rangée neuve, ligne « autre »)" "$(jq_ "$RM" '[ (j.ok||{})["ligne-fermee"] === false, (j.ok||{})["rangee-neuve"] !== false, (j.ok||{})["ligne-autre"] !== false ].join("|")' 2>/dev/null)|$(faux_b2 "$RM")" "true|true|true|"
  mutant_jonction M-OUVREUR "index.html project.html" "new CustomEvent('vf-git:basculer'," "new CustomEvent('vf-git:basculer-mort'," faux_b2
  echo "     M-OUVREUR : B2 -> [$(faux_b2 "$RM")]"; echo "     M-OUVREUR : mesure ${RM:0:420}"
  assert_eq "M-OUVREUR — rougit B2 (le clic sur la seconde ligne n'ouvre plus rien) alors que la route répond 200 (le graphe existe côté serveur)" "$(jq_ "$RM" '[ (j.ok||{})["ouvert-clic"] === false, (j.api||{}).status === 200 ].join("|")' 2>/dev/null)" "true|true"
fi
fi

# --- le lab livré, un par section : B1, B2+B3, captures ---
if joue B1 || joue B2 || joue B3 || joue CAPT; then
  if [ -z "$CHROME" ]; then skip "B1, B2, B3, CAPT" "pas de navigateur"; else
    LV="$WORK/livre"; mk_depot "$LV"; build_lab "$LV/wt-a"; OUT="$LV/wt-a/.vibeflow/cockpit"
    # contrôles positifs du dépôt fabriqué (jamais un lab vide)
    NCOMMITS="$(GT -C "$LV/wt-a" rev-list --count HEAD)"; WTB_MOD="$(GT -C "$LV/wt-b" status --porcelain -unormal | grep -c '^ M\|^M ')"; WTB_NON="$(GT -C "$LV/wt-b" status --porcelain -unormal | grep -c '^??')"
    assert_eq "B0 — le dépôt fabriqué : 3 worktrees, un merge, un tag, un stash, wt-b sale (1 modifié, 2 non suivis)" "$(GT -C "$LV/depot" worktree list | wc -l | tr -d ' ')|$(GT -C "$LV/depot" log --merges --oneline | wc -l | tr -d ' ')|$(GT -C "$LV/depot" tag | wc -l | tr -d ' ')|$(GT -C "$LV/depot" stash list | wc -l | tr -d ' ')|$WTB_MOD|$WTB_NON" "3|1|1|1|1|2"
    serve_out "$OUT"; BASE="http://127.0.0.1:$PORT"
    if joue B1; then
      echo "=== B1 — le nom du dépôt sur les trois onglets, la seconde ligne ==="
      cat "$AUX/aide.js" - > "$AUX/b1.js" <<'JS'
const [base, page] = ARGS;
await fenetre(1440); await s.naviguer(base + page);
await s.attendre(`document.readyState === 'complete' && !!document.querySelector('#proj-name') && !!window.VibeFlow && !!document.querySelector('#vf-git-ligne')`, 'page rendue');
return await s.ev(`(() => ({ nom: document.querySelector('#proj-name').textContent, entete: document.querySelector('header').textContent, ligne: document.querySelector('#vf-git-ligne').textContent, visible: ${VISIBLE('#vf-git-ligne')} }))()`);
JS
      for pg in / /project.html /equipe.html; do
        R="$(cdp "$AUX/b1.js" "$BASE" "$pg")"
        assert_eq "B1 — $pg : le titre est le nom du dossier du dépôt principal (depot, pas wt-a), sans suffixe « — Projet » ni « — Équipe »" "$(jq_ "$R" '[j.nom, / — (Projet|Équipe)/.test(j.entete)].join("|")' 2>/dev/null)" "depot|false"
        assert_eq "B1 — $pg : la seconde ligne est visible et dit la branche (feat/x) et le worktree (wt-a)" "$(jq_ "$R" '[j.visible, /feat\/x/.test(j.ligne), /wt-a/.test(j.ligne)].join("|")' 2>/dev/null)" "true|true|true"
      done
    fi
    if joue B2 || joue B3; then
      echo "=== B2 — le tiroir sur le serveur réel : clic, touche g, graphe, détail, worktrees ==="
      R="$(cdp "$AUX/parcours.js" "$BASE" "$LV/wt-a" "$WTB_MOD" "$WTB_NON")"
      echo "     mesure : ${R:0:600}"
      assert_eq "B2.1 — route réelle, tiroir ouvert au clic, rangées du graphe = rangées de la route (même nombre, même premier sha), touche g ferme puis rouvre : aucune propriété fausse" "$(faux_b2 "$R")" ""
      assert_eq "B2.2 — la route sert tout le dépôt fabriqué : $NCOMMITS commits atteignables depuis le worktree au moins, premier sha complet de 40 hexadécimaux" "$(jq_ "$R" '[(j.api||{}).n >= '"$NCOMMITS"', /^[0-9a-f]{40}$/.test((j.api||{}).h||"")].join("|")' 2>/dev/null)" "true|true"
      assert_eq "B2.3 — clic sur la première rangée : le détail porte le message et chaque fichier de la route réelle /api/vf/git/commit, 200" "$(jq_ "$R" '(() => { const c = (j.det||{}).j||{}; const t = j.detail||""; return [(j.det||{}).status, /sujet-de-tete/.test(t), /corps ligne 2/.test(t), (c.fichiers||[]).length >= 2, (c.fichiers||[]).every((f) => t.includes(f.chemin))].join("|"); })()' 2>/dev/null)" "200|true|true|true|true"
      assert_eq "B2.4 — worktrees : la route sert wt-b tel que git status le dit (modifiés, non suivis), wt-a propre" "$(jq_ "$R" '(() => { const w = ((j.wt||{}).j||{}).worktrees||[]; const b = w.find((x) => /wt-b$/.test(x.chemin))||{}, a = w.find((x) => /wt-a$/.test(x.chemin))||{}; return [(j.wt||{}).status, b.modifies, b.nonSuivis, a.propre].join("|"); })()' 2>/dev/null)" "200|$WTB_MOD|$WTB_NON|true"
      assert_eq "B2.5 — les pastilles de la page disent la même chose : « propre », « $WTB_MOD modifié », « $WTB_NON non suivis »" "$(jq_ "$R" '(() => { const t = j.tiroirTexte||""; return [/propre/.test(t), /'"$WTB_MOD"' modifié/.test(t), /'"$WTB_NON"' non suivis/.test(t)].join("|"); })()' 2>/dev/null)" "true|true|true"
      echo "=== B3 — rafraîchissement réel : un commit puis un git switch pendant la séance ==="
      assert_eq "B3.1 — un commit fait dans le lab : une rangée neuve en tête en moins de ${SIG_MS} ms, la sélection conservée (sha7 $(jq_ "$R" 'j.sel7' 2>/dev/null))" "$(faux_b3 "$R")" ""
      assert_eq "B3.2 — témoin : le tiroir comptait $(jq_ "$R" 'j.avant' 2>/dev/null) rangées avant, une de plus après" "$(jq_ "$R" 'j.apres - j.avant' 2>/dev/null)" "1"
      assert_eq "B3.3 — après git switch -c autre, la seconde ligne dit « autre » (elle disait feat/x)" "$(jq_ "$R" '[/autre/.test(j.ligne), /feat\/x/.test(j.avantLigne)].join("|")' 2>/dev/null)" "true|true"
      assert_eq "B3.4 — aucune erreur de page, aucune violation de CSP sur tout le parcours" "$(jq_ "$R" '[(j.errs||[]).length, (j.violations||[]).length].join("|")' 2>/dev/null)" "0|0"
    fi
    stop_srv
  fi
fi

# --- B4 : lab hors dépôt ---
if joue B4; then
echo "=== B4 — lab hors dépôt : ni seconde ligne, ni ouvreur, ni tiroir ==="
if [ -z "$CHROME" ]; then skip "B4" "pas de navigateur"; else
  HD="$WORK/horsdepot"; mk_lab "$HD"
  assert_eq "B4.0 — témoin : le lab n'est dans aucun dépôt git" "$(GT -C "$HD" rev-parse --git-dir >/dev/null 2>&1 && echo dans-un-depot || echo hors-depot)" "hors-depot"
  build_lab "$HD"; serve_out "$HD/.vibeflow/cockpit"; BASE="http://127.0.0.1:$PORT"
  cat "$AUX/aide.js" - > "$AUX/b4.js" <<'JS'
const [base] = ARGS;
await fenetre(1440); await s.naviguer(base + '/');
await s.attendre(`document.readyState === 'complete' && !!document.querySelector('#proj-name') && !!window.VibeFlow`, 'page rendue');
await pause(800); // le temps qu'une lecture d'en-tête aurait eu pour montrer la ligne
const out = {};
out.nom = await s.ev(`document.querySelector('#proj-name').textContent`);
out.ligne = await s.ev(VISIBLE('#vf-git-ligne')); out.ouvreur = await s.ev(VISIBLE('#vf-git-ouvreur'));
await s.ev(`document.body.focus()`); await touche('g'); await pause(600);
out.tiroir = await s.ev(`!!document.querySelector('#vf-git-tiroir') && ${OUVERT}`);
out.routes = await s.ev(`(async () => { const h = { 'x-vf-cockpit-token': window.VF_COCKPIT_SERVER.token }; const o = {}; for (const u of ['/api/vf/git', '/api/vf/git/entete']) { const r = await fetch(u, { headers: h }); const j = await r.json(); o[u] = [r.status, j.etat].join(':'); } return o; })()`);
out.menu = await s.ev(`/Historique Git/.test(document.body.textContent)`);
out.errs = await s.ev(`window.__errs`); out.violations = [...s.violations];
return out;
JS
  R="$(cdp "$AUX/b4.js" "$BASE")"; stop_srv
  assert_eq "B4.1 — la page est rendue (titre = dossier du lab) mais ni seconde ligne ni ouvreur ne sont visibles, g n'ouvre aucun tiroir" "$(jq_ "$R" '[j.nom, j.ligne, j.ouvreur, j.tiroir].join("|")' 2>/dev/null)" "horsdepot|false|false|false"
  assert_eq "B4.2 — les routes répondent « absent » (200), sans erreur" "$(jq_ "$R" 'JSON.stringify(j.routes)' 2>/dev/null)" '{"/api/vf/git":"200:absent","/api/vf/git/entete":"200:absent"}'
  assert_eq "B4.3 — 0 erreur de page, 0 violation de CSP" "$(jq_ "$R" '[(j.errs||[]).length, (j.violations||[]).length].join("|")' 2>/dev/null)" "0|0"
fi
fi

# --- B5 : lab piégé de bout en bout, GIT_DIR leurre exporté pour l'assemblage ET le serveur ---
mk_prog() { printf '#!/bin/sh\necho "$0 $*" >> "%s/%s"\n%s\n' "$MARQ" "$1" "${2:-exit 0}" > "$PROGS/$1.sh"; chmod +x "$PROGS/$1.sh"; }
marque() { if [ -s "$MARQ/$1" ]; then echo posé; else echo absent; fi; }
marques() { ls "$MARQ" | tr '\n' ' ' | sed 's/ *$//'; }
if joue B5; then
echo "=== B5 — lab piégé (filtres, textconv, fsmonitor, GIT_DIR leurre) : aucun programme du dépôt lancé, .git intact ==="
if [ -z "$CHROME" ]; then skip "B5" "pas de navigateur"; else
  mk_prog PROC "exit 1"; mk_prog CLEAN 'cat'; mk_prog TEXTCONV 'cat "$1"'; mk_prog FSM "exit 1"
  P="$WORK/piege"; mk_lab "$P"; "$GIT_REEL" init -q -b main "$P"; P="$(cd "$P" && pwd -P)"; printf '.vibeflow\n' >> "$P/.git/info/exclude"
  printf 'f.txt filter=f\n*.bin diff=bin\n' > "$P/.gitattributes"; printf 'contenu\n' > "$P/f.txt"; printf 'a\0b\n' > "$P/a.bin"
  "$GIT_REEL" -C "$P" add -A && "$GIT_REEL" -C "$P" commit -q -m "premier"
  printf 'a\0c\n' > "$P/a.bin"; "$GIT_REEL" -C "$P" commit -q -am "SUJET-REEL"
  "$GIT_REEL" -C "$P" config filter.f.clean "$PROGS/CLEAN.sh"; "$GIT_REEL" -C "$P" config filter.f.process "$PROGS/PROC.sh"
  "$GIT_REEL" -C "$P" config diff.bin.textconv "$PROGS/TEXTCONV.sh"; "$GIT_REEL" -C "$P" config core.fsmonitor "$PROGS/FSM.sh"
  UNE_MIN="$(date -v-1M +%Y%m%d%H%M 2>/dev/null || date -d '1 minute ago' +%Y%m%d%H%M)"; touch -t "$UNE_MIN" "$P/f.txt"
  L="$WORK/leurre"; "$GIT_REEL" init -q -b main "$L"; "$GIT_REEL" -C "$L" commit -q --allow-empty -m LEURRE; L="$(cd "$L" && pwd -P)"
  rm -f "$MARQ"/*
  # témoin positif : git BRUT sur ce dépôt lance bien les programmes (sinon « aucun marqueur » ne prouverait rien)
  "$GIT_REEL" --no-optional-locks -c core.fsmonitor=false -C "$P" status --porcelain >/dev/null 2>&1; T_STATUS="$(marque PROC)"
  "$GIT_REEL" -C "$P" log -p -1 >/dev/null 2>&1; T_LOG="$(marque TEXTCONV)"
  assert_eq "B5.0 — témoin positif : git brut lance le filtre (status) et le textconv (log -p) du dépôt piégé" "$T_STATUS|$T_LOG" "posé|posé"
  assert_eq "B5.0b — témoin : GIT_DIR=<leurre> détourne git brut (le dépôt lu est le leurre)" "$(GIT_DIR="$L/.git" "$GIT_REEL" -C "$P" log -1 --format=%s)" "LEURRE"
  rm -f "$MARQ"/*
  node "$AUX/empreinte.mjs" "$P/.git" "$WORK/git-avant.txt" >/dev/null
  ENVX="GIT_DIR=$L/.git"; build_lab "$P"; serve_out "$P/.vibeflow/cockpit"; BASE="http://127.0.0.1:$PORT"; ENVX=""
  cat "$AUX/aide.js" - > "$AUX/b5.js" <<'JS'
const [base] = ARGS;
await fenetre(1440); await s.naviguer(base + '/');
await s.attendre(`document.readyState === 'complete' && !!window.VibeFlow && !!document.querySelector('#vf-git-ligne')`, 'page et seconde ligne');
const out = { ok: {} };
out.ligne = await s.ev(`document.querySelector('#vf-git-ligne').textContent`);
await s.ev(`document.querySelector('#vf-git-ligne').click()`);
await att(out, 'ouvert', OUVERT); await att(out, 'rangees', `document.querySelectorAll('#vf-git-tiroir li[role=option]').length > 0`);
out.rangees = await s.ev(`document.querySelectorAll('#vf-git-tiroir li[role=option]').length`);
await s.ev(`document.querySelector('#vf-git-tiroir li[role=option]').click()`);
await att(out, 'detail', `(() => { const r = document.querySelector('#vf-git-tiroir [role=region][aria-label^="Détail du commit"]'); return !!r && r.textContent.length > 0 && !/Lecture du détail/.test(r.textContent); })()`);
out.detail = await s.ev(`(document.querySelector('#vf-git-tiroir [role=region][aria-label^="Détail du commit"]') || { textContent: '' }).textContent`);
await att(out, 'worktrees', `/propre|modifi|non suivi|illisible|indisponible/.test(document.querySelector('#vf-git-tiroir').textContent.split('Worktrees')[1] || '')`);
out.approx = await s.ev(`/approximatif/.test(document.querySelector('#vf-git-tiroir').textContent)`);
out.errs = await s.ev(`window.__errs`);
return out;
JS
  R="$(cdp "$AUX/b5.js" "$BASE")"; stop_srv
  node "$AUX/empreinte.mjs" "$P/.git" "$WORK/git-apres.txt" >/dev/null
  echo "     mesure : ${R:0:400} ; marqueurs posés : [$(marques)]"
  assert_eq "B5.1 — le cockpit assemblé et servi sous GIT_DIR=<leurre> lit le VRAI dépôt : seconde ligne sur main, tiroir ouvert, rangées, détail du commit SUJET-REEL" "$(jq_ "$R" '[/main/.test(j.ligne), (j.ok||{}).ouvert !== false, j.rangees >= 2, /SUJET-REEL/.test(j.detail)].join("|")' 2>/dev/null)" "true|true|true|true"
  assert_eq "B5.2 — aucun programme du dépôt n'a été lancé (filtre, textconv, fsmonitor : dossier des marqueurs vide)" "$(marques)" ""
  assert_eq "B5.3 — l'état des worktrees est lu (le status du dépôt piégé est passé par la route) et dit « approximatif : filtres du dépôt non exécutés »" "$(jq_ "$R" '[(j.ok||{}).worktrees !== false, j.approx].join("|")' 2>/dev/null)" "true|true"
  assert_eq "B5.4 — l'empreinte de .git est identique avant et après la séance (lecture seule : cmp -s)" "$(cmp -s "$WORK/git-avant.txt" "$WORK/git-apres.txt" && echo identique || echo modifiée)" "identique"
  echo "     témoin B5.4b : une écriture délibérée change l'empreinte"
  GT -C "$P" update-ref refs/heads/ecriture-delibere HEAD; node "$AUX/empreinte.mjs" "$P/.git" "$WORK/git-ecrit.txt" >/dev/null
  assert_eq "B5.4b — témoin : une écriture délibérée dans .git change l'empreinte (la mesure sait rougir)" "$(cmp -s "$WORK/git-avant.txt" "$WORK/git-ecrit.txt" && echo identique || echo modifiée)" "modifiée"
  assert_eq "B5.5 — aucune erreur de page" "$(jq_ "$R" '(j.errs||[]).length' 2>/dev/null)" "0"
fi
fi

# --- CAPT : captures pour le juge de design (P78-D-16) ---
CAPT_DIR="${TMPDIR:-/tmp}/78-captures"
if joue CAPT; then
echo "=== CAPT — captures sous $CAPT_DIR (jamais commitées) ==="
if [ -z "$CHROME" ]; then skip "CAPT" "pas de navigateur"; else
  rm -rf "$CAPT_DIR"; mkdir -p "$CAPT_DIR"
  CP="$WORK/capt"; mk_depot "$CP"; build_lab "$CP/wt-a"; serve_out "$CP/wt-a/.vibeflow/cockpit"; BASE="http://127.0.0.1:$PORT"
  cat "$AUX/aide.js" - > "$AUX/capt.js" <<'JS'
const [base, dossier] = ARGS;
const fs = await import('node:fs');
const png = async (nom) => { const r = await s.send('Page.captureScreenshot', { format: 'png' }); fs.writeFileSync(`${dossier}/${nom}.png`, Buffer.from(r.data, 'base64')); };
const out = { faites: [] };
await s.naviguer(base + '/');
await s.attendre(`document.readyState === 'complete' && !!window.VibeFlow && !!document.querySelector('#proj-name')`, 'page prête');
for (const theme of ['clair', 'sombre']) {
  await s.ev(`document.documentElement.setAttribute('data-theme', '${theme === 'clair' ? 'light' : 'dark'}')`);
  for (const w of [375, 700, 768, 1000, 1440]) {
    await fenetre(w, w < 700 ? 800 : 900); await pause(400);
    await s.ev(`window.VFGitTiroir && window.VFGitTiroir.fermer()`); await pause(200);
    await png(`${theme}-${w}-1-ferme`); out.faites.push(`${theme}-${w}-ferme`);
    await s.ev(`window.VFGitTiroir.ouvrir()`);
    await s.attendre(`${OUVERT} && document.querySelectorAll('#vf-git-tiroir li[role=option]').length > 0`, `tiroir ouvert ${w}`);
    // le tiroir rouvre sur la sélection précédente : on replie le détail pour la vue « ouvert », puis on le redéplie pour la vue « détail »
    await s.ev(`(() => { const sel = document.querySelector('#vf-git-tiroir li[role=option][aria-selected=true]'); if (sel && document.querySelector('#vf-git-tiroir [role=region][aria-label^="Détail du commit"]')) sel.click(); })()`);
    await s.attendre(`!document.querySelector('#vf-git-tiroir [role=region][aria-label^="Détail du commit"]')`, `détail replié ${w}`);
    await pause(900); await png(`${theme}-${w}-2-ouvert`); out.faites.push(`${theme}-${w}-ouvert`);
    await s.ev(`document.querySelector('#vf-git-tiroir li[role=option]').click()`);
    await s.attendre(`(() => { const r = document.querySelector('#vf-git-tiroir [role=region][aria-label^="Détail du commit"]'); return !!r && r.textContent.length > 0 && !/Lecture du détail/.test(r.textContent); })()`, `détail déplié ${w}`);
    await pause(500); await png(`${theme}-${w}-3-detail`); out.faites.push(`${theme}-${w}-detail`);
  }
}
out.errs = await s.ev(`window.__errs || []`);
return out;
JS
  R="$(cdp "$AUX/capt.js" "$BASE" "$CAPT_DIR")"; stop_srv
  NPNG="$(find "$CAPT_DIR" -name '*.png' | awk 'END{print NR}')"
  assert_eq "CAPT.1 — 30 captures produites (5 largeurs x 2 thèmes x fermé, ouvert, détail), aucune erreur de page" "$NPNG|$(jq_ "$R" '(j.errs||[]).length' 2>/dev/null)" "30|0"
  # Terminal ouvert à côté du tiroir : seulement si `--terminal` se lance (sinon la capture est signalée absente, jamais inventée)
  TL="$WORK/capt-term"; mk_depot "$TL"; build_lab "$TL/wt-a"; OUT_T="$TL/wt-a/.vibeflow/cockpit"; mkdir -p "$OUT_T/.cache"; rm -f "$OUT_T/.cache/server.json"
  (umask 077; node -e "console.log(require('crypto').randomBytes(32).toString('hex'))" | tr -d '\n' > "$OUT_T/.cache/terminal-amorce")
  ENVS="SHELL=/bin/sh VF_COCKPIT_TERM_GRACE_MS=5000 VF_COCKPIT_ENGINE_DIR=$SCRIPTS/../skills/cockpit-moteur VF_COCKPIT_SCRIPTS_DIR=$SCRIPTS"; serve_out "$OUT_T" --terminal; ENVS=""
  for _ in $(seq 1 100); do grep -q '"terminal"' "$OUT_T/.cache/server.json" 2>/dev/null && break; sleep 0.1; done
  cat "$AUX/aide.js" - > "$AUX/capt-term.js" <<'JS'
const [base, dossier] = ARGS;
const fs = await import('node:fs');
await fenetre(1440, 900); await s.naviguer(base + '/');
await s.attendre(`document.readyState === 'complete' && !!document.querySelector('#vf-git-ligne')`, 'page prête');
try { await s.attendre(`!!document.querySelector('.vf-term-pastille') && !document.querySelector('.vf-term-pastille').hidden`, 'pastille Terminal', 15000); } catch (e) { return { sautee: String(e.message) }; }
await s.ev(`window.VFGitTiroir.ouvrir()`); await s.attendre(`${OUVERT} && document.querySelectorAll('#vf-git-tiroir li[role=option]').length > 0`, 'tiroir ouvert');
await s.ev(`document.querySelector('.vf-term-pastille').click()`);
await s.attendre(`document.body.classList.contains('vf-term-ouvert') && !!document.querySelector('.vf-term-tiroir') && !document.querySelector('.vf-term-tiroir').hidden`, 'Terminal ouvert');
await pause(900);
const r = await s.send('Page.captureScreenshot', { format: 'png' }); fs.writeFileSync(`${dossier}/sombre-1440-4-terminal-ouvert.png`, Buffer.from(r.data, 'base64'));
return { fait: true };
JS
  RT="$(cdp "$AUX/capt-term.js" "http://127.0.0.1:$PORT" "$CAPT_DIR")"; stop_srv
  if [ -n "$(jq_ "$RT" 'j.sautee || j.erreur || ""' 2>/dev/null)" ]; then skip "CAPT.2 — capture Terminal ouvert" "$(jq_ "$RT" 'j.sautee || j.erreur')"; else
    assert_eq "CAPT.2 — capture du tiroir Git avec le Terminal ouvert" "$(test -s "$CAPT_DIR/sombre-1440-4-terminal-ouvert.png" && echo oui || echo non)" "oui"; fi
fi
fi

vf_hyg_assert
echo; echo "Résultats : $PASS réussis, $FAIL échoués, $SKIP sautés"
if [ "$((PASS+FAIL))" -eq 0 ]; then echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée"; exit 1; fi
[ "$FAIL" -eq 0 ]
