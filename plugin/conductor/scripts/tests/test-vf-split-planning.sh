#!/usr/bin/env bash
# test-vf-split-planning.sh — Contrat documentaire du skill vf-split-planning, de sa commande et de ses
# renvois (Phase 41.2, plan 41.2-05, exigences WSCH-01 et WSCH-03 côté skill, QUAL-01).
#
# Portable, sans réseau, sans moteur. Vérifie le CONTRAT ÉCRIT : la question exacte, son repli
# non interactif, les scripts cités à la cascade `.claude/scripts/`, le geste suivant, et — surtout —
# WSCH-01 : AUCUN des deux mots du jargon moteur dans ce qui est montré à l'utilisateur.
#
# SONDE WSCH-01 (décision P412-D-06 du manager : pas d'exemption « identifiant technique »). La sonde
# balaie le fichier ENTIER (frontmatter, spans « … », prose, blocs de code), pas seulement les spans :
# un mot interdit où que ce soit rougit. Elle est anti-vide : au moins un span « … » lu pour le skill,
# au moins une ligne lue pour la commande, sinon rc 2. Les mots sont assemblés à l'exécution (le gate
# ne se balaie pas lui-même).
#
# Surcharges de test (preuve du rouge, jamais en usage normal) :
#   VF_TEST_SKILL_PATH    chemin du SKILL.md jugé (absent => « introuvable », rc 1)
#   VF_TEST_COMMAND_PATH  chemin de la commande jugée
#
# Cas : T1-T12 (skill + commande), D1-D5 (la sonde discrimine), R1-R4 (renvois), M1-M2 (manuel).
# Aucun `diff` (proxifié, menteur sur ce poste) : `cmp -s`.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
CONDUCTOR="$(cd "$HERE/../.." && pwd)"
PLUGIN="$(cd "$CONDUCTOR/.." && pwd)"
SKILL="${VF_TEST_SKILL_PATH:-$CONDUCTOR/skills/vf-split-planning/SKILL.md}"
CMD="${VF_TEST_COMMAND_PATH:-$PLUGIN/commands/vf-split-planning.md}"
NEWLAB="$CONDUCTOR/skills/vf-new-lab/SKILL.md"
ROUTING="$PLUGIN/dev-orchestrator/references/intent-routing.md"
REPO="$(cd "$PLUGIN/.." && pwd)"
MAN_FR="$REPO/manual/fr/06-reference/commandes.md"
MAN_EN="$REPO/manual/en/06-reference/commands.md"

PASS=0; FAIL=0
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

ok() { # <ID> <description> <true|false> [détail attendu/obtenu]
  if [ "$3" = "true" ]; then echo "  ✓ $1 — $2"; PASS=$((PASS+1))
  else echo "  ✗ $1 — $2${4:+ [$4]}"; FAIL=$((FAIL+1)); fi
}
has()  { grep -qF -- "$1" "$2" 2>/dev/null && echo true || echo false; }
hasx() { grep -qxF -- "$1" "$2" 2>/dev/null && echo true || echo false; }

echo "== test-vf-split-planning (WSCH-01, WSCH-03 côté skill) =="

[ -f "$SKILL" ] || { echo "  ✗ T1 — SKILL.md introuvable : $SKILL"; exit 1; }
[ -f "$CMD" ]   || { echo "  ✗ T1 — commande introuvable : $CMD"; exit 1; }
ok T1 "SKILL.md et commande présents" true

# Mots interdits, assemblés à l'exécution (jamais le littéral dans ce fichier).
W1="work""stream"; W2="compar""timent"

