#!/usr/bin/env bash
# test-cockpit-responsive.sh — CKPT-12 (P67-D-21) : la fenêtre du cockpit est ajustable, de 1 024 à 2 560 px, sans superposition ni rognage.
#   R1 chargement à 1 024 / 1 280 / 1 440 / 1 920 / 2 560 px · R2 redimensionnement à chaud 1 920 -> 1 024 -> 1 920 · R3 rendu non cassé à 800 et 390 px
#   R4 témoin rouge : le même lab sans la mise en page du cockpit rougit · R5 lab sans STATE.md : aucun champ vide dans le sous-titre ni le panneau
# Deux onglets (Code, Projet) × deux labs (nom court, nom de 60 caractères), badge « au travail » rempli (verrou + nœud de DAG).
# Mesure : getBoundingClientRect dans un Chrome headless (chrome-responsive.mjs) — recouvrement des éléments frères, scrollWidth > clientWidth,
# recherche >= 200 px, logo >= 20x18 sans filtre, barre de question sur une ligne avec son invite entière.
# Sans navigateur : la suite se déclare SAUTÉE (exit 0, message explicite) — jamais un vert à vide. Exit 0 si tout passe.
set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; } # port libre choisi à l'exécution (jamais un tirage au hasard : trois suites en parallèle se heurtaient)
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
ENG="$SCRIPTS/../skills/cockpit-moteur"
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi; done
if [ -z "$CHROME" ]; then echo "  ⊘ SUITE SAUTÉE : aucun navigateur (Chrome, Chromium) — CKPT-12 NON vérifié, non compté comme réussi"; exit 0; fi
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude/scripts"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [${2:0:600}]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [${2:0:600}]"; FAIL=$((FAIL+1)); fi; }

cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
# violations d'une clé de mesure (une ligne par violation, « - » si aucune) ; la mesure elle-même doit exister
cat > "$AUX/viol.mjs" <<'JS'
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); const m = j.mesures?.[process.argv[2]];
if (!m) { console.log('mesure absente : ' + (j.erreur || process.argv[2])); process.exit(0); }
const bas = process.argv[3] === 'bas'; // sous 1 000 px le panneau est un tiroir fermé : seul l'en-tête et la barre de question sont mesurés
const plein = m.m.enteteElements >= (bas ? 3 : 6) && (bas || /#panel/.test(m.m.surfaces || '')) && /#ask/.test(m.m.surfaces || '');
console.log(!plein ? 'mesure vide : ' + JSON.stringify(m.m) : m.v.length ? m.v.slice(0, 4).join(' | ') : 'aucune');
JS
# faux verrou de driver (HOME jetable) : un propriétaire au nom long, comme en vraie mission
cat > "$HOME/.claude/scripts/driver-lock.sh" <<'SH'
#!/usr/bin/env bash
case "$1" in
  status) echo '{"locks":[{"present":true,"owner":"vf-dev-manager-v2-cockpit","step":"mission","ws":"","scope":"repo","age_seconds":135,"stale":false,"children_running":1}]}' ;;
  orphans) echo '{"orphans":[]}' ;;
