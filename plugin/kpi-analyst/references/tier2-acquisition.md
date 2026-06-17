# Tier 2 — Acquisition de données externes (HUMAN-GATED, non construit en v1)

> Tier 1 (structuration interne) est livré et sûr. Tier 2 (aller chercher la donnée hors du lab) ouvre
> une **surface de risque** (sécurité, coût, non-déterminisme). Il est **documenté ici mais volontairement
> non-construit en v1** : on l'active connecteur par connecteur, sous validation humaine.

---

## Principe

Quand un KPI dépend d'une source **hors du lab** (ex. abonnés Instagram, vues YouTube, solde Stripe live),
l'agent **ne va pas** la chercher en autonomie. Il :

1. **Propose un connecteur** : une procédure réutilisable décrite dans `.claude/kpi/connectors/<nom>.md`
   (quelle source, quel moyen d'accès, quelle valeur produite, à quelle fréquence).
2. **Attend la validation humaine** du connecteur ET du périmètre d'accès.
3. Une fois validé, le connecteur devient un **extracteur Tier 2** (même contrat de sortie JSON) — mais
   sa `confidence` plafonne à `medium` (source externe, pas un fichier du lab).

---

## Garde-fous de sécurité (non négociables)

- **Périmètre d'accès explicite** : quels serveurs MCP, quel niveau d'automatisation navigateur, quelles
  API — **autorisés un par un** par l'humain. L'agent n'élargit JAMAIS son périmètre seul.
- **Jamais d'automatisation navigateur en autonomie sur des chiffres financiers / sensibles.** Un solde,
  un CA, un MRR ne se lisent pas via un Chrome piloté sans supervision.
- **Aucun secret en clair** : identifiants/tokens via le coffre du lab (env / credentials), jamais dans
  un fichier committé, jamais dans `KPIS.md`.
- **Aucune action d'écriture** côté source externe : Tier 2 est **lecture seule**.
- **Validation des chiffres financiers** : tout KPI financier issu d'un connecteur externe est marqué
  `medium` et signalé pour contrôle humain avant d'être présenté comme acquis.
- **Réversibilité** : un connecteur se désactive sans casser le schéma (le KPI repasse `low`/`null`).

---

## Format d'un connecteur — `.claude/kpi/connectors/<nom>.md`

```markdown
---
connector: instagram-abonnes
status: proposed        # proposed | approved | active | disabled
access: ["mcp:<serveur>"]   # périmètre explicitement demandé
produces: ["abonnes"]   # key(s) du schéma alimentée(s)
confidenceCap: medium
---

## Source
Compte Instagram @xxx — nombre d'abonnés.

## Moyen d'accès (demandé, à valider)
MCP <serveur> / endpoint <...>. PAS d'automatisation navigateur.

## Valeur produite
{ "key": "abonnes", "value": <n>, "source": "instagram:@xxx", "confidence": "medium" }

## Fréquence
quotidienne (cron) — lecture seule.
```

> Tant qu'un connecteur est `proposed`/`approved` mais pas `active`, le KPI associé reste `low`/`null`
> dans `KPIS.md` (affiché « à confirmer »). On ne présente jamais un chiffre non encore branché.
