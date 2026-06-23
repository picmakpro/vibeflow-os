# COMPARTIMENTS — Planning hiérarchique : steering lab + plan conditionnel typé

> Référence on-demand du skill `vf-planning` (planning-core v2). Répond à : faut-il un `.planning/`
> au niveau du lab ET dans chaque compartiment (projet interne, projet client, process) ? Toujours ?
> Comment éviter que le planning cannibalise la mémoire ?
>
> Fondé sur la recherche RES-127 (GSD, Kiro, Cline Memory Bank, SAFe, rolling-wave) + le terrain
> BusinessFlow-Lab (OBS-014). Principe Core P9 (modulariser pour la cognition).

---

## 1. Le principe central (contre-intuitif mais vérifié)

> **Aucun framework mûr n'a de « plan global du portefeuille ».** Le plan vit à l'**unité de livraison**.
> Le niveau au-dessus est du **steering durable**, pas un plan.

Un lab qui contient plusieurs **compartiments** (projets internes, projets clients, process récurrents)
**ne doit donc PAS** avoir un `ROADMAP.md` global qui les agrège — ce serait un plan mort dès la
semaine 2. Il a :

| Niveau | Nature | Contenu |
|--------|--------|---------|
| **Lab** | *steering* durable + index | `PROJECT.md` (identité/valeur du lab) + `STATE.md` (focus transverse : quels compartiments sont actifs) + **`INDEX.md`** (tableau de bord qui POINTE vers les plans de compartiment) |
| **Compartiment** | *plan* volatile, **conditionnel** | son propre socle `.planning/` — **seulement s'il passe le seuil d'autonomie** (§3) |

Le lab **agrège des pointeurs**, il ne contient pas les plans. Chaque plan vit chez son compartiment.

> **Lab mono-objectif (sans compartiments)** : le comportement v1 est inchangé — un seul `.planning/`
> à la racine. La hiérarchie ne s'active que pour les labs réellement multi-compartiments.

---

## 2. Typer le compartiment : `deliverable` vs `continuous`

C'est le deuxième axe, et il corrige un angle mort de planning-core v1 (tout supposait une trajectoire
A→B à jalons). Beaucoup de travail est **cyclique** (acquisition, contenu récurrent, support) et n'a
pas de fin. Forcer une roadmap dessus produit des plans morts.

| Type | Nature | Forme du plan | Pas de… |
|------|--------|---------------|---------|
| **`deliverable`** | A→B, **a une fin** (un livrable) | `STATE.md` + `ROADMAP.md` + (phases/MILESTONES selon profil) | — |
| **`continuous`** | **se renouvelle**, pas de fin | `STATE.md` + **`BOARD.md`** (colonnes + WIP + cadence de revue) | ❌ pas de `ROADMAP.md`, pas de MILESTONES |

- Le « planning qui se renouvelle » = pour un `continuous`, le plan est un **board rebattu à chaque
  cadence** (hebdo/mensuel), pas un chemin de A à B. La cadence remplace le jalon.
- **Cas hybride** (important) : un compartiment `continuous` peut **héberger** des sous-cycles
  `deliverable` temporaires. Ex. un programme de formation (continu) qui engendre des *launches* (chacun
  a une fin). On type le compartiment `continuous` ET on ouvre un mini-plan `deliverable` par launch,
  fermé à la livraison. C'est le seul cas qui justifie une vraie imbrication.

Le `type` se fixe à la **création** du compartiment (champ `config.json`) ; il est révisable.

---

## 3. Le seuil d'autonomie (machine-vérifiable)

> **Tout compartiment n'a PAS besoin d'un plan.** L'imposer partout = sur-ingénierie (double source de
> vérité, plans morts). Le terrain le prouve : `finance/`, `pipeline/`, `contracts/` ont déjà un suivi
> *intrinsèque* (registres, dossiers physiques) — un `.planning/` y serait pur doublon.

Un compartiment **mérite son propre plan** si **AU MOINS UNE** condition est vraie :

1. **Livrable distinct** avec ses propres critères de succès, OU
2. **Dépendances internes non triviales** (≥ plusieurs étapes/phases enchaînées), OU
3. **Durée / autonomie** qui dépasse l'horizon du parent (≥ `min_age_days`, défaut **3 j** d'activité), OU
4. **Volume** ≥ `min_tasks` étapes distinctes (défaut **5**).

En dessous → **pas de `.planning/` propre** : juste une **ligne dans `INDEX.md`** du lab.

