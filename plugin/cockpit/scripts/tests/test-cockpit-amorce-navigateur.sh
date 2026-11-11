#!/usr/bin/env bash
# test-cockpit-amorce-navigateur.sh — AUDC-B-03 bis (lot 0 bis de l'audit du cockpit) : la page de redirection du lanceur, ouverte comme fichier local,
# atteint le cockpit ; une page d'un autre site n'obtient ni page, ni fichier, ni effet d'état.
#   N1  CHEMIN RÉEL (Chrome headless) : le lanceur écrit sa page, le navigateur l'ouvre en file://, suit la redirection vers le cockpit ; en-têtes envoyés relevés
#       et assertés (cross-site, navigate, document) ; le document arrive (200), le cadre du terminal échange la clé, la clé est consommée, aucun échec annoncé
#   P1  requêtes inter-sites brutes (Sec-Fetch-* posés comme un navigateur) : la seule navigation admise est GET /project.html, premier niveau, avec le SECRET D'OUVERTURE
#       (?o=) du lanceur, tant que la clé d'amorçage est armée ; refus : sans secret, secret faux, déjà employé, expiré, à droits larges ou en lien ; clé absente, expirée,
#       à droits larges, en lien, vide, trop grosse, datée du futur, dossier ; autre destination, autre page, autre méthode ; témoins positifs : même origine, saisie à la main
#   M   mutants (un par prédicat) : exception retirée, élargie (destination, mode, page, méthode), secret non exigé ou réutilisable, chaque prédicat de la clé
#       (droits, taille, vide, futur, expiration, lien) ; le prédicat « dossier » est équivalent (la lecture d'un dossier échoue de toute façon) : cas seulement
# Avec --no-open, le lanceur arme la clé 60 s sans consommateur : les cas P1 rejouent cet état, sans navigateur.
# Chrome headless ; sans navigateur, N1 est SAUTÉE hors CI et ÉCHOUE en CI (jamais un vert à vide). Exit 0 si tout passe, 1 sinon.
set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; }
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"; MODULE="$(cd "$SCRIPTS/.." && pwd)"; LAUNCH="$SCRIPTS/vf-cockpit.mjs"
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi; done
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/run" "$WORK/fauxbin" "$WORK/bin"
cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0
court() { if [ "${#1}" -gt 300 ]; then printf '%s […] %s' "${1:0:140}" "${1: -140}"; else printf '%s' "$1"; fi; }
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$(court "$3")]"; echo "     obtenu:  [$(court "$2")]"; FAIL=$((FAIL+1)); fi; }
cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
# rq.mjs <port> <méthode> <chemin> [nom=valeur…] -> code HTTP ; les en-têtes Sec-Fetch-* sont posés tels qu'un navigateur les enverrait
cat > "$AUX/rq.mjs" <<'JS'
import http from 'node:http';
const [, , port, methode, chemin, ...ent] = process.argv; const h = { Host: `127.0.0.1:${port}` };
for (const e of ent) { const i = e.indexOf('='); h[e.slice(0, i)] = e.slice(i + 1); }
const r = http.request({ host: '127.0.0.1', port: Number(port), path: chemin, method: methode, headers: h, agent: false }, (res) => { res.resume(); res.on('end', () => console.log(res.statusCode)); });
r.on('error', () => console.log(0)); r.setTimeout(8000, () => r.destroy()); r.end();
JS
for o in open xdg-open; do printf '#!/bin/sh\necho "$@" >> "%s/run/ouvert.txt"\n' "$WORK" > "$WORK/fauxbin/$o"; chmod +x "$WORK/fauxbin/$o"; done
OUVERT="$WORK/run/ouvert.txt"
cat > "$WORK/bin/shell-test" <<SH
#!/bin/sh
/bin/sh -i
SH
chmod +x "$WORK/bin/shell-test"; export SHELL="$WORK/bin/shell-test"
NL=0; LRC=0; LOUT=""; NLAB=0
lance() { local l="$1"; shift; NL=$((NL+1)); LOUT="$WORK/lance-$NL.out"; (cd "$LAB" && PATH="$WORK/fauxbin:$PATH" node "$l" "$@" --lab "$LAB" --port "$(libre)" > "$LOUT" 2>&1); LRC=$?; }
mklab() {
  local L="$1" B="$1/.planning"; mkdir -p "$L/src" "$B/phases/01-socle"; printf 'export const u = 1;\n' > "$L/src/u.js"
  printf -- '## Phases\n\n- [x] **Phase 1: Socle** - premier jet\n\n### Phase 1: Socle\n**Goal**: Poser le socle\n' > "$B/ROADMAP.md"
  printf -- '---\nstatus: executing\ncurrent_phase: 1\nmilestone: v1.0 MVP\n---\n' > "$B/STATE.md"
  printf -- '---\nwave: 1\nfiles_modified: [src/u.js]\n---\n<objective>Poser le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
}
nouveau_lab() { NLAB=$((NLAB+1)); LAB="$WORK/lab$NLAB"; mklab "$LAB"; OUT="$LAB/.vibeflow/cockpit"; AM="$OUT/.cache/terminal-amorce"; SJ="$OUT/.cache/server.json"; rm -f "$OUVERT"; }
sj() { [ -f "$SJ" ] && node "$AUX/ev.mjs" "$1" < "$SJ" 2>/dev/null; true; }
rq() { node "$AUX/rq.mjs" "$PORT" "$@"; }
arret() { lance "${1:-$LAUNCH}" stop; }
# copie du module dont <fichier> est muté (sed…) ; code 1 si la copie n'a pas changé
mutant() { local d="$WORK/mut-$1" rel="$2"; shift 2; rm -rf "$d"; mkdir -p "$d"; cp -R "$MODULE/." "$d/"; MUT_L="$d/scripts/vf-cockpit.mjs"; local f="$d/$rel"
  cp "$f" "$f.orig"; sed -i.bak "$@" "$f"; local r=0; cmp -s "$f" "$f.orig" && r=1; rm -f "$f.orig" "$f.bak"; return $r; }

