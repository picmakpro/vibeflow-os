#!/usr/bin/env bash
# test-cockpit-aide.sh — l'aide des raccourcis (80-15, FORM-03, FORM-18, P80-D-11/12/13/32/51/55/59), un vrai Chrome.
#   AI1 : « ? » ouvre l'aide filtrée par onglet, rangées du registre, Échap, ligne du terminal (avec et sans --terminal), fichier servi
#   AI2 : palette, saisie et modificateurs, piège à Tab et inert, 1024 × 768, cohérence touche-effet, mouvement réduit, un écouteur, Échap sur Équipe.
#   Régime allégé (consigne de Samuel, session principale, 2026-11-13) : pas de mutant.
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
  vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur (Chrome, Chromium) — l'aide des raccourcis NON vérifiée, non comptée comme réussie"; exit 0
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
# build_serve <lab> [--terminal] -> PORT, SRV, LANCE_RC (module du dépôt).
build_serve() {
  local L="$1" O="$1/.vibeflow/cockpit" flag=() pret=port
  [ "${2:-}" = "--terminal" ] && { flag=(--terminal); pret=terminal; }
  node "$SCRIPTS/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
  mkdir -p "$WORK/fauxbin" "$O/.cache"; rm -f "$O/.cache/terminal-amorce"
  cp "$SCRIPTS/tests/temoins/fauxbin-claude/claude" "$WORK/fauxbin/claude"; chmod +x "$WORK/fauxbin/claude"
  [ -n "${flag[*]:-}" ] && (umask 077; node -e "console.log(require('crypto').randomBytes(32).toString('hex'))" > "$O/.cache/terminal-amorce")
  COCKPIT_MODULE="" COCKPIT_PRET="$pret" COCKPIT_LOG="$WORK/serve.out" cockpit_lancer "$L" PATH="$WORK/fauxbin:$PATH" ${flag[@]+"${flag[@]}"}; LANCE_RC=$?
  SRV="$VF_PID"; PORT="$VF_PORT"
}
mesurer() { REAL_HOME="$REAL_HOME" node "$HERE_T/chrome-aide.mjs" "$CHROME" "http://127.0.0.1:$PORT" "$1" 2>"$WORK/mesure.err"; }
E() { printf '%s' "${2:-$R}" | node "$AUX/ev.mjs" "$1"; }
LAB="$WORK/lab"; mklab "$LAB"; build_serve "$LAB"
assert_eq "AI0 — serveur du lab démarré" "$([ "$PORT" -gt 0 ] && echo oui || echo non)" "oui"
cockpit_get /_vf/ui/60-vf-aide.js > "$WORK/f60.js"; C60="$VF_CODE"
R="$(mesurer base)"; [ -n "${SONDE:-}" ] && { printf '%s\n' "$R"; cat "$WORK/mesure.err"; }; [ -n "${KEEP:-}" ] && printf '%s\n' "$R" > "$WORK/base.json"
vf_hyg_stop "$SRV"
chk() { assert_eq "$1" "$(E "$2")" "$3"; }
AP="'"; TERM="Le terminal s${AP}active avec --terminal"
LIBS="(r) => r.rangees.map((x) => x.lib).sort().join('|')"
REG="(r) => r.map((x) => x.lib).sort().join('|')"
TT="[[[\"$TERM\",[],\"Partout\"]],\"Partout\",[\"$TERM\"],0,true]"

echo "=== AI1 — « ? » ouvre l${AP}aide, rangées du registre, Échap, ligne du terminal, fichier servi ==="
chk "AI1.1 — Code : dialog modal nommé, titre « Raccourcis clavier » (tabindex -1, focus dessus), « Vue : Code », groupes Partout et La carte seuls" \
  "[j.ai1.code.role, j.ai1.code.modal, j.ai1.code.nom, j.ai1.code.titre, j.ai1.code.tabindex, j.ai1.code.foc, j.ai1.code.vue, j.ai1.code.groupes]" \
  '["dialog","true",true,"Raccourcis clavier","-1",true,"Vue : Code",["Partout","La carte"]]'
chk "AI1.2 — chaque rangée est une entrée du registre (Code, Projet), rien de plus ; Entrée et Espace ; C ; ni « bureau » ni « téléphone »" \
  "[($LIBS)(j.ai1.code) === ($REG)(j.ai1.regCode), ($LIBS)(j.ai1.projet) === ($REG)(j.ai1.regProjet),
    j.ai1.projet.groupes.includes('Projet : couloirs et liste'), j.ai1.code.rangees.some((r) => r.lib === 'Sélectionner la carte' && r.kbd[0] === 'Espace'),
    j.ai1.projet.rangees.filter((r) => /^(Plonger dans|Sélectionner) la phase\$/.test(r.lib)).map((r) => r.kbd[0]).join('|'),
    j.ai1.projet.rangees.some((r) => r.lib === 'Cadrer la sélection et ses voisins' && r.kbd[0] === 'C'),
    /bureau|téléphone/i.test(j.ai1.code.texte + j.ai1.projet.texte + j.ai1.mobile.texte)]" \
  '[true,true,true,true,"Entrée|Espace",true,false]'
