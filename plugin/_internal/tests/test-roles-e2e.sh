#!/usr/bin/env bash
# test-roles-e2e.sh — Preuves de bout en bout des postes (Phase 58, plan 58-09, RLPO-11).
#
# CRITÈRES COUVERTS (P58-D-19) :
#   critère 1 — un lab NEUF posé en poste `product` n'expose aucune commande dev
#               (E2E-C1, -ARTEFACTS, -TEMOIN, -DEPS, -CATALOGUE, -SESSION) ;
#   critère 2 — une install SANS poste est identique à celle d'avant la phase :
#               invariants permanents (E2E-C2-INV, E2E-C2-TEMOIN) et comparaison des deux engines,
#               ancien (git archive de la base) contre nouveau, sur le MÊME cache de modules
#               (E2E-C2-AB, E2E-C2-AB-TEMOIN, ARMÉS) ;
#   critère 5 — aucun fichier d'agent au-delà de 250 lignes (E2E-C5) ;
#   présences doctrinales — ADR-077 et l'entrée de glossaire, une seule fois (E2E-ADR, E2E-GLOSS) ;
#   E2E-HOME — le vrai ~/.claude n'est jamais touché.
#
# ARMEMENT : les preuves qui dépendent de la BASE de la branche (E2E-C2-AB et son témoin) ne tournent
# que sous VF_ROLE_E2E_LIVRAISON=1 : sinon une ligne `⊘ SKIP E2E-C2-AB` est imprimée, pour ne jamais
# rougir plus tard sur une branche qui modifierait légitimement ces fichiers. La base est lue dans
# VF_ROLE_E2E_BASE, sinon `git merge-base HEAD origin/main` ; objet illisible -> SKIP nommé, jamais un vert.
# Armée, un SKIP de ces deux cas est un ÉCHEC (une preuve armée qui ne regarde pas ne rend pas vert).
#
# CRAN DE MUTATION : VF_ROLE_E2E_INTERNAL=<dossier _internal> remplace l'engine « nouveau » par une copie
# (mutant) ; le cache de modules reste celui du dépôt. Jamais posé en CI.
#
# DURÉE : non armée ~40 s (deux `install --all`), armée ~65 s (trois). Chaque install est bornée par
# l'appelant (perl -e 'alarm N; exec @ARGV').
#
# ISOLATION : HOME jetable par lab, PYTHONUSERBASE conservé, chaque lab `mktemp -d` + `git init -q`,
# empreinte du vrai ~/.claude avant/après. Comparaisons par fichiers temporaires et `cmp -s`, comptages
# par awk, jamais `diff`.
# Convention : ok()/ko()/skip(), exit 0 si tout passe, exit 1 au moindre KO.

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
INTERNAL_DIR="$(cd "$TESTS_DIR/.." && pwd)"
PLUGIN="$(cd "$INTERNAL_DIR/.." && pwd)"
DEPOT="$(cd "$PLUGIN/.." && pwd)"
NEW_INTERNAL="${VF_ROLE_E2E_INTERNAL:-$INTERNAL_DIR}"
ENG_NEW="$NEW_INTERNAL/vibeflow-update.sh"

pass=0; fail=0; skipped=0
ok()   { echo "  ✓ $1"; pass=$((pass+1)); }
ko()   { echo "  ✗ $1"; fail=$((fail+1)); }
skip() { echo "  ⊘ SKIP $1"; skipped=$((skipped+1)); }

GREP="$(command -v grep)"

# PYTHONUSERBASE exporté AVANT tout changement de HOME : un site-packages utilisateur ne migre pas avec lui.
PYTHONUSERBASE="${PYTHONUSERBASE:-$(python3 -m site --user-base 2>/dev/null || echo "$HOME/.local")}"; export PYTHONUSERBASE

echo "== test-roles-e2e (engine: $ENG_NEW) =="

