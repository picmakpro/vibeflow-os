# vf-portable.sh — lib partagée de portabilité Windows (contrat PR #29 « CONTRAT-PORTABILITE.md »,
# D-04, Phase 30). Possédée par l'ENGINE (plugin/_internal/lib/), jamais par un module : aucun
# module ne peut l'emporter en se désinstallant. Posée à l'install/update par copy_engine_lib()
# dans vibeflow-update.sh.
#
# CETTE LIB EST SOURCÉE, JAMAIS EXÉCUTÉE SEULE : pas de shebang exécutable en tête d'intention
# (le fichier n'a pas de bit +x, cf. copy_engine_lib()), pas de `set -e`, aucun `exit`, aucune
# écriture au chargement — un consommateur qui la source sous `set -u` ne doit jamais casser.
#
# Résout la dette de 3 défauts déjà documentés (ADR-054, contrat §1) : la résolution Python
# recopiée dans ~13 scripts et déjà divergente (variante A complète avec `timeout` vs variante B
# allégée sans neutralisation WindowsApps), le wrapper jqx() redéfini 5 fois, et des gardes qui
# sortent 0 sans interpréteur (protection muette).
#
# Symboles exposés (contrat §2) :
#   vf_resolve_python [--fast]   — résout un interpréteur utilisable (cascade python3→python→py -3).
#   vf_python <args…>            — INVOQUE l'interpréteur résolu. Fonction, pas variable : porte le
#                                   lanceur à argument `py -3` qu'un `PYBIN=` ne peut pas exprimer.
#   vf_py_probe <candidat> [--fast] — sonde un candidat : présent, pas le stub *WindowsApps*,
#                                   s'exécute réellement (profil complet), Python 3.
#   jqx <args…>                  — wrapper jq qui neutralise le CRLF du jq natif Windows.
#   vf_guard_unavailable <script> <motif> — contrat de marqueur §4 (voir plus bas).
#
# Deux profils de sonde (résolution de l'hypothèse A1, RESEARCH.md) — le contrat ne tranche pas la
# fréquence d'appel, la lib expose donc les deux plutôt que d'en deviner un :
#   - PROFIL COMPLET (par défaut, sans --fast) : présence + rejet WindowsApps + sonde d'EXÉCUTION
#     réelle (gardée par `timeout` là où il existe) + version Python 3. À utiliser pour toute
#     résolution qui n'a lieu QU'UNE FOIS (install, SessionStart) — merge-hooks.sh, préflight,
#     inject-mcp-tools.sh.
#   - PROFIL RAPIDE (--fast) : présence + rejet WindowsApps par CHEMIN SEUL, ZÉRO spawn ajouté
#     (amendement ADR-054 point 3). À réserver aux gardes qui tournent à CHAQUE invocation d'un
#     outil (PreToolUse) — un spawn `timeout` supplémentaire par édition serait une régression de
#     latence perceptible. guard-file-size.sh (Phase 30, tâche 3) l'utilise pour cette raison.
#
# IS_WINDOWS — détection INCONDITIONNELLE au chargement (uname -s + variable d'environnement
# système $OS, Git Bash sous Windows émet `MINGW64_NT-…`/`MSYS_NT-…`, cmd/PowerShell posent
# OS=Windows_NT). PORTÉE PAR LA LIB : un consommateur ne doit JAMAIS la redéfinir localement — une
# redéfinition locale casse sous `set -u` si le consommateur source la lib après coup, et duplique
# exactement le défaut que ce fichier existe pour fermer (contrat §2).
case "$(uname -s 2>/dev/null)" in
  MINGW*|MSYS*|CYGWIN*) IS_WINDOWS=1 ;;
  *)
    case "${OS:-}" in
      Windows_NT) IS_WINDOWS=1 ;;
      *) IS_WINDOWS=0 ;;
    esac
    ;;
esac