chk "AI1.3 — Échap ferme l${AP}aide, le focus revient à l${AP}élément d${AP}avant, aucune entrée dans la pile, même fenêtre" \
  "[j.ai1.ferme.ouverte, j.ai1.ferme.foc, j.ai1.ferme.pile, j.ai1.ferme.memeFenetre]" '[false,"btn-panel",false,true]'
chk "AI1.4 — sans --terminal, Code, Projet, Équipe : une rangée « Partout » au texte du registre, sans kbd ; 0 requête, aucun nœud du terminal créé" \
  "['code', 'projet', 'equipe'].map((n) => j.ai1.terminal[n]).map((t) => [t.rangee.map((r) => [r.lib, r.kbd, r.groupe]), t.groupe, t.reg,
    t.requetes, t.apres === t.avant])" "[$TT,$TT,$TT]"
OK60=false; [ "$C60" = 200 ] && grep -qF VF_AIDE "$WORK/f60.js" && OK60=true
chk "AI1.5 — /_vf/ui/60-vf-aide.js rend 200 avec VF_AIDE, la page l${AP}a chargé, window.VF_AIDE est un objet" \
  "[$OK60, j.ai1.ressource]" '[true,[true,"object"]]'

echo "=== AI2 — palette, gardes, piège, mise en page, cohérence touche-effet, un écouteur, Échap ==="
chk "AI2.1 — la palette (« > ») liste « Afficher les raccourcis » ; Entrée ouvre l${AP}aide (focus sur le titre) ; chaque action de la palette est une rangée" \
  "[j.ai2.actions.includes('Afficher les raccourcis'), j.ai2.palette.foc, j.ai2.palette.vue,
    j.ai2.actions.every((x) => j.ai2.palette.rangees.some((r) => r.lib === x))]" '[true,true,"Vue : Code",true]'
chk "AI2.2 — « ? » dans un TEXTAREA : tapé, aide fermée ; ⌘? et Ctrl+? : rien" "[j.ai2.saisie.ouverte, j.ai2.saisie.valeur, j.ai2.modifs]" '[false,"?",false]'
chk "AI2.3 — 30 Tab : focus toujours dans la boîte ; header et #stage inertes pendant, plus après" \
  "[j.ai2.piege.dedans, j.ai2.piege.pendant, j.ai2.piege.apres]" '[true,[true,true],[false,false]]'
chk "AI2.4 — 1024 × 768 : pas de débordement, hauteur ≤ 80 %, défilement interne, deux colonnes ; 390 px : une colonne, pas de débordement" \
  "[j.ai2.large.sw, j.ai2.large.h, j.ai2.large.defile, j.ai2.large.colonnes, j.ai2.etroit.sw, j.ai2.etroit.colonnes]" '[true,true,true,2,true,1]'
chk "AI2.5 — chaque touche du registre de Code produit son effet (+, -, F, C, P, G, Retour arrière, ?)" \
  "Object.entries(j.ai2.effets).filter(([k, v]) => v !== true).map(([k]) => k).join(',') + '/' + Object.keys(j.ai2.effets).length" "/8"
chk "AI2.6 — mouvement réduit : aucune animation active à l${AP}ouverture ni à la fermeture" "j.ai2.piege.anim" "[0,0]"
chk "AI2.7 — deux allers-retours : aucun écouteur de plus, une aide ; sur Équipe Échap ferme l${AP}aide puis revient à la page" \
  "[j.ai2.cycle.ecouteurs, j.ai2.cycle.aides, j.ai2.cycle.vue, j.ai2.equipe.vue, j.ai2.equipe.ferme, j.ai2.equipe.foc, j.ai2.equipe.pile, j.ai2.equipe.recu]" \
  "[0,1,\"Vue : Projet\",\"Vue : Équipe\",true,\"btn-panel\",false,{\"dp\":false}]"
chk "AI9 — témoin : aucune section du pilote n${AP}a échoué" "Object.entries(j.erreurs).map(([k, v]) => k + ' ' + v).join(' | ')" ""

echo "=== AI1.4t — avec --terminal : même rangée, même texte, aucun nœud du terminal créé ==="
LAB2="$WORK/lab2"; cp -R "$LAB" "$LAB2"; rm -rf "$LAB2/.vibeflow"; build_serve "$LAB2" --terminal
assert_eq "AI0t — serveur du lab --terminal démarré" "$([ "$PORT" -gt 0 ] && echo oui || echo non)" "oui"
R="$(mesurer term)"; [ -n "${SONDE:-}" ] && { printf '%s\n' "$R"; cat "$WORK/mesure.err"; }; vf_hyg_stop "$SRV"
chk "AI1.4t — avec --terminal : même rangée au même texte, sans kbd, 0 requête, aucun nœud créé par l${AP}aide" \
  "[j.ai1.termAvec.rangee.map((r) => [r.lib, r.kbd]), j.ai1.termAvec.reg.filter((e) => e.info).map((e) => e.lib), j.ai1.termAvec.requetes,
    j.ai1.termAvec.apres === j.ai1.termAvec.avant]" "[[[\"$TERM\",[]]],[\"$TERM\"],0,true]"
chk "AI9t — témoin : aucune section du pilote n${AP}a échoué (--terminal)" "Object.entries(j.erreurs).map(([k, v]) => k + ' ' + v).join(' | ')" ""
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
