#!/usr/bin/env bash
# test-check-requirements-survival.sh — Suite de vérification de check-requirements-survival.sh et
# de sa primitive requirements-survival-detect.sh (LEDG-02, plan 18-01).
#
# Harness sur le modèle de test-check-doc-drift.sh : mktemp -d avec trap, un dossier de fixture
# jetable par cas, jamais le .planning/ réel de ce dépôt. Aucun dépôt git n'est requis (contrairement
# à check-doc-drift.sh) : les fixtures sont de simples arborescences de fichiers.
#
# Les cinq issues QUAL-01 sur CE gate (A-18-01 du plan 18-01) :
#   issue 1    — SILENCE   : ledger présent sans ID disparu, ou aucun jalon clos, ou pas de .planning/
#   issue 2    — SIGNAL    : [ledger-absent] — jalon clos ET REQUIREMENTS.md absent
#   issue 2bis — SIGNAL    : [ledger-exigences-disparues] — REQUIREMENTS.md présent, ID disparu (A-18-08)
#   issue 3    — BRUYANT   : [ledger-illisible] — MILESTONES.md/traces malformés, jamais un vert
#   issue 4    — BRUYANT   : [ledger-outil-absent] — primitive introuvable
#
# Chaque cas capture stdout ET le code de retour dans deux variables DISTINCTES, assertées
# séparément — jamais une assertion combinée qui déduit l'un de l'autre. Chaque échec imprime une
# trace à trois champs (assertion / attendu / obtenu), jamais un simple "KO" muet.
#
# Discrimination par MUTATION (5, une par issue) : chaque mutation est jouée sur une COPIE du script
# sous mktemp -d, jamais sur le fichier vivant — vérifié en fin de suite par une empreinte du dépôt.

set -uo pipefail

SCRIPTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GATE="$SCRIPTS_DIR/check-requirements-survival.sh"
PRIMITIVE="$SCRIPTS_DIR/requirements-survival-detect.sh"
# Référence pour les guards de mutation issue2bis/issue3/issue4 (sed cible "exit 0" → "hook_exit 3"
# dans une seule branche du case) : le décompte du fichier vivant sert de zéro avant mutation.
BASE_HOOKEXIT3_COUNT="$(grep -c "hook_exit 3" "$GATE")"

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
# ko <assertion> <attendu> <obtenu> — trace à trois champs distincts, jamais un "KO" muet.
ko() {
  echo "  ✗ $1"
  echo "    assertion : $1"
  echo "    attendu   : $2"
  echo "    obtenu    : $3"
  FAIL=$((FAIL+1))
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# ==================================================================================================
# Constructeurs de fixture — arborescences de fichiers pures, jamais le .planning/ réel.
# ==================================================================================================

# mk_root <name> -> imprime <path>/.planning créé (vide, pas encore de MILESTONES.md)
mk_root() {
  local d="$TMP/$1"
  mkdir -p "$d/.planning" || { echo "  ✗ FIXTURE — mkdir $d/.planning impossible" >&2; exit 1; }
  printf '%s' "$d"
}

CLOSED_H2='## ✅ demo-v1 — Un jalon clos (fixture de test)'

w_milestones() { # <root> <heading-body>
  printf '# Milestones\n\n%s\n\nDétail.\n' "$2" > "$1/.planning/MILESTONES.md"
}

w_archive() { # <root> <label> <content>
  mkdir -p "$1/.planning/milestones"
  printf '%s' "$3" > "$1/.planning/milestones/${2}-REQUIREMENTS.md"
}

w_live() { # <root> <content>
  printf '%s' "$2" > "$1/.planning/REQUIREMENTS.md"
}

w_armed() { # <root>
  : > "$1/.planning/.requirements-survival-armed"
}

# Archive minimale à un ID garanti (traçabilité présente, aucun jeton caduc).
archive_one_id() { # <id> [annotation]
  printf -- '- [x] **%s**%s: texte de l'"'"'exigence\n\n## Traceability\n\n| Requirement | Phase | Status |\n|---|---|---|\n| %s | Phase 1 | Done |\n' "$1" "${2:-}" "$1"
}

echo "== test-check-requirements-survival =="

# === Cas 1 — pas de répertoire de planning du tout : stdout vide, code 3 ==========================
D="$TMP/no-planning-1"; mkdir -p "$D"
out="$(bash "$GATE" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "1 pas de .planning/ du tout → silence, code 3"; else ko "1 pas de .planning/ du tout → silence, code 3" "rc=3 out=[]" "rc=$rc out=[$out]"; fi

# === Cas 2 — .planning/ sans MILESTONES.md : stdout vide, code 3 ==================================
D="$(mk_root c2)"
out="$(bash "$GATE" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "2 .planning/ sans MILESTONES.md → silence, code 3"; else ko "2 .planning/ sans MILESTONES.md → silence, code 3" "rc=3 out=[]" "rc=$rc out=[$out]"; fi

# === Cas 3 — titres H2 présents, aucun jalon clos, ledger absent : stdout vide, code 3 =============
D="$(mk_root c3)"
w_milestones "$D" '## en cours — Jalon pas fini'
out="$(bash "$GATE" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "3 H2 présents, aucun clos, ledger absent → silence, code 3"; else ko "3 H2 présents, aucun clos, ledger absent → silence, code 3" "rc=3 out=[]" "rc=$rc out=[$out]"; fi

# === Cas 4 — jalon clos ET ledger présent (sans archive) : stdout vide, code 3 =====================
D="$(mk_root c4)"
w_milestones "$D" "$CLOSED_H2"
w_live "$D" $'# Requirements\n- [x] **QQQQ-01**: sans rapport\n'
out="$(bash "$GATE" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "4 jalon clos et ledger présent → silence, code 3"; else ko "4 jalon clos et ledger présent → silence, code 3" "rc=3 out=[]" "rc=$rc out=[$out]"; fi

# === Cas 5 — jalon clos, ledger absent, archive présente : [ledger-absent] + libellé, code 0 ========
D="$(mk_root c5)"
w_milestones "$D" "$CLOSED_H2"
w_archive "$D" "demo-v1" "$(archive_one_id AAAA-01)"
out="$(bash "$GATE" --path "$D" 2>/dev/null)"; rc=$?
has=0; case "$out" in "[ledger-absent]"*"demo-v1"*) has=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ]; then ok "5 jalon clos, ledger absent, archive présente → [ledger-absent] + libellé, code 0"; else ko "5 jalon clos, ledger absent, archive présente → [ledger-absent] + libellé, code 0" "rc=0 out contient [ledger-absent] et demo-v1" "rc=$rc out=[$out]"; fi

# === Cas 6 — ledger absent, archive absente, marqueur absent : stdout vide, code 3 (cran avertissement) ==
D="$(mk_root c6)"
w_milestones "$D" "$CLOSED_H2"
out="$(bash "$GATE" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "6 ledger absent, archive absente, marqueur absent → silence (A-18-02)"; else ko "6 ledger absent, archive absente, marqueur absent → silence (A-18-02)" "rc=3 out=[]" "rc=$rc out=[$out]"; fi

# === Cas 7 — même fixture, marqueur d'armement présent : signal distinct, code 0 ===================
D="$(mk_root c7)"
w_milestones "$D" "$CLOSED_H2"
w_armed "$D"
out="$(bash "$GATE" --path "$D" 2>/dev/null)"; rc=$?
has=0; case "$out" in "[ledger-absent]"*"aucune archive"*) has=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ]; then ok "7 même fixture armée → constat distinct « aucune archive », code 0"; else ko "7 même fixture armée → constat distinct « aucune archive », code 0" "rc=0 out contient aucune archive" "rc=$rc out=[$out]"; fi

# === Cas 8 — MILESTONES.md sans aucun titre H2 : [ledger-illisible] no_heading, code 0 =============
D="$(mk_root c8)"
printf '# Milestones\nprose seulement, aucun H2 ici\n' > "$D/.planning/MILESTONES.md"
out="$(bash "$GATE" --path "$D" 2>/dev/null)"; rc=$?
has=0; case "$out" in "[ledger-illisible]"*"no_heading"*) has=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ]; then ok "8 aucun H2 → [ledger-illisible] no_heading, code 0"; else ko "8 aucun H2 → [ledger-illisible] no_heading, code 0" "rc=0 out contient no_heading" "rc=$rc out=[$out]"; fi

# === Cas 9 — libellé hors liste blanche (caractère de contrôle) : illisible, jamais réimprimé =======
D="$(mk_root c9)"
printf '## \xe2\x9c\x85 bad\x01name \xe2\x80\x94 clos\n' > "$D/.planning/MILESTONES.md"
out="$(bash "$GATE" --path "$D" 2>/dev/null)"; rc=$?
has=0; case "$out" in "[ledger-illisible]"*"label_rejected"*) has=1 ;; esac
leaked=0; printf '%s' "$out" | grep -q $'\x01' && leaked=1
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ] && [ "$leaked" -eq 0 ]; then ok "9 libellé hors liste blanche → illisible label_rejected, valeur brute jamais réimprimée (T-18-01)"; else ko "9 libellé hors liste blanche → illisible label_rejected, valeur brute jamais réimprimée (T-18-01)" "rc=0 out contient label_rejected, aucun octet de contrôle" "rc=$rc out=[$out] leaked=$leaked"; fi

# === Cas 10 — trace carried-from: malformée : illisible trace_malformed, code 0 ====================
D="$(mk_root c10)"
w_milestones "$D" "$CLOSED_H2"
w_live "$D" $'# Requirements\n- [ ] **RRRR-01**: exigence carried-from:!!! forme cassée\n'
out="$(bash "$GATE" --path "$D" 2>/dev/null)"; rc=$?
has=0; case "$out" in "[ledger-illisible]"*"trace_malformed"*) has=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ]; then ok "10 trace carried-from: malformée → illisible trace_malformed, code 0"; else ko "10 trace carried-from: malformée → illisible trace_malformed, code 0" "rc=0 out contient trace_malformed" "rc=$rc out=[$out]"; fi

