---
name: project-phase44-recalc-planning-findings
description: Audit Phase 44 (recalc-planning.sh) tour 3 -- repli code-1 (lot 3) rouvert par 3 divergences I/O bash-vs-Python (symlink signal, UTF-8 strict), dedup token collision (sous-journalisation), ouvert au 2026-09-28
metadata:
  type: project
---

Audit `audit-44` tour 3 (mandat vf-dev-manager-g44, re-audit ciblé lot 3) sur
`plugin/planning-core/scripts/recalc-planning.sh` (HEAD `ca185e4`). Verdict OPEN_THREATS,
statut `gaps_found`. Prolonge les findings A/B du tour
initial, toujours ouverts, non redecrits ici) et de [[project-symlink-escape-gsd-scripts]].

- **Tour 2 -> tour 3, ce qui est VRAIMENT ferme** : le contournement "GSD_HOME inexistant" du
  tour 2 est ferme UNIQUEMENT pour le cas fichier REGULIER -- verifie en execution reelle (lab
  jetable, GSD_HOME pointe vers un chemin absent, package.json fichier normal + STATE.md
  `planning_version` valide) : refus exit 3, rien ecrit. Le lot 3 (commit `dab3f62`, fonctions
  `_a_signal_de_code`/`_porte_planning_version`, recalc-planning.sh ~L302-407) reproduit en Python
  pur la combinaison "socle + signal de code" independamment de l'environnement -- mais c'est une
  REIMPLEMENTATION, pas un appel au detecteur bash reel, et elle diverge de lui sur la SEMANTIQUE
  d'E/S, pas seulement sur la liste de noms de fichiers.

- **Finding C (HIGH, ask-user)** -- trois divergences I/O verifiees en execution reelle, memes
  causes profondes, meme classe de contournement (`recalc-planning.sh` : `_a_signal_de_code`
  ~L318-334, `_porte_planning_version`/`_lire_frontmatter_fichier` ~L232-243) :
  1. **Symlink sur un fichier signal** (`package.json` etc.) : bash `[ -f "./$f" ]`
     (`detect-gsd-engine.sh:177`) SUIT les liens ; Python `est_fichier_regulier` (lstat, jamais de
     suivi) non. Lab avec `package.json` -> lien vers un fichier regulier EXTERNE au lab +
     `STATE.md` `planning_version` valide + `GSD_HOME` inexistant : le moteur ECRIT
     (`.recalc-cache.json`, `INDEX.md`, `STATE.md`, exit 0) alors que le meme disque avec `GSD_HOME`
     EXISTANT (chaine presente) fait dire au detecteur reel "migration a examiner" (exit 2).
     **L'ecriture DETRUIT le marqueur `planning_version` lui-meme** (le STATE.md regenere ne porte
     plus que `genere_par: recalc-planning`, etc.) -- l'ecriture efface la preuve qui aurait du la
     bloquer.
  2. **Symlink sur un dossier `*.xcodeproj`** : bash `[ -d "$f" ]` (glob `./*.xcodeproj`) SUIT les
     liens ; Python `entree.is_dir(follow_symlinks=False)` (~L330) explicitement non. Meme
     exploit, meme resultat (exit 0 au lieu du refus) -- verifie separement en execution reelle.
  3. **`STATE.md` avec des octets UTF-8 invalides APRES la fermeture du frontmatter** :
     `_lire_frontmatter_fichier` decode tout le fichier en UTF-8 strict et echoue entierement des
     qu'un octet invalide existe n'importe ou dans le fichier -> `_porte_planning_version` rend
     False comme si le marqueur etait absent. Le detecteur bash reel (awk, ligne par ligne,
     s'arrete a la fermeture `---`) trouve le marqueur meme avec du binaire apres. Verifie en
     execution reelle : meme resultat (ecriture au lieu du refus).
  Les trois partagent la meme cause : le repli Python du lot 3 reimplemente la LISTE de signaux du
  detecteur bash mais pas sa SEMANTIQUE d'E/S (suivi de lien, tolerance aux octets invalides hors
  frontmatter). Precondition realiste, pas seulement adverse : un `STATE.md` avec `planning_version`
  (sans `gsd_state_version`) est PRECISEMENT le socle planning-core pre-migration que la priorite 3
  existe pour proteger -- un `package.json` symlinke est un motif courant de monorepo, pas
  necessairement une attaque. `ask-user` car la remediation touche la meme frontiere que Finding A
  (P44-D-09/D-14 : jusqu'ou le repli doit-il fideliser le comportement du script bash source plutot
  que sourcer/appeler le script lui-meme -- choix deja pose en P44-D-01b/D-01d).

- **Finding D (MEDIUM, auto-fix)** -- `_jeton_journal` (~L1247-1257) n'est PAS injective : elle
  collabore les runs d'espaces et `=` en un seul `_`. Verifie par calcul direct :
  `jeton("3 4") == jeton("3_4") == "3_4"`. Consequence dans `lignes_a_journaliser` (~L1210-1241,
  fixee lot 3 pour comparer assaini-vs-assaini, commit `dab3f62`) : deux valeurs BRUTES distinctes
  du champ `tentative` (lu tel quel depuis VERDICT.md, non valide -- P44-D-09) qui normalisent vers
  le meme jeton sont vues comme un DOUBLON -> une cloture reellement nouvelle peut ne PAS etre
  journalisee dans `cloture.log` si son `tentative` assaini collide avec le dernier jeton deja
  ecrit. Gap de tracabilite, pas de bypass d'ecriture. Remediation suggeree : encodage injectif
  (echappement caractere-par-caractere ou repr()/JSON) au lieu d'un remplacement qui collabore.

- **Non confirme en execution, a verifier si pertinent** : aucune autre divergence trouvee sur
  cwd, sous-dossiers pour signal de code (bash et Python cherchent tous deux SEULEMENT a la racine
  -- symetrique), ni sur `CLAUDE_CONFIG_DIR`/autres variables d'env (le repli ne depend d'AUCUNE
  variable d'env par design, seulement du disque -- coherent). Pas de lecture hors racine_lab, pas
  de suivi de lien supplementaire, pas de lecture de fichier enorme constatee dans le repli lui-meme
  (RAS sur ce point du mandat).

- Delegation `gsd-security-auditor` (tour 3) : verdict SECURED sur les 3 zones demandees
  (9 menaces T-44-02/03/04/05/06/15/17/18/21 toutes COUVERTES) -- mais methodologie DECLARATIVE
  (le code existe et correspond au motif attendu), jamais testee sur des entrees adverses. Preuve
  que le recoupement apporte une valeur reelle : T-44-02 (refus migration tient quel que soit
  GSD_HOME) marque COUVERT par le delegue sur la seule base du texte du code, alors que mes 3
  essais en execution reelle (Finding C) le contredisent concretement pour le sous-cas
  symlink/UTF-8. Meme lecon que le tour 1 (cf. [[feedback-execute-dont-trust-green]]) : un audit
  declaratif ne remplace jamais l'execution adverse.

Etat au 2026-09-28 (tour 3) : Finding A/B (tour 1) toujours ouverts et non retraites. Finding C/D
neufs, transmis a vf-dev-manager. A verifier lors d'un futur audit si les trois sous-cas de C et le
D ont ete corriges avant de les re-signaler comme neufs -- verifier chaque sous-cas SEPAREMENT
(memes labs jetables : symlink fichier, symlink dossier, UTF-8 invalide en queue de STATE.md), pas
seulement le cas nominal deja ferme au tour 2.
