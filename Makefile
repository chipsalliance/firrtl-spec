all: build/spec.pdf

build/spec.pdf: spec.md include/spec-template.tex include/firrtl.xml include/ebnf.xml | build/
	pandoc $< --template include/spec-template.tex --syntax-definition include/firrtl.xml --syntax-definition include/ebnf.xml -r markdown+table_captions+inline_code_attributes+gfm_auto_identifiers --filter pandoc-crossref -o $@

IMG_SRC=$(wildcard include/img_src/*.dot) 
images: $(IMG_SRC) | build/ build/img/
	$(foreach dotfile,$(IMG_SRC),dot -Tpng $(dotfile) -o build/img/$(patsubst %.dot,%.png,$(lastword $(subst /, ,$(dotfile))));)

clean:
	rm -rf build

%/:
	mkdir $@
