#!/usr/bin/env bash
# test-cockpit-echec-onglet.sh — dire l'échec d'un chargement d'onglet (80-21, FORM-16, P80-D-22), un vrai Chrome, sans réseau.
#   EC1 un onglet affiché, la lecture de Projet en échec : annonce, palette, relance, ligne d'état (pilote : chrome-echec-onglet.mjs, mode ec1)
#   EC2 premier chargement en échec : un seul message, « Réessayer » prend le focus ; script persistant (mode ec2)
#   Mutants : levés (régime allégé de la Phase 80, ce plan n'est pas une garde).  EC_SCRIPTS = dossier de scripts à bâtir (rejeu sur la base).
# Sans navigateur : SUITE SAUTÉE (exit 0, message explicite), jamais un vert à vide.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"; ENG="$SCRIPTS/../skills/cockpit-moteur"
CHROME=""
for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
if [ -z "$CHROME" ]; then
  . "$HERE_T/chrome-saut.sh"
  vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur (Chrome, Chromium) — l'échec d'un chargement d'onglet NON vérifié, non compté comme réussi"; exit 0
fi
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0; SC_BASE="${EC_SCRIPTS:-$SCRIPTS}"
. "$HERE_T/couloirs-commun.sh"
FICHIER="$SC_BASE/../skills/cockpit-moteur/assets/ui/00-vf-onglets-echec.js"
TEXTE="Lecture impossible : les données de cet onglet n'ont pas pu être lues."
mesurer() { REAL_HOME="$REAL_HOME" node "$HERE_T/chrome-echec-onglet.mjs" "$CHROME" "http://127.0.0.1:$PORT" "$1" "$FICHIER" 2>"$WORK/mesure.err"; }
sonde() { [ -n "${SONDE:-}" ] && { printf '%s\n' "$1"; cat "$WORK/mesure.err"; }; return 0; }
LAB="$WORK/lab"; mklab "$LAB"
wr "$LAB/src/app/main.js" <<< 'export const a = 1;'; wr "$LAB/README.md" <<< '# lab'
git -C "$LAB" add -A && git -C "$LAB" -c user.email=t@t -c user.name=t commit -q -m code
build_serve "$LAB"
assert_eq "EC0 — serveur du lab démarré" "$([ "$PORT" -gt 0 ] && echo oui || echo non)" "oui"

echo "=== EC1 — un onglet affiché, la lecture de Projet en échec ==="
R1="$(mesurer ec1)"; sonde "$R1"; E1() { E "$1" "$R1"; }
assert_eq "EC1.1 — échec annoncé une fois, annulé, Code reste affiché (adresse, titre, focus), aucune boîte, echec() lit l'échec" \
  "$(E1 '[j.ec11.e1.etat.phase, j.ec11.e1.etat.onglet, j.ec11.e1.aff, j.ec11.e1.p === j.ec11.e0.p, j.ec11.e1.t === j.ec11.e0.t, j.ec11.e1.ae === j.ec11.e0.ae,
    j.ec11.e1.prevented.join(), j.ec11.e1.live, JSON.stringify(j.ec11.e1.ech), j.ec11.e1.boite, j.ec11.e1.repli, j.ec11.e1.o === j.ec11.e0.o]')" \
  "[\"echec\",\"projet\",\"code\",true,true,true,\"true\",\"$TEXTE L'onglet Code reste affiché.\","\
"\"{\\\"onglet\\\":\\\"projet\\\",\\\"affiche\\\":\\\"code\\\"}\",false,false,true]"
assert_eq "EC1.2 — palette : une rangée « Réessayer » (détail : Projet) au champ vide, à la saisie, en mode > ; absente du registre ; sans échec : aucune" \
  "$(E1 '[j.ec12.vide, j.ec12.saisie, j.ec12.action, j.ec12.reg, j.ec12.sansEchec.vide, j.ec12.sansEchec.saisie]')" \
  '[["Réessayer|Projet"],["Réessayer|Projet"],["Réessayer|Projet"],[],[],[]]'
