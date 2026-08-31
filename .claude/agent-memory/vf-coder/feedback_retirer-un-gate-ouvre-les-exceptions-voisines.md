---
name: retirer-un-gate-ouvre-les-exceptions-voisines
description: Retirer un gate devenu sans objet rouvre les exceptions que les gates VOISINS s'étaient accordées parce qu'il existait — chercher ces exceptions avant de retirer.
metadata:
  type: feedback
---

Avant de retirer un gate devenu sans objet, **chercher les exceptions que les gates voisins se
sont accordées parce que ce gate existait**. Elles deviennent des trous béants, et le retrait se
présente comme un nettoyage.

**Why :** sur la Phase 23, `T25b` gardait la brique Cadrage ; `T25` s'était donc explicitement
**borné aux briques Plan/Exécution**, avec une fixture imposant qu'un bloc Cadrage portant
`--auto` reste **VERT**, et un libellé d'`ok` disant « Cadrage licite ». Retirer `T25b` seul
supprimait la **seule** garde du Cadrage — dans un plan dont un critère de succès proclamait
« aucune garde ré-ancrée n'est plus faible que celle qu'elle remplace ». Le défaut a survécu à ma
propre rédaction et n'a été vu qu'en re-validation.

L'argument piège, que j'ai écrit noir sur blanc et qui est **faux** : « supprimer la cause est plus
fort qu'un gate ». Supprimer la cause traite un **état atteint une fois** ; un gate traite la
**non-régression**. Les confondre produit exactement le faux vert qu'on croit fermer.

**How to apply :** avant tout retrait de gate — `grep` l'identifiant du gate dans TOUT le fichier
de test, pas seulement son bloc. Les renvois hors bloc se classent en trois familles, et une seule
se supprime : (1) le **bloc** lui-même → part ; (2) les **commentaires de périmètre** des gates
voisins (« X relève de <gate> ») → se **réécrivent**, ils documentent une décision de périmètre qui
change ; (3) les **données de test** (fixtures, motifs de prémisse morte) → **intouchables**, elles
gagnent même en valeur. Puis : élargir le voisin, **retourner** sa fixture d'exception (jamais la
supprimer), et corriger les libellés d'`ok` devenus sur-déclarants. Cf. [[feedback_gate-jamais-de-repli]],
[[feedback_libelles-ok-geles]], [[feedback_mutation-test-discriminating-cases]].
