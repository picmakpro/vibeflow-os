#!/usr/bin/env bash
# test-seed-registres.sh — Suite de l'instanciation des registres canoniques.
#
# T1  — lab vierge : les 5 registres sont créés depuis les gabarits → exit 0
# T2  — IDEMPOTENCE : second passage → rien de créé, exit 0
# T3  — NON DESTRUCTIF (le test qui compte) : un registre porteur de contenu utilisateur n'est
#       NI écrasé NI modifié — vérifié par empreinte, pas par simple présence du fichier
# T4  — création partielle : seuls les registres manquants sont posés, les autres intacts
# T5  — --check sur lab vierge → exit 3 (verdict INDÉTERMINÉ), et RIEN n'est écrit
# T6  — --check sur lab complet → exit 0
# T7  — dossier de gabarits introuvable → exit 1 BRUYANT (jamais un faux vert)
# T8  — dossier de gabarits vide → exit 1 bruyant
# T9  — --quiet : silencieux en régime nominal, mais une ANOMALIE traverse quand même stderr
# T10 — data-driven : un 6e gabarit ajouté est posé sans toucher au script
# T11 — le résultat passe check-registres.sh --strict (contrat de bout en bout entre les deux)
# T12 — --project pose dans le lab courant (./.claude/memory), pas dans le scope d'installation
# T13 — --project reconnaît un lab marqué par .claude/ aussi bien que par .planning/
# T14 — GARDE : hors d'un lab, rien n'est écrit (le hook de session ne sème pas n'importe où)
# T15 — VF_NO_AUTO_SEED coupe l'instanciation automatique sans désinstaller
# T16 — --project reste non destructif au rejeu (il tourne à CHAQUE ouverture de session)
# T17 — deux labs distincts ont deux mémoires distinctes (l'invariant que le scope user cassait)

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$(cd "$TESTS_DIR/.." && pwd)"
SEED="$SCRIPTS_DIR/seed-registres.sh"
CHECK="$SCRIPTS_DIR/check-registres.sh"
TEMPLATES="$(cd "$SCRIPTS_DIR/../references/templates-memoire" && pwd)"

pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }

echo "== test-seed-registres (seeder: $SEED) =="

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Chaque cas part d'un dossier mémoire neuf.
fresh() { rm -rf "$WORK/mem"; echo "$WORK/mem"; }

# ---------- T1 : lab vierge → 5 registres créés ----------
MEM="$(fresh)"
bash "$SEED" --memory-dir="$MEM" --templates-dir="$TEMPLATES" >/dev/null 2>&1
RC=$?
n=$(find "$MEM" -maxdepth 1 -name '*.md' 2>/dev/null | grep -c . || true)
if [ "$RC" -eq 0 ] && [ "$n" -eq 5 ]; then
  ok "T1 lab vierge : 5 registres créés (exit 0)"
else
  ko "T1 attendu 5 registres / exit 0 (obtenu $n / rc=$RC)"
fi

# Les noms sont bien les canons attendus par le lint, pas les noms de gabarits.
canon_ok=true
for r in DECISIONS LEARNINGS BLOCKERS JOURNAL EVALS; do
  [ -f "$MEM/$r.md" ] || canon_ok=false
done
$canon_ok && ok "T1bis noms canoniques (DECISIONS/LEARNINGS/BLOCKERS/JOURNAL/EVALS)" \
          || ko "T1bis un registre canon manque — mapping <nom>-template.md → <NOM>.md cassé"

# ---------- T2 : idempotence ----------
out=$(bash "$SEED" --memory-dir="$MEM" --templates-dir="$TEMPLATES" 2>&1)
RC=$?
n2=$(find "$MEM" -maxdepth 1 -name '*.md' | grep -c . || true)
if [ "$RC" -eq 0 ] && [ "$n2" -eq 5 ] && printf '%s' "$out" | grep -q "déjà en place"; then
  ok "T2 idempotence : second passage sans création, exit 0"
else
  ko "T2 second passage inattendu (rc=$RC, $n2 fichiers) : $out"
fi

# ---------- T3 : NON DESTRUCTIF (invariant central du script) ----------
printf '\n## DEC-999 : trace utilisateur irremplaçable\n' >> "$MEM/DECISIONS.md"
before=$(shasum "$MEM/DECISIONS.md" | cut -d' ' -f1)
bash "$SEED" --memory-dir="$MEM" --templates-dir="$TEMPLATES" >/dev/null 2>&1
after=$(shasum "$MEM/DECISIONS.md" | cut -d' ' -f1)
if [ "$before" = "$after" ] && grep -q "DEC-999" "$MEM/DECISIONS.md"; then
  ok "T3 NON DESTRUCTIF : registre porteur de contenu inchangé (empreinte identique)"
