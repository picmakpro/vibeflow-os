#!/usr/bin/env bash
# test-cockpit-lancer-bout-en-bout.sh — bout en bout du lancement depuis les cartes avec un FAUX `claude` : sans navigateur puis dans Chromium
# (LANC-05, LANC-09, LANC-10, LANC-12 ; P72-D-01, D-02, D-14 à D-16, D-19 ; plan 72-12). Serveur `--terminal` réel, vrai shell, vraie page Q ;
# aucune session Claude réelle : un faux `claude` (temoins/fauxbin-claude/claude) est en tête du PATH D'ORIGINE du shell et consigne son argv.
# Lab de test : partitionné, phase 1 au titre `"; touch pwn-titre #`, phase 2 à un titre balise, compartiments hostiles `a$(id)` et `a$(touch pwn-ws)`.
#   B0  témoin : serveur réel, session du client Node (onglet A), invite, `command -v claude` imprime le faux claude du PATH d'origine
#   B1  proposition de P puis lecture par Q : UUID v4 de la ligne herite     B2  lancement herite : argv octet pour byte, racine du lab, environnement privé de CLAUDE_CODE_*
#   B3  default / acceptEdits / plan : --permission-mode <mode> avant le prompt   B4  cible lancée, rejeu refusé (404), avertissement de récence
#   B5  claude n'a tourné qu'après l'Entrée       B6  compartiments hostiles : bloquant, refus 409, rien d'exécuté, aucun `$(` dans les réponses
#   B7  proposition sans confirmation : rien d'écrit, puis annulée            B8  programme au premier plan : 409, rien d'écrit, puis 204 à son retour
#   B9  sans `claude` dans le PATH d'origine : bloquant claude-introuvable, refus
#   CH  Chromium : bandeau, clic de confiance précoce ignoré, clic après armement (ligne SANS Entrée), Entrée au clavier, présélection du mode, Annuler
#   M-RETOUR-CHARIOT (rougit B2) · M-LISTE-PAGE (rougit B6) : mutants sur copies du module
# Sans Chrome : la section CH annonce « NON vérifiée, non comptée ». Limite : Chrome headless Linux a `pointer: none` — aucune assertion ici ne lit ce media.
# La recette avec le VRAI `claude` (skill /vf-dev ouvert, boîte de confiance du dossier, transcript dans l'onglet Équipe) est par juges, hors suite.
# Chaque absence est précédée du témoin positif de la même observation ; seules attentes à durée fixe : fenêtres d'observation d'une ABSENCE (2 s ou arme_apres_ms + 1,5 s).
# Exit 0 si tout passe, 1 sinon.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
ENG="$(cd "$SCRIPTS/../skills/cockpit-moteur" && pwd -P)"; TA="$HERE_T/terminal-aux.mjs"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; RUN="$WORK/run"; mkdir -p "$AUX" "$WORK/home" "$WORK/bin" "$WORK/fauxbin" "$WORK/pathsans" "$RUN"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
export VF_COCKPIT_MODE_DIR="$WORK/etat"; unset XDG_CACHE_HOME # AUDC-B-05 : le mode retenu d'un lancement accepté va dans un dossier jetable, jamais dans le dossier d'état réel de l'utilisateur ni de la CI
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
. "$HERE_T/socle-serveur.sh"
PASS=0; FAIL=0; NONVERIF=0
court() { if [ "${#1}" -gt 300 ]; then printf '%s […] %s' "${1:0:140}" "${1: -140}"; else printf '%s' "$1"; fi; }
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$(court "$3")]"; echo "     obtenu:  [$(court "$2")]"; FAIL=$((FAIL+1)); fi; }
nonverif() { echo "  ⊘ $1 — NON vérifiée sans navigateur, non comptée comme réussie"; NONVERIF=$((NONVERIF+1)); }
CHROME=""
for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue
  if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
echo "navigateur : ${CHROME:-aucun (la section CH est annoncée non vérifiée)}"

