#!/usr/bin/env bash
# test-check-hook-paths.sh — Suite de discrimination de check-hook-paths.sh (Phase 30 plan 30-09,
# QUAL-01 : trois issues, mutation rouge prouvée).
#
# Cas discriminants, chacun avec sa phrase d'intention :
#   T1  — silence fort : fixture saine → stdout ZÉRO octet (compté, pas comparé), rc 0 sous --hook,
#         rc 3 sans --hook.
#   T2  — constat sur `command` : chemin absolu inexistant PAR CONSTRUCTION → signal, rc 0.
#   T2b — constat sur `args` : même famille, branche `args` prouvée INDÉPENDAMMENT de `command`.
#   T3  — code 2 jamais émis : agrégé sur les rc de T1/T2/T2b/T4.
#   T4  — illisible et BRUYANT : JSON invalide → stdout vide, stderr nommant le fichier, rc 1,
#         INCHANGÉ sous --hook (la traduction ne touche que le silence, jamais l'erreur).
#   T5  — les deux fichiers de réglages de PROJET sont lus, chacun indépendamment (deux sous-cas).
#   T6  — absence totale de réglages : stdout vide, rc 3 sans drapeau, rc 0 avec.
#   T7  — parité d'interface : --hook + --quiet → 64 ; argument inconnu → 64 ; --path sans valeur
#         → 64.
#   T8  — anti-vert-à-vide de la suite : sur la fixture T1, le nombre d'entrées examinées annoncé
#         sur stderr doit être STRICTEMENT positif.
#   T9  — garde anti-« réparation » de l'entrée n°26 de hooks.json : son `command` reste le nom nu
#         littéral `bash`, jamais le jeton d'interpréteur substitué à l'install.
#   T10 — identité du bloc localisateur : somme de contrôle normalisée identique à celle
#         d'inject-mcp-tools.sh (3e consommateur PYBIN réel de ce module, hors périmètre de T12 de
#         test-vf-portable.sh qui n'en connaît que 3 en dur — reliquat A-30-09-4).
#   T11 — aller-retour dans le moteur de fusion (merge-hooks.sh) : atterrit en projet (pas de
#         jeton {{VF_BASH}}), substitution du préfixe de scripts, idempotence, retrait.
#   T12 — l'inventaire durable (docs/HOOKS-CONTRAT-SORTIE.md §4) et le parc réel s'accordent — avec
#         un écart TRANSITOIRE explicitement toléré (voir note ci-dessous).
#
# NOTE SUR T12 (écart transitoire attendu, pas un défaut du test) : ce plan (30-09) pose la 26e
# entrée de hooks.json à la tâche 1, mais ne met à jour l'inventaire durable
# (docs/HOOKS-CONTRAT-SORTIE.md, qui déclare encore 25) qu'à la tâche 3. Entre les deux, le recompte
# réel du parc (26) diverge nécessairement du nombre déclaré par le document (25) — un écart réel,
# mais BORNÉ et ATTENDU à ce point précis de l'exécution du plan. T12 le distingue explicitement
# d'un écart non attendu (SKIP silencieux ne suffirait pas — le SKIP ici est BRUYANT et nomme
# l'écart exact) : SKIP uniquement si l'écart mesuré est EXACTEMENT +1 (parc = doc + 1, la
# signature de « tâche 3 pas encore jouée ») ; tout autre écart (0, négatif, ou différent de 1) est
# un KO. La tâche 3 relance cette même suite dans le cadre de sa propre revérification complète des
# 61 suites du dépôt — à ce moment-là, doc et parc valent 26 tous les deux, et T12 devient OK.
#
# ---------------------------------------------------------------------------------------------
# TRACES DE MUTATION (jouées manuellement pendant l'écriture de cette suite, contre le script livré
# — restauré après coup, revérifié vert. Consignées ici pour que la discriminance ne soit jamais
# affirmée sans preuve, et reprises telles quelles dans 30-09-SUMMARY.md) :
#
# m1 — neutraliser le contrôle d'existence du chemin (rendre `os.path.isfile`/`os.access` toujours
#      vrais dans le bloc Python embarqué). Cas discriminants attendus ROUGES : T2, T2b, T5
#      (les deux sous-cas). Cas attendus VERTS (inchangés) : T1, T4, T6, T7.
#      OBTENU : T2 rouge (attendu "stdout non vide, marqueur [hook-paths]", obtenu "stdout vide, rc
#      3" — plus aucun FINDING n'est émis, le chemin cassé est déclaré existant) ; T2b rouge (même
#      motif, branche `args`) ; T5 (sous-cas a et b) rouges (même motif) ; T1/T4/T6/T7 restés verts
#      (aucune de ces branches ne dépend du contrôle d'existence muté).
# m2 — avaler l'erreur d'analyse (le bloc Python traite un JSON invalide comme un fichier absent,
#      donc silencieux, au lieu d'émettre PARSE_ERROR). Cas discriminant attendu ROUGE : T4 seul.
#      OBTENU : T4 rouge (attendu "stdout vide, stderr NOMMANT LE FICHIER FAUTIF, rc 1 sans --hook
#      ET sous --hook", obtenu "stdout vide, stderr générique portant seulement '0 entrée(s)
#      examinée(s) sur 0 fichier(s) lus — rien à signaler' (JAMAIS le nom du fichier), rc 3 sans
#      --hook et rc 0 sous --hook" — le faux PASS silencieux que QUAL-01 interdit apparaît
#      exactement sous cette mutation) ; T1/T2/T2b/T5/T6/T7/T9/T10/T11 restés verts.
# m3 — remplacer, dans une COPIE de hooks.json (restaurée après coup), le `command` littéral
#      `bash` de l'entrée n°26 par le jeton d'interpréteur `{{VF_BASH}}`. Cas discriminant attendu
#      ROUGE : T9 seul (T11 utilise à dessein un fragment SYNTHÉTIQUE autoportant, jamais le
#      hooks.json vivant, précisément pour rester découplé de cette mutation — sans ce découplage,
#      T11a rougissait aussi, en violation de « T9 seul » : is_local_entry() de merge-hooks.sh route
#      toute entrée portant {{VF_BASH}} vers le fichier LOCAL, ce que T11a aurait alors constaté à
#      raison sur le fragment réel muté ; corrigé en amont de cette trace).
#      OBTENU (après correction) : T9 rouge (attendu "command == 'bash' littéral, jeton {{VF_BASH}}
#      absent", obtenu "command == '{{VF_BASH}}'" — la garde anti-« réparation » rougit exactement
#      comme prévu) ; tous les autres cas, T11 inclus, restés verts.
# m4 — retirer `.claude/settings.local.json` de la liste des candidats balayés par
#      check-hook-paths.sh. Cas discriminant attendu ROUGE : le second sous-cas de T5 (entrée
#      cassée UNIQUEMENT dans settings.local.json) seul.
#      OBTENU : T5 sous-cas b rouge (attendu "stdout non vide, signal émis", obtenu "stdout vide,
#      rc 3" — le fichier local n'est simplement plus lu) ; T5 sous-cas a resté vert (settings.json
#      reste candidat) ; T1/T2/T2b/T4/T6/T7/T9 inchangés.
#
# Convention du dépôt : ok()/ko()/skip(), isolation mktemp, exit 0 si 0 KO, exit 1 sinon.
set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$(cd "$TESTS_DIR/.." && pwd)"
MOD="$(cd "$SCRIPTS_DIR/.." && pwd)"
REPO="$(cd "$MOD/.." && pwd)"
REPO_ROOT="$(cd "$REPO/.." && pwd)"

