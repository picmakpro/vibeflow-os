# Mission — Phase 72 « Lancer du travail depuis les cartes du cockpit » (compartiment fiabilite)

Manager : vf-dev-manager, reprise après crash (owner `mgr72-reprise`, verrou de phase repris par takeover, génération `DRIVER.lock.gen.1793917130.97826`). Branche `feat/phase-72-lancer-depuis-cartes`, worktree `.claude/worktrees/phase-72`. Brief et arbitrages d'origine : `.planning/archives/stash/2026-11-05-crash-mandat-72.md` (dépôt principal).

## Plan de bataille (DAG)

`.planning/workstreams/fiabilite/MISSION-72.dag.json` (non suivi). Nœuds repris : ex-02, ex-09, ex-14 (interrompus par le crash), puis ex-10, vague 3 (ex-11, ex-12, ex-13) en parallèle, ex-16 (plan neuf, P72-D-20), ex-15 (bump). Pipelining des juges : revue et audit par lot à SHA figé (lot 1 84501819, lot 2 b5efcc40 / 9b63d963 rebasé, lot 3 4fa5fe95) pendant que l'exécution avançait ; recette par juge Playwright au SHA 4fa5fe95 ; correctifs ciblés (A, B, C, D, F, G, H, réglages visuels) ; nœud docs en deux parties ; non-régression complète.

## Résultat

- 16 plans sur 16 exécutés (72-16 ajouté par P72-D-20), cockpit v1.4.0, 181 suites.
- Revue : lots 1 et 3 `passed`, lot 2 `gaps_found` (S1, déjà corrigé par acb032e1). Tous les findings auto-fix corrigés avec témoin rouge et mutant.
- Audit sécurité : lot 1 et 2 ESCALATE (F6, F-1), lot 3 SECURED ; rapport `72-SECURITY.md`, aucun finding ouvert, résiduels acceptés écrits.
- Recette par juge (Chrome, faux claude) : étapes fonctionnelles 1 à 6 OK, réglages visuels faits (b05d3001).
- Arbitrages humains de la reprise (Samuel, AskUserQuestion, session principale, 2026-11-06) : SP-6 « Fichier du lab (Recommandé) » (P72-D-20) ; F-1 « Geste humain exigé (Recommandé) » (P72-D-21), puis, prémisse corrigée par le manager, « Garder, risque écrit (Recommandé) » (P72-D-22).

## Consignés, non corrigés (hors périmètre)

