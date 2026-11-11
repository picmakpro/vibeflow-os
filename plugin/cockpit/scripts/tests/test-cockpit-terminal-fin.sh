#!/usr/bin/env bash
# test-cockpit-terminal-fin.sh — terminal : la vraie cause d'un onglet sans amorce, « Terminer la session », bandeau de lancement (audit du cockpit, lot 0 ; AUDC-M10, AUDC-M11).
#   FIN.1  onglet de Q ouvert à la main (aucun secret) : la carte dit la vraie cause (amorce à usage unique, 60 s, déjà utilisée ou périmée) et le remède (relancer la commande)
#   FIN.2  POST /api/vf/terminal/terminer : refusé sans le jeton de la page ; avec lui, le shell disparaît (processus), la session est « terminée », le serveur reste actif
#          (une attache neuve lance un autre shell) ; sans session, la demande est inoffensive
#   FIN.3  page Projet réelle sous Chrome : le libellé de « Terminer la session » tient dans l'en-tête à 1280, 1440 et 1024 px ; « Terminer la session » demande un double geste, le premier ne termine rien, le second fait disparaître le shell ; la barre dit « Terminé »
#   FIN.4  bandeau de lancement à la hauteur par défaut : la phrase « écrit cette ligne sans la lancer » et la liste des modes sont visibles, le tiroir s'ajuste au bandeau ;
#          après « Annuler », le statut du panneau (« Proposition envoyée… Confirmez-la ») ET l'annonce du cadre du terminal (« Lancement proposé : … Expire dans … ») reviennent à zéro
# Chaque absence a son témoin positif dans le même scénario. Sans Chrome : FIN.1, FIN.3 et FIN.4 annoncent « NON vérifiée ». Exit 0 si tout passe, 1 sinon.
set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; }
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
ENG="$(cd "$SCRIPTS/../skills/cockpit-moteur" && pwd -P)"; TA="$HERE_T/terminal-aux.mjs"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; RUN="$WORK/run"; mkdir -p "$AUX" "$WORK/home" "$WORK/bin" "$WORK/tmp-serveur" "$RUN"
export REAL_HOME="$HOME"; export HOME="$WORK/home"; export CHROME_SESSION="$HERE_T/chrome-session.mjs"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0; NONVERIF=0
court() { if [ "${#1}" -gt 300 ]; then printf '%s […] %s' "${1:0:140}" "${1: -140}"; else printf '%s' "$1"; fi; }
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$(court "$3")]"; echo "     obtenu:  [$(court "$2")]"; FAIL=$((FAIL+1)); fi; }
nonverif() { echo "  ⊘ $1 — NON vérifiée sans navigateur, non comptée comme réussie"; NONVERIF=$((NONVERIF+1)); }
CHROME=""
for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue
  if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
echo "navigateur : ${CHROME:-aucun}"

cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
# shell de test : écrit son PID (le PID reste celui du shell, exec) puis un shell interactif
cat > "$WORK/bin/shell-test" <<SH
#!/bin/sh
echo \$\$ > "$RUN/shell.pid"
exec /bin/sh -i
SH
chmod +x "$WORK/bin/shell-test"; export SHELL="$WORK/bin/shell-test"
rq() { node "$TA" req "$@"; }
sj() { node "$AUX/ev.mjs" "$1" < "$OUT/.cache/server.json" 2>/dev/null; }
mklab() {
  local L="$1" B="$1/.planning"; mkdir -p "$L/src" "$B/phases/01-socle"; printf 'export const u = 1;\n' > "$L/src/u.js"
  printf -- '## Phases\n\n- [ ] **Phase 1: Socle** - premier jet\n\n### Phase 1: Socle\n**Goal**: Poser le socle\n' > "$B/ROADMAP.md"
  printf -- '---\nstatus: executing\ncurrent_phase: 1\nmilestone: v1.0 MVP\n---\n' > "$B/STATE.md"
  printf -- '---\nwave: 1\nfiles_modified: [src/u.js]\n---\n<objective>Poser le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  node "$SCRIPTS/vf-cockpit.mjs" build --lab "$L" > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
}
LAB="$WORK/lab"; mklab "$LAB"; OUT="$LAB/.vibeflow/cockpit"
NS=0; SRV_PID=0; SRV_PORT=0; QP=0
srv() { # serveur --terminal réel ; amorce neuve dans le fichier du lanceur -> SRV_PID SRV_PORT QP AMORCE
  NS=$((NS+1)); rm -f "$OUT/.cache/server.json" "$RUN/shell.pid"; mkdir -p "$OUT/.cache"
  AMORCE="$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")"; (umask 077; printf '%s' "$AMORCE" > "$OUT/.cache/terminal-amorce")
  ( cd "$LAB" && VF_COCKPIT_ENGINE_DIR="$ENG" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS" TMPDIR="$WORK/tmp-serveur" exec node "$OUT/serve.mjs" --no-open --terminal --port "$(libre)" > "$WORK/serve-$NS.out" 2>&1 ) </dev/null >/dev/null 2>&1 &
  SRV_PID=$!; PIDS+=($SRV_PID)
  for _ in $(seq 1 100); do grep -q '"terminal"' "$OUT/.cache/server.json" 2>/dev/null && break; sleep 0.1; done
  SRV_PORT="$(sj j.port)"; QP="$(sj '(j.terminal&&j.terminal.url)||""')"; QP="${QP##*:}"
}
unsrv() { vf_hyg_stop "$SRV_PID"; }
vivant() { kill -0 "$1" 2>/dev/null && echo oui || echo non; }
mort_avant() { local fin=$((SECONDS+$2)); while [ $SECONDS -le $fin ]; do [ "$(vivant "$1")" = non ] && return 0; sleep 0.2; done; return 1; }
chrome_fin() { node "$HERE_T/chrome-fin.mjs" "$CHROME" "$1" 2> "$WORK/chrome.err"; } # chrome_fin <json> -> une ligne JSON

