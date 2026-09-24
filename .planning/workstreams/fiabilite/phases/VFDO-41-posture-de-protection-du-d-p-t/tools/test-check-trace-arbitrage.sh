#!/usr/bin/env bash
# test-check-trace-arbitrage.sh — Suite de verification de check-trace-arbitrage.sh (Phase 41,
# PROT-04, QUAL-01, plan 41-15, Task 2). Patron : tools/test-check-aucune-fermeture.sh (Task 1 de
# ce meme plan) et scripts/tests/test-check-baseline-arbitrage.sh (plan 41-14). Chaque cas
# construit SON PROPRE depot jetable sous mktemp -d, JAMAIS le depot reel ; identite git passee
# par -c, jamais la configuration du poste. Une suite incapable de rougir est un defaut.
#
# VINGT-ET-UN cas (C0..C17, plus C2b, C6b, C6c) plus DIX mutants opposables (MUT-1 a MUT-10) —
# MUT-1 a MUT-2 un par comparaison du script sous test (MUT-2 REPURPOSE le 2026-09-24 : l'ancien
# comptage d'unicite qu'il tuait a ete retire, voir fix defaut A ci-dessous), MUT-3 a MUT-4 sur les
# deux autres comparaisons, MUT-5 et MUT-6 sur la PORTE D'ENTREE du detecteur (liste des marqueurs
# d'invocation, decision du manager, reprise 2026-09-18), MUT-7 a MUT-9 AJOUTES le 2026-09-24 sur
# les trois defauts corriges ce jour-la (merges de PR reels, commits de release, insensibilite a
# la casse du mot declencheur — voir C6c/MUT-7, C14/MUT-8, C15/MUT-9), MUT-10 AJOUTE le 2026-09-24
# (ADR-075) sur le prefixe de registre obligatoire P41-D-NN (voir C16/C17/MUT-10) — regle de
# comptage (avertissement 3 du verificateur frais, decision du manager du 2026-09-17) : chaque
# mutant asserte le rc EXACT sur le mutant ET sur l'original, et n'est credite que par une ligne
# de forme canonique « ✓ MUT-<n> TUE : rc_mutant=<x> attendu <x>, rc_original=<y> attendu <y> ».
# Un mutant qui « echoue » par un plantage ou une plage vide n'est PAS compte comme tue. MUT-5 est
# le SEUL mutant de cette suite juge sur la plage REELLE du depot (jamais une fixture jetable) :
# le resserrement lui-meme n'est prouve que par sa capacite a distinguer un detecteur large (rouge
# sur l'historique reel) d'un detecteur resserre (vert sur ce meme historique).
#
# FIX DU 2026-09-24 (arbitrage Samuel, AskUserQuestion session principale) — TROIS defauts de
# conception corriges dans check-trace-arbitrage.sh, mesures sur le depot reel :
#   A. Les citations multiples DISTINCTES et CONFORMES sont desormais ACCEPTEES (etaient
#      refusees a tort — voir C2/C2b et MUT-2 repurpose).
#   B1. Les merges REELS de PR GitHub (« Merge pull request #N from ... ») sont exclus du
#       jugement, au meme titre que le merge ephemere de previsualisation (voir C6c/MUT-7).
#   B2. Les commits de release (« release(vX.Y.Z): ... ») sont exclus du jugement (voir C14/MUT-8).
#   B3. Le mot declencheur de l'extraction (« arbitrage »/« décision ») est desormais insensible
#       a la casse (voir C15/MUT-9).
#
# FIX DU 2026-09-24, SEPARE (arbitrage Samuel, AskUserQuestion session principale, ADR-075) — UN
# QUATRIEME defaut, distinct des trois ci-dessus (ceux-ci corrigeaient la FORME de la citation ;
# celui-ci corrige la PORTE D'ENTREE elle-meme) : un identifiant `D-01`..`D-10` NU franchissait la
# porte d'entree quel que soit son registre d'origine. Mesure sur le depot reel : la mission
# « partition reelle du planning » a numerote sa propre decision `D-02` le 2026-09-23, sans rapport
# avec le registre de cette phase, et des commits qui la citaient sans invoquer d'arbitrage
# rendaient pourtant FORME-NON-CONFORME (contourne a l'epoque en avancant BASE-TRACE-ARBITRAGE,
# voir 41-PREUVES.md § 41-14). Le detecteur n'engage desormais son controle que sur la forme
# prefixee par SON PROPRE registre, `P41-D-01`..`P41-D-10` (voir C16/C17/MUT-10).
set -uo pipefail

TOOLS_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$TOOLS_DIR/check-trace-arbitrage.sh"
TARGET="$SCRIPT"
# REAL_ROOT — racine du depot reel, calculee EXACTEMENT comme DEFAULT_ROOT dans le script sous
# test (git rev-parse --show-toplevel depuis TOOLS_DIR, jamais un comptage de `../` — meme defaut
# mesure et corrige le 2026-09-24 cf. check-trace-arbitrage.sh), utilisee UNIQUEMENT par MUT-5
# (jamais par les controles C0..C13 ni MUT-1..MUT-4, tous sur fixture jetable).
REAL_ROOT="$(git -C "$TOOLS_DIR" rev-parse --show-toplevel)"

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS + 1)); }
ko() {  # <assertion> <attendu> <obtenu>
  echo "  ✗ $1"
  echo "    assertion : $1"
  echo "    attendu   : $2"
  echo "    obtenu    : $3"
  FAIL=$((FAIL + 1))
}
okmut() {  # <n> <rc_mutant> <attendu_mut> <rc_original> <attendu_orig>
  echo "  ✓ MUT-$1 TUE : rc_mutant=$2 attendu $3, rc_original=$4 attendu $5"
  PASS=$((PASS + 1))
}
komut() {  # <n> <assertion> <attendu> <obtenu>
  echo "  ✗ MUT-$1 NON TUE : $2"
  echo "    assertion : MUT-$1 $2"
  echo "    attendu   : $3"
  echo "    obtenu    : $4"
  FAIL=$((FAIL + 1))
}

