#!/usr/bin/env bash
# test-cockpit-projet-visite.sh — la visite du cockpit dans Chrome, onglets Code et Projet, et le panneau « Format de la planification » dans la page : « Par où commencer » ne revient pas d'elle-même (O4 : port stable par lab,
# localStorage seul, aucun cookie), parcourue étape par étape (O5 : cible, centrage, texte entier, « Passer », repère, français), visite propre à l'onglet Projet (O6.5-O6.19, y compris les passes police large, titre haut,
# tangente, carte haute), panneau Format de la planification (R3.13-R3.22).
# Découpe de l'ancien test-cockpit-projet.sh (arbitrage Samuel, AskUserQuestion session principale, 2026-11-07) ; le socle commun est projet-commun.sh. Serveurs lancés par le vrai lanceur (vf-cockpit.mjs), plage de ports décalée.
# Sans navigateur : « SUITE SAUTÉE », exit 0, jamais comptée comme réussie. Exit 0 si tout passe, 1 sinon.

set -uo pipefail
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi; done
if [ -z "$CHROME" ]; then echo "  ⊘ SUITE SAUTÉE : aucun navigateur (Chrome, Chromium) — la visite (O4, O5, O6.5-O6.19) et le panneau Format dans la page (R3.13-R3.22) ne sont PAS vérifiés, non comptés comme réussis"; exit 0; fi
. "$(dirname "$0")/projet-commun.sh"
# lab de dérive de R3 (R3.13-R3.22 en copient le .planning), construit comme dans test-cockpit-projet-graphe.sh
mk_r3 "$WORK/r3"
# O4 (recette 3, arbitrage Samuel, AskUserQuestion session principale, 2026-11-03) : la visite « Par où commencer » revenait à chaque chargement et recouvrait la réponse. Cause : son « déjà vue » vivait dans le localStorage
# de l'ORIGINE (port compris) et le port du serveur changeait à chaque lancement. Décision (même date, « C : port stable par lab ») : port stable par lab (vf-cockpit-port.mjs), « déjà vue » en localStorage seul,
# par lab (vibeflow-cockpit:visite:<lab>, 75-vf-modele.js), aucun cookie. Serveurs lancés par le VRAI lanceur (vf-cockpit.mjs), plage de ports décalée (VF_COCKPIT_PORT_BASE : 4378 et 4379 tiennent les serveurs de recette).
# Un Chrome, un profil. Cas : visite au premier chargement ; fermée (croix) puis rechargée sur le MÊME port ; fermée (Échap) idem ; passée jusqu'au bout (autre lab) idem ; serveur relancé (même port stable) ;
# bouton qui la rouvre ; aucun cookie. O4.3 (« même lab, AUTRE port ») n'a plus de sens avec le port stable : remplacé par la relance du serveur. Sans navigateur la section est SAUTÉE, jamais comptée comme réussie.
echo "=== O4 — la visite « Par où commencer » ne revient pas d'elle-même : port stable par lab, localStorage seul, aucun cookie ==="
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
SRVPIDS=(); LABS4=()
fin4() { for L in ${LABS4[@]+"${LABS4[@]}"}; do node "$SCRIPTS/vf-cockpit.mjs" stop --lab "$L" >/dev/null 2>&1; done; for p in ${SRVPIDS[@]+"${SRVPIDS[@]}"}; do vf_hyg_stop "$p"; done; vf_hyg_fin; rm -rf "$WORK"; }
trap fin4 EXIT
mklab4() {
  local L="$1" B="$1/.planning"; mkdir -p "$L/src" "$B/phases/01-socle"
  printf 'export const u = () => 1;\n' > "$L/src/util.js"; printf '# Roadmap\n\n## Jalon démo\n\n- [x] **Phase 1: Socle** - premier jet\n- [ ] **Phase 2: Suite** - deuxième jet\n- [ ] **Phase 3: Fin** - dernier jet\n' > "$B/ROADMAP.md"
  printf '<objective>Faire le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"; echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  LABS4+=("$L")
}
# plage décalée : base prise au hasard au-dessus des ports de recette, jamais 4378..4500
export VF_COCKPIT_PORT_BASE=$((30000 + (RANDOM * 11) % 30000))
adr4() { node "$SCRIPTS/vf-cockpit.mjs" open --no-open --lab "$1" | sed -En 's#^Cockpit : (http://127\.0\.0\.1:[0-9]+)/ .*#\1/index.html#p' | head -1; }
pid4() { node "$AUX/get.mjs" "$1/.vibeflow/cockpit/.cache/server.json" 'j.pid' 2>/dev/null || echo 0; }
pref4() { node --input-type=module -e "import('$SCRIPTS/vf-cockpit-port.mjs').then(m=>console.log(m.portPrefere(process.argv[1])))" "$1"; }
# trois labs dont les ports préférés sont éloignés (≥ 25) : jamais de collision, donc jamais de repli, qui rendrait le cas dépendant du hasard des noms de dossier
for i in $(seq 1 80); do L4="$WORK/lab4-$i"; LC4="$WORK/lab4c-$i"; LE4="$WORK/lab4e-$i"; mkdir -p "$L4" "$LC4" "$LE4"; x=$(pref4 "$L4"); y=$(pref4 "$LC4"); z=$(pref4 "$LE4")
  [ $((x>y ? x-y : y-x)) -ge 25 ] && [ $((x>z ? x-z : z-x)) -ge 25 ] && [ $((y>z ? y-z : z-y)) -ge 25 ] && break; done
