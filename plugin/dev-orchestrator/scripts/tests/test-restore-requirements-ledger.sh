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
# NOTR-01 (coché, SANS aucune ligne de traçabilité — voyage par défaut, jamais garantie hallucinée
# depuis une trace absente ; correctif mineur 2026-08-18, revue de code : ce commentaire décrivait
# encore l'itération « case à cocher seule » abandonnée, l'assertion réelle l. 132/144 exige
# l'inverse, le voyage),
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
# Cas 18 (BLOQUANT #2, correctif 2026-08-18 — revue de code) : `cp` non vérifié avant le `mv`
# atomique. Sous `set -uo pipefail` (SANS `-e`), un `cp` en échec (cible non inscriptible) ne
# stoppait rien avant correctif : le `mv` suivant déplaçait alors un fichier vide/tronqué PAR-DESSUS
# le ledger vivant. Simulé ici en rendant `$TMPD/.REQUIREMENTS.md.XXXXXX` non copiable : on retire
# l'écriture sur le RÉPERTOIRE `.planning/` juste avant le `cp` intermédiaire n'est pas simulable
# proprement (root peut toujours écrire) — on simule plutôt en pointant `--path` vers un répertoire
# où `.planning/` est en lecture seule, empêchant le `mv` final (et donc, transitivement, prouvant
# que le script n'écrase JAMAIS $LIVE sur un échec de la chaîne cp/mv).
# ==================================================================================================
D="$(mk_root c18)"
w_milestones "$D" "$CLOSED_H2"
w_archive "$D" "demo-v1" "$DEMO_ARCHIVE"
LIVE_CONTENT_18=$'# Requirements: Live\n- [x] **PRECIEUX-02**: exigence vivante jamais archivee\n'
w_live "$D" "$LIVE_CONTENT_18"
LIVE_F18="$D/.planning/REQUIREMENTS.md"
sum_before18="$(checksum "$LIVE_F18")"
# Répertoire .planning/ rendu non-inscriptible : mktemp -p .planning/ (fichier temporaire d'écriture)
# échoue, ce qui est le point de garde le plus en amont de la chaîne cp/mv — prouve qu'aucune
# écriture partielle ne peut jamais atteindre $LIVE quand la préparation du temporaire échoue.
chmod 0555 "$D/.planning" 2>/dev/null
out18="$(bash "$SCRIPT" --path "$D" --write --overwrite-live 2>&1)"; rc18=$?
chmod 0755 "$D/.planning" 2>/dev/null
sum_after18="$(checksum "$LIVE_F18")"
if [ "$rc18" -ne 0 ] && [ "$sum_before18" = "$sum_after18" ]; then ok "18 (BLOQUANT #2) échec de préparation d'écriture (répertoire non-inscriptible) → code non nul, \$LIVE inchangé par empreinte, message sur stderr"; else ko "18 (BLOQUANT #2) échec de préparation d'écriture (répertoire non-inscriptible) → code non nul, \$LIVE inchangé par empreinte, message sur stderr" "code!=0, empreinte identique ($sum_before18)" "rc=$rc18 empreinte_apres=$sum_after18 out=[$out18]"; fi

# --- MUTATION BLOQUANT #2 : retirer la garde `cp ... || { ... exit 1; }` (revenir à un `cp` non
# vérifié suivi d'un `mv` inconditionnel) — simulé en shadowant `cp` lui-même via un PATH restreint
# (correctif 2026-08-18, revue tour 2, finding #4 : l'ancienne technique `chmod 0555 .planning`
# n'était PAS discriminante — le fichier destination `$WRITE_TMP` est créé par `mktemp` AVANT le
# `cp`, donc `cp` n'a besoin d'aucun droit d'ÉCRITURE sur le RÉPERTOIRE pour écrire DANS un fichier
# déjà existant : le test rendait systématiquement `ok` sur la branche de repli « écart non
# observable », prouvé en le rejouant sans aucune modification du script réel. Un `cp` de
# remplacement échouant UNIQUEMENT sur le gabarit mktemp de destination (`.REQUIREMENTS.md.`) laisse
# passer la sauvegarde `BACKUP_PATH` (motif différent) vers le vrai `/bin/cp`.)
MUT18_DIR="$TMP/mut-cpmv"; mkdir -p "$MUT18_DIR/fakebin"
cat > "$MUT18_DIR/fakebin/cp" <<'FAKECP18'
#!/bin/sh
last=""
for a in "$@"; do last="$a"; done
case "$last" in
  *".REQUIREMENTS.md."*) exit 1 ;;
  *) exec /bin/cp "$@" ;;
esac
FAKECP18
chmod +x "$MUT18_DIR/fakebin/cp"
# awk retire la garde `if ! cp ... ; then ... exit 1; fi` et le `chmod`, la remplace par un `cp`
# inconditionnel suivi directement du `mv` inconditionnel — reproduit EXACTEMENT le défaut d'origine.
awk '
  /^if ! cp "\$TMPD\/proposed.md" "\$WRITE_TMP"; then$/ { skip = 1; print "cp \"$TMPD/proposed.md\" \"$WRITE_TMP\""; next }
  skip && /^fi$/ { skip = 0; next }
  skip { next }
  /^chmod 0644 "\$WRITE_TMP" 2>\/dev\/null \|\| true$/ { next }
  /^if ! mv "\$WRITE_TMP" "\$LIVE"; then$/ { skip2 = 1; print "mv \"$WRITE_TMP\" \"$LIVE\""; next }
  skip2 && /^fi$/ { skip2 = 0; next }
  skip2 { next }
  { print }
