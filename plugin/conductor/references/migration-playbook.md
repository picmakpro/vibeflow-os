# MIGRATION-PLAYBOOK — Recalibrer un lab quand le framework évolue (C3)

> Référence on-demand de `vf-calibrate` / `vibeflow-conductor`. Comment classer les changements du
> framework et migrer un lab proprement, sous validation humaine.

---

## 1. Classer chaque changement

| Classe | Nature | Traitement |
|--------|--------|-----------|
| **bugfix** (PATCH) | correction sans impact structurel | `vibeflow-update.sh update <module>` suffit |
| **capacité** (MINOR) | nouveau module / nouvelle option | installer/activer si pertinent — pas de migration |
| **breaking-doctrine** (MAJOR) | structure, registres, principes, conventions changent | **migration** (étapes ci-dessous) |

> La distinction est cruciale : traiter une restructuration comme un simple `cp` casse le lab. La
> source de vérité d'un changement = le `CHANGELOG.md` du module + l'historique du framework.

## 2. Recette de migration (breaking-doctrine)

1. **Snapshot avant** — le lab est sauvegardé (réversibilité).
2. **Diff structurel** — lister précisément ce qui change côté lab : fichiers, registres, conventions,
   rules contextuelles potentiellement impactées.
3. **Plan explicite** — réversible vs décision requise ; présenter à l'utilisateur, **attendre le feu
   vert** (ADR-031).
4. **Appliquer** — rafraîchir les modules ; pour une réorganisation de fichiers, déléguer à
   `software-architecture` (`/restructure`) ou au migrateur ; respecter les seuils (densité, taille).
5. **Re-stamp** — `framework-version.sh stamp` (sinon drift fantôme).
6. **Re-audit** — `vibeflow-validator` (5 phases) confirme l'alignement. Score < seuil → corriger.

## 2bis. Recette : migration planning v2 (compartiments) — SANS PERTE DE DONNÉES

Quand un lab adopte **planning-core v2** (steering lab + plan conditionnel typé), on **n'écrase rien** :
on adopte les patterns existants et on archive proprement. Classée *breaking-doctrine* (nouvelle
topologie), donc snapshot + validation humaine obligatoires.

1. **Détecter la dette** : `planning-core/scripts/detect-planning-debt.sh --root <projects>` liste les
   compartiments actifs sans plan au-dessus du seuil. C'est le point de départ du diff.
2. **Recenser + classer** chaque compartiment : `deliverable` / `continuous` / infra (suivi intrinsèque
   → **pas** de plan). Cf. planning-core `references/compartments.md`.
3. **Récupérer l'existant comme matière première** (jamais jeter) :
   - un `PLAN.md` / `README` d'état / `HANDOFF` déjà présent → son **état courant** alimente le nouveau
     `STATE.md` (ou `BOARD.md` si `continuous`) ; sa **trajectoire** → `ROADMAP.md` (deliverable) ou les
     colonnes du board (continuous).
   - l'ancien fichier est **déplacé** en `<compartiment>/.planning/_archive/`, **pas supprimé**.
4. **Désengorger la mémoire** : l'état courant qui squattait le JOURNAL et les décisions ouvertes
   (« À FAIRE ») du registre **migrent vers le plan** ; la décision durable **reste** en mémoire, le plan
   la **référence** (`→ DEC-XXX`). On déplace, on ne duplique pas.
5. **Poser `INDEX.md`** au niveau lab, pointant vers tous les plans + listant les compartiments infra.
6. **Re-stamp + re-audit** (étapes standard ci-dessous).

> Garantie zéro perte : tout fichier existant est soit **promu** dans la nouvelle structure, soit
> **archivé** sous `_archive/`. Aucune suppression. Snapshot global avant (étape 1 de la recette §2).

## 2ter. Recette : poser model_profile: balanced (lab GSD existant)

Classée *capacité* (nouvelle option, un défaut déjà implicite côté gsd-core rendu explicite) —
pas une restructuration : protocole allégé, ni snapshot global ni re-audit 5 phases requis, juste
la confirmation ADR-031 avant écriture (recette ci-dessous).

**Déclencheur** : `vf-calibrate` détecte un lab avec un moteur GSD actif
(`detect-gsd-engine.sh` → exit 0) dont `.planning/config.json` n'a PAS de clé `model_profile`
(ou une valeur `inherit` explicite, le piège à corriger).

**Ce qui se passe si on laisse faire** : le profil par défaut de gsd-core (`balanced`, planner
opus / executor+verifier sonnet) reste implicite — un futur changement de défaut amont, ou un
worker sonnet qui invoque `gsd-plan-phase` en `inherit`, tirerait silencieusement `gsd-planner`
vers sonnet (dégradation de la qualité de plan sans signal).

**Recette (PROPOSER, jamais imposer — ADR-031)** :
1. Lire `.planning/config.json` (créer l'objet s'il n'existe pas encore, sans autre champ).
2. PROPOSER l'ajout de `"model_profile": "balanced"` — annoncer explicitement pourquoi (protège
   d'un changement de défaut amont + du piège `inherit`).
3. Sur confirmation explicite uniquement : écrire la clé, snapshot avant/après (comme toute
   écriture `vf-calibrate`).
4. Refus → ne rien écrire, journaliser la proposition déclinée (pas de re-proposition en boucle
   à chaque `vf-calibrate` — une fois par session suffit).

## 3. Surfaçage opt-in à l'ouverture de session (façon GSD)

Pour que l'utilisateur **voie** qu'une mise à jour le concerne (comme GSD le montrait dans le repo),
sans rompre le principe « zéro hook imposé » du plugin : un hook **opt-in**, advisory, à coller dans
`.claude/settings.json` du lab (jamais auto-injecté) :

```json
{
  "hooks": {
    "SessionStart": [
      { "hooks": [ { "type": "command",
        "command": "bash .claude/scripts/framework-version.sh drift --quiet || true" } ] }
    ]
  }
}
```

`|| true` garantit que la session ne casse jamais : le hook **signale** un retard (exit 1 interne
absorbé) et invite à lancer `/vf-calibrate`. Rien n'est appliqué automatiquement.

## 4. Côté maintenance VibeFlow (notre rôle)

Le conductor + `vf-calibrate` sont distribués **dans chaque lab**. C'est par eux que l'équipe VibeFlow
peut **recalibrer** un lab branché en suivant la dernière version du framework — toujours via le même
garde-fou : détecter → proposer → valider → appliquer → re-auditer. Jamais d'action silencieuse sur
le lab d'autrui.
