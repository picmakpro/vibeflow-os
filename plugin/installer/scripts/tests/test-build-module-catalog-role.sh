#!/usr/bin/env bash
# Test de build-module-catalog.sh sous un poste (Phase 58, RLPO-05, P58-D-17) — autonome.
# Cas CAT-TRACE-1..3, CAT-SOLO, CAT-PRODUCT, CAT-DEV, CAT-ENV, CAT-PRIO, CAT-ROLES-INV,
# CAT-POSTE-INV, CAT-COL3, CAT-INTEGRITE ; mutants CAT-MUT-1..3.
# La sortie sans poste est comparée À L'OCTET (cmp -s) à celle de la copie gelée du catalogue
# d'avant la phase (fixtures/build-module-catalog-pre-58.sh = octets de a2ed5094).
# zsh aliase grep : le script est lancé par `bash`, `command grep` partout.
set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$(cd "$TESTS_DIR/.." && pwd)/build-module-catalog.sh"
FROZEN="$TESTS_DIR/fixtures/build-module-catalog-pre-58.sh"
REPO_ROOT="$(cd "$TESTS_DIR/../../../.." && pwd)"
PLUGIN="$REPO_ROOT/plugin"
ROLES_SH="$PLUGIN/_internal/module-roles.sh"
TARGET="$SCRIPT"
MARK="zzSECRETzz"

