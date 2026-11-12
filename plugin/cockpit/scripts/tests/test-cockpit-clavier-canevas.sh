#!/usr/bin/env bash
# test-cockpit-clavier-canevas.sh — le canevas au clavier (80-01, FORM-01, P80-D-10/36/51), un vrai Chrome, de vraies touches, sans réseau.
#   CC1 un seul arrêt de tabulation, flèches vers le voisin spatial, rôle listbox · CC2 noms accessibles (arbre d'accessibilité), Origine/Fin
#   CC3 sélection qui suit le focus (panneau latéral), plongée et remontée, redessin, tiroir Git, repli sur #stage · CC4 feuille de détail
#   CC5 Équipe intacte · CC6 anneau sur la .card (deux thèmes), clic sans anneau, mouvement réduit
#   Mutants (copie du module dans $WORK, jamais le module) : M-VOISIN-DOM, M-REPOSE, M-EQUIPE, M-REPLI-BODY.
#   CC_SCRIPTS = dossier de scripts à bâtir (rejeu sur la base, sans le module).
# Sans navigateur : SUITE SAUTÉE (exit 0, message explicite), jamais un vert à vide.
set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; }
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"; ENG="$SCRIPTS/../skills/cockpit-moteur"
CHROME=""
for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
if [ -z "$CHROME" ]; then
  . "$HERE_T/chrome-saut.sh"
  vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur (Chrome, Chromium) — le clavier du canevas NON vérifié, non compté comme réussi"; exit 0
