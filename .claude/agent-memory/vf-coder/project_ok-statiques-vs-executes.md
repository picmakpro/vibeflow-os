---
name: ok-statiques-vs-executes
description: Compter les assertions d'une suite shell — sites d'appel statiques `ok "` et libellés `ok` exécutés sont deux nombres différents, et les confondre a produit trois chiffres contradictoires sur la Phase 23
metadata:
  type: project
---

Dans `test-dev-orchestrator.sh` (module dev-orchestrator), **deux comptages d'assertions coexistent
et ne coïncident jamais** : les **sites d'appel statiques** (`ok "` dans le fichier — 90 à
`a7f1a37`) et les **libellés `ok` exécutés** (102). Les boucles (`for` sur les agents, sur les
scripts SC5, sur les scopes) font diverger les deux.

**Why:** trois tours de revue successifs de la Phase 23 ont annoncé « 87 → 90 », puis « 86 → 89 »
en déclarant le premier faux, sans jamais dire lequel des deux objets était compté. Re-mesure au
troisième tour : **87 → 90 est exact pour le compte statique**, « 86 → 89 » n'est reproductible
sous aucune décomposition, et le vrai désaccord n'était pas le chiffre mais l'objet mesuré.

**How to apply:** nommer l'objet avant de citer un nombre. Pour le compte statique, trois formes
**disjointes** partitionnent exactement le total, ce qui rend la mesure vérifiable :
`^[[:space:]]*ok "` + `&&[[:space:]]+ok "` + `\)[[:space:]]+ok "`. Pour les exécutions, extraire les
libellés du run en `awk` puis `sort -u`. Un chiffre transmis dans un mandat se **re-mesure avant
d'être écrit dans un document normatif** — cf. [[diff-proxifie-utiliser-comm]] pour la méthode de
comparaison d'ensembles, et [[libelles-ok-geles]] pour la contrainte sur ces libellés.
