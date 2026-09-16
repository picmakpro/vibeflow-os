---
name: mutant-sibling-dependency-masks-vacuity
description: Un mutant de script copié en isolation (mktemp) peut échouer AVANT le code muté faute de dépendance sœur, rendant l'assertion vraie sans rien prouver
metadata:
  type: feedback
---

Règle : quand un test de mutation copie un script cible dans un répertoire isolé (`mktemp -d`)
pour produire un « mutant », vérifie que les dépendances runtime du script (scripts sœurs sourcés
via `$(dirname "$0")/...`) sont AUSSI présentes à cet endroit isolé — sinon le mutant échoue
avant même d'atteindre la ligne mutée, et une assertion permissive (`rc != code_attendu_conforme`
au lieu de `rc == code_attendu_mutant`) l'accepte comme si la mutation avait fait son travail.

Confirmé sur 39-01 (`plugin/conductor/scripts/tests/test-check-divergence.sh`, MUT-2) : la copie de
`check-divergence.sh` dans `$TMP/mutants/` omet `workstream-policy.sh` (résolu par
`$(dirname "$0")/../../planning-core/scripts/workstream-policy.sh`) ; le mutant sort systématiquement
en rc=2 (« non vérifiable ») AVANT d'appeler `check_s2`. Preuve définitive : une mutation SANS
RAPPORT avec `check_s2` (ex. ajouter un commentaire inoffensif après `exit 0`), placée dans le même
répertoire isolé, produit EXACTEMENT le même rc=2 — donc l'assertion ne discrimine rien.

Deuxième couche, indépendante, trouvée en corrigeant la première (sibling copié) : la mutation
ciblée (neutraliser le `return 1` final de `check_s2`) reste SANS EFFET même une fois le mutant
exécutable de bout en bout, parce que les deux sites d'appel font `check_s2 ... || true` — le code
de retour est jeté. Le signal réel qui pilote la sortie du script est l'accumulation dans le
tableau `FAIL_MSGS` (faite AVANT le `return`), pas la valeur de retour de la fonction. Un mutant
qui « neutralise la branche » en touchant le retour d'une fonction n'a de sens que si ce retour est
effectivement consulté par l'appelant.

**Why:** Phase 39 documente explicitement (39-01-PLAN.md Task 2) que « if the mutant's exit code is
unchanged (still 1), the mutation targeted dead code and is NOT opposable... a non-opposable mutant
must make THIS SUITE fail, not silently pass » — exactement le mode d'échec retrouvé ici, sauf que
l'assertion permissive (`-ne 1` au lieu de `-eq 0`) a laissé passer un mutant non opposable à
l'insu du script. Cinquième occurrence documentée du même anti-pattern « mécanisme qui a l'air
correct et ne peut pas rendre rouge pour la bonne raison » sur ce dépôt — voir
[[mutation-test-regression-claims]] et [[mirror-gate-superset-drift]].

**How to apply:** pour tout MUT-N jugé en revue, ne fais jamais confiance à l'assertion du harnais.
Reproduis le mutant EN DEHORS du harnais (bash direct) et confirme (1) qu'il atteint réellement le
code muté (pas d'échec précoce sur une dépendance manquante), et (2) qu'une mutation NON LIÉE placée
dans les mêmes conditions ne produirait pas le même verdict — si elle le produit, l'assertion est
vacueuse.
