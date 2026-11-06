---
phase: 72
plan: 06
status: complete
requirements: [LANC-01, LANC-02]
commits: [3bc04859, 3b13fffb, 2328ab50, 1f3ba842]
---

# 72-06 — Interface de lancement des cartes (SUMMARY)

Trace du rouge et des mutants : `72-06-RED-TRACE.md`. Commits : `3bc04859` test (suite rouge), `3b13fffb` docs (trace du rouge), `2328ab50` feat (module), `1f3ba842` docs (trace des mutants).

## Livré

- `plugin/cockpit/scripts/vf-cockpit-lancer-ui.mjs` (144 lignes) : `injectionLancer({ indisponible })` (chaîne vide, ou une seule balise `<script>` sans attribut, sans `<style>`), `LIBELLES_VERBES`, `MOTIFS`.
  Le script s'enregistre par `window.VibeFlow.addPanelSection('item', …)` (section `{ html, bind, top: true }`), attend l'API du viewer (50 essais de 100 ms), se tait hors `/project.html` et hors `127.0.0.1`.
- `plugin/cockpit/scripts/tests/test-cockpit-lancer-ui.sh` : LU.S1 à LU.S7 (statique), LU.1 à LU.15 sur page factice sous Chrome (faux viewer qui rejoue la boucle des sections et l'écouteur d'Entrée de `window`, CSP de v2.75.0 via `terminal-aux.mjs csp-v275`), neuf mutants. 45 PASS / 0 FAIL.
- Aucun fichier existant touché ; rien sous `assets/ui/`.

## Forme lue de `GET /api/vf/lancer/cibles`

`{ actif:true, cibles:[{ id, kind, principal, verbes, bloquants, avertissements, lancee }] }` (`terminal` et `claude` ne sont pas lus). Une réponse non OK, non JSON, sans `actif === true` ou sans tableau `cibles` : aucune section.
Seule une cible `n:<id>` ouvre la section, et seulement si `<id>` est dans la liste. `lancee` : `true` -> « Lancée depuis la carte. » ; objet portant `etat` (`attendue`, `vue`, `terminee`) ET `verbe` (ordre fermé) -> « Lancée : <Verbe>, <état> »
(les clés en plus sont ignorées) ; toute autre valeur : aucune ligne. À trancher par le manager (couplage 72-09 / 72-07) : si PL-09.5 garde le booléen, les trois états de 72-07 n'atteignent pas la carte.
Verbes : filtrés sur l'ordre fermé, dédoublonnés, triés dans cet ordre ; principal = `principal` s'il survit au filtre, sinon le premier verbe de l'ordre fermé présent ; aucun verbe valide : « Aucune action disponible. ».
Un bloquant (même de code inconnu) désactive tous les boutons (`disabled`) ; dix lignes au plus par liste.

## Table `MOTIFS` livrée (à aligner avec 72-03)

Bloquants : `phase-finie`, `terminal-absent`, `terminal-arrete`, `premier-plan-occupe`, `claude-introuvable`, `python3-absent`, `phase-hors-motif`, `compartiment-hors-motif`, `mission-hors-phase`.
Avertissements : `dependance-non-close`, `mission-vivante`, `phase-plus-avancee-ailleurs`, `lancement-recent`. Emplacement réservé (P72-D-07, rien ne l'alimente) : `travail-non-commite`.
Les 14 textes sont ceux de la carte des sondes du plan, mot pour mot (LU.S7 les compare). Code inconnu : « Contrôle non reconnu. », jamais le code brut. 72-03 reste la source des noms : tout code ajouté là-bas doit l'être ici.

## Refus lus dans `POST /api/vf/lancer`

202 -> « Proposition envoyée au terminal : <Verbe> — <titre>. Confirmez-la dans le terminal. » (titre lu dans `#panel .pt`, `textContent`, replié, 80 caractères, jamais envoyé). Hors 202 : champ `refus` égal à `bloque` (409 de 72-09) -> « Le lancement est bloqué : voyez les motifs ci-dessus. » ;
sinon 404 -> « Le lancement n'est pas disponible. Relancez /vf-cockpit --terminal. » ; tout autre statut et tout autre `refus` (`jeton`, `origine`, `schema`, …), corps illisible, champ `motif` -> « Le lancement a été refusé. » ; réseau coupé -> « Le cockpit ne répond pas. ».
Le corps envoyé est exactement `{ cible, verbe }` (jamais `chat`, jamais un texte du lab).

## Reste à faire

- 72-09 : brancher `injectionLancer({ indisponible })` dans `injection()` de `vf-cockpit-terminal.mjs`, à côté de `injectionTiroir` ; la preuve octet pour octet de la CSP sans drapeau est la sienne. La page factice reproduit la boucle des sections du viewer (viewer.html l.1537-1546) : 72-12 la rejoue en réel.
- 72-14 : ce script n'émet aucun événement après une proposition ; le tiroir n'est pas prévenu (lecture serveur ou événement du document à trancher).
- 72-13 : aucun champ `chat` ni option « continuer le chat » ici.

## Vérifications

`test-cockpit-lancer-ui.sh` (bash, et lancée depuis zsh) : 45 PASS / 0 FAIL ; `check-file-size.sh` : OK ; `node --check` : OK ; aucun `fiabilite`/`gouvernance` dans `vf-cockpit-*.mjs` ; `assets/ui/` intact ;
`test-cockpit-reseau.sh` 15 PASS / 0 FAIL ; `test-cockpit-assemblage.sh` 40 PASS / 0 FAIL ; `test-cockpit-projet.sh` : 146 PASS / 0 FAIL relevés (dont P4.7 et P4.8) avant l'échéance de 590 s que j'avais fixée (la suite est longue sous charge, d'autres codeurs la jouaient en parallèle) : fin de suite NON observée.
`check-version-sync.sh` rouge attendu jusqu'à 72-15 (non joué).
