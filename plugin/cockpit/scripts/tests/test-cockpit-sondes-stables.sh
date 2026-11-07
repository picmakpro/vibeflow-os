#!/usr/bin/env bash
# test-cockpit-sondes-stables.sh — aides « mesurer une fois posé » de chrome-session.mjs (stabiliser, attendreValeur, attendreEtStabiliser, positionPosee).
#   N  partie node pure : lecteurs factices à séquence de valeurs (sans navigateur)
#   C  partie Chrome : un élément qui se déplace en plusieurs temps — positionPosee rend la position FINALE, une lecture immédiate (témoin) une autre
#   M  mutants (sur une COPIE de chrome-session.mjs) : chacun doit faire rougir au moins une assertion de N, sinon FAIL « mutant sans effet »
# Exit 0 si tout passe.
set -uo pipefail
HERE_T="$(cd "$(dirname "$0")" && pwd)"; SRC="$HERE_T/chrome-session.mjs"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/mut"
export CHROME_SESSION="$SRC"
cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi; done

# pure.mjs <module> : joue les cas sur le module donné ; une ligne par cas : « OK <cas> » ou « KO <cas> | attendu: … | obtenu: … »
cat > "$AUX/pure.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
const M = await import(pathToFileURL(process.argv[2]).href);
const J = JSON.stringify; const sortie = []; const sur = async (f) => { try { return await f(); } catch (e) { return 'EXCEPTION ' + e.message; } };
const cas = (nom, obtenu, attendu) => sortie.push(J(obtenu) === J(attendu) ? `OK ${nom}` : `KO ${nom} | attendu: ${J(attendu)} | obtenu: ${J(obtenu)}`);
// lecteur factice : rend successivement les valeurs de la séquence (la dernière se répète), compte ses lectures ; une valeur `new Error` fait lever
const lecteur = (seq, fabrique = (v) => v) => { const l = { n: 0, lire: async () => { const v = seq[Math.min(l.n, seq.length - 1)]; l.n++; if (v instanceof Error) throw v; return fabrique(v); } }; return l; };
const O = { pas: 5, max: 400 };
let l = lecteur([1, 2, 3, 3]); let r = await M.stabiliser(l.lire, O);
cas('N1 stabiliser 1,2,3,3 -> 3', r, 3); cas('N1b stabiliser : 4 lectures exactement', l.n, 4);
l = lecteur([{ x: 1 }], (v) => ({ ...v })); r = await M.stabiliser(l.lire, O);
cas('N2 objets reconstruits à chaque lecture : égalité JSON, rend la valeur', r, { x: 1 }); cas('N2b objets reconstruits : stable dès la 2e lecture (pas d\'identité)', l.n, 2);
l = lecteur([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100]);
let t0 = Date.now(); r = await M.stabiliser(l.lire, { pas: 5, max: 150 }); let dt = Date.now() - t0;
cas('N3 jamais stable : rend la DERNIÈRE lecture (la lecture n° n, jamais la première)', r === l.n, true); cas('N3b jamais stable : plusieurs lectures ont eu lieu', l.n > 5, true);
cas('N3c jamais stable : l\'échéance est respectée (>= 150 ms et < 150 ms + 1 s)', dt >= 140 && dt < 1150, true);
l = lecteur([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40]);
t0 = Date.now(); r = await M.attendreValeur(l.lire, () => false, { pas: 5, max: 150 }); dt = Date.now() - t0;
cas('N4 prédicat jamais vrai : rend la dernière lecture', r === l.n, true); cas('N4b prédicat jamais vrai : borne en temps respectée', dt >= 140 && dt < 1150, true);
l = lecteur([new Error('x'), new Error('x'), 5, 5]); r = await sur(() => M.stabiliser(l.lire, O));
cas('N5 lecteur qui lève au début : pas d\'exception, rend la valeur stable', r, 5);
l = lecteur([7, new Error('x'), 7, 7]); r = await sur(() => M.stabiliser(l.lire, O));
cas('N5b une lecture qui lève entre deux identiques les sépare (7,x,7,7 -> 4 lectures)', l.n, 4);
l = lecteur([new Error('x')]); r = await sur(() => M.stabiliser(l.lire, { pas: 5, max: 60 }));
cas('N5c lecteur qui lève toujours : rend undefined sans exception', r === undefined, true);
l = lecteur([1, 2, 3, 4]); r = await M.attendreValeur(l.lire, (v) => v >= 3, O);
cas('N6 attendreValeur rend la première valeur qui satisfait le prédicat', r, 3); cas('N6b attendreValeur s\'arrête à cette lecture (3 lectures)', l.n, 3);
l = lecteur([1, 1, 5, 6, 7, 7]); r = await M.attendreEtStabiliser(l.lire, (v) => v >= 5, O);
cas('N7 attendreEtStabiliser : condition vraie PUIS valeur stable (1,1,5,6,7,7 -> 7)', r, 7);
// positionPosee : ev factice qui évalue l'expression bâtie par l'aide contre un faux document dont l'élément rend des rects successifs
const faux = (rects) => { let n = 0; return { doc: { getElementById: () => (rects ? { getBoundingClientRect: () => rects[Math.min(n++, rects.length - 1)] } : null) }, lectures: () => n }; };
const evSur = (f) => async (expr) => new Function('document', `return (${expr})`)(f.doc);
const R = (x) => ({ x, y: 20, width: 200, height: 40 });
let f = faux([R(0), R(50), R(100), R(100)]); r = await M.positionPosee(evSur(f), "document.getElementById('a')", { pas: 5, max: 400 });
cas('N8 positionPosee : position FINALE après rects successifs', r, { x: 100, y: 20, l: 200, h: 40, cx: 200, cy: 40 }); cas('N8b positionPosee : 4 lectures', f.lectures(), 4);
f = faux(null); r = await M.positionPosee(evSur(f), "document.getElementById('a')", { pas: 5, max: 400 });
cas('N9 positionPosee : élément absent -> null', r, null);
f = faux([R(0), R(50), R(100), R(100)]); r = await M.positionPosee(evSur(f), "document.getElementById('a')", { pas: 5, max: 400 });
cas('N10 positionPosee : ev quelconque, centre calculé (cx = x + l/2, cy = y + h/2)', [r.cx, r.cy], [r.x + 100, r.y + 20]);
console.log(sortie.join('\n'));
JS
CAS="$(node "$AUX/pure.mjs" "$SRC" 2>&1)"
echo "=== N — aides, partie node pure ==="
NOK=0; while IFS= read -r ln; do
  case "$ln" in
    "OK "*) echo "  ✅ PASS — ${ln#OK }"; PASS=$((PASS+1)); NOK=$((NOK+1)) ;;
    "KO "*) echo "  ❌ FAIL — ${ln#KO }"; FAIL=$((FAIL+1)) ;;
    *) echo "  ❌ FAIL — sortie inattendue de pure.mjs : $ln"; FAIL=$((FAIL+1)) ;;
  esac