# --- La sonde : fichier ENTIER ; mode span (>= 1 span « … ») ou ligne (>= 1 ligne non vide) ----------
# Sortie : « spans=N lignes=N hits=N » ; rc 0 conforme, 1 mot interdit, 2 rien lu (jamais un vert à vide).
sonde() { # <fichier> <span|ligne>
  LC_ALL=C awk -v mode="$2" -v w1="$W1" -v w2="$W2" '
    BEGIN{ spans=0; lignes=0; hits=0 }
    { if ($0 ~ /[^ \t]/) lignes++
      rest=$0
      while ((a=index(rest,"\302\253"))>0) { rest=substr(rest,a+2); b=index(rest,"\302\273")
        if (b==0) { spans++; break }
        spans++; rest=substr(rest,b+2) }
      low=tolower($0)
      if (index(low,w1)>0 || index(low,w2)>0) { hits++; print "HIT l." NR ": " substr($0,1,100) } }
    END{ print "spans=" spans " lignes=" lignes " hits=" hits
         vide = (mode=="span") ? (spans==0) : (lignes==0)
         exit (vide ? 2 : (hits>0 ? 1 : 0)) }' "$1"
}

# --- T2/T3 : la question, sa ligne « pourquoi », ses options, son header ----------------------------
ok T2 "la question exacte de WSCH-01" \
  "$(has "Plusieurs personnes ou agents vont-ils travailler en parallèle sur des sujets séparés ?" "$SKILL")"
t3=true
for s in "Ça évite qu'un deuxième chantier attende que le premier soit fini pour démarrer. Par défaut, un seul planning suffit — on peut toujours basculer plus tard." \
         "Oui, prévoir plusieurs sujets en parallèle" "Non, un seul planning suffit (recommandé)" "header « Parallèle »"; do
  [ "$(has "$s" "$SKILL")" = "true" ] || t3=false
done
ok T3 "ligne « pourquoi », deux options et header « Parallèle »" "$t3"

# --- T4/T5 : WSCH-01, sonde sur le fichier entier ----------------------------------------------------
out=$(sonde "$SKILL" span); rc=$?
ok T4 "WSCH-01 skill : zéro mot interdit sur le fichier entier, >= 1 span lu ($(printf '%s' "$out" | tail -1))" \
  "$([ $rc -eq 0 ] && echo true || echo false)" "attendu rc 0, obtenu rc $rc : $(printf '%s' "$out" | head -3 | tr '\n' ' ')"
out=$(sonde "$CMD" ligne); rc=$?
ok T5 "WSCH-01 commande : zéro mot interdit, >= 1 ligne lue ($(printf '%s' "$out" | tail -1))" \
  "$([ $rc -eq 0 ] && echo true || echo false)" "attendu rc 0, obtenu rc $rc : $(printf '%s' "$out" | head -3 | tr '\n' ' ')"

# --- T6 : repli D-02 (planning unique, mention du geste ultérieur) ------------------------------------
t6=true
for s in "est indisponible" "Réponse négative ou question sautée" "RIEN n'est créé" "reste possible"; do
  [ "$(has "$s" "$SKILL")" = "true" ] || t6=false
done
ok T6 "repli non interactif / refus : planning unique, rien créé, /vf-split-planning reste possible" "$t6"

# --- T7 : scripts cités en cascade .claude/scripts/, jamais plugin/<module>/scripts/ -----------------
t7=true
[ "$(has ".claude/scripts/split-planning.sh" "$SKILL")" = "true" ] || t7=false
[ "$(has ".claude/scripts/check-planning-not-inflight.sh" "$SKILL")" = "true" ] || t7=false
grep -qE 'plugin/[a-zA-Z0-9_-]+/scripts/' "$SKILL" && t7=false
ok T7 "scripts cités en .claude/scripts/, aucun chemin plugin/<module>/scripts/" "$t7"

# --- T8/T9 : frontmatter et densité ------------------------------------------------------------------
fm=$(awk '/^---[ \t]*$/{n++; next} n==1{print} n>=2{exit}' "$SKILL")
t8=true
printf '%s\n' "$fm" | grep -qx 'name: vf-split-planning' || t8=false
printf '%s\n' "$fm" | grep -q 'vf-nature' && t8=false
ok T8 "frontmatter : name: vf-split-planning, pas de vf-nature" "$t8"
n=$(wc -l < "$SKILL" | tr -d ' ')
ok T9 "densité : $n lignes <= 500" "$([ "$n" -le 500 ] && echo true || echo false)"

