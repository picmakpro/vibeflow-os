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

# --- second laboratoire : sections ADR, registres de phase (entière et décimale), commits citants ---
L2="$WORK/lab2"; mkdir -p "$L2/docs" "$L2/.planning/phases/90-demo" "$L2/.planning/phases/90.5-pointe"
G_ init -q -b main "$L2"
{ printf '%s\n' '# ADR' '' '## ADR-001 : Premier choix' '' 'texte' '' '## ADR-002 — Second choix' '' '```' '## ADR-099 : faux' '```'; } > "$L2/docs/ADR.md"
LONG="mot0 mot1 mot2 mot3 mot4 mot5 mot6 mot7 mot8 mot9 mot10 mot11 mot12 mot13 mot14 mot15 mot16 mot17 mot18 mot19 mot20 mot21 mot22 mot23 mot24 mot25 mot26"
{ printf '%s\n' '- **P90-D-01 (choix) :** choix retenu, suit ADR-001' '- **P90-D-01 (amendé) :** reprise du choix' '- **D-04 :** décision nue' '### Arbitrage D-05' '```' '- **P90-D-09 :** dans un bloc de code' '```'; echo "- **P90-D-07 :** **gras** et \`code\` $LONG"; } > "$L2/.planning/phases/90-demo/90-CONTEXT.md"
printf '%s\n' '- **P90.5-D-01 (pointé) :** décision de la phase décimale' '- **P90.5-D-02 :** seconde décision' > "$L2/.planning/phases/90.5-pointe/90.5-CONTEXT.md"
G_ -C "$L2" add -A; G_ -C "$L2" commit -q -m "docs: pose les registres"
G_ -C "$L2" commit -q --allow-empty -m "feat: ajoute ADR-007"
G_ -C "$L2" commit -q --allow-empty -m "feat: met en oeuvre P90-D-01"
G_ -C "$L2" commit -q --allow-empty -m "applique D-04, suit ADR-001"
G_ -C "$L2" commit -q --allow-empty -m "fix: suit P90.5-D-01"
H_() { G_ -C "$L2" log --format=%h -1 --grep="$1"; }
D "$L2" > "$WORK/o52.json"
Q53='JSON.stringify([j.adrs.map((a) => a.id), j.adrs.map((a) => a.titre), j.rel.adrSansSection.includes("ADR-007"), j.rel.parAdr["ADR-099"] === undefined])'
assert_eq "T5.3 — deux sections lues (tiret cadratin toléré), ADR-099 en bloc de code ignorée, ADR-007 citée sans section" "$(J "$WORK/o52.json" "$Q53")" '[["ADR-001","ADR-002"],["Premier choix","Second choix"],true,true]'
Q54='JSON.stringify(["P90-D-01","D-04","D-05","P90-D-09"].map((i) => j.definitions.filter((d) => d.id === i).length).concat(j.definitions.filter((d) => d.id === "P90-D-01").map((d) => [d.amendee, d.adr, d.nue, d.cle, d.ligne]), j.definitions.filter((d) => d.id === "D-04").map((d) => [d.nue, d.cle]), j.definitions.filter((d) => /^P90\.5-/.test(d.id)).map((d) => [d.id, d.nue, d.cle])))'
assert_eq "T5.4 — définitions : doublon en une entrée amendée, nue qualifiée par sa phase, titre ### et bloc de code ignorés, phase décimale lue" "$(J "$WORK/o52.json" "$Q54")" '[1,1,0,0,[true,["ADR-001"],false,"P90-D-01:ph-90",1],[true,"D-04:ph-90"],["P90.5-D-01",false,"P90.5-D-01:ph-90.5"],["P90.5-D-02",false,"P90.5-D-02:ph-90.5"]]'
assert_eq "T5.4 — témoin positif : le registre 90.5 du lab porte deux lignes de définition" "$(grep -c '^- \*\*P90.5-D-' "$L2/.planning/phases/90.5-pointe/90.5-CONTEXT.md")" "2"
Q54B="JSON.stringify(j.rel.parDecision['P90.5-D-01:ph-90.5'].commits)"
assert_eq "T5.4 — un commit qui cite P90.5-D-01 est relié à la définition de la phase décimale" "$(J "$WORK/o52.json" "$Q54B")" "[\"$(H_ 'suit P90.5-D-01')\"]"
Q55='JSON.stringify([j.rel.parDecision["P90-D-01:ph-90"].commits, j.rel.parDecision["D-04:ph-90"].commits, j.rel.parAdr["ADR-001"].commits])'
assert_eq "T5.5 — décision préfixée reliée à son commit, nue sans commit, le commit « D-04 » remonté par son ADR" "$(J "$WORK/o52.json" "$Q55")" "[[\"$(H_ 'met en oeuvre P90-D-01')\"],[],[\"$(H_ 'applique D-04')\"]]"
assert_eq "T5.5 — témoin positif : le commit contient bien « D-04 » dans git" "$(G_ -C "$L2" log --format=%h --grep='D-04' | grep -c .)" "1"
Q56='JSON.stringify([j.rel.parAdr["ADR-001"].decisions, Object.keys(j).concat(Object.keys(j.rel)).some((k) => /exigence/i.test(k))])'
assert_eq "T5.6 — ADR -> décisions : arête lue dans la ligne de définition, aucune arête exigence -> décision" "$(J "$WORK/o52.json" "$Q56")" '[["P90-D-01:ph-90"],false]'
Q57='JSON.stringify(j.definitions.filter((d) => d.id === "P90-D-07").map((d) => [d.titre.length <= 80, d.titre.length > 20, /\*\*|`/.test(d.titre)]))'
assert_eq "T5.7 — titre de 150 caractères et plus coupé à 80 au plus, sans gras ni accent grave" "$(J "$WORK/o52.json" "$Q57")" "[[true,true,false]]"

