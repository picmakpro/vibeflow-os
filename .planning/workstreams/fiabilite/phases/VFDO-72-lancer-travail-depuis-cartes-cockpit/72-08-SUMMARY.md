# 72-08 — SUMMARY : bandeau de proposition de la page Q

Statut : passed. Trace du rouge et des mutants : `72-08-RED-TRACE.md`.

## Commits
- `8bb0dae4` test(72-08) : suite neuve et ses quatorze mutants, rouge joué sur la base
- `6f833d35` docs(72-08) : trace du rouge
- `540ed066` feat(72-08) : vue (`vfTermVue.proposition`)
- `a347dc0f` test(72-08) : attendus de LB.V1 et M-CLIC-NON-FIABLE corrigés, attentes souples
- `5f0bf133` feat(72-08) : client (sondage précoce, `POST /lancer`, mode retenu, message fixe)
- le commit docs de cette trace et de ce résumé

## Lignes finales
Client 279 lignes (239 avant), vue 186 lignes (125 avant). Aucun fichier de style, de page ni de tiroir touché.

## Baselines LB.S1 (mesurées sur la base, inchangées)
`location.search` 2, `URLSearchParams` 0, `searchParams` 0, `location.href` 0 ; écouteurs de messages 0 ; `postMessage(` 1 ; couleurs `#xxx` vue 6 / client 0 ; `rgb(` vue 3 ; `px` client 1.

## Forme lue
- `GET /proposition` : `{ etat:'aucune' }` ou `{ etat:'en-attente', id (^[A-Za-z0-9_-]{8,64}$), verbe, intention (≤200), phase (≤20), ws (≤40 ou null), lignes:{default,acceptEdits,plan,herite} (ASCII imprimable 1..400), bloquants, avertissements (≤20 chaînes ≤40), arme_apres_ms (0..10000), expire_ms (1..600000) }`. Toute autre forme vaut `aucune`. `expire_ms` est validé, non utilisé.
- `POST /lancer` `{ id, mode }` : 204 ok, 409 occupe, 425 attendre, 404 absente (proposition consommée localement), 410 sans-session, 400 et tout autre statut refus, exception reseau. `POST /annuler` `{ id }` : aucun statut attendu.
- Noms normatifs pour 72-13 : `forme`, `lancer(mode)` (72-13 ajoute `avecChat`), `vfTermVue.proposition(p, cb)`.

## Table MOTIFS livrée
Quatorze codes (9 bloquants, 4 avertissements, `travail-non-commite`), textes de 72-06 mot pour mot, inconnu « Contrôle non reconnu. » ; table sans prototype (`constructor` n'affiche pas une fonction). À aligner avec 72-03 et 72-06.

## Stockage
Clé unique nouvelle : `vf.terminal.mode`, relue contre la liste fermée à chaque lecture. Choix à auditer (P72-D-02bis) : le mode n'est retenu qu'au 204, jamais sur un changement du sélecteur.

## Pour 72-14 et l'audit
- 72-14 : ajouter `proposition` à `LISTE_MESSAGES` du tiroir (le client l'émet déjà, avant `visible()`).
- Ligne du sondage précoce : `lire(); setInterval(lire, PROPOSITION_MS); // garde:sondage-precoce` ; ligne du crochet : `pret = true; terminal = term; afficher(); // garde:pret`.
- T-72-48 : dans le cas froid, le premier `GET /proposition` précède l'ouverture du tiroir, donc l'armement tenu par l'état n'ajoute presque rien ; la garde réelle reste le délai côté bandeau (LB.V3, LB.E2).

## Écarts et remarques
- Jetons 71.5 (message du manager) : le bandeau n'ajoute aucune valeur de style, aucune bordure ni fond. Il réutilise les classes `vf-q-*` existantes, dont la pastille `vf-q-attention` (point coloré par variable) et les textes `vf-q-attention-texte` / `vf-q-erreur-texte` (couleur de texte par variable), comme le bandeau de collage. Pas de glyphe d'état ajouté ; le `select` natif garde le style du navigateur. Le manager remplacera ou ajustera à la 71.5.
- Les deux premiers commits de suite n'ont pas le trailer `Gate-Touche` (le plan mesure `plugin/cockpit/scripts/tests/` hors des six classes de `check-gate-touche.sh`).
