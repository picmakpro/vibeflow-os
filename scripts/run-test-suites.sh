#!/usr/bin/env bash
# run-test-suites.sh — découvre, exécute et COLLECTE les suites de tests du dépôt.
#
# Pourquoi ce script existe (dette BACKLOG « formats de sortie hétérogènes entre les 12 suites »).
# Le collecteur vivait en YAML inline dans la CI et ne regardait QUE le code de sortie. C'était sûr
# — aucun faux KO — mais aveugle sur le défaut n°1 du dépôt : une suite qui sort 0 SANS avoir
# exercé un seul cas est un vert, et personne ne le voit. Le lire dans la prose était exclu : six
# formats textuels coexistaient sur douze suites, et le piège n'y est pas seulement le faux KO
# (motif absent) mais le faux VERT par sous-chaîne — « résultat : N OK / 0 KO » est un préfixe
# littéral de « résultat : N OK / 0 KO / 0 SKIP ». D'où un contrat MACHINE, émis EN PLUS du libellé
# humain que chaque suite garde tel quel :
#
#     RESULT: pass=<N> fail=<N> skip=<N>
#
# Quatre issues, jamais un vert par défaut (QUAL-01) :
#   1. suite verte + contrat cohérent            -> PASS
#   2. suite rouge (rc != 0)                     -> FAIL, comme avant
#   3. contrat PRÉSENT mais MALFORMÉ ou incohérent avec le code de sortie (fail>0 alors que rc=0,
#      ou pass+fail=0 : un vert à vide)          -> FAIL BRUYANT, jamais un silence
#   4. contrat ABSENT                            -> suite « hors contrat », comptée et affichée,
#      PAS un échec — la conversion du parc est un ratchet, pas un big bang.
#
# Le ratchet : MIN_UNDER_CONTRACT est le nombre de suites qui DOIVENT émettre le contrat. Il ne
# descend jamais. Convertir une suite de plus, c'est monter ce plancher dans le même commit — et
# une suite qui cesserait d'émettre fait rougir la CI au lieu de disparaître des radars.
set -u

ROOTS="${VF_TEST_ROOTS:-plugin scripts}"
MIN_UNDER_CONTRACT="${VF_MIN_UNDER_CONTRACT:-13}"

# `::group::` / `::error::` ne sont interprétés que par GitHub Actions ; en local ce sont des
# lignes de texte inoffensives. On les garde inconditionnellement plutôt que de brancher sur $CI :
# une sortie qui change de forme selon l'environnement est une sortie qu'on ne peut pas déboguer.
suites="$(find $ROOTS -type f -path '*/tests/test-*.sh' 2>/dev/null | sort)"
count="$(printf '%s\n' "$suites" | grep -c . || true)"
echo "== $count suite(s) découverte(s) =="
# Assertion de découverte non vide (F13) : 0 suite = échec, jamais un vert.
if [ "$count" -eq 0 ]; then
  echo "::error::aucune suite de tests découverte (motif */tests/test-*.sh) — refus de rendre un verdict vide"
  exit 1
fi

fail=0
under_contract=0
total_pass=0
total_fail=0
total_skip=0

while IFS= read -r t; do
  [ -n "$t" ] || continue
  echo "::group::$t"
  out="$(bash "$t" 2>&1)"; rc=$?
  printf '%s\n' "$out"

  # DERNIÈRE occurrence : une suite peut légitimement imprimer d'autres lignes après son bilan
  # (test-inject-mcp-tools.sh le fait), et une fixture peut contenir le mot ailleurs.
  line="$(printf '%s\n' "$out" | grep '^RESULT: ' | tail -1)"

  if [ -z "$line" ]; then
    # Issue 4 — hors contrat. Le code de sortie reste seul juge, comme avant ce script.
    if [ "$rc" -ne 0 ]; then
      echo "::error::FAIL(rc=$rc) $t"
      fail=$((fail + 1))
    else
      echo "PASS $t (hors contrat)"
    fi
    echo "::endgroup::"
    continue
  fi

  under_contract=$((under_contract + 1))
  p="$(printf '%s' "$line" | sed -n 's/^RESULT: pass=\([0-9][0-9]*\) fail=\([0-9][0-9]*\) skip=\([0-9][0-9]*\)$/\1/p')"
  f="$(printf '%s' "$line" | sed -n 's/^RESULT: pass=\([0-9][0-9]*\) fail=\([0-9][0-9]*\) skip=\([0-9][0-9]*\)$/\2/p')"
  s="$(printf '%s' "$line" | sed -n 's/^RESULT: pass=\([0-9][0-9]*\) fail=\([0-9][0-9]*\) skip=\([0-9][0-9]*\)$/\3/p')"

  # Issue 3a — contrat MALFORMÉ. Un imparsable n'est JAMAIS toléré en silence : c'est très
  # exactement le mode de panne que ce contrat existe pour supprimer.
  if [ -z "$p" ] || [ -z "$f" ] || [ -z "$s" ]; then
    echo "::error::CONTRAT ILLISIBLE $t — ligne obtenue : [$line]"
    fail=$((fail + 1))
    echo "::endgroup::"
    continue
  fi

  total_pass=$((total_pass + p))
  total_fail=$((total_fail + f))
  total_skip=$((total_skip + s))

  # Issue 3b — VERT À VIDE : la suite sort 0 sans avoir exercé un seul cas. Invisible pour un
  # collecteur qui ne lit que le code de sortie, et c'est le défaut n°1 du dépôt.
  if [ "$((p + f))" -eq 0 ]; then
    echo "::error::VERT À VIDE $t — contrat déclare 0 cas exécuté (rc=$rc)"
    fail=$((fail + 1))
    echo "::endgroup::"
    continue
  fi

  # Issue 3c — contrat et code de sortie qui se contredisent : des KO comptés sur une sortie 0
  # (une suite qui oublie de propager son échec), ou l'inverse.
  if [ "$f" -gt 0 ] && [ "$rc" -eq 0 ]; then
    echo "::error::CONTRAT INCOHÉRENT $t — $f échec(s) déclaré(s) mais rc=0"
    fail=$((fail + 1))
    echo "::endgroup::"
    continue
  fi

  if [ "$rc" -ne 0 ]; then
    echo "::error::FAIL(rc=$rc) $t — $f échec(s) sur $((p + f)) cas"
    fail=$((fail + 1))
  else
    echo "PASS $t — $p cas"
  fi
  echo "::endgroup::"
done <<EOF
$suites
EOF

echo "== bilan : $count suite(s), $fail échec(s) =="
echo "== contrat : $under_contract/$count suite(s) — $total_pass cas verts, $total_fail rouges, $total_skip ignorés =="

# Le ratchet. Une suite qui cesse d'émettre le contrat disparaîtrait des radars sans ce plancher.
if [ "$under_contract" -lt "$MIN_UNDER_CONTRACT" ]; then
  echo "::error::RÉGRESSION DU CONTRAT — $under_contract suite(s) sous contrat, plancher $MIN_UNDER_CONTRACT"
  echo "  Le plancher ne descend jamais : soit la suite manquante a perdu sa ligne RESULT:, soit"
  echo "  la conversion recule. Rétablir l'émission, ou justifier explicitement la baisse."
  fail=$((fail + 1))
fi

[ "$fail" -eq 0 ]
