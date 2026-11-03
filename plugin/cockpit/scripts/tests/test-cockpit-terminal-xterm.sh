#!/usr/bin/env bash
# test-cockpit-terminal-xterm.sh — terminal réel dans Chrome : plein écran, touches, séquences hostiles
# (TERM-09 navigateur, TERM-10 comportement ; P71-D-06, D-16 ; plan 71-08, hypothèse A2 de 71-RESEARCH).
#   T13  programme plein écran témoin (temoins/plein-ecran.py) dans la page Q réelle : T13.6 grille (TEMOIN-PLEIN-ECRAN-DEBUT puis PRET),
#        T13.7 redimensionnement de la fenêtre -> WINCH <lignes>x<colonnes> dans la grille, T13.8 Ctrl-C -> SIGINT-RECU et retour à l'écran normal,
#        T13.9 touches : Échap, Tab, Ctrl+R, Ctrl+W, flèche haut atteignent le shell (récepteur d'entrée brute), Ctrl+Maj+Espace n'envoie aucun octet
#   T14  programme hostile (temoins/hostile.py : OSC 52, OSC 8, DCS, XTGETTCAP, CSI 21t/18t/14t/16t, DECRQSS puis DA1) : T14.1 l'entrée reçue est la réponse à DA1
#        SEULE (témoin T14.1a : elle est reçue), T14.2 aucun appel au presse-papiers, T14.3 ni window.open ni confirm sans clic, T14.4 un clic sur le lien
#        OSC 8 l'ouvre une fois en noopener sans confirm, T14.5 témoin de l'espion (un appel délibéré au presse-papiers est compté)
#   M-*  mutants (copies de la sortie ou du moteur, « mutant sans effet » = FAIL) : M-CTRLC (T13.8), M-DCS et M-WINOPT (T14.1, mesure de A2),
#        M-CLIP (T14.2), M-LIEN (T14.3/T14.4)
# Chrome requis pour toutes les sections : sans lui la suite annonce « SUITE SAUTÉE (navigateur) », ne compte rien et sort 1 (anti-vert-à-vide).
# Limite assumée : Chrome headless Linux n'a pas de pointeur fin (pointer: none) et son presse-papiers n'est pas observable depuis la page ; on
# mesure donc les APPELS à navigator.clipboard.* et document.execCommand par espions posés avant la page, jamais le contenu du presse-papiers du poste.
# Variables : VF_XTERM_MS (échéance d'une attente navigateur, 20000 par défaut). Exit 0 si tout passe, 1 sinon.
set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; } # port libre choisi à l'exécution
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
ENG="$(cd "$SCRIPTS/../skills/cockpit-moteur" && pwd -P)"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude/scripts" "$WORK/bin" "$WORK/run" "$WORK/temoins"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
export CHROME_SESSION="$HERE_T/chrome-session.mjs"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0
court() { if [ "${#1}" -gt 300 ]; then printf '%s […] %s' "${1:0:140}" "${1: -140}"; else printf '%s' "$1"; fi; }
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$(court "$3")]"; echo "     obtenu:  [$(court "$2")]"; FAIL=$((FAIL+1)); fi; }
cp "$HERE_T/temoins/plein-ecran.py" "$WORK/temoins/plein-ecran.py"; cp "$HERE_T/temoins/hostile.py" "$WORK/temoins/hostile.py"

CHROME=""
for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue
  if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
if [ -z "$CHROME" ]; then echo "  ⊘ SUITE SAUTÉE (navigateur) : TERM-09 (navigateur) et TERM-10 (comportement) NON vérifiés, non comptés comme réussis"; exit 1; fi

# shell de test : marqué par son chemin (hygiene.sh le retrouve), bash interactif sans exec, invite « VFP> »
printf "PS1='VFP> '\n" > "$WORK/rc"
printf '#!/bin/sh\nbash --rcfile "%s/rc" -i\n' "$WORK" > "$WORK/bin/shell-test"; chmod +x "$WORK/bin/shell-test"; export SHELL="$WORK/bin/shell-test"

cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/hex.mjs" <<'JS'
// hex.mjs <fichier> has <octets-hex> | re <expression régulière sur l'hexadécimal> | len : « oui »/« non » (len : le nombre d'octets) ; fichier absent : « absent »
import fs from 'node:fs';
const [, , f, cmd, arg] = process.argv; let h; try { h = fs.readFileSync(f, 'utf8').trim(); } catch { console.log('absent'); process.exit(0); }
if (cmd === 'has') console.log(Buffer.from(h, 'hex').includes(Buffer.from(arg, 'hex')) ? 'oui' : 'non');
else if (cmd === 're') console.log(new RegExp(arg).test(h) ? 'oui' : 'non');
else console.log(Buffer.from(h, 'hex').length);
JS
cat > "$AUX/chrome-xterm.mjs" <<'JS'
// chrome-xterm.mjs <chrome> <mode> <json> : scénarios navigateur du terminal réel ; UNE ligne JSON. Modes : plein · hostile.
// Q est jouée en PREMIER niveau (le secret est dans son stockage) après l'amorçage ; saisie par Input.insertText puis Entrée par dispatchKeyEvent.
// Chaque étape est isolée (essai) : une mesure indisponible est nommée dans `erreurs`, jamais un résultat vide. Amorçage et secret ne sont jamais rendus.
import { pathToFileURL } from 'node:url';
const { executer, pause } = await import(pathToFileURL(process.env.CHROME_SESSION).href);
const [, , chrome, mode, brut] = process.argv;
const { P, Q, amorce, plein, hostile, sortieHex, recepteurHex, avecRecepteur } = JSON.parse(brut);
const OQ = `http://127.0.0.1:${Q}`, MS = Number(process.env.VF_XTERM_MS) || 20000;
const erreurs = {};
const essai = async (nom, f) => { try { return await f(); } catch (e) { erreurs[nom] = String(e.message).slice(0, 140); return undefined; } };
const TXT = `((document.querySelector('.xterm-rows') || {}).textContent || '').replace(/\\u00a0/g, ' ')`;
// espions posés AVANT la page : presse-papiers (navigator.clipboard.*, document.execCommand), window.open, confirm
const ESPION = `(() => { const E = window.__esp = { clip: 0, exec: 0, confirm: 0, open: [] };
  const c = navigator.clipboard; if (c) for (const m of ['writeText', 'write', 'readText', 'read']) c[m] = function () { E.clip++; return Promise.resolve(m.indexOf('read') === 0 ? '' : undefined); };
  document.execCommand = function () { E.exec++; return false; };
  window.open = function () { E.open.push(Array.prototype.map.call(arguments, String)); return null; };
  window.confirm = function () { E.confirm++; return false; };
})()`;

