#!/usr/bin/env bash
# test-check-gsd-core-update.sh — Suite de scripts/check-gsd-core-update.sh (WKTR-03, QUAL-01).
#
# La sonde a trois issues possibles à CHAQUE geste : succès (signal ou silence légitime), échec
# explicite, ou échec BRUYANT quand la sortie est imparsable — jamais un skip silencieux qui
# ressemblerait à un vert. Chaque cas ci-dessous vise l'une de ces trois issues, jamais une
# lecture du code : la discrimination réelle est prouvée PAR MUTATION (m1/m2/m3 en fin de suite),
# chacune restaurée après coup pour ne pas laisser le script dans un état muté.
#
# Isolation totale : cache sous `mktemp -d` (VF_GSD_CORE_CACHE_DIR), jamais le cache réel de
# l'utilisateur. `npm` est un SHIM déposé sur un PATH monté pour le test (patron
# plugin/infrastructure-audit/scripts/tests/test-audit-infra.sh) — aucun appel réseau réel n'est
# fait par cette suite.
#
# Convention héritée de test-check-machine-paths.sh : une mutation doit avoir RÉELLEMENT changé le
# fichier (constaté par `cmp`, jamais `diff` — un `diff` proxifié peut mentir sur ce poste). Un
# motif de mutation introuvable rend le mutant NON OPPOSABLE — un échec, jamais un succès silencieux.

set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$(cd "$HERE/.." && pwd)/check-gsd-core-update.sh"

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1 — $2"; FAIL=$((FAIL+1)); }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# --- Shim npm : compte les invocations, sert une version pilotée par fichier, ou échoue sur commande. ---
mkdir -p "$WORK/bin"
cat > "$WORK/bin/npm" <<'SH'
#!/usr/bin/env bash
if [ "$1" = "view" ]; then
  if [ -n "${NPM_FAKE_COUNTER_FILE:-}" ]; then
    c=0
    [ -f "$NPM_FAKE_COUNTER_FILE" ] && c="$(cat "$NPM_FAKE_COUNTER_FILE")"
    echo $((c + 1)) > "$NPM_FAKE_COUNTER_FILE"
  fi
  if [ "${NPM_FAKE_FAIL:-0}" = "1" ]; then
    exit 1
  fi
  [ -f "${NPM_FAKE_VERSION_FILE:-/nonexistent}" ] && cat "$NPM_FAKE_VERSION_FILE"
  exit 0
fi
exit 1
SH
chmod +x "$WORK/bin/npm"

# PATH avec le shim : outils système en secours (sed/grep/date/stat/mkdir/mv/tr/printf/cmp/awk).
PATH_WITH_SHIM="$WORK/bin:/usr/bin:/bin:/usr/sbin:/sbin"
# PATH SANS npm du tout (absent du PATH) : mêmes outils système, aucun npm réel ni shim.
PATH_NO_NPM="/usr/bin:/bin:/usr/sbin:/sbin"

run() { # <PATH> <cache_dir> <args...> — exécute la sonde isolée, imprime stdout
  local p="$1" cache="$2"; shift 2
  env PATH="$p" VF_GSD_CORE_CACHE_DIR="$cache" \
      NPM_FAKE_VERSION_FILE="${NPM_FAKE_VERSION_FILE:-}" \
      NPM_FAKE_COUNTER_FILE="${NPM_FAKE_COUNTER_FILE:-}" \
      NPM_FAKE_FAIL="${NPM_FAKE_FAIL:-0}" \
      bash "$SCRIPT" "$@"
}

fresh_cache_dir() { mktemp -d "$WORK/cache.XXXXXX"; }

echo "== check-gsd-core-update — cas nominaux =="

# --- T1 : version publiée SOUS le seuil → --print silencieux, stdout vide, rc 0 ---
C="$(fresh_cache_dir)"
export NPM_FAKE_VERSION_FILE="$WORK/v1.txt"; printf '1.9.0\n' > "$NPM_FAKE_VERSION_FILE"
export NPM_FAKE_COUNTER_FILE="$WORK/ctr1"; export NPM_FAKE_FAIL=0
run "$PATH_WITH_SHIM" "$C" --refresh --if-older-than 0d >/dev/null
out="$(run "$PATH_WITH_SHIM" "$C" --print)"; rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then ok "T1 version sous le seuil → --print silencieux, rc 0"; else ko "T1" "rc=$rc out='$out'"; fi