fi
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0
assert_eq() {
  if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1))
  else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [${2:0:600}]"; FAIL=$((FAIL+1)); fi
}
cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; let j; try { j = JSON.parse(fs.readFileSync(0, 'utf8')); } catch { console.log('sortie illisible'); process.exit(0); }
if (j.erreur) { console.log('mesure indisponible : ' + j.erreur); process.exit(0); }
const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/mut.mjs" <<'JS'
import fs from 'node:fs'; const [, , f, a, b] = process.argv; const t = fs.readFileSync(f, 'utf8');
if (!t.includes(a) || t.split(a).length !== 2) { console.error('mutation impossible : motif absent ou multiple : ' + a); process.exit(1); }
fs.writeFileSync(f, t.replace(a, () => b));
JS
# une session d'équipe (la page Équipe n'est servie que s'il y a de quoi la bâtir)
cat > "$AUX/mk-agents.mjs" <<'JS'
import fs from 'node:fs'; import path from 'node:path';
const [, , home, lab, sid] = process.argv, now = Date.now(), iso = (ms) => new Date(ms).toISOString();
const dir = path.join(home, '.claude', 'projects', '-lab'), sub = path.join(dir, sid, 'subagents'); fs.mkdirSync(sub, { recursive: true });
const base = (o) => ({ cwd: lab, sessionId: sid, gitBranch: 'main', version: '2.1.317', ...o });
const put = (f, l) => fs.writeFileSync(f, l.map((x) => JSON.stringify(x)).join('\n') + '\n');
const msg = (t, ts, c, x = {}) => base({ type: t, timestamp: iso(ts), message: { content: c }, ...x });
const outil = (name, input) => [{ type: 'tool_use', name, input }];
put(path.join(dir, sid + '.jsonl'), [msg('user', now - 600000, 'salut'), msg('assistant', now - 5000, outil('Bash', { command: 'echo a' }))]);
for (const a of [{ id: 'mgr1', d: 1, role: 'vf-dev-manager' }, { id: 'act1', d: 2, p: 'mgr1', role: 'vf-coder' }]) {
  const meta = { agentType: a.role, isBuiltIn: false, description: 'tâche ' + a.id, toolUseId: 'toolu_' + a.id, spawnDepth: a.d, requestShape: 'background' };
  if (a.p) meta.parentAgentId = a.p;
  fs.writeFileSync(path.join(sub, `agent-${a.id}.meta.json`), JSON.stringify(meta));
  put(path.join(sub, `agent-${a.id}.jsonl`), [msg('user', now - 300000, 'mandat', { isSidechain: true, agentId: a.id, parentUuid: null }),
    msg('assistant', now - 4000, [{ type: 'tool_use', name: 'Read', input: { file_path: '/x' } }], { isSidechain: true, agentId: a.id })]);
}
JS
mklab() { # un module avec fichier, un module sans fichier (niveau vide), 13 notes dont une au titre hostile, du code qui s'importe (liens, couches), une phase
  local L="$1" B="$1/.planning"; mkdir -p "$L/src" "$L/plugin/mod/scripts" "$L/plugin/vide" "$B/phases/01-socle" "$L/lots"
  printf "import { b } from './b.js';\nimport { c } from './c.js';\nexport const u = () => b() + c();\n" > "$L/src/util.js"
  printf "import { d } from './d.js';\nexport const b = () => d();\n" > "$L/src/b.js"
  printf "import { d } from './d.js';\nimport { e } from './e.js';\nexport const c = () => d() + e();\n" > "$L/src/c.js"
  printf 'export const d = () => 1;\n' > "$L/src/d.js"; printf "import { d } from './d.js';\nexport const e = () => d();\n" > "$L/src/e.js"
  printf 'export const f = () => 2;\n' > "$L/src/f.js"
  printf '{"name":"mod","type":"skill","description":"Un module de test."}\n' > "$L/plugin/mod/module.json"; echo 1.0.0 > "$L/plugin/mod/VERSION"
  printf '# Module\n' > "$L/plugin/mod/README.md"; printf '#!/usr/bin/env bash\necho run\n' > "$L/plugin/mod/scripts/run.sh"
  printf '{"name":"vide","type":"skill","description":"Sans fichier."}\n' > "$L/plugin/vide/module.json"
  for i in $(seq -w 1 12); do printf '# Note %s\n' "$i" > "$L/lots/n$i.md"; done
  printf '# Piège\n' > "$L/lots/<img src=x onerror=window.__xss=1>.md"
  printf '# Titre du projet\n' > "$B/PROJECT.md"
  printf '# Roadmap\n\n## Jalon démo\n\n- [x] **Phase 1: Socle** - premier jet\n\n### Phase 1: Socle\n**Depends on**: Nothing (first phase)\n' > "$B/ROADMAP.md"
  printf -- '---\nfiles_modified: [plugin/mod/README.md]\n---\n<objective>Faire le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"
  echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
}
# bâtir et servir : build_serve <lab> <dossier de scripts> <dossier du moteur> -> PORT, SRV
build_serve() {
  local L="$1" O="$1/.vibeflow/cockpit"; node "$2/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
  rm -f "$O/.cache/server.json"; mkdir -p "$WORK/fauxbin"
  cp "$SCRIPTS/tests/temoins/fauxbin-claude/claude" "$WORK/fauxbin/claude"; chmod +x "$WORK/fauxbin/claude"
  ( cd "$L" && PATH="$WORK/fauxbin:$PATH" VF_COCKPIT_ENGINE_DIR="$3" VF_COCKPIT_SCRIPTS_DIR="$2" \
      exec node "$O/serve.mjs" --no-open --port "$(libre)" > "$WORK/serve.out" 2>&1 ) </dev/null >/dev/null 2>&1 &
  SRV=$!; PIDS+=($SRV)
  for _ in $(seq 1 300); do grep -q '"port"' "$O/.cache/server.json" 2>/dev/null && break; sleep 0.1; done
  PORT="$(node -e "console.log(JSON.parse(require('fs').readFileSync('$O/.cache/server.json','utf8')).port)" 2>/dev/null || echo 0)"
}
mesurer() { REAL_HOME="$REAL_HOME" node "$HERE_T/chrome-clavier-canevas.mjs" "$CHROME" "http://127.0.0.1:$PORT" "${1:-}" 2>"$WORK/mesure.err"; }
LAB="$WORK/lab"; mklab "$LAB"; node "$AUX/mk-agents.mjs" "$HOME" "$LAB" aaaa1111-2222-3333-4444-555555555555
SC_BASE="${CC_SCRIPTS:-$SCRIPTS}"; ln -s "$SC_BASE" "$WORK/scripts-hote"
build_serve "$LAB" "$WORK/scripts-hote" "$SC_BASE/../skills/cockpit-moteur"
assert_eq "CC0 — serveur du lab démarré" "$([ "$PORT" -gt 0 ] && echo oui || echo non)" "oui"
R="$(mesurer)"; [ -n "${SONDE:-}" ] && { printf '%s\n' "$R"; cat "$WORK/mesure.err"; }; [ -n "${KEEP:-}" ] && printf '%s\n' "$R" > "$WORK/mesure.json"
E() { printf '%s' "${2:-$R}" | node "$AUX/ev.mjs" "$1"; }
UN='[1,1,1,1]'; tt() { echo "j.cc1.mouv.$1.t0"; }

