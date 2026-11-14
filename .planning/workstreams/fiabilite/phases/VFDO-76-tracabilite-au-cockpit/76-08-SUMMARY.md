---
phase: 76
plan: "08"
requirements: [TRAC-12]
status: complete
---

# 76-08 — Retrait du nœud « Exigences », puis clôture (régime allégé)

Exécuté sur `feat/phase-76-questions`, après la fusion de 80-11 (`e6304cc9`, merge `b24c0d2e4`, un seul conflit, `00-vibeflow.js` : les ajouts des deux côtés sont gardés).
Commits : `707ea49bf` (témoins rouges), `5de90fab7` (retrait), puis le commit de clôture (CHANGELOG, compteurs, durées de shard, limite écrite, SUMMARY).

## Livré

- Graphe Projet sans nœud `<id>.req`, sans carte `req/…`, sans lien « couvre » ; `piedExigences` et le champ `exigences {faits, total}` de la 80 ne sont pas touchés.
- `window.VF_EXIGENCES.lireExigences` (80) rebranchée sur `meta.vf.trace.exigences` et `nodes[].trace.plans[]` : seul le corps entre les marqueurs `porte-exigences` change ; signature, globale, marqueurs et ligne `garde:porte` intacts ; `cible` vaut `null`.
- Chat local du Projet (`vf-cockpit-ask.mjs`) : les exigences se lisent dans `meta.vf.trace.exigences`, la réponse ne cite que la carte de la phase ; la consigne de l'agent ne parle plus de `n:ph-<N>.req` ni de `f:req/<ID>`.
- Clés de libellé retirées avec le nœud et les liens : `data` (« Couvre »), `feuille:exigences`, `parent:exigences`, `liste:exigences`, `entrant:data`, `sortant:data`, `statut:exigences:done`, `statut:exigences:todo`. Pictogramme et couleurs du genre `exigences` retirés de `vf-cockpit-types.mjs` (aucun consommateur : PV2.1, PV2.5, PV2.7, PL2.x verts).
- `ownReqs` (`vf-cockpit-project.mjs`) : il ne part PAS avec le nœud (il nourrit le pied « x/y exigences » et le champ `exigences`). Il rattachait les exigences d'archive par le seul numéro (`r.wsKey === '*'`) ; il est aligné sur 438a2ef6 : une exigence d'archive ne se rattache à une phase vivante que par un plan de CETTE phase qui la cite, jamais là où le ledger vivant du même compartiment porte le même identifiant ; une phase d'archive (numéro unique, aucun compartiment) garde le numéro.
- Outils : `retrait-lecteurs.mjs` (`--inventaire`, `--porte`, `--porte-brut`, `--lab-reference`, `--temoins` ; inventaire, jamais une porte), `rejouer-suites.sh` (codes 0, 1, 3, 4 ; **priorité 3 avant 1 avant 4**, écrite en en-tête, jouée par R76.4a à R76.4g : un rouge reste un rouge même si le journal est incomplet, et `JOUE-DIFFERENT-PRESENT` est alors imprimé quand même), `chrome-tracabilite-couverture.mjs` (C8).
- Limite écrite (demandée par la session principale, décision déléguée par Samuel, message session principale, 2026-11-08, option recommandée, prise par la session principale le 2026-11-14) : `plugin/cockpit/README.md`, paragraphe « Limite connue de la traçabilité (rafraîchissement) » à la suite de la route `cockpit-trace@1`, ligne de CHANGELOG, entrée `.planning/BACKLOG.md` (« la clé `planning` de VF_ETAT n'avance pas sur une exigence ajoutée seule »). Pas de correctif.
- CHANGELOG § Non publié (section Phase 76), compteur de suites des deux README recompté : **253**, commande `find plugin scripts -path '*/tests/test-*.sh' | grep -c .` → `253` (avant : 246) ; `bash scripts/check-version-sync.sh` vert. Une ligne de durée par suite neuve de la 76 dans `scripts/ci-shard-suites.sh`. Aucun bump, aucun tag.

## Preuves de la condition d'arrêt (P76-D-39), avant et après

| Preuve | Avant | Après |
|--------|-------|-------|
| R76.2a équivalence de la porte de la 80 (lab de référence) | sortie capturée dans `76-08-PORTE-AVANT.json` | identique (`cmp -s`) |
| R76.2b cible brute | `f:req/…` non nulles (rouge nommé `cible-non-nulle: f:req/AUTH-01` consigné) | toutes `null` (11 exigences et couvertures lues) |
| R76.3 couverture du panneau d'exigence (C8.1) | `76-08-COUVERTE-AVANT.txt` : 9 lignes, une exigence à 3 plans | `comm` vide : aucun plan manquant |
| PL2.9 | vert | vert (non modifié) |
| PV2.5 | vert | vert (non modifié) |
| négatif de la 80 | — | vrai pour le corps de la porte et les marqueurs ; le motif strict a UNE occurrence, `41-vf-projet-vue.js:191` (mot « recouvre » dans un commentaire sur le tiroir Git) |

## Écarts

- Écart : le lab de référence de la porte n'est pas le dépôt (`--porte "$PWD"` du plan, mouvant) mais un lab fabriqué par `retrait-lecteurs.mjs --lab-reference` (deux compartiments, une exigence d'archive, un libellé de 363 caractères, des plans qui couvrent) : déterministe, rejouable par la suite.
- Écart : le recensement du plan (B3) n'avait pas vu trois suites qui affirmaient le nœud : `test-cockpit-tracabilite-collecte.sh` (T9.11, l'ancien porteur est remplacé par une lecture indépendante des fichiers sources), `test-cockpit-projet-vocabulaire.sh` + `chrome-projet-vocabulaire.mjs` (PV2.3 : plus de carte d'exigence, la preuve devient « ni carte ni nœud, une fois dans `meta.vf.trace` » ; PV2.1, PV2.5, PV2.7 inchangés et verts) et `test-cockpit-tracabilite-page.sh` C2.5. Aucune assertion n'est supprimée.
- Écart : C2.5 (section Jalon ouverte, défilement gardé) déclenchait un changement de structure en retirant une exigence ; sans nœud, c'est un `patch` sans rechargement (le panneau se redessine, le défilement revient à 0, comportement du moteur et non de la 76). Le déclencheur est un plan retiré (changement de structure) ; la section reste ouverte et le défilement gardé, comme avant. Le comportement du patch (défilement perdu au `sansEntree`) est de l'ancien moteur : remonté, non corrigé.
- Écart : le négatif strict de la 80 a une occurrence (« recouvre », commentaire de `41-vf-projet-vue.js`, fichier de la 80, hors périmètre) ; non touché (voir les findings).
- Écart : `colonnes-baseline.txt` baisse (`vf-cockpit-ask.mjs` 37 vers 35, `vf-cockpit-project.mjs` 68 vers 66), aucune hausse.
- Contrat 75-04 : `touched` reste absent quand un plan n'a pas de `files_modified` (le code de `construireGraphe` n'est pas changé sur ce point). Aucun champ de `cockpit-project@1` ajouté ; seuls des libellés de `meta.kindLabels` et un genre de nœud sont retirés ; `test-cockpit-projet-champs.sh` vert.

