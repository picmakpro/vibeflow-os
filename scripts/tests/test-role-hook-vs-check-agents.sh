#!/usr/bin/env bash
# test-role-hook-vs-check-agents.sh — contrôle croisé du rôle dérivé par le hook central de planning-core
# (Phase 45, plan 45-08 ; GATE-09, P45-D-05, P45-D-05a) : le hook RÉIMPLÉMENTE les prédicats I5 (juge) et I6
# (manager) de plugin/conductor/scripts/check-agents.sh — planning-core ne dépend d'aucun module, un lab qui
# l'installe seul n'a pas ce script. Deux implémentations de la même classification divergent tôt ou tard :
# cette suite compare le rôle que le hook rend (mode de diagnostic `planning-hook.sh --classer`) à un ORACLE
# DIFFÉRENTIEL fait de check-agents.sh lui-même, sur tout le corpus d'agents du dépôt et sur des fixtures
# adverses. Elle peut rougir : deux mutants du hook (MUT-CROISE-JUGE, MUT-CROISE-TOKENIZER) doivent la faire
# rougir, sinon elle ne prouve rien.
#
# Outillage du DÉPÔT (scripts/tests/, pas un module) : il asserte sur des scripts de DEUX modules (planning-core
# et conductor) à la fois, ce qu'un test de module ne peut pas faire sans casser dans un lab qui n'en installe
# qu'un (même doctrine que scripts/tests/test-hook-exit-parc.sh).
#
# ORACLE (recette sondée, 45-RESEARCH.md « Oracle différentiel du rôle »). Pour chaque définition, deux
# variantes jetables sous mktemp : (a) sans la ligne `omitClaudeMd:` -> `invariant I5` dans la sortie de
# `check-agents.sh --file` <=> juge ; (b) sans `SendMessage` dans `tools:` -> `invariant I6` <=> manager ; sinon
# `vf-internal: true` lu par une expression minimale <=> worker ; sinon producteur. Les fixtures portent en
# plus un rôle DÉCLARÉ par cette suite : hook, oracle et déclaré doivent s'accorder (une fixture fausse est
# signalée, jamais absorbée).
#
# Corpus : `plugin/<module>/agents/*.md` et `plugin/<module>/AGENT.md`, recomptés par find ; plancher déclaré
# 31 (jamais un vert à vide). Les juges trouvés sont exactement quality-gate-client, content-clarity-judge,
# vf-design-judge, growth-quality-judge ; les managers exactement les cinq vf-*-manager.
#
# Portable GNU/BSD (bash 3.2, P45-D-16) : ni `sed -i`, ni `diff` (proxifié et menteur sur ce poste : `cmp`,
# `comm`), ni tableau associatif, ni `timeout` ; lançable depuis tout cwd ; aucun fichier du dépôt n'est modifié
# (mutants et fixtures sous mktemp -d).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOK="$ROOT/plugin/planning-core/scripts/planning-hook.sh"
CHECK="$ROOT/plugin/conductor/scripts/check-agents.sh"
PLANCHER_CORPUS=31

pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() {
  echo "  ✗ $1"
  echo "    assertion : $2"
  echo "    attendu   : $3"
  echo "    obtenu    : $4"
  fail=$((fail+1))
}

WORK="$(mktemp -d)" || { echo "mktemp -d a échoué" >&2; exit 1; }
trap 'rm -rf "$WORK"' EXIT
export LC_ALL=C
TAB="$(printf '\t')"

[ -f "$HOOK" ] || { ko "planning-hook.sh présent" "le hook central existe" "$HOOK" "absent"; echo "== Résultat : $pass OK · $fail KO =="; exit 1; }
[ -f "$CHECK" ] || { ko "check-agents.sh présent" "l'oracle existe" "$CHECK" "absent"; echo "== Résultat : $pass OK · $fail KO =="; exit 1; }

# --- Corpus ---------------------------------------------------------------------------------------------
CORPUS="$WORK/corpus.txt"
( cd "$ROOT" && { find plugin -mindepth 3 -maxdepth 3 -path 'plugin/*/agents/*.md'; find plugin -mindepth 2 -maxdepth 2 -name AGENT.md; } | sort ) > "$CORPUS"
N_CORPUS="$(grep -c . "$CORPUS")"

