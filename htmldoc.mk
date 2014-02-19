htmldoc: build/htmldoc build/htmldoc/src/index.html.md build/htmldoc/src/lib/index.html.md build/htmldoc/out build/htmldoc/out/adminpage.css build/htmldoc/out/htmldoc.tgz

build/htmldoc/src/index.html.md: README.md
	@mkdir -p "$(@D)"
	cat tools/htmldoc/header.md "$<" > "$@"

build/htmldoc/src/lib/index.html.md: lib/Readme.md
	@mkdir -p "$(@D)"
	cat tools/htmldoc/header.md "$<" > "$@"

build/htmldoc/out: build/htmldoc/src
	@rm -rf build/htmldoc/out
	@cd tools/htmldoc && $(DOCPAD_BIN) --silent generate --env static

build/htmldoc/out/adminpage.css: lib/adminpage/build/component-build/adminpage.css
	@mkdir -p "$(@D)"
	@cp "$<" "$@"

build/htmldoc/out/htmldoc.tgz: build/htmldoc/out
	@rm -f build/htmldoc/out/htmldoc.tgz
	cd build/htmldoc/out && tar -czf htmldoc.tgz --exclude htmldoc.tgz *

htmldoc/clean:
	rm -rf build/htmldoc

