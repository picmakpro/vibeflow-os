// VibeFlow (80-04) : rendu pur des couloirs de Projet — des chaînes HTML, JAMAIS une donnée du lab concaténée :
// tout texte passe par `h()` du moteur (T-80-07). Entrée : le modèle de 41-vf-projet-modele.js (window.__vfProjetModele).
// Exposé : window.__vfProjetRendu { vue, blocJalon, couloir, carte, historique, listes, etatVue }.
(() => {
  const SC = window.Floorplan, M = window.__vfProjetModele;
  if (!SC || !M) return;
  const h = SC.h, sain = (id) => String(id).replace(/[^\w-]/g, '_');
  const pastille = (st, mot) => `<span class="vst vst-${h(st)}">${h(mot)}</span>`;
  const decrit = (x) => (x.coupe ? ` aria-describedby="vp-d-${sain(x.id)}"` : '');
  const complet = (x) => (x.coupe ? `<span id="vp-d-${sain(x.id)}" hidden>${h(x.complet)}</span>` : '');

  const carte = (c, o) => {
    const cur = o.sel === c.id ? ' aria-current="true"' : '';
    const etat = c.ligne ? h(c.ligne) + (c.preuve ? ` · <span class="vp-preuve">${h(c.preuve)}</span>` : '') : '';
    return `<li><button type="button" class="vp-carte" data-id="${h(c.id)}" tabindex="-1" aria-label="${h(c.nom)}"${decrit(c)}${cur}>`
      + `<span class="vp-num">${h(c.num)}</span><span class="vp-titre">${h(c.titre)}</span>`
      + `<span class="vp-etat"${c.ligne ? '' : ' aria-hidden="true"'}>${etat}</span></button>${complet(c)}</li>`;
  };
  const couloir = (def, cartes, o) => {
    const [cle, mot, st] = def, n = cartes.length, nom = `${mot}, ${n} phase${n > 1 ? 's' : ''}`;
    const corps = n ? `<ul class="vp-cartes">${cartes.map((c) => carte(c, o)).join('')}</ul>` : '<p class="vp-vide">aucune phase</p>';
    return `<div class="vp-couloir" role="group" aria-label="${h(nom)}" data-couloir="${h(cle)}"><h3 class="vp-ch">`
      + `<span class="vst vst-${h(st)} vp-gl" aria-hidden="true"></span><span class="vp-mot">${h(mot)}</span><span class="vp-n">${n}</span></h3>${corps}</div>`;
  };
  const blocJalon = (b, o) => {
    const id = 'vp-j-' + sain(b.jalon), texte = M.synthese(b.faites, b.total, 0);
    const barre = `<div class="vp-barre"><div class="vf-bar${b.enCours ? ' st-active' : ''}" role="progressbar" aria-valuemin="0" aria-valuemax="100"`
      + ` aria-valuenow="${b.pourcent}" aria-label="Avancement du jalon" aria-valuetext="${h(texte)}"><i style="width:${b.pourcent}%"></i></div>`
      + `<span class="vp-pc" aria-hidden="true">${b.pourcent} %</span></div>`;
    const cs = b.total ? `<div class="vp-couloirs">${M.COULOIRS.map((d) => couloir(d, b.couloirs[d[0]], o)).join('')}</div>` : '<p class="vp-vide">aucune phase</p>';
    return `<section class="vp-jalon" aria-labelledby="${id}" data-jalon="${h(b.jalon)}"><div class="vp-jt"><div class="vp-jn"><h2 id="${id}">${h(b.nom)}</h2>`
      + `<p class="vp-syn">${h(b.synthese)}</p></div>${barre}</div>${cs}</section>`;
  };
  const rangee = (r, o, avecPastille = true) => {
    const cur = o.sel === r.id ? ' aria-current="true"' : '', date = r.date ? `<span class="vp-r-d">${h(r.date)}</span>` : '';
    return `<li><button type="button" class="vp-rangee" data-id="${h(r.id)}" tabindex="-1"${decrit(r)}${cur}><span class="vp-r-t">${h(r.titre)}</span>`
      + `${date}${avecPastille && !r.date ? pastille(r.st, r.mot) : ''}</button>${complet(r)}</li>`;
  };
  const disclosure = (cle, titre, compte, lignes, ouverts) => `<details class="vp-details" data-cle="${h(cle)}"${ouverts && ouverts.has(cle) ? ' open' : ''}>`
    + `<summary><span class="vp-sum-t">${h(titre)}</span><span class="vp-n">${h(compte)}</span></summary><ul class="vp-rangees">${lignes.join('')}</ul></details>`;
  const historique = (hist, o) => (hist ? disclosure('historique', 'Historique', hist.resume,
    hist.lignes.map((l) => rangee({ id: l.id, titre: l.nom, coupe: false, date: l.texte }, o, false)), o.ouverts) : '');
  const listes = (ls, o) => ls.map((l) => disclosure(l.cle, l.titre, l.compte, l.rows.map((r) => rangee(r, o)), o.ouverts)).join('');
  const etatVue = (texte, detail) => `<div class="vp-info"><p>${h(texte)}</p>${detail ? `<p>${h(detail)}</p>` : ''}</div>`;

  const vue = (m, o) => {
    const info = m.blocs.length ? '' : etatVue('Aucun jalon dans la planification. Le ROADMAP du dépôt ne déclare ni jalon ni phase.',
      'Le format attendu est décrit dans « Format de la planification », dans la vue d\'ensemble du panneau.');
    return info + m.blocs.map((b) => blocJalon(b, o)).join('') + `<div class="vp-listes">${historique(m.historique, o)}${listes(m.listes, o)}</div>`;
  };
  window.__vfProjetRendu = Object.freeze({ vue, blocJalon, couloir, carte, historique, listes, etatVue });
})();
