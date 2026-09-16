# Head-governance — les quatre compétences du head of minds

> Chargée **on-demand** par `vibeflow-head` (incarné par le skill `vf-dev`) et par `vf-auto`
> lorsqu'une mission dépasse le routage direct — allouer le bon niveau d'équipe, séquencer les
> missions, contrôler la sortie d'un manager sur témoin machine, compter ce que ça coûte. Écrite
> pour être **déplaçable** : rien ici ne vaut spécifiquement pour `dev-orchestrator` plutôt que
> pour un head cross-métier hypothétique (écarté par D-01, hors périmètre du jour).
>
> **A1** : le head GOUVERNE et lance des équipes — il n'invoque JAMAIS lui-même un skill ni un
> agent `gsd-*`. La colonne « Mind » ci-dessous nomme toujours l'équipe dispatchée
> (`Task(vf-coder)`, `Task(vf-dev-manager)`, …), jamais un geste `gsd-*` exécuté en direct par le
> head : ce geste est celui que l'équipe porte une fois mandatée.

---

## 1. Règle d'échelle (allocation, dans un seul sens)

Graduée du moins cher au plus cher. **On escalade, on ne redescend jamais en cours de geste** : une
fois le niveau d'équipe choisi pour un travail, on ne repasse pas à un niveau moins cher en cours
de route au motif que ça se passe bien.

