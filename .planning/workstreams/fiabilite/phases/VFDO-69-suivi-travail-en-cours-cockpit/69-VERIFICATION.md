---
phase: VFDO-69-suivi-travail-en-cours-cockpit
verified: 2026-11-04T05:30:00Z
status: human_needed
score: 16/16 must-haves verified
covered_files:
  - .planning/workstreams/fiabilite/phases/VFDO-69-suivi-travail-en-cours-cockpit/69-01-PLAN.md
  - .planning/workstreams/fiabilite/phases/VFDO-69-suivi-travail-en-cours-cockpit/69-01-SUMMARY.md
  - .planning/workstreams/fiabilite/phases/VFDO-69-suivi-travail-en-cours-cockpit/69-02-PLAN.md
  - .planning/workstreams/fiabilite/phases/VFDO-69-suivi-travail-en-cours-cockpit/69-02-SUMMARY.md
  - .planning/workstreams/fiabilite/phases/VFDO-69-suivi-travail-en-cours-cockpit/69-03-PLAN.md
  - .planning/workstreams/fiabilite/phases/VFDO-69-suivi-travail-en-cours-cockpit/69-03-SUMMARY.md
  - .planning/workstreams/fiabilite/phases/VFDO-69-suivi-travail-en-cours-cockpit/69-04-PLAN.md
  - .planning/workstreams/fiabilite/phases/VFDO-69-suivi-travail-en-cours-cockpit/69-04-SUMMARY.md
  - .planning/workstreams/fiabilite/phases/VFDO-69-suivi-travail-en-cours-cockpit/69-05-PLAN.md
  - .planning/workstreams/fiabilite/phases/VFDO-69-suivi-travail-en-cours-cockpit/69-05-SUMMARY.md
  - .planning/workstreams/fiabilite/phases/VFDO-69-suivi-travail-en-cours-cockpit/69-06-PLAN.md
  - .planning/workstreams/fiabilite/phases/VFDO-69-suivi-travail-en-cours-cockpit/69-06-SUMMARY.md
  - .planning/workstreams/fiabilite/phases/VFDO-69-suivi-travail-en-cours-cockpit/69-07-PLAN.md
  - .planning/workstreams/fiabilite/phases/VFDO-69-suivi-travail-en-cours-cockpit/69-07-SUMMARY.md
  - .planning/workstreams/fiabilite/phases/VFDO-69-suivi-travail-en-cours-cockpit/69-08-PLAN.md
  - .planning/workstreams/fiabilite/phases/VFDO-69-suivi-travail-en-cours-cockpit/69-08-SUMMARY.md
  - .planning/workstreams/fiabilite/phases/VFDO-69-suivi-travail-en-cours-cockpit/69-09-PLAN.md
  - .planning/workstreams/fiabilite/phases/VFDO-69-suivi-travail-en-cours-cockpit/69-09-SUMMARY.md
  - plugin/cockpit/scripts/vf-cockpit-avancement.mjs
  - plugin/cockpit/scripts/vf-cockpit-equipe.mjs
  - plugin/cockpit/scripts/vf-cockpit-interface.json
  - plugin/cockpit/scripts/vf-cockpit-planning.mjs
  - plugin/cockpit/scripts/vf-cockpit-project.mjs
  - plugin/cockpit/scripts/vf-cockpit-server.mjs
  - plugin/cockpit/scripts/vf-cockpit-transcript.mjs
  - plugin/cockpit/scripts/vf-cockpit-who.mjs
  - plugin/cockpit/skills/cockpit-moteur/assets/ui/71-vf-equipe-rendu.js
  - plugin/cockpit/skills/cockpit-moteur/assets/ui/72-vf-equipe.js
