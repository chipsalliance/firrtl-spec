# Compute a version to use for the specification based on the latest tag.
VERSION=$(shell git describe --tags --dirty --match 'v*.*.*' | sed 's/^v//')

IMG_SRCS=$(wildcard include/img_src/*.dot)
IMG_EPSS=$(IMG_SRCS:include/img_src/%.dot=build/img/%.eps)

.PHONY: all clean images
.PRECIOUS: build/ build/img/

all: build/spec.pdf build/abi.pdf

clean:
	rm -rf build

images: $(IMG_EPSS)

PANDOC_FLAGS=\
	--template include/spec-template.tex \
	--syntax-definition include/firrtl.xml \
	--syntax-definition include/ebnf.xml \
	-r markdown+table_captions+inline_code_attributes+gfm_auto_identifiers \
	--filter pandoc-crossref \
	--metadata version:$(VERSION)

build/spec.pdf: spec.md revision-history.yaml include/spec-template.tex include/firrtl.xml include/ebnf.xml $(IMG_EPSS) | build/
	pandoc $< --metadata-file=revision-history.yaml $(PANDOC_FLAGS) -o $@

build/abi.pdf: abi.md revision-history.yaml include/spec-template.tex include/firrtl.xml $(IMG_EPSS) | build/
	pandoc $< --metadata-file=revision-history.yaml $(PANDOC_FLAGS) -o $@

build/img/%.eps: include/img_src/%.dot | build/img/
	dot -Teps $< -o $@

build/ build/img/:
	mkdir -p $@
