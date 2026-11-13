#!/usr/bin/env bash
# test-cockpit-responsive.sh — CKPT-12 (P67-D-21) : la fenêtre du cockpit est ajustable, de 1 024 à 2 560 px, sans superposition ni rognage.
#   R1 chargement à 1 024 / 1 280 / 1 440 / 1 920 / 2 560 px · R2 redimensionnement à chaud 1 920 -> 1 024 -> 1 920 · R3 rendu non cassé à 800 et 390 px
#   R4 témoin rouge : le même lab sans la mise en page du cockpit rougit · R5 lab sans STATE.md : aucun champ vide dans le sous-titre ni le panneau
#   R13 à R16 (70-04, Phase 70) : téléphone — en-tête sur une rangée avec menu « ⋯ », onglets à 13 px / rail à 4 px, zoom, tiroir, titre de la vue d'ensemble (voir le bloc en fin de suite)
#   R17 à R20 (70-12, Phase 70 ; P70-D-20) : onglet Équipe — R17 zoom en rangée en bas à gauche dès 701 px (Code et Projet inchangés), R18 fil d'Ariane / recherche, R19 titre / première carte, R20 page Équipe dans la matrice
# Deux onglets (Code, Projet) × deux labs (nom court, nom de 60 caractères), badge « au travail » rempli : une session active par lab (P69-D-33 : le badge ne compte que les agents ;
# un verrou ou un nœud de DAG ne suffisent plus). R7.5 : un lab sans agent actif, badge « Personne ».
# Mesure : getBoundingClientRect dans un Chrome headless (chrome-responsive.mjs) — recouvrement des éléments frères, scrollWidth > clientWidth,
# recherche >= 200 px, logo >= 20x18 sans filtre, barre de question sur une ligne avec son invite entière.
# Durée (P70-D-18, mesurée par date +%s, poste chargé, load average 15) : 256 s avant, 74 s après — mêmes 191 libellés. Les mesures indépendantes (un Chrome chacune, profil jetable distinct) partent en même temps
# et les assertions se lisent ensuite dans l'ordre d'origine ; le fil d'Ariane (O2b) attend l'état posé de la page (géométrie identique sur deux images), plus une durée fixe de 500 ms.
# Sans navigateur : la suite se déclare SAUTÉE (exit 0, message explicite) — jamais un vert à vide. Exit 0 si tout passe.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
ENG="$SCRIPTS/../skills/cockpit-moteur"
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi; done
if [ -z "$CHROME" ]; then . "$(dirname "$0")/chrome-saut.sh"; vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur (Chrome, Chromium) — CKPT-12 NON vérifié, non compté comme réussi"; exit 0; fi
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude/scripts"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
. "$(dirname "$0")/socle-serveur.sh"
PASS=0; FAIL=0
# Moteur de questions : sans `claude` sur le PATH du serveur, la barre de question porte l'avis « no_engine » et mesure 56 à 75 px de plus (CI Linux, run 42486502412, R14.4 et R17.2 :
# 376 au lieu de 432 à 800 px, 256 au lieu de 312 à 768 px, 587 au lieu de 662 à 1 024 px ; reproduit sous macOS en retirant `claude` du PATH). Les positions absolues de la suite sont celles de la barre
# SANS avis (92 px, 40 px à 1 024 px) : le serveur reçoit donc un faux `claude` (le témoin du moteur, comme test-cockpit-moteur-carte.sh), identique sur le poste d'un dev et en CI.
# Le cas sans moteur a son propre bloc (R25, en fin de suite) : le zoom se pose 8 px au-dessus de la barre TELLE QU'ELLE EST.
FAUXBIN="$WORK/fauxbin"; mkdir -p "$FAUXBIN"; cp "$(dirname "$0")/temoins/fauxbin-claude/claude" "$FAUXBIN/claude"; chmod +x "$FAUXBIN/claude"; PATH_AVEC_MOTEUR="$FAUXBIN:$PATH"; export PATH="$PATH_AVEC_MOTEUR"
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [${2:0:600}]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [${2:0:600}]"; FAIL=$((FAIL+1)); fi; }

cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
# violations d'une clé de mesure (une ligne par violation, « - » si aucune) ; la mesure elle-même doit exister
cat > "$AUX/viol.mjs" <<'JS'
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); const m = j.mesures?.[process.argv[2]];
if (!m) { console.log('mesure absente : ' + (j.erreur || process.argv[2])); process.exit(0); }
const bas = /bas/.test(process.argv[3] || ''); // sous 1 000 px le panneau est un tiroir fermé : seul l'en-tête et la barre de question sont mesurés
const equipe = /equipe/.test(process.argv[3] || ''); // 70-12 : l'onglet Équipe n'a pas de barre de question (« equipe » ou « equipe-bas »)
// P78-D-39 (amende P70-D-16, arbitrage Samuel, AskUserQuestion session principale, 2026-11-06) : seul le drapeau « git » (lab avec Git, donc ouvreur posé) abaisse le plancher de la recherche
// à 152 px, et seulement de 1 000 à 1 279 px (dernière largeur de la clé : « 1024 », « resize:1920:1024 »). Sans drapeau, ou hors de cette plage, le minimum reste 200 px, à l'identique.
const larg = Number((String(process.argv[2]).match(/(\d+)$/) || [])[1]), git = /git/.test(process.argv[3] || '');
const garde = (x) => { const r = /^recherche : (\d+) px, minimum 200$/.exec(x); return !(git && larg >= 1000 && larg <= 1279 && r && Number(r[1]) >= 152); };
const plein = m.m.enteteElements >= (bas ? 3 : 6) && (bas || /#panel/.test(m.m.surfaces || '')) && (equipe || /#ask/.test(m.m.surfaces || ''));
console.log(!plein ? 'mesure vide : ' + JSON.stringify(m.m) : m.v.filter(garde).length ? m.v.filter(garde).slice(0, 4).join(' | ') : 'aucune');
JS
# faux verrou de driver (HOME jetable) : un propriétaire au nom long, comme en vraie mission
cat > "$HOME/.claude/scripts/driver-lock.sh" <<'SH'
#!/usr/bin/env bash
case "$1" in
  status) echo '{"present": true, "scope": "lab", "location": "git-common-dir", "legacy_lock": false, "locks": [{"present": true, "owner": "vf-dev-manager-v2-cockpit", "step": "mission", "age_seconds": 135, "ttl": 1800, "stale": false, "generation": "g1", "session_ids": [], "lease_seconds": 5, "guard_effective": false, "progress_epoch": null, "progress_age_seconds": null, "children_running": 1, "scope": "depot", "ws": "", "location": "git-common-dir"}], "children_running": 1}' ;;
  orphans) echo '{"orphans":[]}' ;;
esac
SH
NSESS=0
agent_actif() { # agent_actif <lab> : une session Claude Code récente de ce lab (forme réelle) : un agent actif, que le badge compte ; sa date est rafraîchie tant que la suite vit (fraîcheur de 3 minutes)
  local L="$1"
  local SID D TS; NSESS=$((NSESS+1)); SID="aaaa1111-2222-3333-4444-$(printf '%012d' "$NSESS")"; D="$HOME/.claude/projects/-lab-$NSESS"; TS="$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"; mkdir -p "$D"
    printf '{"type":"user","cwd":"%s","sessionId":"%s","gitBranch":"main","version":"2.1.317","timestamp":"%s","message":{"content":"salut"}}\n{"type":"assistant","cwd":"%s","sessionId":"%s","gitBranch":"main","version":"2.1.317","timestamp":"%s","message":{"content":[{"type":"text","text":"bonjour"}]}}\n' "$L" "$SID" "$TS" "$L" "$SID" "$TS" > "$D/$SID.jsonl"
    ( while kill -0 $$ 2>/dev/null; do touch "$D/$SID.jsonl"; sleep 10; done ) </dev/null >/dev/null 2>&1 &
}
mklab() { # mklab <dir> [sans-agent] [sans-git] : lab GSD sans STATE.md, deux phases, un DAG de mission avec un nœud en cours, une session active (sauf sans-agent)
  local L="$1" B="$1/.planning"; mkdir -p "$L/src" "$B/phases/01-socle" "$B/phases/02-suite" "$B/missions"
  printf 'export const u = () => 1;\n' > "$L/src/util.js"
  printf '# Roadmap\n\n## Jalon démo\n\n- [x] **Phase 1: Socle** - premier jet\n- [ ] **Phase 2: Suite** - la suite\n' > "$B/ROADMAP.md"
  printf '<objective>Faire le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"; echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
  printf '<objective>Faire la suite</objective>\n' > "$B/phases/02-suite/02-01-PLAN.md"
  printf '{"nodes":[{"id":"a","step":"première étape","stage":"","deps":[],"scope":["src/**"],"status":"done"},{"id":"b","step":"seconde étape","stage":"","deps":["a"],"scope":["src/**"],"status":"running"}]}\n' > "$B/missions/demo.dag.json"
  [ "${2:-}" = sans-agent ] || agent_actif "$L"
  [ "${3:-}" = sans-git ] || { git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init; } # sans-git (P78-D-39) : un dossier qui n'est pas un dépôt
  node "$SCRIPTS/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/build-$(basename "$L").out" 2>&1 || cat "$WORK/build-$(basename "$L").out"
}
# le serveur reçoit les scripts par un lien nommé autrement que « scripts » : pas de conductor voisin, le faux driver-lock.sh de HOME répond (v1.1.1 : le conductor voisin passe avant)
SCRIPTS_HOTE="$WORK/scripts-hote"; ln -s "$SCRIPTS" "$SCRIPTS_HOTE"
srv() { # srv <sortie> -> SRV_PORT SRV_PID
  local o="$1" lab; lab="$(cd "$1/../.." && pwd)"
  COCKPIT_SORTIE="$o" cockpit_lancer "$lab" VF_COCKPIT_ENGINE_DIR="$ENG" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS_HOTE"
  SRV_PID="${VF_PID:-}"; SRV_PORT="${VF_PORT:-0}"
}
unsrv() { vf_hyg_stop "$SRV_PID"; }
mes() { REAL_HOME="$REAL_HOME" node "$HERE_T/chrome-responsive.mjs" "$CHROME" "$@"; } # mes <url> <largeurs> <resize|-> [<captures>]
LARGES="1024,1280,1440,1920,2560"
# boutons d'en-tête OPTIONNELS de l'onglet Code (Travail récent et Écrans n'existent que si le lab a un historique récent et des pages) : ajoutés par l'API
# d'extension du viewer, avec leur libellé et leur icône d'origine, pour mesurer le pire en-tête réel — sans eux R-1 (bouton rogné à 1 024 px) restait invisible
INJ_CODE="(() => { const SC = window.VibeFlow; SC.addHeaderButton({ id: 'btn-recent', label: 'Recent work', icon: 'recent', title: 'What was just worked on, on one board', onClick() {} }); SC.addHeaderButton({ id: 'screens-btn', label: 'Screens', icon: 'ui', title: 'Pick a screen of the app', onClick() {} }); return true; })()"

LC="$WORK/lab-court"; mklab "$LC"
LS="$WORK/lab-sans-git"; mklab "$LS" "" sans-git # P78-D-39 : un lab sans Git à 1 024 px
LL="$WORK/vibeflow-os-un-nom-de-projet-vraiment-tres-long-pour-tester"; mklab "$LL"
echo "=== R1, R2 — chargement et redimensionnement à chaud : deux onglets, deux labs ==="
# P70-D-18 : les deux labs sont servis d'emblée et leurs six mesures (R1/R2 : quatre, R3 : deux) partent en même temps, un Chrome chacune ; les assertions se lisent ensuite, dans l'ordre d'origine
srv "$LC/.vibeflow/cockpit"; P_court=$SRV_PORT; PID_court=$SRV_PID
srv "$LL/.vibeflow/cockpit"; P_long=$SRV_PORT; PID_long=$SRV_PID
MPIDS=()
for nom in court long; do
  eval "P=\$P_$nom"
  for onglet in index project; do
    inj=""; [ "$onglet" = index ] && inj="$INJ_CODE"
    RESP_INJECT="$inj" mes "http://127.0.0.1:$P/$onglet.html" "$LARGES" 1920:1024 ${SHOTS:+"$SHOTS/$nom-$onglet"} > "$WORK/mes-$nom-$onglet.json" & MPIDS+=($!)
    if [ "$nom" = court ]; then mes "http://127.0.0.1:$P/$onglet.html" 800,390 - > "$WORK/mes3-$onglet.json" & MPIDS+=($!); fi
  done
