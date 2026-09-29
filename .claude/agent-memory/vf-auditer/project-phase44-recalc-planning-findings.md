---
name: project-phase44-recalc-planning-findings
description: Audit Phase 44 (recalc-planning.sh) tour 7 final -- CLOS (HEAD 345303e, verdict SECURED) : lot 7 ferme la menace PERM du tour 6 (garde de lecture du detecteur, fidelite par execution + lisibilite reelle), 303 OK suite de regression, aucun vecteur CLONE trouve ; deux findings LOCAL residuels documentes (TOCTOU garde/detecteur mesure a 1 sur 15, FIFO sur STATE.md bloquant sans O_NONBLOCK), action no-op par doctrine du mandat
metadata:
  type: project
---

Audit `audit-44` tour 4 (mandat vf-dev-manager, mission mgr-44-reprise, mode autonome) sur
`plugin/planning-core/scripts/recalc-planning.sh` HEAD `885d9b3`. Verdict SECURED, statut
`gaps_found` (findings LOW residuels, aucune menace vivante). Referme l'etat OUVERT du tour 3
de ce meme fichier de memoire.

- **A (forgerie tentative: dans cloture.log, tour 1) FERME** -- verifie par execution : 5
  variantes rejouees en labs jetables reels (spaceeq "x y cle=INJECTED", U+2028, U+0085, CR,
  NUL). Les 3 premieres + spaceeq produisent une ligne UNIQUE, `=`/espace correctement
  pourcent-encodes (`_jeton_journal`, lot 4, injectif). Le CR ne survit meme pas jusqu'au
  jeton : la lecture UTF-8 texte de `_lire_frontmatter_fichier` traduit tout CR isole en
  `\n` (universal newlines Python), ce qui invalide le frontmatter en amont
  (`ligne-non-reconnue`) -- fail-closed par une CAUSE DIFFERENTE mais tout aussi fermante.
  Seul residu : le NUL (`\x00`) n'est PAS couvert par `str.isspace()` et traverse tel quel
  dans le jeton (verifie : ligne cloture.log contient `x^@y` litteral) -- mais NUL ne
  reproduit AUCUN des 3 separateurs structurels du format (`\n`, `"  "` litteral, `=`), donc
  AUCUNE forgerie de ligne/champ n'est possible avec ce residu (confirme independamment par
  gsd-security-auditor). Finding residuel LOW / auto-fix : NUL octet brut ecrit dans un
  journal append-only, integrite pas exploitabilite.

