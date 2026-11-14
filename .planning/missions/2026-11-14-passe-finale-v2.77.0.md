# Passe finale avant v2.77.0 — rapport de mission (2026-11-14)

Origine : arbitrage Samuel, message session principale, 2026-11-14 (« une passe complète avant la fusion vers la branche de release »).
Branche `fix/passe-finale-v2.77.0` (PR à venir vers `integration/cockpit-audit`). Temps A : lecture et mutants des gardes ; B1 : corrections,
L2/L3/L5 ; B2 : fusion de `f68185ee`, L4, fichiers écartés, régie. Relecteurs : agents frais non auteurs ; revue des corrections par `vf-reviewer`.

## Constats par lot
- **MAJ-1** lecteurs de texte du lab super-linéaires (gardes, blocages, questions-champs, project, git-details, code-vf, health) : `f799b6bed` (suite rouge) + `37a60b678`.
- **L1 confinement et jeton** : MAJ-2 jeton par préfixe `c6417dc12` ; MAJ-3 préfixe sans séparateur `ff44ab411` ; MAJ-4 index écrit via un ancêtre lié `3b24d6dfd` ; mineurs corrigés `59382067e`, `d061e34ff`, `bcd45f5af`, `ea5dc16f4` (DL-01), `c22aee4f8`.
- **Couverture** : MAJ-5 D8.9 `76db23e1c` ; MAJ-6 D10.7 `4c16a0d84` + `e4a84e9a8` ; CSP de base exacte `b8f1e4896` ; F.1 `f166782d2`.
- **L2/L3 coquille et direct** : L3-03 élu sans flux réel `c0b97d939` ; L3-01/N5.1 pastille `5d3742008` ; L2-01 lecture d'onglet bornée `4d763cb2f`.
- **L5** : L5m-01 scan du moteur hors du lab `e16af8dd7` + `0b32c4a1e` (régression NFD trouvée par la revue) ; L5m-03 `57cd6fc79` ; L5u-01 lanceur `b170539e6` ; L5u-02 terminal `06f3002ab` ; L5o-01 six modules non livrés par `/vf-update` `0d0b3948b`.
- **B2** : L4a-01 âges des agents `efe6cfe86` ; L4b-01 fichiers à t `0e99656ac` (+ L4b-02 `4efb781ae`) ; L4c-01 repère de visite `87eadc92b` ; L4c-02 « rien de nouveau » à tort `adc701831` ; EX-01 écouteurs média `6fbe80d03` + `d1826c584`.
- **§ 2 bis** : cliquet d'observateurs élargi `ec4d81bb2`, `1de825b89`, `33fcabc32` (arbitrage Samuel, message session principale, 2026-11-14, option a) ; clic réel vers Équipe `f6ba40dc0` ; W4.1 `fe7569ce4` + `7156cf54d` (seuil inchangé) ; EK5.1/EKR1 déjà corrigés `5ab5cdc0e`.
- **Mineurs** : tous versés en un sujet unique de `.planning/BACKLOG.md` (« Passe finale v2.77.0 : mineurs »), palette comprise (non reproduite).
- **Ouverts** : AM7.6 (`test-cockpit-cycle-serveur.sh`) rouge local identique sur la base, la CI tranche ; TEMP-12 cochée sur la CI verte de la tête du lot (run 43610046755, `1ac5bae5`, arbre identique à `f68185ee`).

## Mutants (cible : mutants / tués d'emblée / survivants ; tous les survivants tués ensuite par un cas ajouté)
| Cible | Mutants | Tués d'emblée | Survivants |
|---|---|---|---|
| jeton, CSP | 5, 5 | 4, 4 | 1, 1 |
| chemins, liens | 5, 5 (dont 1 équivalent) | 3, 3 | 2, 1 |
| D10.7, D8.9, F.1 | 5, 5, 5 | 2, 4, 4 | 3, 1, 1 |
| coquille : ordre, relance, onglets | 5, 5, 5 | 5, 2, 5 | 0, 3, 0 |
| magasin : abonnements, patch, rejeu, reconnexion | 5, 5, 5, 5 | 4, 1, 4, 4 | 1, 4, 1, 1 |
| régie : questions, modèle, rendu/pied | 5, 5, 5 | 5, 2, 3 | 0, 3, 2 |
| observateurs `02-*` | 7 | 3 | 4 trous de couverture, au BACKLOG |
Total : 85 mutants, 59 tués d'emblée, 1 équivalent, 25 survivants, tous tués ensuite par un cas ajouté. À part : 7 mutants des observateurs `02-*`, 3 tués, 4 trous de couverture versés au BACKLOG.

## Notes SOBR-04 (pour les notes de release)
- Commande : `git diff v2.76.0..<sha final> -- plugin/` (hors `plugin/cockpit/scripts/tests/**`) ; relecteurs : agents frais non auteurs, un par lot, revue des corrections par `vf-reviewer`, vérification par un nœud distinct.
- L1a : serveur jetable, en-têtes Host/Origin hostiles, jeton absent, faux ou passé en paramètre d'URL — 403 partout, 200 avec jeton — code 0.
- L1c : `node sonde-boucle.mjs` (texte de CI de 400 Kio) — boucle bloquée 10 687 ms — 0 (MAJ-1). L1d : `node sonde-planning.mjs state 120000` — 22 608 ms contre 15 ms au témoin — 0.
- L1b : `bash s5-git.sh` — aucune marque posée, témoin git brut : marques posées — 0. L3 : `node sonde-elu-abandonne.mjs` — 0 vol, 10 pongs, 0 flux réel — 0 (L3-03).
- L5m : index forgé + `node scan.mjs` — contenu hors du lab dans `scan.json` — 0 (L5m-01). L5o : install v2.76.0 puis update — « déjà à jour », agent non recopié — 0 (L5o-01).
- L4c : `node sonde-memoire.js` — écriture refusée dès 133 phases (8 197 octets) — 0 (L4c-01). EX : `sonde-mq.sh` sous Chrome — écouteurs 4 à 28 sur 6 onglets, 0 retrait — 0 (EX-01).
- V : gates du job CI (version-sync, gate-touche, baseline-arbitrage, ci-shard-suites, machine-paths) — 0 ; 24 suites vertes, AM7.6 rouge identique sur la base.

## Preuves E6
```json
{"preuves":[
{"verdict":"gate:version-sync","commande":"bash scripts/check-version-sync.sh","exit_code":0,"sha":"ea5dc16f40e03f2d5bc227dcb68e960ca4c5405e"},
{"verdict":"gate:machine-paths","commande":"bash scripts/check-machine-paths.sh","exit_code":0,"sha":"ea5dc16f40e03f2d5bc227dcb68e960ca4c5405e"},
{"verdict":"ci-tete-du-lot","commande":"run 43610046755 (CI verte, arbre identique à f68185ee)","preuve":"amont","exit_code":0,"sha":"1ac5bae5"},
{"verdict":"ci-pr","commande":"à venir","exit_code":null,"sha":null}
]}
```
