#!/usr/bin/env bash
# test-cockpit-git-graphe.sh — sorties git -> graphe en JS pur (Phase 78, GITC-06 ; P78-D-22, P78-D-23)
#   G0 contrôles positifs de la fixture (git réel, avant tout appel au module)
#   G1 journal : alignement, coupes, champs mal formés · G2 refs et worktrees · G3 fusion topologique
#   (G4 placement des couloirs, G5 étiquettes et teinte, mutants : sections ajoutées au fil des tâches)
# Dépôt fabriqué par la suite dans mktemp (identité et dates fixées), jamais de dépôt distant. Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t.test GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t.test
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
MOD="$SCRIPTS/vf-cockpit-git-graphe.mjs"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
AUX="$WORK/aux"; FX="$WORK/fx"; REPO="$WORK/repo"; mkdir -p "$AUX" "$FX" "$REPO"

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_ok() { if [ "$2" = "0" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; FAIL=$((FAIL+1)); fi; }

# --- fixture : dépôt à historique varié, dates fixes ---
G() { git -C "$REPO" "$@"; }
T=1700000000
ci() { T=$((T+60)); GIT_AUTHOR_DATE="$T +0000" GIT_COMMITTER_DATE="$T +0000" G "$@"; }
c() { ci commit -q --allow-empty -m "$1"; }
G init -q -b main .
c c0; for i in 1 2 3 4 5; do c "m$i é"; done
G checkout -q -b f; c f1; c f2                       # branche mergée --no-ff
G checkout -q main; c m6; ci merge -q --no-ff f -m "merge f"
G branch g2; G branch g3                              # merge octopus (3 parents)
G checkout -q g2; c g2a; G checkout -q g3; c g3a; G checkout -q main; c m7; ci merge -q g2 g3 -m octopus
G checkout -q --orphan o; c o1; c o2                  # seconde racine
G checkout -q main; ci merge -q --no-ff --allow-unrelated-histories o -m "merge o"
for i in $(seq 8 21); do c "m$i"; done
G branch u main~12; G checkout -q u; c u1; c u2; G checkout -q main   # branche non mergée
G branch b2 main; G branch 'a,b' main~2; G tag -a v1 -m v1 main; G tag lw main~3
G update-ref refs/remotes/origin/main main
G worktree add -q --detach "$WORK/wt-a"; G worktree add -q -b wtb "$WORK/wt-b" main~5
G log --topo-order -z --format='%H%x00%P%x00%at%x00%an%x00%s' -n 25 refs/heads/main > "$FX/jr25.out"
G log --topo-order -z --format='%H%x00%P%x00%at%x00%an%x00%s' refs/heads/main > "$FX/jr-all.out"
G log --topo-order -z --format='%H%x00%P%x00%at%x00%an%x00%s' -n 10 refs/heads/main > "$FX/jr10.out"
G log --topo-order -z --format='%H%x00%P%x00%at%x00%an%x00%s' -n 500 refs/heads/u --not refs/heads/main > "$FX/jr-u.out"
G log --topo-order -z --format='%H%x00%P%x00%at%x00%an%x00%s' refs/heads/f > "$FX/jr-f.out"
G for-each-ref --format='%(refname)%00%(objectname)%00%(*objectname)%00%(creatordate:unix)' refs/heads refs/remotes refs/tags > "$FX/refs.out"
G worktree list --porcelain -z > "$FX/wt.out"

echo "━━ G0 contrôles de la fixture"
assert_eq "G0.1 au moins 30 commits sur main" "$([ "$(G rev-list --count refs/heads/main)" -ge 30 ] && echo oui)" "oui"
assert_eq "G0.2 un merge octopus (3 parents)" "$(G rev-list --count --min-parents=3 refs/heads/main)" "1"
assert_eq "G0.3 deux racines atteintes depuis main" "$(G rev-list --count --max-parents=0 refs/heads/main)" "2"
assert_eq "G0.4 trois worktrees" "$(G worktree list | wc -l | tr -d " ")" "3"
assert_eq "G0.5 la sortie du journal n'est pas vide" "$([ "$(wc -c < "$FX/jr25.out")" -gt 500 ] && echo oui)" "oui"

# --- sondes node ---
cat > "$AUX/s.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
import path from 'node:path';
import fs from 'node:fs';
const lire = (fx, n) => fs.readFileSync(path.join(fx, n), 'utf8');
const lcg = (seed) => { let s = seed >>> 0; return () => (s = (Math.imul(s, 1664525) + 1013904223) >>> 0) / 4294967296; };
const melange = (a, seed) => { const r = lcg(seed), t = [...a]; for (let i = t.length - 1; i > 0; i--) { const j = Math.floor(r() * (i + 1)); [t[i], t[j]] = [t[j], t[i]]; } return t; };
const MOT = /^[0-9a-f]{40}$/;
export const P = {};
P.g11 = (M, fx) => { const r = M.lireJournal(lire(fx, 'jr25.out')); if (!r.ok) return 'ko ' + r.raison; return r.commits.length === 25 && r.commits.every((c) => MOT.test(c.h) && c.p.every((p) => MOT.test(p)) && Number.isInteger(c.at)) ? 'ok 25' : 'incoherent'; };
P.g11h = (M, fx) => { const r = M.lireJournal(lire(fx, 'jr25.out')); return r.ok ? r.commits.map((c) => c.h).join('\n') : 'ko'; };
P.g12 = (M, fx) => {
  const s = lire(fx, 'jr25.out'), t = s.split('\0'), n = t.length - 1;
  const debut = n > 5 ? t.slice(0, n - 5).join('\0').length + 1 : 0;
  let mauvais = 0, total = 0;
  for (let l = debut + 1; l < s.length; l++) { total++; if (M.lireJournal(s.slice(0, l)).ok) mauvais++; }
  const front = M.lireJournal(s.slice(0, debut));
  return `${mauvais} ${total} ${front.ok ? front.commits.length : 'ko'}`;
};
P.g13 = (M, fx) => {
  const s = lire(fx, 'jr25.out'), t = s.split('\0');
  const ok = (x) => (M.lireJournal(x).ok ? 'ok' : 'ko');
  const sha39 = s.slice(1);
  const at = [...t]; at[2] = '12x'; const parent = [...t]; parent[1] = 'zz' + t[1];
  return [ok(sha39), ok(at.join('\0')), ok(parent.join('\0')), ok(s)].join(' ');
};
P.g21 = (M, fx) => {
  const s = lire(fx, 'refs.out'), r = M.lireRefs(s);
  const l = s.split('\n'); l[0] = l[0].split('\0').slice(0, 3).join('\0');
  const pelees = r.ok ? r.refs.filter((x) => x.pelee).length : -1;
  return [r.ok ? 'ok:' + r.refs.length : 'ko', M.lireRefs(l.join('\n')).ok ? 'ok' : 'ko', M.lireRefs(s.slice(0, -3)).ok ? 'ok' : 'ko', 'pelees=' + pelees].join(' ');
};
P.g21n = (M, fx) => { const r = M.lireRefs(lire(fx, 'refs.out')); return r.ok ? r.refs.map((x) => x.ref).join('\n') : 'ko'; };
P.g22 = (M, fx) => {
  const s = lire(fx, 'wt.out'), r = M.lireWorktrees(s);
  if (!r.ok) return 'ko ' + r.raison;
  const w = r.worktrees;
  const coupes = [s.slice(0, -1), s.slice(0, -2), s.slice(0, 40), 'n' + s].map((x) => (M.lireWorktrees(x).ok ? 'ok' : 'ko'));
  return `n=${w.length} b0=${w[0].branche} d1=${w[1].detache} b2=${w[2].branche} coupes=${coupes.join(',')}`;
};
P.g22c = (M, fx) => { const r = M.lireWorktrees(lire(fx, 'wt.out')); return r.ok ? r.worktrees.map((w) => w.chemin).join('\n') : 'ko'; };
P.g31 = (M, fx) => {
  const base = M.lireJournal(lire(fx, 'jr-all.out')).commits, nm = M.lireJournal(lire(fx, 'jr-u.out')).commits;
  const o = M.ordonner([base, nm]), idx = new Map(o.map((c, i) => [c.h, i]));
  let viol = 0; for (const c of o) for (const p of c.p) if (idx.has(p) && idx.get(p) <= idx.get(c.h)) viol++;
  const ref = JSON.stringify(o);
  const stable = [M.ordonner([nm, base]), M.ordonner([[...base].reverse(), [...nm].reverse()]), M.ordonner([melange(base, 7), melange(nm, 9)]), M.ordonner([melange([...base, ...nm], 3)])].every((x) => JSON.stringify(x) === ref);
  return `${o.length} ${idx.size} viol=${viol} stable=${stable}`;
};
P.g32 = (M) => {
  const sha = (ch) => ch.repeat(40);
  const libres = ['c', '3', 'a', 'e', '7', 'b'].map((ch) => ({ h: sha(ch), p: [], at: 100, an: '', s: '' }));
  const ties = M.ordonner([melange(libres, 5)]).map((c) => c.h[0]).join('');
  const enfant = { h: sha('f'), p: [sha('a')], at: 100, an: '', s: '' }, pere = { h: sha('a'), p: [], at: 100, an: '', s: '' };
  const egal = M.ordonner([[pere, enfant]]).map((c) => c.h[0]).join('');
  const skew = M.ordonner([[{ h: sha('1'), p: [sha('2')], at: 1, an: '', s: '' }, { h: sha('2'), p: [], at: 999, an: '', s: '' }, { h: sha('3'), p: [], at: 500, an: '', s: '' }]]).map((c) => c.h[0]).join('');
  return `ties=${ties} egal=${egal} skew=${skew}`;
};
JS
cat > "$AUX/z.mjs" <<'JS'
const [, , mod, nom, fx] = process.argv;
const { pathToFileURL } = await import('node:url');
let M; try { M = await import(pathToFileURL(mod).href); } catch { console.log('charge-ko'); process.exit(0); }
const { P } = await import(pathToFileURL(process.env.VF_SONDES).href);
try { console.log(await P[nom](M, fx)); } catch (e) { console.log('sonde-ko ' + e.message); }
JS
Q() { VF_SONDES="$AUX/s.mjs" node "$AUX/z.mjs" "${2:-$MOD}" "$1" "$FX" 2>&1; }
TOPO25="$(G rev-list --topo-order -n 25 refs/heads/main)"

echo "━━ G1 journal"
assert_eq "G1.1 25 commits lus, parents au motif" "$(Q g11)" "ok 25"
assert_eq "G1.1b mêmes sha, même ordre que git rev-list --topo-order" "$(Q g11h)" "$TOPO25"
R="$(Q g12)"; set -- $R
assert_eq "G1.2 chaque coupe dans le dernier enregistrement donne ok:false (0 faux positifs)" "${1:-?}" "0"
assert_eq "G1.2b la coupe a bien été jouée sur tout l'enregistrement" "$([ "${2:-0}" -gt 20 ] && echo oui)" "oui"
assert_eq "G1.2c la frontière exacte du dernier enregistrement reste ok (24 commits)" "${3:-?}" "24"
assert_eq "G1.3 sha de 39 caractères, at non entier, parent mal formé : ok:false ; entrée saine : ok" "$(Q g13)" "ko ko ko ok"

echo "━━ G2 refs et worktrees"
NREFS="$(G for-each-ref refs/heads refs/remotes refs/tags | wc -l | tr -d ' ')"
assert_eq "G2.1 4 champs : ok ; ligne à 3 champs : ko ; ligne coupée : ko ; tag annoté pelé" "$(Q g21)" "ok:$NREFS ko ko pelees=1"
assert_eq "G2.1b noms de refs identiques à for-each-ref (virgule permise)" "$(Q g21n)" "$(G for-each-ref --format='%(refname)' refs/heads refs/remotes refs/tags)"
assert_eq "G2.2 3 worktrees, 2e détaché, 3e sur refs/heads/wtb, sorties coupées refusées" "$(Q g22)" "n=3 b0=refs/heads/main d1=true b2=refs/heads/wtb coupes=ko,ko,ko,ko"
assert_eq "G2.2b chemins identiques à git worktree list --porcelain" "$(Q g22c)" "$(G worktree list --porcelain | sed -n 's/^worktree //p')"

echo "━━ G3 fusion topologique"
NU="$(G rev-list --count refs/heads/main refs/heads/u)"
assert_eq "G3.1 enfants avant parents, ensemble complet, stable aux listes permutées et mélangées" "$(Q g31)" "$NU $NU viol=0 stable=true"
assert_eq "G3.2 égalité de date départagée par sha, enfant d'abord à date égale, horloge décalée" "$(Q g32)" "ties=37abce egal=fa skew=312"

echo ""
echo "Résultats : $PASS passés, $FAIL échoués"
[ "$FAIL" -eq 0 ]
