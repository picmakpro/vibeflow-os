#!/usr/bin/env bash
# test-cockpit-git-graphe.sh — sorties git -> graphe en JS pur (Phase 78, GITC-06 ; P78-D-22, P78-D-23)
#   G0 contrôles positifs de la fixture (git réel, avant tout appel au module)
#   G1 journal : alignement, coupes, champs mal formés · G2 refs et worktrees · G3 fusion topologique
#   G4 placement des couloirs (invariants, octopus, fenêtre, déterminisme, quatre couloirs, perf) · G5 étiquettes et teinte
#   Mutants : M-ALIGN (motif du sha) · M-PAQUET (compte de champs, NUL final) · M-OCTOPUS · M-RACINE · M-ORDRE
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

# --- second dépôt : quatre couloirs simultanés (G4.5) ---
R4="$WORK/repo4"; mkdir -p "$R4"; git -C "$R4" init -q -b main .
T4=1700100000
c4() { T4=$((T4+60)); GIT_AUTHOR_DATE="$T4 +0000" GIT_COMMITTER_DATE="$T4 +0000" git -C "$R4" "$@"; }
c4 commit -q --allow-empty -m r0
for i in 1 2 3 4; do git -C "$R4" checkout -q -b p$i main; c4 commit -q --allow-empty -m p$i; done
for i in 1 2 3 4; do git -C "$R4" checkout -q -b t$i p$i; c4 commit -q --allow-empty -m t$i; done
git -C "$R4" log --topo-order -z --format='%H%x00%P%x00%at%x00%an%x00%s' t1 t2 t3 t4 > "$FX/jr4.out"
G rev-parse refs/heads/main > "$FX/tete-main.txt"
assert_eq "G0.6 le dépôt à quatre branches compte 9 commits" "$(git -C "$R4" rev-list --count t1 t2 t3 t4)" "9"

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
const ordonne = (M, fx, f = 'jr-all.out') => M.ordonner([M.lireJournal(lire(fx, f)).commits]);
P.g41 = (M, fx) => {
  const cs = ordonne(M, fx), pl = M.placer(cs, { couloirsMax: 99 }), idx = new Map(cs.map((c, i) => [c.h, i]));
  const enfants = new Set(cs.flatMap((c) => c.p));
  let viol = 0;
  pl.rangees.forEach((r, i) => {
    const c = cs[i];
    for (const s of r.sortants) { const j = idx.get(s.parent); if (s.de !== r.col || (j !== undefined && (j <= i || pl.rangees[j].col !== s.vers))) viol++; }
    c.p.forEach((p, k) => { const j = idx.get(p); if (j !== undefined && j <= i) viol++; });
    const p0 = c.p[0], j0 = idx.get(p0);
    if (p0 && j0 !== undefined) { if (r.suite ? pl.rangees[j0].col !== r.col : !r.sortants.some((s) => s.parent === p0)) viol++; }
    if (r.entrants.length > 1 || (enfants.has(c.h) && r.entrants[0] !== r.col)) viol++;
  });
  return `viol=${viol} ouverts=${pl.ouvertsEnBas} racines=${pl.racines} rangees=${pl.rangees.length}`;
};
P.g42 = (M, fx) => {
  const cs = ordonne(M, fx), pl = M.placer(cs), oct = [];
  pl.rangees.forEach((r, i) => { if (cs[i].p.length === 3) oct.push(r); });
  if (oct.length !== 1) return 'octopus=' + oct.length;
  const r = oct[0], vers = r.sortants.map((s) => s.vers);
  return `n=1 s=${r.sortants.length} distincts=${new Set(vers).size === vers.length && !vers.includes(r.col)} fusion=${r.fusion} suite=${r.suite}`;
};
P.g43 = (M, fx) => {
  const cs = M.lireJournal(lire(fx, 'jr10.out')).commits, pl = M.placer(M.ordonner([cs]));
  const h = new Set(cs.map((c) => c.h)), hors = new Set(cs.flatMap((c) => c.p).filter((p) => !h.has(p)));
  const listes = pl.rangees.reduce((n, r) => n + r.ouvertBas.length, 0);
  const tort = pl.rangees.filter((r, i) => r.racine !== (M.ordonner([cs])[i].p.length === 0)).length;
  return `ouverts=${pl.ouvertsEnBas} hors=${hors.size} egal=${pl.ouvertsEnBas === hors.size} listes=${listes === hors.size} racines=${pl.racines} tort=${tort}`;
};
const pipe = (M, fx, listes) => JSON.stringify(M.placer(M.ordonner(listes)));
const deux = (M, fx) => [M.lireJournal(lire(fx, 'jr-all.out')).commits, M.lireJournal(lire(fx, 'jr-u.out')).commits];
P.g44a = (M, fx) => pipe(M, fx, deux(M, fx));
P.g44b = (M, fx) => pipe(M, fx, deux(M, fx));
P.g44c = (M, fx) => pipe(M, fx, structuredClone(deux(M, fx)));
P.g44d = (M, fx) => { const [a, b] = deux(M, fx); return pipe(M, fx, [melange(b, 11), melange(a, 13)]); };
P.g44e = (M, fx) => { const [a, b] = deux(M, fx); return pipe(M, fx, [melange([...a, ...b].map((c) => ({ ...c, p: [...c.p] })), 17)]); };
P.g45 = (M, fx) => {
  const cs = ordonne(M, fx, 'jr4.out'), pl = M.placer(cs), p2 = M.placer(cs, { couloirsMax: 2 });
  const vals = (pl) => pl.rangees.flatMap((r) => [r.col, ...r.entrants, ...r.ouvertBas, ...r.sortants.flatMap((s) => [s.de, s.vers])]);
  return `vus=${pl.couloirsVus} max=${Math.max(...vals(pl))} replies0=${pl.replies} | max2=${Math.max(...vals(p2))} largeur2=${Math.max(...p2.rangees.map((r) => r.largeur))} replies2=${p2.replies > 0}`;
};
P.g46 = (M) => {
  const n = 1000, h = (i) => i.toString(16).padStart(40, '0');
  const cs = Array.from({ length: n }, (_, i) => ({ h: h(i), p: i + 1 >= n ? [] : [h(i + 1), ...(i % 3 === 0 && i + 9 < n ? [h(i + 9)] : []), ...(i % 50 === 0 && i + 20 < n ? [h(i + 20), h(i + 31)] : [])], at: 1e6 - i, an: '', s: '' }));
  const t0 = performance.now(); const pl = M.placer(cs); const ms = performance.now() - t0;
  return `ms=${ms.toFixed(2)} vus=${pl.couloirsVus} rangees=${pl.rangees.length} dense=${pl.couloirsVus >= 5} rapide=${ms < 200}`;
};
P.g48 = (M, fx) => {
  const base = M.lireJournal(lire(fx, 'jr-all.out')).commits, f = M.lireJournal(lire(fx, 'jr-f.out')).commits;
  const repli = JSON.stringify(M.ordonner([base, f])) === JSON.stringify(M.ordonner([base])) && JSON.stringify(M.placer(M.ordonner([base, f]))) === JSON.stringify(M.placer(M.ordonner([base])));
  const refs = M.lireRefs(lire(fx, 'refs.out')).refs, et = M.etiquettes(refs, {});
  const noms = (et.get(f[0].h) || []).map((e) => e.type + ':' + e.nom).join(',');
  return `repli=${repli} etiquette=${noms}`;
};
P.g51 = (M) => {
  const S = 's'.repeat(40), T = 't'.repeat(40);
  const refs = [{ ref: 'refs/tags/v1', sha: T, pelee: S, date: 1 }, { ref: 'refs/remotes/origin/a', sha: S, pelee: '', date: 1 }, { ref: 'refs/heads/b', sha: S, pelee: '', date: 1 }, { ref: 'refs/heads/a', sha: S, pelee: '', date: 1 }, { ref: 'refs/stash', sha: S, pelee: '', date: 1 }];
  const opt = { head: 'refs/heads/a', worktrees: [{ chemin: '/w', branche: 'refs/heads/b' }] };
  const rendu = (rs) => JSON.stringify([...M.etiquettes(rs, opt)]);
  const perms = (a) => (a.length <= 1 ? [a] : a.flatMap((x, i) => perms([...a.slice(0, i), ...a.slice(i + 1)]).map((p) => [x, ...p])));
  const toutes = perms(refs), ref0 = rendu(refs), stable = toutes.length === 120 && toutes.every((p) => rendu(p) === ref0);
  const m = M.etiquettes(refs, opt), l = m.get(S) || [];
  return `ordre=${l.map((e) => e.nom).join(',')} groupes=${m.size} stable=${stable} wt=${l.find((e) => e.nom === 'b')?.worktree} cour=${l.filter((e) => e.courante).map((e) => e.nom).join('+')}`;
};
P.g51b = (M, fx) => {
  const refs = M.lireRefs(lire(fx, 'refs.out')).refs, tete = lire(fx, 'tete-main.txt').trim();
  const noms = (rs) => (M.etiquettes(rs, { head: 'refs/heads/main' }).get(tete) || []).map((e) => e.nom).join(',');
  const toutes = [...M.etiquettes(refs, {}).values()].flat().map((e) => e.nom);
  return `${noms(refs)} inverse=${noms([...refs].reverse()) === noms(refs)} virgule=${toutes.includes('a,b')}`;
};
P.g52 = (M) => Array.from({ length: 20 }, (_, i) => M.teinte(i === 0 ? 'feat/a,b é' : 'branche-' + i)).join(' ');
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