TMP="$(mktemp -d)"
MUTD="$(mktemp -d)"
trap 'rm -rf "$TMP" "$MUTD"' EXIT

git_c() {  # <root> <args...> — identite de fixture par -c, jamais la config du poste.
  local root="$1"; shift
  git -C "$root" -c user.name=CI -c user.email=ci@example.invalid -c commit.gpgsign=false "$@"
}

# mk_repo <name> -> imprime <path> ; depot jetable vierge sur `main`, un premier commit neutre.
mk_repo() {
  local d="$TMP/$1"
  mkdir -p "$d" || { echo "  ✗ FIXTURE — mkdir $d impossible" >&2; exit 1; }
  git_c "$d" init -q -b main >/dev/null
  printf 'depart\n' > "$d/README-fixture.md"
  git_c "$d" add -A >/dev/null
  git_c "$d" commit -q -m "chore: etat initial de fixture" >/dev/null
  printf '%s' "$d"
}

commit_msg() {  # <root> <message complet> — touche un fichier neutre pour avoir un diff a committer.
  local root="$1" msg="$2"
  date +%s%N > "$root/marqueur-fixture.txt" 2>/dev/null || echo "$RANDOM$RANDOM" > "$root/marqueur-fixture.txt"
  git_c "$root" add -A >/dev/null
  git_c "$root" commit -q -m "$msg" >/dev/null
}

rev() { git_c "$1" rev-parse "$2"; }

# mk_preuves <root> [ligne-base-trace-arbitrage] — construit le registre de fixture au meme
# chemin relatif que le vrai 41-PREUVES.md, avec ou sans la cle BASE-TRACE-ARBITRAGE.
mk_preuves() {
  local root="$1" ligne="${2:-}"
  local dir="$root/.planning/phases/VFDO-41-posture-de-protection-du-d-p-t"
  mkdir -p "$dir"
  {
    echo "# registre de fixture"
    echo ""
    if [ -n "$ligne" ]; then
      echo "$ligne"
    fi
  } > "$dir/41-PREUVES.md"
}

# safe_run <var_out> <var_rc> [args...] — invocation TOUJOURS via $TARGET --root ... deja fourni
# par l'appelant dans [args...]. Ecrit sortie et rc REEL dans les variables nommees. Appelee comme
# instruction NUE (jamais entouree de $(...)) : `set +e`/`set -e` bascule alors l'etat REEL du
# shell courant — le seul moyen de faire cohabiter `bash -e` (impose par le verify du plan) avec
# un rc de fixture volontairement non nul, sans perdre l'affectation dans un sous-shell de
# substitution de commande. Meme patron que tools/test-check-aucune-fermeture.sh (Task 1).
safe_run() {
  local __vout="$1" __vrc="$2"; shift 2
  local __out __rc
  set +e
  __out="$(bash "$TARGET" "$@" 2>&1)"
  __rc=$?
  set -e
  eval "$__vout=\$__out"
  eval "$__vrc=\$__rc"
}

# make_mutant <name> <old> <new> -> imprime le chemin du mutant ; retour 0 = opposable et valide,
# 1 = identique a l'original (NON OPPOSABLE), 2 = syntaxe invalide.
make_mutant() {
  local name="$1" old="$2" new="$3"
  local out="$MUTD/${name}.sh"
  awk -v old="$old" -v new="$new" '{ if ($0 == old) { print new } else { print } }' "$SCRIPT" > "$out"
  if cmp -s "$out" "$SCRIPT"; then
    echo "$out"
    return 1
  fi
  if ! bash -n "$out" 2>/dev/null; then
    echo "$out"
    return 2
  fi
  echo "$out"
  return 0
}

CANON="arbitrage Samuel, AskUserQuestion session principale, 2026-09-17"

echo "== test-check-trace-arbitrage : CONTROLES (C0..C13) =="

# --- C0 : trois commits dont un citant conformement -> rc 0 ----------------------------------
D="$(mk_repo c0)"; B="$(rev "$D" HEAD)"
commit_msg "$D" "chore: rien a signaler"
commit_msg "$D" "feat: hausse quelque chose

$CANON"
safe_run out rc --root "$D" --base-ref "$B"
[ "$rc" -eq 0 ] && ok "C0 trois commits, un citant conformement -> rc 0" || ko "C0" "rc=0" "rc=$rc :: $out"

# --- C1 : citation « arbitrage Samuel » sans canal ni date -> rc 1 FORME-NON-CONFORME --------
D="$(mk_repo c1)"; B="$(rev "$D" HEAD)"
commit_msg "$D" "feat: hausse quelque chose

arbitrage Samuel, sans canal ni date ici"
safe_run out rc --root "$D" --base-ref "$B"
case "$out" in *FORME-NON-CONFORME*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ]; then ok "C1 citation sans canal ni date -> rc 1 FORME-NON-CONFORME"
else ko "C1" "rc=1 FORME-NON-CONFORME" "rc=$rc :: $out"; fi

# --- C2 : deux arbitrages DISTINCTS et conformes dans le meme commit -> rc 0 (fix defaut A,
# 2026-09-24 : refuser ce cas punissait ce que la regle voulait obtenir — voir 76985e3, 7b0ba33,
# b90c6bc, 6243c46, 849f29e sur le depot reel, tous CITATIONS-MULTIPLES a tort avant ce fix)
D="$(mk_repo c2)"; B="$(rev "$D" HEAD)"
commit_msg "$D" "feat: hausse quelque chose

$CANON

