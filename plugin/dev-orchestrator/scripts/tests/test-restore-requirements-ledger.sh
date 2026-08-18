#!/usr/bin/env bash
# test-restore-requirements-ledger.sh — Suite de vérification de restore-requirements-ledger.sh
# (LEDG-01, plan 18-02). Harness sur le modèle de test-check-doc-drift.sh : mktemp -d + trap, une
# fixture par cas, capture stdout/stderr/code séparément, jamais le .planning/ réel de ce dépôt.
#
# Trois destins couverts (D-18-11, A-18-06) : garantie ([x] + Complete/Livré v, sans caduc) → écrite
# sous ## Garanties ; voyage (case non cochée, sans caduc) → famille d'origine + carried-from: ;
# caduque (jeton caduc sur corps OU traçabilité, précédence absolue) → jamais écrite, reste dans
# l'archive seule. Un 4e cas — forme non reconnue — est un repli conservateur (T-18-09) : jamais un
# crash, toujours signalé sur stderr avec son ID, jamais écrit.
#
# Rejeu RÉEL (dernier bloc) : sur une COPIE jetable de l'archive réelle de ce dépôt
# (agentique-v1.0-REQUIREMENTS.md), jamais une simple fixture calibrée dessus — ROADMAP.md exige que
# LEDG-01 soit rejoué sur la clôture RÉELLE. Les comptes de référence sont RE-DÉRIVÉS par la suite
# elle-même (oracle indépendant en awk/grep, mêmes motifs que vf_ledger_classify), jamais codés en
# dur — un nombre figé périmerait si l'archive change.

set -uo pipefail

SCRIPTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$SCRIPTS_DIR/restore-requirements-ledger.sh"
PRIMITIVE="$SCRIPTS_DIR/requirements-survival-detect.sh"
REPO_ROOT="$(cd "$SCRIPTS_DIR/../../.." && pwd)"
REAL_ARCHIVE="$REPO_ROOT/.planning/milestones/agentique-v1.0-REQUIREMENTS.md"

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() {
  echo "  ✗ $1"
  echo "    assertion : $1"
  echo "    attendu   : $2"
  echo "    obtenu    : $3"
  FAIL=$((FAIL+1))
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mk_root() { local d="$TMP/$1"; mkdir -p "$d/.planning" || { echo "  ✗ FIXTURE — mkdir $d/.planning" >&2; exit 1; }; printf '%s' "$d"; }
CLOSED_H2='## ✅ demo-v1 — Un jalon clos (fixture de test)'
w_milestones() { printf '# Milestones\n\n%s\n' "$2" > "$1/.planning/MILESTONES.md"; }
w_archive() { mkdir -p "$1/.planning/milestones"; printf '%s' "$3" > "$1/.planning/milestones/${2}-REQUIREMENTS.md"; }
w_live() { printf '%s' "$2" > "$1/.planning/REQUIREMENTS.md"; }
# garanties_section <file> — imprime UNIQUEMENT le contenu sous ## Garanties, borné au premier
# titre de N'IMPORTE QUEL niveau ≥2 (## OU ###) qui suit — jamais seulement ##, sinon les blocs de
# famille (### <famille>, voyage) qui suivent SANS H2 intercalé se retrouvent inclus à tort.
garanties_section() { awk '/^## Garanties/{f=1;next} /^#{2,6} /{f=0} f{print}' "$1"; }

# Archive de démonstration, calibrée sur le VOCABULAIRE RÉEL de l'archive agentique-v1.0 (mesuré le
# 2026-08-18 : aucun `Pending`, très majoritairement `Done — <détail>`, `Planned — plan NN`, ou
# prose libre) — jamais le vocabulaire `Complete`/`Pending` du texte initial du plan, périmé sur
# mesure (voir la correction A-18-06 du 2026-08-18 dans 18-02-PLAN.md). La case à cocher est le
# signal PRIMAIRE (nouvelle précédence) : AAAA-01 (coché, trace "Done — …"), BBBB-01 (non coché,
# trace "Planned — …"), VERB-02 (non coché [~], caduc SEULEMENT sur la traçabilité — fait réel),
# NOTR-01 (coché, SANS aucune ligne de traçabilité — doit quand même devenir garantie, zéro perte),
# PROSE-01 (coché, trace en prose libre, forme réelle "Spike done — GO"), CCCC-99 (case NI x NI
# vide NI ~ — seule vraie forme non reconnue, code 3).
DEMO_ARCHIVE=$'# Requirements: Demo\n\n**Defined:** 2026-01-01\n\n## v1 Requirements\n\n### Famille A\n\n- [x] **AAAA-01**: item livre\n- [ ] **BBBB-01**: item en attente\n- [~] **VERB-02**: item caduc via tracabilite seule\n- [x] **NOTR-01**: sans tracabilite correspondante\n- [x] **PROSE-01**: statut en prose libre\n- [Q] **CCCC-99**: forme de case non reconnue\n\n## Traceability\n\n| Requirement | Phase | Status |\n|---|---|---|\n| AAAA-01 | Phase 1 | Done - plans 24-01 et 24-12 |\n| BBBB-01 | Phase 1 | Planned - plan 29-02 |\n| VERB-02 | Phase 1 | Livre - **caduc depuis v9** |\n| PROSE-01 | Phase 9 | Spike done - GO (round-trip verifie) |\n| CCCC-99 | Phase 1 | Done |\n'

echo "== test-restore-requirements-ledger =="

# === Cas 1 — ledger vivant présent : rien à reconstituer, exit 1, stdout vide, fichier intact =====
D="$(mk_root c1)"
w_milestones "$D" "$CLOSED_H2"
w_live "$D" $'# Requirements\n- [x] **X-01**: rien\n'
before="$(cat "$D/.planning/REQUIREMENTS.md")"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
after="$(cat "$D/.planning/REQUIREMENTS.md")"
if [ "$rc" -eq 1 ] && [ -z "$out" ] && [ "$before" = "$after" ]; then ok "1 ledger vivant présent → rien à reconstituer, exit 1, fichier intact"; else ko "1 ledger vivant présent → rien à reconstituer, exit 1, fichier intact" "rc=1 out=[] fichier intact" "rc=$rc out=[$out]"; fi

# === Cas 2 — aucun jalon clos : exit 1 =============================================================
D="$(mk_root c2)"
w_milestones "$D" "## en cours — Jalon pas fini"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 1 ] && [ -z "$out" ]; then ok "2 aucun jalon clos → exit 1"; else ko "2 aucun jalon clos → exit 1" "rc=1 out=[]" "rc=$rc out=[$out]"; fi