- **B (garde emplacement occupe, os.path.isfile -> lien suivi, tour 1) FERME** -- verifie
  par execution sur les 4 cibles (INDEX.md, STATE.md, cloture.log, .recalc-cache.json) en
  lien vers un fichier regulier EXTERNE au lab : refus exit 1, message "emplacement
  occupe...", fichier victime hors du lab jamais touche (contenu verifie identique
  avant/apres). `cloture.log` catche via `lire_journal`/ELOOP (O_NOFOLLOW a l'ouverture),
  les 3 autres via `est_fichier_regulier` (lstat) dans la boucle d'`appliquer_ecritures`.

- **C (3 divergences symlink/UTF-8 detecteur, tour 3) FERME PAR CORRECTION DE CLASSE (lot
  4)** -- la reimplementation Python du detecteur GSD a ete SUPPRIMEE ; `detection_gsd()`
  appelle desormais le VRAI `detect-gsd-engine.sh` en sous-processus, environnement copie
  de `os.environ` avec SEULE surcharge `GSD_HOME` = dossier du detecteur (toujours
  existant). Verifie par execution reelle sur les 3 labs adverses originaux (package.json
  symlink -> fichier regulier externe, *.xcodeproj symlink -> dossier externe, STATE.md
  avec octets UTF-8 invalides apres le frontmatter) + socle `planning_version` : les 3
  refusent desormais exit 3 (P44-D-02a), ZERO fichier ecrit dans .planning/. Suite de
  regression du depot (`test-recalc-planning.sh`, 233/233 OK) couvre les 3 memes labels +
  matrice d'env -- tous verts, corrobore l'execution independante.

- **D (collision de jeton "3 4"/"3_4", tour 3) FERME** -- `_jeton_journal` (lot 4)
  remplace l'assainissement par `_` (non injectif) par un echappement pourcent injectif.
  Verifie par execution reelle en DEUX passages sur le meme lab : run 1 avec
  `tentative: "3 4"` -> ligne `tentative=3%204` ; VERDICT.md reecrit avec
  `tentative: "3_4"` -> DEUXIEME ligne distincte `tentative=3_4` ajoutee
  (`cloture_ajouts=1`, pas absorbee par le dedoublonnage).

- **T2 (GSD_HOME absent/mal cible -> code 1 -> ecriture, tour 2) FERME** -- `GSD_HOME` est
  desormais TOUJOURS surcharge explicitement vers le dossier du detecteur lui-meme, qui
  existe forcement des lors que le detecteur a deja ete verifie regulier. Verifie : tous
  mes runs tournaient avec `GSD_HOME` ambiant VIDE sans aucun code-1 errone. Suite de
  regression verte sur `R-GSD-HOME-SIGNAL (b) GSD_HOME inexistant`.

- **Nouvelle surface lot 4 (env_maitrise = dict(os.environ), seule GSD_HOME surchargee) --
  verifiee saine sur le point demande, DEUX findings residuels LOW trouves** :
  - `GSD_WORKSTREAM`/`VF_WORKSTREAM` herites : AUCUN effet sur le verdict. Confirme par
    lecture (grep) : `detect-gsd-engine.sh` n'appelle QUE `vf_ws_enumerate`, jamais
    `vf_ws_resolve` (seule fonction qui lirait ces variables) ; `vf_ws_enumerate` n'enumere
    que le DISQUE, aucune dependance a une variable d'environnement. Verifie aussi par
    execution : `GSD_WORKSTREAM=malicious-nonexistent-ws` sur un lab deja refusant -- meme
    refus, aucun changement de verdict.
  - **Finding LOW/auto-fix -- `ecrire_si_different` (~L1327-1330) lit l'existant via
    `open()` NU, sans O_NOFOLLOW**, seul site parmi 7. TOCTOU reel entre le `lstat` de
    garde et cet `open()`. Impact borne : ce contenu ne sert qu'a une comparaison
    d'octets (jamais expose/journalise), et l'ECRITURE qui suit passe par `os.replace`
    (jamais de suivi de lien a la destination) -- donc pas d'evasion de `.planning/` ni de
    fuite. Contredit litteralement l'invariant declare par le commentaire de
    `est_fichier_regulier` ("jamais le seul rempart"). Trouve par delegation
    gsd-security-auditor (lecture ligne par ligne), confirme par ma propre lecture.
  - **Finding LOW/auto-fix -- `BASH_ENV`/`ENV` herites tels quels dans `env_maitrise`**,
    jamais filtres avant le `subprocess.run`. PAS une nouvelle surface introduite par lot
    4 : verifie empiriquement (lab jetable, `BASH_ENV` exporte pointant un payload,
    wrapper `bash recalc-planning.sh` invoque) que le payload s'execute des le TOUT
    PREMIER appel bash (le wrapper shell lui-meme, avant meme que Python ou le
    sous-processus du detecteur ne tournent) -- l'outil est deja entierement compromis a
    l'invocation si BASH_ENV est positionne cote appelant, independamment de
    env_maitrise. Categorie "ce que l'appelant peut faire a lui-meme", PAS une elevation
    via CONTENU DE LAB. Reste un ecart de coherence avec le docstring "environnement
    MAITRISE" -- moindre privilege suggere, pas une menace vivante.
  - Injection via `--path` (dossier commencant par `-`, avec espace) : verifiee saine par
    execution (subprocess liste-based, jamais de shell ; chemin toujours absolu).
  - Fail-closed (detecteur absent, symlink, dossier, timeout 30s) : verifie par execution
    reelle, 4 sous-cas separes, ZERO octet ecrit dans chaque lab.

- **Delegation gsd-security-auditor (tour 4)** : mandat cible sur 4 points precis avec
  citation ligne par ligne exigee (pas un verdict declaratif global). A trouve les 2
  findings LOW ci-dessus que mon execution initiale n'avait pas couverts, et a confirme
  independamment A et GSD_WORKSTREAM. Nettement plus utile que les tours 1/3 (verdict
  SECURED global sur simple pattern-matching) -- cadrer la delegation sur des questions
  precises avec exigence de citation produit un vrai recoupement, cf.
  [[feedback-execute-dont-trust-green]].

Etat au 2026-09-28 (tour 4, HEAD 885d9b3) : A/B/C/D/T2 tous FERMES, verifies par execution
reelle + corrobores par la suite de regression du depot (233/233 OK) + par
gsd-security-auditor sur les points cibles. 3 findings LOW residuels ouverts, action
auto-fix, aucun ne constitue une menace vivante (NUL non-forgeant dans le journal, TOCTOU
de lecture sans impact d'evasion/fuite, BASH_ENV deja "game over" au niveau de l'appelant
independamment de env_maitrise). Si un tour 5 est necessaire, verifier que ces 3 items ont
ete corriges avant de les re-signaler comme neufs.

---

## Tour 5 (2026-09-28, HEAD 0be13a9, mission mgr-44-reprise, apres correction lot 5)

Verdict global OPEN_THREATS (statut gaps_found) : le lot 5 (F44-05/06/07, F1, environnement du
detecteur reconstruit de zero) est verifie FERME par execution reelle, mais une menace VIVANTE a
ete decouverte HORS du diff du lot 5, dans une couche voisine que `recalc-planning.sh` appelle
transitivement -- confirmee INDEPENDAMMENT par gsd-security-auditor (labo jetable separe, sans se
fier a mon PoC initial).

- **Rejoue et FERME par execution reelle sur HEAD 0be13a9** : A (forgerie tentative:, 5 variantes
  y compris NUL -- desormais echappe en `%00`, F44-05 confirme corrige), B (les 4 cibles gardees
  en lien vers un fichier regulier externe, refus + cible intacte), C (3 divergences symlink/
  UTF-8 tour 3, toutes refusent), D (collision de jeton "3 4"/"3_4", 2 lignes distinctes), T2
  (GSD_HOME ambiant poison sans aucun effet), F44-06 (O_NOFOLLOW sur la lecture d'
  `ecrire_si_different`, plus confirme par la suite du depot : "F44-06 ecrire_si_different sur un
  lien (TOCTOU simule)"), F1 (awk factice en tete de PATH ambiant, fonction exportee
  `BASH_FUNC_awk%%`, `ENV`/`BASH_ENV` ambiants -- tous sans effet sur le verdict du detecteur ;
  `BASH_ENV` execute bien un payload dans le WRAPPER EXTERNE lui-meme avant que Python ne demarre,
  categorie deja close "l'appelant se compromet lui-meme", mais le verdict de SECURITE reste
  correct malgre cette compromission -- confirmation plus forte qu'au tour 4). `_jeton_journal` :
  ValueError sur repli vide confirme INATTEIGNABLE par grep exhaustif (6 sites d'appel, tous
  litteraux non vides "-"/"inconnu") -- jamais un lab a moitie ecrit par ce chemin.
  Suite de regression du depot rejouee en direct : `bash
  plugin/planning-core/scripts/tests/test-recalc-planning.sh` -> **270 OK, 0 KO, exit 0** (HEAD
  0be13a9 ; 233 au tour 4, la hausse vient des tests ajoutes par le lot 5 lui-meme).

- **NOUVELLE MENACE OUVERTE, HORS PERIMETRE DU LOT 5 -- masquage d'un compartiment GSD par un
  saut de ligne (LF) dans son NOM** (severite HIGH, action ask-user, PROPRIETE violee : P44-D-02a
  "ne jamais ecrire sur un planning tenu par GSD"). `vf_ws_enumerate`
  (`plugin/planning-core/scripts/workstream-policy.sh:294-311`) enumere les compartiments de
  `.planning/workstreams/*/` et emet `printf '%s\n' "$(cd "$entry" && pwd)"` PAR COMPARTIMENT --
  sans jamais appeler `vf_ws_name_valid` (alphabet `[A-Za-z0-9._-]`), qui ne governe QUE la
  resolution d'un nom DECLARE (GSD_WORKSTREAM/pointeur), jamais l'enumeration depuis le disque. Un
  nom de compartiment contenant un LF litteral (legal POSIX, seuls `/` et NUL sont interdits) fait
  emettre PLUSIEURS lignes stdout pour UNE seule entree. Le consommateur
  (`plugin/planning-core/scripts/detect-gsd-engine.sh:117-167`, boucle `while IFS= read -r
  _wsdir`) est un lecteur strictement ligne-par-ligne, incapable de reconstituer le chemin reel :
  le marqueur `gsd_state_version` du compartiment hostile devient INVISIBLE, sans le signaler
  (stderr VIDE -- ni "present mais vide apres filtrage" ni aucun autre diagnostic, car
  `vf_ws_enumerate` a reellement rendu 0/succes cote shell). `detect-gsd-engine.sh` retombe alors
  sur la priorite 4 (terrain libre, exit 3) ; `detection_gsd()`
  (`plugin/planning-core/scripts/recalc-planning.sh:414-426`) mappe ce 3 sur `"non-gsd"` ; `main()`
  (memes fichier, lignes ~1587-1591) n'ecrit QUE si `verdict_gsd == "non-gsd"` -- **ecrit donc
  reellement** INDEX.md/STATE.md/.recalc-cache.json a la racine de `.planning/` alors qu'un
  compartiment est VRAIMENT tenu par GSD. Reproduit par MOI (labo jetable, compartiment
  `compartiment-un<LF>marqueur-cache/STATE.md` avec `gsd_state_version: 3`, environnement maitrise
  EXACT de `recalc-planning.sh` : PATH=`/usr/bin:/bin:/usr/sbin:/sbin`, GSD_HOME=dossier du
  detecteur, `--noprofile --norc`) : detecteur seul -> exit 3 ; `recalc-planning.sh
  --planning=.planning` (config.json adherent `cycles-v1`) -> **exit 0, ecrits =
  [INDEX.md, STATE.md, .recalc-cache.json]**. **Confirme INDEPENDAMMENT par gsd-security-auditor**,
  labo separe reconstruit de zero sans se fier a mon PoC, meme resultat, plus une citation
  ligne-par-ligne complete des deux couches (emission + consommation) et un bonus : le meme
  defaut affecte `check-planning-state.sh:136-141` (comptage `awk 'NF>0{c++}'` gonfle par un
  compartiment LF -- impact borne, diagnostic seul, pas de porte d'ecriture, non verifie en
  profondeur). Le bug vit ENTIEREMENT dans le protocole IPC ligne-par-ligne entre
  `vf_ws_enumerate` et ses deux consommateurs (`workstream-policy.sh`, hors du diff du lot 5 --
  fichier NON touche) : le durcissement du lot 5 (liste blanche d'environnement, resolution
  stricte de bash, alphabet etendu de `_jeton_journal`) ne couvre AUCUNE partie de cette chaine.
  Remediation suggeree (pas appliquee, hors mandat lecture seule) : echapper le LF a l'emission
  (`vf_ws_enumerate`) OU delimiter par NUL des deux cotes (`printf '%s\0'` + `read -r -d ''`) --
  decision de portage a trancher par le proprietaire de `workstream-policy.sh` (Phase 41.1), pas
  par ce lot.

- **2 findings LOW additionnels, non bloquants** (trouves par gsd-security-auditor, confirmes non
  exploitables dans le chemin observe) :
  - `_bash_candidat_valide`, cas fichier regulier DIRECT sans verification de proprietaire :
    NON une regression -- `CANDIDATS_BASH` est une paire de chemins absolus FIXES, hors de portee
    du contenu d'un lab (substituer `/bin/bash` exigerait une ecriture root sur `/bin`, hors du
    modele de menace "contenu de lab").
  - `assert jeton, "..."` en fin de `_jeton_journal` (`recalc-planning.sh:1315`) : eliminable sous
    `python -O`/`PYTHONOPTIMIZE` -- mais la garde REELLE (`raise ValueError` sur repli vide, en
    tete de fonction) reste active quel que soit `-O`, et l'invocation observee
    (`PYBIN=python3` sans `-O`, ligne 55) ne declenche pas ce mode. Nit d'hygiene seulement.
  - `--noprofile --norc` (ligne 407, nouveau au lot 5) : NE couvre PAS `BASH_ENV`/`ENV` (ces
    flags ne suppriment que les fichiers de demarrage de shell INTERACTIF/login ; `BASH_ENV` est
    un mecanisme distinct pour un shell NON interactif executant un script, deja et uniquement
    couvert par la liste blanche d'environnement du lot 5). Pas une regression, juste une
    precision -- le commentaire du code ne sur-promet d'ailleurs rien a ce sujet.

Lecon pour un tour 6 eventuel : la question "le detecteur peut-il rendre 3 par erreur depuis le
CONTENU d'un lab" (posee explicitement par le mandat du tour 5) etait la bonne question a poser --
elle a immediatement fait surface une classe de bug entiere restee invisible aux tours 1/3/4, qui
ne testaient que des cas nommes SAINEMENT (symlinks, UTF-8 invalide, mais jamais un NOM DE FICHIER
hostile). Generaliser : chaque fois qu'un protocole IPC texte ligne-par-ligne (`vf_ws_enumerate`
et consorts) transporte un chemin derive d'un NOM DE FICHIER/DOSSIER arbitraire, verifier
explicitement le cas d'un separateur d'enregistrement (LF, mais aussi envisager CR/NUL bien que
NUL soit interdit par POSIX) EMBARQUE DANS LE NOM lui-meme -- pas seulement dans le CONTENU d'un
fichier.

---

## Tour 6 (2026-09-28, HEAD 32b5d59, mission mgr-44-reprise, apres correction lot 6, TOUR FINAL)

Verdict global OPEN_THREATS (statut gaps_found) : le lot 6 (garde `_enumeration_workstreams_fidele`,
`recalc-planning.sh:381-425`) FERME reellement le LF-COMPARTIMENT-MASQUE-GSD du tour 5 pour ses DEUX
classes nommees (nom a saut de ligne, nom cache par un point) -- rejoue par execution directe sur
HEAD, refus code 3 avec message explicite citant P44-D-02a. MAIS la garde ne couvre que le CONTENU
du nom/chemin, jamais les PERMISSIONS du repertoire : une exploration systematique de la classe (nom
tiret initial, nom avec caracteres de glob, segment de lien symbolique intermediaire dans le chemin
du planning, inondation de 3000 decoys + 1 compartiment masque par LF, STATE.md en lien) a fait
surface UNE VARIANTE VIVANTE non couverte -- meme mecanisme de silence que le tour 5, racine
differente.

- **A, B rejoues sur HEAD 32b5d59, FERMES par execution reelle** (methode : lab `traceur` du banc de
  la suite du depot, materialise via `aides.py`/`banc.txt` extraits du harnais reel, jamais
  reimplementes). A (forgerie `tentative:`, 8 variantes : saut de ligne, `cle=INJECTED`, espaces,
  U+2028, U+0085, NUL, CR isole, controles C0) : les 6 premieres produisent chacune EXACTEMENT une
  ligne dans `cloture.log`, tous les separateurs structurels (`%`, `=`, espace/U+2028/U+0085, NUL,
  C0) desormais pourcent-encodes de facon injective (`_jeton_journal`, alphabet etendu
  `not str.isprintable()` -- le residu NUL du tour 4 est CONFIRME CORRIGE, `tentative=x%00y`) ; LF et
  CR isoles ne produisent AUCUNE ligne DU TOUT (`cloture_ajouts=0`, `cloture.log` absent) car le
  frontmatter de VERDICT.md devient invalide en amont -- fail-closed par une cause differente, encore
  plus fermante qu'un simple encodage. B (les 4 cibles gardees -- INDEX.md, STATE.md, cloture.log,
  .recalc-cache.json -- en lien vers un fichier regulier ET vers un chemin hors du lab, y compris un
  lien PENDANT hors du lab) : 8 sous-cas (4 cibles x {regulier-hors-lab, pendant-hors-lab}), refus
  systematique (exit 1), lien jamais suivi, victime externe intacte octet pour octet, aucune cible
  pendante jamais creee.

