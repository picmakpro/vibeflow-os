---
phase: 31-manifeste-d-install-dry-run-issue-20
plan: 05
verified: 2026-08-16T17:50:00Z
status: gaps_found
score: 6/7 must-haves vérifiés
behavior_unverified: 0
overrides_applied: 0
method: exécution réelle en labs mktemp jetables, /bin/bash 3.2, arbre `git archive HEAD` isolé
isolation:
  arbre: /tmp/vf31v.oaVeJZ (git archive HEAD, hors dépôt)
  labs: mktemp -d /tmp/vf31l.* — un lab neuf par cas, jamais réutilisé entre cas
  cache: mktemp -d /tmp/vf31c.* — TOUJOURS disjoint du lab (jamais sous le lab)
  home: mktemp -d /tmp/vf31h.* exporté en HOME sur chaque script
  target_root: ./.claude relatif au lab (scope project) — jamais le dépôt, jamais le vrai $HOME
  preuve_non_contamination: "git status --porcelain inchangé ; git diff --quiet HEAD -- plugin/ → 0 ; 0 résidu engine dans le vrai ~/.claude ; 0 répertoire *-removed dans le vrai ~/.claude"
gaps:
  - truth: "Manifeste imparsable = BRUYANT et NON destructif : le moteur refuse de s'en servir pour supprimer et ne supprime rien (QUAL-01, 3e issue)"
    status: partial
    reason: >-
      Les QUATRE formes énumérées par D-31-07 (ligne vide, chemin absolu, segment .., \r résiduel)
      sont bien rejetées globalement, bruyamment, sans aucune suppression. Une CINQUIÈME forme non
      énumérée — un octet NUL dans une ligne — n'est ni détectée ni signalée : `read -r` la tronque
      silencieusement sous bash 3.2, la ligne tronquée passe les 4 contrôles, et la convergence
      supprime UN AUTRE FICHIER que celui nommé au manifeste.
    artifacts:
      - path: "plugin/_internal/vibeflow-update.sh:262-292 (vf_manifest_valid)"
        issue: "aucun contrôle d'octet NUL parmi les 4 contrôles ; le NUL est absorbé par `read` avant tout test"
    missing:
      - "5e contrôle dans vf_manifest_valid : rejet global si la ligne LUE est plus courte que la ligne SUR DISQUE (détection de troncature NUL), ou test d'octets nuls sur le fichier avant la boucle"
      - "sous-cas T19 dédié à la forme NUL (bruyant ET non destructif), au même titre que les 4 existants"
  - truth: "Le --dry-run de la convergence annonce exactement les suppressions qui auront lieu"
    status: partial
    reason: >-
      Fidèle dans le cas nominal (comm à vide dans les DEUX sens sur 5 suppressions / 4 sous-répertoires).
      INFIDÈLE dans le sens dangereux dès qu'une copie DÉGRADÉE survient (source du cache illisible —
      la classe de panne que T10-T13 traitent déjà en première classe) : la pose réelle ne consigne pas
      le chemin, la convergence le supprime ; le miroir VF_CONVERGE_DRYSET le consigne quand même
      (la branche dry-run de vf_place_file annonce `+` sans jamais lire la source) et le dry-run
      reste SILENCIEUX sur cette suppression.
    artifacts:
      - path: "plugin/_internal/vibeflow-update.sh:545-566 (vf_place_file, branche dry-run)"
        issue: "annonce `+` inconditionnelle — le miroir ne peut pas savoir que le cp réel échouera"
      - path: "plugin/_internal/vibeflow-update.sh:1770-1778 (vf_converge_apply, branche dry-run)"
        issue: "consomme le miroir comme « nouveau manifeste » sans marge pour les poses en échec"
    missing:
      - "cas de suite : copie dégradée + convergence → le fichier ENCORE POSSÉDÉ par le module ne doit pas être supprimé (ou, à défaut, doit l'être en le disant honnêtement)"
      - "arbitrage explicite : soit exclure de la convergence les chemins dont la pose a été dégradée pendant CE run, soit annoncer la suppression au dry-run"
  - truth: "Un chemin n'est supprimé que si les SIX conditions de D-31-07 tiennent simultanément — chacune prouvée par un cas de suite dédié (critère d'acceptation, tâche 2 du 31-05-PLAN.md)"
    status: partial
    reason: >-
      Les six conditions sont bien IMPLÉMENTÉES et quatre d'entre elles sont vivantes en
      comportement. Mais la suite n'en discrimine que DEUX : campagne de mutation sur les six,
      (a) et (b) font rougir T18 ; (c), (d), (e), (f) laissent la suite à 46 OK / 0 KO.
      (c) est un mutant ÉQUIVALENT (subsumé par (d), démontré). (d) et (f) sont PROUVÉS KILLABLES
      par scénario différentiel construit à la main — ce sont donc de vrais trous de couverture,
      sur deux gardes que le registre STRIDE du plan classe `high` (T-31-04, D-31-03).
    artifacts:
      - path: "plugin/_internal/tests/test-manifest.sh (T17-T22)"
        issue: "aucun cas n'exerce la condition (d) « fichier régulier / jamais un lien » ni la condition (f) « liste close d'exclusions »"
    missing:
      - "cas T : ligne de manifeste pointant un LIEN SYMBOLIQUE — le lien survit (sans (d) il est supprimé : mesuré)"
      - "cas T : ligne de manifeste portant un chemin EXCLU (scripts/vf-portable.sh) — il survit (sans (f) il est supprimé : mesuré)"
  - truth: "Un échec de backup laisse le lab dans un état d'où l'update suivant reconverge"
    status: partial
    reason: >-
      Aucune perte de données (la suppression n'a jamais lieu sans backup réussi — vérifié sur trois
      formes de panne). Mais quand c'est le `mkdir -p` du répertoire de backup qui échoue,
      `set -e` avorte vf_converge_apply APRÈS que install_module a déjà flushé le NOUVEAU manifeste :
      l'ancien est perdu, le chemin orphelin n'est plus candidat à AUCUN update ultérieur
      (mesuré : update#2 → « 0 chemin(s) retiré(s) » alors que le fichier est toujours sur disque).
      Le message rendu est un `mkdir: … Permission denied` brut, sans préfixe [vibeflow-update]
      et sans dire que la convergence a été interrompue.
    artifacts:
      - path: "plugin/_internal/vibeflow-update.sh:1826 (mkdir -p \"$(dirname \"$backup_dest\")\")"
        issue: "appel nu sous `set -e` — contrairement au `cp` juste en dessous, dont l'échec est capturé et journalisé"
    missing:
      - "capturer le rc du mkdir comme celui du cp : même branche « backup en échec … NON supprimé », même ligne de log"
human_verification:
  - test: "Arbitrer le comportement attendu quand une copie est DÉGRADÉE pendant un update qui converge"
    expected: "Décision produit : le fichier encore possédé par le module doit-il survivre (exclusion des poses dégradées du diff) ou être supprimé-avec-backup ? Dans les deux cas le --dry-run doit dire la vérité."
    why_human: "Arbitrage entre deux contrats existants qui se contredisent (tolérance Phase 30 aux copies dégradées vs convergence MANI-03) — pas une erreur d'implémentation à corriger mécaniquement."
  - test: "Arbitrer la sévérité du vecteur NUL dans le manifeste"
    expected: "Décision : 5e forme d'illisibilité à ajouter à D-31-07, ou risque accepté et documenté (la suppression reste sauvegardée donc récupérable)."
    why_human: "D-31-07 énumère quatre formes de façon close ; ajouter une cinquième est une révision de décision, pas une correction de bug."
---

# Phase 31 — lot 05 : la convergence à l'update (MANI-03) — Rapport de vérification

**Exigence vérifiée (MANI-03)** : « À l'update, les chemins de l'ancien manifeste absents du nouveau
sont supprimés avec backup systématique et liste signalée à l'utilisateur ; un fichier tiers non
manifesté reste intact. »

**Méthode** : exécution réelle uniquement. Aucune assertion tirée du SUMMARY, du PLAN ou du code lu.
Arbre mesuré = `git archive HEAD` extrait hors dépôt (`/tmp/vf31v.oaVeJZ`), `/bin/bash` 3.2.57.

## Isolation (exigée par le mandat — code qui SUPPRIME des fichiers)

| Ressource | Emplacement | Garantie |
|---|---|---|
| Arbre sous test | `/tmp/vf31v.oaVeJZ` (git archive HEAD) | jamais le dépôt |
| Lab (TARGET_ROOT) | `mktemp -d /tmp/vf31l.*`, scope `project` → `./.claude` relatif au lab | un lab NEUF par cas |
| Cache modules | `mktemp -d /tmp/vf31c.*` | toujours DISJOINT du lab, jamais dessous |
| HOME | `mktemp -d /tmp/vf31h.*` exporté sur chaque script | le vrai `$HOME` n'est jamais TARGET_ROOT |
| Canaris | `$LAB/outside.txt`, `$LAB/sibling/data.txt`, `/tmp/vf31canary.*`, `/etc/passwd` (md5) | hors TARGET_ROOT |

**Preuve de non-contamination, après toute la campagne :**
`git status --porcelain` inchangé (seuls les fichiers non suivis préexistants) · `git diff --quiet HEAD -- plugin/` → rc=0 ·
0 résidu `.vibeflow-manifest-*`/`.vibeflow-acc-*` dans le vrai `~/.claude/scripts/` · 0 répertoire `*-removed` dans le vrai `~/.claude/.backups/`.
Les mutations de l'axe 7 ont porté sur la COPIE `/tmp/vf31v.oaVeJZ/…`, restaurées et prouvées par `cmp` à chaque itération.

## Précautions de mesure (pièges mesurés de cet environnement)

- Tout décompte passe par `awk 'END{print NR}'` sur **fichier matérialisé** — jamais `wc` piped, jamais `grep -c`.
- Toute comparaison d'ensembles passe par `comm` sur listes triées `LC_ALL=C`, **dans les deux sens**.
- Toute identité de fichier passe par `cmp`/`md5 -q` — jamais `diff`.
- Les gates et `bash -n` sont lancés **nus**, `$?` lu immédiatement.

---

## Axe 1 — Le backup est-il VRAIMENT systématique ? (multi-fichiers, multi-répertoires)

Scénario : `software-architecture` installé, puis **5 fichiers retirés du cache dans 4 sous-répertoires**
(`rules/`, `references/` → posé sous `skills/…/references/`, `scripts/`, `scripts/tests/`), VERSION bumpée, `update` réel.

```
attendus_supprimes=5      (comm -23 ancien_manifeste nouveau_manifeste)
reellement_supprimes=5    (snapshot disque pré-update vs post-update)
sauvegardes=5             (find .backups/<mod>-<ts>-removed -type f)
comm -3 attendus reels        -> vide
comm -3 reels sauvegardes     -> vide
```

`cmp` octet à octet backup vs original (snapshot pré-update) — **5/5 IDENTIQUE** :

```
IDENTIQUE rules/doc-research-before-debug.md
IDENTIQUE scripts/check-file-size.sh
IDENTIQUE scripts/tests/test-check-file-size.sh
IDENTIQUE skills/software-architecture/references/anti-patterns.md
IDENTIQUE skills/software-architecture/references/solid-soc.md
```

Arborescence relative **préservée** sous `.claude/.backups/software-architecture-20260816-173703-removed/`.
Liste rendue à l'utilisateur — en-tête + **une ligne par chemin** :

```
[vibeflow-update]   convergence de software-architecture : 5 chemin(s) retiré(s) (…-removed)
[vibeflow-update]     - rules/doc-research-before-debug.md
[vibeflow-update]     - scripts/check-file-size.sh
[vibeflow-update]     - scripts/tests/test-check-file-size.sh
[vibeflow-update]     - skills/software-architecture/references/anti-patterns.md
[vibeflow-update]     - skills/software-architecture/references/solid-soc.md
```

**Verdict : N supprimés ⇒ N sauvegardés, sur 5 fichiers / 4 sous-répertoires. VÉRIFIÉ.**

## Axe 2 — Le backup peut-il échouer sans empêcher la suppression ?

Trois formes de panne distinctes, chacune sur un lab neuf. Fichier condamné : `rules/doc-research-before-debug.md`.

| Forme de panne | rc | Victime | Message |
|---|---|---|---|
| `.claude/.backups` existant, `chmod 000` | 1 | **PRÉSENTE** | `mkdir: ./.claude/.backups/software-architecture-…: Permission denied` (avorté dans `backup_module`, **avant** `install_module`) |
| Répertoire `<mod>-<ts>-removed` pré-créé `chmod 500` (le `mkdir -p` du sous-répertoire échoue) | 1 | **PRÉSENTE** | `mkdir: ./.claude/.backups/…-removed/rules: Permission denied` (avorté **dans** `vf_converge_apply`) |
| Destination de backup pré-créée `chmod 000` (le `cp` échoue, le `mkdir` réussit) | 0 | **PRÉSENTE** | `convergence de software-architecture : backup en échec pour rules/doc-research-before-debug.md — NON supprimé (pas de suppression sans filet)` puis `0 chemin(s) retiré(s)` |

**Réponse : NON — la suppression n'a JAMAIS lieu sans backup réussi. La propriété centrale tient sur les trois formes.**

**Mais** (gap 4) : dans la 2e forme, l'avortement survient **après** que `install_module` a flushé le nouveau
manifeste. L'ancien est perdu, et l'orphelin n'est plus rattrapable :

```
update#1 rc=1 (abort mkdir)
  victime sur disque après #1        : PRESENTE
  victime dans le manifeste après #1 : NON
update#2 (nouveau bump) rc=0
  convergence de software-architecture : 0 chemin(s) retiré(s)
  victime sur disque après #2        : PRESENTE (orpheline definitive)
```

Le `cp` (ligne 1827) capture son rc et journalise ; le `mkdir -p` (ligne 1826) juste au-dessus est un **appel nu**.

## Axe 3 — Le lecteur validant tient-il sur des entrées hostiles ?

12 formes, chacune injectée dans l'**ancien** manifeste, chacune sur un lab neuf, avec canaris hors TARGET_ROOT.

| # | Entrée hostile | rc | Rejet nommé | Abstention | Effet | Canaris |
|---|---|---|---|---|---|---|
| 1 | chemin absolu `/etc/passwd` | 0 | oui — `chemin absolu (ligne 13)` | oui | **aucune suppression** | INTACTS, `/etc/passwd` md5 inchangé |
| 2 | `..` au milieu `a/../../etc/x` | 0 | oui — `segment .. (ligne 13)` | oui | **aucune suppression** | INTACTS |
| 3 | ligne vide | 0 | oui — `ligne vide (ligne 13)` | oui | **aucune suppression** | INTACTS |
| 4 | CRLF `rules/crlf.md\r` | 0 | oui — `octet de retour chariot résiduel (ligne 13)` | oui | **aucune suppression** | INTACTS |
| 5 | espaces en **tête** `   rules/lead.md` | 0 | non (forme non énumérée) | — | ligne ignorée (condition (c)) ; `rules/lead.md` **PRÉSENT** | INTACTS |
| 6 | espaces en **queue** `rules/trail.md   ` | 0 | non | — | supprime **exactement** `rules/trail.md   ` ; le voisin `rules/trail.md` **PRÉSENT** | INTACTS |
| 7 | chemin **avec espaces** `rules/avec espace.md` | 0 | non | — | supprimé correctement (il est bien absent du nouveau) | INTACTS |
| 8 | **UTF-8** `rules/utf8-éà-✓.md` | 0 | non | — | supprimé correctement | INTACTS |
| 9 | chemin **très long** (4000 car.) | 0 | non | — | ignoré (n'existe pas), aucun crash | INTACTS |
| 10 | contenu **binaire** (NUL) | 0 | **NON** | **non** | ⚠️ voir gap 1 ci-dessous | INTACTS |
| 11 | **lien symbolique** sortant de TARGET_ROOT | 0 | non | — | lien **PRÉSENT**, cible `outside.txt` **INTACTE** (condition (d)) | INTACTS |
| 12 | **backslash** `rules/back\slash.md` | 0 | non | — | supprime le bon fichier ; le voisin `rules/backslash.md` **PRÉSENT** | INTACTS |

**Rien n'a jamais disparu hors TARGET_ROOT** sur les 12 cas (canari global `/tmp/vf31canary.*` intact, `/etc/passwd` md5 inchangé).

### GAP 1 — le vecteur NUL : silencieux ET destructif sur le mauvais fichier

Mécanisme isolé au grain unité :

```
$ od -c  ->  r u l e s / b i n \0 s u i t e . m d \n
$ while IFS= read -r l; do printf "lu=[%s] len=%s\n" "$l" "${#l}"; done
lu=[rules/bin] len=9
$ vf_manifest_valid  ->  VERDICT: VALIDE (rc=0) — la ligne binaire passe
```

Effet de bout en bout (lab neuf, voisin `rules/bin` créé, ligne `rules/bin<NUL>suite.md` injectée) :

```
convergence : 2 chemin(s) retiré(s)
voisin 'rules/bin' : !!! SUPPRIME — troncature au NUL, mauvais fichier detruit !!!
rejet 'imparsable' ? NON (la ligne binaire passe le validateur)
```

Contre-épreuve (anti-faux-vert) : la même ligne **sans** NUL supprime bien `rules/bin` → le mécanisme est
vivant, le cas n'est pas un vert à vide.

C'est exactement la classe que le commentaire de `vf_manifest_valid` dit vouloir interdire (« le contrôle du
\r est un REJET, jamais un nettoyage silencieux … le nettoyer en silence masquerait la cause »). La suppression
reste sauvegardée, donc récupérable.

## Axe 4 — Le `while read` est-il nu ?

**Audit exhaustif du code** (awk sur fichier matérialisé) : 10 occurrences de `while … read` dans l'engine,
**0 nue** — toutes en `while IFS= read -r` (ou `IFS='='` pour le registre clé=valeur). Idem dans la suite : 0 nue.

**Preuve comportementale des deux modes d'échec demandés :**

- *Amputation → ne matche rien (fuite)* : ligne `   rules/lead.md` (espaces de tête). `rules/lead.md`
  **PRÉSENT** après l'update. Un `read` nu aurait strippé les espaces, produit `rules/lead.md`, et ce fichier
  aurait passé les six conditions → il aurait été supprimé. Il ne l'a pas été.
- *Amputation → matche un AUTRE fichier (suppression du mauvais)* : ligne `rules/trail.md   ` (espaces de
  queue) avec un voisin `rules/trail.md`. Le moteur supprime **`rules/trail.md   `** et laisse
  **`rules/trail.md` PRÉSENT**. Un `read` nu aurait détruit le voisin.
- *Backslash sans `-r`* : ligne `rules/back\slash.md` avec voisin `rules/backslash.md`. Le voisin est
  **PRÉSENT** ; c'est bien la cible littérale qui est supprimée.

**Verdict : le `while read` de `vf_converge_apply` n'est PAS nu, et c'est prouvé par contre-épreuve, pas par lecture.**
Réserve : la protection `IFS=`/`-r` ne couvre pas la troncature NUL (gap 1), qui produit la même conséquence par un autre chemin.

## Axe 5 — D-31-14 : un fichier posé hors cycle reste inconnu

Scénario **complet** exercé : install → injection dans le cache → `update` à **version inchangée**
(chemin `sync_module_governance`) → retrait du cache → **vrai bump** → convergence.

```
[apres install] hors-cycle sur disque=NON | dans le manifeste=NON
update version inchangée :
  software-architecture déjà à jour (v1.6.0) — resync gouvernance (scripts + hooks)
  7 chemin(s) posé(s) hors cycle manifeste, non consigné(s)
[apres sync]    hors-cycle sur disque=OUI | dans le manifeste=NON
vrai bump (script retiré du cache → absent des DEUX manifestes) :
  convergence de software-architecture : 0 chemin(s) retiré(s)
[apres bump]    hors-cycle sur disque=OUI | dans le manifeste=NON
  contenu intact ? OUI (cmp identique)
```

Variante (script **conservé** dans le cache au bump) : il est consigné pour la première fois
(`sur disque=OUI | manifeste=OUI`), `0 chemin(s) retiré(s)` — jamais traité comme supprimable entre les deux.

Resync à version inchangée → manifeste **BYTE-IDENTIQUE** (`cmp` rc=0). `sync_module_governance` n'appelle,
commentaires filtrés, **aucune** de `vf_manifest_flush` / `vf_manifest_reset` / `vf_converge_*` (0 occurrence en code).

**VÉRIFIÉ.**

## Axe 6 — Fidélité du miroir `VF_CONVERGE_DRYSET`

**6.1 — cas nominal** (labs jumeaux à état initial identique ; 5 suppressions, 4 sous-répertoires, + un fichier tiers) :

```
|P (annonces [plan] -)|              = 5
|R (réellement disparus du disque)|  = 5
comm -23 P R  (annoncé, pas supprimé — sur-annonce)   -> vide
comm -13 P R  (supprimé, PAS annoncé — SILENCE)       -> vide
```

Le lab dry-run reste **byte-identique** : inventaire des chemins IDENTIQUE, empreintes md5 par fichier IDENTIQUES.
Sur l'ensemble complet des annonces `[plan] +` vs manifeste réel, le seul écart est exactement la liste close
d'exclusions (`.backups/*`, `scripts/.vibeflow-manifest-*`, `scripts/vf-portable.sh`) — que le miroir écarte
délibérément (ligne 512). **Miroir fidèle.**

### GAP 2 — 6.2 : le miroir TAIT une suppression réelle dès qu'une copie est dégradée

Seule perturbation : `chmod 000` sur **une source du cache** (`rules/production-code-architecture.md`) —
la classe de panne que T10-T13 traitent déjà en première classe. Aucune altération de manifeste.

```
|P (annonces [plan] -)|             = 5
|R (réellement disparus du disque)| = 6
comm -23 P R  -> vide
comm -13 P R  -> ! rules/production-code-architecture.md      <-- SILENCE
```

Confirmation isolée, avec état avant/après :

```
AVANT : sur disque=PRESENT · identique à la source du cache (cmp)=OUI · dans le manifeste=OUI
        TOUJOURS déclaré par le module (présent dans le cache)=OUI
APRÈS : rules/production-code-architecture.md = SUPPRIME
        toujours déclaré par le module (cache) = OUI
  copie dégradée : ./.claude/rules/production-code-architecture.md (pose en échec)
  ⚠ 1 copie(s) dégradée(s) détectée(s) pendant la pose
  convergence de software-architecture : 1 chemin(s) retiré(s)
    - rules/production-code-architecture.md
  sauvegarde présente et identique à l'original : OUI (récupérable)
```

Deux conséquences distinctes :
1. Un fichier **encore possédé par le module** est supprimé du lab, et le message le déclare
   « disparu du module » — ce qui est **faux**. La tolérance Phase 30 aux copies dégradées (« la pose n'échoue
   PAS », l'ancien fichier était conservé) devient, sous convergence, une suppression.
2. Le `--dry-run` **ne l'annonce pas** — la divergence est dans le sens que le mandat qualifie de bien pire.

Récupérable (backup identique à l'original), mais silencieux à la prévisualisation.

## Axe 7 — La suite peut-elle rougir ? Mutation des SIX conditions de D-31-07

Campagne systématique : chaque condition neutralisée à tour de rôle (`:` no-op), suite `test-manifest.sh`
rejouée, restauration prouvée par `cmp` à chaque itération. Baseline : **46 OK / 0 KO / 0 SKIP**.

| Cond. | Mutation | `bash -n` | Suite | Assertion cassée / attendu / obtenu | Restauration |
|---|---|---|---|---|---|
| **(a)** | `done < "$old_source"` → itère aussi tout `find $TARGET_ROOT` | 0 | **45 OK / 1 KO** | `✗ T18 : FAIL — fichier tiers ou fichier survivant absent/altéré (débordement de la convergence)` — attendu : `z-tiers.md` ET `production-code-architecture.md` présents ; obtenu : absent/altéré | `cmp` rc=0 |
| **(b)** | `LC_ALL=C grep -qxF "$rel" "$new_sorted" && continue` → `:` | 0 | **45 OK / 1 KO** | `✗ T18 : FAIL — fichier tiers ou fichier survivant absent/altéré (débordement de la convergence)` — même attendu/obtenu | `cmp` rc=0 |
| **(c)** | `[ -e "$full" ] || continue` → `:` | 0 | 46 OK / 0 KO | **SURVIVANT** | `cmp` rc=0 |
| **(d)** | `{ [ -f "$full" ] && [ ! -L "$full" ]; } || continue` → `:` | 0 | 46 OK / 0 KO | **SURVIVANT** | `cmp` rc=0 |
| **(e)** | `vf_rel_to_target "$full" >/dev/null 2>&1 \|\| continue` → `:` | 0 | 46 OK / 0 KO | **SURVIVANT** | `cmp` rc=0 |
| **(f)** | `vf_manifest_excluded "$rel" && continue` → `:` | 0 | 46 OK / 0 KO | **SURVIVANT** | `cmp` rc=0 |

Suite après restauration finale : **46 OK / 0 KO / 0 SKIP**, `cmp` engine vs référence rc=0.

### GAP 3 — les mutants survivants (d) et (f) sont PROUVÉS KILLABLES

Pour ne pas confondre « mutant équivalent » et « trou de couverture », scénario discriminant construit à la main
sur chacun, arbre commité vs arbre muté :

```
CONDITION (d) — ligne de manifeste pointant un LIEN SYMBOLIQUE
  arbre commité : lien rules/evil-link = PRESENT   · 1 chemin(s) retiré(s)
  arbre muté    : lien rules/evil-link = SUPPRIME  · 2 chemin(s) retiré(s)
  (cible outside.txt INTACTE dans les deux cas)

CONDITION (f) — ligne EXCLUE scripts/vf-portable.sh (lib partagée entre TOUS les modules)
  arbre commité : scripts/vf-portable.sh = PRESENT   · 1 chemin(s) retiré(s)
  arbre muté    : scripts/vf-portable.sh = SUPPRIME  · 2 chemin(s) retiré(s)

CONDITION (c) — subsomption par (d)
  arbre commité : 1 chemin(s) retiré(s)
  arbre muté    : 1 chemin(s) retiré(s)   → mutant ÉQUIVALENT, inkillable, légitime
```

- **(c)** : mutant équivalent démontré (entièrement subsumé par `[ -f ]` de (d)). Aucune dette.
- **(e)** : non constructible depuis l'extérieur tant que `vf_manifest_valid` rejette absolu et `..` — défense
  en profondeur indiscernable de son absence. Défendable comme équivalent conditionnel.
- **(d)** et **(f)** : **gardes vivantes, zéro couverture**. Le registre STRIDE du plan les classe `high`
  (T-31-04 « suppression de masse sur une ligne résolvant vers un répertoire », D-31-03 « artefact partagé »).

Le critère d'acceptation de la tâche 2 du 31-05-PLAN.md — « seuls T15-T20 de la tâche 3 en apportent la preuve
comportementale, **chacun ciblant une condition précise** » — est **faux tel que livré** : 2 conditions sur 6
sont discriminées, et l'exécutant n'a déclaré qu'**un seul** mutant mort (la première tentative sur (b)).

## Critères mécaniques du plan (comptes par `awk`, jamais `grep -c` ni `wc` piped)

| Critère | Attendu | Mesuré |
|---|---|---|
| `bash -n vibeflow-update.sh` (nu) | 0 | **0** |
| `^vf_manifest_(valid\|read)\(\)` | 2 | **2** |
| `^vf_converge_(snapshot\|apply)\(\)` | 2 | **2** |
| `\|\| true` dans les 4 fonctions, commentaires filtrés | 0 | **0** |
| `rm -rf` dans `vf_converge_apply`, commentaires filtrés | 0 | **0** |
| conditions `# (a)`..`# (f)` commentées | 6 | **6** |
| 3 codes de retour documentés au-dessus de `vf_manifest_read` | 3 | **3** |
| `sync_module_governance` mentionne « manifeste » | ≥1 | **4** |
| `sync_module_governance` appelle flush/converge/reset (code seul) | 0 | **0** |

## Suites et gates (arbre `git archive HEAD`, lancés NUS)

```
test-manifest.sh        rc=0   46 OK / 0 KO / 0 SKIP
test-vibeflow-update.sh rc=0   19 OK / 0 KO / 0 SKIP
test-merge-hooks.sh     rc=0   34 OK ·  0 KO
scripts/check-machine-paths.sh  rc=0  (dans le dépôt : 1036 fichiers balayés)
scripts/check-version-sync.sh   rc=0  (v2.53.1, 17 modules)
scripts/check-release-tag.sh    rc=0  (VERSION=v2.53.1 ↔ tag v2.53.1)
```

Arbre de travail == HEAD pour les deux fichiers du lot (`cmp` rc=0 sur les deux).
Les trois commits du mandat sont présents : `3a41cc9`, `6bcd2a3`, `032bf32`.

## Cas complémentaires

| Cas | Résultat |
|---|---|
| `--dry-run update` sur scénario de convergence | rc=0, `[plan] - ./.claude/rules/doc-research-before-debug.md`, arbre **byte-identique** (chemins + md5) |
| Manifeste corrompu par `/etc/passwd` injecté | rc=0, `chemin absolu (ligne 13)` + `inutilisable — AUCUNE suppression`, **aucune** ligne de convergence, `/etc/passwd` md5 inchangé, victime légitime **PRÉSENTE** |
| Manifeste VIDE (0 octet) mais valide | rc=0, `0 chemin(s) retiré(s)`, aucun crash, aucun faux rejet |

## Vérités observables

| # | Vérité (must_haves du 31-05-PLAN.md) | Statut | Preuve |
|---|---|---|---|
| 1 | Chemin absent du nouveau manifeste sauvegardé PUIS supprimé, liste rendue | ✓ VÉRIFIÉ | Axe 1 : 5/5, `cmp` identiques, en-tête + 5 lignes |
| 2 | Suppression seulement si les SIX conditions tiennent | ✓ VÉRIFIÉ (comportement) | Axe 7 : (a)(b)(d)(f) prouvées vivantes ; (c) équivalent ; (e) conditionnel — **mais couverture 2/6, voir gap 3** |
| 3 | Fichier tiers non manifesté intact | ✓ VÉRIFIÉ | `z-tiers.md` intact sur tous les runs ; mutation (a)/(b) fait rougir T18 |
| 4 | Backup toujours avant suppression, arbo relative préservée | ✓ VÉRIFIÉ | Axes 1 & 2 : aucune suppression sans backup réussi sur 3 formes de panne |
| 5 | Manifeste imparsable = BRUYANT et NON destructif | ✗ **PARTIEL** | 4 formes déclarées OK ; **5e forme (NUL) silencieuse et destructive sur le mauvais fichier** — gap 1 |
| 6 | Manifeste absent = repli gracieux | ✓ VÉRIFIÉ | T20 + axe 5, rc=0, manifeste réécrit |
| 7 | `sync_module_governance` ne touche jamais au manifeste | ✓ VÉRIFIÉ | Axe 5 : `cmp` byte-identique, 0 appel en code |

**Score : 6/7.**

## Prohibitions

| Prohibition | Statut | Preuve |
|---|---|---|
| Aucune suppression sur un manifeste jugé imparsable | ✓ (jugement incomplet) | Axe 3 lignes 1-4 : abstention totale ; réserve : le NUL n'est jamais « jugé imparsable » |
| Aucune suppression d'un chemin non régulier | ✓ VÉRIFIÉ | Lien `rules/evil-link` intact ; garde prouvée vivante par mutation différentielle |
| Aucune suppression hors TARGET_ROOT après normalisation | ✓ VÉRIFIÉ | 12 cas hostiles, canaris intacts, `/etc/passwd` md5 inchangé |
| `sync_module_governance` n'écrit jamais de manifeste partiel | ✓ VÉRIFIÉ | Axe 5, `cmp` byte-identique |
| Aucune suppression pendant `--dry-run` | ✓ VÉRIFIÉ | Arbre byte-identique (chemins + md5 par fichier) |

---

_Vérifié : 2026-08-16 — par exécution réelle en labs jetables, `/bin/bash` 3.2, arbre `git archive HEAD`._