# --- T10 : geste suivant (commande isolée dans son span) + proposition de commit sans le faire -------
t10=true
grep -qxF "« /gsd-new-milestone --ws <sujet> »" "$SKILL" || t10=false
[ "$(has "state.json" "$SKILL")" = "true" ] || t10=false
[ "$(has "Ne JAMAIS commiter sans accord" "$SKILL")" = "true" ] || t10=false
ok T10 "geste suivant en un span isolé, commit proposé (state.json) jamais fait" "$t10"

# --- T11/T12 -----------------------------------------------------------------------------------------
ok T11 "garde-fou « seul le moteur écrit »" "$(has "Seul le moteur écrit" "$SKILL")"
t12=true
[ "$(has 'skill **`vf-split-planning`**' "$CMD")" = "true" ] || t12=false
[ "$(has '$ARGUMENTS' "$CMD")" = "true" ] || t12=false
[ "$(has 'vibeflow-install' "$CMD")" = "true" ] || t12=false
ok T12 "trampoline : invoque le skill, passe \$ARGUMENTS, renvoie à vibeflow-install" "$t12"

# --- D1-D5 : la sonde DISCRIMINE (copies jetables du skill) -------------------------------------------
echo "  -- discriminations de la sonde (copies jetables) --"
DOK=0
verdict() { sonde "$1" span >/dev/null 2>&1; echo $?; }
disc() { # <ID> <description> <attendu> <fichier>
  local r; r=$(verdict "$4")
  if [ "$r" = "$3" ]; then DOK=$((DOK+1)); ok "$1" "$2" true
  else ok "$1" "$2" false "attendu rc $3, obtenu rc $r"; fi
}

# D1 : mot interdit injecté dans la question
awk -v w="${W1}s" '{ if (index($0,"Plusieurs personnes ou agents")>0) sub(/Plusieurs personnes/, "Plusieurs " w); print }' "$SKILL" > "$TMP/d1.md"
disc D1 "mot interdit injecté dans la question => rc 1" 1 "$TMP/d1.md"

# D2 : mot interdit injecté dans description:
awk -v w="$W2" '{ if ($0 ~ /^description:/) sub(/Utiliser quand/, "Utiliser quand " w); print }' "$SKILL" > "$TMP/d2.md"
disc D2 "mot interdit injecté dans description: => rc 1" 1 "$TMP/d2.md"

# D3 : hors « », dans un bloc de code (identifiant à saisir) — la sonde du fichier ENTIER le voit (P412-D-06)
{ cat "$SKILL"; printf '\n```sh\nexport GSD_%s=mon-sujet\n```\n' "$(printf '%s' "$W1" | tr 'a-z' 'A-Z')"; } > "$TMP/d3.md"
disc D3 "mot interdit dans un bloc de code, hors « » => rc 1 (pas d'exemption)" 1 "$TMP/d3.md"

# D4 : fichier sans aucun span => rc 2, jamais un vert à vide
LC_ALL=C sed 's/\xc2\xab//g; s/\xc2\xbb//g' "$SKILL" > "$TMP/d4.md"
disc D4 "fichier sans aucun span => rc 2" 2 "$TMP/d4.md"

# D5 : mot interdit en prose libre (ni span, ni code) => rc 1
{ cat "$SKILL"; printf '\nNote interne : le %s du moteur.\n' "$W2"; } > "$TMP/d5.md"
ok_d5=$(verdict "$TMP/d5.md")
ok D5 "mot interdit en prose, hors « » => rc 1" "$([ "$ok_d5" = 1 ] && echo true || echo false)" "attendu rc 1, obtenu rc $ok_d5"

echo "== sonde : $DOK/4 discriminations prouvées =="

# __BILAN__
echo "== bilan : $((PASS+FAIL)) cas, $FAIL échec(s) =="
[ "$FAIL" -eq 0 ] && [ "$DOK" -eq 4 ]
