#!/usr/bin/env bash
# test-check-phase-invariants.sh — fixtures jetables pour check-phase-invariants.sh.
# Cas V1-V13 (voir 40.1-02-PLAN.md, Task 2), plus V14-V17 (correction ciblee du 2026-09-17,
# constats revue et audit de la mission d'execution 40.1 : swap() restreint a l'ancien plafond,
# LC_ALL=C, rc de git rev-list). Sortie: "== resultat : N ok, M ko ==".
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CPI="$SCRIPT_DIR/check-phase-invariants.sh"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
REAL_GATE="$REPO_ROOT/plugin/conductor/scripts/check-instruction-budget.sh"

OK=0
KO=0

report() { # <label> <verdict: ok|ko> <detail>
  if [ "$2" = ok ]; then
    echo "✓ $1 — $3"
    OK=$((OK + 1))
  else
    echo "✗ $1 — $3"
    KO=$((KO + 1))
  fi
}

agent_content() { # <marker-line-fragment-after-"agents <= "> -> contenu sur stdout
  printf '# Agent Test\n\n## Regles\n\n- agents <= %s\n- ligne neutre de contenu\n' "$1"
}

# new_agent_repo [<adjust-file> <delta>] -> imprime le chemin du depot sur stdout.
# Cree main avec 3 agents (a, b, c/agents/x.md), le gate reel, la sentinelle, et une baseline
# EXACTE mesuree par le gate lui-meme (deviee de <delta> lignes sur <adjust-file> si fournis).
new_agent_repo() {
  local adjust_file="${1:-}" delta="${2:-0}"
  local r
  r="$(mktemp -d)"
  git -C "$r" -c user.name=t -c user.email=t@t.co init -q -b main
  printf 'v0.0.1\n' > "$r/VERSION"
  mkdir -p "$r/plugin/a" "$r/plugin/b" "$r/plugin/c/agents" "$r/plugin/conductor/scripts" "$r/.planning"
  agent_content "250 lignes${A_SUFFIX:-}" > "$r/plugin/a/AGENT.md"
  agent_content "250 lignes" > "$r/plugin/b/AGENT.md"
  agent_content "250 lignes" > "$r/plugin/c/agents/x.md"
  cp "$REAL_GATE" "$r/plugin/conductor/scripts/check-instruction-budget.sh"
  chmod +x "$r/plugin/conductor/scripts/check-instruction-budget.sh"
  git -C "$r" add -A
  git -C "$r" -c user.name=t -c user.email=t@t.co commit -q -m "base agents"

  # Mesure reelle (gate sans baseline) pour ecrire une baseline exacte.
  local mout
  mout="$(bash "$r/plugin/conductor/scripts/check-instruction-budget.sh" --path "$r" 2>/dev/null)"
  local bl="$r/.planning/instruction-budget-baselines.tsv"
  : > "$bl"
  local rel lines instr
  for rel in plugin/a/AGENT.md plugin/b/AGENT.md plugin/c/agents/x.md; do
    lines="$(printf '%s\n' "$mout" | awk -F' \\| ' -v f="$rel" '$1==f{print $2; exit}')"
    instr="$(printf '%s\n' "$mout" | awk -F' \\| ' -v f="$rel" '$1==f{print $4; exit}')"
    if [ "$rel" = "$adjust_file" ]; then
      lines=$((lines + delta))
    fi
    printf '%s\t%s\t%s\n' "$rel" "$lines" "$instr" >> "$bl"
  done
  mkdir -p "$r/.planning"
  : > "$r/.planning/.instruction-budget-armed"
  git -C "$r" add -A
  git -C "$r" -c user.name=t -c user.email=t@t.co commit -q -m "baseline + sentinelle"

  git -C "$r" checkout -q -b w
  printf '%s\n' "$r"
}

touch_baseline_comment() { # <repo>
  printf '# note %s\n' "$RANDOM" >> "$1/.planning/instruction-budget-baselines.tsv"
  git -C "$1" add -A
  git -C "$1" -c user.name=t -c user.email=t@t.co commit -q -m "chore: commentaire baseline"
}

