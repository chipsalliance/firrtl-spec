
all: build/spec.pdf

build/spec.pdf: spec.md include/spec-template.tex include/firrtl.xml include/ebnf.xml | build/
	pandoc $< --template include/spec-template.tex --syntax-definition include/firrtl.xml --syntax-definition include/ebnf.xml -r markdown+table_captions+inline_code_attributes+gfm_auto_identifiers --filter pandoc-crossref -o $@

clean:
	rm -rf build

%/:
	mkdir $@