# ---- N1 : le chemin réel, dans un vrai navigateur ----
N1() { # N1 <lanceur> <étiquette> -> N1_RES (JSON), N1_AM (clé encore là ?), N1_LOUT
  local l="$1"; nouveau_lab; export VF_COCKPIT_OUVERTURE_MS=25000
  local PP; PP="$(libre)"
  node "$HERE_T/chrome-amorce-ouvrir.mjs" "$CHROME" "{\"ouvert\":\"$OUVERT\",\"P\":$PP,\"attenteMs\":90000}" > "$WORK/n1.json" 2> "$WORK/n1.err" &
  local WP=$!; PIDS+=($WP)
  NL=$((NL+1)); N1_LOUT="$WORK/lance-$NL.out"; (cd "$LAB" && PATH="$WORK/fauxbin:$PATH" node "$l" open --terminal --lab "$LAB" --port "$PP" > "$N1_LOUT" 2>&1); LRC=$?
  wait $WP 2>/dev/null; N1_RES="$(cat "$WORK/n1.json" 2>/dev/null)"; N1_AM="$([ -e "$AM" ] && echo la || echo consommee)"
  arret "$l"
}
echo "=== N1 — chemin réel : page du lanceur ouverte en file:// dans Chrome ==="
if [ -z "$CHROME" ]; then
  . "$(dirname "$0")/chrome-saut.sh"; vf_chrome_saut "  ⊘ N1 SAUTÉE : aucun navigateur — le chemin réel de l'ouverture n'est PAS vérifié, non compté comme réussi"
else
  N1 "$LAUNCH"
  echo "     mesure : $N1_RES · clé: $N1_AM"
  assert_eq "N1 — le navigateur envoie Sec-Fetch-Site/Mode/Dest = cross-site/navigate/document (ce que P1.1 rejoue)" "$(echo "$N1_RES" | node "$AUX/ev.mjs" 'j.sfs + "/" + j.sfm + "/" + j.sfd')" "cross-site/navigate/document"
  assert_eq "N1 — le document du cockpit répond 200 à la page de redirection du lanceur" "$(echo "$N1_RES" | node "$AUX/ev.mjs" 'j.statut')" "200"
  assert_eq "N1 — le cadre du terminal échange la clé (POST /amorce : 200)" "$(echo "$N1_RES" | node "$AUX/ev.mjs" 'j.amorce')" "200"
  assert_eq "N1 — la clé à usage unique est consommée" "$N1_AM" "consommee"
  assert_eq "N1 — le lanceur ne signale aucun échec d'ouverture du terminal" "$(grep -c "le terminal ne s'est pas ouvert" "$N1_LOUT")" "0"