# IS_WSL — détection ADDITIVE, jamais une redéfinition de IS_WINDOWS (Phase 33, WTCH-03). WSL
# tourne sous noyau LINUX : `uname -s` y rend `Linux`, donc IS_WINDOWS ci-dessus reste 0 sous WSL
# par construction — ce fichier existe précisément pour porter l'information manquante que
# IS_WINDOWS seul ne peut pas voir. Mutuellement exclusifs par calcul : si IS_WINDOWS=1, IS_WSL
# vaut 0 sans même lire /proc/version (court-circuit). Sinon, lecture de
# ${VF_PROC_VERSION_PATH:-/proc/version} : fichier absent/illisible = non-WSL, jamais une erreur
# (cohérent avec le chargement inconditionnel de cette lib, sans écriture ni `exit`).
# VF_PROC_VERSION_PATH est un point d'injection de TEST uniquement — jamais positionné en usage
# normal, réservé aux shims CI (test-vf-portable.sh T14-T16).
if [ "$IS_WINDOWS" = "1" ]; then
  IS_WSL=0
else
  _vf_proc_version="${VF_PROC_VERSION_PATH:-/proc/version}"
  if [ -r "$_vf_proc_version" ] && grep -qiE 'microsoft|wsl' "$_vf_proc_version" 2>/dev/null; then
    IS_WSL=1
  else
    IS_WSL=0
  fi
  unset _vf_proc_version
fi

# vf_py_probe <candidat> [--fast]
# <candidat> est un token d'invocation complet (mot-séparé volontairement non quoté à l'usage) :
# "python3", "python", ou "py -3" (le lanceur Windows exige TOUJOURS -3, jamais probé sans).
# Renvoie 0 si le candidat est utilisable, 1 sinon. N'imprime rien (fail-open silencieux côté sonde
# — c'est l'appelant, via vf_guard_unavailable, qui décide du message et du code).
vf_py_probe() {
  local cand="$1" fast="${2:-}" bin
  # "py -3" → bin="py" pour les contrôles de présence/chemin ; l'invocation réelle plus bas garde
  # le token complet non quoté pour que "-3" soit repassé à l'interpréteur.
  bin="${cand%% *}"
  command -v "$bin" >/dev/null 2>&1 || return 1
  # ADR-054 : le stub Microsoft Store (App Execution Alias) est PRÉSENT au sens de `command -v`
  # mais inerte à l'exécution (pend ou sort en 49 sans stdout). Rejet par CHEMIN — commun aux deux
  # profils, c'est le contrôle qui existe déjà aujourd'hui dans guard-file-size.sh (Pitfall 3).
  case "$(command -v "$bin" 2>/dev/null)" in *WindowsApps*) return 1 ;; esac
  [ "$fast" = "--fast" ] && return 0
  # Profil complet uniquement à partir d'ici : sonde d'EXÉCUTION réelle, gardée par `timeout` là où
  # il existe (Git Bash oui, macOS non) — c'est la variante A COMPLÈTE de merge-hooks.sh:54-71.
  local probe='import sys; sys.exit(0 if sys.version_info[0]>=3 else 1)'
  if command -v timeout >/dev/null 2>&1; then
    # shellcheck disable=SC2086 — $cand est un token interne contrôlé ("python3"/"python"/"py -3"),
    # le word-splitting volontaire est ce qui permet à "py -3" de porter son argument de lanceur.
    timeout 5 $cand -c "$probe" >/dev/null 2>&1 || return 1
  else
    $cand -c "$probe" >/dev/null 2>&1 || return 1
  fi
  return 0
}

# État mémoïsé — variables de PROCESSUS (pas de re-sonde à chaque appel dans le même script).
VF_PYTHON_INVOKE=""
VF_PYTHON_RESOLVED="0"

# vf_resolve_python [--fast]
# Cascade python3 → python → py -3 (contrat §2). Résultat mémorisé : un second appel dans le même
# processus, quel que soit le profil demandé, réutilise la résolution déjà faite (résolution
# paresseuse, jamais reproduite deux fois). Rend non nul si aucun candidat ne passe, SANS RIEN
# IMPRIMER — c'est l'appelant qui décide du message et du code (vf_guard_unavailable).
vf_resolve_python() {
  local fast="${1:-}" cand
  if [ "$VF_PYTHON_RESOLVED" = "1" ]; then
    [ -n "$VF_PYTHON_INVOKE" ]
    return $?
  fi
  VF_PYTHON_RESOLVED="1"
  for cand in python3 python "py -3"; do
    if vf_py_probe "$cand" "$fast"; then
      VF_PYTHON_INVOKE="$cand"
      return 0
    fi
  done
  VF_PYTHON_INVOKE=""
  return 1
}

