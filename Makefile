all: build/spec.pdf

IMG_SRCS=$(wildcard include/img_src/*.dot)
IMG_EPSS=$(foreach dotfile,$(IMG_SRCS),build/img/$(patsubst %.dot,%.eps,$(lastword $(subst /, ,$(dotfile)))))

images: $(IMG_EPSS)

build/spec.pdf: spec.md include/spec-template.tex include/firrtl.xml include/ebnf.xml $(IMG_EPSS) | build/
	pandoc $< --template include/spec-template.tex --syntax-definition include/firrtl.xml --syntax-definition include/ebnf.xml -r markdown+table_captions+inline_code_attributes+gfm_auto_identifiers --filter pandoc-crossref -o $@

build/img/%.eps: include/img_src/%.dot | build/img/
	dot -Teps $< -o $@

clean:
	rm -rf build

%/:
	mkdir -p $@