# === Cas 11 — trace carried-from: bien formée : stdout vide, code 3 (jamais un FAIL sur le contenu) =
D="$(mk_root c11)"
w_milestones "$D" "$CLOSED_H2"
w_live "$D" $'# Requirements\n- [ ] **SSSS-01**: exigence voyageuse carried-from: v1.2\n'
out="$(bash "$GATE" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "11 trace carried-from: bien formée → silence, code 3 (D-18-10)"; else ko "11 trace carried-from: bien formée → silence, code 3 (D-18-10)" "rc=3 out=[]" "rc=$rc out=[$out]"; fi

# === Cas 12 — primitive introuvable : [ledger-outil-absent], code 0 ===============================
D="$TMP/isolated-gate"; mkdir -p "$D"
cp "$GATE" "$D/"
out="$(bash "$D/check-requirements-survival.sh" --path "$TMP" 2>/dev/null)"; rc=$?
has=0; case "$out" in "[ledger-outil-absent]"*) has=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ]; then ok "12 primitive introuvable → [ledger-outil-absent], code 0"; else ko "12 primitive introuvable → [ledger-outil-absent], code 0" "rc=0 out commence par [ledger-outil-absent]" "rc=$rc out=[$out]"; fi

# === Cas 13 (OBLIGATOIRE, issue 2bis) — exigence supprimée d'un REQUIREMENTS.md TOUJOURS présent ===
# JAMAIS nominal, JAMAIS code 3 : c'est le cas qui prouve que LEDG-02 couvre le volet « exigence
# disparue du ledger vivant », pas seulement le volet « fichier absent ».
D="$(mk_root c13)"
w_milestones "$D" "$CLOSED_H2"
w_archive "$D" "demo-v1" "$(archive_one_id XXXX-01)"
w_live "$D" $'# Requirements\n- [x] **YYYY-99**: sans rapport\n'
out="$(bash "$GATE" --path "$D" 2>/dev/null)"; rc=$?
has=0; case "$out" in "[ledger-exigences-disparues]"*"XXXX-01"*) has=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ]; then ok "13 (OBLIGATOIRE) ID garanti disparu d'un ledger PRÉSENT → [ledger-exigences-disparues], code 0, JAMAIS nominal"; else ko "13 (OBLIGATOIRE) ID garanti disparu d'un ledger PRÉSENT → [ledger-exigences-disparues], code 0, JAMAIS nominal" "rc=0 out contient [ledger-exigences-disparues] et XXXX-01" "rc=$rc out=[$out]"; fi

# === Cas 14 — non-régression fait n°1 (A-18-08) : caduc SEULEMENT sur la ligne de traçabilité =======
D="$(mk_root c14)"
w_milestones "$D" "$CLOSED_H2"
w_archive "$D" "demo-v1" $'- [~] **VERB-02** *(partiel — 17/18)*: 18 nouveaux verbes livrés\n\n## Traceability\n\n| Requirement | Phase | Status |\n|---|---|---|\n| VERB-02 | Phase 12 | Livré — **caduc depuis v2.33.0** |\n'
w_live "$D" $'# Requirements\n- [x] **ZZZZ-01**: rien\n'
out="$(bash "$GATE" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "14 non-régression fait n°1 — caduc sur la traçabilité seule (VERB-02) → exclu du diff, silence"; else ko "14 non-régression fait n°1 — caduc sur la traçabilité seule (VERB-02) → exclu du diff, silence" "rc=3 out=[]" "rc=$rc out=[$out]"; fi

# === Cas 15 — non-régression fait n°2 (A-18-08) : annotation intercalée, ID quand même extrait ======
D="$(mk_root c15)"
w_milestones "$D" "$CLOSED_H2"
w_archive "$D" "demo-v1" "$(archive_one_id XXXX-02 ' *(annotation entre l'"'"'id et les deux-points)*')"
w_live "$D" $'# Requirements\n- [x] **ZZZZ-01**: rien\n'
out="$(bash "$GATE" --path "$D" 2>/dev/null)"; rc=$?
has=0; case "$out" in "[ledger-exigences-disparues]"*"XXXX-02"*) has=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ]; then ok "15 non-régression fait n°2 — annotation intercalée n'empêche pas l'extraction de l'ID (XXXX-02)"; else ko "15 non-régression fait n°2 — annotation intercalée n'empêche pas l'extraction de l'ID (XXXX-02)" "rc=0 out contient [ledger-exigences-disparues] et XXXX-02" "rc=$rc out=[$out]"; fi

# === Cas 16 — non-régression fait n°3 (A-18-08) : ID de corps SANS ligne de traçabilité, exclu ======
D="$(mk_root c16)"
w_milestones "$D" "$CLOSED_H2"
w_archive "$D" "demo-v1" $'- [x] **NOTR-01**: sans traçabilité\n\n## Traceability\n\n| Requirement | Phase | Status |\n|---|---|---|\n'
w_live "$D" $'# Requirements\n- [x] **ZZZZ-01**: rien\n'
out="$(bash "$GATE" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "16 non-régression fait n°3 — ID de corps sans traçabilité → exclu du diff, jamais compté disparu"; else ko "16 non-régression fait n°3 — ID de corps sans traçabilité → exclu du diff, jamais compté disparu" "rc=3 out=[]" "rc=$rc out=[$out]"; fi

# === Cas 17 — diff sans effet quand rien ne manque (ID garanti présent dans le vivant) ==============
D="$(mk_root c17)"
w_milestones "$D" "$CLOSED_H2"
w_archive "$D" "demo-v1" "$(archive_one_id XXXX-04)"
w_live "$D" $'# Requirements\n- [x] **XXXX-04**: présent dans le vivant aussi\n'
out="$(bash "$GATE" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "17 diff d'IDs sans effet quand l'ID garanti est présent dans le vivant → silence"; else ko "17 diff d'IDs sans effet quand l'ID garanti est présent dans le vivant → silence" "rc=3 out=[]" "rc=$rc out=[$out]"; fi

# === Cas 18 (OBLIGATOIRE, N1) — ID vivant écrit SANS case à cocher (forme VOC-01/VOC-02) ============
D="$(mk_root c18)"
w_milestones "$D" "$CLOSED_H2"
w_archive "$D" "demo-v1" "$(archive_one_id XXXX-03)"
w_live "$D" $'# Requirements\n- **XXXX-03**: forme sans case à cocher, comme VOC-01/VOC-02\n'
out="$(bash "$GATE" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "18 (OBLIGATOIRE N1) ID vivant sans case à cocher → PAS déclaré disparu, extraction côté vivant laxe"; else ko "18 (OBLIGATOIRE N1) ID vivant sans case à cocher → PAS déclaré disparu, extraction côté vivant laxe" "rc=3 out=[]" "rc=$rc out=[$out]"; fi

# === Cas 19 — parité d'interface : --hook+--quiet, argument inconnu, --path sans valeur → 64 ========
bash "$GATE" --hook --quiet >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 64 ]; then ok "19a --hook et --quiet ensemble → code 64"; else ko "19a --hook et --quiet ensemble → code 64" "rc=64" "rc=$rc"; fi
bash "$GATE" --nope >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 64 ]; then ok "19b argument inconnu → code 64"; else ko "19b argument inconnu → code 64" "rc=64" "rc=$rc"; fi
bash "$GATE" --path >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 64 ]; then ok "19c --path sans valeur → code 64"; else ko "19c --path sans valeur → code 64" "rc=64" "rc=$rc"; fi
out="$(bash "$GATE" --help 2>/dev/null)"; rc=$?
if [ "$rc" -eq 0 ] && [ -n "$out" ]; then ok "19d --help → code 0, sortie non vide"; else ko "19d --help → code 0, sortie non vide" "rc=0 out non vide" "rc=$rc out=[$out]"; fi

# === Cas 20 — traduction sous --hook : silence STRICT (zéro octet, compté), code 0 ==================
D="$(mk_root c20)"
w_milestones "$D" "$CLOSED_H2"
out="$(bash "$GATE" --path "$D" --hook 2>/dev/null)"; rc=$?
nbytes="${#out}"
if [ "$rc" -eq 0 ] && [ "$nbytes" -eq 0 ]; then ok "20 --hook traduit le silence (3→0), stdout STRICTEMENT vide (0 octet)"; else ko "20 --hook traduit le silence (3→0), stdout STRICTEMENT vide (0 octet)" "rc=0 octets=0" "rc=$rc octets=$nbytes"; fi

# === Cas 21 — lecture seule : empreinte find identique avant/après exécution ========================
D="$(mk_root c21)"
w_milestones "$D" "$CLOSED_H2"
w_archive "$D" "demo-v1" "$(archive_one_id AAAA-01)"
before="$(find "$D" | LC_ALL=C sort)"
bash "$GATE" --path "$D" >/dev/null 2>&1
after="$(find "$D" | LC_ALL=C sort)"
if [ "$before" = "$after" ]; then ok "21 lecture seule — empreinte find identique avant/après"; else ko "21 lecture seule — empreinte find identique avant/après" "before == after" "before=[$before] after=[$after]"; fi

# === Cas 22 — déterminisme : deux exécutions consécutives, même stdout et même code =================
D="$(mk_root c22)"
w_milestones "$D" "$CLOSED_H2"
w_archive "$D" "demo-v1" "$(archive_one_id XXXX-01)"
w_live "$D" $'# Requirements\n- [x] **YYYY-99**: sans rapport\n'
out1="$(bash "$GATE" --path "$D" 2>/dev/null)"; rc1=$?
out2="$(bash "$GATE" --path "$D" 2>/dev/null)"; rc2=$?
if [ "$rc1" -eq "$rc2" ] && [ "$out1" = "$out2" ]; then ok "22 déterminisme — deux exécutions consécutives, même stdout et même code"; else ko "22 déterminisme — deux exécutions consécutives, même stdout et même code" "rc1==rc2, out1==out2" "rc1=$rc1 rc2=$rc2 out1=[$out1] out2=[$out2]"; fi

