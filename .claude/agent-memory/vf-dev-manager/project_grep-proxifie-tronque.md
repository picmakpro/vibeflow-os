---
name: grep-proxifie-tronque
description: Sur cette machine `grep` est proxifié et tronque silencieusement ses sorties — 31 lignes rendues sur 102 lors d'une extraction de libellés
metadata:
  type: project
---

`grep` est proxifié (hook RTK) et **tronque silencieusement** ses sorties : lors de la Phase 23,
un `grep '✓' | sed` sur la suite de tests a rendu **31 lignes sur 102**, sans aucun avertissement.
Même famille que [[diff-proxifie-faux-identique]] (« Files are identical » sur des fichiers qui
diffèrent).

**Why:** un audit qui fait confiance à ce `grep` conclut à une disparition massive d'assertions —
ou, pire, à leur présence. C'est précisément l'outil qu'on emploie pour prouver qu'aucune assertion
n'a été retirée en douce, donc l'erreur est auto-masquante.

**How to apply:** dans tout mandat de worker qui doit **dénombrer** ou **comparer des ensembles**
(libellés `ok`, assertions, entrées de table), impose `awk` pour l'extraction et `sort -u` + `comm`
sur listes matérialisées ; `rtk proxy <cmd>` pour contourner le filtre quand la commande brute est
nécessaire (`rtk proxy git status`). Ne jamais accepter un comptage issu d'un `grep` piped.

⚠️ **Le remède a son propre piège : `awk` multi-fichiers doit utiliser `FNR`, jamais `NR`.**
`awk '/motif/{print FILENAME":"NR}'` sur **plusieurs** fichiers rend un numéro de ligne **cumulé**
sur tout le flux, donc des ancres **fausses mais plausibles**, sans aucun signal. Mesuré en Phase 23 :
`23-02-PLAN.md:815` et `23-04-PLAN.md:1772` au lieu de `:378` et `:462` — décalages de +437 et +1310.
Le nom de fichier, lui, reste juste : seul le numéro ment. Un `xargs`/`find` qui découpe en lots
aggrave le cas (le compteur repart par lot). Toute ancre consignée via un `awk` multi-fichiers en
`NR` est **suspecte et doit être re-dérivée** — même famille que [[base-de-diff-derivee-du-parent]].
Corollaire de mandat : exiger que toute sonde **prouve sa non-vacuité** en retrouvant un site connu
d'avance, aux bons numéros ; une sonde qui rate le site témoin ne conclut rien.

⚠️ **Troisième variante, mesurée en Phase 23 : ne JAMAIS compter les lignes de la sortie d'une
commande proxifiée.** Le proxy **injecte sa propre ligne de statut**, donc un `git stash list`
**vide** rend `1` à un `awk 'END{print NR}'` — le compteur invente une entrée qui n'existe pas.
J'ai conclu à tort qu'un worker avait laissé un stash après un `git stash pop` en worktree partagé,
et j'ai failli traiter une perte de données imaginaire. Sens inverse du piège de troncature, même
cause : **la sortie proxifiée n'est pas la sortie de la commande.**
**How to apply:** matérialiser dans un fichier (`cmd > f`) *puis* compter le fichier, ou passer par
`rtk proxy`. Vaut pour tout comptage qui porte un verdict — `git stash list`, `git status --short`,
listes de fichiers. Et vaut aussi pour **mes propres sondes de manager**, pas seulement pour les
mandats de workers : c'est là que je me suis fait prendre.

⚠️ **Quatrième variante, mesurée en Phase 31 : `wc` piped rend parfois des valeurs fausses.**
`wc -c < M | tr -d ' '` a rendu **`0`** sur un fichier de **38 octets** (`od -c` et `stat -f %z`
concordants à 38), et `wc -l < M` un `0` sur un fichier d'une ligne. **Non reproductible à la
demande** — une sonde isolée sur le même fichier a ensuite rendu 38 et 1 correctement, pipe inclus.
Je le consigne tel quel, sans prétendre à un défaut systématique : ce qui compte est que la classe
est la même que les trois ci-dessus, et qu'un critère d'acceptation qui compte via `wc` peut
**valider à tort**. **How to apply:** préférer `awk 'END{print NR}'` à tout `wc` piped dans un
critère de plan ou une sonde de verdict.

⚠️ **Cinquième variante, la plus bête et la plus coûteuse : `$?` APRÈS UN PIPE rend le code de sortie
du DERNIER maillon, pas celui du gate.** Mesuré Phase 31 : `bash scripts/check-machine-paths.sh 2>&1 |
awk 'NR<=4'` puis `echo "EXIT=$?"` a rendu **0** alors que le gate sortait **1** — j'ai lu le succès
d'`awk`. J'ai conclu « gate vert » et enchaîné ; c'est la **revue** qui a trouvé la CI rouge.
**How to apply:** un gate se lance **nu**, jamais dans un pipe : `bash gate.sh >/dev/null 2>&1;
echo $?`. Si le rendu doit être filtré, capturer le rc **avant** de filtrer
(`bash gate.sh > f 2>&1; rc=$?; awk … f`). Classique de shell, mais je l'ai commis **en cherchant
précisément cette classe de défaut** — donc l'automatisme ne va pas de soi.

**Le mode d'échec commun aux cinq variantes** : une commande de comptage cassée rend `0`, et `0`
est indiscernable de « la propriété est vraie ». C'est pour ça qu'un critère de comptage doit
**prouver qu'il peut rougir** (contrôle positif sur une fixture fautive) avant de compter pour un
verdict — voir [[liste-de-cas-ne-ferme-pas-une-classe]].

Voir aussi [[re-deriver-les-listes-d-une-revue]] et [[artefacts-descriptifs-non-testes]].
