# Compute a version to use for the specification based on the latest tag.
VERSION=$(shell git describe --tags --dirty --match 'v*.*.*' | sed 's/^v//')

IMG_SRCS=$(shell find include/img_src/ -type f -name '*.dot')
IMG_EPSS=$(IMG_SRCS:include/img_src/%.dot=build/%.eps)
IMG_PNG=$(IMG_SRCS:include/img_src/%.dot=build/%.png)

.PHONY: all clean format images
.PRECIOUS: build/ build/img/

all: build/spec.pdf build/abi.pdf

clean:
	rm -rf build

format:
	find . -type f -name '*.md'	| xargs -IX pandoc -o X --wrap=preserve -t gfm+pipe_tables+attributes X

images: $(IMG_EPSS) $(IMG_PNGS)

PANDOC_FLAGS=\
	--pdf-engine=latexmk \
	--pdf-engine-opt=-logfilewarninglist \
	--pdf-engine-opt=-Werror \
	--template include/spec-template.tex \
	--syntax-definition include/firrtl.xml \
	--syntax-definition include/ebnf.xml \
	-r markdown+table_captions+inline_code_attributes+gfm_auto_identifiers \
	--filter pandoc-crossref \
	--metadata version:$(VERSION)

build/%.pdf: %.md %.yaml revision-history.yaml include/contributors.json include/common.yaml include/spec-template.tex include/firrtl.xml include/ebnf.xml $(IMG_EPSS) | build/
	pandoc $< --metadata-file $*.yaml --metadata-file=revision-history.yaml --metadata-file=include/contributors.json --metadata-file=include/common.yaml $(PANDOC_FLAGS) -o $@

build/%.eps: include/img_src/%.dot | build/
	dot -Teps $< -o $@

build/%.png: include/img_src/%.dot | build/
	dot -Tpng $< -o $@

build/:
	mkdir -p $@