# === Cas 23 — bash -n passe sur les deux scripts neufs ==============================================
if bash -n "$GATE" 2>/dev/null && bash -n "$PRIMITIVE" 2>/dev/null; then ok "23 bash -n passe sur check-requirements-survival.sh et requirements-survival-detect.sh"; else ko "23 bash -n passe sur check-requirements-survival.sh et requirements-survival-detect.sh" "bash -n OK sur les deux" "au moins un des deux échoue"; fi

# === Cas 24 — mention NUE du jeton carried-from: en prose (cas réel .planning/REQUIREMENTS.md:932) ===
# n'est PAS une tentative de trace : silence, jamais illisible. Couvre le correctif appliqué en
# cours de rédaction de la primitive (regex de bare-mention), jusque-là non testé explicitement.
D="$(mk_root c24)"
w_milestones "$D" "$CLOSED_H2"
w_live "$D" $'# Requirements\n- [ ] **LEDG-01**: convention décrite en prose, trace `carried-from:`\n'
out="$(bash "$GATE" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "24 mention nue de carried-from: en prose (backtick, sans valeur) → silence, jamais illisible"; else ko "24 mention nue de carried-from: en prose (backtick, sans valeur) → silence, jamais illisible" "rc=3 out=[]" "rc=$rc out=[$out]"; fi

# === Cas 25 — le diff d'IDs tourne INDÉPENDAMMENT de VF_LEDGER_ARMED (A-18-08) : marqueur présent ===
# ET ID disparu → le signal [ledger-exigences-disparues] sort quand même (jamais absorbé par le cran
# d'armement, qui ne régit QUE le cas « archive absente », pas le diff d'IDs).
D="$(mk_root c25)"
w_milestones "$D" "$CLOSED_H2"
w_armed "$D"
w_archive "$D" "demo-v1" "$(archive_one_id XXXX-05)"
w_live "$D" $'# Requirements\n- [x] **YYYY-99**: sans rapport\n'
out="$(bash "$GATE" --path "$D" 2>/dev/null)"; rc=$?
has=0; case "$out" in "[ledger-exigences-disparues]"*"XXXX-05"*) has=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ]; then ok "25 diff d'IDs indépendant de VF_LEDGER_ARMED — signal émis même marqueur présent"; else ko "25 diff d'IDs indépendant de VF_LEDGER_ARMED — signal émis même marqueur présent" "rc=0 out contient [ledger-exigences-disparues] et XXXX-05" "rc=$rc out=[$out]"; fi

# === Cas 26 — plusieurs IDs disparus : compte exact + jusqu'à 5 IDs listés, jamais tronqué en dessous
D="$(mk_root c26)"
w_milestones "$D" "$CLOSED_H2"
w_archive "$D" "demo-v1" $'- [x] **MMMM-01**: un\n- [x] **MMMM-02**: deux\n- [x] **MMMM-03**: trois\n\n## Traceability\n\n| Requirement | Phase | Status |\n|---|---|---|\n| MMMM-01 | Phase 1 | Done |\n| MMMM-02 | Phase 1 | Done |\n| MMMM-03 | Phase 1 | Done |\n'
w_live "$D" $'# Requirements\n- [x] **YYYY-99**: sans rapport\n'
out="$(bash "$GATE" --path "$D" 2>/dev/null)"; rc=$?
has_count=0; case "$out" in "[ledger-exigences-disparues] 3 "*) has_count=1 ;; esac
# Correctif MOYEN (2026-08-18, revue de code) : la branche tautologique `*MMMM-01*|*MMMM-02*|*MMMM-03*`
# mettait has_ids=1 dès qu'UN SEUL des trois IDs était présent, neutralisant l'intention « jamais
# tronqué » — un mutant tronquant à 1 ID ne rougissait pas sous cette assertion. Seule la branche
# exigeant les TROIS IDs subsiste désormais.
has_ids=0; case "$out" in *"MMMM-01"*"MMMM-02"*"MMMM-03"*) has_ids=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has_count" -eq 1 ] && [ "$has_ids" -eq 1 ]; then ok "26 plusieurs IDs disparus → compte exact (3), IDs listés"; else ko "26 plusieurs IDs disparus → compte exact (3), IDs listés" "rc=0 out commence par [ledger-exigences-disparues] 3 et cite les IDs" "rc=$rc out=[$out]"; fi

# === Cas 27 — jalon OUVERT listé AVANT le jalon clos : le premier CLOS (pas le premier H2) est retenu
D="$(mk_root c27)"
printf '# Milestones\n\n## en cours — Jalon pas fini\n\n%s\n' "$CLOSED_H2" > "$D/.planning/MILESTONES.md"
w_archive "$D" "demo-v1" "$(archive_one_id AAAA-01)"
out="$(bash "$GATE" --path "$D" 2>/dev/null)"; rc=$?
has=0; case "$out" in "[ledger-absent]"*"demo-v1"*) has=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ]; then ok "27 H2 ouvert avant le H2 clos → le premier CLOS est retenu (demo-v1), pas le premier H2"; else ko "27 H2 ouvert avant le H2 clos → le premier CLOS est retenu (demo-v1), pas le premier H2" "rc=0 out contient [ledger-absent] et demo-v1" "rc=$rc out=[$out]"; fi

# === Cas 28 (T-18-02) — archive-cible en lien symbolique : traitée comme ABSENTE, jamais suivie =====
# Le chemin d'archive n'est retenu que s'il est un fichier RÉGULIER ([ -f ] ET [ ! -L ]) — un lien
# symbolique vers une cible arbitraire ne doit jamais être lu ni compté comme une archive présente.
D="$(mk_root c28)"
w_milestones "$D" "$CLOSED_H2"
OUTSIDE="$TMP/c28-outside-target.md"
printf -- '- [x] **OOOO-01**: cible hors périmètre, ne doit jamais être lue\n' > "$OUTSIDE"
mkdir -p "$D/.planning/milestones"
ln -s "$OUTSIDE" "$D/.planning/milestones/demo-v1-REQUIREMENTS.md"
out="$(bash "$GATE" --path "$D" 2>/dev/null)"; rc=$?
# Archive symlinkée → traitée comme absente : cran avertissement par défaut (marqueur non posé),
# donc silence — jamais un [ledger-absent] portant un chemin résolu via le lien.
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "28 (T-18-02) archive en lien symbolique → traitée comme absente, jamais suivie"; else ko "28 (T-18-02) archive en lien symbolique → traitée comme absente, jamais suivie" "rc=3 out=[]" "rc=$rc out=[$out]"; fi

# ==================================================================================================
# Cas 29-31 (BLOQUANT #1, correctif 2026-08-18 — revue de code + audit sécurité) : traversée de
# répertoire par le libellé de jalon. La classe de caractères d'origine `^[0-9A-Za-z._ /-]{1,80}$`
# admettait `.` ET `/` SIMULTANÉMENT — une traversée `../` intégrale passait la liste blanche,
# prouvée par exécution réelle avant correctif (`agentique-v1.0-phases/../../../../outside/pwn`,
# répertoire ancre qui existe RÉELLEMENT dans ce dépôt). `/` est désormais exclu de la classe.
# ==================================================================================================

# === Cas 29 — libellé contenant `/` (forme minimale) : label_rejected, jamais réimprimé ============
D="$(mk_root c29)"
printf '## \xe2\x9c\x85 evil/segment \xe2\x80\x94 clos\n' > "$D/.planning/MILESTONES.md"
out="$(bash "$GATE" --path "$D" 2>/dev/null)"; rc=$?
has=0; case "$out" in "[ledger-illisible]"*"label_rejected"*) has=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ]; then ok "29 (BLOQUANT #1) libellé contenant / → label_rejected"; else ko "29 (BLOQUANT #1) libellé contenant / → label_rejected" "rc=0 out contient label_rejected" "rc=$rc out=[$out]"; fi

# === Cas 30 — libellé portant une séquence de traversée `..` COMBINÉE à `/` : label_rejected =======
D="$(mk_root c30)"
printf '## \xe2\x9c\x85 a/../b \xe2\x80\x94 clos\n' > "$D/.planning/MILESTONES.md"
out="$(bash "$GATE" --path "$D" 2>/dev/null)"; rc=$?
has=0; case "$out" in "[ledger-illisible]"*"label_rejected"*) has=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ]; then ok "30 (BLOQUANT #1) libellé contenant .. avec / → label_rejected"; else ko "30 (BLOQUANT #1) libellé contenant .. avec / → label_rejected" "rc=0 out contient label_rejected" "rc=$rc out=[$out]"; fi

# === Cas 31 — PoC COMPLET, ancre réelle `agentique-v1.0-phases/` : rejeté, RIEN hors périmètre lu ===
# Reproduit exactement le PoC de la revue : le libellé remonte de .planning/milestones/<ancre>/
# jusqu'au parent de la fixture (4 niveaux) puis vise outside/pwn-REQUIREMENTS.md, HORS de $D.
D="$(mk_root c31)"
w_milestones "$D" '## ✅ agentique-v1.0-phases/../../../../outside/pwn — clos (PoC traversée)'
mkdir -p "$D/.planning/milestones/agentique-v1.0-phases"
mkdir -p "$TMP/outside"
printf -- '- [x] **SECRET-01**: contenu hors perimetre, ne doit JAMAIS etre lu ni ecrit dans le ledger\n' > "$TMP/outside/pwn-REQUIREMENTS.md"
sum_before="$(cat "$TMP/outside/pwn-REQUIREMENTS.md")"
out="$(bash "$GATE" --path "$D" 2>/dev/null)"; rc=$?
has=0; case "$out" in "[ledger-illisible]"*"label_rejected"*) has=1 ;; esac
leaked=0; printf '%s' "$out" | grep -q 'SECRET-01' && leaked=1
sum_after="$(cat "$TMP/outside/pwn-REQUIREMENTS.md")"
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ] && [ "$leaked" -eq 0 ] && [ "$sum_before" = "$sum_after" ]; then ok "31 (BLOQUANT #1, PoC complet) traversée via agentique-v1.0-phases/../../../../outside/pwn → label_rejected, fichier hors périmètre jamais lu ni modifié"; else ko "31 (BLOQUANT #1, PoC complet) traversée via agentique-v1.0-phases/../../../../outside/pwn → label_rejected, fichier hors périmètre jamais lu ni modifié" "rc=0 label_rejected, aucune fuite, fichier hors périmètre inchangé" "rc=$rc out=[$out] leaked=$leaked inchangé=$([ "$sum_before" = "$sum_after" ] && echo oui || echo non)"; fi

