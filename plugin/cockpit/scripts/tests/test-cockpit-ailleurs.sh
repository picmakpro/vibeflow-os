#!/usr/bin/env bash
# test-cockpit-ailleurs.sh — l'onglet Projet voit les phases en cours dans un worktree (N5 de la recette 68, BACKLOG).
# Règle de priorité (documentée dans le README du module) : l'état le plus avancé gagne parmi l'arbre courant et ses worktrees
# (à faire < en cours < à recetter) ; un état clos sur l'arbre courant reste clos ; une clôture lue seulement dans un worktree vaut « à recetter » (rien n'est clos avant d'être fusionné).
#   L0 contrôles positifs des fixtures (git réel) · L1 témoin : carte « en cours » avec décompte et mention du worktree (rouge avant le correctif)
#   L2 priorité : clos reste clos, l'arbre courant plus avancé garde la main, un worktree clos vaut « à recetter »
#   L3 lien symbolique sortant d'un worktree : jamais suivi · L4 pied de jalon et signal@1 · L5 chaînes piégées nettoyées
# Fixtures construites par la suite dans mktemp. Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t.test GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t.test
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"
GIT_REEL="$(command -v git)"
G_() { "$GIT_REEL" "$@"; }
export HOME="$WORK/home"

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_not() { if [[ "$2" != *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (a trouvé [$3])"; FAIL=$((FAIL+1)); fi; }

# carte.mjs <scripts> <racine> <n> : état et pied de la carte de la phase <n> dans l'onglet Projet, sous la forme « st|foot » ; « signal » rend « etat|faits/total|ailleurs » depuis signal@1
cat > "$AUX/q.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const [, , scripts, what, root, n] = process.argv;
const imp = (f) => import(pathToFileURL(path.join(scripts, f)).href);
if (what === 'carte') {
  const m = await imp('vf-cockpit-project.mjs'); const g = m.buildProjectGraph(root);
  const x = g.nodes.find((y) => y.id === `ph-${n}`);
  console.log(x ? `${x.st}|${x.foot}` : 'absente');
} else if (what === 'jalon') {
  const m = await imp('vf-cockpit-project.mjs'); const g = m.buildProjectGraph(root);
  console.log(g.nodes.find((y) => y.kind === 'jalon').foot);
} else if (what === 'details') {
  const m = await imp('vf-cockpit-project.mjs'); const g = m.buildProjectGraph(root);
  console.log(g.nodes.find((y) => y.id === `ph-${n}`)?.details ?? '');
} else if (what === 'signal') {
  const m = await imp('vf-cockpit-signal.mjs'); const s = m.collectSignal(root, { home: process.env.HOME });
  const p = s.phases.find((y) => y.n === n);
  console.log(p ? `${p.avancement.etat}|${p.avancement.plans.faits}/${p.avancement.plans.total}|${p.avancement.ailleurs?.arbre ?? ''}` : 'absente');
}
JS
carte() { node "$AUX/q.mjs" "$SCRIPTS" carte "$1" "$2"; }
plan() { mkdir -p "$1"; printf -- '---\nwave: 1\n---\n<objective>\nUn plan\n</objective>\n' > "$1/$2-PLAN.md"; }
somme() { printf -- '# fait\n' > "$1/$2-SUMMARY.md"; }

# --- fixtures : lab plat git, ROADMAP à 6 phases, un worktree « wt-phase-2 » ---
L="$WORK/lab"; W="$WORK/wt-phase-2"; HORS="$WORK/hors"
G_ init -q -b main "$L"
mkdir -p "$L/.planning/phases"
cat > "$L/.planning/ROADMAP.md" <<'EOF'
# Roadmap

## Milestones

- 🚧 **v1.0 Test** - Phases 1-6

## Phases

- [ ] **Phase 1: Un** - a
- [ ] **Phase 2: Deux** - b
- [x] **Phase 3: Trois** - c
- [ ] **Phase 4: Quatre** - d
- [ ] **Phase 5: Cinq** - e
- [ ] **Phase 6: Six** - f
EOF
# arbre courant : phase 5 en cours (1 plan fait sur 2), phase 6 à recetter (1/1), phase 3 close (dossier vide)
D5="$L/.planning/phases/05-cinq"; plan "$D5" 05-01; somme "$D5" 05-01; plan "$D5" 05-02
D6="$L/.planning/phases/06-six"; plan "$D6" 06-01; somme "$D6" 06-01
printf 'x\n' > "$L/.planning/.gardien"
G_ -C "$L" add -A; G_ -C "$L" commit -q -m c0
G_ -C "$L" branch feat/phase-2-x
G_ -C "$L" worktree add -q "$W" feat/phase-2-x 2>/dev/null
# worktree : phase 2 en cours (2 plans faits sur 3), phase 3 non close (plans seulement), phase 5 à recetter (2/2), phase 6 en cours (1 plan fait sur 2)
D2="$W/.planning/phases/02-deux"; plan "$D2" 02-01; somme "$D2" 02-01; plan "$D2" 02-02; somme "$D2" 02-02; plan "$D2" 02-03
D3="$W/.planning/phases/03-trois"; plan "$D3" 03-01
D5W="$W/.planning/phases/05-cinq"; plan "$D5W" 05-01; somme "$D5W" 05-01; plan "$D5W" 05-02; somme "$D5W" 05-02
D6W="$W/.planning/phases/06-six"; plan "$D6W" 06-01; plan "$D6W" 06-02; somme "$D6W" 06-01
# phase 4 du worktree : dossier qui est un lien symbolique vers un dossier HORS du worktree, plein de plans faits
mkdir -p "$HORS"; plan "$HORS" 04-01; somme "$HORS" 04-01
ln -s "$HORS" "$W/.planning/phases/04-quatre"

echo "=== L0 — contrôles positifs des fixtures ==="
assert_eq "L0.1 — git réel voit deux arbres" "$(G_ -C "$L" worktree list --porcelain | grep -c '^worktree ')" "2"
assert_eq "L0.2 — le dossier de la phase 2 du worktree porte 3 plans et 2 sommaires" "$(ls "$D2" | grep -c PLAN)/$(ls "$D2" | grep -c SUMMARY)" "3/2"
assert_eq "L0.3 — l'arbre principal n'a aucun dossier pour la phase 2" "$(ls "$L/.planning/phases" | grep -c '^02-')" "0"
assert_eq "L0.4 — le lien de la phase 4 sort du worktree et porte un plan fait" "$(cd "$W/.planning/phases/04-quatre" && pwd -P)|$(ls "$W/.planning/phases/04-quatre" | wc -l | tr -d ' ')" "$(cd "$HORS" && pwd -P)|2"

echo "=== L1 — témoin : la carte de la phase 2 sort « en cours » avec son décompte ==="
assert_eq "L1.1 — la carte de la phase 2 est active (en cours), jamais « à faire »" "$(carte "$L" 2 | cut -d'|' -f1)" "active"
assert_has "L1.2 — son pied porte le décompte 2/3 plans" "$(carte "$L" 2)" "2/3 plans"
assert_has "L1.3 — son pied dit le worktree" "$(carte "$L" 2)" "dans worktree wt-phase-2"
assert_has "L1.4 — le détail dit que l'avancement est lu dans le worktree" "$(node "$AUX/q.mjs" "$SCRIPTS" details "$L" 2)" "Avancement lu dans le worktree wt-phase-2"
assert_eq "L1.5 — la phase 1, nulle part commencée, reste à faire sans mention" "$(carte "$L" 1)" "todo|pas de plan"

echo "=== L2 — priorité ==="
assert_eq "L2.1 — clos sur l'arbre courant reste clos (phase 3 : plans non faits dans le worktree)" "$(carte "$L" 3 | cut -d'|' -f1)" "done"
assert_not "L2.2 — la phase 3 close ne porte aucune mention de worktree" "$(carte "$L" 3)" "worktree"
assert_has "L2.3 — le worktree plus avancé gagne : phase 5 passe à recetter (2/2)" "$(carte "$L" 5)" "à recetter · 2/2 plans · dans worktree wt-phase-2"
assert_eq "L2.4 — l'arbre courant plus avancé garde la main : phase 6 à recetter, sans mention" "$(carte "$L" 6)" "active|à recetter · 1/1 plans"

echo "=== L3 — lien symbolique sortant ==="
assert_eq "L3.1 — la phase 4 (dossier lié hors du worktree) reste à faire : le lien n'est pas suivi" "$(carte "$L" 4)" "todo|pas de plan"

echo "=== L4 — jalon et signal@1 ==="
assert_has "L4.2 — pied de jalon : 1 en cours (la 2), 2 à recetter (la 5 et la 6)" "$(node "$AUX/q.mjs" "$SCRIPTS" jalon "$L")" "1 en cours · 2 à recetter · 2 à faire"
assert_eq "L4.3 — signal@1 : la phase 2 porte l'avancement du worktree" "$(node "$AUX/q.mjs" "$SCRIPTS" signal "$L" 2)" "en-cours|2/3|wt-phase-2"

echo "=== L5 — sans worktree, rien ne change ==="
SOLO="$WORK/solo"; G_ init -q -b main "$SOLO"; mkdir -p "$SOLO/.planning"; cp "$L/.planning/ROADMAP.md" "$SOLO/.planning/"
assert_eq "L5.1 — un lab sans worktree : phase 2 à faire, sans mention" "$(carte "$SOLO" 2)" "todo|pas de plan"

echo
echo "Résultat : $PASS passés, $FAIL en échec"
[ "$FAIL" -eq 0 ]
