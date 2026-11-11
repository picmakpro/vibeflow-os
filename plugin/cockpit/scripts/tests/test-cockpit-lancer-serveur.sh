#!/usr/bin/env bash
# test-cockpit-lancer-serveur.sh — assemblage du lancement côté serveur P : cibles, POST, canal vers Q, refus de LANC-03 dans le serveur réel
# (LANC-01 à LANC-04, LANC-08, LANC-10 ; P72-D-06, P72-D-09 à P72-D-12, P72-D-16, P72-D-17, P72-D-18).
#   S0-S3  sans `--terminal` : GET cibles = route inconnue, POST = route inconnue, page = disque + script de jeton, CSP de v2.75.0
#   P1     parité : motifs et verbes de l'export réel du gabarit = littéraux de 72-CONTRATS §2
#   A0-A4  avec drapeau et enfant factice : terminal actif, GET cibles, POST 202, messages IPC dans l'ordre, forme acceptée par le vrai état de Q
#   R1-R12 refus de LANC-03 et de LANC-04, chacun joué APRÈS son témoin positif (POST valide : 202, proposition +1)
#   F1-F3  fuites : flux SSE (témoin `hello`), journal, journal du serveur, server.json
#   U1-U2  injection du lanceur dans la page et empreinte dans la CSP · L1-L4 retour `lancee` (forme riche jusqu'à la carte) · E1-E3 états inertes et bloquants · C1-C2 chat
#   M-*    mutants (copies de la sortie, jamais le module) : M-SANS-DRAPEAU, M-LISTE-PAGE, M-TOKEN-CODE, M-LANCEE-LIBRE
# Chaque témoin négatif a son contrôle positif. Exit 0 si tout passe, 1 sinon.
set -uo pipefail
libre() { # port libre choisi à l'exécution, gardé : ≥ 4600 et différent de 4456 (FAIL nommé et sortie sinon)
  local p; p="$(node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})")"
  if [ "${p:-0}" -lt 4600 ] || [ "$p" = 4456 ]; then echo "  ❌ FAIL — port libre invalide [$p] (garde : ≥ 4600 et ≠ 4456)" >&2; kill -s TERM $$; fi
  echo "$p"
}
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
ENG="$SCRIPTS/../skills/cockpit-moteur"; TA="$HERE_T/terminal-aux.mjs"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home" "$WORK/fauxbin" "$WORK/pathsans"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
. "$(dirname "$0")/socle-serveur.sh"
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$(court "$3")]"; echo "     obtenu:  [$(court "$2")]"; FAIL=$((FAIL+1)); fi; }
court() { if [ "${#1}" -gt 300 ]; then printf '%s […] %s' "${1:0:140}" "${1: -140}"; else printf '%s' "$1"; fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [${2:0:300}]"; FAIL=$((FAIL+1)); fi; }
assert_not() { if [[ "$2" != *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     sous-chaîne interdite: [$3]"; echo "     obtenu:  [${2:0:300}]"; FAIL=$((FAIL+1)); fi; }

# ---- aides Node écrites dans $AUX (aucune dépendance) ----
cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/jl.mjs" <<'JS'
// jl.mjs <journal> <expression sur L> : lignes JSON du journal du faux enfant
import fs from 'node:fs'; const L = []; for (const l of fs.readFileSync(process.argv[2], 'utf8').split('\n')) { try { L.push(JSON.parse(l)); } catch {} }
const v = new Function('L', 'return (' + process.argv[3] + ')')(L); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/norm.mjs" <<'JS'
// norm.mjs : sortie de `terminal-aux req` sur l'entrée -> « statut|en-têtes triés sans date|corps »
import fs from 'node:fs'; const t = fs.readFileSync(0, 'utf8'); const i = t.indexOf('\n'), k = t.indexOf('\n', i + 1); let h = {};
try { h = JSON.parse(t.slice(i + 1, k)); } catch {} delete h.date;
console.log(t.slice(0, i) + '|' + JSON.stringify(Object.fromEntries(Object.entries(h).sort())) + '|' + t.slice(k + 1));
JS
cat > "$AUX/strip.mjs" <<'JS'
// strip.mjs <page servie> <fichier du disque> : « <nombre de scripts de jeton>:identique|different » une fois le seul script de jeton retiré
import fs from 'node:fs'; const [, , a, b] = process.argv; const s = fs.readFileSync(a, 'utf8'), d = fs.readFileSync(b, 'utf8'); const re = /<script>window\.VF_COCKPIT_SERVER=[^<]*<\/script>/;
console.log(`${s.split(new RegExp(re.source, 'g')).length - 1}:${s.replace(re, '') === d ? 'identique' : 'different'}`);
JS
cat > "$AUX/ptok.mjs" <<'JS'
import fs from 'node:fs'; const m = /VF_COCKPIT_SERVER=\{"token":"([0-9a-f]+)"/.exec(fs.readFileSync(process.argv[2], 'utf8')); console.log(m ? m[1] : '');
JS
cat > "$AUX/sse.mjs" <<'JS'
// sse.mjs <port> <jeton> <fichier> <ms> : capture bornée du flux SSE (jeton en paramètre d'adresse, comme serve.mjs l'admet)
import http from 'node:http'; import fs from 'node:fs'; const [, , port, jeton, fichier, ms] = process.argv; fs.writeFileSync(fichier, '');
const r = http.request({ host: '127.0.0.1', port: Number(port), path: `/api/vf/events?token=${jeton}`, headers: { Host: `127.0.0.1:${port}` }, agent: false }, (res) => { res.on('data', (c) => fs.appendFileSync(fichier, c)); });
r.on('error', () => {}); r.end(); setTimeout(() => { r.destroy(); process.exit(0); }, Number(ms));
JS
cat > "$AUX/stub-q.mjs" <<'JS'
// enfant factice de Q : remplace vf-cockpit-terminal-processus.mjs dans une COPIE de la sortie. STUB_LOG, STUB_PORT, STUB_MODE (defaut|lancee|lancee-mal).
// Le journal ne reçoit jamais l'environnement ni les jetons : « init » seul, les messages cibles et proposition entiers.
import fs from 'node:fs'; import crypto from 'node:crypto';
const { STUB_LOG, STUB_PORT, STUB_MODE = 'defaut' } = process.env;
export const CORPS_ENTREE_MAX = 262144; // exporté comme le vrai module : vf-cockpit-terminal.mjs le ré-exporte
const ecrire = (o) => fs.appendFileSync(STUB_LOG, JSON.stringify(o) + '\n');
fs.writeFileSync(STUB_LOG + '.pid', String(process.pid));
const lancee = (p, extra = {}) => ({ t: 'lancee', cible: p.cible, verbe: p.verbe, session: crypto.randomUUID(), at: Date.now(), ...extra });
process.on('message', (m) => {
  if (!m || typeof m !== 'object') return;
  if (m.t === 'init') { ecrire({ t: 'init' }); process.send({ t: 'pret', port: Number(STUB_PORT) }); }
  else if (m.t === 'jetons') ecrire({ t: 'jetons' });
  else if (m.t === 'arret') { ecrire({ t: 'arret' }); process.exit(0); }
  else if (m.t === 'cibles') ecrire(m);
  else if (m.t === 'proposition') {
    ecrire(m);
    if (STUB_MODE === 'lancee') setTimeout(() => { const l = lancee(m); ecrire({ uuid: l.session }); process.send(l); }, 100);
    if (STUB_MODE === 'lancee-mal') setTimeout(() => {
      const { at, ...sansAt } = lancee(m);
      for (const x of [lancee(m, { session: 'pas-un-uuid' }), { ...lancee(m), extra: 1 }, lancee(m, { verbe: 'deployer' }), sansAt, lancee(m, { cible: 'ph-9999' })]) process.send(x);
      ecrire({ envoye: 5 });
    }, 100);
  }
});
process.on('disconnect', () => process.exit(0));
JS
cat > "$AUX/harnais.mjs" <<'JS'
// harnais.mjs <mode> <sortie> <lab> [args] : importe les modules de la COPIE de la sortie ; une ligne JSON. Modes : p1, ui, l3, l4, q, e2, e3
import { pathToFileURL } from 'node:url'; import { Readable } from 'node:stream'; import crypto from 'node:crypto';
const [, , mode, sortie, lab, ...reste] = process.argv;
const imp = (f) => import(pathToFileURL(`${sortie}/${f}`).href);
const sortir = (o) => { console.log(typeof o === 'string' ? o : JSON.stringify(o)); process.exit(0); };
let G, U, L, C, P;
try { G = await imp('vf-cockpit-lancer-gabarit.mjs'); U = await imp('vf-cockpit-lancer-ui.mjs'); } catch { sortir('module introuvable : gabarit ou interface'); }
if (mode === 'p1') sortir({ phase: G.MOTIF_PHASE.source, comp: G.MOTIF_COMPARTIMENT.source, verbes: [...G.VERBES] });
if (mode === 'ui') { // ui <sortie> <lab> <page> <fichier csp>
  const fs = await import('node:fs'); const page = fs.readFileSync(reste[0], 'utf8'), csp = fs.readFileSync(reste[1], 'utf8').trim();
  const marque = U.injectionLancer({ indisponible: false }); const corps = /<script>([\s\S]*?)<\/script>/.exec(marque)?.[1] ?? '';
  const h = `'sha256-${crypto.createHash('sha256').update(corps).digest('base64')}'`;
  sortir(`balise=${marque.length > 100 && page.includes(marque) ? 'oui' : 'non'} empreinte=${corps && csp.includes(h) ? 'oui' : 'non'}`);
}
try { L = await imp('vf-cockpit-lancer.mjs'); C = await imp('vf-cockpit-lancer-canal.mjs'); P = await imp('vf-cockpit-lancer-post.mjs'); } catch { sortir('module introuvable : lanceur'); }
console.error = () => {};
const ptoken = 'a1'.repeat(16), UG = new URL('http://127.0.0.1:1234/api/vf/lancer/cibles'), UP = new URL('http://127.0.0.1:1234/api/vf/lancer');
const res0 = () => ({ headersSent: false, writeHead(c) { this.code = c; this.headersSent = true; }, end(b) { this.body = b; } });
const lire = async (lancer) => { const res = res0(); lancer.get({ method: 'GET', headers: {} }, res, UG); return JSON.parse(res.body); };
const posterRes = async (lancer, corps) => {
  const buf = Buffer.from(JSON.stringify(corps)), req = Readable.from([buf]); req.method = 'POST'; req.socket = { localPort: 1234 };
  req.headers = { host: '127.0.0.1:1234', origin: 'http://127.0.0.1:1234', [P.ENTETE_JETON]: ptoken, 'content-type': 'application/json', 'content-length': String(buf.length) };
  const res = res0(); await lancer.traiter(req, res, UP); return res;
};
const poster = async (lancer, corps) => (await posterRes(lancer, corps)).code;
const faux = (sur = {}) => { const sent = []; let abo = null; return { sent, pousser: (m) => abo && abo(m), canal: { etat: () => 'actif', envoyer: (m) => { sent.push(m); return true; }, abonner: (f) => { abo = f; }, claude: () => true, python3: () => true, ...sur } }; };
const lanceur = () => L.creerLancer({ root: lab, here: sortie, ptoken, log: () => {} });
const ph1 = (j) => j.cibles.find((x) => x.id === 'ph-1');
if (mode === 'l3' || mode === 'l4' || mode === 'q') {
  const f = faux(); C.definir(f.canal); const lancer = lanceur(); await lire(lancer); // premier get : publie la liste à Q
  const uuid = crypto.randomUUID();
  if (mode === 'q') {
    const Q = await imp('vf-cockpit-lancer-q.mjs'); const etat = Q.creerEtatLancer({ gabarit: G });
    const code = await poster(lancer, { cible: 'ph-1', verbe: 'executer' });
    const l = etat.definirCibles(f.sent.find((m) => m.t === 'cibles')?.cibles), p = etat.proposer(f.sent.find((m) => m.t === 'proposition') || {});
    sortir({ code, liste: l.ok, retenues: l.retenues, ecartees: l.ecartees, proposition: p.ok });
  }
  f.pousser({ t: 'lancee', cible: 'ph-1', verbe: 'executer', session: uuid, at: 1 });
  if (mode === 'l3') { const m = lancer.lancees(); sortir({ estMap: m instanceof Map, taille: m.size, entree: m.get(uuid) || null }); }
  const etat = async () => { const c = ph1(await lire(lancer)); return c.lancee && c.lancee.etat; }; const r = [await etat()];
  lancer.sourceWho(() => ({ workers: [{ kind: 'session', id: uuid, etat: 'actif' }] })); r.push(await etat());
  lancer.sourceWho(() => ({ workers: [{ kind: 'session', id: uuid, etat: 'termine' }] })); r.push(await etat()); sortir(r.join(','));
}
if (mode === 'e2') { // preparerTerminal sous win32 : registre « indisponible », aucune balise du lanceur
  const T = await imp('vf-cockpit-terminal.mjs'); const t = T.preparerTerminal({ here: sortie, root: lab, jetons: () => [], plateforme: 'win32' });
  const j = await lire(lanceur()), marque = U.injectionLancer({ indisponible: false });
  sortir({ terminal: j.terminal, balise: t.injection().includes(marque) ? 'oui' : 'non', temoin: marque.length > 100, bloquees: j.cibles.length > 0 && j.cibles.every((c) => c.bloquants.length > 0) });
}
if (mode === 'e4') { // canal « indisponible » (win32) puis « arrete » : le code du refus de POST est celui du contrat, jamais un autre code 503
  const r = []; for (const etat of ['indisponible', 'arrete', 'actif']) { const f = faux({ etat: () => etat }); C.definir(f.canal); const res = await posterRes(lanceur(), { cible: 'ph-1', verbe: 'executer' }); r.push(`${etat}:${res.code}:${res.code === 202 ? '' : JSON.parse(res.body).refus}`); }
  sortir(r.join(' '));
}
if (mode === 'e5') { // refus de proposer() : cible inconnue 404, verbe hors liste 422, bloquant 409 (claude absent), témoin 202 ; la règle « verbe permis, aucun bloquant » est celle de verdict()
  const cas = [['ph-999', 'executer', {}], ['ph-1', 'deployer', {}], ['ph-1', 'executer', { claude: () => false }], ['ph-1', 'executer', {}]], r = [];
  for (const [cible, verbe, sur] of cas) { const f = faux(sur); C.definir(f.canal); const res = await posterRes(lanceur(), { cible, verbe }); const b = res.code === 202 ? {} : JSON.parse(res.body); r.push(`${res.code}:${b.refus || ''}:${(b.bloquants || []).join('+')}`); }
  sortir(r.join(' '));
}
if (mode === 'e3') { // e3 <sortie> <lab> <moteur> <fauxbin> <pathsans> : les DEUX lecteurs réels (claude, python3), état du canal forcé à « actif »
  const [eng, fauxbin, sans] = reste; process.env.VF_COCKPIT_ENGINE_DIR = eng;
  const T = await imp('vf-cockpit-terminal.mjs'); T.preparerTerminal({ here: sortie, root: lab, jetons: () => [] });
  const reel = C.canal(), sent = []; C.definir({ ...reel, etat: () => 'actif', envoyer: (m) => { sent.push(m); return true; } }); const lancer = lanceur(); const PATH0 = process.env.PATH;
  const cas = async (origine, pathVar) => {
    process.env.VF_COCKPIT_PATH_ORIGINE = origine; process.env.PATH = pathVar; const j = await lire(lancer); const n0 = sent.filter((m) => m.t === 'proposition').length;
    const code = await poster(lancer, { cible: 'ph-1', verbe: 'executer' });
    return `${j.claude}|${ph1(j).bloquants.join('+')}|${code}|+${sent.filter((m) => m.t === 'proposition').length - n0}`;
  };
  sortir({ sansClaude: await cas('/inexistant-vf-abs', PATH0), sansPython: await cas(`${fauxbin}:${PATH0}`, sans), complet: await cas(`${fauxbin}:${PATH0}`, PATH0) });
}
sortir('mode inconnu');
JS

# ---- lab, faux claude, serveurs ----
printf '#!/bin/sh\nexit 0\n' > "$WORK/fauxbin/claude"; chmod +x "$WORK/fauxbin/claude"
ln -s "$(command -v node)" "$WORK/pathsans/node"; ln -s "$(command -v git)" "$WORK/pathsans/git"
export VF_COCKPIT_PATH_ORIGINE="$WORK/fauxbin:$PATH"
rq() { node "$TA" req "$@"; }
sta() { rq "$@" | sed -n 1p; }
sig() { rq "$@" | node "$AUX/norm.mjs"; }
mklab() { # mklab <dir> : phase 1 (PLAN), phases 2 et 3 aux titres hostiles, phase 4 finie ; sortie dans <dir>/.vibeflow/cockpit
  local L="$1" B="$1/.planning"; mkdir -p "$L/src" "$B/phases/01-socle" "$B/phases/04-fini"; printf 'export const u = 1;\n' > "$L/src/u.js"
  cat > "$B/ROADMAP.md" <<'RM'
## Phases

- [ ] **Phase 1: Socle** - premier jet
- [ ] **Phase 2: ; touch MARQ-TITRE #** - titre hostile
- [ ] **Phase 3: <img src=x onerror=void(0)>** - titre hostile
- [x] **Phase 4: Fini** - déjà livré

### Phase 1: Socle
**Goal**: Poser le socle

### Phase 2: ; touch MARQ-TITRE #
**Goal**: $(touch MARQ-GOAL)

### Phase 3: <img src=x onerror=void(0)>
**Goal**: Autre

### Phase 4: Fini
**Goal**: Livré
RM
  printf -- '---\nstatus: executing\ncurrent_phase: 1\nmilestone: v1.0 MVP\n---\n' > "$B/STATE.md"
  printf -- '---\nwave: 1\nfiles_modified: [src/u.js]\n---\n<objective>Poser le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"
  cp "$B/phases/01-socle/01-01-PLAN.md" "$B/phases/04-fini/04-01-PLAN.md"; printf -- '---\nstatus: complete\n---\n# ok\n' > "$B/phases/04-fini/04-01-SUMMARY.md"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  node "$SCRIPTS/vf-cockpit.mjs" build --lab "$L" > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
}
SRVN=0
srv() { # srv <sortie> <0|1 terminal> -> SRV_PORT SRV_PID SRV_O SRV_OUT ; serveur lancé directement depuis la sortie, comme le lanceur
  local o="$1" term="${2:-0}" lab; lab="$(cd "$1/../.." && pwd)"
  SRVN=$((SRVN+1)); SRV_O="$o"; SRV_OUT="$WORK/serve-$SRVN-$RANDOM.out"; rm -f "$o/.cache/server.json" "$o/.cache/terminal-amorce"; mkdir -p "$o/.cache"
  local flag=(); if [ "$term" = 1 ]; then flag=(--terminal); (umask 077; node -e "process.stdout.write(require('crypto').randomBytes(24).toString('hex'))" > "$o/.cache/terminal-amorce"); fi
  local pret=port; if [ "$term" = 1 ]; then pret=terminal; fi
  COCKPIT_PRET="$pret" COCKPIT_LOG="$SRV_OUT" cockpit_lancer "$lab" VF_COCKPIT_ENGINE_DIR="$ENG" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS" ${flag[@]+"${flag[@]}"}
  SRV_PID="$VF_PID"; SRV_PORT="${VF_PORT:-0}"
}
sj() { node "$AUX/ev.mjs" "$1" < "$SRV_O/.cache/server.json" 2>/dev/null; }
unsrv() { vf_hyg_stop "$SRV_PID"; }
STUBN=0
srv_stub() { # srv_stub <sortie> <mode> -> comme srv, avec enfant factice (STUB_LOG, STUB_PORT) ; PTOK (jeton de la page Projet), CTOK (jeton de server.json)
  STUBN=$((STUBN+1)); export STUB_LOG="$WORK/stub-$STUBN.log" STUB_PORT="$(libre)" STUB_MODE="$2"; : > "$STUB_LOG"
  srv "$1" 1; rq "$SRV_PORT" GET /project.html --corps-vers "$WORK/page-$STUBN.html" > /dev/null; PTOK="$(node "$AUX/ptok.mjs" "$WORK/page-$STUBN.html")"; CTOK="$(sj j.token)"
}
mutant() { # mutant <nom> <fichier-relatif-à-la-sortie> <expression-sed> -> MUT_OUT ; code 1 si la cible manque ou si la copie n'a pas changé
  local d="$WORK/mut-$1" f; rm -rf "$d"; mkdir -p "$d"; cp -R "$LAB/.planning" "$d/.planning"; cp -R "$LAB/.vibeflow" "$d/.vibeflow"
  MUT_OUT="$d/.vibeflow/cockpit"; cp "$AUX/stub-q.mjs" "$MUT_OUT/vf-cockpit-terminal-processus.mjs"; f="$MUT_OUT/$2"; [ -f "$f" ] || return 1
  cp "$f" "$f.orig"; sed -i.bak "$3" "$f"; local r=0; cmp -s "$f" "$f.orig" && r=1; rm -f "$f.orig" "$f.bak"; return $r
}
nprop() { local n; n="$(grep -c '"t":"proposition"' "$STUB_LOG" 2>/dev/null)"; echo "${n:-0}"; }
attend_n() { local i; for i in $(seq 1 30); do [ "$(nprop)" -ge "$1" ] && return 0; sleep 0.1; done; return 1; }
OKB='{"cible":"ph-1","verbe":"executer"}'; JSONH='Content-Type:application/json'
temoin() { # POST valide du jeu d'en-têtes de base : 202 et proposition +1
  local n0 s; n0="$(nprop)"; s="$(sta "$SRV_PORT" POST /api/vf/lancer --jeton "$PTOK" --entete "$JSONH" --corps "$OKB")"
  if [ "$s" = 202 ] && attend_n $((n0+1)); then echo ok; else echo "témoin positif absent : le refus ne prouve rien (statut $s)"; fi
}
refuse() { # refuse <libellé> <options de rq…> : témoin positif, puis la requête hostile ; 4xx, jamais 202, proposition inchangée, code d'erreur fermé
  local lib="$1" t n0 sortie s corps cls=refus code=ok n1; shift
  t="$(temoin)"; sleep 0.2; n0="$(nprop)"; sortie="$(rq "$SRV_PORT" POST /api/vf/lancer "$@")"; sleep 0.3; n1="$(nprop)"
  s="$(printf '%s\n' "$sortie" | sed -n 1p)"; corps="$(printf '%s\n' "$sortie" | sed '1,2d')"
  case "$s" in 4[0-9][0-9]) ;; ERREUR*) [ -n "${COUPURE_OK:-}" ] || cls="$s" ;; *) cls="non-refus : $s" ;; esac
  if [ -n "$corps" ]; then code="$(printf '%s' "$corps" | node "$AUX/ev.mjs" '(j.refus||j.erreur||"")' 2>/dev/null)"; [[ "$code" =~ ^[a-z0-9-]{1,40}$ ]] && code=ok || code="code-invalide : ${code:-corps non JSON}"; fi
  assert_eq "$lib — refus 4xx, après témoin 202 (+1), proposition inchangée, code fermé" "$t;$cls;$((n1-n0));$code" "ok;refus;0;ok"
}

LAB="$WORK/lab"; mklab "$LAB"; OUT="$LAB/.vibeflow/cockpit"
STUBD="$WORK/stubd"; mkdir -p "$STUBD"; cp -R "$LAB/.planning" "$STUBD/.planning"; cp -R "$LAB/.vibeflow" "$STUBD/.vibeflow"; STUBO="$STUBD/.vibeflow/cockpit"; cp "$AUX/stub-q.mjs" "$STUBO/vf-cockpit-terminal-processus.mjs"
CSPCH() { sed -n 2p "$1" | node "$AUX/ev.mjs" 'j["content-security-policy"]'; }

echo "=== S — sans le drapeau (LANC-02, P72-D-17) ==="
srv "$OUT" 0; P0=$SRV_PORT; rq "$P0" GET /project.html --corps-vers "$WORK/s-projet.html" > "$WORK/s-projet.out"; PTOK0="$(node "$AUX/ptok.mjs" "$WORK/s-projet.html")"
assert_eq "S0 — témoin : le lab se construit, le serveur démarre, GET /api/vf/etat rend 200 sous le jeton de la page Projet" "$([ "$P0" -gt 0 ] && sta "$P0" GET /api/vf/etat --jeton "$PTOK0" || echo "pas de serveur")" "200"
S1A="$(sig "$P0" GET /api/vf/lancer/cibles --jeton "$PTOK0")"; S1B="$(sig "$P0" GET /api/vf/inconnu --jeton "$PTOK0")"
assert_eq "S1 — témoin : GET /api/vf/inconnu rend un statut d'erreur (≥ 400)" "$([ "${S1B%%|*}" -ge 400 ] 2>/dev/null && echo oui || echo "non : ${S1B%%|*}")" "oui"
assert_eq "S1 — sans drapeau, GET /api/vf/lancer/cibles rend statut, en-têtes et corps d'une route inconnue" "$S1A" "$S1B"
S2A="$(sig "$P0" POST /api/vf/lancer --jeton "$PTOK0" --entete "$JSONH" --corps "$OKB")"; S2B="$(sig "$P0" POST /api/vf/inconnu --jeton "$PTOK0" --entete "$JSONH" --corps "$OKB")"
assert_eq "S2 — témoin : POST /api/vf/inconnu rend un statut d'erreur (≥ 400)" "$([ "${S2B%%|*}" -ge 400 ] 2>/dev/null && echo oui || echo "non : ${S2B%%|*}")" "oui"
assert_eq "S2 — sans drapeau, POST /api/vf/lancer (en-têtes complets et valides) rend ce que rend une route inconnue de même méthode" "$S2A" "$S2B"
rq "$P0" GET / --corps-vers "$WORK/s-index.html" > "$WORK/s-index.out"; rq "$P0" GET /index.html --corps-vers "$WORK/s-index2.html" > "$WORK/s-index2.out"
assert_eq "S3 — /project.html : le fichier du disque plus un seul script de jeton, rien d'autre" "$(node "$AUX/strip.mjs" "$WORK/s-projet.html" "$OUT/project.html")" "1:identique"
assert_eq "S3 — / : le fichier du disque plus un seul script de jeton" "$(node "$AUX/strip.mjs" "$WORK/s-index.html" "$OUT/index.html")" "1:identique"
assert_eq "S3 — /index.html : le fichier du disque plus un seul script de jeton" "$(node "$AUX/strip.mjs" "$WORK/s-index2.html" "$OUT/index.html")" "1:identique"
CSPS="$(CSPCH "$WORK/s-projet.out")"
assert_eq "S3 — CSP de /project.html = formule de v2.75.0 appliquée à la page servie" "$CSPS" "$(node "$TA" csp-v275 "$WORK/s-projet.html")"
assert_not "S3 — aucune sous-chaîne frame-src" "$CSPS" "frame-src"
unsrv

echo "=== P1 — parité du gabarit (72-CONTRATS §2) ==="
assert_eq "P1 — MOTIF_PHASE, MOTIF_COMPARTIMENT et VERBES de l'export réel du gabarit valent les littéraux du contrat" "$(node "$AUX/harnais.mjs" p1 "$STUBO" "$LAB")" '{"phase":"^\\d+(?:\\.\\d+)?$","comp":"^[a-z0-9][a-z0-9-]{0,39}$","verbes":["cadrer","planifier","executer","verifier","reprendre"]}'

echo "=== A — avec le drapeau et l'enfant factice ==="
srv_stub "$STUBO" defaut; P1=$SRV_PORT; QPORT=$STUB_PORT; PID1=$SRV_PID
node "$AUX/sse.mjs" "$P1" "$PTOK" "$WORK/sse.out" 90000 & SSEPID=$!; PIDS+=($SSEPID)
assert_eq "A0 — terminal actif : GET /api/vf/terminal rend etat actif" "$(rq "$P1" GET /api/vf/terminal --jeton "$PTOK" | sed '1,2d' | node "$AUX/ev.mjs" 'j.etat' 2>/dev/null)" "actif"
assert_eq "A0 — le journal du faux enfant porte init (premier message)" "$(node "$AUX/jl.mjs" "$STUB_LOG" 'L[0]')" '{"t":"init"}'
rq "$P1" GET /api/vf/lancer/cibles --jeton "$PTOK" > "$WORK/a1.out"; A1="$(sed '1,2d' "$WORK/a1.out")"
assert_eq "A1 — GET cibles : 200, quatre clés actif, cibles, claude, terminal ; terminal actif, claude vrai" "$(sed -n 1p "$WORK/a1.out") $(printf '%s' "$A1" | node "$AUX/ev.mjs" 'Object.keys(j).sort().join()+" "+j.actif+" "+j.terminal+" "+j.claude' 2>/dev/null)" "200 actif,cibles,claude,terminal true actif true"
PRIN="$(printf '%s' "$A1" | node "$AUX/ev.mjs" '(j.cibles.find(c=>c.id==="ph-1")||{}).principal' 2>/dev/null)"
assert_eq "A1 — la phase 1 est dans la liste, son principal est parmi ses verbes" "$(printf '%s' "$A1" | node "$AUX/ev.mjs" '(c=>c?c.verbes.includes(c.principal)+" "+c.principal:"absente")(j.cibles.find(c=>c.id==="ph-1"))' 2>/dev/null)" "true executer"
assert_eq "A1 — la phase finie porte un bloquant phase-finie" "$(printf '%s' "$A1" | node "$AUX/ev.mjs" '(j.cibles.find(c=>c.id==="ph-4")||{bloquants:[]}).bloquants.join()' 2>/dev/null)" "phase-finie"
assert_eq "A1 — chaque cible n'a que les sept clés du contrat" "$(printf '%s' "$A1" | node "$AUX/ev.mjs" 'j.cibles.length>0&&j.cibles.every(c=>Object.keys(c).sort().join()==="avertissements,bloquants,id,kind,lancee,principal,verbes")' 2>/dev/null)" "true"
assert_eq "A1 — témoin : la réponse porte des cibles (sans elles, l'absence de texte du lab ne prouve rien)" "$(printf '%s' "$A1" | node "$AUX/ev.mjs" 'j.cibles.length>0' 2>/dev/null)" "true"
for h in MARQ touch onerror Socle; do assert_not "A1 — aucun texte du lab (« $h ») dans la réponse" "$A1" "$h"; done
A2B="{\"cible\":\"ph-1\",\"verbe\":\"${PRIN:-executer}\"}" # le corps est posé dans une variable : bash 3.2 mal-découpe les guillemets échappés d'une substitution imbriquée
assert_eq "A2 — POST valide (cible de la phase 1, son principal) : 202 et {\"propose\":true}" "$(rq "$P1" POST /api/vf/lancer --jeton "$PTOK" --entete "$JSONH" --corps "$A2B" | sed '1p;3,$!d' | tr '\n' ' ')" '202 {"propose":true}'
attend_n 1
assert_eq "A3 — le journal de Q montre cibles (une ou plus) puis proposition, une seule proposition, dans cet ordre" "$(node "$AUX/jl.mjs" "$STUB_LOG" '(/^(cibles )+proposition$/.test(L.filter(x=>x.t&&x.t!=="init"&&x.t!=="jetons").map(x=>x.t).join(" "))?"ordre-ok":"ordre-ko")+" "+L.filter(x=>x.t==="proposition").length' 2>/dev/null)" "ordre-ok 1"
assert_eq "A3 — clés exactes : proposition (t, cible, verbe, bloquants, avertissements) et cibles (t, cibles)" "$(node "$AUX/jl.mjs" "$STUB_LOG" 'Object.keys(L.find(x=>x.t==="proposition")).sort().join()+" "+Object.keys(L.filter(x=>x.t==="cibles").pop()).sort().join()' 2>/dev/null)" "avertissements,bloquants,cible,t,verbe cibles,t"
assert_eq "A3 — chaque entrée de la liste envoyée à Q : six clés fermées ; identifiants ph-1, ph-2, ph-3 (la phase finie n'y est pas)" "$(node "$AUX/jl.mjs" "$STUB_LOG" '(l=>l.every(e=>Object.keys(e).sort().join()==="id,kind,phase,verbe,verbes,ws")+" "+l.map(e=>e.id).join())(L.filter(x=>x.t==="cibles").pop().cibles)' 2>/dev/null)" "true ph-1,ph-2,ph-3"
assert_eq "A3 — bloquants et avertissements de la proposition : tableaux vides" "$(node "$AUX/jl.mjs" "$STUB_LOG" '(p=>JSON.stringify([p.bloquants,p.avertissements]))(L.find(x=>x.t==="proposition"))' 2>/dev/null)" "[[],[]]"
assert_eq "A3 — témoin : le journal de Q porte au moins une proposition" "$([ "$(nprop)" -ge 1 ] && echo oui || echo non)" "oui"
assert_eq "A3 — aucun texte du lab dans les messages envoyés à Q" "$(grep -c -e MARQ -e touch -e onerror -e Socle "$STUB_LOG")" "0"
assert_eq "A4 — contrat : le vrai état de Q accepte la liste (3 retenues, 0 écartée) puis la proposition de P" "$(node "$AUX/harnais.mjs" q "$STUBO" "$LAB")" '{"code":202,"liste":true,"retenues":3,"ecartees":0,"proposition":true}'

echo "=== R — refus de LANC-03 et de LANC-04, chacun après son témoin positif ==="
BASE=(--entete "$JSONH" --corps "$OKB")
refuse "R1 — Origin tierce" --jeton "$PTOK" "${BASE[@]}" --origin http://evil.example
refuse "R2 — Origin absente" --jeton "$PTOK" "${BASE[@]}" --sans-origin
refuse "R3 — Origin de Q" --jeton "$PTOK" "${BASE[@]}" --origin "http://127.0.0.1:$QPORT"
refuse "R4 — Host localhost:<P> avec Origin http://127.0.0.1:<P>" --jeton "$PTOK" "${BASE[@]}" --host "localhost:$P1"
refuse "R5 — jeton de la page Code (seul celui de la page Projet est admis)" --jeton "$CTOK" "${BASE[@]}"
refuse "R6 — mauvais jeton" --jeton "$(printf 'f%.0s' $(seq 1 32))" "${BASE[@]}"
refuse "R7 — Content-Type text/plain" --jeton "$PTOK" --entete 'Content-Type:text/plain' --corps "$OKB"
COUPURE_OK=1 refuse "R8 — corps de 600 octets" --jeton "$PTOK" --entete "$JSONH" --corps-octets 600
refuse "R9 — champ inconnu" --jeton "$PTOK" --entete "$JSONH" --corps '{"cible":"ph-1","verbe":"executer","x":"y"}'
refuse "R10 — cible malformée « 72;touch MARQ-R10 »" --jeton "$PTOK" --entete "$JSONH" --corps '{"cible":"72;touch MARQ-R10","verbe":"executer"}'
refuse "R10 — cible malformée « \$(touch MARQ-R10b) »" --jeton "$PTOK" --entete "$JSONH" --corps '{"cible":"$(touch MARQ-R10b)","verbe":"executer"}'
assert_eq "R10 — aucun fichier MARQ-* n'a été créé (ni dans le lab, ni dans le dossier de travail)" "$(ls "$LAB" "$WORK" 2>/dev/null | grep -c MARQ-R10)" "0"
refuse "R11 — cible bien formée absente de la liste (ph-9999)" --jeton "$PTOK" --entete "$JSONH" --corps '{"cible":"ph-9999","verbe":"executer"}'
refuse "R11 — verbe hors des verbes de la cible" --jeton "$PTOK" --entete "$JSONH" --corps '{"cible":"ph-1","verbe":"deployer"}'
refuse "R12 — cible porteuse d'un bloquant (phase finie)" --jeton "$PTOK" --entete "$JSONH" --corps '{"cible":"ph-4","verbe":"executer"}'

echo "=== C — chat ==="
UC='11111111-2222-4333-8444-555555555555'; n0="$(nprop)"
C1B="{\"cible\":\"ph-1\",\"verbe\":\"executer\",\"chat\":\"$UC\"}"; C1S="$(sta "$P1" POST /api/vf/lancer --jeton "$PTOK" --entete "$JSONH" --corps "$C1B")"; attend_n $((n0+1)); C1C="$(node "$AUX/jl.mjs" "$STUB_LOG" 'L.filter(x=>x.t==="proposition").pop().chat' 2>/dev/null)"
assert_eq "C1 — chat valide (UUID) : 202 et la proposition porte chat" "$C1S ${C1C:-aucune proposition}" "202 $UC"
refuse "C2 — chat non UUID" --jeton "$PTOK" --entete "$JSONH" --corps '{"cible":"ph-1","verbe":"executer","chat":"pas-un-uuid"}'
# C3 : un UUID aux majuscules est refusé par P (même forme que le gabarit : minuscules, 8-4-4-4-12), sinon P répondrait 202 pour une proposition que Q ou le gabarit refuse. Résiduel P72-D-22 inchangé : un POST direct reste possible.
UCM='ABCDEFAB-ABCD-4BCD-8BCD-ABCDEFABCDEF'; CMB="{\"cible\":\"ph-1\",\"verbe\":\"executer\",\"chat\":\"$UCM\"}"
refuse "C3 — chat UUID aux majuscules" --jeton "$PTOK" --entete "$JSONH" --corps "$CMB"
C3R="$(rq "$SRV_PORT" POST /api/vf/lancer --jeton "$PTOK" --entete "$JSONH" --corps "$CMB")"
assert_eq "C3 — chat aux majuscules : 422 et refus chat-invalide (jamais 202)" "$(printf '%s\n' "$C3R" | sed -n 1p) $(printf '%s\n' "$C3R" | sed '1,2d' | node "$AUX/ev.mjs" 'j.refus' 2>/dev/null)" "422 chat-invalide"

echo "=== F — fuites : flux SSE, journal, journal du serveur, server.json ==="
rq "$P1" GET /api/vf/journal --jeton "$PTOK" | sed '1,2d' > "$WORK/journal.json"; vf_hyg_stop "$SSEPID"; sleep 0.3
SSE="$(cat "$WORK/sse.out")"
assert_eq "F1 — témoin : la série a envoyé au moins trois propositions à Q (sans elles, l'absence de fuite ne prouve rien)" "$([ "$(nprop)" -ge 3 ] && echo oui || echo "non : $(nprop)")" "oui"
assert_has "F1 — témoin : le flux capté porte « event: hello »" "$SSE" "event: hello"
for h in lancer proposition 'claude --session-id' MARQ; do assert_not "F1 — le flux ne contient pas « $h »" "$SSE" "$h"; done
assert_eq "F2 — témoin : GET /api/vf/journal rend un document non vide" "$([ -s "$WORK/journal.json" ] && echo oui || echo non)" "oui"
assert_eq "F2 — le journal du direct ne contient pas « lancer »" "$(grep -c lancer "$WORK/journal.json")" "0"
assert_eq "F3 — témoin : le journal du serveur et server.json sont lisibles (jeton présent)" "$([ -n "$CTOK" ] && [ -f "$SRV_OUT" ] && echo oui || echo non)" "oui"
assert_eq "F3 — ni « proposition », ni « claude --session-id », ni « touch » dans le journal du serveur et server.json" "$(cat "$SRV_OUT" "$SRV_O/.cache/server.json" | grep -c -e proposition -e 'claude --session-id' -e touch)" "0"

echo "=== U — injection du lanceur et CSP ==="
rq "$P1" GET /project.html --corps-vers "$WORK/u-page.html" > "$WORK/u-page.out"; CSPCH "$WORK/u-page.out" > "$WORK/u-csp.txt"
UI="$(node "$AUX/harnais.mjs" ui "$STUBO" "$LAB" "$WORK/u-page.html" "$WORK/u-csp.txt")"
assert_eq "U1 — la page /project.html servie avec le drapeau contient le texte de injectionLancer({ indisponible: false })" "${UI%% *}" "balise=oui"
EXACT=non; [ "$(cat "$WORK/u-csp.txt")" = "$(node "$TA" csp-v275 "$WORK/u-page.html"); frame-src http://127.0.0.1:$QPORT" ] && EXACT=oui
assert_eq "U2 — CSP = formule de v2.75.0 de la page servie + « ; frame-src http://127.0.0.1:<Q> » exact, et le script du lanceur y est empreinté" "exact=$EXACT ${UI#* }" "exact=oui empreinte=oui"
unsrv

echo "=== L — retour lancee (forme riche jusqu'à la carte) ==="
lancee_de() { rq "$SRV_PORT" GET /api/vf/lancer/cibles --jeton "$PTOK" | sed '1,2d' | node "$AUX/ev.mjs" 'j.cibles.find(c=>c.id==="ph-1").lancee' 2>/dev/null; }
srv_stub "$STUBO" lancee; AVANT="$(lancee_de)"
sta "$SRV_PORT" POST /api/vf/lancer --jeton "$PTOK" --entete "$JSONH" --corps "$OKB" > /dev/null; APRES="$AVANT"
for _ in $(seq 1 30); do APRES="$(lancee_de)"; [ "$APRES" != "false" ] && break; sleep 0.1; done
assert_eq "L1 — enfant factice en mode lancee : la carte passe de false à { etat: attendue, verbe } (forme riche, jamais le booléen seul)" "$AVANT -> $APRES" 'false -> {"etat":"attendue","verbe":"executer"}'
unsrv
srv_stub "$STUBO" lancee-mal; AVANT="$(lancee_de)"
sta "$SRV_PORT" POST /api/vf/lancer --jeton "$PTOK" --entete "$JSONH" --corps "$OKB" > /dev/null
for _ in $(seq 1 30); do grep -q '"envoye"' "$STUB_LOG" && break; sleep 0.1; done; sleep 0.4
assert_eq "L2 — cinq messages lancee mal formés (UUID, clé en trop, verbe, at absent, cible hors liste) envoyés : la carte reste false" "$(grep -c '"envoye"' "$STUB_LOG") $(lancee_de)" "1 false"
unsrv
assert_eq "L3 — message valide poussé à l'abonné : lancees() est une Map portant la session avec { phase, ws, verbe }" "$(node "$AUX/harnais.mjs" l3 "$STUBO" "$LAB")" '{"estMap":true,"taille":1,"entree":{"phase":"1","ws":null,"verbe":"executer"}}'
assert_has "L3 — vf-cockpit-server.mjs de la sortie passe lancees: lancer.lancees() à pageEquipe" "$(cat "$STUBO/vf-cockpit-server.mjs")" "lancees: lancer.lancees()"
assert_eq "L4 — les trois états du suivi atteignent la carte : attendue, vue, terminee" "$(node "$AUX/harnais.mjs" l4 "$STUBO" "$LAB")" "attendue,vue,terminee"

echo "=== E — états inertes et bloquants ==="
srv_stub "$STUBO" defaut; rq "$SRV_PORT" GET /api/vf/lancer/cibles --jeton "$PTOK" > /dev/null; kill -9 "$(cat "$STUB_LOG.pid")" 2>/dev/null
for _ in $(seq 1 50); do [ "$(rq "$SRV_PORT" GET /api/vf/lancer/cibles --jeton "$PTOK" | sed '1,2d' | node "$AUX/ev.mjs" 'j.terminal' 2>/dev/null)" = arrete ] && break; sleep 0.1; done
E1="$(rq "$SRV_PORT" GET /api/vf/lancer/cibles --jeton "$PTOK" | sed '1,2d')"; N0="$(wc -l < "$STUB_LOG" | tr -d ' ')"; S="$(sta "$SRV_PORT" POST /api/vf/lancer --jeton "$PTOK" --entete "$JSONH" --corps "$OKB")"; sleep 0.3
assert_eq "E1 — enfant tué : terminal arrete, chaque cible porte un bloquant terminal-arrete" "$(printf '%s' "$E1" | node "$AUX/ev.mjs" 'j.terminal+" "+(j.cibles.length>0&&j.cibles.every(c=>c.bloquants.includes("terminal-arrete")))' 2>/dev/null)" "arrete true"
assert_eq "E1 — un POST valide est refusé (409 ou 503, jamais 202) et le journal du faux enfant ne grandit pas" "$([ "$S" = 409 ] || [ "$S" = 503 ] && echo refus || echo "statut $S") $(( $(wc -l < "$STUB_LOG" | tr -d ' ') - N0 ))" "refus 0"
unsrv
assert_eq "E2 — sous win32 : terminal indisponible, cibles toutes bloquées, injection() sans la balise du lanceur" "$(node "$AUX/harnais.mjs" e2 "$STUBO" "$LAB")" '{"terminal":"indisponible","balise":"non","temoin":true,"bloquees":true}'
assert_eq "E2b — POST /api/vf/lancer : canal indisponible -> 503 terminal-indisponible ; canal arrete -> 503 terminal-arrete ; actif -> 202 (témoin)" "$(node "$AUX/harnais.mjs" e4 "$STUBO" "$LAB")" "indisponible:503:terminal-indisponible arrete:503:terminal-arrete actif:202:"
E5_ATT="404:cible-inconnue: 422:verbe-refuse: 409:bloque:claude-introuvable 202::"
assert_eq "E2c — refus de POST /api/vf/lancer : cible inconnue 404 cible-inconnue ; verbe hors liste 422 verbe-refuse ; claude absent 409 bloque + claude-introuvable ; complet 202 (témoin)" "$(node "$AUX/harnais.mjs" e5 "$STUBO" "$LAB")" "$E5_ATT"
assert_eq "E3 — claude absent du PATH du shell : bloquant claude-introuvable et POST refusé ; python3 absent : python3-absent et POST refusé ; les deux présents : 202, +1 (témoin)" "$(node "$AUX/harnais.mjs" e3 "$STUBO" "$LAB" "$ENG" "$WORK/fauxbin" "$WORK/pathsans")" '{"sansClaude":"false|claude-introuvable|409|+0","sansPython":"true|python3-absent|409|+0","complet":"true||202|+1"}'

echo "=== M — mutants (copies de la sortie) ==="
if mutant sans-drapeau vf-cockpit-lancer.mjs 's|const servi = () => canal() !== null;|const servi = () => true;|'; then
  srv "$MUT_OUT" 0; MT="$(rq "$SRV_PORT" GET /project.html --corps-vers "$WORK/m1.html" > /dev/null; node "$AUX/ptok.mjs" "$WORK/m1.html")"; MP=$SRV_PORT
  MA="$(sig "$MP" GET /api/vf/lancer/cibles --jeton "$MT")"; MB="$(sig "$MP" GET /api/vf/inconnu --jeton "$MT")"; MC="$(sig "$MP" POST /api/vf/lancer --jeton "$MT" --entete "$JSONH" --corps "$OKB")"; MD="$(sig "$MP" POST /api/vf/inconnu --jeton "$MT" --entete "$JSONH" --corps "$OKB")"
  assert_eq "M-SANS-DRAPEAU — le mutant rougit S1 et S2 : les deux routes sont servies sans le drapeau" "$([ "$MA" != "$MB" ] && echo S1-rouge || echo S1-vert) $([ "$MC" != "$MD" ] && echo S2-rouge || echo S2-vert)" "S1-rouge S2-rouge"; unsrv
else assert_eq "M-SANS-DRAPEAU — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
if mutant liste-page vf-cockpit-lancer.mjs "s|const cible = liste.find((x) => x.id === demande.cible);|const cible = { id: demande.cible, verbes: [demande.verbe], bloquants: [], avertissements: [], kind: 'phase', phase: '1', ws: null };|
s|const v = verdict(liste, cible.id, demande.verbe);.*$|const v = { lancable: true, bloquants: [] };|"; then
  srv_stub "$MUT_OUT" defaut; n0="$(nprop)"; sta "$SRV_PORT" POST /api/vf/lancer --jeton "$PTOK" --entete "$JSONH" --corps '{"cible":"ph-9999","verbe":"executer"}' > /dev/null; sleep 0.5
  assert_eq "M-LISTE-PAGE — le mutant rougit R11 : une cible absente de la liste du disque envoie une proposition (+1 au lieu de 0)" "+$(( $(nprop) - n0 ))" "+1"; unsrv
else assert_eq "M-LISTE-PAGE — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
if mutant token-code vf-cockpit-server.mjs 's|creerLancer({ root, here, ptoken,|creerLancer({ root, here, ptoken: token,|'; then
  srv_stub "$MUT_OUT" defaut
  assert_eq "M-TOKEN-CODE — le mutant rougit A2 et R5 : le jeton Projet est refusé, le jeton Code est admis" "$(sta "$SRV_PORT" POST /api/vf/lancer --jeton "$PTOK" --entete "$JSONH" --corps "$OKB"),$(sta "$SRV_PORT" POST /api/vf/lancer --jeton "$CTOK" --entete "$JSONH" --corps "$OKB")" "403,202"; unsrv
else assert_eq "M-TOKEN-CODE — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
if mutant lancee-libre vf-cockpit-lancer.mjs 's|if (!lanceeValide(m)) return;|if (false) return;|'; then
  srv_stub "$MUT_OUT" lancee-mal; sta "$SRV_PORT" POST /api/vf/lancer --jeton "$PTOK" --entete "$JSONH" --corps "$OKB" > /dev/null
  for _ in $(seq 1 30); do grep -q '"envoye"' "$STUB_LOG" && break; sleep 0.1; done; sleep 0.4
  assert_eq "M-LANCEE-LIBRE — le mutant rougit L2 : un message mal formé est enregistré (la carte n'est plus false)" "$([ "$(lancee_de)" != false ] && echo L2-rouge || echo L2-vert)" "L2-rouge"; unsrv
else assert_eq "M-LANCEE-LIBRE — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi

if mutant uuid-maj vf-cockpit-lancer.mjs '/^const UUID = /s/0-9a-f/0-9a-fA-F/g'; then
  srv_stub "$MUT_OUT" defaut; MC3="$(rq "$SRV_PORT" POST /api/vf/lancer --jeton "$PTOK" --entete "$JSONH" --corps "$CMB" | sed -n 1p)"
  assert_eq "M-UUID-MAJUSCULES — le mutant rougit C3 : le motif de P accepte les majuscules, 202 au lieu de 422" "$MC3" "202"; unsrv
else assert_eq "M-UUID-MAJUSCULES — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi

if mutant code-indispo vf-cockpit-lancer.mjs "s#refus: etat === 'indisponible' ? 'terminal-indisponible' : 'terminal-arrete'#refus: 'terminal-arrete'#"; then
  assert_eq "M-CODE-INDISPONIBLE — le mutant rend toujours terminal-arrete : E2b rougit" "$(node "$AUX/harnais.mjs" e4 "$MUT_OUT" "$LAB")" "indisponible:503:terminal-arrete arrete:503:terminal-arrete actif:202:"
else assert_eq "M-CODE-INDISPONIBLE — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
if mutant garde-actif vf-cockpit-lancer.mjs "s#if (etat !== 'actif') return { statut: 503, corps: { refus: etat === 'indisponible' ? 'terminal-indisponible' : 'terminal-arrete' } };##"; then
  assert_eq "M-GARDE-ACTIF — le mutant retire la garde d'état : un canal indisponible ne rend plus 503 terminal-indisponible (E2b rougit)" "$(node "$AUX/harnais.mjs" e4 "$MUT_OUT" "$LAB")" "indisponible:409:bloque arrete:409:bloque actif:202:"
else assert_eq "M-GARDE-ACTIF — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi

if mutant verdict-bloque vf-cockpit-lancer-cibles.mjs "s#return { lancable: bloquants.length === 0,#return { lancable: true,#"; then
  assert_eq "M-VERDICT-BLOQUE — le mutant rend toujours lançable : le POST d'une cible bloquée passe (409 -> 202), E2c rougit : proposer() s'appuie bien sur verdict()" "$(node "$AUX/harnais.mjs" e5 "$MUT_OUT" "$LAB")" "404:cible-inconnue: 422:verbe-refuse: 202:: 202::"
else assert_eq "M-VERDICT-BLOQUE — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
if mutant verdict-verbe vf-cockpit-lancer-cibles.mjs "s#if (!c || !Array.isArray(c.verbes) || !c.verbes.includes(verbe)) return null;#if (!c || !Array.isArray(c.verbes)) return null;#"; then
  assert_eq "M-VERDICT-VERBE — le mutant ne juge plus le verbe : un verbe hors liste passe (422 -> 202), E2c rougit" "$(node "$AUX/harnais.mjs" e5 "$MUT_OUT" "$LAB")" "404:cible-inconnue: 202:: 409:bloque:claude-introuvable 202::"
else assert_eq "M-VERDICT-VERBE — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi

vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