# ---- aides Node (jamais dans le dépôt) ----
cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/ptok.mjs" <<'JS'
import fs from 'node:fs'; const m = /VF_COCKPIT_SERVER=\{"token":"([0-9a-f]+)"/.exec(fs.readFileSync(process.argv[2], 'utf8')); console.log(m ? m[1] : '');
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
cat > "$AUX/apres-off.mjs" <<'JS'
// apres-off.mjs <fichier> <décalage> <sous-chaine> <ms> : TROUVE si la sous-chaîne paraît dans les octets AJOUTÉS après le décalage
import fs from 'node:fs';
const [, , f, off, sous, ms] = process.argv; const fin = Date.now() + Number(ms);
for (;;) {
  let t = ''; try { t = fs.readFileSync(f).subarray(Number(off)).toString('latin1'); } catch {}
  if (t.includes(sous)) { console.log('TROUVE'); process.exit(0); }
  if (Date.now() >= fin) { console.log('ABSENT'); process.exit(1); }
  await new Promise((r) => setTimeout(r, 50));
}
JS
# shell de test : le PID enregistré reste celui du shell (exec) ; invite VFP> ; le PATH est celui d'ORIGINE du serveur (faux claude en tête)
cat > "$WORK/bin/rc" <<SH
PS1='VFP> '; unset PROMPT_COMMAND; bind 'set enable-bracketed-paste off' 2>/dev/null
SH
cat > "$WORK/bin/shell-test" <<SH
#!/bin/sh
echo \$\$ > "$RUN/shell.pid"
exec /bin/bash --rcfile "$WORK/bin/rc" -i
SH
chmod +x "$WORK/bin/shell-test"; export SHELL="$WORK/bin/shell-test"
cp "$HERE_T/temoins/fauxbin-claude/claude" "$WORK/fauxbin/claude"; chmod +x "$WORK/fauxbin/claude" # exécutable par la suite, jamais par le mode du fichier versionné
ln -s "$(command -v node)" "$WORK/pathsans/node"; ln -s "$(command -v git)" "$WORK/pathsans/git"

rq() { node "$TA" req "$@"; }
sta() { rq "$@" | sed -n 1p; }
evj() { node "$AUX/ev.mjs" "$1"; }
JSONH='Content-Type:application/json'
UUID4='^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'

# ---- lab de test (PL-12.1) : partitionné, titres et compartiments hostiles, dossiers créés par chemins entre apostrophes ----
mklab() {
  local L="$1" B="$1/.planning" W="$1/.planning/workstreams"
  mkdir -p "$L/src" "$W/fiabilite/phases/"'01-"; touch pwn-titre #' "$W/fiabilite/phases/02-img" "$W/"'a$(id)' "$W/"'a$(touch pwn-ws)'
  printf 'export const u = 1;\n' > "$L/src/u.js"
  cat > "$W/fiabilite/ROADMAP.md" <<'RM'
## Phases

- [ ] **Phase 1: "; touch pwn-titre #** - titre hostile
- [ ] **Phase 2: <img src=x onerror=void(0)>** - titre balise

### Phase 1: "; touch pwn-titre #
**Goal**: $(touch pwn-goal)

### Phase 2: <img src=x onerror=void(0)>
**Goal**: Autre
RM
  printf -- '## Phases\n\n- [ ] **Phase 9: Hostile un**\n\n### Phase 9: Hostile un\n**Goal**: Un\n' > "$W/"'a$(id)'"/ROADMAP.md"
  printf -- '## Phases\n\n- [ ] **Phase 8: Hostile deux**\n\n### Phase 8: Hostile deux\n**Goal**: Deux\n' > "$W/"'a$(touch pwn-ws)'"/ROADMAP.md"
  printf -- '---\nstatus: executing\ncurrent_phase: 1\nmilestone: v1.0 MVP\n---\n' > "$W/fiabilite/STATE.md"
  printf -- '---\nwave: 1\nfiles_modified: [src/u.js]\n---\n<objective>"; touch pwn-titre #</objective>\n' > "$W/fiabilite/phases/"'01-"; touch pwn-titre #'"/01-01-PLAN.md"
  printf 'fiabilite\n' > "$B/active-workstream"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  node "$SCRIPTS/vf-cockpit.mjs" build --lab "$L" > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
}
MODULE="$(cd "$SCRIPTS/.." && pwd -P)"; MUT_OUT=""; MUT_MOD=""
mod_de() { if [ -n "$MUT_OUT" ] && [ "$1" = "$MUT_OUT" ]; then printf '%s\n' "$MUT_MOD"; else printf '%s\n' "$MODULE"; fi; } # racine du module qui sert une sortie : la copie mutée pour MUT_OUT, sinon celui du dépôt
mutant() { # mutant <nom> <fichier-du-module> <expression-sed> -> MUT_OUT (données) + MUT_MOD (copie du module muté) ; code 1 si la cible manque ou si la copie n'a pas changé (« mutant sans effet »)
  local d="$WORK/mut-$1"; rm -rf "$d"; mkdir -p "$d"; cp -R "$LAB/.planning" "$d/.planning"; cp -R "$LAB/.vibeflow" "$d/.vibeflow"
  MUT_OUT="$d/.vibeflow/cockpit"; MUT_MOD=""
  cockpit_module_muter "$(basename "$d")" "$2" "$3" || return 1
  MUT_MOD="$COCKPIT_MODULE"; unset COCKPIT_MODULE; return 0
}
LAB="$WORK/lab"; mklab "$LAB"; OUT="$LAB/.vibeflow/cockpit"

# ---- manche : serveur --terminal réel sur la sortie voulue, session du client Node (onglet A), invite ----
NM=0; SRV_PID=0; SRV_PORT=0; QP=0; SECRET=""; FPID=0; FLUX=""; PTOK=""; AMORCE=""; SHPID=""
env_serveur() { # env_serveur <pid> : environnement du processus (Linux : /proc ; macOS : ps eww), une ligne par mot
  if [ -r "/proc/$1/environ" ]; then tr '\0' '\n' < "/proc/$1/environ"; else ps eww -p "$1" 2>/dev/null | tr ' ' '\n'; fi
}
reset_run() { rm -f "$RUN/argv" "$RUN/argv.tmp" "$RUN/env" "$RUN/env.tmp" "$RUN/cwd" "$RUN/cwd.tmp"; }
serveur_debut() { # serveur_debut <sortie> [PATH d'origine du shell] -> SRV_PID SRV_PORT QP PTOK AMORCE (sans session de client)
  NM=$((NM+1)); local o="$1" porigine="${2:-$WORK/fauxbin:$PATH}" lab; lab="$(cd "$1/../.." && pwd)"
  reset_run; rm -f "$RUN/shell.pid" "$o/.cache/server.json" "$o/.cache/terminal-amorce"; mkdir -p "$o/.cache"
  AMORCE="$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")"; (umask 077; printf '%s' "$AMORCE" > "$o/.cache/terminal-amorce"; printf '%s' "$AMORCE" > "$WORK/amorce.$NM")
  local mod cm=""; mod="$(mod_de "$o")"; [ "$mod" = "$MODULE" ] || cm="$mod"   # copie mutée : l'aide vérifie que le serveur lancé la charge (code 5 sinon)
  COCKPIT_MODULE="$cm" COCKPIT_PRET=terminal COCKPIT_LOG="$WORK/serve-$NM.out" cockpit_lancer "$lab" CLAUDE_CODE_SESSION_ID=leurre-72-12 CLAUDECODE=1 FAUX_CLAUDE_SORTIE="$RUN" VF_COCKPIT_PATH_ORIGINE="$porigine" \
      VF_COCKPIT_ENGINE_DIR="$mod/skills/cockpit-moteur" VF_COCKPIT_SCRIPTS_DIR="$mod/scripts" --terminal
  SRV_PID="$VF_PID"; SRV_PORT="${VF_PORT:-0}"
  QP="$(node "$AUX/ev.mjs" '(j.terminal&&j.terminal.url)||""' < "$o/.cache/server.json" 2>/dev/null)"; QP="${QP##*:}"; QP="${QP:-0}"
  rq "$SRV_PORT" GET /project.html --corps-vers "$WORK/page-$NM.html" > /dev/null; PTOK="$(node "$AUX/ptok.mjs" "$WORK/page-$NM.html")"
}
manche_debut() { # manche_debut <sortie> [PATH d'origine du shell] -> serveur_debut + SECRET FPID FLUX SHPID (session du client Node, onglet A, invite)
  serveur_debut "$@"; FLUX="$WORK/flux-$NM.out"; : > "$FLUX"
  SECRET="$(node "$TA" amorcer "$QP" "$WORK/amorce.$NM" | sed -n 2p)"
  node "$TA" flux "$QP" "$SECRET" A "$FLUX" 600000 --taille 24x400 > "$WORK/flux-$NM.log" 2>&1 & FPID=$!; PIDS+=($FPID)
  node "$TA" attendre "$FLUX" 'VFP> ' 15000 > /dev/null
  SHPID="$(cat "$RUN/shell.pid" 2>/dev/null)"
}
manche_fin() { vf_hyg_stop "$FPID"; vf_hyg_stop "$SRV_PID"; for _ in $(seq 1 30); do [ -z "$(vf_hyg_vivants)" ] && break; sleep 0.2; done; }
# ---- gestes : P propose, Q lit, Q lance ----
PST=""; PBODY=""; PB=""; ID=""; LH=""; UU=""; ARME_LU=0
cibles_p() { rq "$SRV_PORT" GET /api/vf/lancer/cibles --jeton "$PTOK" | sed '1,2d'; }
cible_de() { printf '%s' "$1" | evj '(j.cibles.find(c=>c.id==="'"$2"'")||{})'"$3" 2>/dev/null; } # cible_de <corps> <id> <.champ>
prop_p() { # prop_p <cible> <verbe> -> PST PBODY (POST de P : Origin de P, jeton de la page Projet)
  local s; s="$(rq "$SRV_PORT" POST /api/vf/lancer --jeton "$PTOK" --entete "$JSONH" --corps "{\"cible\":\"$1\",\"verbe\":\"$2\"}")"
  PST="$(printf '%s\n' "$s" | sed -n 1p)"; PBODY="$(printf '%s\n' "$s" | sed '1,2d')"
}
get_prop() { rq "$QP" GET /proposition --sans-origin --entete 'sec-fetch-site:same-origin' --secret "$SECRET" --onglet A | sed '1,2d'; }
lire_prop() { # attente BORNÉE de l'arrivée de la proposition (IPC), puis ID LH UU ARME_LU ; la première lecture démarre l'armement
  local i; PB=""; for i in $(seq 1 40); do PB="$(get_prop)"; [ "$(printf '%s' "$PB" | evj 'j.etat' 2>/dev/null)" = en-attente ] && break; sleep 0.1; done
  ID="$(printf '%s' "$PB" | evj 'j.id' 2>/dev/null)"; LH="$(printf '%s' "$PB" | evj 'j.lignes.herite' 2>/dev/null)"; ARME_LU="$(printf '%s' "$PB" | evj 'j.arme_apres_ms' 2>/dev/null)"; ARME_LU="${ARME_LU:-0}"
  UU="$(printf '%s' "$LH" | sed -n -E "s/.*--session-id '([0-9a-f-]{36})'.*/\1/p")"; LH="${LH:-LIGNE-ABSENTE-DU-CORPS}"; UU="${UU:-UUID-ABSENT}" # un motif vide trouverait tout : jamais de vert à vide
}
attente_arme() { sleep "$(node -e "console.log(($ARME_LU + 300) / 1000)")"; } # = arme_apres_ms lu + marge : jamais une durée codée en dur
lancer_q() { rq "$QP" POST /lancer --secret "$SECRET" --onglet A --corps "{\"id\":\"${2:-$ID}\",\"mode\":\"$1\"}" | sed -n 1p; }
entree_cr() { node "$TA" entree "$QP" "$SECRET" A '\r' > /dev/null; }
attendre_argv() { for _ in $(seq 1 80); do [ -f "$RUN/argv" ] && break; sleep 0.1; done; [ -f "$RUN/argv" ] && tr '\0' '|' < "$RUN/argv" || echo absent; }
argv_absent_2s() { sleep 2; [ -e "$RUN/argv" ] && echo présent || echo absent; } # fenêtre d'observation d'une ABSENCE (bornée)
invite_apres() { node "$AUX/apres.mjs" "$FLUX" "$1" 'VFP> ' 10000; }
nlignes() { grep -a -c 'claude --session-id' "$FLUX" | tr -d ' '; }
attendu() { # attendu <mode> <verbe> <phase> <ws> <uuid> -> $WORK/attendu.argv ; LITTÉRAUX de la sonde G1 de test-cockpit-lancer-gabarit.sh (72-01), jamais importés (PL-12.4)
  local imp=INCONNU; case "$2" in cadrer) imp=Cadre ;; planifier) imp=Planifie ;; executer) imp=Execute ;; verifier) imp=Verifie ;; reprendre) imp=Reprends ;; esac
  { printf '%s\0' --session-id "$5" -n "vf-phase-$3-$4"; [ "$1" = herite ] || printf '%s\0' --permission-mode "$1"; printf '%s\0' "/vf-dev $imp la Phase $3 du compartiment $4"; } > "$WORK/attendu.argv"
}
comparer() { if cmp -s "$RUN/argv" "$WORK/attendu.argv"; then echo identique; else echo "différent : obtenu [$(tr '\0' '|' < "$RUN/argv" 2>/dev/null)] attendu [$(tr '\0' '|' < "$WORK/attendu.argv")]"; fi; }
lancement() { # lancement <cible> <verbe> <mode> -> LS (statut de POST /lancer) ; proposition, lecture, armement, lancement, Entrée du client, argv
  reset_run; prop_p "$1" "$2"; lire_prop; attente_arme; LS="$(lancer_q "$3")"
}
BASE=""