# === Cas 2b — jalon clos sans archive disponible : exit 1 ===========================================
D="$(mk_root c2b)"
w_milestones "$D" "$CLOSED_H2"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 1 ] && [ -z "$out" ]; then ok "2b jalon clos sans archive → exit 1"; else ko "2b jalon clos sans archive → exit 1" "rc=1 out=[]" "rc=$rc out=[$out]"; fi

# === Cas 3 — reconstitution nominale, mode diff (défaut) : exit 0, AUCUNE écriture =================
D="$(mk_root c3)"
w_milestones "$D" "$CLOSED_H2"
w_archive "$D" "demo-v1" "$DEMO_ARCHIVE"
before="$(find "$D" | LC_ALL=C sort)"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
after="$(find "$D" | LC_ALL=C sort)"
has_g=0; case "$out" in *"## Garanties"*) has_g=1 ;; esac
has_c=0; case "$out" in *"carried-from:"*) has_c=1 ;; esac
has_leak=0; case "$out" in *"VERB-02"*) has_leak=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$before" = "$after" ] && [ "$has_g" -eq 1 ] && [ "$has_c" -eq 1 ] && [ "$has_leak" -eq 0 ]; then ok "3 mode diff — exit 0, aucune écriture, ## Garanties + carried-from:, jamais l'item caduc"; else ko "3 mode diff — exit 0, aucune écriture, ## Garanties + carried-from:, jamais l'item caduc" "rc=0 fs inchangé, Garanties+carried-from présents, VERB-02 absent" "rc=$rc fs_egal=$([ "$before" = "$after" ] && echo oui || echo NON) g=$has_g c=$has_c leak=$has_leak"; fi

# === Cas 4 — reconstitution nominale, mode --write : fichier écrit, sections validées ==============
D="$(mk_root c4)"
w_milestones "$D" "$CLOSED_H2"
w_archive "$D" "demo-v1" "$DEMO_ARCHIVE"
out="$(bash "$SCRIPT" --path "$D" --write 2>/dev/null)"; rc=$?
F="$D/.planning/REQUIREMENTS.md"
ok_write=0
if [ "$rc" -eq 0 ] && [ -f "$F" ]; then
  g_has_aaaa=0; garanties_section "$F" | grep -q 'AAAA-01' && g_has_aaaa=1
  v_has_bbbb=0; grep -q 'BBBB-01.*carried-from: demo-v1' "$F" && v_has_bbbb=1
  no_verb02=1; grep -q 'VERB-02' "$F" && no_verb02=0
  [ "$g_has_aaaa" -eq 1 ] && [ "$v_has_bbbb" -eq 1 ] && [ "$no_verb02" -eq 1 ] && ok_write=1
fi
if [ "$ok_write" -eq 1 ]; then ok "4 mode --write — AAAA-01 sous Garanties, BBBB-01 avec carried-from:, VERB-02 absent"; else ko "4 mode --write — AAAA-01 sous Garanties, BBBB-01 avec carried-from:, VERB-02 absent" "rc=0, sections conformes" "rc=$rc contenu=[$(cat "$F" 2>/dev/null)]"; fi

# === Cas 5 — la table Traceability écrite ne porte QUE l'ID Pending ===============================
trace_ok=0
if [ -f "$F" ]; then
  awk '/^## Traceability/{f=1;next} f&&/^\|/{print}' "$F" > "$TMP/trace-only.txt"
  grep -q 'BBBB-01' "$TMP/trace-only.txt" && ! grep -q 'AAAA-01' "$TMP/trace-only.txt" && ! grep -q 'VERB-02' "$TMP/trace-only.txt" && trace_ok=1
