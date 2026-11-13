#!/usr/bin/env bash
# test-ci-shard-suites.sh — Suite de vérification de scripts/ci-shard-suites.sh (mission « CI sélective », lot B ;
# arbitrages Samuel, AskUserQuestion session principale, 2026-11-07 : « PR sélective, main complète »,
# « Module + dépendances citées », « Oui, découper projet »).
#
# Ce que la suite prouve, sur la découverte RÉELLE du dépôt et sur des listes synthétiques :
#   union des shards = entrée, shards disjoints, déterminisme, suites > 600 s seules sur leur shard, `--all` inchangé
#   (comparé à `find plugin scripts -type f -path '*/tests/test-*.sh' | LC_ALL=C sort`), `--liste` hors découverte → 65,
#   shard vide toléré sur une petite liste, glob `test-cockpit-projet-*.sh` estimé à 540 s (arbre factice).
# SIX mutants, appliqués par sed sur une COPIE du script (jamais sur l'original) : chacun asserte qu'il a bien changé la
# copie, que la propriété visée est ROUGE sur le mutant ET VERTE sur l'original, et imprime la trace du rouge.
# Aucune suite lourde n'est jouée : la suite ne lit que des listes de chemins (moins de 30 s).
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$ROOT/scripts/ci-shard-suites.sh"
N=14  # la valeur de SHARDS visée par la CI ; la propriété est testée aussi sur d'autres n
XTERM=plugin/cockpit/scripts/tests/test-cockpit-terminal-xterm.sh
PROJET=plugin/cockpit/scripts/tests/test-cockpit-projet-visite.sh

PASS=0; FAIL=0
ok() { echo "  OK $1"; PASS=$((PASS + 1)); }
ko() { echo "  KO $1"; echo "    attendu : $2"; echo "    obtenu  : $3"; FAIL=$((FAIL + 1)); }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# part <script> <shard> <n> [liste] — cwd = racine du dépôt (la découverte est relative).
part() {
  if [ -n "${4:-}" ]; then (cd "$ROOT" && bash "$1" "$2" "$3" --liste "$4"); else (cd "$ROOT" && bash "$1" "$2" "$3"); fi
}
# union <script> <n> [liste] — toutes les parts, concaténées (non triées).
union() { local s=0; while [ "$s" -lt "$2" ]; do part "$1" "$s" "$2" "${3:-}"; s=$((s + 1)); done; }

# --- table des durées, lue dans le script lui-même (aucune copie à tenir) -------------------------------------
TABLE="$WORK/table.txt"
sed -n '/^  cat <<.DUREES.$/,/^DUREES$/p' "$SCRIPT" | grep -E '^[0-9]+ ' > "$TABLE"
# load_max <n> <fichier de parts concaténées par shard : « shard<TAB>chemin »> -> imprime « max moyenne-hors-réservées »
est() { # chemin -> secondes (exact, sinon 7)
  awk -v p="$1" '$2 == p { print $1; f = 1; exit } END { if (!f) print 7 }' "$TABLE"
}
loads() { # script n -> une ligne par shard : « shard charge nb »
  local sc="$1" n="$2" s=0 f
  while [ "$s" -lt "$n" ]; do
    f="$WORK/l$s.txt"; part "$sc" "$s" "$n" > "$f"
    awk -v s="$s" 'NR == FNR { t[$2] = $1; next } { x += ($0 in t) ? t[$0] : 7; c++ } END { print s, x + 0, c + 0 }' "$TABLE" "$f"
    s=$((s + 1))
  done
}

ALL="$WORK/all.txt"; (cd "$ROOT" && find plugin scripts -type f -path '*/tests/test-*.sh' | LC_ALL=C sort) > "$ALL"
NALL="$(awk 'END { print NR }' "$ALL")"

echo "== test-ci-shard-suites — partition pondérée par les durées mesurées =="
echo "   découverte : $NALL suites ; table : $(awk 'END { print NR }' "$TABLE") entrées"

