#!/usr/bin/env bash
# test-cockpit-fr-donnees.sh — AUDC-H4 (lot 0 de l'audit du cockpit) : la traduction du chrome ne réécrit pas les données du lab.
#   D1 les titres de cartes d'un lab portant tokens.ts, open.mjs, health.mjs restent ceux que le moteur écrit : Tokens, Open, Health (avant : « Jetons », « Ouvrir », « Santé »)
#   D2 une description de carte qui est une phrase du dictionnaire (« Health ») reste telle quelle
#   D4 le panneau de détail d'une carte garde son titre (« Tokens ») et sa description (« Health ») ; D5 une ligne de liste, un résultat de recherche, l'infobulle et le fil d'Ariane gardent le nom (et la description) de la donnée
#   D6 le texte de repli du panneau d'un lien (sans description) reste traduit ; les noms de cartes d'un panneau « réponse » ne le sont pas
#   D3 témoins : le chrome reste traduit (bouton « Santé », « Pas encore de description » d'une carte sans description)
# Chrome headless ; sans navigateur la suite est SAUTÉE hors CI, et ÉCHOUE en CI (jamais un vert à vide).
set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; }
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"; ENG="$SCRIPTS/../skills/cockpit-moteur"
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi; done
if [ -z "$CHROME" ]; then
  . "$(dirname "$0")/chrome-saut.sh"; vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur — la traduction des données n'est PAS vérifiée, non compté comme réussi"; exit 0
fi
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [${2:0:400}]"; FAIL=$((FAIL+1)); fi; }
cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
mklab() {
  local L="$1" B="$1/.planning"; mkdir -p "$L/src" "$B/phases/01-socle"
  printf 'export const u = () => 1;\n' > "$L/src/util.js"; printf 'export const jeton = 1;\n' > "$L/src/tokens.ts"; printf "import { u } from './util.js';\nexport const ouvrir = u() + 2;\n" > "$L/src/open.mjs"; printf 'export const sante = 3;\n' > "$L/src/health.mjs"; printf '# Roadmap\n\n## Jalon démo\n\n- [x] **Phase 1: Socle** - premier jet\n' > "$B/ROADMAP.md"
  printf '<objective>Faire le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"; echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  node "$SCRIPTS/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
}
srv() { # srv <sortie> -> SRV_PORT
  local o="$1" lab; lab="$(cd "$1/../.." && pwd)"; rm -f "$o/.cache/server.json"
  ( cd "$lab" && VF_COCKPIT_ENGINE_DIR="$ENG" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS" exec node "$o/serve.mjs" --no-open --port $(libre) > "$o/../serve.out" 2>&1 ) </dev/null >/dev/null 2>&1 &
  PIDS+=($!)
  for _ in $(seq 1 100); do grep -q '"port"' "$o/.cache/server.json" 2>/dev/null && break; sleep 0.1; done
  SRV_PORT="$(node -e "console.log(JSON.parse(require('fs').readFileSync('$o/.cache/server.json','utf8')).port)" 2>/dev/null || echo 0)"
  SRV_REAL="$(node -e "console.log(JSON.parse(require('fs').readFileSync('$o/.cache/server.json','utf8')).pid)" 2>/dev/null || echo 0)"
}
mesure() { # mesure <lab> -> JSON sur la sortie ; arrête le serveur ensuite
  local o="$1/.vibeflow/cockpit"; srv "$o"
  local r; r="$(REAL_HOME="$REAL_HOME" node "$HERE_T/chrome-fr-donnees.mjs" "$CHROME" "http://127.0.0.1:$SRV_PORT/" "n:d-src")"
  vf_hyg_kill TERM "$SRV_REAL"
  printf '%s\n' "$r"
}
LAB="$WORK/lab"; mklab "$LAB"
echo "=== données du lab dans l'onglet Code (conteneur n:d-src) ==="
R="$(mesure "$LAB")"; [ -n "${DBG:-}" ] && echo "RAW: $R"
assert_eq "D0 — la mesure a eu lieu" "$(printf '%s' "$R" | node "$AUX/ev.mjs" '!!j.erreur')" "false"
assert_eq "D1 — les titres de cartes sont ceux des fichiers" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.cartes.map((c) => c.titre).sort().join(",")')" "Health,Open,Tokens,Util"
assert_eq "D2 — une description « Health » n'est pas traduite" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.descPosee')" "Health"
assert_eq "D3.1 — témoin : le bouton de santé reste en français" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.temoin')" "Santé"
assert_eq "D3.2 — témoin : une carte sans description dit « Pas encore de description »" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.cartes.filter((c) => c.vide).every((c) => c.desc === "Pas encore de description") && j.cartes.some((c) => c.vide)')" "true"
assert_eq "D4.1 — panneau : le titre de la carte est le nom du fichier" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.panneau.titre')" "Tokens"
assert_eq "D4.2 — panneau : la description « Health » n'est pas traduite" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.panneau.desc')" "Health"
assert_eq "D4.3 — témoin : le panneau d'une carte sans description dit « Pas encore de description. »" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.panneauVide.vide && j.panneauVide.desc')" "Pas encore de description."
assert_eq "D4.4 — le titre du panneau d'une autre carte (Open) reste le nom du fichier" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.panneauVide.titre')" "Open"
assert_eq "D5.1 — ligne de liste : nom et description gardés" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.ligne.nom + "|" + j.ligne.desc')" "Tokens|Health"
assert_eq "D5.2 — résultat de recherche : nom et description gardés" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.recherche.nom + "|" + j.recherche.desc')" "Tokens|Health"
assert_eq "D5.3 — infobulle d'une carte : le nom est gardé" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.infobulle')" "Tokens"
assert_eq "D5.4 — fil d'Ariane : le nom est gardé" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.miette')" "Tokens"
assert_eq "D6.0 — témoin : le conteneur porte au moins un lien (hors « contient »), le panneau du lien a été ouvert par un vrai clic" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.nAretes > 0 && !!j.lien')" "true"
assert_eq "D6.1 — panneau d'un lien sans description : le texte de repli du viewer reste traduit (aucun « connection » anglais)" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.lien ? (/connection|endpoint/.test(j.lien.desc) ? "anglais:" + j.lien.desc : "traduit") : "absent"')" "traduit"
assert_eq "D6.2 — panneau « réponse » réel : les noms de cartes listées (rangées de la réponse et du parcours) sont ceux des fichiers" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.reponse.join(",")')" "Tokens,Open,1. Health,2. Open"
assert_eq "D6.3 — panneau « réponse » : le title des rangées (nom de la carte, suivi de la note) n'est pas traduit" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.reponseTitres.join("|")')" "Tokens|Open — Health|Health|Open"
assert_eq "D6.4 — panneau « réponse » : la NOTE d'une rangée reste traduite (« Health » → « Santé »)" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.reponseNote')" "Santé"
assert_eq "D6.5 — repli d'un lien, formes plurielles et « across m endpoints » (balisage du viewer posé dans le panneau) : toutes traduites" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.replis.filter((t) => /connection|endpoint|across/.test(t)).length + "/" + j.replis.length')" "0/3"
assert_eq "D5.5 — gabarits à noms : « Tokens contient Open » (chrome traduit, noms gardés)" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.gabarits.lien')" "Tokens contient Open"
assert_eq "D5.6 — « Inside Tokens » → « Dans Tokens », « Everything behind Health » garde « Health »" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.gabarits.dans + "|" + j.gabarits.derriere')" "Dans Tokens|Tout ce qu'il y a derrière Health"
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ "$FAIL" -eq 0 ]
