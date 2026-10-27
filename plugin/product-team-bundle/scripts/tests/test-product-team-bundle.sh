#!/usr/bin/env bash
# test-product-team-bundle.sh — Suite de composition du module product-team-bundle (Phase 59,
# P59-D-18, P59-PL-06). Distincte de test-check-prd.sh (qui prouve le script par mutants) : cette
# suite prouve que le bundle est bien composé et que chaque garde peut rougir.
#
# Règle de la suite (preuve incapable de rougir = preuve nulle) : chaque contrôle est une fonction
# qui prend la RACINE d'un module en argument, imprime ses motifs de rouge (KO-<CAS>:<détail>) et
# rend 0 ou 1. Il est joué sur le module réel (témoin positif) ET sur une COPIE MUTÉE, qui doit
# rougir avec le motif attendu, pas seulement avec un code non nul. Copie identique = NON OPPOSABLE.
#
#   PTB-COMPO    — fichiers du module, frontmatters (description/model/memory), noms
#   PTB-MODULE   — module.json : version=VERSION, proposable:false, roles, requires
#   PTB-LIGNES   — corpus <= 250 lignes, skill <= 500
#   PTB-MUT-*    — mutants des cas ci-dessus (un par garde)
#   PTB-AGENTS   — check-agents.sh --strict, monde fermé (témoin) ; mutants I6, I1 x2, I5, I2
#   PTB-FRONT    — check-agents.sh --file AGENT.md : exactement 3 avertissements nommés
#   PTB-JUGE     — prd-gate : « 79 n'est pas 80 », contrat check-prd.sh, rubric = 100, Bash borné
#   PTB-MANAGER  — vf-product-manager : verrou, DIGEST, human_needed, proposition sans lancement
#   PTB-BLOC     — bloc typé du kernel dans les quatre agents
#   PTB-SKILL    — /vf-product incarne vibeflow-product, jamais en Task
#   PTB-NOMS     — aucune marque protégée dans les noms, aucun terme de découpage agile exclu (Q-11)
#
# Convention : helpers ok()/ko()/skip(), exit 1 si au moins un KO (SKIP non bloquant).
# Portabilité : bash 3.2, awk POSIX (mawk), aucun chemin de machine ; les copies vivent sous $TMP.

set -uo pipefail

MOD="$(cd "$(dirname "$0")/../.." && pwd)"
REPO="$(cd "$MOD/.." && pwd)"

pass=0; fail=0; skipped=0
ok()   { echo "  ✓ $1"; pass=$((pass+1)); }
ko()   { echo "  ✗ $1"; fail=$((fail+1)); }
skip() { echo "  ⊘ SKIP $1"; skipped=$((skipped+1)); }

# grep insensible aux alias (ugrep) : binaire système.
GREP="$(command -v grep)"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
TMPW="$TMP/w.out"

AGENTS="vf-product-manager vf-product-analyst vf-product-pm prd-gate"
CORPUS="AGENT.md agents/vf-product-manager.md agents/vf-product-analyst.md agents/vf-product-pm.md agents/prd-gate.md"

echo "== test-product-team-bundle (module: $MOD) =="

# ---------------------------------------------------------------------------
# Outils de mutation (aucune écriture hors de $TMP)
# ---------------------------------------------------------------------------
has() { "$GREP" -qF -- "$2" "$1"; }                       # fichier, motif fixe
need() { has "$2" "$4" || { echo "KO-$1:$3"; return 1; }; return 0; }   # CAS fichier id motif

