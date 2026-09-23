#!/usr/bin/env bash
# test-check-release-tag.sh — Suite de verification de check-release-tag.sh, volet fenetre de
# grace (ADR-073). Couvre les quatre situations mandatees : tag present, tag absent DANS la
# fenetre, tag absent HORS fenetre, mode --remote sans release GitHub.
#
# Chaque fixture est un depot git jetable sous mktemp (jamais le depot reel) : VERSION, un commit
# dont la date est controlee via GIT_AUTHOR_DATE/GIT_COMMITTER_DATE au format "@<epoch>" (portable
# macOS/Linux, contrairement a `date -d`), et un stub scripts/check-version-sync.sh qui reussit
# toujours (ce volet n'est pas sous test ici). Aucun appel reseau reel : le remote `origin` est un
# depot bare local, et `gh` est un binaire jetable pose en tete de PATH.
#
# CINQ cas + UN mutant opposable. Regle de comptage (meme patron que test-check-push-sans-pr.sh) :
# chaque mutant asserte le rc EXACT attendu sur le mutant ET sur l'original.
set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-release-tag.sh"

PASS=0; FAIL=0
ok() { echo "  OK $1"; PASS=$((PASS + 1)); }
ko() {
  echo "  KO $1"
  echo "    attendu : $2"
  echo "    obtenu  : $3"
  FAIL=$((FAIL + 1))
}
okmut() { echo "  OK MUT-$1 TUE : rc_mutant=$2 attendu $3, rc_original=$4 attendu $5"; PASS=$((PASS + 1)); }
komut() {
  echo "  KO MUT-$1 NON TUE : $2"
  echo "    attendu : $3"
  echo "    obtenu  : $4"
  FAIL=$((FAIL + 1))
}

WORKROOT="$(mktemp -d)"
BARE="$WORKROOT/origin.git"
GHBIN="$WORKROOT/ghbin"
trap 'rm -rf "$WORKROOT"' EXIT

git init -q --bare "$BARE"
mkdir -p "$GHBIN"

# mk_fake_gh <rc_release_view> — pose un `gh` jetable en tete de PATH. `gh release view <tag>`
# rend rc_release_view ; les autres sous-commandes ne sont pas utilisees par le script sous test
# une fois le tag pousse (branche gh privilegiee).
mk_fake_gh() {
  local rc="$1"
  cat > "$GHBIN/gh" <<GHSTUB
#!/bin/sh
case "\$1 \$2" in
  "release view") exit $rc ;;
esac
exit 0
GHSTUB
  chmod +x "$GHBIN/gh"
}

# setup_repo <version> <commit_age_seconds_ago> -> imprime le chemin du repo jetable, VERSION
# ecrit, un commit dont la date est now-<age>, remote origin = $BARE.
setup_repo() {
  local version="$1" age="$2"
  local dir; dir="$(mktemp -d -p "$WORKROOT")"
  git init -q -b main "$dir"
  git -C "$dir" config user.email t@t.co
  git -C "$dir" config user.name Test
  git -C "$dir" remote add origin "$BARE"
  mkdir -p "$dir/scripts"
  cat > "$dir/scripts/check-version-sync.sh" <<'SYNC'
#!/usr/bin/env bash
exit 0
SYNC
  chmod +x "$dir/scripts/check-version-sync.sh"
  printf '%s\n' "$version" > "$dir/VERSION"
  git -C "$dir" add -A
  local ts; ts=$(( $(date +%s) - age ))
  GIT_AUTHOR_DATE="@$ts" GIT_COMMITTER_DATE="@$ts" git -C "$dir" commit -q -m "release $version"
  echo "$dir"
}

# run <repo> [args...] -> stdout+stderr fusionnes, rc capture dans $rc (jamais sous set -e).
run() {
  local dir="$1"; shift
  local out rc
  set +e
  out="$(cd "$dir" && PATH="$GHBIN:$PATH" bash "$SCRIPT" "$@" 2>&1)"
  rc=$?
  set -e
  printf '%s' "$out"
  return "$rc"
}

echo "== test-check-release-tag : PASS =="

# --- CAS 1 : tag present (local) -> rc0, hors --remote -----------------------------------------
R1="$(setup_repo "2.64.0" 3600)"
git -C "$R1" tag -a v2.64.0 -m "v2.64.0 — test" >/dev/null
set +e; OUT1="$(run "$R1")"; RC1=$?; set -e
if [ "$RC1" -eq 0 ]; then ok "cas1 tag present -> rc0"; else ko "cas1 tag present -> rc0" "0" "$RC1 ($OUT1)"; fi

