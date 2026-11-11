// vf-cockpit-lancer-style — feuille de la section « Lancer du travail » de la page hôte (72, réglages de recette du 2026-11-06).
// Export : STYLE_LANCER -> texte CSS, passé dans la configuration du script de lancement (vf-cockpit-lancer-ui) qui le pose dans un <style> à l'exécution (CSP de la page : style-src 'unsafe-inline').
// Charte 71.5 : variables existantes seulement, grille 2-4-6-8-12-16-20-24-32, aucun liseré, aucune bordure colorée, aucun fond d'état, aucun halo. Les jetons --sp-* arrivent avec la 71.5 ; la valeur de repli est celle de la grille.
export const STYLE_LANCER = `
#panel [data-vf-lancer] > * + * { margin-top: var(--sp-8, 8px); }
#panel [data-vf-lancer] details > .btn { margin: var(--sp-8, 8px) var(--sp-8, 8px) 0 0; }
#panel [data-vf-lancer] summary { cursor: pointer; }
#panel .sec [data-vf-lancer] { padding: var(--sp-12, 12px) 0 var(--sp-4, 4px); } /* section remontée sous le titre, dans l'en-tête du panneau : pas de seconde marge latérale */
@media (max-width: 999px), (pointer: coarse) {
  body.vf-term-ouvert #panel { padding-bottom: var(--vf-term-reserve, 0px); scroll-padding-bottom: var(--vf-term-reserve, 0px); }
}
`;
