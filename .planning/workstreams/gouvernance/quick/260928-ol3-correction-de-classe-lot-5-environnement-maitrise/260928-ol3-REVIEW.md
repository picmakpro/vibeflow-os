---
phase: quick-260928-ol3
reviewed: 2026-09-28T00:00:00Z
depth: deep
files_reviewed: 2
files_reviewed_list:
  - plugin/planning-core/scripts/recalc-planning.sh
  - plugin/planning-core/scripts/tests/test-recalc-planning.sh
findings:
  critical: 0
  warning: 3
  info: 2
  total: 5
status: issues_found
---

# Correctif de classe (lot 5, Phase 44) : Code Review Report

**Reviewed:** 2026-09-28
**Depth:** deep (diff `885d9b3..0be13a9`, cross-checked against `detect-gsd-engine.sh` et
`workstream-policy.sh`, suite de tests rejouée localement)
**Files Reviewed:** 2
**Status:** issues_found (aucun Critical — 3 Warnings, 2 Info)

## Summary

Diff ciblé : `_bash_candidat_valide`/`_resoudre_bash` (résolution de bash par liste blanche fixe +
`lstat`), `detection_gsd` (environnement de sous-processus reconstruit de zéro), `_jeton_journal`
(alphabet d'échappement étendu au non-imprimable + garde sur `repli` vide) et `ecrire_si_different`
(lecture `O_NOFOLLOW` de l'existant), plus la nouvelle matrice de tests associée.

J'ai relu le diff ligne à ligne, tracé les deux fonctions voisines appelées par le sous-processus
(`detect-gsd-engine.sh`, `workstream-policy.sh`) pour vérifier qu'aucune dépendance résiduelle à
l'environnement hérité ne subsiste, recompilé le corps Python extrait du heredoc (`py_compile`,
OK), vérifié la syntaxe bash des deux fichiers (`bash -n`, OK), et rejoué l'intégralité de la suite
de tests en local : **270 OK · 0 KO**, mutants ciblés (`MUT-ENV-OS-ENVIRON`, `MUT-BASH-VIA-PATH`,
`MUT-BASH-INTROUVABLE`, `MUT-SOUS-PROCESSUS`, `MUT-F5-JETON-VIDE`, `MUT-F44-06-NOFOLLOW`) tous
tués.

Verdict global : le correctif atteint son objectif déclaré — l'environnement du sous-processus
détecteur ne dépend plus d'aucune variable héritée (confirmé : un seul site de construction
d'environnement dans tout le fichier, `env_maitrise = {"PATH": PATH_MAITRISE}`, aucun résidu
`os.environ.get`/fusion ailleurs), et `TimeoutExpired` est bien intercepté par le
`except Exception` englobant (sous-classe de `SubprocessError` → `Exception`). Les points relevés
ci-dessous sont des gaps de robustesse/portabilité et une clarification de commentaire — aucun ne
rouvre le vecteur mesuré (PATH empoisonné faisant mentir le détecteur).

## Warnings

### WR-01: `_bash_candidat_valide` — asymétrie de contrôle de propriétaire entre les deux branches, et aucune vérification des bits d'écriture groupe/autre

