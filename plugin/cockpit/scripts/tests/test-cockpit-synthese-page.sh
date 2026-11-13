#!/usr/bin/env bash
# test-cockpit-synthese-page.sh — la coquille de la Synthèse sur l'onglet Projet (77-05, SYNT-01 ; P77-D-01, P77-D-17, P77-D-19, P77-D-30, P77-D-34).
#   B  sondes positives du banc (chrome-synthese.mjs) : le lab fixture, le lancement par copie de module, la copie mutée, les écouteurs, le style, le stockage, le journal réseau
#   W1 trois onglets · W2 bouton · W3 largeur · W10 chemins · W11a réseau et stockage · W13a focus et Échap · W14 mouvement · W16 cibles · W18 ligne-résumé · W19 en-tête · W20 tiroirs
#   RB1 registre des blocs · O1 aller-retour d'onglet · R1 titre · CS1 CSP, fichier servi, plafonds
# Deux serveurs lancés par cockpit_lancer sur une COPIE du module (charge prouvée) : « nue » (coquille seule) et « témoin » (coquille + bloc témoin posé dans la copie).
# Chrome headless ; sans navigateur la partie navigateur est SAUTÉE hors CI, et ÉCHOUE en CI (jamais un vert à vide). Mutants levés (régime allégé, 2026-11-13).
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE GIT_CEILING_DIRECTORIES
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; TESTS="$SCRIPTS/tests"; MOD="$(cd "$SCRIPTS/.." && pwd -P)"; ENG="$MOD/skills/cockpit-moteur"; UI="$ENG/assets/ui"
BANC="$TESTS/chrome-synthese.mjs"
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi; done
WORK="$(mktemp -d "${TMPDIR:-/tmp}/tmp.XXXXXXXXXX")"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"
REAL_HOME="$(node -e 'console.log(require("os").userInfo().homedir)')"; export HOME="$WORK/home"
trap 'vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"' EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
. "$(dirname "$0")/socle-serveur.sh"
PASS=0; FAIL=0
assert_eq() { if [ "$#" -ne 3 ]; then echo "  ❌ FAIL — $1 (assert_eq a reçu $# arguments au lieu de 3)"; FAIL=$((FAIL+1)); elif [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [${3:0:300}]"; echo "     obtenu:  [${2:0:300}]"; FAIL=$((FAIL+1)); fi; }
cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; let j; try { j = JSON.parse(fs.readFileSync(0, 'utf8')); } catch { console.log('illisible'); process.exit(0); }
let v; try { v = new Function('j', 'return (' + process.argv[2] + ')')(j); } catch (e) { v = 'erreur:' + e.message; } console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/largeur.mjs" <<'JS'
// largeur.mjs <fichier…> : une ligne « fichier lignes colonnes_max » par fichier (colonnes en points de code, jamais en octets)
import fs from 'node:fs'; for (const f of process.argv.slice(2)) { const l = fs.readFileSync(f, 'utf8').split('\n'); if (l.at(-1) === '') l.pop(); console.log(f, l.length, Math.max(0, ...l.map((x) => [...x.replace(/\r$/, '')].length))); }
JS
JN() { printf '%s' "$RN" | node "$AUX/ev.mjs" "$1"; }; JT() { printf '%s' "$RT" | node "$AUX/ev.mjs" "$1"; }

echo "=== CS1 (statique) — les fichiers ui/74-vf-synthese*.js : CSP, jeton, plafonds ==="
FICH=("$UI"/74-vf-synthese*.js); NF="${#FICH[@]}"
[ -e "${FICH[0]}" ] || NF=0
assert_eq "CS1.0 — témoin : le glob ouvre au moins un fichier (jamais un vert à vide)" "$([ "$NF" -ge 1 ] && echo oui || echo non)" "oui"
SCAN="$(/usr/bin/grep -lE 'x-floorplan-token|x-vf-cockpit-token|eval\(|new Function|blob:| on[a-z]+=|/api/vf/(doing|transcript)' "${FICH[@]}" 2>/dev/null | tr '\n' ' ')"
assert_eq "CS1.1 — aucun attribut on*, eval, new Function, blob:, en-tête de jeton ni route de dernière commande ou de transcript" "$SCAN" ""
assert_eq "CS1.2 — chaque fichier : au plus 299 lignes et 160 points de code par ligne (mesure en points de code)" "$(node "$AUX/largeur.mjs" "${FICH[@]}" 2>/dev/null | awk '$2 > 299 || $3 > 160 { print $1 }' | tr '\n' ' ')" ""

echo "=== B — sondes positives du banc ==="
mklab() { local L; L="$(node "$BANC" lab "$WORK")" || return 1; node "$SCRIPTS/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"; printf '%s\n' "$L"; }
LAB="$(mklab)"
assert_eq "B1 — labFixture : le lab porte le dossier marqueur, la prose marqueur du STATE et la puce piégée" "$(basename "$LAB")|$(/usr/bin/grep -c 'MARQUEUR-PROSE-77' "$LAB/.planning/STATE.md")|$(/usr/bin/grep -c 'window.__xss' "$LAB/.planning/STATE.md")|$(git -C "$LAB" rev-list --count HEAD)" "RACINE-MARQUEUR-77|1|1|1"
copie_sans_freres() { local d; d="$(cockpit_module_copie "$WORK/mod-$1")" || return 1; rm -f "$d"/skills/cockpit-moteur/assets/ui/74-vf-synthese-*.js; printf '%s\n' "$d"; }
COP_NUE="$(copie_sans_freres nue)"; COP_TEM="$(copie_sans_freres temoin)"; node "$BANC" temoin "$COP_TEM"
assert_eq "B2 — copies de module : aucun frère 74-vf-synthese-* dans la « nue », le seul bloc témoin dans l'autre ; le témoin n'est jamais dans le module livré" "$(ls "$COP_NUE"/skills/cockpit-moteur/assets/ui/ | /usr/bin/grep -c '74-vf-synthese-')|$(ls "$COP_TEM"/skills/cockpit-moteur/assets/ui/ | /usr/bin/grep -c '74-vf-synthese-')|$(ls "$UI" | /usr/bin/grep -c 'temoin')" "0|1|0"
( cockpit_module_muter_page neutre 's|ANCRE-QUI-N-EXISTE-PAS-77-05|x|' 2>/dev/null ); assert_eq "B3 — copieMutee : un mutant sans effet est refusé (code 1)" "$?" "1"
export COCKPIT_MODULE="$COP_NUE"; cockpit_lancer "$LAB"; RL=$?; PORT="${VF_PORT:-0}"
assert_eq "B4 — lancer : le serveur de la copie « nue » est prêt, charge la copie visée et refuse l'empreinte d'une autre copie" "$RL|$([ "$PORT" -gt 0 ] && echo prêt)|$(cockpit_module_charge "$COP_NUE" && echo charge)|$(cockpit_module_charge "$COP_TEM" && echo charge-aussi || echo autre-refusee)" "0|prêt|charge|autre-refusee"
cat > "$AUX/sonde.css" <<'CSS'
.x { padding: 10px; color: #123456; }
CSS
node "$TESTS/css-jetons.mjs" "$AUX/sonde.css" > /dev/null 2>&1; CJ_ROUGE=$?; [ ! -e "${FICH[0]}" ] || { node "$TESTS/css-jetons.mjs" "${FICH[@]}" > /dev/null 2>&1; CJ_VERT=$?; }
assert_eq "B5 — css-jetons : rouge sur un espacement de 10 px et une couleur injectés, vert sur les fichiers de la Synthèse" "$CJ_ROUGE|${CJ_VERT:-0}" "1|0"

if [ -z "$CHROME" ]; then
  . "$(dirname "$0")/chrome-saut.sh"; vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur — la coquille de la Synthèse dans Chrome (W1 à W20, RB1, O1, R1, CS1 navigateur) n'est PAS vérifiée, non comptée comme réussie"
  vf_hyg_assert; echo ""; echo "  Résultats : $PASS PASS / $FAIL FAIL"; [ "$FAIL" -eq 0 ]; exit $?
fi
mesurer() { REAL_HOME="$REAL_HOME" SYNTH_INTERDITS="RACINE-MARQUEUR-77|$REAL_HOME|$WORK" node "$BANC" scenario "$CHROME" "$PORT" "$@"; }
cockpit_exporter "$LAB" "$WORK/export.html" > /dev/null 2>&1
RN="$(mesurer nue "$WORK/export.html")"; [ -n "${DBG:-}" ] && echo "RAW nue: $RN"
cockpit_arreter; export COCKPIT_MODULE="$COP_TEM"; cockpit_lancer "$LAB"; RL=$?; PORT="${VF_PORT:-0}"
RT="$(mesurer temoin)"; [ -n "${DBG:-}" ] && echo "RAW témoin: $RT"
cockpit_arreter

echo "=== B (navigateur) — outils du banc, chacun vu positif ==="
assert_eq "B6 — mesures obtenues sans erreur nommée (nue et témoin), serveur témoin prêt" "$RL|$(JN "j.erreur||''")|$(JT "j.erreur||''")" "0||"
assert_eq "B7 — écouteurs instrumentés (un écouteur posé est compté), style calculé (teinte injectée vue), mesure obtenue, stockage écrit avant chargement lu par la page" "$(JT 'j.sondes.ecouteur + "|" + j.sondes.style + "|" + j.sondes.pose.obtenue + "|" + j.sondes.stockage')" "1|rgb(12, 34, 56)|true|1"
assert_eq "B8 — journal réseau : il voit des GET /api/vf/ avec leur en-tête de jeton ; la recherche voit le marqueur dans meta.root ; #btn-health est trouvé sur Code par la même requête que W2" "$(JT '(j.reseau.getsAvecJeton >= 1) + "|" + j.racine + "|" + (j.pages[0].sante >= 1)')" "true|true|true"
assert_eq "B9 — préconditions de la 79 par exécution : surOnglet, VF_ETAT.lireJson et jeton sont des fonctions sur la page servie ; la page exportée n'a pas de coquille" "$(JN 'j.pre.surOnglet + "," + j.pre.lireJson + "," + j.pre.jeton')|$(JN 'j.exportee.coquille')" "function,function,function|false"

echo "=== W — la coquille dans Chrome ==="
assert_eq "W1 — nav.vf-tabs compte 3 liens sur Code, Projet et Équipe ; aucun role=\"tab\" neuf" "$(JN 'j.pages.map((p) => p.tabs + "/" + p.roleTab).join()')" "3/0,3/0,3/0"
assert_eq "W2.1 — #btn-synthese : absent sur Code et sur Équipe, une fois sur Projet ; absent de la page exportée (sans serveur), qui est bien chargée sans coquille" "$(JN 'j.pages.map((p) => p.btn).join() + "|" + j.exportee.btn + "|" + j.exportee.exportee')" "0,1,0|0|true"
assert_eq "W2.2 — juste après #btn-health, aria-controls=panel, aria-expanded faux puis vrai puis faux, nom accessible commençant par « Synthèse »" "$(JN '[j.bouton.apresSante, j.bouton.controls, j.bouton.expanded, j.ouvert.expanded, j.basculeFerme.expanded, j.bouton.nom.startsWith("Synthèse")].join()')" "true,panel,false,true,false,true"
assert_eq "W2.3 — aucun badge, aucun chiffre, libellé « Synthèse »" "$(JN '[j.bouton.badge, j.bouton.chiffre, j.bouton.bl].join()')" "false,false,Synthèse"
assert_eq "W3.1 — le rectangle et la transformation de #viewport sont identiques avant et après l'ouverture ; la feuille de la coquille est unique et ne porte aucune règle sur #panel" "$(JN '(JSON.stringify(j.vp0) === JSON.stringify(j.vp1)) + "|" + j.regleFeuille.n + "|" + j.regleFeuille.surPanneau')|$(JT 'JSON.stringify(j.vp0) === JSON.stringify(j.vp1)')" "true|1|false|true"
assert_eq "W3.2 — la largeur du panneau est la même Synthèse ouverte et détail d'une carte ouvert" "$(JT 'j.largeurSynth > 0 && j.largeurSynth === j.selection.largeurDetail')" "true"
assert_eq "W10 — le texte du panneau ne contient ni le dossier marqueur, ni le dossier personnel, ni le dossier temporaire du poste" "$(JT 'j.interditsVus.length + "|" + j.interditsGeneriques')" "0|false"
assert_eq "W11a.1 — aucun POST, aucune requête vers les routes de dernière commande ou de transcript, chaque lecture de l'API porte le jeton" "$(JT 'j.reseau.posts + "," + j.reseau.interdites + "," + j.reseau.lecturesSansJeton')" "0,0,0"
assert_eq "W11a.2 — sessionStorage et clés du stockage inchangés par l'ouverture ; la clé de la visite guidée n'est pas écrite" "$(JN 'j.stockApres')|$(JT 'j.stockApres + "|" + j.cleVisite.length')" "true|true|0"
assert_eq "W13a.1 — à l'ouverture le focus est sur le h2 (tabindex -1) de la Synthèse ; la zone vive est un status poli atomique" "$(JN '[j.ouvert.h2, j.ouvert.tab, j.ouvert.focus, j.ouvert.sr].join("|")')" "Synthèse|-1|H2:true|status,polite,true"
assert_eq "W13a.2 — Échap (focus dans la Synthèse, puis sur le bouton) la ferme et rend le focus à #btn-synthese" "$(JN '[j.echap.ouverte, j.echap.focus, j.echap.expanded, j.echapBouton.ouverte, j.echapBouton.focus].join()')" "false,btn-synthese,false,false,btn-synthese"
assert_eq "W13a.3 — l'arrivée de données (le témoin rafraîchit son texte et son résumé) ne change ni le focus, ni le défilement, ne rappelle pas la Synthèse et n'annonce rien" "$(JT '[JSON.stringify(j.avantRefresh.focus) === JSON.stringify(j.apresRefresh.focus), j.avantRefresh.focus.temoin, j.avantRefresh.scroll > 0 && j.avantRefresh.scroll === j.apresRefresh.scroll, j.apresRefresh.texte, j.apresRefresh.titre.includes("-bis"), j.apresRefresh.sr === "", j.apresRefresh.ouverte].join()')" "true,1,true,T-visite-bis,true,true,true"
assert_eq "W14 — sous prefers-reduced-motion : aucune animation, aucune transition sur le bouton ni sous .vf-sy (témoin : au moins dix éléments mesurés)" "$(JT '(j.mouvement.n >= 10) + "," + j.mouvement.animations + "," + j.mouvement.transitions')" "true,0,0"
assert_eq "W16 — à 800 px : le bouton, la ligne-résumé et « Fermer la synthèse » font au moins 44 px ; aucun débordement horizontal du panneau" "$(JT '[j.cibles.bouton >= 44, j.cibles.ligne >= 44, j.cibles.fermer >= 44, j.debordPanneau.every(Boolean)].join()')" "true,true,true,true"
assert_eq "W18.1 — la ligne-résumé (fournie par le bloc témoin) est un button.row.vf-rep focusable placé avant « Prochaines phases », sans jauge ni badge, au texte du témoin" "$(JT '[j.ligne.n, j.ligne.tag, j.ligne.classes.includes("vf-rep"), j.ligne.avantProchaines, j.ligne.extras, j.ligne.texte, j.ligneFocus].join()')" "1,BUTTON,true,true,0,TEMOIN-RESUME-77,true"
assert_eq "W18.2 — sans bloc témoin, la ligne-résumé ne rend aucun nœud" "$(JN 'j.ligneAvant')" "0"
assert_eq "W19.1 — l'en-tête ne déborde pas à 1 280, 1 440, 1 600, 1 639 et 1 920 px et ne gagne aucune ligne" "$(JT 'j.entete.map((e) => e.w + ":" + e.debord + ":" + e.memeHauteur).join()')" "1280:false:true,1440:false:true,1600:false:true,1639:false:true,1920:false:true"
assert_eq "W19.2 — à 600 px le menu « Plus d'actions » liste « Synthèse » une fois" "$(JT 'j.menu')" "1"
assert_eq "W20 — la Synthèse ne touche pas au tiroir Git ; un autre contenu de panneau la remplace ; sélectionner une carte la ferme" "$(JT '[j.tiroirAvant === j.selection.tiroirApres, j.remplace.synth, j.remplace.whop, j.remplace.expanded, j.selection.synth, j.selection.expanded].join()')" "true,false,true,false,false,false"
assert_eq "RB1.1 — blocs inscrits AVANT la coquille (ordre brouillé, un id inconnu) : rendus dans l'ordre fixe visite, burnup, methode ; l'inconnu est ignoré ; le tableau n'est jamais réaffecté ; chaque section se nomme par son h3" "$(JT '[j.blocs.join("-"), j.refIdentique, j.labelled, j.blocsTexte].join("|")')" "visite-burnup-methode|true|true|visite=T-visite,burnup=T-burnup,methode=T-methode"
assert_eq "RB1.2 — un bloc inscrit APRÈS la coquille est rendu, en dernier, au prochain affichage" "$(JT 'j.blocsApres.join("-") + "|" + j.apresTexte.includes("T-apres")')" "visite-burnup-methode-cout|true"
assert_eq "O1 — aller-retour d'onglet (code, projet, puis deux cycles) sans recharger la page : un bouton, une ligne-résumé, chaque bloc rendu une fois, écouteurs de document et de window égaux aux deux relevés" "$(JT '[j.surCode, j.ligneRetour.n, j.ligneCycles.n, JSON.stringify(j.ecout1) === JSON.stringify(j.ecout2), j.apresCycles.boutons, j.apresCycles.blocs.join("-"), j.apresCycles.compte.nbInstall, j.apresCycles.compte.nbRendu, j.apresCycles.memeDocument].join()')" "0,1,1,true,1,visite-burnup-methode,1,1,true"
assert_eq "R1 — title et aria-label : « Synthèse du projet » sans fournisseur, « Synthèse : … depuis votre dernière visite » avec le texte du témoin, aussi après un aller-retour d'onglet" "$(JN 'j.bouton.title + "|" + j.bouton.nom')|$(JT 'j.titre')|$(JT 'j.apresCycles.titre')" "Synthèse du projet|Synthèse du projet|Synthèse : TEMOIN-TITRE-77 depuis votre dernière visite|Synthèse : TEMOIN-TITRE-77 depuis votre dernière visite|Synthèse : TEMOIN-TITRE-77-bis depuis votre dernière visite"
assert_eq "CS1.3 — aucun securitypolicyviolation à l'ouverture (nue et témoin) ; 74-vf-synthese.js est servi sous /_vf/ en 200 avec une étiquette" "$(JN 'j.csp')|$(JT 'j.csp')|$(JN 'j.fichier.statut + "," + j.fichier.etag')" "0|0|200,true"
assert_eq "E0 — aucune exception de page (nue et témoin)" "$(JN 'j.erreursPage.length')|$(JT 'j.erreursPage.length')" "0|0"
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ "$FAIL" -eq 0 ]
