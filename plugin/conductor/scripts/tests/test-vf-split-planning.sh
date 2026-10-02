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
# Cas : T1-T12 (skill + commande), D1-D5 (la sonde discrimine), R1-R4 (renvois), M1-M2 (manuel),
#       P1-P5 (ordre des étapes, refus relayés, confirmation de bascule, nom) et D6-D9 (leurs mutants).
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

# --- R1-R4 : les renvois (un seul exécutant, deux points d'entrée y renvoient sans poser la question) ---
echo "  -- renvois et manuel --"
W3="compart""ment"
lignes_ws() { # <fichier> : les SEULES lignes portant vf-split-planning (vf-new-lab emploie légitimement l'autre sens du mot)
  grep -F "vf-split-planning" "$1" 2>/dev/null
}
mots_interdits() { # lit stdin ; rc 0 si AUCUN mot interdit (français et anglais)
  ! LC_ALL=C awk -v a="$W1" -v b="$W2" -v c="$W3" '{ l=tolower($0); if (index(l,a)||index(l,b)||index(l,c)) f=1 } END{ exit f?0:1 }'
}
ln_of() { grep -nF -- "$1" "$2" 2>/dev/null | head -1 | cut -d: -f1; }

l3=$(ln_of "3. **Socle planning**" "$NEWLAB"); lr=$(ln_of "vf-split-planning" "$NEWLAB"); ll=$(ln_of "**Lab à compartiments**" "$NEWLAB")
r1=false
[ -n "$l3" ] && [ -n "$lr" ] && [ -n "$ll" ] && [ "$l3" -lt "$lr" ] && [ "$lr" -lt "$ll" ] && r1=true
ok R1 "vf-new-lab : renvoi entre « 3. Socle planning » (l.${l3:-?}) et « Lab à compartiments » (l.${ll:-?}), trouvé l.${lr:-?}" "$r1" \
  "attendu $l3 < renvoi < $ll, obtenu ${lr:-absent}"

nl=$(lignes_ws "$NEWLAB" | wc -l | tr -d ' ')
bloc=$(grep -B1 -F "vf-split-planning" "$NEWLAB")  # le renvoi tient sur deux lignes : la précédente et celle qui nomme le skill
r2=true
[ "$nl" -ge 1 ] || r2=false
printf '%s\n' "$bloc" | grep -qF "BOOT-04" || r2=false
printf '%s\n' "$bloc" | grep -qF "terminé" || r2=false
printf '%s\n' "$bloc" | grep -qF "ne la pose pas" || r2=false
printf '%s\n' "$bloc" | mots_interdits || r2=false
ok R2 "vf-new-lab : $nl ligne(s) de renvoi — après gsd-new-project terminé (BOOT-04), la question n'est pas posée ici, aucun mot interdit" "$r2"

r3=true
grep -F "démarrer un projet" "$ROUTING" | grep -qF "vf-split-planning" || r3=false
grep -F "onboarde ce codebase" "$ROUTING" | grep -qF "vf-split-planning" || r3=false
grep -F "on sera plusieurs" "$ROUTING" | grep -qF "vf-split-planning" || r3=false
ok R3 "intent-routing : lignes « démarrer un projet », « onboarde ce codebase » et « on sera plusieurs » renvoient au skill" "$r3"

nr=$(lignes_ws "$ROUTING" | wc -l | tr -d ' ')
r4=true
[ "$nr" -ge 3 ] || r4=false
lignes_ws "$ROUTING" | mots_interdits || r4=false
ok R4 "intent-routing : $nr ligne(s) de renvoi (>= 3), aucun mot interdit" "$r4" "attendu >= 3 lignes sans mot interdit, obtenu $nr"

# --- M1/M2 : le manuel cesse d'affirmer une liste close fausse -------------------------------------
section() { # <fichier> : la section « ### `/vf-split-planning` » jusqu'au titre suivant
  awk '/^### `\/vf-split-planning`/{on=1; print; next} on && /^##/{exit} on{print}' "$1" 2>/dev/null
}
m1=true
grep -qx '## Les huit commandes' "$MAN_FR" || m1=false
grep -q '^## Les sept commandes' "$MAN_FR" && m1=false
grep -qx '### `/vf-split-planning`' "$MAN_FR" || m1=false
[ -n "$(section "$MAN_FR")" ] && section "$MAN_FR" | mots_interdits || m1=false
ok M1 "manuel FR : « Les huit commandes », section /vf-split-planning sans mot interdit" "$m1"
m2=true
grep -qx '## The eight commands' "$MAN_EN" || m2=false
grep -q '^## The seven commands' "$MAN_EN" && m2=false
grep -qx '### `/vf-split-planning`' "$MAN_EN" || m2=false
[ -n "$(section "$MAN_EN")" ] && section "$MAN_EN" | mots_interdits || m2=false
ok M2 "manuel EN : « The eight commands », section /vf-split-planning sans mot interdit" "$m2"

