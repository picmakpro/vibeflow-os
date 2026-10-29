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
#   PTB-DISPOSITION — dépôt ou lab reconnu par le NOM de la racine (signal positif), jamais par l'absence d'un fichier ;
#                     en dépôt, retirer AGENT.md, module.json ou VERSION rougit (mutants)
#   PTB-COMPO, PTB-MODULE, PTB-LIGNES — fichiers, frontmatters, module.json, 250 lignes (+ mutants)
#   PTB-AGENTS, PTB-FRONT — check-agents.sh en monde fermé (mutants I6, I1 x2, I5, I2) et sur AGENT.md
#   PTB-JUGE, PTB-MANAGER — une ancre par clause de seuil (79 n'est pas 80, rubric = 100, human_needed,
#                           jamais lancé...), chaque ancre retirée à son tour d'une copie
#   PTB-BLOC, PTB-SKILL, PTB-NOMS — bloc typé, incarnation sans Task, marque protégée, termes agiles (Q-11)
#   PTB-GABARITS, PTB-GSD — gabarits brut -> check-prd 1, rempli -> 0 ; lisibles par gsd-tools mark-complete
#   PTB-CATALOG — proposable:false prouvé POSITIVEMENT (test-build-module-catalog.sh reste intact)
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

# Disposition : DÉPÔT (le module est un dossier complet nommé product-team-bundle : AGENT.md, module.json, VERSION) ou
# LAB (suite posée à plat par l'installeur sous <racine>/.claude/scripts/tests/ : le module n'existe plus comme
# dossier). Elle se reconnaît par un signal POSITIF, le nom de la racine, JAMAIS par l'absence d'un fichier contrôlé
# (sinon supprimer AGENT.md ferait passer la suite en « lab » et sauter ses contrôles). Un nom inconnu est un KO.
# Les contrôles qui lisent le module entier ou les dossiers voisins du dépôt sont sautés AUDIBLEMENT en lab (SKIP
# compté, jamais OK) ; en dépôt, l'absence d'un fichier du module est un KO.
detect_dispo() { # <racine> -> depot | lab | inconnue
  case "$(basename "$1")" in
    .claude) echo lab ;;
    product-team-bundle) echo depot ;;
    *) echo inconnue ;;
  esac
}
DISPO="$(detect_dispo "$MOD")"
if [ "$DISPO" = lab ]; then LAB=1; else LAB=0; fi

echo "== test-product-team-bundle (module: $MOD, disposition: $DISPO) =="
[ "$LAB" = 1 ] && echo "  (disposition lab : contrôles propres au dépôt sautés — composition du module, lignes, front matter AGENT.md, noms, gabarits)"

# --- Outils de mutation (aucune écriture hors de $TMP)
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

# --- Contrôles (argument : racine d'un module)
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

ctl_disposition() { # <racine> : en dépôt, AGENT.md, module.json et VERSION sont exigés ; nom inconnu = rouge
  local r=0 f
  case "$(detect_dispo "$1")" in
    depot) for f in AGENT.md module.json VERSION; do [ -f "$1/$f" ] || { echo "KO-DISPOSITION:absent $f en disposition dépôt"; r=1; }; done ;;
    lab) : ;;
    *) echo "KO-DISPOSITION:racine $(basename "$1") ni .claude ni product-team-bundle"; r=1 ;;
  esac
  return $r
}

# --- PTB-DISPOSITION : signal positif, jamais l'absence d'un fichier contrôlé (revue-59, tour 2)
mkdispo() { rm -rf "$TMP/dispo.$1"; mkdir -p "$TMP/dispo.$1"; cp -R "$MOD" "$TMP/dispo.$1/product-team-bundle" 2>/dev/null && echo "$TMP/dispo.$1/product-team-bundle"; }
case_ctl "PTB-DISPOSITION : racine réelle reconnue ($DISPO), fichiers exigés en dépôt" ctl_disposition "$MOD"
if [ "$DISPO" = depot ]; then
  M="$(mkdispo agent)"; rm -f "$M/AGENT.md"
  mutant_ptb DISPO-AGENT "KO-DISPOSITION:absent AGENT.md" ctl_disposition "$MOD" "$M"
  M="$(mkdispo json)"; rm -f "$M/module.json"
  mutant_ptb DISPO-MODULE-JSON "KO-DISPOSITION:absent module.json" ctl_disposition "$MOD" "$M"
  M="$(mkdispo version)"; rm -f "$M/VERSION"
  mutant_ptb DISPO-VERSION "KO-DISPOSITION:absent VERSION" ctl_disposition "$MOD" "$M"