fi
if [ "$trace_ok" -eq 1 ]; then ok "5 table Traceability écrite ne porte que l'ID Pending (BBBB-01)"; else ko "5 table Traceability écrite ne porte que l'ID Pending (BBBB-01)" "seul BBBB-01 dans la table" "$(cat "$TMP/trace-only.txt" 2>/dev/null)"; fi

# === Cas 6 (T-18-09) — forme non reconnue (code 3, case NI x NI vide NI ~) : continue, ID sur
# stderr, absent du fichier. C'est la SEULE forme qui doit encore tomber en code 3 (correction du
# 2026-08-18 : l'absence de traçabilité ou un statut en texte libre ne suffisent plus).
D="$(mk_root c6)"
w_milestones "$D" "$CLOSED_H2"
w_archive "$D" "demo-v1" "$DEMO_ARCHIVE"
errfile="$TMP/c6.err"
bash "$SCRIPT" --path "$D" --write >/dev/null 2>"$errfile"; rc=$?
has_stderr=0; grep -q 'CCCC-99' "$errfile" && has_stderr=1
not_written=1; grep -q 'CCCC-99' "$D/.planning/REQUIREMENTS.md" && not_written=0
if [ "$rc" -eq 0 ] && [ "$has_stderr" -eq 1 ] && [ "$not_written" -eq 1 ]; then ok "6 (T-18-09) forme non reconnue (case ni x/vide/~) → continue (exit 0), ID sur stderr, absent du fichier écrit"; else ko "6 (T-18-09) forme non reconnue (case ni x/vide/~) → continue (exit 0), ID sur stderr, absent du fichier écrit" "rc=0, CCCC-99 sur stderr, absent du fichier" "rc=$rc stderr=[$(cat "$errfile")]"; fi

# === Cas 6b — PRÉSENCE ET DESTINATION du vocabulaire réel (route 1, correction finale du
# 2026-08-18) : `Done` reconnu comme livré (AAAA-01, PROSE-01 via "Spike done"), `Planned` et
# l'ABSENCE de traçabilité restent VOYAGE par défaut (BBBB-01, NOTR-01) — jamais garantie hallucinée
# faute de confirmation. Aucun des quatre n'est perdu (présence), et chacun est dans la BONNE
# section (destination) — c'est le test qui aurait attrapé la route « case seule » (134 IDs cochés
# dont 19 `Planned` classés garantie à tort, zéro voyage).
D="$(mk_root c6b)"
w_milestones "$D" "$CLOSED_H2"
w_archive "$D" "demo-v1" "$DEMO_ARCHIVE"
bash "$SCRIPT" --path "$D" --write >/dev/null 2>/dev/null
WF6B="$D/.planning/REQUIREMENTS.md"
garanties_section "$WF6B" > "$TMP/c6b-garanties.txt"
aaaa_ok=0; grep -q 'AAAA-01' "$TMP/c6b-garanties.txt" && aaaa_ok=1
bbbb_ok=0; grep -q 'BBBB-01.*carried-from: demo-v1' "$WF6B" && ! grep -q 'BBBB-01' "$TMP/c6b-garanties.txt" && bbbb_ok=1
notr_ok=0; grep -q 'NOTR-01.*carried-from: demo-v1' "$WF6B" && ! grep -q 'NOTR-01' "$TMP/c6b-garanties.txt" && notr_ok=1
prose_ok=0; grep -q 'PROSE-01' "$TMP/c6b-garanties.txt" && prose_ok=1
if [ "$aaaa_ok" -eq 1 ] && [ "$bbbb_ok" -eq 1 ] && [ "$notr_ok" -eq 1 ] && [ "$prose_ok" -eq 1 ]; then
  ok "6b présence ET destination — Done→Garanties (AAAA-01, PROSE-01), Planned ET sans-traçabilité→voyage jamais garantie (BBBB-01, NOTR-01)"
else
  ko "6b présence ET destination — Done→Garanties (AAAA-01, PROSE-01), Planned ET sans-traçabilité→voyage jamais garantie (BBBB-01, NOTR-01)" "aaaa+prose en Garanties, bbbb+notr en voyage AVEC carried-from, JAMAIS en Garanties" "aaaa=$aaaa_ok bbbb=$bbbb_ok notr=$notr_ok prose=$prose_ok"
fi

# Cas 6c retiré (redondant avec 14a, qui vérifie exactement la même propriété — présence de chaque
# ID non-caduc, écart nommé ID par ID — sur l'archive RÉELLE plutôt que sur la fixture DEMO_ARCHIVE).

