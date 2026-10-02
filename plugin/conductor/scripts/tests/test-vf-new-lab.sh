#!/usr/bin/env bash
# test-vf-new-lab.sh — Asserts documentaires sur le SKILL vf-new-lab (mode express, audit 2026-07-25 §F).
# Portable, sans réseau. Vérifie le CONTRAT écrit du skill : express existe, 3 questions max,
# Gate C jamais affaibli, profil leger, dérivation marquée, fan-out en fond, dette d'express.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="$SCRIPT_DIR/../skills/vf-new-lab/SKILL.md"
PASS=0; FAIL=0

ok()  { if [ "$2" = "true" ]; then echo "  ✓ $1"; PASS=$((PASS+1)); else echo "  ✗ $1"; FAIL=$((FAIL+1)); fi; }
has() { grep -qF "$1" "$SKILL" 2>/dev/null && echo true || echo false; }
# Bloc borné : le squelette YAML de frontmatter posé à la Phase 5 (entre ```yaml et la ``` fermante).
squelette() { sed -n '/```yaml/,/^   ```$/p' "$SKILL" 2>/dev/null; }
# Bloc borné : le point 2 du Gate C (énumération des champs exigés par check-agents.sh --strict).
gate_c_point2() { sed -n '/`bash .claude\/scripts\/check-agents.sh --strict`/,/^   3\. /p' "$SKILL" 2>/dev/null | sed '$d'; }

echo "== test-vf-new-lab (mode express) =="

[ -f "$SKILL" ] || { echo "  ✗ SKILL.md introuvable : $SKILL"; exit 1; }

# --- Le mode express existe et est routé dès le triage ---
ok "section Mode express présente"            "$(has "## Mode express")"
ok "express proposé au triage (Phase 0)"      "$(has "Détection express")"
ok "déclencheurs d'urgence documentés"        "$(has "juste pour tester")"
ok "contrat ≤ 15 minutes documenté"           "$(has "15 min")"

# --- 3 questions maximum ---
ok "3 questions maximum documentées"          "$(has "3 questions maximum")"
ok "les 3 questions : métier"                 "$(has "Métier du lab")"
ok "les 3 questions : objectif en une phrase" "$(has "en une phrase")"
ok "les 3 questions : capacités prioritaires" "$(has "Capacités prioritaires")"

# --- Dérivation dégradée assumée ---
ok "marqueur [DÉRIVÉ — à affiner] documenté"  "$(has "[DÉRIVÉ — à affiner]")"
ok "profil leger posé dans config.json"       "$(has "Profil \`leger\` posé d'office")"
ok "s'appuie sur .planning/config.json"       "$(has ".planning/config.json")"

# --- Gates : A/B assouplis, C INTACT ---
ok "Gate A assoupli : [DÉRIVÉ] ne bloque pas" "$(has "ne bloquent pas")"
ok "Gate A : seuls les [À CLARIFIER] sur les 3 réponses bloquent" "$(has "l'une des 3 réponses données")"
ok "Gate C déclaré INTACT en express"         "$(has "Gate C — INTACT, non négociable")"
ok "Gate C : vérifs machine non négociables"  "$(has "ne se négocient JAMAIS")"
# Anti-régression : aucune ligne ne doit affaiblir le Gate C (assoupli/allégé/optionnel/sauté).
if grep -Ei 'Gate C[^.]*(assoupli|allégé|optionnel|sauté|skip|négociable[^s])' "$SKILL" | grep -qv "non négociable"; then
  ok "Gate C jamais assoupli dans le texte" "false"
else
  ok "Gate C jamais assoupli dans le texte" "true"
fi

# --- Fabrication en tâche de fond + dette d'express ---
ok "fan-out skill-creator en tâche de fond"   "$(has "en arrière-plan")"
ok "l'utilisateur peut travailler pendant la fabrication" "$(has "travailler pendant la fabrication")"
ok "récap dette d'express obligatoire"        "$(has "dette d'express")"
ok "affinage ultérieur via /vf-calibrate"     "$(has "/vf-calibrate")"

# --- effort aligné sur check-agents.sh (ADR-044) : le gate est bloquant même si CLAUDE.md:63 et
# docs/ADR.md:63 (doctrine interne, mainteneurs, hors périmètre de cette PR — voir Reste ouvert
# du dossier de soumission) ne citent encore que description/model/memory. Assertions bornées au
# bloc YAML du squelette (Phase 5) et au point 2 du Gate C : pas de grep sur tout le fichier, pour
# ne pas être trompé par une occurrence hors de ces deux blocs. ---
EFFORT_LIGNE="$(squelette | grep -E '^\s*effort:' | head -1)"

if printf '%s' "$EFFORT_LIGNE" | grep -qiE 'optionnel|facultatif|optional'; then
  ok "squelette agent : effort jamais présenté comme optionnel" "false"
else
  ok "squelette agent : effort jamais présenté comme optionnel" "true"
fi
ok "squelette agent : effort au format check-agents (low|medium|high|xhigh|max)" \
  "$(printf '%s' "$EFFORT_LIGNE" | grep -qE 'effort: <?low\|medium\|high\|xhigh\|max' && echo true || echo false)"
ok "Gate C (point 2) : effort cité dans l'énumération des champs exigés" \
  "$(gate_c_point2 | grep -qF "name/description/model/memory/effort" && echo true || echo false)"

# --- Densité (ADR-029 : skill ≤ 500 lignes) ---
LINES=$(wc -l < "$SKILL" | tr -d ' ')
ok "densité ≤ 500 lignes ($LINES)"            "$([ "$LINES" -le 500 ] && echo true || echo false)"

echo ""
echo "  PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
