# planning-core

> **Socle de planning & gestion documentaire du lab.** Pose le tronc commun `.planning/` d'un lab
> **non-dev** — adapté à sa logique métier, jamais imposé — et tient l'**altitude lab** sur tous les
> labs : index des projets, compartiments typés, pont mémoire, enforcement par hooks.
>
> Sur un lab de code, le planning du **projet** appartient au moteur de développement : ce module
> redirige vers le verbe adéquat au lieu de produire un format concurrent (ADR-055).

**Type** : `skill + references + scripts` · **Version** : v2.10.0 · **Dépend de** : rien.

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
    modele-cycles.md           # référence du modèle par cycles (recalc-planning.sh)
    templates/                 # 10 gabarits universels neutres-métier
    templates/cycles/          # 8 gabarits du modèle par cycles
  scripts/
    check-gates-alive.sh       # canary de session du hook central (SessionStart, advisory, Phase 45)
    check-planning-state.sh    # garde-fou fraîcheur de STATE.md (advisory)
    deroger-gate.sh            # dérogation nominative à un gate d'écriture, journal append-only (Phase 45)
    detect-gsd-engine.sh       # fait « un moteur GSD est-il en place ? » (4 exits)
    detect-planning-debt.sh    # 8e signal de dette : dette de planning (ADR-040)
    guard-planning-updated.sh  # gate bloquant : planning à jour avant clôture (exception motivée)
    planning-context.sh        # contexte planning injecté en session
    planning-hook.sh           # hook central PreToolUse : gates d'écriture et cloisonnement par rôle (Phase 45)
    planning-session-snapshot.sh  # snapshot de fin de session
    planning-task-context.sh   # contexte par tâche
    poser-verdict.sh           # seul chemin légitime vers VERDICT.md : hash et tentative calculés (Phase 45)
    recalc-planning.sh         # recalcul d'état dérivé du disque, modèle par cycles (Python embarqué)
    rejeu-gates.sh             # rejeu en lecture seule d'un lab sur copie : faux refus, faux accept (Phase 45)
    rejeu-reel.sh              # geste de rejeu sur lab réel, empreinte de tout l'arbre avant et après (Phase 45)
    workstream-policy.sh       # politique unique de nom de workstream, à sourcer (suite test-workstream-policy.sh)
    tests/                     # 18 suites (planning-core, hooks, hardening, detect-*, recalc-planning, gates, rejeu, pré-filtre, G4′, D1, clôture, canary de juge)
```

## Moteur par cycles (recalc-planning.sh)

Recalcul d'état, dérivé du disque, jamais déclaré : un lab qui adhère explicitement au nouveau
modèle (`"planning_version": "cycles-v1"` dans `.planning/config.json`) obtient huit états (dont
`indéterminé`) recalculés pour ses cycles/phases/plans, `INDEX.md`, `STATE.md` et `cloture.log`
(append-only) régénérés, avec un cache incrémental par hash du contenu. Sans cette adhésion, ou
sur un planning détecté comme tenu par GSD, le recalcul **refuse d'écrire** — mode `--read-only`
disponible sur n'importe quel planning, adhérent ou non, sortie JSON sur la sortie standard
uniquement. Le socle existant décrit ci-dessus reste inchangé et toujours actif pour tout lab qui
n'a pas adhéré. Détail complet : `references/modele-cycles.md`.

## Hook central (Phase 45)

Un hook `PreToolUse` unique (`scripts/planning-hook.sh`) porte les gates d'écriture du moteur (G1, G2,
G5, G6, G7) et le cloisonnement par rôle de la fabrique d'agents. Il n'agit que dans un lab qui a
adhéré à `cycles-v1` et reste **fail-closed** dans ce lab seulement (la commande enregistrée refuse les
écritures par outil quand le script ou `python3` manque, `Bash` restant ouvert pour la réparation) ;
partout ailleurs, labs de développement compris, il ne sort rien. **État livré : G6, G5, G1, G7 et le
cloisonnement par rôle sont armés (étapes 1 à 4) : ils refusent, fermés sur défaillance** ; seul G2
avertit. L'arbitrage de Willy qu'attendait l'armement est rendu et appliqué
(Q-ARM, AskUserQuestion session principale, 2026-09-30) ; le rejeu réel final sur des labs au repos
est fait (relevé de phase `45-REJEU-FINAL.md`, commit `708debcb`) et l'armement s'est fait par
étapes, dans un ordre fixe, un commit par étape. Ce que le hook refuse, observe ou laisse passer, ses limites
déclarées, la dérogation, la commande de verdict, le canary et le rejeu sont décrits dans la section
« Hook central et gates d'écriture (Phase 45) » de `references/modele-cycles.md`, tenue identique au
code par un contrôle croisé en CI.
