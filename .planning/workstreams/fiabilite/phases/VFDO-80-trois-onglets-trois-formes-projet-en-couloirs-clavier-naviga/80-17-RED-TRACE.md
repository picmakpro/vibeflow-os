# 80-17 — trace des rouges (P80-D-25), régime allégé

Régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale) : pas de mutant, les rouges sont
ceux de la base fusionnée (tête 1257249f, 80-16 incluse), avant tout code.

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-finitions.sh` (lab lancé avec `--terminal`), mesures du pilote `chrome-finitions.mjs`.
Première passe : 6 PASS / 17 FAIL. Le seul rouge qui n'est pas voulu (FI3.4, liste) venait d'un sélecteur du pilote (`.vp-rangee` au lieu de
`.vp-ligne`, les lignes de la liste) : corrigé, FI3.4 relu vert sur la base (4 vues, trois états chacune, aucune intersection).

| Cas | Attendu | Obtenu sur la base |
|-----|---------|--------------------|
| FI1.1 (historique, tech, lancer) | `list-style none`, marqueur masqué, chevron 16 × 16, zone ≥ 32 | `disclosure-closed` ou `list-item`, chevron absent (`none`/`auto`) |
| FI1.1b | chevron à 90° ouvert | aucun chevron (angle indéfini) |
| FI1.1c | summary ≥ 44 px, select 36 px au toucher | select natif (`appearance: auto`) |
| FI1.2 | `appearance none`, 28 px, fond `--raise`, contour 1 px | `auto`, 25 px, fond noir, contour 0, désactivé à opacité 0,7 |
| FI1.3 | `#proposition-mode` = `#vf-modele` (valeurs calculées) | `auto`, 20 px, fond `--raise-2`, rayon 12, désactivé à opacité 0,7 |
| FI1.4 | rotation instantanée en mouvement réduit, 0 animation | `[0, 0]` (rien ne tourne) |
| FI1.5 | `/_vf/ui/03-vf-charte.js` en 200, chargé, une feuille | 404, aucune entrée de ressource, aucune feuille |
| FI2.1 (1440 px) | tous les boutons d'en-tête à 36 px | `theme-toggle` à 44 px, les six autres à 36 |
| FI3.1 | `#vf-lock` en police de texte, chiffres tabulaires | `[false, false, "500"]` (mono, chiffres proportionnels) |
| FI3.1b | quatre éléments d'Équipe en police de texte | `[false, true, "500"]` ×3 et `[false, false, "500"]` pour `.r-meta b` |
| FI3.2 | pastilles Santé/Récent aux teintes du bureau, point de « ⋯ » à la teinte la plus haute | fond `22,22,22` (`--on`) pour les deux, point `22,22,22` |
| FI4.1 à FI4.3 | fichier neuf, jetons, inventaire | fichier absent, ligne `AJOUT` absente |

Verts sur la base, gardés verts : FI1.3b (`q.css` sans `url(`), FI2.1 à 1100 px, FI2.2, FI2.3 (ouvreur Git à 44 × 44 de 701 à 1279 px), FI3.4.

Écarts du pilote relevés en route (consignés, pas du code produit) : `window.Floorplan` n'existe plus une fois la page rendue (la portée de 79-16 le
retire) : la sonde de pastilles pose ses boutons par `window.VibeFlow.addHeaderButton` ; la feuille d'Équipe (`window.__vfEquipeRendu.css`) n'est
posée qu'au premier dessin du tiroir « Au travail » : la sonde la pose comme `70-vf-live.js` (`poserCss`).