else
  ko "T3 RÉGRESSION GRAVE : le seeder a modifié un registre existant"
fi

# ---------- T4 : création partielle ----------
rm -f "$MEM/LEARNINGS.md" "$MEM/BLOCKERS.md"
before=$(shasum "$MEM/DECISIONS.md" | cut -d' ' -f1)
bash "$SEED" --memory-dir="$MEM" --templates-dir="$TEMPLATES" >/dev/null 2>&1
after=$(shasum "$MEM/DECISIONS.md" | cut -d' ' -f1)
if [ -f "$MEM/LEARNINGS.md" ] && [ -f "$MEM/BLOCKERS.md" ] && [ "$before" = "$after" ]; then
  ok "T4 partiel : les 2 manquants posés, DECISIONS.md toujours intact"
else
  ko "T4 création partielle incorrecte"
fi

# ---------- T5 : --check sur lab vierge → exit 3, et RIEN écrit ----------
MEM="$(fresh)"
bash "$SEED" --check --memory-dir="$MEM" --templates-dir="$TEMPLATES" >/dev/null 2>&1
RC=$?
if [ "$RC" -eq 3 ] && [ ! -d "$MEM" ]; then
  ok "T5 --check lab vierge : exit 3 et aucun écrit (pas même le dossier)"
else
  ko "T5 attendu exit 3 sans écriture (rc=$RC, dossier présent : $([ -d "$MEM" ] && echo oui || echo non))"
fi

# ---------- T6 : --check sur lab complet → exit 0 ----------
bash "$SEED" --memory-dir="$MEM" --templates-dir="$TEMPLATES" >/dev/null 2>&1
bash "$SEED" --check --memory-dir="$MEM" --templates-dir="$TEMPLATES" >/dev/null 2>&1
[ $? -eq 0 ] && ok "T6 --check lab complet : exit 0" || ko "T6 attendu exit 0"

# ---------- T7 : gabarits introuvables → échec BRUYANT ----------
MEM="$(fresh)"
out=$(bash "$SEED" --memory-dir="$MEM" --templates-dir="$WORK/nexiste-pas" 2>&1)
RC=$?
if [ "$RC" -eq 1 ] && printf '%s' "$out" | grep -qi "introuvable"; then
  ok "T7 gabarits absents : exit 1 avec message explicite (jamais un faux vert)"
else
  ko "T7 attendu exit 1 bruyant (rc=$RC) : $out"
fi

# ---------- T8 : dossier de gabarits vide → échec bruyant ----------
mkdir -p "$WORK/vide"
out=$(bash "$SEED" --memory-dir="$MEM" --templates-dir="$WORK/vide" 2>&1)
RC=$?
if [ "$RC" -eq 1 ] && printf '%s' "$out" | grep -qi "aucun gabarit"; then
  ok "T8 gabarits vides : exit 1 avec message explicite"
else
  ko "T8 attendu exit 1 bruyant (rc=$RC) : $out"
fi

# ---------- T9 : --quiet muet en nominal, bavard sur anomalie ----------
MEM="$(fresh)"
out=$(bash "$SEED" --quiet --memory-dir="$MEM" --templates-dir="$TEMPLATES" 2>&1)
if [ -z "$out" ]; then
  ok "T9 --quiet : silencieux en régime nominal"
else
  ko "T9 --quiet devrait être muet, obtenu : $out"
fi
out=$(bash "$SEED" --quiet --memory-dir="$MEM" --templates-dir="$WORK/nexiste-pas" 2>&1)
if printf '%s' "$out" | grep -qi "introuvable"; then
  ok "T9bis --quiet : l'ANOMALIE traverse quand même (pas de dégradation silencieuse)"
else
  ko "T9bis --quiet a avalé une anomalie — exactement le défaut que le hook doit fermer"
fi

# ---------- T10 : data-driven, un 6e gabarit est posé sans toucher au script ----------
cp -r "$TEMPLATES" "$WORK/tpl6"
printf '# Registre de test\n' > "$WORK/tpl6/rituels-template.md"
MEM="$(fresh)"
bash "$SEED" --memory-dir="$MEM" --templates-dir="$WORK/tpl6" >/dev/null 2>&1
if [ -f "$MEM/RITUELS.md" ]; then
  ok "T10 data-driven : un 6e gabarit est posé sans modification du script"
else
  ko "T10 le script a une liste de registres en dur — régression de doctrine"
fi

