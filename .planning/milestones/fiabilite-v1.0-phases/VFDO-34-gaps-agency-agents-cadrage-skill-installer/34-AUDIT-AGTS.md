# 34-AUDIT-AGTS — Note d'audit AGTS-01 : gaps `agency-agents`, verdict par gap

> **Objet :** rendre le verdict AGTS-01 sur pièces — re-mesurer la matrice division → module du
> catalogue tiers `agency-agents` (`.planning/BACKLOG.md:320-331`, item du 2026-07-20), et poser
> un **verdict écrit par gap** (combler / reporter / refuser) adossé à la règle de preuve du
> milestone `fiabilite-v1.0` (`.planning/REQUIREMENTS.md:906-912`).
>
> **Date de la note :** 2026-09-15.
>
> **Ce qu'elle tranche :** le sort de chaque ligne de la matrice — combler maintenant (aucune ne
> l'est ici), reporter (une seule : `web-test-team`, par dépendance déjà actée), ou refuser faute
> de preuve au sens D-02 (six lignes).
>
> **Ce qu'elle ne tranche pas :** le sort d'AGTS-02 (`mobile-test`/`mobile-test-team`, run réel de
> sortie d'expérimental — Volet 2 de cette même phase, traité par `34-01`/`34-04`/`34-05`, jamais
> re-arbitré ici — D-06) ; aucun agent n'est créé, importé ou esquissé par cette note (D-01).

## Corpus mesuré

**Commande exécutée le 2026-09-15** (mêmes deux comptes que le job `gates` de `.github/workflows/ci.yml:245-320`,
qui scanne exactement `plugin/*/agents/*.md` (premier niveau) et `plugin/*/AGENT.md` — c'est cette
définition machine qui fait autorité, pas une liste de rapport) :

```
node -e '
const fs=require("fs"),p=require("path");
let a=0,b=0;
for (const d of fs.readdirSync("plugin",{withFileTypes:true})){
  if(!d.isDirectory()) continue;
  const ad=p.join("plugin",d.name,"agents");
  if (fs.existsSync(ad)) a += fs.readdirSync(ad).filter(f=>f.endsWith(".md")).length;
  if (fs.existsSync(p.join("plugin",d.name,"AGENT.md"))) b++;
}
console.log(a, b, a+b);
'
```

Sortie : `25 6 31`.

**Corpus distribué mesuré : 25 agents de module + 6 AGENT.md = 31 fichiers**, mesuré le 2026-09-15.

Ce périmètre **exclut délibérément** (reprise du commentaire de `.github/workflows/ci.yml:276-280`,
« la population réelle est de 31 fichiers, pas 25 ») : les blueprints
(`content/agents/*.blueprint.md`, 9 fichiers), le contenu de référence/exemples
(`plugin/reference/content/...`, 11 fichiers), et les 3 agents internes au moteur officiel
`skill-creator` (`skills/skill-creator/agents/*.md` — `analyzer`, `comparator`, `grader`,
propriété Anthropic, non gouvernés par `check-agents.sh`).

Le compte est **identique** à celui produit par la recherche de phase du même jour
(`34-RESEARCH.md` § Volet 1, `[VERIFIED]` le 2026-09-15) : le parc n'a pas bougé entre l'écriture
de la recherche et l'écriture de cette note. Aucune divergence à trancher par comparaison
d'ensembles ici — les deux mesures s'accordent.

**Confirmation de l'absence de `web-test-team`**, commande et sortie :

```
$ find plugin -maxdepth 1 -iname "web-test-team"
(aucune sortie)
```

`web-test-team` n'existe pas dans `plugin/` au 2026-09-15 — cohérent avec D-06 (son sort dépend du
Volet 2 de cette même phase, pas de cette note).

**Vérification des modules cités dans la matrice ci-dessous**, commande et sortie (chaque module
cité comme couverture existe encore sous ce nom dans `plugin/`) :

```
$ for m in dev-orchestrator software-architecture design-orchestrator planning-core conductor \
    kpi-analyst consolidator content-bundle growth-bundle mobile-test mobile-test-team \
    infrastructure-audit audit-architecture business-pilot-bundle; do
    [ -d "plugin/$m" ] && echo "OK  $m" || echo "MISSING $m"
  done
OK  dev-orchestrator
OK  software-architecture
OK  design-orchestrator
OK  planning-core
OK  conductor
OK  kpi-analyst
OK  consolidator
OK  content-bundle
OK  growth-bundle
OK  mobile-test
OK  mobile-test-team
OK  infrastructure-audit
OK  audit-architecture
OK  business-pilot-bundle
```

