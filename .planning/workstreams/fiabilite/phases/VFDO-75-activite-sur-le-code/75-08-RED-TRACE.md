# 75-08 — trace du rouge : le sélecteur de lentilles, le menu, le panneau, le radar

Régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale) : mutants levés, sauf ceux de la chaîne XSS (tâche 3).
Les chemins sont relativisés : `<tmp>` pour le dossier de travail, `.` pour la racine du dépôt.

## Tâche 1 : le sélecteur et la lentille « Points chauds »

Base du rouge : `95f9b75a` (tête de la phase avant 75-08 : 75-01 à 75-07, 79-16 à 79-18, pile de surcouches de la 80). Mesure sur une copie de `git archive 95f9b75a plugin/cockpit`
où l'on a seulement posé `test-cockpit-activite-lentilles.sh`, `chrome-activite-lentilles.mjs` et `fixtures/test-cockpit-activite-lentilles/` (`SECTIONS=t1`).

| Rouge | Commande | Attendu | Obtenu | Bonne raison |
|---|---|---|---|---|
| module des tables absent | `bash <copie>/plugin/cockpit/scripts/tests/test-cockpit-activite-lentilles.sh` | `L0 : le harnais lit le module` (code 0) | `ENOENT … skills/cockpit-moteur/assets/ui/75-vf-activite-tables.js` ; `BILAN : 0 PASS, 1 FAIL` | le fichier n'existe pas sur la base : `ls ui/75-vf-activite*` ne rend rien |
| interface absente (tables posées par `TABLES_JS`) | `SECTIONS=t1 TABLES_JS=<tmp>/tables-nouveau.js bash <copie>/…/test-cockpit-activite-lentilles.sh` | `L1 : Lentille : Aucune|menu|false|false|Lentille d'activité sur le code` | `mesure indisponible : attente de « sélecteur posé et première lecture » dépassée (90000 ms)` ; `BILAN : 8 PASS, 1 FAIL` | la mesure attend `document.getElementById('btn-lentilles')` (sonde S1) : sur la base le bouton n'existe pas ; les 6 témoins purs (L2, L1b) sont verts parce que `TABLES_JS` leur donne le module |

Même mesure sur la tête de la tâche 1 : `29 PASS, 0 FAIL` (49 s). L'échec « module absent » a donc deux explications séparées et nommées : fichier absent (table pure), bouton absent (page).

Écart : le code de la tâche 1 (`75-vf-activite.js`, `-tables.js`, `-menu.js`) et celui des tâches 2 et 3 (`-panneau.js`, `-collisions.js`, états, phrases) ont été écrits en un jet avant les témoins de ces tâches (mêmes fichiers) ;
les témoins de la tâche 2 et de la tâche 3 sont rouges sur la base pour la même raison (voir leurs sections ci-dessous, ajoutées avec elles). Les mutants des tâches sont levés par le régime allégé.

## Tâche 2 : le menu complet, ses états exacts, le clavier, les trois autres lentilles et leurs mots

Base du rouge : `95f9b75a` pour le navigateur ; tête de la tâche 1 (`323a1bf6`) pour l'état intermédiaire. Suite sur la copie de la base, avec les témoins de la tâche 2 (`SECTIONS=t2`, `VF_CDP_ECHEANCE_MS=20000`).

| Rouge | Attendu | Obtenu | Bonne raison |
|---|---|---|---|
| tables sans couplage, gardes, empreinte (`sed` sur une copie du module : `const TABLES = { chauds: tableChauds };`), `VM_SEUL=1 TABLES_JS=<tmp>/tables-sans-trois.js` | `L0 : le harnais lit les tables` (code 0) | `L0 : le harnais a échoué (code 1)` : `rows('couplage', …)[0]` est `undefined` | la table de couplage n'existe plus : l'observation `L8.noeud-et-vide` lit sa première rangée ; la pile des autres lentilles est la même |
| base, navigateur (`TABLES_JS=<tmp>/tables-nouveau.js`), 38 témoins purs verts puis `L5` | `lens-boite|Lentille,Agents,Légende de la lentille|true,true,true|lens-titre lens-legende lens-radar|Lentille d'activité sur le code` | `mesure indisponible : attente de « sélecteur posé et première lecture » dépassée (20000 ms)` ; `BILAN : 38 PASS, 1 FAIL` | pas de `#btn-lentilles` ni de `#lens-menu` sur la base (même cause que la tâche 1, témoins de la tâche 2 : L5 à L12) |

Même mesure sur la tête de la tâche 2 : `67 PASS, 0 FAIL` (`SECTIONS=t2`, 43 s). Écart : le code de la tâche 2 (états, clavier, légendes) est dans les fichiers livrés par le commit de la tâche 1 ; l'état intermédiaire est donc une copie mutée, pas un commit antérieur.