echo "=== T6 — passage git borné et durci ==="
# argv.mjs <journal> : appels git journalisés par l'emballage -> JSON { log: [argv], revparse: [argv], tous: [argv...] }
cat > "$AUX/argv.mjs" <<'JS'
import fs from 'node:fs';
const blocs = fs.readFileSync(process.argv[2], 'utf8').split('--8<--\n').map((b) => b.split('\n').filter((l) => l !== '')).filter((b) => b.length);
const pas = (b, nom) => b.includes(nom);
console.log(JSON.stringify({ log: blocs.filter((b) => pas(b, 'log')), revparse: blocs.filter((b) => pas(b, 'rev-parse') && pas(b, 'HEAD')), tous: blocs.flat() }));
JS
: > "$WORK/argv.log"
D "$L2" > "$WORK/o61.json"
node "$AUX/argv.mjs" "$WORK/argv.log" > "$WORK/a61.json"
Q61='(() => { const l = j.log[0] || []; const i = l.indexOf("--end-of-options"); return [j.log.length, i > 0 && /^[0-9a-f]{40}$/.test(l[i + 1]) && l[i + 2] === "--" && l.length === i + 3, l.includes("--max-count=2000"), j.tous.includes("--all"), j.revparse.length > 0 && j.revparse.every((r) => r.includes("--verify") && r.includes("--end-of-options"))].join("|"); })()'
assert_eq "T6.1 — argv : --end-of-options, sha de 40 caractères, --, --max-count=2000, jamais --all, rev-parse --verify --end-of-options" "$(J "$WORK/a61.json" "$Q61")" "1|true|true|false|true"

# trois commits de plus que la borne de la sonde : cinq commits citants
L3="$WORK/lab3"; mkdir -p "$L3"; G_ init -q -b main "$L3"
for i in 1 2 3 4 5; do G_ -C "$L3" commit -q --allow-empty -m "feat: suit ADR-001 ($i)"; done
G_ -C "$L3" commit -q --allow-empty -m "chore: sans citation"
D "$L3" 3 > "$WORK/o62a.json"; D "$L3" 10 > "$WORK/o62b.json"
Q62='[j.cit.commits.length, j.cit.tronque].join("|")'
assert_eq "T6.2 — borne max=3 sur cinq commits citants : 3 commits, tronque" "$(J "$WORK/o62a.json" "$Q62")" "3|true"
assert_eq "T6.2 — témoin positif : max=10 rend les 5 commits, tronque faux" "$(J "$WORK/o62b.json" "$Q62")" "5|false"

