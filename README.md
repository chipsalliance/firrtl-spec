This repository hosts the specification for the FIRRTL language.

To build this, you need the following:

- [`pandoc`](https://pandoc.org/)
- [`pandoc-crossref`](https://lierdakil.github.io/pandoc-crossref/)
- A LaTeX distribution, e.g., [`TeX Live`](https://tug.org/texlive/)
- [`latexmk`](https://ctan.org/pkg/latexmk?lang=en) which may come with your LaTeX distribution
- [Graphviz](https://graphviz.org/)

For compatability with continuous integration (CI) testing, use the versions of
`pandoc` and `pandoc-crossref` that are [listed in the CI GitHub
Action](.github/workflows/continuous-integration-ci.yml). If this release is
*not* available in your package manager, you can download binaries from their
GitHub releases pages:
- [`pandoc` releases](https://github.com/jgm/pandoc/releases)
- [`pandoc-crossref` releases](https://github.com/lierdakil/pandoc-crossref/releases)

To run tests, you need Verilator and `firtool` available on your `PATH`.

After resolving these dependencies, use the following build targets:

- `make` or `make all` will compile will compile `spec.md` and `abi.md` into
  `build/spec.pdf` and `build/abi.pdf`.
- `make format` will format all Markdown files by round-tripping them through
  `pandoc`. *For this build step to be usable, use the exact versions of
  `pandoc` and `pandoc-crossref` that CI uses!*
- `make test` will extract FIRRTL and Verilog snippets from the specification
  and ABI document and, respectively, run them through `firtool -parse-only` or
  `verilator --lint-only` to test that they are legal FIRRTL or Verilog.
