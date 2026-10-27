# Rapport du mini-projet

Le document principal est `main.tex`. Le PDF `main.pdf` correspond à la version révisée
des sources. Les sections, figures, logos et références sont inclus dans ce dossier.

## Compilation

Le projet utilise `biblatex` avec le backend **BibTeX** :

```text
pdflatex main.tex
bibtex main
pdflatex main.tex
pdflatex main.tex
```

`latexmk -pdf main.tex` ou un projet Overleaf avec compilation pdfLaTeX conviennent aussi.
Le PDF livré a été compilé avec Tectonic, puis rendu en images pour vérification.

Les originaux des captures ModelSim sont conservés dans `figures/`. La commande
`simcapture` affiche les signaux et l'axe temporel en masquant les panneaux et l'espace
vide ; elle ne change ni les valeurs ni les instants visibles sur les captures.

Les programmes et la procédure de vérification se trouvent à la racine du dépôt, dans
`programmes/` et `validation/`.
