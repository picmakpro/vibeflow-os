#!/usr/bin/env bash
# guard-file-size.sh — Hook PreToolUse(Edit|Write) : porte blindée de l'Iron Law 300L
# (ADR-035 « aucun fichier de code > 300 lignes sans plan de découpe », câblé ADR-043).
#
# Câblage (posé automatiquement par l'install du module software-architecture) :
#   PreToolUse · matcher "Edit|Write" · command: bash .claude/scripts/guard-file-size.sh
#
# Règle — le guard juge le RÉSULTAT de l'opération, jamais le seul état passé du disque
# (mesurer l'ancien contenu bloquait la remédiation elle-même : un Write de refactor
# conforme, ou l'Edit qui ajoute le marqueur d'échappatoire, étaient deny → boucle
# deny/retry qui enseignait le contournement par Bash/sed) :
#   - Write : le contenu ENTRANT fait foi (le fichier est intégralement remplacé).
#     >= VF_ARCH_BLOCK (300) lignes sans marqueur `vibeflow:allow-large-file` → deny,
#     y compris pour un fichier NEUF (un Write initial de 2000 lignes ne passe plus).
#   - Edit : ne pas agrandir = toujours allow (c'est la voie de découpe) ; poser le
#     marqueur = toujours allow. Une édition qui agrandit est estimée (lignes disque
#     + delta de lignes, occurrences comptées si replace_all) : résultat >= seuil
#     sans marqueur (sur disque ou entrant) → deny.
#   Fichier non-code → allow. check-file-size.sh reste le gate CLI/pre-commit
#   (--staged / --all) ; mêmes seuils, même marqueur.
#
# Fail-open : SEUL le deny explicite bloque ; toute erreur interne (JSON invalide,
# fichier illisible, python absent) → allow silencieux. Un garde-fou cassé ne bloque
# jamais le flux. Un seul spawn python3 (parse stdin + décision + deny) par appel.

set -uo pipefail


# Préfiltre trivial sans spawn : payload sans file_path → rien à mesurer
# (couvre aussi le stdin invalide : allow silencieux immédiat).
INPUT="$(cat 2>/dev/null || true)"
case "$INPUT" in
  *file_path*) ;;
  *) exit 0 ;;
esac

# >>> vf-portable:locator (bloc canonique, contrat PR #29 §3 / D-04 — Phase 30 plan 30-05. Ne
# pas retaper à la main : copier depuis plugin/_internal/lib/vf-portable.sh entre ces deux
# marqueurs — seul le préfixe de message varie d'un consommateur à l'autre (identité vérifiée
# par somme de contrôle dans test-vf-portable.sh).
# Préfixe de ce consommateur : [guard-file-size]
#   1. $(dirname "$0")/vf-portable.sh              → install à plat (TARGET_ROOT/scripts)
#   2. $(dirname "$0")/lib/vf-portable.sh           → engine dans le cache du plugin
#   3. remontée bornée (<= 4 niveaux) depuis $(dirname "$0") vers _internal/lib/vf-portable.sh
#      → module/installeur exécuté depuis le dépôt, quelle que soit sa profondeur réelle
#   4. $(dirname "$0")/../../scripts/vf-portable.sh → extracteur kpi copié
# Aucun candidat trouvé → message préfixé en stderr + sortie non-zéro. Jamais un `source` muet.
_vf_portable_lib=""
_vf_portable_dir="$(dirname "$0")"
for _vf_portable_cand in "$_vf_portable_dir/vf-portable.sh" "$_vf_portable_dir/lib/vf-portable.sh"; do
  [ -f "$_vf_portable_cand" ] && { _vf_portable_lib="$_vf_portable_cand"; break; }
done
if [ -z "$_vf_portable_lib" ]; then
  _vf_portable_walk="$_vf_portable_dir"
  for _vf_portable_i in 1 2 3 4; do
    _vf_portable_walk="$_vf_portable_walk/.."
    if [ -f "$_vf_portable_walk/_internal/lib/vf-portable.sh" ]; then
      _vf_portable_lib="$_vf_portable_walk/_internal/lib/vf-portable.sh"
      break
    fi
  done
fi
if [ -z "$_vf_portable_lib" ] && [ -f "$_vf_portable_dir/../../scripts/vf-portable.sh" ]; then
  _vf_portable_lib="$_vf_portable_dir/../../scripts/vf-portable.sh"
fi
if [ -z "$_vf_portable_lib" ]; then
  echo "[guard-file-size] vf-portable.sh introuvable (candidats épuisés — installer/mettre à jour vibeflow)" >&2
  exit 1
