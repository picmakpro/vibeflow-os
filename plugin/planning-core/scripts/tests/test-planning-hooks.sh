#!/usr/bin/env bash
# test-planning-hooks.sh — Tests des hooks planning ADR-050 (amendée) :
#   planning-session-snapshot.sh (SessionStart, baseline de session)
#   guard-planning-updated.sh (Stop, blocage si planning pas à jour — attribution session)
#   planning-context.sh (SessionStart, digest index-first)
#   planning-task-context.sh (UserPromptSubmit, STATE du compartiment ciblé)
# Lancer avec BASH_BIN=/bin/bash pour valider la portabilité bash 3.2 macOS.
set -u

SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
BASH_BIN="${BASH_BIN:-bash}"
PC="$SCRIPTS/planning-context.sh"
PT="$SCRIPTS/planning-task-context.sh"
G="$SCRIPTS/guard-planning-updated.sh"
SNAPSHOT="$SCRIPTS/planning-session-snapshot.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
export TMPDIR="$WORK/tmp"   # isole snapshots + marqueurs du vrai /tmp
mkdir -p "$TMPDIR"

PASS=0; FAIL=0
ok()  { echo "  ✅ $1"; PASS=$((PASS+1)); }
ko()  { echo "  ❌ $1"; FAIL=$((FAIL+1)); }
new_session() { # $1 sid — écrit la baseline de la session $1 (depuis le répertoire courant)
  printf '{"session_id":"%s","source":"startup"}' "$1" | "$BASH_BIN" "$SNAPSHOT" >/dev/null 2>&1
}
guard_is() { # $1 sid $2 expected $3 label [$4 env]
  local code
  printf '{"session_id":"%s","stop_hook_active":false}' "$1" | env ${4:-} "$BASH_BIN" "$G" >/dev/null 2>&1; code=$?
  [ "$code" = "$2" ] && ok "$3 (exit=$code)" || ko "$3 (exit=$code, attendu $2)"
}
has()  { echo "$1" | grep -q "$2" && ok "$3" || ko "$3"; }
hasnt(){ echo "$1" | grep -q "$2" && ko "$3" || ok "$3"; }

echo "=== guard-planning-updated.sh (Stop) + planning-session-snapshot.sh (baseline) ==="
R="$WORK/repo"; mkdir -p "$R/.planning"; cd "$R"
git init -q; git config user.email t@t.co; git config user.name t
printf 'last_updated: 2026-07-16\n# STATE\n' > .planning/STATE.md
echo base > deliverable.md; git add -A; git commit -qm init

# G1 : livrable modifié pendant la session, planning intact → BLOQUE (une fois)
new_session s1
echo modif >> deliverable.md
guard_is s1 2 "G1 livrable changé pendant la session + planning non maj → BLOQUE"
# G2 : marqueur .blocked → plus JAMAIS de re-blocage cette session (même stop_hook_active=false)
guard_is s1 0 "G2 même session, tour suivant → un seul blocage par session"

# G3 : dirt PRÉEXISTANT (présent à l'ouverture de la nouvelle session) → non attribué → autorise
new_session s2
guard_is s2 0 "G3 dirt préexistant au démarrage → pas attribué à la session (faux positif v1)"
# G4 : le fichier déjà sale est ENCORE modifié pendant la session (hash blob change) → BLOQUE
echo re-modif >> deliverable.md
guard_is s2 2 "G4 fichier déjà sale mais contenu modifié pendant la session → BLOQUE (hash)"
git add -A; git commit -qm cleanup

# G5 (cas GSD/dev-orchestrator) : STATE.md maj + COMMITTÉ pendant la session, livrable sale → autorise
new_session s3
sleep 1   # une session réelle agit des secondes après son ouverture (granularité seconde)
echo maj >> .planning/STATE.md; git add .planning; git commit -qm "update planning"
echo brouillon > newdoc.md
guard_is s3 0 "G5 planning committé pendant la session → autorise (faux positif v1 n°1)"
rm -f newdoc.md

# G6 : livrable COMMITTÉ pendant la session sans planning (arbre propre) → BLOQUE (raté par v1)
new_session s4
sleep 1
echo feature >> deliverable.md; git add -A; git commit -qm "feature sans planning"
guard_is s4 2 "G6 livrable committé sans maj planning (arbre propre) → BLOQUE"
guard_is s4 0 "G6b puis plus de re-blocage cette session"

