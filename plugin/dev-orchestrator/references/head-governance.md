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
>
> **B1 — Place du head** (arbitrage Samuel, AskUserQuestion session principale, 2026-09-17) : le
> head est **incarné dans la session principale** (via `/vf-dev`) ou lancé en autonomie
> (`vf-auto`) — **jamais dispatché lui-même comme sous-agent (`Task(vibeflow-head)`)**.
> Profondeurs visées : manager 1, `vf-coder` 2, briques GSD 3 (`team-kernel.md` §Marge de
> profondeur de dispatch). Dispatcher le head en Task l'enfoncerait d'un cran et briserait cette
> marge dès son premier geste.

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

### Trois questions avant l'échelle (2026-09-24)

Avant de lire la table, le head répond à **trois questions indépendantes**, chacune notée
`faible | moyen | fort` — jamais une impression globale de « difficulté » (une seule note
mélange tout et se laisse tirer vers le bas par un cas qui *a l'air* simple) :

1. **Coordination** — combien de parties du système bougent ensemble ? (un fichier ↔ plusieurs
   modules ↔ un contrat entre modules ou un schéma partagé)
2. **Incertitude** — la cause ou la conception sont-elles connues, ou faut-il investiguer pour
   les découvrir ? (bug reproduit et localisé ↔ symptôme sans cause ↔ conception ouverte)
3. **Conséquence** — qu'est-ce qu'une erreur coûte ? (réversible en un commit ↔ régression
   visible ↔ données, sécurité, release)

**Composition** : le niveau de travail retenu est le **max(coordination, incertitude)** ; une
conséquence `fort` **abaisse d'un cran** ce qu'il faut pour monter d'un niveau (un `moyen`
suffit alors à passer de `Task(vf-coder)` à `Task(vf-dev-manager)`). Pattern emprunté au
routage typé des harnais de code (`docs/research/2026-09-24-jev-system-one.md` §Ce qu'on retient) :
décomposer, puis composer dans le code, jamais demander au modèle « c'est gros ou pas ». Le head
peut porter ces trois notes et le niveau retenu avec une `confiance` (`mission-contracts.md`
§Confiance d'un jugement) ; sous `SEUIL_CONFIANCE`, il **propose** au lieu de dispatcher d'office,
même sous boucle autonome. Ces questions ne remplacent ni `SEUIL_EQUIPE` ni les signaux
« mission » : elles disent **où lire** la table, la table dit quoi lancer.

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

**Cas `blocked` + `cause: "profondeur"`** (B2, `mission-contracts.md` §Retour « bloqué :
profondeur ») — ce n'est **pas un cinquième code** parmi les quatre codes de sortie du gate
ci-dessus (sain / manque(s) nommé(s) / indéterminé / outillage illisible) : ceux-ci restent au
nombre de quatre. Ce cas relève d'une taxonomie distincte, celle du contrat canonique Pattern C
(`mission-contracts.md`), dont le rapport typé garde lui aussi ses quatre statuts
(`passed|gaps_found|human_needed|blocked`) — et celui-ci reste `"statut": "blocked"` (jamais
`human_needed`). Un `vf-coder` a
constaté l'outil `Agent` absent et rendu son mandat intact via son manager. Le head **ne
redispatche jamais au même niveau** (ce qui reproduirait la même profondeur) et ne code jamais à
sa place (ADR-031) : il relance le mandat **depuis la session principale**, au niveau où l'outil
de lancement est disponible (profondeur 1 ou 2), en citant `mission-contracts.md` §Retour
« bloqué : profondeur » plutôt que de trancher seul.

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