# ---------- FIN.1 : la vraie cause ----------
echo "=== FIN.1 — onglet ouvert à la main : la carte dit la vraie cause ==="
srv
if [ -n "$CHROME" ]; then
  R="$(chrome_fin "$(printf '{"mode":"carte","P":%s,"Q":%s}' "$SRV_PORT" "$QP")")"
  CARTE="$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.carte||""')"
  assert_eq "FIN.1 — témoin : la carte d'état est affichée (role alert)" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.carteRole||"absent"')" "alert"
  assert_eq "FIN.1 — la carte nomme l'amorce à usage unique" "$(printf '%s' "$CARTE" | grep -ci "usage unique")" "1"
  assert_eq "FIN.1 — la carte donne la durée de validité (60 s)" "$(printf '%s' "$CARTE" | grep -c "60 s")" "1"
  assert_eq "FIN.1 — la carte dit que l'amorce est déjà utilisée ou périmée" "$(printf '%s' "$CARTE" | grep -ci "périmée")" "1"
  assert_eq "FIN.1 — la carte donne le remède (la commande qui en prépare une neuve)" "$(printf '%s' "$CARTE" | grep -c '/vf-cockpit --terminal')" "1"
  assert_eq "FIN.1 — la carte ne dit plus « non disponible »" "$(printf '%s' "$CARTE" | grep -ci "non disponible")" "0"
else nonverif "FIN.1"; fi
unsrv

# ---------- FIN.2 : route « terminer » ----------
echo "=== FIN.2 — POST /api/vf/terminal/terminer ==="
srv
PTOK="$(curl -s "http://127.0.0.1:$SRV_PORT/project.html" | grep -o 'VF_COCKPIT_SERVER={"token":"[0-9a-f]*"' | head -1 | sed 's/.*"token":"//;s/"//')"
AM="$AMORCE"; printf '%s' "$AM" > "$WORK/amorce.txt"; SEC="$(node "$TA" amorcer "$QP" "$WORK/amorce.txt" | sed -n 2p)"
ONG="$(node -e "console.log(require('crypto').randomBytes(16).toString('hex'))")"
node "$TA" flux "$QP" "$SEC" "$ONG" "$WORK/flux1.bin" 30000 > /dev/null 2>&1 & FL=$!; PIDS+=($FL)
for _ in $(seq 1 80); do [ -s "$RUN/shell.pid" ] && break; sleep 0.1; done
SH1="$(cat "$RUN/shell.pid" 2>/dev/null)"
assert_eq "FIN.2 — témoin : le shell tourne (session vivante)" "$(vivant "${SH1:-0}") $(node "$TA" etat "$QP" "$SEC" | sed -n 3p | node "$AUX/ev.mjs" 'j.session')" "oui vivante"
terminer() { rq "$SRV_PORT" POST /api/vf/terminal/terminer --jeton "$1" --corps '{}' --entete 'Content-Type:application/json' | sed -n 1p; }
assert_eq "FIN.2 — sans jeton de page : refusé (403), le shell vit encore" "$(terminer "mauvais-jeton") $(vivant "${SH1:-0}")" "403 oui"
assert_eq "FIN.2 — avec le jeton de la page : accepté (200)" "$(terminer "$PTOK")" "200"
assert_eq "FIN.2 — le processus du shell a disparu" "$(mort_avant "${SH1:-0}" 20 && echo oui || echo non)" "oui"
assert_eq "FIN.2 — la session n'est plus vivante (la place est en fermeture puis libre : « absente », jamais « vivante »)" "$(node "$TA" etat "$QP" "$SEC" | sed -n 3p | node "$AUX/ev.mjs" 'j.session')" "absente"
rm -f "$RUN/shell.pid"
node "$TA" flux "$QP" "$SEC" "$ONG" "$WORK/flux2.bin" 30000 > /dev/null 2>&1 & FL2=$!; PIDS+=($FL2)
for _ in $(seq 1 80); do [ -s "$RUN/shell.pid" ] && break; sleep 0.1; done
SH2="$(cat "$RUN/shell.pid" 2>/dev/null)"
assert_eq "FIN.2 — le serveur reste actif : une attache neuve lance un autre shell" "$([ -n "$SH2" ] && [ "$SH2" != "$SH1" ] && echo oui || echo non) $(vivant "${SH2:-0}")" "oui oui"
vf_hyg_stop "$FL"; vf_hyg_stop "$FL2"
unsrv
srv
assert_eq "FIN.2 — sans session : la demande est inoffensive (200)" "$(terminer "$(curl -s "http://127.0.0.1:$SRV_PORT/project.html" | grep -o 'VF_COCKPIT_SERVER={"token":"[0-9a-f]*"' | head -1 | sed 's/.*"token":"//;s/"//')")" "200"
unsrv

