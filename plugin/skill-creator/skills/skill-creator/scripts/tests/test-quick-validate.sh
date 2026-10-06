#!/usr/bin/env bash
# Test de quick_validate.py — autonome (crée des skills temporaires)
#
# 1-2 : les clés VibeFlow que SKILL.md demande d'écrire (vf-nature, ecrit, vf-rubrique-juge,
#       marqueurs) sont acceptées — régression v2.67.0 : skill-creator v1.1.0 les demandait et
#       son propre validateur les refusait (« Unexpected key(s) … vf-nature »)
# 3   : une clé inconnue reste refusée (le validateur discrimine toujours)
# 4   : parité avec conductor/scripts/check-skills.sh (VIBEFLOW_SKILL_FIELDS) — une clé ajoutée
#       au gate sans l'être ici rougit
# 5   : classe d'invocation (POCK-07) : vf-invocation: user + disable-model-invocation: true
#       acceptés ; une valeur de classe n'est jamais jugée ici (check-skills.sh la juge)
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HERE/../quick_validate.py"
CHECK_SKILLS="$HERE/../../../../../conductor/scripts/check-skills.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0; fail=0
ok()   { echo "  ✓ $1"; pass=$((pass+1)); }
ko()   { echo "  ✗ $1"; fail=$((fail+1)); }

mk_skill() { # mk_skill <dir> <lignes de frontmatter supplémentaires>
  mkdir -p "$TMP/$1"
  printf -- '---\nname: %s\ndescription: Skill de test du validateur.\n%b---\n\n# Test\n' "$1" "$2" > "$TMP/$1/SKILL.md"
}

echo "== test-quick-validate =="

# 1. vf-nature seule (nature outil, cas par défaut du flux)
mk_skill demo-outil 'vf-nature: outil\n'
out=$(python3 "$SCRIPT" "$TMP/demo-outil" 2>&1); rc=$?
[ $rc -eq 0 ] && ok "vf-nature: outil → exit 0" || ko "vf-nature: outil refusé (rc=$rc) : $out"

# 2. procédure complète : ecrit, vf-rubrique-juge et les trois marqueurs
mk_skill demo-procedure 'vf-nature: procedure\necrit: docs/livrable.md\nvf-rubrique-juge: vf-design-judge\nvf-gate-bloquant: true\nvf-livrable-tiers: false\nvf-couche-qualite: true\n'
out=$(python3 "$SCRIPT" "$TMP/demo-procedure" 2>&1); rc=$?
[ $rc -eq 0 ] && ok "procédure complète → exit 0" || ko "procédure complète refusée (rc=$rc) : $out"

# 3. clé inconnue → toujours refusée
mk_skill demo-inconnue 'vf-inventee: x\n'
out=$(python3 "$SCRIPT" "$TMP/demo-inconnue" 2>&1); rc=$?
if [ $rc -ne 0 ] && printf '%s' "$out" | grep -q 'vf-inventee'; then
  ok "clé inconnue → refusée et nommée"
else
  ko "clé inconnue acceptée (rc=$rc) : $out"
fi

# 4. parité avec le gate des skills
if [ ! -f "$CHECK_SKILLS" ]; then
  ko "check-skills.sh introuvable ($CHECK_SKILLS) — parité non vérifiable"
else
  champs=$(python3 - "$CHECK_SKILLS" <<'EOF'
import re, sys
src = open(sys.argv[1], encoding="utf-8").read()
m = re.search(r'VIBEFLOW_SKILL_FIELDS\s*=\s*\{([^}]*)\}', src)
print(" ".join(re.findall(r'"([^"]+)"', m.group(1))) if m else "")
EOF
)
  if [ -z "$champs" ]; then
    ko "VIBEFLOW_SKILL_FIELDS illisible dans check-skills.sh — parité non vérifiable"
  else
    fm=""; for c in $champs; do fm="${fm}${c}: x\n"; done
    mk_skill demo-parite "$fm"
    out=$(python3 "$SCRIPT" "$TMP/demo-parite" 2>&1)
    if printf '%s' "$out" | grep -q 'Unexpected key'; then
      ko "clé(s) du gate refusée(s) par le validateur : $out"
    else
      ok "les $(echo $champs | wc -w | tr -d ' ') clés de VIBEFLOW_SKILL_FIELDS sont acceptées"
    fi
  fi
fi

# 5. classe d'invocation (POCK-07) : un skill user produit par le flux doit passer le validateur
mk_skill demo-user 'vf-invocation: user\ndisable-model-invocation: true\n'
out=$(python3 "$SCRIPT" "$TMP/demo-user" 2>&1); rc=$?
[ $rc -eq 0 ] && ok "vf-invocation: user + disable-model-invocation: true → exit 0" || ko "classe user refusée (rc=$rc) : $out"

echo "== bilan : $pass ok / $fail ko =="
[ $((pass + fail)) -gt 0 ] || { echo "  ✗ aucune assertion exécutée"; exit 1; }
[ "$fail" -eq 0 ]