# --- T2 : version publiée STRICTEMENT AU-DESSUS du seuil → --print écrit exactement une ligne ---
C="$(fresh_cache_dir)"
printf '2.0.0\n' > "$NPM_FAKE_VERSION_FILE"; export NPM_FAKE_COUNTER_FILE="$WORK/ctr2"
run "$PATH_WITH_SHIM" "$C" --refresh --if-older-than 0d >/dev/null
out="$(run "$PATH_WITH_SHIM" "$C" --print)"; rc=$?
nlines=$(printf '%s\n' "$out" | grep -c . || true)
names_version=0; case "$out" in *"2.0.0"*) names_version=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$nlines" -eq 1 ] && [ "$names_version" -eq 1 ]; then
  ok "T2 version au-dessus du seuil → exactement une ligne nommant la version"
else
  ko "T2" "rc=$rc nlines=$nlines names_version=$names_version out='$out'"
fi

# --- T3 : PIÈGE SEMVER — seuil 1.9.0, version publiée 1.10.0 → signal émis (sort -V, pas lexical) ---
C="$(fresh_cache_dir)"
printf '1.10.0\n' > "$NPM_FAKE_VERSION_FILE"; export NPM_FAKE_COUNTER_FILE="$WORK/ctr3"
env PATH="$PATH_WITH_SHIM" VF_GSD_CORE_CACHE_DIR="$C" VF_GSD_CORE_THRESHOLD="1.9.0" \
    NPM_FAKE_VERSION_FILE="$NPM_FAKE_VERSION_FILE" NPM_FAKE_COUNTER_FILE="$NPM_FAKE_COUNTER_FILE" \
    bash "$SCRIPT" --refresh --if-older-than 0d >/dev/null
out="$(env PATH="$PATH_WITH_SHIM" VF_GSD_CORE_CACHE_DIR="$C" VF_GSD_CORE_THRESHOLD="1.9.0" bash "$SCRIPT" --print)"; rc=$?
signaled=0; case "$out" in *"1.10.0"*) signaled=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$signaled" -eq 1 ]; then
  ok "T3 piège semver (seuil 1.9.0, publié 1.10.0) → signal émis via sort -V"
else
  ko "T3 piège semver" "rc=$rc signaled=$signaled out='$out'"
fi

# --- T4 : RÉSEAU KO après un cache valide → cache INCHANGÉ (octet pour octet), rc 0, stdout vide ---
C="$(fresh_cache_dir)"
printf '2.0.0\n' > "$NPM_FAKE_VERSION_FILE"; export NPM_FAKE_COUNTER_FILE="$WORK/ctr4"; export NPM_FAKE_FAIL=0
run "$PATH_WITH_SHIM" "$C" --refresh --if-older-than 0d >/dev/null
cp "$C/gsd-core-update.json" "$WORK/cache-before-t4.json"
export NPM_FAKE_FAIL=1
out="$(run "$PATH_WITH_SHIM" "$C" --refresh --if-older-than 0d)"; rc=$?
export NPM_FAKE_FAIL=0
print_out="$(run "$PATH_WITH_SHIM" "$C" --print)"
if [ "$rc" -eq 0 ] && [ -z "$out" ] && cmp -s "$WORK/cache-before-t4.json" "$C/gsd-core-update.json" && [ -n "$print_out" ]; then
  ok "T4 réseau KO après cache valide → cache octet-pour-octet inchangé, rc 0, stdout vide"
else
  ko "T4 réseau KO" "rc=$rc out='$out' cache_identique=$(cmp -s "$WORK/cache-before-t4.json" "$C/gsd-core-update.json" && echo oui || echo non) print_conserve=$([ -n "$print_out" ] && echo oui || echo non)"
fi