rmdir "$L4" "$LC4" "$LE4" 2>/dev/null; mklab4 "$L4"; mklab4 "$LC4"; mklab4 "$LE4"
UA="$(adr4 "$L4")"; SRVPIDS+=("$(pid4 "$L4")"); UC="$(adr4 "$LC4")"; SRVPIDS+=("$(pid4 "$LC4")"); UE="$(adr4 "$LE4")"; SRVPIDS+=("$(pid4 "$LE4")")
cat > "$WORK/relance4.sh" <<RELANCE
#!/usr/bin/env bash
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null VF_COCKPIT_PORT_BASE=$VF_COCKPIT_PORT_BASE
for l in "$L4" "$LC4" "$LE4"; do node "$SCRIPTS/vf-cockpit.mjs" stop --lab "\$l" >/dev/null 2>&1; done
op() { node "$SCRIPTS/vf-cockpit.mjs" open --no-open --lab "\$1" | sed -En 's#^Cockpit : (http://127\.0\.0\.1:[0-9]+)/ .*#\1/index.html#p' | head -1; }
c=\$(op "$LC4"); e=\$(op "$LE4"); a=\$(op "$L4"); printf '%s\n%s\n%s\n' "\$a" "\$c" "\$e"
RELANCE
chmod +x "$WORK/relance4.sh"
XV="$(node "$SCRIPTS/tests/chrome-visite.mjs" "$CHROME" "$UA" "$UC" "$UE" "$WORK/relance4.sh")"
SRVPIDS+=("$(pid4 "$L4")" "$(pid4 "$LC4")" "$(pid4 "$LE4")")
[ -n "${DBG:-}" ] && echo "RAW: $XV"
x4() { printf '%s' "$XV" | node "$AUX/get.mjs" /dev/stdin "$1"; }
assert_eq "O4.0 — témoin : deux labs sur deux ports, la mesure a eu lieu sans erreur, le port du lab est celui de l'empreinte" "$([ "$UA" != "$UC" ] && echo distincts)|$(x4 "j.erreur||''")|$([ "${UA##*:}" = "$(node --input-type=module -e "import('$SCRIPTS/vf-cockpit-port.mjs').then(m=>console.log(m.portPrefere(process.argv[1])))" "$L4")/index.html" ] && echo stable)" "distincts||stable"
assert_eq "O4.1 — premier chargement du lab, la visite s'affiche" "$(x4 'j.premiere')" "true"
assert_eq "O4.2 — fermée par la croix, elle ne revient pas au rechargement sur le même port" "$(x4 'j.croix')" "false"
assert_eq "O4.2b — fermée par Échap (troisième lab, vu pour la première fois), elle ne revient pas au rechargement" "$(x4 'j.echap')" "false"
assert_eq "O4.3 — les trois serveurs arrêtés puis relancés dans un autre ordre (même port stable) : elle ne revient pas (page initialisée, lab connu ; adresse identique)" "$(x4 '[j.relance,j.temoins]')|$([ "$(x4 'j.urlRelance')" = "$UA" ] && echo meme-adresse)" "[false,true]|meme-adresse"
assert_eq "O4.4 — le bouton « Par où commencer » la rouvre" "$(x4 'j.bouton')" "true"
assert_eq "O4.5 — un AUTRE lab la voit à son premier chargement (le rangement est par lab, pas global)" "$(x4 'j.autreLab')" "true"
assert_eq "O4.6 — passée jusqu'au bout (autre lab), elle ne revient pas au rechargement" "$(x4 'j.passee')" "false"
assert_eq "O4.7 — aucun cookie posé : document.cookie vide sur chaque page chargée (témoin : au moins 6 relevés)" "$(x4 'j.cookies.filter(Boolean).length')|$(x4 'j.cookies.length>=6')" "0|true"
# O5 (70-07, UIFN-04, P70-D-02 : arbitrage Samuel, AskUserQuestion session principale, 2026-11-03) : la visite « Par où commencer » parcourue étape par étape (chrome-visite-etapes.mjs), sur l'onglet Code d'un lab
# jetable à plusieurs cartes de premier niveau, servi par le vrai lanceur, à 1 440 et 390 px. Une assertion par mesure et par largeur ; l'obtenu liste les ÉTAPES fautives (numéros, vide = aucune).
# O5.1 chaque étape cible un élément (carte sélectionnée, centrée dans une zone libre et non couverte par la carte de visite, ou élément du chrome mis en évidence) · O5.2 texte entier (jamais « … »), carte de visite dans la fenêtre
# O5.3 « Passer » visible à chaque étape · O5.4 repère « n sur N » juste · O5.5 aucun mot anglais témoin.
echo "=== O5 — la visite, étape par étape : cible, centrage, texte entier, « Passer », repère, français ==="
L5="$WORK/lab5"; mkdir -p "$L5"; mklab4 "$L5"
for d in web api db; do mkdir -p "$L5/$d"; for i in 1 2 3; do printf "export const f%s = () => %s;\n" "$i" "$i" > "$L5/$d/m$i.js"; done; done
git -C "$L5" add -A && git -C "$L5" -c user.email=t@t -c user.name=t commit -q -m cartes
U5="$(adr4 "$L5")"; SRVPIDS+=("$(pid4 "$L5")")
X5="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$U5" 1440,390)"
[ -n "${DBG:-}" ] && echo "RAW5: $X5"
x5() { printf '%s' "$X5" | node "$AUX/get.mjs" /dev/stdin "$1"; }
assert_eq "O5.0 — témoin : la mesure a eu lieu sans erreur, au moins trois étapes à chaque largeur" "$(x5 "j.erreur||''")|$(x5 'j.l1440.n>=3&&j.l390.n>=3')" "|true"
for W in 1440 390; do
  f5() { x5 "j.l$W.etapes.filter((e)=>$1).map((e)=>e.i).join(',')"; }
  assert_eq "O5.1 [$W px] — étapes sans cible, hors du centre de la zone libre, recouvertes par la carte de visite ou hors fenêtre" "$(f5 '!e.cible||!e.centre||e.couvert||!e.visible')" ""
  assert_eq "O5.2 [$W px] — étapes dont le texte est coupé, incomplet ou dont la carte de visite sort de la fenêtre" "$(f5 'e.coupe||!e.entier||!e.tient')" ""
  assert_eq "O5.3 [$W px] — étapes sans bouton « Passer » visible" "$(f5 '!e.passer')" ""
  assert_eq "O5.4 [$W px] — étapes dont le repère n'est pas « n sur N » juste" "$(x5 "j.l$W.etapes.filter((e)=>e.repere!==e.i+' sur '+j.l$W.n).map((e)=>e.i).join(',')")" ""
  assert_eq "O5.5 [$W px] — étapes qui montrent un mot anglais (liste de F11)" "$(f5 '!!e.anglais')" ""
done
# O5.6 (correctif 70-07) : même cas, onglet Code : page déjà vue dans le même profil, rechargée, aux deux largeurs
X56="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$U5" 1440,390 recharge)"
x56() { printf '%s' "$X56" | node "$AUX/get.mjs" /dev/stdin "$1"; }
assert_eq "O5.6 — Code, page déjà vue (rechargement) : mesure sans erreur et étapes sans cible, mal centrées, couvertes ou hors fenêtre, aux deux largeurs" "$(x56 "j.erreur||''")|$(x56 '["l1440","r1440","l390","r390"].map((k)=>j[k].etapes.filter((e)=>!e.cible||!e.centre||e.couvert||!e.visible).map((e)=>k+":"+e.i).join(",")).join("")')" "|"
# O6.5 (70-08) : la même visite parcourue dans Chrome sur l'onglet Projet (project.html) d'un lab à jalon, phase en cours, mission : les mesures O5.1 à O5.5 passent sur Projet, quatre étapes, la première est celle du jalon.
echo "=== O6.5 — la visite Projet dans Chrome ==="
L6="$WORK/lab6"; mkdir -p "$L6"; mklab4 "$L6"
printf -- '---\nstatus: executing\ncurrent_phase: 2\n---\n' > "$L6/.planning/STATE.md"
mkdir -p "$L6/.planning/missions"; printf '{"phase":"2","nodes":[{"id":"a","step":"s","deps":[],"status":"running"}]}\n' > "$L6/.planning/missions/MISSION-X.dag.json"
git -C "$L6" add -A && git -C "$L6" -c user.email=t@t -c user.name=t commit -q -m projet
U6="$(adr4 "$L6")"; SRVPIDS+=("$(pid4 "$L6")"); P6="${U6%index.html}project.html"
# un Chrome (donc un profil neuf) par largeur : la visite se mesure à la PREMIÈRE ouverture de la page ; au rechargement d'une page déjà vue dans le même profil, le centrage de la première étape (une carte) dérive (écart consigné dans 70-08-SUMMARY.md)
X61="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$P6" 1440)"; X62="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$P6" 390)"
X6="$(node -e "const a=JSON.parse(process.argv[1]),b=JSON.parse(process.argv[2]);console.log(JSON.stringify({erreur:a.erreur||b.erreur,...a,...b}))" "$X61" "$X62")"
[ -n "${DBG:-}" ] && echo "RAW6: $X6"
x6() { printf '%s' "$X6" | node "$AUX/get.mjs" /dev/stdin "$1"; }
cat > "$AUX/titres.mjs" <<'JS'
// titres.mjs <chrome> <session.mjs> <url> : titre, kicker et repère de chaque étape de la visite lancée par son API ; une ligne JSON { etapes: [ { kicker, titre, note } ] } ou { erreur }
import { pathToFileURL } from 'node:url';
const [, , chrome, sess, url] = process.argv;
const { executer, pause, stabiliser, attendreValeur } = await import(pathToFileURL(sess).href);
await executer(chrome, async (s) => {
  await s.naviguer(url); await s.attendre("document.readyState === 'complete' && !!window.VibeFlowTour && !!document.getElementById('tour-btn')", 'page prête');
  await s.attendre("!!window.__vfModele && !!window.__vfModele.modele", 'lab connu');
  await attendreValeur(() => s.ev('window.VibeFlowTour.active()'), (v) => v === true, { max: 3000 }); // le démarrage d'office a eu lieu (ou n'aura pas lieu : plafond 3 s)
  await s.ev('window.VibeFlowTour.end()'); await s.ev('window.VibeFlowTour.start()'); await s.attendre('window.VibeFlowTour.active()', 'visite lancée', 15000);
  const etapes = [];
  for (let i = 0; i < 12 && (await s.ev('window.VibeFlowTour.active()')); i++) {
    // l'étape affichée est celle attendue (« i sur N »), puis son texte est posé (deux relevés identiques) : on ne lit plus 400 ms après la touche
    const lire = () => s.ev("(() => { const c = document.getElementById('tour'); const q = (x) => (c.querySelector(x) || {}).textContent || ''; return { kicker: q('.tk span:last-child'), titre: q('.tt'), note: q('.tn'), rep: ((/(\\d+) sur \\d+/.exec(q('.tk')) || [])[1]) || '' }; })()");
    await attendreValeur(lire, (v) => v.rep === String(i + 1), { max: 10000 });
    const { kicker, titre, note } = await stabiliser(lire, { pas: 250, max: 5000 });
    etapes.push({ kicker, titre, note });
    await s.ev("window.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowRight', bubbles: true }))"); await pause(150);
  }
  return { etapes };
});
JS
T6="$(node "$AUX/titres.mjs" "$CHROME" "$SCRIPTS/tests/chrome-session.mjs" "$P6")"
[ -n "${DBG:-}" ] && echo "RAW6T: $T6"
t6() { printf '%s' "$T6" | node "$AUX/get.mjs" /dev/stdin "$1"; }
assert_eq "O6.5a — témoin : la mesure a eu lieu sans erreur, la visite Projet compte quatre étapes à chaque largeur" "$(x6 "j.erreur||''")|$(x6 'j.l1440.n+","+j.l390.n')" "|4,4"
assert_eq "O6.5b — la première étape est celle du jalon, la dernière « au travail » ; aucune ne dit « base de code »" "$(t6 'j.etapes.length')|$(t6 '/jalon/i.test(((j.etapes[0]||{}).kicker||"")+((j.etapes[0]||{}).titre||""))')|$(t6 '/travail/i.test(((j.etapes[3]||{}).kicker||"")+((j.etapes[3]||{}).titre||""))')|$(t6 'j.etapes.filter((e)=>/base de code|dans le code/i.test(e.kicker+e.titre+e.note)).length')" "4|true|true|0"
for W in 1440 390; do
  f6() { x6 "j.l$W.etapes.filter((e)=>$1).map((e)=>e.i).join(',')"; }
  assert_eq "O6.5c [$W px] — Projet : étapes sans cible, mal centrées, couvertes ou hors fenêtre (O5.1)" "$(f6 '!e.cible||!e.centre||e.couvert||!e.visible')" ""
  assert_eq "O6.5d [$W px] — Projet : texte coupé ou carte hors fenêtre (O5.2)" "$(f6 'e.coupe||!e.entier||!e.tient')" ""
  assert_eq "O6.5e [$W px] — Projet : étapes sans « Passer » (O5.3)" "$(f6 '!e.passer')" ""
  assert_eq "O6.5f [$W px] — Projet : repère « n sur N » faux (O5.4)" "$(x6 "j.l$W.etapes.filter((e)=>e.repere!==e.i+' sur '+j.l$W.n).map((e)=>e.i).join(',')")" ""
  assert_eq "O6.5g [$W px] — Projet : mot anglais (O5.5)" "$(f6 '!!e.anglais')" ""
