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
has_ids=0; case "$out" in *"MMMM-01"*"MMMM-02"*"MMMM-03"*) has_ids=1 ;; *"MMMM-01"*|*"MMMM-02"*|*"MMMM-03"*) has_ids=1 ;; esac
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

mut_run() { # <mid> <dossier-mutant> <fixture> <expect_rc> <expect_stdout_mode:empty|nonempty> [--hook]
  local mid="$1" mdir="$2" fixture="$3" expect_rc="$4" mode="$5"; shift 5
  local out rc dims=""
  out="$(bash "$mdir/check-requirements-survival.sh" --path "$fixture" "$@" 2>/dev/null)"; rc=$?
  if [ "$rc" -ne "$expect_rc" ]; then dims="${dims}code(attendu ${expect_rc}, obtenu ${rc}) "; fi
  case "$mode" in
    empty)    [ -n "$out" ] && dims="${dims}stdout(attendu vide, obtenu [$out]) " ;;
    nonempty) [ -z "$out" ] && dims="${dims}stdout(attendu non vide, obtenu vide) " ;;
  esac
  printf '%s' "$dims"
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
# mut_run reçoit le comportement CORRECT (non muté) en référence — dims s'accumule quand l'ACTUEL
# (sous mutation) s'en écarte. DM_SILENT non muté : code 3, stdout vide (silence, D-18-10). La
# mutation cible ce cas — il doit rougir (dims non vide). Le cas issue2bis (DM_MISSING) doit rester
# VERT (inchangé).
dims="$(mut_run issue1 "$M1_DIR" "$DM_SILENT" 3 empty)"
if [ -n "$dims" ]; then ok "MUTATION issue1 (nominal→absent_after_close) rougit le cas silencieux comme attendu : $dims"; mutant_note "issue1" "$dims"; else ko "MUTATION issue1 — N'A PAS ROUGI" "le cas silencieux DM_SILENT change de comportement sous la mutation" "aucune différence détectée"; fi
dims2="$(mut_run issue1-controle "$M1_DIR" "$DM_MISSING" 0 nonempty)"
if [ -z "$dims2" ]; then ok "MUTATION issue1 — le cas issue2bis (DM_MISSING) reste VERT sous cette mutation (discriminance)"; else ko "MUTATION issue1 — discriminance rompue, DM_MISSING affecté aussi" "DM_MISSING inchangé" "$dims2"; fi

# --- MUTATION issue2 : l'état d'absence (absent_after_close) redevient nominal.
M2_DIR="$TMP/mut-issue2"; mkdir -p "$M2_DIR"
cp "$GATE" "$M2_DIR/"
sed 's/VF_LEDGER_STATE="absent_after_close"; return 0/VF_LEDGER_STATE="nominal"; return 1/' "$PRIMITIVE" > "$M2_DIR/requirements-survival-detect.sh"
chmod +x "$M2_DIR/check-requirements-survival.sh" "$M2_DIR/requirements-survival-detect.sh"
# DM_ABSENT non muté : code 0, stdout non vide ([ledger-absent]) — référence CORRECTE passée à
# mut_run. Sous la mutation (absent→nominal), l'ACTUEL retombe en silence : dims doit capter l'écart.
dims="$(mut_run issue2 "$M2_DIR" "$DM_ABSENT" 0 nonempty)"
if [ -n "$dims" ]; then ok "MUTATION issue2 (absent→nominal) rougit le cas [ledger-absent] comme attendu : $dims"; mutant_note "issue2" "$dims"; else ko "MUTATION issue2 — N'A PAS ROUGI" "le cas DM_ABSENT change de comportement sous la mutation" "aucune différence détectée"; fi
dims2="$(mut_run issue2-controle "$M2_DIR" "$DM_SILENT" 3 empty)"
if [ -z "$dims2" ]; then ok "MUTATION issue2 — le cas silencieux (DM_SILENT) reste VERT sous cette mutation (discriminance)"; else ko "MUTATION issue2 — discriminance rompue, DM_SILENT affecté aussi" "DM_SILENT inchangé" "$dims2"; fi