# === Cas 7 — item VERB-02-like (caduc via traçabilité seule) : archive source jamais modifiée ======
D="$(mk_root c7)"
w_milestones "$D" "$CLOSED_H2"
w_archive "$D" "demo-v1" "$DEMO_ARCHIVE"
ARCH="$D/.planning/milestones/demo-v1-REQUIREMENTS.md"
before_arch="$(cat "$ARCH")"
bash "$SCRIPT" --path "$D" --write >/dev/null 2>&1
after_arch="$(cat "$ARCH")"
if [ "$before_arch" = "$after_arch" ]; then ok "7 archive source jamais modifiée (lecture seule stricte, T-18-08)"; else ko "7 archive source jamais modifiée (lecture seule stricte, T-18-08)" "archive identique avant/après" "archive modifiée"; fi

# === Cas 8 — écriture atomique : aucun fichier résiduel après --write ==============================
D="$(mk_root c8)"
w_milestones "$D" "$CLOSED_H2"
w_archive "$D" "demo-v1" "$DEMO_ARCHIVE"
bash "$SCRIPT" --path "$D" --write >/dev/null 2>&1
residual="$(find "$D/.planning" -maxdepth 1 -name '.REQUIREMENTS.md.*' 2>/dev/null)"
if [ -z "$residual" ]; then ok "8 écriture atomique — aucun fichier temporaire résiduel après --write"; else ko "8 écriture atomique — aucun fichier temporaire résiduel après --write" "aucun résidu" "résidu=[$residual]"; fi

# === Cas 9 — déterminisme : deux exécutions consécutives en mode diff, même stdout =================
D="$(mk_root c9)"
w_milestones "$D" "$CLOSED_H2"
w_archive "$D" "demo-v1" "$DEMO_ARCHIVE"
out1="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"
out2="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"
if [ "$out1" = "$out2" ]; then ok "9 déterminisme — deux exécutions consécutives en mode diff, même stdout"; else ko "9 déterminisme — deux exécutions consécutives en mode diff, même stdout" "out1==out2" "out1=[$out1] out2=[$out2]"; fi

# === Cas 10 — parité d'interface ====================================================================
bash "$SCRIPT" --path >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 64 ]; then ok "10a --path sans valeur → 64"; else ko "10a --path sans valeur → 64" "rc=64" "rc=$rc"; fi
bash "$SCRIPT" --nope >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 64 ]; then ok "10b argument inconnu → 64"; else ko "10b argument inconnu → 64" "rc=64" "rc=$rc"; fi
out="$(bash "$SCRIPT" --help 2>/dev/null)"; rc=$?
if [ "$rc" -eq 0 ] && [ -n "$out" ]; then ok "10c --help → 0, sortie non vide"; else ko "10c --help → 0, sortie non vide" "rc=0 out non vide" "rc=$rc out=[$out]"; fi

# === Cas 11 — bash -n passe =========================================================================
if bash -n "$SCRIPT" 2>/dev/null; then ok "11 bash -n passe sur restore-requirements-ledger.sh"; else ko "11 bash -n passe sur restore-requirements-ledger.sh" "OK" "échec"; fi

# ==================================================================================================
# Garde de non-écrasement (défense en profondeur au-delà de vf_ledger_state) — --write refuse
# d'écrire si $LIVE existe, --overwrite-live autorise avec sauvegarde .bak-<jalon> tracée. Empreinte
# md5/checksum du fichier vivant, jamais une inspection visuelle (exigence explicite).
# ==================================================================================================
checksum() { if command -v md5 >/dev/null 2>&1; then md5 -q "$1"; else md5sum "$1" | awk '{print $1}'; fi; }

# --- Cas 15 — --write avec $LIVE présent, SANS --overwrite-live : refus, code non-zéro, $LIVE
# prouvé inchangé par empreinte (jamais une inspection visuelle du contenu).
D="$(mk_root c15)"
w_milestones "$D" "$CLOSED_H2"
w_archive "$D" "demo-v1" "$DEMO_ARCHIVE"
w_live "$D" $'# Requirements: Live\n- [x] **PRECIEUX-01**: exigence vivante jamais archivee\n'
LIVE_F="$D/.planning/REQUIREMENTS.md"
sum_before="$(checksum "$LIVE_F")"
out="$(bash "$SCRIPT" --path "$D" --write 2>/dev/null)"; rc=$?
sum_after="$(checksum "$LIVE_F")"
if [ "$rc" -ne 0 ] && [ "$sum_before" = "$sum_after" ]; then ok "15 --write avec \$LIVE présent, sans --overwrite-live → refus (code $rc, non nul), \$LIVE inchangé par empreinte"; else ko "15 --write avec \$LIVE présent, sans --overwrite-live → refus (code $rc, non nul), \$LIVE inchangé par empreinte" "code non nul, empreinte identique ($sum_before)" "rc=$rc empreinte_apres=$sum_after"; fi

