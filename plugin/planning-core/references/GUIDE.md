# GUIDE — Doctrine du socle de planning universel

> Référence chargée on-demand par le skill `vf-planning`. Explique **pourquoi** le tronc commun
> existe, **ce qui est invariant**, et **comment adapter** sans biaiser la logique métier d'un lab.

---

## 1. Le problème qu'on résout

Un lab perd le fil entre deux sessions. La connaissance « où va-t-on, où en est-on, qu'a-t-on
décidé et pourquoi » se dilue dans des conversations qui se dégradent, ou s'éparpille dans des docs
qui dérivent. Ce n'est pas un problème de *mémoire* (capitaliser le passé) — nos registres
`.claude/memory/` font déjà ça. C'est un problème de **planning** : tenir un **état présent + une
intention future** reconstructibles depuis le disque.

Le socle `.planning/` répond à ça avec une règle simple : **l'état vit dans des fichiers, pas dans la
conversation.** On le relit au démarrage de chaque session plutôt que de compter sur le contexte.

## 2. Ce qui est universel vs ce qui s'adapte

L'erreur à éviter : prendre la forme d'un `.planning/` **dev** (issue de GSD) et la plaquer sur tous
les labs. Un lab de contenu, de vente ou de montage de dossier a une **autre logique métier** —
lui imposer des `codebase/`, des « sprints de code », des exigences techniques le **biaise**.

La bonne approche sépare deux couches :

- **Le tronc commun (invariant)** = la *logique de discipline*, vraie pour tout travail structuré :
  une charte, un état courant, une trajectoire, une trace des étapes, une archive des jalons.
  → Les 7 artefacts (voir SKILL.md).
- **L'extension de domaine (adaptable)** = ce qui est propre au métier du lab. Elle prend la **forme
  du métier**, jamais une forme importée :

  | Métier du lab | Extension typique (exemples, non imposés) |
  |---|---|
  | Dev / code | `codebase/` (architecture, stack, conventions, tests) |
  | Contenu / éditorial | `editorial/` (angles, calendrier, lignes, formats) |
  | Vente / growth | `pipeline/` (séquences, ICP, objections, offres) |
  | Montage de dossier | `dossiers/` (pièces, exigences réglementaires, statuts) |
  | Design / identité | `design/` (système, références, déclinaisons) |
  | Recherche | `corpus/` (sources, hypothèses, protocoles) |

  Ces noms sont des **exemples**. Le skill dérive l'extension du métier réel, en dialogue si besoin —
  il n'a pas de catalogue figé à appliquer.

## 3. La clé de voûte : STATE.md

Si un lab ne devait avoir qu'**un** fichier, ce serait `STATE.md`. Il porte la position courante, le
focus, l'avancement, les todos, et un pointeur vers la charte. C'est lui qu'on relit en premier à
chaque session. **Il doit rester frais** — un STATE périmé est pire que pas de STATE.

Les autres artefacts gravitent autour : `PROJECT` (le cadre stable), `ROADMAP` (la trajectoire),
`REQUIREMENTS` (le détail vérifiable), `phases/` (la trace fine), `MILESTONES` (l'archive).

## 4. Adapter la rigueur, pas seulement la forme

Tous les labs ne méritent pas la même cérémonie. Un lab créatif ponctuel n'a pas besoin d'exigences
à IDs ni de découpage en phases — ça l'alourdirait sans valeur. D'où les **3 profils** (voir
`PROFILES.md`) : on prend le minimum qui sert, on monte en rigueur seulement quand le métier le
justifie. **La rigueur est un curseur, pas un défaut maximal.**

## 5. Ne pas cannibaliser la mémoire

`.planning/` (avant/présent) et `.claude/memory/` (capitalisation/passé) sont **complémentaires**, pas
concurrents. Le pont est défini dans `bridge-memory.md`. Règle d'or : **une information a un seul
propriétaire.** Les décisions structurantes *durables* vivent en ADR/DECISIONS ; les décisions
*courantes du projet* vivent dans `PROJECT.md` et remontent en mémoire quand elles deviennent
structurantes. Jamais les deux à la fois.

## 6. En une phrase

> Récupérer la **logique** d'une documentation opérationnelle chirurgicale — pas un gabarit dev à
> imposer. Le tronc est commun ; le métier décide du reste.