echo "=== B0 — témoin : serveur réel, session du client (onglet A), invite, claude = le faux du PATH d'origine ==="
manche_debut "$OUT"
assert_eq "B0 — ports de P et de Q distincts, au moins 4600, jamais 4456" "$([ "$SRV_PORT" -ge 4600 ] && [ "$QP" -ge 4600 ] && [ "$SRV_PORT" != 4456 ] && [ "$QP" != 4456 ] && [ "$SRV_PORT" != "$QP" ] && echo oui || echo "non P=$SRV_PORT Q=$QP")" "oui"
assert_eq "B0 — l'échange de l'amorçage rend un secret de 64 hexadécimaux, et la page Projet porte un jeton" "$([[ "$SECRET" =~ ^[0-9a-f]{64}$ ]] && echo oui || echo "non : ${SECRET:-vide}") $([ -n "$PTOK" ] && echo jeton || echo sans-jeton)" "oui jeton"
assert_eq "B0 — le flux de l'onglet A atteint l'invite VFP> et GET /etat rend « vivante »" "$(grep -a -c 'VFP> ' "$FLUX" | tr -d ' ' | sed 's/^[1-9][0-9]*$/invite/') $(node "$TA" etat "$QP" "$SECRET" | sed '1,2d' | evj 'j.session')" "invite vivante"
assert_eq "B0 — le PID enregistré est celui du shell (exec) et ce shell est au premier plan de son terminal" "$([ -n "$SHPID" ] && [ "$(ps -o pgid= -p "$SHPID" | tr -d ' ')" = "$SHPID" ] && echo oui || echo "non ($SHPID)")" "oui"
SZ0="$(wc -c < "$FLUX" | tr -d ' ')"; node "$TA" entree "$QP" "$SECRET" A 'command -v claude\r' > /dev/null
assert_eq "B0 — « command -v claude » tapé au shell imprime le faux claude du PATH d'origine (PATH restitué par envShell)" "$(node "$AUX/apres-off.mjs" "$FLUX" "$SZ0" "$WORK/fauxbin/claude" 8000)" "TROUVE"
LEURRE_SRV="$(env_serveur "$SRV_PID")"
assert_eq "B0 — témoin des leurres : le serveur porte CLAUDECODE=1 et CLAUDE_CODE_SESSION_ID=leurre-72-12 dans son environnement (sans eux, leur absence chez le faux claude ne prouve rien)" "$(printf '%s\n' "$LEURRE_SRV" | grep -c -x -e 'CLAUDECODE=1' -e 'CLAUDE_CODE_SESSION_ID=leurre-72-12' | tr -d ' ')" "2"