# --- C1 : --all inchangé -------------------------------------------------------------------------------------
(cd "$ROOT" && bash "$SCRIPT" --all) > "$WORK/all-script.txt"; rc=$?
if [ "$rc" -eq 0 ] && [ "$NALL" -gt 0 ] && cmp -s "$ALL" "$WORK/all-script.txt"; then
  ok "C1 --all = find plugin scripts '*/tests/test-*.sh' | sort ($NALL suites, rc 0)"
else
  ko "C1 --all" "rc 0 et même liste que find|sort ($NALL)" "rc=$rc, $(awk 'END { print NR }' "$WORK/all-script.txt") ligne(s)"
fi

# --- C2 : union = découverte, sans doublon, pour plusieurs n ----------------------------------------------------
for n in 6 7 "$N"; do
  union "$SCRIPT" "$n" | LC_ALL=C sort > "$WORK/u.txt"
  dups="$(uniq -d "$WORK/u.txt" | awk 'END { print NR }')"
  if cmp -s "$WORK/u.txt" "$ALL" && [ "$dups" -eq 0 ]; then
    ok "C2 n=$n : l'union des $n shard(s) est la découverte ($NALL), sans doublon (disjoints)"
  else
    ko "C2 n=$n" "union = découverte, 0 doublon" "$(awk 'END { print NR }' "$WORK/u.txt") ligne(s), $dups doublon(s)"
  fi
done

# --- C3 : déterminisme -------------------------------------------------------------------------------------------
loads "$SCRIPT" "$N" > "$WORK/run1.txt"; union "$SCRIPT" "$N" > "$WORK/d1.txt"; union "$SCRIPT" "$N" > "$WORK/d2.txt"
if cmp -s "$WORK/d1.txt" "$WORK/d2.txt" && [ -s "$WORK/d1.txt" ]; then
  ok "C3 deux exécutions donnent exactement les mêmes parts (ordre compris)"
else
  ko "C3 déterminisme" "deux sorties identiques" "elles diffèrent"
fi

# --- C4 : les suites > 600 s sont seules sur leur shard ----------------------------------------------------------
heavy_alone() { # script -> 0 si xterm (692 s) et projet-visite (658 s) sont chacune SEULE sur son shard ; trace sur stdout
  local sc="$1" s=0 bad=0 hx=0 hp=0 cnt
  while [ "$s" -lt "$N" ]; do
    part "$sc" "$s" "$N" > "$WORK/h.txt"; cnt="$(awk 'END { print NR }' "$WORK/h.txt")"
    if grep -qxF "$XTERM" "$WORK/h.txt"; then hx=1; [ "$cnt" -eq 1 ] || { bad=1; echo "    shard $s : $XTERM avec $((cnt - 1)) autre(s) suite(s)"; }; fi
    if grep -qxF "$PROJET" "$WORK/h.txt"; then hp=1; [ "$cnt" -eq 1 ] || { bad=1; echo "    shard $s : $PROJET avec $((cnt - 1)) autre(s) suite(s)"; }; fi
    s=$((s + 1))
  done
  [ "$hx" -eq 1 ] && [ "$hp" -eq 1 ] || { bad=1; echo "    suite lourde absente de la découverte (hx=$hx hp=$hp)"; }
  return "$bad"
}
if tr=$(heavy_alone "$SCRIPT"); then
  ok "C4 test-cockpit-terminal-xterm.sh (692 s) et test-cockpit-projet-visite.sh (658 s) sont chacune seule sur son shard (n=$N)"
else
  ko "C4 suites lourdes seules" "chacune seule sur son shard" "$tr"
fi

