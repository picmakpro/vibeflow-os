---
name: bash-gate-bug-classes-phase41
description: Quatre classes de bug confirmées par mutation/exécution réelle sur les gardes bash de Phase 41 (G-1/G-2/G-3) — à ressonder sur toute future garde in-repo de ce dépôt
metadata:
  type: feedback
---

Sur les gardes bash `set -uo pipefail` (jamais `-e`) de ce dépôt, quatre classes de bug se sont
avérées réelles et reproductibles en Phase 41 (revue du 2026-09-18, HEAD `b8f931e`) — à re-sonder
systématiquement sur toute future garde du même patron (`scripts/check-*.sh` + suite + étape CI) :

1. **Validation asymétrique base/HEAD sur `$((10#$var))`.** `check-baseline-arbitrage.sh` valide
   la parsabilité numérique de la baseline à la BASE (`BAD_LINE`, awk) mais jamais à HEAD. Une
   valeur non numérique à HEAD déclenche une erreur arithmétique bash non fatale (pas de `-e`) ;
   le flag booléen (`instr_over`) reste à sa valeur par défaut 0, et la hausse réelle n'est JAMAIS
   détectée — le script sort `CONFORME` (rc 0) au lieu d'un rc bloquant ou NON-VERIFIABLE. Prouvé
   empiriquement (commit d'un TSV avec une colonne instructions non numérique à HEAD → rc 0 au
   lieu du HAUSSE-SANS-ARBITRAGE attendu). Confirmé indépendamment par `gsd-code-reviewer` en
   parallèle — findings convergents sans coordination.
2. **`${#var}` dépend de la locale.** Un seuil de longueur minimale sur du texte accentué français
   (ex. la « raison » du trailer `Gate-Touche:` dans `check-gate-touche.sh`) compte des OCTETS
   sous `LC_ALL=C` au lieu de caractères — un texte de 6 caractères réels avec accents passe le
   seuil « 10 » sous locale C alors qu'il échoue sous UTF-8. Prouvé par rejeu du même commit sous
   `LC_ALL=en_US.UTF-8` (rc 1, MARQUEUR-MAL-FORME) puis `LC_ALL=C` (rc 0, DECLARE). Lié à
   [[feedback_locale-dependent-string-length]] si ce nom existe déjà ailleurs.
3. **`gh api ... 2>&1` fusionne stderr dans le JSON attendu.** `check-push-sans-pr.sh` capture la
   sortie de `gh api` avec `2>&1` avant de la faire parser par `jq`. Tout texte incident sur stderr
   (notice de mise à jour `gh`, avertissement quelconque) casse le parse JSON → `INDETERMINE` →
   rc 2 NON-VERIFIABLE — qui fait échouer (`exit 1`) l'étape CI « mesure réelle » sur push vers
   `main`, la seule étape à conséquence réelle de G-3. Reproduit avec un faux binaire `gh` qui
   écrit une ligne anodine sur stderr avant un JSON valide sur stdout. Variante du pattern
   [[feedback_2to1-merge-hides-stream-claim]] (fusion de flux), mais ici côté production (appel API
   réel), pas seulement côté test.
4. **Doctrine écrite avant un correctif tardif, jamais mise à jour.** `docs/ADR.md` (ADR-072) et
   `CHANGELOG.md` citent encore « cinq mutants opposables » pour G-2 alors que le commit `4ac7aa0`
   (« rejette les motifs Gate-Touche à virgule littérale, 6e mutant ») a porté la suite à SIX
   mutants — commit postérieur, dans l'historique, aux docs 41-18 qui le citent. `REQUIREMENTS.md`
   (mis à jour plus tard, en 41-19) est correct. Motif structurel : un correctif de revue de
   jointure qui touche le CODE n'entraîne pas automatiquement une relecture des comptes cités dans
   la DOCTRINE déjà committée — chercher spécifiquement les comptes numériques (mutants, bascules,
   assertions) dans ADR.md/CHANGELOG.md après tout commit `fix(...)` qui ajoute un cas de test.

**Why** : les quatre ont été confirmés par exécution réelle (pas seulement lecture), certains avec
un faux binaire `gh` ou une bascule de locale — jamais en se fiant à la déclaration de la suite
QUAL-01 elle-même, qui passait à 0 ko sur ces quatre axes puisqu'elle ne les couvre pas.

**How to apply** : sur toute future garde `scripts/check-*.sh` de ce dépôt, avant de faire
confiance à `bilan : N ok, 0 ko`, tester au moins : une valeur malformée injectée côté HEAD/nouveau
(jamais seulement côté base/ancien), une bascule de locale sur tout `${#var}`, un `2>&1` sur tout
appel `gh api`/réseau avant un parse JSON, et une relecture des comptes numériques cités dans
ADR.md/CHANGELOG.md après le dernier commit `fix` touchant une suite.
