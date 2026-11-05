# 78-03 — trace des rouges (commandes à copier du tiroir Git)

Commande commune : `bash plugin/cockpit/scripts/tests/test-cockpit-git-commandes.sh` (module `vf-cockpit-git-commandes.mjs` absent).

## Tâche 1 — témoins C1 rouges AVANT le module

| Témoin | Assertion | Attendu | Obtenu |
|---|---|---|---|
| C1.0 | les 17 noms hostiles existent comme branches (`update-ref`) | 17 | 17 (vert d'emblée : c'est le témoin positif de la fixture, pas du module) |
| C1.1 | `bash -c "$(cmdSwitch nom)"` bascule sur la branche, aucun marqueur | liste d'échecs vide | les 17 noms en échec (module absent, `cmd.mjs` rc 4) |
| C1.2 | idem sous zsh | vide | 17 en échec |
| C1.3 | `cmdCd` dossier piégé et `-rel` sous bash et zsh | vide | `[bash:piege][bash:tiret][zsh:piege][zsh:tiret]` |
| C1.4 | `citer` rejoué à l'octet, 17 chaînes x 2 shells | vide | 34 échecs |
| C1.5 | refus -> `null`, acceptés -> commande | vide | tous les refus en `nul-attendu` (rc 4 au lieu de 3) |
| C1.6 | échantillon généré (150 noms, bash, zsh, sh) | 3 shells sans échec | 0 (`GEN module absent`) |
| C1.6b | portée : >= 100 exécutées, >= 10 armées, >= 5 refusées | 3 | 0 |
| C1.7 | `AFFICHAGE_REFUSE` = `nettoie` sur U+0000..U+10FFFF | `76\|0` | vide |

Résultat : `Résultats : 1 PASS, 8 FAIL`, exit 1. Les rouges tiennent à l'absence du module (rc 4 de `cmd.mjs`), ce qui est le rouge voulu de la base.