# --- Fixtures adverses ------------------------------------------------------------------------------------
# Chaque fixture : fixtures/<nom>.md ; son rôle DÉCLARÉ par cette suite est dans declares.txt (<nom> <rôle>).
FIX="$WORK/fixtures"
mkdir -p "$FIX"
DECLARES="$WORK/declares.txt"
: > "$DECLARES"

fixture() { # <nom> <rôle déclaré> <lignes du frontmatter...> (le frontmatter est refermé par la suite)
  local nom="$1" role="$2"; shift 2
  { echo "---"; echo "name: $nom"; echo "description: fixture adverse du contrôle croisé du rôle"; local l; for l in "$@"; do echo "$l"; done; echo "---"; echo "Corps de la fixture."; } > "$FIX/$nom.md"
  echo "$nom $role" >> "$DECLARES"
}

fixture allowlist-imbriquee manager 'tools: Read, SendMessage, Agent(a, b(c, d), e)'
fixture allowlist-task manager 'tools: Read, SendMessage, Task(x, y)'
fixture allowlist-agent-et-task manager 'tools: Read, SendMessage, Agent(x), Task(y)'
fixture disallowed-bloc juge 'tools: Read, Glob' 'disallowedTools:' '  - Write' '  - Edit' 'omitClaudeMd: true'
fixture disallowed-flux juge 'tools: Read, Glob' 'disallowedTools: [Write, Edit]' 'omitClaudeMd: true'
fixture disallowed-guillemets juge 'tools: Read, Glob' 'disallowedTools: "Write, Edit"' 'omitClaudeMd: true'
fixture interne-guillemets worker 'tools: Read, Write' 'vf-internal: "true"'
fixture continuation-indentee manager 'tools: Read, SendMessage,' '  Agent(a, b)'
fixture write-seul producteur 'tools: Read, Glob' 'disallowedTools: Write' 'omitClaudeMd: true'
fixture edit-seul producteur 'tools: Read, Glob' 'disallowedTools: Edit' 'omitClaudeMd: true'
fixture juge-interne juge 'tools: Read, Glob' 'disallowedTools: Write, Edit' 'omitClaudeMd: true' 'vf-internal: true'
fixture juge-avec-allowlist-interne worker 'tools: Read, Agent(x)' 'disallowedTools: Write, Edit' 'vf-internal: true'
fixture juge-avec-allowlist-non-interne manager 'tools: Read, SendMessage, Agent(x)' 'disallowedTools: Write, Edit'
fixture manager-interne worker 'tools: Read, SendMessage, Agent(x)' 'vf-internal: true'
fixture juge-allowlist-vide juge 'tools: Read, Agent()' 'disallowedTools: Write, Edit' 'omitClaudeMd: true'
fixture agent-nu producteur 'tools: Read, SendMessage, Agent'
fixture parenthese-non-fermee producteur 'tools: Read, SendMessage, Agent(a, b'
fixture entree-vide producteur 'tools: Read, SendMessage, Agent(a,,b)'
fixture disallowed-parenthese producteur 'tools: Read, Glob' 'disallowedTools: Write, Edit(x)'
fixture interne-faux producteur 'tools: Read, Write' 'vf-internal: vrai'
fixture tools-guillemets manager 'tools: "Read, SendMessage, Agent(a, b)"'
fixture tools-puces manager 'tools:' '  - Read' '  - SendMessage' '  - Agent(a, b)'
fixture producteur-simple producteur 'tools: Read, Write, Glob'
N_FIXTURES="$(grep -c . "$DECLARES")"

# --- Oracle différentiel : check-agents.sh sur deux variantes jetables -------------------------------------
variante_sans_omit() { # <src> <dst> : retire les lignes `omitClaudeMd:` du frontmatter
  awk 'NR == 1 && $0 == "---" { fm = 1; print; next } fm && $0 == "---" { fm = 0 } fm && /^omitClaudeMd:/ { next } { print }' "$1" > "$2"
}
variante_sans_sendmessage() { # <src> <dst> : retire SendMessage des tools: du frontmatter (puce, liste, continuation)
  awk 'NR == 1 && $0 == "---" { fm = 1; print; next }
       fm && $0 == "---" { fm = 0 }
       fm && /^[ \t]+-[ \t]+SendMessage[ \t]*$/ { next }
       fm && (/^tools:/ || /^[ \t]/) { gsub(/SendMessage[ ]*,[ ]*/, ""); gsub(/,[ ]*SendMessage/, ""); gsub(/SendMessage/, "") }
       { print }' "$1" > "$2"
}
interne_vrai() { # <fichier> : vf-internal: true (sans ou avec guillemets), dans le frontmatter seulement
  awk 'NR == 1 && $0 == "---" { fm = 1; next } fm && $0 == "---" { exit } fm { print }' "$1" \
    | grep -E "^vf-internal:[[:space:]]*[\"']?true[\"']?[[:space:]]*$" > /dev/null
}

