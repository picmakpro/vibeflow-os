# Contrat de portabilité — `vf-portable.sh`

> **Statut : contrat figé, implémentation à venir.**
> La lib est produite par le plan `01-01` (tracer) de la Phase 1 « Portabilité Windows » du
> workstream gouvernance. Ce document est le contrat d'interface : il est stable et on peut
> planifier contre lui **avant** que le fichier n'existe. La lib elle-même est livrée à
> l'exécution du tracer.
>
> **Destinataires** : tout module dont les scripts résolvent un interpréteur Python, enveloppent
> `jq`, ou déclarent des hooks. Aujourd'hui : `conductor`, `consolidator`, `planning-core`,
> `infrastructure-audit`, `kpi-analyst`, `dev-orchestrator`, `software-architecture`, `_internal`.

---

## 1. Pourquoi ce contrat existe

Trois défauts de portabilité Windows ont la même cause : **une logique de compatibilité recopiée
au lieu d'être partagée**.

- La résolution de l'interpréteur Python est dupliquée dans ~13 scripts de production. Un
  correctif précédent en a oublié 7.
- Le wrapper `jqx()` qui neutralise le CRLF de `jq` natif Windows est redéfini **5 fois** à
  l'identique.
- Certaines gardes sortent en `exit 0` sans interpréteur — protection muette : l'utilisateur croit
  être protégé et ne l'est pas.

Le contrat remplace la recopie par une lib unique, et la convention par un **gate qui échoue**.

---

## 2. Ce que la lib expose

Emplacement : `plugin/_internal/lib/vf-portable.sh` — possédée par l'**engine**, pas par un
module. Aucun module ne peut l'emporter en se désinstallant. Elle est posée à l'install par
`copy_engine_lib()` dans `vibeflow-update.sh`.

| Symbole | Rôle |
|---|---|
| `vf_resolve_python` | Résout un interpréteur utilisable. Cascade `python3` → `python` → `py -3`. |
| `vf_python <args…>` | **Invoque** l'interpréteur résolu. **Fonction, pas variable** — c'est ce qui fait de `py -3` un barreau de plein droit, alors qu'un `PYBIN=` ne peut pas porter un lanceur à argument. |
| `vf_py_probe <candidat>` | Sonde un candidat : présent, pas le stub `*WindowsApps*`, s'exécute réellement (gardé par `timeout` sous Windows), et est bien un Python 3. |
| `jqx <args…>` | Wrapper `jq` : `command jq "$@" \| tr -d '\r'`. Neutralise le CRLF de `jq` natif Windows. |
| `vf_guard_unavailable <script> <motif>` | Écrit le marqueur de garde inexécutable. Voir §4. |

La détection `IS_WINDOWS` est **portée par la lib**. Ne la redéfinissez pas : la sonde en dépend,
et une redéfinition locale casse sous `set -u`.

---

## 3. Le bloc localisateur — à reproduire à l'identique

La lib doit être atteignable depuis **deux contextes de exécution différents** : le cache du
plugin (avant install — `preflight.sh`, `merge-hooks.sh`, `resolve-deps.sh`) et le dossier de
scripts à plat (après install). La profondeur de chemin diffère. D'où un bloc à quatre candidats,
**identique dans tous les consommateurs — seul le préfixe de message change** :

```sh
# >>> vf-portable:locator (bloc canonique — ne pas éditer à la main, cf. plan 01-01)
#   1. $(dirname "$0")/vf-portable.sh                      → install à plat
#   2. $(dirname "$0")/lib/vf-portable.sh                  → engine dans le cache
#   3. $(dirname "$0")/../../_internal/lib/vf-portable.sh  → module ou installer dans le dépôt
#   4. $(dirname "$0")/../../scripts/vf-portable.sh        → extracteur kpi copié
# Aucun candidat trouvé → message préfixé en stderr + sortie non-zéro. Jamais un `source` muet.
# <<< vf-portable:locator
```

**Les deux lignes de marqueur ne sont pas décoratives.** Le gate extrait le bloc *entre* elles,
normalise le préfixe de message et asserte que tous les blocs du dépôt partagent **une seule
somme de contrôle**. Deux sommes = dérive détectée.

Le candidat 3 n'est pas théorique : c'est lui qui fait tourner `check-agents.sh` depuis le job
`gates` de la CI.

---

## 4. Contrat de marqueur — « n'a pas pu tourner » est un troisième état

Une garde qui ne peut pas s'exécuter **ne sort jamais 0**. Trois actions, ensemble :

1. Appeler `vf_guard_unavailable <script> <motif>` — écrit une ligne dans
   `$VF_GUARD_HEALTH_DIR/<script>.marker` (horodatage ISO, script, motif).