# subst <fichier> <ancien> <nouveau> [préfixe] : remplace TOUTES les occurrences (texte fixe, pas de
# regex) ; avec un préfixe, seules les lignes qui commencent par lui sont touchées.
subst() {
  OLD="$2" NEW="$3" PFX="${4:-}" awk '{
    o = ENVIRON["OLD"]; n = ENVIRON["NEW"]; p = ENVIRON["PFX"]; out = ""; s = $0
    if (p != "" && substr($0, 1, length(p)) != p) { print; next }
    while ((i = index(s, o)) > 0) { out = out substr(s, 1, i - 1) n; s = substr(s, i + length(o)) }
    print out s }' "$1" > "$TMPW" && cp "$TMPW" "$1"
}
# dropline <fichier> <préfixe> : supprime les lignes qui COMMENCENT par ce texte fixe.
dropline() {
  PFX="$2" awk '{ p = ENVIRON["PFX"]; if (substr($0, 1, length(p)) != p) print }' "$1" > "$TMPW" && cp "$TMPW" "$1"
}
# mkmut <étiquette> : copie du module sous $TMP, imprime le chemin.
mkmut() { rm -rf "$TMP/m.$1"; cp -R "$MOD" "$TMP/m.$1" && echo "$TMP/m.$1"; }

LAST_OUT=""
run_ctl() { LAST_OUT="$("$1" "$2" 2>&1)"; return $?; }
brief() { printf '%s' "$LAST_OUT" | tr '\n' ' ' | cut -c1-220; }

# case_ctl <étiquette> <contrôle> <racine> : cas direct, vert attendu.
case_ctl() {
  if run_ctl "$2" "$3"; then ok "$1"; else ko "$1 — $(brief)"; fi
}

# mutant_ptb <étiquette> <motif> <contrôle> <original> <copie mutée>
# Exige : (1) contrôle vert sur l'original, (2) copie différente, (3) contrôle rouge sur la copie,
# (4) la sortie contient le motif attendu.
mutant_ptb() {
  local label="$1" pat="$2" ctl="$3" orig="$4" mut="$5"
  if ! run_ctl "$ctl" "$orig"; then ko "PTB-MUT-$label témoin positif rouge sur l'original — $(brief)"; return; fi
  if diff -rq "$orig" "$mut" >/dev/null 2>&1; then ko "PTB-MUT-$label NON OPPOSABLE (copie identique à l'original)"; return; fi
  if run_ctl "$ctl" "$mut"; then ko "PTB-MUT-$label SURVIVANT : contrôle vert sur la copie mutée"; return; fi
  if printf '%s' "$LAST_OUT" | "$GREP" -qF -- "$pat"; then
    ok "PTB-MUT-$label rouge attendu (« $pat »)"
  else
    ko "PTB-MUT-$label rouge pour une autre raison (attendu « $pat ») — $(brief)"
  fi
}

# ---------------------------------------------------------------------------
# Contrôles (argument : racine d'un module)
# ---------------------------------------------------------------------------
ctl_compo() {
  local r=0 f a field
  for f in $CORPUS skills/vf-product/SKILL.md references/BRIEF.template.md scripts/check-prd.sh; do
    [ -f "$1/$f" ] || { echo "KO-COMPO:absent $f"; r=1; }
  done
  "$GREP" -q '^name: vibeflow-product$' "$1/AGENT.md" 2>/dev/null || { echo "KO-COMPO:name AGENT.md"; r=1; }
  for a in $AGENTS; do
    for field in description model memory; do
      "$GREP" -q "^${field}:" "$1/agents/$a.md" 2>/dev/null || { echo "KO-COMPO:$a sans $field"; r=1; }
    done
    "$GREP" -q "^name: $a\$" "$1/agents/$a.md" 2>/dev/null || { echo "KO-COMPO:$a name != nom de fichier"; r=1; }
  done
  "$GREP" -q '^name: vf-product$' "$1/skills/vf-product/SKILL.md" 2>/dev/null || { echo "KO-COMPO:name skill"; r=1; }
  "$GREP" -q '^vf-invocation: model$' "$1/skills/vf-product/SKILL.md" 2>/dev/null || { echo "KO-COMPO:vf-invocation skill"; r=1; }
  return $r
}

