This repository hosts the specification for the FIRRTL language.

To build this, you need the following:

- [`pandoc`](https://pandoc.org/)
- [`pandoc-crossref`](https://lierdakil.github.io/pandoc-crossref/)
- A LaTeX distribution, e.g., [`TeX Live`](https://tug.org/texlive/)
- [`latexmk`](https://ctan.org/pkg/latexmk?lang=en) which may come with your LaTeX distribution
- [Graphviz](https://graphviz.org/)

After resolving these dependencies, run `make` to compile `spec.md` into `build/spec.pdf`.
