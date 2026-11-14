#!/usr/bin/env bash
# test-cockpit-activite-lentilles.sh — Phase 75, plan 75-08 : le sélecteur de lentilles, le menu, le panneau et le compte du radar (ACTV-01, ACTV-02, ACTV-06, ACTV-07, ACTV-08, ACTV-10).
# Moitié sans navigateur (`vm`, les fonctions PURES de ui/75-vf-activite-tables.js) : tables de marques, états, phrases, annonces ; moitié navigateur (un Chrome sans affichage,
# lab construit par la suite, avec un vrai historique git) : bouton, menu, clavier, marques, panneau, compte de `.k`, `surOnglet`. La route /api/vf/activite est lue pour de vrai (Points
# chauds, onglets, fraîcheur) ou remplacée par la page (états, empreinte, collisions : la même forme, poussée par un événement `git` du flux).
# Régime allégé (mandat commun de la Phase 75) : seuls les mutants de la chaîne XSS sont joués (MUTANT-ROUGE — <nom>).
# Variables : TABLES_JS (autre fichier de tables : le témoin rouge se rejoue sur la base, où il n'existe pas), SECTIONS (liste de sections navigateur : t1,t2,t3).
# Forme : « PASS — <id> : <texte> », « ❌ FAIL — <id> : <texte> », ligne finale « BILAN : <n> PASS, <m> FAIL » ; sort en 1 au premier FAIL.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
MODULE_UI="$HERE/../../skills/cockpit-moteur/assets/ui"
TABLES="${TABLES_JS:-$MODULE_UI/75-vf-activite-tables.js}"
FX="$HERE/fixtures/test-cockpit-activite-lentilles"
SECTIONS="${SECTIONS:-t1,t2,t3}"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/tmp.XXXXXXXXXX")"; WORK="$(cd "$WORK" && pwd -P)"
cleanup() { type vf_hyg_fin > /dev/null 2>&1 && vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
PASS=0; FAIL=0
NB=$'\xc2\xa0'

fin() { echo "BILAN : $PASS PASS, $FAIL FAIL"; [ "$FAIL" -eq 0 ]; exit $?; }
assert_eq() { # id texte obtenu attendu
  if [ "$3" = "$4" ]; then echo "  ✅ PASS — $1 : $2"; PASS=$((PASS+1))
  else echo "  ❌ FAIL — $1 : $2"; echo "     attendu: [${4:0:600}]"; echo "     obtenu:  [${3:0:600}]"; FAIL=$((FAIL+1)); fin; fi
}
wantsection() { case ",$SECTIONS," in *",$1,"*) return 0 ;; esac; return 1; }