covered_digest: "v4:sha256:9ae5b384e0841374b1896790b57538501258b107466a6dbc42c33791743c3ccb"
behavior_unverified: 0
overrides_applied: 0
human_verification:
  - test: "Recette humaine de fin de phase (69-RECETTE-HUMAINE.md, 14 étapes) : statut du fichier « À FAIRE », colonnes « Retour de Samuel » vides sauf l'étape 1 (capture sans texte)"
    expected: "Samuel déroule la recette, ou ratifie par écrit que les verdicts des juges Playwright la remplacent (méthode du 2026-11-04) ; le statut passe à FAITE"
    why_human: "P69-D-30 exige la recette humaine AVANT le merge ; les verdicts Playwright sont des avis de juges automatiques, non l'avis de Samuel. Ce n'est pas un défaut du code."
  - test: "Rejouer sur le code courant les deux étapes que les juges ont notées KO avant correction : étape 3 (contraste de la pastille « En cours », thème clair) et étape 6 (verrou tenu visible dans le tiroir « Au travail »)"
    expected: "Contraste lisible (>= 4,5:1) dans les deux thèmes ; le verrou de phase tenu apparaît dans « Verrous et nœuds » au lieu de « Driver libre »"
    why_human: "Les correctifs existent (db8f6736, 63b7869f) et leurs suites sont vertes, mais le fichier de recette garde le verdict KO d'origine sans verdict de rejeu des juges."
  - test: "Lien agent <-> nœud sur un agent ACTIF (CKPT-21)"
    expected: "Un agent actif qui exécute un nœud est rattaché, lien cliquable dans les deux sens"
    why_human: "Les juges signalent que le chemin positif n'a été vu que sur des agents terminés ; il est couvert par fixture (E21), pas par une session vivante."
---

# Phase 69 : Suivi du travail en cours dans le cockpit — Rapport de vérification

**Objectif de phase :** la carte Projet du cockpit dit la vérité sur l'avancement (états de phase dérivés de traces locales, décompte des plans, jalon, mission rattachée) et le cockpit montre l'équipe au travail (arbre session, manager, workers, liens vers les nœuds, dernière action, onglet Équipe, transcript à la demande).
**Vérifié :** 2026-11-04, worktree `phase-69b`, branche `feat/phase-69-suivi-travail`, tête `93de1f95`, arbre propre.
**Statut :** human_needed
**Re-vérification :** Non, vérification initiale.

## Verdict

Tout le périmètre automatisable est atteint. Les 16 exigences CKPT-13 à CKPT-28 sont dans le code et prouvées par des suites rejouées. Aucune lacune de code. Le statut est `human_needed` parce que la recette humaine, exigée avant le merge par P69-D-30, n'est pas faite : le fichier est « À FAIRE » et seuls des avis de juges Playwright y figurent.

## Rejeu des suites (par moi, sur la tête 93de1f95)

21 suites du module `plugin/cockpit/scripts/tests/`, toutes en code de sortie 0, 0 FAIL :

| Suite | Résultat | Suite | Résultat |
|---|---|---|---|
| avancement | 61 PASS | robustesse | 25 PASS |
| equipe | 116 PASS | securite | 91 PASS |
| forme-claude | 56 PASS | serveur | 70 PASS |
| transcript | 99 PASS | direct | 75 PASS |
| who | 87 PASS | questions | 56 PASS |
| projet | 56 PASS | chaine-xss | 22 PASS |
| reseau | 15 PASS | marque-blanche | 22 PASS |
| vendor | 77 PASS | onglet-code | 18 PASS |
| assemblage | 40 PASS | reconnexion | 10 PASS |
| chrome-fr | 26 PASS | responsive | 191 PASS |
| hygiene | exit 0 | | |

Sondes directes en plus : `etiquette('Bash', {command avec secret})` rend `{verbe:'lance une commande', cible:''}` (secret absent) ; `Read /etc/passwd` rend « un fichier hors du lab » ; `citationsDuMandat` ne rend que les identifiants cités. Génération du graphe sur ce dépôt : Phase 67 `7/7 plans · 4 correctifs` (état `fait`, mission `2026-11-01-v2-cockpit` rattachée), Phase 69 `à recetter · 9/9 plans · 0/16 exigences`, jalon `1 clos · 1 à recetter · 4 à faire · 17 %`, jalon `active`.

## Exigences CKPT-13 à CKPT-26 (le mandat)

