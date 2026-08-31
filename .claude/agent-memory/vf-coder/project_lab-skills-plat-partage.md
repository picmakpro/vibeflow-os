---
name: lab-skills-plat-partage
description: En lab installé, .claude/skills/ (et agents/) est plat et partagé entre tous les modules — un test qui balaie skills/vf-* juge les verbes des autres modules et vire rouge chez l'utilisateur
metadata:
  type: project
---

Un test de module qui itère sur `$MOD/skills/vf-*/` est vert en source et **rouge en lab
installé** : l'installeur pose les skills de **tous** les modules à plat sous `.claude/skills/`,
et le socle `conductor` est installé par défaut partout (`vf-calibrate`, `vf-new-lab`,
`vf-update`). Même piège sur `$MOD/agents/` : en lab, les `references/` d'un module y atterrissent
(`.claude/agents/<mod>-references/`), donc un grep récursif sur `agents/` les ramasse aussi.

**Why:** ce mode d'échec a coûté deux tours de revue sur l'étape 12 — d'abord sur la fixture T4
(cibles du module design absentes), puis sur un contrôle universel de descriptions qui jugeait les
verbes de `conductor`. À chaque fois : recette verte en source, suite rouge chez l'utilisateur.

Le piège joue **dans les deux sens**, et le second est le plus vicieux : `"$MOD"/references/*.md`
n'expanse **pas** en lab (les références y vivent sous `agents/<mod>-references/`, d'où la variable
`REFS_DIR` que ces suites résolvent déjà au démarrage). Le glob littéral non expansé est avalé par
`[ -f "$f" ] || continue` → **zéro fichier balayé et un message vert qui prétend le contraire**.
Mesuré en Phase 23 sur une disposition lab simulée : 0 référence ouverte d'un côté, 6 agents captés
de l'autre dont le voisin `gsd-executor.md` (qui porte légitimement les intitulés interdits).

**How to apply (corollaire, non négociable) :** toute boucle de balayage compte les fichiers
réellement ouverts et **échoue à zéro** (« un vert à vide n'est pas une garantie ») — c'est la
seule chose qui empêche le vert à vide de se reproduire ; et elle itère sur `$REFS_DIR` + une liste
fermée d'agents, jamais sur un glob en dur.

**How to apply:** dès qu'un test de `plugin/<module>/scripts/tests/` balaie `skills/` ou `agents/`,
(1) le borner aux objets **possédés** par le module — la liste de propriété se dérive d'un fichier
du module (pour `dev-orchestrator`, la colonne « Verbe » de `references/intent-routing.md`), jamais
d'une denylist des autres modules, qui pourrit au module suivant ; (2) prévoir le contre-poids : un
objet livré mais absent de la liste sort de l'audit **en silence** — vérifier l'égalité
livrés/déclarés (faisable en source uniquement) ; (3) **rejouer la recette en lab standard**
(installer conductor + planning-core + validator en plus), pas seulement en source ni avec les
seuls modules du chantier. Voir [[recette-grep-c-litteral]] et [[check-agents-scope]].