done
# O6.6 (correctif 70-07, relevé par 70-08) : la visite d'une page DÉJÀ vue dans le même profil Chrome (rechargement) se centre comme au premier chargement. Cause : le fit de 450 ms du démarrage de la visite défaisait
# le centrage d'une première étape qui est une carte (onglet Projet) quand la carte était mesurée tôt ; un profil neuf, plus lent à se poser, masquait le cas. Ici UN Chrome pour les deux largeurs, deux passes chacune (clés l, r).
X66="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$P6" 390,1440 recharge)"
[ -n "${DBG:-}" ] && echo "RAW66: $X66"
x66() { printf '%s' "$X66" | node "$AUX/get.mjs" /dev/stdin "$1"; }
assert_eq "O6.9 — témoin : le rechargement a été mesuré (erreur vide, quatre étapes à chaque passe)" "$(x66 "j.erreur||''")|$(x66 '["l390","r390","l1440","r1440"].map((k)=>j[k].n).join()')" "|4,4,4,4"
for K in l390 r390 l1440 r1440; do
  assert_eq "O6.9 [$K] — Projet, page déjà vue dans le même profil : étapes sans cible, mal centrées, couvertes ou hors fenêtre" "$(x66 "j.$K.etapes.filter((e)=>!e.cible||!e.centre||e.couvert||!e.visible).map((e)=>e.i).join(',')")" ""
done
# O6.11 et O6.12 (correctifs 70-07, juge Playwright de la recette) : sur l'onglet Projet, UN Chrome, 1 440 puis 390 px, option `passer` : O6.11 « Passer » (ou Échap) pendant une étape de carte rend la vue d'avant la visite (même transformation, aucune carte
# de moins dans la fenêtre, aucune carte recouverte par le titre) ; O6.12 le contour d'une étape sur un élément du chrome (« au travail », #vf-lock) survit à la réécriture du className du bouton par la couche live (70-vf-live.js).
# lab à quatorze phases : le jalon est une grande carte, la visite la zoome et la déplace (sur un petit lab elle est déjà en place)
L8="$WORK/lab8"; mkdir -p "$L8"; mklab4 "$L8"
{ printf '# Roadmap\n\n## Jalon démo\n\n'; for i in $(seq 1 14); do printf -- '- [ ] **Phase %s: Étape %s** - jet %s\n' "$i" "$i" "$i"; done; } > "$L8/.planning/ROADMAP.md"
printf -- '---\nstatus: executing\ncurrent_phase: 2\n---\n' > "$L8/.planning/STATE.md"
mkdir -p "$L8/.planning/missions"; printf '{"phase":"2","nodes":[{"id":"a","step":"s","deps":[],"status":"running"}]}\n' > "$L8/.planning/missions/MISSION-X.dag.json"
git -C "$L8" add -A && git -C "$L8" -c user.email=t@t -c user.name=t commit -q -m grand
U8="$(adr4 "$L8")"; SRVPIDS+=("$(pid4 "$L8")"); P8="${U8%index.html}project.html"
X68="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$P8" 1440,390 passer)"
[ -n "${DBG:-}" ] && echo "RAW68: $X68"
x68() { printf '%s' "$X68" | node "$AUX/get.mjs" /dev/stdin "$1"; }
assert_eq "O6.11a — témoin : la mesure a eu lieu sans erreur, avec la vue d'avant et la vue d'après « Passer » aux deux largeurs" "$(x68 "j.erreur||''")|$(x68 '!!(j.p1440&&j.p1440.avant&&j.p1440.apres&&j.p390&&j.p390.avant&&j.p390.apres)')" "|true"
for W in 1440 390; do
  assert_eq "O6.11 [$W px] — « Passer » à l'étape 3 (une carte) rend la vue d'ensemble d'avant la visite, celle que rend « Terminé » (zoom à 2 % près, position à 4 px près, aucune carte de moins dans la fenêtre, aucune de plus recouverte par le titre)" "$(x68 "[j.p$W].map((p)=>Math.abs(p.avant.k-p.apres.k)<=p.avant.k*0.02&&Math.abs(p.avant.x-p.apres.x)<=4&&Math.abs(p.avant.y-p.apres.y)<=4&&p.apres.visibles>=p.avant.visibles&&p.apres.recouvre<=p.avant.recouvre)[0]")" "true"
  assert_eq "O6.12 [$W px] — Projet : le contour de l'étape « au travail » est encore là après la réécriture du className de #vf-lock (étapes dont le contour a disparu)" "$(x68 "j.l$W.etapes.filter((e)=>e.anneau===true).map((e)=>e.i).join(',')")" ""