arbitrage Samuel, canal Slack de secours, 2026-09-18"
safe_run out rc --root "$D" --base-ref "$B"
[ "$rc" -eq 0 ] && ok "C2 deux arbitrages distincts conformes -> rc 0" || ko "C2" "rc=0" "rc=$rc :: $out"

# --- C2b : deux citations, l'une conforme et l'une NON conforme (perimetre mal cite) -> rc 1
# ARBITRAGE-DE-PERIMETRE-MAL-CITE. Preserve L'INTENTION D'ORIGINE de C2 (ne pas laisser une
# citation douteuse se noyer dans un paquet de bonnes), a l'echelle de la citation plutot que du
# message entier.
D="$(mk_repo c2b)"; B="$(rev "$D" HEAD)"
commit_msg "$D" "feat: hausse quelque chose

arbitrage Samuel, canal Slack de secours, 2026-09-18

arbitrage Samuel, canal de secours, 2026-09-17"
safe_run out rc --root "$D" --base-ref "$B"
case "$out" in *ARBITRAGE-DE-PERIMETRE-MAL-CITE*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ]; then ok "C2b citation douteuse noyee dans un paquet de bonnes -> rc 1 ARBITRAGE-DE-PERIMETRE-MAL-CITE"
else ko "C2b" "rc=1 ARBITRAGE-DE-PERIMETRE-MAL-CITE" "rc=$rc :: $out"; fi

# --- C3 : meme chaine canonique repetee deux fois -> rc 0 (controle negatif) -----------------
D="$(mk_repo c3)"; B="$(rev "$D" HEAD)"
commit_msg "$D" "feat: hausse quelque chose

$CANON. Rappel de la meme citation : $CANON."
safe_run out rc --root "$D" --base-ref "$B"
[ "$rc" -eq 0 ] && ok "C3 meme citation repetee deux fois -> rc 0" || ko "C3" "rc=0" "rc=$rc :: $out"

# --- C4 : arbitrage + date 2026-09-17 dans une forme voisine mais NON identique --------------
D="$(mk_repo c4)"; B="$(rev "$D" HEAD)"
commit_msg "$D" "feat: hausse quelque chose

arbitrage Samuel, canal de secours, 2026-09-17"
safe_run out rc --root "$D" --base-ref "$B"
case "$out" in *ARBITRAGE-DE-PERIMETRE-MAL-CITE*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ]; then ok "C4 forme voisine mais non identique -> rc 1 ARBITRAGE-DE-PERIMETRE-MAL-CITE"
else ko "C4" "rc=1 ARBITRAGE-DE-PERIMETRE-MAL-CITE" "rc=$rc :: $out"; fi

# --- C5 : commits ne citant rien -> rc 0 -----------------------------------------------------
D="$(mk_repo c5)"; B="$(rev "$D" HEAD)"
commit_msg "$D" "chore: rien a signaler ici"
commit_msg "$D" "feat: encore rien a signaler"
safe_run out rc --root "$D" --base-ref "$B"
[ "$rc" -eq 0 ] && ok "C5 commits ne citant rien -> rc 0" || ko "C5" "rc=0" "rc=$rc :: $out"

# --- C6 : message au format du merge ephemere de GitHub, sans citation -> rc 0 (borne) -------
D="$(mk_repo c6)"; B="$(rev "$D" HEAD)"
H1="0000000000000000000000000000000000000001"
H2="0000000000000000000000000000000000000002"
commit_msg "$D" "Merge $H1 into $H2"
commit_msg "$D" "chore: commit normal qui suit le merge ephemere"
safe_run out rc --root "$D" --base-ref "$B"
case "$out" in *"decouverte: commits=1 "*) n1=1 ;; *) n1=0 ;; esac
if [ "$rc" -eq 0 ] && [ "$n1" -eq 1 ]; then ok "C6 merge ephemere exclu, commit normal juge -> rc 0, commits=1"
else ko "C6" "rc=0 decouverte: commits=1" "rc=$rc :: $out"; fi

# --- C6b : identifiant compose "D-01-suite", sans aucune citation -> rc 0 (revue F5, 2026-09-18) -
# Avant le fix, MARKER_REGEX excluait le tiret a GAUCHE de D-NN mais pas a DROITE : "D-01-suite"
# matchait a tort la porte d'entree (M+=1), et puisque ce commit ne porte aucune citation complete
# derriere, il rendait FORME-NON-CONFORME/rc 1 — faux rouge sur un identifiant compose qui n'a
# jamais invoque d'autorite humaine. Apres le fix, ce meme identifiant ne franchit plus la porte
# d'entree : le commit reste hors jugement, plage non vide, rc 0.
D="$(mk_repo c6b)"; B="$(rev "$D" HEAD)"
commit_msg "$D" "chore: reference D-01-suite dans ce message, aucune citation ici"
safe_run out rc --root "$D" --base-ref "$B"
if [ "$rc" -eq 0 ]; then ok "C6b identifiant compose D-01-suite, aucune citation -> rc 0"
else ko "C6b identifiant compose D-01-suite" "rc=0" "rc=$rc :: $out"; fi

# --- C6c : merge REEL d'une PR GitHub (« Merge pull request #N from <branche> »), titre portant un
# marqueur P41-D-NN mais AUCUNE citation -> exclu du jugement (fix defaut B1, 2026-09-24 : depot
# reel, commit 0cec964, "Merge pull request #94 from picmakpro/feat/partition-planning-d02",
# rendait FORME-NON-CONFORME a cause du marqueur D-02 dans le titre de PR fusionne — marqueur de
# fixture prefixe P41-D-05 depuis le fix ADR-075, un D-NN nu ne franchissant plus la porte
# d'entree, voir PREFIXE DE REGISTRE OBLIGATOIRE dans le script sous test).
D="$(mk_repo c6c)"; B="$(rev "$D" HEAD)"
commit_msg "$D" "Merge pull request #94 from acme/feature-D-05-something

