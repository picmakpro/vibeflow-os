#!/usr/bin/env bash
# test-cockpit-palette.sh — la palette de commandes (80-14, FORM-04, FORM-18, P80-D-11/13/14/21/35/51/55), un vrai Chrome.
#   PA1 : « >git » ouvre l'historique Git sans rien envoyer, rôles ARIA · PA2 : huit actions, mode >, copie du lien, question sans envoi, onglets, focus,
#   ligne du terminal · PA3 : phases et agents par VF_ETAT, état vide et annonce, requête hostile, formes (44 / 36 px, pied), fichiers servis sans doublon.
#   Régime allégé (consigne de Samuel, session principale, 2026-11-13) : pas de mutant. PA_SCRIPTS = module à bâtir (rejeu sur la base : scripts/ + skills/).
# Sans navigateur : SUITE SAUTÉE (exit 0, message explicite), jamais un vert à vide.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
CHROME=""
for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
if [ -z "$CHROME" ]; then
  . "$HERE_T/chrome-saut.sh"
  vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur (Chrome, Chromium) — la palette de commandes NON vérifiée, non comptée comme réussie"; exit 0
fi
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
. "$HERE_T/socle-serveur.sh"
PASS=0; FAIL=0
assert_eq() {
  if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1))
  else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [${2:0:700}]"; FAIL=$((FAIL+1)); fi
}
cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; let j; try { j = JSON.parse(fs.readFileSync(0, 'utf8')); } catch { console.log('sortie illisible'); process.exit(0); }
if (j.erreur) { console.log('mesure indisponible : ' + j.erreur); process.exit(0); }
const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
mklab() { # un lab de code (n05 importe n06 à n08) et un projet d'une phase « Socle »
  local L="$1" B="$1/.planning" i; mkdir -p "$L/src" "$B/phases/01-socle"
  for i in $(seq -w 1 12); do printf 'export const v%s = () => %s;\n' "$i" "$((10#$i))" > "$L/src/n$i.js"; done
  printf "import { v06 } from './n06.js';\\nimport { v07 } from './n07.js';\\n" > "$L/src/n05.js"
  printf "import { v08 } from './n08.js';\\nexport const v05 = () => v06() + v07() + v08();\\n" >> "$L/src/n05.js"
  printf '# Titre du projet\n' > "$B/PROJECT.md"
  printf '# Roadmap\n\n## Jalon démo\n\n- [x] **Phase 1: Socle** - jet\n\n### Phase 1: Socle\n**Depends on**: Nothing\n' > "$B/ROADMAP.md"
  printf -- '---\nfiles_modified: [src/n01.js]\n---\n<objective>Faire le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"
  echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
  git -C "$L" init -q -b main && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
}
# build_serve <lab> [--terminal] -> PORT, SRV, LANCE_RC. Le module est celui de PA_SCRIPTS s'il est posé, sinon celui du dépôt.
build_serve() {
  local L="$1" O="$1/.vibeflow/cockpit" mod="${PA_SCRIPTS:+$RACINE_BASE}" flag=() pret=port
  [ "${2:-}" = "--terminal" ] && { flag=(--terminal); pret=terminal; }
  node "${mod:-$SCRIPTS/..}/scripts/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
  mkdir -p "$WORK/fauxbin" "$O/.cache"; rm -f "$O/.cache/terminal-amorce"
  cp "$SCRIPTS/tests/temoins/fauxbin-claude/claude" "$WORK/fauxbin/claude"; chmod +x "$WORK/fauxbin/claude"
  [ -n "${flag[*]:-}" ] && (umask 077; node -e "console.log(require('crypto').randomBytes(32).toString('hex'))" > "$O/.cache/terminal-amorce")
  COCKPIT_MODULE="$mod" COCKPIT_PRET="$pret" COCKPIT_LOG="$WORK/serve.out" cockpit_lancer "$L" PATH="$WORK/fauxbin:$PATH" ${flag[@]+"${flag[@]}"}; LANCE_RC=$?
  SRV="$VF_PID"; PORT="$VF_PORT"
}
mesurer() { REAL_HOME="$REAL_HOME" node "$HERE_T/chrome-palette.mjs" "$CHROME" "http://127.0.0.1:$PORT" "$1" 2>"$WORK/mesure.err"; }
E() { printf '%s' "${2:-$R}" | node "$AUX/ev.mjs" "$1"; }
SC_BASE="${PA_SCRIPTS:-$SCRIPTS}"; RACINE_BASE="$(cd "$SC_BASE/.." && pwd -P)"
LAB="$WORK/lab"; mklab "$LAB"; build_serve "$LAB"
assert_eq "PA0 — serveur du lab démarré" "$([ "$PORT" -gt 0 ] && echo oui || echo non)" "oui"
cockpit_get /_vf/ui/07-vf-raccourcis.js > "$WORK/f07.js"; C07="$VF_CODE"; cockpit_get /_vf/ui/79-vf-fr-dict-c.js > "$WORK/f79.js"; C79="$VF_CODE"
R="$(mesurer base)"; [ -n "${SONDE:-}" ] && { printf '%s\n' "$R"; cat "$WORK/mesure.err"; }; [ -n "${KEEP:-}" ] && printf '%s\n' "$R" > "$WORK/base.json"
vf_hyg_stop "$SRV"
# chk <titre> <expression JS sur j> <attendu> : l'expression peut courir sur plusieurs lignes (guillemets simples)
chk() { assert_eq "$1" "$(E "$2")" "$3"; }
AP="'"; GIT="Ouvrir l${AP}historique Git"; TERM="Le terminal s${AP}active avec --terminal"
HUIT="[\"Ajuster à l${AP}écran\",\"Cadrer la sélection et ses voisins\",\"Monter d${AP}un niveau\",\"Afficher ou masquer le détail\","
HUIT="$HUIT\"Zoom avant\",\"Zoom arrière\",\"$GIT\",\"Afficher les raccourcis\"]"
BASC="Basculer couloirs, liste, graphe"