done
# O6.16 (Q6b, P70-D-23 : Samuel, AskUserQuestion session principale Claude Code, 2026-11-04 : « Tout selon les recos (Recommandé) ») : sous 701 px, la visite zoome une petite carte jusqu'à la rendre lisible (le juge a mesuré 46 x 31 px) : au moins 120 px de large
# à chaque étape de carte à 390 px (le graphe entier n'y borne plus le zoom : il ne tient pas à cette taille ; au-dessus de 701 px le bornage par le graphe entier reste, O6.10).
assert_eq "O6.16 [390 px] — Projet (lab à quatorze phases) : étapes dont la carte ciblée fait moins de 120 px de large (largeur mesurée)" "$(x68 "j.l390.etapes.filter((e)=>e.largeur!=null&&e.largeur<120).map((e)=>e.i+':'+e.largeur+'px').join(',')")" ""
# O6.13 (correctif 70-07, CI Linux de la PR #200 : R20 « #panel recouvre #tour » à 768 px) : la carte de visite ne passe jamais sous le panneau de détail, quelle que soit la largeur de celui-ci (elle dépend des polices et de la plateforme :
# ici le panneau est élargi à 440 px, ce qui rougit sans Linux). Cause : la carte gardait ses 360 px et son côté même quand le panneau s'avançait. L'émulation `pointer: none` de la suite (R8) ne reproduit PAS le cas : R20 reste vert sous Chrome sans pointeur.
X69="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$P6" 768,1024 panneau)"
[ -n "${DBG:-}" ] && echo "RAW69: $X69"
x69() { printf '%s' "$X69" | node "$AUX/get.mjs" /dev/stdin "$1"; }
assert_eq "O6.13a — témoin : la mesure a eu lieu sans erreur, au moins trois étapes à chaque largeur" "$(x69 "j.erreur||''")|$(x69 'j.l768.n>=3&&j.l1024.n>=3')" "|true"
for W in 768 1024; do
  assert_eq "O6.13 [$W px] — Projet, panneau élargi à 440 px : étapes dont la carte de visite recouvre le panneau" "$(x69 "j.l$W.etapes.filter((e)=>e.surPanneau).map((e)=>e.i).join(',')")" ""
done
# O6.14 (correctif 70-07, CI Linux de ddc487ce : R20 « #context recouvre #tour » à 768 px sur Équipe) : la visite ne s'ouvre pas d'elle-même sur l'onglet Équipe, qui n'a aucune visite conçue (P70-D-02 vise Code et Projet ; son graphe
# a `tour: []`, le repli aurait raconté « une base de code » à propos de sessions et de sous-agents). Sous Linux le démarrage d'office l'ouvrait (le rendu y est plus lent : les cartes de l'équipe sont déjà là à ses 700 ms) ; ici on appelle
# start() comme lui, sans argument, ce qui rougit sous macOS. Le bouton « Par où commencer » reste libre de l'ouvrir. Lab avec une session et un sous-agent, HOME jetable.
HEQ="$WORK/home-eq"; LEQ="$WORK/lab-eq"; mkdir -p "$LEQ/src" "$LEQ/.planning/phases/01-socle" "$HEQ/.claude/projects/-lab-eq"
printf 'export const u = () => 1;\n' > "$LEQ/src/util.js"; printf '# Roadmap\n\n## Jalon démo\n\n- [ ] **Phase 1: Socle** - jet\n' > "$LEQ/.planning/ROADMAP.md"; printf '<objective>x</objective>\n' > "$LEQ/.planning/phases/01-socle/01-01-PLAN.md"
git -C "$LEQ" init -q && git -C "$LEQ" add -A && git -C "$LEQ" -c user.email=t@t -c user.name=t commit -q -m init; LABS4+=("$LEQ")
SIDQ=aaaa1111-2222-3333-4444-000000000099; TSQ="$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"; DQ="$HEQ/.claude/projects/-lab-eq"; mkdir -p "$DQ/$SIDQ/subagents"
printf '{"type":"user","cwd":"%s","sessionId":"%s","gitBranch":"main","version":"2.1.317","timestamp":"%s","message":{"content":"salut"}}\n{"type":"assistant","cwd":"%s","sessionId":"%s","gitBranch":"main","version":"2.1.317","timestamp":"%s","message":{"content":[{"type":"text","text":"bonjour"}]}}\n' "$LEQ" "$SIDQ" "$TSQ" "$LEQ" "$SIDQ" "$TSQ" > "$DQ/$SIDQ.jsonl"
printf '{"agentType":"vf-coder","isBuiltIn":false,"launchedWithDefaults":false,"description":"tâche synthétique","toolUseId":"toolu_s1","spawnDepth":1,"requestShape":"background","requestNonInteractive":true}' > "$DQ/$SIDQ/subagents/agent-s1.meta.json"
printf '{"type":"user","isSidechain":true,"agentId":"s1","parentUuid":null,"cwd":"%s","sessionId":"%s","gitBranch":"main","version":"2.1.317","timestamp":"%s","message":{"role":"user","content":"mandat synthétique"}}\n' "$LEQ" "$SIDQ" "$TSQ" > "$DQ/$SIDQ/subagents/agent-s1.jsonl"
UEQ="$(HOME="$HEQ" adr4 "$LEQ")"; SRVPIDS+=("$(pid4 "$LEQ")"); PEQ="${UEQ%index.html}equipe.html"
XEQ="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$PEQ" 768 equipe)"
[ -n "${DBG:-}" ] && echo "RAWEQ: $XEQ"
xeq() { printf '%s' "$XEQ" | node "$AUX/get.mjs" /dev/stdin "$1"; }
assert_eq "O6.14a — témoin : la mesure a eu lieu sans erreur, l'onglet Équipe a au moins deux cartes (une session et un sous-agent)" "$(xeq "j.erreur||''")|$(xeq 'j.e768.cartes>=2')" "|true"
assert_eq "O6.14 — Équipe / 768 px : le démarrage d'office (start() sans argument) n'ouvre pas la visite" "$(xeq 'j.e768.auto')" "false"
assert_eq "O6.14b — Équipe : le bouton « Par où commencer » n'ouvre plus de visite (Samuel, AskUserQuestion session principale Claude Code, 2026-11-04 : « Tout selon les recos (Recommandé) », P70-D-23, Q13a), il est désactivé (aria-disabled) avec une infobulle qui le dit" "$(xeq 'j.e768.manuel')|$(xeq 'j.e768.bouton.aria')|$(xeq '/Équipe/.test(j.e768.bouton.titre)')" "false|true|true"
# O6.15 (CI Linux de 03bada92 : R15.4b « Échap ferme le tiroir » rouge sous Linux, où la visite d'office s'ouvre pendant la mesure) : quand la visite est ouverte, elle est la couche du dessus et capte la première Échap ; le tiroir de détail
# n'est touché ni par l'ouverture de la visite, ni par sa sortie, et la seconde Échap le ferme. Contrat de l'ordre, mesuré à 390 px sur Projet ; R15.4b mesure donc le tiroir visite fermée (test-cockpit-responsive.sh, section R15 seule).
XEC="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$P6" 390 echap)"
[ -n "${DBG:-}" ] && echo "RAWEC: $XEC"
xec() { printf '%s' "$XEC" | node "$AUX/get.mjs" /dev/stdin "$1"; }
assert_eq "O6.15a — témoin : mesure sans erreur, tiroir ouvert par la carte avant la visite, visite démarrée" "$(xec "j.erreur||''")|$(xec 'j.t390.carteOuverte.tiroir')|$(xec 'j.t390.visiteDemarree.tour')" "|true|true"
assert_eq "O6.15 — visite ouverte au-dessus d'un tiroir ouvert : l'ouverture de la visite ne ferme pas le tiroir ; la première Échap ferme la visite et laisse le tiroir ; la seconde ferme le tiroir (tiroir|visite après chaque temps)" "$(xec '[j.t390.visiteDemarree,j.t390.echap1,j.t390.echap2].map((x)=>x.tiroir+"/"+x.tour).join(" ")')" "true/true true/false false/false"
# DIAG : pour chaque étape fautive de O6.17, une ligne compacte de bbox et de polices (aucune assertion ne change ; la CI Linux nous donne ainsi la vraie géométrie)
diag17() { # diag17 <étiquette> <json> <largeur> <clé>
  local l; l="$(printf '%s' "$2" | node "$AUX/get.mjs" /dev/stdin "j.l$3.etapes.filter((e)=>e.surfaces.length||!e.dansZone||!e.tient||!e.toutLibre||e.couvert).map((e)=>'étape '+e.i+' toutLibre='+e.toutLibre+' couvert='+e.couvert+' surfaces='+e.surfaces.join('+')+' '+e.diag).join('\\n')" 2>/dev/null)"
  [ -n "$l" ] && printf '%s\n' "$l" | sed "s/^/     DIAG $1 [$3 px] /"
  return 0
}
# O6.17 (CI Linux de 07e75a54 : R3 « #zoom recouvre #tour » à 800 px ; quatrième instance après #panel, #context et Échap) : la CLASSE de défaut, pas un cas de plus. Visite ouverte par l'API (sans course de calendrier), sur Code et sur Projet,
# à 390, 768, 800, 1 024 et 1 440 px : à CHAQUE étape, la carte de visite ne recouvre aucune surface fixe visible de l'interface (#zoom, #panel, #context, en-tête, #ask et ses avis, contour de la cible).
XS1="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$U5" 390,768,800,1024,1440)"; XS2="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$P6" 390,768,800,1024,1440)"
[ -n "${DBG:-}" ] && echo "RAWS: $XS1 $XS2"
xs1() { printf '%s' "$XS1" | node "$AUX/get.mjs" /dev/stdin "$1"; }
xs2() { printf '%s' "$XS2" | node "$AUX/get.mjs" /dev/stdin "$1"; }
assert_eq "O6.17a — témoin : les deux mesures ont eu lieu sans erreur, au moins deux étapes à chaque largeur" "$(xs1 "j.erreur||''")|$(xs2 "j.erreur||''")|$(xs1 '[390,768,800,1024,1440].every((w)=>j["l"+w].n>=2)')|$(xs2 '[390,768,800,1024,1440].every((w)=>j["l"+w].n>=2)')" "||true|true"
for W in 390 768 800 1024 1440; do
  assert_eq "O6.17 [$W px] — Code : étapes dont la carte de visite recouvre une surface fixe (étape:surfaces)" "$(xs1 "j.l$W.etapes.filter((e)=>e.surfaces.length).map((e)=>e.i+':'+e.surfaces.join('+')).join(' ')")" ""
  diag17 "O6.17 Code" "$XS1" "$W"
  assert_eq "O6.17 [$W px] — Projet : étapes dont la carte de visite recouvre une surface fixe (étape:surfaces)" "$(xs2 "j.l$W.etapes.filter((e)=>e.surfaces.length).map((e)=>e.i+':'+e.surfaces.join('+')).join(' ')")" ""
  diag17 "O6.17 Projet" "$XS2" "$W"