# Empreinte du vrai ~/.claude (sous-chemins que l'engine sait écrire) avant la suite.
snapshot_home_claude() {
  find "$HOME/.claude/agents" "$HOME/.claude/skills" "$HOME/.claude/scripts" \
       "$HOME/.claude/rules" "$HOME/.claude/commands" "$HOME/.claude/settings.json" \
       -type f 2>/dev/null | wc -l | tr -d ' '
}
HOME_BEFORE=$(snapshot_home_claude)

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
WORK="$(cd "$WORK" && pwd -P)"

nlines() { awk 'END { print NR }' "$1"; }
sorted() { LC_ALL=C sort -u; }

# mk_lab <nom> — pose LAB et LABHOME (git init -q).
mk_lab() {
  LAB="$WORK/$1/lab"; LABHOME="$WORK/$1/home"
  mkdir -p "$LAB" "$LABHOME" || return 1
  (cd "$LAB" && git init -q) || return 1
}

# do_install <lab> <home> <engine> <cache> <poste|-> <args...> — stdout/stderr dans $WORK/out.<nom du lab>.
do_install() {
  local lab="$1" home="$2" eng="$3" cache="$4" role="$5" rc=0 tag
  shift 5
  tag="$(basename "$(dirname "$lab")")"
  if [ "$role" = "-" ]; then
    (cd "$lab" && env -u VF_ROLE -u VF_TARGET HOME="$home" VF_RUNTIME=claude VF_SCOPE=project \
       VIBEFLOW_CACHE="$cache" "${BASH:-bash}" "$eng" "$@") > "$WORK/out.$tag" 2> "$WORK/err.$tag" || rc=$?
  else
    (cd "$lab" && env -u VF_TARGET HOME="$home" VF_ROLE="$role" VF_RUNTIME=claude VF_SCOPE=project \
       VIBEFLOW_CACHE="$cache" "${BASH:-bash}" "$eng" "$@") > "$WORK/out.$tag" 2> "$WORK/err.$tag" || rc=$?
  fi
  return "$rc"
}

# ---------------------------------------------------------------------------
# Labs : A = poste product (critère 1) ; R = sans poste, référence complète (témoin et critère 2)
# ---------------------------------------------------------------------------
mk_lab A; LA="$LAB"; HA="$LABHOME"
do_install "$LA" "$HA" "$ENG_NEW" "$PLUGIN" product install --all; RCA=$?
mk_lab R; LR="$LAB"; HR="$LABHOME"
do_install "$LR" "$HR" "$ENG_NEW" "$PLUGIN" - install --all; RCR=$?

REG_A="$LA/.claude/scripts/.vibeflow-installed"
MANIF_DIR_R="$LR/.claude/scripts"

# ---------------------------------------------------------------------------
# E2E-C1 — le registre du lab product : conductor et consolidator, aucun module dev
# ---------------------------------------------------------------------------
miss=0
[ "$RCA" -eq 0 ] || { ko "E2E-C1 pré-condition : install --all product rc=$RCA — $(tail -3 "$WORK/err.A")"; miss=1; }
[ "$RCR" -eq 0 ] || { ko "E2E-C1 pré-condition : install --all de référence rc=$RCR — $(tail -3 "$WORK/err.R")"; miss=1; }
for m in conductor consolidator; do
  "$GREP" -q "^$m=" "$REG_A" 2>/dev/null || { ko "E2E-C1 : $m absent du registre du lab product"; miss=1; }
done
for m in dev-orchestrator mobile-test mobile-test-team; do
  if "$GREP" -q "^$m=" "$REG_A" 2>/dev/null; then ko "E2E-C1 : $m inscrit au registre du lab product"; miss=1; fi
  "$GREP" -q "^$m=" "$LR/.claude/scripts/.vibeflow-installed" 2>/dev/null || { ko "E2E-C1 : $m absent du registre de référence (la vérification serait à vide)"; miss=1; }
done
[ "$(cat "$LA/.claude/vibeflow-role" 2>/dev/null)" = "product" ] || { ko "E2E-C1 : .claude/vibeflow-role ≠ product"; miss=1; }
[ "$miss" -eq 0 ] && ok "E2E-C1 (P58-D-05, P58-D-19) : lab neuf product, conductor et consolidator posés, aucun module dev au registre"