echo "=== CC1 — un arrêt de tabulation, flèches vers le voisin spatial ==="
assert_eq "CC1.1 — le parcours Tab complet ne s'arrête qu'UNE fois dans #svg, sur une carte (le reste de la page garde ses arrêts)" \
  "$(E '[j.cc1.arretsCanevas, j.cc1.carte, j.cc1.arrets > 8]')" "[1,true,true]"
M='j.cc1.mouv'
assert_eq "CC1.2 — → : la carte de droite ; ← : retour ; ↓ : la carte dessous (même colonne) ; ↑ : retour ; une seule carte à tabindex=0" \
  "$(E "[$M.droite.vers !== $M.droite.de && $M.droite.pvers.x > $M.droite.pde.x, $M.gauche.vers === $M.droite.de,
    $M.bas.pvers.y > $M.bas.pde.y && $M.bas.pvers.x === $M.bas.pde.x, $M.haut.vers === $M.bas.de,
    ['droite', 'gauche', 'bas', 'haut'].every((k) => $M[k].t0 === 1)]")" "[true,true,true,true,true]"
assert_eq "CC1.3 — #svg est une listbox nommée « Carte : <niveau>, N cartes »" \
  "$(E '[j.cc1.listbox.role, /^Carte : .+, \d+ cartes$/.test(j.cc1.listbox.nom)]')" '["listbox",true]'
echo "=== CC2 — noms accessibles (arbre d'accessibilité réel), Origine et Fin ==="
N='j.cc2.options.length'
assert_eq "CC2.1a — chaque carte est une option, N = nombre de cartes, la listbox est nommée avec N, ses enfants sont des options" \
  "$(E "[$N === j.cc2.titres.length, $N >= 18, j.cc2.listbox.endsWith(', ' + $N + ' cartes'),
    j.cc2.enfants.length === $N && j.cc2.enfants.every((r) => r === 'option')]")" "[true,true,true,true]"
POS='j.cc2.dom.map((d) => d[1]).sort((a, b) => a - b).join() === Array.from({ length: '$N' }, (_, i) => i + 1).join()'
LIEN='/(, reliée à \d+ cartes?|, aucune liaison)$/.test(o.nom)'
TITRE='j.cc2.dom.slice().sort((a, b) => a[1] - b[1]).every((d, i) => d[0].startsWith(j.cc2.titres.find((t) => t[0] === j.cc2.ordre[i])[1]))'
assert_eq "CC2.1b — posinset et setsize cohérents, nom = titre puis liaisons (« reliée à N carte(s) » ou « aucune liaison »), ordre de lecture" \
  "$(E "[$POS, j.cc2.dom.every((d) => d[2] === $N), j.cc2.options.every((o) => $LIEN), $TITRE]")" "[true,true,true,true]"