## Suites jouées une fois sur la tête commitée (secondes mesurées)

| Suite | Verdict | s |
|-------|---------|---|
| test-cockpit-projet-graphe.sh | 129 PASS, 1 FAIL sous charge (P10.5, mutant de croissance au rapport d'horloge) ; P10.5 rejoué seul : vert | 577 |
| test-cockpit-questions.sh | 135 PASS | 26 |
| test-cockpit-tracabilite-collecte.sh | 36 PASS | 29 |
| test-cockpit-tracabilite-page.sh | vert (C2.5 réparé, C8.0 et C8.1 verts) | 53 |
| test-cockpit-projet-liste.sh | 51 PASS (PL2.9 vert) | 118 |
| test-cockpit-projet-vocabulaire.sh | 18 PASS (PV2.5 vert) | 27 |
| test-cockpit-tracabilite-chaine / decisions / memoire / route / panneaux, questions-attente | verts | 29, 4, 9, 48, 58, 26 |
| test-cockpit-projet-champs.sh | 21 PASS | 3 |
| test-cockpit-vendor.sh | 253 PASS (largeur, baseline des colonnes) | 81 |
| test-cockpit-routes.sh, test-cockpit-lecture-fil.sh (ATTENDU, RK.1, RK.7, D8.9 après la fusion) | verts, aucun recompte nécessaire | 46, 2 |
| scripts/check-version-sync.sh | vert (253 suites) | 2 |
| scripts/tests/test-ci-shard-suites.sh | C5 et MUT-3 rouges, déjà rouges sur la tête avant ma table (borne dépassée de 1 s avec mes durées, de bien plus sans) : table des durées incomplète pour les suites des phases 73, 74, 75, 79, hors périmètre | 2 |

Secondes passées dans les suites : environ 1 140 s sur la tête, plus environ 330 s de rejeux et d'essais (e5 de C2.5, P10.5 seul, baseline de C2.5 sur la base extraite).

rituel levé : rejeu de TOUTES les suites avant et après le retrait (`rejouer-suites.sh avant` / `apres`) : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale)
rituel levé : baseline R76.4 vérifiée par `awk` dans la trace rouge : régime allégé (même consigne)
rituel levé : mutants M-PORTE-76, M-COUV-PANNEAU, M-RETRAIT, M-SUITE-OUBLIEE : régime allégé (même consigne)
rituel levé : rejeu des commandes du job `gates` de `ci.yml` : régime allégé (même consigne) ; la CI le fait