2. Imprimer le motif en `stderr`, préfixé par le nom du script — motif `[nom-du-script] …`.
3. Sortir **non-zéro**.

Le hook doctor de `conductor` agrège tous les marqueurs en **une seule ligne** au démarrage de
session, et escalade en refus bloquant après 3 sessions si le marqueur persiste.

> Précédent inter-outils : « n'a pas pu tourner » est un état distinct de « a tourné et a trouvé
> un problème ». ESLint le fait (exit 2 pour config fatale, exit 1 pour findings) ; l'API Checks
> de GitHub aussi (`neutral` / `startup_failure` distincts de `success`/`failure`).

---

## 5. Hooks — forme exec

Les fragments `hooks/hooks.json` passent de la forme shell à la **forme exec** :

```jsonc
// AVANT — forme shell : la chaîne part dans un shell
{ "type": "command", "command": "bash {{VF_SCRIPTS}}/mon-script.sh --hook || true" }

// APRÈS — forme exec : spawn direct, aucun shell
{ "type": "command",
  "command": "<chemin ABSOLU vers bash, résolu et vérifié à l'install>",
  "args": ["{{VF_SCRIPTS}}/mon-script.sh", "--hook"] }
```

Règles, toutes vérifiées sur la documentation officielle :

- `type` **reste** `"command"`. C'est la **présence de `args`** qui bascule en forme exec.
- `command` est **résolu sur le `PATH`**. Un nom nu (`"bash"`) reproduirait donc exactement le bug
  qu'on corrige. Le **chemin absolu est la pièce porteuse**, pas un raffinement.
- Chaque drapeau est un **élément d'`args` séparé**. Un drapeau à valeur accolée
  (`--if-older-than=14d`) reste un élément unique.
- **`|| true` disparaît par construction** — ce n'est plus du shell, l'opérateur n'est pas
  exprimable. Le silence devient impossible à écrire, pas seulement déconseillé.
- `timeout`, `if`, `statusMessage`, `async`, `asyncRewake` restent acceptés. **`shell` est ignoré**
  dès que `args` est présent.

Bénéfice au passage : un chemin de lab contenant un espace (« GS ADVISORY ») casse en forme shell
et passe en forme exec sans guillemets.

---

## 6. Le gate — ce qui fera échouer la CI

`scripts/check-portable-resolution.sh` échoue (exit 1) si, **hors de la lib**, il trouve :

1. une résolution d'interpréteur Python (motif historique `PYBIN=` ou équivalent) ;
2. une définition de `jqx()` ;
3. une exclusion de stub `*WindowsApps*` — ce troisième balayage existe parce qu'un script portait
   sa propre sonde sans jamais assigner la variable historique, donc invisible aux deux premiers ;
4. une **dérive du bloc localisateur** — deux sommes de contrôle différentes après normalisation.

Les lignes de commentaire sont filtrées avant comptage : un gate qui mord sur sa propre
documentation est un gate qu'on finit par désactiver.

---

## 7. Fichiers concernés hors polarité gouvernance

Pour la polarité dev (Phase 27, portée par Samuel) :

| Fichier | Ce qu'il faut faire |
|---|---|
| `plugin/software-architecture/scripts/guard-file-size.sh` | Remplacer le bloc de résolution par le localisateur + `vf_python`. Renverser le silence : `vf_guard_unavailable` + sortie non-zéro. |
| `plugin/dev-orchestrator/hooks/hooks.json` | Migrer toutes les entrées en forme exec. Classer chaque entrée **advisory ou bloquante**, explicitement. |
| `plugin/software-architecture/hooks/hooks.json` | Idem. |

`plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` contient aussi un motif de résolution — à
vérifier au moment de la migration : s'il est actif en production, il entre dans le périmètre du
gate.

**Pourquoi ces fichiers ne peuvent pas être exclus** : l'exigence PORT-02 dit qu'aucune résolution
dupliquée ne subsiste, et c'est un gate qui échoue. Tant qu'un fichier garde son bloc, le gate
reste rouge et l'invariant n'est pas livrable — pour personne.

---

## 8. Séquencement

1. Plan `01-01` (tracer) livre la lib, sa pose par l'engine, et deux consommateurs — un à plat, un
   depuis le cache. **C'est à ce moment que la lib devient réelle.**
2. Plan `01-03` migre les consommateurs de la polarité gouvernance et câble le gate en CI.
3. **Phase 27** (polarité dev) migre les fichiers du §7.

Le gate ne peut passer au vert qu'une fois les deux polarités migrées. À câbler en CI en
conséquence — soit après la Phase 27, soit en mode avertissement d'ici là.

---

*Contrat figé le 2026-08-02. Source : `01-CONTEXT.md` (D-01, D-02, D-06, D-08, D-11..D-16) et les
plans `01-01` à `01-06` du workstream gouvernance.*