echo "=== PA1 — « >git » ouvre l${AP}historique Git, sans rien envoyer ; rôles ARIA ==="
chk "PA1.1 — « >git » : une rangée « Ouvrir l${AP}historique Git » avec le kbd G ; Entrée : palette fermée, tiroir ouvert, focus sur son titre, 0 envoi" \
  "[j.pa1.lignes[0].lib, j.pa1.lignes[0].kbd, j.pa1.git.ferme, j.pa1.git.foc, j.pa1.git.envoi]" "[\"$GIT\",[\"G\"],true,\"vf-git-titre-t\",0]"
chk "PA1.2 — boîte dialog modale nommée, champ combobox, liste listbox, groupes, aria-activedescendant sur une option qui suit ↓" \
  "[j.pa1.aria.dialog, j.pa1.aria.modal, j.pa1.aria.nom, j.pa1.aria.combo, j.pa1.aria.etendu, j.pa1.aria.ctrl, j.pa1.aria.liste, j.pa1.aria.option,
    j.pa1.aria.groupes > 0, j.pa1.aria.a1[1], j.pa1.aria.a1[0] !== j.pa1.aria.a0]" \
  '["dialog","true","Rechercher ou lancer une action","combobox","true","results","listbox",true,true,true,true]'

echo "=== PA2 — actions, mode >, copie du lien, question, onglets, focus, ligne du terminal ==="
chk "PA2.1 — champ vide, une sélection : les huit usuelles dans l${AP}ordre, puis « Aller à Projet », « Aller à Équipe », puis les entités" \
  "j.pa2.vide.libs.slice(0, 8)" "$HUIT"
