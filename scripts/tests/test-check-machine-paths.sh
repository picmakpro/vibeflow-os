#!/usr/bin/env bash
# test-check-machine-paths.sh — Suite de vérification de scripts/check-machine-paths.sh
# (Phase 24, mandat de correction ciblée du 2026-08-05).
#
# CE QUE CETTE SUITE PROUVE, ET POURQUOI ELLE EST BÂTIE AINSI.
#
# Le gate testé a trois organes, et un vert d'ensemble ne dit RIEN sur celui des trois qui l'a
# produit. Une suite qui n'exercerait que « dépôt propre → 0 / dépôt sale → 1 » resterait verte si
# l'échappatoire cessait d'être lue, si l'allowlist de placeholders devenait un décor, ou si la
# détection s'éteignait pendant qu'un autre chemin rendait 1. La discriminance est donc prouvée
# organe par organe, PAR MUTATION, et dans les deux sens :
#   - MUT1 : la détection neutralisée → le dépôt SALE doit devenir vert ;
#   - MUT2 : l'échappatoire non lue → le dépôt marqué (vert) doit devenir ROUGE ;
#   - MUT3 : l'allowlist vidée → le dépôt placeholder (vert) doit devenir ROUGE.
# Sans MUT2 et MUT3, les deux échappatoires seraient des verts à vide : elles laisseraient passer
# parce que rien ne les regarde, et la suite ne saurait pas faire la différence.
#
# LES LITTÉRAUX FAUTIFS SONT CONSTRUITS À L'EXÉCUTION (`"$U/alice/…"`, jamais `/Users/alice/…`
# écrit tel quel). Ce n'est pas une coquetterie : cette suite est elle-même un fichier VERSIONNÉ,
# donc dans l'univers que le gate balaie. Y écrire un chemin de machine en clair ferait rougir le
# gate sur sa propre suite — la contorsion serait alors d'ajouter une exception pour elle, c'est-à-dire
# de commencer à trouer le gate par son test. La concaténation évite l'exception.
#
# Toutes les fixtures sont des dépôts git JETABLES sous `mktemp -d`, nettoyés par `trap`. Aucune
# n'est ancrée sur l'arbre réel : celui-ci bougera. Le seul cas ancré dessus est un contrôle final,
# explicitement NON discriminant, placé APRÈS les mutations et jamais à leur place.
#
# Règle héritée de `test-check-capability-activation.sh` : une mutation doit avoir CHANGÉ le
# fichier, constaté par `cmp` et JAMAIS par `diff` (le `diff` de certains postes est proxifié et
# ment). Un motif de mutation introuvable rend le mutant NON OPPOSABLE — un échec, jamais un
# succès silencieux.

set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-machine-paths.sh"

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1 — $2"; FAIL=$((FAIL+1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Le préfixe fautif, assemblé à l'exécution — voir l'en-tête.
U="/Users"
H="/home"
HATCH="vf-allow-machine-path"

# --- Fabrique de dépôts jetables ----------------------------------------------------------------
mk_repo() { # <nom> — crée un dépôt git vide, imprime son chemin
  local d="$TMP/$1"
  mkdir -p "$d"
  git init -q "$d" >/dev/null 2>&1
  printf '%s\n' "$d"
}
track() { # <repo> — indexe tout ; `git add` n'exige aucune identité, donc pas de commit à faire
  git -C "$1" add -A >/dev/null 2>&1
}
rc_of() { # <repo> [args…]
  bash "$SCRIPT" --path "$1" >/dev/null 2>&1
  echo $?
}
out_of() { # <repo>
  bash "$SCRIPT" --path "$1" 2>&1
}

echo "== check-machine-paths — cas nominaux =="

# --- T1 : dépôt propre → 0 ----------------------------------------------------------------------
D="$(mk_repo t1)"
printf 'voir .planning/ROADMAP.md et plugin/conductor/scripts/\n' > "$D/doc.md"
track "$D"
rc="$(rc_of "$D")"
[ "$rc" -eq 0 ] && ok "T1 dépôt propre → 0" || ko "T1 dépôt propre → 0" "rc=$rc"

# --- T2 : chemin de machine versionné → 1, avec fichier ET ligne nommés --------------------------
# Le cas DISCRIMINANT de référence : c'est lui que MUT1 devra faire virer au vert.
D="$(mk_repo t2)"
printf 'ligne anodine\nbase : %s/alice/dev/projet/.planning\n' "$U" > "$D/etude.md"
track "$D"
rc="$(rc_of "$D")"; out="$(out_of "$D")"
n2=0; case "$out" in *"etude.md:2"*) n2=1 ;; esac
n2b=0; case "$out" in *"alice"*) n2b=1 ;; esac
if [ "$rc" -eq 1 ] && [ "$n2" -eq 1 ] && [ "$n2b" -eq 1 ]; then
  ok "T2 chemin de machine → 1, fichier:ligne et segment nommés"