ctl_module() {
  local r=0 j="$1/module.json" ver vf req
  [ -f "$j" ] && [ -f "$1/VERSION" ] || { echo "KO-MODULE:module.json ou VERSION absent"; return 1; }
  ver="$(jq -r '.version' "$j")"; vf="$(tr -d '[:space:]' < "$1/VERSION")"
  # Triade module.json <-> VERSION ; la valeur v1.0.0 est celle de la naissance (CHANGELOG), pas une case
  # permanente : un bump normal ne doit pas rougir cette suite.
  { [ "$ver" = "$vf" ] && printf '%s' "$vf" | "$GREP" -qE '^v[0-9]+\.[0-9]+\.[0-9]+$'; } || { echo "KO-MODULE:version module.json=$ver VERSION=$vf"; r=1; }
  [ "$(jq -r '.proposable' "$j")" = "false" ] || { echo "KO-MODULE:proposable != false"; r=1; }
  [ "$(jq -c '.roles' "$j")" = '["product"]' ] || { echo "KO-MODULE:roles = $(jq -c '.roles' "$j")"; r=1; }
  req="$(jq -r '(.requires // []) | sort | join(",")' "$j")"
  [ "$req" = "audit-architecture,conductor,consolidator,planning-core,software-architecture" ] || { echo "KO-MODULE:requires = $req"; r=1; }
  return $r
}

ctl_lignes() {
  local r=0 f n
  for f in $CORPUS; do
    [ -f "$1/$f" ] || { echo "KO-LIGNES:absent $f"; r=1; continue; }
    n="$(wc -l < "$1/$f" | tr -d ' ')"
    [ "${n:-999}" -le 250 ] || { echo "KO-LIGNES:$f $n >250"; r=1; }
  done
  f="skills/vf-product/SKILL.md"
  [ -f "$1/$f" ] || { echo "KO-LIGNES:absent $f"; return 1; }
  n="$(wc -l < "$1/$f" | tr -d ' ')"
  [ "${n:-999}" -le 500 ] || { echo "KO-LIGNES:$f $n >500"; r=1; }
  return $r
}

# ---------------------------------------------------------------------------
# PTB-COMPO / PTB-MODULE / PTB-LIGNES — cas directs puis mutants
# ---------------------------------------------------------------------------
case_ctl "PTB-COMPO : fichiers, frontmatters (description/model/memory) et noms du module" ctl_compo "$MOD"
case_ctl "PTB-MODULE : version=VERSION, proposable:false, roles=[product], requires fermé" ctl_module "$MOD"
case_ctl "PTB-LIGNES : corpus <= 250 lignes, skill <= 500 (P59-D-12)" ctl_lignes "$MOD"

M="$(mkmut compo)"; dropline "$M/agents/vf-product-analyst.md" "memory:"
mutant_ptb COMPO-MEMORY "KO-COMPO:vf-product-analyst sans memory" ctl_compo "$MOD" "$M"

M="$(mkmut proposable)"; jq '.proposable = true' "$M/module.json" > "$TMPW" && cp "$TMPW" "$M/module.json"
mutant_ptb MODULE-PROPOSABLE "KO-MODULE:proposable" ctl_module "$MOD" "$M"

M="$(mkmut roles)"; jq 'del(.roles)' "$M/module.json" > "$TMPW" && cp "$TMPW" "$M/module.json"
mutant_ptb MODULE-ROLES "KO-MODULE:roles" ctl_module "$MOD" "$M"

M="$(mkmut requires)"; jq '.requires += ["design-orchestrator"]' "$M/module.json" > "$TMPW" && cp "$TMPW" "$M/module.json"
mutant_ptb MODULE-REQUIRES "KO-MODULE:requires" ctl_module "$MOD" "$M"

M="$(mkmut lignes)"
n="$(wc -l < "$M/agents/prd-gate.md" | tr -d ' ')"
awk -v k="$((251 - n))" '{ print } END { for (i = 0; i < k; i++) print "<!-- mutant -->" }' "$M/agents/prd-gate.md" > "$TMPW" && cp "$TMPW" "$M/agents/prd-gate.md"
mutant_ptb LIGNES-251 "KO-LIGNES:agents/prd-gate.md 251 >250" ctl_lignes "$MOD" "$M"

