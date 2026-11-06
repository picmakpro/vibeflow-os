#!/usr/bin/env bash
# test-cockpit-sante.sh — le contrôle de santé du cockpit (lib/health.mjs + ui/20-health.js), retours du panel PU-G-079, 081 à 084.
#   S1 titre = légende (079) · S2 clé de format réel dans un fichier de test : signalée « probablement factice », ton baissé (081)
#   S3 fichiers tiers hors des conseils « très gros » et « inutilisé » (082) · S4 l'introduction ne cite que les services utilisés (083)
#   S5 l'intitulé du bloc de l'onglet Projet dit « (security only) » (084)
#   M  mutations : chaque correctif est défait dans une COPIE du moteur ; la sonde doit rougir (une preuve incapable de rougir ne prouve rien)
# Le moteur est joué par cockpit-sante/sonde.mjs (fichiers fabriqués dans mktemp, panneau dans un contexte minimal sans navigateur).
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
MOTEUR="$SCRIPTS/../skills/cockpit-moteur"
SONDE="$SCRIPTS/tests/cockpit-sante/sonde.mjs"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_ne() { if [ "$2" != "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (valeur interdite: [$3])"; FAIL=$((FAIL+1)); fi; }
val() { grep -m1 "^$2=" "$1" | sed "s/^$2=//"; }

node "$SONDE" "$MOTEUR" > "$WORK/ref.out" 2>"$WORK/ref.err"
assert_eq "L0 — la sonde tourne sur le moteur courant (rc 0)" "$?" "0"
assert_eq "L0 — la sonde rend les 28 clés attendues" "$(grep -c '^[a-z0-9._]*=' "$WORK/ref.out")" "28"
R="$WORK/ref.out"

echo "=== S1 — titre et légende (PU-G-079) ==="
assert_eq "S1.1 — 3 importants + 1 à corriger + 1 mineur : le titre compte 5" "$(val "$R" g079.titre)" "5 things need attention"
assert_eq "S1.2 — la légende compte les mêmes 5" "$(val "$R" g079.legende)" "3 important, 1 worth fixing, 1 minor"
assert_eq "S1.3 — le titre du bouton porte le même compte" "$(val "$R" g079.titre_bouton)" "Health check: 5 things need attention"
assert_eq "S1.4 — la pastille du bouton porte le même compte" "$(val "$R" g079.pastille)" "5"
assert_eq "S1.5 — singulier : « 1 thing needs attention »" "$(val "$R" g079.titre_un)" "1 thing needs attention"
assert_eq "S1.6 — seulement des mineurs : « Nothing urgent », aucun nombre" "$(val "$R" g079.titre_mineurs)" "Nothing urgent"

echo "=== S2 — clé dans un fichier de test (PU-G-081) ==="
assert_eq "S2.1 — la clé de format réel est toujours signalée en test" "$(val "$R" g081.present)" "true"
assert_eq "S2.2 — mais au ton baissé : « à corriger » (medium), jamais « important »" "$(val "$R" g081.severite)" "medium"
assert_eq "S2.3 — le titre dit que la clé est probablement factice" "$(val "$R" g081.titre)" "A key in aws.test.js is probably fake"
assert_eq "S2.4 — le détail dit « probably fake »" "$(val "$R" g081.detail_factice)" "true"
assert_eq "S2.5 — le détail n'a plus le ton d'alarme (« get into … as you »)" "$(val "$R" g081.detail_alarmiste)" "false"
assert_eq "S2.6 — témoin : la même clé dans le code de l'app reste « important »" "$(val "$R" g081.reel.severite)" "high"
assert_eq "S2.7 — témoin : et garde le ton d'alarme" "$(val "$R" g081.reel.alarmiste)" "true"
assert_eq "S2.8 — témoin : sans le mot « factice »" "$(val "$R" g081.reel.factice)" "false"

echo "=== S3 — fichiers tiers (PU-G-082) ==="
assert_eq "S3.1 — « très gros » : seul le fichier du projet (ni vendor/, ni *.bundled.js, ni *.min.js)" "$(val "$R" g082.gros)" '["src/big.js"]'
assert_eq "S3.2 — « inutilisé » : les orphelins du projet seulement" "$(val "$R" g082.inutilises)" '["src/big.js","src/orphan.js"]'

echo "=== S4 — services cités (PU-G-083) ==="
assert_eq "S4.1 — dépôt sans service : liste vide" "$(val "$R" g083.aucun)" "[]"
assert_eq "S4.2 — Supabase repéré à l'import" "$(val "$R" g083.supabase)" '["Supabase"]'
assert_eq "S4.3 — Firebase repéré à l'import" "$(val "$R" g083.firebase)" '["Firebase"]'
assert_eq "S4.4 — Stripe repéré à l'import" "$(val "$R" g083.stripe)" '["Stripe"]'
assert_eq "S4.5 — les trois ensemble, dans cet ordre" "$(val "$R" g083.trois)" '["Supabase","Firebase","Stripe"]'
assert_eq "S4.6 — panneau, aucun service : aucun des trois noms" "$(val "$R" g083.ui.sans)" "false"
assert_eq "S4.7 — panneau, graphe ancien sans champ : aucun des trois noms" "$(val "$R" g083.ui.sans_champ)" "false"
assert_eq "S4.8 — panneau, aucun service : pas de phrase vide « … utilise : . »" "$(val "$R" g083.ui.phrase_vide)" "false"
assert_eq "S4.9 — panneau, Supabase seul : Supabase, ni Firebase ni Stripe" "$(val "$R" g083.ui.avec_supabase)" "true"
assert_eq "S4.10 — panneau, trois services : les trois" "$(val "$R" g083.ui.trois)" "true"

echo "=== S5 — onglet Projet (PU-G-084) ==="
assert_eq "S5.1 — onglet Projet : « Health (security only) »" "$(val "$R" g084.projet)" "Health (security only)"
assert_eq "S5.2 — onglet Code : « Health » inchangé" "$(val "$R" g084.code)" "Health"

# --- mutations : le correctif défait dans une copie, la clé visée doit changer ---
# mutant <nom> <fichier relatif> <ancre exacte> <remplacement> <clé> : la copie est rejouée, la clé doit différer de la référence
mutant() {
  local nom="$1" fic="$2" ancre="$3" rempl="$4" cle="$5" d="$WORK/m-$1"
  mkdir -p "$d/scripts" "$d/assets/ui" && cp -R "$MOTEUR/scripts/lib" "$d/scripts/lib" && cp "$MOTEUR/assets/ui/20-health.js" "$d/assets/ui/"
  local ok; ok="$(node -e '
    const fs=require("fs"); const [f,a,b]=process.argv.slice(1); const s=fs.readFileSync(f,"utf8");
    if(!s.includes(a)){console.log("ancre-introuvable");process.exit(0)}
    fs.writeFileSync(f,s.split(a).join(b)); console.log("ok")' "$d/$fic" "$ancre" "$rempl")"
  assert_eq "M.$nom — l'ancre du mutant existe dans le fichier" "$ok" "ok"
  node "$SONDE" "$d" > "$d.out" 2>/dev/null
  assert_ne "M.$nom — la clé $cle rougit sur le mutant" "$(val "$d.out" "$cle")" "$(val "$R" "$cle")"
}
echo "=== M — mutations ==="
mutant 079-titre assets/ui/20-health.js "SC.plural(total, 'thing')" "SC.plural(urgent, 'thing')" g079.titre
mutant 079-pastille assets/ui/20-health.js "total > 99 ? '99+' : String(total)" "urgent > 99 ? '99+' : String(urgent)" g079.pastille
mutant 081-severite scripts/lib/health.mjs "const allTest = group.every((g) => g.list.every((s) => s.test));" "const allTest = false;" g081.severite
mutant 081-titre scripts/lib/health.mjs "const allTest = group.every((g) => g.list.every((s) => s.test));" "const allTest = false;" g081.titre
mutant 082-gros scripts/lib/health.mjs "&& !THIRD_PARTY.test(f.p) && !/(^|" "&& !/(^|" g082.gros
mutant 082-inutilises scripts/lib/health.mjs "TEST_FILE.test(f.p) || THIRD_PARTY.test(f.p) ||" "TEST_FILE.test(f.p) ||" g082.inutilises
mutant 083-moteur scripts/lib/health.mjs "if (usesSupabase) services.push('Supabase');" "services.push('Supabase');" g083.aucun
mutant 083-ui assets/ui/20-health.js "\${!PLAN && services.length ?" "\${!PLAN ?" g083.ui.phrase_vide
mutant 083-liste-figee assets/ui/20-health.js "services.join(', ')}.\`)}</p>\` : ''}" "services.join(', ')}. Supabase, Firebase, Stripe.\`)}</p>\` : ''}" g083.ui.avec_supabase
mutant 084 assets/ui/20-health.js "'Health (security only)' : 'Health'" "'Health' : 'Health'" g084.projet

echo
echo "=== Bilan : $PASS passés, $FAIL en échec ==="
[ "$FAIL" -eq 0 ]