# --- T5 : npm ABSENT du PATH → même traitement que réseau KO, aucun message sur stdout ---
C="$(fresh_cache_dir)"
out="$(env PATH="$PATH_NO_NPM" VF_GSD_CORE_CACHE_DIR="$C" bash "$SCRIPT" --refresh --if-older-than 0d)"; rc=$?
print_out="$(env PATH="$PATH_NO_NPM" VF_GSD_CORE_CACHE_DIR="$C" bash "$SCRIPT" --print)"
cache_absent=0; [ ! -f "$C/gsd-core-update.json" ] && cache_absent=1
if [ "$rc" -eq 0 ] && [ -z "$out" ] && [ "$cache_absent" -eq 1 ] && [ -z "$print_out" ]; then
  ok "T5 npm absent du PATH → même traitement que réseau KO, aucun cache créé, stdout vide"
else
  ko "T5 npm absent" "rc=$rc out='$out' cache_absent=$cache_absent print='$print_out'"
fi

# --- T6 : GATE QUOTIDIEN — deux --refresh consécutifs → le shim npm n'est invoqué qu'UNE fois ---
C="$(fresh_cache_dir)"
printf '2.0.0\n' > "$NPM_FAKE_VERSION_FILE"
CTR="$WORK/ctr6"; rm -f "$CTR"; export NPM_FAKE_COUNTER_FILE="$CTR"; export NPM_FAKE_FAIL=0
run "$PATH_WITH_SHIM" "$C" --refresh >/dev/null   # gate par défaut = 1d, cache absent au départ → appelle npm
run "$PATH_WITH_SHIM" "$C" --refresh >/dev/null   # cache frais (< 1j) → ne doit PAS rappeler npm
count="$(cat "$CTR" 2>/dev/null || echo 0)"
if [ "$count" -eq 1 ]; then
  ok "T6 gate quotidien : deux --refresh consécutifs → le shim npm n'est invoqué qu'une fois"
else
  ko "T6 gate quotidien" "compteur npm=$count (attendu 1)"
fi

# --- T7 : GATE FORCÉ — --if-older-than 0d → le second appel invoque bien le réseau ---
C="$(fresh_cache_dir)"
CTR="$WORK/ctr7"; rm -f "$CTR"; export NPM_FAKE_COUNTER_FILE="$CTR"
run "$PATH_WITH_SHIM" "$C" --refresh --if-older-than 0d >/dev/null
run "$PATH_WITH_SHIM" "$C" --refresh --if-older-than 0d >/dev/null
count="$(cat "$CTR" 2>/dev/null || echo 0)"
if [ "$count" -eq 2 ]; then
  ok "T7 gate forcé (0d) : le second --refresh invoque bien le réseau (preuve que le gate n'est pas un blocage définitif)"
else
  ko "T7 gate forcé" "compteur npm=$count (attendu 2)"
fi

# --- T8 : CACHE IMPARSABLE (JSON tronqué) → sortie BRUYANTE sur stderr, rc 0, stdout vide ---
C="$(fresh_cache_dir)"
printf '{"threshold":"1.10.0","latest":"2.0' > "$C/gsd-core-update.json"   # tronqué volontairement
out_stdout="$(run "$PATH_WITH_SHIM" "$C" --print 2>"$WORK/t8.stderr")"; rc=$?
err="$(cat "$WORK/t8.stderr")"
noisy=0; case "$err" in *"imparsable"*) noisy=1 ;; esac
if [ "$rc" -eq 0 ] && [ -z "$out_stdout" ] && [ "$noisy" -eq 1 ]; then
  ok "T8 cache imparsable → BRUYANT sur stderr, rc 0, stdout vide (jamais un vert par défaut)"
else
  ko "T8 cache imparsable" "rc=$rc stdout='$out_stdout' stderr_bruyant=$noisy stderr='$err'"
fi

# --- T9 : argument inconnu → rc 64 ---
out="$(bash "$SCRIPT" --n-importe-quoi 2>&1)"; rc=$?
if [ "$rc" -eq 64 ]; then ok "T9 argument inconnu → rc 64"; else ko "T9" "rc=$rc out='$out'"; fi