fi
mkdir -p "$TMP/dx/.claude" "$TMP/dx/product-team-bundle" "$TMP/dx/ailleurs"
{ [ "$(detect_dispo "$TMP/dx/.claude")" = lab ] && [ "$(detect_dispo "$TMP/dx/product-team-bundle")" = depot ] \
  && [ "$(detect_dispo "$TMP/dx/ailleurs")" = inconnue ]; } \
  && ok "PTB-DISPOSITION : « .claude » = lab, « product-team-bundle » = dépôt, tout autre nom = inconnue" \
  || ko "PTB-DISPOSITION : détection de la disposition par le nom de la racine"
if ctl_disposition "$TMP/dx/ailleurs" >/dev/null 2>&1; then ko "PTB-DISPOSITION : racine inconnue acceptée (devrait rougir)"; else ok "PTB-DISPOSITION : racine inconnue rouge"; fi
if ctl_disposition "$TMP/dx/.claude" >/dev/null 2>&1; then ok "PTB-DISPOSITION : racine « .claude » sans AGENT.md acceptée (lab)"; else ko "PTB-DISPOSITION : racine lab rouge à tort"; fi
if ctl_disposition "$TMP/dx/product-team-bundle" >/dev/null 2>&1; then ko "PTB-DISPOSITION : dossier module vide accepté (devrait rougir)"; else ok "PTB-DISPOSITION : dossier module vide rouge en dépôt"; fi

# --- PTB-COMPO / PTB-MODULE / PTB-LIGNES — cas directs puis mutants
if [ "$LAB" = 1 ]; then
  skip "PTB-COMPO disposition lab : le module n'est pas un dossier complet (contrôle propre au dépôt)"
  skip "PTB-MODULE disposition lab : module.json et VERSION ne sont pas posés (contrôle propre au dépôt)"
  skip "PTB-LIGNES disposition lab : corpus non regroupé sous la racine du module (contrôle propre au dépôt)"
else
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
fi

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
# Une clause de seuil se compte OCCURRENCE PAR OCCURRENCE (revue-59 F5) : l'ablation retire toutes les
# occurrences du texte exact, donc chaque occurrence porteuse a son propre texte de contexte, unique
# dans son fichier — un seuil changé sur UNE ligne seulement laisse sa propre ancre introuvable.
JUGE_ANCHORS='79|79 n'"'"'est pas 80
description-seuil|passe à 80 sans éliminatoire
seuil-entete|Seuil de passage : score ≥ 80/100 ET aucun
seuil-passed|`passed` si le score est ≥ 80 ET
contrat-requirements|check-prd.sh --requirements
contrat-brief|--brief
human_needed|human_needed
eliminatoire|"eliminatoire"
bash-borne|Bash sert uniquement
detail-brief|"brief"
detail-exigences|"exigences"
detail-criteres|"criteres"
detail-priorites|"priorites"
detail-tracabilite|"tracabilite"
mode-brief-seul|## Rubric /100 — mode BRIEF seul
mode-brief-appel|En mode BRIEF seul, l'"'"'appel est
mode-brief-sans-exigences|Aucun point n'"'"'est joué sur des exigences
mode-brief-seuil|Seuil de passage, identique : score ≥ 80/100
methode-brief-seul|puis (sauf en mode BRIEF seul, étape 7) le PROJECT'
MANAGER_ANCHORS='verrou|driver-lock.sh acquire
digest|DIGEST
human_needed|human_needed
seuil-vert|score ≥ 80, `eliminatoire: false`
seuil-verdict|score ≥ 80/100, `eliminatoire: false`
seuil-sous|score < 80
next_step_propose|next_step_propose
jamais-lance|jamais lancé
vert-juge|Un vert ne vient que de `prd-gate`
halte-humaine|Sous le seuil, halte humaine
pas-de-passage-de-main|ni relance silencieuse, ni passage de main au head
aucun-passage-de-main|Aucun passage de main au head
override|override
livrables-verdict|`brief+prd`, `verdict`}
verdict-seul|`verdict` ne garde que `juge` → `humain`
prd-saute-analyste|`prd` seul saute `analyste`
brief-mode-juge|le juge est dispatché en **mode BRIEF seul**
brief-mode-appel|appel `check-prd.sh --brief`
dag-chemin|.planning/missions/<AAAA-MM-JJ>-<sujet>.dag.json'