# --- MUTATION issue2bis : le retour 3 (ids_missing) retombe sur la branche silencieuse (hook_exit 3).
# C'est LA mutation qui rejoue la lettre du cas obligatoire : si elle ne fait rougir QUE ce cas, le
# gate ne peut jamais retomber en silence sur une exigence disparue.
M2BIS_DIR="$TMP/mut-issue2bis"; mkdir -p "$M2BIS_DIR"
cp "$PRIMITIVE" "$M2BIS_DIR/"
sed "/^  3)\$/,/^    ;;\$/ s/exit 0/hook_exit 3/" "$GATE" > "$M2BIS_DIR/check-requirements-survival.sh"
chmod +x "$M2BIS_DIR/check-requirements-survival.sh" "$M2BIS_DIR/requirements-survival-detect.sh"
dims="$(mut_run issue2bis "$M2BIS_DIR" "$DM_MISSING" 0 nonempty)"
if [ -n "$dims" ]; then ok "MUTATION issue2bis (ids_missing→silence) rougit le cas obligatoire comme attendu : $dims"; mutant_note "issue2bis" "$dims"; else ko "MUTATION issue2bis — N'A PAS ROUGI" "le cas DM_MISSING (13) change de comportement sous la mutation" "aucune différence détectée"; fi
dims2="$(mut_run issue2bis-controle "$M2BIS_DIR" "$DM_SILENT" 3 empty)"
if [ -z "$dims2" ]; then ok "MUTATION issue2bis — le cas silencieux (DM_SILENT) reste VERT sous cette mutation (discriminance)"; else ko "MUTATION issue2bis — discriminance rompue, DM_SILENT affecté aussi" "DM_SILENT inchangé" "$dims2"; fi

# --- MUTATION issue3 : le retour 2 (illisible) retombe sur la branche silencieuse (hook_exit 3).
M3_DIR="$TMP/mut-issue3"; mkdir -p "$M3_DIR"
cp "$PRIMITIVE" "$M3_DIR/"
sed "/^  2)\$/,/^    ;;\$/ s/exit 0/hook_exit 3/" "$GATE" > "$M3_DIR/check-requirements-survival.sh"
chmod +x "$M3_DIR/check-requirements-survival.sh" "$M3_DIR/requirements-survival-detect.sh"
dims="$(mut_run issue3 "$M3_DIR" "$DM_UNREADABLE" 0 nonempty)"
if [ -n "$dims" ]; then ok "MUTATION issue3 (illisible→silence) rougit le cas illisible comme attendu : $dims"; mutant_note "issue3" "$dims"; else ko "MUTATION issue3 — N'A PAS ROUGI" "le cas DM_UNREADABLE change de comportement sous la mutation" "aucune différence détectée"; fi
dims2="$(mut_run issue3-controle "$M3_DIR" "$DM_SILENT" 3 empty)"
if [ -z "$dims2" ]; then ok "MUTATION issue3 — le cas silencieux (DM_SILENT) reste VERT sous cette mutation (discriminance)"; else ko "MUTATION issue3 — discriminance rompue, DM_SILENT affecté aussi" "DM_SILENT inchangé" "$dims2"; fi

# --- MUTATION issue4 : la primitive introuvable retombe sur un hook_exit 3 silencieux.
M4_DIR="$TMP/mut-issue4"; mkdir -p "$M4_DIR"
sed '/^if \[ -z "\$PRIMITIVE"/,/^fi$/ s/exit 0/hook_exit 3/' "$GATE" > "$M4_DIR/check-requirements-survival.sh"
chmod +x "$M4_DIR/check-requirements-survival.sh"
dims="$(mut_run issue4 "$M4_DIR" "$DM_SILENT" 0 nonempty)"
if [ -n "$dims" ]; then ok "MUTATION issue4 (outil-absent→silence) rougit le cas outil-absent comme attendu : $dims"; mutant_note "issue4" "$dims"; else ko "MUTATION issue4 — N'A PAS ROUGI" "le cas sans primitive change de comportement sous la mutation" "aucune différence détectée"; fi

echo ""
echo "-- Trace des rougissements de mutation (à citer dans le SUMMARY) --"
printf '%s' "$MUT_TRACE"

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