echo "=== B1 / B2 / B5 — lancement herite de la phase 1 : proposition de P, lecture, armement, 204, Entrée du client ==="
BASE="$(cibles_p)"
V1="$(cible_de "$BASE" ph-1 .principal)"; PH1="$(cible_de "$BASE" ph-1 .id)"; PH2="$(cible_de "$BASE" ph-2 .principal)"
assert_eq "B1 — GET cibles : ph-1 (titre hostile) est lançable (aucun bloquant), son principal est parmi ses verbes ; témoin : la liste porte des cartes" "$PH1 $(cible_de "$BASE" ph-1 '.bloquants.length') $(printf '%s' "$BASE" | evj 'j.cibles.length>0') $(printf '%s' "$BASE" | evj '(c=>c.verbes.includes(c.principal))(j.cibles.find(c=>c.id==="ph-1"))')" "ph-1 0 true true"
reset_run; prop_p ph-1 "$V1"; lire_prop
assert_eq "B1 — POST /api/vf/lancer de P (Origin de P, jeton de page Projet) : 202 ; GET /proposition de Q : en-attente, UUID v4 dans la ligne herite" "$PST $(printf '%s' "$PB" | evj 'j.etat') $([[ "$UU" =~ $UUID4 ]] && echo uuid-v4 || echo "pas-un-uuid-v4 ($UU)")" "202 en-attente uuid-v4"
attente_arme; S204="$(lancer_q herite)"
assert_eq "B2 — POST /lancer {id, mode:herite} de Q (Origin de Q, secret, onglet A) après armement : 204 (témoin positif des refus qui suivent)" "$S204" "204"
assert_eq "B2 — la ligne herite exacte de GET /proposition est à l'invite (écrite, pas exécutée)" "$(node "$TA" attendre "$FLUX" "$LH" 8000)" "TROUVE"
assert_eq "B5 — après 204 et AVANT toute frappe : le faux claude n'a pas tourné (argv absent 2 s)" "$(argv_absent_2s)" "absent"
entree_cr
attendre_argv > /dev/null; attendu herite "$V1" 1 fiabilite "$UU"
assert_eq "B2 — après l'Entrée du client : argv du faux claude identique OCTET POUR OCTET au tableau attendu (--session-id, UUID de la ligne, -n, vf-phase-1-fiabilite, aucun --permission-mode, /vf-dev <intention>)" "$(comparer)" "identique"
assert_eq "B5 — témoin : le faux claude a tourné après l'Entrée (argv présent)" "$([ -e "$RUN/argv" ] && echo présent || echo absent)" "présent"
for _ in $(seq 1 30); do [ -e "$RUN/env" ] && [ -e "$RUN/cwd" ] && break; sleep 0.1; done
assert_eq "B2 — lancé à la racine du lab (dossier courant physique = racine du lab)" "$(cat "$RUN/cwd" 2>/dev/null)" "$LAB"
assert_eq "B2 — l'environnement du faux claude ne porte ni CLAUDECODE ni CLAUDE_CODE_* ni VF_COCKPIT_* (témoin : FAUX_CLAUDE_SORTIE et TERM y figurent)" "$(grep -c -E '^(CLAUDECODE|CLAUDE_CODE_.*|VF_COCKPIT_.*)$' "$RUN/env" | tr -d ' ') $(grep -c -x -e FAUX_CLAUDE_SORTIE -e TERM "$RUN/env" | tr -d ' ')" "0 2"
assert_eq "B2 — aucun fichier pwn-* dans le lab (titre hostile inerte)" "$(ls "$LAB" | grep -c '^pwn-' | tr -d ' ')" "0"
invite_apres "$LH" > /dev/null