- BACKLOG : surface du chat `/api/ask` pilotable par un script de la page Projet (phases 69-70) ; `CLAUDE_EFFORT` / `CLAUDE_PID` transmis au claude lancé (filtre d'env de la Phase 71) ; barre de question rangée à l'ouverture automatique du tiroir (frappes perdues).
- Charte 71.5 : pastille et texte ambre `vf-q-attention`, halo des cartes « en cours » : classes de la Phase 71, possédées par la 71.5 ; replis `var(--sp-8, 8px)` et feuille `<style id="vf-lancer-style">` à fondre à la fusion de la 71.5 (72-BRANCHEMENTS-MERGE §6).
- Course `lstat`/ouverture sur le dossier support du mode (L1), temporaires non balayés après SIGKILL (S-3) : consignés.

## Points de goût pour Samuel (recette)

Intentions en ASCII sans accent (alphabet fermé de la ligne, voulu) ; bouton principal « Cadrer » désactivé sur une phase finie ; pas de bouton « Lancer » sur la carte (l'action est le verbe) ; message du refus 409 générique (quatre causes indistinguables côté serveur) ; ligne `VFP>` vide ajoutée par le Ctrl-C avant la ligne proposée ; « Lancée » et la récence ne survivent pas à une relance du cockpit.

## Journal de la reprise
## Reprise après crash (2026-11-05, ~23 h 30)

- Crash machine à 21 h 58 (WindowServer tué par le watchdog) : manager `mgr72`, ses trois codeurs (ex-02, ex-09, ex-14) et la session pilote morts.
- Décision de Samuel, message direct en session principale, 2026-11-05 vers 23 h 20 : « ok 1, mais non on reprend tel quel […] » — même méthode, mêmes vagues parallèles.
- Verrou de phase repris par `takeover` (owner `mgr72-reprise`, génération `DRIVER.lock.gen.1793917130.97826`, `recovered: true`) ; trois enfants fantômes fermés `failed` au registre (a615ec49347950fb3 ex-14, a3a27e6cad4fd8e6f ex-09, abd13b2719bedf11f ex-02) ; registre à 0.
- Gate d'invariants : rc 3 (SAIN). Flags d'enchaînement relus : `false`/`false` (aucune écriture).
- `REBASE_HEAD` résiduel dans le git-dir du worktree : aucun `rebase-merge`/`rebase-apply`, rebase terminé, résidu inerte.
- Arbre non commité attribué par `files_modified` des plans : `vf-cockpit-terminal-session.mjs` → 72-02 ; `vf-cockpit-server.mjs`, `vf-cockpit-terminal.mjs`, `vf-cockpit-lancer.mjs`, `vf-cockpit-lancer-canal.mjs` → 72-09 ; `vf-cockpit-terminal-tiroir.mjs` → 72-14. Périmètres disjoints. Décision : chaque plan est repris par un codeur neuf qui part du travail partiel (non vérifié), le juge contre la suite rouge déjà commitée, le termine ou le refait. Sauvegarde : `.planning/archives/stash/2026-11-05-crash-phase-72.patch` (dépôt principal).
- Redispatch des trois nœuds interrompus, en parallèle, même arbre, commits par pathspec : ex-02 (af9091d55052fa204), ex-09 (a7aab0a0b64490944), ex-14 (a03aa7bcb3c7ac418).
- ex-02 rendu passed (commits ffbaa971, 9ac5e282, 1394276e) ; ex-10 dispatché (a204f23c199e3a3a9).
- ex-09 rendu passed (6fde1538, ea4f3e3d) ; à reporter : contrat §113 « lancee » booléen vs forme riche {etat,verbe}|false (doc à harmoniser) ; hunk sourceWho en plus dans server.mjs (merge avec la 78).
- ex-14 rendu passed (11ba668f, d9f30539) ; à rejouer hors charge : test-cockpit-securite.sh FB3.5 (plafond d'horloge 10 s, obtenu 16 s sous load 15-19), suite non touchée par la 72.
- ex-10 rendu passed (ea718f86..84501819) ; docs à corriger : 72-10-PLAN B3 et BRANCHEMENTS-MERGE décrivent l'ajout de /proposition à la ligne navigateur (réalisé autrement : controle() via l'URL de /etat, 549d3bcc) ; statut 504 de POST /lancer absent du contrat §4.
- Vague 3 dispatchée en parallèle : ex-11 (af3ecc605e911a0fa), ex-12 (a87060b803ad60e7b), ex-13 (a0079971c8da64201).
- Pipelining : revue (a9ed5b46e3e7055d9) et audit sécurité (ad9bd57ce58e084c8) du lot 1 au SHA figé 84501819 pendant la vague 3 ; revue/audit de jointure ensuite.

## Revue et audit du lot 1 (SHA 84501819)

- Revue : `passed`, 11 mineurs (ST-1 à ST-5, SP-1 à SP-6). Audit : `human_needed` sur F6 seul, aucune menace haute ou moyenne confirmée par sonde, F1 à F5 low/info.
- Fusion dédupliquée, correctifs ciblés à dispatcher après la vague 3 :
  - côté Q (client, vue, tiroir, lancer-ui) : F1 focus déplacé par une proposition (fenêtre non focalisée : frappes de P vers le shell) ; ST-2 parité des trois tables de motifs ; ST-5 message faux pour `occupee` ; SP-1 cadre de Q absent après rechargement (proposition invisible).
  - côté serveur/PTY (pty.py, processus, lancer, cibles, suivi, lancer-q) : F3 témoin de la garde onglet de /annuler et du code terminal-indisponible ; ST-1 source unique de RECENCE_MS et code mort exporté ; ST-3 délai d'armement réglable par l'environnement ; ST-4 OSError rendu `ok`.
  - documentaires : contrat §4 (504), §9 et §113 (`lancee` forme riche), BRANCHEMENTS B5 (hunks du serveur), plan 72-10 B3, T-72-08 (revalidation Python = alphabet + préfixe seulement), SUMMARY 72-14 incohérent avec sa RED-TRACE, 72-RESEARCH.md:238 (check-machine-paths).
- Décisions du manager (techniques, hors périmètre produit) : ST-3 → l'environnement ne peut que RALLONGER le délai d'armement, jamais l'abaisser sous la valeur de production ; SP-1 → un POST accepté rend la proposition visible (P monte et ouvre le tiroir sans focus si le cadre de Q n'existe pas) ; F2 (« au repos » = PID du shell au premier plan) → limite documentée au README, pas de détection d'invite ; F5 (504 puis ligne tardive) → documentée au contrat §4.
- À l'humain : F6 (portée réelle du mode « hérité ») et SP-6 (le dernier mode choisi ne survit pas à la relance du cockpit), après recherche documentaire sur F6.
- Correctifs documentaires faits (94bdb6e2). Le point 72-RESEARCH.md:238 était déjà propre ; check-machine-paths rouge sur 72-12-RED-TRACE.md:72, signalé au codeur de 72-12.
- Recherche F6 (doc officielle Claude Code, poste en 2.1.318) : depuis la v2.1.257, `defaultMode: bypassPermissions` (et auto) venu de .claude/settings.json ou settings.local.json d'un projet est ignoré ; `skipDangerousModePermissionPrompt` n'est pas lu depuis un dépôt ; `--permission-mode` l'emporte sur defaultMode. Donc « hérité » ne peut être bypass que si le poste le pose : pas de risque nouveau par rapport à Q2. Résidu : un projet peut imposer acceptEdits ; version antérieure à 2.1.257. Décision du manager : corriger NOTE_HERITE (sources réelles), limite de version au README. Remonté à la session principale pour information.
- SP-6 posé à Samuel via la session principale (SendMessage, 2026-11-06), recommandation A (mode persisté côté processus de Q, servi à la seule origine Q). En attente.
- SP-6 tranché : Samuel, AskUserQuestion session principale, 2026-11-06, « Fichier du lab (Recommandé) » (option A). Consigné P72-D-20. Plan neuf 72-16 en cours d'écriture (ac180880b3398b3d7) ; exécution après ex-13 et fix-srv-a ; ex-15 dépendra de ex-16.
- Correctifs serveur/PTY (F3, ST-1, ST-3, ST-4) dispatchés en parallèle de la vague 3 (a37fc55e78c808073).
- ex-12 rendu gaps_found (217f1c81, d2b6bb01, 0c164b5f, fdcdde93, a5805a81) : J1 (boucle de toutes les suites sur arbre propre) transféré au nœud de non-régression du manager ; rouge LB.S3 (client 282 lignes > 280) observé pendant l'édition de 72-13, à reconstater.
- ex-11 rendu passed (35d72e63, 833806b1). plan-16 écrit (781adf29), plan-checker 0 bloquant mais non relancé après correction : re-vérification commandée avant exécution.
- check-16 : PASS, 0 bloquant, 3 avertissements (LB.C4 l.619 non transposée ; ensemble FAIL de la tâche 2 contient LM.C2 probablement verte ; témoin de LB.E5 à reprendre sur CLE_SECRET) → imposés au mandat d'exécution de 72-16.
- ex-13 rendu passed (2c73b795..b5efcc40). Décision du manager : M-CHAT-NON-VALIDE-Q « absorbé » accepté tel quel (défense en profondeur, le gabarit refuse aussi) — ce n'est pas une preuve de la garde de Q, ne pas le compter comme mutant tué. Client de Q à 280 lignes, au plafond de LB.S3 : fix-ui-a puis ex-16 en séquence sur ce fichier.
- fix-srv-a rendu passed (bda27787, 41f08dbe, 9dc27b50, b6e2c21a, 1f220a78). Nouveau motif `ecriture` → HTTP 410, accepté par le manager ; à inscrire au contrat §4 (nœud docs). Code mort de suivi retiré avec ses témoins (LS2.1, M-RECENCE-INFINIE) ; la récence reste témoignée dans la suite cibles.
- Lot 2 (b5efcc40) : revue a0d251c7c906596bb, audit ad23a83aa0069a2d5 ; fix-ui-a a989ef645619b6d6a en parallèle.
- Audit lot 2 (b5efcc40) : ESCALATE sur F-1 (moyen conditionnel : une charge dans P peut faire retenir l'UUID d'une conversation qu'elle a écrite et proposer « continuer le chat » ; la confirmation humaine couvre la ligne, pas le contexte repris). Remonté à Samuel via la session principale (SendMessage, 2026-11-06), recommandation A (UUID retenu seulement sur geste humain réel, témoin XSS chat:true). F-2 (mode réel de « hérité » en reprise) : sonde réelle commandée (a509a141eea6eab02). F-3 (M-LISTE-PAGE périmé dans la suite bout-en-bout après ST-1) et F-4 (410 de `ecriture` sans témoin) : correctif de témoins (a98c3acba9446daa3).
- F-1 tranché : Samuel, AskUserQuestion session principale, 2026-11-06, « Geste humain exigé (Recommandé) » (option A). À consigner P72-D-21. Résiduel accepté en connaissance de cause : un script peut attendre le prochain geste réel pour glisser sa question. À écrire au README (72-15) et au rapport d'audit. Options B, C et D écartées.
- fix-ui-a rendu passed (2cf478f4, 90237961) : F1, SP-1, ST-2, ST-5 (texte vrai pour les quatre causes du 409 ; décision du manager : pas de corps de refus côté serveur, le texte commun suffit), F6 (NOTE_HERITE).
- fix-c rendu passed (acb032e1) : F-3 et F-4.
- Sonde F-2 (vrai claude 2.1.318) : `-r … --fork-session` sans `--permission-mode` ne restaure PAS `dontAsk` ; la reprise prend le mode par défaut du poste (`auto` sur ce poste : écriture sans invite), comme une session neuve. La note corrigée du mode hérité est donc juste aussi pour la variante chat. À écrire au README : sur un poste où le défaut est `auto`, « hérité » écrit sans invite. Transcripts de sonde laissés sous ~/.claude/projects/ (hors dépôt).
- ex-16 (a4b1ee9717a90e84e) et fix-f1 (add64587948f98078) dispatchés en parallèle.
- Revue lot 2 (b5efcc40) : gaps_found sur S1 (majeur : M-LISTE-PAGE périmé, suite bout-en-bout rouge) — déjà corrigé par fix-c (acb032e1), constat indépendant de l'audit F-3 ; S2 (docstring « poussée » plus forte que le code : `ok` = mise en file, écriture tentée) et P1 (motif `ecriture` absent du contrat §4/§5 et de la docstring de module de pty.py) → nœud docs ; S3 (motif UUID lâche côté page) → ajouté au mandat fix-f1. Statut 410 de `ecriture` validé par le manager.
- fix-f1 rendu gaps_found (2b9e23b9, P72-D-21 consigné, S3 fait). Garde d'activation livrée et témoignée, mais elle ne ferme que le chemin par l'interface : la route de P accepte `chat:<uuid>` du corps, donc une charge dans P le POSTe directement (lecture de la route + TC.7). La prémisse de l'arbitrage F-1 (« un script ne peut pas forger l'activation » ⇒ fermeture) était fausse : erreur du manager. Re-question à Samuel via la session principale (SendMessage, 2026-11-06) : C' (garder, résiduel honnête, recommandé), B' (le terminal affiche date et première question lues dans le transcript local), D (reporter). Signalé hors phase : une charge dans P pilote déjà le chat (Read, Grep, Glob, Bash en liste blanche), surface des phases 69-70.
- F-1 re-tranché : Samuel, AskUserQuestion session principale, 2026-11-06, « Garder, risque écrit (Recommandé) » (option C'), à consigner P72-D-22 ; remplace P72-D-21 comme arbitrage sur le résiduel, le correctif 2b9e23b9 reste. Demandes d'ordonnancement de la session principale : témoin de caractérisation du résiduel (exécuté, pas lu) et entrée de BACKLOG pour la surface du chat (phases 69-70). Dispatché : a8a6443e31793432f.
- res-f1 rendu passed (0a1d90f8, 86d6a4b9, 45690d08) : manche RES (caractérisation, Chrome réel, 202 + case décochée, 0 octet, 0 argv ; 3 mutants rouges). Précision mesurée : l'identifiant n'apparaît dans la ligne qu'une fois la case cochée → README : « affiché quand la case est cochée ».
- ex-16 rendu gaps_found (60a7c152..1918d7ad) : un seul rouge, test-cockpit-lancer-xss.sh C1l.4a (« clé du mode introuvable », constante CLE_MODE retirée par 72-16) → fix-final. Client 279 lignes. check-version-sync rouge sur le nombre de suites du README (à recompter par 72-15).
- Rebase sur origin/main (57e7957f) : 106 commits, sans conflit ; HEAD 4fa5fe95 (avant : 1918d7ad).
- Frontière en parallèle : ex-15 (a78bcd70ad6ec0d5d), fix-final (a5eefc5ec6c282619), revue lot 3 (a5b5c816e4ccdb94d), audit lot 3 / ré-audit F-1 (a9cbfbdb4d9466968), recette par juge Playwright (a1f5888da6ef651b9), tous au SHA figé 4fa5fe95 pour les juges.
- ex-15 rendu passed (c2239e73, 0bdf7045, 68ded1c5, af16ba72) : cockpit v1.4.0, 181 suites, 18 gates du job gates verts au SHA 68ded1c5.
- fix-final rendu passed (87552b91) : C1l.4a sur la clé vivante `vf.terminal.secret` (mutant srcdoc rouge), `ecriture` au contrat §4/§5, docstring du PTY (commentaires seuls).
- Recette par juge (4fa5fe95) : passed, étapes 1 à 6 OK, captures sous le scratchpad recette72/. Étape 7 : F-V1 responsive 768 (section des cartes sous le tiroir, moyen), espacements de la section, contrôles natifs non thémés en sombre, état non armé peu visible → réglages visuels (abcd63ac033cbead4). Pastille et texte ambre `vf-q-attention` et halo des cartes « en cours » : classes de la Phase 71, possédées par la 71.5 → hors périmètre. CLAUDE_EFFORT/CLAUDE_PID transmis au claude lancé (filtre d'env de la Phase 71) et F-U1 (barre de question rangée à l'ouverture auto du tiroir, frappes perdues) → BACKLOG (nœud docs). Points de goût listés pour Samuel au rapport.
- Revue lot 3 (4fa5fe95) : passed, 5 mineurs. S-1 (mutant trim survit) et P-1 (P et Q acceptent l'UUID majuscule) → fix-mineurs-c (a21907fd406805acb). S-2 (note hérité dépend de la version) → décision du manager : incise « Claude Code 2.1.257 et plus », relayée au codeur des réglages. S-3 (temporaires non balayés après SIGKILL) : no-op, noté. P-2 (« identifiant affiché » → « quand la case est cochée ») : README déjà juste ; à corriger dans le texte de P72-D-22 par le nœud docs.
- Audit lot 3 / ré-audit F-1 (4fa5fe95) : SECURED, aucune décision humaine nouvelle. P72-D-20 tient (here = dirname de serve.mjs posé une fois par le processus serveur, pas par la page). Low : L1 (lien symbolique sur `.cache` redirige l'écriture) et I2 (BOM toléré) → ajoutés à fix-mineurs-c ; L2 (trois `.focus()` de la vue sans garde hasFocus, code de la Phase 71) → nœud fix-l2 après les réglages visuels ; L3 (README) tenu par 72-15. Mesure : la fenêtre d'activation de P s'ouvre aussi sur un geste dans le cadre de Q (≈ 5 s) — reste dans le résiduel P72-D-22, à écrire. I3 : l'agent /api/ask lit Read(./**), donc le fichier du mode (non sensible) → T-72-128. Paragraphe « Résiduels acceptés » de l'auditeur à recopier dans le rapport d'audit (nœud docs). Recoupement gsd-security-auditor : mêmes conclusions (L1 classé medium chez lui, low ici : le lanceur refuse les liens de la sortie et l'écriture exige déjà T-72-127).
- docs partie 1 rendu passed (1e1eee43) : 72-SECURITY.md, P72-D-22 précisé, T-72-128, 2 entrées BACKLOG, ROADMAP 16/16 plans (case de phase non cochée), LANC-01 à 11 cochées, LANC-12 laissée (Linux non mesuré avant la CI). Reste pour la partie 2 : texte du F4 du lot 1 (revalidation Python = alphabet + préfixe seulement, info, no-op, documenté en T-72-08 par 94bdb6e2), statut final de L1/I2/L2, re-dérivation finale de BRANCHEMENTS-MERGE.
- fix-mineurs-c rendu passed (084e221d, 38eeeb3a) : S-1, P-1, L1 (lstat du dossier support, course lstat/ouverture consignée), I2 (BOM refusé).
- ui-recette rendu passed (b05d3001) : 5 réglages, module neuf vf-cockpit-lancer-style.mjs, feuille du bandeau posée par la vue (<style id=vf-lancer-style>) en attendant la fusion de la 71.5 ; jetons --sp-* absents de cet arbre → var(--sp-8, 8px) avec repli, à retirer à la fusion de la 71.5. Note hérité avec l'incise « Claude Code 2.1.257 et plus ».
- fix-l2 rendu passed (a5dc9180, 9dd54e92) : gardes hasFocus sur la carte et le bandeau ; collage non gardé (atteint par geste paste/drop dans Q seulement). Déviation hors liste acceptée par le manager : T20.6 de test-cockpit-terminal-tiroir.sh (Phase 71) attendait le focus pris par la carte dans un cadre sans focus, comportement supprimé par L2 ; le scénario donne d'abord le focus au cadre, assertions inchangées (relu : 2 lignes de mise en place, aucune assertion retirée). 72-SECURITY : aucun finding ouvert. BRANCHEMENTS re-dérivé (15 M, 30 A).
- Non-régression complète lancée au SHA 9dd54e92 : 181 suites découvertes par ci-shard-suites.sh --all, séquentielles, borne 1200 s par suite, puis job gates rejoué par replay-ci-jobs.sh.

## Preuves E6

Relayées verbatim des blocs typés des workers (SHA au rejeu ; commandes depuis la racine du worktree).

```json
[
  {"verdict": "suite", "commande": "bash plugin/cockpit/scripts/tests/test-cockpit-lancer-pty.sh pty", "exit_code": 0, "sha": "9ac5e282"},
  {"verdict": "suite", "commande": "bash plugin/cockpit/scripts/tests/test-cockpit-terminal-session.sh", "exit_code": 0, "sha": "9ac5e282"},
  {"verdict": "suite-72-09", "commande": "bash plugin/cockpit/scripts/tests/test-cockpit-lancer-serveur.sh", "exit_code": 0, "sha": "6fde1538905f8b753f2f24cc86a599a9db9849c3"},
  {"verdict": "suite du processus de Q", "commande": "bash plugin/cockpit/scripts/tests/test-cockpit-lancer-processus.sh", "exit_code": 0, "sha": "549d3bcc"},
  {"verdict": "suite tiroir", "commande": "bash plugin/cockpit/scripts/tests/test-cockpit-terminal-tiroir.sh", "exit_code": 0, "sha": "f9607584 + arbre à 11ba668f"},
  {"verdict": "recette", "commande": "bash plugin/cockpit/scripts/tests/test-cockpit-lancer-bout-en-bout.sh", "exit_code": 0, "sha": "84501819f472a58d54350be109d8b57ab10b1224"},
  {"verdict": "revue", "commande": "bash plugin/cockpit/scripts/tests/test-cockpit-lancer-{gabarit,cibles,post,q,suivi,pty,processus,serveur,ui,bandeau}.sh (extraction git archive 84501819)", "exit_code": 0, "sha": "84501819f472a58d54350be109d8b57ab10b1224"},
  {"verdict": "audit", "commande": "bash plugin/cockpit/scripts/tests/test-cockpit-lancer-processus.sh (extraction 84501819)", "exit_code": 0, "sha": "84501819f472a58d54350be109d8b57ab10b1224"},
  {"verdict": "revue", "commande": "bash plugin/cockpit/scripts/tests/test-cockpit-lancer-bout-en-bout.sh (extraction de b5efcc40)", "exit_code": 1, "sha": "b5efcc40c9983ee0332937c69ee6fe2ae6d01e4a"},
  {"verdict": "correctif F-3", "commande": "bash plugin/cockpit/scripts/tests/test-cockpit-lancer-bout-en-bout.sh (export b5efcc40 + correctif)", "exit_code": 0, "sha": "acb032e1"},
  {"verdict": "revue", "commande": "bash plugin/cockpit/scripts/tests/test-cockpit-lancer-mode.sh (extraction git archive 4fa5fe95)", "exit_code": 0, "sha": "4fa5fe958fa085b4141ce04fb150fc3d351dad34"},
  {"verdict": "audit", "commande": "bash plugin/cockpit/scripts/tests/test-cockpit-lancer-mode.sh", "exit_code": 0, "sha": "4fa5fe95"},
  {"verdict": "gates", "commande": "bash scripts/check-version-sync.sh", "exit_code": 0, "sha": "68ded1c5"},
  {"verdict": "suite", "commande": "bash plugin/cockpit/scripts/tests/test-cockpit-lancer-xss.sh", "exit_code": 0, "sha": "87552b91"},
  {"verdict": "suite", "commande": "bash plugin/cockpit/scripts/tests/test-cockpit-lancer-mode.sh (export 38eeeb3a)", "exit_code": 0, "sha": "38eeeb3a"},
  {"verdict": "suite", "commande": "bash plugin/cockpit/scripts/tests/test-cockpit-lancer-bandeau.sh", "exit_code": 0, "sha": "a5dc9180"},
  {"verdict": "suite", "commande": "bash plugin/cockpit/scripts/tests/test-cockpit-terminal-tiroir.sh", "exit_code": 0, "sha": "a5dc9180"},
  {"verdict": "gate", "commande": "bash scripts/check-machine-paths.sh", "exit_code": 0, "sha": "9dd54e92"}
]
```