| Travail | Mind | Condition |
|---|---|---|
| un commit, pas d'impact archi | `Task(vf-coder)` | trivial (mandat « tâche courte », le head dispatche directement) ; vf-coder y lance `gsd-quick --validate`, sans revue séparée |
| bug / crash | recherche doc (ADR-045) **puis** `Task(vf-coder)` (correctif d'un commit) ou `Task(vf-dev-manager)` (au-delà) | le head porte la recherche web, les workers cloisonnés ne l'ont pas |
| une étape unique planifiée, ou tout geste au-delà d'un commit | `Task(vf-dev-manager)` | N = 1, aucun signal de durée |
| N ≥ `SEUIL_EQUIPE` ou signal de durée ou étages combinés | `Task(vf-dev-manager)` | seuil et signaux : voir ci-dessous |
| mission design pure (zéro feature) | `Task(vf-design-manager)` | binaire, jamais une dominante calculée |
| projet mobile, vérification réelle | `vf-test-orchestrator` | via le manager, ou direct sous `vf-auto` |
| configuration du lab | `vibeflow-conductor` | hors dev |
| conformité du lab | `/vf-audit` (validator) | chasse gardée, ADR-057 |

Trois renvois, aucune recopie : la **correspondance** intention → brique reste dans
`intent-routing.md` (source unique — cette table n'ajoute que l'échelle, jamais la carte) ; le
seuil canonique `SEUIL_EQUIPE` est **défini dans** `mission-contracts.md` §Seuil de bascule — on le
cite, on ne réécrit jamais sa valeur ; les signaux « mission » sont la liste canonique de
`mission-contracts.md` §Signaux « mission ».

**Déclenchement (D-09).** Sur signal mission, le head **PROPOSE** le dispatch d'un manager et
attend le feu vert **en conversation**. Sous une **boucle autonome**, ou sur un signal de durée
explicite, il **dispatche d'office** sans redemander. ADR-031 reste intact : ce n'est pas une
autorisation nouvelle, c'est la même heuristique de proposition déjà en vigueur, qui se scinde
selon le mode plutôt que de rester muette dessus.

## 2. Séquencement (parallélisme au niveau mission)

Le manager parallélise des **nœuds** à périmètres disjoints (frontière `ready`, team-kernel). Le
head parallélise des **missions** — et **sur ce dépôt, aujourd'hui, il les sérialise** (D-02) : un
manager à la fois. Ce qu'il fait réellement de plus :

- lire les dépendances déclarées de la feuille de route (`Depends on:` dans `ROADMAP.md`) ;
- ordonner les missions restantes en conséquence ;
- détecter les étapes indépendantes à l'intérieur d'une mission et les **déclarer** au manager
  dans le brief (périmètres disjoints connus), pour que la frontière `ready` du manager en
  profite — le head ne recalcule jamais cette frontière lui-même.

**Le fan-out d'exécution n'est borné par aucun nombre.** Ses seules bornes sont la disjonction des
périmètres et les plafonds de budget (`autonomous-guardrails.md`). La formule « pas plus de deux
ou trois agents d'un coup » est un signal d'alerte sur l'**ajout d'agents au catalogue** dans une
PR — jamais une limite d'orchestration à l'exécution.

**Extension non livrée — un manager par workstream.** Un lab réellement partitionné
(`workstreams.md` §5 « La condition dure ») pourrait vouloir plusieurs managers en parallèle, un
par compartiment. Cette voie exigerait, avant d'être livrée, quatre choses :

- un `driver-lock.sh` **compartiment-aware** (lock nommé par workstream), avec amendement daté
  de l'ADR du socle d'équipe pour que l'invariant devienne « un manager **par compartiment** » ;
- une `guard-driver-lock.sh` alignée sur ce même compartimentage ;
- un pointeur de workstream **et** une clé de session **distincts par manager** ;
- une preuve d'usage concurrent **réel**, pas une preuve de mécanisme sur clone jetable.

**Déclencheur** : la partition effective d'un lab — elle-même gatée humain. Tant qu'il n'est pas
franchi, le head sérialise (D-02).

## 3. Contrat de sortie (vérifier le témoin, pas refaire le travail)

**Principe** : un vert du manager est accepté s'il porte une **preuve machine**. Le head rejoue
**uniquement** le gate dont la preuve manque — jamais un étage, jamais la revue, et il ne relit
jamais un diff.

Résolution du gate de sortie par la **cascade des scripts frères** documentée dans
`mission-flow.md` §Résolution — jamais un chemin en dur.

Six contrôles, chacun bon marché et déterministe :

- **E1** — verrou de driver relâché.
- **E2** — arbre propre (hors artefacts gitignorés attendus).
- **E3** — branche dédiée, PR ouverte (ADR-059).
- **E4** — STATE/ROADMAP marqués pour les étapes de la mission.
- **E5** — rapport détaillé présent sur disque, à son chemin canonique `.planning/missions/…`.
- **E6** — chaque verdict du rapport porte sa preuve (commande + code de sortie + SHA) : voir le
  **Contrat de preuves E6 (verdict → head)** de `mission-contracts.md`.

Quatre codes de sortie, et une conduite par code :

- **sain** : enchaîner.
- **manque(s) nommé(s)** : mandat de **clôture ciblée** au manager — jamais corrigé par le head
  lui-même (ADR-031, un orchestrateur ne produit pas).
- **indéterminé** : la mission est traitée comme **non prouvée** — jamais annoncée verte, et le
  head le dit explicitement à son propre rapport.
- **outillage illisible** : escalade humaine.

Trois règles de conduite s'y ajoutent :

(a) **Le head ne relâche ni ne reprend JAMAIS un verrou de driver.** Sur un verrou encore tenu, il
renvoie un mandat de clôture ciblée au manager, puis escalade à l'humain avec la commande de
reprise à jouer — le relâchement reste le geste du **tenant** (D-11).

(b) Un gate rejoué l'est avec la **commande canonique** que le verdict devait porter, nommée par
le contrat de preuves — jamais une liste locale, jamais le job de gates complet de l'intégration
continue (D-12).

(c) **Une** preuve manquante se rejoue ; **deux ou plus** signalent que la source n'a pas appliqué
le contrat — dans ce cas, mandat de clôture ciblée et source consignée pour amendement, jamais une
rafale de re-jeux (D-14).

## 4. Économie (trois règles, un décompte)

1. **Ne jamais relire ce que le digest porte.** Le head lit le rapport compact et le disque
   pointé, jamais l'intégralité de `.planning/` après une mission.
2. **Ne jamais rejuger un diff sans nouveau commit.** Un verdict PASS sur un SHA donné vaut tant
   que le HEAD de la branche reste ce SHA.
3. **Relayer, jamais recalculer.** `estimate`/`actuals`, `verdicts`, décompte de budget : tout se
   recopie verbatim, jamais recalculé ni arrondi.

Décompte par mission — trois lignes ajoutées au rapport existant, jamais une statistique, aucun
fichier neuf (D-13, le registre inter-missions est explicitement écarté) : minds dispatchés, tours
consommés, gates rejoués (E6).

Bornes dures inchangées : `autonomous-guardrails.md` (plafonds de temps et de jetons, trois essais,
anti-triche) — cette référence n'y touche pas.