- **LF-COMPARTIMENT-MASQUE-GSD (tour 5) : PoC exact rejoue sur HEAD -> LF FERME.** Message stderr de
  `recalc-planning.sh` lui-meme (pas seulement du detecteur, desormais visible AVANT tout appel au
  sous-processus) : « refus (P44-D-02a, garde de fidelite d'enumeration, lot 6) ... classes :
  nom-compartiment-saut-de-ligne ». `INDEX.md`/`STATE.md`/`.recalc-cache.json` jamais crees.

- **NOUVELLE VARIANTE VIVANTE, MEME CLASSE -- repertoire de compartiment SANS PERMISSION
  D'EXECUTION (chmod 000 ou chmod 600) masque un compartiment GSD reel** (severite HIGH, action
  ask-user, PROPRIETE violee : P44-D-02a, meme propriete que le tour 5). Mecanisme identique au tour
  5, racine differente : `_enumeration_workstreams_fidele` (lot 6) ne verifie QUE le contenu du nom
  et du chemin (saut de ligne, point initial) -- JAMAIS les bits de permission du repertoire. Dans
  `vf_ws_enumerate` (`workstream-policy.sh:294-311`), l'entree chmod 000/600 passe `vf_ws_path_nolink`
  (0 = existe, non-lien -- lstat n'exige aucune permission) et `[ -d "$entry" ]` (stat n'exige aucune
  permission) : la garde d'exclusion ne se declenche PAS. `cd "$entry" && pwd` a l'interieur de la
  substitution de commande ECHOUE (permission refusee, l'entree du repertoire etant illisible/non
  traversable) -- verifie DIRECTEMENT en source cant `vf_ws_enumerate`
  (`bash -c ". workstream-policy.sh; vf_ws_enumerate <planning>"`) : stdout = UNE LIGNE VIDE (`\n`),
  stderr = `workstream-policy.sh: line 305: cd: <chemin>: Permission denied` (le diagnostic EXISTE a
  ce niveau, mais `found=1` reste positionne malgre l'echec de `cd`, donc rc=0 -- succes cote appelant
  malgre le contenu vide). Le consommateur (`detect-gsd-engine.sh:117-167`, `[ -n "$_wsdir" ] ||
  continue`) saute silencieusement la ligne vide, ne trouve aucun marqueur, retombe sur priorite 3 ->
  exit 3 -> `detection_gsd()` mappe en `"non-gsd"` -> ECRITURE REELLE. Verifie de bout en bout sur le
  PIPELINE COMPLET (`recalc-planning.sh` reel, pas seulement le detecteur isole) : lab avec UN SEUL
  compartiment `gsd_state_version: 1.0` en chmod 000 -> `rc=0`, stderr **completement vide** (le
  diagnostic « Permission denied » vu au niveau du sous-shell de `vf_ws_enumerate` est integralement
  AVALE par le `subprocess.run(..., stderr=PIPE)` de `detection_gsd()`, qui ne relaie JAMAIS le stderr
  du detecteur sur le chemin de succes -- silence total cote operateur, PIRE que le tour 5 qui au
  moins imprimait un message avant lot 6) -- `INDEX.md`/`STATE.md`/`.recalc-cache.json` reellement
  ecrits, `STATE.md` genere porte `etat: aucun` en ecrasement d'un planning tenu par GSD. Rejoue a
  l'identique avec chmod 600 (lisible, non traversable). Remediation suggeree (pas appliquee, hors
  mandat lecture seule) : dans `_enumeration_workstreams_fidele`, ajouter une classe masquante
  `nom-compartiment-illisible` des que `os.access(entree, os.X_OK)` est faux pour une entree deja
  retenue comme dossier reel non-lien -- meme famille de correction que le lot 6, un seul predicat
  supplementaire, sans toucher a `workstream-policy.sh` (P44-D-01b).