role_oracle() { # <fichier> <nom unique> : rôle selon check-agents.sh (case sur la sortie : jamais un grep -q sous pipefail)
  local f="$1" n="$2" sortie_a sortie_b
  variante_sans_omit "$f" "$WORK/va-$n.md"
  variante_sans_sendmessage "$f" "$WORK/vb-$n.md"
  sortie_a="$(bash "$CHECK" --file "$WORK/va-$n.md" 2>&1)"
  case "$sortie_a" in *"invariant I5"*) echo juge; return ;; esac
  sortie_b="$(bash "$CHECK" --file "$WORK/vb-$n.md" 2>&1)"
  case "$sortie_b" in *"invariant I6"*) echo manager; return ;; esac
  if interne_vrai "$f"; then echo worker; return; fi
  echo producteur
}

# ORACLE : <clé>\t<chemin>\t<rôle oracle>\t<rôle déclaré ou -> ; construit UNE fois (indépendant du hook).
ORACLE="$WORK/oracle.tsv"
: > "$ORACLE"
i=0
while IFS= read -r rel; do
  i=$((i+1))
  printf '%s\t%s\t%s\t-\n' "corpus:$rel" "$ROOT/$rel" "$(role_oracle "$ROOT/$rel" "c$i")" >> "$ORACLE"
done < "$CORPUS"
while IFS=' ' read -r nom declare; do
  i=$((i+1))
  printf '%s\t%s\t%s\t%s\n' "fixture:$nom" "$FIX/$nom.md" "$(role_oracle "$FIX/$nom.md" "f$i")" "$declare" >> "$ORACLE"
done < "$DECLARES"

# --- Comparaison : rôle rendu par un hook (--classer) contre l'oracle --------------------------------------
role_hook() { # <hook> <fichier>
  bash "$1" --classer "$2" 2>/dev/null | sed -n 's/^{"role": "\([a-z]*\)".*/\1/p'
}

comparer() { # <hook> <fichier de sortie des écarts> : imprime « n ecarts » sur stdout
  local hook="$1" sortie="$2" n=0 ecarts=0 cle chemin oracle declare rh
  : > "$sortie"
  while IFS="$TAB" read -r cle chemin oracle declare; do
    n=$((n+1))
    rh="$(role_hook "$hook" "$chemin")"
    if [ "$rh" != "$oracle" ]; then
      ecarts=$((ecarts+1)); echo "$cle : hook=${rh:-<vide>} oracle=$oracle" >> "$sortie"
    elif [ "$declare" != "-" ] && [ "$declare" != "$oracle" ]; then
      ecarts=$((ecarts+1)); echo "$cle : oracle=$oracle déclaré=$declare (fixture fausse ou oracle faux)" >> "$sortie"
    fi
  done < "$ORACLE"
  echo "$n $ecarts"
}

echo "== Contrôle croisé du rôle : hook (--classer) contre check-agents.sh =="
ECARTS_F="$WORK/ecarts-hook.txt"
set -- $(comparer "$HOOK" "$ECARTS_F")
N_COMPARES="$1"; N_ECARTS="$2"
echo "CROISE n=$N_COMPARES corpus=$N_CORPUS fixtures=$N_FIXTURES ecarts=$N_ECARTS"
if [ "$N_CORPUS" -lt "$PLANCHER_CORPUS" ]; then
  ko "CROISE corpus" "le corpus compte au moins $PLANCHER_CORPUS définitions d'agents (find, jamais un vert à vide)" ">= $PLANCHER_CORPUS" "$N_CORPUS"
else
  ok "CROISE corpus : $N_CORPUS définitions d'agents recomptées par find (plancher $PLANCHER_CORPUS)"
fi
if [ "$N_ECARTS" -ne 0 ]; then
  ko "CROISE écarts" "rôle du hook = oracle check-agents.sh pour chaque définition et chaque fixture" "ecarts=0" "ecarts=$N_ECARTS : $(tr '\n' ';' < "$ECARTS_F")"
else
  ok "CROISE : $N_COMPARES définitions (corpus $N_CORPUS + fixtures $N_FIXTURES), rôle du hook = oracle, aucune fixture fausse"