assert_eq "CC2.1c — liaisons exactes (D relié à B, C, E ; Util à B et C ; F à personne) ; arêtes, ports et fond cachés (aria-hidden)" \
  "$(E "[['D', 'reliée à 3 cartes'], ['Util', 'reliée à 2 cartes'], ['F', 'aucune liaison']].map((p) =>
    j.cc2.options.some((o) => o.nom.startsWith(p[0] + ',') && o.nom.endsWith(p[1]))).join() + '|' + j.cc2.decor")" "true,true,true|true,true,true"
assert_eq "CC2.1d — T-80-01 : un titre « <img …onerror=… > » du lab est lu tel quel dans le nom, sans img créé ni code exécuté" \
  "$(E '[j.cc2.xss.img, j.cc2.xss.flag, j.cc2.xss.nom]')" "[0,true,1]"
assert_eq "CC2.1e — Projet : le mot d'état de la pastille se lit dans le nom (une carte au moins examinée, aucun écart)" \
  "$(E '[j.cc21p.examinees >= 1, j.cc21p.ecarts]')" "[true,0]"
assert_eq "CC2.2 — Fin : dernière carte en ordre de lecture ; Origine : première ; ↓ au bas, ↑ et ← au haut ne bougent pas (aucune boucle)" \
  "$(E '[j.cc22.fin[0] === j.cc22.fin[1], j.cc22.debut[0] === j.cc22.debut[1], j.cc22.bas[0] === j.cc22.bas[1],
    new Set(j.cc22.haut).size]')" "[true,true,true,1]"
echo "=== CC3 — sélection, plongée, remontée, redessin, tiroir Git, repli ==="
assert_eq "CC3.1 — panneau latéral : la sélection suit le focus ; Échap désélectionne (focus resté) ; Espace resélectionne" \
  "$(E '[j.cc31.suit, j.cc31.echap, j.cc31.espace]')" "[[true,1],[null,true,0],[true,1]]"
assert_eq "CC3.2 — Entrée plonge, focus sur la première carte AU rendu du niveau ; Échap remonte, focus sur la carte quittée, jamais body" \
  "$(E '[j.cc32.niveau !== "root", j.cc32.auRender === j.cc32.premier && j.cc32.premier !== null, j.cc32.apres === j.cc32.premier,
    j.cc32.remonte.c, j.cc32.remonte.id === j.cc32.de, j.cc32.remonte.tag]')" '[true,true,true,"root",true,"g"]'
assert_eq "CC3.3 — un redessin recrée les cartes : le focus est sur la même carte, une seule à tabindex=0" \
  "$(E '[j.cc33.avant === j.cc33.apres && j.cc33.apres !== null, j.cc33.t0]')" "[true,1]"
assert_eq "CC3.4 — tiroir Git ouvert : la carte focalisée est ramenée hors de lui (rectangles disjoints), zoom inchangé" \
  "$(E '[j.cc34.disjoints, j.cc34.gauche >= j.cc34.droit, j.cc34.k[0] === j.cc34.k[1]]')" "[true,true,true]"
for RET in Backspace Escape; do
  assert_eq "CC3.5 ($RET) — niveau sans carte : focus sur #stage (tabindex=-1), jamais body, région live ; au retour, la carte quittée" \
    "$(E "[j.cc35.$RET.focus, j.cc35.$RET.stage, j.cc35.$RET.ti, /^Niveau .+, aucune carte\$/.test(j.cc35.$RET.live), j.cc35.$RET.vide,
      j.cc35.$RET.retour, j.cc35.$RET.role, j.cc35.$RET.nomSvg]")" '["n:m-vide",true,"-1",true,"Nothing inside.",["root","n:m-vide","g"],null,null]'