# Front door : mêmes livrables que le manager (un verdict demandé est une mission acceptée), code 3 complet.
AGENTMD_ANCHORS='livrables-verdict|`brief+prd`, `verdict`}
code-3-complet|indéterminé (cible absente, zéro exigence, case à cocher non reconnue, bloc ou commentaire non fermé)'

# Outils exacts des deux workers producteurs (revue-59 : un outil en trop, Bash sur l'analyste qui dit ne pas l'avoir,
# laissait la suite verte). Ligne « tools: » égale à la valeur attendue, pas un simple préfixe.
ANALYST_TOOLS='Read, Write, Edit, Glob, Grep'
PM_TOOLS='Read, Write, Edit, Glob, Grep'

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
  local r=0 f="$1/agents/prd-gate.md" sum sums
  [ -f "$f" ] || { echo "KO-JUGE:prd-gate.md absent"; return 1; }
  anchors JUGE "$f" "$JUGE_ANCHORS" || r=1
  # Une somme PAR rubric (complet ET mode BRIEF seul), chacune égale à 100 ; deux rubrics au moins.
  sums="$(awk -F'|' '/^## Rubric/ { s = 1; n++; next } /^## / { s = 0 } s && $3 ~ /^ *[0-9]+ *$/ { t[n] += $3 } END { for (i = 1; i <= n; i++) print t[i] + 0 }' "$f")"
  [ "$(printf '%s\n' "$sums" | awk 'NF { c++ } END { print c + 0 }')" -ge 2 ] || { echo "KO-JUGE:rubric BRIEF seul absente (deux rubrics attendues)"; r=1; }
  for sum in $sums; do
    [ "$sum" = "100" ] || { echo "KO-JUGE:somme=$sum (attendu 100)"; r=1; }
  done
  return $r
}

ctl_manager() {
  local f="$1/agents/vf-product-manager.md"
  [ -f "$f" ] || { echo "KO-MANAGER:vf-product-manager.md absent"; return 1; }
  anchors MANAGER "$f" "$MANAGER_ANCHORS"
}

ctl_agentmd() {
  local f="$1/AGENT.md"
  [ -f "$f" ] || { echo "KO-AGENTMD:AGENT.md absent"; return 1; }
  anchors AGENTMD "$f" "$AGENTMD_ANCHORS"
}

ctl_tools() { # <racine> : tools: exacts des workers analyste et pm
  local r=0 a want got
  for a in vf-product-analyst vf-product-pm; do
    case "$a" in vf-product-analyst) want="$ANALYST_TOOLS" ;; *) want="$PM_TOOLS" ;; esac
    got="$(awk '/^tools:/ { sub(/^tools:[[:space:]]*/, ""); print; exit }' "$1/agents/$a.md" 2>/dev/null)"
    [ "$got" = "$want" ] || { echo "KO-TOOLS:$a tools=[$got] (attendu [$want])"; r=1; }
  done
  return $r
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

# --- PTB-AGENTS / PTB-FRONT — frontmatters sous check-agents.sh (SKIP nommé si le contrôleur manque)
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

if [ "$LAB" = 1 ]; then
  skip "PTB-FRONT disposition lab : AGENT.md est posé sous agents/product-team-bundle.md (contrôle propre au dépôt)"