else
  ko "T2 chemin de machine → 1" "rc=$rc fichier:ligne=$n2 segment=$n2b"
fi

# --- T3 : segment placeholder `dev` → 0 ---------------------------------------------------------
# Cas RÉEL du dépôt : plugin/_internal/tests/fixtures/gsd-core-settings.json cite `/Users/dev/…`,
# une fixture amont anonymisée. La faire rougir désarmerait le gate dès sa pose.
D="$(mk_repo t3)"
printf 'commande: bash %s/dev/.claude/gsd-core/hooks/gsd-session-state.sh\n' "$U" > "$D/fixture.json"
track "$D"
rc="$(rc_of "$D")"
[ "$rc" -eq 0 ] && ok "T3 placeholder « dev » → 0" || ko "T3 placeholder « dev » → 0" "rc=$rc"

# --- T4 : `/home/runner` (GitHub Actions) → 0 ---------------------------------------------------
D="$(mk_repo t4)"
printf 'workspace CI : %s/runner/work/vibeflow-os/vibeflow-os\n' "$H" > "$D/ci.md"
track "$D"
rc="$(rc_of "$D")"
[ "$rc" -eq 0 ] && ok "T4 placeholder « runner » (/home) → 0" || ko "T4 placeholder « runner » → 0" "rc=$rc"

# --- T5 : segment non identifiant (`<user>`, `…`) → 0 -------------------------------------------
# Forme recommandée en documentation utilisateur : elle dit « un compte quelconque » et ne matche
# pas la classe de caractères. C'est l'échappatoire n°2, celle qui ne coûte aucun marqueur.
D="$(mk_repo t5)"
printf 'installer sous %s/<user>/.claude/ ou %s/…/.claude/\n' "$U" "$U" > "$D/manuel.md"
track "$D"
rc="$(rc_of "$D")"
[ "$rc" -eq 0 ] && ok "T5 segment non identifiant (<user>, …) → 0" || ko "T5 segment non identifiant → 0" "rc=$rc"

# --- T6 : `/home` au MILIEU d'un chemin composé → 0 (non-régression) ----------------------------
# Faux positif MESURÉ au premier run du gate sur l'arbre réel : `$WORK/home/.claude/...` (fixture du
# plan 04-02) est un sous-dossier nommé `home`, pas le `/home` du système. 3 occurrences. Ce cas
# garde le correctif : sans lui, le gate rougirait sur des chemins qui ne désignent aucune machine.
D="$(mk_repo t6)"
printf 'marqueur absent : $WORK%s/.claude/scripts/.vibeflow-installed\n' "$H" > "$D/plan.md"
printf 'relatif aussi : fixtures%s/dupont/x\n' "$U" >> "$D/plan.md"
track "$D"
rc="$(rc_of "$D")"
[ "$rc" -eq 0 ] && ok "T6 /home et /Users au milieu d'un chemin composé → 0" || ko "T6 chemin composé → 0" "rc=$rc"

# --- T7 : échappatoire explicite → 0 ------------------------------------------------------------
# Le cas que MUT2 devra faire virer au ROUGE.
D="$(mk_repo t7)"
printf 'sortie citee : %s/bob/dev/x  %s\n' "$U" "$HATCH" > "$D/transcript.md"
track "$D"
rc="$(rc_of "$D")"
[ "$rc" -eq 0 ] && ok "T7 marqueur d'échappatoire → 0" || ko "T7 marqueur d'échappatoire → 0" "rc=$rc"

# --- T8 : l'échappatoire ne vaut QUE pour sa ligne ----------------------------------------------
# Une échappatoire de portée fichier serait une porte : un marqueur posé une fois amnistierait tout
# ce qui est écrit ensuite. Deux lignes fautives, UNE seule marquée → il doit rester exactement une
# occurrence signalée, et elle doit désigner la ligne 2.
D="$(mk_repo t8)"
printf 'amnistiee : %s/bob/x  %s\n%s/carol/y\n' "$U" "$HATCH" "$U" > "$D/mixte.md"
track "$D"
rc="$(rc_of "$D")"; out="$(out_of "$D")"
nb="$(printf '%s\n' "$out" | awk 'index($0,"segment de compte")>0 { n++ } END { print n+0 }')"
seg=0; case "$out" in *"carol"*) seg=1 ;; esac
amn=0; case "$out" in *"bob"*) amn=1 ;; esac
if [ "$rc" -eq 1 ] && [ "$nb" -eq 1 ] && [ "$seg" -eq 1 ] && [ "$amn" -eq 0 ]; then
  ok "T8 l'échappatoire est de portée LIGNE, pas fichier (1 occurrence, la bonne)"