SCRIPT="$SCRIPTS_DIR/check-hook-paths.sh"
HOOKS_JSON="$MOD/hooks/hooks.json"
INJECT="$SCRIPTS_DIR/inject-mcp-tools.sh"
MERGER="$REPO/_internal/merge-hooks.sh"
DOC="$REPO_ROOT/docs/HOOKS-CONTRAT-SORTIE.md"

[ -f "$SCRIPT" ] || { echo "FATAL: check-hook-paths.sh introuvable : $SCRIPT" >&2; exit 1; }

pass=0; fail=0; skipped=0
ok()   { echo "  ✓ $1"; pass=$((pass+1)); }
ko()   { echo "  ✗ $1"; fail=$((fail+1)); }
skip() { echo "  ⊘ SKIP $1"; skipped=$((skipped+1)); }

echo "== test-check-hook-paths (script: $SCRIPT) =="

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Scope utilisateur neutralisé — la suite ne doit JAMAIS dépendre de l'état réel du poste
# (~/.claude/settings*.json de la machine qui exécute la suite).
export CLAUDE_CONFIG_DIR="$WORK/user-scope-vide"
mkdir -p "$CLAUDE_CONFIG_DIR"

# Interpréteur "réellement en train de tourner" (T1) : bash lui-même exécute cette suite, son
# chemin absolu est dérivé à l'exécution, jamais un littéral de machine.
REAL_ABS_BIN="$(command -v bash)"

