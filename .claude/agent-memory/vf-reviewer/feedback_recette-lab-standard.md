---
name: recette-lab-standard
description: Toute recette « en lab installé » d'une suite de tests de module doit inclure conductor (socle obligatoire), pas seulement les modules du chantier
metadata:
  type: feedback
---

Quand je revois une suite de tests de module (ex. `test-dev-orchestrator.sh`), la disposition
« lab installé » de la recette doit installer **conductor** (et son filet : planning-core,
validator, consolidator) en plus des modules du chantier — pas seulement les deux modules
concernés.

**Why:** en lab, `.claude/skills/` est **plat** et partagé par tous les modules ; toute boucle
`for … in $MOD/skills/vf-*/SKILL.md` audite donc aussi les verbes des **autres** modules.
conductor est le socle *obligatoire* installé par défaut dans chaque lab (README.md, note
« At install since v2.13.0 ») : ses verbes (`vf-calibrate`, `vf-new-lab`, `vf-update`) sont
présents chez tous les utilisateurs. Le piège « vert ici, rouge chez l'utilisateur » s'est
rouvert deux fois d'affilée sur l'étape 12 (vague 3) parce que la recette s'arrêtait aux modules
du chantier : d'abord sur la fixture T4 (cibles design), puis sur le contrôle universel T12(b).

**How to apply:** dès qu'un test itère sur un glob `vf-*`/`gsd-*` sans allowlist de propriété,
exiger (1) que le contrôle soit scopé aux verbes possédés par le chantier — allowlist dérivée de
la doctrine, jamais une denylist des autres modules — et (2) une passe de recette en lab standard
avec conductor installé. Un contrôle qui juge le contenu d'un module tiers est un faux positif
par construction (D-01 : ces fichiers ne sont pas modifiables depuis ce chantier).