else
  ko "T8 échappatoire de portée ligne" "rc=$rc occurrences=$nb carol=$seg bob_amnistie=$amn"
fi

# --- T9 : un fichier NON SUIVI ne compte pas ----------------------------------------------------
# Le défaut visé est de VERSIONNER un chemin de machine. Un brouillon local n'est pas publié — le
# gate n'a pas à le juger, sinon il devient un bruit qu'on apprend à ignorer.
D="$(mk_repo t9)"
printf 'suivi et propre\n' > "$D/suivi.md"
track "$D"
printf 'brouillon : %s/dave/secret\n' "$U" > "$D/non-suivi.md"
rc="$(rc_of "$D")"
[ "$rc" -eq 0 ] && ok "T9 fichier non suivi ignoré → 0" || ko "T9 fichier non suivi ignoré → 0" "rc=$rc"

# --- T10 : pas un dépôt git → 2 (NON VÉRIFIABLE, jamais un vert) --------------------------------
D="$TMP/t10"; mkdir -p "$D"
printf 'x\n' > "$D/f.md"
rc="$(rc_of "$D")"
[ "$rc" -eq 2 ] && ok "T10 hors dépôt git → 2 (non vérifiable)" || ko "T10 hors dépôt git → 2" "rc=$rc"

# --- T11 : dépôt git SANS fichier suivi → 2 -----------------------------------------------------
# Le cas « vert à vide » que ce dépôt a déjà payé plusieurs fois : une cible vide qui rend 0
# ressemble à s'y méprendre à un succès. Elle doit rendre 2.
D="$(mk_repo t11)"
rc="$(rc_of "$D")"
[ "$rc" -eq 2 ] && ok "T11 univers vide → 2 (jamais un vert)" || ko "T11 univers vide → 2" "rc=$rc"

# --- T12 : contrat d'usage ----------------------------------------------------------------------
bash "$SCRIPT" --path "$TMP/inexistant-$$" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && ok "T12a racine inexistante → 2" || ko "T12a racine inexistante → 2" "rc=$rc"
bash "$SCRIPT" --inconnu >/dev/null 2>&1; rc=$?
[ "$rc" -eq 64 ] && ok "T12b argument inconnu → 64" || ko "T12b argument inconnu → 64" "rc=$rc"
bash "$SCRIPT" --help >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && ok "T12c --help → 0" || ko "T12c --help → 0" "rc=$rc"

# --- T13 : le compteur d'univers est RÉEL -------------------------------------------------------
# Un compteur anti-vert-à-vide qui se trompe est pire qu'absent : il donne l'illusion du contrôle.
# Celui-ci s'est trompé d'un facteur 800 au premier jet (`awk -v RS="\0"` ne découpe pas sur NUL
# côté macOS : 1 rendu pour 868 fichiers). Le cas le tient : 3 fichiers suivis → « 3 ».
D="$(mk_repo t13)"
printf 'a\n' > "$D/a.md"; printf 'b\n' > "$D/b.md"; printf 'c\n' > "$D/c.md"
track "$D"
out="$(out_of "$D")"
n13=0; case "$out" in *"3 fichier(s)"*) n13=1 ;; esac
[ "$n13" -eq 1 ] && ok "T13 compteur d'univers exact (3 fichiers suivis)" || ko "T13 compteur d'univers" "sortie=$out"

# ================================================================================================
# == MUTATIONS — le gate sait-il rougir, et chacun de ses trois organes est-il vraiment lu ?
# ================================================================================================
echo ""
echo "== mutations =="

mutate() { # <src> <dst> <programme awk> — 0 si le mutant a été déposé, 1 sinon (cible INTACTE)
  local tmp="$2.mut.$$"
  # La cible n'est JAMAIS tronquée avant que le programme ait réussi : `awk … > cible` viderait la
  # cible d'abord, et un awk en échec laisserait un fichier VIDE que `cmp -s` déclarerait « changé ».
  if ! awk "$3" "$1" > "$tmp" 2>/dev/null; then rm -f "$tmp"; return 1; fi
  if [ ! -s "$tmp" ]; then rm -f "$tmp"; return 1; fi
  mv "$tmp" "$2"
  return 0
}

MUT="$TMP/mutant.sh"

# --- MUT1 : la DÉTECTION neutralisée → le dépôt SALE (T2) doit devenir VERT ---------------------
D="$(mk_repo m1)"
printf 'base : %s/alice/dev/projet\n' "$U" > "$D/etude.md"
track "$D"
cp "$SCRIPT" "$TMP/m1.orig"
if ! mutate "$TMP/m1.orig" "$MUT" '{ sub(/\(Users\|home\)/, "(ZZZNOMATCHZZZ)"); print }'; then
  ko "MUT1 détection" "le programme de mutation a ÉCHOUÉ — mutant NON CONSTRUIT"