done
# O6.17 passe « police large » (CI Linux de 63efb1e1 : O6.17 à 800 px, R22, R3 à 390 px rougissaient sous Linux, où Chrome tombe sur DejaVu Sans, plus large que les polices de macOS) : la classe de défaut doit être fermée pour TOUTE largeur de police.
# La carte de visite, le titre et les cartes du graphe prennent Verdana puis DejaVu Sans avec un espacement de lettres (le poste ne décide plus de la taille des textes) ; mêmes cinq largeurs, Code et Projet : aucune surface recouverte,
# la carte ciblée entièrement dans la zone libre (marges comprises), la carte de visite dans la fenêtre. Témoin générique, à garder.
XP1="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$U5" 390,768,800,1024,1440 police)"; XP2="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$P6" 390,768,800,1024,1440 police)"
[ -n "${DBG:-}" ] && echo "RAWP: $XP1 $XP2"
xp1() { printf '%s' "$XP1" | node "$AUX/get.mjs" /dev/stdin "$1"; }
xp2() { printf '%s' "$XP2" | node "$AUX/get.mjs" /dev/stdin "$1"; }
assert_eq "O6.17p-a — témoin : les deux mesures en police large ont eu lieu sans erreur, au moins deux étapes à chaque largeur" "$(xp1 "j.erreur||''")|$(xp2 "j.erreur||''")|$(xp1 '[390,768,800,1024,1440].every((w)=>j["l"+w].n>=2)')|$(xp2 '[390,768,800,1024,1440].every((w)=>j["l"+w].n>=2)')" "||true|true"
for W in 390 768 800 1024 1440; do
  assert_eq "O6.17p [$W px] — Code, police large : étapes dont la carte de visite recouvre une surface fixe, dont la carte ciblée sort de la zone libre ou dont la carte de visite sort de la fenêtre" "$(xp1 "j.l$W.etapes.filter((e)=>e.surfaces.length||!e.dansZone||!e.tient).map((e)=>e.i+':'+e.surfaces.join('+')+(e.dansZone?'':' hors-zone')+(e.tient?'':' hors-fenetre')).join(' ')")" ""
  diag17 "O6.17p Code" "$XP1" "$W"
  assert_eq "O6.17p [$W px] — Projet, police large : étapes dont la carte de visite recouvre une surface fixe, dont la carte ciblée sort de la zone libre ou dont la carte de visite sort de la fenêtre" "$(xp2 "j.l$W.etapes.filter((e)=>e.surfaces.length||!e.dansZone||!e.tient).map((e)=>e.i+':'+e.surfaces.join('+')+(e.dansZone?'':' hors-zone')+(e.tient?'':' hors-fenetre')).join(' ')")" ""
  diag17 "O6.17p Projet" "$XP2" "$W"
done
# O6.17d passe « police réelle » : la VRAIE DejaVu Sans (fichiers TTF libres hors dépôt, $VF_DEJAVU_DIR) imposée à toute la page par @font-face, comme le fait fontconfig sous Ubuntu. Sautée, et dite sautée, sans la variable.
if [ -n "${VF_DEJAVU_DIR:-}" ] && [ -f "$VF_DEJAVU_DIR/DejaVuSans.ttf" ]; then
  XD1="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$U5" 390,768,800,1024,1440 dejavu)"; XD2="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$P6" 390,768,800,1024,1440 dejavu)"
  xd1() { printf '%s' "$XD1" | node "$AUX/get.mjs" /dev/stdin "$1"; }
  xd2() { printf '%s' "$XD2" | node "$AUX/get.mjs" /dev/stdin "$1"; }
  assert_eq "O6.17d-a — témoin : mesures en DejaVu Sans réelle sans erreur, polices rendues = DejaVu Sans" "$(xd1 "j.erreur||''")|$(xd2 "j.erreur||''")|$(xd2 'j.l800.etapes.every((e)=>/DejaVu Sans/.test(e.diag.split("rendu=")[1]||""))')" "||true"
  for W in 390 768 800 1024 1440; do
    assert_eq "O6.17d [$W px] — Code, DejaVu Sans réelle : étapes dont la carte de visite recouvre une surface fixe ou dont la carte ciblée sort de la zone libre" "$(xd1 "j.l$W.etapes.filter((e)=>e.surfaces.length||!e.dansZone||!e.tient).map((e)=>e.i+':'+e.surfaces.join('+')).join(' ')")" ""
    diag17 "O6.17d Code" "$XD1" "$W"
    assert_eq "O6.17d [$W px] — Projet, DejaVu Sans réelle : étapes dont la carte de visite recouvre une surface fixe ou dont la carte ciblée sort de la zone libre" "$(xd2 "j.l$W.etapes.filter((e)=>e.surfaces.length||!e.dansZone||!e.tient).map((e)=>e.i+':'+e.surfaces.join('+')).join(' ')")" ""
    diag17 "O6.17d Projet" "$XD2" "$W"
  done