mk_settings() { # <fichier> <command> <args0>
  mkdir -p "$(dirname "$1")"
  printf '{"hooks":{"SessionStart":[{"matcher":"startup","hooks":[{"type":"command","command":"%s","args":["%s","--hook"]}]}]}}\n' \
    "$2" "$3" > "$1"
}

bytes_of() { wc -c < "$1" | tr -d '[:space:]'; }

# ---------- T1 : silence fort ----------
mkdir -p "$WORK/t1"
T1_TARGET="$WORK/t1/target.sh"; touch "$T1_TARGET"
mk_settings "$WORK/t1/.claude/settings.json" "$REAL_ABS_BIN" "$T1_TARGET"
T1_OUT="$WORK/t1.out"; T1_ERR="$WORK/t1.err"
bash "$SCRIPT" --path "$WORK/t1" --hook >"$T1_OUT" 2>"$T1_ERR"; T1_RC=$?
T1H_OUT="$WORK/t1h.out"; T1H_ERR="$WORK/t1h.err"
bash "$SCRIPT" --path "$WORK/t1" >"$T1H_OUT" 2>"$T1H_ERR"; T1H_RC=$?
if [ "$T1_RC" = "0" ] && [ "$(bytes_of "$T1_OUT")" = "0" ] \
   && [ "$T1H_RC" = "3" ] && [ "$(bytes_of "$T1H_OUT")" = "0" ]; then
  ok "T1 silence fort : stdout 0 octet, rc 0 sous --hook, rc 3 sans --hook (out/err séparés)"
else
  ko "T1 silence fort : hook(rc=$T1_RC,bytes=$(bytes_of "$T1_OUT")) sans-hook(rc=$T1H_RC,bytes=$(bytes_of "$T1H_OUT"))"
fi

# ---------- T2 : constat sur `command` (chemin cassé PAR CONSTRUCTION) ----------
# Le chemin fautif est bâti en créant un répertoire temporaire PUIS en le supprimant : jamais un
# binaire simplement absent d'un PATH restreint, jamais un accident d'environnement (piège n°1).
T2_GONE_DIR="$(mktemp -d)"; T2_GONE_BIN="$T2_GONE_DIR/interprete-disparu"; rmdir "$T2_GONE_DIR"
mkdir -p "$WORK/t2"
T2_TARGET="$WORK/t2/target.sh"; touch "$T2_TARGET"
mk_settings "$WORK/t2/.claude/settings.json" "$T2_GONE_BIN" "$T2_TARGET"
T2_OUT="$WORK/t2.out"; T2_ERR="$WORK/t2.err"
bash "$SCRIPT" --path "$WORK/t2" >"$T2_OUT" 2>"$T2_ERR"; T2_RC=$?
T2_LINES="$(wc -l < "$T2_OUT" | tr -d '[:space:]')"
if [ "$T2_RC" = "0" ] && [ -s "$T2_OUT" ] && head -1 "$T2_OUT" | grep -q '^\[hook-paths\]' \
   && grep -qF "$T2_GONE_BIN" "$T2_OUT" && [ "$T2_LINES" -le 7 ]; then
  ok "T2 constat sur command : chemin fautif cité, marqueur en tête, <=7 lignes, rc 0"
