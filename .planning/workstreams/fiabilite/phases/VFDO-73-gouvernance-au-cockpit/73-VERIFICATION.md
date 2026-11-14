---
phase: VFDO-73-gouvernance-au-cockpit
verified: 2026-11-14T02:43:35Z
status: human_needed
score: 23/24 must-haves verified
covered_files:
  - .planning/workstreams/fiabilite/phases/VFDO-73-gouvernance-au-cockpit/73-01-PLAN.md
  - .planning/workstreams/fiabilite/phases/VFDO-73-gouvernance-au-cockpit/73-01-SUMMARY.md
  - .planning/workstreams/fiabilite/phases/VFDO-73-gouvernance-au-cockpit/73-02-PLAN.md
  - .planning/workstreams/fiabilite/phases/VFDO-73-gouvernance-au-cockpit/73-02-SUMMARY.md
  - .planning/workstreams/fiabilite/phases/VFDO-73-gouvernance-au-cockpit/73-03-PLAN.md
  - .planning/workstreams/fiabilite/phases/VFDO-73-gouvernance-au-cockpit/73-03-SUMMARY.md
  - .planning/workstreams/fiabilite/phases/VFDO-73-gouvernance-au-cockpit/73-04-PLAN.md
  - .planning/workstreams/fiabilite/phases/VFDO-73-gouvernance-au-cockpit/73-04-SUMMARY.md
  - .planning/workstreams/fiabilite/phases/VFDO-73-gouvernance-au-cockpit/73-05-PLAN.md
  - .planning/workstreams/fiabilite/phases/VFDO-73-gouvernance-au-cockpit/73-05-SUMMARY.md
  - .planning/workstreams/fiabilite/phases/VFDO-73-gouvernance-au-cockpit/73-06-PLAN.md
  - .planning/workstreams/fiabilite/phases/VFDO-73-gouvernance-au-cockpit/73-06-SUMMARY.md
  - .planning/workstreams/fiabilite/phases/VFDO-73-gouvernance-au-cockpit/73-07-PLAN.md
  - .planning/workstreams/fiabilite/phases/VFDO-73-gouvernance-au-cockpit/73-07-SUMMARY.md
  - .planning/workstreams/fiabilite/phases/VFDO-73-gouvernance-au-cockpit/73-08-PLAN.md
  - .planning/workstreams/fiabilite/phases/VFDO-73-gouvernance-au-cockpit/73-08-SUMMARY.md
  - .planning/workstreams/fiabilite/phases/VFDO-73-gouvernance-au-cockpit/73-09-PLAN.md
  - .planning/workstreams/fiabilite/phases/VFDO-73-gouvernance-au-cockpit/73-09-SUMMARY.md
  - .planning/workstreams/fiabilite/phases/VFDO-73-gouvernance-au-cockpit/73-10-PLAN.md
  - .planning/workstreams/fiabilite/phases/VFDO-73-gouvernance-au-cockpit/73-10-SUMMARY.md
  - .planning/workstreams/fiabilite/phases/VFDO-73-gouvernance-au-cockpit/73-11-PLAN.md
  - .planning/workstreams/fiabilite/phases/VFDO-73-gouvernance-au-cockpit/73-11-SUMMARY.md
  - plugin/cockpit/CHANGELOG.md
  - plugin/cockpit/README.md
  - plugin/cockpit/scripts/vf-cockpit-equipe-carte.mjs
  - plugin/cockpit/scripts/vf-cockpit-etat-officiel.mjs
  - plugin/cockpit/scripts/vf-cockpit-interface.json
  - plugin/cockpit/scripts/vf-cockpit-regie-donnees.mjs
  - plugin/cockpit/scripts/vf-cockpit-regie-lecture.mjs
  - plugin/cockpit/scripts/vf-cockpit-route-ailleurs.mjs
  - plugin/cockpit/scripts/vf-cockpit-who.mjs
  - plugin/cockpit/skills/cockpit-moteur/assets/ui/00-vibeflow.js
  - plugin/cockpit/skills/cockpit-moteur/assets/ui/70-vf-live.js
  - plugin/cockpit/skills/cockpit-moteur/assets/ui/71-vf-equipe-rendu.js
  - plugin/cockpit/skills/cockpit-moteur/assets/ui/72-vf-equipe.js
  - plugin/cockpit/skills/cockpit-moteur/assets/ui/72-vf-regie-modele.js
  - plugin/cockpit/skills/cockpit-moteur/assets/ui/72-vf-regie-pied.js
  - plugin/cockpit/skills/cockpit-moteur/assets/ui/72-vf-regie-questions-lecture.js
  - plugin/cockpit/skills/cockpit-moteur/assets/ui/72-vf-regie-questions-rendu.js
  - plugin/cockpit/skills/cockpit-moteur/assets/ui/72-vf-regie-questions-source.js
  - plugin/cockpit/skills/cockpit-moteur/assets/ui/72-vf-regie-rendu.js
  - plugin/cockpit/skills/cockpit-moteur/assets/ui/72-vf-regie-source.js
  - plugin/cockpit/skills/cockpit-moteur/assets/ui/72-vf-regie-style.js
  - plugin/cockpit/skills/cockpit-moteur/assets/ui/90-vf-titre.js
