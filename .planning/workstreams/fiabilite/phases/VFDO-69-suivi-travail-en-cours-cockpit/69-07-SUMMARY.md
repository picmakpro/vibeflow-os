---
phase: 69-suivi-travail-en-cours-cockpit
plan: 07
requirements: [CKPT-24, CKPT-25, CKPT-26, CKPT-28]
---

# 69-07 — route du transcript et garde d'émission lue du contrat

## Livré
- `vf-cockpit-server.mjs` : route `GET /api/vf/transcript?id=` (400 `id-invalide` hors `ID_RE`, sinon `revealTranscript`, `no-store`, jamais journalisée ni écrite) ; `porteInterdit` remplace `porteDoing`, liste `INTERDITS` lue une fois du contrat voisin (`schemas['vibeflow/cockpit-who@2'].interdits`), contrat illisible ou liste vide -> tout objet est refusé (fermé par défaut) ; `ID_RE` importé de `vf-cockpit-lecture.mjs` ; `noter` ne compte plus les agents `termine` comme actifs.
- Suites : F4 (`test-cockpit-serveur.sh`), `/api/vf/transcript?id=x` dans H1 (`securite`), route interrogée sous la sonde et témoin R1.4 (`reseau`).
- Harnais (décision du manager, mission mgr69exec, 2026-11-03) : `graphe.mjs` de `test-cockpit-equipe.sh` charge l'embed de la SORTIE assemblée (`$OUT`, marqueur `window.VF_COCKPIT`), pas celui des sources (`window.FLOORPLAN`). Le découpage n'accepte pas deux marqueurs.

## Témoins
- Rouge avant : T25 (route absente, 69-04-RED-TRACE) ; E23.3-5 rouges sur le harnais d'origine (65 PASS / 3 FAIL).
- Vert après : `test-cockpit-transcript.sh` T0, T24, T25 sans FAIL (dont M-JETON T25.15 et M-PORTE T25.17 vus) ; `serveur` 66/0 ; `securite` 91/0 ; `reseau` 15/0 ; `direct`, `questions`, `robustesse`, `chaine-xss` exit 0 ; `equipe` 68/0.
- Mutants : F4 rougit si le contrat reste dans la copie (F4.0 et F4 FAIL) ; E23.3 rougit sur une page sans le marqueur servi (« marqueur de début absent »).
- T26.1-4 et T26.7 restent rouges tant que 69-08 n'a pas livré la couche d'affichage (hors plan).

## Risque résiduel
Le transcript réduit reste lisible par tout processus local qui lit le jeton : accepté par P69-D-27 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-03), aucun resserrement.

## Écarts
- Le contrat est lu depuis le dossier du module serveur (`import.meta.url`), pas `resolveScriptsDir(here)` : la sortie assemblée en porte une copie (build) et F4 en dépend.
- Le jeton servi se lit dans l'en-tête `x-vf-cockpit-token` (le plan citait `x-floorplan-token`, renommé au build).