bump_three_agents() { # <repo>
  sed -i.bak 's/<= 250 lignes/<= 300 lignes/' "$1/plugin/a/AGENT.md" && rm -f "$1/plugin/a/AGENT.md.bak"
  sed -i.bak 's/<= 250 lignes/<= 300 lignes/' "$1/plugin/b/AGENT.md" && rm -f "$1/plugin/b/AGENT.md.bak"
  sed -i.bak 's/<= 250 lignes/<= 300 lignes/' "$1/plugin/c/agents/x.md" && rm -f "$1/plugin/c/agents/x.md.bak"
  git -C "$1" add -A
  git -C "$1" -c user.name=t -c user.email=t@t.co commit -q -m "feat: adr-029 plafond 300"
}

run_cpi() { # <repo> [extra args...] -> stdout+stderr dans $LAST_OUT, rc dans $?
  local r="$1" _rc=0
  shift
  LAST_OUT="$(bash "$CPI" --root "$r" --main-ref main "$@" 2>&1)" && _rc=0 || _rc=$?
  return "$_rc"
}

# --- V1 ------------------------------------------------------------------------------------------
R1="$(new_agent_repo)"
touch_baseline_comment "$R1"
bump_three_agents "$R1"
rc=0; run_cpi "$R1" || rc=$?
case "$LAST_OUT" in *"fichiers=3"*) fn_ok=1 ;; *) fn_ok=0 ;; esac
[ "$rc" -eq 0 ] && [ "$fn_ok" -eq 1 ] && v=ok || v=ko
report V1 "$v" "attendu rc=0 fichiers=3, obtenu rc=$rc : $(printf '%s' "$LAST_OUT" | awk '/^INVARIANTS/')"

# --- V2 ------------------------------------------------------------------------------------------
R2="$(new_agent_repo)"
touch_baseline_comment "$R2"
sed -i.bak 's/<= 250 lignes/<= 300 lignes obligatoire/' "$R2/plugin/a/AGENT.md" && rm -f "$R2/plugin/a/AGENT.md.bak"
git -C "$R2" add -A
git -C "$R2" -c user.name=t -c user.email=t@t.co commit -q -m "feat: reecriture partielle"
rc=0; run_cpi "$R2" || rc=$?
case "$LAST_OUT" in *"I2=ko"*) i2_ko=1 ;; *) i2_ko=0 ;; esac
[ "$rc" -eq 1 ] && [ "$i2_ko" -eq 1 ] && v=ok || v=ko
report V2 "$v" "ligne reecrite (mot ajoute), attendu rc=1 I2=ko, obtenu rc=$rc"

# --- V3 ------------------------------------------------------------------------------------------
R3="$(new_agent_repo)"
touch_baseline_comment "$R3"
printf -- '- nouvelle regle ajoutee\n' >> "$R3/plugin/a/AGENT.md"
git -C "$R3" add -A
git -C "$R3" -c user.name=t -c user.email=t@t.co commit -q -m "feat: ajout de regle"
rc=0; run_cpi "$R3" || rc=$?
[ "$rc" -eq 1 ] && v=ok || v=ko
report V3 "$v" "ligne ajoutee sans retrait, attendu rc=1, obtenu rc=$rc"

# --- V4 ------------------------------------------------------------------------------------------
R4="$(new_agent_repo)"
sed -i.bak '1s/[0-9][0-9]*/999/' "$R4/.planning/instruction-budget-baselines.tsv" && rm -f "$R4/.planning/instruction-budget-baselines.tsv.bak"
git -C "$R4" add -A
git -C "$R4" -c user.name=t -c user.email=t@t.co commit -q -m "chore: modifie une ligne de donnees de la baseline"
rc=0; run_cpi "$R4" || rc=$?
case "$LAST_OUT" in *"I1=ko"*) i1_ko=1 ;; *) i1_ko=0 ;; esac
[ "$rc" -eq 1 ] && [ "$i1_ko" -eq 1 ] && v=ok || v=ko
report V4 "$v" "ligne de donnees de la baseline modifiee, attendu rc=1 I1=ko, obtenu rc=$rc"

# --- V5 ------------------------------------------------------------------------------------------
R5="$(new_agent_repo)"
rc=0; run_cpi "$R5" || rc=$?
[ "$rc" -eq 1 ] && v=ok || v=ko
report V5 "$v" "diff vide (aucun commit de branche), attendu rc=1, obtenu rc=$rc"

