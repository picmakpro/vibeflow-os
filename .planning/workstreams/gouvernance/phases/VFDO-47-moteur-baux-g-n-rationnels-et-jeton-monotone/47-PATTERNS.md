# Phase 47 : Moteur — baux générationnels et jeton monotone - Pattern Map

**Mapped:** 2026-10-12
**Files analyzed:** 24 (création ou modification)
**Analogs found:** 22 exacts ou role-match / 24 (2 sans analogue complet : la prise `mkdir gen-<n+1>` entière, et l'imputation G2′)
**Racine des chemins :** worktree `agent-a27d54e8a8701d01e`, branche `gouvernance/phase-47-cadrage`. Tous les analogues ci-dessous sont des fichiers **suivis** (`git ls-files` non vide, 15 fichiers vérifiés) ; aucun miroir `.gsd/capabilities` n'est cité.
**Règle de lecture des lignes :** les numéros de ligne sont ceux du HEAD de ce worktree (code de la Phase 46, avant la 46.1). Ils ne servent qu'à retrouver la **fonction** (P47-D-10) : chaque plan cite la fonction et se re-valide contre le code livré par la 46.1 avant exécution.

## File Classification

| Fichier neuf / modifié | Rôle | Flux de données | Analogue le plus proche (fonction) | Qualité |
|---|---|---|---|---|
| Bloc « registre + journal » (clé, `meta`, `prendre`, `plus_haute`, `lire_meta`, journal d'empreintes, `decider_baux`, `reconcilier_fichier`) — copié à l'identique dans hook, `baux.sh`, recalcul | utility (bloc partagé) | file-I/O + CRUD (journal append-only) | `inscrire_surveillance` + `_jeton_journal` (4 copies, R-D1-09) ; `decider_trace` ; `lire_surveillance` ; `empreinte_fichier` ; `driver-lock.sh` `takeover` (idée du mutex par génération + relecture) | role-match (la prise entière n'a pas d'analogue) |
| `plugin/planning-core/scripts/baux.sh` (NEUF) | utility (CLI écrivain) | request-response + file-I/O atomique | `poser-verdict.sh` : `Refus`, `ouvrir_verrou`, `ecrire_atomique`, `poser`, `main` | exact (même squelette bash + Python embarqué) |
| `planning-hook.sh` : `evaluer_bail` | middleware (gate) | request-response | `evaluer_g3` (+ `evaluer_g5`) | exact |
| `planning-hook.sh` : `evaluer_g2p` | middleware (gate) | request-response | `evaluer_g3` (même `unite_de_fichier(…, "CLOTURE.md")`) + `decider_trace` pour l'imputation | role-match |
| `planning-hook.sh` : `effets_baux` + appel dans `main` | service (effet après décision finale) | event-driven (PreToolUse → effet disque) | `inscrire_intentions` (appel `main`, branche « aucun refus ») + `consommer` / `decider` (effet seulement si la décision finale passe) | exact |
| `planning-hook.sh` : `fichier_protege` / `PROTEGES_G6` / `script_protege` / `adhesion_conservee` / `evaluer_g6` (sous-arbre `baux/`, liste de `config.json`, `baux.sh`) | middleware (gate G6) | request-response | `fichier_protege`, `script_protege`, `adhesion_conservee`, `evaluer_g6` eux-mêmes | exact (extension en profondeur : pas d'analogue de profondeur) |
| `planning-hook.sh` : identité de l'appelant (`session_id`) | utility | transform | `evaluer_role` (lecture `agent_id` / `agent_type`) | role-match |
| `planning-hook.sh` : bloc d'armement (`ARMEMENT_BAIL`, `ARMEMENT_G2P`, `ORDRE_ETAPES`, `TABLE_ARMEMENT`, `armement_valide`, `GATES_A_VERDICT`, texte de `evaluer_gates`) | config | n/a | les lignes `ARMEMENT_G4P` (étape 6) et la scission 5a/5b dans `armement_valide` | exact |
| `scripts/recalc-planning.sh` : verrou d'écriture, `main`, `appliquer_ecritures` | service | batch + file-I/O | `poser-verdict.sh` `ouvrir_verrou` ; `inscrire_surveillance` (flock) ; `appliquer_ecritures` lui-même | role-match |
| `scripts/recalc-planning.sh` : `rendre_index` (colonne « Bail en cours »), règle miroir dans `_r1_a_r8`, `signature_unite` | service | transform | `rendre_index`, `_r1_a_r8` (règle R4 « livrables présents »), `signature_unite` | exact |
| `plugin/conductor/scripts/dag.sh` : `load` / `save` + verrou | utility | CRUD file-I/O | `recalc-planning.sh` `ecrire_si_different` + `poser-verdict.sh` `ecrire_atomique` + `ouvrir_verrou` | role-match |
| `scripts/check-gates-alive.sh` | utility (canary) | request-response | entrées `G4P-handback` / `G4P-stop` de `CANARIS`, `GATES`, `lire_armement` | exact |
| `scripts/rejeu-gates.sh` / `scripts/rejeu-reel.sh` | utility (banc de rejeu) | batch | `ORDRE_ETAPES` / `ETAPE_DE` / `armer_copie` / `ETAPE_G4P`, bornes `--etape` | exact |
| `scripts/deroger-gate.sh` (`GATES`, usage, message) | utility (CLI) | request-response | tuple `GATES` + message `--gate` de `valider` | exact |
| `references/modele-cycles.md` | doc | n/a | sections `### G3`, `### G4′`, `### D1`, `### Table d'armement livrée`, `## Hors de cette phase` | exact |
| spec moteur (§5, §5.1-2, §6.1, §6.2, §6.4) | doc | n/a | annotations « Amendé le … » déjà posées dans la spec (voir Shared Patterns) | role-match |
| `scripts/tests/test-baux-registre.sh` (NEUF) | test | concurrence + mutation | `test-driver-lock.sh` T13/T32 (tempête 24 × 5), `test-cloture-empreintes.sh` (ast-identité R-EMP-04, `executer_mutant`), `test-planning-gates.sh` R-VERDICT-08 (délai injecté) | exact (par composition) |
| `scripts/tests/test-bail-gate.sh` (NEUF) + `fixtures/bail-banc.txt` | test | request-response (banc) + mutation | `test-cloture-gates.sh` + `fixtures/cloture-banc.txt` ; `test-planning-gates.sh` `Ctx` / `classer` / `make_hook_mutant` | exact |
| `scripts/tests/test-g2prime.sh` (NEUF) | test | request-response + mutation | `test-d1-surveillance.sh` (`tuer`, `rendre`, `copie_forcee`, sections) | exact |
| `plugin/conductor/scripts/tests/test-dag.sh` (T50–T52) | test | concurrence + mutation | `test-driver-lock.sh` T13, T32, T41b (seam `VF_DRIVER_TEST_DIE_AFTER_MUTEX`) | role-match |
| `scripts/tests/test-recalc-planning.sh` (cas de deux recalculs concurrents) | test | concurrence | `test-planning-gates.sh` R-VERDICT-08 (`copie_modifiee` + deux `Popen`) | role-match |
| Suites « découplées » à étendre (expressions `ARMEMENT_(?:…)`, `TABLE_ATTENDUE`, `ORDRE_ATTENDU`) | test | n/a | les mêmes lignes pour `G4P` | exact |
| `VERSION` / `module.json` / `CHANGELOG.md` / `README.md` du module, `conductor` idem | config | n/a | entrée `## [v2.10.0]` de `plugin/planning-core/CHANGELOG.md` | exact |
| `.planning/BACKLOG.md` (clore `dag.sh`, fiches `onFailure` et `driver-lock.sh`) | doc | n/a | fiche `## \`save()\` de \`dag.sh\` … — DIFFÉRÉ` (l.169) | exact |

---

## Pattern Assignments

### Bloc « registre + journal » (utility, file-I/O) — NEUF, une seule implémentation copiée dans trois scripts

**Analogue principal (structure de la copie à comparer) :** `inscrire_surveillance` + `_jeton_journal` de `plugin/planning-core/scripts/planning-hook.sh` (l.1219-1305). Les mêmes fonctions existent à l'identique dans `recalc-planning.sh` (l.1911, l.1964), `poser-verdict.sh` (l.697, l.750) et `deroger-gate.sh`, comparées par `controle_d1_09` de `test-d1-surveillance.sh` (R-D1-09) et `controle_emp_04` de `test-cloture-empreintes.sh` (R-EMP-04).

**Règle de copie :** le bloc ne lit **aucune variable d'environnement** (R-ENV-02 interdit toute lecture d'environnement par le cœur du hook). `CLAUDE_CODE_SESSION_ID` n'est lue que par `baux.sh`, **hors du bloc**.

**Encodeur de valeurs de journal et de `meta` (à réutiliser tel quel, ne pas réécrire) :** `_jeton_journal` (l.1219-1266) — échappe `%`, `=`, espaces, non imprimables ; **ne protège pas `/`**, donc **ne jamais l'employer pour un nom de dossier** (clé = sha256, cf. ci-dessous).
```python
brute = valeur if valeur not in (None, "") else repli
...
if caractere == "%" or caractere == "=" or caractere.isspace() or not caractere.isprintable():
    for octet in caractere.encode("utf-8"):
        morceaux.append("%{:02X}".format(octet))
```

**Ajout de ligne au journal, fail-open, sous flock (patron pour `empreintes.log`, mais ici le fail-closed en `armed` est porté par l'appelant) — `inscrire_surveillance` (l.1272-1305) :**
```python
if os.path.islink(planning) or (os.path.lexists(chemin) and not stat.S_ISREG(os.lstat(chemin).st_mode)):
    return
ligne = "{}  genre={}  chemin={}  sha256={}  par={}  source={}\n".format(
    _temps.strftime("%Y-%m-%dT%H:%M:%SZ", _temps.gmtime()), _jeton_journal(genre, "-"), ...)
descripteur = os.open(chemin, os.O_WRONLY | os.O_APPEND | os.O_CREAT | getattr(os, "O_NOFOLLOW", 0) | getattr(os, "O_NONBLOCK", 0), 0o600)
try:
    if not stat.S_ISREG(os.fstat(descripteur).st_mode):
        return
    if hasattr(os, "fchmod"):
        os.fchmod(descripteur, 0o600)
    if _verrou is not None:
        _verrou.flock(descripteur, _verrou.LOCK_EX)
```
Grammaire du journal à reprendre (`LIGNE_SURVEILLANCE_RE`, l.2820) : champs séparés par **deux espaces**, `clé=valeur`, horodatage ISO en tête. Pour `empreintes.log` : `<ISO UTC>  genre=<g>  gen=<n|->  sha256=<hex|absent|->  par=<identité>  unite=<chemin|->` (RESEARCH R-1).

**Lecture bornée du journal :** copier `lire_surveillance` (l.2934-2958 : lecture des `BORNE_LECTURE_SURVEILLANCE` derniers octets, ligne coupée écartée, `urllib.parse.unquote` au décodage, lien jamais suivi). Pour le journal d'empreintes, la borne est `BORNE_LECTURE_FICHIER` (1 Mio, A11) ; une ligne `ouverture` hors fenêtre = référence absente (RESEARCH R-1, cas 9).

**Règle d'explication — fonction PURE à copier-adapter : `decider_trace` (l.2970-2987) :**
```python
derniere = None
for rang, entree in enumerate(entrees):
    if entree["genre"] == "reference":
        derniere = rang
if derniere is None:
    return ["reference"]
if entrees[derniere]["sha"] == sha:
    return []
apres = entrees[derniere + 1:]  # d1-apres
expliquee = any((e["genre"] == "moteur" and e["sha"] == sha) or e["genre"] == "intention" for e in apres)  # d1-explique
return ["reference"] if expliquee else ["contournement", "reference"]  # d1-contournement
```
`decider_baux` = la même fonction **sans** le genre `moteur` (l'outil écrivain pose directement un `reference`). Poser ses marqueurs de commentaire uniques (`# baux-…`) pour que chaque mutant ne vise qu'une ligne. Appeler `tracer_changement` (l.2990-2996) comme patron de « appliquer les genres rendus par la fonction pure, dans l'ordre ».

**Empreinte d'un fichier déclaré : réutiliser `empreinte_fichier` (l.2902-2931)** (`lstat`, non-régulier = `absent`, `O_NOFOLLOW`, borne d'octets lus). Ne pas ré-écrire un hachage. Ajouter le budget d'octets total par invocation (Pitfall 7, ordre de grandeur 64 Mio `[ASSUMED]`) pour rester dans `ECHEANCE_COEUR_S = 8.0`.

**Lecture d'un fichier du lab : `lire_octets_bornes` (l.501-518)** (rend `("absent"|"illisible"|"hors-borne"|"ok", octets)`) ; toute lecture neuve est inscrite dans `RECENSEMENT_LECTURE`, toute énumération `os.listdir` (ex. `plus_haute`) dans `RECENSEMENT_READDIR` de `test-planning-gates.sh` (l.884, l.959) **dans le même commit**, avec la décision `"neutre"` (noms `gen-<n>` ASCII) — sinon `R-READDIR-RECENSEMENT` / `R-LECTURE-RECENSEMENT` rougissent.

**Chemin en forme NFC : `composants_nfc` (l.471-480)** — toute comparaison de chemins (déclaré vs écrit) passe par là ; la clé est `sha256(NFC(chemin déclaré)).hexdigest()` (RESEARCH R-3).

**Validation des entrées déclarées : `entree_ecrit_valide` (l.734-750)** (copie à 4 exemplaires, ne pas la dupliquer ; ajouter les bornes de composant ≤ 255 octets, ≤ 64 entrées, doublons NFC+casefold dans une fonction voisine).

**Prise (`mkdir gen-<n+1>` + relecture) — pas d'analogue exact.** Analogue d'idée : `plugin/conductor/scripts/driver-lock.sh` `takeover` (l.550-590) : mutex nommé d'après la génération observée, **revalidation après acquisition** (« la génération ne suffit pas … est RELU ici ») et trap de libération ; et `ln_atomic` (l.169-172) dont le commentaire documente le piège uutils (`ln -sh`). **Ne pas reprendre** : identité de génération `epoch.pid` non entière, effacement des anciennes générations (`rm -rf` l.586), `ln -sh` en premier. Utiliser le squelette validé par prototype de RESEARCH (« Code Examples » → `prendre`) : `os.mkdir(rep, 0o700)` exclusif (jamais `makedirs(exist_ok=True)`, mutant rouge `FAUX_SUCCES=20`), `meta` publié par `os.link` (repli `O_EXCL`) — jamais `os.replace` (écrase le `meta` d'un autre), puis relecture du disque.

---

### `plugin/planning-core/scripts/baux.sh` (NEUF) — utility, CLI écrivain, request-response + file-I/O atomique

**Analogue :** `plugin/planning-core/scripts/poser-verdict.sh` (squelette entier : bash + `python3 -I -S - "$@" <<'PY_…_EOF'`). Marqueur de heredoc proposé `PY_BAUX_EOF` (sert à `corps_python(texte, marqueur)` des suites).

**Entête shell et choix de l'interpréteur (l.74-88) — copier tel quel, adapter le nom :**
```bash
set -u

PYBIN=python3
case "$(command -v python3 2>/dev/null)" in
  ''|*WindowsApps*)
    if command -v python >/dev/null 2>&1; then
      PYBIN=python
    else
      echo "[poser-verdict] python3 ou python requis (ADR-054)" >&2
      exit 1
    fi
    ;;
esac

"$PYBIN" -I -S - "$@" <<'PY_POSER_VERDICT_EOF'
```

**Imports et `fcntl` optionnel (l.89-103) :** `datetime, hashlib, json, os, re, stat, sys, tempfile, unicodedata, urllib.parse` ; `try: import fcntl / except ImportError: fcntl = None`.

**Codes de sortie par exception `Refus` (l.117-121, l.1086-1101) :**
```python
class Refus(Exception):
    def __init__(self, code, message):
        Exception.__init__(self, message)
        self.code = code
        self.message = message
...
    except Refus as refus:
        print("[poser-verdict] " + refus.message, file=sys.stderr)
        if refus.code == 64:
            print(USAGE, file=sys.stderr)
        sys.exit(refus.code)
    except OSError as exc:
        print("[poser-verdict] échec de lecture ou d'écriture (%s) : aucun verdict posé" % type(exc).__name__, file=sys.stderr)
        sys.exit(1)
```
Codes proposés RESEARCH (A9, à figer au plan) : 0 écrit · 64 usage · 73 dépassé (repli) · 74 pas de `fcntl` · 1 E/S. **Message sans chemin absolu ni « no such file » / « can't open »** (P46-D-10, `FRAGMENTS_INTERDITS_SORTIE`) : ne nommer que le chemin relatif au lab ou le type d'exception (`type(exc).__name__`).

**Verrou (l.926-934) — adapter : verrouiller `<clé>/verrou` (fichier stable jamais remplacé), pas le fichier gardé :**
```python
def ouvrir_verrou(chemin):
    if fcntl is None:
        return None
    descripteur = os.open(chemin, os.O_RDONLY | SANS_SUIVI_DE_LIEN)
    fcntl.flock(descripteur, fcntl.LOCK_EX)
    return descripteur
```
Ordre dans `poser` à imiter (l.1054) : verrou → lecture → contrôle → écriture atomique ; la vérification « ma génération est la plus haute » se fait **sous le verrou**, au moment d'écrire (jamais au réveil), `# baux-verif-sous-verrou`.

**Écriture atomique (l.1008-1021) — copier, en passant la cible par `os.path.realpath` et en refusant un lien :**
```python
def ecrire_atomique(dossier, nom, texte):
    chemin_verdict = os.path.join(dossier, nom)
    descripteur, chemin_tmp = tempfile.mkstemp(prefix=".VERDICT.", suffix=".tmp", dir=dossier)
    try:
        with os.fdopen(descripteur, "w", encoding="utf-8") as fh:
            fh.write(texte)
            fh.flush()
            os.fchmod(fh.fileno(), 0o644)
        os.replace(chemin_tmp, chemin_verdict)  # verdict-atomique
    except BaseException:
        if os.path.lexists(chemin_tmp):
            os.unlink(chemin_tmp)
        raise
    return chemin_verdict
```
Écart à documenter : `mkstemp` crée en 0600 ; **copier les droits de l'existant** (0644 par défaut) comme le fait `ecrire_si_different` (`os.fchmod(fd_tmp, 0o644)`, `recalc-planning.sh` l.2131).

**Identité (BAIL-05, P47-D-12) :** `--identite=hors-session:<label>` pour un cron, sinon `session:` + `os.environ["CLAUDE_CODE_SESSION_ID"]` (seule lecture d'environnement du feature, dans `baux.sh` uniquement), sinon refus 64. Le patron `CLAUDE_CODE_SESSION_ID` côté shell existe dans `plugin/conductor/scripts/driver-lock.sh` (testé par T15/T17 de `test-driver-lock.sh`).

**Ajout au G6 des scripts :** inscrire `baux.sh` dans `SCRIPTS_HOOK_G6` du hook (l.1622, tuple d'une ligne ; la 46.1 peut y ajouter son script de décision : fusion à la main).

---

### `planning-hook.sh` : `evaluer_bail` (middleware gate, request-response)

**Analogue :** `evaluer_g3` (l.1850-1876) pour la forme générale ; `evaluer_g5` (l.1487-1503) pour « un verdict sur un chemin déclaré, dérogeable ». Les gates sont **purs** (aucune écriture) : rejoués par le recalcul, le rejeu et le banc.

**Squelette à copier (garde d'entrée, identité de chemin, un `Verdict`) :**
```python
racine = contexte["racine"]  # g3-sonde
if contexte["outil"] not in OUTILS_ECRITURE or not contexte["ecrit"]:
    return []
composants = composants_nfc(contexte["ecrit"], racine)
unite = unite_de_fichier(composants, "CLOTURE.md")  # g3-forme
if unite is None:
    return []
chemin_rel = "/".join(composants)
...
return [Verdict("G3", chemin_rel, RAISON_G3_PLAN_BORNE)]
```
Adapter : `Verdict("BAIL", chemin_declare, raison)` (le chemin déclaré est le chemin d'une dérogation nominative `--gate=BAIL`). Hors liste ou liste vide → `[]` (silence).

**Identité de l'appelant (nouveau : le hook ne lit pas `session_id` aujourd'hui, 0 occurrence) :** analogue de lecture dans `evaluer_role` (l.2625) :
```python
payload = contexte["payload"]
agent_id, agent_type = payload.get("agent_id"), payload.get("agent_type")
avec_identite = isinstance(agent_id, str) and agent_id != "" and isinstance(agent_type, str) and agent_type != ""
```
**Attention :** `evaluer_role` exige `agent_id` ET `agent_type` ; l'identité du bail (P47-D-01) est `agent:<agent_id>` si `agent_id` est une chaîne non vide, **sinon** `session:<session_id>`, sinon refus fail-closed (« identité absente »). Squelette validé dans RESEARCH « Code Examples » (`identite_appelant`). Ne pas lire l'environnement.

**Fail-closed :** toute exception → `evaluer_protege` (l.2777-2782) renvoie `Verdict(gate, None, "erreur interne du gate : …")` :
```python
def evaluer_protege(gate, fonction, contexte):
    try:
        return list(fonction(contexte))
    except Exception as exc:
        return [Verdict(gate, None, "erreur interne du gate : " + type(exc).__name__)]  # protege-erreur
```
Messages de refus : relatifs au lab, jamais de chemin absolu (test de contenu, Security Domain V7).

**Pitfall 9 (tests) :** chaque cas et chaque processus d'une tempête reçoit un `agent_id` dérivé du cas ; les helpers `payload(…, agent_id="agent-test")` des suites fixent aujourd'hui un `agent_id` constant et `session_id: "sess-test"` (`test-planning-gates.sh` l.202+ ; `canary`/`canary-agent` dans `check-gates-alive.sh` l.445-448 ; `rejeu`/`rejeu-agent` dans `rejeu-gates.sh` l.1456-1459) : sinon un `doit-refuser` devient un `doit-passer` en silence.

---

### `planning-hook.sh` : `evaluer_g2p` (middleware gate, request-response)

**Analogue :** `evaluer_g3` (même accroche `unite_de_fichier(composants, "CLOTURE.md")`, l.1801-1815 pour la fonction de forme ; l.1856 pour l'appel) ; imputation = fonction pure sur le modèle de `decider_trace`.

**Forme de l'unité (à réutiliser, ne pas toucher) :** `unite_de_fichier` (l.1801-1815) :
```python
n = len(composants)
if n not in (6, 8) or composants[-1].casefold() != nom.casefold():
    return None
if composants[0].casefold() != ".planning" or composants[1].casefold() != "cycles" or composants[3].casefold() != "phases":
    return None
if n == 8 and composants[5].casefold() != "plans":
    return None
unites = [composants[2], composants[4]] + ([composants[6]] if n == 8 else [])
if not all(NOM_UNITE.match(u) for u in unites):
    return None
return composants[:-1]
```
`unite_de_chemin` (voisine, pour l'ouverture d'unité sur un fichier quelconque de l'unité) = **même validation des composants sans exiger un nom de fichier** : à écrire à côté, sans modifier `unite_de_fichier` (RESEARCH R-1, `[ASSUMED]`). Une `CLOTURE.md` d'une autre forme (niveau cycle, style GSD) → `[]` (banc G13).

**Imputation (fonction pure, à placer avec le bloc partagé, squelette RESEARCH « Code Examples » `impute`)** : `ouvrir` = dernière ligne `ouverture` de l'unité ; `contournement` après elle ou `"contournement" in decider_baux(lignes, sha)` ; `couvert` = une ligne `prise` de `unite == U` après l'ouverture ; imputé ⇔ `contourne and not couvert`. Pas de ligne `ouverture` → non jugé + observation `g2p-sans-reference` (jamais un refus sur une référence que le moteur n'a pas posée).

**Observation sans refus (pour `g2p-sans-reference`, `fichier hors borne`) :** `observer(Verdict(...), contexte)` (l.1321-1340) — écrit une ligne au journal d'observation, jamais une exception :
```python
ligne = "{}  gate={}  lab={}  chemin={}  outil={}  raison={}\n".format(horodatage, verdict.gate, _jeton_journal(contexte.get("racine"), "-"), ...)  # obs-ligne
descripteur = os.open(chemin, os.O_WRONLY | os.O_APPEND | os.O_CREAT | SANS_SUIVI_DE_LIEN, 0o600)
```
(un gate dont la sortie doit rester vide en `observe` n'utilise **pas** `observer` pour un cas qui passe normalement : voir G12/G21, « passe + observation »).

**Dérogation nominative :** automatique par `decider` sur `Verdict("G2P", chemin_rel_du_CLOTURE, raison)` ; banc G20.

---

### `planning-hook.sh` : `effets_baux` + appel dans `main` (service, event-driven)

**Analogue (emplacement et contrat) :** `inscrire_intentions(payload, cibles)` (l.3011-3024), appelée dans `main` **uniquement** si `refus` est vide (l.3525-3530). C'est là que `effets_baux` s'insère, juste avant `inscrire_intentions` :
```python
if refus:
    sortie_refus(refus)
else:
    inscrire_intentions(payload, cibles or [(ecrit, racine)])  # d1-intention : la décision finale est un passage, l'écriture par outil est tracée (D1)
    if avis:
        sortie_contexte(avis)
```
**Zone partagée 46.1 : la plus fragile** (`main`, `cibles`, `depart_evenement`, sélection du lab `sys.argv[5]`). L'appel doit rester sur le chemin « aucun refus » et réutiliser les **mêmes `cibles`**. Citer la fonction `main` (branche `EVT_PRETOOLUSE`), pas la ligne.

**Analogue de la règle « l'effet n'a lieu que si la décision finale passe » :** `decider` (l.1456-1484), consommation de dérogation :
```python
if refus:  # decider-global
    return refus, citations
for verdict, entree in couverts:
    if consommer(contexte["racine"], entree):
```
**Analogue de la forme d'un effet fail-open sous journalisation :** `inscrire_intentions` (`try … except Exception: return`). **Écart voulu pour `effets_baux`** : en `armed`, toute exception remonte (le `except BaseException` de `main` rend un `deny` fail-closed, l.3542-3545) ; en `observe`, l'exception est capturée et journalisée par `observer` et ne refuse jamais (RESEARCH R-2, condition 3).

**Réponse à l'agent (déjà existante) :** `sortie_contexte(textes)` (l.1184-1188), `additionalContext` ; le `Write` de la demande est un **allow** (jamais un `deny` « de succès »).

**Demande de prise (lecture) :** le contenu est lu dans `tool_input.content` du payload — patron de `adhesion_conservee` (l.1687-1695) :
```python
entree = contexte["payload"].get("tool_input")
if contexte["outil"] == "NotebookEdit" or not isinstance(entree, dict):
    return RAISON_ADHESION_INVERIFIABLE
texte = entree.get("content") if contexte["outil"] == "Write" else _appliquer_edit(cible, entree)
```
puis `lire_frontmatter(texte)` (l.587). Une seule fonction de validation de la demande, appelée par le gate **et** par l'effet (les gates restent purs ; l'effet re-dérive).

---

### `planning-hook.sh` : protection G6 en profondeur et liste de `config.json` (middleware, request-response)

**Analogue :** `fichier_protege` (l.1590-1612), `script_protege` (l.1626-1643), `adhesion_conservee` (l.1687-1695), `evaluer_g6` (l.1698-1719).

**Limite à lever (vérifiée) :** `fichier_protege` n'accepte que l'**enfant direct** de `.planning/` :
```python
a_la_racine = _meme_dossier(parent, planning)  # g6-racine
if a_la_racine and nom.casefold() in PROTEGES_G6:  # id-casefold
    return PROTEGES_G6[nom.casefold()]
```
`Write` sur `.planning/baux/<clé>/gen-9/meta` **passe aujourd'hui**. Ajouter une fonction voisine (ex. `sous_arbre_baux_protege`) selon le patron d'identité de `fichier_protege` / `script_protege` : `os.path.realpath`, `unicodedata.normalize("NFC", …)`, comparaison `casefold`, `os.path.samefile` pour un lien dur existant, `_meme_dossier` :
```python
def _meme_dossier(a, b):
    try:
        return os.path.samefile(a, b)
    except OSError:
        return a.casefold() == b.casefold()
```
Refuser `Write`/`Edit`/`NotebookEdit` sur tout `<planning>/baux/**` **sauf** le motif exact des demandes (`demandes/<nom>.md`, `Write` seul, nom `^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$`). Ajouter un genre à `raison_g6(nom, genre)` (l.1569-1576, fusion à la main avec le genre du compteur G4′ de la 46.1) :
```python
def raison_g6(nom, genre):
    if genre == "derog":
        return ("%s est un fichier inscrit par deroger-gate.sh — l'écriture par outil est refusée ; ..." % nom)
    if genre == "d1":
        return "%s est inscrit par le moteur (D1) : l'écriture par outil est refusée ; ce journal ne se rédige pas" % nom
```
Corollaire : G6 est **armé** (étape 1) → cette protection est armée dès la livraison alors que `BAIL`/`G2P` sont en observation (aucune régression attendue : personne n'écrit sous `baux/`).

**Liste déclarée dans `config.json` (BAIL-04) :** `evaluer_g6` applique aujourd'hui à `config.json` la seule règle `adhesion_conservee` (genre `"adhesion"`, l.1716-1719). Étendre à « adhésion **et** liste conservées » : comparer la liste du contenu proposé à celle du contenu courant (`lire_octets_bornes`), sur le même patron que `_appliquer_edit` (l.1646-1662) pour reconstruire le contenu d'un `Edit`. **Ne pas** reproduire le verrou de la 46.1 posé sur `config.json` (un `Write` peut le remplacer) : verrouiller un fichier `verrou` stable.

**Pièges de protection :** liens dans `baux/` (Pitfall 10) → `lstat` à chaque niveau ; patron `inscrire_surveillance` : `if os.path.islink(planning) …: return`.

---

### `planning-hook.sh` : bloc d'armement (config)

**Analogue :** les constantes et la table (l.133-144) ; `armement_valide` (l.551-570) ; `GATES_A_VERDICT` (l.2774) ; texte de refus dans `evaluer_gates` (l.2790-2792).

**Lignes à étendre dans le même commit (une constante par ligne avec le marqueur `# etape-<n>` que les suites relisent par regex) :**
```python
ARMEMENT_G4P = "observe"  # etape-6
ARMEMENT_BAIL = "observe"  # etape-7
ARMEMENT_G2P = "observe"  # etape-7
ORDRE_ETAPES = (("G6", "G5"), ("G1",), ("G7",), ("ROLE",), ("G3", "G4"), ("G4P",), ("BAIL", "G2P"))
TABLE_ARMEMENT = {…, "G4P": ARMEMENT_G4P, "BAIL": ARMEMENT_BAIL, "G2P": ARMEMENT_G2P}
```
Nommer `G2P` (ASCII, comme `G4P` pour G4′) et `BAIL`. **`armement_valide` (patron de la scission 5a/5b, ligne `armement-g3-g4`, l.562-563) :**
```python
if table.get("G4") == "armed" and table.get("G3") != "armed":
    return False  # armement-g3-g4
```
→ ajouter `if table.get("G2P") == "armed" and table.get("BAIL") != "armed": return False  # armement-bail-g2p` (scission 7a/7b, P47-D-06a). La règle générale « une étape commencée exige la précédente armée en entier » (boucle l.564-569) rend l'étape 7 inarmable tant que G4′ (étape 6) ne l'est pas.

**`GATES_A_VERDICT` (une ligne, marqueur `# gates-a-verdict`) :** ajouter `("BAIL", evaluer_bail), ("G2P", evaluer_g2p)` ; un mutant du banc remplace cette ligne entière (`make_hook_mutant(…, "# gates-a-verdict", …)`, ex. `test-planning-gates.sh` l.1875) : **tous ces mutants énumèrent les gates en dur** et doivent suivre.

**Texte de refus de table incohérente (`evaluer_gates`)** : ajouter « puis BAIL et G2′ » à la liste d'étapes (P47-D-10).

---

### `scripts/recalc-planning.sh` : verrou d'écriture, colonne « Bail en cours », règle miroir (service, batch)

**Analogue du verrou :** `poser-verdict.sh` `ouvrir_verrou` (l.926-934, cité ci-dessus) pour la forme ; le patron de refus d'un dossier de planning en lien existe déjà dans `appliquer_ecritures` (l.2334-2341) :
```python
try:
    planning_est_lien = stat.S_ISLNK(os.lstat(planning).st_mode)
except OSError:
    planning_est_lien = False
if planning_est_lien:
    print("[recalc-planning] dossier de planning en lien symbolique : " + planning, file=sys.stderr)
    return (1, None)
```
Le fichier **n'importe pas `fcntl` au niveau module** aujourd'hui (seulement `import fcntl as _verrou` dans `inscrire_surveillance`, l.1973) : ajouter `try: import fcntl / except ImportError: fcntl = None` comme `poser-verdict.sh` l.100-103.

**Où poser le verrou (Pattern 7, `main` l.2414-2511) :** chemin d'écriture seulement, **après** les refus d'adhésion (code 2, l.2452-2460) et de détection GSD (code 3, l.2462-2471), `flock(LOCK_EX)` sur le **descripteur du dossier de planning** ; déplacer `scanner(planning_abs)` (aujourd'hui l.2422, avant les deux branches) **sous** le verrou pour le chemin d'écriture ; la lecture seule garde l'ordre actuel (`--read-only` n'écrit jamais, G19). Le dédoublonnage de `cloture.log` (`lire_journal` l.2342 → `lignes_a_journaliser` l.2354 → `ajouter_au_journal` l.2357) tombe ainsi sous le verrou. Ordre des verrous écrit en référence : planning, puis `surveillance.log` ; `<clé>/verrou`, puis `empreintes.log` ; jamais l'inverse.

**Écriture atomique existante (réutiliser, ne rien ajouter) : `ecrire_si_different` (l.2107-2147).**

**Colonne « Bail en cours » :** `rendre_index` (l.2045-2074) code `aucun` en dur (l.2058) :
```python
lignes.append(
    "| " + cycle["chemin"] + " | " + _texte_etat_cycle(cycle) + " | " + phase_courante
    + " | " + dernier + " | aucun |"
)
```
Remplacer `aucun` par `<chemin>#<n>` triés séparés par `, ` (aucun horodatage dans la colonne : sinon `INDEX.md` serait réécrit à chaque recalcul) ; **octet pour octet identique à aujourd'hui quand `baux/` est absent** (test de régression). Lecture seule du registre via le sous-ensemble du bloc partagé.

**Règle miroir de G2′ :** à insérer dans `_r1_a_r8` (l.1371-1455) entre R4 (livrables présents, retours `indéterminé`) et R5 (verdict présent) ; même forme de retour :
```python
return ("indéterminé", "livrable-absent:" + v, meta)
```
→ `return ("indéterminé", "bail-hors-perimetre:" + chemin, meta)` `[ASSUMED libellé]`, ajouter le code à la « Table de tous les codes de raison » de `modele-cycles.md` (§ l.643) et à `libelle_raison` (l.1786). **Cache :** `signature_unite` (l.1497-1517) ne hache que les fichiers de l'unité et le `CADRAGE.md` ; soit y ajouter le sha des fichiers déclarés + la fin du journal, soit exclure du cache l'unité à laquelle la règle s'applique (le plus simple). `NOMS_MODELE_RACINE_DOSSIERS` contient déjà `"baux"` (l.765) : non parcouru, rien à ajouter.

---

### `plugin/conductor/scripts/dag.sh` : `load` / `save` + verrou (utility, CRUD file-I/O)

**Défaut actuel (l.111-121) :**
```python
def load():
    if not os.path.exists(file):
        return {"nodes": []}
    with open(file, encoding="utf-8") as fh:
        return json.load(fh)

def save(dag):
    os.makedirs(os.path.dirname(file) or ".", exist_ok=True)
    with open(file, "w", encoding="utf-8") as fh:
        json.dump(dag, fh, indent=2, ensure_ascii=False)
        fh.write("\n")
```
Sites load-modify-save : `init` (l.318-321), `add` (l.327-350, `save` l.348), `mark` (l.361-383, `save` l.368), `reopen` (l.385-415, `save` l.411) ; `ready`/`status`/`tree` en lecture seule.

**Analogue du correctif :** `recalc-planning.sh` `ecrire_si_different` (écriture atomique du même dossier, `fchmod`, nettoyage du temporaire en cas d'erreur) :
```python
fd_tmp, chemin_tmp = tempfile.mkstemp(dir=dossier, prefix=".tmp-recalc-")
fd_non_adopte = True  # tant que os.fdopen n'a pas pris possession du descripteur (F5)
try:
    os.fchmod(fd_tmp, 0o644)
    with os.fdopen(fd_tmp, "wb") as fh:
        fd_non_adopte = False
        fh.write(octets)
    os.replace(chemin_tmp, chemin)
except Exception:
    ...
        os.remove(chemin_tmp)
    raise
```
+ `poser-verdict.sh` `ouvrir_verrou` pour `fcntl` optionnel. Squelette complet validé par prototype : RESEARCH « Code Examples » (`dag.sh` : verrou et écriture atomique). Points à respecter : `flock` sur le **descripteur du dossier** (jamais le fichier remplacé par `os.replace`), pris **avant** `load()`, relâché **après** `save()` et **avant** `check_stall_signal` / `record_progress` / `record_milestone` (jusqu'à 2 s chacun, l.377-380) ; cible `os.path.realpath(file)` ; mode de l'existant, défaut 0644 ; `import tempfile` est **déjà** présent (l.104) mais pas `fcntl` (`try/except ImportError`). Marqueurs de commentaire uniques `# dag-verrou` et `# dag-atomique` pour les mutants.

**Bump :** `plugin/conductor/VERSION` / `module.json` / `CHANGELOG.md`, **renuméroté après les merges de `fiabilite`** (A11 : patch, v1.48.2 sur `origin/main` au 2026-10-12 contre v1.46.0 sur cette branche) ; ne pas toucher `VERSION` racine, `plugin.json`, `marketplace.json`.

---

### `scripts/check-gates-alive.sh` (canary), `rejeu-gates.sh`, `rejeu-reel.sh`, `deroger-gate.sh` (utility)

**Analogue : les lignes de G4′ / de l'étape 6, et de G3-G4 (étape 5).**

`check-gates-alive.sh` : `GATES` (l.195), `CANARIS` (l.235-281), `lire_armement` (l.589-604) :
```python
GATES = ("G6", "G5", "G1", "G7", "ROLE", "G3", "G4", "G4P")
...
    # Étape 6 (46-06, P46-D-02, P46-D-11) : G4′ — ...
    "G4P-handback|G4P|nominal|SubagentHandback:sans-sortie@" + AGENT_PRODUCTEUR + "|",
    "G4P-stop|G4P|nominal|SubagentStop:sans-sortie@" + AGENT_PRODUCTEUR + "|",
...
    for gate in GATES:
        valeurs = re.findall(r'^ARMEMENT_' + gate + r' = "([^"]*)"', texte, re.M)
        if len(valeurs) != 1 or valeurs[0] not in VALEURS_ARMEMENT:
            raise Indetermine("ligne ARMEMENT_" + gate + " absente, en double ou de valeur inconnue")
```
Ajouter `"BAIL", "G2P"` à `GATES` et deux (ou plus) cas de la forme `"<id>|<gate>|nominal|<outil:chemin[@agent]>|<étiquette de couverture>"` : cas `BAIL-sans-bail` (écriture d'un fichier déclaré sans génération) et `G2P-contournement` (CLOTURE.md après un contournement). Le lab synthétique du canary doit **poser une liste déclarée dans son `config.json`** ; `agent_id` constant `"canary-agent"` (l.448) : prévoir une identité par cas (Pitfall 9). Un gate armé sans cas = signal ; en `observe`, `aucun` est admis dans la table de la référence.

`rejeu-gates.sh` : `GATES` / `ORDRE_ETAPES` / `ETAPE_DE` (l.147-149), `ETAPE_G3G4, ETAPE_G4P = 5, 6` (l.164, **ajouter une constante d'étape 7, elle ne dérive pas de `ORDRE_ETAPES`**), `armer_copie` (l.386-393), bornes `--etape` (l.1583, l.1596 : `("1", "2", "3", "4", "5", "6")` → `…"7"`, messages « attendu 1, … ou 7 ») :
```python
for gate in [g for lot in ORDRE_ETAPES[:etape] for g in lot]:
    motif = re.compile(r'^ARMEMENT_' + gate + r' = "(?:observe|armed)"', re.M)
    if len(motif.findall(texte)) != 1:
        raise ErreurOutil("motif d'armement non unique : ARMEMENT_" + gate)
```
`rejeu-reel.sh` : liste `("1".."6")` l.214-215 + usage/entête. `deroger-gate.sh` : `GATES = ("G1", "G3", "G4", "G4P", "G5", "G6", "G7", "ROLE", "PLAFOND")` (l.63), `USAGE` (l.67), message `--gate` dans `valider` (l.291). Ajouter `BAIL`, `G2P`.

---

### `references/modele-cycles.md` et spec moteur (doc)

**Analogue de structure (références) :** `### G3 — pas de clôture sans livrable (Phase 46)` (l.1220-1240) pour une section de gate (forme du chemin, conditions de refus, messages relatifs au lab, dérogation nominative, comportement en `observe`/armé) ; `### D1 — écritures surveillées` (l.1296) pour le journal ; `### Table d'armement livrée` (l.1108-1156) : table `| Gate | Étape | État | Comportement sur défaillance | Cas de canary | Relevé |` + cinq listes « sur une seule ligne » que `R-REFERENCE` compare au code ; `## Hors de cette phase` (l.1530) à amender (la ligne « G2′ et les baux : Phase 47 » devient livrée). Ajouts : section « Les baux » (registre, clé, `meta`, prise, relecture, génération incomplète = détenue par personne), `### BAIL`, `### G2′`, usage cron de `baux.sh`, limites **lettrées** chacune sur sa ligne (dernière lettre de la 46 : (bu) ; `bc` et `bd` sautées par convention ; lire la référence livrée par la 46.1 avant d'attribuer — `LIMITES_REFERENCE`, `test-planning-gates.sh` ~l.5359). **Ne pas toucher** le frontmatter de `skills/planning-core/SKILL.md` (budget d'instructions).

**Spec (`docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md`)** : §5 (G2′ l.343), §5.1-2 (annoter « réglable depuis 2.1.295 », source et date, P47-D-07), §6.1 (l.443 : la forme `<cycle>-<phase>` devient `<clé>/gen-<n>/meta`, granularité fichier, battement informatif), §6.2 (l.495), §6.4 (l.532). Convention : **annoter avec date et canal** à l'endroit amendé, sans réécrire l'historique (cf. l'annotation existante « amendement l.359 »).

---

### Tests

#### `scripts/tests/test-baux-registre.sh` (NEUF) — concurrence + mutation + ast-identité

**Analogue de squelette (suite bash + aides Python en heredoc) :** `test-cloture-empreintes.sh`.
- Entête (l.36-70) : `set -uo pipefail`, `TESTS_DIR`/`SCRIPTS_DIR`, choix de `PYBIN`, **helpers bash `ok`/`ko`** :
```bash
pass=0; fail=0
ko() {
  echo "  ✗ $1"
  echo "    assertion : $2"
  echo "    attendu   : $3"
  echo "    obtenu    : $4"
  fail=$((fail+1))
}
```
Le `ok` bash vit côté Python : `ok(libelle)` imprime `  ✓ …`, `ko(libelle, assertion, attendu, obtenu)` imprime les quatre lignes ; `okmut(ident, trace)` imprime `  ✓ MUT-<ident> TUÉ — …`, `komut(ident, assertion, attendu, obtenu)` imprime `  ✗ MUT-<ident> NON TUÉ` + `attendu (original)` / `obtenu (mutant)` (l.96-111). La boucle de la suite (`run_sections`, l.1659-1680) compte `✓`/`✗` dans la sortie des aides et termine par `echo "== Résultat : $pass OK · $fail KO =="` ; sections filtrables : `VF_BAUX_SECTIONS` (patron `VF_CLOT_SECTIONS`, `run_sections "${VF_CLOT_SECTIONS:-emp,ast,plaf,juge,mut}"`), mutants filtrables par `VF_BAUX_MUTANTS`.
- **ast-identité des copies (R-EMP-04) :** `corps_python(texte, marqueur)` (l.152-163), `corps_ast`, `arbre_de` (`ast.dump` de la fonction ou de la constante, docstring comprise), `comparer_arbres(arbres, noms, fautes)` (l.1006-1017, `controle_emp_04` l.1019) ; adapter `NOMS_BLOC`/`TROIS_COPIES` à `("planning-hook.sh","PY_PLANNING_HOOK_EOF"), ("baux.sh","PY_BAUX_EOF"), ("recalc-planning.sh","PY_RECALC_PLANNING_EOF")` (le recalcul n'ayant qu'un sous-ensemble nommé). `charger_bloc(chemin, marqueur)` (l.164) exécute le corps embarqué sans l'appel final à `main()`.
- **Mutants :** `make_mutant(ctx, nom, marqueur, ident, motif, remplacement)` (l.1443-1475) remplace l'**unique** ligne portant `motif` (indentation conservée), `bash -n` + `compile(corps_python(mute, marqueur), …)` doivent passer ; `executer_mutant(ctx, ident, nom, marqueur, motif, remplacement, cid, ctrl, mot_cle, avec_temoin)` (l.1492-1520) vérifie : l'original passe le contrôle, le témoin reste vert sous le mutant, le contrôle rougit **pour la raison visée** (`mot_cle in mutant[1]`). Table `MUTANTS = [(ident, script, marqueur, motif, remplacement, cid, ctrl, mot_clé, témoin), …]` (l.1570). Mutants à poser (RESEARCH §Validation) : `MUT-BAUX-MAKEDIRS` (`makedirs(exist_ok=True)` → `FAUX_SUCCES=20`), `MUT-BAUX-RELECTURE` **avec** injection de `mkdir` fantôme (sinon mutant équivalent, Pitfall 4), `MUT-BAUX-REPLACE` (publication du `meta` par `os.replace`), `MUT-BAUX-CLE` (clé sans NFC), `MUT-OUTIL-VERIF-AU-REVEIL`, `MUT-OUTIL-SANS-VERROU`, `MUT-OUTIL-TRUNCATION`. Jamais de mutant tué par une course ou une durée : il meurt par structure ou par verdict.

**Analogue de la tempête (T13 et T32) :** `plugin/conductor/scripts/tests/test-driver-lock.sh` l.215-232 et l.407-421. Patron exact (24 concurrents × 5 rondes) :
```bash
T13_N=24; T13_ROUNDS=5
t13_bad=0
for round in $(seq 1 "$T13_ROUNDS"); do
  rm -rf "$VF_DRIVER_LOCK" "$WORK_DIR"/rec.*
  "$SCRIPT" acquire --owner=DEAD --step=x >/dev/null 2>&1
  age_stale "$VF_DRIVER_LOCK"
  for i in $(seq 1 "$T13_N"); do ( "$SCRIPT" acquire --owner="R$i" --step=y >"$WORK_DIR/rec.$i" 2>/dev/null ) & done
  wait
  won=$(grep -l '"acquired": true' "$WORK_DIR"/rec.* 2>/dev/null | wc -l | tr -d ' ')
  ...
done
num_eq "T13.1 — $T13_ROUNDS rounds × $T13_N concurrents : jamais un seul gagnant, tous refusés …" "$t13_bad" 0
```
T32 : même squelette, `t32_worst`/`t32_zero`/`t32_bad` (« aucun round hors contrat (pire=…) », « jamais 0 gagnant »). **Écart obligatoire :** l'assertion de la tempête de la 47 n'est **pas** « un seul gagnant » mais *contiguïté 1..N sans trou, retours distincts, 0 faux succès, une seule identité passe le gate à la fin* (RESEARCH §Concurrence) ; chaque processus reçoit une identité distincte. Helpers de la suite source : `assert`, `assert_exit` (l.46-47), `num_eq` (l.191), compteurs `PASS`/`FAIL` et **garde anti-vert-à-vide** dans l'épilogue (`if [ "$((PASS+FAIL))" -eq 0 ]`) — à reprendre dans la partie bash de la nouvelle suite. Dans la suite Python-embarquée de planning-core, lancer en `subprocess.Popen` ×N puis `p.wait(timeout=60)` (voir R-VERDICT-08 ci-dessous).

**Analogue de l'injection de défaut déterministe :** `test-driver-lock.sh` T41b (l.564-581) — seam de test **inerte par défaut** `VF_DRIVER_TEST_DIE_AFTER_MUTEX` (côté script : `[ -n "${VF_DRIVER_TEST_DIE_AFTER_MUTEX:-}" ] && exit 137`, `driver-lock.sh` l.636, l.745) ; pour la 47, préférer la **copie modifiée** (patron R-VERDICT-08, ci-dessous) pour ne pas ajouter de variable d'environnement au script livré : `mkdir` fantôme = copie du bloc dont `os.mkdir` « rend sans rien créer, une fois sur deux ».

**Analogue de la copie modifiée avec délai (R-VERDICT-08) — `test-planning-gates.sh` `copie_modifiee` (l.4480-4498) et `controle_verdict_verrou` (l.4565-4600) :**
```python
d = copie_modifiee(ctx, _dossier(ctx, script), "poser-verdict.sh",
                   [("    controle_tentative(tentative, ancienne)\n",
                     "    controle_tentative(tentative, ancienne)\n    import time\n    time.sleep(0.7)\n")], "poser-avec-delai")
...
procs = [subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=ctx.env()) for _ in range(2)]
codes = sorted(p.wait(timeout=60) for p in procs)
...
lota_mutant("VERDICT-VERROU", "# verdict-verrou", "verrou = None  # verdict-verrou", "R-VERDICT-08", "poser-verdict.sh", "PY_POSER_VERDICT_EOF")
```
`copie_modifiee` exige que chaque motif apparaisse **exactement une fois** et fait passer `bash -n`. C'est le patron pour : injecter un délai entre la lecture de `n` et le `mkdir` (tempête) ; injecter un délai entre `load()` et `save()` dans `dag.sh` ; injecter un délai dans le recalcul pour rendre la double-écriture de `cloture.log` observable.

#### `scripts/tests/test-bail-gate.sh` (NEUF) + `fixtures/bail-banc.txt`

**Analogue :** `test-cloture-gates.sh` + `fixtures/cloture-banc.txt` (banc texte, mêmes directives) ; helpers de `test-planning-gates.sh`.
- **Rejeu par la commande enregistrée** (jamais par appel direct, P45-D-20) : classe `Ctx` (`test-planning-gates.sh` l.253-350) : `charger_commande()` lit `hooks.json`, `lancer(mode, entree, cwd, dossier)` rejoue sous `/bin/sh -c`, `copie_forcee(dossier, valeur)` / `copie_armee()` forcent les constantes `ARMEMENT_*` sur une **copie** (jamais l'état livré). **À étendre :** `forcer_armement` (l.243-251) et son motif `^(ARMEMENT_(G6|G5|G1|G7|ROLE|G3|G4|G4P) = )` ; le `if n != 8: raise RuntimeError("huit constantes ARMEMENT_* attendues, …")` (l.329 ; second contrôle R-TABLE l.3370) ; `observe_partout` (l.600) ; `ETAPES_FORCEES`. **C'est exactement le piège n°1 de la recherche** (`re.subn` trouve encore 8 sur 10 constantes) : les 7 suites « découplées » (`test-planning-gates`, `test-d1-surveillance`, `test-cloture-gates`, `test-g4p-sortie-brute`, `test-juges-canary`, `test-planning-hook-registered`, `test-rejeu-gates`) + `plugin/_internal/tests/test-planning-hook-installed.sh` doivent être étendues dans le commit qui ajoute les constantes, avec le **test de recensement** de Wave 0.
- **Payload :** `payload(outil, entree, cwd, agent_type=None, agent_id="agent-test")` (`test-planning-gates.sh` l.202-215) pose `session_id: "sess-test"` ; le banc BAIL doit paramétrer `agent_id` **et** `session_id` par cas (session revenue / sous-agent frère / session non reprise).
- **Classification de sortie :** `classer(rc, out)` (l.353-380) rend `silence | avertit | deny | block | watchPaths | autre:…` ; `contexte_de(out)` lit `additionalContext` (réponse à la demande de prise). Contrôle `doit-passer` = `v in ("silence", "avertit")`, `doit-refuser` = `v == "deny"` (l.595-597).
- **Banc texte :** grammaire `@@ lab <nom> [jumeau-de=<lab>]` / `@@ fichier` / `@@ dossier` / `@@ lien` / directive propre `@@ ecriture <outil> <chemin> [agent=<type>] :: <attendu> <gate>` (entête de `fixtures/cloture-banc.txt` ; analyseur `parser_banc`, `test-planning-gates.sh` l.392). Pas d'arborescence versionnée (« l'installeur pose `fixtures/` à plat ») ; **chaque lab adhérent porte son jumeau `-dev`** non adhérent qui doit se taire (GATE-10). Étendre la grammaire par une directive `@@ bail <fichier> gen=<n> detenteur=<identité>` matérialisée par la **vraie** prise du bloc partagé (jamais un `meta` écrit à la main, par analogie avec `@@ verdict` qui appelle la vraie `poser-verdict.sh`).
- **Mutants :** `make_hook_mutant(ctx, ident, motif, remplacement)` (`test-planning-gates.sh` l.607-650 via `make_script_mutant` ; copie dans `test-cloture-gates.sh` l.360-390 avec `observe_partout` de base) ; `tuer(ctx, ident, motif, remplacement, id_controle, controle)` de `test-d1-surveillance.sh` l.1534-1555 (original conforme, **témoin** « Write neutre d'un lab adhérent » inchangé sous le mutant, contrôle rouge sous le mutant) ; `rendre(ident, titre, controle, ctx)` pour les cas verts. Mutants listés dans la recherche : `MUT-BAIL-IDENTITE`, `MUT-BAIL-DETENTEUR`, `MUT-BAIL-INCOMPLET`, `MUT-BAIL-SAMEFILE`, `MUT-BAIL-PREFIXE`, `MUT-G6-BAUX`, `MUT-LISTE-G6`, `MUT-LISTE-PREFIXE`, `MUT-BAIL-EFFET-AVANT-DECISION`, `MUT-ADHESION-IGNOREE`. Marqueur de commentaire unique par branche (`# bail-…`) car `make_hook_mutant` exige **une seule ligne porteuse**.

#### `scripts/tests/test-g2prime.sh` (NEUF)

**Analogue :** `test-d1-surveillance.sh` (suite de la même famille : journal, réconciliation, `copie_forcee`, sections `base,mutants_base,moteur,mutants_moteur,…` filtrées par `VF_D1_SECTIONS`, `tuer`/`rendre`). Reprendre `fabriquer_lab` (`test-cloture-gates.sh` l.409-427, lab avec `plan`, `unite`, `fichiers`, `liens`, `adherent` ; variante D1 : `test-d1-surveillance.sh` l.349), `ecrire_dans` (l.428), `session` (l.433 ; D1 l.793), `journal_d1` (l.451) → `journal_empreintes(lab, cle)`, `deroger(ctx, lab, gate, chemins)` (l.464), toutes dans `test-cloture-gates.sh`. Un test par cas du banc G01-G23 de la recherche, chacun avec son jumeau `-dev`. G05 (« changement avant l'ouverture ») et G19 (« `--read-only` : arbre du lab identique octet pour octet avant/après ») sont les cas structurants ; G10/G15/G16/G17 sont des **limites nommées**, comptées à part (jamais comptées comme faux accept).

#### `plugin/conductor/scripts/tests/test-dag.sh` (T50-T52)

**Analogue de squelette (en place) :** entête et helpers de `test-dag.sh` (l.20-48) — `assert`, `assert_not`, `assert_exit`, `assert_eq`, `run_bounded`, `WORK_DIR`, `F="$WORK_DIR/m.dag.json"`, `set -uo pipefail`, épilogue avec garde anti-vert-à-vide ; dernier cas existant `T49` (l.923). **Baseline à ne pas régresser : `Résultats : 161 PASS / 0 FAIL`.** Ajouter `T50` (perte déterministe par injection de délai entre `load()` et `save()` dans une **copie** de `dag.sh` + rondes), `T51` (lecteur concurrent : jamais de JSON tronqué sur une boucle de `dag.sh ready`), `T52` (droits 0644 conservés, lien conservé). Mutants `# dag-verrou` retiré → perte ; `# dag-atomique` → lectures déchirées (observé : 108 sur 1613) : chacun doit rougir **pour sa raison**. Tempête à l'identique de T13 : `for i in $(seq 1 "$N"); do ( "$SCRIPT" add --file="$F" --id="N$i" --step=s >/dev/null 2>&1 ) & done; wait`, puis compter les nœuds finaux. Ce fichier est dans la surface de `check-gate-touche.sh` (`Gate-Touche:` obligatoire).

#### `scripts/tests/test-recalc-planning.sh` (cas concurrent)

**Analogue :** `test-planning-gates.sh` R-VERDICT-08 (deux `Popen` + délai injecté via `copie_modifiee`). `test-recalc-planning.sh` a déjà `ok()`/`ko()` bash (l.98-105), le coureur de banc R01-R04 et `fixtures/recalc-planning-banc.txt` ; ajouter un cas « deux recalculs simultanés, délai entre `lire_journal` et `ajouter_au_journal` : `cloture.log` sans doublon, `INDEX.md` cohérent » et un cas de régression « colonne `Bail en cours` = `aucun` octet pour octet sans `baux/` ». Mutant `MUT-RECALC-SANS-VERROU`.

---

## Shared Patterns

### Contrat de sortie du hook (jamais exit 2) et fail-closed sous adhésion
**Source :** `planning-hook.sh` `sortie_refus` (l.1176-1181), `sortie_contexte` (l.1184-1188), `main` Phase B (l.3513-3550), `_emettre` (l.1169).
**Apply to :** `evaluer_bail`, `evaluer_g2p`, `effets_baux` (refus par `permissionDecision: deny` code 0 ; erreur interne → deny, P45-D-08 ; hors adhésion → `sys.exit(0)` silence).
```python
def sortie_refus(raisons):
    _emettre({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": "\n".join(raisons),
    }})
```

### Entonnoir de décision (armed → deny, observe → ligne d'observation, dérogation)
**Source :** `decider` (l.1456-1484), `Verdict = collections.namedtuple("Verdict", ("gate", "chemin_rel", "raison"))` (l.1210), `evaluer_gates` (l.2785-2801).
**Apply to :** toute nouvelle fonction `evaluer_*` : renvoie `[Verdict(...)]`, **ne décide jamais** ; ne jamais ajouter un second chemin de refus.

### Dérogation nominative consommée seulement si la décision finale passe
**Source :** `derogation_active` (l.1395-1409), `consommer` (l.1412-1447, flock + relecture sous verrou), `citer` (l.1450). CLI : `deroger-gate.sh` ; copies à jour dans `poser-verdict.sh` (l.817-916).
**Apply to :** `BAIL` et `G2P` (jeton de gate ajouté à `GATES` de `deroger-gate.sh`).

### Écriture du moteur expliquée au journal de D1 (`inscrire_ecriture_moteur`)
**Source :** `planning-hook.sh` l.2999-3008 (copies `recalc-planning.sh` l.2320, `poser-verdict.sh` l.786).
**Apply to :** tout écrivain du moteur qui écrit un fichier surveillé (le recalcul après verrou ; `baux.sh` n'écrit **pas** de fichier surveillé par D1, il écrit des fichiers déclarés par le lab).
```python
empreinte = empreinte_fichier(os.path.join(racine, *chemin_rel.split("/")))
if empreinte is not None:
    inscrire_surveillance(racine, "moteur", chemin_rel, empreinte, par, None)
```
**Ne pas étendre D1** pour les fichiers déclarés (zone réécrite par la 46.1, N-5/A5 ; D1 ne connaît que les formes sous `.planning/` : `chemin_relatif_surveille` rend `None` si `composants[0] != NOM_PLANNING`).

### Lecture bornée et sans lien de tout fichier contrôlé par l'agent
**Source :** `lire_octets_bornes` (l.501-518), `est_fichier_regulier` (l.482-487), `SANS_SUIVI_DE_LIEN`, `empreinte_fichier` (l.2902-2931).
**Apply to :** journal d'empreintes, `meta`, demande de prise, `config.json`, fichiers déclarés. Inscrire chaque nouvel appel dans `RECENSEMENT_LECTURE` / `RECENSEMENT_READDIR` (`test-planning-gates.sh` l.884, l.959) dans le même commit.

### Identité de chemin (APFS/ext4) : NFC pour comparer, nom brut pour les E/S
**Source :** `composants_nfc` (l.471-480), `_meme_dossier` (l.1583-1587), `fichier_protege` (l.1590-1612).
**Apply to :** comparaison chemin écrit / fichier déclaré (`samefile`, sinon NFC + `casefold` par composants), clé d'unité du repère `.unites/`. Tout cas de test à chemin composable a son **jumeau NFD** (`jumeau_nfd`, `test-planning-gates.sh` ; dérivé par la suite, R-BANC-NFD).

### Copies ast-identiques d'un bloc partagé
**Source :** `controle_emp_04`, `comparer_arbres`, `NOMS_BLOC`, `NOMS_JOURNAL` (`test-cloture-empreintes.sh` l.963-1048) ; `controle_d1_09` (`test-d1-surveillance.sh`).
**Apply to :** le bloc registre + journal (hook, `baux.sh`, recalcul). Une retouche suit dans les trois fichiers ; les fonctions qui lisent l'environnement restent hors du bloc.

### Écriture atomique + verrou stable
**Source :** `ecrire_atomique` (`poser-verdict.sh` l.1008-1021), `ecrire_si_different` (`recalc-planning.sh` l.2107-2147), `ouvrir_verrou` (`poser-verdict.sh` l.926-934).
**Apply to :** `baux.sh ecrire`, `dag.sh save`, verrou du recalcul. **Anti-pattern :** verrouiller le fichier que `os.replace` remplace (le suivant verrouille un autre inode) ; verrouiller un descripteur de dossier ou un fichier `verrou` jamais remplacé.

### Harnais de test : `ok`/`ko`, mutants à marqueur unique, témoin, jumeau `-dev`
**Source :** `test-cloture-empreintes.sh` (aides Python en heredoc `PY_AIDES_…_EOF`, `run_sections`), `test-planning-gates.sh` (`Ctx`, `classer`, `make_script_mutant`, `lota`/`lota_mutant`/`sec_lota` l.4040-4140), `test-d1-surveillance.sh` (`tuer`, `rendre`).
**Apply to :** les trois suites neuves. Règles : suite lancée par `bash <suite>` (jamais sourcée), portable GNU/BSD (ni `stat -f/-c`, ni `sed -i`, ni `timeout`, ni `readlink -f`, ni `grep -P`, `cmp -s` jamais `diff`), bash 3.2 (ni `declare -A`, ni `mapfile`), jamais `commande && { … }` nu (piège CI `bash -e {0}`), Python 3.9, nom `test-*.sh` sous un dossier `tests/` (découverte CI `find plugin scripts -type f -path '*/tests/test-*.sh'`), le compte « N suites » de `README.md` et `README.fr.md` suit (`scripts/check-version-sync.sh`).

### Marqueur `Gate-Touche:` et convention de commit
**Source :** `CLAUDE.md` (Gardes in-repo) ; `scripts/check-gate-touche.sh`.
**Apply to :** tout commit qui touche un gate, sa suite, un hook ou `test-dag.sh` : un trailer `Gate-Touche: <chemin> — <raison ≥ 10 caractères>` par chemin, sans virgule (P47-D-16). Commits en français ; décisions préfixées `P47-D-NN`, jamais `D-01` nu ; canal et date de tout arbitrage.

### Version / module (aucune release)
**Source :** `plugin/planning-core/CHANGELOG.md` entrée `## [v2.10.0] — 2026-10-06 (…)` (forme : titre daté, `**Minor** (nouvelle capacité) :`, puces gras « État d'armement livré », « … »), `module.json` (champ `version`, `description` à compléter), `VERSION`.
**Apply to :** `planning-core` v2.12.0 (la 46.1 l'aura passé en v2.11.0 : **relire les valeurs livrées**), `conductor` patch renuméroté. **Ne pas** toucher `VERSION` racine, `plugin.json`, `marketplace.json`, badges ni historique des README (ADR-073, garde-fou du jalon).

### Zone partagée avec la 46.1 (à déclarer dans chaque plan qui la touche, P47-D-10)
`ARMEMENT_*` / `ORDRE_ETAPES` / `TABLE_ARMEMENT` / `armement_valide` ; `GATES_A_VERDICT` ; `PROTEGES_G6` / `fichier_protege` / `raison_g6` / `SCRIPTS_HOOK_G6` ; `main` (branche PreToolUse, `cibles`, `depart_evenement`) ; D1 (`reconcilier`, `decider_trace`, `FICHIERS_RACINE_SURVEILLES` — **non touchés par la 47**) ; `hooks.json` / `COMMANDE_REFERENCE` (**non réécrits**, P47-D-11) ; `check-gates-alive.sh` (`GATES`, `CANARIS`, `lire_armement`) ; `rejeu-gates.sh` / `rejeu-reel.sh` ; `NOMS_MODELE_RACINE_*` ; suites `test-planning-gates.sh`, `test-cloture-gates.sh`, `test-d1-surveillance.sh`, `test-rejeu-gates.sh` ; `modele-cycles.md` ; spec §5 ; `VERSION`/`module.json`/`CHANGELOG.md`. Plans 47-05 et 47-06 touchent le même fichier (`planning-hook.sh`) : à séquencer.

---

## No Analog Found

| Fichier / fonction | Rôle | Flux | Raison |
|---|---|---|---|
| `prendre` / `plus_haute` / `publier_exclusif` (génération entière monotone, jamais effacée, `mkdir` exclusif + `os.link` du `meta` + relecture) | utility | file-I/O concurrent | `driver-lock.sh` est le seul analogue de prise concurrente mais utilise `epoch.pid`, `ln -sh` d'abord (piège uutils P47-D-14) et **efface** les générations ; utiliser le squelette prototypé de RESEARCH « Code Examples ». |
| `impute` / règle d'imputation G2′ (journal d'empreintes par fichier déclaré, `ouverture`, `prise` = déclaration) | utility (fonction pure) | transform | Conception neuve (P47-D-04a), RESEARCH R-1 ; `decider_trace` ne fournit que la règle d'explication (`decider_baux`), pas l'imputation à une unité. Confiance MEDIUM : jamais exercée contre le vrai harnais. |
| Protection G6 **en profondeur** de `.planning/baux/**` | middleware | request-response | `fichier_protege` ne protège que l'enfant direct de `.planning/` ; il n'existe aucune protection de sous-arbre à copier (patron d'identité seulement). |
| Geste de prise par fichier de demande (`Write` → effet après décision finale) | middleware | event-driven | Aucun gate existant ne transforme une écriture par outil en effet disque : seule la consommation de dérogation de `decider` ressemble (même contrainte « seulement si la décision finale passe »). |
| `unite_de_chemin` (forme d'unité sans nom de fichier imposé) | utility | transform | À écrire à côté de `unite_de_fichier` sans la modifier (RESEARCH R-1, `[ASSUMED]`). |
| Test de recensement « toute constante `ARMEMENT_<X>` figure dans chaque expression des suites et dans `GATES` des trois scripts » | test | transform | Aucun test existant ne recoupe les 15 lieux ; commande de recensement rouge aujourd'hui fournie par RESEARCH (`AssertionError: constantes ARMEMENT_* : 8 (attendu 10)`). |

---

## Metadata

**Analog search scope :** `plugin/planning-core/scripts/` (hook, recalcul, pose de verdict, dérogation, canary, rejeu, suites et fixtures), `plugin/planning-core/references/modele-cycles.md`, `plugin/planning-core/{VERSION,module.json,CHANGELOG.md}`, `plugin/conductor/scripts/` (`dag.sh`, `driver-lock.sh`, suites), `docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md` §5-§6, `.planning/BACKLOG.md`.
**Files scanned :** ~30 fichiers lus par plages (47-CONTEXT, 47-RESEARCH, 47-SCOUTING en entier ; hook, recalcul, pose, dag, driver-lock, 6 suites par sections).
**Non lus par contrainte :** `47-RECHERCHE-BAUX.md` (faits repris via RESEARCH), le checkout `gouvernance-46-1` (interdit : ses plans et son `46.1-PATTERNS.md` ne sont pas relus ; la zone partagée est traitée par fonction), aucun lab externe.
**Pattern extraction date :** 2026-10-12

## PATTERN MAPPING COMPLETE
