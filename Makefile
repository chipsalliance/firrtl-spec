all: build/spec.pdf

IMGSRC=$(wildcard include/img_src/*.dot) 
IMGS=$(foreach dotfile,$(IMGSRC),build/img/$(patsubst %.dot,%.png,$(lastword $(subst /, ,$(dotfile)))))
build/spec.pdf: spec.md include/spec-template.tex include/firrtl.xml include/ebnf.xml $(IMGS) | build/
	pandoc $< --template include/spec-template.tex --syntax-definition include/firrtl.xml --syntax-definition include/ebnf.xml -r markdown+table_captions+inline_code_attributes+gfm_auto_identifiers --filter pandoc-crossref -o $@

build/img/%.png: include/img_src/%.dot | build/img/
	dot -Tpng $< -o $@

clean:
	rm -rf build

%/:
	mkdir -p $@