' "$SCRIPT" > "$MUT18_DIR/restore-requirements-ledger.sh"
cp "$PRIMITIVE" "$MUT18_DIR/"
chmod +x "$MUT18_DIR"/*.sh
# Contrôle que la mutation a bien retiré la garde (sinon le test suivant ne prouverait rien).
guard_removed=0
grep -q 'if ! cp "\$TMPD/proposed.md"' "$MUT18_DIR/restore-requirements-ledger.sh" || guard_removed=1
if [ "$guard_removed" -eq 1 ]; then
  # Référence gardée (script RÉEL, même shadow cp) : prouve que la garde tient effectivement sous
  # exactement le même stimulus qu'utilisera la mutation ci-dessous.
  D="$(mk_root c18b)"
  w_milestones "$D" "$CLOSED_H2"
  w_archive "$D" "demo-v1" "$DEMO_ARCHIVE"
  w_live "$D" "$LIVE_CONTENT_18"
  LIVE_F18B="$D/.planning/REQUIREMENTS.md"
  sum_before18b="$(checksum "$LIVE_F18B")"
  PATH="$MUT18_DIR/fakebin:$PATH" bash "$SCRIPT" --path "$D" --write --overwrite-live >/dev/null 2>"$TMP/c18b.err"; rc18b=$?
  sum_after18b="$(checksum "$LIVE_F18B")"
  if [ "$rc18b" -ne 0 ] && [ "$sum_before18b" = "$sum_after18b" ]; then
    ok "18b (BLOQUANT #2) script RÉEL, cp shadowé (échoue sur WRITE_TMP) → code non nul, \$LIVE inchangé par empreinte"
  else
    ko "18b (BLOQUANT #2) script RÉEL, cp shadowé (échoue sur WRITE_TMP) → code non nul, \$LIVE inchangé par empreinte" "rc!=0, empreinte identique" "rc=$rc18b empreinte_apres=$sum_after18b"
  fi

  D="$(mk_root cm18)"
  w_milestones "$D" "$CLOSED_H2"
  w_archive "$D" "demo-v1" "$DEMO_ARCHIVE"
  w_live "$D" "$LIVE_CONTENT_18"
  LIVE_F_M18="$D/.planning/REQUIREMENTS.md"
  sum_before_m18="$(checksum "$LIVE_F_M18")"
  PATH="$MUT18_DIR/fakebin:$PATH" bash "$MUT18_DIR/restore-requirements-ledger.sh" --path "$D" --write --overwrite-live >/dev/null 2>&1; mut18_rc=$?
  sum_after_m18="$(checksum "$LIVE_F_M18")"
  # Sous la mutation (guarde retirée), le mv déplace le fichier vide/tronqué (cp échoué) PAR-DESSUS
  # $LIVE : code 0 ET empreinte modifiée sont TOUS DEUX attendus — c'est la corruption exacte que
  # la garde existe pour empêcher.
  if [ "$mut18_rc" -eq 0 ] && [ "$sum_before_m18" != "$sum_after_m18" ]; then
    ok "MUTATION BLOQUANT #2 (garde cp/mv retirée) rougit comme attendu : cp shadowé échoue sur WRITE_TMP, mv écrase \$LIVE avec un fichier vide (code=0, empreinte modifiée)"
  else
    ko "MUTATION BLOQUANT #2 — N'A PAS ROUGI comme attendu" "code=0 ET empreinte modifiée (corruption silencieuse reproduite)" "rc=$mut18_rc empreinte_egale=$([ "$sum_before_m18" = "$sum_after_m18" ] && echo oui || echo NON)"
  fi
else
  ko "MUTATION BLOQUANT #2 — construction du mutant a échoué" "la garde cp/mv est retirée du fichier muté" "grep trouve encore la garde"
fi

# ==================================================================================================
# Cas 19 (ÉLEVÉE, correctif 2026-08-18 — revue de code + audit sécurité) : injection de terminal
# (ANSI/BEL) dans le diff affiché. Le diff réimprime le contenu de l'ARCHIVE verbatim — une archive
# hostile portant ESC[2K / ESC[1A / BEL pourrait masquer des lignes que l'humain croit lire
# intégralement, défaisant la validation humaine (ADR-031) sur laquelle repose tout le gate.
# ==================================================================================================
D="$(mk_root c19)"
w_milestones "$D" "$CLOSED_H2"
HOSTILE_ARCHIVE=$'# Requirements: Hostile\n\n### Famille\n\n- [x] **ANSI-01**: item avec sequence \x1b[2Ket \x1b[1Aet bel\x07 inline\n\n## Traceability\n\n| Requirement | Phase | Status |\n|---|---|---|\n| ANSI-01 | Phase 1 | Done - \x1b[2Kcamoufle |\n'
w_archive "$D" "demo-v1" "$HOSTILE_ARCHIVE"
diff_out19="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"
has_esc19=0; printf '%s' "$diff_out19" | grep -q $'\x1b' && has_esc19=1
has_bel19=0; printf '%s' "$diff_out19" | grep -q $'\x07' && has_bel19=1
if [ "$has_esc19" -eq 0 ] && [ "$has_bel19" -eq 0 ]; then ok "19a (ÉLEVÉE) diff affiché — aucun octet de contrôle ESC/BEL, archive hostile neutralisée à l'affichage"; else ko "19a (ÉLEVÉE) diff affiché — aucun octet de contrôle ESC/BEL, archive hostile neutralisée à l'affichage" "0 ESC, 0 BEL" "ESC présent=$has_esc19 BEL présent=$has_bel19"; fi
# Le FICHIER écrit sous --write conserve les octets de contrôle INTACTS (D-18-13, zéro normalisation
# du contenu écrit — seul le RENDU terminal est neutralisé, jamais le fichier).
bash "$SCRIPT" --path "$D" --write >/dev/null 2>&1
WF19="$D/.planning/REQUIREMENTS.md"
written_has_esc19=0; grep -q $'\x1b' "$WF19" 2>/dev/null && written_has_esc19=1
written_has_bel19=0; grep -q $'\x07' "$WF19" 2>/dev/null && written_has_bel19=1
if [ "$written_has_esc19" -eq 1 ] && [ "$written_has_bel19" -eq 1 ]; then ok "19b (ÉLEVÉE) fichier écrit sous --write — octets de contrôle CONSERVÉS intacts (D-18-13, la neutralisation ne touche que l'affichage)"; else ko "19b (ÉLEVÉE) fichier écrit sous --write — octets de contrôle CONSERVÉS intacts (D-18-13, la neutralisation ne touche que l'affichage)" "ESC présent=1 BEL présent=1 dans le fichier écrit" "ESC=$written_has_esc19 BEL=$written_has_bel19"; fi

# --- MUTATION ÉLEVÉE : retirer le `| tr -d ...` de neutralisation du diff — doit faire ROUGIR 19a
# (les octets de contrôle réapparaissent dans le diff affiché), en laissant VERT 19b (le fichier
# écrit, jamais touché par cette neutralisation, reste inchangé par la mutation).
MUT19_DIR="$TMP/mut-ansi"; mkdir -p "$MUT19_DIR"
sed "s/| tr -d '\\\\000-\\\\010\\\\013-\\\\037\\\\177'//" "$SCRIPT" > "$MUT19_DIR/restore-requirements-ledger.sh"
cp "$PRIMITIVE" "$MUT19_DIR/"
chmod +x "$MUT19_DIR"/*.sh
guard19_removed=0
# Le fichier vivant porte PLUSIEURS `tr -d` (compteurs GARANTIES_N/VOYAGE_N/…, sans rapport avec la
# neutralisation) — la présence ATTENDUE, spécifique, est celle de la plage de contrôle C0 retirée.
grep -qF "tr -d '\\000-\\010\\013-\\037\\177'" "$MUT19_DIR/restore-requirements-ledger.sh" || guard19_removed=1
if [ "$guard19_removed" -eq 1 ]; then
  D="$(mk_root cm19)"
  w_milestones "$D" "$CLOSED_H2"
  w_archive "$D" "demo-v1" "$HOSTILE_ARCHIVE"
  mut19_out="$(bash "$MUT19_DIR/restore-requirements-ledger.sh" --path "$D" 2>/dev/null)"
  mut19_has_esc=0; printf '%s' "$mut19_out" | grep -q $'\x1b' && mut19_has_esc=1
  if [ "$mut19_has_esc" -eq 1 ]; then ok "MUTATION ÉLEVÉE (neutralisation retirée) rougit le cas 19a comme attendu : ESC réapparaît dans le diff affiché"; else ko "MUTATION ÉLEVÉE — N'A PAS ROUGI" "ESC réapparaît dans le diff affiché sous la mutation" "toujours absent — mutation sans effet observable"; fi
else
  ko "MUTATION ÉLEVÉE — construction du mutant a échoué" "le fichier muté ne porte plus tr -d" "grep trouve encore tr -d"
fi

# ==================================================================================================
# Cas 20 (MOYEN, correctif 2026-08-18) : IDs de traçabilité DUPLIQUÉS — deux lignes pour le même ID,
# statuts CONTRADICTOIRES. Le dernier gagne (déterministe, comportement inchangé) mais la duplication
# est désormais SIGNALÉE sur stderr, jamais un écrasement silencieux.
# ==================================================================================================
D="$(mk_root c20)"
w_milestones "$D" "$CLOSED_H2"
DUP_ARCHIVE=$'# Requirements: Dup\n\n### Famille\n\n- [x] **DUP-01**: item avec traces dupliquees\n\n## Traceability\n\n| Requirement | Phase | Status |\n|---|---|---|\n| DUP-01 | Phase 1 | Done - premiere trace |\n| DUP-01 | Phase 2 | Planned - deuxieme trace contradictoire |\n'
w_archive "$D" "demo-v1" "$DUP_ARCHIVE"
diff20_err="$(bash "$SCRIPT" --path "$D" 2>&1 1>/dev/null)"
signaled20=0; printf '%s' "$diff20_err" | grep -q 'DUP-01' && signaled20=1
if [ "$signaled20" -eq 1 ]; then ok "20 (MOYEN) traçabilité dupliquée (DUP-01, statuts contradictoires) → signalée sur stderr, jamais un écrasement silencieux"; else ko "20 (MOYEN) traçabilité dupliquée (DUP-01, statuts contradictoires) → signalée sur stderr, jamais un écrasement silencieux" "stderr contient DUP-01" "stderr=[$diff20_err]"; fi
# Déterminisme : la ligne retenue est TOUJOURS la dernière rencontrée dans l'archive (comportement
# inchangé, deux exécutions consécutives rendent la même ligne de traçabilité écrite).
bash "$SCRIPT" --path "$D" --write >/dev/null 2>/dev/null
WF20A="$(cat "$D/.planning/REQUIREMENTS.md" 2>/dev/null)"
rm -f "$D/.planning/REQUIREMENTS.md"
bash "$SCRIPT" --path "$D" --write >/dev/null 2>/dev/null
WF20B="$(cat "$D/.planning/REQUIREMENTS.md" 2>/dev/null)"
if [ "$WF20A" = "$WF20B" ] && printf '%s' "$WF20A" | grep -q 'deuxieme trace contradictoire'; then ok "20 (MOYEN) suite — résultat déterministe (dernière trace rencontrée retenue à chaque exécution)"; else ko "20 (MOYEN) suite — résultat déterministe (dernière trace rencontrée retenue à chaque exécution)" "deux écritures identiques, dernière trace retenue" "identique=$([ "$WF20A" = "$WF20B" ] && echo oui || echo non)"; fi

# ==================================================================================================
# Cas 21 (MOYEN, correctif 2026-08-18) : statut « Incomplete » ne doit JAMAIS matcher `complete` en
# sous-chaîne dans vf_ledger_classify (LEDG-01) — bornes de mot désormais appliquées. Sans le
# correctif, INCO-01 (case cochée, trace « Incomplete ») aurait été classée Garantie à tort, perdant
# silencieusement son carried-from: si elle n'était pas réellement livrée.
# ==================================================================================================
D="$(mk_root c21)"
w_milestones "$D" "$CLOSED_H2"
INCO_ARCHIVE=$'# Requirements: Inco\n\n### Famille\n\n- [x] **INCO-01**: statut incomplet\n\n## Traceability\n\n| Requirement | Phase | Status |\n|---|---|---|\n| INCO-01 | Phase 1 | Incomplete - reste 2 items |\n'
w_archive "$D" "demo-v1" "$INCO_ARCHIVE"
bash "$SCRIPT" --path "$D" --write >/dev/null 2>&1
WF21="$D/.planning/REQUIREMENTS.md"
inco_in_garanties=0
awk '/^## Garanties/{f=1;next} /^#{2,6} /{f=0} f{print}' "$WF21" 2>/dev/null | grep -q 'INCO-01' && inco_in_garanties=1
inco_in_reportees=0
# Frontière H1/H2 uniquement (règle réelle du consommateur, D-18-03/14c) — PAS #{2,6} : les
# familles ### vivent SOUS ## Reportées sans H2 intercalé, une frontière #{2,6} couperait au
# premier ### et manquerait systématiquement tout ID nichée sous sa famille.
REPORTEES21="$(awk '/^## Reportées/{f=1;next} /^#{1,2} /{f=0} f{print}' "$WF21" 2>/dev/null)"
if printf '%s' "$REPORTEES21" | grep -q 'INCO-01' && printf '%s' "$REPORTEES21" | grep -q 'carried-from: demo-v1'; then
  inco_in_reportees=1
fi
if [ "$inco_in_garanties" -eq 0 ] && [ "$inco_in_reportees" -eq 1 ]; then ok "21 (MOYEN) statut Incomplete → PAS classé Garantie via un match complete/done en sous-chaîne, voyage (carried-from:) comme attendu"; else ko "21 (MOYEN) statut Incomplete → PAS classé Garantie via un match complete/done en sous-chaîne, voyage (carried-from:) comme attendu" "0 sous Garanties, 1 sous Reportées avec carried-from:" "garanties=$inco_in_garanties reportees=$inco_in_reportees"; fi

# --- MUTATION MOYEN (complete|done) : retirer les bornes de mot dans une COPIE de la primitive —
# doit faire ROUGIR le cas 21 (INCO-01 devient Garantie à tort), en laissant VERT le cas 6b (PROSE-01
# reste garantie via Spike done, AAAA-01 via Done).
MUT21_DIR="$TMP/mut-incomplete"; mkdir -p "$MUT21_DIR"
sed "s/\\\\bcomplete\\\\b|\\\\bdone\\\\b/complete|done/" "$PRIMITIVE" > "$MUT21_DIR/requirements-survival-detect.sh"
cp "$SCRIPT" "$MUT21_DIR/"
chmod +x "$MUT21_DIR"/*.sh
guard21_removed=0
grep -qE "grep -qiE 'complete\|done'" "$MUT21_DIR/requirements-survival-detect.sh" && guard21_removed=1
if [ "$guard21_removed" -eq 1 ]; then
  D="$(mk_root cm21)"
  w_milestones "$D" "$CLOSED_H2"
  w_archive "$D" "demo-v1" "$INCO_ARCHIVE"
  bash "$MUT21_DIR/restore-requirements-ledger.sh" --path "$D" --write >/dev/null 2>&1
  MWF21="$D/.planning/REQUIREMENTS.md"
  mut21_wrong=0
  awk '/^## Garanties/{f=1;next} /^#{2,6} /{f=0} f{print}' "$MWF21" 2>/dev/null | grep -q 'INCO-01' && mut21_wrong=1
  if [ "$mut21_wrong" -eq 1 ]; then ok "MUTATION MOYEN (bornes de mot retirées) rougit le cas 21 comme attendu : INCO-01 classée Garantie à tort"; else ko "MUTATION MOYEN — N'A PAS ROUGI" "INCO-01 classée Garantie sous la mutation" "toujours voyage — mutation sans effet observable"; fi
  # Contrôle de discriminance : AAAA-01 (Done réel) et PROSE-01 (Spike done) restent en Garanties.
  D2="$(mk_root cm21-controle)"
  w_milestones "$D2" "$CLOSED_H2"
  w_archive "$D2" "demo-v1" "$DEMO_ARCHIVE"
  bash "$MUT21_DIR/restore-requirements-ledger.sh" --path "$D2" --write >/dev/null 2>&1
  MWF21C="$D2/.planning/REQUIREMENTS.md"
  ctrl21_ok=1
  MG21="$(awk '/^## Garanties/{f=1;next} /^#{2,6} /{f=0} f{print}' "$MWF21C" 2>/dev/null)"
  printf '%s' "$MG21" | grep -q 'AAAA-01' || ctrl21_ok=0
  printf '%s' "$MG21" | grep -q 'PROSE-01' || ctrl21_ok=0
  if [ "$ctrl21_ok" -eq 1 ]; then ok "MUTATION MOYEN — le cas 6b (AAAA-01/PROSE-01 garanties) reste VERT sous cette mutation (discriminance)"; else ko "MUTATION MOYEN — discriminance rompue, cas 6b affecté aussi" "AAAA-01 et PROSE-01 toujours en Garanties" "MG21=[$MG21]"; fi
else
  ko "MUTATION MOYEN — construction du mutant a échoué" "le fichier muté ne porte plus les bornes de mot" "grep n'a pas trouvé la forme sans bornes"
fi

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

  # Rejeu --write sur la COPIE jetable (jamais le dépôt réel). stdout capturé aussi (le résumé
  # "Garanties: N …" y est imprimé, pas sur stderr) — nécessaire au cas 14c ci-dessous.
  bash "$SCRIPT" --path "$D" --write >"$TMP/c12-write.out" 2>"$TMP/c12-write.err"
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

  # --- 14c FRONTIÈRE DE SECTION vue par un CONSOMMATEUR RÉEL (correction structurelle du
  # 2026-08-18) : `updateTraceabilityCell()` (gsd-core, cité par D-18-03) borne sa portée au
  # PROCHAIN H1/H2 — jamais au prochain H3. Un lecteur qui applique CETTE règle exacte sur
  # ## Garanties doit ramasser EXACTEMENT le compte annoncé (93) et ZÉRO ligne carried-from: — pas
  # 135 IDs dont 42 voyageuses nichées sous des ### de famille sans H2 intercalé (défaut réel
  # constaté : les familles ### suivaient directement ## Garanties, aucun H2 entre les deux).
  awk '/^## Garanties/{f=1;next} /^#{1,2} /{f=0} f{print}' "$WF" > "$TMP/c12-garanties-h1h2.txt"
  h1h2_ids="$(grep -oE '\*\*[A-Z]+-[0-9]+\*\*' "$TMP/c12-garanties-h1h2.txt" | tr -d '*' | sort -u | wc -l | tr -d ' ')"
  h1h2_carried="$(grep -c 'carried-from:' "$TMP/c12-garanties-h1h2.txt")"
  written_g_count="$(grep -oE 'Garanties: [0-9]+' "$TMP/c12-write.out" | grep -oE '[0-9]+' | head -1)"
  if [ "$h1h2_ids" -eq "$written_g_count" ] && [ "$h1h2_carried" -eq 0 ]; then
    ok "14c frontière H1/H2 (règle du consommateur réel) — ## Garanties contient exactement $written_g_count IDs, 0 carried-from:"
  else
    ko "14c frontière H1/H2 (règle du consommateur réel) — ## Garanties contient exactement $written_g_count IDs, 0 carried-from:" "IDs=$written_g_count carried-from=0" "IDs=$h1h2_ids carried-from=$h1h2_carried"
  fi

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

  # --- MUTATION C : rétrograder le H2 des voyageuses (## Reportées) en H3 (### Reportées) — le
  # défaut structurel réel constaté et corrigé le 2026-08-18. Doit faire ROUGIR 14c (règle du
  # consommateur réel, H1/H2 seulement), en laissant 14a/14b VERTS (présence et destination à la
  # SOURCE restent correctes — seule la structure du fichier écrit change).
  MUTC_DIR="$TMP/mut-h2"; mkdir -p "$MUTC_DIR"
  sed 's/echo "## Reportées"/echo "### Reportées"/' "$SCRIPT" > "$MUTC_DIR/restore-requirements-ledger.sh"
  cp "$PRIMITIVE" "$MUTC_DIR/"
  chmod +x "$MUTC_DIR"/*.sh
  bash "$MUTC_DIR/restore-requirements-ledger.sh" --path "$D" --write >"$TMP/mutc.out" 2>"$TMP/mutc.err"
  MUTC_WF="$D/.planning/REQUIREMENTS.md"
  awk '/^## Garanties/{f=1;next} /^#{1,2} /{f=0} f{print}' "$MUTC_WF" > "$TMP/mutc-garanties-h1h2.txt" 2>/dev/null
  mutc_carried="$(grep -c 'carried-from:' "$TMP/mutc-garanties-h1h2.txt" 2>/dev/null || echo 0)"
  if [ "$mutc_carried" -gt 0 ]; then
    ok "MUTATION C (H2 des voyageuses rétrogradé en H3) rougit 14c comme attendu : $mutc_carried ligne(s) carried-from: nichée(s) sous ## Garanties (règle du consommateur réel)"
  else
    ko "MUTATION C — N'A PAS ROUGI 14c" "au moins une ligne carried-from: nichée sous ## Garanties par la règle H1/H2" "0 — mutation sans effet observable"
  fi
  rm -f "$D/.planning/REQUIREMENTS.md"
fi

# ==================================================================================================
# Cas 22 (BLOQUANT, correctif 2026-08-18, revue tour 2) : confinement de traversée symlink
# D'ANCÊTRE. La garde `[ -f "$archive" ] && [ ! -L "$archive" ]` ne teste QUE le fichier feuille —
# jamais les répertoires intermédiaires. Reproduit trois fois (revue, audit, exécution) :
# `.planning/milestones` symlinké vers un répertoire HORS du lab, jalon déclaré clos, $LIVE absent
# → sans la garde d'ancêtre, restore lisait/écrivait du contenu venu de l'EXTÉRIEUR du lab.
# ==================================================================================================
D="$(mk_root c22)"
w_milestones "$D" "$CLOSED_H2"
OUTSIDE22_DIR="$TMP/outside-secret-22"
mkdir -p "$OUTSIDE22_DIR"
printf '# Requirements: Hostile\n\n### Famille\n\n- [x] **LEAK-01**: exigence venue de HORS du lab\n\n## Traceability\n\n| Requirement | Phase | Status |\n|---|---|---|\n| LEAK-01 | Phase 1 | Done - leak |\n' > "$OUTSIDE22_DIR/demo-v1-REQUIREMENTS.md"
ln -s "$OUTSIDE22_DIR" "$D/.planning/milestones"
sum_outside22_before="$(checksum "$OUTSIDE22_DIR/demo-v1-REQUIREMENTS.md")"

# Mode diff (sans --write) : aucune fuite dans stdout.
diff22_out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc22diff=$?
leak22diff=0; printf '%s' "$diff22_out" | grep -q 'LEAK-01' && leak22diff=1
if [ "$leak22diff" -eq 0 ]; then ok "22a (BLOQUANT) mode diff — ancêtre symlinké, LEAK-01 absent de stdout"; else ko "22a (BLOQUANT) mode diff — ancêtre symlinké, LEAK-01 absent de stdout" "LEAK-01 absent" "diff=[$diff22_out] rc=$rc22diff"; fi

# Mode --write : refus (rien à reconstituer, archive inatteignable via l'ancêtre lien), $LIVE
# toujours absent, cible externe non touchée (empreinte).
bash "$SCRIPT" --path "$D" --write >/dev/null 2>"$TMP/c22-write.err"; rc22write=$?
live22_present=0; [ -f "$D/.planning/REQUIREMENTS.md" ] && live22_present=1
sum_outside22_after="$(checksum "$OUTSIDE22_DIR/demo-v1-REQUIREMENTS.md")"
if [ "$rc22write" -ne 0 ] && [ "$live22_present" -eq 0 ] && [ "$sum_outside22_before" = "$sum_outside22_after" ]; then
  ok "22b (BLOQUANT) --write — refus (code!=0), \$LIVE toujours absent, cible externe intacte par empreinte"
else
  ko "22b (BLOQUANT) --write — refus (code!=0), \$LIVE toujours absent, cible externe intacte par empreinte" "rc!=0, LIVE absent, empreinte externe identique" "rc=$rc22write live_present=$live22_present empreinte_egale=$([ "$sum_outside22_before" = "$sum_outside22_after" ] && echo oui || echo NON)"
fi

# --- MUTATION (BLOQUANT, cas 22) : retirer la garde d'ancêtre des DEUX occurrences dans la
# primitive partagée (index/substr, pas de regex — évite tout souci d'échappement de `$` en awk) —
# le mutant doit rougir : LEAK-01 apparaît dans le diff.
MUT22_DIR="$TMP/mut-ancestor"; mkdir -p "$MUT22_DIR"
awk '
{
  line = $0
  pat = " && ! vf_ancestor_symlink_found \"$archive\" \"$planning_dir\""
  idx = index(line, pat)
  if (idx > 0) { line = substr(line, 1, idx - 1) substr(line, idx + length(pat)) }
  print line
}
' "$PRIMITIVE" > "$MUT22_DIR/requirements-survival-detect.sh"
cp "$SCRIPT" "$MUT22_DIR/"
chmod +x "$MUT22_DIR"/*.sh
# La fonction elle-même (définition + commentaires) reste présente dans le fichier muté — seul
# l'APPEL dans les deux gardes `if` est retiré. Contrôler l'absence du littéral fonction seule
# donnerait toujours faux (grep la trouverait dans la définition) : on vérifie l'absence de l'APPEL
# dans un contexte de condition `if`.
guard22_removed=0
grep -q '\] && ! vf_ancestor_symlink_found' "$MUT22_DIR/requirements-survival-detect.sh" || guard22_removed=1
if [ "$guard22_removed" -eq 1 ]; then
  diff22mut_out="$(bash "$MUT22_DIR/restore-requirements-ledger.sh" --path "$D" 2>/dev/null)"
  leak22mut=0; printf '%s' "$diff22mut_out" | grep -q 'LEAK-01' && leak22mut=1
  if [ "$leak22mut" -eq 1 ]; then
    ok "MUTATION 22 (garde d'ancêtre retirée) rougit comme attendu : LEAK-01 réapparaît dans le diff via l'ancêtre symlinké"
  else
    ko "MUTATION 22 — N'A PAS ROUGI" "LEAK-01 présent dans le diff sous la mutation" "LEAK-01 absent — discriminance rompue"
  fi
else
  ko "MUTATION 22 — construction du mutant a échoué" "vf_ancestor_symlink_found absent du fichier muté" "grep le trouve encore"
fi
# Discriminance : un cas sans ancêtre symlinké (cas 3, DEMO_ARCHIVE) reste VERT sous cette mutation.
D_CTRL22="$(mk_root c22ctrl)"
w_milestones "$D_CTRL22" "$CLOSED_H2"
w_archive "$D_CTRL22" "demo-v1" "$DEMO_ARCHIVE"
ctrl22_out="$(bash "$MUT22_DIR/restore-requirements-ledger.sh" --path "$D_CTRL22" 2>/dev/null)"; ctrl22_rc=$?
if [ "$ctrl22_rc" -eq 0 ] && printf '%s' "$ctrl22_out" | grep -q 'AAAA-01'; then
  ok "MUTATION 22 — le cas 3 (archive normale, aucun ancêtre lien) reste VERT sous cette mutation (discriminance)"
else
  ko "MUTATION 22 — discriminance rompue, le cas normal est affecté aussi" "cas normal inchangé (rc=0, AAAA-01 présent)" "rc=$ctrl22_rc out=[$ctrl22_out]"
fi

# ==================================================================================================
# Cas 23 (MAJEUR #1, correctif 2026-08-18, revue tour 2) : neutralisation ANSI/BEL étendue au canal
# du message de traçabilité DUPLIQUÉE (cas 20) — jusqu'ici réimprimé directement par awk vers
# /dev/stderr, HORS de portée du `tr -d` qui ne protégeait que le diff sur stdout.
# ==================================================================================================
D="$(mk_root c23)"
w_milestones "$D" "$CLOSED_H2"
DUPHOSTILE_ARCHIVE=$'# Requirements: DupHostile\n\n### Famille\n\n- [x] **DUPH-01**: item avec traces dupliquees hostiles\n\n## Traceability\n\n| Requirement | Phase | Status |\n|---|---|---|\n| DUPH-01 | Phase 1 | Done - premiere \x1b[2Ktrace |\n| DUPH-01 | Phase 2 | Planned - deuxieme trace \x07contradictoire |\n'
w_archive "$D" "demo-v1" "$DUPHOSTILE_ARCHIVE"
err23="$(bash "$SCRIPT" --path "$D" 2>&1 1>/dev/null)"
has_esc23=0; printf '%s' "$err23" | grep -q $'\x1b' && has_esc23=1
has_bel23=0; printf '%s' "$err23" | grep -q $'\x07' && has_bel23=1
signaled23=0; printf '%s' "$err23" | grep -q 'DUPH-01' && signaled23=1
if [ "$has_esc23" -eq 0 ] && [ "$has_bel23" -eq 0 ] && [ "$signaled23" -eq 1 ]; then
  ok "23 (MAJEUR #1) message de traçabilité dupliquée sur stderr — aucun ESC/BEL, DUPH-01 toujours signalé"
else
  ko "23 (MAJEUR #1) message de traçabilité dupliquée sur stderr — aucun ESC/BEL, DUPH-01 toujours signalé" "0 ESC, 0 BEL, DUPH-01 présent" "ESC=$has_esc23 BEL=$has_bel23 signalé=$signaled23 err=[$err23]"
fi

# --- MUTATION (MAJEUR #1, cas 23) : retirer le filtre `tr -d` sur CE canal (revenir à l'impression
# awk directe vers /dev/stderr) — le mutant doit rougir : ESC/BEL réapparaissent.
MUT23_DIR="$TMP/mut-dupwarn"; mkdir -p "$MUT23_DIR"
awk '
  /^if \[ -s "\$TMPD\/dupwarn.txt" \]; then$/ { skip = 1; next }
  skip && /^fi$/ { skip = 0; next }
  skip { next }
  { print }
' "$SCRIPT" > "$MUT23_DIR/restore-requirements-ledger.sh"
cp "$PRIMITIVE" "$MUT23_DIR/"
chmod +x "$MUT23_DIR"/*.sh
# "dupwarn.txt" seul resterait toujours présent (la population du fichier, `-v dupfile=...`, est
# HORS du bloc retiré) — on contrôle l'absence spécifique de la boucle de réimpression sanitisée.
guard23_removed=0
grep -q '_dupid _dupold _dupnew' "$MUT23_DIR/restore-requirements-ledger.sh" || guard23_removed=1
if [ "$guard23_removed" -eq 1 ]; then
  err23mut="$(bash "$MUT23_DIR/restore-requirements-ledger.sh" --path "$D" 2>&1 1>/dev/null)"
  has_esc23mut=0; printf '%s' "$err23mut" | grep -q $'\x1b' && has_esc23mut=1
  # Sans la boucle de réimpression sanitisée, le fichier dupwarn.txt reste écrit mais jamais
  # réimprimé du tout (aucun autre point du script ne le lit) : la discriminance porte donc sur
  # l'ABSENCE totale du signal DUPH-01 sous cette mutation précise (pas sur l'ESC réintroduit) —
  # documenté ici pour éviter un faux négatif si un futur remaniement change la stratégie.
  signaled23mut=0; printf '%s' "$err23mut" | grep -q 'DUPH-01' && signaled23mut=1
  if [ "$signaled23mut" -eq 0 ]; then
    ok "MUTATION 23 (bloc de réimpression sanitisée retiré) rougit comme attendu : DUPH-01 disparaît totalement du signal stderr"
  else
    ko "MUTATION 23 — N'A PAS ROUGI" "DUPH-01 absent sous la mutation (bloc retiré)" "signalé=$signaled23mut err=[$err23mut]"
  fi
else
  ko "MUTATION 23 — construction du mutant a échoué" "le bloc dupwarn.txt est retiré du fichier muté" "grep le trouve encore"
fi

# ==================================================================================================
# Cas 24 (MAJEUR #2, correctif 2026-08-18, revue tour 2) : la trace T-18-09 (forme non reconnue,
# code 3) échappe à --quiet. Sans le correctif, `say()` gatait ce message : stderr vide sous
# --quiet, contredisant l'invariant documenté en tête de fichier (« jamais absorbé sans trace »).
# ==================================================================================================
D="$(mk_root c24)"
w_milestones "$D" "$CLOSED_H2"
w_archive "$D" "demo-v1" "$DEMO_ARCHIVE"
err24_noquiet="$(bash "$SCRIPT" --path "$D" 2>&1 1>/dev/null)"
err24_quiet="$(bash "$SCRIPT" --path "$D" --quiet 2>&1 1>/dev/null)"
has24_noquiet=0; printf '%s' "$err24_noquiet" | grep -q 'CCCC-99' && has24_noquiet=1
has24_quiet=0; printf '%s' "$err24_quiet" | grep -q 'CCCC-99' && has24_quiet=1
if [ "$has24_noquiet" -eq 1 ] && [ "$has24_quiet" -eq 1 ]; then
  ok "24 (MAJEUR #2) trace T-18-09 (CCCC-99, code 3) présente sur stderr SANS --quiet ET AVEC --quiet"
else
  ko "24 (MAJEUR #2) trace T-18-09 (CCCC-99, code 3) présente sur stderr SANS --quiet ET AVEC --quiet" "présente dans les deux modes" "sans_quiet=$has24_noquiet avec_quiet=$has24_quiet"
fi

# --- MUTATION (MAJEUR #2, cas 24) : remettre `say` à la place des `echo` directs — le mutant doit
# rougir sous --quiet uniquement (le mode normal reste vert, discriminance).
MUT24_DIR="$TMP/mut-code3quiet"; mkdir -p "$MUT24_DIR"
awk '
  /^  echo "\[restore-requirements-ledger\] forme non reconnue \(code 3\)/ {
    sub(/^  echo "\[restore-requirements-ledger\] /, "  say \"")
    sub(/" >&2$/, "\"")
    print; next
  }
  /^  while IFS= read -r cid; do \[ -n "\$cid" \] && echo "\[restore-requirements-ledger\]   - \$cid" >&2; done/ {
    sub(/echo "\[restore-requirements-ledger\]   - \$cid" >&2/, "say \"  - $cid\"")
    print; next
  }
  { print }
' "$SCRIPT" > "$MUT24_DIR/restore-requirements-ledger.sh"
cp "$PRIMITIVE" "$MUT24_DIR/"
chmod +x "$MUT24_DIR"/*.sh
# Le mutant a réussi si le `echo` direct D'ORIGINE (non gaté par --quiet) a disparu — même
# convention que les mutations précédentes (contrôler l'ABSENCE du texte original, pas la présence
# du remplacement).
guard24_removed=0
grep -q 'echo "\[restore-requirements-ledger\] forme non reconnue' "$MUT24_DIR/restore-requirements-ledger.sh" || guard24_removed=1
if [ "$guard24_removed" -eq 1 ]; then
  err24mut_quiet="$(bash "$MUT24_DIR/restore-requirements-ledger.sh" --path "$D" --quiet 2>&1 1>/dev/null)"
  has24mut_quiet=0; printf '%s' "$err24mut_quiet" | grep -q 'CCCC-99' && has24mut_quiet=1
  err24mut_noquiet="$(bash "$MUT24_DIR/restore-requirements-ledger.sh" --path "$D" 2>&1 1>/dev/null)"
  has24mut_noquiet=0; printf '%s' "$err24mut_noquiet" | grep -q 'CCCC-99' && has24mut_noquiet=1
  if [ "$has24mut_quiet" -eq 0 ] && [ "$has24mut_noquiet" -eq 1 ]; then
    ok "MUTATION 24 (say() réintroduit) rougit comme attendu : CCCC-99 disparaît sous --quiet, reste sous mode normal (discriminance)"
  else
    ko "MUTATION 24 — N'A PAS ROUGI comme attendu" "absent sous --quiet, présent sans --quiet" "avec_quiet=$has24mut_quiet sans_quiet=$has24mut_noquiet"
  fi
else
  ko "MUTATION 24 — construction du mutant a échoué" "say(...) réintroduit dans le fichier muté" "grep ne le trouve pas"
fi

# ==================================================================================================
# Cas 25 (MAJEUR #3, correctif 2026-08-18, revue tour 2) : la sauvegarde `cp "$LIVE" "$BACKUP_PATH"`
# suit un symlink PRÉEXISTANT à l'emplacement prévisible `${LIVE}.bak-<jalon>` — le contenu du
# ledger vivant s'écrirait alors À TRAVERS le lien, vers une cible arbitraire hors du lab.
# ==================================================================================================
D="$(mk_root c25)"
w_milestones "$D" "$CLOSED_H2"
w_archive "$D" "demo-v1" "$DEMO_ARCHIVE"
LIVE_CONTENT_25=$'# Requirements: Live\n- [x] **PRECIEUX-25**: exigence vivante jamais archivee\n'
w_live "$D" "$LIVE_CONTENT_25"
LIVE_F25="$D/.planning/REQUIREMENTS.md"
BACKUP_F25="${LIVE_F25}.bak-demo-v1"
OUTSIDE25="$TMP/outside-target-25.txt"
printf 'secret-exterieur-25\n' > "$OUTSIDE25"
ln -s "$OUTSIDE25" "$BACKUP_F25"
sum_live25_before="$(checksum "$LIVE_F25")"
sum_outside25_before="$(checksum "$OUTSIDE25")"
out25="$(bash "$SCRIPT" --path "$D" --write --overwrite-live 2>&1)"; rc25=$?
sum_live25_after="$(checksum "$LIVE_F25")"
sum_outside25_after="$(checksum "$OUTSIDE25")"
if [ "$rc25" -ne 0 ] && [ "$sum_live25_before" = "$sum_live25_after" ] && [ "$sum_outside25_before" = "$sum_outside25_after" ]; then
  ok "25 (MAJEUR #3) BACKUP_PATH symlink préexistant → refus (code!=0), \$LIVE inchangé, cible externe non écrite"
else
  ko "25 (MAJEUR #3) BACKUP_PATH symlink préexistant → refus (code!=0), \$LIVE inchangé, cible externe non écrite" "rc!=0, LIVE inchangé, cible externe inchangée" "rc=$rc25 live_egal=$([ "$sum_live25_before" = "$sum_live25_after" ] && echo oui || echo NON) externe_egal=$([ "$sum_outside25_before" = "$sum_outside25_after" ] && echo oui || echo NON) out=[$out25]"
fi

# --- MUTATION (MAJEUR #3, cas 25) : retirer la garde `[ -L "$BACKUP_PATH" ]` — le mutant doit
# rougir : la cible externe reçoit le contenu du ledger vivant.
MUT25_DIR="$TMP/mut-backupsym"; mkdir -p "$MUT25_DIR"
awk '
  /^  if \[ -L "\$BACKUP_PATH" \]; then$/ { skip = 1; next }
  skip && /^  fi$/ { skip = 0; next }
  skip { next }
  { print }
' "$SCRIPT" > "$MUT25_DIR/restore-requirements-ledger.sh"
cp "$PRIMITIVE" "$MUT25_DIR/"
chmod +x "$MUT25_DIR"/*.sh
guard25_removed=0
grep -q 'BACKUP_PATH.*est un lien symbolique' "$MUT25_DIR/restore-requirements-ledger.sh" || guard25_removed=1
if [ "$guard25_removed" -eq 1 ]; then
  D25M="$(mk_root c25mut)"
  w_milestones "$D25M" "$CLOSED_H2"
  w_archive "$D25M" "demo-v1" "$DEMO_ARCHIVE"
  w_live "$D25M" "$LIVE_CONTENT_25"
  LIVE_F25M="$D25M/.planning/REQUIREMENTS.md"
  BACKUP_F25M="${LIVE_F25M}.bak-demo-v1"
  OUTSIDE25M="$TMP/outside-target-25mut.txt"
  printf 'secret-exterieur-25mut\n' > "$OUTSIDE25M"
  ln -s "$OUTSIDE25M" "$BACKUP_F25M"
  bash "$MUT25_DIR/restore-requirements-ledger.sh" --path "$D25M" --write --overwrite-live >/dev/null 2>&1
  leaked25mut=0
  grep -q 'PRECIEUX-25' "$OUTSIDE25M" 2>/dev/null && leaked25mut=1
  if [ "$leaked25mut" -eq 1 ]; then
    ok "MUTATION 25 (garde symlink retirée) rougit comme attendu : le contenu du ledger vivant fuit vers la cible externe via le lien"
  else
    ko "MUTATION 25 — N'A PAS ROUGI" "PRECIEUX-25 présent dans la cible externe sous la mutation" "absent — discriminance rompue"
  fi
else
  ko "MUTATION 25 — construction du mutant a échoué" "la garde symlink de BACKUP_PATH est retirée du fichier muté" "grep la trouve encore"
fi

# ==================================================================================================
# Cas 26 (correction ciblée post-revue, 2026-08-18) : la garde `vf_ancestor_symlink_found` a un
# TROISIÈME point d'usage — restore-requirements-ledger.sh:105, sur OVERRIDE_ARCHIVE (le seul chemin
# atteignable sous --write --overwrite-live). Les cas 22/25 couvrent les deux points d'usage internes
# à la primitive ; celui-ci couvre l'appel direct dans le script lui-même, resté sans test dédié.
# Même montage que le cas 22 (.planning/milestones symlinké vers l'extérieur) mais combiné à un
# $LIVE PRÉSENT (précondition qui rend --overwrite-live atteignable, seul chemin qui peuple
# OVERRIDE_ARCHIVE) — sans la garde, l'archive externe serait lue via l'ancêtre lien et écrite
# PAR-DESSUS le ledger vivant.
# ==================================================================================================
D="$(mk_root c26)"
w_milestones "$D" "$CLOSED_H2"
OUTSIDE26_DIR="$TMP/outside-secret-26"
mkdir -p "$OUTSIDE26_DIR"
printf '# Requirements: Hostile\n\n### Famille\n\n- [x] **LEAK-26**: exigence venue de HORS du lab\n\n## Traceability\n\n| Requirement | Phase | Status |\n|---|---|---|\n| LEAK-26 | Phase 1 | Done - leak |\n' > "$OUTSIDE26_DIR/demo-v1-REQUIREMENTS.md"
ln -s "$OUTSIDE26_DIR" "$D/.planning/milestones"
LIVE_CONTENT_26=$'# Requirements: Live\n- [x] **PRECIEUX-26**: exigence vivante jamais archivee\n'
w_live "$D" "$LIVE_CONTENT_26"
LIVE_F26="$D/.planning/REQUIREMENTS.md"
sum_live26_before="$(checksum "$LIVE_F26")"
sum_outside26_before="$(checksum "$OUTSIDE26_DIR/demo-v1-REQUIREMENTS.md")"
out26="$(bash "$SCRIPT" --path "$D" --write --overwrite-live 2>&1)"; rc26=$?
sum_live26_after="$(checksum "$LIVE_F26")"
sum_outside26_after="$(checksum "$OUTSIDE26_DIR/demo-v1-REQUIREMENTS.md")"
leak26_in_live=0; grep -q 'LEAK-26' "$LIVE_F26" 2>/dev/null && leak26_in_live=1
if [ "$rc26" -ne 0 ] && [ "$sum_live26_before" = "$sum_live26_after" ] && [ "$sum_outside26_before" = "$sum_outside26_after" ] && [ "$leak26_in_live" -eq 0 ]; then
  ok "26 (3e point d'usage, --write --overwrite-live) ancêtre symlinké → refus (code!=0), \$LIVE inchangé par empreinte, cible externe intacte, LEAK-26 absent du ledger"
else
  ko "26 (3e point d'usage, --write --overwrite-live) ancêtre symlinké → refus (code!=0), \$LIVE inchangé par empreinte, cible externe intacte, LEAK-26 absent du ledger" "rc!=0, empreintes live/externe identiques, LEAK-26 absent" "rc=$rc26 live_egal=$([ "$sum_live26_before" = "$sum_live26_after" ] && echo oui || echo NON) externe_egal=$([ "$sum_outside26_before" = "$sum_outside26_after" ] && echo oui || echo NON) leak_present=$leak26_in_live out=[$out26]"
fi

# --- MUTATION (cas 26) : retirer l'appel à vf_ancestor_symlink_found du SCRIPT lui-même (ligne 105),
# pas de la primitive — le mutant doit rougir : LEAK-26 apparaît dans le ledger vivant écrit.
MUT26_DIR="$TMP/mut-override-ancestor"; mkdir -p "$MUT26_DIR"
awk '
{
  line = $0
  pat = " && ! vf_ancestor_symlink_found \"$_cand_archive\" \"$PLANNING_DIR\""
  idx = index(line, pat)
  if (idx > 0) { line = substr(line, 1, idx - 1) substr(line, idx + length(pat)) }
  print line
}
' "$SCRIPT" > "$MUT26_DIR/restore-requirements-ledger.sh"
cp "$PRIMITIVE" "$MUT26_DIR/"
chmod +x "$MUT26_DIR"/*.sh
guard26_removed=0
grep -q '_cand_archive.*&& ! vf_ancestor_symlink_found' "$MUT26_DIR/restore-requirements-ledger.sh" || guard26_removed=1
if [ "$guard26_removed" -eq 1 ]; then
  D26M="$(mk_root c26mut)"
  w_milestones "$D26M" "$CLOSED_H2"
  OUTSIDE26M_DIR="$TMP/outside-secret-26mut"
  mkdir -p "$OUTSIDE26M_DIR"
  printf '# Requirements: Hostile\n\n### Famille\n\n- [x] **LEAKM-26**: exigence venue de HORS du lab\n\n## Traceability\n\n| Requirement | Phase | Status |\n|---|---|---|\n| LEAKM-26 | Phase 1 | Done - leak |\n' > "$OUTSIDE26M_DIR/demo-v1-REQUIREMENTS.md"
  ln -s "$OUTSIDE26M_DIR" "$D26M/.planning/milestones"
  w_live "$D26M" "$LIVE_CONTENT_26"
  LIVE_F26M="$D26M/.planning/REQUIREMENTS.md"
  bash "$MUT26_DIR/restore-requirements-ledger.sh" --path "$D26M" --write --overwrite-live >/dev/null 2>&1; mut26_rc=$?
  leaked26mut=0; grep -q 'LEAKM-26' "$LIVE_F26M" 2>/dev/null && leaked26mut=1
  if [ "$mut26_rc" -eq 0 ] && [ "$leaked26mut" -eq 1 ]; then
    ok "MUTATION 26 (garde d'ancêtre retirée du 3e point d'usage) rougit comme attendu : LEAKM-26 écrit dans le ledger vivant via l'ancêtre symlinké"
  else
    ko "MUTATION 26 — N'A PAS ROUGI" "code=0 ET LEAKM-26 présent dans le ledger écrit" "rc=$mut26_rc leak_present=$leaked26mut"
  fi
  # Discriminance : le chemin nominal --write --overwrite-live SANS ancêtre symlinké (cas 16) reste
  # VERT sous cette mutation.
  D_CTRL26="$(mk_root c26ctrl)"
  w_milestones "$D_CTRL26" "$CLOSED_H2"
  w_archive "$D_CTRL26" "demo-v1" "$DEMO_ARCHIVE"
  w_live "$D_CTRL26" "$LIVE_CONTENT_26"
  bash "$MUT26_DIR/restore-requirements-ledger.sh" --path "$D_CTRL26" --write --overwrite-live >/dev/null 2>&1; ctrl26_rc=$?
  ctrl26_written=0; grep -q 'AAAA-01' "$D_CTRL26/.planning/REQUIREMENTS.md" 2>/dev/null && ctrl26_written=1
  if [ "$ctrl26_rc" -eq 0 ] && [ "$ctrl26_written" -eq 1 ]; then
    ok "MUTATION 26 — le cas nominal --overwrite-live sans ancêtre lien (cas 16) reste VERT sous cette mutation (discriminance)"
  else
    ko "MUTATION 26 — discriminance rompue, le cas nominal est affecté aussi" "cas nominal inchangé (rc=0, AAAA-01 écrit)" "rc=$ctrl26_rc écrit=$ctrl26_written"
  fi
else
  ko "MUTATION 26 — construction du mutant a échoué" "l'appel vf_ancestor_symlink_found sur _cand_archive est retiré du fichier muté" "grep le trouve encore"
fi

# ==================================================================================================
# Cas 27 (BLOQUANT G1, correction ciblée post-vérification 2026-08-18) : portabilité CRLF (ADR-054).
# Rejeu de la MÊME archive `$DEMO_ARCHIVE` (comptes de référence déjà établis par le cas 4 : 2
# Garanties, 2 Voyage, 1 caduque, 1 forme non reconnue) mais en CRLF de bout en bout (MILESTONES.md
# ET l'archive). Reproduit par exécution AVANT correctif sur cette même fixture :
# `Garanties: 0, Voyage: 4` — chaque item classé code 1 (perdant sa classification garantie/caduque
# réelle) parce que le `\r` résiduel en fin de ligne de corps déplaçait l'extraction d'ID côté awk et
# cassait la jonction body/trace. Rouge avant ce correctif (reproduit ci-dessus par exécution
# indépendante sur le code pré-correctif), vert après.
# ==================================================================================================
D="$(mk_root c27)"
printf '# Milestones\r\n\r\n## \xe2\x9c\x85 demo-v1 \xe2\x80\x94 Un jalon clos (fixture de test)\r\n' > "$D/.planning/MILESTONES.md"
mkdir -p "$D/.planning/milestones"
CRLF_DEMO_ARCHIVE="${DEMO_ARCHIVE//$'\n'/$'\r\n'}"
printf '%s' "$CRLF_DEMO_ARCHIVE" > "$D/.planning/milestones/demo-v1-REQUIREMENTS.md"
out27="$(bash "$SCRIPT" --path "$D" --write 2>/dev/null)"; rc27=$?
F27="$D/.planning/REQUIREMENTS.md"
counts_ok=0
case "$out27" in *"Garanties: 2, Voyage: 2, Caduques laissées en archive: 1, Forme non reconnue (stderr): 1"*) counts_ok=1 ;; esac
no_cr_written=0
if [ -f "$F27" ] && ! grep -q $'\r' "$F27"; then no_cr_written=1; fi
if [ "$rc27" -eq 0 ] && [ "$counts_ok" -eq 1 ] && [ "$no_cr_written" -eq 1 ]; then
  ok "27 (G1) archive et MILESTONES.md en CRLF → mêmes comptes que le baseline LF (2/2/1/1), fichier écrit sans \\r résiduel"
else
  ko "27 (G1) archive et MILESTONES.md en CRLF → mêmes comptes que le baseline LF (2/2/1/1), fichier écrit sans \\r résiduel" "rc=0, Garanties: 2, Voyage: 2, Caduques: 1, code3: 1, aucun \\r dans le fichier écrit" "rc=$rc27 out=[$out27] cr_absent=$no_cr_written"
fi

# --- MUTATION G1 (archive) : retirer la normalisation CRLF de la double lecture de l'archive dans
# une COPIE de la primitive-consommatrice (restore-requirements-ledger.sh lui-même, la substitution
# de processus vit dans CE script, pas dans la primitive) — doit faire ROUGIR le cas 27 (comptes
# faux sous CRLF), en laissant VERT le cas 4 (même archive, LF, non affecté par la mutation).
MUT27_DIR="$TMP/mut-g1-archive"; mkdir -p "$MUT27_DIR"
cp "$PRIMITIVE" "$MUT27_DIR/"
sed "s#' <(tr -d '\\\\r' < \"\$ARCHIVE\") <(tr -d '\\\\r' < \"\$ARCHIVE\") > \"\$TMPD/tuples.tsv\"#' \"\$ARCHIVE\" \"\$ARCHIVE\" > \"\$TMPD/tuples.tsv\"#" "$SCRIPT" > "$MUT27_DIR/restore-requirements-ledger.sh"
chmod +x "$MUT27_DIR"/*.sh
guard27_removed=0
grep -qF "' \"\$ARCHIVE\" \"\$ARCHIVE\" > \"\$TMPD/tuples.tsv\"" "$MUT27_DIR/restore-requirements-ledger.sh" && guard27_removed=1
bash -n "$MUT27_DIR/restore-requirements-ledger.sh" 2>/dev/null || guard27_removed=0
if [ "$guard27_removed" -eq 1 ]; then
  D27M="$(mk_root c27mut)"
  printf '# Milestones\r\n\r\n## \xe2\x9c\x85 demo-v1 \xe2\x80\x94 Un jalon clos (fixture de test)\r\n' > "$D27M/.planning/MILESTONES.md"
  mkdir -p "$D27M/.planning/milestones"
  printf '%s' "$CRLF_DEMO_ARCHIVE" > "$D27M/.planning/milestones/demo-v1-REQUIREMENTS.md"
  out27mut="$(bash "$MUT27_DIR/restore-requirements-ledger.sh" --path "$D27M" --write 2>/dev/null)"
  counts_mut_ok=0
  case "$out27mut" in *"Garanties: 2, Voyage: 2, Caduques laissées en archive: 1, Forme non reconnue (stderr): 1"*) counts_mut_ok=1 ;; esac
  if [ "$counts_mut_ok" -eq 0 ]; then
    ok "MUTATION G1 (normalisation CRLF de l'archive retirée) rougit le cas 27 comme attendu : comptes faux sous CRLF"
  else
    ko "MUTATION G1 — N'A PAS ROUGI" "les comptes divergent du baseline sous la mutation" "out=[$out27mut]"
  fi
  D27CTRL="$(mk_root c27ctrl)"
  w_milestones "$D27CTRL" "$CLOSED_H2"
  w_archive "$D27CTRL" "demo-v1" "$DEMO_ARCHIVE"
  out27ctrl="$(bash "$MUT27_DIR/restore-requirements-ledger.sh" --path "$D27CTRL" --write 2>/dev/null)"
  counts_ctrl_ok=0
  case "$out27ctrl" in *"Garanties: 2, Voyage: 2, Caduques laissées en archive: 1, Forme non reconnue (stderr): 1"*) counts_ctrl_ok=1 ;; esac
  if [ "$counts_ctrl_ok" -eq 1 ]; then
    ok "MUTATION G1 — le cas 4 (même archive, LF) reste VERT sous cette mutation (discriminance)"
  else
    ko "MUTATION G1 — discriminance rompue, cas 4 affecté aussi" "comptes inchangés (2/2/1/1)" "out=[$out27ctrl]"
  fi
else
  ko "MUTATION G1 — construction du mutant a échoué" "la double lecture normalisée est retirée du fichier muté" "grep ne la trouve pas / bash -n échoue"
fi

echo ""
echo "== résultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