- **Variantes de la meme classe testees SAINES (refusent correctement, aucune ecriture)** : nom
  commencant par un tiret (`-compartiment-tiret`, glob shell transparent, aucun souci) ; nom avec
  caracteres de glob litteraux (`*`, `[`, `]` dans le nom d'un repertoire reel -- le glob du DISQUE
  matche les noms litteraux sans reinterpretation) ; segment de lien symbolique INTERMEDIAIRE dans le
  chemin du dossier de planning lui-meme (`.planning` atteint via un repertoire parent en lien --
  resolu de facon transparente par le noyau a chaque appel `lstat`/`stat`, aucune classe masquante) ;
  inondation de 3000 compartiments-leurres plus un compartiment reellement masque par LF (le
  detecteur de fidelite d'enumeration cite toujours la bonne classe malgre le volume, aucune perte
  d'echelle) ; `STATE.md` d'un compartiment en lien vers un fichier REEL du meme compartiment portant
  le marqueur (`[ -f ]` suit le lien, marqueur trouve, refus correct -- PLUS protecteur, pas moins) ;
  `STATE.md` en lien PENDANT (cible inexistante -- `[ -f ]` echoue, traite comme absent : ce n'est PAS
  un masquage d'un marqueur REEL, aucun marqueur n'existe nulle part dans ce cas, comportement
  equivalent a un compartiment sans `STATE.md` du tout, pas une instance de la classe).

- **Non-regression** : suite complete du depot rejouee en DIRECT (`bash
  plugin/planning-core/scripts/tests/test-recalc-planning.sh`, HEAD 32b5d59) -> **285 OK, 0 KO, exit
  0** (270 au tour 5, la hausse vient des 15 assertions R-ENUM-FIDELE-* du lot 6 lui-meme). Rejeux
  standalone additionnels (hors suite, PoC personnels) : C (labs adverses, deja couverts par
  R-LABS-ADVERSES de la suite, 11/11 verts, aucun rouge) ; D (collision de jeton "3 4"/"3_4", 2 passes
  reelles sur le meme chemin de phase -> 2 lignes DISTINCTES `tentative=3%204` puis `tentative=3_4`) ;
  T2 (GSD_HOME ambiant pointant vers un chemin totalement inexistant, planning avec un compartiment
  REELLEMENT marque -> refus code 3 immuable, aucun effet du poison ambiant) ; F1-revue (faux `awk`
  en tete de PATH ambiant + `BASH_ENV` pointant un payload inexistant, meme planning marque -> refus
  code 3 identique, l'environnement maitrise en liste blanche neutralise les deux).

Lecon pour un tour 7 eventuel : la MEME question posee au tour 5 ("le detecteur peut-il rendre 3 par
erreur depuis le CONTENU d'un lab") reste feconde une fois DEPLACEE d'un axe (le NOM porte-t-il un
octet structurant ?) a un axe voisin (le repertoire est-il TRAVERSABLE ?) -- chaque primitive du
protocole IPC ligne-par-ligne (`vf_ws_enumerate`) qui peut echouer PARTIELLEMENT (ici : `cd` peut
echouer alors que `lstat`/`[ -d ]` en amont ont reussi) sans faire echouer la fonction ENGLOBANTE
(`found=1` deja positionne) est un candidat a la meme classe de bug. Generaliser encore : chercher
systematiquement, dans toute fonction shell qui emet des lignes derivees du DISQUE, les ecarts entre
« l'entree existe et son TYPE est correct » (ce que la garde deja posee verifie) et « l'entree est
ENTIEREMENT LISIBLE au moment de l'emission » (ce qu'aucune garde ne verifie ici) -- permissions,
mais aussi (non teste ce tour, a envisager pour un suivant) une entree qui disparait entre le
`scandir`/`glob` et le `cd` (TOCTOU de suppression concurrente).

**Confirme INDEPENDAMMENT par gsd-security-auditor** (labo separe reconstruit de zero, chmod 000 ET
chmod 600, controle negatif 755 refermant correctement) -- verdict OPEN_THREATS, severite qualifiee
"critical" (bypass complet et silencieux de l'unique garde d'ecriture P44-D-02a), citation
supplementaire precise non relevee par moi : `found=1` (workstream-policy.sh:306, INCONDITIONNEL,
jamais subordonne au succes du `cd` qui le precede) est la ligne exacte qui transforme l'echec de
`cd` en succes cote appelant -- et `detection_gsd` (recalc-planning.sh:519-523) ne LIT ni ne
REIMPRIME jamais `resultat.stderr` du sous-processus sur le chemin de succes, ce qui explique le
silence total observe cote `recalc-planning.sh` malgre le diagnostic "Permission denied" reellement
emis par le sous-shell de `vf_ws_enumerate`.

---

## Tour 7 (2026-09-28, HEAD 345303e, mission mgr-44-reprise, apres correction lot 7, TOUR FINAL CIBLE, CLOS)

Verdict global SECURED (statut passed) : le lot 7 (_lecture_detecteur_fidele, recalc-planning.sh:444-531) FERME reellement la menace HIGH du tour 6 (compartiment chmod 000/600, found=1 inconditionnel de vf_ws_enumerate) -- verifie par execution directe sur les DEUX variantes (000 et 600) plus un controle negatif 755, et un chmod 000 sur STATE.md racine. Principe du lot 7 : fidelite PAR EXECUTION (relance reelle de vf_ws_enumerate, comparee a l ensemble reel du disque via os.scandir) + lisibilite REELLE (os.scandir/os.open, jamais os.access) de chaque compartiment et STATE.md retenu -- toute OSError ou tout ecart d ensemble refuse AVANT d appeler le detecteur reel.- A, B, LF, D, T2, F1-revue (awk seul, BASH_ENV non rejouable ce tour par garde d isolation du poste) tous rejoues et FERMES sur HEAD 345303e. C corrobore par suite complete rejouee en direct : 303 OK / 0 KO (285 au tour 6, +18 assertions du lot 7).- PERM (menace du tour 6) FERME : chmod 000 -> classes compartiment-illisible + enumeration-non-fidele (os.scandir echoue) ; chmod 600 -> classe enumeration-non-fidele SEULE (os.scandir reussit sur ce poste avec 600, mais le cd bash echoue -- demontre que les DEUX volets de la garde sont complementaires, pas redondants) ; STATE.md racine chmod 000 -> classe state-racine-illisible, marqueur intact.- Chasse finale (clone-only, mandat explicite) : espace dans nom, Unicode NFD (octets preserves identiques cote python et bash sur ce systeme de fichiers), profondeur 40 niveaux, STATE.md compartiment lien pendant, STATE.md compartiment = DOSSIER (ecrit mais PAS un bypass -- aucun marqueur reel ne peut exister dans un dossier, les deux couches convergent), 3000 compartiments-leurres + 1 reellement marque -- TOUS surs. AUCUN vecteur CLONE trouve.- Finding LOW/no-op decouvert par la chasse volume : vf_ws_enumerate SEULE (mesuree isolement, hors moteur) prend ~98s sur 3000 compartiments reels, au-dela du timeout=30 utilise par _executer_vf_ws_enumerate ET par l appel detecteur reel -- refuse par timeout (enumeration-execution-en-echec), TOUJOURS fail-closed, jamais un bypass. Preexistant a vf_ws_enumerate (hors perimetre P44-D-01b), le lot 7 double le cout (une invocation de plus avant meme d atteindre le detecteur reel) sans changer la direction fail-closed. Categorie CLONE mais non-bloquant.- TOCTOU garde et detecteur reel (recalc-planning.sh:610-634), CONFIRME EXPLOITABLE, HIGH/LOCAL. La garde (une lecture) et le detecteur reel (relance sa PROPRE vf_ws_enumerate en interne, priorite 2bis) sont deux lectures independantes du disque separees par un intervalle non nul. Racer mv du compartiment marque pendant l execution, 15 essais : 1 sur 15 a produit une ECRITURE malgre marqueur reellement present. Categorie LOCAL par construction, non-bloquant selon la doctrine du tour, mais desormais MESURE (environ 7 pourcent) et non plus hypothetique. A tracer en backlog pour un futur lot.- FIFO sur STATE.md (racine ET compartiment), CONFIRME, blocage indefini, medium-high/LOCAL. La fonction ouvrable fait os.open du chemin en lecture SANS O_NONBLOCK : mkfifo sur STATE.md bloque le process indefiniment (plus de 8s observees, aucune borne, contrairement aux deux timeout=30 deja en place ailleurs). Aucun mode FIFO ne voyage par un clone, categorie LOCAL par construction.- Collision d ensembles (point 1 du code) : CLOSED, readdir POSIX ne peut structurellement pas rendre deux noms identiques dans un meme repertoire, et la comparaison est une egalite de listes triees exactes, pas d ensembles dedupliques, donc tout doublon casse l egalite plutot que de masquer.- STATE.md-dossier : confirme non-bypass, argumentation convergente avec la mienne (un dossier ne peut pas porter de frontmatter, les deux couches -- garde et detecteur reel -- traitent le cas de facon coherente).

Lecon pour un lot 8 eventuel (si le head le decide malgre la doctrine no-op de ce tour) : le TOCTOU garde/detecteur est la CONSEQUENCE DIRECTE du choix architectural du lot 7 lui-meme (deux lectures independantes du disque au lieu d une seule partagee) -- corriger l un sans reintroduire l autre demanderait de faire lire au detecteur reel le meme instantane que la garde (ex. passer l ensemble deja verifie en argument, ou fusionner les deux passages en une seule execution), ce qui toucherait au perimetre P44-D-01b/P44-D-01d (detecteur inchange, non reimplemente). La FIFO merite un correctif simple et local (stat prealable refusant les types speciaux avant tout os.open dans la fonction ouvrable, ou O_NONBLOCK plus verif post-ouverture) qui ne touche a aucun perimetre protege -- bon candidat isole si un lot 8 est ouvert malgre tout.