# --- CAS 2 : tag absent, commit RECENT (dans la fenetre par defaut 900s) -> rc3 ----------------
R2="$(setup_repo "2.65.0" 10)"
set +e; OUT2="$(run "$R2")"; RC2=$?; set -e
if [ "$RC2" -eq 3 ]; then ok "cas2 tag absent dans la fenetre -> rc3"; else ko "cas2 tag absent dans la fenetre -> rc3" "3" "$RC2 ($OUT2)"; fi
case "$OUT2" in
  *"fenêtre de grâce"*) ok "cas2 message mentionne la fenetre de grace" ;;
  *) ko "cas2 message mentionne la fenetre de grace" "contient 'fenêtre de grâce'" "$OUT2" ;;
esac

# --- CAS 3 : tag absent, commit HORS fenetre (grace custom courte) -> rc1 ----------------------
R3="$(setup_repo "2.66.0" 3600)"
set +e; OUT3="$(VF_RELEASE_TAG_GRACE_SECONDS=60 run "$R3")"; RC3=$?; set -e
if [ "$RC3" -eq 1 ]; then ok "cas3 tag absent hors fenetre -> rc1"; else ko "cas3 tag absent hors fenetre -> rc1" "1" "$RC3 ($OUT3)"; fi
case "$OUT3" in
  *"hors fenêtre de grâce"*) ok "cas3 message mentionne 'hors fenêtre de grâce'" ;;
  *) ko "cas3 message mentionne 'hors fenêtre de grâce'" "contient 'hors fenêtre de grâce'" "$OUT3" ;;
esac

# --- CAS 4 : --remote, tag present + pousse, SANS release GitHub -> rc1 ------------------------
R4="$(setup_repo "2.67.0" 3600)"
git -C "$R4" tag -a v2.67.0 -m "v2.67.0 — test" >/dev/null
git -C "$R4" push -q origin v2.67.0
mk_fake_gh 1
set +e; OUT4="$(run "$R4" --remote)"; RC4=$?; set -e
if [ "$RC4" -eq 1 ]; then ok "cas4 --remote sans release GitHub -> rc1"; else ko "cas4 --remote sans release GitHub -> rc1" "1" "$RC4 ($OUT4)"; fi
case "$OUT4" in
  *"AUCUNE release GitHub"*) ok "cas4 message mentionne l'absence de release" ;;
  *) ko "cas4 message mentionne l'absence de release" "contient 'AUCUNE release GitHub'" "$OUT4" ;;
esac

# --- CAS 5 (regression guard) : --remote, tag present + pousse + release presente -> rc0 -------
R5="$(setup_repo "2.68.0" 3600)"
git -C "$R5" tag -a v2.68.0 -m "v2.68.0 — test" >/dev/null
git -C "$R5" push -q origin v2.68.0
mk_fake_gh 0
set +e; OUT5="$(run "$R5" --remote)"; RC5=$?; set -e
if [ "$RC5" -eq 0 ]; then ok "cas5 --remote conforme -> rc0"; else ko "cas5 --remote conforme -> rc0" "0" "$RC5 ($OUT5)"; fi

echo "== test-check-release-tag : MUTANT =="

# --- MUT-1 : la fenetre de grace par defaut est ecrasee a 0s -> le cas2 (rc3 attendu) doit
# devenir rc1 sur le mutant, et rester rc3 sur l'original. Preuve que la fenetre de grace est
# reellement ce qui fait la difference (regle de comptage : rc exact sur mutant ET original).
MUTD="$(mktemp -d -p "$WORKROOT")"
MUT1="$MUTD/mut1.sh"
awk '{ if ($0 == "  grace=\"${VF_RELEASE_TAG_GRACE_SECONDS:-900}\"") { print "  grace=\"${VF_RELEASE_TAG_GRACE_SECONDS:-0}\"" } else { print } }' "$SCRIPT" > "$MUT1"
if cmp -s "$MUT1" "$SCRIPT"; then
  komut 1 "mutant identique a l'original (non opposable)" "fichiers differents" "identiques"
elif ! bash -n "$MUT1" 2>/dev/null; then
  komut 1 "mutant syntaxiquement invalide" "bash -n OK" "bash -n KO"
else
  set +e
  OUTM="$(cd "$R2" && PATH="$GHBIN:$PATH" bash "$MUT1" 2>&1)"; RCM=$?
  OUTO="$(cd "$R2" && PATH="$GHBIN:$PATH" bash "$SCRIPT" 2>&1)"; RCO=$?
  set -e
  if [ "$RCM" -eq 1 ] && [ "$RCO" -eq 3 ]; then
    okmut 1 "$RCM" "1" "$RCO" "3"
  else
    komut 1 "rc mutant=1 (grace ecrasee a 0) et rc original=3 (fenetre par defaut)" "rc_mutant=1, rc_original=3" "rc_mutant=$RCM, rc_original=$RCO"
  fi
fi

echo
echo "== test-check-release-tag : bilan =="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