else echo "  ⊘ O6.17d SAUTÉ : VF_DEJAVU_DIR absent (DejaVuSans.ttf et DejaVuSans-Bold.ttf hors dépôt) — la passe en police réelle n'est PAS vérifiée, non comptée comme réussie"; fi
# O6.17t passe « titre haut » (CI Linux de 6c75f230 : #context recouvre #tour à 800 px, introuvable avec DejaVu Sans réelle sous macOS) : le bloc titre est rempli d'une description de 600 caractères avant la visite (police, nom de projet long, ce qui en fait
# un titre plus haut que prévu) ; la carte de visite ne doit rien recouvrir, quitte à replier la description pendant la visite. Cinq largeurs, Code et Projet. Témoin générique de géométrie, indépendant de la police du poste.
XT1="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$U5" 390,768,800,1024,1440 titrehaut)"; XT2="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$P6" 390,768,800,1024,1440 titrehaut)"
xt1() { printf '%s' "$XT1" | node "$AUX/get.mjs" /dev/stdin "$1"; }
xt2() { printf '%s' "$XT2" | node "$AUX/get.mjs" /dev/stdin "$1"; }
assert_eq "O6.17t-a — témoin : mesures à titre haut sans erreur, au moins deux étapes à chaque largeur" "$(xt1 "j.erreur||''")|$(xt2 "j.erreur||''")|$(xt1 '[390,768,800,1024,1440].every((w)=>j["l"+w].n>=2)')|$(xt2 '[390,768,800,1024,1440].every((w)=>j["l"+w].n>=2)')" "||true|true"
for W in 390 768 800 1024 1440; do
  assert_eq "O6.17t [$W px] — Code, titre haut : étapes dont la carte de visite recouvre une surface fixe (étape:surfaces)" "$(xt1 "j.l$W.etapes.filter((e)=>e.surfaces.length).map((e)=>e.i+':'+e.surfaces.join('+')).join(' ')")" ""
  diag17 "O6.17t Code" "$XT1" "$W"
  assert_eq "O6.17t [$W px] — Projet, titre haut : étapes dont la carte de visite recouvre une surface fixe (étape:surfaces)" "$(xt2 "j.l$W.etapes.filter((e)=>e.surfaces.length).map((e)=>e.i+':'+e.surfaces.join('+')).join(' ')")" ""
  diag17 "O6.17t Projet" "$XT2" "$W"
done
# O6.18 passe « tangente » (CI Linux de f41cfd25 : R22 « #ask recouvre #tour » à 1 640 px ; diagnostic de la CI : placement jugé libre à 260 px de large, carte rendue 16..276, #ask à partir de 274) : la carte de visite est jugée sur sa bbox AU MOMENT du placement,
# c'est-à-dire pendant son animation d'entrée (98 % de sa taille) ; une surface à 2 px du bord de la carte finie paraît alors à distance et la carte la recouvre une fois posée. Ici #ask, plus haute (avis), est posée à 2 px DANS le bord de la carte
# à sa largeur d'origine, immobile avant la visite. Cinq largeurs ne sont pas utiles : la géométrie est celle de la carte ; 1 024 et 1 440 px, Code et Projet.
XG1="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$U5" 1024,1440 tangent)"; XG2="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$P6" 1024,1440 tangent)"
xg1() { printf '%s' "$XG1" | node "$AUX/get.mjs" /dev/stdin "$1"; }
xg2() { printf '%s' "$XG2" | node "$AUX/get.mjs" /dev/stdin "$1"; }
assert_eq "O6.18a — témoin : mesures tangentes sans erreur, au moins deux étapes à chaque largeur" "$(xg1 "j.erreur||''")|$(xg2 "j.erreur||''")|$(xg1 '[1024,1440].every((w)=>j["l"+w].n>=2)')|$(xg2 '[1024,1440].every((w)=>j["l"+w].n>=2)')" "||true|true"
for W in 1024 1440; do
  assert_eq "O6.18 [$W px] — Code, #ask à 2 px dans le bord de la carte : étapes dont la carte de visite recouvre une surface fixe" "$(xg1 "j.l$W.etapes.filter((e)=>e.surfaces.length).map((e)=>e.i+':'+e.surfaces.join('+')).join(' ')")" ""
  diag17 "O6.18 Code" "$XG1" "$W"
  assert_eq "O6.18 [$W px] — Projet, #ask à 2 px dans le bord de la carte : étapes dont la carte de visite recouvre une surface fixe" "$(xg2 "j.l$W.etapes.filter((e)=>e.surfaces.length).map((e)=>e.i+':'+e.surfaces.join('+')).join(' ')")" ""
  diag17 "O6.18 Projet" "$XG2" "$W"
done
# O6.10 (correctif 70-07, REG-70-01 de 70-VERIFICATION.md) : visite Projet active au premier chargement sur un lab à jalon et à mission, à 1 024 et 1 920 px : la carte ciblée tient dans la zone libre ET aucune carte du graphe ne sort de la zone
# libre à gauche du panneau (critère de R1, chrome-responsive.mjs). Cause : aim() centrait et zoomait la carte sans regarder le reste du graphe, qui débordait sous le panneau ; il ne dézoomait jamais une carte plus large que sa zone.
L7="$WORK/vibeflow-os-un-nom-de-projet-vraiment-tres-long-pour-tester"; mkdir -p "$L7/src" "$L7/.planning/phases/01-socle" "$L7/.planning/phases/02-suite" "$L7/.planning/missions"
printf 'export const u = () => 1;\n' > "$L7/src/util.js"; printf '# Roadmap\n\n## Jalon démo\n\n- [x] **Phase 1: Socle** - premier jet\n- [ ] **Phase 2: Suite** - la suite\n' > "$L7/.planning/ROADMAP.md"
printf '<objective>Faire le socle</objective>\n' > "$L7/.planning/phases/01-socle/01-01-PLAN.md"; echo ok > "$L7/.planning/phases/01-socle/01-01-SUMMARY.md"; printf '<objective>Faire la suite</objective>\n' > "$L7/.planning/phases/02-suite/02-01-PLAN.md"
printf '{"nodes":[{"id":"a","step":"première étape","stage":"","deps":[],"scope":["src/**"],"status":"done"},{"id":"b","step":"seconde étape","stage":"","deps":["a"],"scope":["src/**"],"status":"running"}]}\n' > "$L7/.planning/missions/demo.dag.json"
git -C "$L7" init -q && git -C "$L7" add -A && git -C "$L7" -c user.email=t@t -c user.name=t commit -q -m init; LABS4+=("$L7")
U7="$(adr4 "$L7")"; SRVPIDS+=("$(pid4 "$L7")"); P7="${U7%index.html}project.html"
X7="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$P7" 1024)"; X72="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$P7" 1920)"
X7="$(node -e "const a=JSON.parse(process.argv[1]),b=JSON.parse(process.argv[2]);console.log(JSON.stringify({erreur:a.erreur||b.erreur,...a,...b}))" "$X7" "$X72")"
[ -n "${DBG:-}" ] && echo "RAW7: $X7"
x7() { printf '%s' "$X7" | node "$AUX/get.mjs" /dev/stdin "$1"; }
assert_eq "O6.10 — témoin : la mesure a eu lieu sans erreur, au moins trois étapes à chaque largeur" "$(x7 "j.erreur||''")|$(x7 'j.l1024.n>=3&&j.l1920.n>=3')" "|true"
for W in 1024 1920; do
  assert_eq "O6.10 [$W px] — Projet : étapes dont la carte ciblée sort de la zone libre, dont une carte du graphe sort de la zone libre à gauche du panneau, ou qui sélectionnent une carte (le panneau doit garder la vue d'ensemble, R5.3)" "$(x7 "j.l$W.etapes.filter((e)=>!e.dansZone||!e.toutLibre||e.selectionne).map((e)=>e.i).join(',')")" ""