echo "=== B3 — quatre modes : default, acceptEdits, plan avec --permission-mode avant le prompt (herite : B2) ==="
for M in default acceptEdits plan; do
  lancement ph-1 "$V1" "$M"; SZ="$(wc -c < "$FLUX" | tr -d ' ')"; entree_cr; RES="$(attendre_argv)"; attendu "$M" "$V1" 1 fiabilite "$UU"
  assert_eq "B3 — mode $M : POST /lancer 204 puis, après l'Entrée, argv identique octet pour octet (--permission-mode '$M' avant le prompt, sinon comme B2)" "$PST $LS $(comparer)" "202 204 identique"
  assert_eq "B3 — mode $M : exactement un --permission-mode dans l'argv, valant $M (témoin de la comparaison : l'argv n'est pas vide)" "$([ "$RES" != absent ] && echo non-vide) $(tr '\0' '\n' < "$RUN/argv" | grep -c -x -e '--permission-mode' | tr -d ' ') $(tr '\0' '\n' < "$RUN/argv" | sed -n '/^--permission-mode$/{n;p;}')" "non-vide 1 $M"
  invite_apres "$LH" > /dev/null
done

echo "=== B4 — cible lancée, rejeu refusé, avertissement de récence ==="
LANCEE=""; for _ in $(seq 1 40); do LANCEE="$(cible_de "$(cibles_p)" ph-1 '.lancee')"; [ -n "$LANCEE" ] && [ "$LANCEE" != "false" ] && break; sleep 0.1; done
BASE4="$(cibles_p)"
assert_eq "B4 — GET cibles : ph-1 est marquée lancée (forme riche livrée : un objet à état et verbe, jamais false) ; ph-2, jamais lancée, reste false" "$(cible_de "$BASE4" ph-1 '.lancee' | evj 'typeof j === "object" && j !== null && typeof j.etat === "string" && typeof j.verbe === "string"') $(cible_de "$BASE4" ph-2 .lancee)" "true false"
assert_eq "B4 — second POST /lancer du même id (consommé) : 404" "$(lancer_q plan "$ID")" "404"
prop_p ph-1 "$V1"; lire_prop
assert_eq "B4 — la seconde proposition de ph-1 porte lancement-recent dans ses avertissements, sans bloquer (202, aucun bloquant)" "$PST $(printf '%s' "$PB" | evj 'j.avertissements.includes("lancement-recent")') $(printf '%s' "$PB" | evj 'j.bloquants.length')" "202 true 0"
ann() { rq "$QP" POST /annuler --secret "$SECRET" --onglet A --corps "{\"id\":\"$1\"}" | sed -n 1p; }
assert_eq "B4 — POST /annuler retire cette proposition (204) : GET /proposition rend aucune" "$(ann "$ID") $(get_prop)" '204 {"etat":"aucune"}'