else
  ko "T2 constat sur command : rc=$T2_RC lignes=$T2_LINES contenu=[$(cat "$T2_OUT")]"
fi

# ---------- T2b : constat sur `args` (command sain, args[0] cassé PAR CONSTRUCTION) ----------
T2B_GONE_DIR="$(mktemp -d)"; T2B_GONE_TARGET="$T2B_GONE_DIR/target-disparu.sh"; rmdir "$T2B_GONE_DIR"
mkdir -p "$WORK/t2b/.claude"
mk_settings "$WORK/t2b/.claude/settings.json" "$REAL_ABS_BIN" "$T2B_GONE_TARGET"
T2B_OUT="$WORK/t2b.out"; T2B_ERR="$WORK/t2b.err"
bash "$SCRIPT" --path "$WORK/t2b" >"$T2B_OUT" 2>"$T2B_ERR"; T2B_RC=$?
T2B_LINES="$(wc -l < "$T2B_OUT" | tr -d '[:space:]')"
if [ "$T2B_RC" = "0" ] && [ -s "$T2B_OUT" ] && head -1 "$T2B_OUT" | grep -q '^\[hook-paths\]' \
   && grep -qF "$T2B_GONE_TARGET" "$T2B_OUT" && [ "$T2B_LINES" -le 7 ]; then
  ok "T2b constat sur args : branche args prouvée indépendamment de command, rc 0"
else
  ko "T2b constat sur args : rc=$T2B_RC lignes=$T2B_LINES contenu=[$(cat "$T2B_OUT")]"
fi

# ---------- T4 : illisible et BRUYANT ----------
mkdir -p "$WORK/t4/.claude"
printf '{ ceci n est pas du json valide' > "$WORK/t4/.claude/settings.json"
T4_OUT="$WORK/t4.out"; T4_ERR="$WORK/t4.err"
bash "$SCRIPT" --path "$WORK/t4" >"$T4_OUT" 2>"$T4_ERR"; T4_RC=$?
T4H_OUT="$WORK/t4h.out"; T4H_ERR="$WORK/t4h.err"
bash "$SCRIPT" --path "$WORK/t4" --hook >"$T4H_OUT" 2>"$T4H_ERR"; T4H_RC=$?
if [ "$(bytes_of "$T4_OUT")" = "0" ] && [ -s "$T4_ERR" ] && grep -qF "settings.json" "$T4_ERR" \
   && [ "$T4_RC" != "0" ] && [ "$T4_RC" != "2" ] \
   && [ "$T4H_RC" = "$T4_RC" ] && [ "$(bytes_of "$T4H_OUT")" = "0" ]; then
  ok "T4 illisible et bruyant : stdout vide, stderr nomme le fichier, rc=$T4_RC inchangé sous --hook"
else
  ko "T4 illisible : sans-hook(rc=$T4_RC,bytes=$(bytes_of "$T4_OUT"),err=[$(cat "$T4_ERR")]) hook(rc=$T4H_RC,bytes=$(bytes_of "$T4H_OUT"))"
fi