CHECK_AGENTS=""
for cand in "$REPO/conductor/scripts/check-agents.sh" "$HOME/.claude/scripts/check-agents.sh"; do
  [ -f "$cand" ] && { CHECK_AGENTS="$cand"; break; }
done

ctl_agents() {
  local o rc
  o="$(bash "$CHECK_AGENTS" --strict --resolve-agents=strict --manifest-freshness=strict \
        --agents-dir="$1/agents" --agent-registry-dir="$1/agents" 2>&1)"; rc=$?
  printf '%s\n' "$o"
  [ "$rc" -eq 0 ] || echo "KO-AGENTS:rc=$rc"
  return "$rc"
}

ctl_front() {
  local o rc n r=0
  o="$(bash "$CHECK_AGENTS" --file "$1/AGENT.md" 2>&1)"; rc=$?
  n="$(printf '%s\n' "$o" | awk '/⚠/ { n++ } END { print n + 0 }')"
  [ "$rc" -eq 0 ] && [ "$n" -eq 3 ] || { echo "KO-FRONT:rc=$rc avertissements=$n (attendu rc 0 et 3)"; r=1; }
  printf '%s\n' "$o" | "$GREP" -qF 'different du nom de fichier' || { echo "KO-FRONT:avertissement nom absent"; r=1; }
  printf '%s\n' "$o" | "$GREP" -qF 'aucun skill cable' || { echo "KO-FRONT:avertissement skill absent"; r=1; }
  printf '%s\n' "$o" | "$GREP" -qF 'tools absent' || { echo "KO-FRONT:avertissement tools absent"; r=1; }
  return $r
}

# Ancres : « identifiant|texte exact ». Un même tableau sert le contrôle ET le balayage de mutants :
# chaque ancre est retirée à son tour d'une copie, qui doit rougir avec l'identifiant de CETTE ancre.
JUGE_ANCHORS='79|79 n'"'"'est pas 80
seuil|≥ 80
contrat-requirements|check-prd.sh --requirements
contrat-brief|--brief
human_needed|human_needed
eliminatoire|"eliminatoire"
bash-borne|Bash sert uniquement
detail-brief|"brief"
detail-exigences|"exigences"
detail-criteres|"criteres"
detail-priorites|"priorites"
detail-tracabilite|"tracabilite"'
MANAGER_ANCHORS='verrou|driver-lock.sh acquire
digest|DIGEST
human_needed|human_needed
seuil|≥ 80
next_step_propose|next_step_propose
jamais-lance|jamais lancé
override|override'

# anchors <CAS> <fichier> <liste> : toutes les ancres de la liste doivent figurer dans le fichier.
anchors() {
  local r=0 id text
  while IFS='|' read -r id text; do
    [ -n "$id" ] || continue
    need "$1" "$2" "$id" "$text" || r=1
  done <<ANCRES
$3
ANCRES
  return $r
}

ctl_juge() {
  local r=0 f="$1/agents/prd-gate.md" sum
  [ -f "$f" ] || { echo "KO-JUGE:prd-gate.md absent"; return 1; }
  anchors JUGE "$f" "$JUGE_ANCHORS" || r=1
  sum="$(awk -F'|' '/^## Rubric/ { s = 1; next } /^## / { s = 0 } s && $3 ~ /^ *[0-9]+ *$/ { t += $3 } END { print t + 0 }' "$f")"
  [ "$sum" = "100" ] || { echo "KO-JUGE:somme=$sum (attendu 100)"; r=1; }
  return $r
}

ctl_manager() {
  local f="$1/agents/vf-product-manager.md"
  [ -f "$f" ] || { echo "KO-MANAGER:vf-product-manager.md absent"; return 1; }
  anchors MANAGER "$f" "$MANAGER_ANCHORS"
}

