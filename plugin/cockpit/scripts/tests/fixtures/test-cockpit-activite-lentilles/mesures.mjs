// mesures.mjs — les mesures navigateur du plan 75-08, une fonction par section (t1 : tâche 1, t2 : tâche 2, t3 : tâche 3). Chaque fonction rend un objet JSON simple.
import { mesuresT1 } from './mesures-t1.mjs';
import { mesuresT2 } from './mesures-t2.mjs';
import { mesuresT3 } from './mesures-t3.mjs';
export const sections = { ...mesuresT1, ...mesuresT2, ...mesuresT3 };