Rouges connus qui ne sont pas à ce plan : F7.4a de frise, W24.4 de who, N5.1 de reconnexion (non joués ici). `test-cockpit-vendor.sh` vert sur cette tête ; T28-F de `test-dev-orchestrator.sh` non joué.

## À verser par la jointure

- Recoupement avec AUDC-I25 de la Phase 80 (liste « à cocher » des exigences) : la porte rebranchée rend la même liste (R76.2a, PL2.2) ; rien à rouvrir.
- Collision avec la 77 sur le `return` de `construireGraphe` (`lastDesc`) : non touchée ici.
- Un lecteur de Projet ajouté par la 77 se revalide à son exécution (R76.3, R76.4 sur son propre diff).

## Suite du mandat (manager de la Phase 76)

- Négatif de la 76 : le motif `couvre` devient le mot entier `\bcouvre\b` (plan, verify et fails_when ; décision déléguée par Samuel, message session principale, 2026-11-08, option recommandée, prise par le manager de la Phase 76 le 2026-11-14). Rejoué sur `ui/41-vf-projet-*.js` : 0 occurrence dans les huit fichiers. Témoin positif sur une copie jetable hors du dépôt, un lien `l.label === 'couvre'` réintroduit : vu (ligne 98 de la copie).
- `scripts/tests/test-ci-shard-suites.sh` C5 et MUT-3 : verte sur 82aab6cc (242 suites, 22 PASS), rouge sur notre tête (253 suites). Les durées de nos huit suites 76 sont déjà mesurées ; les remplacer par les secondes des SUMMARY de 76-01 à 76-09 ou par d'autres valeurs documentées (cinq combinaisons essayées) laisse le dépassement à +1 ou +2 s (max 1213 à 1217 contre une borne de 1211 à 1216) : le dépassement ne vient pas de nos durées mais des suites des phases 73, 74, 75, 79 et 80, sans durée dans la table (défaut 7 s), que le mandat interdit de toucher. Aucun changement du fichier ; à lever par une remesure des durées de ces phases.

## Correctif revue finale M1/M2 (et constats de la vérification de but)

- Correctif revue finale M1 : `ownReqs` (pied, champ `exigences`) lit `meta.vf.trace.exigences` avec la règle de la porte (phase et compartiment, `cleNoeud` pour une exigence d'archive) ; repli sur le tableau de traçabilité seulement si la collecte a échoué. Témoin R76.6 vu rouge (« 0/0=1/1=,… »), vert ensuite ; sur le dépôt réel : 87 phases, 0 divergence entre le champ et la porte (5 avant : ph-38, ph-27, ph-28, ph-40, ph-30). R76.2a (équivalence de la porte) reste identique.
- Correctif revue finale M2 : `exigencesDe` écarte la jumelle d'archive (`ws '*'`) d'une exigence vivante de même identifiant. Q76.3 vu rouge sur l'ancien code (« [false|true] »), vert ensuite ; « ADPT-01 ? » et « QUAL-01 ? » sur le dépôt : une exigence chacune. Le premier commit du témoin portait une parenthèse en trop qui le faisait rougir pour une mauvaise raison ; corrigée avec le fix.
- C8.1 (vérification de but) : cause = le harnais, pas le produit. La première ouverture (REQ-11) est la plus lente, les puces étaient lues avant que le corps du panneau soit posé ; le harnais attend maintenant le corps, retente trois fois et lève une erreur nommée au lieu d'un `continue` silencieux. Rejoué sous une moyenne de charge de 80 : vert.
- CHANGELOG : la ligne de la régie ne dit plus « tant que le champ n'est pas servi (76-09) ». C2.6b : marqueur propre au texte d'une exigence (MARQ-EXIG-76 dans REQ-14), compté dans l'export (0) et dans le registre du lab (1).