fi
# shellcheck source=/dev/null
. "$_vf_portable_lib"
unset _vf_portable_lib _vf_portable_dir _vf_portable_cand _vf_portable_walk _vf_portable_i
# <<< vf-portable:locator

# Profil RAPIDE (--fast, zéro spawn ajouté — amendement ADR-054 point 3) : ce guard tourne à
# CHAQUE Edit/Write, un spawn `timeout` supplémentaire par appel serait une régression de latence
# perceptible (Pitfall 3, RESEARCH.md). Renversement du silence (D-02) : le chemin « aucun
# interpréteur utilisable », qui sortait 0 avant cette migration, appelle désormais le marqueur de
# garde puis sort avec le code qu'il rend (non nul, différent de 2) — le reste du fail-open
# (erreur interne du programme Python = allow silencieux) est PRÉSERVÉ à l'identique plus bas.
if ! vf_resolve_python --fast; then
  vf_guard_unavailable "guard-file-size.sh" "aucun interprète Python utilisable (profil rapide, PreToolUse)"
  exit $?
fi

# NB : programme passé en -c (sans apostrophes) ; le payload est rejoué sur le stdin
# du python. Le bash ne fait plus que router : le deny JSON est émis par python.
printf '%s' "$INPUT" | vf_python -c '
import json, os, re, sys

MARKER = "vibeflow:allow-large-file"

def head_has_marker(text):
    # Echappatoire documentee (identique a check-file-size.sh) : 5 premieres lignes.
    return MARKER in "\n".join(text.splitlines()[:5])

try:
    payload = json.load(sys.stdin)
    tool = payload.get("tool_name") or ""
    ti = payload.get("tool_input") or {}
    path = ti.get("file_path") or ""
    if not path:
        sys.exit(0)
    # Meme perimetre que check-file-size.sh : seuls les fichiers de code comptent.
    if not re.search(r"\.(ts|tsx|js|jsx|mjs|cjs|py|go|rb|java|kt|swift|rs|php)$", path):
        sys.exit(0)
    try:
        block = int(os.environ.get("VF_ARCH_BLOCK", "300"))
    except ValueError:
        block = 300

    estimated = None
    if tool == "Write":
        content = ti.get("content")
        if not isinstance(content, str) or head_has_marker(content):
            sys.exit(0)  # payload atypique, ou dette tracee dans le contenu entrant
        # splitlines compte la derniere ligne meme sans newline finale (wc -l la rate).
        estimated = len(content.splitlines())
    elif tool == "Edit":
        old = ti.get("old_string")
        new = ti.get("new_string")
        if not isinstance(old, str) or not isinstance(new, str) or not old:
            sys.exit(0)  # appel invalide : Edit produira sa propre erreur
        if MARKER in new:
            sys.exit(0)  # poser le marqueur est TOUJOURS permis (sinon deny-loop)
        # Delta de lignes exact = delta de newlines (vrai aussi pour des fragments
        # partiels de ligne, la ou un compte de lignes des fragments derive de +/-1).
        growth = new.count("\n") - old.count("\n")
        if growth <= 0:
            sys.exit(0)  # retrecir / ne pas agrandir = voie de decoupe, toujours permis
        try:
            with open(path, encoding="utf-8", errors="replace") as f:
                disk = f.read()
        except OSError:
            sys.exit(0)  # illisible ou absent : fail-open, le tool rendra sa propre erreur
        if head_has_marker(disk):
            sys.exit(0)  # dette deja tracee sur le disque
        if ti.get("replace_all"):
            occ = disk.count(old)
            if occ == 0:
                sys.exit(0)  # occurrence absente : Edit echouera de lui-meme
            growth = occ * growth
        estimated = len(disk.splitlines()) + growth
    else:
        sys.exit(0)  # autre tool (matcher plus large) : hors perimetre, allow

    if estimated is None or estimated < block:
        sys.exit(0)

    reason = (
        "Iron Law ADR-035 : cette operation amenerait " + path + " a ~" + str(estimated)
        + " lignes (seuil " + str(block) + "). Marche a suivre : 1) decouper le fichier"
        + " (SRP — extraire un module coherent) avant de poursuivre ; ou 2) tracer la"
        + " dette en ajoutant le marqueur vibeflow:allow-large-file dans les 5 premieres"
        + " lignes ET une entree dette dans le registre. Les editions qui reduisent le"
        + " fichier passent toujours. Ne contourne pas silencieusement via Bash/sed."
    )
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }, ensure_ascii=False))
except Exception:
    sys.exit(0)  # fail-open : toute erreur interne = allow
' 2>/dev/null || exit 0
exit 0