await executer(chrome, async (s) => {
  const att = (expr, nom) => s.attendre(expr, nom, MS);
  const r = { erreurs };
  const touche = async (o) => { await s.send('Input.dispatchKeyEvent', { type: 'keyDown', ...o }); await s.send('Input.dispatchKeyEvent', { type: 'keyUp', key: o.key, code: o.code, windowsVirtualKeyCode: o.windowsVirtualKeyCode, modifiers: o.modifiers }); };
  const taper = async (texte) => { await s.send('Input.insertText', { text: texte }); await touche({ key: 'Enter', code: 'Enter', windowsVirtualKeyCode: 13, text: '\r' }); };
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true }).catch(() => {});
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: ESPION });

  // amorçage dans l'onglet puis Q en premier niveau jusqu'à l'invite du shell
  await essai('amorcage', async () => {
    await s.naviguer(`${OQ}/#t=${amorce}`);
    await att(`location.port === '${P}' && location.pathname === '/project.html' && document.readyState === 'complete'`, 'arrivée sur P');
  });
  await essai('invite', async () => { await s.naviguer(`${OQ}/`); await att(`${TXT}.includes('VFP>')`, 'invite du shell'); r.invite = true; });
  if (!r.invite) return r;

  if (mode === 'plein') {
    await essai('plein-ecran', async () => {
      await taper(`python3 -I ${plein}`);
      await att(`${TXT}.includes('TEMOIN-PLEIN-ECRAN-DEBUT') && ${TXT}.includes('PRET')`, 'TEMOIN-PLEIN-ECRAN-DEBUT puis PRET dans la grille');
      r.debut = true; r.pret = true;
      r.taille0 = await s.ev(`(${TXT}.match(/TAILLE (\\d+x\\d+)/) || [])[1] || ''`);
    });
    await essai('winch', async () => { // fenêtre agrandie -> ResizeObserver -> POST /taille -> SIGWINCH -> WINCH dans la grille
      await s.send('Emulation.setDeviceMetricsOverride', { width: 1400, height: 1000, deviceScaleFactor: 1, mobile: false });
      const cond = `(() => { const m = ${TXT}.match(/WINCH (\\d+)x(\\d+)/g); if (!m) return false; const d = m[m.length - 1].match(/(\\d+)x(\\d+)/); return Number(d[1]) === document.querySelector('.xterm-rows').childElementCount; })()`;
      await att(cond, 'WINCH <lignes>x<colonnes> aux dimensions de la grille');
      r.winch = await s.ev(`(() => { const m = ${TXT}.match(/WINCH (\\d+x\\d+)/g); return m[m.length - 1].slice(6); })()`);
      r.lignes = await s.ev(`document.querySelector('.xterm-rows').childElementCount`);
    });
    await essai('sigint', async () => {
      await touche({ key: 'c', code: 'KeyC', windowsVirtualKeyCode: 67, modifiers: 2 });
      await att(`${TXT}.includes('SIGINT-RECU')`, 'SIGINT-RECU');
      r.sigint = true;
      r.debutApres = await s.ev(`${TXT}.includes('TEMOIN-PLEIN-ECRAN-DEBUT')`);
    });
    if (avecRecepteur) await essai('touches', async () => {
      await att(`${TXT}.includes('VFP>')`, 'invite du shell après Ctrl-C');
      await taper(`python3 -I ${hostile} --recepteur ${recepteurHex} 30`);
      await att(`${TXT}.includes('RECEPTEUR-PRET')`, 'RECEPTEUR-PRET');
      await touche({ key: 'Escape', code: 'Escape', windowsVirtualKeyCode: 27 });
      await touche({ key: 'Tab', code: 'Tab', windowsVirtualKeyCode: 9 });
      await touche({ key: 'r', code: 'KeyR', windowsVirtualKeyCode: 82, modifiers: 2 });
      await touche({ key: 'w', code: 'KeyW', windowsVirtualKeyCode: 87, modifiers: 2 });
      await touche({ key: 'ArrowUp', code: 'ArrowUp', windowsVirtualKeyCode: 38 });
      await touche({ key: ' ', code: 'Space', windowsVirtualKeyCode: 32, modifiers: 10 }); // Ctrl+Maj+Espace : aucun octet
      await touche({ key: 'z', code: 'KeyZ', windowsVirtualKeyCode: 90, text: 'z' }); // sentinelle : fin de la lecture
      await att(`${TXT}.includes('RECEPTEUR-FIN')`, 'RECEPTEUR-FIN');
      r.touches = true;
    });
    return r;
  }

  // mode hostile : témoin de l'espion (un appel délibéré compte), puis le programme hostile, puis le clic sur le lien OSC 8
  await essai('temoin-espion', async () => {
    await s.ev(`navigator.clipboard.writeText('temoin')`);
    r.clipTemoin = await s.ev(`window.__esp.clip`);
    await s.ev(`window.__esp.clip = 0`);
  });
  await essai('hostile', async () => {
    await taper(`python3 -I ${hostile} ${sortieHex} 6`);
    await att(`${TXT}.includes('HOSTILE-FIN')`, 'HOSTILE-FIN');
    r.avant = await s.ev(`JSON.parse(JSON.stringify(window.__esp))`);
  });
  await essai('lien', async () => {
    const pt = await s.ev(`(() => { const sp = [...document.querySelectorAll('.xterm-rows span')].find((x) => x.textContent.indexOf('LIEN') >= 0); if (!sp) return null; const b = sp.getBoundingClientRect(); return { x: b.left + b.width / 2, y: b.top + b.height / 2 }; })()`);
    if (!pt) throw new Error('cellule LIEN absente de la grille');
    r.cellule = true;
    await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: pt.x - 3, y: pt.y });
    await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: pt.x, y: pt.y });
    await att(`!!document.querySelector('.xterm-cursor-pointer')`, 'survol du lien (curseur main)');
    await s.send('Input.dispatchMouseEvent', { type: 'mousePressed', x: pt.x, y: pt.y, button: 'left', clickCount: 1 });
    await s.send('Input.dispatchMouseEvent', { type: 'mouseReleased', x: pt.x, y: pt.y, button: 'left', clickCount: 1 });
    await att(`window.__esp.open.length + window.__esp.confirm >= 1`, 'ouverture du lien (window.open ou confirm)');
  });
  r.apres = await s.ev(`JSON.parse(JSON.stringify(window.__esp))`).catch(() => null);
  return r;
}, { csp: false });
JS