done <<< "$CAS"
assert_eq "N-compte — les 19 cas ont tous rendu un verdict (anti-vert-à-vide)" "$(printf '%s\n' "$CAS" | grep -c -E '^(OK|KO) ')" "19"

echo "=== C — Chrome : un élément qui se déplace en plusieurs temps ==="
if [ -z "$CHROME" ]; then echo "  ⊘ SUITE SAUTÉE (navigateur) : aucun Chrome — partie C non comptée comme réussie"; else
cat > "$AUX/pose.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
const { executer, positionPosee } = await import(pathToFileURL(process.env.CHROME_SESSION).href);
// 8 pas de 80 ms (+50 px chacun) : le premier pas est synchrone dans go(), la position finale (400) n'arrive qu'après ~560 ms
const page = `<div id=a style="position:absolute;left:0;top:30px;width:20px;height:10px;background:red"></div><script>window.go=()=>{let k=0;const p=()=>{k++;document.getElementById('a').style.left=(50*k)+'px';if(k<8)setTimeout(p,80)};p()}</script>`;
await executer(process.argv[2], async (s) => {
  await s.naviguer('data:text/html;charset=utf-8,' + encodeURIComponent(page));
  const avant = await s.ev("document.getElementById('a').getBoundingClientRect().x");
  const immediate = await s.ev("(() => { window.go(); return document.getElementById('a').getBoundingClientRect().x; })()");
  const posee = await positionPosee(s.ev, "document.getElementById('a')");
  const absent = await positionPosee(s.ev, "document.getElementById('nul')");
  return { avant, immediate, posee, absent };
});
JS
CR="$(node "$AUX/pose.mjs" "$CHROME")"
ev() { printf '%s' "$CR" | node -e "const j=JSON.parse(require('fs').readFileSync(0,'utf8'));const v=(function(j){return $1})(j);console.log(typeof v==='string'?v:JSON.stringify(v))"; }
assert_eq "C1 — témoin : l'élément n'a pas bougé avant le geste (x = 0)" "$(ev 'j.avant')" "0"
assert_eq "C2 — témoin : la lecture immédiate rend une position intermédiaire (50), pas la finale" "$(ev 'j.immediate')" "50"
assert_eq "C3 — positionPosee rend la position FINALE (x = 400, centre 410/35)" "$(ev '[j.posee.x,j.posee.cx,j.posee.cy]')" "[400,410,35]"
assert_eq "C4 — la position posée diffère de la lecture immédiate" "$(ev 'j.posee.x !== j.immediate')" "true"
assert_eq "C5 — élément absent : null" "$(ev 'j.absent')" "null"
fi