Tous présents. La ligne « Spatial / Game / Healthcare / GIS / Academic » cite `vf-new-lab`, qui
n'est **pas** un dossier `plugin/`, mais une commande/skill (`plugin/commands/vf-new-lab.md`) du
canal `installer` — dérivation, pas module first-class ; vérifié présent :
`find plugin -iname "*new-lab*"` → `plugin/commands/vf-new-lab.md`.

## Matrice division → module (re-mesurée)

### Conventions de verdict

Un mot par ligne, choisi parmi quatre valeurs admises :
- **`sans objet`** — division déjà couverte ✅ ; jamais une case vide (indistinguable d'un oubli).
- **`reporter`** — réservé aux gaps dont une preuve **existe** mais dont le comblement est différé
  pour une raison de séquencement. Seul cas ici : `web-test-team`, dont la justification n'est
  **pas** la règle D-02 mais la dépendance explicite à AGTS-02 (déjà actée au ROADMAP, traitée par
  les plans `34-01`/`34-04`/`34-05` du Volet 2 de cette même phase) — cette note le **nomme et
  renvoie**, elle ne re-arbitre pas (D-06).
- **`refuser`** — tout gap sans preuve au sens de la règle de preuve du milestone.
- **`combler`** — uniquement si une preuve existe et est citable avec sa source exacte. **Aucune
  ligne ne reçoit ce verdict dans cette note** (voir § Limite de la recherche de preuve et
  § Gaps refusés).

| Division agency-agents | Module VibeFlow | Statut | Verdict |
|---|---|---|---|
| Engineering | `dev-orchestrator`, `software-architecture` | ✅ Couvert | sans objet |
| Design | `design-orchestrator` | ✅ Couvert | sans objet |
| Project Management | `planning-core`, `conductor`, `kpi-analyst`, `consolidator` | ✅ Couvert | sans objet |
| Marketing / Content | `content-bundle`, `growth-bundle` | ✅ Couvert | sans objet |
| Testing | `mobile-test`(-team) → gap identifié : `web-test-team` | 🟡 Mobile only, expérimental | reporter |
| Security | `infrastructure-audit`, `audit-architecture` (+ agent `vf-auditer` du dev-orchestrator) | 🟡 Audit oui ; pas incident/compliance | refuser |
| Sales | `business-pilot-bundle` (blueprint commercial) | 🟡 Granularité fine à dériver | refuser |
| Product | `planning-core` + `business-pilot-bundle` | 🟡 Pas de module product first-class | refuser |
| Paid Media | `growth-bundle` (crochet par canal) | 🟡 Crochet oui, blueprints non | refuser |
| Support | — | ❌ Manquant | refuser |
| Spatial / Game / Healthcare / GIS / Academic | `vf-new-lab` (dérivation) | ❌ Niche, pas de module | refuser |

Onze lignes de division, identiques à celles de `BACKLOG.md:320-331` — colonnes « Division » et
« Statut » re-mesurées contre le parc réel (aucune n'a changé), colonne « Verdict » nouvelle
(absente de la matrice d'origine, exigée par D-01).

## Gaps refusés

Pour chacune des six lignes `refuser` : la formule de D-02 en toutes lettres, et la preuve
précise qui manque.

### Security (audit sécurité / compliance)
Un ❌ dans la matrice du catalogue ne suffit pas — la couverture du catalogue est une source d'inspiration, jamais une référence d'exigence.

**Preuve manquante :** aucun incident de sécurité documenté impliquant l'absence d'un agent
spécialisé compliance/incident-response n'a été trouvé dans `.planning/` (BACKLOG, STATE,
research/, missions/, phases/) ; aucune demande externe (client, testeur, issue) ne réclame un tel
agent ; aucun bug récurrent par construction ne le nécessite. `infrastructure-audit` et
`audit-architecture` couvrent déjà l'audit technique — ce qui manquerait est un persona
« compliance / gestion d'incident », dont ni l'incident ni la demande n'existent à ce jour.

### Sales (granularité SDR / discovery / proposal)
Un ❌ dans la matrice du catalogue ne suffit pas — la couverture du catalogue est une source d'inspiration, jamais une référence d'exigence.

**Preuve manquante :** aucune demande externe (client freelance de Samuel, testeur du module
`business-pilot-bundle`) demandant une granularité SDR/discovery/proposal plus fine que le
blueprint commercial actuel n'a été trouvée. Aucun incident (proposition perdue faute d'outil,
process cassé) ni bug récurrent constaté.

### Product (module product first-class)
Un ❌ dans la matrice du catalogue ne suffit pas — la couverture du catalogue est une source d'inspiration, jamais une référence d'exigence.

**Preuve manquante :** aucune demande externe ni incident documenté ne réclame un module
« Product » distinct de `planning-core` + `business-pilot-bundle`. La seule trace disponible est
l'usage personnel de Samuel, explicitement écarté comme preuve au cadrage du 2026-09-14 (D-02) —
il faudrait une demande écrite (issue, retour de lab tiers) ou un incident où l'absence de ce
module a coûté quelque chose, et aucun des deux n'existe.

### Paid Media (blueprints par canal PPC/programmatic)
Un ❌ dans la matrice du catalogue ne suffit pas — la couverture du catalogue est une source d'inspiration, jamais une référence d'exigence.

**Preuve manquante :** le crochet `growth-bundle/par-canal` existe déjà ; ce qui manquerait est un
blueprint PPC/programmatic distillé du catalogue. Aucune demande externe ni incident récurrent
n'a été trouvé justifiant cette extension précise — seule l'inspiration du catalogue (❌/🟡) la
motive, ce que D-02 exclut nommément.

### Support (customer service / analytics / legal)
Un ❌ dans la matrice du catalogue ne suffit pas — la couverture du catalogue est une source d'inspiration, jamais une référence d'exigence.

**Preuve manquante :** aucune demande externe ne réclame un bundle « Support » (`SupportFlow`,
piste #3 de `BACKLOG.md:335-338`) ; recherche textuelle du 2026-09-15 sur `.planning/` par le
mot-clé `SupportFlow` : aucune mention en dehors de la BACKLOG elle-même et de `34-CONTEXT.md`.
Il faudrait un lab non-dev réel demandant ce bundle, ou un incident lié à son absence — ni l'un ni
l'autre n'existe.

### Spatial / Game / Healthcare / GIS / Academic (verticales niche)
Un ❌ dans la matrice du catalogue ne suffit pas — la couverture du catalogue est une source d'inspiration, jamais une référence d'exigence.

**Preuve manquante :** aucune demande externe pour un module de niche (spatial, jeu vidéo, santé,
SIG, académique) n'a été trouvée ; aucun lab de ce type n'a jamais été créé sur ce poste via
`vf-new-lab`. Il faudrait un utilisateur réel de l'une de ces verticales demandant explicitement
une dérivation dédiée — absent à ce jour.

## Limite de la recherche de preuve

La recherche de preuve menée le 2026-09-15 (consignée dans `34-RESEARCH.md` § Volet 1) portait sur
`.planning/BACKLOG.md`, `.planning/STATE.md`, `.planning/research/*.md`, `.planning/missions/*.md`
et `.planning/phases/**/*.md`, avec les mots-clés **`SupportFlow`** et **`agency-agents`**, plus la
lecture directe des sections citées en `canonical_refs` de `34-CONTEXT.md`. Elle était **textuelle**
— une preuve réelle (incident, demande externe, bug récurrent) formulée avec des mots non couverts
par ces mots-clés (par exemple un incident de sécurité décrit sans jamais employer le mot
« compliance », ou une demande client relayée oralement puis notée ailleurs sous un intitulé
différent) resterait **invisible** à cette recherche.

Cette limite ne convertit **aucun** verdict `refuser` en un statut intermédiaire type
« à réexaminer » — les six refus ci-dessus restent des refus. Elle dit seulement à quelle
condition l'un d'eux serait à rouvrir : la découverte, après cette note, d'un incident documenté,
d'une demande externe (client, testeur, issue) ou d'un bug récurrent par construction, portant
spécifiquement sur l'une des six divisions refusées — condition qui n'est pas remplie aujourd'hui.

**Rappel explicite** (pour que la question ne se rejoue pas de mémoire) : l'usage personnel de
Samuel, sans trace écrite, **ne compte pas** comme preuve au sens D-02 — option explicitement
écartée au cadrage du 2026-09-14.

## Discipline de comblement (Pitfall 12)

Reprise de la mise en garde de `.planning/research/PITFALLS.md:377-408`, formulée sans ambiguïté
(précision de rédaction demandée par Samuel le 2026-09-15, portée par `40-CONTEXT.md` § Claude's
Discretion — elle ne révise **pas** D-03, elle le formule sans ambiguïté) :

Le signal d'alarme, phrase complète et non tronquée : « plus de 2-3 agents **ajoutés au catalogue** dans une PR ».
Ce seuil porte exclusivement sur l'AJOUT au catalogue d'agents distribués (un geste rare,
délibéré, gaté). Il **ne borne PAS** le **fan-out d'exécution** — combien de sous-agents tournent
simultanément pendant une mission — qui n'est borné que par **la disjonction des périmètres**
d'écriture et par le budget, jamais par ce seuil de 2-3. Confondre les deux bloquerait à tort une
mission qui dispatche légitimement de nombreux sous-agents en parallèle (comme cette phase
elle-même) sur une lecture erronée du Pitfall 12 — c'est précisément ce que la Phase 40 doit
éviter.

Un futur comblement (si une preuve D-02 apparaît un jour pour l'une des six divisions refusées) se
fait **un agent à la fois**, jamais par lot : chaque agent ajouté passe individuellement
`check-agents.sh` (ADR-044 — description, model, memory requis) et, si elle est armée, la règle 4
de `check-capability-activation.sh` (armement `isolation:`/`vf-mcp-consumer`/`vf-mcp-tools`
n'admis que si sa précondition est distribuée par un `# vf-requires:` légal, levé par un
`# vf-provides:` du corpus balayé). Un agent dont la description recouvre une cible déjà routée
par `vibeflow-dev`/`vibeflow-design` est un **synonyme** : rejet doctrinal, pas un cas limite.

## Ce qu'on n'en prend pas

Reprise du paragraphe de l'item d'origine (`BACKLOG.md:335-338`) : **pas** de catalogue plat,
**pas** de densité incompatible avec ADR-029 (agents ≤ 250 lignes, skills ≤ 500, bootstrap
≤ 2000 tokens), **aucun** copier-coller direct de personas dans `plugin/`. L'anti-feature est
gravée au ledger (`.planning/REQUIREMENTS.md:1094`) pour deux raisons de fond : (1) la densité
ADR-029 est structurellement incompatible avec un catalogue de 230+ personas plates ; (2) le
catalogue source (`msitarzewski/agency-agents`, MIT) n'a **aucune gouvernance** — ni
`check-agents.sh`, ni `check-overlaps`, ni discipline de synonymes — ses agents ne peuvent donc
jamais être importés tels quels sans recréer la façade de synonymes enterrée en v2.33.0 (bascule
agentique, cf. `[[audit-2026-07-bascule-agentique]]`).

## Items backlog à créer

**aucun item à créer** — zéro verdict `combler` dans la matrice ci-dessus. Les six gaps refusés
ne produisent aucun item (un refus n'est pas différé, il est clos jusqu'à preuve nouvelle,
cf. § Limite de la recherche de preuve). Le seul gap à statut non-terminal, `web-test-team`
(`reporter`), a déjà son item vivant en tant que dépendance du Volet 2 de cette même phase
(plans `34-01`/`34-04`/`34-05`) — il ne redonne pas lieu à un item BACKLOG distinct ici, ce serait
un doublon du suivi déjà en place au ROADMAP.

## Conséquence ledger

Ce que `34-06` (consolidation du ledger de la phase) doit faire de cette note :

1. **Item BACKLOG `## Combler les gaps de couverture inspirés du catalogue agency-agents`**
   (`.planning/BACKLOG.md:303-348`) — amender avec le résultat de cet audit : la matrice porte
   désormais un verdict par ligne (cette note en est la source), six gaps refusés faute de preuve
   D-02 (aucun changement d'état tant qu'une preuve n'apparaît pas), un gap (`web-test-team`,
   Testing) reporté sur la dépendance AGTS-02 déjà suivie au ROADMAP. Ne pas rouvrir la question
   sans preuve nouvelle nommée (condition écrite § Limite de la recherche de preuve).
2. **Table de traçabilité des exigences** — la ligne `AGTS-01` passe à un état clos avec verdict
   (livrable = cette note), sans création d'agent ; `AGTS-02` reste distincte, son état suit le
   Volet 2 de la phase (34-01/34-04/34-05), pas cette note.
3. **`.planning/PROJECT.md`** — aucune case « item actif » nouvelle à cocher pour AGTS-01 : rien
   n'a été construit (D-01). Ne pas toucher la ligne `PROJECT.md:82` relative à `mobile-test`,
   qui appartient au Volet 2.

## Périmètre

SHA de base : 7e504ade15730ab3db38c6cb7bacd5b1f95ebb0f

Preuve par diff scopé, exécutée à la clôture de la note : aucun fichier sous `plugin/`, `scripts/`,
`docs/`, `manual/`, `.github/`, ni les README racine (`README.md`, `README.fr.md`) n'a été créé ni
modifié depuis le SHA de base — traduction exécutable de « aucun agent n'est créé dans cette
phase » (D-01).

```
$ git diff --quiet 7e504ade15730ab3db38c6cb7bacd5b1f95ebb0f -- plugin scripts docs manual .github README.md README.fr.md
$ echo $?
0
```

Seul fichier de ce dépôt touché par ce plan (`34-03`) : `34-AUDIT-AGTS.md`, dans ce dossier de
phase.