# --- V6 : hotfix sur main raccourcit un agent non touche, branche rebasee puis V1 -----------------
R6="$(new_agent_repo)"
git -C "$R6" checkout -q main
# raccourcit 'b' (retire la ligne neutre, qui est aussi une puce comptee) et abaisse SES DEUX
# colonnes de baseline (lignes et instructions) en consequence, meme commit.
sed -i.bak '/ligne neutre de contenu/d' "$R6/plugin/b/AGENT.md" && rm -f "$R6/plugin/b/AGENT.md.bak"
awk -F'\t' 'BEGIN{OFS="\t"} $1=="plugin/b/AGENT.md"{$2=$2-1; $3=$3-1} {print}' \
  "$R6/.planning/instruction-budget-baselines.tsv" > "$R6/.planning/instruction-budget-baselines.tsv.new"
mv "$R6/.planning/instruction-budget-baselines.tsv.new" "$R6/.planning/instruction-budget-baselines.tsv"
git -C "$R6" add -A
git -C "$R6" -c user.name=t -c user.email=t@t.co commit -q -m "hotfix: raccourcit b et sa baseline"
git -C "$R6" checkout -q w
git -C "$R6" -c user.name=t -c user.email=t@t.co rebase -q main >/dev/null 2>&1
touch_baseline_comment "$R6"
bump_three_agents "$R6"
rc=0; run_cpi "$R6" || rc=$?
[ "$rc" -eq 0 ] && v=ok || v=ko
report V6 "$v" "hotfix non impute (agent raccourci + baseline abaissee sur main), attendu rc=0, obtenu rc=$rc : $(printf '%s' "$LAST_OUT" | awk '/^INVARIANTS/')"

# --- V7 ------------------------------------------------------------------------------------------
R7="$(new_agent_repo)"
touch_baseline_comment "$R7"
printf 'v0.0.2\n' > "$R7/VERSION"
git -C "$R7" add -A
git -C "$R7" -c user.name=t -c user.email=t@t.co commit -q -m "chore: touche VERSION"
rc=0; run_cpi "$R7" || rc=$?
case "$LAST_OUT" in *"I4=ko"*) i4_ko=1 ;; *) i4_ko=0 ;; esac
[ "$rc" -eq 1 ] && [ "$i4_ko" -eq 1 ] && v=ok || v=ko
report V7 "$v" "commit touchant VERSION, attendu rc=1 I4=ko, obtenu rc=$rc"

# --- V8 : nombre voisin (2500, precede d'un point, DEJA present avant la branche) laisse intact ---
A_SUFFIX=" (voir aussi .2500)"
R8="$(new_agent_repo)"
unset A_SUFFIX
touch_baseline_comment "$R8"
bump_three_agents "$R8"
rc=0; run_cpi "$R8" || rc=$?
after="$(awk 'NR==5' "$R8/plugin/a/AGENT.md")"
case "$after" in *"300 lignes (voir aussi .2500)"*) content_ok=1 ;; *) content_ok=0 ;; esac
[ "$rc" -eq 0 ] && [ "$content_ok" -eq 1 ] && v=ok || v=ko
report V8 "$v" "2500 precede d'un point non swappe, attendu rc=0, obtenu rc=$rc, ligne=$after"

# --- V9 : --min-agents 4 sur V1 --------------------------------------------------------------------
rc=0; run_cpi "$R1" --min-agents 4 || rc=$?
[ "$rc" -eq 1 ] && v=ok || v=ko
report V9 "$v" "min-agents 4 sur un depot a 3 fichiers verifies, attendu rc=1, obtenu rc=$rc"

# --- V10 : V1 + commit non prefixe qui reecrit une ligne d'agent -----------------------------------
sed -i.bak 's/<= 300 lignes/<= 300 lignes revu/' "$R1/plugin/b/AGENT.md" && rm -f "$R1/plugin/b/AGENT.md.bak"
git -C "$R1" add -A
git -C "$R1" -c user.name=t -c user.email=t@t.co commit -q -m "wip"
rc=0; run_cpi "$R1" || rc=$?
[ "$rc" -eq 1 ] && v=ok || v=ko
report V10 "$v" "sujet non prefixe (wip) impute quand meme, attendu rc=1, obtenu rc=$rc"

