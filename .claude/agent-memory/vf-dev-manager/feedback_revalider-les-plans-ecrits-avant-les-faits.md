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


**Le cas le plus net, mesuré le 2026-09-09 (Phase 39) : MÊME outil, MÊMES plans, 0 bloquant contre
5.** Le `vf-coder` qui venait d'écrire les trois plans a lancé `gsd-plan-checker` lui-même et rendu
« VERIFICATION PASSED, 0 blocker, 1 warning advisory ». Relancé par le manager **en contexte neuf**,
sur les mêmes fichiers au même commit, le même agent a rendu **5 bloquants et 6 warnings** — et un
second juge indépendant (traçabilité/falsifiabilité) a confirmé les mêmes trois défauts majeurs par
d'autres chemins de mesure.

Les bloquants n'étaient pas des jugements de goût, mais des **spécifications écrites contre une
arborescence imaginaire** : la clé d'extraction du filet de divergence (`^([0-9]+…)-`) ne matchait
**aucun** des 10 dossiers de phase du dépôt (tous en `VFDO-NN-slug`), le signal de cardinalité
rougissait sur un arbre **sain** (12 en-têtes de ROADMAP pour 10 dossiers, l'écart étant la
convention d'archivage permanente du dépôt), et la fixture de preuve commitait des dossiers
**vides** — que git ne versionne pas — rendant le critère d'acceptation inatteignable quelle que
soit la qualité du code.

**Why:** le producteur ne relit pas ses plans contre le disque, il les relit contre l'intention
qu'il vient de former. Le contexte producteur porte la justification (« cette ancre matche les
formes `05-` et `02.1-` de ce repo ») **et** l'erreur, si bien que le vérificateur qui partage ce
contexte valide la justification au lieu de la mesurer. Un juge frais n'a que le disque.

**How to apply:** ne jamais accepter un plan-check **lancé par l'agent qui a écrit le plan** comme
tenant lieu du nœud `plancheck` du plan de bataille — le relancer en contexte neuf, systématiquement.
Deux juges valent mieux qu'un quand le coût d'erreur est asymétrique : ici le second a trouvé, par
un autre chemin, que le run de preuve exportait la variable d'environnement qui **masquait** le
défaut qu'il prétendait mesurer. Fusionner et dédupliquer AVANT de rouvrir — un seul `reopen`, un
seul mandat de correction ciblée. Voir [[revue-obligatoire-cout-erreur-asymetrique]] et
[[descripteur-gsd-core-non-probant]].
