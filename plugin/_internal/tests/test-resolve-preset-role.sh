#!/usr/bin/env bash
# Test de resolve-preset.sh list sous un poste (Phase 58, RLPO-06, P58-D-21) — autonome.
# Cas PRE-TRACE-1..3 ; la sortie sans poste est comparée À L'OCTET (cmp -s) à celle de la copie
# gelée d'avant la phase (fixtures/resolve-preset-pre-58.sh = octets de a2ed5094), lancée depuis
# un miroir temporaire de _internal/ (elle résout ses voisins par son propre dossier).
# Aucune syntaxe propre à bash 4 : la suite tourne aussi sous /bin/bash 3.2.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$(cd "$HERE/.." && pwd)/resolve-preset.sh"
INTERNAL="$(cd "$HERE/.." && pwd)"
FROZEN="$HERE/fixtures/resolve-preset-pre-58.sh"
REPO_ROOT="$(cd "$HERE/../../.." && pwd)"
PLUGIN="$REPO_ROOT/plugin"
ROLES_SH="$INTERNAL/module-roles.sh"
TARGET="$SCRIPT"
MARK="zzSECRETzz"

pass=0; fail=0; skipped=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }
skip() { echo "  ⊘ SKIP $1"; skipped=$((skipped+1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
OUTS="$TMP/outs"; mkdir -p "$OUTS"; nout=0

echo "== test-resolve-preset-role =="

# run <racine modules> <fichier presets|-> <VAR=val|-> args... -> $RC, $TMP/o, $TMP/e (archive stdout pour PRE-COL4)
run() {
  local root="$1" pf="$2" ev="$3"; shift 3
  local e
  e=(env -u VF_ROLE "VF_MODULES_ROOT=$root")
  [ "$pf" = "-" ] || e+=("VF_PRESETS_FILE=$pf")
  [ "$ev" = "-" ] || e+=("$ev")
  "${e[@]}" bash "$TARGET" "$@" >"$TMP/o" 2>"$TMP/e"; RC=$?
  [ "${1-}" = "list" ] && { nout=$((nout+1)); cp "$TMP/o" "$OUTS/$nout"; }
  return 0
}
names() { cut -f1 "$1"; }

# ---------- Fixture : dépendance directe et TRANSITIVE vers un module de dev ------------------------
FIX="$TMP/fix"; mkdir -p "$FIX/mods/base" "$FIX/mods/devx" "$FIX/mods/mid"
echo '{"name":"base","requires":[]}' > "$FIX/mods/base/module.json"
echo '{"name":"devx","requires":[],"roles":["dev"]}' > "$FIX/mods/devx/module.json"
echo '{"name":"mid","requires":["devx"]}' > "$FIX/mods/mid/module.json"
cat > "$FIX/presets.json" <<'JSON'
{"presets":[
  {"name":"p-base","titre":"Base","description":"sans dev","modules":["base"]},
  {"name":"p-direct","titre":"Direct","description":"module de dev direct","modules":["devx"]},
  {"name":"p-transitif","titre":"Transitif","description":"requires vers un module de dev","modules":["mid"]},
  {"name":"p-mixte","titre":"Mixte","description":"base plus dev","modules":["base","devx"]}
]}
JSON
FX="$FIX/mods"; FP="$FIX/presets.json"
printf 'p-base\n' > "$TMP/exp-base"
printf 'p-base\np-direct\np-transitif\np-mixte\n' > "$TMP/exp-all"

# Miroir d'_internal/ pour la copie gelée (elle trouve resolve-deps.sh et presets.json par son dossier)
MIR="$TMP/mirror/_internal"; mkdir -p "$MIR"
cp "$FROZEN" "$MIR/resolve-preset.sh"; cp "$INTERNAL/resolve-deps.sh" "$INTERNAL/presets.json" "$MIR/"
frozen_run() { local t="$TARGET"; TARGET="$MIR/resolve-preset.sh"; run "$@"; TARGET="$t"; }

# ---------- PRE-TRACE-1 -----------------------------------------------------------------------------
probe_trace1() {
  run "$FX" "$FP" - list --role product; local rp="$RC"; names "$TMP/o" > "$TMP/n-prod"
  run "$FX" "$FP" - list --role dev;     local rd="$RC"; names "$TMP/o" > "$TMP/n-dev"
  run "$FX" "$FP" - list --role solo;    local rs="$RC"; names "$TMP/o" > "$TMP/n-solo"
  [ "$rp" -eq 0 ] && [ "$rd" -eq 0 ] && [ "$rs" -eq 0 ] \
    && cmp -s "$TMP/n-prod" "$TMP/exp-base" && cmp -s "$TMP/n-dev" "$TMP/exp-all" && cmp -s "$TMP/n-solo" "$TMP/exp-all"
}
probe_trace1 && ok "PRE-TRACE-1 fixture (dépendance directe, transitive, mixte) : product ne voit que p-base ; dev et solo voient les quatre" \
  || ko "PRE-TRACE-1 attendu product=[p-base] dev=solo=[4 presets], obtenu product=[$(tr '\n' ' ' < "$TMP/n-prod")] dev=[$(tr '\n' ' ' < "$TMP/n-dev")] solo=[$(tr '\n' ' ' < "$TMP/n-solo")]"

# ---------- PRE-TRACE-2 : sortie sans poste = octets d'avant la phase -------------------------------
run "$FX" "$FP" - list; cp "$TMP/o" "$TMP/new-fix"
frozen_run "$FX" "$FP" - list; cp "$TMP/o" "$TMP/old-fix"
run "$PLUGIN" - - list; cp "$TMP/o" "$TMP/new-real"
frozen_run "$PLUGIN" - - list; cp "$TMP/o" "$TMP/old-real"
{ cmp -s "$TMP/new-fix" "$TMP/old-fix" && [ -s "$TMP/new-fix" ] && cmp -s "$TMP/new-real" "$TMP/old-real" && [ -s "$TMP/new-real" ]; } \
  && ok "PRE-TRACE-2 list sans poste identique à l'octet (cmp -s) à la copie gelée, fixture et dépôt réel" \
  || ko "PRE-TRACE-2 attendu sortie identique à la copie gelée, obtenu un écart ou une sortie vide"

# ---------- PRE-TRACE-3 : dépôt réel, la liste est DÉRIVÉE de la fermeture --------------------------
run "$PLUGIN" - - list; names "$TMP/o" | LC_ALL=C sort > "$TMP/real-all"
run "$PLUGIN" - - list --role product; RCP="$RC"; names "$TMP/o" | LC_ALL=C sort > "$TMP/real-prod"
LC_ALL=C comm -23 "$TMP/real-all" "$TMP/real-prod" > "$TMP/real-removed"
LC_ALL=C comm -12 "$TMP/real-all" "$TMP/real-prod" > "$TMP/real-kept"
bad=0; detail=""
invisible_in_closure() { # <preset> -> 0 si la fermeture contient un module invisible au poste product
  local p="$1" m
  VF_MODULES_ROOT="$PLUGIN" bash "$SCRIPT" "$p" > "$TMP/clo" 2>/dev/null || { echo "fermeture de $p irrésoluble"; return 2; }
  while IFS= read -r m; do
    [ -n "$m" ] || continue
    [ "$(VF_MODULES_ROOT="$PLUGIN" bash "$ROLES_SH" visible "$m" product 2>/dev/null)" = "no" ] && return 0
  done < "$TMP/clo"
  return 1
}
while IFS= read -r p; do
  [ -n "$p" ] || continue
  invisible_in_closure "$p"; r=$?
  [ "$r" -eq 1 ] || { bad=$((bad+1)); detail="$detail kept:$p(rc$r)"; }
done < "$TMP/real-kept"
while IFS= read -r p; do
  [ -n "$p" ] || continue
  invisible_in_closure "$p"; r=$?
  [ "$r" -eq 0 ] || { bad=$((bad+1)); detail="$detail removed:$p(rc$r)"; }
done < "$TMP/real-removed"
{ [ "$RCP" -eq 0 ] && [ "$bad" -eq 0 ] && [ -s "$TMP/real-all" ]; } \
  && ok "PRE-TRACE-3 dépôt réel, product : $(wc -l < "$TMP/real-kept" | tr -d ' ') presets gardés (fermeture 100% visible), $(wc -l < "$TMP/real-removed" | tr -d ' ') retirés (fermeture avec un module invisible)" \
  || ko "PRE-TRACE-3 attendu rc 0 et filtre conforme à la fermeture, obtenu rc $RCP écarts:$detail"

# ---------- PRE-SOLO, PRE-DEV : même octets que sans poste ------------------------------------------
probe_solo() {
  run "$FX" "$FP" - list; cp "$TMP/o" "$TMP/s-ref"
  run "$FX" "$FP" - list --role solo; cmp -s "$TMP/o" "$TMP/s-ref" || return 1
  run "$FX" "$FP" VF_ROLE=solo list;  cmp -s "$TMP/o" "$TMP/s-ref" || return 1
  run "$PLUGIN" - - list; cp "$TMP/o" "$TMP/s-ref2"
  run "$PLUGIN" - - list --role solo; cmp -s "$TMP/o" "$TMP/s-ref2" || return 1
  run "$PLUGIN" - VF_ROLE=solo list;  cmp -s "$TMP/o" "$TMP/s-ref2"
}
probe_solo && ok "PRE-SOLO --role solo et VF_ROLE=solo = sortie sans poste (cmp -s), fixture et dépôt réel" \
  || ko "PRE-SOLO attendu sortie identique à celle sans poste, obtenu un écart ($(wc -c < "$TMP/o" | tr -d ' ') octets)"
probe_dev() {
  run "$FX" "$FP" - list; cp "$TMP/o" "$TMP/d-ref"
  run "$FX" "$FP" - list --role dev; cmp -s "$TMP/o" "$TMP/d-ref" || return 1
  run "$PLUGIN" - - list; cp "$TMP/o" "$TMP/d-ref2"
  run "$PLUGIN" - - list --role dev; cmp -s "$TMP/o" "$TMP/d-ref2"
}
probe_dev && ok "PRE-DEV --role dev = sortie sans poste (cmp -s), fixture et dépôt réel" \
  || ko "PRE-DEV attendu sortie identique à celle sans poste, obtenu un écart"

# ---------- PRE-ENV, PRE-PRIO -----------------------------------------------------------------------
run "$FX" "$FP" - list --role product; cp "$TMP/o" "$TMP/prod-flag"
run "$FX" "$FP" VF_ROLE=product list; cp "$TMP/o" "$TMP/prod-env"
cmp -s "$TMP/prod-flag" "$TMP/prod-env" && [ -s "$TMP/prod-flag" ] && ok "PRE-ENV VF_ROLE=product sans drapeau = --role product" \
  || ko "PRE-ENV attendu même sortie que --role product, obtenu un écart"
probe_prio() { run "$FX" "$FP" VF_ROLE=dev list --role product; cmp -s "$TMP/o" "$TMP/prod-flag"; }
probe_prio && ok "PRE-PRIO VF_ROLE=dev --role product : le drapeau l'emporte" \
  || ko "PRE-PRIO attendu la sortie de --role product, obtenu $(names "$TMP/o" | tr '\n' ' ')"

# ---------- PRE-NOM : la résolution nommée ne lit jamais le poste ------------------------------------
run "$FX" "$FP" - p-direct; A="$RC"; cp "$TMP/o" "$TMP/nom-ref"
run "$FX" "$FP" VF_ROLE=product p-direct; B="$RC"; cp "$TMP/o" "$TMP/nom-prod"
run "$FX" "$FP" "VF_ROLE=$MARK" p-direct; C="$RC"; cp "$TMP/o" "$TMP/nom-mark"
run "$PLUGIN" - - dev; D="$RC"; cp "$TMP/o" "$TMP/nom-real"
run "$PLUGIN" - VF_ROLE=product dev; E="$RC"
{ [ "$A$B$C$D$E" = "00000" ] && cmp -s "$TMP/nom-ref" "$TMP/nom-prod" && cmp -s "$TMP/nom-ref" "$TMP/nom-mark" && [ -s "$TMP/nom-ref" ] && cmp -s "$TMP/nom-real" "$TMP/o"; } \
  && ok "PRE-NOM résolution nommée inchangée sous VF_ROLE=product ou hostile (fixture et dépôt réel)" \
  || ko "PRE-NOM attendu rc 0 et fermetures identiques, obtenu rc $A/$B/$C/$D/$E"

# ---------- PRE-INV : erreurs bruyantes ------------------------------------------------------------
run "$FX" "$FP" - list --role "$MARK"; A="$RC"; AALL="$(cat "$TMP/o" "$TMP/e")"; AERR="$(cat "$TMP/e")"
run "$FX" "$FP" - list --role; B="$RC"
run "$FX" "$FP" - list --role=; C="$RC"
run "$FX" "$FP" - list --zz; D="$RC"
run "$FX" "$FP" "VF_ROLE=$MARK" list; E="$RC"; EALL="$(cat "$TMP/o" "$TMP/e")"
run "$FX" "$FP" - list extra; F="$RC"
leak=0; printf '%s%s' "$AALL" "$EALL" | command grep -q "$MARK" && leak=1
{ [ "$A" -eq 1 ] && printf '%s' "$AERR" | command grep -q 'poste invalide' && [ "$leak" -eq 0 ] \
  && [ "$B" -eq 1 ] && [ "$C" -eq 1 ] && [ "$D" -eq 1 ] && [ "$E" -eq 1 ] && [ "$F" -eq 1 ]; } \
  && ok "PRE-INV poste hors ensemble, --role sans valeur, --role= vide, argument inconnu, VF_ROLE hostile : rc 1, valeur jamais réimprimée" \
  || ko "PRE-INV attendu rc 1 partout sans fuite, obtenu $A/$B/$C/$D/$E/$F fuite=$leak err[$AERR]"

BAD="$TMP/bad"; mkdir -p "$BAD/okmod" "$BAD/badmod"
echo '{"name":"okmod","requires":[]}' > "$BAD/okmod/module.json"
echo '{"name":"badmod","requires":[],"roles":[]}' > "$BAD/badmod/module.json"
echo '{"presets":[{"name":"p-ok","titre":"t","description":"d","modules":["okmod"]},{"name":"p-bad","titre":"t","description":"d","modules":["badmod"]}]}' > "$BAD/presets.json"
run "$BAD/." "$BAD/presets.json" - list --role product; A="$RC"; AERR="$(cat "$TMP/e")"
run "$BAD/." "$BAD/presets.json" - list; B="$RC"; BHAS="$(names "$TMP/o" | command grep -cx p-bad)"
{ [ "$A" -eq 1 ] && printf '%s' "$AERR" | command grep -q 'badmod' && [ "$B" -eq 0 ] && [ "$BHAS" = "1" ]; } \
  && ok "PRE-ROLES-INV roles [] : --role product rc 1 nommant badmod ; sans poste rc 0 et preset listé" \
  || ko "PRE-ROLES-INV attendu rc 1 + nom du module puis rc 0 + preset listé, obtenu rc $A [$AERR] puis rc $B (listé: $BHAS)"

echo '{"presets":[{"name":"p-ok","titre":"t","description":"d","modules":["okmod"]},{"name":"p-ghost","titre":"t","description":"d","modules":["okmod","fantome"]}]}' > "$BAD/ghost.json"
mkdir -p "$BAD/clean/okmod"; cp "$BAD/okmod/module.json" "$BAD/clean/okmod/module.json"
run "$BAD/clean" "$BAD/ghost.json" - list --role product; A="$RC"; AERR="$(cat "$TMP/e")"; AOUT="$(cat "$TMP/o")"
run "$BAD/clean" "$BAD/ghost.json" - list; B="$RC"
{ [ "$A" -eq 1 ] && printf '%s' "$AERR" | command grep -q 'p-ghost' && [ -z "$AOUT" ] && [ "$B" -eq 0 ]; } \
  && ok "PRE-FERMETURE fermeture irrésoluble : --role product rc 1 nommant p-ghost, aucun preset sauté ; sans poste rc 0" \
  || ko "PRE-FERMETURE attendu rc 1 + nom du preset + stdout vide puis rc 0, obtenu rc $A [$AERR] puis rc $B"

# ---------- PRE-COL4 --------------------------------------------------------------------------------
badcol=0; nfiles=0
for f in "$OUTS"/*; do
  [ -s "$f" ] || continue
  nfiles=$((nfiles+1))
  n="$(awk -F'\t' 'NF != 4 { n++ } END { print n+0 }' "$f")"
  [ "$n" = "0" ] || badcol=$((badcol+n))
done
{ [ "$badcol" -eq 0 ] && [ "$nfiles" -gt 5 ]; } && ok "PRE-COL4 $nfiles sorties : chaque ligne a 4 champs séparés par tabulation" \
  || ko "PRE-COL4 attendu 0 ligne fautive sur plus de 5 sorties, obtenu $badcol sur $nfiles"

# ---------- PRE-INTEGRITE : empreinte ÉPINGLÉE (la CI ne clone pas l'historique, P58-PL-03) ---------
FROZEN_CKSUM="1806114509 4156"
FROZEN_SHA256="b0a44150e77ffa9cc7f7ab7a4950b531cb38b395550fd3fafdcf969e9311f58d"
frozen_matches() { # <fichier> : empreinte conforme à l'épingle
  local f="$1" ck sh=""
  ck="$(cksum < "$f" | awk '{print $1" "$2}')"
  [ "$ck" = "$FROZEN_CKSUM" ] || return 1
  if command -v sha256sum >/dev/null 2>&1; then sh="$(sha256sum < "$f" | awk '{print $1}')"
  elif command -v shasum >/dev/null 2>&1; then sh="$(shasum -a 256 < "$f" | awk '{print $1}')"; fi
  [ -z "$sh" ] || [ "$sh" = "$FROZEN_SHA256" ]
}
frozen_matches "$FROZEN" && ok "PRE-INTEGRITE la copie gelée porte l'empreinte épinglée (cksum $FROZEN_CKSUM), sans dépendre de .git" \
  || ko "PRE-INTEGRITE la copie gelée ne porte pas l'empreinte épinglée"
ALTF="$TMP/frozen-alt.sh"; { head -c 100 "$FROZEN"; printf 'X'; tail -c +102 "$FROZEN"; } > "$ALTF"
if cmp -s "$ALTF" "$FROZEN"; then ko "PRE-INTEGRITE-TEMOIN la copie altérée est identique à l'originale (octet 101 déjà X)"
elif ! frozen_matches "$ALTF" && frozen_matches "$FROZEN"; then
  ok "PRE-INTEGRITE-TEMOIN un octet altéré (même taille) rougit la vérification d'empreinte, l'original reste vert"
else ko "PRE-INTEGRITE-TEMOIN la copie altérée d'un octet reste verte (empreinte incapable d'échouer)"; fi
if git -C "$REPO_ROOT" cat-file -e a2ed5094:plugin/_internal/resolve-preset.sh 2>/dev/null; then
  git -C "$REPO_ROOT" show a2ed5094:plugin/_internal/resolve-preset.sh > "$TMP/a2ed5094.sh" 2>/dev/null
  cmp -s "$TMP/a2ed5094.sh" "$FROZEN" && ok "PRE-INTEGRITE-GIT la copie gelée est identique à l'objet a2ed5094" \
    || ko "PRE-INTEGRITE-GIT la copie gelée diffère de a2ed5094"
else
  skip "PRE-INTEGRITE-GIT (clone superficiel : a2ed5094 illisible ; l'empreinte épinglée a déjà jugé)"
fi

# ---------- PRE-SKILL : la ligne « Presets » du skill demande la liste du poste ----------------------
SKILL_MD="$PLUGIN/installer/SKILL.md"
skill_row() { command grep -F '| Presets (étape 4) |' "$1" | command grep -qF 'resolve-preset.sh" list --role <poste>'; }
skill_row "$SKILL_MD" && ok "PRE-SKILL la ligne « Presets (étape 4) » passe --role <poste> à list" \
  || ko "PRE-SKILL attendu 'resolve-preset.sh\" list --role <poste>' dans la ligne Presets du skill"
ALTS="$TMP/skill-alt.md"; sed 's/list --role <poste>/list/' "$SKILL_MD" > "$ALTS"
skill_row "$ALTS" && ko "PRE-SKILL-TEMOIN la copie sans --role reste verte (assertion incapable d'échouer)" \
  || ok "PRE-SKILL-TEMOIN la même assertion rougit sur une copie sans --role"

# ---------- Mutants ---------------------------------------------------------------------------------
MT="$TMP/mut/_internal"; mkdir -p "$MT"
cp "$ROLES_SH" "$INTERNAL/resolve-deps.sh" "$INTERNAL/presets.json" "$MT/"
MUTBIN="$MT/resolve-preset.sh"

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

mutant PRE-MUT-1 '{ if (index($0, "grep -qxF -- \"$mod\" || { keep=0; break; }")) print "      :"; else print }' \
  probe_trace1 "filtre neutralisé (tout preset gardé)"
mutant PRE-MUT-2 '{ if (index($0, "if [ \"$keep\" -eq 1 ]; then")) print "    if [ \"$keep\" -eq 0 ]; then"; else print }' \
  probe_trace1 "filtre inversé (garde les presets invisibles)"
mutant PRE-MUT-3 '{ if ($0 == "    product|dev) ;;") print "    solo|product|dev) ;;"; else if (index($0, "bash \"$ROLES_SH\" list \"$POSTE\"")) { sub(/list "\$POSTE"/, "list product"); print } else print }' \
  probe_solo "solo filtré comme product"
mutant PRE-MUT-4 '{ print; if ($0 == "  set -- list") print "  POSTE=\"${VF_ROLE:-$POSTE}\"" }' \
  probe_prio "priorité inversée (VF_ROLE l emporte sur --role)"

echo "== Résultat : $pass OK, $fail KO =="
[ "$skipped" -eq 0 ] || echo "   ($skipped SKIP)"
[ "$fail" -eq 0 ]