done
echo "=== CC4 — feuille de détail : 390 px tactile et 800 px pointeur fin ==="
for F in tactile moyen; do
  assert_eq "CC4.1 ($F) — la flèche ne sélectionne pas, Espace sélectionne et ouvre la feuille, Entrée plonge" \
    "$(E "[j.cc4.$F.feuille, j.cc4.$F.fleche, j.cc4.$F.espace, j.cc4.$F.plonge]")" '[true,[true,null],[true,false],"n:m-mod"]'
done
echo "=== CC5 — Équipe : aucune carte ne devient une option ==="
assert_eq "CC5.1 — equipe.html : des cartes (témoin), aucun tabindex (cartes, #svg, #stage), aucun role=option, pas de listbox" \
  "$(E '[j.cc5.cartes > 0, j.cc5.tab, j.cc5.opt, j.cc5.lb, j.cc5.svgTab, j.cc5.stageTab]')" "[true,0,0,null,null,null]"
echo "=== CC6 — anneau sur la .card, mouvement réduit ==="
for TH in sombre clair; do
  assert_eq "CC6.1 ($TH) — anneau de 2 px de la couleur de --ring sur la .card, pas sur le g, avec l'ombre du repos (--shadow-card) et sans l'anneau doux ni l'ombre de .sel" \
    "$(E "[j.cc6.$TH.l, j.cc6.$TH.st, j.cc6.$TH.couleur === j.cc6.$TH.ring, j.cc6.$TH.gOutline, j.cc6.$TH.ombre === j.cc6.$TH.repos]")" \
    '["2px","solid",true,"none",true]'
done
assert_eq "CC6.1c — après un simple clic : focus sur la carte mais aucun contour (anneau réservé au clavier) ; les flèches marchent ensuite" \
  "$(E '[j.cc6.clic.focus, j.cc6.clic.contours, j.cc6.fleche]')" "[true,0,true]"
assert_eq "CC6.2 — mouvement réduit : aucune animation active après flèche, plongée et remontée ; focus posé au rendu" \
  "$(E '[j.cc62.fleche, j.cc62.plongee, j.cc62.remontee, j.cc62.auRender, j.cc62.racine]')" '[0,0,0,true,"root"]'
assert_eq "CC8.1 — focus dans le champ de question : un redessin ne le déplace pas sur une carte" \
  "$(E '[j.cc8.avant, j.cc8.apres]')" '["ask-input","ask-input"]'
assert_eq "CC9 — témoin : aucune section du pilote n'a échoué" "$(E 'Object.keys(j.erreurs).join()')" ""
vf_hyg_stop "$SRV"
# lab à deux modules qui s'importent : le niveau du premier porte un connecteur sortant (CC7)
L2="$WORK/lab2"; mkdir -p "$L2/plugin/m1" "$L2/plugin/m2" "$L2/.planning"; printf '# Deux modules\n' > "$L2/.planning/PROJECT.md"
printf '# Roadmap\n\n## Jalon démo\n\n- [x] **Phase 1: Socle** - premier jet\n\n### Phase 1: Socle\n**Depends on**: Nothing (first phase)\n' > "$L2/.planning/ROADMAP.md"
for m in m1 m2; do printf '{"name":"%s","type":"skill","description":"Module."}\n' "$m" > "$L2/plugin/$m/module.json"; done
printf "import { b } from '../m2/b.js';\nexport const a = () => b();\n" > "$L2/plugin/m1/a.js"; printf 'export const b = () => 1;\n' > "$L2/plugin/m2/b.js"
git -C "$L2" init -q && git -C "$L2" add -A && git -C "$L2" -c user.email=t@t -c user.name=t commit -q -m init
build_serve "$L2" "$WORK/scripts-hote" "$SC_BASE/../skills/cockpit-moteur"; R7="$(mesurer cc7)"; vf_hyg_stop "$SRV"
assert_eq "CC7.1 — niveau à connecteurs : cartes x: options nommées « Vers/Depuis <entité> », jamais l'id interne, comptées dans la liste" \
  "$(E '[j.cc7.x.length >= 1, j.cc7.x.every((c) => c[1] === "option" && /^(Vers|Depuis) [^:]+(, reliée à \d+ cartes?|, aucune liaison)$/.test(c[2]) && !c[2].includes(c[0]))]' "$R7")" "[true,true]"

