# Compute a version to use for the specification based on the latest tag.
VERSION=$(shell git describe --tags --dirty --match 'v*.*.*' | sed 's/^v//')

IMG_SRCS=$(shell find include/img_src/ -type f -name '*.dot')
IMG_EPSS=$(IMG_SRCS:include/img_src/%.dot=build/%.eps)
IMG_PNG=$(IMG_SRCS:include/img_src/%.dot=build/%.png)

.PHONY: all clean format images test
.PRECIOUS: build/ build/img/

all: build/spec.pdf build/abi.pdf

clean:
	rm -rf build

format:
	find . -type f -name '*.md' -exec ./scripts/format.sh {} ';'

images: $(IMG_EPSS) $(IMG_PNGS)

test: build/spec.pdf build/abi.pdf | build/
	find build/ -type f -name '*.fir' | xargs -n1 firtool -parse-only -disable-annotation-unknown -o /dev/null
	find build/ -type f -name '*.v' | xargs -n1 verilator --default-language 1364-2005 -Wall -Wno-DECLFILENAME -Wno-UNDRIVEN -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM -Wno-MULTITOP --lint-only -o /dev/null
	find build/ -type f -name '*.sv' | xargs -n1 verilator --default-language 1800-2017 -Wall -Wno-DECLFILENAME -Wno-UNDRIVEN -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM -Wno-MULTITOP --lint-only -o /dev/null

PANDOC_FLAGS=\
	--pdf-engine=latexmk \
	--pdf-engine-opt=-logfilewarninglist \
	--pdf-engine-opt=-Werror \
	--template include/spec-template.tex \
	--syntax-definition include/firrtl.xml \
	--syntax-definition include/ebnf.xml \
	-r markdown+table_captions+inline_code_attributes+gfm_auto_identifiers \
	--filter pandoc-crossref \
	--lua-filter scripts/extract-firrtl-code.lua \
	--metadata version:$(VERSION)

build/%.pdf: %.md %.yaml revision-history.yaml include/contributors.json include/common.yaml include/spec-template.tex include/firrtl.xml include/ebnf.xml scripts/extract-firrtl-code.lua $(IMG_EPSS) | build/
	pandoc $< --metadata-file $*.yaml --metadata-file=revision-history.yaml --metadata-file=include/contributors.json --metadata-file=include/common.yaml $(PANDOC_FLAGS) -o $@

build/%.eps: include/img_src/%.dot | build/
	dot -Teps $< -o $@

build/%.png: include/img_src/%.dot | build/
	dot -Tpng $< -o $@

build/:
	mkdir -p $@
