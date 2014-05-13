DOCPAD_BIN := $(NODE_BIN)/docpad
DOCPAD_GENERATE := $(DOCPAD_BIN) generate --env static
GIT := git --git-dir $(shell test -r .rsync-src && cat .rsync-src).git
GIT_ORIGIN := $(shell $(GIT) config remote.origin.url)
GIT_ORIGIN_HTTPS := $(GIT_ORIGIN:git@github.com:%=https://github.com/%)
GITHUB_URL := $(GIT_ORIGIN_HTTPS:.git=)
HTMLDOC := $(BUILD)/htmldoc

htmldoc: $(HTMLDOC)/src/index.html.md $(HTMLDOC)/src/lib/index.html.md $(HTMLDOC)/out $(HTMLDOC)/out/htmldoc.tgz

$(HTMLDOC)/src/index.html.md: README.md
	@mkdir -p "$(@D)"
	cat tools/htmldoc/header.md "$<" > "$@"

$(HTMLDOC)/src/lib/index.html.md: lib/Readme.md
	@mkdir -p "$(@D)"
	cat tools/htmldoc/header.md "$<" > "$@"

$(HTMLDOC)/out:
	@rm -rf $(HTMLDOC)/out
	@cd tools/htmldoc && $(DOCPAD_GENERATE) --silent

$(HTMLDOC)/out/htmldoc.tgz: $(HTMLDOC)/out
	@rm -f $(HTMLDOC)/out/htmldoc.tgz
	cd $(HTMLDOC)/out && tar -czf htmldoc.tgz --exclude htmldoc.tgz *

htmldoc/clean:
	rm -rf $(HTMLDOC)