done
# O6.19 passe « carte haute » (CI Linux de 83b13be4 puis 6498ed80 : R1 « long / project / 1 024 px : carte : sort de la zone libre (245..692 / libre 0..648) », intermittent, puis O6.19 lui-même à 1 024 px) : garantie de construction, pas un cas de plus.
# Au-dessus de 701 px un état existe toujours : réduire le zoom jusqu'à ce que tout le graphe tienne dans la zone libre (hors panneau, carte de visite, titre, en-tête, barre de question) avec la carte ciblée visible. aim() réduit donc le zoom par
# paliers (jusqu'à 40 % du zoom qui remplit juste la zone libre) au lieu de centrer comme avant. Contraintes poussées plus loin que la CI : carte de visite de 420 px de haut au moins, seule, puis avec une police large, puis avec la vraie DejaVu Sans
# ($VF_DEJAVU_DIR). Lab « nom long » (jalon, mission), Projet, 768, 1 024 et 1 440 px. Mutant (à la main, voir 70-07-RED-TRACE.md) : le repli « centrer comme avant » rétabli rougit à 1 024 et 1 440 px.
for OPT in cartehaute cartehaute,police cartehaute,dejavu; do
  case "$OPT" in *dejavu*) { [ -n "${VF_DEJAVU_DIR:-}" ] && [ -f "$VF_DEJAVU_DIR/DejaVuSans.ttf" ]; } || { echo "  ⊘ O6.19 [$OPT] SAUTÉ : VF_DEJAVU_DIR absent — la passe en police réelle n'est PAS vérifiée, non comptée comme réussie"; continue; };; esac
  XH="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$P7" 768,1024,1440 "$OPT")"
  xh() { printf '%s' "$XH" | node "$AUX/get.mjs" /dev/stdin "$1"; }
  assert_eq "O6.19a [$OPT] — témoin : mesure sans erreur, au moins deux étapes à chaque largeur" "$(xh "j.erreur||''")|$(xh '[768,1024,1440].every((w)=>j["l"+w].n>=2)')" "|true"
  for W in 768 1024 1440; do
    assert_eq "O6.19 [$OPT, $W px] — Projet, carte de visite haute : étapes dont une carte du graphe sort de la zone libre à gauche du panneau, ou dont la carte ciblée est recouverte ou hors de sa zone" "$(xh "j.l$W.etapes.filter((e)=>!e.toutLibre||e.couvert||!e.dansZone).map((e)=>e.i).join(',')")" ""
    diag17 "O6.19 $OPT Projet" "$XH" "$W"
  done
