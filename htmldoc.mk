DOCPAD_BIN := $(NODE_BIN)/docpad
DOCPAD_GENERATE := $(DOCPAD_BIN) generate --env static
GIT := git --git-dir $(shell test -r .rsync-src && cat .rsync-src).git
GIT_ORIGIN := $(shell $(GIT) config remote.origin.url)
GIT_ORIGIN_HTTPS := $(GIT_ORIGIN:git@github.com:%=https://github.com/%)
GITHUB_URL := $(GIT_ORIGIN_HTTPS:.git=)

htmldoc: build/htmldoc/src/index.html.md build/htmldoc/src/lib/index.html.md build/htmldoc/out build/htmldoc/out/htmldoc.tgz

build/htmldoc/src/index.html.md: README.md
	@mkdir -p "$(@D)"
	cat tools/htmldoc/header.md "$<" > "$@"

build/htmldoc/src/lib/index.html.md: lib/Readme.md
	@mkdir -p "$(@D)"
	cat tools/htmldoc/header.md "$<" > "$@"

build/htmldoc/out:
	@rm -rf build/htmldoc/out
	@cd tools/htmldoc && $(DOCPAD_GENERATE) --silent

build/htmldoc/out/htmldoc.tgz: build/htmldoc/out
	@rm -f build/htmldoc/out/htmldoc.tgz
	cd build/htmldoc/out && tar -czf htmldoc.tgz --exclude htmldoc.tgz *

htmldoc/clean:
	rm -rf build/htmldoc

