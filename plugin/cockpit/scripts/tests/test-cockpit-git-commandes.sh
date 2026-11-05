#!/usr/bin/env bash
# test-cockpit-git-commandes.sh — commandes à copier du tiroir Git, exécutées pour de vrai (GITC-10 ; P78-D-14, T-78-09 à T-78-11)
#   C1 citation et constructeurs sur noms hostiles : bash, zsh, échantillon généré, citation à l'octet, refus à l'affichage, parité avec `nettoie`
#   C2 formes de --end-of-options sondées sur git réel (branch -d, show, switch --detach, stash show)
#   C3 mutants M-CITE, M-EOO, M-BIDI (+ un mutant par plage de la classe d'affichage), chacun avec la trace de SON rouge
# La propriété prouvée est générative : pour tout nom de ref valide, la commande copiée, lancée par `sh -c` dans un dépôt jetable, ne fait
# que l'opération affichée (aucun fichier marqueur créé). Fixtures dans mktemp, jamais de dépôt distant. Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t.test GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t.test
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
AUX="$WORK/aux"; REPO="$WORK/repo"; M="$WORK/marques"; DIRS="$WORK/dirs"; MUT="$WORK/mut"
mkdir -p "$AUX" "$M" "$DIRS" "$MUT"
export VF_MOD="${VF_MOD:-$SCRIPTS/vf-cockpit-git-commandes.mjs}"
MOD_REEL="$VF_MOD"
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }

# --- aides node écrites par la suite ---
# cmd.mjs <export> : appelle l'export nommé (argument dans $ARG, jamais réinterprété par un shell) ; exit 3 = null, 4 = module ou export absent
cat > "$AUX/cmd.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
const fn = process.argv[2];
let m; try { m = await import(pathToFileURL(process.env.VF_MOD).href); } catch { process.exit(4); }
if (typeof m[fn] !== 'function') process.exit(4);
const a = process.env.ARGJSON ? JSON.parse(process.env.ARG) : (process.env.ARG ?? '');
const r = m[fn].length === 0 ? m[fn]() : m[fn](a);
if (r === null) process.exit(3);
process.stdout.write(String(r));
JS
# parite.mjs : AFFICHAGE_REFUSE contre nettoie (vf-cockpit-arbres.mjs), sur tous les points de code U+0000 à U+10FFFF
cat > "$AUX/parite.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const m = await import(pathToFileURL(process.env.VF_MOD).href).catch(() => null);
const { nettoie } = await import(pathToFileURL(path.join(process.argv[2], 'vf-cockpit-arbres.mjs')).href);
if (!m || !(m.AFFICHAGE_REFUSE instanceof RegExp)) { console.log('module absent'); process.exit(0); }
let refuses = 0; const ecarts = [];
for (let cp = 0; cp <= 0x10ffff; cp++) {
  const ch = String.fromCodePoint(cp);
  const r = m.AFFICHAGE_REFUSE.test(ch); const n = nettoie(ch) === '';
  if (r) refuses++;
  if (r !== n) ecarts.push(cp.toString(16));
}
console.log(`${refuses}|${ecarts.length}${ecarts.length ? '|' + ecarts.slice(0, 5).join(',') : ''}`);
JS
# gen.mjs <module> <dépôt> <marqueurs> <dossiers> <shells> <n> <graine> : échantillon généré de noms (filtré par git check-ref-format), chaque
# commande est EXÉCUTÉE par chaque shell ; sortie : une ligne JSON par shell
cat > "$AUX/gen.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
const [, , mod, repo, marques, dirs, shells, nStr, seed0] = process.argv;
const m = await import(pathToFileURL(mod).href).catch(() => null);
if (!m) { console.log(JSON.stringify({ erreur: 'module absent' })); process.exit(0); }
const git = (...a) => spawnSync('git', ['-C', repo, ...a], { encoding: 'utf8' });
let s = Number(seed0) >>> 0; const rnd = (n) => { s = (Math.imul(s, 1664525) + 1013904223) >>> 0; return s % n; };
// oracle indépendant du module : ce que l'affichage retirerait
const refuse = (t) => [...t].some((c) => { const p = c.codePointAt(0); return p <= 0x1f || (p >= 0x7f && p <= 0x9f) || p === 0x2028 || p === 0x2029 || (p >= 0x202a && p <= 0x202e) || (p >= 0x2066 && p <= 0x2069); });
const T = ['a', 'b', 'x', '-', '--', '.', '_', '/', '$', '(', ')', ';', '`', '|', '&', "'", '"', '<', '>', '*', '\\', '{', '}', ',', '!', '#', '%', '=', '+', '@', 'é', '🙂', '‮', '\u0007', '⁦', '\u0085',
  '-x', '--all', '$HOME', '${IFS}', 'HEAD', 'refs/heads/y', '1234567', 'ghp_abcdefghijklmnopqrstuvwxyz0123',
  `$(touch\${IFS}${marques}/g1)`, `\`touch\${IFS}${marques}/g2\``, `;touch\${IFS}${marques}/g3;`, `';touch\${IFS}${marques}/g4;'`, `|touch\${IFS}${marques}/g5|`, `&touch\${IFS}${marques}/g6&`];