done
# R3 (retours panel, lot 6) — le panneau « Format de la planification » dans Chrome : section toujours là (PU-G-160), écart en tête avec lien (PU-G-151), glyphes distincts (PU-G-159), liste lisible (PU-G-152),
# clic = copie de « fichier:ligne » (PU-G-154), bouton Copier = exactement la commande affichée (PU-G-153, Q14), bloc Santé absent (DG-15). Le presse-papiers est remplacé par un témoin qui note ce qu'on lui donne.
cat > "$AUX/format.mjs" <<'JS'
// format.mjs <chrome> <session.mjs> <url> : une ligne JSON { ... } mesurée dans le panneau d'ensemble de l'onglet Projet
import { pathToFileURL } from 'node:url';
const [, , chrome, sess, url] = process.argv;
const { executer, pause, stabiliser, attendreValeur, attendreEtStabiliser } = await import(pathToFileURL(sess).href);
const r = await executer(chrome, async (s) => {
  await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
  await s.naviguer(url); await s.attendre("document.readyState === 'complete' && !!document.querySelector('#panel .vf-stats') && !!document.getElementById('vf-format')", 'section Format');
  // la mise en page du panneau est posée (section, lignes non lues, texte) avant toute mesure de géométrie : deux relevés identiques, jamais une durée fixe
  await stabiliser(() => s.ev("(() => { const b = (e) => { if (!e) return null; const r = e.getBoundingClientRect(); return [r.left, r.top, r.width, r.height].map(Math.round); }; const rf = [...document.querySelectorAll('.vf-ref')].map((e) => [b(e.querySelector('.vf-texte')), b(e.querySelector('code'))]); return { sec: b(document.getElementById('vf-format')), al: b(document.querySelector('.vf-alerte')), cmd: b(document.querySelector('.vf-cmd')), rf, pw: document.getElementById('panel').scrollWidth }; })()"), { pas: 250, max: 5000 });
  const o = await s.ev(`(async () => {
    window.__cp = []; Object.defineProperty(navigator, 'clipboard', { value: { writeText: (t) => { window.__cp.push(t); return Promise.resolve(); } }, configurable: true });
    const q = (x) => document.querySelector(x), qa = (x) => [...document.querySelectorAll(x)];
    const sec = q('#vf-format'), al = q('.vf-alerte'), cmd = q('.vf-cmd code'), btn = q('.vf-cmd .vf-copie'), refs = qa('.vf-ref');
    const txt = (e) => (e ? e.innerText.replace(/\\s+/g, ' ').trim() : '');
    // glyphes : une pastille témoin par classe, injectée dans le panneau, lue par son style calculé (chaque forme est un masque propre)
    const sonde = document.createElement('div'); document.body.appendChild(sonde);
    const forme = (c) => { sonde.innerHTML = '<span class="vst vst-' + c + '">x</span>'; return getComputedStyle(sonde.firstChild).getPropertyValue('--g-st').trim(); };
    const G = Object.fromEntries(['done', 'active', 'todo', 'blocked', 'recette', 'abandonnee', 'tolere', 'ignore', 'info'].map((c) => [c, forme(c)])); sonde.remove();
    const o = { section: !!sec, titre: txt(sec && sec.querySelector('h3')), texteSection: txt(sec),
      alerte: txt(al), lienAlerte: al && al.querySelector('[data-vf-section]') ? al.querySelector('[data-vf-section]').dataset.vfSection : '',
      formes: Object.values(G).filter(Boolean).length, formesDistinctes: new Set(Object.values(G)).size,
      santeDansDom: qa('#panel [data-hc-open]').length, sante: qa('#panel .sec').some((e) => e.querySelector('[data-hc-open]') && getComputedStyle(e).display !== 'none'),
      listeTitre: txt(qa('#panel h3').find((h) => /non lues/.test(h.textContent))), nbRefs: refs.length,
      commande: cmd ? cmd.textContent : '', commandeBouton: btn ? btn.dataset.vfCopie : '' };
    const panneau = q('#panel'); o.debordeH = panneau.scrollWidth > panneau.clientWidth + 1;
    if (refs.length) { const t = refs[0].querySelector('.vf-texte'), c = refs[0].querySelector('code'); o.largeurTexte = Math.round(t.getBoundingClientRect().width); o.largeurPanneau = Math.round(panneau.clientWidth); o.refSurUneLigne = c.getBoundingClientRect().height < 40; o.texteApresRef = t.getBoundingClientRect().top >= c.getBoundingClientRect().bottom - 1;
      // le dernier segment (« ROADMAP.md:23 ») tient sur UNE ligne : jamais coupé au milieu d'un nom ou d'un numéro
      const tn = [...c.childNodes].filter((n) => n.nodeType === 3).at(-1), seg = tn.textContent.split('/').pop(), r = document.createRange(); r.setStart(tn, tn.textContent.length - seg.length); r.setEnd(tn, tn.textContent.length); o.dernierSegmentUneLigne = r.getClientRects().length === 1; }
    o.alertePresente = !!al; o.copiePresente = !!q('.vf-cmd .vf-copie'); o.refPresente = refs.length > 0;
    return o; })()`);
  // les trois gestes suivants lisent leur effet dès qu'il est posé (défilement fini, copie faite et libellé « Copié », qui peut être éphémère), jamais après un délai fixe
  if (o.alertePresente) {
    await s.ev("document.querySelector('.vf-alerte [data-vf-section]').click()");
    // la section est visible dans le panneau (le prédicat de l'assertion), PUIS son défilement est fini ; un relevé pris avant que le défilement ne commence n'est pas retenu
    const lireSection = () => s.ev("(() => { const b = document.getElementById('vf-format').getBoundingClientRect(), p = document.getElementById('panel').getBoundingClientRect(); return { top: Math.round(b.top), ok: b.top >= p.top - 2 && b.top < p.bottom }; })()");
    const sec = await attendreEtStabiliser(lireSection, (v) => v.ok, { max: 6000 });
    o.sectionVisible = !!(sec && sec.ok);
  }
  if (o.copiePresente) {
    await s.ev("document.querySelector('.vf-cmd .vf-copie').click()");
    const c = await attendreValeur(() => s.ev("(() => { const b = document.querySelector('.vf-cmd .vf-copie'); return { cp: window.__cp.at(-1) || '', et: b ? b.textContent.trim() : '' }; })()"), (v) => v.cp !== '' && v.et === 'Copié');
    o.copieCommande = c.cp; o.etatBouton = c.et;
  }
  if (o.refPresente) {
    const avant = await s.ev('window.__cp.length');
    await s.ev("document.querySelectorAll('.vf-ref')[0].click()");
    const c = await attendreValeur(() => s.ev("(() => { const r2 = document.querySelectorAll('.vf-ref')[0]; return { n: window.__cp.length, cp: window.__cp.at(-1) || '', aff: r2.querySelector('code').textContent.replace(/^Copié/, '').trim(), et: r2.querySelector('.vf-copie-etat').textContent }; })()"), (v) => v.n > avant && v.et === 'Copié');
    o.copieRef = c.cp; o.refAffichee = c.aff; o.etatRef = c.et;
  }
  o.nbCopies = await s.ev('window.__cp.length');
  return o;
});
console.log(JSON.stringify(r));
JS
mkdir -p "$WORK/lab-r3c/src"; LR3="$WORK/lab-r3c"; cp -R "$WORK/r3/.planning" "$LR3/.planning"; printf 'export const u = () => 1;\n' > "$LR3/src/util.js"
git -C "$LR3" init -q && git -C "$LR3" add -A && git -C "$LR3" -c user.email=t@t -c user.name=t commit -q -m init; LABS4+=("$LR3")
UR3="$(adr4 "$LR3")"; SRVPIDS+=("$(pid4 "$LR3")"); PR3="${UR3%index.html}project.html"
XR3="$(node "$AUX/format.mjs" "$CHROME" "$SCRIPTS/tests/chrome-session.mjs" "$PR3")"
[ -n "${DBG:-}" ] && echo "RAWR3: $XR3"
xr3() { printf '%s' "$XR3" | node "$AUX/get.mjs" /dev/stdin "$1"; }
assert_eq "R3.13 — PU-G-155 : le panneau dit « 5 écarts : 1 lu malgré une petite différence, 4 non lus » (le compteur du titre vaut 5)" "$(xr3 'j.titre')|$(xr3 '/5 écarts : 1 lu malgré une petite différence, 4 non lus\./.test(j.texteSection)')" "Format de la planification 5|true"
assert_eq "R3.14 — PU-G-151 : l'écart est dit EN TÊTE du panneau (« 4 lignes du planning non lues — chiffres peut-être incomplets ») avec un lien vers la section, qui l'amène à l'écran" "$(xr3 'j.alerte')|$(xr3 'j.lienAlerte')|$(xr3 'j.sectionVisible')" "4 lignes du planning non lues — chiffres peut-être incomplets · Voir|vf-format|true"
assert_eq "R3.15 — PU-G-159 : « lu malgré une petite différence » (triangle), « non lu » (losange) et « à savoir » (anneau à point) ont chacun un glyphe de forme propre : neuf formes de pastille, non vides, toutes distinctes (dont l'anneau de « À faire » et la coche de « Fait »)" "$(xr3 'j.formes+"|"+j.formesDistinctes')" "9|9"
assert_eq "R3.16 — PU-G-158 : le panneau n'emploie ni « gabarit GSD », ni « Goal », ni « Depends on », ni « toléré », ni « ignoré » ; il dit « Lu malgré une petite différence » et « Non lu — à corriger »" "$(xr3 '/gabarit GSD|Goal|Depends on|toléré|ignoré/.test(j.texteSection)')|$(xr3 '/Lu malgré une petite différence/.test(j.texteSection)')|$(xr3 '/Non lu — à corriger/.test(j.texteSection)')" "false|true|true"
assert_eq "R3.17 — PU-G-152 : la liste « Lignes du planning non lues » a 4 lignes ; chaque chemin:numéro tient sur sa ligne en petit, le texte vient dessous en (presque) pleine largeur, et le dernier segment (« ROADMAP.md:23 ») n'est jamais coupé, sans défilement horizontal" "$(xr3 'j.listeTitre')|$(xr3 'j.nbRefs')|$(xr3 'j.refSurUneLigne')|$(xr3 'j.texteApresRef')|$(xr3 'j.largeurTexte>=j.largeurPanneau-70')|$(xr3 'j.debordeH')|$(xr3 'j.dernierSegmentUneLigne')" "Lignes du planning non lues 4|4|true|true|true|false|true"
node "$AUX/q.mjs" "$SCRIPTS" project "$LR3" > "$WORK/g-r3c.json"
assert_eq "R3.18 — PU-G-153 / Q14 : le bouton Copier donne au presse-papiers EXACTEMENT la commande affichée, qui est celle de la donnée (une seule source) ; le bouton dit « Copié » ensuite" "$(xr3 'j.copieCommande===j.commande&&j.commande===j.commandeBouton&&j.commande.length>60')|$([ "$(xr3 'j.copieCommande')" = "$(G "$WORK/g-r3c.json" 'j.meta.vf.drift.commande')" ] && echo meme)|$(xr3 'j.etatBouton')" "true|meme|Copié"
assert_eq "R3.19 — PU-G-154 : un clic sur une ligne non lue copie « fichier:ligne » tel qu'affiché et dit « Copié » (deux copies au total : la commande, puis la ligne)" "$(xr3 'j.copieRef===j.refAffichee&&/ROADMAP\.md:\d+$/.test(j.copieRef)')|$(xr3 'j.etatRef')|$(xr3 'j.nbCopies')" "true|Copié|2"
assert_eq "R3.20 — DG-15 : le bloc Santé existe dans la page (témoin positif : 1) mais est masqué dans l'onglet Projet : aucun « Aucun problème trouvé » ne côtoie les lignes non lues" "$(xr3 'j.santeDansDom')|$(xr3 'j.sante')" "1|false"
# PU-G-160 : un lab CONFORME montre quand même la section (« Conforme · 0 ligne non comprise ») et y signale le groupe « Hors jalon »
mkdir -p "$WORK/lab-r3d/src"; LR3D="$WORK/lab-r3d"; cp -R "$WORK/r3/.planning" "$LR3D/.planning"; printf '%s\n' '# Roadmap' '' '## Milestones' '' '- 🚧 **v1.0 Démo** - Phases 1-2 (in progress)' '' '## Phases' '' '- [x] **Phase 1: Socle** - a' '- [ ] **Phase 2: Écran** - b' '- [ ] **Phase 3: Orpheline** - c' '' '### Phase 1: Socle' '**Goal**: g1' '' '### Phase 2: Écran' '**Goal**: g2' '**Depends on**: Phase 1' > "$LR3D/.planning/ROADMAP.md"; printf '%s\n' '- [ ] **AUTH-01**: ok' > "$LR3D/.planning/REQUIREMENTS.md"
printf 'export const u = () => 1;\n' > "$LR3D/src/util.js"; git -C "$LR3D" init -q && git -C "$LR3D" add -A && git -C "$LR3D" -c user.email=t@t -c user.name=t commit -q -m init; LABS4+=("$LR3D")
UR3D="$(adr4 "$LR3D")"; SRVPIDS+=("$(pid4 "$LR3D")"); PR3D="${UR3D%index.html}project.html"
XR3D="$(node "$AUX/format.mjs" "$CHROME" "$SCRIPTS/tests/chrome-session.mjs" "$PR3D")"
[ -n "${DBG:-}" ] && echo "RAWR3D: $XR3D"
xr3d() { printf '%s' "$XR3D" | node "$AUX/get.mjs" /dev/stdin "$1"; }
assert_eq "R3.21 — PU-G-160 : lab conforme -> la section est affichée : « Conforme · 0 ligne non comprise », sans écart en tête, sans commande" "$(xr3d 'j.section')|$(xr3d 'j.titre')|$(xr3d '/Conforme · 0 ligne non comprise/.test(j.texteSection)')|$(xr3d 'j.alerte===""&&j.commande===""')" "true|Format de la planification|true|true"
assert_eq "R3.22 — PU-G-160 : le groupe « Hors jalon » (phase 3, aucun jalon ne la cite) est signalé dans la section, même quand le lab est conforme" "$(xr3d '/Hors jalon 1 phase ne figure dans aucun jalon du ROADMAP/.test(j.texteSection)')|$(xr3d 'j.santeDansDom')|$(xr3d 'j.sante')" "true|1|false"
unset VF_COCKPIT_PORT_BASE
for L in "${LABS4[@]}"; do node "$SCRIPTS/vf-cockpit.mjs" stop --lab "$L" >/dev/null 2>&1; done; for p in "${SRVPIDS[@]}"; do vf_hyg_stop "$p"; done; SRVPIDS=()
vf_hyg_assert

bilan
