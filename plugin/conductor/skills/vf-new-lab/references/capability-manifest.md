# Manifeste de capacités — dériver QUOI fabriquer (T2 du Lab Factory)

> Référence de `vf-new-lab` (phase Manifeste). Transforme le brief clarifié en une **liste de capacités
> à fabriquer**, classées par nature, justifiées, proportionnées au profil. C'est l'entrée du fan-out
> skill-creator (`skill-fanout.md`). **Aucune capacité dérivée d'un brief non clarifié** (gate A d'abord).

---

## Les 3 natures de capacité

Une capacité = un skill à créer. On la classe en une des 3 natures (ça oriente le brief du skill-creator) :

| Nature | Question | Exemple (lab acquisition) | Forme du skill |
|--------|----------|----------------------------|----------------|
| **Savoir** | « Que doit *connaître* le lab ? » | base ICP, playbook objections, doctrine cold-email | base de connaissance injectable (référence dense) |
| **Compétence** | « Que doit *savoir-faire* le lab ? » | rédiger une séquence, scorer un lead, analyser une campagne | skill d'action outillé (procédé + critères) |
| **Procédure** | « Quel *workflow répétable* le lab exécute-t-il ? » | lancer une séquence, traiter un rejet, revue hebdo pipeline | workflow à étapes + critères de sortie (+ auditeur si génératif) |

> Une même demande métier peut engendrer les 3 : un *savoir* (connaître), une *compétence* (faire),
> une *procédure* (enchaîner de façon répétable). Ne pas tout mettre en « compétence » par défaut.

---

## Dérivation depuis le brief

Parcourir le brief clarifié et, **section par section**, extraire les capacités :
- Section **Process & livrables** → surtout des **procédures** + les **compétences** qu'elles appellent.
- Section **Métier & vocabulaire** + **Parties prenantes** → des **savoirs** (ce que le lab doit maîtriser).
- Section **Gates & EVALS** → les **procédures de vérification** (qui auront un auditeur, cf. `procedure-audit-wiring.md`).

Pour chaque capacité, écrire une entrée dans `docs/CAPABILITY_MANIFEST.md` :

```markdown
### CAP-01 — Rédiger une séquence cold-email
- nature : compétence
- justifie : brief §5 (livrable récurrent « séquence »)
- critère de succès : produit une séquence 4-7 emails personnalisée ICP, ton conforme, CTA unique
- skill cible : `sequence-writer`
- auditeur requis: non (compétence, pas procédure générative ; champ binaire obligatoire si nature = procédure)
- priorité : P0 (cœur) | statut : [À CLARIFIER si nature/justif/critère manquant]
```

---

## Gate du manifeste (B)

Le manifeste passe par le **gate B** (`completeness-gate.md`) : aucune capacité ne part au fan-out tant
qu'elle n'a pas, de façon **dure** : nature + justification + critère de succès + (si nature `procédure`)
**`auditeur requis: oui|non`** binaire + **orthogonalité** (ne recouvre pas une autre capacité). **Anti-slop
n°1** : une capacité sans justification rattachée au brief, ou redondante avec une autre = `[À CLARIFIER]`
(à fusionner/justifier), pas un skill de plus.

L'utilisateur **valide/édite la liste** (menu numéroté possible, cf. `elicitation-methods.md` — Red Team
sur le manifeste : « lesquelles sont en trop / lesquelles manquent ? »).

---

## Proportionnalité au profil (anti-sur-ingénierie)

Le **nombre** de capacités fabriquées suit le profil de rigueur (planning-core `PROFILES.md`), il n'est
jamais « le plus possible ». Le script `scripts/proportion-capabilities.sh` donne le plafond conseillé :

| Profil | Plafond conseillé de capacités P0 | Esprit |
|--------|-----------------------------------|--------|
| **Léger** | 1-3 | juste le cœur, on ajoute plus tard |
| **Standard** | 4-8 | les compétences/procédures opérationnelles |
| **Complet** | 9-20 | corpus riche (dev / lab critique) |

Au-delà du plafond → priorisation P0/P1/P2 ; seules les **P0 partent au fan-out** à l'init, le reste
est listé comme backlog dans le manifeste (à créer à la demande plus tard). **On ne fabrique jamais
20 skills « parce qu'on peut ».**

---

## Sortie de la phase

`docs/CAPABILITY_MANIFEST.md` : table des capacités P0 validées (gate B franchi) → consommée par le
fan-out skill-creator. Les P1/P2 restent en backlog dans le même fichier.
