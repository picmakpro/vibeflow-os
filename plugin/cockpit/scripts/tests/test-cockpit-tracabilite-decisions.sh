#!/usr/bin/env bash
# test-cockpit-tracabilite-decisions.sh — décisions et ce qui les relie : ADR de docs/ADR.md, définitions des registres de phase, commits citants
#   (TRAC-05 côté données, TRAC-06 ; P76-D-09, D-10, D-16, D-17, D-18)
#   T5 ADR, définitions préfixées et nues, arêtes lues, citation nue jamais reliée · T6 passage git borné et durci (argv, borne, délai, corps jeté, sujet, lab sans git)
# Dépôts fabriqués sous mktemp (auteur et dates fixés, aucun dépôt distant). Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME=Alice GIT_AUTHOR_EMAIL=a@t.test GIT_COMMITTER_NAME=Alice GIT_COMMITTER_EMAIL=a@t.test
export GIT_AUTHOR_DATE="2026-01-15T12:00:00" GIT_COMMITTER_DATE="2026-01-15T12:00:00"
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"
AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home" "$WORK/wrap"
export HOME="$WORK/home"
GIT_REEL="$(command -v git)"
trap 'vf_hyg_fin; [ -n "${KEEP:-}" ] || { chmod -R u+rwx "$WORK" 2>/dev/null; rm -rf "$WORK"; }' EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init

# Emballage de git en tête du PATH : repose l'isolation APRÈS le nettoyage des GIT_* par le serveur, journalise l'argv (un argument par ligne,
# `--8<--` entre deux appels) ; si $WORK/lent existe, l'appel `log` dort 30 s (variable GIT_* retirée de l'environnement : le drapeau est un fichier).
cat > "$WORK/wrap/git" <<EOS
#!/bin/sh
{ for a in "\$@"; do printf '%s\n' "\$a"; done; echo '--8<--'; } >> "$WORK/argv.log"
case " \$* " in *" log "*) [ -e "$WORK/lent" ] && exec sleep 30;; esac
GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null exec "$GIT_REEL" "\$@"
EOS
chmod +x "$WORK/wrap/git"; export PATH="$WORK/wrap:$PATH"

PASS=0; FAIL=0
assert_eq() { if [ "$#" -ne 3 ]; then echo "  ❌ FAIL — $1 (assert_eq : $# arguments au lieu de 3)"; FAIL=$((FAIL+1)); elif [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }

# j.mjs <fichier|-> <expression sur j> : JSON lu dans le fichier, expression évaluée
cat > "$AUX/j.mjs" <<'JS'
import fs from 'node:fs';
let j; try { j = JSON.parse(fs.readFileSync(process.argv[2] === '-' ? 0 : process.argv[2], 'utf8')); } catch { console.log('illisible'); process.exit(0); }
if (j && j.erreur === 'module-absent') { console.log('absent'); process.exit(0); }
const v = new Function('j', 'return (' + process.argv[3] + ')')(j);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
J() { node "$AUX/j.mjs" "$1" "$2" 2>/dev/null || echo "illisible"; }

# decisions.mjs <scripts> <lab> [max] [fin_ms] : lit docs/ADR.md et les *-CONTEXT.md, appelle teteSha, commitsCitants et relier, imprime le JSON (Maps converties).
# Module absent : {"erreur":"module-absent"} (le rouge est une assertion, jamais un plantage).
cat > "$AUX/decisions.mjs" <<'JS'
import path from 'node:path';
import fs from 'node:fs';
const [, , scripts, lab, max, finMs] = process.argv;
let R, T, P, PL;
try {
  R = await import(path.join(scripts, 'vf-cockpit-registres.mjs'));
  T = await import(path.join(scripts, 'vf-cockpit-trace-git.mjs'));
  P = await import(path.join(scripts, 'vf-cockpit-paths.mjs'));
  PL = await import(path.join(scripts, 'vf-cockpit-planning.mjs'));
} catch (e) { console.log(JSON.stringify({ erreur: 'module-absent', detail: String(e.message).slice(0, 120) })); process.exit(0); }
const lire = (f) => PL.lireConfine(lab, () => PL.read(f));
const adrs = R.sectionsAdr(lire(path.join(lab, 'docs', 'ADR.md')));
const definitions = [];
const base = path.join(lab, '.planning', 'phases');
if (fs.existsSync(base)) for (const d of fs.readdirSync(base).sort()) {
  const dir = path.join(base, d);
  for (const f of fs.readdirSync(dir)) {
    const m = /^(\d+(?:\.\d+)?)-CONTEXT\.md$/.exec(f); if (!m) continue;
    definitions.push(...R.definitionsRegistre(lire(path.join(dir, f)), { phase: 'ph-' + m[1], ws: 'demo', fichier: f, couper: (s, n) => PL.clipMot(s, n) }));
  }
}
const fin = P.finDans(finMs ? Number(finMs) : T.BORNES_TRACE.echeanceMs);
const t0 = Date.now();
const tete = await T.teteSha(lab, { fin });
const cit = tete.sha ? await T.commitsCitants(lab, tete.sha, { fin, ...(max ? { max: Number(max) } : {}) }) : { commits: [], tronque: false, absent: true };
const rel = R.relier({ adrs, definitions, commits: cit.commits });
const obj = (m) => Object.fromEntries(m);
console.log(JSON.stringify({ adrs, definitions, tete, cit, ms: Date.now() - t0, rel: { parAdr: obj(rel.parAdr), parDecision: obj(rel.parDecision), adrSansSection: rel.adrSansSection } }));
JS
D() { node "$AUX/decisions.mjs" "$SCRIPTS" "$@" 2>/dev/null; }   # D <lab> [max] [fin_ms] > sortie JSON
G_() { "$GIT_REEL" "$@"; }

# --- laboratoire fabriqué (hors de tout dépôt parent) ---
LAB="$WORK/lab"; mkdir -p "$LAB/docs"
G_ init -q -b main "$LAB"
printf '%s\n' '# ADR' '' '## ADR-001 : Premier choix' '' 'texte' > "$LAB/docs/ADR.md"
G_ -C "$LAB" add docs/ADR.md; G_ -C "$LAB" commit -q -m "docs: pose les ADR"
G_ -C "$LAB" commit -q --allow-empty -m "feat: suit ADR-001" -m "CORPS-SECRET-76 : détail privé du message"

echo "=== T5 — ADR, décisions, arêtes lues ==="
D "$LAB" > "$WORK/o51.json"
Q51='(() => { const c = j.cit.commits.find((x) => x.sujet.includes("suit ADR-001")); const a = j.rel.parAdr["ADR-001"].commits; return [a.length === 1 && a[0] === c.h7, c.h7.length, /^\d{4}-\d{2}-\d{2}$/.test(c.jour), JSON.stringify(j).includes("CORPS-SECRET-76")].join("|"); })()'
assert_eq "T5.1 — le commit qui cite ADR-001 est relié à la section (h7, jour, sujet) et son corps n'est pas servi" "$(J "$WORK/o51.json" "$Q51")" "true|7|true|false"
assert_eq "T5.2 — témoin positif : le corps du commit contient bien le marqueur dans git" "$(G_ -C "$LAB" log -1 --format=%B | grep -c 'CORPS-SECRET-76')" "1"

echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
TOTAL=$((PASS+FAIL))
if [ "$TOTAL" -eq 0 ]; then echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée, résultat non fiable"; exit 1; fi
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
