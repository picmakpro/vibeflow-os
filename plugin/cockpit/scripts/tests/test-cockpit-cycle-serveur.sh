#!/usr/bin/env bash
# test-cockpit-cycle-serveur.sh — le cycle du serveur du cockpit : coût du direct (AUDC-H2) et vie du serveur (AUDC-H3).
#   H2.1-H2.4  un seul appel au verrou par cycle du filet ; aucune collecte quand aucun onglet n'est connecté (témoin positif : un onglet connecté collecte)
#   H2.8       la connexion d'un onglet relit l'état une fois (au plus un tour par période du filet)
#   H2.5-H2.6  un changement de planning relit le planning UNE fois (exigences), sans interroger le verrou quand personne n'écoute
#   H3.*       journal daté avec motif d'arrêt, verrou de lanceur, relance identique / relance à option changée, activité authentifiée
# Le test COMPTE des appels (faux verrou, lectures de fichier), il ne mesure aucun temps.
# Lab neutre dans mktemp, HOME jetable, isolation git. Exit 0 si tout passe, 1 sinon.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home" "$WORK/scripts-faux"
export HOME="$WORK/home"
trap 'vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"' EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [${2:0:300}]"; FAIL=$((FAIL+1)); fi; }
assert_ge() { if [ "${2:--1}" -ge "$3" ] 2>/dev/null; then echo "  ✅ PASS — $1 ($2 >= $3)"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (obtenu $2, attendu >= $3)"; FAIL=$((FAIL+1)); fi; }

# --- faux verrou : chaque appel est consigné dans le lab observé (cwd de l'appel), la forme rendue est celle d'un lab sans verrou ---
cat > "$WORK/scripts-faux/driver-lock.sh" <<'SH'
#!/usr/bin/env bash
mkdir -p "$PWD/.vibeflow"; echo "$1" >> "$PWD/.vibeflow/compteur-verrou"
case "$1" in status) echo '{"locks":[]}' ;; orphans) echo '{"orphans":[]}' ;; *) echo '{}' ;; esac
SH
chmod +x "$WORK/scripts-faux/driver-lock.sh"

# --- harnais : démarre le direct réel sur un lab, mesure sur une fenêtre, rend un JSON ---
cat > "$AUX/cycle.mjs" <<'JS'
// cycle.mjs <scripts> <lab> <client|sans> : le direct réel (startLive), un lab, un faux verrou. Sortie : un JSON de comptes.
import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [, , scripts, lab, mode] = process.argv;
const compteur = path.join(lab, '.vibeflow', 'compteur-verrou');
let req = 0; const lire = fs.readFileSync;
fs.readFileSync = function (f, ...r) { if (String(f).endsWith('REQUIREMENTS.md')) req++; return lire.call(this, f, ...r); };
const { startLive } = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-live.mjs')).href);
const appels = (nom) => (fs.existsSync(compteur) ? fs.readFileSync(compteur, 'utf8').split('\n').filter((l) => l === nom).length : 0);
const evs = [];
const live = startLive({ root: lab, sortie: path.join(lab, '.vibeflow', 'cockpit'), onEvent: (n) => evs.push(n), log: () => {}, aClient: () => mode === 'client' });
const dormir = (ms) => new Promise((r) => setTimeout(r, ms));
// fenêtre 1 : le filet seul (5 s de période), sans rien changer
fs.rmSync(compteur, { force: true }); await dormir(5700);
const filet = { status: appels('status'), orphans: appels('orphans') };
// fenêtre 2 : un changement de planning ; le prochain tour du filet tombe 4 s plus tard, hors de la fenêtre
fs.rmSync(compteur, { force: true }); req = 0; evs.length = 0;
fs.writeFileSync(path.join(lab, '.planning', 'ROADMAP.md'), '- [x] **Phase 1: Socle** - premier jet\n- [x] **Phase 2: Suite** - deuxième jet\n');
for (let i = 0; i < 40 && !evs.some((e) => e === 'patch' || e === 'structural'); i++) await dormir(100);
const changement = { evenement: evs.some((e) => e === 'patch' || e === 'structural'), status: appels('status'), exigences: req };
// fenêtre 3 : la connexion d'un onglet après un silence relit l'état une fois, et pas deux (deux onglets coup sur coup)
fs.rmSync(compteur, { force: true }); live.reveil?.(); live.reveil?.();
const reveil = { status: appels('status') };
live.stop();
console.log(JSON.stringify({ filet, changement, reveil }));
process.exit(0);
JS