# ---------------------------------------------------------------------------
# E2E-C1-ARTEFACTS / E2E-C1-TEMOIN — D = chemins des manifestes dev de R, moins les chemins partagés
# ---------------------------------------------------------------------------
DEVALL="$WORK/dev.all"; OTHERS="$WORK/others"; DSET="$WORK/D"
: > "$DEVALL"; : > "$OTHERS"
for f in "$MANIF_DIR_R"/.vibeflow-manifest-*; do
  [ -f "$f" ] || continue
  case "$f" in
    *.vibeflow-manifest-dev-orchestrator|*.vibeflow-manifest-mobile-test|*.vibeflow-manifest-mobile-test-team) cat "$f" >> "$DEVALL" ;;
    *) cat "$f" >> "$OTHERS" ;;
  esac
done
sorted < "$DEVALL" > "$DEVALL.s"; sorted < "$OTHERS" > "$OTHERS.s"
comm -23 "$DEVALL.s" "$OTHERS.s" > "$DSET"
SHARED="$(comm -12 "$DEVALL.s" "$OTHERS.s" | awk 'END { print NR }')"
CARD_D="$(nlines "$DSET")"

# artefacts_dev_presents <lab> <fichier-D> — nombre de chemins de D présents sous <lab>/.claude/
artefacts_dev_presents() {
  local lab="$1" dfile="$2" p n=0
  while IFS= read -r p || [ -n "$p" ]; do
    [ -n "$p" ] || continue
    if [ -e "$lab/.claude/$p" ] || [ -L "$lab/.claude/$p" ]; then n=$((n+1)); fi
  done < "$dfile"
  echo "$n"
}

# Noms de scripts cités par les hooks.json des trois modules dev, moins ceux que d'autres modules citent aussi.
hook_names() { # <module>... -> noms de fichiers .sh/.mjs cités, un par ligne
  local m
  for m in "$@"; do
    [ -f "$PLUGIN/$m/hooks/hooks.json" ] && "$GREP" -o '[A-Za-z0-9_.-]*\.\(sh\|mjs\)' "$PLUGIN/$m/hooks/hooks.json"
  done | sorted
}
OTHER_MODS=""
for d in "$PLUGIN"/*/hooks/hooks.json; do
  [ -f "$d" ] || continue
  m="$(basename "$(dirname "$(dirname "$d")")")"
  case "$m" in dev-orchestrator|mobile-test|mobile-test-team) ;; *) OTHER_MODS="$OTHER_MODS $m" ;; esac
done
# shellcheck disable=SC2086
hook_names $OTHER_MODS > "$WORK/hooks.others"
hook_names dev-orchestrator mobile-test mobile-test-team > "$WORK/hooks.dev.all"
comm -23 "$WORK/hooks.dev.all" "$WORK/hooks.others" > "$WORK/hooks.dev"

# hooks_dev_dans_settings <lab> — nombre de noms de hooks dev cités dans les settings du lab
hooks_dev_dans_settings() {
  local lab="$1" n name c=0
  while IFS= read -r name || [ -n "$name" ]; do
    [ -n "$name" ] || continue
    n="$(cat "$lab/.claude/settings.json" "$lab/.claude/settings.local.json" 2>/dev/null | "$GREP" -cF -- "$name")"
    [ "$n" -eq 0 ] || c=$((c+1))
  done < "$WORK/hooks.dev"
  echo "$c"
}

miss=0
if [ "$CARD_D" -eq 0 ]; then
  ko "E2E-C1-ARTEFACTS : dérivation vide (ensemble D de 0 chemin) — la vérification serait à vide"; miss=1
else
  N_ART="$(artefacts_dev_presents "$LA" "$DSET")"
  [ "$N_ART" -eq 0 ] || { ko "E2E-C1-ARTEFACTS : $N_ART artefact(s) dev présent(s) dans le lab product"; miss=1; }
  [ "$(nlines "$WORK/hooks.dev")" -gt 0 ] || { ko "E2E-C1-ARTEFACTS : aucun nom de hook dev dérivé (dérivation vide)"; miss=1; }
  N_HK="$(hooks_dev_dans_settings "$LA")"
  [ "$N_HK" -eq 0 ] || { ko "E2E-C1-ARTEFACTS : $N_HK hook(s) dev cité(s) dans les settings du lab product"; miss=1; }
fi
[ "$miss" -eq 0 ] && ok "E2E-C1-ARTEFACTS (P58-D-05) : aucun des $CARD_D chemins dev dérivés ($SHARED partagé(s) écarté(s)), aucun hook dev dans les settings"

N_REF="$(artefacts_dev_presents "$LR" "$DSET")"
N_HK_REF="$(hooks_dev_dans_settings "$LR")"
if [ "$CARD_D" -gt 0 ] && [ "$N_REF" -gt 0 ] && [ "$N_HK_REF" -gt 0 ]; then
  ok "E2E-C1-TEMOIN (P58-D-19) : le lab de référence porte $N_REF artefact(s) dev et $N_HK_REF hook(s) dev — la vérification peut rougir"
else
  ko "E2E-C1-TEMOIN : le lab de référence ne porte pas d'artefact dev ($N_REF) ou de hook dev ($N_HK_REF) — la vérification est aveugle"
fi

# ---------------------------------------------------------------------------
# E2E-C1-DEPS — VRAI PAR CONSTRUCTION, non discriminant (revue S8)
#   Ni gsd-*, ni gsd-core, ni superpowers sous le HOME jetable. L'engine n'appelle JAMAIS
#   ensure-deps.sh : aucun mutant de l'engine ne peut rougir ce cas. Il constate un fait d'environnement
#   (le HOME jetable reste vierge de dépendances), il ne prouve pas que le poste les évite.
# ---------------------------------------------------------------------------
N_DEPS="$(find "$HA" \( -iname 'gsd-*' -o -iname 'gsd-core' -o -iname '*superpowers*' \) 2>/dev/null | awk 'END { print NR }')"
[ "$N_DEPS" -eq 0 ] && ok "E2E-C1-DEPS (P58-D-05, vrai par construction : l'engine n'appelle jamais ensure-deps.sh) : aucune dépendance gsd-* ni superpowers sous le HOME jetable du lab product" \
  || ko "E2E-C1-DEPS : $N_DEPS entrée(s) gsd-*/superpowers sous le HOME jetable"

