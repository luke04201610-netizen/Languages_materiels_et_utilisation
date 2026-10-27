# Vérification du rapport

Les exercices utilisés dans le rapport sont les variantes de `exo/`. Les dossiers
`partie2/` à `partie5/` contiennent une autre version du travail et ne doivent pas être
mélangés aux sources de `exo/` dans une même bibliothèque.

## Reproduire les simulations

Depuis la racine du dépôt, avec Python 3 et ModelSim SE-64 2020.4 :

```text
python validation/run_modelsim.py --modelsim-bin C:/modeltech64_2020.4/win64
```

Le script crée une bibliothèque isolée pour chaque scénario dans
`tmp/pdfs/report-validation/`. Il compile les fichiers de `exo/`, applique les paramètres
et l'option `+prog`, vérifie les valeurs lues et le temps de fin. Il ne remplace aucun
programme d'entrée et n'utilise pas les bibliothèques de la session graphique.

Le dernier résultat vérifié est conservé dans `results.json` : **28 scénarios réussis, 167 comparaisons de valeurs**.
Les journaux complets sont régénérés localement dans le dossier de travail ignoré par Git.

Certains cas demandent une interprétation particulière :

- Les cas `cpu_original_*_known_defect*` vérifient que les défauts du modèle d'origine
  sont reproduits. Leur réussite ne signifie pas que ce modèle est correct.
- Le cas `cpu_original_rv32m_unsupported` vérifie onze instructions M non reconnues
  par le modèle initial, ainsi que les onze messages correspondants.
- Le cas `system_instr_uninitialised_external_data` vérifie que le premier programme
  atteint la fin avec x1 et x2 indéfinis lorsque la RAM externe n'a pas été initialisée.
  Il sert de contre-exemple à comparer à `instr2.txt`.

Les avertissements de métavaleurs au démarrage des RAM sont attendus. Les erreurs de
compilation, assertions de sévérité `error` ou `failure`, valeurs inattendues et temps de
fin incorrects font échouer le contrôle.

## Programmes fournis

`programmes/instr.txt` est une copie du premier programme retrouvé dans le dossier local
de téléchargement. Le fichier contient six instructions, puis deux mots initialisés par
la directive `@40`. Il n'a pas été reconstruit à partir de `instr2.txt`.

SHA-256 du fichier conservé :

```text
41559a8d2dc9096f6925c23b1dff475e620ae35c2c171ec0aa283db8f6e0f409
```

Les processeurs de `exo/` acceptent désormais `+prog=chemin`. Sans cette option, chacun
conserve le fichier par défaut de son exercice. Les dimensions de RAM des exercices Q4
et Q5 sont de type `positive` ; les configurations valides précédentes sont inchangées.
