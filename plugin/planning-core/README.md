# planning-core

> **Socle de planning & gestion documentaire universel.** Pose le tronc commun `.planning/` d'un
> lab — la couche qui répond à « où va-t-on, où en est-on, qu'a-t-on décidé » — **adapté à la
> logique métier**, jamais imposé.

**Type** : `skill + references + scripts` · **Version** : v1.1.0 · **Dépend de** : rien.

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

Une fois le module installé, invoquer le skill : « **mets en place le planning du projet** »,
« structure la doc », « où en est-on ? ». Le skill `vf-planning` lit le métier du lab, propose un
profil, et pose `.planning/` adapté. En maintenance, il tient `STATE.md` à jour et trace les étapes.

## Cohabitation avec la mémoire

`.planning/` (avant/présent) et `.claude/memory/` (capitalisation) sont complémentaires, jamais
dupliqués. Le pont est défini dans `references/bridge-memory.md`. `planning-core` fonctionne **seul**
si le lab n'a pas (encore) de registres mémoire.

## Garder le socle vivant (moteur léger)

`scripts/check-planning-state.sh` est un garde-fou **advisory** (jamais bloquant) qui signale un
`STATE.md` périmé ou un `.planning/` absent. Utilisable à la main, au `/checkpoint`, ou via un hook
SessionStart **opt-in** (wiring documenté dans `references/domain-detection.md`, jamais auto-injecté).
C'est ce qui amorce un lab fraîchement installé **sans rien imposer** : le garde-fou surface le
manque, le skill pose un socle adapté au métier.

## Contenu du module

```
planning-core/
  SKILL.md                     # /vf-planning — scaffoldeur/maintaineur adaptatif
  references/
    GUIDE.md                   # doctrine : tronc, anti-biais, adaptation métier
    PROFILES.md                # 3 profils + mapping métier → profil
    bridge-memory.md           # pont planning ↔ registres mémoire
    domain-detection.md        # heuristiques métier → profil + auto-infusion (hook opt-in)
    example-lab-contenu.md     # exemple complet d'un socle adapté à un lab NON-dev
    templates/                 # 8 gabarits universels neutres-métier
  scripts/
    check-planning-state.sh    # garde-fou fraîcheur de STATE.md (advisory)
    tests/test-planning-core.sh
```