# --- C5 : LPT — la charge maximale reste sous la borne ------------------------------------------------------------
# Borne = moyenne de la charge NON réservée × 1,05 ; la moyenne vient de la table (lourdes > 600 s retirées).
lpt_borne() {
  awk -v n="$N" 'NR == FNR { t[$2] = $1; next }
    { d = ($0 in t) ? t[$0] : 7; if (d > 600) { nh++ } else { rest += d } }
    END { printf "%d\n", (rest / (n - nh)) * 1.05 + 0.999 }' "$TABLE" "$ALL"
}
BORNE="$(lpt_borne)"
lpt_ok() { # script -> 0 si max des charges non réservées ≤ BORNE ; trace « shard charge »
  loads "$1" "$N" > "$WORK/ld.txt"
  # charges des shards non réservés = tous sauf ceux qui contiennent une suite > 600 s (1 seule suite : charge > 600 et nb = 1)
  awk -v b="$BORNE" '$3 == 1 && $2 > 600 { next } { if ($2 > m) { m = $2; s = $1 } } END { print "    charge max hors réservées : " m " s (shard " s "), borne " b " s"; exit (m > b) }' "$WORK/ld.txt"
}
if tr=$(lpt_ok "$SCRIPT"); then ok "C5 LPT : $(echo "$tr" | sed 's/^ *//') — la plus chargée est sous la borne (moyenne × 1,05)"; else ko "C5 LPT" "charge max ≤ $BORNE s" "$tr"; fi

# --- C6 : --liste hors découverte / doublon / illisible → 65 ------------------------------------------------------
printf '%s\n' "$XTERM" "plugin/zz/scripts/tests/test-inexistante.sh" > "$WORK/inconnue.txt"
out="$(cd "$ROOT" && bash "$SCRIPT" 0 3 --liste "$WORK/inconnue.txt" 2>&1)"; rc=$?
if [ "$rc" -eq 65 ] && printf '%s' "$out" | grep -q 'test-inexistante.sh'; then ok "C6a --liste avec une suite inconnue → rc 65, la ligne fautive est nommée"; else ko "C6a" "rc 65 et nom de la ligne" "rc=$rc : $out"; fi
printf '%s\n' "$XTERM" "$XTERM" > "$WORK/dup.txt"
out="$(cd "$ROOT" && bash "$SCRIPT" 0 3 --liste "$WORK/dup.txt" 2>&1)"; rc=$?
if [ "$rc" -eq 65 ]; then ok "C6b --liste avec un doublon → rc 65"; else ko "C6b" "rc 65" "rc=$rc : $out"; fi
(cd "$ROOT" && bash "$SCRIPT" 0 3 --liste "$WORK/n-existe-pas.txt") >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 65 ]; then ok "C6c --liste illisible → rc 65"; else ko "C6c" "rc 65" "rc=$rc"; fi
(cd "$ROOT" && bash "$SCRIPT" 0 3 --nimporte "$WORK/dup.txt") >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 64 ]; then ok "C6d option inconnue en 3e position → rc 64 (usage)"; else ko "C6d" "rc 64" "rc=$rc"; fi

# --- C7 : petite liste — shards vides tolérés, union = la liste ----------------------------------------------------
SMALL="$WORK/petite.txt"; sed -n '3p;40p;120p' "$ALL" > "$SMALL"
union "$SCRIPT" "$N" "$SMALL" | LC_ALL=C sort > "$WORK/us.txt"
nvide=0; rcs=0; s=0
while [ "$s" -lt "$N" ]; do
  part "$SCRIPT" "$s" "$N" "$SMALL" > "$WORK/ps.txt"; r=$?; [ "$r" -eq 0 ] || rcs=1
  [ -s "$WORK/ps.txt" ] || nvide=$((nvide + 1)); s=$((s + 1))
done
LC_ALL=C sort "$SMALL" > "$WORK/small-sorted.txt"
if [ "$rcs" -eq 0 ] && cmp -s "$WORK/us.txt" "$WORK/small-sorted.txt" && [ "$nvide" -ge $((N - 3)) ]; then
  ok "C7 liste de 3 suites sur $N shards : union = la liste, $nvide shard(s) vide(s), tous rc 0"
else
  ko "C7 petite liste" "union = 3 suites, ≥ $((N - 3)) vides, rc 0" "rcs=$rcs vides=$nvide union=$(awk 'END { print NR }' "$WORK/us.txt")"
fi
: > "$WORK/vide.txt"
if [ -z "$(union "$SCRIPT" "$N" "$WORK/vide.txt")" ] && part "$SCRIPT" 0 "$N" "$WORK/vide.txt" >/dev/null; then ok "C7b liste vide : tous les shards sont vides, rc 0"; else ko "C7b liste vide" "shards vides, rc 0" "sortie non vide ou rc ≠ 0"; fi