# sweep <CAS> <contrôle> <fichier relatif> <liste> : un mutant par ancre (ablation du texte exact).
SWEEP_N=0
sweep() {
  local id text M
  while IFS='|' read -r id text; do
    [ -n "$id" ] || continue
    SWEEP_N=$((SWEEP_N + 1))
    M="$(mkmut "sw$SWEEP_N")"; subst "$M/$3" "$text" "§ablation§"
    mutant_ptb "$1-$id" "KO-$1:$id" "$2" "$MOD" "$M"
  done <<ANCRES
$4
ANCRES
}

ctl_bloc() {
  local r=0 a
  for a in $AGENTS; do
    need BLOC "$1/agents/$a.md" "$a" "passed|gaps_found|human_needed|blocked" || r=1
  done
  return $r
}

ctl_skill() {
  local r=0 f="$1/skills/vf-product/SKILL.md"
  [ -f "$f" ] || { echo "KO-SKILL:SKILL.md absent"; return 1; }
  need SKILL "$f" incarne "incarne l'agent" || r=1
  need SKILL "$f" agent "vibeflow-product" || r=1
  need SKILL "$f" jamais "jamais dispatché en" || r=1      # la phrase se coupe en fin de ligne avant « Task »
  need SKILL "$f" Task "Task (profondeur" || r=1
  need SKILL "$f" manager "vf-product-manager" || r=1
  return $r
}

ctl_noms() {
  local r=0 f
  # Marque protégée : noms de fichiers et champs name: (la doctrine tient dans le nom, pas dans la prose).
  find "$1" -type f | awk 'tolower($0) ~ /bmad/ { print "KO-NOMS:marque dans un nom de fichier " $0; bad = 1 } END { exit bad }' || r=1
  for f in $(find "$1" -type f -name '*.md'); do
    "$GREP" -iE '^name:.*bmad' "$f" >/dev/null 2>&1 && { echo "KO-NOMS:marque dans un champ name: de $f"; r=1; }
  done
  # Termes de découpage agile exclus (Q-11) : mot entier, casse ignorée, hors scripts/tests/ ; gabarits produit inclus.
  if "$GREP" -rIiwE -l 'epics?|stor(y|ies)' --exclude-dir=tests "$1" "$REPO/planning-core/references/templates/product" >/dev/null 2>&1; then
    echo "KO-NOMS:agile terme exclu dans $("$GREP" -rIiwE -l 'epics?|stor(y|ies)' --exclude-dir=tests "$1" "$REPO/planning-core/references/templates/product" | tr '\n' ' ')"
    r=1
  fi
  return $r
}

# ---------------------------------------------------------------------------
# PTB-AGENTS / PTB-FRONT — frontmatters sous check-agents.sh (SKIP nommé si le contrôleur manque)
# ---------------------------------------------------------------------------
if [ -z "$CHECK_AGENTS" ]; then
  skip "PTB-AGENTS contrôleur check-agents.sh introuvable (conductor absent de cette disposition)"
  skip "PTB-FRONT contrôleur check-agents.sh introuvable (conductor absent de cette disposition)"
