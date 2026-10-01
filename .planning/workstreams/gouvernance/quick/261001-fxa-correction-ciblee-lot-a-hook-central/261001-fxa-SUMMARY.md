---
quick_id: 261001-fxa
status: complete
description: Correction ciblée lot A de la Phase 45 (hook central et commandes annexes) — B1/H1, H2, M1+m5, m2, H4, m3, m4+B3, B3, M2, M1 (canary), B1 (basse)
base: e13a426
commits: [adc64256, 21e0893d, 75f37562, 98073cd5, a6b86f35, 2e81cbf9, f3528924]
---

# Quick 261001-fxa — correction ciblée lot A (hook central et commandes annexes)

Source : revue de phase (vf-reviewer) et audit de sécurité (vf-auditer) sur `e13a426`. Décisions du manager vf-dev-manager,
2026-10-01, renversables. Chaque constat : test rouge d'abord, correctif, test vert, mutant qui retire le seul correctif et rougit
(trace imprimée par la suite). Aucun cas existant supprimé, aucun mutant retiré. Exécution directe par vf-coder dans le worktree de
mission (aucun exécuteur isolé lancé, aucun `gsd-tools state`, ni STATE.md ni ROADMAP.md touchés).

| Id | Correctif | Tests (rouges avant) | Mutants tués | Commit |
|----|-----------|----------------------|--------------|--------|
| B1/H1 | `.planning` dans (ou sous) un composant `.planning` jamais racine de lab (hook, poser-verdict, canary, `vf_tight`), casefold | R-IMB-01..05, A19-A23 (six modes), banc `imbrique-*` | IMB-HOOK, IMB-POSER, IMB-CANARY, IMB-CASEFOLD, IMB-HOOK-CANARY, EXT-12, EXT-12D | adc64256 |
| B1 (basse) | `PX=0` ferme en panne (hooks.json) | E37-E39, E09b (« none » -> « tight »), E40 ; EXT-2 et EXT-4 rejoués sur E40 | PX-1, PX-1D | 21e0893d |
| m2 | `decider` : dérogation consommée seulement si la décision finale est un passage grâce à elle | R-DEROG-09 | DEROG-GLOBALE | 75f37562 |
| H4, m3, m4+B3 | poser-verdict : refus des Cc/Zl/Zp, forme d'unité, `flock` sur le PLAN.md, argv UTF-8 | R-VERDICT-06..09 | VERDICT-CONTROLES, -FORME-UNITE, -VERROU, -UTF8 | 98073cd5 |
| B3 | deroger-gate : droits du journal jamais élargis, argv UTF-8 | R-DEROG-10 | DEROG-FCHMOD, DEROG-UTF8 | a6b86f35 |
| H2, M1+m5 | parseur de définitions linéaire/borné, échéance interne (code 73), transport effacé, version active du plugin | R-DEFS-01..05, R-VERSION-01 | PUCE-REGEX-FM, PUCE-REGEX-CHAMP, PUCE-EQUIVALENCE, ECHEANCE-ARMEE, ECHEANCE-DELAI, ECHEANCE-PARENT, TRANSPORT-EFFACE, PLUGIN-INSTALLED, PLUGIN-HAUTE, PLUGIN-TRI | 2e81cbf9 |
| M2, M1 (canary) | canary : commande de référence stricte (embarquée), constantes d'armement absentes = signal | R-CAN-09..11, R-CAN-12 (lab installé) | CANG-RECONNUE, CANG-ARMEMENT-SIGNAL, CAN-RECONNUE | f3528924 |

## Décisions d'implémentation à relire (renversables)

- **Amendement de P45-D-01a** (décision du manager vf-dev-manager, 2026-10-01) : le chemin d'un candidat de racine est exclu dès qu'un de ses
  composants est `.planning` (casse ignorée). Limite : un lab situé sous un ancêtre nommé `.planning` n'est plus vu.
- **Commande de référence du canary embarquée** (`COMMANDE_REFERENCE`) : l'installeur ne pose pas `hooks.json` dans le lab. La suite
  (R-CAN-11) compare la constante à `hooks.json` octet pour octet ; R-CAN-01 de la suite installée la compare à ce que l'installeur pose.
  Option `--reference=<fichier>` réservée aux suites (jamais lue des réglages) : les commandes-témoins (R-CAN-02, R-CAN-08, MUT-CAN-*) passent
  leur propre commande.
- **Code 73** (échéance interne du cœur ou lanceur disparu) ajouté au contrat des codes du lanceur ; la commande enregistrée le traite comme tout
  code non nul (ferme sous adhésion, silence ailleurs).
- **`PX=0` ferme sans condition** : un chemin à échappement JSON non géré refuse en panne même hors lab (le doute tombe du côté du refus) ;
  la limite d (Unicode échappé dans le lab lui-même, E09b) est fermée.
- **Plugins** : repli sur la plus haute version du cache ; plusieurs `installPath` : la plus haute ; `installPath` hors `~/.claude/plugins` ignoré.
- Délai mesuré sur ce poste (appel avec agent de plugin, HOME réel) : 0,05 s contre 0,12 à 0,40 s avant.

## Hors périmètre, non touché

- L'autre moitié de M1 (protéger le script du hook et les réglages par G6) : attend l'arbitrage de Willy.
- `docs/HOOKS-CONTRAT-SORTIE.md` : décompte inchangé (31 entrées), document NON édité. Deux libellés de la ligne 31 (`check-gates-alive.sh`)
  sont périmés : « 4 (… table d'armement absente …) » devient un signal (code 0), et la liste des signaux ne cite ni « commande enregistrée
  non reconnue » ni « constantes d'armement absentes ou illisibles ». À reporter par le manager.
- `test-rejeu-gates.sh` et `test-recalc-planning.sh` (lot B) : non rejoués.
