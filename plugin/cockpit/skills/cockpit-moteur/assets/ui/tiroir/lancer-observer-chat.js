function installerObservateurChat(fenetre, rappel, extraire = extraireSessionChat) {
  const natif = fenetre.fetch;
  if (typeof natif !== 'function') return;
  const lire = async (copie) => {
    const lecteur = copie.body.getReader(), dec = new TextDecoder(); let texte = '';
    for (;;) { const m = await lecteur.read(); if (m.done) break; texte += dec.decode(m.value, { stream: true }); if (texte.length > 262144) { lecteur.cancel(); break; } }
    return texte;
  };
  // activation utilisateur réelle (F-1, P72-D-21) : lue AU MOMENT de l'appel (jamais à la réponse) par les accesseurs natifs saisis à l'installation ; absente ou illisible : faux (échec fermé)
  const acc = (o, k) => { try { const d = o && Object.getOwnPropertyDescriptor(o, k); return d && typeof d.get === 'function' ? d.get : null; } catch (e) { return null; } };
  const gNav = acc(fenetre.Navigator && fenetre.Navigator.prototype, 'userActivation'), gAct = acc(fenetre.UserActivation && fenetre.UserActivation.prototype, 'isActive');
  const actif = () => { try { const ua = gNav ? gNav.call(fenetre.navigator) : fenetre.navigator.userActivation; return (gAct ? gAct.call(ua) : ua.isActive) === true; } catch (e) { return false; } };
  fenetre.fetch = function (entree, init) {
    const humain = actif(); // garde:activation
    const promesse = natif.apply(fenetre, arguments);
    try {
      const url = typeof entree === 'string' ? entree : (entree && entree.url) || '';
      const corps = init && typeof init.body === 'string' ? JSON.parse(init.body) : null;
      if (humain && init && String(init.method).toUpperCase() === 'POST' && new URL(url, fenetre.location.href).pathname === '/api/ask' && corps && typeof corps === 'object' && (corps.mode === undefined || corps.mode === 'ask')) {
        Promise.resolve(promesse).then((reponse) => { try { return lire(reponse.clone()).then((t) => { const id = extraire(t); if (id) rappel(id); }, () => {}); } catch (e) { return undefined; } }, () => {});
      }
    } catch (e) { void e; } // une enveloppe qui échoue laisse passer la requête telle quelle
    return promesse;
  };
}