echo "=== B6 — compartiments hostiles a\$(id) et a\$(touch pwn-ws) : bloquant, refus, rien d'exécuté ==="
BASE6="$(cibles_p)"; NA="$(nlignes)"; reset_run
RP8="$(rq "$SRV_PORT" POST /api/vf/lancer --jeton "$PTOK" --entete "$JSONH" --corps '{"cible":"ph-8","verbe":"cadrer"}')"; RP9="$(rq "$SRV_PORT" POST /api/vf/lancer --jeton "$PTOK" --entete "$JSONH" --corps '{"cible":"ph-9","verbe":"cadrer"}')"
assert_eq "B6 — GET cibles : les cartes ph-8 et ph-9 portent le bloquant compartiment-hors-motif (témoin : ph-1 n'en porte aucun)" "$(cible_de "$BASE6" ph-8 '.bloquants.join()') $(cible_de "$BASE6" ph-9 '.bloquants.join()') [$(cible_de "$BASE6" ph-1 '.bloquants.join()')]" "compartiment-hors-motif compartiment-hors-motif []"
assert_eq "B6 — POST /api/vf/lancer pour ph-8 et ph-9 : 409 (bloque), jamais 202" "$(printf '%s\n' "$RP8" | sed -n 1p) $(printf '%s\n' "$RP9" | sed -n 1p)" "409 409"
assert_eq "B6 — aucune proposition n'est arrivée à Q (GET /proposition : aucune), aucun argv, aucune ligne de plus à l'invite" "$(get_prop) $([ -e "$RUN/argv" ] && echo argv || echo sans-argv) $([ "$(nlignes)" = "$NA" ] && echo lignes-inchangees || echo lignes-en-plus)" '{"etat":"aucune"} sans-argv lignes-inchangees'
assert_eq "B6 — aucun fichier pwn-ws ni pwn-* dans le lab ; aucune réponse (cibles, POST) ne contient « \$( »" "$(ls "$LAB" | grep -c '^pwn-' | tr -d ' ') $(printf '%s\n%s\n%s' "$BASE6" "$RP8" "$RP9" | grep -c -F '$(' | tr -d ' ')" "0 0"
prop_p ph-1 "$V1"; lire_prop
assert_eq "B6 — témoin positif dans la même exécution : le POST de ph-1 rend 202 et Q a la proposition" "$PST $(printf '%s' "$PB" | evj 'j.etat')" "202 en-attente"
ann "$ID" > /dev/null

echo "=== B7 — proposition sans confirmation : rien d'écrit, puis annulée ==="
prop_p ph-2 "$PH2"; reset_run; NB="$(nlignes)"; lire_prop
assert_eq "B7 — témoin : la proposition de ph-2 est arrivée à Q (en-attente) et armée au sens de arme_apres_ms lu ($ARME_LU)" "$PST $(printf '%s' "$PB" | evj 'j.etat') $([ "$ARME_LU" -gt 0 ] && echo arme-lu || echo arme-illisible)" "202 en-attente arme-lu"
sleep "$(node -e "console.log(($ARME_LU + 1500) / 1000)")" # fenêtre d'observation d'une ABSENCE : arme_apres_ms + 1,5 s
assert_eq "B7 — sans confirmation : aucun argv, aucune ligne claude de plus à l'invite, la proposition est toujours en attente" "$([ -e "$RUN/argv" ] && echo argv || echo sans-argv) $([ "$(nlignes)" = "$NB" ] && echo lignes-inchangees || echo lignes-en-plus) $(get_prop | evj 'j.etat + " " + (j.id === "'"$ID"'")')" "sans-argv lignes-inchangees en-attente true"
assert_eq "B7 — POST /annuler : 204 puis aucune" "$(ann "$ID") $(get_prop)" '204 {"etat":"aucune"}'

