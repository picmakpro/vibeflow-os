# Garde-fous des boucles autonomes

> **Rôle** : référence chargée on-demand par `vf-auto` (et par toute boucle de
> test/correction non supervisée, ex. le module `mobile-test`). Formalise les cinq
> garde-fous qui rendent une boucle autonome **sûre, non-tricheuse et terminante**.
>
> **Origine** : doctrine extraite du track « équipe d'agents » (revizapp), généralisée.
> Voir `.planning/research/agent-team-spec-revizapp.md` (couche B).
>
> **Iron Law** : *une boucle autonome ne triche jamais et s'arrête toujours proprement.*

---

## Pourquoi

Un agent laissé en autonomie sur « rends les tests verts » a deux échappatoires
dégénérées : (1) **tricher** en affaiblissant le test au lieu de corriger le code, et
(2) **boucler à l'infini** sur un échec qu'il ne sait pas résoudre. Les cinq garde-fous
ci-dessous ferment ces deux portes.

---

## Les 5 garde-fous

### 1. Anti-thrash — abandon après N tentatives

Sur un même échec, la boucle ne réessaie pas indéfiniment. Au-delà de **N tentatives**
(config `maxAttemptsPerFlow`, défaut **3**) sans progrès, elle **abandonne ce point**,
le consigne dans le rapport et passe au suivant. Un échec non résolu est un résultat
légitime à remonter, pas une raison de brûler le budget.

### 2. Anti-régression — revert de ce qui casse le vert

Tout changement qui fait **échouer un test précédemment vert** est **reverté
automatiquement** (config `revertOnRegression`, défaut **true**). Garantit la
**monotonie** : le nombre de tests verts ne décroît jamais au cours de la boucle.

### 3. Critère d'arrêt — vert OU plafond

La boucle s'arrête dès que l'une des conditions est remplie :
- **tout est vert** (objectif atteint), ou
- un **plafond** est atteint : temps mur (`maxWallClockMinutes`) ou tokens (`maxTokens`).

Pas de troisième porte de sortie. Un plafond atteint sans le vert est un arrêt **propre**
avec rapport, pas un échec silencieux.

### 4. Séparation anti-triche — qui code ≠ qui teste

**Le rôle qui corrige le code applicatif n'est jamais celui qui écrit ou modifie les
tests**, et réciproquement. Règle absolue : **on n'affaiblit jamais un assert** pour
« faire passer ». Un test qui échoue signale un vrai problème — on corrige le code, ou on
consigne l'échec (garde-fou 1), jamais on ne mutile la preuve.

> Cette séparation se **matérialise techniquement** par le cloisonnement d'outils
> (Pattern 12 — voir `reference/content/methodology/patterns/12-cloisonnement-outils.md`) :
> le correcteur de code n'a pas les droits d'écriture sur les tests, l'auteur des tests
> n'a pas les droits sur le code applicatif.

### 5. Traçabilité — commit atomique + rapport de synthèse

Chaque correctif accepté fait l'objet d'un **commit atomique** (un fix = un commit,
message clair). En fin de boucle, un **rapport de synthèse** récapitule : diff global,
tests passés/abandonnés, régressions revertées, budget consommé. C'est ce que l'utilisateur
lit au réveil — pas les logs bruts.

---

## Schéma de config (optionnel, par projet)

Un fichier `night-run.json` à la racine du projet paramètre la boucle. Absent → défauts
ci-dessus.

```json
{
  "maxWallClockMinutes": 180,
  "maxTokens": null,
  "maxAttemptsPerFlow": 3,
  "revertOnRegression": true
}
```

---

## Reframe utilisateur

Ne jamais exposer « garde-fou anti-thrash » en jargon : parler de **« la boucle abandonne
un point bloqué après 3 essais »**, **« aucun test vert n'est jamais cassé »**,
**« rapport de synthèse au réveil »**. Voir `vocabulary-map.md`.