# --- P1-P5 : la STRUCTURE du skill (WSCH-03 côté skill, P412-D-08), D6-D9 : elle rougit sur ses mutants --------
# Propriété : la précondition est appelée AVANT toute création, chacun de ses refus (et de ceux du geste) est relayé en
# langage d'usage par une puce dédiée, la bascule d'un lab démarré se confirme AVANT l'appel au geste, le nom suit
# la même règle dans les deux modes. Une fonction, jouée sur le vrai skill puis sur des copies mutées.
echo "  -- structure du skill (étapes, refus relayés, confirmation) --"
sec() { # <fichier> <préfixe de titre « ### N. »> : le corps de l'étape, jusqu'au titre suivant
  awk -v p="$2" 'index($0,p)==1{on=1; next} on && /^### /{exit} on{print}' "$1"
}
lnum() { grep -nF -- "$1" "$2" 2>/dev/null | head -1 | cut -d: -f1; }
structure() { # <fichier> -> rc 0 conforme ; STRUCT_BAD = les écarts
  local f="$1" bad="" n prev=0 s1 s4 s6 l_pre l_geste l_conf
  for n in 1 2 3 4 5 6 7 8; do
    l="$(grep -n "^### $n\. " "$f" | head -1 | cut -d: -f1)"
    if [ -z "$l" ]; then bad="$bad étape-$n-absente"; elif [ "$l" -le "$prev" ]; then bad="$bad étape-$n-hors-ordre"; else prev="$l"; fi
  done
  s1="$(sec "$f" "### 1. ")"; s4="$(sec "$f" "### 4. ")"; s6="$(sec "$f" "### 6. ")"
  l_pre="$(lnum "bash .claude/scripts/check-planning-not-inflight.sh" "$f")"; l_geste="$(lnum "bash .claude/scripts/split-planning.sh" "$f")"
  { [ -n "$l_pre" ] && [ -n "$l_geste" ] && [ "$l_pre" -lt "$l_geste" ]; } || bad="$bad précondition-pas-avant-le-geste"
  # étape 1 : une puce par code, chacune avec son message dit
  printf '%s\n' "$s1" | grep -F -- "- rc 1" | grep -qF "Une phase est en cours dans ce lab" || bad="$bad précondition:rc1-non-relayé"
  printf '%s\n' "$s1" | grep -F -- "- rc 2" | grep -qF "Je n'ai pas pu vérifier qu'aucune phase n'est en cours" || bad="$bad précondition:rc2-non-relayé"
  printf '%s\n' "$s1" | grep -F -- "- tout autre code" | grep -qF "Je n'ai pas pu vérifier" || bad="$bad précondition:autre-code-non-relayé"
  # étape 6 : les refus du geste, un message dit par code, y compris un code non prévu
  printf '%s\n' "$s6" | grep -F -- "- rc 1" | grep -qF "Je n'ai rien changé" || bad="$bad geste:rc1-non-relayé"
  printf '%s\n' "$s6" | grep -F -- "- rc 2" | grep -qF "Je n'ai pas pu terminer proprement" || bad="$bad geste:rc2-non-relayé"
  printf '%s\n' "$s6" | grep -F -- "- rc 64" | grep -qF "Ce nom de sujet n'est pas accepté" || bad="$bad geste:rc64-non-relayé"
  printf '%s\n' "$s6" | grep -F -- "- tout autre code" | grep -qF "Je n'ai pas pu terminer proprement" || bad="$bad geste:autre-code-non-relayé"
  # étape 4 : confirmation de bascule d'un lab démarré, AVANT le geste ; le nom, même règle dans les deux modes
  l_conf="$(lnum "sera rangé dans le sujet" "$f")"
  { [ -n "$l_conf" ] && [ -n "$l_geste" ] && [ "$l_conf" -lt "$l_geste" ]; } || bad="$bad confirmation-absente-ou-après-le-geste"
  printf '%s\n' "$s4" | grep -qF "AVANT tout appel au geste" || bad="$bad confirmation:pas-avant-tout-appel"
  printf '%s\n' "$s4" | grep -qF "RIEN n'est fait" || bad="$bad confirmation:refus-non-traité"
  printf '%s\n' "$s4" | grep -qF "pas de seconde question" || bad="$bad confirmation:lab-neuf-non-distingué"
  printf '%s\n' "$s4" | grep -qF "dans les deux modes" || bad="$bad nom:règle-non-unique"
  printf '%s\n' "$s4" | grep -qF "l'emporte toujours" || bad="$bad nom:argument-non-prioritaire"
  STRUCT_BAD="$bad"; [ -z "$bad" ]
}
clean() { local p; for p in "$@"; do case "$STRUCT_BAD" in *"$p"*) echo false; return ;; esac; done; echo true; }
structure "$SKILL"; sr=$?
ok P1 "étapes 1 à 8 présentes dans l'ordre ; précondition appelée avant le geste" \
  "$(clean étape- précondition-pas)" "$STRUCT_BAD"