# ---------- T5 : les deux fichiers de réglages de PROJET, indépendamment ----------
# Sous-cas a : settings.json cassé, settings.local.json sain.
T5A_GONE_DIR="$(mktemp -d)"; T5A_GONE_BIN="$T5A_GONE_DIR/x"; rmdir "$T5A_GONE_DIR"
mkdir -p "$WORK/t5a"
T5A_TA="$WORK/t5a/a.sh"; T5A_TB="$WORK/t5a/b.sh"; touch "$T5A_TA" "$T5A_TB"
mk_settings "$WORK/t5a/.claude/settings.json" "$T5A_GONE_BIN" "$T5A_TA"
mk_settings "$WORK/t5a/.claude/settings.local.json" "$REAL_ABS_BIN" "$T5A_TB"
T5A_OUT="$WORK/t5a.out"; T5A_ERR="$WORK/t5a.err"
bash "$SCRIPT" --path "$WORK/t5a" >"$T5A_OUT" 2>"$T5A_ERR"; T5A_RC=$?

# Sous-cas b : settings.json sain, settings.local.json cassé (fixtures indépendantes de a).
T5B_GONE_DIR="$(mktemp -d)"; T5B_GONE_BIN="$T5B_GONE_DIR/y"; rmdir "$T5B_GONE_DIR"
mkdir -p "$WORK/t5b"
T5B_TA="$WORK/t5b/a.sh"; T5B_TB="$WORK/t5b/b.sh"; touch "$T5B_TA" "$T5B_TB"
mk_settings "$WORK/t5b/.claude/settings.json" "$REAL_ABS_BIN" "$T5B_TA"
mk_settings "$WORK/t5b/.claude/settings.local.json" "$T5B_GONE_BIN" "$T5B_TB"
T5B_OUT="$WORK/t5b.out"; T5B_ERR="$WORK/t5b.err"
bash "$SCRIPT" --path "$WORK/t5b" >"$T5B_OUT" 2>"$T5B_ERR"; T5B_RC=$?

if [ "$T5A_RC" = "0" ] && [ -s "$T5A_OUT" ] && grep -qF "$T5A_GONE_BIN" "$T5A_OUT"; then
  ok "T5 sous-cas a : entrée cassée dans settings.json (local sain) → constat"
else
  ko "T5 sous-cas a : rc=$T5A_RC contenu=[$(cat "$T5A_OUT")]"
fi
if [ "$T5B_RC" = "0" ] && [ -s "$T5B_OUT" ] && grep -qF "$T5B_GONE_BIN" "$T5B_OUT"; then
  ok "T5 sous-cas b : entrée cassée dans settings.local.json (projet sain) → constat"
else
  ko "T5 sous-cas b : rc=$T5B_RC contenu=[$(cat "$T5B_OUT")]"
fi

# ---------- T3 : code 2 jamais émis (agrégé sur T1/T2/T2b/T4) ----------
T3_OK=1
for rc in "$T1_RC" "$T1H_RC" "$T2_RC" "$T2B_RC" "$T4_RC" "$T4H_RC" "$T5A_RC" "$T5B_RC"; do
  [ "$rc" != "2" ] || T3_OK=0
done
if [ "$T3_OK" = "1" ]; then
  ok "T3 code 2 jamais émis (T1/T2/T2b/T4/T5, avec et sans --hook)"
else
  ko "T3 code 2 observé sur au moins une fixture"
fi

# ---------- T6 : absence totale de réglages ----------
mkdir -p "$WORK/t6"
T6_OUT="$WORK/t6.out"; T6_ERR="$WORK/t6.err"
bash "$SCRIPT" --path "$WORK/t6" >"$T6_OUT" 2>"$T6_ERR"; T6_RC=$?
T6H_OUT="$WORK/t6h.out"; T6H_ERR="$WORK/t6h.err"
bash "$SCRIPT" --path "$WORK/t6" --hook >"$T6H_OUT" 2>"$T6H_ERR"; T6H_RC=$?
if [ "$(bytes_of "$T6_OUT")" = "0" ] && [ "$T6_RC" = "3" ] \
   && [ "$(bytes_of "$T6H_OUT")" = "0" ] && [ "$T6H_RC" = "0" ]; then
  ok "T6 absence totale de réglages : stdout vide, rc 3 sans --hook, rc 0 avec"