| Exigence | Statut | Preuve (code) | Preuve (témoin) |
|---|---|---|---|
| CKPT-13 objet `avancement` à 4 états | VERIFIED | `vf-cockpit-avancement.mjs:88-93` (fait > a-recetter > en-cours > a-faire, ni `current_phase` ni compartiment actif) ; posé par `vf-cockpit-planning.mjs:144-147` ; contrat `vf-cockpit-interface.json:4-11` | `test-cockpit-avancement.sh` A2.1 (STATE sur la phase 9, plans faits -> `a-recetter`), A2.3-A2.6 (clés exactes, version 1) |
| CKPT-14 plan fait = PLAN + SUMMARY ; correctifs à part | VERIFIED | `vf-cockpit-avancement.mjs:19-30` (ensembles, intersection et différence) ; pied `vf-cockpit-project.mjs:~83` | A1.1 « 7/7 plans · 4 correctifs », A1.2 absence de « 11/7 » ; réel : Phase 67 |
| CKPT-15 rattachement des missions, ordre champ / nom / dossier | VERIFIED | `vf-cockpit-avancement.mjs:41-53` (règle 1 décide seule, puis `MISSION-<n>`, puis `dossierPhase`) ; `vf-cockpit-planning.mjs:99-101,141-143` | A3.1-A3.2, A10.1 (`phase` inconnue ne se corrige jamais) ; réel : mission 67 sous la 67 |
| CKPT-16 jalon en cours ; pied « N clos · N à recetter · N à faire · N % » strict | VERIFIED | `vf-cockpit-project.mjs:22-25` (pied, pourcentage sur les phases closes), `:54-55` (en cours si `en-cours` ou `a-recetter`) | témoin (d) de la suite avancement + `test-cockpit-projet.sh` ; réel : `1 clos · 1 à recetter · 4 à faire · 17 %`. Écart mineur : le pied ajoute « N en cours » quand N > 0 (P69-PL-03), sur-ensemble du libellé exigé, sans effet sur le pourcentage. |
| CKPT-17 `reste` depuis traces locales, aucun réseau | VERIFIED | `vf-cockpit-avancement.mjs:65-77` (RECETTE-HUMAINE non « FAITE », pas de VERIFICATION, case non cochée) ; module pur, aucun import réseau | A6.1 (témoin positif : la sonde enregistre un fetch) puis A6 (zéro connexion sortante) ; CI, PR, merge absents du code |
| CKPT-18 règle `ph.n === curPhase` retirée | VERIFIED | `vf-cockpit-project.mjs:43` (`phaseStatus` = projection de `avancement.etat`) ; `curPhase` (`:36`) ne sert plus qu'à l'affichage (`:133,135`) | A18.0 (le source ne compare plus), A18.1, A18.2-A18.3 (copie mutée détectée) |
| CKPT-19 arbre session -> manager -> workers, liste plate retirée | VERIFIED | `vf-cockpit-equipe.mjs:61-74,92` (ancêtres par `parentAgentId`, profondeur `spawnDepth`) ; champs `parent`, `depth`, `role`, `task`, `etat`, `dureeS` (`:94-97`) ; rendu `71-vf-equipe-rendu.js:31-58`, appelé `70-vf-live.js:64` | E19 (fixture à trois niveaux), EUI (imbrication) |
| CKPT-20 actifs + terminés < 24 h, repliés ; > 24 h absents | VERIFIED | `vf-cockpit-equipe.mjs:11,57` (fenêtre 86400 s) ; `71-vf-equipe-rendu.js:42-47` (`<details>` « Terminés depuis moins de 24 h ») | E20 (2 h présent et terminé, 25 h absent), F14 |
| CKPT-21 rattachement agent -> nœud, jamais deviné, lien dans les deux sens | VERIFIED | `vf-cockpit-equipe.mjs:120-135` (registre d'abord, puis citations du mandat ; aucun, ambigu ou inconnu ne lie rien) ; `vf-cockpit-transcript.mjs:62-68` ; `71-vf-equipe-rendu.js:25-29` (agent -> nœud), `:60-64` + `70-vf-live.js:141` (nœud -> agent) | E21 (« revue-p3 » lié, nœud inconnu non lié). Voir humain n° 3 : chemin positif vu en réel sur terminés seulement |
| CKPT-22 dernière action lisible, ni argument ni sortie ni chemin hors lab | VERIFIED | `vf-cockpit-transcript.mjs:10-59` (table de verbes fermée, `cheminDuLab`, aucune valeur d'entrée hors cible) ; actifs seulement `vf-cockpit-equipe.mjs:30` ; bornes `vf-cockpit-who.mjs:134` ; garde du flux `vf-cockpit-server.mjs:29-30,56` | E22 (secret factice absent de `who` et du hello) ; sonde directe ci-dessus |
| CKPT-23 onglet « Équipe », libellés français | VERIFIED | `vf-cockpit-server.mjs:127-134` (`pageEquipe`), `72-vf-equipe.js`, `00-vibeflow.js:10,77` ; graphe `vf-cockpit-equipe-carte.mjs` | E23, EUI, `test-cockpit-chrome-fr.sh` (26 PASS), `test-cockpit-assemblage.sh` |
| CKPT-24 transcript réduit, jamais sorties d'outils ni fichiers lus | VERIFIED | `vf-cockpit-transcript.mjs:82-112` (liste blanche : mandat = 1re ligne user, messages = blocs `text` assistant, outils = nom + cible ; `tool_result` jamais lu) ; commande seulement derrière « Voir la dernière commande » `vf-cockpit-who.mjs:143-178` | `test-cockpit-transcript.sh` T24 (marqueurs de sortie et de fichier absents) |
| CKPT-25 transcript par requête authentifiée, id connu, jamais SSE/fichiers/export | VERIFIED | Garde Host `serve.mjs:505`, jeton `:511`, délégation `:512` ; route `vf-cockpit-server.mjs:91-97` (`ID_RE`, GET seul `:70`) ; id résolu par la collecte, pas par l'entrée `vf-cockpit-who.mjs:195-199` ; clés `mandat/messages/outils` interdites au flux `interface.json` + `vf-cockpit-server.mjs:30,56,75` | T25 (sans jeton refusé, id hors liste ou `../` refusé, marqueur absent du SSE et de `.vibeflow/cockpit/`, mutants M-JETON et M-PORTE) |
| CKPT-26 rendu en texte, CSP inchangée | VERIFIED | `71-vf-equipe-rendu.js:67-82` (`createElement` + `textContent` seulement), `72-vf-equipe.js:125` ; `serve.mjs` : aucune ligne CSP dans le diff de la branche | T26 (`<img onerror>` rendu en texte, aucun nœud `img`, en-tête CSP identique), `test-cockpit-chaine-xss.sh` (22 PASS) |

## Exigences hors mandat, dites séparément : CKPT-27 et CKPT-28

| Exigence | Statut | Preuve |
|---|---|---|
| CKPT-27 test de forme étendu, champ disparu -> `forme-inconnue` | VERIFIED | Contrat `vf-cockpit-interface.json` (`claudeCode.metaSousAgent` : `agentType`, `description`, `spawnDepth`, `toolUseId`, `requestShape`, `requisSiProfondeur.parentAgentId`, `booleensFacultatifs.finished`, `formeArretee` ; `transcriptSousAgent` : `isSidechain`, `agentId`) ; `vf-cockpit-equipe.mjs:17-26` (forme invalide -> `null`, compté `forme-inconnue` `:58-61,103`) ; `test-cockpit-forme-claude.sh` F1-F11 (une amputation par champ, dont `parentAgentId`), F12, F15 (56 PASS) |
| CKPT-28 calcul dans la lib du socle, schéma versionné qui monte, aucun réseau | VERIFIED | `vf-cockpit-who.mjs:3,139` schéma `vibeflow/cockpit-who@2` (était `@1` sur `main`, `git show main:...who.mjs:161`) ; contrat `interface.json` clé `cockpit-who@2` ; calcul dans `vf-cockpit-equipe.mjs` et `vf-cockpit-transcript.mjs` (aucun calcul dans l'interface) ; E28 ; `test-cockpit-reseau.sh` R1.5 (témoin réseau de CKPT-03 rejoué sur le serveur de la phase, 15 PASS) |

## Hygiène

- Balises de dette (TBD, FIXME, XXX) dans les 45 fichiers `plugin/` modifiés : aucune.
- Artefacts : tous présents, substantiels, câblés (`readPlanning` -> `avancement` -> `buildProjectGraph` ; `collectWho` -> `collecteAgents` -> `rattacher` -> flux et onglet Équipe ; `route` -> `revealTranscript`).
- Flux de données (niveau 4) : le graphe réel de ce dépôt produit les valeurs attendues (voir « Rejeu »), pas de valeur codée en dur.
- Commits de correction de recette (36acb0af « Dépend de », 63b7869f verrou, db8f6736 contraste, f66ba2f2 pied, 1e820393 export) : présents, suites vertes à la tête.

## Points sans effet sur le statut

- `REQUIREMENTS.md` : CKPT-13 à CKPT-28 encore `[ ]` et « Pending » en traçabilité. C'est le geste de clôture de phase, après recette ; pas une lacune de code.
- Écarts assumés et tracés, hors jugement : onglets resserrés (P69-D-28), latence de la suite responsive 175 s (P69-D-31), défauts visuels D et E renvoyés à la Phase 70 (P69-D-34).

## Résumé des manques

Aucun manque de code. Un seul blocage de statut : la recette humaine (voir `human_verification` du frontmatter).

---

_Verified: 2026-11-04T05:30:00Z_
_Verifier: Claude (gsd-verifier)_
