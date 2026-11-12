# 79-07 — SUMMARY

Plan 79-07 (SOCL-10, SOCL-11) : une règle physique unique pour les chemins, le scan qui juge un lien comme sa cible, les pilotes nommés vidés pour tout lancement de git. Statut : passed ; audit de sécurité intermédiaire (vf-auditer, avant la reprise) : passed, aucun constat haut.

`AVANT` = 1f4197ce (première ligne de `79-07-RED-TRACE.md`). Point d'arrêt après la tâche 3 : levé par la session principale le 2026-11-12 à 00 h 11, réponse « reprendre tâche 4 », décision déléguée par Samuel (AskUserQuestion session principale, 2026-11-11, « Claude, sur preuves (Recommandé) ») ; contrôles recopiés dans la trace.

## Interface exportée pour 79-13 (amendement A23), recopiée

Nom : `cheminPhysique`. Module : `plugin/cockpit/scripts/vf-cockpit-git-sortant.mjs` (export nommé), copie octet pour octet dans `plugin/cockpit/skills/cockpit-moteur/scripts/lib/vf-git-sortant.mjs`. Signature : `cheminPhysique(chemin, { plusProcheParent = false } = {})` rend une chaîne (chemin absolu physique, liens résolus par le noyau) ou `null`.
- Valeur non chaîne, vide ou contenant un octet nul : `null`. Chemin relatif : pris relativement au dossier courant par concaténation, sans normalisation.
- Mode strict : realpath natif ; tout échec rend `null` (jamais la forme écrite).
- `plusProcheParent: true` (cible d'un fichier supprimé) : sur ENOENT seulement, remonte au plus proche parent qui se résout, rend ce parent physique suivi du reste du nom ; `null` si le reste contient `..` ou `.` (un `..` après un élément absent n'a pas de sens physique), si un élément existant ne se résout pas (lien pendant, boucle, droits, ENOTDIR).
- Jamais de chemin émis tel quel : l'appelant (79-13) ramène le résultat à la racine du lab (amendements A22, A33) ou rend « un fichier hors du lab » sur `null`. Le chemin absolu ne sort jamais de la fonction vers une donnée publique.
- Stabilité : nom et signature sont figés par ce plan ; G17 de test-cockpit-git-config-depot.sh la protège ; le SUMMARY de ce plan répète cette section. Consommateurs prévus : 79-13 (cibles du radar, A23) et 79-16 (gardes de chemin de 79-06 et de serve.mjs, A37).

## Commits `(79-07)` (ordre)

6c6a8479 témoins rouges · 0180f45c extraction du lanceur · 199d725b règle physique · d99b396a ancres de worktreeVerifie · b17f5510 amendement · d4db658e mutants de la règle · bca33d4b point d'arrêt · aa2b04f1 reprise · c5f7d5e0 scan (D-M15) · 6c41f105 mutants du moteur · 8821299f colonnes du lanceur · ca2cb1c9 amendement tâche 5 · 28621b52 reciblage terminal-lanceur · c8a009df pilotes nommés · 0003b927 mutants D7 · e6838fe2 amendement tâche ajoutée · e3579216 gitSortant, dossier réel du dépôt · 730416dc G19, M-DEDANS, trace.

## Fichiers modifiés

vf-cockpit-git-sortant.mjs et sa copie lib/vf-git-sortant.mjs (octet pour octet), scan.mjs, vf-cockpit-paths.mjs, vf-cockpit-git-lanceur.mjs (neuf), vf-cockpit-git-durci.mjs, vf-cockpit-git-details.mjs, test-cockpit-git-config-depot.sh (A8 à A14, B5, G16 à G19, D6, D7 et leurs mutants), test-cockpit-git-env.sh, 79-07-RED-TRACE.md. Hors liste d'origine, ajoutés à `files_modified` par amendement daté (déviations minimales, aucune n'est surveillée par check-gate-touche.sh) : test-cockpit-terminal-lanceur.sh (mutants gitnomnu et whonomnu reciblés sur le lanceur extrait), test-cockpit-git-signature.sh (R2.2c : sous-commande `config` de la lecture des pilotes), test-cockpit-git-details.sh (M-RETOUR neutralise la seconde défense). test-cockpit-confinement.sh non touchée (A37).

