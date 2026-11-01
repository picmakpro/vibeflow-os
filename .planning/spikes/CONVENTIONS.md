# Conventions des spikes

- **Stack** : Node ≥ 18, zéro dépendance, modules ESM `.mjs`. Lecture seule sur le dépôt observé ;
  les sorties vont dans un dossier qui s'ignore lui-même (`floorplan/`).
- **Code tiers** : copie figée dans le dossier du spike, avec sa licence et un `VENDORED.txt` qui
  donne la version, le commit et chaque patch (marqué `vibeflow Pn` dans le source).
- **JSON inliné dans du HTML** : échapper `</script`, U+2028 et U+2029. Écrire ces échappements
  sous forme ASCII, car certains outils d'écriture les convertissent en caractères réels.
- **Preuve visuelle** : captures dans `captures/` du spike, prises dans un vrai navigateur sur le
  dépôt réel, jamais sur un jeu de démonstration.
