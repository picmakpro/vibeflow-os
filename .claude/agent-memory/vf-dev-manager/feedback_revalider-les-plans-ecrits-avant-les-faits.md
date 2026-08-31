---
name: revalider-les-plans-ecrits-avant-les-faits
description: Un plan rédigé avant qu'un arbitrage ne soit tranché doit passer au plan-checker AVANT exécution — la passe coûte ~75k tokens et évite des tours d'exécution entiers
metadata:
  type: feedback
---

Quand une phase est planifiée d'un bloc puis exécutée plan par plan, **les plans d'aval ont été
écrits avant que les faits d'amont ne soient connus**. Ils portent la prémisse d'avant. Systématiser
un nœud `plancheck-NN` (agent `gsd-plan-checker`, **lecture seule**, parallélisable sans risque)
avant chaque exécution.

**Why:** mesuré sur la Phase 23 de vibeflow-os. La passe a trouvé **3 bloquants sur le plan 23-03**
(table d'allowlist logiquement contradictoire, motif adossé à un gate qu'on venait de dégazer,
et **zéro** occurrence de la décision qui conditionnait le plan dans son propre bloc `<context>` —
son exécutant ne l'aurait jamais vue) et **3 sur le plan 23-04**. Coût : ~75k tokens par passe.
Coût de l'alternative, constaté sur le plan 23-01 qui n'en avait pas eu : **3 tours d'exécution et
2 tours de revue**.

**Le vert interne du pipeline ne compte pas.** Mesuré Phase 31 (2026-08-16) : le `gsd-plan-checker`
lancé **par `gsd-plan-phase` lui-même** a rendu `PASSED, 0 blocker` sur 8 plans où deux
re-validations **externes** ont trouvé **11 bloquants**, dont deux à conséquence lourde (install
avortée pour presque tous les modules par interaction `set -e` × propagation de rc ; manifeste
affirmant des fichiers jamais écrits, relu ensuite pour **supprimer**). Poser le nœud `plancheck`
même — surtout — quand le pipeline s'est déclaré vert : le checker interne juge le plan qu'il vient
de produire.

**Une passe de correction introduit ses propres régressions.** Toujours Phase 31 : la correction des
11 bloquants en a fermé 9 et **créé 2 nouveaux**, sur le mécanisme que deux des findings touchaient
déjà. Toujours re-vérifier après correction, avec un mandat qui cherche explicitement les
régressions (contrats inter-plans désalignés, identifiants de cas en collision ou orphelins,
nouvelles assertions non falsifiables). Ne jamais marquer le nœud `done` sur la déclaration du
correcteur.

**How to apply:** dans le mandat du plan-checker, énumérer les **faits établis depuis la rédaction**
avec leur source vérifiable, et lui demander de **les re-vérifier lui-même** plutôt que de les
croire — sur cette phase, cinq prémisses d'affilée se sont révélées fausses, dont deux dans les
mandats que j'écrivais moi-même, et c'est à chaque fois quelqu'un qui a re-mesuré qui l'a rattrapé.
Lui donner aussi les **familles de défauts** déjà trouvées sur les plans voisins (sonde à token au
lieu de relation, vert à vide, piège de l'infinitif, critère vert avant écriture) : elles se
répètent d'un plan à l'autre parce que les plans ont été écrits dans la même passe. L'amendement
qui suit se fait par `gsd-planner` en mode **chirurgical** — lui interdire explicitement de
régénérer le plan, sinon il détruit le travail déjà validé.
