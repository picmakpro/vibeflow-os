// VibeFlow (73-05) : la régie de l'onglet Équipe : adaptateur de source unique (VF_ETAT, sinon vf-who et __vfLive), montage par onglet (VF_COQUILLE.surOnglet),
// registre des vues de la Phase 74, événements annulables vf-agent:*, ancres, recherche, Échap, lecteur de repli. Le rendu est dans 72-vf-regie-rendu.js.
// Rien ne se dessine au chargement du script avec la coquille : le montage a lieu au rappel de surOnglet,
// son nettoyage retire tout (écouteurs, abonnements, minuteries, DOM).
(() => {
  const W = window, D = document, CLE = '72-vf-regie-source.js', CLE_VUE = 'vibeflow-cockpit:equipe-vue', DELAI_COUPE = 15000;
  const vues = [{ id: 'regie', libelle: 'Régie' }];
  let attente = null; // ancre n:se-… / n:ag-… reçue avant le montage ou avant l'arrivée du who : consommée au premier rendu où la ligne existe
  let monte = null; // le montage de l'onglet courant : jamais gardé d'une exécution à l'autre (la clé sessionStorage est la seule mémoire)

  // ---------- registre des vues : la Phase 74 s'y déclare (frise) ----------
  const declarer = (v) => {
    if (!v || typeof v !== 'object' || !/^[a-z0-9-]{1,32}$/.test(String(v.id))) return false;
    if (typeof v.libelle !== 'string' || !v.libelle || v.libelle.length > 40) return false;
    const fn = (f) => (typeof f === 'function' ? f : null), vue = { id: v.id, libelle: v.libelle, monter: fn(v.monter), demonter: fn(v.demonter) };
    const i = vues.findIndex((x) => x.id === v.id);
    if (v.id === 'regie') return false;
    if (i >= 0) vues[i] = vue; else vues.push(vue);
    if (monte) monte.declaree(vue);
    return true;
  };
  W.__vfEquipeVues = { declarer, vues: () => vues.map((v) => ({ id: v.id, libelle: v.libelle })) };

  // ---------- l'adaptateur : le seul endroit qui sait d'où viennent who, lock, la connexion et le jeton ----------
  const adaptateur = () => {
    const E = W.VF_ETAT, L = () => W.__vfLive || {}, S = () => W.FLOORPLAN_SERVER || null;
    const jeton = () => (E ? E.jeton() : null) || (S() && S().token) || null;
    return {
      who: () => (E ? E.lire('who') : L().who) || null, lock: () => (E ? E.lire('lock') : L().lock) || null, jeton,
      whoAt: () => (E ? null : L().whoAt),
      perdu: () => (E ? !!E.lire('connexion') && E.lire('connexion') !== 'ouvert' : L().connected === false && !!L().who),
      ecouter: (f) => {
        if (E) return ['who', 'lock', 'connexion', 'graphe'].map((k) => E.abonner(k, () => f(k)));
        D.addEventListener('vf-who', f); return [() => D.removeEventListener('vf-who', f)];
      },
      // les missions en cours : meta.vf.missions de l'enveloppe de l'onglet (le graphe posé par la coquille),
      // relue par la route quand VF_ETAT annonce que l'enveloppe a changé
      missions: (g) => { const v = g && g.meta && g.meta.vf; return Array.isArray(v && v.missions) ? v.missions.filter((m) => typeof m === 'string') : []; },
      graphe: () => (E ? E.lireJson('/api/vf/graphe?onglet=equipe') : Promise.resolve(null)),
      graphePose: () => (E && E.lire('graphe') && E.lire('graphe').onglet) || null,
      transcript: (id) => {
        const chemin = '/api/vf/transcript?id=' + encodeURIComponent(id);
        if (E) return E.lireJson(chemin);
        return W.fetch(chemin, { headers: { 'x-floorplan-token': jeton() }, cache: 'no-store' }).then((r) => (r.ok ? r.json() : null));
      },
    };
  };
  const emettre = (type, detail, annulable) => D.dispatchEvent(new CustomEvent(type, { detail, cancelable: annulable, bubbles: true }));

  // ---------- le lecteur de repli (P73-D-33) : le transcript réduit, dans le panneau latéral ; la Phase 74 le retire d'un geste ----------
  async function ouvrirRepli(A, id, ouvreur, nom) {
    const SC = W.Floorplan; if (!SC || typeof SC.showPanel !== 'function') return;
    let d = null; try { d = await A.transcript(id); } catch { d = null; }
    if (!monte) return; // l'onglet a changé pendant la lecture
    const lecteur = W.__vfEquipeRendu.transcript(d, D);
    SC.showPanel('', (p) => {
      const sec = D.createElement('div'), t = D.createElement('h2'); sec.className = 'sec'; t.className = 'pt'; t.textContent = nom;
      sec.append(t, lecteur); p.replaceChildren(sec);
    });
    const P = D.getElementById('panel'), O = W.VF_SURCOUCHES;
    if (P && P.classList) P.classList.add('vf-rg-lecteur'); // la feuille masque le contenu par défaut du moteur ; seul le lecteur la montre
    if (O && P) O.ouvrir(P, { modale: false, ouvreur, fermer: () => { if (P.classList) P.classList.remove('vf-rg-lecteur'); SC.closePanel(); O.fermer(P); } });
    // 73-08 (UIFN-12) : le bouton quitte la ligne une fois le rapport lu ; le focus passe au titre du lecteur, jamais à body
    const T = P && P.querySelector('.pt'); if (T) { T.tabIndex = -1; T.focus({ preventScroll: true }); }
    emettre('vf-agent:lu', { id }, false);
  }

  function monter() {
    if (!D.body) return () => {};
    const QS = W.__vfRegieQuestions || {}, A = adaptateur(), P = W.__vfRegiePied, R = W.__vfRegieRendu;
    const racine = D.createElement('section'), recherche = D.getElementById('search');
    racine.id = 'vf-equipe'; racine.setAttribute('role', 'main'); racine.setAttribute('aria-busy', 'true');
    D.body.append(racine); D.body.classList.add('vf-regie-montee');
    const ui = R.monter(racine), nettoyerPied = P.monter(racine), retraits = [], minuteries = [];
    let missions = A.missions((W.Floorplan && W.Floorplan.graph) || W.VF_COCKPIT);
    let vivant = true, recu = Date.now(), coupeT0 = null, fige = null, tCoupe = null, lectureT0 = Date.now(), choisie = 'regie', luHash = null, tm = null;
    const sess = (k) => { try { return W.sessionStorage.getItem(k); } catch { return null; } };
    const ecouter = (cible, type, f) => { cible.addEventListener(type, f); retraits.push(() => cible.removeEventListener(type, f)); };

    // ---------- dessin : who et lock lus par l'adaptateur, jamais ailleurs ----------
    const rendre = () => {
      if (!vivant) return;
      const who = A.who(), M = W.__vfRegieModele, now = Date.now(), perdu = A.perdu(), sansDirect = !A.jeton();
      if (!perdu) { coupeT0 = null; fige = null; } else if (coupeT0 === null) coupeT0 = now;
      if (perdu && fige === null && now - coupeT0 >= DELAI_COUPE) fige = now;
      if (perdu && fige === null && tCoupe === null) tCoupe = setTimeout(() => { tCoupe = null; rendre(); }, DELAI_COUPE - (now - coupeT0));
      const recuA = A.whoAt() || recu, lus = W.__vfRegieLu && typeof W.__vfRegieLu.lus === 'function' ? W.__vfRegieLu.lus() : null;
      if (!who && !sansDirect) { P.maj({ lecture: true, muet: now - lectureT0 < 150 }); return; }
      const m = M.modele(who || { workers: [] }, A.lock(), { now: fige !== null ? fige : now, recuA, lus, missions, nonCommite: P.nonCommite(),
        questions: QS.etat ? QS.etat() : undefined });
      ui.rendre(m, { sections: !sansDirect });
      if (recherche) ui.filtrer(recherche.value);
      P.maj({ direct: !sansDirect, aucun: !!m.etatPage, sources: who && who.sources, coupe: fige !== null ? (fige - recuA) / 1000 : null });
      toutMarquer(m);
      if (attente && ancre(attente.id, attente.kind)) attente = null;
    };
    const toutMarquer = (m) => { // « Tout marquer comme relu » : seulement si le module « lu » existe, dès trois lignes à relire (jamais de bouton mort)
      const lu = W.__vfRegieLu, ids = m.sections[2].ids || m.sections[2].lignes.map((l) => l.id);
      const tete = ui.titre('a-relire') && ui.titre('a-relire').parentNode;
      if (lu && typeof lu.toutMarquer === 'function' && ids.length >= 3 && tete) {
        if (!tm) {
          tm = D.createElement('button'); tm.className = 'btn'; tm.setAttribute('type', 'button'); tm.setAttribute('data-vf-tout', ''); tete.append(tm);
        }
        if (tm.textContent !== 'Tout marquer comme relu') tm.textContent = 'Tout marquer comme relu';
        tm._ids = ids;
      } else if (tm) { // le bouton qui porte le focus et quitte la page : le focus va au titre de sa section, jamais à body
        const avait = D.activeElement === tm, t = ui.titre('a-relire');
        tm.remove(); tm = null; if (avait && t) t.focus({ preventScroll: true });
      }
    };

    // ---------- ouverture d'une ligne : événement annulable, le comportement suit seulement si personne ne l'annule ----------
    const ouvrir = (li, declencheur, bouton) => {
      const l = li && li._ln; if (!l) return;
      if (!emettre('vf-agent:ouvrir', { id: l.id, kind: l.kind, declencheur }, true)) return;
      if (declencheur === 'rapport') { ouvrirRepli(A, l.id, bouton, l.nom); return; }
      ui.basculer(l.cle, declencheur === 'ancre' || !ui.deplie().includes(l.cle));
      if (declencheur === 'ancre') { li.scrollIntoView({ block: 'center' }); (li._t || li).focus(); }
    };
    const ancre = (id, kind) => {
      const l = ui.lignes(id).filter((li) => li._ln.kind === kind);
      const li = l.find((x) => x._ln.cle.startsWith('a-vous:')) || l[0];
      if (!li) return false;
      ouvrir(li, 'ancre'); return true;
    };
    const aller = (section) => {
      const t = typeof section === 'string' ? ui.titre(section) : null;
      if (t) { t.scrollIntoView({ block: 'start' }); t.focus(); }
    };
    const fragment = () => {
      const h = String(W.location.hash || ''); luHash = h;
      const r = new URLSearchParams(h.slice(1)).get('r'), m = /^#vf-([a-z-]+)$/.exec(h);
      if (r) {
        const a = /^n:(se|ag)-(.+)$/.exec(r), kind = a && (a[1] === 'se' ? 'session' : 'subagent');
        if (a && !ancre(a[2], kind)) attente = { id: a[2], kind };
      } else if (m) aller(m[1]);
    };

    // ---------- vues et bascule ----------
    const choisir = (id, garder) => {
      if (!vues.some((v) => v.id === id)) id = 'regie';
      const ancien = vues.find((v) => v.id === choisie);
      if (id !== choisie && ancien && ancien.demonter) { try { ancien.demonter(); } catch { /* une vue qui lève ne casse pas la régie */ } }
      choisie = id; ui.bascule(vues, choisie, (x) => choisir(x, true));
      const v = vues.find((x) => x.id === id);
      if (id !== 'regie' && v.monter) { try { v.monter(ui.vue(id)); } catch { /* idem */ } }
      if (garder) { try { W.sessionStorage.setItem(CLE_VUE, id); } catch { /* stockage refusé : la position ne se garde pas */ } }
    };
    const declaree = () => {
      ui.bascule(vues, choisie, (x) => choisir(x, true));
      const s = sess(CLE_VUE); if (s && s !== choisie && vues.some((v) => v.id === s)) choisir(s, false);
    };

    // ---------- clavier, clic, recherche ----------
    ecouter(racine, 'click', (e) => {
      // 00-vibeflow.js annule le clic de tout élément sous [data-vf-section] (lien, résumé de repli) : il s'arrête ici, sans preventDefault
      if (e.target && e.target.closest && e.target.closest('a[href], summary')) { e.stopPropagation(); return; }
      const b = e.target && e.target.closest ? e.target.closest('button, [data-vf-tout]') : null, li = b && b.closest('li[data-vf-cle]');
      if (!b) return;
      if (b.hasAttribute('data-vf-tout')) { if (tm && W.__vfRegieLu) { W.__vfRegieLu.toutMarquer(tm._ids); rendre(); } return; }
      if (li && b.classList.contains('vf-rg-tog')) ouvrir(li, 'nom', b);
      else if (li && b.classList.contains('vf-rg-caret')) ui.replier(li.getAttribute('data-vf-cle'));
      else if (li && b === li._b) ouvrir(li, 'rapport', b);
    });
    ecouter(D, 'keydown', (e) => {
      if (e.defaultPrevented) return;
      if (e.key === 'Enter' && recherche && e.target === recherche) { const li = ui.premiere(); if (li) { e.preventDefault(); li._t.focus(); } return; }
      if (e.key !== 'Escape') return;
      const o = ui.deplie(), a = D.activeElement, fl = a && a.closest ? a.closest('li[data-vf-cle]') : null;
      if (o.length) { // cran 2 : un détail déplié se replie, le focus revient à son bouton
        const li = ui.basculer(fl && o.includes(fl.getAttribute('data-vf-cle')) ? fl.getAttribute('data-vf-cle') : o[o.length - 1], false);
        e.preventDefault(); e.stopPropagation(); if (li && li._t) li._t.focus(); return;
      }
      if (recherche && recherche.value) { recherche.value = ''; ui.filtrer(''); e.preventDefault(); e.stopPropagation(); } // cran 3 ; cran 4 : rien
    });
    if (recherche) ecouter(recherche, 'input', () => ui.filtrer(recherche.value));
    ecouter(D, 'vf-regie:aller', (e) => aller(e.detail && e.detail.section));
    ecouter(D, 'vf-regie:redessiner', () => rendre());
    const nettoyerQ = QS.monter ? QS.monter(racine) : () => {}; // 73-11 : Échap des replis, après celui du détail en flux
    ecouter(D, 'vf:onglet', (e) => { if (e.detail && e.detail.onglet === 'equipe' && String(W.location.hash || '') !== luHash) fragment(); });
    const relireMissions = () => { // l'enveloppe d'Équipe a changé : on relit ses missions, le dessin suit ; une lecture refusée garde les missions connues
      if (A.graphePose() !== 'equipe') return;
      A.graphe().then((j) => { if (!vivant || !j) return; missions = A.missions(j); rendre(); }, () => {});
    };
    const surEtat = (cle) => {
      if (cle === 'graphe') { relireMissions(); return; }
      if (cle === 'who') { recu = Date.now(); P.surWho(); }
      rendre();
    };
    for (const d of A.ecouter(surEtat)) retraits.push(d);
    minuteries.push(setInterval(rendre, 30000));

    monte = { declaree: () => declaree(), ancre };
    declaree(); rendre();
    // avec VF_ONGLETS le fragment se lit à vf:onglet, émis après pushState (l'adresse du rappel est encore celle de l'onglet précédent)
    // au chargement de la page (aucun vf:onglet à venir) le fragment se lit ici ; lors d'une arrivée, vf:onglet le lit (luHash)
    if (!W.VF_ONGLETS) fragment(); else minuteries.push(setTimeout(() => { if (luHash === null) fragment(); }, 0));
    if (!A.who()) { minuteries.push(setTimeout(rendre, 150)); }
    return () => {
      vivant = false; monte = null;
      const v = vues.find((x) => x.id === choisie); if (v && v.demonter) { try { v.demonter(); } catch { /* idem */ } }
      for (const r of retraits.splice(0)) r();
      for (const t of minuteries.splice(0)) { clearInterval(t); clearTimeout(t); }
      if (tCoupe !== null) clearTimeout(tCoupe);
      nettoyerPied(); nettoyerQ(); racine.remove(); D.body.classList.remove('vf-regie-montee');
      const pn = D.getElementById('panel'); if (pn && pn.classList) pn.classList.remove('vf-rg-lecteur');
    };
  }

  // ---------- l'interface que lit 00-vibeflow.js (arrivée par #r=n:…) et le bouton « N au travail » ----------
  W.__vfRegie = {
    arriver: (r) => { // vrai pour toute ancre de ligne, même avant le montage : la ligne la consomme à son premier rendu
      const m = /^n:(se|ag)-(.+)$/.exec(String(r)); if (!m) return false;
      const kind = m[1] === 'se' ? 'session' : 'subagent';
      if (!(monte && monte.ancre(m[2], kind))) attente = { id: m[2], kind };
      return true;
    },
    monte: () => monte !== null,
  };
  const C = W.VF_COQUILLE;
  if (C && typeof C.surOnglet === 'function') C.surOnglet((a) => (a && a.onglet === 'equipe' ? monter() : undefined), { cle: CLE });
  else if (W.Floorplan && W.Floorplan.graph && W.Floorplan.graph.meta.vfTab === 'equipe') monter();
})();
