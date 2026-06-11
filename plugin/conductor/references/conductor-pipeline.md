# CONDUCTOR-PIPELINE — Ordre canonique de configuration d'un lab

> Référence on-demand de `vibeflow-conductor`. L'enchaînement de référence pour configurer, vérifier
> et maintenir un lab. Le conductor n'embarque que l'ordre ; le détail est ici.

---

## 1. Ordre canonique

```
new-lab → install-modules → planning → verify(validator) → [vie du lab] → calibrate(update/migration)
```

| Étape | Action coulisse | Vocabulaire utilisateur |
|-------|-----------------|-------------------------|
| Création du lab | skill `vf-new-lab` | « monter le lab » |
| Pose des modules | skill `vibeflow-install` | « installer VibeFlow » |
| Socle planning/doc | skill `vf-planning` | « mettre en place le suivi » |
| Vérification | agent `vibeflow-validator` (Task) | « vérifier que tout est aligné » |
| Recalibration | skill `vf-calibrate` | « mettre à jour le lab » |

## 2. Escape hatches (ne pas payer le pipeline complet)

- **Lab déjà créé, juste ajouter un module** → directement `vibeflow-install`.
- **Lab déjà créé, juste poser le planning** → directement `vf-planning`.
- **Simple audit ponctuel** → directement `vibeflow-validator`, sans reconfigurer.

Heuristique : le pipeline complet ne sert qu'à la **création** d'un lab ou à une **migration**
structurante. Le reste, c'est de l'intervention ciblée.

## 3. Quand le conductor intervient (et quand il s'efface)

**Il intervient** : création de lab, install/désinstall de modules, audit de conformité, mise à jour
du framework, migration de doctrine, réception d'une escalade.

**Il s'efface** : pendant le travail métier quotidien (production de contenu, de dossiers, de code,
de campagnes). Là, ce sont les **agents métier** du lab qui travaillent. Le conductor ne s'immisce pas.

## 4. Garde-fous transverses

- Tout lab configuré embarque ses **auditeurs** (validator + audit-architecture) — pas de filet, pas
  de lab.
- Toute opération de **migration** : snapshot avant + re-stamp version + re-audit après.
- **Jamais** de correction/migration silencieuse (ADR-031).
- **Jamais** de forme dev plaquée sur un lab non-dev.
