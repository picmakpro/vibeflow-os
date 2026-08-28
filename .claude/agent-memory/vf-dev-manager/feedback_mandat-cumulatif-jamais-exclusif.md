---
name: mandat-cumulatif-jamais-exclusif
description: Un mandat formulé en « jamais X, fais Y » fait supprimer une garantie existante ; exiger Y EN PLUS de X
metadata:
  type: feedback
---

Quand je commande un correctif de gate, formuler l'exigence en **cumul** (« Y **en plus de** X »),
jamais en exclusion (« jamais X, fais Y »). Un worker consciencieux lit l'exclusion comme un ordre
de suppression.

**Why:** Phase 23, `exec-01`. J'avais écrit « écris l'assertion contre l'ensemble réellement
déclaré, **jamais** contre une liste de noms figée dans le test ». Le worker a supprimé la boucle
`for champ in 'plan_id' 'checkpoint' 'gate' 'attendu'`. Cette boucle était morte pour 3 noms mais
**vivante pour `plan_id`** : le rename `plan_id`→`plan_ref` faisait 1 KO avant, 0 KO après. J'avais
commandé une régression de couverture, trouvée par la revue au tour suivant. Le reviewer l'a
qualifiée de « faux dilemme » — les deux propriétés étaient cumulables depuis le début.

**How to apply:** avant d'écrire une consigne négative dans un mandat, demander « qu'est-ce que la
formulation actuelle attrape que la mienne n'attraperait plus ? ». Si la réponse n'est pas « rien »,
écrire les deux. Vaut pour toute consigne de remplacement d'un mécanisme de vérification : un gate
qu'on remplace doit d'abord être mesuré sur ce qu'il couvre réellement. Voir
[[revue-obligatoire-cout-erreur-asymetrique]] et [[artefacts-descriptifs-non-testes]].
