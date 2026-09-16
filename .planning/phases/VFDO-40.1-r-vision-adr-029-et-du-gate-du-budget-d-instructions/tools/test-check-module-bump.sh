#!/usr/bin/env bash
# test-check-module-bump.sh — fixtures jetables pour phase-base.sh et check-module-bump.sh.
# Cas B1-B15 (voir 40.1-02-PLAN.md, Task 1). Sortie: "== resultat : N ok, M ko ==".
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CMB="$SCRIPT_DIR/check-module-bump.sh"
PB="$SCRIPT_DIR/phase-base.sh"

OK=0
KO=0

report() { # <label> <verdict: ok|ko> <detail>
  if [ "$2" = ok ]; then
    echo "✓ $1 — $3"
    OK=$((OK + 1))
  else
    echo "✗ $1 — $3"
    KO=$((KO + 1))
  fi
}

mkbase() { # -> imprime le chemin du depot jetable sur stdout
  local r
  r="$(mktemp -d)"
  git -C "$r" -c user.name=t -c user.email=t@t.co init -q -b main
  mkdir -p "$r/plugin/m"
  printf 'v1.2.3\n' > "$r/plugin/m/VERSION"
  printf '{\n  "name": "m",\n  "version": "v1.2.3"\n}\n' > "$r/plugin/m/module.json"
  printf '# Changelog — m\n\n## [v1.2.3] — base\n' > "$r/plugin/m/CHANGELOG.md"
  printf '**Version** : v1.2.3\n' > "$r/plugin/m/README.md"
  git -C "$r" add -A
  git -C "$r" -c user.name=t -c user.email=t@t.co commit -q -m "base v1.2.3"
  git -C "$r" checkout -q -b w
  printf '%s\n' "$r"
}

bump_commit() { # <repo> <version> <changelog-line> <subject> <touch-module-json:0|1>
  local r="$1" ver="$2" cl="$3" subj="$4" touch_mj="$5"
  printf '%s\n' "$ver" > "$r/plugin/m/VERSION"
  if [ "$touch_mj" -eq 1 ]; then
    printf '{\n  "name": "m",\n  "version": "%s"\n}\n' "$ver" > "$r/plugin/m/module.json"
  fi
  { printf '# Changelog — m\n\n%s\n' "$cl"; tail -n +2 "$r/plugin/m/CHANGELOG.md" 2>/dev/null | tail -n +2; } > "$r/plugin/m/CHANGELOG.md.new"
  mv "$r/plugin/m/CHANGELOG.md.new" "$r/plugin/m/CHANGELOG.md"
  printf '**Version** : %s\n' "$ver" > "$r/plugin/m/README.md"
  git -C "$r" add -A
  git -C "$r" -c user.name=t -c user.email=t@t.co commit -q -m "$subj"
}

rc_of() { # <repo> <module> <kind> [extra args...] -> imprime le rc, capture stdout/stderr dans $LAST_OUT
  local r="$1" m="$2" k="$3" _rc=0
  shift 3
  LAST_OUT="$(bash "$CMB" "$m" "$k" --root "$r" "$@" 2>&1)" && _rc=0 || _rc=$?
  return "$_rc"
}

# --- B1-B9 : sur un depot de base commun a chaque cas (rebranche a chaque fois) ------------------

R="$(mkbase)"
bump_commit "$R" v1.2.4 "## [v1.2.4] — d (Phase 40.1)" "bump: v1.2.4" 1
rc1=0; rc_of "$R" m patch --main-ref main || rc1=$?
[ "$rc1" -eq 0 ] && v=ok || v=ko
report B1 "$v" "attendu rc=0 (patch conforme), obtenu rc=$rc1 : $LAST_OUT"

rc2=0; rc_of "$R" m minor --main-ref main || rc2=$?
[ "$rc2" -eq 1 ] && v=ok || v=ko
report B2 "$v" "attendu rc=1 (minor sur un bump patch), obtenu rc=$rc2"

R="$(mkbase)"
bump_commit "$R" v1.3.0 "## [v1.3.0] — d (Phase 40.1)" "bump: v1.3.0" 1
rc3=0; rc_of "$R" m minor --main-ref main || rc3=$?
[ "$rc3" -eq 0 ] && v=ok || v=ko
report B3 "$v" "attendu rc=0 (minor conforme), obtenu rc=$rc3 : $LAST_OUT"

R="$(mkbase)"
git -C "$R" checkout -q main
bump_commit "$R" v1.2.4 "## [v1.2.4] — hotfix" "hotfix: v1.2.4" 1
git -C "$R" checkout -q w
git -C "$R" -c user.name=t -c user.email=t@t.co rebase -q main >/dev/null 2>&1
git -C "$R" -c user.name=t -c user.email=t@t.co commit -q --allow-empty -m "w1 (sans bump)"
rc4=0; rc_of "$R" m patch --main-ref main || rc4=$?
[ "$rc4" -eq 1 ] && v=ok || v=ko
report B4 "$v" "hotfix integre par main non impute, attendu rc=1, obtenu rc=$rc4"