else
  case_ctl "PTB-AGENTS : --strict --resolve-agents=strict --manifest-freshness=strict vert (monde fermé du bundle)" ctl_agents "$MOD"

  M="$(mkmut i6)"; subst "$M/agents/vf-product-manager.md" "SendMessage, " "" "tools:"
  mutant_ptb AGENTS-I6 "invariant I6" ctl_agents "$MOD" "$M"

  M="$(mkmut i1a)"; dropline "$M/agents/vf-product-analyst.md" "vf-internal:"
  mutant_ptb AGENTS-I1-SANS-DRAPEAU "invariant I1 — description: porte" ctl_agents "$MOD" "$M"

  M="$(mkmut i1b)"; subst "$M/agents/vf-product-pm.md" "Worker interne" "Ouvrier" "description:"
  mutant_ptb AGENTS-I1-SANS-MARQUEUR "invariant I1 — vf-internal: true sans le marqueur" ctl_agents "$MOD" "$M"

  M="$(mkmut i5)"; dropline "$M/agents/prd-gate.md" "omitClaudeMd:"
  mutant_ptb AGENTS-I5 "invariant I5" ctl_agents "$MOD" "$M"

  M="$(mkmut i2)"; subst "$M/agents/vf-product-manager.md" ", prd-gate)" ")" "tools:"
  mutant_ptb AGENTS-I2 "invariant I2" ctl_agents "$MOD" "$M"

  case_ctl "PTB-FRONT : check-agents --file AGENT.md rend 0 avec exactement 3 avertissements nommés" ctl_front "$MOD"

  M="$(mkmut front)"
  awk '{ print } !d && /^memory:/ { print "tools: Read"; d = 1 }' "$M/AGENT.md" > "$TMPW" && cp "$TMPW" "$M/AGENT.md"
  mutant_ptb FRONT-TOOLS "KO-FRONT:avertissement tools absent" ctl_front "$MOD" "$M"

  # Un champ inconnu ajoute un 4e avertissement : le COMPTE change (même falsification que T20 du head).
  M="$(mkmut frontchamp)"
  awk '{ print } !d && /^memory:/ { print "champ-inconnu: x"; d = 1 }' "$M/AGENT.md" > "$TMPW" && cp "$TMPW" "$M/AGENT.md"
  mutant_ptb FRONT-COMPTE "KO-FRONT:rc=0 avertissements=4" ctl_front "$MOD" "$M"
fi

# ---------------------------------------------------------------------------
# PTB-JUGE / PTB-MANAGER / PTB-BLOC / PTB-SKILL / PTB-NOMS — clauses de seuil et doctrine
# ---------------------------------------------------------------------------
case_ctl "PTB-JUGE : prd-gate porte 79 n'est pas 80, le contrat check-prd.sh, la rubric = 100, Bash borné" ctl_juge "$MOD"
M="$(mkmut jsomme)"; subst "$M/agents/prd-gate.md" "mesurables | 25 |" "mesurables | 24 |"
mutant_ptb JUGE-SOMME-99 "KO-JUGE:somme=99" ctl_juge "$MOD" "$M"
sweep JUGE ctl_juge agents/prd-gate.md "$JUGE_ANCHORS"

case_ctl "PTB-MANAGER : verrou, DIGEST, human_needed sous le seuil, proposition jamais lancée, override tracé" ctl_manager "$MOD"
sweep MANAGER ctl_manager agents/vf-product-manager.md "$MANAGER_ANCHORS"

case_ctl "PTB-BLOC : bloc typé passed|gaps_found|human_needed|blocked dans les quatre agents" ctl_bloc "$MOD"
M="$(mkmut bloc)"; subst "$M/agents/vf-product-analyst.md" "passed|gaps_found|human_needed|blocked" "ok|ko"
mutant_ptb BLOC-ANALYSTE "KO-BLOC:vf-product-analyst" ctl_bloc "$MOD" "$M"

case_ctl "PTB-SKILL : /vf-product incarne vibeflow-product, jamais dispatché en Task, cite le manager" ctl_skill "$MOD"
M="$(mkmut skill)"; subst "$M/skills/vf-product/SKILL.md" "jamais dispatché en" "dispatché en"
mutant_ptb SKILL-JAMAIS-TASK "KO-SKILL:jamais" ctl_skill "$MOD" "$M"

case_ctl "PTB-NOMS : aucune marque protégée dans les noms, aucun terme de découpage agile exclu (Q-11)" ctl_noms "$MOD"
M="$(mkmut nagile)"; printf '\nLe découpage en epic puis en story est exclu.\n' >> "$M/agents/vf-product-pm.md"
mutant_ptb NOMS-AGILE "KO-NOMS:agile" ctl_noms "$MOD" "$M"
M="$(mkmut nmarque)"; subst "$M/agents/vf-product-pm.md" "name: vf-product-pm" "name: bmad-pm" "name:"
mutant_ptb NOMS-MARQUE "KO-NOMS:marque dans un champ name:" ctl_noms "$MOD" "$M"

echo "== résultat : $pass OK / $fail KO / $skipped SKIP =="
[ "$fail" -eq 0 ]
