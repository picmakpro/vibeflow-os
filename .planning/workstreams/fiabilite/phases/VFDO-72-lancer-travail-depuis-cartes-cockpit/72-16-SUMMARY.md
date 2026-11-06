---
phase: 72
plan: 16
status: complete-with-one-open-finding
requirements: [LANC-09]
---

# 72-16 — SUMMARY : le mode retenu survit aux relances du cockpit (P72-D-20)

Exécution INLINE (un autre codeur travaillait dans le même arbre) ; trace du rouge, des mutants et du tableau de transposition : `72-16-RED-TRACE.md`.

## Commits (branche feat/phase-72-lancer-depuis-cartes)

| SHA | Sujet |
|---|---|
| 60a7c152 | test(72-16) suite du mode retenu et ses dix-huit mutants, rouge joué sur la base |
| 2d54848e | docs(72-16) trace du rouge |
| d36b214f | test(72-16) harnais de la suite du mode retenu : mutants du processus avec session, témoin du module, lab à phase ouverte |
| af4cf700 | feat(72-16) mémoire du mode retenu : fichier du lab tenu par Q, écriture au lancement accepté, lecture dans la proposition |
| 3fa5a965 | docs(72-16) trace des mutants du processus |
| a44ab153 | test(72-16) bandeau transposé au mode servi (LB.C4, LB.E2, LB.E5, LB.E6 et mutants), rouge joué sur le client de la base |
| 45eac55c | feat(72-16) présélection du mode lue de la proposition servie par Q, stockage du navigateur retiré |
| (suivants) | test(72-16) suites bandeau et bout en bout au vert ; docs(72-16) README, recensement, trace, résumé |

## Lignes avant / après

- `vf-cockpit-terminal-processus.mjs` : 199 -> 203 (+5 / -1). `vf-cockpit-lancer-mode.mjs` : neuf, 57 lignes.
- `vf-cockpit-terminal-client.mjs` : 280 -> 279 (plafond LB.S3 de 280, jamais relevé ; aucun module neuf nécessaire).

## Forme lue de GET /proposition

Réponse `en-attente` : les clés du contrat §4 plus `mode_retenu` (un mot de `default, acceptEdits, plan, herite`) ; réponse `aucune` : la seule clé `etat`. `72-CONTRATS.md` §4 étendu.

## Ancres `garde:mode-*` (texte réel)

- processus : `const memoireMode = creerMemoireMode({ fichier: path.join(here, '.cache', FICHIER_MODE) }); // garde:mode-support` ; `const lireProposition = () => { const p = lq.lire(); return p.etat === 'en-attente' ? { ...p, mode_retenu: memoireMode.lire() } : p; }; // garde:mode-servi` ; `memoireMode.ecrire(demande.mode); // garde:mode-ecrit` (après le test de `w.ok`, avant `lq.confirmer`).
- module : `garde:mode-nofollow`, `garde:mode-nonblock`, `garde:mode-uid`, `garde:mode-droits`, `garde:mode-taille`, `garde:mode-valide`, `garde:mode-rename`, `garde:mode-unlink`.
- client : `const v = p.mode_retenu; // garde:mode-lecture` ; `return MODES.indexOf(v) >= 0 ? v : 'default'; // garde:mode-relu`.

## Tableau de transposition LB.C4 / LB.E2 / LB.E5 / LB.E6

Voir `72-16-RED-TRACE.md` (« Tableau de transposition ») : chaque ligne donne l'attendu avant, après et le verdict « pas plus faible ». LB.E2 a dû être transposé aussi (le plan le disait « intact » : son dernier champ lisait la clé retirée).

## Branchements à recenser pour le merge (B4, B7, B11, B12)

`72-BRANCHEMENTS-MERGE.md` §5, avec les nombres de lignes relevés sur le diff.

## Points d'audit de P72-D-02bis / P72-D-20 (à relire à la clôture)

1. `lancer()` : l'ordre des appels (`consommer`, `sessions.lancer`, test de `w.ok`, `memoireMode.ecrire`, `lq.confirmer`) ; mutants M-ECRITURE-A-LA-DEMANDE et M-ECRITURE-AVANT-LE-SHELL.
2. `charger()` du module : O_NOFOLLOW, O_NONBLOCK, `fstat` sur le descripteur, propriétaire, droits, 32 octets avant lecture, égalité à quatre mots ; mutants M-SUIT-LIEN, M-BLOQUANT, M-PROPRIETAIRE, M-DROITS-IGNORES, M-TAILLE, M-SANS-REVALIDATION.
3. `lireProposition` : aucune clé hors liste, `mode_retenu` seulement dans `en-attente` ; M-MODE-DANS-AUCUNE.
4. Diff du client : aucune lecture ni écriture de stockage pour le mode (LM.C3, LB.C4) ; M-STOCKAGE-RESTE.
5. Liste statique des fichiers côté P (LM.S2) : dérivée par `find`, jamais tenue à la main ; seul le processus importe le module ; M-P-LIT-LE-FICHIER. Limite dite (T-72-128) : c'est P qui fournit `here` à Q par l'IPC `init` ; l'étanchéité est celle du code.

## Écarts dits

- LM.Q8 et LM.Q6 ne mesurent pas « 0 octet à /entree » : la suite du mode n'a pas de client navigateur ; l'absence de retour chariot est mesurée par « le faux claude n'a pas tourné », le geste du client reste couvert par LB.E2 (Chrome).
- Hors `files_modified` : `72-16-PLAN.md` (phrase de l'INFO dans T-72-128), `test-cockpit-lancer-bout-en-bout.sh` (CH2 : premier lancement = fichier absent).
- FINDING OUVERT : `test-cockpit-lancer-xss.sh` l.46-47 relève la clé du mode dans la constante `CLE_MODE` du client, retirée par ce plan : 75 PASS / 1 FAIL (« clé du mode introuvable »). Fichier du codeur voisin (F-1), non touché. Correctif d'une ligne (littéral `vf.terminal.mode` : la sonde C1l.4a ne teste que l'accès de P au stockage de Q).
- `check-version-sync.sh` : écart de nombre de suites (README 167, réel 181), préexistant (les suites de la Phase 72) : à recompter par 72-15.

## Rappel au manager

72-15 (bump de version, README, CHANGELOG) doit dépendre de 72-16 : la ligne d'usage du README est posée par ce plan, 72-15 ajoute sans réécrire.