echo "=== Mutants (copie du module dans \$WORK) ==="
mutant() { # mutant <nom> <ancien> <nouveau> -> RM (mesure du mutant) ; une mutation impossible compte comme un échec
  local M="$WORK/mod-$1" L="$WORK/lab-$1"; mkdir -p "$M/scripts" "$M/skills"
  cp "$SC_BASE"/*.mjs "$SC_BASE"/*.json "$M/scripts/"; cp -R "$SC_BASE/../skills/cockpit-moteur" "$M/skills/cockpit-moteur"
  cp -R "$LAB" "$L"; node "$AUX/mk-agents.mjs" "$HOME" "$L" bbbb1111-2222-3333-4444-555555555555
  if ! node "$AUX/mut.mjs" "$M/skills/cockpit-moteur/assets/ui/04-vf-clavier-canevas.js" "$2" "$3"; then
    echo "  ❌ FAIL — $1 : mutation impossible"; FAIL=$((FAIL+1)); RM="{}"; return
  fi
  build_serve "$L" "$M/scripts" "$M/skills/cockpit-moteur"; RM="$(mesurer)"; vf_hyg_stop "$SRV"; rm -rf "$L"
}
mutant M-VOISIN-DOM "const tous = ordre(), moi = rect(id);" \
  "const tous = ordre(), moi = rect(id); if (dir !== 'debut' && dir !== 'fin') {
    const d = cartes(), j = d.indexOf(id) + (dir === 'gauche' || dir === 'haut' ? -1 : 1); return d[j] || null; }"
assert_eq "M-VOISIN-DOM — le mutant rougit CC1.2 (voisin = carte suivante du DOM) (témoin : CC1.1 reste vert)" \
  "$(E "[$M.bas.pvers.x === $M.bas.pde.x, j.cc1.arretsCanevas]" "$RM")" "[false,1]"
mutant M-REPOSE "if (liste.length) poser(liste, cible);" "if (liste.length && avant !== conteneur) poser(liste, cible);"
assert_eq "M-REPOSE — le mutant rougit CC3.3 (rôle et tabindex non reposés au redessin) (témoin : CC1.1 reste vert)" \
  "$(E '[j.cc33.apres, j.cc1.arretsCanevas]' "$RM")" "[null,1]"
mutant M-EQUIPE "const equipe = () => !!G.meta && G.meta.vfTab === 'equipe';" "const equipe = () => false;"
assert_eq "M-EQUIPE — le mutant rougit CC5.1 (garde d'Équipe retirée : #svg d'Équipe reçoit un tabindex) (témoin : CC1.1 reste vert)" \
  "$(E '[j.cc5.svgTab !== null, j.cc1.arretsCanevas]' "$RM")" "[true,1]"
mutant M-REPLI-BODY "const g = liste.length ? state.chipEls.get(cible) : stage;" "const g = liste.length ? state.chipEls.get(cible) : null;"
assert_eq "M-REPLI-BODY — le mutant rougit CC3.5 (niveau sans carte : le focus reste où le retrait du DOM le laisse) (témoin : CC3.2 reste vert)" \
  "$(E '[j.cc35.Escape.stage, j.cc32.remonte.c]' "$RM")" '[false,"root"]'
mutant M-FOCUS-VOLE "    if (!focusDans) return;" "    void focusDans;"
assert_eq "M-FOCUS-VOLE — le mutant rougit CC8.1 (garde focusDans retirée : le redessin vole le focus) (témoin : CC3.3 reste vert)" \
  "$(E '[j.cc8.apres !== "ask-input", j.cc33.avant === j.cc33.apres]' "$RM")" "[true,true]"
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