ok P2 "étape 1 : une puce dédiée, avec son message dit, pour rc 1, rc 2 et tout autre code" \
  "$(clean précondition:)" "$STRUCT_BAD"
ok P3 "étape 6 : une puce dédiée, avec son message dit, pour rc 1, rc 2, rc 64 et tout autre code" \
  "$(clean geste:)" "$STRUCT_BAD"
ok P4 "étape 4 : confirmation « sera rangé dans le sujet » avant le geste, refus = rien fait, lab neuf sans seconde question" \
  "$(clean confirmation)" "$STRUCT_BAD"
ok P5 "étape 4 : le nom passé en argument l'emporte, même règle dans les deux modes (aligné sur le manuel)" \
  "$(clean nom:)" "$STRUCT_BAD"
[ $sr -eq 0 ] || echo "      (structure du vrai skill : $STRUCT_BAD)"

# Mutants du skill (copies jetables) : chacun doit faire rougir `structure`.
strip_bullet() { # <fichier> <début de puce> <sortie> : retire la puce et ses lignes de suite (indentées)
  awk -v b="$2" 'index($0,b)==1{skip=1; next} skip && /^  [^ ]/{next} {skip=0; print}' "$1" > "$3"
}
dmut() { # <ID> <description> <fichier muté> <fragment attendu dans STRUCT_BAD>
  if cmp -s "$3" "$SKILL"; then ok "$1" "$2" false "mutant NON OPPOSABLE (identique au skill)"; return; fi
  structure "$3"; local r=$?
  if [ $r -ne 0 ] && printf '%s' "$STRUCT_BAD" | grep -qF -- "$4"; then DOK=$((DOK+1)); ok "$1" "$2" true
  else ok "$1" "$2" false "attendu un rouge contenant [$4], obtenu rc $r [$STRUCT_BAD]"; fi
  echo "      trace $1 : assertion=${4} ; attendu=rouge ; obtenu=$([ $r -ne 0 ] && echo "rouge [$STRUCT_BAD]" || echo vert)"
}
# D6 : la ligne « rc 2 » de la précondition supprimée
awk '/^### 1\. /{on=1} /^### 2\. /{on=0} on && index($0,"- rc 2")==1{skip=1; next} skip && /^  [^ ]/{next} {skip=0; print}' "$SKILL" > "$TMP/d6.md"
dmut D6 "ligne « rc 2 » de la précondition supprimée => rouge" "$TMP/d6.md" "précondition:rc2-non-relayé"
# D7 : « 5. Le geste » placée AVANT « 1. Précondition »
awk '/^### /{cur=$2+0} {b[cur]=b[cur] $0 "\n"} END{printf "%s%s", b[0], b[5]; for(i=1;i<=8;i++) if(i!=5) printf "%s", b[i]}' "$SKILL" > "$TMP/d7.md"
dmut D7 "étape « Le geste » placée avant « Précondition » => rouge" "$TMP/d7.md" "précondition-pas-avant-le-geste"
# D8 : toutes les puces « rc 1 » et « rc 2 » supprimées (précondition ET geste)
strip_bullet "$SKILL" "- rc 1" "$TMP/d8a.md"; strip_bullet "$TMP/d8a.md" "- rc 2" "$TMP/d8.md"
dmut D8 "puces « rc 1 » et « rc 2 » supprimées => rouge" "$TMP/d8.md" "rc1-non-relayé"
# D9 : confirmation de bascule (P412-D-08) supprimée
awk 'index($0,"sera rangé dans le sujet")>0{next} {print}' "$SKILL" > "$TMP/d9.md"
dmut D9 "confirmation « sera rangé dans le sujet » supprimée => rouge" "$TMP/d9.md" "confirmation-absente-ou-après-le-geste"
echo "== structure : $DOK/8 mutants de la sonde et du skill prouvés =="

# __BILAN__
echo "== bilan : $((PASS+FAIL)) cas, $FAIL échec(s) =="
[ "$FAIL" -eq 0 ] && [ "$DOK" -eq 8 ]
