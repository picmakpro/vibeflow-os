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