fi

# Les juges et les managers du corpus : exactement les noms connus (le hook ET l'oracle).
JUGES_ATTENDUS="$WORK/juges-attendus.txt"
MANAGERS_ATTENDUS="$WORK/managers-attendus.txt"
printf '%s\n' content-clarity-judge growth-quality-judge quality-gate-client vf-design-judge | sort > "$JUGES_ATTENDUS"
printf '%s\n' vf-business-manager vf-content-manager vf-design-manager vf-dev-manager vf-growth-manager | sort > "$MANAGERS_ATTENDUS"
for role in juge manager; do
  TROUVES="$WORK/trouves-$role.txt"
  : > "$TROUVES"
  while IFS="$TAB" read -r cle chemin oracle declare; do
    case "$cle" in corpus:*) ;; *) continue ;; esac
    if [ "$(role_hook "$HOOK" "$chemin")" = "$role" ]; then basename "$chemin" .md >> "$TROUVES"; fi
  done < "$ORACLE"
  sort -o "$TROUVES" "$TROUVES"
  if [ "$role" = "juge" ]; then attendus="$JUGES_ATTENDUS"; else attendus="$MANAGERS_ATTENDUS"; fi
  if cmp -s "$TROUVES" "$attendus"; then
    ok "CROISE-${role}s : le hook classe en $role exactement $(tr '\n' ' ' < "$attendus")"
  else
    ko "CROISE-${role}s" "les ${role}s du corpus sont exactement la liste connue" "$(tr '\n' ' ' < "$attendus")" "$(tr '\n' ' ' < "$TROUVES")"
  fi
done

# --- Mutants du hook (copies sous mktemp, motif unique, cmp) ----------------------------------------------
muter() { # <src> <dst> <motif> <remplacement> : remplace la ligne UNIQUE qui contient le motif (indentation gardée)
  awk -v m="$3" -v r="$4" 'index($0, m) { n++; match($0, /^[ ]*/); print substr($0, 1, RLENGTH) r; next } { print } END { if (n != 1) exit 3 }' "$1" > "$2"
}

mutant() { # <id> <motif> <remplacement> <libellé de l'écart attendu>
  local id="$1" motif="$2" repl="$3" attendu="$4" dst="$WORK/mutant-$1/planning-hook.sh" n ecarts
  mkdir -p "$WORK/mutant-$id"
  if ! muter "$HOOK" "$dst" "$motif" "$repl"; then
    ko "MUT-$id" "le motif du mutant est unique dans planning-hook.sh" "une seule ligne" "motif absent ou ambigu : $motif"
    return
  fi
  if cmp -s "$HOOK" "$dst"; then
    ko "MUT-$id" "le mutant diffère du hook (cmp)" "copies différentes" "copies identiques — mutant NON OPPOSABLE"
    return
  fi
  if ! bash -n "$dst" 2>/dev/null; then
    ko "MUT-$id" "le mutant est du bash valide (bash -n)" "syntaxe valide" "bash -n échoue"
    return
  fi
  chmod +x "$dst"
  set -- $(comparer "$dst" "$WORK/ecarts-$id.txt")
  n="$1"; ecarts="$2"
  if [ "$ecarts" -ge 1 ]; then
    echo "  ✓ MUT-$id TUÉ — $attendu · ecarts=$ecarts sur $n · premier écart : $(head -1 "$WORK/ecarts-$id.txt")"
    pass=$((pass+1))
  else
    echo "  ✗ MUT-$id NON TUÉ"
    echo "    assertion : le contrôle croisé rougit sous le mutant ($attendu)"
    echo "    attendu   : ecarts >= 1"
    echo "    obtenu    : ecarts=$ecarts sur $n (mutant non opposable par cette suite)"
    fail=$((fail+1))
  fi
}

mutant CROISE-JUGE 'if "Write" in interdits and "Edit" in interdits and not liste:  # role-juge' \
  'if "Write" in interdits and not liste:  # role-juge' \
  "juge = Write seul retiré : la fixture « write-seul » devient un juge pour le hook, pas pour check-agents.sh"
mutant CROISE-TOKENIZER 'elif ch == "," and profondeur == 0:  # role-virgule' \
  'elif ch == ",":  # role-virgule' \
  "découpage à la virgule nue : les allowlists Agent(a, b) éclatent, les managers ne sont plus vus"

echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
