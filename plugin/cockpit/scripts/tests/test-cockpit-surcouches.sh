#!/usr/bin/env bash
# test-cockpit-surcouches.sh — pile unique de surcouches (80-02 : FORM-02, AUDC-M6, P80-D-11, D-34, D-59 a), sans réseau.
#   SU1 palette : Tab hors du champ puis Échap la ferme et rend le focus ; un seul Échap dans le champ ; garde d'unicité (réévaluation du module)
#   SU2 export : 15 Tab restent dans la boîte, Maj+Tab boucle, inert posé puis levé (jamais celui d'un témoin), focus rendu ; palette : 30 Tab
#   SU3 panneau fermé : aucun focalisable (1440 px), focus rendu au bouton, mouvement réduit
#   SU4 tiroirs et Échap : dessus de pile, palette sur tiroir, contrat Échap consommé (Code, Équipe, Terminal), ordre des écouteurs, cas interdit
#   SU5 les trois listes recopiées ont disparu · SU6 coquille de la 79 (en attente : témoin exécutable après la 79)
#   Mutants (copie de la sortie du lab dans $WORK) : M-INERT-TOUT, M-PIEGE, M-PALETTE, M-ECHAP-VIDE, M-SANS-PREVENT, M-UNICITE ; M-PERSISTANT après la 79
# Sans navigateur : la suite se déclare SAUTÉE (exit 0, message explicite) — jamais un vert à vide. Exit 0 si tout passe.
set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; }
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
ENG="$SCRIPTS/../skills/cockpit-moteur"; UI="$ENG/assets/ui"; PILE="$UI/00-vf-surcouches.js"
CHROME=""
for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
if [ -z "$CHROME" ]; then
  . "$HERE_T/chrome-saut.sh"
  vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur — la pile de surcouches NON vérifiée, non comptée comme réussie"; exit 0
fi
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0; MUTANTS=0
assert_eq() {
  if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1))
  else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [${2:0:600}]"; FAIL=$((FAIL+1)); fi
}
cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; let j; try { j = JSON.parse(fs.readFileSync(0, 'utf8')); } catch { console.log('sortie illisible'); process.exit(0); }
if (j.erreur) { console.log('mesure indisponible : ' + j.erreur); process.exit(0); }
const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/chg.mjs" <<'JS'
import fs from 'node:fs'; const [, , a, b] = process.argv; const x = fs.readFileSync(a, 'utf8').split('\n'), y = fs.readFileSync(b, 'utf8').split('\n');
console.log(x.length === y.length ? x.filter((l, i) => l !== y[i]).length : -1);
JS
cat > "$AUX/mk-agents.mjs" <<'JS'
import fs from 'node:fs'; import path from 'node:path';
const [, , home, lab, sid] = process.argv; const now = Date.now(); const iso = (ms) => new Date(ms).toISOString();
const dir = path.join(home, '.claude', 'projects', '-lab'); const sub = path.join(dir, sid, 'subagents'); fs.mkdirSync(sub, { recursive: true });
const base = (o) => ({ cwd: lab, sessionId: sid, gitBranch: 'main', version: '2.1.317', ...o });
const put = (f, l) => fs.writeFileSync(f, l.map((x) => JSON.stringify(x)).join('\n') + '\n');
const outil = (name, input) => ({ content: [{ type: 'tool_use', name, input }] });
put(path.join(dir, sid + '.jsonl'), [base({ type: 'user', timestamp: iso(now - 600000), message: { content: 'salut' } }),
  base({ type: 'assistant', timestamp: iso(now - 5000), message: outil('Bash', { command: 'echo bonjour' }) })]);
const meta = { agentType: 'vf-coder', isBuiltIn: false, launchedWithDefaults: false, description: 'tâche synthétique', toolUseId: 'toolu_a1', spawnDepth: 1 };
fs.writeFileSync(path.join(sub, 'agent-a1.meta.json'), JSON.stringify(meta));
const ag = { isSidechain: true, agentId: 'a1' };
put(path.join(sub, 'agent-a1.jsonl'), [
  base({ type: 'user', ...ag, parentUuid: null, timestamp: iso(now - 300000), message: { role: 'user', content: 'mandat' } }),
  base({ type: 'assistant', ...ag, timestamp: iso(now - 4000), message: outil('Read', { file_path: '/x' }) })]);
