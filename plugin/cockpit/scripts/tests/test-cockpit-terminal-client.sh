#!/usr/bin/env bash
# test-cockpit-terminal-client.sh — client de la page du terminal (Q) : amorçage dans l'onglet, secret hors cookie, cadre sous sandbox, canal
# Q vers P, options xterm (TERM-04, TERM-05, TERM-10 statique, T17 côté Q ; P71-D-12, D-13, D-15, D-16, D-18 ; O4, O8 ; plan 71-06).
#   ST   statique (page servie par Q, scripts propres = vue et client) : T14.S1-S4 (options xterm sûres), T17.Q1-Q3 (canal sortant), T6.5 (aucun set-cookie)
#   T6   navigateur : amorçage Q/#t=… -> P/project.html, fragment effacé AVANT l'échange, aucun cookie, stockage de Q illisible depuis P, fichier consommé
#   T9   navigateur : T9.5 cadre sandbox="allow-scripts allow-same-origin" (ready puis etat:connecte d'origine Q), T9.6 origine tierce bloquée par
#        frame-ancestors, T9.7 0 violation de CSP (Q en premier niveau, P avec le cadre attaché), TQ.1 saisie -> shell -> sortie (transport)
#   T17  T17.Q4 Ctrl+Maj+Espace dans le cadre -> message toggle reçu par P, T17.Q5 tout message reçu est dans la liste fermée
#   O4   O4.1 même onglet = reprise (le second cadre se reconnecte) · O4.2 autre onglet (sessionStorage vide) = carte « Terminal déjà ouvert »
#   O8   MESURE-O8 : liens (window.open) bloqués ou ouverts sous le sandbox minimal puis avec allow-popups, opener nul (mesure, non comptée)
#   M-*  mutants (copies de la sortie, « mutant sans effet » = FAIL) : M-COOKIE, M-FRAGMENT, M-STOCKAGE, M-ETOILE, M-ECOUTE + M-CLIP, M-ANCETRES, M-SETCOOKIE
# Sans Chrome : les sections statiques tournent, la suite annonce « SUITE SAUTÉE (navigateur) » et ne compte rien d'invérifié comme réussi.
# Variables : VF_CLIENT_MS (échéance d'une attente navigateur, 20000 par défaut). Exit 0 si tout passe, 1 sinon.
set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; } # port libre choisi à l'exécution
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
ENG="$SCRIPTS/../skills/cockpit-moteur"; TA="$HERE_T/terminal-aux.mjs"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude/scripts" "$WORK/bin" "$WORK/run"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
export CHROME_SESSION="$HERE_T/chrome-session.mjs"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0
court() { if [ "${#1}" -gt 300 ]; then printf '%s […] %s' "${1:0:140}" "${1: -140}"; else printf '%s' "$1"; fi; }
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$(court "$3")]"; echo "     obtenu:  [$(court "$2")]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [$(court "$2")]"; FAIL=$((FAIL+1)); fi; }

CHROME=""
for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue
  if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
if [ -z "$CHROME" ]; then echo "  ⊘ SUITE SAUTÉE (navigateur) : TERM-04 et TERM-05 NON vérifiés, non comptés comme réussis"; fi

# shell de test : marqué par son chemin (hygiene.sh le retrouve), shell interactif sans exec
printf '#!/bin/sh\n/bin/sh -i\n' > "$WORK/bin/shell-test"; chmod +x "$WORK/bin/shell-test"; export SHELL="$WORK/bin/shell-test"

cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/stat.mjs" <<'JS'
// stat.mjs <page.html> : faits statiques des deux scripts propres (vue = 3e, client = 4e <script>), motifs tolérants (espaces, guillemets)
import fs from 'node:fs';
const h = fs.readFileSync(process.argv[2], 'utf8');
const s = [...h.matchAll(/<script>([\s\S]*?)<\/script>/g)].map((m) => m[1]);
const p = s.slice(2).join('\n');
const n = (re) => (p.match(re) || []).length;
const etats = [...new Set([...p.matchAll(/['"`]etat:([a-z]+)['"`]/g)].map((m) => m[1]))].sort().join(',');
console.log(JSON.stringify({
  scripts: s.length, propres: p.length,
  dcs: /registerDcsHandler\(\s*\{(?=[^}]*intermediates\s*:\s*['"]\$['"])(?=[^}]*final\s*:\s*['"]q['"])/.test(p),
  winopt: /windowOptions\s*:\s*\{\s*\}/.test(p), macopt: /macOptionIsMeta\s*:\s*false/.test(p),
  presse: n(/ClipboardAddon|navigator\s*\.\s*clipboard|execCommand\s*\(/g),
  lien: /linkHandler\s*:/.test(p) && /activate/.test(p) && /window\s*\.\s*open\s*\([^)]*['"]noopener['"]/.test(p), confirm: n(/\bconfirm\s*\(/g),
  ecoute: n(/addEventListener\(\s*['"]message['"]|\bonmessage\s*=/g), postmsg: n(/\bpostMessage\s*\(/g), etoile: n(/postMessage\s*\([^)]*['"]\*['"]/g), etats,
}));
JS
cat > "$AUX/pagegen.mjs" <<'JS'
// pagegen.mjs <sortie> <moteur> <theme> <fichier> : page rendue par le module de la sortie (sans serveur)
import { pathToFileURL } from 'node:url'; import fs from 'node:fs';
const [, , sortie, moteur, theme, out] = process.argv;
const m = await import(pathToFileURL(`${sortie}/vf-cockpit-terminal-page.mjs`).href);
m.preparerPage({ engineDir: moteur }); fs.writeFileSync(out, m.pageTerminal({ theme, origineP: 'http://127.0.0.1:4242' }).html);
JS
cat > "$AUX/tierce.mjs" <<'JS'
// tierce.mjs <port> <urlQ> : origine tierce qui encadre Q ; consigne les messages reçus (espion posé dans la page)
import http from 'node:http';
const [, , port, urlq] = process.argv;
const page = `<!doctype html><title>tierce</title><script>window.__msgs=[];addEventListener('message',function(e){window.__msgs.push({o:e.origin,d:String(e.data).slice(0,40)})})</script><iframe src="${urlq}/?theme=dark" style="width:400px;height:240px"></iframe>`;
http.createServer((q, r) => { r.writeHead(200, { 'Content-Type': 'text/html' }); r.end(page); }).listen(Number(port), '127.0.0.1');
JS
cat > "$AUX/chrome-client.mjs" <<'JS'
// chrome-client.mjs <chrome> <mode> <json> : scénarios navigateur du client de Q ; UNE ligne JSON. Modes : t6 · cadre · tierce.
// Chaque étape est isolée (essai) : une mesure indisponible est nommée dans `erreurs`, jamais un résultat vide. Amorçage et secret sont masqués en sortie.
import { pathToFileURL } from 'node:url';
const { executer, pause } = await import(pathToFileURL(process.env.CHROME_SESSION).href);
const [, , chrome, mode, brut] = process.argv;
const { P, Q, amorce, tierce } = JSON.parse(brut);
const OP = `http://127.0.0.1:${P}`, OQ = `http://127.0.0.1:${Q}`, MS = Number(process.env.VF_CLIENT_MS) || 20000;
const LISTE = ['ready', 'etat:connecte', 'etat:reconnexion', 'etat:termine', 'etat:refuse', 'etat:expire', 'etat:arrete', 'toggle'];
const erreurs = {};
const essai = async (nom, f) => { try { return await f(); } catch (e) { erreurs[nom] = String(e.message).slice(0, 140); return undefined; } };
const INVITE = `/\\$/.test((document.querySelector('.xterm-rows') || {}).textContent || '')`;
const masquer = (o, secret) => { let t = JSON.stringify(o).split(amorce).join('<amorce>'); if (secret) t = t.split(secret).join('<secret>'); return JSON.parse(t); };

await executer(chrome, async (s) => {
  const att = (expr, nom) => s.attendre(expr, nom, MS);
  const poll = async (f, nom) => { const fin = Date.now() + MS; for (;;) { const v = await f().catch(() => null); if (v) return v; if (Date.now() > fin) throw new Error(`attente de « ${nom} » dépassée (${MS} ms)`); await pause(100); } };
  const r = { erreurs };

  if (mode === 'tierce') {
    await essai('tierce', async () => {
      await s.naviguer(tierce);
      await poll(async () => s.violations.some((v) => /frame-ancestors/.test(v)), 'violation frame-ancestors');
    });
    r.violations = [...s.violations];
    r.msgs = await s.ev('JSON.stringify(window.__msgs)').then((x) => JSON.parse(x || '[]')).catch(() => []);
    return masquer(r);
  }

  // --- S1 : amorçage dans l'onglet ---
  r.adresse1 = '?'; r.histoireFrag = -1;
  await essai('amorcage', async () => {
    await s.naviguer(`${OQ}/#t=${amorce}`);
    await att(`location.port === '${P}' && location.pathname === '/project.html' && document.readyState === 'complete'`, 'arrivée sur P');
  });
  r.adresse1 = await s.ev('location.href').catch(() => '?');
  r.histoireFrag = await s.send('Page.getNavigationHistory').then((h) => h.entries.filter((e) => /#t=/.test(e.url)).length).catch(() => -1);

  if (mode === 't6') {
    // --- S2 : échange refusé (amorçage déjà consommé) : Q reste, sans fragment, carte « Session expirée » ---
    r.refus = { hash: '?', port: '?', carte: '' };
    await essai('refus', async () => {
      await s.naviguer(`${OQ}/#t=${amorce}`);
      await att(`(document.getElementById('etat') || {}).textContent && document.getElementById('etat').textContent.includes('Session expirée')`, 'carte Session expirée');
    });
    r.refus = await s.ev(`({ hash: location.hash, port: location.port, carte: (document.getElementById('etat') || {}).textContent || '' })`).catch(() => r.refus);
    // --- S3 : Q en premier niveau : secret dans son stockage, aucun cookie, terminal vivant ---
    r.secretQ = null; r.cookieQ = '?'; r.invite = false;
    await essai('q-premier-niveau', async () => {
      await s.naviguer(`${OQ}/`);
      r.secretQ = await s.ev(`localStorage.getItem('vf.terminal.secret')`);
      r.cookieQ = await s.ev('document.cookie');
      await att(INVITE, 'invite du shell');
      r.invite = true;
    });
    const secret = /^[0-9a-f]{64}$/.test(r.secretQ || '') ? r.secretQ : '';
    // --- S4 : P : aucun cookie, aucune trace de l'amorçage ni du secret ; stockage de Q illisible depuis P ---
    r.cookieP = '?'; r.scanP = null; r.stockageCadre = '?'; r.stockageP = '?';
    await essai('retour-P', async () => {
      await s.naviguer(`${OP}/project.html`);
      r.cookieP = await s.ev('document.cookie');
      r.scanP = await s.ev(`(() => {
        const A = ${JSON.stringify(amorce)}, S = ${JSON.stringify(secret)};
        const st = []; for (const k of Object.keys(localStorage)) st.push(k, localStorage.getItem(k)); for (const k of Object.keys(sessionStorage)) st.push(k, sessionStorage.getItem(k));
        const nb = (t) => (t.includes(A) ? 1 : 0) + (S && t.includes(S) ? 1 : 0);
        return { adresse: nb(location.href), dom: nb(document.documentElement.outerHTML), stockage: nb(st.join('\\n')), cookie: nb(document.cookie) };
      })()`);
      r.stockageCadre = await s.ev(`(async () => {
        const f = document.createElement('iframe'); f.dataset.t = '1'; f.style.cssText = 'position:fixed;left:0;top:0;width:640px;height:360px;border:0';
        f.src = '${OQ}/?theme=dark'; await new Promise((ok) => { f.onload = ok; document.body.appendChild(f); });
        let n; try { f.contentWindow.localStorage.getItem('x'); n = 'lisible'; } catch (e) { n = e.name; } f.remove(); return n; })()`);
      r.stockageP = await s.ev(`(() => { localStorage.setItem('vf.test.temoin', '1'); const v = localStorage.getItem('vf.test.temoin') === '1' ? 'lisible' : 'illisible'; localStorage.removeItem('vf.test.temoin'); return v; })()`);
    });
    return masquer(r, secret);
  }

  // --- mode cadre : P avec le cadre de Q sous sandbox ---
  const monter = async (sandbox) => {
    await s.ev(`(() => { window.__msgs = [];
      if (!window.__espion) { window.__espion = true; addEventListener('message', (e) => window.__msgs.push({ o: e.origin, d: typeof e.data === 'string' ? e.data.slice(0, 40) : '<' + typeof e.data + '>' })); }
      document.querySelectorAll('iframe[data-t]').forEach((f) => f.remove());
      const f = document.createElement('iframe'); f.dataset.t = '1'; f.setAttribute('sandbox', ${JSON.stringify(sandbox)});
      f.style.cssText = 'position:fixed;left:0;top:0;width:640px;height:360px;border:0;z-index:99999'; f.src = '${OQ}/?theme=dark'; document.body.appendChild(f); })()`);
  };
  const messages = () => s.ev('JSON.stringify(window.__msgs)').then((x) => JSON.parse(x || '[]')).catch(() => []);
  const CONNECTE = `window.__msgs.some((m) => m.d === 'etat:connecte')`;
  const SBX1 = 'allow-scripts allow-same-origin', SBX2 = 'allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox';
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true }).catch(() => {});
  await essai('P', async () => { await s.naviguer(`${OP}/project.html`); await att(`document.readyState === 'complete'`, 'page P'); });

  // T9.5 / T9.7 (P)
  await essai('cadre1', async () => { await monter(SBX1); await att(CONNECTE, 'etat:connecte du cadre sandbox'); });
  r.msgs1 = await messages(); r.violationsP = [...s.violations];

  // T17.Q4 : Ctrl+Maj+Espace dans le cadre
  await essai('toggle', async () => {
    const clic = (type) => s.send('Input.dispatchMouseEvent', { type, x: 320, y: 180, button: 'left', clickCount: 1 });
    await clic('mousePressed'); await clic('mouseReleased');
    const touche = (type) => s.send('Input.dispatchKeyEvent', { type, key: ' ', code: 'Space', windowsVirtualKeyCode: 32, modifiers: 10 });
    await touche('keyDown'); await touche('keyUp');
    await att(`window.__msgs.some((m) => m.d === 'toggle')`, 'message toggle');
  });
  r.msgsToggle = await messages();

  // O8 : window.open depuis le cadre, sandbox minimal puis avec allow-popups
  const o8 = async (sandbox) => {
    await monter(sandbox);
    const enfant = await poll(async () => (await s.send('Page.getFrameTree')).frameTree.childFrames?.find((c) => c.frame.url.startsWith(OQ)), 'cadre de Q dans l’arbre des cadres');
    const monde = await s.send('Page.createIsolatedWorld', { frameId: enfant.frame.id, worldName: 'o8' });
    const dans = (expression) => s.send('Runtime.evaluate', { contextId: monde.executionContextId, expression, returnByValue: true, userGesture: true }).then((x) => x?.result?.value);
    const statut = await dans(`(() => { const w = window.open('about:blank', '_blank'); if (w) { w.close(); return 'ouvert'; } return 'bloque'; })()`);
    let opener = 'sans objet';
    if (statut === 'ouvert') {
      const avant = new Set((await s.send('Target.getTargets')).targetInfos.map((t) => t.targetId));
      await dans(`window.open('about:blank', '_blank', 'noopener') && 0`);
      const nouveau = await poll(async () => (await s.send('Target.getTargets')).targetInfos.find((t) => t.type === 'page' && !avant.has(t.targetId)), 'fenêtre ouverte en noopener');
      opener = nouveau.canAccessOpener ? 'present' : 'nul';
      await s.send('Target.closeTarget', { targetId: nouveau.targetId }).catch(() => {});
    }
    return { statut, opener };
  };
  r.o8min = await essai('o8-minimal', () => o8(SBX1));
  r.o8pop = await essai('o8-popups', () => o8(SBX2));
  // O4.1 : le second cadre (monté par la mesure ci-dessus, même onglet) reprend la session
  await essai('cadre2', async () => { await monter(SBX2); await att(CONNECTE, 'etat:connecte du second cadre (reprise)'); });
  r.msgs2 = await messages();
  await s.ev(`document.querySelectorAll('iframe[data-t]').forEach((f) => f.remove())`).catch(() => {});

  // T9.7 (Q en premier niveau) + TQ.1 : saisie -> shell -> sortie
  r.invite = false; r.eco = false; r.violationsQ = [];
  const marq = `${Date.now()}`;
  await essai('q-premier-niveau', async () => {
    await s.naviguer(`${OQ}/`);
    await att(INVITE, 'invite du shell (Q en premier niveau)');
    r.invite = true; r.violationsQ = [...s.violations];
    for (const c of `echo MA""RQ-${marq}`) { await s.send('Input.dispatchKeyEvent', { type: 'keyDown', key: c, text: c, unmodifiedText: c }); await s.send('Input.dispatchKeyEvent', { type: 'keyUp', key: c }); }
    await s.send('Input.dispatchKeyEvent', { type: 'keyDown', key: 'Enter', code: 'Enter', windowsVirtualKeyCode: 13, text: '\r' });
    await s.send('Input.dispatchKeyEvent', { type: 'keyUp', key: 'Enter', code: 'Enter', windowsVirtualKeyCode: 13 });
    await att(`document.querySelector('.xterm-rows').textContent.includes('MARQ-${marq}')`, 'sortie de la commande saisie');
    r.eco = true;
  });
  r.violationsQ = r.violationsQ.length ? r.violationsQ : [...s.violations];

  // O4.2 : autre onglet = sessionStorage vide
  r.autre = '?';
  await essai('autre-onglet', async () => {
    await s.ev(`sessionStorage.clear()`);
    await s.naviguer(`${OQ}/`);
    await att(`(document.getElementById('etat') || {}).textContent && document.getElementById('etat').textContent.includes('Terminal déjà ouvert')`, 'carte Terminal déjà ouvert');
  });
  r.autre = await s.ev(`(document.getElementById('etat') || {}).textContent || ''`).catch(() => '?');
  r.liste = LISTE;
  return masquer(r);
}, { csp: true });
JS

rq() { node "$TA" req "$@"; }
rj() { printf '%s\n' "$1" | node "$AUX/ev.mjs" "$2" 2>/dev/null; }
amorce_neuve() { node -e "console.log(require('crypto').randomBytes(24).toString('hex'))"; }
mklab() {
  local L="$1" B="$1/.planning"; mkdir -p "$L/src" "$B/phases/01-socle"; printf 'export const u = 1;\n' > "$L/src/u.js"
  printf -- '## Phases\n\n- [x] **Phase 1: Socle** - premier jet\n\n### Phase 1: Socle\n**Goal**: Poser le socle\n' > "$B/ROADMAP.md"
  printf -- '---\nstatus: executing\ncurrent_phase: 1\nmilestone: v1.0 MVP\n---\n' > "$B/STATE.md"
  printf -- '---\nwave: 1\nfiles_modified: [src/u.js]\n---\n<objective>Poser le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  node "$SCRIPTS/vf-cockpit.mjs" build --lab "$L" > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
}
SRVN=0
srv() { # srv <sortie> -> SRV_PORT SRV_PID SRV_O SRV_OUT QP AMORCE ; serveur lancé directement avec --terminal, comme le lanceur
  local o="$1" lab; lab="$(cd "$1/../.." && pwd)"
  SRVN=$((SRVN+1)); SRV_O="$o"; SRV_OUT="$WORK/serve-$SRVN.out"; rm -f "$o/.cache/server.json" "$o/.cache/terminal-amorce"; mkdir -p "$o/.cache"
  AMORCE="$(amorce_neuve)"; (umask 077; printf '%s' "$AMORCE" > "$o/.cache/terminal-amorce")
  ( cd "$lab" && VF_COCKPIT_ENGINE_DIR="$ENG" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS" exec node "$o/serve.mjs" --no-open --terminal --port "$(libre)" > "$SRV_OUT" 2>&1 ) </dev/null >/dev/null 2>&1 &
  SRV_PID=$!; PIDS+=($SRV_PID)
  for _ in $(seq 1 100); do grep -q '"terminal"' "$o/.cache/server.json" 2>/dev/null && break; sleep 0.1; done
  SRV_PORT="$(sj j.port)"; SRV_PORT="${SRV_PORT:-0}"; QP="$(sj '(j.terminal&&j.terminal.url)||"http://127.0.0.1:0"')"; QP="${QP##*:}"
}
sj() { node "$AUX/ev.mjs" "$1" < "$SRV_O/.cache/server.json" 2>/dev/null; }
unsrv() { vf_hyg_stop "$SRV_PID"; }
mutant() { # mutant <nom> <fichier-relatif-à-la-sortie> <expression-sed> -> MUT_OUT ; code 1 si la cible manque ou si la copie n'a pas changé
  local d="$WORK/mut-$1" f; rm -rf "$d"; mkdir -p "$d"; cp -R "$LAB/.planning" "$d/.planning"; cp -R "$LAB/.vibeflow" "$d/.vibeflow"
  MUT_OUT="$d/.vibeflow/cockpit"; f="$MUT_OUT/$2"; [ -f "$f" ] || return 1
  cp "$f" "$f.orig"; sed -i.bak "$3" "$f"; local r=0; cmp -s "$f" "$f.orig" && r=1; rm -f "$f.orig" "$f.bak"; return $r
}
sans_effet() { assert_eq "$1 — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; }
navig() { node "$AUX/chrome-client.mjs" "$CHROME" "$@"; } # navig <mode> <json>
run_t6() { # run_t6 <sortie> -> T6J T6_FICHIER ; un serveur neuf, un amorçage neuf, un Chrome neuf
  srv "$1"; T6_P=$SRV_PORT; T6_Q=$QP
  T6J="$(navig t6 "{\"P\":$T6_P,\"Q\":$T6_Q,\"amorce\":\"$AMORCE\"}")"
  T6_FICHIER="$([ -e "$1/.cache/terminal-amorce" ] && echo present || echo supprime)"; unsrv
}

LAB="$WORK/lab"; mklab "$LAB"; OUT="$LAB/.vibeflow/cockpit"
ATTENDU_ETATS="arrete,connecte,expire,refuse,reconnexion,termine"

echo "=== ST — scripts propres de la page servie par Q (statique) ==="
srv "$OUT"; mkdir -p "$WORK/q"; rq "$QP" GET / --corps-vers "$WORK/q/page.html" > "$WORK/q/page.out"
ST="$(node "$AUX/stat.mjs" "$WORK/q/page.html")"
assert_eq "ST.0 — témoin : la page de Q a ses quatre <script> (les deux derniers sont les scripts propres)" "$(rj "$ST" 'j.scripts')" "4"
assert_eq "T14.S1 — gestionnaire DCS de remplacement (registerDcsHandler sur \$ et q) dans le client servi" "$(rj "$ST" 'j.dcs')" "true"
assert_eq "T14.S2 — windowOptions vide et macOptionIsMeta faux" "$(rj "$ST" 'j.winopt+"/"+j.macopt')" "true/true"
assert_eq "T14.S3 — aucun addon presse-papiers, navigator.clipboard ni execCommand dans les scripts propres (la page est vivante : propres > 200)" "$(rj "$ST" 'j.presse+"/"+(j.propres>200)')" "0/true"
assert_eq "T14.S4 — linkHandler avec activate qui ouvre en noopener ; aucun confirm(" "$(rj "$ST" 'j.lien+"/"+j.confirm')" "true/0"
assert_eq "T17.Q1 — aucun écouteur de messages entrants dans Q (la page est vivante : propres > 200)" "$(rj "$ST" 'j.ecoute+"/"+(j.propres>200)')" "0/true"
assert_eq "T17.Q2 — au moins un postMessage( et aucun avec l'étoile" "$(rj "$ST" '(j.postmsg>=1)+"/"+j.etoile')" "true/0"
assert_eq "T17.Q3 — les littéraux etat:* des scripts propres sont exactement les six valeurs de la liste" "$(rj "$ST" 'j.etats' | tr ',' '\n' | sort | tr '\n' ',')" "$(printf '%s' "$ATTENDU_ETATS" | tr ',' '\n' | sort | tr '\n' ',')"
# T6.5 : aucun set-cookie sur les routes de Q (réponses admises ET refusées), témoin : l'échange réussit
rq "$QP" GET / > "$WORK/q/c-page.out"; rq "$QP" POST /amorce --amorce "mauvais" > "$WORK/q/c-refus.out"
rq "$QP" POST /amorce --amorce "$AMORCE" > "$WORK/q/c-amorce.out"; SEC="$(sed 1,2d "$WORK/q/c-amorce.out" | node "$AUX/ev.mjs" j.secret 2>/dev/null)"
rq "$QP" GET /etat --secret "$SEC" > "$WORK/q/c-etat.out"; rq "$QP" POST /entree --secret "$SEC" --onglet c0ffee --corps "" > "$WORK/q/c-entree.out"
COOKIES=0; for f in page refus amorce etat entree; do COOKIES=$((COOKIES + $(sed -n 2p "$WORK/q/c-$f.out" | node "$AUX/ev.mjs" 'Object.keys(j).filter(k=>k==="set-cookie").length' 2>/dev/null || echo 9))); done
assert_eq "T6.5 — aucun set-cookie sur GET /, POST /amorce (refusé et admis), GET /etat, POST /entree (témoin : l'échange rend un secret de 64 hexadécimaux)" "$COOKIES/$([[ "$SEC" =~ ^[0-9a-f]{64}$ ]] && echo secret || echo "sans-secret")" "0/secret"
unsrv

echo "=== M-ETOILE / M-ECOUTE / M-CLIP / M-SETCOOKIE — mutants statiques ==="
mut_page() { node "$AUX/pagegen.mjs" "$MUT_OUT" "$ENG" dark "$WORK/m-$1.html"; node "$AUX/stat.mjs" "$WORK/m-$1.html"; }
if mutant etoile vf-cockpit-terminal-client.mjs "s|MESSAGES\[cle\], cfg.origineP|MESSAGES[cle], '*'|"; then
  assert_eq "M-ETOILE — le mutant rougit T17.Q2 : un postMessage avec l'étoile" "$(rj "$(mut_page etoile)" 'j.etoile>=1')" "true"
else sans_effet "M-ETOILE"; fi
if mutant ecoute vf-cockpit-terminal-client.mjs "s|const RACCOURCI|addEventListener('message', () => {}); const RACCOURCI|"; then
  assert_eq "M-ECOUTE — le mutant rougit T17.Q1 : un écouteur de messages entrants" "$(rj "$(mut_page ecoute)" 'j.ecoute>=1')" "true"
else sans_effet "M-ECOUTE"; fi
if mutant clip vf-cockpit-terminal-client.mjs "s|const RACCOURCI|navigator.clipboard.writeText('x'); const RACCOURCI|"; then
  assert_eq "M-CLIP — le mutant rougit T14.S3 : un appel au presse-papiers" "$(rj "$(mut_page clip)" 'j.presse>=1')" "true"
else sans_effet "M-CLIP"; fi
if mutant setcookie vf-cockpit-terminal.mjs "s|res.setHeader('Referrer-Policy', 'no-referrer');|res.setHeader('Referrer-Policy', 'no-referrer'); res.setHeader('Set-Cookie', 'a=b');|"; then
  srv "$MUT_OUT"; rq "$QP" GET / > "$WORK/m-setcookie.out"
  assert_eq "M-SETCOOKIE — le mutant rougit T6.5 : set-cookie présent" "$(sed -n 2p "$WORK/m-setcookie.out" | node "$AUX/ev.mjs" 'Object.keys(j).filter(k=>k==="set-cookie").length' 2>/dev/null)" "1"; unsrv
else sans_effet "M-SETCOOKIE"; fi

if [ -n "$CHROME" ]; then
echo "=== T6 — amorçage dans l'onglet, secret hors cookie (TERM-04 ; P71-D-12, D-13) ==="
run_t6 "$OUT"; J="$T6J"; OP="http://127.0.0.1:$T6_P"
assert_eq "T6.0 — témoin : le scénario n'a pas échoué globalement" "$(rj "$J" 'j.erreur||"ok"')" "ok"
assert_eq "T6.1 — Q/#t=… mène à P/project.html sans fragment ni paramètre ; aucune entrée d'historique ne porte #t=" "$(rj "$J" '"adresse="+j.adresse1+" historique_avec_fragment="+j.histoireFrag')" "adresse=$OP/project.html historique_avec_fragment=0"
assert_eq "T6.1b — échange refusé : Q reste, adresse sans fragment, carte « Session expirée »" "$(rj "$J" '"hash=["+j.refus.hash+"] port="+j.refus.port+" carte="+(j.refus.carte.includes("Session expirée")?"oui":"non")')" "hash=[] port=$T6_Q carte=oui"
SECRET_OK="$(rj "$J" '/^[0-9a-f]{64}$/.test(j.secretQ||"")?"oui":"non"')"
assert_eq "T6.3 — le secret (64 hexadécimaux) est rangé dans le stockage de Q (Q en premier niveau), terminal vivant" "secret=$SECRET_OK invite=$(rj "$J" 'j.invite')" "secret=oui invite=true"
assert_eq "T6.2 — document.cookie vide sur P et sur Q (témoin : le secret existe bien, sinon le vide ne prouve rien)" "P=[$(rj "$J" 'j.cookieP')] Q=[$(rj "$J" 'j.cookieQ')] secret_connu=$SECRET_OK" "P=[] Q=[] secret_connu=oui"
assert_eq "T6.4 — depuis P, le stockage du cadre de Q lève SecurityError (témoins : le secret est dans Q, le stockage de P est lisible)" "$(rj "$J" 'j.stockageCadre')/secret_dans_q=$SECRET_OK/stockage_p=$(rj "$J" 'j.stockageP')" "SecurityError/secret_dans_q=oui/stockage_p=lisible"
assert_eq "T6.6 — le fichier d'amorçage est supprimé après l'échange" "$T6_FICHIER" "supprime"
assert_eq "T6.7 — ni l'amorçage ni le secret dans l'adresse, le DOM, le stockage ou les cookies de P (témoin : secret connu)" "$(rj "$J" '"adresse="+j.scanP.adresse+" dom="+j.scanP.dom+" stockage="+j.scanP.stockage+" cookie="+j.scanP.cookie')/secret_connu=$SECRET_OK" "adresse=0 dom=0 stockage=0 cookie=0/secret_connu=oui"

echo "=== T9 / T17 / O4 / O8 — cadre sous sandbox dans P (TERM-05, A1 ; P71-D-18) ==="
srv "$OUT"; CP=$SRV_PORT; CQ=$QP; OP="http://127.0.0.1:$CP"; OQ="http://127.0.0.1:$CQ"
J="$(navig cadre "{\"P\":$CP,\"Q\":$CQ,\"amorce\":\"$AMORCE\"}")"; unsrv
assert_eq "T9.0 — témoin : le scénario n'a pas échoué globalement" "$(rj "$J" 'j.erreur||"ok"')" "ok"
assert_eq "T9.5 — cadre sandbox=\"allow-scripts allow-same-origin\" dans P : ready puis etat:connecte, tous d'origine Q" "$(rj "$J" '(function(){const m=j.msgs1||[];const a=m.findIndex(x=>x.d==="ready"),b=m.findIndex(x=>x.d==="etat:connecte");return "ordre="+(a>=0&&b>a?"ok":"ko")+" origines="+[...new Set(m.map(x=>x.o))].join(",")})()')" "ordre=ok origines=$OQ"
assert_eq "T9.7 — 0 violation de CSP : P avec le cadre chargé et attaché, Q en premier niveau (témoins : connecté sous sandbox, invite du shell)" "$(rj "$J" '"connecte="+((j.msgs1||[]).some(x=>x.d==="etat:connecte")?"oui":"non")+" P="+(j.violationsP||["?"]).length+" Q="+(j.invite?"oui":"non")+"/"+(j.violationsQ||["?"]).length')" "connecte=oui P=0 Q=oui/0"
assert_eq "TQ.1 — la saisie atteint le shell et sa sortie revient (POST /entree puis flux, Q en premier niveau)" "$(rj "$J" 'j.eco')" "true"
assert_eq "T17.Q4 — Ctrl+Maj+Espace dans le cadre : message toggle reçu par P, d'origine Q" "$(rj "$J" '"toggle="+((j.msgsToggle||[]).some(x=>x.d==="toggle"&&x.o==="'"$OQ"'")?"oui":"non")')" "toggle=oui"
assert_eq "T17.Q5 — tout message reçu par P est dans la liste fermée (au moins ready, etat:connecte et toggle ont été vus)" "$(rj "$J" '(function(){const m=[...(j.msgsToggle||[]),...(j.msgs2||[])];return "hors_liste="+m.filter(x=>!j.liste.includes(x.d)).length+" vus="+["ready","etat:connecte","toggle"].every(v=>m.some(x=>x.d===v))})()')" "hors_liste=0 vus=true"
assert_eq "O4.1 — même onglet = reprise : le second cadre se reconnecte (etat:connecte, pas etat:refuse)" "$(rj "$J" '"connecte="+((j.msgs2||[]).some(x=>x.d==="etat:connecte")?"oui":"non")+" refuse="+((j.msgs2||[]).some(x=>x.d==="etat:refuse")?"oui":"non")')" "connecte=oui refuse=non"
assert_eq "O4.2 — autre onglet (sessionStorage vide) : carte « Terminal déjà ouvert »" "$(rj "$J" '(j.autre||"").includes("Terminal déjà ouvert")?"oui":"non"')" "oui"
echo "  mesure : MESURE-O8 minimal=$(rj "$J" '(j.o8min||{}).statut||"indisponible"') popups=$(rj "$J" '(j.o8pop||{}).statut||"indisponible"') opener=$(rj "$J" '(j.o8pop||{}).opener||"indisponible"')"
echo "MESURE-O8 minimal=$(rj "$J" '(j.o8min||{}).statut||"indisponible"') popups=$(rj "$J" '(j.o8pop||{}).statut||"indisponible"') opener=$(rj "$J" '(j.o8pop||{}).opener||"indisponible"')"

echo "=== T9.6 — origine tierce : Q refuse d'être encadrée (frame-ancestors) ==="
srv "$OUT"; TP="$(libre)"; node "$AUX/tierce.mjs" "$TP" "http://127.0.0.1:$QP" & TIERCE_PID=$!; PIDS+=($TIERCE_PID)
for _ in $(seq 1 50); do rq "$TP" GET / --host "127.0.0.1:$TP" --sans-origin 2>/dev/null | grep -q '^200' && break; sleep 0.1; done
J="$(navig tierce "{\"P\":$SRV_PORT,\"Q\":$QP,\"amorce\":\"$AMORCE\",\"tierce\":\"http://127.0.0.1:$TP/\"}")"; vf_hyg_stop "$TIERCE_PID"; unsrv
assert_eq "T9.6 — page tierce (autre port) qui encadre Q : une violation frame-ancestors, aucun message reçu (témoin : la violation est relevée)" "$(rj "$J" '"violation="+((j.violations||[]).some(v=>/frame-ancestors/.test(v))?"oui":"non")+" messages="+(j.msgs||["?"]).length')" "violation=oui messages=0"

echo "=== M-COOKIE / M-FRAGMENT / M-STOCKAGE / M-ANCETRES — mutants jouées en navigateur ==="
if mutant cookie vf-cockpit-terminal-client.mjs "s|localStorage.setItem(CLE_SECRET, secret);|localStorage.setItem(CLE_SECRET, secret); document.cookie = 'vfs=' + secret + '; path=/';|"; then
  run_t6 "$MUT_OUT"
  assert_has "M-COOKIE — le mutant rougit T6.2 : un cookie existe" "$(rj "$T6J" 'j.cookieQ')" "vfs="
else sans_effet "M-COOKIE"; fi
if mutant fragment vf-cockpit-terminal-client.mjs "s|history.replaceState(null, '', location.pathname + location.search);||"; then
  run_t6 "$MUT_OUT"
  assert_eq "M-FRAGMENT — le mutant rougit T6.1b : l'échange refusé laisse #t= dans l'adresse de Q" "$(rj "$T6J" 'j.refus.hash.slice(0,3)')" "#t="
else sans_effet "M-FRAGMENT"; fi
if mutant stockage vf-cockpit-terminal-client.mjs "s|'/project.html')|'/project.html?s=' + secret)|"; then
  run_t6 "$MUT_OUT"
  assert_has "M-STOCKAGE — le mutant rougit T6.1 : le secret figure dans l'adresse de P" "$(rj "$T6J" 'j.adresse1')" "?s="
else sans_effet "M-STOCKAGE"; fi
if mutant ancetres vf-cockpit-terminal-page.mjs 's|frame-ancestors \${origineP}|frame-ancestors *|'; then
  srv "$MUT_OUT"; TP="$(libre)"; node "$AUX/tierce.mjs" "$TP" "http://127.0.0.1:$QP" & TIERCE_PID=$!; PIDS+=($TIERCE_PID)
  for _ in $(seq 1 50); do rq "$TP" GET / --host "127.0.0.1:$TP" --sans-origin 2>/dev/null | grep -q '^200' && break; sleep 0.1; done
  VF_CLIENT_MS=6000 J="$(navig tierce "{\"P\":$SRV_PORT,\"Q\":$QP,\"amorce\":\"$AMORCE\",\"tierce\":\"http://127.0.0.1:$TP/\"}")"; vf_hyg_stop "$TIERCE_PID"; unsrv
  assert_eq "M-ANCETRES — le mutant rougit T9.6 : aucune violation frame-ancestors (la page tierce encadre Q)" "$(rj "$J" '(j.violations||[]).some(v=>/frame-ancestors/.test(v))?"oui":"non"')" "non"
else sans_effet "M-ANCETRES"; fi
fi

vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