covered_digest: "v4:sha256:e786bfadfb20d397a48faaab7c7c44fd2bf1f1f5cfa1c4690be5e11f8830288a"
behavior_unverified: 0
overrides_applied: 0
human_verification:
  - test: "Lire le résultat de la CI Linux sur la tête 7aa3e5f2 (PR #248) : jobs « Gates de qualité (mode strict) » et « Périmètre du changement »"
    expected: "Les deux jobs verts ; toutes les suites cockpit vertes sous Linux (critère de succès 7)"
    why_human: "Les deux jobs étaient en cours à la vérification ; aucune exécution Linux locale possible, rien n'est donc prouvé sous Linux"
  - test: "Sur un poste avec une session Claude Code vivante qui attend l'utilisateur, jouer `claude agents --json` et consigner la sortie réduite (présence de `cwd`, lignes après `turn_duration`)"
    expected: "`cwd` présent pour la session en attente ; `pendingBackgroundAgentCount` lu sur la dernière ligne `turn_duration` ; la ligne « Ailleurs sur ce poste » et « attend ses agents (N) » apparaissent sur la régie réelle"
    why_human: "Vérification manuelle seule déclarée par 73-VALIDATION.md (REGI-10, REGI-13) : demande une session vivante ; les suites utilisent un faux `claude`"
  - test: "Rejouer toutes les suites `test-cockpit-*.sh` sur la tête de fusion, sous macOS, avec le jeton Chrome commun"
    expected: "Aucun rouge ; en particulier les rouges déclarés hors Phase 73 par les SUMMARY (`test-cockpit-git-entete.sh` : 17 rouges de la Phase 79 ; `test-cockpit-projet-visite.sh` R3.18) sont relus sur la tête finale"
    why_human: "Cette vérification n'a rejoué que la suite de la régie et la suite de vendorisation (régime allégé) ; l'état des autres suites sur la tête finale n'est connu que par les SUMMARY"
---

# Phase 73 : Gouvernance au cockpit, rapport de vérification