chk "PA2.1b — suite : les onglets (Code absent), des entités ; les raccourcis en kbd ; intitulés de groupe affichés" \
  "[j.pa2.vide.libs.slice(8), j.pa2.vide.plus > 10, j.pa2.vide.kbd.join('|'), j.pa2.vide.titres.length]" \
  '[["Aller à Projet","Aller à Équipe"],true,"F|C|Retour arrière|P|+|-|G|?",3]'
chk "PA2.2 — « > » : actions seules, sans intitulé de groupe, pastille « Actions », aucune rangée grisée ; sans sélection, « Cadrer… » absente ; \
« Basculer… » absente sur Code" \
  "[j.pa2.actions.libs.every((x) => !/^Aller à|^Phase/.test(x)), j.pa2.actions.titres, j.pa2.actions.pastille, j.pa2.actions.grises,
    j.pa2.actions.libs.includes('$BASC'), j.pa2.sansSel.includes('Cadrer la sélection et ses voisins')]" \
  '[true,0,[false,"Actions"],0,false,false]'
chk "PA2.2b — sur Projet, « $BASC » est présente" "j.pa2.projetActions.includes('$BASC')" "true"
chk "PA2.3 — « Copier le lien de cette vue » : adresse complète écrite, toast « Lien copié », focus revenu ; \
refus : « Copie impossible. Le lien est dans la barre d${AP}adresse. »" \
  "[j.pa2.lien.ecrit.length === 1 && j.pa2.lien.ecrit[0] === j.pa2.lien.href, j.pa2.lien.toast, j.pa2.lien.foc, j.pa2.lienKo]" \
  "[true,\"Lien copié\",\"btn-panel\",\"Copie impossible. Le lien est dans la barre d${AP}adresse.\"]"
chk "PA2.4 — « Poser une question à l${AP}agent » : focus dans la barre, rien d${AP}envoyé (0 POST, 0 /api/), le texte saisi après le libellé y est posé" \
  "[j.pa2.question.foc, j.pa2.question.valeur, j.pa2.question.envoi, j.pa2.questionTexte]" '["ask-input","",0,"pourquoi"]'
chk "PA2.5 — « Aller à Projet » : même fenêtre, focus posé ; après « Aller à Équipe » avec une pile de Retour, VF_PANNEAU est absent ou vide" \
  "[j.pa2.projet.memeFenetre, j.pa2.projet.foc !== 'BODY', j.pa2.equipe.taille >= 1,
    j.pa2.equipe.pile === 'absent' || j.pa2.equipe.pile === 0]" "[true,true,true,true]"
chk "PA2.6 — Ajuster et Zoom : carte itinérante ; Afficher ou masquer le détail : #btn-panel ; Monter : carte itinérante" \
  "[j.pa2.focus.ajuster[1], j.pa2.focus.zoom[1], j.pa2.focus.detail[0], j.pa2.focus.monter]" "[true,true,\"btn-panel\",true]"
chk "PA2.7 — texte visible de la palette : aucun mot anglais du moteur" \
  "/\\b(Choose|Open|Close|Entities|Search|No results|navigate)\\b/.test(j.pa2.vide.texte)" "false"