# --- Cas 16 — --write --overwrite-live avec $LIVE présent : écrit, ET la sauvegarde .bak-<jalon>
# existe avec le CONTENU de l'ancien vivant (vérifié, pas seulement son existence).
D="$(mk_root c16)"
w_milestones "$D" "$CLOSED_H2"
w_archive "$D" "demo-v1" "$DEMO_ARCHIVE"
OLD_LIVE_CONTENT=$'# Requirements: Live\n- [x] **PRECIEUX-01**: exigence vivante jamais archivee\n'
w_live "$D" "$OLD_LIVE_CONTENT"
LIVE_F="$D/.planning/REQUIREMENTS.md"
BACKUP_F="${LIVE_F}.bak-demo-v1"
# Référence sur DISQUE, comparée octet à octet (cmp) — jamais `$(cat …)` contre une chaîne bash :
# la substitution de commande retire les retours à la ligne finaux, cassant toute comparaison
# stricte contre un contenu qui en porte un (piège constaté en cours de rédaction).
printf '%s' "$OLD_LIVE_CONTENT" > "$TMP/c16-reference.txt"
out="$(bash "$SCRIPT" --path "$D" --write --overwrite-live 2>/dev/null)"; rc=$?
backup_ok=0
if [ -f "$BACKUP_F" ] && cmp -s "$BACKUP_F" "$TMP/c16-reference.txt"; then backup_ok=1; fi
written_ok=0
grep -q 'AAAA-01' "$LIVE_F" 2>/dev/null && written_ok=1
if [ "$rc" -eq 0 ] && [ "$backup_ok" -eq 1 ] && [ "$written_ok" -eq 1 ]; then ok "16 --write --overwrite-live avec \$LIVE présent → écrit, sauvegarde .bak-demo-v1 dont le CONTENU est l'ancien vivant"; else ko "16 --write --overwrite-live avec \$LIVE présent → écrit, sauvegarde .bak-demo-v1 dont le CONTENU est l'ancien vivant" "rc=0, backup_content==ancien vivant, nouveau contenu écrit" "rc=$rc backup_ok=$backup_ok written_ok=$written_ok"; fi

# --- Cas 17 — --write avec $LIVE ABSENT : chemin nominal inchangé (non-régression) -----------------
D="$(mk_root c17)"
w_milestones "$D" "$CLOSED_H2"
w_archive "$D" "demo-v1" "$DEMO_ARCHIVE"
out="$(bash "$SCRIPT" --path "$D" --write 2>/dev/null)"; rc=$?
if [ "$rc" -eq 0 ] && [ -f "$D/.planning/REQUIREMENTS.md" ]; then ok "17 --write avec \$LIVE absent → chemin nominal inchangé (non-régression)"; else ko "17 --write avec \$LIVE absent → chemin nominal inchangé (non-régression)" "rc=0, fichier écrit" "rc=$rc"; fi

# --- MUTATION garde — retirer le refus fait ROUGIR le cas 15 (refus), en laissant VERTS les cas
# 16 (override) et 17 (LIVE absent). Mutant sous mktemp -d, jamais le fichier vivant.
# Deux couches défendent le refus (défense en profondeur) : le early-exit qui suit vf_ledger_state
# (OVERRIDE_ARCHIVE n'est peuplé QUE si $OVERWRITE_LIVE vaut 1) ET le garde-fou redondant juste avant
# l'écriture. La mutation retire la condition $OVERWRITE_LIVE aux DEUX endroits — c'est le seul
# moyen de simuler le défaut visé de bout en bout (une seule couche mutée resterait protégée par
# l'autre, ce qui ne prouverait rien sur la discriminance globale).
MUT_DIR="$TMP/mut-guard"; mkdir -p "$MUT_DIR"
sed -e 's/if \[ "\$state_rc" -ne 0 \] && \[ "\$OVERWRITE_LIVE" -eq 1 \] \\/if [ "$state_rc" -ne 0 ] \\/' \
    -e 's/if \[ -f "\$LIVE" \] && \[ "\$OVERWRITE_LIVE" -ne 1 \]; then/if false; then/' \
    "$SCRIPT" > "$MUT_DIR/restore-requirements-ledger.sh"
