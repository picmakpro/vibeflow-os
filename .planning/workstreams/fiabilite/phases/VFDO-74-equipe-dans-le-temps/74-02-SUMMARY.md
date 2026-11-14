# 74-02 — résumé : `echec` dans le fil réduit (TEMP-08, TEMP-11)

## Livré
- `vf-cockpit-transcript.mjs` : le fil `cockpit-transcript@2` gagne le champ facultatif `echec: true` sur une ligne d'outil dont le résultat, apparié par identifiant d'appel exact, porte `is_error === true` (booléen strict). Aucune ligne `compaction` ni `humain` (P74-D-48).
- Seuls `tool_use_id` et `is_error` d'un résultat sont lus, jamais son contenu. L'identifiant d'appel reste interne (Map bornée à `outs`, purgée à l'éviction, jamais émise) ; un identifiant porté par deux appels désigne le plus récent. Un appel avant la frontière de 8 Mo n'est pas dans la Map : son résultat n'apparie rien.
- Préfiltre par sous-chaîne (`"assistant"` ou `"is_error":true` / `"is_error": true`) avant tout `JSON.parse` : une ligne `user` sans drapeau vrai n'est jamais analysée.
- `regrouper` : `echec` entre dans la clé ; un échec n'est jamais absorbé ni propagé.
- `CLES_LUES` exporté, figé : `tool_use.id`, `tool_use_id`, `is_error` (pour la comparaison du plan 74-09, B1, au bloc `claudeCode.index` de 79-08).
- `test-cockpit-transcript.sh` : section `T24D38` (14 libellés : .1 à .8, .9a à .9f), six mutants sur copies du module, sections T24 et T25 inchangées.
- Fichier à 141 lignes, 13 lignes de plus de 160 colonnes (départ : 13).

## Forme réelle relevée d'un résultat d'outil en erreur (transcript local, sans contenu ni chemin)
Ligne `type: "user"` ; bloc de `message.content` : `{ type: "tool_result", content, is_error: true, tool_use_id: "toolu_…" }` (`is_error` booléen, `tool_use_id` chaîne).

## Écarts
- Écart : précondition « Phase 79 entière / OK-PRECONDITION-79 » non jouée, remplacée par les prérequis réels (79-13 : `reduireCible` présent ; 79-22 : table en mémoire présente) — régime allégé.
- Écart : T24D38.7 ne vérifie pas l'`echec` du fil (prouvé par .1) pour rester vert avant le changement, comme le plan le demande ; il garde durée, compteur de `JSON.parse` et 31 appels.
- Écart : relevé T24G2 et T24H1 à T24H8 : verts sur la base fusionnée, aucun attendu réécrit par ce plan ; `reduireTranscript` et ses exports n'ont pas été modifiés par 79-22.
- Écart : un mutant (`mutd`/`detecte`) est écarté s'il est vide, invalide à `node --check`, ou s'il casse la réduction (garde contre le « détecté » par plantage).
- rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale)
- Plan non marqué audit : pas de mutants au-delà de ceux que le plan nomme.

## Suites jouées sur la tête commitée (8c6e17d76)
- `test-cockpit-transcript.sh` : 125 PASS / 0 FAIL, 65 s (T24F4.1 et T27.B2, rouges connus, verts ce coup-ci ; vus rouges sur les runs de la tâche 1).
- `test-cockpit-securite.sh` : 104 PASS / 0 FAIL, 114 s.
- `test-cockpit-who.sh` : 156 PASS / 1 FAIL, 182 s ; W24.4 (rapport de temps 2N/N du masque sur 5 lecteurs) rouge deux fois (run 1 puis rejeu seul), sonde d'horloge sous charge ; la suite n'importe ni n'appelle `vf-cockpit-transcript.mjs` (aucune occurrence), donc sans lien avec ce plan : rapporté, non corrigé.

Trace du rouge : `74-02-RED-TRACE.md`. Rouges T26/T27 hors périmètre : non corrigés.