**File:** `plugin/planning-core/scripts/recalc-planning.sh:39-63`
**Issue:** La branche « fichier régulier direct » (`stat.S_ISREG(info.st_mode) -> True`) ne vérifie
aucun propriétaire ni aucun mode de permission ; seule la branche « lien symbolique » exige
`info_cible.st_uid == 0`. Le raisonnement documenté (« si substituable par un non-root, le système
est déjà compromis à un niveau que cette garde ne peut pas traiter ») est solide **pour le modèle
de menace explicitement visé** (contenu adverse d'un dossier `.planning`, PATH détourné) puisque
les deux candidats sont des chemins absolus fixes (`/bin/bash`, `/usr/bin/bash`) que ce modèle de
menace ne permet pas de faire pointer ailleurs. Deux nuances au-delà de ce raisonnement documenté,
demandées explicitement dans le brief de revue :
1. **Aucune des deux branches ne vérifie les bits groupe/autre** (mode `stat.S_IMODE`) — un
   `/bin/bash` root-owned mais accidentellement `0666`/`0777` (conteneur mal provisionné, image CI
   avec permissions larges, hôte multi-tenant) passerait la validation dans les DEUX branches sans
   qu'aucun contrôle ne le signale, alors que c'est exactement le vecteur qu'un attaquant
   non-root exploiterait pour substituer le binaire. L'argument « système déjà compromis » couvre
   implicitement ce cas (la garde ne prétend traiter que la substitution par un acteur qui n'a
   plus besoin d'un uid particulier pour écrire), mais ce n'est énoncé nulle part dans le
   commentaire — un futur lecteur qui prend le commentaire au pied de la lettre (« la branche
   directe n'exige pas de vérification de propriétaire séparée ») pourrait légitimement croire que
   la brèche « fichier root-owned mais world-writable » est hors de portée d'un attaquant non-root,
   ce qui est faux.
2. **TOCTOU résiduel** : `_bash_candidat_valide` (`lstat`) puis, pour la branche lien, `realpath` +
   `stat`, valident un état qui peut changer avant que `subprocess.run` n'exécute le même chemin
   par son nom (pas par descripteur ouvert). Fenêtre de course étroite et de même portée que le
   point 1 (exige déjà une écriture sur `/bin` ou `/usr/bin`), mais c'est un check-then-use
   classique qu'un commentaire pourrait nommer explicitement plutôt que de laisser un lecteur le
   redécouvrir.
**Fix:** Ajouter, dans les deux branches de `_bash_candidat_valide`, une vérification des bits
groupe/autre (`info.st_mode & (stat.S_IWGRP | stat.S_IWOTH) == 0`) en plus de la régularité — coût
nul, ferme la nuance 1 sans affaiblir le raisonnement existant. Pour la nuance 2, documenter (sans
nécessairement corriger, vu le coût/bénéfice) que la fenêtre TOCTOU est un choix assumé, au même
titre que le reste du raisonnement de cette fonction.

### WR-02: `--noprofile --norc` ne neutralise pas `BASH_ENV`/`ENV` — la protection vient exclusivement de la liste blanche d'environnement, pas de ces deux flags

**File:** `plugin/planning-core/scripts/recalc-planning.sh:406-410` (invocation `subprocess.run`)
**Issue:** Le brief demande explicitement si `--noprofile --norc` suffit à neutraliser un
`BASH_ENV`/`ENV` hérité « dans TOUS les cas ». Réponse mesurée : **`--noprofile` et `--norc` n'ont
strictement aucun effet sur la lecture de `BASH_ENV`/`ENV`**, ni sur ce cas précis ni sur aucun
autre. `--noprofile` ne s'applique qu'à un shell de LOGIN (`/etc/profile`, `~/.bash_profile`) ;
`--norc` ne s'applique qu'à un shell INTERACTIF (`~/.bashrc`). L'invocation ici
(`bash --noprofile --norc detect-gsd-engine.sh --quiet --path ...`) n'est NI un login NI un shell
interactif (un script est passé en argument) : dans ce mode, bash ne lit de toute façon ni
`/etc/profile` ni `~/.bashrc`, avec ou sans ces deux flags — ils sont donc des no-ops purs pour
CETTE invocation précise, dans tous les cas de figure testés (confirmé par la matrice
`bash-env-awk`/`env-var` du test file, qui passent grâce à l'ABSENCE de `BASH_ENV`/`ENV` dans
`env_maitrise`, pas grâce à ces flags). La protection réelle contre `BASH_ENV`/`ENV` est
**exclusivement** que `env_maitrise` est construit de zéro et ne les contient jamais — le
commentaire des lignes 87-96 l'énonce d'ailleurs correctement (« l'environnement est désormais
construit DE ZÉRO »), mais l'ajout de `--noprofile --norc` sur la ligne d'invocation, sans
commentaire dédié à son propos, crée un risque de confusion pour un futur lecteur : si quelqu'un
réintroduit un jour une fusion partielle de `os.environ` (régression du type déjà mesuré par ce
lot), il pourrait croire à tort que `--noprofile --norc` referme le vecteur `BASH_ENV`, alors que
ces flags ne l'ont jamais fait.
**Fix:** Soit retirer `--noprofile --norc` (inutiles ici, aucune régression fonctionnelle à les
retirer), soit — préférable, coût nul — ajouter une ligne de commentaire au-dessus de l'invocation
précisant explicitement : « `--noprofile --norc` sont des no-ops pour cette invocation non-login
non-interactive (aucun effet sur `BASH_ENV`/`ENV`) ; la protection réelle contre ces deux variables
est l'absence de `BASH_ENV`/`ENV` dans `env_maitrise` ci-dessus » — pour que le prochain lecteur ne
leur attribue pas un rôle qu'ils n'ont pas.

### WR-03: `CANDIDATS_BASH` figé à deux chemins — régression de portabilité fail-closed sur les systèmes sans `/bin/bash` ni `/usr/bin/bash`

**File:** `plugin/planning-core/scripts/recalc-planning.sh:84-88`, `330-339`
**Issue:** Remplacer `shutil.which("bash")` par deux chemins absolus fixes ferme bien le vecteur
PATH détourné (justifié), mais élimine aussi toute tolérance pour un `bash` légitime installé
ailleurs — Alpine/musl minimal (bash absent par défaut, ou posé via `apk add bash` sans garantie de
chemin), NixOS (bash vit typiquement sous `/nix/store/.../bin/bash`, `/bin/bash` souvent absent
sans la couche de compat `environment.usrbinenv`), ou tout conteneur distroless/minimal où bash
n'est présent qu'à un chemin non standard. Sur ces systèmes, `_resoudre_bash()` rend systématiquement
`None`, et `recalc-planning.sh` refuse alors TOUJOURS d'écrire (`non-concluante` → exit 3), même sur
un lab légitimement `non-gsd`. Le comportement fail-closed est le bon réflexe de sûreté (mieux vaut
refuser que se tromper), mais c'est une régression fonctionnelle totale et silencieuse sur ces
environnements — rien dans le code ni les commentaires ne signale ce cas à l'opérateur autrement
que par le message stderr générique « interpréteur bash introuvable ». Le docstring de
`_bash_candidat_valide` reconnaît explicitement se limiter à « macOS et Linux courants » — la
portée réduite est assumée, mais aucun message ne guide l'opérateur d'un système non standard vers
une remédiation (ex. symlink `/bin/bash`).
**Fix:** Si les systèmes hors macOS/Linux « courants » sont hors périmètre assumé du module
(probable, à confirmer avec Willy/Samuel), documenter ce choix comme limite de portée connue à côté de
`CANDIDATS_BASH` (pas seulement dans le docstring de `_bash_candidat_valide`, qui ne le lie pas
explicitement au fail-closed total qui en découle). Sinon, envisager un troisième candidat
(`/usr/local/bin/bash`, fréquent sur Homebrew Intel/BSD) sans réintroduire de dépendance au PATH.

## Info

### IN-01: Commentaire cassé au milieu d'un mot (« priorité 2bis\n# SAUTÉE ») dans `detection_gsd`

**File:** `plugin/planning-core/scripts/recalc-planning.sh:167-169`
**Issue:** Le commentaire du cas `code == 3` casse la phrase « priorité 2bis SAUTÉE » entre deux
lignes de commentaire (`# ... priorité 2bis` puis `# SAUTÉE ») tout en rendant...`), résultat
probable d'un retour à la ligne automatique mal repositionné lors d'une édition. Purement cosmétique
(aucun effet fonctionnel), mais nuit à la lisibilité d'un commentaire par ailleurs dense et
important (justifie pourquoi le code 3 n'est pas gaté sur stderr non vide).
**Fix:** Reformater le paragraphe pour que « priorité 2bis SAUTÉE » reste sur une seule ligne.

### IN-02: `assert jeton, ...` dans `_jeton_journal` — invariant désactivable sous `python -O`/`PYTHONOPTIMIZE`

**File:** `plugin/planning-core/scripts/recalc-planning.sh:222-224`
**Issue:** Le nouveau garde-fou final (`assert jeton, "..."`) protège un invariant que le docstring
démontre mathématiquement inatteignable une fois `repli` garanti non vide (chaque caractère produit
au moins un caractère de sortie). Le risque réel est donc nul en l'état — mais `assert` est
strippé silencieusement si l'interpréteur tourne avec `-O`/`PYTHONOPTIMIZE=1`. Le script est
aujourd'hui invoqué via `"$PYBIN" -` (ligne 67 du wrapper bash), sans `-O`, donc pas de risque
observable actuellement ; mais un futur appelant qui invoquerait ce module autrement (tests,
réutilisation) pourrait silencieusement perdre ce filet de sécurité, contrairement à la garde
`ValueError` du début de fonction (ligne 210-211) qui, elle, reste toujours active.
**Fix:** Remplacer par une levée explicite (`if not jeton: raise AssertionError(...)` ou une
exception dédiée) pour rester cohérent avec le style « garde bruyante toujours active » déjà choisi
pour `repli` en tête de fonction — cosmétique, coût nul.

---

_Reviewed: 2026-09-28_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: deep_
