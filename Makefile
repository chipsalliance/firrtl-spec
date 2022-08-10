IMG_SRCS=$(wildcard include/img_src/*.dot)
IMG_EPSS=$(foreach dotfile,$(IMG_SRCS),build/img/$(patsubst %.dot,%.eps,$(lastword $(subst /, ,$(dotfile)))))

.PHONY: all clean images
.PRECIOUS: build/ build/img/

all: build/spec.pdf

clean:
	rm -rf build

images: $(IMG_EPSS)

PANDOC_FLAGS=\
	--template include/spec-template.tex \
	--syntax-definition include/firrtl.xml \
	--syntax-definition include/ebnf.xml \
	-r markdown+table_captions+inline_code_attributes+gfm_auto_identifiers \
	--filter pandoc-crossref

build/spec.pdf: spec.md include/spec-template.tex include/firrtl.xml include/ebnf.xml $(IMG_EPSS) | build/
	pandoc $< $(PANDOC_FLAGS) -o $@

build/img/%.eps: include/img_src/%.dot | build/img/
	dot -Teps $< -o $@

build/ build/img/:
	mkdir -p $@
