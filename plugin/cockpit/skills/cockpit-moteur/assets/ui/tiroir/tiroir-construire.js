function construireTiroir(document, textes) {
  const NS = 'http:' + '//www.w3.org/2000/svg'; // espace de noms SVG, construit par concaténation : le script servi ne porte aucune adresse web entière
  const el = (tag, cls, txt) => { const e = document.createElement(tag); if (cls) e.className = cls; if (txt !== undefined) e.textContent = txt; return e; };
  const picto = (d) => {
    const s = document.createElementNS(NS, 'svg'); s.setAttribute('viewBox', '0 0 16 16'); s.setAttribute('aria-hidden', 'true');
    const p = document.createElementNS(NS, 'path'); p.setAttribute('d', d); s.appendChild(p); return s;
  };
  const bouton = (cls, libelle, d) => { const b = el('button', 'vf-term-bouton ' + cls); b.type = 'button'; b.setAttribute('aria-label', libelle); b.title = libelle; b.appendChild(picto(d)); return b; };

  const pastille = el('button', 'vf-term-pastille'); pastille.type = 'button';
  pastille.setAttribute('aria-label', textes.ouvrir); pastille.title = textes.ouvrir;
  pastille.setAttribute('data-vf-flottant', 'bouton'); // attribut neutre : les extensions de la page lisent celui-ci, jamais la classe ni la forme
  pastille.appendChild(picto('M3 4l4 4-4 4 M9 12h4'));
  pastille.appendChild(el('span', 'vf-term-libelle', textes.pastille));
  const point = el('span', 'vf-term-point'); point.hidden = true; pastille.appendChild(point);

  const region = el('section', 'vf-term-tiroir'); region.setAttribute('role', 'region'); region.setAttribute('aria-label', textes.titre); region.hidden = true; region.inert = true; region.setAttribute('data-vf-flottant', 'tiroir');
  const poignee = el('div', 'vf-term-poignee'); poignee.setAttribute('role', 'separator'); poignee.setAttribute('aria-orientation', 'horizontal');
  poignee.setAttribute('aria-label', textes.poignee); poignee.setAttribute('aria-valuemin', '160'); poignee.tabIndex = 0; poignee.appendChild(el('span', 'vf-term-grip'));
  const corps = el('div', 'vf-term-corps');
  const barre = el('div', 'vf-term-barre');
  const etatPoint = el('span', 'vf-term-etat-point'); etatPoint.setAttribute('data-etat', 'inactif');
  const etatTexte = el('span', 'vf-term-etat');
  const boutonPlein = bouton('vf-term-plein', textes.agrandir, 'M3 6V3h3 M13 6V3h-3 M3 10v3h3 M13 10v3h-3'); boutonPlein.setAttribute('aria-pressed', 'false');
  const boutonFermer = bouton('vf-term-fermer', textes.fermer, 'M4 4l8 8 M12 4l-8 8');
  // AUDC-M10 : « Terminer la session » (le mot et un glyphe, jamais une teinte d'alerte), caché tant qu'aucune session ne tourne ; double geste (le script pose le texte de confirmation)
  const boutonTerminer = el('button', 'vf-term-bouton vf-term-terminer'); boutonTerminer.type = 'button'; boutonTerminer.hidden = true; boutonTerminer.title = textes.terminerAide;
  boutonTerminer.setAttribute('aria-label', textes.terminer); boutonTerminer.appendChild(picto('M4 4h8v8H4z')); boutonTerminer.appendChild(el('span', 'vf-term-terminer-texte', textes.terminer));
  [etatPoint, el('span', 'vf-term-titre', textes.titre), etatTexte, el('span', 'vf-term-espace'), boutonTerminer, boutonPlein, boutonFermer].forEach((n) => barre.appendChild(n));
  const emplacementCadre = el('div', 'vf-term-zone');
  const charge = el('div', 'vf-term-charge', textes.charge); charge.hidden = true; emplacementCadre.appendChild(charge);
  corps.appendChild(barre); corps.appendChild(emplacementCadre);
  region.appendChild(poignee); region.appendChild(corps);

  const annonce = el('div', 'vf-term-annonce'); annonce.setAttribute('role', 'status'); annonce.setAttribute('aria-live', 'polite');
  const puce = el('div', 'vf-term-puce'); puce.setAttribute('role', 'status'); puce.setAttribute('data-vf-flottant', 'etat');
  const carteInjoignable = el('div', 'vf-term-carte'); carteInjoignable.setAttribute('role', 'alert'); carteInjoignable.tabIndex = -1;
  carteInjoignable.appendChild(document.createTextNode(textes.injoignable));
  const colle = el('span', 'vf-term-insecable'); colle.appendChild(el('code', '', textes.commande)); colle.appendChild(document.createTextNode('.')); carteInjoignable.appendChild(colle); // commande et point final ne se coupent jamais
  return { pastille, point, region, barre, etatPoint, etatTexte, boutonPlein, boutonFermer, boutonTerminer, poignee, emplacementCadre, charge, annonce, puce, carteInjoignable };
}
