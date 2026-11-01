# 67 — Recette humaine de fin de phase (bloc `<human-check>` de 67-07, tâche 2)

**Statut : À FAIRE — aucune réponse consignée.** Ce fichier prépare la recette ; il ne la remplit pas. Chaque point reste
décoché tant que Samuel n'a pas répondu ; sa réponse est ensuite consignée **mot pour mot, avec son canal et sa date**
(mémoire « arbitrage humain jamais inférable »). Le vérificateur de phase consolide ce fichier dans le fichier UAT.

Pré-requis : un vrai navigateur (Chrome, Safari ou Firefox), Node ≥ 22, la branche `feat/v2-cockpit` à son dernier commit.

## 1. Lancer le cockpit

Depuis la racine du dépôt (là où se trouve `plugin/`) :

```bash
# A. sur l'arbre réel (ce dépôt)
node plugin/cockpit/scripts/vf-cockpit.mjs open --rebuild
#    imprime : Cockpit : http://127.0.0.1:<port>/ (Code) · http://127.0.0.1:<port>/project.html (Projet)

# B. sur un lab GSD jetable (plat, deux phases, un DAG) — copier-coller tel quel
LAB="$(mktemp -d)"; mkdir -p "$LAB/src" "$LAB/.planning/phases/01-socle" "$LAB/.planning/phases/02-suite" "$LAB/.planning/missions"
printf 'export const u = () => 1;\n' > "$LAB/src/util.js"
printf '# Roadmap\n\n## Jalon démo\n\n- [x] **Phase 1: Socle** - premier jet\n- [ ] **Phase 2: Suite** - la suite\n' > "$LAB/.planning/ROADMAP.md"
printf '<objective>Faire le socle</objective>\n' > "$LAB/.planning/phases/01-socle/01-01-PLAN.md"; echo ok > "$LAB/.planning/phases/01-socle/01-01-SUMMARY.md"
printf '<objective>Faire la suite</objective>\n' > "$LAB/.planning/phases/02-suite/02-01-PLAN.md"
printf '{"nodes":[{"id":"a","step":"première étape","stage":"","deps":[],"scope":["src/**"],"status":"done"},{"id":"b","step":"seconde étape","stage":"","deps":["a"],"scope":["src/**"],"status":"running"}]}\n' > "$LAB/.planning/missions/demo.dag.json"
git -C "$LAB" init -q
node plugin/cockpit/scripts/vf-cockpit.mjs open --lab "$LAB" --rebuild
echo "$LAB"   # à noter : c'est le lab jetable

# C. sur n'importe quel autre lab GSD (dossier portant .planning/)
node plugin/cockpit/scripts/vf-cockpit.mjs open --lab <dossier-du-lab> --rebuild
```

Ouvrir les deux adresses imprimées (onglets **Code** et **Projet**). Pour arrêter : `node plugin/cockpit/scripts/vf-cockpit.mjs stop --lab <dossier>`
(le serveur s'arrête aussi seul 60 minutes après la fermeture du dernier onglet).

## 2. Ce qu'il faut regarder

1. **Marque.** Titre de l'onglet du navigateur, logo et favicon VibeFlow ; aucune mention du produit d'origine nulle part
   (en-tête, panneaux, visite guidée, santé, glossaire, boîte d'export, infobulles).
2. **Français, deux onglets.** Racine, une phase, un tableau de réponse, « Par où commencer », « Santé », glossaire (survoler un
   terme souligné), « Exporter », « Parcours » ; en-tête lisible à 1 280 et à 1 440 px de large.
   *Limite déjà connue* : sur l'onglet **Code**, les messages du panneau « Santé » et les notes de couverture sont produits en
   anglais à l'assemblage (données du moteur, pas du chrome) ; à juger comme écart acceptable ou non.
3. **Onglet Projet.** « Où en est-on ? » répond tout de suite ; une question « pourquoi » répond en 15 à 30 s par l'agent ; le
   sélecteur de modèle montre Sonnet par défaut ; un passage à Haiku survit au rechargement de la page.
4. **« Au travail ».** Dans le lab où tourne une session Claude Code (la vôtre), le badge « au travail » la montre ; « Voir la
   dernière commande » la révèle dans la ligne ; un export téléchargé (« Exporter ») ne la contient pas.
5. **Réseau.** Outils réseau du navigateur (onglet Réseau, filtre « tout ») : aucune requête vers un autre hôte ni un autre port
   que celui du cockpit au chargement des deux onglets.
6. **Direct.** Dans le lab jetable : cocher la case de la Phase 2 met la carte à jour en moins de 2 s sans perdre le zoom :
   ```bash
   perl -pi -e 's/- \[ \] \*\*Phase 2/- [x] **Phase 2/' "$LAB/.planning/ROADMAP.md"
   ```

## 3. Réponses de Samuel (à remplir par lui, jamais par un agent)

| Point | Réponse mot pour mot | Canal | Date |
|-------|----------------------|-------|------|
| 1. Marque | | | |
| 2. Français (deux onglets, 1 280 et 1 440 px ; limite Santé du Code) | | | |
| 3. Questions et modèle | | | |
| 4. « Au travail » et dernière commande | | | |
| 5. Réseau | | | |
| 6. Direct | | | |
