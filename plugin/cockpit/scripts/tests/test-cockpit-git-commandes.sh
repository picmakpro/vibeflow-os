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
const FIXES = ["-", "@", "HEAD", "FETCH_HEAD", "ORIG_HEAD", "MERGE_HEAD", "refs/heads/y", "1234567", "0000000000000000000000000000000000000000", "--", "-x", "--all"];
const valide = (n) => spawnSync('git', ['check-ref-format', 'refs/heads/' + n]).status === 0;
let essais = 0;
for (const n of FIXES) if (valide(n) && !vus.has(n)) { vus.add(n); noms.push(n); }
while (noms.length < Number(nStr) && essais++ < 20000) {
  let n = ''; for (let k = 1 + rnd(6); k > 0; k--) n += T[rnd(T.length)];
  if (!vus.has(n) && valide(n)) { vus.add(n); noms.push(n); }
}
const sorties = [];
for (const sh of shells.split(',')) {
  const r = { shell: sh, n: noms.length, nuls: 0, executes: 0, armes: 0, ignores: 0, echecs: [] };
  let i = 0;
  for (const nom of noms) {
    i++;
    const attendNul = refuse(nom) || nom.length > 200;
    const run = (cmd, extra = '') => spawnSync(sh, ['-c', cmd + extra], { cwd: repo, encoding: 'utf8' });
    const marquesVides = () => { const l = fs.readdirSync(marques); for (const f of l) fs.rmSync(path.join(marques, f), { recursive: true, force: true }); return l.length === 0; };
    const retour = () => git('symbolic-ref', 'HEAD', 'refs/heads/main');
    const echec = (quoi, nom_) => r.echecs.push(`${quoi}:${JSON.stringify(nom_)}`);
    // switch
    const c1 = m.cmdSwitch(nom), c2 = m.cmdBranchSupprimer(nom);
    const sansSwitch = nom === '-' || nom === '@'; // raccourcis de git switch : pas de commande de bascule
    if (attendNul) { r.nuls++; if (c1 !== null || c2 !== null) echec('devait-etre-null', nom); }
    else if (sansSwitch) { r.nuls++; if (c1 !== null) echec('switch-devait-etre-null', nom); }
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

# C1.3 : cd vers un dossier au nom piégé. Le nom ne contient aucun « / » (marqueur RELATIF `touch cdm`, la commande est lancée depuis $M : une injection y laisserait `cdm`) : le dossier est créé tel quel
NOMDIR='w'"'"'$(touch cdm)'"'"'x'; HOSTILE="$DIRS/$NOMDIR"; mkdir "$HOSTILE" "$DIRS/-rel"
ECH=""; [ -d "$HOSTILE" ] && [ "$(ls "$DIRS" | grep -c "touch cdm")" = "1" ] || ECH="$ECH[dossier-pas-tel-quel]"
for sh in bash zsh; do
  command -v "$sh" >/dev/null 2>&1 || continue
  CMD cmdCd "$HOSTILE"; OBT="$(cd "$M" && "$sh" -c "$CMD_OUT && pwd" 2>/dev/null)"
  [ "$OBT" = "$(cd "$HOSTILE" && pwd)" ] && marques_vides || ECH="$ECH[$sh:piege]"
  CMD cmdCd "-rel"; OBT="$(cd "$DIRS" && "$sh" -c "$CMD_OUT && pwd" 2>/dev/null)"
  [ "$OBT" = "$(cd "$DIRS/-rel" && pwd)" ] || ECH="$ECH[$sh:tiret]"
done
assert_eq "C1.3 — cmdCd d'un dossier w'\$(touch cdm)'x (créé tel quel) puis d'un chemin en « - » : pwd juste, aucun marqueur" "$ECH" ""


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


# C1.8 : « - » et « @ » existent comme branches mais git switch les lit en raccourcis : pas de commande de bascule ; branch -d, lui, les vise bien
for n in '-' '@'; do git -C "$REPO" update-ref "refs/heads/$n" HEAD; done
CMD cmdSwitch '-'; R1=$CMD_RC; CMD cmdSwitch '@'; R2=$CMD_RC
assert_eq "C1.8a — cmdSwitch('-') et cmdSwitch('@') -> null (git switch les lit en raccourcis)" "$R1|$R2" "3|3"
ECH=""
for n in '-' '@'; do
  git -C "$REPO" symbolic-ref HEAD refs/heads/main; CMD cmdBranchSupprimer "$n"
  (cd "$REPO" && bash -c "$CMD_OUT" >/dev/null 2>&1); RC=$?
  git -C "$REPO" show-ref --verify "refs/heads/$n" >/dev/null 2>&1 && ECH="$ECH[$n:encore-la]"; [ "$RC" -eq 0 ] || ECH="$ECH[$n:rc$RC]"
done
assert_eq "C1.8b — cmdBranchSupprimer('-') et ('@') exécutées : branches supprimées" "$ECH" ""

echo "=== C2 — formes de --end-of-options sondées sur git réel ==="
git -C "$REPO" symbolic-ref HEAD refs/heads/main      # la boucle C1 a pu laisser HEAD sur un nom hostile : la branche courante n'est jamais -x
git -C "$REPO" update-ref refs/heads/-x HEAD 2>/dev/null
SANS="$(cd "$REPO" && bash -c "git branch -d '-x'" 2>&1)"; RCS=$?
assert_eq "C2.1a — témoin : git branch -d '-x' SANS --end-of-options échoue et la branche reste" "$([ "$RCS" -ne 0 ] && echo echec)|$(git -C "$REPO" show-ref --verify refs/heads/-x >/dev/null 2>&1 && echo reste)" "echec|reste"
CMD cmdBranchSupprimer '-x'; (cd "$REPO" && bash -c "$CMD_OUT" >/dev/null 2>&1); RC=$?
assert_eq "C2.1b — cmdBranchSupprimer('-x') exécutée (branche mergée, HEAD ailleurs) : rc 0, branche supprimée" "$RC|$(git -C "$REPO" show-ref --verify refs/heads/-x >/dev/null 2>&1 && echo reste || echo supprimee)" "0|supprimee"
git -C "$REPO" symbolic-ref HEAD refs/heads/main
PREM="$(git -C "$REPO" rev-parse --short=7 HEAD~1)"
CMD cmdShowStat "$SHA7"; SORTIE="$(cd "$REPO" && bash -c "$CMD_OUT" 2>&1)"; RC=$?
assert_eq "C2.2a — cmdShowStat(sha7) exécutée : rc 0 et le commit « deux » est montré" "$RC|$([[ "$SORTIE" == *deux* ]] && echo montre)" "0|montre"
CMD cmdDetacher "$PREM"; (cd "$REPO" && bash -c "$CMD_OUT" >/dev/null 2>&1); RC=$?
assert_eq "C2.2b — cmdDetacher(sha7) exécutée : rc 0, HEAD détaché sur ce commit" "$RC|$(git -C "$REPO" symbolic-ref -q HEAD >/dev/null 2>&1 && echo branche || echo detache)|$(git -C "$REPO" rev-parse --short=7 HEAD)" "0|detache|$PREM"
git -C "$REPO" symbolic-ref HEAD refs/heads/main
ECH=""
for fn in cmdDetacher cmdShowStat; do for v in '--all' 'HEAD' 'ABCDEF1' 'abcdef' "$(printf 'a%.0s' $(seq 1 65))" 'abcdef1;id' ''; do CMD $fn "$v"; [ "$CMD_RC" -eq 3 ] || ECH="$ECH[$fn:$v]"; done
  for v in 'abcdef1' "$(printf 'a%.0s' $(seq 1 64))"; do CMD $fn "$v"; [ "$CMD_RC" -eq 0 ] || ECH="$ECH[$fn:ok:$v]"; done; done
assert_eq "C2.2c — sha : --all, HEAD, majuscules, 6 car., 65 car., injection -> null ; 7 et 64 car. hexa -> commande" "$ECH" ""
SREPO="$WORK/srepo"; git init -q -b main "$SREPO"; git -C "$SREPO" commit -q --allow-empty -m base; echo x > "$SREPO/f"; git -C "$SREPO" add f; git -C "$SREPO" stash push -q
CMD cmdStashShow 'stash@{0}'; SORTIE="$(cd "$SREPO" && bash -c "$CMD_OUT" 2>&1)"; RC=$?
assert_eq "C2.3a — cmdStashShow('stash@{0}') exécutée après un stash push : rc 0, fichier f listé" "$RC|$([[ "$SORTIE" == *" f "* || "$SORTIE" == f* ]] && echo liste)" "0|liste"
ECH=""; for v in 'stash@{0};id' 'stash@{}' 'stash@{12345}' 'stash@{0} x' '--all' ''; do CMD cmdStashShow "$v"; [ "$CMD_RC" -eq 3 ] || ECH="$ECH[$v]"; done
assert_eq "C2.3b — ref de stash hors motif -> null" "$ECH" ""
echo x > "$SREPO/g"; git -C "$SREPO" add g; CMD cmdCommitInitial; (cd "$SREPO" && bash -c "$CMD_OUT" >/dev/null 2>&1); RC=$?
assert_eq "C2.4a — cmdCommitInitial exécutée : rc 0, sujet « premier commit »" "$RC|$(git -C "$SREPO" log -1 --format=%s)" "0|premier commit"
CMD cmdStatus; (cd "$SREPO" && bash -c "$CMD_OUT" >/dev/null 2>&1); RC=$?
assert_eq "C2.4b — cmdStatus exécutée : « git status », rc 0" "$CMD_OUT|$RC" "git status|0"

echo "=== C3 — mutants (copies du module), chacun avec la trace de SON rouge ==="
for n in "${NOMS[@]}"; do git -C "$REPO" update-ref "refs/heads/$n" HEAD; done   # C2 a supprimé -x : les sondes de C1 repartent de noms tous présents
cat > "$AUX/mutate.mjs" <<'JS2'
import fs from 'node:fs';
const [, , src, dst, kind, de, vers] = process.argv;
let s = fs.readFileSync(src, 'utf8');
const ligne = (debut, f) => { const l = s.split('\n'); const k = l.findIndex((x) => x.startsWith(debut)); if (k < 0) process.exit(5); l[k] = f(l[k]); s = l.join('\n'); };
if (kind === 'M-CITE') { const a = s.indexOf(".replace(/'/g"); const b = s.indexOf('+ "\'"', a); if (a < 0 || b < 0) process.exit(5); s = s.slice(0, a) + ' ' + s.slice(b); }
else if (kind === 'M-EOO') ligne('export const cmdSwitch', (x) => { if (!x.includes('--end-of-options ')) process.exit(5); return x.replace('--end-of-options ', ''); });
else if (kind === 'M-BIDI') ligne('export const AFFICHAGE_REFUSE', () => 'export const AFFICHAGE_REFUSE = /(?!)/;');
else if (kind === 'PLAGE') ligne('export const AFFICHAGE_REFUSE', (x) => { if (x.split(de).length !== 2) process.exit(5); return x.replace(de, vers); });
else process.exit(6);
if (s === fs.readFileSync(src, 'utf8')) process.exit(5);
fs.writeFileSync(dst, s);
JS2
# mutant <nom> <kind> [de vers] : produit la copie, vérifie qu'elle charge, puis rend « sw|ci|nu » (R = la sonde rougit, V = propre)
sonde_mutant() {
  local nom="$1"; shift; local p="$MUT/$nom.mjs"
  node "$AUX/mutate.mjs" "$MOD_REEL" "$p" "$@" 2>/dev/null || { printf 'mutation-impossible'; return; }
  VF_MOD="$p" CMD cmdStatus; [ "$CMD_OUT" = "git status" ] || { printf 'mutant-ne-charge-pas'; return; }
  local sw ci nu
  sw="$(VF_MOD="$p" echecs_switch bash)"; ci="$(VF_MOD="$p" echecs_citer bash)"; nu="$(VF_MOD="$p" echecs_nuls)"
  git -C "$REPO" symbolic-ref HEAD refs/heads/main
  printf '%s|%s|%s' "$([ -n "$sw" ] && echo R || echo V)$([[ "$sw" == *"[-x]"* ]] && echo -x)" "$([ -n "$ci" ] && echo R || echo V)" "$([ -n "$nu" ] && echo R || echo V)"
}
assert_eq "C3.1 — M-CITE (échappement de ' retiré) rougit C1.1 ET C1.4, pas C1.5" "$(sonde_mutant M-CITE M-CITE)" "R|R|V"
assert_eq "C3.2 — M-EOO (--end-of-options retiré de cmdSwitch) rougit C1.1 sur -x, pas C1.4 ni C1.5" "$(sonde_mutant M-EOO M-EOO)" "R-x|V|V"
assert_eq "C3.3 — M-BIDI (AFFICHAGE_REFUSE vidé) rougit C1.5, pas C1.1 ni C1.4" "$(sonde_mutant M-BIDI M-BIDI)" "V|V|R"
U='\u'
i=0
for pl in "${U}0000-${U}001f=>" "${U}007f-${U}009f=>" "${U}2028=>" "${U}2029=>" "${U}202a-${U}202e=>" "${U}2066-${U}2069=>" \
          "${U}202a-${U}202e=>${U}202b-${U}202e" "${U}202a-${U}202e=>${U}202a-${U}202d" "${U}2066-${U}2069=>${U}2067-${U}2069" "${U}2066-${U}2069=>${U}2066-${U}2068"; do
  i=$((i+1)); DE="${pl%%=>*}"; VERS="${pl#*=>}"
  assert_eq "C3.4.$i — M-BIDI plage ${DE} -> [${VERS}] rougit C1.5 seul" "$(sonde_mutant "M-BIDI-$i" PLAGE "$DE" "$VERS")" "V|V|R"
done

echo
echo "=== Résultats : $PASS PASS, $FAIL FAIL ==="
[ "$FAIL" -eq 0 ]