Partition reelle du planning — P41-D-05 (sans rapport avec une citation)"
commit_msg "$D" "chore: commit normal qui suit le merge de PR"
safe_run out rc --root "$D" --base-ref "$B"
case "$out" in *"decouverte: commits=1 "*) n1=1 ;; *) n1=0 ;; esac
if [ "$rc" -eq 0 ] && [ "$n1" -eq 1 ]; then ok "C6c merge reel de PR exclu malgre un marqueur dans le titre -> rc 0, commits=1"
else ko "C6c" "rc=0 decouverte: commits=1" "rc=$rc :: $out"; fi

# --- C7 : --base-ref egal a HEAD -> rc 3 PLAGE-VIDE ------------------------------------------
D="$(mk_repo c7)"; H="$(rev "$D" HEAD)"
safe_run out rc --root "$D" --base-ref "$H"
case "$out" in *PLAGE-VIDE*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 3 ] && [ "$has" -eq 1 ]; then ok "C7 --base-ref egal HEAD -> rc 3 PLAGE-VIDE"
else ko "C7" "rc=3 PLAGE-VIDE" "rc=$rc :: $out"; fi

# --- C8 : --base-ref vers une ref inexistante -> rc 2 ----------------------------------------
D="$(mk_repo c8)"
safe_run out rc --root "$D" --base-ref "refs/heads/ref-inexistante-xyz"
[ "$rc" -eq 2 ] && ok "C8 --base-ref inexistante -> rc 2" || ko "C8" "rc=2" "rc=$rc :: $out"

# --- C9 : option inconnue -> rc 64 -----------------------------------------------------------
D="$(mk_repo c9)"
safe_run out rc --root "$D" --option-bidon
[ "$rc" -eq 64 ] && ok "C9 option inconnue -> rc 64" || ko "C9" "rc=64" "rc=$rc :: $out"

# --- C10 : citation conforme COUPEE par un retour a la ligne -> rc 0 (normalisation) ---------
D="$(mk_repo c10)"; B="$(rev "$D" HEAD)"
commit_msg "$D" "feat: hausse quelque chose

arbitrage Samuel,
AskUserQuestion session principale,
2026-09-17"
safe_run out rc --root "$D" --base-ref "$B"
[ "$rc" -eq 0 ] && ok "C10 citation coupee par retour a la ligne -> rc 0 (normalisation)" || ko "C10" "rc=0" "rc=$rc :: $out"

# --- C11 : commit NON conforme PLACE COMME BORNE (donc avant/a la borne), commit conforme apres
# Reutilise par MUT-3 : la borne est lue via --base-ref pointant EXACTEMENT sur le commit fautif
# lui-meme (exclusion par construction du range git A..B, exclusif de A) ; MUT-3 deplace la
# resolution d'un cran EN ARRIERE (parent de la borne au lieu de la borne elle-meme), ce qui fait
# rentrer ce commit fautif dans le range juge.
D="$(mk_repo c11)"
FAUTIF_MSG="feat: hausse quelque chose

arbitrage Samuel, sans canal ni date (fautif, place a la borne)"
commit_msg "$D" "$FAUTIF_MSG"
BORNE="$(rev "$D" HEAD)"
commit_msg "$D" "feat: hausse conforme apres la borne

$CANON"
safe_run out rc --root "$D" --base-ref "$BORNE"
[ "$rc" -eq 0 ] && ok "C11 commit fautif a la borne exclu, commit conforme apres -> rc 0" || ko "C11" "rc=0" "rc=$rc :: $out"

# --- C12 : registre SANS ligne BASE-TRACE-ARBITRAGE, sans --base-ref -> rc 2 -----------------
D="$(mk_repo c12)"
commit_msg "$D" "chore: commit neutre"
mk_preuves "$D" ""
safe_run out rc --root "$D"
[ "$rc" -eq 2 ] && ok "C12 registre sans cle BASE-TRACE-ARBITRAGE -> rc 2" || ko "C12" "rc=2" "rc=$rc :: $out"

# --- C13 : registre portant une valeur NON RESOLUBLE en commit -> rc 2 ----------------------
D="$(mk_repo c13)"
commit_msg "$D" "chore: commit neutre"
mk_preuves "$D" "BASE-TRACE-ARBITRAGE: 0000000000000000000000000000000000000000"
safe_run out rc --root "$D"
[ "$rc" -eq 2 ] && ok "C13 registre avec valeur non resoluble -> rc 2" || ko "C13" "rc=2" "rc=$rc :: $out"

# --- C14 : commit de release ("release(vX.Y.Z): ...") portant un marqueur P41-D-NN mais AUCUNE
# citation -> exclu du jugement (fix defaut B2, 2026-09-24 : depot reel, commit 3617ec0,
# "release(v2.65.0): ...", rendait FORME-NON-CONFORME a cause du marqueur D-02 decrivant un
# correctif inclus dans le paquet publie — marqueur de fixture prefixe P41-D-05 depuis le fix
# ADR-075, un D-NN nu ne franchissant plus la porte d'entree).
D="$(mk_repo c14)"; B="$(rev "$D" HEAD)"
commit_msg "$D" "release(v9.9.9): rattrapage de publication

Depuis v9.9.8, un correctif (P41-D-05) avait touche le plugin distribue sans
jamais etre publie — bump patch, sans rapport avec une citation."
commit_msg "$D" "chore: commit normal qui suit la release"
safe_run out rc --root "$D" --base-ref "$B"
case "$out" in *"decouverte: commits=1 "*) n1=1 ;; *) n1=0 ;; esac
if [ "$rc" -eq 0 ] && [ "$n1" -eq 1 ]; then ok "C14 commit de release exclu malgre un marqueur -> rc 0, commits=1"
else ko "C14" "rc=0 decouverte: commits=1" "rc=$rc :: $out"; fi