**Objectif de la phase :** le cockpit montre ce qui attend une décision humaine (reliée à sa phase et à ce qu'elle bloque), qui tient le verrou de driver, quels arbres de travail existent avec leur non commité, et l'alerte du watchdog ; l'onglet Équipe devient une régie (« À vous », « Au travail », « Terminé, à relire », « Au repos ») à la place de son canevas.
**Vérifié :** 2026-11-14, tête `7aa3e5f2` de `feat/phase-73-gouvernance-regie` (worktree `<worktree>`)
**Statut :** human_needed (aucun manque de code constaté ; trois points non prouvables ici, listés plus bas)
**Re-vérification :** non, vérification initiale (régime allégé, une passe)

## Sondes jouées sur la tête 7aa3e5f2

| Sonde | Commande | Résultat | Verdict |
|---|---|---|---|
| Suite de la régie, entière, avec Chrome par le jeton commun | `test-cockpit-regie.sh` (toutes sections) | 339 PASS / 0 FAIL ; sections navigateur jouées (RG1_chrome, RG11_tiroir_chrome, RG17_chrome), mutants de non-fuite tués (M-AILLEURS-FLUX, M-Q-HTML, M-VERROU-PAGE-BRUT) | PASS |
| Suite de vendorisation (cliquet des 160 colonnes, tailles, inventaire `AJOUT`, moteur intact) | `test-cockpit-vendor.sh` | 253 PASS / 0 FAIL (les rouges V4c.9a/b des SUMMARY 73-07 à 73-10 sont refermés sur la tête finale) | PASS |
| Gates de dépôt | `check-version-sync.sh` ; `check-machine-paths.sh` ; `check-file-size.sh` sur les fichiers d'interface de la phase | tous verts (compteur « 243 suites » aligné sur les deux README ; 70-vf-live.js 295 et 00-vibeflow.js 298 lignes, sous 300) | PASS |
| Moteur vendorisé non touché | `git diff` des cinq fichiers du moteur entre la fusion de l'intégration et la tête | diff vide ; aucun commit de la phase ne les touche | PASS |
| Linux | CI de la PR #248 sur la tête | jobs « Gates » et « Périmètre » en cours | NON VÉRIFIÉ |

Aucun processus ni serveur laissé vivant par ces sondes.

## Critères de succès de la ROADMAP

| # | Critère | Statut | Preuve |
|---|---|---|---|
| 1 | Équipe sans canevas : quatre sections dans l'ordre, un agent qui attend en tête de « À vous » et à sa place dans l'arbre ; aucun fichier du moteur modifié | VERIFIED | `72-vf-regie-modele.js:189-200` (ordre), `:150` et `:168-175` (double présence) ; `vf-cockpit-equipe-carte.mjs:39` (`nodes: []`) ; `72-vf-equipe.js:1-12` (réduit au libellé de recherche) ; RG1.1, RG1.2, RG3.1, RG3.4 verts ; diff vide sur le moteur |
| 2 | « À vous » = sessions qui attendent + phases `human_needed`, classées par l'aval, « impact inconnu » plutôt qu'une estimation | VERIFIED | `72-vf-regie-modele.js:36-38, 82-88, 142-146, 93-95` ; `vf-cockpit-regie-donnees.mjs:39-46, 86-96, 122-136` ; RG4.*, RG5.* (regie-rg-gouvernance.sh:55-76, regie-rg-modele.sh:126-131) |
| 3 | Tenant du verrou, alerte du watchdog, arbres de travail avec non commité, sans appel git neuf ni champ brut du verrou dans la page | VERIFIED | `72-vf-regie-modele.js:18-27, 153-167` (liste blanche, marques) ; `72-vf-regie-pied.js:104-108` (routes git existantes, aucune minuterie) ; RG6.20, RG7.*, RG8.* verts |
| 4 | Titre « (N) vous attendent » qui survit aux autres écrivains ; « ailleurs » = nombre et nom de lab, nom jamais hors de la page servie | VERIFIED | `90-vf-titre.js:32-40` ; seul écrivain de `document.title` dans `ui/` (grep) ; `vf-cockpit-route-ailleurs.mjs:13-32`, `vf-cockpit-etat-officiel.mjs:106-120` ; RG12.1, RG13.30, RG13.* et les mutants de fuite verts |
| 5 | « Terminé, à relire » se vide à la lecture, dans ce navigateur, en 24 h au plus ; seule action d'une ligne : « Lire le rapport » | VERIFIED | `90-vf-titre.js:43-88` (localStorage par lab, purge 24 h) ; `72-vf-regie-modele.js:178-182` ; `72-vf-regie-rendu.js:97-100` ; RG11.* verts |
| 6 | La Phase 74 branche frise et fiche par le registre et l'événement, sans retoucher la 73 | VERIFIED | `72-vf-regie-source.js:12-22, 48, 115, 210-218` ; contrats documentés `plugin/cockpit/README.md:354-355` ; RG15.1 à RG15.10 verts |
| 7 | Suites cockpit vertes sous macOS et Linux, témoins du canevas re-pointés sans suppression, chaque exigence prouvée par un témoin rouge avant le code | UNCERTAIN | Rouge avant le code : 11 fichiers `73-NN-RED-TRACE.md`. Aucun fichier de test supprimé (`git log --diff-filter=D` vide) ; identifiants LE.*, LR.*, W23, EK*, EA2.15, EUI.3 présents. Suites régie et vendorisation vertes sur la tête (ci-dessus). Linux non prouvé (CI en cours) ; autres suites cockpit connues seulement par les SUMMARY : voir Human Verification |

## Exigences REGI-01 à REGI-17

| Exigence | Preuve dans le code | Témoin | Verdict |
|---|---|---|---|
| REGI-01 | Quatre sections, compteur = lignes d'agent, sous-titre = agents distincts en vie, vide dit : `72-vf-regie-modele.js:187-205` ; rendu `72-vf-regie-rendu.js:144-152` ; clé `section:id` `modele.js:136` | RG1.1, RG1.2, RG1.3 (`regie-rg-modele.sh:66-74`), RG1.12 états, M-CLE-ID-SEUL | VERIFIED |
| REGI-02 | Adaptateur unique `VF_ETAT.lire('who'\|'lock')` sinon `vf-who` + `__vfLive` : `72-vf-regie-source.js:25-47` ; modèle pur sans DOM | RG2.0, RG2.1 (même entrée, même DOM par les deux sources) | VERIFIED |
| REGI-03 | Enveloppe `cockpit-equipe@1` à `nodes` vide, meta gardée : `vf-cockpit-equipe-carte.mjs:24-41` ; aucun rechargement dans `72-vf-*` ; moteur intact | RG3.1 à RG3.7, M-GARDE-MEMO ; vendor 253/0 | VERIFIED |
| REGI-04 | `phasesHumaines` en-tête seul : `vf-cockpit-regie-donnees.mjs:100-136`, câblage `vf-cockpit-regie-lecture.mjs:65-83` et `vf-cockpit-who.mjs:195-196` ; lignes de phase `modele.js:142-146` ; sessions `:93-95` | RG4.1 à RG4.14, RG4.4 | VERIFIED |
| REGI-05 | `aval` / `retientDe` : `regie-donnees.mjs:39-96` ; trois rangs `modele.js:82-88` ; libellés `:36-38` | RG5.1 à RG5.6, M-IMPACT-TRI | VERIFIED |
| REGI-06 | Liste blanche champ par champ `modele.js:18-27` ; ligne de mission et verrou de dépôt `:153-167` | RG6.1 à RG6.3, RG6.20 (positif avant négatif), M-VERROU-*, M-VERROU-PAGE-BRUT | VERIFIED |
| REGI-07 | « verrou abandonné » depuis `stale`, « aucun nœud marqué depuis N min » au-delà de la fenêtre : `modele.js:154-159` ; fenêtre à source unique `regie-donnees.mjs:140-146` sur la ligne réelle `check-guard-health.sh:127` ; extraction impossible = rien marqué | RG7.0 à RG7.6, M-STALL-LIGNE, M-STALL-ABSENT, M-STALL-ANCRE, M-STALL-INCONNU-MARQUE | VERIFIED |
| REGI-08 | Bloc replié, jointure par chemin, relu sur l'événement `git`, aucun appel git neuf : `72-vf-regie-pied.js:46-116` | RG8.1 à RG8.6 (RG8.1 vu rejoué : « non vérifié » sans compte) | VERIFIED |
| REGI-09 | « silencieux » > 120 s (`71-vf-equipe-rendu.js:61`), « suspect » > fenêtre, commande jusqu'à 15 min, orphelin neutre sans action, `sortisSilence` en pied : `modele.js:55-80, 194` | RG9.1 à RG9.8, RG9.20 à RG9.22, M-CALME, M-LONGUE-EGALE-STALL | VERIFIED |
| REGI-10 | `attendAgents` sur la dernière ligne `turn_duration`, sessions non actives : `regie-donnees.mjs:158-164`, `regie-lecture.mjs:31`, borné `who.mjs:169, 182` ; mot `modele.js:51, 64` | RG10.1 à RG10.6, RG10.10 | VERIFIED |
| REGI-11 | « Lu » à l'ouverture, `localStorage` par lab, purge 24 h, repli sans stockage : `90-vf-titre.js:43-88` ; « Tout marquer comme relu » `72-vf-regie-source.js:97-110` ; « échec » / « arrêté » `modele.js:60` ; tiroir : `70-vf-live.js:189`, `71-vf-equipe-rendu.js:142-146` | RG11.1 à RG11.24 (RG11.22 navigateur), RG17.R2, RG17.R3 | VERIFIED |
| REGI-12 | Compositeur unique, pastille neutre : `90-vf-titre.js:20-40, 95-102` ; écrivains remplacés `00-vibeflow.js:13`, `76-vf-git-entete.js:19` | RG12.1 à RG12.7, RG0.13 | VERIFIED |
| REGI-13 | `ailleurs()` `etat-officiel.mjs:106-120` ; route `route-ailleurs.mjs:13-32` + `vf-cockpit-server.mjs:105` ; ligne de page `72-vf-regie-pied.js:118-140` ; bloc `cockpit-ailleurs@1` dans `vf-cockpit-interface.json:150` | RG13.0 à RG13.17, RG13.30 à RG13.35 (positif d'abord), M-AILLEURS-FLUX, M-AILLEURS-PAGE-STOCKAGE, mutants `cwd` | VERIFIED |
| REGI-14 | Un seul style `.btn`, seule action de ligne « Lire le rapport » (`72-vf-regie-rendu.js:97-100`), nom écrit une fois (`:48-52`) ; Santé : voir note 1 | RG14.0, RG14.3, RG14.20, RG14.30 | VERIFIED (réserve, note 1) |
| REGI-15 | Registre `window.__vfEquipeVues`, bascule dès deux vues (`rendu.js:194-206`), événements annulables `vf-agent:ouvrir` / `vf-agent:lu`, attributs `data-vf-*` (`:80-81`), ancres traitées par la régie (`source.js:210-218`, `00-vibeflow.js:286`) | RG15.1 à RG15.10 | VERIFIED |
| REGI-16 | LE → LR re-pointés (aucun supprimé), nettoyage à l'émission `who.mjs`, export sans régie, recherche par lignes `rendu.js:172-180`, compteur README 243 | LR.0b à LR.7, W23, RG16.1 à RG16.20, `check-version-sync` | VERIFIED (macOS) ; Linux non prouvé |
| REGI-17 | Lecture fermée par défaut `72-vf-regie-questions-lecture.js:53-79` (état exact `en-attente` et forme complète), source `…-source.js:22-36`, rang `modele.js:84-88`, décisions appliquées à part, bilan, absence dite `lecture.js:105-130` | RG17.0 à RG17.43 dont RG17.40 navigateur ; mutants M-Q-MALFORMEE-EN-ATTENTE, M-Q-AVERIFIER-EN-ATTENTE, M-Q-ETAT-IGNORE, M-Q-LIEN-BRUT, M-Q-HTML tués | VERIFIED (sur fixture à la forme du contrat, comme l'exigence le demande) |

## Cas connus ouverts (non comptés comme manques de la phase)

1. **RG1.12 / `VF_ONGLETS.aller`** : 80-10 n'est pas dans la branche. Le fragment d'ancre est lu à `vf:onglet` (repli de document) et le montage à froid sous `VF_ONGLETS` n'est pas prouvé (`72-vf-regie-source.js:195-196`). À revalider à l'arrivée de 80-10.
2. **Chaîne 76-09 vers route vers page** : la Phase 76 n'est pas fusionnée. REGI-17 est prouvée sur fixture ; tant que la route du graphe Projet ne sert pas `meta.vf.questions`, la page dit « Lecture des questions des cadrages pas encore livrée (Phase 76) » (`72-vf-regie-questions-lecture.js:105`).

## Notes

1. **REGI-14, Santé (réserve, non un manque)** : « ni calculée ni injectée » est tenue par construction (l'enveloppe d'Équipe ne porte aucun champ `health`, RG14.3), mais le bouton et la section du moteur existent encore, masqués par la règle de feuille `00-vibeflow.js:134`. Retirer vraiment le bouton demanderait un patch du fichier du moteur `20-health.js`, contraire à P73-D-24. Décision prise au planning (hypothèse A2, `73-RESEARCH.md` C6bis, `73-08-PLAN.md:88`).
2. **But de la ROADMAP, « alerte posée sur le nœud de mission »** : l'alerte est posée sur la ligne de mission de la régie, pas sur un nœud de carte (il n'y a plus de carte sur Équipe). La marque sur les nœuds `running` « quand le DAG est visible » (P73-D-09, UI-SPEC § 6.3) n'est jamais déclenchée puisque la régie ne montre pas de nœuds. Conforme au texte de REGI-07 et au critère 3, qui ne demandent que la lecture sur la régie.
3. **Libellé REGI-07** : l'exigence dit « sans progrès depuis N min », le code dit « aucun nœud marqué depuis N min » (P73-D-09, formulation au conditionnel de la source, voulue).
4. **Suivi administratif laissé à l'appelant** : `ROADMAP.md` n'a pas coché `73-11-PLAN.md` ; `REQUIREMENTS.md` garde REGI-01..17 en « Pending » ; `73-VALIDATION.md` reste `draft` avec `nyquist_compliant: false` et statuts « pending ».

## Anti-patterns

Aucun `TBD`, `FIXME` ni `XXX` dans les fichiers de la phase ; aucun `TODO`, `HACK` ni `PLACEHOLDER` dans les fichiers d'interface neufs. Aucun HTML construit à partir de données du disque dans la régie (RG17.40 : texte hostile inerte, `window.__pwn` indéfini). Pas de stub : chaque module est lu et câblé (source, rendu, pied, titre, questions), les données du serveur passent par `who@2` et la route `ailleurs`.

## Gaps Summary

Aucun manque de code constaté : les 17 exigences et les critères 1 à 6 sont tenus par le code de la tête `7aa3e5f2` et par 339 témoins verts, navigateur compris. Le critère 7 reste incertain sur deux points que cette passe ne peut pas lever (Linux, et les suites cockpit autres que la régie et la vendorisation) ; la sonde réelle de `claude agents --json` est une vérification manuelle déclarée par la validation de la phase. D'où `human_needed`.

---

_Verified: 2026-11-14T02:43:35Z_
_Verifier: Claude (gsd-verifier)_