pass=0; fail=0; skipped=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }
skip() { echo "  ⊘ SKIP $1"; skipped=$((skipped+1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
OUTS="$TMP/outs"; mkdir -p "$OUTS"; nout=0

echo "== test-build-module-catalog-role =="

# cat_run <racine> <env|-> args... -> $RC, $TMP/o (stdout), $TMP/e (stderr) ; archive la sortie pour CAT-COL3
cat_run() {
  local root="$1" ev="$2"; shift 2
  [ "$ev" = "-" ] && ev=""
  # shellcheck disable=SC2086
  env -u VF_ROLE VF_MODULES_ROOT="$root" $ev bash "$TARGET" "$@" >"$TMP/o" 2>"$TMP/e"; RC=$?
  nout=$((nout+1)); cp "$TMP/o" "$OUTS/$nout"
}
frozen_run() { env -u VF_ROLE VF_MODULES_ROOT="$1" bash "$FROZEN" >"$TMP/f" 2>/dev/null; }
names_of() { cut -f1 "$1" | LC_ALL=C sort; }

# ---------- Fixture isolée -------------------------------------------------------------------------
FIX="$TMP/fix"
mkdir -p "$FIX/zeta" "$FIX/alpha" "$FIX/boss" "$FIX/cache" "$FIX/devmod" "$FIX/sans-manifeste"
cat > "$FIX/zeta/module.json" <<'JSON'
{ "name": "zeta", "version": "v1.0.0", "type": "single-skill", "description": "Module Zeta de test.", "requires": [] }
JSON
cat > "$FIX/alpha/module.json" <<'JSON'
{ "name": "alpha", "version": "v1.0.0", "type": "single-skill", "description": "Module Alpha de test.", "requires": [] }
JSON
cat > "$FIX/boss/module.json" <<'JSON'
{ "name": "boss", "version": "v1.0.0", "type": "agent", "description": "Module Boss obligatoire.", "mandatory": true, "requires": [] }
JSON
cat > "$FIX/cache/module.json" <<'JSON'
{ "name": "cache", "version": "v1.0.0", "type": "doc-only", "description": "Module caché WIP.", "proposable": false, "requires": [] }
JSON
cat > "$FIX/devmod/module.json" <<'JSON'
{ "name": "devmod", "version": "v1.0.0", "type": "single-skill", "description": "Module réservé au poste dev.", "roles": ["dev"], "requires": [] }
JSON
: > "$FIX/sans-manifeste/README.md"

# ---------- Tracer ---------------------------------------------------------------------------------
cat_run "$PLUGIN" - --role product
has_devo="$(cut -f1 "$TMP/o" | command grep -cx 'dev-orchestrator')"
cons3="$(awk -F'\t' '$1 == "conductor" { print $3 }' "$TMP/o")"
{ [ "$RC" -eq 0 ] && [ "$has_devo" = "0" ] && [ "$cons3" = "mandatory" ]; } \
  && ok "CAT-TRACE-1 --role product : pas de dev-orchestrator, conductor mandatory, rc 0" \
  || ko "CAT-TRACE-1 attendu rc 0, dev-orchestrator absent, conductor mandatory ; obtenu rc $RC devo=$has_devo conductor=[$cons3]"

cat_run "$PLUGIN" -; cp "$TMP/o" "$TMP/real-new"; frozen_run "$PLUGIN"
cmp -s "$TMP/real-new" "$TMP/f" && ok "CAT-TRACE-2 sans poste sur le dépôt réel : identique à l'octet à la copie gelée" \
  || ko "CAT-TRACE-2 sortie sans poste différente de la copie gelée ($(wc -c < "$TMP/real-new" | tr -d ' ') contre $(wc -c < "$TMP/f" | tr -d ' ') octets)"

cat_run "$FIX" -; cp "$TMP/o" "$TMP/fix-new"; frozen_run "$FIX"
{ cmp -s "$TMP/fix-new" "$TMP/f" && [ -s "$TMP/f" ]; } && ok "CAT-TRACE-3 sans poste sur la fixture isolée : identique à l'octet à la copie gelée" \
  || ko "CAT-TRACE-3 sortie sans poste de la fixture différente de la copie gelée"

# ---------- solo, product, dev ---------------------------------------------------------------------
cat_run "$PLUGIN" - --role solo; cp "$TMP/o" "$TMP/solo-flag"
cat_run "$PLUGIN" VF_ROLE=solo; cp "$TMP/o" "$TMP/solo-env"
probe_solo() { cat_run "$PLUGIN" - --role solo; cmp -s "$TMP/o" "$TMP/real-new"; }
{ cmp -s "$TMP/solo-flag" "$TMP/real-new" && cmp -s "$TMP/solo-env" "$TMP/real-new"; } \
  && ok "CAT-SOLO --role solo et VF_ROLE=solo : sortie identique à la sortie sans poste" \
  || ko "CAT-SOLO attendu sortie identique à l'absence de poste, obtenu un écart"

probe_product() {
  cat_run "$PLUGIN" - --role product; names_of "$TMP/o" > "$TMP/prod-names"
  names_of "$TMP/real-new" > "$TMP/all-names"
  MOINS="$(comm -23 "$TMP/all-names" "$TMP/prod-names" | tr '\n' ' ')"
  PLUS="$(comm -13 "$TMP/all-names" "$TMP/prod-names" | tr '\n' ' ')"
  [ "$MOINS" = "dev-orchestrator mobile-test mobile-test-team " ] && [ -z "$PLUS" ]
}
probe_product && ok "CAT-PRODUCT product = sortie sans poste moins [$MOINS], rien en plus" \
  || ko "CAT-PRODUCT attendu moins « dev-orchestrator mobile-test mobile-test-team », obtenu moins [$MOINS] plus [$PLUS]"

cat_run "$PLUGIN" - --role dev
cmp -s "$TMP/o" "$TMP/real-new" && ok "CAT-DEV --role dev : sortie identique à la sortie sans poste" \
  || ko "CAT-DEV attendu sortie identique, obtenu un écart"

cat_run "$PLUGIN" - --role product; cp "$TMP/o" "$TMP/prod-flag"
cat_run "$PLUGIN" VF_ROLE=product; cp "$TMP/o" "$TMP/prod-env"
cmp -s "$TMP/prod-flag" "$TMP/prod-env" && ok "CAT-ENV VF_ROLE=product sans drapeau = --role product" \
  || ko "CAT-ENV attendu même sortie que --role product, obtenu un écart"

probe_prio() { cat_run "$PLUGIN" VF_ROLE=dev --role product; cmp -s "$TMP/o" "$TMP/prod-flag"; }
probe_prio && ok "CAT-PRIO VF_ROLE=dev --role product : le drapeau l'emporte" \
  || ko "CAT-PRIO attendu la sortie de --role product, obtenu un écart"

# ---------- Erreurs bruyantes -----------------------------------------------------------------------
BADFIX="$TMP/badfix"; mkdir -p "$BADFIX/okmod" "$BADFIX/badmod"
cat > "$BADFIX/okmod/module.json" <<'JSON'
{ "name": "okmod", "version": "v1.0.0", "type": "single-skill", "description": "ok", "requires": [] }
JSON
cat > "$BADFIX/badmod/module.json" <<'JSON'
{ "name": "badmod", "version": "v1.0.0", "type": "single-skill", "description": "roles vide", "roles": [], "requires": [] }
JSON
cat_run "$BADFIX" - --role product; A="$RC"; AERR="$(cat "$TMP/e")"
cat_run "$BADFIX" -; B="$RC"; BHAS="$(cut -f1 "$TMP/o" | command grep -cx badmod)"
{ [ "$A" -eq 1 ] && printf '%s' "$AERR" | command grep -q 'badmod' && [ "$B" -eq 0 ] && [ "$BHAS" = "1" ]; } \
  && ok "CAT-ROLES-INV roles [] : --role product rc 1 nommant badmod ; sans poste rc 0 et module listé" \
  || ko "CAT-ROLES-INV attendu rc 1 + nom du module puis rc 0 + module listé, obtenu rc $A [$AERR] puis rc $B (listé: $BHAS)"

cat_run "$PLUGIN" - --role "$MARK"; A="$RC"; AOUT="$(cat "$TMP/o")"; AERR="$(cat "$TMP/e")"
leak=0; printf '%s%s' "$AOUT" "$AERR" | command grep -q "$MARK" && leak=1
cat_run "$PLUGIN" - --role; B="$RC"
cat_run "$PLUGIN" - --role=; C="$RC"
cat_run "$PLUGIN" - --zz; D="$RC"
cat_run "$PLUGIN" "VF_ROLE=$MARK"; E="$RC"; EALL="$(cat "$TMP/o" "$TMP/e")"
leak2=0; printf '%s' "$EALL" | command grep -q "$MARK" && leak2=1
{ [ "$A" -eq 1 ] && printf '%s' "$AERR" | command grep -q 'poste invalide' && [ "$leak" -eq 0 ] \
  && [ "$B" -eq 1 ] && [ "$C" -eq 1 ] && [ "$D" -eq 1 ] && [ "$E" -eq 1 ] && [ "$leak2" -eq 0 ]; } \
  && ok "CAT-POSTE-INV poste hors ensemble, --role sans valeur, --role= vide, argument inconnu, VF_ROLE hostile : rc 1, valeur jamais réimprimée" \
  || ko "CAT-POSTE-INV attendu rc 1 partout sans fuite, obtenu $A/$B/$C/$D/$E fuite=$leak/$leak2 err[$AERR]"

# ---------- Trois colonnes --------------------------------------------------------------------------
badcol=0; nfiles=0
for f in "$OUTS"/*; do
  [ -s "$f" ] || continue
  nfiles=$((nfiles+1))
  n="$(awk -F'\t' 'NF != 3 || ($3 != "mandatory" && $3 != "optional") { n++ } END { print n+0 }' "$f")"
  [ "$n" = "0" ] || badcol=$((badcol+n))
done
{ [ "$badcol" -eq 0 ] && [ "$nfiles" -gt 5 ]; } && ok "CAT-COL3 $nfiles sorties : chaque ligne a 3 champs, le 3e vaut mandatory ou optional" \
  || ko "CAT-COL3 attendu 0 ligne fautive sur plus de 5 sorties, obtenu $badcol sur $nfiles"

# ---------- Intégrité de la copie gelée ------------------------------------------------------------
if git -C "$REPO_ROOT" cat-file -e a2ed5094:plugin/installer/scripts/build-module-catalog.sh 2>/dev/null; then
  git -C "$REPO_ROOT" show a2ed5094:plugin/installer/scripts/build-module-catalog.sh > "$TMP/a2ed5094.sh" 2>/dev/null
  cmp -s "$TMP/a2ed5094.sh" "$FROZEN" && ok "CAT-INTEGRITE la copie gelée est identique à l'objet a2ed5094" \
    || ko "CAT-INTEGRITE la copie gelée diffère de a2ed5094"
else
  skip "CAT-INTEGRITE (clone superficiel : a2ed5094 illisible)"
fi

# ---------- Mutants ---------------------------------------------------------------------------------
MT="$TMP/mut"; mkdir -p "$MT/installer/scripts" "$MT/_internal"
cp "$ROLES_SH" "$MT/_internal/module-roles.sh"
MUTBIN="$MT/installer/scripts/build-module-catalog.sh"

# mutant <id> <awk> <probe> <description>
mutant() {
  local id="$1" prog="$2" probe="$3" desc="$4"
  awk "$prog" "$SCRIPT" > "$MUTBIN"
  if cmp -s "$MUTBIN" "$SCRIPT"; then ko "$id : mutant NON OPPOSABLE (copie identique à l'original) — $desc"; return; fi
  if ! bash -n "$MUTBIN" 2>/dev/null; then ko "$id : mutant invalide (bash -n) — $desc"; return; fi
  TARGET="$MUTBIN"; "$probe"; local mrc=$?
  local mdesc="obtenu sur le mutant : $(wc -c < "$TMP/o" | tr -d ' ') octets en sortie (le cas ${probe#probe_} exige la sortie de l'original)"
  TARGET="$SCRIPT"; "$probe"; local orc=$?
  if [ "$mrc" -ne 0 ] && [ "$orc" -eq 0 ]; then ok "$id tué ($desc) — attendu vert sur l'original, rouge sur le mutant ; $mdesc"
  elif [ "$mrc" -eq 0 ]; then ko "$id mutant SURVIVANT ($desc) — le cas ${probe#probe_} reste vert"
  else ko "$id original rouge après mutation ($desc)"; fi
  TARGET="$SCRIPT"
}

mutant CAT-MUT-1 '{ if (index($0, "      *\"$NL$name$NL\"*) ;;")) { print "      *\"$NL$name$NL\"*) continue ;;" } else if (index($0, "      *) continue ;;")) { print "      *) ;;" } else print }' \
  probe_product "filtre inversé (garde les modules invisibles)"
mutant CAT-MUT-2 '{ if (!d && $0 == "case \"$POSTE\" in") { print "POSTE=\"${VF_ROLE:-$POSTE}\""; d=1 } print }' \
  probe_prio "priorité inversée (VF_ROLE l emporte sur --role)"
mutant CAT-MUT-3 '{ if ($0 == "  product|dev)") print "  solo|product|dev)"; else if (index($0, "bash \"$ROLES_SH\" list \"$POSTE\"")) { sub(/list "\$POSTE"/, "list product"); print } else print }' \
  probe_solo "solo filtré comme product"

# ---------- Assertions statiques sur le skill installeur (58-07, SKILL-1..7) ------------------------
# Chaque assertion est une fonction qui prend un chemin de fichier : rejouée sur une copie altérée par
# SKILL-TEMOIN (la preuve peut rougir). Jamais d'ancre sur un numéro de ligne.
SKILL_MD="$PLUGIN/installer/SKILL.md"
# skill_block <fichier> <regex début> <regex fin> : de la ligne de début (incluse) à celle de fin (exclue)
skill_block() { awk -v a="$2" -v b="$3" '$0 ~ a { f = 1 } f && $0 ~ b && !($0 ~ a) { exit } f { print }' "$1"; }
has_all() { # <texte> <fragment>... : tous présents (littéraux)
  local txt="$1" frag; shift
  for frag in "$@"; do printf '%s\n' "$txt" | command grep -qF -- "$frag" || return 1; done
}
skill_1() { awk '/^2\. / && !a { a = NR } /^2 bis\. / { n++; b = NR } /^3\. / && !c { c = NR } END { exit !(n == 1 && a && c && a < b && b < c) }' "$1"; }
skill_2() { has_all "$(skill_block "$1" '^2 bis\. ' '^3\. ')" 'VF_ROLE' 'solo' 'product' 'dev' 'user' 'un poste est une vue, pas un droit'; }
skill_3() {
  command grep -E '^\| Catalogue' "$1" | command grep -qF -- '--role' || return 1
  command grep -E '^\| Engine' "$1" | command grep -qF 'VF_ROLE' || return 1
  command grep -qF ' role <poste>' "$1"
}
skill_4() { ! command grep -qF "comme s'il était prêt" "$1"; }
skill_5() { has_all "$(skill_block "$1" '^4\. ' '^5\. ')" 'seulement si dev-orchestrator figure au catalogue filtré par le poste'; }
skill_6() { has_all "$(skill_block "$1" '^5\. ' '^6\. ')" 'jamais en poste product'; }
skill_7() {
  ! command grep -qF 'role == mandatory' "$1" && ! command grep -qF 'role=mandatory' "$1" \
    && ! command grep -qF 'description<TAB>role' "$1" \
    && has_all "$(skill_block "$1" '^3\. ' '^4\. ')" 'statut'
}
for n in 1 2 3 4 5 6 7; do
  if "skill_$n" "$SKILL_MD"; then ok "SKILL-$n assertion statique tenue sur plugin/installer/SKILL.md"
  else ko "SKILL-$n assertion statique fausse sur plugin/installer/SKILL.md"; fi
done
# SKILL-TEMOIN : deux copies altérées font rougir SKILL-1 et SKILL-4 (et l'original reste vert sur les deux).
ALT="$TMP/skill-alt"; mkdir -p "$ALT"
awk '!/^2 bis\. /' "$SKILL_MD" > "$ALT/sans-2bis.md"
{ cat "$SKILL_MD"; printf '%s\n' "Les bundles métier incomplets : ne JAMAIS proposer un métier figé comme s'il était prêt."; } > "$ALT/phrase-perimee.md"
if ! skill_1 "$ALT/sans-2bis.md" && skill_1 "$SKILL_MD" && ! skill_4 "$ALT/phrase-perimee.md" && skill_4 "$SKILL_MD"; then
  ok "SKILL-TEMOIN la copie sans « 2 bis. » rougit SKILL-1, la copie à phrase périmée rougit SKILL-4, l'original reste vert"
else
  ko "SKILL-TEMOIN une assertion ne rougit pas sur la copie altérée (SKILL-1 ou SKILL-4 incapable d'échouer)"
fi

# SKILL-TEMOIN-2 : une copie altérée par propriété gardée (2, 3, 5, 6, 7) rougit l'assertion qui la tient.
sed 's/un poste est une vue, pas un droit/un poste est un droit/' "$SKILL_MD" > "$ALT/a2.md"
sed 's/ --role <poste>` |/` |/' "$SKILL_MD" > "$ALT/a3.md"
sed 's/seulement si dev-orchestrator figure/toujours si dev-orchestrator figure/' "$SKILL_MD" > "$ALT/a5.md"
sed 's/jamais en poste product/parfois en poste product/' "$SKILL_MD" > "$ALT/a6.md"
{ cat "$SKILL_MD"; printf '%s\n' 'Les entrées `role == mandatory` sont posées.'; } > "$ALT/a7.md"
badt=0
for n in 2 3 5 6 7; do
  if cmp -s "$ALT/a$n.md" "$SKILL_MD"; then ko "SKILL-TEMOIN-2 la copie altérée de SKILL-$n est identique à l'original"; badt=1; continue; fi
  if "skill_$n" "$ALT/a$n.md"; then ko "SKILL-TEMOIN-2 SKILL-$n reste vert sur sa copie altérée (incapable d'échouer)"; badt=1; fi
done
[ "$badt" -eq 0 ] && ok "SKILL-TEMOIN-2 chacune des assertions SKILL-2, 3, 5, 6, 7 rougit sur sa copie altérée"

echo "== Résultat : $pass OK, $fail KO, $skipped SKIP =="
[ "$fail" -eq 0 ]