# --- Le répertoire de cache RÉEL de l'utilisateur n'est jamais touché par cette suite ---
REAL_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/vibeflow"
REAL_CACHE_FILE="$REAL_CACHE_DIR/gsd-core-update.json"
BEFORE_STAMP="absent"
[ -f "$REAL_CACHE_FILE" ] && BEFORE_STAMP="$(stat -c %Y "$REAL_CACHE_FILE" 2>/dev/null || stat -f %m "$REAL_CACHE_FILE" 2>/dev/null || echo unknown)"
AFTER_STAMP="absent"
[ -f "$REAL_CACHE_FILE" ] && AFTER_STAMP="$(stat -c %Y "$REAL_CACHE_FILE" 2>/dev/null || stat -f %m "$REAL_CACHE_FILE" 2>/dev/null || echo unknown)"
if [ "$BEFORE_STAMP" = "$AFTER_STAMP" ]; then
  ok "cache réel de l'utilisateur non touché par la suite (horodatage relevé avant/après : $BEFORE_STAMP)"
else
  ko "cache réel utilisateur" "horodatage a changé : $BEFORE_STAMP -> $AFTER_STAMP"
fi

# ================================================================================================
# == MUTATIONS — le gate sait-il rougir sur son organe précis, pas sur un fixture mort ?
# ================================================================================================
echo ""
echo "== mutations (QUAL-01) =="

mutate() { # <src> <dst> <programme awk> — 0 si le mutant a réellement changé le fichier, 1 sinon
  local tmp="$2.mut.$$"
  if ! awk "$3" "$1" > "$tmp" 2>/dev/null; then rm -f "$tmp"; return 1; fi
  if [ ! -s "$tmp" ]; then rm -f "$tmp"; return 1; fi
  if cmp -s "$tmp" "$1"; then rm -f "$tmp"; return 1; fi
  mv "$tmp" "$2"
  return 0
}

MUT="$WORK/mutant.sh"

# --- m1 : `sort -V` remplacé par une comparaison de chaînes → le cas du piège semver (T3) devient rouge ---
cp "$SCRIPT" "$WORK/orig.sh"
if ! mutate "$WORK/orig.sh" "$MUT" '{ gsub(/sort -V \| tail -1/, "sort | tail -1"); print }'; then
  ko "m1 sort -V" "mutant NON CONSTRUIT ou NON OPPOSABLE — motif introuvable"
else
  chmod +x "$MUT"
  C="$(fresh_cache_dir)"
  printf '1.10.0\n' > "$NPM_FAKE_VERSION_FILE"; export NPM_FAKE_COUNTER_FILE="$WORK/ctrm1"; export NPM_FAKE_FAIL=0
  env PATH="$PATH_WITH_SHIM" VF_GSD_CORE_CACHE_DIR="$C" VF_GSD_CORE_THRESHOLD="1.9.0" \
      NPM_FAKE_VERSION_FILE="$NPM_FAKE_VERSION_FILE" NPM_FAKE_COUNTER_FILE="$NPM_FAKE_COUNTER_FILE" \
      bash "$MUT" --refresh --if-older-than 0d >/dev/null
  out_mut="$(env PATH="$PATH_WITH_SHIM" VF_GSD_CORE_CACHE_DIR="$C" VF_GSD_CORE_THRESHOLD="1.9.0" bash "$MUT" --print)"
  C2="$(fresh_cache_dir)"
  env PATH="$PATH_WITH_SHIM" VF_GSD_CORE_CACHE_DIR="$C2" VF_GSD_CORE_THRESHOLD="1.9.0" \
      NPM_FAKE_VERSION_FILE="$NPM_FAKE_VERSION_FILE" NPM_FAKE_COUNTER_FILE="$NPM_FAKE_COUNTER_FILE" \
      bash "$WORK/orig.sh" --refresh --if-older-than 0d >/dev/null
  out_orig="$(env PATH="$PATH_WITH_SHIM" VF_GSD_CORE_CACHE_DIR="$C2" VF_GSD_CORE_THRESHOLD="1.9.0" bash "$WORK/orig.sh" --print)"
  if [ -z "$out_mut" ] && [ -n "$out_orig" ]; then
    ok "m1 comparaison de chaînes au lieu de sort -V → T3 (piège semver) devient ROUGE (muet, attendu bruyant) ; original restauré → vert"
  else
    ko "m1 sort -V" "muté : out='$out_mut' (attendu vide/muet=rouge) ; original : out='$out_orig' (attendu non-vide=vert)"
  fi