echo "=== M — mutants de chrome-session.mjs (copie jetable) : chacun doit rougir au moins une assertion de N ==="
mutant() { # nom, motif exact, remplacement
  local nom="$1" motif="$2" rempl="$3" f="$WORK/mut/$1.mjs"
  M_MOTIF="$motif" M_REMPL="$rempl" node -e "const fs=require('fs');const s=fs.readFileSync(process.argv[1],'utf8');const m=process.env.M_MOTIF;if(!s.includes(m)){console.error('motif absent');process.exit(3)}fs.writeFileSync(process.argv[2],s.replace(m,()=>process.env.M_REMPL))" "$SRC" "$f" 2>"$WORK/mut/$nom.err" || { assert_eq "M $nom — mutant appliqué (motif présent dans la source)" "motif absent" "motif présent"; return; }
  if cmp -s "$SRC" "$f"; then assert_eq "M $nom — mutant sans effet (copie identique)" "identique" "modifiée"; return; fi
  local sortie ko; sortie="$(node "$AUX/pure.mjs" "$f" 2>&1)"; ko="$(printf '%s\n' "$sortie" | grep -E '^KO ' || true)"
  if [ -n "$ko" ]; then echo "  trace du rouge ($nom) :"; printf '%s\n' "$ko" | head -3 | sed 's/^/     /'; assert_eq "M $nom — mutant tué ($(printf '%s\n' "$ko" | wc -l | tr -d ' ') assertion(s) rougissent)" "tué" "tué"
  else assert_eq "M $nom — mutant sans effet" "survivant" "tué"; fi
}
mutant a-stabiliser-premiere-lecture 'if (c.ok && prec && identiques(prec.v, c.v)) return c.v;' 'return c.v;'
mutant b-attendreValeur-sans-predicat 'if (c.ok && vrai(predicat, c.v)) return c.v;' 'if (c.ok) return c.v;'
mutant c-comparaison-par-identite 'JSON.stringify(a) === JSON.stringify(b)' 'a === b'
mutant d-positionPosee-sans-stabilisation 'return stabiliser(lire, { pas, max });' 'return lire();'
mutant e-attendreEtStabiliser-sans-stabilite 'return stabiliser(lire, opts);' 'return lire();'
mutant f-lecture-qui-leve-propagee 'try { return { v: await lire(), ok: true }; } catch { return { v: undefined, ok: false }; }' 'return { v: await lire(), ok: true };'

vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