# --- V11 : V1 (avant V10) + merge de main sans resolution manuelle ---------------------------------
R11="$(new_agent_repo)"
touch_baseline_comment "$R11"
bump_three_agents "$R11"
git -C "$R11" checkout -q main
printf 'note\n' > "$R11/plugin/conductor/NOTE.md"
git -C "$R11" add -A
git -C "$R11" -c user.name=t -c user.email=t@t.co commit -q -m "chore: note sans rapport"
git -C "$R11" checkout -q w
git -C "$R11" -c user.name=t -c user.email=t@t.co merge -q --no-edit main >/dev/null 2>&1
rc=0; run_cpi "$R11" || rc=$?
[ "$rc" -eq 0 ] && v=ok || v=ko
report V11 "$v" "merge de main sans resolution sur chemin garde, attendu rc=0, obtenu rc=$rc : $(printf '%s' "$LAST_OUT" | awk '/^INVARIANTS/')"

# --- V12 : agent non touche par la branche, baseline SOUS-estimee (hausse) -------------------------
R12="$(new_agent_repo plugin/b/AGENT.md -1)"
touch_baseline_comment "$R12"
bump_three_agents "$R12"
rc=0; run_cpi "$R12" || rc=$?
case "$LAST_OUT" in *"I3=ko"*) i3_ko=1 ;; *) i3_ko=0 ;; esac
[ "$rc" -eq 1 ] && [ "$i3_ko" -eq 1 ] && v=ok || v=ko
report V12 "$v" "baseline sous-estimee (hausse), attendu rc=1 I3=ko, obtenu rc=$rc"

# new_agent_repo_unicode -> comme new_agent_repo, mais l'agent 'a' porte une ligne accentuee avec un
# "≤" multi-octets et un identifiant "ADR-029" (constat 2 : awk plante sous macOS hors LC_ALL=C sur
# ce type de contenu ; constat 1 : sans restriction a l'ancienne valeur du plafond, le "029" de
# "ADR-029" serait lui aussi swappe en 300, provoquant un LINE_MISMATCH sur une ligne pourtant
# inchangee).
new_agent_repo_unicode() {
  local r
  r="$(mktemp -d)"
  git -C "$r" -c user.name=t -c user.email=t@t.co init -q -b main
  printf 'v0.0.1\n' > "$r/VERSION"
  mkdir -p "$r/plugin/a" "$r/plugin/b" "$r/plugin/c/agents" "$r/plugin/conductor/scripts" "$r/.planning"
  {
    printf '# Agent Test\n\n## Regles\n\n'
    printf -- '- agents \xe2\x89\xa4 250 lignes (ADR-029)\n'
    printf -- '- ligne neutre de contenu\n'
  } > "$r/plugin/a/AGENT.md"
  agent_content "250 lignes" > "$r/plugin/b/AGENT.md"
  agent_content "250 lignes" > "$r/plugin/c/agents/x.md"
  cp "$REAL_GATE" "$r/plugin/conductor/scripts/check-instruction-budget.sh"
  chmod +x "$r/plugin/conductor/scripts/check-instruction-budget.sh"
  git -C "$r" add -A
  git -C "$r" -c user.name=t -c user.email=t@t.co commit -q -m "base agents unicode"

  local mout
  mout="$(bash "$r/plugin/conductor/scripts/check-instruction-budget.sh" --path "$r" 2>/dev/null)"
  local bl="$r/.planning/instruction-budget-baselines.tsv"
  : > "$bl"
  local rel lines instr
  for rel in plugin/a/AGENT.md plugin/b/AGENT.md plugin/c/agents/x.md; do
    lines="$(printf '%s\n' "$mout" | awk -F' \\| ' -v f="$rel" '$1==f{print $2; exit}')"
    instr="$(printf '%s\n' "$mout" | awk -F' \\| ' -v f="$rel" '$1==f{print $4; exit}')"
    printf '%s\t%s\t%s\n' "$rel" "$lines" "$instr" >> "$bl"
  done
  : > "$r/.planning/.instruction-budget-armed"
  git -C "$r" add -A
  git -C "$r" -c user.name=t -c user.email=t@t.co commit -q -m "baseline + sentinelle"
  git -C "$r" checkout -q -b w
  printf '%s\n' "$r"
}

