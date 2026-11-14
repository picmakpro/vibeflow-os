---
phase: 76
plan: "01"
requirements-completed: [TRAC-01, TRAC-02, TRAC-03, TRAC-04, TRAC-11]
---

# 76-01 — Chaîne d'exigences (fonctions pures) : SUMMARY

## Livré

Cinq modules neufs sous `plugin/cockpit/scripts/` (tous sous 160 points de code par ligne, 120 lignes au plus) et deux fonctions extraites :

- `vf-cockpit-frontmatter.mjs` : `valeurImbriquee`, `listeImbriquee` (premier bloc `---`, 400 lignes, jamais d'évaluation).
- `vf-cockpit-trace-ledger.mjs` : `traceDuLedger`, `statutFait`, `citationsLigne` ; constante `ETAPE` dérivée de `reTraceabilite` (forme « Étape N », TRAC-11).
- `vf-cockpit-trace-collecte.mjs` : `traceDePhase`, `lireTrace`, `projeterTrace`.
- `vf-cockpit-trace-chaine.mjs` : `MAILLONS`, `ligneExigence`, `lignesDePhase`, `vueExigence`.
- `vf-cockpit-trace-bilans.mjs` : `bilanExigences`, `vuePhase`, `vueJalon`.
- `vf-cockpit-avancement.mjs` : `ligneStatutRecette`, `recetteFaite` exportées (ajoutées en fin de fichier, deux lignes de `reste()` et la ligne d'en-tête changées, aucune ligne déplacée) ; verdicts de `reste()` inchangés (quatre formes, tableaux avant et après identiques, voir `76-01-RED-TRACE.md`).

### Forme de projection livrée (pour 76-04)

`projeterTrace(graphe, trace, { jalonActif, couper })` pose, sans monter la version du schéma : `nodes[i].trace` sur chaque nœud `phase`
(`plans[{ id, fichier, exigences|null, criteres{n,liste}|null, summary{fichier,exigences|null}|null }]`, `correctifs[]`, `verification{fichier,status|null,cites}|null`,
`recette{fichier,statut|null,faite,cites}|null`, `preuves[{sorte,fichier,plan|null,statut|null}]`, `lignesSansExigence`),
`meta.vf.trace = { exigences[{ id, ws, coche, phase|null, phasesParPlan, statut|null, fait, rattachement, libelle, fichier, cites{decisions,adrs,nues} }], etapes|null, ledgers }`,
`meta.vf.jalonActif`. `lireTrace` rend `{ phases: Map, ledger: { statuts, lignes, lignesSansExigence, etapes, n }, exigences }` (le champ `exigences` est ajouté au contrat du plan, c'est lui que `projeterTrace` projette) ;
ses `ledgers` sont `[{ ws ('' plat, nom, '*' archive), fichier, txt }]` et `lire` reçoit un chemin absolu.

### Écarts et précisions (aucun ne change un contrat consommé par une autre phase)

- Écart : `vueExigence` rend `{ ...ligneExigence, exigence: {…}, noeud }` (forme du retour non précisée par le plan) ; 76-05 la consommera telle quelle ou l'adaptera.
- Écart : un maillon `contradiction` porte un champ `code` (`cochee-sans-summary`, `complete-sans-plan`), repris dans `mot.code` quand la contradiction est le mot de ligne ; `contradictions` ne liste que celles qui ne sont pas le mot.
- Écart : `maillonsEnDefaut` = `{ plan, summary, verification, recette, manquants, nonLisibles, contradictions }` (compteurs par maillon avec chevauchement, plus comptes par état, `manquants` hors contradiction).
- Écart : `listeImbriquee` plafonne à 64 éléments par défaut, donc `criteres.n` ne dépasse jamais 64 ; les preuves de VERIFICATION et de recette sont celles du premier fichier trié (les maillons).
- Fixture : dans la suite, REQ-08 de la phase 7 n'a pas de SUMMARY (sinon la mention « non cochée, SUMMARY lu » s'ajoutait à la mention visée) ; première capture rouge de T2 faite avec un harnais dont les lectures se recouvraient (compteur perdu dans une substitution de commande), rejouée proprement contre le code de la tâche 1 : la RED-TRACE porte la capture corrigée (19 rouges).
- Garde de largeur V4c.9a (160 points de code, signalé par le manager de la phase) : les quatre modules, le lecteur de frontmatter et la ligne ajoutée à `vf-cockpit-avancement.mjs` sont ramenés sous 160 dans le même commit que la tâche 3 (commit dédié non séparable de ce code).
- À verser par la jointure : TRAC-02 du ledger cite encore les quatre causes en « trait corail » alors que P76-D-15bis n'en garde que deux (ledger à reformuler par la jointure, pas par ce plan).

## Rituels levés

- rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale) — les douze mutants (M-MANQUE-VERIF, M-RECETTE, M-CITE-NUE, M-SUMMARY-CLE, M-NIVEAU, M-NONLISIBLE, M-ABSENCE-ROUGE, M-ECRITURE, M-COMPLETE-3, M-DECOMPTE, M-AUTRE-JALON, M-DEDUIT) ne sont pas joués ; le seul témoin exigé est le rouge d'assertion consigné avant chaque code.
- rituel levé : régime allégé (même consigne) — pas de triple passe, pas de rejeu suite par suite, pas de gate de compteur (`check-version-sync.sh` § 9 reste rouge jusqu'à 76-08, attendu).

## Suites jouées (une fois ; projet-graphe et avancement avant le reflux des lignes longues, qui ne change aucune logique, la suite de la chaîne et vendor après)

| Suite | Verdict |
|-------|---------|
| `test-cockpit-tracabilite-chaine.sh` | 66 passés, 0 échoués (exit 0), 17 s |
| `test-cockpit-projet-graphe.sh` | 119 PASS / 0 FAIL |
| `test-cockpit-avancement.sh` | 69 PASS / 0 FAIL |
| `test-cockpit-vendor.sh` | 251 PASS / 1 FAIL : V4 (`tests/chrome-coin.mjs` à 300 lignes) = rouge de la **base** `faed809d`, corrigé en avant par la jointure, non touché ; V4c.9a passe |
