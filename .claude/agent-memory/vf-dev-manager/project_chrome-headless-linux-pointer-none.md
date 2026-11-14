---
name: chrome-headless-linux-pointer-none
description: Rouges « Linux seulement » du cockpit : (pointer: fine) faux, thème clair par défaut (prefers-color-scheme), /etc/gitconfig à filtre lfs ; jamais les polices
metadata:
  type: project
---

PR #187 (2026-11-02) : test-cockpit-responsive.sh était rouge en CI Linux à 1 024 px, vert sur macOS.
L'hypothèse du brief (« polices Linux plus larges ») était fausse : Inter était bien chargé. Mesure en
Docker (Debian + Chromium) : `matchMedia('(pointer: fine)')` vaut false sous Chrome headless Linux
(`pointer: none`). La règle souris de 01-vf-responsive.js ne s'appliquait donc pas. Correctif :
`not (pointer: coarse)`. Le témoin portable est le cas R8 (Chrome macOS lancé avec `--blink-settings`
sans pointeur).

**Why:** un écart macOS/Linux sur du CSS fait penser aux polices. Une media query d'interaction
(`pointer`, `hover`) diverge aussi, et rien ne la signale.

**How to apply:** devant un rouge CSS « Linux seulement », relever `matchMedia` pour pointer/hover
dans le Chrome de la CI (Docker local `node:24-bookworm` + chromium, ~15 min) avant tout
correctif typographique. Autre constat du même jour : `replay-ci-jobs.sh --job tests` (Phase 40.1)
rend « 0 rejouée » depuis le passage du job `tests` en matrice de shards (exit 2). Rejouer les
suites d'un module à la main ; la découverte complète, c'est la CI ou `scripts/ci-shard-suites.sh`.
Voir [[non-regression-sur-la-decouverte-complete]].

**Deux causes de plus, PR #216 (Phase 78, 2026-11-06)**, toutes deux dans les suites et pas dans le produit :
- Chrome headless Linux est en **thème clair** par défaut (`prefers-color-scheme`), et le thème du cockpit est
  « auto ». Une mesure « sombre » qui ne pose pas `data-theme="dark"` mesure le clair deux fois. Le mutant de
  contraste restait au-dessus de 4,5:1 en clair. L'hypothèse `pointer: none` a été écartée par mesure. Pour
  reproduire sous macOS : `Emulation.setEmulatedMedia` avec `prefers-color-scheme=light`.
- Le runner ubuntu-latest déclare `filter.lfs.*` dans `/etc/gitconfig`. `envGit` retire tout `GIT_*` hérité,
  donc le `GIT_CONFIG_NOSYSTEM=1` posé par une suite n'atteint jamais le git du serveur. Le cockpit y voit un
  filtre déclaré : « approximatif » est alors le comportement JUSTE. Un témoin « sans filtre » doit reposer
  l'isolation après `envGit` (emballage `git` en tête du PATH).