# ---------------------------------------------------------------------------
# E2E-C1-CATALOGUE — le catalogue du poste product ne porte aucune ligne dev
# ---------------------------------------------------------------------------
CAT="$WORK/catalogue.product"; CAT_ALL="$WORK/catalogue.all"
bash "$PLUGIN/installer/scripts/build-module-catalog.sh" --role product > "$CAT" 2>/dev/null; RCC=$?
env -u VF_ROLE bash "$PLUGIN/installer/scripts/build-module-catalog.sh" > "$CAT_ALL" 2>/dev/null
miss=0
[ "$RCC" -eq 0 ] && [ "$(nlines "$CAT")" -gt 0 ] || { ko "E2E-C1-CATALOGUE : catalogue product vide ou en erreur (rc=$RCC)"; miss=1; }
for m in dev-orchestrator mobile-test mobile-test-team; do
  awk -F'\t' -v m="$m" '$1 == m { n++ } END { exit (n > 0 ? 0 : 1) }' "$CAT" && { ko "E2E-C1-CATALOGUE : $m dans le catalogue product"; miss=1; }
  awk -F'\t' -v m="$m" '$1 == m { n++ } END { exit (n > 0 ? 0 : 1) }' "$CAT_ALL" || { ko "E2E-C1-CATALOGUE : $m absent du catalogue sans poste (témoin aveugle)"; miss=1; }
done
[ "$miss" -eq 0 ] && ok "E2E-C1-CATALOGUE (P58-D-17) : aucune des trois lignes dev au catalogue product, présentes au catalogue sans poste"

