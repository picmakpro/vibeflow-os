# planning-core

> **Socle de planning & gestion documentaire du lab.** Pose le tronc commun `.planning/` d'un lab
> **non-dev** — adapté à sa logique métier, jamais imposé — et tient l'**altitude lab** sur tous les
> labs : index des projets, compartiments typés, pont mémoire, enforcement par hooks.
>
> Sur un lab de code, le planning du **projet** appartient au moteur de développement : ce module
> redirige vers le verbe adéquat au lieu de produire un format concurrent (ADR-055).

**Type** : `skill + references + scripts` · **Version** : v2.6.1 · **Dépend de** : rien.

---

## Le problème

Un lab perd le fil entre deux sessions : l'intention future et l'état présent se diluent dans des
conversations qui se dégradent ou des docs qui dérivent. Ce n'est pas un problème de mémoire (le
passé) — c'est un problème de **planning** (le présent + l'avenir), géré dans des fichiers
reconstructibles depuis le disque.

## L'idée

Reprendre la **logique** d'une documentation opérationnelle chirurgicale (inspirée du `.planning/`
de GSD) — **sans** plaquer une forme dev sur des labs qui ont une autre logique métier. Deux couches :

- **Tronc commun (invariant)** : la discipline vraie pour tout travail structuré.
- **Extension de domaine (adaptable)** : `codebase/` pour le dev, `editorial/` pour le contenu,
  `pipeline/` pour la vente, `dossiers/` pour le montage de dossier… dérivée du métier réel.

## Le tronc commun (7 artefacts)

| Artefact | Rôle | Présent dès le profil… |
|---|---|---|
| `STATE.md` ★ | Où on en est MAINTENANT (clé de voûte, relu chaque session) | léger |
| `PROJECT.md` | Charte : quoi, valeur, contraintes, décisions clés | léger |
| `ROADMAP.md` | Où on va : étapes + critères de succès | léger |
| `config.json` | Profil de rigueur + options | léger |
| `REQUIREMENTS.md` | Exigences à IDs + traçabilité | standard |
| `MILESTONES.md` + `milestones/` | Archive des jalons | standard |
| `phases/NN/PLAN.md`+`SUMMARY.md` | Trace plan → exécution → bilan | standard |

## 3 profils de rigueur

**Léger** (créatif/ponctuel) · **Standard** (contenu/vente/ops/dossier) · **Complet** (dev/critique).
La rigueur est un curseur — on prend le minimum qui sert. Détail : `references/PROFILES.md`.

## Utilisation

Une fois le module installé, invoquer le skill : « **mets en place le suivi de ce lab** »,
« structure la doc », « fais l'index de mes projets ». Le skill `vf-planning` commence par déterminer
qui tient le planning du lab, puis pose le socle adapté au métier (lab non-dev) ou se limite à
l'altitude lab en redirigeant vers le verbe de projet (lab de code). En maintenance, il tient
`STATE.md` à jour et trace les étapes.

## Cohabitation avec la mémoire

`.planning/` (avant/présent) et `.claude/memory/` (capitalisation) sont complémentaires, jamais
dupliqués. Le pont est défini dans `references/bridge-memory.md`. `planning-core` fonctionne **seul**
si le lab n'a pas (encore) de registres mémoire.

## Garder le socle vivant (moteur léger)

`scripts/check-planning-state.sh` est un garde-fou **advisory** (jamais bloquant) qui signale un
`STATE.md` périmé ou un `.planning/` absent. Utilisable à la main, au `/vf-audit`, ou via un hook
SessionStart **opt-in** (wiring documenté dans `references/domain-detection.md`, jamais auto-injecté).
C'est ce qui amorce un lab fraîchement installé **sans rien imposer** : le garde-fou surface le
manque, le skill pose un socle adapté au métier.

## Contenu du module

```
planning-core/
  SKILL.md                     # /vf-planning — scaffoldeur/maintaineur adaptatif
  hooks/
    hooks.json                 # câblage garde-fous (SessionStart / PreToolUse)
  references/
    GUIDE.md                   # doctrine : tronc, anti-biais, adaptation métier
    PROFILES.md                # 3 profils + mapping métier → profil
    bridge-memory.md           # pont planning ↔ registres mémoire
    compartments.md            # compartiments à l'altitude lab
    domain-detection.md        # heuristiques métier → profil + auto-infusion (hook opt-in)
    example-lab-contenu.md     # exemple complet d'un socle adapté à un lab NON-dev
    gsd-handoff.md             # frontière d'altitude planning-core / moteur GSD (ADR-055)
    templates/                 # 10 gabarits universels neutres-métier
  scripts/
    check-planning-state.sh    # garde-fou fraîcheur de STATE.md (advisory)
    detect-gsd-engine.sh       # fait « un moteur GSD est-il en place ? » (4 exits)
    detect-planning-debt.sh    # 8e signal de dette : dette de planning (ADR-040)
    guard-planning-updated.sh  # gate bloquant : planning à jour avant clôture (exception motivée)
    planning-context.sh        # contexte planning injecté en session
    planning-session-snapshot.sh  # snapshot de fin de session
    planning-task-context.sh   # contexte par tâche
    tests/                     # 5 suites (planning-core, hooks, hardening, detect-*)
```