# ---------- FIN.2b : une seule session (P71-D-05) ----------
echo "=== FIN.2b — shell qui ignore les signaux : la place reste prise jusqu'à sa mort ==="
printf '#!/bin/sh\necho $$ > "%s/shell.pid"\ntrap "" HUP TERM INT\nexec sleep 40\n' "$RUN" > "$WORK/bin/shell-tetu"; chmod +x "$WORK/bin/shell-tetu"
SHELL_AVANT="$SHELL"; export SHELL="$WORK/bin/shell-tetu"
srv
PTOK="$(curl -s "http://127.0.0.1:$SRV_PORT/project.html" | grep -o 'VF_COCKPIT_SERVER={"token":"[0-9a-f]*"' | head -1 | sed 's/.*"token":"//;s/"//')"
printf '%s' "$AMORCE" > "$WORK/amorce.txt"; SEC="$(node "$TA" amorcer "$QP" "$WORK/amorce.txt" | sed -n 2p)"
ONG="$(node -e "console.log(require('crypto').randomBytes(16).toString('hex'))")"
node "$TA" flux "$QP" "$SEC" "$ONG" "$WORK/fluxT1.bin" 30000 > /dev/null 2>&1 & FT=$!; PIDS+=($FT)
for _ in $(seq 1 80); do [ -s "$RUN/shell.pid" ] && break; sleep 0.1; done
SHT="$(cat "$RUN/shell.pid" 2>/dev/null)"
assert_eq "FIN.2b — témoin : le shell obstiné tourne" "$(vivant "${SHT:-0}")" "oui"
terminer "$PTOK" > /dev/null
ATT="$(rq "$QP" GET /flux --secret "$SEC" --onglet "$ONG" --echeance 1500 | sed -n 1p)"
assert_eq "FIN.2b — ré-attache immédiate : refusée (503) tant que l'ancien shell vit, jamais un second shell" "$ATT $(vivant "${SHT:-0}")" "503 oui"
assert_eq "FIN.2b — l'ancien shell finit par mourir (fermeture bornée)" "$(mort_avant "${SHT:-0}" 25 && echo oui || echo non)" "oui"
export SHELL="$SHELL_AVANT"; vf_hyg_stop "$FT"
unsrv