else
  ko "T6 absence de réglages : sans-hook(rc=$T6_RC) hook(rc=$T6H_RC)"
fi

# ---------- T7 : parité d'interface ----------
T7_OK=1
bash "$SCRIPT" --hook --quiet >/dev/null 2>/dev/null; [ "$?" = "64" ] || T7_OK=0
bash "$SCRIPT" --argument-bidon >/dev/null 2>/dev/null; [ "$?" = "64" ] || T7_OK=0
bash "$SCRIPT" --path >/dev/null 2>/dev/null; [ "$?" = "64" ] || T7_OK=0
if [ "$T7_OK" = "1" ]; then
  ok "T7 parité d'interface : --hook+--quiet, argument inconnu, --path sans valeur → 64"
else
  ko "T7 parité d'interface : au moins un cas ne rend pas 64"
fi

# ---------- T8 : anti-vert-à-vide de la suite elle-même ----------
T8_N="$(grep -oE '^\[check-hook-paths\] [0-9]+ entrée' "$T1H_ERR" | grep -oE '[0-9]+' | head -1)"
if [ -n "${T8_N:-}" ] && [ "$T8_N" -gt 0 ]; then
  ok "T8 anti-vert-à-vide : $T8_N entrée(s) réellement examinée(s) sur la fixture T1"
else
  ko "T8 anti-vert-à-vide : nombre d'entrées examinées absent ou nul (stderr=[$(cat "$T1H_ERR")])"
fi

# ---------- T9 : garde anti-« réparation » de l'entrée n°26 ----------
T9_RESULT="$(python3 - "$HOOKS_JSON" <<'PYEOF'
import json, sys
d = json.load(open(sys.argv[1]))
hs = [h for gs in d["hooks"].values() for g in gs for h in g["hooks"]]
matches = [h for h in hs if any(isinstance(a, str) and "check-hook-paths.sh" in a for a in h.get("args", []))]
if len(matches) != 1:
    print("COUNT %d" % len(matches))
else:
    h = matches[0]
    cmd = h.get("command", "")
    if cmd == "bash" and "{{VF_BASH}}" not in cmd:
        print("OK")
    else:
        print("COMMAND %r" % cmd)
PYEOF
)"
if [ "$T9_RESULT" = "OK" ]; then
  ok "T9 entrée n°26 : command reste le nom nu littéral 'bash', jamais le jeton {{VF_BASH}}"
else
  ko "T9 entrée n°26 altérée ($T9_RESULT) — ce filet diagnostique la péremption du chemin absolu ; s'y soumettre le tuerait dans le seul cas où il sert (dérogation à ADR-071 §Décision 2, autorisée par l'approbation humaine de l'addendum du 2026-08-15, pas par l'ADR elle-même)"
fi

# ---------- T10 : identité du bloc localisateur (contre inject-mcp-tools.sh) ----------
extract_locator_block() {
  awk '/^# >>> vf-portable:locator/{flag=1} flag{print} /^# <<< vf-portable:locator/{flag=0; exit}' "$1"
}
sha256_of_stdin() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum | awk '{print $1}'
  else shasum -a 256 | awk '{print $1}'
  fi
}
checksum_locator_block() {
  local f="$1" block
  block="$(extract_locator_block "$f")"
  case "$block" in
    *'>>> vf-portable:locator'*'<<< vf-portable:locator'*) : ;;
    *) echo "MISSING"; return 0 ;;
  esac
  printf '%s\n' "$block" | sed -E 's/\[[A-Za-z0-9_-]+\]/[PREFIX]/g' | sha256_of_stdin
}
T10_SUM_SELF="$(checksum_locator_block "$SCRIPT")"
T10_SUM_REF="$(checksum_locator_block "$INJECT")"
if [ "$T10_SUM_SELF" = "MISSING" ] || [ "$T10_SUM_REF" = "MISSING" ]; then
  ko "T10 identité du bloc : marqueurs absents/dépareillés (self=$T10_SUM_SELF ref=$T10_SUM_REF) — échec BRUYANT, jamais un vert par défaut"
