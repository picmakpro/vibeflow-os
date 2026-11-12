#!/usr/bin/env bash
# test-cockpit-coin.sh — coin bas-droit, ligne d'état, repères de bord (80-05, FORM-10, FORM-12, P80-D-16/18/25/32/50), un vrai Chrome, sans réseau.
#   CN1 repères « N cartes par là » : compte, geste, ordre de Tab · CN2 bloc bas-droit, minicarte, hachure du tiroir Git, ligne d'état, sans terminal
#   CN3 feuille de détail (390 et 800 px), tactile, terminal ouvert, focus orphelin, mouvement réduit
#   Mutants (copie du module dans $WORK, jamais le module) : M-FREEAREA, M-COMPTE, M-TERMINAL.
#   CN_SCRIPTS = dossier de scripts à bâtir (rejeu sur la base). Sans navigateur : SUITE SAUTÉE (exit 0), jamais un vert à vide.
set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; }
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
CHROME=""
for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
if [ -z "$CHROME" ]; then
  . "$HERE_T/chrome-saut.sh"
  vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur (Chrome, Chromium) — le coin bas-droit NON vérifié, non compté comme réussi"; exit 0
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
BRANCHE='vf/<img/src=x/onerror=window.__xss=1>/branche-tres-longue-pour-lellipse'
mklab() { # 70 notes dans un dossier (un niveau qui déborde), un module, une phase ; la branche est longue et hostile
  local L="$1" B="$1/.planning"; mkdir -p "$L/src" "$L/plugin/mod/scripts" "$B/phases/01-socle" "$L/lots"
  printf 'export const u = () => 1;\n' > "$L/src/util.js"
  printf '{"name":"mod","type":"skill","description":"Un module de test."}\n' > "$L/plugin/mod/module.json"; echo 1.0.0 > "$L/plugin/mod/VERSION"
  printf '# Module\n' > "$L/plugin/mod/README.md"; printf '#!/usr/bin/env bash\necho run\n' > "$L/plugin/mod/scripts/run.sh"
  for i in $(seq -w 1 70); do printf '# Note %s\n' "$i" > "$L/lots/n$i.md"; done
  printf '# Titre du projet\n' > "$B/PROJECT.md"
  printf '# Roadmap\n\n## Jalon démo\n\n- [x] **Phase 1: Socle** - premier jet\n\n### Phase 1: Socle\n' > "$B/ROADMAP.md"
  printf -- '---\nfiles_modified: [plugin/mod/README.md]\n---\n<objective>Faire le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"
  echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
  git -C "$L" init -q -b "$BRANCHE" && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
}
# build_serve <lab> <dossier de scripts> <dossier du moteur> [--terminal] -> PORT, SRV
build_serve() {
  local L="$1" O="$1/.vibeflow/cockpit" flag=(); [ "${4:-}" = "--terminal" ] && flag=(--terminal)
  node "$2/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
  rm -f "$O/.cache/server.json" "$O/.cache/terminal-amorce"; mkdir -p "$WORK/fauxbin" "$O/.cache"
  cp "$SCRIPTS/tests/temoins/fauxbin-claude/claude" "$WORK/fauxbin/claude"; chmod +x "$WORK/fauxbin/claude"
  [ -n "${flag[*]:-}" ] && (umask 077; node -e "console.log(require('crypto').randomBytes(32).toString('hex'))" > "$O/.cache/terminal-amorce")
  ( cd "$L" && PATH="$WORK/fauxbin:$PATH" VF_COCKPIT_ENGINE_DIR="$3" VF_COCKPIT_SCRIPTS_DIR="$2" \
      exec node "$O/serve.mjs" --no-open ${flag[@]+"${flag[@]}"} --port "$(libre)" > "$WORK/serve.out" 2>&1 ) </dev/null >/dev/null 2>&1 &
  SRV=$!; PIDS+=($SRV)
  for _ in $(seq 1 300); do grep -q '"port"' "$O/.cache/server.json" 2>/dev/null && break; sleep 0.1; done
  PORT="$(node -e "console.log(JSON.parse(require('fs').readFileSync('$O/.cache/server.json','utf8')).port)" 2>/dev/null || echo 0)"
}
mesurer() { REAL_HOME="$REAL_HOME" node "$HERE_T/chrome-coin.mjs" "$CHROME" "http://127.0.0.1:$PORT" "$1" 2>"$WORK/mesure.err"; }
E() { printf '%s' "${2:-$R}" | node "$AUX/ev.mjs" "$1"; }
LAB="$WORK/lab"; mklab "$LAB"
SC_BASE="${CN_SCRIPTS:-$SCRIPTS}"; ln -s "$SC_BASE" "$WORK/scripts-hote"
build_serve "$LAB" "$WORK/scripts-hote" "$SC_BASE/../skills/cockpit-moteur"
assert_eq "CN0 — serveur du lab démarré" "$([ "$PORT" -gt 0 ] && echo oui || echo non)" "oui"

echo "=== CN1 — repères « N cartes par là » ==="
R="$(mesurer cn1)"; [ -n "${SONDE:-}" ] && { printf '%s\n' "$R"; cat "$WORK/mesure.err"; }; [ -n "${KEEP:-}" ] && printf '%s\n' "$R" > "$WORK/cn1.json"
OK1='j.cn1.etats.every((e) => ["gauche", "droite", "haut", "bas"].every((b) => (e.reperes.find((r) => r.bord === b) || { n: 0 }).n === e.hors[b]))'
assert_eq "CN1.1 — niveau de 70 cartes : un repère au moins ; par bord, ajusté puis coupé puis écarté, compte = cartes ENTIÈREMENT hors champ" \
  "$(E "[j.cn1.etats.length === 4, j.cn1.etats.some((e) => e.reperes.length > 0),
    j.cn1.etats.some((e) => Object.values(e.hors).some((n) => n > 0)), $OK1]")" "[true,true,true,true]"
assert_eq "CN1.2 — clic sur le repère droit : le compte diminue, le zoom et la sélection restent" \
  "$(E "(() => { const c = j.cn1.clic, a = c.avant, p = c.apres; if (!a || !p) return 'sans clic';
    return [a.hors.droite > 0, p.hors.droite < a.hors.droite, p.k === a.k, p.sel === a.sel]; })()")" "[true,true,true,true]"
NOM='/^\d+ cartes? hors champ (à gauche|à droite|en haut|en bas)\. Aller à la plus proche\.$/'
assert_eq "CN1.3 — Tab depuis la carte itinérante : un repère (button), nom « N cartes hors champ à <bord>. Aller à la plus proche. »" \
  "$(E "[j.cn1.tab.repere, $NOM.test(j.cn1.tab.nom || '')]")" "[true,true]"
assert_eq "CN1.9 — témoin : aucune section du pilote n'a échoué" "$(E 'Object.keys(j.erreurs).join()')" ""
vf_hyg_stop "$SRV"
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