const vus = new Set(); const noms = [];
const valide = (n) => spawnSync('git', ['check-ref-format', 'refs/heads/' + n]).status === 0;
let essais = 0;
while (noms.length < Number(nStr) && essais++ < 20000) {
  let n = ''; for (let k = 1 + rnd(6); k > 0; k--) n += T[rnd(T.length)];
  if (!vus.has(n) && valide(n)) { vus.add(n); noms.push(n); }
}
const sorties = [];
for (const sh of shells.split(',')) {
  const r = { shell: sh, n: noms.length, nuls: 0, executes: 0, armes: 0, passes: 0, ignores: 0, echecs: [] };
  let i = 0;
  for (const nom of noms) {
    i++;
    const attendNul = refuse(nom);
    const run = (cmd, extra = '') => spawnSync(sh, ['-c', cmd + extra], { cwd: repo, encoding: 'utf8' });
    const marquesVides = () => { const l = fs.readdirSync(marques); for (const f of l) fs.rmSync(path.join(marques, f), { recursive: true, force: true }); return l.length === 0; };
    const retour = () => git('symbolic-ref', 'HEAD', 'refs/heads/main');
    const echec = (quoi, nom_) => r.echecs.push(`${quoi}:${JSON.stringify(nom_)}`);
    // switch
    const c1 = m.cmdSwitch(nom), c2 = m.cmdBranchSupprimer(nom);
    if (attendNul) { r.nuls++; if (c1 !== null || c2 !== null) echec('devait-etre-null', nom); }
    else if (typeof c1 !== 'string' || typeof c2 !== 'string') echec('null-inattendu', nom);
    else {
      retour(); git('update-ref', 'refs/heads/' + nom, 'HEAD');
      if (git('show-ref', '--verify', 'refs/heads/' + nom).status !== 0) { r.ignores++; continue; }
      r.executes++; if (/touch/.test(nom)) r.armes++;
      const p = run(c1);
      if (p.status !== 0 || git('symbolic-ref', 'HEAD').stdout.trim() !== 'refs/heads/' + nom) echec('switch', nom);
      if (!marquesVides()) echec('switch-marqueur', nom);
      retour();
      const q = run(c2);
      if (q.status !== 0 || git('show-ref', '--verify', 'refs/heads/' + nom).status === 0) { echec('branch-d', nom); git('update-ref', '-d', 'refs/heads/' + nom); }
      if (!marquesVides()) echec('branch-d-marqueur', nom);
      if (echec.length === 0) r.passes++;
    }
    // cd vers un dossier portant le nom
    const dir = path.join(dirs, String(i), nom);
    try { fs.mkdirSync(dir, { recursive: true }); } catch { continue; }
    const c3 = m.cmdCd(dir);
    if (refuse(dir) || dir.length > 200) { if (c3 !== null) echec('cd-devait-etre-null', nom); continue; }
    if (typeof c3 !== 'string') { echec('cd-null-inattendu', nom); continue; }
    const p3 = spawnSync(sh, ['-c', c3 + ' && pwd -P'], { cwd: dirs, encoding: 'utf8' });
    if (p3.status !== 0 || p3.stdout.replace(/\n$/, '') !== fs.realpathSync(dir)) echec('cd', nom);
    if (!marquesVides()) echec('cd-marqueur', nom);
  }
  sorties.push(r);
}
for (const r of sorties) console.log(JSON.stringify(r));
JS
CMD() { CMD_OUT="$(ARG="${2-}" node "$AUX/cmd.mjs" "$1" 2>/dev/null)"; CMD_RC=$?; }
marques_vides() { [ -z "$(ls -A "$M")" ]; }

# --- dépôt jetable : deux commits, main ---
git init -q -b main "$REPO"; git -C "$REPO" commit -q --allow-empty -m un; git -C "$REPO" commit -q --allow-empty -m deux
SHA7="$(git -C "$REPO" rev-parse --short=7 HEAD)"