# ---------------------------------------------------------------------------
# E2E-C1-SESSION — le hook installé dit le poste, le lecteur installé le rend
# ---------------------------------------------------------------------------
HOOK_OUT="$WORK/hook.A"
(cd "$LA" && CLAUDE_PROJECT_DIR="$LA" bash "$LA/.claude/scripts/check-role-consistency.sh" --hook > "$HOOK_OUT" 2>"$WORK/hook.A.err"); RCH=$?
GET_OUT="$(bash "$LA/.claude/scripts/vf-role.sh" get --path "$LA" 2>/dev/null)"; RCG=$?
printf 'Poste : product\n' > "$WORK/hook.exp"
if [ "$RCH" -eq 0 ] && cmp -s "$HOOK_OUT" "$WORK/hook.exp" && [ "$RCG" -eq 0 ] && [ "$GET_OUT" = "product" ]; then
  ok "E2E-C1-SESSION (P58-D-10, P58-D-15) : le hook installé dit « Poste : product », le lecteur installé rend product"
else
  ko "E2E-C1-SESSION : hook rc=$RCH (attendu « Poste : product »), lecteur rc=$RCG valeur « $GET_OUT »"
fi

# ---------------------------------------------------------------------------
# E2E-C2-INV — invariants permanents d'une install sans poste ; E2E-C2-TEMOIN
# ---------------------------------------------------------------------------
# invariants_sans_poste <lab> — nombre d'assertions violées (détail sur $WORK/inv.detail)
invariants_sans_poste() {
  local lab="$1" v=0 e r
  : > "$WORK/inv.detail"
  [ ! -e "$lab/.claude/vibeflow-role" ] || { v=$((v+1)); echo "fichier de poste présent" >> "$WORK/inv.detail"; }
  [ ! -e "$lab/.gitignore" ] || { v=$((v+1)); echo ".gitignore présent (scope project)" >> "$WORK/inv.detail"; }
  if [ -f "$lab/.worktreeinclude" ]; then
    [ "$(nlines "$lab/.worktreeinclude")" -eq 4 ] || { v=$((v+1)); echo ".worktreeinclude n'a pas 4 lignes" >> "$WORK/inv.detail"; }
    "$GREP" -q 'vibeflow-role' "$lab/.worktreeinclude" && { v=$((v+1)); echo "ligne de poste dans .worktreeinclude" >> "$WORK/inv.detail"; }
  else
    v=$((v+1)); echo ".worktreeinclude absent" >> "$WORK/inv.detail"
  fi
  e="$WORK/inv.hook.out"; r="$WORK/inv.hook.err"
  (cd "$lab" && CLAUDE_PROJECT_DIR="$lab" bash "$lab/.claude/scripts/check-role-consistency.sh" --hook > "$e" 2> "$r"); local rc=$?
  [ "$rc" -eq 0 ] || { v=$((v+1)); echo "hook de poste rc=$rc" >> "$WORK/inv.detail"; }
  [ ! -s "$e" ] || { v=$((v+1)); echo "hook de poste non muet sur stdout" >> "$WORK/inv.detail"; }
  [ ! -s "$r" ] || { v=$((v+1)); echo "hook de poste non muet sur stderr" >> "$WORK/inv.detail"; }
  echo "$v"
}

V_R="$(invariants_sans_poste "$LR")"
mk_lab C; LC_="$LAB"; HC="$LABHOME"
do_install "$LC_" "$HC" "$ENG_NEW" "$PLUGIN" - --dry-run install --all; RCD=$?
miss=0
[ "$V_R" -eq 0 ] || { ko "E2E-C2-INV : $V_R invariant(s) violé(s) sur le lab sans poste — $(tr '\n' ';' < "$WORK/inv.detail")"; miss=1; }
[ "$RCD" -eq 0 ] || { ko "E2E-C2-INV : plan --dry-run sans poste rc=$RCD"; miss=1; }
"$GREP" -q 'vibeflow-role' "$WORK/out.C" && { ko "E2E-C2-INV : le plan --dry-run sans poste mentionne le poste"; miss=1; }
[ "$(nlines "$WORK/out.C")" -gt 0 ] || { ko "E2E-C2-INV : plan --dry-run vide (la vérification serait à vide)"; miss=1; }
[ -z "$(ls -A "$LC_" | "$GREP" -v '^\.git$')" ] || { ko "E2E-C2-INV : le --dry-run a écrit dans le lab"; miss=1; }
[ "$miss" -eq 0 ] && ok "E2E-C2-INV (P58-D-10, P58-D-19) : sans poste ni fichier de poste, ni .gitignore, .worktreeinclude à 4 lignes, hook muet, plan sans poste"