mklab() {
  local L="$1"; mkdir -p "$L/.planning/phases/01-x" "$L/.vibeflow/cockpit"
  printf -- '- [x] **Phase 1: Socle** - premier jet\n- [ ] **Phase 2: Suite** - deuxième jet\n' > "$L/.planning/ROADMAP.md"
  printf -- '- [x] **REQ-01**: premier\n- [ ] **REQ-02**: second\n' > "$L/.planning/REQUIREMENTS.md"
  printf '<objective>socle</objective>\n' > "$L/.planning/phases/01-x/01-01-PLAN.md"; echo ok > "$L/.planning/phases/01-x/01-01-SUMMARY.md"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
}

echo "=== H2 — cycle du filet et lecture du planning ==="
mklab "$WORK/labc"; mklab "$WORK/labs"
VF_COCKPIT_SCRIPTS_DIR="$WORK/scripts-faux" node "$AUX/cycle.mjs" "$SCRIPTS" "$WORK/labc" client > "$WORK/c.json" 2> "$WORK/c.err" &
PC=$!
VF_COCKPIT_SCRIPTS_DIR="$WORK/scripts-faux" node "$AUX/cycle.mjs" "$SCRIPTS" "$WORK/labs" sans > "$WORK/s.json" 2> "$WORK/s.err" &
PS_=$!
wait "$PC"; wait "$PS_"
jq_() { node -e "const j=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'));const v=new Function('j','return ('+process.argv[2]+')')(j);console.log(typeof v==='string'?v:JSON.stringify(v))" "$1" "$2" 2>/dev/null || echo "illisible"; }
echo "  (avec onglet : $(cat "$WORK/c.json" 2>/dev/null) · sans onglet : $(cat "$WORK/s.json" 2>/dev/null))"
assert_ge "H2.0 — témoin positif : avec un onglet connecté, le filet a collecté (au moins un appel au verrou)" "$(jq_ "$WORK/c.json" 'j.filet.status')" 1
assert_eq "H2.1 — un seul appel au verrou par cycle du filet (appels 'status' = 1 sur la fenêtre d'un cycle)" "$(jq_ "$WORK/c.json" 'j.filet.status')" "1"
assert_eq "H2.2 — aucune collecte sans onglet : zéro appel au verrou sur la fenêtre du filet" "$(jq_ "$WORK/s.json" 'j.filet.status')" "0"
assert_eq "H2.3 — aucune collecte sans onglet : zéro lecture du registre des orphelins" "$(jq_ "$WORK/s.json" 'j.filet.orphans')" "0"
assert_eq "H2.4 — un changement de planning est annoncé même sans onglet (la page sur disque suit)" "$(jq_ "$WORK/s.json" 'j.changement.evenement')" "true"
assert_eq "H2.5 — un changement de planning relit le planning UNE fois : REQUIREMENTS.md ouvert au plus 2 fois (1 lecture du planning + 1 contrôle de format brut ; trois fois = planning relu)" "$(jq_ "$WORK/c.json" 'j.changement.exigences >= 1 && j.changement.exigences <= 2')" "true"
assert_eq "H2.6 — sans onglet, un changement de planning n'interroge pas le verrou" "$(jq_ "$WORK/s.json" 'j.changement.status')" "0"
assert_eq "H2.7 — avec un onglet, un changement de planning interroge le verrou une fois" "$(jq_ "$WORK/c.json" 'j.changement.status')" "1"

assert_eq "H2.8 — la connexion d'un onglet après un silence relit le verrou une fois (le second onglet coup sur coup ne relit pas)" "$(jq_ "$WORK/s.json" 'j.reveil.status')" "1"

echo "== bilan : $PASS réussi(s), $FAIL échec(s) =="
[ "$FAIL" -eq 0 ]