# --- C8 : le glob projet-* est estimé à 540 s (arbre factice, la découverte y est relative) ----------------------------
FAKE="$WORK/fake"; mkdir -p "$FAKE/plugin/cockpit/scripts/tests"
for f in test-cockpit-projet-a.sh test-cockpit-projet-b.sh test-cockpit-collecte.sh; do : > "$FAKE/plugin/cockpit/scripts/tests/$f"; done
mkdir -p "$FAKE/scripts"
fake_part() { (cd "$FAKE" && bash "$1" "$2" 2 2>/dev/null); } # n=2
# 540 s chacune, collecte entre 7 et 540 s dans la table (379 s à la mesure du 2026-11-13 ; bandeau, 632 s, est devenue lourde
# donc réservée, d'où ce choix) : LPT → projet-a → 0, projet-b → 1, collecte → 0 (charges égales, indice le plus bas).
# À 7 s (défaut) la collecte passerait en tête : shard 0 = {collecte}. À > 600 s, deux lourdes + un reste sur 2 shards : rc 64.
P0="$(fake_part "$SCRIPT" 0 | tr '\n' ' ')"; P1="$(fake_part "$SCRIPT" 1 | tr '\n' ' ')"
if [ "$P0" = "plugin/cockpit/scripts/tests/test-cockpit-collecte.sh plugin/cockpit/scripts/tests/test-cockpit-projet-a.sh " ] \
   && [ "$P1" = "plugin/cockpit/scripts/tests/test-cockpit-projet-b.sh " ]; then
  ok "C8 projet-a, projet-b (inexistantes, glob) sont estimées à 540 s : < 600 s (non réservées), > 311 s (placées avant la collecte)"
else
  ko "C8 glob projet-*" "shard0={collecte,projet-a} shard1={projet-b}" "shard0=[$P0] shard1=[$P1]"
fi
if grep -qE '^540 plugin/cockpit/scripts/tests/test-cockpit-projet-\*\.sh$' "$SCRIPT"; then ok "C8b la table porte la ligne « 540 …/test-cockpit-projet-*.sh »"; else ko "C8b" "ligne 540 projet-*" "absente"; fi

# --- C9 : trop de suites lourdes → rc 64 ---------------------------------------------------------------------------------
printf '%s\n' "$XTERM" "$PROJET" "plugin/cockpit/scripts/tests/test-cockpit-collecte.sh" > "$WORK/lourdes.txt"
(cd "$ROOT" && bash "$SCRIPT" 0 2 --liste "$WORK/lourdes.txt") >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 64 ]; then ok "C9 deux suites lourdes + un reste sur 2 shards → rc 64"; else ko "C9" "rc 64" "rc=$rc"; fi

# ====================================================================================================================
# MUTANTS — chaque mutation est appliquée par sed sur une COPIE ; on vérifie (a) que la copie diffère de l'original,
# (b) que la propriété visée est rouge sur le mutant avec la trace, (c) qu'elle est verte sur l'original.
# ====================================================================================================================
okmut() { echo "  OK MUT-$1 TUE : $2"; PASS=$((PASS + 1)); }
komut() { echo "  KO MUT-$1 NON TUE : $2"; FAIL=$((FAIL + 1)); }
mutant() { # <id> <sed-script> -> chemin du mutant, ou rien si inchangé
  local f="$WORK/mut-$1.sh"; sed "$2" "$SCRIPT" > "$f"
  if cmp -s "$f" "$SCRIPT"; then echo ""; else echo "$f"; fi
}

# MUT-1 : le seuil de réservation devient inatteignable → xterm n'est plus réservée.
M="$(mutant 1 's/^SEUIL=600$/SEUIL=99999/')"
if [ -z "$M" ]; then komut 1 "sed sans effet (ligne SEUIL=600 introuvable)"
elif trm=$(heavy_alone "$M"); then komut 1 "suites lourdes toujours seules malgré SEUIL=99999"
elif heavy_alone "$SCRIPT" >/dev/null; then okmut 1 "suite lourde non réservée — rouge sur le mutant ($(echo "$trm" | head -1 | sed 's/^ *//')), vert sur l'original"
else komut 1 "la propriété est rouge sur l'original aussi"; fi