esac
SH
mklab() { # mklab <dir> : lab GSD sans STATE.md, deux phases, un DAG de mission avec un nœud en cours
  local L="$1" B="$1/.planning"; mkdir -p "$L/src" "$B/phases/01-socle" "$B/phases/02-suite" "$B/missions"
  printf 'export const u = () => 1;\n' > "$L/src/util.js"
  printf '# Roadmap\n\n## Jalon démo\n\n- [x] **Phase 1: Socle** - premier jet\n- [ ] **Phase 2: Suite** - la suite\n' > "$B/ROADMAP.md"
  printf '<objective>Faire le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"; echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
  printf '<objective>Faire la suite</objective>\n' > "$B/phases/02-suite/02-01-PLAN.md"
  printf '{"nodes":[{"id":"a","step":"première étape","stage":"","deps":[],"scope":["src/**"],"status":"done"},{"id":"b","step":"seconde étape","stage":"","deps":["a"],"scope":["src/**"],"status":"running"}]}\n' > "$B/missions/demo.dag.json"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  node "$SCRIPTS/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/build-$(basename "$L").out" 2>&1 || cat "$WORK/build-$(basename "$L").out"
}
srv() { # srv <sortie> -> SRV_PORT SRV_PID
  local o="$1" lab; lab="$(cd "$1/../.." && pwd)"; rm -f "$o/.cache/server.json"
  ( cd "$lab" && VF_COCKPIT_ENGINE_DIR="$ENG" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS" exec node "$o/serve.mjs" --no-open --port $(libre) > "$o/../serve.out" 2>&1 ) </dev/null >/dev/null 2>&1 &
  SRV_PID=$!; PIDS+=($SRV_PID)
  for _ in $(seq 1 100); do grep -q '"port"' "$o/.cache/server.json" 2>/dev/null && break; sleep 0.1; done
  SRV_PORT="$(node -e "console.log(JSON.parse(require('fs').readFileSync('$o/.cache/server.json','utf8')).port)" 2>/dev/null || echo 0)"
}
unsrv() { vf_hyg_stop "$SRV_PID"; }
mes() { REAL_HOME="$REAL_HOME" node "$HERE_T/chrome-responsive.mjs" "$CHROME" "$@"; } # mes <url> <largeurs> <resize|-> [<captures>]
LARGES="1024,1280,1440,1920,2560"
# boutons d'en-tête OPTIONNELS de l'onglet Code (Travail récent et Écrans n'existent que si le lab a un historique récent et des pages) : ajoutés par l'API
# d'extension du viewer, avec leur libellé et leur icône d'origine, pour mesurer le pire en-tête réel — sans eux R-1 (bouton rogné à 1 024 px) restait invisible
INJ_CODE="(() => { const SC = window.VibeFlow; SC.addHeaderButton({ id: 'btn-recent', label: 'Recent work', icon: 'recent', title: 'What was just worked on, on one board', onClick() {} }); SC.addHeaderButton({ id: 'screens-btn', label: 'Screens', icon: 'ui', title: 'Pick a screen of the app', onClick() {} }); return true; })()"

LC="$WORK/lab-court"; mklab "$LC"
LL="$WORK/vibeflow-os-un-nom-de-projet-vraiment-tres-long-pour-tester"; mklab "$LL"
echo "=== R1, R2 — chargement et redimensionnement à chaud : deux onglets, deux labs ==="
for spec in "court:$LC" "long:$LL"; do
  nom="${spec%%:*}"; lab="${spec#*:}"; srv "$lab/.vibeflow/cockpit"; P=$SRV_PORT
  assert_eq "0 — serveur du lab « $nom » démarré" "$([ "$P" -gt 0 ] && echo oui || echo non)" "oui"
  for onglet in index project; do
    inj=""; [ "$onglet" = index ] && inj="$INJ_CODE"
    R="$(RESP_INJECT="$inj" mes "http://127.0.0.1:$P/$onglet.html" "$LARGES" 1920:1024 ${SHOTS:+"$SHOTS/$nom-$onglet"})"
    echo "$R" > "$WORK/mes-$nom-$onglet.json"
    for w in ${LARGES//,/ }; do assert_eq "R1 — $nom / $onglet / $w px : aucune superposition, aucun rognage" "$(printf '%s' "$R" | node "$AUX/viol.mjs" "$w")" "aucune"; done
    assert_eq "R2 — $nom / $onglet : 1 920 -> 1 024 à chaud" "$(printf '%s' "$R" | node "$AUX/viol.mjs" "resize:1920:1024")" "aucune"
    assert_eq "R2 — $nom / $onglet : 1 024 -> 1 920 à chaud (retour)" "$(printf '%s' "$R" | node "$AUX/viol.mjs" "resize:1024:1920")" "aucune"
  done
  if [ "$nom" = court ]; then
    echo "=== R3 — en dessous de 1 024 px : rendu non cassé (800 et 390 px) ==="
    for onglet in index project; do
      R="$(mes "http://127.0.0.1:$P/$onglet.html" 800,390 -)"
      for w in 800 390; do assert_eq "R3 — $onglet / $w px : aucune superposition d'en-tête, aucun défilement horizontal" "$(printf '%s' "$R" | node "$AUX/viol.mjs" "$w" bas)" "aucune"; done
    done
  fi
  unsrv
done
echo "=== R5, R6 — lab sans STATE.md : aucun champ vide ; titre de l'onglet ; traduction avant la peinture ==="
srv "$LC/.vibeflow/cockpit"; PC=$SRV_PORT
EXPR='({ titre: document.title, ctx: (document.getElementById("context")||{}).innerText||"", panneau: (document.getElementById("panel")||{}).innerText||"" })'
XP="$(node "$HERE_T/chrome-cdp.mjs" "$CHROME" 2000 "$EXPR" "http://127.0.0.1:$PC/project.html" "http://127.0.0.1:$PC/index.html")"
assert_eq "R5.1 — sous-titre du projet sans « ? » ni parenthèses vides" "$(printf '%s' "$XP" | node "$AUX/ev.mjs" '/[?]|[(][)]/.test(j.resultats[0].valeur.ctx)')" "false"
assert_eq "R5.2 — panneau d'ensemble sans bloc « Maintenant » ni « Phase — »" "$(printf '%s' "$XP" | node "$AUX/ev.mjs" '/Maintenant|Phase —/.test(j.resultats[0].valeur.panneau)')" "false"
assert_has "R5.3 — témoin : le panneau montre bien les effectifs du lab" "$(printf '%s' "$XP" | node "$AUX/ev.mjs" 'j.resultats[0].valeur.panneau')" "phases"
assert_eq "R6.1 — titre de l'onglet Projet : « <nom> — Projet »" "$(printf '%s' "$XP" | node "$AUX/ev.mjs" 'j.resultats[0].valeur.titre')" "lab-court — Projet"
assert_eq "R6.2 — titre de l'onglet Code : « <nom> — Code »" "$(printf '%s' "$XP" | node "$AUX/ev.mjs" 'j.resultats[1].valeur.titre')" "lab-court — Code"
EXPR='(async () => { const d = document.createElement("div"); d.textContent = "Thinking…"; document.body.appendChild(d); await Promise.resolve(); await Promise.resolve(); const t = d.textContent; d.remove(); return t; })()'
XT="$(node "$HERE_T/chrome-cdp.mjs" "$CHROME" 1500 "$EXPR" "http://127.0.0.1:$PC/project.html")"; unsrv
assert_eq "R6.3 — « Thinking… » inséré est traduit avant toute image (deux micro-tâches)" "$(printf '%s' "$XT" | node "$AUX/ev.mjs" 'j.resultats[0].valeur')" "Réflexion…"

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

# I2 (recette 3, retour de Samuel, saisie texte, session principale, 2026-11-03) : « le flou sous le titre est trop dense, il faut aussi qu'il ai un radius fort en haut faible en bas, il doit etre comparable au blur iOS ».
# Matériau retenu : blur(24px) saturate(1.8), fond à 30 % d'opacité, coins 22 px en haut et 6 px en bas — mesuré dans le style calculé, deux thèmes, deux onglets.
echo "=== I2 — le titre de la vue d'ensemble : verre dépoli à la iOS (filtre, fond translucide, rayons fort en haut / faible en bas) ==="
cat > "$AUX/i2.js" <<'JS'
(async () => { const pause = (ms) => new Promise((r) => setTimeout(r, ms)); const ctx = document.getElementById('context'), out = {};
  for (const th of ['light', 'dark']) { document.documentElement.setAttribute('data-theme', th); await pause(150);
    const cs = getComputedStyle(ctx), m = /rgba?\(([^)]+)\)/.exec(cs.backgroundColor), p = m ? m[1].split(',').map(Number) : [];
    out[th] = { filtre: cs.backdropFilter, alpha: p.length === 4 ? p[3] : 1, haut: [parseFloat(cs.borderTopLeftRadius), parseFloat(cs.borderTopRightRadius)], bas: [parseFloat(cs.borderBottomLeftRadius), parseFloat(cs.borderBottomRightRadius)] }; }
  return out; })()
JS
srv "$LC/.vibeflow/cockpit"; PI=$SRV_PORT
for onglet in index project; do
  XI="$(CDP_VIEWPORT=1280x800 CDP_PRET="document.readyState === 'complete' && !!document.querySelector('#context h1')" node "$HERE_T/chrome-cdp.mjs" "$CHROME" 300 "$(cat "$AUX/i2.js")" "http://127.0.0.1:$PI/$onglet.html")"
  for th in light dark; do
    VI="j.resultats[0].valeur.$th"
    assert_eq "I2.1 — $onglet / $th : flou large mais doux, saturation relevée (blur(24px) saturate(1.8))" "$(printf '%s' "$XI" | node "$AUX/ev.mjs" "$VI.filtre")" "blur(24px) saturate(1.8)"
    assert_eq "I2.2 — $onglet / $th : fond nettement plus transparent (opacité <= 0,35, > 0)" "$(printf '%s' "$XI" | node "$AUX/ev.mjs" "$VI.alpha>0&&$VI.alpha<=0.35")" "true"
    assert_eq "I2.3 — $onglet / $th : coins très arrondis en haut (22 px), peu en bas (6 px)" "$(printf '%s' "$XI" | node "$AUX/ev.mjs" "[$VI.haut,$VI.bas]")" "[[22,22],[6,6]]"
  done
done
unsrv

echo "=== R4 — témoin rouge : sans la mise en page du cockpit, la mesure rougit ==="
LM="$WORK/lab-mutant"; mkdir -p "$LM/.planning" "$LM/.vibeflow" "$LM/.planning/missions"; cp -R "$LL/.vibeflow/cockpit" "$LM/.vibeflow/cockpit"; cp "$LL/.planning/missions/demo.dag.json" "$LM/.planning/missions/"
node -e "
const fs=require('fs');for(const f of ['index.html','project.html']){const p='$LM/.vibeflow/cockpit/'+f;const h=fs.readFileSync(p,'utf8');
const n=h.replace(/<script>\/\* ui\/01-vf-responsive\.js \*\/[\s\S]*?<\/script>/,'<script>/* mutant */</script>');if(n===h){console.error('mutant : bloc 01-vf-responsive.js introuvable');process.exit(1)}fs.writeFileSync(p,n)}" || FAIL=$((FAIL+1))
srv "$LM/.vibeflow/cockpit"; RM="$(mes "http://127.0.0.1:$SRV_PORT/project.html" 1440 - )"; unsrv
assert_has "R4.1 — témoin rouge : sans 01-vf-responsive.js, l'en-tête à 1 440 px est signalé" "$(printf '%s' "$RM" | node "$AUX/ev.mjs" 'j.mesures["1440"].v.join(" | ")')" "en-tête"

# R4.2 — témoin rouge de R-1 : la borne d'avant (colonne gauche de 300 px) fait sortir le dernier bouton de l'onglet Code à 1 024 px
LM2="$WORK/lab-mutant2"; mkdir -p "$LM2/.planning/missions" "$LM2/.vibeflow"; cp -R "$LL/.vibeflow/cockpit" "$LM2/.vibeflow/cockpit"; cp "$LL/.planning/missions/demo.dag.json" "$LM2/.planning/missions/"
node -e "
const fs=require('fs');const p='$LM2/.vibeflow/cockpit/index.html';const h=fs.readFileSync(p,'utf8');
const n=h.replace('header .hl { flex: 1 1 0; min-width: 264px; }','header .hl { flex: 1 1 0; min-width: 300px; }');if(n===h){console.error('mutant : borne de 264 px introuvable');process.exit(1)}fs.writeFileSync(p,n)" || FAIL=$((FAIL+1))
srv "$LM2/.vibeflow/cockpit"; RM2="$(RESP_INJECT="$INJ_CODE" mes "http://127.0.0.1:$SRV_PORT/index.html" 1024 - )"; unsrv
assert_has "R4.2 — témoin rouge : avec la colonne gauche à 300 px, un bouton de l'en-tête sort de la fenêtre à 1 024 px (onglet Code)" "$(printf '%s' "$RM2" | node "$AUX/ev.mjs" 'j.mesures["1024"].v.join(" | ")')" "sort de la fenêtre"

# R8 — témoin indépendant de la police ET de la plateforme : Chrome headless sous Linux n'a aucun périphérique de pointage (`pointer: none`) ; la mise en page
# « souris » du cockpit était écrite `(pointer: fine)` et ne s'appliquait pas là (CI, run 41370886002, 8 rouges à 1 024 px) alors que macOS (`fine`) passait. Le même
# Chrome, lancé avec `--blink-settings` sans pointeur, reproduit ce cas sur n'importe quel poste : mêmes assertions R1, onglets Code (avec ses boutons optionnels) et Projet.
echo "=== R8 — aucun périphérique de pointage (pointer: none) : mêmes assertions R1 à 1 024, 1 280 et 1 440 px ==="
CHROME_NOPTR="$AUX/chrome-sans-pointeur.sh"
printf '#!/bin/sh\nexec "%s" --blink-settings=primaryPointerType=1,availablePointerTypes=1,primaryHoverType=1,availableHoverTypes=1 "$@"\n' "$CHROME" > "$CHROME_NOPTR"; chmod +x "$CHROME_NOPTR"
for spec in "court:$LC" "long:$LL"; do
  nom="${spec%%:*}"; lab="${spec#*:}"; srv "$lab/.vibeflow/cockpit"; P=$SRV_PORT
  for onglet in index project; do
    inj=""; [ "$onglet" = index ] && inj="$INJ_CODE"
    R="$(RESP_INJECT="$inj" REAL_HOME="$REAL_HOME" node "$HERE_T/chrome-responsive.mjs" "$CHROME_NOPTR" "http://127.0.0.1:$P/$onglet.html" 1024,1280,1440 -)"
    assert_eq "R8.0 — $nom / $onglet : le Chrome du témoin n'a bien aucun pointeur" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.mesures["1024"].m.pointeur')" "none"
    for w in 1024 1280 1440; do assert_eq "R8 — $nom / $onglet / $w px sans pointeur : aucune superposition, aucun rognage" "$(printf '%s' "$R" | node "$AUX/viol.mjs" "$w")" "aucune"; done
  done
  unsrv
done

# R9 — témoin indépendant de la police : des métriques de texte plus larges que celles d'Inter (interlettrage +5 % sur tout l'en-tête, injecté après le chargement)
# ne doivent faire ni recouvrir, ni rogner, ni sortir de la fenêtre un seul élément de l'en-tête à 1 024 px — la mise en page ne dépend d'aucune largeur de police calibrée.
INJ_LARGE="(() => { const st = document.createElement('style'); st.textContent = 'header, header * { letter-spacing: 0.05em !important; }'; document.head.appendChild(st); return true; })()"
echo "=== R9 — métriques de texte élargies (interlettrage +5 %) : mêmes assertions R1 à 1 024 px ==="
srv "$LL/.vibeflow/cockpit"; P=$SRV_PORT
for onglet in index project; do
  inj="$INJ_LARGE"; [ "$onglet" = index ] && inj="$INJ_CODE; $INJ_LARGE"
  R="$(RESP_INJECT="$inj" mes "http://127.0.0.1:$P/$onglet.html" 1024 -)"
  assert_eq "R9 — long / $onglet / 1 024 px, texte élargi : aucune superposition, aucun rognage" "$(printf '%s' "$R" | node "$AUX/viol.mjs" "1024")" "aucune"
done
unsrv

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

vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
