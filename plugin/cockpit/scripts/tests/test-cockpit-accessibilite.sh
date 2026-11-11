#!/usr/bin/env bash
# test-cockpit-accessibilite.sh — finitions d'interface immédiates du lot 0 de l'audit du cockpit (AUDC-M7, X4, X6, X7), sans réseau.
#   M7 « Mise en page… » est posé ET peint avant le calcul de mise en page d'un niveau de 70 cartes (jamais un indicateur derrière le calcul)
#   X4 un seul anneau de focus sur tout le parcours au clavier, champ de question compris ; aria-current sur l'onglet actif ; un seul <main>
#   X6 en mouvement réduit : plus de fondu de plongée, plus d'animation décorative (compte des animations actives)
#   X7 un seul format de titre d'onglet du navigateur sur les trois pages : « <Onglet> · <nom> »
# Un Chrome, un profil jetable (chrome-accessibilite.mjs) ; les assertions se lisent sur sa sortie JSON. Lab construit par la suite, dans mktemp.
# Sans navigateur : la suite se déclare SAUTÉE (exit 0, message explicite) — jamais un vert à vide. Exit 0 si tout passe.
set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; }
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
ENG="$SCRIPTS/../skills/cockpit-moteur"
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi; done
if [ -z "$CHROME" ]; then echo "  ⊘ SUITE SAUTÉE : aucun navigateur (Chrome, Chromium) — les finitions d'interface NON vérifiées, non comptées comme réussies"; exit 0; fi
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [${2:0:600}]"; FAIL=$((FAIL+1)); fi; }
cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; let j; try { j = JSON.parse(fs.readFileSync(0, 'utf8')); } catch { console.log('sortie illisible'); process.exit(0); }
if (j.erreur) { console.log('mesure indisponible : ' + j.erreur); process.exit(0); }
const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
# session d'équipe : un manager et deux workers actifs (la page Équipe n'est servie que s'il y a de quoi la bâtir)
cat > "$AUX/mk-agents.mjs" <<'JS'
import fs from 'node:fs'; import path from 'node:path';
const [, , home, lab, sid] = process.argv; const now = Date.now();
const dir = path.join(home, '.claude', 'projects', '-lab'); const sub = path.join(dir, sid, 'subagents'); fs.mkdirSync(sub, { recursive: true });
const iso = (ms) => new Date(ms).toISOString(); const base = (o) => ({ cwd: lab, sessionId: sid, gitBranch: 'main', version: '2.1.317', ...o });
const put = (f, lignes) => fs.writeFileSync(f, lignes.map((l) => JSON.stringify(l)).join('\n') + '\n');
put(path.join(dir, sid + '.jsonl'), [base({ type: 'user', timestamp: iso(now - 600000), message: { content: 'salut' } }), base({ type: 'assistant', timestamp: iso(now - 5000), message: { content: [{ type: 'tool_use', name: 'Bash', input: { command: 'echo bonjour' } }] } })]);
const agents = [{ id: 'mgr1', d: 1, role: 'vf-dev-manager' }, { id: 'act1', d: 2, parent: 'mgr1', role: 'vf-coder' }, { id: 'act2', d: 2, parent: 'mgr1', role: 'vf-coder' }];
for (const a of agents) {
  const meta = { agentType: a.role, isBuiltIn: false, launchedWithDefaults: false, description: 'tâche synthétique ' + a.id, toolUseId: 'toolu_' + a.id, spawnDepth: a.d, requestShape: 'background', requestNonInteractive: true };
  if (a.d >= 2) meta.parentAgentId = a.parent;
  fs.writeFileSync(path.join(sub, `agent-${a.id}.meta.json`), JSON.stringify(meta));
  put(path.join(sub, `agent-${a.id}.jsonl`), [base({ type: 'user', isSidechain: true, agentId: a.id, parentUuid: null, timestamp: iso(now - 300000), message: { role: 'user', content: 'mandat de ' + a.id } }), base({ type: 'assistant', isSidechain: true, agentId: a.id, timestamp: iso(now - 4000), message: { content: [{ type: 'tool_use', name: 'Read', input: { file_path: '/x' } }] } })]);
}
JS
mklab() { # un module, 70 notes dans un même dossier (un niveau de 70 cartes), une phase
  local L="$1" B="$1/.planning"; mkdir -p "$L/src" "$L/plugin/mod/scripts" "$B/phases/01-socle" "$L/lots"
  printf 'export const u = () => 1;\n' > "$L/src/util.js"
  printf '{"name":"mod","type":"skill","description":"Un module de test."}\n' > "$L/plugin/mod/module.json"; echo 1.0.0 > "$L/plugin/mod/VERSION"
  printf '# Module\n\nLancer `run.sh`.\n' > "$L/plugin/mod/README.md"
  printf '#!/usr/bin/env bash\necho run\n' > "$L/plugin/mod/scripts/run.sh"
  for i in $(seq -w 1 70); do printf '# Note %s\n' "$i" > "$L/lots/n$i.md"; done
  printf '# Roadmap\n\n## Jalon démo\n\n- [x] **Phase 1: Socle** - premier jet\n\n### Phase 1: Socle\n**Depends on**: Nothing (first phase)\n' > "$B/ROADMAP.md"
  printf -- '---\nfiles_modified: [plugin/mod/README.md]\n---\n<objective>Faire le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"; echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  node "$SCRIPTS/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
}
LAB="$WORK/lab"; mklab "$LAB"
node "$AUX/mk-agents.mjs" "$HOME" "$LAB" aaaa1111-2222-3333-4444-555555555555
SCRIPTS_HOTE="$WORK/scripts-hote"; ln -s "$SCRIPTS" "$SCRIPTS_HOTE"
O="$LAB/.vibeflow/cockpit"; rm -f "$O/.cache/server.json"
mkdir -p "$WORK/fauxbin"; cp "$SCRIPTS/tests/temoins/fauxbin-claude/claude" "$WORK/fauxbin/claude"; chmod +x "$WORK/fauxbin/claude" # sans « claude » sur le PATH du serveur, le champ de question reste désactivé
( cd "$LAB" && PATH="$WORK/fauxbin:$PATH" VF_COCKPIT_ENGINE_DIR="$ENG" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS_HOTE" exec node "$O/serve.mjs" --no-open --port "$(libre)" > "$WORK/serve.out" 2>&1 ) </dev/null >/dev/null 2>&1 &
SRV_PID=$!; PIDS+=($SRV_PID)
for _ in $(seq 1 300); do grep -q '"port"' "$O/.cache/server.json" 2>/dev/null && break; sleep 0.1; done
PORT="$(node -e "console.log(JSON.parse(require('fs').readFileSync('$O/.cache/server.json','utf8')).port)" 2>/dev/null || echo 0)"
assert_eq "A0 — serveur du lab démarré" "$([ "$PORT" -gt 0 ] && echo oui || echo non)" "oui"
R="$(REAL_HOME="$REAL_HOME" node "$HERE_T/chrome-accessibilite.mjs" "$CHROME" "http://127.0.0.1:$PORT" 2>"$WORK/mesure.err")"
[ -n "${KEEP:-}" ] && printf '%s\n' "$R" > "$WORK/mesure.json"
[ -n "${SONDE:-}" ] && { printf '%s\n' "$R"; cat "$WORK/mesure.err"; }
E() { printf '%s' "$R" | node "$AUX/ev.mjs" "$1"; }

echo "=== M7 — « Mise en page… » posé et peint avant le calcul (AUDC-M7) ==="
assert_eq "M7.0 — témoin : le calcul mesuré est celui d'un niveau d'au moins 70 cartes" "$(E 'j.m7.gros && j.m7.gros.cartes >= 70')" "true"
assert_eq "M7.1 — quand le calcul démarre, l'indicateur est déjà allumé" "$(E 'j.m7.gros.allume')" "true"
assert_eq "M7.2 — … et opaque (pas un fondu qui n'a pas commencé)" "$(E 'j.m7.gros.opacite')" "1"
assert_eq "M7.3 — … et au moins une image a été produite depuis qu'il est allumé (il est peint, pas seulement posé)" "$(E 'j.m7.gros.images >= 1')" "true"
assert_eq "M7.4 — un petit niveau (témoin : moins de 24 cartes) ne clignote pas : l'indicateur reste éteint, sa temporisation de 160 ms inchangée" "$(E 'j.m7.petit.cartes > 0 && j.m7.petit.cartes < 24 && j.m7.petit.allume === false')" "true"
echo "=== X7 — un seul format de titre d'onglet (AUDC-X7) ==="
assert_eq "X7.1 — Code : « Code · <nom> »" "$(E "j.x7.code.titre === 'Code · ' + j.x7.code.nom")" "true"
assert_eq "X7.2 — Projet : « Projet · <nom> »" "$(E "j.x7.projet.titre === 'Projet · ' + j.x7.projet.nom")" "true"
assert_eq "X7.3 — Équipe : « Équipe · <nom> »" "$(E "j.x7.equipe.titre === 'Équipe · ' + j.x7.equipe.nom")" "true"
assert_eq "X7.4 — témoin : le nom du projet est lu et non vide sur les trois pages" "$(E "[j.x7.code, j.x7.projet, j.x7.equipe].every((p) => p.nom.length > 0)")" "true"
echo "=== X4 — un seul anneau de focus, repères d'accessibilité (AUDC-X4) ==="
assert_eq "X4.0 — témoin : le parcours au clavier atteint au moins 15 éléments dont le champ de question" "$(E "j.x4.arrets.length >= 15 && j.x4.arrets.some((a) => a.cle === 'ask-input')")" "true"
assert_eq "X4.1 — chaque arrêt du parcours porte un anneau (aucun sans) — arrêts sans anneau : " "$(E "j.x4.arrets.filter((a) => !a.anneau).map((a) => a.cle).join(',')")" ""
assert_eq "X4.2 — un seul style d'anneau sur tout le parcours (largeur, trait, couleur)" "$(E "new Set(j.x4.arrets.map((a) => a.anneau)).size")" "1"
assert_eq "X4.3 — le champ de question a son anneau" "$(E "!!j.x4.arrets.find((a) => a.cle === 'ask-input').anneau")" "true"
assert_eq "X4.4 — aria-current=page sur l'onglet actif, et sur lui seul (Code, Projet, Équipe)" "$(E "[j.x7.code.courants.join(), j.x7.projet.courants.join(), j.x7.equipe.courants.join()].join('|')")" "Code=page|Projet=page|Équipe=page"
assert_eq "X4.5 — un seul <main> par page (Code, Projet, Équipe)" "$(E "[j.x7.code.main, j.x7.projet.main, j.x7.equipe.main].join('|')")" "1|1|1"
echo "=== X6 — mouvement réduit (AUDC-X6) ==="
assert_eq "X6.0 — témoin : sans préférence, la plongée anime (plus de 20 animations actives) sur un niveau de 70 cartes" "$(E 'j.x6.temoin.cartes >= 70 && j.x6.temoin.actives > 20')" "true"
assert_eq "X6.1 — en mouvement réduit, aucune animation active au repos" "$(E 'j.x6.reduit.repos')" "0"
assert_eq "X6.2 — … ni pendant la plongée (niveau de 70 cartes bien posé)" "$(E 'j.x6.reduit.cartes >= 70 && j.x6.reduit.actives')" "0"
assert_eq "X6.3 — … le fondu et le mouvement de caméra de la plongée durent 0 s" "$(E "j.x6.reduit.transitions.split(',').every((d) => parseFloat(d) === 0)")" "true"
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
