---
name: feedback-execute-dont-trust-green
description: Dans vibeflow-os, un audit de sécurité doit reproduire par exécution réelle, jamais se fier à un compteur "X OK / 0 KO" ni à la seule lecture du code
metadata:
  type: feedback
---

Sur ce repo (vibeflow-os), une correction de sécurité ne se certifie jamais par lecture de code ni
par un compteur de tests vert. Il faut reconstruire le chemin d'attaque décisif et le rejouer pour
de vrai (dépôt git poisonné avec fixture malveillante, chaîne d'install complète
`vibeflow-update.sh install <module>` exécutée depuis ce dépôt, mesure du rc et des effets de bord
observables — fichier témoin écrit ou non, contenu réellement lu ou non).

**Why :** en Phase 23 (couplage GSD), le compteur "120 OK / 0 KO" a menti au moins cinq fois — des
tests de non-exécution dont le piège n'était jamais atteint (verts gratuits), une non-régression
mesurée fausse, un canari CI jamais rejoué sur un vrai runner. Un audit qui se contente de lire le
code de la mitigation et de constater "les tests passent" reproduit exactement ce mode de défaillance.

**How to apply :** pour toute mitigation de type "lecture jamais exécution" (T-23-0x-0y), construire
soi-même : (1) un dépôt git avec la fixture piégée à l'emplacement résolu en PREMIER par la cascade
de résolution du moteur (ex. `$root/.claude/gsd-core/bin/lib/...`, où `$root` = toplevel git du
dépôt courant — donc le dépôt piégé lui-même) ; (2) rejouer la chaîne combinée bout en bout
(pas les deux moitiés séparément) ; (3) vérifier positivement que le piège a été LU (son contenu
apparaît dans la sortie produite), pas seulement "non exécuté" — un piège jamais atteint ne prouve
rien. Voir aussi [[reference-rtk-proxy-quirks-vibeflow-os]] pour l'outillage de mesure sur ce poste.
