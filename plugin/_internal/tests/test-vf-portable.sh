#!/usr/bin/env bash
# test-vf-portable.sh — Suite de vérification de la lib partagée vf-portable.sh (contrat PR #29,
# D-04, Phase 30 plan 30-05).
#
# T1  — chargement sous `set -u` sans erreur, aucun effet de bord.
# T2  — les 5 symboles du contrat sont bien des fonctions après chargement.
# T3  — vf_python exécute réellement un programme Python trivial.
# T4  — un candidat stub *WindowsApps* est REJETÉ par la sonde (profil complet).
# T5  — le profil rapide (--fast) ne lance AUCUN processus (compteur de shim).
# T6  — vf_guard_unavailable : marqueur écrit, motif sur stderr, code rendu non nul ET != 2.
# T7  — répertoire de marqueurs non créable : le motif est quand même imprimé, même code rendu.
# T8  — cascade vf_resolve_python : candidat retenu mémorisé (pas de re-sonde au second appel).
#
# Intégration engine (tâche 2, copy_engine_lib()) :
# T9  — install d'un module → la lib est posée À PLAT dans le répertoire de scripts du lab,
#       NON exécutable, contenu identique à la source (cmp).
# T10 — resync gouvernance (version inchangée, chemin `update`) → la lib reste posée et identique,
#       aucun doublon de fichier.
# T11 — lib source absente du cache (engine isolé, ni cache ni voisinage) → l'install ÉCHOUE,
#       le message nomme la lib, le lab n'est PAS marqué installé (VG-3).
#
# Identité du bloc localisateur (tâche 3, contrat §3/§6) :
# T12 — les 4 consommateurs PYBIN (guard-file-size.sh, inject-mcp-tools.sh,
#       test-dev-orchestrator.sh, check-hook-paths.sh) reproduisent le MÊME bloc (une seule somme
#       de contrôle après normalisation du préfixe de message, le seul jeton autorisé à varier).
# T13 — l'extraction ne rend JAMAIS une somme sur un fichier sans les deux marqueurs appariés
#       (échec BRUYANT, jamais un vert par défaut sur « aucun bloc trouvé »).
#
# Convention TESTING.md du dépôt : ok()/ko()/skip(), isolation mktemp, trois issues par cas
# (jamais un skip silencieux sur les cas T1-T8/T12/T13 — seules les extensions d'intégration
# engine, ajoutées par la tâche 2, peuvent SKIP proprement si l'environnement ne le permet pas).
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
INTERNAL_DIR="$(cd "$HERE/.." && pwd)"
LIB="$INTERNAL_DIR/lib/vf-portable.sh"
REPO="$(cd "$INTERNAL_DIR/.." && pwd)"          # = .../plugin (même convention que test-vibeflow-update.sh)
INSTALLER="$INTERNAL_DIR/vibeflow-update.sh"

pass=0; fail=0; skipped=0
ok()   { echo "  ✓ $1"; pass=$((pass+1)); }
ko()   { echo "  ✗ $1"; fail=$((fail+1)); }
skip() { echo "  ⊘ SKIP $1"; skipped=$((skipped+1)); }

echo "== test-vf-portable (lib: $LIB) =="

