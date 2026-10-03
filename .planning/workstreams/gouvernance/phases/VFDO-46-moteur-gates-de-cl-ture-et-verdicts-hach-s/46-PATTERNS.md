# Phase 46: Moteur — gates de clôture et verdicts hachés - Pattern Map

**Mapped:** 2026-10-03
**Compartiment :** `gouvernance` (toute commande GSD : `--ws gouvernance`, `node ~/.claude/gsd-core/bin/gsd-tools.cjs`)
**Files analyzed:** 38 (fichiers à créer ou modifier, d'après `46-CONTEXT.md` P46-D-01..19, `46-RESEARCH.md` « Découpage recommandé » et « Wave 0 Gaps »)
**Analogs found:** 38 / 38 (dont 4 fichiers sans analogue direct pour une partie de leur logique : voir « No Analog Found »)
**Racine des chemins :** le worktree `gouvernance-46` ; `PC` = `plugin/planning-core`. Tous les analogues cités ont été vérifiés **suivis par git** (`git ls-files`) : aucun miroir d'installation ou de runtime n'est cité.
**Numéros de ligne :** relevés sur le worktree à la date ci-dessus ; ils dérivent à chaque commit sur ces fichiers, ancrer de préférence sur les **balises de commentaire** (`# g1-cadrage`, `# decider-armed`…) que les mutants des suites utilisent.

Format de référence pour ce document : `45-PATTERNS.md` (même dossier de phase voisin, `VFDO-45-…/45-PATTERNS.md`).

## File Classification

| Fichier nouveau / modifié | Rôle | Flux de données | Analogue le plus proche | Qualité |
|---|---|---|---|---|
| `PC/scripts/planning-hook.sh` — `evaluer_g3`, `evaluer_g4` | gate (hook PreToolUse) | request-response | `evaluer_g1` + `unite_de_plan` (`planning-hook.sh:1281-1339`) | exact |
| `PC/scripts/planning-hook.sh` — `evaluer_g4p` + grammaire sortie brute | gate (hook PreToolUse/SubagentStop) | request-response | `evaluer_role` (`planning-hook.sh:1989-2024`) | role-match |
| `PC/scripts/planning-hook.sh` — modes par événement (`main`, sorties) | hook / dispatcher | event-driven | `main()` + `sortie_refus` (`planning-hook.sh:2073-2131`, `799-811`) | exact (à décliner) |
| `PC/scripts/planning-hook.sh` — constantes d'armement, `ORDRE_ETAPES`, `armement_valide` | config | transform | `planning-hook.sh:103-110`, `475-490` | exact |
| `PC/scripts/planning-hook.sh` + `poser-verdict.sh` + `recalc-planning.sh` — `livrable_present`, empreinte des livrables | utilitaire partagé (3 copies ast-identiques) | file-I/O, transform | `hash_contenu` + `signature_unite` (`recalc-planning.sh:1147-1190`) ; copies ast-identiques déjà pratiquées (`_jeton_journal`, `lire_frontmatter`) | role-match |
| `PC/scripts/planning-hook.sh` — D1 (liste surveillée, `watchPaths`, journal, réconciliation) | hook / service | event-driven, file-I/O | `observer` + `_jeton_journal` (`planning-hook.sh:827-909`) ; `planning-session-snapshot.sh` (baseline par hash) | partial |
| `PC/scripts/planning-hook.sh` — vérificateur de juges (SessionStart + `--juges`) | service / diagnostic | batch | mode `--classer` + `classer_fichier` (`planning-hook.sh:2027-2038`, `2076-2078`) | role-match |
| `PC/scripts/poser-verdict.sh` — deux empreintes, plafond, dérogation `PLAFOND`, forme d'unité de juge | commande CLI | CRUD (écriture atomique) | lui-même (`poser-verdict.sh:349-442`) + `consommer` du hook (`planning-hook.sh:977-1008`) | exact |
| `PC/scripts/recalc-planning.sh` — R4, empreintes, `à clore`, cache v2 | service de dérivation | transform | lui-même (`recalc-planning.sh:1100-1128`, `1245-1272`) | exact |
| `PC/scripts/deroger-gate.sh` — `GATES` étendu | commande CLI | CRUD (append-only) | lui-même (`deroger-gate.sh:57-62`, `225-226`) | exact |
| `PC/scripts/check-gates-alive.sh` — `COMMANDE_REFERENCE`, `GATES`, `CANARIS`, lecture des 5 événements | canary | request-response | lui-même (`check-gates-alive.sh:152-241`, `332-386`, `465-534`) | exact |
| `PC/scripts/rejeu-gates.sh` / `rejeu-reel.sh` — étapes 5 et 6, constructeurs G3/G4/G4P | outil de mesure | batch, file-I/O | `construire_g1` / `construire_g7` / `construire_role` (`rejeu-gates.sh:709-870`) | exact |
| `PC/hooks/hooks.json` | config (câblage) | event-driven | lui-même (`hooks.json:34-45`) | exact |
| `PC/references/templates/cycles/VERDICT.template.md` | template | — | lui-même (l.1-21) | exact |
| `PC/references/modele-cycles.md` | doc de référence | — | section « Hook central et gates d'écriture (Phase 45) » (l.713-1058) | exact |
| `docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md` (§3.1, §5, §5.1, §10) | spec | — | amendement P45-D-14a (l.169-171) | exact |
| `.planning/workstreams/gouvernance/ROADMAP.md` (note Phase 47, l.236) | planning | — | notes datées de la ROADMAP du compartiment | role-match |
| `PC/VERSION`, `PC/module.json`, `PC/CHANGELOG.md`, `PC/README.md` | config / doc | — | bump v2.9.0 (Phase 45) | exact |
| `README.md`, `README.fr.md` (compteur « N suites ») | doc | — | `scripts/check-version-sync.sh` | exact |
| `docs/HOOKS-CONTRAT-SORTIE.md` (`n==33` → `n==37`) | doc de contrat | — | entrées 32 et 33 (l.191-194) | exact |
| `scripts/tests/test-hook-exit-parc.sh` (exclusions nommées) | test | batch | bloc « Exclusions NOMMÉES » (l.375-388) | role-match |
| **`PC/scripts/tests/test-cloture-empreintes.sh`** (nouveau) | test | request-response + mutation | `test-planning-gates.sh` (sections `verdict`, `lota`, `jeton`) | role-match |
| **`PC/scripts/tests/test-cloture-gates.sh`** (nouveau) | test | request-response + banc + mutation | `test-planning-gates.sh` (sections `g5`, `g1`, `banc`, `mutants`) | role-match |
| **`PC/scripts/tests/test-g4p-sortie-brute.sh`** (nouveau) | test | request-response + mutation | `test-planning-gates.sh` section `role` (R-ROLE-01..13) | role-match |
| **`PC/scripts/tests/test-d1-surveillance.sh`** (nouveau) | test | event-driven | `test-planning-hook-registered.sh` (rejeu de la commande enregistrée) | role-match |
| **`PC/scripts/tests/test-juges-canary.sh`** (nouveau) + fixtures de juges | test | batch | `test-planning-gates.sh` section `verdict` (fixtures par la vraie commande) | role-match |
| **`PC/scripts/tests/fixtures/cloture-banc.txt`** (nouveau, nom libre) | fixture (banc texte) | — | `fixtures/gates-banc.txt`, `fixtures/recalc-planning-banc.txt` | exact |
| `PC/scripts/tests/fixtures/recalc-planning-banc.txt` (l.577 + nouveaux labs) | fixture | — | lui-même | exact |
| `PC/scripts/tests/test-recalc-planning.sh` (R27, MUT-LIVRABLES-CACHE, nouveaux cas) | test | batch | lui-même (l.998-1024, 2282-2297) | exact |
| `PC/scripts/tests/test-planning-gates.sh` (regex d'armement, `TABLE_ATTENDUE`, `GATES_REFERENCE`, R-REFERENCE) | test | — | lui-même (l.146-147, 286, 301, 468, 4603) | exact |
| `PC/scripts/tests/test-planning-hook-registered.sh` (`BASE_EVENEMENTS`, regex d'armement) | test | — | lui-même (l.65-80, 201) | exact |
| `PC/scripts/tests/test-rejeu-gates.sh` (regex l.154, 1203, `ARMES` l.211) | test | — | lui-même | exact |
| `PC/scripts/tests/test-planning-prefilter.sh` (nouveaux événements, matcher) | test | équivalence + mutation | lui-même (sections `table`, `bornes`, `corpus`, `mutants`) | exact |
| `plugin/_internal/tests/test-planning-hook-installed.sh` (4 entrées, matcher élargi) | test | as-installed | lui-même (R-INST-01..08) | exact |
| `46-REJEU-ATTENDUS.txt`, `46-REJEU-ETAPE-5.md`, `46-REJEU-ETAPE-6.md` (artefacts de phase) | doc de mesure | — | `45-REJEU-ATTENDUS.txt`, `45-REJEU-ETAPE-4.md` | exact |
| `SORTIE-PIEGEE.md` (contrat + gabarit de la sortie piégée, sous `PC/references/templates/…`) | template | — | `VERDICT.template.md` | role-match |

## Pattern Assignments

Les assignations suivent le découpage recommandé de `46-RESEARCH.md` (46-01 à 46-09). Le planificateur peut le regrouper ; l'ordre « modèle avant les gates qui le lisent » est imposé par CONTEXT.

---

### Plan 46-01 — Prédicat « livrable présent », empreinte des livrables, `poser-verdict.sh`

#### `PC/scripts/poser-verdict.sh` (commande CLI, CRUD, écriture atomique)

**Analogue :** lui-même, plus les six fonctions de dérogation du hook (`planning-hook.sh:918-1014`) à copier ast-identiques.

**Squelette d'un script du module** (en-tête, résolution de l'interpréteur, heredoc quoté, `Refus(code, message)`) — `poser-verdict.sh:32-75` :
```bash
set -u
PYBIN=python3
case "$(command -v python3 2>/dev/null)" in
  ''|*WindowsApps*)
    if command -v python >/dev/null 2>&1; then PYBIN=python
    else echo "[poser-verdict] python3 ou python requis (ADR-054)" >&2; exit 1; fi ;;
esac
"$PYBIN" -I -S - "$@" <<'PY_POSER_VERDICT_EOF'
...
class Refus(Exception):
    def __init__(self, code, message):
        Exception.__init__(self, message)
        self.code = code
        self.message = message
```
Codes actuels (en-tête l.28-29) : `0` écrit · `1` lecture/écriture · `2` lab non adhérent · `64` usage/tentative/constat/unité. Le plafond ajoute un code distinct (RESEARCH recommande **65**) : à écrire dans l'en-tête, dans `main()` et dans `modele-cycles.md`.

**Contrôle de tentative à étendre pour le plafond** (`poser-verdict.sh:349-354`) :
```python
def controle_tentative(nouvelle, ancienne):
    """1 à la création, ancienne + 1 pour remplacer : sinon refus 64, fichier inchangé (anti-boucle)."""
    attendue = 1 if ancienne is None else ancienne + 1
    if nouvelle != attendue:  # verdict-tentative
        raise Refus(64, "--tentative : %d attendu (%s), reçu %d" % (...))
```
À ajouter ici : `PLAFOND_TENTATIVES = 3` en constante du script (jamais lue d'un fichier du lab) ; `nouvelle > PLAFOND_TENTATIVES` → `Refus(65, …)` message distinct, **sauf** dérogation nominative couvrant l'unité. Poser une balise (`# verdict-plafond`) sur la ligne de refus : c'est elle que le mutant « plafond retiré » ciblera.

**Flux de `poser()` à respecter** (`poser-verdict.sh:396-442`) : validations d'argv → `realpath(unite)` → `racine_lab` + adhésion (code 2) → `forme_unite` → PLAN.md régulier → `ouvrir_verrou(plan)` → hash → lecture de la tentative existante → `controle_tentative` → `lignes_verdict` → `verifier_relecture` → `ecrire_atomique`. La consommation de dérogation et le calcul de l'empreinte des livrables se font **sous le verrou déjà pris** (`# verdict-verrou`, l.424), avant `ecrire_atomique`.

**Pièges de forme à ne pas rater**
- `lignes_verdict` (l.357-368) écrit `juge`, `hash`, `tentative`, `score`, `constats` : y insérer le champ d'empreinte des livrables (nom libre ; RESEARCH recommande `hash_livrables`, admis par `CLE_RE`).
- `verifier_relecture` (l.371-377) compare le dict relu à un dict attendu **fermé** :
```python
    attendu = {"juge": juge, "hash": empreinte, "tentative": str(tentative), "score": score,
               "constats": [{"critere": c, "resultat": r} for c, r in constats]}
    if statut != "ok" or donnees != attendu:
        raise Refus(64, "valeur(s) qui ne se relisent pas identiques (...)")
```
Y ajouter la nouvelle clé, sinon **toute** pose est refusée.
- La prose de `lignes_verdict` l.363-367 dit « le hash (sha256 … PLAN.md) » : la mettre à jour (deux empreintes).

**Seconde forme d'unité (verdict de canary de juge, P46-D-06a)** : `forme_unite` (l.317-329) n'accepte que 5 ou 7 composants `.planning/cycles/<c>/phases/<p>[/plans/<pl>]` et `poser()` exige `PLAN.md` régulier (l.421-423). La forme `.planning/juges/<juge>` (artefact haché = `SORTIE-PIEGEE.md`, pas d'empreinte de livrables) doit être admise **à côté**, sans affaiblir le refus des autres dossiers (jumeau négatif obligatoire : `.planning/juges/../autre` et `.planning/autre/x` restent refusés). Balise sur la ligne de forme comme l'existante : `# verdict-forme-unite` (l.420, déjà ciblée par le mutant `VERDICT-FORME-UNITE`).

**Dérogation côté commande** : copier ast-identiques, depuis `planning-hook.sh`, `NOM_JOURNAL_DEROGATIONS`, `LIGNE_DEROGATION_RE`, `_chemin_journal_derogations`, `_ouvrir_journal_derogations`, `_entrees_journal`, `_derogation_non_consommee`, `derogation_active`, `consommer`, `citer`, `_jeton_journal` (`planning-hook.sh:827-1014`). Cœur de `consommer` à reproduire tel quel (verrou, relecture sous verrou, ajout `consommee`) — `planning-hook.sh:977-1008` :
```python
def consommer(racine, entree):
    try:
        descripteur = _ouvrir_journal_derogations(racine, os.O_RDWR | os.O_APPEND)
        if descripteur is None:
            return False
        try:
            if fcntl is not None:
                fcntl.flock(descripteur, fcntl.LOCK_EX)
            os.lseek(descripteur, 0, os.SEEK_SET)
            ...
            restante = _derogation_non_consommee(_entrees_journal(existant), entree["gate"], entree["chemin"])
            if restante is None or restante["id"] != entree["id"]:
                return False
            ligne = "{}  consommee  id={}  gate={}  chemin={}\n".format(horodatage, entree["id"], entree["gate"], _jeton_journal(entree["chemin"], "-"))
```
Jeton du gate : recommandation `PLAFOND` ; `chemin` = chemin relatif de l'unité. Ordre : refuser si pas de dérogation → consommer → écrire (si l'écriture échoue après consommation, la dérogation est perdue : fail-closed visible au journal).

**Messages d'erreur** : sortie sur stderr préfixée `[poser-verdict] `, jamais de chemin absolu hors du lab, jamais `no such file` / `can't open` (P46-D-10, #60490) — vérifier `main()` (l.445-460) : le `except OSError` imprime `str(exc)`, qui contient le chemin absolu et `No such file or directory` : **à neutraliser** pour les nouveaux chemins de code qui lisent les livrables.

---

#### `PC/scripts/deroger-gate.sh` (commande CLI, CRUD append-only)

**Analogue :** lui-même. Deux lignes à changer, un test qui les compare.
`deroger-gate.sh:57` : `GATES = ("G1", "G5", "G6", "G7", "ROLE")` → ajouter `G3`, `G4`, `G4P`, `PLAFOND`.
`deroger-gate.sh:61` (`USAGE`) et `:226` (`raise Refus(64, "--gate : G1, G5, G6, G7 ou ROLE attendu, reçu : " + …)`) citent la liste en toutes lettres : les trois endroits ensemble, plus l'en-tête l.7.
```python
def valider(valeurs, chemins_bruts):
    if valeurs["gate"] not in GATES:
        raise Refus(64, "--gate : G1, G5, G6, G7 ou ROLE attendu, reçu : " + valeurs["gate"])
```
Le chemin d'une dérogation G3/G4 est celui du fichier écrit (`.planning/cycles/…/SUMMARY.md`) tel que `decider` le passe à `derogation_active` (`planning-hook.sh:1030`) ; pour G4′ la recherche propose `agents/<agent_type>`.

---

#### Prédicat « livrable présent » + empreinte des livrables (code partagé, trois copies ast-identiques)

**Analogue :** pas de module partagé possible (« l'installeur ne pose que `*.sh` », `recalc-planning.sh:23-26`) ; le patron en vigueur est la **copie ast-identique + test de comparaison d'arbres**. Précédents : `_jeton_journal` (hook l.827-874 = recalc = deroger-gate l.130-177), `lire_frontmatter` / `dequote` / `CLE_RE` / `_lire_liste_indentee`, `lire_registre`, `est_fichier_regulier`, `verifier_adhesion`, `racine_lab`.

**Briques à réutiliser** (déjà dans le code, ne pas réécrire) :
- Lecture sans suivi de lien — `recalc-planning.sh:1147-1167` :
```python
def hash_contenu(chemin):
    if not est_fichier_regulier(chemin):
        return None
    try:
        descripteur = os.open(chemin, os.O_RDONLY | SANS_SUIVI_DE_LIEN)
    except OSError:
        return None
    hacheur = hashlib.sha256()
    try:
        with os.fdopen(descripteur, "rb") as fh:
            while True:
                bloc = fh.read(65536)
                if not bloc:
                    break
                hacheur.update(bloc)
    except OSError:
        return None
    return hacheur.hexdigest()
```
- Texte canonique trié puis haché — `recalc-planning.sh:1170-1190` (`signature_unite` : lignes `"fichier\t" + nom + "\t" + h`, `"\n".join`, `hashlib.sha256(texte.encode("utf-8"))`).
- Forme d'une entrée `ecrit:` valide — `entree_ecrit_valide` (`planning-hook.sh:650-666`, identique dans `deroger-gate.sh:111-127` et recalc).
- Entrées `ecrit:` d'un PLAN.md (scalaire ou liste) — `_valeurs_ecrit` + `_lire_ecrit_reel` (`recalc-planning.sh:1193-1203`).

**À écrire (aucun analogue)** : `lstat` composant par composant (tout lien = absent), « vide » = fichier de 0 octet ou dossier sans fichier régulier non vide, parcours borné fichiers + octets avec refus explicite au dépassement (jamais d'empreinte partielle). Esquisse de départ dans `46-RESEARCH.md` Pattern 1 (l.192-206). Bornes recommandées : 2000 fichiers, 128 MiB (mesurées, `46-RESEARCH.md` Pattern 2). Exclusions fixes `.DS_Store`, `Thumbs.db`, `desktop.ini` : décision renversable à annoncer.

**Test d'ast-identité à écrire** : copier `_arbre_fonction` + `controle_jeton` (`test-planning-gates.sh:900-914`) :
```python
def _arbre_fonction(corps, nom):
    for noeud in ast.parse(corps).body:
        if isinstance(noeud, ast.FunctionDef) and noeud.name == nom:
            return ast.dump(noeud)
    return None

def controle_jeton(ctx, script):
    chemin = script if script.endswith(".sh") else os.path.join(script, "planning-hook.sh")
    a_h = _arbre_fonction(corps_python(open(chemin, encoding="utf-8").read()), "_jeton_journal")
    a_r = _arbre_fonction(corps_python(open(ctx.recalc, encoding="utf-8").read(), "PY_RECALC_PLANNING_EOF"), "_jeton_journal")
    ...
    if a_h != a_r:
        return False, "arbres différents"
    return True, "arbres ast identiques (docstring comprise)"
```
Étendre aux **trois** marqueurs de heredoc : `PY_PLANNING_HOOK_EOF`, `PY_POSER_VERDICT_EOF`, `PY_RECALC_PLANNING_EOF` ; une constante (borne) est une `ast.Assign` à comparer comme `CLE_RE` dans `_arbres_parseur` (l.643-649). Preuve croisée « un seul prédicat » : même verdict de présence rendu par le hook (G3) et par `recalc-planning.sh --read-only` (R4) sur un lot de fixtures (fichier absent, vide, lien, dossier vide, dossier non vide).

---

### Plan 46-02 — Recalcul : R4, empreintes, `à clore`, cache v2

#### `PC/scripts/recalc-planning.sh` (service de dérivation, transform)

**Analogue :** lui-même. Points de contact exhaustifs (déjà relevés par RESEARCH, confirmés ligne à ligne) :

| Lieu | Ligne | Changement |
|---|---|---|
| `CACHE_SCHEMA_VERSION = 1` | l.82 | `2` (cache ancien = `autre-format` = recalcul complet, `charger_cache` l.1230) |
| `ETATS_TOUS` | l.104-107 | + `"à clore"` ; `TERMINAUX` (l.102) **ne change pas** (non terminal) |
| `LIBELLES["verdict-passe-sans-SUMMARY.md"]` | l.119 | entrée devenue morte : la retirer ; ajouter les libellés de `verdict-perime` et `livrable-modifie-apres-cloture` |
| `NOMS_MODELE_RACINE_FICHIERS` / `_DOSSIERS` | l.758-766 | + journal de D1 (`surveillance.log`) et dossier `juges` |
| R4 | l.1100-1103 | `os.path.lexists` → prédicat « livrable présent » |
| R6-R8 | l.1109-1128 | insérer empreintes entre R6 et R7 ; R8 sans SUMMARY → `("à clore", None, meta)` |
| `_meta_unite` | l.1020-1033 | lit déjà `hash` ; lire aussi l'empreinte des livrables |
| `_deriver_feuille_cache` | l.1245-1272 | exiger l'égalité de l'empreinte composée (recalculée à chaque passage) |

**R4 actuel** (à remplacer) — `recalc-planning.sh:1100-1103` :
```python
    # R4
    manquant = next((v for v in valeurs if not os.path.lexists(os.path.join(racine_lab, v))), None)
    if manquant is not None:
        return ("indéterminé", "livrable-absent:" + manquant, meta)
```
**Insertion des empreintes et de `à clore`** — remplacer le bloc R7/R8 (l.1118-1128) en gardant la forme du retour `(état, raison, meta)` :
```python
    # R7
    if any(c.get("resultat") == "échec" for c in constats):
        if summary_present:
            return ("indéterminé", "SUMMARY.md-avec-verdict-en-echec", meta)
        return ("à corriger", None, meta)
    # R8
    if summary_present:
        meta2 = dict(meta)
        meta2["type_derivation"] = "feuille"
        return ("close", None, meta2)
    return ("indéterminé", "verdict-passe-sans-SUMMARY.md", meta)   # → ("à clore", None, meta)
```
Ordre recommandé (RESEARCH Pattern 4) : R6 valide → empreintes (écart ou clé absente : SUMMARY absent → `("à juger", "verdict-perime", meta)` ; SUMMARY présent → `("indéterminé", "livrable-modifie-apres-cloture", meta)`) → R7 → R8. Les raisons sont des codes en kebab-case sans espace, comme celles existantes (`livrable-absent:<entrée>`, `verdict-invalide`).

**Cache — le piège** : `_deriver_feuille_cache` ne compare que l'**existence** des livrables (l.1259-1260) :
```python
        livrables_actuels = {v: os.path.lexists(os.path.join(racine_lab, v)) for v in ecrit_cache}
        if livrables_actuels == livrables_cache:
```
Sans changement, un `close` en cache survit à la réécriture d'un livrable. Stocker l'empreinte composée dans l'entrée (`cache_ctx["nouveau"][chemin_rel] = {...}`, l.1267-1270) et exiger son égalité. Le mutant `LIVRABLES-CACHE` de `test-recalc-planning.sh` cible la **chaîne exacte** `if livrables_actuels == livrables_cache:` : si la ligne change, le mutant devient non opposable → le réécrire dans le même plan.

**Rendu** : `_texte_etat_cycle` n'affiche la raison que pour `indéterminé` (`recalc-planning.sh:1614-1617`) ; décider d'un libellé pour `à juger (verdict-perime)` (RESEARCH : oui, une ligne).

**Aucun lien suivi / aucune fuite de chemin** : le moteur lit en `O_NOFOLLOW`/`lstat` partout (`est_fichier_regulier`, `hash_contenu`) ; la nouvelle lecture des livrables suit la même règle.

#### `PC/references/templates/cycles/VERDICT.template.md`
**Analogue :** lui-même. Ajouter la clé d'empreinte des livrables au frontmatter (l.2-9), et réécrire la prose l.19-21 (« lus et restitués, jamais vérifiés … relève de la Phase 46 » → vérifiés) et la mention de `à clore`.

#### `PC/scripts/tests/fixtures/recalc-planning-banc.txt` + `test-recalc-planning.sh`
**Analogue :** les labs `etat-a-corriger-jumeau` (l.535-578) et `etat-close` (l.580+).
- Changer l'attendu l.577 : `@@ attendu cycles/01-c/phases/01-p :: indéterminé :: verdict-passe-sans-SUMMARY.md` → `à clore` (état sans raison) ; l.578 l'attendu d'agrégat suit (`à clore` est non terminal : l'agrégat du cycle n'est plus `indéterminé :: phase-indeterminee:01-p`).
- Format d'un lab du banc (à copier pour chaque nouveau cas, avec son **jumeau négatif** `jumeau-de=`) :
```
@@ lab etat-a-corriger-jumeau jumeau-de=etat-a-corriger

@@ fichier .planning/config.json
{"planning_version": "cycles-v1"}
@@ fichier .planning/cycles/01-c/phases/01-p/PLAN.md
---
ecrit: livrables/rapport.md
---
...
@@ fichier livrables/rapport.md
Livrable de etat-a-corriger-jumeau.

@@ attendu cycles/01-c/phases/01-p :: indéterminé :: verdict-passe-sans-SUMMARY.md
```
- Les livrables du banc doivent rester **non vides** (R4 passe à « absent ou vide » : 0 fichier vide dans ce banc aujourd'hui, `46-RESEARCH.md` Pitfall 3) ; refaire l'inventaire des `ecrit:` par grep dans `test-recalc-planning.sh`, `test-planning-gates.sh`, `test-rejeu-gates.sh` avant de toucher R4.
- `test-recalc-planning.sh` R27 (l.998-1024) assertionne le libellé « verdict passé, SUMMARY absent » dans `INDEX.md` et `STATE.md` : à réécrire pour le libellé de `à clore`.

---

### Plan 46-03 — Hook : modes par événement, G3, G4, constantes d'armement, commande unique

#### `PC/scripts/planning-hook.sh` — `evaluer_g3` / `evaluer_g4` (gate, request-response)

**Analogue :** `evaluer_g1` + `unite_de_plan` (`planning-hook.sh:1281-1339`), et `evaluer_g5` (l.1047-1064) pour la résolution physique et la casse.

**Généraliser `unite_de_plan`** (aujourd'hui figé sur `plan.md`, 6 ou 8 composants) à un nom de fichier paramétré (`CLOTURE.md`, `SUMMARY.md`) — l.1281-1295 :
```python
def unite_de_plan(composants):
    n = len(composants)
    if n not in (6, 8) or composants[-1].casefold() != "plan.md":
        return None
    if composants[0].casefold() != ".planning" or composants[1].casefold() != "cycles" or composants[3].casefold() != "phases":
        return None
    if n == 8 and composants[5].casefold() != "plans":
        return None
    unites = [composants[2], composants[4]] + ([composants[6]] if n == 8 else [])
    if not all(NOM_UNITE.match(u) for u in unites):
        return None
    return composants[:5]  # g1-phase
```
Pour G3/G4 l'unité jugée est le **dossier de l'unité** (5 ou 7 composants + nom de fichier), pas la phase : ne pas réutiliser le `return composants[:5]` de G1 (sous `plans/<plan>/`, G1 juge la phase ; G3/G4 jugent le plan). Même forme que `forme_unite` de `poser-verdict.sh:317-329`, qu'un contrôle croisé doit aligner (revue m3).

**Squelette d'un gate** (signature, périmètre d'outil, résolution physique, `Verdict`, bords « jamais refuser un état illisible » vs refus fail-closed) — `evaluer_g1`, l.1308-1339 :
```python
def evaluer_g1(contexte):
    if contexte["outil"] not in ("Write", "Edit") or not contexte["ecrit"]:
        return []
    racine = contexte["racine"]
    rel = os.path.relpath(os.path.realpath(contexte["ecrit"]), racine)
    composants = [c for c in rel.split(os.sep) if c not in ("", ".")]
    dossier_phase = unite_de_plan(composants)  # g1-forme
    if dossier_phase is None:
        return []
    chemin_rel = "/".join(composants)
    ...
    if not os.path.lexists(cadrage):  # g1-cadrage
        return [Verdict("G1", chemin_rel, "la phase %s n'a pas de CADRAGE.md — cadrez avant de planifier (spec §5)" % phase)]
```
G3/G4 doivent couvrir `("Write", "Edit", "NotebookEdit")` = `OUTILS_ECRITURE` (P46-D-01), comme `evaluer_g5` (l.1055 `contexte["outil"] not in OUTILS_ECRITURE`). **Différence assumée avec G1** : G1 se tait sur un état que le modèle ne sait pas lire (F5, l.1325-1337) ; G3/G4 sont fail-closed (P46-D-10) : `VERDICT.md` absent/invalide/échec/périmé = refus. Choix « `PLAN.md` absent ou illisible » : refuser (Open Question 1 de RESEARCH, à annoncer), mesuré au rejeu comme « refus conforme au modèle ».

**Lecture des voisins** : `lire_frontmatter_fichier` (l.607-618, O_NOFOLLOW, UTF-8 strict) ; entrées `ecrit:` valides par `entree_ecrit_valide` (l.650-666) ; contrôle des constats = règle R6 de `recalc-planning.sh:1113-1117` :
```python
    constats = verdict_donnees.get("constats")
    if not isinstance(constats, list) or len(constats) == 0 or any(
        not isinstance(c, dict) or c.get("resultat") not in ("passé", "échec") for c in constats
    ):
```
Message de refus G4 sur écart : « verdict périmé : re-juger (tentative n+1) » avec n lu dans le verdict (P46-D-03). Chemins **relatifs au lab** uniquement ; jamais `no such file` / `can't open`.

**Enregistrement dans l'entonnoir** — `planning-hook.sh:2043` :
```python
GATES_A_VERDICT = (("G6", evaluer_g6), ("G5", evaluer_g5), ("G1", evaluer_g1), ("G7", evaluer_g7), ("ROLE", evaluer_role))  # gates-a-verdict
```
→ ajouter `("G3", evaluer_g3), ("G4", evaluer_g4), ("G4P", evaluer_g4p)`. `evaluer_protege` (l.2046-2050) fournit gratuitement l'erreur interne fail-closed (`Verdict(gate, None, "erreur interne du gate : " + type(exc).__name__)`), `decider` (l.1017-1044) l'armement, l'observation et la dérogation nominative.

**Balises de mutant** : chaque garde porte un commentaire de fin de ligne unique (`# g3-vide`, `# g3-lien`, `# g4-hash`, `# g4-hash-livrables`, `# g4-echec`, `# g4-verdict-absent`…) : c'est ce que `make_script_mutant` remplace (une seule ligne, motif fixe). Voir « Gabarit de suite » plus bas.

---

#### `PC/scripts/planning-hook.sh` — constantes d'armement, `ORDRE_ETAPES`, `armement_valide`

**Analogue :** lui-même, l.99-110 et 475-490.
```python
ARMEMENT_G6 = "armed"  # etape-1
...
ARMEMENT_ROLE = "armed"  # etape-4
G2_MODE = "avertit"
ORDRE_ETAPES = (("G6", "G5"), ("G1",), ("G7",), ("ROLE",))
TABLE_ARMEMENT = {"G6": ARMEMENT_G6, "G5": ARMEMENT_G5, "G1": ARMEMENT_G1, "G7": ARMEMENT_G7, "ROLE": ARMEMENT_ROLE}
```
Ajouter **une ligne par constante** (`ARMEMENT_G3 = "observe"  # etape-5`, `ARMEMENT_G4 = "observe"  # etape-5`, `ARMEMENT_G4P = "observe"  # etape-6`), `ORDRE_ETAPES += (("G3", "G4"), ("G4P",))`, `TABLE_ARMEMENT`. Chaque constante sur sa propre ligne, format exact `^ARMEMENT_<gate> = "…"` : le canary la relit par regex (`check-gates-alive.sh:475`), le rejeu et les mutants la réécrivent. `armement_valide` (l.475-490) n'impose l'égalité `G6 == G5` qu'à ce couple (l.482) : l'imposer aussi à `G3 == G4` (même étape, un seul geste) et mettre à jour le message de `evaluer_gates` (l.2060-2061, « l'ordre des étapes (G6 et G5, puis G1, puis G7, puis le rôle) »).

**Les cinq lieux de copie à étendre AVANT le premier armement, dans le commit qui ajoute les constantes** (sinon la copie « découplée » force G6…ROLE à `observe` et laisse G3/G4/G4P à `armed` → table incohérente → tout refusé → toutes les suites rouges) :
- `planning-hook.sh:103-110` (ci-dessus) ;
- `check-gates-alive.sh:181` `GATES = ("G6", "G5", "G1", "G7", "ROLE")` ; `lire_canaris` (l.502) n'accepte que `("DEGRADE",) + GATES` ; `lire_armement` (l.474-478) lève `Indetermine` si une ligne manque ;
- `rejeu-gates.sh:126-127` `GATES` et `ORDRE_ETAPES`, `ETAPE_DE` (l.128), `CONSTRUCTEURS` (l.871), `--etape` validé `("1","2","3","4")` (l.1087) ; `rejeu-reel.sh:11` et `:212` ;
- `deroger-gate.sh:57` ;
- les **suites** à regex en dur `ARMEMENT_(?:G6|G5|G1|G7|ROLE)` : `test-planning-gates.sh:286` (`copie_forcee`, avec `if n != 5` l.287-288), `:301` (`copie_armee`), `:468` (`observe_partout`) ; `test-planning-hook-registered.sh:201` (avec `n != 5`) ; `test-rejeu-gates.sh:154`, `:1203` ; `TABLE_ATTENDUE` et `ORDRE_ATTENDU` (`test-planning-gates.sh:146-147`), `controle_table_02` (tables à 5 arguments `T(g6, g5, g1, g7, role)`), `GATES_REFERENCE` (l.4603), `canaris_par_gate` (l.4662-4664), `ARMES` (`test-rejeu-gates.sh:211`).
Piste de réduction du couplage : centraliser la liste dans une aide de suite plutôt que d'éditer huit regex.

---

#### `PC/scripts/planning-hook.sh` — modes par événement (`main`, sorties) (event-driven)

**Analogue :** `main()` (l.2073-2131) et `sortie_refus`/`sortie_contexte` (l.799-811). Le script **ne lit jamais** `hook_event_name` aujourd'hui.

**Point d'insertion** : après `lire_payload` (l.2082) et **avant** `cible_de` (l.2091), qui ne lit que `tool_input.file_path|notebook_path` (l.196-217) et suppose un appel d'outil. Un `FileChanged` porte `file_path` et `event` **au premier niveau** (pas dans `tool_input`) : la racine du lab se dérive de ce `file_path` ; `CwdChanged` porte `old_cwd`/`new_cwd` en plus de `cwd` ; un `SubagentHandback` n'a pas de `file_path` (`ecrit is None` → `depart = cwd`, l.2092, fonctionne tel quel).

**Squelette de `main()` à décliner** (phase A silencieuse, phase B fail-closed) — l.2081-2131 :
```python
    try:
        payload = lire_payload(sys.argv[1])  # phase-a
    except BaseException:
        sys.exit(3)  # phase-a-sortie
    try:
        ecrit, cwd, variantes = cible_de(payload, sys.argv[3] if len(sys.argv) > 3 else "")
        depart = ecrit if ecrit is not None else (cwd if cwd is not None else os.getcwd())  # racine-depart
        racine = racine_lab(depart)
        adherent = racine is not None and verifier_adhesion(os.path.join(racine, ".planning"))["adherente"]
        ...
    if not adherent and not autres:
        sys.exit(0)  # non-adherent
    # Phase B : le lab est adhérent. Toute erreur devient un refus explicite, code 0 (P45-D-08).
    try:
        ...
        if refus:
            sortie_refus(refus)
        elif avis:
            sortie_contexte(avis)
    except BaseException as exc:
        sortie_refus(["[planning-core] erreur interne du hook central dans un lab adhérent "
                      "cycles-v1 : action refusée (P45-D-08) — " + type(exc).__name__])
    sys.exit(0)
```
**Contrat par événement (P46-D-10)** : `PreToolUse` deny JSON exit 0 (inchangé) ; `SubagentStop` `{"decision":"block","reason":…}` exit 0, **jamais exit 2** ; `SessionStart`/`CwdChanged`/`FileChanged` ne refusent jamais (fail-open déclaré pour D1, y compris `except BaseException` → silence, pas de `sortie_refus`). La branche `except` de la phase B ne doit donc plus appeler `sortie_refus` pour D1.

**Sorties à paramétrer** (aujourd'hui `hookEventName` codé en dur) — l.799-811 :
```python
def sortie_refus(raisons):
    _emettre({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": "\n".join(raisons),
    }})
```
Ajouter `sortie_bloc` (SubagentStop) et `sortie_watch` (SessionStart/CwdChanged) en passant par `_emettre` (qui appelle `figer_echeance()`, l.792-796) ; ne jamais écrire sur stdout autrement.

**Échéance et codes du lanceur** : inchangés (`ECHEANCE_COEUR_S = 8.0`, `CODE_ECHEANCE = 73`, l.95-97) ; tout nouveau calcul (empreinte, réconciliation) reste borné bien en deçà.

**Diagnostic** : le mode `--classer` (4e argument, l.2076-2078, `classer_fichier` l.2027-2038) est le patron d'un mode « diagnostic » (`--juges`) : une ligne JSON, code 0, sans lire stdin.

---

#### `PC/hooks/hooks.json` + commande enregistrée (config, event-driven)

**Analogue :** lui-même. Contraintes d'installeur (`merge-hooks.sh:498-516`, boucle « Idempotence » : retire toute entrée qui cite le même script dans **tous les groupes du même événement**) :
- `SubagentHandback` entre **dans le matcher existant** `"Write|Edit|NotebookEdit|Bash|Agent|Task"` (`hooks.json:36`) → `"…|Task|SubagentHandback"` ; **jamais** un second groupe `PreToolUse`.
- `SubagentStop`, `CwdChanged`, `FileChanged` : une entrée chacune, **matcher omis** ; `SessionStart` : un groupe sans matcher (se réunit au groupe sans matcher existant, l.14-18, sans conflit : scripts différents).
- Forme shell inline, **jamais** `{{VF_BASH}}` (la forme exec part dans `settings.local.json`). Même `timeout: 20` (`hooks.json:41`).
- **Même texte de commande** sous les cinq événements (comparé octet pour octet par six suites) avec une queue de repli sensible à l'événement.

**Queue de repli à adapter** (`hooks.json:40`, fin de la chaîne ; copie lisible dans `COMMANDE_REFERENCE`, `check-gates-alive.sh:162-180`) :
```sh
vf_pre && exit 0
if [ -f "$S" ]; then O=$(printf '%s' "$I" | bash "$S"); R=$?; fi
if [ "$R" -eq 0 ]; then [ -z "$O" ] || printf '%s\n' "$O"; exit 0; fi
case $I in *'"tool_name":"Write"'*|*'"tool_name":"Edit"'*|*'"tool_name":"NotebookEdit"'*|*'"tool_name":"Agent"'*|*'"tool_name":"Task"'*) ;; *) exit 0 ;; esac
```
→ ajouter `*'"tool_name":"SubagentHandback"'*` au `case` (sinon `R-REFERENCE` l'affiche « laissé ouvert », `test-planning-gates.sh:4685-4689` `outils_commande`). Tout autre événement : `exit 0` (fail-open déclaré, `SubagentStop` en mode dégradé compris : le shell ne dérive pas le rôle). Le pré-filtre `vf_pre` greppe `"(file_path|notebook_path|cwd)"` (`hooks.json:40`) : il ne capte pas `new_cwd` (guillemet ouvrant devant `new_`) — à prouver par la suite de pré-filtre.

**Cinq copies du texte de la commande à garder synchrones** : `hooks.json:40`, `COMMANDE_REFERENCE` (`check-gates-alive.sh:152-180`), et les suites qui la comparent (`test-planning-hook-registered.sh`, `test-planning-prefilter.sh`, `test-planning-gates.sh`, `test-planning-hook-installed.sh`, `test-rejeu-gates.sh`). Le `description` de `hooks.json` (l.2) est à mettre à jour.

---

### Plan 46-04 — G4′ : rapport de sous-agent sans sortie brute

#### `PC/scripts/planning-hook.sh` — `evaluer_g4p` (gate, request-response)

**Analogue :** `evaluer_role` (`planning-hook.sh:1989-2024`) pour l'identité du sous-agent et le périmètre par rôle.

**Identité et rôle à reprendre tels quels** (l.2003-2008) :
```python
    payload = contexte["payload"]
    agent_id, agent_type = payload.get("agent_id"), payload.get("agent_type")
    avec_identite = isinstance(agent_id, str) and agent_id != "" and isinstance(agent_type, str) and agent_type != ""
    signaux = []
    role, definition = resoudre_agent(agent_type, racine, contexte.get("arg_home"), signaux) if avec_identite else ("inconnu", None)  # role-principal
    for signal in signaux:  # role-signal : un budget d'indexation épuisé ne se tait jamais (lot C, N1)
        observer(Verdict("ROLE", None, signal), contexte)
```
G4′ refuse **seulement** `worker`/`producteur` (rôle dérivé par `deriver_role`, l.1694-1711) ; jamais `juge`, `manager`, `inconnu`, `illisible`, ni fil principal, ni `agent_type` vide. **Risque majeur** (RESEARCH Pattern 6) : « producteur » = tout agent résolu qui n'est ni juge, ni manager, ni `vf-internal`, y compris un agent sans `Bash` → boucle de refus. Limiter G4′ aux agents capables d'exécuter une commande, via `jetons_nus_agent(lignes, "tools"|"disallowedTools")` (`planning-hook.sh:1682-1691`) ; hypothèse non vérifiée A8 (un agent sans `tools:` hérite de `Bash`).

**Où lire le rapport** : `payload["tool_input"]["message"]` (chaîne uniquement ; tout autre type = aucune preuve), `outil == "SubagentHandback"` (P46-D-02). Repli `SubagentStop` : `last_assistant_message` **seulement** quand `permission_mode != "auto"` (en mode auto le rapport a déjà passé le `PreToolUse` ; garde à tester avec payloads des deux modes). Sortie `SubagentStop` : `{"decision":"block","reason":…}` exit 0.

**Grammaire de la sortie brute** (aucun analogue dans le code : écrite par la phase, pas plus permissive que P46-D-02a) : parcours **linéaire** ligne à ligne, pas de regex à retour arrière, bloc fermé par une ligne de même caractère (```` ``` ``` ou `~~~`, longueur ≥ 3) ; première ligne non vide = `^\$ \S` ; la ligne non vide suivante est de la sortie (ni fermeture, ni `$ `). Jumeaux négatifs obligatoires : bloc sans commande, commande sans sortie, bloc non fermé, `$` sans espace, sortie hors du bloc, commande en deuxième ligne (liste de `46-RESEARCH.md` Pattern 6).

**Dérogation nominative** : `gate=G4P`, chemin `agents/<agent_type>`, usage unique (`derogation_active` / `consommer`).

**Message de refus** : doit dire que le rapport est refusé faute de sortie de commande brute et comment lever (rejouer une commande et coller sa sortie dans un bloc) ; en mode dégradé de la commande enregistrée, message « hook indisponible, réparer » (sinon le sous-agent boucle).

#### `PC/scripts/tests/test-g4p-sortie-brute.sh` (nouveau)
**Analogue :** section `role` de `test-planning-gates.sh` (`R-ROLE-01..13`, l.3070-3088) : fabrique de définitions d'agents dans un lab jetable (`.claude/agents/*.md`), payload avec `agent_id`/`agent_type`, copie observe puis armed (`ctx.copie_forcee`, l.280-296), journal d'observation compté (`lignes_journal`, l.768-772), lab dev silencieux (jumeau `-dev`). Voir « Gabarit de suite ».

---

### Plan 46-05 — Canary de juge (C-16)

#### `PC/scripts/planning-hook.sh` — vérificateur (mode `SessionStart` + `--juges`) (batch)
**Analogue :** mode `--classer` (diagnostic) + `resoudre_agent`/`deriver_role` (l.1950-1974, 1694-1711) pour lister les juges d'un lab ; sortie du signal : une ligne agrégée préfixée `[planning-core] …` (patron de `signaler` du canary, `check-gates-alive.sh:248-250`, préfixe l.147 `PREFIXE = "[planning-core] canary : "`) :
```python
def signaler(texte):
    sys.stdout.write(PREFIXE + texte + "\n")
    sys.stdout.flush()
```
Pour le hook, la sortie `SessionStart` suit le contrat de P46-D-10 (JSON `hookSpecificOutput`, ne bloque jamais). Contrat (RESEARCH Pattern 9) : pour chaque juge — pas de dossier/sortie piégée, ou verdict absent, ou `hash` ne correspondant plus à la sortie piégée → « juge sans preuve » ; critère visé non en `échec` → « juge laxiste » ; **jamais vert** quand le lab n'a aucun dossier (cas de tous les labs existants : une ligne agrégée, comptes et premiers noms, pour ne pas noyer le `SessionStart`).

**Emplacement** : `.planning/juges/<juge>/{SORTIE-PIEGEE.md, VERDICT.md}` (`juges` à ajouter à `NOMS_MODELE_RACINE_DOSSIERS`, `recalc-planning.sh:758`, sinon « Hors modèle » dans `INDEX.md` ; G5 protège déjà tout `VERDICT.md` sous `.planning/`, `planning-hook.sh:1060`). Ne pas loger les juges dans un cycle réel (le recalcul les dériverait).

**Gabarit de la sortie piégée** : `references/templates/…/SORTIE-PIEGEE.template.md`, forme du `VERDICT.template.md` (frontmatter `juge`, `critere_vise`, provenance de l'exemple raté + prose).

#### `PC/scripts/tests/test-juges-canary.sh` (nouveau) + fixtures de juges
**Analogue :** `lab_frais` + `poser` + `lancer_script` (`test-planning-gates.sh:971-993`) : les quatre états (sortie piégée, juge prouvé, juge laxiste, juge sans preuve) sont construits **par la vraie `poser-verdict.sh`**, jamais par un hash écrit à la main :
```python
def poser(ctx, dossier, lab, tentative, juge="vf-design-judge", score="8/10", constats=("critere-a::passé",), unite=UNITE, extra=()):
    args = ["--unite=" + os.path.join(lab, unite), "--juge=" + juge, "--tentative=" + str(tentative), "--score=" + score]
    args += ["--constat=" + c for c in constats] + list(extra)
    return lancer_script(ctx, dossier, "poser-verdict.sh", args)
```

---

### Plan 46-06 — D1 : surveillance, journal, réconciliation

#### `PC/scripts/planning-hook.sh` — D1 (event-driven, file-I/O)
**Analogues partiels :**
- Journal append-only encodé : `observer` (`planning-hook.sh:890-909`) — ajout seul, `O_NOFOLLOW`, dossier/fichier en 0700/0600, **toute erreur = aucune ligne, jamais une exception** :
```python
        descripteur = os.open(chemin, os.O_WRONLY | os.O_APPEND | os.O_CREAT | SANS_SUIVI_DE_LIEN, 0o600)
        try:
            if hasattr(os, "fchmod"):
                os.fchmod(descripteur, 0o600)
            os.write(descripteur, ligne.encode("utf-8"))
        finally:
            os.close(descripteur)
    except Exception:
        return
```
  Lignes encodées par `_jeton_journal` (copie ast-identique, jamais d'injection de ligne) ; format de ligne à deux espaces `<horodatage>  clé=valeur …` comme `observer` (l.900) et le journal de dérogation (`planning-hook.sh:912-919`).
- Réconciliation par hash au démarrage : patron `planning-session-snapshot.sh` (baseline hashée « first-wins », rotation, fail-open `exit 0` silencieux, l.1-75) et `hash_contenu` (`recalc-planning.sh:1147`).
- Journal sous `.planning/`, fichier enfant direct, protégé G6 : copier le traitement de `derogations-gates.log` — `NOMS_MODELE_RACINE_FICHIERS` (`recalc-planning.sh:760-766`), `PROTEGES_G6` (`planning-hook.sh:1110-1114`), ligne R-REFERENCE « Noms protégés par G6 » (`modele-cycles.md` ligne « **Noms protégés par G6** : `STATE.md`, `INDEX.md`, `cloture.log`, `.recalc-cache.json`, `derogations-gates.log`, `config.json`. »), `raison_g6`. **Ne jamais surveiller ce journal** ni le faire écrire par un fichier surveillé (boucle infinie citée par la doc).
- Écrivains du moteur qui inscrivent ce qu'ils écrivent (« écriture expliquée ») : `recalc-planning.sh`, `poser-verdict.sh`, `deroger-gate.sh` (ajout d'une ligne après leur écriture) ; le hook inscrit l'intention à chaque `PreToolUse` laissé passer sur un chemin surveillé.

**Aucun analogue** : forme de `watchPaths` de `CwdChanged`/`FileChanged` (non montrée par la doc ; émettre les deux formes et la déclarer non mesurée, P46-D-08), liste surveillée fichier par fichier bornée (128 recommandé), mesure du coût par événement.

**Piège de lint** : `check-planning-consumers-registered.sh` (`plugin/conductor/scripts/`) signale tout `*.sh` hors `tests/` portant `.planning/workstreams`, ou `.planning/` suivi de `STATE.md`/`ROADMAP.md`/`REQUIREMENTS.md` **sur la même ligne** (commentaires compris). Composer ces noms par variables — précédent `NOM_ETAT = "STATE.md"` (`check-gates-alive.sh:193`, utilisé en concaténation l.225 : `"G6-principal|G6|nominal|Write:.planning/" + NOM_ETAT + "|fil-principal"`) — ou inscrire le script au recensement.

#### `PC/scripts/tests/test-d1-surveillance.sh` (nouveau)
**Analogue :** `test-planning-hook-registered.sh` (rejeu de la commande enregistrée sous `/bin/sh -c`, payloads par événement). Assertions : `watchPaths` fichier par fichier et bornés (jamais un dossier, #91634), hors adhésion **aucun** `watchPaths` et stdout d'octet vide, trace d'une écriture non expliquée, jamais de refus, journal non surveillé ; mutation `watchPaths` renvoyé hors adhésion.

---

### Plan 46-07 — Mesure du coût du pré-filtre, zéro régression labs dev

#### `PC/scripts/tests/test-planning-prefilter.sh` (extension) et `plugin/_internal/tests/test-planning-hook-installed.sh`
**Analogue :** eux-mêmes. Garde d'équivalence : trois commandes rejouées (complète, sans pré-filtre, tronquée à l'appel), propriétés (A)-(G), corpus × formes de chemin, mutants. Sections lançables une à une : `VF_PF_SECTIONS=table,bornes | corpus | mutants`, `VF_PF_MUT=<préfixes>` (la suite entière dépasse 600 s sur machine chargée : **ne pas empiler**, étendre par sections). Étendre : payloads `SubagentHandback`, `SubagentStop`, `SessionStart`, `CwdChanged`, `FileChanged`, avec leur forme de payload (top-level `file_path`, `new_cwd`), lab dev → `0 octet` et code 0 ; mutation « ignorer l'adhésion » rouge (prolonge GATE-10).
**Protocole de mesure du coût** : quick 261002-brz (`SUMMARY` l.21-24) et 261003-1le (`SUMMARY` l.21-26) — 40 rejeux entrelacés par outil, médianes, `/bin/sh`, dans ce dépôt et sur un lab adhérent synthétique ; résultat écrit dans `modele-cycles.md`.
`test-planning-hook-installed.sh` : R-INST-01 (« exactement UNE entrée PreToolUse … ») devient « une entrée par événement + matcher élargi, dans `settings.json` jamais `settings.local.json` » ; installation réelle par `vibeflow-update.sh` dans un lab jetable, HOME et `XDG_CACHE_HOME` réassignés et exportés.

---

### Plan 46-08 — Rejeu en lecture seule, étapes 5 et 6

#### `PC/scripts/rejeu-gates.sh` / `rejeu-reel.sh` (outil de mesure, batch)
**Analogue :** `construire_g1`, `construire_g7`, `construire_role` (`rejeu-gates.sh:709-870`).

**Registre et attendus** — `rejeu-gates.sh:871` :
```python
CONSTRUCTEURS = {"reecriture": construire_reecriture, "G6": construire_g6, "G5": construire_g5, "G1": construire_g1, "G7": construire_g7, "ROLE": construire_role}  # rejeu-registre
```
Un constructeur rend des tuples `(outil, chemin, attendu, agent_type[, origine[, charge[, branche[, situation]]]])`, `attendu ∈ {doit-passer, doit-refuser, doit-refuser-modele}` (P45-D-21a). Trois contraintes de la 46 :
1. **Pitfall 11 (faux accept à vide)** : les labs réels n'ont ni `VERDICT.md` ni unités `cycles/` au format modèle ; un constructeur G3/G4 qui ne parcourt que le réel rendrait « 0/0 » sans rien jouer. Il faut des **unités synthétiques à attendus nominatifs** créées sur la **copie** — patron `phases_synthetiques` (l.678-706) et `construire_g7` (l.735-753, dossier synthétique `rejeu-orphelin-g7/`, `sous_copie(lab, …)` avant toute écriture) :
```python
        synth = (parent + "/" if parent else "") + SYNTH_ORPHELIN_G7
        sous_copie(lab, os.path.join(lab.copie, synth))
        try:
            os.makedirs(os.path.join(lab.copie, synth), exist_ok=True)
        except OSError:
            continue
        sortie.append(("Write", synth + "/.planning/config.json", "doit-refuser", "", "etat-derive", None, None, "creation"))
```
2. Un `SUMMARY.md` de style GSD (`.planning/phases/…`) ne doit **jamais** déclencher G3/G4 : seule la forme `.planning/cycles/<c>/phases/<p>[/plans/<pl>]/{CLOTURE,SUMMARY}.md` est visée ; le constructeur rejoue des écritures réelles de cette forme avec attendu dérivé du modèle (`etats_derives`, l.663-675, `exploitable`/`attendu_derive` l.635-651 : **aucune modification nécessaire** pour `à clore`, tout état ≠ `indéterminé` « fait référence »).
3. G4′ : pas de payload d'outil de fichier — `payload()` (l.948-976) fabrique `Write|Edit|NotebookEdit|Agent|Task|Bash` : ajouter `SubagentHandback` (entrée `{"message": …}`) et `hook_event_name` selon l'événement.

**Armement simulé** — `armer_copie` (l.364-378), `ORDRE_ETAPES[:etape]` : s'étend avec l'ordre ; **motif non unique = `ErreurOutil`** (garde utile). `analyser` (l.1087) : `--etape` accepte `("1","2","3","4")` → étendre à `5`, `6` ; en-tête l.11 et usage de `rejeu-reel.sh` idem.

**Artefacts de phase** : `46-REJEU-ATTENDUS.txt` au format `<gate> | <lab affiché> | <chemin relatif> | <attendu> | <motif>` (modèle `45-REJEU-ATTENDUS.txt`, ex. `G7 | ~/BusinessFlow-Lab | projects/avma | doit-refuser-modele | orphelin D-05 — refus conforme au modèle, lab non migré`), relevés `46-REJEU-ETAPE-5.md` et `46-REJEU-ETAPE-6.md` au format `45-REJEU-ETAPE-4.md` (tableau d'en-tête, `COMMIT-REJOUE <sha>`, contrôle de repos `lsof -d cwd` avant et après, `EMPREINTE-IDENTIQUE`). **Point de contrôle humain** avant chaque armement : le mandat de rejeu réel de la 45 (Willy, 2026-09-30) ne couvre pas explicitement la 46 (Open Question 2).

---

### Plan 46-09 — Armement, documentation, version

#### Armement (commit de constantes)
**Analogue :** les quatre commits de la 45 (`3d06e503` G6/G5, `bf6cfa87` G1, `b6609fa6` G7, `239df76d` ROLE, cités `PC/CHANGELOG.md` v2.9.0). Un commit = les constantes `ARMEMENT_G3`/`ARMEMENT_G4` à `"armed"` **et** `TABLE_ATTENDUE` des suites **et** la table de `modele-cycles.md` (R-REFERENCE) dans le **même** commit ; puis étape 6 (`G4P`). Condition : canary vert + 0 faux refus / 0 faux accept sur le banc puis le rejeu réel (P45-D-03, P46-D-11). D1 n'a pas de constante d'armement.

#### `PC/references/modele-cycles.md`
**Analogue :** section « Hook central et gates d'écriture (Phase 45) » (l.713-1058). Tables que R-REFERENCE compare au code, **à étendre en même temps que le code** :
- « Table d'armement livrée » (l.846-870 : colonnes `Gate | Étape | État | Comportement sur défaillance | Cas de canary | Relevé`) → lignes G3, G4 (étape 5), G4P (étape 6), relevés `46-REJEU-ETAPE-5/6` ;
- « Ordre d'évaluation » (`GATES_A_VERDICT (G6, G5, G1, G7, ROLE)`) ;
- les cinq listes sur **une seule ligne** (« Noms protégés par G6 », etc.) ;
- limites lettrées (a)…(ae) chacune sur sa ligne (nouvelles limites : (ao)… ; non mesurées : `FileChanged` sous `settings.json` en 2.1.288, #95440, forme de `watchPaths` ; Bash ouvert, `rm VERDICT.md` remet le compteur à 1) ;
- tables d'états et de codes (l.426-441, 484-485, 491-497, 508-536, 648-658 : états `à clore`, codes `verdict-perime`, `livrable-modifie-apres-cloture`, libellés) ; section « Hors de cette phase » (l.1059+) à purger de « G3, G4, G4′ et D1 … Phase 46 ».
- Grammaire exacte de la sortie brute et coût du pré-filtre par événement.

#### Spec moteur (`docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md`)
**Analogue :** amendement daté et attribué de P45-D-14a (l.169-171) — modèle de rédaction :
```
**Amendement du 2026-09-29 (P45-D-14a).** … 
Décision (Willy, AskUserQuestion session principale, 2026-09-29) : …
```
Quatre amendements (P46-D-18) avec canal et date « Willy, AskUserQuestion session principale, 2026-10-03 » : §3.1 (titre « Les huit états dérivés » l.215 → neuf, ligne `à clore`), §5 (table G3/G4/G4′, l.320-362), §5.1-1 (contrat par événement), §10 (deux empreintes, plafond de 3, l.630-645).

#### ROADMAP, versions, compteurs, inventaire
- `ROADMAP.md` du compartiment, Phase 47, l.236 : `**Depends on:** Phase 46 (G2′ se branche sur le même événement `TaskCompleted` que G3/G4 …)` → note datée (P46-D-19) : n'est plus vrai, point d'accroche re-décidé au cadrage de la 47. À la main (jamais `state.*`, frontmatter de STATE fermé avant la ligne 60).
- `planning-core` v2.9.0 → v2.10.0 **sans release** (P46-D-14) : `PC/VERSION` (`v2.9.0`), `PC/module.json` l.3, `PC/CHANGELOG.md` (entrée `## [v2.10.0] — <date>` calquée sur `[v2.9.0] — 2026-10-01`, qui se termine par « Aucune release : le module reste en … (ADR-073) »), `PC/README.md` en-tête `**Version**` (`check-version-sync.sh` point 8). `VERSION` racine, `plugin.json`, `marketplace.json` et l'historique des README racine **ne bougent pas**.
- Compteurs « N suites » des deux README racine (`README.md:142` « 104 suites in CI », `README.fr.md:147` « 104 suites ») : `scripts/check-version-sync.sh` exige l'égalité avec `find plugin scripts -type f -path '*/tests/test-*.sh'` (CI : `ci.yml:218-219`) → 104 + nombre de suites ajoutées (cinq nouvelles suites prévues = 109). `PC/README.md:103` dit « 12 suites » pour 13 réelles : écart préexistant non gaté.
- `docs/HOOKS-CONTRAT-SORTIE.md` §4 (l.80-86) : `assert n==33` → `n==37` (quatre nouvelles entrées : `SubagentStop`, `CwdChanged`, `FileChanged`, `SessionStart` de `planning-hook.sh` ; le matcher élargi ne compte pas) ; section « planning-core — 8 entrées » (l.184) → 12, nouvelles lignes d'inventaire au format de la ligne 32 (colonnes `# | Événement · matcher | Script | Invocation | --hook | Codes | Classement | Forme | Action`). Commande de recomptage à relancer (écrite dans le document, l.85, avec son `assert n==33`).
- `scripts/tests/test-hook-exit-parc.sh` : ne lit pas `hooks.json` (inventaire déclaré) ; ajouter, si pertinent, une exclusion nommée pour les nouvelles entrées bloquantes par décision JSON (bloc l.375-388, `echo "  ⊘ guard-… — bloque par décision JSON, sort toujours 0"`). **Touche `scripts/tests/test-*.sh` = surface de `check-gate-touche.sh`** : trailer `Gate-Touche:` obligatoire sur ce commit.

---

## Gabarit de suite : jumeau négatif + mutation avec trace

Toute suite nouvelle de la phase suit ce gabarit. Les cinq suites sont des scripts bash autonomes, découverts par la CI (`find plugin scripts -type f -path '*/tests/test-*.sh'`, `.github/workflows/ci.yml:218`, **sans modifier `ci.yml`**), lançables par `bash <suite>` (jamais sourcées sous zsh), chacune visant < 120 s (ne **pas** empiler dans `test-planning-gates.sh`, 3 min 43 pour 461 cas : seuls `R-REFERENCE`/`R-TABLE` s'y étendent).

### A. Squelette d'une suite (copier `test-planning-hook-registered.sh:1-60`, `test-planning-gates.sh:103-130`)
```bash
#!/usr/bin/env bash
# test-<nom>.sh — <ce que la suite prouve> (Phase 46, <plan> ; CLOT-xx ; P46-D-yy).
# Familles : R-<X>-01 ... ; MUT-* : chaque garde est tuée par un mutant à motif unique dont la trace est imprimée.
# Portable GNU/BSD (P45-D-16) : ni `stat -f/-c`, ni `sed -i`, ni `timeout`, ni `readlink -f` ; `cmp -s` jamais `diff` ;
# tout le travail fin est fait par Python (PYBIN). Lançable depuis tout cwd. Piège CI (`bash -e {0}`) : jamais `cmd && { … }` nu.
set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$TESTS_DIR/.." && pwd)"
HOOK="$SCRIPTS_DIR/planning-hook.sh"
HOOKS_JSON="$SCRIPTS_DIR/../hooks/hooks.json"
[ -f "$HOOKS_JSON" ] || HOOKS_JSON=""

PYBIN=python3
case "$(command -v python3 2>/dev/null)" in
  ''|*WindowsApps*)
    if command -v python >/dev/null 2>&1; then PYBIN=python
    else echo "[test-<nom>] python3 requis" >&2; exit 1; fi
    ;;
esac

pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() {
  echo "  ✗ $1"
  echo "    assertion : $2"
  echo "    attendu   : $3"
  echo "    obtenu    : $4"
  fail=$((fail+1))
}

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
T_DEBUT="$(date +%s)"
# ... AIDES (heredoc Python quoté), run_sections ...
T_FIN="$(date +%s)"
echo "DUREE s=$((T_FIN - T_DEBUT))"
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
```
Les aides Python vivent dans un heredoc quoté (`cat > "$AIDES" <<'PY_AIDES_<NOM>_EOF'`), invoquées **par section** (`VF_<NOM>_SECTIONS=a,b`), leurs lignes `  ✓ …` / `  ✗ …` sont recomptées par le shell (`run_sections`, `test-planning-gates.sh:4930-4945`) ; une section qui plante sans ligne `✗` est elle-même un `ko`. Sous `.claude/scripts/tests/` d'un lab (as-installed) la suite doit imprimer `NOTE … hors dépôt` plutôt qu'un vert à vide (`test-planning-prefilter.sh:57-63`, message l.60).

### B. Payload, rejeu de la **commande enregistrée**, copies forcées (jamais l'état d'armement livré)
Le hook est rejoué par la commande lue dans `hooks.json` sous `/bin/sh -c` (`Ctx.lancer`, `test-planning-gates.sh:262-278`), jamais par appel direct du script (P45-D-20). Les cas de gate tournent sur une copie dont les constantes `ARMEMENT_*` sont **forcées** (`copie_forcee(dossier, "observe"|"armed")`, l.280-296) : jamais sur l'état livré, qui change à chaque armement. Payload du harnais (l.177-189) :
```python
def payload(outil, entree, cwd, agent_type=None, agent_id="agent-test"):
    obj = {"session_id": "sess-test", "transcript_path": "transcript.jsonl", "cwd": cwd,
           "prompt_id": "prompt-test", "permission_mode": "default"}
    if agent_type is not None:
        obj["agent_id"] = agent_id
        obj["agent_type"] = agent_type
    obj["hook_event_name"] = "PreToolUse"
    obj["tool_name"] = outil
    obj["tool_input"] = entree
    obj["tool_use_id"] = "toolu_test"
    return json.dumps(obj, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
```
→ à paramétrer par `hook_event_name` pour les événements de la 46 (`SubagentStop` : `last_assistant_message`, `permission_mode` ; `FileChanged` : `file_path`/`event` de premier niveau ; `CwdChanged` : `old_cwd`/`new_cwd`) ; `classer(rc, out)` (l.311-330) distingue `silence | avertit | deny | autre:*` : ajouter les formes `block` (SubagentStop) et `watchPaths`.

### C. Contrôle `(conforme, détail)` + jumeaux négatifs (patron R-G5-01..06, `test-planning-gates.sh:789-880`)
Chaque contrôle rend `(bool, détail)` et s'applique à un dossier de scripts donné (le livré ou un mutant). **Jumeaux exigés pour chaque gate** :
1. copie **observe** : silence, code 0, **UNE** ligne `gate=<G>` au journal, sans contenu (`controle_g5_01`) ;
2. copie **armed** : **UN** objet deny, `[planning-core] <G> :`, motif nommant la commande de sortie, journal vide (`controle_g5_02`) ;
3. **voisins qui passent** (jumeau négatif de forme) : `PLAN.md`, `SUMMARY.md` GSD, nom voisin, livrable nommé `verdict`, fichier hors de la forme `.planning/cycles/…` (`controle_g5_04`) ;
4. **lab dev** (non adhérent) : stdout d'octet vide et code 0 pour chaque événement, y compris pour la mutation « adhésion ignorée » (`controle_g6_07`) ;
5. **erreur interne** injectée (mutant sonde `# g5-sonde`) : observe journalise, armed refuse (`controle_g5_05`) ;
6. **jumeau d'une unité conforme** : le même lab avec livrable présent / verdict valide / empreintes conformes ne refuse pas (patron `etat-a-corriger-jumeau`).

Extrait de référence (`controle_g5_02`, l.810-823) :
```python
def controle_g5_02(ctx, script):
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    cache = dossier_neuf(ctx, "cache-g5-02")
    rc, out, err = _g5(ctx, d, "Write", VERDICT_REL, extra_env={"XDG_CACHE_HOME": cache})
    v = classer(rc, out)
    if v != "deny" or err or len(out.splitlines()) != 1:
        return False, "%s stderr=%s %s" % (v, court(err), court(out))
    raison = json.loads(out.decode("utf-8"))["hookSpecificOutput"]["permissionDecisionReason"]
    if not raison.startswith("[planning-core] G5 :") or "poser-verdict.sh" not in raison:
        return False, "raison : " + raison
    if lignes_journal(cache):
        return False, "un refus a écrit au journal d'observation"
    return True, "copie armed : un objet deny, raison « [planning-core] G5 : … poser-verdict.sh », journal vide"
```
Ajouter pour la 46 une assertion de **contenu des messages** : aucun chemin absolu hors du lab, ni `no such file`, ni `can't open` (P46-D-10, #60490).

### D. Mutation avec trace : `make_script_mutant` + `okmut` / `komut`
**Mécanique** (`test-planning-gates.sh:471-503`) : l'**unique** ligne portant le motif fixe est remplacée (indentation conservée) dans une copie ; `bash -n` et la compilation du corps Python extrait (`corps_python(texte, marqueur)`, l.510-520) doivent passer ; le mutant est construit sur un texte `observe_partout` (base indépendante de l'armement). Un motif ambigu ou absent, ou un mutant identique, est un **KO nommé** (« MOTIF AMBIGU OU ABSENT », « NON OPPOSABLE »). D'où l'obligation de **balises de ligne uniques** dans le code livré (`# g3-vide`, `# g4-hash`…).

**Enregistrement d'un mutant** — deux patrons équivalents :
- liste `M` de `sec_mutants` (`test-planning-gates.sh:3197-3330`) : `(ident, motif, remplacement, id_contrôle, fonction_contrôle[, nom_script, marqueur])`, par exemple
  `("DECIDER-ARMED", 'if etat == "armed":  # decider-armed', 'if False:  # decider-armed', "R-G5-02", controle_g5_02)` ;
- ou décorateurs `@lota("R-…")` + `lota_mutant(ident, motif, remplacement, controle, nom, marqueur)` (`test-planning-gates.sh:3363-3379`, usage l.3798-3910) — **le plus compact pour une suite neuve** :
```python
@lota("R-VERDICT-09")
def controle_verdict_utf8(ctx, script):
    ...
lota_mutant("VERDICT-UTF8", "# verdict-utf8", "pass  # verdict-utf8", "R-VERDICT-09", "poser-verdict.sh", "PY_POSER_VERDICT_EOF")
```
Un mutant d'un **autre** script (`poser-verdict.sh`, `recalc-planning.sh`, `check-gates-alive.sh`) passe son `nom` et son marqueur de heredoc (`PY_POSER_VERDICT_EOF`, `PY_RECALC_PLANNING_EOF`, `PY_CHECK_GATES_ALIVE_EOF`).

**Preuve d'opposabilité** (boucle de `sec_mutants`, l.3341-3359) — le contrôle doit : (1) passer sur l'**original** ; (2) laisser un **témoin** (Write neutre d'un lab adhérent) inchangé sous le mutant ; (3) **rougir** sous le mutant. Trace imprimée :
```python
def okmut(ident, trace):
    print("  ✓ MUT-%s TUÉ — %s" % (ident, trace))
def komut(ident, assertion, attendu, obtenu):
    print("  ✗ MUT-%s NON TUÉ" % ident)
    print("    assertion : " + assertion)
    print("    attendu (original) : " + attendu)
    print("    obtenu (mutant)     : " + obtenu)
...
okmut(ident, "%s rougit · attendu (original) : %s · obtenu (mutant) : %s · témoin inchangé" % (cible, original[1], mutant[1]))
```
**Mutants de la 46 à tracer** (liste de `46-RESEARCH.md`, section « Validation Architecture ») : prédicat « vide » neutralisé ; lien suivi ; comparaison de `hash` retirée ; comparaison de l'empreinte des livrables retirée ; fail-open sur erreur interne ; adhésion ignorée ; matcher sans `SubagentHandback` ; grammaire de la sortie brute assouplie ; garde `permission_mode` retirée ; plafond retiré ; consommation de dérogation sans verrou ; `watchPaths` renvoyé hors adhésion. **Règle de la 45 (quick 261001-qq9)** : un mutant se tue par **structure ou verdict, jamais par la durée**.

### E. Variante tout-bash (suites de dérivation) : `make_recalc_mutant` / `okmut` / `komut` / `_verifier_plantage`
Pour `test-recalc-planning.sh` et toute suite qui ne passe pas par le hook : `make_recalc_mutant <id> <motif> <remplacement>` (`test-recalc-planning.sh:2216-2262`) copie le script, exige `grep -Fc` = 1 occurrence (« MOTIF AMBIGU OU ABSENT »), `cmp -s` différent (« NON OPPOSABLE »), `bash -n`, compilation du corps Python ; `_verifier_plantage` (l.1516-1527) refuse un mutant qui plante (trace Python non gérée, code hors `{0,1,2,3,64}`) au lieu de l'avoir « tué ». Exemple à copier — `MUT-LIVRABLES-CACHE` (l.2282-2297) :
```bash
if make_recalc_mutant LIVRABLES-CACHE \
  'if livrables_actuels == livrables_cache:' \
  'if True:  # MUT-LIVRABLES-CACHE'
then
  MR="$MUT_DIR/recalc-planning.sh"
  ...
  if ! _verifier_plantage LIVRABLES-CACHE "état de la phase de R58 après suppression du livrable" "$WORK/mut-livrables-cache-out.json" "$WORK/mut-livrables-cache-err.txt" "$RC_M"; then
    if grep -qF 'livrable absent : livrables/rapport.md' "$DIR_CAS/.planning/INDEX.md" 2>/dev/null; then
      komut LIVRABLES-CACHE "…" "indéterminé, livrable-absent (original)" "indéterminé, livrable-absent (mutant non opposable)"
    else
      okmut LIVRABLES-CACHE "… · attendu (original) : indéterminé … · obtenu (mutant) : $(grep 'cycles/01-traceur' "$DIR_CAS/.planning/INDEX.md" 2>/dev/null) (…)"
    fi
  fi
fi
```
Le test jumeau d'un cas « supprimé » (R58) pour un livrable **réécrit** est le cas nouveau exigé par le piège du cache.

### F. Banc texte (fixtures) : jumeau de lab + directive d'écriture
`fixtures/gates-banc.txt` (directives expliquées dans son en-tête, l.1-20) et `fixtures/recalc-planning-banc.txt` : un lab = `@@ lab <nom>` ; son **jumeau négatif** = `@@ lab <nom>-dev jumeau-de=<nom>` (même arbre, `planning_version` non adhérent → silence) ; `@@ fichier <chemin>` (contenu = lignes suivantes) ; `@@ dossier <chemin>` ; `@@ lien <chemin> -> <cible>` ; `@@ ecriture <outil> <chemin> [agent=…] [cwd=…] [commande=…] :: <attendu> [<gate>]` avec attendu `doit-passer | doit-refuser | avertit | silence` ; `@@ attendu <unité> :: <état>[ :: <raison>]` (banc de recalcul). Le banc de clôture est **un fichier texte versionné à plat sous `fixtures/`** (l'installeur pose `fixtures/` à plat ; aucun dossier `.planning/` imbriqué n'est versionné). Le dossier de planning s'écrit `.planning/` dans le banc : c'est du texte. Le banc de clôture a besoin de directives d'**événement** en plus de `ecriture` (RESEARCH Wave 0) ; étendre le coureur du banc (`labs_banc`, `materialiser`, `entree_de_ecriture`, `juger`, `test-planning-gates.sh:433-460`).
Compte exigé (« COMPTE <gate> » / « COUVERTURE ») : une assertion que le banc **joue réellement** au moins N cas par gate et par attendu (jamais un vert à vide ; modèle : `COUVERTURE G7`, `COMPTE G7`).

---

## Shared Patterns

### Entonnoir de décision, armement, observation, dérogation
**Source :** `planning-hook.sh:1017-1044` (`decider`), `:2046-2070` (`evaluer_protege`, `evaluer_gates`), `:890-909` (`observer`)
**Apply to :** G3, G4, G4′ (via `Verdict(gate, chemin_rel, raison)`), jamais un second chemin de décision.
```python
    for verdict in verdicts:
        etat = TABLE_ARMEMENT.get(verdict.gate)
        if etat == "armed":  # decider-armed
            entree = None if verdict.chemin_rel is None else derogation_active(contexte["racine"], verdict.gate, verdict.chemin_rel)
            if entree is None:
                refus.append("[planning-core] %s : %s" % (verdict.gate, verdict.raison))
            else:
                couverts.append((verdict, entree))
        else:
            observer(verdict, contexte)
```
`chemin_rel` vaut `None` pour une erreur interne (jamais couverte par une dérogation). Une dérogation n'est consommée que si la décision **finale** est un passage grâce à elle (`decider-global`, l.1037-1038).

### Fail-closed dans le périmètre adhérent, silence ailleurs
**Source :** `planning-hook.sh:2110-2131` (`# non-adherent`, phase B), `hooks.json:40` (repli shell), `pré-filtre vf_pre`
**Apply to :** tout nouvel événement et matcher. Hors lab adhérent : stdout d'octet vide, code 0 ; l'exit 2 est interdit (P45-D-08, P46-D-10). `exit 0` avec décision imprimée est livré tel quel (`figer_echeance()` avant l'impression, `_emettre` l.792-796).

### Encodage de journal et écriture append-only sans suivi de lien
**Source :** `_jeton_journal` (`planning-hook.sh:827-874`, copies ast-identiques `recalc-planning.sh`, `deroger-gate.sh:130-177`), `observer` (l.890-909), `inscrire` de `deroger-gate.sh:262-292` (`O_APPEND | O_CREAT | O_NOFOLLOW`, `fcntl.flock`, droits jamais élargis, journal non régulier = refus code 1)
**Apply to :** journal de D1, ligne `consommee` du plafond, ligne d'intention du hook. Injectif, aucun saut de ligne, jamais le contenu écrit.

### Lecture de fichiers du modèle sans suivi de lien, UTF-8 strict
**Source :** `est_fichier_regulier` (`planning-hook.sh:436-441`), `lire_frontmatter_fichier` (l.607-618), `hash_contenu` (`recalc-planning.sh:1147`), `lire_octets`/`ouvrir_verrou` (`poser-verdict.sh:332-346`)
**Apply to :** prédicat de livrable, empreintes, lecture de `VERDICT.md`/`PLAN.md`, réconciliation de D1. `lstat` + `O_NOFOLLOW` partout ; un lien est « absent ».

### Dérivation du rôle d'un agent
**Source :** `resoudre_agent` (`planning-hook.sh:1950-1974`), `deriver_role` (l.1694-1711), `jetons_nus_agent` (l.1682-1691), `normaliser` (l.1714-1717)
**Apply to :** G4′ et vérificateur de juges. Le contrôle croisé avec `check-agents.sh` vit dans `scripts/tests/test-role-hook-vs-check-agents.sh`. `home` est un argument du lanceur (le cœur ne lit **aucune** variable d'environnement, `R-ENV-02`).

### Rejeu de la commande enregistrée et ses cinq lieux de copie
**Source :** `COMMANDE_REFERENCE` (`check-gates-alive.sh:152-180`), `fabriquer_payload` (l.345-369), `verdict` (l.372-386), `attendu_de` (l.530-534), `lire_armement` (l.465-479)
**Apply to :** toute modification du texte de la commande et toute extension de `CANARIS` (un cas par gate armé ; couverture minimale `COUVERTURE_MINIMALE`, l.184 ; étiquettes vérifiées contre le payload par `etiquette_vraie`, l.482-495 ; l'attendu est **dérivé** de la table d'armement, jamais écrit dans `CANARIS`). `trouver_commande` (l.317-341) ne lit que `evenements.get("PreToolUse")` : le canary doit lire les cinq événements. Ajouter, pour D1, un cas de canary par **rejeu d'un payload synthétique avec trace exigée** (P46-D-11 : D1 n'est jamais armé mais a son canary) ; pour G3/G4/G4′ un cas par gate, forme `"G3-vide|G3|nominal|Write:.planning/cycles/01-c/phases/01-p/CLOTURE.md|fil-principal"` (champs `id|gate|mode|payload|étiquettes`, `lire_canaris` l.498-509).

### Marqueur `Gate-Touche:` et contrôle
**Source :** `CLAUDE.md` racine (« Marqueur », G-2), `scripts/check-gate-touche.sh` (surface fermée l.25-30, classifieur l.204-215), `45-CONTROLE-MARQUEUR.sh` (contrôle réutilisable)
**Apply to :** tout commit touchant `PC/scripts/planning-hook.sh`, la commande de `hooks.json`, une suite de gate. `PC/**` n'est pas dans la surface de `check-gate-touche.sh` (discipline que la 45 s'est imposée, P46-D-17) ; `scripts/tests/test-hook-exit-parc.sh` l'est (obligatoire). Forme reconnue à la forme seule :
```
Gate-Touche: plugin/planning-core/scripts/planning-hook.sh — G3 et G4 en PreToolUse, constantes en observe
```
(motif sans virgule, séparateur ` — ` ou ` - `, raison de ≥ 10 caractères non blancs). Contrôle : `bash .planning/workstreams/gouvernance/phases/VFDO-45-moteur-hook-central-par-r-le-et-gates-d-criture/45-CONTROLE-MARQUEUR.sh --base=<ref> -- plugin/planning-core/scripts plugin/planning-core/hooks`.

### Conventions de livraison
**Source :** `CLAUDE.md` racine (commits en français ; `Gate-Touche:` ; identifiants préfixés `P46-D-NN`, `CLOT-NN` ; traçabilité des arbitrages « canal + date »), `CLAUDE.local.md`.
**Apply to :** tous les plans. Aucune release avant la clôture de `fiabilite-v1.0` ; gates de planning rejoués à la main avec `--file .planning/workstreams/gouvernance/STATE.md` ; STATE tenu à la main (jamais `state.*`) ; shell du poste = `/bin/zsh`, CI = `bash -e {0}` : rejouer les deux ; bash 3.2 (ni `declare -A`, ni `mapfile`, ni `${x^^}`, ni `[[ -v ]]`) ; Python compatible 3.9 (ni `match`, ni `X | Y`) ; BSD/macOS (ni `stat -f/-c`, ni `sed -i`, ni `timeout`, ni `readlink -f`, ni `grep -P`) ; aucun chemin de machine (`/Users/…`) dans un fichier livré (`scripts/check-machine-paths.sh`).

---

## Pièges de couplage (relevés pendant la cartographie)

1. **Erreur du chemin `OSError` des scripts `poser-verdict.sh`/`deroger-gate.sh`** : `print("… " + str(exc))` (`poser-verdict.sh:458`, `deroger-gate.sh:320`) imprime le chemin absolu et « No such file or directory » : contraire à P46-D-10 pour tout nouveau chemin de code qui lit les livrables.
2. **`controle_table_02`** (`test-planning-gates.sh`) construit des tables à cinq arguments `T(g6, g5, g1, g7, role)` et compte « 6 tables rejetées, 5 préfixes acceptés » : à réécrire pour huit gates et sept préfixes d'ordre.
3. **`copie_forcee`/`_dossier_observe`** exigent exactement **cinq** réécritures de constantes (`if n != 5: raise RuntimeError`, `test-planning-gates.sh:287-288` et **aussi l.2845**, `test-planning-hook-registered.sh:203`) : passer à huit **et** ajouter les trois noms aux regex, dans le même commit que les constantes.
4. **`R-REFERENCE`** lit la table de `modele-cycles.md` et la compare à `TABLE_ARMEMENT`, au matcher et au glob de la commande (`outils_commande`, l.4685-4689) : ajouter `SubagentHandback` au matcher **et** au `case` du repli, sinon l'outil apparaît « laissé ouvert ».
5. **`merge-hooks.sh`** : deux groupes `PreToolUse` citant `planning-hook.sh` s'écraseraient (même cause que l'entrée 27 de `HOOKS-CONTRAT-SORTIE.md`). Test d'installation réelle à ajouter : **une** entrée par événement, matcher élargi, dans `settings.json`.
6. **`recalc-planning-banc.txt:577`** et **R27** (`test-recalc-planning.sh:1005-1024`) encodent l'ancien `indéterminé :: verdict-passe-sans-SUMMARY.md` : à réécrire dans le plan qui introduit `à clore`.
7. **Cache** : `CACHE_SCHEMA_VERSION = 1` → 2 ; le mutant `LIVRABLES-CACHE` perd son motif si la ligne de comparaison change.

## No Analog Found

Parties de fichiers sans analogue direct (le planificateur s'appuie sur `46-RESEARCH.md` et `46-RECHERCHE-HOOKS.md`) :

| Élément | Rôle | Flux | Raison |
|---|---|---|---|
| Parcours borné + `lstat` composant par composant du prédicat « livrable présent » | utilitaire | file-I/O | Aucun parcours borné de livrables n'existe ; les parcours bornés actuels (`_verdicts_du_planning`, `BORNE_PARCOURS_VERDICTS = 20000`, `planning-hook.sh:1067-1079`) s'arrêtent silencieusement au lieu de refuser explicitement |
| Grammaire de la sortie brute (G4′) | utilitaire | transform | Aucun détecteur de sortie de commande dans un rapport ; esquisse dans RESEARCH Pattern 6 |
| `watchPaths` de `CwdChanged`/`FileChanged` ; forme de sortie par événement | hook | event-driven | Aucun hook du module ne traite ces événements (aucun `plugin/*/hooks/hooks.json` ne les déclare) ; forme non mesurée (P46-D-08) |
| Réconciliation par hash au `SessionStart` + notion d'« écriture expliquée » | service | batch | La baseline de `planning-session-snapshot.sh` est un patron de **forme** (hash first-wins) mais porte sur git, pas sur un journal d'intentions |
| Sortie piégée / verdict de canary de juge | contrat | batch | « Sortie piégée » n'existe que dans les specs (`46-SCOUTING.md` §4) ; notion voisine : test de discrimination de `plugin/audit-architecture/references/rubric-design.md:58-62, 79-84` |
| Banc de clôture à directives d'événement | fixture | — | `gates-banc.txt` ne connaît que `@@ ecriture` ; directive d'événement à créer |

## Metadata

**Analog search scope :** `plugin/planning-core/` (scripts, tests, fixtures, hooks, references), `plugin/_internal/` (`merge-hooks.sh`, `tests/`), `scripts/` et `scripts/tests/`, `docs/` (`HOOKS-CONTRAT-SORTIE.md`, spec moteur), `.planning/workstreams/gouvernance/` (ROADMAP, Phase 45), `.github/workflows/ci.yml`.
**Fichiers lus :** `planning-hook.sh` (l.1-260, 343-385, 419-670, 756-1360, 1660-1730, 1940-2139), `poser-verdict.sh` (complet), `recalc-planning.sh` (l.76-135, 752-770, 1000-1300), `deroger-gate.sh` (complet), `check-gates-alive.sh` (l.1-40, 75-645), `rejeu-gates.sh` (l.1-180, 364-432, 635-770, 948-1114), `hooks/hooks.json` ; suites : `test-planning-gates.sh` (en-tête, aides, sections `g5`, `mutants`, `lota`, `verdict`), `test-planning-hook-registered.sh` (l.1-260), `test-recalc-planning.sh` (en-tête, R27, R58, `make_recalc_mutant`, mutants), `test-planning-prefilter.sh` (en-tête), `test-planning-hook-installed.sh` (en-tête), `test-hook-exit-parc.sh` (en-tête, exclusions) ; fixtures : `gates-banc.txt`, `recalc-planning-banc.txt` (extraits) ; `merge-hooks.sh` l.498-518 ; `check-gate-touche.sh` ; `45-PATTERNS.md`, `45-REJEU-ATTENDUS.txt`, `45-CONTROLE-MARQUEUR.sh`, `45-REJEU-ETAPE-4.md` (en-têtes).
**Contrôle « fichier suivi » :** `git ls-files` rend non vide pour tous les chemins cités (scripts, suites, fixtures, `hooks.json`, `modele-cycles.md`, `merge-hooks.sh`, `ci.yml`, spec, ROADMAP, artefacts de la Phase 45).
**Pattern extraction date :** 2026-10-03