echo "=== B8 — programme au premier plan (sleep 30) : 409, rien d'écrit ; à son retour, 204 et le lancement aboutit ==="
node "$TA" entree "$QP" "$SECRET" A 'sleep 30\r' > /dev/null
SLP=""; for _ in $(seq 1 50); do SLP="$(command pgrep -P "$SHPID" | head -1)"; [ -n "$SLP" ] && break; sleep 0.1; done
PGSLP="$(ps -o pgid= -p "${SLP:-0}" 2>/dev/null | tr -d ' ')"
assert_eq "B8 — témoin : sleep occupe le premier plan (groupe du processus différent du PID du shell)" "$([ -n "$PGSLP" ] && [ "$PGSLP" != "$SHPID" ] && echo premier-plan || echo "non (${PGSLP:-aucun})")" "premier-plan"
reset_run; NC="$(nlignes)"; prop_p ph-1 "$V1"; lire_prop; attente_arme; S409="$(lancer_q herite)"; VIVANT="$(kill -0 "${SLP:-0}" 2>/dev/null && echo vivant || echo mort)"
assert_eq "B8 — POST /lancer rend 409, le sleep vit toujours, aucun argv, aucune ligne de plus à l'invite, la proposition est toujours en attente (même id)" "$S409 $VIVANT $([ -e "$RUN/argv" ] && echo argv || echo sans-argv) $([ "$(nlignes)" = "$NC" ] && echo lignes-inchangees || echo lignes-en-plus) $(get_prop | evj 'j.id === "'"$ID"'"')" "409 vivant sans-argv lignes-inchangees true"
SZ8="$(wc -c < "$FLUX" | tr -d ' ')"; PPID_SLP="$(ps -o ppid= -p "${SLP:-0}" 2>/dev/null | tr -d ' ')"; [ "$PPID_SLP" = "$SHPID" ] && kill "$SLP" 2>/dev/null # arrêté par son PID, fils du shell vérifié
assert_eq "B8 — après la fin du programme, l'invite revient" "$(node "$AUX/apres-off.mjs" "$FLUX" "$SZ8" 'VFP> ' 10000)" "TROUVE"
S204b="$(lancer_q herite)"
assert_eq "B8 — témoin positif : après le retour de l'invite, le même POST /lancer rend 204 et la ligne paraît à l'invite" "$S204b $(node "$TA" attendre "$FLUX" "$LH" 8000)" "204 TROUVE"
entree_cr; attendre_argv > /dev/null; attendu herite "$V1" 1 fiabilite "$UU"
assert_eq "B8 — après l'Entrée : le lancement aboutit (argv exact)" "$(comparer)" "identique"
manche_fin

echo "=== B9 — sans claude dans le PATH d'origine : bloquant claude-introuvable, refus ==="
manche_debut "$OUT" "$WORK/pathsans"
BASE9="$(cibles_p)"; prop_p ph-1 cadrer
assert_eq "B9 — PATH d'origine sans claude : GET cibles rend claude:false et ph-1 porte claude-introuvable" "$(printf '%s' "$BASE9" | evj 'j.claude') $(cible_de "$BASE9" ph-1 '.bloquants.includes("claude-introuvable")')" "false true"
assert_eq "B9 — POST /api/vf/lancer pour ph-1 : 409 (bloque) ; GET /proposition rend aucune (témoin : le terminal est actif, la cause est donc claude)" "$PST $(printf '%s' "$BASE9" | evj 'j.terminal') $(get_prop)" '409 actif {"etat":"aucune"}'
manche_fin

