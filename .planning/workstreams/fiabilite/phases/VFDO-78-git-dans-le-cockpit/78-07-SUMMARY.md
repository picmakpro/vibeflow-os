---
phase: 78
plan: "07"
requirements-completed: [GITC-13]
key-files:
  modified:
    - plugin/cockpit/scripts/vf-cockpit-build.mjs
    - plugin/cockpit/skills/cockpit-moteur/scripts/lib/common.mjs
    - plugin/cockpit/amont/patches/scripts__lib__common.mjs.diff
    - plugin/cockpit/skills/cockpit-moteur/VENDORED.txt
    - plugin/cockpit/scripts/tests/test-cockpit-git-env.sh
---

# 78-07 — environnement git unique étendu au moteur vendorisé (GITC-13, P78-D-25)

Arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 : « Corriger avant la release (Recommandé) ». Rouges, mutants et vert : `78-07-RED-TRACE.md`.

- `run()` de `vf-cockpit-build.mjs` passe `envGit(lab, { config: configFiltres(filtresDeclares(lab, lab)) })` (import de `envEnfant` retiré, le PATH assaini est compris dans envGit).
- `git()` de `common.mjs` : première ligne `if (process.env.VF_COCKPIT_GIT_DURCI !== '1') return null;`, commentaire `// vibeflow P27`. Numéro retenu : **P27** (P26 était le dernier).
- Lignes `+` du diff amont (hors P10) : le commentaire P27 et la garde.
- `VENDORED.txt` : `PATCH scripts/lib/common.mjs P10,P27 …` avec description.
- Suite : section **E8** (le plan disait E6, mais E6 et E7 étaient déjà pris par la garde statique et les mutants de 78-01) : E8.0 à E8.4, M-GARDE, M-ENV-MOTEUR. 83 assertions, 0 échec.

## Conséquence du fermé par défaut

Un moteur lancé à la main hors de l'assemblage (sans `VF_COCKPIT_GIT_DURCI=1`) n'a plus de liste git : carte sans fichiers suivis, sans head. Retour arrière : retirer la garde. À consigner au README par 78-11. Le serveur (`skillScript` de serve.mjs) lance `plan.mjs` et `build.mjs` sans marqueur : `keepOutOfGit` y reçoit `null` (avertissement tu), suite serveur verte.

## Écarts

1. Section E8 et non E6 (collision de numéros).
2. `regenerer-patch` sans clone absorbe la garde dans l'amont : régénération avec un clone reconstruit (fichier courant sans la garde, P10 inversé).
3. Fixture E8 : un fichier de code ajouté au lab (la carte Code ne compte que le code).
4. `synchro.sh verifier` et V6.1 de `test-cockpit-vendor.sh` restent rouges pour un seul fichier : `assets/ui/77-vf-git-vue-detail.js` (78-10, sa ligne AJOUT n'est pas encore posée). L'écart de `common.mjs` est résolu. Le rouge disparaît quand 78-10 pose sa ligne.