# G7 : anti-boucle stop_hook_active
new_session s5
echo x >> deliverable.md
code=$(printf '{"session_id":"s5","stop_hook_active": true}' | "$BASH_BIN" "$G" >/dev/null 2>&1; echo $?)
[ "$code" = "0" ] && ok "G7 anti-boucle (stop_hook_active) → autorise" || ko "G7 (exit=$code)"
# G8 : échappatoire marqueur (one-shot)
touch .planning/.session-noop
guard_is s5 0 "G8 échappatoire marqueur → autorise"
[ -f .planning/.session-noop ] && ko "G8b marqueur consommé" || ok "G8b marqueur consommé (one-shot)"
# G9/G10 : modes warn / off
guard_is s5 0 "G9 mode warn → autorise" "VF_PLANNING_STOP=warn"
guard_is s5 0 "G10 mode off → autorise" "VF_PLANNING_STOP=off"
guard_is s5 2 "G9b (contrôle) le même état bloque en mode block"
git add -A; git commit -qm g10

# G11 : session inconnue (pas de baseline) → fail-open
echo y >> deliverable.md
guard_is sid-inconnu 0 "G11 pas de baseline pour la session → fail-open"
git add -A; git commit -qm g11

# G12 : seulement .claude/ (méta) ou .DS_Store → autorise
new_session s6
mkdir -p .claude/memory; echo r >> .claude/memory/DECISIONS.md; echo j > .DS_Store
guard_is s6 0 "G12 seulement méta (.claude/, .DS_Store) → autorise"
rm -f .DS_Store; git add -A; git commit -qm g12

# G13 : rien changé → autorise
new_session s7
guard_is s7 0 "G13 rien changé pendant la session → autorise"

# G14 : baseline first-wins — un compact ré-émet SessionStart, la baseline d'origine est conservée
new_session s8
echo compacte >> deliverable.md
new_session s8   # ré-émission (compact) : ne doit PAS écraser la baseline
guard_is s8 2 "G14 re-SessionStart (compact) n'écrase pas la baseline → dirt toujours attribué"
git add -A; git commit -qm g14