# --- MUTATION BLOQUANT #1 : rétablir `/` dans la classe de caractères du libellé (régression de
# l'état d'origine) — doit faire ROUGIR les cas 29/31 (la traversée redevient acceptée) et laisser
# VERT un cas de libellé légitime SANS `/` (cas 5, demo-v1).
MTRAV_DIR="$TMP/mut-traversal"; mkdir -p "$MTRAV_DIR"
cp "$GATE" "$MTRAV_DIR/"
sed "s/\[0-9A-Za-z\._ -\]{1,80}\\\$'; then/[0-9A-Za-z._ \/-]{1,80}\$'; then/" "$PRIMITIVE" > "$MTRAV_DIR/requirements-survival-detect.sh"
chmod +x "$MTRAV_DIR/check-requirements-survival.sh" "$MTRAV_DIR/requirements-survival-detect.sh"
# Contrôle : la mutation a bien réintroduit `/` dans le fichier muté (sinon le test suivant ne
# prouverait rien) — assertion sur le texte du mutant lui-même.
if grep -q "\[0-9A-Za-z\._ /-\]{1,80}\\\$" "$MTRAV_DIR/requirements-survival-detect.sh"; then
  D="$(mk_root cm-trav)"
  w_milestones "$D" '## ✅ agentique-v1.0-phases/../../../../outside/pwn-mut — clos (PoC traversée)'
  mkdir -p "$D/.planning/milestones/agentique-v1.0-phases"
  printf -- '- [x] **SECRET-02**: contenu hors perimetre\n' > "$TMP/outside/pwn-mut-REQUIREMENTS.md"
  out_mut="$(bash "$MTRAV_DIR/check-requirements-survival.sh" --path "$D" 2>/dev/null)"; rc_mut=$?
  rejected_mut=0; case "$out_mut" in "[ledger-illisible]"*"label_rejected"*) rejected_mut=1 ;; esac
  if [ "$rejected_mut" -eq 0 ]; then ok "MUTATION BLOQUANT #1 (/ réintroduit) rougit le cas 31 comme attendu : le libellé de traversée n'est plus rejeté"; else ko "MUTATION BLOQUANT #1 — N'A PAS ROUGI" "le libellé de traversée devient accepté sous la mutation" "toujours rejeté (label_rejected)"; fi
  # Contrôle de discriminance : un libellé légitime sans `/` (demo-v1) reste inchangé sous la mutation.
  D2="$(mk_root cm-trav-controle)"
  w_milestones "$D2" "$CLOSED_H2"
  w_archive "$D2" "demo-v1" "$(archive_one_id AAAA-01)"
  out_ctrl="$(bash "$MTRAV_DIR/check-requirements-survival.sh" --path "$D2" 2>/dev/null)"; rc_ctrl=$?
  has_ctrl=0; case "$out_ctrl" in "[ledger-absent]"*"demo-v1"*) has_ctrl=1 ;; esac
  if [ "$rc_ctrl" -eq 0 ] && [ "$has_ctrl" -eq 1 ]; then ok "MUTATION BLOQUANT #1 — le cas 5 (libellé légitime demo-v1) reste VERT sous cette mutation (discriminance)"; else ko "MUTATION BLOQUANT #1 — discriminance rompue, demo-v1 affecté aussi" "cas 5 inchangé" "rc=$rc_ctrl out=[$out_ctrl]"; fi
else
  ko "MUTATION BLOQUANT #1 — construction du mutant a échoué" "le fichier muté réintroduit / dans la classe" "sed n'a pas produit la forme attendue"
fi

# ==================================================================================================
# Cas 32 (MOYEN, correctif 2026-08-18) : trace carried-from: bien formée en PRÉFIXE, suffixe garbage
# — l'ancienne regex non ancrée `carried-from: [0-9A-Za-z._-]{1,80}` matchait comme SOUS-CHAÎNE,
# laissant passer un suffixe garbage pour bien formé au lieu de tomber en illisible (D-18-10).
# ==================================================================================================
D="$(mk_root c32)"
w_milestones "$D" "$CLOSED_H2"
w_live "$D" $'# Requirements\n- [ ] **GARB-01**: exigence voyageuse carried-from: v1.2!!!GARBAGE\n'
out="$(bash "$GATE" --path "$D" 2>/dev/null)"; rc=$?
has=0; case "$out" in "[ledger-illisible]"*"trace_malformed"*) has=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ]; then ok "32 (MOYEN) préfixe valide + suffixe garbage sur carried-from: → illisible trace_malformed (ancrage \$)"; else ko "32 (MOYEN) préfixe valide + suffixe garbage sur carried-from: → illisible trace_malformed (ancrage \$)" "rc=0 out contient trace_malformed" "rc=$rc out=[$out]"; fi

# ==================================================================================================
# Cas 34 (MOYEN, correctif 2026-08-18, référence dangling corrigée en revue tour 2) : ordre
# DÉTERMINISTE de la liste d'IDs disparus tronquée à 5. `for (id in bodyseen)` en awk n'a jamais
# d'ordre garanti (POSIX ne le spécifie pas) — l'ordre d'itération dépend de l'implémentation awk
# (table de hachage interne), donc PEUT diverger de l'ordre alphabétique ET de l'ordre d'insertion
# selon la plateforme (gawk en CI Linux vs awk BSD en local macOS). requirements-survival-detect.sh
# trie désormais explicitement (LC_ALL=C sort) avant toute troncature (voir vf_ledger_state) : ce
# cas prouve que le tri tient, indépendamment de l'ordre d'itération natif d'un awk donné — assertion
# vérifiable ci-dessous par exécution, pas par un résultat d'investigation antérieure non reproduit
# ici.
# ==================================================================================================
D="$(mk_root c34)"
w_milestones "$D" "$CLOSED_H2"
w_archive "$D" "demo-v1" $'- [x] **ZZZZ-01**: un\n- [x] **AAAA-02**: deux\n- [x] **MMMM-03**: trois\n- [x] **BBBB-04**: quatre\n- [x] **YYYY-05**: cinq\n- [x] **KKKK-06**: six\n\n## Traceability\n\n| Requirement | Phase | Status |\n|---|---|---|\n| ZZZZ-01 | Phase 1 | Done |\n| AAAA-02 | Phase 1 | Done |\n| MMMM-03 | Phase 1 | Done |\n| BBBB-04 | Phase 1 | Done |\n| YYYY-05 | Phase 1 | Done |\n| KKKK-06 | Phase 1 | Done |\n'
w_live "$D" $'# Requirements\n- [x] **WWWW-99**: sans rapport\n'
out="$(bash "$GATE" --path "$D" 2>/dev/null)"
sorted_5="AAAA-02 BBBB-04 KKKK-06 MMMM-03 YYYY-05"
has_sorted=0; case "$out" in *"$sorted_5"*) has_sorted=1 ;; esac
if [ "$has_sorted" -eq 1 ]; then ok "34 (MOYEN) 6 IDs disparus → les 5 premiers listés sont TRIÉS alphabétiquement (ordre déterministe), ZZZZ-01 tronqué"; else ko "34 (MOYEN) 6 IDs disparus → les 5 premiers listés sont TRIÉS alphabétiquement (ordre déterministe), ZZZZ-01 tronqué" "sortie contient [$sorted_5]" "out=[$out]"; fi