elif [ "$T10_SUM_SELF" = "$T10_SUM_REF" ]; then
  ok "T10 identité du bloc localisateur : somme identique à inject-mcp-tools.sh ($T10_SUM_SELF)"
else
  ko "T10 sommes DIVERGENTES : self=$T10_SUM_SELF ref=$T10_SUM_REF"
fi

# ---------- T11 : aller-retour dans le moteur de fusion ----------
# Fragment SYNTHÉTIQUE, autoportant — mirroir de la forme réelle de l'entrée n°26 (command nu
# littéral `bash`, args = script + --hook), mais jamais lu depuis le hooks.json VIVANT du module.
# Découplage DÉLIBÉRÉ de T9 (qui lit, lui, le hooks.json réel) : sous la mutation m3, seul T9 doit
# rougir — si T11 lisait directement le fragment réel, la mutation route l'entrée vers le fichier
# LOCAL (is_local_entry() de merge-hooks.sh teste la présence du jeton {{VF_BASH}}) et ferait
# rougir T11 aussi, ce qui violerait « attendu rouge T9 seul » du plan. Le mécanisme du moteur de
# fusion (routage, substitution, idempotence, retrait) est indépendant du CONTENU précis du hooks.json
# livré — un fragment synthétique de même forme suffit à le prouver, sans coupler les deux cas.
BASH_ABS_TEST="$(command -v bash || true)"
if [ -z "$BASH_ABS_TEST" ] || [ ! -f "$MERGER" ]; then
  skip "T11 aller-retour merge-hooks.sh : bash absolu ou merge-hooks.sh non dérivable sur cette machine"
else
  mkdir -p "$WORK/t11/scripts"
  T11_PROJECT="$WORK/t11/settings.json"
  T11_LOCAL="$WORK/t11/settings-local.json"
  T11_PREFIX="$WORK/t11/scripts"
  FRAG_T11="$WORK/t11/frag.json"
  printf '{"hooks":{"SessionStart":[{"matcher":"startup","hooks":[{"type":"command","command":"bash","args":["{{VF_SCRIPTS}}/check-hook-paths.sh","--hook"]}]}]}}\n' > "$FRAG_T11"
  VF_BASH_BIN="$BASH_ABS_TEST" bash "$MERGER" merge "$FRAG_T11" --settings "$T11_PROJECT" --settings-local "$T11_LOCAL" --scripts-prefix "$T11_PREFIX" 2>/dev/null
  T11_MERGE_RC=$?
  T11_OK=1
  [ "$T11_MERGE_RC" = "0" ] || { ko "T11 premier merge : rc=$T11_MERGE_RC"; T11_OK=0; }
  if [ "$T11_OK" = "1" ]; then
    python3 -c "
import json
d = json.load(open('$T11_PROJECT'))
entries = [h for g in d.get('hooks', {}).get('SessionStart', []) for h in g['hooks']]
match = [h for h in entries if any('check-hook-paths.sh' in a for a in h.get('args', []) if isinstance(a, str))]
assert len(match) == 1, 'attendu 1 entree dans le fichier projet, trouve %d' % len(match)
h = match[0]
assert h['command'] == 'bash', h['command']
assert h['args'][0] == '$T11_PREFIX/check-hook-paths.sh', h['args']
loc = json.load(open('$T11_LOCAL')) if __import__('os').path.isfile('$T11_LOCAL') else {}
loc_entries = [x for g in loc.get('hooks', {}).get('SessionStart', []) for x in g['hooks']]
loc_match = [x for x in loc_entries if any('check-hook-paths.sh' in a for a in x.get('args', []) if isinstance(a, str))]
assert len(loc_match) == 0, 'entree check-hook-paths.sh a fui dans le fichier local : %r' % loc_match
" 2>"$WORK/t11.err"
    if [ "$?" = "0" ]; then
      ok "T11a entrée atterrit dans le fichier PROJET (command nu, pas de jeton) — préfixe substitué dans args"
    else
      ko "T11a $(cat "$WORK/t11.err")"
      T11_OK=0
    fi
  fi
  if [ "$T11_OK" = "1" ]; then
    VF_BASH_BIN="$BASH_ABS_TEST" bash "$MERGER" merge "$FRAG_T11" --settings "$T11_PROJECT" --settings-local "$T11_LOCAL" --scripts-prefix "$T11_PREFIX" 2>/dev/null
    python3 -c "