# G15 : baseline périmée (>48h) → fail-open
new_session s9
SNAPF=$(ls "$TMPDIR"/vibeflow-planning-guard/*-s9.snap 2>/dev/null | head -1)
if [ -n "$SNAPF" ]; then
  old=$(( $(date +%s) - 200000 ))
  { echo "$old"; sed -n '2,$p' "$SNAPF"; } > "$SNAPF.new" && mv "$SNAPF.new" "$SNAPF"
  echo z >> deliverable.md
  guard_is s9 0 "G15 baseline périmée (>48h) → fail-open"
  git add -A; git commit -qm g15
else
  ko "G15 snapshot s9 introuvable"
fi

# G16 : .planning GITIGNORÉ + mis à jour pendant la session (signal mtime) → autorise
R2="$WORK/repo-gsd"; mkdir -p "$R2/.planning"; cd "$R2"
git init -q; git config user.email t@t.co; git config user.name t
echo ".planning/" > .gitignore
printf '# STATE\n' > .planning/STATE.md
echo base > doc.md; git add -A; git commit -qm init
new_session s10
sleep 1
echo maj >> .planning/STATE.md    # maj planning invisible de git (gitignoré)
echo modif >> doc.md
guard_is s10 0 "G16 .planning gitignoré mais touché pendant la session (mtime) → autorise"

# G17 : hors repo git / sans .planning → autorise
mkdir -p "$WORK/nogit/.planning"; cd "$WORK/nogit"; echo x > d.md
guard_is s11 0 "G17 hors repo git → autorise (pas de trappe)"
R3="$WORK/noplanning"; mkdir -p "$R3"; cd "$R3"
git init -q; git config user.email t@t.co; git config user.name t
echo x > d.md
new_session s12
guard_is s12 0 "G18 repo sans .planning → autorise"

# G19 : le message de blocage cite les livrables attribués
cd "$R"
new_session s13
echo cite-moi > fichier-cite.md
ERR=$(printf '{"session_id":"s13","stop_hook_active":false}' | "$BASH_BIN" "$G" 2>&1 >/dev/null || true)
has "$ERR" "fichier-cite.md" "G19 le motif de blocage cite le livrable attribué"
has "$ERR" "ne bloquera plus cette session" "G19b le motif annonce le blocage one-shot"
git add -A; git commit -qm g19

echo "=== planning-context.sh (SessionStart) ==="
M="$WORK/mono"; mkdir -p "$M/.planning"; cd "$M"
printf 'last_updated: 2026-07-16\n# STATE\n## En cours\n- tache A\n' > .planning/STATE.md
out=$("$BASH_BIN" "$PC"); has "$out" "extrait borné" "C1 mono : header extrait STATE"; has "$out" "tache A" "C1 mono : contenu injecté"
MU="$WORK/multi"; mkdir -p "$MU/.planning" "$MU/projects/acquisition/.planning"; cd "$MU"
printf '# INDEX\n| acquisition | actif |\n' > .planning/INDEX.md
printf 'last_updated: 2026-07-16\n# acq\n- séquence CTO\n' > projects/acquisition/.planning/STATE.md
out=$("$BASH_BIN" "$PC"); has "$out" "compartiments" "C2 multi : header INDEX"; has "$out" "acquisition" "C2 multi : INDEX injecté"
hasnt "$out" "séquence CTO" "C2 multi : ne charge PAS les STATE des compartiments (anti-saturation)"
N="$WORK/none"; mkdir -p "$N"; cd "$N"
out=$("$BASH_BIN" "$PC"); [ -z "$out" ] && ok "C3 pas de .planning → silencieux" || ko "C3 devrait être vide"

echo "=== planning-task-context.sh (UserPromptSubmit) ==="
cd "$MU"
out=$(printf '{"prompt":"aide sur la séquence acquisition"}' | "$BASH_BIN" "$PT")
has "$out" "acquisition" "T1 compartiment ciblé détecté"; has "$out" "séquence CTO" "T1 STATE du compartiment injecté"
out=$(printf '{"prompt":"quelle heure"}' | "$BASH_BIN" "$PT"); [ -z "$out" ] && ok "T2 aucun match → silencieux" || ko "T2 devrait être vide"
cd "$M"; out=$(printf '{"prompt":"tache A"}' | "$BASH_BIN" "$PT"); [ -z "$out" ] && ok "T3 lab mono → silencieux" || ko "T3 devrait être vide"

echo "=== ADR-055 : --defer-to-gsd met fin à la double injection SessionStart ==="
DETECT_TMP=$(mktemp -d)
FAKE_GSD2="$DETECT_TMP/gsd-home"; mkdir -p "$FAKE_GSD2"

mk_gsd_lab() { # <dir> — lab mono-projet dont le planning appartient à GSD
  mkdir -p "$1/.planning"
  printf -- '---\ngsd_state_version: 1.0\nlast_updated: "%s"\n---\n\n# État\n' "$(date +%Y-%m-%d)" \
    > "$1/.planning/STATE.md"
}

# Cas A : check-planning-state --defer-to-gsd sur un lab sous GSD → silencieux, exit 0.
LAB="$DETECT_TMP/a"; mk_gsd_lab "$LAB"
out=$( cd "$LAB" && GSD_HOME="$FAKE_GSD2" "$BASH_BIN" "$SCRIPTS/check-planning-state.sh" --defer-to-gsd 2>&1 )
code=$?
if [ "$code" -eq 0 ] && [ -z "$out" ]; then
  ok "D-A check-planning-state se tait sous moteur GSD"
else
  ko "D-A check-planning-state devait se taire — exit $code, sortie: '$out'"
fi

# Cas B : SANS le flag, le comportement est inchangé (il parle).
out=$( cd "$LAB" && GSD_HOME="$FAKE_GSD2" "$BASH_BIN" "$SCRIPTS/check-planning-state.sh" 2>&1 )
if [ -n "$out" ]; then ok "D-B comportement par défaut inchangé"
else ko "D-B sans flag, le script devait parler"; fi

# Cas C : planning-context --defer-to-gsd sur un lab MONO sous GSD → aucune injection.
out=$( cd "$LAB" && GSD_HOME="$FAKE_GSD2" "$BASH_BIN" "$PC" --defer-to-gsd 2>&1 )
if [ -z "$out" ]; then ok "D-C planning-context n'injecte rien en mono-projet GSD"
else ko "D-C planning-context devait rester muet — sortie: '$out'"; fi

# Cas D : ALTITUDE LAB — avec un INDEX.md, l'injection a lieu MALGRÉ le flag.
LAB="$DETECT_TMP/d"; mk_gsd_lab "$LAB"
printf '# Index du lab\n\n| Compartiment | Statut |\n|---|---|\n| client-a | actif |\n' \
  > "$LAB/.planning/INDEX.md"
out=$( cd "$LAB" && GSD_HOME="$FAKE_GSD2" "$BASH_BIN" "$PC" --defer-to-gsd 2>&1 )
if echo "$out" | grep -q "client-a"; then
  ok "D-D altitude lab : l'INDEX est injecté même sous GSD"
else
  ko "D-D l'INDEX du lab devait être injecté — sortie: '$out'"
fi

# Cas E : lab NON-dev (pas de moteur GSD) → le flag ne change rien, ça parle.
LAB="$DETECT_TMP/e"; mkdir -p "$LAB/.planning"
printf -- '---\nplanning_version: 1.0\nlast_updated: "%s"\n---\n\n# État\n' "$(date +%Y-%m-%d)" \
  > "$LAB/.planning/STATE.md"
out=$( cd "$LAB" && GSD_HOME="$FAKE_GSD2" "$BASH_BIN" "$PC" --defer-to-gsd 2>&1 )
if [ -n "$out" ]; then ok "D-E lab non-dev : injection préservée"
else ko "D-E lab non-dev, l'injection devait avoir lieu"; fi

rm -rf "$DETECT_TMP"

echo ""
echo "== BILAN : $PASS PASS / $FAIL FAIL =="
[ "$FAIL" -eq 0 ]