# --- MUTATION MOYEN (tri) : retirer le tri explicite (LC_ALL=C sort) dans une COPIE de la primitive
# — sur CET awk (ordre de hachage, sondé plus haut, prouvé non alphabétique), la liste tronquée
# n'est plus triée : doit ROUGIR le cas 34, en laissant VERT le cas 26 (3 IDs seulement, aucune
# troncature en jeu, l'ordre alphabétique n'y est pas assertionné).
MUT34_DIR="$TMP/mut-sort"; mkdir -p "$MUT34_DIR"
sed "s/missing_list=\"\$(printf '%s\\\\n' \"\$missing_list\" | tr ' ' '\\\\n' | LC_ALL=C sort | tr '\\\\n' ' ' | sed 's\/ \*\$\/\/')\"/missing_list=\"\$missing_list\"/" "$PRIMITIVE" > "$MUT34_DIR/requirements-survival-detect.sh"
cp "$GATE" "$MUT34_DIR/"
chmod +x "$MUT34_DIR"/*.sh
guard34_removed=0
grep -q "LC_ALL=C sort" "$MUT34_DIR/requirements-survival-detect.sh" || guard34_removed=1
if [ "$guard34_removed" -eq 1 ]; then
  D="$(mk_root cm34)"
  w_milestones "$D" "$CLOSED_H2"
  w_archive "$D" "demo-v1" $'- [x] **ZZZZ-01**: un\n- [x] **AAAA-02**: deux\n- [x] **MMMM-03**: trois\n- [x] **BBBB-04**: quatre\n- [x] **YYYY-05**: cinq\n- [x] **KKKK-06**: six\n\n## Traceability\n\n| Requirement | Phase | Status |\n|---|---|---|\n| ZZZZ-01 | Phase 1 | Done |\n| AAAA-02 | Phase 1 | Done |\n| MMMM-03 | Phase 1 | Done |\n| BBBB-04 | Phase 1 | Done |\n| YYYY-05 | Phase 1 | Done |\n| KKKK-06 | Phase 1 | Done |\n'
  w_live "$D" $'# Requirements\n- [x] **WWWW-99**: sans rapport\n'
  out_mut="$(bash "$MUT34_DIR/check-requirements-survival.sh" --path "$D" 2>/dev/null)"; rc_mut=$?
  if [ "$rc_mut" -eq 126 ] || [ "$rc_mut" -eq 127 ]; then
    # Assertion d'absence (pas de passage par mut_run) : sans cette garde, un harnais cassé
    # (mutant introuvable/non exécutable) produirait un out_mut vide, matchant silencieusement
    # "pas triée" et rendant un ✓ pour la mauvaise raison — même classe que le sentinel HARNESS_BROKEN.
    ko "MUTATION MOYEN (tri retiré) — harnais cassé (rc=$rc_mut)" "exécution normale du mutant (rc ni 126 ni 127)" "rc=$rc_mut — pas une preuve de morsure"
  else
    mut_sorted=0; case "$out_mut" in *"$sorted_5"*) mut_sorted=1 ;; esac
    if [ "$mut_sorted" -eq 0 ]; then ok "MUTATION MOYEN (tri retiré) rougit le cas 34 comme attendu : la liste tronquée n'est plus triée alphabétiquement"; else ko "MUTATION MOYEN — N'A PAS ROUGI" "la liste diverge de l'ordre alphabétique sous la mutation" "toujours triée — mutation sans effet observable"; fi
  fi
  # Contrôle de discriminance : le cas 26 (3 IDs, jamais tronqué) reste inchangé sous la mutation.
  D2="$(mk_root cm34-controle)"
  w_milestones "$D2" "$CLOSED_H2"
  w_archive "$D2" "demo-v1" $'- [x] **MMMM-01**: un\n- [x] **MMMM-02**: deux\n- [x] **MMMM-03**: trois\n\n## Traceability\n\n| Requirement | Phase | Status |\n|---|---|---|\n| MMMM-01 | Phase 1 | Done |\n| MMMM-02 | Phase 1 | Done |\n| MMMM-03 | Phase 1 | Done |\n'
  w_live "$D2" $'# Requirements\n- [x] **YYYY-99**: sans rapport\n'
  out_ctrl="$(bash "$MUT34_DIR/check-requirements-survival.sh" --path "$D2" 2>/dev/null)"; rc_ctrl=$?
  if [ "$rc_ctrl" -eq 126 ] || [ "$rc_ctrl" -eq 127 ]; then
    ko "MUTATION MOYEN — discriminance (cas 26) — harnais cassé (rc=$rc_ctrl)" "exécution normale du mutant (rc ni 126 ni 127)" "rc=$rc_ctrl — pas une preuve de discriminance"
  else
    has_ctrl=0; case "$out_ctrl" in *"MMMM-01"*"MMMM-02"*"MMMM-03"*) has_ctrl=1 ;; esac
    if [ "$has_ctrl" -eq 1 ]; then ok "MUTATION MOYEN — le cas 26 (3 IDs, sans troncature) reste VERT sous cette mutation (discriminance)"; else ko "MUTATION MOYEN — discriminance rompue, cas 26 affecté aussi" "3 IDs toujours listés" "out=[$out_ctrl]"; fi
  fi
else
  ko "MUTATION MOYEN — construction du mutant a échoué" "le fichier muté ne porte plus LC_ALL=C sort" "grep trouve encore LC_ALL=C sort"
fi

# Note : le cas « statut Incomplete ne matche pas complete/done en sous-chaîne » (MOYEN) NE teste
# PAS ce script — `vf_ledger_state` (utilisé ici par check-requirements-survival.sh) ne consulte
# jamais le vocabulaire `complete`/`done`, seulement la présence d'ID (D-18-10). Ce vocabulaire
# n'appartient qu'à `vf_ledger_classify` (LEDG-01, consommée par restore-requirements-ledger.sh) —
# le cas correctement discriminant vit dans test-restore-requirements-ledger.sh.

# ==================================================================================================
# Bloc de mutations — une par issue QUAL-01, jouée sur une COPIE sous mktemp -d, jamais sur le
# fichier vivant. Chaque mutation doit faire ROUGIR le cas visé et laisser VERTS les cas des autres
# issues — une couverture qui ne discrimine pas ne prouve rien.
# ==================================================================================================
echo "== Mutations (discrimination des 5 issues QUAL-01) =="

MUT_TRACE=""
mutant_note() { # <mutation-id> <dims>
  MUT_TRACE="${MUT_TRACE}${1} : ${2}
"
}

# --- Fixture partagée par les mutations issue1/issue3/issue4/issue2bis : jalon clos, ledger présent,
# sans ID disparu (le cas « silencieux » de référence, non affecté par les mutations des AUTRES issues).
# Armée (D-18-09) : sans quoi la 3e occurrence « nominal » mutée en issue1 retomberait quand même sur
# la branche silencieuse via le cran avertissement (ARCHIVE vide + ARMED=0) — la mutation ne serait
# alors observable sur AUCUNE fixture de cette suite, un mutant increvable. L'armement ne change rien
# au comportement NON muté (nominal ignore ARMED), donc les autres mutations restent inchangées.
DM_SILENT="$(mk_root m-silent)"
w_milestones "$DM_SILENT" "$CLOSED_H2"
w_live "$DM_SILENT" $'# Requirements\n- [x] **QQQQ-01**: rien\n'
w_armed "$DM_SILENT"

# --- Fixture partagée par la mutation issue2 : jalon clos, ledger absent, archive présente.
DM_ABSENT="$(mk_root m-absent)"
w_milestones "$DM_ABSENT" "$CLOSED_H2"
w_archive "$DM_ABSENT" "demo-v1" "$(archive_one_id AAAA-01)"

# --- Fixture partagée par la mutation issue2bis : ID garanti disparu d'un ledger PRÉSENT.
DM_MISSING="$(mk_root m-missing)"
w_milestones "$DM_MISSING" "$CLOSED_H2"
w_archive "$DM_MISSING" "demo-v1" "$(archive_one_id XXXX-01)"
w_live "$DM_MISSING" $'# Requirements\n- [x] **YYYY-99**: sans rapport\n'

# --- Fixture partagée par la mutation issue3 : MILESTONES.md sans aucun H2 (illisible).
DM_UNREADABLE="$(mk_root m-unreadable)"
printf '# Milestones\nprose seulement\n' > "$DM_UNREADABLE/.planning/MILESTONES.md"

# mut_run <mid> <dossier-mutant> <fixture> <expect_rc> <expect_stdout_mode:empty|nonempty> [--hook]
# Un rc 126 (non exécutable) ou 127 (introuvable — script relocalisé, chemin cassé) n'est JAMAIS une
# preuve que la mutation a mordu : c'est une panne de harnais. dims est alors préfixé HARNESS_BROKEN,
# un sentinel que mut_check (ci-dessous) traite TOUJOURS comme un échec bruyant, quel que soit le
# mode attendu — jamais un "✓" pour la mauvaise raison.
mut_run() {
  local mid="$1" mdir="$2" fixture="$3" expect_rc="$4" mode="$5"; shift 5
  local out rc dims=""
  out="$(bash "$mdir/check-requirements-survival.sh" --path "$fixture" "$@" 2>/dev/null)"; rc=$?
  if [ "$rc" -eq 126 ] || [ "$rc" -eq 127 ]; then
    printf 'HARNESS_BROKEN(rc=%s)' "$rc"
    return
  fi
  if [ "$rc" -ne "$expect_rc" ]; then dims="${dims}code(attendu ${expect_rc}, obtenu ${rc}) "; fi
  case "$mode" in
    empty)    [ -n "$out" ] && dims="${dims}stdout(attendu vide, obtenu [$out]) " ;;
    nonempty) [ -z "$out" ] && dims="${dims}stdout(attendu non vide, obtenu vide) " ;;
  esac
  printf '%s' "$dims"
}

# mut_check <dims> <expect_nonempty:0|1> <mid> <ok-label> <ko-label> — interprète mut_run en
# distinguant "le test a mordu" (dims non vide attendu) de "le harnais est cassé" (HARNESS_BROKEN,
# TOUJOURS un ko, jamais interprété comme une morsure ni comme une discriminance préservée).
mut_check() {
  local dims="$1" expect_nonempty="$2" mid="$3" ok_label="$4" ko_label="$5"
  case "$dims" in
    HARNESS_BROKEN*)
      ko "$ok_label" "exécution normale du mutant (rc ni 126 ni 127)" "$dims — harnais cassé, pas une preuve de morsure"
      return
      ;;
  esac
  if [ "$expect_nonempty" -eq 1 ]; then
    if [ -n "$dims" ]; then ok "$ok_label : $dims"; mutant_note "$mid" "$dims"
    else ko "$ko_label" "le comportement change sous la mutation" "aucune différence détectée"; fi
  else
    if [ -z "$dims" ]; then ok "$ok_label"
    else ko "$ko_label" "cas inchangé" "$dims"; fi
  fi
}

# --- MUTATION issue1 : l'état nominal (« ledger présent sans ID disparu ») devient absent_after_close.
M1_DIR="$TMP/mut-issue1"; mkdir -p "$M1_DIR"
cp "$GATE" "$M1_DIR/"
awk '
  BEGIN { n = 0 }
  {
    if ($0 ~ /VF_LEDGER_STATE="nominal"; return 1/) {
      n++
      if (n == 3) { sub(/VF_LEDGER_STATE="nominal"; return 1/, "VF_LEDGER_STATE=\"absent_after_close\"; return 0") }
    }
    print
  }
' "$PRIMITIVE" > "$M1_DIR/requirements-survival-detect.sh"
chmod +x "$M1_DIR/check-requirements-survival.sh" "$M1_DIR/requirements-survival-detect.sh"
# Garde — l'awk ne mute QUE la 3e occurrence : vérifier que la substitution a bien eu lieu (et pas
# seulement que le fichier diffère), sans quoi un écart de dims ne prouverait rien. PIÈGE ÉCARTÉ :
# la chaîne 'VF_LEDGER_STATE="absent_after_close"; return 0' existe DÉJÀ une fois dans la source
# (branche réelle de retour absent) — un simple `grep -qF` réussit donc TOUJOURS, mutation ou pas
# (garde vacante). On compte les occurrences : la source en porte 1, la mutation doit en ajouter
# une 2e (le nominal muté) — un mutant non porteur reste à 1.
ABSENT_COUNT_SRC=$(grep -c 'VF_LEDGER_STATE="absent_after_close"; return 0' "$PRIMITIVE")
ABSENT_COUNT_MUT=$(grep -c 'VF_LEDGER_STATE="absent_after_close"; return 0' "$M1_DIR/requirements-survival-detect.sh")
guardissue1_removed=0
[ "$ABSENT_COUNT_MUT" -eq "$((ABSENT_COUNT_SRC + 1))" ] && guardissue1_removed=1
if [ "$guardissue1_removed" -eq 1 ]; then
  # mut_run reçoit le comportement CORRECT (non muté) en référence — dims s'accumule quand l'ACTUEL
  # (sous mutation) s'en écarte. DM_SILENT non muté : code 3, stdout vide (silence, D-18-10). La
  # mutation cible ce cas — il doit rougir (dims non vide). Le cas issue2bis (DM_MISSING) doit rester
  # VERT (inchangé).
  dims="$(mut_run issue1 "$M1_DIR" "$DM_SILENT" 3 empty)"
  mut_check "$dims" 1 issue1 "MUTATION issue1 (nominal→absent_after_close) rougit le cas silencieux comme attendu" "MUTATION issue1 — N'A PAS ROUGI"
  dims2="$(mut_run issue1-controle "$M1_DIR" "$DM_MISSING" 0 nonempty)"
  mut_check "$dims2" 0 issue1-controle "MUTATION issue1 — le cas issue2bis (DM_MISSING) reste VERT sous cette mutation (discriminance)" "MUTATION issue1 — discriminance rompue, DM_MISSING affecté aussi"
else
  ko "MUTATION issue1 — construction du mutant a échoué" "le fichier muté porte VF_LEDGER_STATE=\"absent_after_close\"; return 0" "grep ne le trouve pas (3e occurrence non substituée)"
fi

# --- MUTATION issue2 : l'état d'absence (absent_after_close) redevient nominal.
M2_DIR="$TMP/mut-issue2"; mkdir -p "$M2_DIR"
cp "$GATE" "$M2_DIR/"
sed 's/VF_LEDGER_STATE="absent_after_close"; return 0/VF_LEDGER_STATE="nominal"; return 1/' "$PRIMITIVE" > "$M2_DIR/requirements-survival-detect.sh"
chmod +x "$M2_DIR/check-requirements-survival.sh" "$M2_DIR/requirements-survival-detect.sh"
guardissue2_removed=0
grep -qF 'VF_LEDGER_STATE="absent_after_close"; return 0' "$M2_DIR/requirements-survival-detect.sh" || guardissue2_removed=1
if [ "$guardissue2_removed" -eq 1 ]; then
  # DM_ABSENT non muté : code 0, stdout non vide ([ledger-absent]) — référence CORRECTE passée à
  # mut_run. Sous la mutation (absent→nominal), l'ACTUEL retombe en silence : dims doit capter l'écart.
  dims="$(mut_run issue2 "$M2_DIR" "$DM_ABSENT" 0 nonempty)"
  mut_check "$dims" 1 issue2 "MUTATION issue2 (absent→nominal) rougit le cas [ledger-absent] comme attendu" "MUTATION issue2 — N'A PAS ROUGI"
  dims2="$(mut_run issue2-controle "$M2_DIR" "$DM_SILENT" 3 empty)"
  mut_check "$dims2" 0 issue2-controle "MUTATION issue2 — le cas silencieux (DM_SILENT) reste VERT sous cette mutation (discriminance)" "MUTATION issue2 — discriminance rompue, DM_SILENT affecté aussi"
else
  ko "MUTATION issue2 — construction du mutant a échoué" "le fichier muté ne porte plus VF_LEDGER_STATE=\"absent_after_close\"; return 0" "grep le trouve encore"
fi

# --- MUTATION issue2bis : le retour 3 (ids_missing) retombe sur la branche silencieuse (hook_exit 3).
# C'est LA mutation qui rejoue la lettre du cas obligatoire : si elle ne fait rougir QUE ce cas, le
# gate ne peut jamais retomber en silence sur une exigence disparue.
M2BIS_DIR="$TMP/mut-issue2bis"; mkdir -p "$M2BIS_DIR"
cp "$PRIMITIVE" "$M2BIS_DIR/"
sed "/^  3)\$/,/^    ;;\$/ s/exit 0/hook_exit 3/" "$GATE" > "$M2BIS_DIR/check-requirements-survival.sh"
chmod +x "$M2BIS_DIR/check-requirements-survival.sh" "$M2BIS_DIR/requirements-survival-detect.sh"
guardissue2bis_removed=0
[ "$(grep -c "hook_exit 3" "$M2BIS_DIR/check-requirements-survival.sh")" -eq $((BASE_HOOKEXIT3_COUNT + 1)) ] && guardissue2bis_removed=1
if [ "$guardissue2bis_removed" -eq 1 ]; then
  dims="$(mut_run issue2bis "$M2BIS_DIR" "$DM_MISSING" 0 nonempty)"
  mut_check "$dims" 1 issue2bis "MUTATION issue2bis (ids_missing→silence) rougit le cas obligatoire comme attendu" "MUTATION issue2bis — N'A PAS ROUGI"
  dims2="$(mut_run issue2bis-controle "$M2BIS_DIR" "$DM_SILENT" 3 empty)"
  mut_check "$dims2" 0 issue2bis-controle "MUTATION issue2bis — le cas silencieux (DM_SILENT) reste VERT sous cette mutation (discriminance)" "MUTATION issue2bis — discriminance rompue, DM_SILENT affecté aussi"
else
  ko "MUTATION issue2bis — construction du mutant a échoué" "le fichier muté porte $((BASE_HOOKEXIT3_COUNT + 1)) occurrences de hook_exit 3" "grep en trouve $(grep -c "hook_exit 3" "$M2BIS_DIR/check-requirements-survival.sh")"
fi

# --- MUTATION issue3 : le retour 2 (illisible) retombe sur la branche silencieuse (hook_exit 3).
M3_DIR="$TMP/mut-issue3"; mkdir -p "$M3_DIR"
cp "$PRIMITIVE" "$M3_DIR/"
sed "/^  2)\$/,/^    ;;\$/ s/exit 0/hook_exit 3/" "$GATE" > "$M3_DIR/check-requirements-survival.sh"
chmod +x "$M3_DIR/check-requirements-survival.sh" "$M3_DIR/requirements-survival-detect.sh"
guardissue3_removed=0
[ "$(grep -c "hook_exit 3" "$M3_DIR/check-requirements-survival.sh")" -eq $((BASE_HOOKEXIT3_COUNT + 1)) ] && guardissue3_removed=1
if [ "$guardissue3_removed" -eq 1 ]; then
  dims="$(mut_run issue3 "$M3_DIR" "$DM_UNREADABLE" 0 nonempty)"
  mut_check "$dims" 1 issue3 "MUTATION issue3 (illisible→silence) rougit le cas illisible comme attendu" "MUTATION issue3 — N'A PAS ROUGI"
  dims2="$(mut_run issue3-controle "$M3_DIR" "$DM_SILENT" 3 empty)"
  mut_check "$dims2" 0 issue3-controle "MUTATION issue3 — le cas silencieux (DM_SILENT) reste VERT sous cette mutation (discriminance)" "MUTATION issue3 — discriminance rompue, DM_SILENT affecté aussi"
else
  ko "MUTATION issue3 — construction du mutant a échoué" "le fichier muté porte $((BASE_HOOKEXIT3_COUNT + 1)) occurrences de hook_exit 3" "grep en trouve $(grep -c "hook_exit 3" "$M3_DIR/check-requirements-survival.sh")"
fi

# --- MUTATION issue4 : la primitive introuvable retombe sur un hook_exit 3 silencieux.
M4_DIR="$TMP/mut-issue4"; mkdir -p "$M4_DIR"
sed '/^if \[ -z "\$PRIMITIVE"/,/^fi$/ s/exit 0/hook_exit 3/' "$GATE" > "$M4_DIR/check-requirements-survival.sh"
chmod +x "$M4_DIR/check-requirements-survival.sh"
guardissue4_removed=0
[ "$(grep -c "hook_exit 3" "$M4_DIR/check-requirements-survival.sh")" -eq $((BASE_HOOKEXIT3_COUNT + 1)) ] && guardissue4_removed=1
if [ "$guardissue4_removed" -eq 1 ]; then
  dims="$(mut_run issue4 "$M4_DIR" "$DM_SILENT" 0 nonempty)"
  mut_check "$dims" 1 issue4 "MUTATION issue4 (outil-absent→silence) rougit le cas outil-absent comme attendu" "MUTATION issue4 — N'A PAS ROUGI"
else
  ko "MUTATION issue4 — construction du mutant a échoué" "le fichier muté porte $((BASE_HOOKEXIT3_COUNT + 1)) occurrences de hook_exit 3" "grep en trouve $(grep -c "hook_exit 3" "$M4_DIR/check-requirements-survival.sh")"
fi

# ==================================================================================================
# Auto-preuve (mandat correction ciblée W-A) : le harnais doit CRIER sur une relocalisation, jamais
# verdir. Reproduit le symptôme constaté en mission — une suite/script relocalisé rend bash rc=127,
# faussement compté "ça a mordu" avant ce correctif. Ici : mdir SANS check-requirements-survival.sh
# du tout (relocalisation simulée) → mut_run doit rendre HARNESS_BROKEN, jamais un dims interprété
# comme silence légitime (mode empty) ni comme morsure (mode nonempty). Cas de test, pas une
# vérification manuelle.
# ==================================================================================================
RELOC_DIR="$TMP/mut-relocated-suite"; mkdir -p "$RELOC_DIR"
# Volontairement rien copié dedans : chemin "$RELOC_DIR/check-requirements-survival.sh" introuvable,
# bash rend rc=127 — exactement le symptôme d'une suite relocalisée.
dims_reloc="$(mut_run reloc-empty "$RELOC_DIR" "$DM_SILENT" 3 empty)"
case "$dims_reloc" in
  HARNESS_BROKEN*) ok "mut_run — script mutant introuvable (relocalisation simulée) → HARNESS_BROKEN signalé, jamais lu comme un silence légitime : $dims_reloc" ;;
  *) ko "mut_run — script mutant introuvable (relocalisation simulée) → HARNESS_BROKEN signalé" "dims commence par HARNESS_BROKEN" "dims=[$dims_reloc]" ;;
esac
dims_reloc2="$(mut_run reloc-nonempty "$RELOC_DIR" "$DM_ABSENT" 0 nonempty)"
case "$dims_reloc2" in
  HARNESS_BROKEN*) ok "mut_run — même panne de harnais signalée HARNESS_BROKEN quel que soit le mode attendu (nonempty), jamais lue comme une morsure : $dims_reloc2" ;;
  *) ko "mut_run — panne de harnais signalée HARNESS_BROKEN en mode nonempty" "dims commence par HARNESS_BROKEN" "dims=[$dims_reloc2]" ;;
esac
# mut_check doit aussi crier sur ce sentinel (jamais un ✓, jamais lu comme discriminance préservée).
# Vérifié dans un SUBSHELL avec ok/ko locaux : mut_check("HARNESS_BROKEN") est CENSÉ produire un ko —
# router cette assertion via le compteur PASS/FAIL réel de la suite ferait passer un résultat attendu
# pour un vrai échec de suite, brouillant le total final.
mc_probe_result="$(
  PASS=0; FAIL=0
  ok() { PASS=$((PASS+1)); }
  ko() { FAIL=$((FAIL+1)); }
  mut_check "$dims_reloc" 1 reloc-probe-bit "ne doit jamais s'afficher" "attendu : ko en mode bit"
  mut_check "$dims_reloc2" 0 reloc-probe-discrim "ne doit jamais s'afficher" "attendu : ko en mode discriminance"
  printf 'pass=%s fail=%s' "$PASS" "$FAIL"
)"
if [ "$mc_probe_result" = "pass=0 fail=2" ]; then
  ok "mut_check — une panne de harnais (HARNESS_BROKEN) produit TOUJOURS un ko, jamais un ✓, quel que soit expect_nonempty (0 ou 1)"
else
  ko "mut_check — une panne de harnais produit toujours un ko, jamais un ✓" "pass=0 fail=2" "$mc_probe_result"
fi

echo ""
echo "-- Trace des rougissements de mutation (à citer dans le SUMMARY) --"
printf '%s' "$MUT_TRACE"

# ==================================================================================================
# Cas 35 (BLOQUANT, correctif 2026-08-18, revue tour 2) : confinement de traversée symlink
# D'ANCÊTRE, second consommateur. La garde vit dans la primitive PARTAGÉE (vf_ledger_state) — ce
# gate en hérite sans logique propre (D-18-06), mais la couverture doit exister aux DEUX
# consommateurs séparément (le fait qu'un composant partagé soit corrigé une fois ne prouve pas
# que les deux points d'appel en profitent identiquement).
# ==================================================================================================
D="$(mk_root c35)"
w_milestones "$D" "$CLOSED_H2"
OUTSIDE35_DIR="$TMP/outside-secret-35"
mkdir -p "$OUTSIDE35_DIR"
printf '%s' "$(archive_one_id LEAK-35)" > "$OUTSIDE35_DIR/demo-v1-REQUIREMENTS.md"
ln -s "$OUTSIDE35_DIR" "$D/.planning/milestones"
out35="$(bash "$GATE" --path "$D" 2>/dev/null)"; rc35=$?
if [ "$rc35" -eq 3 ] && [ -z "$out35" ]; then
  ok "35 (BLOQUANT) ancêtre symlinké — archive inatteignable, gate se replie sur le cran avertissement (silence, code 3)"
else
  ko "35 (BLOQUANT) ancêtre symlinké — archive inatteignable, gate se replie sur le cran avertissement (silence, code 3)" "rc=3 out=[]" "rc=$rc35 out=[$out35]"
fi

# --- MUTATION (BLOQUANT, cas 35) : retirer la garde d'ancêtre dans la primitive (même technique
# index/substr que la suite restore-requirements-ledger, aucun souci d'échappement `$` en awk) — le
# mutant doit rougir : le gate prétend qu'une archive est disponible pour un jalon dont l'archive
# n'est atteignable QUE via un lien.
MUT35_DIR="$TMP/mut-ancestor-gate"; mkdir -p "$MUT35_DIR"
awk '
{
  line = $0
  pat = " && ! vf_ancestor_symlink_found \"$archive\" \"$planning_dir\""
  idx = index(line, pat)
  if (idx > 0) { line = substr(line, 1, idx - 1) substr(line, idx + length(pat)) }
  print line
}
' "$PRIMITIVE" > "$MUT35_DIR/requirements-survival-detect.sh"
cp "$GATE" "$MUT35_DIR/"
chmod +x "$MUT35_DIR"/*.sh
guard35_removed=0
grep -q '\] && ! vf_ancestor_symlink_found' "$MUT35_DIR/requirements-survival-detect.sh" || guard35_removed=1
if [ "$guard35_removed" -eq 1 ]; then
  out35mut="$(bash "$MUT35_DIR/check-requirements-survival.sh" --path "$D" 2>/dev/null)"; rc35mut=$?
  leaked35mut=0; printf '%s' "$out35mut" | grep -q '\[ledger-absent\]' && leaked35mut=1
  if [ "$rc35mut" -eq 0 ] && [ "$leaked35mut" -eq 1 ]; then
    ok "MUTATION 35 (garde d'ancêtre retirée) rougit comme attendu : [ledger-absent] émis avec archive prétendue disponible via l'ancêtre symlinké"
  else
    ko "MUTATION 35 — N'A PAS ROUGI" "rc=0, [ledger-absent] émis" "rc=$rc35mut out=[$out35mut]"
  fi
else
  ko "MUTATION 35 — construction du mutant a échoué" "l'appel à vf_ancestor_symlink_found est retiré du fichier muté" "grep le trouve encore"
fi
# Discriminance : un cas de jalon clos sans archive du tout, armé (issue 2, DÉJÀ dans cette suite)
# reste VERT sous cette mutation.
D_CTRL35="$(mk_root c35ctrl)"
w_milestones "$D_CTRL35" "$CLOSED_H2"
w_armed "$D_CTRL35"
ctrl35_out="$(bash "$MUT35_DIR/check-requirements-survival.sh" --path "$D_CTRL35" 2>/dev/null)"; ctrl35_rc=$?
if [ "$ctrl35_rc" -eq 0 ] && printf '%s' "$ctrl35_out" | grep -q 'aucune archive à reconstituer'; then
  ok "MUTATION 35 — le cas jalon-clos-sans-archive reste VERT sous cette mutation (discriminance)"
else
  ko "MUTATION 35 — discriminance rompue, le cas sans archive est affecté aussi" "cas inchangé (rc=0, message sans archive)" "rc=$ctrl35_rc out=[$ctrl35_out]"
fi

# ==================================================================================================
# Cas 36-39 (BLOQUANT G1, correction ciblée post-vérification 2026-08-18) : portabilité CRLF
# (ADR-054). Sous `core.autocrlf=true` (défaut Git for Windows), un `.md` de lab peut porter des
# fins de ligne CRLF sans que ce dépôt ne le contrôle (`.gitattributes` protège SES PROPRES fichiers,
# pas ceux d'un lab tiers). Trois symptômes reproduits par exécution AVANT correctif, rejoués ici
# rouge-avant/vert-après via `printf ... "\r"` — jamais un fichier binaire externe.
# ==================================================================================================
CR="$(printf '\r')"

# === Cas 36 — titre H2 clos en CRLF, SANS séparateur em-dash après le libellé (forme minimale
# `## ✅ <libellé>`) : PAS de faux label_rejected. Fixture choisie précisément : quand une
# description suit un tiret cadratin (`CLOSED_H2` standard de cette suite), l'extraction du
# libellé tronque tout après le tiret — le `\r` traînant y est coupé AVEC la description, la CRLF
# ne peut donc pas y être observée. Vérifié par exécution sur le code PRÉ-correctif : SEULE la
# forme sans description reproduit `label_rejected` sous CRLF (reproduit ici, rouge avant/vert
# après ce correctif).
D="$(mk_root c36)"
printf '# Milestones\r\n\r\n## \xe2\x9c\x85 demo-v1\r\n\r\nDetail.\r\n' > "$D/.planning/MILESTONES.md"
w_archive "$D" "demo-v1" "$(archive_one_id AAAA-01)"
out="$(bash "$GATE" --path "$D" 2>/dev/null)"; rc=$?
has=0; case "$out" in "[ledger-absent]"*"demo-v1"*) has=1 ;; esac
leaked_reject=0; printf '%s' "$out" | grep -q 'label_rejected' && leaked_reject=1
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ] && [ "$leaked_reject" -eq 0 ]; then ok "36 (G1) titre H2 clos en CRLF sans description → [ledger-absent] normal, jamais label_rejected"; else ko "36 (G1) titre H2 clos en CRLF sans description → [ledger-absent] normal, jamais label_rejected" "rc=0, [ledger-absent] demo-v1, jamais label_rejected" "rc=$rc out=[$out]"; fi

# === Cas 37 — trace carried-from: bien formée en CRLF : silence, jamais trace_malformed =============
D="$(mk_root c37)"
printf '# Milestones\r\n\r\n%s\r\n\r\nDetail.\r\n' "$CLOSED_H2" > "$D/.planning/MILESTONES.md"
printf '# Requirements\r\n- [ ] **SSSS-01**: exigence voyageuse carried-from: v1.2\r\n' > "$D/.planning/REQUIREMENTS.md"
out="$(bash "$GATE" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "37 (G1) trace carried-from: bien formée en CRLF → silence, jamais trace_malformed"; else ko "37 (G1) trace carried-from: bien formée en CRLF → silence, jamais trace_malformed" "rc=3 out=[]" "rc=$rc out=[$out]"; fi

# === Cas 38 (G3) — trace RÉELLEMENT tronquée (pas de backtick, pas de valeur) → trace_malformed =====
# Correction du bras trop large : `carried-from:[[:space:]]*$` excluait AUSSI ce cas, indistinct
# de la mention nue en prose (cas 24) qu'il visait seul. Contrôle de discriminance : le cas 24 reste
# silencieux (backtick), voir plus haut dans cette suite.
D="$(mk_root c38)"
w_milestones "$D" "$CLOSED_H2"
w_live "$D" $'# Requirements\n- [ ] **TTTT-01**: exigence tronquee \xe2\x80\x94 carried-from:\n'
out="$(bash "$GATE" --path "$D" 2>/dev/null)"; rc=$?
has=0; case "$out" in "[ledger-illisible]"*"trace_malformed"*) has=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ]; then ok "38 (G3) trace carried-from: réellement tronquée (sans backtick, sans valeur) → illisible trace_malformed"; else ko "38 (G3) trace carried-from: réellement tronquée (sans backtick, sans valeur) → illisible trace_malformed" "rc=0 out contient trace_malformed" "rc=$rc out=[$out]"; fi

# --- MUTATION G3 : réintroduire le bras trop large (`carried-from:[[:space:]]*$`, sans exigence de
# backtick) dans une COPIE de la primitive — doit faire ROUGIR le cas 38 (la trace tronquée redevient
# silencieusement absorbée), en laissant VERT le cas 24 (mention nue en prose, backtick, inchangée).
MUTG3_DIR="$TMP/mut-g3"; mkdir -p "$MUTG3_DIR"
sed "s/grep -vE 'carried-from:\`' \\\\/grep -vE 'carried-from:\`|carried-from:[[:space:]]*\$' \\\\/" "$PRIMITIVE" > "$MUTG3_DIR/requirements-survival-detect.sh"
cp "$GATE" "$MUTG3_DIR/"
chmod +x "$MUTG3_DIR"/*.sh
guardg3_removed=0
grep -qF "grep -vE 'carried-from:\`|carried-from:[[:space:]]*\$' \\" "$MUTG3_DIR/requirements-survival-detect.sh" && guardg3_removed=1
bash -n "$MUTG3_DIR/requirements-survival-detect.sh" 2>/dev/null || guardg3_removed=0
if [ "$guardg3_removed" -eq 1 ]; then
  out_mut="$(bash "$MUTG3_DIR/check-requirements-survival.sh" --path "$D" 2>/dev/null)"; rc_mut=$?
  malformed_mut=0; case "$out_mut" in "[ledger-illisible]"*"trace_malformed"*) malformed_mut=1 ;; esac
  if [ "$malformed_mut" -eq 0 ]; then ok "MUTATION G3 (bras large réintroduit) rougit le cas 38 comme attendu : la trace tronquée redevient absorbée silencieusement"; else ko "MUTATION G3 — N'A PAS ROUGI" "la trace tronquée n'est plus flagée trace_malformed sous la mutation" "rc=$rc_mut out=[$out_mut]"; fi
  D_G3CTRL="$(mk_root c38-controle)"
  w_milestones "$D_G3CTRL" "$CLOSED_H2"
  w_live "$D_G3CTRL" $'# Requirements\n- [ ] **LEDG-01**: convention décrite en prose, trace `carried-from:`\n'
  out_ctrl="$(bash "$MUTG3_DIR/check-requirements-survival.sh" --path "$D_G3CTRL" 2>/dev/null)"; rc_ctrl=$?
  if [ "$rc_ctrl" -eq 3 ] && [ -z "$out_ctrl" ]; then ok "MUTATION G3 — le cas 24 (mention nue en prose, backtick) reste VERT sous cette mutation (discriminance)"; else ko "MUTATION G3 — discriminance rompue, cas 24 affecté aussi" "rc=3 out=[]" "rc=$rc_ctrl out=[$out_ctrl]"; fi
else
  ko "MUTATION G3 — construction du mutant a échoué" "le fichier muté réintroduit le bras large" "grep ne le trouve pas / bash -n échoue"
fi

# --- MUTATION G1 (CRLF) : retirer la normalisation `tr -d '\r'` de l'extraction du titre H2 dans une
# COPIE de la primitive — doit faire ROUGIR le cas 36 (le titre CRLF redevient rejeté), en laissant
# VERT le cas 5 (libellé légitime demo-v1, déjà en LF, non affecté par la mutation).
# Surgie par CONTENU exact de ligne, via ENVIRON (jamais `-v`, qui interprète `\r` comme un octet
# de contrôle au lieu des deux caractères littéraux backslash+r présents dans la ligne source —
# constaté par exécution : `-v` cassait la comparaison d'égalité de ligne, silencieusement).
MUTCRLF_DIR="$TMP/mut-crlf"; mkdir -p "$MUTCRLF_DIR"
export MUT_CRLF_OLD1 MUT_CRLF_OLD2 MUT_CRLF_NEW1 MUT_CRLF_NEW2
MUT_CRLF_OLD1="$(sed -n '98p' "$PRIMITIVE")"
MUT_CRLF_OLD2="$(sed -n '105p' "$PRIMITIVE")"
MUT_CRLF_NEW1='  heading="$(awk '"'"''
MUT_CRLF_NEW2='  '"'"' "$milestones")"'
awk '
  $0 == ENVIRON["MUT_CRLF_OLD1"] { print ENVIRON["MUT_CRLF_NEW1"]; next }
  $0 == ENVIRON["MUT_CRLF_OLD2"] { print ENVIRON["MUT_CRLF_NEW2"]; next }
  { print }
' "$PRIMITIVE" > "$MUTCRLF_DIR/requirements-survival-detect.sh"
unset MUT_CRLF_OLD1 MUT_CRLF_OLD2 MUT_CRLF_NEW1 MUT_CRLF_NEW2
cp "$GATE" "$MUTCRLF_DIR/"
chmod +x "$MUTCRLF_DIR"/*.sh
guardcrlf_removed=0
grep -q "tr -d '\\\\r' < \"\$milestones\"" "$MUTCRLF_DIR/requirements-survival-detect.sh" || guardcrlf_removed=1
bash -n "$MUTCRLF_DIR/requirements-survival-detect.sh" 2>/dev/null || guardcrlf_removed=0
if [ "$guardcrlf_removed" -eq 1 ]; then
  D="$(mk_root cm-crlf)"
  printf '# Milestones\r\n\r\n## \xe2\x9c\x85 demo-v1\r\n\r\nDetail.\r\n' > "$D/.planning/MILESTONES.md"
  out_mut="$(bash "$MUTCRLF_DIR/check-requirements-survival.sh" --path "$D" 2>/dev/null)"; rc_mut=$?
  rejected_mut=0; case "$out_mut" in "[ledger-illisible]"*"label_rejected"*) rejected_mut=1 ;; esac
  if [ "$rejected_mut" -eq 1 ]; then ok "MUTATION G1 (normalisation CRLF retirée) rougit le cas 36 comme attendu : titre CRLF redevient label_rejected"; else ko "MUTATION G1 — N'A PAS ROUGI" "le titre CRLF redevient label_rejected sous la mutation" "rc=$rc_mut out=[$out_mut]"; fi
  D2="$(mk_root cm-crlf-controle)"
  w_milestones "$D2" "$CLOSED_H2"
  w_archive "$D2" "demo-v1" "$(archive_one_id AAAA-01)"
  out_ctrl="$(bash "$MUTCRLF_DIR/check-requirements-survival.sh" --path "$D2" 2>/dev/null)"; rc_ctrl=$?
  has_ctrl=0; case "$out_ctrl" in "[ledger-absent]"*"demo-v1"*) has_ctrl=1 ;; esac
  if [ "$rc_ctrl" -eq 0 ] && [ "$has_ctrl" -eq 1 ]; then ok "MUTATION G1 — le cas 5 (libellé légitime demo-v1, LF) reste VERT sous cette mutation (discriminance)"; else ko "MUTATION G1 — discriminance rompue, demo-v1 affecté aussi" "cas 5 inchangé" "rc=$rc_ctrl out=[$out_ctrl]"; fi
else
  ko "MUTATION G1 — construction du mutant a échoué" "le fichier muté ne porte plus la normalisation tr -d '\\r'" "grep la trouve encore"
fi

# ==================================================================================================
# Garde finale — le fichier vivant est intact après la suite (aucune mutation n'a touché l'arbre réel).
# ==================================================================================================
if [ -x "$GATE" ] || [ -f "$GATE" ]; then :; fi
if bash -n "$GATE" 2>/dev/null && bash -n "$PRIMITIVE" 2>/dev/null; then
  ok "garde finale — les deux scripts vivants restent syntaxiquement intacts après le bloc de mutations"
else
  ko "garde finale — les deux scripts vivants restent syntaxiquement intacts après le bloc de mutations" "bash -n OK sur les deux fichiers vivants" "au moins un échoue"
fi

echo ""
echo "== résultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