else
    case_ctl "PTB-FRONT : check-agents --file AGENT.md rend 0 avec exactement 3 avertissements nommés" ctl_front "$MOD"

    M="$(mkmut front)"
    awk '{ print } !d && /^memory:/ { print "tools: Read"; d = 1 }' "$M/AGENT.md" > "$TMPW" && cp "$TMPW" "$M/AGENT.md"
    mutant_ptb FRONT-TOOLS "KO-FRONT:avertissement tools absent" ctl_front "$MOD" "$M"

    # Un champ inconnu ajoute un 4e avertissement : le COMPTE change (même falsification que T20 du head).
    M="$(mkmut frontchamp)"
    awk '{ print } !d && /^memory:/ { print "champ-inconnu: x"; d = 1 }' "$M/AGENT.md" > "$TMPW" && cp "$TMPW" "$M/AGENT.md"
    mutant_ptb FRONT-COMPTE "KO-FRONT:rc=0 avertissements=4" ctl_front "$MOD" "$M"
fi
fi

# --- PTB-JUGE / PTB-MANAGER / PTB-BLOC / PTB-SKILL / PTB-NOMS — clauses de seuil et doctrine
case_ctl "PTB-JUGE : prd-gate porte 79 n'est pas 80, le contrat check-prd.sh, la rubric = 100, Bash borné" ctl_juge "$MOD"
M="$(mkmut jsomme)"; subst "$M/agents/prd-gate.md" "mesurables | 25 |" "mesurables | 24 |"
mutant_ptb JUGE-SOMME-99 "KO-JUGE:somme=99" ctl_juge "$MOD" "$M"
M="$(mkmut jsommeb)"; subst "$M/agents/prd-gate.md" "rien d'inventé | 25 |" "rien d'inventé | 24 |"
mutant_ptb JUGE-SOMME-BRIEF-99 "KO-JUGE:somme=99" ctl_juge "$MOD" "$M"
M="$(mkmut jsansb)"; subst "$M/agents/prd-gate.md" "## Rubric /100 — mode BRIEF seul" "## Section BRIEF seul"
mutant_ptb JUGE-SANS-RUBRIC-BRIEF "KO-JUGE:rubric BRIEF seul absente" ctl_juge "$MOD" "$M"
sweep JUGE ctl_juge agents/prd-gate.md "$JUGE_ANCHORS"

case_ctl "PTB-MANAGER : verrou, DIGEST, human_needed sous le seuil, proposition jamais lancée, override tracé" ctl_manager "$MOD"
sweep MANAGER ctl_manager agents/vf-product-manager.md "$MANAGER_ANCHORS"

case_ctl "PTB-AGENTMD : le front door annonce les mêmes livrables que le manager et le code 3 complet" ctl_agentmd "$MOD"
sweep AGENTMD ctl_agentmd AGENT.md "$AGENTMD_ANCHORS"

case_ctl "PTB-TOOLS : les workers analyste et pm portent exactement leurs outils (analyste sans Bash)" ctl_tools "$MOD"
M="$(mkmut toolsa)"; subst "$M/agents/vf-product-analyst.md" "Grep" "Grep, Bash" "tools:"
mutant_ptb TOOLS-ANALYSTE-BASH "KO-TOOLS:vf-product-analyst" ctl_tools "$MOD" "$M"
M="$(mkmut toolsae)"; subst "$M/agents/vf-product-analyst.md" "Write, Edit," "Write," "tools:"
mutant_ptb TOOLS-ANALYSTE-EDIT "KO-TOOLS:vf-product-analyst" ctl_tools "$MOD" "$M"
M="$(mkmut toolsp)"; subst "$M/agents/vf-product-pm.md" "Grep" "Grep, Bash" "tools:"
mutant_ptb TOOLS-PM-BASH "KO-TOOLS:vf-product-pm" ctl_tools "$MOD" "$M"

# PRDT-06 : inversion de la clause de halte et de l'interdiction de passage de main (pas seulement leur ablation).
M="$(mkmut halte)"; subst "$M/agents/vf-product-manager.md" "Sous le seuil, halte humaine" "Sous le seuil, relance libre"
mutant_ptb MANAGER-HALTE-INVERSEE "KO-MANAGER:halte-humaine" ctl_manager "$MOD" "$M"
M="$(mkmut passage)"; subst "$M/agents/vf-product-manager.md" "ni relance silencieuse, ni passage de main au head" "puis relance silencieuse, puis passage de main au head"
mutant_ptb MANAGER-PASSAGE-INVERSE "KO-MANAGER:pas-de-passage-de-main" ctl_manager "$MOD" "$M"

