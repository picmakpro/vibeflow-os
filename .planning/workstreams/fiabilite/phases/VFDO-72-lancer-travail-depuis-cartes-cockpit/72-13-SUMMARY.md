---
phase: 72
plan: 13
requirements: [LANC-11]
verdict_porte_A5: VERTE
estimate: { tokens: 110000, raw_tokens: 110000, tasks: 3, confidence: low }
---

# 72-13 — option « continuer le chat » (LANC-11)

Trace : `72-13-RED-TRACE.md` (porte A5, rouge, écarts).

## Porte A5 (tâche 0)

**VERTE — 2026-11-05, claude 2.1.318 (Claude Code)**, voie fidèle (serveur du cockpit réel sur lab jetable, `POST /api/ask`), aucun repli. Relevés R-HISTORIQUE, R-REGLAGE, R-OUTIL, R-SUIVI, R-COPIE tous obtenus (essai 2). Commits du manager précédent : `d55c37c3` (porte), `f252e8db` (cause de l'essai 1 écarté). La sonde vaut pour cette version de `claude` (limite à écrire au README par 72-15).

## Livré

- `vf-cockpit-lancer-ui.mjs` : `CHAT_LIVRE`, `extraireSessionChat` (pure, bornée), `installerObservateurChat` (enveloppe de `window.fetch` limitée à `POST /api/ask` en mode ask, lecture d'un clone, UUID seul retenu dans une variable de fermeture), `corpsProposition` (pure). Le corps du POST de 72-06 reste `{ cible, verbe }` tant qu'aucune conversation n'est observée ; la ligne `garde:corps` garde son motif pour le mutant `M-CHAT-ENVOYE` de 72-06.
- `vf-cockpit-terminal-vue.mjs` : case native « Continuer la conversation du chat », décochée, classes existantes (`vf-q-reste`, `vf-q-texte`), aucune règle de style ; la zone « Commande exacte » suit la case et le mode ; `cb.lancer(mode, avecChat)`.
- `vf-cockpit-terminal-client.mjs` : `forme` accepte `chat` (vrai) avec `lignes_chat` (ensemble, sinon « aucune ») ; `POST /lancer` porte `chat: true` seulement case cochée ; fichier à 280 lignes (borne de LB.S3 de 72-08).
- `tests/test-cockpit-lancer-chat.sh` : TC.1 à TC.7, six mutants.

## Interface exigée de Q — mesure boîte noire (TC.5)

Les trois points sont déjà tenus par 72-05 et 72-10 : (1) `chat` forgé ignoré (8 formes), (2) `lignes` sans `-r` et `lignes_chat` égale au gabarit 72-01, même session, (3) `POST /lancer { id, mode, chat }` booléen strict, champ inconnu 400, 0 octet.

## Écarts au plan (code livré suivi)

- La capture du PTY vaut `\x03` + ligne (contrat §4 de 72-02).
- TC.5 et la route de P sont verts sur la base (le plan les supposait rouges).
- `M-CHAT-NON-VALIDE-Q` est absorbé par le gabarit (défense en profondeur) : asserté comme tel, pas un rouge fabriqué.
- Les majuscules d'un UUID passent P et la forme de Q mais sont refusées au composeur : proposition ignorée en silence, fail-closed.
- La commande `verify` de la tâche 2 compte `grep -c 'FAIL'` : la ligne « Résultats : N PASS / 0 FAIL » la fait valoir 1. À corriger côté plan (`❌ FAIL`).