# MUT-2 : une suite est perdue par la partition (la 50e du tri est ignorée à l'impression).
M="$(mutant 2 's/if (s == shard) print p\[i\]/if (s == shard \&\& i != 50) print p[i]/')"
if [ -z "$M" ]; then komut 2 "sed sans effet"
else
  union "$M" "$N" | LC_ALL=C sort > "$WORK/um.txt"
  perdu="$(comm -23 "$ALL" "$WORK/um.txt" | head -1)"
  if [ -n "$perdu" ] && ! cmp -s "$WORK/um.txt" "$ALL"; then okmut 2 "union ≠ découverte, suite perdue : $perdu"; else komut 2 "l'union du mutant égale la découverte"; fi
fi

# MUT-3 : le LPT devient un tourniquet sur les shards non réservés.
M="$(mutant 3 's/else { s = nh; for (j = nh + 1; j < n; j++) if (load\[j\] < load\[s\]) s = j }/else { s = nh + (rr++ % (n - nh)) }/')"
if [ -z "$M" ]; then komut 3 "sed sans effet"
else
  tr3=$(lpt_ok "$M"); r3=$?
  if [ "$r3" -ne 0 ] && lpt_ok "$SCRIPT" >/dev/null; then okmut 3 "tourniquet : $(echo "$tr3" | sed 's/^ *//') — au-dessus de la borne $BORNE s ; LPT d'origine sous la borne"
  else komut 3 "charge max du tourniquet = $tr3 (borne $BORNE), original rc=$?"; fi
fi

# MUT-4 : --liste est ignorée (la partition porte sur la découverte complète).
M="$(mutant 4 's/^  sel="\$(grep \. "\$liste" | LC_ALL=C sort)"$/  sel="$disc"/')"
if [ -z "$M" ]; then komut 4 "sed sans effet"
else
  union "$M" "$N" "$SMALL" | LC_ALL=C sort > "$WORK/um.txt"
  nm="$(awk 'END { print NR }' "$WORK/um.txt")"
  if [ "$nm" -eq "$NALL" ] && ! cmp -s "$WORK/um.txt" "$WORK/small-sorted.txt"; then okmut 4 "--liste ignoré : $nm suites rendues pour une liste de 3 (union ≠ liste)"; else komut 4 "le mutant respecte la liste ($nm lignes)"; fi
fi

# MUT-5 : le contrôle « hors découverte » est neutralisé.
M="$(mutant 5 's/^  if \[ -n "\$inconnu" \]; then$/  if [ -n "" ]; then/')"
if [ -z "$M" ]; then komut 5 "sed sans effet"
else
  (cd "$ROOT" && bash "$M" 0 3 --liste "$WORK/inconnue.txt") >/dev/null 2>&1; rcm=$?
  (cd "$ROOT" && bash "$SCRIPT" 0 3 --liste "$WORK/inconnue.txt") >/dev/null 2>&1; rco=$?
  if [ "$rcm" -ne 65 ] && [ "$rco" -eq 65 ]; then okmut 5 "suite inconnue acceptée : rc_mutant=$rcm, rc_original=$rco (attendu 65)"; else komut 5 "rc_mutant=$rcm rc_original=$rco"; fi
fi

# MUT-6 : l'estimation par glob est supprimée (le défaut de 7 s s'applique à projet-*).
M="$(mutant 6 's/for (g = 1; g <= ng; g++) if/for (g = 1; g <= 0; g++) if/')"
if [ -z "$M" ]; then komut 6 "sed sans effet"
else
  m0="$(fake_part "$M" 0 | tr '\n' ' ')"
  if [ "$m0" = "plugin/cockpit/scripts/tests/test-cockpit-collecte.sh " ] && [ "$P0" != "$m0" ]; then okmut 6 "glob sans effet : shard0=[$m0] au lieu de [$P0]"; else komut 6 "shard0 du mutant = [$m0]"; fi
fi

echo
echo "== test-ci-shard-suites : bilan =="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