[ -f "$LIB" ] || { echo "FATAL: lib introuvable : $LIB" >&2; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# ---------- T1 : chargement sous `set -u`, aucune erreur ----------
T1_OUT=$(bash -u -c "set -u; . '$LIB'; echo ok" 2>&1)
if [ "$T1_OUT" = "ok" ]; then
  ok "T1 chargement sous set -u : silencieux, aucune erreur"
else
  ko "T1 chargement sous set -u : sortie inattendue [$T1_OUT]"
fi

# ---------- T2 : les 5 symboles sont des fonctions ----------
T2_OUT=$(bash -c ". '$LIB'; type vf_resolve_python vf_python vf_py_probe jqx vf_guard_unavailable 2>&1 | grep -c 'is a function'")
if [ "$T2_OUT" = "5" ]; then
  ok "T2 les 5 symboles du contrat sont des fonctions"
else
  ko "T2 attendu 5 fonctions, trouvé [$T2_OUT]"
fi

# ---------- T3 : vf_python exécute réellement un programme Python ----------
T3_OUT=$(bash -c ". '$LIB'; vf_python -c 'import sys; print(sys.version_info[0])'" 2>/dev/null)
if [ "$T3_OUT" = "3" ]; then
  ok "T3 vf_python invoque réellement l'interpréteur (version majeure = 3)"
else
  ko "T3 vf_python n'a pas rendu '3' — sortie=[$T3_OUT]"
fi

# ---------- T4 : candidat stub *WindowsApps* rejeté par la sonde ----------
# Le stub DÉLÈGUE au vrai python3 (donc réussirait la sonde d'exécution si le rejet par CHEMIN
# était absent) : le cas ne discrimine le rejet-par-chemin QUE si le stub, une fois cette exclusion
# retirée, passerait la sonde — un stub qui échoue toujours (ex. `exit 49` inconditionnel) masque
# la mutation m1 (le rejet réussirait pour la mauvaise raison, via l'échec d'exécution).
REAL_PY3="$(command -v python3)"
STUB_DIR="$WORK/WindowsApps"
mkdir -p "$STUB_DIR"
cat > "$STUB_DIR/python3" <<STUB
#!/bin/bash
exec "$REAL_PY3" "\$@"
STUB
chmod +x "$STUB_DIR/python3"
T4_RC=0
env PATH="$STUB_DIR:/usr/bin:/bin" bash -c ". '$LIB'; vf_py_probe python3" >/dev/null 2>&1 || T4_RC=$?
if [ "$T4_RC" -ne 0 ]; then
  ok "T4 candidat stub *WindowsApps* rejeté par vf_py_probe (rc=$T4_RC) — le stub délègue au vrai python3, seul le rejet par CHEMIN l'exclut"
else
  ko "T4 candidat stub *WindowsApps* accepté à tort (rc=0)"
fi

# ---------- T5 : profil rapide (--fast) — zéro spawn ajouté ----------
# Shim complet : PATH pointe UNIQUEMENT vers ce dossier, python3 est un compteur qui s'incrémente
# à chaque exécution ; on prouve qu'un profil rapide ne l'exécute JAMAIS (seule sa présence/son
# chemin sont contrôlés par `command -v`, jamais un spawn réel).
FAST_BIN="$WORK/fastbin"
mkdir -p "$FAST_BIN"
COUNTER="$WORK/spawn-count"
: > "$COUNTER"
cat > "$FAST_BIN/python3" <<SH
#!/bin/bash
echo x >> "$COUNTER"
exit 0
SH
chmod +x "$FAST_BIN/python3"
for t in bash cat command timeout; do
  p=$(command -v "$t" 2>/dev/null) && ln -sf "$p" "$FAST_BIN/$t" 2>/dev/null
done
env PATH="$FAST_BIN" bash -c ". '$LIB'; vf_py_probe python3 --fast" >/dev/null 2>&1
SPAWNS="$(wc -l < "$COUNTER" | tr -d ' ')"
if [ "$SPAWNS" = "0" ]; then
  ok "T5 profil rapide (--fast) : zéro processus python3 lancé (compteur=$SPAWNS)"
else
  ko "T5 profil rapide (--fast) : $SPAWNS processus python3 lancé(s) — régression de latence"
fi

# ---------- T6 : vf_guard_unavailable — marqueur écrit, motif stderr, code non nul != 2 ----------
T6_HEALTH="$WORK/health-ok"
T6_ERR="$WORK/t6.err"
T6_RC=0
env VF_GUARD_HEALTH_DIR="$T6_HEALTH" bash -c ". '$LIB'; vf_guard_unavailable 'guard-test.sh' 'motif de test T6'" \
  2>"$T6_ERR" || T6_RC=$?
T6_OK=1
[ "$T6_RC" -ne 0 ] || { ko "T6 code rendu = 0 (attendu non nul)"; T6_OK=0; }
[ "$T6_RC" -ne 2 ] || { ko "T6 code rendu = 2 (interdit, D-02)"; T6_OK=0; }
grep -qF '[guard-test.sh] motif de test T6' "$T6_ERR" \
  || { ko "T6 motif absent de stderr (contenu=[$(cat "$T6_ERR")])"; T6_OK=0; }
[ -f "$T6_HEALTH/guard-test.sh.marker" ] \
  || { ko "T6 marqueur non écrit sous $T6_HEALTH"; T6_OK=0; }
if [ "$T6_OK" = "1" ]; then
  ok "T6 vf_guard_unavailable : marqueur écrit, motif sur stderr, code=$T6_RC (non nul, != 2)"
fi

# ---------- T7 : répertoire de marqueurs non créable — fail-safe ----------
T7_BLOCKER="$WORK/blocked-file"
: > "$T7_BLOCKER"   # un FICHIER régulier à la place d'un dossier : mkdir -p dessous échoue.
T7_HEALTH="$T7_BLOCKER/health"
T7_ERR="$WORK/t7.err"
T7_RC=0
env VF_GUARD_HEALTH_DIR="$T7_HEALTH" bash -c ". '$LIB'; vf_guard_unavailable 'guard-test.sh' 'motif T7'" \
  2>"$T7_ERR" || T7_RC=$?
T7_OK=1
[ "$T7_RC" -ne 0 ] || { ko "T7 code rendu = 0 malgré répertoire non créable"; T7_OK=0; }
grep -qF '[guard-test.sh] motif T7' "$T7_ERR" \
  || { ko "T7 motif absent de stderr quand le répertoire est non créable"; T7_OK=0; }
[ ! -e "$T7_HEALTH" ] \
  || { ko "T7 un marqueur a été créé alors que le répertoire ne peut pas l'être"; T7_OK=0; }
if [ "$T7_OK" = "1" ]; then
  ok "T7 répertoire de marqueurs non créable : motif imprimé quand même, code=$T7_RC (fail-safe)"
fi

# ---------- T8 : cascade mémoïsée — pas de re-sonde au second appel ----------
T8_OUT=$(bash -c ". '$LIB'; vf_resolve_python >/dev/null 2>&1; first=\"\$VF_PYTHON_INVOKE\"; VF_PYTHON_INVOKE=SENTINEL; vf_resolve_python >/dev/null 2>&1; echo \"\$VF_PYTHON_INVOKE\"")
if [ "$T8_OUT" = "SENTINEL" ]; then
  ok "T8 vf_resolve_python mémoïsé : le second appel ne re-sonde pas (valeur mémorisée conservée)"
else
  ko "T8 vf_resolve_python a re-sondé au second appel — sortie=[$T8_OUT]"
fi

# ---------- T9 : install d'un module → lib posée à plat, non exécutable, contenu identique ----------
if [ -f "$INSTALLER" ] && [ -d "$REPO/software-architecture" ]; then
  T9_LAB="$(mktemp -d)"
  (cd "$T9_LAB" && VIBEFLOW_CACHE="$REPO" VF_SCOPE=project bash "$INSTALLER" install software-architecture >/dev/null 2>&1)
  T9_DEST="$T9_LAB/.claude/scripts/vf-portable.sh"
  T9_OK=1
  [ -f "$T9_DEST" ] || { ko "T9 lib absente après install → $T9_DEST"; T9_OK=0; }
  if [ "$T9_OK" = "1" ]; then
    [ ! -x "$T9_DEST" ] || { ko "T9 lib posée EXÉCUTABLE (attendu : sourcée seulement)"; T9_OK=0; }
    cmp -s "$LIB" "$T9_DEST" || { ko "T9 contenu de la lib posée diffère de la source (cmp)"; T9_OK=0; }
  fi
  [ "$T9_OK" = "1" ] && ok "T9 install software-architecture : lib posée à plat, non exécutable, contenu identique (cmp)"

  # ---------- T10 : resync gouvernance (version inchangée) → lib toujours présente, pas de doublon ----------
  T10_BEFORE_COUNT=$(find "$T9_LAB/.claude/scripts" -maxdepth 1 -name 'vf-portable.sh*' | wc -l | tr -d ' ')
  (cd "$T9_LAB" && VIBEFLOW_CACHE="$REPO" VF_SCOPE=project bash "$INSTALLER" update software-architecture >/dev/null 2>&1)
  T10_AFTER_COUNT=$(find "$T9_LAB/.claude/scripts" -maxdepth 1 -name 'vf-portable.sh*' | wc -l | tr -d ' ')
  T10_OK=1
  [ -f "$T9_DEST" ] || { ko "T10 lib absente après resync (version inchangée)"; T10_OK=0; }
  cmp -s "$LIB" "$T9_DEST" 2>/dev/null || { ko "T10 contenu de la lib diffère après resync"; T10_OK=0; }
  [ "$T10_BEFORE_COUNT" = "1" ] && [ "$T10_AFTER_COUNT" = "1" ] \
    || { ko "T10 doublon de fichier détecté (avant=$T10_BEFORE_COUNT après=$T10_AFTER_COUNT)"; T10_OK=0; }
  [ "$T10_OK" = "1" ] && ok "T10 resync gouvernance (version inchangée) : lib toujours posée et identique, aucun doublon"
  rm -rf "$T9_LAB"
else
  skip "T9/T10 intégration engine : installer ou module software-architecture introuvable"
fi

# ---------- T11 (VG-3) : lib source absente du cache → install ÉCHOUE, message nomme la lib ----------
T11_LAB="$(mktemp -d)"
T11_CACHE="$T11_LAB/cache"
T11_ENGINE_DIR="$T11_LAB/engine"
# Engine copié SEUL (même patron que T8 de test-vibeflow-update.sh) : ni $CACHE/_internal/lib/,
# ni le repli $(dirname "$0")/lib/ n'existent → find_engine_lib() doit rendre une chaîne vide,
# copy_engine_lib() doit échouer BRUYAMMENT (jamais un retour neutre, VG-3).
mkdir -p "$T11_ENGINE_DIR" "$T11_CACHE/hooked/scripts"
cp "$INSTALLER" "$T11_ENGINE_DIR/vibeflow-update.sh"
echo v1.0.0 > "$T11_CACHE/hooked/VERSION"
printf '{"name":"hooked","version":"v1.0.0"}\n' > "$T11_CACHE/hooked/module.json"
printf '#!/usr/bin/env bash\necho x\n' > "$T11_CACHE/hooked/scripts/hooked.sh"
T11_ERR="$T11_LAB/t11.err"
T11_RC=0
(cd "$T11_LAB" && VF_SCOPE=project VIBEFLOW_CACHE="$T11_CACHE" \
   bash "$T11_ENGINE_DIR/vibeflow-update.sh" install hooked >"$T11_ERR" 2>&1) || T11_RC=$?
T11_OK=1
[ "$T11_RC" -ne 0 ] || { ko "T11 install exit 0 malgré la lib source absente"; T11_OK=0; }
grep -qF "vf-portable.sh" "$T11_ERR" \
  || { ko "T11 le message d'échec ne nomme pas vf-portable.sh (contenu=[$(cat "$T11_ERR")])"; T11_OK=0; }
if [ -f "$T11_LAB/.claude/scripts/.vibeflow-installed" ] && grep -q '^hooked=' "$T11_LAB/.claude/scripts/.vibeflow-installed" 2>/dev/null; then
  ko "T11 module marqué installé alors que la lib de portabilité n'a pas pu être posée"; T11_OK=0
fi
[ "$T11_OK" = "1" ] && ok "T11 lib source absente du cache : install échoue (rc=$T11_RC), message nomme la lib, lab non marqué installé (VG-3)"
rm -rf "$T11_LAB"

# ---------- Contrôle d'identité du bloc localisateur (tâche 3, contrat §3/§6) ----------
# Extrait le bloc CANONIQUE entre les deux marqueurs, normalise le SEUL jeton autorisé à varier
# (le préfixe de message entre crochets), et calcule une somme de contrôle. Anticipe le gate amont
# (check-portable-resolution.sh, pas encore livré dans ce dépôt) : toute dérive de copier-coller
# entre les 3 consommateurs PYBIN doit être détectée à la machine, jamais par relecture.
extract_locator_block() {
  awk '/^# >>> vf-portable:locator/{flag=1} flag{print} /^# <<< vf-portable:locator/{flag=0; exit}' "$1"
}

sha256_of_stdin() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
  else
    shasum -a 256 | awk '{print $1}'
  fi
}

