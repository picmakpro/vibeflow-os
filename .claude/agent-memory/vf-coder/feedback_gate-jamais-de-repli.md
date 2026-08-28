---
name: gate-jamais-de-repli
description: Un gate ne doit jamais retomber sur une vérification plus faible — KO explicite « non vérifiable » plutôt qu'un vert obtenu par repli ; et « exactement X » se mesure par égalité d'ensemble, jamais par liste noire
metadata:
  type: feedback
---

Deux règles que Samuel a imposées sur les sondes de la suite `dev-orchestrator` (Phase 23) :

1. **Aucun repli silencieux.** Si la sonde stricte ne s'applique pas à une cible, ne pas retomber
   sur une vérification plus faible (co-présence de tokens, présence nominale) : lever un **KO
   explicite** (« mapping non vérifiable »). Un vert obtenu par repli est indistinguable d'un vert
   mérité.
2. **« Exactement X » ⇒ égalité d'ensemble.** Une liste noire de graphies interdites ne ferme rien
   (elle a toujours une maille manquante) ; quand la doctrine dit « sont exactement … — rien
   d'autre », mesurer l'égalité entre l'ensemble mesuré et l'ensemble attendu.

**Why:** deux failles réelles, chacune laissant la suite à 87 OK / 0 KO alors que la doctrine était
inversée ou polluée. Le compteur d'entrées ne reconnaissait qu'une graphie (`` `human_needed` ``) et
manquait la graphie JSON (`` `statut: "human_needed"` ``) : 2 assertions sur 3 — dont le fichier de
référence — mesuraient en fait la co-présence sous un nouveau nom. Et l'ensemble « clos » du
minimum de reprise acceptait `journal_des_taches_executees`, absent de la liste noire.

**How to apply:** dès qu'une propriété est portée par plusieurs fichiers, vérifier que chacun
l'écrit sous la **même forme rhétorique** avant d'écrire une sonde unique — sinon implémenter une
sonde par forme (ici : énumération « étiquette → mapping » vs implication « prémisse ⇒ conséquent »)
et prouver par mutation **quelle** forme couvre **quelle** cible. Corollaire de
[[mutation-test-discriminating-cases]] : élargir un motif pour fermer une faille crée souvent un
faux rouge sur une rédaction licite — vérifier les deux sens avant de livrer.