V_A="$(invariants_sans_poste "$LA")"
if [ "$V_A" -ge 2 ]; then
  ok "E2E-C2-TEMOIN (P58-D-19) : les mêmes invariants rougissent sur le lab product ($V_A assertions violées)"
else
  ko "E2E-C2-TEMOIN : les invariants ne rougissent que sur $V_A assertion(s) du lab product (attendu ≥ 2) — vérification aveugle"
fi

# ---------------------------------------------------------------------------
# E2E-C2-AB — ancien engine contre nouveau sur le même cache (ARMÉ)
# ---------------------------------------------------------------------------
esc_re() { printf '%s' "$1" | sed 's/[][\.*^$|/]/\\&/g'; }

# norm_tree <lab> <home> <cache> <dest> — copie normalisée (hors exclusions) ; liste dans <dest>.list
norm_tree() {
  local lab="$1" home="$2" cache="$3" dest="$4" f
  mkdir -p "$dest"
  (cd "$lab" && find . -type f -not -path './.git/*' -not -path './.claude/.backups/*' \
      -not -path './.claude/logs/archive.log' -not -path './.claude/scripts/.vibeflow-target' | LC_ALL=C sort) > "$dest.list"
  local sedargs=() p
  for p in "$lab" "$home" "$cache"; do
    sedargs+=(-e "s|$(esc_re "$p")|<TOK>|g")
    sedargs+=(-e "s|$(esc_re "${p#/private}")|<TOK>|g")
  done
  while IFS= read -r f || [ -n "$f" ]; do
    mkdir -p "$dest/$(dirname "$f")"
    case "$f" in
      ./.claude/skills/*gsd-skills-index.md|*/gsd-skills-index.md)
        LC_ALL=C sed "${sedargs[@]}" -e '/Généré le/d' "$lab/$f" > "$dest/$f" ;;
      *) LC_ALL=C sed "${sedargs[@]}" "$lab/$f" > "$dest/$f" ;;
    esac
  done < "$dest.list"
}

# norm_compare <labA> <homeA> <cacheA> <labB> <homeB> <cacheB> — 0 identiques ; 1 sinon, 1re divergence (chemin) sur $WORK/ab.first
norm_compare() {
  rm -rf "$WORK/nA" "$WORK/nB" "$WORK/nA.list" "$WORK/nB.list"
  norm_tree "$1" "$2" "$3" "$WORK/nA"; norm_tree "$4" "$5" "$6" "$WORK/nB"
  : > "$WORK/ab.first"
  if ! cmp -s "$WORK/nA.list" "$WORK/nB.list"; then
    echo "listes de fichiers différentes: $(comm -3 "$WORK/nA.list" "$WORK/nB.list" | head -1 | tr -d '\t')" > "$WORK/ab.first"; return 1
  fi
  [ "$(nlines "$WORK/nA.list")" -gt 0 ] || { echo "arbres vides" > "$WORK/ab.first"; return 1; }
  local f
  while IFS= read -r f || [ -n "$f" ]; do
    cmp -s "$WORK/nA/$f" "$WORK/nB/$f" || { echo "$f" > "$WORK/ab.first"; return 1; }
  done < "$WORK/nA.list"
  return 0
}

BASE="${VF_ROLE_E2E_BASE:-}"
[ -n "$BASE" ] || BASE="$(git -C "$DEPOT" merge-base HEAD origin/main 2>/dev/null)"
ARMED="${VF_ROLE_E2E_LIVRAISON:-0}"
ab_skip() { # <raison>
  if [ "$ARMED" = "1" ]; then ko "E2E-C2-AB : preuve armée mais non exécutable ($1) — jamais un vert"; else skip "E2E-C2-AB ($1)"; fi
}