fi

# ---- P1 : la propriété de sécurité — les requêtes inter-sites ----
XS="Sec-Fetch-Site=cross-site"; SEC="$(printf '%064d' 9)"
CLE() { echo "$OUT/.cache/terminal-amorce"; }; SECF() { echo "$OUT/.cache/terminal-ouvrir-secret"; }
ecrire() { rm -f "$1"; printf '%s' "$2" > "$1"; chmod 600 "$1"; }
arme() { ecrire "$(CLE)" "$(printf '%064d' 7)"; ecrire "$(SECF)" "$SEC"; } # l'état que le lanceur pose : clé et secret d'ouverture, frais, 0600
datee() { node -e "const t=(Date.now()+Number(process.argv[2])*1000)/1000; require('fs').utimesSync(process.argv[1], t, t)" "$1" "$2"; }
ECARTS=""; MODE_P="assert"
cas() { # cas <libellé « P1.n — … »> <attendu> <méthode> <chemin> [en-têtes…]
  local lib="$1" att="$2"; shift 2; local obt; obt="$(rq "$@")"
  if [ "$MODE_P" = assert ]; then assert_eq "$lib" "$obt" "$att"; elif [ "$obt" != "$att" ]; then ECARTS="$ECARTS [$lib : $obt au lieu de $att]"; fi
}
P1() { # P1 <lanceur> : cockpit avec terminal (--no-open : clé armée 60 s sans consommateur), toutes les requêtes
  local l="$1"; nouveau_lab; lance "$l" open --terminal --no-open; PORT="$(sj j.port)"
  [ -n "$PORT" ] || { ECARTS="$ECARTS [cockpit non démarré]"; [ "$MODE_P" = assert ] && assert_eq "P1 — le cockpit démarre" "rien" "port"; return; }
  local nav="$XS Sec-Fetch-Mode=navigate Sec-Fetch-Dest=document" P="/project.html?o=$SEC"
  arme; cas "P1.1 — clé armée et secret d'ouverture : navigation inter-sites de premier niveau vers /project.html : page servie" 200 GET "$P" $nav
  arme; cas "P1.2 — secret valide, autre page (/index.html) : refusée" 403 GET "/index.html?o=$SEC" $nav
  arme; cas "P1.3 — secret valide, / : refusée" 403 GET "/?o=$SEC" $nav
  arme; cas "P1.4 — secret valide, fichier (/graph.json) : refusé" 403 GET "/graph.json?o=$SEC" $nav
  arme; cas "P1.5 — secret valide, /project.html dans un cadre (Dest iframe) : refusée" 403 GET "$P" $XS Sec-Fetch-Mode=navigate Sec-Fetch-Dest=iframe
  arme; cas "P1.6 — secret valide, /project.html comme script : refusée" 403 GET "$P" $XS Sec-Fetch-Mode=no-cors Sec-Fetch-Dest=script
  arme; cas "P1.7 — secret valide, /project.html comme image : refusée" 403 GET "$P" $XS Sec-Fetch-Mode=no-cors Sec-Fetch-Dest=image
  arme; cas "P1.8 — secret valide, /project.html par fetch (Mode cors, Dest empty) : refusée" 403 GET "$P" $XS Sec-Fetch-Mode=cors Sec-Fetch-Dest=empty
  arme; cas "P1.9 — secret valide, Mode autre que navigate avec Dest document : refusée" 403 GET "$P" $XS Sec-Fetch-Mode=cors Sec-Fetch-Dest=document
  arme; cas "P1.10 — secret valide, POST inter-sites vers /project.html : refusé" 403 POST "$P" $nav
  arme; cas "P1.11 — secret valide, en-têtes Mode et Dest absents : refusée" 403 GET "$P" $XS
  arme; cas "P1.12 — clé armée SANS secret d'ouverture : navigation inter-sites refusée (aucune page, aucun effet)" 403 GET /project.html $nav
  arme; cas "P1.13 — clé armée, secret FAUX : refusée" 403 GET "/project.html?o=$(printf '%064d' 8)" $nav
  arme; cas "P1.14 — clé armée, secret vide (?o=) : refusée" 403 GET "/project.html?o=" $nav
  arme; cas "P1.15 — secret employé une fois (200) : la même navigation est refusée ensuite" 200 GET "$P" $nav
  cas "P1.16 — même requête, clé encore armée, secret brûlé : refusée" 403 GET "$P" $nav
  arme; datee "$(SECF)" -120; cas "P1.17 — secret expiré (plus de 60 s), clé fraîche : refusé" 403 GET "$P" $nav
  arme; chmod 644 "$(SECF)"; cas "P1.18 — fichier du secret lisible par les autres (0644) : refusé" 403 GET "$P" $nav
  arme; rm -f "$(SECF)"; printf '%s' "$SEC" > "$OUT/.cache/cible-secret"; chmod 600 "$OUT/.cache/cible-secret"; ln -s "$OUT/.cache/cible-secret" "$(SECF)"
  cas "P1.19 — fichier du secret en lien symbolique : refusé" 403 GET "$P" $nav; rm -f "$(SECF)" "$OUT/.cache/cible-secret"
  arme; rm -f "$(SECF)"; cas "P1.20 — secret absent du disque : refusée" 403 GET "$P" $nav
  arme; rm -f "$(CLE)"; cas "P1.21 — secret valide mais aucune clé armée : refusée" 403 GET "$P" $nav
  arme; datee "$(CLE)" -120; cas "P1.22 — clé armée depuis plus de 60 s (expirée) : refusée" 403 GET "$P" $nav
  arme; chmod 644 "$(CLE)"; cas "P1.23 — fichier de clé lisible par les autres (0644) : refusé" 403 GET "$P" $nav
  arme; rm -f "$(CLE)"; printf '%064d' 7 > "$OUT/.cache/cible-lien"; chmod 600 "$OUT/.cache/cible-lien"; ln -s "$OUT/.cache/cible-lien" "$(CLE)"
  cas "P1.24 — clé en lien symbolique : refusée" 403 GET "$P" $nav; rm -f "$(CLE)" "$OUT/.cache/cible-lien"
  arme; ecrire "$(CLE)" ""; cas "P1.25 — fichier de clé vide : refusé" 403 GET "$P" $nav
  arme; datee "$(CLE)" 600; cas "P1.26 — clé datée du futur : refusée" 403 GET "$P" $nav
  arme; ecrire "$(CLE)" "$(printf '%0200d' 7)"; cas "P1.27 — fichier de clé trop gros (200 octets) : refusé" 403 GET "$P" $nav
  arme; rm -f "$(CLE)"; mkdir "$(CLE)"; cas "P1.28 — clé qui est un dossier : refusée" 403 GET "$P" $nav; rmdir "$(CLE)"
  arme; ecrire "$(CLE)" "   "; cas "P1.29 — fichier de clé fait de blancs : refusé" 403 GET "$P" $nav
  rm -f "$(CLE)" "$(SECF)"
  cas "P1.30 — témoin : même origine vers /project.html, rien d'armé : servie" 200 GET /project.html Sec-Fetch-Site=same-origin Sec-Fetch-Mode=navigate Sec-Fetch-Dest=document
  cas "P1.31 — témoin : saisie de l'adresse à la main (Sec-Fetch-Site none), rien d'armé : servie" 200 GET /project.html Sec-Fetch-Site=none Sec-Fetch-Mode=navigate Sec-Fetch-Dest=document
  cas "P1.32 — témoin : requête sans en-tête Sec-Fetch (autre outil que le navigateur) : servie" 200 GET /project.html
  arret "$l"
}
echo "=== P1 — requêtes inter-sites : l'exception reste étroite ==="
P1 "$LAUNCH"

