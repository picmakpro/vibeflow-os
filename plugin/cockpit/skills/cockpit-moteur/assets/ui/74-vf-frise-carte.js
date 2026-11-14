// VibeFlow (74-06) : « Voir sur la carte », point d'appel UNIQUE de la frise vers l'onglet Code (P74-D-12, D-37, D-52). Posé dans le rappel d'arrivée sur
// Équipe, sur l'objet window.__vfFrise (74-vf-frise.js se charge APRÈS ce fichier et réassigne l'objet : rien ne s'y pose au chargement) :
//   voirSurLaCarte(fichiers, titre) -> Promise<void>   fichiers = tableau de { arbre, cible } ; seul appelant : le bouton de l'encart
//   finirRelecture() -> void                           retire la couche `relecture` ; appelée au retrait du curseur et au départ de l'onglet
// Le canal est celui de la Phase 75 (window.VF_MARQUES, 75-vf-marques.js) : couche EXCLUSIVE `relecture`, une rangée [id, palier, glyphe, mot, infobulle] par
// fichier de l'arbre principal (id `f:<chemin>`) ; les fichiers d'un worktree ne marquent aucune carte du lab. Ce module se charge avant le canal : il ne lit
// window.VF_MARQUES qu'au geste (corps de fonction), jamais au chargement. Canal absent : la pose est déposée dans window.VF_MARQUES_EN_ATTENTE, que le canal
// vide à son chargement. L'onglet Code s'ouvre par window.VF_ONGLETS.aller('code') (80-10), VF_COQUILLE.chargerOnglet('code') en repli.
// Écart au plan : plus de mécanisme provisoire du moteur ni de clé de repli en sessionStorage (décision déléguée par Samuel, message session principale,
// 2026-11-08, option recommandée ; prise par la session principale le 2026-11-13 ; amende P74-D-47).
(() => {
  'use strict';
  const W = window, COUCHE = 'relecture', ESSAIS = 10, PAUSE_MS = 100;
  const annoncer = (t) => { const F = W.__vfFrise; if (F && typeof F.annoncer === 'function') F.annoncer(t); };
  const pause = (ms) => new Promise((ok) => setTimeout(ok, ms));
  const rangees = (fichiers, titre) => fichiers
    .filter((f) => f && f.arbre === null && typeof f.cible === 'string' && f.cible !== '')
    .map((f) => [`f:${f.cible}`, null, 'relecture', 'relu', titre]);
  const ouvrirCode = () => new Promise((ok) => {
    const O = W.VF_ONGLETS, C = W.VF_COQUILLE;
    if (O && typeof O.aller === 'function') ok(O.aller('code'));
    else if (C && typeof C.chargerOnglet === 'function') ok(C.chargerOnglet('code'));
    else throw new Error('aucun routage d\'onglet');
  });
  const poser = (entrees) => {
    const V = W.VF_MARQUES;
    if (V && typeof V.poser === 'function') return V.poser(COUCHE, entrees, { exclusif: true }) === true;
    W.VF_MARQUES_EN_ATTENTE = Array.isArray(W.VF_MARQUES_EN_ATTENTE) ? W.VF_MARQUES_EN_ATTENTE : [];
    W.VF_MARQUES_EN_ATTENTE.push({ couche: COUCHE, entrees, exclusif: true });
    return true;
  };

  async function voirSurLaCarte(fichiers, titre) {
    const lignes = rangees(Array.isArray(fichiers) ? fichiers : [], String(titre || ''));
    try { await ouvrirCode(); } catch { annoncer("L'onglet Code n'a pas pu s'ouvrir."); return; }
    if (!lignes.length) return;
    for (let i = 0; i < ESSAIS; i++) { // le canal ne s'ouvre qu'à l'arrivée sur Code : quelques reprises courtes
      if (poser(lignes)) return;
      await pause(PAUSE_MS);
    }
    annoncer("Les fichiers n'ont pas pu être marqués sur la carte.");
  }
  function finirRelecture() {
    const V = W.VF_MARQUES;
    if (V && typeof V.retirer === 'function') { try { V.retirer(COUCHE); } catch { /* canal fermé : rien à retirer */ } }
    const f = W.VF_MARQUES_EN_ATTENTE;
    if (Array.isArray(f)) for (let i = f.length - 1; i >= 0; i--) if (f[i] && f[i].couche === COUCHE) f.splice(i, 1);
  }

  const rappel = (a) => {
    const F = W.__vfFrise;
    if (!a || a.onglet !== 'equipe' || !F) return undefined;
    F.voirSurLaCarte = voirSurLaCarte; F.finirRelecture = finirRelecture;
    return () => {}; // le départ retire la couche par le nettoyage du curseur (finirRelecture)
  };
  const C = W.VF_COQUILLE;
  if (C && typeof C.surOnglet === 'function') C.surOnglet(rappel, { cle: '74-vf-frise-carte.js' });
})();
