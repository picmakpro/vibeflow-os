# Phase 45: Moteur — hook central par rôle et gates d'écriture - Pattern Map

**Mapped:** 2026-09-29
**Files analyzed:** 27 (fichiers nouveaux ou modifiés, dont 9 chores documentaires)
**Analogs found:** 24 / 27 (3 sans analogue direct : commande enregistrée en shell pur, table d'armement, journal d'observation — voir « No Analog Found »)

Tous les chemins cités sont **suivis par git** (`git ls-files` vérifié le 2026-09-29) et relatifs à la racine du dépôt. Aucun chemin miroir (`.claude/scripts`, `.claude/gsd-core`) n'est cité. Aucun chemin machine (`/Users/…`, `~/…`) n'apparaît dans les extraits de code livré : `check-machine-paths.sh` les rejette dans tout fichier suivi.

Règle de lecture : les numéros de ligne sont ceux du worktree `gouvernance-45` au 2026-09-29. Re-vérifier avec `grep -n` avant de citer une ligne dans un plan si une autre PR a touché le fichier.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `plugin/planning-core/scripts/planning-hook.sh` (lanceur bash + Python embarqué ; nom au choix du planificateur) | hook (PreToolUse), middleware de refus | request-response (payload JSON stdin → JSON deny / silence) | `plugin/conductor/scripts/guard-driver-lock.sh` (forme du deny, routage par `tool_name`) + `plugin/planning-core/scripts/recalc-planning.sh` (Python embarqué, adhésion, frontmatter) | role-match (deux analogues à combiner) |
| commande enregistrée (champ `command` de l'entrée `PreToolUse`) | config + shell fail-closed | request-response | aucun exact ; forme de l'entrée : `plugin/conductor/hooks/hooks.json` l.5-21 | partial (voir No Analog) |
| `plugin/planning-core/hooks/hooks.json` (+1 `PreToolUse`, +1 `SessionStart` canary) | config | event-driven | `plugin/conductor/hooks/hooks.json` (PreToolUse + SessionStart) et lui-même | exact |
| `plugin/planning-core/scripts/check-gates-alive.sh` (canary de session) | hook (SessionStart), diagnostic | batch (rejeu + marqueur) | `plugin/conductor/scripts/check-guard-health.sh` | exact (même famille, P45-D-20) |
| commande de verdict (pose `VERDICT.md`) | utilitaire CLI | file-I/O (écriture atomique + hash) | `plugin/planning-core/scripts/recalc-planning.sh` (`_ecrire_atomique`, `_jeton_journal`, parse d'arguments) | role-match |
| commande de dérogation + journal append-only | utilitaire CLI | file-I/O (ajout seul) | `recalc-planning.sh` `ajouter_au_journal` l.1589-1602 + `_jeton_journal` l.1529-1560 | exact (mécanique), role-match (commande) |
| `plugin/planning-core/scripts/recalc-planning.sh` (GATE-14, `NOMS_MODELE_RACINE_FICHIERS`) | service (moteur), modification | batch / CRUD sur fichiers générés | lui-même | exact |
| outil de rejeu lecture seule (chemins en argument) | utilitaire CLI | batch / transform (lecture + rapport) | `aides.py` du banc 44 dans `test-recalc-planning.sh` l.123-436 (`materialiser`, `empreinte`, `coureur`) + `recalc-planning.sh --read-only` | role-match |
| `plugin/planning-core/scripts/tests/test-planning-hook-registered.sh` | test | request-response (rejeu de la commande) + mutation | `plugin/planning-core/scripts/tests/test-recalc-planning.sh` (helpers, mutants) + `scripts/tests/test-hook-exit-parc.sh` (deux flux, `cmp`) | role-match |
| `plugin/planning-core/scripts/tests/test-planning-gates.sh` | test | batch (banc deux sens) + mutation | `test-recalc-planning.sh` | exact |
| `plugin/planning-core/scripts/tests/fixtures/gates-banc.txt` | fixture | file-I/O (banc texte) | `plugin/planning-core/scripts/tests/fixtures/recalc-planning-banc.txt` | exact |
| `plugin/planning-core/scripts/tests/test-recalc-planning.sh` (réécriture `socle-signal`, GATE-14) | test, modification | batch | lui-même l.2670-2720, 2746-2809, 2942-2992, 3900-3940 | exact |
| `plugin/_internal/tests/test-planning-hook-installed.sh` | test as-installed | file-I/O + rejeu | `plugin/_internal/tests/test-vibeflow-update.sh` (T10 l.507-561, `check_exec_settings` l.462-505) | role-match |
| `scripts/tests/test-role-hook-vs-check-agents.sh` | test croisé multi-modules | batch (oracle différentiel) | `scripts/tests/test-hook-exit-parc.sh` + `plugin/conductor/scripts/tests/test-check-agents.sh` l.392-410 (`--file`) | role-match |
| suite de l'outil de rejeu (`…/tests/test-…replay….sh`) | test | file-I/O (empreinte `cmp`) | `test-recalc-planning.sh` R04/R07 (l.510-513, 581-583) + `test-hook-exit-parc.sh` | role-match |
| suite du canary de session (`check-gates-alive`) | test | batch | `plugin/conductor/scripts/tests/test-check-guard-health.sh` | exact |
| `plugin/planning-core/references/modele-cycles.md` | doc de référence | — | lui-même (§ « Hors de cette phase » l.685-695, § `VERDICT.md` l.354-372, table des codes l.54-66) | exact |
| `docs/HOOKS-CONTRAT-SORTIE.md` | doc durable | — | lui-même §4 (l.78-103, inventaire), §5 (l.185-195, décompte) | exact |
| `plugin/conductor/references/workstream-planning-consumers.md` | doc de gouvernance | — | lui-même (recensement) | exact |
| `plugin/planning-core/{VERSION,module.json,CHANGELOG.md,README.md}` | config/doc (bump v2.9.0) | — | leur état v2.8.0 | exact |
| `README.md` et `README.fr.md` (compteur « N suites ») | doc | — | `scripts/check-version-sync.sh` §9 l.131-139 | exact |
| `.planning/workstreams/gouvernance/REQUIREMENTS.md` (famille `GATE-01..15`) | planning | — | famille `MOTR-*` du même fichier | exact |

## Pattern Assignments

### `plugin/planning-core/scripts/planning-hook.sh` (hook PreToolUse, request-response)

**Analogue principal (Python embarqué, lanceur) :** `plugin/planning-core/scripts/recalc-planning.sh` l.13-67.
**Analogue secondaire (forme du refus, routage par outil) :** `plugin/conductor/scripts/guard-driver-lock.sh` l.418-440 et l.535-544.

**Lanceur et résolution de l'interpréteur** (`recalc-planning.sh` l.49-67, motif ADR-054, stub Microsoft Store détecté par chemin) :
```bash
set -uo pipefail
PYBIN=python3
case "$(command -v python3 2>/dev/null)" in
  ''|*WindowsApps*)
    if command -v python >/dev/null 2>&1; then
      PYBIN=python
    else
      echo "[recalc-planning] interpréteur Python introuvable — impossible d'exécuter le moteur" >&2
      exit 1
    fi
    ;;
esac

"$PYBIN" - "$PLANNING_DIR" "$READ_ONLY" "$DETECT_GSD_SH" <<'PY_RECALC_PLANNING_EOF'
import errno
...
PY_RECALC_PLANNING_EOF
```
À adapter (RESEARCH « Lanceur ») : le lanceur du hook **ne décide de rien**, il rend tout code ≠ 0 à la commande enregistrée. Transport de la charge utile par fichier temporaire `mktemp` 0600 + `trap 'rm -f "$T"' EXIT` (patron `plugin/_internal/merge-hooks.sh` l.146-156 : `PREFIX_FILE="$(mktemp "${TMPDIR:-/tmp}/vf-merge-hooks-prefix.XXXXXX")"`), puis `"$PYBIN" -I -S - "$T" <<'PY_PLANNING_HOOK_EOF'`. Le marqueur de fin de heredoc doit être unique et propre au script (les suites de mutants extraient le corps par `awk '/<<.PY_…_EOF.$/{f=1;next} /^PY_…_EOF$/{f=0} f'`, voir `test-recalc-planning.sh` l.1480).

**Forme du deny** (`guard-driver-lock.sh` l.535-544 ; identique dans `plugin/software-architecture/scripts/guard-file-size.sh` l.158-164) :
```python
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": reason,
    }
}, ensure_ascii=False))
sys.exit(0)
```
Toujours exit 0, **jamais** exit 2 (DIV-2, `docs/HOOKS-CONTRAT-SORTIE.md` §1 et en-tête de `guard-driver-lock.sh` l.22-25). Un seul objet JSON par exécution, encodé par `json.dumps` (HOOKS-CONTRAT §3 bis).

**Avertissement G2 et citation de dérogation** (canal vérifié F11, `45-RESEARCH.md` « Code Examples ») : même enveloppe **sans** `permissionDecision`, avec `"additionalContext"` à la place de la raison. Ne pas utiliser `systemMessage` (DIV-3).

**Lecture du payload et routage par outil** (`guard-driver-lock.sh` l.416-440 — copier la structure, pas la gestion d'erreur) :
```python
try:
    payload = json.load(sys.stdin)
except Exception:
    sys.exit(0)  # imparsable -> fail-open SILENCIEUX (QUAL-01 issue 3)

tool = payload.get("tool_name") or ""
ti = payload.get("tool_input") or {}
if not isinstance(ti, dict):
    sys.exit(0)
```
**NE PAS COPIER** ces `sys.exit(0)` sur erreur : dans le hook de la 45 (P45-D-08, Pattern 3 de la recherche) une erreur **avant** que l'adhésion soit connue rend `sys.exit(3)` **sans rien imprimer** (la couche shell tranche), et une erreur **après** rend un `deny` explicite exit 0 (`try/except BaseException`). Les gardes existants sont fail-open ; celui-ci ne l'est pas dans un lab adhérent.

**Normalisation de chemin Windows** (`guard-driver-lock.sh` l.428-434, à reprendre pour le décodage du `file_path`) :
```python
norm = fp.replace("\\\\", "/").replace("\\", "/")
if not re.search(r"(^|/)\.planning/", norm):
    sys.exit(0)
```
Le hook de la 45 remplace ensuite par une résolution **physique** (`os.path.realpath`) et une comparaison d'identité (`os.path.samefile` + `casefold`, Pattern 5 de la recherche), pas par une comparaison de chaînes.

**Adhésion : même lecture que la 44** (`recalc-planning.sh` l.274-301) — à recopier sans divergence, avec `O_NOFOLLOW` :
```python
chemin = os.path.join(planning, "config.json")
...
descripteur = os.open(chemin, os.O_RDONLY | SANS_SUIVI_DE_LIEN)
...
resultat["adherente"] = isinstance(resultat["declaree"], str) and resultat["declaree"] == SCHEMA_ADHESION
```
avec `SCHEMA_ADHESION = "cycles-v1"` (l.71) et `SANS_SUIVI_DE_LIEN = getattr(os, "O_NOFOLLOW", 0)` (l.73).

**Frontmatter (G1, rôle)** : `recalc-planning.sh` `lire_frontmatter` l.145-200 et `_lire_frontmatter_fichier` l.245-258 (grammaire minimale, `("absent"|"invalide:…"|"ok", données)`). Le module n'est pas importable (heredoc) : **réimplémenter** ~60 lignes et prouver l'accord par contrôle croisé (Pattern 6 de la recherche).

**États dérivés de G1** : `recalc-planning.sh` l.1338-1355 (Φ2 `à cadrer` = pas de `CADRAGE.md` ; Φ3 `registre-invalide` ; Φ4 `en cadrage` = ligne `structurante: oui` sans `statut`), `lire_registre` l.932-950. G1 refuse seulement `à cadrer` et `en cadrage` (recommandation F5/A7 : jamais l'`indéterminé`), et seulement sous `cycles/*/phases/<unité>/PLAN.md` ou `…/plans/<unité>/PLAN.md`.

**Marqueurs de code (G7)** — liste **dupliquée** dans le Python, avec un test qui compare au texte du détecteur (`plugin/planning-core/scripts/detect-gsd-engine.sh` l.175-181) :
```
  for f in package.json go.mod Cargo.toml pyproject.toml pom.xml build.gradle \
           build.gradle.kts composer.json Gemfile tsconfig.json Package.swift; do
    [ -f "./$f" ] && return 0
  done
  # Projet Xcode : dossier *.xcodeproj à la racine.
  for f in ./*.xcodeproj; do [ -d "$f" ] && return 0; done
```

**Classification du rôle (I5/I6)** — prédicats à reproduire, `plugin/conductor/scripts/check-agents.sh` :
- I6 (manager) l.893-906 : `if not dispatch: return []` ; `if str(fm.get("vf-internal", "")) == "true": return []`.
- I5 (juge) l.908-921 : `disallowed = bare_tokens(fmlines, "disallowedTools")` ; `if not ("Write" in disallowed and "Edit" in disallowed): return []` ; `if dispatch: return []`.
- Le tokenizer d'allowlist (`extract_raw_field`, `tokenize_field`, `parse_token`, `allowlist_agents`) gère les parenthèses imbriquées : **ne pas** le simplifier en `split(",")`.
- Indexation des définitions par `name:` du frontmatter avec repli sur le nom de fichier (`agent_display_name`, `check-agents.sh:755`) ; `agent_type` **normalisé** (casse, séparateurs) ; nom ambigu ou inconnu = « Tous » seulement (P45-D-05b, P45-D-11).

**Erreurs et journal d'observation** : ne journaliser que gate, chemin **relatif**, raison, horodatage — jamais `content` ni `command` (Pitfall 7). Le répertoire du journal d'observation se dérive comme celui des marqueurs de santé : `${VF_GUARD_HEALTH_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/vibeflow/guard-health}` (`plugin/_internal/lib/vf-portable.sh` `vf_guard_unavailable`, `check-guard-health.sh` l.84). Choix ouvert A8 : à confirmer.

**Table d'armement** : constante du code livré, jamais un fichier du lab (P45-D-03a). Voir « No Analog Found ».

**Ne pas lire de variable d'environnement qui change le comportement** (anti-pattern de la recherche, spec §5.2) : contraste avec `guard-driver-lock.sh` qui lit `VF_DRIVER_LOCK_OVERRIDE` (l.469) — ne pas copier cet interrupteur.

---

### Commande enregistrée (champ `command` de l'entrée PreToolUse — couche shell fail-closed)

**Analogue de forme d'entrée :** `plugin/conductor/hooks/hooks.json` l.5-21 (groupe `PreToolUse` à `matcher`, entrée `type: command`).
**Source de vérité du contenu :** `45-RESEARCH.md` § « Code Examples — La commande enregistrée » (commande testée : 39 cas × 6 shells, 936 appels E2E). **Copier telle quelle, ne pas réécrire.** Le squelette est :
```sh
S={{VF_SCRIPTS}}/planning-hook.sh
I=$(cat); R=1; O=
if [ -f "$S" ]; then O=$(printf '%s' "$I" | bash "$S"); R=$?; fi
if [ "$R" -eq 0 ]; then [ -z "$O" ] || printf '%s\n' "$O"; exit 0; fi
case $I in *'"tool_name":"Write"'*|*'"tool_name":"Edit"'*|*'"tool_name":"NotebookEdit"'*) ;; *) exit 0 ;; esac
...
printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"[planning-core] hook central indisponible …"}}'
exit 0
```
Contraintes non négociables (F2, F3, Pitfall 1-2) :
- forme **shell** (`bash {{VF_SCRIPTS}}/…`-like, jeton `{{VF_SCRIPTS}}` seul, jamais `{{VF_BASH}}`) : la forme exec va dans `settings.local.json` (`merge-hooks.sh:362-367`) et n'a pas de shell pour porter le test de présence ;
- le script est lancé **en fils** (`O=$(… | bash "$S")`), jamais `exec` ;
- **aucune** expansion `${v#*motif}` sur la charge utile (quadratique sous bash 3.2 : 95 s à 254 Ko) ;
- POSIX seul : pas de `[[ ]]`, `local`, `${//}`, `$'…'` ;
- message de repli **statique ASCII** (aucune valeur dynamique interpolée dans du JSON en shell) ;
- l'inline ne doit citer **aucun autre** `*.sh`/`*.py` que le script du hook (ils entreraient dans la dédup et le retrait de `merge-hooks.sh`, `SCRIPT_RE` l.322).
Dans `hooks.json`, le champ est JSON-échappé : **générer** l'entrée par `json.dumps`, ne pas l'éditer à la main, puis relire par `json.load` et comparer à la commande de référence de la suite.

---

### `plugin/planning-core/hooks/hooks.json` (config, event-driven)

**Analogue :** `plugin/conductor/hooks/hooks.json` (même dépôt, même installeur) et l'état actuel de `plugin/planning-core/hooks/hooks.json` l.1-35.

**Entrée PreToolUse à matcher combiné** (`plugin/conductor/hooks/hooks.json` l.13-19) :
```json
{
  "matcher": "Bash|Write|Edit",
  "hooks": [
    { "type": "command", "command": "{{VF_BASH}}", "args": ["{{VF_SCRIPTS}}/guard-driver-lock.sh"] }
  ]
}
```
La 45 diffère : `matcher` = `Write|Edit|NotebookEdit|Bash|Agent|Task` (liste de noms exacts, P45-D-09), `command` de forme shell (inline), clé `"timeout": 20` explicite (préservée par le merge, sondé). **Une seule entrée** pour le script : deux entrées sous deux matchers se purgent mutuellement (`guard-driver-lock.sh` en-tête l.8-14 ; `HOOKS-CONTRAT-SORTIE.md` §4 l.90-96).

**Entrée SessionStart du canary** — deux formes existantes dans le même module :
- forme shell advisory de planning-core (l.7-11) : `{ "type": "command", "command": "bash {{VF_SCRIPTS}}/check-planning-state.sh --defer-to-gsd || true" }` ;
- forme exec de la famille santé (conductor l.32) : `{ "type": "command", "command": "{{VF_BASH}}", "args": ["{{VF_SCRIPTS}}/check-guard-health.sh", "--hook"] }`.
Recommandation : forme shell `… --hook || true` comme le reste de planning-core (le canary signale, ne bloque jamais ; la forme exec l'enverrait en `settings.local.json`). Ajouter au groupe `matcher: "startup"` existant (l.4-12), **sans** nouveau groupe.

**Chore induit** : `description` du fichier à étendre (elle documente chaque entrée). Le décompte `HOOKS-CONTRAT-SORTIE.md` passe de 29 à 31 (voir ci-dessous).

---

### `plugin/planning-core/scripts/check-gates-alive.sh` (canary de session, batch)

**Analogue :** `plugin/conductor/scripts/check-guard-health.sh` (même famille, P45-D-20).

**Traduction du silence interne vers le harnais** (l.124-133) :
```bash
hook_exit() { # <code>
  local code="$1"
  if [ "$HOOK" -eq 1 ] && { [ "$code" -eq 3 ] || [ "$code" -eq 4 ]; }; then
    exit 0
  fi
  exit "$code"
}
```
Contrat de codes à reprendre (en-tête l.28-46) : 0 = signal (une seule ligne stdout), 3 = SAIN, 4 = INDÉTERMINÉ (rien vérifié, jamais un vert de complaisance), 64 = usage. Sous `--hook`, stdout est **strictement vide** hors signal (`HOOKS-CONTRAT-SORTIE.md` §3).

**Marqueur d'auto-indisponibilité** (`report_self_unavailable`, l.141-158) et **cascade Python locale** (`py_resolve_local`, l.169-180) : reproduites localement, jamais en sourçant `vf-portable.sh` (justification en tête de fichier).

**Répertoire de santé** (l.84) : `DEFAULT_HEALTH_DIR="${VF_GUARD_HEALTH_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/vibeflow/guard-health}"` — même dérivation que l'écrivain (`vf_guard_unavailable`) : un écart rendrait le lecteur aveugle.

**Ce que le canary ajoute** (aucun analogue : `check-guard-health.sh` n'exécute aucun garde) : rejouer la commande **posée** sous les modes de RESEARCH « Rejeu du canary », sur un lab jetable dans un `mktemp -d`. Il itère la table d'armement et exige un cas par gate armé. Ne jamais bloquer (P45-D-20 : « signale sans bloquer »).

---

### Commande de verdict (utilitaire, file-I/O atomique)

**Analogue :** `plugin/planning-core/scripts/recalc-planning.sh` — parse d'arguments l.30-37, écriture atomique l.1700-1716, jeton injectif l.1529-1560.

**Arguments** (patron l.30-37) :
```bash
for arg in "$@"; do
  case "$arg" in
    --planning=*) PLANNING_DIR="${arg#*=}" ;;
    --read-only)  READ_ONLY=1 ;;
    -h|--help)    grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[recalc-planning] argument inconnu : $arg" >&2; exit 64 ;;
  esac
done
```
**Écriture atomique** (l.1700-1716) : `tempfile.mkstemp(dir=dossier, prefix=".tmp-…")`, `os.fchmod(fd_tmp, 0o644)`, `os.replace(chemin_tmp, chemin)`, fermeture du descripteur non adopté sur exception.
**Hash** : `hashlib.sha256` (déjà importé l.15) — jamais `sha256sum`/`shasum` (divergence GNU/BSD).
**Format de sortie** : gabarit `plugin/planning-core/references/templates/cycles/VERDICT.template.md` (clés `juge`, `hash`, `tentative`, `score`, `constats: - critere / resultat`) et `modele-cycles.md` § `VERDICT.md` l.354-372. La commande recopie `tentative` **telle quelle** et refuse d'écraser un `VERDICT.md` existant sans `tentative` incrémentée. Artefact haché : hypothèse A3 (le `PLAN.md` de l'unité), **à confirmer** avant de figer (la 46 vérifie).
**Ce que la commande n'est pas** : un `Write`/`Edit` — c'est une commande Bash, donc hors du périmètre de G5/G6 (Pattern 8). F8 : trois juges sur quatre n'ont pas `Bash` ; la commande est lancée par le manager.

---

### Commande de dérogation + journal append-only (file-I/O ajout seul)

**Analogue :** `recalc-planning.sh` `ajouter_au_journal` l.1589-1602 et `_jeton_journal` l.1529-1560.

**Ajout seul, permissions forcées** (l.1595-1600) :
```python
fd_journal = os.open(chemin, os.O_WRONLY | os.O_APPEND | os.O_CREAT | SANS_SUIVI_DE_LIEN, 0o644)
os.fchmod(fd_journal, 0o644)
texte = "".join(ligne + "\n" for ligne in lignes)
with os.fdopen(fd_journal, "a", encoding="utf-8") as fh:
    fh.write(texte)
```
**Encodage pourcent injectif de chaque champ** (l.1546-1560, à réutiliser tel quel pour qui/canal/date/gate/chemin/raison) :
```python
for caractere in str(brute):
    if caractere == "%" or caractere == "=" or caractere.isspace() or not caractere.isprintable():
        for octet in caractere.encode("utf-8"):
            morceaux.append("%{:02X}".format(octet))
    else:
        morceaux.append(caractere)
```
avec l'exception explicite (jamais un `assert` nu, IN-02) si `repli` est vide. **Deux implémentations** de cet encodeur (script de hook et `recalc`) : prévoir un contrôle croisé si la dérogation est lue par le hook.
**Nom du fichier** : ne pas réutiliser `DEROGATION.md` (pris par P44-D-07, Pitfall 8). Exemple : `derogations-gates.log`, à ajouter à `NOMS_MODELE_RACINE_FICHIERS` (`recalc-planning.sh` l.752-755) sinon il sort en « Hors modèle » de `INDEX.md` (F7).
**Refus de placeholder** : vide, `TODO`, `xxx`, `…`, `<…>`, **après** normalisation Unicode (`unicodedata` déjà importé l.20). Aucune horloge, aucune condition d'urgence (spec §5.2 règle 2) ; usage unique par (gate, chemin) recommandé, consommation par ligne ajoutée.

---

### `plugin/planning-core/scripts/recalc-planning.sh` — modification GATE-14 et racine (service, batch)

**Analogue :** lui-même. Points d'insertion vérifiés le 2026-09-29.

**Site 1 — `detection_gsd`, branche code 2** (l.680-684) :
```python
    if code == 2:
        # Signalement de MIGRATION (socle planning-core + signal de code) : refus d'écriture,
        # ...
        return "non-concluante"  # motif-code-2-migration
```
→ rendre un verdict distinct (ex. `"migration"`), sans toucher au reste de la fonction (garde de lecture l.635-651, environnement maîtrisé, codes 0/1/3, repli générique). Le motif `# motif-code-2-migration` est **le motif unique** du mutant `CODE2-MIGRATION` : le conserver sur la ligne modifiée, ou mettre à jour le mutant.

**Site 2 — appelant** (l.1841-1858) :
```python
    adhesion = verifier_adhesion(planning_abs)
    if not adhesion["adherente"]:
        print("[recalc-planning] refus d'écriture (P44-D-02) : ...", file=sys.stderr)
        sys.exit(2)

    verdict_gsd = detection_gsd(detect_sh, planning_abs, racine_lab)
    if verdict_gsd != "non-gsd":
        print("[recalc-planning] refus d'écriture (P44-D-02a) : ...", file=sys.stderr)
        sys.exit(3)
```
→ laisser passer `"migration"` (`if verdict_gsd not in ("non-gsd", "migration"):`). **L'adhésion est testée avant** : « sans adhésion → exit 2 inchangé » et « adhésion + détecteur 0 → exit 3 » sont structurellement préservés.
**Contraintes** : `detect-gsd-engine.sh` et `workstream-policy.sh` octet pour octet inchangés (P45-D-02b) ; mettre à jour la docstring l.587-604 et la table des codes de `modele-cycles.md:54-66` (ligne « **2** … `non-concluante` … **refusée** »), la prose l.64-71, le `README` et le `CHANGELOG`.

**Site 3 — `NOMS_MODELE_RACINE_FICHIERS`** (l.752-755) : ajouter le nom du journal de dérogation ; c'est le même fichier que GATE-14 : **sérialiser** les tâches (F7).

---

### Outil de rejeu lecture seule (utilitaire, batch / transform)

**Analogue :** `aides.py` dans `plugin/planning-core/scripts/tests/test-recalc-planning.sh` l.123-436 (`empreinte`, `materialiser`, `coureur`) et `recalc-planning.sh --read-only`.

**Empreinte d'arbre** (l.264-288) — à reprendre pour la preuve « aucune écriture » (sha256 avant/après, comparée par `cmp`, jamais `diff`) :
```python
def empreinte(dossier):
    resultat = []
    for racine, dossiers, fichiers in os.walk(dossier, followlinks=False):
        dossiers.sort()
        ...
                with open(chemin, "rb") as fh:
                    h = hashlib.sha256(fh.read()).hexdigest()
                resultat.append(("fichier", rel, h))
    resultat.sort(key=lambda t: t[1])
    return resultat
```
Contraintes (P45-D-21, F4-F5-F10) : chemins des labs en **argument** (jamais `~/…` dans le code livré ni en CI) ; travail sur une **copie** dans un dossier temporaire où l'adhésion est simulée (jamais un interrupteur dans le script livré) ; copier seulement `.planning/`, `.claude/` et les marqueurs de code (pas `node_modules/`) ; aucun `git` lancé ; rapport machine-lisible `gate | chemin | attendu | obtenu | raison` ; distinguer faux refus de conception (fichier hérité, F5) et bug.
**Emplacement** : `plugin/planning-core/scripts/` (un `.sh` avec Python embarqué, comme `recalc-planning.sh` : l'installeur ne pose pas de `.py`). Attention : `scripts/*.sh` est posé chez l'utilisateur ; si l'outil ne doit pas l'être, le mettre sous `scripts/` racine du dépôt — à trancher (voir « No Analog Found »).

---

### `plugin/planning-core/scripts/tests/test-planning-hook-registered.sh` (test, mutation)

**Analogues :** `test-recalc-planning.sh` (helpers, mutants), `scripts/tests/test-hook-exit-parc.sh` (deux flux séparés, `cmp`, compteur anti-vert-à-vide).

**Helpers `ok`/`ko` avec assertion/attendu/obtenu** (`test-recalc-planning.sh` l.96-104) :
```bash
pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() {
  echo "  ✗ $1"
  echo "    assertion : $2"
  echo "    attendu   : $3"
  echo "    obtenu    : $4"
  fail=$((fail+1))
}
```
**Racines et interpréteur** (l.74-87, à reprendre) : `TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`, `SCRIPTS_DIR="$(cd "$TESTS_DIR/.." && pwd)"`, `WORK="$(mktemp -d)"` + `trap 'rm -rf "$WORK"' EXIT`, cascade `PYBIN` avec rejet `*WindowsApps*`.
**Deux flux, jamais fusionnés** (`test-hook-exit-parc.sh` l.71-96 `run_case`) : stdout et stderr dans deux fichiers distincts, code assertion séparée, mode `empty|nonempty|any`. C'est le moyen de prouver « octet vide + exit 0 » pour GATE-10.
**Anti-vert-à-vide** (l.62-64 `DECLARED_TARGETS`) : compteur déclaré en dur, comparé au nombre de cas réellement exercés ; vidé, la suite échoue au lieu de passer au vert.
**Validation de sortie** : `json.loads` (jamais `jq`, HOOKS-CONTRAT §3 bis) : `printf '%s' "$out" | python3 -c 'import json,sys; d=json.loads(sys.stdin.read()); assert d["hookSpecificOutput"]["permissionDecision"]=="deny"'`.
**Construction des payloads** (`plugin/conductor/scripts/tests/test-guard-driver-lock.sh` l.60-72 : `json.dumps` via `python3 -c`) : fabriquer les payloads du corpus adverse avec `json.dumps` (compact, ordre des clés du harnais : `session_id, transcript_path, cwd, prompt_id, permission_mode, [agent_id, agent_type], hook_event_name, tool_name, tool_input, tool_use_id`). Ne pas insérer de fixture JSON écrite à la main avec des chemins machine.
**Portabilité CI** (P45-D-16, R4) : pas de `stat -f`/`stat -c` (utiliser `mode_octal()` par `os.stat`, l.94), pas de `sed -i` (le patron `sed -i.bak` de `test-guard-driver-lock.sh` l.74-80 est **à ne pas copier**), pas de `timeout` (chronométrer par `date +%s` ou `perf_counter`), `cmp -s` jamais `diff`.
**Mutants à motif unique** : voir `make_recalc_mutant` ci-dessous.

---

### `plugin/planning-core/scripts/tests/test-planning-gates.sh` + `fixtures/gates-banc.txt`

**Analogues :** `test-recalc-planning.sh` et `plugin/planning-core/scripts/tests/fixtures/recalc-planning-banc.txt`.

**Banc texte (grammaire)** (`recalc-planning-banc.txt` l.1-15, l.17-45) :
```
@@ lab traceur

@@ fichier .planning/config.json
{"planning_version": "cycles-v1"}

@@ fichier .planning/cycles/01-traceur/phases/01-livree/CADRAGE.md
---
inconnues:
  - id: I-01
    ...
---
```
Directives existantes : `@@ lab <nom> [jumeau-de=<lab>]`, `@@ dossier`, `@@ fichier`, `@@ fichier-dehors`, `@@ lien <chemin> -> <cible>` (`DEHORS/…` vers un bac frère hors lab), `@@ attendu <unité> :: <état> [:: <raison>]`, `@@ attendu-hors-modele`. Étendre par `@@ ecriture <outil> <chemin> :: doit-passer|doit-refuser [gate]` (RESEARCH R3). Le banc est un **fichier texte** : l'installeur pose `fixtures/` à plat (`vibeflow-update.sh:1987-2054`), aucun sous-dossier, aucun dossier `.planning/` versionné.
**Matérialiseur / coureur** : `aides.py` l.123-436 (parseur `parser_banc` l.140, `materialiser` l.228, `empreinte` l.264, `coureur` l.302, `couverture` l.360). Soit **étendre** ce fichier, soit le **partager** (extraction dans une aide commune) ; le heredoc `PY_AIDES_EOF` est propre à `test-recalc-planning.sh`. Rejets à conserver : `_valider_chemin_banc` (l.133-137 : pas de `/`, `~` initial ni `..`).
**Jumeau négatif** (`jumeau-de=`) et **couverture** (`couverture()` l.360-396) : une couverture exige, pour chaque cas, un positif et un jumeau opposé sur la même entrée. Reprendre ce contrôle pour « chaque gate a un cas `doit-passer` et un cas `doit-refuser` ».

**Mutants** (`test-recalc-planning.sh` l.1444-1525) — copier tel quel (renommer `RECALC` en script du hook et le marqueur du heredoc) :
```bash
make_recalc_mutant() { # <id> <motif> <remplacement>
  ...
  n="$(grep -Fc -- "$motif" "$orig")"
  if [ "$n" -ne 1 ]; then
    komut "$id" "motif fixe unique dans recalc-planning.sh" "exactement 1 occurrence" "MOTIF AMBIGU OU ABSENT (n=$n)"
    return 1
  fi
  ...
  MUT_MOTIF_ENV="$motif" MUT_REPL_ENV="$remplacement" awk '
    index($0, ENVIRON["MUT_MOTIF_ENV"]) {
      match($0, /^[ \t]*/)
      print substr($0, RSTART, RLENGTH) ENVIRON["MUT_REPL_ENV"]
      next
    }
    { print }
  ' "$orig" > "$tmp"
  cmp -s "$tmp" "$orig" && komut … "NON OPPOSABLE (identique)"
  bash -n "$tmp"
  # compilation du corps Python extrait du heredoc :
  awk '/<<.PY_RECALC_PLANNING_EOF.$/{f=1;next} /^PY_RECALC_PLANNING_EOF$/{f=0} f' "$tmp" > "$pybody"
  "$PYBIN" -c 'import sys; f=sys.argv[1]; compile(open(f, encoding="utf-8").read(), f, "exec")' "$pybody"
```
et les issues (l.1498-1508) :
```bash
okmut() { echo "  ✓ MUT-$1 TUÉ — $2"; pass=$((pass+1)); }
komut() { echo "  ✗ MUT-$1 NON TUÉ"; echo "    assertion : $2"; echo "    attendu (original) : $3"; echo "    obtenu (mutant)     : $4"; fail=$((fail+1)); }
```
et le prédicat de plantage `_verifier_plantage` (l.1514-1525). **Exemple d'utilisation complet d'un mutant** (l.1527-1548, MUT-ADHESION) : motif unique + remplacement, deux labs (cas et témoin), comparaison des codes `RC_T` (original) et `RC_M` (mutant), `okmut` si différents, `komut … "(mutant non opposable)"` sinon.
Mutations minimales attendues (RESEARCH R1/Validation) : « ignorer l'adhésion » (M5/MI6, GATE-10), code de sortie du script ignoré, test de présence retiré, `exit 2` au lieu de deny (DIV-2), décodage de `\"` retiré, « le plus proche gagne » retiré, 1re occurrence → dernière, TIGHT → LOOSE, filtre d'outil retiré.

---

### `plugin/planning-core/scripts/tests/test-recalc-planning.sh` — réécriture GATE-14 (modification)

**Analogue :** lui-même. Tests à réécrire (mesurés) :

| Test | Lignes | Aujourd'hui | Après GATE-14 |
|---|---|---|---|
| `oracle_differentiel` (table de codes) | 2697-2712 | `0\|2) code_attendu=3` | scinder : `0) 3`, `2) 0` (le lab `traceur` est adhérent) |
| appel `oracle_differentiel socle-signal setup_socle_signal` | 2719 | attend 3 | attend 0 (écrit) |
| `matrice_env socle-signal setup_socle_signal 3` | 2809 | 3 | 0 |
| `R-LABS-ADVERSES` (3 divergences `package.json`/`*.xcodeproj` en lien, `STATE.md` UTF-8 invalide) | 2864-2925 | 3, STATE.md intact | le détecteur voit un signal → 2 → écriture : re-poser attendus et invariant |
| `R-CODE2-MIGRATION` | 2942-2964 | 3 + message P44-D-02a + empreinte identique | adhésion + détecteur 2 : 0 et écrit ; **jumeaux** : sans adhésion → 2 (empreinte identique, cache compris) ; détecteur 0 → 3 |
| `MUT-CODE2-MIGRATION` | 2982-2992 | remplace `return "non-concluante"  # motif-code-2-migration` par `return "non-gsd"` | muter la nouvelle branche (renvoyer `non-concluante` ou `non-gsd`) |
| `R-GSD-HOME-SIGNAL (a)/(b)` | 3900-3940 | 3 | re-poser |
| `R-LOT8-TEMOIN` | 3447-3465 (même table `0\|2) code_attendu=3`) | 3 | scinder aussi |

**Fixtures de scénario existantes à réutiliser** (l.2673-2691) :
```bash
setup_socle_signal() {
  printf -- '---\nplanning_version: "2.0"\n---\n' > "$1/.planning/STATE.md"
  printf '%s' '{}' > "$1/package.json"
}
```
et `materialiser traceur "$DIR"` (lab adhérent `cycles-v1`, banc l.17-19). Chaque branche de P45-D-02a : un cas + son jumeau négatif + sa mutation rouge tracée (`okmut`/`komut`). Preuve « rien touché, cache compris » : `empreinte "$DIR" > avant.txt` … `cmp -s avant.txt apres.txt` (R04 l.510-513).

---

### `plugin/_internal/tests/test-planning-hook-installed.sh` (test as-installed)

**Analogue :** `plugin/_internal/tests/test-vibeflow-update.sh` T10 (l.507-561) et `check_exec_settings` (l.462-505).

**Installation réelle dans un lab jetable** (l.217-221, 515-520) :
```bash
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
prepare_module "$CACHE" "planning-core"        # l.60-68 : cp -r "$REPO/$mod/." "$cache/$mod/"
(cd "$LAB" && VF_SCOPE=project VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" install planning-core >/dev/null 2>&1)
```
Puis lire `settings.json` **posé** (la forme shell y va, pas `settings.local.json`), extraire la commande de l'entrée `PreToolUse`, la rejouer (RESEARCH « Rejeu du canary ») :
```bash
printf '%s' "$PAYLOAD_DENY" | env CLAUDE_PROJECT_DIR="$LAB" PATH="$PATH_SANS_PYTHON" /bin/sh -c "$CMD"
```
attendu : rc 0, stdout = un objet JSON, `permissionDecision == "deny"` (`json.loads`). Le préfixe posé est `"$CLAUDE_PROJECT_DIR"/.claude/scripts` (`vibeflow-update.sh:1831-1833`).
**Isolation** (`test-vibeflow-update.sh` l.30-52) : `HOME` + cache `mktemp` ; snapshot du vrai `~/.claude` avant/après en ceinture-bretelles (sous-chemins que l'engine écrit seulement, pas tout `~/.claude`).
**Garde anti-vert-à-vide** (T10b l.551-561, `check_exec_settings`) : 0 entrée posée est TOUJOURS un échec ; reprendre le principe (« la suite doit rougir si `settings.json` ne porte aucune entrée du hook »), avec un test négatif qui vide le fichier.
**Modes** : script présent · script absent (`CLAUDE_PROJECT_DIR` vide) · `python3` absent (`PATH` = liens vers `bash grep head cat sh`) · plantage `exit 1` et `exit 2` · payloads `Agent` **et** `Task` · fil principal · `agent_type:"plugin:nom"` · lab **dev** dans les mêmes modes (attendu : silence) · désinstallation sans entrée résiduelle (T10-uninstall l.528-545).
**CI** : découverte automatique (`ci.yml:218`), sans toucher `ci.yml` (une PR qui touche `ci.yml` exige la revue code owner). Sous `bash -e {0}` : piège `grep -q X && {…}` (`ci.yml:552`).

---

### `scripts/tests/test-role-hook-vs-check-agents.sh` (test croisé, oracle différentiel)

**Analogues :** `scripts/tests/test-hook-exit-parc.sh` (suite de parc multi-modules, l.1-20 : « Outillage du DÉPÔT… c'est ce qui l'autorise à asserter sur des scripts de PLUSIEURS modules ») et `plugin/conductor/scripts/tests/test-check-agents.sh` (appel `bash "$CHECK" --file "$f" --skills-dir="$SK"`, l.403-404 ; `--strict --file` l.2929).

**Recette de l'oracle** (RESEARCH « Oracle différentiel », sondée) : pour chaque définition d'agent (31 fichiers : `plugin/*/agents/*.md` + `plugin/*/AGENT.md`), deux variantes jetables sous `mktemp -d` — (a) sans la ligne `omitClaudeMd:` ; (b) sans `SendMessage` dans `tools:` ; lancer `check-agents.sh --file <variante>` ; « `invariant I5` apparaît en (a) » ⇔ juge ; « `invariant I6` apparaît en (b) » ⇔ manager. Comparer `rôle(hook)` à cet oracle pour chaque agent **et** chaque fixture. Une mutation du prédicat du hook (« juge = Write seul retiré ») doit rendre le contrôle **rouge**.
**Découvertes de la recherche à couvrir** : F8 (3 juges sur 4 sans `Bash`), F9 (4 workers dispatcheurs : `vf-auditer`, `vf-coder`, `vf-reviewer`, `vf-test-orchestrator`, à la fois `vf-internal: true` et allowlist `Agent(...)` non vide). Les tests **ne tranchent pas** ces arbitrages ; ils nomment les cas.
**Surface G-2** (`scripts/check-gate-touche.sh:24-37`) : cette suite est sous `scripts/tests/test-*.sh`, donc **dans** la surface machine : tout commit qui la touche porte `Gate-Touche: scripts/tests/test-role-hook-vs-check-agents.sh — <raison ≥ 10 caractères>`. `plugin/planning-core/**` est hors surface machine, mais poser le trailer sur tout commit qui touche `hooks.json` ou le script du hook reste la lecture conservatrice (CLAUDE.md « Marqueur »).
**Mutants sous `mktemp -d` uniquement**, discrimination par `cmp` (jamais `diff`), motif identique aux suites de parc : `assert_mutant_differs` (`test-hook-exit-parc.sh` l.140+) échoue bruyamment si le motif est introuvable.

---

### Suites de l'outil de rejeu et du canary de session

- **Rejeu** : `test-recalc-planning.sh` R04/R07 (l.510-513, 581-583) pour le motif « empreinte avant/après, `cmp -s` » ; mutation « l'outil écrit dans le lab » rouge (RESEARCH Wave 0). Aucun `git`, aucune écriture dans les chemins passés en argument.
- **Canary de session** : `plugin/conductor/scripts/tests/test-check-guard-health.sh` (isolation par `--dir=<fictif>` sous `mktemp -d`, préflight anti-fixture-réelle l.29-40, assertions stdout et code séparées) ; chaque cas asserte stdout **et** code dans deux variables distinctes.

---

### Chores documentaires et de version

**`docs/HOOKS-CONTRAT-SORTIE.md`** — §4 (l.78-103) et §5 (l.185-195) : ajouter les deux entrées (PreToolUse du hook central, SessionStart du canary), passer le recomptage de 29 à 31 **dans l'assertion et le texte ensemble** (« l'inventaire et l'assertion ensemble, jamais l'un sans l'autre », l.100-103), mettre `planning-core` à 8 dans le tableau §5. La commande de recomptage fait foi :
```bash
python3 -c "import json,glob; n=sum(len(h.get('hooks',[])) for f in sorted(glob.glob('plugin/*/hooks/hooks.json')) for gs in json.load(open(f))['hooks'].values() for h in gs); print(n); assert n==29, n"
```
Garde machine : `plugin/dev-orchestrator/scripts/tests/test-check-hook-paths.sh` T12 (l.395-413) lit `assert n==<N>` dans le document et le compare au parc réel ; un écart d'exactement +1 est toléré comme « transitoire » (skip), tout autre écart rougit : mettre à jour **dans le même commit** que `hooks.json`. Documenter la ligne de la table (colonne « Classement ») : **bloquante par décision JSON**, jamais par exit 2 ; et signaler que `guard-planning-updated.sh` reste l'exception exit 2 (P45-D-19).
Note : le document dit « 29 entrées » alors que les tableaux numérotent jusqu'à 29 avec des trous (#27-29) ; ne pas corriger la numérotation, ajouter #30/#31.

**`plugin/conductor/references/workstream-planning-consumers.md`** — le lint `plugin/conductor/scripts/check-planning-consumers-registered.sh:162-166` exige qu'un `*.sh` suivi hors `tests/` dont une ligne porte `.planning/workstreams`, ou `.planning/` **sur la même ligne** que `STATE.md`, `ROADMAP.md` ou `REQUIREMENTS.md`, figure au recensement. Le script du hook nommera `STATE.md`/`INDEX.md` : composer les chemins **à l'exécution** (jamais `.planning/…STATE.md` sur une seule ligne), ou recenser (catégorie `c`/`a2`). Rejouer `bash plugin/conductor/scripts/check-planning-consumers-registered.sh` après chaque écriture du script.

**Bump `planning-core` v2.8.0 → v2.9.0** (P45-D-18, triade + en-tête) :
- `plugin/planning-core/VERSION` : `v2.8.0` → `v2.9.0` ;
- `plugin/planning-core/module.json` : `"version": "v2.8.0"` → `"v2.9.0"` (le champ `description` cite le moteur : l'étendre) ;
- `plugin/planning-core/README.md` l.10 : `**Type** : … · **Version** : v2.8.0 · **Dépend de** : rien.` → v2.9.0 (gate `scripts/check-version-sync.sh` §8, l.116-130 : ligne `**Version**` ↔ `VERSION` du module) ;
- `plugin/planning-core/CHANGELOG.md` : nouvelle entrée en tête, format de l'existante (`## [v2.8.0] — 2026-09-28 (…, Phase 44)` puis `**Minor** (nouvelle capacité) :` puis puces en gras).
**Jamais** de bump de `VERSION` racine, de `plugin/.claude-plugin/plugin.json`, de `.claude-plugin/marketplace.json`, ni d'historique de `README.md` (P45-D-18, CLAUDE.local.md : aucune release avant la clôture de `fiabilite-v1.0`). Si une PR de `fiabilite` bumpe aussi `planning-core`, renuméroter la 45.

**Compteurs de suites `README.md` et `README.fr.md`** — `scripts/check-version-sync.sh` §9 (l.131-139) compare `grep -o '[0-9][0-9]* suites'` (première occurrence) au `find plugin scripts -path '*/tests/test-*.sh'`. Valeur mesurée aujourd'hui : **92** partout. Chaque **nouvelle** suite `test-*.sh` ajoute 1 : `test-planning-hook-registered.sh`, `test-planning-gates.sh`, `test-planning-hook-installed.sh`, `test-role-hook-vs-check-agents.sh`, suite du rejeu, suite du canary de session = **+6** si toutes créées, soit 98 ; **recompter** par la commande (`find … | grep -c .`) au moment du commit, jamais recopier. Les deux README changent ensemble. La première occurrence est en ligne 142 de chaque README (« 92 suites in CI »).

**`modele-cycles.md`** : à compléter (P45-D-03, P45-D-05b, P45-D-10, P45-D-14) — tables d'armement (G6/G5/G1/G7/rôle : observation ou armé), prédicat littéral de « habité » (G7), limite « Bash non couvert », ordre de résolution `agent_type` → définition, limites déclarées de la couche shell (RESEARCH R1, points a-f), format et emplacement du journal de dérogation ; remplacer la section « Hors de cette phase » l.685-695 (les lignes « Aucun hook ni gate câblé » et « G6 arrive en Phase 45 » deviennent fausses).

**`REQUIREMENTS.md` du compartiment** : poser `GATE-01..15` avant le plan (P45-D-17) sur le format des lignes `MOTR-*` du même fichier.

## Shared Patterns

### Refus : `permissionDecision: deny` + exit 0, jamais exit 2
**Source :** `plugin/conductor/scripts/guard-driver-lock.sh` l.22-25 et l.535-544 ; `docs/HOOKS-CONTRAT-SORTIE.md` §1, §3 bis.
**Apply to :** planning-hook.sh, commande enregistrée (message statique), commandes de repli. Un seul objet JSON par exécution ; validation par `json.loads`.
**Exception connue, hors 45 :** `plugin/planning-core/scripts/guard-planning-updated.sh` (Stop, exit 2 voulu, P45-D-19) — ne pas normaliser.

### Fail-closed **dans un lab adhérent seulement**, fail-open ailleurs
**Sources à NE PAS copier pour la gestion d'erreur :** `guard-driver-lock.sh` l.418-420 (« imparsable → fail-open silencieux »), `guard-agent-write.sh` l.19-20 (« Fail-open : toute erreur interne → allow »), `guard-file-size.sh` l.165-166 (« fail-open : toute erreur interne = allow »). Elles sont fail-open par doctrine (ADR-031, anti-accident). La 45 est le premier garde fail-closed du dépôt : le motif est propre à cette phase (R1 + Pattern 3), à ne pas confondre avec la « limite de fond » de ces gardes.
**Ce qui reste commun :** l'observabilité de « n'a pas pu tourner » — `vf_guard_unavailable` (code 17, marqueur de santé) pour un hook **advisory** ; pour le hook central, l'indisponibilité en lab adhérent **est** un deny statique.

### Résolution de l'interpréteur Python (ADR-054)
**Source :** `recalc-planning.sh` l.49-61 ; `guard-agent-write.sh` l.41-45 ; `check-guard-health.sh` `py_resolve_local` l.169-180 (avec `py -3`).
**Apply to :** planning-hook.sh, commandes verdict/dérogation, outil de rejeu, suites. Détection du stub Microsoft Store par **chemin** (`*WindowsApps*`), jamais par exécution.

### Racine du lab dérivée du chemin écrit, jamais de `$CLAUDE_PROJECT_DIR`
**Source :** P45-D-12, `45-SCOUTING.md` A.5a. Contre-exemple à ne pas suivre : `guard-driver-lock.sh` résout par `payload.cwd` + `os.path.realpath(cwd)` (l.448) — acceptable pour un dispatch, pas pour une écriture. Le plus proche ancêtre contenant `.planning/` gagne (F12).
**Apply to :** planning-hook.sh (Python), couche shell (`cd -P`/`pwd -P`).

### Lecture d'adhésion strictement identique à la 44
**Source :** `recalc-planning.sh` `verifier_adhesion` l.274-301. Égalité stricte `"cycles-v1"`, `O_NOFOLLOW`, `json.loads`. La couche shell n'en fait qu'une lecture « TIGHT » (une seule ligne `"planning_version": "cycles-v1"`) ; toute divergence (config en lien symbolique, valeur échappée) est une **limite déclarée** (RESEARCH R1 points b-c), à écrire dans `modele-cycles.md`.

### Écriture atomique et fichiers de transport
**Source :** `recalc-planning.sh` l.1700-1716 (`mkstemp` + `fchmod` + `os.replace`) ; `plugin/_internal/merge-hooks.sh` l.146-156 (`mktemp` + `trap`).
**Apply to :** commande de verdict, lanceur du hook. Jamais `/tmp/x.$$` prévisible.

### Journal encodé de façon injective
**Source :** `recalc-planning.sh` `_jeton_journal` l.1529-1560 ; `ajouter_au_journal` l.1589-1602.
**Apply to :** journal de dérogation, journal d'observation (chemin relatif + gate + raison seulement).

### Suites : `ok`/`ko`, mutants à motif unique, jumeaux négatifs, `cmp`
**Source :** `test-recalc-planning.sh` l.96-104 (`ok`/`ko`), l.1444-1525 (mutants) ; `test-hook-exit-parc.sh` l.62-96 (deux flux, plancher anti-vert-à-vide).
**Apply to :** toutes les nouvelles suites. Chaque garde = un cas vert sur code sain **et** rouge sous un mutant à motif unique dont la trace (assertion, attendu, obtenu) est imprimée ; sinon la suite ne prouve rien (`README.md` v2.53.0 : « a test case must be green on sound code AND red under mutation »).
**Portabilité CI Linux (P45-D-16)** : pas de `stat -f`/`sed -i`/`timeout`/`readlink -f`/`grep -P`/`xargs -r`/`find -printf`/`date -d`. Commandes de boucle rejouables sous zsh **et** bash : listes littérales à ≥ 2 éléments ou `while IFS= read -r`, jamais `for x in $liste` (zsh ne découpe pas), `printf` plutôt que `echo`.

### Gates de dépôt à rejouer après chaque vague
`bash scripts/check-version-sync.sh` (bump, compteur de suites) ; `bash scripts/check-machine-paths.sh` (aucun `/Users/…` ni `/home/…` dans un fichier suivi) ; `bash plugin/conductor/scripts/check-planning-consumers-registered.sh` ; `bash plugin/dev-orchestrator/scripts/tests/test-check-hook-paths.sh` (T12) ; `bash plugin/_internal/tests/test-merge-hooks.sh` et `test-manifest.sh` ; gates de planning du compartiment rejoués à la main (`--file .planning/workstreams/gouvernance/STATE.md`, CI = `fiabilite` seul).

### Trailer `Gate-Touche:` et traçabilité (commits)
**Source :** `CLAUDE.md` § « Gardes in-repo », `scripts/check-gate-touche.sh` l.24-37. Tout commit touchant `scripts/tests/test-role-hook-vs-check-agents.sh`, un `scripts/check-*.sh` ou `ci.yml` : `Gate-Touche: <chemin-ou-motif> — <raison ≥ 10 caractères non blancs>`. Identifiants de décision préfixés `P45-D-NN`. Toute citation d'arbitrage nomme canal et date (« Willy, AskUserQuestion session principale, 2026-09-29 »).

## No Analog Found

| Fichier ou mécanisme | Role | Data Flow | Reason |
|---|---|---|---|
| Couche shell de la commande enregistrée (POSIX pur : `grep -a -o -E`, `case` glob, décodage par segments, `cd -P`/`pwd -P`) | hook / middleware | request-response | Aucun hook du dépôt ne contient de commande inline multi-instructions : tous sont `bash {{VF_SCRIPTS}}/x.sh` ou forme exec. Le précédent est créé par cette phase ; source de vérité = `45-RESEARCH.md` « Code Examples » (testée : 39 cas × 6 shells). L'idempotence et le retrait de `merge-hooks.sh` ont été sondés avec elle. |
| Table d'armement (`observe` / `armed` / `warn`) dans le code livré | config embarquée | — | Aucun script du dépôt ne porte d'état d'armement par gate. Le plus proche conceptuellement : `check-agents.sh` `--strict` qui promeut des avertissements en erreurs (l.588 cité par `guard-agent-write.sh`), mais c'est un drapeau de ligne de commande, pas une constante du script. |
| Journal d'observation d'un gate (chemin, gate, raison, sans contenu) hors du lab | log | file-I/O | Analogue de **dérivation de dossier seulement** : `vf-portable.sh` `vf_guard_unavailable` (marqueurs de santé, `${VF_GUARD_HEALTH_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/vibeflow/guard-health}`). Le format multi-lignes append-only est nouveau ; le marqueur de santé est un fichier réécrit, pas un journal. Emplacement à confirmer (A8). |
| Rejeu, sur copie temporaire, de labs réels avec adhésion simulée | outil de mesure | batch | Aucun script du dépôt ne rejoue un gate sur une copie de lab réel. Analogue partiel : `aides.py` (`empreinte`, `materialiser`) et `recalc-planning.sh --read-only`. Emplacement de l'outil (`plugin/planning-core/scripts/` posé chez l'utilisateur, ou `scripts/` du dépôt) à trancher. |
| Canary qui **rejoue la commande posée** | hook de vérification | batch | `check-guard-health.sh` n'exécute aucun garde (constat `45-SCOUTING.md` B2 : « Aucun canary n'existe dans le plugin »). Analogue CI : le « canari de forme du moteur GSD » de `.github/workflows/ci.yml` (à partir de l.91, extrait cité par RESEARCH R3 comme l.119-213) (cas positif, négatif, plancher de compte, `set -eu`, bilan `fail`/`note`) — à reproduire dans la suite, pas à éditer (`ci.yml` est sous revue code owner). |

## Metadata

**Analog search scope:** `plugin/planning-core/{scripts,hooks,references}`, `plugin/conductor/{scripts,hooks,references}`, `plugin/software-architecture/scripts`, `plugin/_internal/{merge-hooks.sh,tests,lib}`, `scripts/{,tests}`, `docs/HOOKS-CONTRAT-SORTIE.md`, README racine.
**Files scanned:** ~35 (lus en tout ou en partie) ; 20 chemins d'analogues confirmés suivis par `git ls-files`.
**Pattern extraction date:** 2026-09-29
**Points à arbitrer avant de figer un plan (issus de `45-RESEARCH.md`, non décidés ici) :** F2 (forme shell vs exec), F4 (prédicat « habité »), F5 (sémantique de G1 face à `registre-invalide`), F6 (protection de `config.json`/`planning_version`), F7 (`.recalc-cache.json` et nom du journal), F8 (qui lance la commande de verdict), F9 (workers dispatcheurs), F10 (sauvegarde du `STATE.md`/`INDEX.md` v2 avant la première écriture), A3 (artefact haché par le verdict), A8 (emplacement du journal d'observation).