if [ "$ARMED" != "1" ]; then
  skip "E2E-C2-AB (preuve de livraison non armée : VF_ROLE_E2E_LIVRAISON=1 pour la jouer)"
elif [ -z "$BASE" ] || ! git -C "$DEPOT" cat-file -e "$BASE^{commit}" 2>/dev/null; then
  ab_skip "base illisible : VF_ROLE_E2E_BASE ou origin/main absent"
else
  REF="$WORK/cacheref"; mkdir -p "$REF"
  cp -R "$PLUGIN/." "$REF/" 2>/dev/null
  rm -rf "$REF/_internal"
  mkdir -p "$WORK/arch"
  if git -C "$DEPOT" archive "$BASE" plugin/_internal | tar -x -C "$WORK/arch" 2>/dev/null && [ -f "$WORK/arch/plugin/_internal/vibeflow-update.sh" ]; then
    cp -R "$WORK/arch/plugin/_internal" "$REF/_internal"
    mk_lab O; LO="$LAB"; HO="$LABHOME"
    do_install "$LO" "$HO" "$REF/_internal/vibeflow-update.sh" "$REF" - install --all; RCO=$?
    miss=0
    [ "$RCO" -eq 0 ] || { ko "E2E-C2-AB pré-condition : install de l'ancien engine rc=$RCO — $(tail -3 "$WORK/err.O")"; miss=1; }
    if [ "$miss" -eq 0 ]; then
      # Les deux engines ont posé leurs arbres sur le MÊME cache de modules (contenu) : on compare lab R (nouveau) à lab O (ancien).
      if norm_compare "$LO" "$HO" "$REF" "$LR" "$HR" "$PLUGIN"; then
        :
      else
        ko "E2E-C2-AB : installs sans poste différentes, première divergence : $(cat "$WORK/ab.first")"; miss=1
      fi
      # Plans --dry-run des deux engines
      mk_lab P; LP1="$LAB"; HP1="$LABHOME"; mk_lab Q; LQ="$LAB"; HQ="$LABHOME"
      do_install "$LP1" "$HP1" "$REF/_internal/vibeflow-update.sh" "$REF" - --dry-run install --all
      do_install "$LQ" "$HQ" "$ENG_NEW" "$PLUGIN" - --dry-run install --all
      plan_norm() { # <sortie> <lab> <home> <cache> -> stdout
        local sedargs=() p
        for p in "$2" "$3" "$4"; do sedargs+=(-e "s|$(esc_re "$p")|<TOK>|g" -e "s|$(esc_re "${p#/private}")|<TOK>|g"); done
        "$GREP" -v '\.backups/settings-' "$1" | LC_ALL=C sed "${sedargs[@]}"
      }
      plan_norm "$WORK/out.P" "$LP1" "$HP1" "$REF" > "$WORK/plan.old"
      plan_norm "$WORK/out.Q" "$LQ" "$HQ" "$PLUGIN" > "$WORK/plan.new"
      if [ "$(nlines "$WORK/plan.old")" -gt 0 ] && cmp -s "$WORK/plan.old" "$WORK/plan.new"; then :; else
        ko "E2E-C2-AB : plans --dry-run différents ou vides (ancien $(nlines "$WORK/plan.old") lignes, nouveau $(nlines "$WORK/plan.new"))"; miss=1
      fi
      [ "$miss" -eq 0 ] && ok "E2E-C2-AB (P58-PL-05, P58-D-10) : ancien et nouvel engine posent le même lab sans poste ($(nlines "$WORK/nA.list") fichiers) et le même plan --dry-run"
      # Témoin : le lab product (A) est jugé DIFFÉRENT de l'ancien par le même comparateur.
      if norm_compare "$LO" "$HO" "$REF" "$LA" "$HA" "$PLUGIN"; then
        ko "E2E-C2-AB-TEMOIN : le comparateur juge IDENTIQUES l'ancien engine et le lab product — comparateur aveugle"
      else
        ok "E2E-C2-AB-TEMOIN (P58-PL-05) : le lab product est jugé DIFFÉRENT de l'ancien engine (première divergence : $(cat "$WORK/ab.first"))"
      fi
    else
      ko "E2E-C2-AB-TEMOIN : non joué (pré-condition de E2E-C2-AB en échec)"
    fi
  else
    ab_skip "git archive de la base impossible"
  fi
fi

# ---------------------------------------------------------------------------
# E2E-C5 — aucun agent au-delà de 250 lignes
# ---------------------------------------------------------------------------
LONG="$WORK/agents.long"; : > "$LONG"
NAG=0
while IFS= read -r f || [ -n "$f" ]; do
  [ -n "$f" ] || continue
  NAG=$((NAG+1))
  n="$(awk 'END { print NR }' "$f")"
  [ "$n" -le 250 ] || echo "$f ($n lignes)" >> "$LONG"
done < <(cd "$DEPOT" && { find plugin/*/agents -name '*.md' -not -path '*-references*' 2>/dev/null; ls plugin/*/AGENT.md 2>/dev/null; } | LC_ALL=C sort -u)
if [ "$NAG" -gt 0 ] && [ ! -s "$LONG" ]; then
  ok "E2E-C5 (critère 5, ADR-029) : $NAG fichier(s) d'agent, aucun au-delà de 250 lignes"
else
  ko "E2E-C5 : $NAG agent(s) mesuré(s), fautif(s) : $(tr '\n' ';' < "$LONG")"
fi

# ---------------------------------------------------------------------------
# E2E-ADR / E2E-GLOSS — présences doctrinales, une seule fois
# ---------------------------------------------------------------------------
# ADR-077 : un seul titre, et dans son corps (jusqu'au titre suivant) les deux énoncés.
N_ADR="$(awk '/^## ADR-077 : /{ n++ } END { print n+0 }' "$DEPOT/docs/ADR.md")"
N_ENONCES="$(awk '/^## ADR-077 : /{ in77 = 1; next } /^## /{ in77 = 0 }
  in77 && index($0, "agentique first, ouvert à la collaboration humaine") { a = 1 }
  in77 && index($0, "un poste est une vue, pas un droit") { b = 1 }
  END { print a + b + 0 }' "$DEPOT/docs/ADR.md")"
if [ "$N_ADR" -eq 1 ] && [ "$N_ENONCES" -eq 2 ]; then
  ok "E2E-ADR (P58-D-11) : ADR-077 présente exactement une fois, avec ses deux énoncés"
else
  ko "E2E-ADR : $N_ADR titre(s) « ## ADR-077 : » (attendu 1), $N_ENONCES énoncé(s) dans le corps (attendu 2)"
fi
N_GL="$(awk '/^- \*\*poste \/ rôle d.agent \/ statut\*\*/{ n++ } END { print n+0 }' "$DEPOT/docs/_transverse/REFERENCE.md")"
if [ "$N_GL" -eq 1 ]; then
  ok "E2E-GLOSS (P58-D-12) : l'entrée de glossaire « poste / rôle d'agent / statut » est présente exactement une fois"
else
  ko "E2E-GLOSS : $N_GL entrée(s) « poste / rôle d'agent / statut » dans docs/_transverse/REFERENCE.md (attendu 1)"
fi

# ---------------------------------------------------------------------------
# E2E-HOME — le vrai ~/.claude n'a pas bougé
# ---------------------------------------------------------------------------
HOME_AFTER=$(snapshot_home_claude)
if [ "$HOME_BEFORE" = "$HOME_AFTER" ]; then
  ok "E2E-HOME (T-58-29) : le vrai ~/.claude est intact ($HOME_BEFORE fichiers)"
else
  ko "E2E-HOME : le vrai ~/.claude est POLLUÉ ($HOME_BEFORE -> $HOME_AFTER fichiers)"
fi

echo "cardinal de D : $CARD_D chemins dev dérivés ($SHARED partagé(s) écarté(s))"
echo "== Résultat : $pass OK, $fail KO, $skipped SKIP =="
[ "$fail" -eq 0 ]