case_ctl "PTB-BLOC : bloc typé passed|gaps_found|human_needed|blocked dans les quatre agents" ctl_bloc "$MOD"
M="$(mkmut bloc)"; subst "$M/agents/vf-product-analyst.md" "passed|gaps_found|human_needed|blocked" "ok|ko"
mutant_ptb BLOC-ANALYSTE "KO-BLOC:vf-product-analyst" ctl_bloc "$MOD" "$M"

case_ctl "PTB-SKILL : /vf-product incarne vibeflow-product, jamais dispatché en Task, cite le manager" ctl_skill "$MOD"
M="$(mkmut skill)"; subst "$M/skills/vf-product/SKILL.md" "jamais dispatché en" "dispatché en"
mutant_ptb SKILL-JAMAIS-TASK "KO-SKILL:jamais" ctl_skill "$MOD" "$M"

if [ "$LAB" = 1 ]; then
  skip "PTB-NOMS disposition lab : balayage du module entier et des gabarits de planning-core impossible (contrôle propre au dépôt)"
else
  case_ctl "PTB-NOMS : aucune marque protégée dans les noms, aucun terme de découpage agile exclu (Q-11)" ctl_noms "$MOD"
  M="$(mkmut nagile)"; printf '\nLe découpage en epic puis en story est exclu.\n' >> "$M/agents/vf-product-pm.md"
  mutant_ptb NOMS-AGILE "KO-NOMS:agile" ctl_noms "$MOD" "$M"
  M="$(mkmut nmarque)"; subst "$M/agents/vf-product-pm.md" "name: vf-product-pm" "name: bmad-pm" "name:"
  mutant_ptb NOMS-MARQUE "KO-NOMS:marque dans un champ name:" ctl_noms "$MOD" "$M"
fi

# --- PTB-GABARITS / PTB-GSD / PTB-CATALOG — preuves croisées (gabarits <-> script, gabarit <-> moteur, filtre)
REQ_TPL="$REPO/planning-core/references/templates/product/REQUIREMENTS.template.md"
BRIEF_TPL="$MOD/references/BRIEF.template.md"
CHECK_PRD="$MOD/scripts/check-prd.sh"
CATALOG="$REPO/installer/scripts/build-module-catalog.sh"
GSDT="$HOME/.claude/gsd-core/bin/gsd-tools.cjs"