JS
mklab() { # un module, une phase, un dépôt git (le tiroir Git et la touche g existent)
  local L="$1" B="$1/.planning" N; N="$WORK/build-$(basename "$1").out"
  mkdir -p "$L/src" "$L/plugin/mod/scripts" "$B/phases/01-socle"
  printf 'export const u = () => 1;\n' > "$L/src/util.js"
  printf '{"name":"mod","type":"skill","description":"Un module de test."}\n' > "$L/plugin/mod/module.json"; echo 1.0.0 > "$L/plugin/mod/VERSION"
  printf '# Module\n\nLancer `run.sh`.\n' > "$L/plugin/mod/README.md"; printf '#!/usr/bin/env bash\necho run\n' > "$L/plugin/mod/scripts/run.sh"
  printf '# Titre du projet\n' > "$B/PROJECT.md"
  printf '# Roadmap\n\n## Jalon démo\n\n- [x] **Phase 1: Socle** - premier jet\n\n### Phase 1: Socle\n**Depends on**: Nothing (first phase)\n' > "$B/ROADMAP.md"
  printf -- '---\nfiles_modified: [plugin/mod/README.md]\n---\n<objective>Faire le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"
  echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
  git -C "$L" init -q -b main && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  node "$SCRIPTS/vf-cockpit-build.mjs" "$L" --quiet > "$N" 2>&1 || cat "$N"
}
SCRIPTS_HOTE="$WORK/scripts-hote"; ln -s "$SCRIPTS" "$SCRIPTS_HOTE"
mkdir -p "$WORK/fauxbin"; cp "$SCRIPTS/tests/temoins/fauxbin-claude/claude" "$WORK/fauxbin/claude"; chmod +x "$WORK/fauxbin/claude"
serve() { # serve <lab> <dossier de sortie> [--terminal] : serveur en fond, port dans SERVED (pas de sous-shell : PIDS doit survivre)
  local lab="$1" o="$2"; shift 2; rm -f "$o/.cache/server.json"; mkdir -p "$o/.cache"
  if [ "${1:-}" = "--terminal" ]; then
    (umask 077; node -e "console.log(require('crypto').randomBytes(32).toString('hex'))" | tr -d '\n' > "$o/.cache/terminal-amorce")
  fi
  ( cd "$lab" && PATH="$WORK/fauxbin:$PATH" SHELL=/bin/sh VF_COCKPIT_TERM_GRACE_MS=5000 VF_COCKPIT_ENGINE_DIR="$ENG" \
      VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS_HOTE" exec node "$o/serve.mjs" --no-open "$@" --port "$(libre)" \
      > "$WORK/serve-$(basename "$o").out" 2>&1 ) </dev/null >/dev/null 2>&1 &
  PIDS+=($!); for _ in $(seq 1 300); do grep -q '"port"' "$o/.cache/server.json" 2>/dev/null && break; sleep 0.1; done
  SERVED="$(node -e "console.log(JSON.parse(require('fs').readFileSync('$o/.cache/server.json','utf8')).port)" 2>/dev/null || echo 0)"
}
LAB="$WORK/lab"; mklab "$LAB"; node "$AUX/mk-agents.mjs" "$HOME" "$LAB" aaaa1111-2222-3333-4444-555555555555
O="$LAB/.vibeflow/cockpit"; serve "$LAB" "$O"; PORT="$SERVED"
assert_eq "A0 — serveur du lab démarré" "$([ "$PORT" -gt 0 ] && echo oui || echo non)" "oui"
TL="$WORK/lab-term"; mklab "$TL"; OT="$TL/.vibeflow/cockpit"; serve "$TL" "$OT" --terminal; PORT_T="$SERVED"
pilote() { # pilote <port> <module> <racine-terminal> <sections>
  REAL_HOME="$REAL_HOME" node "$HERE_T/chrome-surcouches.mjs" "$CHROME" "http://127.0.0.1:$1" "$2" "${3:-}" "${4:-su1,su2,su3,su4}" 2>"$WORK/mesure.err"
}
R="$(pilote "$PORT" "$PILE" "http://127.0.0.1:$PORT_T")"
[ -n "${KEEP:-}" ] && printf '%s\n' "$R" > "$WORK/mesure.json"
[ -n "${SONDE:-}" ] && { printf '%s\n' "$R"; cat "$WORK/mesure.err"; }
E() { printf '%s' "$R" | node "$AUX/ev.mjs" "$1"; }
ok() { assert_eq "$1" "$(E "$2")" "${3:-true}"; } # ok <libellé> <expression sur j> [attendu]

echo "=== SU1 — palette : Tab hors du champ, Échap (AUDC-M6) ==="
ok "SU1.1 — palette ouverte, Tab hors du champ, Échap : fermée, focus rendu à l'élément d'avant" \
  "j.su1.ferme && j.su1.retour === 'btn-export'"
ok "SU1.2 — Échap dans le champ de recherche ferme encore la palette en un appui" 'j.su1.champ'
ok "SU1.3 — le module réévalué ne change ni l'identité de VF_SURCOUCHES ni le nombre d'écouteurs ; SU1.1 reste vrai" \
  "j.su1.api === 'object' && j.su1.identite && j.su1.nouveaux === 0 && j.su1.rejoue"
echo "=== SU2 — modale : piège à Tab, inert suivi, retour à l'ouvreur ==="
ok "SU2.1 — export ouvert, 15 Tab : le focus reste dans la boîte ; Maj+Tab depuis le premier : le dernier" \
  'j.su2.arrets.length === 15 && j.su2.arrets.every(Boolean) && j.su2.maj'
ok "SU2.2 — modale : en-tête, scène et panneau inertes ; fermée par Échap : plus d'inert de la pile, focus sur #btn-export" \
  "j.su2.pendant === 'true,true,true' && j.su2.ferme && j.su2.focus === 'btn-export' \
    && j.su2.apres.split(',').filter((x) => x && x !== 'vf-temoin-inert').length === 0"
ok "SU2.3 — l'élément témoin déjà inert avant l'ouverture l'est encore après la fermeture" \
  "j.su2.avant === 'vf-temoin-inert' && j.su2.apres.split(',').includes('vf-temoin-inert')"
ok "SU2.4 — palette ouverte, 30 Tab : le focus reste dans la boîte" 'j.su2.pal.length === 30 && j.su2.pal.every(Boolean)'
echo "=== SU3 — panneau latéral fermé hors de la tabulation (AUDC-M6) ==="
ok "SU3.1 — 1440 px : panneau ouvert, des focalisables ; fermé (p) : aucun focalisable visible" \
  'j.su3.ouvert > 0 && j.su3.ferme && j.su3.focalisables === 0'
ok "SU3.2 — le focus était dans le panneau que p ferme : il va à #btn-panel" "j.su3.dansPanneau && j.su3.focus === 'btn-panel'"
ok "SU3.3 — mouvement réduit : panneau fermé, visibility: hidden posé sans attendre la transition" 'j.su3.reduit' hidden
echo "=== SU4 — tiroirs, ordre d'Échap et contrat consommé (Phases 73 et 74) ==="
ok "SU4.1 — tiroir Git ouvert, focus sur body : Échap le ferme, la sélection reste ; l'Échap suivant la lève" \
  'j.su4.tiroirFerme && j.su4.selGardee && j.su4.selLevee'
ok "SU4.2 — palette ouverte sur le tiroir Git : Échap ferme la palette, le tiroir reste" 'j.su4.palFerme && j.su4.tiroirResteOuvert'
ok "SU4.3 — dessus() : le tiroir Git seul, puis #palette quand elle est ouverte par-dessus" 'j.su4.dessusTiroir && j.su4.dessusPalette'
ok "SU4.4 — Échap consommé (Code, Équipe) : palette fermée, defaultPrevented vrai pour le témoin, vue non appelée" \
  "['consomme_index', 'consomme_equipe'].every((k) => j.su4[k].ferme && j.su4[k].temoin.length === 1 && j.su4[k].temoin[0] === true && j.su4[k].vue === 0)"
ok "SU4.5 — aucune surcouche : Échap arrive intact à la vue (defaultPrevented faux), Code et Équipe" \
  "['index', 'equipe'].every((k) => j.su4['ouverte_' + k] === false && j.su4['vide_' + k].temoin[0] === false && j.su4['vide_' + k].vue === 1)"
if [ "$(E 'j.su4.terminal && j.su4.terminal.sautee ? 1 : 0')" = "1" ]; then
  echo "  ⊘ SU4.5b SAUTÉ — Terminal non lancé : $(E 'j.su4.terminal.sautee') (non compté comme réussi)"
else
  ok "SU4.5b — focus dans la région du Terminal : la pile n'agit pas (defaultPrevented faux, vue appelée)" \
    'j.su4.terminal.temoin[0] === false && j.su4.terminal.vue === 1 && j.su4.terminal.ouverte === false'
fi
ok "SU4.6 — un seul écouteur Échap de la pile, posé avant tout écouteur d'extension ; palette fermée malgré le cas interdit" \
  'j.su4.ordre.pile === 1 && j.su4.ordre.avantTout && j.su4.ordre.dernier > 0 && j.su4.consomme_index.ferme'
echo "  ℹ cas interdit : constat documenté — un écouteur en capture sur window posé AVANT la pile reçoit l'appui" \
  "avec defaultPrevented = $(E 'j.su4.consomme_index.interdit.slice(-1).join()') (ni PASS ni FAIL de la pile)"
echo "=== SU5 — les listes recopiées ont disparu (retrait 4) ==="
assert_eq "SU5.1 — « #palette.open, #flowmenu.open » absent de 02, 73 et 77 (baseline : 1 dans chacun)" \
  "$(cd "$UI" && grep -lF '#palette.open, #flowmenu.open' 02-vf-telephone.js 73-vf-tiroir-travail.js 77-vf-git-tiroir.js | tr '\n' ',')" ""
echo "=== SU6 — coquille de la 79 ==="
echo "  ⏳ ATTENTE — SU6.1 (coquille de la 79 absente : témoin exécutable après la 79, exigé vert par la jointure)"
echo "=== Mutants (copie de la sortie du lab) ==="
mutant() { # mutant <nom> <sections> <motif sed> <assertion> : copie la sortie et le module, applique le motif, rejoue, attend ROUGE
  local nom="$1" sec="$2" motif="$3" test="$4" m="$WORK/mut-$1" nj nh port RM
  rm -rf "$m"; cp -R "$O" "$m"; cp "$PILE" "$m.js"; sed -i.bak "$motif" "$m/index.html" "$m.js"
  nj="$(node "$AUX/chg.mjs" "$PILE" "$m.js")"; nh="$(node "$AUX/chg.mjs" "$O/index.html" "$m/index.html")"
  { [ "$nj" -ge 1 ] && [ "$nj" = "$nh" ]; } || { echo "  ❌ FAIL — mutant $nom : $nj ligne(s) du module, $nh de la page (attendu : égales, au moins une)"; FAIL=$((FAIL+1)); return; }
  serve "$LAB" "$m"; port="$SERVED"; RM="$(pilote "$port" "$m.js" "" "$sec")"
  if [ "$(printf '%s' "$RM" | node "$AUX/ev.mjs" "$test")" = "false" ]; then
    echo "  ✅ PASS — $nom : le mutant rougit"; PASS=$((PASS+1)); MUTANTS=$((MUTANTS+1))
  else echo "  ❌ FAIL — $nom : le mutant ne rougit pas"; echo "     sortie: ${RM:0:400}"; FAIL=$((FAIL+1)); fi
}
mutant M-INERT-TOUT su2 's#for (const x of e.inertes)#for (const x of document.querySelectorAll("[inert]"))#' \
  "j.su2.apres.split(',').includes('vf-temoin-inert')"
mutant M-PIEGE su2 "s#if (ev.key === 'Tab' && modale)#if (false)#" 'j.su2.arrets.every(Boolean) && j.su2.maj'
mutant M-PALETTE su1 "s#document.getElementById('pal-x').click();#void 0;#" 'j.su1.ferme'
mutant M-ECHAP-VIDE su4 's#{ // vf-echap$#{ ev.preventDefault(); ev.stopPropagation();#' \
  "j.su4.vide_index.temoin[0] === false && j.su4.vide_index.vue === 1"
mutant M-SANS-PREVENT su4 's#const consomme = (ev) => { ev.preventDefault();#const consomme = (ev) => {#' \
  'j.su4.consomme_index.temoin[0] === true'
mutant M-UNICITE su1 's#if (window.VF_SURCOUCHES) return;##' 'j.su1.identite && j.su1.nouveaux === 0'
echo "  ⏳ ATTENTE — M-PERSISTANT (marqueur vf-coquille: persistant retiré : exécutable après la 79, exigé rouge par la jointure)"
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
