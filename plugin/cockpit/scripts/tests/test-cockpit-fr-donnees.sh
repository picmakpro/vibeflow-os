#!/usr/bin/env bash
# test-cockpit-fr-donnees.sh — AUDC-H4 (lot 0 de l'audit du cockpit) : la traduction du chrome ne réécrit pas les données du lab.
#   D1 les titres de cartes d'un lab portant tokens.ts, open.mjs, health.mjs restent ceux que le moteur écrit : Tokens, Open, Health (avant : « Jetons », « Ouvrir », « Santé »)
#   D2 une description de carte qui est une phrase du dictionnaire (« Health ») reste telle quelle
#   D4 le panneau de détail d'une carte garde son titre (« Tokens ») et sa description (« Health ») ; D5 une ligne de liste, un résultat de recherche, l'infobulle et le fil d'Ariane gardent le nom (et la description) de la donnée
#   D6 le texte de repli du panneau d'un lien (sans description) reste traduit ; les noms de cartes d'un panneau « réponse » ne le sont pas
#   D3 témoins : le chrome reste traduit (bouton « Santé », « Pas encore de description » d'une carte sans description)
# Chrome headless ; sans navigateur la suite est SAUTÉE hors CI, et ÉCHOUE en CI (jamais un vert à vide).
set -uo pipefail
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
. "$(dirname "$0")/socle-serveur.sh"
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [${2:0:400}]"; FAIL=$((FAIL+1)); fi; }
cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
mklab() {
  local L="$1" B="$1/.planning"; mkdir -p "$L/src" "$B/phases/01-socle"
  printf 'export const u = () => 1;\n' > "$L/src/util.js"; printf 'export const jeton = 1;\n' > "$L/src/tokens.ts"; printf "import { u } from './util.js';\nexport const ouvrir = u() + 2;\n" > "$L/src/open.mjs"; printf 'export const sante = 3;\n' > "$L/src/health.mjs"; printf '# Roadmap\n\n## Jalon démo\n\n- [x] **Phase 1: Socle** - premier jet\n' > "$B/ROADMAP.md"
  printf '<objective>Faire le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"; echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
  # un dossier de plus de 24 fichiers : le viewer le découpe en cartes « dossier » (D7), sans toucher au conteneur de src/ mesuré par D1..D6
  mkdir -p "$L/big/a" "$L/big/b"; for i in $(seq 1 13); do printf 'export const v%s = 1;\n' "$i" > "$L/big/a/f$i.js"; printf 'export const w%s = 1;\n' "$i" > "$L/big/b/g$i.js"; done
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  node "$SCRIPTS/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
}
srv() { # srv <sortie> -> SRV_PORT
  local o="$1" lab; lab="$(cd "$1/../.." && pwd)"
  COCKPIT_SORTIE="$o" cockpit_lancer "$lab" VF_COCKPIT_ENGINE_DIR="$ENG" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS"
  SRV_PORT="${VF_PORT:-0}"; SRV_REAL="${VF_PID:-0}"
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
assert_eq "D6.4 — panneau « réponse » : la note d'une rangée n'est jamais réécrite après coup (« Health » reste « Health » ; les notes d'assemblage de Santé sont traduites à l'émission par t.constat)" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.reponseNote')" "Health"
assert_eq "D5.5 — gabarits à noms, par le traducteur : « Tokens contient Open » (chrome traduit, noms gardés)" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.gabarits.lien')" "Tokens contient Open"
assert_eq "D5.6 — « Inside Tokens » → « Dans Tokens », « Everything behind Health » garde « Health »" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.gabarits.dans + "|" + j.gabarits.derriere')" "Dans Tokens|Tout ce qu'il y a derrière Health"
assert_eq "D7.1 — carte atteinte au clavier : le nom accessible (aria-label) est le nom de la donnée" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.ariaCarte')" "Tokens"
assert_eq "D7.2 — description d'un panneau contenant un mot du glossaire (« endpoints ») : gardée mot pour mot" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.descGlossaire')" "Lists the endpoints anyone can use"
assert_eq "D7.3 — témoin : un dossier a été trouvé à la racine" "$(printf '%s' "$R" | node "$AUX/ev.mjs" '!!j.dossierId')" "true"
assert_eq "D7.4 — panneau d'un dossier : « N files in chemin/ » dit « N fichiers dans chemin/ » (ici big/a/), chemin intact" "$(printf '%s' "$R" | node "$AUX/ev.mjs" '/^\d+ fichiers? dans \S+\/$/.test(j.dossier || "") ? "fr:" + j.dossier.replace(/^\d+ /, "N ") : "autre:" + j.dossier')" "fr:N fichiers dans big/a/"
assert_eq "D7.8 — dossier OUVERT (go, sans sélection) : le panneau décrit le conteneur, le gabarit est traduit" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.dossierOuvert')" "13 fichiers dans big/a/"
assert_eq "D7.9 — entité de connecteur (x:in:<dossier>) : jugée sur l'item décrit, gabarit traduit" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.dossierConnecteur')" "13 fichiers dans big/a/"
assert_eq "D7.5 — lignes de liste RÉELLES du nœud qui porte les dossiers du moteur (émises par le viewer) : « 13 fichiers dans big/a/ » et « 13 fichiers dans big/b/ », chemins intacts" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.lignesReelles && j.lignesReelles.join("|")')" "13 fichiers dans big/a/|13 fichiers dans big/b/"
assert_eq "D7.5b — plus de réécriture après coup : des lignes de liste POSÉES dans le DOM (gabarit anglais, dossier ou fichier) restent telles quelles" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.dossiersPoses.join("|")')" "1 file in src/lib/|12 files in src/mes files in/|3 files in src/ were changed|3 files in src|3 files in x/|See 3 files in src/ and more"
assert_eq "D7.6 — plus de réécriture après coup : des résultats de recherche POSÉS dans le DOM (type dir, type file) restent tels quels" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.resultatsPoses.join("|")')" "5 files in src/|3 files in x/"
assert_eq "D7.7 — panneau d'une carte FICHIER du lab dont la description est le gabarit : intacte (donnée, jugée par l'identité de l'item, pas par la forme du texte)" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.panneauGabarit')" "3 files in x/"
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ "$FAIL" -eq 0 ]
