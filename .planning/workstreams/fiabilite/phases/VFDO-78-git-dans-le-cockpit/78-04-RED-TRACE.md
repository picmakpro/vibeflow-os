# 78-04 — Trace des témoins rouges

Commande commune : `bash plugin/cockpit/scripts/tests/test-cockpit-git-entete.sh` (Chrome headless en CDP, port éphémère, jamais 4456).
Chaque rouge est joué sur la base, avant le code correspondant ; le vert suit dans la même tâche.

## Tâche 1 (tracer)

| Témoin | Assertion | Attendu | Obtenu sur la base (rouge) | Vert après |
|---|---|---|---|---|
| H1.1 | `enteteGit(<wt-a>)` | `ok\|depot\|feat/x\|wt-a\|false` | `` (module `vf-cockpit-git-entete.mjs` absent, l'import échoue) | oui |
| H1.1b | `enteteGit(<depot>)` | `ok\|depot\|main\|null` | `` (module absent) | oui |
| H2.1 | `#proj-name` sur `index.html`, cockpit construit dans le worktree | `depot` | `wt-a` (le nom du moteur, dossier du worktree) | oui |
| H2.1b | `.vf-git-ligne` contient `feat/x` et `wt-a` | `oui` | `non` (aucune seconde ligne) | oui |

## Tâche 2

Rouge joué sur la base de la tâche 1 (module, build et 76 de la tâche 1 ; ni `vfGit` dans `ecrirePage`, ni dans la carte Équipe, ni événements, ni ouvreur).
Journal du rouge : 29 réussis, 22 échoués (`78-04-rouge2b.log` du scratchpad). Les témoins H3.1, H5.1, H5.2 et les mutants étaient déjà verts :
la tâche 1 écrivait déjà l'état détaché, `textContent` et la sortie sans git ; leur valeur tient aux mutants (M-TEXTE, M-ABSENT), qui eux rougissent la cible.

| Témoin | Assertion | Attendu | Obtenu sur la base (rouge) | Vert après |
|---|---|---|---|---|
| H2.2 equipe | `#proj-name` de `/equipe.html` | `depot` | `wt-a` (la carte Équipe ne portait pas `meta.vfGit`) | oui |
| H2.2 equipe | seconde ligne de `/equipe.html` | contient `feat/x` | aucune seconde ligne | oui |
| H2.3a (témoin positif) | `project.html` réécrit par le direct après l'ajout d'un `01-02-PLAN.md` | 1 occurrence du texte du plan | 1 (vert : le direct réécrit bien la page) | oui |
| H2.3b | la page réécrite contient `"vfGit":{"etat":"ok"` | 1 | 0 (`ecrirePage` ne reprenait que `root` et `vfLogos`) | oui |
| H2.3c | `#proj-name` après réécriture | `depot` | `wt-a` | oui |
| H3.3 | ellipse, `title` complet, largeur sur la ligne (événement `vf-git:entete`) | `true` | `false` (l'événement n'était pas écouté) | oui, après passage de la fenêtre à 1440 px (la fenêtre headless par défaut est sous 1000 px et masque la ligne) |
| H3.4 | `vf-git:entete`, `vf-git:signal` (jeton, schéma) | `autre`, `1\|true`, `via-signal` | texte inchangé, aucun appel | oui |
| H3.2b | « Branche indisponible » + ouvreur | `Branche indisponible\|true` | texte inchangé, pas d'ouvreur | oui |
| H3.5 | `vf-git:basculer`, `aria-expanded`, `aria-controls` | `ligne,ouvreur` ; `true,true` ; `vf-git-tiroir` | listes vides, attributs `null` | oui |
| H4.1 (375, 700, 768, 999 px) | ligne masquée, ouvreur 44 × 44 en tête de `.hr` | `false\|true\|44\|44\|true` | `true\|false\|0\|0\|false` (la ligne restait visible sous 1000 px, aucune règle de masquage) | oui |

Note H4.1 : les largeurs 1000 et 1440 px étaient vertes d'emblée (ligne visible, pas d'ouvreur).
Largeur 1000 px : la requête media du viewer (`max-width: 999px`, ou tactile sous 1280 px) ne s'applique pas à 1000 px exactement en pointeur fin : à 1000 px la ligne est visible et l'ouvreur caché (frontière mesurée à 999 / 1000 px).
Le tactile à 1000 px n'est pas émulable avec `chrome-session.mjs` (aucune émulation de `pointer: coarse`).

### Mutants (tâche 2)

| Mutant | Altération | Rouge obtenu |
|---|---|---|
| M-DEPOT | `racine` pris de `rev-parse --show-toplevel` dans une copie du module | H1.1 : `depot` = `wt-a` ; H2.2 : `#proj-name` = `wt-m` (cockpit construit avec la copie) |
| M-TEXTE | `spBranche.innerHTML = texteBranche` dans une copie de 76, branche `<svg/onload=alert(1)>` | `svgEntete > 0` et texte de la ligne différent de la branche (un `svg` neuf dans l'en-tête) |
| M-ABSENT | `V.etat === 'absent' \|\|` retiré dans une copie de 76, lab hors dépôt | `.vf-git-ligne` et `.vf-nom` présents sans git |
