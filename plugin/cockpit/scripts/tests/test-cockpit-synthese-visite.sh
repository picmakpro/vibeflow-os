#!/usr/bin/env bash
# test-cockpit-synthese-visite.sh — le bloc « Depuis votre dernière visite » de la Synthèse et sa feuille neutre (77-08, SYNT-05, SYNT-06, SYNT-07 ; P77-D-02, P77-D-07 à P77-D-10, P77-D-30).
#   S  statique : fichiers ui/74-vf-synthese-visite.js et -style.js (jeton, routes interdites, attributs on*, plafonds, lignes AJOUT)
#   B  sondes positives des outils ajoutés au banc (chrome-synthese.mjs) · V1 à V10 le bloc · OB1 l'ordre des blocs · W4 à W7 la feuille neutre (deux thèmes)
#   W11 stockage et réseau · W12 prose retirée · W13v focus et second onglet · W15 texte du lab inerte · M-INNER mutant de la garde d'échappement · D1 README
# Le MODULE COMPLET est servi (copie par cockpit_module_copie : charge prouvée) : c'est le vrai bloc qui est rendu, jamais un bloc témoin.
# Chrome headless ; sans navigateur la partie navigateur est SAUTÉE hors CI, et ÉCHOUE en CI (jamais un vert à vide). Mutants levés hors M-INNER (régime allégé, 2026-11-13).
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE GIT_CEILING_DIRECTORIES
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; TESTS="$SCRIPTS/tests"; MOD="$(cd "$SCRIPTS/.." && pwd -P)"; ENG="$MOD/skills/cockpit-moteur"; UI="$ENG/assets/ui"
BANC="$TESTS/chrome-synthese.mjs"; VIS="$UI/74-vf-synthese-visite.js"; STY="$UI/74-vf-synthese-style.js"
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
import fs from 'node:fs'; for (const f of process.argv.slice(2)) { const l = fs.readFileSync(f, 'utf8').split('\n'); if (l.at(-1) === '') l.pop(); console.log(f, l.length, Math.max(0, ...l.map((x) => [...x.replace(/\r$/, '')].length))); }
JS
JV() { printf '%s' "$RV" | node "$AUX/ev.mjs" "$1"; }; JM() { printf '%s' "$RM" | node "$AUX/ev.mjs" "$1"; }
RE_QUAND="(aujourd'hui|hier|le [0-9]+(er)? [^ ,]+( [0-9]{4})?), [0-9]+ h [0-9]{2}"