# new_agent_repo_approvals -> comme new_agent_repo, mais l'agent 'a' porte en plus une ligne
# "au moins 2 approbations requises" : un nombre isole SANS RAPPORT avec le plafond ADR-029, utilise
# pour prouver que swap() ne remplace plus N'IMPORTE QUEL nombre par 300 (constat 1).
new_agent_repo_approvals() {
  local r
  r="$(mktemp -d)"
  git -C "$r" -c user.name=t -c user.email=t@t.co init -q -b main
  printf 'v0.0.1\n' > "$r/VERSION"
  mkdir -p "$r/plugin/a" "$r/plugin/b" "$r/plugin/c/agents" "$r/plugin/conductor/scripts" "$r/.planning"
  printf '# Agent Test\n\n## Regles\n\n- agents <= 250 lignes\n- au moins 2 approbations requises\n' > "$r/plugin/a/AGENT.md"
  agent_content "250 lignes" > "$r/plugin/b/AGENT.md"
  agent_content "250 lignes" > "$r/plugin/c/agents/x.md"
  cp "$REAL_GATE" "$r/plugin/conductor/scripts/check-instruction-budget.sh"
  chmod +x "$r/plugin/conductor/scripts/check-instruction-budget.sh"
  git -C "$r" add -A
  git -C "$r" -c user.name=t -c user.email=t@t.co commit -q -m "base agents approvals"

  local mout
  mout="$(bash "$r/plugin/conductor/scripts/check-instruction-budget.sh" --path "$r" 2>/dev/null)"
  local bl="$r/.planning/instruction-budget-baselines.tsv"
  : > "$bl"
  local rel lines instr
  for rel in plugin/a/AGENT.md plugin/b/AGENT.md plugin/c/agents/x.md; do
    lines="$(printf '%s\n' "$mout" | awk -F' \\| ' -v f="$rel" '$1==f{print $2; exit}')"
    instr="$(printf '%s\n' "$mout" | awk -F' \\| ' -v f="$rel" '$1==f{print $4; exit}')"
    printf '%s\t%s\t%s\n' "$rel" "$lines" "$instr" >> "$bl"
  done
  : > "$r/.planning/.instruction-budget-armed"
  git -C "$r" add -A
  git -C "$r" -c user.name=t -c user.email=t@t.co commit -q -m "baseline + sentinelle"
  git -C "$r" checkout -q -b w
  printf '%s\n' "$r"
}

# --- V14 : ligne accentuee (≤) avec identifiant "ADR-029" + remplacement legitime, attendu PASS -----
R14="$(new_agent_repo_unicode)"
touch_baseline_comment "$R14"
sed -i.bak 's/250 lignes/300 lignes/' "$R14/plugin/a/AGENT.md" && rm -f "$R14/plugin/a/AGENT.md.bak"
sed -i.bak 's/<= 250 lignes/<= 300 lignes/' "$R14/plugin/b/AGENT.md" && rm -f "$R14/plugin/b/AGENT.md.bak"
sed -i.bak 's/<= 250 lignes/<= 300 lignes/' "$R14/plugin/c/agents/x.md" && rm -f "$R14/plugin/c/agents/x.md.bak"
git -C "$R14" add -A
git -C "$R14" -c user.name=t -c user.email=t@t.co commit -q -m "feat: adr-029 plafond 300 (unicode)"
rc=0; run_cpi "$R14" || rc=$?
case "$LAST_OUT" in *"fichiers=3"*) fn_ok=1 ;; *) fn_ok=0 ;; esac
[ "$rc" -eq 0 ] && [ "$fn_ok" -eq 1 ] && v=ok || v=ko
report V14 "$v" "ligne accentuee (≤) + ADR-029 non swappe + remplacement legitime, attendu rc=0 fichiers=3, obtenu rc=$rc : $(printf '%s' "$LAST_OUT" | awk '/^INVARIANTS/')"