echo "━━ G4 placement des couloirs"
assert_eq "G4.1 chaque arête vise la colonne de son parent plus bas, aucun couloir ouvert, 2 racines" "$(Q g41)" "viol=0 ouverts=0 racines=2 rangees=$(G rev-list --count refs/heads/main)"
assert_eq "G4.2 octopus : 3 parents, 2 arêtes vers des couloirs distincts, suite du premier parent" "$(Q g42)" "n=1 s=2 distincts=true fusion=true suite=true"
R="$(Q g43)"; K="$(echo "$R" | sed -n 's/^ouverts=\([0-9]*\) .*/\1/p')"
assert_eq "G4.3 fenêtre -n 10 : un couloir ouvert par parent hors fenêtre, aucune racine à tort" "$(echo "$R" | sed 's/^ouverts=[0-9]* hors=[0-9]* //')" "egal=true listes=true racines=0 tort=0"
assert_eq "G4.3b la fenêtre laisse bien au moins un couloir ouvert (témoin non vide)" "$([ "${K:-0}" -ge 1 ] && echo oui)" "oui"
for v in b c d e; do Q g44a > "$AUX/p-a.json"; Q g44$v > "$AUX/p-$v.json"; cmp -s "$AUX/p-a.json" "$AUX/p-$v.json"; assert_ok "G4.4$v même placement (rappel, copie profonde, listes mélangées, commits mélangés)" "$?"; done
assert_eq "G4.4f le témoin de déterminisme n'est pas vide" "$([ "$(wc -c < "$AUX/p-a.json")" -gt 3000 ] && echo oui)" "oui"
assert_eq "G4.5 quatre couloirs vus ; couloirsMax 2 rabat tout sur 0-1, replies > 0" "$(Q g45)" "vus=4 max=3 replies0=0 | max2=1 largeur2=2 replies2=true"
R="$(Q g46)"; echo "  ℹ perf placer 1000 commits : $R"
assert_eq "G4.6 historique dense (>= 5 couloirs), placement rapide" "$(echo "$R" | sed 's/^ms=[0-9.]* vus=[0-9]* //')" "rangees=1000 dense=true rapide=true"
assert_eq "G4.7 branche mergée repliée : ajouter sa liste ne change ni l'ordre ni le placement, son étiquette suit sa pointe" "$(Q g48)" "repli=true etiquette=locale:f"

