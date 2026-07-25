# Rapport de mission — Spike transposition jcode (mémoire + swarm)

**Date :** 2026-07-22
**Phase :** 9 — `memory-swarm-rnd` (R&D, hors chaîne de release)
**Mode :** autonome
**Manager :** vf-dev-manager

---

## Plan de bataille (consigné avant exécution)

1. Matérialiser le lab témoin en fixture reproductible (graine = entrée réelle `projet source` + 4 synthétiques
   calibrées couvrant les 4 types), sans polluer la mémoire de session vivante.
2. Prototype de passe `consolidator` isolé (hors `plugin/consolidator/`) : lit → normalise `trust` → recalcule
   `confidence` effective par demi-vie → archive `superseded_by` non destructif → réécrit → rapporte.
3. Vérifier le critère binaire D-05.
4. Note go/no-go (demi-vies recalibrées + mapping catégories).
5. Mini-cadrage swarm (non implémenté).
6. Suivi (STATE/ROADMAP) + rapports.

### Contrainte d'exécution rencontrée
L'outil `Task` n'était **pas disponible** dans cette session (boîte à outils : Read/Write/Bash/Skill/Edit) —
impossible de déléguer à `vf-coder`/`vf-auditer`/`gsd-advisor-researcher` en sous-agents. Le spike a donc été
exécuté directement, en préservant l'esprit de la doctrine : **aucun artefact ne touche le format officiel** du
`consolidator` ni le socle `conductor` (prototype isolé, jetable) ; les décisions (verdict, recalibration) sont
consignées par écrit pour validation humaine ultérieure via ADR (ADR-031).

---

## Ce qui a été prototypé (RND-01)

- **Fixture lab témoin** : `spike/lab-temoin/` — 5 entrées (1 réelle `projet-alpha-emplacement` recopiée + 4
  synthétiques : feedback/user/reference/project, dont 1 `superseded_by`). Seeder : `spike/seed-lab.py`.
- **Passe consolidator prototype** : `spike/decay-pass.py` — 3 gestes :
  - `trust` (high/medium/low) normalisé ;
  - `confidence` base + `effective_confidence` dérivée via `base × 0.5^(age/HL[type])` (sans access-boost —
    `reinforced[]` hors périmètre) ;
  - `superseded_by` → archivage non destructif (déplacement vers `archive/`, `status: superseded`, corps conservé).
- **Évidence reproductible** : `spike/run-output.txt`.

## Verdict go/no-go mécanique (D-05) — **GO**

| Critère | Résultat |
|---|---|
| Round-trip lit→recalcule→réécrit sur **toutes** les entrées, sans édition humaine | ✅ 4 réécrites + 1 via supersession ; passe 2 **idempotente** (base préservée, eff. identique, 0 archivage parasite) |
| Entrée `superseded_by` archivée (statut basculé, contenu conservé, pas supprimée) | ✅ `projet-alpha-emplacement-obsolete.md` → `archive/`, `status: superseded`, corps intact |

→ Recommandation : **écrire un ADR** (frontmatter enrichi + règle de décroissance dans `consolidator`), sous
validation humaine, avant de toucher le format officiel. Le GO porte **strictement** sur les 3 gestes minimaux.

## Demi-vies recalibrées multi-métiers (RND-02, D-04)

| Type VibeFlow (← jcode) | HL jcode | HL recalibrée | Raison |
|---|---|---|---|
| `feedback` (← Correction) | 365 j | **365 j** | Le feedback validé = moat (LRN-060) |
| `user` (← Preference) | 90 j | **180 j** | Rôle/positionnement stable sur plusieurs mois |
| `reference` (← Entity) | 60 j | **120 j** | Pointeurs externes valides tant que l'outillage ne bouge pas |
| `project` (← Fact) | 30 j | **45 j** | État projet churne mais labs non-dev plus lents qu'une codebase |

Détail : `09-GO-NOGO-memoire.md` (mapping catégories §2, frontmatter proposé §4, intégration §5).

## Cadrage swarm (RND-02) — écrit, NON implémenté

`09-CADRAGE-swarm.md` : Pattern A lock de driver unique RAII **+ récupération de claim périmé livrée d'emblée**
(convergence jcode + custody no-mistakes), Pattern B DAG ready/blocked + ré-entrée, Pattern C rapports typés.
Garde-fou : ne devient une phase d'implémentation que si des collisions sont **observées** sur les backups
isolés (ADR-048/049).

---

## Décisions prises en autonomie

- **Mapping catégories jcode → types VibeFlow** (D-06) : 1:1 (Correction→feedback, Preference→user,
  Entity→reference, Fact→project). Justifié par la transposition naturelle des demi-vies de nature.
- **Forme du frontmatter** (D-06) : `confidence` reste la base non lossy ; décroissance dans `effective_confidence`
  dérivé (alternative « écraser confidence » rejetée : non idempotent). ≤ ~12 lignes/entrée, sous ADR-029.
- **Recalibration des demi-vies** : arbitrée par raisonnement multi-métiers (pas de panel `advisor-researcher`
  faute d'outil `Task` — à revalider si l'ADR est écrit).
- **Fixture reproductible plutôt que mutation de la mémoire vivante** : évite de polluer la session réelle avec
  des entrées synthétiques, tout en satisfaisant « toutes les entrées du lab témoin » (D-01 autorise l'ajout
  d'entrées synthétiques calibrées).

## Blocages / points nécessitant l'utilisateur

- **Aucun blocage technique.** Le spike est concluant.
- **Décision humaine requise avant tout pas suivant** (ADR-031) : écrire l'ADR « frontmatter mémoire enrichi »
  et, seulement ensuite, modifier `plugin/consolidator/` + le format officiel. Rien n'a été touché de ce côté.
- Volet swarm : rester en veille (non implémenté) jusqu'à observation de collisions réelles.

## Livrables (chemins absolus)

- `/Users/samuel/Documents/dev/vibeflow-os/.planning/phases/VFDO-09-spike-transposition-jcode-m-moire-swarm/09-GO-NOGO-memoire.md`
- `/Users/samuel/Documents/dev/vibeflow-os/.planning/phases/VFDO-09-spike-transposition-jcode-m-moire-swarm/09-CADRAGE-swarm.md`
- `/Users/samuel/Documents/dev/vibeflow-os/.planning/phases/VFDO-09-spike-transposition-jcode-m-moire-swarm/spike/decay-pass.py`
- `/Users/samuel/Documents/dev/vibeflow-os/.planning/phases/VFDO-09-spike-transposition-jcode-m-moire-swarm/spike/seed-lab.py`
- `/Users/samuel/Documents/dev/vibeflow-os/.planning/phases/VFDO-09-spike-transposition-jcode-m-moire-swarm/spike/run-output.txt`
- Suivi mis à jour : `STATE.md`, `ROADMAP.md`, `REQUIREMENTS.md`.