# --- V15 : un AUTRE nombre devient 300 (2 approbations -> 300), a cote d'un remplacement legitime ---
R15="$(new_agent_repo_approvals)"
touch_baseline_comment "$R15"
sed -i.bak 's/<= 250 lignes/<= 300 lignes/; s/au moins 2 approbations requises/au moins 300 approbations requises/' "$R15/plugin/a/AGENT.md" && rm -f "$R15/plugin/a/AGENT.md.bak"
sed -i.bak 's/<= 250 lignes/<= 300 lignes/' "$R15/plugin/b/AGENT.md" && rm -f "$R15/plugin/b/AGENT.md.bak"
sed -i.bak 's/<= 250 lignes/<= 300 lignes/' "$R15/plugin/c/agents/x.md" && rm -f "$R15/plugin/c/agents/x.md.bak"
git -C "$R15" add -A
git -C "$R15" -c user.name=t -c user.email=t@t.co commit -q -m "feat: adr-029 plafond 300 + approbations falsifiees"
rc=0; run_cpi "$R15" || rc=$?
case "$LAST_OUT" in *"I2=ko"*) i2_ko=1 ;; *) i2_ko=0 ;; esac
[ "$rc" -eq 1 ] && [ "$i2_ko" -eq 1 ] && v=ok || v=ko
report V15 "$v" "nombre sans rapport (2 approbations) devient 300 malgre un remplacement legitime a cote, attendu rc=1 I2=ko, obtenu rc=$rc"

# --- V16 : l'ancien plafond devient autre chose que 300 (301) -------------------------------------
R16="$(new_agent_repo)"
touch_baseline_comment "$R16"
sed -i.bak 's/<= 250 lignes/<= 301 lignes/' "$R16/plugin/a/AGENT.md" && rm -f "$R16/plugin/a/AGENT.md.bak"
sed -i.bak 's/<= 250 lignes/<= 300 lignes/' "$R16/plugin/b/AGENT.md" && rm -f "$R16/plugin/b/AGENT.md.bak"
sed -i.bak 's/<= 250 lignes/<= 300 lignes/' "$R16/plugin/c/agents/x.md" && rm -f "$R16/plugin/c/agents/x.md.bak"
git -C "$R16" add -A
git -C "$R16" -c user.name=t -c user.email=t@t.co commit -q -m "feat: plafond errone a 301"
rc=0; run_cpi "$R16" || rc=$?
case "$LAST_OUT" in *"I2=ko"*) i2_ko=1 ;; *) i2_ko=0 ;; esac
[ "$rc" -eq 1 ] && [ "$i2_ko" -eq 1 ] && v=ok || v=ko
report V16 "$v" "ancien plafond remplace par 301 (pas 300), attendu rc=1 I2=ko, obtenu rc=$rc"

# --- V17 : ref cassee (stub phase-base.sh renvoie une base inexistante), attendu rc=2 ----------------
R17="$(new_agent_repo)"
touch_baseline_comment "$R17"
bump_three_agents "$R17"
SCRATCH17="$(mktemp -d)"
cp "$CPI" "$SCRATCH17/check-phase-invariants.sh"
cat > "$SCRATCH17/phase-base.sh" <<'EOF'
#!/usr/bin/env bash
echo "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
exit 0
EOF
chmod +x "$SCRATCH17/phase-base.sh" "$SCRATCH17/check-phase-invariants.sh"
rc=0; LAST_OUT="$(bash "$SCRATCH17/check-phase-invariants.sh" --root "$R17" 2>&1)" && rc=0 || rc=$?
[ "$rc" -eq 2 ] && v=ok || v=ko
report V17 "$v" "ref cassee (stub phase-base.sh renvoie une base inexistante), attendu rc=2, obtenu rc=$rc : $LAST_OUT"

# --- V13 : agent non touche par la branche, baseline SUR-estimee (marge) ---------------------------
R13="$(new_agent_repo plugin/c/agents/x.md 1)"
touch_baseline_comment "$R13"
sed -i.bak 's/<= 250 lignes/<= 300 lignes/' "$R13/plugin/a/AGENT.md" && rm -f "$R13/plugin/a/AGENT.md.bak"
sed -i.bak 's/<= 250 lignes/<= 300 lignes/' "$R13/plugin/b/AGENT.md" && rm -f "$R13/plugin/b/AGENT.md.bak"
git -C "$R13" add -A
git -C "$R13" -c user.name=t -c user.email=t@t.co commit -q -m "feat: adr-029 plafond 300 (a et b seulement)"
rc=0; run_cpi "$R13" --min-agents 2 || rc=$?
[ "$rc" -eq 0 ] && v=ok || v=ko
report V13 "$v" "baseline sur-estimee sur un agent non touche (marge), attendu rc=0, obtenu rc=$rc : $(printf '%s' "$LAST_OUT" | awk '/^INVARIANTS/')"

echo "== resultat : $OK ok, $KO ko =="
[ "$KO" -eq 0 ]