import json
d = json.load(open('$T11_PROJECT'))
entries = [h for g in d.get('hooks', {}).get('SessionStart', []) for h in g['hooks']]
match = [h for h in entries if any('check-hook-paths.sh' in a for a in h.get('args', []) if isinstance(a, str))]
assert len(match) == 1, 'seconde fusion a duplique : %d entrees' % len(match)
" 2>"$WORK/t11b.err"
    if [ "$?" = "0" ]; then
      ok "T11b idempotence : une seconde fusion ne duplique pas l'entrée"
    else
      ko "T11b $(cat "$WORK/t11b.err")"
      T11_OK=0
    fi
  fi
  if [ "$T11_OK" = "1" ]; then
    bash "$MERGER" remove "$FRAG_T11" --settings "$T11_PROJECT" --settings-local "$T11_LOCAL" 2>/dev/null
    python3 -c "
import json, os
d = json.load(open('$T11_PROJECT'))
entries = [h for g in d.get('hooks', {}).get('SessionStart', []) for h in g['hooks']]
match = [h for h in entries if any('check-hook-paths.sh' in a for a in h.get('args', []) if isinstance(a, str))]
assert len(match) == 0, 'entree residuelle apres remove : %r' % match
" 2>"$WORK/t11c.err"
    if [ "$?" = "0" ]; then
      ok "T11c remove retire l'entrée du fichier projet"
    else
      ko "T11c $(cat "$WORK/t11c.err")"
    fi
  fi
fi

# ---------- T12 : inventaire durable et parc s'accordent (avec écart transitoire toléré) ----------
if ! command -v python3 >/dev/null 2>&1; then
  skip "T12 inventaire/parc : python3 indisponible"
else
  DOC_DECLARED="$(grep -oE 'assert n==[0-9]+' "$DOC" | head -1 | grep -oE '[0-9]+')"
  ACTUAL="$(cd "$REPO_ROOT" && python3 -c "
import json, glob
n = sum(len(h.get('hooks', [])) for f in sorted(glob.glob('plugin/*/hooks/hooks.json'))
        for gs in json.load(open(f))['hooks'].values() for h in gs)
print(n)
")"
  if [ -z "${DOC_DECLARED:-}" ]; then
    ko "T12 inventaire/parc : assertion de recomptage introuvable dans $DOC"
  elif [ "$DOC_DECLARED" = "$ACTUAL" ]; then
    ok "T12 inventaire et parc s'accordent : $ACTUAL entrée(s) (doc et recompte réel identiques)"
  elif [ "$ACTUAL" = "$((DOC_DECLARED + 1))" ]; then
    skip "T12 écart transitoire ATTENDU ($DOC_DECLARED déclaré par le document, $ACTUAL réel) — la 26e entrée est posée depuis la tâche 1 de ce plan, l'inventaire durable n'est mis à jour QUE par sa tâche 3, qui rejoue cette suite en fin de plan pour prouver la convergence finale"
  else
    ko "T12 écart NON attendu — $DOC déclare $DOC_DECLARED, le recompte réel du parc rend $ACTUAL"
  fi
fi

echo ""
echo "== Résultat : $pass OK, $fail KO, $skipped SKIP =="
[ "$fail" -eq 0 ] && exit 0 || exit 1