if [ -n "${VF_SANS_MUTANTS:-}" ]; then echo "  (mutants non joués : VF_SANS_MUTANTS)"; echo "PASS: $PASS  FAIL: $FAIL"; [ "$FAIL" -eq 0 ]; exit; fi # rejeu rapide contre une autre arborescence (témoin rouge avant)
# ---- M : mutants (la copie du module porte un fichier altéré ; le témoin DOIT rougir : correspondance exacte de l'identifiant) ----
MODE_P="mutant"
echo "=== M — mutants ==="
mut_p() { # mut_p <nom> <id du témoin> <fichier du module> <sed…>
  local nom="$1" cle="$2" rel="$3"; shift 3
  if mutant "$nom" "$rel" "$@"; then ECARTS=""; P1 "$MUT_L"; if [[ "$ECARTS" == *"[$cle — "* ]]; then assert_eq "M-$nom — le témoin $cle rougit" "rouge" "rouge"; else assert_eq "M-$nom — le témoin $cle rougit" "vert: $ECARTS" "rouge"; fi
  else assert_eq "M-$nom — le mutant change $rel" "inchangé" "changé"; fi
}
SV="skills/cockpit-moteur/assets/serve.mjs"; AM_M="scripts/vf-cockpit-terminal-amorce.mjs"
mut_p DEST "P1.5" "$SV" "s/ \&\& req.headers\['sec-fetch-dest'\] === 'document'//"
mut_p MODE "P1.9" "$SV" "s/ \&\& req.headers\['sec-fetch-mode'\] === 'navigate'//"
mut_p PAGE "P1.2" "$SV" "s/ \&\& url.pathname === '\/project.html' \&\& req.headers\['sec-fetch-mode'\]/ \&\& req.headers['sec-fetch-mode']/"
mut_p METHODE "P1.10" "$SV" "s/ouvertureLanceur = (req, url) => req.method === 'GET' \&\& /ouvertureLanceur = (req, url) => /"
mut_p SECRET-NON-EXIGE "P1.12" "scripts/vf-cockpit-terminal.mjs" -e "s/import { ouvertureValide }/import { ouvertureValide, amorceArmee }/" -e "s/ouvertureValide(path.join(here, '.cache'), secret)/amorceArmee(path.join(here, '.cache', 'terminal-amorce'))/"
mut_p SECRET-REUTILISABLE "P1.16" "$AM_M" "s/  try { fs.unlinkSync(f); } catch { return false; }//"
mut_p SECRET-SANS-CLE "P1.21" "$AM_M" "s/  if (!amorceArmee(path.join(dossier, FICHIER_AMORCE), { maintenant })) return false;//"
mut_p DROITS "P1.23" "$AM_M" "s/ (st.mode \& 0o077) !== 0 ||//"
mut_p LIEN "P1.24" "$AM_M" "s/c.O_RDONLY | c.O_NOFOLLOW |/c.O_RDONLY |/"
mut_p FENETRE "P1.22" "$AM_M" "s/age <= DUREE_AMORCE_MS/age <= 9e15/"
mut_p FUTUR "P1.26" "$AM_M" "s/age >= -1000 \&\& //"
mut_p TROP-GROS "P1.27" "$AM_M" "s/ || st.size > MAX_AMORCE//"
mut_p VIDE "P1.25" "$AM_M" -e "s/ || st.size === 0//" -e "s/return contenu === '' ? null : contenu;/return contenu;/"
if mutant RETIRE "$SV" "s/ \&\& !ouvertureLanceur(req, url)//"; then
  ECARTS=""; P1 "$MUT_L"; if [[ "$ECARTS" == *"[P1.1 — "* ]]; then assert_eq "M-RETIRE — exception retirée : P1.1 rougit" "rouge" "rouge"; else assert_eq "M-RETIRE — exception retirée : P1.1 rougit" "vert: $ECARTS" "rouge"; fi
  if [ -n "$CHROME" ]; then N1 "$MUT_L"; assert_eq "M-RETIRE — exception retirée : N1 rougit (403 dans le navigateur, clé non consommée)" "$(echo "$N1_RES" | node "$AUX/ev.mjs" 'j.statut') $N1_AM" "403 la"; fi
else assert_eq "M-RETIRE — le mutant change serve.mjs" "inchangé" "changé"; fi

echo ""; echo "=== Bilan ==="
echo "PASS: $PASS  FAIL: $FAIL"; [ "$FAIL" -eq 0 ]