assert_eq "EC1.2b — Entrée sur la rangée relance : Projet affiché, même page, état prêt, une seule lecture, aucun POST, echec() nul" \
  "$(E1 '[j.ec12.apres.p, j.ec12.apres.origine, j.ec12.apres.pret.phase, j.ec12.apres.aff, j.ec12.apres.ech, j.ec12.apres.fetchs, j.ec12.apres.posts]')" \
  '["/project.html",true,"pret","projet",null,1,0]'
assert_eq "EC3.1 — ligne d'état : « Lecture impossible · Réessayer », une rangée, zone d'appui de 44 au moins, retirée après la relance réussie" \
  "$(E1 '[j.ec31.rangee.texte, j.ec31.rangee.nb, j.ec31.rangee.h >= 44, j.ec31.rangee.vis, j.ec31.apres]')" '["Lecture impossible · Réessayer",1,true,true,0]'
assert_eq "EC3.1b — Entrée sur « Réessayer » de la ligne, lecture encore en échec : un second échec, même état, Code toujours affiché" \
  "$(E1 '[j.ec31.encore.echec, j.ec31.encore.ech && j.ec31.encore.ech.onglet, j.ec31.encore.p]')" '[2,"projet","/"]'
assert_eq "EC1.3 — échec, deux changements d'onglet réussis, nouvel échec : l'entrée de palette une fois, zéro entre les deux, une rangée d'état" \
  "$(E1 '[j.ec13.un, j.ec13.entre, j.ec13.deux, j.ec13.rangees]')" '[1,0,1,1]'
assert_eq "EC1.4 — le script d'échec réévalué après coup : echec() lit toujours l'échec, l'entrée est offerte, aucune annonce de plus" \
  "$(E1 '[j.ec14.ech && j.ec14.ech.onglet, j.ec14.live, j.ec14.rangees]')" '["projet",true,1]'

echo "=== EC2 — premier chargement en échec ==="
R2="$(mesurer ec2)"; sonde "$R2"; E2() { E "$1" "$R2"; }
assert_eq "EC2.2 — script persistant : un objet gelé { montrer, retirer }, UNE écoute (vf:coquille-echec), aucun nœud ni lecture du moteur" \
  "$(E2 '[j.ec22.un, j.ec22.gele, j.ec22.cles.join(), j.ec22.ecoutes.join(), j.ec22.noeuds, j.ec22.lectures.length, j.ec22.marqueur]')" \
  '[true,true,"montrer,retirer","vf:coquille-echec",0,0,true]'
for n in projet code equipe; do
  assert_eq "EC2.1 ($n) — un seul message, la boîte, « Réessayer » a le focus, annulé, aucun repli de la coquille, aucune animation" \
    "$(E2 "[j.ec21$n.e1.etat.phase, j.ec21$n.e1.aff, j.ec21$n.e1.prevented.join(), j.ec21$n.niv.texte, j.ec21$n.niv.role, j.ec21$n.niv.bouton,
      j.ec21$n.e1.ae, j.ec21$n.e1.lectures, j.ec21$n.niv.repli, j.ec21$n.niv.anim]")" \
    "[\"echec\",null,\"true\",\"$TEXTE\",\"status\",\"Réessayer\",\"BUTTON\",1,false,0]"
  assert_eq "EC2.1b ($n) — encore en échec : la boîte revient, focus sur « Réessayer » ; levée : onglet chargé, boîte retirée, aucune entrée de plus" \
    "$(E2 "[j.ec21$n.encore.boite, j.ec21$n.encore.ae, j.ec21$n.fin.etat.phase, j.ec21$n.fin.boite, j.ec21$n.fin.ech, j.ec21$n.dn <= 0]")" \
    '[true,"BUTTON","pret",false,null,true]'
done
echo "=== Sans erreur de pilote ==="
ERR=""; for r in "$R1" "$R2"; do ERR="$ERR$(E 'Object.entries(j.erreurs).map((x) => x[0] + "=" + x[1]).join()' "$r")"; done
assert_eq "EC9 — aucune section du pilote n'a échoué" "$ERR" ""
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