echo "━━ G5 étiquettes et teinte"
assert_eq "G5.1 ordre HEAD, a, b, origin/a, v1 pour les 120 permutations d'entrée ; tag pelé ; worktree ; courante" "$(Q g51)" "ordre=HEAD,a,b,origin/a,v1 groupes=1 stable=true wt=/w cour=HEAD+a"
assert_eq "G5.1b plusieurs refs sur le commit de tête du dépôt fabriqué (tag annoté, distante), entrée inversée" "$(Q g51b)" "HEAD,b2,main,origin/main,v1 inverse=true virgule=true"
T1="$(Q g52)"; T2="$(Q g52)"
assert_eq "G5.2 teinte stable entre deux processus" "$T1" "$T2"
assert_eq "G5.2b teinte dans 1..5 et non constante" "$(echo "$T1" | tr ' ' '\n' | awk '$1<1||$1>5||$1!=int($1){m=1} {v[$1]=1} END{n=0; for(k in v)n++; print (m?"hors":"dans"), (n>=3?"varie":"constante")}')" "dans varie"

echo "━━ Mutants (chaque mutant : copie du module, motif fixe, FAIL si le motif manque ou si la sonde reste verte)"
mutant() { # nom, motif fixe, remplacement
  mkdir -p "$WORK/mut/$1"
  node -e 'const fs=require("fs");const [,, src, dst, de, vers]=process.argv;const s=fs.readFileSync(src,"utf8");const n=s.split(de).length-1;if(n!==1){console.error("motif trouvé "+n+" fois");process.exit(1)}fs.writeFileSync(dst,s.split(de).join(vers))' "$MOD" "$WORK/mut/$1/vf-cockpit-git-graphe.mjs" "$2" "$3"
  local rc=$?; assert_eq "$1 : le motif fixe «$2» existe exactement une fois" "$rc" "0"
}
rouge() { # libellé, obtenu, vert attendu
  case "$2" in charge-ko*|sonde-ko*|"") echo "  ❌ FAIL — $1 (mutant inexploitable : [$2])"; FAIL=$((FAIL+1));; *)
    if [ "$2" != "$3" ]; then echo "  ✅ PASS — $1 (rouge : [$2])"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (la sonde reste verte)"; FAIL=$((FAIL+1)); fi;; esac
}
MM() { echo "$WORK/mut/$1/vf-cockpit-git-graphe.mjs"; }
mutant M-ALIGN '!motif.test(h) || ' ''
rouge "M-ALIGN (motif du sha retiré) rougit G1.3" "$(Q g13 "$(MM M-ALIGN)")" "ko ko ko ok"
assert_eq "M-ALIGN : la sonde G1.1 reste verte sur le mutant (mutant chargé, fixture vivante)" "$(Q g11 "$(MM M-ALIGN)")" "ok 25"
assert_eq "M-ALIGN ne rougit PAS G1.2 : le motif seul ne détecte aucune coupe (c'est le rôle de M-PAQUET)" "$(Q g12 "$(MM M-ALIGN)" | cut -d' ' -f1)" "0"
mutant M-PAQUET "if (j[n] !== '' || n % 5 !== 0) return ko('sortie désalignée'); // GARDE-ALIGNEMENT" ''
R="$(Q g12 "$(MM M-PAQUET)")"
rouge "M-PAQUET (compte de champs et NUL final retirés) rougit G1.2" "$(echo "$R" | cut -d' ' -f1)" "0"
assert_eq "M-PAQUET : G1.3 reste vert sur le mutant (pas de rouge pour une autre raison)" "$(Q g13 "$(MM M-PAQUET)")" "ko ko ko ok"
mutant M-OCTOPUS 'for (let i = 1; i < c.p.length; i++) {' 'for (let i = 1; i < Math.min(c.p.length, 2); i++) {'
rouge "M-OCTOPUS (seul p[1] traité) rougit G4.2" "$(Q g42 "$(MM M-OCTOPUS)")" "n=1 s=2 distincts=true fusion=true suite=true"
assert_eq "M-OCTOPUS : G4.1 sans octopus de fixture reste exécutable (mutant chargé)" "$(Q g11 "$(MM M-OCTOPUS)")" "ok 25"
mutant M-RACINE 'lanes[col] = null; /* LIBERE-RACINE */' 'lanes[col] = c.h; /* mutant */'
rouge "M-RACINE (couloir non libéré à une racine) rougit G4.1" "$(Q g41 "$(MM M-RACINE)")" "viol=0 ouverts=0 racines=2 rangees=$(G rev-list --count refs/heads/main)"
assert_eq "M-RACINE : l'octopus reste placé (mutant chargé)" "$(Q g42 "$(MM M-RACINE)")" "n=1 s=2 distincts=true fusion=true suite=true"
mutant M-ORDRE 'liste.sort(comparer); // TRI-ETIQUETTES' '/* mutant */'
rouge "M-ORDRE (tri retiré dans etiquettes) rougit G5.1" "$(Q g51 "$(MM M-ORDRE)")" "ordre=HEAD,a,b,origin/a,v1 groupes=1 stable=true wt=/w cour=HEAD+a"
assert_eq "M-ORDRE : G4.1 reste vert (mutant chargé)" "$(Q g41 "$(MM M-ORDRE)" | cut -d' ' -f1-3)" "viol=0 ouverts=0 racines=2"

echo ""
echo "Résultats : $PASS passés, $FAIL échoués"
[ "$FAIL" -eq 0 ]