# git qui dort 30 s sur `log` : l'échéance coupe, la sonde rend tronque sans attendre
touch "$WORK/lent"
D "$L3" 10 1500 > "$WORK/o63.json"
rm -f "$WORK/lent"
Q63='[j.tete.sha !== null, j.cit.tronque, j.ms < 5000].join("|")'
assert_eq "T6.3 — délai : tronque vrai, retour en moins de 5 s malgré un git qui dort 30 s" "$(J "$WORK/o63.json" "$Q63")" "true|true|true"

# corps de 300 Kio : lu pour les citations, jamais servi
L4="$WORK/lab4"; mkdir -p "$L4"; G_ init -q -b main "$L4"
{ printf 'feat: suit ADR-001\n\n'; i=0; while [ "$i" -lt 4000 ]; do printf 'ligne de corps numero %05d xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\n' "$i"; i=$((i+1)); done; echo 'GROS-CORPS-76 fin'; } > "$WORK/corps.txt"
G_ -C "$L4" commit -q --allow-empty -F "$WORK/corps.txt"
D "$L4" > "$WORK/o64.json"
Q64='[j.rel.parAdr["ADR-001"].commits.length, JSON.stringify(j).includes("GROS-CORPS-76"), JSON.stringify(j).includes("ligne de corps"), j.cit.tronque].join("|")'
assert_eq "T6.4 — corps de 300 Kio : commit relié, aucune chaîne du corps dans la sortie, non tronqué" "$(J "$WORK/o64.json" "$Q64")" "1|false|false|false"
assert_eq "T6.4 — témoin positif : le marqueur est dans git log --format=%B" "$(G_ -C "$L4" log -1 --format=%B | grep -c 'GROS-CORPS-76')" "1"
assert_eq "T6.4 — témoin de taille : le corps dépasse 250 Kio" "$([ "$(G_ -C "$L4" log -1 --format=%B | wc -c)" -gt 256000 ] && echo oui)" "oui"

# sujet hostile : séquence de contrôle et faux secret d'une forme de MASQUES (jeton GitHub assemblé à l'exécution)
L5="$WORK/lab5"; mkdir -p "$L5"; G_ init -q -b main "$L5"
FAUX="$(printf 'gh%s_%s' p aaaaaaaaaaaaaaaaaaaaaaaaaaaa)"
printf 'feat: suit ADR-001 \033[31mrouge\007 %s fin\n' "$FAUX" > "$WORK/hostile.txt"
G_ -C "$L5" commit -q --allow-empty -F "$WORK/hostile.txt"
D "$L5" > "$WORK/o65.json"
Q65='(() => { const s = j.cit.commits[0].sujet; return [/[\u0000-\u001f\u007f-\u009f]/.test(s), s.includes("[masqué]"), s.includes("ghp_")].join("|"); })()'
assert_eq "T6.5 — sujet hostile : contrôles retirés, secret remplacé par [masqué]" "$(J "$WORK/o65.json" "$Q65")" "false|true|false"
assert_eq "T6.5 — témoin positif : le sujet brut de git porte la séquence d'échappement et le faux secret" "$(G_ -C "$L5" log -1 --format=%s | grep -c "$(printf '\033').*ghp_")" "1"

# lab sans git : aucun log lancé, aucune exception
NG="$WORK/nogit"; mkdir -p "$NG"
: > "$WORK/argv.log"
D "$NG" > "$WORK/o66.json"
Q66='JSON.stringify([j.tete, j.cit.commits.length, j.erreur === undefined])'
assert_eq "T6.6 — lab sans git : teteSha rend { sha: null, absent: true }, aucun commit, aucune exception" "$(J "$WORK/o66.json" "$Q66")" '[{"sha":null,"absent":true},0,true]'
assert_eq "T6.6 — aucun appel log lancé" "$(grep -c '^log$' "$WORK/argv.log")" "0"

echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
TOTAL=$((PASS+FAIL))
if [ "$TOTAL" -eq 0 ]; then echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée, résultat non fiable"; exit 1; fi
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