# ---- section CH : Chromium ----
echo "=== CH — Chromium : bandeau, clic de confiance armé, Entrée au clavier, présélection du mode ==="
if [ -n "$CHROME" ]; then
  rm -rf "$VF_COCKPIT_MODE_DIR" # 72-16 (P72-D-20, AUDC-B-05) : le mode retenu par les manches B (dossier d'état du poste, ici jetable) survit aux relances de Q ; CH2 parle d'un PREMIER lancement, donc d'un état absent
  serveur_debut "$OUT"; RESCH="$WORK/ch.json"; BASEC="$(cibles_p)"; VC="$(cible_de "$BASEC" ph-1 .principal)" # le navigateur est la session : aucun client Node ici
  echo "     [CH] Chrome : $("$CHROME" --version 2>/dev/null | head -1)"
  CHJ="$(printf '{"P":%s,"Q":%s,"amorce":"%s","ptoken":"%s","cible":"ph-1","verbe":"%s","argv":"%s/argv"}' "$SRV_PORT" "$QP" "$AMORCE" "$PTOK" "$VC" "$RUN")"
  node "$HERE_T/chrome-lancer.mjs" "$CHROME" "$CHJ" > "$RESCH" 2> "$WORK/ch.err"
  CH="$(cat "$RESCH")"; echo "     [CH] constats : ${CH:0:600}"
  chj() { printf '%s\n' "$CH" | node "$AUX/ev.mjs" "$1" 2>/dev/null || echo ILLISIBLE; }
  assert_eq "CH0 — témoin : le pilote n'a rendu aucune erreur nommée (ni d'ensemble, ni d'étape)" "$(chj 'j.erreur||JSON.stringify(j.erreurs)')" "{}"
  assert_eq "CH1 — amorçage par la page P puis Q dans son cadre : la grille xterm porte l'invite VFP> " "$(chj 'j.invite')" "true"
  assert_eq "CH2 — après POST /api/vf/lancer : le bandeau paraît en moins de 4 s ; sa ligne porte « claude --session-id ' » et « -n 'vf-phase-1-fiabilite' » ; le sélecteur vaut default (premier lancement)" "$(chj 'j.ch2.duree<4000')/$(chj 'j.ch2.ligne.includes("claude --session-id '"'"'")&&j.ch2.ligne.includes("-n '"'"'vf-phase-1-fiabilite'"'"'")')/$(chj 'j.ch2.mode')" "true/true/default"
  assert_eq "CH3 — clic de confiance AVANT l'armement (aria-disabled vrai relevé au même instant que le centre du bouton) : le bandeau reste, aucune ligne claude dans la grille, argv absent" "$(chj 'j.ch3.desactive')/$(chj 'j.ch3.cible')/$(chj 'j.ch3.bandeau')/$(chj 'j.ch3.lignes')/$(chj 'j.ch3.argv')" "true/proposition-lancer/true/0/absent"
  assert_eq "CH4 — après armement, le sélecteur passe à acceptEdits (valeur posée et événement change) : la ligne porte --permission-mode 'acceptEdits'" "$(chj 'j.ch4.arme')/$(chj 'j.ch4.mode')/$(chj 'j.ch4.ligne.includes("--permission-mode '"'"'acceptEdits'"'"'")')" "true/acceptEdits/true"
  assert_eq "CH5 — clic de confiance après armement : le bandeau disparaît, la ligne est à l'invite de la grille, SANS Entrée : argv absent 2 s" "$(chj 'j.ch5.bandeau')/$(chj 'j.ch5.grille')/$(chj 'j.ch5.argv')" "false/true/absent"
  CHUU="$(chj 'j.ch2.uuid')"; attendu acceptEdits "$VC" 1 fiabilite "$CHUU"; for _ in $(seq 1 50); do [ -f "$RUN/argv" ] && break; sleep 0.1; done
  assert_eq "CH6 — Entrée du clavier (Input.dispatchKeyEvent) : le faux claude tourne, argv identique octet pour octet (acceptEdits, UUID lu dans la ligne affichée avant le clic)" "$(chj 'j.ch6.argv')/$([[ "$CHUU" =~ $UUID4 ]] && comparer || echo "uuid illisible ($CHUU)")" "present/identique"
  assert_eq "CH7 — seconde proposition de ph-1 : le sélecteur présélectionne acceptEdits (dernier mode LANCÉ avec succès) et la zone des pré-vols porte l'avertissement de récence" "$(chj 'j.ch7.mode')/$(chj 'j.ch7.recent')" "acceptEdits/true"
  assert_eq "CH8 — clic de confiance sur « Annuler » : le bandeau disparaît et GET /proposition rend aucune" "$(chj 'j.ch8.bandeau')/$(chj 'j.ch8.etat')" "false/aucune"
  assert_eq "CH9 — zéro violation CSP relevée par la session pendant le scénario, zéro échec nommé d'une étape" "$(chj 'j.violations.length')/$(chj 'Object.keys(j.erreurs||{}).length')" "0/0"
  vf_hyg_stop "$SRV_PID"
else
  nonverif "CH1 à CH9 (bandeau, clic de confiance armé, Entrée au clavier, présélection du mode)"
fi

# ---- mutants : copies du module, résultat fautif exact asserté (la sonde rougit pour la bonne raison) ----
echo "=== M-RETOUR-CHARIOT — la ligne part avec un retour chariot : B2 rougit ==="
if mutant cr vf-cockpit-terminal-processus.mjs "s#sessions.lancer(ligneQ, onglet)#sessions.lancer(ligneQ + '\\\\r', onglet)#"; then
  manche_debut "$MUT_OUT"; prop_p ph-1 "$V1"; lire_prop; attente_arme; R="$(lancer_q herite)"
  assert_eq "M-RETOUR-CHARIOT — sous le mutant, l'assistant refuse la ligne (400 au lieu de 204) et elle n'arrive pas à l'invite : B2 rougit" "$R $(node "$TA" attendre "$FLUX" "$LH" 3000) $([ -e "$RUN/argv" ] && echo argv || echo sans-argv)" "400 ABSENT sans-argv"; manche_fin
else assert_eq "M-RETOUR-CHARIOT — mutant sans effet (ancre absente ou inchangée)" "sans effet" "effet"; fi
echo "=== M-LISTE-PAGE — les deux gardes d'appartenance de proposer() retirées (recherche de cible ET verdict) : B6 rougit ==="
if mutant liste-page vf-cockpit-lancer.mjs "s|const cible = liste.find((x) => x.id === demande.cible);|const cible = { id: demande.cible, verbes: [demande.verbe], bloquants: [], avertissements: [], kind: 'phase', phase: '1', ws: null };|
s|const v = verdict(liste, cible.id, demande.verbe);.*$|const v = { lancable: true, bloquants: [] };|"; then
  manche_debut "$MUT_OUT"; prop_p ph-9 cadrer; R="$PST"
  assert_eq "M-LISTE-PAGE — sous le mutant, la carte du compartiment hostile ph-9 est proposée (202 au lieu de 409) : B6 rougit" "$R" "202"; manche_fin
else assert_eq "M-LISTE-PAGE — mutant sans effet (ancre absente ou inchangée)" "sans effet" "effet"; fi

vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL ($NONVERIF non vérifiées sans navigateur)"; echo "=================================="
[ $((PASS+FAIL)) -ge 30 ] || { echo "  ❌ FAIL — anti-vert-à-vide : moins de 30 assertions jouées"; exit 1; }
[ "$FAIL" -eq 0 ]
