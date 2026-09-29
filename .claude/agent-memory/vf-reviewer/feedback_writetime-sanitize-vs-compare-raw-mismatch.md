---
name: feedback_writetime-sanitize-vs-compare-raw-mismatch
description: quand un correctif ajoute un assainissement au moment de l'ECRITURE d'une valeur, vérifier que toute comparaison/dédoublonnage en amont compare la même forme (assainie), sinon la comparaison "brut vs relu-sur-disque-donc-assaini" échoue en silence
metadata:
  type: feedback
---

Un correctif qui introduit une fonction d'assainissement structurel (espaces/tabulations/`=`
réduits à un jeton) appliquée SEULEMENT au moment de formatter la ligne écrite (ex.
`_formater_ligne_journal`) casse silencieusement toute logique de dédoublonnage/idempotence
en amont qui compare la valeur BRUTE de l'exécution courante contre des valeurs relues depuis
le disque — puisque ce qui est sur disque est déjà passé par l'assainissement, et ce qui vient
d'être recalculé ne l'est pas encore. Le lookup échoue dès que le champ contient un caractère
assaini (espace, `=`), et la ligne est réinjectée à CHAQUE exécution suivante au lieu d'être
déduplique.

**Why** : trouvé et reproduit en Phase 44 (correction ciblée lot 2, `recalc-planning.sh`,
`_jeton_journal`/`_formater_ligne_journal` vs `lignes_a_journaliser`). Le champ `tentative`
(recopié tel quel depuis `VERDICT.md`, sans contrainte de charset — contrairement à `chemin`
qui est filtré par un motif `NOM_UNITE` restrictif en amont) était le vecteur réel, pas
seulement un payload adversarial de test : n'importe quel `tentative:` humain contenant un
espace suffit. Le test du projet (`sonder_l2`) ne vérifiait que la forme d'une écriture
UNIQUE (`_formater_ligne_journal` produit un enregistrement lisible) — jamais le round-trip
par la fonction de dédoublonnage sur deux exécutions successives, exactement où le défaut vit.
Un `VERIFICATION.md` avait marqué "11/11, Aucun gap" sur cette base incomplète.

**How to apply** : dès qu'un diff ajoute/étend un assainissement de valeur appliqué au moment
de l'écriture, chercher TOUTE comparaison de cette même valeur ailleurs dans le fichier
(dédoublonnage, cache, index) et vérifier si elle compare des valeurs brutes ou assainies.
Reproduire un round-trip à deux exécutions (écrire, puis recalculer sur le même état) avec une
valeur qui déclenche l'assainissement (espace, `=`, etc.) plutôt qu'une valeur "propre" — les
suites existantes testent presque toujours avec des valeurs déjà propres et ne voient rien.
Voir aussi [[feedback_mutation-test-regression-claims]] et [[feedback_summary-aggregate-counts-verify]].