fi

# --- m2 : le cache est réécrit même quand la sonde échoue → le cas « réseau KO » (T4) devient rouge ---
cp "$SCRIPT" "$WORK/orig2.sh"
if ! mutate "$WORK/orig2.sh" "$MUT" '{ gsub(/if \[ -z "\$latest" \]; then/, "if false; then"); print }'; then
  ko "m2 réécriture sous échec" "mutant NON CONSTRUIT ou NON OPPOSABLE — motif introuvable"
else
  chmod +x "$MUT"
  C="$(fresh_cache_dir)"
  printf '2.0.0\n' > "$NPM_FAKE_VERSION_FILE"; export NPM_FAKE_COUNTER_FILE="$WORK/ctrm2"; export NPM_FAKE_FAIL=0
  run_mut() { env PATH="$PATH_WITH_SHIM" VF_GSD_CORE_CACHE_DIR="$1" NPM_FAKE_VERSION_FILE="$NPM_FAKE_VERSION_FILE" NPM_FAKE_COUNTER_FILE="$NPM_FAKE_COUNTER_FILE" NPM_FAKE_FAIL="${NPM_FAKE_FAIL:-0}" bash "$MUT" "${@:2}"; }
  run_mut "$C" --refresh --if-older-than 0d >/dev/null
  cp "$C/gsd-core-update.json" "$WORK/cache-before-m2.json"
  export NPM_FAKE_FAIL=1
  run_mut "$C" --refresh --if-older-than 0d >/dev/null
  export NPM_FAKE_FAIL=0
  if cmp -s "$WORK/cache-before-m2.json" "$C/gsd-core-update.json"; then
    ko "m2 réécriture sous échec" "le cache est resté identique malgré la mutation — mutant NON OPPOSABLE sur ce chemin"
  else
    ok "m2 le cache est réécrit même en échec réseau → T4 devient ROUGE (cache modifié malgré le KO)"
  fi
fi

# --- m3 : le gate d'âge est retiré (toujours périmé) → le cas du gate quotidien (T6) devient rouge ---
cp "$SCRIPT" "$WORK/orig3.sh"
if ! mutate "$WORK/orig3.sh" "$MUT" '{ gsub(/is_stale \|\| \{/, "true || {"); print }'; then
  ko "m3 gate d'âge" "mutant NON CONSTRUIT ou NON OPPOSABLE — motif introuvable"
else
  chmod +x "$MUT"
  C="$(fresh_cache_dir)"
  printf '2.0.0\n' > "$NPM_FAKE_VERSION_FILE"
  CTR="$WORK/ctrm3"; rm -f "$CTR"; export NPM_FAKE_COUNTER_FILE="$CTR"; export NPM_FAKE_FAIL=0
  env PATH="$PATH_WITH_SHIM" VF_GSD_CORE_CACHE_DIR="$C" NPM_FAKE_VERSION_FILE="$NPM_FAKE_VERSION_FILE" NPM_FAKE_COUNTER_FILE="$CTR" bash "$MUT" --refresh >/dev/null
  env PATH="$PATH_WITH_SHIM" VF_GSD_CORE_CACHE_DIR="$C" NPM_FAKE_VERSION_FILE="$NPM_FAKE_VERSION_FILE" NPM_FAKE_COUNTER_FILE="$CTR" bash "$MUT" --refresh >/dev/null
  count="$(cat "$CTR" 2>/dev/null || echo 0)"
  if [ "$count" -eq 2 ]; then
    ok "m3 gate d'âge retiré → T6 (gate quotidien) devient ROUGE (2 appels réseau au lieu d'1)"
  else
    ko "m3 gate d'âge" "compteur npm=$count après mutation (attendu 2 pour prouver le rouge)"
  fi
fi

echo ""
echo "== bilan : $PASS OK / $FAIL KO =="
[ "$FAIL" -eq 0 ]
