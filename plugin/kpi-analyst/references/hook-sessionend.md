# Hook SessionEnd — refresh incrémental des KPIs

> Pose un refresh **léger** des valeurs à la fin de chaque session du lab. Headless, coût $0 (abonnement).
> Le schéma n'est PAS retouché ici (il est gelé) — seules les **valeurs** sont ré-extraites.

---

## Principe : incrémental, pas full

Ne ré-exécuter que les extracteurs **dont la source a changé** pendant la session. À défaut de détection
fine, ré-assembler est peu coûteux (les extracteurs Tier 1 sont des lectures locales). Tier 2 (externe)
n'est **jamais** déclenché par SessionEnd — réservé au cron/manuel pour ne pas multiplier les appels.

---

## Snippet `.claude/settings.json` (lab cible)

À fusionner dans les hooks du lab. Le chemin du script dépend du scope d'install (résolu par l'engine) :

```json
{
  "hooks": {
    "SessionEnd": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/scripts/kpis-writer.sh --lab <slug> --domain <domaine> --schema .claude/kpi/schema.json --extractors .claude/kpi/extractors --out .claude/memory/KPIS.md --tier1-only 2>/dev/null || true"
          }
        ]
      }
    ]
  }
}
```

> - `|| true` : un refresh KPI **ne doit jamais** faire échouer la fermeture de session.
> - `--tier1-only` : garde-fou explicite — la fin de session ne déclenche **que** l'interne (pas Tier 2).
>   (Le writer ignore Tier 2 par défaut ; le flag rend l'intention lisible.)
> - `<slug>`/`<domaine>` : renseignés à l'install du module par l'agent/installeur.

---

## Cadence recommandée

| Déclencheur | Portée | Construit en v1 |
|---|---|---|
| `SessionEnd` | Tier 1 incrémental | ✅ |
| Cron quotidien (option) | Tier 1 complet (+ Tier 2 si connecteurs actifs) | option lab/Hub |
| Manuel (« mets à jour les KPIs ») | complet | ✅ |

> Le schéma ne se re-déduit jamais automatiquement : son évolution est un acte explicite validé (Temps 1).