echo "=== S — les deux fichiers neufs, statiquement ==="
assert_eq "S0 — témoin : les deux fichiers existent (jamais un vert à vide)" "$([ -f "$VIS" ] && [ -f "$STY" ] && echo oui || echo non)" "oui"
FICH=("$VIS" "$STY")
assert_eq "S1 — aucun en-tête de jeton, aucune route de dernière commande ou de transcript, eval, new Function, blob: ni attribut on*" "$(/usr/bin/grep -lE 'x-floorplan-token|x-vf-cockpit-token|eval\(|new Function|blob:| on[a-z]+=|/api/vf/(doing|transcript)' "${FICH[@]}" 2>/dev/null | tr '\n' ' ')" ""
assert_eq "S2 — la feuille n'écrit aucune règle sur le panneau du viewer, ni animation ni transition" "$(/usr/bin/grep -cE '#panel|animation|transition' "$STY" 2>/dev/null)" "0"
assert_eq "S3 — chaque fichier : première ligne « // VibeFlow ( », au plus 299 lignes, 160 points de code par ligne (mesure en points de code)" "$(for f in "${FICH[@]}"; do [ -f "$f" ] && head -n 1 "$f" | /usr/bin/grep -q '^// VibeFlow (' && node "$AUX/largeur.mjs" "$f" | awk '$2 > 299 || $3 > 160 { print $1 }' || echo "$f"; done | tr '\n' ' ')" ""
assert_eq "S4 — aucune écriture de sessionStorage ni de la clé de la visite guidée par le bloc" "$(/usr/bin/grep -cE 'sessionStorage|vibeflow-cockpit:visite|tour-seen' "$VIS" 2>/dev/null)" "0"
assert_eq "S5 — lignes AJOUT de VENDORED.txt : une par fichier, dans l'ordre alphabétique des lignes AJOUT" "$(/usr/bin/grep -c -E '^AJOUT assets/ui/74-vf-synthese-(visite|style)\.js$' "$ENG/VENDORED.txt")|$(/usr/bin/grep '^AJOUT ' "$ENG/VENDORED.txt" | LC_ALL=C sort -c 2>&1 | wc -l | tr -d ' ')" "2|0"
cat > "$AUX/sonde.css" <<'CSS'
.x { padding: 10px; color: #123456; }
CSS
node "$TESTS/css-jetons.mjs" "$AUX/sonde.css" > /dev/null 2>&1; CJ_ROUGE=$?; [ -f "$VIS" ] && [ -f "$STY" ] && { node "$TESTS/css-jetons.mjs" "$VIS" "$STY" > /dev/null 2>&1; CJ_VERT=$?; } || CJ_VERT=9
assert_eq "S6 — css-jetons : rouge sur un espacement de 10 px et une couleur injectés, vert sur les deux fichiers" "$CJ_ROUGE|$CJ_VERT" "1|0"

echo "=== D1 — le README du module dit l'effacement, la persistance, le port, le navigateur, l'origine et la borne ==="
RD="$MOD/README.md"; d1() { /usr/bin/grep -ciE "$1" "$RD"; }
assert_eq "D1 — « Tout vu », effacement des données du site, persistance après désinstallation, port, navigateur, localhost et 127.0.0.1, 8 Ko, clé derniere-visite : chacun dit au moins une fois" "$(for m in 'Tout vu' "effacement des données du site" 'désinstall.*(reste|persist|conserv)|(reste|persist|conserv).*désinstall' 'port.*(navigateur|lab).*(perd|perte)|(perd|perte).*(port|navigateur)' 'localhost' '127\.0\.0\.1' '8 Ko' 'derniere-visite'; do [ "$(d1 "$m")" -ge 1 ] && echo oui || echo "non($m)"; done | tr '\n' ',')" "oui,oui,oui,oui,oui,oui,oui,oui,"

echo "=== B — sondes positives des outils du banc (lab, interception, stockage, second onglet) ==="
LABINFO="$(node --input-type=module -e 'const { labDeuxEtats } = await import(process.argv[1]); console.log(JSON.stringify(labDeuxEtats(process.argv[2])));' "file://$BANC" "$WORK")"
LAB="$(printf '%s' "$LABINFO" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(JSON.parse(s).lab))')"
node "$SCRIPTS/vf-cockpit-build.mjs" "$LAB" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
assert_eq "B1 — labDeuxEtats : quatre commits, l'état d'après diffère de l'état d'avant, le dossier porte le marqueur" "$(basename "$LAB")|$(git -C "$LAB" rev-list --count HEAD)|$(printf '%s' "$LABINFO" | node "$AUX/ev.mjs" 'j.avant !== j.apres')" "RACINE-MARQUEUR-77|4|true"
COP="$(cockpit_module_copie "$WORK/mod-visite")"
export COCKPIT_MODULE="$COP"; cockpit_lancer "$LAB"; RL=$?; PORT="${VF_PORT:-0}"
assert_eq "B2 — le serveur du module complet est prêt et charge la copie visée" "$RL|$([ "$PORT" -gt 0 ] && echo prêt)|$(cockpit_module_charge "$COP" && echo charge)" "0|prêt|charge"

if [ -z "$CHROME" ]; then
  . "$(dirname "$0")/chrome-saut.sh"; vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur — le bloc de dernière visite dans Chrome (V1 à V10, OB1, W4 à W7, W11 à W15) n'est PAS vérifié, non comptée comme réussie"
  vf_hyg_assert; echo ""; echo "  Résultats : $PASS PASS / $FAIL FAIL"; [ "$FAIL" -eq 0 ]; exit $?
fi
mesurer() { REAL_HOME="$REAL_HOME" node "$BANC" visite "$CHROME" "$1" "$2"; }
RV="$(mesurer "$PORT" complet)"; [ -n "${DBG:-}" ] && echo "RAW: $RV"
cockpit_arreter

echo "=== B (navigateur) — outils vus positifs ==="
assert_eq "B3 — mesures obtenues sans erreur nommée ; faits du lab lus par la page (clé par lab, racine, sommet, au moins une phase)" "$(JV 'j.erreur || ""')|$(JV '/^[0-9a-f]{12}$/.test(j.faits.lab) + "," + (j.faits.cle || "").endsWith(j.faits.lab) + "," + /^[0-9a-f]{40}$/.test(j.faits.racine) + "," + /^[0-9a-f]{40}$/.test(j.faits.tete) + "," + (Object.keys(j.faits.phases).length >= 2)')" "|true,true,true,true,true"
assert_eq "B4 — sonde de la couleur (W4) : une couleur teintée injectée sous .vf-sy est vue ; stockageLu relit une clé écrite par la page ; l'interception est vue par la page" "$(JV 'j.sondes.w4 >= 1')|$(JV 'j.sondes.stockage')|$(JV 'j.sondes.intercepte + "," + (j.sondes.interceptions >= 1)')" "true|x|sondesondeabc,true"
assert_eq "B5 — second onglet : un storage écrit par le premier arrive au second (et inversement) ; le calcul de 77-04 voit une différence sur le lab avant/après (3 commits, des phases)" "$(JV 'j.sondes.storage2')|$(JV '[j.sondes.difference.vide, j.sondes.difference.commits, j.sondes.difference.phases >= 1].join()')" "true|false,3,true"

echo "=== V — le bloc « Depuis votre dernière visite » ==="
assert_eq "V1 — première visite : la phrase, aucun « Tout vu », la ligne-résumé le dit" "$(JV '[j.v1.fiche.etat, j.v1.fiche.toutVu.length, j.v1.fiche.texte, j.v1.resume].join("|")')" "premiere|0|Première visite sur ce poste Le cockpit garde le repère de cette visite dans ce navigateur, pour vous dire la prochaine fois ce qui a changé.|Première visite sur ce poste"
assert_eq "V2.1 — repère d'il y a 2 h : phases avancées, nouvelle phase, 3 commits, 1 nouveau blocage nommé (« Bloqué » et le texte), 1 blocage levé, « Tout vu »" "$(JV '[/^Depuis (aujourd.hui|hier|le [0-9]+(er)? [^ ,]+), [0-9]+ h [0-9]{2}\. [0-9]+ phases? (a|ont) avancé/.test(j.v2.fiche.texte), j.v2.fiche.texte.includes("nouvelle phase"), j.v2.fiche.texte.includes("3 commits sont arrivés"), j.v2.fiche.texte.includes("1 nouveau blocage"), j.v2.fiche.mots.includes("Bloqué"), j.v2.fiche.texte.includes("blocage piégé"), j.v2.fiche.texte.includes("1 blocage"), j.v2.fiche.mots.includes("Levé"), j.v2.fiche.toutVu.join()].join()')" "true,true,true,true,true,true,true,true,Tout vu"
assert_eq "V2.2 — ligne-résumé et nom accessible du bouton : « Depuis votre dernière visite : N phases, 3 commits, 1 nouveau blocage, 1 blocage levé »" "$(JV '/^Depuis votre dernière visite : [0-9]+ phases?, 3 commits, 1 nouveau blocage, 1 blocage levé$/.test(j.v2.resume) + "|" + j.v2.titre.startsWith("Synthèse : ") + "|" + j.v2.titre.endsWith(" depuis votre dernière visite")')" "true|true|true"
assert_eq "V2.3 — les phases sont des liens #r= (data-vf-go) nommés « Phase N » ; pas de lien vers l'onglet Équipe sans session ; aucun sujet de commit ni auteur" "$(JV '[j.v2.fiche.liens.some((l) => /^#r=.+\|.*Phase [0-9]+/.test(l)), j.v2.fiche.liens.some((l) => l.startsWith("equipe.html")), /suite [123]/.test(j.v2.fiche.texte)].join()')" "true,false,false"
assert_eq "V3 — courante de 10 min : pas de rotation, le rechargement ne vide pas la synthèse" "$(JV '[j.v3.garde.precedente.tete === j.faits.racine, j.v3.fiche.texte.includes("3 commits sont arrivés"), j.v3.fiche.toutVu.length].join()')" "true,true,1"
assert_eq "V4 — visite de plus de 24 h sans session : la réserve des 24 h, jamais un zéro seul" "$(JV '/^Depuis (hier|le [0-9]+(er)? [^ ,]+( [0-9]{4})?), [0-9]+ h [0-9]{2}\. Aucune session terminée dans les 24 dernières heures\. Seules les 24 dernières heures sont gardées\. Voir dans l.onglet Équipe Tout vu$/.test(j.v4.fiche.texte) ? "ok" : j.v4.fiche.texte')" "ok"
assert_eq "V4.2 — la réserve des 24 h porte le lien « Voir dans l'onglet Équipe » vers equipe.html" "$(JV 'j.v4.fiche.liens.some((l) => l.startsWith("equipe.html|"))')" "true"
assert_eq "V5 — identifiant de lab non reçu : le texte dit l'indisponibilité, la ligne-résumé aussi, aucune clé de visite écrite (ni après avoir quitté la page)" "$(JV '[j.v5.fiche.etat, j.v5.fiche.texte, j.v5.resume, j.v5.vues >= 1, j.v5.cles.length].join("|")')" "indispo|Repère de visite indisponible : le cockpit ne connaît pas l'identifiant de ce projet.|Repère de visite indisponible|true|0"
assert_eq "V6 — valeur corrompue : « Première visite sur ce poste », aucune erreur de console ni exception" "$(JV '[j.v6.fiche.etat, j.v6.erreurs].join()')" "premiere,0"
assert_eq "V7 — après navigation hors de la page, la clé porte une courante récente (v: 1, trois clés fermées)" "$(JV '[j.v7.v, j.v7.ageS !== null && j.v7.ageS >= 0 && j.v7.ageS < 120, (j.v7.cles || []).join("+")].join()')" "1,true,v+precedente+courante"
assert_eq "V8 — « Tout vu » : « Rien de nouveau depuis aujourd'hui, HH h MM. », plus de bouton, ligne-résumé et nom du bouton suivent, la valeur gardée avance à maintenant (phases, sommet et blocages du présent)" "$(JV '[/^Rien de nouveau depuis aujourd.hui, [0-9]+ h [0-9]{2}\.$/.test(j.v8.fiche.texte), j.v8.fiche.toutVu.length, j.v8.resume, j.v8.titre, j.v8.garde.precedente.vu >= j.avantClic && JSON.stringify([j.v8.garde.precedente.phases, j.v8.garde.precedente.tete, j.v8.garde.precedente.blocages]) === JSON.stringify([j.faits.phases, j.faits.tete, j.faits.blocages])].join("|")')" "true|0|Rien de nouveau depuis votre dernière visite|Synthèse : Rien de nouveau depuis votre dernière visite|true"
assert_eq "V9 — git en panne : « Commits : non lus, le dépôt git est indisponible. », jamais « 0 commit », les autres lignes intactes" "$(JV '[j.v9.fiche.texte.includes("Commits : non lus, le dépôt git est indisponible."), /0 commit/.test(j.v9.fiche.texte), j.v9.fiche.texte.includes("nouveau blocage"), /phases? (a|ont) avancé/.test(j.v9.fiche.texte), j.v9.vues >= 1].join()')" "true,false,true,true,true"
assert_eq "V10 — après deux changements d'onglet : un seul bloc, une seule ligne-résumé, écouteurs de document et de window égaux à ceux d'un chargement à froid (A51), une seule écriture de courante par masquage" "$(JV '[j.v10.blocs, j.v10.lignes, JSON.stringify(j.v10.ecout) === JSON.stringify(j.ecout0), j.v10.ecritures].join()')" "1,1,true,1"
OB_ATT="visite"; [ -f "$UI/74-vf-synthese-burnup.js" ] && OB_ATT="$OB_ATT-burnup"; [ -f "$UI/74-vf-synthese-jauges.js" ] && OB_ATT="$OB_ATT-methode"
assert_eq "OB1 — ordre final des blocs dans le DOM : visite d'abord, jamais trié (blocs de 77-06 présents au dépôt : $OB_ATT)" "$(JV 'j.ob1.join("-")')" "$OB_ATT"

echo "=== W — la feuille neutre, dans les deux thèmes ==="
for th in clair sombre; do
  assert_eq "W4/W7 ($th) — couleurs neutres (R, G, B à ±2), fonds ∈ {transparent, piste, survol}, aucune ombre, aucun liseré ni halo coloré (au moins dix éléments mesurés)" "$(JV "(j.w4.$th.n >= 10) + '|' + JSON.stringify([j.w4.$th.mal.couleur, j.w4.$th.mal.fond, j.w4.$th.mal.ombre, j.w4.$th.mal.liseres])")" 'true|[[],[],[],[]]'
  assert_eq "W5 ($th) — espacements calculés dans la grille fermée (0, 2, 4, 6, 8, 12, 16, 20, 24, 32)" "$(JV "JSON.stringify(j.w4.$th.mal.espace)")" "[]"
  assert_eq "W6 ($th) — tailles ∈ {20, 13,5, 12,5, 11} px, graisses ∈ {400, 500, 600}, polices Inter ou JetBrains Mono" "$(JV "JSON.stringify([j.w4.$th.mal.taille, j.w4.$th.mal.graisse, j.w4.$th.mal.police])")" "[[],[],[]]"
done
assert_eq "W11.1 — localStorage : seule la clé derniere-visite:<lab> est ajoutée, JSON v: 1, au plus 8 192 octets, relue par la mémoire de 77-04 (liste fermée) ; sessionStorage inchangé ; la visite guidée n'est pas écrite" "$(JV '[j.w11.nouvelles.join() === j.faits.cle, j.w11.octets > 0 && j.w11.octets <= 8192, j.w11.relue, j.w11.v, j.w11.session, j.w11.visiteGuidee.length].join()')" "true,true,true,1,true,0"
assert_eq "W11.2 — aucun POST, aucune requête vers les routes de dernière commande ou de transcript, chaque lecture de l'API porte le jeton (témoin : le journal voit des GET)" "$(JV '[j.reseau.posts, j.reseau.interdites, j.reseau.sansJeton, j.reseau.gets >= 1].join()')" "0,0,0,true"
assert_eq "W12 — la prose du STATE (MARQUEUR-PROSE-77) est absente de Projet ; meta.vf n'a plus la clé de prose" "$(JV '[j.w12.prose, j.w12.cle].join()')" "false,false"
assert_eq "W13v.1 — « Tout vu » : le focus passe au h3 du bloc, la zone vive annonce « Synthèse remise à zéro. »" "$(JV '[j.v8.focus.tag, j.v8.focus.id, j.v8.sr].join("|")')" "H3|vf-sy-t-visite|Synthèse remise à zéro."
assert_eq "W13v.2 — second onglet : il reçoit storage et met à jour sa ligne-résumé et le nom du bouton, sans changer son focus ni annoncer" "$(JV '[j.w13v.resume2, j.w13v.titre2Apres, j.w13v.apres2 === j.w13v.avant2, j.w13v.sr2 === ""].join("|")')" "Rien de nouveau depuis votre dernière visite|Synthèse : Rien de nouveau depuis votre dernière visite|true|true"
assert_eq "W13v.3 — l'arrivée de données (écriture d'un autre onglet) ne déplace pas le focus posé sur un lien du bloc" "$(JV '[j.w13v.focusLien.tag, j.w13v.focusLien.dansBloc, JSON.stringify(j.w13v.focusApresDonnees) === JSON.stringify(j.w13v.focusLien)].join()')" "A,true,true"
assert_eq "W15 — la balise piégée du STATE est affichée en texte : aucun attribut on*, aucune image, window.__xss indéfini, aucun securitypolicyviolation" "$(JV '[j.w15.xss, j.w15.on, j.w15.attrs, j.w15.img, j.w15.texte, j.csp].join()')" "undefined,0,0,0,true,0"
assert_eq "E0 — aucune exception de page ni console.error" "$(JV 'j.erreursPage.length')" "0"

echo "=== M-INNER — la garde d'échappement : un texte du lab injecté sans échappement rougit W15 ==="
if cockpit_module_muter_page minner 's/n\.appendChild(document\.createTextNode(c))/n.insertAdjacentHTML("beforeend", c)/'; then
  cockpit_lancer "$LAB"; RLM=$?; PM="${VF_PORT:-0}"
  assert_eq "M-INNER.0 — le serveur du mutant est prêt et charge la copie mutée (charge prouvée)" "$RLM|$([ "$PM" -gt 0 ] && echo prêt)|$(cockpit_module_charge "$COCKPIT_MODULE" && echo charge)" "0|prêt|charge"
  RM="$(mesurer "$PM" xss)"; cockpit_arreter
  assert_eq "M-INNER — sur le mutant, la balise piégée s'exécute (window.__xss posé ou image rendue) : W15 rougit, la sonde est donc capable d'échouer" "$(JM '(j.w15.xss !== "undefined") || (j.w15.img > 0)')" "true"
else assert_eq "M-INNER.0 — la mutation s'applique (ancre présente dans le fichier du bloc)" "refusée" "appliquée"; fi
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ "$FAIL" -eq 0 ]