# fill_file <entrée> <sortie> : remplace chaque valeur entre crochets par une phrase réelle (la case
# à cocher [ ] / [x] est conservée) ; les lignes Acceptation et Priorité reçoivent une valeur valide.
fill_file() {
  awk '
  function fill(s, txt,    out, body) {
    out = ""
    while (match(s, /\[[^]]+\]/)) {
      body = substr(s, RSTART + 1, RLENGTH - 2)
      if (body == " " || body == "x") out = out substr(s, 1, RSTART - 1) substr(s, RSTART, RLENGTH)
      else out = out substr(s, 1, RSTART - 1) txt
      s = substr(s, RSTART + RLENGTH)
    }
    return out s
  }
  /^  Priorité : \[/ { print "  Priorité : must"; next }
  /^  Acceptation : \[/ { print "  Acceptation : un clic télécharge le fichier en moins de trois secondes"; next }
  { n++; print fill($0, "contenu réel numéro " n " renseigné pour ce produit") }' "$1" > "$TMPW" && cp "$TMPW" "$2"
}

# prd_rc <option> <fichier> : code de check-prd.sh (sortie jetée).
prd_rc() { bash "$CHECK_PRD" "$1" "$2" >/dev/null 2>&1; echo $?; }

# Contrôles sur un FICHIER gabarit (l'argument est le chemin du gabarit, pas une racine de module).
gabarit_ctl() { # <CAS> <option> <gabarit>
  local r=0 raw fil="$TMP/gab.$1.filled"
  raw="$(prd_rc "$2" "$3")"
  [ "$raw" = "1" ] || { echo "KO-GABARITS:$1-brut rc=$raw (attendu 1)"; r=1; }
  fill_file "$3" "$fil"
  raw="$(prd_rc "$2" "$fil")"
  [ "$raw" = "0" ] || { echo "KO-GABARITS:$1-rempli rc=$raw (attendu 0)"; r=1; }
  return $r
}
ctl_gab_req() { gabarit_ctl req --requirements "$1"; }
ctl_gab_brief() { gabarit_ctl brief --brief "$1"; }

ctl_gsd() { # <gabarit REQUIREMENTS>
  local lab="$TMP/lab.gsd" o r=0 n
  rm -rf "$lab"; mkdir -p "$lab/.planning"
  fill_file "$1" "$lab/.planning/REQUIREMENTS.md"; cp "$lab/.planning/REQUIREMENTS.md" "$TMP/lab.gsd.before"
  o="$(cd "$lab" && node "$GSDT" requirements mark-complete PRD-01 2>&1)"
  printf '%s' "$o" | jq -e '.updated == true and .write_set_complete == true' >/dev/null 2>&1 || { echo "KO-GSD:updated absent ou faux"; r=1; }
  has "$lab/.planning/REQUIREMENTS.md" '- [x] **PRD-01**' || { echo "KO-GSD:case non cochée"; r=1; }
  has "$lab/.planning/REQUIREMENTS.md" '| PRD-01 | — | Complete |' || { echo "KO-GSD:traçabilité non Complete"; r=1; }
  n="$(diff "$TMP/lab.gsd.before" "$lab/.planning/REQUIREMENTS.md" | awk '/^[<>]/ { n++ } END { print n + 0 }')"
  [ "$n" = "4" ] || { echo "KO-GSD:$n lignes changées (attendu 4 : la case et la traçabilité, Acceptation et Priorité intactes)"; r=1; }
  return $r
}

catalog_count() { # <module.json de fixture> [option...] : nombre de lignes product-team-bundle du catalogue de fixture
  local j="$1" fx="$TMP/fx.catalog"; shift
  rm -rf "$fx"; mkdir -p "$fx/product-team-bundle"; cp "$j" "$fx/product-team-bundle/module.json"
  env -u VF_ROLE VF_MODULES_ROOT="$fx" bash "$CATALOG" "$@" 2>/dev/null | awk -F'\t' '$1 == "product-team-bundle" { n++ } END { print n + 0 }'
}
ctl_catalog() { # <racine de module>
  local r=0 real n
  real="$(env -u VF_ROLE bash "$CATALOG" 2>/dev/null | awk 'END { print NR }')"
  [ "${real:-0}" -gt 0 ] || { echo "KO-CATALOG:catalogue réel vide (absence sans valeur)"; r=1; }
  n="$(env -u VF_ROLE bash "$CATALOG" 2>/dev/null | awk -F'\t' '$1 == "product-team-bundle" { n++ } END { print n + 0 }')"
  [ "$n" = "0" ] || { echo "KO-CATALOG:réel sans poste liste le bundle ($n)"; r=1; }
  n="$(env -u VF_ROLE bash "$CATALOG" --role product 2>/dev/null | awk -F'\t' '$1 == "product-team-bundle" { n++ } END { print n + 0 }')"
  [ "$n" = "0" ] || { echo "KO-CATALOG:réel au poste product liste le bundle ($n)"; r=1; }
  n="$(catalog_count "$1/module.json")"
  [ "$n" = "0" ] || { echo "KO-CATALOG:fixture proposable:false liste le bundle ($n)"; r=1; }
  return $r
}

if [ "$LAB" = 1 ]; then
  skip "PTB-GABARITS disposition lab : gabarits non posés à cet endroit (contrôle propre au dépôt)"
elif [ ! -f "$REQ_TPL" ] || [ ! -f "$BRIEF_TPL" ]; then
  ko "PTB-GABARITS gabarit introuvable ($REQ_TPL ou $BRIEF_TPL)"
else
  if run_ctl ctl_gab_req "$REQ_TPL"; then ok "PTB-GABARITS : REQUIREMENTS produit brut -> check-prd 1, rempli -> 0"; else ko "PTB-GABARITS requirements — $(brief)"; fi
  if run_ctl ctl_gab_brief "$BRIEF_TPL"; then ok "PTB-GABARITS : BRIEF brut -> check-prd 1, rempli -> 0"; else ko "PTB-GABARITS brief — $(brief)"; fi

  # Mutants sur des COPIES de gabarit (l'original est un fichier : diff -rq et le contrôle l'acceptent).
  fill_file "$REQ_TPL" "$TMP/g.req.prefilled"
  mutant_ptb GAB-REQ-DEJA-REMPLI "KO-GABARITS:req-brut rc=0" ctl_gab_req "$REQ_TPL" "$TMP/g.req.prefilled"
  cp "$REQ_TPL" "$TMP/g.req.sansaccept"; dropline "$TMP/g.req.sansaccept" "  Acceptation :"
  mutant_ptb GAB-REQ-SANS-ACCEPTATION "KO-GABARITS:req-rempli rc=1" ctl_gab_req "$REQ_TPL" "$TMP/g.req.sansaccept"
  fill_file "$BRIEF_TPL" "$TMP/g.brief.prefilled"
  mutant_ptb GAB-BRIEF-DEJA-REMPLI "KO-GABARITS:brief-brut rc=0" ctl_gab_brief "$BRIEF_TPL" "$TMP/g.brief.prefilled"
  cp "$BRIEF_TPL" "$TMP/g.brief.sansvaleur"; subst "$TMP/g.brief.sansvaleur" "## Valeur" "## Gain" "## "
  mutant_ptb GAB-BRIEF-RUBRIQUE-RENOMMEE "KO-GABARITS:brief-rempli rc=1" ctl_gab_brief "$BRIEF_TPL" "$TMP/g.brief.sansvaleur"

  # PTB-GSD : le gabarit rempli reste lisible par le moteur GSD (mark-complete).
  if [ ! -f "$GSDT" ] || ! command -v node >/dev/null 2>&1; then
    skip "PTB-GSD moteur GSD absent (gsd-tools.cjs ou node introuvable : la CI installe le moteur et y joue ce cas)"
  else
    if run_ctl ctl_gsd "$REQ_TPL"; then ok "PTB-GSD : mark-complete PRD-01 sur le gabarit rempli (case, traçabilité, 2 lignes changées)"; else ko "PTB-GSD — $(brief)"; fi
    cp "$REQ_TPL" "$TMP/g.req.idmal"; subst "$TMP/g.req.idmal" '**PRD-01**:' '**PRD01**:'
    mutant_ptb GSD-ID-ILLISIBLE "KO-GSD:updated absent ou faux" ctl_gsd "$REQ_TPL" "$TMP/g.req.idmal"
  fi
fi

# PTB-CATALOG : le filtre proposable:false, prouvé POSITIVEMENT (test-build-module-catalog.sh reste intact).
if [ ! -f "$CATALOG" ]; then
  skip "PTB-CATALOG build-module-catalog.sh introuvable (installer absent de cette disposition)"
else
  case_ctl "PTB-CATALOG : product-team-bundle absent du catalogue réel (sans poste, poste product) et d'une fixture proposable:false" ctl_catalog "$MOD"
  jq '.proposable = true' "$MOD/module.json" > "$TMPW" && cp "$TMPW" "$TMP/mj.true"
  n="$(catalog_count "$TMP/mj.true")"; np="$(catalog_count "$TMP/mj.true" --role product)"
  if [ "$n" = "1" ] && [ "$np" = "1" ]; then ok "PTB-CATALOG témoin positif : proposable:true -> la ligne apparaît (sans poste : $n, poste product : $np)"
  else ko "PTB-CATALOG témoin positif : proposable:true attendu 1 ligne (sans poste : $n, poste product : $np)"; fi
  M="$(mkmut catalog)"; cp "$TMP/mj.true" "$M/module.json"
  mutant_ptb CATALOG-PROPOSABLE-TRUE "KO-CATALOG:fixture proposable:false liste le bundle" ctl_catalog "$MOD" "$M"
fi

echo "== résultat : $pass OK / $fail KO / $skipped SKIP =="
[ "$fail" -eq 0 ]