elif cmp -s "$MUT" "$TMP/m1.orig"; then
  ko "MUT1 détection" "la mutation n'a RIEN changé (motif introuvable) — mutant NON OPPOSABLE"
else
  bash "$MUT" --path "$D" >/dev/null 2>&1; rc_mut=$?
  bash "$TMP/m1.orig" --path "$D" >/dev/null 2>&1; rc_back=$?
  if [ "$rc_mut" -eq 0 ] && [ "$rc_back" -eq 1 ]; then
    ok "MUT1 détection neutralisée → vert (0) ; original restauré → rouge (1). Le rouge vient bien de la détection."
  else
    ko "MUT1 détection" "mutant rc=$rc_mut (attendu 0), original rc=$rc_back (attendu 1)"
  fi
fi

# --- MUT2 : l'ÉCHAPPATOIRE non lue → le dépôt marqué (T7) doit devenir ROUGE --------------------
# Sans ce cas, un marqueur qui ne serait plus consulté laisserait T7 vert par la seule vertu du
# reste : l'échappatoire deviendrait une promesse de documentation, pas un mécanisme.
D="$(mk_repo m2)"
printf 'sortie citee : %s/bob/dev/x  %s\n' "$U" "$HATCH" > "$D/transcript.md"
track "$D"
cp "$SCRIPT" "$TMP/m2.orig"
if ! mutate "$TMP/m2.orig" "$MUT" 'index($0, "index($0, HATCH) > 0") > 0 { next } { print }'; then
  ko "MUT2 échappatoire" "le programme de mutation a ÉCHOUÉ — mutant NON CONSTRUIT"
elif cmp -s "$MUT" "$TMP/m2.orig"; then
  ko "MUT2 échappatoire" "la mutation n'a RIEN changé (motif introuvable) — mutant NON OPPOSABLE"
else
  bash "$MUT" --path "$D" >/dev/null 2>&1; rc_mut=$?
  bash "$TMP/m2.orig" --path "$D" >/dev/null 2>&1; rc_back=$?
  if [ "$rc_mut" -eq 1 ] && [ "$rc_back" -eq 0 ]; then
    ok "MUT2 échappatoire retirée → rouge (1) ; original restauré → vert (0). Le marqueur est réellement consulté."
  else
    ko "MUT2 échappatoire" "mutant rc=$rc_mut (attendu 1), original rc=$rc_back (attendu 0)"
  fi
fi

# --- MUT3 : l'ALLOWLIST vidée → le dépôt placeholder (T3) doit devenir ROUGE --------------------
D="$(mk_repo m3)"
printf 'commande: bash %s/dev/.claude/gsd-core/hooks/gsd-session-state.sh\n' "$U" > "$D/fixture.json"
track "$D"
cp "$SCRIPT" "$TMP/m3.orig"
if ! mutate "$TMP/m3.orig" "$MUT" '/^ALLOW=/ { print "ALLOW=\"\""; next } { print }'; then
  ko "MUT3 allowlist" "le programme de mutation a ÉCHOUÉ — mutant NON CONSTRUIT"
elif cmp -s "$MUT" "$TMP/m3.orig"; then
  ko "MUT3 allowlist" "la mutation n'a RIEN changé (motif introuvable) — mutant NON OPPOSABLE"
else
  bash "$MUT" --path "$D" >/dev/null 2>&1; rc_mut=$?
  bash "$TMP/m3.orig" --path "$D" >/dev/null 2>&1; rc_back=$?
  if [ "$rc_mut" -eq 1 ] && [ "$rc_back" -eq 0 ]; then
    ok "MUT3 allowlist vidée → rouge (1) ; original restauré → vert (0). L'énumération de placeholders est réellement lue."
  else
    ko "MUT3 allowlist" "mutant rc=$rc_mut (attendu 1), original rc=$rc_back (attendu 0)"
  fi
fi

# ================================================================================================
# == CONTRÔLE FINAL sur l'arbre RÉEL — explicitement NON discriminant.
# ================================================================================================
# Placé APRÈS les mutations, et jamais à leur place : il constate l'état du dépôt le jour où la
# suite tourne. S'il rougit un jour, c'est un chemin de machine réellement versionné — pas un défaut
# du gate.
echo ""
echo "== contrôle final (arbre réel, non discriminant) =="
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
bash "$SCRIPT" --path "$REPO_ROOT" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && ok "arbre réel propre (0)" || ko "arbre réel" "rc=$rc — un chemin de machine est versionné, voir la sortie du gate"

echo ""
echo "== bilan : $PASS OK / $FAIL KO =="
[ "$FAIL" -eq 0 ]
