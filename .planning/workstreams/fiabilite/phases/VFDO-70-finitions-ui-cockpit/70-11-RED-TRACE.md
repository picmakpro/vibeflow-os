# 70-11 — traces du rouge (UIFN-12, UIFN-13)

Commande de rejeu : `bash plugin/cockpit/scripts/tests/test-cockpit-equipe.sh > "$TMPDIR/70-11.out" 2>&1` (un Chromium headless par interaction, socle `chrome-session.mjs`).

## EK1 — focus après Entrée sur « Lire le transcript » (UIFN-12)

Date : 2026-11-04. Base : `7a3ace3d` (code de production inchangé depuis 794c6dba pour `72-vf-equipe.js` et `70-vf-live.js`).

Témoin positif EK1.0 : avant l'Entrée, `document.activeElement` = `BUTTON`, `data-vf-transcript="a1"` (PASS, la sonde lit le focus).

Rouge EK1 :

- assertion : après Entrée au clavier (événement de touche réel, CDP `Input.dispatchKeyEvent`), le transcript s'affiche ET l'élément actif reste dans le tiroir
- attendu : `lu=true | actif=dans le tiroir`
- obtenu : `lu=false | actif=BODY`

### Mesure de la cause (relevé toutes les 10 ms après l'Entrée)

Relevé : `["BODY", disabled=false, actif===boutonOrigine=false, boutonOrigineDansLeDocument=false]`, état de la page : `selection = n:ag-a1`, bouton présent mais NEUF, `desactive=false`, fragment d'URL passé à `#v=n%3Aag-mgr1&s=n%3Aag-a1`.

Lecture :

- le bouton d'origine a quitté le document avant le premier relevé et n'a jamais été désactivé : `b.disabled = true` (`72-vf-equipe.js:122`) n'est PAS la cause ;
- le transcript n'est jamais lu (`lu=false`) : le clic n'a pas eu lieu, le gestionnaire de clic de `72-vf-equipe.js` n'a même pas été atteint ;
- le fragment `v=` change : c'est le raccourci global du viewer (`window` `keydown`, touche Entrée avec un nœud sélectionné : `open(state.selected)`, moteur vendorisé) qui reçoit l'Entrée du bouton, descend dans le nœud sélectionné et redessine le panneau ;
- ce n'est donc pas non plus le redessin de `70-vf-live.js:78` (aucun `who` n'est livré dans ce scénario) : la condition d'arrêt du plan (« ne pas modifier `70-vf-live.js` ») ne s'applique pas, la correction reste dans `72-vf-equipe.js`.