# ---------- FIN.3 et FIN.4 : page Projet réelle ----------
echo "=== FIN.3 et FIN.4 — page Projet sous Chrome ==="
if [ -n "$CHROME" ]; then
  srv
  R="$(chrome_fin "$(printf '{"mode":"session","P":%s,"Q":%s,"amorce":"%s","pidShell":"%s"}' "$SRV_PORT" "$QP" "$AMORCE" "$RUN/shell.pid")")"
  echo "     [mesures] $(printf '%s' "$R" | node "$AUX/ev.mjs" 'JSON.stringify({tiroir:j.tiroir,cadre:j.cadre,bandeau:j.bandeau,phrase:j.phrase,modes:j.modes,erreurs:j.erreurs})')"
  g() { printf '%s' "$R" | node "$AUX/ev.mjs" "$1"; }
  assert_eq "FIN.3 — témoin : le bouton « Terminer la session » est présent et le shell tourne" "$(g 'j.pidVivantAvant')" "true"
  assert_eq "FIN.3 — le premier geste ne termine rien (le bouton demande confirmation)" "$(g 'j.pidVivantApresPremier') $(g 'j.apresPremier' | grep -ci 'confirmer')" "true 1"
  assert_eq "FIN.3 — le second geste : le processus du shell a disparu" "$(g 'j.pidVivantApres')" "false"
  assert_eq "FIN.3 — la barre du tiroir dit « Terminé » et le bouton se retire" "$(g 'j.barre') $(g 'j.boutonMasque')" "Terminé true"
  assert_eq "FIN.4 — témoin : le panneau a dit « Proposition envoyée » avant l'annulation" "$(g 'j.statutEnvoi' | grep -c 'Proposition envoyée')" "1"
  assert_eq "FIN.4 — la phrase « écrit cette ligne sans la lancer » est visible à la hauteur par défaut" "$(g 'j.phrase')" "visible"
  assert_eq "FIN.4 — la liste des modes est visible (le tiroir s'ajuste au bandeau)" "$(g 'j.modes')" "visible"
  assert_eq "FIN.4 — le bandeau n'est pas rogné : rien ne défile" "$(g 'j.bandeau.defile <= j.bandeau.client + 1')" "true"
  assert_eq "FIN.4 — le tiroir ne dépasse pas 60 % de la fenêtre (900 px)" "$(g 'j.tiroir <= 540')" "true"
  assert_eq "FIN.4 — après « Annuler », le statut du panneau revient à zéro" "$(g 'j.statutApresAnnuler')" ""
  assert_eq "FIN.4 (AUDC-M11) — témoin : tant que la proposition est là, la région live du cadre dit « Lancement proposé »" "$(g 'j.annonceAvant' | grep -c 'Lancement proposé')" "1"
  assert_eq "FIN.4 (AUDC-M11) — après « Annuler », la région live du cadre revient à zéro (plus d'annonce « Lancement proposé … Expire dans … »)" "$(g 'j.annonceApresAnnuler')" ""
  for L in 1280 1440 1024; do
    assert_eq "FIN.3 (AUDC-M10) — à $L px, le libellé « Terminer la session » tient dans l'en-tête du tiroir, à droite de son glyphe, sur la même ligne" "$(g "JSON.stringify(j.geo[$L])")" '{"dansBarre":true,"cote":true,"memeLigne":true}'
  done
  assert_eq "FIN.3/4 — aucune étape du scénario n'a échoué" "$(g 'JSON.stringify(j.erreurs)')" "{}"
  unsrv
  # fenêtre plus basse (1280 x 720 : tiroir de 259 px par défaut, avant la proposition) : la phrase reste visible, le tiroir ne dépasse pas 60 % de la fenêtre
  srv
  R="$(chrome_fin "$(printf '{"mode":"session","P":%s,"Q":%s,"amorce":"%s","pidShell":"%s","largeur":1280,"hauteur":720}' "$SRV_PORT" "$QP" "$AMORCE" "$RUN/shell.pid")")"
  echo "     [mesures 720] $(printf '%s' "$R" | node "$AUX/ev.mjs" 'JSON.stringify({tiroir:j.tiroir,cadre:j.cadre,bandeau:j.bandeau,phrase:j.phrase,modes:j.modes,erreurs:j.erreurs})')"
  assert_eq "FIN.4 (1280 x 720) — la phrase « écrit cette ligne sans la lancer » est visible à la hauteur par défaut" "$(g 'j.phrase')" "visible"
  assert_eq "FIN.4 (1280 x 720) — le tiroir ne dépasse pas 60 % de la fenêtre (432 px)" "$(g 'j.tiroir <= 432')" "true"
  unsrv
  # fenêtre très basse (1280 x 500) : le rehaussement garde le plafond de 60 % (300 px) et ne met jamais le tiroir en plein écran (PU-G-136)
  srv
  R="$(chrome_fin "$(printf '{"mode":"session","P":%s,"Q":%s,"amorce":"%s","pidShell":"%s","largeur":1280,"hauteur":500}' "$SRV_PORT" "$QP" "$AMORCE" "$RUN/shell.pid")")"
  echo "     [mesures 500] $(printf '%s' "$R" | node "$AUX/ev.mjs" 'JSON.stringify({tiroir:j.tiroir,plein:j.plein,erreurs:j.erreurs})')"
  assert_eq "FIN.5 (1280 x 500) — la proposition ouvre le tiroir (témoin : mesuré, ≥ 300 px) sans le mettre en plein écran, au plus 60 % de la fenêtre (300 px)" "$(g 'j.plein+" "+(j.tiroir>=300&&j.tiroir<=300)')" "false true"
  unsrv
else nonverif "FIN.3"; nonverif "FIN.4"; fi

echo
echo "Résultat : $PASS réussi(s), $FAIL échec(s), $NONVERIF non vérifié(s)"
[ "$FAIL" -eq 0 ]