# --- C15 : citation avec un A majuscule ("Arbitrage Willy, ...") -> rc 0 (fix defaut B3,
# 2026-09-24 : depot reel, commit 557b6fc, rendait FORME-NON-CONFORME au stade de l'extraction
# faute d'insensibilite a la casse sur le mot declencheur). Marqueur P41-D-02 ajoute pour faire
# franchir la PORTE D'ENTREE (sans lui, "Arbitrage Willy" seul ne matche aucun marqueur de
# MARKER_REGEX — exactement la situation du commit reel 557b6fc, ou D-02 etait le declencheur ;
# forme prefixee depuis le fix ADR-075, un D-NN nu ne franchissant plus cette porte).
D="$(mk_repo c15)"; B="$(rev "$D" HEAD)"
commit_msg "$D" "feat: hausse quelque chose (P41-D-02)

Arbitrage Willy, AskUserQuestion session principale, 2026-09-23"
safe_run out rc --root "$D" --base-ref "$B"
[ "$rc" -eq 0 ] && ok "C15 citation avec A majuscule -> rc 0" || ko "C15" "rc=0" "rc=$rc :: $out"

# --- C16 : identifiant D-NN NU, d'un AUTRE registre que celui de cette phase, sans aucune
# citation -> rc 0 (fix ADR-075, defaut mesure : la mission "partition reelle du planning" a
# numerote sa propre decision D-02 le 2026-09-23, sans rapport avec le registre P41-D-01..
# P41-D-10 de cette phase ; un commit qui la cite ne doit plus franchir la porte d'entree de ce
# detecteur). Reproduit la sonde reelle jouee en session : un message qui cite "D-02 au sens de
# la mission de partition" n'engage aucun arbitrage de cette phase.
D="$(mk_repo c16)"; B="$(rev "$D" HEAD)"
commit_msg "$D" "docs(sonde): reprend le chantier lance par la mission D-02 (partition du planning)

Commit temoin : cite D-02 au sens de la mission de partition, pas du registre
de decisions de la phase 41. Aucun arbitrage engage."
safe_run out rc --root "$D" --base-ref "$B"
if [ "$rc" -eq 0 ]; then ok "C16 identifiant D-02 d'un registre etranger, aucune citation -> rc 0"
else ko "C16 identifiant D-02 d'un registre etranger" "rc=0" "rc=$rc :: $out"; fi

# --- C17 : identifiant P41-D-NN, du registre DE CETTE PHASE, sans aucune citation -> rc 1
# FORME-NON-CONFORME (temoin inverse de C16 : le resserrement au prefixe P41- ne doit PAS
# desarmer le detecteur sur son propre registre — un identifiant qui franchit la porte d'entree
# reste juge, exactement comme avant le fix, seule la porte d'entree a change).
D="$(mk_repo c17)"; B="$(rev "$D" HEAD)"
commit_msg "$D" "feat: applique la decision P41-D-02 sans citer d'arbitrage"
safe_run out rc --root "$D" --base-ref "$B"
case "$out" in *FORME-NON-CONFORME*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ]; then ok "C17 identifiant P41-D-02 du registre de la phase, aucune citation -> rc 1 FORME-NON-CONFORME"
else ko "C17 identifiant P41-D-02 du registre de la phase" "rc=1 FORME-NON-CONFORME" "rc=$rc :: $out"; fi

echo "== test-check-trace-arbitrage : MUTANTS (MUT-1 a MUT-10) =="

# --- MUT-1 : neutralise le controle de forme -> C1 devient vert sur le mutant ----------------
MUT1_OLD='  if [ "$nmatches" -eq 0 ]; then'
MUT1_NEW='  if [ "0" = "1" ]; then'
set +e
MUT1_PATH="$(make_mutant mut1 "$MUT1_OLD" "$MUT1_NEW")"
MUT1_STAT=$?
set -e
D="$(mk_repo mut1)"; B="$(rev "$D" HEAD)"
commit_msg "$D" "feat: hausse quelque chose

arbitrage Samuel, sans canal ni date ici"
if [ "$MUT1_STAT" -eq 1 ]; then komut 1 "controle de forme neutralise" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT1_STAT" -eq 2 ]; then komut 1 "controle de forme neutralise" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT1_PATH"; safe_run out_mut rc_mut --root "$D" --base-ref "$B"
  TARGET="$SCRIPT"; safe_run out_orig rc_orig --root "$D" --base-ref "$B"
  if [ "$rc_mut" -eq 0 ] && [ "$rc_orig" -eq 1 ]; then okmut 1 "$rc_mut" 0 "$rc_orig" 1
  else komut 1 "controle de forme neutralise" "rc_mutant=0 rc_original=1" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-2 : neutralise le controle DE PERIMETRE PAR CITATION (fix defaut A, 2026-09-24) ->
# C2b (citation douteuse noyee dans un paquet de bonnes) devient vert sur le mutant, alors que
# l'original la rejette toujours. Repurpose du MUT-2 original (qui testait l'ancien comptage
# d'unicite, retire) : preuve que l'INTENTION D'ORIGINE de C2 (ne jamais laisser une citation
# douteuse se noyer parmi des bonnes) tient toujours apres le changement d'echelle vers le
# jugement par citation.
MUT2_OLD='  if [ "$bad_match" -eq 1 ]; then'
MUT2_NEW='  if [ "0" = "1" ]; then'
set +e
MUT2_PATH="$(make_mutant mut2 "$MUT2_OLD" "$MUT2_NEW")"
MUT2_STAT=$?
set -e
D="$(mk_repo mut2)"; B="$(rev "$D" HEAD)"
commit_msg "$D" "feat: hausse quelque chose