cp "$SCRIPTS_DIR/requirements-survival-detect.sh" "$MUT_DIR/"
chmod +x "$MUT_DIR"/*.sh

D="$(mk_root cm)"
w_milestones "$D" "$CLOSED_H2"
w_archive "$D" "demo-v1" "$DEMO_ARCHIVE"
w_live "$D" "$OLD_LIVE_CONTENT"
LIVE_F="$D/.planning/REQUIREMENTS.md"
sum_before="$(checksum "$LIVE_F")"
bash "$MUT_DIR/restore-requirements-ledger.sh" --path "$D" --write >/dev/null 2>&1; mut_rc=$?
sum_after="$(checksum "$LIVE_F")"
if [ "$mut_rc" -eq 0 ] && [ "$sum_before" != "$sum_after" ]; then
  ok "MUTATION garde (refus retiré) rougit le cas 15 comme attendu : code(attendu non nul, obtenu 0) fichier(attendu inchangé, obtenu écrasé)"
else
  ko "MUTATION garde — N'A PAS ROUGI" "le cas 15 (refus) change de comportement sous la mutation (écrit malgré \$LIVE présent)" "mut_rc=$mut_rc empreinte_identique=$([ "$sum_before" = "$sum_after" ] && echo oui || echo non)"
fi
# Contrôle de discriminance : le cas 17 (LIVE absent) reste VERT sous cette mutation.
D="$(mk_root cm-controle)"
w_milestones "$D" "$CLOSED_H2"
w_archive "$D" "demo-v1" "$DEMO_ARCHIVE"
bash "$MUT_DIR/restore-requirements-ledger.sh" --path "$D" --write >/dev/null 2>&1; ctrl_rc=$?
if [ "$ctrl_rc" -eq 0 ] && [ -f "$D/.planning/REQUIREMENTS.md" ]; then ok "MUTATION garde — le cas 17 (\$LIVE absent) reste VERT sous cette mutation (discriminance)"; else ko "MUTATION garde — discriminance rompue, le cas 17 est affecté aussi" "cas 17 inchangé" "rc=$ctrl_rc"; fi

# ==================================================================================================
# Rejeu RÉEL — copie jetable de l'archive réelle agentique-v1.0, jamais une fixture calibrée dessus.
# Oracle indépendant (awk/grep) recalculé PAR LA SUITE, jamais un nombre codé en dur.
# ==================================================================================================
echo "== Rejeu réel sur agentique-v1.0-REQUIREMENTS.md =="

if [ ! -f "$REAL_ARCHIVE" ]; then
  ko "12 archive réelle agentique-v1.0-REQUIREMENTS.md introuvable — rejeu impossible" "fichier présent" "absent : $REAL_ARCHIVE"
else
  D="$(mk_root c12)"
  w_milestones "$D" '## ✅ agentique-v1.0 — Durcissement du moteur d'"'"'équipes agentique (clos 2026-08-15)'
  mkdir -p "$D/.planning/milestones"
  cp "$REAL_ARCHIVE" "$D/.planning/milestones/agentique-v1.0-REQUIREMENTS.md"
  real_before="$(cat "$REAL_ARCHIVE")"

  # Oracle indépendant : mêmes motifs (caduc / complete|done insensible à la casse / Livré v) que
  # vf_ledger_classify (route 1, correction finale du 2026-08-18), calculés ici en awk sur l'archive
  # copiée — jamais une resimulation de la fonction, un comptage redondant. DEUX passes (idiome
  # FNR==NR, archive passée deux fois) : la table de traçabilité vit APRÈS le corps, une passe
  # unique ne peut pas résoudre trace[id] pour un ID rencontré avant elle.
  ORACLE_ARCHIVE_IDS="$(awk '
    /^## Traceability[ \t]*$/ { exit }
    match($0, /^- \[.\] \*\*[A-Z]+-[0-9]+\*\*/) { line=$0; if (match(line,/[A-Z]+-[0-9]+/)) print substr(line,RSTART,RLENGTH) }
  ' "$D/.planning/milestones/agentique-v1.0-REQUIREMENTS.md" | sort -u)"
  ORACLE_ARCHIVE_TOTAL="$(printf '%s\n' "$ORACLE_ARCHIVE_IDS" | grep -c .)"
  ORACLE_CADUC_IDS="$(awk '
    FNR == NR {
      if ($0 ~ /^## Traceability[ \t]*$/) { intrace = 1; next }
      if (intrace == 1 && match($0, /^\| [A-Z]+-[0-9]+ \|/)) { line=$0; if (match(line,/[A-Z]+-[0-9]+/)) trace[substr(line,RSTART,RLENGTH)]=line }
      next
    }
    /^## Traceability[ \t]*$/ { exit }
    match($0, /^- \[.\] \*\*[A-Z]+-[0-9]+\*\*/) {
      line=$0
      if (match(line,/[A-Z]+-[0-9]+/)) {
        id=substr(line,RSTART,RLENGTH); tl=(id in trace)?trace[id]:""
        if (tolower(line "\n" tl) ~ /caduc/) print id
      }
    }
  ' "$D/.planning/milestones/agentique-v1.0-REQUIREMENTS.md" "$D/.planning/milestones/agentique-v1.0-REQUIREMENTS.md" | sort -u)"
  ORACLE_CADUC_N="$(printf '%s\n' "$ORACLE_CADUC_IDS" | grep -c .)"
  # IDs "Planned" (mesuré : grep -c 'Planned' sur la table de traçabilité de l'archive réelle) —
  # référence de DESTINATION : aucun ne doit jamais atterrir sous ## Garanties.
  ORACLE_PLANNED_IDS="$(awk '/^## Traceability/{f=1;next} f&&/Planned/{match($0,/[A-Z]+-[0-9]+/); if(RSTART) print substr($0,RSTART,RLENGTH)}' "$D/.planning/milestones/agentique-v1.0-REQUIREMENTS.md" | sort -u)"

  diff_out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; diff_rc=$?
  no_verb02=1; printf '%s' "$diff_out" | grep -q 'VERB-02' && no_verb02=0
  if [ "$diff_rc" -eq 0 ] && [ "$no_verb02" -eq 1 ]; then ok "12 rejeu réel, mode diff — exit 0, VERB-02 nulle part dans la reconstitution proposée"; else ko "12 rejeu réel, mode diff — exit 0, VERB-02 nulle part dans la reconstitution proposée" "rc=0, VERB-02 absent" "rc=$diff_rc verb02_absent=$no_verb02"; fi

  real_after="$(cat "$REAL_ARCHIVE")"
  if [ "$real_before" = "$real_after" ]; then ok "13 rejeu réel — l'archive RÉELLE du dépôt reste bit-à-bit identique avant/après"; else ko "13 rejeu réel — l'archive RÉELLE du dépôt reste bit-à-bit identique avant/après" "identique" "MODIFIÉE — INCIDENT"; fi

  # Rejeu --write sur la COPIE jetable (jamais le dépôt réel).
  bash "$SCRIPT" --path "$D" --write >/dev/null 2>"$TMP/c12-write.err"
  WF="$D/.planning/REQUIREMENTS.md"

  # --- 14a PRÉSENCE : IDs écrits = IDs d'archive − caduques, écart NOMMÉ ID par ID (pas une somme).
  written_ids="$(grep -oE '\*\*[A-Z]+-[0-9]+\*\*' "$WF" 2>/dev/null | tr -d '*' | sort -u)"
  missing=""
  while IFS= read -r aid; do
    [ -n "$aid" ] || continue
    printf '%s\n' "$ORACLE_CADUC_IDS" | grep -qx "$aid" && continue
    printf '%s\n' "$written_ids" | grep -qx "$aid" || missing="${missing:+$missing }$aid"
  done <<< "$ORACLE_ARCHIVE_IDS"
  expected_present="$((ORACLE_ARCHIVE_TOTAL - ORACLE_CADUC_N))"
  if [ -z "$missing" ]; then ok "14a rejeu réel — PRÉSENCE : les $expected_present IDs non-caducs de l'archive (sur $ORACLE_ARCHIVE_TOTAL) sont TOUS dans le fichier écrit"; else ko "14a rejeu réel — PRÉSENCE : les $expected_present IDs non-caducs de l'archive (sur $ORACLE_ARCHIVE_TOTAL) sont TOUS dans le fichier écrit" "0 manquant" "manquants=[$missing]"; fi

  # --- 14b DESTINATION : aucun ID "Planned" n'atterrit sous ## Garanties (assertion NOMINATIVE,
  # pas un compteur global — c'est le test qui aurait attrapé la route « case seule »).
  awk '/^## Garanties/{f=1;next} /^#{2,6} /{f=0} f{print}' "$WF" > "$TMP/c12-garanties.txt"
  wrong_planned=""
  while IFS= read -r pid; do
    [ -n "$pid" ] || continue
    grep -q "$pid" "$TMP/c12-garanties.txt" && wrong_planned="${wrong_planned:+$wrong_planned }$pid"
  done <<< "$ORACLE_PLANNED_IDS"
  planned_n="$(printf '%s\n' "$ORACLE_PLANNED_IDS" | grep -c .)"
  if [ -z "$wrong_planned" ]; then ok "14b rejeu réel — DESTINATION : les $planned_n IDs \"Planned\" de l'archive réelle voyagent, AUCUN sous ## Garanties"; else ko "14b rejeu réel — DESTINATION : les $planned_n IDs \"Planned\" de l'archive réelle voyagent, AUCUN sous ## Garanties" "0 Planned sous Garanties" "sous Garanties à tort : [$wrong_planned]"; fi

  # ================================================================================================
  # MUTATIONS A/B — les deux routes de précédence ESSAYÉES ET REJETÉES pendant la rédaction de ce
  # plan, rejouées comme mutants pour prouver que la suite les aurait attrapées. Chaque mutant
  # remplace ENTIÈREMENT vf_ledger_classify (awk : supprime la fonction vivante, une fonction de
  # remplacement est ajoutée en fin de fichier — la dernière définition d'un nom de fonction gagne en
  # bash) dans une COPIE sous mktemp -d, jamais le fichier vivant.
  # ================================================================================================
  strip_classify() { awk '/^vf_ledger_classify\(\) \{/{infunc=1;next} infunc&&/^}$/{infunc=0;next} infunc{next} {print}' "$PRIMITIVE"; }

  # --- MUTATION A : précédence restreinte au contrat D'ORIGINE du plan (Complete/Livré v
  # uniquement, repli sur code 3 plutôt que voyage) — doit faire ROUGIR la PRÉSENCE (14a-like),
  # exactement le défaut mesuré (86/136 perdus) qui a motivé cette réécriture.
  # $D/.planning/REQUIREMENTS.md a déjà été écrit par le --write du script VIVANT (14a/14b) : sans le
# retirer, le --write de la mutation (sans --overwrite-live) serait refusé par la garde de
# non-écrasement et laisserait l'ancien fichier CORRECT en place — un faux négatif de discriminance
# (la mutation semblerait n'avoir aucun effet alors qu'elle n'a simplement jamais tourné).
rm -f "$D/.planning/REQUIREMENTS.md"
MUTA_DIR="$TMP/mut-classify-a"; mkdir -p "$MUTA_DIR"
  strip_classify > "$MUTA_DIR/requirements-survival-detect.sh"
  cat >> "$MUTA_DIR/requirements-survival-detect.sh" <<'EOF3'
vf_ledger_classify() { # MUTATION A — precedence restreinte (Complete/Livre v, repli code 3)
  local body="$1" trace="$2" combo
  combo="$body
$trace"
  if printf '%s' "$combo" | grep -qi 'caduc'; then return 2; fi
  case "$body" in
    '- [x] '*)
      if printf '%s' "$trace" | grep -q 'Complete'; then return 0; fi
      if printf '%s' "$body" | grep -q 'Livré v'; then return 0; fi
      return 3
      ;;
    '- [ ] '*|'- [~] '*) return 1 ;;
    *) return 3 ;;
  esac
}
EOF3
  cp "$SCRIPT" "$MUTA_DIR/"
  chmod +x "$MUTA_DIR"/*.sh
  bash "$MUTA_DIR/restore-requirements-ledger.sh" --path "$D" --write >/dev/null 2>"$TMP/muta.err"
  MUTA_WF="$D/.planning/REQUIREMENTS.md"
  cp "$MUTA_WF" "$TMP/muta-written.md" 2>/dev/null
  MUTA_written_ids="$(grep -oE '\*\*[A-Z]+-[0-9]+\*\*' "$TMP/muta-written.md" 2>/dev/null | tr -d '*' | sort -u)"
  muta_missing=""
  while IFS= read -r aid; do
    [ -n "$aid" ] || continue
    printf '%s\n' "$ORACLE_CADUC_IDS" | grep -qx "$aid" && continue
    printf '%s\n' "$MUTA_written_ids" | grep -qx "$aid" || muta_missing="${muta_missing:+$muta_missing }$aid"
  done <<< "$ORACLE_ARCHIVE_IDS"
  if [ -n "$muta_missing" ]; then ok "MUTATION A (précédence restreinte) rougit la PRÉSENCE comme attendu : $(printf '%s' "$muta_missing" | wc -w | tr -d ' ') ID(s) manquant(s) sous la mutation"; else ko "MUTATION A — N'A PAS ROUGI la présence" "au moins un ID manquant sous la mutation (reproduit le défaut d'origine)" "0 manquant — mutation sans effet observable"; fi
  # Restaurer la fixture avant la mutation B (le --write de la mutation A a écrit le fichier vivant
  # de $D — le retirer pour que la fixture retrouve son état « ledger absent » nominal).
  rm -f "$D/.planning/REQUIREMENTS.md"

  # --- MUTATION B : précédence « case seule » (essayée puis retirée pendant cette même vague,
  # cf. correction dans requirements-survival-detect.sh) — doit faire ROUGIR la DESTINATION
  # (14b-like : les IDs "Planned", tous cochés dans l'archive réelle, atterriraient à tort sous
  # ## Garanties), en laissant la PRÉSENCE verte (elle atteint 136/136 par construction).
  MUTB_DIR="$TMP/mut-classify-b"; mkdir -p "$MUTB_DIR"
  strip_classify > "$MUTB_DIR/requirements-survival-detect.sh"
  cat >> "$MUTB_DIR/requirements-survival-detect.sh" <<'EOF4'
vf_ledger_classify() { # MUTATION B — case a cocher seule, ignore le texte de tracabilite
  local body="$1" trace="$2" combo
  combo="$body
$trace"
  if printf '%s' "$combo" | grep -qi 'caduc'; then return 2; fi
  case "$body" in
    '- [x] '*|'- [~] '*) return 0 ;;
    '- [ ] '*) return 1 ;;
    *) return 3 ;;
  esac
}
EOF4
  cp "$SCRIPT" "$MUTB_DIR/"
  chmod +x "$MUTB_DIR"/*.sh
  bash "$MUTB_DIR/restore-requirements-ledger.sh" --path "$D" --write >/dev/null 2>"$TMP/mutb.err"
  MUTB_WF="$D/.planning/REQUIREMENTS.md"
  awk '/^## Garanties/{f=1;next} /^#{2,6} /{f=0} f{print}' "$MUTB_WF" > "$TMP/mutb-garanties.txt" 2>/dev/null
  mutb_wrong=""
  while IFS= read -r pid; do
    [ -n "$pid" ] || continue
    grep -q "$pid" "$TMP/mutb-garanties.txt" 2>/dev/null && mutb_wrong="${mutb_wrong:+$mutb_wrong }$pid"
  done <<< "$ORACLE_PLANNED_IDS"
  if [ -n "$mutb_wrong" ]; then ok "MUTATION B (case seule) rougit la DESTINATION comme attendu : $(printf '%s' "$mutb_wrong" | wc -w | tr -d ' ') ID(s) \"Planned\" classé(s) garantie à tort"; else ko "MUTATION B — N'A PAS ROUGI la destination" "au moins un ID \"Planned\" sous ## Garanties sous la mutation" "0 — mutation sans effet observable"; fi
  rm -f "$D/.planning/REQUIREMENTS.md"
fi

echo ""
echo "== résultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