chk "PA2.8 — sans --terminal : « terminal » et « >terminal » : une rangée au texte exact, sans kbd ; Entrée : palette fermée, \
focus rendu ; 0 requête, aucun nœud du terminal" \
  "[j.pa2.terminal.l1.map((x) => [x.lib, x.kbd]), j.pa2.terminal.l2.map((x) => [x.lib, x.kbd]), j.pa2.terminal.ferme, j.pa2.terminal.foc,
    j.pa2.terminal.requetes, j.pa2.terminal.noeuds]" "[[[\"$TERM\",[]]],[[\"$TERM\",[]]],true,\"btn-panel\",0,[0,0]]"
chk "PA2.8b — la ligne n${AP}est pas parmi les huit usuelles du champ vide" "j.pa2.vide.libs.includes(\"$TERM\")" "false"

echo "=== PA3 — phases et agents par VF_ETAT, état vide, requête hostile, formes, fichiers servis ==="
chk "PA3.1 — sur Code, « socle » : groupe « Phases » avec « Phase 1 · Socle », aucune requête ; Entrée : Projet sans rechargement, phase sélectionnée" \
  "[j.pa3.phases.l.some((x) => x.lib === 'Phase 1 · Socle'), j.pa3.phases.groupes.includes('Phases'), j.pa3.phases.requetes,
    j.pa3.phases.arrivee.memeFenetre, j.pa3.phases.arrivee.sel]" '[true,true,0,true,"n:ph-1"]'
chk "PA3.1b — sur Projet, « coder » : une rangée « Agents » (rôle et nom court), aucune requête" \
  "[j.pa3.agents.l.map((x) => x.lib), j.pa3.agents.requetes]" '[["vf-coder"],0]'
chk "PA3.2 — aucun texte de mandat ni de titre dans une rangée « Agents »" "/SECRET/.test(j.pa3.agents.texte)" "false"
chk "PA3.3 — « zzz » : deux lignes d${AP}état vide, annonce « Aucun résultat » ; requête hostile rendue en texte, window.__p indéfini" \
  "[j.pa3.vide.en, j.pa3.vide.ed, j.pa3.vide.live, j.pa3.hostile.p, j.pa3.hostile.img, j.pa3.hostile.texte.includes('<img')]" \
  '["Aucun résultat pour « zzz »","Essayez un nom de fichier, ou tapez > pour les actions.","Aucun résultat","undefined",0,true]'
chk "PA3.4 — 390 px au doigt : rangées de 44 px, pied masqué ; 800 px à la souris : rangées de 36 px, pied visible" \
  "[j.pa3.tactile.grossier, j.pa3.tactile.h, j.pa3.tactile.pied, j.pa3.moyen.grossier, j.pa3.moyen.h, j.pa3.moyen.pied !== 'none']" \
  '[true,[44],"none",false,[36],true]'
OK07=false; [ "$C07" = 200 ] && grep -qF VF_RACCOURCIS "$WORK/f07.js" && OK07=true
OK79=false; [ "$C79" = 200 ] && grep -qF 'vibeflow:fr' "$WORK/f79.js" && OK79=true
chk "PA3.5 — les deux fichiers sont servis (200, corps attendu) et chargés ; après deux allers-retours, chaque action une fois, la ligne du terminal une fois" \
  "[$OK07, $OK79, j.pa3.ressources, j.pa3.doubles]" '[true,true,[true,true],{"huit":[1,1,1,1,1,1,1,1],"terminal":1}]'
chk "PA9 — témoin : aucune section du pilote n${AP}a échoué" "Object.entries(j.erreurs).map(([k, v]) => k + ' ' + v).join(' | ')" ""

echo "=== PA2.8t — avec --terminal : même rangée, même texte, aucun nœud du terminal créé par la palette ==="
LAB2="$WORK/lab2"; cp -R "$LAB" "$LAB2"; rm -rf "$LAB2/.vibeflow"; build_serve "$LAB2" --terminal
assert_eq "PA0t — serveur du lab --terminal démarré" "$([ "$PORT" -gt 0 ] && echo oui || echo non)" "oui"
R="$(mesurer term)"; [ -n "${SONDE:-}" ] && { printf '%s\n' "$R"; cat "$WORK/mesure.err"; }; vf_hyg_stop "$SRV"
chk "PA2.8t — avec --terminal : une rangée au même texte exact, sans kbd ; la palette ne crée ni requête ni nœud du terminal" \
  "[j.pa2.termAvec.lignes.map((x) => x.lib), j.pa2.termAvec.lignes[0].kbd, j.pa2.termAvec.apres === j.pa2.termAvec.avant, j.pa2.termAvec.requetes]" \
  "[[\"$TERM\"],[],true,0]"
chk "PA9t — témoin : aucune section du pilote n${AP}a échoué (--terminal)" "Object.entries(j.erreurs).map(([k, v]) => k + ' ' + v).join(' | ')" ""
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