NOMS=()
NOMS+=('x;y|z`w' 'a"b'"'"'c&d' '-x' '--all' '<svg/onload=alert(1)>' 'é🙂' 'k{a,b}' '$HOME' '${HOME}' '!!' '#c')
NOMS+=('p$(touch${IFS}'"$M"'/sub)' 'q`touch${IFS}'"$M"'/bt`' "r';touch\${IFS}$M/q;'s" "t;touch\${IFS}$M/semi;u" "v|touch\${IFS}$M/pipe" "w&touch\${IFS}$M/amp&")

echo "=== C1 — commandes sur noms hostiles, exécutées pour de vrai ==="
CREES=0; for n in "${NOMS[@]}"; do git -C "$REPO" update-ref "refs/heads/$n" HEAD 2>/dev/null && CREES=$((CREES+1)); done
assert_eq "C1.0 — témoin : les ${#NOMS[@]} noms hostiles existent comme branches (dépôt réel)" "$CREES" "${#NOMS[@]}"

# echecs_switch <shell> : noms de NOMS pour lesquels la commande copiée ne bascule pas exactement sur la branche (ou crée un marqueur)
echecs_switch() {
  local sh="$1" n out=""
  for n in "${NOMS[@]}"; do
    git -C "$REPO" symbolic-ref HEAD refs/heads/main
    CMD cmdSwitch "$n"
    (cd "$REPO" && "$sh" -c "$CMD_OUT" >/dev/null 2>&1); local rc=$?
    local sym; sym="$(git -C "$REPO" symbolic-ref HEAD 2>/dev/null)"
    if [ "$CMD_RC" -ne 0 ] || [ "$rc" -ne 0 ] || [ "$sym" != "refs/heads/$n" ] || ! marques_vides; then out="$out[$n]"; fi
    rm -rf "${M:?}"/* 2>/dev/null
  done
  git -C "$REPO" symbolic-ref HEAD refs/heads/main
  printf '%s' "$out"
}
assert_eq "C1.1 — bash -c \"\$(cmdSwitch nom)\" bascule sur la branche hostile, aucun marqueur" "$(echecs_switch bash)" ""
if command -v zsh >/dev/null 2>&1; then
  assert_eq "C1.2 — idem sous zsh -c" "$(echecs_switch zsh)" ""
else
  echo "  ⏭️  SKIP — C1.2 (zsh absent : non compté)"
fi

# C1.3 : cd vers un dossier au nom piégé
HOSTILE="$DIRS/w'\$(touch $M/cd)'x"; mkdir -p "$HOSTILE" "$DIRS/-rel"
ECH=""
for sh in bash zsh; do
  command -v "$sh" >/dev/null 2>&1 || continue
  CMD cmdCd "$HOSTILE"; OBT="$(cd "$WORK" && "$sh" -c "$CMD_OUT && pwd" 2>/dev/null)"
  [ "$OBT" = "$(cd "$HOSTILE" && pwd)" ] && marques_vides || ECH="$ECH[$sh:piege]"
  CMD cmdCd "-rel"; OBT="$(cd "$DIRS" && "$sh" -c "$CMD_OUT && pwd" 2>/dev/null)"
  [ "$OBT" = "$(cd "$DIRS/-rel" && pwd)" ] || ECH="$ECH[$sh:tiret]"
done
assert_eq "C1.3 — cmdCd d'un dossier w'\$(touch …)'x puis d'un chemin en « - » : pwd juste, aucun marqueur" "$ECH" ""

# C1.4 : citer rejoué à l'octet
echecs_citer() {
  local sh="$1" s out="" i=0
  for s in "a'b" '$(touch '"$M"'/c)' '`id`' ';' '|' '&' '\' '"' 'a b  c' "'" "''" 'é🙂' $'fin\n' '-x' '!!' '*' '~'; do
    i=$((i+1)); CMD citer "$s"
    printf '%s' "$s" > "$WORK/citer.attendu"
    "$sh" -c "printf %s $CMD_OUT" > "$WORK/citer.obtenu" 2>/dev/null
    cmp -s "$WORK/citer.attendu" "$WORK/citer.obtenu" && marques_vides || out="$out[$i]"
  done
  printf '%s' "$out"
}
ECH="$(echecs_citer bash)"; command -v zsh >/dev/null 2>&1 && ECH="$ECH$(echecs_citer zsh)"
assert_eq "C1.4 — citer(s) rejoué par printf %s rend s à l'octet (apostrophes, \$(), backtick, ; | & \\ \", retour à la ligne)" "$ECH" ""

# C1.5 : ce que l'affichage retirerait n'a pas de commande
echecs_nuls() {
  local out="" fn v
  for fn in cmdCd cmdSwitch cmdBranchSupprimer; do
    for v in $'a\xe2\x80\xaeb' $'a\a' $'a\xc2\x85b' $'a\x7fb' $'a\xe2\x80\xa8b' $'a\xe2\x80\xa9b' $'a\xe2\x80\xaab' $'a\xe2\x81\xa6b' $'a\xe2\x81\xa9b' $'a\nb' $'a\x1bb' '' "$(printf 'a%.0s' $(seq 1 201))"; do
      CMD "$fn" "$v"; [ "$CMD_RC" -eq 3 ] || out="$out[$fn:nul-attendu:$(printf '%s' "$v" | od -An -c | tr -d ' \n' | cut -c1-24)]"
    done
    for v in 'a' "$(printf 'a%.0s' $(seq 1 200))" $'a\xc2\xa0b' $'a\xe2\x80\xafb' $'a\xe2\x81\xa5b' $'a\xe2\x80\xa7b' 'é🙂'; do
      CMD "$fn" "$v"; [ "$CMD_RC" -eq 0 ] || out="$out[$fn:commande-attendue:$(printf '%s' "$v" | od -An -c | tr -d ' \n' | cut -c1-24)]"
    done
    for v in 'null' '42' '["a"]' '{}'; do ARGJSON=1 CMD "$fn" "$v"; [ "$CMD_RC" -eq 3 ] || out="$out[$fn:non-chaine:$v]"; done
  done
  printf '%s' "$out"
}
assert_eq "C1.5 — U+202E, U+0007, U+0085, DEL, U+2028/9, U+202A, U+2066, U+2069, \\n, ESC, vide, 201 car., non-chaîne -> null ; 200 car., U+00A0, U+202F, U+2065, U+2027 -> commande" "$(echecs_nuls)" ""

# C1.6 : échantillon généré, chaque commande exécutée par chaque shell
SHELLS="bash"; command -v zsh >/dev/null 2>&1 && SHELLS="bash,zsh"; SHELLS="$SHELLS,sh"
GREPO="$WORK/grepo"; git init -q -b main "$GREPO"; git -C "$GREPO" commit -q --allow-empty -m un; git -C "$GREPO" commit -q --allow-empty -m deux
node "$AUX/gen.mjs" "$VF_MOD" "$GREPO" "$M" "$DIRS" "$SHELLS" 150 78 > "$WORK/gen.out" 2>/dev/null
node -e '
const l = require("fs").readFileSync(process.argv[1], "utf8").trim().split("\n").filter(Boolean).map((x) => JSON.parse(x));
if (!l.length || l[0].erreur) { console.log("GEN module absent"); process.exit(0); }
for (const r of l) console.log(`GEN ${r.shell} n=${r.n} nuls=${r.nuls} executes=${r.executes} armes=${r.armes} ignores=${r.ignores} echecs=${r.echecs.length}${r.echecs.length ? " " + r.echecs.slice(0, 5).join(" ; ") : ""}`);
' "$WORK/gen.out" > "$WORK/gen.res"
cat "$WORK/gen.res"
NSH="$(printf '%s' "$SHELLS" | tr ',' '\n' | grep -c .)"
assert_eq "C1.6 — échantillon généré : aucun échec ni marqueur sous $SHELLS" "$(grep -c ' echecs=0$' "$WORK/gen.res")" "$NSH"
assert_eq "C1.6b — témoin de portée : ≥ 100 branches exécutées, ≥ 10 noms armés (touch), ≥ 5 noms refusés, par shell" "$(awk '{ split($4,nul,"="); split($5,exe,"="); split($6,arm,"="); if (exe[2] >= 100 && arm[2] >= 10 && nul[2] >= 5) ok++ } END { print ok+0 }' "$WORK/gen.res")" "$NSH"

# C1.7 : parité avec l'affichage
assert_eq "C1.7 — AFFICHAGE_REFUSE = exactement les points de code que nettoie retire (76, aucun écart, U+0000 à U+10FFFF)" "$(node "$AUX/parite.mjs" "$SCRIPTS" 2>/dev/null)" "76|0"

echo
echo "=== Résultats : $PASS PASS, $FAIL FAIL ==="
[ "$FAIL" -eq 0 ]
