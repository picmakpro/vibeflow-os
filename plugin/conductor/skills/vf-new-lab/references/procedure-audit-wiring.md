# Ficelage des auditeurs — procédures livrées vérifiables (T4 du Lab Factory)

> Référence de `vf-new-lab` (phase Ficelage). Pour chaque **procédure générative** du manifeste (un
> workflow qui produit un output : contenu, dossier, séquence, livrable…), on **conçoit et matérialise
> sa structure d'audit** via le skill `audit-architecture`. Résultat : les procédures du lab sortent
> **déjà vérifiables**, pas « à auditer un jour ».

---

## Pourquoi à l'init (et pas après)

Iron Law de `audit-architecture` : *« un process générateur sans structure d'audit produit de la dérive
silencieuse ; un audit non FORCÉ (verdict bloquant) n'est qu'un avis. »* Si on attend, la procédure
tourne sans filet pendant des semaines. Le Lab Factory l'évite en câblant l'auditeur **au moment où la
procédure est créée**. C'est l'opérationnalisation de P8 (Évaluer) par process, dès la naissance du lab.

---

## Quelles procédures ? (pas toutes)

Seules les capacités de nature **procédure** marquées **« auditeur requis : oui »** dans le manifeste
(`capability-manifest.md`) — c'est-à-dire celles qui **génèrent un output** dont la qualité compte. Une
procédure purement interne/mécanique (ex. « archiver les jalons ») n'a pas besoin d'auditeur. Ne pas
sur-ficeler.

La section **Gates & EVALS** du brief (clarifiée en amont) dit déjà *quoi* doit être audité avant qu'un
output sorte — c'est l'entrée directe de cette phase.

---

## Mécanique : déléguer à `audit-architecture`

Pour chaque procédure générative, invoquer le skill `audit-architecture` qui **dérive depuis le brief**
les couches d'audit selon son primitif :

```
Dimension × Auditeur indépendant × Rubric × Verdict bloquant × Anti-boucle
```

- **Dimension** : sur quel axe on juge l'output (justesse, conformité, ton, complétude…).
- **Auditeur indépendant** : qui juge (≠ celui qui produit — séparation des rôles).
- **Rubric** : critères explicites de pass/fail.
- **Verdict bloquant** : un fail **arrête** la sortie (pas un avis cosmétique).
- **Anti-boucle** : éviter l'audit qui tourne en rond (nb de passes borné, escalade humaine).

`audit-architecture` choisit aussi le **mécanisme d'enforcement** sur le spectre **déterministe↔jugement**
(script de vérif vs auditeur LLM) selon la procédure.

> **Qui matérialise (ADR-031)** : `audit-architecture` **conçoit et propose** la structure — son Iron Law
> lui interdit de matérialiser seul, sans validation humaine. C'est donc **`vf-new-lab` qui matérialise**
> l'auditeur (agent/rule + point de blocage) en Phase 7 (Assemblage). Le **feu vert humain** est la
> **validation du manifeste en Phase 4** (l'utilisateur a validé les capacités, dont les procédures à
> auditer). Ainsi la promesse « procédures déjà auditées » tient sans violer ADR-031.

---

## Sortie de la phase

- Chaque procédure générative du lab a sa **structure d'audit matérialisée** (auditeur + verdict
  bloquant câblé), pas une intention en prose.
- Les auditeurs créés sont des agents/skills réels, câblés comme les autres à l'assemblage.
- Cohérence avec le filet global du lab : `vibeflow-validator` (Phase 4 audit-architecture) saura
  reconstituer ces structures lors des audits ultérieurs.

> Garde-fou : **pas de verdict bloquant → pas d'audit** (Iron Law audit-architecture). Si une procédure
> générative ressort sans point de blocage, c'est un trou — la traiter, pas la laisser passer.