# Rend "MISSING" (jamais une somme) si les DEUX marqueurs ne sont pas présents dans l'ordre —
# c'est le garde-fou anti-« aucun bloc trouvé = vert par défaut » (piège nommé au contrat §6).
checksum_locator_block() {
  local f="$1" block
  block="$(extract_locator_block "$f")"
  case "$block" in
    *'>>> vf-portable:locator'*'<<< vf-portable:locator'*) : ;;
    *) echo "MISSING"; return 0 ;;
  esac
  printf '%s\n' "$block" | sed -E 's/\[[A-Za-z0-9_-]+\]/[PREFIX]/g' | sha256_of_stdin
}

# ---------- T12 : une SEULE somme de contrôle pour les 4 consommateurs réels ----------
T12_GFS="$REPO/software-architecture/scripts/guard-file-size.sh"
T12_IMT="$REPO/dev-orchestrator/scripts/inject-mcp-tools.sh"
T12_TDO="$REPO/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh"
T12_CHP="$REPO/dev-orchestrator/scripts/check-hook-paths.sh"
T12_OK=1
T12_REPORT=""
for T12_ENTRY in "guard-file-size.sh|$T12_GFS" "inject-mcp-tools.sh|$T12_IMT" "test-dev-orchestrator.sh|$T12_TDO" "check-hook-paths.sh|$T12_CHP"; do
  T12_LABEL="${T12_ENTRY%%|*}"
  T12_PATH="${T12_ENTRY#*|}"
  if [ ! -f "$T12_PATH" ]; then
    ko "T12 identité du bloc : consommateur introuvable — $T12_LABEL ($T12_PATH)"
    T12_OK=0
    continue
  fi
  T12_SUM="$(checksum_locator_block "$T12_PATH")"
  if [ "$T12_SUM" = "MISSING" ]; then
    ko "T12 identité du bloc : marqueurs absents/dépareillés dans $T12_LABEL — échec BRUYANT (jamais un vert par défaut)"
    T12_OK=0
    continue
  fi
  T12_REPORT="$T12_REPORT$T12_LABEL=$T12_SUM"$'\n'
