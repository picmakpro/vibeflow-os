#!/usr/bin/env bash
# test-cockpit-lancer-processus.sh — processus de Q : proposition, armement, lancement, refus (LANC-04 à LANC-07, LANC-09, LANC-10 ;
# P72-D-01, D-02, D-10 à D-12, D-14, D-16). Un parent factice (écrit ici) joue le rôle de P : il lance le processus de Q de la SORTIE, lui envoie
# `init`, `cibles`, `proposition`, relève ses messages ; un client (terminal-aux.mjs) joue le rôle de la page Q. Vrai shell, faux `claude`.
#   Q0  témoin : parent, Q prête, amorçage, secret, flux de l'onglet A, invite, GET /etat   Q1  GET /proposition sans proposition, sans secret, Host faux
#   Q2  proposition valide : clés du contrat, quatre lignes, alphabet, UUID commun          Q3  hors liste : cible malformée, absente, verbe, compartiment hostile
#   Q4  POST /lancer avant armement : 425                                                    Q5  après armement : ligne à l'invite SANS retour chariot, puis Entrée du client
#   Q6  programme au premier plan : 409, 0 octet reçu, proposition conservée                 Q7  Origin de P : 403
#   Q8  refus : secret, onglet, Host, Origin absente, id inconnu, mode, champ ligne, corps trop grand
#   Q9  consommée une fois, page sans ligne                                                  Q10 POST /annuler       Q11 messages `lancee`
#   Q12 une proposition remplace la précédente                                               Q13 variante chat (relais)
#   M-* mutants (copies de la sortie) : M-ORIGINE-LANCER, M-ID-LIBRE, M-TEXTE-LIGNE, M-RETOUR-CHARIOT
# Chaque refus a son témoin positif ; aucune attente d'armement n'est une durée codée en dur (arme_apres_ms est lu). Exit 0 si tout passe, 1 sinon.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
libre() { local p i; for i in 1 2 3 4 5 6 7 8 9 10; do p="$(node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})")"; [ "$p" -ge 4600 ] && [ "$p" != 4456 ] && { echo "$p"; return; }; done; echo 0; }
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
ENG="$(cd "$SCRIPTS/../skills/cockpit-moteur" && pwd -P)"; TA="$HERE_T/terminal-aux.mjs"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; RUN="$WORK/run"; mkdir -p "$AUX" "$WORK/home" "$WORK/bin" "$WORK/fauxbin" "$RUN" "$WORK/temoins"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
export VF_COCKPIT_MODE_DIR="$WORK/etat"; unset XDG_CACHE_HOME # AUDC-B-05 : le mode retenu d'un lancement accepté va dans un dossier jetable, jamais dans le dossier d'état réel de l'utilisateur ni de la CI
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$(court "$3")]"; echo "     obtenu:  [$(court "$2")]"; FAIL=$((FAIL+1)); fi; }
court() { if [ "${#1}" -gt 300 ]; then printf '%s […] %s' "${1:0:140}" "${1: -140}"; else printf '%s' "$1"; fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [${2:0:300}]"; FAIL=$((FAIL+1)); fi; }
assert_not() { if [[ "$2" != *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     sous-chaîne interdite: [$3]"; echo "     obtenu:  [${2:0:300}]"; FAIL=$((FAIL+1)); fi; }

# ---- aides écrites par la suite (jamais dans le dépôt) ----
cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/chk.mjs" <<'JS'
// chk.mjs <cas> : verdict sur le corps JSON de GET /proposition (stdin) ; « ok » ou la première raison de rougir
import fs from 'node:fs';
let j; try { j = JSON.parse(fs.readFileSync(0, 'utf8')); } catch { console.log('corps non JSON'); process.exit(0); }
const MODES = ['default', 'acceptEdits', 'plan', 'herite'], ALPHA = /^[A-Za-z0-9 ._:/'-]+$/;
const uuidDe = (l) => { const m = /--session-id '([0-9a-f-]{36})'/.exec(l); return m ? m[1] : null; };
const cas = process.argv[2], chat = process.argv[3];
const verdict = () => {
  if (j.etat !== 'en-attente') return `etat ${j.etat}`;
  const cles = Object.keys(j).sort().join(',');
  const attendues = ['arme_apres_ms', 'avertissements', 'bloquants', 'duree_ms', 'etat', 'expire_ms', 'id', 'intention', 'lignes', 'mode_retenu', 'phase', 'verbe', 'ws'].concat(cas === 'chat' ? ['chat', 'lignes_chat'] : []).sort().join(',');
  if (cles !== attendues) return `clés ${cles}`;
  if (Object.keys(j.lignes).sort().join(',') !== [...MODES].sort().join(',')) return 'lignes : modes';
  if (!Number.isInteger(j.arme_apres_ms) || j.arme_apres_ms <= 0 || !Number.isInteger(j.expire_ms) || j.expire_ms <= 0 || !Number.isInteger(j.duree_ms) || j.duree_ms < j.expire_ms) return 'arme_apres_ms / expire_ms / duree_ms';
  const jeux = cas === 'chat' ? [j.lignes, j.lignes_chat] : [j.lignes];
  for (const jeu of jeux) {
    if (Object.keys(jeu).sort().join(',') !== [...MODES].sort().join(',')) return 'jeu de lignes : modes';
    if (new Set(MODES.map((m) => uuidDe(jeu[m]))).size !== 1 || !uuidDe(jeu.herite)) return 'UUID de session non commun';
    for (const m of MODES) {
      const l = jeu[m];
      if (typeof l !== 'string' || l.length > 400 || !ALPHA.test(l) || !l.startsWith("claude --session-id '") || !l.endsWith("'")) return `ligne ${m} hors alphabet, longueur ou forme`;
      if (/touch|\$\(|;/.test(l)) return `ligne ${m} porte un texte hostile`;
      const avec = l.includes('--permission-mode');
      if (m === 'herite' ? avec : !l.includes(`--permission-mode '${m}'`)) return `ligne ${m} : drapeau de mode`;
    }
  }
  if (new Set([uuidDe(j.lignes.herite)].concat(cas === 'chat' ? [uuidDe(j.lignes_chat.herite)] : [])).size !== 1) return 'session de lignes_chat différente';
  if (cas === 'chat') {
    if (j.chat !== true) return 'chat non booléen vrai';
    for (const m of MODES) { const l = j.lignes_chat[m]; if (!l.includes(`-r '${chat}'`) || !l.includes('--fork-session')) return `lignes_chat ${m} sans reprise`; if (j.lignes[m].includes(chat) || j.lignes[m].includes('--fork-session')) return `lignes ${m} porte le chat`; }
  }
  return 'ok';
};
console.log(verdict());
JS
cat > "$AUX/apres.mjs" <<'JS'
// apres.mjs <fichier> <marque> <sous-chaine> <ms> : TROUVE si la sous-chaîne paraît APRÈS la dernière occurrence de la marque, sinon ABSENT
import fs from 'node:fs';
const [, , f, marque, sous, ms] = process.argv; const fin = Date.now() + Number(ms);
for (;;) {
  let t = ''; try { t = fs.readFileSync(f).toString('latin1'); } catch {}
  const i = t.lastIndexOf(marque);
  if (i >= 0 && t.indexOf(sous, i + marque.length) >= 0) { console.log('TROUVE'); process.exit(0); }
  if (Date.now() >= fin) { console.log('ABSENT'); process.exit(1); }
  await new Promise((r) => setTimeout(r, 50));
}
JS
cat > "$AUX/parent.mjs" <<'JS'
// parent.mjs <sortie> <lab> <moteur> <travail> : joue P (PL-10.1). Lance le processus de Q de la sortie (IPC json), lui envoie `init`, consigne ses messages
// (sauf `pret`) ; serveur de commande 127.0.0.1 : POST /send (retransmet le corps JSON), GET /recus, POST /stop. Première ligne de sortie : PRET <Q> <commande> <P>.
import { fork } from 'node:child_process'; import http from 'node:http'; import net from 'node:net';
const [, , sortie, lab, moteur, travail] = process.argv;
const libre = () => new Promise((r) => { const s = net.createServer().listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const portP = await libre(); const recus = []; let portQ = null, portC = null;
const enfant = fork(sortie + '/vf-cockpit-terminal-processus.mjs', [], { env: process.env, cwd: lab, stdio: ['inherit', 'inherit', 'inherit', 'ipc'], serialization: 'json' });
const pret = () => { if (portQ && portC) console.log(`PRET ${portQ} ${portC} ${portP}`); };
enfant.on('message', (m) => { if (m && m.t === 'pret') { portQ = m.port; pret(); } else recus.push(m); });
enfant.send({ t: 'init', engineDir: moteur, root: lab, here: sortie, jetons: [], portP, envOrigine: { ...process.env, PATH: travail + '/fauxbin:' + process.env.PATH } });
const srv = http.createServer((req, res) => { let b = ''; req.on('data', (c) => { b += c; }); req.on('end', () => {
  if (req.url === '/send' && req.method === 'POST') { try { enfant.send(JSON.parse(b)); res.writeHead(204); } catch { res.writeHead(400); } res.end(); }
  else if (req.url === '/recus') { res.writeHead(200, { 'Content-Type': 'application/json' }); res.end(JSON.stringify(recus)); }
  else if (req.url === '/stop') { res.writeHead(204); res.end(); try { enfant.send({ t: 'arret' }); } catch {} setTimeout(() => process.exit(0), 3500); }
  else { res.writeHead(404); res.end(); } }); });
srv.listen(0, '127.0.0.1', () => { portC = srv.address().port; pret(); });
enfant.on('exit', () => setTimeout(() => process.exit(0), 200));
JS
# shell de test (PL-10.5) : le PID enregistré reste celui du shell (exec) ; invite VFP> ; faux claude dans le PATH (PL-10.7)
cat > "$WORK/bin/rc" <<SH
PS1='VFP> '; unset PROMPT_COMMAND; bind 'set enable-bracketed-paste off' 2>/dev/null
PATH="$WORK/fauxbin:\$PATH"; export PATH
SH
cat > "$WORK/bin/shell-test" <<SH
#!/bin/sh
echo \$\$ > "$RUN/shell.pid"
exec /bin/bash --rcfile "$WORK/bin/rc" -i
SH
cat > "$WORK/fauxbin/claude" <<SH
#!/bin/sh
printf '%s\\0' "\$@" > "$RUN/argv.tmp" && mv "$RUN/argv.tmp" "$RUN/argv"
SH
chmod +x "$WORK/bin/shell-test" "$WORK/fauxbin/claude"; cp "$HERE_T/temoins/hostile.py" "$WORK/temoins/hostile.py"
export SHELL="$WORK/bin/shell-test"

rq() { node "$TA" req "$@"; }
sta() { rq "$@" | sed -n 1p; }
evj() { node "$AUX/ev.mjs" "$1"; }
mklab() { local L="$1" B="$1/.planning"; mkdir -p "$L/src" "$B/phases/01-socle"; printf 'export const u = 1;\n' > "$L/src/u.js"
  printf -- '## Phases\n\n- [x] **Phase 1: Socle** - premier jet\n\n### Phase 1: Socle\n**Goal**: Poser le socle\n' > "$B/ROADMAP.md"
  printf -- '---\nstatus: executing\ncurrent_phase: 1\nmilestone: v1.0 MVP\n---\n' > "$B/STATE.md"
  printf -- '---\nwave: 1\nfiles_modified: [src/u.js]\n---\n<objective>Poser le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  node "$SCRIPTS/vf-cockpit.mjs" build --lab "$L" > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"; }
mutant() { # mutant <nom> <expression-sed>... -> MUT_OUT ; code 1 si la cible manque ou si la copie n'a pas changé (« mutant sans effet »)
  local d="$WORK/mut-$1" f e; local a; a=(); shift; rm -rf "$d"; mkdir -p "$d"; cp -R "$LAB/.planning" "$d/.planning"; cp -R "$LAB/.vibeflow" "$d/.vibeflow"
  MUT_OUT="$d/.vibeflow/cockpit"; f="$MUT_OUT/vf-cockpit-terminal-processus.mjs"; [ -f "$f" ] || return 1
  for e in "$@"; do a+=(-e "$e"); done
  cp "$f" "$f.orig"; sed -i.bak "${a[@]}" "$f"; local r=0; cmp -s "$f" "$f.orig" && r=1; rm -f "$f.orig" "$f.bak"; return $r
}
LAB="$WORK/lab"; mklab "$LAB"; OUT="$LAB/.vibeflow/cockpit"

# ---- manche : un parent sur la sortie voulue, amorçage, flux de l'onglet A, invite ----
NM=0; QP=0; CP=0; PP=0; SECRET=""; PARENT=""; FPID=""; FLUX=""; ARME=2000
manche_debut() { # manche_debut <sortie> -> QP CP PP SECRET PARENT FPID FLUX
  NM=$((NM+1)); local s="$1" am="$WORK/amorce.$NM" po="$WORK/parent-$NM.out"; FLUX="$WORK/flux-$NM.out"; : > "$FLUX"; rm -f "$RUN/argv" "$RUN/argv.tmp" "$RUN/recept.hex"; mkdir -p "$s/.cache"
  node -e "console.log(require('crypto').randomBytes(24).toString('hex'))" > "$am.tmp"; (umask 077; tr -d '\n' < "$am.tmp" > "$s/.cache/terminal-amorce"; tr -d '\n' < "$am.tmp" > "$am")
  VF_COCKPIT_LANCER_ARME_MS=$ARME node "$AUX/parent.mjs" "$s" "$LAB" "$ENG" "$WORK" > "$po" 2>&1 < /dev/null & PARENT=$!; PIDS+=($PARENT)
  for _ in $(seq 1 100); do grep -q '^PRET ' "$po" 2>/dev/null && break; sleep 0.1; done
  read -r _ QP CP PP < <(grep '^PRET ' "$po" | head -1); QP="${QP:-0}"; CP="${CP:-0}"; PP="${PP:-0}"
  SECRET="$(node "$TA" amorcer "$QP" "$am" | sed -n 2p)"
  node "$TA" flux "$QP" "$SECRET" A "$FLUX" 150000 --taille 24x400 > "$WORK/flux-$NM.log" 2>&1 & FPID=$!; PIDS+=($FPID)
  node "$TA" attendre "$FLUX" 'VFP> ' 10000 > /dev/null
}
manche_fin() { vf_hyg_stop "$FPID"; vf_hyg_stop "$PARENT"; for _ in $(seq 1 30); do [ -z "$(vf_hyg_vivants)" ] && break; sleep 0.2; done; }
pget() { rq "$QP" GET /proposition --sans-origin --entete 'sec-fetch-site:same-origin' --secret "$SECRET" --onglet A "$@"; }
pbody() { pget "$@" | sed '1,2d'; }
plx() { local sec="$1" ong="$2" corps="$3"; shift 3; rq "$QP" POST /lancer --secret "$sec" --onglet "$ong" --corps "$corps" "$@"; } # plx <secret> <onglet> <corps> [options rq] -> statut puis en-têtes puis corps
pl() { local c="$1"; shift; plx "$SECRET" A "$c" "$@" | sed -n 1p; }
lj() { printf '{"id":"%s","mode":"%s"%s}' "$1" "$2" "${3:-}"; }
envoyer() { rq "$CP" POST /send --corps "$1" | sed -n 1p; sleep 0.2; }
prop() { printf '{"t":"proposition","cible":"%s","verbe":"%s","bloquants":[],"avertissements":[]%s}' "$1" "$2" "${3:-}"; }
recus() { rq "$CP" GET /recus | sed '1,2d'; }
nlancee() { recus | evj 'j.filter((m) => m.t === "lancee").length'; }
tflux() { wc -c < "$FLUX" | tr -d ' '; }
inchange() { local av="$1"; sleep 1; [ "$(tflux)" = "$av" ] && echo inchange || echo "change ($av -> $(tflux))"; }
attente_arme() { sleep "$(node -e "console.log(($1 + 300) / 1000)")"; } # attente = arme_apres_ms lu + marge : jamais une durée codée en dur
CIBLES='{"t":"cibles","cibles":[{"id":"ph-1","kind":"phase","verbe":"cadrer","verbes":["cadrer","planifier","executer"],"phase":"1","ws":"fiabilite"},{"id":"ph-9","kind":"phase","verbe":"cadrer","verbes":["cadrer"],"phase":"1","ws":"a$(touch M)"},{"id":"72;touch M","kind":"phase","verbe":"cadrer","verbes":["cadrer"],"phase":"1","ws":"fiabilite"}]}'
ARGV_ATT() { printf '%s' "--session-id|$1|-n|vf-phase-1-fiabilite|/vf-dev Cadre la Phase 1 du compartiment fiabilite|"; }
attendre_argv() { for _ in $(seq 1 80); do [ -f "$RUN/argv" ] && break; sleep 0.1; done; [ -f "$RUN/argv" ] && tr '\0' '|' < "$RUN/argv" || echo absent; }

echo "=== Q0 — témoin : parent factice, Q prête, amorçage, secret, flux, invite, /etat ==="
manche_debut "$OUT"
assert_eq "Q0 — Q répond « pret » (port du parent factice, de commande et de Q distincts, jamais 4456, tous au moins 4600)" "$([ "$QP" -ge 4600 ] && [ "$PP" -ge 4600 ] && [ "$QP" != 4456 ] && [ "$QP" != "$PP" ] && echo oui || echo "non Q=$QP P=$PP")" "oui"
assert_eq "Q0 — l'échange de l'amorçage rend un secret de 64 hexadécimaux" "$([[ "$SECRET" =~ ^[0-9a-f]{64}$ ]] && echo oui || echo "non : ${SECRET:-vide}")" "oui"
assert_eq "Q0 — le flux de l'onglet A atteint l'invite VFP> et GET /etat rend « vivante »" "$(grep -c 'VFP> ' "$FLUX" | tr -d ' ' | sed 's/^[1-9][0-9]*$/invite/') $(node "$TA" etat "$QP" "$SECRET" | sed '1,2d' | evj 'j.session')" "invite vivante"
SHPID="$(cat "$RUN/shell.pid" 2>/dev/null)"
assert_eq "Q0 — le PID enregistré est celui du shell lui-même (exec), premier plan au repos = ce groupe" "$([ -n "$SHPID" ] && [ "$(ps -o pgid= -p "$SHPID" | tr -d ' ')" = "$SHPID" ] && echo oui || echo "non ($SHPID)")" "oui"

echo "=== Q1 — GET /proposition sans proposition ==="
assert_eq "Q1 — sans proposition : 200 et {\"etat\":\"aucune\"}" "$(pget | sed -n 1p) $(pbody)" '200 {"etat":"aucune"}'
assert_eq "Q1 — témoin positif (200 ci-dessus) puis : Origin de Q sans secret 401 ; Host localhost 403" "$(pget | sed -n 1p) $(rq "$QP" GET /proposition --onglet A | sed -n 1p) $(pget --host "localhost:$QP" | sed -n 1p)" "200 401 403"
assert_eq "Q1 — avec l'Origin de Q et le secret, sans Sec-Fetch-Site : 200 (comme GET /etat)" "$(rq "$QP" GET /proposition --secret "$SECRET" --onglet A | sed -n 1p)" "200"
assert_eq "Q1 — sans Origin ni Sec-Fetch-Site : 403" "$(rq "$QP" GET /proposition --sans-origin --secret "$SECRET" --onglet A | sed -n 1p)" "403"

echo "=== Q3 — hors liste : cible malformée, absente, verbe hors liste, compartiment hostile ==="
SZ="$(tflux)"; envoyer "$CIBLES" > /dev/null
R3=""; for cv in '72;touch M|cadrer' 'ph-9999|cadrer' 'ph-1|verifier' 'ph-9|cadrer'; do envoyer "$(prop "${cv%%|*}" "${cv##*|}")" > /dev/null; R3="$R3 $(pbody)"; done
assert_eq "Q3 — quatre propositions hors liste (cible 72;touch M, cible absente, verbe hors verbes, compartiment a\$(touch M)) : GET reste aucune" "$R3" ' {"etat":"aucune"} {"etat":"aucune"} {"etat":"aucune"} {"etat":"aucune"}'
assert_eq "Q3 — le flux du terminal n'a reçu aucun octet" "$(inchange "$SZ")" "inchange"
envoyer "$(prop ph-1 cadrer ',"ligne":"claude --session-id \u0027x\u0027 ; touch M","intention":"$(touch M)"')" > /dev/null
assert_eq "Q2 — une clé en trop dans la proposition (ligne, intention hostiles) : refusée ou sans le texte injecté dans les lignes" "$(pbody | evj 'j.etat === "aucune" || (j.etat === "en-attente" && !/touch|\$\(/.test(JSON.stringify(j.lignes)))')" "true"

echo "=== Q2 / Q4 — proposition valide, puis POST /lancer avant armement ==="
envoyer "$(prop ph-1 cadrer)" > /dev/null
B2="$(pbody)"; S425="$(pl "$(lj "$(printf '%s' "$B2" | evj 'j.id')" herite)")"; ID="$(printf '%s' "$B2" | evj 'j.id')"
assert_eq "Q2 — proposition valide : clés du contrat §4, quatre lignes dans l'alphabet, UUID commun, herite sans --permission-mode, trois autres avec leur mode" "$(printf '%s' "$B2" | node "$AUX/chk.mjs" std)" "ok"
ARME_LU="$(printf '%s' "$B2" | evj 'j.arme_apres_ms')"
assert_eq "Q4 — arme_apres_ms lu : au moins 400 ms (sinon la sonde 425 est indécidable)" "$([ "${ARME_LU:-0}" -ge 400 ] 2>/dev/null && echo oui || echo "non (${ARME_LU:-vide})")" "oui"
SZ="$(tflux)"
assert_eq "Q4 — avant armement : POST /lancer rend 425, la proposition reste en attente, le flux est inchangé" "$S425 $(pbody | evj 'j.etat') $(inchange "$SZ")" "425 en-attente inchange"
LH="$(printf '%s' "$B2" | evj 'j.lignes.herite')"; UU="$(printf '%s' "$LH" | sed -E "s/.*--session-id '([0-9a-f-]{36})'.*/\1/")"; LH="${LH:-LIGNE-ABSENTE-DU-CORPS}"; [ "${UU:-$LH}" != "$LH" ] || UU="UUID-ABSENT" # un motif vide trouverait tout : jamais de vert à vide
attente_arme "${ARME_LU:-2000}"

echo "=== Q7 / Q8 — Origin de P et refus, sur la proposition armée ==="
SZ="$(tflux)"
assert_eq "Q7 — Origin de P (secret, onglet A, id valides, armée) : 403, la proposition reste en attente, le flux est inchangé" "$(pl "$(lj "$ID" herite)" --origin "http://127.0.0.1:$PP") $(pbody | evj 'j.etat') $(inchange "$SZ")" "403 en-attente inchange"
SZ="$(tflux)"
R8="$(plx "$(printf 'f%.0s' $(seq 1 64))" A "$(lj "$ID" herite)" | sed -n 1p) $(plx "$SECRET" B "$(lj "$ID" herite)" | sed -n 1p) $(pl "$(lj "$ID" herite)" --host "localhost:$QP") $(pl "$(lj "$ID" herite)" --sans-origin) $(pl "$(lj inconnu herite)") $(pl "$(lj "$ID" bypassPermissions)") $(pl "$(lj "$ID" herite ',"ligne":"claude --session-id \u0027x\u0027 -n \u0027y\u0027 \u0027HOSTILEZ9\u0027"')") $(pl "$(lj "$ID" herite)" --corps-octets 600)"
assert_eq "Q8 — secret erroné 401 · autre onglet 409 · Host localhost 403 · sans Origin 403 · id inconnu 404 · mode hors liste 400 · champ ligne 400 · corps de 600 octets 413" "$R8" "401 409 403 403 404 400 400 413"
assert_eq "Q8 — aucun octet au PTY et la proposition armée reste en attente (le témoin positif suit : Q5)" "$(inchange "$SZ") $(pbody | evj 'j.etat + " " + (j.id === "'"$ID"'")')" "inchange en-attente true"
assert_eq "Q11 — aucun message « lancee » sur Q4, Q7, Q8" "$(nlancee)" "0"

echo "=== Q5 — lancement : la ligne à l'invite SANS retour chariot, puis l'Entrée du client ==="
S204="$(pl "$(lj "$ID" herite)")"
assert_eq "Q5 — après armement : POST /lancer {id, mode:herite} rend 204 (témoin positif de Q7 et de Q8 : même appel, Origin de Q)" "$S204" "204"
assert_eq "Q5 — la ligne herite EXACTE de GET /proposition apparaît à l'invite" "$(node "$TA" attendre "$FLUX" "$LH" 8000)" "TROUVE"
sleep 2; assert_eq "Q5 — après 2 s sans geste : le faux claude n'a pas tourné (argv absent)" "$([ -e "$RUN/argv" ] && echo présent || echo absent)" "absent"
for _ in $(seq 1 30); do [ "$(nlancee)" = 1 ] && break; sleep 0.1; done
assert_eq "Q11 — exactement un message « lancee » pour ce lancement, aux clés t, cible, verbe, session, at ; session = l'UUID de la ligne écrite" "$(nlancee) $(recus | evj 'Object.keys(j.filter((m) => m.t === "lancee")[0] || {}).sort().join()') $(recus | evj 'j.filter((m) => m.t === "lancee").map((m) => m.session === "'"$UU"'" && m.cible === "ph-1" && m.verbe === "cadrer").join()')" "1 at,cible,session,t,verbe true"
node "$TA" entree "$QP" "$SECRET" A '\r' > /dev/null
assert_eq "Q5 — le client tape Entrée : le faux claude a tourné, argv exact (UUID de la ligne, -n, intention, aucun --permission-mode)" "$(attendre_argv)" "$(ARGV_ATT "$UU")"

echo "=== Q9 — consommée une fois ==="
SZ="$(tflux)"
assert_eq "Q9 — second POST /lancer du même id : 404 ; GET /proposition : aucune" "$(pl "$(lj "$ID" herite)") $(pbody)" '404 {"etat":"aucune"}'
PG="$(rq "$QP" GET '/?theme=light' --sans-origin)"
assert_eq "Q9 — témoin : la page de Q (thème clair) est servie en entier" "$([ "$(printf '%s' "$PG" | wc -c | tr -d ' ')" -gt 1000 ] && echo oui || echo non) $(printf '%s' "$PG" | sed -n 1p)" "oui 200"
assert_eq "Q9 — la page ne contient ni la ligne ni l'UUID de session ; GET /proposition rend encore aucune" "$(printf '%s' "$PG" | grep -c -F -e 'claude --session-id' -e "$UU") $(pbody)" '0 {"etat":"aucune"}'

echo "=== Q12 — une seconde proposition remplace la première ==="
envoyer "$(prop ph-1 planifier)" > /dev/null; ID1="$(pbody | evj 'j.id')"; envoyer "$(prop ph-1 executer)" > /dev/null; B12="$(pbody)"; ID2="$(printf '%s' "$B12" | evj 'j.id')"
assert_eq "Q12 — GET montre la seconde (verbe executer, autre id) ; l'ancien id rend 404 ; la seconde reste en attente" "$(printf '%s' "$B12" | evj 'j.verbe') $([ -n "$ID1" ] && [ "$ID1" != "$ID2" ] && echo autre) $(pl "$(lj "$ID1" herite)") $(pbody | evj 'j.id === "'"$ID2"'"')" "executer autre 404 true"

echo "=== Q10 — POST /annuler ==="
ann() { rq "$QP" POST /annuler --secret "$SECRET" --onglet A --corps "{\"id\":\"$1\"}" "${@:2}" | sed -n 1p; }
assert_eq "Q10 — Origin de P : 403 et la proposition reste en attente ; id inconnu : 404 (témoin : la proposition existe)" "$(ann "$ID2" --origin "http://127.0.0.1:$PP") $(pbody | evj 'j.etat') $(ann inconnu)" "403 en-attente 404"
annB() { rq "$QP" POST /annuler --secret "$SECRET" --onglet B --corps "{\"id\":\"$1\"}" | sed -n 1p; }
assert_eq "Q10b — un autre onglet (B), même muni du secret, ne peut pas annuler la proposition de l'onglet propriétaire (A) : 409 et elle reste en attente (même id)" "$(annB "$ID2") $(pbody | evj 'j.etat') $(pbody | evj 'j.id === "'"$ID2"'"')" "409 en-attente true"
assert_eq "Q10 — POST /annuler {id} : 204, puis GET rend aucune, puis le même id rend 404" "$(ann "$ID2") $(pbody) $(ann "$ID2")" '204 {"etat":"aucune"} 404'

echo "=== Q6 — programme au premier plan : 409, aucun octet, proposition conservée ==="
envoyer "$(prop ph-1 cadrer)" > /dev/null; B6="$(pbody)"; ID6="$(printf '%s' "$B6" | evj 'j.id')"; LH6="$(printf '%s' "$B6" | evj 'j.lignes.herite')"; LH6="${LH6:-LIGNE-ABSENTE-DU-CORPS}"
node "$TA" entree "$QP" "$SECRET" A "python3 -I $WORK/temoins/hostile.py --recepteur $RUN/recept.hex 8\\r" > /dev/null
PRET6="$(node "$TA" attendre "$FLUX" RECEPTEUR-PRET 10000)"; REC=""; for _ in $(seq 1 30); do REC="$(command pgrep -P "$SHPID" | head -1)"; [ -n "$REC" ] && break; sleep 0.1; done
PGREC="$(ps -o pgid= -p "${REC:-0}" 2>/dev/null | tr -d ' ')"
assert_eq "Q6 — témoin : le récepteur d'entrée brute est prêt et occupe le premier plan (groupe différent du shell)" "$PRET6 $([ -n "$PGREC" ] && [ "$PGREC" != "$SHPID" ] && echo premier-plan || echo "non (${PGREC:-aucun})")" "TROUVE premier-plan"
attente_arme "$(printf '%s' "$B6" | evj 'j.arme_apres_ms')"; S409="$(pl "$(lj "$ID6" herite)")"; VIVANT="$(kill -0 "${REC:-0}" 2>/dev/null && echo vivant || echo mort)"
assert_eq "Q6 — POST /lancer rend 409, le programme vit encore, la proposition est toujours en attente (même id), aucun message « lancee » de plus" "$S409 $VIVANT $(pbody | evj 'j.id === "'"$ID6"'"') $(nlancee)" "409 vivant true 1"
FIN6="$(node "$TA" attendre "$FLUX" RECEPTEUR-FIN 15000)"
assert_eq "Q6 — après la fin de sa fenêtre : le fichier hexadécimal du récepteur existe et est VIDE (aucun octet : ni la ligne, ni Ctrl-C)" "$FIN6 $([ -f "$RUN/recept.hex" ] && [ ! -s "$RUN/recept.hex" ] && echo vide || echo "non : $(cat "$RUN/recept.hex" 2>/dev/null | cut -c1-60)")" "TROUVE vide"
INV6="$(node "$AUX/apres.mjs" "$FLUX" RECEPTEUR-FIN 'VFP> ' 10000)"
assert_eq "Q6 — après la fin du programme et le retour de l'invite : un nouveau POST /lancer rend 204 et la ligne paraît" "$INV6 $(pl "$(lj "$ID6" herite)") $(node "$TA" attendre "$FLUX" "$LH6" 8000) $(nlancee)" "TROUVE 204 TROUVE 2"

echo "=== Q13 — variante chat (relais) ==="
CHAT="3fa85f64-5717-4562-b3fc-2c963f66afa6"
envoyer "$(prop ph-1 cadrer)" > /dev/null; IDA="$(pbody | evj 'j.id')"; SZ="$(tflux)"
assert_eq "Q13 — chat:true sans conversation : 400 ; chat non booléen : 400 ; flux inchangé (témoin : la proposition est en attente)" "$(pbody | evj 'j.etat') $(pl "$(lj "$IDA" herite ',"chat":true')") $(pl "$(lj "$IDA" herite ',"chat":"oui"')") $(inchange "$SZ")" "en-attente 400 400 inchange"
envoyer "$(prop ph-1 cadrer ",\"chat\":\"$CHAT\"")" > /dev/null; B13="$(pbody)"; ID13="$(printf '%s' "$B13" | evj 'j.id')"
assert_eq "Q13 — GET porte chat:true et lignes_chat (quatre modes : UUID de session commun, reprise -r et --fork-session) ; les lignes standard n'en portent aucun" "$(printf '%s' "$B13" | node "$AUX/chk.mjs" chat "$CHAT")" "ok"
LC="$(printf '%s' "$B13" | evj 'j.lignes_chat.herite' 2>/dev/null)"; LC="${LC:-LIGNE-CHAT-ABSENTE}"; attente_arme "$(printf '%s' "$B13" | evj 'j.arme_apres_ms')"
assert_eq "Q13 — POST {id, mode:herite, chat:true} : 204 et la ligne de lignes_chat.herite figure à l'invite" "$(pl "$(lj "$ID13" herite ',"chat":true')") $(node "$TA" attendre "$FLUX" "$LC" 8000)" "204 TROUVE"
for _ in $(seq 1 30); do [ "$(nlancee)" = 3 ] && break; sleep 0.1; done
assert_eq "Q11 — exactement un message « lancee » par lancement réussi (trois au total) et aucun sur les refus" "$(nlancee)" "3"
manche_fin

# ---- mutants : chacun joué sur une copie de la sortie, résultat exact attendu du défaut (la sonde rougit pour la bonne raison) ----
mut_manche() { # mut_manche <sortie> -> ID_M, LH_M après armement
  manche_debut "$1"; envoyer "$CIBLES" > /dev/null; envoyer "$(prop ph-1 cadrer)" > /dev/null
  local b; b="$(pbody)"; ID_M="$(printf '%s' "$b" | evj 'j.id')"; LH_M="$(printf '%s' "$b" | evj 'j.lignes.herite' 2>/dev/null)"; LH_M="${LH_M:-LIGNE-ABSENTE-DU-CORPS}"; attente_arme "$(printf '%s' "$b" | evj 'j.arme_apres_ms')"
}
echo "=== M-ORIGINE-LANCER — la route /lancer admet l'Origin de P (Q7) ==="
if mutant orig "s#else if (o !== origineQ())#else if (o !== origineQ() \&\& !(url.pathname === '/lancer' \&\& o === 'http://127.0.0.1:' + portP))#"; then
  mut_manche "$MUT_OUT"; R="$(pl "$(lj "$ID_M" herite)" --origin "http://127.0.0.1:$PP")"
  assert_eq "M-ORIGINE-LANCER — sous le mutant, l'Origin de P est acceptée (204 au lieu de 403) : Q7 rougit" "$R" "204"; manche_fin
else assert_eq "M-ORIGINE-LANCER — mutant sans effet (ancre absente ou inchangée)" "sans effet" "effet"; fi
echo "=== M-ID-LIBRE — l'id du client est ignoré (Q8) ==="
if mutant idlibre "s#const idDemande = demande.id;#const idDemande = lireProposition().id;#"; then
  mut_manche "$MUT_OUT"; R="$(pl "$(lj inconnu herite)")"
  assert_eq "M-ID-LIBRE — sous le mutant, un id inconnu consomme quand même la proposition (204 au lieu de 404) : Q8 rougit" "$R" "204"; manche_fin
else assert_eq "M-ID-LIBRE — mutant sans effet (ancre absente ou inchangée)" "sans effet" "effet"; fi
echo "=== M-TEXTE-LIGNE — le client fournit la ligne (Q8) ==="
if mutant texte "s#Object.keys(o).every((k) => cles.includes(k))#true#" "s#const ligneQ = r.ligne;#const ligneQ = demande.ligne || r.ligne;#"; then
  mut_manche "$MUT_OUT"; R="$(pl "$(lj "$ID_M" herite ',"ligne":"claude --session-id \u0027x\u0027 -n \u0027y\u0027 \u0027HOSTILEZ9\u0027"')")"
  assert_eq "M-TEXTE-LIGNE — sous le mutant, le champ ligne est accepté (204) et le texte du client arrive à l'invite : Q8 rougit" "$R $(node "$TA" attendre "$FLUX" HOSTILEZ9 6000)" "204 TROUVE"; manche_fin
else assert_eq "M-TEXTE-LIGNE — mutant sans effet (ancre absente ou inchangée)" "sans effet" "effet"; fi
echo "=== M-RETOUR-CHARIOT — la ligne part avec un retour chariot (Q5) ==="
if mutant cr "s#sessions.lancer(ligneQ, onglet)#sessions.lancer(ligneQ + '\\\\r', onglet)#"; then
  mut_manche "$MUT_OUT"; R="$(pl "$(lj "$ID_M" herite)")"
  assert_eq "M-RETOUR-CHARIOT — sous le mutant, l'assistant refuse la ligne (400) et elle n'arrive pas à l'invite : Q5 rougit" "$R $(node "$TA" attendre "$FLUX" "$LH_M" 3000)" "400 ABSENT"; manche_fin
else assert_eq "M-RETOUR-CHARIOT — mutant sans effet (ancre absente ou inchangée)" "sans effet" "effet"; fi

echo "=== M-ANNULER-PROPRIETAIRE — la garde du propriétaire de POST /annuler est retirée (Q10b) ==="
if mutant annprop "s#if (onglet !== proprietaire) return refus(res, 409);##"; then
  mut_manche "$MUT_OUT"; R="$(annB "$ID_M")"
  assert_eq "M-ANNULER-PROPRIETAIRE — sous le mutant, l'onglet B annule la proposition de l'onglet A (204 au lieu de 409) : Q10b rougit" "$R" "204"; manche_fin
else assert_eq "M-ANNULER-PROPRIETAIRE — mutant sans effet (ancre absente ou inchangée)" "sans effet" "effet"; fi

echo "=== Q14 / M-STATUT-ECRITURE — la session répond le motif « ecriture » : POST /lancer rend 410 et la proposition est restituée ==="
# doublure de sessions.lancer posée sur la copie de la sortie (la même copie que les mutants) : l'assistant refuse l'écriture, sans octet au PTY
STUB_ECR="s#const w = await sessions.lancer(ligneQ, onglet);#const w = { ok: false, motif: 'ecriture' };#"
if mutant ecriture "$STUB_ECR"; then
  mut_manche "$MUT_OUT"; SZ="$(tflux)"; R="$(pl "$(lj "$ID_M" herite)")"
  assert_eq "Q14 — session doublée sur le motif ecriture : POST /lancer rend 410, la proposition est restituée (en attente, même id), aucun message « lancee », flux inchangé" "$R $(pbody | evj 'j.etat + " " + (j.id === "'"$ID_M"'")') $(nlancee) $(inchange "$SZ")" "410 en-attente true 0 inchange"; manche_fin
else assert_eq "Q14 — doublure sans effet (ancre absente ou inchangée)" "sans effet" "effet"; fi
if mutant ecriture-retire "$STUB_ECR" "s#, ecriture: 410 }# }#"; then
  mut_manche "$MUT_OUT"; R="$(pl "$(lj "$ID_M" herite)")"
  assert_eq "M-STATUT-ECRITURE — mapping ecriture retiré, même doublure : le motif devient inconnu, 400 au lieu de 410 : Q14 rougit" "$R" "400"; manche_fin
else assert_eq "M-STATUT-ECRITURE — mutant sans effet (ancre absente ou inchangée)" "sans effet" "effet"; fi

vf_hyg_assert
echo "Résultats : $PASS PASS, $FAIL FAIL"
[ $((PASS+FAIL)) -ge 40 ] || { echo "  ❌ FAIL — anti-vert-à-vide : moins de 40 assertions jouées"; exit 1; }
[ "$FAIL" -eq 0 ]
