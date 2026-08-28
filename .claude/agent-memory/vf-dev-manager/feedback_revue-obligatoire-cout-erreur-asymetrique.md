---
name: revue-obligatoire-cout-erreur-asymetrique
description: Sur un artefact à coût d'erreur asymétrique, commander la revue même si le worker la juge disproportionnée et même si sa suite de tests est verte — une suite verte ne prouve pas que ses cas ne sont pas tautologiques
metadata:
  type: feedback
---

Quand un plan nomme lui-même un **coût d'erreur asymétrique** (une erreur dans un sens produit un
dégât silencieux et durable), la revue de code de l'étage devient **non négociable** — même si
`vf-coder` rend `passed` en expliquant que la revue serait disproportionnée, même si la suite est
verte à 100 %.

**Why:** Phase 13, 2026-07-26. `discover-unintegrated-docs.sh` (155 L) livré en TDD avec 12 tests
verts ; `vf-coder` a sauté la revue, script court et contrat mécanique. Je l'ai commandée quand même
au motif inscrit dans le plan (un faux verdict déclenche une écriture `--mode merge` dans le
`.planning/` réel d'un utilisateur). Elle a trouvé **2 bloquants reproduits empiriquement** : motif
de citation non borné à gauche (`design.md` déclaré « cité » parce qu'un registre mentionnait
`redesign.md` → disparition silencieuse de la sortie) et échappement ERE partiel (seul le `.`
échappé → un `[` non fermé rendait le motif absorbant).

La cause profonde est plus instructive que les bugs : **le cas de test censé couvrir le bornage était
tautologique**. Il opposait `zeta.md` à `zeta-design.md` — jamais une sous-chaîne l'un de l'autre, le
`-design` intercalé cassant toute continuité. Un `index()` naïf sans aucun bornage l'aurait passé.
Le point le plus sensible du script avait donc une couverture **nulle** derrière un décompte vert.
Le vérificateur l'a confirmé ensuite par **tests de mutation** : 3 mutants tués sur 4 après correctif,
alors que la suite d'origine n'en tuait aucun sur cet axe.

**Récidive Phase 19, 2026-07-28 — une forme nouvelle et plus coûteuse à détecter.** `ensure-deps.sh`
appelait son propre garde-fou `inject-mcp-tools.sh --verify` **sans `--force`**, alors que l'injection
juste au-dessus le passait (obligatoire, la cible ne porte pas le flag `vf-mcp-consumer`). Le garde-fou
sortait donc **toujours en 3** : jamais « conforme », jamais « serveur manquant » — il ne pouvait rendre
aucun verdict en production. **Trois étages de vérification l'ont laissé passer** : revue de code (PASS),
gate de portabilité (macOS + Ubuntu + Debian, tout vert), audit sécurité (6/6 angles PASS). Seul le
vérificateur goal-backward l'a vu, en **mutant le bloc livré** : supprimer *tout* le bloc de vérification
laissait la suite à 73 OK / 0 KO.

Deux causes nommables, réutilisables comme sondes :
1. **Le compte rendu prouvait une présence, pas un comportement** — `grep -c 'verify' → 7` cité comme
   justification de câblage. Un décompte d'occurrences ne dit rien de l'exécution.
2. **Les tests exerçaient une forme que la production n'émet jamais** — les cas invoquaient
   `inject-mcp-tools.sh --force --verify` à la main, alors que le chaînage réel émettait `--verify` seul.
   Un test qui n'exerce pas la commande réellement émise est tautologique, quelle que soit sa richesse.

**How to apply:** au moment du `dag.sh add`, repérer dans le plan les mentions de coût asymétrique,
d'écriture chez l'utilisateur, ou de « risque n°1 » — et poser d'emblée un nœud `review` distinct du
nœud `execute`, plutôt que de s'en remettre au jugement du worker. Ne jamais lire « N tests verts »
comme une preuve de couverture : demander au juge de vérifier que les cas **discriminent** (un cas
qui passerait avec une implémentation naïve ne teste rien), ou de le prouver par mutation. Corollaire
de flux : quand les correctifs de revue ne font pas dériver le **contrat public** de l'artefact,
inutile de rouvrir les nœuds aval qui ne consomment que ce contrat.
