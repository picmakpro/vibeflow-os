# 71-FIX-N12 — le lanceur ne lit plus le PATH brut

Correction ciblée du re-audit n°3 (sur `7bb14f15`). Rétablit P71-D-29 (N2), « le lanceur n'exécute jamais un binaire du lab »
(arbitrage Samuel, AskUserQuestion session principale Claude Code, 2026-11-04).

## Constat

`resoudreBinaire(nom)` lisait le PATH brut du lanceur à trois endroits de `vf-cockpit.mjs` : `ps` (`estNotre`, donc `stop` et la relance),
l'ouvreur (`open` / `xdg-open`) et `python3` (contrôle E4). Un PATH qui porte un dossier ABSOLU du lab (`<lab>/bin`, cas de `npm run` ou de direnv)
faisait exécuter `<lab>/bin/open` et `<lab>/bin/ps`. `envEnfant` retire ces dossiers, `gitCommonDir` s'y conformait déjà ; pas le lanceur.

## Correction

- `vf-cockpit.mjs` : `pathSur()` = `envEnfant(LABV).PATH` (LABV posé dès que la racine du lab est connue). Les trois lectures passent par lui.
- L'ouvreur est lancé avec `env: envEnfant(LABV)` : `xdg-open` cherche ses auxiliaires dans son PATH.
- `vf-cockpit-paths.mjs` inchangé : la ligne 137 est la signature de `resoudreBinaire` (défaut `process.env.PATH` pour les appelants sans lab) ; son seul appelant avec un lab, `gitCommonDir`, passe déjà le PATH assaini.
- P71-D-03 tient : le shell du terminal garde le PATH d'origine, `VF_COCKPIT_PATH_ORIGINE` n'est pas touché ; `vf-cockpit-env.mjs` (fichier H-1 de main) non modifié.

## Preuves

- `test-cockpit-terminal-lanceur.sh` L16b : `open`, `xdg-open`, `ps`, `python3` piégés dans `<lab>/bin`, PATH en tête puis en queue ; aucun marqueur, cockpit ouvert par l'ouvreur factice absolu (jamais l'ouvreur réel).
  Cas `python3` : le seul est celui du lab, il est écarté (« python3 introuvable »), le cockpit s'ouvre sans terminal.
- Rouge sur HEAD (`83d4bb44`, copie du module hors arbre) : L16b en tête et python3 en échec (marqueur créé par le binaire du lab) ; vert après : 108 PASS / 0 FAIL.
- Mutant `M-PATH-BRUT` (PATH brut aux trois lectures, ouvreur à l'environnement hérité) : rougit L16b.
- Mutants existants réalignés sur le nouveau texte : `M-SANS-PYTHON3`, `ouvrenomnu` (retire aussi l'`env` assaini, sans quoi le mutant n'exécutait plus rien), `psfinal`.
- Limite : le cas « en queue » passe aussi sur HEAD, car l'`open` et le `ps` système le précèdent dans le PATH ; il reste un témoin de non-régression.