R="$(mkbase)"
bump_commit "$R" v1.2.4 "## [v1.2.4] — sans marqueur de phase" "bump: v1.2.4" 1
rc5=0; rc_of "$R" m patch --main-ref main || rc5=$?
[ "$rc5" -eq 1 ] && v=ok || v=ko
report B5 "$v" "CHANGELOG sans 'Phase 40.1', attendu rc=1, obtenu rc=$rc5"

R="$(mkbase)"
bump_commit "$R" v1.2.4 "## [v1.2.4] — d (Phase 40.1)" "bump: v1.2.4 sans module.json" 0
rc6=0; rc_of "$R" m patch --main-ref main || rc6=$?
[ "$rc6" -eq 1 ] && v=ok || v=ko
report B6 "$v" "module.json reste en v1.2.3, attendu rc=1, obtenu rc=$rc6"

R="$(mkbase)"
git -C "$R" checkout -q main
bump_commit "$R" v1.2.4 "## [v1.2.4] — hotfix" "hotfix: v1.2.4" 1
git -C "$R" checkout -q w
git -C "$R" -c user.name=t -c user.email=t@t.co rebase -q main >/dev/null 2>&1
bump_commit "$R" v1.2.5 "## [v1.2.5] — d (Phase 40.1)" "bump: v1.2.5" 1
rc7=0; rc_of "$R" m patch --main-ref main || rc7=$?
case "$LAST_OUT" in
  *"v1.2.4 → v1.2.5"*) msg_ok=1 ;;
  *) msg_ok=0 ;;
esac
[ "$rc7" -eq 0 ] && [ "$msg_ok" -eq 1 ] && v=ok || v=ko
report B7 "$v" "derivation apres hotfix, attendu rc=0 avec 'v1.2.4 → v1.2.5', obtenu rc=$rc7 : $LAST_OUT"

R="$(mkbase)"
bump_commit "$R" v1.2.4 "## [v1.2.4] — d (Phase 40.1)" "bump" 1
rc8=0; rc_of "$R" m patch --main-ref main || rc8=$?
[ "$rc8" -eq 0 ] && v=ok || v=ko
report B8 "$v" "sujet non prefixe impute quand meme, attendu rc=0, obtenu rc=$rc8 : $LAST_OUT"

R="$(mktemp -d)"
rc9=0; rc_of "$R" m patch --main-ref main || rc9=$?
[ "$rc9" -eq 2 ] && v=ok || v=ko
report B9 "$v" "repertoire non git, attendu rc=2, obtenu rc=$rc9"

R="$(mkbase)"
git -C "$R" branch -m main trunk
rc10=0; rc_of "$R" m patch || rc10=$?
[ "$rc10" -eq 2 ] && v=ok || v=ko
report B10 "$v" "phase-base.sh sans aucune ref main (branche renommee, pas de --main-ref), attendu rc=2, obtenu rc=$rc10"

# --- B11-B15 : resolution de ref de phase-base.sh (meme fixture c0/c1/c2/d1 que le verify du plan)

R="$(mktemp -d)"
g() { git -C "$R" -c user.name=t -c user.email=t@t.co "$@"; }
g init -q -b main
g commit -q --allow-empty -m c0
g commit -q --allow-empty -m c1
c1="$(g rev-parse HEAD)"
g commit -q --allow-empty -m c2
c2="$(g rev-parse HEAD)"
d1="$(g commit-tree "$c1^{tree}" -p "$c1" -m d1)"
g checkout -q -b w
g commit -q --allow-empty -m w1

pb_case() { # <label> <expected_rc> <expected_base|-> [extra args...]
  local label="$1" exp_rc="$2" exp_base="$3"
  shift 3
  local out rc=0 base
  out="$(bash "$PB" --root "$R" "$@" 2>"$R.err")" && rc=0 || rc=$?
  base="$(printf '%s' "$out" | awk 'NR==1')"
  local v=ok detail=""
  if [ "$rc" -ne "$exp_rc" ]; then v=ko; fi
  if [ "$exp_rc" -eq 0 ] && [ "$base" != "$exp_base" ]; then v=ko; fi
  if [ "$exp_base" = DIVERGENCE ]; then
    if ! grep -q diverge "$R.err"; then v=ko; fi
  fi
  detail="attendu rc=$exp_rc base=$exp_base, obtenu rc=$rc base=${base:-vide}"
  report "$label" "$v" "$detail"
}

g update-ref refs/heads/main "$c1"
g update-ref refs/remotes/origin/main "$c2"
pb_case B11 0 "$c2"

g update-ref refs/heads/main "$c2"
g update-ref refs/remotes/origin/main "$c1"
pb_case B12 0 "$c2"

g update-ref refs/heads/main "$c2"
g update-ref refs/remotes/origin/main "$d1"
pb_case B13 2 DIVERGENCE

pb_case B14 0 "$c1" --main-ref origin/main

g update-ref -d refs/heads/main
g update-ref refs/remotes/origin/main "$c2"
pb_case B15 0 "$c2"

echo "== resultat : $OK ok, $KO ko =="
[ "$KO" -eq 0 ]