# ---------- T11 : contrat de bout en bout avec le lint ----------
MEM="$(fresh)"
bash "$SEED" --memory-dir="$MEM" --templates-dir="$TEMPLATES" >/dev/null 2>&1
MEMORY_DIR="$MEM" bash "$CHECK" --strict >/dev/null 2>&1
RC=$?
if [ "$RC" -eq 0 ]; then
  ok "T11 bout en bout : la sortie du seeder passe check-registres.sh --strict"
else
  ko "T11 les registres posés ne passent pas leur propre lint (rc=$RC) — les deux scripts divergent"
fi

# ---------- T12 : --project pose dans le LAB COURANT, pas dans le scope ----------
# Le cas scope user : les scripts vivent dans le home, mais les registres doivent atterrir dans le
# projet ouvert — sinon le seeder remplit le home pendant que le lint constate un projet vide.
mkdir -p "$WORK/lab-planning/.planning"
(cd "$WORK/lab-planning" && bash "$SEED" --project --templates-dir="$TEMPLATES" >/dev/null 2>&1)
n=$(find "$WORK/lab-planning/.claude/memory" -maxdepth 1 -name '*.md' 2>/dev/null | grep -c . || true)
if [ "$n" -eq 5 ]; then
  ok "T12 --project : 5 registres posés dans ./.claude/memory du lab (marqueur .planning/)"
else
  ko "T12 attendu 5 registres dans le lab courant (obtenu $n)"
fi

# ---------- T13 : --project reconnaît aussi un lab marqué par .claude/ ----------
mkdir -p "$WORK/lab-claude/.claude"
(cd "$WORK/lab-claude" && bash "$SEED" --project --templates-dir="$TEMPLATES" >/dev/null 2>&1)
n=$(find "$WORK/lab-claude/.claude/memory" -maxdepth 1 -name '*.md' 2>/dev/null | grep -c . || true)
[ "$n" -eq 5 ] && ok "T13 --project : lab reconnu par .claude/ également" \
               || ko "T13 attendu 5 registres (obtenu $n)"

# ---------- T14 : GARDE — un dossier qui n'est pas un lab n'est JAMAIS semé ----------
# Sans cette garde, le hook de session déposerait 5 fichiers dans le premier dépôt venu.
mkdir -p "$WORK/pas-un-lab"
(cd "$WORK/pas-un-lab" && bash "$SEED" --project --templates-dir="$TEMPLATES" >/dev/null 2>&1)
RC=$?
if [ "$RC" -eq 0 ] && [ ! -d "$WORK/pas-un-lab/.claude" ]; then
  ok "T14 GARDE : dossier sans .planning/ ni .claude/ → rien écrit, exit 0 (non-événement)"
else
  ko "T14 le mode --project a semé hors d'un lab (rc=$RC) — garde inopérante"
fi

# ---------- T15 : VF_NO_AUTO_SEED coupe l'instanciation automatique ----------
mkdir -p "$WORK/lab-optout/.planning"
(cd "$WORK/lab-optout" && VF_NO_AUTO_SEED=1 bash "$SEED" --project --templates-dir="$TEMPLATES" >/dev/null 2>&1)
if [ ! -d "$WORK/lab-optout/.claude/memory" ]; then
  ok "T15 VF_NO_AUTO_SEED : instanciation automatique désactivable sans désinstaller"
else
  ko "T15 VF_NO_AUTO_SEED ignoré — l'échappatoire ne mord pas"
fi

# ---------- T16 : --project reste non destructif ----------
printf '\n## DEC-777 : trace lab\n' >> "$WORK/lab-planning/.claude/memory/DECISIONS.md"
before=$(shasum "$WORK/lab-planning/.claude/memory/DECISIONS.md" | cut -d' ' -f1)
(cd "$WORK/lab-planning" && bash "$SEED" --project --templates-dir="$TEMPLATES" >/dev/null 2>&1)
after=$(shasum "$WORK/lab-planning/.claude/memory/DECISIONS.md" | cut -d' ' -f1)
[ "$before" = "$after" ] && ok "T16 --project : rejeu non destructif (le hook tourne à chaque session)" \
                         || ko "T16 RÉGRESSION : --project a modifié un registre existant"

# ---------- T17 : deux labs distincts ont deux mémoires distinctes ----------
# C'est l'invariant que le scope user cassait : une seule mémoire de compte pour tous les projets.
if [ -f "$WORK/lab-planning/.claude/memory/DECISIONS.md" ] \
   && [ -f "$WORK/lab-claude/.claude/memory/DECISIONS.md" ] \
   && ! grep -q "DEC-777" "$WORK/lab-claude/.claude/memory/DECISIONS.md"; then
  ok "T17 cloisonnement : deux labs, deux mémoires — aucune fuite de l'un vers l'autre"
else
  ko "T17 les labs partagent leur mémoire — le cloisonnement per-projet ne tient pas"
fi

echo ""
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
