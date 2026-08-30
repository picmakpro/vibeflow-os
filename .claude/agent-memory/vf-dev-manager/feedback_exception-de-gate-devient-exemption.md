---
name: exception-de-gate-devient-exemption
description: Une exception déclarée dans un gate exempte de la propriété que le gate protège — vérifier qu'elle ne porte que sur la FORME, jamais sur le résultat observable
metadata:
  type: feedback
---

Quand un gate accepte une liste d'exceptions, exiger que l'exception porte **uniquement sur la
forme du remède**, jamais sur **la propriété que le gate existe pour garantir**. Sinon le fichier
exempté disparaît du radar avec la bénédiction du vert.

**Why:** Phase 38, 2026-08-30. Un gate `check-description-fidelity.sh` a été posé pour empêcher que
des agents soient rejetés par kimi. Il sort `PASS — 74 fichiers, 0 violation, 3 exception(s)`,
`rc=0` — **pendant que `vibeflow-design` est injoignable sur kimi**. L'exception disait vrai sur la
forme (« contient `"` ET `'`, aucune forme quotée ne traverse les deux consommateurs ») mais elle a
silencieusement valu **exemption d'atteignabilité**. Le gate mesurait un **proxy** (égalité parseur
YAML ↔ regex gsd-core), pas le **résultat observable** (le rôle charge-t-il ?). Les deux ne
coïncident pas : un fichier peut être « non convertible sans perte » **et** cassé.

**How to apply:** devant tout gate à liste d'exceptions, poser deux questions. **(1)** L'exception
porte-t-elle sur le remède ou sur le symptôme ? Exempter du *quotage* est légitime ; exempter de la
*validité YAML* ne l'est pas — la seconde est la raison d'être du gate. **(2)** Le gate mesure-t-il
le résultat observable, ou un proxy de laboratoire ? Si c'est un proxy, une exception le vide deux
fois. Corollaire opérationnel : ne jamais conclure « corrigé » sur la sortie d'un gate qu'on vient
de créer — **re-mesurer le résultat réel** (ici : la re-mesure kimi a rendu 30/31 quand le gate
disait 0 violation). Voir [[check-agents-vacuous-green]], [[liste-de-cas-ne-ferme-pas-une-classe]]
et [[mesure-juste-attribution-fausse]].