mkdir -p "$WORK/aux"; AUX="$WORK/aux"
cat > "$AUX/vv.mjs" <<'JS'
import fs from 'node:fs'; const [, , f, cle, expr] = process.argv;
const ligne = fs.readFileSync(f, 'utf8').split('\n').find((l) => l.startsWith(cle + '=')); if (ligne === undefined) { console.log('observation absente : ' + cle); process.exit(0); }
const brut = ligne.slice(cle.length + 1); let j; try { j = JSON.parse(brut); } catch { j = brut; }
const v = new Function('j', 'return (' + expr + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; let j; try { j = JSON.parse(fs.readFileSync(0, 'utf8')); } catch { console.log('sortie illisible'); process.exit(0); }
if (j.erreur) { console.log('mesure indisponible : ' + j.erreur); process.exit(0); }
const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS

# ====================== moitié sans navigateur : les tables pures ======================
OUT="$WORK/observations.txt"
node "$FX/tables-harness.mjs" "$TABLES" > "$OUT" 2> "$WORK/erreur.txt"; RC=$?
if [ "$RC" -ne 0 ]; then echo "  ❌ FAIL — L0 : le harnais a échoué (code $RC)"; sed 's/^/     /' "$WORK/erreur.txt" | head -20; FAIL=$((FAIL+1)); fin; fi
V() { node "$AUX/vv.mjs" "$OUT" "$1" "$2"; }
assert_eq L0 "le module des tables existe et expose ses fonctions pures" "$(grep -c '^absent=true' "$OUT")" "0"

echo "== L2 la table de Points chauds : de la route aux rangées =="
assert_eq L2 "un fichier, un palier (haut, moyen, bas), « 41 changements » et son infobulle chiffrée (espace insécable des milliers)" \
  "$(V L2.chauds 'j.map((r) => r.slice(1).join("|")).join(" ; ")')" "haut|barres|41 changements|41 changements sur 90 jours · 1${NB}203 lignes · rang 12 sur 7 ; moyen|barres|5 changements|5 changements sur 90 jours · 300 lignes · rang 20 sur 7 ; bas|barres|1 changement|1 changement sur 90 jours · 10 lignes · rang 30 sur 7"
assert_eq L2 "un fichier prévu, un doc, une suite et une fixture n'ont aucune marque de Points chauds" "$(V L2.sans-marque 'j.length')" "0"
assert_eq L2 "un nombre au singulier prend le singulier (mot et infobulle)" "$(V L2.singulier 'j.join(" | ")')" "1 changement | 1 changement sur 90 jours · 10 lignes · rang 30 sur 7"
assert_eq L2 "git absent : la lentille n'est pas posée du tout (cachée, retombe sur Aucune, aucune rangée)" "$(V L2.git-absent 'j.join("|")')" "cachee|aucune|"
assert_eq L2 "fenêtre vide : aucune rangée, la légende dit « Aucune modification sur 90 jours »" "$(V L2.fenetre-vide 'j.flat().join("|")')" "0|Aucune modification sur 90 jours"
assert_eq L1b "pastille : le nombre de fichiers en écriture (1), jamais une somme ; l'aria-label dit l'état, 0 à la connexion perdue" "$(V L1.pastille 'j.join("|")')" "1|Lentille${NB}: Aucune, 1 fichier en cours d'écriture|Lentille${NB}: Points chauds|0"

# ====================== moitié navigateur ======================
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" > /dev/null 2>&1; then CHROME="$c"; break; fi; done
if [ -z "$CHROME" ]; then . "$HERE/chrome-saut.sh"; vf_chrome_saut "  ⊘ MOITIÉ NAVIGATEUR SAUTÉE : aucun navigateur (Chrome, Chromium) — le sélecteur, le menu et le panneau NON vérifiés, non comptés comme réussis"; fin; fi
SCRIPTS="$(cd "$HERE/.." && pwd)"
mkdir -p "$WORK/home/.claude"; export REAL_HOME="$HOME"; export HOME="$WORK/home"
. "$HERE/hygiene.sh"; vf_hyg_init
. "$HERE/socle-serveur.sh"
. "$FX/mk-lab.sh"
LAB="$WORK/lab"; mklentilles "$LAB"
cockpit_lancer "$LAB"; PORT="${VF_PORT:-0}"
assert_eq L0 "serveur du lab démarré" "$([ "$PORT" -gt 0 ] && echo oui || echo non)" "oui"
mesurer() { REAL_HOME="$REAL_HOME" node "$HERE/chrome-activite-lentilles.mjs" "$CHROME" "http://127.0.0.1:$VF_PORT" "$1" > "$WORK/mesure-$1.json" 2> "$WORK/mesure-$1.err"; cat "$WORK/mesure-$1.json"; }
E() { printf '%s' "$R" | node "$AUX/ev.mjs" "$1"; }

if wantsection t1; then
echo "== L1 le sélecteur : bouton, place, libellé, état, rien n'est mémorisé =="
R="$(mesurer t1)"
assert_eq L1 "bouton posé : « Lentille : Aucune » (.bl), menu, aria-expanded, SANS aria-pressed, infobulle exacte" "$(E "[j.t1.bouton.bl, j.t1.bouton.haspopup, j.t1.bouton.expanded, j.t1.bouton.pressed, j.t1.bouton.title].join('|')")" "Lentille${NB}: Aucune|menu|false|false|Lentille d'activité sur le code"
assert_eq L1 "créneau : juste après Santé, avant « Par où commencer »" "$(E "[j.t1.bouton.avant, j.t1.bouton.apres].join('|')")" "btn-health|tour-btn"
assert_eq L1 "à l'ouverture de la page : Aucune, aucune marque, aucun nom accessible de pastille" "$(E "[j.t1.ariaInactif, j.t1.bouton.rond].join('|')")" "Lentille${NB}: Aucune|0"
assert_eq L1 "jusqu'à 999 px : le bouton quitte l'en-tête, l'entrée du « ⋯ » est juste après Santé" "$(E "[j.t1.plus.bouton, j.t1.plus.entrees.indexOf('Lentille${NB}: Aucune') === j.t1.plus.entrees.indexOf('Santé') + 1, j.t1.plus.entrees.includes('Lentille${NB}: Aucune')].join('|')")" "none|true|true"
assert_eq L1 "localStorage : aucune clé neuve, ni au chargement ni après le choix d'une lentille" "$(E "[j.t1.ls[0] === j.t1.ls[1], !j.t1.ls[1].toLowerCase().includes('lentille')].join('|')")" "true|true"
assert_eq L20 "état actif : libellé « Lentille : Points chauds », fond neutre de survol, disque plein dans la lentille (r = 3 contre 0) — le signe n'est pas le survol" "$(E "[j.t1.actif.bl, /, 0\\.07\\)\$/.test(j.t1.actif.fond), j.t1.fondInactif === 'rgba(0, 0, 0, 0)', j.t1.actif.rond, j.t1.bouton.rond].join('|')")" "Lentille${NB}: Points chauds|true|true|3|0"
assert_eq L20 "choisir une ligne ferme le menu, rend le focus au bouton, aria-expanded repasse à faux, la couche de marques est celle de la lentille" "$(E "[j.t1.actif.ferme, j.t1.actif.focus, j.t1.actif.expanded, j.t1.actif.active].join('|')")" "true|true|false|activite"