## Ce que le plan retire

La règle lexicale de gitSortant ; le repli lexical de `real()` et les appels au realpath JS des gardes (gitSortant, paths.mjs, scan.mjs, worktreeVerifie) ; `SOUS_COMMANDES_FILTRANTES` ; le lancement des enfants non git sous `envEnfant(lab)` seul ; le bloc de lancement de paths.mjs, déplacé dans le lanceur (296 lignes devenues 166) ; le caractère « lien permis parce que sa forme reste dans le dossier git ».

## Preuve générative

G16 : graine par défaut 4217 (450 arbres, 1402 liens, 1,7 à 4 s hors charge, 12 s sous charge 30) ; rejeu `VF_G16_GRAINE=424242` vert. Quatre mutants de la règle (M-LEXICAL, M-JS, M-REPLI, M-VERROU), deux du scan (M-MEMBRE, M-JS-SCAN), six des pilotes (M-PORTEE, M-FILTRES-SEULS, M-LISTE, M-BASH, M-MEMO, M-OPTIONS vert par redondance voulue), un de la tâche ajoutée (M-DEDANS) : causes, attendus et obtenus dans `79-07-RED-TRACE.md`.

## Écarts et amendements datés

(1) ancres de worktreeVerifie (b17f5510) ; (2) tâche 5 (ca2cb1c9) : sonde de refus exacte pour M-OPTIONS, E9.5b/E9.6a/M-LECTURE de git-env au sens neuf (le refus vaut pour toute sous-commande), suites hors périmètre ; (3) tâche ajoutée (e6838fe2) ; (4) colonnes : aucune ligne neuve de plus de 160 points de code dans le lanceur, git-durci, scan.mjs et git-sortant (mesure contre le paths.mjs d'avant le plan), commit 8821299f ; (5) un renommage de variable fautif des tâches 1 à 3 (`.sorlk_t()` pour `.sort()` dans D6.4) corrigé.

## Relevés à transmettre

- serve.mjs : service statique jugé par le realpath JS (même défaut de maillon divergent) : à 79-16 (A37).
- vf-cockpit-transcript.mjs `cheminDuLab` : à 79-13 (A23, `cheminPhysique`).
- vf-cockpit-live.mjs : appel direct de driver-lock.sh : à 79-09 (il passera par shBorne et recevra envGit).
- vf-cockpit-terminal.mjs:49 (constat bas 1 de l'audit) : à 79-06.
- Repli lexical d'affichage de vf-cockpit-git.mjs, vf-cockpit-git-entete.mjs, vf-cockpit-who.mjs : aucune lecture gardée, aucun correctif.
- 79-06 (même fichier de suite, test-cockpit-terminal-lanceur.sh) : le reciblage des deux mutants est fait ; le conserver à la jointure.
- Coût : toute lecture git du socle lit les pilotes une fois (mémo de 2 s par dossier et lab) ; limite écrite et testée (D6.5).
- La classe de la tâche ajoutée n'est pas atteignable aujourd'hui par `discover()` (la marche saute les liens) ; elle ferme le point central pour les appelants futurs.

## Audit de sécurité

Intermédiaire (vf-auditer, avant la reprise) : passed, aucun constat haut ; constat bas 2 (dossier réel du dépôt) fermé par la tâche ajoutée ; constat bas 1 renvoyé à 79-06. L'audit de fin de segment (manager) couvre les tâches 4 à 6.

## Suites jouées seules (état final)

depot 110/0, git-env 135/0, git-details 136/0 (X6.2 rouge sous charge de 30 à 45, verte rejouée seule), confinement 66/0, git 118/0, vendor 87/0, who 157/0, signal 76/0, path-enfants 37/0, avancement 69/0, assemblage 49/0, git-signature 45/0 (R2.3a et M-SIG-LENTE rouges sous charge, vertes rejouées seules), terminal-lanceur 111/0, lancer-cibles 51/0, terminal-serveur 208/0.

Rouges rapportés, non imputables à 79-07 : test-cockpit-securite.sh FB3.5 (délai de 10 s, rouge de charge, déjà noté avant le plan) ; au dernier rejeu AM4.1 à AM4.4 et M-TERM.0 (le serveur lancé depuis une copie du module : « vf-cockpit-env.mjs est absent », terminal forké depuis la sortie) : surface de 79-06 (assemblage du module, en cours dans le même arbre), verte à 92/0 au rejeu précédent de ce plan ; à rejouer après 79-06.

## Correction ciblée après l'audit de fin de plan (2026-11-12)

Constat haut T-79-705 : la classe « pilote de nom vide » (filtre, fusion, diff) échappait au vidage ; le motif passé à git et l'analyse des clés exigeaient un nom non vide. Correctif : les deux acceptent un nom vide, et toute clé listée que l'analyse ne comprend pas rend la liste non fiable (refus). Témoins rouges D8.0 (git brut), D8.1 (`r,r,v,v,r,r,r` avant, `v,v,v,v,v,v,v` après), D8.2 ; mutants M-VIDE-GIT, M-VIDE-ECARTE, M-VIDE-ANALYSE, M-COMPRIS (section D9 de test-cockpit-git-config-depot.sh), causes et obtenus dans `79-07-RED-TRACE.md`. Deux constats bas : clause du lien retour de `gitSortant` tenue par G19.5 et M-RETOUR-G (cas vert sur le code présent, la preuve est le mutant) ; R2.2d et son témoin R2.2e dans test-cockpit-git-signature.sh. test-cockpit-git-env.sh non touchée. Copies du module partagé identiques (`cmp`), aucune ligne neuve de plus de 160 points de code.

Commits `(79-07)` : e4280349 amendement daté · f4485088 correctif, D8, D9, G19.5, M-RETOUR-G · a34b914e R2.2d, R2.2e.

Suites jouées seules : git-config-depot 126/0, git-env 135/0, git-signature 47/0, git-details 136/0 (X6.2 verte rejouée seule), terminal-lanceur 111/0, git 118/0, who 157/0, vendor 87/0, confinement 66/0, avancement 69/0, lancer-cibles 51/0, path-enfants 37/0, signal 76/0. Rouges rapportés, non imputables : assemblage AM4.15a, AM4.16, M-PURGE-LARGE.0, M-ORDRE.0 (identiques sur un instantané de la tête avant le mandat) ; securite FB3.5, AM4.1 à AM4.4, M-TERM.0 (surface d'assemblage d'un autre plan).

## Correction ciblée n°2 (2026-11-12) — git absent

Régression de la tâche 5 : git introuvable rendait un délai au lieu d'une absence (H5.1b rouge à la tête). `absent` est propagé de la lecture des pilotes au refus, le refus fermé tient pour tout autre échec. D10.1 à D10.3 et M-ABSENT dans test-cockpit-git-config-depot.sh (le témoin tourne en CI Linux : PATH du processus de la sonde sans git). H7.5b non reproduit (PASS à la tête avant et après correctif, PASS à la base) : rien corrigé. Suites jouées seules : git-config-depot 131/0, git-entete 136/0, git-signature 47/0, git-details 136/0, terminal-lanceur 111/0, git 118/0, who 157/0, confinement 111/0. test-cockpit-git-env.sh non touchée.

## Correction ciblée n°3 (2026-11-12)

D10.4 à D10.6 (faux git à code 128, à délai dépassé, échéance passée : jamais « absent »), M-ABSENT-LARGE (le mutant de l'audit rougit D10.4 et D10.6), D10.7 et M-BINAIRE (aucun appelant de production ne passe `binaire` : limite lecture/lancement gardée), dossier de travail de la suite sous TMPDIR. Aucun code produit touché. test-cockpit-git-config-depot.sh 138/0.