# vf_python <args…>
# FONCTION, PAS VARIABLE (contrat §2) : c'est ce qui fait du lanceur "py -3" un barreau de plein
# droit — un `PYBIN="py -3"` ne peut pas être invoqué comme `"$PYBIN" -c ...` sans casser le
# quoting. Résout paresseusement (profil complet) si la résolution n'a pas encore eu lieu ; si un
# appelant a déjà résolu en profil rapide (--fast) plus tôt dans le même processus, cette
# résolution mémorisée est réutilisée telle quelle (pas de re-sonde forcée en profil complet).
vf_python() {
  vf_resolve_python || return 1
  # shellcheck disable=SC2086 — même raison que vf_py_probe : VF_PYTHON_INVOKE peut porter "py -3".
  $VF_PYTHON_INVOKE "$@"
}

# jqx <args…>
# Wrapper jq qui neutralise le CRLF émis par le jq natif Windows (ADR-054, idiome déjà en
# production 5 fois dans le dépôt — repris ici à l'identique, `set -o pipefail` en sous-shell pour
# propager le code retour de `jq`, pas celui de `tr`).
jqx() (
  set -o pipefail
  command jq "$@" | tr -d '\r'
)

# Code de sortie que l'appelant doit utiliser quand vf_guard_unavailable a tourné (D-02) : non nul,
# ET DIFFÉRENT DE 2 — sur un hook PreToolUse, exit 2 bloquerait l'édition tant que Python manque,
# alors que la doctrine du dépôt est « dégradé mais utilisable » (ADR-031). Valeur arbitraire mais
# stable et documentée, jamais 0 ni 2.
VF_GUARD_UNAVAILABLE_EXIT_CODE=17

# vf_guard_unavailable <script> <motif>
# Contrat de marqueur §4 — « n'a pas pu tourner » est un TROISIÈME état, distinct de « a tourné et
# a trouvé un problème » et de « a tourné et n'a rien trouvé ». Trois actions, TOUJOURS ENSEMBLE :
#   1. Écrit une ligne dans $VF_GUARD_HEALTH_DIR/<script>.marker (horodatage ISO, script, motif) —
#      écriture ATOMIQUE (temporaire + renommage), totalement fail-safe : si le répertoire n'est
#      pas créable, cette étape est sautée SANS casser les deux suivantes.
#   2. Imprime le motif sur stderr, préfixé par le nom du script.
#   3. RETOURNE (jamais `exit` elle-même — c'est l'appelant qui sort avec la valeur rendue, ex.
#      `vf_guard_unavailable "$0" "…" ; exit $?`) le code $VF_GUARD_UNAVAILABLE_EXIT_CODE.
# Le hook doctor de `conductor` (agrégation des marqueurs, escalade après 3 sessions) est DIFFÉRÉ
# avec reliquat écrit (D-05) — voir 30-RELIQUATS.md. Les marqueurs s'accumulent sans casse tant
# qu'il n'existe pas ; le motif reste visible IMMÉDIATEMENT sur stderr, jamais uniquement enfoui
# dans un fichier que personne ne lit.
vf_guard_unavailable() {
  local script="$1" motif="$2"
  local health_dir="${VF_GUARD_HEALTH_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/vibeflow/guard-health}"
  local marker="$health_dir/${script}.marker"
  local ts
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  if mkdir -p "$health_dir" 2>/dev/null; then
    { printf '%s\t%s\t%s\n' "$ts" "$script" "$motif" > "${marker}.tmp.$$" \
        && mv -f "${marker}.tmp.$$" "$marker"; } 2>/dev/null \
      || rm -f "${marker}.tmp.$$" 2>/dev/null || true
  fi
  echo "[$script] $motif" >&2
  return "$VF_GUARD_UNAVAILABLE_EXIT_CODE"
}