rq() { node "$HERE_T/terminal-aux.mjs" req "$@"; }
rj() { printf '%s\n' "$1" | node "$AUX/ev.mjs" "$2" 2>/dev/null; }
hx() { node "$AUX/hex.mjs" "$@"; }
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
srv() { # srv <sortie> [moteur] -> SRV_PORT SRV_PID SRV_O SRV_OUT QP AMORCE ; serveur lancé directement avec --terminal, comme le lanceur
  local o="$1" eng="${2:-$ENG}" lab; lab="$(cd "$1/../.." && pwd)"
  SRVN=$((SRVN+1)); SRV_O="$o"; SRV_OUT="$WORK/serve-$SRVN.out"; rm -f "$o/.cache/server.json" "$o/.cache/terminal-amorce"; mkdir -p "$o/.cache"
  AMORCE="$(amorce_neuve)"; (umask 077; printf '%s' "$AMORCE" > "$o/.cache/terminal-amorce")
  ( cd "$lab" && VF_COCKPIT_ENGINE_DIR="$eng" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS" exec node "$o/serve.mjs" --no-open --terminal --port "$(libre)" > "$SRV_OUT" 2>&1 ) </dev/null >/dev/null 2>&1 &
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
mutant_eng() { # mutant_eng <nom> <expression-sed> -> MUT_ENG : copie du moteur dont l'assistant PTY est muté
  MUT_ENG="$WORK/eng-$1"; rm -rf "$MUT_ENG"; cp -R "$ENG" "$MUT_ENG"; local f="$MUT_ENG/terminal/vf-cockpit-pty.py"; [ -f "$f" ] || return 1
  cp "$f" "$f.orig"; sed -i.bak "$2" "$f"; local r=0; cmp -s "$f" "$f.orig" && r=1; rm -f "$f.orig" "$f.bak"; return $r
}
sans_effet() { assert_eq "$1 — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; }
rouge() { echo "     [mutant] obtenu $1, le code sain rend $2" >&2; [ "$1" != "$2" ] && echo rouge || echo "identique : $1"; }
navig() { node "$AUX/chrome-xterm.mjs" "$CHROME" "$@"; } # navig <mode> <json>
run_plein() { # run_plein <sortie> <moteur> <avecRecepteur 0|1> -> PJ ; un serveur neuf, un amorçage neuf, un Chrome neuf
  rm -f "$WORK/rec.hex"; srv "$1" "$2"
  PJ="$(navig plein "{\"P\":$SRV_PORT,\"Q\":$QP,\"amorce\":\"$AMORCE\",\"plein\":\"$WORK/temoins/plein-ecran.py\",\"hostile\":\"$WORK/temoins/hostile.py\",\"recepteurHex\":\"$WORK/rec.hex\",\"avecRecepteur\":$3}")"; unsrv
}
run_hostile() { # run_hostile <sortie> -> HJ ; le relevé hexadécimal de l'entrée reçue est dans $WORK/hostile.hex
  rm -f "$WORK/hostile.hex"; srv "$1"
  HJ="$(navig hostile "{\"P\":$SRV_PORT,\"Q\":$QP,\"amorce\":\"$AMORCE\",\"hostile\":\"$WORK/temoins/hostile.py\",\"sortieHex\":\"$WORK/hostile.hex\"}")"; unsrv
}

LAB="$WORK/lab"; mklab "$LAB"; OUT="$LAB/.vibeflow/cockpit"

echo "=== T13 — programme plein écran témoin dans la page Q réelle (TERM-09 navigateur) ==="
run_plein "$OUT" "$ENG" true; J="$PJ"
assert_eq "T13.0 — témoin : le scénario n'a pas échoué (aucune erreur nommée)" "$(rj "$J" 'j.erreur||JSON.stringify(j.erreurs)')" "{}"
assert_eq "T13.6 — TEMOIN-PLEIN-ECRAN-DEBUT puis PRET dans la grille xterm (témoin : l'invite du shell a précédé)" "invite=$(rj "$J" 'j.invite') debut=$(rj "$J" 'j.debut') pret=$(rj "$J" 'j.pret')" "invite=true debut=true pret=true"
assert_eq "T13.7 — fenêtre agrandie : WINCH <lignes>x<colonnes> dans la grille, lignes = celles de la grille, différent de la taille de départ (TAILLE)" "$(rj "$J" '"winch_lignes_egal="+(!!j.winch&&j.winch.split("x")[0]===String(j.lignes))+" change="+(!!j.winch&&j.winch!==j.taille0)')" "winch_lignes_egal=true change=true"
assert_eq "T13.8 — Ctrl-C : SIGINT-RECU, et retour à l'écran normal (TEMOIN-PLEIN-ECRAN-DEBUT n'est plus à l'écran)" "$(rj "$J" '"sigint="+j.sigint+" debut_apres="+j.debutApres')" "sigint=true debut_apres=false"
assert_eq "T13.9 — touches : le récepteur a reçu EXACTEMENT Échap 1b, Tab 09, Ctrl+R 12, Ctrl+W 17, flèche haut 1b5b41 (ou 1b4f41), puis la sentinelle 7a ; Ctrl+Maj+Espace n'a envoyé aucun octet (pas de 00)" "$(hx "$WORK/rec.hex" re '^1b0912171b(5b|4f)417a$')/nul=$(hx "$WORK/rec.hex" has 00)" "oui/nul=non"

echo "=== T14 — séquences hostiles : rien n'est réinjecté, rien ne sort (TERM-10 ; P71-D-16) ==="
run_hostile "$OUT"; H="$HJ"; HEX="$WORK/hostile.hex"
assert_eq "T14.0 — témoin : le scénario n'a pas échoué (aucune erreur nommée)" "$(rj "$H" 'j.erreur||JSON.stringify(j.erreurs)')" "{}"
assert_eq "T14.1a — témoin : la réponse à DA1 (ESC[?…c) a été reçue par le programme (sans elle, l'absence du reste ne prouve rien)" "$(hx "$HEX" has 1b5b3f)/$(hx "$HEX" re '63$')" "oui/oui"
assert_eq "T14.1 — l'entrée réinjectée dans le PTY est la réponse à DA1 SEULE (1b5b3f…63) : ni 1b50 (DCS) ni 1b5d (OSC)" "$(hx "$HEX" re '^1b5b3f([0-9a-f]{2})+63$')/dcs=$(hx "$HEX" has 1b50)/osc=$(hx "$HEX" has 1b5d)" "oui/dcs=non/osc=non"
assert_eq "T14.5 — témoin de l'espion : un appel délibéré à navigator.clipboard.writeText est compté" "$(rj "$H" 'j.clipTemoin')" "1"
assert_eq "T14.2 — presse-papiers : 0 appel (navigator.clipboard.*, document.execCommand) après OSC 52 écriture et lecture" "$(rj "$H" 'j.avant.clip+"/"+j.avant.exec')" "0/0"
assert_eq "T14.3 — sans clic : 0 window.open, 0 confirm" "$(rj "$H" 'j.avant.open.length+"/"+j.avant.confirm')" "0/0"
assert_eq "T14.4 — clic sur la cellule LIEN : un seul window.open('https://exemple.test/', '_blank', 'noopener'), 0 confirm" "cellule=$(rj "$H" 'j.cellule') $(rj "$H" 'JSON.stringify(j.apres.open)') confirm=$(rj "$H" 'j.apres.confirm')" 'cellule=true [["https://exemple.test/","_blank","noopener"]] confirm=0'

echo "=== M-* — mutants : chaque protection rougit sa sonde ==="
if mutant_eng ctrlc 's/^                vers_shell += donnees$/                vers_shell += donnees.replace(b"\\x03", b"")/'; then
  VF_XTERM_MS=6000 run_plein "$OUT" "$MUT_ENG" false
  assert_eq "M-CTRLC — le mutant retire 0x03 de l'entrée : SIGINT-RECU n'arrive jamais, T13.8 rouge" "$(rouge "sigint=$(rj "$PJ" 'j.sigint') debut_apres=$(rj "$PJ" 'j.debutApres')" "sigint=true debut_apres=false")" "rouge"
else sans_effet "M-CTRLC"; fi
if mutant dcs vf-cockpit-terminal-client.mjs "s|term.parser.registerDcsHandler({ intermediates: '\$', final: 'q' }, () => true);||"; then
  run_hostile "$MUT_OUT"
  assert_eq "M-DCS — gestionnaire DECRQSS non enregistré : xterm répond ESC P (1b50) dans l'entrée du PTY, T14.1 rouge (mesure de A2 : le gestionnaire du client est ce qui l'empêche)" "$(rouge "dcs=$(hx "$WORK/hostile.hex" has 1b50)" "dcs=non")" "rouge"
else sans_effet "M-DCS"; fi
if mutant winopt vf-cockpit-terminal-client.mjs 's|windowOptions: {}|windowOptions: { getWinTitle: true, getWinSizeChars: true, getWinSizePixels: true, getCellSizePixels: true }|'; then
  run_hostile "$MUT_OUT"
  assert_eq "M-WINOPT — windowOptions ouvertes (getWinTitle, getWinSizeChars…) : CSI 18t reçoit la réponse ESC [ 8 ; (1b5b383b) dans l'entrée du PTY, T14.1 rouge (le xterm.js livré ne répond pas à 21t même ouvert : 18t est la sonde qui discrimine)" "$(rouge "taille=$(hx "$WORK/hostile.hex" has 1b5b383b)" "taille=non")" "rouge"
else sans_effet "M-WINOPT"; fi
if mutant clip vf-cockpit-terminal-client.mjs "s|const fit = new FitAddon.FitAddon();|const fit = new FitAddon.FitAddon(); term.parser.registerOscHandler(52, (d) => { navigator.clipboard.writeText(d); return true; });|"; then
  run_hostile "$MUT_OUT"
  assert_eq "M-CLIP — un gestionnaire OSC 52 écrit dans navigator.clipboard : 1 appel compté, T14.2 rouge" "$(rouge "clip=$(rj "$HJ" 'j.avant.clip')" "clip=0")" "rouge"
else sans_effet "M-CLIP"; fi
if mutant lien vf-cockpit-terminal-client.mjs 's|^    linkHandler: .*$||'; then
  run_hostile "$MUT_OUT"
  assert_eq "M-LIEN — linkHandler retiré (comportement natif de xterm) : le clic appelle confirm, T14.4 rouge" "$(rouge "confirm=$(rj "$HJ" 'j.apres&&j.apres.confirm')" "confirm=0")" "rouge"
else sans_effet "M-LIEN"; fi

vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