echo "== L2 Points chauds sur la route réelle : mots, paliers, infobulles, nœuds =="
assert_eq L2 "src/a/m14.js (12 commits, palier haut) : « 12 changements », glyphe de palier haut, infobulle chiffrée" "$(E "((m) => [m.n, m.mot, m.glyphe.includes('lg-haut'), m.titre].join('|'))(j.t1.marques['f:src/a/m14.js'])")" "1|12 changements|true|12 changements sur 90 jours · 14 lignes · rang 1 sur 30"
assert_eq L2 "src/a/m04.js (2 commits, palier moyen) : « 2 changements » ; une seule marque par carte partout" "$(E "[j.t1.marques['f:src/a/m04.js'].mot, j.t1.marques['f:src/a/m04.js'].glyphe.includes('lg-moyen'), Object.values(j.t1.marques).every((m) => m.n <= 1)].join('|')")" "2 changements|true|true"
assert_eq L2 "carte prévue : aucune marque de lentille ; une suite : aucune marque ; un gate : sa marque" "$(E "[j.t1.prevue, j.t1.marques['f:src/a/neuf.mjs'].n, j.t1.sansMarque].join('|')")" "0|0|[0,1]"
assert_eq L2 "carte de nœud : le palier maximal et son nombre, jamais une somme (« 10 chauds », « 14 moyens »)" "$(E "JSON.parse(j.t1.noeud).map(([id, m]) => id + '=' + m).join(' ; ')")" "d:d-src|src/a=10 chauds ; d:d-src|src/b=14 moyens"
assert_eq L19 "le palier est aussi dit par le texte : le nom accessible porte « palier haut » (moyen : « palier moyen »), à la place du mot de lentille" "$(E "[j.t1.nom.includes('12 changements, palier haut, '), j.t1.nomMoyen.includes('4 changements, palier moyen, ')].join('|')")" "true|true"
assert_eq L19 "le rang figure dans la ligne du panneau du fichier (« rang 1 sur 30 »), pas seulement dans le title" "$(E "j.t1.panneau.includes('12 changements sur 90 jours · 14 lignes · rang 1 sur 30')")" "true"

assert_eq L1b "pastille neutre : le nombre de fichiers en écriture (1) sur le fond --on, jamais --recent ; l'aria-label dit l'état" "$(E "[j.t1.badge.txt, j.t1.badge.fond === j.t1.badge.on, j.t1.badge.fond !== j.t1.badge.recent, j.t1.badge.aria].join('|')")" "1|true|true|Lentille${NB}: Points chauds, 1 fichier en cours d'écriture"

echo "== L4 fraîcheur sans sondage =="
assert_eq L4 "calcul fini : ZÉRO requête sur 10 s" "$(E 'j.t1.sondage')" "0"
assert_eq L4 "calcul en cours : une lecture par seconde, 15 au plus, puis arrêt (aucune lecture ensuite)" "$(E '[j.t1.relectures[0] >= 10 && j.t1.relectures[0] <= 16, j.t1.relectures[1]].join("|")')" "true|0"

echo "== L3, L22 surOnglet : Code, Projet, Code, Projet, Code =="
assert_eq L3 "sur Projet : ni bouton, ni menu, ni compte, ni marque, ni feuille de style, aucune couche ; #ask-live toujours présent" "$(E "[0, 2].map((i) => { const v = j.t1.visites[i]; return [v.onglet, v.boutons, v.menus, v.compte, v.live, v.lm, v.styles, String(v.active)].join(','); }).join(' ; ')")" "projet,0,0,0,true,0,0,null ; projet,0,0,0,true,0,0,null"
assert_eq L22 "sur Code, deux fois : un seul bouton, un seul menu, un seul compte, quatre feuilles, #ask-live présent" "$(E "[1, 3].map((i) => { const v = j.t1.visites[i]; return [v.onglet, v.boutons, v.menus, v.compte, v.live, v.styles].join(','); }).join(' ; ')")" "code,1,1,1,true,4 ; code,1,1,1,true,4"
assert_eq L22 "VF_ETAT.abonnes() identique à chaque visite du même onglet (aucun abonnement ne double)" "$(E "[JSON.stringify(j.t1.visites[0].abonnes) === JSON.stringify(j.t1.visites[2].abonnes), JSON.stringify(j.t1.visites[1].abonnes) === JSON.stringify(j.t1.visites[3].abonnes)].join('|')")" "true|true"
assert_eq L3 "Code abonne frise, git, planning et connexion de plus que Projet, et rend ses abonnements en le quittant" "$(E "['frise', 'git', 'planning', 'connexion'].map((k) => j.t1.visites[1].abonnes[k] - j.t1.visites[0].abonnes[k] >= 1).join('|')")" "true|true|true|true"
assert_eq L22 "retour sur Code : réinitialisé (Aucune), puis la lentille choisie ne double aucune marque ; menu, compte et inscription présents" "$(E "[j.t1.libelleRetour, Object.values(j.t1.retour).every((m) => m.n <= 1), j.t1.retour['f:src/a/m14.js'].mot, j.t1.parties].join('|')")" "Lentille${NB}: Points chauds|true|14 changements|[true,true,true]"
fi

fin
