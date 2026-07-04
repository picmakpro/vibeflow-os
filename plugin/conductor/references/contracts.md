# CONTRACTS — Protocole d'escalade sous-agents → vibeflow-conductor (C4)

> Référence chargée on-demand par `vibeflow-conductor`. Définit comment les sous-agents d'un lab
> remontent les problèmes de cohérence au gardien central, et comment celui-ci arbitre.
>
> **Principe** : aucun problème structurel ne doit mourir silencieusement dans un sous-agent. Le
> conductor est le **point de convergence** des incohérences.

---

## Qui escalade, et quand

**Tout** agent du lab (métier ou outillé) escalade au conductor dès qu'il détecte un signal qui
**dépasse son périmètre** :

| Signal détecté par un sous-agent | Exemple |
|---|---|
| Incohérence de structure | un registre attendu manque, une convention n'est plus respectée |
| Conflit de doctrine | deux rules se contredisent, un principe Core semble violé |
| Dérive de densité / hallucination | un agent > 250L, des noms de skills inventés |
| Drift de framework | la version du lab ne correspond plus à la structure attendue |
| Dette critique | registres désynchronisés, process générateur sans garde-fou |
| Décision structurante non tracée | un choix d'archi pris sans entrée DECISIONS (DEC-XXX) |

> Un sous-agent **ne corrige pas** un problème hors de son périmètre : il le **remonte**. Mieux vaut
> escalader que deviner (cohérent avec l'Iron Law du conductor).

## Format d'escalade (court, structuré)

```markdown
**ESCALADE → conductor**
- Source : [agent émetteur]
- Type : structure | doctrine | densité | drift | dette | traçabilité
- Fait : [ce qui a été observé, factuel]
- Évidence : [fichier:ligne / registre / mesure]
- Périmètre : pourquoi je ne traite pas moi-même
```

## Ce que fait le conductor à réception

1. **Trier** : bugfix local (renvoyer au bon agent) vs problème structurel (traiter).
2. **Déléguer l'audit** : pour tout ce qui touche conformité/structure/doctrine → `vibeflow-validator`
   (5 phases). Le conductor ne réaudite pas à la main.
3. **Proposer une remédiation** — jamais l'appliquer sans validation humaine (ADR-031).
4. **Tracer** : si une décision structurante émerge → DECISIONS (DEC-XXX) ; si un pattern → LEARNING.

## Frontière de responsabilité

- Le **sous-agent** détecte et signale.
- Le **validator** audite et score (détecte, ne corrige pas — ADR-031).
- Le **conductor** arbitre, route, et porte la décision de remédiation à l'utilisateur.
- L'**utilisateur** tranche les changements structurels/doctrinaux.

> Cette chaîne est l'équivalent distribué du `contracts.md` interne du Lab VibeFlow (escalade vers
> l'architecte) — ici, c'est le conductor qui incarne ce rôle dans **chaque lab branché**.