done
wait "${MPIDS[@]}"
for nom in court long; do
  eval "P=\$P_$nom"
  assert_eq "0 — serveur du lab « $nom » démarré" "$([ "$P" -gt 0 ] && echo oui || echo non)" "oui"
  for onglet in index project; do
    R="$(cat "$WORK/mes-$nom-$onglet.json")"
    for w in ${LARGES//,/ }; do assert_eq "R1 — $nom / $onglet / $w px : aucune superposition, aucun rognage" "$(printf '%s' "$R" | node "$AUX/viol.mjs" "$w" git)" "aucune"; done
    assert_eq "R2 — $nom / $onglet : 1 920 -> 1 024 à chaud" "$(printf '%s' "$R" | node "$AUX/viol.mjs" "resize:1920:1024" git)" "aucune"
    assert_eq "R2 — $nom / $onglet : 1 024 -> 1 920 à chaud (retour)" "$(printf '%s' "$R" | node "$AUX/viol.mjs" "resize:1024:1920" git)" "aucune"
  done
  if [ "$nom" = court ]; then
    echo "=== R3 — en dessous de 1 024 px : rendu non cassé (800 et 390 px) ==="
    for onglet in index project; do
      R="$(cat "$WORK/mes3-$onglet.json")"
      for w in 800 390; do assert_eq "R3 — $onglet / $w px : aucune superposition d'en-tête, aucun défilement horizontal" "$(printf '%s' "$R" | node "$AUX/viol.mjs" "$w" bas)" "aucune"; done
    done
  fi
done
SRV_PID=$PID_court; unsrv; SRV_PID=$PID_long; unsrv
echo "=== R5, R6 — lab sans STATE.md : aucun champ vide ; titre de l'onglet ; traduction avant la peinture ==="
srv "$LC/.vibeflow/cockpit"; PC=$SRV_PORT
EXPR='({ titre: document.title, ctx: (document.getElementById("context")||{}).innerText||"", panneau: (document.getElementById("panel")||{}).innerText||"" })'
XP="$(node "$HERE_T/chrome-cdp.mjs" "$CHROME" 2000 "$EXPR" "http://127.0.0.1:$PC/project.html" "http://127.0.0.1:$PC/index.html")"
assert_eq "R5.1 — sous-titre du projet sans « ? » ni parenthèses vides" "$(printf '%s' "$XP" | node "$AUX/ev.mjs" '/[?]|[(][)]/.test(j.resultats[0].valeur.ctx)')" "false"
assert_eq "R5.2 — panneau d'ensemble sans bloc « Maintenant » ni « Phase — »" "$(printf '%s' "$XP" | node "$AUX/ev.mjs" '/Maintenant|Phase —/.test(j.resultats[0].valeur.panneau)')" "false"
assert_has "R5.3 — témoin : le panneau montre bien les effectifs du lab" "$(printf '%s' "$XP" | node "$AUX/ev.mjs" 'j.resultats[0].valeur.panneau')" "phases"
assert_eq "R6.1 — titre de l'onglet Projet : « Projet · <nom> » (format unique, AUDC-X7)" "$(printf '%s' "$XP" | node "$AUX/ev.mjs" 'j.resultats[0].valeur.titre')" "Projet · lab-court"
assert_eq "R6.2 — titre de l'onglet Code : « Code · <nom> » (format unique, AUDC-X7)" "$(printf '%s' "$XP" | node "$AUX/ev.mjs" 'j.resultats[1].valeur.titre')" "Code · lab-court"
# R6.3 (79-10, amendement daté 2026-11-13, rv-1021) : le texte est inséré dans le DOM par le CHEMIN D'ÉMISSION RÉEL (une question posée dans le tiroir : submitAsk écrit « Thinking… » dans la feuille
# avant le premier await), puis lu : français affiché. Lecture unique (garde window.__r63) : le relevé est répété jusqu'à stabilité, et une seconde soumission annulerait la première.
EXPR63='(() => { if (window.__r63) return window.__r63; const i = document.querySelector("#ask-input"); i.value = "Combien de fichiers ?"; document.querySelector("#ask-form").requestSubmit(); const t = document.querySelector("#ask-sheet").innerText; return (window.__r63 = { fr: /Réflexion…/.test(t), en: /Thinking…/.test(t) }); })()'
PRET63='document.readyState === "complete" && !!document.querySelector("header .brand .mark") && !document.querySelector("#ask-send").disabled' # le moteur de questions est détecté (faux claude du PATH)
XT="$(CDP_PRET="$PRET63" node "$HERE_T/chrome-cdp.mjs" "$CHROME" 500 "$EXPR63" "http://127.0.0.1:$PC/project.html")"; unsrv
assert_eq "R6.3 — « Thinking… » écrit par le chemin d'émission réel (question posée dans le tiroir) est montré en français, jamais en anglais (79-10)" "$(printf '%s' "$XT" | node "$AUX/ev.mjs" 'JSON.stringify(j.resultats[0].valeur)')" '{"fr":true,"en":false}'
# mutant (dans la suite) : la même page dont l'émission contourne le traducteur (« [t('Thinking…')] » devient « ['Thinking…'] ») : R6.3 doit rougir, c'est-à-dire lire l'anglais
LM="$WORK/lab-mutant63"; mkdir -p "$LM"; ( cd "$LC" && tar -cf - . ) | ( cd "$LM" && tar -xf - )
sed "s/\[t('Thinking…')\]/['Thinking…']/g" "$LC/.vibeflow/cockpit/project.html" > "$LM/.vibeflow/cockpit/project.html"
MUT_N="$(grep -c "\['Thinking…'\]" "$LM/.vibeflow/cockpit/project.html")"
srv "$LM/.vibeflow/cockpit"; PM=$SRV_PORT
XM="$(CDP_PRET="$PRET63" node "$HERE_T/chrome-cdp.mjs" "$CHROME" 500 "$EXPR63" "http://127.0.0.1:$PM/project.html")"; unsrv
assert_eq "R6.3 mutant — avec l'émission qui contourne le traducteur ($MUT_N sites mutés), la même sonde lit « Thinking… » et non « Réflexion… » (la sonde sait voir l'anglais)" "$([ "$MUT_N" -ge 1 ] && printf '%s' "$XM" | node "$AUX/ev.mjs" 'JSON.stringify(j.resultats[0].valeur)' || echo "mutation sans effet")" '{"fr":false,"en":true}'

# O2 (recette 3, arbitrage Samuel, AskUserQuestion session principale, 2026-11-03) : un fil d'Ariane profond (Vue d'ensemble / Historique / Phases) à 1 280 et 1 440 px.
# Un segment de moins de 12 caractères n'est jamais rogné (scrollWidth <= clientWidth) ; si une troncature est nécessaire, elle porte sur un segment du MILIEU, jamais le premier ni le dernier.
echo "=== O2 — fil d'Ariane profond : aucun segment court rogné, troncature au milieu d'abord (1 280 et 1 440 px, labs court et long) ==="
cat > "$AUX/o2.js" <<'JS'
(async () => { const SC = window.VibeFlow, pause = (ms) => new Promise((r) => setTimeout(r, ms));
  SC.reveal('n:ph-1');
  for (let i = 0; i < 100; i++) { const b = [...document.querySelectorAll('#crumbs button')]; if (b.length === 3 && b[0].textContent === "Vue d'ensemble") break; await pause(50); }
  await pause(400);
  const b = [...document.querySelectorAll('#crumbs button')];
  return { seg: b.map((e, i) => ({ t: e.textContent, n: e.textContent.trim().length, i, rogne: e.scrollWidth > e.clientWidth + 1, sw: e.scrollWidth, cw: e.clientWidth })), nb: b.length, W: innerWidth,
    entete: [...document.querySelectorAll('header button, header a, header input')].filter((e) => { const r = e.getBoundingClientRect(); return r.width > 0 && (r.right > innerWidth + 0.5 || r.left < -0.5); }).length }; })()
JS
# deux labs dont le jalon est clos : le projet range ses phases sous « Historique », d'où un fil de trois segments (Vue d'ensemble / Historique / Phases)
mkdir -p "$WORK/deep-court" "$WORK/deep-long"; LDC="$WORK/deep-court/lab-court"; LDL="$WORK/deep-long/vibeflow-os-un-nom-de-projet-vraiment-tres-long-pour-tester"; mklab "$LDC"; mklab "$LDL"
for d in "$LDC" "$LDL"; do printf '# Roadmap\n\n## Jalon démo\n\n- [x] **Phase 1: Socle** - premier jet\n- [x] **Phase 2: Suite** - la suite\n' > "$d/.planning/ROADMAP.md"; node "$SCRIPTS/vf-cockpit-build.mjs" "$d" --quiet > "$WORK/build-deep.out" 2>&1 || cat "$WORK/build-deep.out"; done
for spec in "court:$LDC" "long:$LDL"; do
  nom="${spec%%:*}"; lab="${spec#*:}"; srv "$lab/.vibeflow/cockpit"; PO=$SRV_PORT
  for w in 1280x800 1440x900; do
    XO2="$(CDP_VIEWPORT=$w node "$HERE_T/chrome-cdp.mjs" "$CHROME" 300 "$(cat "$AUX/o2.js")" "http://127.0.0.1:$PO/project.html")"
    V2='j.resultats[0].valeur'
    assert_eq "O2.0 — $nom / $w : témoin, trois segments mesurés, aucun bouton d'en-tête hors de la fenêtre" "$(printf '%s' "$XO2" | node "$AUX/ev.mjs" "($V2.erreur||j.erreur||'')+'|'+$V2.nb+'|'+$V2.entete")" "|3|0"
    assert_eq "O2.1 — $nom / $w : aucun segment de moins de 12 caractères n'est rogné" "$(printf '%s' "$XO2" | node "$AUX/ev.mjs" "$V2.seg.filter((x)=>x.n<12&&x.rogne).map((x)=>x.t+' '+x.sw+'>'+x.cw).join(' | ')||'aucun'")" "aucun"
    assert_eq "O2.2 — $nom / $w : aucune troncature sur le premier ni le dernier segment" "$(printf '%s' "$XO2" | node "$AUX/ev.mjs" "$V2.seg.filter((x)=>x.rogne&&(x.i===0||x.i===$V2.seg.length-1)).map((x)=>x.t+' '+x.sw+'>'+x.cw).join(' | ')||'aucun'")" "aucun"
  done
  unsrv
done

# O2b (revue de la recette 3, F1/F2, arbitrage Samuel, AskUserQuestion session principale, 2026-11-03) : le budget du fil d'Ariane tient compte de la colonne de droite (badge « au travail » compris) et du plancher
# de la recherche. Noms de module réalistes de 15 à 21 caractères, fil de 3 puis de 6 segments dont 2 courts (moins de 12 caractères), onglets Code (avec ses boutons optionnels) ET Projet, badge présent,
# à 1 280, 1 300, 1 320 et 1 440 px. Quatre mesures : aucun bouton d'en-tête hors fenêtre (header.scrollWidth <= innerWidth), aucun segment court rogné, le fil reste dans sa colonne (ni hors de .hl, ni sur la
# recherche), et la troncature porte d'abord sur le milieu (le premier et le dernier ne sont rognés que lorsque les segments longs du milieu sont à leur plancher de 64 px).
cat > "$AUX/o2b.js" <<'JS'
(async () => { const pause = (ms) => new Promise((r) => setTimeout(r, ms)), SC = window.VibeFlow;
  if (location.pathname.endsWith('index.html') && !document.getElementById('btn-recent')) { SC.addHeaderButton({ id: 'btn-recent', label: 'Recent work', icon: 'recent', title: 'What was just worked on, on one board', onClick() {} }); SC.addHeaderButton({ id: 'screens-btn', label: 'Screens', icon: 'ui', title: 'Pick a screen of the app', onClick() {} }); }
  for (let i = 0; i < 100 && !/travail|Personne/.test((document.getElementById('vf-lock') || {}).textContent || ''); i++) await pause(50);
  // pose : la mise en page est posée quand deux images consécutives donnent la même géométrie (fil, en-tête, recherche) — l'état de la page, jamais une durée fixe (P70-D-18 : remplace pause(500))
  const sig = () => [...document.getElementById('crumbs').children].map((e) => { const r = e.getBoundingClientRect(); return e.tagName + e.textContent.length + ':' + r.left + ',' + r.width + ',' + (e.hasAttribute('data-vf-masque') ? 1 : 0); }).join('|') + '|' + document.querySelector('header').scrollWidth + '|' + document.getElementById('search-btn').getBoundingClientRect().left;
  const image = () => new Promise((r) => requestAnimationFrame(() => r()));
  const pose = async () => { let prec = sig(); for (let i = 0; i < 100; i++) { await image(); await image(); const c = sig(); if (c === prec) return; prec = c; } };
  const fil = document.getElementById('crumbs'), proto = fil.querySelector('button'), sep0 = fil.querySelector('.sep') || Object.assign(document.createElement('span'), { className: 'sep', textContent: '/' });
  const jeux = { s3: ["Vue d'ensemble", 'dev-orchestrator', 'design-orchestrator'], s6: ["Vue d'ensemble", 'conductor-references', 'db', 'planning-core-lib', 'src', 'dev-orchestrator-refs'], s8: ["Vue d'ensemble", 'conductor-references', 'planning-core-lib', 'dev-orchestrator-refs', 'design-orchestrator', 'cockpit-moteur-assets', 'skills-references', 'last-segment-name-long'] }, out = { W: innerWidth };
  for (const [cle, segs] of Object.entries(jeux)) {
    fil.innerHTML = ''; segs.forEach((t, i) => { if (i) fil.appendChild(sep0.cloneNode(true)); const b = proto.cloneNode(false); b.textContent = t; b.className = i === segs.length - 1 ? 'cur' : ''; b.removeAttribute('data-vf-court'); b.removeAttribute('data-vf-masque'); fil.appendChild(b); });
    await pose();
    const hd = document.querySelector('header'), R = (e) => e.getBoundingClientRect(), vis = (e) => R(e).width > 0;
    const bs = [...fil.querySelectorAll('button')].filter(vis), n = bs.length, hl = R(document.querySelector('header .hl')), sb = R(document.getElementById('search-btn')), cr = R(fil);
    const pn = document.getElementById('proj-name');
    const ellE = fil.querySelector('.vf-ell'), masques = [...fil.querySelectorAll('button[data-vf-masque]')].map((e) => e.textContent.trim());
    out[cle] = { repli: { ell: !!ellE, title: ellE ? ellE.getAttribute('title') : null, aria: ellE ? ellE.getAttribute('aria-label') : null, masquesNoms: masques.join(' / '), premier: n ? bs[0].textContent : null, dernier: n ? bs[n - 1].textContent : null, dernierR: n ? Math.round(R(bs[n - 1]).right * 10) / 10 : null, filR: Math.round(cr.right * 10) / 10, attPremier: segs[0], attDernier: segs[segs.length - 1] }, pn: [pn.scrollWidth, pn.clientWidth], lock: !!document.getElementById('vf-lock'), nbVisibles: n, nbMasques: fil.querySelectorAll('button[data-vf-masque]').length, ell: !!fil.querySelector('.vf-ell'), hdrSW: hd.scrollWidth,
      dehors: [...hd.querySelectorAll('button, a, input')].filter((e) => vis(e) && (R(e).right > innerWidth + 0.5 || R(e).left < -0.5)).map((e) => e.id || e.textContent.trim().slice(0, 12)),
      courts: bs.filter((e) => e.textContent.trim().length < 12 && e.scrollWidth > e.clientWidth + 1).map((e) => e.textContent + ' ' + e.scrollWidth + '>' + e.clientWidth),
      fil: { dansHl: cr.right <= hl.right + 0.5, surRecherche: cr.right > sb.left + 0.5, crR: Math.round(cr.right), hlR: Math.round(hl.right), sbL: Math.round(sb.left) },
      deficit: bs.map((e, i) => ({ t: e.textContent, i, d: Math.max(0, e.scrollWidth - e.clientWidth), cw: e.clientWidth, milieu: i > 0 && i < n - 1 && e.textContent.trim().length >= 12, bout: (i === 0 || i === n - 1) && e.textContent.trim().length >= 12 })) };
  }
  return out; })()
JS
cat > "$AUX/o2b-viol.mjs" <<'JS'
// usage : o2b-viol.mjs <nature> <jeu s3|s6> <étiquette-par-url, séparées par une virgule> ; lit le JSON de chrome-cdp.mjs sur l'entrée ; « aucune » si tout va bien, sinon les violations
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); const [nat, jeu, etiq] = process.argv.slice(2), noms = (etiq || '').split(',');
if (!j.resultats) { console.log('mesure absente : ' + (j.erreur || '?')); process.exit(0); }
const v = [];
j.resultats.forEach((r, i) => { const x = r.valeur?.[jeu], w = r.valeur?.W, et = (noms[i] || i) + ' ' + w + ' px';
  if (!x) { v.push(et + ' : mesure absente'); return; }
  if (!x.lock) v.push(et + ' : témoin, badge « au travail » absent');
  if (x.nbVisibles + 0 < 2) v.push(et + ' : témoin, fil de moins de 2 segments visibles');
  if (nat === 'hors' && (x.dehors.length || x.hdrSW > w)) v.push(et + ' : hors fenêtre [' + x.dehors.join(',') + '] header.scrollWidth ' + x.hdrSW + ' > ' + w);
  if (nat === 'court' && x.courts.length) v.push(et + ' : segment court rogné ' + x.courts.join(', '));
  if (nat === 'fil' && (!x.fil.dansHl || x.fil.surRecherche)) v.push(et + ' : fil hors de sa colonne (fil.right ' + x.fil.crR + ', .hl.right ' + x.fil.hlR + ', recherche.left ' + x.fil.sbL + ')');
  if (nat === 'ordre') { const bout = x.deficit.filter((d) => d.bout && d.d > 1), mil = x.deficit.filter((d) => d.milieu && d.cw > 65); if (bout.length && mil.length) v.push(et + ' : un bout est tronqué (' + bout.map((d) => d.t + ' -' + d.d).join(', ') + ') alors qu\'un segment du milieu garde plus de 64 px (' + mil.map((d) => d.t + ' ' + d.cw).join(', ') + ')'); }
  if (nat === 'plainte') { const t = x.deficit.filter((d) => d.d > 1).map((d) => d.t + ' -' + d.d); if (x.pn[0] > x.pn[1]) t.push('nom du projet ' + x.pn[0] + '>' + x.pn[1]); if (t.length) v.push(et + ' : ' + t.join(', ')); }
  if (nat === 'repli') { const r = x.repli, p = [];
    if (!r.ell) p.push('repli « … » absent'); if (!(x.nbMasques > 0)) p.push('aucun segment masqué (' + x.nbMasques + ')');
    if (!(r.dernierR <= r.filR + 0.5) || r.dernier !== r.attDernier) p.push('dernier segment « ' + r.dernier + ' » hors de la colonne du fil (right ' + r.dernierR + ' > fil.right ' + r.filR + ')');
    if (r.premier !== r.attPremier) p.push('premier segment non visible (' + r.premier + ')');
    if (!r.masquesNoms || r.title !== r.masquesNoms) p.push('title du « … » [' + r.title + '] != noms masqués [' + r.masquesNoms + ']');
    if (!r.aria || r.aria !== r.title) p.push('aria-label du « … » [' + r.aria + '] != title [' + r.title + ']');
    if (p.length) v.push(et + ' : ' + p.join(' ; ')); }
  if (nat === 'sollicite' && !(x.nbMasques > 0 || x.deficit.some((d) => d.d > 0))) v.push(et + ' : témoin, aucune troncature ni masquage sollicité');
});
console.log(v.length ? v.slice(0, 4).join(' | ') : 'aucune');
JS
O2B_U="index.html project.html"
o2b_mesure() { # o2b_mesure <port> <largeur> -> JSON (onglet Code puis Projet)
  CDP_VIEWPORT="$2x$(( $2 * 5 / 8 ))" CDP_PRET="document.readyState === 'complete' && !!document.querySelector('#crumbs button') && !!document.getElementById('vf-lock')" node "$HERE_T/chrome-cdp.mjs" "$CHROME" 300 "$(cat "$AUX/o2b.js")" "http://127.0.0.1:$1/index.html" "http://127.0.0.1:$1/project.html"
}
echo "=== O2b — budget du fil d'Ariane (revue de la recette 3, F1/F2) : fils de 3 et 6 segments longs, badge présent, 1 280 / 1 300 / 1 320 / 1 440 px, onglets Code et Projet ==="
for spec in "court:$LC" "long:$LL"; do
  nom="${spec%%:*}"; lab="${spec#*:}"; srv "$lab/.vibeflow/cockpit"; PB=$SRV_PORT
  # les cinq largeurs se mesurent en même temps (un Chrome par largeur, profils jetables distincts) ; les assertions se lisent ensuite dans l'ordre d'origine (P70-D-18)
  OPIDS=(); for w in 1280 1300 1320 1366 1440; do o2b_mesure "$PB" "$w" > "$WORK/o2b-$nom-$w.json" & OPIDS+=($!); done; wait "${OPIDS[@]}"
  for w in 1280 1300 1320 1366 1440; do
    XB="$(cat "$WORK/o2b-$nom-$w.json")"
    for jeu in s3 s6; do
      E="Code $nom,Projet $nom"; fq="$jeu"
      assert_eq "O2b.1 — $nom / $jeu / $w px : aucun bouton d'en-tête hors de la fenêtre (header.scrollWidth <= innerWidth), badge présent" "$(printf '%s' "$XB" | node "$AUX/o2b-viol.mjs" hors $jeu "$E")" "aucune"
      assert_eq "O2b.2 — $nom / $jeu / $w px : aucun segment court (moins de 12 caractères) rogné" "$(printf '%s' "$XB" | node "$AUX/o2b-viol.mjs" court $jeu "$E")" "aucune"
      assert_eq "O2b.3 — $nom / $jeu / $w px : le fil reste dans sa colonne (ni hors de .hl, ni sur la recherche)" "$(printf '%s' "$XB" | node "$AUX/o2b-viol.mjs" fil $jeu "$E")" "aucune"
      assert_eq "O2b.4 — $nom / $jeu / $w px : la troncature porte d'abord sur le milieu (le premier et le dernier ne sont rognés que lorsque les segments longs du milieu sont à leur plancher de 64 px)" "$(printf '%s' "$XB" | node "$AUX/o2b-viol.mjs" ordre $jeu "$E")" "aucune"
    done
    case "$w" in 1280|1300|1366) # O2b.7 (re-revue de la recette 3, M1/M2) : le repli « … » d'un fil de 8 segments longs : présent, segments du milieu masqués, dernier segment contenu dans la colonne du fil, premier visible, title = noms masqués, aria-label = title
      assert_eq "O2b.7 — $nom / s8 / $w px : repli « … » présent (nombre de segments masqués > 0), dernier segment dans la colonne du fil (right <= fil.right), premier visible, title et aria-label du « … » = noms masqués" "$(printf '%s' "$XB" | node "$AUX/o2b-viol.mjs" repli s8 "Code $nom,Projet $nom")" "aucune" ;;
    esac
  done
  if [ "$nom" = court ]; then assert_eq "O2b.6 — plainte d'origine, lab court / 1 440 px, fil de 3 segments : « Vue d'ensemble », le nom du projet et les autres segments ne sont plus rognés" "$(printf '%s' "$(cat "$WORK/o2b-court-1440.json")" | node "$AUX/o2b-viol.mjs" plainte s3 "Code court,Projet court")" "aucune"; fi
  XB="$(cat "$WORK/o2b-$nom-1280.json")"
  assert_eq "O2b.5 — $nom / 1 280 px : témoin, le fil de 6 segments sollicite bien la troncature ou le masquage (jamais un vert à vide)" "$(printf '%s' "$XB" | node "$AUX/o2b-viol.mjs" sollicite s6 "Code $nom,Projet $nom")" "aucune"
  unsrv
