function accepteMessage(e, origineQ, fenetreCadre, liste) {
  if (!e || e.isTrusted !== true) return false;
  if (e.origin !== origineQ) return false;
  if (!fenetreCadre || e.source !== fenetreCadre) return false;
  return typeof e.data === 'string' && liste.indexOf(e.data) >= 0;
}