arbitrage Samuel, canal Slack de secours, 2026-09-18

arbitrage Samuel, canal de secours, 2026-09-17"
if [ "$MUT2_STAT" -eq 1 ]; then komut 2 "controle de perimetre par citation neutralise" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT2_STAT" -eq 2 ]; then komut 2 "controle de perimetre par citation neutralise" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT2_PATH"; safe_run out_mut rc_mut --root "$D" --base-ref "$B"
  TARGET="$SCRIPT"; safe_run out_orig rc_orig --root "$D" --base-ref "$B"
  if [ "$rc_mut" -eq 0 ] && [ "$rc_orig" -eq 1 ]; then okmut 2 "$rc_mut" 0 "$rc_orig" 1
  else komut 2 "controle de perimetre par citation neutralise" "rc_mutant=0 rc_original=1" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-3 : neutralise la lecture EXACTE de la borne (repli d'un cran sur son parent, un
# analogue de « adjacence » plutot que la lecture propre de BASE-TRACE-ARBITRAGE) -> la fixture
# C11 (commit fautif place EXACTEMENT a la borne, donc exclu par construction du range exclusif
# A..B) devient ROUGE sur le mutant (le parent-de-la-borne fait rentrer le commit fautif dans le
# range), reste VERTE sur l'original : c'est le mutant qui prouve que la borne resolue est bien
# CELLE LUE, jamais une adjacence de repli.
MUT3_OLD='BASE_SHA="$(git -C "$ROOT" rev-parse --verify -q "${BASE_RAW}^{commit}" 2>/dev/null || true)"'
MUT3_NEW='BASE_SHA="$(git -C "$ROOT" rev-parse --verify -q "${BASE_RAW}^" 2>/dev/null || true)"'
set +e
MUT3_PATH="$(make_mutant mut3 "$MUT3_OLD" "$MUT3_NEW")"
MUT3_STAT=$?
set -e
D="$(mk_repo mut3)"
commit_msg "$D" "feat: hausse quelque chose

arbitrage Samuel, sans canal ni date (fautif, place a la borne)"
BORNE="$(rev "$D" HEAD)"
commit_msg "$D" "feat: hausse conforme apres la borne

$CANON"
if [ "$MUT3_STAT" -eq 1 ]; then komut 3 "lecture exacte de la borne neutralisee" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT3_STAT" -eq 2 ]; then komut 3 "lecture exacte de la borne neutralisee" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT3_PATH"; safe_run out_mut rc_mut --root "$D" --base-ref "$BORNE"
  TARGET="$SCRIPT"; safe_run out_orig rc_orig --root "$D" --base-ref "$BORNE"
  if [ "$rc_mut" -eq 1 ] && [ "$rc_orig" -eq 0 ]; then okmut 3 "$rc_mut" 1 "$rc_orig" 0
  else komut 3 "lecture exacte de la borne neutralisee" "rc_mutant=1 rc_original=0" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-4 : neutralise la normalisation des blancs -> C10 devient ROUGE sur le mutant -------
MUT4_OLD="  tr '\\\\n' ' ' | tr -s '[:space:]' ' ' | sed -e 's/^ //' -e 's/ \$//'"
MUT4_NEW='  cat'
set +e
MUT4_PATH="$(make_mutant mut4 "$MUT4_OLD" "$MUT4_NEW")"
MUT4_STAT=$?
set -e
D="$(mk_repo mut4)"; B="$(rev "$D" HEAD)"
commit_msg "$D" "feat: hausse quelque chose

arbitrage Samuel,
AskUserQuestion session principale,
2026-09-17"
if [ "$MUT4_STAT" -eq 1 ]; then komut 4 "normalisation des blancs neutralisee" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT4_STAT" -eq 2 ]; then komut 4 "normalisation des blancs neutralisee" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT4_PATH"; safe_run out_mut rc_mut --root "$D" --base-ref "$B"
  TARGET="$SCRIPT"; safe_run out_orig rc_orig --root "$D" --base-ref "$B"
  if [ "$rc_mut" -eq 1 ] && [ "$rc_orig" -eq 0 ]; then okmut 4 "$rc_mut" 1 "$rc_orig" 0
  else komut 4 "normalisation des blancs neutralisee" "rc_mutant=1 rc_original=0" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-5 : elargit la porte d'entree a la simple occurrence du mot racine (sans exiger un
# marqueur d'invocation) -> doit rendre ROUGE la mesure sur la PLAGE REELLE du depot, alors que
# l'original reste VERT (decision du manager, reprise 2026-09-18, point 4 premier mutant). SEUL
# mutant de cette suite juge sur REAL_ROOT, jamais une fixture jetable : le resserrement n'est
# prouve que par sa capacite a distinguer un detecteur large (rouge sur l'historique reel, ou des
# mentions informelles pre-existent) d'un detecteur resserre (vert sur ce meme historique).
MUT5_OLD="MARKER_REGEX='[Aa]rbitrage Samuel|sur [Aa]rbitrage|[Dd]écision de Samuel|(^|[^0-9A-Za-z_-])P41-D-(0[1-9]|10)([^0-9A-Za-z_-]|\$)|[A-Za-z0-9_]+-DECISION:|REGLES_MAIN_FORCE_PUSH_SUPPRESSION'"
MUT5_NEW="MARKER_REGEX='arbitrage|arbitrages|décision|décisions|decision|decisions'"
set +e
MUT5_PATH="$(make_mutant mut5 "$MUT5_OLD" "$MUT5_NEW")"
MUT5_STAT=$?
set -e
if [ "$MUT5_STAT" -eq 1 ]; then komut 5 "porte d'entree elargie au mot racine" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT5_STAT" -eq 2 ]; then komut 5 "porte d'entree elargie au mot racine" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT5_PATH"; safe_run out_mut rc_mut --root "$REAL_ROOT"
  TARGET="$SCRIPT"; safe_run out_orig rc_orig --root "$REAL_ROOT"
  if [ "$rc_mut" -eq 1 ] && [ "$rc_orig" -eq 0 ]; then okmut 5 "$rc_mut" 1 "$rc_orig" 0
  else komut 5 "porte d'entree elargie au mot racine (depot reel)" "rc_mutant=1 rc_original=0" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-6 : retire un marqueur d'invocation de la liste (« arbitrage Samuel ») -> doit rendre
# VERT un cas de fixture qui invoque CE marqueur sans citation canonique complete, alors que
# l'original reste ROUGE sur ce meme cas (decision du manager, reprise 2026-09-18, point 4 second
# mutant). Reutilise le scenario de C1 (citation sans canal ni date), sur une fixture jetable
# dediee — jamais le depot reel.
MUT6_OLD="MARKER_REGEX='[Aa]rbitrage Samuel|sur [Aa]rbitrage|[Dd]écision de Samuel|(^|[^0-9A-Za-z_-])P41-D-(0[1-9]|10)([^0-9A-Za-z_-]|\$)|[A-Za-z0-9_]+-DECISION:|REGLES_MAIN_FORCE_PUSH_SUPPRESSION'"
MUT6_NEW="MARKER_REGEX='sur [Aa]rbitrage|[Dd]écision de Samuel|(^|[^0-9A-Za-z_-])P41-D-(0[1-9]|10)([^0-9A-Za-z_-]|\$)|[A-Za-z0-9_]+-DECISION:|REGLES_MAIN_FORCE_PUSH_SUPPRESSION'"
set +e
MUT6_PATH="$(make_mutant mut6 "$MUT6_OLD" "$MUT6_NEW")"
MUT6_STAT=$?
set -e
D="$(mk_repo mut6)"; B="$(rev "$D" HEAD)"
commit_msg "$D" "feat: hausse quelque chose

arbitrage Samuel, sans canal ni date ici"
if [ "$MUT6_STAT" -eq 1 ]; then komut 6 "marqueur arbitrage Samuel retire de la liste" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT6_STAT" -eq 2 ]; then komut 6 "marqueur arbitrage Samuel retire de la liste" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT6_PATH"; safe_run out_mut rc_mut --root "$D" --base-ref "$B"
  TARGET="$SCRIPT"; safe_run out_orig rc_orig --root "$D" --base-ref "$B"
  if [ "$rc_mut" -eq 0 ] && [ "$rc_orig" -eq 1 ]; then okmut 6 "$rc_mut" 0 "$rc_orig" 1
  else komut 6 "marqueur arbitrage Samuel retire de la liste" "rc_mutant=0 rc_original=1" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-7 : retire la forme "Merge pull request #N from ..." de l'exclusion des merges de PR
# (fix defaut B1, 2026-09-24) -> le mutant ne reconnait plus que la forme ephemere ; sur la
# fixture C6c (merge reel de PR, marqueur D-05 dans le titre, aucune citation), le mutant compte
# le commit et le fait rougir FORME-NON-CONFORME, alors que l'original l'exclut toujours (rc 0).
MUT7_OLD="  grep -Eq '^Merge [0-9a-fA-F]{40} into [0-9a-fA-F]{40}\$|^Merge pull request #[0-9]+ from [^[:space:]]+'"
MUT7_NEW="  grep -Eq '^Merge [0-9a-fA-F]{40} into [0-9a-fA-F]{40}\$'"
set +e
MUT7_PATH="$(make_mutant mut7 "$MUT7_OLD" "$MUT7_NEW")"
MUT7_STAT=$?
set -e
D="$(mk_repo mut7)"; B="$(rev "$D" HEAD)"
commit_msg "$D" "Merge pull request #94 from acme/feature-D-05-something

Partition reelle du planning — P41-D-05 (sans rapport avec une citation)"
commit_msg "$D" "chore: commit normal qui suit le merge de PR"
if [ "$MUT7_STAT" -eq 1 ]; then komut 7 "exclusion du merge reel de PR neutralisee" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT7_STAT" -eq 2 ]; then komut 7 "exclusion du merge reel de PR neutralisee" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT7_PATH"; safe_run out_mut rc_mut --root "$D" --base-ref "$B"
  TARGET="$SCRIPT"; safe_run out_orig rc_orig --root "$D" --base-ref "$B"
  if [ "$rc_mut" -eq 1 ] && [ "$rc_orig" -eq 0 ]; then okmut 7 "$rc_mut" 1 "$rc_orig" 0
  else komut 7 "exclusion du merge reel de PR neutralisee" "rc_mutant=1 rc_original=0" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-8 : retire l'exclusion des commits de release (fix defaut B2, 2026-09-24) -> sur la
# fixture C14 (release avec marqueur D-05, aucune citation), le mutant compte le commit et le
# fait rougir FORME-NON-CONFORME, alors que l'original l'exclut toujours (rc 0). Mutation posee
# sur le SITE D'APPEL, jamais sur le motif grep lui-meme (celui-ci porte des parentheses
# echappees ; `awk -v` mangle les sequences `\(` non reconnues et fait echouer la comparaison
# EXACTE de make_mutant — meme famille de piege que documentee en memoire agent, awk -v et ses
# echappements). Le `\\n` DOUBLE ici (bash) est necessaire : `awk -v` collapse un `\\` en `\`
# avant de comparer a `$0`, donc SEUL un double backslash bash survit en simple backslash cote
# awk, celui reellement present dans la ligne ciblee (verifie empiriquement).
MUT8_OLD='  if printf '"'"'%s\\n'"'"' "$norm" | is_release_commit; then'
MUT8_NEW='  if false; then'
set +e
MUT8_PATH="$(make_mutant mut8 "$MUT8_OLD" "$MUT8_NEW")"
MUT8_STAT=$?
set -e
D="$(mk_repo mut8)"; B="$(rev "$D" HEAD)"
commit_msg "$D" "release(v9.9.9): rattrapage de publication

Depuis v9.9.8, un correctif (P41-D-05) avait touche le plugin distribue sans
jamais etre publie — bump patch, sans rapport avec une citation."
commit_msg "$D" "chore: commit normal qui suit la release"
if [ "$MUT8_STAT" -eq 1 ]; then komut 8 "exclusion des commits de release neutralisee" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT8_STAT" -eq 2 ]; then komut 8 "exclusion des commits de release neutralisee" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT8_PATH"; safe_run out_mut rc_mut --root "$D" --base-ref "$B"
  TARGET="$SCRIPT"; safe_run out_orig rc_orig --root "$D" --base-ref "$B"
  if [ "$rc_mut" -eq 1 ] && [ "$rc_orig" -eq 0 ]; then okmut 8 "$rc_mut" 1 "$rc_orig" 0
  else komut 8 "exclusion des commits de release neutralisee" "rc_mutant=1 rc_original=0" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-9 : retire l'insensibilite a la casse sur le mot declencheur de l'extraction (fix
# defaut B3, 2026-09-24) -> sur la fixture C15 ("Arbitrage Willy, ..." avec un A majuscule), le
# mutant n'extrait plus aucune citation et fait rougir FORME-NON-CONFORME, alors que l'original
# l'accepte toujours (rc 0).
MUT9_OLD='      while (match(s, /([Aa]rbitrage|[Aa]rbitrages|[Dd]écision|[Dd]écisions|[Dd]ecision|[Dd]ecisions)[^,.]{0,80},[^,.]{0,80},[^,.]{0,40}[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/)) {'
MUT9_NEW='      while (match(s, /(arbitrage|arbitrages|décision|décisions|decision|decisions)[^,.]{0,80},[^,.]{0,80},[^,.]{0,40}[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/)) {'
set +e
MUT9_PATH="$(make_mutant mut9 "$MUT9_OLD" "$MUT9_NEW")"
MUT9_STAT=$?
set -e
D="$(mk_repo mut9)"; B="$(rev "$D" HEAD)"
commit_msg "$D" "feat: hausse quelque chose (P41-D-02)

Arbitrage Willy, AskUserQuestion session principale, 2026-09-23"
if [ "$MUT9_STAT" -eq 1 ]; then komut 9 "insensibilite a la casse de l'extraction neutralisee" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT9_STAT" -eq 2 ]; then komut 9 "insensibilite a la casse de l'extraction neutralisee" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT9_PATH"; safe_run out_mut rc_mut --root "$D" --base-ref "$B"
  TARGET="$SCRIPT"; safe_run out_orig rc_orig --root "$D" --base-ref "$B"
  if [ "$rc_mut" -eq 1 ] && [ "$rc_orig" -eq 0 ]; then okmut 9 "$rc_mut" 1 "$rc_orig" 0
  else komut 9 "insensibilite a la casse de l'extraction neutralisee" "rc_mutant=1 rc_original=0" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-10 : retire le prefixe de registre obligatoire (fix ADR-075, 2026-09-24) -> le mutant
# redevient sensible a un D-NN NU, quel que soit son registre d'origine ; sur la fixture C16
# (identifiant D-02 de la mission de partition, sans aucune citation d'arbitrage), le mutant
# compte le commit et le fait rougir FORME-NON-CONFORME, alors que l'original l'exclut toujours
# (rc 0) — c'est la preuve que le resserrement au prefixe P41- est reel, pas seulement documente.
MUT10_OLD="MARKER_REGEX='[Aa]rbitrage Samuel|sur [Aa]rbitrage|[Dd]écision de Samuel|(^|[^0-9A-Za-z_-])P41-D-(0[1-9]|10)([^0-9A-Za-z_-]|\$)|[A-Za-z0-9_]+-DECISION:|REGLES_MAIN_FORCE_PUSH_SUPPRESSION'"
MUT10_NEW="MARKER_REGEX='[Aa]rbitrage Samuel|sur [Aa]rbitrage|[Dd]écision de Samuel|(^|[^0-9A-Za-z_-])D-(0[1-9]|10)([^0-9A-Za-z_-]|\$)|[A-Za-z0-9_]+-DECISION:|REGLES_MAIN_FORCE_PUSH_SUPPRESSION'"
set +e
MUT10_PATH="$(make_mutant mut10 "$MUT10_OLD" "$MUT10_NEW")"
MUT10_STAT=$?
set -e
D="$(mk_repo mut10)"; B="$(rev "$D" HEAD)"
commit_msg "$D" "docs(sonde): reprend le chantier lance par la mission D-02 (partition du planning)

Commit temoin : cite D-02 au sens de la mission de partition, pas du registre
de decisions de la phase 41. Aucun arbitrage engage."
if [ "$MUT10_STAT" -eq 1 ]; then komut 10 "prefixe de registre obligatoire neutralise" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT10_STAT" -eq 2 ]; then komut 10 "prefixe de registre obligatoire neutralise" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT10_PATH"; safe_run out_mut rc_mut --root "$D" --base-ref "$B"
  TARGET="$SCRIPT"; safe_run out_orig rc_orig --root "$D" --base-ref "$B"
  if [ "$rc_mut" -eq 1 ] && [ "$rc_orig" -eq 0 ]; then okmut 10 "$rc_mut" 1 "$rc_orig" 0
  else komut 10 "prefixe de registre obligatoire neutralise" "rc_mutant=1 rc_original=0" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

TARGET="$SCRIPT"

echo "== bilan : $PASS ok, $FAIL ko =="
if [ "$FAIL" -ne 0 ]; then exit 1; fi
exit 0