done

# O2b — témoins rouges sur COPIE du lab long (jamais le moteur) : chaque mutant défait UNE règle du budget du fil et doit rougir la mesure qui la garde, à 1 280 px (onglet Code, badge présent).
#   m1 règle des segments courts supprimée -> « segment court rogné » · m2 le min-width de 3a9331c8 (colonne gauche = 280 px + largeur du fil + nom du projet, plafond 50 %) remis -> « hors de la fenêtre »
#   m3 le milieu au même poids que les bouts (1, au lieu de 100 000 : on ne tronque plus le milieu d'abord) -> « le premier est tronqué alors que le milieu garde plus de 64 px »
mutant_o2b() { # mutant_o2b <nom> <nature> <ancien> <nouveau> : <ancien> doit exister dans la page (sinon FAIL nommé)
  local M="$WORK/mut-o2b-$1"; mkdir -p "$M/.planning/missions" "$M/.vibeflow"; cp -R "$LL/.vibeflow/cockpit" "$M/.vibeflow/cockpit"; cp "$LL/.planning/missions/demo.dag.json" "$M/.planning/missions/"
  node -e "
const fs=require('fs');let n=0;for(const f of ['index.html','project.html']){const p='$M/.vibeflow/cockpit/'+f;const h=fs.readFileSync(p,'utf8');const o=process.argv[1],r=process.argv[2];if(!h.includes(o))continue;fs.writeFileSync(p,h.split(o).join(r));n++}
if(!n){console.error('mutant $1 : motif introuvable');process.exit(1)}" "$3" "$4" || { FAIL=$((FAIL+1)); echo "  ❌ FAIL — mutant $1 : motif introuvable dans la page"; return; }
  srv "$M/.vibeflow/cockpit"; MUT_SRV+=("$SRV_PID"); MUT_ID+=("$1"); MUT_NAT+=("$2"); MUT_LIB+=("$5")
  o2b_mesure "$SRV_PORT" 1280 > "$WORK/mut-o2b-$1.json" & MUT_PIDS+=($!) # les trois mutants se mesurent en même temps ; les verdicts tombent dans l'ordre d'origine (P70-D-18)
}
MUT_SRV=(); MUT_ID=(); MUT_NAT=(); MUT_LIB=(); MUT_PIDS=()
mutants_o2b_verdicts() {
  local i XM; [ "${#MUT_PIDS[@]}" -gt 0 ] && wait "${MUT_PIDS[@]}"
  for i in "${!MUT_ID[@]}"; do
    SRV_PID="${MUT_SRV[$i]}"; unsrv; XM="$(cat "$WORK/mut-o2b-${MUT_ID[$i]}.json")"
    assert_neq_aucune "O2b.m${MUT_ID[$i]} — mutant « ${MUT_LIB[$i]} » : la mesure « ${MUT_NAT[$i]} » rougit à 1 280 px" "$(printf '%s' "$XM" | node "$AUX/o2b-viol.mjs" "${MUT_NAT[$i]}" s6 "Code mutant,Projet mutant")"
  done
}
assert_neq_aucune() { if [ "$2" != "aucune" ] && [[ "$2" != "mesure absente"* ]] && [[ "$2" != *"témoin"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: une violation de la nature visée"; echo "     obtenu:  [${2:0:600}]"; FAIL=$((FAIL+1)); fi; }
mutant_o2b 1 court 'header #crumbs button[data-vf-court] { flex: 0 0 auto; }' '' "règle des segments courts supprimée"
mutant_o2b 2 hors '@media (max-width: 999px) { #ask-input' '@media (min-width: 1280px) { :root { --vf-crumbs: 560px; --vf-pn: 100px; } header .hl { min-width: min(calc(280px + var(--vf-crumbs, 0px) + var(--vf-pn, 0px)), 50vw); } } @media (max-width: 999px) { #ask-input' "min-width de 3a9331c8 remis"
mutant_o2b 3 ordre 'button:not([data-vf-court]):not(:first-child):not(.cur) { flex: 0 100000 auto; }' 'button:not([data-vf-court]):not(:first-child):not(.cur) { flex: 0 1 auto; }' "milieu au même poids que les bouts"
mutants_o2b_verdicts

# I2 (recette 3, retour de Samuel, saisie texte, session principale, 2026-11-03) : « le flou sous le titre est trop dense, il faut aussi qu'il ai un radius fort en haut faible en bas, il doit etre comparable au blur iOS ».
# Reprise (avis de Samuel, Wispr Flow, session principale, 2026-11-03 : « pas de bordure, un flou dégradé qui part du haut gauche et descend, comme le header, en mode iOS 26 ») :
# plus de carte bordée ; le flou vit sur #context::before : backdrop-filter blur + saturate, masque en dégradé (mask-image et -webkit-mask-image), aucune bordure, aucun rayon, aucune ombre (#context et ::before) — mesuré dans le style calculé, deux thèmes, deux onglets.
echo "=== I2 — le titre de la vue d'ensemble : flou progressif à la iOS 26 (filtre, masque en dégradé, ni bordure ni rayon ni ombre) ==="
cat > "$AUX/i2.js" <<'JS'
(async () => { const pause = (ms) => new Promise((r) => setTimeout(r, ms)); const ctx = document.getElementById('context'), out = {};
  for (const th of ['light', 'dark']) { document.documentElement.setAttribute('data-theme', th); await pause(150);
    const lire = (cs) => ({ filtre: cs.backdropFilter, masque: cs.maskImage || cs.webkitMaskImage || '', bord: ['Top', 'Right', 'Bottom', 'Left'].map((c) => parseFloat(cs['border' + c + 'Width'])).reduce((a, b) => a + b, 0),
      rayon: ['TopLeft', 'TopRight', 'BottomLeft', 'BottomRight'].map((c) => parseFloat(cs['border' + c + 'Radius'])).reduce((a, b) => a + b, 0), ombre: cs.boxShadow });
    out[th] = { ctx: lire(getComputedStyle(ctx)), av: lire(getComputedStyle(ctx, '::before')), ctxFiltre: getComputedStyle(ctx).backdropFilter }; }
  return out; })()
JS
srv "$LC/.vibeflow/cockpit"; PI=$SRV_PORT
for onglet in index project; do
  XI="$(CDP_VIEWPORT=1280x800 CDP_PRET="document.readyState === 'complete' && !!document.querySelector('#context h1')" node "$HERE_T/chrome-cdp.mjs" "$CHROME" 300 "$(cat "$AUX/i2.js")" "http://127.0.0.1:$PI/$onglet.html")"
  for th in light dark; do
    VI="j.resultats[0].valeur.$th"
    assert_eq "I2.1 — $onglet / $th : flou présent sur la couche (backdrop-filter blur + saturate)" "$(printf '%s' "$XI" | node "$AUX/ev.mjs" "/^blur\\([0-9.]+px\\) saturate\\(/.test($VI.av.filtre)")" "true"
    assert_eq "I2.2 — $onglet / $th : masque en dégradé sur la couche (mask-image radial ou linéaire)" "$(printf '%s' "$XI" | node "$AUX/ev.mjs" "/gradient\\(/.test($VI.av.masque)")" "true"
    assert_eq "I2.3 — $onglet / $th : aucune bordure, aucun rayon, aucune ombre (#context et ::before) et pas de flou sur #context lui-même" "$(printf '%s' "$XI" | node "$AUX/ev.mjs" "[$VI.ctx.bord,$VI.av.bord,$VI.ctx.rayon,$VI.av.rayon,$VI.ctx.ombre,$VI.av.ombre,$VI.ctxFiltre].join('|')")" "0|0|0|0|none|none|none"
  done
done
unsrv

echo "=== R4 — témoin rouge : sans la mise en page du cockpit, la mesure rougit ==="
LM="$WORK/lab-mutant"; mkdir -p "$LM/.planning" "$LM/.vibeflow" "$LM/.planning/missions"; cp -R "$LL/.vibeflow/cockpit" "$LM/.vibeflow/cockpit"; cp "$LL/.planning/missions/demo.dag.json" "$LM/.planning/missions/"
agent_actif "$LM"
node -e "
const fs=require('fs');for(const f of ['index.html','project.html']){const p='$LM/.vibeflow/cockpit/'+f;const h=fs.readFileSync(p,'utf8');
const n=h.replace(/<script>\/\* ui\/01-vf-responsive\.js \*\/[\s\S]*?<\/script>/,'<script>/* mutant */</script>');if(n===h){console.error('mutant : bloc 01-vf-responsive.js introuvable');process.exit(1)}fs.writeFileSync(p,n)}" || FAIL=$((FAIL+1))
srv "$LM/.vibeflow/cockpit"; RM="$(mes "http://127.0.0.1:$SRV_PORT/project.html" 1440 - )"; unsrv
assert_has "R4.1 — témoin rouge : sans 01-vf-responsive.js, l'en-tête à 1 440 px est signalé" "$(printf '%s' "$RM" | node "$AUX/ev.mjs" 'j.mesures["1440"].v.join(" | ")')" "en-tête"

# R4.2 — témoin rouge de R-1 (recalculé en 70-04, P70-D-16 et P70-D-22 : borne de 342 px mesurée, badge « au travail » réduit à son point ; la place libre à 1 024 px va jusqu'à une borne de 380 px, mesurée : le mutant à 342 + 58 = 400 px reste rouge avec de la marge, alors que 342 + 36 tenait encore) : une colonne gauche de 400 px fait sortir le dernier bouton de l'onglet Code à 1 024 px
LM2="$WORK/lab-mutant2"; mkdir -p "$LM2/.planning/missions" "$LM2/.vibeflow"; cp -R "$LL/.vibeflow/cockpit" "$LM2/.vibeflow/cockpit"; cp "$LL/.planning/missions/demo.dag.json" "$LM2/.planning/missions/"
agent_actif "$LM2"   # sans agent actif le badge dit « Personne », plus étroit : la mesure ne verrait plus le même en-tête
node -e "
const fs=require('fs');const p='$LM2/.vibeflow/cockpit/index.html';const h=fs.readFileSync(p,'utf8');
const n=h.replace('header .hl { flex: 1 1 0; min-width: 342px; }','header .hl { flex: 1 1 0; min-width: 400px; }');if(n===h){console.error('mutant : borne de 342 px introuvable');process.exit(1)}fs.writeFileSync(p,n)" || FAIL=$((FAIL+1))
srv "$LM2/.vibeflow/cockpit"; RM2="$(RESP_INJECT="$INJ_CODE" mes "http://127.0.0.1:$SRV_PORT/index.html" 1024 - )"; unsrv
assert_has "R4.2 — témoin rouge : avec la colonne gauche à 400 px, un bouton de l'en-tête sort de la fenêtre à 1 024 px (onglet Code)" "$(printf '%s' "$RM2" | node "$AUX/ev.mjs" 'j.mesures["1024"].v.join(" | ")')" "sort de la fenêtre"

# R8 — témoin indépendant de la police ET de la plateforme : Chrome headless sous Linux n'a aucun périphérique de pointage (`pointer: none`) ; la mise en page
# « souris » du cockpit était écrite `(pointer: fine)` et ne s'appliquait pas là (CI, run 41370886002, 8 rouges à 1 024 px) alors que macOS (`fine`) passait. Le même
# Chrome, lancé avec `--blink-settings` sans pointeur, reproduit ce cas sur n'importe quel poste : mêmes assertions R1, onglets Code (avec ses boutons optionnels) et Projet.
echo "=== R8 — aucun périphérique de pointage (pointer: none) : mêmes assertions R1 à 1 024, 1 280 et 1 440 px ==="
CHROME_NOPTR="$AUX/chrome-sans-pointeur.sh"
printf '#!/bin/sh\nexec "%s" --blink-settings=primaryPointerType=1,availablePointerTypes=1,primaryHoverType=1,availableHoverTypes=1 "$@"\n' "$CHROME" > "$CHROME_NOPTR"; chmod +x "$CHROME_NOPTR"
srv "$LC/.vibeflow/cockpit"; P_court=$SRV_PORT; PID_court=$SRV_PID
srv "$LL/.vibeflow/cockpit"; P_long=$SRV_PORT; PID_long=$SRV_PID
MPIDS=()
for nom in court long; do
  eval "P=\$P_$nom"
  for onglet in index project; do
    inj=""; [ "$onglet" = index ] && inj="$INJ_CODE"
    RESP_INJECT="$inj" REAL_HOME="$REAL_HOME" node "$HERE_T/chrome-responsive.mjs" "$CHROME_NOPTR" "http://127.0.0.1:$P/$onglet.html" 1024,1280,1440 - > "$WORK/r8-$nom-$onglet.json" & MPIDS+=($!)
  done
done
wait "${MPIDS[@]}"
for nom in court long; do
  for onglet in index project; do
    R="$(cat "$WORK/r8-$nom-$onglet.json")"
    assert_eq "R8.0 — $nom / $onglet : le Chrome du témoin n'a bien aucun pointeur" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.mesures["1024"].m.pointeur')" "none"
    for w in 1024 1280 1440; do assert_eq "R8 — $nom / $onglet / $w px sans pointeur : aucune superposition, aucun rognage" "$(printf '%s' "$R" | node "$AUX/viol.mjs" "$w" git)" "aucune"; done
  done
done
SRV_PID=$PID_court; unsrv; SRV_PID=$PID_long; unsrv

# R9 — témoin indépendant de la police : des métriques de texte plus larges que celles d'Inter (interlettrage +5 % sur tout l'en-tête, injecté après le chargement)
# ne doivent faire ni recouvrir, ni rogner, ni sortir de la fenêtre un seul élément de l'en-tête à 1 024 px — la mise en page ne dépend d'aucune largeur de police calibrée.
INJ_LARGE="(() => { const st = document.createElement('style'); st.textContent = 'header, header * { letter-spacing: 0.05em !important; }'; document.head.appendChild(st); return true; })()"
echo "=== R9 — métriques de texte élargies (interlettrage +5 %) : mêmes assertions R1 à 1 024 px ==="
srv "$LL/.vibeflow/cockpit"; P=$SRV_PORT; MPIDS=()
for onglet in index project; do
  inj="$INJ_LARGE"; [ "$onglet" = index ] && inj="$INJ_CODE; $INJ_LARGE"
  RESP_INJECT="$inj" mes "http://127.0.0.1:$P/$onglet.html" 1024 - > "$WORK/r9-$onglet.json" & MPIDS+=($!)
done
wait "${MPIDS[@]}"
for onglet in index project; do
  R="$(cat "$WORK/r9-$onglet.json")"
  assert_eq "R9 — long / $onglet / 1 024 px, texte élargi : aucune superposition, aucun rognage" "$(printf '%s' "$R" | node "$AUX/viol.mjs" "1024" git)" "aucune"
done
unsrv

# P78-D-39 (amende P70-D-16, arbitrage Samuel, AskUserQuestion session principale, 2026-11-06) : de 1 000 à 1 279 px ET seulement quand Git est présent (ouvreur posé), le plancher de la recherche
# est de 152 px et son invite devient « Chercher… » ; partout ailleurs (1 280 px et plus, ou lab sans Git) les 200 px et l'invite d'origine restent EXIGÉS, à l'identique de R1.
echo "=== D39 — plancher de la recherche : 152 px de 1 000 à 1 279 px avec Git, 200 px partout ailleurs et sans Git ==="
EXPR39='(() => { const hc = document.querySelector("header .hc"), sb = document.querySelector("#search-btn"), st = sb.querySelector(".st"); return { git: !!document.querySelector("#vf-git-ouvreur"), plancher: getComputedStyle(hc).minWidth, recherche: Math.round(sb.getBoundingClientRect().width), invite: getComputedStyle(sb, "::after").content, stVisible: getComputedStyle(st).display !== "none", texte: st.textContent }; })()'
# mes39 <port> <largeur> [git] : avec « git » (lab AVEC Git) la page n'est prête qu'une fois l'ouvreur posé (il vient d'un fetch asynchrone : plancher 152 px, invite courte) ; SANS Git on prouve son ABSENCE, seule la durée (600 ms + deux relevés égaux) l'établit
mes39() { local pret=""; [ "${3:-}" = git ] && pret="document.readyState === 'complete' && !!document.querySelector('header .brand .mark') && document.querySelector('header .brand .mark').naturalWidth > 0 && !!document.querySelector('#vf-git-ouvreur')"; CDP_PRET="$pret" CDP_VIEWPORT="$2x800" node "$HERE_T/chrome-cdp.mjs" "$CHROME" 600 "$EXPR39" "http://127.0.0.1:$1/index.html"; }
v39() { printf '%s' "$1" | node "$AUX/ev.mjs" "$2"; }
srv "$LC/.vibeflow/cockpit"; P39g=$SRV_PORT; PID39g=$SRV_PID
srv "$LS/.vibeflow/cockpit"; P39s=$SRV_PORT; PID39s=$SRV_PID
for w in 1000 1024 1279; do
  X="$(mes39 $P39g $w git)"
  assert_eq "D39.1 — avec Git / $w px : l'ouvreur est posé et le plancher de la recherche est 152 px" "$(v39 "$X" 'j.resultats[0].valeur.git + "/" + j.resultats[0].valeur.plancher')" "true/152px"
  assert_eq "D39.2 — avec Git / $w px : l'invite courte « Chercher… » remplace l'invite d'origine" "$(v39 "$X" '(j.resultats[0].valeur.invite) + "/" + j.resultats[0].valeur.stVisible')" '"Chercher…"/false'
  assert_eq "D39.3 — avec Git / $w px : la recherche garde au moins 152 px" "$(v39 "$X" 'j.resultats[0].valeur.recherche >= 152')" "true"
done
for w in 1280 1440; do
  X="$(mes39 $P39g $w git)"
  assert_eq "D39.4 — avec Git / $w px : plancher de 200 px, invite d'origine" "$(v39 "$X" 'j.resultats[0].valeur.plancher + "/" + j.resultats[0].valeur.invite + "/" + j.resultats[0].valeur.stVisible')" "200px/none/true"
  assert_eq "D39.4b — avec Git / $w px : la recherche garde au moins 200 px" "$(v39 "$X" 'j.resultats[0].valeur.recherche >= 200')" "true"
done
for w in 1000 1024 1279 1280; do
  X="$(mes39 $P39s $w)"
  assert_eq "D39.5 — SANS Git / $w px : aucun ouvreur, plancher de 200 px, invite d'origine entière" "$(v39 "$X" 'j.resultats[0].valeur.git + "/" + j.resultats[0].valeur.plancher + "/" + j.resultats[0].valeur.invite + "/" + j.resultats[0].valeur.stVisible')" "false/200px/none/true"
  assert_eq "D39.5b — SANS Git / $w px : la recherche garde au moins 200 px" "$(v39 "$X" 'j.resultats[0].valeur.recherche >= 200')" "true"
done
MPIDS=()
for onglet in index project; do
  inj=""; [ "$onglet" = index ] && inj="$INJ_CODE"
  RESP_INJECT="$inj" mes "http://127.0.0.1:$P39s/$onglet.html" 1024,1280 - ${SHOTS:+"$SHOTS/sansgit-$onglet"} > "$WORK/d39-sg-$onglet.json" & MPIDS+=($!)
done
wait "${MPIDS[@]}"
for onglet in index project; do
  for w in 1024 1280; do assert_eq "D39.6 — lab SANS Git / $onglet / $w px : aucune superposition, aucun rognage, recherche >= 200 px (aucun drapeau : borne d'origine)" "$(printf '%s' "$(cat "$WORK/d39-sg-$onglet.json")" | node "$AUX/viol.mjs" "$w")" "aucune"; done
done
SRV_PID=$PID39g; unsrv; SRV_PID=$PID39s; unsrv
# D39.7 (78-10, revue de delta F6a) : Git présent (152 px, invite courte), puis un signal dont la relecture de l'en-tête rend « absent » : le drapeau tombe, le plancher de 200 px et l'invite d'origine reviennent.
cat > "$AUX/d39-absent.mjs" <<JS
import { executer, stabiliser, attendreValeur } from '$HERE_T/chrome-session.mjs';
const [, , chrome, url] = process.argv;
const PRET = "document.readyState === 'complete' && !!document.querySelector('header .brand .mark') && document.querySelector('header .brand .mark').naturalWidth > 0 && !!document.querySelector('#vf-git-ouvreur')";
await executer(chrome, async (s) => {
  await s.send('Emulation.setDeviceMetricsOverride', { width: 1024, height: 800, deviceScaleFactor: 1, mobile: false });
  await s.naviguer(url); await s.attendre(PRET, 'page prête avec Git');
  const mes = () => s.ev("(() => { const hc = document.querySelector('header .hc'), sb = document.querySelector('#search-btn'); return { drapeau: document.querySelector('header').hasAttribute('data-vf-git'), plancher: getComputedStyle(hc).minWidth, invite: getComputedStyle(sb, '::after').content, stVisible: getComputedStyle(sb.querySelector('.st')).display !== 'none' }; })()");
  const out = { avant: await stabiliser(mes) }; // l'état de départ est posé (deux relevés identiques) avant de le juger
  await s.ev("(() => { const f0 = window.fetch.bind(window); window.fetch = (u, i) => /\\\\/api\\\\/vf\\\\/git\\\\/entete/.test(typeof u === 'string' ? u : u.url) ? Promise.resolve(new Response(JSON.stringify({ schema: 'vibeflow/cockpit-git-entete@1', etat: 'absent', depot: 'x', branche: null, worktree: null, detache: false, sha7: null }), { status: 200, headers: { 'content-type': 'application/json' } })) : f0(u, i); document.dispatchEvent(new CustomEvent('vf-git:signal', { detail: { sig: 'x' } })); })()");
  // la relecture de l'en-tête arrive dans une tâche suivante : on attend que le drapeau soit retiré (borné : le mutant D39m3 le garde, la dernière lecture est alors jugée), puis l'état posé
  await attendreValeur(mes, (v) => v.drapeau === false, { max: 6000 });
  out.apres = await stabiliser(mes);
  out.ouvreurCache = await attendreValeur(() => s.ev("document.querySelector('#vf-git-ouvreur').hidden && document.querySelector('#vf-git-ligne').hidden"), (v) => v === true, { max: 3000 });
  return out;
}, { csp: true });
JS
srv "$LC/.vibeflow/cockpit"; X="$(node "$AUX/d39-absent.mjs" "$CHROME" "http://127.0.0.1:$SRV_PORT/index.html" 2>&1 | tail -1)"; unsrv
assert_eq "D39.7a — Git présent à 1 024 px : drapeau posé, plancher 152 px, invite courte « Chercher… » (témoin positif de l'état de départ)" "$(printf '%s' "$X" | node "$AUX/ev.mjs" '[j.avant.drapeau, j.avant.plancher, j.avant.invite, j.avant.stVisible].join("|")')" 'true|152px|"Chercher…"|false'
assert_eq "D39.7b — la relecture de l'en-tête rend « absent » : drapeau retiré, plancher 200 px, invite d'origine rendue, ouvreur et seconde ligne cachés" "$(printf '%s' "$X" | node "$AUX/ev.mjs" '[j.apres.drapeau, j.apres.plancher, j.apres.invite, j.apres.stVisible, j.ouvreurCache].join("|")')" "false|200px|none|true|true"
# mutants : chacun doit rougir un témoin de SA propre règle (copie du lab construit, une chaîne remplacée, échec si la chaîne est introuvable)
mut39() { # mut39 <labSource> <dest> <ancien> <nouveau>
  mkdir -p "$2/.planning/missions" "$2/.vibeflow"; cp -R "$1/.vibeflow/cockpit" "$2/.vibeflow/cockpit"; cp "$1/.planning/missions/demo.dag.json" "$2/.planning/missions/"; agent_actif "$2"
  M39_A="$3" M39_B="$4" node -e "
const fs=require('fs');for(const f of ['index.html','project.html']){const p='$2/.vibeflow/cockpit/'+f;const h=fs.readFileSync(p,'utf8');
const n=h.split(process.env.M39_A).join(process.env.M39_B);if(n===h){console.error('mutant : chaîne introuvable');process.exit(1)}fs.writeFileSync(p,n)}"
}
# mutant 1 : le plancher de 152 px s'applique aussi sans Git (le défaut de c743e356 : une règle posée avant la sortie « pas de dépôt » de 76-vf-git-entete.js, sans clé sur l'ouvreur)
if mut39 "$LS" "$WORK/lab-mut39a" "if (!V || V.etat === 'absent' || !V.depot) return; // P78-D-11" "document.head.appendChild(Object.assign(document.createElement('style'), { textContent: '@media (min-width: 1000px) and (max-width: 1279px) and (not (pointer: coarse)) { header .hc { min-width: 152px; } }' })); if (!V || V.etat === 'absent' || !V.depot) return; // P78-D-11"; then
  srv "$WORK/lab-mut39a/.vibeflow/cockpit"; X="$(mes39 $SRV_PORT 1024)"; unsrv
  assert_eq "D39m1a — mutant « plancher de 152 px aussi SANS Git » : le plancher mesuré à 1 024 px sans Git est 152 px" "$(v39 "$X" 'j.resultats[0].valeur.plancher')" "152px"
  assert_eq "D39m1 — le même mutant : le témoin D39.5 (sans Git, 1 024 px) rougit" "$([ "$(v39 "$X" 'j.resultats[0].valeur.git + "/" + j.resultats[0].valeur.plancher + "/" + j.resultats[0].valeur.invite + "/" + j.resultats[0].valeur.stVisible')" != "false/200px/none/true" ] && echo rouge || echo vert)" "rouge"
else FAIL=$((FAIL+1)); echo "  ❌ FAIL — D39m1 : mutant non construit"; fi
# mutant 2 : le plancher de 152 px s'applique aussi à 1 280 px
if mut39 "$LC" "$WORK/lab-mut39b" '(max-width: 1279px) and (not (pointer: coarse)) {
      header[data-vf-git] .hc' '(max-width: 1280px) and (not (pointer: coarse)) {
      header[data-vf-git] .hc'; then
  git -C "$WORK/lab-mut39b" init -q -b main # la page relit l'en-tête au chargement : la copie du lab doit rester un dépôt, sinon « absent » retire le drapeau avant la mesure
  srv "$WORK/lab-mut39b/.vibeflow/cockpit"; X="$(mes39 $SRV_PORT 1280 git)"; unsrv
  assert_eq "D39m2a — mutant « plancher de 152 px aussi à 1 280 px » : le plancher mesuré à 1 280 px est 152 px" "$(v39 "$X" 'j.resultats[0].valeur.plancher')" "152px"
  assert_eq "D39m2 — le même mutant : le témoin D39.4 (avec Git, 1 280 px) rougit" "$([ "$(v39 "$X" 'j.resultats[0].valeur.plancher + "/" + j.resultats[0].valeur.invite + "/" + j.resultats[0].valeur.stVisible')" != "200px/none/true" ] && echo rouge || echo vert)" "rouge"
else FAIL=$((FAIL+1)); echo "  ❌ FAIL — D39m2 : mutant non construit"; fi
# mutant 3 (F6a) : le drapeau est posé sans condition, même quand la relecture rend « absent »
if mut39 "$LC" "$WORK/lab-mut39c" "if (entete) entete.toggleAttribute('data-vf-git', d.etat !== 'absent');" "if (entete) entete.setAttribute('data-vf-git', '');"; then
  git -C "$WORK/lab-mut39c" init -q -b main
  srv "$WORK/lab-mut39c/.vibeflow/cockpit"; X="$(node "$AUX/d39-absent.mjs" "$CHROME" "http://127.0.0.1:$SRV_PORT/index.html" 2>&1 | tail -1)"; unsrv
  assert_eq "D39m3 — mutant « setAttribute inconditionnel » : rougit D39.7b (drapeau et plancher de 152 px restent après « absent ») alors que l'état de départ (D39.7a) est le bon" "$(printf '%s' "$X" | node "$AUX/ev.mjs" '[j.avant.drapeau, j.avant.plancher, j.apres.drapeau, j.apres.plancher, j.ouvreurCache].join("|")')" "true|152px|true|152px|true"
else FAIL=$((FAIL+1)); echo "  ❌ FAIL — D39m3 : mutant non construit"; fi

echo "=== R7 — chaque bouton d'en-tête a un nom accessible et une infobulle ; badge « au travail » ==="
srv "$LC/.vibeflow/cockpit"; PC7=$SRV_PORT
EXPR='({ aria: (document.getElementById("vf-lock")||{}).getAttribute ? document.getElementById("vf-lock").getAttribute("aria-label") : null, titre: (document.getElementById("vf-lock")||{}).title, sansInfobulle: [...document.querySelectorAll("header .hr button")].filter((b) => b.getBoundingClientRect().width > 0 && !b.title).map((b) => b.id || b.className), sansNom: [...document.querySelectorAll("header .hr button")].filter((b) => b.getBoundingClientRect().width > 0 && !b.getAttribute("aria-label") && !(b.innerText || "").trim()).map((b) => b.id || b.className) })'
X7="$(RESP_INJECT="" CDP_PRET="document.readyState === 'complete' && !!document.getElementById('flows-btn') && !!document.getElementById('vf-lock') && /travail/.test(document.getElementById('vf-lock').textContent)" node "$HERE_T/chrome-cdp.mjs" "$CHROME" 500 "$EXPR" "http://127.0.0.1:$PC7/index.html" "http://127.0.0.1:$PC7/project.html")"; unsrv
assert_eq "R7.0 — témoin : la mesure a eu lieu sur les deux onglets (aucune erreur, deux résultats)" "$(printf '%s' "$X7" | node "$AUX/ev.mjs" '(j.erreur||"")+"|"+(j.resultats||[]).length')" "|2"
for i in 0 1; do on=$([ $i = 0 ] && echo Code || echo Projet)
  assert_eq "R7.1 — $on : l'aria-label du badge dit l'état (plus « … » figé)" "$(printf '%s' "$X7" | node "$AUX/ev.mjs" "/au travail|Personne/.test(j.resultats[$i].valeur.aria)")" "true"
  assert_eq "R7.2 — $on : l'infobulle du badge ne contient jamais « undefined »" "$(printf '%s' "$X7" | node "$AUX/ev.mjs" "!/undefined/.test(j.resultats[$i].valeur.titre)")" "true"
  assert_eq "R7.3 — $on : aucun bouton visible de la zone d'actions de l'en-tête sans infobulle (icône seule sous 1 600 px)" "$(printf '%s' "$X7" | node "$AUX/ev.mjs" "j.resultats[$i].valeur.sansInfobulle.length+'/'+j.resultats[$i].valeur.sansInfobulle.join(',')")" "0/"
  assert_eq "R7.4 — $on : aucun bouton visible de la zone d'actions de l'en-tête sans nom accessible" "$(printf '%s' "$X7" | node "$AUX/ev.mjs" "j.resultats[$i].valeur.sansNom.length+'/'+j.resultats[$i].valeur.sansNom.join(',')")" "0/"
done

# R7.5 — un lab SANS agent actif (le verrou du faux driver et le nœud de DAG « en cours » restent là) : le badge dit « Personne » et ne ment pas
LP="$WORK/lab-sans-agent"; mklab "$LP" sans-agent
srv "$LP/.vibeflow/cockpit"; PP7=$SRV_PORT
XP="$(RESP_INJECT="" CDP_PRET="document.readyState === 'complete' && !!document.getElementById('flows-btn') && !!document.getElementById('vf-lock') && /Personne/.test(document.getElementById('vf-lock').textContent)" node "$HERE_T/chrome-cdp.mjs" "$CHROME" 500 "$EXPR" "http://127.0.0.1:$PP7/index.html" "http://127.0.0.1:$PP7/project.html")"; unsrv
assert_eq "R7.5.0 — témoin : la mesure du lab sans agent a eu lieu sur les deux onglets" "$(printf '%s' "$XP" | node "$AUX/ev.mjs" '(j.erreur||"")+"|"+(j.resultats||[]).length')" "|2"
for i in 0 1; do on=$([ $i = 0 ] && echo Code || echo Projet)
  assert_eq "R7.5.1 — $on, sans agent actif : l'aria-label du badge dit « Personne au travail »" "$(printf '%s' "$XP" | node "$AUX/ev.mjs" "j.resultats[$i].valeur.aria")" "Personne au travail"
  assert_eq "R7.5.2 — $on, sans agent actif : l'infobulle du badge dit « Personne au travail » et ne contient jamais « undefined »" "$(printf '%s' "$XP" | node "$AUX/ev.mjs" "(/^Personne au travail/.test(j.resultats[$i].valeur.titre)&&!/undefined/.test(j.resultats[$i].valeur.titre))+'|'+j.resultats[$i].valeur.titre.slice(0,60)")" "true|Personne au travail · dépôt : vf-dev-manager-v2-cockpit (mis"
done

# R-M (recette 68, R5 + R7 ; P68-D-35, arbitrage Samuel, AskUserQuestion session principale Claude Code, 2026-11-04 : « Tout selon les recos ») : la carte d'une mission ABANDONNÉE (nœud en cours, aucun verrou) sur l'onglet Projet.
# R5 : la pastille dit « Abandonnée » (jamais « À faire »), du jeton gris neutre de « À faire » ; R7 : le pied de la carte passe à la ligne, la boîte du texte ET celle de la pastille tiennent dans la carte, thèmes sombre et clair.
# Un Chrome par thème (chrome-mission.mjs). Aucun verrou n'est tenu pour ce lab (le driver-lock.sh du conductor voisin répond, comme dans l'installation : « present: false ») : la mission est abandonnée, pas vivante. Le faux driver-lock sans verrou ci-dessous sert de repli si le conductor n'est pas voisin.
echo "=== R-M — carte d'une mission abandonnée : pastille « Abandonnée », pied dans la carte (sombre et clair) ==="
mkdir -p "$WORK/locks-abs"; printf '#!/usr/bin/env bash\ncase "$1" in status) echo "{\\"present\\": false}";; orphans) echo "{\\"orphans\\":[]}";; esac\n' > "$WORK/locks-abs/driver-lock.sh"; chmod +x "$WORK/locks-abs/driver-lock.sh"
LM="$WORK/lab-mission"; mklab "$LM" sans-agent
o="$LM/.vibeflow/cockpit"
cockpit_lancer "$LM" VF_COCKPIT_ENGINE_DIR="$ENG" VF_COCKPIT_SCRIPTS_DIR="$WORK/locks-abs"
SRV_PID="${VF_PID:-}"; PM="${VF_PORT:-0}"
RM="$(REAL_HOME="$REAL_HOME" node "$HERE_T/chrome-mission.mjs" "$CHROME" "http://127.0.0.1:$PM/project.html" dag-demo ${SHOTS:+"$SHOTS/mission"})"; unsrv
assert_eq "R-M.0 — témoin : la mesure a eu lieu dans les deux thèmes, sur la carte abandonnée (data-theme sombre puis clair)" "$(printf '%s' "$RM" | node "$AUX/ev.mjs" '(j.erreur||"")+"|"+(j.sombre||{}).n+"|"+(j.sombre||{}).theme+"|"+(j.clair||{}).n+"|"+(j.clair||{}).theme')" "|1|dark|1|light"
for th in sombre clair; do
  assert_eq "R5 — $th : la pastille dit « Abandonnée » (jamais « À faire »)" "$(printf '%s' "$RM" | node "$AUX/ev.mjs" "(j.$th||{}).pastille")" "Abandonnée"
  assert_eq "R5 — $th : gris neutre, le jeton de « À faire » (aucune couleur en dur dans la pastille)" "$(printf '%s' "$RM" | node "$AUX/ev.mjs" "(j.$th||{}).classe")" "vst vst-abandonnee"
  assert_eq "R7 — $th : le texte du pied et la pastille tiennent dans la carte (droite, bas), texte non rogné" "$(printf '%s' "$RM" | node "$AUX/ev.mjs" "(j.erreur||'')+[(j.$th||{}).dedansTexte,(j.$th||{}).dedansPastille,(j.$th||{}).rogne].join('|')")" "true|true|false"
done

# R13 à R16 (70-04 ; P70-D-01 : arbitrage Samuel, AskUserQuestion session principale, 2026-11-03 ; P70-D-16 : même canal, même date ; P70-D-09 et P70-D-10 : choix du manager) — le téléphone (≤ 700 px) et les onglets.
#   R13 en-tête : une seule rangée sur les trois onglets, aucune action dans la rangée, bouton « ⋯ » et son menu (une entrée par action présente, libellé visible, pastille reportée) ; onglets à 13 px, rail à 4 px à toutes les largeurs
#   R14 zoom : hors de l'en-tête, pile verticale à gauche au-dessus de la barre de question, nom accessible français, au bord gauche à 800 px (lot C : au-dessus de la barre, plus en haut à droite), jamais sur « Remonter d'un niveau »
#   R15 tiroir : pas de bouton Détail, ouvert par une carte ou par le titre de la vue d'ensemble, poignée et croix nommée, fermé par la croix, Échap ou le tap dans le vide
#   R16 titre de la vue d'ensemble : un mot ne se coupe jamais sur deux lignes, sauf s'il est plus large que sa boîte (un nom de lab de 60 caractères ; un nom dont le mot à traits d'union tient dans la boîte)
# Poignée = élément décoratif (aria-hidden) plus large que haut en tête du tiroir ; croix = bouton du tiroir dont le nom accessible commence par « Fermer » (le contrat est écrit ici, 70-05 le tient).
echo "=== R13 à R16 — téléphone : en-tête sur une rangée, zoom, tiroir, titre ; onglets aux valeurs de DESIGN.md ==="
LH="$WORK/Trajectoire du grand jalon pour la equipe-produit-v1.0"; mklab "$LH"
srv "$LC/.vibeflow/cockpit"; P_c=$SRV_PORT; PID_c=$SRV_PID
srv "$LL/.vibeflow/cockpit"; P_l=$SRV_PORT; PID_l=$SRV_PID
srv "$LH/.vibeflow/cockpit"; P_h=$SRV_PORT; PID_h=$SRV_PID
J_PAUSE='const p = (ms) => new Promise((r) => setTimeout(r, ms));'
J_BADGE="const bt = document.getElementById('btn-recent'); if (bt && !bt.querySelector('.badge')) { const s = document.createElement('span'); s.className = 'badge'; s.textContent = '3'; bt.appendChild(s); }"
INJ_MENU="(async () => { $J_PAUSE $INJ_CODE; $J_BADGE await p(300); document.getElementById('vf-plus')?.click(); for (let i = 0; i < 40 && !(document.getElementById('vf-plus-menu')?.getBoundingClientRect().width > 0); i++) await p(50); await p(100); return true; })()"
INJ_DRILL="(async () => { $J_PAUSE window.VibeFlow.reveal('n:ph-1'); for (let i = 0; i < 100; i++) { const u = document.getElementById('btn-up'); if (u && !u.hidden) break; await p(50); } await p(300); return true; })()"
J_OPEN="const nd = [...document.querySelectorAll('#svg g.node')].find((e) => e.getBoundingClientRect().width > 0); nd?.dispatchEvent(new MouseEvent('click', { bubbles: true })); for (let i = 0; i < 60 && getComputedStyle(document.getElementById('panel')).visibility !== 'visible'; i++) await p(50); await p(300);"
INJ_CARTE="(async () => { $J_PAUSE $J_OPEN return true; })()"
INJ_CROIX="(async () => { $J_PAUSE $J_OPEN [...document.querySelectorAll('#panel button')].find((b) => /^Fermer/i.test(b.getAttribute('aria-label') || ''))?.click(); await p(150); return true; })()"
# la visite d'office (700 ms après le rendu) est la couche du dessus et capte la première Échap : sous Linux, plus lent, elle s'ouvre pendant la mesure ; R15.4b mesure le tiroir, visite fermée (70-07, O6.15 fixe l'ordre des deux)
# J2 : la visite d'office est fermée AVANT d'ouvrir la feuille de détail (sinon la feuille de visite relève le zoom au-dessus d'elle et il recouvre vraiment le titre) ; titre court (celui du lab)
INJ_SANS_VISITE="(async () => { $J_PAUSE for (let i = 0; i < 100 && !window.VibeFlowTour?.active(); i++) await p(50); window.VibeFlowTour?.end(); await p(300); $J_OPEN await p(900); return true; })()"
INJ_ECHAP="(async () => { $J_PAUSE $J_OPEN window.VibeFlowTour?.end(); document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true })); await p(150); return true; })()"
INJ_VIDE="(async () => { $J_PAUSE $J_OPEN document.getElementById('svg').dispatchEvent(new MouseEvent('click', { bubbles: true })); await p(150); return true; })()"
INJ_TITRE="(async () => { $J_PAUSE const h = document.querySelector('#context h1'); const r = h.getBoundingClientRect(); document.elementFromPoint(r.left + r.width / 2, r.top + r.height / 2)?.dispatchEvent(new MouseEvent('click', { bubbles: true })); for (let i = 0; i < 60 && getComputedStyle(document.getElementById('panel')).visibility !== 'visible'; i++) await p(50); await p(300); return true; })()"
# deux vagues de Chrome en parallèle (profils jetables distincts) ; les assertions se lisent ensuite
OPIDS=()
RESP_INJECT="$INJ_CODE" mes "http://127.0.0.1:$P_c/index.html" 390,768,800,1024,1440 - > "$WORK/r13-index.json" & OPIDS+=($!)
mes "http://127.0.0.1:$P_c/project.html" 390,768,800,1024,1440 - > "$WORK/r13-project.json" & OPIDS+=($!)
mes "http://127.0.0.1:$P_c/equipe.html" 390,768,800,1024,1440 - > "$WORK/r13-equipe.json" & OPIDS+=($!)
RESP_INJECT="$INJ_MENU" mes "http://127.0.0.1:$P_c/index.html" 390 - > "$WORK/r13-menu.json" & OPIDS+=($!)
RESP_INJECT="$INJ_DRILL" mes "http://127.0.0.1:$P_c/project.html" 390 - > "$WORK/r14-parcours.json" & OPIDS+=($!)
wait "${OPIDS[@]}"; OPIDS=()
RESP_INJECT="$INJ_CARTE" mes "http://127.0.0.1:$P_c/project.html" 390 - > "$WORK/r15-carte.json" & OPIDS+=($!)
RESP_INJECT="$INJ_CROIX" mes "http://127.0.0.1:$P_c/project.html" 390 - > "$WORK/r15-croix.json" & OPIDS+=($!)
RESP_INJECT="$INJ_SANS_VISITE" mes "http://127.0.0.1:$P_c/project.html" 390 - > "$WORK/r14-sans-visite.json" & OPIDS+=($!)
RESP_INJECT="$INJ_ECHAP" mes "http://127.0.0.1:$P_c/project.html" 390 - > "$WORK/r15-echap.json" & OPIDS+=($!)
RESP_INJECT="$INJ_VIDE" mes "http://127.0.0.1:$P_c/project.html" 390 - > "$WORK/r15-vide.json" & OPIDS+=($!)
RESP_INJECT="$INJ_TITRE" mes "http://127.0.0.1:$P_c/project.html" 390 - > "$WORK/r15-titre.json" & OPIDS+=($!)
# R15b (recette du 2026-11-08, PU-G-045) : de 701 à 999 px le panneau est fermé par défaut ET s'ouvre au choix d'une carte ; Échap et « Détail » le referment
# (R15.7 : l'Entrée simulée vise la carte focalisée, comme une vraie touche ; elle visait `document`, cible qu'aucune vraie touche n'a. La vraie palette au clavier réel : R15c.2)
INJ_CARTE_T="(async () => { $J_PAUSE window.VibeFlowTour?.end(); $J_OPEN return true; })()"
INJ_CARTE_CLAVIER="(async () => { $J_PAUSE window.VibeFlowTour?.end(); const nd = [...document.querySelectorAll('#svg g.node')].find((e) => e.getBoundingClientRect().width > 0); nd?.setAttribute('tabindex', '0'); nd?.focus(); (nd || document).dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', bubbles: true })); nd?.dispatchEvent(new MouseEvent('click', { bubbles: true })); for (let i = 0; i < 60 && getComputedStyle(document.getElementById('panel')).visibility !== 'visible'; i++) await p(50); await p(300); return true; })()"
INJ_ECHAP_T="(async () => { $J_PAUSE window.VibeFlowTour?.end(); $J_OPEN document.activeElement?.blur(); document.body.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true })); await p(300); return true; })()"
INJ_BOUTON_T="(async () => { $J_PAUSE window.VibeFlowTour?.end(); $J_OPEN document.getElementById('btn-panel').click(); await p(300); return true; })()"
INJ_REFERME_T="(async () => { $J_PAUSE window.VibeFlowTour?.end(); $J_OPEN document.getElementById('btn-panel').click(); await p(300); window.VibeFlow.rerender(); await p(600); return true; })()"
RESP_INJECT="$INJ_CARTE_T" mes "http://127.0.0.1:$P_c/project.html" 768,999 - > "$WORK/r15t-carte.json" & OPIDS+=($!)
RESP_INJECT="$INJ_CARTE_CLAVIER" mes "http://127.0.0.1:$P_c/project.html" 768 - > "$WORK/r15t-clavier.json" & OPIDS+=($!)
RESP_INJECT="$INJ_ECHAP_T" mes "http://127.0.0.1:$P_c/project.html" 768 - > "$WORK/r15t-echap.json" & OPIDS+=($!)
RESP_INJECT="$INJ_BOUTON_T" mes "http://127.0.0.1:$P_c/project.html" 768 - > "$WORK/r15t-bouton.json" & OPIDS+=($!)
RESP_INJECT="$INJ_REFERME_T" mes "http://127.0.0.1:$P_c/project.html" 768 - > "$WORK/r15t-referme.json" & OPIDS+=($!)
mes "http://127.0.0.1:$P_l/project.html" 768,1440 - > "$WORK/r16-long.json" & OPIDS+=($!)
mes "http://127.0.0.1:$P_h/project.html" 768,1440 - > "$WORK/r16-trait.json" & OPIDS+=($!)
wait "${OPIDS[@]}"
# R15c (revue de la recette du 2026-11-08, PU-G-045 ; P1 à P4, S7 ; 3e tour : F1, F5) : le panneau de 701 à 999 px au GESTE RÉEL (chrome-panneau-etroit.mjs : Input.dispatchMouseEvent, Input.dispatchKeyEvent), puis UN mutant par règle
# (copie du lab court, page mutée, même scénario) : chaque mutant doit rougir le champ de SA règle (deux règles qui tiennent la même ligne, p4 et f5, rougissent ensemble)
node "$HERE_T/chrome-panneau-etroit.mjs" "$CHROME" "http://127.0.0.1:$P_c/project.html" > "$WORK/r15c.json" 2> "$WORK/r15c.err"
R15C_SRV=(); R15C_ID=(); R15C_PIDS=()
r15c_mutant() { # r15c_mutant <nom> <ancien> <nouveau> : <ancien> doit exister dans la page (sinon FAIL nommé)
  local M="$WORK/mut-r15c-$1"; rm -rf "$M"; cp -R "$LC" "$M"
  node -e "
const fs=require('fs');const p='$M/.vibeflow/cockpit/project.html';const h=fs.readFileSync(p,'utf8');const o=process.argv[1],r=process.argv[2];if(!h.includes(o)){console.error('mutant $1 : motif introuvable');process.exit(1)}fs.writeFileSync(p,h.split(o).join(r))" "$2" "$3" || { FAIL=$((FAIL+1)); echo "  ❌ FAIL — mutant R15c.$1 : motif introuvable dans la page"; return; }
  srv "$M/.vibeflow/cockpit"; R15C_SRV+=("$SRV_PID"); R15C_ID+=("$1")
  node "$HERE_T/chrome-panneau-etroit.mjs" "$CHROME" "http://127.0.0.1:$SRV_PORT/project.html" > "$WORK/mut-r15c-$1.json" 2>&1 & R15C_PIDS+=($!)
}
r15c_mutant p1 "sansMemoire && k === 'panel' ? undefined : ecrire(k, v)" "ecrire(k, v)"
r15c_mutant p2 "panel.focus({ preventScroll: true }); versPanneau = true; }" "panel.focus({ preventScroll: true }); }"
r15c_mutant p3 "if (!change && !g) return;" ""
r15c_mutant p4 "git.fermer(true); return; }" "void 0; return; }" # P4 et F5 tiennent le même repli (à l'ouverture du panneau, quel que soit le chemin) : ce mutant-ci le supprime, et rougit donc aussi f5 ; le suivant ne vise que « Détail »
r15c_mutant f1 "choixPalette = dansPalette(ev) && ev.target.closest && ev.target.closest('#results .r') ? { clavier: false } : null;" "choixPalette = (dansPalette(ev) || sur(ev)) ? { clavier: false } : null;" # F1 : le geste armé au pointeur posé sur le graphe (l'ancien comportement)
r15c_mutant j6 "dansPalette(ev) && document.querySelector('#results .r.active') ? { clavier: true } : null;" "dansPalette(ev) ? { clavier: true } : null;" # J6 : le geste de la palette armé même sans résultat choisi (l'ancien comportement)
r15c_mutant j6s "choixPalette = ev.key === 'Enter' && dansPalette(ev) &&" "choixPalette = dansPalette(ev) &&" # J6 variante Espace (revue finale, M-C) : le geste de la palette armé par toute touche de la saisie (l'Espace est un caractère de la requête)
r15c_mutant j6k "ev && ev.type === 'keydown' && (ev.key === 'Enter' || ev.key === ' ') && sur(ev) ? { clavier: true } : null;" "ev && ev.type === 'keydown' && (ev.key === 'Enter' || ev.key === ' ') && sur(ev) ? null : null;" # le choix clavier sur une carte de #svg n'ouvre plus le panneau (témoin de la variante Espace : l'Entrée et l'Espace d'une carte, hors palette, ouvrent toujours)
r15c_mutant f5 "if (mi.matches && git && git.ouvert()) git.fermer(true); return; }" "if (mi.matches && document.activeElement !== btn && git && git.ouvert()) git.fermer(true); return; }" # F5 : le repli oublie les ouvertures par « Détail » (le bouton a le focus, au clic comme au clavier)
r15c_mutant p4b "if (e.detail && e.detail.ouvert && mi.matches && ouvert()" "if (false && mi.matches && ouvert()"
r15c_mutant s7 "ev.stopPropagation(); ev.preventDefault(); sansTrace(() => bascule(false));" "ev.preventDefault(); sansTrace(() => bascule(false));"
[ "${#R15C_PIDS[@]}" -gt 0 ] && wait "${R15C_PIDS[@]}"
for i in "${!R15C_SRV[@]}"; do SRV_PID="${R15C_SRV[$i]}"; unsrv; done
SRV_PID=$PID_c; unsrv; SRV_PID=$PID_l; unsrv; SRV_PID=$PID_h; unsrv
mv_() { printf '%s' "$(cat "$1")" | node "$AUX/ev.mjs" "$2"; } # mv_ <fichier de mesures> <expression JS sur j>
for onglet in index project equipe; do
  F="$WORK/r13-$onglet.json"
  assert_eq "R13.1 — $onglet / 390 px : l'en-tête tient sur une seule rangée" "$(mv_ "$F" 'j.mesures["390"].m.rangees')" "1"
  assert_eq "R13.2 — $onglet / 390 px : aucune action dans la rangée, le bouton « ⋯ » est visible" "$(mv_ "$F" '(j.mesures["390"].m.actionsRangee||"")+"|"+j.mesures["390"].m.plus')" "|true"
  for w in 390 1024 1440; do
    assert_eq "R13.4 — $onglet / $w px : trois onglets à 13 px, rail à 4 px (DESIGN.md §5, P70-D-16, P71.5-D-05)" "$(mv_ "$F" "(()=>{const o=j.mesures[\"$w\"].m.onglets;return o?o.n+'|'+o.police+'|'+o.piste:'onglets absents'})()")" "3|13px|4px/4px"
  done
done
assert_eq "R13.3 — Code / 390 px, menu ouvert : une entrée par action présente (huit avec Travail récent et Écrans), libellé visible égal à celui du bouton d'origine, pastille reportée sur l'entrée et sur « ⋯ »" "$(mv_ "$WORK/r13-menu.json" '(()=>{const m=j.mesures["390"].m,s=m.sources,e=m.menu;if(!e)return "menu absent";const p=[];if(s.length<8)p.push("témoin : "+s.length+" actions seulement");if(!s.some((x)=>x.b))p.push("témoin : aucune pastille sur les boutons d origine");if(e.length!==s.length)p.push(e.length+" entrées pour "+s.length+" actions");s.forEach((x,i)=>{if(!e[i]||!e[i].t||e[i].t!==x.t)p.push("entrée "+i+" : ["+(e[i]&&e[i].t)+"] au lieu de ["+x.t+"]");if(e[i]&&e[i].b!==x.b)p.push("pastille de "+x.t+" : ["+(e[i]&&e[i].b)+"] au lieu de ["+x.b+"]")});if(s.some((x)=>x.b)&&!m.plusPastille)p.push("« ⋯ » sans pastille");return p.join(" ; ")||"aucune"})()')" "aucune"
for onglet in index project equipe; do
  F="$WORK/r13-$onglet.json"
  assert_eq "R14.1 — $onglet / 390 px : le zoom n'est plus dans l'en-tête" "$(mv_ "$F" '(()=>{const z=j.mesures["390"].m.zoom;return z?z.entete+"|"+z.vis:"zoom absent"})()')" "false|true"
  assert_eq "R14.2 — $onglet / 390 px : pile verticale à gauche, au-dessus de la barre de question sans la recouvrir" "$(mv_ "$F" '(()=>{const m=j.mesures["390"].m,z=m.zoom;if(!z)return "zoom absent";const p=[];if(z.dir!=="column")p.push("direction "+z.dir);if(z.r[0]>=195)p.push("à droite (x="+z.r[0]+")");if(m.askRect&&z.r[1]+z.r[3]>m.askRect[1])p.push("bas du zoom "+(z.r[1]+z.r[3])+" > haut de la question "+m.askRect[1]);return p.join(" ; ")||"ok"})()')" "ok"
  for w in 390 768 1440; do
    assert_eq "R14.3 — $onglet / $w px : chaque bouton de zoom a un nom accessible en français (différent de sa source anglaise)" "$(mv_ "$F" "(()=>{const z=j.mesures[\"$w\"].m.zoom;if(!z||!z.boutons.length)return 'zoom absent';return z.boutons.filter((b)=>!b.aria||/^(zoom out|fit to screen|zoom in)/i.test(b.aria)).map((b)=>b.id+' ['+b.aria+']').join(' | ')||'aucun'})()")" "aucun"
  done
done
for onglet in index project; do # sur l'onglet Équipe, la position du zoom à ≥ 701 px change en 70-12 (P70-D-20) : non jugée ici
  assert_eq "R14.4 — $onglet / 800 px : la position du zoom (x,y,largeur,hauteur) : la rangée au bord --edge, 8 au-dessus de la barre de question de 92 px (fenêtre de 800 x 600, cibles de 44 : 144 x 52) ; avant la recette du 2026-11-08 (lot C, PU-G-021 ; arbitrage Samuel, AskUserQuestion session principale, 2026-11-08 : « La zone basse sous 1 280 px »), la pile du haut à droite [732,64,52,144]" "$(mv_ "$WORK/r13-$onglet.json" '(()=>{const z=j.mesures["800"].m.zoom;return z?z.r.join(","):"zoom absent"})()')" "16,432,144,52"
  assert_eq "R14.4b — $onglet / 800 px : le panneau de détail est fermé par défaut (PU-G-045) ; le zoom, au bord gauche depuis le lot C, ne dépend plus de lui" "$(mv_ "$WORK/r13-$onglet.json" 'j.mesures["800"].m.tiroir')" "false"
done
# I-2 (intégration) : feuille de détail ouverte (≤ 700 px), le zoom se relève au-dessus d'elle et se replie (data-vf-replie="titre") s'il recouvrirait le titre : replié il ne recouvre rien ; invisible sans cette raison, il reste « zoom absent »
assert_eq "R14.5 — Projet / 390 px, pendant un parcours : le zoom et « Remonter d'un niveau » ne se recouvrent pas" "$(mv_ "$WORK/r14-parcours.json" '(()=>{const m=j.mesures["390"].m,z=m.zoom,u=m.upRect;if(!u)return "témoin : « Remonter » absent (aucun parcours)";if(!z)return "zoom absent";if(!z.vis)return z.replie==="titre"&&z.feuille?"aucun":"zoom absent";const a=z.r,b=u;const x=Math.min(a[0]+a[2],b[0]+b[2])-Math.max(a[0],b[0]),y=Math.min(a[1]+a[3],b[1]+b[3])-Math.max(a[1],b[1]);return x>1.5&&y>1.5?"recouvrement "+Math.round(x)+"x"+Math.round(y)+" px":"aucun"})()')" "aucun"
# J2 (passe de suivi) : R14.5 acceptait « aucun » pour tout repli par le titre ; un zoom replié À TORT (feuille de détail ouverte, titre court) passait. Ici le titre du lab est court : le zoom, relevé au-dessus de la feuille, ne le recouvre pas et doit rester visible.
assert_eq "R14.6 — Projet / 390 px, feuille de détail ouverte, titre court : le zoom reste visible (non replié) quand il ne recouvre pas le titre" "$(mv_ "$WORK/r14-sans-visite.json" '(()=>{const m=j.mesures["390"].m,z=m.zoom;if(!m.tiroir)return "tiroir fermé (témoin)";if(!z)return "zoom absent";return z.vis&&!z.replie?"visible":"replié ou invisible (replie="+z.replie+", vis="+z.vis+")"})()')" "visible"
assert_eq "R15.1 — 390 px : le bouton Détail est invisible sur les trois onglets" "$(mv_ "$WORK/r13-index.json" 'j.mesures["390"].m.btnPanel')|$(mv_ "$WORK/r13-project.json" 'j.mesures["390"].m.btnPanel')|$(mv_ "$WORK/r13-equipe.json" 'j.mesures["390"].m.btnPanel')" "false|false|false"
assert_eq "R15.2 — Projet / 390 px : le tap d'une carte ouvre le tiroir" "$(mv_ "$WORK/r15-carte.json" 'j.mesures["390"].m.tiroir')" "true"
assert_eq "R15.3 — Projet / 390 px, tiroir ouvert : une poignée visible et une croix visible au nom accessible français" "$(mv_ "$WORK/r15-carte.json" '(()=>{const m=j.mesures["390"].m;return m.tiroir?"poignée "+m.poignee+" · croix "+m.croix:"tiroir fermé (témoin)"})()')" "poignée true · croix true"
assert_eq "R15.4 — Projet / 390 px : la croix ferme le tiroir" "$(mv_ "$WORK/r15-croix.json" 'j.mesures["390"].m.tiroir')" "false"
assert_eq "R15.4b — Projet / 390 px : Échap ferme le tiroir (le viewer)" "$(mv_ "$WORK/r15-echap.json" 'j.mesures["390"].m.tiroir')" "false"
assert_eq "R15.4c — Projet / 390 px : le tap dans le vide ferme le tiroir (le viewer)" "$(mv_ "$WORK/r15-vide.json" 'j.mesures["390"].m.tiroir')" "false"
assert_eq "R15.5 — Projet / 390 px : le tap du titre de la vue d'ensemble ouvre le tiroir" "$(mv_ "$WORK/r15-titre.json" 'j.mesures["390"].m.tiroir')" "true"
assert_eq "R15.6 — Projet / 768 px : le choix d'une carte ouvre le panneau de détail (PU-G-045 ; il est fermé par défaut, R14.4b)" "$(mv_ "$WORK/r15t-carte.json" 'j.mesures["768"].m.tiroir')" "true"
assert_eq "R15.6b — Projet / 999 px : idem à la limite haute de l'étroit" "$(mv_ "$WORK/r15t-carte.json" 'j.mesures["999"].m.tiroir')" "true"
assert_eq "R15.7 — Projet / 768 px : un choix au clavier (Entrée) ouvre le panneau ET le focus y entre" "$(mv_ "$WORK/r15t-clavier.json" 'j.mesures["768"].m.tiroir+"|"+j.mesures["768"].m.focusTiroir')" "true|true"
assert_eq "R15.8 — Projet / 768 px : Échap referme le panneau (témoin : il s'était ouvert, R15.6) ET garde la sélection (S7, revue du 2026-11-08 : le viewer n'entend pas cet Échap, il n'efface pas la sélection ; l'Échap vise le corps de la page, comme au clavier sans focus)" "$(mv_ "$WORK/r15t-echap.json" 'j.mesures["768"].m.tiroir+"|"+j.mesures["768"].m.selection')" "false|true"
assert_eq "R15.9 — Projet / 768 px : le bouton « Détail » referme le panneau" "$(mv_ "$WORK/r15t-bouton.json" 'j.mesures["768"].m.tiroir')" "false"
assert_eq "R15.10 — Projet / 768 px : un rendu de plus sur la même sélection (flux en direct) ne rouvre pas le panneau refermé" "$(mv_ "$WORK/r15t-referme.json" 'j.mesures["768"].m.tiroir')" "false"
SAIN_P1="true|aucune|false|aucune|false|true|vf-cockpit:panel=false"; SAIN_P2="true|true|true|true"; SAIN_P3="false|true"; SAIN_P4="768:true:false|999:true:false"; SAIN_S7="true|false|true"; SAIN_P4B="768:touche:false:true:aucune:false|999:clic:false:true:aucune:false"
SAIN_F1="false|false|false|false|false|false|true"; SAIN_J6="true|false|true|true|false"; SAIN_J6S="true|false|true|true|false"; SAIN_J6K="true|true"; SAIN_F5="768:clavier:true:false:PANEL:vf-cockpit:panel=true|999:clic:true:false:PANEL:vf-cockpit:panel=true"
assert_eq "R15c.1 — P1 : à 768 px, choisir une carte puis Échap n'écrivent PAS la préférence du panneau (aucune clé) ; le rechargement à 768 px le retrouve fermé, à 1 440 px ouvert (défaut du bureau) ; « Détail » l'écrit bien (témoin : la clé existe, false)" "$(mv_ "$WORK/r15c.json" 'j.p1')" "$SAIN_P1"
assert_eq "R15c.2 — P2 : par la palette au clavier réel (/, saisie, Entrée) le panneau s'ouvre et le focus y entre, y compris une fois le recentrage de la carte terminé" "$(mv_ "$WORK/r15c.json" 'j.p2')" "$SAIN_P2"
assert_eq "R15c.3 — P3 : fermé par « Détail » à la souris, un rendu de la MÊME sélection 150 ms plus tard ne rouvre pas le panneau (false) ; choisir une autre carte le rouvre (témoin : true)" "$(mv_ "$WORK/r15c.json" 'j.p3')" "$SAIN_P3"
assert_eq "R15c.4 — P4 : à 768 et à 999 px, une sélection avec le tiroir Git ouvert ouvre le panneau (témoin : true) et replie le tiroir Git (false)" "$(mv_ "$WORK/r15c.json" 'j.p4')" "$SAIN_P4"
assert_eq "R15c.6 — P4 bis : à 768 px (touche g réelle) puis 999 px (clic réel sur l'ouvreur), ouvrir Git avec le panneau ouvert replie le panneau, garde la sélection, n'écrit pas la préférence, et le panneau ne se rouvre pas à la fermeture de Git" "$(mv_ "$WORK/r15c.json" 'j.p4b')" "$SAIN_P4B"
assert_eq "R15c.5 — S7 : un Échap réel (focus au corps de la page) referme le panneau et la sélection reste (témoin : elle existait avant)" "$(mv_ "$WORK/r15c.json" 'j.s7')" "$SAIN_S7"
assert_eq "R15c.7 — F1 : fermé par « Détail », un glisser sur le fond du graphe ne rouvre pas le panneau, ni le rendu qui suit (souris réelle, doigt réel, pincement : six fois false) ; un vrai clic sur une carte le rouvre (témoin : true)" "$(mv_ "$WORK/r15c.json" 'j.f1')" "$SAIN_F1"
assert_eq "R15c.8 — F5 : tiroir Git ouvert, « Détail » (clavier à 768 px, clic réel à 999 px) ouvre le panneau, replie Git, laisse le panneau au sommet (PANEL, jamais GIT) ; la préférence n'est écrite que par ce bouton (panel=true)" "$(mv_ "$WORK/r15c.json" 'j.f5')" "$SAIN_F5"
assert_eq "R15c.9 — J6 : un geste de palette qui ne choisit rien (saisie sans résultat, Entrée, Échap) ne laisse aucun armement : fermé par « Détail », le panneau ne se rouvre pas au rendu suivant (témoins : carte choisie, panneau ouvert puis fermé, aucun résultat, palette refermée)" "$(mv_ "$WORK/r15c.json" 'j.j6')" "$SAIN_J6"
assert_eq "R15c.9b — J6, variante Espace (revue finale, M-C) : dans la saisie de la palette l'Espace est un caractère de la requête, seule l'Entrée choisit un résultat : saisie « pha » (un résultat actif : témoin), Espace, Échap, rendu : le panneau fermé par « Détail » reste fermé (témoins : carte choisie, panneau ouvert puis fermé, résultat actif, palette refermée)" "$(mv_ "$WORK/r15c.json" 'j.j6s')" "$SAIN_J6S"
assert_eq "R15c.9c — J6, témoin du choix clavier hors palette (F1) : Entrée puis Espace sur une carte de #svg (choisie par un écouteur de la sonde) ouvrent le panneau fermé par « Détail » (true|true)" "$(mv_ "$WORK/r15c.json" 'j.j6k')" "$SAIN_J6K"
for i in "${!R15C_ID[@]}"; do
  n="${R15C_ID[$i]}"; v="$(mv_ "$WORK/mut-r15c-$n.json" "j.$n")"; eval "sain=\$SAIN_$(printf %s "$n" | tr a-z A-Z)"; echo "     trace du mutant $n : $v"
  assert_eq "R15c.m-$n — le mutant de la règle « $n » rougit R15c (le champ $n n'est plus « $sain »)" "$([ "$v" = "$sain" ] && echo sain || echo rouge)" "rouge"
done
for spec in "long:r16-long" "trait:r16-trait"; do
  for w in 768 1440; do
    assert_eq "R16 — lab « ${spec%%:*} » / $w px : aucun mot du titre de la vue d'ensemble n'est coupé sur deux lignes (sauf un mot plus large que sa boîte)" "$(mv_ "$WORK/${spec#*:}.json" "(()=>{const m=j.mesures[\"$w\"].m;if(!m.titreMots||!m.titreMots.length)return 'mesure vide : titre absent';return m.titreMots.filter((w)=>w.rect>1&&!w.large).map((w)=>w.mot+' x'+w.rect+' (boîte '+m.titreBoite+' px)').join(' | ')||'aucun'})()")" "aucun"
  done
done

# R17 à R20 (70-12 ; P70-D-20 : choix du manager, vf-dev-manager, 2026-11-04, PAS un arbitrage de Samuel) — l'onglet Équipe (UIFN-14), sur un lab STABLE : une session et un sous-agent
# jetables (la première carte ne varie pas), nom de lab long (le fil d'Ariane et la recherche se disputent la colonne gauche de l'en-tête à 1 024 px).
#   R17.1 zoom : à 768, 1 024 et 1 440 px (donc dès 701 px) la rangée en bas à gauche du viewer d'origine (x=16, 16 px au-dessus du bas, direction « row »), sans recouvrir une carte (R17.1b) ;
#   R17.2 Code et Projet gardent la position du zoom de 794c6dba à 1 440 px, et de 701 à 1 279 px prennent la rangée au bord gauche au-dessus de la barre (PU-G-021, lot C) ; R18 fil d'Ariane et recherche ne se recouvrent pas à 1 024 px (Projet et Équipe) ;
#   R19 le titre `#context h1` ne recouvre pas la première carte, au premier affichage (R19.1 : 390, 768, 1 024, 1 440 px) et après l'ouverture de la session (R19.2 : 390, 1 024 px) ;
#   R20 la page Équipe entre dans la matrice : aucune superposition d'en-tête ni de surfaces, aucun défilement horizontal (R1 et R3 appliqués à `equipe.html`, 390 / 768 / 1 024 / 1 440 px).
echo "=== R17 à R20 — onglet Équipe : zoom, titre, fil d'Ariane, matrice (UIFN-14) ==="
sous_agent() { # sous_agent <numéro de session de agent_actif> <lab> : un sous-agent actif (forme réelle) sous la session du lab ; sa date est rafraîchie tant que la suite vit
  local N="$1" L="$2" SID D TS; SID="aaaa1111-2222-3333-4444-$(printf '%012d' "$N")"; D="$HOME/.claude/projects/-lab-$N/$SID/subagents"; mkdir -p "$D"; TS="$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"
  printf '{"agentType":"vf-coder","isBuiltIn":false,"launchedWithDefaults":false,"description":"tâche synthétique","toolUseId":"toolu_s1","spawnDepth":1,"requestShape":"background","requestNonInteractive":true}' > "$D/agent-s1.meta.json"
  printf '{"type":"user","isSidechain":true,"agentId":"s1","parentUuid":null,"cwd":"%s","sessionId":"%s","gitBranch":"main","version":"2.1.317","timestamp":"%s","message":{"role":"user","content":"mandat synthétique"}}\n{"type":"assistant","isSidechain":true,"agentId":"s1","cwd":"%s","sessionId":"%s","gitBranch":"main","version":"2.1.317","timestamp":"%s","message":{"role":"assistant","content":[{"type":"tool_use","id":"toolu_x","name":"Read","input":{"file_path":"%s/README.md"}}]}}\n' "$L" "$SID" "$TS" "$L" "$SID" "$TS" "$L" > "$D/agent-s1.jsonl"
  ( while kill -0 $$ 2>/dev/null; do touch "$D/agent-s1.jsonl"; sleep 10; done ) </dev/null >/dev/null 2>&1 &
}
LE="$WORK/vibeflow-os-un-nom-de-projet-vraiment-tres-long-equipe"; mklab "$LE"; sous_agent "$NSESS" "$LE"
srv "$LE/.vibeflow/cockpit"; P_e=$SRV_PORT; PID_e=$SRV_PID
zoom_base() { case "$1" in 768) echo "16|312|144|52" ;; 1024) echo "16|662|114|42" ;; 1440) echo "16|842|114|42" ;; esac; } # x|y|largeur|hauteur du zoom de Code et de Projet (labs de la suite, sans le terminal donc sans pastille) : 1 440 px, celui de 794c6dba ; de 701 à 1 279 px (recette du 2026-11-08, lot C ; PU-G-021 ; arbitrage Samuel, AskUserQuestion session principale, 2026-11-08 : « La zone basse sous 1 280 px ») la rangée au bord --edge, 8 au-dessus de la barre de question (768 px : fenêtre de 480, barre de 92, cibles de 44 donc 144 x 52 ; 1 024 px : fenêtre de 768, barre de 40, 114 x 42)
J_PAUSE_E='const p = (ms) => new Promise((r) => setTimeout(r, ms));'
INJ_SESSION="(async () => { $J_PAUSE_E const nd = [...document.querySelectorAll('#svg g.node')].find((e) => e.getBoundingClientRect().width > 0); nd?.dispatchEvent(new MouseEvent('dblclick', { bubbles: true })); for (let i = 0; i < 60 && !/^Session/.test(document.querySelector('#context .k')?.textContent || ''); i++) await p(50); await p(400); return true; })()"
OPIDS=()
mes "http://127.0.0.1:$P_e/equipe.html" 390,768,1024,1440 - > "$WORK/r17-equipe.json" & OPIDS+=($!)
RESP_INJECT="$INJ_SESSION" mes "http://127.0.0.1:$P_e/equipe.html" 390,1024 - > "$WORK/r19-session.json" & OPIDS+=($!)
mes "http://127.0.0.1:$P_e/project.html" 1024 - > "$WORK/r18-projet.json" & OPIDS+=($!)
wait "${OPIDS[@]}"
# R18 (PU-G-001, coque étroite 2026-11-06) : sous 1 280 px la racine du fil prend un libellé court et cède sa place au NOM DU DÉPÔT (masquée plutôt que rognée) ; le témoin ne dit donc plus « fil visible » mais « fil visible ou masqué par la règle » : un fil absent sans l'attribut de masquage reste un échec
R18X='(() => { const f = document.getElementById("crumbs"), b = f && f.querySelector("button"), s = document.getElementById("search-btn"), v = (e) => e && e.getBoundingClientRect().width > 0 && getComputedStyle(e).display !== "none"; const rf = f && v(f) && v(b) ? f.getBoundingClientRect() : null, rs = s && v(s) ? s.getBoundingClientRect() : null; return { visible: !!rf, masque: !!(b && b.hasAttribute("data-vf-masque")), recherche: !!rs, recouvre: rf && rs ? Math.min(rf.right, rs.right) - Math.max(rf.left, rs.left) > 1 && Math.min(rf.bottom, rs.bottom) - Math.max(rf.top, rs.top) > 1 : false }; })()'
for pg in equipe project; do CDP_VIEWPORT=1024x768 node "$HERE_T/chrome-cdp.mjs" "$CHROME" 800 "$R18X" "http://127.0.0.1:$P_e/$pg.html" > "$WORK/r18x-$pg.json"; done
SRV_PID=$PID_e; unsrv
assert_eq "R17.0 — témoin : la fixture de l'onglet Équipe montre au moins une carte à 1 024 px" "$(mv_ "$WORK/r17-equipe.json" 'j.mesures["1024"].m.nCartes>=1')" "true"
for w in 768 1024 1440; do
  assert_eq "R17.1 — Équipe / $w px : le zoom est la rangée en bas à gauche (x, écart au bas de la fenêtre, direction)" "$(mv_ "$WORK/r17-equipe.json" "(()=>{const m=j.mesures[\"$w\"].m;const z=m.zoom;if(!z)return 'zoom absent';return z.r[0]+'|'+(m.fenetre[1]-(z.r[1]+z.r[3]))+'|'+z.dir})()")" "16|16|row"
  assert_eq "R17.1b — Équipe / $w px : le zoom ne recouvre aucune carte" "$(mv_ "$WORK/r17-equipe.json" "(()=>{const m=j.mesures[\"$w\"].m;return m.nCartes>=1?String(m.zoomCartes):'témoin : aucune carte'})()")" "0"
  for onglet in index project; do
    assert_eq "R17.2 — $onglet / $w px : la position du zoom (x,y,largeur,hauteur) : celle de 794c6dba à 1 440 px ; de 768 à 1 024 px, la rangée au bord --edge posée 8 au-dessus de la barre de question, plus la pile du haut à droite (PU-G-021, lot C de la recette du 2026-11-08)" "$(mv_ "$WORK/r13-$onglet.json" "(()=>{const z=j.mesures[\"$w\"].m.zoom;return z?z.r.join('|'):'zoom absent'})()")" "$(zoom_base "$w")"
  done
done
for spec in "Équipe:equipe" "Projet:project"; do
  assert_eq "R18 — ${spec%%:*} / 1 024 px, lab au nom long : le fil d'Ariane ne recouvre pas la recherche (témoin : la recherche est visible, le fil est visible ou masqué par la règle de la racine)" "$(mv_ "$WORK/r18x-${spec#*:}.json" '(()=>{const v=j.resultats[0].valeur;if(!v.recherche)return "témoin : recherche absente";if(!v.visible&&!v.masque)return "témoin : fil absent sans masquage";return v.recouvre?"recouvrement":"aucun"})()')" "aucun"
done
for w in 390 768 1024 1440; do
  assert_eq "R19.1 — Équipe / $w px, premier affichage : le titre ne recouvre pas la première carte (aire en px²)" "$(mv_ "$WORK/r17-equipe.json" "(()=>{const m=j.mesures[\"$w\"].m;return m.nCartes>=1&&m.titreRect?String(m.titreCarte):'témoin : titre ou carte absents'})()")" "0"
done
for w in 390 1024; do
  assert_eq "R19.2 — Équipe / $w px, session ouverte : le titre ne recouvre pas la première carte (aire en px²)" "$(mv_ "$WORK/r19-session.json" "(()=>{const m=j.mesures[\"$w\"].m;return m.nCartes>=1&&m.titreRect?String(m.titreCarte):'témoin : titre ou carte absents'})()")" "0"
done
for w in 390 768 1024 1440; do
  mode=equipe-git; [ "$w" -lt 1000 ] && mode=equipe-bas # lab avec Git : le plancher de la recherche est de 152 px de 1 000 à 1 279 px (P78-D-39), comme pour Code et Projet (R1) ; le nom du dépôt entier prend la place avant (PU-G-001)
  assert_eq "R20 — Équipe / $w px : aucune superposition d'en-tête ni de surfaces, aucun défilement horizontal" "$(printf '%s' "$(cat "$WORK/r17-equipe.json")" | node "$AUX/viol.mjs" "$w" "$mode")" "aucune"
done

# R21 à R23 (70-04, juge des arbitrages, 2026-11-04 ; P70-D-22 : « Badge réduit à son point (Recommandé) », arbitrage Samuel, AskUserQuestion session principale, 2026-11-04 ; Q13a) — chacun a son mutant, sur une COPIE de la page servie :
#   R21 le badge « au travail » entier (« 10 au travail ») ne fait déborder ni l'en-tête ni le fil d'Ariane en parcours de 1 600 à 1 639 px (la tranche du badge réduit va jusqu'à 1 639 px, seuil mesuré 1 635 px) ; mutant : la tranche s'arrête à 1 599 px
#   R22 le repli mesuré : « 99 au travail » et un bouton d'en-tête de plus (libellé visible au-dessus de 1 600 px) à 1 640, 1 700 et 1 800 px, racine (Code) et parcours (Projet) ; mutant : le repli ne pose plus le point
#   R23 une action désactivée l'est aussi dans le menu « ⋯ » (Équipe, 390 px : « Par où commencer ») : aria-disabled, atténuée, même infobulle ; mutant : le menu ne reporte plus l'état désactivé
echo "=== R21 à R23 — badge entier de 1 600 à 1 639 px, repli mesuré, action désactivée du menu « ⋯ » (chacun avec son mutant) ==="
J_LIBELLE() { echo "for (let i = 0; i < 100 && !document.querySelector('#vf-lock .bl'); i++) await p(50); document.querySelector('#vf-lock .bl').textContent = '$1 au travail';"; }
INJ_R21="(async () => { $J_PAUSE $INJ_CODE; $(J_LIBELLE 10) window.VibeFlow.reveal('n:ph-1'); for (let i = 0; i < 100; i++) { const u = document.getElementById('btn-up'); if (u && !u.hidden) break; await p(50); } await p(400); return true; })()"
J_EXTRA="window.VibeFlow.addHeaderButton({ id: 'xtra1', label: 'Extra', icon: 'ui', title: 'Extra', onClick() {} });"
INJ_R22C="(async () => { $J_PAUSE $INJ_CODE; $(J_LIBELLE 99) $J_EXTRA await p(500); return true; })()"
INJ_R22P="(async () => { $J_PAUSE $INJ_CODE; $(J_LIBELLE 99) $J_EXTRA window.VibeFlow.reveal('n:ph-1'); for (let i = 0; i < 100; i++) { const u = document.getElementById('btn-up'); if (u && !u.hidden) break; await p(50); } await p(500); return true; })()"
INJ_R23="(async () => { $J_PAUSE document.getElementById('vf-plus')?.click(); for (let i = 0; i < 40 && !(document.getElementById('vf-plus-menu')?.getBoundingClientRect().width > 0); i++) await p(50); await p(100); return true; })()"
W21="1600,1610,1619,1625,1630,1635,1639"; W22="1640,1700,1800"
mutant_suite() { # mutant_suite <dossier> <ancien> <nouveau> : seconde retouche, sur la copie déjà faite par mutant_page
  node -e "
const fs=require('fs');let n=0;for(const f of ['index.html','project.html','equipe.html']){const p='$WORK/mut-$1/.vibeflow/cockpit/'+f;if(!fs.existsSync(p))continue;const h=fs.readFileSync(p,'utf8');if(!h.includes(process.argv[1]))continue;fs.writeFileSync(p,h.split(process.argv[1]).join(process.argv[2]));n++}
if(!n){console.error('mutant $1 : second motif introuvable');process.exit(1)}" "$2" "$3" || { FAIL=$((FAIL+1)); echo "  ❌ FAIL — mutant $1 : second motif introuvable dans la page"; return 1; }
}
mutant_page() { # mutant_page <dossier> <ancien> <nouveau> : copie de la page du lab long, <ancien> doit exister (sinon FAIL nommé)
  local M="$WORK/mut-$1"; mkdir -p "$M/.planning/missions" "$M/.vibeflow"; cp -R "$LL/.vibeflow/cockpit" "$M/.vibeflow/cockpit"; cp "$LL/.planning/missions/demo.dag.json" "$M/.planning/missions/"; agent_actif "$M"
  node -e "
const fs=require('fs');let n=0;for(const f of ['index.html','project.html','equipe.html']){const p='$M/.vibeflow/cockpit/'+f;if(!fs.existsSync(p))continue;const h=fs.readFileSync(p,'utf8');if(!h.includes(process.argv[1]))continue;fs.writeFileSync(p,h.split(process.argv[1]).join(process.argv[2]));n++}
if(!n){console.error('mutant $1 : motif introuvable');process.exit(1)}" "$2" "$3" || { FAIL=$((FAIL+1)); echo "  ❌ FAIL — mutant $1 : motif introuvable dans la page"; return 1; }
}
# R21 : le repli mesuré rattrape seul un badge trop large ; le mutant retire donc la tranche (1 599 px) ET le repli, pour que la tranche soit ce qui est éprouvée
mutant_page r21 '@media (min-width: 701px) and (max-width: 1639px)' '@media (min-width: 701px) and (max-width: 1599px)'; M21=$?
[ $M21 = 0 ] && { mutant_suite r21 "badge.setAttribute('data-vf-point', '');" '' || M21=1; }
mutant_page r22 "badge.setAttribute('data-vf-point', '');" ''; M22=$?
mutant_page r23 "src.disabled || src.getAttribute('aria-disabled') === 'true'" 'false'; M23=$?
srv "$LL/.vibeflow/cockpit"; P_l=$SRV_PORT; PID_l=$SRV_PID
srv "$LC/.vibeflow/cockpit"; P_c=$SRV_PORT; PID_c=$SRV_PID
[ $M21 = 0 ] && { srv "$WORK/mut-r21/.vibeflow/cockpit"; P_m21=$SRV_PORT; PID_m21=$SRV_PID; }
[ $M22 = 0 ] && { srv "$WORK/mut-r22/.vibeflow/cockpit"; P_m22=$SRV_PORT; PID_m22=$SRV_PID; }
[ $M23 = 0 ] && { srv "$WORK/mut-r23/.vibeflow/cockpit"; P_m23=$SRV_PORT; PID_m23=$SRV_PID; }
OPIDS=()
RESP_INJECT="$INJ_R21" mes "http://127.0.0.1:$P_l/project.html" "$W21" - > "$WORK/r21.json" & OPIDS+=($!)
RESP_INJECT="$INJ_R22C" mes "http://127.0.0.1:$P_l/index.html" "$W22" - > "$WORK/r22-code.json" & OPIDS+=($!)
RESP_INJECT="$INJ_R22P" mes "http://127.0.0.1:$P_l/project.html" "$W22" - > "$WORK/r22-projet.json" & OPIDS+=($!)
RESP_INJECT="$INJ_R23" mes "http://127.0.0.1:$P_c/equipe.html" 390 - > "$WORK/r23.json" & OPIDS+=($!)
wait "${OPIDS[@]}"; OPIDS=()
[ $M21 = 0 ] && { RESP_INJECT="$INJ_R21" mes "http://127.0.0.1:$P_m21/project.html" "$W21" - > "$WORK/m21.json" & OPIDS+=($!); }
[ $M22 = 0 ] && { RESP_INJECT="$INJ_R22C" mes "http://127.0.0.1:$P_m22/index.html" "$W22" - > "$WORK/m22-code.json" & OPIDS+=($!); RESP_INJECT="$INJ_R22P" mes "http://127.0.0.1:$P_m22/project.html" "$W22" - > "$WORK/m22-projet.json" & OPIDS+=($!); }
[ $M23 = 0 ] && { RESP_INJECT="$INJ_R23" mes "http://127.0.0.1:$P_m23/equipe.html" 390 - > "$WORK/m23.json" & OPIDS+=($!); }
[ "${#OPIDS[@]}" -gt 0 ] && wait "${OPIDS[@]}"
SRV_PID=$PID_l; unsrv; SRV_PID=$PID_c; unsrv
for v in m21 m22 m23; do eval "[ \$M${v#m} = 0 ] && { SRV_PID=\$PID_$v; unsrv; }"; done
assert_rouge() { case "$2" in aucune|mesure*|*témoin*) echo "  ❌ FAIL — $1"; echo "     attendu: une violation de mise en page"; echo "     obtenu:  [${2:0:600}]"; FAIL=$((FAIL+1));; *) echo "  ✅ PASS — $1"; PASS=$((PASS+1));; esac; }
viol_() { printf '%s' "$(cat "$1")" | node "$AUX/viol.mjs" "$2"; }
# DIAG : à l'échec d'une assertion de la visite, la ligne de diagnostic de la mesure (bbox de #tour, #ask et ses avis, fenêtre, obstacles vus au placement) ; aucune assertion ne change
diag_visite() { local l; l="$(printf '%s' "$(cat "$1")" | node "$AUX/ev.mjs" "(j.mesures&&j.mesures[\"$2\"]&&j.mesures[\"$2\"].m.tourDiag)||'visite fermée ou diagnostic absent'" 2>/dev/null)"; echo "     DIAG $3 [$2 px] $l"; }
# R23 : toute action désactivée du bouton d'origine l'est aussi sur l'entrée du menu ; témoin : au moins une action désactivée (Équipe : « Par où commencer »)
EXPR23='(()=>{const m=j.mesures["390"].m,s=m.sources,e=m.menu;if(!e)return "menu absent";const p=[];if(!s.some((x)=>x.off))p.push("témoin : aucune action désactivée");s.forEach((x,i)=>{if(!x.off)return;const y=e[i];if(!y||!y.off)p.push(x.t+" : entrée non désactivée");else{if(!(y.op<1))p.push(x.t+" : entrée non atténuée (opacité "+y.op+")");if(y.ti!==x.ti||!y.ti)p.push(x.t+" : infobulle ["+(y.ti||"")+"] au lieu de ["+x.ti+"]")}});return p.join(" ; ")||"aucune"})()'
for w in ${W21//,/ }; do
  assert_eq "R21 — Projet, parcours, badge « 10 au travail » entier / $w px : aucun bouton hors de la fenêtre, fil d'Ariane non rogné, aucune superposition" "$(viol_ "$WORK/r21.json" "$w")" "aucune"
done
for w in 1600 1610 1619 1625 1630; do # sous 1 635 px le badge entier ne tient pas : le mutant doit rougir (dès 1 635 px il tient, rien à démontrer)
  [ $M21 = 0 ] && assert_rouge "R21m — mutant « tranche du badge réduit arrêtée à 1 599 px et repli retiré » : la mesure rougit à $w px" "$(viol_ "$WORK/m21.json" "$w")"
done
for w in ${W22//,/ }; do
  assert_eq "R22 — Code (racine), « 99 au travail » et un bouton de plus / $w px : aucune violation (repli mesuré)" "$(viol_ "$WORK/r22-code.json" "$w")" "aucune"
  assert_eq "R22 — Projet (parcours), « 99 au travail » et un bouton de plus / $w px : aucune violation (repli mesuré)" "$(viol_ "$WORK/r22-projet.json" "$w")" "aucune"
  [ "$(viol_ "$WORK/r22-code.json" "$w")" != aucune ] && diag_visite "$WORK/r22-code.json" "$w" "R22 Code"
  [ "$(viol_ "$WORK/r22-projet.json" "$w")" != aucune ] && diag_visite "$WORK/r22-projet.json" "$w" "R22 Projet"
done
assert_eq "R23 — Équipe / 390 px : l'action désactivée (« Par où commencer ») l'est aussi dans le menu « ⋯ » (aria-disabled, atténuée, même infobulle)" "$(printf '%s' "$(cat "$WORK/r23.json")" | node "$AUX/ev.mjs" "$EXPR23")" "aucune"
if [ $M22 = 0 ]; then # les mutants du repli : sans lui, chacun de ces trois relevés rougit (1 640 px racine : #btn-panel sort ; 1 640 px et 1 700 px en parcours : fil rogné)
  assert_rouge "R22m — mutant « le repli ne pose plus le point » : Code racine à 1 640 px rougit" "$(viol_ "$WORK/m22-code.json" 1640)"
  assert_rouge "R22m — mutant « le repli ne pose plus le point » : Projet parcours à 1 640 px rougit" "$(viol_ "$WORK/m22-projet.json" 1640)"
  assert_rouge "R22m — mutant « le repli ne pose plus le point » : Projet parcours à 1 700 px rougit" "$(viol_ "$WORK/m22-projet.json" 1700)"
fi
[ $M23 = 0 ] && assert_rouge "R23m — mutant « le menu ne reporte plus l'état désactivé » : la mesure rougit" "$(printf '%s' "$(cat "$WORK/m23.json")" | node "$AUX/ev.mjs" "$EXPR23")"

# R24 (coque étroite, 2026-11-06) — le menu « ⋯ » dès 999 px (amendement de P70-D-01, « Icônes dans le menu ⋯ », arbitrage Samuel, AskUserQuestion session principale, 2026-11-06 ; PU-G-008), une icône par ligne et un fond opaque (PU-G-011, PU-G-007 en partie),
# la légende du point « au travail » (PU-G-012), le nom du dépôt et le libellé court de la racine (PU-G-001), le niveau courant du fil entier (PU-G-002). Lab nommé « vibeflow-os » avec un dossier « scripts » : un nom de 11 caractères, un niveau de 7.
#   R24.1 701 à 999 px : « ⋯ » visible, les six icônes secondaires hors de l'en-tête, ouvreur Git et Détail restés dehors ; 1 000 px : rien n'est posé (« ⋯ » absent, icônes visibles)
#   R24.2 menu ouvert à 800 px : une icône par ligne, fond opaque, voile --scrim, légende « Personne au travail » ; R24.3 pastille du « ⋯ » : nom accessible qui dit ce qu'elle annonce
#   R24.4 dans « scripts » à 1 000 px et en paysage 844 px : le niveau courant est entier (flèche + « scripts »), jamais rogné ; R24.5 racine à 1 000 et 1 279 px : le nom « vibeflow-os » n'est jamais rogné, et à 1 279 px la racine s'écrit « Ensemble » (nom accessible : « Vue d'ensemble »)
echo "=== R24 — coque étroite : menu « ⋯ » dès 999 px, icônes, légende, fil d'Ariane, nom du dépôt ==="
LV="$WORK/vibeflow-os"; mkdir -p "$LV/scripts"; for f in vf-cockpit-git vf-cockpit-server vf-cockpit-paths; do printf 'export const x = 1;\n' > "$LV/scripts/$f.mjs"; done; mklab "$LV" sans-agent
srv "$LV/.vibeflow/cockpit"; P_v=$SRV_PORT; PID_v=$SRV_PID
PRET_OUVREUR="document.readyState === 'complete' && !!document.querySelector('header .brand .mark') && document.querySelector('header .brand .mark').naturalWidth > 0 && !!document.querySelector('#vf-git-ouvreur')" # l'ouvreur Git (fetch asynchrone) est posé : le lab de R24 est un dépôt
cdpv() { CDP_PRET="${3:-}" CDP_VIEWPORT="$1" node "$HERE_T/chrome-cdp.mjs" "$CHROME" 1200 "$2" "http://127.0.0.1:$P_v/index.html"; } # cdpv <LxH> <expression> [<CDP_PRET>]
EV24='const vis = (e) => !!e && e.getBoundingClientRect().width > 0 && getComputedStyle(e).display !== "none"; const p = (ms) => new Promise((r) => setTimeout(r, ms));'
X_MENU="(async () => { $EV24 await p(600); const ids = ['theme-toggle', 'btn-health', 'tour-btn', 'btn-export', 'flows-btn', 'filters-btn'].filter((i) => document.getElementById(i)); return { n: ids.length, hors: ids.filter((i) => !vis(document.getElementById(i))).length, plus: vis(document.getElementById('vf-plus')), ouvreur: vis(document.getElementById('vf-git-ouvreur')), detail: vis(document.getElementById('btn-panel')) }; })()"
X_OUVERT="(async () => { $EV24 await p(600); document.documentElement.setAttribute('data-theme', 'dark'); const sa = document.getElementById('btn-health'); if (sa && !sa.querySelector('.badge')) { const c = document.createElement('span'); c.className = 'badge'; c.textContent = '4'; sa.appendChild(c); await p(400); } if (!document.getElementById('vf-plus-menu')) { document.getElementById('vf-plus').click(); await p(300); } const m = document.getElementById('vf-plus-menu'), l = [...m.querySelectorAll('.vf-pl-i')], v = document.getElementById('vf-plus-voile'); return { lignes: l.length, sansIcone: l.filter((b) => !b.querySelector('svg.vf-pl-ic')).length, fond: getComputedStyle(m).backgroundColor, image: getComputedStyle(m).backgroundImage.slice(0, 15), voile: !!v && getComputedStyle(v).backgroundColor !== 'rgba(0, 0, 0, 0)', legende: (m.querySelector('.vf-pl-etat') || {}).textContent || '', pastille: document.getElementById('vf-plus').getAttribute('aria-label') }; })()"
X_FIL="(async () => { $EV24 await p(600); if (document.querySelector('#crumbs button') && !document.getElementById('btn-up').offsetWidth) { window.VibeFlow.go('n:d-scripts'); } await p(900); const b = document.querySelector('#crumbs button.cur'), n = document.getElementById('proj-name'); return { texte: b ? b.textContent.trim() : '', large: b ? Math.round(b.getBoundingClientRect().width) : 0, rogne: b ? b.scrollWidth > b.clientWidth + 1 : null, haut: vis(document.getElementById('btn-up')), nomRogne: n && n.getBoundingClientRect().width > 0 ? n.scrollWidth > n.clientWidth + 1 : null, racine: !!document.querySelector('#crumbs [data-vf-racine]:not([data-vf-masque])') }; })()"
X_RACINE="(async () => { $EV24 await p(600); const n = document.getElementById('proj-name'), r = document.querySelector('#crumbs [data-vf-racine]'); return { nomRogne: n.scrollWidth > n.clientWidth + 1, nom: n.textContent, racine: r ? { court: r.getAttribute('data-vf-racine'), nomAccessible: r.getAttribute('aria-label'), masque: r.hasAttribute('data-vf-masque') } : null }; })()"
for w in 701x800 800x600 999x800 1000x800; do eval "R241_${w%%x*}=\"\$(cdpv $w \"\$X_MENU\" \"\$PRET_OUVREUR\")\""; done
R242="$(cdpv 800x600 "$X_OUVERT")"; R242b="$(cdpv 390x844 "$X_OUVERT")"
R244a="$(cdpv 1000x800 "$X_FIL")"; R244b="$(cdpv 844x390 "$X_FIL")"; R245a="$(cdpv 1000x800 "$X_RACINE")"; R245b="$(cdpv 1279x800 "$X_RACINE")"
SRV_PID=$PID_v; unsrv
ev24() { printf '%s' "$1" | node "$AUX/ev.mjs" "$2"; }
for w in 701 800 999; do
  vn="R241_$w"
  assert_eq "R24.1 — $w px : « ⋯ » visible, les icônes secondaires hors de l'en-tête (6 sur 6), ouvreur Git et Détail restés dehors" "$(ev24 "${!vn}" '(()=>{const v=j.resultats[0].valeur;return (v.plus?"plus":"sans plus")+" "+v.hors+"/"+v.n+" "+(v.ouvreur?"ouvreur":"sans ouvreur")+" "+(v.detail?"detail":"sans detail")})()')" "plus 6/6 ouvreur detail"
done
assert_eq "R24.1 — 1 000 px : rien n'est posé (« ⋯ » absent, les six icônes secondaires visibles)" "$(ev24 "$R241_1000" '(()=>{const v=j.resultats[0].valeur;return (v.plus?"plus":"sans plus")+" "+v.hors+"/"+v.n})()')" "sans plus 0/6"
for spec in "800 px:$R242" "390 px:$R242b"; do
  assert_eq "R24.2 — ${spec%%:*}, menu ouvert, thème sombre : une icône par ligne, fond opaque (--menu-solid sur le fond du thème), voile --scrim, légende du point « au travail »" "$(ev24 "${spec#*:}" '(()=>{const v=j.resultats[0].valeur;const o=/^rgb\(/.test(v.fond);return (v.lignes>=6?"lignes":"témoin : "+v.lignes+" lignes")+" sans-icone="+v.sansIcone+" opaque="+o+" image="+v.image+" voile="+v.voile+" legende="+v.legende})()')" "lignes sans-icone=0 opaque=true image=linear-gradient voile=true legende=Personne au travail"
  assert_eq "R24.3 — ${spec%%:*} : la pastille du « ⋯ » a un nom accessible qui dit ce qu'elle annonce" "$(ev24 "${spec#*:}" 'j.resultats[0].valeur.pastille')" "Plus d'actions, des compteurs à lire dans le menu"
done
for spec in "1000 px:$R244a" "844 px paysage:$R244b"; do
  assert_eq "R24.4 — dans « scripts » à ${spec%%:*} : le niveau courant est entier (flèche « Remonter » et « scripts », largeur > 30 px, non rogné)" "$(ev24 "${spec#*:}" '(()=>{const v=j.resultats[0].valeur;return v.texte+" rogne="+v.rogne+" haut="+v.haut+" large="+(v.large>30)})()')" "scripts rogne=false haut=true large=true"
done
assert_eq "R24.5 — racine à 1 000 px : le nom « vibeflow-os » n'est pas rogné (la racine, qui ne tient pas, est masquée plutôt que rognée)" "$(ev24 "$R245a" '(()=>{const v=j.resultats[0].valeur;return v.nom+" rogne="+v.nomRogne})()')" "vibeflow-os rogne=false"
assert_eq "R24.5 — racine à 1 279 px : nom non rogné, racine écrite « Ensemble », nom accessible « Vue d'ensemble », non masquée" "$(ev24 "$R245b" '(()=>{const v=j.resultats[0].valeur;return v.nom+" rogne="+v.nomRogne+" "+(v.racine?v.racine.court+"/"+v.racine.nomAccessible+" masque="+v.racine.masque:"racine absente")})()')" "vibeflow-os rogne=false Ensemble/Vue d'ensemble masque=false"


# R25 — sans moteur de questions (aucun `claude` sur le PATH du serveur, le cas de la CI Linux et d'un poste neuf) : la barre porte l'avis « no_engine » et est plus haute ; le zoom en rangée de 701 à 1 279 px
# se pose quand même 8 px au-dessus de la barre telle qu'elle est (PU-G-021), jamais sur elle. Le PATH du serveur est un dossier de liens vers les seuls outils dont il a besoin (jamais celui du poste, qui peut porter un vrai `claude`).
echo "=== R25 — sans moteur de questions : l'avis allonge la barre, le zoom reste 8 px au-dessus d'elle ==="
SANS="$WORK/bin-sans-moteur"; mkdir -p "$SANS"; for b in node git sh bash env dirname date mkdir cat rm grep sed seq sleep ln cp chmod touch kill pwd printf tr awk ps pgrep head tail wc basename uname; do p="$(command -v $b 2>/dev/null)"; [ -n "$p" ] && ln -sf "$p" "$SANS/$b"; done
r25_serveur() { PATH="$SANS" command -v claude >/dev/null 2>&1 && { echo "  ❌ le dossier sans moteur porte un claude"; FAIL=$((FAIL+1)); }; local o="$1" lab; lab="$(cd "$1/../.." && pwd)"
  COCKPIT_SORTIE="$o" cockpit_lancer "$lab" PATH="$SANS" VF_COCKPIT_ENGINE_DIR="$ENG" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS_HOTE"
  SRV_PID="${VF_PID:-}"; SRV_PORT="${VF_PORT:-0}"; }
r25_serveur "$LC/.vibeflow/cockpit"; P_sm=$SRV_PORT; PID_sm=$SRV_PID
OPIDS=()
for onglet in index project; do mes "http://127.0.0.1:$P_sm/$onglet.html" 768,800,1024 - > "$WORK/r25-$onglet.json" & OPIDS+=($!); done
wait "${OPIDS[@]}"
SRV_PID=$PID_sm; unsrv
for onglet in index project; do
  for w in 768 800 1024; do
    assert_eq "R25.0 — $onglet / $w px sans moteur : l'avis est affiché, la barre est plus haute que sans avis (témoin de l'état de départ)" "$(mv_ "$WORK/r25-$onglet.json" "(()=>{const m=j.mesures[\"$w\"].m;return m.askBarre?(m.askBarre[3]>(${w}===1024?40:92)):'barre absente'})()")" "true"
    assert_eq "R25.1 — $onglet / $w px sans moteur : le zoom (rangée au bord gauche) se pose 8 px au-dessus de la barre telle qu'elle est (écart au pixel près : 7 à 9)" "$(mv_ "$WORK/r25-$onglet.json" "(()=>{const m=j.mesures[\"$w\"].m;if(!m.zoom||!m.askBarre)return 'mesure absente';const e=m.askBarre[1]-(m.zoom.r[1]+m.zoom.r[3]);return e>=7&&e<=9?'8':'écart '+e})()")" "8"
  done
done

vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