done
if [ "$T12_OK" = "1" ]; then
  T12_UNIQ="$(printf '%s' "$T12_REPORT" | awk -F= '{print $2}' | sort -u)"
  T12_UNIQ_COUNT="$(printf '%s\n' "$T12_UNIQ" | grep -c .)"
  if [ "$T12_UNIQ_COUNT" = "1" ]; then
    ok "T12 identité du bloc localisateur : une seule somme de contrôle pour les 4 consommateurs ($T12_UNIQ)"
  else
    ko "T12 identité du bloc : sommes DIVERGENTES —
$T12_REPORT"
  fi
fi

# ---------- T13 : extraction bruyante — marqueurs absents/dépareillés ne rendent JAMAIS un vert ----------
T13_NONE="$WORK/t13-no-markers.sh"
printf '#!/usr/bin/env bash\necho hello\n' > "$T13_NONE"
T13_OPEN_ONLY="$WORK/t13-open-only.sh"
printf '#!/usr/bin/env bash\n# >>> vf-portable:locator\necho x\n' > "$T13_OPEN_ONLY"
T13_OK=1
for T13_F in "$T13_NONE" "$T13_OPEN_ONLY"; do
  T13_SUM="$(checksum_locator_block "$T13_F")"
  if [ "$T13_SUM" != "MISSING" ]; then
    ko "T13 extraction : $T13_F sans marqueurs valides a quand même rendu une somme (faux vert) — [$T13_SUM]"
    T13_OK=0
  fi
done
[ "$T13_OK" = "1" ] && ok "T13 extraction bruyante : marqueurs absents/dépareillés → jamais une somme silencieuse (2 fixtures, échec explicite)"

echo "== $pass ok · $fail ko · $skipped skip =="
[ "$fail" -eq 0 ]