Les constantes (`min_age_days`, `min_tasks`) vivent dans le `config.json` du lab (clé
`compartments.autonomy_threshold`) — ajustables, pas un jugement à refaire à chaque fois. Elles rendent
le seuil **enforceable** (cf. le script `detect-planning-debt.sh`).

---

## 4. La loi de non-cannibalisation (planning ⊥ mémoire)

L'inquiétude « le planning cannibalise la mémoire » a une réponse nette — et le terrain montre souvent
le **problème inverse** : faute de plan, la mémoire (JOURNAL, registre de décisions) fait le boulot du
plan (état courant noyé dans le journal, décisions ouvertes « À FAIRE » dans le registre). Poser une
couche planning **fine désengorge** la mémoire.

> **Test en une phrase : « Faux demain → plan. Survit à la livraison → mémoire. »**

- Le plan (`STATE`/`ROADMAP`/`BOARD`/`INDEX`) est **volatile, jetable**. Il **référence** une décision
  (`→ DEC-XXX`), il ne la **recopie JAMAIS**.
- La mémoire (5 registres) est **durable, append-only**. Voir `bridge-memory.md` pour les 4 ponts.
- Recopier une décision dans le plan ET la mémoire crée une double source de vérité qui diverge
  (« confidently wrong »). Toujours référencer.

Au niveau compartiment, les ponts de `bridge-memory.md` s'appliquent à l'identique : le `STATE.md` d'un
compartiment alimente le JOURNAL du lab à la clôture ; ses décisions structurantes remontent en
DECISIONS. Un seul propriétaire par information.

---

## 5. `INDEX.md` du lab — le tableau de bord

Unique artefact **nouveau au niveau lab**. Il répond en O(1) à « où en est le lab ? » sans lire le
JOURNAL. Il **pointe**, il ne duplique pas. Une ligne par compartiment :

| Compartiment | Type | Plan | Statut | Dernier refresh |
|---|---|---|---|---|
| `projects/skool-launch` | deliverable | `→ .planning/` | en cours (phase 3/6) | 2026-06-22 |
| `projects/lead-recovery` | continuous | `→ BOARD.md` | actif (cadence hebdo) | 2026-06-20 |
| `projects/landing-page` | deliverable | *(sous seuil)* | livré | — |
| `finance/` | infra | *(suivi intrinsèque)* | n/a | — |

Gabarit : `templates/INDEX.template.md`. Le `STATE.md` du lab reste la clé de voûte transverse (focus
courant, quels compartiments sont chauds) ; l'`INDEX.md` est la carte.

---

## 6. Migration d'un lab existant (sans perte de données)

Quand un lab déjà vivant adopte planning v2 (via `vf-calibrate`), **on n'écrase rien** : on **adopte
les patterns existants** et on **archive proprement**.

1. **Recenser les compartiments** (ex. `projects/*`, + dossiers métier) et leur **activité** (git/mtime).
2. **Classer** chacun : `deliverable` / `continuous` / infra (suivi intrinsèque → pas de plan).
3. **Récupérer l'existant** : un `PLAN.md`, `README` d'état, `HANDOFF` déjà présent = matière première.
   - Son contenu d'**état courant** → alimente le nouveau `STATE.md` (ou `BOARD.md` si continuous).
   - Son contenu de **trajectoire** → `ROADMAP.md` (deliverable) ou colonnes du board (continuous).
   - L'ancien fichier est **conservé** (déplacé en `.planning/_archive/` du compartiment, pas supprimé).
4. **Désengorger la mémoire** : l'état courant qui squattait le JOURNAL/le registre de décisions
   (statuts « À FAIRE ») **migre vers le plan** ; la décision durable **reste** en mémoire, le plan la
   référence. Zéro perte : on déplace, on ne jette pas.
5. **Poser l'`INDEX.md`** du lab pointant vers tout ça.

Recette opérationnelle complète : `conductor/references/migration-playbook.md` (§ planning v2).
**Toujours sous snapshot + validation humaine** (ADR-031). Jamais de migration silencieuse.

---

## 7. Garde-fous

- **Jamais de `ROADMAP.md` global du lab** — steering + INDEX, pas un plan agrégé.
- **Jamais de `.planning/` sur un compartiment sous le seuil** ni sur de l'infra à suivi intrinsèque.
- **Jamais de roadmap sur un `continuous`** — board + cadence.
- **Jamais recopier une décision dans le plan** — référencer `DEC-XXX`.
- **Jamais migrer en écrasant** — archiver l'existant, déplacer l'état, conserver la donnée.
