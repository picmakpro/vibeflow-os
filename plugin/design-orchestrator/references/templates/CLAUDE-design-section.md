# Section Design — à ajouter dans le CLAUDE.md du projet

<!--
  Copier cette section dans le CLAUDE.md du projet.
  Le workflow DA-INIT de /vf-design la génère automatiquement avec les bonnes valeurs et la
  bonne incarnation selon la stack (web / mobile / desktop).
-->

---

## RÈGLE DESIGN : DIRECTION ARTISTIQUE

Toute modification UI doit respecter `DESIGN.md`. Règles non négociables :

1. **Pas de valeurs en dur** — passer par le système de design (rôles couleur/typo/spacing de `DESIGN.md`).
2. **Thème : {{THEME_MODE}}** — {{THEME_DESCRIPTION}}
3. **Anti-AI-slop** : pas de police générique par défaut (Inter/Roboto/Arial), pas de gradient cliché, pas de layout copié-collé.
4. **Accessibilité** : contraste ≥ 4.5:1, focus visibles, cibles tactiles ≥ 44px, labels d'accessibilité.
5. **Loading fidèle** : chaque écran async montre un skeleton fidèle au layout — jamais « Loading… ».
6. **Gate de build/rendu** : `{{BUILD_GATE_CMD}}` doit passer avant tout push.
7. **Ne jamais casser une feature** pour un gain visuel (pas de suppression de composant fonctionnel).

### Fichiers clés (selon stack)

| Fichier | Rôle |
|---|---|
| `DESIGN.md` | bible visuelle — couleurs, typo, spacing, composants, animations |
| `{{TOKENS_FILE}}` | système de design incarné (variables CSS / tokens Swift / theme object) |
| `{{THEME_CONFIG}}` | config thème (tailwind.config / ThemeData / asset catalog) |
| `{{COMPONENTS_PATH}}` | composants / primitives UI |

### Commande /vf-design

Utiliser `/vf-design` (ou simplement demander « améliore le design », « refais cet écran ») pour
toute évolution UI. Le workflow route automatiquement selon l'ampleur :
- **ajustement** (≤2 fichiers) : validation rapide + geste ciblé ;
- **refonte** (multi-fichiers/section) : diagnostic → plan → implémentation → finition → vérif ;
- **refonte complète** (page/écran, nouveau pattern) : exploration → plan → implémentation → audit → vérif.
